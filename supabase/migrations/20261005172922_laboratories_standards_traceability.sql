-- Phase 3: company-scoped laboratory/standard catalogs and historical event snapshots.
-- New links are optional evidence. They never change acceptance or operational decisions.
create table public.calibration_laboratories (
 id uuid primary key,company_id uuid not null references public.companies(id),name text not null,
 data jsonb not null,created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create unique index laboratory_company_name on public.calibration_laboratories(company_id,lower(btrim(name)));
create table public.reference_standards (
 id uuid primary key,company_id uuid not null references public.companies(id),name text not null,serial text not null,
 data jsonb not null,created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create unique index standard_company_serial on public.reference_standards(company_id,lower(btrim(serial)));
create table public.standard_certificates (
 id uuid primary key,standard_id uuid not null references public.reference_standards(id),company_id uuid not null references public.companies(id),
 version integer not null check(version>0),number text not null,calibration_date date not null,valid_until date,
 issuer_laboratory_id uuid references public.calibration_laboratories(id),supersedes_id uuid references public.standard_certificates(id),
 attachment_path text not null default '',data jsonb not null,created_by uuid not null,created_at timestamptz not null default now(),
 unique(standard_id,version),check(valid_until is null or valid_until>=calibration_date)
);
create unique index standard_certificate_identity on public.standard_certificates(standard_id,lower(btrim(number)),calibration_date);
create index standard_certificate_company on public.standard_certificates(company_id);
create index standard_certificate_issuer on public.standard_certificates(issuer_laboratory_id);
create index standard_certificate_supersedes on public.standard_certificates(supersedes_id);
create unique index standard_certificate_file on public.standard_certificates(attachment_path) where attachment_path<>'';
create table public.event_traceability (
 event_id uuid primary key references public.metrological_events(id),company_id uuid not null references public.companies(id),
 laboratory_id uuid references public.calibration_laboratories(id),snapshot jsonb not null
);
create index event_traceability_company on public.event_traceability(company_id);
create index event_traceability_laboratory on public.event_traceability(laboratory_id);
create table public.event_standard_links (
 event_id uuid not null references public.metrological_events(id),certificate_id uuid not null references public.standard_certificates(id),
 company_id uuid not null references public.companies(id),usage text not null default '',primary key(event_id,certificate_id)
);
create index event_standard_certificate on public.event_standard_links(certificate_id);
create index event_standard_company on public.event_standard_links(company_id);

alter table public.calibration_laboratories enable row level security;
alter table public.reference_standards enable row level security;
alter table public.standard_certificates enable row level security;
alter table public.event_traceability enable row level security;
alter table public.event_standard_links enable row level security;
create policy laboratory_read on public.calibration_laboratories for select to authenticated using(private.can_access(company_id));
create policy standard_read on public.reference_standards for select to authenticated using(private.can_access(company_id));
create policy standard_certificate_read on public.standard_certificates for select to authenticated using(private.can_access(company_id));
create policy event_traceability_read on public.event_traceability for select to authenticated using(private.can_access(company_id));
create policy event_standard_read on public.event_standard_links for select to authenticated using(private.can_access(company_id));
revoke all on public.calibration_laboratories,public.reference_standards,public.standard_certificates,public.event_traceability,public.event_standard_links from public,anon,authenticated;
grant select on public.calibration_laboratories,public.reference_standards,public.standard_certificates,public.event_traceability,public.event_standard_links to authenticated;

create function private.save_traceability_record(kind text,payload jsonb)returns jsonb
language plpgsql security definer set search_path='' as $$
declare target uuid=(payload->>'id')::uuid;company uuid=(payload->>'companyId')::uuid;old_data jsonb;record jsonb;start_day date;end_day date;
begin
 if auth.uid() is null or not private.has_permission('manage_instruments') or not private.can_access(company) then raise exception 'Permission denied';end if;
 if target is null or jsonb_typeof(payload) is distinct from 'object' or octet_length(payload::text)>20000 or nullif(btrim(payload->>'name'),'') is null or char_length(payload->>'name')>200 then raise exception 'Invalid traceability record';end if;
 if not exists(select 1 from public.companies where id=company and (data->>'active')::boolean) then raise exception 'Active company required';end if;
 if kind='laboratory' then
  select data into old_data from public.calibration_laboratories where id=target for update;
  if old_data is not null and (old_data->>'companyId')::uuid<>company then raise exception 'Company cannot be changed';end if;
  if coalesce(payload->>'accreditation','') not in ('','sim','não') then raise exception 'Invalid accreditation answer';end if;
  start_day=nullif(payload->>'validFrom','')::date;end_day=nullif(payload->>'validUntil','')::date;
  if start_day is not null and end_day is not null and end_day<start_day then raise exception 'Invalid accreditation date interval';end if;
  record=jsonb_build_object('id',target,'companyId',company,'name',btrim(payload->>'name'),'cnpj',coalesce(payload->>'cnpj',''),'contact',coalesce(payload->>'contact',''),
   'accreditation',coalesce(payload->>'accreditation',''),'accreditationReference',coalesce(payload->>'accreditationReference',''),'scope',coalesce(payload->>'scope',''),
   'validFrom',coalesce(start_day::text,''),'validUntil',coalesce(end_day::text,''),'active',coalesce((payload->>'active')::boolean,true),'notes',coalesce(payload->>'notes',''));
  insert into public.calibration_laboratories(id,company_id,name,data)values(target,company,record->>'name',record)
  on conflict(id)do update set name=excluded.name,data=excluded.data,updated_at=now() where public.calibration_laboratories.company_id=excluded.company_id;
  if not found then raise exception 'Company cannot be changed';end if;
 elsif kind='standard' then
  select data into old_data from public.reference_standards where id=target for update;
  if old_data is not null and (old_data->>'companyId')::uuid<>company then raise exception 'Company cannot be changed';end if;
  if nullif(btrim(payload->>'serial'),'') is null or char_length(payload->>'serial')>200 then raise exception 'Standard identification required';end if;
  record=jsonb_build_object('id',target,'companyId',company,'name',btrim(payload->>'name'),'serial',btrim(payload->>'serial'),'model',coalesce(payload->>'model',''),
   'quantity',coalesce(payload->>'quantity',''),'range',coalesce(payload->>'range',''),'unit',coalesce(payload->>'unit',''),'active',coalesce((payload->>'active')::boolean,true),'notes',coalesce(payload->>'notes',''));
  insert into public.reference_standards(id,company_id,name,serial,data)values(target,company,record->>'name',record->>'serial',record)
  on conflict(id)do update set name=excluded.name,serial=excluded.serial,data=excluded.data,updated_at=now() where public.reference_standards.company_id=excluded.company_id;
  if not found then raise exception 'Company cannot be changed';end if;
 else raise exception 'Invalid catalog kind';end if;
 perform private.write_audit(case when kind='laboratory' then 'Cadastro/alteração de laboratório' else 'Cadastro/alteração de padrão' end,target::text,company,old_data,record,'Histórico dos eventos preservado');
 return record;
end$$;
create function public.save_calibration_laboratory(payload jsonb)returns jsonb language sql security invoker set search_path='' as $$select private.save_traceability_record('laboratory',payload)$$;
create function public.save_reference_standard(payload jsonb)returns jsonb language sql security invoker set search_path='' as $$select private.save_traceability_record('standard',payload)$$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('metrology-standard-certificates','metrology-standard-certificates',false,16777216,array['application/pdf','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/vnd.ms-excel']);
create policy standard_file_read on storage.objects for select to authenticated using(
 bucket_id='metrology-standard-certificates' and exists(select 1 from public.reference_standards s where s.id::text=split_part(storage.objects.name,'/',1))
);
create policy standard_file_insert on storage.objects for insert to authenticated with check(
 bucket_id='metrology-standard-certificates' and private.has_permission('manage_instruments')
 and exists(select 1 from public.reference_standards s where s.id::text=split_part(storage.objects.name,'/',1))
 and name ~ '^[a-f0-9-]{36}/[a-f0-9-]{36}/[a-f0-9-]{36}\.(pdf|xlsx|xls)$'
);
create policy standard_file_orphan_cleanup on storage.objects for delete to authenticated using(
 bucket_id='metrology-standard-certificates' and private.has_permission('manage_instruments') and owner_id=auth.uid()::text
 and exists(select 1 from public.reference_standards s where s.id::text=split_part(storage.objects.name,'/',1))
 and not exists(select 1 from public.standard_certificates c where c.attachment_path=storage.objects.name)
);

create function private.save_standard_certificate(payload jsonb)returns jsonb
language plpgsql security definer set search_path='' as $$
declare target uuid=(payload->>'id')::uuid;standard public.reference_standards%rowtype;company uuid;issuer uuid=nullif(payload->>'issuerLaboratoryId','')::uuid;
 supersedes uuid=nullif(payload->>'supersedesId','')::uuid;day date=nullif(payload->>'calibrationDate','')::date;expiry date=nullif(payload->>'validUntil','')::date;
 path text=coalesce(payload->>'attachmentPath','');record jsonb;file storage.objects%rowtype;next_version integer;
begin
 select * into standard from public.reference_standards where id=(payload->>'standardId')::uuid for update;
 if not found or auth.uid() is null or not private.has_permission('manage_instruments') or not private.can_access(standard.company_id) then raise exception 'Permission denied';end if;
 company=standard.company_id;
 if (payload->>'companyId')::uuid is distinct from company then raise exception 'Certificate company mismatch';end if;
 if exists(select 1 from public.standard_certificates where id=target) then raise exception 'Standard certificates are immutable; add a new version';end if;
 if target is null or day is null or expiry<day or octet_length(payload::text)>20000 or nullif(btrim(payload->>'number'),'') is null or char_length(payload->>'number')>200 or nullif(btrim(payload->>'issuer'),'') is null then raise exception 'Invalid standard certificate';end if;
 if issuer is not null and not exists(select 1 from public.calibration_laboratories where id=issuer and company_id=company) then raise exception 'Issuer laboratory company mismatch';end if;
 if supersedes is not null and not exists(select 1 from public.standard_certificates where id=supersedes and standard_id=standard.id) then raise exception 'Superseded certificate must belong to the same standard';end if;
 if path<>'' then
  if path !~ ('^'||standard.id::text||'/'||target::text||'/[a-f0-9-]{36}\.(pdf|xlsx|xls)$') then raise exception 'Invalid standard attachment path';end if;
  select * into file from storage.objects where bucket_id='metrology-standard-certificates' and name=path for share;
  if not found or file.owner_id is distinct from auth.uid()::text or coalesce(file.metadata->>'mimetype','') not in ('application/pdf','application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
   or (file.metadata->>'size')::bigint is distinct from (payload->>'sizeBytes')::bigint or coalesce((payload->>'sizeBytes')::bigint,0) not between 1 and 16777216 then raise exception 'Standard attachment metadata mismatch';end if;
 end if;
 select coalesce(max(version),0)+1 into next_version from public.standard_certificates where standard_id=standard.id;
 record=jsonb_build_object('id',target,'standardId',standard.id,'companyId',company,'number',btrim(payload->>'number'),'issuer',btrim(payload->>'issuer'),
  'issuerLaboratoryId',coalesce(issuer::text,''),'calibrationDate',day::text,'validUntil',coalesce(expiry::text,''),'scope',coalesce(payload->>'scope',''),
  'traceabilityEvidence',coalesce(payload->>'traceabilityEvidence',''),'attachmentPath',path,'attachmentName',case when path='' then '' else coalesce(payload->>'attachmentName','') end,
  'sizeBytes',case when path='' then 0 else (payload->>'sizeBytes')::bigint end,'version',next_version,'supersedesId',coalesce(supersedes::text,''),
  'createdAt',to_char(now() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),'createdBy',auth.uid());
 insert into public.standard_certificates(id,standard_id,company_id,version,number,calibration_date,valid_until,issuer_laboratory_id,supersedes_id,attachment_path,data,created_by)
 values(target,standard.id,company,next_version,record->>'number',day,expiry,issuer,supersedes,path,record,auth.uid());
 perform private.write_audit('Certificado do padrão registrado',target::text,company,null,record,'Nova versão; certificados anteriores preservados');
 return record;
end$$;
create function public.save_standard_certificate(payload jsonb)returns jsonb language sql security invoker set search_path='' as $$select private.save_standard_certificate(payload)$$;

create function private.traceability_validity(day date,start_day date,end_day date)returns text
language sql immutable set search_path='' as $$select case when day is null then 'data não informada' when start_day is null or end_day is null then 'validade não informada' when end_day<start_day then 'intervalo inválido' when day<start_day then 'posterior à calibração' when day>end_day then 'vencido na data' else 'válido na data' end$$;

-- Wrap the existing operation atomically, preserving all existing fields and decisions.
alter function private.save_metrological_event(jsonb,boolean) rename to save_metrological_event_phase2;
revoke all on function private.save_metrological_event_phase2(jsonb,boolean) from public,anon,authenticated;
create function private.save_metrological_event(payload jsonb,conclude boolean)returns jsonb
language plpgsql security definer set search_path='' as $$
declare master public.instruments%rowtype;lab public.calibration_laboratories%rowtype;cert public.standard_certificates%rowtype;
 standard public.reference_standards%rowtype;day date=nullif(payload->>'date','')::date;lab_id uuid=nullif(payload->>'laboratoryId','')::uuid;
 selections jsonb=coalesce(payload->'traceabilitySelections','[]'::jsonb);selection jsonb;standards jsonb='[]';lab_snapshot jsonb='null';snapshot jsonb;record jsonb;
begin
 select * into master from public.instruments where id=(payload->>'instrumentId')::uuid for update;
 if not found or auth.uid() is null or not private.has_permission('register_event') or not private.can_access(master.company_id) then raise exception 'Permission denied';end if;
 if jsonb_typeof(selections) is distinct from 'array' or jsonb_array_length(selections)>100 or octet_length(selections::text)>200000 then raise exception 'Invalid standard selections';end if;
 if (select count(distinct value->>'certificateId') from jsonb_array_elements(selections))<>jsonb_array_length(selections) then raise exception 'Duplicate or missing standard selection';end if;
 if lab_id is not null then
  select * into lab from public.calibration_laboratories where id=lab_id and company_id=master.company_id for share;
  if not found then raise exception 'Laboratory company mismatch';end if;
  lab_snapshot=jsonb_build_object('record',lab.data,'validity',case when lab.data->>'accreditation'='não' then 'não acreditado' when coalesce(lab.data->>'accreditation','')<>'sim' then 'acreditação não informada' else private.traceability_validity(day,nullif(lab.data->>'validFrom','')::date,nullif(lab.data->>'validUntil','')::date) end);
 end if;
 for selection in select value from jsonb_array_elements(selections)loop
  if char_length(coalesce(selection->>'usage',''))>2000 then raise exception 'Standard usage too long';end if;
  select * into cert from public.standard_certificates where id=(selection->>'certificateId')::uuid and company_id=master.company_id for share;
  if not found then raise exception 'Standard certificate company mismatch';end if;
  select * into standard from public.reference_standards where id=cert.standard_id and company_id=master.company_id for share;
  if not found then raise exception 'Standard company mismatch';end if;
  standards=standards||jsonb_build_array(jsonb_build_object('standard',standard.data,'certificate',cert.data,'validity',private.traceability_validity(day,cert.calibration_date,cert.valid_until),'usage',coalesce(selection->>'usage','')));
 end loop;
 snapshot=jsonb_build_object('eventDate',coalesce(day::text,''),'capturedAt',to_char(now() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),'laboratory',lab_snapshot,'standards',standards);
 record=private.save_metrological_event_phase2((payload-'traceability')||jsonb_build_object('laboratoryId',coalesce(lab_id::text,''),'traceabilitySelections',selections,'traceability',snapshot),conclude);
 insert into public.event_traceability(event_id,company_id,laboratory_id,snapshot)values((record->>'id')::uuid,master.company_id,lab_id,snapshot)
 on conflict(event_id)do update set laboratory_id=excluded.laboratory_id,snapshot=excluded.snapshot;
 delete from public.event_standard_links where event_id=(record->>'id')::uuid;
 for selection in select value from jsonb_array_elements(selections)loop
  insert into public.event_standard_links(event_id,certificate_id,company_id,usage)values((record->>'id')::uuid,(selection->>'certificateId')::uuid,master.company_id,coalesce(selection->>'usage',''));
 end loop;
 return record;
end$$;

revoke all on function private.save_traceability_record(text,jsonb),private.save_standard_certificate(jsonb),private.traceability_validity(date,date,date),private.save_metrological_event(jsonb,boolean) from public,anon;
revoke all on function public.save_calibration_laboratory(jsonb),public.save_reference_standard(jsonb),public.save_standard_certificate(jsonb) from public,anon;
grant execute on function private.save_traceability_record(text,jsonb),private.save_standard_certificate(jsonb),private.save_metrological_event(jsonb,boolean) to authenticated;
grant execute on function public.save_calibration_laboratory(jsonb),public.save_reference_standard(jsonb),public.save_standard_certificate(jsonb) to authenticated;
