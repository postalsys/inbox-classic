# Slovenčina. Návrh, čaká na kontrolu rodeným hovoriacim (pozri core/locales/GLOSSARY.md).

## The app and its menus

mac-quit = Ukončiť Inbox Classic
mac-settings = Nastavenia…
mac-services = Služby
mac-hide = Skryť Inbox Classic
mac-hide-others = Skryť ostatné
mac-show-all = Zobraziť všetky
mac-check-updates = Vyhľadať aktualizácie…
mac-close-window = Zavrieť okno
mac-redo = Znova
mac-cut = Vystrihnúť
mac-paste = Vložiť
mac-menu-window = Okno
mac-minimize = Minimalizovať
mac-zoom = Zmeniť veľkosť
mac-no-updates = Táto verzia Inbox Classic nepodporuje automatické aktualizácie. Stiahnite si najnovšiu verziu z inboxclassic.com.

## Settings

mac-settings-title = Nastavenia
mac-check-updates-automatically = Automaticky vyhľadávať aktualizácie
mac-settings-updates = Aktualizácie

## Dialogs

mac-choose = Vybrať

## The main window

mac-still-running-detail = Inbox Classic naďalej kontroluje novú poštu na pozadí. Aplikáciu otvoríte kliknutím na jej ikonu v Docku.
mac-outbox-waiting =
    { $count ->
        [one] { $count } správa v priečinku Pošta na odoslanie
        [few] { $count } správy v priečinku Pošta na odoslanie
       *[other] { $count } správ v priečinku Pošta na odoslanie
    }
mac-sending = Odosiela sa správa { $subject }…
mac-checking = Kontroluje sa nová pošta v konte „{ $account }“…
mac-account-said = { $account }: { $message }
mac-not-bundle = Táto kópia Inbox Classic nie je balík aplikácie, preto nemôže byť predvolenou poštovou aplikáciou.
mac-not-made-default = Inbox Classic sa nepodarilo nastaviť ako predvolenú poštovú aplikáciu: { $reason }
mac-tool-search = Hľadať

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Text { $count } správy sa ešte indexuje, preto sa ešte môžu objaviť ďalšie výsledky.
       *[other] Text správ ({ $count }) sa ešte indexuje, preto sa ešte môžu objaviť ďalšie výsledky.
    }
mac-results-everywhere =
    { $count ->
        [0] Žiadne výsledky pre „{ $words }“ vo všetkých priečinkoch
        [one] { $count } výsledok pre „{ $words }“ vo všetkých priečinkoch
        [few] { $count } výsledky pre „{ $words }“ vo všetkých priečinkoch
       *[other] { $count } výsledkov pre „{ $words }“ vo všetkých priečinkoch
    }
mac-results-in =
    { $count ->
        [0] Žiadne výsledky pre „{ $words }“ (rozsah: { $folder })
        [one] { $count } výsledok pre „{ $words }“ (rozsah: { $folder })
        [few] { $count } výsledky pre „{ $words }“ (rozsah: { $folder })
       *[other] { $count } výsledkov pre „{ $words }“ (rozsah: { $folder })
    }
mac-still-indexing =
    { $count ->
        [one] text { $count } správy sa ešte indexuje
       *[other] text správ ({ $count }) sa ešte indexuje
    }
mac-folder-unread = { $folder }, neprečítané: { $count }
mac-import-messages = Importovať správy
mac-save-messages = Uložiť správy
mac-save-attachments-menu = Uložiť prílohy…
mac-files-not-saved =
    { $count ->
       *[other] Nepodarilo sa uložiť súbory: { $failed } z { $count }.
    }
mac-no-calendar-app = Pozvánku sa nepodarilo otvoriť. Skontrolujte, či aplikácia kalendára v tomto Macu podporuje súbory .ics.
mac-file-not-saved = Súbor sa nepodarilo uložiť.
mac-unsubscribing = Odosiela sa žiadosť o odhlásenie odberu: { $target }…
mac-loading-list = Načítava sa…

## The compose window

mac-bold = Tučné
mac-italic = Kurzíva
mac-underline = Podčiarknuté
mac-bcc = Skrytá kópia
mac-command-click-to-open = otvoríte kliknutím so stlačeným ⌘
mac-saving-to-drafts = Ukladá sa do priečinka Koncepty…
mac-dont-save = Neuložiť

## The reading pane

mac-files =
    { $count ->
        [one] { $count } súbor
        [few] { $count } súbory
       *[other] { $count } súborov
    }

## Accounts

mac-next = Ďalej
mac-name-placeholder = Anna Nováková
mac-more-sign-in-options = Ďalšie možnosti prihlásenia…
mac-add-sign-in-app = Pridať prihlasovaciu aplikáciu…
mac-looking-up = Hľadajú sa nastavenia domény { $domain }…
mac-add-button = Pridať…
mac-properties-button = Vlastnosti…
mac-signature-button = Textový podpis…
mac-security-button = Zabezpečenie…
mac-sign-in-apps-button = Prihlasovacie aplikácie…

## AI agents

mac-forget-program = Odstrániť oprávnenia programu a históriu aktivity jeho agentov?
mac-forget-program-detail = Oprávnenia programu sa odstránia. Pri ďalšom pripojení vás Inbox Classic znova požiada o povolenie.

## Sign-in apps

mac-checking-issuer = Overuje sa konfigurácia vydavateľa: { $issuer }…
mac-edit-button = Upraviť…
mac-use-for-new-accounts = Ponúkať aplikáciu „{ $name }“ pri pridávaní kont
mac-built-in = { $name } (vstavaná)

## Other windows

mac-new-folder-button = Nový priečinok…
mac-edit-link = Upraviť odkaz…
