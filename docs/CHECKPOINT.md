# Checkpoint de continuidade — 06/10/2026

## Estado atual
Metrikon mínimo publicado em https://metrikon.grcon-qualidade.workers.dev/. Código servido: `707b08196ef738b818f56e6c882d7ae8373ea943`; Cloudflare version ID: `ac74f78f-cc72-408b-a0f1-1c67b467e077`. PR #5 integrada: https://github.com/dw-glitch/Metrikon/pull/5. CI: https://github.com/dw-glitch/Metrikon/actions/runs/37447344208. Publicação: https://github.com/dw-glitch/GRCON/actions/runs/37447700978. Ver PUBLICACAO-SCC-20261006.md e CONFORMIDADE-SCC-PRINTS-20261006.md.

O comando de Vinício e a anotação do responsável substituem o roteiro anterior de 19 fases. A interface tem somente **Cadastro** e **Monitoramento**, com gestão de acessos no cabeçalho do proprietário. Plano vigente: PLANO-MINIMO-20261006.md. Não iniciar automaticamente outra fase nem reintroduzir módulos avançados.

## Regras vigentes
- Cadastro somente com os campos SCC documentados em COMPATIBILIDADE-CADASTRO-ATUAL-20261005.md, reunindo equipamento e calibração em uma tela.
- Não reintroduzir Código interno RHDD, fabricante, TAG ou campos genéricos sem novo comando.
- Restrição é texto obrigatório quando Aceito com restrição = Sim; Empresa contratada é nome obrigatório quando o equipamento é de contratada. Dados não aplicáveis são removidos somente da nova proposta.
- Pergunta completa sobre rastreabilidade e validade dos certificados dos padrões aparece destacada e exige resposta quando laboratório acreditado = Não. Não força outra resposta ou situação.
- Situação do equipamento usa as sete opções SCC documentadas na matriz dos prints; valores antigos permanecem nos históricos.
- Na renovação, identificação, dados do equipamento, tolerância, documento de referência e unidade ficam preservados na interface e no servidor. Atualizam-se os dados destacados do certificado, respostas humanas, anexo e vencimento; LI e histórico são conservados.
- LI automática pela referência oficial; próximo CE-5290.00-22313-856-C1O-843, linha 850. O rascunho inicial reserva o número; correções e renovações preservam a LI. Falha transacional não consome a sequência.
- Novos cadastros/renovações usam |Erro| + |Incerteza| **≤** Tolerância, conforme a anotação de 06/10. Históricos conservam seus dados e critérios, sem reavaliação automática.
- Sugestão de aceitação aplicada por botão explícito. Laboratório acreditado, Calibração aceita, Aceito com restrição, Status do cadastro e Situação do equipamento são independentes.
- Rascunho → aguardando aprovação → aprovado ou devolvido com motivo. Cadastro prepara e envia; Responsável revisa; Consulta lê; Proprietário administra acessos.
- Atualizar certificado cria outra versão na mesma ficha. Certificado vigente e datas só mudam após aprovação; arquivos e versões anteriores são conservados.
- Monitoramento consulta toda a base autorizada, pesquisa, pagina, filtra vencimentos e exporta todas as páginas do filtro.
- APIs anteriores de escrita estão revogadas para clientes; não reativá-las sem preservar o controle de aprovação.

## Repositório, publicação e banco
Repositório: dw-glitch/Metrikon. Deploy isolado pelo arquivo .github/workflows/deploy-metrikon-cloudflare.yml, branch infra/metrikon-cloudflare-deploy de dw-glitch/GRCON. Worker: metrikon. Código fixado pelo SHA validado; não publicar automaticamente toda a main. Main/Worker GRCON não foram alterados.

Supabase independente CCP CONSAG, ref aimvjsbrxnyqjurgicec, onze migrações remotas. Proprietário vinicio.silva@agnet.com.br existente, confirmado e ativo. Não recriar conta, pedir senha no chat, criar outro projeto ou usar ConsagVINI.

Migração do fluxo mínimo: **20261006092211_minimalist_registration_monitoring**, arquivo **20261006090041_minimalist_registration_monitoring.sql**. Migração das instruções SCC: **20261006100441_scc_instructions_conditional_fields**, arquivo **20261006095336_scc_instructions_conditional_fields.sql**. Diferenças históricas local/remoto da LI, importação e rastreabilidade continuam documentadas nas publicações anteriores. Não reaplicar migrações por diferenças nos timestamps.

Após smoke com rollback: oito empresas, 842 entradas da LI (733 originais e 109 planejadas), zero instrumentos, zero propostas e próximo número 843/linha 850. Nenhum certificado ou metadado fictício do teste permaneceu. Históricos e tabelas anteriores não foram apagados.

## Validação
71 testes de domínio/PostgreSQL, TypeScript/Vite, Wrangler dry-run e 13 cenários Chromium sobre o pacote compilado de produção aprovados localmente e no CI. Cadastro/devolução/aprovação/renovação, Excel filtrado, perfis, desktop e celular verificados, sem overflow ou erros JavaScript. A suíte mínima aplica todas as migrações; as antigas verificam os contratos históricos, com o bloqueio das APIs antigas coberto pela suíte nova.

Smoke SQL remoto com papel authenticated e identidade do proprietário validou a regra ≤, LI, anexo, envio, devolução, aprovação, renovação e conservação de ambas as versões. Metadados de Storage foram fixtures SQL dentro da transação, não upload físico pelo Storage API. Campos condicionais e sete situações SCC também verificados; tentativas de alterar série e tolerância na renovação, inclusive com renewal=false forjado, foram rejeitadas. Rollback e sequência preservada confirmados. Advisors de segurança sem novos avisos em relação ao baseline.

Pós-deploy: SHA público conferido, HTTP, rota SPA, logo, manifesto, login desktop/mobile e demonstração com exatamente duas abas e formulário SCC com condicionais/menu aprovados. Evidências preservadas nas execuções GitHub.

## Pendências reais e contexto histórico
Login real do proprietário/equipe, criação/confirmação de novos acessos, concessão de perfis pela interface, upload/leitura assinada pelo Storage API e isolamento operacional entre empresas continuam pendentes. Não declarar QA autenticado concluído com base na demonstração ou no smoke SQL.

14 PDFs individuais foram examinados em entregas anteriores. Os dois ZIPs grandes retornaram 502 e não foram analisados integralmente. Originais e dados pessoais não foram publicados ou cadastrados automaticamente; ver REQUISITOS-CERTIFICADOS.md.

O roteiro de fases 4–18, importação operacional, laboratórios/padrões como módulos, checklist avançado, RNC, notificações, OCR/IA, etiquetas/QR e vídeos deixou de ser o próximo objetivo. Qualquer retomada depende de novo comando. Próximo passo operacional: validar o fluxo mínimo com acessos e certificados reais, sem acrescentar abas.
