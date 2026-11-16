# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.
# Português europeu: maiúscula só na primeira palavra, como no macOS em português.

## The app and its menus

mac-quit = Sair do Inbox Classic
mac-settings = Definições…
mac-services = Serviços
mac-hide = Ocultar Inbox Classic
mac-hide-others = Ocultar outros
mac-show-all = Mostrar tudo
mac-check-updates = Procurar atualizações…
mac-close-window = Fechar janela
mac-redo = Refazer
mac-cut = Cortar
mac-paste = Colar
mac-menu-window = Janela
mac-minimize = Minimizar
mac-zoom = Zoom
mac-no-updates = Esta versão do Inbox Classic não suporta atualizações automáticas. Transfira a versão mais recente em inboxclassic.com.

## Settings

mac-settings-title = Definições
mac-language-label = Idioma:
mac-restart-hint = Reinicie o Inbox Classic para mudar o idioma.
mac-notify-new-mail = Notificar-me quando chegar correio novo
mac-restart-question = Reiniciar agora o Inbox Classic para mudar o idioma?

## Dialogs

mac-choose = Escolher

## The main window

mac-still-running-detail = O Inbox Classic continua a verificar se há correio novo em segundo plano. Clique no respetivo ícone na Dock para abrir a aplicação.
mac-outbox-waiting =
    { $count ->
        [one] { $count } mensagem na Caixa de Saída
       *[other] { $count } mensagens na Caixa de Saída
    }
mac-sending = A enviar { $subject }…
mac-checking = A verificar se há mensagens novas em { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Esta cópia do Inbox Classic não está num pacote de aplicação (.app), por isso não pode ser definida como aplicação de correio predefinida.
mac-not-made-default = O Inbox Classic não foi definido como aplicação de correio predefinida: { $reason }
mac-tool-search = Pesquisar

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] O texto de { $count } mensagem ainda está a ser indexado, por isso poderão surgir mais resultados em breve.
       *[other] O texto de { $count } mensagens ainda está a ser indexado, por isso poderão surgir mais resultados em breve.
    }
mac-results-everywhere =
    { $count ->
        [0] Nenhum resultado para «{ $words }» em todas as pastas
        [one] { $count } resultado para «{ $words }» em todas as pastas
       *[other] { $count } resultados para «{ $words }» em todas as pastas
    }
mac-results-in =
    { $count ->
        [0] Nenhum resultado para «{ $words }» em { $folder }
        [one] { $count } resultado para «{ $words }» em { $folder }
       *[other] { $count } resultados para «{ $words }» em { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] ainda a indexar o texto de { $count } mensagem
       *[other] ainda a indexar o texto de { $count } mensagens
    }
mac-folder-unread = { $folder }, { $count } por ler
mac-import-messages = Importar mensagens
mac-save-messages = Guardar mensagens
mac-save-attachments-menu = Guardar anexos…
mac-files-not-saved =
    { $count ->
       *[other] Ficheiros não guardados: { $failed } de { $count }.
    }
mac-no-calendar-app = Não há nenhuma aplicação de calendário neste Mac para abrir convites (ficheiros .ics).
mac-file-not-saved = Não foi possível guardar o ficheiro.
mac-unsubscribing = A cancelar a subscrição de { $target }…

## The compose window

mac-bold = Negrito
mac-italic = Itálico
mac-underline = Sublinhado
mac-bcc = Bcc
mac-command-click-to-open = ⌘-clique para abrir
mac-saving-to-drafts = A guardar em Rascunhos…
mac-dont-save = Não guardar

## The reading pane

mac-files =
    { $count ->
        [one] { $count } ficheiro
       *[other] { $count } ficheiros
    }

## Accounts

mac-next = Seguinte
mac-name-placeholder = Ana Silva
mac-more-sign-in-options = Mais opções de início de sessão…
mac-add-sign-in-app = Adicionar uma aplicação de início de sessão…
mac-looking-up = A procurar as definições de { $domain }…
mac-add-button = Adicionar…
mac-properties-button = Propriedades…
mac-signature-button = Assinatura…
mac-security-button = Segurança…
mac-sign-in-apps-button = Aplicações de início de sessão…

## AI agents

mac-forget-program = Remover este programa e o histórico de atividade dos seus agentes?
mac-forget-program-detail = As permissões do programa serão eliminadas. Será pedida novamente autorização da próxima vez que se ligar.

## Sign-in apps

mac-checking-issuer = A verificar { $issuer }…
mac-edit-button = Editar…
mac-use-for-new-accounts = Usar { $name } para contas novas
mac-built-in = { $name } (integrada)

## Other windows

mac-new-folder-button = Nova pasta…
mac-edit-link = Editar ligação…
