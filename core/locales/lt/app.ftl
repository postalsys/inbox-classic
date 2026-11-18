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
# review: new
ui-unsubscribe = Atsisakyti prenumeratos
# review: new
ui-open-in-calendar = Atidaryti kalendoriuje
# review: new
ui-pictures-blocked = Kai kurie paveikslėliai užblokuoti, kad siuntėjas negalėtų atpažinti jūsų kompiuterio. Spustelėkite čia, kad atsisiųstumėte paveikslėlius.
# review: new
ui-not-shown = Laiško parodyti nepavyko.
# review: new
ui-attachment-not-read = Priedo perskaityti nepavyko.
# review: new
ui-attachment-not-saved = Priedo įrašyti nepavyko.
# review: new
ui-not-downloaded = Laiškas dar neatsisiųstas.
# review: new
ui-leave-list = Išeiti iš šio adresatų sąrašo?
# review: new
ui-leave-one-click = Inbox Classic išsiųs prenumeratos atsisakymo užklausą adresu { $target }. Joks tinklalapis nebus atidarytas ir joks el. laiškas nebus išsiųstas.
# review: new
ui-leave-mail = Norėdami atsisakyti prenumeratos, išsiųskite el. laišką adresu { $target }. Inbox Classic jį jums paruoš. Išsiųskite laišką, kad patvirtintumėte.
# review: new
ui-leave-web = Adresatų sąrašo prenumeratos atsisakymo puslapis bus atidarytas jūsų naršyklėje ({ $target }).
# review: new
ui-unsubscribing = Atsisakoma prenumeratos: { $target }...
# review: new
ui-cannot-unsubscribe = Šiame laiške nėra galimybės atsisakyti prenumeratos.
# review: new
ui-unsubscribed = Prenumeratos atsisakymo užklausa priimta. Adresatų sąrašas praneša, kad nebesiųs šių laiškų.
# review: new
ui-not-unsubscribed = Nepavyko atsisakyti prenumeratos: { $reason }
# review: new
ui-event-span = { $start } iki { $end }
# review: new
ui-event-floating = { $when } (siuntėjo laikas)
# review: new
ui-invitation = Kvietimas: { $title }
# review: new
ui-invitation-updated = Atnaujintas kvietimas: { $title }
# review: new
ui-invitation-canceled = Atšaukta: { $title }
# review: new
ui-invitation-answer = Atsakymas į kvietimą: { $title }
# review: new
ui-no-title = (be pavadinimo)
# review: new
ui-organizer = Organizatorius: { $name }
# review: new
ui-invitation-not-read = Kvietimo perskaityti nepavyko.
# review: new
ui-no-calendar = Šiame kompiuteryje nėra kalendoriaus programos, kuri atidarytų kvietimus (.ics failus).
# review: new
ui-messages-not-changed = Laiškų pakeisti nepavyko.
# review: new
ui-new-folder-in-selected = Naujas aplankas bus sukurtas pažymėtame aplanke.
# review: new
ui-new-folder-at-top = Naujas aplankas bus sukurtas paskyros viršutiniame lygmenyje.
# review: new
ui-folder-not-created = Aplanko sukurti nepavyko.
# review: new
ui-folder-not-renamed = Aplanko pervardyti nepavyko.
# review: new
ui-folder-not-deleted = Aplanko panaikinti nepavyko.
# review: new
ui-rename-folder-intro = Įveskite naują aplanko „{ $folder }“ pavadinimą.
# review: new
ui-properties-of = Ypatybės: { $subject }
# review: new
ui-internet-headers = Šio laiško interneto antraštės:
# review: new
ui-save-messages-in = Įrašyti laiškus į
# review: new
ui-save-message-as = Įrašyti laišką kaip
# review: new
ui-import-choose-folder = Pirmiausia pasirinkite aplanką, į kurį importuoti laiškus.
# review: new
ui-add-account-title = Pridėti pašto paskyrą
# review: new
ui-accounts-title = Paskyros
# review: new
ui-security-none = Nėra (nešifruota)
# review: new
ui-field-required = Laukas „{ $field }“ privalomas.
# review: new
ui-email-invalid = El. pašto adresas netinkamas.
# review: new
ui-ports-invalid = Prievadai yra skaičiai nuo 1 iki 65535.
# review: new
ui-looking-up = Ieškoma domeno { $domain } nustatymų...
# review: new
ui-found-none = Įveskite paskyros duomenis, kuriuos pateikė jūsų el. pašto paslaugų teikėjas.
# review: new
ui-found-change = Pakeiskite šiuos nustatymus, jei paslaugų teikėjas pateikė kitokius.
# review: new
ui-found-guess = Šiam adresui nustatymų nerasta. Siūlomi serverių vardai tik spėjami. Pasitikrinkite juos pas savo paslaugų teikėją.
# review: new
ui-found-mx = Inbox Classic atpažino jūsų el. pašto paslaugų teikėją ir užpildė jo serverių nustatymus.
# review: new
ui-found-srv = Šie nustatymai rasti jūsų domeno DNS įrašuose.
# review: new
ui-found-autodiscover = Šiuos nustatymus rado Microsoft Autodiscover (Exchange).
# review: new
ui-found-other = Šiam adresui rasti šie nustatymai.
# review: new
ui-app-password-needed = { $provider } pašto programose nepriima jūsų įprasto slaptažodžio. Sukurkite programos slaptažodį savo { $provider } paskyroje ir įveskite jį kitos formos lauke „Slaptažodis“.
# review: new
ui-app-password-open = Atidaryti { $provider } instrukcijas naršyklėje?
# review: new
ui-plain-warning = Be šifravimo bet kas, perimantis jūsų tinklo srautą, gali perskaityti jūsų slaptažodį ir laiškus. Naudokite šį ryšį tik su serveriu, esančiu jūsų kompiuteryje arba vietiniame tinkle.
# review: new
ui-continue-ask = Tęsti?
# review: new
ui-add-sign-in-app = Pridėti prisijungimo programą...
# review: new
ui-turned-off = { $name } šiame kompiuteryje išjungta.
# review: new
ui-off-here = Šiame kompiuteryje išjungta.
# review: new
ui-why = Kodėl?
# review: new
ui-more-sign-in = Daugiau prisijungimo būdų...
# review: new
ui-other-account = Norėdami pridėti kitą el. pašto paskyrą, įveskite savo el. pašto adresą ir vardą, kurį turi matyti gavėjai. Tada bus ieškoma serverio nustatymų.
# review: new
ui-field-account-name = Paskyros pavadinimas:
# review: new
ui-field-name = Rodomas vardas:
# review: new
ui-field-email = El. pašto adresas:
# review: new
ui-field-user = Naudotojo vardas:
# review: new
ui-field-password = Slaptažodis:
# review: new
ui-field-imap-host = Gaunamųjų laiškų (IMAP) serveris:
# review: new
ui-field-imap-port = IMAP prievadas:
# review: new
ui-field-imap-security = IMAP sauga:
# review: new
ui-field-smtp-host = Siunčiamųjų laiškų (SMTP) serveris:
# review: new
ui-field-smtp-port = SMTP prievadas:
# review: new
ui-field-smtp-security = SMTP sauga:
# review: new
ui-field-other-addresses = Kiti adresai, iš kurių siunčiate:
# review: new
ui-sign-in-not-started = Nepavyko pradėti prisijungimo per naršyklę.
# review: new
ui-sign-in-in-browser = Prisijunkite prie paskyros { $account } atsidariusiame naršyklės lange, tada grįžkite čia.
# review: new
ui-sign-in-failed = Nepavyko prisijungti: { $reason }
# review: new
ui-account-not-saved = Paskyros įrašyti nepavyko.
# review: new
ui-start-intro = Gmail, Google Workspace, Outlook.com ir Microsoft 365: prisijunkite pačios Google ar Microsoft puslapyje. Slaptažodį įvedate ten, o ne Inbox Classic.
# review: new
ui-start-intro-apps = Prisijunkite per naršyklę viena iš savo prisijungimo programų (Daugiau prisijungimo būdų) arba toliau pridėkite bet kurią el. pašto paskyrą, nurodę savo vardą ir adresą.
# review: new
ui-use-app-password = Naudoti programos slaptažodį
# review: new
ui-the-provider = paslaugų teikėjas
# review: new
ui-provider-intro = Prisijunkite prie { $email } svetainėje, kurią valdo { $provider }. Jūsų slaptažodis Inbox Classic neperduodamas. Taip pat galite naudoti programos slaptažodį, sukurtą paskyros saugos nustatymuose.
# review: new
ui-provider-intro-apps = Prisijunkite prie { $email } svetainėje, kurią valdo { $provider }, naudodami vieną iš savo prisijungimo programų (Daugiau prisijungimo būdų). Taip pat galite naudoti programos slaptažodį, sukurtą paskyros saugos nustatymuose.
# review: new
ui-finish = Baigti
# review: new
ui-logon = Prisijungimas
# review: new
ui-enter-password = Įveskite paskyros { $account } slaptažodį.
# review: new
ui-signs-in-with = Prisijungimo programa: { $app }. Prisijungiama naršyklėje, o paskyra naudoja šios programos serverius.
# review: new
ui-keep-password = Palikite slaptažodžio lauką tuščią, jei norite išsaugoti dabartinį slaptažodį.
# review: new
ui-remove-account = Pašalinti paskyrą
# review: new
ui-remove-account-ask = Pašalinti šią paskyrą iš Inbox Classic? Jos laiškai lieka serveryje; kopija šiame kompiuteryje ir įrašytas slaptažodis pašalinami.
# review: new
ui-col-email = El. pašto adresas
# review: new
ui-col-incoming = Gaunamųjų laiškų serveris
# review: new
ui-type-email = Įveskite savo el. pašto adresą, vardas@example.com.
# review: new
ui-ai-agent = DI agentas
# review: new
ui-ai-agent-access = DI agento prieiga
# review: new
ui-ai-agents = DI agentai
# review: new
ui-program-path = Programa: { $path }
# review: new
ui-it-may = Leidžiami veiksmai:
# review: new
ui-accounts-it-may-use = Leidžiamos paskyros:
# review: new
ui-send-message-ask = Siųsti laišką?
# review: new
ui-col-name = Pavadinimas
# review: new
ui-never = Niekada
# review: new
ui-connect-agent = Prijungti DI agentą
# review: new
ui-connect-agent-intro = Įtraukite tai į savo agento MCP serverius (Claude Desktop: Settings > Developer > Edit Config):
# review: new
ui-col-program = Programa
# review: new
ui-col-may = Teisės
# review: new
ui-col-last-used = Paskutinį kartą naudota
# review: new
ui-col-when = Kada
# review: new
ui-col-what = Veiksmas
# review: new
ui-sign-in-app = Prisijungimo programa
# review: new
ui-sign-in-apps = Prisijungimo programos
# review: new
ui-add-sign-in-app-title = Pridėti prisijungimo programą
# review: new
ui-preset-app-name = { $provider } prisijungimo programa
# review: new
ui-issuer-not-checked = išdavėjo patikrinti negalima
# review: new
ui-checking-issuer = Tikrinamas { $issuer }...
# review: new
ui-issuer-unusable = Išdavėjo naudoti negalima: { $reason }
# review: new
ui-issuer-usable = Išdavėją galima naudoti.
# review: new
ui-sign-in-app-not-saved = Prisijungimo programos įrašyti nepavyko: { $reason }
# review: new
ui-check = &Tikrinti
# review: new
ui-fill-in-for = Naudoti nustatymus:
# review: new
ui-app-name = Pavadinimas:
# review: new
ui-issuer = Išdavėjas:
# review: new
ui-client-id = Kliento ID:
# review: new
ui-client-secret = Kliento paslaptis:
# review: new
ui-scopes = Teisės (scopes):
# review: new
ui-imap-server = IMAP serveris:
# review: new
ui-smtp-server = SMTP serveris:
# review: new
ui-redirect-uri = Peradresavimo URI:
# review: new
ui-sign-in-app-intro = Prisijungimo programa yra OAuth klientas, kurį užregistruojate pas savo paslaugų teikėją, kad galėtumėte prisijungti per naršyklę. Pasirinkite paslaugų teikėją, kad būtų užpildyti jo nustatymai, tada įveskite kliento ID ir kliento paslaptį, jei paslaugų teikėjas ją pateikė.
# review: new
ui-remove-secret = Kliento paslaptis įrašyta. Įveskite naują, kad ją pakeistumėte, arba pašalinkite įrašytą paslaptį
# review: new
ui-register-it = Užregistruokite programą pas savo paslaugų teikėją
# review: new
ui-built-in-note = { $name } yra įtaisytoji. Galite keisti tik tai, ar ji siūloma naujoms paskyroms.
# review: new
ui-client-with-secret = Kliento ID: { $client }, su kliento paslaptimi.
# review: new
ui-client-public = Kliento ID: { $client }, viešasis klientas (be paslapties).
# review: new
ui-no-accounts = Paskyrų nėra
# review: new
ui-remove-sign-in-app = Pašalinti prisijungimo programą
# review: new
ui-remove-sign-in-app-ask = Pašalinti prisijungimo programą { $name } ir jos įrašytą kliento paslaptį?
# review: new
ui-sign-in-app-not-removed = Prisijungimo programa nepašalinta. { $reason }
# review: new
ui-sign-in-apps-intro = Prisijungimo programos leidžia paskyroms prisijungti per naršyklę. Nepažymėta programa naujoms paskyroms nesiūloma; ją jau naudojančios paskyros veikia toliau.
# review: new
ui-col-issuer = Išdavėjas
# review: new
ui-col-used-by = Naudoja
# review: new
ui-options-system-default = Sistemos numatytoji ({ $language })
# review: new
ui-settings-general = Bendra
# review: new
ui-settings-reading = Skaitymas
# review: new
ui-settings-new-mail = Nauji laiškai
# review: new
ui-settings-sending = Siuntimas
# review: new
ui-settings-default-apps = Numatytosios programos
# review: new
ui-settings-message-list = Laiškų sąrašas
# review: new
ui-settings-messages = Laiškai
# review: new
ui-settings-encryption = Šifravimas
# review: new
ui-settings-language = Kalba
# review: new
ui-settings-label = { $label }:
# review: new
ui-apply = &Taikyti
# review: new
ui-language-label = &Kalba:
# review: new
ui-restart-note = Paleiskite Inbox Classic iš naujo, kad pasikeistų kalba.
# review: new
ui-restart-ask = Paleidus iš naujo, Inbox Classic bus rodoma kalba: { $language }. Paleisti iš naujo dabar?
# review: new
ui-notify-new-mail = &Pranešti, kai gaunami nauji laiškai
# review: new
ui-new-folder-title = Naujas aplankas
# review: new
ui-rename-folder-title = Pervardyti aplanką
# review: new
ui-delete-folder-question = Panaikinti aplanką „{ $folder }“ su jo laiškais ir jame esančiais aplankais? Jis bus panaikintas ir serveryje.
ui-properties = &Ypatybės
# review: new
ui-account-sync = Siųsti ir &gauti
# review: new
ui-account-properties = &Ypatybės...
# review: new
ui-account-move-up = Perkelti &aukštyn
# review: new
ui-account-move-down = Perkelti ž&emyn
ui-menu-open = Ati&daryti
ui-menu-flag = V&ėliavėlė
ui-menu-view-source = Rodyti &šaltinį
# review: new
ui-save-attachments = Įrašyti priedus
# review: new
ui-attachment-open = Atidaryti
# review: new
ui-attachment-save-as = Įrašyti kaip...
# review: new
ui-attachment-save-all = Įrašyti visus...
# review: new
ui-attachment-show-in-message = Rodyti laiške
# review: new
ui-attachments-strip = Priedai
# review: new
ui-attachment-note-title = Šio failo atidarymas
# review: new
ui-attachment-program-tip = Šio tipo failų atidaryti negalima: jie gali paleisti programas. Įrašykite failą ir atidarykite jį patys.
# review: new
ui-clear-flag = &Nuimti vėliavėlę
# review: new
ui-button-move = &Perkelti
# review: new
ui-button-copy = &Kopijuoti
# review: new
ui-find-folder = Ieškoti aplanko
# review: new
ui-new-folder-in = Naujas aplankas bus sukurtas aplanke „{ $folder }“.
# review: new
ui-outbox-send-all = &Siųsti viską dabar
# review: new
ui-yes = Taip
# review: new
ui-no = Ne
# review: new
ui-try-again = Bandyti dar kartą
ui-remove = Pa&šalinti
ui-signature-of = Parašo tekstas: { $account }
# review: new
ui-sign-in-with = Prisijungti naudojant { $provider }
# review: new
ui-sign-in-in-browser-yours = Prisijunkite prie savo paskyros atsidariusiame naršyklės lange, tada grįžkite čia.
# review: new
ui-browser-sign-in-server = { $server } (prisijungimas naršyklėje)
# review: new
ui-dont-allow = Neleisti
# review: new
ui-allow = &Leisti
# review: new
ui-dont-send = Nesiųsti
ui-dont-unsubscribe = Neatsisakyti prenumeratos
# review: new
ui-edit-first = &Pirma redaguoti
# review: new
ui-new-address = Naujas adresas
# review: new
ui-turn-away = &Atmesti
# review: new
ui-clear-agent-log = Išvalyti agentų veiklos istoriją?
# review: new
ui-clear-agent-log-detail = Agentų atlikti pakeitimai nebus atšaukti.
# review: new
ui-let-agents-connect = &Leisti DI agentams jungtis prie Inbox Classic
# review: new
ui-change-button = Keisti…
# review: new
ui-undo-button = Atšaukti
# review: new
ui-rules-title = Laiškų taisyklės
# review: new
ui-rules-intro = Taisyklės rūšiuoja naujus laiškus aplanke „Gauti laiškai“, kol Inbox Classic veikia. Atitinkančios taisyklės vykdomos iš eilės. Kai taisyklė perkelia laišką iš aplanko „Gauti laiškai“, kitos taisyklės jam nebetaikomos.
# review: new
ui-rules-none = Taisyklių dar nėra. Spustelėkite „Nauja“, kad sukurtumėte.
# review: new
ui-rule-new = &Nauja...
# review: new
ui-rule-edit = &Keisti...
# review: new
ui-rule-delete-button = &Panaikinti
# review: new
ui-rule-title = Laiškų taisyklė
# review: new
ui-rule-name = Pavadinimas:
# review: new
ui-rule-account = Paskyra:
# review: new
ui-rule-all-accounts = Visos paskyros
# review: new
ui-rule-query = Paieškos kriterijai:
# review: new
ui-rule-query-hint = Naudokite paieškos žodžius, pavyzdžiui, from:ann@example.com, subject:sąskaita arba list:news.example.com, kaip ir paieškos laukelyje.
# review: new
ui-rule-count = { $count ->
    [one] Šiuos kriterijus dabar atitinka { $count } laiškas aplanke „Gauti laiškai“.
    [few] Šiuos kriterijus dabar atitinka { $count } laiškai aplanke „Gauti laiškai“.
   *[other] Šiuos kriterijus dabar atitinka { $count } laiškų aplanke „Gauti laiškai“.
}
# review: new
ui-rule-show = &Rodyti
# review: new
ui-rule-actions = Veiksmai:
# review: new
ui-rule-move = &Perkelti į:
# review: new
ui-rule-mark-read = Žymėti kaip &skaitytą
# review: new
ui-rule-flag = Žymėti &vėliavėle
# review: new
ui-rule-archive = &Archyvuoti
# review: new
ui-rule-junk = Perkelti į aplanką „&Nepageidaujami laiškai“
# review: new
ui-rule-delete = Panaikin&ti
# review: new
ui-rule-quiet = Nepranešti &man apie jį
# review: new
ui-rule-apply-now = Taip pat taikyti laiškams, jau esantiems aplanke „&Gauti laiškai“
# review: new
ui-rule-delete-ask = Panaikinti taisyklę „{ $name }“?
# review: new
ui-create-rule = Kurti taisyklę...
# review: new
ui-rules-applied = { $count ->
    [one] Jūsų taisyklės surūšiavo { $count } laišką
    [few] Jūsų taisyklės surūšiavo { $count } laiškus
   *[other] Jūsų taisyklės surūšiavo { $count } laiškų
}
# review: new
ui-col-rule-matches = Kriterijai
# review: new
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
