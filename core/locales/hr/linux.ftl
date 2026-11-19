# Hrvatski. Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

## The main window

gtk-search-looks-in = Pretraživanje ({ $place }) obuhvaća predmete, pošiljatelje, primatelje, nazive privitaka i tekst poruka. Provjerite jesu li riječi ispravno napisane ili ih unesite manje.
gtk-search-still-indexing = { $count ->
    [one] Još traje indeksiranje teksta poruka (preostalo: { $count }). Uskoro se može pojaviti više rezultata.
    [few] Još traje indeksiranje teksta poruka (preostalo: { $count }). Uskoro se može pojaviti više rezultata.
   *[other] Još traje indeksiranje teksta poruka (preostalo: { $count }). Uskoro se može pojaviti više rezultata.
}
gtk-search-results-everywhere = { $count ->
    [0] Nema rezultata
    [one] { $count } rezultat
    [few] { $count } rezultata
   *[other] { $count } rezultata
} za „{ $words }“ u svim mapama
gtk-search-results-in = { $count ->
    [0] Nema rezultata
    [one] { $count } rezultat
    [few] { $count } rezultata
   *[other] { $count } rezultata
} za „{ $words }“ u mapi { $place }
gtk-search-indexing = { $count ->
    [one] tekst poruka još se indeksira (preostalo: { $count })
    [few] tekst poruka još se indeksira (preostalo: { $count })
   *[other] tekst poruka još se indeksira (preostalo: { $count })
}
gtk-list-loading = Učitavanje...
gtk-menu-rename = Preimenuj...
gtk-import-one-question = Uvesti poruku { $file } u mapu { $folder }?
gtk-files-not-saved = Broj datoteka koje nije moguće spremiti: { $failed } od ukupno { $total }.
gtk-unsubscribe-one-click =
    Želite li otkazati pretplatu na ovu listu e-pošte?

    Inbox Classic poslat će zahtjev za otkazivanje pretplate na adresu { $target }. Neće se otvoriti web-stranica niti će se poslati poruka e-pošte.
gtk-unsubscribe-mail =
    Želite li otkazati pretplatu na ovu listu e-pošte?

    Za otkazivanje pretplate pošaljite poruku na adresu { $target }. Inbox Classic pripremit će je za vas. Pošaljite je kako biste potvrdili otkazivanje pretplate.
gtk-unsubscribe-web =
    Želite li otkazati pretplatu na ovu listu e-pošte?

    U pregledniku će se otvoriti stranica za otkazivanje pretplate na listu e-pošte ({ $target }).
gtk-unsubscribe-failed = Otkazivanje pretplate nije uspjelo: { $problem }
gtk-toolbar-create-mail-menu = Napiši poruku s određenog računa
gtk-toolbar-send-recv-menu = Pošalji i primi poštu za određeni račun
gtk-main-menu = Glavni izbornik
gtk-folder-list = Popis mapa
gtk-quit = Zatvori

## The Move and Copy window

gtk-new-folder-at-top-of = Nova će se mapa stvoriti na najvišoj razini računa { $account }.

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Nema nepročitanih poruka
    [one] { $count } nepročitana poruka
    [few] { $count } nepročitane poruke
   *[other] { $count } nepročitanih poruka
}

## The Outbox

gtk-outbox-empty = Nijedna poruka ne čeka na slanje.
gtk-outbox-row = Za: { $to }  ·  Dodano u red za slanje: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic i dalje provjerava novu poštu u pozadini. Njegovom ikonom na gornjoj traci otvorite ili zatvorite aplikaciju.
gtk-sign-in-again-ask =
    Prijava na račun { $account } odbijena je ili je sesija istekla.

    Želite li se ponovno prijaviti u pregledniku?
gtk-default-app-not-installed = Ova kopija programa Inbox Classic nije instalirana, pa je sustav ne navodi kao aplikaciju za poštu. Instalirajte je da biste je mogli odabrati.
gtk-default-app-now = Inbox Classic sada je vaša zadana aplikacija za poštu: poveznice e-pošte ovdje otvaraju novu poruku.
gtk-default-app-failed = Inbox Classic nije moguće postaviti kao zadanu aplikaciju za poštu.

## The reading pane

gtk-reader-date = Datum:
gtk-reader-files = Privici poruke
gtk-files = { $count ->
    [one] { $count } datoteka
    [few] { $count } datoteke
   *[other] { $count } datoteka
}
gtk-pictures-blocked = Neke su slike blokirane kako bi se pošiljatelju otežalo praćenje.
gtk-download-pictures = Preuzmi slike
gtk-save-attachments-menu = Spremi privitke...

## The compose window

gtk-format-bold = Podebljano (Ctrl+B)
gtk-format-italic = Kurziv (Ctrl+I)
gtk-format-underline = Podcrtano (Ctrl+U)
gtk-format-hyperlink = Hiperveza (Ctrl+K)
gtk-font = Font
gtk-show-cc = _Kopija
gtk-show-bcc = _Skrivena kopija
gtk-save-tip = Spremi (Ctrl+S)
gtk-link-status = { $link }    (Ctrl + klik za otvaranje)

## Accounts

gtk-plain-warning =
    Bez šifriranja veze netko tko presretne mrežni promet može pročitati vaše podatke za prijavu i poruke. Ovu vezu upotrebljavajte samo s poslužiteljem na svojem računalu ili u lokalnoj mreži.

    Želite li nastaviti?
gtk-account-name-title = Naziv računa
gtk-display-name-title = Ime za prikaz
gtk-turned-off-why = Mogućnost „{ $button }“ isključena je na ovom računalu. { $reason }
gtk-turned-off-why-long =
    Mogućnost „{ $button }“ isključena je na ovom računalu.

    { $reason }
gtk-next = Dalje >
gtk-provider-sign-in = Prijavite se na račun { $address } putem preglednika ({ $provider }). Inbox Classic pritom ne dobiva vašu lozinku. Ako vaš račun podržava lozinke za aplikacije, izradite takvu lozinku u sigurnosnim postavkama računa. Za Outlook.com i Microsoft 365 koristite prijavu putem preglednika.
gtk-provider-sign-in-apps = Prijavite se na račun { $address } putem preglednika ({ $provider }). Odaberite „Još mogućnosti prijave“, a zatim jednu od svojih aplikacija za prijavu. Ako vaš račun podržava lozinke za aplikacije, izradite takvu lozinku u sigurnosnim postavkama računa. Za Outlook.com i Microsoft 365 koristite prijavu putem preglednika.
gtk-accounts-add = Dodaj...
gtk-accounts-properties = Svojstva...
gtk-accounts-signature = Potpis...
gtk-accounts-sign-in-apps = Aplikacije za prijavu...

## Sign-in apps

gtk-app-server = { $kind } poslužitelj
gtk-app-port = { $kind } priključak
gtk-app-security = Sigurnost veze ({ $kind })
gtk-issuer-found =
    Stranica za prijavu: { $page }
    Adresa za dobivanje tokena: { $endpoint }
gtk-client-id = ID klijenta
gtk-client-secret = Tajna klijenta
gtk-scopes = Dozvole (scopes)
gtk-redirect-uri = URI za preusmjeravanje
gtk-issuer-usable =
    Izdavatelj se može koristiti.

    { $found }
gtk-app-built-in = Aplikacija { $app } je ugrađena. Možete samo promijeniti nudi li se za nove račune. { $reason }
gtk-built-in = { $app } (ugrađena)
gtk-offered-for-new = Nudi se za nove račune
gtk-edit-button = Uredi...
gtk-remove-app-ask = Želite li ukloniti aplikaciju za prijavu { $app } i njezinu spremljenu tajnu klijenta?
gtk-sign-in-apps-intro = Aplikacije za prijavu omogućuju računima prijavu putem preglednika. Aplikacija koja je isključena ne nudi se za nove račune; računi koji je već koriste i dalje rade.

## AI agents

gtk-agent-it-may = Dopuštene radnje
gtk-agent-accounts = Dopušteni računi
gtk-never-used = Još nije korišten
gtk-last-used = Posljednja upotreba: { $date }
gtk-forget-program = Želite li ukloniti ovaj program s popisa?
gtk-forget-program-detail = Dozvole programa i povijest aktivnosti njegovih agenata bit će izbrisane. Pri sljedećem povezivanju ponovno će se tražiti vaša dozvola.
gtk-no-agents-yet = Još nijedan agent nije zatražio pristup vašoj pošti.
gtk-nothing-yet = Zasad ništa.

## Preferences

gtk-preferences = Postavke
gtk-notify-subtitle = Samo dok je Inbox Classic u pozadini

## The desktop entry and the page of the software stores

gtk-desktop-generic-name = Klijent e-pošte
gtk-desktop-comment = Brz i jednostavan program za čitanje i pisanje e-pošte
gtk-desktop-keywords = pošta;e-pošta;poruke;ulazna pošta;klijent e-pošte;
gtk-metainfo-summary = Brz i jednostavan program za poštu
gtk-metainfo-description = Inbox Classic omogućuje čitanje i pisanje e-pošte u poznatom sučelju. U klasičnom rasporedu mape su lijevo, popis poruka gore, a odabrana poruka ispod. Podržava račune s protokolima IMAP i SMTP te prijavu na Outlook.com i Microsoft 365 putem preglednika.
gtk-metainfo-feature-sanitized = Skripte u porukama se ne izvršavaju, a vanjske slike preuzimaju se samo uz vaše dopuštenje
gtk-metainfo-feature-search = Pretraživanje predmeta, pošiljatelja, primatelja, naziva privitaka i teksta poruka, uz operatore pretraživanja iz Gmaila
gtk-metainfo-feature-replies = Citirani tekst ranijih poruka u odgovorima skriven je iza gumba za prikaz
gtk-metainfo-feature-offline = Preuzetu poštu možete čitati bez interneta dok je lokalna kopija sačuvana; podaci za prijavu obično se čuvaju u sustavskom spremištu, ako je dostupno
