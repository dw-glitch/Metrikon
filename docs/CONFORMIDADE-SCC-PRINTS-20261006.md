# Instruções do responsável — prints de 06/10/2026

Fonte: três prints fornecidos por Vinício (1000812755.png, 1000812754.png e 1000812753.png). As instruções e imagens foram lidas na conversa; os caminhos locais informados para os anexos estavam indisponíveis. Não houve acesso ao SCC. Esta matriz cobre as instruções observáveis, sem afirmar equivalência com funções não mostradas.

## Matriz de conformidade
| Instrução / referência | Diferença encontrada | Correção |
|---|---|---|
| Incluir caixa de texto para Restrição | Só havia Sim/Não para aceitação com restrição | Campo Restrição aparece quando Aceito com restrição = Sim; texto necessário ao enviar, persistido por versão |
| Incluir caixa de texto para Empresa Contratada | Só havia Sim/Não para equipamento de contratada | Campo Empresa contratada aparece quando Equipamento de empresa contratada = Sim; nome necessário ao enviar, persistido na ficha e proposta |
| Se não foi laboratório acreditado, incluir a pergunta destacada | Pergunta abreviada e sempre visível | Texto completo: “Os certificados dos padrões utilizados na calibração foram validados quanto à rastreabilidade e validade?”; visível, destacado e com resposta explícita exigida somente quando laboratório acreditado = Não |
| Situações do equipamento mostradas no SCC | Menu com quatro situações genéricas | Menu com as sete situações da imagem, mantendo os valores antigos apenas no histórico |
| Campos destacados para atualizar a calibração | Identificação e parâmetros também eram editáveis | Renovação preserva dados do equipamento, documento de referência da tolerância, tolerância e unidade; altera os dados destacados do novo certificado e recalcula a soma |
| Tela de cadastro | Fluxo mínimo já continha os campos-base | Conservados os campos da referência, LI automática, aprovação e somente Cadastro/Monitoramento |

## Situação do equipamento
As opções novas são exatamente as mostradas no menu: AGUARDANDO ENVIO PARA CALIBRAÇÃO, DESMOBILIZADO, DISPONÍVEL PARA TRANSFERÊNCIA, DISPONÍVEL PARA USO, EM USO, ENVIADO PARA CALIBRAÇÃO e ENVIADO PARA MANUTENÇÃO. A decisão é manual e independente da aceitação, do cálculo, da acreditação e do vencimento.

## Atualização da calibração
Os destaques identificam Entidade calibradora, Data da calibração, Número do certificado, Incerteza de medição, Erro de medição, soma de erro/incerteza, laboratório acreditado e validação dos certificados dos padrões. A soma é calculada; os demais dados destacados são editáveis na renovação. As respostas de análise (aceitação, restrição e situação) continuam explícitas para decisão humana. Anexo e vencimento são atualizados para o monitoramento autorizado anteriormente.

Identificação, modelo, obra, local, área responsável, processo, faixas, divisão, periodicidade, status cadastral, vínculo com contratada e parâmetros fixos permanecem somente leitura na renovação. A LI permanece imutável. Se uma ficha antiga de contratada ainda não tem o nome da empresa, o novo campo permite preenchê-lo uma vez; após isso ele também é preservado na renovação.

O servidor verifica os mesmos limites de edição, usando a ficha e o certificado aprovado como referência. Marcar renewal = false no payload não permite alterar campos fixos. Alterações inválidas são rejeitadas inclusive em rascunhos. O envio aguarda aprovação; aprovação atualiza o vigente; versões e arquivos anteriores permanecem conservados.

Ao responder Não à restrição/contratada ou Sim à acreditação, os dados condicionais não aplicáveis são removidos da nova proposta; nenhuma versão histórica é reescrita. A resposta Não à validação dos padrões não força aceitação ou situação: o responsável mantém a decisão explícita, conforme o procedimento já autorizado.

Restrição, empresa contratada e validação dos padrões são exibidas na ficha/histórico e exportadas na lista Excel do certificado vigente. Exportação mantém os filtros e abrange todas as páginas autorizadas.

## Validação
Suíte de domínio/banco e navegador cobre campos condicionais, obrigatoriedades, limpeza de valores não aplicáveis, sete situações, independência das respostas, bloqueio de alteração dos dados fixos pelo servidor, aprovação, histórico e Excel. O teste de renovação tenta alterar série, modelo, obra, periodicidade, contratada, referência, tolerância e unidade diretamente pela RPC e verifica a rejeição. As sete situações são enviadas e aprovadas no banco dentro de transação descartada.

Login/upload reais da equipe permanecem uma validação operacional pendente. Testes de demonstração e SQL não equivalem a acesso ao SCC nem a QA com usuários reais.

Entrega publicada: PR #5, código 707b08196ef738b818f56e6c882d7ae8373ea943, 71 testes e 13 cenários de navegador de produção aprovados. Migração remota aplicada e smoke transacional com rollback confirmado. Ver PUBLICACAO-SCC-20261006.md e CHECKPOINT.md.
