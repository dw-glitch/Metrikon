# Checkpoint de continuidade — 05/10/2026

## Estado atual

Metrikon publicado em https://metrikon.grcon-qualidade.workers.dev/. Fases 1 e 2 implementadas, testadas e publicadas. Banco remoto independente CCP CONSAG `aimvjsbrxnyqjurgicec`, cinco migrações aplicadas. Login/upload real do proprietário e validação com a LI oficial continuam pendentes; isso não equivale a liberação para uso metrológico real.

Código servido: `fe34977b02a3e0273f3260ca0428fbd10f363b33`. Cloudflare version ID: `fd07434b-113c-4bb3-bb06-8af285e19e29`. Execução de publicação aprovada: https://github.com/dw-glitch/GRCON/actions/runs/37324017303. A main do Metrikon pode conter documentação posterior ao código servido. Ver `docs/PUBLICACAO-FASES-1-2.md`.

Repositório autorizado: `dw-glitch/Metrikon`, main. Publicação pelo workflow isolado `.github/workflows/deploy-metrikon-cloudflare.yml` no branch `infra/metrikon-cloudflare-deploy` de `dw-glitch/GRCON`. A main e o Worker GRCON permanecem preservados. O login no painel Cloudflare rejeitou a verificação; o fluxo com GitHub Actions/Wrangler e secrets existentes foi confirmado e funcionou.

O usuário autorizou expressamente a continuidade das próximas fases. ConsagVINI permanece excluída. Não criar outro projeto Supabase, não reaplicar migrações e não recriar o proprietário.

## Funcionalidades implementadas

- Identidade Metrikon e logo original, navegação, dashboard, busca e exportação Excel filtrada.
- Empresas, ficha permanente, cadastro em cinco etapas, identificações independentes, grandezas/faixas e histórico de periodicidade.
- Cadastros auxiliares por empresa: tipos/famílias, áreas, setores, processos e locais, com ativo/inativo e auditoria. Sugestões de preenchimento preservam texto e histórico dos instrumentos.
- Fotos JPG/PNG/WebP e documentos PDF privados na ficha, até 10 MB, verificação de assinatura antes do envio e metadados reais ao registrar. Documentos vinculados não podem ser apagados pela limpeza de upload.
- LI XLSX/XLS/CSV em Worker, seleção de aba/cabeçalho, 21 campos independentes, prévia, duplicados/erros, seleção e confirmação humana. Até 20 MB/10.000 linhas/300 colunas; prévia visual de 200 e relatório CSV completo.
- Importação por lotes atômicos/idempotentes de 500, origem/linha e auditoria. Código existente preservado; UUIDs gerados no servidor; novos instrumentos fora de uso e sem datas/liberação importadas. Falha posterior preserva lotes anteriores e permite retomada na mesma tela.
- Fluxo manual inicial das fases 4–9: evento, certificado PDF, identidade, pontos, checklist, regra estrita e decisão humana. Cada ciclo permanece independente, rascunho não altera situação e concluído é imutável.
- Mascote preparado em componente/eventos, sem vídeo oficial.

## Supabase

Proprietário real `vinicio.silva@agnet.com.br`, UUID `87dd90f9-dd3f-4d92-948c-e8ce1afe0094`, já criado/confirmado/ativo; reserva de ativação consumida. Não pedir senha em chat nem recriar conta. Ver `docs/ATIVACAO-20261005.md`.

Migração nova `20261005135647_master_data_li_import.sql` aplicada. Tabelas `instrument_references`, `instrument_assets`, `instrument_import_batches` com RLS e grants de leitura; escritas por RPCs guardadas. Buckets de anexos e certificados privados e separados.

QA SQL transacional remoto aprovado com rollback, sem fixtures persistidas. Última conferência: zero empresas, instrumentos, cadastros auxiliares/lotes reais; bucket de anexos não público. Advisors não trouxeram nova advertência das tabelas; ACL privada intencionalmente inacessível a clientes e índices ainda sem uso são informativos. Auth mantém a advertência de proteção contra senhas vazadas desativada, descrita em `docs/FASES-1-2-20261005.md`.

## Certificados recebidos

14 PDFs individuais foram disponibilizados: 7 HI-LO, 5 calibres de solda, 1 calibrador elétrico e 1 conjunto digitalizado. Extração de texto nos 14, inspeção visual de modelos representativos e OCR das 19 páginas do conjunto digitalizado para identificar sua composição. Há PDFs com certificados dos padrões anexos e páginas de assinatura/avaliação.

Os dois ZIPs grandes retornaram 502 e não foram analisados. Os PDFs individuais permitem preparar os requisitos: grupos por escala/função/modo, unidade e faixa; ângulos em graus/minutos; fonte/medidor; papel do certificado principal e dos padrões; original integral; OCR como sugestão revisável. Ver `docs/REQUISITOS-CERTIFICADOS.md`.

Originais, valores individuais, imagens/OCR e dados pessoais não foram enviados ao repositório nem importados no banco. Amostras não são LI e não autorizam cadastro, alteração de datas ou liberação automática.

## Validação realizada

- `npm run verify`: 42 testes de domínio e PostgreSQL e build TypeScript/produção aprovados.
- `npm run test:ui`: 13 grupos Chromium, sem erros JavaScript; cadastro, evento/igualdade rejeitada, auditoria, catálogo, anexo, importação em Worker, exportação e sessão demonstrativa.
- Desktop 1440/1366/1280 e mobile 390 sem overflow nos cenários testados.
- PostgreSQL: UUID forjado, duplicates, lotes idempotentes, rollback, identificação/origem, metadados/autoria do anexo e isolamento entre empresas.
- GitHub Actions refez verify/UI/dry-run e aprovou deploy/smoke. Conferência adicional no navegador público dos menus e importador.

## Pendências e próxima ação

1. Validar login do proprietário, upload real e URL assinada pela interface. Site URL/recuperação de senha e usuários/permissões RHDD precisam de QA próprio.
2. Receber LI oficial e confirmar mapeamento, critérios, tolerâncias e periodicidades por processo. Não inventar parâmetros RHDD.
3. Próximo desenvolvimento: fase 3, laboratórios/padrões e rastreabilidade por evento, seguido de certificados/grupos conforme amostras. Ampliação do fluxo manual continua dependente de critérios e QA operacional.
4. RNC exige PR CONSAG 220 43; QR/etiquetas, competências, relatórios completos, extração assistida, notificações e mascote oficial permanecem nos checkpoints futuros.
5. Carga com milhares de registros, busca parcial otimizada e central integral de pendências ainda não concluídas.

Continuar deste estado. Preservar histórico, demonstração e testes. Detalhes de fases/limites em `docs/FASES-1-2-20261005.md`, plano em `docs/FASES-METRIKON.md` e parâmetros pendentes em `docs/PENDENCIAS-RHDD.md`. Não declarar login/upload real, leitura integral dos ZIPs ou fases futuras como concluídos.
