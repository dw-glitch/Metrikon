# Metrikon

Novo produto independente. **Nenhum sistema ou banco GRCON foi alterado.**

## O que esta entrega representa

Fundação e cadastro mestre, com protótipo demonstrável do ciclo manual de controle metrológico. Em 05/10/2026, o banco e o bucket privado de certificados foram ativados no novo projeto Supabase **CCP CONSAG**, separado da ConsagVINI. O frontend React/TypeScript está configurado para esse destino. O proprietário real já foi criado, confirmado e ativado. **Publicado no Cloudflare em https://metrikon.grcon-qualidade.workers.dev/. Login/upload autenticado pela interface ainda estão pendentes.** O repositório de continuidade é `dw-glitch/Metrikon`. A fase 0 não será declarada integralmente concluída antes desses testes ponta a ponta.

A demonstração usa dados fictícios e mantém dados/PDFs **apenas em memória nesta sessão**. Não realiza liberações operacionais reais. É possível revisar o fluxo pelo arquivo `Metrikon_Demonstracao.html`, sem Node ou instalação. A configuração de produção nunca está embutida nesse arquivo.

## Implementado e verificável

- Identidade Metrikon confirmada pelo proprietário em 05/10/2026; logo enviada aplicada sem redesenho e cores azuis/teal alinhadas à marca.
- Cadastro de empresas e instrumentos; identificações distintas; cadastro em cinco etapas; ficha permanente; múltiplas grandezas/faixas.
- Histórico de mudança de periodicidade com anterior/novo/motivo/evidência/responsável/data.
- Protótipo manual em seis etapas: evento, PDF, resultados, checklist, análise quantitativa e decisão.
- Regra exata `abs(erro) + abs(incerteza) < tolerância` em TypeScript/Decimal e PostgreSQL/NUMERIC; igualdade não conforme.
- Checklist de 19 itens; observação/evidência e justificativa para não aplicável.
- Rascunho sem modificar a situação operacional; decisão humana; PDF associado ao ciclo; evento concluído imutável.
- Dados cadastrais, situação operacional, estado metrológico e workflow separados.
- Busca por identificações, certificado, fabricante/modelo, empresa e responsável. Paginação de 50 registros no backend.
- Exportação Excel de instrumentos com os filtros aplicados; auditoria exportável (últimos 100 registros exibidos na produção).
- RLS por empresa e autorização persistida no banco; sem decisões de acesso com `user_metadata`.
- Storage privado de PDF (20 MB), arquivos novos sem sobrescrita; URLs assinadas de 60 segundos.
- Menu, dashboard e layout responsivo; infraestrutura de eventos do mascote, sem vídeos.

## Desenvolvimento

Requer Node 24 para desenvolvimento e CI. O usuário operacional só precisa de navegador após a publicação.

```sh
npm ci
npm run verify
npm run test:ui
npm run dev
```

`test:ui` inicia seu próprio servidor e encerra ao concluir. Em ambientes com restrições de sockets Unix, usa Chromium headless sem processos auxiliares; nenhum isolamento/permissão do aplicativo é desativado.

## Próxima ação

Leia `docs/CHECKPOINT.md`, `docs/ATIVACAO.md`, `docs/ATIVACAO-20261005.md`, `docs/PRIMEIRO-ACESSO.md`, `docs/REPOSITORIO-PUBLICACAO.md` e `docs/PENDENCIAS-RHDD.md`. Não reaplicar as migrações já executadas. O projeto novo foi criado pelo usuário no plano Free; não houve criação de outro projeto nem mudança de plano nesta ativação. ConsagVINI continua excluída. O proprietário `vinicio.silva@agnet.com.br` já está confirmado e ativo. O usuário criou `dw-glitch/Metrikon` e autorizou a atualização da versão anterior em 05/10/2026. O código está organizado na raiz; a publicação Cloudflare e o QA público foram concluídos; a próxima etapa da fase 0 é QA autenticado. O método reproduzível de deploy está em `docs/REPOSITORIO-PUBLICACAO.md`.

O estado das 19 fases e os critérios de continuidade estão em [`docs/FASES-METRIKON.md`](docs/FASES-METRIKON.md). As fases seguintes serão implementadas somente após comando do usuário, conforme confirmado em 05/10/2026.

A importação real da LI, os cadastros de laboratórios/padrões, a central completa de pendências, RNC/impactos, QR/etiquetas, competências, extração assistida, notificações e vídeos são próximas fases. Não há botões que simulem a entrega dessas funcionalidades.


## Cadastros auxiliares e LI

Fases 1 e 2: cadastros auxiliares por empresa, anexos privados na ficha e importação XLSX/XLS/CSV com mapeamento, prévia, proteção de duplicados e confirmação humana. Ver `docs/FASES-1-2-20261005.md` para limites, migração e validações. Novos cadastros importados iniciam fora de uso e sem datas/liberação metrológica.
