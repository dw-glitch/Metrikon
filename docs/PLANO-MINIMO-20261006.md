# Metrikon — plano mínimo aprovado por Vinício em 06/10/2026

Este plano substitui a sequência anterior de 19 fases. Fonte: confirmação de que os prints anteriores são do SCC, novo comando de Vinício e duas fotografias da mesma anotação do responsável. O proprietário tem apenas prints e não possui acesso ao SCC; não afirmar equivalência integral com funções não observadas.

## Leitura da anotação
1. Tela de cadastro baseada no SCC, com os mesmos campos.
2. Comparar |Erro| + |Incerteza| com a tolerância; a anotação usa **≤**. Conforme sugere “Calibração aceita? Sim”; não conforme sugere “Não”.
3. Salvar e enviar para aprovação do responsável.
4. Responsável aprova ou devolve/reprova o cadastro.
5. Monitoramento lista instrumentos com vencimento próximo e permite pesquisar, gerar a lista e visualizar a informação.
6. Atualizar a calibração pela ficha existente, sem perder o histórico, usando “Atualizar certificado”.

## Espaço de trabalho
Apenas **Cadastro** e **Monitoramento**. Não há dashboard, laboratórios/padrões, empresas, importação da LI, eventos avançados, checklist, configurações/fases ou auditoria como abas de trabalho. Gestão de acessos fica em uma ação do proprietário no cabeçalho. Dados históricos permanecem no banco; tabelas/migrações anteriores não são apagadas.

Cadastro reúne Dados do Equipamento e Dados da Calibração em uma única tela, sem wizard. Mantém os campos SCC documentados em COMPATIBILIDADE-CADASTRO-ATUAL-20261005.md, incluindo status, respostas independentes, rastreabilidade/validade de padrões e situação do equipamento. Número LI continua automático e imutável. O vencimento confirmado e o arquivo do certificado são necessários para monitorar e atualizar a calibração. O sistema pode sugerir vencimento pelo intervalo cadastrado, por ação explícita do usuário; não substitui automaticamente a data confirmada.

O resultado numérico agora usa ≤ para **novos cadastros/atualizações**, conforme a nova anotação. A sugestão de aceitação é aplicada por botão explícito; as respostas e a aprovação continuam visíveis para decisão humana. Nenhum checklist de 19 itens ou matriz de restrições anterior foi incorporado ao fluxo mínimo. Históricos anteriores conservam dados e critérios registrados.

## Perfis
| Perfil | Autoridade |
|---|---|
| Proprietário | Gerencia acessos, cadastra, consulta, aprova e devolve |
| Responsável | Cadastra, consulta, aprova e devolve |
| Cadastro | Preenche rascunho, corrige devolução e envia; não aprova |
| Consulta | Pesquisa, abre ficha/histórico e exporta; não altera |

Papéis técnicos existentes owner, quality_admin, analyst e viewer são reutilizados; inspector/contractor permanecem somente consulta nesta interface. O acesso pode ser limitado à empresa. O usuário cria/confirma seu acesso no Auth; só o proprietário pode vincular o e-mail confirmado a um perfil. Não concede owner pelo aplicativo, não altera outro owner e não permite autoelevação. Não solicita senha de terceiros.

## Aprovação e renovação
Rascunho → aguardando aprovação → aprovado ou devolvido. A devolução exige motivo. Versão enviada fica congelada; devolvida pode ser corrigida e reenviada. Perfil e escopo são verificados no banco, inclusive chamadas pelo console. APIs anteriores de escrita são revogadas para evitar contornar a aprovação.

Na criação, o rascunho reserva a LI oficial e cria a ficha fora de uso, sem certificado vigente. O número é mantido ao corrigir o cadastro. O envio não muda certificado vigente, datas ou situação de um instrumento já aprovado. A aprovação registra responsável/data, aplica os dados revisados e atualiza o certificado vigente. Renovar cria outra versão na mesma ficha; nunca substitui o arquivo anterior. Uma versão em andamento por instrumento evita envios concorrentes ambíguos. Arquivos privados PDF/XLSX/XLS até 16 MB; URLs de leitura duram 60 segundos.

Monitoramento consulta toda a base autorizada, com paginação de 50, pesquisa, filtros Todos/Vencidos/Próximos/Sem data e janela explícita de 1–365 dias (inicial 30). Cadastro também filtra aguardando aprovação. A lista Excel exporta todas as páginas correspondentes ao filtro, incluindo identificação, campos cadastrais e datas. Expirar não altera automaticamente a decisão humana; o aviso fica visível.

## Escopo encerrado e validação real pendente
O plano anterior de módulos avançados está substituído, sem desenvolvimento automático de fases 4–18. OCR/IA, RNC, QR/etiquetas, notificações, mascote e módulos metrológicos avançados ficam fora deste escopo.

QA autenticado pela interface permanece pendente: proprietário, criação/confirmação de novo usuário, concessão de perfis, upload/abertura assinada no Storage API e operação com certificados reais. Testes SQL transacionais e demonstração não equivalem a essa validação.
