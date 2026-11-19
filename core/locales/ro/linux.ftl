# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferințe, Ieșire).

## The main window

gtk-search-looks-in = În „{ $place }”, se caută în subiectele și textul mesajelor, în numele și adresele expeditorilor și destinatarilor, precum și în numele atașărilor. Verificați ortografia sau încercați mai puține cuvinte.
gtk-search-still-indexing = { $count ->
    [one] Textul unui mesaj este încă în curs de indexare. În curând pot apărea mai multe rezultate.
    [few] Textul a { $count } mesaje este încă în curs de indexare. În curând pot apărea mai multe rezultate.
   *[other] Textul a { $count } de mesaje este încă în curs de indexare. În curând pot apărea mai multe rezultate.
}
gtk-search-results-everywhere = { $count ->
    [0] Niciun rezultat
    [one] 1 rezultat
    [few] { $count } rezultate
   *[other] { $count } de rezultate
} pentru „{ $words }” în toate folderele
gtk-search-results-in = { $count ->
    [0] Niciun rezultat
    [one] 1 rezultat
    [few] { $count } rezultate
   *[other] { $count } de rezultate
} pentru „{ $words }” în „{ $place }”
gtk-search-indexing = { $count ->
    [one] se indexează încă textul unui mesaj
    [few] se indexează încă textul a { $count } mesaje
   *[other] se indexează încă textul a { $count } de mesaje
}
gtk-list-loading = Se încarcă...
gtk-menu-rename = Redenumire...
gtk-import-one-question = Importați mesajul din fișierul „{ $file }” în „{ $folder }”?
gtk-files-not-saved = Fișiere care nu au putut fi salvate: { $failed } din { $total }.
gtk-unsubscribe-one-click =
    Vă dezabonați de la această listă de corespondență?

    Inbox Classic va trimite o cerere de dezabonare către { $target }. Nu se va deschide nicio pagină web și nu se va trimite niciun e-mail.
gtk-unsubscribe-mail =
    Vă dezabonați de la această listă de corespondență?

    Pentru dezabonare, trimiteți un e-mail la { $target }. Inbox Classic îl pregătește pentru dvs. Trimiteți mesajul pentru a confirma.
gtk-unsubscribe-web =
    Vă dezabonați de la această listă de corespondență?

    Pagina de dezabonare a listei de corespondență se va deschide în browser ({ $target }).
gtk-unsubscribe-failed = Dezabonarea nu a reușit: { $problem }
gtk-toolbar-create-mail-menu = Compuneți un mesaj dintr-un anumit cont
gtk-toolbar-send-recv-menu = Trimiteți și primiți mesaje într-un anumit cont
gtk-main-menu = Meniu principal
gtk-folder-list = Listă de foldere
gtk-quit = Ieșire

## The Move and Copy window

gtk-new-folder-at-top-of = Folderul nou va fi creat la nivelul principal al contului „{ $account }”.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Niciun mesaj necitit
    [one] 1 mesaj necitit
    [few] { $count } mesaje necitite
   *[other] { $count } de mesaje necitite
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Niciun mesaj nu așteaptă să fie trimis.
gtk-outbox-row = Către: { $to }  ·  În așteptare din { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic caută în continuare mesaje noi în fundal. Folosiți pictograma aplicației din bara de sus pentru a o deschide sau a ieși din ea.
gtk-sign-in-again-ask =
    Conectarea la contul „{ $account }” a fost refuzată sau sesiunea a expirat.

    Doriți să vă conectați din nou în browser?
gtk-default-app-not-installed = Această copie a aplicației Inbox Classic nu a fost instalată, așa că sistemul nu o afișează în lista aplicațiilor de e-mail. Instalați-o pentru a o putea alege.
gtk-default-app-now = Inbox Classic este acum aplicația dvs. de e-mail implicită: linkurile de e-mail deschid aici un mesaj nou.
gtk-default-app-failed = Inbox Classic nu a putut fi setat ca aplicație de e-mail implicită.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Dată:
gtk-reader-files = Atașările mesajului
gtk-files = { $count ->
    [one] { $count } fișier
    [few] { $count } fișiere
   *[other] { $count } de fișiere
}
gtk-pictures-blocked = Unele imagini au fost blocate, ca expeditorul să nu vă poată identifica computerul.
gtk-download-pictures = Descărcare imagini
gtk-save-attachments-menu = Salvare atașări...

## The compose window

gtk-format-bold = Aldin (Ctrl+B)
gtk-format-italic = Cursiv (Ctrl+I)
gtk-format-underline = Subliniat (Ctrl+U)
gtk-format-hyperlink = Hyperlink (Ctrl+K)
gtk-font = Font
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Salvare (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+clic pentru deschidere)

## Accounts

gtk-plain-warning =
    Fără criptare, oricine interceptează traficul de rețea vă poate citi parola și mesajele. Folosiți această conexiune doar cu un server de pe propriul computer sau din rețeaua locală.

    Continuați?
gtk-account-name-title = Nume cont
gtk-display-name-title = Nume afișat
gtk-turned-off-why = Opțiunea „{ $button }” este dezactivată pe acest computer. { $reason }
gtk-turned-off-why-long =
    Opțiunea „{ $button }” este dezactivată pe acest computer.

    { $reason }
gtk-next = Următorul >
gtk-provider-sign-in = Conectați-vă la contul „{ $address }” pe site-ul furnizorului ({ $provider }). Inbox Classic nu primește parola dvs. Dacă acest cont permite folosirea parolelor de aplicație pentru e-mail, puteți folosi o astfel de parolă creată în setările de securitate ale contului. Outlook.com și Microsoft 365 permit numai conectarea prin browser.
gtk-provider-sign-in-apps = Conectați-vă la contul „{ $address }” pe site-ul furnizorului ({ $provider }), folosind una dintre aplicațiile dvs. de conectare din „Mai multe opțiuni de conectare”. Dacă acest cont permite folosirea parolelor de aplicație pentru e-mail, puteți folosi o astfel de parolă creată în setările de securitate ale contului. Outlook.com și Microsoft 365 permit numai conectarea prin browser.
gtk-accounts-add = Adăugare...
gtk-accounts-properties = Proprietăți...
gtk-accounts-signature = Textul semnăturii...
gtk-accounts-sign-in-apps = Aplicații de conectare...

## Sign-in apps

gtk-app-server = Server { $kind }
gtk-app-port = Port { $kind }
gtk-app-security = Securitate { $kind }
gtk-issuer-found =
    Pagina de conectare: { $page }
    Endpoint pentru token: { $endpoint }
gtk-client-id = ID client
gtk-client-secret = Secret client
gtk-scopes = Permisiuni (scopes)
gtk-redirect-uri = URI de redirecționare
gtk-issuer-usable =
    Emitentul poate fi folosit.

    { $found }
gtk-app-built-in = Aplicația „{ $app }” este integrată în Inbox Classic. Puteți schimba doar dacă apare printre opțiunile de conectare pentru conturi noi. { $reason }
gtk-built-in = { $app } (integrată)
gtk-offered-for-new = Oferită pentru conturile noi
gtk-edit-button = Editare...
gtk-remove-app-ask = Eliminați aplicația de conectare „{ $app }” și secretul client salvat pentru aceasta?
gtk-sign-in-apps-intro = Aplicațiile de conectare vă permit să vă conectați la conturi prin browser. Dacă o aplicație este dezactivată, nu apare printre opțiunile de conectare pentru conturi noi. Conturile care o folosesc deja continuă să funcționeze.

## AI agents

gtk-agent-it-may = Acțiuni permise
gtk-agent-accounts = Conturi permise
gtk-never-used = Nefolosit niciodată
gtk-last-used = Ultima utilizare: { $date }
gtk-forget-program = Eliminați programul din această listă?
gtk-forget-program-detail = Permisiunile programului și istoricul activității agenților săi vor fi șterse. Vi se va cere din nou permisiunea la următoarea conectare.
gtk-no-agents-yet = Niciun agent nu a cerut încă acces la mesajele dvs.
gtk-nothing-yet = Nimic încă.

## Preferences

gtk-preferences = Preferințe
gtk-notify-subtitle = Doar cât timp Inbox Classic este în fundal

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Client de e-mail
gtk-desktop-comment = Citiți și scrieți e-mailuri: un program de e-mail rapid și simplu
gtk-desktop-keywords = poștă;email;e-mail;mesaje;corespondență;
gtk-metainfo-summary = Un program de e-mail rapid și simplu
gtk-metainfo-description = Inbox Classic este un program de e-mail cu o interfață clasică: folderele în stânga, lista mesajelor sus și mesajul selectat dedesubt. Funcționează cu orice cont IMAP și SMTP și se conectează la Outlook.com și Microsoft 365 prin browser.
gtk-metainfo-feature-sanitized = Mesajele sunt afișate fără scripturi sau alte elemente active, iar imaginile de pe internet sunt încărcate doar cu acordul dvs.
gtk-metainfo-feature-search = Căutare în subiecte, numele și adresele expeditorilor și destinatarilor, numele fișierelor și textul mesajelor, cu operatori de căutare ca în Gmail
gtk-metainfo-feature-replies = În răspunsuri, mesajele anterioare citate sunt restrânse
gtk-metainfo-feature-offline = Mesajele pot fi citite și offline, iar parolele sunt păstrate în portchei
