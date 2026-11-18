# Lietuvių. Juodraštis, laukia gimtakalbio peržiūros (žr. core/locales/GLOSSARY.md).

## The menus

menu-file = &Failas
menu-edit = &Taisa
menu-view = &Rodinys
menu-tools = Įra&nkiai
menu-message = &Laiškas
menu-help = Ž&inynas
menu-layout = &Išdėstymas
menu-sort-by = &Rikiuoti pagal
menu-text-size = &Teksto dydis
menu-folder = &Aplankas
menu-insert = Įt&erpti

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = &Nauja paskyra...
cmd-exit = &Išeiti
cmd-sync = Siųsti ir &gauti visose paskyrose
cmd-mark-read = &Žymėti kaip skaitytą
cmd-mark-unread = Žymėti kaip &neskaitytą
cmd-pictures = Atsisiųsti &paveikslėlius
cmd-about = &Apie Inbox Classic
cmd-new-mail = &Naujas laiškas
cmd-reply = &Atsakyti siuntėjui
cmd-reply-all = Atsakyti &visiems
cmd-forward = Persi&ųsti
cmd-help = &Turinys
cmd-delete = Panaikin&ti laišką
cmd-move = Perk&elti į aplanką...
cmd-flag = Žymėti vėliavėl&e
cmd-new-folder = &Naujas aplankas...
cmd-rename-folder = &Pervardyti aplanką...
cmd-delete-folder = Panaikin&ti aplanką
cmd-empty-folder = &Išvalyti aplanką
ui-empty-button = Išvalyti
cmd-accounts = &Paskyros...
cmd-find = &Ieškoti laiško
cmd-save-as = Įrašyti &kaip...
cmd-print = &Spausdinti...
cmd-import = Importuoti &laiškus...
cmd-outbox = &Siunčiami laiškai...
cmd-properties = &Ypatybės
cmd-mark-all-read = Žymėti &visus kaip skaitytus
cmd-junk = Žymėti kaip nepa&geidaujamą
cmd-not-junk = Žymėti &kaip pageidaujamą
cmd-archive = A&rchyvuoti
cmd-watch-conversation = Ste&bėti pokalbį
cmd-ignore-conversation = &Ignoruoti pokalbį
cmd-next-message = &Kitas laiškas
cmd-previous-message = A&nkstesnis laiškas
cmd-next-unread = Kitas ne&skaitytas laiškas
cmd-go-to-folder = &Eiti į aplanką...
cmd-find-in-message = Ieškoti šiame &laiške...
ui-go-to-prompt = Eiti į aplanką:
ui-find-in-message-hint = Ieškoti šiame laiške
ui-find-not-found = „{ $words }“ šiame laiške nėra
cmd-expand-all-threads = Išskleisti &visus pokalbius
cmd-collapse-all-threads = S&utraukti visus pokalbius
ui-group-by-conversation = &Grupuoti laiškus pagal pokalbius
cmd-folder-list = &Aplankų sąrašas
cmd-layout-automatic = &Automatinis
cmd-layout-classic = &Klasikinis
cmd-layout-columns = &Stulpeliai
cmd-sort-date = &Data
cmd-sort-from = &Siuntėjas
cmd-sort-subject = &Tema
cmd-sort-size = D&ydis
cmd-sort-ascending = Didėjimo tvar&ka
cmd-sort-descending = &Mažėjimo tvarka
cmd-text-size-largest = &Didžiausias
cmd-text-size-larger = Did&esnis
cmd-text-size-medium = &Vidutinis
cmd-text-size-smaller = &Mažesnis
cmd-text-size-smallest = Mažiau&sias
cmd-hide-ignored = Slėpti ign&oruojamus pokalbius
cmd-hide-read = Slėpti skait&ytus laiškus
cmd-notify = Pranešti apie &naujus laiškus
cmd-open = &Atidaryti Inbox Classic
cmd-default-app = N&ustatyti kaip numatytąją pašto programą...
cmd-view-source = &Laiško šaltinis
cmd-ai-agents = &DI agentai...
cmd-options = Pa&rinktys...
cmd-message-rules = Laiškų &taisyklės...
cmd-encryption-keys = Šifravimo ra&ktai...
cmd-create-rule-from-message = Kurti &taisyklę iš laiško...
cmd-select-all = &Pažymėti viską
cmd-undo = &Atšaukti
cmd-copy = K&opijuoti į aplanką...
cmd-address-book = &Adresų knygelė...
cmd-add-sender-to-book = Įtraukti siuntėją į adresų knyge&lę
cmd-import-address-book = Importuoti a&dresų knygelę...
cmd-export-address-book = &Eksportuoti adresų knygelę...
cmd-export-setup = Eksportuoti nus&tatymus ir paskyras...
cmd-import-setup = Importuoti n&ustatymus ir paskyras...
cmd-compose-sign = Skaitmeniškai &pasirašyti
cmd-compose-encrypt = Ši&fruoti
cmd-attach-my-key = Pridėti savo &viešąjį raktą

## The tray icon's menu

tray-check = &Tikrinti, ar yra naujų laiškų
tray-no-accounts = Paskyrų dar nėra

## Words the windows of more than one platform share

ui-tb-create-mail = Naujas laiškas
ui-tb-reply = Atsakyti
ui-tb-reply-all = Atsakyti visiems
ui-tb-forward = Persiųsti
ui-tb-print = Spausdinti
ui-tb-delete = Naikinti
ui-tb-junk = Nepageidaujamas
ui-tb-not-junk = Pageidaujamas
ui-tb-archive = Archyvuoti
ui-tb-previous = Ankstesnis
ui-tb-next = Kitas
ui-previous-tip = Ankstesnis laiškas
ui-next-tip = Kitas laiškas
ui-tb-sync = Siųsti ir gauti
ui-tb-mark-read = Skaitytas
ui-tb-mark-unread = Neskaitytas
ui-still-running = Inbox Classic vis dar veikia
ui-no-subject = (be temos)
ui-quoted = „{ $subject }“
ui-newest-from = Naujausias laiškas: { $subject } (siuntėjas: { $sender })
ui-new-messages = { $count ->
    [one] { $count } naujas laiškas
    [few] { $count } nauji laiškai
   *[other] { $count } naujų laiškų
}
ui-outbox-waiting = { $count ->
    [one] { $count } laiškas aplanke „Siunčiami laiškai“
    [few] { $count } laiškai aplanke „Siunčiami laiškai“
   *[other] { $count } laiškų aplanke „Siunčiami laiškai“
}
ui-outbox-waits = Laiškas { $subject } laukia aplanke „Siunčiami laiškai“
ui-outbox-sending = Siunčiamas laiškas { $subject }...
ui-from-account = Paskyra: { $account }
ui-sign-in-refused = Prisijungimas prie paskyros { $account } atmestas arba seansas baigėsi.
ui-sign-in-again-ask = Prisijungti iš naujo naršyklėje?
ui-sign-in-again-failed = Nepavyko prisijungti iš naujo: { $reason }
ui-unknown-reason = nežinoma priežastis
ui-checking = Ieškoma naujų laiškų. Paskyra: { $account }...
ui-done = Atlikta
ui-sent-at = Laiškas { $subject } išsiųstas { $time }
ui-draft-saved = Laiškas įrašytas į aplanką „Juodraščiai“
ui-draft-not-saved = Laiškas neįrašytas į aplanką „Juodraščiai“: { $reason }
ui-about-core = Branduolys { $version }
ui-add-account-first = Pirmiausia pridėkite pašto paskyrą.
ui-add-account-first-link = Pirmiausia pridėkite pašto paskyrą, tada dar kartą spustelėkite el. pašto nuorodą.
ui-default-app-is = Inbox Classic yra numatytoji pašto programa. Spustelėjus el. pašto nuorodą, joje atveriamas naujo laiško langas.
ui-select-message-first = Pirmiausia pažymėkite laišką.
ui-store-not-opened = Nepavyko atidaryti pašto saugyklos.
ui-store-or-cert-not-opened = Nepavyko atidaryti pašto saugyklos arba sertifikato failo.
ui-help-title = Inbox Classic žinynas
ui-help-missing = Šioje programos Inbox Classic kopijoje nėra žinyno.
ui-ok = Gerai
ui-cancel = Atšaukti
ui-close = Uždaryti
ui-col-subject = Tema
ui-col-from = Nuo
ui-col-to = Kam
ui-col-received = Gauta
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Stebimas pokalbis
ui-col-sent = Išsiųsta
ui-col-size = Dydis
ui-col-folder = Aplankas
ui-col-account = Paskyra
ui-col-queued = Įtraukimo laikas
ui-col-status = Būsena
ui-outbox-title = Siunčiami laiškai
ui-outbox-status-waiting = Laukia
ui-outbox-status-not-sent = Neišsiųsta: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = Į eilę įtraukė DI agentas; siuntimas nuo { $time }
ui-outbox-delete-ask = Panaikinti šį laišką jo neišsiuntus?
ui-open-link = Atidaryti nuorodą
ui-edit-link = Redaguoti nuorodą...
ui-remove-link = Pašalinti nuorodą
ui-insert-attachment = Įterpti priedą
ui-insert-picture = Įterpti paveikslėlį
ui-filter-all = Visi failai
ui-filter-pictures = Paveikslėliai
ui-filter-messages = El. laiškai
ui-save-attachment-as = Įrašyti priedą kaip
ui-not-sent = Laiško išsiųsti nepavyko.
ui-attachment-forgotten = Parašėte „{ $word }“, bet joks failas nepridėtas. Vis tiek siųsti laišką?
ui-send-anyway = Vis tiek siųsti
ui-go-back = Grįžti
ui-not-saved = Laiško įrašyti nepavyko.
ui-saving-draft = Įrašoma į aplanką „Juodraščiai“...
ui-compose-saved-at = Įrašyta į aplanką „Juodraščiai“ { $time }
ui-compose-restored = Laiškas atkurtas po netikėto programos užsidarymo
ui-compose-not-saved = Neįrašyta į aplanką „Juodraščiai“: { $reason }
ui-save-changes-ask = Ar įrašyti šio laiško pakeitimus į aplanką „Juodraščiai“?
ui-new-message-title = Naujas laiškas
ui-link-invalid = Įveskite žiniatinklio adresą (https://...) arba el. pašto nuorodą (mailto:...).
ui-link-address = Adresas:
ui-hyperlink = Hipersaitas
ui-hyperlink-intro = Adresas, į kurį veda pažymėtas tekstas.
ui-edit-hyperlink = Redaguoti hipersaitą
ui-edit-hyperlink-intro = Nuorodos paskirties adresas. Ištrinkite adresą, kad pašalintumėte nuorodą ir paliktumėte tekstą.
ui-not-a-picture = Nepavyko įterpti paveikslėlio. Pasirinkite ne didesnį kaip 10 MB PNG, JPEG, GIF arba WebP failą.
ui-format-color = Šrifto spalva
ui-format-numbers = Numeruotas sąrašas
ui-format-bullets = Sąrašas su ženkleliais
ui-format-outdent = Mažinti įtrauką
ui-format-indent = Didinti įtrauką
ui-format-left = Lygiuoti kairėje
ui-format-center = Centruoti
ui-format-right = Lygiuoti dešinėje
ui-format-line = Įterpti horizontalią liniją
ui-tb-send = Siųsti
ui-tb-save = Įrašyti
ui-tb-attach = Pridėti
ui-tb-sign = Pasirašyti
ui-tb-encrypt = Šifruoti
ui-field-keys = Raktai:
ui-field-from = Nuo:
ui-field-to = Kam:
ui-field-cc = Kopija:
ui-field-bcc = Slapta kopija:
ui-field-subject = Tema:
ui-field-attach = Priedai:
ui-signature = Parašo tekstas
ui-signature-hint = Įterpiamas į šios paskyros naujus laiškus, atsakymus ir persiunčiamus laiškus.
ui-signature-not-saved = Nepavyko įrašyti parašo teksto.
ui-all-inboxes = Visi gauti laiškai
ui-all-sent = Visi išsiųsti
ui-all-drafts = Visi juodraščiai
ui-flagged-folder = Su vėliavėle
ui-all-folders = Visi aplankai
ui-the-account = paskyra
ui-folder-name = Aplanko pavadinimas:
ui-find-hint = Ieškoti laiškų
ui-find-tip = Ieško laiškų temose ir tekste, siuntėjų bei gavėjų varduose ir adresuose, taip pat priedų pavadinimuose.
ui-clear-search = Išvalyti paiešką
ui-no-match = Nėra laiškų, atitinkančių „{ $words }“.
ui-no-match-all = Visuose aplankuose ieškoma laiškų temose ir tekste, siuntėjų bei gavėjų varduose ir adresuose, taip pat priedų pavadinimuose. Patikrinkite rašybą arba įveskite mažiau žodžių.
ui-no-match-in = Paieškos vieta: „{ $folder }“. Ieškoma laiškų temose ir tekste, siuntėjų bei gavėjų varduose ir adresuose, taip pat priedų pavadinimuose. Patikrinkite rašybą arba įveskite mažiau žodžių.
ui-no-items = Šiame rodinyje nėra laiškų.
ui-choose-folder = Pasirinkite aplanką, kad pamatytumėte jo laiškus.
ui-unsubscribe = Atsisakyti prenumeratos
ui-open-in-calendar = Atidaryti kalendoriuje
ui-pictures-blocked = Kai kurie paveikslėliai užblokuoti, kad siuntėjui būtų sunkiau sekti, kada skaitote laišką. Spustelėkite čia, kad juos atsisiųstumėte.
ui-not-shown = Laiško parodyti nepavyko.
ui-attachment-not-read = Priedo perskaityti nepavyko.
ui-attachment-not-saved = Priedo įrašyti nepavyko.
ui-not-downloaded = Laiškas dar neatsisiųstas.
ui-leave-list = Atsisakyti šio adresatų sąrašo prenumeratos?
ui-leave-one-click = Inbox Classic išsiųs prašymą atsisakyti prenumeratos svetainei { $target }. Tinklalapis nebus atidarytas ir el. laiškas nebus siunčiamas.
ui-leave-mail = Inbox Classic paruoš laišką su prašymu atsisakyti prenumeratos. Gavėjas: { $target }. Išsiųskite laišką, kad pateiktumėte prašymą.
ui-leave-web = Adresatų sąrašo prenumeratos atsisakymo puslapis bus atidarytas jūsų naršyklėje ({ $target }).
ui-unsubscribing = Siunčiamas prašymas atsisakyti prenumeratos: { $target }...
ui-cannot-unsubscribe = Šiame laiške nėra galimybės atsisakyti prenumeratos.
ui-unsubscribed = Prašymas atsisakyti prenumeratos priimtas.
ui-not-unsubscribed = Nepavyko atsisakyti prenumeratos: { $reason }
ui-event-span = { $start } iki { $end }
ui-event-floating = { $when } (laiko juosta nenustatyta)
ui-invitation = Kvietimas: { $title }
ui-invitation-updated = Atnaujintas kvietimas: { $title }
ui-invitation-canceled = Atšaukta: { $title }
ui-invitation-answer = Atsakymas į kvietimą: { $title }
ui-no-title = (be pavadinimo)
ui-organizer = Organizatorius: { $name }
ui-invitation-not-read = Kvietimo perskaityti nepavyko.
ui-no-calendar = Nepavyko atidaryti kvietimo kalendoriaus programoje. Patikrinkite, ar kompiuteryje yra programa .ics failams atidaryti.
ui-messages-not-changed = Laiškų pakeisti nepavyko.
ui-new-folder-in-selected = Naujas aplankas bus sukurtas pažymėtame aplanke.
ui-new-folder-at-top = Naujas aplankas bus sukurtas paskyros viršutiniame lygmenyje.
ui-folder-not-created = Aplanko sukurti nepavyko.
ui-folder-not-renamed = Aplanko pervardyti nepavyko.
ui-folder-not-deleted = Aplanko panaikinti nepavyko.
ui-rename-folder-intro = Įveskite naują aplanko „{ $folder }“ pavadinimą.
ui-properties-of = Ypatybės: { $subject }
ui-internet-headers = Šio laiško antraštės:
ui-save-messages-in = Pasirinkti aplanką laiškams įrašyti
ui-save-message-as = Įrašyti laišką kaip
ui-import-choose-folder = Pirmiausia pasirinkite aplanką, į kurį importuoti laiškus.
ui-add-account-title = Pridėti pašto paskyrą
ui-accounts-title = Paskyros
ui-security-none = Nėra (nešifruota)
ui-field-required = Laukas „{ $field }“ privalomas.
ui-email-invalid = El. pašto adresas netinkamas.
ui-ports-invalid = Prievadų numeriai turi būti nuo 1 iki 65535.
ui-looking-up = Ieškoma domeno { $domain } nustatymų...
ui-found-none = Įveskite paskyros duomenis, kuriuos pateikė jūsų el. pašto paslaugų teikėjas.
ui-found-change = Pakeiskite šiuos nustatymus, jei paslaugų teikėjas pateikė kitokius.
ui-found-guess = Šiam adresui nustatymų nerasta. Siūlomi serverių adresai yra tik spėjimai. Patikrinkite juos pagal paslaugų teikėjo nurodymus.
ui-found-mx = Inbox Classic atpažino jūsų el. pašto paslaugų teikėją ir parinko jo serverių nustatymus.
ui-found-srv = Šie nustatymai rasti jūsų domeno DNS įrašuose.
ui-found-autodiscover = Šie nustatymai rasti naudojant Microsoft Autodiscover (Exchange).
ui-found-other = Šiam adresui rasti šie nustatymai.
ui-app-password-needed = { $provider } pašto programose nepriima įprasto paskyros slaptažodžio. Programos slaptažodį sukurkite savo paskyroje svetainėje, kurią valdo { $provider }. Kitame lange įveskite jį į lauką „Slaptažodis“.
ui-app-password-open = Atidaryti naršyklėje instrukcijas, kurias pateikia { $provider }?
ui-plain-warning = Be šifravimo bet kas, perimantis jūsų tinklo srautą, gali perskaityti jūsų slaptažodį ir laiškus. Naudokite šį ryšį tik su serveriu, esančiu jūsų kompiuteryje arba vietiniame tinkle.
ui-continue-ask = Tęsti?
ui-add-sign-in-app = Pridėti prisijungimo programą...
ui-turned-off = Šiame kompiuteryje parinktis „{ $name }“ išjungta.
ui-off-here = Šiame kompiuteryje išjungta.
ui-why = Kodėl?
ui-more-sign-in = Daugiau prisijungimo būdų...
ui-other-account = Norėdami pridėti kitą el. pašto paskyrą, įveskite savo el. pašto adresą ir vardą, kurį turi matyti gavėjai. Tada bus ieškoma serverio nustatymų.
ui-field-account-name = Paskyros pavadinimas:
ui-field-name = Rodomas vardas:
ui-field-email = El. pašto adresas:
ui-field-user = Naudotojo vardas:
ui-field-password = Slaptažodis:
ui-field-imap-host = Gaunamųjų laiškų (IMAP) serveris:
ui-field-imap-port = IMAP prievadas:
ui-field-imap-security = IMAP sauga:
ui-field-smtp-host = Siunčiamųjų laiškų (SMTP) serveris:
ui-field-smtp-port = SMTP prievadas:
ui-field-smtp-security = SMTP sauga:
ui-field-other-addresses = Kiti adresai, iš kurių siunčiate:
ui-sign-in-not-started = Nepavyko pradėti prisijungimo per naršyklę.
ui-sign-in-in-browser = Prisijunkite prie paskyros { $account } atsidariusiame naršyklės lange, tada grįžkite čia.
ui-sign-in-failed = Nepavyko prisijungti: { $reason }
ui-account-not-saved = Paskyros įrašyti nepavyko.
ui-start-intro = Gmail, Google Workspace, Outlook.com ir Microsoft 365 paskyras pridėkite prisijungę svetainėje, kurią valdo Google arba Microsoft. Slaptažodį įvesite ten; Inbox Classic jo negaus.
ui-start-intro-apps = Prisijunkite per naršyklę naudodami vieną iš savo prisijungimo programų (parinktis „Daugiau prisijungimo būdų“) arba toliau pridėkite el. pašto paskyrą, įvedę savo vardą ir el. pašto adresą.
ui-use-app-password = Naudoti programos slaptažodį
ui-the-provider = paslaugų teikėjas
ui-provider-intro = Prisijunkite prie paskyros { $email } svetainėje, kurią valdo { $provider }. Inbox Classic negaus jūsų slaptažodžio. Jei jūsų paskyroje leidžiama naudoti programos slaptažodį paštui, galite jį sukurti paskyros saugos nustatymuose. Prie Outlook.com ir Microsoft 365 paskyrų čia prisijungiama tik per naršyklę.
ui-provider-intro-apps = Prisijunkite prie paskyros { $email } svetainėje, kurią valdo { $provider }, naudodami vieną iš savo prisijungimo programų (parinktis „Daugiau prisijungimo būdų“). Jei jūsų paskyroje leidžiama naudoti programos slaptažodį paštui, galite jį sukurti paskyros saugos nustatymuose. Prie Outlook.com ir Microsoft 365 paskyrų čia prisijungiama tik per naršyklę.
ui-finish = Baigti
ui-logon = Prisijungimas
ui-enter-password = Įveskite paskyros { $account } slaptažodį.
ui-signs-in-with = Prisijungimo programa: { $app }. Prisijungiama naršyklėje, o paskyra naudoja šios programos serverius.
ui-keep-password = Palikite slaptažodžio lauką tuščią, kad liktų dabartinis slaptažodis.
ui-remove-account = Pašalinti paskyrą
ui-remove-account-ask = Pašalinti šią paskyrą iš Inbox Classic? Jos vietiniai laiškai ir įrašyti prisijungimo duomenys bus pašalinti. Serveryje esantys laiškai liks, tačiau tik šiame kompiuteryje laikomi laiškai bus prarasti.
ui-col-email = El. pašto adresas
ui-col-incoming = Gaunamųjų laiškų serveris
ui-type-email = Įveskite savo el. pašto adresą, vardas@example.com.
ui-ai-agent = DI agentas
ui-ai-agent-access = DI agento prieiga
ui-ai-agents = DI agentai
ui-program-path = Programa: { $path }
ui-it-may = Leidžiami veiksmai:
ui-accounts-it-may-use = Leidžiamos paskyros:
ui-send-message-ask = Siųsti laišką?
ui-col-name = Pavadinimas
ui-never = Niekada
ui-connect-agent = Prijungti DI agentą
ui-connect-agent-intro = Įtraukite šias eilutes į agento MCP serverių nustatymus (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Programa
ui-col-may = Teisės
ui-col-last-used = Paskutinį kartą naudota
ui-col-when = Kada
ui-col-what = Veiksmas
ui-sign-in-app = Prisijungimo programa
ui-sign-in-apps = Prisijungimo programos
ui-add-sign-in-app-title = Pridėti prisijungimo programą
ui-preset-app-name = Prisijungimo programa: { $provider }
ui-issuer-not-checked = išdavėjo patikrinti negalima
ui-checking-issuer = Tikrinamas išdavėjas: { $issuer }...
ui-issuer-unusable = Išdavėjo naudoti negalima: { $reason }
ui-issuer-usable = Išdavėją galima naudoti.
ui-sign-in-app-not-saved = Prisijungimo programos įrašyti nepavyko: { $reason }
ui-check = &Tikrinti
ui-fill-in-for = Naudoti nustatymus:
ui-app-name = Pavadinimas:
ui-issuer = Išdavėjas:
ui-client-id = Kliento ID:
ui-client-secret = Kliento paslaptis:
ui-scopes = Teisės (scopes):
ui-imap-server = IMAP serveris:
ui-smtp-server = SMTP serveris:
ui-redirect-uri = Peradresavimo URI:
ui-sign-in-app-intro = Prisijungimo programa yra OAuth klientas, kurį užregistruojate pas savo paslaugų teikėją, kad galėtumėte prisijungti per naršyklę. Pasirinkite paslaugų teikėją, kad būtų užpildyti jo nustatymai, tada įveskite kliento ID ir kliento paslaptį, jei paslaugų teikėjas ją pateikė.
ui-remove-secret = Kliento paslaptis įrašyta. Įveskite naują, kad ją pakeistumėte, arba pašalinkite įrašytą paslaptį
ui-register-it = Užregistruokite programą pas savo paslaugų teikėją
ui-built-in-note = Programa { $name } yra įtaisyta į Inbox Classic. Galite pasirinkti tik tai, ar ji siūloma naujoms paskyroms.
ui-client-with-secret = Kliento ID: { $client }. Kliento paslaptis įrašyta.
ui-client-public = Viešasis klientas be paslapties. Kliento ID: { $client }.
ui-no-accounts = Paskyrų nėra
ui-remove-sign-in-app = Pašalinti prisijungimo programą
ui-remove-sign-in-app-ask = Pašalinti prisijungimo programą { $name } ir jos įrašytą kliento paslaptį?
ui-sign-in-app-not-removed = Prisijungimo programa nepašalinta. { $reason }
ui-sign-in-apps-intro = Prisijungimo programos leidžia paskyroms prisijungti per naršyklę. Nepažymėta programa naujoms paskyroms nesiūloma; ją jau naudojančios paskyros veikia toliau.
ui-col-issuer = Išdavėjas
ui-col-used-by = Naudoja
ui-options-system-default = Sistemos kalba ({ $language })
ui-settings-general = Bendra
ui-settings-reading = Skaitymas
ui-settings-new-mail = Nauji laiškai
ui-settings-sending = Siuntimas
ui-settings-default-apps = Numatytosios programos
ui-settings-message-list = Laiškų sąrašas
ui-settings-messages = Laiškai
ui-settings-encryption = Šifravimas
ui-settings-language = Kalba
ui-settings-label = { $label }:
ui-apply = &Taikyti
ui-language-label = &Kalba:
ui-restart-note = Paleiskite Inbox Classic iš naujo, kad pasikeistų kalba.
ui-restart-ask = Pasirinkta kalba: { $language }. Ji įsigalios paleidus Inbox Classic iš naujo. Paleisti iš naujo dabar?
ui-notify-new-mail = &Pranešti, kai gaunami nauji laiškai
ui-new-folder-title = Naujas aplankas
ui-rename-folder-title = Pervardyti aplanką
ui-delete-folder-question = Panaikinti aplanką „{ $folder }“ su jo laiškais ir jame esančiais aplankais? Jis bus panaikintas ir serveryje.
ui-properties = &Ypatybės
ui-account-sync = Siųsti ir &gauti
ui-account-properties = &Ypatybės...
ui-account-move-up = Perkelti &aukštyn
ui-account-move-down = Perkelti ž&emyn
ui-menu-open = Ati&daryti
ui-menu-flag = V&ėliavėlė
ui-menu-view-source = Rodyti &šaltinį
ui-save-attachments = Įrašyti priedus
ui-attachment-open = Atidaryti
ui-attachment-save-as = Įrašyti kaip...
ui-attachment-save-all = Įrašyti visus...
ui-attachment-show-in-message = Rodyti laiške
ui-attachments-strip = Priedai
ui-attachment-note-title = Šio failo atidarymas
ui-attachment-program-tip = Šio tipo failų atidarymas čia išjungtas, nes jie gali paleisti programas. Jei norite atidaryti failą patys, pirmiausia jį įrašykite.
ui-clear-flag = &Nuimti vėliavėlę
ui-button-move = &Perkelti
ui-button-copy = &Kopijuoti
ui-find-folder = Ieškoti aplanko
ui-new-folder-in = Naujas aplankas bus sukurtas aplanke „{ $folder }“.
ui-outbox-send-all = &Siųsti visus dabar
ui-yes = Taip
ui-no = Ne
ui-try-again = Bandyti dar kartą
ui-remove = Pa&šalinti
ui-signature-of = Parašo tekstas: { $account }
ui-sign-in-with = Prisijungti naudojant { $provider }
ui-sign-in-in-browser-yours = Prisijunkite prie savo paskyros atsidariusiame naršyklės lange, tada grįžkite čia.
ui-browser-sign-in-server = { $server } (prisijungimas naršyklėje)
ui-dont-allow = Neleisti
ui-allow = &Leisti
ui-dont-send = Nesiųsti
ui-dont-unsubscribe = Neatsisakyti prenumeratos
ui-edit-first = &Pirmiausia redaguoti
ui-new-address = Naujas adresas
ui-turn-away = &Atmesti
ui-clear-agent-log = Išvalyti agentų veiklos istoriją?
ui-clear-agent-log-detail = Agentų atlikti pakeitimai nebus atšaukti.
ui-let-agents-connect = &Leisti DI agentams jungtis prie Inbox Classic
ui-change-button = Keisti…
ui-undo-button = Atšaukti
ui-rules-title = Laiškų taisyklės
ui-rules-intro = Kol Inbox Classic veikia, taisyklės taikomos naujiems laiškams aplanke „Gauti laiškai“. Laišką atitinkančios taisyklės vykdomos iš eilės. Jei taisyklė perkelia laišką iš šio aplanko, kitos taisyklės jam nebetaikomos.
ui-rules-none = Taisyklių dar nėra. Norėdami sukurti taisyklę, spustelėkite mygtuką „Nauja“.
ui-rule-new = &Nauja...
ui-rule-edit = &Keisti...
ui-rule-delete-button = &Panaikinti
ui-rule-title = Laiškų taisyklė
ui-rule-name = Pavadinimas:
ui-rule-account = Paskyra:
ui-rule-all-accounts = Visos paskyros
ui-rule-query = Paieškos kriterijai:
ui-rule-query-hint = Naudokite paieškos žodžius, pavyzdžiui, from:ann@example.com, subject:sąskaita arba list:news.example.com, kaip ir paieškos laukelyje.
ui-rule-count = { $count ->
    [one] Šiuos kriterijus dabar atitinka { $count } laiškas aplanke „Gauti laiškai“.
    [few] Šiuos kriterijus dabar atitinka { $count } laiškai aplanke „Gauti laiškai“.
   *[other] Šiuos kriterijus dabar atitinka { $count } laiškų aplanke „Gauti laiškai“.
}
ui-rule-show = &Rodyti
ui-rule-actions = Veiksmai:
ui-rule-move = &Perkelti į:
ui-rule-mark-read = Žymėti kaip &skaitytą
ui-rule-flag = Žymėti &vėliavėle
ui-rule-archive = &Archyvuoti
ui-rule-junk = Perkelti į aplanką „&Nepageidaujami laiškai“
ui-rule-delete = Panaikin&ti
ui-rule-quiet = Nepranešti &man apie jį
ui-rule-apply-now = Taip pat taikyti laiškams, jau esantiems aplanke „&Gauti laiškai“
ui-rule-delete-ask = Panaikinti taisyklę „{ $name }“?
ui-create-rule = Kurti taisyklę...
ui-rules-applied = { $count ->
    [one] Jūsų taisyklės surūšiavo { $count } laišką
    [few] Jūsų taisyklės surūšiavo { $count } laiškus
   *[other] Jūsų taisyklės surūšiavo { $count } laiškų
}
ui-col-rule-matches = Kriterijai
ui-clear-button = &Išvalyti
# review: new
ui-how-to-connect = Kaip prijungti agentą…
# review: new
ui-agent-programs = Programos, kurių agentai paprašė prieigos prie jūsų pašto
# review: new
ui-what-agents-did = Agentų veikla
# review: new
ui-restart-now = &Paleisti iš naujo dabar
# review: new
ui-restart-later = &Vėliau

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

# review: new
ui-tb-new-contact = Naujas kontaktas
# review: new
ui-tb-new-group = Nauja grupė
# review: new
ui-tb-properties = Ypatybės
# review: new
ui-tb-write-to = Rašyti
# review: new
ui-menu-new-contact = Naujas &kontaktas...
# review: new
ui-menu-new-group = Nauja &grupė...
# review: new
ui-menu-write-to = &Rašyti
# review: new
ui-menu-delete = &Panaikinti
# review: new
ui-book-find-hint = Įveskite vardą arba el. pašto adresą
# review: new
ui-book-all-contacts = Visi kontaktai
# review: new
ui-col-phone = Telefonas
# review: new
ui-book-empty = Adresų knygelė tuščia. Spustelėkite „Naujas kontaktas“, kad ką nors pridėtumėte, arba importuokite vCard ar CSV failą per meniu „Failas“.
# review: new
ui-book-no-match = Nėra kontaktų, atitinkančių „{ $words }“.
# review: new
ui-book-delete-ask = { $count ->
    [one] Panaikinti šį kontaktą iš adresų knygelės?
   *[other] Panaikinti šiuos kontaktus ({ $count }) iš adresų knygelės?
}
# review: new
ui-group-delete-ask = Panaikinti grupę „{ $name }“? Jos nariai lieka adresų knygelėje.
# review: new
ui-book-no-address = { $name } neturi el. pašto adreso.
# review: new
ui-new-contact-title = Naujas kontaktas
# review: new
ui-contact-title = Ypatybės: { $name }
# review: new
ui-contact-first = Vardas:
# review: new
ui-contact-last = Pavardė:
# review: new
ui-contact-display = Rodomas vardas:
# review: new
ui-contact-nickname = Slapyvardis:
# review: new
ui-contact-company = Įmonė:
# review: new
ui-contact-addresses = El. pašto adresai:
# review: new
ui-contact-address-hint = Įveskite el. pašto adresą
# review: new
ui-contact-add = &Pridėti
# review: new
ui-contact-set-default = Nustatyti kaip &numatytąjį
# review: new
ui-contact-default = { $address } (numatytasis)
# review: new
ui-contact-phones = Telefono numeriai:
# review: new
ui-phone-home = Namų
# review: new
ui-phone-work = Darbo
# review: new
ui-phone-mobile = Mobilusis
# review: new
ui-phone-other = Kitas
# review: new
ui-contact-notes = Pastabos:
# review: new
ui-contact-name-needed = Įveskite kontakto vardą arba el. pašto adresą.
# review: new
ui-contact-address-invalid = „{ $address }“ nėra tinkamas el. pašto adresas.
# review: new
ui-contact-not-saved = Kontakto įrašyti nepavyko: { $reason }
# review: new
ui-new-group-title = Nauja grupė
# review: new
ui-group-title = Ypatybės: { $name }
# review: new
ui-group-name = Grupės pavadinimas:
# review: new
ui-group-members = Nariai:
# review: new
ui-group-select-members = Pa&sirinkti narius...
# review: new
ui-group-new-member = Pridėti el. pašto adresą, kurio nėra adresų knygelėje:
# review: new
ui-group-name-needed = Įveskite grupės pavadinimą.
# review: new
ui-group-not-saved = Grupės įrašyti nepavyko: { $reason }
# review: new
ui-group-members-count = { $count ->
    [one] { $count } narys
    [few] { $count } nariai
   *[other] { $count } narių
}
# review: new
ui-select-recipients = Pasirinkti gavėjus
# review: new
ui-select-members = Pasirinkti grupės narius
# review: new
ui-pick-intro = Įveskite vardą arba pasirinkite jį iš sąrašo:
# review: new
ui-pick-recipients = Laiško gavėjai:
# review: new
ui-pick-members = Grupės nariai:
# review: new
ui-pick-to = &Kam →
# review: new
ui-pick-cc = K&opija →
# review: new
ui-pick-bcc = &Slapta kopija →
# review: new
ui-pick-add = &Pridėti →
# review: new
ui-pick-tip = Pasirinkti gavėjus iš adresų knygelės
# review: new
ui-filter-address-books = Adresų knygelės (vCard, CSV)
# review: new
ui-filter-vcard = vCard failai
# review: new
ui-book-export-name = Adresų knygelė
# review: new
ui-book-imported = { $added ->
    [one] Pridėtas { $added } kontaktas
    [few] Pridėti { $added } kontaktai
   *[other] Pridėta kontaktų: { $added }
}, { $skipped ->
    [one] praleistas { $skipped }, jau esantis adresų knygelėje.
    [few] praleisti { $skipped }, jau esantys adresų knygelėje.
   *[other] praleista jau esančių adresų knygelėje: { $skipped }.
}
# review: new
ui-book-not-imported = Adresų knygelės importuoti nepavyko: { $reason }
# review: new
ui-book-exported = { $count ->
    [one] { $count } kontaktas įrašytas į { $file }.
    [few] { $count } kontaktai įrašyti į { $file }.
   *[other] Į { $file } įrašyta kontaktų: { $count }.
}
# review: new
ui-book-not-exported = Adresų knygelės įrašyti nepavyko: { $reason }
# review: new
ui-code-copied = Kodas nukopijuotas
# review: changed
ui-codes-in-notifications = &Rodyti prisijungimo kodus pranešimuose apie naujus laiškus
# review: new
ui-tool-unread-only = Neskaityti
# review: new
ui-no-unread = Čia neskaitytų laiškų nėra.
# review: new
ui-pictures-always-sender = Visada atsisiųsti paveikslėlius iš { $sender }
# review: new
ui-pictures-always-domain = Visada atsisiųsti paveikslėlius iš visų { $domain } siuntėjų
# review: new
ui-pictures-unconfirmed = Siuntėjo domeno ({ $domain }) patvirtinti nepavyko, todėl šio laiško paveikslėliai automatiškai neatsisiunčiami.
# review: changed
ui-pictures-always-option = &Atsisiųsti paveikslėlius visuose laiškuose
# review: new
ui-pictures-always-warning = Tada siuntėjai galės matyti, kada skaitote jų laiškus.
# review: new
ui-protection-details = &Išsamiau...
# review: new
ui-protection-details-title = Saugos informacija
# review: new
ui-download-heading = Atsisiuntimas
# review: changed
ui-download-ahead = &Atsisiųsti laiškus iš anksto:
# review: new
ui-download-ahead-recent = Naujausius laiškus, kurių kiekvienas iki 1 MB
# review: new
ui-download-ahead-all = Visus laiškus
# review: new
ui-download-ahead-never = Tik atidarant
# review: changed
ui-download-limit = &Saugyklos riba kiekvienai paskyrai:
# review: changed
ui-send-delay = &Delsa prieš siunčiant:
# review: new
ui-send-delay-note = Kol laiškas laukia išsiuntimo, siuntimą galite atšaukti komanda „Atšaukti“.
# review: new
ui-dark-messages = Rodyti laiškus tamsiame fone, kai sistemoje įjungtas tamsusis režimas
# review: new
ui-preview-show = Rodyti prie&dus laiškuose
# review: new
ui-preview-show-note = Po laiško tekstu rodo paveikslėlius ir pirmuosius PDF failų puslapius. Šias peržiūras Inbox Classic sukuria pati, todėl niekas faile negali būti paleista.
# review: new
ui-preview-pdfs = Rodyti PDF &failus laiškuose
# review: new
ui-sending-in = { $subject } bus išsiųstas po { $count ->
    [one] { $count } sekundės
   *[other] { $count } sekundžių
}
# review: new
ui-send-undone = { $subject } neišsiųstas. Laiškas vėl atidarytas redaguoti.
# review: new
ui-send-too-late = { $subject } jau išsiųstas.
# review: new
ui-outbox-status-undo = Bus išsiųsta { $time }
# review: new
ui-download-note = Iš anksto atsisiųsti laiškai atsidaro iš karto. Viršijus saugyklos ribą, seniausios vietinės kopijos pašalinamos ir vėl atsisiunčiamos, kai jas atidarote.
# review: new
ui-attachment-downloading = Šis laiškas dar neatsisiųstas iki galo. Bandykite dar kartą, kai atsisiuntimas baigsis.
# review: changed
ui-trusted-senders-button = &Patikimi siuntėjai...
# review: new
ui-trusted-senders-title = Patikimi siuntėjai
# review: new
ui-trusted-senders-note = Šių siuntėjų laiškų paveikslėliai atsisiunčiami automatiškai, kai jūsų pašto paslaugų teikėjas patvirtina siuntėjo domeną.
# review: new
ui-trusted-everyone-at = Visi iš { $domain }
# review: new
ui-trusted-senders-empty = Patikimų siuntėjų dar nepridėta.
# review: new
ui-search-encrypted = Ieškoti &užšifruotuose laiškuose
# review: new
ui-search-encrypted-note = Užšifruoti laiškai šiame kompiuteryje iššifruojami juos atsisiuntus ar atidarius, kad būtų galima rasti jų žodžius, o sąraše būtų rodoma jų tikroji tema. Indeksas nėra šifruotas, o DI agentai jame niekada neieško. Išjunkite, kad jie būtų pašalinti iš indekso.
# review: new
ui-pgp-keyserver = I&eškoti raktų keys.openpgp.org
# review: new
ui-pgp-keyserver-note = Kai šifruojate laišką arba ieškote rakto, ieškomas adresas siunčiamas į keys.openpgp.org. Pirmiausia klausiama paties adreso domeno.
# review: changed
ui-eml-default = &Atidaryti .eml failus su Inbox Classic
# review: new
ui-eml-default-done = Dabar .eml failus atidaro Inbox Classic.
# review: new
ui-eml-default-failed = Nepavyko nustatyti Inbox Classic kaip numatytosios .eml failų programos: { $reason }
# review: new
ui-folders = Aplankai
# review: new
ui-sorted-by = Rikiuota pagal: { $field }
# review: changed
ui-layout-label = &Išdėstymas:
# review: new
ui-columns-note = Langas pakankamai platus stulpelių išdėstymui. Išdėstymą galite pakeisti per Rodinys > Išdėstymas.
# review: new
ui-row-unread = Neskaitytas
# review: new
ui-row-flagged = Su vėliavėle
# review: new
ui-row-attachments = Yra priedų
# review: new
ui-row-encrypted = Užšifruotas
# review: new
ui-row-signed = Pasirašytas
# review: new
ui-row-messages = { $count ->
    [one] { $count } laiškas
    [few] { $count } laiškai
   *[other] { $count } laiškų
}
# review: changed
ui-list-pictures = &Rodyti siuntėjų paveikslėlius laiškų sąraše
# review: changed
ui-list-pictures-note = Patvirtintiems siuntėjams rodomi prekių ženklų logotipai arba adresų knygelės paveikslėliai, o kai paveikslėlio nėra, inicialai. Logotipai atsisiunčiami vieną kartą kiekvienam prekės ženklui, o ne kiekvienam laiškui.
# review: new
ui-card-picture = Paveikslėlis:
# review: new
ui-card-picture-choose = Pa&sirinkti...
# review: new
ui-picture-not-picture = Šis failas nėra PNG ar JPEG paveikslėlis.
# review: new
ui-picture-too-large = Šis paveikslėlis per didelis. Pasirinkite ne didesnį nei 10 MB, kurio plotis ir aukštis ne didesni nei 8000 taškų.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
# review: new
ui-keys-title = Šifravimo raktai
# review: new
ui-keys-intro = Jūsų raktai pasirašo jūsų laiškus ir atveria jums užšifruotus laiškus. Kontaktų raktai tikrina jų parašus ir šifruoja jiems siunčiamus laiškus.
# review: new
ui-keys-empty = Raktų dar nėra. Spustelėkite „Naujas raktas“, kad sukurtumėte savo raktą, arba „Importuoti“, kad pridėtumėte jau turimą raktą.
# review: new
ui-keys-col-name = Vardas
# review: new
ui-keys-col-address = Adresas
# review: new
ui-keys-col-kind = Rūšis
# review: new
ui-keys-col-status = Būsena
# review: new
ui-keys-kind-own = Jūsų raktas
# review: new
ui-keys-kind-contact = Kontaktas
# review: new
ui-keys-status-verified = { $status }, patikrintas
# review: new
ui-keys-new = &Naujas raktas...
# review: new
ui-keys-import = &Importuoti...
# review: new
ui-keys-export = &Eksportuoti...
# review: new
ui-keys-backup = &Atsarginė kopija...
# review: new
ui-keys-verify = Pa&tikrinti...
# review: new
ui-keys-new-title = Naujas raktas
# review: new
ui-keys-new-for = Sukurti raktą:
# review: new
ui-keys-new-make = &Sukurti raktą
# review: new
ui-keys-no-account = Pirmiausia pridėkite pašto paskyrą: raktas kuriamas paskyros adresams.
# review: new
ui-keys-memory-only = Slaptažodžiai laikomi tik atmintyje, todėl dabar sukurto ar importuoto privačiojo rakto nebus galima naudoti uždarius Inbox Classic.
# review: new
ui-keys-backup-offer = Jūsų naujas raktas paruoštas. Įrašyti jo atsarginę kopiją dabar? Jei šis kompiuteris bus prarastas ar atkurtas, raktą bus galima susigrąžinti tik iš atsarginės kopijos.
# review: new
ui-keys-backup-now = Į&rašyti atsarginę kopiją...
# review: new
ui-keys-later = &Vėliau
# review: new
ui-keys-backup-title = Rakto atsarginė kopija
# review: new
ui-keys-backup-intro = Atsarginė kopija apsaugota slaptafraze. Laikykite failą ir slaptafrazę skirtingose saugiose vietose: raktui susigrąžinti reikės abiejų.
# review: new
ui-keys-passphrase = &Slaptafrazė:
# review: new
ui-keys-passphrase-again = Įveskite &dar kartą:
# review: new
ui-keys-passphrase-differ = Slaptafrazės nesutampa.
# review: new
ui-keys-passphrase-short = Naudokite bent 8 simbolių slaptafrazę.
# review: new
ui-keys-backup-saved = Atsarginė kopija įrašyta.
# review: new
ui-keys-import-title = Importuoti raktą
# review: new
ui-keys-import-passphrase = Šis privatusis raktas apsaugotas slaptafraze. Įveskite ją, kad importuotumėte raktą:
# review: new
ui-keys-file-filter = OpenPGP raktai
# review: new
ui-keys-use-for = Naudoti šį raktą adresams { $addresses }? Jūsų laiškai iš jų bus juo pasirašomi, o šiuo raktu užšifruotus laiškus bus galima skaityti čia.
# review: new
ui-keys-use = &Naudoti
# review: new
ui-keys-not-now = Ne &dabar
# review: new
ui-keys-remove-own = Pašalinti savo raktą { $fingerprint }? Juo užšifruotų laiškų čia nebebus galima skaityti, nebent vėl importuosite jo atsarginę kopiją.
# review: new
ui-keys-remove-contact = Pašalinti kontakto { $name } raktą? Jo parašų nebus galima patikrinti ir jam siunčiamų laiškų užšifruoti, kol vėl pridėsite jo raktą.
# review: new
ui-key-properties-title = Rakto ypatybės
# review: new
ui-key-names = Vardai:
# review: new
ui-key-fingerprint = Kontrolinis kodas:
# review: new
ui-key-status = Būsena:
# review: new
ui-key-created = Sukurtas:
# review: new
ui-key-expires = Galioja iki:
# review: new
ui-key-never = Neribotai
# review: new
ui-key-algorithm = Algoritmas:
# review: new
ui-key-source = Šaltinis:
# review: new
ui-key-addresses = Adresai:
# review: new
ui-key-address-verified = { $address } (patikrintas)
# review: new
ui-key-address-not-verified = { $address } (nepatikrintas)
# review: new
ui-verify-title = Patikrinti raktą
# review: new
ui-verify-intro = Paprašykite, kad { $name } perskaitytų jums savo rakto kontrolinį kodą iš savo programos, susitikus asmeniškai arba skambučio metu. Nelyginkite jo su atsiųstu el. paštu: kas galėjo pakeisti raktą, galėjo pakeisti ir jį.
# review: new
ui-verify-fingerprint = Jūsų turimo rakto kontrolinis kodas:
# review: new
ui-verify-marks = { $count ->
    [one] Jei jie sutampa, raktas pažymimas kaip šio žmogaus raktas adresui { $addresses }. Jei tas adresas ne jo, spustelėkite „Nesutampa“.
   *[other] Jei jie sutampa, raktas pažymimas kaip šio žmogaus raktas adresams { $addresses }. Jei kuris nors iš šių adresų ne jo, spustelėkite „Nesutampa“.
}
# review: new
ui-verify-match = &Sutampa
# review: new
ui-verify-differ = &Nesutampa
# review: new
ui-verify-differs = Jūsų turimas raktas nėra tas, kurį turi { $name }. Pašalinkite jį ir dar kartą paprašykite rakto.
# review: new
ui-verify-unmark = Žymėti kaip nepa&tikrintą
# review: new
ui-account-security = Sauga
# review: new
ui-account-security-intro = Turint raktą, jūsų laiškus galima pasirašyti, o žmonės gali siųsti jums užšifruotus laiškus.
# review: new
ui-account-key = Šios paskyros &raktas:
# review: new
ui-account-key-none = Nėra
# review: new
ui-account-key-new = &Naujas raktas...
# review: new
ui-account-autocrypt = &Siųsti savo viešąjį raktą su laiškais (Autocrypt)
# review: new
ui-contact-key = Šifravimo raktas:
# review: new
ui-contact-key-none = Rakto nėra
# review: new
ui-contact-key-use-new = Naudoti &naująjį raktą
# review: new
ui-contact-key-keep = &Palikti dabartinį
ui-recipient-keys-title = Gavėjų raktai
ui-recipient-col-recipient = Gavėjas
ui-recipient-col-key = Raktas
ui-recipient-find-key = &Rasti raktą
ui-recipient-remove = Pašalinti iš &laiško
ui-send-unencrypted = Siųsti neši&fruotą
ui-compose-make-key = &Sukurti raktą...
ui-compose-show-keys = Šifravimo ra&ktai...
ui-compose-encrypt-off = &Išjungti šifravimą
ui-compose-keep-encrypted = &Palikti šifravimą
# review: new
ui-setup-export-title = Eksportuoti nustatymus ir paskyras
# review: new
ui-setup-import-title = Importuoti nustatymus ir paskyras
# review: new
ui-setup-export-intro = Pasirinkite, ką perkelti į kitą kompiuterį. Faile laiškų nėra: ten jie bus atsisiųsti iš naujo.
# review: new
ui-setup-use-passphrase = &Apsaugoti failą slaptafraze
# review: new
ui-setup-passphrase-note = Su slaptafraze failas užšifruojamas ir jame taip pat saugomi jūsų slaptažodžiai, prisijungimai ir privatieji raktai. Be jos kiekviena paskyra kitame kompiuteryje paprašys slaptažodžio.
# review: new
ui-setup-export-button = &Eksportuoti...
# review: new
ui-setup-file-filter = Inbox Classic nustatymai ir paskyros
# review: new
ui-setup-ask-passphrase = Šis failas apsaugotas slaptafraze. Įveskite ją, kad pamatytumėte, kas yra faile:
# review: new
ui-setup-import-intro = Pasirinkite, ką importuoti. Šiame kompiuteryje jau esančios paskyros paliekamos tokios, kokios yra.
# review: new
ui-setup-from = Įrašė Inbox Classic { $version }, { $date }.
# review: new
ui-setup-import-button = &Importuoti
# review: new
ui-setup-done = Atlikta
# review: new
ui-setup-first-run = Importuoti nustatymus ir paskyras iš kito kompiuterio...
