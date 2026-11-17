# Čeština. Koncept, čeká na kontrolu rodilým mluvčím (viz core/locales/GLOSSARY.md).

## The main window

# review: new
gtk-search-looks-in = Hledání v umístění { $place } zahrnuje předměty, odesílatele, příjemce, názvy příloh a text zpráv. Zkontrolujte pravopis nebo zkuste méně slov.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Text 1 zprávy se stále indexuje. Brzy se mohou objevit další výsledky.
   *[other] Text { $count } zpráv se stále indexuje. Brzy se mohou objevit další výsledky.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Žádné výsledky
    [one] 1 výsledek
    [few] { $count } výsledky
   *[other] { $count } výsledků
} pro „{ $words }“ ve všech složkách
# review: new
gtk-search-results-in = { $count ->
    [0] Žádné výsledky
    [one] 1 výsledek
    [few] { $count } výsledky
   *[other] { $count } výsledků
} pro „{ $words }“ v umístění { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] stále se indexuje text 1 zprávy
   *[other] stále se indexuje text { $count } zpráv
}
# review: new
gtk-list-loading = Načítání...
# review: new
gtk-menu-rename = Přejmenovat...
# review: new
gtk-import-one-question = Importovat zprávu { $file } do složky { $folder }?
# review: new
gtk-files-not-saved = Některé soubory nelze uložit ({ $failed } z { $total }).
# review: new
gtk-unsubscribe-one-click =
    Odhlásit se z této konference?

    Inbox Classic pošle žádost o odhlášení na { $target }. Neotevře se žádná webová stránka a neodešle se žádný e-mail.
# review: new
gtk-unsubscribe-mail =
    Odhlásit se z této konference?

    K odhlášení je třeba poslat e-mail na { $target }. Inbox Classic ho za vás připraví. Pro potvrzení zprávu odešlete.
# review: new
gtk-unsubscribe-web =
    Odhlásit se z této konference?

    Stránka pro odhlášení z konference se otevře v prohlížeči ({ $target }).
# review: new
gtk-unsubscribe-failed = Odhlášení se nezdařilo: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Napsat z konkrétního účtu
# review: new
gtk-toolbar-send-recv-menu = Odeslat a přijmout poštu konkrétního účtu
# review: new
gtk-main-menu = Hlavní nabídka
# review: new
gtk-folder-list = Seznam složek
# review: new
gtk-quit = Ukončit

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Nová složka bude na nejvyšší úrovni účtu { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Žádné nepřečtené zprávy
    [one] 1 nepřečtená zpráva
    [few] { $count } nepřečtené zprávy
   *[other] { $count } nepřečtených zpráv
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Žádné zprávy nečekají na odeslání.
# review: new
gtk-outbox-row = Komu: { $to }  ·  Zařazeno { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic dál kontroluje novou poštu na pozadí. Aplikaci otevřete nebo ukončíte pomocí její ikony na horní liště.
# review: new
gtk-sign-in-again-ask =
    Přihlášení k účtu { $account } bylo odmítnuto nebo relace vypršela.

    Přihlásit se znovu v prohlížeči?
# review: new
gtk-default-app-not-installed = Tato kopie Inbox Classic nebyla nainstalována, a proto ji systém neuvádí jako poštovní aplikaci. Chcete-li ji vybrat, nainstalujte ji.
# review: new
gtk-default-app-now = Inbox Classic je teď vaše výchozí poštovní aplikace: e-mailové odkazy zde otevřou novou zprávu.
# review: new
gtk-default-app-failed = Inbox Classic nelze nastavit jako výchozí poštovní aplikaci.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Datum:
# review: new
gtk-reader-files = Přílohy zprávy
# review: new
gtk-files = { $count ->
    [one] { $count } soubor
    [few] { $count } soubory
   *[other] { $count } souborů
}
# review: new
gtk-pictures-blocked = Některé obrázky byly zablokovány, aby odesílatel nemohl identifikovat váš počítač.
# review: new
gtk-download-pictures = Stáhnout obrázky
# review: new
gtk-save-attachments-menu = Uložit přílohy...

## The compose window

# review: new
gtk-format-bold = Tučné (Ctrl+B)
# review: new
gtk-format-italic = Kurzíva (Ctrl+I)
# review: new
gtk-format-underline = Podtržené (Ctrl+U)
# review: new
gtk-format-hyperlink = Hypertextový odkaz (Ctrl+K)
# review: new
gtk-font = Písmo
# review: new
gtk-show-cc = _Kopie
# review: new
gtk-show-bcc = _Skrytá
# review: new
gtk-save-tip = Uložit (Ctrl+S)
# review: new
gtk-link-status = { $link }    (otevřete kliknutím s klávesou Ctrl)

## Accounts

# review: new
gtk-plain-warning =
    Bez šifrování může kdokoli, kdo zachytí váš síťový provoz, přečíst vaše heslo i zprávy. Toto spojení používejte jen se serverem ve vlastním počítači nebo v místní síti.

    Pokračovat?
# review: new
gtk-account-name-title = Název účtu
# review: new
gtk-display-name-title = Zobrazované jméno
# review: new
gtk-turned-off-why = Možnost „{ $button }“ je v tomto počítači vypnutá. { $reason }
# review: new
gtk-turned-off-why-long =
    Možnost „{ $button }“ je v tomto počítači vypnutá.

    { $reason }
# review: new
gtk-next = Další >
# review: new
gtk-provider-sign-in = Přihlaste se k účtu { $address } na webu poskytovatele ({ $provider }). Vaše heslo se aplikaci Inbox Classic nepředává. Můžete také použít heslo aplikace vytvořené v nastavení zabezpečení vašeho účtu.
# review: new
gtk-provider-sign-in-apps = Přihlaste se k účtu { $address } na webu poskytovatele ({ $provider }) pomocí některé ze svých přihlašovacích aplikací (Další možnosti přihlášení). Můžete také použít heslo aplikace vytvořené v nastavení zabezpečení vašeho účtu.
# review: new
gtk-accounts-add = Přidat...
# review: new
gtk-accounts-properties = Vlastnosti...
# review: new
gtk-accounts-signature = Podpis...
# review: new
gtk-accounts-sign-in-apps = Přihlašovací aplikace...

## Sign-in apps

# review: new
gtk-app-server = Server { $kind }
# review: new
gtk-app-port = Port { $kind }
# review: new
gtk-app-security = Zabezpečení { $kind }
# review: new
gtk-issuer-found =
    Přihlašovací stránka: { $page }
    Koncový bod tokenu: { $endpoint }
# review: new
gtk-client-id = ID klienta
# review: new
gtk-client-secret = Tajný kód klienta
# review: new
gtk-scopes = Oprávnění (scopes)
# review: new
gtk-redirect-uri = URI přesměrování
# review: new
gtk-issuer-usable =
    Vydavatele lze použít.

    { $found }
# review: new
gtk-app-built-in = { $app } je vestavěná. Můžete jen změnit, zda se nabízí pro nové účty. { $reason }
# review: new
gtk-built-in = { $app } (vestavěná)
# review: new
gtk-offered-for-new = Nabízet pro nové účty
# review: new
gtk-edit-button = Upravit...
# review: new
gtk-remove-app-ask = Odebrat přihlašovací aplikaci { $app } a její uložený tajný kód klienta?
# review: new
gtk-sign-in-apps-intro = Přihlašovací aplikace umožňují účtům přihlásit se přes prohlížeč. Vypnutá aplikace se nenabízí pro nové účty; účty, které ji už používají, fungují dál.

## AI agents

# review: new
gtk-agent-it-may = Povolené akce
# review: new
gtk-agent-accounts = Povolené účty
# review: new
gtk-never-used = Nikdy nepoužito
# review: new
gtk-last-used = Naposledy použito { $date }
# review: new
gtk-forget-program = Odebrat tento program?
# review: new
gtk-forget-program-detail = Oprávnění programu a historie činnosti jeho agentů budou odstraněny. Při příštím připojení budete znovu požádáni o svolení.
# review: new
gtk-no-agents-yet = Zatím žádný agent nepožádal o použití vaší pošty.
# review: new
gtk-nothing-yet = Zatím nic.

## Preferences

# review: new
gtk-preferences = Předvolby
# review: changed
gtk-notify-subtitle = Jen když je Inbox Classic na pozadí

## The desktop entry and the page of the software stores

# review: new
gtk-desktop-generic-name = Poštovní klient
# review: new
gtk-desktop-comment = Čtení a psaní e-mailů: rychlý a jednoduchý poštovní program
# review: new
gtk-desktop-keywords = pošta;e-mail;email;zprávy;doručená pošta;
# review: new
gtk-metainfo-summary = Rychlý a jednoduchý poštovní program
# review: new
gtk-metainfo-description = Inbox Classic čte a píše e-maily se složkami vlevo, zprávami nahoře a zprávou pod nimi, jak to poštovní programy dělávaly. Funguje s každým účtem IMAP a SMTP a k Outlook.com a Microsoft 365 se přihlašuje přes prohlížeč.
# review: new
gtk-metainfo-feature-sanitized = Každá zpráva se zobrazuje očištěná, bez skriptů, a obrázky z internetu jen tehdy, když je povolíte
# review: new
gtk-metainfo-feature-search = Hledání, které najde slova v předmětu, u odesílatelů a příjemců, v názvech souborů i v textu, s operátory Gmailu
# review: new
gtk-metainfo-feature-replies = Odpovědi skryjí starší zprávy, které citují
# review: new
gtk-metainfo-feature-offline = Pošta zůstane čitelná i offline; hesla se uchovávají ve vaší klíčence
