# Publicação da fase 3 — 05/10/2026

## Versão e evidências
- PR integrada: https://github.com/dw-glitch/Metrikon/pull/3
- Código servido: `d5f1b9f827ba26e6a4d761c368bee39630f670ff`.
- URL: https://metrikon.grcon-qualidade.workers.dev/
- Cloudflare version ID: `0c98096f-ceb5-48f6-b39f-254aba4d3ec0`.
- Deploy aprovado: https://github.com/dw-glitch/GRCON/actions/runs/37352167598
- CI da PR aprovado: https://github.com/dw-glitch/Metrikon/actions/runs/37351805611
- Workflow isolado da GRCON, branch infra/metrikon-cloudflare-deploy, commit `cc7269d27ccbd1d1f51c1cde65a5f208ae81563e`, somente Worker metrikon.

## Comportamento publicado
Menu Laboratórios e padrões, com cadastros por empresa, acreditação declarada/escopo/intervalo, padrões e certificados imutáveis versionados. Anexos privados PDF/XLSX/XLS até 16 MB; URLs assinadas de 60 segundos. Vínculos opcionais por controle com snapshots reconstruídos pelo servidor e validade histórica na data do evento. Renovar, renomear ou inativar não reescreve o ciclo anterior. Não presume validade, periodicidade, equivalência de escopo, aceitação ou autorização de uso.

InstrumentForm permaneceu sem alterações nesta fase. A LI automática e os campos/decisões manuais independentes continuam preservados. Especificação em docs/FASE-3-20261005.md.

## Banco e smoke
Projeto independente CCP CONSAG: `aimvjsbrxnyqjurgicec`. Nova migração remota: `20261005175539_laboratories_standards_traceability`; arquivo SQL local: `supabase/migrations/20261005172922_laboratories_standards_traceability.sql`. Nove migrações remotas; não reaplicar versões antigas por diferenças históricas de timestamp.

Após aplicar a migração, o smoke BEGIN/ROLLBACK usou papel authenticated e identidade do proprietário ativo, validando os RPCs, versão e autor atribuídos pelo servidor, Número LI 843, snapshot não forjável, validade em 2025 e expiração em 2026, renovação como versão 2, preservação do snapshot após renomeação/inativação e rejeição de alteração de certificado. Também confirmou ausência de EXECUTE do cliente no núcleo anterior do evento.

Após rollback: zero laboratórios, padrões, certificados de padrões, snapshots e instrumentos; zero LI vinculadas; próxima LI 843, linha 850. As oito empresas e as 842 entradas oficiais foram preservadas. O smoke não realizou login real nem upload pelo Storage API; isso continua pendente. Os testes PostgreSQL locais cobrem arquivos/metadados, conclusão imutável e RLS entre empresas.

Advisors de segurança permaneceram iguais à linha de base, sem aviso novo: quatro INFO nas ACL privadas sem políticas, intencionalmente acessadas por funções guardadas, e WARN pré-existente do Auth sobre proteção de senha vazada desabilitada. Referências: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy e https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection.

## Validação
59 testes de domínio/PostgreSQL, TypeScript/Vite, Wrangler dry-run e 16 grupos Chromium passaram localmente, na CI e no deploy. Desktop/mobile sem overflow e zero erros JavaScript. Evidências da tela nova e do ciclo metrológico estão nos artefatos das execuções acima.

Smoke público pós-deploy aprovou HTTP, rota SPA, logo, manifesto, configuração operacional e tela de login desktop/mobile. deployment-meta.json foi conferido diretamente e apresenta o SHA e runId acima.

## Pendências e continuidade
QA operacional autenticado: login do proprietário, cadastro com evidências reais, upload/reabertura de anexos privados pela interface, expiração de URLs e isolamento operacional. Não declarar esses fluxos como testados com usuário real. A próxima fase é 4 — eventos metrológicos, somente mediante novo comando. Nenhuma fase posterior foi iniciada automaticamente.
