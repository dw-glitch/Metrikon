import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';

test('proprietário: reserva privada e ativação única após confirmação do Auth',async t=>{
 const db=new PGlite();
 try{
  await db.exec(`create role anon;create role authenticated;create schema auth;create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz);create function auth.uid()returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema auth to anon,authenticated;grant execute on function auth.uid()to anon,authenticated;create schema storage;create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);create table storage.objects(id uuid default gen_random_uuid(),bucket_id text,name text,owner_id text,metadata jsonb);alter table storage.objects enable row level security;`);
  const directory=new URL('../supabase/migrations/',import.meta.url);
  for(const filename of readdirSync(directory).filter(x=>x.endsWith('.sql')&&x<'20261006090041').sort())await db.exec(readFileSync(new URL(filename,directory),'utf8'));
  const reserved=crypto.randomUUID(),other=crypto.randomUUID();
  await t.test('e-mail diferente, mesmo confirmado, não recebe papel',async()=>{
   await db.query('insert into auth.users(id,email,email_confirmed_at)values($1,$2,now())',[other,'outra.pessoa@example.invalid']);
   assert.equal((await db.query('select * from private.members')).rows.length,0);
  });
  await t.test('e-mail reservado sem confirmação não recebe papel',async()=>{
   await db.query('insert into auth.users(id,email)values($1,$2)',[reserved,'VINICIO.SILVA@AGNET.COM.BR']);
   assert.equal((await db.query('select * from private.members')).rows.length,0);
  });
  await t.test('confirmação ativa proprietário e preserva auditoria',async()=>{
   await db.query('update auth.users set email_confirmed_at=now()where id=$1',[reserved]);
   const m=await db.query<{user_id:string;role:string;active:boolean;company_id:string|null}>('select * from private.members');
   assert.deepEqual(m.rows.map(x=>({id:x.user_id,role:x.role,active:x.active,company:x.company_id})),[{id:reserved,role:'owner',active:true,company:null}]);
   assert.equal((await db.query('select * from public.audit_log')).rows.length,1);
   assert.equal((await db.query('select * from public.profiles')).rows.length,1);
  });
  await t.test('nova atualização do Auth não desfaz revogação do membro',async()=>{
   await db.query('update private.members set active=false where user_id=$1',[reserved]);
   await db.query('update auth.users set email_confirmed_at=now()where id=$1',[reserved]);
   assert.equal((await db.query<{active:boolean}>('select active from private.members')).rows[0].active,false);
   assert.equal((await db.query('select * from public.audit_log')).rows.length,1);
  });
  await t.test('reserva consumida não transfere papel para outra conta',async()=>{
   await db.query('insert into auth.users(id,email,email_confirmed_at)values($1,$2,now())',[crypto.randomUUID(),'vinicio.silva@agnet.com.br']);
   assert.equal((await db.query('select * from private.members')).rows.length,1);
  });
  await t.test('cliente não lê/altera reserva nem executa função de ativação',async()=>{
   for(const role of ['anon','authenticated']){
    await db.exec(`set role ${role}`);
    await assert.rejects(()=>db.query('select * from private.owner_bootstrap'),/permission denied/);
    await assert.rejects(()=>db.query("update private.owner_bootstrap set email='intruso@example.invalid'"),/permission denied/);
    await assert.rejects(()=>db.query('select private.claim_verified_owner()'),/permission denied/);
    await db.exec('reset role');
    const p=await db.query<{allowed:boolean}>("select has_function_privilege($1,'private.claim_verified_owner()','execute') as allowed",[role]);
    assert.equal(p.rows[0].allowed,false);
   }
  });
 }finally{await db.close();}
});
