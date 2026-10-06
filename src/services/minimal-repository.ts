import {supabase} from './supabase';
import {unwrap} from './repository';
import type {Instrument} from '../domain/types';
import type {SimpleRegistration,Member} from '../domain/minimal';
export interface WorkspaceRow {instrument:Instrument;openRegistration:SimpleRegistration|null}
export interface Workspace {items:WorkspaceRow[];total:number;metrics:{total:number;expired:number;soon:number;pending:number}}
const db=()=>{if(!supabase)throw new Error('Configuração do Metrikon indisponível.');return supabase;};
export async function context():Promise<{userId:string;role:string;companyId:string|null;permissions:string[]}>{return unwrap(await db().rpc('minimal_context'));}
export async function workspace(search:string,filter:string,window:number,page:number):Promise<Workspace>{return unwrap(await db().rpc('minimal_workspace',{search,filter,window_days:window,page_number:page}));}
export async function save(record:SimpleRegistration,submit:boolean):Promise<SimpleRegistration>{return unwrap(await db().rpc('save_simple_registration',{payload:record,submit}));}
export async function review(id:string,approve:boolean,notes:string):Promise<SimpleRegistration>{return unwrap(await db().rpc('review_simple_registration',{registration_id:id,approve,notes}));}
export async function history(id:string):Promise<SimpleRegistration[]>{const rows=unwrap(await db().from('instrument_registrations').select('*').eq('instrument_id',id).order('version',{ascending:false}));return rows.map(r=>({id:r.id,instrumentId:r.instrument_id,companyId:r.company_id,version:r.version,state:r.state,instrument:r.instrument_data,certificate:r.certificate_data,quantitative:r.quantitative,baseUpdatedAt:r.base_updated_at,createdBy:r.created_by,submittedAt:r.submitted_at,reviewedBy:r.reviewed_by,reviewedName:r.reviewed_label,reviewedAt:r.reviewed_at,reviewNotes:r.review_notes,updatedAt:r.updated_at,renewal:Boolean(r.instrument_data?.lastControl)}));}
export async function members():Promise<Member[]>{return unwrap(await db().rpc('minimal_members'));}
export async function member(email:string,role:string,companyId:string|null,enabled:boolean):Promise<Member[]>{return unwrap(await db().rpc('set_minimal_member',{email,new_role:role,target_company:companyId,enabled}));}
