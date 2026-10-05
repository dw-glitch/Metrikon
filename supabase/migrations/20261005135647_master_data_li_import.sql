-- Independent CCP CONSAG only. Catalogs and imports never change metrological decisions.
create table public.instrument_references (
 id uuid primary key, company_id uuid not null references public.companies(id),
 kind text not null check(kind in ('type','area','sector','process','location')),
 name text not null check(char_length(btrim(name)) between 1 and 150),
 notes text not null default '', active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index instrument_references_name on public.instrument_references(company_id,kind,lower(btrim(name)));
create index instrument_references_company_kind on public.instrument_references(company_id,kind,active);
alter table public.instrument_references enable row level security;
revoke all on public.instrument_references from public,anon,authenticated;
grant select on public.instrument_references to authenticated;
create policy reference_read on public.instrument_references for select to authenticated using(private.can_access(company_id));

create function private.save_instrument_reference(payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare target uuid=(payload->>'id')::uuid;company uuid=(payload->>'companyId')::uuid;old_row public.instrument_references%rowtype;new_row public.instrument_references%rowtype;
begin
 if not private.has_permission('manage_instruments') or not private.can_access(company) then raise exception 'Permission denied';end if;
 select * into old_row from public.instrument_references where id=target for update;
 if old_row.id is not null and old_row.company_id<>company then raise exception 'Reference company cannot be reassigned';end if;
 if not exists(select 1 from public.companies c where c.id=company and coalesce((c.data->>'active')::boolean,false)) then raise exception 'Active company required';end if;
 insert into public.instrument_references(id,company_id,kind,name,notes,active)
 values(target,company,payload->>'kind',btrim(payload->>'name'),left(coalesce(payload->>'notes',''),2000),coalesce((payload->>'active')::boolean,true))
 on conflict(id)do update set kind=excluded.kind,name=excluded.name,notes=excluded.notes,active=excluded.active,updated_at=now()
 returning * into new_row;
 perform private.write_audit('Cadastro auxiliar de instrumento',target::text,company,to_jsonb(old_row),to_jsonb(new_row),'');
 return to_jsonb(new_row);
end$$;
create function public.save_instrument_reference(payload jsonb) returns jsonb language sql security invoker set search_path='' as $$select private.save_instrument_reference(payload)$$;

create table public.instrument_assets (
 id uuid primary key,instrument_id uuid not null references public.instruments(id),
 name text not null check(char_length(name) between 1 and 255),
 mime_type text not null check(mime_type in ('application/pdf','image/jpeg','image/png','image/webp')),
 size_bytes bigint not null check(size_bytes between 1 and 10485760),
 storage_path text not null unique,created_by uuid not null references auth.users(id),created_at timestamptz not null default now()
);
create index instrument_assets_instrument_date on public.instrument_assets(instrument_id,created_at desc);
alter table public.instrument_assets enable row level security;
revoke all on public.instrument_assets from public,anon,authenticated;
grant select on public.instrument_assets to authenticated;
create policy instrument_asset_read on public.instrument_assets for select to authenticated using(exists(select 1 from public.instruments i where i.id=instrument_id));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('metrology-instrument-assets','metrology-instrument-assets',false,10485760,array['application/pdf','image/jpeg','image/png','image/webp']);
create policy instrument_asset_storage_read on storage.objects for select to authenticated using(bucket_id='metrology-instrument-assets' and exists(select 1 from public.instruments i where i.id::text=split_part(name,'/',1)));
create policy instrument_asset_storage_insert on storage.objects for insert to authenticated with check(
 bucket_id='metrology-instrument-assets' and private.has_permission('manage_instruments')
 and exists(select 1 from public.instruments i where i.id::text=split_part(name,'/',1))
 and name ~ '^[a-f0-9-]{36}/[a-f0-9-]{36}\.(pdf|jpg|png|webp)$');
-- Only the uploader can remove an unlinked failed upload. Registered documents have no deletion policy.
create policy instrument_asset_orphan_cleanup on storage.objects for delete to authenticated using(
 bucket_id='metrology-instrument-assets' and owner_id=(select auth.uid())::text and private.has_permission('manage_instruments')
 and exists(select 1 from public.instruments i where i.id::text=split_part(name,'/',1))
 and not exists(select 1 from public.instrument_assets a where a.storage_path=storage.objects.name));
grant delete on storage.objects to authenticated;

create function private.register_instrument_asset(payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare target_instrument uuid=(payload->>'instrumentId')::uuid;company uuid;result public.instrument_assets%rowtype;object_row storage.objects%rowtype;
begin
 select company_id into company from public.instruments where id=target_instrument;
 if company is null or not private.can_access(company) or not private.has_permission('manage_instruments') then raise exception 'Permission denied';end if;
 if (payload->>'storagePath') !~ ('^'||target_instrument::text||'/[a-f0-9-]{36}\.(pdf|jpg|png|webp)$') then raise exception 'Invalid instrument asset path';end if;
 select * into object_row from storage.objects where bucket_id='metrology-instrument-assets' and name=payload->>'storagePath' for update;
 if not found or object_row.owner_id is distinct from auth.uid()::text then raise exception 'Stored file belonging to the uploader required';end if;
 if object_row.metadata->>'mimetype' is distinct from payload->>'mimeType' or (object_row.metadata->>'size')::bigint is distinct from (payload->>'sizeBytes')::bigint then raise exception 'Stored file metadata mismatch';end if;
 insert into public.instrument_assets(id,instrument_id,name,mime_type,size_bytes,storage_path,created_by)
 values((payload->>'id')::uuid,target_instrument,left(payload->>'name',255),payload->>'mimeType',(payload->>'sizeBytes')::bigint,payload->>'storagePath',auth.uid()) returning * into result;
 perform private.write_audit('Documento cadastral anexado',target_instrument::text,company,null,to_jsonb(result),'');
 return to_jsonb(result);
end$$;
create function public.register_instrument_asset(payload jsonb)returns jsonb language sql security invoker set search_path='' as $$select private.register_instrument_asset(payload)$$;

create table public.instrument_import_batches (
 id uuid primary key,company_id uuid not null references public.companies(id),created_by uuid not null references auth.users(id),
 source_name text not null,request_hash text not null,result jsonb not null,created_at timestamptz not null default now()
);
create index instrument_import_company_date on public.instrument_import_batches(company_id,created_at desc);
create index instrument_import_actor on public.instrument_import_batches(created_by);
alter table public.instrument_import_batches enable row level security;
revoke all on public.instrument_import_batches from public,anon,authenticated;
grant select on public.instrument_import_batches to authenticated;
create policy import_batch_read on public.instrument_import_batches for select to authenticated using(private.can_access(company_id) and private.has_permission('manage_instruments'));

create function private.import_instruments(rows jsonb,target_company uuid,source_name text,batch_id uuid)returns jsonb
language plpgsql security definer set search_path='' as $$
declare cached public.instrument_import_batches%rowtype;item jsonb;draft jsonb;record jsonb;code_value text;row_number integer;results jsonb='[]';created_count integer=0;skipped_count integer=0;request_fingerprint text;
begin
 if not private.has_permission('manage_instruments') or not private.can_access(target_company) then raise exception 'Permission denied';end if;
 if not exists(select 1 from public.companies c where c.id=target_company and coalesce((c.data->>'active')::boolean,false)) then raise exception 'Active company required';end if;
 if batch_id is null or jsonb_typeof(rows) is distinct from 'array' or jsonb_array_length(rows) not between 1 and 500 or octet_length(rows::text)>4000000 or source_name is null or char_length(source_name) not between 1 and 255 then raise exception 'Invalid import batch';end if;
 request_fingerprint=md5(rows::text||target_company::text||source_name);
 perform pg_advisory_xact_lock(hashtextextended(batch_id::text,0));
 select * into cached from public.instrument_import_batches where id=batch_id;
 if found then
  if cached.created_by<>auth.uid() or cached.company_id<>target_company or cached.request_hash<>request_fingerprint then raise exception 'Import request does not match the original batch';end if;
  return cached.result;
 end if;
 for item in select value from jsonb_array_elements(rows)loop
  draft=item->'instrument';row_number=(item->>'rowNumber')::integer;code_value=btrim(draft->>'code');
  if row_number is null or row_number<1 or jsonb_typeof(draft) is distinct from 'object' or code_value is null or char_length(code_value) not between 1 and 150 or nullif(btrim(draft->>'description'),'') is null or char_length(draft->>'description')>2000 or (draft->>'ownerCompanyId')::uuid is distinct from target_company then raise exception 'Invalid import row %',row_number;end if;
  if exists(select 1 from public.instruments where lower(btrim(code))=lower(code_value)) then
   skipped_count=skipped_count+1;results=results||jsonb_build_array(jsonb_build_object('rowNumber',row_number,'code',code_value,'outcome','duplicate'));continue;
  end if;
  -- A new server UUID prevents an imported ID from updating another instrument.
  -- All operational fields and dates remain governed by the existing save/decision engine.
  draft=draft||jsonb_build_object('id',gen_random_uuid(),'code',code_value,'ownerCompanyId',target_company,'userCompanyId','',
   'operationalStatus','fora de uso','lastControl','','nextControl','','registrationStatus','ativo',
   'importReference',jsonb_build_object('file',source_name,'row',row_number,'importedAt',now()));
  if jsonb_typeof(draft->'capabilities') is distinct from 'array' then raise exception 'Invalid measurement capabilities';end if;
  draft=jsonb_set(draft,'{capabilities}',coalesce((select jsonb_agg(cap.value||jsonb_build_object('id',gen_random_uuid()) order by cap.ordinality) from jsonb_array_elements(draft->'capabilities') with ordinality cap(value,ordinality)),'[]'::jsonb));
  begin
   record=private.save_instrument(draft,'Importação LI confirmada',source_name||' • linha '||row_number);
   created_count=created_count+1;results=results||jsonb_build_array(jsonb_build_object('rowNumber',row_number,'code',code_value,'outcome','imported','id',record->>'id'));
  exception when unique_violation then
   if not exists(select 1 from public.instruments where lower(btrim(code))=lower(code_value)) then raise;end if;
   skipped_count=skipped_count+1;results=results||jsonb_build_array(jsonb_build_object('rowNumber',row_number,'code',code_value,'outcome','duplicate'));
  end;
 end loop;
 record=jsonb_build_object('created',created_count,'skipped',skipped_count,'rows',results,'batchId',batch_id);
 insert into public.instrument_import_batches values(batch_id,target_company,auth.uid(),source_name,request_fingerprint,record,now());
 perform private.write_audit('Importação LI confirmada',batch_id::text,target_company,null,record,source_name);
 return record;
end$$;
create function public.import_instruments(rows jsonb,target_company uuid,source_name text,batch_id uuid)returns jsonb language sql security invoker set search_path='' as $$select private.import_instruments(rows,target_company,source_name,batch_id)$$;

revoke all on function private.save_instrument_reference(jsonb),private.register_instrument_asset(jsonb),private.import_instruments(jsonb,uuid,text,uuid) from public,anon;
revoke all on function public.save_instrument_reference(jsonb),public.register_instrument_asset(jsonb),public.import_instruments(jsonb,uuid,text,uuid) from public,anon;
grant execute on function private.save_instrument_reference(jsonb),private.register_instrument_asset(jsonb),private.import_instruments(jsonb,uuid,text,uuid) to authenticated;
grant execute on function public.save_instrument_reference(jsonb),public.register_instrument_asset(jsonb),public.import_instruments(jsonb,uuid,text,uuid) to authenticated;

-- Preview sees only instruments visible to the caller. Commit still enforces the global code index.
create function public.check_import_codes(codes text[])returns text[] language sql stable security invoker set search_path='' as $$
 select coalesce(array_agg(i.code),'{}'::text[]) from public.instruments i
 where lower(btrim(i.code))=any(array(select lower(btrim(x)) from unnest(codes) x limit 500))
$$;
revoke all on function public.check_import_codes(text[]) from public,anon;
grant execute on function public.check_import_codes(text[]) to authenticated;
create index instrument_assets_actor on public.instrument_assets(created_by);
