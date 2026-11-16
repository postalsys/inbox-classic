# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = O Inbox Classic continua verificando se há e-mails novos em segundo plano. Clique no ícone para abri-lo. Para sair, clique no ícone com o botão direito do mouse e use o menu dele.
# review: new
win-default-app-not-installed = Esta cópia do Inbox Classic não foi instalada, por isso o Windows não a mostra como aplicativo de e-mail. Instale-a para poder escolhê-la.
# review: new
win-default-app-settings = O Windows vai abrir as configurações de Aplicativos padrão. Escolha o Inbox Classic para abrir os links MAILTO.
# review: new
win-no-unread = Não há mensagens não lidas
# review: new
win-unread-messages = { $count ->
    [0] Não há mensagens não lidas
    [one] { $count } mensagem não lida
   *[other] { $count } mensagens não lidas
}
# review: new
win-print-failed = Não foi possível imprimir a mensagem.
# review: new
win-print-title-of = Imprimir - { $subject }
# review: new
win-no-bodies = Não é possível mostrar o conteúdo das mensagens.
# review: new
win-webview-failed = Não foi possível criar o WebView2.
# review: new
win-webview-missing = O runtime do WebView2 não está disponível.

## Buttons and words used in many windows

# review: new
win-delete-button = &Excluir
# review: new
win-find-label = &Localizar:
# review: new
win-save-as-button = Salvar &como...
# review: new
win-too-many-files = Arquivos demais de uma vez: escolha menos.

## The Outbox


## The compose window

# review: new
win-editor-failed = Não é possível escrever mensagens.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+clique para abrir)
# review: new
win-format-bold = Negrito ({ $ctrl }+B)
# review: new
win-format-italic = Itálico ({ $ctrl }+I)
# review: new
win-format-underline = Sublinhado ({ $ctrl }+U)
# review: new
win-format-link = Hiperlink ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = &Bcc
# review: new
win-signature-title = Assinatura: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Nenhum resultado para “{ $words }” em todas as pastas
    [one] { $count } resultado para “{ $words }” em todas as pastas
   *[other] { $count } resultados para “{ $words }” em todas as pastas
}
# review: new
win-search-found-in = { $count ->
    [0] Nenhum resultado para “{ $words }” em { $folder }
    [one] { $count } resultado para “{ $words }” em { $folder }
   *[other] { $count } resultados para “{ $words }” em { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] ainda indexando o texto de { $count } mensagem
   *[other] ainda indexando o texto de { $count } mensagens
}
# review: new
win-no-match-indexing = { $count ->
    [one] O texto de { $count } mensagem ainda está sendo indexado, por isso mais resultados podem aparecer em breve.
   *[other] O texto de { $count } mensagens ainda está sendo indexado, por isso mais resultados podem aparecer em breve.
}
# review: new
win-files = { $count ->
    [one] { $count } arquivo
   *[other] { $count } arquivos
}
# review: new
win-click-to-retry = Clique aqui para tentar novamente.
# review: new
win-save-attachments = &Salvar anexos...
# review: new
win-files-not-saved = Não foi possível salvar { $failed } dos { $count } arquivos.
# review: new
win-new-folder-in-highlighted = A nova pasta será criada dentro da pasta selecionada.
# review: new
win-delete-folder-ask = Excluir a pasta “{ $folder }” com as mensagens e as pastas que ela contém? Ela também será excluída no servidor.
# review: new
win-rename = &Renomear...
# review: new
win-messages-not-saved = Não foi possível salvar as mensagens.
# review: new
win-messages-not-forwarded = Não foi possível encaminhar as mensagens.

## Accounts

# review: new
win-sign-in-google = Fazer login com o Google
# review: new
win-sign-in-microsoft = Entrar com a Microsoft
# review: new
win-next = &Avançar >
# review: new
win-your-account = sua conta
# review: new
win-browser-sign-in = (login no navegador)
# review: new
win-add = A&dicionar...
# review: new
win-properties-button = &Propriedades...
# review: new
win-signature-button = &Assinatura...
# review: new
win-sign-in-apps-button = Aplicativos de &login...

## AI agents

# review: new
win-dont-allow = &Não permitir
# review: new
win-col-address = Endereço
# review: new
win-never-written-to = Você nunca escreveu para
# review: new
win-book-find-label = Digite um nome ou endereço de e-mail:
# review: new
win-send = &Enviar
# review: new
win-dont-send = &Não enviar
# review: new
win-forget-program-ask = Remover este programa, as permissões dele e o histórico de atividade dos seus agentes? Ele precisará pedir autorização novamente na próxima vez que se conectar.
# review: new
win-clear-log-ask = Limpar o histórico de atividade dos agentes? Isso não desfaz as alterações feitas pelos agentes.
# review: new
win-agent-programs = &Programas cujos agentes pediram acesso ao seu e-mail:
# review: new
win-change = &Alterar...
# review: new
win-what-agents-did = A&tividade dos agentes:
# review: new
win-how-to-connect = Como conectar um agente

## Sign-in apps

# review: new
win-built-in = (integrado)
# review: new
win-edit = &Editar...

## Options

# review: new
win-options-language-label = &Mostrar o Inbox Classic em:
# review: new
win-options-restart-note = Reinicie o Inbox Classic para mudar o idioma.
# review: new
win-options-notify = &Notificar quando chegarem e-mails novos
# review: new
win-restart-ask = O Inbox Classic mostra { $language } depois de reiniciar. Reiniciar agora?
# review: new
win-folders-hide = Ocultar a lista de pastas
# review: new
win-folders-pin = Manter a lista de pastas ao lado das mensagens
# review: new
win-folders-show = Mostrar as pastas

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Iniciar o Inbox Classic
# review: new
win-installer-welcome-new =
    Este assistente vai instalar o Inbox Classic { $version }, um programa de e-mail.

    Não são necessários direitos de administrador: ele é instalado apenas para a sua conta.
# review: new
win-installer-welcome-same =
    O Inbox Classic { $version } já está instalado. Este assistente vai instalá-lo novamente.

    Suas contas e seus e-mails são mantidos.
# review: new
win-installer-welcome-update =
    Este assistente vai atualizar o Inbox Classic { $installed } para a versão { $version }.

    Se estiver em execução, ele é fechado primeiro. Suas contas e seus e-mails são mantidos.
# review: new
win-installer-older-ask = O Inbox Classic { $installed } está instalado, e é mais recente do que { $version }. Instalar a versão mais antiga mesmo assim?
# review: new
win-installer-still-running = O Inbox Classic continua em execução. Feche-o e tente novamente.
# review: new
win-installer-remove-mail-ask = Remover também as contas e os e-mails que o Inbox Classic armazena neste computador? Os e-mails nos servidores são mantidos.
