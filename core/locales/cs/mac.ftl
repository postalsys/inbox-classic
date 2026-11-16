# Čeština. Koncept, čeká na kontrolu rodilým mluvčím (viz core/locales/GLOSSARY.md).

## The app and its menus

mac-quit = Ukončit Inbox Classic
mac-settings = Nastavení…
mac-services = Služby
mac-hide = Skrýt Inbox Classic
mac-hide-others = Skrýt ostatní
mac-show-all = Zobrazit vše
mac-check-updates = Vyhledat aktualizace…
mac-close-window = Zavřít okno
mac-redo = Znovu
mac-cut = Vyjmout
mac-paste = Vložit
mac-menu-window = Okno
mac-minimize = Minimalizovat
mac-zoom = Zvětšit
mac-no-updates = Tato verze Inbox Classic nepodporuje automatické aktualizace. Stáhněte si nejnovější verzi z inboxclassic.com.

## Settings

mac-settings-title = Nastavení
mac-language-label = Jazyk:
mac-restart-hint = Jazyk se změní po restartu Inbox Classic.
mac-notify-new-mail = Upozornit mě, když přijde nová pošta
mac-restart-question = Restartovat Inbox Classic hned a změnit jazyk?

## Dialogs

mac-choose = Vybrat

## The main window

mac-still-running-detail = Inbox Classic dál kontroluje novou poštu na pozadí. Aplikaci otevřete kliknutím na její ikonu v Docku.
mac-outbox-waiting =
    { $count ->
        [one] { $count } zpráva ve složce Pošta k odeslání
        [few] { $count } zprávy ve složce Pošta k odeslání
       *[other] { $count } zpráv ve složce Pošta k odeslání
    }
mac-sending = Odesílání { $subject }…
mac-checking = Kontrola nových zpráv v účtu { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Tato kopie Inbox Classic není balíček aplikace, a nemůže proto být výchozí poštovní aplikací.
mac-not-made-default = Inbox Classic se nepodařilo nastavit jako výchozí poštovní aplikaci: { $reason }
mac-tool-search = Hledat

## The folders and the message list

mac-still-indexing-more = { $count ->
    [one] Text { $count } zprávy se ještě připravuje pro vyhledávání. Brzy se mohou objevit další výsledky.
   *[other] Text { $count } zpráv se ještě připravuje pro vyhledávání. Brzy se mohou objevit další výsledky.
}
mac-results-everywhere =
    { $count ->
        [0] Žádné výsledky pro „{ $words }“ ve všech složkách
        [one] { $count } výsledek pro „{ $words }“ ve všech složkách
        [few] { $count } výsledky pro „{ $words }“ ve všech složkách
       *[other] { $count } výsledků pro „{ $words }“ ve všech složkách
    }
mac-results-in =
    { $count ->
        [0] Žádné výsledky pro „{ $words }“ ve složce { $folder }
        [one] { $count } výsledek pro „{ $words }“ ve složce { $folder }
        [few] { $count } výsledky pro „{ $words }“ ve složce { $folder }
       *[other] { $count } výsledků pro „{ $words }“ ve složce { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] stále se indexuje text { $count } zprávy
       *[other] stále se indexuje text { $count } zpráv
    }
mac-folder-unread = { $folder }, nepřečtené: { $count }
mac-import-messages = Importovat zprávy
mac-save-messages = Uložit zprávy
mac-save-attachments-menu = Uložit přílohy…
mac-files-not-saved = { $count ->
   *[other] Celkem souborů: { $count }. Nepodařilo se uložit: { $failed }.
}
mac-no-calendar-app = V tomto Macu není k dispozici žádná kalendářová aplikace, která by otevřela pozvánky (soubory .ics).
mac-file-not-saved = Soubor nelze uložit.
mac-unsubscribing = Odesílání žádosti o odhlášení odběru: { $target }…
mac-loading-list = Načítání…

## The compose window

mac-bold = Tučné
mac-italic = Kurzíva
mac-underline = Podtržené
mac-bcc = Skrytá kopie
mac-command-click-to-open = otevřete kliknutím s klávesou ⌘
mac-saving-to-drafts = Ukládání do složky Koncepty…
mac-dont-save = Neukládat

## The reading pane

mac-files =
    { $count ->
        [one] { $count } soubor
        [few] { $count } soubory
       *[other] { $count } souborů
    }

## Accounts

mac-next = Další
mac-name-placeholder = Jana Nováková
mac-more-sign-in-options = Další možnosti přihlášení…
mac-add-sign-in-app = Přidat přihlašovací aplikaci…
mac-looking-up = Vyhledávání nastavení pro { $domain }…
mac-add-button = Přidat…
mac-properties-button = Vlastnosti…
mac-signature-button = Podpis…
mac-security-button = Zabezpečení…
mac-sign-in-apps-button = Přihlašovací aplikace…

## AI agents

mac-forget-program = Odebrat tento program a historii činnosti jeho agentů?
mac-forget-program-detail = Oprávnění programu budou odstraněna. Při příštím připojení budete znovu požádáni o svolení.

## Sign-in apps

mac-checking-issuer = Ověřování vydavatele: { $issuer }…
mac-edit-button = Upravit…
mac-use-for-new-accounts = Používat přihlašovací aplikaci { $name } pro nové účty
mac-built-in = { $name } (vestavěná)

## Other windows

mac-new-folder-button = Nová složka…
mac-edit-link = Upravit odkaz…
