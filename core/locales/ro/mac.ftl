# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, curly quotes. The macOS menus of the system use the familiar imperative
# ("Ieși din", "Ascunde"), as macOS in Romanian does.

## The app and its menus

# review: new
mac-quit = Ieși din Inbox Classic
# review: new
mac-settings = Configurări…
# review: new
mac-services = Servicii
# review: new
mac-hide = Ascunde Inbox Classic
# review: new
mac-hide-others = Ascunde celelalte
# review: new
mac-show-all = Afișează tot
# review: new
mac-check-updates = Caută actualizări…
# review: new
mac-close-window = Închide fereastra
# review: new
mac-redo = Refă
# review: new
mac-cut = Taie
# review: new
mac-paste = Lipește
# review: new
mac-menu-window = Fereastră
# review: new
mac-minimize = Minimizează
# review: new
mac-zoom = Zoom
# review: new
mac-no-updates = Această versiune de Inbox Classic nu acceptă actualizări automate. Descărcați cea mai recentă versiune de pe inboxclassic.com.

## Settings

# review: new
mac-settings-title = Configurări
# review: new
mac-check-updates-automatically = Caută automat actualizări
# review: new
mac-settings-updates = Actualizări

## Dialogs

# review: new
mac-choose = Alegere

## The main window

# review: new
mac-still-running-detail = Inbox Classic caută în continuare e-mailuri noi în fundal. Faceți clic pe pictograma lui din Dock pentru a deschide aplicația.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } mesaj în Mesaje de trimis
        [few] { $count } mesaje în Mesaje de trimis
       *[other] { $count } de mesaje în Mesaje de trimis
    }
# review: new
mac-sending = Se trimite { $subject }…
# review: new
mac-checking = Se caută mesaje noi pentru { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Această copie a Inbox Classic nu este un pachet de aplicație, așa că nu poate fi aplicația de e-mail implicită.
# review: new
mac-not-made-default = Inbox Classic nu a fost setat ca aplicație de e-mail implicită: { $reason }
# review: new
mac-tool-search = Căutare

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Textul unui mesaj este încă în curs de indexare, așa că în curând s-ar putea găsi mai multe.
        [few] Textul a { $count } mesaje este încă în curs de indexare, așa că în curând s-ar putea găsi mai multe.
       *[other] Textul a { $count } de mesaje este încă în curs de indexare, așa că în curând s-ar putea găsi mai multe.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Niciun rezultat pentru „{ $words }” în toate folderele
        [one] { $count } rezultat pentru „{ $words }” în toate folderele
        [few] { $count } rezultate pentru „{ $words }” în toate folderele
       *[other] { $count } de rezultate pentru „{ $words }” în toate folderele
    }
# review: new
mac-results-in =
    { $count ->
        [0] Niciun rezultat pentru „{ $words }” în { $folder }
        [one] { $count } rezultat pentru „{ $words }” în { $folder }
        [few] { $count } rezultate pentru „{ $words }” în { $folder }
       *[other] { $count } de rezultate pentru „{ $words }” în { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] se indexează încă textul unui mesaj
        [few] se indexează încă textul a { $count } mesaje
       *[other] se indexează încă textul a { $count } de mesaje
    }
# review: new
mac-folder-unread = { $folder }, necitite: { $count }
# review: new
mac-import-messages = Import mesaje
# review: new
mac-save-messages = Salvare mesaje
# review: new
mac-save-attachments-menu = Salvare atașări…
# review: new
mac-files-not-saved =
    { $count ->
        [few] { $failed } din cele { $count } fișiere nu au putut fi salvate.
       *[other] { $failed } din cele { $count } de fișiere nu au putut fi salvate.
    }
# review: new
mac-no-calendar-app = Pe acest Mac nu există nicio aplicație de calendar care să deschidă invitații (fișiere .ics).
# review: new
mac-file-not-saved = Fișierul nu a putut fi salvat.
# review: new
mac-unsubscribing = Se face dezabonarea de la { $target }…
mac-loading-list = Se încarcă…

## The compose window

# review: new
mac-bold = Aldin
# review: new
mac-italic = Cursiv
# review: new
mac-underline = Subliniat
# review: new
mac-bcc = Bcc
# review: new
mac-command-click-to-open = ⌘-clic pentru deschidere
# review: new
mac-saving-to-drafts = Se salvează în Schițe…
# review: new
mac-dont-save = Nu salva

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } fișier
        [few] { $count } fișiere
       *[other] { $count } de fișiere
    }

## Accounts

# review: new
mac-next = Următorul
# review: new
mac-name-placeholder = Ana Popescu
# review: new
mac-more-sign-in-options = Mai multe opțiuni de conectare…
# review: new
mac-add-sign-in-app = Adăugare aplicație de conectare…
# review: new
mac-looking-up = Se caută setările pentru { $domain }…
# review: new
mac-add-button = Adăugare…
# review: new
mac-properties-button = Proprietăți…
# review: new
mac-signature-button = Semnătură…
# review: new
mac-security-button = Securitate…
# review: new
mac-sign-in-apps-button = Aplicații de conectare…

## AI agents

# review: new
mac-forget-program = Eliminați acest program și istoricul activității agenților lui?
# review: new
mac-forget-program-detail = Permisiunile programului vor fi șterse. Vi se va cere din nou permisiunea data viitoare când se conectează.

## Sign-in apps

# review: new
mac-checking-issuer = Se verifică { $issuer }…
# review: new
mac-edit-button = Editare…
# review: new
mac-use-for-new-accounts = Folosire { $name } pentru conturile noi
# review: new
mac-built-in = { $name } (integrată)

## Other windows

# review: new
mac-new-folder-button = Folder nou…
# review: new
mac-edit-link = Editare link…
