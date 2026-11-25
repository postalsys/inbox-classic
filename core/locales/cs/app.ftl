# Čeština. Koncept, čeká na kontrolu rodilým mluvčím (viz core/locales/GLOSSARY.md).

## The menus

menu-file = &Soubor
menu-edit = Ú&pravy
menu-view = &Zobrazit
menu-tools = &Nástroje
menu-message = Zp&ráva
menu-help = Nápo&věda
menu-layout = Roz&ložení
menu-sort-by = S&eřadit podle
menu-text-size = Velikost &textu
menu-folder = &Složka
menu-insert = Vl&ožit

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = &Nový účet...
cmd-exit = &Konec
cmd-sync = &Odeslat a přijmout vše
cmd-mark-read = Ozna&čit jako přečtené
cmd-mark-unread = Označit jako &nepřečtené
cmd-pictures = Stáhnout &obrázky
cmd-about = O &aplikaci Inbox Classic
cmd-new-mail = &Nová zpráva
cmd-reply = Odpovědět odes&ílateli
cmd-reply-all = Odpovědět &všem
cmd-forward = &Přeposlat
cmd-help = &Obsah
cmd-delete = &Odstranit zprávu
cmd-move = Přes&unout do složky...
cmd-flag = Označit pří&znakem
cmd-new-folder = &Nová složka...
cmd-rename-folder = &Přejmenovat složku...
cmd-delete-folder = &Odstranit složku
cmd-empty-folder = V&yprázdnit složku
ui-empty-button = Vyprázdnit
cmd-accounts = Ú&čty...
cmd-find = Na&jít zprávu
cmd-save-as = &Uložit jako...
cmd-print = &Tisknout...
# review: new
cmd-print-conversation = Tisknout konver&zaci...
cmd-import = &Importovat zprávy...
cmd-outbox = &Pošta k odeslání...
cmd-properties = &Vlastnosti
cmd-mark-all-read = Označit vše j&ako přečtené
cmd-junk = Označit jako nevyžá&danou
cmd-not-junk = Označit jako v&yžádanou
cmd-archive = &Archivovat
cmd-watch-conversation = &Sledovat konverzaci
cmd-ignore-conversation = &Ignorovat konverzaci
cmd-next-message = &Další zpráva
cmd-previous-message = &Předchozí zpráva
cmd-next-unread = Další &nepřečtená zpráva
cmd-go-to-folder = Přejít do slo&žky...
cmd-find-in-message = Najít v &této zprávě...
ui-go-to-prompt = Přejít do složky:
ui-find-in-message-hint = Najít v této zprávě
ui-find-not-found = „{ $words }“ v této zprávě není
cmd-expand-all-threads = &Rozbalit všechny konverzace
cmd-collapse-all-threads = Sbal&it všechny konverzace
ui-group-by-conversation = &Seskupovat zprávy podle konverzace
# review: new
ui-show-whole-conversation = Zobrazit &celou konverzaci v podokně čtení
# review: new
ui-show-whole-conversation-note = Řádek konverzace otevře všechny její zprávy, včetně vašich odpovědí, konceptů a zpráv založených v jiných složkách. Přečtené zprávy jsou sbalené do jednoho řádku: kliknutím na řádek zprávu otevřete nebo znovu sbalíte.
# review: new
ui-conversation-order = Řaz&ení zpráv v konverzaci:
# review: new
ui-conversation-oldest-first = Nejstarší první
# review: new
ui-conversation-newest-first = Nejnovější první
# review: new
ui-thread-count = { $new ->
    [0] ({ $count })
    [one] ({ $count }, { $new } nová)
    [few] ({ $count }, { $new } nové)
   *[other] ({ $count }, { $new } nových)
}
# review: new
ui-conversation-to = komu: { $people }
# review: new
ui-conversation-draft = Koncept
# review: new
ui-conversation-alone = Podepsaná nebo šifrovaná: otevře se samostatně
# review: new
ui-conversation-downloading = Stahování…
# review: new
ui-conversation-earlier = { $count ->
    [one] Zobrazit { $count } starší zprávu
    [few] Zobrazit { $count } starší zprávy
   *[other] Zobrazit { $count } starších zpráv
}
# review: new
ui-conversation-elsewhere = { $count ->
    [one] Tato konverzace má ještě { $count } zprávu v jiné složce.
    [few] Tato konverzace má ještě { $count } zprávy v jiných složkách.
   *[other] Tato konverzace má ještě { $count } zpráv v jiných složkách.
}
# review: new
ui-conversation-this-folder = &Jen tato složka
# review: new
ui-conversation-whole = &Celá konverzace
cmd-folder-list = &Seznam složek
cmd-layout-automatic = &Automatické
cmd-layout-classic = &Klasické
cmd-layout-columns = &Sloupce
cmd-sort-date = &Datum
cmd-sort-from = &Od
cmd-sort-subject = &Předmět
cmd-sort-size = &Velikost
cmd-sort-ascending = Vz&estupně
cmd-sort-descending = &Sestupně
cmd-text-size-largest = &Největší
cmd-text-size-larger = &Větší
cmd-text-size-medium = &Střední
cmd-text-size-smaller = &Menší
cmd-text-size-smallest = Nejm&enší
cmd-hide-ignored = Skrýt i&gnorované konverzace
cmd-hide-read = Skrýt přečtené zprá&vy
cmd-notify = Upozor&nit na novou poštu
cmd-open = &Otevřít Inbox Classic
cmd-default-app = Nastavit jako &výchozí poštovní aplikaci...
cmd-view-source = &Zdrojový kód zprávy
cmd-ai-agents = &Agenti AI...
cmd-options = &Možnosti...
cmd-message-rules = Pravidla &zpráv...
cmd-encryption-keys = Šif&rovací klíče...
cmd-create-rule-from-message = Vytvořit pravidlo ze zpr&ávy...
cmd-unsubscribe = &Odhlásit odběr ze seznamu...
cmd-select-all = Vybrat &vše
cmd-undo = &Zpět
cmd-copy = &Kopírovat do složky...
cmd-address-book = A&dresář...
cmd-add-sender-to-book = Přidat odesílatele do adr&esáře
cmd-import-address-book = Importovat a&dresář...
cmd-export-address-book = &Exportovat adresář...
cmd-export-setup = Ex&portovat nastavení a účty...
cmd-import-setup = I&mportovat nastavení a účty...
cmd-compose-sign = &Digitálně podepsat
cmd-compose-encrypt = Ši&frovat
cmd-attach-my-key = Připojit můj &veřejný klíč

## The tray icon's menu

tray-check = &Zkontrolovat novou poštu
tray-no-accounts = Zatím žádné účty

## Words the windows of more than one platform share

ui-tb-create-mail = Nová zpráva
ui-tb-reply = Odpovědět
ui-tb-reply-all = Odpovědět všem
ui-tb-forward = Přeposlat
ui-tb-print = Tisk
ui-tb-delete = Odstranit
ui-tb-junk = Nevyžádaná
ui-tb-not-junk = Vyžádaná
ui-tb-archive = Archivovat
ui-tb-previous = Předchozí
ui-tb-next = Další
ui-previous-tip = Předchozí zpráva
ui-next-tip = Další zpráva
ui-tb-sync = Odeslat a přijmout
ui-tb-mark-read = Přečtené
ui-tb-mark-unread = Nepřečtené
ui-still-running = Inbox Classic stále běží
ui-no-subject = (bez předmětu)
ui-quoted = „{ $subject }“
ui-newest-from = Nejnovější zpráva: { $subject } (odesílatel: { $sender })
ui-new-messages = { $count ->
    [one] { $count } nová zpráva
    [few] { $count } nové zprávy
   *[other] { $count } nových zpráv
}
ui-outbox-waiting = { $count ->
    [one] 1 zpráva ve složce Pošta k odeslání
    [few] { $count } zprávy ve složce Pošta k odeslání
   *[other] { $count } zpráv ve složce Pošta k odeslání
}
ui-outbox-waits = { $subject } čeká ve složce Pošta k odeslání
ui-outbox-sending = Odesílání { $subject }...
ui-from-account = Z účtu { $account }
ui-sign-in-refused = Přihlášení k účtu { $account } bylo odmítnuto nebo relace vypršela.
ui-sign-in-again-ask = Přihlásit se znovu v prohlížeči?
ui-sign-in-again-failed = Nové přihlášení se nezdařilo: { $reason }
ui-unknown-reason = neznámý důvod
ui-checking = Kontrola nových zpráv v účtu { $account }...
ui-done = Hotovo
ui-sent-at = Zpráva „{ $subject }“ odeslána v { $time }
ui-draft-saved = Zpráva uložena do složky Koncepty
ui-draft-not-saved = Zprávu nelze uložit do složky Koncepty: { $reason }
ui-about-core = Jádro { $version }
ui-add-account-first = Nejdřív přidejte poštovní účet.
ui-add-account-first-link = Nejdřív přidejte poštovní účet a pak znovu klikněte na e-mailový odkaz.
ui-default-app-is = Inbox Classic je vaše výchozí poštovní aplikace: e-mailové odkazy zde otevřou novou zprávu.
ui-select-message-first = Nejdřív vyberte zprávu.
ui-store-not-opened = Úložiště pošty nelze otevřít.
ui-store-or-cert-not-opened = Úložiště pošty nebo soubor certifikátu nelze otevřít.
ui-help-title = Nápověda Inbox Classic
ui-help-missing = V této kopii Inbox Classic chybí nápověda.
ui-ok = OK
ui-cancel = Zrušit
ui-close = Zavřít
ui-col-subject = Předmět
ui-col-from = Od
ui-col-to = Komu
ui-col-received = Přijato
ui-watched-conversation = Sledovaná konverzace
ui-col-sent = Odesláno
ui-col-size = Velikost
ui-col-folder = Složka
ui-col-account = Účet
ui-col-queued = Zařazeno k odeslání
ui-col-status = Stav
ui-outbox-title = Pošta k odeslání
ui-outbox-status-waiting = Čeká
ui-outbox-status-not-sent = Neodesláno: { $reason }
ui-outbox-status-agent = Agent AI zařadil zprávu k odeslání v { $time }
ui-outbox-delete-ask = Odstranit tuto zprávu bez odeslání?
ui-open-link = Otevřít odkaz
ui-edit-link = Upravit odkaz...
ui-remove-link = Odebrat odkaz
ui-insert-attachment = Vložit přílohu
ui-insert-picture = Vložit obrázek
ui-filter-all = Všechny soubory
ui-filter-pictures = Obrázky
ui-filter-messages = Poštovní zprávy
ui-save-attachment-as = Uložit přílohu jako
ui-not-sent = Zprávu nelze odeslat.
ui-attachment-forgotten = Napsali jste „{ $word }“, ale není připojen žádný soubor. Přesto zprávu odeslat?
ui-send-anyway = Přesto odeslat
ui-go-back = Vrátit se
ui-not-saved = Zprávu nelze uložit.
ui-saving-draft = Ukládání do složky Koncepty...
ui-compose-saved-at = Uloženo do složky Koncepty v { $time }
ui-compose-restored = Obnoveno po neočekávaném ukončení Inbox Classic
ui-compose-not-saved = Neuloženo do složky Koncepty: { $reason }
ui-save-changes-ask = Chcete uložit změny této zprávy do složky Koncepty?
ui-new-message-title = Nová zpráva
ui-link-invalid = Zadejte webovou adresu (https://...) nebo e-mailový odkaz (mailto:...).
ui-link-address = Adresa:
ui-hyperlink = Hypertextový odkaz
ui-hyperlink-intro = Adresa, na kterou vybraný text odkazuje.
ui-edit-hyperlink = Upravit hypertextový odkaz
ui-edit-hyperlink-intro = Cílová adresa odkazu. Smažte adresu, chcete-li odkaz odebrat a text ponechat.
ui-not-a-picture = Obrázek nelze vložit. Vyberte čitelný soubor PNG, JPEG, GIF nebo WebP o velikosti nejvýše 10 MB.
ui-format-color = Barva písma
ui-format-numbers = Číslovaný seznam
ui-format-bullets = Seznam s odrážkami
ui-format-outdent = Zmenšit odsazení
ui-format-indent = Zvětšit odsazení
ui-format-left = Zarovnat doleva
ui-format-center = Na střed
ui-format-right = Zarovnat doprava
ui-format-line = Vložit vodorovnou čáru
ui-tb-send = Odeslat
ui-tb-save = Uložit
ui-tb-attach = Připojit
ui-tb-sign = Podepsat
ui-tb-encrypt = Šifrovat
ui-field-keys = Klíče:
ui-field-from = Od:
ui-field-to = Komu:
ui-field-cc = Kopie:
ui-field-bcc = Skrytá kopie:
ui-field-subject = Předmět:
ui-field-attach = Přílohy:
ui-signature = Podpis
ui-signature-hint = Přidává se k novým zprávám, odpovědím a přeposlaným zprávám z tohoto účtu.
ui-signature-not-saved = Podpis nelze uložit.
ui-all-inboxes = Všechny doručené
ui-all-sent = Všechny odeslané
ui-all-drafts = Všechny koncepty
ui-flagged-folder = S příznakem
ui-all-folders = Všechny složky
ui-the-account = účet
ui-folder-name = Název složky:
ui-find-hint = Hledat v poště
ui-find-tip = Hledá v předmětech zpráv, odesílatelích, příjemcích, názvech příloh a textu zpráv.
ui-clear-search = Vymazat hledání
ui-no-match = Pro hledání „{ $words }“ nebyly nalezeny žádné zprávy.
ui-no-match-all = Hledá se v předmětech, odesílatelích, příjemcích, názvech příloh a textu zpráv ve všech složkách. Zkontrolujte pravopis nebo zkuste méně slov.
ui-no-match-in = Hledání ve složce { $folder } zahrnuje předměty, odesílatele, příjemce, názvy příloh a text zpráv. Zkontrolujte pravopis nebo zkuste méně slov.
ui-no-items = V tomto zobrazení nejsou žádné položky.
ui-choose-folder = Vyberte složku, jejíž zprávy chcete zobrazit.
ui-unsubscribe = Odhlásit odběr
ui-open-in-calendar = Otevřít v kalendáři
ui-pictures-blocked = Některé obrázky jsou zablokovány, aby se omezilo sledování ze strany odesílatele.
ui-not-shown = Zprávu nelze zobrazit.
ui-attachment-not-read = Přílohu nelze přečíst.
ui-attachment-not-saved = Přílohu nelze uložit.
ui-not-downloaded = Zpráva ještě není stažena.
ui-leave-list = Odhlásit odběr těchto zpráv?
ui-leave-one-click = Inbox Classic pošle žádost o odhlášení na { $target }. Neotevře se žádná webová stránka a neodešle se žádný e-mail.
ui-leave-mail = K odhlášení je třeba poslat e-mail na { $target }. Inbox Classic ho za vás připraví. Pro potvrzení zprávu odešlete.
ui-leave-web = V prohlížeči se otevře stránka pro odhlášení odběru ({ $target }).
ui-unsubscribing = Odesílání žádosti o odhlášení odběru: { $target }...
ui-cannot-unsubscribe = Tato zpráva nenabízí možnost odhlášení.
ui-unsubscribed = Žádost o odhlášení odběru byla přijata. To ještě nepotvrzuje, že zasílání zpráv skončilo.
ui-not-unsubscribed = Odhlášení se nezdařilo: { $reason }
ui-list-bar = Tato zpráva je z rozesílacího seznamu ({ $domain }).
ui-list-bar-plain = Tato zpráva je z rozesílacího seznamu.
ui-list-bar-asked = O odhlášení odběru z tohoto seznamu jste požádali dne { $date }.
ui-list-bar-came-after = O odhlášení jste požádali dne { $date }, ale tato zpráva přišla o více než dva dny později.
ui-list-bar-opened = Stránku pro odhlášení odběru z tohoto seznamu jste otevřeli dne { $date }.
ui-list-bar-failed = Žádost o odhlášení se nezdařila: { $reason }
ui-unsubscribe-ask = Odhlásit odběr…
ui-unsubscribe-again = Znovu odhlásit odběr…
ui-event-span = { $start } až { $end }
ui-event-floating = { $when } (bez převodu časového pásma)
ui-invitation = Pozvánka: { $title }
ui-invitation-updated = Aktualizovaná pozvánka: { $title }
ui-invitation-canceled = Zrušeno: { $title }
ui-invitation-answer = Odpověď na pozvánku: { $title }
ui-no-title = (bez názvu)
ui-organizer = Organizátor: { $name }
ui-invitation-not-read = Pozvánku nelze přečíst.
ui-no-calendar = Pozvánku (soubor .ics) se nepodařilo otevřít v kalendáři. Zkontrolujte, zda je nainstalovaná kalendářová aplikace a zda otevírá soubory .ics.
ui-messages-not-changed = Zprávy nelze změnit.
ui-new-folder-in-selected = Nová složka bude vytvořena uvnitř vybrané složky.
ui-new-folder-at-top = Nová složka bude vytvořena na nejvyšší úrovni účtu.
ui-folder-not-created = Složku nelze vytvořit.
ui-folder-not-renamed = Složku nelze přejmenovat.
ui-folder-not-deleted = Složku nelze odstranit.
ui-rename-folder-intro = Zadejte nový název složky „{ $folder }“.
ui-properties-of = Vlastnosti: { $subject }
ui-internet-headers = Internetové hlavičky této zprávy:
ui-save-messages-in = Vybrat složku pro uložení zpráv
ui-save-message-as = Uložit zprávu jako
ui-import-choose-folder = Nejdřív vyberte složku, do které se mají zprávy importovat.
ui-add-account-title = Přidat poštovní účet
ui-accounts-title = Účty
ui-security-none = Žádné (nešifrováno)
ui-field-required = Pole { $field } je povinné.
ui-email-invalid = E-mailová adresa není platná.
ui-ports-invalid = Porty jsou čísla od 1 do 65535.
ui-looking-up = Vyhledávání nastavení pro { $domain }...
ui-found-none = Zadejte údaje k účtu podle pokynů svého poskytovatele e-mailu.
ui-found-change = Pokud vám poskytovatel sdělil jiné nastavení, upravte tyto údaje.
ui-found-guess = Pro tuto adresu nebyla nalezena žádná nastavení. Navržené názvy serverů jsou odhady. Ověřte si je u svého poskytovatele.
ui-found-mx = Inbox Classic rozpoznal vašeho poskytovatele e-mailu a vyplnil nastavení jeho serverů.
ui-found-srv = Tato nastavení byla nalezena v záznamech DNS vaší domény.
ui-found-autodiscover = Tato nastavení byla nalezena službou Microsoft Autodiscover (Exchange).
ui-found-other = Pro tuto adresu byla nalezena tato nastavení.
ui-app-password-needed = Poskytovatel: { $provider }. Pokud váš účet podporuje hesla aplikací, vytvořte si jedno v jeho nastavení zabezpečení a zadejte ho do pole Heslo v dalším formuláři. Jinak použijte přihlášení přes prohlížeč, je-li k dispozici.
ui-app-password-open = Otevřít v prohlížeči pokyny poskytovatele { $provider }?
ui-plain-warning = Bez šifrování může kdokoli, kdo zachytí váš síťový provoz, přečíst vaše heslo i zprávy. Pokračujte pouze tehdy, je-li spojení chráněno jiným způsobem; samotná místní síť šifrování neposkytuje.
ui-continue-ask = Pokračovat?
ui-add-sign-in-app = Přidat přihlašovací aplikaci...
ui-turned-off = Možnost „{ $name }“ je v tomto počítači vypnutá.
ui-off-here = V tomto počítači vypnuto.
ui-why = Proč?
ui-more-sign-in = Další možnosti přihlášení...
ui-other-account = Chcete-li přidat jiný e-mailový účet, zadejte svou e-mailovou adresu a jméno, které mají vidět příjemci. Nastavení serverů se vyhledá v dalším kroku.
ui-field-account-name = Název účtu:
ui-field-name = Zobrazované jméno:
ui-field-email = E-mailová adresa:
ui-field-user = Uživatelské jméno:
ui-field-password = Heslo:
ui-field-imap-host = Server příchozí pošty (IMAP):
ui-field-imap-port = Port IMAP:
ui-field-imap-security = Zabezpečení IMAP:
ui-field-smtp-host = Server odchozí pošty (SMTP):
ui-field-smtp-port = Port SMTP:
ui-field-smtp-security = Zabezpečení SMTP:
ui-field-other-addresses = Další adresy, ze kterých odesíláte:
ui-sign-in-not-started = Přihlášení přes prohlížeč nelze spustit.
ui-sign-in-in-browser = Přihlaste se k účtu { $account } v okně prohlížeče, které se otevřelo, a pak se vraťte sem.
ui-sign-in-failed = Přihlášení se nezdařilo: { $reason }
ui-account-not-saved = Účet nelze uložit.
ui-start-intro = Gmail, Google Workspace, Outlook.com a Microsoft 365: přihlaste se přímo na stránce Googlu nebo Microsoftu. Heslo zadáváte tam, nikdy do aplikace Inbox Classic.
ui-start-intro-apps = Přihlaste se přes prohlížeč pomocí některé ze svých přihlašovacích aplikací (Další možnosti přihlášení), nebo níže přidejte libovolný e-mailový účet se svým jménem a adresou.
ui-use-app-password = Použít heslo aplikace
ui-the-provider = poskytovatel
ui-provider-intro = Přihlaste se k účtu { $email } na webu poskytovatele ({ $provider }). Vaše heslo se aplikaci Inbox Classic nepředává. Pokud váš účet podporuje hesla aplikací, můžete si jedno vytvořit v nastavení zabezpečení. Pro účty Outlook.com a Microsoft 365 je nutné přihlášení přes prohlížeč.
ui-provider-intro-apps = Přihlaste se k účtu { $email } na webu poskytovatele ({ $provider }) pomocí některé ze svých přihlašovacích aplikací (Další možnosti přihlášení). Pokud váš účet podporuje hesla aplikací, můžete si jedno vytvořit v nastavení zabezpečení. Pro účty Outlook.com a Microsoft 365 je nutné přihlášení přes prohlížeč.
ui-finish = Dokončit
ui-logon = Přihlášení
ui-enter-password = Zadejte heslo k účtu { $account }.
ui-signs-in-with = Přihlašovací aplikace: { $app }. Přihlášení probíhá v prohlížeči a účet používá servery této aplikace.
ui-keep-password = Chcete-li zachovat současné heslo, ponechte pole hesla prázdné.
ui-remove-account = Odebrat účet
ui-remove-account-ask = Odebrat tento účet z aplikace Inbox Classic? Odstraní se jeho místní data, včetně čekajících zpráv ve složce Pošta k odeslání a uložených přihlašovacích údajů. Pošta na serveru se nezmění.
ui-col-email = E-mailová adresa
ui-col-incoming = Server příchozí pošty
ui-type-email = Zadejte svou e-mailovou adresu, jmeno@example.com.
ui-ai-agent = Agent AI
ui-ai-agent-access = Přístup agenta AI
ui-ai-agents = Agenti AI
ui-program-path = Program: { $path }
ui-it-may = Povolené akce:
ui-accounts-it-may-use = Povolené účty:
ui-send-message-ask = Odeslat zprávu?
ui-col-name = Název
ui-never = Nikdy
ui-connect-agent = Připojit agenta AI
ui-connect-agent-intro = Do nastavení serverů MCP svého agenta přidejte následující konfiguraci (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Program
ui-col-may = Oprávnění
ui-col-last-used = Naposledy použito
ui-col-when = Kdy
ui-col-what = Akce
ui-sign-in-app = Přihlašovací aplikace
ui-sign-in-apps = Přihlašovací aplikace
ui-add-sign-in-app-title = Přidat přihlašovací aplikaci
ui-preset-app-name = Přihlašovací aplikace { $provider }
ui-issuer-not-checked = vydavatele nelze ověřit
ui-checking-issuer = Ověřování vydavatele: { $issuer }...
ui-issuer-unusable = Vydavatele nelze použít: { $reason }
ui-issuer-usable = Vydavatele lze použít.
ui-sign-in-app-not-saved = Přihlašovací aplikaci nelze uložit: { $reason }
ui-check = &Ověřit
ui-fill-in-for = Použít nastavení pro:
ui-app-name = Název:
ui-issuer = Vydavatel:
ui-client-id = ID klienta:
ui-client-secret = Tajný kód klienta:
ui-scopes = Oprávnění (scopes):
ui-imap-server = Server IMAP:
ui-smtp-server = Server SMTP:
ui-redirect-uri = URI přesměrování:
ui-sign-in-app-intro = Přihlašovací aplikace je klient OAuth, kterého zaregistrujete u svého poskytovatele, abyste se mohli přihlašovat přes prohlížeč. Zvolte poskytovatele, aby se vyplnila jeho nastavení, a pak přidejte ID klienta a tajný kód klienta, pokud vám ho poskytovatel dal.
ui-remove-secret = Tajný kód klienta je uložen. Zadejte nový, který ho nahradí, nebo uložený kód odeberte
ui-register-it = Zaregistrujte aplikaci u svého poskytovatele
ui-built-in-note = Přihlašovací aplikace { $name } je vestavěná. Můžete pouze určit, zda se má nabízet pro nové účty.
ui-client-with-secret = ID klienta: { $client }, s tajným kódem klienta.
ui-client-public = ID klienta: { $client }, veřejný klient (bez tajného kódu).
ui-no-accounts = Žádné účty
ui-remove-sign-in-app = Odebrat přihlašovací aplikaci
ui-remove-sign-in-app-ask = Odebrat přihlašovací aplikaci { $name } a její uložený tajný kód klienta?
ui-sign-in-app-not-removed = Přihlašovací aplikace nebyla odebrána. { $reason }
ui-sign-in-apps-intro = Přihlašovací aplikace umožňují přihlášení k účtům přes prohlížeč. Nezaškrtnuté aplikace se nenabízejí pro nové účty. Účty, které je už používají, fungují dál.
ui-col-issuer = Vydavatel
ui-col-used-by = Používá
ui-options-system-default = Výchozí podle systému ({ $language })
ui-settings-general = Obecné
ui-settings-reading = Čtení
ui-settings-new-mail = Nová pošta
ui-settings-sending = Odesílání
ui-settings-default-apps = Výchozí aplikace
ui-settings-message-list = Seznam zpráv
ui-settings-messages = Zprávy
ui-settings-encryption = Šifrování
ui-settings-language = Jazyk
ui-settings-label = { $label }:
ui-apply = &Použít
# review: new
ui-settings-sync = Synchronizace
# review: new
ui-sync-note = Udržujte účty, klíče, Adresář, pravidla a nastavení stejné na každém počítači, a to přes složku nebo úložiště, které vlastníte. Vše se zašifruje vaší heslovou frází synchronizace dříve, než opustí tento počítač.
# review: new
ui-sync-place = Synchronizováno přes:
# review: new
ui-sync-status = Stav:
# review: new
ui-sync-set-up = &Nastavit synchronizaci…
# review: new
ui-sync-now = Synchronizovat n&yní
# review: new
ui-sync-computers = Počíta&če…
# review: new
ui-sync-history = &Historie…
# review: new
ui-sync-turn-off = &Vypnout synchronizaci…
# review: new
ui-sync-what = Co synchronizovat
# review: new
ui-sync-what-note = Hesla, přihlášení a soukromé klíče se přenášejí jen zašifrované. Vynechte, co má zůstat jen v tomto počítači.
# review: new
ui-sync-accounts = Úč&ty
# review: new
ui-sync-passwords = Hes&la
# review: new
ui-sync-sign-ins = Př&ihlášení přes Google, Microsoft a přihlašovací aplikace
# review: new
ui-sync-sign-in-apps = Přihlašovací &aplikace
# review: new
ui-sync-app-secrets = Ta&jné kódy přihlašovacích aplikací
# review: new
ui-sync-contacts = A&dresář
# review: new
ui-sync-keys = &Klíče
# review: new
ui-sync-private-keys = Vaše &soukromé klíče
# review: new
ui-sync-rules = P&ravidla
# review: new
ui-sync-trusted = Důvěryhodní &odesílatelé
# review: new
ui-sync-settings = Nastav&ení
# review: new
ui-sync-preferences = Rozvržení a &zobrazení
# review: new
ui-sync-everything = Vše
# review: new
ui-sync-some-left-out = Něco je vynecháno
# review: new
ui-sync-where = Kam ukládat
# review: new
ui-sync-folder = Složka
# review: new
ui-sync-folder-note = Dropbox, OneDrive, iCloud Drive, Google Drive, Nextcloud nebo Syncthing ji zkopíruje na vaše další počítače.
# review: new
ui-sync-bucket = Úložiště kompatibilní s S3
# review: new
ui-sync-bucket-note = Amazon S3, Cloudflare R2, Backblaze B2, MinIO nebo jiné úložiště, které funguje jako S3.
# review: new
ui-sync-folder-label = &Složka:
# review: new
ui-sync-folder-none = Zatím nevybrána
# review: new
ui-sync-choose-folder = &Vybrat…
# review: new
ui-sync-choose-folder-title = Vyberte složku pro synchronizaci
# review: new
ui-sync-endpoint = &Koncový bod:
# review: new
ui-sync-region = &Oblast:
# review: new
ui-sync-bucket-name = &Bucket:
# review: new
ui-sync-prefix = Složka v b&ucketu:
# review: new
ui-sync-access-key = &ID přístupového klíče:
# review: new
ui-sync-secret-key = &Tajný přístupový klíč:
# review: new
ui-sync-next = &Další
# review: new
ui-sync-join-title = Připojit se k synchronizaci
# review: new
ui-sync-join-note = Na tomto místě je synchronizace vašich dalších počítačů. Zadejte heslovou frázi synchronizace, kterou jste zvolili na prvním z nich.
# review: new
ui-sync-start-title = Spustit synchronizaci
# review: new
ui-sync-start-note = Zvolte heslovou frázi synchronizace. Zadáte ji jednou na každém počítači, který přidáte. Uložte si ji na bezpečné místo: bez ní se žádný další počítač nepřipojí.
# review: new
ui-sync-name = &Název tohoto počítače:
# review: new
ui-sync-merge-note = Co má tento počítač a co obsahuje synchronizace, se spojí: účet nebo kontakt, který je na obou místech, bude jen jeden.
# review: new
ui-sync-turn-on = Za&pnout synchronizaci
# review: new
ui-sync-on = Synchronizace je zapnutá.
# review: new
ui-sync-turn-off-ask = Vypnout synchronizaci v tomto počítači? Vše zůstane, jak je, zde i na vašich dalších počítačích. Tento počítač se jen přestane synchronizovat.
# review: new
ui-sync-turn-off-button = Vypnout
# review: new
ui-sync-computers-title = Počítače
# review: new
ui-sync-computers-note = Počítače, které se synchronizují přes toto místo. Odeberte ten, který už nepoužíváte: přestane se synchronizovat a to, co synchronizoval, zůstane.
# review: new
ui-sync-this-computer = Tento počítač
# review: new
ui-sync-seen = Naposledy synchronizováno: { $when }
# review: new
ui-sync-remove-ask = Odebrat počítač „{ $name }“ ze synchronizace? Při příštím pokusu se přestane synchronizovat. Chcete-li jej znovu synchronizovat, nastavte na něm synchronizaci znovu.
# review: new
ui-sync-loading = Načítání…
# review: new
ui-sync-history-title = Historie
# review: new
ui-sync-history-note = Když byla stejná věc změněna na dvou počítačích současně, zůstala změna provedená jako poslední a ta druhá je zde. Obnovte ji, chcete-li místo toho použít ji.
# review: new
ui-sync-history-empty = Žádné změny nebyly nahrazeny.
# review: new
ui-sync-history-row = Zdroj: { $source }, { $when }
# review: new
ui-sync-restore = Obno&vit
# review: new
ui-sync-restore-points = Body obnovení
# review: new
ui-sync-restore-points-note = Než synchronizace něco v tomto počítači odebere, uloží se předchozí stav. Otevřete bod obnovení a vraťte z něj, co si vyberete.
# review: new
ui-sync-restore-points-empty = Zatím žádné.
# review: new
ui-sync-open-point = &Otevřít…
# Set Up Sync on Windows: back from its second step to the first, as a wizard's Back button
# review: new
win-sync-back = < &Zpět
ui-language-label = &Jazyk:
ui-restart-note = Jazyk se změní po restartu Inbox Classic.
ui-restart-ask = Vybraný jazyk ({ $language }) se použije po restartu aplikace Inbox Classic. Restartovat hned?
ui-notify-new-mail = &Upozornit mě, když přijde nová pošta
ui-new-folder-title = Nová složka
ui-rename-folder-title = Přejmenovat složku
ui-delete-folder-question = Odstranit složku „{ $folder }“ i s jejími zprávami a složkami v ní? Odstraní se i na serveru.
ui-properties = V&lastnosti
ui-account-sync = Odeslat a &přijmout
ui-account-properties = &Vlastnosti...
# review: new
ui-account-properties-of = Vlastnosti úč&tu...
ui-account-move-up = Posunout na&horu
ui-account-move-down = Posunout &dolů
ui-menu-open = &Otevřít
ui-menu-flag = P&říznak
ui-menu-view-source = Zobrazit &zdrojový kód
# Context menu: the same action as cmd-unsubscribe, with its own access key.
ui-menu-unsubscribe = &Odhlásit odběr ze seznamu...
ui-save-attachments = Uložit přílohy
ui-attachment-open = Otevřít
ui-attachment-save-as = Uložit jako...
ui-attachment-save-all = Uložit vše...
ui-attachment-show-in-message = Zobrazit ve zprávě
ui-attachments-strip = Přílohy
ui-attachment-note-title = Otevření tohoto souboru
ui-attachment-program-tip = Tento typ souboru může spouštět programy, proto jej zde nelze přímo otevřít. Pokud jej chcete otevřít sami, nejprve jej uložte.
ui-clear-flag = Zr&ušit příznak
ui-button-move = &Přesunout
ui-button-copy = &Kopírovat
ui-find-folder = Najít složku
ui-new-folder-in = Nová složka bude ve složce { $folder }.
ui-outbox-send-all = &Odeslat vše hned
ui-yes = Ano
ui-no = Ne
ui-try-again = Zkusit znovu
ui-remove = Ode&brat
ui-signature-of = Podpis: { $account }
ui-sign-in-with = Přihlásit se přes { $provider }
ui-sign-in-in-browser-yours = Přihlaste se ke svému účtu v okně prohlížeče, které se otevřelo, a pak se vraťte sem.
ui-browser-sign-in-server = { $server } (přihlášení v prohlížeči)
ui-dont-allow = Nepovolit
ui-allow = &Povolit
ui-dont-send = Neodesílat
ui-dont-unsubscribe = Neodhlašovat
ui-edit-first = Nejdřív &upravit
ui-new-address = Nová adresa
ui-turn-away = O&dmítnout
ui-clear-agent-log = Vymazat historii činnosti agentů?
ui-clear-agent-log-detail = Změny provedené agenty se tím nevrátí zpět.
ui-let-agents-connect = &Povolit agentům AI připojení k Inbox Classic
ui-change-button = Změnit…
ui-undo-button = Zpět
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Vrátit změny za období…
ui-undo-since-span = Vrátit změny tohoto programu:
ui-take-back = Vrátit změny
ui-rules-title = Pravidla zpráv
ui-rules-intro = Pravidla zpracovávají nové zprávy v Doručené poště, když je Inbox Classic spuštěný. Pravidla, jejichž podmínky zpráva splňuje, se použijí v uvedeném pořadí. Jakmile některé přesune zprávu z Doručené pošty, další se už nepoužijí.
ui-rules-none = Zatím nemáte žádná pravidla. Vytvořte první kliknutím na Nové.
ui-rule-new = &Nové...
ui-rule-edit = &Upravit...
ui-rule-delete-button = Od&stranit
ui-rule-title = Pravidlo zpráv
ui-rule-name = Název:
ui-rule-account = Účet:
ui-rule-all-accounts = Všechny účty
ui-rule-query = Kritéria hledání:
ui-rule-query-hint = Použijte výrazy hledání, například from:ann@example.com, subject:faktura nebo list:news.example.com, stejně jako v poli hledání.
ui-rule-count = { $count ->
    [one] Těmto kritériím teď odpovídá 1 zpráva v Doručené poště.
    [few] Těmto kritériím teď odpovídají { $count } zprávy v Doručené poště.
   *[other] Těmto kritériím teď odpovídá { $count } zpráv v Doručené poště.
}
ui-rule-show = &Zobrazit
ui-rule-actions = Akce:
ui-rule-move = &Přesunout do:
ui-rule-mark-read = Označit jako p&řečtenou
ui-rule-flag = Ozna&čit příznakem
ui-rule-archive = &Archivovat
ui-rule-junk = Přesunout do složky &Nevyžádaná pošta
ui-rule-delete = &Odstranit
ui-rule-quiet = Neupozorňova&t mě na ni
ui-rule-apply-now = Použít také na zprávy, které už jsou v &Doručené poště
ui-rule-delete-ask = Odstranit pravidlo „{ $name }“?
ui-create-rule = Vytvořit pravidlo...
ui-rules-applied = { $count ->
    [one] Pravidla zpracovala 1 zprávu
    [few] Pravidla zpracovala { $count } zprávy
   *[other] Pravidla zpracovala { $count } zpráv
}
ui-col-rule-matches = Kritéria
ui-clear-button = &Vymazat
ui-how-to-connect = Jak připojit agenta…
ui-agent-programs = Programy, jejichž agenti požádali o přístup k vaší poště
ui-what-agents-did = Činnost agentů
ui-restart-now = &Restartovat hned
ui-restart-later = &Později

## The Address Book

ui-tb-new-contact = Nový kontakt
ui-tb-new-group = Nová skupina
ui-tb-properties = Vlastnosti
ui-tb-write-to = Napsat zprávu
ui-menu-new-contact = Nový &kontakt...
ui-menu-new-group = Nová &skupina...
ui-menu-write-to = &Napsat zprávu
ui-menu-delete = &Odstranit
ui-book-find-hint = Zadejte jméno nebo e-mailovou adresu
ui-book-all-contacts = Všechny kontakty
ui-col-phone = Telefon
ui-book-empty = Adresář je prázdný. Přidejte kontakt tlačítkem Nový kontakt nebo importujte soubor vCard či CSV z nabídky Soubor.
ui-book-no-match = Pro hledání „{ $words }“ nebyly nalezeny žádné kontakty.
ui-book-delete-ask = { $count ->
    [one] Odstranit tento kontakt z Adresáře?
   *[other] Odstranit tyto kontakty ({ $count }) z Adresáře?
}
ui-group-delete-ask = Odstranit skupinu „{ $name }“? Její členové zůstanou v Adresáři.
ui-book-no-address = { $name } nemá žádnou e-mailovou adresu.
ui-new-contact-title = Nový kontakt
ui-contact-title = Vlastnosti: { $name }
ui-contact-first = Jméno:
ui-contact-last = Příjmení:
ui-contact-display = Zobrazované jméno:
ui-contact-nickname = Přezdívka:
ui-contact-company = Společnost:
ui-contact-addresses = E-mailové adresy:
ui-contact-address-hint = Zadejte e-mailovou adresu
ui-contact-add = &Přidat
ui-contact-set-default = Nastavit jako &výchozí
ui-contact-default = { $address } (výchozí)
ui-contact-phones = Telefonní čísla:
ui-phone-home = Domů
ui-phone-work = Práce
ui-phone-mobile = Mobil
ui-phone-other = Jiný
ui-contact-notes = Poznámky:
ui-contact-name-needed = Zadejte jméno nebo e-mailovou adresu kontaktu.
ui-contact-address-invalid = „{ $address }“ není platná e-mailová adresa.
ui-contact-not-saved = Kontakt nelze uložit: { $reason }
ui-new-group-title = Nová skupina
ui-group-title = Vlastnosti: { $name }
ui-group-name = Název skupiny:
ui-group-members = Členové:
ui-group-select-members = &Vybrat členy...
ui-group-new-member = Přidat e-mailovou adresu, která není v Adresáři:
ui-group-name-needed = Zadejte název skupiny.
ui-group-not-saved = Skupinu nelze uložit: { $reason }
ui-group-members-count = { $count ->
    [one] 1 člen
    [few] { $count } členové
   *[other] { $count } členů
}
ui-select-recipients = Vybrat příjemce
ui-select-members = Vybrat členy skupiny
ui-pick-intro = Zadejte jméno nebo ho vyberte ze seznamu:
ui-pick-recipients = Příjemci zprávy:
ui-pick-members = Členové skupiny:
ui-pick-to = &Komu →
ui-pick-cc = K&opie →
ui-pick-bcc = &Skrytá kopie →
ui-pick-add = &Přidat →
ui-pick-tip = Vybrat příjemce z Adresáře
ui-filter-address-books = Adresáře (vCard, CSV)
ui-filter-vcard = Soubory vCard
ui-book-export-name = Adresář
ui-book-imported = { $added ->
    [one] Přidán 1 kontakt.
    [few] Přidány { $added } kontakty.
   *[other] Přidáno { $added } kontaktů.
} { $skipped ->
    [one] Přeskočen 1 kontakt, který už je v Adresáři.
    [few] Přeskočeny { $skipped } kontakty, které už jsou v Adresáři.
   *[other] Přeskočeno { $skipped } kontaktů, které už jsou v Adresáři.
}
ui-book-not-imported = Adresář nelze importovat: { $reason }
ui-book-exported = { $count ->
    [one] 1 kontakt uložen do souboru { $file }.
    [few] { $count } kontakty uloženy do souboru { $file }.
   *[other] { $count } kontaktů uloženo do souboru { $file }.
}
ui-book-not-exported = Adresář nelze uložit: { $reason }
ui-code-copied = Kód zkopírován
ui-codes-in-notifications = &Zobrazovat přihlašovací kódy v oznámeních o nové poště
ui-tool-unread-only = Nepřečtené
ui-no-unread = Nejsou tu žádné nepřečtené zprávy.
ui-pictures-always-sender = Vždy stahovat obrázky od { $sender }
ui-pictures-always-domain = Vždy stahovat obrázky od všech z domény { $domain }
ui-pictures-unconfirmed = Doménu odesílatele ({ $domain }) nelze ověřit, proto se obrázky v této zprávě nestahují automaticky.
ui-pictures-always-option = Stah&ovat obrázky ve všech zprávách
ui-pictures-always-warning = Odesílatelé pak mohou zjistit, kdy čtete jejich zprávy.
ui-protection-details = &Podrobnosti...
ui-protection-details-title = Podrobnosti zabezpečení
ui-download-heading = Stahování
ui-download-ahead = &Stahovat zprávy předem:
ui-download-ahead-recent = Nedávné zprávy o velikosti do 1 MB
ui-download-ahead-all = Všechny zprávy
ui-download-ahead-never = Jen při otevření
ui-download-limit = &Limit místa pro každý účet:
ui-send-delay = Pr&odleva před odesláním:
ui-send-delay-note = Během odpočítávání můžete odeslání zrušit příkazem Zpět. Tato možnost končí po uplynutí odpočítávání, i když zpráva stále čeká na odeslání.
ui-dark-messages = Zobrazovat zprávy na tmavém pozadí, když je systém v tmavém režimu
ui-preview-show = Zobrazovat pří&lohy ve zprávách
ui-preview-show-note = Zobrazuje obrázky a první stránky souborů PDF pod textem zprávy. Inbox Classic vytváří tyto náhledy sám, bez spouštění skriptů nebo jiného aktivního obsahu souborů.
ui-preview-pdfs = Zobrazovat soubory PD&F ve zprávách
ui-sending-in = { $subject } se odešle za { $count ->
    [one] 1 sekundu
    [few] { $count } sekundy
   *[other] { $count } sekund
}
ui-send-undone = Odeslání bylo zrušeno: { $subject }. Zpráva je znovu otevřená k úpravám.
ui-send-too-late = Odeslání už nelze zrušit: { $subject }.
ui-outbox-status-undo = Odeslání nejdříve v { $time }
ui-download-note = Zprávy stažené předem se otevřou okamžitě. Po překročení limitu se nejstarší obsah z mezipaměti odstraní a při otevření zprávy znovu stáhne. Koncepty a zprávy otevřené od spuštění aplikace zůstávají zachovány, takže velikost může limit překročit.
ui-attachment-downloading = Stahování této zprávy ještě neskončilo. Zkuste to znovu po dokončení stahování.
ui-trusted-senders-button = &Důvěryhodní odesílatelé...
ui-trusted-senders-title = Důvěryhodní odesílatelé
ui-trusted-senders-note = Obrázky ve zprávách od těchto odesílatelů se stahují automaticky, když váš poskytovatel pošty ověří doménu odesílatele.
ui-trusted-everyone-at = Všichni z domény { $domain }
ui-trusted-senders-empty = Zatím nebyli přidáni žádní důvěryhodní odesílatelé.
ui-search-encrypted = Hledat v &šifrovaných zprávách
ui-search-encrypted-note = Pokud je k dispozici odpovídající soukromý klíč, může Inbox Classic na tomto počítači dešifrovat stažené nebo otevřené zprávy. Pak můžete hledat v jejich textu a seznam zobrazí začátek textu i předmět ze šifrované části, pokud je uveden. Dešifrovaný obsah se ukládá nešifrovaně do místního vyhledávacího indexu. Agenti AI v tomto obsahu hledat nemohou. Vypnutím této volby se dešifrovaný obsah z indexu odstraní.
ui-pgp-keyserver = &Hledat klíče na keys.openpgp.org
ui-pgp-keyserver-note = Při hledání klíče podle e-mailové adresy se nejprve prohledá doména této adresy. V případě potřeby se adresa odešle na keys.openpgp.org. Pokud hledáte podle otisku nebo ID klíče, odešle se tento identifikátor místo adresy.
ui-eml-default = Otevírat &soubory .eml v aplikaci Inbox Classic
ui-eml-default-done = Inbox Classic teď otevírá soubory .eml.
ui-eml-default-failed = Inbox Classic nelze nastavit jako výchozí aplikaci pro soubory .eml: { $reason }
ui-folders = Složky
ui-sorted-by = Seřazeno podle: { $field }
ui-layout-label = &Rozložení:
ui-columns-note = Okno je dost široké pro rozložení do sloupců. Rozložení můžete změnit v nabídce Zobrazit > Rozložení.
ui-row-unread = Nepřečtená
ui-row-flagged = S příznakem
ui-row-attachments = Obsahuje přílohy
ui-row-encrypted = Šifrovaná
ui-row-signed = Podepsaná
ui-row-messages = { $count ->
    [one] { $count } zpráva
    [few] { $count } zprávy
   *[other] { $count } zpráv
}
ui-list-pictures = &Zobrazovat obrázky odesílatelů v seznamu zpráv
ui-list-pictures-note = V rozložení do sloupců zobrazuje loga značek nebo obrázky z Adresáře, pokud je doména odesílatele ověřená. Není-li obrázek dostupný, zobrazí iniciály. Stažená loga se ukládají a používají znovu pro více zpráv.
ui-card-picture = Obrázek:
ui-card-picture-choose = Vyb&rat...
ui-picture-not-picture = Soubor nelze přečíst jako obrázek PNG nebo JPEG.
ui-picture-too-large = Tento obrázek je příliš velký. Vyberte obrázek o velikosti nejvýše 10 MB a šířce i výšce nejvýše 8000 pixelů.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
ui-keys-title = Šifrovací klíče
ui-keys-intro = Vlastní klíče slouží k digitálnímu podepisování vašich zpráv a čtení pošty šifrované pro vás. Klíče kontaktů slouží k ověřování jejich digitálních podpisů a šifrování zpráv, které jim posíláte.
ui-keys-empty = Zatím žádné klíče. Klikněte na Nový klíč a vytvořte si vlastní, nebo na Importovat a přidejte klíč, který už máte.
ui-keys-col-name = Jméno
ui-keys-col-address = Adresa
ui-keys-col-kind = Druh
ui-keys-col-status = Stav
ui-keys-kind-own = Váš klíč
ui-keys-kind-contact = Kontakt
ui-keys-status-verified = { $status }, vlastnictví ověřeno
ui-keys-new = &Nový klíč...
ui-keys-import = &Importovat...
ui-keys-export = &Exportovat...
ui-keys-backup = &Zálohovat...
ui-keys-verify = &Ověřit...
ui-keys-new-title = Nový klíč
ui-keys-new-for = Vytvořit klíč pro:
ui-keys-new-make = &Vytvořit klíč
ui-keys-no-account = Nejdřív přidejte poštovní účet: klíč se vytváří pro adresy účtu.
ui-keys-memory-only = Přihlašovací údaje a ochranný klíč se uchovávají jen v paměti. Soukromý klíč vytvořený nebo importovaný nyní proto po zavření Inbox Classic nepůjde použít.
ui-keys-backup-offer = Váš nový klíč je připravený. Uložit teď jeho zálohu? Při ztrátě počítače nebo obnovení jeho výchozího stavu lze klíč obnovit jen ze zálohy.
ui-keys-backup-now = &Uložit zálohu...
ui-keys-later = &Později
ui-keys-backup-title = Zálohovat klíč
ui-keys-backup-intro = Záloha je chráněna heslovou frází. Soubor a heslovou frázi uchovávejte na různých bezpečných místech: k obnovení klíče potřebujete obojí.
ui-keys-passphrase = &Heslová fráze:
ui-keys-passphrase-again = &Zadejte ji znovu:
ui-keys-passphrase-differ = Heslové fráze se neshodují.
ui-keys-passphrase-short = Použijte heslovou frázi s alespoň 8 znaky.
ui-keys-backup-saved = Záloha byla uložena.
ui-keys-import-title = Importovat klíč
ui-keys-import-passphrase = Tento soukromý klíč je chráněn heslovou frází. Zadejte ji, abyste klíč mohli importovat:
ui-keys-file-filter = Klíče OpenPGP
ui-keys-use-for = Používat tento klíč pro adresy { $addresses }? Budete jím moci digitálně podepisovat zprávy z těchto adres a číst zde poštu šifrovanou pro tento klíč.
ui-keys-use = &Použít
ui-keys-not-now = &Teď ne
ui-keys-remove-own = Odebrat váš klíč { $fingerprint }? Dokud neimportujete jeho zálohu, nepůjde jím dešifrovat další poštu. Již dešifrovaný obsah se tím neodstraní.
ui-keys-remove-contact = Odebrat tento klíč ({ $name })? Dokud jej znovu nepřidáte, nepůjde jím ověřovat digitální podpisy ani šifrovat zprávy.
ui-key-properties-title = Vlastnosti klíče
ui-key-names = Jména:
ui-key-fingerprint = Otisk:
ui-key-status = Stav:
ui-key-created = Vytvořen:
ui-key-expires = Platnost do:
ui-key-never = Nikdy
ui-key-algorithm = Algoritmus:
ui-key-source = Zdroj:
ui-key-addresses = Adresy:
ui-key-address-verified = { $address } (ověřeno)
ui-key-address-not-verified = { $address } (neověřeno)
ui-verify-title = Ověřit klíč
ui-verify-intro = Ověřujete klíč: { $name }. Požádejte jeho vlastníka, aby vám osobně nebo po telefonu přečetl otisk ze své aplikace. Neporovnávejte jej s otiskem poslaným e-mailem: kdo by mohl pozměnit klíč, mohl by pozměnit i tento otisk.
ui-verify-fingerprint = Otisk klíče, který máte:
ui-verify-marks = { $count ->
    [0] Tento klíč neobsahuje žádné e-mailové adresy. Otisk můžete porovnat, ale ověření vlastnictví nelze uložit.
    [one] Než kliknete na Shodují se, ověřte také, že dotyčné osobě patří adresa { $addresses }. Poté bude klíč pro tuto adresu označen jako ověřený. Pokud adresa dané osobě nepatří, klikněte na Liší se.
   *[other] Než kliknete na Shodují se, ověřte také, že dotyčné osobě patří všechny uvedené adresy: { $addresses }. Poté bude klíč pro tyto adresy označen jako ověřený. Pokud některá adresa dané osobě nepatří, klikněte na Liší se.
}
ui-verify-match = &Shodují se
ui-verify-differ = &Liší se
ui-verify-differs = Ověření klíče se nezdařilo: { $name }. Otisky se liší. Odeberte tento klíč a požádejte dotyčnou osobu o její klíč znovu.
ui-verify-unmark = Označit jako &neověřený
ui-account-security = Zabezpečení
ui-account-security-intro = S klíčem můžete své zprávy digitálně podepisovat a ostatní vám mohou posílat šifrovanou poštu.
ui-account-key = &Klíč pro tento účet:
ui-account-key-none = Žádný
ui-account-key-new = &Nový klíč...
ui-account-autocrypt = &Posílat můj veřejný klíč se zprávami (Autocrypt)
ui-contact-key = Šifrovací klíč:
ui-contact-key-none = Žádný klíč
ui-contact-key-use-new = Použít &nový klíč
ui-contact-key-keep = Ponechat &současný
ui-recipient-keys-title = Klíče příjemců
ui-recipient-col-recipient = Příjemce
ui-recipient-col-key = Klíč
ui-recipient-find-key = Najít &klíč
ui-recipient-remove = &Odebrat ze zprávy
ui-send-unencrypted = Odeslat &bez šifrování
ui-compose-make-key = &Vytvořit klíč...
ui-compose-show-keys = Šif&rovací klíče...
ui-compose-encrypt-off = &Vypnout šifrování
ui-compose-keep-encrypted = &Ponechat šifrování
ui-setup-export-title = Exportovat nastavení a účty
ui-setup-import-title = Importovat nastavení a účty
ui-setup-export-intro = Zvolte, co chcete přenést do jiného počítače. Soubor neobsahuje zprávy. Na druhém počítači lze znovu stáhnout jen poštu, která zůstala na serveru.
ui-setup-use-passphrase = &Chránit soubor heslovou frází
ui-setup-passphrase-note = S heslovou frází je soubor šifrovaný a může obsahovat uložené přihlašovací údaje a dostupné soukromé klíče z vybraných částí. Bez ní se na druhém počítači budete muset k účtům znovu přihlásit heslem nebo přes prohlížeč.
ui-setup-export-button = &Exportovat...
ui-setup-file-filter = Nastavení a účty Inbox Classic
ui-setup-ask-passphrase = Tento soubor je chráněn heslovou frází. Zadejte ji, abyste viděli, co soubor obsahuje:
ui-setup-import-intro = Zvolte, co importovat. Účty, které už v tomto počítači jsou, zůstanou beze změny.
ui-setup-from = Uloženo aplikací Inbox Classic { $version } dne { $date }.
ui-setup-import-button = &Importovat
ui-setup-done = Hotovo
ui-setup-first-run = Importovat nastavení a účty z jiného počítače...
# review: new
ui-first-run-other = Už používáte Inbox Classic na jiném počítači? Přeneste sem jeho účty a nastavení.
# review: new
ui-first-run-sync = Připojit se k jeho synchronizaci…
# review: new
ui-first-run-import = Importovat ze souboru…

ui-field-verifiers = Důvěryhodné zdroje ověření odesílatele:
ui-attachment-import-key = Importovat klíč...
ui-book-key-known = Má šifrovací klíč
ui-book-key-verified = Má šifrovací klíč s ověřeným vlastníkem
ui-keys-publish = Zveře&jnit...
ui-keys-publish-ask = Zveřejnit váš veřejný klíč na keys.openpgp.org, aby ho ostatní mohli najít? Adresy v klíči: { $addresses }. Každou adresu je před zveřejněním nutné potvrdit pomocí odkazu zaslaného na tuto adresu.
ui-keys-publish-now = Zveřejnit
ui-keys-paste = Importovat ze &schránky
ui-keys-paste-none = Schránka neobsahuje žádný klíč OpenPGP.
ui-contact-find-key = Najít &klíč
# review: new
ui-reactions-label = Reakce:
# review: new
ui-reaction-open-email = Otevřít e-mail s reakcí
# review: new
ui-reaction-show-as-email = Zobrazit jako e-mail
# review: new
ui-reaction-when = Reakce: { $when }
