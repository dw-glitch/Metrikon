# Referências efetivamente verificadas

- PR-5290.00-22313-696-C1O-004_0001_0.pdf: lido integralmente (7 páginas), incorpora PR CONSAG 220 42 Rev. 11, 5 páginas. Fonte das regras metrológicas desta entrega.
- PR CONSAG 220 48 — Competência, Treinamento e Conscientização, Rev. 23: lido integralmente (9 páginas). Fase 13 será específica de metrologia, sem LMS.
- CE-5290.00-22313-856-C1O-679_0001_0.pdf: lido integralmente, exemplo de manômetro digital Rosemount, identificação individual, faixas distintas e dados em bar/MPa/% da amplitude. Não foi importado nem usado como template rígido.
- Prompt de requisitos anexado em 02/10/2026: fonte do escopo e fases, sem substituir o procedimento.
- Nome final Metrikon e logo: confirmados e enviados pelo proprietário em 05/10/2026. `public/metrikon-logo.png` preserva os bytes do anexo `Logo Metrikon_ Precisão e Tecnologia.png`. Favicon e ícones de instalação derivados apenas por redimensionamento do mesmo arquivo.
- Cores de marca: azul, azul escuro e teal alinhados à logo Metrikon. Cores semânticas de situação e contraste dos formulários preservados.

## Confirmações de domínio

| Requisito | Evidência | Implementação / classificação |
|---|---|---|
| Calibração e verificação distintas | §3.1.2 e §3.1.4 | Tipos próprios; regra confirmada |
| Frequência ajustável | §3.1.3 | Histórico de mudanças; regra confirmada; estrutura de auditoria é melhoria de software |
| Critério estrito com absolutos | §3.1.6 | Decimal/NUMERIC e testes de limite; regra confirmada |
| Análise qualitativa | §3.1.5 | Checklist manual extensível; labels extras do prompt são estrutura de software |
| Liberação depende das duas análises | §3.1.7 | Validação frontend e backend; regra confirmada |
| Reprovação, segregação, RNC e impacto | §3.1.7 | Aviso e preparação de decisão; workflow de RNC pendente da fase 11 |
| Identificação e situação | §3.1.1 e §3.1.8 | Ficha/identificações distintas; etiqueta própria pendente |
| Subcontratados incluídos | §3.1.10 | Empresas e instrumentos por proprietário; regra confirmada |
| Eventos concluídos imutáveis | Preservação de registros + requisito explícito | Melhoria de software |
| Situação inicial “fora de uso” | Não constitui regra geral confirmada | Hipótese temporária conservadora de protótipo, documentada nas pendências |

Os demais certificados/anexos, a LI real e as telas do sistema antigo não foram declarados validados nesta entrega. Não foi possível identificar a LI atual com segurança; uma lista de válvulas apareceu como candidato e foi rejeitada por escopo.

Supabase: documentação atual de RLS/Auth verificada e changelog de 02/10/2026 consultado. Nenhuma dependência de ltree/btree_gist/criptografia legada afetada pelo breaking change PostgreSQL 15.19/17.11 foi introduzida.
