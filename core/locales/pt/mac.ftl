# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.
# Português europeu: maiúscula só na primeira palavra, como no macOS em português.

## The app and its menus

# review: new
mac-quit = Sair do Inbox Classic
# review: new
mac-settings = Definições…
# review: new
mac-services = Serviços
# review: new
mac-hide = Ocultar Inbox Classic
# review: new
mac-hide-others = Ocultar outros
# review: new
mac-show-all = Mostrar tudo
# review: new
mac-check-updates = Procurar atualizações…
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
mac-no-updates = Esta versão do Inbox Classic não suporta atualizações automáticas. Transfira a versão mais recente em inboxclassic.com.

## Settings

# review: new
mac-settings-title = Definições
# review: new
mac-language-label = Idioma:
# review: new
mac-restart-hint = Reinicie o Inbox Classic para mudar o idioma.
# review: new
mac-notify-new-mail = Notificar-me quando chegar correio novo
# review: new
mac-restart-question = Reiniciar agora o Inbox Classic para mudar o idioma?

## Dialogs

# review: new
mac-choose = Escolher

## The main window

# review: new
mac-still-running-detail = O Inbox Classic continua a verificar se há correio novo em segundo plano. Clique no respetivo ícone na Dock para abrir a aplicação.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } mensagem na Caixa de Saída
       *[other] { $count } mensagens na Caixa de Saída
    }
# review: new
mac-sending = A enviar { $subject }…
# review: new
mac-checking = A verificar se há mensagens novas em { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Esta cópia do Inbox Classic não é um pacote de aplicação, por isso não pode ser a aplicação de correio predefinida.
# review: new
mac-not-made-default = O Inbox Classic não foi definido como aplicação de correio predefinida: { $reason }
# review: new
mac-tool-search = Pesquisar

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] O texto de { $count } mensagem ainda está a ser indexado, por isso poderão ser encontradas mais em breve.
       *[other] O texto de { $count } mensagens ainda está a ser indexado, por isso poderão ser encontradas mais em breve.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Nenhum resultado para «{ $words }» em todas as pastas
        [one] { $count } resultado para «{ $words }» em todas as pastas
       *[other] { $count } resultados para «{ $words }» em todas as pastas
    }
# review: new
mac-results-in =
    { $count ->
        [0] Nenhum resultado para «{ $words }» em { $folder }
        [one] { $count } resultado para «{ $words }» em { $folder }
       *[other] { $count } resultados para «{ $words }» em { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] ainda a indexar o texto de { $count } mensagem
       *[other] ainda a indexar o texto de { $count } mensagens
    }
# review: new
mac-folder-unread = { $folder }, { $count } não lidas
# review: new
mac-import-messages = Importar mensagens
# review: new
mac-save-messages = Guardar mensagens
# review: new
mac-save-attachments-menu = Guardar anexos…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Não foi possível guardar { $failed } dos { $count } ficheiros.
    }
# review: new
mac-no-calendar-app = Não há nenhuma aplicação de calendário neste Mac para abrir convites (ficheiros .ics).
# review: new
mac-file-not-saved = Não foi possível guardar o ficheiro.
# review: new
mac-unsubscribing = A cancelar a subscrição de { $target }…
# review: new
mac-loading-list = A carregar…

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
mac-saving-to-drafts = A guardar em Rascunhos…
# review: new
mac-dont-save = Não guardar

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } ficheiro
       *[other] { $count } ficheiros
    }

## Accounts

# review: new
mac-next = Seguinte
# review: new
mac-name-placeholder = Ana Silva
# review: new
mac-more-sign-in-options = Mais opções de início de sessão…
# review: new
mac-add-sign-in-app = Adicionar uma aplicação de início de sessão…
# review: new
mac-looking-up = A procurar as definições de { $domain }…
# review: new
mac-add-button = Adicionar…
# review: new
mac-properties-button = Propriedades…
# review: new
mac-signature-button = Assinatura…
# review: new
mac-security-button = Segurança…
# review: new
mac-sign-in-apps-button = Aplicações de início de sessão…

## AI agents

# review: new
mac-forget-program = Remover este programa e o histórico de atividade dos seus agentes?
# review: new
mac-forget-program-detail = As permissões do programa serão eliminadas. Será pedida novamente autorização da próxima vez que se ligar.

## Sign-in apps

# review: new
mac-checking-issuer = A verificar { $issuer }…
# review: new
mac-edit-button = Editar…
# review: new
mac-use-for-new-accounts = Usar { $name } para contas novas
# review: new
mac-built-in = { $name } (integrada)

## Other windows

# review: new
mac-new-folder-button = Nova pasta…
# review: new
mac-edit-link = Editar ligação…
