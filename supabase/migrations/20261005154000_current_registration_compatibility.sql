-- Compatibility with the calibration-certificate form currently used by the RHDD team.
-- Acceptance, registration status and equipment situation remain independent human records.
update storage.buckets
set file_size_limit=16777216,
    allowed_mime_types=array['application/pdf','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/vnd.ms-excel']
where id='metrology-certificates';

drop policy if exists metrology_certificate_insert on storage.objects;
create policy metrology_certificate_insert on storage.objects for insert to authenticated with check(
 bucket_id='metrology-certificates'
 and private.has_permission('register_event')
 and exists(select 1 from public.instruments i where i.id::text=split_part(name,'/',1))
 and name ~ '^[a-f0-9-]{36}/[a-f0-9-]{36}/[a-f0-9-]{36}\.(pdf|xlsx|xls)$'
);

create or replace function private.refresh_search(target_instrument uuid) returns void language sql security definer set search_path='' as $$
 update public.instruments i set search_text=concat_ws(' ',i.code,i.serial,i.tag,i.data->>'internalId',i.data->>'assetNumber',i.data->>'liNumber',i.data->>'description',i.data->>'manufacturer',i.data->>'model',i.data->>'workSite',i.data->>'calibrationResponsibleArea',i.data->>'measurementRange',i.data->>'usageRange',i.data->>'verificationDivision',i.data->>'responsible',(select c.name from public.companies c where c.id=i.company_id),(select string_agg(concat_ws(' ',e.certificate_number,e.data->>'laboratory'),' ') from public.metrological_events e where e.instrument_id=i.id)) where i.id=target_instrument
$$;

create or replace function private.save_metrological_event(payload jsonb,conclude boolean)returns jsonb language plpgsql security definer set search_path='' as $$
declare target uuid=(payload->>'id')::uuid;instrument uuid=(payload->>'instrumentId')::uuid;master public.instruments%rowtype;old_event public.metrological_events%rowtype;current_data jsonb;point jsonb;item jsonb;group_id uuid;quant_status text='pendente';qual_status text='pendente';point_status text;decision text=payload->>'decision';restriction jsonb=payload->'restriction';field text;divergent boolean=false;next_day date;event_day date;attachment text=payload->>'attachmentPath';procedure_status text='pendente';registration_status_value text=payload->>'registrationStatus';
begin
 select * into master from public.instruments where id=instrument for update;
 if not found or not private.has_permission('register_event') or not private.can_access(master.company_id) then raise exception 'Permission denied';end if;
 select * into old_event from public.metrological_events where id=target for update;
 if old_event.id is not null and (old_event.instrument_id<>instrument or old_event.workflow='concluído') then raise exception 'Closed events are immutable; create a new cycle';end if;
 if jsonb_typeof(payload->'points')<>'array' or jsonb_typeof(payload->'checklist')<>'array' then raise exception 'Points and checklist must be arrays';end if;
 event_day=nullif(payload->>'date','')::date;next_day=nullif(payload->>'nextDate','')::date;
 procedure_status=public.evaluate_metrology_point(private.parse_decimal(payload->>'measurementError'),private.parse_decimal(payload->>'measurementUncertainty'),private.parse_decimal(payload->>'processTolerance'),payload->>'resultBasis',payload->>'resultBasis');
 quant_status=procedure_status;
 if next_day is not null and (event_day is null or next_day<=event_day) then raise exception 'Next control must be after event date';end if;
 for field in select unnest(array['serial','tag','manufacturer','model'])loop
  if nullif(btrim(payload->'certificateIdentity'->>field),'') is not null and lower(btrim(coalesce(master.data->>field,'')))<>lower(btrim(payload->'certificateIdentity'->>field)) then divergent=true;end if;
 end loop;
 -- Schema and decisions recomputed server-side, not accepted from client claims.
 if jsonb_array_length(payload->'points')>0 then
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
  for field in select unnest(array['workSite','criticality','serial','model','location','calibrationResponsibleArea','process','measurementRange','usageRange','verificationDivision'])loop
   if nullif(btrim(master.data->>field),'') is null then raise exception 'Current registration field required: %',field;end if;
  end loop;
  if coalesce(master.data->>'periodicityMonths','')!~'^[1-9][0-9]*
  if decision not in ('liberado para uso','uso condicionado','fora de uso','segregado') or decision is null then raise exception 'Operational decision required';end if;
  if attachment is null or attachment !~ ('^'||instrument::text||'/'||target::text||'/[a-f0-9-]+\.(pdf|xlsx|xls) or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'A stored PDF/XLSX/XLS certificate belonging to this event is required';end if;
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
  update public.instruments set registration_status=registration_status_value,operational_status=decision,next_control=next_day,data=data||jsonb_build_object('registrationStatus',registration_status_value,'operationalStatus',decision,'lastControl',event_day::text,'nextControl',coalesce(next_day::text,''),'metrologicalStatus',case when quant_status='não conforme' or qual_status='não conforme' then 'reprovado' when decision='liberado para uso' then 'válido' else 'em análise' end),updated_at=now()where id=instrument;
 end if;
 perform private.refresh_search(instrument);
 perform private.write_audit(case when conclude then 'Decisão metrológica' else 'Rascunho do controle' end,target::text,master.company_id,old_event.data,current_data,coalesce(payload->>'rationale',''));
 return current_data;
end$$; then raise exception 'Current registration interval required';end if;
  if coalesce(master.data->>'contractorEquipment','') not in ('sim','não') then raise exception 'Contractor equipment answer required';end if;
  if event_day is null or nullif(btrim(payload->>'certificateNumber'),'') is null or nullif(btrim(payload->>'laboratory'),'') is null or nullif(btrim(payload->>'rationale'),'') is null then raise exception 'Event date, certificate number, calibration entity and rationale required';end if;
  if nullif(btrim(payload->>'toleranceReferenceDocument'),'') is null then raise exception 'Tolerance reference document required';end if;
  if procedure_status='pendente' then raise exception 'Error, uncertainty and positive process tolerance with a common basis are required';end if;
  if coalesce(payload->>'laboratoryAccredited','') not in ('sim','não') then raise exception 'Laboratory accreditation answer required';end if;
  if coalesce(payload->>'calibrationAccepted','') not in ('sim','não') then raise exception 'Calibration acceptance answer required';end if;
  if coalesce(payload->>'acceptedWithRestriction','') not in ('sim','não') then raise exception 'Restricted acceptance answer required';end if;
  if registration_status_value not in ('ativo','inativo','desmobilizado','baixado') then raise exception 'Registration status required';end if;
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
end$$;) or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'A stored PDF certificate belonging to this event is required';end if;
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
  if attachment !~ ('^'||instrument::text||'/'||target::text||'/[a-f0-9-]+\.(pdf|xlsx|xls) or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'Certificate storage reference is invalid';end if;
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
end$$; then raise exception 'Current registration interval required';end if;
  if coalesce(master.data->>'contractorEquipment','') not in ('sim','não') then raise exception 'Contractor equipment answer required';end if;
  if event_day is null or nullif(btrim(payload->>'certificateNumber'),'') is null or nullif(btrim(payload->>'laboratory'),'') is null or nullif(btrim(payload->>'rationale'),'') is null then raise exception 'Event date, certificate number, calibration entity and rationale required';end if;
  if nullif(btrim(payload->>'toleranceReferenceDocument'),'') is null then raise exception 'Tolerance reference document required';end if;
  if procedure_status='pendente' then raise exception 'Error, uncertainty and positive process tolerance with a common basis are required';end if;
  if coalesce(payload->>'laboratoryAccredited','') not in ('sim','não') then raise exception 'Laboratory accreditation answer required';end if;
  if coalesce(payload->>'calibrationAccepted','') not in ('sim','não') then raise exception 'Calibration acceptance answer required';end if;
  if coalesce(payload->>'acceptedWithRestriction','') not in ('sim','não') then raise exception 'Restricted acceptance answer required';end if;
  if registration_status_value not in ('ativo','inativo','desmobilizado','baixado') then raise exception 'Registration status required';end if;
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
end$$;) or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'Certificate storage reference is invalid';end if;
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
end$$; then raise exception 'Current registration interval required';end if;
  if coalesce(master.data->>'contractorEquipment','') not in ('sim','não') then raise exception 'Contractor equipment answer required';end if;
  if event_day is null or nullif(btrim(payload->>'certificateNumber'),'') is null or nullif(btrim(payload->>'laboratory'),'') is null or nullif(btrim(payload->>'rationale'),'') is null then raise exception 'Event date, certificate number, calibration entity and rationale required';end if;
  if nullif(btrim(payload->>'toleranceReferenceDocument'),'') is null then raise exception 'Tolerance reference document required';end if;
  if procedure_status='pendente' then raise exception 'Error, uncertainty and positive process tolerance with a common basis are required';end if;
  if coalesce(payload->>'laboratoryAccredited','') not in ('sim','não') then raise exception 'Laboratory accreditation answer required';end if;
  if coalesce(payload->>'calibrationAccepted','') not in ('sim','não') then raise exception 'Calibration acceptance answer required';end if;
  if coalesce(payload->>'acceptedWithRestriction','') not in ('sim','não') then raise exception 'Restricted acceptance answer required';end if;
  if registration_status_value not in ('ativo','inativo','desmobilizado','baixado') then raise exception 'Registration status required';end if;
  if decision not in ('liberado para uso','uso condicionado','fora de uso','segregado') or decision is null then raise exception 'Operational decision required';end if;
  if attachment is null or attachment !~ ('^'||instrument::text||'/'||target::text||'/[a-f0-9-]+\.(pdf|xlsx|xls) or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'A stored PDF certificate belonging to this event is required';end if;
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
end$$;) or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'A stored PDF certificate belonging to this event is required';end if;
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
  if attachment !~ ('^'||instrument::text||'/'||target::text||'/[a-f0-9-]+\.(pdf|xlsx|xls) or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'Certificate storage reference is invalid';end if;
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
end$$;) or not exists(select 1 from storage.objects where bucket_id='metrology-certificates' and name=attachment) then raise exception 'Certificate storage reference is invalid';end if;
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

revoke all on function private.save_metrological_event(jsonb,boolean) from public,anon;
grant execute on function private.save_metrological_event(jsonb,boolean) to authenticated;
