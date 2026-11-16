# Hrvatski. Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

## The main window

# review: new
gtk-search-looks-in = Pretraživanje u mapi { $place } obuhvaća predmete, pošiljatelje, primatelje, nazive privitaka i tekst poruka. Provjerite pravopis ili pokušajte s manje riječi.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Tekst { $count } poruke još se indeksira. Uskoro se možda pojavi više rezultata.
    [few] Tekst { $count } poruke još se indeksira. Uskoro se možda pojavi više rezultata.
   *[other] Tekst { $count } poruka još se indeksira. Uskoro se možda pojavi više rezultata.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Nema rezultata
    [one] { $count } rezultat
    [few] { $count } rezultata
   *[other] { $count } rezultata
} za „{ $words }“ u svim mapama
# review: new
gtk-search-results-in = { $count ->
    [0] Nema rezultata
    [one] { $count } rezultat
    [few] { $count } rezultata
   *[other] { $count } rezultata
} za „{ $words }“ (mjesto: { $place })
# review: new
gtk-search-indexing = { $count ->
    [one] tekst { $count } poruke još se indeksira
    [few] tekst { $count } poruke još se indeksira
   *[other] tekst { $count } poruka još se indeksira
}
# review: new
gtk-menu-rename = Preimenuj...
# review: new
gtk-import-one-question = Uvesti poruku { $file } u mapu { $folder }?
# review: new
gtk-files-not-saved = Nije moguće spremiti { $failed } od ukupno { $total } datoteka.
# review: new
gtk-unsubscribe-one-click =
    Napustiti ovaj popis za slanje?

    Inbox Classic poslat će zahtjev za otkazivanje pretplate na { $target }. Neće se otvoriti nijedna web-stranica niti će se poslati poruka e-pošte.
# review: new
gtk-unsubscribe-mail =
    Napustiti ovaj popis za slanje?

    Da biste otkazali pretplatu, pošaljite poruku e-pošte na { $target }. Inbox Classic pripremit će je za vas. Pošaljite poruku kao potvrdu.
# review: new
gtk-unsubscribe-web =
    Napustiti ovaj popis za slanje?

    Stranica za otkazivanje pretplate na popis za slanje otvorit će se u pregledniku ({ $target }).
# review: new
gtk-unsubscribe-failed = Otkazivanje pretplate nije uspjelo: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Napiši poruku s određenog računa
# review: new
gtk-toolbar-send-recv-menu = Pošalji i primi poštu za određeni račun
# review: new
gtk-main-menu = Glavni izbornik
# review: new
gtk-folder-list = Popis mapa
# review: new
gtk-quit = Zatvori

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Nova mapa ide na najvišu razinu računa { $account }.

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Nema nepročitanih poruka
    [one] { $count } nepročitana poruka
    [few] { $count } nepročitane poruke
   *[other] { $count } nepročitanih poruka
}

## The Outbox

# review: new
gtk-outbox-empty = Nijedna poruka ne čeka na slanje.
# review: new
gtk-outbox-row = Za: { $to }  ·  U redu čekanja od { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic i dalje provjerava novu poštu u pozadini. Njegovom ikonom na gornjoj traci otvorite ili zatvorite aplikaciju.
# review: new
gtk-sign-in-again-ask =
    Prijava na račun { $account } odbijena je ili je sesija istekla.

    Ponovno se prijaviti u pregledniku?
# review: new
gtk-default-app-not-installed = Ova kopija programa Inbox Classic nije instalirana, pa je sustav ne navodi kao aplikaciju za poštu. Instalirajte je da biste je mogli odabrati.
# review: new
gtk-default-app-now = Inbox Classic sada je vaša zadana aplikacija za poštu: poveznice e-pošte ovdje otvaraju novu poruku.
# review: new
gtk-default-app-failed = Inbox Classic nije moguće postaviti kao zadanu aplikaciju za poštu.

## The reading pane

# review: new
gtk-reader-date = Datum:
# review: new
gtk-reader-files = Privici poruke
# review: new
gtk-files = { $count ->
    [one] { $count } datoteka
    [few] { $count } datoteke
   *[other] { $count } datoteka
}
# review: new
gtk-pictures-blocked = Neke su slike blokirane kako pošiljatelj ne bi mogao prepoznati vaše računalo.
# review: new
gtk-download-pictures = Preuzmi slike
# review: new
gtk-save-attachments-menu = Spremi privitke...

## The compose window

# review: new
gtk-format-bold = Podebljano (Ctrl+B)
# review: new
gtk-format-italic = Kurziv (Ctrl+I)
# review: new
gtk-format-underline = Podcrtano (Ctrl+U)
# review: new
gtk-format-hyperlink = Hiperveza (Ctrl+K)
# review: new
gtk-font = Font
# review: new
gtk-show-cc = _Kopija
# review: new
gtk-show-bcc = _Skrivena kopija
# review: new
gtk-save-tip = Spremi (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl + klik za otvaranje)

## Accounts

# review: new
gtk-plain-warning =
    Bez šifriranja svatko tko presretne vaš mrežni promet može pročitati vašu lozinku i poruke. Ovu vezu koristite samo s poslužiteljem na vlastitom računalu ili u lokalnoj mreži.

    Nastaviti?
# review: new
gtk-account-name-title = Naziv računa
# review: new
gtk-display-name-title = Ime za prikaz
# review: new
gtk-turned-off-why = Mogućnost „{ $button }“ isključena je na ovom računalu. { $reason }
# review: new
gtk-turned-off-why-long =
    Mogućnost „{ $button }“ isključena je na ovom računalu.

    { $reason }
# review: new
gtk-next = Dalje >
# review: new
gtk-provider-sign-in = Prijavite se na { $address } na web-mjestu davatelja usluge ({ $provider }). Vaša se lozinka ne dijeli s programom Inbox Classic. Možete koristiti i lozinku za aplikaciju stvorenu u sigurnosnim postavkama računa.
# review: new
gtk-provider-sign-in-apps = Prijavite se na { $address } na web-mjestu davatelja usluge ({ $provider }) nekom od svojih aplikacija za prijavu (Još mogućnosti prijave). Možete koristiti i lozinku za aplikaciju stvorenu u sigurnosnim postavkama računa.
# review: new
gtk-accounts-add = Dodaj...
# review: new
gtk-accounts-properties = Svojstva...
# review: new
gtk-accounts-signature = Potpis...
# review: new
gtk-accounts-sign-in-apps = Aplikacije za prijavu...

## Sign-in apps

# review: new
gtk-app-server = { $kind } poslužitelj
# review: new
gtk-app-port = { $kind } priključak
# review: new
gtk-app-security = { $kind } sigurnost
# review: new
gtk-issuer-found =
    Stranica za prijavu: { $page }
    Krajnja točka tokena: { $endpoint }
# review: new
gtk-client-id = ID klijenta
# review: new
gtk-client-secret = Tajna klijenta
# review: new
gtk-scopes = Dozvole (scopes)
# review: new
gtk-redirect-uri = URI za preusmjeravanje
# review: new
gtk-issuer-usable =
    Izdavatelj se može koristiti.

    { $found }
# review: new
gtk-app-built-in = Aplikacija { $app } je ugrađena. Možete samo promijeniti nudi li se za nove račune. { $reason }
# review: new
gtk-built-in = { $app } (ugrađena)
# review: new
gtk-offered-for-new = Nudi se za nove račune
# review: new
gtk-edit-button = Uredi...
# review: new
gtk-remove-app-ask = Ukloniti aplikaciju za prijavu { $app } i njezinu spremljenu tajnu klijenta?
# review: new
gtk-sign-in-apps-intro = Aplikacije za prijavu omogućuju računima prijavu putem preglednika. Aplikacija koja je isključena ne nudi se za nove račune; računi koji je već koriste i dalje rade.

## AI agents

# review: new
gtk-agent-it-may = Dopuštene radnje
# review: new
gtk-agent-accounts = Dopušteni računi
# review: new
gtk-never-used = Nikad korišteno
# review: new
gtk-last-used = Zadnje korišteno { $date }
# review: new
gtk-forget-program = Ukloniti ovaj program?
# review: new
gtk-forget-program-detail = Dozvole programa i povijest aktivnosti njegovih agenata bit će izbrisane. Pri sljedećem povezivanju ponovno će se tražiti vaša dozvola.
# review: new
gtk-no-agents-yet = Još nijedan agent nije zatražio pristup vašoj pošti.
# review: new
gtk-nothing-yet = Zasad ništa.

## Preferences

# review: new
gtk-preferences = Osobitosti
# review: new
gtk-language = Jezik
# review: new
gtk-language-subtitle = Jezik aplikacije i pomoći
# review: new
gtk-new-mail-group = Nova pošta
# review: new
gtk-notify-new-mail = Obavijesti o novoj pošti
# review: new
gtk-notify-subtitle = Obavijest kad stignu nove poruke dok je prozor u pozadini
# review: new
gtk-restart-to-change = Inbox Classic ponovno se pokreće radi promjene jezika.

## The desktop entry and the page of the software stores

# review: new
gtk-desktop-generic-name = Klijent e-pošte
# review: new
gtk-desktop-comment = Čitajte i pišite e-poštu: brz i jednostavan program za poštu
# review: new
gtk-desktop-keywords = pošta;e-pošta;poruke;ulazna pošta;klijent e-pošte;
# review: new
gtk-metainfo-summary = Brz i jednostavan program za poštu
# review: new
gtk-metainfo-description = Inbox Classic čita i piše e-poštu s mapama s lijeve strane, porukama na vrhu i porukom ispod, kao što su to nekad radili programi za poštu. Radi sa svakim računom IMAP i SMTP, a na Outlook.com i Microsoft 365 prijavljuje se putem preglednika.
# review: new
gtk-metainfo-feature-sanitized = Svaka se poruka prikazuje pročišćena, bez skripti, a slike s interneta samo kad ih dopustite
# review: new
gtk-metainfo-feature-search = Pretraživanje koje pronalazi riječi u predmetu, osobama, nazivima datoteka i tekstu, s Gmailovim operatorima
# review: new
gtk-metainfo-feature-replies = Odgovori sažimaju ranije poruke koje citiraju
# review: new
gtk-metainfo-feature-offline = Pošta ostaje čitljiva i bez veze s internetom; lozinke se čuvaju u vašem privjesku ključeva
