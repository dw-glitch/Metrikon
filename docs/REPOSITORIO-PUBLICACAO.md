# Repositório e publicação Metrikon

## Publicado em 05/10/2026

URL: https://metrikon.grcon-qualidade.workers.dev/

| Evidência | Valor |
|---|---|
| Código | `dw-glitch/Metrikon`, SHA `db53260950d612b7e43c6d929b20f04a74230d81` |
| Worker | `metrikon` |
| Conta | Mesma conta Cloudflare usada pelo GRCON |
| Version ID | `757bd589-2a05-4e0d-af78-5c46b87b050e` |
| Execução | https://github.com/dw-glitch/GRCON/actions/runs/37317718220 |

A publicação foi concluída por **GitHub Actions → Wrangler → Workers Static Assets**, repetindo o método efetivamente usado pelo GRCON. O painel Cloudflare apresentou erro de verificação neste navegador; o fluxo de CI usa as credenciais já cadastradas no GitHub e dispensa esse login interativo.

## Onde a rotina executa

As credenciais `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID` já existem no repositório GRCON. Secrets de repositório não são automaticamente compartilhados com Metrikon e seus valores não são recuperáveis pela conexão. Por isso a rotina de publicação está em uma branch dedicada do GRCON:

- Branch: `infra/metrikon-cloudflare-deploy`.
- Arquivo: `.github/workflows/deploy-metrikon-cloudflare.yml`.
- Link: https://github.com/dw-glitch/GRCON/blob/infra/metrikon-cloudflare-deploy/.github/workflows/deploy-metrikon-cloudflare.yml.

Essa rotina baixa somente o código do **Metrikon**, fixado em SHA completo. A branch principal e a rotina existente de deploy do GRCON não foram modificadas. O novo Worker tem nome `metrikon` e publica `dist/` do Metrikon. Banco, autenticação e PDFs permanecem no projeto independente Supabase **CCP CONSAG**, ref `aimvjsbrxnyqjurgicec`.

A chave frontend de `deployment-public.env.example` é pública e é carregada durante o build. Os secrets Cloudflare são fornecidos exclusivamente na etapa de implantação e não são incorporados ao frontend, aos metadados, aos arquivos de QA ou à documentação.

## Etapas executadas

1. Conferência do destino e da configuração pública independente.
2. Node 24 e `npm ci --ignore-scripts`.
3. `npm run verify`: 31 testes e compilação de produção.
4. Wrangler dry-run e 10 grupos Chromium com `npm run test:ui`.
5. Inclusão de `deployment-meta.json` no pacote, com app, repositório, SHA do código e execução.
6. `npm run deploy:cloudflare -- --config wrangler.jsonc --name metrikon`.
7. Conferência dos metadados servidos, página principal, rota SPA por navegação real, logo PNG, manifesto e tela de acesso desktop/mobile, sem erros de JavaScript.
8. Evidências em `metrikon-cloudflare-qa` na execução GitHub Actions.

Todas as etapas passaram na execução final. O endereço público também foi aberto no Cloud Browser, com formulário de login e logo visíveis.

## Próximas publicações

A rotina atual usa uma versão fixada e **não publica automaticamente qualquer commit na main do Metrikon**. As fases posteriores continuam aguardando comando do usuário.

Após concluir e validar uma fase autorizada:

1. Integrar o código ao `dw-glitch/Metrikon` e registrar seu SHA completo.
2. Atualizar no workflow da branch dedicada os pontos que fixam/conferem esse SHA: checkout, geração de metadados e validação dos metadados/registro de evidências.
3. Enviar a atualização dessa rotina para `infra/metrikon-cloudflare-deploy`; o push no arquivo de workflow dispara a publicação.
4. Acompanhar o resultado e conferir a nova versão em `/deployment-meta.json`.

Não é necessário copiar tokens para o chat ou para o código. A autonomia do código Metrikon permanece no seu próprio repositório; essa branch é apenas o executor de publicação com credenciais existentes. Uma transferência futura da rotina ao próprio repositório Metrikon exige configurar ali os secrets de implantação por um canal seguro.

## Critérios ainda pendentes da fase 0

- No Supabase CCP CONSAG, conferir **Authentication → URL Configuration → Site URL** como `https://metrikon.grcon-qualidade.workers.dev/`. O deploy não alterou essa configuração de autenticação.
- Login autenticado do proprietário `vinicio.silva@agnet.com.br` com a senha já criada pelo usuário.
- Cadastro autorizado, envio de um PDF de teste, reabertura por URL assinada, isolamento por empresa e expiração da URL.

Não recriar o proprietário, não reaplicar migrações e não usar ConsagVINI. A publicação e o QA público não substituem esses testes autenticados.

## Configuração alternativa pelo painel

Caso seja desejada posteriormente uma integração nativa Cloudflare Builds, o repositório também suporta Worker `metrikon`, branch `main`, raiz vazia, build `npm run verify` e deploy `npm run deploy:cloudflare`. Usar `NODE_VERSION=24` e as variáveis de build de `deployment-public.env.example`. Esse método pelo painel não foi o usado nesta publicação.

## Referências oficiais

- https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/
- https://developers.cloudflare.com/workers/static-assets/routing/single-page-application/
- https://supabase.com/docs/guides/auth/redirect-urls
