# Fases Metrikon — estado em 05/10/2026

Fonte: plano original de 19 fases fornecido pelo usuário em `Texto colado(20261002-182251).txt`, lido integralmente, e código atual. Nome e identidade atualizados para Metrikon por confirmação do proprietário.

## Regra de continuidade

Comando do usuário em 05/10/2026: atualizar este repositório com a versão Metrikon mais recente e implementar as fases posteriores conforme novos comandos por este chat. Não iniciar outra fase automaticamente. Cada fase deve ter implementação, validação proporcional, correções, commit, evidências e atualização deste documento. Não recomeçar, não reaplicar migrações existentes e não declarar funcionalidades parciais como completas em produção.

## Estado e trabalho restante

| Fase | Tema | Estado atual | O que falta para concluir |
|---|---|---|---|
| 0 | Fundação | Identidade, Supabase independente, proprietário e Cloudflare publicados; QA público aprovado | Validar login, upload real, isolamento e URL assinada pela interface autenticada |
| 1 | Cadastro mestre | Implementado e publicado; cadastro conforme as imagens, LI automática, ficha, busca, Excel, cadastros auxiliares e anexos privados | Validar operações reais; preservar a referência obrigatória de Vinício sem reintroduzir campos extras |
| 2 | Importação da LI | XLSX/XLS/CSV em Worker, mapeamento, prévia, duplicados, confirmação e lotes idempotentes implementados/publicados; referência oficial e sequência armazenadas | Validar importação operacional autenticada com a LI oficial; preservar números, registros existentes e ordem da LI |
| 3 | Laboratórios e padrões | Não implementada | Cadastros, acreditação/escopo, rastreabilidade, certificados dos padrões e validade na data do controle |
| 4 | Eventos metrológicos | Fluxo manual de calibração/verificação e histórico implementados | Completar etapas de envio/retorno, vínculos com laboratório/padrões/procedimentos e validar periodicidades reais |
| 5 | Certificados | Upload manual, vínculo por ciclo, storage privado e comparação básica de identidade implementados | QA de armazenamento com usuário real e PDFs representativos; completar dados/conferência cadastral e anexos necessários |
| 6 | Resultados metrológicos | Pontos, grandezas/faixas, erro, incerteza, k, Veff, direção e unidades disponíveis | Validar grupos e diversidade dos certificados reais; completar apresentação e revisão dos resultados por grupo/faixa |
| 7 | Análise qualitativa | Checklist de 19 itens, observações, evidências e justificativa de não aplicável implementados | Confirmar aplicabilidade RHDD por família, melhorar vínculos de evidências e validar certificados reais |
| 8 | Análise quantitativa | Motor Decimal/NUMERIC estrito e testes críticos implementados | Completar visão de ponto crítico/pior caso e critérios por processo; validar análises com certificados reais |
| 9 | Decisão metrológica | Decisão humana, bloqueios confirmados, ciclo imutável e estrutura de restrição implementados | Definir e configurar matriz de autorização/uso condicionado; validar todos os cenários operacionais e suas evidências |
| 10 | Pendências e vencimentos | Dashboard e central inicial implementados; central limitada à página carregada | Consultar a base autorizada inteira, completar categorias/filtros/KPIs e alertas internos parametrizados |
| 11 | Ocorrências e impacto | Não implementada | Queda/dano/outros eventos, retirada de uso/recalibração, RNC referenciada e avaliação de impacto; fluxo definitivo depende do PR CONSAG 220 43 |
| 12 | QR Code e etiquetas | Rota protegida da ficha preparada | QR único, consulta rápida, controle de exposição, impressão e templates/dimensões configuráveis |
| 13 | Competências e autorizações | ACL privada e papéis básicos implementados | Colaboradores/funções, competências/evidências/validade e administração auditada de permissões; sem criar LMS |
| 14 | Relatórios e auditoria | Excel filtrado de instrumentos e auditoria inicial implementados | Relatórios/exportações de eventos, vencimentos, empresas, laboratórios, reprovações e pendências; auditoria paginada completa e modo auditor |
| 15 | Extração inteligente | Não implementada | PDF digital/OCR, identificação de campos, pré-preenchimento, fonte/evidência e revisão humana; começar após estabilizar o fluxo manual; IA não aprova calibração |
| 16 | Notificações externas | Não implementada | Teams, e-mail e alertas do navegador com destinatários, prazos e preferências configuráveis |
| 17 | Mascote | Componente e eventos preparados, sem vídeos | Integrar vídeos oficiais com transparência real, gatilhos, toggle e reduced-motion; preservar navegação |
| 18 | Hardening e produção | Parte das proteções e testes já aplicada | QA completo em produção, carga de milhares de instrumentos, segurança/RLS/storage, acessibilidade, recuperação/backup, regressões e PWA quando viável |

Fases 1–2 implementadas e publicadas, com correção cadastral e Número LI automático concluídos em 05/10/2026 (PR #2). Isso não equivale a QA operacional autenticado ou conclusão das fases futuras. A próxima fase de desenvolvimento permanece laboratórios e padrões. Estado atual e evidências em docs/CHECKPOINT.md e docs/PUBLICACAO-CADASTRO-LI-20261005.md.

## Validações disponíveis

A correção cadastral foi validada por 47 testes de domínio/PostgreSQL, build TypeScript/Vite, Wrangler dry-run e 13 grupos Chromium. Smoke transacional remoto confirmou atribuição e preservação da LI com rollback. CI e deploy repetiram testes; QA público e metadados do código servido aprovados. Login/upload autenticados pela interface continuam pendentes.

## Informações RHDD ainda necessárias

- QA operacional do mapeamento/importação com a LI oficial já fornecida e armazenada.
- Pessoas/funções autorizadas, critérios de uso condicionado, tolerâncias e periodicidades por processo.
- Procedimentos de verificação interna e PR CONSAG 220 43 para RNC/impactos.
- Modelo e dimensões das etiquetas, exposição dos dados por QR, prazos e destinatários de alertas.
- Certificados reais representativos e vídeos oficiais para as fases correspondentes.

Essas lacunas devem permanecer documentadas e configuráveis em `docs/PENDENCIAS-RHDD.md`. Implementar estruturas seguras quando possível, sem inventar regras operacionais.
