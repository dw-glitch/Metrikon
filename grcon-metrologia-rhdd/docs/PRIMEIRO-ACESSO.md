# Primeiro acesso do proprietário

E-mail definido pelo usuário: **vinicio.silva@agnet.com.br**.

O papel está reservado de forma privada no projeto **CCP CONSAG**. Ainda não existe usuário Auth real com esse e-mail. A integração conectada não oferece criação de usuários Auth; não foi gerada senha nem enviado convite.

1. Abrir [Authentication → Users do CCP CONSAG](https://supabase.com/dashboard/project/aimvjsbrxnyqjurgicec/auth/users).
2. Selecionar **Add user → Create user** (a interface pode exibir “Create new user”).
3. Informar exatamente `vinicio.silva@agnet.com.br` e definir a senha diretamente no painel.
4. Criar o usuário com o e-mail confirmado pelo administrador (opção **Auto Confirm User**, quando exibida). Se usar um fluxo com confirmação por e-mail, completar essa confirmação.

Após a confirmação, o gatilho privado vincula automaticamente o UUID real ao papel `owner`. Outro e-mail não recebe esse papel, e a ativação só acontece uma vez. Não é necessário executar SQL, compartilhar senha no chat ou instalar Node.

Depois verificar o vínculo no banco, concluir publicação do novo app e testar login, upload, leitura do PDF por URL assinada e isolamento por empresa. O acesso do aplicativo é distinto do login do painel Supabase. ConsagVINI e GRCON antigo não são utilizados.
