# Publicação do cadastro fiel e Número LI automático — 05/10/2026

## Entrega
- PR: https://github.com/dw-glitch/Metrikon/pull/2
- Código servido: `3f7094962ebe9c2ea9ee41511d0e904558456726`.
- URL: https://metrikon.grcon-qualidade.workers.dev/
- Cloudflare version ID: `f7692107-0f3c-4937-a5c4-8a87be13a95c`.
- Deploy aprovado: https://github.com/dw-glitch/GRCON/actions/runs/37347869106
- CI da PR aprovado: https://github.com/dw-glitch/Metrikon/actions/runs/37347596643

## Comportamento
O formulário de instrumento contém somente os campos da ficha de referência definidos por Vinício, com Número LI informativo e automático. Código interno RHDD, descrição genérica, tipo/família, fabricante, TAG, patrimônio, empresas e demais campos extras deixaram o fluxo de cadastro. A ficha, busca, exportação e importação foram alinhadas ao mesmo conjunto. O ciclo de calibração mantém seus dados e decisões independentes.

O banco bloqueia transacionalmente a referência oficial ao cadastrar. Com a base atual, o próximo número é CE-5290.00-22313-856-C1O-843, linha 850. A atribuição avança a sequência somente junto ao cadastro confirmado. Edição mantém o número; código inventado fora da LI oficial é rejeitado. Importação vincula instrumentos aos números existentes na referência oficial.

Referência obrigatória: docs/COMPATIBILIDADE-CADASTRO-ATUAL-20261005.md. Mudanças futuras nos campos e significados dependem de determinação de Vinício.

## Banco
Projeto independente CCP CONSAG: `aimvjsbrxnyqjurgicec`. Migração remota aplicada: `20261005171946_li_number_auto_assignment`; SQL versionado: `supabase/migrations/20261005163000_li_number_auto_assignment.sql`. Não reaplicar a migração pela diferença do timestamp. O projeto possui oito migrações; a versão remota de master_data_li_import é 20261005141533, enquanto o arquivo local histórico usa 20261005135647.

Smoke com a identidade do proprietário por SQL e BEGIN/ROLLBACK passou antes e depois da aplicação. Criou temporariamente 843/linha 850, confirmou incremento para 844/851 e preservação do número em uma edição com número forjado. Após rollback: zero instrumentos, zero vínculos de LI, próximo número 843, próxima linha 850. O teste não equivale a login real pela interface.

Os advisors de segurança permaneceram iguais aos anteriores, sem novo aviso introduzido pela migração.

## Validação
47 testes de domínio/PostgreSQL, TypeScript/Vite build, Wrangler dry-run e 13 grupos Chromium aprovados localmente e novamente no GitHub. Cadastro sem campos extras, busca por série, Excel filtrado, importação em Worker, ciclo com XLSX e decisões independentes, anexos, desktop 1440/1366/1280 e mobile 390 passaram sem erros de JavaScript.

O deploy repetiu os testes antes de publicar. Smoke público posterior aprovou metadados do mesmo SHA, página, rota SPA, logo, manifesto e login desktop/mobile. Os metadados servidos também foram conferidos diretamente.

## Pendências
Login do proprietário e upload/abertura real de PDF/XLSX/XLS com sessão autenticada pela interface, isolamento operacional e expiração de URL assinada continuam pendentes. A próxima fase de desenvolvimento é laboratórios e padrões; esta entrega conclui a correção cadastral e não implementa essa fase.
