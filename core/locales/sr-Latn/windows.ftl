# Srpski (latinica). Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic i dalje proverava da li ima nove pošte u pozadini. Kliknite na ikonu da biste ga otvorili. Da biste izašli, kliknite desnim tasterom miša na ikonu i upotrebite njen meni.
# review: new
win-default-app-not-installed = Ova kopija programa Inbox Classic nije instalirana, pa je Windows ne navodi kao aplikaciju za poštu. Instalirajte je da biste mogli da je izaberete.
# review: new
win-default-app-settings = Windows će otvoriti podešavanja Podrazumevane aplikacije. Izaberite Inbox Classic za otvaranje MAILTO veza.
# review: new
win-no-unread = Nema nepročitanih poruka
# review: new
win-unread-messages = { $count ->
    [one] { $count } nepročitana poruka
    [few] { $count } nepročitane poruke
   *[other] { $count } nepročitanih poruka
}
# review: new
win-print-failed = Poruku nije moguće odštampati.
# review: new
win-print-title-of = Odštampaj: { $subject }
# review: new
win-no-bodies = Sadržaj poruka ne može da se prikaže.
# review: new
win-webview-failed = Pravljenje komponente WebView2 nije uspelo.
# review: new
win-webview-missing = WebView2 izvršno okruženje nije dostupno.
# review: new
win-list-loading = Učitavanje...

## Buttons and words used in many windows

# review: new
win-delete-button = &Izbriši
# review: new
win-find-label = &Pronađi:
# review: new
win-save-as-button = Sačuvaj &kao...
# review: new
win-too-many-files = Previše datoteka odjednom: izaberite manje.

## The Outbox


## The compose window

# review: new
win-editor-failed = Poruke ne mogu da se pišu.
# review: new
win-ctrl-click-to-open = ({ $ctrl } + klik za otvaranje)
# review: new
win-format-bold = Podebljano ({ $ctrl }+B)
# review: new
win-format-italic = Kurziv ({ $ctrl }+I)
# review: new
win-format-underline = Podvučeno ({ $ctrl }+U)
# review: new
win-format-link = Hiperveza ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = &Bcc
# review: new
win-signature-title = Potpis: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Nema rezultata za „{ $words }“ u svim fasciklama
    [one] { $count } rezultat za „{ $words }“ u svim fasciklama
    [few] { $count } rezultata za „{ $words }“ u svim fasciklama
   *[other] { $count } rezultata za „{ $words }“ u svim fasciklama
}
# review: new
win-search-found-in = { $count ->
    [0] Nema rezultata za „{ $words }“ u fascikli { $folder }
    [one] { $count } rezultat za „{ $words }“ u fascikli { $folder }
    [few] { $count } rezultata za „{ $words }“ u fascikli { $folder }
   *[other] { $count } rezultata za „{ $words }“ u fascikli { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] tekst { $count } poruke se još indeksira
    [few] tekst { $count } poruke se još indeksira
   *[other] tekst { $count } poruka se još indeksira
}
# review: new
win-no-match-indexing = { $count ->
    [one] Tekst { $count } poruke se još indeksira, pa će uskoro možda biti pronađeno više.
    [few] Tekst { $count } poruke se još indeksira, pa će uskoro možda biti pronađeno više.
   *[other] Tekst { $count } poruka se još indeksira, pa će uskoro možda biti pronađeno više.
}
# review: new
win-files = { $count ->
    [one] { $count } datoteka
    [few] { $count } datoteke
   *[other] { $count } datoteka
}
# review: new
win-click-to-retry = Kliknite ovde da biste pokušali ponovo.
# review: new
win-save-attachments = &Sačuvaj priloge...
# review: new
win-files-not-saved = Nije moguće sačuvati { $failed } od ukupno { $count } datoteka.
# review: new
win-new-folder-in-highlighted = Nova fascikla biće napravljena unutar izabrane fascikle.
# review: new
win-delete-folder-ask = Da li želite da izbrišete fasciklu „{ $folder }“ sa njenim porukama i fasciklama u njoj? Briše se i na serveru.
# review: new
win-rename = &Preimenuj...
# review: new
win-messages-not-saved = Poruke nije moguće sačuvati.
# review: new
win-messages-not-forwarded = Poruke nije moguće proslediti.

## Accounts

# review: new
win-sign-in-google = Prijavite se pomoću Google naloga
# review: new
win-sign-in-microsoft = Prijavite se pomoću Microsoft naloga
# review: new
win-next = &Dalje >
# review: new
win-your-account = vaš nalog
# review: new
win-browser-sign-in = (prijava putem pregledača)
# review: new
win-add = &Dodaj...
# review: new
win-properties-button = &Svojstva...
# review: new
win-signature-button = &Potpis...
# review: new
win-sign-in-apps-button = &Aplikacije za prijavljivanje...

## AI agents

# review: new
win-dont-allow = &Nemoj dozvoliti
# review: new
win-col-address = Adresa
# review: new
win-never-written-to = Nikad niste pisali
# review: new
win-book-find-label = Unesite ime ili adresu e-pošte:
# review: new
win-send = &Pošalji
# review: new
win-dont-send = &Nemoj poslati
# review: new
win-unsubscribe = &Otkaži pretplatu
# review: new
win-dont-unsubscribe = &Nemoj otkazati pretplatu
# review: new
win-forget-program-ask = Da li želite da uklonite ovaj program, njegove dozvole i istoriju aktivnosti njegovih agenata? Pri sledećem povezivanju ponovo će se tražiti vaša dozvola.
# review: new
win-clear-log-ask = Da li želite da obrišete istoriju aktivnosti agenata? Time se neće opozvati promene koje su agenti napravili.
# review: new
win-agent-programs = &Programi čiji su agenti zatražili pristup vašoj pošti:
# review: new
win-change = Pro&meni...
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
win-folders-hide = Sakrij listu fascikli
# review: new
win-folders-pin = Drži listu fascikli pored poruka
# review: new
win-folders-show = Prikaži fascikle

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Pokreni Inbox Classic
# review: new
win-installer-welcome-new =
    Instaliraće se Inbox Classic { $version }, program za e-poštu.

    Nisu potrebna administratorska prava, instalira se samo za vaš nalog.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } je već instaliran. Biće ponovo instaliran.

    Vaši nalozi i pošta se čuvaju.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } biće ažuriran na verziju { $version }.

    Ako je pokrenut, najpre će biti zatvoren. Vaši nalozi i pošta se čuvaju.
# review: new
win-installer-older-ask = Instaliran je Inbox Classic { $installed }, koji je noviji od verzije { $version }. Da li ipak želite da instalirate stariju verziju?
# review: new
win-installer-still-running = Inbox Classic je još uvek pokrenut. Zatvorite ga i pokušajte ponovo.
# review: new
win-installer-remove-mail-ask = Da li želite da uklonite i naloge i poštu koje Inbox Classic čuva na ovom računaru? Pošta na serverima ostaje.
