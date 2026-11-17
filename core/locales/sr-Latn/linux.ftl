# Srpski (latinica). Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = Pretraga obuhvata teme, pošiljaoce, primaoce, nazive priloga i tekst poruka. Opseg pretrage: { $place }. Proverite pravopis ili pokušajte sa manje reči.
gtk-search-still-indexing = { $count ->
    [one] Indeksiranje teksta još traje; preostalo poruka: { $count }. Uskoro se može pojaviti više rezultata.
    [few] Indeksiranje teksta još traje; preostalo poruka: { $count }. Uskoro se može pojaviti više rezultata.
   *[other] Indeksiranje teksta još traje; preostalo poruka: { $count }. Uskoro se može pojaviti više rezultata.
}
gtk-search-results-everywhere = { $count ->
    [0] Nema rezultata
    [one] { $count } rezultat
    [few] { $count } rezultata
   *[other] { $count } rezultata
} za „{ $words }“ u svim fasciklama
gtk-search-results-in = { $count ->
    [0] Nema rezultata
    [one] { $count } rezultat
    [few] { $count } rezultata
   *[other] { $count } rezultata
} za „{ $words }“ (opseg: { $place })
gtk-search-indexing = { $count ->
    [one] još se indeksira tekst poruka; preostalo: { $count }
    [few] još se indeksira tekst poruka; preostalo: { $count }
   *[other] još se indeksira tekst poruka; preostalo: { $count }
}
gtk-list-loading = Učitavanje...
gtk-menu-rename = Preimenuj...
gtk-import-one-question = Da li želite da uvezete poruku { $file } u fasciklu { $folder }?
gtk-files-not-saved = Ukupno datoteka: { $total }; nije sačuvano: { $failed }.
gtk-unsubscribe-one-click =
    Da li želite da se odjavite sa ove liste za slanje?

    Inbox Classic će poslati zahtev za otkazivanje pretplate na { $target }. Neće se otvoriti nijedna veb-stranica niti će biti poslata poruka e-pošte.
gtk-unsubscribe-mail =
    Da li želite da se odjavite sa ove liste za slanje?

    Da biste otkazali pretplatu, pošaljite poruku e-pošte na { $target }. Inbox Classic će je pripremiti za vas. Pošaljite poruku kao potvrdu.
gtk-unsubscribe-web =
    Da li želite da se odjavite sa ove liste za slanje?

    Stranica za odjavu sa liste otvoriće se u pregledaču ({ $target }).
gtk-unsubscribe-failed = Otkazivanje pretplate nije uspelo: { $problem }
gtk-toolbar-create-mail-menu = Napiši poruku sa određenog naloga
gtk-toolbar-send-recv-menu = Pošalji i primi poštu za određeni nalog
gtk-main-menu = Glavni meni
gtk-folder-list = Lista fascikli
gtk-quit = Izađi

## The Move and Copy window

gtk-new-folder-at-top-of = Nova fascikla biće napravljena na najvišem nivou naloga { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Nema nepročitanih poruka
    [one] { $count } nepročitana poruka
    [few] { $count } nepročitane poruke
   *[other] { $count } nepročitanih poruka
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Nijedna poruka ne čeka na slanje.
gtk-outbox-row = Za: { $to }  ·  Dodato u red: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic i dalje proverava da li ima nove pošte u pozadini. Pomoću njegove ikone na gornjoj traci otvorite aplikaciju ili izađite iz nje.
gtk-sign-in-again-ask =
    Prijava na nalog { $account } je odbijena ili je sesija istekla.

    Da li želite ponovo da se prijavite u pregledaču?
gtk-default-app-not-installed = Ova kopija programa Inbox Classic nije instalirana. Instalirajte program da biste mogli da ga izaberete kao podrazumevanu aplikaciju za e-poštu.
gtk-default-app-now = Inbox Classic je sada podrazumevana aplikacija za e-poštu. Veze ka adresama e-pošte otvaraju novu poruku u ovom programu.
gtk-default-app-failed = Inbox Classic nije moguće postaviti kao podrazumevanu aplikaciju za poštu.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Datum:
gtk-reader-files = Prilozi poruke
gtk-files = { $count ->
    [one] { $count } datoteka
    [few] { $count } datoteke
   *[other] { $count } datoteka
}
gtk-pictures-blocked = Neke slike su blokirane da bi se sprečilo praćenje.
gtk-download-pictures = Preuzmi slike
gtk-save-attachments-menu = Sačuvaj priloge...

## The compose window

gtk-format-bold = Podebljano (Ctrl+B)
gtk-format-italic = Kurziv (Ctrl+I)
gtk-format-underline = Podvučeno (Ctrl+U)
gtk-format-hyperlink = Hiperveza (Ctrl+K)
gtk-font = Font
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Sačuvaj (Ctrl+S)
gtk-link-status = { $link }    (Ctrl + klik za otvaranje)

## Accounts

gtk-plain-warning =
    Bez šifrovanja svako ko presretne vaš mrežni saobraćaj može da pročita vašu lozinku i poruke. Ovu vezu koristite samo sa serverom na svom računaru ili u lokalnoj mreži.

    Da li želite da nastavite?
gtk-account-name-title = Naziv naloga
gtk-display-name-title = Ime za prikaz
gtk-turned-off-why = Opcija „{ $button }“ je isključena na ovom računaru. { $reason }
gtk-turned-off-why-long =
    Opcija „{ $button }“ je isključena na ovom računaru.

    { $reason }
gtk-next = Dalje >
# review: changed
gtk-provider-sign-in = { $provider }: Prijavite se na nalog { $address } na veb-sajtu pružaoca usluge. Inbox Classic ne dobija vašu lozinku. Možete da koristite i lozinku za aplikaciju napravljenu u bezbednosnim podešavanjima naloga.
# review: changed
gtk-provider-sign-in-apps = { $provider }: Prijavite se na nalog { $address } na veb-sajtu pružaoca usluge pomoću jedne od svojih aplikacija za prijavljivanje (Još opcija za prijavljivanje). Možete da koristite i lozinku za aplikaciju napravljenu u bezbednosnim podešavanjima naloga.
gtk-accounts-add = Dodaj...
gtk-accounts-properties = Svojstva...
gtk-accounts-signature = Potpis...
gtk-accounts-sign-in-apps = Aplikacije za prijavljivanje...

## Sign-in apps

gtk-app-server = { $kind } server
gtk-app-port = { $kind } port
gtk-app-security = { $kind } bezbednost
gtk-issuer-found =
    Stranica za prijavu: { $page }
    Adresa za dobijanje tokena: { $endpoint }
gtk-client-id = ID klijenta
gtk-client-secret = Tajna klijenta
gtk-scopes = Opsezi (scopes)
gtk-redirect-uri = URI za preusmeravanje
gtk-issuer-usable =
    Izdavalac može da se koristi.

    { $found }
gtk-app-built-in = Aplikacija { $app } je ugrađena. Možete samo da promenite da li se nudi za nove naloge. { $reason }
gtk-built-in = { $app } (ugrađena)
gtk-offered-for-new = Nudi se za nove naloge
gtk-edit-button = Uredi...
gtk-remove-app-ask = Da li želite da uklonite aplikaciju za prijavljivanje { $app } i njenu sačuvanu tajnu klijenta?
gtk-sign-in-apps-intro = Aplikacije za prijavljivanje omogućavaju nalozima da se prijave putem pregledača. Aplikacija koja je isključena ne nudi se za nove naloge; nalozi koji je već koriste i dalje rade.

## AI agents

gtk-agent-it-may = Dozvoljene radnje
gtk-agent-accounts = Dozvoljeni nalozi
gtk-never-used = Nikad nije korišćeno
gtk-last-used = Poslednja upotreba: { $date }
gtk-forget-program = Da li želite da uklonite ovaj program?
gtk-forget-program-detail = Dozvole programa i istorija aktivnosti njegovih agenata biće izbrisane. Pri sledećem povezivanju ponovo će se tražiti vaša dozvola.
gtk-no-agents-yet = Još nijedan agent nije zatražio pristup vašoj pošti.
gtk-nothing-yet = Zasad ništa.

## Preferences

gtk-preferences = Podešavanja
gtk-notify-subtitle = Samo dok je Inbox Classic u pozadini

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Klijent e-pošte
gtk-desktop-comment = Čitajte i pišite e-poštu: brz i jednostavan program za poštu
gtk-desktop-keywords = pošta;e-pošta;poruke;prijemno sanduče;klijent e-pošte;
gtk-metainfo-summary = Brz i jednostavan program za poštu
gtk-metainfo-description = Inbox Classic je program za e-poštu sa fasciklama levo, listom poruka gore i prikazom izabrane poruke ispod. Podržava IMAP i SMTP naloge, kao i prijavu na Outlook.com i Microsoft 365 putem pregledača.
gtk-metainfo-feature-sanitized = Poruke se prikazuju bez skripti i drugog nebezbednog sadržaja. Slike sa interneta preuzimaju se samo uz vašu dozvolu
gtk-metainfo-feature-search = Pretraga tema, pošiljalaca, primalaca, naziva priloga i teksta poruka, uz operatore kao u Gmailu
gtk-metainfo-feature-replies = Citirane poruke u odgovorima su sažete i mogu da se prošire po potrebi
gtk-metainfo-feature-offline = Čitajte preuzetu poštu i bez interneta. Lozinke se čuvaju u sistemskom privesku ključeva
