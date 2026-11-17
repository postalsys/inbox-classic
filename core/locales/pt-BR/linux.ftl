# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = A pesquisa em { $place } abrange assuntos, remetentes, destinatários, nomes de anexos e texto das mensagens. Verifique a ortografia ou tente menos palavras.
gtk-search-still-indexing = { $count ->
    [one] O texto de { $count } mensagem ainda está sendo indexado. Mais resultados podem aparecer em breve.
   *[other] O texto de { $count } mensagens ainda está sendo indexado. Mais resultados podem aparecer em breve.
}
gtk-search-results-everywhere = { $count ->
    [0] Nenhum resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para “{ $words }” em todas as pastas
gtk-search-results-in = { $count ->
    [0] Nenhum resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para “{ $words }” em { $place }
gtk-search-indexing = { $count ->
    [one] ainda indexando o texto de { $count } mensagem
   *[other] ainda indexando o texto de { $count } mensagens
}
gtk-list-loading = Carregando...
gtk-menu-rename = Renomear...
gtk-import-one-question = Importar a mensagem { $file } para { $folder }?
gtk-files-not-saved = Arquivos que não foi possível salvar: { $failed } de { $total }.
gtk-unsubscribe-one-click =
    Sair desta lista de e-mails?

    O Inbox Classic vai enviar um pedido de cancelamento da inscrição para { $target }. Nenhuma página da Web será aberta e nenhum e-mail será enviado.
gtk-unsubscribe-mail =
    Sair desta lista de e-mails?

    Para cancelar a inscrição, envie um e-mail para { $target }. O Inbox Classic o prepara para você. Envie a mensagem para confirmar.
gtk-unsubscribe-web =
    Sair desta lista de e-mails?

    A página de cancelamento da inscrição da lista de e-mails vai abrir no seu navegador ({ $target }).
gtk-unsubscribe-failed = Não foi possível cancelar a inscrição: { $problem }
gtk-toolbar-create-mail-menu = Escrever a partir de uma conta específica
gtk-toolbar-send-recv-menu = Enviar e receber e-mails de uma conta específica
gtk-main-menu = Menu principal
gtk-folder-list = Lista de pastas
gtk-quit = Sair

## The Move and Copy window

gtk-new-folder-at-top-of = A nova pasta será criada no nível principal da conta { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Não há mensagens não lidas
    [one] { $count } mensagem não lida
   *[other] { $count } mensagens não lidas
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Não há mensagens aguardando envio.
gtk-outbox-row = Para: { $to }  ·  Na fila desde { $queued }  ·  { $status }

## The app

gtk-still-running-detail = O Inbox Classic continua verificando se há e-mails novos em segundo plano. Use o ícone dele na barra superior para abrir ou fechar o aplicativo.
gtk-sign-in-again-ask =
    O login em { $account } foi rejeitado ou a sessão expirou.

    Fazer login novamente no navegador?
gtk-default-app-not-installed = Esta cópia do Inbox Classic não foi instalada, por isso o sistema não a mostra como aplicativo de e-mail. Instale-a para poder escolhê-la.
gtk-default-app-now = O Inbox Classic agora é seu aplicativo de e-mail padrão: os links de e-mail abrem uma nova mensagem aqui.
gtk-default-app-failed = Não foi possível definir o Inbox Classic como aplicativo de e-mail padrão.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Data:
gtk-reader-files = Anexos da mensagem
gtk-files = { $count ->
    [0] nenhum arquivo
    [one] { $count } arquivo
   *[other] { $count } arquivos
}
gtk-pictures-blocked = Algumas imagens foram bloqueadas para ajudar a impedir que o remetente identifique o seu computador.
gtk-download-pictures = Baixar imagens
gtk-save-attachments-menu = Salvar anexos...

## The compose window

gtk-format-bold = Negrito (Ctrl+B)
gtk-format-italic = Itálico (Ctrl+I)
gtk-format-underline = Sublinhado (Ctrl+U)
gtk-format-hyperlink = Hiperlink (Ctrl+K)
gtk-font = Fonte
gtk-show-cc = _Cc
gtk-show-bcc = Cc_o
gtk-save-tip = Salvar (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+clique para abrir)

## Accounts

gtk-plain-warning =
    Sem criptografia, qualquer pessoa que intercepte seu tráfego de rede pode ler sua senha e suas mensagens. Use esta conexão apenas com um servidor no seu próprio computador ou na sua rede local.

    Continuar?
gtk-account-name-title = Nome da conta
gtk-display-name-title = Nome de exibição
gtk-turned-off-why = A opção “{ $button }” está desativada neste computador. { $reason }
gtk-turned-off-why-long =
    A opção “{ $button }” está desativada neste computador.

    { $reason }
gtk-next = Avançar >
gtk-provider-sign-in = { $provider }: faça login em { $address } no site do provedor. Sua senha não é compartilhada com o Inbox Classic. Se sua conta permitir o uso de senhas de app para e-mail, você pode criar uma nas configurações de segurança. Para Outlook.com e Microsoft 365, é necessário fazer login pelo navegador.
gtk-provider-sign-in-apps = { $provider }: faça login em { $address } no site do provedor usando um dos seus aplicativos de login (Mais opções de login). Se sua conta permitir o uso de senhas de app para e-mail, você pode criar uma nas configurações de segurança. Para Outlook.com e Microsoft 365, é necessário fazer login pelo navegador.
gtk-accounts-add = Adicionar...
gtk-accounts-properties = Propriedades...
gtk-accounts-signature = Assinatura...
gtk-accounts-sign-in-apps = Aplicativos de login...

## Sign-in apps

gtk-app-server = Servidor { $kind }
gtk-app-port = Porta { $kind }
gtk-app-security = Segurança { $kind }
gtk-issuer-found =
    Página de login: { $page }
    Endpoint do token: { $endpoint }
gtk-client-id = ID do cliente
gtk-client-secret = Segredo do cliente
gtk-scopes = Permissões (scopes)
gtk-redirect-uri = URI de redirecionamento
gtk-issuer-usable =
    O emissor pode ser usado.

    { $found }
gtk-app-built-in = O aplicativo { $app } é integrado ao Inbox Classic. Você só pode escolher se ele aparece nas opções de login ao adicionar contas. { $reason }
gtk-built-in = { $app } (integrado)
gtk-offered-for-new = Oferecido para contas novas
gtk-edit-button = Editar...
gtk-remove-app-ask = Remover o aplicativo de login { $app } e o segredo do cliente salvo?
gtk-sign-in-apps-intro = Os aplicativos de login permitem que as contas façam login pelo navegador. Um aplicativo desativado não é oferecido para contas novas; as contas que já o usam continuam funcionando.

## AI agents

gtk-agent-it-may = Ações permitidas
gtk-agent-accounts = Contas permitidas
gtk-never-used = Nunca usado
gtk-last-used = Último uso: { $date }
gtk-forget-program = Remover este programa?
gtk-forget-program-detail = As permissões do programa e o histórico de atividade dos agentes serão excluídos. Na próxima conexão, você precisará autorizar o acesso novamente.
gtk-no-agents-yet = Nenhum agente solicitou acesso aos seus e-mails.
gtk-nothing-yet = Ainda nada.

## Preferences

gtk-preferences = Preferências
gtk-notify-subtitle = Somente enquanto o Inbox Classic está em segundo plano

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Cliente de e-mail
gtk-desktop-comment = Ler e escrever e-mails: um programa de e-mail rápido e simples
gtk-desktop-keywords = e-mail;correio;correio eletrônico;mensagens;caixa de entrada;
gtk-metainfo-summary = Um programa de e-mail rápido e simples
gtk-metainfo-description = O Inbox Classic permite ler e escrever e-mails em uma interface familiar: pastas à esquerda, lista de mensagens na parte superior e conteúdo da mensagem selecionada logo abaixo. Funciona com qualquer conta IMAP e SMTP e permite fazer login no Outlook.com e no Microsoft 365 pelo navegador.
gtk-metainfo-feature-sanitized = As mensagens são exibidas sem scripts ou outros conteúdos potencialmente perigosos; as imagens da internet só são carregadas com sua autorização
gtk-metainfo-feature-search = Pesquisa no assunto, nos remetentes, nos destinatários, nos nomes dos anexos e no texto das mensagens, com suporte aos operadores do Gmail
gtk-metainfo-feature-replies = O texto de mensagens anteriores citado nas respostas fica recolhido e pode ser expandido quando necessário
gtk-metainfo-feature-offline = Os e-mails já baixados podem ser lidos sem conexão à internet; as senhas ficam armazenadas no chaveiro do sistema
