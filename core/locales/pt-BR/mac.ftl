# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.
# Português do Brasil: maiúscula só na primeira palavra, como no macOS em português do Brasil.

## The app and its menus

# review: new
mac-quit = Sair do Inbox Classic
# review: new
mac-settings = Ajustes…
# review: new
mac-services = Serviços
# review: new
mac-hide = Ocultar Inbox Classic
# review: new
mac-hide-others = Ocultar outros
# review: new
mac-show-all = Mostrar tudo
# review: new
mac-check-updates = Buscar atualizações…
# review: new
mac-close-window = Fechar janela
# review: new
mac-redo = Refazer
# review: new
mac-cut = Cortar
# review: new
mac-paste = Colar
# review: new
mac-menu-window = Janela
# review: new
mac-minimize = Minimizar
# review: new
mac-zoom = Zoom
# review: new
mac-no-updates = Esta versão do Inbox Classic não suporta atualizações automáticas. Baixe a versão mais recente em inboxclassic.com.

## Settings

# review: new
mac-settings-title = Ajustes
# review: new
mac-check-updates-automatically = Buscar atualizações automaticamente
# review: new
mac-settings-updates = Atualizações

## Dialogs

# review: new
mac-choose = Escolher

## The main window

# review: new
mac-still-running-detail = O Inbox Classic continua verificando se há e-mails novos em segundo plano. Clique no ícone dele no Dock para abrir o aplicativo.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } mensagem na Caixa de Saída
       *[other] { $count } mensagens na Caixa de Saída
    }
# review: new
mac-sending = Enviando { $subject }…
# review: new
mac-checking = Verificando se há mensagens novas em { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Esta cópia do Inbox Classic não é um pacote de aplicativo, por isso não pode ser o aplicativo de e-mail padrão.
# review: new
mac-not-made-default = O Inbox Classic não foi definido como aplicativo de e-mail padrão: { $reason }
# review: new
mac-tool-search = Pesquisar

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] O texto de { $count } mensagem ainda está sendo indexado, por isso mais resultados podem aparecer em breve.
       *[other] O texto de { $count } mensagens ainda está sendo indexado, por isso mais resultados podem aparecer em breve.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Nenhum resultado para “{ $words }” em todas as pastas
        [one] { $count } resultado para “{ $words }” em todas as pastas
       *[other] { $count } resultados para “{ $words }” em todas as pastas
    }
# review: new
mac-results-in =
    { $count ->
        [0] Nenhum resultado para “{ $words }” em { $folder }
        [one] { $count } resultado para “{ $words }” em { $folder }
       *[other] { $count } resultados para “{ $words }” em { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] ainda indexando o texto de { $count } mensagem
       *[other] ainda indexando o texto de { $count } mensagens
    }
# review: new
mac-folder-unread = { $folder }, { $count } não lidas
# review: new
mac-import-messages = Importar mensagens
# review: new
mac-save-messages = Salvar mensagens
# review: new
mac-save-attachments-menu = Salvar anexos…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Não foi possível salvar { $failed } dos { $count } arquivos.
    }
# review: new
mac-no-calendar-app = Não há nenhum aplicativo de calendário neste Mac para abrir convites (arquivos .ics).
# review: new
mac-file-not-saved = Não foi possível salvar o arquivo.
# review: new
mac-unsubscribing = Cancelando a inscrição em { $target }…
# review: new
mac-loading-list = Carregando…

## The compose window

# review: new
mac-bold = Negrito
# review: new
mac-italic = Itálico
# review: new
mac-underline = Sublinhado
# review: new
mac-bcc = Bcc
# review: new
mac-command-click-to-open = ⌘-clique para abrir
# review: new
mac-saving-to-drafts = Salvando em Rascunhos…
# review: new
mac-dont-save = Não salvar

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } arquivo
       *[other] { $count } arquivos
    }

## Accounts

# review: new
mac-next = Continuar
# review: new
mac-name-placeholder = Ana Silva
# review: new
mac-more-sign-in-options = Mais opções de login…
# review: new
mac-add-sign-in-app = Adicionar um aplicativo de login…
# review: new
mac-looking-up = Procurando as configurações de { $domain }…
# review: new
mac-add-button = Adicionar…
# review: new
mac-properties-button = Propriedades…
# review: new
mac-signature-button = Assinatura…
# review: new
mac-security-button = Segurança…
# review: new
mac-sign-in-apps-button = Aplicativos de login…

## AI agents

# review: new
mac-forget-program = Remover este programa e o histórico de atividade dos seus agentes?
# review: new
mac-forget-program-detail = As permissões do programa serão excluídas. Ele precisará pedir autorização novamente na próxima vez que se conectar.

## Sign-in apps

# review: new
mac-checking-issuer = Verificando { $issuer }…
# review: new
mac-edit-button = Editar…
# review: new
mac-use-for-new-accounts = Usar { $name } para contas novas
# review: new
mac-built-in = { $name } (integrado)

## Other windows

# review: new
mac-new-folder-button = Nova pasta…
# review: new
mac-edit-link = Editar link…
