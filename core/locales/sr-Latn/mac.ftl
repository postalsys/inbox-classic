# Srpski (latinica). Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.

## The app and its menus

mac-quit = Izađi iz programa Inbox Classic
mac-settings = Podešavanja…
mac-services = Usluge
mac-hide = Sakrij Inbox Classic
mac-hide-others = Sakrij ostale
mac-show-all = Prikaži sve
mac-check-updates = Potraži ažuriranja…
mac-close-window = Zatvori prozor
mac-redo = Ponovi
mac-cut = Iseci
mac-paste = Nalepi
mac-menu-window = Prozor
mac-minimize = Minimizuj
mac-zoom = Uvećaj prozor
mac-no-updates = Ova verzija programa Inbox Classic ne podržava automatska ažuriranja. Preuzmite najnoviju verziju sa sajta inboxclassic.com.

## Settings

mac-settings-title = Podešavanja
mac-language-label = Jezik:
mac-restart-hint = Ponovo pokrenite Inbox Classic da biste promenili jezik.
mac-notify-new-mail = Obavesti me kada stigne nova pošta
mac-restart-question = Da li želite da sada ponovo pokrenete Inbox Classic da biste promenili jezik?

## Dialogs

mac-choose = Izaberi

## The main window

mac-still-running-detail = Inbox Classic i dalje proverava da li ima nove pošte u pozadini. Kliknite na njegovu ikonu u Dock-u da biste otvorili aplikaciju.
mac-outbox-waiting =
    { $count ->
        [one] { $count } poruka u Izlaznom sandučetu
        [few] { $count } poruke u Izlaznom sandučetu
       *[other] { $count } poruka u Izlaznom sandučetu
}
mac-sending = Slanje: { $subject }…
mac-checking = Provera novih poruka na nalogu { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Ova kopija programa Inbox Classic nije upakovana kao macOS aplikacija i ne može da se izabere kao podrazumevana aplikacija za e-poštu.
mac-not-made-default = Inbox Classic nije postavljen kao podrazumevana aplikacija za poštu: { $reason }
mac-tool-search = Pretraga

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Indeksiranje teksta nije završeno za još { $count } poruku. Uskoro se može pojaviti više rezultata.
        [few] Indeksiranje teksta nije završeno za još { $count } poruke. Uskoro se može pojaviti više rezultata.
       *[other] Indeksiranje teksta nije završeno; preostalo poruka: { $count }. Uskoro se može pojaviti više rezultata.
}
mac-results-everywhere =
    { $count ->
        [0] Nema rezultata za „{ $words }“ u svim fasciklama
        [one] { $count } rezultat za „{ $words }“ u svim fasciklama
        [few] { $count } rezultata za „{ $words }“ u svim fasciklama
       *[other] { $count } rezultata za „{ $words }“ u svim fasciklama
}
mac-results-in =
    { $count ->
        [0] Nema rezultata za „{ $words }“ u fascikli { $folder }
        [one] { $count } rezultat za „{ $words }“ u fascikli { $folder }
        [few] { $count } rezultata za „{ $words }“ u fascikli { $folder }
       *[other] { $count } rezultata za „{ $words }“ u fascikli { $folder }
}
mac-still-indexing =
    { $count ->
        [one] još se indeksira tekst poruka; preostalo: { $count }
        [few] još se indeksira tekst poruka; preostalo: { $count }
       *[other] još se indeksira tekst poruka; preostalo: { $count }
}
mac-folder-unread = { $folder }, nepročitano: { $count }
mac-import-messages = Uvezi poruke
mac-save-messages = Sačuvaj poruke
mac-save-attachments-menu = Sačuvaj priloge…
mac-files-not-saved =
    { $count ->
       *[other] Ukupno datoteka: { $count }; nije sačuvano: { $failed }.
}
mac-no-calendar-app = Na ovom Macu nema aplikacije za kalendar koja može da otvori pozivnice (datoteke .ics).
mac-file-not-saved = Datoteku nije moguće sačuvati.
mac-unsubscribing = Otkazivanje pretplate: { $target }…

## The compose window

mac-bold = Podebljano
mac-italic = Kurziv
mac-underline = Podvučeno
mac-bcc = Bcc
mac-command-click-to-open = ⌘ + klik za otvaranje
mac-saving-to-drafts = Čuvanje u fascikli Radne verzije…
mac-dont-save = Ne čuvaj

## The reading pane

mac-files =
    { $count ->
        [one] { $count } datoteka
        [few] { $count } datoteke
       *[other] { $count } datoteka
}

## Accounts

mac-next = Dalje
mac-name-placeholder = Ana Petrović
mac-more-sign-in-options = Još opcija za prijavljivanje…
mac-add-sign-in-app = Dodaj aplikaciju za prijavljivanje…
mac-looking-up = Traženje podešavanja za { $domain }…
mac-add-button = Dodaj…
mac-properties-button = Svojstva…
mac-signature-button = Potpis…
mac-security-button = Bezbednost…
mac-sign-in-apps-button = Aplikacije za prijavljivanje…

## AI agents

mac-forget-program = Da li želite da uklonite ovaj program i istoriju aktivnosti njegovih agenata?
mac-forget-program-detail = Dozvole programa biće izbrisane. Pri sledećem povezivanju ponovo će se tražiti vaša dozvola.

## Sign-in apps

mac-checking-issuer = Provera izdavaoca { $issuer }…
mac-edit-button = Uredi…
mac-use-for-new-accounts = Koristi aplikaciju { $name } za nove naloge
mac-built-in = { $name } (ugrađena)

## Other windows

mac-new-folder-button = Nova fascikla…
mac-edit-link = Uredi vezu…
