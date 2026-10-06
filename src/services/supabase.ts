import { createClient } from '@supabase/supabase-js';
import {resolvePublicSupabaseConfig} from './runtime-config';

const runtimeConfig=resolvePublicSupabaseConfig(import.meta.env);
const url=runtimeConfig.url;
const key=runtimeConfig.key;
// Explicit barrier against accidentally wiring the existing GRCON database.
const forbiddenHost='kvyrttccwzdhasplfxnr.supabase.co';
function validateUrl(value:string|undefined){if(!value)return 'Configure a URL do projeto independente.';try{const parsed=new URL(value);if(parsed.hostname===forbiddenHost)return 'O banco do GRCON atual não pode ser utilizado neste aplicativo.';if(parsed.protocol!=='https:')return 'Configure uma URL HTTPS válida para o projeto independente.';return '';}catch{return 'A URL do novo banco é inválida.';}}
function validateKey(value:string|undefined){if(!value)return 'Configure a chave pública do projeto independente.';if(!value.startsWith('sb_publishable_')&&value.split('.').length!==3)return 'A chave pública configurada é inválida.';return '';}
export const configurationError=validateUrl(url)||validateKey(key);
export const configurationSource=runtimeConfig.source;
export const partialConfigurationOverrideIgnored=runtimeConfig.partialOverrideIgnored;
export const supabase=!configurationError?createClient(url,key,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}}):null;
export const appName=import.meta.env.VITE_APP_NAME?.trim()||'Metrikon';
