# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic caută în continuare mesaje noi în fundal. Faceți clic pe pictogramă pentru a deschide aplicația. Pentru a ieși, faceți clic dreapta pe pictogramă și folosiți meniul acesteia.
win-default-app-not-installed = Această copie a aplicației Inbox Classic nu a fost instalată, așa că Windows nu o afișează în lista aplicațiilor de e-mail. Instalați-o pentru a o putea alege.
win-default-app-settings = Windows va deschide setările Aplicații implicite. Alegeți Inbox Classic pentru a deschide linkurile MAILTO.
win-no-unread = Niciun mesaj necitit
win-unread-messages = { $count ->
    [one] 1 mesaj necitit
    [few] { $count } mesaje necitite
   *[other] { $count } de mesaje necitite
}
win-print-failed = Mesajul nu a putut fi imprimat.
win-print-title-of = Imprimare: { $subject }
win-no-bodies = Conținutul mesajelor nu poate fi afișat.
win-webview-failed = Inițializarea WebView2 nu a reușit.
win-webview-missing = Mediul de rulare WebView2 nu este disponibil.
win-list-loading = Se încarcă...

## Buttons and words used in many windows

win-delete-button = Șt&ergere
win-find-label = &Căutare:
win-save-as-button = &Salvare ca...
win-too-many-files = Prea multe fișiere deodată: alegeți mai puține.

## The Outbox


## The compose window

win-editor-failed = Nu se pot redacta mesaje.
win-ctrl-click-to-open = ({ $ctrl }+clic pentru deschidere)
win-format-bold = Aldin ({ $ctrl }+B)
win-format-italic = Cursiv ({ $ctrl }+I)
win-format-underline = Subliniat ({ $ctrl }+U)
win-format-link = Hyperlink ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature-title = Textul semnăturii: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Niciun rezultat pentru „{ $words }” în toate folderele
    [one] { $count } rezultat pentru „{ $words }” în toate folderele
    [few] { $count } rezultate pentru „{ $words }” în toate folderele
   *[other] { $count } de rezultate pentru „{ $words }” în toate folderele
}
win-search-found-in = { $count ->
    [0] Niciun rezultat pentru „{ $words }” în „{ $folder }”
    [one] { $count } rezultat pentru „{ $words }” în „{ $folder }”
    [few] { $count } rezultate pentru „{ $words }” în „{ $folder }”
   *[other] { $count } de rezultate pentru „{ $words }” în „{ $folder }”
}
win-search-indexing = { $count ->
    [one] se indexează încă textul unui mesaj
    [few] se indexează încă textul a { $count } mesaje
   *[other] se indexează încă textul a { $count } de mesaje
}
win-no-match-indexing = { $count ->
    [one] Textul unui mesaj este încă în curs de indexare, așa că în curând pot apărea mai multe rezultate.
    [few] Textul a { $count } mesaje este încă în curs de indexare, așa că în curând pot apărea mai multe rezultate.
   *[other] Textul a { $count } de mesaje este încă în curs de indexare, așa că în curând pot apărea mai multe rezultate.
}
win-files = { $count ->
    [one] { $count } fișier
    [few] { $count } fișiere
   *[other] { $count } de fișiere
}
win-save-attachments = &Salvare atașări...
win-files-not-saved = Fișiere care nu au putut fi salvate: { $failed } din { $count }.
win-new-folder-in-highlighted = Folderul nou va fi creat în folderul selectat.
win-delete-folder-ask = Ștergeți folderul „{ $folder }”, inclusiv mesajele și subfolderele sale? Acestea vor fi șterse și de pe server.
win-rename = &Redenumire...
win-messages-not-saved = Mesajele nu au putut fi salvate.
win-messages-not-forwarded = Mesajele nu au putut fi redirecționate.

## Accounts

win-sign-in-google = Conectare cu Google
win-sign-in-microsoft = Conectare cu Microsoft
win-next = &Următorul >
win-your-account = contul dvs.
win-browser-sign-in = (conectare prin browser)
win-add = &Adăugare...
win-properties-button = &Proprietăți...
win-signature-button = Textul se&mnăturii...
win-sign-in-apps-button = Aplicații de &conectare...

## AI agents

win-dont-allow = &Nu permiteți
win-col-address = Adresă
win-never-written-to = Niciun mesaj trimis la această adresă
win-book-find-label = Introduceți un nume sau o adresă de e-mail:
win-send = &Trimitere
win-dont-send = &Nu trimiteți
win-unsubscribe = &Dezabonare
win-dont-unsubscribe = &Nu vă dezabonați
win-forget-program-ask = Eliminați programul din această listă, împreună cu permisiunile și istoricul activității agenților săi? Vi se va cere din nou permisiunea la următoarea conectare.
win-clear-log-ask = Ștergeți istoricul activității agenților? Modificările făcute de agenți nu vor fi anulate.
win-agent-programs = &Programe ai căror agenți au cerut acces la mesajele dvs.:
win-change = &Modificare...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Anulare pe &interval...
win-take-back = &Anulare modificări
win-what-agents-did = &Activitatea agenților:
win-agent-reads = Ce s-a citit între { $from } și { $to }:
win-agent-reads-hint = Selectați mai sus o activitate de citire pentru a vedea detaliile.

## Sign-in apps

win-built-in = (integrată)
win-edit = &Editare...

## Options

win-folders-hide = Ascundere listă de foldere
win-folders-pin = Păstrare listă de foldere lângă mesaje
win-folders-show = Afișare foldere

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Pornire Inbox Classic
win-installer-welcome-new =
    Se va instala Inbox Classic { $version }, un program de e-mail.

    Nu sunt necesare drepturi de administrator. Aplicația se instalează doar pentru contul dvs. Windows.
win-installer-welcome-same =
    Inbox Classic { $version } este deja instalat. Se va instala din nou.

    Conturile și e-mailurile dvs. se păstrează.
win-installer-welcome-update =
    Inbox Classic { $installed } va fi actualizat la { $version }.

    Dacă rulează, mai întâi este închis. Conturile și e-mailurile dvs. se păstrează.
win-installer-older-ask = Este instalat Inbox Classic { $installed }, mai nou decât { $version }. Instalați totuși versiunea mai veche?
win-installer-still-running = Inbox Classic rulează încă. Închideți-l și încercați din nou.
win-installer-remove-mail-ask = Eliminați și datele locale ale Inbox Classic: conturile, mesajele descărcate și cele în așteptarea trimiterii, setările, contactele și cheile? Mesajele de pe servere rămân acolo. Datele din Managerul de acreditări nu sunt șterse.
