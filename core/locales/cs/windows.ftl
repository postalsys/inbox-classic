# Čeština. Koncept, čeká na kontrolu rodilým mluvčím (viz core/locales/GLOSSARY.md).

## The main window

# review: new
win-still-running-detail = Inbox Classic dál kontroluje novou poštu na pozadí. Kliknutím na ikonu ho otevřete. Chcete-li ho ukončit, klikněte na ikonu pravým tlačítkem a použijte její nabídku.
# review: new
win-default-app-not-installed = Tato kopie Inbox Classic nebyla nainstalována, a proto ji Windows neuvádí jako poštovní aplikaci. Chcete-li ji vybrat, nainstalujte ji.
# review: new
win-default-app-settings = Windows otevře nastavení Výchozí aplikace. Vyberte Inbox Classic pro otevírání odkazů MAILTO.
# review: new
win-no-unread = Žádné nepřečtené zprávy
# review: new
win-unread-messages = { $count ->
    [one] 1 nepřečtená zpráva
    [few] { $count } nepřečtené zprávy
   *[other] { $count } nepřečtených zpráv
}
# review: new
win-print-failed = Zprávu nelze vytisknout.
# review: new
win-print-title-of = Tisk: { $subject }
# review: new
win-no-bodies = Obsah zpráv nelze zobrazit.
# review: new
win-webview-failed = Vytvoření WebView2 se nezdařilo.
# review: new
win-webview-missing = Modul runtime WebView2 není k dispozici.

## Buttons and words used in many windows

# review: new
win-delete-button = &Odstranit
# review: new
win-find-label = &Najít:
# review: new
win-save-as-button = Uložit &jako...
# review: new
win-too-many-files = Příliš mnoho souborů najednou: vyberte jich méně.

## The Outbox


## The compose window

# review: new
win-editor-failed = Zprávy nelze psát.
# review: new
win-ctrl-click-to-open = (otevřete kliknutím s klávesou { $ctrl })
# review: new
win-format-bold = Tučné ({ $ctrl }+B)
# review: new
win-format-italic = Kurzíva ({ $ctrl }+I)
# review: new
win-format-underline = Podtržené ({ $ctrl }+U)
# review: new
win-format-link = Hypertextový odkaz ({ $ctrl }+K)
# review: new
win-show-cc = &Kopie
# review: new
win-show-bcc = &Skrytá
# review: new
win-signature-title = Podpis: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Žádné výsledky pro „{ $words }“ ve všech složkách
    [one] { $count } výsledek pro „{ $words }“ ve všech složkách
    [few] { $count } výsledky pro „{ $words }“ ve všech složkách
   *[other] { $count } výsledků pro „{ $words }“ ve všech složkách
}
# review: new
win-search-found-in = { $count ->
    [0] Žádné výsledky pro „{ $words }“ ve složce { $folder }
    [one] { $count } výsledek pro „{ $words }“ ve složce { $folder }
    [few] { $count } výsledky pro „{ $words }“ ve složce { $folder }
   *[other] { $count } výsledků pro „{ $words }“ ve složce { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] stále se indexuje text { $count } zprávy
   *[other] stále se indexuje text { $count } zpráv
}
# review: new
win-no-match-indexing = { $count ->
    [one] Text { $count } zprávy se stále indexuje, brzy se tedy může najít víc.
   *[other] Text { $count } zpráv se stále indexuje, brzy se tedy může najít víc.
}
# review: new
win-files = { $count ->
    [one] { $count } soubor
    [few] { $count } soubory
   *[other] { $count } souborů
}
# review: new
win-click-to-retry = Kliknutím sem to zkusíte znovu.
# review: new
win-save-attachments = &Uložit přílohy...
# review: new
win-files-not-saved = Některé soubory nelze uložit ({ $failed } z { $count }).
# review: new
win-new-folder-in-highlighted = Nová složka bude vytvořena uvnitř vybrané složky.
# review: new
win-delete-folder-ask = Odstranit složku „{ $folder }“ i s jejími zprávami a složkami v ní? Odstraní se i na serveru.
# review: new
win-rename = &Přejmenovat...
# review: new
win-messages-not-saved = Zprávy nelze uložit.
# review: new
win-messages-not-forwarded = Zprávy nelze přeposlat.

## Accounts

# review: new
win-sign-in-google = Přihlásit se přes Google
# review: new
win-sign-in-microsoft = Přihlásit se přes Microsoft
# review: new
win-next = &Další >
# review: new
win-your-account = váš účet
# review: new
win-browser-sign-in = (přihlášení v prohlížeči)
# review: new
win-add = &Přidat...
# review: new
win-properties-button = &Vlastnosti...
# review: new
win-signature-button = Po&dpis...
# review: new
win-sign-in-apps-button = Př&ihlašovací aplikace...

## AI agents

# review: new
win-dont-allow = &Nepovolit
# review: new
win-col-address = Adresa
# review: new
win-never-written-to = Nikdy jste nepsali
# review: new
win-book-find-label = Zadejte jméno nebo e-mailovou adresu:
# review: new
win-send = &Odeslat
# review: new
win-dont-send = &Neodesílat
# review: new
win-forget-program-ask = Odebrat tento program, jeho oprávnění a historii činnosti jeho agentů? Při příštím připojení budete znovu požádáni o svolení.
# review: new
win-clear-log-ask = Vymazat historii činnosti agentů? Změny provedené agenty se tím nevrátí zpět.
# review: new
win-agent-programs = &Programy, jejichž agenti požádali o přístup k vaší poště:
# review: new
win-change = &Změnit...
# review: new
win-what-agents-did = Či&nnost agentů:
# review: new
win-how-to-connect = Jak připojit agenta

## Sign-in apps

# review: new
win-built-in = (vestavěná)
# review: new
win-edit = &Upravit...

## Options

# review: new
win-options-language-label = &Jazyk Inbox Classic:
# review: new
win-options-restart-note = Jazyk se změní po restartu Inbox Classic.
# review: new
win-options-notify = &Upozornit mě, když přijde nová pošta
# review: new
win-restart-ask = Inbox Classic se po restartu zobrazí v jazyce { $language }. Restartovat hned?
# review: new
win-folders-hide = Skrýt seznam složek
# review: new
win-folders-pin = Ponechat seznam složek vedle zpráv
# review: new
win-folders-show = Zobrazit složky

## The installer

# review: new
win-installer-start = Spustit Inbox Classic
# review: new
win-installer-welcome-new =
    Tímto se nainstaluje Inbox Classic { $version }, poštovní program.

    Nejsou potřeba oprávnění správce, instaluje se jen pro váš účet.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } už je nainstalován. Tímto se nainstaluje znovu.

    Vaše účty a pošta zůstanou zachovány.
# review: new
win-installer-welcome-update =
    Tímto se Inbox Classic { $installed } aktualizuje na verzi { $version }.

    Pokud je spuštěný, nejdřív se ukončí. Vaše účty a pošta zůstanou zachovány.
# review: new
win-installer-older-ask = Je nainstalován Inbox Classic { $installed }, který je novější než { $version }. Přesto nainstalovat starší verzi?
# review: new
win-installer-still-running = Inbox Classic stále běží. Ukončete ho a zkuste to znovu.
# review: new
win-installer-remove-mail-ask = Odebrat také účty a poštu, které Inbox Classic uchovává v tomto počítači? Pošta na serverech zůstane.
