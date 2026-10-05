# Arquitetura e isolamento

Frontend: React + TypeScript + Vite. Domínio em `src/domain`; acesso ao banco em `src/services`; formulários em `src/components`. Nada foi importado do runtime do GRCON. A identidade atual é Metrikon, com a logo fornecida pelo proprietário; nenhum recurso de marca GRCON é servido.

## Persistência

Instrumento permanente → eventos metrológicos → grupos de grandeza/unidade → pontos de resultado. Cada evento tem checklist, certificado e decisão. O JSON do evento é um snapshot manual e os resultados normalizados são derivados na mesma transação pelo banco. Decisões concluídas não são atualizáveis pelo cliente. Drafts podem ser revisados antes da conclusão.

As extensões do cadastro ficam em JSON tipado durante a fundação. Grandezas/faixas, resultados, histórico, ACL e decisões têm tabelas próprias. Extração/OCR não participa da aprovação. A futura arquitetura deve manter entradas extraídas separadas dos dados revisados.

## Tabelas desta fundação

`profiles`, `companies`, `instruments`, `instrument_measurement_capabilities`, `instrument_periodicity_history`, `metrological_events`, `calibration_result_groups`, `calibration_points`, `qualitative_review_items`, `certificates`, `metrological_decisions`, `conditional_use_restrictions`, `audit_log`, `system_settings`.

`private.members`, `private.role_permissions`, `private.user_permissions`: autorização independente de perfis editáveis ou JWT de usuário. As seis funções/perfis iniciais existem como valores de domínio; apenas o owner recebe permissões provisórias de bootstrap. Uso condicionado e aceitação de divergências exigem concessão explícita mesmo para owner.

## Entidades planejadas por fase

| Fase | Entidades / recursos |
|---|---|
| 1, evolução | instrument_types, areas, sectors, processes, locations, instrument_identifiers (atualmente campos tipados distintos na ficha) |
| 2 | jobs/linhas/mapeamentos de importação da LI, duplicidades e confirmação assistida |
| 3 | laboratories, laboratory_accreditations, standards, standard_certificates e vínculos N:N por evento |
| 5, evolução | attachments, evidências e verificação de assinatura/tipo de documento |
| 7, evolução | qualitative_reviews, templates versionados do checklist |
| 8, evolução | quantitative_reviews e versões de tolerâncias por processo, grandeza e faixa |
| 11 | equipment_occurrences, impact_assessments, rnc_references (sem workflow inventado da PR 220 43) |
| 13 | functions, competencies, person_competencies, training_evidences, authorizations |
| 15 | certificate_extractions e revisão humana da leitura |
| 16 | notifications e integrações externas autorizadas |

## Segurança

Todas as tabelas públicas têm RLS e grants de leitura limitados; alterações operacionais passam por RPC. Os wrappers públicos são SECURITY INVOKER. As funções privadas que efetivamente escrevem são SECURITY DEFINER com `search_path=''`, validação de `auth.uid()`, vínculo ativo, permissão e escopo empresarial. Não há chave privilegiada no frontend nem políticas que autorizem alterações só porque o usuário está autenticado.

Certificados usam bucket privado; nenhum caminho de PDF é publicamente acessível. Sem sobrescrita e sem política de exclusão. A identificação do responsável pela decisão vem do banco. Campos de situação operacional e próxima data do cadastro são protegidos contra alteração direta via RPC de cadastro.

## Limites conhecidos desta primeira entrega

- Dashboard conta toda a base autorizada; lista de pendências ainda usa a página atual na produção, com aviso explícito. A fase 10 terá filtros/consultas próprios e todas as categorias.
- Busca atual utiliza ILIKE para permitir correspondência de identificações parciais. Índices de código/TAG/série/empresa/status/data estão presentes; índice FTS está preparado, mas a pesquisa geral ainda não usa FTS. A busca por conteúdo parcial precisa de pg_trgm e medição na fase de desempenho para bases grandes.
- Auditoria exibida limitada aos últimos 100 registros. Exportação integral/paginada de auditoria entra na fase 14.
- Estado “a vencer” não assume um limiar RHDD; dashboard expõe janelas explícitas de 7/30/60 dias.
- Manifest preparado, mas PWA instalável/service worker/offline operacional ainda não concluídos.
- Sem consumo de IA, OCR, Teams, e-mail ou vídeos. Sem política automática de prazo ou periodicidade.
