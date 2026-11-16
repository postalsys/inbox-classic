# Srpski (latinica). Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

# review: new
gtk-search-looks-in = Pretraga u { $place } obuhvata teme, pošiljaoce, primaoce, nazive priloga i tekst poruka. Proverite pravopis ili pokušajte sa manje reči.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Tekst { $count } poruke se još indeksira. Uskoro bi moglo da se pojavi više rezultata.
    [few] Tekst { $count } poruke se još indeksira. Uskoro bi moglo da se pojavi više rezultata.
   *[other] Tekst { $count } poruka se još indeksira. Uskoro bi moglo da se pojavi više rezultata.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Nema rezultata
    [one] { $count } rezultat
    [few] { $count } rezultata
   *[other] { $count } rezultata
} za „{ $words }“ u svim fasciklama
# review: new
gtk-search-results-in = { $count ->
    [0] Nema rezultata
    [one] { $count } rezultat
    [few] { $count } rezultata
   *[other] { $count } rezultata
} za „{ $words }“ u { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] tekst { $count } poruke se još indeksira
    [few] tekst { $count } poruke se još indeksira
   *[other] tekst { $count } poruka se još indeksira
}
# review: new
gtk-list-loading = Učitavanje...
# review: new
gtk-menu-rename = Preimenuj...
# review: new
gtk-import-one-question = Da li želite da uvezete poruku { $file } u fasciklu { $folder }?
# review: new
gtk-files-not-saved = Nije moguće sačuvati { $failed } od ukupno { $total } datoteka.
# review: new
gtk-unsubscribe-one-click =
    Da li želite da napustite ovu listu za slanje?

    Inbox Classic će poslati zahtev za otkazivanje pretplate na { $target }. Neće se otvoriti nijedna veb-stranica niti će biti poslata poruka e-pošte.
# review: new
gtk-unsubscribe-mail =
    Da li želite da napustite ovu listu za slanje?

    Da biste otkazali pretplatu, pošaljite poruku e-pošte na { $target }. Inbox Classic će je pripremiti za vas. Pošaljite poruku kao potvrdu.
# review: new
gtk-unsubscribe-web =
    Da li želite da napustite ovu listu za slanje?

    Stranica liste za slanje za otkazivanje pretplate otvoriće se u pregledaču ({ $target }).
# review: new
gtk-unsubscribe-failed = Otkazivanje pretplate nije uspelo: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Napiši poruku sa određenog naloga
# review: new
gtk-toolbar-send-recv-menu = Pošalji i primi poštu za određeni nalog
# review: new
gtk-main-menu = Glavni meni
# review: new
gtk-folder-list = Lista fascikli
# review: new
gtk-quit = Izađi

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Nova fascikla ide na najviši nivo naloga { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Nema nepročitanih poruka
    [one] { $count } nepročitana poruka
    [few] { $count } nepročitane poruke
   *[other] { $count } nepročitanih poruka
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Nijedna poruka ne čeka na slanje.
# review: new
gtk-outbox-row = Za: { $to }  ·  Stavljeno u red { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic i dalje proverava da li ima nove pošte u pozadini. Pomoću njegove ikone na gornjoj traci otvorite aplikaciju ili izađite iz nje.
# review: new
gtk-sign-in-again-ask =
    Prijava na nalog { $account } je odbijena ili je sesija istekla.

    Da li želite ponovo da se prijavite u pregledaču?
# review: new
gtk-default-app-not-installed = Ova kopija programa Inbox Classic nije instalirana, pa je sistem ne navodi kao aplikaciju za poštu. Instalirajte je da biste mogli da je izaberete.
# review: new
gtk-default-app-now = Inbox Classic je sada vaša podrazumevana aplikacija za poštu: veze e-pošte ovde otvaraju novu poruku.
# review: new
gtk-default-app-failed = Inbox Classic nije moguće postaviti kao podrazumevanu aplikaciju za poštu.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Datum:
# review: new
gtk-reader-files = Prilozi poruke
# review: new
gtk-files = { $count ->
    [one] { $count } datoteka
    [few] { $count } datoteke
   *[other] { $count } datoteka
}
# review: new
gtk-pictures-blocked = Neke slike su blokirane da pošiljalac ne bi mogao da prepozna vaš računar.
# review: new
gtk-download-pictures = Preuzmi slike
# review: new
gtk-save-attachments-menu = Sačuvaj priloge...

## The compose window

# review: new
gtk-format-bold = Podebljano (Ctrl+B)
# review: new
gtk-format-italic = Kurziv (Ctrl+I)
# review: new
gtk-format-underline = Podvučeno (Ctrl+U)
# review: new
gtk-format-hyperlink = Hiperveza (Ctrl+K)
# review: new
gtk-font = Font
# review: new
gtk-show-cc = _Cc
# review: new
gtk-show-bcc = _Bcc
# review: new
gtk-save-tip = Sačuvaj (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl + klik za otvaranje)

## Accounts

# review: new
gtk-plain-warning =
    Bez šifrovanja svako ko presretne vaš mrežni saobraćaj može da pročita vašu lozinku i poruke. Ovu vezu koristite samo sa serverom na svom računaru ili u lokalnoj mreži.

    Da li želite da nastavite?
# review: new
gtk-account-name-title = Naziv naloga
# review: new
gtk-display-name-title = Ime za prikaz
# review: new
gtk-turned-off-why = Opcija „{ $button }“ je isključena na ovom računaru. { $reason }
# review: new
gtk-turned-off-why-long =
    Opcija „{ $button }“ je isključena na ovom računaru.

    { $reason }
# review: new
gtk-next = Dalje >
# review: new
gtk-provider-sign-in = Prijavite se na { $address } na veb-sajtu dobavljača usluge ({ $provider }). Vaša lozinka se ne deli sa programom Inbox Classic. Možete da koristite i lozinku za aplikaciju napravljenu u bezbednosnim podešavanjima naloga.
# review: new
gtk-provider-sign-in-apps = Prijavite se na { $address } na veb-sajtu dobavljača usluge ({ $provider }) nekom od svojih aplikacija za prijavljivanje (Još opcija za prijavljivanje). Možete da koristite i lozinku za aplikaciju napravljenu u bezbednosnim podešavanjima naloga.
# review: new
gtk-accounts-add = Dodaj...
# review: new
gtk-accounts-properties = Svojstva...
# review: new
gtk-accounts-signature = Potpis...
# review: new
gtk-accounts-sign-in-apps = Aplikacije za prijavljivanje...

## Sign-in apps

# review: new
gtk-app-server = { $kind } server
# review: new
gtk-app-port = { $kind } port
# review: new
gtk-app-security = { $kind } bezbednost
# review: new
gtk-issuer-found =
    Stranica za prijavu: { $page }
    Krajnja tačka tokena: { $endpoint }
# review: new
gtk-client-id = ID klijenta
# review: new
gtk-client-secret = Tajna klijenta
# review: new
gtk-scopes = Opsezi (scopes)
# review: new
gtk-redirect-uri = URI za preusmeravanje
# review: new
gtk-issuer-usable =
    Izdavalac može da se koristi.

    { $found }
# review: new
gtk-app-built-in = Aplikacija { $app } je ugrađena. Možete samo da promenite da li se nudi za nove naloge. { $reason }
# review: new
gtk-built-in = { $app } (ugrađena)
# review: new
gtk-offered-for-new = Nudi se za nove naloge
# review: new
gtk-edit-button = Uredi...
# review: new
gtk-remove-app-ask = Da li želite da uklonite aplikaciju za prijavljivanje { $app } i njenu sačuvanu tajnu klijenta?
# review: new
gtk-sign-in-apps-intro = Aplikacije za prijavljivanje omogućavaju nalozima da se prijave putem pregledača. Aplikacija koja je isključena ne nudi se za nove naloge; nalozi koji je već koriste i dalje rade.

## AI agents

# review: new
gtk-agent-it-may = Dozvoljene radnje
# review: new
gtk-agent-accounts = Dozvoljeni nalozi
# review: new
gtk-never-used = Nikad nije korišćeno
# review: new
gtk-last-used = Poslednja upotreba: { $date }
# review: new
gtk-forget-program = Da li želite da uklonite ovaj program?
# review: new
gtk-forget-program-detail = Dozvole programa i istorija aktivnosti njegovih agenata biće izbrisane. Pri sledećem povezivanju ponovo će se tražiti vaša dozvola.
# review: new
gtk-no-agents-yet = Još nijedan agent nije zatražio pristup vašoj pošti.
# review: new
gtk-nothing-yet = Zasad ništa.

## Preferences

# review: new
gtk-preferences = Podešavanja
# review: new
gtk-language-subtitle = Jezik aplikacije i pomoći
# review: new
gtk-notify-subtitle = Obaveštenje kada stignu nove poruke dok je prozor u pozadini

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Klijent e-pošte
# review: new
gtk-desktop-comment = Čitajte i pišite e-poštu: brz i jednostavan program za poštu
# review: new
gtk-desktop-keywords = pošta;e-pošta;poruke;prijemno sanduče;klijent e-pošte;
# review: new
gtk-metainfo-summary = Brz i jednostavan program za poštu
# review: new
gtk-metainfo-description = Inbox Classic čita i piše e-poštu sa fasciklama sa leve strane, porukama na vrhu i porukom ispod, kao što su to nekada radili programi za poštu. Radi sa svakim IMAP i SMTP nalogom, a na Outlook.com i Microsoft 365 prijavljuje se putem pregledača.
# review: new
gtk-metainfo-feature-sanitized = Svaka poruka se prikazuje prečišćena, bez skripti, a slike sa interneta samo kada ih dozvolite
# review: new
gtk-metainfo-feature-search = Pretraga koja pronalazi reči u temi, imenima ljudi, nazivima datoteka i tekstu, sa Gmail operatorima
# review: new
gtk-metainfo-feature-replies = Odgovori skupljaju ranije poruke koje citiraju
# review: new
gtk-metainfo-feature-offline = Pošta ostaje čitljiva i bez veze sa internetom; lozinke se čuvaju u vašem privesku ključeva
