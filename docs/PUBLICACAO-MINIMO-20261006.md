# Publicação do escopo mínimo — 06/10/2026

## Versão publicada
URL: https://metrikon.grcon-qualidade.workers.dev/
Código: `7b87db48900336ab13b7fb431ca32921a0896207`.
Cloudflare version ID: `eba635a6-b2cd-42b4-b0f5-081e3dd77761`.
PR: https://github.com/dw-glitch/Metrikon/pull/4.
CI: https://github.com/dw-glitch/Metrikon/actions/runs/37442405281.
Publicação aprovada: https://github.com/dw-glitch/GRCON/actions/runs/37443103042.

O comando de Vinício e a anotação do responsável substituem o plano anterior de 19 fases. A interface oferece Cadastro e Monitoramento. Cadastro reúne equipamento e calibração com os campos SCC documentados, LI automática, sugestão quantitativa ≤ e respostas independentes. Responsável aprova ou devolve com motivo. Atualizar certificado conserva a ficha, a LI e o histórico; o certificado vigente só muda após aprovação.

Monitoramento consulta toda a base autorizada, pagina, pesquisa, filtra vencimentos por janela de dias e exporta a lista filtrada. A ação Acessos do proprietário fica fora das duas abas; os perfis são Proprietário, Responsável, Cadastro e Consulta, com escopo empresarial verificado no servidor.

## Banco independente
Projeto Supabase CCP CONSAG: `aimvjsbrxnyqjurgicec`. Migração remota `20261006092211_minimalist_registration_monitoring`, correspondente ao arquivo local `20261006090041_minimalist_registration_monitoring.sql`. Não reaplicar por diferença de timestamp.

A migração acrescenta propostas versionadas e RPCs guardadas, conserva dados anteriores e revoga aos clientes APIs antigas de escrita que poderiam contornar a aprovação. Novas avaliações usam ≤; avaliações históricas mantêm seu critério anterior.

Smoke transacional remoto sob authenticated e identidade do proprietário aprovado: LI 843, soma 0,4 + 0,1 ≤ 0,5, anexo, envio, devolução, reenvio, aprovação, renovação e preservação das versões. Os objetos Storage desse smoke foram metadados temporários inseridos por SQL, sem upload físico; rollback descartou as fixtures. Base final: oito empresas, 842 entradas LI, zero instrumentos, zero propostas, próxima LI 843 e linha 850.

Advisors de segurança comparados antes/depois: sem novas ocorrências. Baseline preservado: quatro INFO RLS Enabled No Policy em tabelas ACL privadas, com acesso por funções guardadas, e um WARN preexistente Leaked Password Protection Disabled. Este último não foi introduzido pela migração; configurações de Auth não foram alteradas.

## Verificações
- 69 testes de domínio/PostgreSQL aprovados localmente e no CI.
- A suíte mínima aplica todas as migrações, verifica APIs antigas revogadas, RBAC/RLS, anexos, aprovação, renovação, histórico e paginação de toda a base.
- Suítes de contratos antigos executam o snapshot histórico de migrações, pois essas APIs deixam de estar disponíveis no fluxo vigente.
- TypeScript/Vite, Wrangler dry-run e 11 cenários Chromium aprovados.
- Fluxo completo, respostas independentes, LI, Excel filtrado, quatro larguras, celular e saída/reset da demonstração verificados.
- Pacote compilado com configuração pública independente também verificado em preview local, incluindo / e /instrumentos.
- Pós-publicação verifica SHA servido, HTTP, rota SPA, logo, manifesto, login desktop/mobile, duas abas na demonstração e saída. Artefatos preservados nas execuções GitHub.

## Limites da evidência
Demonstração e SQL transacional não são QA operacional autenticado. Login real do proprietário/equipe, criação/confirmação de acessos, atribuição de perfil pela interface, upload e abertura pelo Storage API e operação com certificados reais continuam pendentes.

Não houve retomada automática do plano anterior. OCR/IA, RNC, notificações, etiquetas/QR e módulos avançados permanecem fora deste escopo.

A primeira execução (37442634490) publicou o pacote, mas a checagem pública aguardou a tela além do timeout. O pacote de produção com a mesma configuração pública passou no preview local. A rotina recebeu diagnóstico adicional e a repetição (37443103042), com o mesmo SHA de código, passou integralmente; não foi identificada uma causa definitiva para o timeout inicial.
