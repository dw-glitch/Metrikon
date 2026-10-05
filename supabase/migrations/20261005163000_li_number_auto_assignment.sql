-- Instrument registration follows the official LI. There is no user-managed internal instrument code.
-- public.instruments.code remains only as a compatibility column and mirrors the official LI number.
create or replace function private.save_instrument(payload jsonb,change_reason text,change_evidence text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
 target uuid=(payload->>'id')::uuid;
 company uuid=(payload->>'ownerCompanyId')::uuid;
 old_value jsonb;
 old_months integer;
 new_months integer;
 cap jsonb;
 current_data jsonb;
 existing_li text;
 li_ref public.li_references%rowtype;
 li_entry public.li_entries%rowtype;
 li_entry_id uuid;
 li_code text;
 li_values jsonb;
 company_name text;
 source_info jsonb;
begin
 if not private.has_permission('manage_instruments') or not private.can_access(company) then raise exception 'Permission denied';end if;
 if nullif(btrim(payload->>'description'),'') is null then raise exception 'Instrument description required';end if;
 if not exists(select 1 from public.companies c where c.id=company and coalesce((c.data->>'active')::boolean,false)) then raise exception 'Active company required';end if;

 select i.data into old_value from public.instruments i where i.id=target for update;
 if old_value is not null and not private.can_access((old_value->>'ownerCompanyId')::uuid) then raise exception 'Permission denied';end if;

 if old_value is null then
  existing_li=nullif(btrim(payload->>'liNumber'),'');
  if existing_li is not null then
   select * into li_entry from public.li_entries
   where lower(btrim(code))=lower(existing_li)
   for update;
   if not found then raise exception 'LI number must come from the registered official LI';end if;
   if li_entry.company_id<>company then raise exception 'LI number belongs to another company';end if;
   if li_entry.instrument_id is not null then raise exception 'LI number is already linked to an instrument';end if;
   li_code=li_entry.code;
   source_info=private.li_entry_json(li_entry)||jsonb_build_object('instrumentId',target);
  else
   if (select count(*) from public.li_references)<>1 then raise exception 'Exactly one official LI reference is required for automatic numbering';end if;
   select * into li_ref from public.li_references order by created_at desc limit 1 for update;
   select name into company_name from public.companies where id=company;
   li_code=li_ref.prefix||lpad(li_ref.next_number::text,greatest(3,length(li_ref.next_number::text)),'0');
   li_entry_id=gen_random_uuid();
   li_values=jsonb_build_array(
    '',li_code,coalesce(payload->>'description',''),coalesce(payload->>'serial',''),coalesce(payload->>'model',''),
    coalesce(payload->>'measurementRange',''),'','','',coalesce(payload->>'periodicityMonths',''),'',
    coalesce(company_name,''),'','','','',''
   );
   source_info=jsonb_build_object(
    'id',li_entry_id,'row',li_ref.next_row,'number',li_ref.next_number,'code',li_code,
    'companyId',company,'origin','new','values',li_values,'instrumentId',target
   );
  end if;
  current_data=payload||jsonb_build_object(
   'code',li_code,'liNumber',li_code,'liSource',source_info,
   'operationalStatus','fora de uso','lastControl','','nextControl','','metrologicalStatus','em análise'
  );
 else
  current_data=payload||jsonb_build_object(
   'code',old_value->>'code','liNumber',old_value->>'liNumber','liSource',old_value->'liSource',
   'operationalStatus',coalesce(old_value->>'operationalStatus','fora de uso'),
   'lastControl',coalesce(old_value->>'lastControl',''),
   'nextControl',coalesce(old_value->>'nextControl',''),
   'metrologicalStatus',coalesce(old_value->>'metrologicalStatus','em análise')
  );
 end if;

 old_months=(old_value->>'periodicityMonths')::integer;
 new_months=(current_data->>'periodicityMonths')::integer;
 if new_months is not null and new_months<1 then raise exception 'Periodicity must be positive';end if;
 if old_months is distinct from new_months and old_value is not null and (nullif(btrim(change_reason),'') is null or nullif(btrim(change_evidence),'') is null) then raise exception 'Periodicity change requires reason and evidence';end if;
 if jsonb_typeof(current_data->'capabilities')<>'array' then raise exception 'Capabilities must be an array';end if;

 insert into public.instruments(id,code,company_id,registration_status,operational_status,serial,tag,next_control,data)
 values(target,current_data->>'liNumber',company,current_data->>'registrationStatus',current_data->>'operationalStatus',coalesce(current_data->>'serial',''),coalesce(current_data->>'tag',''),nullif(current_data->>'nextControl','')::date,current_data)
 on conflict(id)do update set
  code=excluded.code,company_id=excluded.company_id,registration_status=excluded.registration_status,
  serial=excluded.serial,tag=excluded.tag,data=excluded.data,updated_at=now();

 if old_value is null then
  if existing_li is not null then
   update public.li_entries set instrument_id=target where id=li_entry.id;
  else
   insert into public.li_entries(id,reference_prefix,row_number,sequence_number,code,company_id,origin,source_values,instrument_id)
   values(li_entry_id,li_ref.prefix,li_ref.next_row,li_ref.next_number,li_code,company,'new',li_values,target);
   update public.li_references set
    planned_max=greatest(planned_max,next_number),
    next_number=next_number+1,
    next_row=next_row+1
   where prefix=li_ref.prefix;
  end if;
 elsif coalesce(old_value->'liSource'->>'origin','')='new' then
  select * into li_entry from public.li_entries where instrument_id=target for update;
  if found then
   li_values=li_entry.source_values;
   li_values=jsonb_set(li_values,'{2}',to_jsonb(coalesce(current_data->>'description','')),false);
   li_values=jsonb_set(li_values,'{3}',to_jsonb(coalesce(current_data->>'serial','')),false);
   li_values=jsonb_set(li_values,'{4}',to_jsonb(coalesce(current_data->>'model','')),false);
   li_values=jsonb_set(li_values,'{5}',to_jsonb(coalesce(current_data->>'measurementRange','')),false);
   li_values=jsonb_set(li_values,'{9}',to_jsonb(coalesce(current_data->>'periodicityMonths','')),false);
   select name into company_name from public.companies where id=company;
   li_values=jsonb_set(li_values,'{11}',to_jsonb(coalesce(company_name,'')),false);
   update public.li_entries set source_values=li_values where id=li_entry.id;
   current_data=jsonb_set(current_data,'{liSource,values}',li_values,true);
   update public.instruments set data=current_data where id=target;
  end if;
 end if;

 delete from public.instrument_measurement_capabilities where instrument_id=target;
 for cap in select value from jsonb_array_elements(current_data->'capabilities')loop
  if nullif(btrim(cap->>'quantity'),'') is null or nullif(btrim(cap->>'unit'),'') is null or private.parse_decimal(cap->>'min') is null or private.parse_decimal(cap->>'max') is null then raise exception 'Invalid measurement capability';end if;
  insert into public.instrument_measurement_capabilities(id,instrument_id,quantity,unit,min_value,max_value,range_type)
  values((cap->>'id')::uuid,target,cap->>'quantity',cap->>'unit',private.parse_decimal(cap->>'min'),private.parse_decimal(cap->>'max'),coalesce(cap->>'rangeType',''));
 end loop;

 if old_months is distinct from new_months and old_value is not null then
  insert into public.instrument_periodicity_history(instrument_id,previous_months,new_months,reason,evidence,actor)
  values(target,old_months,new_months,change_reason,change_evidence,auth.uid());
 end if;
 perform private.refresh_search(target);
 perform private.write_audit(case when old_value is null then 'Cadastro de instrumento' else 'Alteração de instrumento' end,target::text,company,old_value,current_data,
  case when old_value is null then 'Número LI atribuído automaticamente: '||current_data->>'liNumber'||' • linha '||coalesce(current_data->'liSource'->>'row','') else change_reason end);
 return current_data;
end$$;

create or replace function private.import_instruments(rows jsonb,target_company uuid,source_name text,batch_id uuid)returns jsonb
language plpgsql security definer set search_path='' as $$
declare cached public.instrument_import_batches%rowtype;item jsonb;draft jsonb;record jsonb;li_value text;row_number integer;results jsonb='[]';created_count integer=0;skipped_count integer=0;request_fingerprint text;
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
  draft=item->'instrument';row_number=(item->>'rowNumber')::integer;li_value=btrim(draft->>'liNumber');
  if row_number is null or row_number<1 or jsonb_typeof(draft) is distinct from 'object' or li_value is null or char_length(li_value) not between 1 and 150 or nullif(btrim(draft->>'description'),'') is null or char_length(draft->>'description')>2000 or (draft->>'ownerCompanyId')::uuid is distinct from target_company then raise exception 'Invalid import row %',row_number;end if;
  if not exists(select 1 from public.li_entries e where lower(btrim(e.code))=lower(li_value) and e.company_id=target_company) then raise exception 'LI number on row % is not in the registered official LI',row_number;end if;
  if exists(select 1 from public.instruments where lower(btrim(data->>'liNumber'))=lower(li_value)) then
   skipped_count=skipped_count+1;results=results||jsonb_build_array(jsonb_build_object('rowNumber',row_number,'code',li_value,'outcome','duplicate'));continue;
  end if;
  draft=draft||jsonb_build_object('id',gen_random_uuid(),'code',li_value,'liNumber',li_value,'ownerCompanyId',target_company,'userCompanyId','',
   'operationalStatus','fora de uso','lastControl','','nextControl','','registrationStatus','ativo',
   'importReference',jsonb_build_object('file',source_name,'row',row_number,'importedAt',now()));
  if jsonb_typeof(draft->'capabilities') is distinct from 'array' then raise exception 'Invalid measurement capabilities';end if;
  draft=jsonb_set(draft,'{capabilities}',coalesce((select jsonb_agg(cap.value||jsonb_build_object('id',gen_random_uuid()) order by cap.ordinality) from jsonb_array_elements(draft->'capabilities') with ordinality cap(value,ordinality)),'[]'::jsonb));
  begin
   record=private.save_instrument(draft,'Importação LI confirmada',source_name||' • linha '||row_number);
   created_count=created_count+1;results=results||jsonb_build_array(jsonb_build_object('rowNumber',row_number,'code',li_value,'outcome','imported','id',record->>'id'));
  exception when unique_violation then
   if not exists(select 1 from public.instruments where lower(btrim(data->>'liNumber'))=lower(li_value)) then raise;end if;
   skipped_count=skipped_count+1;results=results||jsonb_build_array(jsonb_build_object('rowNumber',row_number,'code',li_value,'outcome','duplicate'));
  end;
 end loop;
 record=jsonb_build_object('created',created_count,'skipped',skipped_count,'rows',results,'batchId',batch_id);
 insert into public.instrument_import_batches values(batch_id,target_company,auth.uid(),source_name,request_fingerprint,record,now());
 perform private.write_audit('Importação LI confirmada',batch_id::text,target_company,null,record,source_name);
 return record;
end$$;

create or replace function public.check_import_codes(codes text[])returns text[]
language sql stable security invoker set search_path='' as $$
 select coalesce(array_agg(i.data->>'liNumber'),'{}'::text[]) from public.instruments i
 where lower(btrim(i.data->>'liNumber'))=any(array(select lower(btrim(x)) from unnest(codes) x limit 500))
$$;

create or replace function private.refresh_search(target_instrument uuid) returns void language sql security definer set search_path='' as $$
 update public.instruments i set search_text=concat_ws(' ',
  i.data->>'liNumber',i.serial,i.tag,i.data->>'internalId',i.data->>'assetNumber',i.data->>'description',
  i.data->>'manufacturer',i.data->>'model',i.data->>'workSite',i.data->>'calibrationResponsibleArea',
  i.data->>'measurementRange',i.data->>'usageRange',i.data->>'verificationDivision',i.data->>'responsible',
  (select c.name from public.companies c where c.id=i.company_id),
  (select string_agg(concat_ws(' ',e.certificate_number,e.data->>'laboratory'),' ') from public.metrological_events e where e.instrument_id=i.id)
 ) where i.id=target_instrument
$$;
