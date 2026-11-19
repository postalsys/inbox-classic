# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, curly quotes. The macOS menus of the system use the familiar imperative
# ("Ieși din", "Ascunde"), as macOS in Romanian does.

## The app and its menus

mac-quit = Ieși din Inbox Classic
mac-settings = Configurări…
mac-services = Servicii
mac-hide = Ascunde Inbox Classic
mac-hide-others = Ascunde celelalte
mac-show-all = Afișează tot
mac-check-updates = Caută actualizări…
mac-close-window = Închide fereastra
mac-redo = Refă
mac-cut = Taie
mac-paste = Lipește
mac-menu-window = Fereastră
mac-minimize = Minimizează
mac-zoom = Zoom
mac-no-updates = Această versiune de Inbox Classic nu acceptă actualizări automate. Descărcați cea mai recentă versiune de pe inboxclassic.com.

## Settings

mac-settings-title = Configurări
mac-check-updates-automatically = Caută automat actualizări
mac-settings-updates = Actualizări

## Dialogs

mac-choose = Alegere

## The main window

mac-still-running-detail = Inbox Classic caută în continuare mesaje noi în fundal. Faceți clic pe pictograma aplicației din Dock pentru a o deschide.
mac-outbox-waiting = { $count ->
        [one] { $count } mesaj în folderul „Mesaje de trimis”
        [few] { $count } mesaje în folderul „Mesaje de trimis”
       *[other] { $count } de mesaje în folderul „Mesaje de trimis”
    }
mac-sending = Se trimite mesajul { $subject }…
mac-checking = Se caută mesaje noi în contul „{ $account }”…
mac-account-said = { $account }: { $message }
mac-not-bundle = Această copie a aplicației Inbox Classic nu este un pachet de aplicație, așa că nu poate fi setată ca aplicație de e-mail implicită.
mac-not-made-default = Inbox Classic nu a fost setat ca aplicație de e-mail implicită: { $reason }
mac-tool-search = Căutare

## The folders and the message list

mac-still-indexing-more = { $count ->
        [one] Textul unui mesaj este încă în curs de indexare, așa că în curând pot apărea mai multe rezultate.
        [few] Textul a { $count } mesaje este încă în curs de indexare, așa că în curând pot apărea mai multe rezultate.
       *[other] Textul a { $count } de mesaje este încă în curs de indexare, așa că în curând pot apărea mai multe rezultate.
    }
mac-results-everywhere =
    { $count ->
        [0] Niciun rezultat pentru „{ $words }” în toate folderele
        [one] { $count } rezultat pentru „{ $words }” în toate folderele
        [few] { $count } rezultate pentru „{ $words }” în toate folderele
       *[other] { $count } de rezultate pentru „{ $words }” în toate folderele
    }
mac-results-in = { $count ->
        [0] Niciun rezultat pentru „{ $words }” în „{ $folder }”
        [one] { $count } rezultat pentru „{ $words }” în „{ $folder }”
        [few] { $count } rezultate pentru „{ $words }” în „{ $folder }”
       *[other] { $count } de rezultate pentru „{ $words }” în „{ $folder }”
    }
mac-still-indexing =
    { $count ->
        [one] se indexează încă textul unui mesaj
        [few] se indexează încă textul a { $count } mesaje
       *[other] se indexează încă textul a { $count } de mesaje
    }
mac-folder-unread = { $folder }, necitite: { $count }
mac-import-messages = Import mesaje
mac-save-messages = Salvare mesaje
mac-save-attachments-menu = Salvare atașări…
mac-files-not-saved = Fișiere care nu au putut fi salvate: { $failed } din { $count }.
mac-no-calendar-app = Pe acest Mac nu există nicio aplicație de calendar care să deschidă invitații (fișiere .ics).
mac-file-not-saved = Fișierul nu a putut fi salvat.
mac-unsubscribing = Se face dezabonarea de la { $target }…
mac-loading-list = Se încarcă…

## The compose window

mac-bold = Aldin
mac-italic = Cursiv
mac-underline = Subliniat
mac-bcc = Bcc
mac-command-click-to-open = ⌘-clic pentru deschidere
mac-saving-to-drafts = Se salvează în folderul „Schițe”…
mac-dont-save = Nu salva

## The reading pane

mac-files =
    { $count ->
        [one] { $count } fișier
        [few] { $count } fișiere
       *[other] { $count } de fișiere
    }

## Accounts

mac-next = Următorul
mac-name-placeholder = Ana Popescu
mac-more-sign-in-options = Mai multe opțiuni de conectare…
mac-add-sign-in-app = Adăugare aplicație de conectare…
mac-looking-up = Se caută setările pentru { $domain }…
mac-add-button = Adăugare…
mac-properties-button = Proprietăți…
mac-signature-button = Textul semnăturii…
mac-security-button = Securitate…
mac-sign-in-apps-button = Aplicații de conectare…

## AI agents

mac-forget-program = Eliminați programul din această listă și ștergeți istoricul activității agenților săi?
mac-forget-program-detail = Permisiunile programului vor fi șterse. Vi se va cere din nou permisiunea la următoarea conectare.

## Sign-in apps

mac-checking-issuer = Se verifică { $issuer }…
mac-edit-button = Editare…
mac-use-for-new-accounts = Folosire { $name } pentru conturile noi
mac-built-in = { $name } (integrată)

## Other windows

mac-new-folder-button = Folder nou…
mac-edit-link = Editare link…
