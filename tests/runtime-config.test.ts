import test from 'node:test';
import assert from 'node:assert/strict';
import {canonicalPublicSupabaseConfig,resolvePublicSupabaseConfig} from '../src/services/runtime-config';

test('uses canonical public Supabase config when build variables are absent',()=>{
  const config=resolvePublicSupabaseConfig({});
  assert.equal(config.url,canonicalPublicSupabaseConfig.url);
  assert.equal(config.key,canonicalPublicSupabaseConfig.publishableKey);
  assert.equal(config.source,'canonical');
  assert.equal(config.partialOverrideIgnored,false);
});

test('uses environment override only when URL and publishable key are both present',()=>{
  const config=resolvePublicSupabaseConfig({
    VITE_SUPABASE_URL:' https://example.supabase.co ',
    VITE_SUPABASE_PUBLISHABLE_KEY:' sb_publishable_example '
  });
  assert.equal(config.url,'https://example.supabase.co');
  assert.equal(config.key,'sb_publishable_example');
  assert.equal(config.source,'environment');
});

test('ignores a partial environment override instead of leaving auth unconfigured',()=>{
  const config=resolvePublicSupabaseConfig({VITE_SUPABASE_URL:'https://partial.supabase.co'});
  assert.equal(config.url,canonicalPublicSupabaseConfig.url);
  assert.equal(config.key,canonicalPublicSupabaseConfig.publishableKey);
  assert.equal(config.source,'canonical');
  assert.equal(config.partialOverrideIgnored,true);
});
