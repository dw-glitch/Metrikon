# Compatibilidade com o cadastro atualmente utilizado — 05/10/2026

Esta matriz registra a referência inicial determinada pelo proprietário do Metrikon. O objetivo desta entrega é reproduzir o preenchimento utilizado atualmente pela equipe antes de qualquer evolução de processo. Alterações futuras de significado, obrigatoriedade ou decisão dependem de orientação do proprietário.

| Campo/recurso do aplicativo atual | Correspondência no Metrikon | Situação encontrada | Ajuste implementado |
|---|---|---|---|
| Obra | `Instrument.workSite` | Ausente | Campo criado no cadastro, detalhe, busca/exportação e validação de conclusão |
| Equipamento crítico | `Instrument.criticality` | Existia como “Criticidade” genérica | Rótulo e significado alinhados ao preenchimento atual |
| Código de série / identificação | `Instrument.serial` | Existia como “Número de série do fabricante” | Rótulo ajustado; valor permanece independente de TAG/patrimônio |
| Modelo | `Instrument.model` | Existente | Preservado e exigido ao concluir um controle |
| Local de uso | `Instrument.location` | Existente como “Local” | Rótulo alinhado e preservado |
| Área/Setor responsável pela calibração | `Instrument.calibrationResponsibleArea` | Ausente | Campo próprio criado; não substitui Área nem Setor |
| Processo | `Instrument.process` | Existente | Preservado |
| Faixa de medição | `Instrument.measurementRange` | Existia somente de forma indireta em faixas/grandezas | Campo direto criado; faixas detalhadas continuam disponíveis |
| Faixa de utilização | `Instrument.usageRange` | Ausente | Campo criado |
| Entidade calibradora | `MetrologicalEvent.laboratory` | Existia como “Laboratório / executor” | Rótulo alinhado ao uso atual |
| Data da calibração | `MetrologicalEvent.date` | Existente | Preservado |
| Intervalo de calibrações (meses) | `Instrument.periodicityMonths` | Existia como periodicidade | Rótulo alinhado; histórico de mudança permanece |
| Valor da divisão de verificação | `Instrument.verificationDivision` | Ausente | Campo criado |
| Número do certificado | `MetrologicalEvent.certificateNumber` | Existente | Preservado |
| Documento de referência da tolerância | `MetrologicalEvent.toleranceReferenceDocument` | Ausente | Campo criado e validado na conclusão |
| Tolerância do processo | `MetrologicalEvent.processTolerance` | Existia apenas por ponto detalhado | Campo direto criado; tolerância deve ser > 0 |
| Incerteza de medição | `MetrologicalEvent.measurementUncertainty` | Existia apenas por ponto detalhado | Campo direto criado |
| Erro de medição | `MetrologicalEvent.measurementError` | Existia apenas por ponto detalhado | Campo direto criado |
| % ou unidade | `MetrologicalEvent.resultBasis` | Ausente | Campo criado; não há conversão automática |
| Laboratório acreditado? | `MetrologicalEvent.laboratoryAccredited` | Ausente | Campo sim/não criado; não reprova automaticamente |
| Calibração aceita? | `MetrologicalEvent.calibrationAccepted` | Ausente | Campo sim/não criado e mantido independente da fórmula e da situação |
| Status do cadastro | `Instrument.registrationStatus` + snapshot do evento | Já existia no cadastro, não no fechamento do ciclo | Incluído na decisão do ciclo e mantido independente da situação do equipamento |
| Situação do equipamento | `Instrument.operationalStatus` / `MetrologicalEvent.decision` | Existia como “Situação operacional” | Rótulo alinhado; decisão continua humana |
| Aceito com restrição? | `MetrologicalEvent.acceptedWithRestriction` | Não havia resposta própria | Campo sim/não criado; restrição estruturada existente continua separada |
| Equipamento de empresa contratada? | `Instrument.contractorEquipment` | Ausente | Campo sim/não criado |
| Rastreabilidade/validade dos padrões | Checklist qualitativo | Existente | Preservado explicitamente |
| Fórmula `|Erro| + |Incerteza| < Tolerância` | `evaluateCurrentProcedure` + PostgreSQL | Existia por ponto detalhado | Aplicada também aos campos diretos; igualdade não conforme; tolerância zero inválida |
| Anexo do certificado | Storage privado `metrology-certificates` | Somente PDF, até 20 MB | Passa a aceitar PDF/XLSX/XLS, até 16 MB, com assinatura/extensão verificadas no cliente |
| Importação da LI | Mapeamento assistido + referência oficial | Campos novos não estavam no mapeamento; migração da sequência oficial estava aplicada no banco e ausente no Git | Campos cadastrais adicionados ao mapeamento e migração `rhdd_li_reference` sincronizada no repositório |
| Detalhes/histórico | Ficha e histórico por ciclo | Não mostravam as novas respostas | Passam a mostrar acreditação, aceitação, restrição, status e situação, além dos dados da fórmula |
| Exportação Excel | Exportação de instrumentos | Não continha os campos novos | Colunas do preenchimento atual adicionadas |

## Separações obrigatórias

O Metrikon não deriva automaticamente um dos seguintes registros a partir de outro:

- laboratório acreditado;
- calibração aceita;
- aceito com restrição;
- status do cadastro;
- situação do equipamento.

Um laboratório marcado como **não acreditado** não causa reprovação automática. A resposta de **Calibração aceita?** também não altera automaticamente o status cadastral nem a situação do equipamento.

## Arquivos e análise

O anexo do ciclo aceita **PDF, XLSX ou XLS**, com limite de **16 MB**. A regra quantitativa continua estrita: `|Erro| + |Incerteza| < Tolerância`. Igualdade é não conforme e tolerância zero é inválida. Os pontos detalhados continuam disponíveis como complemento do preenchimento principal e não existe conversão automática de unidades.
