export const canonicalPublicSupabaseConfig={
  url:'https://aimvjsbrxnyqjurgicec.supabase.co',
  publishableKey:'sb_publishable_VryWLhRfDB-XzbvWKiKsPA_FvwpDkY-'
} as const;

export type PublicSupabaseConfig={
  url:string;
  key:string;
  source:'environment'|'canonical';
  partialOverrideIgnored:boolean;
};

const clean=(value:string|undefined)=>value?.trim()||'';

export function resolvePublicSupabaseConfig(env:Record<string,string|undefined>):PublicSupabaseConfig{
  const envUrl=clean(env.VITE_SUPABASE_URL);
  const envKey=clean(env.VITE_SUPABASE_PUBLISHABLE_KEY);
  const completeOverride=Boolean(envUrl&&envKey);
  return {
    url:completeOverride?envUrl:canonicalPublicSupabaseConfig.url,
    key:completeOverride?envKey:canonicalPublicSupabaseConfig.publishableKey,
    source:completeOverride?'environment':'canonical',
    partialOverrideIgnored:Boolean(envUrl)!==Boolean(envKey)
  };
}
