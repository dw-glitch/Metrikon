# Checkpoint de continuidade — atualizado em 05/10/2026

## Estado real

Fase atual: **FASE 0 — fundação local testada, banco remoto ativado e proprietário real confirmado; QA autenticado pela interface e publicação pendentes.** Projeto novo: **CCP CONSAG**, ref `aimvjsbrxnyqjurgicec`. ConsagVINI permanece excluída. Ver `docs/ATIVACAO-20261005.md` para evidências e limites da validação.

Também foi implementado o cadastro mestre inicial e um protótipo manual das fases 4–9 para demonstrar o ciclo. Isso **não significa que todas essas fases estejam concluídas em produção**. Não avançar para importação real, RNC ou liberações operacionais até o ambiente novo ser ativado e os dados/regras correspondentes serem confirmados.

Identidade final **Metrikon**, confirmada em 05/10/2026. Logo original aplicada; ver `docs/IDENTIDADE-METRIKON.md`. O commit validado atual está em `CHECKPOINT.json` dentro da entrega.
Commit de fundação: `8bcdb40`.
A entrega contém um commit posterior de documentação/checkpoint. O HEAD final está no arquivo `CHECKPOINT.json` dentro do pacote e no bundle Git.

## Funcionalidades prontas no protótipo

- Identidade Metrikon, logo enviada pelo proprietário, navegação, dashboard e busca.
- Instrumentos/empresas, cadastro em cinco etapas, identificações separadas, ficha, faixas/grandezas e histórico de periodicidade.
- Evento manual em seis etapas, PDF, comparação de identidade, pontos, checklist, regra estrita e decisão humana.
- Preservação dos ciclos; rascunho não altera situação operacional; próxima data confirmada manualmente.
- Exportação Excel filtrada de instrumentos; auditoria demonstrável/exportável.
- Supabase Auth e acesso ao banco configurados para CCP CONSAG; proprietário real criado, confirmado e ativo.
- Migração com tabelas, índices, ACL, RLS, RPC, auditoria e storage privado testada em PostgreSQL local via PGlite.
- Componente/eventos do mascote preparados, sem vídeo ou redesenho.

## Testes executados

- `npm test`: **31 testes passaram** (inclui 15 subtestes de PostgreSQL, 6 subtestes de ativação do proprietário e os testes do domínio), após incluir o hardening remoto, a reserva do proprietário e a identidade Metrikon.
- `npm run build`: TypeScript estrito + compilação de produção passaram.
- `npm run test:ui`: **10 grupos de verificações Chromium passaram**, sem erros de JavaScript.
- Cadastro completo → PDF → resultados → checklist → análise de igualdade não conforme → correção → decisão → histórico → próxima data.
- Busca por série; Excel de um registro com filtro conferido; navegação de todos os menus; retorno entre etapas preservando dados.
- Desktop 1440/1366/1280 e mobile 390, sem overflow horizontal da página.
- Demonstração HTML standalone aberta como arquivo local: logo carregada, dashboard funcionando, sem erros de JavaScript e sem instalar Node.
- Auditoria de dependências de produção: zero vulnerabilidades conhecidas reportadas na verificação desta entrega.

O agent-browser não conseguiu iniciar seu daemon no ambiente. A verificação foi realizada diretamente com Chromium Headless Shell via Playwright, com servidor e navegador no mesmo processo de teste. Nenhuma verificação de interface foi declarada concluída com base apenas na compilação.

## Testes ainda pendentes

- Banco e bucket já provisionados no Supabase real, quatro migrações aplicadas e advisors sem ERROR/WARN. SQL transacional remoto aprovado; upload e URLs assinadas com usuário real ainda pendentes.
- Login, usuários RHDD e permissões reais; convites e recuperação de senha.
- Publicação Cloudflare em novo projeto/URL e QA de produção.
- LI real e diversidade completa de certificados (elétrico multigrandeza, HI-LO, durômetro, esquadro, escaneado, RBC). Os testes de upload desta entrega usam PDF sintético explícito; não representam validação documental dessas famílias.
- Importação xlsx/xls/csv, laboratórios/padrões, RNC/impactos, QR/etiquetas, competências e integrações nas fases respectivas.
- Carga de milhares de instrumentos, pesquisa parcial otimizada e central de pendências integral.

## Principais arquivos

`src/App.tsx`, `src/styles.css`, `src/components/InstrumentForm.tsx`, `src/components/EventForm.tsx`, `src/components/Primitives.tsx`, `src/domain/metrology.ts`, `src/domain/types.ts`, `src/services/repository.ts`, `src/services/supabase.ts`, `supabase/migrations/20261002184038_metrology_foundation.sql`, `tests/database.test.ts`, `tests/metrology.test.ts`, `tests/browser.mjs`, `scripts/build-demo.mjs`, `vercel.json` e documentação em `docs/`.

## Próxima ação concreta

**Correção do usuário em 02/10/2026: ConsagVINI não poderá ser usada.** Em 05/10/2026 o usuário conectou outro destino, CCP CONSAG, criado por ele no plano Free. Banco e bucket já ativados nesse projeto; não criar outro projeto nem reaplicar migrações. O proprietário `vinicio.silva@agnet.com.br` já foi criado pelo usuário, confirmado e ativado automaticamente no UUID `87dd90f9-dd3f-4d92-948c-e8ce1afe0094`. A migração `20261005115131_owner_bootstrap.sql` foi testada localmente e no banco real; a reserva agora está consumida. Não solicitar senha nem recriar conta. Repositório confirmado e autorizado pelo usuário: `dw-glitch/Metrikon`, main, em 05/10/2026. Atualizar a versão anterior com a identidade final Metrikon e manter código/configuração/testes na raiz. O histórico anterior será preservado. A continuidade das fases posteriores aguarda comando explícito do usuário; plano em `docs/FASES-METRIKON.md`. Próxima etapa da fase 0: publicação em novo Worker Cloudflare, com raiz do repositório e variáveis de `deployment-public.env.example`. Depois concluir login/upload/URL assinada e QA remoto da fase 0 antes de retomar a fase 1/2 com a LI oficial.

## Regra para a próxima sessão

Continuar deste checkpoint e desses commits; não recomeçar. Preservar a demonstração e os testes já aprovados. Não publicar as funcionalidades pendentes como concluídas. Os parâmetros RHDD continuam em `docs/PENDENCIAS-RHDD.md`.

## Verificação do envio GitHub

O commit de atualização `07eb441` preserva o upload anterior e organiza os 49 arquivos do código atual na raiz. A primeira execução GitHub Actions aprovou os 31 testes e o build, mas a espera pela mensagem `Local:` no console expirou antes dos testes da interface. O teste agora verifica a resposta HTTP do servidor, registra diagnósticos em caso de falha e usa porta estrita. Essa correção afeta apenas o executor de QA. Os 10 grupos Chromium passaram localmente com `CI=true npm run test:ui`, sem erros de JavaScript. O resultado remoto correspondente é registrado pelo workflow GitHub Actions.
