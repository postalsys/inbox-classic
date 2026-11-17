# Čeština. Koncept, čeká na kontrolu rodilým mluvčím (viz core/locales/GLOSSARY.md).

## The app and its menus

# review: new
mac-quit = Ukončit Inbox Classic
# review: new
mac-settings = Nastavení…
# review: new
mac-services = Služby
# review: new
mac-hide = Skrýt Inbox Classic
# review: new
mac-hide-others = Skrýt ostatní
# review: new
mac-show-all = Zobrazit vše
# review: new
mac-check-updates = Vyhledat aktualizace…
# review: new
mac-close-window = Zavřít okno
# review: new
mac-redo = Znovu
# review: new
mac-cut = Vyjmout
# review: new
mac-paste = Vložit
# review: new
mac-menu-window = Okno
# review: new
mac-minimize = Minimalizovat
# review: new
mac-zoom = Zvětšit
# review: new
mac-no-updates = Tato verze Inbox Classic nepodporuje automatické aktualizace. Stáhněte si nejnovější verzi z inboxclassic.com.

## Settings

# review: new
mac-settings-title = Nastavení
# review: new
mac-check-updates-automatically = Automaticky vyhledávat aktualizace
# review: new
mac-settings-updates = Aktualizace

## Dialogs

# review: new
mac-choose = Vybrat

## The main window

# review: new
mac-still-running-detail = Inbox Classic dál kontroluje novou poštu na pozadí. Aplikaci otevřete kliknutím na její ikonu v Docku.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } zpráva ve složce Pošta k odeslání
        [few] { $count } zprávy ve složce Pošta k odeslání
       *[other] { $count } zpráv ve složce Pošta k odeslání
    }
# review: new
mac-sending = Odesílání { $subject }…
# review: new
mac-checking = Kontrola nových zpráv v účtu { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Tato kopie Inbox Classic není balíček aplikace, a nemůže proto být výchozí poštovní aplikací.
# review: new
mac-not-made-default = Inbox Classic se nepodařilo nastavit jako výchozí poštovní aplikaci: { $reason }
# review: new
mac-tool-search = Hledat

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Text { $count } zprávy se stále indexuje, brzy se tedy může najít víc.
       *[other] Text { $count } zpráv se stále indexuje, brzy se tedy může najít víc.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Žádné výsledky pro „{ $words }“ ve všech složkách
        [one] { $count } výsledek pro „{ $words }“ ve všech složkách
        [few] { $count } výsledky pro „{ $words }“ ve všech složkách
       *[other] { $count } výsledků pro „{ $words }“ ve všech složkách
    }
# review: new
mac-results-in =
    { $count ->
        [0] Žádné výsledky pro „{ $words }“ ve složce { $folder }
        [one] { $count } výsledek pro „{ $words }“ ve složce { $folder }
        [few] { $count } výsledky pro „{ $words }“ ve složce { $folder }
       *[other] { $count } výsledků pro „{ $words }“ ve složce { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] stále se indexuje text { $count } zprávy
       *[other] stále se indexuje text { $count } zpráv
    }
# review: new
mac-folder-unread = { $folder }, nepřečtené: { $count }
# review: new
mac-import-messages = Importovat zprávy
# review: new
mac-save-messages = Uložit zprávy
# review: new
mac-save-attachments-menu = Uložit přílohy…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Některé soubory nelze uložit ({ $failed } z { $count }).
    }
# review: new
mac-no-calendar-app = V tomto Macu není k dispozici žádná kalendářová aplikace, která by otevřela pozvánky (soubory .ics).
# review: new
mac-file-not-saved = Soubor nelze uložit.
# review: new
mac-unsubscribing = Odhlašování z { $target }…
# review: new
mac-loading-list = Načítání…

## The compose window

# review: new
mac-bold = Tučné
# review: new
mac-italic = Kurzíva
# review: new
mac-underline = Podtržené
# review: new
mac-bcc = Skrytá
# review: new
mac-command-click-to-open = otevřete kliknutím s klávesou ⌘
# review: new
mac-saving-to-drafts = Ukládání do složky Koncepty…
# review: new
mac-dont-save = Neukládat

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } soubor
        [few] { $count } soubory
       *[other] { $count } souborů
    }

## Accounts

# review: new
mac-next = Další
# review: new
mac-name-placeholder = Jana Nováková
# review: new
mac-more-sign-in-options = Další možnosti přihlášení…
# review: new
mac-add-sign-in-app = Přidat přihlašovací aplikaci…
# review: new
mac-looking-up = Vyhledávání nastavení pro { $domain }…
# review: new
mac-add-button = Přidat…
# review: new
mac-properties-button = Vlastnosti…
# review: new
mac-signature-button = Podpis…
# review: new
mac-security-button = Zabezpečení…
# review: new
mac-sign-in-apps-button = Přihlašovací aplikace…

## AI agents

# review: new
mac-forget-program = Odebrat tento program a historii činnosti jeho agentů?
# review: new
mac-forget-program-detail = Oprávnění programu budou odstraněna. Při příštím připojení budete znovu požádáni o svolení.

## Sign-in apps

# review: new
mac-checking-issuer = Ověřování { $issuer }…
# review: new
mac-edit-button = Upravit…
# review: new
mac-use-for-new-accounts = Používat { $name } pro nové účty
# review: new
mac-built-in = { $name } (vestavěná)

## Other windows

# review: new
mac-new-folder-button = Nová složka…
# review: new
mac-edit-link = Upravit odkaz…
