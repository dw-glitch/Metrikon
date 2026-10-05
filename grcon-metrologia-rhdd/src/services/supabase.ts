import { createClient } from '@supabase/supabase-js';
const url=import.meta.env.VITE_SUPABASE_URL?.trim();
const key=import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY?.trim();
// Explicit barrier against accidentally wiring the existing GRCON database.
const forbiddenHost='kvyrttccwzdhasplfxnr.supabase.co';
function validateUrl(value:string|undefined){if(!value)return '';try{const parsed=new URL(value);if(parsed.hostname===forbiddenHost)return 'O banco do GRCON atual não pode ser utilizado neste aplicativo.';if(parsed.protocol!=='https:')return 'Configure uma URL HTTPS válida para o projeto independente.';return '';}catch{return 'A URL do novo banco é inválida.';}}
export const configurationError=validateUrl(url);
export const supabase=url && key && !configurationError?createClient(url,key,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}}):null;
export const appName=import.meta.env.VITE_APP_NAME?.trim()||'GRCON Metrologia — RHDD';
