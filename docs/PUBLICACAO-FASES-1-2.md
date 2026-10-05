# Publicação das fases 1 e 2 — 05/10/2026

URL: https://metrikon.grcon-qualidade.workers.dev/

Código servido: `fe34977b02a3e0273f3260ca0428fbd10f363b33` do repositório `dw-glitch/Metrikon`.

Cloudflare version ID: `fd07434b-113c-4bb3-bb06-8af285e19e29`.

Execução aprovada: https://github.com/dw-glitch/GRCON/actions/runs/37324017303

Commit de infraestrutura: `945e659c4956b57a3fdb626f57531e8cd09b08eb`, branch isolado `infra/metrikon-cloudflare-deploy`. O workflow obtém somente a versão fixada do Metrikon e usa os secrets existentes apenas no passo de deploy. O aplicativo GRCON não foi publicado nem sua main alterada.

## Evidências

- 42 testes e build aprovados na execução remota.
- 13 grupos Chromium aprovados antes da publicação, incluindo cadastro auxiliar, anexo da ficha e LI em Worker.
- Wrangler dry-run e deploy aprovados.
- Metadados públicos correspondem ao SHA servido. HTTP, rota SPA `/instrumentos`, logo, manifesto e tela de acesso desktop/mobile aprovados.
- Conferência adicional no navegador do endereço público: demonstração aberta e menus novos presentes; página Importar LI com arquivo, cabeçalho e etapas visíveis.
- QA PostgreSQL remoto transacional aprovado, sem persistir fixtures. Bucket de anexos cadastrais privado. Empresas, instrumentos, cadastros auxiliares e lotes continuam vazios; nenhuma amostra virou dado operacional.

## Limites

Login do proprietário e upload real/URL assinada pela interface ainda pendentes. A LI oficial não foi recebida. Esta validação não atesta aprovação metrológica ou transcrição dos certificados. Documentos originais foram apenas lidos como referência local; somente requisitos genéricos foram registrados no repositório.

## Continuidade

Mudanças de documentação podem estar à frente do SHA servido. Para publicar novo código, validar, escolher o SHA e atualizar todas as referências fixadas de `.github/workflows/deploy-metrikon-cloudflare.yml` no branch de infraestrutura. Não usar a main do GRCON nem alterar o Worker GRCON.
