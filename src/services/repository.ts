import { supabase } from './supabase';
import type { Company, Instrument, MetrologicalEvent, AuditEntry, PeriodicityEntry, LIReferenceSummary } from '../domain/types';
export const PAGE_SIZE=50;
export interface Query { search:string; company:string; registration:string; page:number }
export interface Overview { total:number; active:number; released:number; conditioned:number; outOfUse:number; expired:number; due7:number; due30:number; due60:number; awaitingAnalysis:number }
export function unwrap<T>(result:{data:T|null;error:{message:string}|null}):NonNullable<T> {if(result.error)throw new Error(result.error.message);if(result.data===null)throw new Error('Nenhum dado retornado pelo serviço.');return result.data as NonNullable<T>;}
function db(){if(!supabase)throw new Error('Configuração do banco independente pendente.');return supabase;}
export async function getPermissions():Promise<string[]> { return unwrap(await db().rpc('my_permissions')); }
export async function getCompanies():Promise<Company[]> {return unwrap(await db().from('companies').select('data').order('name').limit(500)).map(x=>x.data as Company);}
export async function getLIReference():Promise<LIReferenceSummary|null>{
 const rows=unwrap(await db().from('li_references').select('prefix,document,source_name,next_number,next_row').order('created_at',{ascending:false}).limit(2));
 if(!rows.length)return null;
 if(rows.length>1)throw new Error('Há mais de uma LI oficial registrada. Defina o escopo antes de cadastrar um novo instrumento.');
 const x=rows[0] as any;return {prefix:x.prefix,document:x.document,sourceName:x.source_name,nextNumber:x.next_number,nextRow:x.next_row,nextCode:`${x.prefix}${String(x.next_number).padStart(Math.max(3,String(x.next_number).length),'0')}`};
}
export async function listInstruments(q:Query):Promise<{items:Instrument[];total:number}> {
  let query=db().from('instruments').select('data',{count:'exact'}).order('code').range(q.page*PAGE_SIZE,(q.page+1)*PAGE_SIZE-1);
  const search=q.search.trim().slice(0,150).replace(/[%,()]/g,' ');
  if(search)query=query.ilike('search_text',`%${search}%`);
  if(q.company)query=query.eq('company_id',q.company);
  if(q.registration)query=query.eq('registration_status',q.registration);
  const response=await query;
  return {items:unwrap(response).map(x=>x.data as Instrument),total:response.count||0};
}
export async function overview(company:string):Promise<Overview> {return unwrap(await db().rpc('metrology_overview',{company_filter:company||null}));}
export async function saveInstrument(instrument:Instrument, reason:string,evidence:string):Promise<Instrument> {return unwrap(await db().rpc('save_instrument',{payload:instrument,change_reason:reason,change_evidence:evidence}));}
export async function saveCompany(company:Company):Promise<Company> {return unwrap(await db().rpc('save_company',{payload:company}));}
export async function loadInstrument(id:string):Promise<Instrument> {const result=await db().from('instruments').select('data').eq('id',id).single();if(result.error)throw new Error(result.error.message);if(!result.data)throw new Error('Instrumento não encontrado ou sem permissão.');return (result.data as unknown as {data:Instrument}).data;}
export async function listEvents(instrumentId:string):Promise<MetrologicalEvent[]> {return unwrap(await db().from('metrological_events').select('data').eq('instrument_id',instrumentId).order('event_date',{ascending:false})).map(x=>x.data as MetrologicalEvent);}
export async function saveEvent(event:MetrologicalEvent, conclude:boolean):Promise<MetrologicalEvent> {return unwrap(await db().rpc('save_metrological_event',{payload:event,conclude}));}
export const CERTIFICATE_ATTACHMENT_LIMIT=16*1024*1024;
export async function inspectCertificateAttachment(file:File):Promise<{extension:'pdf'|'xlsx'|'xls';mimeType:string}>{
  if(!file.size||file.size>CERTIFICATE_ATTACHMENT_LIMIT)throw new Error('Selecione PDF, XLSX ou XLS de até 16 MB.');
  const extension=file.name.split('.').pop()?.toLowerCase();
  const bytes=new Uint8Array(await file.slice(0,8).arrayBuffer());
  const text=new TextDecoder().decode(bytes);
  if(extension==='pdf'&&text.startsWith('%PDF-'))return {extension:'pdf',mimeType:'application/pdf'};
  if(extension==='xlsx'&&bytes[0]===0x50&&bytes[1]===0x4b&&bytes[2]===0x03&&bytes[3]===0x04)return {extension:'xlsx',mimeType:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'};
  if(extension==='xls'&&[0xd0,0xcf,0x11,0xe0,0xa1,0xb1,0x1a,0xe1].every((v,i)=>bytes[i]===v))return {extension:'xls',mimeType:'application/vnd.ms-excel'};
  throw new Error('A extensão e o conteúdo do anexo precisam corresponder a PDF, XLSX ou XLS.');
}
export async function uploadCertificate(event:MetrologicalEvent,file:File):Promise<string> {
  const checked=await inspectCertificateAttachment(file);
  const path=`${event.instrumentId}/${event.id}/${crypto.randomUUID()}.${checked.extension}`;
  unwrap(await db().storage.from('metrology-certificates').upload(path,file,{contentType:checked.mimeType,upsert:false}));
  return path;
}
export async function certificateUrl(path:string):Promise<string> {return unwrap(await db().storage.from('metrology-certificates').createSignedUrl(path,60)).signedUrl;}
export async function listAudit():Promise<AuditEntry[]> {return unwrap(await db().from('audit_log').select('*').order('at',{ascending:false}).limit(100)).map(x=>({id:x.id,at:x.at,actor:x.actor||'Sistema',action:x.action,entity:x.entity,before:x.old_data,after:x.new_data,reason:x.reason||''}));}
export async function listPeriodicity(id:string):Promise<PeriodicityEntry[]> {return unwrap(await db().from('instrument_periodicity_history').select('*').eq('instrument_id',id).order('at',{ascending:false})).map(x=>({id:x.id,instrumentId:x.instrument_id,previous:x.previous_months,next:x.new_months,reason:x.reason,evidence:x.evidence,actor:x.actor,at:x.at}));}

// Auxiliary catalog names are suggestions; instrument snapshots preserve historical text.
import {inspectAsset,type CatalogEntry,type InstrumentAsset} from '../domain/catalogs';
import type {ImportResult,PreviewRow} from '../domain/li-import';
function catalogFromRow(x:any):CatalogEntry{return {id:x.id,companyId:x.company_id,kind:x.kind,name:x.name,notes:x.notes,active:x.active};}
function assetFromRow(x:any):InstrumentAsset{return {id:x.id,instrumentId:x.instrument_id,name:x.name,mimeType:x.mime_type,sizeBytes:x.size_bytes,storagePath:x.storage_path,createdAt:x.created_at};}
export async function listCatalogs():Promise<CatalogEntry[]>{const result:CatalogEntry[]=[];for(let offset=0;;offset+=1000){const rows=unwrap(await db().from('instrument_references').select('*').order('id').range(offset,offset+999));result.push(...rows.map(catalogFromRow));if(rows.length<1000)return result;}}
export async function saveCatalog(entry:CatalogEntry):Promise<CatalogEntry>{return catalogFromRow(unwrap(await db().rpc('save_instrument_reference',{payload:entry})));}
export async function listAssets(id:string):Promise<InstrumentAsset[]>{return unwrap(await db().from('instrument_assets').select('*').eq('instrument_id',id).order('created_at',{ascending:false})).map(assetFromRow);}
export async function uploadAsset(instrumentId:string,file:File):Promise<InstrumentAsset>{
 const checked=await inspectAsset(file);const path=`${instrumentId}/${crypto.randomUUID()}.${checked.extension}`;
 unwrap(await db().storage.from('metrology-instrument-assets').upload(path,file,{contentType:checked.mimeType,upsert:false}));
 try{return assetFromRow(unwrap(await db().rpc('register_instrument_asset',{payload:{id:crypto.randomUUID(),instrumentId,name:file.name,mimeType:checked.mimeType,sizeBytes:file.size,storagePath:path}})));}
 catch(e){await db().storage.from('metrology-instrument-assets').remove([path]);throw e;}
}
export async function assetUrl(path:string):Promise<string>{return unwrap(await db().storage.from('metrology-instrument-assets').createSignedUrl(path,60)).signedUrl;}
export async function checkImportCodes(codes:string[]):Promise<string[]>{const known:string[]=[];for(let start=0;start<codes.length;start+=500){known.push(...unwrap<string[]>(await db().rpc('check_import_codes',{codes:codes.slice(start,start+500)})));}return known;}
export async function importInstruments(rows:PreviewRow[],companyId:string,sourceName:string,batchId:string):Promise<ImportResult>{return unwrap(await db().rpc('import_instruments',{rows:rows.map(r=>({rowNumber:r.rowNumber,instrument:r.instrument})),target_company:companyId,source_name:sourceName,batch_id:batchId}));}
