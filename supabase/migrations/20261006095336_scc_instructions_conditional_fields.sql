-- SCC instructions supplied by Vinício on 06/10/2026: conditional text fields, standards question,
-- seven equipment situations and calibration renewal without changing equipment/fixed parameters.
-- Existing history retains its values; no record or file is rewritten by this migration.
alter table public.instruments drop constraint instruments_operational_status_check;
alter table public.instruments add constraint instruments_operational_status_check check(operational_status in (
 'aguardando envio para calibração','desmobilizado','disponível para transferência','disponível para uso','em uso','enviado para calibração','enviado para manutenção',
 'liberado para uso','uso condicionado','fora de uso','segregado'
));
create or replace function private.simple_registration_json(r public.instrument_registrations)returns jsonb language sql stable set search_path='' as $$
 select jsonb_build_object('id',r.id,'instrumentId',r.instrument_id,'companyId',r.company_id,'version',r.version,'state',r.state,'instrument',r.instrument_data,'certificate',r.certificate_data,'quantitative',r.quantitative,'baseUpdatedAt',r.base_updated_at,'createdBy',r.created_by,'submittedAt',r.submitted_at,'reviewedBy',r.reviewed_by,'reviewedName',r.reviewed_label,'reviewedAt',r.reviewed_at,'reviewNotes',r.review_notes,'updatedAt',r.updated_at,'renewal',nullif(r.instrument_data->>'lastControl','') is not null)
$$;

create or replace function private.save_simple_registration(payload jsonb,submit boolean)returns jsonb language plpgsql security definer set search_path='' as $$
declare target uuid=(payload->>'id')::uuid;i jsonb=payload->'instrument';c jsonb=payload->'certificate';master public.instruments%rowtype;old public.instrument_registrations%rowtype;r public.instrument_registrations%rowtype;q jsonb;key text;file storage.objects%rowtype;path text;new_version int;renewal boolean;baseline jsonb;
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
 -- SCC renewal updates the highlighted calibration values, not equipment identity or fixed parameters.
 renewal=nullif(master.data->>'lastControl','') is not null;
 if renewal then
  foreach key in array array['workSite','criticality','serial','model','location','calibrationResponsibleArea','process','measurementRange','usageRange','verificationDivision','periodicityMonths','registrationStatus','contractorEquipment'] loop
   if coalesce(i->>key,'') is distinct from coalesce(master.data->>key,'') then raise exception 'Atualização da calibração não altera os dados do equipamento: %',key;end if;
  end loop;
  if nullif(btrim(master.data->>'contractorCompanyName'),'') is not null and coalesce(btrim(i->>'contractorCompanyName'),'') is distinct from btrim(master.data->>'contractorCompanyName') then raise exception 'Atualização da calibração não altera a Empresa contratada';end if;
  baseline=coalesce(master.data->'currentCertificate',(select certificate_data from public.instrument_registrations where instrument_id=master.id and state='aprovado' order by version desc limit 1),(select data from public.metrological_events where instrument_id=master.id and workflow='concluído' order by event_date desc,created_at desc limit 1));
  foreach key in array array['toleranceReferenceDocument','processTolerance','resultBasis'] loop
   if coalesce(c->>key,'') is distinct from coalesce(baseline->>key,'') then raise exception 'Atualização da calibração não altera os parâmetros fixos: %',key;end if;
  end loop;
 end if;
 -- Only the SCC field set is persisted; operational/current certificate values cannot be forged.
 i=jsonb_build_object('id',master.id,'ownerCompanyId',master.company_id,'liNumber',master.data->>'liNumber','code',master.code,'liSource',master.data->'liSource',
  'workSite',coalesce(i->>'workSite',''),'criticality',coalesce(i->>'criticality',''),'serial',coalesce(i->>'serial',''),'model',coalesce(i->>'model',''),'location',coalesce(i->>'location',''),
  'calibrationResponsibleArea',coalesce(i->>'calibrationResponsibleArea',''),'process',coalesce(i->>'process',''),'measurementRange',coalesce(i->>'measurementRange',''),'usageRange',coalesce(i->>'usageRange',''),
  'verificationDivision',coalesce(i->>'verificationDivision',''),'periodicityMonths',(i->>'periodicityMonths')::integer,'registrationStatus',i->>'registrationStatus','contractorEquipment',coalesce(i->>'contractorEquipment','não'),
  'contractorCompanyName',case when i->>'contractorEquipment'='sim' then btrim(coalesce(i->>'contractorCompanyName','')) else '' end,'operationalStatus',master.data->>'operationalStatus','lastControl',master.data->>'lastControl','nextControl',master.data->>'nextControl');
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
  'calibrationAccepted',coalesce(c->>'calibrationAccepted',''),'acceptedWithRestriction',coalesce(c->>'acceptedWithRestriction',''),'standardsValidation',case when c->>'laboratoryAccredited'='não' then coalesce(c->>'standardsValidation','') else '' end,'restrictionText',case when c->>'acceptedWithRestriction'='sim' then btrim(coalesce(c->>'restrictionText','')) else '' end,
  'decision',coalesce(c->>'decision',''),'attachmentPath',path,'attachmentName',coalesce(c->>'attachmentName',''));
 q=private.simple_quantitative(c);
 if length(i->>'contractorCompanyName')>500 or length(c->>'restrictionText')>2000 then raise exception 'Texto de Empresa contratada ou Restrição muito longo';end if;
 if submit then
  foreach key in array array['workSite','criticality','serial','model','location','calibrationResponsibleArea','process','measurementRange','usageRange','verificationDivision'] loop if nullif(btrim(i->>key),'') is null then raise exception 'Campo obrigatório: %',key;end if;end loop;
  if coalesce((i->>'periodicityMonths')::int,0)<1 or i->>'contractorEquipment' not in ('sim','não') then raise exception 'Intervalo ou empresa contratada inválido';end if;
  foreach key in array array['date','nextDate','laboratory','certificateNumber','toleranceReferenceDocument','attachmentPath'] loop if nullif(btrim(c->>key),'') is null then raise exception 'Campo obrigatório: %',key;end if;end loop;
  if c->>'date' !~ '^\d{4}-\d{2}-\d{2}$' or c->>'nextDate' !~ '^\d{4}-\d{2}-\d{2}$' or (c->>'nextDate')::date<=(c->>'date')::date or q->>'status'='pendente' then raise exception 'Datas ou valores da calibração inválidos';end if;
  foreach key in array array['laboratoryAccredited','calibrationAccepted','acceptedWithRestriction'] loop if c->>key not in ('sim','não') then raise exception 'Resposta obrigatória: %',key;end if;end loop;
  if i->>'contractorEquipment'='sim' and nullif(btrim(i->>'contractorCompanyName'),'') is null then raise exception 'Informe a Empresa contratada';end if;
  if c->>'acceptedWithRestriction'='sim' and nullif(btrim(c->>'restrictionText'),'') is null then raise exception 'Informe a Restrição';end if;
  if c->>'laboratoryAccredited'='não' and c->>'standardsValidation' not in ('sim','não') then raise exception 'Informe a validação da rastreabilidade e validade dos certificados dos padrões';end if;
  if c->>'decision' not in ('aguardando envio para calibração','desmobilizado','disponível para transferência','disponível para uso','em uso','enviado para calibração','enviado para manutenção') then raise exception 'Selecione a Situação do equipamento conforme o SCC';end if;
 end if;
 select coalesce(max(version),0)+1 into new_version from public.instrument_registrations where instrument_id=master.id;
 insert into public.instrument_registrations(id,instrument_id,company_id,version,state,instrument_data,certificate_data,quantitative,base_updated_at,created_by,submitted_at)
 values(target,master.id,master.company_id,coalesce(old.version,new_version),case when submit then 'aguardando aprovação' else 'rascunho' end,i,c,q,coalesce(old.base_updated_at,master.updated_at),coalesce(old.created_by,auth.uid()),case when submit then now() end)
 on conflict(id)do update set state=excluded.state,instrument_data=excluded.instrument_data,certificate_data=excluded.certificate_data,quantitative=excluded.quantitative,submitted_at=excluded.submitted_at,updated_at=now() returning * into r;
 perform private.write_audit(case when submit then 'Cadastro enviado para aprovação' else 'Rascunho de cadastro salvo' end,master.code,master.company_id,to_jsonb(old),to_jsonb(r),'SCC simplificado');
 return private.simple_registration_json(r);
end$$;

notify pgrst,'reload schema';
