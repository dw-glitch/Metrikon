# Arquitetura e isolamento — escopo mínimo de 06/10/2026

React, TypeScript e Vite. A interface ativa contém somente Cadastro e Monitoramento. SimpleRegistrationForm reúne os campos SCC; domain/minimal.ts concentra cálculo, validação e vencimento; services/minimal-repository.ts usa RPCs com autorização no servidor. A gestão de acessos é uma ação do proprietário no cabeçalho.

## Cadastro, aprovação e certificado

instruments conserva a ficha e a LI oficial. instrument_registrations armazena propostas versionadas com os dados cadastrais, certificado, resultado quantitativo calculado pelo servidor, autor, envio, revisão e observação. Existe somente uma versão em andamento por instrumento.

O rascunho inicial reserva a LI e cria a ficha fora de uso, sem certificado vigente. O envio congela a proposta. O responsável pode devolver com motivo ou aprovar; somente a aprovação aplica os dados da proposta à ficha, às datas e ao certificado vigente. Uma renovação usa a mesma ficha e LI, preservando versões e arquivos anteriores. O bloqueio da ficha e da proposta usa a mesma ordem nas funções de edição e revisão; a aprovação verifica a data da ficha usada pela proposta.

Novas propostas calculam |erro| + |incerteza| ≤ tolerância, com precisão decimal, conforme a anotação de 06/10. A interface oferece um botão para aplicar a sugestão de aceitação. Respostas manuais, situação operacional e aprovação permanecem decisões explícitas. Eventos históricos mantêm os dados e o critério estrito anterior.

## Consulta e acessos

minimal_workspace filtra toda a base autorizada antes da paginação de 50 registros. As contagens abrangem essa base; a exportação consulta todas as páginas do filtro. Vencimentos usam o calendário de America/Recife, com janela explícita de 1–365 dias, inicialmente 30. O vencimento sinaliza a pendência sem alterar automaticamente a situação operacional.

Proprietário (owner) gerencia perfis; Responsável (quality_admin) cadastra e revisa; Cadastro (analyst) prepara e envia; Consulta (viewer, além de papéis legados de consulta) apenas lê. O vínculo pode limitar o acesso à empresa. A concessão de perfil exige usuário Auth existente e e-mail confirmado. Não há criação ou alteração de owner nessa ação, nem autoelevação.

## Segurança e compatibilidade histórica

RLS permite leitura apenas com vínculo ativo e escopo autorizado. Alterações passam pelas novas RPCs. Wrappers públicos são SECURITY INVOKER; o núcleo privado usa SECURITY DEFINER, search_path vazio, identificação por auth.uid(), permissão, escopo, bloqueios e auditoria. Escritas diretas nas tabelas permanecem proibidas. As antigas funções de cadastro/importação/eventos e preparação da LI têm execução revogada aos clientes para não contornar a revisão.

Os certificados usam o bucket privado metrology-certificates, arquivos PDF/XLSX/XLS até 16 MB, caminho vinculado ao instrumento e leitura assinada por 60 segundos. O servidor verifica existência, proprietário ou vínculo histórico autorizado, tamanho e tipo do objeto. O cliente verifica a assinatura do arquivo antes de iniciar a gravação. Não há sobrescrita ou exclusão de certificados aprovados.

As tabelas anteriores de eventos, pontos, decisões, laboratórios, padrões, rastreabilidade e importação permanecem preservadas. A ficha lê eventos anteriores como histórico. Os formulários e módulos antigos saíram da interface ativa; a manutenção dos arquivos e tabelas não autoriza retomar o roteiro anterior de 19 fases.

## Validação e limites

A suíte mínima aplica todas as migrações e testa permissões, bloqueio das APIs legadas, anexos, devolução, aprovação, renovação, isolamento empresarial e paginação. As suítes históricas aplicam o conjunto anterior de migrações para verificar seus contratos originais. A demonstração não persiste dados no banco.

Não há OCR/IA, checklist avançado, RNC, notificações, QR/etiquetas ou operação offline neste escopo. Login com usuários reais, confirmação de novos acessos, upload e abertura pelo Storage API e QA operacional de perfis continuam pendentes; testes SQL com identidade simulada não substituem a validação autenticada pela interface.
