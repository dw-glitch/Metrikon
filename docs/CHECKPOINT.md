# Checkpoint de continuidade — 05/10/2026

## Estado atual
Metrikon publicado em https://metrikon.grcon-qualidade.workers.dev/. Código servido: `3f7094962ebe9c2ea9ee41511d0e904558456726`; Cloudflare version ID: `f7692107-0f3c-4937-a5c4-8a87be13a95c`. PR #2 integrada à main e publicação aprovada: https://github.com/dw-glitch/GRCON/actions/runs/37347869106. Detalhes em docs/PUBLICACAO-CADASTRO-LI-20261005.md.

Fases 1–2 implementadas e publicadas, com a correção cadastral mais recente concluída. A fase 3 — laboratórios/padrões — permanece por implementar. Login/upload real do proprietário pela interface e QA operacional continuam pendentes.

## Regras obrigatórias
- Cadastro conforme as imagens do procedimento atual, somente com os campos documentados em docs/COMPATIBILIDADE-CADASTRO-ATUAL-20261005.md.
- Não reintroduzir Código interno RHDD ou campos genéricos no formulário sem instrução expressa de Vinício.
- Número LI automático pelo banco, seguindo a ordem da referência oficial. No checkpoint: próximo CE-5290.00-22313-856-C1O-843, linha 850.
- Edição preserva o número; importação vincula os números existentes na LI; falha transacional não consome a sequência.
- Laboratório acreditado, Calibração aceita, Aceito com restrição, Status do cadastro e Situação do equipamento são dados independentes.
- Regra quantitativa estrita: |Erro| + |Incerteza| < Tolerância. Nenhuma conversão automática.
- Mudanças nos campos, obrigatoriedades e critérios dependem de determinação do proprietário.
- Não iniciar outra fase automaticamente.

## Repositório, publicação e banco
Repositório: dw-glitch/Metrikon. Deploy isolado via .github/workflows/deploy-metrikon-cloudflare.yml, branch infra/metrikon-cloudflare-deploy de dw-glitch/GRCON. Worker: metrikon. A rotina fixa o SHA validado e não publica automaticamente toda alteração da main. Não alterar main/Worker GRCON para esta entrega.

Supabase independente CCP CONSAG, ref aimvjsbrxnyqjurgicec, oito migrações remotas. Proprietário real vinicio.silva@agnet.com.br já criado, confirmado e ativo. Não recriar conta, pedir senha no chat, criar outro projeto ou usar ConsagVINI.

Nova migração remota: 20261005171946_li_number_auto_assignment; arquivo local: 20261005163000_li_number_auto_assignment.sql. master_data_li_import também tem timestamps históricos local/remoto diferentes. Não reaplicar migrações existentes por causa dessas diferenças.

Referência oficial armazenada: 733 códigos originais (001–733) e 109 linhas planejadas (734–842). O banco conserva oito empresas da LI, 842 entradas, zero instrumentos e zero entradas vinculadas no fim desta entrega. Nenhum fixture do smoke transacional permaneceu.

## Funcionalidades e validação
Identidade e logo Metrikon, dashboard, busca, ficha, Excel filtrado, empresas, cadastro conforme referência, catálogos auxiliares, anexos privados, importação XLSX/XLS/CSV em Worker com mapeamento/prévia/duplicados/confirmação e lotes idempotentes. Fotos/documentos cadastrais e certificados do ciclo usam buckets privados separados.

Fluxo manual de calibração/verificação preserva os campos atuais, anexos PDF/XLSX/XLS até 16 MB, checklist, cálculo estrito e decisão humana. Rascunhos não alteram situação; ciclos concluídos são imutáveis. A ampliação operacional das fases futuras ainda está pendente.

47 testes de domínio/PostgreSQL, build TypeScript/Vite, Wrangler dry-run e 13 grupos Chromium passaram localmente e no GitHub. Desktop e mobile testados sem overflow; zero erros JavaScript. Smoke SQL remoto com rollback passou antes e depois da migração. Pós-deploy público e metadados do SHA servido aprovados. Evidências anexadas às execuções GitHub.

## Amostras e pendências
14 PDFs individuais de certificados foram examinados em entregas anteriores, incluindo modelos HI-LO, calibres de solda, calibrador elétrico e conjunto digitalizado. Os dois ZIPs grandes retornaram 502 e não foram analisados. Não declarar leitura integral desses ZIPs. Originais e dados pessoais não foram publicados no Git nem cadastrados automaticamente. Ver docs/REQUISITOS-CERTIFICADOS.md.

Pendências operacionais: login real do proprietário, upload e reabertura assinada pela interface, isolamento entre empresas, expiração de URLs e QA de importação real. Parâmetros RHDD, responsáveis/autorização, critérios/periodicidades, RNC PR CONSAG 220 43, etiquetas, notificações e vídeos oficiais continuam nos checkpoints futuros.

Próxima fase de desenvolvimento: laboratórios e padrões, preservando o cadastro atual. Não reiniciar as fases anteriores nem declarar QA autenticado ou fases futuras como concluídos.
