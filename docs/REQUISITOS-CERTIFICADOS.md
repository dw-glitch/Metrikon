# Requisitos observados nos certificados — 05/10/2026

14 PDFs individuais disponibilizados como referência documental: 7 HI-LO, 5 calibres de solda, 1 calibrador elétrico e 1 conjunto digitalizado de alta tensão. Os PDFs HI-LO/solda incluem páginas de padrões anexos, além do certificado principal. O ZIP de aproximadamente 306 MB e a segunda parte de aproximadamente 321 MB retornaram HTTP 502 e não foram analisados. Os documentos originais, imagens, valores medidos, dados de pessoas e OCR não são incluídos neste repositório nem cadastrados como dados operacionais.

## Modelos e estrutura observados

- HI-LO: escalas superior/inferior/base em mm e ângulo em graus/minutos, com incerteza própria para escala e ângulo. Identificações do instrumento e do certificado são diferentes.
- Calibre de solda: escalas superior/central/angular milimetrada e ângulo; grupos independentes, incluindo repetição de valores de referência. Tendência pode adotar convenção de sinal diferente de outros modelos.
- Calibrador elétrico: modo medidor e modo fonte, faixas V/mA, resolução, valor indicado/padrão, incerteza, k e graus de liberdade por ponto. O PDF contém páginas de assinatura e avaliação além das tabelas.
- Conjunto digitalizado de alta tensão: certificado principal de equipamento e certificados anexos dos padrões usados. As páginas não possuem texto pesquisável. OCR serve como rascunho e exige revisão visual.

A inspeção visual conferiu os modelos e tabelas representativos. Extração de texto foi realizada nos 14 PDFs; para o conjunto digitalizado de 19 páginas foi aplicado OCR local apenas para reconhecer a composição. Isso não representa transcrição validada de todos os resultados, autenticidade das assinaturas ou aprovação metrológica.

## Consequências para as fases 3–7 e 15

1. Laboratórios e padrões: cadastrar instrumento padrão, certificado/emissor e validade histórica com vínculo ao evento. Datas dos padrões anexos não definem próxima calibração do equipamento principal.
2. Certificados: guardar PDF integral imutável, revisão/versão, vínculo ao evento, hash e papel de cada documento (principal, padrão, assinatura, avaliação). O nome CE do arquivo não é o número do certificado emitido pelo laboratório.
3. Grupos: separar grandeza, escala/função, modo medidor/fonte, faixa, resolução, unidade e página. Mesmo instrumento pode ter diversas grandezas e unidades.
4. Pontos: conservar os valores originais e sua precisão; registrar referência/indicação, erro/tendência, U, k, veff e localização na página. Não inferir sinal de erro de forma universal.
5. Ângulos: precisar de entrada/normalização explícita de graus e minutos, unidade consistente entre erro/U/tolerância e referência à regra de conversão. Texto angular não pode ser tratado como decimal simples.
6. Tolerância: EMA/MEA de fabricante e selo de aprovação no documento são evidências; o critério/tolerância do processo RHDD e a decisão humana permanecem separados. Não copiar tolerância de um certificado de padrão para outro instrumento.
7. Extração assistida: texto e OCR com indicação de origem/página, campos ausentes e confiança. Revisão humana obrigatória, sem criar instrumentos, datas, liberação ou aprovação automaticamente.

## Situação implementada e lacunas

O fluxo manual atual já aceita PDF privado, identificação, pontos, checklist e decisão; o motor continua usando |Erro| + |U| < Tolerância com unidades iguais. Os anexos cadastrais e a LI das fases 1/2 não substituem o certificado de cada ciclo.

Modelagem completa de laboratórios/padrões, grupos por modo/escala, pacote de certificados e extração/OCR pertencem aos próximos checkpoints. Os PDFs foram recebidos como referência para essas providências. A LI oficial e os critérios RHDD ainda precisam ser fornecidos/confirmados.
