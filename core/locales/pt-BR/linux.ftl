# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

# review: new
gtk-search-looks-in = A pesquisa em { $place } abrange assuntos, remetentes, destinatários, nomes de anexos e texto das mensagens. Verifique a ortografia ou tente menos palavras.
# review: new
gtk-search-still-indexing = { $count ->
    [one] O texto de { $count } mensagem ainda está sendo indexado. Mais resultados podem aparecer em breve.
   *[other] O texto de { $count } mensagens ainda está sendo indexado. Mais resultados podem aparecer em breve.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Nenhum resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para “{ $words }” em todas as pastas
# review: new
gtk-search-results-in = { $count ->
    [0] Nenhum resultado
    [one] { $count } resultado
   *[other] { $count } resultados
} para “{ $words }” em { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] ainda indexando o texto de { $count } mensagem
   *[other] ainda indexando o texto de { $count } mensagens
}
# review: new
gtk-list-loading = Carregando...
# review: new
gtk-menu-rename = Renomear...
# review: new
gtk-import-one-question = Importar a mensagem { $file } para { $folder }?
# review: new
gtk-files-not-saved = Não foi possível salvar { $failed } dos { $total } arquivos.
# review: new
gtk-unsubscribe-one-click =
    Sair desta lista de e-mails?

    O Inbox Classic vai enviar um pedido de cancelamento da inscrição para { $target }. Nenhuma página da Web será aberta e nenhum e-mail será enviado.
# review: new
gtk-unsubscribe-mail =
    Sair desta lista de e-mails?

    Para cancelar a inscrição, envie um e-mail para { $target }. O Inbox Classic o prepara para você. Envie a mensagem para confirmar.
# review: new
gtk-unsubscribe-web =
    Sair desta lista de e-mails?

    A página de cancelamento da inscrição da lista de e-mails vai abrir no seu navegador ({ $target }).
# review: new
gtk-unsubscribe-failed = Não foi possível cancelar a inscrição: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Escrever a partir de uma conta específica
# review: new
gtk-toolbar-send-recv-menu = Enviar e receber e-mails de uma conta específica
# review: new
gtk-main-menu = Menu principal
# review: new
gtk-folder-list = Lista de pastas
# review: new
gtk-quit = Sair

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = A nova pasta fica no nível superior de { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Não há mensagens não lidas
    [one] { $count } mensagem não lida
   *[other] { $count } mensagens não lidas
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Não há mensagens aguardando envio.
# review: new
gtk-outbox-row = Para: { $to }  ·  Em fila { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = O Inbox Classic continua verificando se há e-mails novos em segundo plano. Use o ícone dele na barra superior para abrir ou fechar o aplicativo.
# review: new
gtk-sign-in-again-ask =
    O login em { $account } foi rejeitado ou expirou.

    Fazer login novamente no navegador?
# review: new
gtk-default-app-not-installed = Esta cópia do Inbox Classic não foi instalada, por isso o sistema não a mostra como aplicativo de e-mail. Instale-a para poder escolhê-la.
# review: new
gtk-default-app-now = O Inbox Classic agora é seu aplicativo de e-mail padrão: os links de e-mail abrem uma nova mensagem aqui.
# review: new
gtk-default-app-failed = Não foi possível tornar o Inbox Classic o aplicativo de e-mail padrão.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Data:
# review: new
gtk-reader-files = Anexos da mensagem
# review: new
gtk-files = { $count ->
    [0] nenhum arquivo
    [one] { $count } arquivo
   *[other] { $count } arquivos
}
# review: new
gtk-pictures-blocked = Algumas imagens foram bloqueadas para ajudar a impedir que o remetente identifique o seu computador.
# review: new
gtk-download-pictures = Baixar imagens
# review: new
gtk-save-attachments-menu = Salvar anexos...

## The compose window

# review: new
gtk-format-bold = Negrito (Ctrl+B)
# review: new
gtk-format-italic = Itálico (Ctrl+I)
# review: new
gtk-format-underline = Sublinhado (Ctrl+U)
# review: new
gtk-format-hyperlink = Hiperlink (Ctrl+K)
# review: new
gtk-font = Fonte
# review: new
gtk-show-cc = _Cc
# review: new
gtk-show-bcc = _Bcc
# review: new
gtk-save-tip = Salvar (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+clique para abrir)

## Accounts

# review: new
gtk-plain-warning =
    Sem criptografia, qualquer pessoa que intercepte seu tráfego de rede pode ler sua senha e suas mensagens. Use esta conexão apenas com um servidor no seu próprio computador ou na sua rede local.

    Continuar?
# review: new
gtk-account-name-title = Nome da conta
# review: new
gtk-display-name-title = Nome de exibição
# review: new
gtk-turned-off-why = A opção “{ $button }” está desativada neste computador. { $reason }
# review: new
gtk-turned-off-why-long =
    A opção “{ $button }” está desativada neste computador.

    { $reason }
# review: new
gtk-next = Avançar >
# review: new
gtk-provider-sign-in = Faça login em { $address } no site do provedor ({ $provider }). Sua senha não é compartilhada com o Inbox Classic. Você também pode usar uma senha de app criada nas configurações de segurança da sua conta.
# review: new
gtk-provider-sign-in-apps = Faça login em { $address } no site do provedor ({ $provider }) com um dos seus aplicativos de login (Mais opções de login). Você também pode usar uma senha de app criada nas configurações de segurança da sua conta.
# review: new
gtk-accounts-add = Adicionar...
# review: new
gtk-accounts-properties = Propriedades...
# review: new
gtk-accounts-signature = Assinatura...
# review: new
gtk-accounts-sign-in-apps = Aplicativos de login...

## Sign-in apps

# review: new
gtk-app-server = Servidor { $kind }
# review: new
gtk-app-port = Porta { $kind }
# review: new
gtk-app-security = Segurança { $kind }
# review: new
gtk-issuer-found =
    Página de login: { $page }
    Endpoint do token: { $endpoint }
# review: new
gtk-client-id = ID de cliente
# review: new
gtk-client-secret = Segredo de cliente
# review: new
gtk-scopes = Permissões (scopes)
# review: new
gtk-redirect-uri = URI de redirecionamento
# review: new
gtk-issuer-usable =
    O emissor pode ser usado.

    { $found }
# review: new
gtk-app-built-in = { $app } é integrado. Você só pode alterar se ele é oferecido para contas novas. { $reason }
# review: new
gtk-built-in = { $app } (integrado)
# review: new
gtk-offered-for-new = Oferecido para contas novas
# review: new
gtk-edit-button = Editar...
# review: new
gtk-remove-app-ask = Remover o aplicativo de login { $app } e o segredo de cliente salvo dele?
# review: new
gtk-sign-in-apps-intro = Os aplicativos de login permitem que as contas façam login pelo navegador. Um aplicativo desativado não é oferecido para contas novas; as contas que já o usam continuam funcionando.

## AI agents

# review: new
gtk-agent-it-may = Ações permitidas
# review: new
gtk-agent-accounts = Contas permitidas
# review: new
gtk-never-used = Nunca usado
# review: new
gtk-last-used = Último uso: { $date }
# review: new
gtk-forget-program = Remover este programa?
# review: new
gtk-forget-program-detail = As permissões do programa e o histórico de atividade dos seus agentes serão excluídos. Ele precisará pedir autorização novamente na próxima vez que se conectar.
# review: new
gtk-no-agents-yet = Nenhum agente pediu para usar seu e-mail ainda.
# review: new
gtk-nothing-yet = Ainda nada.

## Preferences

# review: new
gtk-preferences = Preferências
# review: new
gtk-language-subtitle = Idioma do aplicativo e da ajuda
# review: new
gtk-notify-subtitle = Uma notificação quando chegam mensagens novas com a janela em segundo plano

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Cliente de e-mail
# review: new
gtk-desktop-comment = Ler e escrever e-mails: um programa de e-mail rápido e simples
# review: new
gtk-desktop-keywords = e-mail;correio;correio eletrônico;mensagens;caixa de entrada;
# review: new
gtk-metainfo-summary = Um programa de e-mail rápido e simples
# review: new
gtk-metainfo-description = O Inbox Classic lê e escreve e-mails com as pastas à esquerda, as mensagens em cima e a mensagem embaixo, como os programas de e-mail de antigamente. Funciona com qualquer conta IMAP e SMTP e faz login no Outlook.com e no Microsoft 365 pelo navegador.
# review: new
gtk-metainfo-feature-sanitized = Cada mensagem é mostrada limpa, sem scripts, e as imagens da internet só quando você permitir
# review: new
gtk-metainfo-feature-search = Uma pesquisa que encontra palavras no assunto, nas pessoas, nos nomes dos arquivos e no texto, com os operadores do Gmail
# review: new
gtk-metainfo-feature-replies = As respostas recolhem as mensagens anteriores que citam
# review: new
gtk-metainfo-feature-offline = Os e-mails continuam legíveis offline; as senhas ficam armazenadas no seu chaveiro
