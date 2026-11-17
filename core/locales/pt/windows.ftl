# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = O Inbox Classic continua a verificar se há correio novo em segundo plano. Clique no ícone para o abrir. Para sair, clique com o botão direito do rato no ícone e use o respetivo menu.
# review: new
win-default-app-not-installed = Esta cópia do Inbox Classic não foi instalada, por isso o Windows não a apresenta como aplicação de correio. Instale-a para a poder escolher.
# review: new
win-default-app-settings = O Windows vai abrir as definições de Aplicações predefinidas. Escolha o Inbox Classic para abrir as ligações MAILTO.
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
# review: new
win-list-loading = A carregar...

## Buttons and words used in many windows

# review: new
win-delete-button = &Eliminar
# review: new
win-find-label = &Localizar:
# review: new
win-save-as-button = Guardar &como...
# review: new
win-too-many-files = Demasiados ficheiros de uma vez: escolha menos.

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
win-format-link = Hiperligação ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = &Bcc
# review: new
win-signature-title = Assinatura: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Nenhum resultado para «{ $words }» em todas as pastas
    [one] { $count } resultado para «{ $words }» em todas as pastas
   *[other] { $count } resultados para «{ $words }» em todas as pastas
}
# review: new
win-search-found-in = { $count ->
    [0] Nenhum resultado para «{ $words }» em { $folder }
    [one] { $count } resultado para «{ $words }» em { $folder }
   *[other] { $count } resultados para «{ $words }» em { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] ainda a indexar o texto de { $count } mensagem
   *[other] ainda a indexar o texto de { $count } mensagens
}
# review: new
win-no-match-indexing = { $count ->
    [one] O texto de { $count } mensagem ainda está a ser indexado, por isso poderão ser encontradas mais em breve.
   *[other] O texto de { $count } mensagens ainda está a ser indexado, por isso poderão ser encontradas mais em breve.
}
# review: new
win-files = { $count ->
    [one] { $count } ficheiro
   *[other] { $count } ficheiros
}
# review: new
win-click-to-retry = Clique aqui para tentar novamente.
# review: new
win-save-attachments = &Guardar anexos...
# review: new
win-files-not-saved = Não foi possível guardar { $failed } dos { $count } ficheiros.
# review: new
win-new-folder-in-highlighted = A nova pasta será criada dentro da pasta selecionada.
# review: new
win-delete-folder-ask = Eliminar a pasta «{ $folder }» com as respetivas mensagens e as pastas que contém? Também será eliminada no servidor.
# review: new
win-rename = &Mudar o nome...
# review: new
win-messages-not-saved = Não foi possível guardar as mensagens.
# review: new
win-messages-not-forwarded = Não foi possível reencaminhar as mensagens.

## Accounts

# review: new
win-sign-in-google = Iniciar sessão com o Google
# review: new
win-sign-in-microsoft = Iniciar sessão com a Microsoft
# review: new
win-next = &Seguinte >
# review: new
win-your-account = a sua conta
# review: new
win-browser-sign-in = (início de sessão no browser)
# review: new
win-add = A&dicionar...
# review: new
win-properties-button = &Propriedades...
# review: new
win-signature-button = &Assinatura...
# review: new
win-sign-in-apps-button = Aplicações de &início de sessão...

## AI agents

# review: new
win-dont-allow = &Não permitir
# review: new
win-col-address = Endereço
# review: new
win-never-written-to = Nunca escreveu para
# review: new
win-book-find-label = Escreva um nome ou endereço de e-mail:
# review: new
win-send = &Enviar
# review: new
win-dont-send = &Não enviar
# review: new
win-unsubscribe = &Cancelar subscrição
# review: new
win-dont-unsubscribe = &Não cancelar subscrição
# review: new
win-forget-program-ask = Remover este programa, as respetivas permissões e o histórico de atividade dos seus agentes? Será pedida novamente autorização da próxima vez que se ligar.
# review: new
win-clear-log-ask = Limpar o histórico de atividade dos agentes? Isto não anula as alterações feitas pelos agentes.
# review: new
win-agent-programs = &Programas cujos agentes pediram acesso ao seu correio:
# review: new
win-change = &Alterar...
# review: new
win-what-agents-did = A&tividade dos agentes:
# review: new
win-how-to-connect = Como ligar um agente

## Sign-in apps

# review: new
win-built-in = (integrada)
# review: new
win-edit = &Editar...

## Options

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

    Não são precisos direitos de administrador: é instalado apenas para a sua conta.
# review: new
win-installer-welcome-same =
    O Inbox Classic { $version } já está instalado. Este assistente vai instalá-lo novamente.

    As suas contas e o seu correio são mantidos.
# review: new
win-installer-welcome-update =
    Este assistente vai atualizar o Inbox Classic { $installed } para a versão { $version }.

    Se estiver em execução, é fechado primeiro. As suas contas e o seu correio são mantidos.
# review: new
win-installer-older-ask = Está instalado o Inbox Classic { $installed }, que é mais recente do que { $version }. Instalar mesmo assim a versão mais antiga?
# review: new
win-installer-still-running = O Inbox Classic continua em execução. Feche-o e tente novamente.
# review: new
win-installer-remove-mail-ask = Remover também as contas e o correio que o Inbox Classic guarda neste computador? O correio nos servidores mantém-se.
