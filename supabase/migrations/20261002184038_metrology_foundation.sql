-- Apply ONLY to the new independent Metrology project. No references to GRCON operational tables.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table private.members (
 user_id uuid primary key references auth.users(id), role text not null check(role in ('owner','quality_admin','analyst','inspector','contractor','viewer')),
 company_id uuid, active boolean not null default true
);
create table private.role_permissions(role text not null, permission text not null, primary key(role,permission));
create table private.user_permissions(user_id uuid references auth.users(id), permission text not null, valid_until timestamptz, primary key(user_id,permission));
-- Software bootstrap only. Final RHDD permission matrix is pending. No other role is automatically empowered.
insert into private.role_permissions values ('owner','read'),('owner','manage_instruments'),('owner','manage_companies'),('owner','register_event'),('owner','conclude_analysis'),('owner','release_instrument'),('owner','view_audit');
-- authorize_conditioned and accept_divergence deliberately require explicit configuration, even for owner.
create table public.profiles (id uuid primary key references auth.users(id), name text not null default '');
create table public.companies(id uuid primary key, name text not null, data jsonb not null, created_at timestamptz not null default now());
alter table private.members add constraint member_company_fk foreign key(company_id) references public.companies(id);
create table public.instruments (
 id uuid primary key, code text not null, company_id uuid not null references public.companies(id), registration_status text not null check(registration_status in ('ativo','inativo','desmobilizado','baixado')),
 operational_status text not null check(operational_status in ('liberado para uso','uso condicionado','fora de uso','segregado')),
 serial text not null default '', tag text not null default '', next_control date, search_text text not null default '', data jsonb not null, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index instruments_code_unique on public.instruments(lower(btrim(code)));
create index instruments_serial on public.instruments(serial);
create index instruments_tag on public.instruments(tag);
create index instruments_company_status_due on public.instruments(company_id,registration_status,next_control);
create index instruments_next_control on public.instruments(next_control);
create index instruments_operational on public.instruments(operational_status);
create index instruments_search on public.instruments using gin(to_tsvector('simple',search_text));
create table public.instrument_measurement_capabilities (id uuid primary key, instrument_id uuid not null references public.instruments(id), quantity text not null, unit text not null, min_value numeric not null, max_value numeric not null, range_type text not null, check(min_value<=max_value));
create index capabilities_instrument on public.instrument_measurement_capabilities(instrument_id);
create table public.instrument_periodicity_history(id uuid primary key default gen_random_uuid(),instrument_id uuid not null references public.instruments(id), previous_months integer,new_months integer,reason text not null,evidence text not null,actor uuid not null,at timestamptz not null default now());
create index periodicity_instrument_date on public.instrument_periodicity_history(instrument_id,at desc);
create table public.metrological_events (id uuid primary key,instrument_id uuid not null references public.instruments(id),event_type text not null check(event_type in ('calibração externa','verificação interna')),event_date date,certificate_number text not null default '',workflow text not null check(workflow in ('aguardando envio','em calibração','certificado recebido','análise em andamento','concluído')),data jsonb not null,created_at timestamptz not null default now());
create index events_instrument_date on public.metrological_events(instrument_id,event_date desc);
create index events_certificate on public.metrological_events(certificate_number);
create index events_workflow on public.metrological_events(workflow);
create table public.calibration_result_groups (id uuid primary key default gen_random_uuid(),event_id uuid not null references public.metrological_events(id), quantity text not null, unit text not null,unique(event_id,quantity,unit));
create index result_groups_event on public.calibration_result_groups(event_id);
create table public.calibration_points (id uuid primary key, group_id uuid not null references public.calibration_result_groups(id),reference_value numeric,indicated_value numeric,error_value numeric,uncertainty numeric,tolerance numeric,unit text,tolerance_unit text,factor_k numeric,veff text,direction text,notes text,evaluation text not null check(evaluation in ('conforme','não conforme','pendente')));
create index points_group on public.calibration_points(group_id);
create table public.qualitative_review_items(event_id uuid references public.metrological_events(id),item_key text,label text not null,outcome text not null check(outcome in ('','conforme','não conforme','não aplicável')),notes text not null default '',evidence text not null default '',primary key(event_id,item_key));
create table public.certificates(event_id uuid primary key references public.metrological_events(id),number text not null,storage_path text not null unique,identity jsonb not null,divergence_justification text not null default '');
create table public.metrological_decisions(event_id uuid primary key references public.metrological_events(id),decision text not null,quantitative_outcome text not null,qualitative_outcome text not null,rationale text not null,authorizer uuid not null,at timestamptz not null default now());
create table public.conditional_use_restrictions(event_id uuid primary key references public.metrological_events(id),data jsonb not null,deadline date not null);
create table public.audit_log(id uuid primary key default gen_random_uuid(),at timestamptz not null default now(),actor uuid,action text not null,entity text not null,company_id uuid,old_data jsonb,new_data jsonb,reason text not null default '');
create index audit_company_date on public.audit_log(company_id,at desc);
create table public.system_settings(key text primary key,value jsonb not null,classification text not null check(classification in ('confirmed_rule','pending_rhdd','software_improvement','prototype_hypothesis')),source text not null);
insert into public.system_settings values
 ('quantitative_rule','{"expression":"abs(error)+abs(uncertainty)<tolerance","operator":"<"}','confirmed_rule','PR CONSAG 220 42 Rev.11 §3.1.6'),
 ('alert_threshold_days','null','pending_rhdd','RHDD: aguardando confirmação'),
 ('conditioned_use_authority','null','pending_rhdd','RHDD: aguardando confirmação'),
 ('rnc_workflow','null','pending_rhdd','PR CONSAG 220 43 não fornecido'),
 ('brand','{"appName":"GRCON Metrologia — RHDD"}','prototype_hypothesis','Nome provisório solicitado');

-- Private ACL helpers are narrowly privileged, never use user_metadata and never accept a caller user ID.
create function private.has_permission(required_permission text) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from private.members m where m.user_id=auth.uid() and m.active and (exists(select 1 from private.role_permissions p where p.role=m.role and p.permission=required_permission) or exists(select 1 from private.user_permissions p where p.user_id=m.user_id and p.permission=required_permission and (p.valid_until is null or p.valid_until>now()))))
$$;
create function private.can_access(target_company uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.has_permission('read') and exists(select 1 from private.members m where m.user_id=auth.uid() and m.active and (m.company_id is null or m.company_id=target_company))
$$;
create function private.event_access(target_event uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.metrological_events e join public.instruments i on i.id=e.instrument_id where e.id=target_event and private.can_access(i.company_id))
$$;
create function public.my_permissions() returns jsonb language sql stable security invoker set search_path='' as $$
 select coalesce(jsonb_agg(p), '[]'::jsonb) from unnest(array['read','manage_instruments','manage_companies','register_event','conclude_analysis','release_instrument','authorize_conditioned','accept_divergence','view_audit']) p where private.has_permission(p)
$$;

-- Backend numeric evaluation uses exact NUMERIC and strictly '<'. Inputs with incompatible units are pending.
create function public.evaluate_metrology_point(error_value numeric,uncertainty numeric,tolerance numeric,unit text,tolerance_unit text) returns text language sql immutable security invoker set search_path='' as $$
 select case when error_value is null or uncertainty is null or tolerance is null or tolerance<=0 or nullif(btrim(unit),'') is null or nullif(btrim(tolerance_unit),'') is null or btrim(unit)<>btrim(tolerance_unit) then 'pendente' when abs(error_value)+abs(uncertainty)<tolerance then 'conforme' else 'não conforme' end
$$;
create function private.parse_decimal(v text) returns numeric language plpgsql immutable security invoker set search_path='' as $$ begin if v is null or btrim(v)!~'^[+-]?[0-9]+([.,][0-9]+)?$' then return null;end if;return replace(btrim(v),',','.')::numeric;end $$;
create function private.write_audit(action_name text,entity_name text,target_company uuid,old_value jsonb,new_value jsonb,reason text) returns void language plpgsql security definer set search_path='' as $$begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 insert into public.audit_log(actor,action,entity,company_id,old_data,new_data,reason)values(auth.uid(),action_name,entity_name,target_company,old_value,new_value,coalesce(reason,''));
end$$;

create function private.refresh_search(target_instrument uuid) returns void language sql security definer set search_path='' as $$
 update public.instruments i set search_text=concat_ws(' ',i.code,i.serial,i.tag,i.data->>'internalId',i.data->>'assetNumber',i.data->>'liNumber',i.data->>'description',i.data->>'manufacturer',i.data->>'model',i.data->>'responsible',(select c.name from public.companies c where c.id=i.company_id),(select string_agg(concat_ws(' ',e.certificate_number,e.data->>'laboratory'),' ') from public.metrological_events e where e.instrument_id=i.id)) where i.id=target_instrument
$$;
create function private.save_company(payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare target uuid=(payload->>'id')::uuid; old_value jsonb;
begin
 if not private.has_permission('manage_companies') then raise exception 'Permission denied';end if;
 if exists(select 1 from private.members m where m.user_id=auth.uid() and m.company_id is not null) then raise exception 'Company administration requires unscoped permission';end if;
 if nullif(btrim(payload->>'name'),'') is null then raise exception 'Company name required';end if;
 select c.data into old_value from public.companies c where c.id=target for update;
 insert into public.companies(id,name,data)values(target,btrim(payload->>'name'),payload) on conflict(id)do update set name=excluded.name,data=excluded.data;
 perform private.write_audit('Cadastro/alteração de empresa',target::text,target,old_value,payload,'');
 perform private.refresh_search(i.id) from public.instruments i where i.company_id=target;
 return payload;
end$$;
create function public.save_company(payload jsonb)returns jsonb language sql security invoker set search_path='' as $$select private.save_company(payload)$$;

create function private.save_instrument(payload jsonb,change_reason text,change_evidence text) returns jsonb language plpgsql security definer set search_path='' as $$
declare target uuid=(payload->>'id')::uuid; company uuid=(payload->>'ownerCompanyId')::uuid;old_value jsonb;old_months integer;new_months integer;cap jsonb;current_data jsonb;
begin
 if not private.has_permission('manage_instruments') or not private.can_access(company) then raise exception 'Permission denied';end if;
 if nullif(btrim(payload->>'code'),'') is null or nullif(btrim(payload->>'description'),'') is null then raise exception 'Code and description required';end if;
 select i.data into old_value from public.instruments i where i.id=target for update;
 if old_value is not null and not private.can_access((old_value->>'ownerCompanyId')::uuid) then raise exception 'Permission denied';end if;
 -- Operational decision and dates cannot be forged by editing the master record.
 current_data=payload||jsonb_build_object('operationalStatus',coalesce(old_value->>'operationalStatus','fora de uso'),'lastControl',coalesce(old_value->>'lastControl',''),'nextControl',coalesce(old_value->>'nextControl',''),'metrologicalStatus',coalesce(old_value->>'metrologicalStatus','em análise'));
 old_months=(old_value->>'periodicityMonths')::integer;new_months=(payload->>'periodicityMonths')::integer;
 if new_months is not null and new_months<1 then raise exception 'Periodicity must be positive';end if;
 if old_months is distinct from new_months and (nullif(btrim(change_reason),'') is null or nullif(btrim(change_evidence),'') is null) then raise exception 'Periodicity change requires reason and evidence';end if;
 if jsonb_typeof(payload->'capabilities')<>'array' then raise exception 'Capabilities must be an array';end if;
 insert into public.instruments(id,code,company_id,registration_status,operational_status,serial,tag,next_control,data)values(target,btrim(payload->>'code'),company,payload->>'registrationStatus',current_data->>'operationalStatus',coalesce(payload->>'serial',''),coalesce(payload->>'tag',''),nullif(current_data->>'nextControl','')::date,current_data)on conflict(id)do update set code=excluded.code,company_id=excluded.company_id,registration_status=excluded.registration_status,serial=excluded.serial,tag=excluded.tag,data=excluded.data,updated_at=now();
 -- Capabilities are editable master data; event result snapshots remain untouched.
 delete from public.instrument_measurement_capabilities where instrument_id=target;
 for cap in select value from jsonb_array_elements(payload->'capabilities')loop
  if nullif(btrim(cap->>'quantity'),'') is null or nullif(btrim(cap->>'unit'),'') is null or private.parse_decimal(cap->>'min') is null or private.parse_decimal(cap->>'max') is null then raise exception 'Invalid measurement capability';end if;
  insert into public.instrument_measurement_capabilities(id,instrument_id,quantity,unit,min_value,max_value,range_type)values((cap->>'id')::uuid,target,cap->>'quantity',cap->>'unit',private.parse_decimal(cap->>'min'),private.parse_decimal(cap->>'max'),coalesce(cap->>'rangeType',''));
 end loop;
 if old_months is distinct from new_months then insert into public.instrument_periodicity_history(instrument_id,previous_months,new_months,reason,evidence,actor)values(target,old_months,new_months,change_reason,change_evidence,auth.uid());end if;
 perform private.refresh_search(target);
 perform private.write_audit(case when old_value is null then 'Cadastro de instrumento' else 'Alteração de instrumento' end,target::text,company,old_value,current_data,change_reason);
 return current_data;
end$$;
create function public.save_instrument(payload jsonb,change_reason text,change_evidence text)returns jsonb language sql security invoker set search_path='' as $$select private.save_instrument(payload,change_reason,change_evidence)$$;

create function private.save_metrological_event(payload jsonb,conclude boolean)returns jsonb language plpgsql security definer set search_path='' as $$
declare target uuid=(payload->>'id')::uuid;instrument uuid=(payload->>'instrumentId')::uuid;master public.instruments%rowtype;old_event public.metrological_events%rowtype;current_data jsonb;point jsonb;item jsonb;group_id uuid;quant_status text='pendente';qual_status text='pendente';point_status text;decision text=payload->>'decision';restriction jsonb=payload->'restriction';field text;divergent boolean=false;next_day date;event_day date;attachment text=payload->>'attachmentPath';
begin
 select * into master from public.instruments where id=instrument for update;
 if not found or not private.has_permission('register_event') or not private.can_access(master.company_id) then raise exception 'Permission denied';end if;
 select * into old_event from public.metrological_events where id=target for update;
 if old_event.id is not null and (old_event.instrument_id<>instrument or old_event.workflow='concluído') then raise exception 'Closed events are immutable; create a new cycle';end if;
 if jsonb_typeof(payload->'points')<>'array' or jsonb_typeof(payload->'checklist')<>'array' then raise exception 'Points and checklist must be arrays';end if;
 event_day=nullif(payload->>'date','')::date;next_day=nullif(payload->>'nextDate','')::date;
 if next_day is not null and (event_day is null or next_day<=event_day) then raise exception 'Next control must be after event date';end if;
 for field in select unnest(array['serial','tag','manufacturer','model'])loop
  if nullif(btrim(payload->'certificateIdentity'->>field),'') is not null and lower(btrim(coalesce(master.data->>field,'')))<>lower(btrim(payload->'certificateIdentity'->>field)) then divergent=true;end if;
 end loop;
 -- Schema and decisions recomputed server-side, not accepted from client claims.
 if jsonb_array_length(payload->'points')>0 then
  quant_status='conforme';
  for point in select value from jsonb_array_elements(payload->'points')loop
   point_status=public.evaluate_metrology_point(private.parse_decimal(point->>'error'),private.parse_decimal(point->>'uncertainty'),private.parse_decimal(point->>'tolerance'),point->>'unit',point->>'toleranceUnit');
   if point_status='não conforme' then quant_status='não conforme';elsif point_status='pendente' and quant_status<>'não conforme' then quant_status='pendente';end if;
  end loop;
 end if;
 if jsonb_array_length(payload->'checklist')=19 and (select count(distinct value->>'key') from jsonb_array_elements(payload->'checklist'))=19 and not exists(select 1 from jsonb_array_elements(payload->'checklist')where (value->>'key') !~ '^q([0-9]|1[0-8])$') then
  qual_status='conforme';
  for item in select value from jsonb_array_elements(payload->'checklist')loop
   if item->>'outcome'='não conforme' then qual_status='não conforme';elsif (coalesce(item->>'outcome','') not in ('conforme','não aplicável') or item->>'outcome'='não aplicável' and nullif(btrim(item->>'notes'),'') is null) and qual_status<>'não conforme' then qual_status='pendente';end if;
  end loop;
  if not exists(select 1 from jsonb_array_elements(payload->'checklist')where value->>'outcome'='conforme') and qual_status='conforme' then qual_status='pendente';end if;
 end if;
 if conclude then
  if not private.has_permission('conclude_analysis') then raise exception 'Permission denied: conclude_analysis';end if;
  if event_day is null or nullif(btrim(payload->>'certificateNumber'),'') is null or nullif(btrim(payload->>'rationale'),'') is null then raise exception 'Event date, certificate number and rationale required';end if;
  if decision not in ('liberado para uso','uso condicionado','fora de uso','segregado') or decision is null then raise exception 'Operational decision required';end if;
  if attachment is null or attachment !~ ('^'||instrument::text||'/'||target::text||'/[a-f0-9-]+\.pdf$') or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'A stored PDF certificate belonging to this event is required';end if;
  if divergent and (nullif(btrim(payload->>'divergenceJustification'),'') is null or not private.has_permission('accept_divergence')) then raise exception 'Divergence requires justification and explicit authorization';end if;
  if decision='liberado para uso' and (not private.has_permission('release_instrument') or quant_status<>'conforme' or qual_status<>'conforme') then raise exception 'Release requires permission and qualitative + quantitative conformity';end if;
  if decision='uso condicionado' then
   if not private.has_permission('authorize_conditioned') then raise exception 'RHDD conditioned-use authority pending';end if;
   for field in select unnest(array['type','description','authorizedRange','allowedProcesses','forbiddenProcesses','deadline','authorizer','evidence'])loop if nullif(btrim(restriction->>field),'') is null then raise exception 'Restriction field required: %',field;end if;end loop;
   if (restriction->>'deadline')::date<event_day then raise exception 'Restriction deadline must not precede event date';end if;
  end if;
  -- An earlier cycle can be archived, but cannot replace the current instrument situation.
  if nullif(master.data->>'lastControl','')::date>event_day then raise exception 'An earlier event cannot replace the latest operational decision';end if;
 end if;
 current_data=payload||jsonb_build_object('workflow',case when conclude then 'concluído' else 'análise em andamento' end,'createdAt',coalesce(old_event.data->>'createdAt',to_char(now() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')));
 insert into public.metrological_events(id,instrument_id,event_type,event_date,certificate_number,workflow,data)values(target,instrument,payload->>'type',event_day,coalesce(payload->>'certificateNumber',''),current_data->>'workflow',current_data)on conflict(id)do update set event_type=excluded.event_type,event_date=excluded.event_date,certificate_number=excluded.certificate_number,workflow=excluded.workflow,data=excluded.data;
 -- Only draft result rows are replaced. Concluded history cannot enter this branch again.
 delete from public.calibration_points where calibration_points.group_id in(select g.id from public.calibration_result_groups g where event_id=target);
 delete from public.calibration_result_groups where event_id=target;
 delete from public.qualitative_review_items where event_id=target;
 for point in select value from jsonb_array_elements(payload->'points')loop
  insert into public.calibration_result_groups(event_id,quantity,unit)values(target,coalesce(point->>'quantity',''),coalesce(point->>'unit',''))on conflict(event_id,quantity,unit)do update set quantity=excluded.quantity returning id into group_id;
  insert into public.calibration_points values((point->>'id')::uuid,group_id,private.parse_decimal(point->>'reference'),private.parse_decimal(point->>'indicated'),private.parse_decimal(point->>'error'),private.parse_decimal(point->>'uncertainty'),private.parse_decimal(point->>'tolerance'),point->>'unit',point->>'toleranceUnit',private.parse_decimal(point->>'k'),point->>'veff',point->>'direction',point->>'notes',public.evaluate_metrology_point(private.parse_decimal(point->>'error'),private.parse_decimal(point->>'uncertainty'),private.parse_decimal(point->>'tolerance'),point->>'unit',point->>'toleranceUnit'));
 end loop;
 for item in select value from jsonb_array_elements(payload->'checklist')loop
  insert into public.qualitative_review_items values(target,item->>'key',coalesce(item->>'label',''),coalesce(item->>'outcome',''),coalesce(item->>'notes',''),coalesce(item->>'evidence',''));
 end loop;
 if nullif(attachment,'') is not null then
  if attachment !~ ('^'||instrument::text||'/'||target::text||'/[a-f0-9-]+\.pdf$') or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'Certificate storage reference is invalid';end if;
  insert into public.certificates values(target,coalesce(payload->>'certificateNumber',''),attachment,coalesce(payload->'certificateIdentity','{}'::jsonb),coalesce(payload->>'divergenceJustification',''))on conflict(event_id)do update set number=excluded.number,storage_path=excluded.storage_path,identity=excluded.identity,divergence_justification=excluded.divergence_justification;
 end if;
 if conclude then
  insert into public.metrological_decisions values(target,decision,quant_status,qual_status,payload->>'rationale',auth.uid(),now());
  if decision='uso condicionado' then insert into public.conditional_use_restrictions values(target,restriction,(restriction->>'deadline')::date);end if;
  update public.instruments set operational_status=decision,next_control=next_day,data=data||jsonb_build_object('operationalStatus',decision,'lastControl',event_day::text,'nextControl',coalesce(next_day::text,''),'metrologicalStatus',case when quant_status='não conforme' or qual_status='não conforme' then 'reprovado' when decision='liberado para uso' then 'válido' else 'em análise' end),updated_at=now()where id=instrument;
 end if;
 perform private.refresh_search(instrument);
 perform private.write_audit(case when conclude then 'Decisão metrológica' else 'Rascunho do controle' end,target::text,master.company_id,old_event.data,current_data,coalesce(payload->>'rationale',''));
 return current_data;
end$$;
create function public.save_metrological_event(payload jsonb,conclude boolean)returns jsonb language sql security invoker set search_path='' as $$select private.save_metrological_event(payload,conclude)$$;

create function public.metrology_overview(company_filter uuid default null)returns jsonb language sql stable security invoker set search_path='' as $$
 select jsonb_build_object('total',count(*),'active',count(*)filter(where registration_status='ativo'),'released',count(*)filter(where operational_status='liberado para uso'),'conditioned',count(*)filter(where operational_status='uso condicionado'),'outOfUse',count(*)filter(where operational_status in ('fora de uso','segregado')),'expired',count(*)filter(where next_control<(now() at time zone 'America/Sao_Paulo')::date),'due7',count(*)filter(where next_control between (now() at time zone 'America/Sao_Paulo')::date and (now() at time zone 'America/Sao_Paulo')::date+7),'due30',count(*)filter(where next_control between (now() at time zone 'America/Sao_Paulo')::date and (now() at time zone 'America/Sao_Paulo')::date+30),'due60',count(*)filter(where next_control between (now() at time zone 'America/Sao_Paulo')::date and (now() at time zone 'America/Sao_Paulo')::date+60),'awaitingAnalysis',(select count(*)from public.metrological_events e join public.instruments j on j.id=e.instrument_id where e.workflow<>'concluído' and (company_filter is null or j.company_id=company_filter)))from public.instruments where company_filter is null or company_id=company_filter
$$;

-- Every exposed table: RLS + explicit read-only grants. All operational writes require guarded RPCs.
do $$declare table_name text;begin
 for table_name in select unnest(array['profiles','companies','instruments','instrument_measurement_capabilities','instrument_periodicity_history','metrological_events','calibration_result_groups','calibration_points','qualitative_review_items','certificates','metrological_decisions','conditional_use_restrictions','audit_log','system_settings'])loop
  execute format('alter table public.%I enable row level security',table_name);
  execute format('revoke all on table public.%I from anon, authenticated',table_name);
  execute format('grant select on table public.%I to authenticated',table_name);
 end loop;
end$$;
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid());
create policy company_read on public.companies for select to authenticated using(private.can_access(id));
create policy instrument_read on public.instruments for select to authenticated using(private.can_access(company_id));
create policy capability_read on public.instrument_measurement_capabilities for select to authenticated using(exists(select 1 from public.instruments i where i.id=instrument_id));
create policy periodicity_read on public.instrument_periodicity_history for select to authenticated using(exists(select 1 from public.instruments i where i.id=instrument_id));
create policy event_read on public.metrological_events for select to authenticated using(exists(select 1 from public.instruments i where i.id=instrument_id));
create policy group_read on public.calibration_result_groups for select to authenticated using(private.event_access(event_id));
create policy point_read on public.calibration_points for select to authenticated using(exists(select 1 from public.calibration_result_groups g where g.id=group_id));
create policy checklist_read on public.qualitative_review_items for select to authenticated using(private.event_access(event_id));
create policy certificate_read on public.certificates for select to authenticated using(private.event_access(event_id));
create policy decision_read on public.metrological_decisions for select to authenticated using(private.event_access(event_id));
create policy restriction_read on public.conditional_use_restrictions for select to authenticated using(private.event_access(event_id));
create policy audit_read on public.audit_log for select to authenticated using(private.has_permission('view_audit') and private.can_access(company_id));
create policy settings_read on public.system_settings for select to authenticated using(private.has_permission('read'));

-- Private certificates bucket. No public files, no replacements and no deletion.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)values('metrology-certificates','metrology-certificates',false,20971520,array['application/pdf']);
create policy metrology_certificate_read on storage.objects for select to authenticated using(bucket_id='metrology-certificates' and exists(select 1 from public.instruments i where i.id::text=split_part(name,'/',1)));
create policy metrology_certificate_insert on storage.objects for insert to authenticated with check(bucket_id='metrology-certificates' and private.has_permission('register_event') and exists(select 1 from public.instruments i where i.id::text=split_part(name,'/',1)) and name ~ '^[a-f0-9-]{36}/[a-f0-9-]{36}/[a-f0-9-]{36}\.pdf$');

-- Revoke implicit function execution, then expose only validated entrypoints and ACL helpers needed by RLS.
revoke all on all functions in schema private from public,anon,authenticated;
grant execute on function private.has_permission(text),private.can_access(uuid),private.event_access(uuid),private.save_company(jsonb),private.save_instrument(jsonb,text,text),private.save_metrological_event(jsonb,boolean)to authenticated;
revoke all on function public.my_permissions(),public.evaluate_metrology_point(numeric,numeric,numeric,text,text),public.save_company(jsonb),public.save_instrument(jsonb,text,text),public.save_metrological_event(jsonb,boolean),public.metrology_overview(uuid)from public,anon;
grant execute on function public.my_permissions(),public.evaluate_metrology_point(numeric,numeric,numeric,text,text),public.save_company(jsonb),public.save_instrument(jsonb,text,text),public.save_metrological_event(jsonb,boolean),public.metrology_overview(uuid)to authenticated;
revoke all on all tables in schema private from public,anon,authenticated;
