# Srpski (latinica). Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic nastavlja da proverava novu poštu u pozadini. Kliknite na njegovu ikonu u sistemskoj paleti da biste otvorili prozor. Za izlazak iz programa kliknite desnim tasterom miša na ikonu i izaberite Izlaz.
win-default-app-not-installed = Ova kopija programa Inbox Classic nije instalirana. Instalirajte program da biste mogli da ga izaberete kao podrazumevanu aplikaciju za e-poštu u Windowsu.
win-default-app-settings = Windows će otvoriti podešavanja Podrazumevane aplikacije. Izaberite Inbox Classic za otvaranje MAILTO veza.
win-no-unread = Nema nepročitanih poruka
win-unread-messages = { $count ->
    [one] { $count } nepročitana poruka
    [few] { $count } nepročitane poruke
   *[other] { $count } nepročitanih poruka
}
win-print-failed = Poruku nije moguće odštampati.
win-print-title-of = Odštampaj: { $subject }
win-no-bodies = Sadržaj poruka ne može da se prikaže.
win-webview-failed = Prikaz poruka nije moguće pokrenuti (WebView2).
win-webview-missing = Komponenta WebView2 za prikaz poruka nije dostupna.
win-list-loading = Učitavanje...

## Buttons and words used in many windows

win-delete-button = &Izbriši
win-find-label = Pron&ađi:
win-save-as-button = Sačuvaj &kao...
win-too-many-files = Previše datoteka odjednom: izaberite manje.

## The Outbox


## The compose window

win-editor-failed = Uređivač poruka nije moguće pokrenuti.
win-ctrl-click-to-open = ({ $ctrl } + klik za otvaranje)
win-format-bold = Podebljano ({ $ctrl }+B)
win-format-italic = Kurziv ({ $ctrl }+I)
win-format-underline = Podvučeno ({ $ctrl }+U)
win-format-link = Hiperveza ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature-title = Potpis: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Nema rezultata za „{ $words }“ u svim fasciklama
    [one] { $count } rezultat za „{ $words }“ u svim fasciklama
    [few] { $count } rezultata za „{ $words }“ u svim fasciklama
   *[other] { $count } rezultata za „{ $words }“ u svim fasciklama
}
win-search-found-in = { $count ->
    [0] Nema rezultata za „{ $words }“ u fascikli { $folder }
    [one] { $count } rezultat za „{ $words }“ u fascikli { $folder }
    [few] { $count } rezultata za „{ $words }“ u fascikli { $folder }
   *[other] { $count } rezultata za „{ $words }“ u fascikli { $folder }
}
win-search-indexing = { $count ->
    [one] još se indeksira tekst poruka; preostalo: { $count }
    [few] još se indeksira tekst poruka; preostalo: { $count }
   *[other] još se indeksira tekst poruka; preostalo: { $count }
}
win-no-match-indexing = { $count ->
    [one] Indeksiranje teksta nije završeno za još { $count } poruku. Uskoro se može pojaviti više rezultata.
    [few] Indeksiranje teksta nije završeno za još { $count } poruke. Uskoro se može pojaviti više rezultata.
   *[other] Indeksiranje teksta nije završeno; preostalo poruka: { $count }. Uskoro se može pojaviti više rezultata.
}
win-files = { $count ->
    [one] { $count } datoteka
    [few] { $count } datoteke
   *[other] { $count } datoteka
}
win-click-to-retry = Kliknite ovde da biste pokušali ponovo.
win-save-attachments = &Sačuvaj priloge...
win-files-not-saved = Ukupno datoteka: { $count }; nije sačuvano: { $failed }.
win-new-folder-in-highlighted = Nova fascikla biće napravljena unutar izabrane fascikle.
win-delete-folder-ask = Da li želite da izbrišete fasciklu „{ $folder }“ sa njenim porukama i fasciklama u njoj? Briše se i na serveru.
win-rename = &Preimenuj...
win-messages-not-saved = Poruke nije moguće sačuvati.
win-messages-not-forwarded = Poruke nije moguće proslediti.

## Accounts

win-sign-in-google = Prijavite se pomoću Google naloga
win-sign-in-microsoft = Prijavite se pomoću Microsoft naloga
win-next = &Dalje >
win-your-account = vaš nalog
win-browser-sign-in = (prijava putem pregledača)
win-add = &Dodaj...
win-properties-button = &Svojstva...
win-signature-button = &Potpis...
win-sign-in-apps-button = &Aplikacije za prijavljivanje...

## AI agents

win-dont-allow = &Nemoj dozvoliti
win-col-address = Adresa
win-never-written-to = Nikad niste pisali
win-book-find-label = Unesite ime ili adresu e-pošte:
win-send = &Pošalji
win-dont-send = &Nemoj poslati
win-unsubscribe = &Otkaži pretplatu
win-dont-unsubscribe = &Nemoj otkazati pretplatu
win-forget-program-ask = Da li želite da uklonite ovaj program, njegove dozvole i istoriju aktivnosti njegovih agenata? Pri sledećem povezivanju ponovo će se tražiti vaša dozvola.
win-clear-log-ask = Da li želite da obrišete istoriju aktivnosti agenata? Time se neće opozvati promene koje su agenti napravili.
win-agent-programs = &Programi čiji su agenti zatražili pristup vašoj pošti:
win-change = Pro&meni...
win-what-agents-did = &Aktivnost agenata:
# review: new
win-agent-reads = Šta je pročitano od { $from } do { $to }:
# review: new
win-agent-reads-hint = Izaberite gore red sa čitanjima da vidite šta je pročitano.
win-how-to-connect = Kako povezati agenta

## Sign-in apps

win-built-in = (ugrađena)
win-edit = &Uredi...

## Options

win-folders-hide = Sakrij listu fascikli
win-folders-pin = Drži listu fascikli pored poruka
win-folders-show = Prikaži fascikle

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Pokreni Inbox Classic
win-installer-welcome-new =
    Biće instaliran program za e-poštu Inbox Classic { $version }.

    Nisu potrebna administratorska prava. Program se instalira samo za vaš korisnički nalog u Windowsu.
win-installer-welcome-same =
    Inbox Classic { $version } je već instaliran. Biće ponovo instaliran.

    Vaši nalozi i preuzeta pošta biće sačuvani.
win-installer-welcome-update =
    Inbox Classic { $installed } biće ažuriran na verziju { $version }.

    Ako je pokrenut, najpre će biti zatvoren. Vaši nalozi i preuzeta pošta biće sačuvani.
win-installer-older-ask = Instaliran je Inbox Classic { $installed }, koji je noviji od verzije { $version }. Da li ipak želite da instalirate stariju verziju?
win-installer-still-running = Inbox Classic je još uvek pokrenut. Zatvorite ga i pokušajte ponovo.
win-installer-remove-mail-ask = Da li želite da uklonite i naloge i lokalne kopije poruka sa ovog računara? Pošta ostaje na serverima.
