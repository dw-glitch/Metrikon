# Publicação — instruções SCC dos prints de 06/10/2026

URL: https://metrikon.grcon-qualidade.workers.dev/
Código servido: `707b08196ef738b818f56e6c882d7ae8373ea943`.
Cloudflare version ID: `ac74f78f-cc72-408b-a0f1-1c67b467e077`.
PR: https://github.com/dw-glitch/Metrikon/pull/5.
CI aprovado: https://github.com/dw-glitch/Metrikon/actions/runs/37447344208.
Publicação: https://github.com/dw-glitch/GRCON/actions/runs/37447700978.

## Conformidade implementada
- Restrição: caixa de texto quando Aceito com restrição = Sim.
- Empresa contratada: caixa de texto quando o equipamento é de contratada.
- Padrões: pergunta completa sobre rastreabilidade e validade, destacada e exigida quando laboratório acreditado = Não.
- Situação do equipamento: sete opções da imagem SCC; registros anteriores não são convertidos.
- Renovação: dados destacados do certificado editáveis, soma recalculada, identificação e parâmetros fixos preservados; decisão humana, anexo e vencimento explícitos.
- Novos textos/respostas preservados na ficha e versões e incluídos no Excel do certificado vigente.
- Cadastro e Monitoramento permanecem as duas abas; certificado vigente só muda após aprovação.

Matriz completa: CONFORMIDADE-SCC-PRINTS-20261006.md. Não houve acesso ao SCC; a conformidade se refere às instruções observáveis nos três prints.

## Banco e validação
Projeto independente CCP CONSAG: aimvjsbrxnyqjurgicec. Migração remota `20261006100441_scc_instructions_conditional_fields`, arquivo local `20261006095336_scc_instructions_conditional_fields.sql`. A migração conserva grants, RLS, revisão obrigatória e os históricos. Não reaplicar por diferença de timestamp.

71 testes de domínio/PostgreSQL, TypeScript/Vite, Wrangler dry-run e 13 cenários Chromium passaram localmente e no CI. A suíte UI compila e testa o pacote de produção. Condicionais, textos exigidos, limpeza de valores não aplicáveis, sete situações, campos preservados na renovação, histórico, Excel e desktop/celular verificados, sem erros JavaScript.

Smoke SQL remoto sob authenticated e identidade do proprietário passou: ausência de nome/restrição/validação dos padrões é rejeitada quando aplicável; cadastro/devolução/aprovação/renovação preservam LI e histórico; alterações de série e tolerância são rejeitadas mesmo forjando renewal=false; sete situações passam por envio/aprovação, mantendo aceitação e padrões como respostas independentes. Dados e metadados de Storage eram fixtures SQL, sem upload físico; rollback confirmado.

Base após rollback: oito empresas, 842 entradas LI, zero instrumentos e propostas; próximo número 843, linha 850. Onze migrações remotas. Advisors sem novos avisos: permanecem quatro INFO das ACL privadas e um WARN preexistente da proteção de senhas vazadas desativada.

Pós-publicação validou SHA, HTTP, rota SPA, logo/manifesto, login desktop/mobile, duas abas e o formulário público de demonstração com os campos condicionais e o menu SCC. Evidências preservadas no artefato da execução GitHub.

## Pendências operacionais
Login da equipe e upload/leitura assinada pelo Storage API com certificados reais continuam pendentes. Demonstração e SQL transacional não equivalem a QA autenticado pela interface. Nenhuma senha foi solicitada e nenhuma conta foi recriada.
