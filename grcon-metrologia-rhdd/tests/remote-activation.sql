-- Run only on the new independent app project. All fixtures are rolled back.
-- Exercises real PostgreSQL/Auth schema/RLS; does not pretend to test HTTP login or PDF upload.
begin;
create temporary table qa_metrology_fixture(name text primary key,payload jsonb) on commit drop;
insert into qa_metrology_fixture values
 ('owner',jsonb_build_object('id',gen_random_uuid())),
 ('contractor',jsonb_build_object('id',gen_random_uuid())),
 ('outsider',jsonb_build_object('id',gen_random_uuid())),
 ('company_a',jsonb_build_object('id',gen_random_uuid(),'name','QA temporária A')),
 ('company_b',jsonb_build_object('id',gen_random_uuid(),'name','QA temporária B'));
insert into auth.users(id,aud,role)
 select (payload->>'id')::uuid,'authenticated','authenticated' from qa_metrology_fixture where name in ('owner','contractor','outsider');
insert into private.members(user_id,role,company_id)
 select (f.payload->>'id')::uuid,case when f.name='owner' then 'owner' else 'contractor' end,
 case when f.name='contractor' then (select (payload->>'id')::uuid from qa_metrology_fixture where name='company_b') else null end
 from qa_metrology_fixture f where f.name='owner';
-- The company FK is populated after the companies exist.
insert into private.role_permissions values('contractor','read');
insert into qa_metrology_fixture
 select 'instrument',jsonb_build_object('id',gen_random_uuid(),'code','QA-ROLLBACK-ONLY','description','Instrumento temporário de QA','ownerCompanyId',(select payload->>'id' from qa_metrology_fixture where name='company_a'),'registrationStatus','ativo','operationalStatus','liberado para uso','periodicityMonths',null,'capabilities','[]'::jsonb);
insert into qa_metrology_fixture
 select 'event',jsonb_build_object('id',gen_random_uuid(),'instrumentId',(select payload->>'id' from qa_metrology_fixture where name='instrument'),'type','calibração externa','date','2026-10-05','nextDate','2027-04-05','certificateNumber','QA-SEM-PDF','rationale','QA transacional','decision','liberado para uso','attachmentPath','','points','[]'::jsonb,'checklist','[]'::jsonb);
grant select on qa_metrology_fixture to authenticated;
select set_config('request.jwt.claims',jsonb_build_object('sub',(select payload->>'id' from qa_metrology_fixture where name='owner'),'role','authenticated')::text,true);
set local role authenticated;
do $$declare instrument jsonb; rejected boolean=false;
begin
 if not public.my_permissions() @> '["read","register_event","release_instrument"]'::jsonb then raise exception 'QA owner ACL failed';end if;
 perform public.save_company((select payload from qa_metrology_fixture where name='company_a'));
 perform public.save_company((select payload from qa_metrology_fixture where name='company_b'));
 instrument=public.save_instrument((select payload from qa_metrology_fixture where name='instrument'),'','');
 if instrument->>'operationalStatus'<>'fora de uso' then raise exception 'QA forged master release failed';end if;
 perform public.save_metrological_event((select payload from qa_metrology_fixture where name='event'),false);
 if (select count(*) from public.metrological_events)<>1 then raise exception 'QA draft persistence failed';end if;
 begin
  perform public.save_metrological_event((select payload from qa_metrology_fixture where name='event'),true);
 exception when raise_exception then
  if sqlerrm not like '%stored PDF%' then raise;end if;
  rejected=true;
 end;
 if not rejected then raise exception 'QA missing stored PDF was accepted';end if;
 rejected=false;
 begin update public.instruments set operational_status='liberado para uso';
 exception when insufficient_privilege then rejected=true;end;
 if not rejected then raise exception 'QA direct client mutation allowed';end if;
 if public.evaluate_metrology_point(0.40,0.10,0.50,'mm','mm')<>'não conforme' or public.evaluate_metrology_point(0.39,0.10,0.50,'mm','mm')<>'conforme' or public.evaluate_metrology_point(0,0,1,'mm','cm')<>'pendente' then raise exception 'QA numeric boundary/unit failed';end if;
end$$;
reset role;
insert into private.members(user_id,role,company_id)
 select (payload->>'id')::uuid,'contractor',(select (payload->>'id')::uuid from qa_metrology_fixture where name='company_b') from qa_metrology_fixture where name='contractor';
select set_config('request.jwt.claims',jsonb_build_object('sub',(select payload->>'id' from qa_metrology_fixture where name='contractor'),'role','authenticated')::text,true);
set local role authenticated;
do $$begin
 if (select count(*) from public.instruments)<>0 or (select count(*) from public.metrological_events)<>0 or (select count(*) from public.audit_log)<>0 then raise exception 'QA cross-company isolation failed';end if;
 if (select count(*) from public.companies)<>1 then raise exception 'QA company isolation failed';end if;
end$$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',(select payload->>'id' from qa_metrology_fixture where name='outsider'),'role','authenticated')::text,true);
set local role authenticated;
do $$begin
 if public.my_permissions()<>'[]'::jsonb or (select count(*) from public.companies)<>0 or (select count(*) from public.instruments)<>0 then raise exception 'QA unlinked account gained access';end if;
end$$;
reset role;
update private.members set active=false where user_id=(select (payload->>'id')::uuid from qa_metrology_fixture where name='owner');
select set_config('request.jwt.claims',jsonb_build_object('sub',(select payload->>'id' from qa_metrology_fixture where name='owner'),'role','authenticated')::text,true);
set local role authenticated;
do $$begin
 if public.my_permissions()<>'[]'::jsonb or (select count(*) from public.instruments)<>0 then raise exception 'QA revocation failed';end if;
end$$;
reset role;
select set_config('request.jwt.claims','{}',true);
set local role anon;
do $$declare rejected boolean=false;begin
 begin perform * from public.instruments;exception when insufficient_privilege then rejected=true;end;
 if not rejected then raise exception 'QA anonymous read allowed';end if;
end$$;
reset role;
rollback;
select jsonb_build_object('transactional_checks_passed',true,'fixtures_rolled_back',true,'remaining_auth_users',(select count(*) from auth.users),'remaining_instruments',(select count(*) from public.instruments),'remaining_events',(select count(*) from public.metrological_events),'remaining_audit',(select count(*) from public.audit_log)) as qa_result;
