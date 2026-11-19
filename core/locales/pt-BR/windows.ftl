# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = O Inbox Classic continua verificando se há e-mails novos em segundo plano. Clique no ícone para abri-lo. Para sair, clique no ícone com o botão direito do mouse e use o menu dele.
win-default-app-not-installed = Esta cópia do Inbox Classic não foi instalada, por isso o Windows não a mostra como aplicativo de e-mail. Instale-a para poder escolhê-la.
win-default-app-settings = O Windows vai abrir as configurações de Aplicativos padrão. Escolha o Inbox Classic para abrir os links MAILTO.
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
win-list-loading = Carregando...

## Buttons and words used in many windows

win-delete-button = E&xcluir
win-find-label = &Localizar:
win-save-as-button = &Salvar como...
win-too-many-files = Você selecionou arquivos demais. Selecione menos arquivos e tente novamente.

## The Outbox


## The compose window

win-editor-failed = Não é possível escrever mensagens.
win-ctrl-click-to-open = ({ $ctrl }+clique para abrir)
win-format-bold = Negrito ({ $ctrl }+B)
win-format-italic = Itálico ({ $ctrl }+I)
win-format-underline = Sublinhado ({ $ctrl }+U)
win-format-link = Hiperlink ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = Cc&o
win-signature-title = Assinatura: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Nenhum resultado para “{ $words }” em todas as pastas
    [one] { $count } resultado para “{ $words }” em todas as pastas
   *[other] { $count } resultados para “{ $words }” em todas as pastas
}
win-search-found-in = { $count ->
    [0] Nenhum resultado para “{ $words }” em { $folder }
    [one] { $count } resultado para “{ $words }” em { $folder }
   *[other] { $count } resultados para “{ $words }” em { $folder }
}
win-search-indexing = { $count ->
    [one] ainda indexando o texto de { $count } mensagem
   *[other] ainda indexando o texto de { $count } mensagens
}
win-no-match-indexing = { $count ->
    [one] O texto de { $count } mensagem ainda está sendo indexado, por isso mais resultados podem aparecer em breve.
   *[other] O texto de { $count } mensagens ainda está sendo indexado, por isso mais resultados podem aparecer em breve.
}
win-files = { $count ->
    [one] { $count } arquivo
   *[other] { $count } arquivos
}
win-click-to-retry = Clique aqui para tentar novamente.
win-save-attachments = &Salvar anexos...
win-files-not-saved = Arquivos que não foi possível salvar: { $failed } de { $count }.
win-new-folder-in-highlighted = A nova pasta será criada dentro da pasta selecionada.
win-delete-folder-ask = Excluir a pasta “{ $folder }” com as mensagens e as pastas que ela contém? Ela também será excluída no servidor.
win-rename = &Renomear...
win-messages-not-saved = Não foi possível salvar as mensagens.
win-messages-not-forwarded = Não foi possível encaminhar as mensagens.

## Accounts

win-sign-in-google = Fazer login com o Google
win-sign-in-microsoft = Entrar com a Microsoft
win-next = &Avançar >
win-your-account = sua conta
win-browser-sign-in = (login no navegador)
win-add = A&dicionar...
win-properties-button = &Propriedades...
win-signature-button = &Assinatura...
win-sign-in-apps-button = Aplicativos de &login...

## AI agents

win-dont-allow = &Não permitir
win-col-address = Endereço
win-never-written-to = Nenhuma mensagem enviada
win-book-find-label = Digite um nome ou endereço de e-mail:
win-send = &Enviar
win-dont-send = &Não enviar
win-unsubscribe = &Cancelar inscrição
win-dont-unsubscribe = &Não cancelar inscrição
win-forget-program-ask = Remover este programa da lista, suas permissões e o histórico de atividade dos agentes? Na próxima conexão, você precisará autorizar o acesso novamente.
win-clear-log-ask = Limpar o histórico de atividade dos agentes? Isso não desfaz as alterações feitas pelos agentes.
win-agent-programs = Pro&gramas cujos agentes pediram acesso ao seu e-mail:
win-change = &Alterar...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Desfazer de&sde...
win-take-back = &Desfazer
win-what-agents-did = A&tividade dos agentes:
win-agent-reads = O que foi lido das { $from } às { $to }:
win-agent-reads-hint = Selecione acima uma linha de leituras para ver o que foi lido.
win-how-to-connect = Como conectar um agente

## Sign-in apps

win-built-in = (integrado)
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
    Este assistente vai instalar o Inbox Classic { $version }, um programa de e-mail.

    Não são necessárias permissões de administrador: a instalação vale apenas para sua conta de usuário do Windows.
win-installer-welcome-same =
    O Inbox Classic { $version } já está instalado. Este assistente vai instalá-lo novamente.

    Suas contas e seus e-mails serão mantidos.
win-installer-welcome-update =
    Este assistente vai atualizar o Inbox Classic { $installed } para a versão { $version }.

    Se estiver em execução, ele será fechado antes da atualização. Suas contas e seus e-mails serão mantidos.
win-installer-older-ask = O Inbox Classic { $installed } está instalado, e é mais recente do que { $version }. Instalar a versão mais antiga mesmo assim?
win-installer-still-running = O Inbox Classic continua em execução. Feche-o e tente novamente.
win-installer-remove-mail-ask = Remover também todos os dados locais do Inbox Classic, incluindo contas, e-mails, contatos, chaves e configurações? Os e-mails nos servidores são mantidos. As credenciais no armazenamento do sistema podem permanecer.
