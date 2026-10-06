# Checkpoint de continuidade — 06/10/2026

## Estado atual
Metrikon mínimo publicado em https://metrikon.grcon-qualidade.workers.dev/. Código servido: `7b87db48900336ab13b7fb431ca32921a0896207`; Cloudflare version ID: `eba635a6-b2cd-42b4-b0f5-081e3dd77761`. PR #4 integrada: https://github.com/dw-glitch/Metrikon/pull/4. CI: https://github.com/dw-glitch/Metrikon/actions/runs/37442405281. Publicação: https://github.com/dw-glitch/GRCON/actions/runs/37443103042. Ver PUBLICACAO-MINIMO-20261006.md.

O comando de Vinício e a anotação do responsável substituem o roteiro anterior de 19 fases. A interface tem somente **Cadastro** e **Monitoramento**, com gestão de acessos no cabeçalho do proprietário. Plano vigente: PLANO-MINIMO-20261006.md. Não iniciar automaticamente outra fase nem reintroduzir módulos avançados.

## Regras vigentes
- Cadastro somente com os campos SCC documentados em COMPATIBILIDADE-CADASTRO-ATUAL-20261005.md, reunindo equipamento e calibração em uma tela.
- Não reintroduzir Código interno RHDD, fabricante, TAG ou campos genéricos sem novo comando.
- LI automática pela referência oficial; próximo CE-5290.00-22313-856-C1O-843, linha 850. O rascunho inicial reserva o número; correções e renovações preservam a LI. Falha transacional não consome a sequência.
- Novos cadastros/renovações usam |Erro| + |Incerteza| **≤** Tolerância, conforme a anotação de 06/10. Históricos conservam seus dados e critérios, sem reavaliação automática.
- Sugestão de aceitação aplicada por botão explícito. Laboratório acreditado, Calibração aceita, Aceito com restrição, Status do cadastro e Situação do equipamento são independentes.
- Rascunho → aguardando aprovação → aprovado ou devolvido com motivo. Cadastro prepara e envia; Responsável revisa; Consulta lê; Proprietário administra acessos.
- Atualizar certificado cria outra versão na mesma ficha. Certificado vigente e datas só mudam após aprovação; arquivos e versões anteriores são conservados.
- Monitoramento consulta toda a base autorizada, pesquisa, pagina, filtra vencimentos e exporta todas as páginas do filtro.
- APIs anteriores de escrita estão revogadas para clientes; não reativá-las sem preservar o controle de aprovação.

## Repositório, publicação e banco
Repositório: dw-glitch/Metrikon. Deploy isolado pelo arquivo .github/workflows/deploy-metrikon-cloudflare.yml, branch infra/metrikon-cloudflare-deploy de dw-glitch/GRCON. Worker: metrikon. Código fixado pelo SHA validado; não publicar automaticamente toda a main. Main/Worker GRCON não foram alterados.

Supabase independente CCP CONSAG, ref aimvjsbrxnyqjurgicec, dez migrações remotas. Proprietário vinicio.silva@agnet.com.br existente, confirmado e ativo. Não recriar conta, pedir senha no chat, criar outro projeto ou usar ConsagVINI.

Nova migração remota: **20261006092211_minimalist_registration_monitoring**; arquivo local: **20261006090041_minimalist_registration_monitoring.sql**. Diferenças históricas local/remoto da LI, importação e rastreabilidade continuam documentadas nas publicações anteriores. Não reaplicar migrações por diferenças nos timestamps.

Após smoke com rollback: oito empresas, 842 entradas da LI (733 originais e 109 planejadas), zero instrumentos, zero propostas e próximo número 843/linha 850. Nenhum certificado ou metadado fictício do teste permaneceu. Históricos e tabelas anteriores não foram apagados.

## Validação
69 testes de domínio/PostgreSQL, TypeScript/Vite, Wrangler dry-run e 11 cenários Chromium aprovados localmente e no CI. Cadastro/devolução/aprovação/renovação, Excel filtrado, perfis, desktop e celular verificados, sem overflow ou erros JavaScript. A suíte mínima aplica todas as migrações; as antigas verificam os contratos históricos, com o bloqueio das APIs antigas coberto pela suíte nova.

Smoke SQL remoto com papel authenticated e identidade do proprietário validou a regra ≤, LI, anexo, envio, devolução, aprovação, renovação e conservação de ambas as versões. Metadados de Storage foram fixtures SQL dentro da transação, não upload físico pelo Storage API. Rollback e sequência preservada confirmados. Advisors de segurança sem novos avisos em relação ao baseline.

Pós-deploy: SHA público conferido, HTTP, rota SPA, logo, manifesto, login desktop/mobile e demonstração com exatamente duas abas aprovados. Evidências preservadas nas execuções GitHub.

## Pendências reais e contexto histórico
Login real do proprietário/equipe, criação/confirmação de novos acessos, concessão de perfis pela interface, upload/leitura assinada pelo Storage API e isolamento operacional entre empresas continuam pendentes. Não declarar QA autenticado concluído com base na demonstração ou no smoke SQL.

14 PDFs individuais foram examinados em entregas anteriores. Os dois ZIPs grandes retornaram 502 e não foram analisados integralmente. Originais e dados pessoais não foram publicados ou cadastrados automaticamente; ver REQUISITOS-CERTIFICADOS.md.

O roteiro de fases 4–18, importação operacional, laboratórios/padrões como módulos, checklist avançado, RNC, notificações, OCR/IA, etiquetas/QR e vídeos deixou de ser o próximo objetivo. Qualquer retomada depende de novo comando. Próximo passo operacional: validar o fluxo mínimo com acessos e certificados reais, sem acrescentar abas.
