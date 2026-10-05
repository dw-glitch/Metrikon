-- Trusted one-time designation supplied by the user. Does not create an Auth user,
-- issue credentials, confirm an email, or send an invitation.
create table private.owner_bootstrap (
 singleton boolean primary key default true check(singleton),
 email text not null unique check(email=lower(btrim(email))),
 claimed_by uuid unique references auth.users(id),
 claimed_at timestamptz,
 check((claimed_by is null)=(claimed_at is null))
);
alter table private.owner_bootstrap enable row level security;
revoke all on private.owner_bootstrap from public,anon,authenticated;
insert into private.owner_bootstrap(email) values('vinicio.silva@agnet.com.br');

create function private.claim_verified_owner() returns trigger
language plpgsql security definer set search_path='' as $$
declare claimed boolean;
begin
 if new.email is null or new.email_confirmed_at is null then return new;end if;
 update private.owner_bootstrap set claimed_by=new.id,claimed_at=now()
 where email=lower(btrim(new.email)) and claimed_by is null returning singleton into claimed;
 if claimed then
  insert into private.members(user_id,role,company_id,active)values(new.id,'owner',null,true)
  on conflict(user_id)do update set role='owner',company_id=null,active=true;
  insert into public.profiles(id,name)values(new.id,'Vinício')on conflict(id)do nothing;
  insert into public.audit_log(actor,action,entity,old_data,new_data,reason)
  values(new.id,'Ativação do proprietário',new.id::text,null,jsonb_build_object('role','owner'),'E-mail definido pelo usuário; acesso confirmado pelo Supabase Auth.');
 end if;
 return new;
end$$;
revoke all on function private.claim_verified_owner() from public,anon,authenticated;
create trigger metrology_claim_owner_after_verification
after insert or update of email,email_confirmed_at on auth.users
for each row execute function private.claim_verified_owner();
