# Hrvatski. Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

## The app and its menus

mac-quit = Zatvori Inbox Classic
mac-settings = Postavke…
mac-services = Usluge
mac-hide = Sakrij Inbox Classic
mac-hide-others = Sakrij ostale
mac-show-all = Prikaži sve
mac-check-updates = Potraži ažuriranja…
mac-close-window = Zatvori prozor
mac-redo = Ponovi
mac-cut = Izreži
mac-paste = Zalijepi
mac-menu-window = Prozor
mac-minimize = Minimiziraj
mac-zoom = Zumiraj
mac-no-updates = Ova verzija programa Inbox Classic ne podržava automatska ažuriranja. Preuzmite najnoviju verziju s inboxclassic.com.

## Settings

mac-settings-title = Postavke
mac-check-updates-automatically = Automatski traži ažuriranja
mac-settings-updates = Ažuriranja

## Dialogs

mac-choose = Odaberi

## The main window

mac-still-running-detail = Inbox Classic i dalje provjerava novu poštu u pozadini. Kliknite njegovu ikonu u Docku da biste otvorili aplikaciju.
mac-outbox-waiting =
    { $count ->
        [one] { $count } poruka u mapi Izlazna pošta
        [few] { $count } poruke u mapi Izlazna pošta
       *[other] { $count } poruka u mapi Izlazna pošta
    }
mac-sending = Slanje: { $subject }…
mac-checking = Provjera novih poruka na računu { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Ova kopija programa Inbox Classic nije u obliku paketa aplikacije (.app) pa je nije moguće postaviti kao zadanu aplikaciju.
mac-not-made-default = Inbox Classic nije postavljen kao zadana aplikacija za poštu: { $reason }
mac-tool-search = Pretraživanje

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Još traje indeksiranje teksta poruka (preostalo: { $count }). Uskoro se može pojaviti više rezultata.
        [few] Još traje indeksiranje teksta poruka (preostalo: { $count }). Uskoro se može pojaviti više rezultata.
       *[other] Još traje indeksiranje teksta poruka (preostalo: { $count }). Uskoro se može pojaviti više rezultata.
    }
mac-results-everywhere =
    { $count ->
        [0] Nema rezultata za „{ $words }“ u svim mapama
        [one] { $count } rezultat za „{ $words }“ u svim mapama
        [few] { $count } rezultata za „{ $words }“ u svim mapama
       *[other] { $count } rezultata za „{ $words }“ u svim mapama
    }
mac-results-in =
    { $count ->
        [0] Nema rezultata za „{ $words }“ u mapi { $folder }
        [one] { $count } rezultat za „{ $words }“ u mapi { $folder }
        [few] { $count } rezultata za „{ $words }“ u mapi { $folder }
       *[other] { $count } rezultata za „{ $words }“ u mapi { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] tekst poruka još se indeksira (preostalo: { $count })
        [few] tekst poruka još se indeksira (preostalo: { $count })
       *[other] tekst poruka još se indeksira (preostalo: { $count })
    }
mac-folder-unread = { $folder }, nepročitano: { $count }
mac-import-messages = Uvoz poruka
mac-save-messages = Spremanje poruka
mac-save-attachments-menu = Spremi privitke…
mac-files-not-saved =
    { $count ->
       *[other] Broj datoteka koje nije moguće spremiti: { $failed } od ukupno { $count }.
    }
mac-no-calendar-app = Na ovom Macu nema aplikacije kalendara koja bi otvorila pozivnice (datoteke .ics).
mac-file-not-saved = Datoteku nije moguće spremiti.
mac-unsubscribing = Otkazivanje pretplate: { $target }…
mac-loading-list = Učitavanje…

## The compose window

mac-bold = Podebljano
mac-italic = Kurziv
mac-underline = Podcrtano
mac-bcc = Skrivena kopija
mac-command-click-to-open = ⌘ + klik za otvaranje
mac-saving-to-drafts = Spremanje u Skice…
mac-dont-save = Nemoj spremiti

## The reading pane

mac-files =
    { $count ->
        [one] { $count } datoteka
        [few] { $count } datoteke
       *[other] { $count } datoteka
    }

## Accounts

mac-next = Dalje
mac-name-placeholder = Ana Horvat
mac-more-sign-in-options = Još mogućnosti prijave…
mac-add-sign-in-app = Dodaj aplikaciju za prijavu…
mac-looking-up = Traženje postavki domene { $domain }…
mac-add-button = Dodaj…
mac-properties-button = Svojstva…
mac-signature-button = Potpis…
mac-security-button = Sigurnost…
mac-sign-in-apps-button = Aplikacije za prijavu…

## AI agents

mac-forget-program = Želite li ukloniti ovaj program s popisa i povijest aktivnosti njegovih agenata?
mac-forget-program-detail = Dozvole programa bit će izbrisane. Pri sljedećem povezivanju ponovno će se tražiti vaša dozvola.

## Sign-in apps

mac-checking-issuer = Provjera izdavatelja { $issuer }…
mac-edit-button = Uredi…
mac-use-for-new-accounts = Koristi aplikaciju { $name } za nove račune
mac-built-in = { $name } (ugrađena)

## Other windows

mac-new-folder-button = Nova mapa…
mac-edit-link = Uredi poveznicu…
