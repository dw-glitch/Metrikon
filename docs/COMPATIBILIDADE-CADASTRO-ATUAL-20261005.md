# Compatibilidade com o cadastro atualmente utilizado — 05/10/2026

Esta é a referência inicial obrigatória determinada pelo proprietário do Metrikon. O cadastro do instrumento deve reproduzir a forma de preenchimento atualmente utilizada pela equipe. Campos, significados, obrigatoriedades e critérios só podem ser alterados futuramente por determinação do proprietário.

## Cadastro do instrumento

A interface de cadastro exibe somente os campos presentes na referência operacional, além do número da LI, que é gerado automaticamente pelo sistema:

| Campo da referência atual | Campo Metrikon | Regra |
|---|---|---|
| Obra | `Instrument.workSite` | Visível e obrigatório |
| Equipamento crítico | `Instrument.criticality` | Visível e obrigatório |
| Código de série / identificação | `Instrument.serial` | Visível e obrigatório |
| Modelo | `Instrument.model` | Visível e obrigatório |
| Local de uso | `Instrument.location` | Visível e obrigatório |
| Área/Setor responsável pela calibração do equipamento | `Instrument.calibrationResponsibleArea` | Visível e obrigatório |
| Processo | `Instrument.process` | Visível e obrigatório |
| Faixa de medição | `Instrument.measurementRange` | Visível e obrigatório |
| Faixa de utilização | `Instrument.usageRange` | Visível e obrigatório |
| Intervalo de calibrações (em meses) | `Instrument.periodicityMonths` | Visível e obrigatório |
| Valor da divisão de verificação do equipamento | `Instrument.verificationDivision` | Visível e obrigatório |
| Status do cadastro | `Instrument.registrationStatus` | Visível |
| Equipamento de empresa contratada? | `Instrument.contractorEquipment` | Visível como Sim/Não |
| Número LI / N-1710 | `Instrument.liNumber` | Exibido, mas nunca digitado pelo usuário |

### Campos retirados da interface de cadastro

Não fazem parte do preenchimento atual e não devem aparecer no cadastro: **Código interno RHDD, Descrição, Tipo/família, Fabricante, TAG, Identificação interna, Patrimônio, Empresa proprietária, Empresa usuária, Área, Setor, Responsável, Tipo de controle, Grandezas/faixas detalhadas e Observações**.

Alguns campos legados permanecem apenas na estrutura interna por compatibilidade com o banco. Para novos cadastros eles são neutralizados no backend e não constituem dados a serem preenchidos. O UUID é exclusivamente uma chave técnica invisível.

## Número da LI automático

O usuário não informa nem escolhe manualmente o número da LI. A fonte é a referência oficial armazenada em `li_references` e `li_entries`.

Na referência carregada em 05/10/2026, a sequência existente estava planejada até **842**, portanto a próxima posição era:

- número: **CE-5290.00-22313-856-C1O-843**
- linha: **850**

Esses valores não são hardcoded. `next_number` e `next_row` são lidos e bloqueados transacionalmente pelo banco no instante da criação. Se outro usuário cadastrar antes, o próximo cadastro recebe a sequência atualizada. Edições posteriores não podem alterar o número já vinculado.

Um cadastro que já exista na LI pode ser associado ao número oficial correspondente. Um número digitado/inventado que não exista na referência oficial é rejeitado pelo backend.

## Dados da calibração

O ciclo metrológico mantém os campos da mesma referência operacional: Entidade calibradora, Data da calibração, Número do certificado, Documento de referência da tolerância, Tolerância do processo, Incerteza de medição, Erro de medição, `|Erro| + |Incerteza|`, % ou unidade, laboratório acreditado, validação da rastreabilidade/validade dos padrões, Calibração aceita, Status do cadastro, Aceito com restrição e Situação do equipamento.

Laboratório acreditado, Calibração aceita, Aceito com restrição, Status do cadastro e Situação do equipamento permanecem registros independentes. Nenhum deles deve ser automaticamente inferido de outro.

Atualização autorizada por Vinício em 06/10/2026: no novo fluxo mínimo, a anotação do responsável determina **`|Erro| + |Incerteza| ≤ Tolerância`**; igualdade é conforme. Tolerância zero continua inválida. Eventos anteriores mantêm seu critério originalmente registrado, sem reavaliação automática. A sugestão de aceitação é aplicada por ação explícita e o responsável aprova ou devolve o cadastro. Ver docs/PLANO-MINIMO-20261006.md.

## Anexos

O ciclo aceita **PDF, XLSX e XLS**, com limite de **16 MB**, em armazenamento privado. A extensão e a assinatura do arquivo são verificadas antes do envio.

## Regra de continuidade

Detalhamento autorizado em 06/10/2026 pelos três prints adicionais: campo Empresa contratada quando o equipamento é de contratada; texto Restrição quando aceito com restrição; pergunta completa e destacada de rastreabilidade/validade dos certificados dos padrões quando a calibração não foi realizada em laboratório acreditado; sete situações exatas do SCC; renovação limitada aos dados da nova calibração, preservando identificação e parâmetros fixos. Ver CONFORMIDADE-SCC-PRINTS-20261006.md.

Qualquer evolução futura deve preservar este cadastro como baseline. Não reintroduzir campos genéricos de gestão metrológica no fluxo principal sem solicitação expressa do proprietário.
