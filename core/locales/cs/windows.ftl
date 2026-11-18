# Čeština. Koncept, čeká na kontrolu rodilým mluvčím (viz core/locales/GLOSSARY.md).

## The main window

win-still-running-detail = Inbox Classic dál kontroluje novou poštu na pozadí. Kliknutím na ikonu ho otevřete. Chcete-li ho ukončit, klikněte na ikonu pravým tlačítkem a použijte její nabídku.
win-default-app-not-installed = Abyste mohli zvolit Inbox Classic jako poštovní aplikaci ve Windows, nejprve jej nainstalujte.
win-default-app-settings = Windows otevře nastavení Výchozí aplikace. Vyberte Inbox Classic pro otevírání odkazů MAILTO.
win-no-unread = Žádné nepřečtené zprávy
win-unread-messages = { $count ->
    [one] 1 nepřečtená zpráva
    [few] { $count } nepřečtené zprávy
   *[other] { $count } nepřečtených zpráv
}
win-print-failed = Zprávu nelze vytisknout.
win-print-title-of = Tisk: { $subject }
win-no-bodies = Obsah zpráv nelze zobrazit.
win-webview-failed = Vytvoření WebView2 se nezdařilo.
win-webview-missing = Modul runtime WebView2 není k dispozici.
win-list-loading = Načítání...

## Buttons and words used in many windows

win-delete-button = Odst&ranit
win-find-label = Nají&t:
win-save-as-button = Uložit &jako...
win-too-many-files = Příliš mnoho souborů najednou: vyberte jich méně.

## The Outbox


## The compose window

win-editor-failed = Editor zpráv se nepodařilo otevřít.
win-ctrl-click-to-open = (otevřete kliknutím s klávesou { $ctrl })
win-format-bold = Tučné ({ $ctrl }+B)
win-format-italic = Kurzíva ({ $ctrl }+I)
win-format-underline = Podtržené ({ $ctrl }+U)
win-format-link = Hypertextový odkaz ({ $ctrl }+K)
win-show-cc = &Kopie
win-show-bcc = &Skrytá kopie
win-signature-title = Podpis: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Žádné výsledky pro „{ $words }“ ve všech složkách
    [one] { $count } výsledek pro „{ $words }“ ve všech složkách
    [few] { $count } výsledky pro „{ $words }“ ve všech složkách
   *[other] { $count } výsledků pro „{ $words }“ ve všech složkách
}
win-search-found-in = { $count ->
    [0] Žádné výsledky pro „{ $words }“ ve složce { $folder }
    [one] { $count } výsledek pro „{ $words }“ ve složce { $folder }
    [few] { $count } výsledky pro „{ $words }“ ve složce { $folder }
   *[other] { $count } výsledků pro „{ $words }“ ve složce { $folder }
}
win-search-indexing = { $count ->
    [one] stále se indexuje text { $count } zprávy
   *[other] stále se indexuje text { $count } zpráv
}
win-no-match-indexing = { $count ->
    [one] Text { $count } zprávy se ještě připravuje pro vyhledávání. Brzy se mohou objevit další výsledky.
   *[other] Text { $count } zpráv se ještě připravuje pro vyhledávání. Brzy se mohou objevit další výsledky.
}
win-files = { $count ->
    [one] { $count } soubor
    [few] { $count } soubory
   *[other] { $count } souborů
}
win-click-to-retry = Kliknutím sem to zkusíte znovu.
win-save-attachments = &Uložit přílohy...
win-files-not-saved = Celkem souborů: { $count }. Nepodařilo se uložit: { $failed }.
win-new-folder-in-highlighted = Nová složka bude vytvořena uvnitř vybrané složky.
win-delete-folder-ask = Odstranit složku „{ $folder }“ i s jejími zprávami a složkami v ní? Odstraní se i na serveru.
win-rename = &Přejmenovat...
win-messages-not-saved = Zprávy nelze uložit.
win-messages-not-forwarded = Zprávy nelze přeposlat.

## Accounts

win-sign-in-google = Přihlásit se přes Google
win-sign-in-microsoft = Přihlásit se přes Microsoft
win-next = &Další >
win-your-account = váš účet
win-browser-sign-in = (přihlášení v prohlížeči)
win-add = &Přidat...
win-properties-button = &Vlastnosti...
win-signature-button = Po&dpis...
win-sign-in-apps-button = Př&ihlašovací aplikace...

## AI agents

win-dont-allow = &Nepovolit
win-col-address = Adresa
win-never-written-to = Nikdy jste nepsali
win-book-find-label = Zadejte jméno nebo e-mailovou adresu:
win-send = &Odeslat
win-dont-send = &Neodesílat
win-unsubscribe = &Odhlásit odběr
win-dont-unsubscribe = &Neodhlašovat
win-forget-program-ask = Odebrat tento program, jeho oprávnění a historii činnosti jeho agentů? Při příštím připojení budete znovu požádáni o svolení.
win-clear-log-ask = Vymazat historii činnosti agentů? Změny provedené agenty se tím nevrátí zpět.
win-agent-programs = Programy, jejic&hž agenti požádali o přístup k vaší poště:
win-change = Zm&ěnit...
win-what-agents-did = Či&nnost agentů:
# review: new
win-agent-reads = Co bylo přečteno od { $from } do { $to }:
# review: new
win-agent-reads-hint = Vyberte výše řádek s přečteným a uvidíte, co bylo přečteno.
win-how-to-connect = Jak připojit agenta

## Sign-in apps

win-built-in = (vestavěná)
win-edit = &Upravit...

## Options

win-folders-hide = Skrýt seznam složek
win-folders-pin = Ponechat seznam složek vedle zpráv
win-folders-show = Zobrazit složky

## The installer

win-installer-start = Spustit Inbox Classic
win-installer-welcome-new = Nainstaluje se poštovní aplikace Inbox Classic { $version }.

    Instalace platí pouze pro váš uživatelský účet ve Windows a nevyžaduje oprávnění správce.
win-installer-welcome-same = Inbox Classic { $version } je již nainstalován. Instalace se provede znovu.

    Vaše účty a pošta zůstanou zachovány.
win-installer-welcome-update = Inbox Classic { $installed } se aktualizuje na verzi { $version }.

    Pokud je aplikace spuštěná, nejprve se ukončí. Vaše účty a pošta zůstanou zachovány.
win-installer-older-ask = Je nainstalován Inbox Classic { $installed }, který je novější než { $version }. Přesto nainstalovat starší verzi?
win-installer-still-running = Inbox Classic stále běží. Ukončete ho a zkuste to znovu.
win-installer-remove-mail-ask = Odstranit také účty a místní kopie pošty, které Inbox Classic uchovává v tomto počítači? Pošta na serverech zůstane zachována.
