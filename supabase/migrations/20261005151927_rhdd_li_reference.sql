-- Official LI snapshots are private reference data. Proposed blank-row numbers do not release instruments.
create table public.li_references (
 prefix text primary key, document text not null, source_name text not null, source_hash text not null,
 original_max integer not null check(original_max>=0),planned_max integer not null check(planned_max>=original_max),
 next_number integer not null check(next_number>planned_max),next_row integer not null check(next_row>7),
 created_by uuid not null references auth.users(id),created_at timestamptz not null default now()
);
create table public.li_entries (
 id uuid primary key default gen_random_uuid(),reference_prefix text not null references public.li_references(prefix),
 row_number integer not null check(row_number>7),sequence_number integer not null check(sequence_number>0),
 code text not null unique,company_id uuid not null references public.companies(id),origin text not null check(origin in('original','planned','new')),
 source_values jsonb not null check(jsonb_typeof(source_values)='array'),instrument_id uuid references public.instruments(id),
 unique(reference_prefix,row_number),unique(reference_prefix,sequence_number)
);
create table public.li_certificate_preparations (
 id uuid primary key,company_id uuid not null references public.companies(id),entry_id uuid not null references public.li_entries(id),
 created_by uuid not null references auth.users(id),request_hash text not null,result jsonb not null,created_at timestamptz not null default now()
);
create index li_reference_actor on public.li_references(created_by);
create index li_entry_company_row on public.li_entries(company_id,row_number);
create index li_entry_instrument on public.li_entries(instrument_id);
create index li_preparation_company on public.li_certificate_preparations(company_id);
create index li_preparation_entry on public.li_certificate_preparations(entry_id);
create index li_preparation_actor on public.li_certificate_preparations(created_by);
alter table public.li_references enable row level security;
alter table public.li_entries enable row level security;
alter table public.li_certificate_preparations enable row level security;
revoke all on public.li_references,public.li_entries,public.li_certificate_preparations from public,anon,authenticated;
grant select on public.li_references,public.li_entries,public.li_certificate_preparations to authenticated;
create policy li_reference_read on public.li_references for select to authenticated using(private.has_permission('read'));
create policy li_entry_read on public.li_entries for select to authenticated using(private.can_access(company_id));
create policy li_preparation_read on public.li_certificate_preparations for select to authenticated using(private.can_access(company_id) and private.has_permission('register_event'));
create function private.li_entry_json(e public.li_entries)returns jsonb language sql immutable set search_path='' as $$
 select jsonb_build_object('id',e.id,'row',e.row_number,'number',e.sequence_number,'code',e.code,'companyId',e.company_id,'origin',e.origin,'values',e.source_values,'instrumentId',e.instrument_id)
$$;
create function private.register_li_reference(payload jsonb)returns jsonb language plpgsql security definer set search_path='' as $$
declare ref public.li_references%rowtype;item jsonb;number_value integer;code_value text;last_original integer=0;planned integer=0;last_row integer=7;origin_value text;company uuid;prefix_value text=payload->>'prefix';
begin
 if not private.has_permission('manage_instruments') or not private.has_permission('manage_companies') or not exists(select 1 from private.members where user_id=auth.uid() and active and company_id is null) then raise exception 'Permission denied';end if;
 if prefix_value is null or char_length(prefix_value) not between 10 and 120 or nullif(payload->>'sourceHash','') is null or nullif(payload->>'sourceName','') is null or jsonb_typeof(payload->'entries') is distinct from 'array' or jsonb_array_length(payload->'entries') not between 1 and 10000 or octet_length(payload::text)>8000000 then raise exception 'Invalid LI reference';end if;
 perform pg_advisory_xact_lock(hashtextextended(prefix_value,0));
 select * into ref from public.li_references where prefix=prefix_value;
 if found then
  if ref.source_hash<>payload->>'sourceHash' then raise exception 'LI reference already registered; preserve existing sequence and history';end if;
  return jsonb_build_object('prefix',prefix_value,'alreadyRegistered',true);
 end if;
 for item in select value from jsonb_array_elements(payload->'entries')loop
  if nullif(item->'values'->>1,'') is not null then
   code_value=item->'values'->>1;
   if left(code_value,length(prefix_value))<>prefix_value or substring(code_value from length(prefix_value)+1)!~'^[0-9]+$' then raise exception 'Invalid original code';end if;
   last_original=greatest(last_original,substring(code_value from length(prefix_value)+1)::integer);
  end if;
 end loop;
 planned=last_original;
 insert into public.li_references values(prefix_value,payload->>'document',left(payload->>'sourceName',255),payload->>'sourceHash',last_original,last_original,last_original+1,8,auth.uid(),now());
 for item in select value from jsonb_array_elements(payload->'entries') order by (value->>'row')::integer loop
  if (item->>'row')::integer<=last_row or jsonb_typeof(item->'values') is distinct from 'array' or jsonb_array_length(item->'values')<13 or nullif(item->'values'->>2,'') is null then raise exception 'Invalid LI row';end if;
  last_row=(item->>'row')::integer;company=(item->>'companyId')::uuid;
  if not private.can_access(company) or not exists(select 1 from public.companies c where c.id=company and upper(btrim(c.name))=upper(btrim(item->'values'->>11)) and (c.data->>'active')::boolean) then raise exception 'LI company mismatch';end if;
  if nullif(item->'values'->>1,'') is not null then number_value=substring(item->'values'->>1 from length(prefix_value)+1)::integer;origin_value='original';else planned=planned+1;number_value=planned;origin_value='planned';end if;
  code_value=prefix_value||lpad(number_value::text,greatest(3,length(number_value::text)),'0');
  if number_value<1 or code_value is distinct from item->>'code' or number_value is distinct from (item->>'number')::integer then raise exception 'Invalid LI sequence proposal';end if;
  insert into public.li_entries(reference_prefix,row_number,sequence_number,code,company_id,origin,source_values)values(prefix_value,last_row,number_value,code_value,company,origin_value,item->'values');
 end loop;
 update public.li_references set planned_max=planned,next_number=planned+1,next_row=last_row+1 where prefix=prefix_value;
 perform private.write_audit('Referência LI registrada',prefix_value,null,null,jsonb_build_object('sourceHash',payload->>'sourceHash','originalMax',last_original,'plannedMax',planned,'rows',jsonb_array_length(payload->'entries')),'Sequência das linhas originais preservada');
 return jsonb_build_object('prefix',prefix_value,'originalMax',last_original,'plannedMax',planned,'nextNumber',planned+1,'nextRow',last_row+1);
end$$;
create function public.register_li_reference(payload jsonb)returns jsonb language sql security invoker set search_path='' as $$select private.register_li_reference(payload)$$;

create function private.prepare_li_certificate(payload jsonb)returns jsonb language plpgsql security definer set search_path='' as $$
declare ref public.li_references%rowtype;entry public.li_entries%rowtype;cached public.li_certificate_preparations%rowtype;company uuid=(payload->>'companyId')::uuid;request_id uuid=(payload->>'requestId')::uuid;fingerprint text=md5(payload::text);instrument jsonb;event jsonb;result jsonb;draft jsonb;code_value text;
begin
 if not private.has_permission('manage_instruments') or not private.has_permission('register_event') or not private.can_access(company) then raise exception 'Permission denied';end if;
 if request_id is null or jsonb_typeof(payload->'instrument') is distinct from 'object' or jsonb_typeof(payload->'event') is distinct from 'object' or octet_length(payload::text)>200000 then raise exception 'Invalid certificate preparation';end if;
 perform pg_advisory_xact_lock(hashtextextended(request_id::text,0));
 select * into cached from public.li_certificate_preparations where id=request_id;
 if found then
  if cached.created_by<>auth.uid() or cached.company_id<>company or cached.request_hash<>fingerprint then raise exception 'Certificate request does not match the original';end if;
  return cached.result;
 end if;
 if not exists(select 1 from public.companies c where c.id=company and (c.data->>'active')::boolean) then raise exception 'Active company required';end if;
 select * into ref from public.li_references where prefix=payload->>'prefix' for update;
 if not found then raise exception 'Register the official LI first';end if;
 if nullif(payload->>'entryId','') is not null then
  select * into entry from public.li_entries where id=(payload->>'entryId')::uuid and reference_prefix=ref.prefix for update;
  if not found or entry.company_id<>company or not private.can_access(entry.company_id) then raise exception 'LI entry not accessible for this company';end if;
 else
  if ref.next_number is distinct from (payload->>'expectedNumber')::integer or ref.next_row is distinct from (payload->>'expectedRow')::integer then raise exception 'A sequência avançou. Atualize a prévia antes de confirmar.';end if;
  code_value=ref.prefix||lpad(ref.next_number::text,greatest(3,length(ref.next_number::text)),'0');
  if jsonb_typeof(payload->'values') is distinct from 'array' or jsonb_array_length(payload->'values')<>13 then raise exception 'Invalid LI cells';end if;
  insert into public.li_entries(reference_prefix,row_number,sequence_number,code,company_id,origin,source_values) values(ref.prefix,ref.next_row,ref.next_number,code_value,company,'new',payload->'values') returning * into entry;
  update public.li_references set next_number=next_number+1,next_row=next_row+1 where prefix=ref.prefix;
 end if;
 if entry.instrument_id is not null then select i.data into instrument from public.instruments i where i.id=entry.instrument_id and i.company_id=company;end if;
 if instrument is null then
  if (select count(*) from public.instruments i where lower(btrim(i.code))=lower(entry.code) or lower(btrim(i.data->>'liNumber'))=lower(entry.code))>1 then raise exception 'Ambiguous instrument link; review the LI code';end if;
  select i.data into instrument from public.instruments i where lower(btrim(i.code))=lower(entry.code) or lower(btrim(i.data->>'liNumber'))=lower(entry.code);
  if instrument is not null and (instrument->>'ownerCompanyId')::uuid<>company then raise exception 'LI code belongs to another company';end if;
 end if;
 if instrument is null then
  draft=payload->'instrument'||jsonb_build_object('id',gen_random_uuid(),'code',entry.code,'liNumber',entry.code,'ownerCompanyId',company,'userCompanyId','','operationalStatus','fora de uso','registrationStatus','ativo','lastControl','','nextControl','','capabilities','[]'::jsonb,'liSource',private.li_entry_json(entry));
  instrument=private.save_instrument(draft,'Cadastro assistido por certificado',ref.source_name||' • LISTA, linha '||entry.row_number);
 end if;
 if instrument->'liSource' is null then instrument=instrument||jsonb_build_object('liSource',private.li_entry_json(entry));update public.instruments set data=instrument where id=(instrument->>'id')::uuid;end if;
 update public.li_entries set instrument_id=(instrument->>'id')::uuid where id=entry.id returning * into entry;
 draft=payload->'event'||jsonb_build_object('id',gen_random_uuid(),'instrumentId',instrument->>'id','workflow','análise em andamento','decision','','rationale','','attachmentPath','','createdAt',now());
 event=private.save_metrological_event(draft,false);
 result=jsonb_build_object('entry',private.li_entry_json(entry),'instrument',instrument,'event',event);
 insert into public.li_certificate_preparations values(request_id,company,entry.id,auth.uid(),fingerprint,result,now());
 perform private.write_audit('Prévia LI e certificado confirmada',entry.code,company,null,jsonb_build_object('row',entry.row_number,'eventId',event->>'id','requestId',request_id,'cells',payload->'values'),'Rascunho sem liberação operacional');
 return result;
end$$;
create function public.prepare_li_certificate(payload jsonb)returns jsonb language sql security invoker set search_path='' as $$select private.prepare_li_certificate(payload)$$;
revoke all on function private.li_entry_json(public.li_entries) from public,anon,authenticated;
revoke all on function private.register_li_reference(jsonb),public.register_li_reference(jsonb),private.prepare_li_certificate(jsonb),public.prepare_li_certificate(jsonb) from public,anon;
grant execute on function private.register_li_reference(jsonb),public.register_li_reference(jsonb),private.prepare_li_certificate(jsonb),public.prepare_li_certificate(jsonb) to authenticated;
