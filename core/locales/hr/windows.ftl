# Hrvatski. Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

## The main window

# review: new
win-still-running-detail = Inbox Classic i dalje provjerava novu poštu u pozadini. Kliknite ikonu da biste ga otvorili. Da biste izašli, desnom tipkom miša kliknite ikonu i upotrijebite njezin izbornik.
# review: new
win-default-app-not-installed = Ova kopija programa Inbox Classic nije instalirana, pa je Windows ne navodi kao aplikaciju za poštu. Instalirajte je da biste je mogli odabrati.
# review: new
win-default-app-settings = Windows će otvoriti postavke Zadane aplikacije. Odaberite Inbox Classic za otvaranje poveznica MAILTO.
# review: new
win-no-unread = Nema nepročitanih poruka
# review: new
win-unread-messages = { $count ->
    [one] { $count } nepročitana poruka
    [few] { $count } nepročitane poruke
   *[other] { $count } nepročitanih poruka
}
# review: new
win-print-failed = Poruku nije moguće ispisati.
# review: new
win-print-title-of = Ispis: { $subject }
# review: new
win-no-bodies = Tijela poruka ne mogu se prikazati.
# review: new
win-webview-failed = Stvaranje komponente WebView2 nije uspjelo.
# review: new
win-webview-missing = Okruženje za izvođenje WebView2 nije dostupno.
# review: new
win-list-loading = Učitavanje...

## Buttons and words used in many windows

# review: new
win-delete-button = &Izbriši
# review: new
win-find-label = &Traži:
# review: new
win-save-as-button = Spremi &kao...
# review: new
win-too-many-files = Previše datoteka odjednom: odaberite manje.

## The compose window

# review: new
win-editor-failed = Poruke se ne mogu pisati.
# review: new
win-ctrl-click-to-open = ({ $ctrl } + klik za otvaranje)
# review: new
win-format-bold = Podebljano ({ $ctrl }+B)
# review: new
win-format-italic = Kurziv ({ $ctrl }+I)
# review: new
win-format-underline = Podcrtano ({ $ctrl }+U)
# review: new
win-format-link = Hiperveza ({ $ctrl }+K)
# review: new
win-show-cc = &Kopija
# review: new
win-show-bcc = &Skrivena kopija
# review: new
win-signature-title = Potpis: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Nema rezultata za „{ $words }“ u svim mapama
    [one] { $count } rezultat za „{ $words }“ u svim mapama
    [few] { $count } rezultata za „{ $words }“ u svim mapama
   *[other] { $count } rezultata za „{ $words }“ u svim mapama
}
# review: new
win-search-found-in = { $count ->
    [0] Nema rezultata za „{ $words }“ u mapi { $folder }
    [one] { $count } rezultat za „{ $words }“ u mapi { $folder }
    [few] { $count } rezultata za „{ $words }“ u mapi { $folder }
   *[other] { $count } rezultata za „{ $words }“ u mapi { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] tekst { $count } poruke još se indeksira
    [few] tekst { $count } poruke još se indeksira
   *[other] tekst { $count } poruka još se indeksira
}
# review: new
win-no-match-indexing = { $count ->
    [one] Tekst { $count } poruke još se indeksira, pa će uskoro možda biti pronađeno više.
    [few] Tekst { $count } poruke još se indeksira, pa će uskoro možda biti pronađeno više.
   *[other] Tekst { $count } poruka još se indeksira, pa će uskoro možda biti pronađeno više.
}
# review: new
win-files = { $count ->
    [one] { $count } datoteka
    [few] { $count } datoteke
   *[other] { $count } datoteka
}
# review: new
win-click-to-retry = Kliknite ovdje da biste pokušali ponovno.
# review: new
win-save-attachments = &Spremi privitke...
# review: new
win-files-not-saved = Nije moguće spremiti { $failed } od ukupno { $count } datoteka.
# review: new
win-new-folder-in-highlighted = Nova će se mapa stvoriti unutar odabrane mape.
# review: new
win-delete-folder-ask = Izbrisati mapu „{ $folder }“ s njezinim porukama i mapama u njoj? Briše se i na poslužitelju.
# review: new
win-rename = &Preimenuj...
# review: new
win-messages-not-saved = Poruke nije moguće spremiti.
# review: new
win-messages-not-forwarded = Poruke nije moguće proslijediti.

## Accounts

# review: new
win-sign-in-google = Prijava putem Googlea
# review: new
win-sign-in-microsoft = Prijava putem Microsofta
# review: new
win-next = &Dalje >
# review: new
win-your-account = vaš račun
# review: new
win-browser-sign-in = (prijava putem preglednika)
# review: new
win-add = &Dodaj...
# review: new
win-properties-button = &Svojstva...
# review: new
win-signature-button = &Potpis...
# review: new
win-sign-in-apps-button = &Aplikacije za prijavu...

## AI agents

# review: new
win-dont-allow = &Nemoj dopustiti
# review: new
win-col-address = Adresa
# review: new
win-never-written-to = Nikad niste pisali
# review: new
win-book-find-label = Upišite ime ili adresu e-pošte:
# review: new
win-send = &Pošalji
# review: new
win-dont-send = &Nemoj poslati
# review: new
win-forget-program-ask = Ukloniti ovaj program, njegove dozvole i povijest aktivnosti njegovih agenata? Pri sljedećem povezivanju ponovno će se tražiti vaša dozvola.
# review: new
win-clear-log-ask = Očistiti povijest aktivnosti agenata? Time se neće poništiti promjene koje su agenti napravili.
# review: new
win-agent-programs = &Programi čiji su agenti zatražili pristup vašoj pošti:
# review: new
win-change = Pro&mijeni...
# review: new
win-what-agents-did = &Aktivnost agenata:
# review: new
win-how-to-connect = Kako povezati agenta

## Sign-in apps

# review: new
win-built-in = (ugrađena)
# review: new
win-edit = &Uredi...

## Options

# review: new
win-folders-hide = Sakrij popis mapa
# review: new
win-folders-pin = Drži popis mapa uz poruke
# review: new
win-folders-show = Prikaži mape

## The installer

# review: new
win-installer-start = Pokreni Inbox Classic
# review: new
win-installer-welcome-new =
    Instalirat će se Inbox Classic { $version }, program za e-poštu.

    Nisu potrebna administratorska prava, instalira se samo za vaš račun.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } već je instaliran. Ponovno će se instalirati.

    Vaši računi i pošta bit će zadržani.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } ažurirat će se na verziju { $version }.

    Ako je pokrenut, najprije će se zatvoriti. Vaši računi i pošta bit će zadržani.
# review: new
win-installer-older-ask = Instaliran je Inbox Classic { $installed }, koji je noviji od verzije { $version }. Ipak instalirati stariju verziju?
# review: new
win-installer-still-running = Inbox Classic još je pokrenut. Zatvorite ga i pokušajte ponovno.
# review: new
win-installer-remove-mail-ask = Ukloniti i račune i poštu koje Inbox Classic čuva na ovom računalu? Pošta na poslužiteljima ostaje.
