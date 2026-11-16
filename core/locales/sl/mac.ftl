# Slovenščina. Osnutek, čaka na pregled naravnega govorca (glej core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-. Mac conventions: an ellipsis (…)
# after a command that asks for more.

## The app and its menus

# review: new
mac-quit = Končaj Inbox Classic
# review: new
mac-settings = Nastavitve…
# review: new
mac-services = Storitve
# review: new
mac-hide = Skrij Inbox Classic
# review: new
mac-hide-others = Skrij druge
# review: new
mac-show-all = Pokaži vse
# review: new
mac-check-updates = Preveri posodobitve…
# review: new
mac-close-window = Zapri okno
# review: new
mac-redo = Uveljavi
# review: new
mac-cut = Izreži
# review: new
mac-paste = Prilepi
# review: new
mac-menu-window = Okno
# review: new
mac-minimize = Minimiraj
# review: new
mac-zoom = Povečava
# review: new
mac-no-updates = Ta različica programa Inbox Classic ne podpira samodejnih posodobitev. Najnovejšo različico prenesite s strani inboxclassic.com.

## Settings

# review: new
mac-settings-title = Nastavitve
# review: new
mac-check-updates-automatically = Samodejno preveri posodobitve

## Dialogs

# review: new
mac-choose = Izberi

## The main window

# review: new
mac-still-running-detail = Inbox Classic v ozadju še naprej preverja novo pošto. Kliknite njegovo ikono v Docku, da odprete program.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } sporočilo v mapi Odpošiljanje
        [two] { $count } sporočili v mapi Odpošiljanje
        [few] { $count } sporočila v mapi Odpošiljanje
       *[other] { $count } sporočil v mapi Odpošiljanje
    }
# review: new
mac-sending = Pošiljanje { $subject }…
# review: new
mac-checking = Preverjanje novih sporočil v { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Ta kopija programa Inbox Classic ni paket aplikacije, zato ne more biti privzeti poštni program.
# review: new
mac-not-made-default = Inbox Classic ni bil nastavljen kot privzeti poštni program: { $reason }
# review: new
mac-tool-search = Iskanje

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Besedilo { $count } sporočila se še indeksira, zato bo kmalu morda najdenih več zadetkov.
       *[other] Besedilo { $count } sporočil se še indeksira, zato bo kmalu morda najdenih več zadetkov.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Ni rezultatov za »{ $words }« v vseh mapah
        [one] { $count } rezultat za »{ $words }« v vseh mapah
        [two] { $count } rezultata za »{ $words }« v vseh mapah
        [few] { $count } rezultati za »{ $words }« v vseh mapah
       *[other] { $count } rezultatov za »{ $words }« v vseh mapah
    }
# review: new
mac-results-in =
    { $count ->
        [0] Ni rezultatov za »{ $words }« v mapi { $folder }
        [one] { $count } rezultat za »{ $words }« v mapi { $folder }
        [two] { $count } rezultata za »{ $words }« v mapi { $folder }
        [few] { $count } rezultati za »{ $words }« v mapi { $folder }
       *[other] { $count } rezultatov za »{ $words }« v mapi { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] besedilo { $count } sporočila se še indeksira
       *[other] besedilo { $count } sporočil se še indeksira
    }
# review: new
mac-folder-unread = { $folder }, neprebrana: { $count }
# review: new
mac-import-messages = Uvozi sporočila
# review: new
mac-save-messages = Shrani sporočila
# review: new
mac-save-attachments-menu = Shrani priponke…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Ni bilo mogoče shraniti { $failed } od { $count } datotek.
    }
# review: new
mac-no-calendar-app = V tem Macu ni koledarskega programa, ki bi odprl povabila (datoteke .ics).
# review: new
mac-file-not-saved = Datoteke ni bilo mogoče shraniti.
# review: new
mac-unsubscribing = Odjavljanje od { $target }…
# review: new
mac-loading-list = Nalaganje…

## The compose window

# review: new
mac-bold = Krepko
# review: new
mac-italic = Ležeče
# review: new
mac-underline = Podčrtano
# review: new
mac-bcc = Skp
# review: new
mac-command-click-to-open = ⌘ + klik za odpiranje
# review: new
mac-saving-to-drafts = Shranjevanje v mapo Osnutki…
# review: new
mac-dont-save = Ne shrani

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } datoteka
        [two] { $count } datoteki
        [few] { $count } datoteke
       *[other] { $count } datotek
    }

## Accounts

# review: new
mac-next = Naprej
# review: new
mac-name-placeholder = Ana Novak
# review: new
mac-more-sign-in-options = Več možnosti prijave…
# review: new
mac-add-sign-in-app = Dodaj aplikacijo za prijavo…
# review: new
mac-looking-up = Iskanje nastavitev za { $domain }…
# review: new
mac-add-button = Dodaj…
# review: new
mac-properties-button = Lastnosti…
# review: new
mac-signature-button = Podpis…
# review: new
mac-security-button = Varnost…
# review: new
mac-sign-in-apps-button = Aplikacije za prijavo…

## AI agents

# review: new
mac-forget-program = Želite odstraniti ta program in zgodovino dejavnosti njegovih agentov?
# review: new
mac-forget-program-detail = Dovoljenja programa bodo izbrisana. Ko se bo naslednjič povezal, boste znova vprašani za dovoljenje.

## Sign-in apps

# review: new
mac-checking-issuer = Preverjanje { $issuer }…
# review: new
mac-edit-button = Uredi…
# review: new
mac-use-for-new-accounts = Uporabi { $name } za nove račune
# review: new
mac-built-in = { $name } (vgrajena)

## Other windows

# review: new
mac-new-folder-button = Nova mapa…
# review: new
mac-edit-link = Uredi povezavo…
