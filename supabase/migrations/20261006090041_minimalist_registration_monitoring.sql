-- Scope superseded by Vinício on 06/10/2026: Cadastro + Monitoramento, SCC fields.
-- Preserve legacy history and the '<' evaluation recorded there. New registrations use '<='.
create table public.instrument_registrations (
 id uuid primary key,instrument_id uuid not null references public.instruments(id),company_id uuid not null references public.companies(id),
 version integer not null,state text not null check(state in ('rascunho','aguardando aprovação','aprovado','devolvido')),
 instrument_data jsonb not null,certificate_data jsonb not null,quantitative jsonb not null,
 base_updated_at timestamptz not null,created_by uuid not null references auth.users(id),created_at timestamptz not null default now(),
 submitted_at timestamptz,reviewed_by uuid references auth.users(id),reviewed_at timestamptz,review_notes text not null default '',reviewed_label text not null default '',updated_at timestamptz not null default now(),
 unique(instrument_id,version)
);
create unique index one_open_registration on public.instrument_registrations(instrument_id) where state in ('rascunho','aguardando aprovação','devolvido');
create index registrations_company_state on public.instrument_registrations(company_id,state,updated_at desc);
create index registrations_creator on public.instrument_registrations(created_by);
create index registrations_reviewer on public.instrument_registrations(reviewed_by);
alter table public.instrument_registrations enable row level security;
create policy registration_read on public.instrument_registrations for select to authenticated using(private.can_access(company_id));
revoke all on public.instrument_registrations from public,anon,authenticated;grant select on public.instrument_registrations to authenticated;
-- Existing role IDs retained; UI labels now define the simple hierarchy.
insert into private.role_permissions(role,permission)values
 ('owner','edit_registration'),('owner','review_registration'),('owner','manage_access'),
 ('quality_admin','read'),('quality_admin','manage_instruments'),('quality_admin','register_event'),('quality_admin','edit_registration'),('quality_admin','review_registration'),
 ('analyst','read'),('analyst','manage_instruments'),('analyst','register_event'),('analyst','edit_registration'),
 ('viewer','read'),('inspector','read'),('contractor','read') on conflict do nothing;
-- Disable previous write APIs so editing cannot bypass responsible approval.
do $$declare f record;begin
 for f in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname in ('public','private') and (p.proname like 'save_%' or p.proname like 'import_%' or p.proname like 'register_%' or p.proname='prepare_li_certificate') loop
 execute format('revoke execute on function %s from public,anon,authenticated',f.signature);
 end loop;
end$$;
create or replace function public.my_permissions()returns jsonb language sql stable security invoker set search_path='' as $$
 select coalesce(jsonb_agg(p),'[]'::jsonb) from unnest(array['read','edit_registration','review_registration','manage_access']) p where private.has_permission(p)
$$;
create function private.simple_registration_json(r public.instrument_registrations)returns jsonb language sql stable set search_path='' as $$
 select jsonb_build_object('id',r.id,'instrumentId',r.instrument_id,'companyId',r.company_id,'version',r.version,'state',r.state,'instrument',r.instrument_data,'certificate',r.certificate_data,'quantitative',r.quantitative,'baseUpdatedAt',r.base_updated_at,'createdBy',r.created_by,'submittedAt',r.submitted_at,'reviewedBy',r.reviewed_by,'reviewedName',r.reviewed_label,'reviewedAt',r.reviewed_at,'reviewNotes',r.review_notes,'updatedAt',r.updated_at)
$$;
create function private.simple_quantitative(c jsonb)returns jsonb language plpgsql immutable set search_path='' as $$
declare e numeric=private.parse_decimal(c->>'measurementError');u numeric=private.parse_decimal(c->>'measurementUncertainty');t numeric=private.parse_decimal(c->>'processTolerance');begin
 return jsonb_build_object('status',case when e is null or u is null or t is null or t<=0 or coalesce(c->>'resultBasis','') not in ('%','unidade') then 'pendente' when abs(e)+abs(u)<=t then 'conforme' else 'não conforme' end,'total',case when e is null or u is null then '' else (abs(e)+abs(u))::text end,'operator','<=');end$$;
create function private.minimal_context()returns jsonb language plpgsql stable security definer set search_path='' as $$
declare m private.members%rowtype;begin select * into m from private.members where user_id=auth.uid() and active;if not found then raise exception 'Acesso não autorizado';end if;return jsonb_build_object('userId',m.user_id,'role',m.role,'companyId',m.company_id,'permissions',public.my_permissions());end$$;
create function public.minimal_context()returns jsonb language sql security invoker set search_path='' as $$select private.minimal_context()$$;

create function private.save_simple_registration(payload jsonb,submit boolean)returns jsonb language plpgsql security definer set search_path='' as $$
declare target uuid=(payload->>'id')::uuid;i jsonb=payload->'instrument';c jsonb=payload->'certificate';master public.instruments%rowtype;old public.instrument_registrations%rowtype;r public.instrument_registrations%rowtype;q jsonb;key text;file storage.objects%rowtype;path text;new_version int;
begin
 if auth.uid() is null or not private.has_permission('edit_registration') then raise exception 'Permissão de cadastro necessária';end if;
 if submit is null or target is null or jsonb_typeof(i) is distinct from 'object' or jsonb_typeof(c) is distinct from 'object' or octet_length(payload::text)>30000 then raise exception 'Cadastro inválido';end if;
 select * into master from public.instruments where id=(i->>'id')::uuid for update;
 if not found then
  if not private.can_access((i->>'ownerCompanyId')::uuid) then raise exception 'Empresa não autorizada';end if;
  perform private.save_instrument(i,'Cadastro inicial','Cadastro SCC simplificado');
  select * into master from public.instruments where id=(i->>'id')::uuid for update;
 end if;
 if not private.can_access(master.company_id) or (i->>'ownerCompanyId')::uuid is distinct from master.company_id then raise exception 'Empresa não autorizada';end if;
 select * into old from public.instrument_registrations where id=target for update;
 if found and (old.instrument_id<>master.id or old.state not in ('rascunho','devolvido')) then raise exception 'Versão enviada ou aprovada é imutável';end if;
 if old.id is null and exists(select 1 from public.instrument_registrations where instrument_id=master.id and state in ('rascunho','aguardando aprovação','devolvido')) then raise exception 'Já existe cadastro em andamento para este instrumento';end if;
 -- Only the SCC field set is persisted; operational/current certificate values cannot be forged.
 i=jsonb_build_object('id',master.id,'ownerCompanyId',master.company_id,'liNumber',master.data->>'liNumber','code',master.code,'liSource',master.data->'liSource',
  'workSite',coalesce(i->>'workSite',''),'criticality',coalesce(i->>'criticality',''),'serial',coalesce(i->>'serial',''),'model',coalesce(i->>'model',''),'location',coalesce(i->>'location',''),
  'calibrationResponsibleArea',coalesce(i->>'calibrationResponsibleArea',''),'process',coalesce(i->>'process',''),'measurementRange',coalesce(i->>'measurementRange',''),'usageRange',coalesce(i->>'usageRange',''),
  'verificationDivision',coalesce(i->>'verificationDivision',''),'periodicityMonths',(i->>'periodicityMonths')::integer,'registrationStatus',i->>'registrationStatus','contractorEquipment',coalesce(i->>'contractorEquipment','não'),
  'operationalStatus',master.data->>'operationalStatus','lastControl',master.data->>'lastControl','nextControl',master.data->>'nextControl');
 if coalesce(i->>'registrationStatus','') not in ('ativo','inativo','desmobilizado','baixado') then raise exception 'Status de cadastro inválido';end if;
 path=coalesce(c->>'attachmentPath','');
 if path<>'' then
  if path !~ ('^'||master.id::text||'/[a-f0-9-]{36}/[a-f0-9-]{36}\.(pdf|xlsx|xls)$') then raise exception 'Anexo não pertence ao instrumento';end if;
  select * into file from storage.objects where bucket_id='metrology-certificates' and name=path for share;
  if not found or coalesce(file.metadata->>'mimetype','') not in ('application/pdf','application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') or coalesce((file.metadata->>'size')::bigint,0) not between 1 and 16777216 then raise exception 'Anexo inexistente ou inválido';end if;
  if file.owner_id is distinct from auth.uid()::text and not exists(select 1 from public.instrument_registrations where instrument_id=master.id and certificate_data->>'attachmentPath'=path) and not exists(select 1 from public.certificates cc join public.metrological_events ee on ee.id=cc.event_id where ee.instrument_id=master.id and cc.storage_path=path) then raise exception 'Anexo não registrado por usuário autorizado';end if;
 end if;
 c=jsonb_build_object('date',coalesce(c->>'date',''),'nextDate',coalesce(c->>'nextDate',''),'laboratory',coalesce(c->>'laboratory',''),'certificateNumber',coalesce(c->>'certificateNumber',''),
  'laboratoryAccredited',coalesce(c->>'laboratoryAccredited',''),'toleranceReferenceDocument',coalesce(c->>'toleranceReferenceDocument',''),'processTolerance',coalesce(c->>'processTolerance',''),
  'measurementError',coalesce(c->>'measurementError',''),'measurementUncertainty',coalesce(c->>'measurementUncertainty',''),'resultBasis',coalesce(c->>'resultBasis',''),
  'calibrationAccepted',coalesce(c->>'calibrationAccepted',''),'acceptedWithRestriction',coalesce(c->>'acceptedWithRestriction',''),'standardsValidation',coalesce(c->>'standardsValidation',''),
  'decision',coalesce(c->>'decision',''),'attachmentPath',path,'attachmentName',coalesce(c->>'attachmentName',''));
 q=private.simple_quantitative(c);
 if submit then
  foreach key in array array['workSite','criticality','serial','model','location','calibrationResponsibleArea','process','measurementRange','usageRange','verificationDivision'] loop if nullif(btrim(i->>key),'') is null then raise exception 'Campo obrigatório: %',key;end if;end loop;
  if coalesce((i->>'periodicityMonths')::int,0)<1 or i->>'contractorEquipment' not in ('sim','não') then raise exception 'Intervalo ou empresa contratada inválido';end if;
  foreach key in array array['date','nextDate','laboratory','certificateNumber','toleranceReferenceDocument','attachmentPath'] loop if nullif(btrim(c->>key),'') is null then raise exception 'Campo obrigatório: %',key;end if;end loop;
  if c->>'date' !~ '^\d{4}-\d{2}-\d{2}$' or c->>'nextDate' !~ '^\d{4}-\d{2}-\d{2}$' or (c->>'nextDate')::date<=(c->>'date')::date or q->>'status'='pendente' then raise exception 'Datas ou valores da calibração inválidos';end if;
  foreach key in array array['laboratoryAccredited','calibrationAccepted','acceptedWithRestriction'] loop if c->>key not in ('sim','não') then raise exception 'Resposta obrigatória: %',key;end if;end loop;
  if c->>'decision' not in ('liberado para uso','uso condicionado','fora de uso','segregado') then raise exception 'Situação do equipamento obrigatória';end if;
 end if;
 select coalesce(max(version),0)+1 into new_version from public.instrument_registrations where instrument_id=master.id;
 insert into public.instrument_registrations(id,instrument_id,company_id,version,state,instrument_data,certificate_data,quantitative,base_updated_at,created_by,submitted_at)
 values(target,master.id,master.company_id,coalesce(old.version,new_version),case when submit then 'aguardando aprovação' else 'rascunho' end,i,c,q,coalesce(old.base_updated_at,master.updated_at),coalesce(old.created_by,auth.uid()),case when submit then now() end)
 on conflict(id)do update set state=excluded.state,instrument_data=excluded.instrument_data,certificate_data=excluded.certificate_data,quantitative=excluded.quantitative,submitted_at=excluded.submitted_at,updated_at=now() returning * into r;
 perform private.write_audit(case when submit then 'Cadastro enviado para aprovação' else 'Rascunho de cadastro salvo' end,master.code,master.company_id,to_jsonb(old),to_jsonb(r),'SCC simplificado');
 return private.simple_registration_json(r);
end$$;
create function public.save_simple_registration(payload jsonb,submit boolean)returns jsonb language sql security invoker set search_path='' as $$select private.save_simple_registration(payload,submit)$$;

create function private.review_simple_registration(registration_id uuid,approve boolean,notes text)returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.instrument_registrations%rowtype;master public.instruments%rowtype;updated jsonb;begin
 if approve is null or auth.uid() is null or not private.has_permission('review_registration') then raise exception 'Aprovação reservada ao responsável';end if;
 -- Same lock order as save to serialize concurrent approvals/edits.
 select i.* into master from public.instruments i join public.instrument_registrations rr on rr.instrument_id=i.id where rr.id=registration_id for update of i;
 if not found or not private.can_access(master.company_id) then raise exception 'Cadastro indisponível';end if;
 select * into r from public.instrument_registrations where id=registration_id for update;
 if r.state<>'aguardando aprovação' then raise exception 'Cadastro não está aguardando aprovação';end if;
 if length(coalesce(notes,''))>2000 or not approve and nullif(btrim(notes),'') is null then raise exception 'Informe o motivo da devolução';end if;
 if approve then
  if master.updated_at is distinct from r.base_updated_at then raise exception 'Ficha alterada após envio. Atualize o cadastro antes de aprovar';end if;
  updated=private.save_instrument(r.instrument_data,'Alteração revisada pelo responsável',coalesce(nullif(btrim(notes),''),'Certificado aprovado no Metrikon'));
  updated=updated||jsonb_build_object('lastControl',r.certificate_data->>'date','nextControl',r.certificate_data->>'nextDate','operationalStatus',r.certificate_data->>'decision','currentRegistrationId',r.id,'currentCertificate',r.certificate_data);
  update public.instruments set data=updated,operational_status=updated->>'operationalStatus',next_control=(r.certificate_data->>'nextDate')::date,updated_at=now() where id=master.id;
  perform private.refresh_search(master.id);
 end if;
 update public.instrument_registrations set state=case when approve then 'aprovado' else 'devolvido' end,reviewed_by=auth.uid(),reviewed_at=now(),reviewed_label=(select email from auth.users where id=auth.uid()),review_notes=btrim(coalesce(notes,'')),updated_at=now() where id=r.id returning * into r;
 perform private.write_audit(case when approve then 'Cadastro aprovado' else 'Cadastro devolvido' end,master.code,master.company_id,master.data,case when approve then updated else master.data end,notes);
 return private.simple_registration_json(r);
end$$;
create function public.review_simple_registration(registration_id uuid,approve boolean,notes text)returns jsonb language sql security invoker set search_path='' as $$select private.review_simple_registration(registration_id,approve,notes)$$;

create function private.minimal_members()returns jsonb language plpgsql stable security definer set search_path='' as $$begin
 if auth.uid() is null or not private.has_permission('manage_access') or not exists(select 1 from private.members where user_id=auth.uid() and role='owner' and active and company_id is null) then raise exception 'Somente proprietário gerencia perfis';end if;
 return coalesce((select jsonb_agg(jsonb_build_object('userId',m.user_id,'email',u.email,'role',m.role,'companyId',m.company_id,'active',m.active) order by u.email) from private.members m join auth.users u on u.id=m.user_id),'[]');end$$;
create function public.minimal_members()returns jsonb language sql security invoker set search_path='' as $$select private.minimal_members()$$;
create function private.set_minimal_member(email text,new_role text,target_company uuid,enabled boolean)returns jsonb language plpgsql security definer set search_path='' as $$declare target uuid;old private.members%rowtype;begin
 perform private.minimal_members();
 if new_role not in ('quality_admin','analyst','viewer') then raise exception 'Perfil inválido';end if;
 select id into target from auth.users where lower(auth.users.email)=lower(btrim(set_minimal_member.email)) and email_confirmed_at is not null;
 if target is null then raise exception 'Usuário precisa existir e confirmar e-mail no acesso do Metrikon';end if;
 select * into old from private.members where user_id=target for update;
 if target=auth.uid() or old.role='owner' then raise exception 'Proprietário não pode ser alterado por este formulário';end if;
 if target_company is not null and not exists(select 1 from public.companies where id=target_company and (data->>'active')::boolean) then raise exception 'Empresa inválida';end if;
 insert into private.members(user_id,role,company_id,active)values(target,new_role,target_company,enabled)on conflict(user_id)do update set role=excluded.role,company_id=excluded.company_id,active=excluded.active;
 perform private.write_audit('Perfil de acesso atualizado',target::text,target_company,to_jsonb(old),jsonb_build_object('role',new_role,'companyId',target_company,'active',enabled),'Proprietário');
 return private.minimal_members();end$$;
create function public.set_minimal_member(email text,new_role text,target_company uuid,enabled boolean)returns jsonb language sql security invoker set search_path='' as $$select private.set_minimal_member(email,new_role,target_company,enabled)$$;
-- New guarded functions; no anonymous execution or raw table mutation.
revoke all on function private.simple_registration_json(public.instrument_registrations),private.simple_quantitative(jsonb),private.minimal_context(),private.save_simple_registration(jsonb,boolean),private.review_simple_registration(uuid,boolean,text),private.minimal_members(),private.set_minimal_member(text,text,uuid,boolean) from public,anon,authenticated;
revoke all on function public.minimal_context(),public.save_simple_registration(jsonb,boolean),public.review_simple_registration(uuid,boolean,text),public.minimal_members(),public.set_minimal_member(text,text,uuid,boolean) from public,anon;
grant execute on function private.minimal_context(),private.save_simple_registration(jsonb,boolean),private.review_simple_registration(uuid,boolean,text),private.minimal_members(),private.set_minimal_member(text,text,uuid,boolean) to authenticated;
grant execute on function public.minimal_context(),public.save_simple_registration(jsonb,boolean),public.review_simple_registration(uuid,boolean,text),public.minimal_members(),public.set_minimal_member(text,text,uuid,boolean) to authenticated;
update public.system_settings set value='{"expression":"abs(error)+abs(uncertainty)<=tolerance","operator":"<=","scope":"instrument_registrations"}',source='Vinício, anotação do responsável em 06/10/2026; históricos anteriores preservados' where key='quantitative_rule';
create function private.minimal_workspace(search text,filter text,window_days integer,page_number integer)returns jsonb language plpgsql stable security definer set search_path='' as $$
declare output jsonb;begin
 if auth.uid() is null or not private.has_permission('read') then raise exception 'Sem permissão de consulta';end if;
 if window_days not between 1 and 365 or page_number<0 or page_number>20000 or length(search)>150 or filter not in ('todos','vencidos','proximos','sem_data','aprovacao') then raise exception 'Filtro inválido';end if;
 with accessible as(select i.*,rr.id as registration_id,rr.state as registration_state,private.simple_registration_json(rr) as open_registration from public.instruments i left join public.instrument_registrations rr on rr.instrument_id=i.id and rr.state in ('rascunho','aguardando aprovação','devolvido') where private.can_access(i.company_id)),
 matched as(select * from accessible where (search='' or strpos(lower(search_text),lower(search))>0 or strpos(lower(coalesce(data->>'criticality','')||' '||coalesce(data->>'serial','')||' '||coalesce(data->>'location','')),lower(search))>0) and
 case filter when 'vencidos' then next_control<(now() at time zone 'America/Recife')::date
 when 'proximos' then next_control between (now() at time zone 'America/Recife')::date and (now() at time zone 'America/Recife')::date+window_days
 when 'sem_data' then next_control is null when 'aprovacao' then registration_state='aguardando aprovação' else true end),
 paged as(select * from matched order by next_control nulls last,code limit 50 offset page_number*50)
 select jsonb_build_object('items',coalesce((select jsonb_agg(jsonb_build_object('instrument',data,'openRegistration',case when registration_id is null then null else open_registration end) order by next_control nulls last,code) from paged),'[]'),'total',(select count(*)from matched),
 'metrics',jsonb_build_object('total',(select count(*)from accessible),'expired',(select count(*)from accessible where next_control<(now() at time zone 'America/Recife')::date),'soon',(select count(*)from accessible where next_control between (now() at time zone 'America/Recife')::date and (now() at time zone 'America/Recife')::date+window_days),'pending',(select count(*)from accessible where registration_state='aguardando aprovação'))) into output;return output;end$$;
create function public.minimal_workspace(search text,filter text,window_days integer,page_number integer)returns jsonb language sql security invoker set search_path='' as $$select private.minimal_workspace(search,filter,window_days,page_number)$$;
revoke all on function private.minimal_workspace(text,text,integer,integer),public.minimal_workspace(text,text,integer,integer) from public,anon;
grant execute on function private.minimal_workspace(text,text,integer,integer),public.minimal_workspace(text,text,integer,integer) to authenticated;
