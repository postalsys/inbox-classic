# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = O Inbox Classic continua a verificar se há correio novo em segundo plano. Clique no ícone para o abrir. Para sair, clique com o botão direito do rato no ícone e use o respetivo menu.
win-default-app-not-installed = Esta cópia do Inbox Classic não foi instalada, por isso o Windows não a apresenta como aplicação de correio. Instale-a para a poder escolher.
win-default-app-settings = O Windows vai abrir as definições de Aplicações predefinidas. Escolha o Inbox Classic para abrir as ligações MAILTO.
win-no-unread = Não há mensagens não lidas
win-unread-messages = { $count ->
    [0] Não há mensagens não lidas
    [one] { $count } mensagem não lida
   *[other] { $count } mensagens não lidas
}
win-print-failed = Não foi possível imprimir a mensagem.
win-print-title-of = Imprimir - { $subject }
win-no-bodies = Não é possível mostrar o conteúdo das mensagens.
win-webview-failed = Não foi possível inicializar o WebView2.
win-webview-missing = O runtime do WebView2 não está disponível.
win-list-loading = A carregar...

## Buttons and words used in many windows

win-delete-button = &Eliminar
win-find-label = &Localizar:
win-save-as-button = Guardar &como...
win-too-many-files = Demasiados ficheiros de uma vez: escolha menos.

## The Outbox


## The compose window

win-editor-failed = Não é possível escrever mensagens.
win-ctrl-click-to-open = ({ $ctrl }+clique para abrir)
win-format-bold = Negrito ({ $ctrl }+B)
win-format-italic = Itálico ({ $ctrl }+I)
win-format-underline = Sublinhado ({ $ctrl }+U)
win-format-link = Hiperligação ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature-title = Assinatura: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Nenhum resultado para «{ $words }» em todas as pastas
    [one] { $count } resultado para «{ $words }» em todas as pastas
   *[other] { $count } resultados para «{ $words }» em todas as pastas
}
win-search-found-in = { $count ->
    [0] Nenhum resultado para «{ $words }» em { $folder }
    [one] { $count } resultado para «{ $words }» em { $folder }
   *[other] { $count } resultados para «{ $words }» em { $folder }
}
win-search-indexing = { $count ->
    [one] ainda a indexar o texto de { $count } mensagem
   *[other] ainda a indexar o texto de { $count } mensagens
}
win-no-match-indexing = { $count ->
    [one] O texto de { $count } mensagem ainda está a ser indexado, por isso poderão surgir mais resultados em breve.
   *[other] O texto de { $count } mensagens ainda está a ser indexado, por isso poderão surgir mais resultados em breve.
}
win-files = { $count ->
    [one] { $count } ficheiro
   *[other] { $count } ficheiros
}
win-save-attachments = &Guardar anexos...
win-files-not-saved = Ficheiros não guardados: { $failed } de { $count }.
win-new-folder-in-highlighted = A nova pasta será criada dentro da pasta selecionada.
win-delete-folder-ask = Eliminar a pasta «{ $folder }» com as respetivas mensagens e as pastas que contém? Também será eliminada no servidor.
win-rename = &Mudar o nome...
win-messages-not-saved = Não foi possível guardar as mensagens.
win-messages-not-forwarded = Não foi possível reencaminhar as mensagens.

## Accounts

win-sign-in-google = Iniciar sessão com o Google
win-sign-in-microsoft = Iniciar sessão com a Microsoft
win-next = &Seguinte >
win-your-account = a sua conta
win-browser-sign-in = (início de sessão no browser)
win-add = A&dicionar...
win-properties-button = &Propriedades...
win-signature-button = &Assinatura...
win-sign-in-apps-button = Aplicações de &início de sessão...

## AI agents

win-dont-allow = &Não permitir
win-col-address = Endereço
win-never-written-to = Nenhuma mensagem enviada
win-book-find-label = Escreva um nome ou endereço de e-mail:
win-send = &Enviar
win-dont-send = &Não enviar
win-unsubscribe = &Cancelar subscrição
win-dont-unsubscribe = &Não cancelar subscrição
win-forget-program-ask = Remover este programa da lista, as respetivas permissões e o histórico de atividade dos seus agentes? Será pedida novamente autorização da próxima vez que se ligar.
win-clear-log-ask = Limpar o histórico de atividade dos agentes? Isto não anula as alterações feitas pelos agentes.
win-agent-programs = Pro&gramas cujos agentes pediram acesso ao seu correio:
win-change = Alt&erar...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Anular altera&ções...
win-take-back = &Anular alterações
win-what-agents-did = A&tividade dos agentes:
win-agent-reads = O que foi lido das { $from } às { $to }:
win-agent-reads-hint = Selecione acima uma linha de leituras para ver o que foi lido.

## Sign-in apps

win-built-in = (integrada)
win-edit = &Editar...

## Options

win-folders-hide = Ocultar a lista de pastas
win-folders-pin = Manter a lista de pastas ao lado das mensagens
win-folders-show = Mostrar as pastas

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Iniciar o Inbox Classic
win-installer-welcome-new =
    Este assistente vai instalar o Inbox Classic { $version }, um programa de correio eletrónico.

    Não são necessários privilégios de administrador: a instalação destina-se apenas à sua conta de utilizador do Windows.
win-installer-welcome-same =
    O Inbox Classic { $version } já está instalado. Este assistente vai instalá-lo novamente.

    As suas contas e o seu correio serão preservados.
win-installer-welcome-update =
    Este assistente vai atualizar o Inbox Classic { $installed } para a versão { $version }.

    Se estiver em execução, será fechado antes da atualização. As suas contas e o seu correio serão preservados.
win-installer-older-ask = Está instalado o Inbox Classic { $installed }, que é mais recente do que { $version }. Instalar mesmo assim a versão mais antiga?
win-installer-still-running = O Inbox Classic continua em execução. Feche-o e tente novamente.
win-installer-remove-mail-ask = Remover também todos os dados locais do Inbox Classic, incluindo contas, mensagens, contactos, regras e chaves? O correio nos servidores e as credenciais no armazenamento do sistema mantêm-se.
