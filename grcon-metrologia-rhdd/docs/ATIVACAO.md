# Ativação independente — banco ativado, acesso/publicação pendentes

**Atualização de 05/10/2026:** o usuário reconectou o Supabase a outra organização, com o projeto recém-criado e vazio **CCP CONSAG** (`aimvjsbrxnyqjurgicec`). As duas migrações locais foram aplicadas nesse destino, o bucket privado foi criado e o QA transacional remoto passou. Não executar novamente os passos de provisionamento abaixo. A identificação do proprietário, o login/upload real e a publicação ainda estão pendentes. Evidências: `docs/ATIVACAO-20261005.md`.

1. **ConsagVINI está excluída por instrução do usuário em 02/10/2026.** O usuário informou que criará outro destino devido à sobrecarga do plano grátis. Aguardar a identificação e disponibilidade da nova organização/projeto; não criar nada na ConsagVINI nem reutilizar projeto/branch do GRCON. A ferramenta exige escolha explícita e confirmação do custo antes de criar um projeto.
2. Criar novo projeto `grcon-metrologia-rhdd` em região apropriada (preferência operacional: São Paulo, a confirmar sem custo presumido). Consultar custo da organização escolhida, apresentar e obter a confirmação exigida.
3. Aplicar somente `supabase/migrations/20261002184038_metrology_foundation.sql` no projeto novo. Rodar advisors de segurança/performance, conferir RLS, grants, bucket privado e executar testes remotos com usuários de empresas distintas.
4. Criar/convocar o primeiro usuário no Supabase Auth do projeto novo. Vincular seu UUID real em `private.members` com papel owner, em operação administrativa confiável. Não colocar essa capacidade no cliente. Os demais papéis deverão ser definidos pela matriz RHDD.
5. Configurar `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY` no novo projeto Vercel. Usar somente chave pública publishable; nunca service_role. Nome configurável em `VITE_APP_NAME`.
6. Criar repositório separado e privado destinado a este produto; enviar os commits locais. O conector GitHub disponível não oferece operação de criação de repositório; não houve escrita no repositório GRCON. O bundle Git incluído na entrega permite restaurar todos os checkpoints.
7. Escolher a conta Vercel destinada ao novo projeto. Existem duas conexões do mesmo e-mail; não presumir o destino de uma escrita. Vincular/deployar exclusivamente esta pasta. Configurar domínio formal do produto, sem nomes informais.
8. Verificar `READY`, acesso por URL própria, Auth, RBAC, permissões negadas, upload real, URL assinada, exportação, histórico e ciclo completo. Só então declarar a fase 0 remota concluída.

## Limites a conferir antes da ativação

Segundo a documentação oficial consultada em 02/10/2026, o limite de dois projetos gratuitos ativos vale entre todas as organizações em que a conta é Owner ou Administrator. Criar apenas outra organização nessa mesma conta não amplia esse limite. Cada projeto possui uma instância Postgres própria; as cotas de uso são geralmente agregadas por organização, com limites específicos por projeto, como tamanho do banco. O recurso efetivamente esgotado ainda não foi identificado: não presumir que foi banco, armazenamento, tráfego ou quantidade de projetos. Conferir Usage no novo destino antes de escolher o plano.

Fonte: https://supabase.com/docs/guides/platform/billing-on-supabase

## Armazenamento dos certificados

O usuário confirmou que os certificados devem ser armazenados no aplicativo. Guardar o PDF original no bucket privado do novo projeto, vinculado ao instrumento/evento e protegido pelas permissões de empresa. O bucket já existe no Supabase real; o primeiro upload e a abertura por URL assinada com usuário real ainda precisam ser validados. O limite de upload implementado é 20 MB por PDF. O plano Free inclui 1 GB de armazenamento de arquivos por organização, segundo a documentação consultada; avaliar quantidade e tamanho médio dos PDFs antes de escolher o plano. Não apagar certificados históricos para liberar espaço sem decisão explícita. A demonstração HTML mantém arquivos somente em memória e não serve como arquivo permanente.

## Bootstrap administrativo (somente no projeto novo)

Depois de criar o usuário no Auth, a operação é:

```sql
-- Substituir pelo UUID REAL do usuário confirmado. Executar no projeto novo, por administrador confiável.
insert into private.members(user_id, role, active)
values ('00000000-0000-0000-0000-000000000000'::uuid, 'owner', true);
```

O UUID acima é deliberadamente um placeholder e falhará se não existir em Auth. Não é uma credencial nem cria um usuário. Não executar sem substituir e confirmar o ambiente.

## Roteiro de QA remoto

Owner cadastra empresa/instrumento → analista sem permissão não consegue modificar via console → contratada da empresa B não vê dados/PDFs da empresa A → rascunho não libera instrumento → igualdade não libera → ponto conforme + checklist + PDF + autorização permitem decisão → evento concluído não muda → próximo ciclo preserva anterior → revogação do membro remove acesso → exportação corresponde aos filtros → signed URL expira.

A estrutura real de storage/Auth foi provisionada em 05/10/2026 e o QA transacional SQL remoto passou. Os testes locais usam PGlite com stubs apenas dos schemas Auth/Storage. Nenhum desses testes substitui o QA de login/upload autenticado e de publicação.
