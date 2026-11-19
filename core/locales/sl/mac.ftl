# Slovenščina. Osnutek, čaka na pregled naravnega govorca (glej core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-. Mac conventions: an ellipsis (…)
# after a command that asks for more.

## The app and its menus

mac-quit = Končaj Inbox Classic
mac-settings = Nastavitve…
mac-services = Storitve
mac-hide = Skrij Inbox Classic
mac-hide-others = Skrij druge
mac-show-all = Pokaži vse
mac-check-updates = Preveri posodobitve…
mac-close-window = Zapri okno
mac-redo = Uveljavi
mac-cut = Izreži
mac-paste = Prilepi
mac-menu-window = Okno
mac-minimize = Minimiraj
mac-zoom = Povečaj okno
mac-no-updates = Ta različica programa Inbox Classic ne podpira samodejnih posodobitev. Najnovejšo različico prenesite s strani inboxclassic.com.

## Settings

mac-settings-title = Nastavitve
mac-check-updates-automatically = Samodejno preveri posodobitve
mac-settings-updates = Posodobitve

## Dialogs

mac-choose = Izberi

## The main window

mac-still-running-detail = Inbox Classic v ozadju še naprej preverja novo pošto. Kliknite njegovo ikono v Docku, da odprete program.
mac-outbox-waiting =
    { $count ->
        [one] { $count } sporočilo v mapi Odpošiljanje
        [two] { $count } sporočili v mapi Odpošiljanje
        [few] { $count } sporočila v mapi Odpošiljanje
       *[other] { $count } sporočil v mapi Odpošiljanje
    }
mac-sending = Pošiljanje { $subject }…
mac-checking = Preverjanje novih sporočil v računu »{ $account }«…
mac-account-said = { $account }: { $message }
mac-not-bundle = Ta kopija programa Inbox Classic ni paket aplikacije, zato ne more biti privzeti poštni program.
mac-not-made-default = Inbox Classic ni bil nastavljen kot privzeti poštni program: { $reason }
mac-tool-search = Iskanje

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Besedilo { $count } sporočila se še indeksira, zato bo kmalu morda najdenih več zadetkov.
       *[other] Besedilo { $count } sporočil se še indeksira, zato bo kmalu morda najdenih več zadetkov.
    }
mac-results-everywhere =
    { $count ->
        [0] Ni rezultatov za »{ $words }« v vseh mapah
        [one] { $count } rezultat za »{ $words }« v vseh mapah
        [two] { $count } rezultata za »{ $words }« v vseh mapah
        [few] { $count } rezultati za »{ $words }« v vseh mapah
       *[other] { $count } rezultatov za »{ $words }« v vseh mapah
    }
mac-results-in = { $count ->
        [0] Ni rezultatov za »{ $words }« v prikazu »{ $folder }«
        [one] { $count } rezultat za »{ $words }« v prikazu »{ $folder }«
        [two] { $count } rezultata za »{ $words }« v prikazu »{ $folder }«
        [few] { $count } rezultati za »{ $words }« v prikazu »{ $folder }«
       *[other] { $count } rezultatov za »{ $words }« v prikazu »{ $folder }«
    }
mac-still-indexing =
    { $count ->
        [one] besedilo { $count } sporočila se še indeksira
       *[other] besedilo { $count } sporočil se še indeksira
    }
mac-folder-unread = { $folder }, neprebrana: { $count }
mac-import-messages = Uvozi sporočila
mac-save-messages = Shrani sporočila
mac-save-attachments-menu = Shrani priponke…
mac-files-not-saved =
    { $count ->
       *[other] Datoteke, ki jih ni bilo mogoče shraniti: { $failed }. Skupno število datotek: { $count }.
    }
mac-no-calendar-app = Povabila (datoteke .ics) ni bilo mogoče odpreti v koledarskem programu.
mac-file-not-saved = Datoteke ni bilo mogoče shraniti.
mac-unsubscribing = Odjavljanje od { $target }…
mac-loading-list = Nalaganje…

## The compose window

mac-bold = Krepko
mac-italic = Ležeče
mac-underline = Podčrtano
mac-bcc = Skp
mac-command-click-to-open = ⌘ + klik za odpiranje
mac-saving-to-drafts = Shranjevanje v mapo Osnutki…
mac-dont-save = Ne shrani

## The reading pane

mac-files =
    { $count ->
        [one] { $count } datoteka
        [two] { $count } datoteki
        [few] { $count } datoteke
       *[other] { $count } datotek
    }

## Accounts

mac-next = Naprej
mac-name-placeholder = Ana Novak
mac-more-sign-in-options = Več možnosti prijave…
mac-add-sign-in-app = Dodaj aplikacijo za prijavo…
mac-looking-up = Iskanje nastavitev za { $domain }…
mac-add-button = Dodaj…
mac-properties-button = Lastnosti…
mac-signature-button = Besedilo podpisa…
mac-security-button = Varnost…
mac-sign-in-apps-button = Aplikacije za prijavo…

## AI agents

mac-forget-program = Želite odstraniti dovoljenja tega programa in zgodovino dejavnosti njegovih agentov?
mac-forget-program-detail = Dovoljenja programa bodo izbrisana. Ko se bo naslednjič povezal, boste znova vprašani za dovoljenje.

## Sign-in apps

mac-checking-issuer = Preverjanje izdajatelja »{ $issuer }«…
mac-edit-button = Uredi…
mac-use-for-new-accounts = Uporabi aplikacijo »{ $name }« za nove račune
mac-built-in = { $name } (vgrajena)

## Other windows

mac-new-folder-button = Nova mapa…
mac-edit-link = Uredi povezavo…
