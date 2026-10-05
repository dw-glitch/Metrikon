# Ativação independente — banco ativado, acesso/publicação pendentes

**Atualização de 05/10/2026:** o usuário reconectou o Supabase a outra organização, com o projeto recém-criado e vazio **CCP CONSAG** (`aimvjsbrxnyqjurgicec`). As quatro migrações locais foram aplicadas nesse destino, o bucket privado foi criado e o QA transacional remoto passou. O proprietário `vinicio.silva@agnet.com.br` já foi criado pelo usuário, confirmado e ativado no papel owner. Não executar novamente os passos de provisionamento/cadastro abaixo. Login/upload pela interface e publicação ainda estão pendentes. Evidências: `docs/ATIVACAO-20261005.md` e próxima etapa em `docs/REPOSITORIO-PUBLICACAO.md`.

1. Usar exclusivamente o projeto independente **CCP CONSAG** (`aimvjsbrxnyqjurgicec`), já provisionado pelo usuário. ConsagVINI permanece excluída.
2. Banco, bucket privado e proprietário confirmado/ativo já foram verificados. As quatro migrações estão aplicadas, incluindo a identidade Metrikon. Não repetir provisionamento nem cadastro do proprietário.
3. Usar o repositório existente `dw-glitch/Metrikon`, atualizado por autorização do usuário, e conectar um novo Worker Cloudflare chamado `metrikon`. Seguir `docs/REPOSITORIO-PUBLICACAO.md`.
4. Configurar as variáveis de `deployment-public.env.example`, incluindo `VITE_APP_NAME=Metrikon`, URL do projeto independente e somente chave pública publishable.
5. Verificar deploy ativo, URL própria, login, RBAC, permissões negadas, upload real, URL assinada, exportação, histórico e ciclo completo. Só então declarar a fase 0 remota concluída.

## Limites a conferir antes da ativação

Segundo a documentação oficial consultada em 02/10/2026, o limite de dois projetos gratuitos ativos vale entre todas as organizações em que a conta é Owner ou Administrator. Criar apenas outra organização nessa mesma conta não amplia esse limite. Cada projeto possui uma instância Postgres própria; as cotas de uso são geralmente agregadas por organização, com limites específicos por projeto, como tamanho do banco. O recurso efetivamente esgotado ainda não foi identificado: não presumir que foi banco, armazenamento, tráfego ou quantidade de projetos. Conferir Usage no novo destino antes de escolher o plano.

Fonte: https://supabase.com/docs/guides/platform/billing-on-supabase

## Armazenamento dos certificados

O usuário confirmou que os certificados devem ser armazenados no aplicativo. Guardar o PDF original no bucket privado do novo projeto, vinculado ao instrumento/evento e protegido pelas permissões de empresa. O bucket já existe no Supabase real; o primeiro upload e a abertura por URL assinada com usuário real ainda precisam ser validados. O limite de upload implementado é 20 MB por PDF. O plano Free inclui 1 GB de armazenamento de arquivos por organização, segundo a documentação consultada; avaliar quantidade e tamanho médio dos PDFs antes de escolher o plano. Não apagar certificados históricos para liberar espaço sem decisão explícita. A demonstração HTML mantém arquivos somente em memória e não serve como arquivo permanente.

## Proprietário

O proprietário `vinicio.silva@agnet.com.br` já foi criado pelo usuário, confirmado e ativado automaticamente pela reserva privada de uso único. A reserva está consumida. Não recriar o usuário nem solicitar sua senha. Ver `docs/PRIMEIRO-ACESSO.md`.

## Roteiro de QA remoto

Owner cadastra empresa/instrumento → analista sem permissão não consegue modificar via console → contratada da empresa B não vê dados/PDFs da empresa A → rascunho não libera instrumento → igualdade não libera → ponto conforme + checklist + PDF + autorização permitem decisão → evento concluído não muda → próximo ciclo preserva anterior → revogação do membro remove acesso → exportação corresponde aos filtros → signed URL expira.

A estrutura real de storage/Auth foi provisionada em 05/10/2026 e o QA transacional SQL remoto passou. Os testes locais usam PGlite com stubs apenas dos schemas Auth/Storage. Nenhum desses testes substitui o QA de login/upload autenticado e de publicação.
