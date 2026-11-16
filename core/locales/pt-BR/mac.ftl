# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.
# Português do Brasil: maiúscula só na primeira palavra, como no macOS em português do Brasil.

## The app and its menus

mac-quit = Sair do Inbox Classic
mac-settings = Ajustes…
mac-services = Serviços
mac-hide = Ocultar Inbox Classic
mac-hide-others = Ocultar outros
mac-show-all = Mostrar tudo
mac-check-updates = Buscar atualizações…
mac-close-window = Fechar janela
mac-redo = Refazer
mac-cut = Cortar
mac-paste = Colar
mac-menu-window = Janela
mac-minimize = Minimizar
mac-zoom = Zoom
mac-no-updates = Esta versão do Inbox Classic não suporta atualizações automáticas. Baixe a versão mais recente em inboxclassic.com.

## Settings

mac-settings-title = Ajustes
mac-language-label = Idioma:
mac-restart-hint = Reinicie o Inbox Classic para mudar o idioma.
mac-notify-new-mail = Notificar quando chegarem e-mails novos
mac-restart-question = Reiniciar agora o Inbox Classic para mudar o idioma?

## Dialogs

mac-choose = Escolher

## The main window

mac-still-running-detail = O Inbox Classic continua verificando se há e-mails novos em segundo plano. Clique no ícone dele no Dock para abrir o aplicativo.
mac-outbox-waiting =
    { $count ->
        [one] { $count } mensagem na Caixa de Saída
       *[other] { $count } mensagens na Caixa de Saída
    }
mac-sending = Enviando { $subject }…
mac-checking = Verificando se há mensagens novas em { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Esta cópia do Inbox Classic não está em um pacote .app do macOS e não pode ser definida como aplicativo de e-mail padrão.
mac-not-made-default = O Inbox Classic não foi definido como aplicativo de e-mail padrão: { $reason }
mac-tool-search = Pesquisar

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] O texto de { $count } mensagem ainda está sendo indexado, por isso mais resultados podem aparecer em breve.
       *[other] O texto de { $count } mensagens ainda está sendo indexado, por isso mais resultados podem aparecer em breve.
    }
mac-results-everywhere =
    { $count ->
        [0] Nenhum resultado para “{ $words }” em todas as pastas
        [one] { $count } resultado para “{ $words }” em todas as pastas
       *[other] { $count } resultados para “{ $words }” em todas as pastas
    }
mac-results-in =
    { $count ->
        [0] Nenhum resultado para “{ $words }” em { $folder }
        [one] { $count } resultado para “{ $words }” em { $folder }
       *[other] { $count } resultados para “{ $words }” em { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] ainda indexando o texto de { $count } mensagem
       *[other] ainda indexando o texto de { $count } mensagens
    }
mac-folder-unread = { $folder }, não lidas: { $count }
mac-import-messages = Importar mensagens
mac-save-messages = Salvar mensagens
mac-save-attachments-menu = Salvar anexos…
mac-files-not-saved =
    { $count ->
       *[other] Arquivos que não foi possível salvar: { $failed } de { $count }.
    }
mac-no-calendar-app = Não há nenhum aplicativo de calendário neste Mac para abrir convites (arquivos .ics).
mac-file-not-saved = Não foi possível salvar o arquivo.
mac-unsubscribing = Cancelando a inscrição em { $target }…

## The compose window

mac-bold = Negrito
mac-italic = Itálico
mac-underline = Sublinhado
mac-bcc = Cco
mac-command-click-to-open = ⌘-clique para abrir
mac-saving-to-drafts = Salvando em Rascunhos…
mac-dont-save = Não salvar

## The reading pane

mac-files =
    { $count ->
        [one] { $count } arquivo
       *[other] { $count } arquivos
    }

## Accounts

mac-next = Continuar
mac-name-placeholder = Ana Silva
mac-more-sign-in-options = Mais opções de login…
mac-add-sign-in-app = Adicionar um aplicativo de login…
mac-looking-up = Procurando as configurações de { $domain }…
mac-add-button = Adicionar…
mac-properties-button = Propriedades…
mac-signature-button = Assinatura…
mac-security-button = Segurança…
mac-sign-in-apps-button = Aplicativos de login…

## AI agents

mac-forget-program = Remover este programa e o histórico de atividade dos seus agentes?
mac-forget-program-detail = As permissões do programa serão excluídas. Na próxima conexão, você precisará autorizar o acesso novamente.

## Sign-in apps

mac-checking-issuer = Verificando { $issuer }…
mac-edit-button = Editar…
mac-use-for-new-accounts = Usar { $name } para contas novas
mac-built-in = { $name } (integrado)

## Other windows

mac-new-folder-button = Nova pasta…
mac-edit-link = Editar link…
