# Hrvatski. Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

## The main window

win-still-running-detail = Inbox Classic i dalje provjerava novu poštu u pozadini. Kliknite ikonu da biste ga otvorili. Da biste izašli, desnom tipkom miša kliknite ikonu i upotrijebite njezin izbornik.
win-default-app-not-installed = Ova kopija programa Inbox Classic nije instalirana, pa je Windows ne navodi kao aplikaciju za poštu. Instalirajte je da biste je mogli odabrati.
win-default-app-settings = U postavkama sustava Windows otvorit će se odjeljak Zadane aplikacije. Odaberite Inbox Classic za otvaranje poveznica MAILTO.
win-no-unread = Nema nepročitanih poruka
win-unread-messages = { $count ->
    [one] { $count } nepročitana poruka
    [few] { $count } nepročitane poruke
   *[other] { $count } nepročitanih poruka
}
win-print-failed = Poruku nije moguće ispisati.
win-print-title-of = Ispis: { $subject }
win-no-bodies = Sadržaj poruka nije moguće prikazati.
win-webview-failed = Komponentu WebView2 nije moguće pokrenuti.
win-webview-missing = Okruženje za izvođenje WebView2 nije dostupno.
win-list-loading = Učitavanje...

## Buttons and words used in many windows

win-delete-button = &Izbriši
win-find-label = &Traži:
win-save-as-button = Spremi k&ao...
win-too-many-files = Previše datoteka odjednom: odaberite manje.

## The compose window

win-editor-failed = Uređivač poruka nije moguće pokrenuti.
win-ctrl-click-to-open = ({ $ctrl } + klik za otvaranje)
win-format-bold = Podebljano ({ $ctrl }+B)
win-format-italic = Kurziv ({ $ctrl }+I)
win-format-underline = Podcrtano ({ $ctrl }+U)
win-format-link = Hiperveza ({ $ctrl }+K)
win-show-cc = &Kopija
win-show-bcc = &Skrivena kopija
win-signature-title = Potpis: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Nema rezultata za „{ $words }“ u svim mapama
    [one] { $count } rezultat za „{ $words }“ u svim mapama
    [few] { $count } rezultata za „{ $words }“ u svim mapama
   *[other] { $count } rezultata za „{ $words }“ u svim mapama
}
win-search-found-in = { $count ->
    [0] Nema rezultata za „{ $words }“ u mapi { $folder }
    [one] { $count } rezultat za „{ $words }“ u mapi { $folder }
    [few] { $count } rezultata za „{ $words }“ u mapi { $folder }
   *[other] { $count } rezultata za „{ $words }“ u mapi { $folder }
}
win-search-indexing = { $count ->
    [one] tekst poruka još se indeksira (preostalo: { $count })
    [few] tekst poruka još se indeksira (preostalo: { $count })
   *[other] tekst poruka još se indeksira (preostalo: { $count })
}
win-no-match-indexing = { $count ->
    [one] Još traje indeksiranje teksta poruka (preostalo: { $count }). Uskoro se može pojaviti više rezultata.
    [few] Još traje indeksiranje teksta poruka (preostalo: { $count }). Uskoro se može pojaviti više rezultata.
   *[other] Još traje indeksiranje teksta poruka (preostalo: { $count }). Uskoro se može pojaviti više rezultata.
}
win-files = { $count ->
    [one] { $count } datoteka
    [few] { $count } datoteke
   *[other] { $count } datoteka
}
win-click-to-retry = Kliknite ovdje da biste pokušali ponovno.
win-save-attachments = &Spremi privitke...
win-files-not-saved = Broj datoteka koje nije moguće spremiti: { $failed } od ukupno { $count }.
win-new-folder-in-highlighted = Nova će se mapa stvoriti unutar odabrane mape.
win-delete-folder-ask = Želite li izbrisati mapu „{ $folder }“, njezine poruke i podmape? Izbrisat će se i na poslužitelju.
win-rename = &Preimenuj...
win-messages-not-saved = Poruke nije moguće spremiti.
win-messages-not-forwarded = Poruke nije moguće proslijediti.

## Accounts

win-sign-in-google = Prijava putem Googlea
win-sign-in-microsoft = Prijava putem Microsofta
win-next = &Dalje >
win-your-account = vaš račun
win-browser-sign-in = (prijava putem preglednika)
win-add = &Dodaj...
win-properties-button = &Svojstva...
win-signature-button = &Potpis...
win-sign-in-apps-button = &Aplikacije za prijavu...

## AI agents

win-dont-allow = &Nemoj dopustiti
win-col-address = Adresa
win-never-written-to = Nikad niste pisali
win-book-find-label = Upišite ime ili adresu e-pošte:
win-send = &Pošalji
win-dont-send = &Nemoj poslati
win-unsubscribe = &Otkaži pretplatu
win-dont-unsubscribe = &Nemoj otkazati pretplatu
win-forget-program-ask = Želite li ukloniti ovaj program s popisa, zajedno s njegovim dozvolama i poviješću aktivnosti agenata? Pri sljedećem povezivanju ponovno će se tražiti vaša dozvola.
win-clear-log-ask = Želite li izbrisati povijest aktivnosti agenata? Time se neće poništiti promjene koje su agenti napravili.
win-agent-programs = &Programi čiji su agenti zatražili pristup vašoj pošti:
win-change = Pro&mijeni...
win-what-agents-did = &Aktivnost agenata:
# review: new
win-agent-reads = Što je pročitano od { $from } do { $to }:
# review: new
win-agent-reads-hint = Odaberite gore redak s čitanjima da vidite što je pročitano.
win-how-to-connect = Kako povezati agenta

## Sign-in apps

win-built-in = (ugrađena)
win-edit = &Uredi...

## Options

win-folders-hide = Sakrij popis mapa
win-folders-pin = Zadrži popis mapa uz poruke
win-folders-show = Prikaži mape

## The installer

win-installer-start = Pokreni Inbox Classic
win-installer-welcome-new =
    Instalirat će se Inbox Classic { $version }, program za e-poštu.

    Nisu potrebna administratorska prava. Program će se instalirati samo za vaš korisnički račun u sustavu Windows.
win-installer-welcome-same =
    Inbox Classic { $version } već je instaliran. Ponovno će se instalirati.

    Vaši računi i pošta ostat će sačuvani.
win-installer-welcome-update =
    Inbox Classic { $installed } ažurirat će se na verziju { $version }.

    Ako je pokrenut, najprije će se zatvoriti. Vaši računi i pošta ostat će sačuvani.
win-installer-older-ask = Instalirana verzija programa Inbox Classic ({ $installed }) novija je od verzije { $version }. Želite li ipak instalirati stariju verziju?
win-installer-still-running = Inbox Classic još je pokrenut. Zatvorite ga i pokušajte ponovno.
win-installer-remove-mail-ask = Želite li ukloniti i postavke računa te poštu koju Inbox Classic čuva na ovom računalu? Pošta na poslužiteljima ostat će sačuvana.
