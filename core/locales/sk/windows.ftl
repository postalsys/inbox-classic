# Slovenčina. Návrh, čaká na kontrolu rodeným hovoriacim (pozri core/locales/GLOSSARY.md).

## The main window

win-still-running-detail = Inbox Classic naďalej kontroluje novú poštu na pozadí. Kliknutím na ikonu ho otvoríte. Ak ho chcete ukončiť, kliknite na ikonu pravým tlačidlom a použite jej ponuku.
win-default-app-not-installed = Táto kópia Inbox Classic nebola nainštalovaná, preto ju Windows neuvádza medzi poštovými aplikáciami. Ak ju chcete vybrať, nainštalujte ju.
win-default-app-settings = Windows otvorí nastavenia Predvolené aplikácie. Vyberte Inbox Classic na otváranie odkazov MAILTO.
win-no-unread = Žiadne neprečítané správy
win-unread-messages = { $count ->
    [one] 1 neprečítaná správa
    [few] { $count } neprečítané správy
   *[other] { $count } neprečítaných správ
}
win-print-failed = Správu sa nepodarilo vytlačiť.
win-print-title-of = Tlač: { $subject }
win-no-bodies = Obsah správ nemožno zobraziť.
win-webview-failed = Zobrazenie správy pomocou WebView2 sa nepodarilo vytvoriť.
win-webview-missing = Prostredie WebView2 Runtime nie je k dispozícii.
win-list-loading = Načítava sa...

## Buttons and words used in many windows

win-delete-button = O&dstrániť
win-find-label = &Hľadať:
win-save-as-button = &Uložiť ako...
win-too-many-files = Príliš veľa súborov naraz: vyberte menej.

## The Outbox


## The compose window

win-editor-failed = Správy nemožno písať.
win-ctrl-click-to-open = (otvoríte kliknutím so stlačeným klávesom { $ctrl })
win-format-bold = Tučné ({ $ctrl }+B)
win-format-italic = Kurzíva ({ $ctrl }+I)
win-format-underline = Podčiarknuté ({ $ctrl }+U)
win-format-link = Hypertextový odkaz ({ $ctrl }+K)
win-show-cc = &Kópia
win-show-bcc = &Skrytá kópia
win-signature-title = Textový podpis: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Žiadne výsledky pre „{ $words }“ vo všetkých priečinkoch
    [one] { $count } výsledok pre „{ $words }“ vo všetkých priečinkoch
    [few] { $count } výsledky pre „{ $words }“ vo všetkých priečinkoch
   *[other] { $count } výsledkov pre „{ $words }“ vo všetkých priečinkoch
}
win-search-found-in = { $count ->
    [0] Žiadne výsledky pre „{ $words }“ (rozsah: { $folder })
    [one] { $count } výsledok pre „{ $words }“ (rozsah: { $folder })
    [few] { $count } výsledky pre „{ $words }“ (rozsah: { $folder })
   *[other] { $count } výsledkov pre „{ $words }“ (rozsah: { $folder })
}
win-search-indexing = { $count ->
    [one] text { $count } správy sa ešte indexuje
   *[other] text správ ({ $count }) sa ešte indexuje
}
win-no-match-indexing = { $count ->
    [one] Text { $count } správy sa ešte indexuje, preto sa ešte môžu objaviť ďalšie výsledky.
   *[other] Text správ ({ $count }) sa ešte indexuje, preto sa ešte môžu objaviť ďalšie výsledky.
}
win-files = { $count ->
    [one] { $count } súbor
    [few] { $count } súbory
   *[other] { $count } súborov
}
win-save-attachments = &Uložiť prílohy...
win-files-not-saved = Nepodarilo sa uložiť súbory: { $failed } z { $count }.
win-new-folder-in-highlighted = Nový priečinok sa vytvorí vo vybratom priečinku.
win-delete-folder-ask = Odstrániť priečinok „{ $folder }“ so všetkými správami a podpriečinkami? Odstráni sa aj zo servera.
win-rename = &Premenovať...
win-messages-not-saved = Správy sa nepodarilo uložiť.
win-messages-not-forwarded = Správy sa nepodarilo preposlať.

## Accounts

win-sign-in-google = Prihlásiť sa cez Google
win-sign-in-microsoft = Prihlásiť sa cez Microsoft
win-next = Ď&alej >
win-your-account = vaše konto
win-browser-sign-in = (prihlásenie cez prehliadač)
win-add = &Pridať...
win-properties-button = &Vlastnosti...
win-signature-button = Textový po&dpis...
win-sign-in-apps-button = Pr&ihlasovacie aplikácie...

## AI agents

win-dont-allow = &Nepovoliť
win-col-address = Adresa
win-never-written-to = Nikdy ste nepísali
win-book-find-label = Zadajte meno alebo e-mailovú adresu:
win-send = &Odoslať
win-dont-send = &Neodoslať
win-unsubscribe = &Odhlásiť odber
win-dont-unsubscribe = &Neodhlásiť odber
win-forget-program-ask = Odstrániť uložené oprávnenia tohto programu a históriu aktivity jeho agentov? Pri ďalšom pripojení vás Inbox Classic znova požiada o povolenie.
win-clear-log-ask = Vymazať históriu aktivity agentov? Týmto sa nevrátia zmeny vykonané agentmi.
win-agent-programs = P&rogramy, ktorých agenti požiadali o prístup k vašej pošte:
win-change = &Zmeniť...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Vrá&tiť zmeny za obdobie...
win-take-back = &Vrátiť zmeny
win-what-agents-did = &Aktivita agentov:
win-agent-reads = Údaje prečítané od { $from } do { $to }:
win-agent-reads-hint = Vyberte vyššie záznam o čítaní a zobrazia sa podrobnosti o prečítaných údajoch.

## Sign-in apps

win-built-in = (vstavaná)
win-edit = &Upraviť...

## Options

win-folders-hide = Skryť zoznam priečinkov
win-folders-pin = Ponechať zoznam priečinkov vedľa správ
win-folders-show = Zobraziť priečinky

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Spustiť Inbox Classic
win-installer-welcome-new =
    Nainštaluje sa poštový program Inbox Classic { $version }.

    Práva správcu nie sú potrebné. Program sa nainštaluje iba pre vaše používateľské konto.
win-installer-welcome-same =
    Inbox Classic { $version } už je nainštalovaný. Nainštaluje sa znova.

    Vaše kontá a pošta sa zachovajú.
win-installer-welcome-update =
    Inbox Classic { $installed } sa aktualizuje na verziu { $version }.

    Ak je spustený, najprv sa zatvorí. Vaše kontá a pošta sa zachovajú.
win-installer-older-ask = Je nainštalovaný Inbox Classic { $installed }, ktorý je novší ako { $version }. Nainštalovať aj tak staršiu verziu?
win-installer-still-running = Inbox Classic je stále spustený. Zatvorte ho a skúste to znova.
win-installer-remove-mail-ask = Odstrániť aj miestne údaje Inbox Classic vrátane kont, pošty čakajúcej na odoslanie, nastavení, kontaktov a kľúčov? Pošta na serveroch zostane. Záznamy v systémovom úložisku prihlasovacích údajov sa neodstránia.
