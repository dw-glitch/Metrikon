import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import {demoState} from '../src/services/demo';
import {emptyEvent,prepareEventForPersistence} from '../src/domain/metrology';
import {newLaboratory,newStandard,newStandardCertificate} from '../src/domain/traceability';
const owner='91000000-0000-4000-8000-000000000001',contractor='91000000-0000-4000-8000-000000000002',outsider='91000000-0000-4000-8000-000000000003';
test('PostgreSQL fase 3: rastreabilidade, certificados imutáveis e isolamento',async t=>{
 const db=new PGlite();
 try{
 await db.exec(`create role anon;create role authenticated;create schema auth;create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz);create function auth.uid()returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema auth to anon,authenticated;grant execute on function auth.uid()to anon,authenticated;create schema storage;create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);create table storage.objects(id uuid default gen_random_uuid(),bucket_id text,name text,owner_id text,metadata jsonb);alter table storage.objects enable row level security;grant usage on schema storage to authenticated;grant select,insert on storage.objects to authenticated;`);
 const directory=new URL('../supabase/migrations/',import.meta.url);
 for(const filename of readdirSync(directory).filter(x=>x.endsWith('.sql')&&!x.includes('minimalist_registration_monitoring')).sort())await db.exec(readFileSync(new URL(filename,directory),'utf8'));
 const auth=async(id:string,role='authenticated')=>{await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id]);await db.exec(`set role ${role}`);};
 const rpc=async(fn:string,args:unknown[])=>db.query<{result:any}>(`select public.${fn}(${args.map((_,i)=>'$'+(i+1)).join(',')}) as result`,args);
 const fixture=demoState(),company=fixture.companies[0],other=fixture.companies[1];
 await db.query('insert into auth.users(id)values($1),($2),($3)',[owner,contractor,outsider]);await db.query("insert into private.members(user_id,role)values($1,'owner')",[owner]);
 await auth(owner);await rpc('save_company',[company]);await rpc('save_company',[other]);
 const laboratory={...newLaboratory(company.id),name:'Laboratório histórico',accreditation:'sim',accreditationReference:'ACR-01',scope:'Comprimento',validFrom:'2025-01-01',validUntil:'2025-12-31'};
 const standard={...newStandard(company.id),name:'Bloco padrão',serial:'PAD-001',quantity:'Comprimento',range:'0 a 100',unit:'mm'};
 const otherLab={...newLaboratory(other.id),name:'Laboratório outra empresa'};
 const otherStandard={...newStandard(other.id),name:'Outro padrão',serial:'OUTRO-001'};
 await rpc('save_calibration_laboratory',[laboratory]);await rpc('save_reference_standard',[standard]);await rpc('save_calibration_laboratory',[otherLab]);await rpc('save_reference_standard',[otherStandard]);
 const certificate={...newStandardCertificate(standard),number:'PAD-CERT-01',issuer:'Emissor original',issuerLaboratoryId:laboratory.id,calibrationDate:'2025-01-01',validUntil:'2025-12-31',scope:'0 a 100 mm',traceabilityEvidence:'Padrão rastreado'};
 certificate.attachmentPath=`${standard.id}/${certificate.id}/${crypto.randomUUID()}.pdf`;certificate.attachmentName='padrao.pdf';certificate.sizeBytes=100;
 await db.query('insert into storage.objects(bucket_id,name,owner_id,metadata)values($1,$2,$3,$4)',['metrology-standard-certificates',certificate.attachmentPath,owner,{mimetype:'application/pdf',size:100}]);
 const otherCert={...newStandardCertificate(otherStandard),number:'OTHER-CERT',issuer:'Outro emissor',calibrationDate:'2025-01-01'};
 await rpc('save_standard_certificate',[otherCert]);
 await t.test('cadastros rejeitam duplicados e troca de empresa',async()=>{
  await assert.rejects(()=>rpc('save_calibration_laboratory',[{...laboratory,id:crypto.randomUUID(),name:' LABORATÓRIO HISTÓRICO '}]),/duplicate key/);
  await assert.rejects(()=>rpc('save_reference_standard',[{...standard,id:crypto.randomUUID(),serial:' pad-001 '}]),/duplicate key/);
  await assert.rejects(()=>rpc('save_reference_standard',[{...standard,companyId:other.id}]),/Company cannot/);
 });
 await t.test('certificado valida emissor, arquivo real e metadados; atribui versão no servidor',async()=>{
  await assert.rejects(()=>rpc('save_standard_certificate',[{...certificate,issuerLaboratoryId:otherLab.id}]),/company mismatch/);
  await assert.rejects(()=>rpc('save_standard_certificate',[{...certificate,sizeBytes:90}]),/metadata mismatch/);
  const saved=(await rpc('save_standard_certificate',[{...certificate,version:900,createdBy:outsider}])).rows[0].result;
  assert.equal(saved.version,1);assert.equal(saved.createdBy,owner);
  await assert.rejects(()=>rpc('save_standard_certificate',[{...certificate,id:crypto.randomUUID(),validUntil:'2024-12-31',attachmentPath:''}]),/Invalid standard certificate/);
  await assert.rejects(()=>rpc('save_standard_certificate',[{...certificate,validUntil:'2030-01-01'}]),/immutable/);
  await db.query('delete from storage.objects where name=$1',[certificate.attachmentPath]);assert.equal((await db.query('select * from storage.objects where name=$1',[certificate.attachmentPath])).rows.length,1);
 });
 await db.exec('reset role');await db.query("insert into public.li_references(prefix,document,source_name,source_hash,original_max,planned_max,next_number,next_row,created_by)values('CE-','LI teste','LI teste','hash',1,842,843,850,$1)",[owner]);await auth(owner);
 const instrument={...fixture.instruments[0],code:'',liNumber:'',liSource:undefined};await rpc('save_instrument',[instrument,'','']);
 const event=emptyEvent(instrument.id,'inativo');event.date='2025-06-01';event.nextDate='2026-06-01';event.certificateNumber='EQUIP-01';event.laboratory='Entidade manual';event.laboratoryAccredited='não';event.calibrationAccepted='não';event.acceptedWithRestriction='não';event.decision='liberado para uso';event.rationale='Decisão humana independente';event.toleranceReferenceDocument='Procedimento';event.processTolerance='0.5';event.measurementUncertainty='0.1';event.measurementError='0.3';event.resultBasis='unidade';event.checklist.forEach(i=>i.outcome='conforme');event.laboratoryId=laboratory.id;event.traceabilitySelections=[{certificateId:certificate.id,usage:'Escala inferior'}];event.attachmentPath=`${instrument.id}/${event.id}/${crypto.randomUUID()}.pdf`;
 await db.query('insert into storage.objects(bucket_id,name,owner_id,metadata)values($1,$2,$3,$4)',['metrology-certificates',event.attachmentPath,owner,{mimetype:'application/pdf',size:100}]);
 await t.test('vínculos de outra empresa e snapshot forjado são rejeitados ou recalculados',async()=>{
  await assert.rejects(()=>rpc('save_metrological_event',[{...event,laboratoryId:otherLab.id},false]),/company mismatch/);
  await assert.rejects(()=>rpc('save_metrological_event',[{...event,traceabilitySelections:[{certificateId:otherCert.id,usage:''}]},false]),/company mismatch/);
  await assert.rejects(()=>rpc('save_metrological_event',[{...event,traceabilitySelections:[...event.traceabilitySelections!,...event.traceabilitySelections!]},false]),/Duplicate/);
  const saved=(await rpc('save_metrological_event',[{...prepareEventForPersistence(event),traceability:{laboratory:{record:{name:'FORJADO'}}}},false])).rows[0].result;
  assert.equal(saved.traceability.laboratory.record.name,laboratory.name);assert.equal(saved.traceability.standards[0].validity,'válido na data');assert.equal(saved.laboratoryAccredited,'não');assert.equal(saved.calibrationAccepted,'não');
  const expired=(await rpc('save_metrological_event',[{...event,id:crypto.randomUUID(),date:'2026-01-01',nextDate:'',attachmentPath:''},false])).rows[0].result;
  assert.equal(expired.traceability.standards[0].validity,'vencido na data');assert.equal(expired.calibrationAccepted,'não');
 });
 await t.test('conclusão congela padrão e validade histórica; renovação não altera o evento',async()=>{
  await rpc('save_metrological_event',[prepareEventForPersistence(event),true]);
  await rpc('save_calibration_laboratory',[{...laboratory,name:'Nome atualizado',active:false}]);await rpc('save_reference_standard',[{...standard,name:'Padrão atualizado',active:false}]);
  const renewal={...certificate,id:crypto.randomUUID(),number:'PAD-CERT-02',calibrationDate:'2026-01-01',validUntil:'2026-12-31',attachmentPath:'',attachmentName:'',sizeBytes:0,supersedesId:certificate.id};
  const saved=(await rpc('save_standard_certificate',[renewal])).rows[0].result;assert.equal(saved.version,2);
  const historical=(await db.query<{data:any}>('select data from public.metrological_events where id=$1',[event.id])).rows[0].data;
  assert.equal(historical.traceability.laboratory.record.name,'Laboratório histórico');assert.equal(historical.traceability.standards[0].standard.name,'Bloco padrão');assert.equal(historical.traceability.standards[0].certificate.number,'PAD-CERT-01');assert.equal(historical.traceability.standards[0].validity,'válido na data');
  assert.equal(historical.date,'2025-06-01');assert.equal(historical.nextDate,'2026-06-01');await assert.rejects(()=>rpc('save_metrological_event',[event,false]),/immutable/);
  assert.equal((await db.query('select * from public.event_standard_links where event_id=$1',[event.id])).rows.length,1);
 });
 await t.test('cliente não altera certificados, snapshots ou função antiga diretamente',async()=>{
  for(const table of ['calibration_laboratories','reference_standards','standard_certificates','event_traceability','event_standard_links'])await assert.rejects(()=>db.query(`delete from public.${table}`),/permission denied/);
  await assert.rejects(()=>db.query('select private.save_metrological_event_phase2($1,false)',[event]),/permission denied/);
 });
 await db.exec('reset role');await db.query("insert into private.members(user_id,role,company_id)values($1,'contractor',$2)",[contractor,other.id]);await db.exec("insert into private.role_permissions values('contractor','read')");await auth(contractor);
 await t.test('RLS isola cadastros, certificados, snapshots e arquivos entre empresas',async()=>{
  assert.equal((await db.query('select * from public.calibration_laboratories')).rows.length,1);assert.equal((await db.query('select * from public.reference_standards')).rows.length,1);
  assert.equal((await db.query('select * from public.standard_certificates')).rows.length,1);assert.equal((await db.query('select * from public.event_traceability')).rows.length,0);assert.equal((await db.query('select * from public.event_standard_links')).rows.length,0);
  assert.equal((await db.query('select * from storage.objects')).rows.length,0);await assert.rejects(()=>rpc('save_calibration_laboratory',[laboratory]),/Permission denied/);
 });
 await auth(outsider);await t.test('sem vínculo não lê nem cadastra; anon não executa RPC',async()=>{
  assert.equal((await db.query('select * from public.reference_standards')).rows.length,0);await assert.rejects(()=>rpc('save_reference_standard',[standard]),/Permission denied/);
  await auth('', 'anon');await assert.rejects(()=>rpc('save_standard_certificate',[certificate]),/permission denied/);
 });
 }finally{await db.close();}
});
