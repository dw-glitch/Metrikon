-- Transactional RPC/RLS QA only: does not validate browser login or actual Storage upload.
begin;
set local request.jwt.claim.sub='87dd90f9-dd3f-4d92-948c-e8ce1afe0094';
set local role authenticated;
do $$
declare c uuid=gen_random_uuid();b uuid=gen_random_uuid();rid uuid=gen_random_uuid();code_value text='QA-TX-'||gen_random_uuid()::text;payload jsonb;items jsonb;result jsonb;again jsonb;
begin
 perform public.save_company(jsonb_build_object('id',c,'name','QA transacional temporário','cnpj','','contract','QA','contact','','active',true));
 perform public.save_instrument_reference(jsonb_build_object('id',rid,'companyId',c,'kind','area','name','Oficina QA','notes','','active',true));
 if not exists(select 1 from public.instrument_references where id=rid) then raise exception 'Catalog RLS/read failed';end if;
 payload=jsonb_build_object('id',gen_random_uuid(),'code',code_value,'description','Instrumento sintético QA','ownerCompanyId',c,'userCompanyId','','periodicityMonths',null,'capabilities','[]'::jsonb,'operationalStatus','liberado para uso','registrationStatus','ativo','nextControl','2030-01-01','lastControl','2026-01-01','serial','','tag','','manufacturer','','model','','area','','sector','','process','','location','','responsible','','notes','');
 items=jsonb_build_array(jsonb_build_object('rowNumber',2,'instrument',payload));
 result=public.import_instruments(items,c,'QA-transacional.csv',b);
 if (result->>'created')::integer<>1 then raise exception 'Import did not create expected record';end if;
 if not exists(select 1 from public.instruments where code=code_value and operational_status='fora de uso' and next_control is null and data->>'lastControl'='' and data->'importReference'->>'row'='2')then raise exception 'Operational safety/import provenance failed';end if;
 again=public.import_instruments(items,c,'QA-transacional.csv',b);
 if result<>again then raise exception 'Idempotent import failed';end if;
 result=public.import_instruments(items,c,'QA-transacional.csv',gen_random_uuid());
 if (result->>'created')::integer<>0 or (result->>'skipped')::integer<>1 then raise exception 'Duplicate protection failed';end if;
 if not code_value=any(public.check_import_codes(array[lower(code_value)])) then raise exception 'Preview normalized code check failed';end if;
 begin
  update public.instrument_references set name='Forbidden' where id=rid;
  raise exception 'Direct catalog writes unexpectedly allowed';
 exception when insufficient_privilege then null;
 end;
end$$;
rollback;
select jsonb_build_object('transactionalQA','passed','fixtures','rolled back','scope','catalog RPC, import defaults/provenance, idempotence, duplicate protection, read RLS and write grants') as result;
