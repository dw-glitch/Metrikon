-- Final app identity confirmed by the proprietor on 2026-10-05.
-- Prior applied migrations remain unchanged; operational data and ACL are preserved.
update public.system_settings
set value = '{"appName":"Metrikon"}'::jsonb,
    classification = 'confirmed_rule',
    source = 'Nome final e logo confirmados pelo proprietário em 05/10/2026'
where key = 'brand';
