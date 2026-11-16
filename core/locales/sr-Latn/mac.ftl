# Srpski (latinica). Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.

## The app and its menus

# review: new
mac-quit = Izađi iz programa Inbox Classic
# review: new
mac-settings = Podešavanja…
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
mac-cut = Iseci
# review: new
mac-paste = Nalepi
# review: new
mac-menu-window = Prozor
# review: new
mac-minimize = Minimizuj
# review: new
mac-zoom = Zumiraj
# review: new
mac-no-updates = Ova verzija programa Inbox Classic ne podržava automatska ažuriranja. Preuzmite najnoviju verziju sa sajta inboxclassic.com.

## Settings

# review: new
mac-settings-title = Podešavanja
# review: new
mac-check-updates-automatically = Automatski traži ažuriranja

## Dialogs

# review: new
mac-choose = Izaberi

## The main window

# review: new
mac-still-running-detail = Inbox Classic i dalje proverava da li ima nove pošte u pozadini. Kliknite na njegovu ikonu u Dock-u da biste otvorili aplikaciju.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } poruka u Izlaznom sandučetu
        [few] { $count } poruke u Izlaznom sandučetu
       *[other] { $count } poruka u Izlaznom sandučetu
}
# review: new
mac-sending = Slanje: { $subject }…
# review: new
mac-checking = Provera novih poruka na nalogu { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Ova kopija programa Inbox Classic nije paket aplikacije, pa ne može da bude podrazumevana aplikacija za poštu.
# review: new
mac-not-made-default = Inbox Classic nije postavljen kao podrazumevana aplikacija za poštu: { $reason }
# review: new
mac-tool-search = Pretraga

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Tekst { $count } poruke se još indeksira, pa će uskoro možda biti pronađeno više.
        [few] Tekst { $count } poruke se još indeksira, pa će uskoro možda biti pronađeno više.
       *[other] Tekst { $count } poruka se još indeksira, pa će uskoro možda biti pronađeno više.
}
# review: new
mac-results-everywhere =
    { $count ->
        [0] Nema rezultata za „{ $words }“ u svim fasciklama
        [one] { $count } rezultat za „{ $words }“ u svim fasciklama
        [few] { $count } rezultata za „{ $words }“ u svim fasciklama
       *[other] { $count } rezultata za „{ $words }“ u svim fasciklama
}
# review: new
mac-results-in =
    { $count ->
        [0] Nema rezultata za „{ $words }“ u fascikli { $folder }
        [one] { $count } rezultat za „{ $words }“ u fascikli { $folder }
        [few] { $count } rezultata za „{ $words }“ u fascikli { $folder }
       *[other] { $count } rezultata za „{ $words }“ u fascikli { $folder }
}
# review: new
mac-still-indexing =
    { $count ->
        [one] tekst { $count } poruke se još indeksira
        [few] tekst { $count } poruke se još indeksira
       *[other] tekst { $count } poruka se još indeksira
}
# review: new
mac-folder-unread = { $folder }, nepročitano: { $count }
# review: new
mac-import-messages = Uvezi poruke
# review: new
mac-save-messages = Sačuvaj poruke
# review: new
mac-save-attachments-menu = Sačuvaj priloge…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Nije moguće sačuvati { $failed } od ukupno { $count } datoteka.
}
# review: new
mac-no-calendar-app = Na ovom Macu nema aplikacije kalendara koja bi otvorila pozivnice (datoteke .ics).
# review: new
mac-file-not-saved = Datoteku nije moguće sačuvati.
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
mac-underline = Podvučeno
# review: new
mac-bcc = Bcc
# review: new
mac-command-click-to-open = ⌘ + klik za otvaranje
# review: new
mac-saving-to-drafts = Čuvanje u fascikli Radne verzije…
# review: new
mac-dont-save = Nemoj da sačuvaš

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
mac-name-placeholder = Ana Petrović
# review: new
mac-more-sign-in-options = Još opcija za prijavljivanje…
# review: new
mac-add-sign-in-app = Dodaj aplikaciju za prijavljivanje…
# review: new
mac-looking-up = Traženje podešavanja za { $domain }…
# review: new
mac-add-button = Dodaj…
# review: new
mac-properties-button = Svojstva…
# review: new
mac-signature-button = Potpis…
# review: new
mac-security-button = Bezbednost…
# review: new
mac-sign-in-apps-button = Aplikacije za prijavljivanje…

## AI agents

# review: new
mac-forget-program = Da li želite da uklonite ovaj program i istoriju aktivnosti njegovih agenata?
# review: new
mac-forget-program-detail = Dozvole programa biće izbrisane. Pri sledećem povezivanju ponovo će se tražiti vaša dozvola.

## Sign-in apps

# review: new
mac-checking-issuer = Provera izdavaoca { $issuer }…
# review: new
mac-edit-button = Uredi…
# review: new
mac-use-for-new-accounts = Koristi aplikaciju { $name } za nove naloge
# review: new
mac-built-in = { $name } (ugrađena)

## Other windows

# review: new
mac-new-folder-button = Nova fascikla…
# review: new
mac-edit-link = Uredi vezu…
