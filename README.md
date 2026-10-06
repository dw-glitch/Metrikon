# Metrikon

Cadastro e monitoramento de instrumentos de calibração para a equipe da qualidade, baseado nos campos do SCC apresentados por Vinício.

Aplicativo: https://metrikon.grcon-qualidade.workers.dev/

## Fluxo
- **Cadastro:** dados do equipamento e da calibração na mesma tela; LI automática; certificado privado; salvar rascunho e enviar ao responsável.
- **Monitoramento:** pesquisar, filtrar vencidos/próximos/sem data, consultar ficha e histórico e exportar Excel filtrado.
- **Atualizar certificado:** abrir a mesma ficha, informar a nova calibração e enviar; a aprovação atualiza a versão vigente e preserva as anteriores.
- **Perfis:** Proprietário, Responsável, Cadastro e Consulta. Só o proprietário gerencia acessos pelo cabeçalho.

O cálculo do fluxo mínimo compara |Erro| + |Incerteza| ≤ Tolerância conforme a anotação de 06/10/2026. Aprovação continua humana. O plano anterior de 19 fases foi substituído; ver docs/PLANO-MINIMO-20261006.md.

## Desenvolvimento
Node 24, React/TypeScript/Vite, Supabase independente CCP CONSAG e Cloudflare Worker metrikon. Configuração pública em deployment-public.env.example; nenhuma chave privilegiada no frontend.

```sh
npm ci
npm run verify
npm run test:ui
npm run deploy:cloudflare -- --dry-run
```

As migrações históricas são preservadas. Não reaplicar migrações antigas por diferença de timestamp entre o arquivo SQL local e a versão remota. Não utilizar o banco ou Worker do GRCON.

Os testes antigos validam seus contratos históricos anteriores à migração mínima. tests/minimal-database.test.ts aplica todas as migrações e valida o contrato vigente, hierarquia, aprovação, renovação, isolamento e bloqueio de escrita pelas APIs antigas.

Estado publicado e QA operacional pendente: docs/CHECKPOINT.md.
