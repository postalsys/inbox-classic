# Hrvatski. Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

## The app and its menus

# review: new
mac-quit = Zatvori Inbox Classic
# review: new
mac-settings = Postavke…
# review: new
mac-services = Usluge
# review: new
mac-hide = Sakrij Inbox Classic
# review: new
mac-hide-others = Sakrij ostale
# review: new
mac-show-all = Prikaži sve
# review: new
mac-check-updates = Potraži ažuriranja…
# review: new
mac-close-window = Zatvori prozor
# review: new
mac-redo = Ponovi
# review: new
mac-cut = Izreži
# review: new
mac-paste = Zalijepi
# review: new
mac-menu-window = Prozor
# review: new
mac-minimize = Minimiziraj
# review: new
mac-zoom = Zumiraj
# review: new
mac-no-updates = Ova verzija programa Inbox Classic ne podržava automatska ažuriranja. Preuzmite najnoviju verziju s inboxclassic.com.

## Settings

# review: new
mac-settings-title = Postavke
# review: new
mac-check-updates-automatically = Automatski traži ažuriranja
# review: new
mac-settings-updates = Ažuriranja

## Dialogs

# review: new
mac-choose = Odaberi

## The main window

# review: new
mac-still-running-detail = Inbox Classic i dalje provjerava novu poštu u pozadini. Kliknite njegovu ikonu u Docku da biste otvorili aplikaciju.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } poruka u mapi Izlazna pošta
        [few] { $count } poruke u mapi Izlazna pošta
       *[other] { $count } poruka u mapi Izlazna pošta
    }
# review: new
mac-sending = Slanje: { $subject }…
# review: new
mac-checking = Provjera novih poruka na računu { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Ova kopija programa Inbox Classic nije paket aplikacije, pa ne može biti zadana aplikacija za poštu.
# review: new
mac-not-made-default = Inbox Classic nije postavljen kao zadana aplikacija za poštu: { $reason }
# review: new
mac-tool-search = Pretraživanje

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Tekst { $count } poruke još se indeksira, pa će uskoro možda biti pronađeno više.
        [few] Tekst { $count } poruke još se indeksira, pa će uskoro možda biti pronađeno više.
       *[other] Tekst { $count } poruka još se indeksira, pa će uskoro možda biti pronađeno više.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Nema rezultata za „{ $words }“ u svim mapama
        [one] { $count } rezultat za „{ $words }“ u svim mapama
        [few] { $count } rezultata za „{ $words }“ u svim mapama
       *[other] { $count } rezultata za „{ $words }“ u svim mapama
    }
# review: new
mac-results-in =
    { $count ->
        [0] Nema rezultata za „{ $words }“ u mapi { $folder }
        [one] { $count } rezultat za „{ $words }“ u mapi { $folder }
        [few] { $count } rezultata za „{ $words }“ u mapi { $folder }
       *[other] { $count } rezultata za „{ $words }“ u mapi { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] tekst { $count } poruke još se indeksira
        [few] tekst { $count } poruke još se indeksira
       *[other] tekst { $count } poruka još se indeksira
    }
# review: new
mac-folder-unread = { $folder }, nepročitano: { $count }
# review: new
mac-import-messages = Uvoz poruka
# review: new
mac-save-messages = Spremanje poruka
# review: new
mac-save-attachments-menu = Spremi privitke…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Nije moguće spremiti { $failed } od ukupno { $count } datoteka.
    }
# review: new
mac-no-calendar-app = Na ovom Macu nema aplikacije kalendara koja bi otvorila pozivnice (datoteke .ics).
# review: new
mac-file-not-saved = Datoteku nije moguće spremiti.
# review: new
mac-unsubscribing = Otkazivanje pretplate: { $target }…
# review: new
mac-loading-list = Učitavanje…

## The compose window

# review: new
mac-bold = Podebljano
# review: new
mac-italic = Kurziv
# review: new
mac-underline = Podcrtano
# review: new
mac-bcc = Skrivena kopija
# review: new
mac-command-click-to-open = ⌘ + klik za otvaranje
# review: new
mac-saving-to-drafts = Spremanje u Skice…
# review: new
mac-dont-save = Nemoj spremiti

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } datoteka
        [few] { $count } datoteke
       *[other] { $count } datoteka
    }

## Accounts

# review: new
mac-next = Dalje
# review: new
mac-name-placeholder = Ana Horvat
# review: new
mac-more-sign-in-options = Još mogućnosti prijave…
# review: new
mac-add-sign-in-app = Dodaj aplikaciju za prijavu…
# review: new
mac-looking-up = Traženje postavki za { $domain }…
# review: new
mac-add-button = Dodaj…
# review: new
mac-properties-button = Svojstva…
# review: new
mac-signature-button = Potpis…
# review: new
mac-security-button = Sigurnost…
# review: new
mac-sign-in-apps-button = Aplikacije za prijavu…

## AI agents

# review: new
mac-forget-program = Ukloniti ovaj program i povijest aktivnosti njegovih agenata?
# review: new
mac-forget-program-detail = Dozvole programa bit će izbrisane. Pri sljedećem povezivanju ponovno će se tražiti vaša dozvola.

## Sign-in apps

# review: new
mac-checking-issuer = Provjera izdavatelja { $issuer }…
# review: new
mac-edit-button = Uredi…
# review: new
mac-use-for-new-accounts = Koristi aplikaciju { $name } za nove račune
# review: new
mac-built-in = { $name } (ugrađena)

## Other windows

# review: new
mac-new-folder-button = Nova mapa…
# review: new
mac-edit-link = Uredi poveznicu…
