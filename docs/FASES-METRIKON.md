# Fases Metrikon — estado em 05/10/2026

Fonte: plano original de 19 fases fornecido pelo usuário em `Texto colado(20261002-182251).txt`, lido integralmente, e código atual. Nome e identidade atualizados para Metrikon por confirmação do proprietário.

## Regra de continuidade

Comando do usuário em 05/10/2026: atualizar este repositório com a versão Metrikon mais recente e implementar as fases posteriores conforme novos comandos por este chat. Não iniciar outra fase automaticamente. Cada fase deve ter implementação, validação proporcional, correções, commit, evidências e atualização deste documento. Não recomeçar, não reaplicar migrações existentes e não declarar funcionalidades parciais como completas em produção.

## Estado e trabalho restante

| Fase | Tema | Estado atual | O que falta para concluir |
|---|---|---|---|
| 0 | Fundação | Arquitetura, identidade Metrikon, banco separado, storage privado, proprietário e código local validados; repositório criado pelo usuário | Publicar na Cloudflare em Worker/URL próprios; validar login, upload real, acesso isolado e URL assinada pela interface |
| 1 | Cadastro mestre | Cadastro de instrumentos/empresas, ficha, busca, identificações e faixas implementados | Cadastros próprios de tipos, áreas, setores, processos e locais; fotos/documentos cadastrais; validar operações e escopos reais |
| 2 | Importação da LI | Não implementada | Importar xlsx/xls/csv com mapeamento, prévia, validação, duplicidades e confirmação; validar a LI oficial; preservar registros existentes |
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

Nenhuma fase é declarada integralmente concluída em produção. A fundação e partes do cadastro/ciclo manual estão implementadas e testadas localmente. As próximas fases complementam essa base.

## Validações disponíveis

A versão Metrikon foi validada por 31 testes de domínio/PostgreSQL, compilação TypeScript/produção e 10 grupos Chromium, além da demonstração standalone. Houve QA transacional de RLS/ACL no banco real, e confirmação do proprietário ativo e da marca Metrikon. Isso não substitui login/upload autenticados e QA do app publicado.

## Informações RHDD ainda necessárias

- LI atual dos equipamentos e significado das colunas.
- Pessoas/funções autorizadas, critérios de uso condicionado, tolerâncias e periodicidades por processo.
- Procedimentos de verificação interna e PR CONSAG 220 43 para RNC/impactos.
- Modelo e dimensões das etiquetas, exposição dos dados por QR, prazos e destinatários de alertas.
- Certificados reais representativos e vídeos oficiais para as fases correspondentes.

Essas lacunas devem permanecer documentadas e configuráveis em `docs/PENDENCIAS-RHDD.md`. Implementar estruturas seguras quando possível, sem inventar regras operacionais.
