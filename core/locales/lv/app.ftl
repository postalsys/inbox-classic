# Latviešu. Melnraksts, gaida dzimtās valodas runātāja pārskatīšanu (sk. core/locales/GLOSSARY.md).
# The words of the windows, the same on every platform. An & marks the letter of a menu item that Alt and the letter
# choose on Windows and Linux (&& is an ampersand); the Mac leaves it out. Put it on a letter of your word, a different
# one for each item of a menu where you can.

## The menus

menu-file = &Fails
menu-edit = &Rediģēt
menu-view = &Skats
menu-tools = Rī&ki
menu-message = &Ziņojums
menu-help = &Palīdzība
menu-layout = &Izkārtojums
menu-sort-by = &Kārtot pēc
menu-text-size = &Teksta lielums
menu-folder = &Mape
menu-insert = &Ievietot

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = &Jauns konts...
cmd-exit = I&ziet
cmd-sync = Sūtīt un saņemt &visos kontos
cmd-mark-read = Atzīmēt kā &lasītu
cmd-mark-unread = Atzīmēt kā &nelasītu
cmd-pictures = Lejupielādēt &attēlus
cmd-about = &Par Inbox Classic
cmd-new-mail = &Jauns ziņojums
cmd-reply = At&bildēt sūtītājam
cmd-reply-all = Atbildēt &visiem
cmd-forward = &Pārsūtīt
cmd-help = &Saturs
cmd-delete = &Dzēst ziņojumu
cmd-move = Pārviet&ot uz mapi...
cmd-flag = &Atzīmēt ar karodziņu
cmd-new-folder = &Jauna mape...
cmd-rename-folder = Pā&rdēvēt mapi...
cmd-delete-folder = &Dzēst mapi
cmd-empty-folder = &Iztukšot mapi
ui-empty-button = Iztukšot
cmd-accounts = &Konti...
cmd-find = Meklēt &ziņojumu
cmd-save-as = &Saglabāt kā...
cmd-print = Dr&ukāt...
cmd-import = &Importēt ziņojumus...
cmd-outbox = &Izsūtne...
cmd-properties = R&ekvizīti
cmd-mark-all-read = Atzīmēt visus kā lasī&tus
cmd-junk = A&tzīmēt kā nevēlamu
cmd-not-junk = At&celt nevēlama pasta atzīmi
cmd-archive = Ar&hivēt
cmd-watch-conversation = Vērot sa&runu
cmd-ignore-conversation = I&gnorēt sarunu
cmd-next-message = &Nākamais ziņojums
cmd-previous-message = Ie&priekšējais ziņojums
cmd-next-unread = Nākamais nelasītais &ziņojums
cmd-go-to-folder = Pā&riet uz mapi...
cmd-find-in-message = M&eklēt šajā ziņojumā...
ui-go-to-prompt = Pāriet uz mapi:
ui-find-in-message-hint = Meklēt šajā ziņojumā
ui-find-not-found = Šajā ziņojumā nav „{ $words }”
cmd-expand-all-threads = Izvērst visas &sarunas
cmd-collapse-all-threads = Sakļaut visas sar&unas
ui-group-by-conversation = &Grupēt ziņojumus pēc sarunām
cmd-folder-list = &Mapju saraksts
cmd-layout-automatic = &Automātisks
cmd-layout-classic = &Klasisks
cmd-layout-columns = K&olonnas
cmd-sort-date = &Datums
cmd-sort-from = &Sūtītājs
cmd-sort-subject = &Tēma
cmd-sort-size = &Lielums
cmd-sort-ascending = &Augošā secībā
cmd-sort-descending = D&ilstošā secībā
cmd-text-size-largest = &Vislielākais
cmd-text-size-larger = &Lielāks
cmd-text-size-medium = Vi&dējs
cmd-text-size-smaller = &Mazāks
cmd-text-size-smallest = Vism&azākais
cmd-hide-ignored = Slēpt ign&orētās sarunas
cmd-hide-read = Slēpt &lasītos ziņojumus
cmd-notify = &Paziņot par jauniem ziņojumiem
cmd-open = &Atvērt Inbox Classic
cmd-default-app = Iestatīt kā &noklusējuma pasta lietotni...
cmd-view-source = Ziņojuma pirmko&ds
cmd-ai-agents = &MI aģenti...
cmd-options = &Opcijas...
cmd-message-rules = Ziņojumu &kārtulas...
cmd-encryption-keys = Šifrēšanas &atslēgas...
cmd-create-rule-from-message = I&zveidot kārtulu no ziņojuma...
cmd-select-all = Atlasīt &visu
cmd-undo = &Atsaukt
cmd-copy = Kopēt uz &mapi...
cmd-address-book = A&drešu grāmata...
cmd-add-sender-to-book = Pievienot sūtītā&ju adrešu grāmatai
cmd-import-address-book = Importēt &adrešu grāmatu...
cmd-export-address-book = Eksportēt adrešu &grāmatu...
cmd-export-setup = Eksportēt iestatījumus un k&ontus...
cmd-import-setup = Importēt iestatījumus u&n kontus...
cmd-compose-sign = &Digitāli parakstīt
cmd-compose-encrypt = Šif&rēt
cmd-attach-my-key = Pievienot savu &publisko atslēgu

## The tray icon's menu

tray-check = Pārbaudīt, &vai ir jauni ziņojumi
tray-no-accounts = Vēl nav kontu

## Words the windows of more than one platform share

ui-tb-create-mail = Jauns ziņojums
ui-tb-reply = Atbildēt
ui-tb-reply-all = Atbildēt visiem
ui-tb-forward = Pārsūtīt
ui-tb-print = Drukāt
ui-tb-delete = Dzēst
ui-tb-junk = Nevēlams
ui-tb-not-junk = Nav nevēlams
ui-tb-archive = Arhivēt
ui-tb-previous = Iepriekšējais
ui-tb-next = Nākamais
ui-previous-tip = Iepriekšējais ziņojums
ui-next-tip = Nākamais ziņojums
ui-tb-sync = Sūtīt/saņemt
ui-tb-mark-read = Lasīts
ui-tb-mark-unread = Nelasīts
ui-still-running = Inbox Classic joprojām darbojas
ui-no-subject = (bez tēmas)
ui-quoted = „{ $subject }”
ui-newest-from = Jaunākais ziņojums: { $subject } (sūtītājs: { $sender })
ui-new-messages = { $count ->
    [zero] { $count } jaunu ziņojumu
    [one] { $count } jauns ziņojums
   *[other] { $count } jauni ziņojumi
}
ui-outbox-waiting = { $count ->
    [zero] Mapē „Izsūtne” ir { $count } ziņojumu
    [one] Mapē „Izsūtne” ir { $count } ziņojums
   *[other] Mapē „Izsūtne” ir { $count } ziņojumi
}
ui-outbox-waits = Ziņojums { $subject } gaida mapē „Izsūtne”
ui-outbox-sending = Nosūta ziņojumu { $subject }...
ui-from-account = No konta „{ $account }”
ui-sign-in-refused = Pierakstīšanās kontā „{ $account }” ir noraidīta vai sesija ir beigusies.
ui-sign-in-again-ask = Vai pierakstīties vēlreiz pārlūkprogrammā?
ui-sign-in-again-failed = Neizdevās pierakstīties vēlreiz: { $reason }
ui-unknown-reason = nezināms iemesls
ui-checking = Pārbauda, vai kontā „{ $account }” ir jauni ziņojumi...
ui-done = Gatavs
ui-sent-at = Ziņojums { $subject } nosūtīts plkst. { $time }
ui-draft-saved = Ziņojums saglabāts mapē „Melnraksti”
ui-draft-not-saved = Neizdevās saglabāt ziņojumu mapē „Melnraksti”: { $reason }
ui-about-core = Kodols { $version }
ui-add-account-first = Vispirms pievienojiet pasta kontu.
ui-add-account-first-link = Vispirms pievienojiet pasta kontu, pēc tam vēlreiz noklikšķiniet uz e-pasta saites.
ui-default-app-is = Inbox Classic ir jūsu noklusējuma pasta lietotne. Noklikšķinot uz e-pasta saites, tajā tiek atvērts jauna ziņojuma logs.
ui-select-message-first = Vispirms atlasiet ziņojumu.
ui-store-not-opened = Neizdevās atvērt pasta datubāzi.
ui-store-or-cert-not-opened = Neizdevās atvērt pasta datubāzi vai sertifikāta failu.
ui-help-title = Inbox Classic palīdzība
ui-help-missing = Šajā Inbox Classic kopijā nav palīdzības failu.
ui-ok = Labi
ui-cancel = Atcelt
ui-close = Aizvērt
ui-col-subject = Tēma
ui-col-from = Sūtītājs
ui-col-to = Adresāti
ui-col-received = Saņemts
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Vērota saruna
ui-col-sent = Nosūtīts
ui-col-size = Lielums
ui-col-folder = Mape
ui-col-account = Konts
ui-col-queued = Rindā kopš
ui-col-status = Statuss
ui-outbox-title = Izsūtne
ui-outbox-status-waiting = Gaida
ui-outbox-status-not-sent = Nav nosūtīts: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = MI aģenta ziņojums rindā; sūtīšana ne agrāk kā plkst. { $time }
ui-outbox-delete-ask = Vai dzēst šo ziņojumu, to nenosūtot?
ui-open-link = Atvērt saiti
ui-edit-link = Rediģēt saiti...
ui-remove-link = Noņemt saiti
ui-insert-attachment = Ievietot pielikumu
ui-insert-picture = Ievietot attēlu
ui-filter-all = Visi faili
ui-filter-pictures = Attēli
ui-filter-messages = Pasta ziņojumi
ui-save-attachment-as = Saglabāt pielikumu kā
ui-not-sent = Neizdevās nosūtīt ziņojumu.
ui-attachment-forgotten = Jūs uzrakstījāt „{ $word }”, bet neviens fails nav pievienots. Vai tomēr nosūtīt ziņojumu?
ui-send-anyway = Tomēr nosūtīt
ui-go-back = Atgriezties
ui-not-saved = Neizdevās saglabāt ziņojumu.
ui-saving-draft = Saglabā mapē „Melnraksti”...
ui-compose-saved-at = Saglabāts mapē „Melnraksti” plkst. { $time }
ui-compose-restored = Ziņojums atjaunots pēc negaidītas Inbox Classic aizvēršanās
ui-compose-not-saved = Neizdevās saglabāt mapē „Melnraksti”: { $reason }
ui-save-changes-ask = Vai saglabāt šī ziņojuma izmaiņas mapē „Melnraksti”?
ui-new-message-title = Jauns ziņojums
ui-link-invalid = Ierakstiet tīmekļa adresi (https://...) vai e-pasta saiti (mailto:...).
ui-link-address = Adrese:
ui-hyperlink = Hipersaite
ui-hyperlink-intro = Adrese, uz kuru ved atlasītais teksts.
ui-edit-hyperlink = Rediģēt hipersaiti
ui-edit-hyperlink-intro = Saites mērķa adrese. Izdzēsiet adresi, lai noņemtu saiti, saglabājot tekstu.
ui-not-a-picture = Neizdevās ievietot attēlu. Izvēlieties PNG, JPEG, GIF vai WebP failu, kas nav lielāks par 10 MB.
ui-format-color = Fonta krāsa
ui-format-numbers = Numurēts saraksts
ui-format-bullets = Aizzīmēts saraksts
ui-format-outdent = Samazināt atkāpi
ui-format-indent = Palielināt atkāpi
ui-format-left = Līdzināt pa kreisi
ui-format-center = Centrēt
ui-format-right = Līdzināt pa labi
ui-format-line = Ievietot horizontālu līniju
ui-tb-send = Sūtīt
ui-tb-save = Saglabāt
ui-tb-attach = Pievienot
ui-tb-sign = Parakstīt
ui-tb-encrypt = Šifrēt
ui-field-keys = Atslēgas:
ui-field-from = No:
ui-field-to = Kam:
ui-field-cc = Kopija:
ui-field-bcc = Diskrētā kopija:
ui-field-subject = Tēma:
ui-field-attach = Pielikumi:
ui-signature = Paraksta teksts
ui-signature-hint = Šo tekstu pievieno jaunajiem ziņojumiem, atbildēm un pārsūtītajiem ziņojumiem, ko sūtāt no šī konta.
ui-signature-not-saved = Neizdevās saglabāt paraksta tekstu.
ui-all-inboxes = Visas iesūtnes
ui-all-sent = Visi nosūtītie
ui-all-drafts = Visi melnraksti
ui-flagged-folder = Ar karodziņu
ui-all-folders = Visas mapes
ui-the-account = konts
ui-folder-name = Mapes nosaukums:
ui-find-hint = Meklēt ziņojumus
ui-find-tip = Meklē ziņojumu tēmās un tekstā, sūtītāju un adresātu vārdos un adresēs, kā arī pielikumu nosaukumos.
ui-clear-search = Notīrīt meklēšanu
ui-no-match = Neviens ziņojums neatbilst „{ $words }”.
ui-no-match-all = Visās mapēs meklē ziņojumu tēmās un tekstā, sūtītāju un adresātu vārdos un adresēs, kā arī pielikumu nosaukumos. Pārbaudiet pareizrakstību vai ievadiet mazāk vārdu.
ui-no-match-in = Meklēšanas vieta: „{ $folder }”. Meklē ziņojumu tēmās un tekstā, sūtītāju un adresātu vārdos un adresēs, kā arī pielikumu nosaukumos. Pārbaudiet pareizrakstību vai ievadiet mazāk vārdu.
ui-no-items = Šajā skatā nav ziņojumu.
ui-choose-folder = Izvēlieties mapi, lai redzētu tās ziņojumus.
ui-unsubscribe = Atteikties no abonēšanas
ui-open-in-calendar = Atvērt kalendārā
ui-pictures-blocked = Daži attēli ir bloķēti, lai sūtītājam būtu grūtāk izsekot, kad lasāt ziņojumu. Noklikšķiniet šeit, lai tos lejupielādētu.
ui-not-shown = Neizdevās parādīt ziņojumu.
ui-attachment-not-read = Neizdevās nolasīt pielikumu.
ui-attachment-not-saved = Neizdevās saglabāt pielikumu.
ui-not-downloaded = Ziņojums vēl nav lejupielādēts.
ui-leave-list = Vai atteikties no šī adresātu saraksta abonēšanas?
ui-leave-one-click = Inbox Classic nosūtīs atteikšanās pieprasījumu vietnei „{ $target }”. Tīmekļa lapa netiks atvērta un e-pasta ziņojums netiks nosūtīts.
ui-leave-mail = Inbox Classic sagatavos ziņojumu ar pieprasījumu atteikties no abonēšanas. Saņēmējs: { $target }. Nosūtiet šo ziņojumu, lai iesniegtu pieprasījumu.
ui-leave-web = Adresātu saraksta atteikšanās lapa tiks atvērta jūsu pārlūkprogrammā ({ $target }).
ui-unsubscribing = Nosūta atteikšanās pieprasījumu vietnei „{ $target }”...
ui-cannot-unsubscribe = Šajā ziņojumā nav iespējas atteikties no abonēšanas.
ui-unsubscribed = Atteikšanās pieprasījums pieņemts.
ui-not-unsubscribed = Neizdevās atteikties no abonēšanas: { $reason }
ui-event-span = { $start } līdz { $end }
ui-event-floating = { $when } (laika josla nav noteikta)
ui-invitation = Uzaicinājums: { $title }
ui-invitation-updated = Atjaunināts uzaicinājums: { $title }
ui-invitation-canceled = Atcelts: { $title }
ui-invitation-answer = Atbilde uz uzaicinājumu: { $title }
ui-no-title = (bez nosaukuma)
ui-organizer = Organizators: { $name }
ui-invitation-not-read = Neizdevās nolasīt uzaicinājumu.
ui-no-calendar = Neizdevās atvērt uzaicinājumu kalendāra lietotnē. Pārbaudiet, vai datorā ir lietotne .ics failu atvēršanai.
ui-messages-not-changed = Neizdevās mainīt ziņojumus.
ui-new-folder-in-selected = Jaunā mape tiks izveidota atlasītajā mapē.
ui-new-folder-at-top = Jaunā mape tiks izveidota konta augšējā līmenī.
ui-folder-not-created = Neizdevās izveidot mapi.
ui-folder-not-renamed = Neizdevās pārdēvēt mapi.
ui-folder-not-deleted = Neizdevās izdzēst mapi.
ui-rename-folder-intro = Ievadiet jaunu nosaukumu mapei „{ $folder }”.
ui-properties-of = { $subject }: rekvizīti
ui-internet-headers = Šī ziņojuma galvenes:
ui-save-messages-in = Izvēlieties mapi ziņojumu saglabāšanai
ui-save-message-as = Saglabāt ziņojumu kā
ui-import-choose-folder = Vispirms izvēlieties mapi, kurā importēt ziņojumus.
ui-add-account-title = Pievienot pasta kontu
ui-accounts-title = Konti
ui-security-none = Nav (nešifrēts)
ui-field-required = Aizpildiet lauku „{ $field }”.
ui-email-invalid = E-pasta adrese nav derīga.
ui-ports-invalid = Portu numuriem jābūt skaitļiem no 1 līdz 65535.
ui-looking-up = Meklē domēna „{ $domain }” iestatījumus...
ui-found-none = Ievadiet konta datus, ko norādījis jūsu e-pasta pakalpojumu sniedzējs.
ui-found-change = Mainiet šos iestatījumus, ja jūsu pakalpojumu sniedzējs ir norādījis citus.
ui-found-guess = Šai adresei iestatījumi netika atrasti. Ieteiktie serveru nosaukumi ir tikai minējumi. Salīdziniet tos ar pakalpojumu sniedzēja norādījumiem.
ui-found-mx = Inbox Classic atpazina jūsu e-pasta pakalpojumu sniedzēju un ievadīja tā serveru iestatījumus.
ui-found-srv = Šie iestatījumi tika atrasti jūsu domēna DNS ierakstos.
ui-found-autodiscover = Šie iestatījumi atrasti, izmantojot Microsoft Autodiscover (Exchange).
ui-found-other = Šai adresei tika atrasti šie iestatījumi.
ui-app-password-needed = { $provider } pasta programmās nepieņem jūsu parasto konta paroli. Atveriet sava pakalpojumu sniedzēja vietni un konta iestatījumos izveidojiet lietotnes paroli. Ievadiet to nākamās veidlapas laukā „Parole”.
ui-app-password-open = Vai pārlūkprogrammā atvērt norādījumus, ko sniedz { $provider }?
ui-plain-warning = Bez šifrēšanas ikviens, kas pārtver jūsu tīkla datplūsmu, var izlasīt jūsu paroli un ziņojumus. Izmantojiet šo savienojumu tikai ar serveri jūsu datorā vai lokālajā tīklā.
ui-continue-ask = Vai turpināt?
ui-add-sign-in-app = Pievienot pierakstīšanās lietotni...
ui-turned-off = Iespēja „{ $name }” šajā datorā ir izslēgta.
ui-off-here = Šajā datorā izslēgta.
ui-why = Kāpēc?
ui-more-sign-in = Citas pierakstīšanās iespējas...
ui-other-account = Lai pievienotu citu e-pasta kontu, ievadiet savu e-pasta adresi un vārdu, ko redzēs adresāti. Pēc tam tiks meklēti servera iestatījumi.
ui-field-account-name = Konta nosaukums:
ui-field-name = Parādāmais vārds:
ui-field-email = E-pasta adrese:
ui-field-user = Lietotājvārds:
ui-field-password = Parole:
ui-field-imap-host = Ienākošā pasta (IMAP) serveris:
ui-field-imap-port = IMAP ports:
ui-field-imap-security = IMAP drošība:
ui-field-smtp-host = Izejošā pasta (SMTP) serveris:
ui-field-smtp-port = SMTP ports:
ui-field-smtp-security = SMTP drošība:
ui-field-other-addresses = Citas adreses, no kurām sūtāt:
ui-sign-in-not-started = Neizdevās sākt pierakstīšanos pārlūkprogrammā.
ui-sign-in-in-browser = Atvērtajā pārlūkprogrammas logā pierakstieties kontā „{ $account }”, pēc tam atgriezieties šeit.
ui-sign-in-failed = Neizdevās pierakstīties: { $reason }
ui-account-not-saved = Neizdevās saglabāt kontu.
ui-start-intro = Lai pievienotu Gmail, Google Workspace, Outlook.com vai Microsoft 365 kontu, pierakstieties Google vai Microsoft vietnē. Paroli ievadīsiet tur; Inbox Classic to nesaņems.
ui-start-intro-apps = Pierakstieties pārlūkprogrammā, izmantojot kādu no savām pierakstīšanās lietotnēm (izvēle „Citas pierakstīšanās iespējas”), vai pievienojiet e-pasta kontu, tālāk ievadot savu vārdu un adresi.
ui-use-app-password = Izmantot lietotnes paroli
ui-the-provider = pakalpojumu sniedzējs
ui-provider-intro = Pierakstieties kontā „{ $email }” vietnē, ko pārvalda { $provider }. Inbox Classic nesaņem jūsu paroli. Ja kontā ir atļautas lietotņu paroles e-pastam, varat izmantot paroli, kas izveidota konta drošības iestatījumos. Outlook.com un Microsoft 365 kontiem šeit jāizmanto pierakstīšanās pārlūkprogrammā.
ui-provider-intro-apps = Pierakstieties kontā „{ $email }” vietnē, ko pārvalda { $provider }. Izmantojiet kādu no savām pierakstīšanās lietotnēm (izvēle „Citas pierakstīšanās iespējas”). Ja kontā ir atļautas lietotņu paroles e-pastam, varat izmantot paroli, kas izveidota konta drošības iestatījumos. Outlook.com un Microsoft 365 kontiem šeit jāizmanto pierakstīšanās pārlūkprogrammā.
ui-finish = Pabeigt
ui-logon = Pierakstīšanās
ui-enter-password = Ievadiet konta „{ $account }” paroli.
ui-signs-in-with = Pierakstīšanās lietotne: { $app }. Pierakstīšanās notiek pārlūkprogrammā, un konts izmanto šīs lietotnes serverus.
ui-keep-password = Atstājiet paroles lauku tukšu, lai saglabātu pašreizējo paroli.
ui-remove-account = Noņemt kontu
ui-remove-account-ask = Vai noņemt šo kontu no Inbox Classic? Tiks dzēsti tā ziņojumi šajā datorā un saglabātie pierakstīšanās dati. Ziņojumi serverī paliks, taču ziņojumi, kas glabājas tikai šajā datorā, tiks zaudēti.
ui-col-email = E-pasta adrese
ui-col-incoming = Ienākošā pasta serveris
ui-type-email = Ierakstiet savu e-pasta adresi, vards@example.com.
ui-ai-agent = MI aģents
ui-ai-agent-access = MI aģenta piekļuve
ui-ai-agents = MI aģenti
ui-program-path = Programma: { $path }
ui-it-may = Atļautās darbības:
ui-accounts-it-may-use = Atļautie konti:
ui-send-message-ask = Vai nosūtīt ziņojumu?
ui-col-name = Nosaukums
ui-never = Nekad
ui-connect-agent = Pievienot MI aģentu
ui-connect-agent-intro = Pievienojiet šīs rindas sava aģenta MCP serveru iestatījumiem (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Programma
ui-col-may = Atļaujas
ui-col-last-used = Pēdējā lietošana
ui-col-when = Kad
ui-col-what = Darbība
ui-sign-in-app = Pierakstīšanās lietotne
ui-sign-in-apps = Pierakstīšanās lietotnes
ui-add-sign-in-app-title = Pievienot pierakstīšanās lietotni
ui-preset-app-name = Pierakstīšanās lietotne: { $provider }
ui-issuer-not-checked = izdevēju nevar pārbaudīt
ui-checking-issuer = Pārbauda izdevēju: { $issuer }...
ui-issuer-unusable = Izdevēju nevar izmantot: { $reason }
ui-issuer-usable = Izdevēju var izmantot.
ui-sign-in-app-not-saved = Neizdevās saglabāt pierakstīšanās lietotni: { $reason }
ui-check = &Pārbaudīt
ui-fill-in-for = Izmantot iestatījumus:
ui-app-name = Nosaukums:
ui-issuer = Izdevējs:
ui-client-id = Klienta ID:
ui-client-secret = Klienta noslēpums:
ui-scopes = Atļaujas (scopes):
ui-imap-server = IMAP serveris:
ui-smtp-server = SMTP serveris:
ui-redirect-uri = Novirzīšanas URI:
ui-sign-in-app-intro = Pierakstīšanās lietotne ir OAuth klients, ko reģistrējat pie sava pakalpojumu sniedzēja, lai pierakstītos pārlūkprogrammā. Izvēlieties pakalpojumu sniedzēju, lai ievadītu tā iestatījumus, pēc tam pievienojiet klienta ID un klienta noslēpumu, ja pakalpojumu sniedzējs to ir izsniedzis.
ui-remove-secret = Noņemt saglabāto klienta noslēpumu. Lai to aizstātu, ievadiet jaunu.
ui-register-it = Reģistrējiet lietotni pie sava pakalpojumu sniedzēja
ui-built-in-note = Lietotne „{ $name }” ir iebūvēta Inbox Classic. Varat mainīt tikai to, vai tā tiek piedāvāta jauniem kontiem.
ui-client-with-secret = Klienta ID: { $client }. Klienta noslēpums ir saglabāts.
ui-client-public = Publisks klients bez noslēpuma. Klienta ID: { $client }.
ui-no-accounts = Nav kontu
ui-remove-sign-in-app = Noņemt pierakstīšanās lietotni
ui-remove-sign-in-app-ask = Vai noņemt pierakstīšanās lietotni „{ $name }” un tās saglabāto klienta noslēpumu?
ui-sign-in-app-not-removed = Neizdevās noņemt pierakstīšanās lietotni. { $reason }
ui-sign-in-apps-intro = Pierakstīšanās lietotnes ļauj kontiem pierakstīties pārlūkprogrammā. Lietotne, kas nav atzīmēta, netiek piedāvāta jauniem kontiem; konti, kas to jau izmanto, turpina darboties.
ui-col-issuer = Izdevējs
ui-col-used-by = Izmanto
ui-options-system-default = Sistēmas valoda ({ $language })
ui-settings-general = Vispārīgi
ui-settings-reading = Lasīšana
ui-settings-new-mail = Jauni ziņojumi
ui-settings-sending = Sūtīšana
ui-settings-default-apps = Noklusējuma lietotnes
ui-settings-message-list = Ziņojumu saraksts
ui-settings-messages = Ziņojumi
ui-settings-encryption = Šifrēšana
ui-settings-language = Valoda
ui-settings-label = { $label }:
ui-apply = &Lietot
ui-language-label = &Valoda:
ui-restart-note = Restartējiet Inbox Classic, lai mainītu valodu.
ui-restart-ask = Pēc restartēšanas Inbox Classic būs šajā valodā: { $language }. Restartēt tūlīt?
ui-notify-new-mail = &Paziņot par jauniem ziņojumiem
ui-new-folder-title = Jauna mape
ui-rename-folder-title = Pārdēvēt mapi
ui-delete-folder-question = Vai dzēst mapi „{ $folder }” ar tās ziņojumiem un tajā esošajām mapēm? Tā tiks izdzēsta arī serverī.
ui-properties = R&ekvizīti
ui-account-sync = Sūtīt un saņe&mt
ui-account-properties = &Rekvizīti...
ui-account-move-up = Pārvietot &augšup
ui-account-move-down = Pārvietot l&ejup
ui-menu-open = &Atvērt
ui-menu-flag = &Karodziņš
ui-menu-view-source = Skatīt p&irmkodu
ui-save-attachments = Saglabāt pielikumus
ui-attachment-open = Atvērt
ui-attachment-save-as = Saglabāt kā...
ui-attachment-save-all = Saglabāt visus...
ui-attachment-show-in-message = Rādīt ziņojumā
ui-attachments-strip = Pielikumi
ui-attachment-note-title = Šī faila atvēršana
ui-attachment-program-tip = Šeit nevar atvērt šāda veida failus, jo tie var palaist programmas. Lai failu atvērtu paši, vispirms to saglabājiet.
ui-clear-flag = &Noņemt karodziņu
ui-button-move = &Pārvietot
ui-button-copy = &Kopēt
ui-find-folder = Meklēt mapi
ui-new-folder-in = Jaunā mape tiks izveidota mapē „{ $folder }”.
ui-outbox-send-all = &Sūtīt visus tagad
ui-yes = Jā
ui-no = Nē
ui-try-again = Mēģināt vēlreiz
ui-remove = Noņem&t
ui-signature-of = Paraksta teksts: { $account }
ui-sign-in-with = Pierakstīties ar { $provider }
ui-sign-in-in-browser-yours = Pierakstieties savā kontā atvērtajā pārlūkprogrammas logā, pēc tam atgriezieties šeit.
ui-browser-sign-in-server = { $server } (pierakstīšanās pārlūkprogrammā)
ui-dont-allow = Neatļaut
ui-allow = &Atļaut
ui-dont-send = Nesūtīt
ui-dont-unsubscribe = Neatteikties
ui-edit-first = &Vispirms rediģēt
ui-new-address = Jauna adrese
ui-turn-away = A&traidīt
ui-clear-agent-log = Vai notīrīt aģentu darbību vēsturi?
ui-clear-agent-log-detail = Tas neatsauks aģentu veiktās izmaiņas.
ui-let-agents-connect = Ļa&ut MI aģentiem pieslēgties Inbox Classic
ui-change-button = Mainīt…
ui-undo-button = Atsaukt
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Atsaukt kopš…
ui-undo-since-span = Atsaukt šīs programmas darbības:
ui-take-back = Atsaukt
ui-rules-title = Ziņojumu kārtulas
ui-rules-intro = Kamēr Inbox Classic darbojas, jaunajiem ziņojumiem mapē „Iesūtne” tiek piemērotas kārtulas. Ziņojumam atbilstošās kārtulas tiek izpildītas pēc kārtas. Ja kāda kārtula pārvieto ziņojumu ārpus šīs mapes, pārējās kārtulas tam vairs netiek piemērotas.
ui-rules-none = Vēl nav kārtulu. Noklikšķiniet uz pogas „Jauna”, lai izveidotu kārtulu.
ui-rule-new = &Jauna...
ui-rule-edit = &Rediģēt...
ui-rule-delete-button = &Dzēst
ui-rule-title = Ziņojumu kārtula
ui-rule-name = Nosaukums:
ui-rule-account = Konts:
ui-rule-all-accounts = Visi konti
ui-rule-query = Meklēšanas kritēriji:
ui-rule-query-hint = Izmantojiet meklēšanas vārdus, piemēram, from:ann@example.com, subject:rēķins vai list:news.example.com, tāpat kā meklēšanas lodziņā.
ui-rule-count = { $count ->
    [zero] Pašlaik šiem kritērijiem atbilst { $count } ziņojumu mapē „Iesūtne”.
    [one] Pašlaik šiem kritērijiem atbilst { $count } ziņojums mapē „Iesūtne”.
   *[other] Pašlaik šiem kritērijiem atbilst { $count } ziņojumi mapē „Iesūtne”.
}
ui-rule-show = &Rādīt
ui-rule-actions = Darbības:
ui-rule-move = &Pārvietot uz:
ui-rule-mark-read = Atzīmēt kā &lasītu
ui-rule-flag = Atzīmēt ar &karodziņu
ui-rule-archive = &Arhivēt
ui-rule-junk = Pārvietot uz mapi „&Nevēlamais e-pasts”
ui-rule-delete = &Dzēst
ui-rule-quiet = Nerādīt pa&ziņojumu
ui-rule-apply-now = Piemērot arī ziņojumiem, kas jau ir mapē „&Iesūtne”
ui-rule-delete-ask = Vai dzēst kārtulu „{ $name }”?
ui-create-rule = Izveidot kārtulu...
ui-rules-applied = { $count ->
    [one] Jūsu kārtulas apstrādāja { $count } ziņojumu
   *[other] Jūsu kārtulas apstrādāja { $count } ziņojumus
}
ui-col-rule-matches = Kritēriji
ui-clear-button = &Notīrīt
# review: new
ui-how-to-connect = Kā pievienot aģentu…
# review: new
ui-agent-programs = Programmas, kuru aģenti ir lūguši piekļuvi jūsu pastam
# review: new
ui-what-agents-did = Aģentu darbības
# review: new
ui-restart-now = &Restartēt tagad
# review: new
ui-restart-later = &Vēlāk

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

# review: new
ui-tb-new-contact = Jauna kontaktpersona
# review: new
ui-tb-new-group = Jauna grupa
# review: new
ui-tb-properties = Rekvizīti
# review: new
ui-tb-write-to = Rakstīt
# review: new
ui-menu-new-contact = Jauna &kontaktpersona...
# review: new
ui-menu-new-group = Jauna &grupa...
# review: new
ui-menu-write-to = &Rakstīt
# review: new
ui-menu-delete = &Dzēst
# review: new
ui-book-find-hint = Ierakstiet vārdu vai e-pasta adresi
# review: new
ui-book-all-contacts = Visas kontaktpersonas
# review: new
ui-col-phone = Tālrunis
# review: new
ui-book-empty = Adrešu grāmata ir tukša. Noklikšķiniet uz Jauna kontaktpersona, lai kādu pievienotu, vai importējiet vCard vai CSV failu no izvēlnes Fails.
# review: new
ui-book-no-match = Neviena kontaktpersona neatbilst „{ $words }”.
# review: new
ui-book-delete-ask = { $count ->
    [1] Vai dzēst šo kontaktpersonu no adrešu grāmatas?
    [one] Vai dzēst šo { $count } kontaktpersonu no adrešu grāmatas?
   *[other] Vai dzēst šīs { $count } kontaktpersonas no adrešu grāmatas?
}
# review: new
ui-group-delete-ask = Vai dzēst grupu „{ $name }”? Tajā esošās personas paliek adrešu grāmatā.
# review: new
ui-book-no-address = Kontaktpersonai { $name } nav e-pasta adreses.
# review: new
ui-new-contact-title = Jauna kontaktpersona
# review: new
ui-contact-title = { $name }: rekvizīti
# review: new
ui-contact-first = Vārds:
# review: new
ui-contact-last = Uzvārds:
# review: new
ui-contact-display = Parādāmais vārds:
# review: new
ui-contact-nickname = Iesauka:
# review: new
ui-contact-company = Uzņēmums:
# review: new
ui-contact-addresses = E-pasta adreses:
# review: new
ui-contact-address-hint = Ierakstiet e-pasta adresi
# review: new
ui-contact-add = &Pievienot
# review: new
ui-contact-set-default = Iestatīt kā &noklusējumu
# review: new
ui-contact-default = { $address } (noklusējums)
# review: new
ui-contact-phones = Tālruņa numuri:
# review: new
ui-phone-home = Mājas
# review: new
ui-phone-work = Darba
# review: new
ui-phone-mobile = Mobilais
# review: new
ui-phone-other = Cits
# review: new
ui-contact-notes = Piezīmes:
# review: new
ui-contact-name-needed = Ierakstiet kontaktpersonas vārdu vai e-pasta adresi.
# review: new
ui-contact-address-invalid = „{ $address }” nav derīga e-pasta adrese.
# review: new
ui-contact-not-saved = Kontaktpersonu nevarēja saglabāt: { $reason }
# review: new
ui-new-group-title = Jauna grupa
# review: new
ui-group-title = { $name }: rekvizīti
# review: new
ui-group-name = Grupas nosaukums:
# review: new
ui-group-members = Dalībnieki:
# review: new
ui-group-select-members = &Atlasīt dalībniekus...
# review: new
ui-group-new-member = Pievienot e-pasta adresi, kuras nav adrešu grāmatā:
# review: new
ui-group-name-needed = Ierakstiet grupas nosaukumu.
# review: new
ui-group-not-saved = Grupu nevarēja saglabāt: { $reason }
# review: new
ui-group-members-count = { $count ->
    [zero] { $count } dalībnieku
    [one] { $count } dalībnieks
   *[other] { $count } dalībnieki
}
# review: new
ui-select-recipients = Atlasīt adresātus
# review: new
ui-select-members = Atlasīt grupas dalībniekus
# review: new
ui-pick-intro = Ierakstiet vārdu vai atlasiet to sarakstā:
# review: new
ui-pick-recipients = Ziņojuma adresāti:
# review: new
ui-pick-members = Grupas dalībnieki:
# review: new
ui-pick-to = &Kam →
# review: new
ui-pick-cc = K&opija →
# review: new
ui-pick-bcc = &Diskrētā kopija →
# review: new
ui-pick-add = &Pievienot →
# review: new
ui-pick-tip = Izvēlēties adresātus no adrešu grāmatas
# review: new
ui-filter-address-books = Adrešu grāmatas (vCard, CSV)
# review: new
ui-filter-vcard = vCard faili
# review: new
ui-book-export-name = Adrešu grāmata
# review: new
ui-book-imported = { $added ->
    [one] Pievienota { $added } kontaktpersona
   *[other] Pievienotas { $added } kontaktpersonas
}, { $skipped ->
    [one] izlaista { $skipped }, kas jau ir adrešu grāmatā.
   *[other] izlaistas { $skipped }, kas jau ir adrešu grāmatā.
}
# review: new
ui-book-not-imported = Adrešu grāmatu nevarēja importēt: { $reason }
# review: new
ui-book-exported = { $count ->
    [one] { $count } kontaktpersona saglabāta failā { $file }.
   *[other] { $count } kontaktpersonas saglabātas failā { $file }.
}
# review: new
ui-book-not-exported = Adrešu grāmatu nevarēja saglabāt: { $reason }
# review: new
ui-code-copied = Kods nokopēts
# review: changed
ui-codes-in-notifications = &Rādīt pierakstīšanās kodus paziņojumos par jaunu pastu
# review: new
ui-tool-unread-only = Nelasītie
# review: new
ui-no-unread = Šeit nav nelasītu ziņojumu.
# review: new
ui-pictures-always-sender = Vienmēr lejupielādēt attēlus no { $sender }
# review: new
ui-pictures-always-domain = Vienmēr lejupielādēt attēlus no visiem domēnā { $domain }
# review: new
ui-pictures-unconfirmed = Sūtītāja domēnu ({ $domain }) nevarēja pārbaudīt, tāpēc attēli šajā ziņojumā netiek lejupielādēti automātiski.
# review: changed
ui-pictures-always-option = Lejupielādēt &attēlus visos ziņojumos
# review: new
ui-pictures-always-warning = Tad sūtītāji var redzēt, kad jūs lasāt viņu ziņojumus.
# review: new
ui-protection-details = &Detaļas...
# review: new
ui-protection-details-title = Drošības detaļas
# review: new
ui-download-heading = Lejupielāde
# review: changed
ui-download-ahead = Lejupielādēt &ziņojumus iepriekš:
# review: new
ui-download-ahead-recent = Nesenos ziņojumus līdz 1 MB katru
# review: new
ui-download-ahead-all = Visus ziņojumus
# review: new
ui-download-ahead-never = Tikai atverot
# review: changed
ui-download-limit = &Krātuves ierobežojums kontam:
# review: changed
ui-send-delay = &Aizture pirms sūtīšanas:
# review: new
ui-send-delay-note = Kamēr ziņojums gaida nosūtīšanu, sūtīšanu var atcelt ar Atsaukt.
# review: new
ui-dark-messages = Rādīt ziņojumus uz tumša fona, kad sistēmā ir tumšais režīms
# review: new
ui-preview-show = Rādīt &pielikumus vēstulēs
# review: new
ui-preview-show-note = Pēc vēstules teksta rāda attēlus un PDF failu pirmās lappuses. Šos priekšskatījumus Inbox Classic veido pati, tāpēc nekas failā nevar tikt palaists.
# review: new
ui-preview-pdfs = Rādīt PDF &failus vēstulēs
# review: new
ui-sending-in = { $subject } tiks nosūtīts pēc { $count ->
    [one] { $count } sekundes
   *[other] { $count } sekundēm
}
# review: new
ui-send-undone = { $subject } netika nosūtīts. Ziņojums ir atkal atvērts rediģēšanai.
# review: new
ui-send-too-late = { $subject } jau tika nosūtīts.
# review: new
ui-outbox-status-undo = Tiks nosūtīts plkst. { $time }
# review: new
ui-download-note = Iepriekš lejupielādēti ziņojumi atveras uzreiz. Kad krātuves ierobežojums ir pārsniegts, vecākās lokālās kopijas tiek noņemtas un atkal lejupielādētas, kad tās atverat.
# review: new
ui-attachment-downloading = Šī ziņojuma lejupielāde vēl nav pabeigta. Mēģiniet vēlreiz, kad lejupielāde būs pabeigta.
# review: changed
ui-trusted-senders-button = &Uzticamie sūtītāji...
# review: new
ui-trusted-senders-title = Uzticamie sūtītāji
# review: new
ui-trusted-senders-note = Attēli ziņojumos no šiem sūtītājiem tiek lejupielādēti automātiski, kad jūsu pasta pakalpojumu sniedzējs pārbauda sūtītāja domēnu.
# review: new
ui-trusted-everyone-at = Visi domēnā { $domain }
# review: new
ui-trusted-senders-empty = Vēl nav pievienots neviens uzticams sūtītājs.
# review: new
ui-search-encrypted = Meklēt &šifrētos ziņojumos
# review: new
ui-search-encrypted-note = Šifrētie ziņojumi šajā datorā tiek atšifrēti pēc lejupielādes vai atvēršanas, lai to vārdus varētu atrast un sarakstā būtu redzams to īstais temats. Indekss nav šifrēts, un MI aģenti tajā nekad nemeklē. Izslēdziet šo, lai tos noņemtu no indeksa.
# review: new
ui-pgp-keyserver = &Meklēt atslēgas vietnē keys.openpgp.org
# review: new
ui-pgp-keyserver-note = Kad šifrējat ziņojumu vai meklējat atslēgu, meklētā adrese tiek nosūtīta uz keys.openpgp.org. Vispirms tiek vaicāts pašas adreses domēnam.
# review: changed
ui-eml-default = Atvērt .&eml failus ar Inbox Classic
# review: new
ui-eml-default-done = Inbox Classic tagad atver .eml failus.
# review: new
ui-eml-default-failed = Inbox Classic nevarēja iestatīt kā noklusējuma lietotni .eml failiem: { $reason }
# review: new
ui-folders = Mapes
# review: new
ui-sorted-by = Kārtots pēc: { $field }
# review: changed
ui-layout-label = &Izkārtojums:
# review: new
ui-columns-note = Logs ir pietiekami plats kolonnu izkārtojumam. Izkārtojumu var mainīt sadaļā Skats > Izkārtojums.
# review: new
ui-row-unread = Nelasīts
# review: new
ui-row-flagged = Ar karodziņu
# review: new
ui-row-attachments = Ir pielikumi
# review: new
ui-row-encrypted = Šifrēts
# review: new
ui-row-signed = Parakstīts
# review: new
ui-row-messages = { $count ->
    [zero] { $count } ziņojumu
    [one] { $count } ziņojums
   *[other] { $count } ziņojumi
}
# review: changed
ui-list-pictures = &Rādīt sūtītāju attēlus ziņojumu sarakstā
# review: changed
ui-list-pictures-note = Pārbaudītiem sūtītājiem rāda zīmolu logotipus vai adrešu grāmatas attēlus, bet, ja attēla nav, iniciāļus. Logotipi tiek lejupielādēti vienreiz katram zīmolam, nevis katram ziņojumam.
# review: new
ui-card-picture = Attēls:
# review: new
ui-card-picture-choose = &Izvēlēties...
# review: new
ui-picture-not-picture = Šis fails nav PNG vai JPEG attēls.
# review: new
ui-picture-too-large = Šis attēls ir pārāk liels. Izvēlieties attēlu, kas nav lielāks par 10 MB un kura platums un augstums nepārsniedz 8000 pikseļu.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
# review: new
ui-keys-title = Šifrēšanas atslēgas
# review: new
ui-keys-intro = Jūsu atslēgas paraksta jūsu ziņojumus un atver jums šifrētu pastu. Jūsu kontaktpersonu atslēgas pārbauda viņu parakstus un šifrē viņiem sūtīto pastu.
# review: new
ui-keys-empty = Vēl nav atslēgu. Noklikšķiniet uz Jauna atslēga, lai izveidotu savējo, vai uz Importēt, lai pievienotu jau esošu atslēgu.
# review: new
ui-keys-col-name = Vārds
# review: new
ui-keys-col-address = Adrese
# review: new
ui-keys-col-kind = Veids
# review: new
ui-keys-col-status = Statuss
# review: new
ui-keys-kind-own = Jūsu atslēga
# review: new
ui-keys-kind-contact = Kontaktpersona
# review: new
ui-keys-status-verified = { $status }, pārbaudīta
# review: new
ui-keys-new = &Jauna atslēga...
# review: new
ui-keys-import = &Importēt...
# review: new
ui-keys-export = &Eksportēt...
# review: new
ui-keys-backup = &Dublēt...
# review: new
ui-keys-verify = &Pārbaudīt...
# review: new
ui-keys-new-title = Jauna atslēga
# review: new
ui-keys-new-for = Izveidot atslēgu:
# review: new
ui-keys-new-make = &Izveidot atslēgu
# review: new
ui-keys-no-account = Vispirms pievienojiet pasta kontu: atslēga tiek izveidota konta adresēm.
# review: new
ui-keys-memory-only = Paroles tiek glabātas tikai atmiņā, tāpēc tagad izveidotu vai importētu privāto atslēgu pēc Inbox Classic aizvēršanas nevarēs izmantot.
# review: new
ui-keys-backup-offer = Jūsu jaunā atslēga ir gatava. Vai saglabāt tās dublējumu tagad? Ja šis dators tiks pazaudēts vai atiestatīts, atslēgu varēs atgūt tikai no dublējuma.
# review: new
ui-keys-backup-now = &Saglabāt dublējumu...
# review: new
ui-keys-later = &Vēlāk
# review: new
ui-keys-backup-title = Dublēt atslēgu
# review: new
ui-keys-backup-intro = Dublējumu aizsargā paroles frāze. Glabājiet failu un paroles frāzi dažādās drošās vietās: lai atgūtu atslēgu, vajadzēs abus.
# review: new
ui-keys-passphrase = &Paroles frāze:
# review: new
ui-keys-passphrase-again = &Ierakstiet vēlreiz:
# review: new
ui-keys-passphrase-differ = Paroles frāzes nesakrīt.
# review: new
ui-keys-passphrase-short = Izmantojiet paroles frāzi, kurā ir vismaz 8 rakstzīmes.
# review: new
ui-keys-backup-saved = Dublējums tika saglabāts.
# review: new
ui-keys-import-title = Importēt atslēgu
# review: new
ui-keys-import-passphrase = Šo privāto atslēgu aizsargā paroles frāze. Ierakstiet to, lai importētu atslēgu:
# review: new
ui-keys-file-filter = OpenPGP atslēgas
# review: new
ui-keys-use-for = Vai izmantot šo atslēgu adresei { $addresses }? Jūsu ziņojumi no turienes tiks parakstīti ar to, un ar to šifrētu pastu varēs lasīt šeit.
# review: new
ui-keys-use = &Izmantot
# review: new
ui-keys-not-now = &Ne tagad
# review: new
ui-keys-remove-own = Vai noņemt jūsu atslēgu { $fingerprint }? Ar to šifrētu pastu šeit vairs nevarēs lasīt, ja vien atkal neimportēsiet tās dublējumu.
# review: new
ui-keys-remove-contact = Vai noņemt kontaktpersonas { $name } atslēgu? Viņa parakstus nevarēs pārbaudīt un viņam sūtīto pastu nevarēs šifrēt, līdz atkal pievienosiet viņa atslēgu.
# review: new
ui-key-properties-title = Atslēgas rekvizīti
# review: new
ui-key-names = Vārdi:
# review: new
ui-key-fingerprint = Pirkstu nospiedums:
# review: new
ui-key-status = Statuss:
# review: new
ui-key-created = Izveidota:
# review: new
ui-key-expires = Derīga līdz:
# review: new
ui-key-never = Bez termiņa
# review: new
ui-key-algorithm = Algoritms:
# review: new
ui-key-source = Avots:
# review: new
ui-key-addresses = Adreses:
# review: new
ui-key-address-verified = { $address } (pārbaudīta)
# review: new
ui-key-address-not-verified = { $address } (nav pārbaudīta)
# review: new
ui-verify-title = Pārbaudīt atslēgu
# review: new
ui-verify-intro = Palūdziet, lai { $name } jums nolasa savas atslēgas pirkstu nospiedumu no savas lietotnes, klātienē vai pa tālruni. Nesalīdziniet to ar e-pastā sūtītu: tas, kurš varētu mainīt atslēgu, varētu mainīt arī to.
# review: new
ui-verify-fingerprint = Jūsu rīcībā esošās atslēgas pirkstu nospiedums:
# review: new
ui-verify-marks = { $count ->
    [1] Ja tie sakrīt, atslēga tiek atzīmēta kā šīs personas atslēga adresei { $addresses }. Ja šī adrese nav šīs personas, noklikšķiniet uz Atšķiras.
   *[other] Ja tie sakrīt, atslēga tiek atzīmēta kā šīs personas atslēga adresēm { $addresses }. Ja kāda no šīm adresēm nav šīs personas, noklikšķiniet uz Atšķiras.
}
# review: new
ui-verify-match = &Sakrīt
# review: new
ui-verify-differ = &Atšķiras
# review: new
ui-verify-differs = Jūsu atslēga nav tā, kas ir personai { $name }. Noņemiet to un vēlreiz palūdziet viņa atslēgu.
# review: new
ui-verify-unmark = Atzīmēt kā &nepārbaudītu
# review: new
ui-account-security = Drošība
# review: new
ui-account-security-intro = Ar atslēgu jūsu ziņojumus var parakstīt, un cilvēki var jums sūtīt šifrētu pastu.
# review: new
ui-account-key = &Atslēga šim kontam:
# review: new
ui-account-key-none = Nav
# review: new
ui-account-key-new = &Jauna atslēga...
# review: new
ui-account-autocrypt = &Sūtīt manu publisko atslēgu kopā ar ziņojumiem (Autocrypt)
# review: new
ui-contact-key = Šifrēšanas atslēga:
# review: new
ui-contact-key-none = Nav atslēgas
# review: new
ui-contact-key-use-new = Izmantot &jauno atslēgu
# review: new
ui-contact-key-keep = &Paturēt pašreizējo
ui-recipient-keys-title = Adresātu atslēgas
ui-recipient-col-recipient = Adresāts
ui-recipient-col-key = Atslēga
ui-recipient-find-key = &Meklēt atslēgu
ui-recipient-remove = &Noņemt no ziņojuma
ui-send-unencrypted = Sūtīt &bez šifrēšanas
ui-compose-make-key = &Izveidot atslēgu...
ui-compose-show-keys = Šifrēšanas a&tslēgas...
ui-compose-encrypt-off = &Izslēgt šifrēšanu
ui-compose-keep-encrypted = &Atstāt ieslēgtu
# review: new
ui-setup-export-title = Eksportēt iestatījumus un kontus
# review: new
ui-setup-import-title = Importēt iestatījumus un kontus
# review: new
ui-setup-export-intro = Izvēlieties, ko pārnest uz citu datoru. Failā nav ziņojumu: tie tur tiks lejupielādēti no jauna.
# review: new
ui-setup-use-passphrase = &Aizsargāt failu ar paroles frāzi
# review: new
ui-setup-passphrase-note = Ar paroles frāzi fails tiek šifrēts un satur arī jūsu paroles, pierakstīšanās datus un privātās atslēgas. Bez tās katrs konts citā datorā prasīs savu paroli.
# review: new
ui-setup-export-button = &Eksportēt...
# review: new
ui-setup-file-filter = Inbox Classic iestatījumi un konti
# review: new
ui-setup-ask-passphrase = Šo failu aizsargā paroles frāze. Ierakstiet to, lai redzētu, kas ir failā:
# review: new
ui-setup-import-intro = Izvēlieties, ko importēt. Konti, kas jau ir šajā datorā, paliek nemainīti.
# review: new
ui-setup-from = Saglabājusi Inbox Classic { $version }, { $date }.
# review: new
ui-setup-import-button = &Importēt
# review: new
ui-setup-done = Gatavs
# review: new
ui-setup-first-run = Importēt iestatījumus un kontus no cita datora...
