import { supabase } from './supabase';
import type { Company, Instrument, MetrologicalEvent, AuditEntry, PeriodicityEntry } from '../domain/types';
export const PAGE_SIZE=50;
export interface Query { search:string; company:string; registration:string; page:number }
export interface Overview { total:number; active:number; released:number; conditioned:number; outOfUse:number; expired:number; due7:number; due30:number; due60:number; awaitingAnalysis:number }
export function unwrap<T>(result:{data:T|null;error:{message:string}|null}):NonNullable<T> {if(result.error)throw new Error(result.error.message);if(result.data===null)throw new Error('Nenhum dado retornado pelo serviço.');return result.data as NonNullable<T>;}
function db(){if(!supabase)throw new Error('Configuração do banco independente pendente.');return supabase;}
export async function getPermissions():Promise<string[]> { return unwrap(await db().rpc('my_permissions')); }
export async function getCompanies():Promise<Company[]> {return unwrap(await db().from('companies').select('data').order('name').limit(500)).map(x=>x.data as Company);}
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
export async function uploadCertificate(event:MetrologicalEvent,file:File):Promise<string> {
  if(!file.name.toLowerCase().endsWith('.pdf')||file.size>20*1024*1024)throw new Error('Selecione PDF de até 20 MB.');
  if(new TextDecoder().decode(await file.slice(0,5).arrayBuffer())!=='%PDF-')throw new Error('O arquivo não possui cabeçalho PDF válido.');
  const path=`${event.instrumentId}/${event.id}/${crypto.randomUUID()}.pdf`;
  unwrap(await db().storage.from('metrology-certificates').upload(path,file,{contentType:'application/pdf',upsert:false}));
  return path;
}
export async function certificateUrl(path:string):Promise<string> {return unwrap(await db().storage.from('metrology-certificates').createSignedUrl(path,60)).signedUrl;}
export async function listAudit():Promise<AuditEntry[]> {return unwrap(await db().from('audit_log').select('*').order('at',{ascending:false}).limit(100)).map(x=>({id:x.id,at:x.at,actor:x.actor||'Sistema',action:x.action,entity:x.entity,before:x.old_data,after:x.new_data,reason:x.reason||''}));}
export async function listPeriodicity(id:string):Promise<PeriodicityEntry[]> {return unwrap(await db().from('instrument_periodicity_history').select('*').eq('instrument_id',id).order('at',{ascending:false})).map(x=>({id:x.id,instrumentId:x.instrument_id,previous:x.previous_months,next:x.new_months,reason:x.reason,evidence:x.evidence,actor:x.actor,at:x.at}));}
