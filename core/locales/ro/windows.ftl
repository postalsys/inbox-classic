# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic caută în continuare e-mailuri noi în fundal. Faceți clic pe pictogramă pentru a-l deschide. Pentru a ieși, faceți clic dreapta pe pictogramă și folosiți meniul ei.
# review: new
win-default-app-not-installed = Această copie a Inbox Classic nu a fost instalată, așa că Windows nu o afișează ca aplicație de e-mail. Instalați-o pentru a o putea alege.
# review: new
win-default-app-settings = Windows va deschide setările Aplicații implicite. Alegeți Inbox Classic pentru a deschide linkurile MAILTO.
# review: new
win-no-unread = Niciun mesaj necitit
# review: new
win-unread-messages = { $count ->
    [one] 1 mesaj necitit
    [few] { $count } mesaje necitite
   *[other] { $count } de mesaje necitite
}
# review: new
win-print-failed = Mesajul nu a putut fi imprimat.
# review: new
win-print-title-of = Imprimare - { $subject }
# review: new
win-no-bodies = Conținutul mesajelor nu poate fi afișat.
# review: new
win-webview-failed = Crearea WebView2 nu a reușit.
# review: new
win-webview-missing = Mediul de rulare WebView2 nu este disponibil.
win-list-loading = Se încarcă...

## Buttons and words used in many windows

# review: new
win-delete-button = Șt&ergere
# review: new
win-find-label = &Căutare:
# review: new
win-save-as-button = Salvare c&a...
# review: new
win-too-many-files = Prea multe fișiere deodată: alegeți mai puține.

## The Outbox


## The compose window

# review: new
win-editor-failed = Mesajele nu pot fi scrise.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+clic pentru deschidere)
# review: new
win-format-bold = Aldin ({ $ctrl }+B)
# review: new
win-format-italic = Cursiv ({ $ctrl }+I)
# review: new
win-format-underline = Subliniat ({ $ctrl }+U)
# review: new
win-format-link = Hyperlink ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = &Bcc
# review: new
win-signature-title = Semnătură: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Niciun rezultat pentru „{ $words }” în toate folderele
    [one] { $count } rezultat pentru „{ $words }” în toate folderele
    [few] { $count } rezultate pentru „{ $words }” în toate folderele
   *[other] { $count } de rezultate pentru „{ $words }” în toate folderele
}
# review: new
win-search-found-in = { $count ->
    [0] Niciun rezultat pentru „{ $words }” în { $folder }
    [one] { $count } rezultat pentru „{ $words }” în { $folder }
    [few] { $count } rezultate pentru „{ $words }” în { $folder }
   *[other] { $count } de rezultate pentru „{ $words }” în { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] se indexează încă textul unui mesaj
    [few] se indexează încă textul a { $count } mesaje
   *[other] se indexează încă textul a { $count } de mesaje
}
# review: new
win-no-match-indexing = { $count ->
    [one] Textul unui mesaj este încă în curs de indexare, așa că în curând s-ar putea găsi mai multe.
    [few] Textul a { $count } mesaje este încă în curs de indexare, așa că în curând s-ar putea găsi mai multe.
   *[other] Textul a { $count } de mesaje este încă în curs de indexare, așa că în curând s-ar putea găsi mai multe.
}
# review: new
win-files = { $count ->
    [one] { $count } fișier
    [few] { $count } fișiere
   *[other] { $count } de fișiere
}
# review: new
win-click-to-retry = Faceți clic aici pentru a încerca din nou.
# review: new
win-save-attachments = &Salvare atașări...
# review: new
win-files-not-saved = { $count ->
    [few] { $failed } din cele { $count } fișiere nu au putut fi salvate.
   *[other] { $failed } din cele { $count } de fișiere nu au putut fi salvate.
}
# review: new
win-new-folder-in-highlighted = Folderul nou va fi creat în folderul selectat.
# review: new
win-delete-folder-ask = Ștergeți folderul „{ $folder }” cu mesajele și folderele din el? Este șters și de pe server.
# review: new
win-rename = &Redenumire...
# review: new
win-messages-not-saved = Mesajele nu au putut fi salvate.
# review: new
win-messages-not-forwarded = Mesajele nu au putut fi redirecționate.

## Accounts

# review: new
win-sign-in-google = Conectare cu Google
# review: new
win-sign-in-microsoft = Conectare cu Microsoft
# review: new
win-next = &Următorul >
# review: new
win-your-account = contul dvs.
# review: new
win-browser-sign-in = (conectare prin browser)
# review: new
win-add = &Adăugare...
# review: new
win-properties-button = &Proprietăți...
# review: new
win-signature-button = Se&mnătură...
# review: new
win-sign-in-apps-button = Aplicații de &conectare...

## AI agents

# review: new
win-dont-allow = &Nu permiteți
# review: new
win-col-address = Adresă
# review: new
win-never-written-to = Nu ați scris niciodată la ea
# review: new
win-book-find-label = Introduceți un nume sau o adresă de e-mail:
# review: new
win-send = &Trimitere
# review: new
win-dont-send = &Nu trimiteți
# review: new
win-unsubscribe = &Dezabonare
# review: new
win-dont-unsubscribe = &Nu vă dezabonați
# review: new
win-forget-program-ask = Eliminați acest program, permisiunile lui și istoricul activității agenților lui? Vi se va cere din nou permisiunea data viitoare când se conectează.
# review: new
win-clear-log-ask = Ștergeți istoricul activității agenților? Modificările făcute de agenți nu vor fi anulate.
# review: new
win-agent-programs = &Programe ai căror agenți au cerut acces la e-mailul dvs.:
# review: new
win-change = &Modificare...
# review: new
win-what-agents-did = &Activitatea agenților:
# review: new
win-how-to-connect = Cum se conectează un agent

## Sign-in apps

# review: new
win-built-in = (integrată)
# review: new
win-edit = &Editare...

## Options

# review: new
win-folders-hide = Ascundere listă de foldere
# review: new
win-folders-pin = Păstrare listă de foldere lângă mesaje
# review: new
win-folders-show = Afișare foldere

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Pornire Inbox Classic
# review: new
win-installer-welcome-new =
    Se va instala Inbox Classic { $version }, un program de e-mail.

    Nu sunt necesare drepturi de administrator, se instalează doar pentru contul dvs.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } este deja instalat. Se va instala din nou.

    Conturile și e-mailurile dvs. se păstrează.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } va fi actualizat la { $version }.

    Dacă rulează, mai întâi este închis. Conturile și e-mailurile dvs. se păstrează.
# review: new
win-installer-older-ask = Este instalat Inbox Classic { $installed }, mai nou decât { $version }. Instalați totuși versiunea mai veche?
# review: new
win-installer-still-running = Inbox Classic rulează încă. Închideți-l și încercați din nou.
# review: new
win-installer-remove-mail-ask = Eliminați și conturile și e-mailurile pe care Inbox Classic le păstrează pe acest computer? E-mailurile de pe servere rămân.
