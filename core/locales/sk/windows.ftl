# Slovenčina. Návrh, čaká na kontrolu rodeným hovoriacim (pozri core/locales/GLOSSARY.md).

## The main window

# review: new
win-still-running-detail = Inbox Classic naďalej kontroluje novú poštu na pozadí. Kliknutím na ikonu ho otvoríte. Ak ho chcete ukončiť, kliknite na ikonu pravým tlačidlom a použite jej ponuku.
# review: new
win-default-app-not-installed = Táto kópia Inbox Classic nebola nainštalovaná, preto ju Windows neuvádza medzi poštovými aplikáciami. Ak ju chcete vybrať, nainštalujte ju.
# review: new
win-default-app-settings = Windows otvorí nastavenia Predvolené aplikácie. Vyberte Inbox Classic na otváranie odkazov MAILTO.
# review: new
win-no-unread = Žiadne neprečítané správy
# review: new
win-unread-messages = { $count ->
    [one] 1 neprečítaná správa
    [few] { $count } neprečítané správy
   *[other] { $count } neprečítaných správ
}
# review: new
win-print-failed = Správu sa nepodarilo vytlačiť.
# review: new
win-print-title-of = Tlač: { $subject }
# review: new
win-no-bodies = Obsah správ nemožno zobraziť.
# review: new
win-webview-failed = Vytvorenie WebView2 zlyhalo.
# review: new
win-webview-missing = Modul runtime WebView2 nie je k dispozícii.
win-list-loading = Načítava sa...

## Buttons and words used in many windows

# review: new
win-delete-button = &Odstrániť
# review: new
win-find-label = &Hľadať:
# review: new
win-save-as-button = Uložiť &ako...
# review: new
win-too-many-files = Príliš veľa súborov naraz: vyberte menej.

## The Outbox


## The compose window

# review: new
win-editor-failed = Správy nemožno písať.
# review: new
win-ctrl-click-to-open = (otvoríte kliknutím so stlačeným klávesom { $ctrl })
# review: new
win-format-bold = Tučné ({ $ctrl }+B)
# review: new
win-format-italic = Kurzíva ({ $ctrl }+I)
# review: new
win-format-underline = Podčiarknuté ({ $ctrl }+U)
# review: new
win-format-link = Hypertextový odkaz ({ $ctrl }+K)
# review: new
win-show-cc = &Kópia
# review: new
win-show-bcc = &Skrytá kópia
# review: new
win-signature-title = Podpis: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Žiadne výsledky pre „{ $words }“ vo všetkých priečinkoch
    [one] { $count } výsledok pre „{ $words }“ vo všetkých priečinkoch
    [few] { $count } výsledky pre „{ $words }“ vo všetkých priečinkoch
   *[other] { $count } výsledkov pre „{ $words }“ vo všetkých priečinkoch
}
# review: new
win-search-found-in = { $count ->
    [0] Žiadne výsledky pre „{ $words }“ v priečinku { $folder }
    [one] { $count } výsledok pre „{ $words }“ v priečinku { $folder }
    [few] { $count } výsledky pre „{ $words }“ v priečinku { $folder }
   *[other] { $count } výsledkov pre „{ $words }“ v priečinku { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] text { $count } správy sa ešte indexuje
   *[other] text správ ({ $count }) sa ešte indexuje
}
# review: new
win-no-match-indexing = { $count ->
    [one] Text { $count } správy sa ešte indexuje, takže sa čoskoro môže nájsť viac.
   *[other] Text správ ({ $count }) sa ešte indexuje, takže sa čoskoro môže nájsť viac.
}
# review: new
win-files = { $count ->
    [one] { $count } súbor
    [few] { $count } súbory
   *[other] { $count } súborov
}
# review: new
win-click-to-retry = Kliknutím sem to skúsite znova.
# review: new
win-save-attachments = &Uložiť prílohy...
# review: new
win-files-not-saved = Nepodarilo sa uložiť { $failed } z { $count } súborov.
# review: new
win-new-folder-in-highlighted = Nový priečinok sa vytvorí vo vybratom priečinku.
# review: new
win-delete-folder-ask = Odstrániť priečinok „{ $folder }“ s jeho správami a priečinkami v ňom? Odstráni sa aj na serveri.
# review: new
win-rename = &Premenovať...
# review: new
win-messages-not-saved = Správy sa nepodarilo uložiť.
# review: new
win-messages-not-forwarded = Správy sa nepodarilo preposlať.

## Accounts

# review: new
win-sign-in-google = Prihlásiť sa cez Google
# review: new
win-sign-in-microsoft = Prihlásiť sa cez Microsoft
# review: new
win-next = Ď&alej >
# review: new
win-your-account = vaše konto
# review: new
win-browser-sign-in = (prihlásenie cez prehliadač)
# review: new
win-add = &Pridať...
# review: new
win-properties-button = &Vlastnosti...
# review: new
win-signature-button = Po&dpis...
# review: new
win-sign-in-apps-button = Prihlasovacie a&plikácie...

## AI agents

# review: new
win-dont-allow = &Nepovoliť
# review: new
win-col-address = Adresa
# review: new
win-never-written-to = Nikdy ste nepísali
# review: new
win-book-find-label = Zadajte meno alebo e-mailovú adresu:
# review: new
win-send = &Odoslať
# review: new
win-dont-send = &Neodoslať
win-unsubscribe = &Odhlásiť odber
win-dont-unsubscribe = &Neodhlásiť odber
# review: new
win-forget-program-ask = Odstrániť tento program, jeho oprávnenia a históriu aktivity jeho agentov? Pri ďalšom pripojení sa vás znova opýta na povolenie.
# review: new
win-clear-log-ask = Vymazať históriu aktivity agentov? Zmeny, ktoré agenti urobili, sa tým nevrátia.
# review: new
win-agent-programs = &Programy, ktorých agenti požiadali o prístup k vašej pošte:
# review: new
win-change = &Zmeniť...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
win-undo-since = &Vrátiť za obdobie...
# review: new
win-take-back = &Vrátiť
# review: new
win-what-agents-did = &Aktivita agentov:
# review: new
win-agent-reads = Čo sa prečítalo od { $from } do { $to }:
# review: new
win-agent-reads-hint = Vyberte vyššie riadok s prečítaným a uvidíte, čo sa prečítalo.
# review: new
win-how-to-connect = Ako pripojiť agenta

## Sign-in apps

# review: new
win-built-in = (vstavaná)
# review: new
win-edit = &Upraviť...

## Options

# review: new
win-folders-hide = Skryť zoznam priečinkov
# review: new
win-folders-pin = Ponechať zoznam priečinkov vedľa správ
# review: new
win-folders-show = Zobraziť priečinky

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Spustiť Inbox Classic
# review: new
win-installer-welcome-new =
    Nainštaluje sa Inbox Classic { $version }, e-mailový program.

    Nie sú potrebné práva správcu, inštaluje sa iba pre vaše konto.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } už je nainštalovaný. Nainštaluje sa znova.

    Vaše kontá a pošta sa zachovajú.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } sa aktualizuje na verziu { $version }.

    Ak je spustený, najprv sa zatvorí. Vaše kontá a pošta sa zachovajú.
# review: new
win-installer-older-ask = Je nainštalovaný Inbox Classic { $installed }, ktorý je novší ako { $version }. Nainštalovať aj tak staršiu verziu?
# review: new
win-installer-still-running = Inbox Classic je stále spustený. Zatvorte ho a skúste to znova.
# review: new
win-installer-remove-mail-ask = Odstrániť aj kontá a poštu, ktoré Inbox Classic uchováva v tomto počítači? Pošta na serveroch zostane.
