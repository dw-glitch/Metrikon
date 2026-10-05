-- Only run while the real owner's Auth account has not yet been created.
-- No messages/passwords issued; all synthetic Auth users and grants roll back.
begin;
do $$declare owner_id uuid=gen_random_uuid();other_id uuid=gen_random_uuid();begin
 if exists(select 1 from auth.users where lower(email)='vinicio.silva@agnet.com.br') then raise exception 'Real owner account already exists; skip synthetic bootstrap test';end if;
 if not exists(select 1 from private.owner_bootstrap where email='vinicio.silva@agnet.com.br' and claimed_by is null) then raise exception 'Owner reservation not pending';end if;
 insert into auth.users(id,aud,role,email,email_confirmed_at) values(other_id,'authenticated','authenticated',other_id::text||'@example.invalid',now());
 if exists(select 1 from private.members where user_id=other_id) then raise exception 'Unreserved email received a membership';end if;
 insert into auth.users(id,aud,role,email) values(owner_id,'authenticated','authenticated','vinicio.silva@agnet.com.br');
 if exists(select 1 from private.members where user_id=owner_id) then raise exception 'Unconfirmed owner received a membership';end if;
 update auth.users set email_confirmed_at=now()where id=owner_id;
 if not exists(select 1 from private.members where user_id=owner_id and role='owner' and active and company_id is null) then raise exception 'Confirmed owner was not activated';end if;
 if not exists(select 1 from private.owner_bootstrap where claimed_by=owner_id and claimed_at is not null) then raise exception 'Reservation not consumed';end if;
 if (select count(*) from public.audit_log where actor=owner_id and action='Ativação do proprietário')<>1 then raise exception 'Activation audit missing';end if;
 update private.members set active=false where user_id=owner_id;
 update auth.users set email_confirmed_at=now()where id=owner_id;
 if exists(select 1 from private.members where user_id=owner_id and active) then raise exception 'Auth update undid revocation';end if;
 if has_table_privilege('authenticated','private.owner_bootstrap','SELECT') or has_table_privilege('authenticated','private.owner_bootstrap','UPDATE') or has_function_privilege('authenticated','private.claim_verified_owner()','EXECUTE') or has_function_privilege('anon','private.claim_verified_owner()','EXECUTE') then raise exception 'Client can access owner reservation/trigger';end if;
end$$;
rollback;
select jsonb_build_object('bootstrap_qa_passed',true,'fixtures_rolled_back',true,'reserved_email',(select email from private.owner_bootstrap),'reservation_pending',(select claimed_by is null from private.owner_bootstrap),'registered_auth_users',(select count(*)from auth.users),'members',(select count(*)from private.members)) as owner_bootstrap_result;
