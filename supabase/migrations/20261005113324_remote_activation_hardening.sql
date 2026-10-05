-- Additional checks after provisioning on PostgreSQL 17.11. Only the independent app project.
create index members_company on private.members(company_id);
alter table private.members enable row level security;
alter table private.role_permissions enable row level security;
alter table private.user_permissions enable row level security;
-- No client policies: private ACL remains accessible only through narrowly guarded helpers.
alter policy profile_read on public.profiles using (id=(select auth.uid()));

-- New Supabase projects include an RLS event trigger. Keep the trigger operational,
-- but remove direct API execution permissions from the platform's privileged function.
do $$begin
 if to_regprocedure('public.rls_auto_enable()') is not null then
  execute 'revoke execute on function public.rls_auto_enable() from public, anon, authenticated';
 end if;
end$$;
