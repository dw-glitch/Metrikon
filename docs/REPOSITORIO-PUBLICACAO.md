# Repositório e publicação Metrikon

## Repositório confirmado em 05/10/2026

O usuário criou https://github.com/dw-glitch/Metrikon, branch principal `main`, e enviou manualmente a versão anterior extraída do ZIP. Em seguida autorizou sua atualização para a entrega Metrikon, com nome e logo finais.

A atualização organiza o código na raiz (`package.json`, `src`, `public`, `supabase`, `tests`, `docs`) e inclui `.github/workflows/verify.yml`, `.gitignore` e `.env.example`. O commit de upload anterior permanece no histórico. Os arquivos compilados, resultados temporários de testes e bundle antigo não são necessários na árvore atual: o build é reproduzido a partir do código e o histórico preserva o envio anterior.

A demonstração entregue como `Metrikon_Demonstracao.html` é isolada e usa dados fictícios; pode ser regenerada com `node scripts/build-demo.mjs`. O código operacional recebe a configuração por variáveis de ambiente. Nunca enviar `.env.local`, segredos ou node_modules ao repositório.

O commit na branch principal é o checkpoint oficial para as próximas fases. Consultar `docs/FASES-METRIKON.md`. As fases seguintes aguardam comando do usuário; atualização no GitHub não representa publicação Vercel nem validação de login real.

## Publicação ainda pendente

As duas conexões Vercel previamente consultadas apontam para a equipe **Consagprojetos** (`bibiaprojetos`, id `team_eBDda8FnsszhSrSnLm3Jym6d`). Antes de escrita, resolver a conexão de conta exigida pela ferramenta. Usar um novo projeto chamado `metrikon`, vinculado somente ao repositório `dw-glitch/Metrikon`, com raiz do projeto vazia (raiz do repositório), framework Vite, comando `npm run build` e saída `dist`.

Configurar as variáveis de `deployment-public.env.example`, incluindo `VITE_APP_NAME=Metrikon`, URL do projeto independente CCP CONSAG e somente chave publishable. Não reaplicar as quatro migrações já executadas nem recriar o proprietário.

Verificar READY, URL própria, login real, upload de PDF, isolamento por empresa e expiração da URL assinada. Só então considerar a fase 0 remota concluída.
