# Repositório e publicação Metrikon

## Repositório confirmado em 05/10/2026

O usuário criou https://github.com/dw-glitch/Metrikon, branch principal `main`, e enviou manualmente a versão anterior extraída do ZIP. Em seguida autorizou sua atualização para a entrega Metrikon, com nome e logo finais.

A atualização organiza o código na raiz (`package.json`, `src`, `public`, `supabase`, `tests`, `docs`) e inclui `.github/workflows/verify.yml`, `.gitignore` e `.env.example`. O commit de upload anterior permanece no histórico. Os arquivos compilados, resultados temporários de testes e bundle antigo não são necessários na árvore atual: o build é reproduzido a partir do código e o histórico preserva o envio anterior.

A demonstração entregue como `Metrikon_Demonstracao.html` é isolada e usa dados fictícios; pode ser regenerada com `node scripts/build-demo.mjs`. O código operacional recebe a configuração por variáveis de ambiente. Nunca enviar `.env.local`, segredos ou node_modules ao repositório.

O commit na branch principal é o checkpoint oficial para as próximas fases. Consultar `docs/FASES-METRIKON.md`. As fases seguintes aguardam comando do usuário; atualização no GitHub não representa publicação Cloudflare nem validação de login real.

## Destino escolhido: Cloudflare Workers com Static Assets

Em 05/10/2026 o usuário escolheu Cloudflare para publicar pelo navegador. O repositório inclui `wrangler.jsonc`, Wrangler com versão fixa no lockfile, Node 24 em `.node-version`, rotas SPA e `public/_headers`. O Vite copia os arquivos públicos para `dist`. Não é necessário instalar Node no computador do usuário.

### Passos pelo navegador

1. Entre em https://dash.cloudflare.com/ e selecione sua conta.
2. Abra **Workers & Pages** → **Create application** → **Import a repository / Get started**. Conecte o GitHub e autorize o repositório `dw-glitch/Metrikon`.
3. Selecione o repositório e preencha:

| Campo | Valor |
|---|---|
| Worker name / Nome | `metrikon` (deve coincidir com `wrangler.jsonc`) |
| Production branch / Branch | `main` |
| Root directory / Diretório raiz | Vazio, ou `.` se o painel exigir um valor |
| Build command | `npm run verify` |
| Deploy command | `npm run deploy:cloudflare` |

A saída `dist` já está definida em `wrangler.jsonc`; não é necessário um campo de output directory no fluxo Workers. O build executa os testes de domínio/banco local e compila o frontend. Os testes Chromium continuam no GitHub Actions.

4. Em **Build variables and secrets**, adicione as três variáveis de `deployment-public.env.example` e `NODE_VERSION=24`. Não configurar somente variáveis de runtime: o Vite precisa dos valores durante a compilação. A chave `sb_publishable_...` é pública. Nunca substituir por secret key ou service_role.
5. Use a criação automática do token de implantação oferecida pela Cloudflare. Não copiar tokens para o código ou para o chat.
6. Clique **Save and Deploy**. Aguarde build bem-sucedido e implantação ativa. Abra a URL fornecida, no formato `https://metrikon.<subdominio-da-conta>.workers.dev`; o endereço exato só existe após a publicação.
7. No Supabase **CCP CONSAG** (`aimvjsbrxnyqjurgicec`), em **Authentication → URL Configuration**, defina o **Site URL** com o endereço HTTPS publicado. A opção controla redirecionamentos de autenticação e links de e-mail. Não reaplicar migrações nem recriar o proprietário.
8. Acesse o app com `vinicio.silva@agnet.com.br` e a senha que o proprietário já criou. Verifique login, cadastro autorizado, upload de um PDF de teste, reabertura do certificado, isolamento por empresa e expiração das URLs assinadas. Só então considerar a fase 0 remota concluída.

### Continuidade

Commits na branch de produção conectada disparam builds e publicações. As próximas fases continuam aguardando comando do usuário. Não enviar fases incompletas a `main` com publicação automática habilitada. Um domínio próprio é opcional e pode ser vinculado depois em **Settings → Domains & Routes**.

O banco, autenticação e PDFs continuam no Supabase independente. O plano Cloudflare tem limites de compilação e de recursos dinâmicos; não significa implantação ilimitada de todos os serviços.

### Validação da preparação

Em 05/10/2026, `npm run verify` passou os 31 testes e a compilação; `npm run deploy:cloudflare -- --dry-run` validou o pacote sem publicar. O servidor local Wrangler serviu `/` e uma rota interna com HTTP 200, título Metrikon e os headers configurados; a logo retornou PNG. A implantação real, login e upload na URL pública continuam pendentes.

### Referências oficiais

- https://developers.cloudflare.com/workers/ci-cd/builds/
- https://developers.cloudflare.com/workers/ci-cd/builds/configuration/
- https://developers.cloudflare.com/workers/static-assets/routing/single-page-application/
- https://developers.cloudflare.com/workers/static-assets/headers/
- https://supabase.com/docs/guides/auth/redirect-urls
