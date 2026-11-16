# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferințe, Ieșire).

## The main window

# review: new
gtk-search-looks-in = Căutarea în { $place } acoperă subiectele, expeditorii, destinatarii, numele atașărilor și textul mesajelor. Verificați ortografia sau încercați mai puține cuvinte.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Textul unui mesaj este încă în curs de indexare. În curând pot apărea mai multe rezultate.
    [few] Textul a { $count } mesaje este încă în curs de indexare. În curând pot apărea mai multe rezultate.
   *[other] Textul a { $count } de mesaje este încă în curs de indexare. În curând pot apărea mai multe rezultate.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Niciun rezultat
    [one] 1 rezultat
    [few] { $count } rezultate
   *[other] { $count } de rezultate
} pentru „{ $words }” în toate folderele
# review: new
gtk-search-results-in = { $count ->
    [0] Niciun rezultat
    [one] 1 rezultat
    [few] { $count } rezultate
   *[other] { $count } de rezultate
} pentru „{ $words }” în { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] se indexează încă textul unui mesaj
    [few] se indexează încă textul a { $count } mesaje
   *[other] se indexează încă textul a { $count } de mesaje
}
# review: new
gtk-list-loading = Se încarcă...
# review: new
gtk-menu-rename = Redenumire...
# review: new
gtk-import-one-question = Importați mesajul { $file } în { $folder }?
# review: new
gtk-files-not-saved = { $failed } din cele { $total } fișiere nu au putut fi salvate.
# review: new
gtk-unsubscribe-one-click =
    Părăsiți această listă de corespondență?

    Inbox Classic va trimite o cerere de dezabonare către { $target }. Nu se va deschide nicio pagină web și nu se va trimite niciun e-mail.
# review: new
gtk-unsubscribe-mail =
    Părăsiți această listă de corespondență?

    Pentru dezabonare, trimiteți un e-mail la { $target }. Inbox Classic îl pregătește pentru dvs. Trimiteți mesajul pentru a confirma.
# review: new
gtk-unsubscribe-web =
    Părăsiți această listă de corespondență?

    Pagina de dezabonare a listei de corespondență se va deschide în browser ({ $target }).
# review: new
gtk-unsubscribe-failed = Dezabonarea nu a reușit: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Scrieți dintr-un anumit cont
# review: new
gtk-toolbar-send-recv-menu = Trimiteți și primiți e-mail pentru un anumit cont
# review: new
gtk-main-menu = Meniu principal
# review: new
gtk-folder-list = Listă de foldere
# review: new
gtk-quit = Ieșire

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Folderul nou va fi la nivelul de sus al contului { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Niciun mesaj necitit
    [one] 1 mesaj necitit
    [few] { $count } mesaje necitite
   *[other] { $count } de mesaje necitite
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Niciun mesaj nu așteaptă să fie trimis.
# review: new
gtk-outbox-row = Către: { $to }  ·  În așteptare din { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic caută în continuare e-mailuri noi în fundal. Folosiți pictograma lui din bara de sus pentru a deschide aplicația sau a ieși din ea.
# review: new
gtk-sign-in-again-ask =
    Conectarea la { $account } a fost refuzată sau sesiunea a expirat.

    Vă conectați din nou în browser?
# review: new
gtk-default-app-not-installed = Această copie a Inbox Classic nu a fost instalată, așa că sistemul nu o afișează ca aplicație de e-mail. Instalați-o pentru a o putea alege.
# review: new
gtk-default-app-now = Inbox Classic este acum aplicația dvs. de e-mail implicită: linkurile de e-mail deschid aici un mesaj nou.
# review: new
gtk-default-app-failed = Inbox Classic nu a putut fi setat ca aplicație de e-mail implicită.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Dată:
# review: new
gtk-reader-files = Atașările mesajului
# review: new
gtk-files = { $count ->
    [one] { $count } fișier
    [few] { $count } fișiere
   *[other] { $count } de fișiere
}
# review: new
gtk-pictures-blocked = Unele imagini au fost blocate, ca expeditorul să nu vă poată identifica computerul.
# review: new
gtk-download-pictures = Descărcare imagini
# review: new
gtk-save-attachments-menu = Salvare atașări...

## The compose window

# review: new
gtk-format-bold = Aldin (Ctrl+B)
# review: new
gtk-format-italic = Cursiv (Ctrl+I)
# review: new
gtk-format-underline = Subliniat (Ctrl+U)
# review: new
gtk-format-hyperlink = Hyperlink (Ctrl+K)
# review: new
gtk-font = Font
# review: new
gtk-show-cc = _Cc
# review: new
gtk-show-bcc = _Bcc
# review: new
gtk-save-tip = Salvare (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+clic pentru deschidere)

## Accounts

# review: new
gtk-plain-warning =
    Fără criptare, oricine interceptează traficul de rețea vă poate citi parola și mesajele. Folosiți această conexiune doar cu un server de pe propriul computer sau din rețeaua locală.

    Continuați?
# review: new
gtk-account-name-title = Nume cont
# review: new
gtk-display-name-title = Nume afișat
# review: new
gtk-turned-off-why = Opțiunea „{ $button }” este dezactivată pe acest computer. { $reason }
# review: new
gtk-turned-off-why-long =
    Opțiunea „{ $button }” este dezactivată pe acest computer.

    { $reason }
# review: new
gtk-next = Următorul >
# review: new
gtk-provider-sign-in = Conectați-vă la { $address } pe site-ul web al furnizorului ({ $provider }). Parola nu este partajată cu Inbox Classic. Puteți folosi și o parolă de aplicație creată în setările de securitate ale contului.
# review: new
gtk-provider-sign-in-apps = Conectați-vă la { $address } pe site-ul web al furnizorului ({ $provider }) folosind una dintre aplicațiile dvs. de conectare (Mai multe opțiuni de conectare). Puteți folosi și o parolă de aplicație creată în setările de securitate ale contului.
# review: new
gtk-accounts-add = Adăugare...
# review: new
gtk-accounts-properties = Proprietăți...
# review: new
gtk-accounts-signature = Semnătură...
# review: new
gtk-accounts-sign-in-apps = Aplicații de conectare...

## Sign-in apps

# review: new
gtk-app-server = Server { $kind }
# review: new
gtk-app-port = Port { $kind }
# review: new
gtk-app-security = Securitate { $kind }
# review: new
gtk-issuer-found =
    Pagina de conectare: { $page }
    Endpoint pentru token: { $endpoint }
# review: new
gtk-client-id = ID client
# review: new
gtk-client-secret = Secret client
# review: new
gtk-scopes = Permisiuni (scopes)
# review: new
gtk-redirect-uri = URI de redirecționare
# review: new
gtk-issuer-usable =
    Emitentul poate fi folosit.

    { $found }
# review: new
gtk-app-built-in = { $app } este integrată. Puteți schimba doar dacă este oferită pentru conturile noi. { $reason }
# review: new
gtk-built-in = { $app } (integrată)
# review: new
gtk-offered-for-new = Oferită pentru conturile noi
# review: new
gtk-edit-button = Editare...
# review: new
gtk-remove-app-ask = Eliminați aplicația de conectare { $app } și secretul client salvat?
# review: new
gtk-sign-in-apps-intro = Aplicațiile de conectare permit conturilor să se conecteze prin browser. Una dezactivată nu este oferită pentru conturile noi; conturile care o folosesc deja funcționează în continuare.

## AI agents

# review: new
gtk-agent-it-may = Acțiuni permise
# review: new
gtk-agent-accounts = Conturi permise
# review: new
gtk-never-used = Nefolosit niciodată
# review: new
gtk-last-used = Folosit ultima dată { $date }
# review: new
gtk-forget-program = Eliminați acest program?
# review: new
gtk-forget-program-detail = Permisiunile programului și istoricul activității agenților lui vor fi șterse. Vi se va cere din nou permisiunea data viitoare când se conectează.
# review: new
gtk-no-agents-yet = Niciun agent nu a cerut încă să vă folosească e-mailul.
# review: new
gtk-nothing-yet = Nimic încă.

## Preferences

# review: new
gtk-preferences = Preferințe
# review: new
gtk-language = Limbă
# review: new
gtk-language-subtitle = Limba aplicației și a ajutorului
# review: new
gtk-new-mail-group = E-mail nou
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Notificare la e-mail nou
# review: new
gtk-notify-subtitle = O notificare când sosesc mesaje noi cât timp fereastra este în fundal
# review: new
gtk-restart-to-change = Inbox Classic repornește pentru a schimba limba.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Client de e-mail
# review: new
gtk-desktop-comment = Citiți și scrieți e-mailuri: un program de e-mail rapid și simplu
# review: new
gtk-desktop-keywords = poștă;email;e-mail;mesaje;corespondență;
# review: new
gtk-metainfo-summary = Un program de e-mail rapid și simplu
# review: new
gtk-metainfo-description = Inbox Classic citește și scrie e-mailuri cu folderele în stânga, mesajele sus și mesajul dedesubt, ca programele de e-mail de odinioară. Funcționează cu orice cont IMAP și SMTP și se conectează la Outlook.com și Microsoft 365 prin browser.
# review: new
gtk-metainfo-feature-sanitized = Fiecare mesaj este afișat curățat, fără scripturi, iar imaginile de pe internet doar când le permiteți
# review: new
gtk-metainfo-feature-search = O căutare care găsește cuvinte în subiect, în expeditori și destinatari, în numele fișierelor și în text, cu operatorii din Gmail
# review: new
gtk-metainfo-feature-replies = Răspunsurile pliază mesajele anterioare pe care le citează
# review: new
gtk-metainfo-feature-offline = E-mailurile rămân de citit și offline; parolele sunt păstrate în portcheiul dvs.
