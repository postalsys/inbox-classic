# Slovenčina. Návrh, čaká na kontrolu rodeným hovoriacim (pozri core/locales/GLOSSARY.md).

## The menus

menu-file = &Súbor
menu-edit = Úp&ravy
menu-view = &Zobraziť
menu-tools = &Nástroje
menu-message = Sprá&va
menu-help = &Pomocník
menu-layout = &Rozloženie
menu-sort-by = Zorad&iť podľa
menu-text-size = &Veľkosť textu
menu-folder = P&riečinok
menu-insert = Vl&ožiť

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = Nové &konto...
cmd-exit = &Ukončiť
cmd-sync = Odoslať a &prijať všetko
cmd-mark-read = Oz&načiť ako prečítané
cmd-mark-unread = O&značiť ako neprečítané
cmd-pictures = S&tiahnuť obrázky
cmd-about = O &programe Inbox Classic
cmd-new-mail = &Nová správa
cmd-reply = &Odpovedať
cmd-reply-all = Odpovedať všetký&m
cmd-forward = &Preposlať
cmd-help = &Obsah
cmd-delete = &Odstrániť správu
cmd-move = P&resunúť do priečinka...
cmd-flag = Označiť prízna&kom
cmd-new-folder = &Nový priečinok...
cmd-rename-folder = Pr&emenovať priečinok...
cmd-delete-folder = O&dstrániť priečinok
cmd-empty-folder = &Vyprázdniť priečinok
ui-empty-button = Vyprázdniť
cmd-accounts = K&ontá...
cmd-find = Ná&jsť správu
cmd-save-as = Uložiť &ako...
cmd-print = &Tlačiť...
cmd-print-conversation = Tlačiť konver&záciu...
cmd-import = &Importovať správy...
cmd-outbox = Pošta na &odoslanie...
cmd-properties = V&lastnosti
cmd-mark-all-read = Označiť všetko &ako prečítané
cmd-junk = Ozn&ačiť ako nevyžiadanú
cmd-not-junk = Označ&iť ako vyžiadanú
cmd-archive = Arc&hivovať
cmd-watch-conversation = Sledovať konverzá&ciu
cmd-ignore-conversation = I&gnorovať konverzáciu
cmd-next-message = Ď&alšia správa
cmd-previous-message = &Predchádzajúca správa
cmd-next-unread = Ďalšia &neprečítaná správa
cmd-go-to-folder = Prejsť &do priečinka...
cmd-find-in-message = Nájsť v &tejto správe...
ui-go-to-prompt = Prejsť do priečinka:
ui-find-in-message-hint = Nájsť v tejto správe
ui-find-not-found = „{ $words }“ sa v tejto správe nenachádza
cmd-expand-all-threads = R&ozbaliť všetky konverzácie
cmd-collapse-all-threads = Z&baliť všetky konverzácie
# review: new
cmd-next-in-conversation = Ďa&lšia správa v konverzácii
# review: new
cmd-previous-in-conversation = Predc&hádzajúca správa v konverzácii
# review: new
cmd-open-all-messages = Otvoriť vš&etky správy
# review: new
cmd-fold-all-messages = Zbaliť všet&ky správy
ui-group-by-conversation = Zoskupovať správy podľa &konverzácií
ui-show-whole-conversation = Zobraziť &celú konverzáciu na table na čítanie
ui-show-whole-conversation-note = Otvorte správy konverzácie spoločne vrátane svojich odpovedí, konceptov a správ v iných priečinkoch. Prečítané správy sú zvyčajne zbalené do riadka; kliknutím na riadok správu otvoríte alebo zbalíte.
ui-conversation-order = P&oradie správ v konverzácii:
ui-conversation-oldest-first = Najstaršie prvé
ui-conversation-newest-first = Najnovšie prvé
ui-thread-count = { $new ->
    [0] ({ $count })
    [one] ({ $count }, { $new } nová)
    [few] ({ $count }, { $new } nové)
   *[other] ({ $count }, { $new } nových)
}
ui-conversation-to = komu: { $people }
ui-conversation-draft = Koncept
ui-conversation-downloading = Sťahovanie…
# review: new
ui-conversation-you = Ja
# review: new
ui-conversation-messages = { $count ->
    [one] { $count } správa
    [few] { $count } správy
   *[other] { $count } správ
}
# review: new
ui-conversation-unread = { $count ->
    [one] { $count } neprečítaná
    [few] { $count } neprečítané
   *[other] { $count } neprečítaných
}
# review: new
ui-conversation-found-in = Nájdené v priečinku { $folder }
# review: new
ui-conversation-hidden = { $count ->
    [one] Ešte { $count } správa
    [few] Ešte { $count } správy
   *[other] Ešte { $count } správ
}
# review: new
ui-conversation-open-message = Otvoriť správu
# review: new
ui-conversation-fold-message = Zbaliť správu
# review: new
ui-conversation-more = Viac
# review: new
ui-conversation-edit = Upraviť
ui-conversation-elsewhere = { $count ->
    [one] Táto konverzácia má aj { $count } správu v inom priečinku.
    [few] Táto konverzácia má aj { $count } správy v iných priečinkoch.
   *[other] Táto konverzácia má aj { $count } správ v iných priečinkoch.
}
ui-conversation-this-folder = &Len tento priečinok
ui-conversation-whole = &Celá konverzácia
cmd-folder-list = &Zoznam priečinkov
cmd-layout-automatic = &Automatické
cmd-layout-classic = &Klasické
cmd-layout-columns = &Stĺpce
cmd-sort-date = &Dátum
cmd-sort-from = &Od
cmd-sort-subject = &Predmet
cmd-sort-size = Veľ&kosť
cmd-sort-ascending = Zoradiť v&zostupne
cmd-sort-descending = Zoradiť zo&stupne
cmd-text-size-largest = &Najväčšia
cmd-text-size-larger = &Väčšia
cmd-text-size-medium = &Stredná
cmd-text-size-smaller = &Menšia
cmd-text-size-smallest = Na&jmenšia
cmd-hide-ignored = Skryť i&gnorované konverzácie
cmd-hide-read = &Skryť prečítané správy
cmd-notify = Upozorňovať na &novú poštu
cmd-open = &Otvoriť Inbox Classic
cmd-default-app = Nastaviť ako pre&dvolenú poštovú aplikáciu...
cmd-view-source = Zdro&j správy
cmd-ai-agents = &AI agenti...
cmd-options = &Možnosti...
cmd-message-rules = P&ravidlá správ...
cmd-encryption-keys = Šifrovacie &kľúče...
cmd-create-rule-from-message = V&ytvoriť pravidlo zo správy...
cmd-unsubscribe = Odhlásiť odber &zoznamu...
cmd-select-all = &Vybrať všetko
cmd-undo = &Späť
cmd-copy = &Kopírovať do priečinka...
cmd-address-book = Adre&sár...
cmd-add-sender-to-book = Pridať odosi&elateľa do adresára
cmd-import-address-book = Importovať a&dresár...
cmd-export-address-book = E&xportovať adresár...
cmd-export-setup = Exportovať na&stavenia a kontá...
cmd-import-setup = Im&portovať nastavenia a kontá...
cmd-compose-sign = &Digitálne podpísať
cmd-compose-encrypt = Ši&frovať
cmd-attach-my-key = Priložiť svoj &verejný kľúč

## The tray icon's menu

tray-check = &Skontrolovať novú poštu
tray-no-accounts = Zatiaľ žiadne kontá

## Words the windows of more than one platform share

ui-tb-create-mail = Vytvoriť správu
ui-tb-reply = Odpovedať
ui-tb-reply-all = Odpovedať všetkým
ui-tb-forward = Preposlať
ui-tb-print = Tlačiť
ui-tb-delete = Odstrániť
ui-tb-junk = Nevyžiadaná
ui-tb-not-junk = Vyžiadaná
ui-tb-archive = Archivovať
ui-tb-previous = Predchádzajúca
ui-tb-next = Ďalšia
ui-previous-tip = Predchádzajúca správa
ui-next-tip = Ďalšia správa
ui-tb-sync = Odoslať/prijať
ui-tb-mark-read = Prečítané
ui-tb-mark-unread = Neprečítané
ui-still-running = Inbox Classic stále beží
ui-no-subject = (bez predmetu)
ui-quoted = „{ $subject }“
ui-newest-from = Najnovšia správa (odosielateľ: { $sender }): { $subject }
ui-new-messages = { $count ->
    [one] { $count } nová správa
    [few] { $count } nové správy
   *[other] { $count } nových správ
}
ui-outbox-waiting = { $count ->
    [one] 1 správa v priečinku Pošta na odoslanie
    [few] { $count } správy v priečinku Pošta na odoslanie
   *[other] { $count } správ v priečinku Pošta na odoslanie
}
ui-outbox-waits = Správa { $subject } čaká v priečinku Pošta na odoslanie
ui-outbox-sending = Odosiela sa správa { $subject }...
ui-from-account = Z konta { $account }
ui-sign-in-refused = Prihlásenie do konta { $account } bolo odmietnuté alebo relácia vypršala.
ui-sign-in-again-ask = Prihlásiť sa znova v prehliadači?
ui-sign-in-again-failed = Opätovné prihlásenie zlyhalo: { $reason }
ui-unknown-reason = neznámy dôvod
ui-checking = Kontrolujú sa nové správy v konte { $account }...
ui-done = Hotovo
ui-sent-at = Správa { $subject } bola odoslaná o { $time }
ui-draft-saved = Správa bola uložená do priečinka Koncepty
ui-draft-not-saved = Správa sa neuložila do priečinka Koncepty: { $reason }
ui-about-core = Jadro { $version }
ui-add-account-first = Najprv pridajte poštové konto.
ui-add-account-first-link = Najprv pridajte poštové konto a potom znova kliknite na e-mailový odkaz.
ui-default-app-is = Inbox Classic je vaša predvolená poštová aplikácia: e-mailové odkazy tu otvoria novú správu.
ui-select-message-first = Najprv vyberte správu.
ui-store-not-opened = Úložisko pošty sa nepodarilo otvoriť.
ui-store-or-cert-not-opened = Úložisko pošty alebo súbor certifikátu sa nepodarilo otvoriť.
ui-help-title = Pomocník Inbox Classic
ui-help-missing = V tejto kópii Inbox Classic chýba pomocník.
ui-ok = OK
ui-cancel = Zrušiť
ui-close = Zavrieť
ui-col-subject = Predmet
ui-col-from = Od
ui-col-to = Komu
ui-col-received = Prijaté
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Sledovaná konverzácia
ui-col-sent = Odoslané
ui-col-size = Veľkosť
ui-col-folder = Priečinok
ui-col-account = Konto
ui-col-queued = Zaradené
ui-col-status = Stav
ui-outbox-title = Pošta na odoslanie
ui-outbox-status-waiting = Čaká
ui-outbox-status-not-sent = Neodoslané: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = Zaradil AI agent; odoslanie najskôr o { $time }
ui-outbox-delete-ask = Odstrániť túto správu bez odoslania?
ui-open-link = Otvoriť odkaz
ui-edit-link = Upraviť odkaz...
ui-remove-link = Odstrániť odkaz
ui-insert-attachment = Vložiť prílohu
ui-insert-picture = Vložiť obrázok
ui-filter-all = Všetky súbory
ui-filter-pictures = Obrázky
ui-filter-messages = E-mailové správy
ui-save-attachment-as = Uložiť prílohu ako
ui-not-sent = Správu sa nepodarilo odoslať.
ui-attachment-forgotten = Napísali ste „{ $word }“, ale nie je priložený žiadny súbor. Odoslať správu aj tak?
ui-send-anyway = Odoslať aj tak
ui-go-back = Späť
ui-not-saved = Správu sa nepodarilo uložiť.
ui-saving-draft = Ukladá sa do priečinka Koncepty...
ui-compose-saved-at = Uložené do priečinka Koncepty o { $time }
ui-compose-restored = Správa bola obnovená po neočakávanom ukončení Inbox Classic
ui-compose-not-saved = Správu sa nepodarilo uložiť do priečinka Koncepty: { $reason }
ui-save-changes-ask = Chcete uložiť zmeny tejto správy do priečinka Koncepty?
ui-new-message-title = Nová správa
ui-link-invalid = Zadajte webovú adresu (https://...) alebo e-mailový odkaz (mailto:...).
ui-link-address = Adresa:
ui-hyperlink = Hypertextový odkaz
ui-hyperlink-intro = Adresa, na ktorú odkazuje vybratý text.
ui-edit-hyperlink = Upraviť hypertextový odkaz
ui-edit-hyperlink-intro = Cieľová adresa odkazu. Vymažte adresu, ak chcete odkaz odstrániť a text ponechať.
ui-not-a-picture = Obrázok sa nepodarilo vložiť. Vyberte čitateľný súbor PNG, JPEG, GIF alebo WebP s veľkosťou najviac 10 MB.
ui-format-color = Farba písma
ui-format-numbers = Číslovaný zoznam
ui-format-bullets = Zoznam s odrážkami
ui-format-outdent = Zmenšiť odsadenie
ui-format-indent = Zväčšiť odsadenie
ui-format-left = Zarovnať doľava
ui-format-center = Centrovať
ui-format-right = Zarovnať doprava
ui-format-line = Vložiť vodorovnú čiaru
ui-tb-send = Odoslať
ui-tb-save = Uložiť
ui-tb-attach = Priložiť
ui-tb-sign = Podpísať
ui-tb-encrypt = Šifrovať
ui-field-keys = Kľúče:
ui-field-from = Od:
ui-field-to = Komu:
ui-field-cc = Kópia:
ui-field-bcc = Skrytá kópia:
ui-field-subject = Predmet:
ui-field-attach = Prílohy:
ui-signature = Textový podpis
ui-signature-hint = Pridáva sa k novým správam, odpovediam a preposlaným správam z tohto konta.
ui-signature-not-saved = Textový podpis sa nepodarilo uložiť.
ui-all-inboxes = Všetka doručená pošta
ui-all-sent = Všetka odoslaná pošta
ui-all-drafts = Všetky koncepty
ui-flagged-folder = S príznakom
ui-all-folders = Všetky priečinky
ui-the-account = konto
ui-folder-name = Názov priečinka:
ui-find-hint = Hľadať v pošte
ui-find-tip = Prehľadáva predmety, odosielateľov, príjemcov, názvy príloh a text správ.
ui-clear-search = Vymazať vyhľadávanie
ui-no-match = Výrazu „{ $words }“ nezodpovedajú žiadne správy.
ui-no-match-all = Vyhľadávanie zahŕňa predmety, mená a adresy odosielateľov a príjemcov, názvy príloh a text správ vo všetkých priečinkoch. Skontrolujte pravopis alebo skúste zadať menej slov.
ui-no-match-in = Rozsah vyhľadávania: „{ $folder }“. Vyhľadávanie zahŕňa predmety, mená a adresy odosielateľov a príjemcov, názvy príloh a text správ. Skontrolujte pravopis alebo skúste zadať menej slov.
ui-no-items = V tomto zobrazení nie sú žiadne položky.
ui-choose-folder = Vyberte priečinok, ak chcete vidieť jeho správy.
ui-unsubscribe = Odhlásiť odber
ui-open-in-calendar = Otvoriť v kalendári
ui-pictures-blocked = Niektoré obrázky boli zablokované, aby sa obmedzila možnosť sledovania odosielateľom.
ui-not-shown = Správu sa nepodarilo zobraziť.
ui-attachment-not-read = Prílohu sa nepodarilo prečítať.
ui-attachment-not-saved = Prílohu sa nepodarilo uložiť.
ui-not-downloaded = Správa ešte nie je stiahnutá.
ui-leave-list = Odhlásiť odber týchto správ?
ui-leave-one-click = Inbox Classic pošle žiadosť o odhlásenie odberu na server { $target }. Neotvorí sa žiadna webová stránka a neodošle sa žiadny e-mail.
ui-leave-mail = Ak chcete odhlásiť odber, pošlite e-mail na adresu { $target }. Inbox Classic ho pre vás pripraví. Žiadosť potom odošlite.
ui-leave-web = V prehliadači sa otvorí stránka na odhlásenie odberu ({ $target }).
ui-unsubscribing = Odosiela sa žiadosť o odhlásenie odberu: { $target }...
ui-cannot-unsubscribe = Táto správa neponúka možnosť odhlásiť odber.
ui-unsubscribed = Žiadosť o odhlásenie odberu bola prijatá.
ui-not-unsubscribed = Odber sa nepodarilo odhlásiť: { $reason }
ui-list-bar = Táto správa je zo zoznamu adresátov ({ $domain }).
ui-list-bar-plain = Táto správa je zo zoznamu adresátov.
ui-list-bar-asked = O odhlásenie odberu z tohto zoznamu ste požiadali { $date }.
ui-list-bar-came-after = O odhlásenie odberu ste požiadali { $date }, ale táto správa prišla o viac ako dva dni neskôr.
ui-list-bar-opened = Stránku na odhlásenie odberu z tohto zoznamu ste otvorili { $date }.
ui-list-bar-failed = Žiadosť o odhlásenie odberu zlyhala: { $reason }
ui-unsubscribe-ask = Odhlásiť odber…
ui-unsubscribe-again = Znova odhlásiť odber…
ui-event-span = { $start } až { $end }
ui-event-floating = { $when } (bez prepočtu časového pásma)
ui-invitation = Pozvánka: { $title }
ui-invitation-updated = Aktualizovaná pozvánka: { $title }
ui-invitation-canceled = Zrušené: { $title }
ui-invitation-answer = Odpoveď na pozvánku: { $title }
ui-no-title = (bez názvu)
ui-organizer = Organizátor: { $name }
ui-invitation-not-read = Pozvánku sa nepodarilo prečítať.
ui-no-calendar = Pozvánku sa nepodarilo otvoriť. Skontrolujte, či aplikácia kalendára v tomto počítači podporuje súbory .ics.
ui-messages-not-changed = Správy sa nepodarilo zmeniť.
ui-new-folder-in-selected = Nový priečinok sa vytvorí vo vybratom priečinku.
ui-new-folder-at-top = Nový priečinok sa vytvorí na najvyššej úrovni konta.
ui-folder-not-created = Priečinok sa nepodarilo vytvoriť.
ui-folder-not-renamed = Priečinok sa nepodarilo premenovať.
ui-folder-not-deleted = Priečinok sa nepodarilo odstrániť.
ui-rename-folder-intro = Zadajte nový názov priečinka „{ $folder }“.
ui-properties-of = Vlastnosti: { $subject }
ui-internet-headers = Internetové hlavičky tejto správy:
ui-save-messages-in = Vyberte priečinok na uloženie správ
ui-save-message-as = Uložiť správu ako
ui-import-choose-folder = Najprv vyberte priečinok, do ktorého sa majú správy importovať.
ui-add-account-title = Pridať poštové konto
ui-accounts-title = Kontá
ui-security-none = Žiadne (nešifrované)
ui-field-required = Pole { $field } je povinné.
ui-email-invalid = E-mailová adresa nie je platná.
ui-ports-invalid = Porty sú čísla od 1 do 65535.
ui-looking-up = Hľadajú sa nastavenia domény { $domain }...
ui-found-none = Zadajte údaje konta od svojho poskytovateľa e-mailu.
ui-found-change = Ak vám poskytovateľ uviedol iné nastavenia, upravte ich podľa jeho pokynov.
ui-found-guess = Pre túto adresu sa nenašli žiadne nastavenia. Navrhnuté názvy serverov sú odhady. Overte ich u svojho poskytovateľa.
ui-found-mx = Inbox Classic rozpoznal vášho poskytovateľa e-mailu a vyplnil nastavenia jeho serverov.
ui-found-srv = Tieto nastavenia sa našli v záznamoch DNS vašej domény.
ui-found-autodiscover = Tieto nastavenia sa našli cez Microsoft Autodiscover (Exchange).
ui-found-other = Tieto nastavenia sa našli pre túto adresu.
ui-app-password-needed = Poskytovateľ: { $provider }. Ak vaše konto podporuje heslá aplikácií, vytvorte si takéto heslo v nastaveniach zabezpečenia konta a zadajte ho do poľa Heslo v ďalšom formulári. Outlook.com a Microsoft 365 vyžadujú prihlásenie cez prehliadač.
ui-app-password-open = Otvoriť pokyny služby { $provider } v prehliadači?
ui-plain-warning = Bez šifrovania môže ktokoľvek, kto zachytí vašu sieťovú komunikáciu, prečítať vaše heslo a správy. Samotná lokálna sieť neposkytuje šifrovanie. Pokračujte len vtedy, ak je pripojenie chránené iným spôsobom.
ui-continue-ask = Pokračovať?
ui-add-sign-in-app = Pridať prihlasovaciu aplikáciu...
ui-turned-off = Možnosť „{ $name }“ je v tomto počítači vypnutá.
ui-off-here = V tomto počítači je táto možnosť vypnutá.
ui-why = Prečo?
ui-more-sign-in = Ďalšie možnosti prihlásenia...
ui-other-account = Ak chcete pridať iné e-mailové konto, zadajte svoju e-mailovú adresu a meno, ktoré majú vidieť príjemcovia. Nastavenia serverov sa vyhľadajú potom.
ui-field-account-name = Názov konta:
ui-field-name = Zobrazované meno:
ui-field-email = E-mailová adresa:
ui-field-user = Meno používateľa:
ui-field-password = Heslo:
ui-field-imap-host = Server prichádzajúcej pošty (IMAP):
ui-field-imap-port = Port IMAP:
ui-field-imap-security = Zabezpečenie IMAP:
ui-field-smtp-host = Server odchádzajúcej pošty (SMTP):
ui-field-smtp-port = Port SMTP:
ui-field-smtp-security = Zabezpečenie SMTP:
ui-field-other-addresses = Ďalšie adresy, z ktorých posielate:
ui-sign-in-not-started = Prihlásenie cez prehliadač sa nepodarilo spustiť.
ui-sign-in-in-browser = Prihláste sa do konta { $account } v okne prehliadača, ktoré sa otvorilo, a potom sa vráťte sem.
ui-sign-in-failed = Prihlásenie zlyhalo: { $reason }
ui-account-not-saved = Konto sa nepodarilo uložiť.
ui-start-intro = Gmail, Google Workspace, Outlook.com a Microsoft 365: prihláste sa na stránke Googlu alebo Microsoftu. Heslo zadávate tam, nikdy nie do Inbox Classic.
ui-start-intro-apps = Prihláste sa cez prehliadač pomocou jednej zo svojich prihlasovacích aplikácií (Ďalšie možnosti prihlásenia) alebo nižšie zadajte meno a adresu a pridajte iné e-mailové konto.
ui-use-app-password = Použiť heslo aplikácie
ui-the-provider = poskytovateľa
ui-provider-intro = Prihláste sa ku kontu { $email } cez { $provider } na jeho webovej stránke. Inbox Classic nedostane vaše heslo. Ak konto podporuje heslá aplikácií pre poštové programy, môžete použiť aj takéto heslo vytvorené v nastaveniach zabezpečenia konta. Outlook.com a Microsoft 365 podporujú iba prihlásenie cez prehliadač.
ui-provider-intro-apps = Prihláste sa ku kontu { $email } cez { $provider } na jeho webovej stránke pomocou jednej zo svojich prihlasovacích aplikácií (Ďalšie možnosti prihlásenia). Ak konto podporuje heslá aplikácií pre poštové programy, môžete použiť aj takéto heslo vytvorené v nastaveniach zabezpečenia konta. Outlook.com a Microsoft 365 podporujú iba prihlásenie cez prehliadač.
ui-finish = Dokončiť
ui-logon = Prihlásenie
ui-enter-password = Zadajte heslo konta { $account }.
ui-signs-in-with = Prihlasovacia aplikácia: { $app }. Prihlásenie prebieha v prehliadači a konto používa servery tejto aplikácie.
ui-keep-password = Ak chcete ponechať súčasné heslo, nechajte pole hesla prázdne.
ui-remove-account = Odstrániť konto
ui-remove-account-ask = Odstrániť toto konto z Inbox Classic? Odstránia sa jeho miestne údaje vrátane správ čakajúcich na odoslanie a uložených prihlasovacích údajov. Pošta uložená na serveri tam zostane. Správy dostupné iba v tomto počítači sa stratia.
ui-col-email = E-mailová adresa
ui-col-incoming = Server prichádzajúcej pošty
ui-type-email = Zadajte svoju e-mailovú adresu, meno@example.com.
ui-ai-agent = AI agent
ui-ai-agent-access = Prístup AI agenta
ui-ai-agents = AI agenti
ui-program-path = Program: { $path }
ui-it-may = Povolené akcie:
ui-accounts-it-may-use = Povolené kontá:
ui-send-message-ask = Odoslať správu?
ui-col-name = Názov
ui-never = Nikdy
ui-connect-agent = Pripojiť AI agenta
ui-connect-agent-intro = Pridajte túto konfiguráciu medzi servery MCP svojho agenta (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Program
ui-col-may = Oprávnenia
ui-col-last-used = Naposledy použité
ui-col-when = Kedy
ui-col-what = Akcia
ui-sign-in-app = Prihlasovacia aplikácia
ui-sign-in-apps = Prihlasovacie aplikácie
ui-add-sign-in-app-title = Pridať prihlasovaciu aplikáciu
ui-preset-app-name = Prihlasovacia aplikácia { $provider }
ui-issuer-not-checked = vydavateľa nemožno overiť
ui-checking-issuer = Overuje sa konfigurácia vydavateľa: { $issuer }...
ui-issuer-unusable = Vydavateľa nemožno použiť: { $reason }
ui-issuer-usable = Vydavateľa možno použiť.
ui-sign-in-app-not-saved = Prihlasovaciu aplikáciu sa nepodarilo uložiť: { $reason }
ui-check = &Overiť
ui-fill-in-for = Použiť nastavenia pre:
ui-app-name = Názov:
ui-issuer = Vydavateľ:
ui-client-id = ID klienta:
ui-client-secret = Tajný kód klienta:
ui-scopes = Rozsahy oprávnení:
ui-imap-server = Server IMAP:
ui-smtp-server = Server SMTP:
ui-redirect-uri = URI presmerovania:
ui-sign-in-app-intro = Prihlasovacia aplikácia je klient OAuth, ktorého zaregistrujete u svojho poskytovateľa, aby ste sa mohli prihlasovať cez prehliadač. Vyberte poskytovateľa, aby sa vyplnili jeho nastavenia, a potom pridajte ID klienta a tajný kód klienta, ak vám ho poskytovateľ dal.
ui-remove-secret = Tajný kód klienta je uložený. Zadajte nový, ktorý ho nahradí, alebo uložený tajný kód odstráňte
ui-register-it = Zaregistrujte aplikáciu u svojho poskytovateľa
ui-built-in-note = Aplikácia „{ $name }“ je vstavaná. Môžete len zmeniť, či sa má ponúkať pri pridávaní kont.
ui-client-with-secret = ID klienta: { $client }. Tajný kód klienta je uložený.
ui-client-public = ID klienta: { $client }. Verejný klient bez tajného kódu.
ui-no-accounts = Žiadne kontá
ui-remove-sign-in-app = Odstrániť prihlasovaciu aplikáciu
ui-remove-sign-in-app-ask = Odstrániť prihlasovaciu aplikáciu { $name } aj s jej uloženým tajným kódom klienta?
ui-sign-in-app-not-removed = Prihlasovacia aplikácia nebola odstránená. { $reason }
ui-sign-in-apps-intro = Prihlasovacie aplikácie umožňujú kontám prihlasovať sa cez prehliadač. Aplikácia, ktorá nie je začiarknutá, sa pre nové kontá neponúka; kontá, ktoré ju už používajú, fungujú ďalej.
ui-col-issuer = Vydavateľ
ui-col-used-by = Používa
ui-options-system-default = Podľa systému ({ $language })
ui-settings-general = Všeobecné
ui-settings-reading = Čítanie
ui-settings-new-mail = Nová pošta
ui-settings-sending = Odosielanie
ui-settings-default-apps = Predvolené aplikácie
ui-settings-message-list = Zoznam správ
ui-settings-messages = Správy
ui-settings-encryption = Šifrovanie
ui-settings-language = Jazyk
ui-settings-label = { $label }:
ui-apply = &Použiť
ui-settings-sync = Synchronizácia
ui-sync-note = Majte svoje kontá, kľúče, adresár, pravidlá a nastavenia rovnaké na každom počítači, a to cez priečinok alebo úložisko, ktoré vlastníte. Všetko sa zašifruje vašou prístupovou frázou synchronizácie skôr, než opustí tento počítač.
ui-sync-place = Synchronizované cez:
ui-sync-status = Stav:
ui-sync-set-up = &Nastaviť synchronizáciu…
ui-sync-now = S&ynchronizovať teraz
ui-sync-computers = P&očítače…
ui-sync-history = &História…
ui-sync-turn-off = &Vypnúť synchronizáciu…
ui-sync-what = Čo synchronizovať
ui-sync-what-note = Heslá, prihlásenia a súkromné kľúče sa prenášajú iba zašifrované. Vynechajte, čo má zostať len v tomto počítači.
ui-sync-accounts = Kon&tá
ui-sync-passwords = He&slá
ui-sync-sign-ins = Prihlásenia cez &Google, Microsoft a prihlasovacie aplikácie
ui-sync-sign-in-apps = Prihlasovacie &aplikácie
ui-sync-app-secrets = Ta&jné kódy prihlasovacích aplikácií
ui-sync-contacts = A&dresár
ui-sync-keys = &Kľúče
ui-sync-private-keys = Vaše súkro&mné kľúče
ui-sync-rules = P&ravidlá
ui-sync-trusted = Dôveryhodní odosie&latelia
ui-sync-settings = Nastav&enia
ui-sync-preferences = Rozloženie a &zobrazenie
ui-sync-everything = Všetko
ui-sync-some-left-out = Niečo je vynechané
ui-sync-where = Kam ukladať
ui-sync-folder = Priečinok
ui-sync-folder-note = Dropbox, OneDrive, iCloud Drive, Google Drive, Nextcloud alebo Syncthing ho skopíruje do vašich ďalších počítačov.
ui-sync-bucket = Úložisko kompatibilné s S3
ui-sync-bucket-note = Amazon S3, Cloudflare R2, Backblaze B2, MinIO alebo iné úložisko, ktoré funguje ako S3.
ui-sync-folder-label = &Priečinok:
ui-sync-folder-none = Zatiaľ nevybraný
ui-sync-choose-folder = &Vybrať…
ui-sync-choose-folder-title = Vyberte priečinok na synchronizáciu
ui-sync-endpoint = &Koncový bod:
ui-sync-region = &Oblasť:
ui-sync-bucket-name = &Bucket:
ui-sync-prefix = Priečinok v b&uckete:
ui-sync-access-key = &ID prístupového kľúča:
ui-sync-secret-key = &Tajný prístupový kľúč:
ui-sync-next = Ď&alej
ui-sync-join-title = Pripojiť sa k synchronizácii
ui-sync-join-note = Toto umiestnenie už obsahuje synchronizované údaje. Zadajte prístupovú frázu synchronizácie, ktorú ste zvolili na prvom počítači.
ui-sync-start-title = Spustiť synchronizáciu
ui-sync-start-note = Zvoľte prístupovú frázu synchronizácie. Zadáte ju raz na každom počítači, ktorý pridáte. Uložte si ju na bezpečné miesto: bez nej sa žiadny ďalší počítač nepripojí.
ui-sync-name = &Názov tohto počítača:
ui-sync-merge-note = Údaje tohto počítača sa zlúčia so synchronizovanými údajmi. Zhodné kontá a kontakty sa zlúčia do jedného záznamu.
ui-sync-turn-on = Zapnúť s&ynchronizáciu
ui-sync-on = Synchronizácia je zapnutá.
ui-sync-turn-off-ask = Vypnúť synchronizáciu v tomto počítači? Všetko zostane, ako je, tu aj na vašich ďalších počítačoch. Tento počítač sa len prestane synchronizovať.
ui-sync-turn-off-button = Vypnúť
ui-sync-computers-title = Počítače
ui-sync-computers-note = Tieto počítače sa synchronizujú cez rovnaké umiestnenie. Odstráňte počítač, ktorý už nepoužívate, aby sa prestal synchronizovať. Jeho synchronizované údaje zostanú zachované.
ui-sync-this-computer = Tento počítač
ui-sync-seen = Naposledy synchronizované: { $when }
ui-sync-remove-ask = Odstrániť počítač „{ $name }“ zo synchronizácie? Pri ďalšom pokuse sa prestane synchronizovať. Ak ho chcete znova synchronizovať, nastavte na ňom synchronizáciu znova.
ui-sync-loading = Načítava sa…
ui-sync-history-title = História
ui-sync-history-note = Pri konflikte zmien z rôznych počítačov synchronizácia ponechá jednu verziu. Nahradené hodnoty nájdete tu; obnovte hodnotu, ak ju chcete znova použiť. Heslá, prihlasovacie údaje a súkromné kľúče sa tu neuchovávajú.
ui-sync-history-empty = Žiadne zmeny neboli nahradené.
ui-sync-history-row = Zdroj: { $source }, { $when }
ui-sync-restore = &Obnoviť
ui-sync-restore-points = Body obnovenia
ui-sync-restore-points-note = Body obnovenia uložia vaše kontá a nastavenia predtým, ako synchronizácia odstráni položky z tohto počítača. Otvorte bod a vyberte, čo obnoviť.
ui-sync-restore-points-empty = Zatiaľ žiadne.
ui-sync-open-point = Ot&voriť…
# Set Up Sync on Windows: back from its second step to the first, as a wizard's Back button
win-sync-back = < S&päť
ui-language-label = &Jazyk:
ui-restart-note = Jazyk sa zmení po reštartovaní Inbox Classic.
ui-restart-ask = Nový jazyk po reštartovaní Inbox Classic: { $language }. Reštartovať teraz?
ui-notify-new-mail = &Upozorniť ma, keď príde nová pošta
ui-new-folder-title = Nový priečinok
ui-rename-folder-title = Premenovať priečinok
ui-delete-folder-question = Odstrániť priečinok „{ $folder }“ so všetkými správami a podpriečinkami? Odstráni sa aj zo servera.
ui-properties = V&lastnosti
ui-account-sync = Odoslať a &prijať
ui-account-properties = &Vlastnosti...
ui-account-properties-of = Vlastnosti &konta...
ui-account-move-up = Posunúť na&hor
ui-account-move-down = Posunúť nado&l
ui-menu-open = Ot&voriť
ui-menu-flag = &Farba príznaku
ui-menu-view-source = Zo&braziť zdroj
# Context menu: the same action as cmd-unsubscribe, with its own access key.
ui-menu-unsubscribe = Odhlá&siť odber zoznamu...
ui-save-attachments = Uložiť prílohy
ui-attachment-open = Otvoriť
ui-attachment-save-as = Uložiť ako...
ui-attachment-save-all = Uložiť všetky...
ui-attachment-show-in-message = Zobraziť v správe
ui-attachments-strip = Prílohy
ui-attachment-note-title = Otvorenie tohto súboru
ui-attachment-program-tip = Tento typ súboru môže spúšťať programy, preto sa nedá otvoriť priamo. Ak ho chcete otvoriť samostatne, najprv ho uložte.
ui-clear-flag = Zr&ušiť príznak
ui-button-move = P&resunúť
ui-button-copy = &Kopírovať
ui-find-folder = Nájsť priečinok
ui-new-folder-in = Nový priečinok bude v priečinku { $folder }.
ui-outbox-send-all = &Odoslať všetko teraz
ui-yes = Áno
ui-no = Nie
ui-try-again = Skúsiť znova
ui-remove = &Odstrániť
ui-signature-of = Textový podpis: { $account }
ui-sign-in-with = Prihlásiť sa cez { $provider }
ui-sign-in-in-browser-yours = Prihláste sa do svojho konta v okne prehliadača, ktoré sa otvorilo, a potom sa vráťte sem.
ui-browser-sign-in-server = { $server } (prihlásenie cez prehliadač)
ui-dont-allow = Nepovoliť
ui-allow = &Povoliť
ui-dont-send = Neodoslať
ui-dont-unsubscribe = Neodhlásiť odber
ui-edit-first = Najprv &upraviť
ui-new-address = Nová adresa
ui-turn-away = O&dmietnuť
ui-clear-agent-log = Vymazať históriu aktivity agentov?
ui-clear-agent-log-detail = Týmto sa nevrátia zmeny vykonané agentmi.
ui-let-agents-connect = &Povoliť AI agentom pripájať sa k Inbox Classic
ui-change-button = Zmeniť…
ui-undo-button = Späť
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Vrátiť zmeny za obdobie…
ui-undo-since-span = Vrátiť zmeny tohto programu za obdobie:
ui-take-back = Vrátiť zmeny
ui-rules-title = Pravidlá správ
ui-rules-intro = Pravidlá spracúvajú nové správy v priečinku Doručená pošta, kým je Inbox Classic spustený. Pravidlá, ktorých podmienky správa spĺňa, sa použijú v poradí. Keď pravidlo určí presunutie správy mimo tohto priečinka, ďalšie pravidlá sa už neuplatnia.
ui-rules-none = Zatiaľ nemáte žiadne pravidlá. Kliknutím na Nové vytvoríte prvé.
ui-rule-new = &Nové...
ui-rule-edit = &Upraviť...
ui-rule-delete-button = O&dstrániť
ui-rule-title = Pravidlo správ
ui-rule-name = Názov:
ui-rule-account = Konto:
ui-rule-all-accounts = Všetky kontá
ui-rule-query = Kritériá vyhľadávania:
ui-rule-query-hint = Použite vyhľadávacie výrazy, napríklad from:ann@example.com, subject:faktúra alebo list:news.example.com, rovnako ako v poli vyhľadávania.
ui-rule-count = { $count ->
    [one] Týmto kritériám teraz zodpovedá 1 správa v priečinku Doručená pošta.
    [few] Týmto kritériám teraz zodpovedajú { $count } správy v priečinku Doručená pošta.
   *[other] Týmto kritériám teraz zodpovedá { $count } správ v priečinku Doručená pošta.
}
ui-rule-show = &Zobraziť
ui-rule-actions = Akcie:
ui-rule-move = &Presunúť do:
ui-rule-mark-read = Označiť ako p&rečítanú
ui-rule-flag = Označiť príznak&om
ui-rule-archive = &Archivovať
ui-rule-junk = Presunúť do priečinka &Nevyžiadaná pošta
ui-rule-delete = O&dstrániť
ui-rule-quiet = Ne&upozorňovať ma na ňu
ui-rule-apply-now = Použiť aj na správy, ktoré už sú v priečinku Doručená poš&ta
ui-rule-delete-ask = Odstrániť pravidlo „{ $name }“?
ui-create-rule = Vytvoriť pravidlo...
ui-rules-applied = { $count ->
    [one] 1 správa spracovaná vašimi pravidlami
    [few] { $count } správy spracované vašimi pravidlami
   *[other] { $count } správ spracovaných vašimi pravidlami
}
ui-col-rule-matches = Kritériá
ui-clear-button = &Vymazať
ui-how-to-connect = Ako pripojiť agenta…
ui-agent-programs = Programy, ktorých agenti požiadali o prístup k vašej pošte
ui-what-agents-did = Aktivita agentov
ui-restart-now = &Reštartovať teraz
ui-restart-later = &Neskôr

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Nový kontakt
ui-tb-new-group = Nová skupina
ui-tb-properties = Vlastnosti
ui-tb-write-to = Napísať
ui-menu-new-contact = Nový &kontakt...
ui-menu-new-group = Nová &skupina...
ui-menu-write-to = &Napísať
ui-menu-delete = &Odstrániť
ui-book-find-hint = Zadajte meno alebo e-mailovú adresu
ui-book-all-contacts = Všetky kontakty
ui-col-phone = Telefón
ui-book-empty = Adresár je prázdny. Kliknutím na Nový kontakt niekoho pridáte, alebo importujte súbor vCard či CSV z ponuky Súbor.
ui-book-no-match = Výrazu „{ $words }“ nezodpovedajú žiadne kontakty.
ui-book-delete-ask = { $count ->
    [one] Odstrániť tento kontakt z adresára?
    [few] Odstrániť tieto { $count } kontakty z adresára?
   *[other] Odstrániť týchto { $count } kontaktov z adresára?
}
ui-group-delete-ask = Odstrániť skupinu „{ $name }“? Jej kontakty zostanú v adresári.
ui-book-no-address = { $name } nemá e-mailovú adresu.
ui-new-contact-title = Nový kontakt
ui-contact-title = Vlastnosti: { $name }
ui-contact-first = Meno:
ui-contact-last = Priezvisko:
ui-contact-display = Zobrazované meno:
ui-contact-nickname = Prezývka:
ui-contact-company = Spoločnosť:
ui-contact-addresses = E-mailové adresy:
ui-contact-address-hint = Zadajte e-mailovú adresu
ui-contact-add = &Pridať
ui-contact-set-default = Nastaviť ako pre&dvolenú
ui-contact-default = { $address } (predvolená)
ui-contact-phones = Telefónne čísla:
ui-phone-home = Domov
ui-phone-work = Práca
ui-phone-mobile = Mobil
ui-phone-other = Iné
ui-contact-notes = Poznámky:
ui-contact-name-needed = Zadajte meno alebo e-mailovú adresu kontaktu.
ui-contact-address-invalid = „{ $address }“ nie je platná e-mailová adresa.
ui-contact-not-saved = Kontakt sa nepodarilo uložiť: { $reason }
ui-new-group-title = Nová skupina
ui-group-title = Vlastnosti: { $name }
ui-group-name = Názov skupiny:
ui-group-members = Členovia:
ui-group-select-members = &Vybrať členov...
ui-group-new-member = Pridať e-mailovú adresu, ktorá nie je v adresári:
ui-group-name-needed = Zadajte názov skupiny.
ui-group-not-saved = Skupinu sa nepodarilo uložiť: { $reason }
ui-group-members-count = { $count ->
    [one] 1 člen
    [few] { $count } členovia
   *[other] { $count } členov
}
ui-select-recipients = Vybrať príjemcov
ui-select-members = Vybrať členov skupiny
ui-pick-intro = Zadajte meno alebo ho vyberte zo zoznamu:
ui-pick-recipients = Príjemcovia správy:
ui-pick-members = Členovia skupiny:
ui-pick-to = &Komu →
ui-pick-cc = Kó&pia →
ui-pick-bcc = &Skrytá kópia →
ui-pick-add = &Pridať →
ui-pick-tip = Vybrať príjemcov z adresára
ui-filter-address-books = Adresáre (vCard, CSV)
ui-filter-vcard = Súbory vCard
ui-book-export-name = Adresár
ui-book-imported = { $added ->
    [one] Pridaný 1 kontakt
    [few] Pridané { $added } kontakty
   *[other] Pridaných { $added } kontaktov
}, { $skipped ->
    [one] 1 preskočený, už bol v adresári.
    [few] { $skipped } preskočené, už boli v adresári.
   *[other] { $skipped } preskočených, už boli v adresári.
}
ui-book-not-imported = Adresár sa nepodarilo importovať: { $reason }
ui-book-exported = { $count ->
    [one] 1 kontakt uložený do súboru { $file }.
    [few] { $count } kontakty uložené do súboru { $file }.
   *[other] { $count } kontaktov uložených do súboru { $file }.
}
ui-book-not-exported = Adresár sa nepodarilo uložiť: { $reason }
ui-code-copied = Kód bol skopírovaný
ui-codes-in-notifications = &Zobrazovať jednorazové kódy v upozorneniach na novú poštu
ui-tool-unread-only = Neprečítané
ui-no-unread = Nie sú tu žiadne neprečítané správy.
ui-pictures-always-sender = Vždy sťahovať obrázky (odosielateľ: { $sender })
ui-pictures-always-domain = Vždy sťahovať obrázky od všetkých z domény { $domain }
ui-pictures-unconfirmed = Doménu odosielateľa ({ $domain }) sa nepodarilo overiť, preto sa obrázky v tejto správe nesťahujú automaticky.
ui-pictures-always-option = &Sťahovať obrázky vo všetkých správach
ui-pictures-always-warning = Odosielatelia potom môžu zistiť, kedy čítate ich správy.
ui-protection-details = &Podrobnosti...
ui-protection-details-title = Podrobnosti zabezpečenia
ui-download-heading = Sťahovanie
ui-download-ahead = &Sťahovať správy vopred:
ui-download-ahead-recent = Nedávne správy s veľkosťou najviac 1 MB
ui-download-ahead-all = Všetky správy
ui-download-ahead-never = Iba pri otvorení
ui-download-limit = &Limit úložiska na konto:
ui-send-delay = &Oneskorenie pred odoslaním:
ui-send-delay-note = Počas odpočítavania môžete odoslanie správy zrušiť príkazom Späť.
ui-dark-messages = Zobrazovať správy na tmavom pozadí, keď je systém v tmavom režime
ui-preview-show = Zobrazovať prí&lohy v správach
ui-preview-show-note = Zobrazuje obrázky a prvé strany súborov PDF pod textom správy. Inbox Classic náhľady vytvára sám bez spúšťania skriptov obsiahnutých v súboroch.
ui-preview-pdfs = Zobrazovať súbory PD&F v správach
ui-sending-in = Odoslanie správy { $subject } o { $count ->
    [one] 1 sekundu
    [few] { $count } sekundy
   *[other] { $count } sekúnd
}
ui-send-undone = Správa { $subject } sa neodoslala. Znova sa otvorila na úpravy.
ui-send-too-late = Odoslanie správy { $subject } už nemožno zrušiť.
ui-outbox-status-undo = Odoslanie najskôr o { $time }
ui-download-note = Správy stiahnuté vopred môžete otvoriť bez čakania na stiahnutie. Po prekročení limitu program odstráni najstaršie stiahnuté kópie obsahu, okrem konceptov a správ otvorených od spustenia programu. Odstránený obsah sa pri otvorení stiahne znova. Limit sa nevzťahuje na všetky údaje aplikácie.
ui-attachment-downloading = Táto správa sa ešte nestiahla celá. Skúste to znova po dokončení sťahovania.
ui-trusted-senders-button = &Dôveryhodní odosielatelia...
ui-trusted-senders-title = Dôveryhodní odosielatelia
ui-trusted-senders-note = Obrázky od týchto odosielateľov sa môžu sťahovať automaticky, ak poskytovateľ pošty overí doménu odosielateľa. Výnimkou sú nevyžiadaná pošta a šifrované časti správ.
ui-trusted-everyone-at = Všetci z domény { $domain }
ui-trusted-senders-empty = Zatiaľ neboli pridaní žiadni dôveryhodní odosielatelia.
ui-search-encrypted = Hľadať v š&ifrovaných správach
ui-search-encrypted-note = Po stiahnutí alebo otvorení správy sa ju program pokúsi dešifrovať dostupným kľúčom. Potom možno prehľadávať jej obsah a v zozname zobraziť chránený predmet. Index sa ukladá v tomto počítači bez šifrovania. AI agenti neprehľadávajú dešifrovaný obsah. Vypnutím tejto možnosti odstránite dešifrované údaje z indexu a obnovíte vonkajšie predmety správ.
ui-pgp-keyserver = &Hľadať kľúče na keys.openpgp.org
ui-pgp-keyserver-note = Pri hľadaní kľúča podľa e-mailovej adresy sa program najprv obráti na doménu adresy. Ak tam kľúč nenájde a táto možnosť je zapnutá, odošle adresu aj na keys.openpgp.org. Pri hľadaní podľa odtlačku alebo identifikátora kľúča sa namiesto adresy odošle tento identifikátor.
ui-eml-default = Otvárať &súbory .eml v Inbox Classic
ui-eml-default-done = Inbox Classic teraz otvára súbory .eml.
ui-eml-default-failed = Inbox Classic sa nepodarilo nastaviť ako predvolenú aplikáciu pre súbory .eml: { $reason }
ui-folders = Priečinky
ui-sorted-by = Zoradené podľa: { $field }
ui-layout-label = &Rozloženie:
ui-columns-note = Okno je dosť široké na rozloženie so stĺpcami. Rozloženie môžete zmeniť v ponuke Zobraziť > Rozloženie.
ui-row-unread = Neprečítaná
ui-row-flagged = S príznakom
ui-row-attachments = Obsahuje prílohy
ui-row-encrypted = Šifrovaná
ui-row-signed = Digitálne podpísaná
ui-row-messages = { $count ->
    [one] { $count } správa
    [few] { $count } správy
   *[other] { $count } správ
}
ui-list-pictures = &Zobrazovať obrázky odosielateľov v zozname správ
ui-list-pictures-note = V stĺpcovom rozložení zobrazuje logá značiek alebo obrázky z adresára, ak poskytovateľ potvrdí doménu odosielateľa. Inak zobrazuje iniciály. Logá sa uchovávajú v počítači a používajú opakovane; ich stiahnutie alebo obnovenie môže vyžadovať pripojenie na internet.
ui-card-picture = Obrázok:
ui-card-picture-choose = &Vybrať...
ui-picture-not-picture = Tento súbor nie je platný obrázok PNG ani JPEG.
ui-picture-too-large = Tento obrázok je príliš veľký. Vyberte obrázok s veľkosťou najviac 10 MB, so šírkou a výškou najviac 8000 pixelov.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
ui-keys-title = Šifrovacie kľúče
ui-keys-intro = Vaše kľúče slúžia na digitálne podpisovanie správ a dešifrovanie pošty určenej pre vás. Kľúče kontaktov umožňujú kontrolovať ich digitálne podpisy a šifrovať správy pre nich.
ui-keys-empty = Zatiaľ žiadne kľúče. Kliknutím na Nový kľúč si vytvoríte vlastný, alebo kliknutím na Importovať pridáte kľúč, ktorý už máte.
ui-keys-col-name = Meno
ui-keys-col-address = Adresa
ui-keys-col-kind = Druh
ui-keys-col-status = Stav
ui-keys-kind-own = Váš kľúč
ui-keys-kind-contact = Kontakt
ui-keys-status-verified = { $status }; vlastník kľúča je overený
ui-keys-new = &Nový kľúč...
ui-keys-import = &Importovať...
ui-keys-export = &Exportovať...
ui-keys-backup = &Zálohovať...
ui-keys-verify = Ove&riť...
ui-keys-new-title = Nový kľúč
ui-keys-new-for = Vytvoriť kľúč pre:
ui-keys-new-make = &Vytvoriť kľúč
ui-keys-no-account = Najprv pridajte poštové konto: kľúč sa vytvára pre adresy konta.
ui-keys-memory-only = Heslá sa uchovávajú iba v pamäti, preto súkromný kľúč vytvorený alebo importovaný teraz nebude možné použiť po zatvorení Inbox Classic.
ui-keys-backup-offer = Váš nový kľúč je pripravený. Uložiť teraz jeho zálohu? Ak tento počítač stratíte alebo ho obnovíte do pôvodného stavu, kľúč možno získať späť iba zo zálohy.
ui-keys-backup-now = &Uložiť zálohu...
ui-keys-later = &Neskôr
ui-keys-backup-title = Zálohovať kľúč
ui-keys-backup-intro = Záloha je chránená prístupovou frázou. Súbor a prístupovú frázu uchovávajte na rôznych bezpečných miestach: na obnovenie kľúča potrebujete oboje.
ui-keys-passphrase = &Prístupová fráza:
ui-keys-passphrase-again = &Zadajte ju znova:
ui-keys-passphrase-differ = Prístupové frázy sa nezhodujú.
ui-keys-passphrase-short = Použite prístupovú frázu s aspoň 8 znakmi.
ui-keys-backup-saved = Záloha bola uložená.
ui-keys-import-title = Importovať kľúč
ui-keys-import-passphrase = Tento súkromný kľúč je chránený prístupovou frázou. Zadajte ju, aby sa kľúč importoval:
ui-keys-file-filter = Kľúče OpenPGP
ui-keys-use-for = Priradiť kľúče k adresám: { $addresses }? Budete ich môcť používať na digitálne podpisovanie správ z týchto adries a dešifrovanie pošty pre ne.
ui-keys-use = &Použiť
ui-keys-not-now = &Teraz nie
ui-keys-remove-own = Odstrániť váš kľúč { $fingerprint }? Bez opätovného importu jeho zálohy ho nebudete môcť použiť na dešifrovanie pošty. Už dešifrované údaje sa tým neodstránia.
ui-keys-remove-contact = Odstrániť kľúč kontaktu „{ $name }“? Kým ho znova nepridáte, nebude možné používať tento kľúč na kontrolu digitálnych podpisov ani na šifrovanie pošty.
ui-key-properties-title = Vlastnosti kľúča
ui-key-names = Mená:
ui-key-fingerprint = Odtlačok:
ui-key-status = Stav:
ui-key-created = Vytvorený:
ui-key-expires = Platnosť do:
ui-key-never = Nikdy
ui-key-algorithm = Algoritmus:
ui-key-source = Zdroj:
ui-key-addresses = Adresy:
ui-key-address-verified = { $address } (vlastník kľúča je overený)
ui-key-address-not-verified = { $address } (vlastník kľúča nie je overený)
ui-verify-title = Overiť kľúč
ui-verify-intro = Kontakt: { $name }. Požiadajte túto osobu, aby vám osobne alebo počas hovoru prečítala odtlačok kľúča zo svojej aplikácie. Neporovnávajte ho s odtlačkom poslaným e-mailom: kto mohol zmeniť kľúč, mohol zmeniť aj správu s odtlačkom.
ui-verify-fingerprint = Odtlačok kľúča, ktorý máte:
ui-verify-marks = { $count ->
    [0] Tento kľúč neobsahuje e-mailové adresy. Overenie jeho vlastníka sa nedá uložiť.
    [one] Ak sa odtlačky zhodujú, potvrdíte vlastníka kľúča pre adresu: { $addresses }. Ak táto adresa danej osobe nepatrí, kliknite na Líšia sa.
   *[other] Ak sa odtlačky zhodujú, potvrdíte vlastníka kľúča pre adresy: { $addresses }. Ak niektorá z nich danej osobe nepatrí, kliknite na Líšia sa.
}
ui-verify-match = &Zhodujú sa
ui-verify-differ = &Líšia sa
ui-verify-differs = Kľúč, ktorý máte, nie je ten, ktorý má { $name }. Odstráňte ho a požiadajte o kľúč znova.
ui-verify-unmark = Zrušiť overe&nie vlastníka
ui-account-security = Zabezpečenie
ui-account-security-intro = S kľúčom môžete správy digitálne podpisovať a ostatní vám môžu posielať šifrovanú poštu.
ui-account-key = &Kľúč pre toto konto:
ui-account-key-none = Žiadny
ui-account-key-new = &Nový kľúč...
ui-account-autocrypt = &Posielať môj verejný kľúč s mojimi správami (Autocrypt)
ui-contact-key = Šifrovací kľúč:
ui-contact-key-none = Žiadny kľúč
ui-contact-key-use-new = Použiť &nový kľúč
ui-contact-key-keep = Ponechať &súčasný
ui-recipient-keys-title = Kľúče príjemcov
ui-recipient-col-recipient = Príjemca
ui-recipient-col-key = Kľúč
ui-recipient-find-key = Nájsť &kľúč
ui-recipient-remove = &Odstrániť zo správy
ui-send-unencrypted = Odoslať &bez šifrovania
ui-compose-make-key = &Vytvoriť kľúč...
ui-compose-show-keys = Šifrovacie &kľúče...
ui-compose-encrypt-off = &Vypnúť šifrovanie
ui-compose-keep-encrypted = &Ponechať šifrovanie
ui-setup-export-title = Exportovať nastavenia a kontá
ui-setup-import-title = Importovať nastavenia a kontá
ui-setup-export-intro = Vyberte, čo chcete preniesť do iného počítača. Súbor neobsahuje správy. Na druhom počítači možno znova stiahnuť poštu uloženú na serveri; správy dostupné iba v tomto počítači sa neprenesú.
ui-setup-use-passphrase = &Chrániť súbor prístupovou frázou
ui-setup-passphrase-note = Súbor chránený prístupovou frázou je šifrovaný a môže obsahovať dostupné uložené heslá, prihlasovacie údaje a súkromné kľúče z vybraných častí konfigurácie. Bez prístupovej frázy sa budete musieť na druhom počítači znova prihlásiť do kont, prípadne cez prehliadač.
ui-setup-export-button = &Exportovať...
ui-setup-file-filter = Nastavenia a kontá Inbox Classic
ui-setup-ask-passphrase = Tento súbor je chránený prístupovou frázou. Zadajte ju, ak chcete vidieť, čo súbor obsahuje:
ui-setup-import-intro = Vyberte, čo chcete importovať. Existujúce kontá v tomto počítači zostanú nezmenené.
ui-setup-from = Uložil Inbox Classic { $version } dňa { $date }.
ui-setup-import-button = &Importovať
ui-setup-done = Hotovo
ui-setup-first-run = Importovať nastavenia a kontá z iného počítača...
ui-first-run-other = Už používate Inbox Classic na inom počítači? Preneste sem jeho kontá a nastavenia.
ui-first-run-sync = Pripojiť sa k synchronizácii…
ui-first-run-import = Importovať zo súboru…

ui-field-verifiers = Dôveryhodné zdroje overenia odosielateľa:
ui-attachment-import-key = Importovať kľúč...
ui-book-key-known = Má šifrovací kľúč
ui-book-key-verified = Má šifrovací kľúč s overeným vlastníkom
ui-keys-publish = Zvere&jniť...
ui-keys-publish-ask = Zverejniť váš verejný kľúč na keys.openpgp.org, aby ho ostatní mohli nájsť? Adresy v kľúči: { $addresses }. Každú adresu treba pred zaradením do adresára potvrdiť pomocou odkazu zaslaného na túto adresu.
ui-keys-publish-now = Zverejniť
ui-keys-paste = Importovať zo &schránky
ui-keys-paste-none = Schránka neobsahuje žiadny kľúč OpenPGP.
ui-contact-find-key = Nájsť &kľúč
ui-reactions-label = Reakcie:
ui-reaction-open-email = Otvoriť e-mail s reakciou
ui-reaction-show-as-email = Zobraziť ako e-mail
ui-reaction-when = Reakcia: { $when }
