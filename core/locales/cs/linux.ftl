# Čeština. Koncept, čeká na kontrolu rodilým mluvčím (viz core/locales/GLOSSARY.md).

## The main window

gtk-search-looks-in = Hledání v umístění { $place } zahrnuje předměty, odesílatele, příjemce, názvy příloh a text zpráv. Zkontrolujte pravopis nebo zkuste méně slov.
gtk-search-still-indexing = { $count ->
    [one] Text 1 zprávy se stále indexuje. Brzy se mohou objevit další výsledky.
   *[other] Text { $count } zpráv se stále indexuje. Brzy se mohou objevit další výsledky.
}
gtk-search-results-everywhere = { $count ->
    [0] Žádné výsledky
    [one] 1 výsledek
    [few] { $count } výsledky
   *[other] { $count } výsledků
} pro „{ $words }“ ve všech složkách
gtk-search-results-in = { $count ->
    [0] Žádné výsledky
    [one] 1 výsledek
    [few] { $count } výsledky
   *[other] { $count } výsledků
} pro „{ $words }“ v umístění { $place }
gtk-search-indexing = { $count ->
    [one] stále se indexuje text 1 zprávy
   *[other] stále se indexuje text { $count } zpráv
}
gtk-list-loading = Načítání...
gtk-menu-rename = Přejmenovat...
gtk-import-one-question = Importovat zprávu { $file } do složky { $folder }?
gtk-files-not-saved = Celkem souborů: { $total }. Nepodařilo se uložit: { $failed }.
gtk-unsubscribe-one-click = Odhlásit odběr těchto zpráv?

    Inbox Classic pošle žádost o odhlášení na { $target }. Neotevře se žádná webová stránka a neodešle se žádný e-mail.
gtk-unsubscribe-mail = Odhlásit odběr těchto zpráv?

    K odhlášení je třeba poslat e-mail na { $target }. Inbox Classic jej připraví. Pro potvrzení odhlášení zprávu odešlete.
gtk-unsubscribe-web = Odhlásit odběr těchto zpráv?

    V prohlížeči se otevře stránka pro odhlášení odběru ({ $target }).
gtk-unsubscribe-failed = Odhlášení se nezdařilo: { $problem }
gtk-toolbar-create-mail-menu = Napsat zprávu z konkrétního účtu
gtk-toolbar-send-recv-menu = Odeslat a přijmout poštu konkrétního účtu
gtk-main-menu = Hlavní nabídka
gtk-folder-list = Seznam složek
gtk-quit = Ukončit

## The Move and Copy window

gtk-new-folder-at-top-of = Nová složka bude na nejvyšší úrovni účtu { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Žádné nepřečtené zprávy
    [one] 1 nepřečtená zpráva
    [few] { $count } nepřečtené zprávy
   *[other] { $count } nepřečtených zpráv
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Žádné zprávy nečekají na odeslání.
gtk-outbox-row = Komu: { $to }  ·  Zařazeno k odeslání: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic dál kontroluje novou poštu na pozadí. Aplikaci otevřete nebo ukončíte pomocí její ikony na horní liště.
gtk-sign-in-again-ask =
    Přihlášení k účtu { $account } bylo odmítnuto nebo relace vypršela.

    Přihlásit se znovu v prohlížeči?
gtk-default-app-not-installed = Abyste mohli zvolit Inbox Classic jako poštovní aplikaci v systému, nejprve jej nainstalujte.
gtk-default-app-now = Inbox Classic je teď vaše výchozí poštovní aplikace: e-mailové odkazy zde otevřou novou zprávu.
gtk-default-app-failed = Inbox Classic nelze nastavit jako výchozí poštovní aplikaci.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Datum:
gtk-reader-files = Přílohy zprávy
gtk-files = { $count ->
    [one] { $count } soubor
    [few] { $count } soubory
   *[other] { $count } souborů
}
gtk-pictures-blocked = Některé obrázky jsou zablokovány, aby se omezilo sledování ze strany odesílatele.
gtk-download-pictures = Stáhnout obrázky
gtk-save-attachments-menu = Uložit přílohy...

## The compose window

gtk-format-bold = Tučné (Ctrl+B)
gtk-format-italic = Kurzíva (Ctrl+I)
gtk-format-underline = Podtržené (Ctrl+U)
gtk-format-hyperlink = Hypertextový odkaz (Ctrl+K)
gtk-font = Písmo
gtk-show-cc = _Kopie
gtk-show-bcc = _Skrytá kopie
gtk-save-tip = Uložit (Ctrl+S)
gtk-link-status = { $link }    (otevřete kliknutím s klávesou Ctrl)

## Accounts

gtk-plain-warning =
    Bez šifrování může kdokoli, kdo zachytí váš síťový provoz, přečíst vaše heslo i zprávy. Toto spojení používejte jen se serverem ve vlastním počítači nebo v místní síti.

    Pokračovat?
gtk-account-name-title = Název účtu
gtk-display-name-title = Zobrazované jméno
gtk-turned-off-why = Možnost „{ $button }“ je v tomto počítači vypnutá. { $reason }
gtk-turned-off-why-long =
    Možnost „{ $button }“ je v tomto počítači vypnutá.

    { $reason }
gtk-next = Další >
gtk-provider-sign-in = Přihlaste se k účtu { $address } na webu poskytovatele ({ $provider }). Vaše heslo se aplikaci Inbox Classic nepředává. Můžete také použít heslo aplikace vytvořené v nastavení zabezpečení vašeho účtu.
gtk-provider-sign-in-apps = Přihlaste se k účtu { $address } na webu poskytovatele ({ $provider }) pomocí některé ze svých přihlašovacích aplikací (Další možnosti přihlášení). Můžete také použít heslo aplikace vytvořené v nastavení zabezpečení vašeho účtu.
gtk-accounts-add = Přidat...
gtk-accounts-properties = Vlastnosti...
gtk-accounts-signature = Podpis...
gtk-accounts-sign-in-apps = Přihlašovací aplikace...

## Sign-in apps

gtk-app-server = Server { $kind }
gtk-app-port = Port { $kind }
gtk-app-security = Zabezpečení { $kind }
gtk-issuer-found = Přihlašovací stránka: { $page }
    Koncový bod pro získání tokenů: { $endpoint }
gtk-client-id = ID klienta
gtk-client-secret = Tajný kód klienta
gtk-scopes = Oprávnění (scopes)
gtk-redirect-uri = URI přesměrování
gtk-issuer-usable =
    Vydavatele lze použít.

    { $found }
gtk-app-built-in = Přihlašovací aplikace { $app } je vestavěná. Můžete pouze určit, zda se má nabízet pro nové účty. { $reason }
gtk-built-in = { $app } (vestavěná)
gtk-offered-for-new = Nabízet pro nové účty
gtk-edit-button = Upravit...
gtk-remove-app-ask = Odebrat přihlašovací aplikaci { $app } a její uložený tajný kód klienta?
gtk-sign-in-apps-intro = Přihlašovací aplikace umožňují přihlášení k účtům přes prohlížeč. Vypnuté aplikace se nenabízejí pro nové účty. Účty, které je už používají, fungují dál.

## AI agents

gtk-agent-it-may = Povolené akce
gtk-agent-accounts = Povolené účty
gtk-never-used = Nikdy nepoužito
gtk-last-used = Naposledy použito { $date }
gtk-forget-program = Odebrat tento program?
gtk-forget-program-detail = Oprávnění programu a historie činnosti jeho agentů budou odstraněny. Při příštím připojení budete znovu požádáni o svolení.
gtk-no-agents-yet = Zatím žádný agent nepožádal o přístup k vaší poště.
gtk-nothing-yet = Zatím nic.

## Preferences

gtk-preferences = Předvolby
gtk-notify-subtitle = Jen když je Inbox Classic na pozadí

## The desktop entry and the page of the software stores

gtk-desktop-generic-name = Poštovní klient
gtk-desktop-comment = Čtení a psaní e-mailů: rychlý a jednoduchý poštovní program
gtk-desktop-keywords = pošta;e-mail;email;zprávy;doručená pošta;
gtk-metainfo-summary = Rychlý a jednoduchý poštovní program
gtk-metainfo-description = Inbox Classic je aplikace pro čtení a psaní e-mailů s klasickým rozložením: složky vlevo, seznam zpráv nahoře a obsah vybrané zprávy pod ním. Podporuje účty IMAP a SMTP. K Outlook.com a Microsoft 365 se přihlásíte přes prohlížeč.
gtk-metainfo-feature-sanitized = Zprávy se zobrazují bez skriptů a dalšího nebezpečného obsahu. Obrázky z internetu se stahují jen s vaším svolením
gtk-metainfo-feature-search = Vyhledávání v předmětech, odesílatelích, příjemcích, názvech příloh a textu zpráv s podporou operátorů známých z Gmailu
gtk-metainfo-feature-replies = Starší zprávy citované v odpovědích se sbalí a můžete je znovu rozbalit
gtk-metainfo-feature-offline = Staženou poštu lze číst i bez připojení. Hesla jsou uložena v systémové klíčence
