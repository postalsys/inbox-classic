# Slovenčina. Návrh, čaká na kontrolu rodeným hovoriacim (pozri core/locales/GLOSSARY.md).

## The app and its menus

# review: new
mac-quit = Ukončiť Inbox Classic
# review: new
mac-settings = Nastavenia…
# review: new
mac-services = Služby
# review: new
mac-hide = Skryť Inbox Classic
# review: new
mac-hide-others = Skryť ostatné
# review: new
mac-show-all = Zobraziť všetko
# review: new
mac-check-updates = Vyhľadať aktualizácie…
# review: new
mac-close-window = Zavrieť okno
# review: new
mac-redo = Znova
# review: new
mac-cut = Vystrihnúť
# review: new
mac-paste = Vložiť
# review: new
mac-menu-window = Okno
# review: new
mac-minimize = Minimalizovať
# review: new
mac-zoom = Zväčšiť
# review: new
mac-no-updates = Táto verzia Inbox Classic nepodporuje automatické aktualizácie. Stiahnite si najnovšiu verziu z inboxclassic.com.

## Settings

# review: new
mac-settings-title = Nastavenia
# review: new
mac-language-label = Jazyk:
# review: new
mac-restart-hint = Jazyk sa zmení po reštartovaní Inbox Classic.
# review: new
mac-notify-new-mail = Upozorniť ma, keď príde nová pošta
# review: new
mac-restart-question = Reštartovať Inbox Classic teraz a zmeniť jazyk?

## Dialogs

# review: new
mac-choose = Vybrať

## The main window

# review: new
mac-still-running-detail = Inbox Classic naďalej kontroluje novú poštu na pozadí. Aplikáciu otvoríte kliknutím na jej ikonu v Docku.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } správa v priečinku Pošta na odoslanie
        [few] { $count } správy v priečinku Pošta na odoslanie
       *[other] { $count } správ v priečinku Pošta na odoslanie
    }
# review: new
mac-sending = Odosiela sa { $subject }…
# review: new
mac-checking = Kontrolujú sa nové správy v konte { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Táto kópia Inbox Classic nie je balík aplikácie, preto nemôže byť predvolenou poštovou aplikáciou.
# review: new
mac-not-made-default = Inbox Classic sa nestal predvolenou poštovou aplikáciou: { $reason }
# review: new
mac-tool-search = Hľadať

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Text { $count } správy sa ešte indexuje, takže sa čoskoro môže nájsť viac.
       *[other] Text správ ({ $count }) sa ešte indexuje, takže sa čoskoro môže nájsť viac.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Žiadne výsledky pre „{ $words }“ vo všetkých priečinkoch
        [one] { $count } výsledok pre „{ $words }“ vo všetkých priečinkoch
        [few] { $count } výsledky pre „{ $words }“ vo všetkých priečinkoch
       *[other] { $count } výsledkov pre „{ $words }“ vo všetkých priečinkoch
    }
# review: new
mac-results-in =
    { $count ->
        [0] Žiadne výsledky pre „{ $words }“ v priečinku { $folder }
        [one] { $count } výsledok pre „{ $words }“ v priečinku { $folder }
        [few] { $count } výsledky pre „{ $words }“ v priečinku { $folder }
       *[other] { $count } výsledkov pre „{ $words }“ v priečinku { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] text { $count } správy sa ešte indexuje
       *[other] text správ ({ $count }) sa ešte indexuje
    }
# review: new
mac-folder-unread = { $folder }, neprečítané: { $count }
# review: new
mac-import-messages = Importovať správy
# review: new
mac-save-messages = Uložiť správy
# review: new
mac-save-attachments-menu = Uložiť prílohy…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Nepodarilo sa uložiť { $failed } z { $count } súborov.
    }
# review: new
mac-no-calendar-app = V tomto Macu nie je žiadna aplikácia kalendára, ktorá by otvorila pozvánky (súbory .ics).
# review: new
mac-file-not-saved = Súbor sa nepodarilo uložiť.
# review: new
mac-unsubscribing = Odhlasovanie z { $target }…

## The compose window

# review: new
mac-bold = Tučné
# review: new
mac-italic = Kurzíva
# review: new
mac-underline = Podčiarknuté
# review: new
mac-bcc = Skrytá kópia
# review: new
mac-command-click-to-open = otvoríte kliknutím so stlačeným ⌘
# review: new
mac-saving-to-drafts = Ukladá sa do priečinka Koncepty…
# review: new
mac-dont-save = Neuložiť

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } súbor
        [few] { $count } súbory
       *[other] { $count } súborov
    }

## Accounts

# review: new
mac-next = Ďalej
# review: new
mac-name-placeholder = Anna Nováková
# review: new
mac-more-sign-in-options = Ďalšie možnosti prihlásenia…
# review: new
mac-add-sign-in-app = Pridať prihlasovaciu aplikáciu…
# review: new
mac-looking-up = Hľadajú sa nastavenia domény { $domain }…
# review: new
mac-add-button = Pridať…
# review: new
mac-properties-button = Vlastnosti…
# review: new
mac-signature-button = Podpis…
# review: new
mac-security-button = Zabezpečenie…
# review: new
mac-sign-in-apps-button = Prihlasovacie aplikácie…

## AI agents

# review: new
mac-forget-program = Odstrániť tento program a históriu aktivity jeho agentov?
# review: new
mac-forget-program-detail = Oprávnenia programu sa odstránia. Pri ďalšom pripojení sa vás znova opýta na povolenie.

## Sign-in apps

# review: new
mac-checking-issuer = Overuje sa { $issuer }…
# review: new
mac-edit-button = Upraviť…
# review: new
mac-use-for-new-accounts = Používať { $name } pre nové kontá
# review: new
mac-built-in = { $name } (vstavaná)

## Other windows

# review: new
mac-new-folder-button = Nový priečinok…
# review: new
mac-edit-link = Upraviť odkaz…
