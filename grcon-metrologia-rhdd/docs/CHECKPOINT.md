# Checkpoint de continuidade — atualizado em 05/10/2026

## Estado real

Fase atual: **FASE 0 — fundação local testada e banco remoto ativado; primeiro usuário, QA autenticado e publicação pendentes.** Projeto novo: **CCP CONSAG**, ref `aimvjsbrxnyqjurgicec`. ConsagVINI permanece excluída. Ver `docs/ATIVACAO-20261005.md` para evidências e limites da validação.

Também foi implementado o cadastro mestre inicial e um protótipo manual das fases 4–9 para demonstrar o ciclo. Isso **não significa que todas essas fases estejam concluídas em produção**. Não avançar para importação real, RNC ou liberações operacionais até o ambiente novo ser ativado e os dados/regras correspondentes serem confirmados.

Commit do código validado: `ddd5f533d8ba5faa85264a7a8cb3e6c34f7695b7`.
Commit de fundação: `8bcdb40`.
A entrega contém um commit posterior de documentação/checkpoint. O HEAD final está no arquivo `CHECKPOINT.json` dentro do pacote e no bundle Git.

## Funcionalidades prontas no protótipo

- Identidade oficial, design system, navegação, dashboard e busca.
- Instrumentos/empresas, cadastro em cinco etapas, identificações separadas, ficha, faixas/grandezas e histórico de periodicidade.
- Evento manual em seis etapas, PDF, comparação de identidade, pontos, checklist, regra estrita e decisão humana.
- Preservação dos ciclos; rascunho não altera situação operacional; próxima data confirmada manualmente.
- Exportação Excel filtrada de instrumentos; auditoria demonstrável/exportável.
- Supabase Auth e acesso ao banco configurados para CCP CONSAG, aguardando o primeiro usuário real.
- Migração com tabelas, índices, ACL, RLS, RPC, auditoria e storage privado testada em PostgreSQL local via PGlite.
- Componente/eventos do mascote preparados, sem vídeo ou redesenho.

## Testes executados

- `npm test`: **31 testes passaram** (inclui 15 subtestes de PostgreSQL, 6 subtestes de ativação do proprietário e os testes do domínio), após incluir o hardening remoto e a reserva do proprietário.
- `npm run build`: TypeScript estrito + compilação de produção passaram.
- `npm run test:ui`: **10 grupos de verificações Chromium passaram**, sem erros de JavaScript.
- Cadastro completo → PDF → resultados → checklist → análise de igualdade não conforme → correção → decisão → histórico → próxima data.
- Busca por série; Excel de um registro com filtro conferido; navegação de todos os menus; retorno entre etapas preservando dados.
- Desktop 1440/1366/1280 e mobile 390, sem overflow horizontal da página.
- Demonstração HTML standalone aberta como arquivo local: logo carregada, dashboard funcionando, sem erros de JavaScript e sem instalar Node.
- Auditoria de dependências de produção: zero vulnerabilidades conhecidas reportadas na verificação desta entrega.

O agent-browser não conseguiu iniciar seu daemon no ambiente. A verificação foi realizada diretamente com Chromium Headless Shell via Playwright, com servidor e navegador no mesmo processo de teste. Nenhuma verificação de interface foi declarada concluída com base apenas na compilação.

## Testes ainda pendentes

- Banco e bucket já provisionados no Supabase real, duas migrações aplicadas e advisors sem ERROR/WARN. SQL transacional remoto aprovado; upload e URLs assinadas com usuário real ainda pendentes.
- Login, usuários RHDD e permissões reais; convites e recuperação de senha.
- Publicação Vercel em novo projeto/URL e QA de produção.
- LI real e diversidade completa de certificados (elétrico multigrandeza, HI-LO, durômetro, esquadro, escaneado, RBC). Os testes de upload desta entrega usam PDF sintético explícito; não representam validação documental dessas famílias.
- Importação xlsx/xls/csv, laboratórios/padrões, RNC/impactos, QR/etiquetas, competências e integrações nas fases respectivas.
- Carga de milhares de instrumentos, pesquisa parcial otimizada e central de pendências integral.

## Principais arquivos

`src/App.tsx`, `src/styles.css`, `src/components/InstrumentForm.tsx`, `src/components/EventForm.tsx`, `src/components/Primitives.tsx`, `src/domain/metrology.ts`, `src/domain/types.ts`, `src/services/repository.ts`, `src/services/supabase.ts`, `supabase/migrations/20261002184038_metrology_foundation.sql`, `tests/database.test.ts`, `tests/metrology.test.ts`, `tests/browser.mjs`, `scripts/build-demo.mjs`, `vercel.json` e documentação em `docs/`.

## Próxima ação concreta

**Correção do usuário em 02/10/2026: ConsagVINI não poderá ser usada.** Em 05/10/2026 o usuário conectou outro destino, CCP CONSAG, criado por ele no plano Free. Banco e bucket já ativados nesse projeto; não criar outro projeto nem reaplicar migrações. O proprietário definido pelo usuário é `vinicio.silva@agnet.com.br`. A migração `20261005115131_owner_bootstrap.sql` reserva esse e-mail em tabela privada e ativa seu UUID uma única vez após confirmação no Auth. Foi testada localmente e no banco real com rollback; nenhum usuário ou senha real foi criado. Falta criar o acesso no painel, conforme `docs/PRIMEIRO-ACESSO.md`. Depois concluir login/upload/URL assinada, repositório separado e publicação própria. Não reutilizar banco do GRCON. Uma nova organização na mesma conta não amplia o limite de dois projetos gratuitos ativos entre organizações em que ela é Owner/Administrator. Concluir QA remoto da fase 0 antes de retomar a fase 1/2 com a LI oficial.

## Regra para a próxima sessão

Continuar deste checkpoint e desses commits; não recomeçar. Preservar a demonstração e os testes já aprovados. Não publicar as funcionalidades pendentes como concluídas. Os parâmetros RHDD continuam em `docs/PENDENCIAS-RHDD.md`.
