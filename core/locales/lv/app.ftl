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
# review: new
ui-open-in-calendar = Atvērt kalendārā
# review: new
ui-pictures-blocked = Daži attēli ir bloķēti, lai sūtītājs nevarētu identificēt jūsu datoru. Noklikšķiniet šeit, lai lejupielādētu attēlus.
# review: new
ui-not-shown = Ziņojumu nevarēja parādīt.
# review: new
ui-attachment-not-read = Pielikumu nevarēja nolasīt.
# review: new
ui-attachment-not-saved = Pielikumu nevarēja saglabāt.
# review: new
ui-not-downloaded = Ziņojums vēl nav lejupielādēts.
# review: new
ui-leave-list = Vai atteikties no šī adresātu saraksta?
# review: new
ui-leave-one-click = Inbox Classic nosūtīs atteikšanās pieprasījumu uz { $target }. Netiks atvērta neviena tīmekļa lapa un netiks nosūtīts neviens e-pasta ziņojums.
# review: new
ui-leave-mail = Lai atteiktos, nosūtiet e-pasta ziņojumu uz { $target }. Inbox Classic to sagatavos jūsu vietā. Nosūtiet ziņojumu, lai apstiprinātu.
# review: new
ui-leave-web = Adresātu saraksta atteikšanās lapa tiks atvērta jūsu pārlūkprogrammā ({ $target }).
# review: new
ui-unsubscribing = Atsakās no { $target }...
# review: new
ui-cannot-unsubscribe = Šajā ziņojumā nav iespējas atteikties no abonēšanas.
# review: new
ui-unsubscribed = Atteikšanās pieprasījums pieņemts. Adresātu saraksts paziņo, ka pārtrauks sūtīt šos ziņojumus.
# review: new
ui-not-unsubscribed = Neizdevās atteikties no abonēšanas: { $reason }
# review: new
ui-event-span = { $start } līdz { $end }
# review: new
ui-event-floating = { $when } (sūtītāja laiks)
# review: new
ui-invitation = Uzaicinājums: { $title }
# review: new
ui-invitation-updated = Atjaunināts uzaicinājums: { $title }
# review: new
ui-invitation-canceled = Atcelts: { $title }
# review: new
ui-invitation-answer = Atbilde uz uzaicinājumu: { $title }
# review: new
ui-no-title = (bez nosaukuma)
# review: new
ui-organizer = Organizators: { $name }
# review: new
ui-invitation-not-read = Uzaicinājumu nevarēja nolasīt.
# review: new
ui-no-calendar = Šajā datorā nav kalendāra lietotnes, ar ko atvērt uzaicinājumus (.ics failus).
# review: new
ui-messages-not-changed = Ziņojumus nevarēja mainīt.
# review: new
ui-new-folder-in-selected = Jaunā mape tiks izveidota atlasītajā mapē.
# review: new
ui-new-folder-at-top = Jaunā mape tiks izveidota konta augšējā līmenī.
# review: new
ui-folder-not-created = Mapi nevarēja izveidot.
# review: new
ui-folder-not-renamed = Mapi nevarēja pārdēvēt.
# review: new
ui-folder-not-deleted = Mapi nevarēja izdzēst.
# review: new
ui-rename-folder-intro = Ievadiet jaunu nosaukumu mapei „{ $folder }”.
# review: new
ui-properties-of = { $subject }: rekvizīti
# review: new
ui-internet-headers = Šī ziņojuma interneta galvenes:
# review: new
ui-save-messages-in = Saglabāt ziņojumus mapē
# review: new
ui-save-message-as = Saglabāt ziņojumu kā
# review: new
ui-import-choose-folder = Vispirms izvēlieties mapi, kurā importēt ziņojumus.
# review: new
ui-add-account-title = Pievienot pasta kontu
# review: new
ui-accounts-title = Konti
# review: new
ui-security-none = Nav (nešifrēts)
# review: new
ui-field-required = Aizpildiet lauku „{ $field }”.
# review: new
ui-email-invalid = E-pasta adrese nav derīga.
# review: new
ui-ports-invalid = Porti ir skaitļi no 1 līdz 65535.
# review: new
ui-looking-up = Meklē domēna { $domain } iestatījumus...
# review: new
ui-found-none = Ievadiet konta datus, ko norādījis jūsu e-pasta pakalpojumu sniedzējs.
# review: new
ui-found-change = Mainiet šos iestatījumus, ja jūsu pakalpojumu sniedzējs ir norādījis citus.
# review: new
ui-found-guess = Šai adresei iestatījumi netika atrasti. Ieteiktie serveru nosaukumi ir minējumi. Pārbaudiet tos pie sava pakalpojumu sniedzēja.
# review: new
ui-found-mx = Inbox Classic atpazina jūsu e-pasta pakalpojumu sniedzēju un aizpildīja tā servera iestatījumus.
# review: new
ui-found-srv = Šie iestatījumi tika atrasti jūsu domēna DNS ierakstos.
# review: new
ui-found-autodiscover = Šos iestatījumus atrada Microsoft Autodiscover (Exchange).
# review: new
ui-found-other = Šai adresei tika atrasti šie iestatījumi.
# review: new
ui-app-password-needed = { $provider } nepieņem jūsu parasto paroli pasta programmās. Izveidojiet lietotnes paroli savā { $provider } kontā un ierakstiet to nākamās veidlapas laukā Parole.
# review: new
ui-app-password-open = Vai atvērt { $provider } norādījumus pārlūkprogrammā?
# review: new
ui-plain-warning = Bez šifrēšanas ikviens, kas pārtver jūsu tīkla datplūsmu, var izlasīt jūsu paroli un ziņojumus. Izmantojiet šo savienojumu tikai ar serveri jūsu datorā vai lokālajā tīklā.
# review: new
ui-continue-ask = Vai turpināt?
# review: new
ui-add-sign-in-app = Pievienot pierakstīšanās lietotni...
# review: new
ui-turned-off = { $name } šajā datorā ir izslēgta.
# review: new
ui-off-here = Šajā datorā izslēgta.
# review: new
ui-why = Kāpēc?
# review: new
ui-more-sign-in = Citas pierakstīšanās iespējas...
# review: new
ui-other-account = Lai pievienotu citu e-pasta kontu, ievadiet savu e-pasta adresi un vārdu, ko redzēs adresāti. Pēc tam tiks meklēti servera iestatījumi.
# review: new
ui-field-account-name = Konta nosaukums:
# review: new
ui-field-name = Parādāmais vārds:
# review: new
ui-field-email = E-pasta adrese:
# review: new
ui-field-user = Lietotājvārds:
# review: new
ui-field-password = Parole:
# review: new
ui-field-imap-host = Ienākošā pasta (IMAP) serveris:
# review: new
ui-field-imap-port = IMAP ports:
# review: new
ui-field-imap-security = IMAP drošība:
# review: new
ui-field-smtp-host = Izejošā pasta (SMTP) serveris:
# review: new
ui-field-smtp-port = SMTP ports:
# review: new
ui-field-smtp-security = SMTP drošība:
# review: new
ui-field-other-addresses = Citas adreses, no kurām sūtāt:
# review: new
ui-sign-in-not-started = Pierakstīšanos pārlūkprogrammā nevarēja sākt.
# review: new
ui-sign-in-in-browser = Pierakstieties kontā { $account } atvērtajā pārlūkprogrammas logā, pēc tam atgriezieties šeit.
# review: new
ui-sign-in-failed = Neizdevās pierakstīties: { $reason }
# review: new
ui-account-not-saved = Kontu nevarēja saglabāt.
# review: new
ui-start-intro = Gmail, Google Workspace, Outlook.com un Microsoft 365: pierakstieties Google vai Microsoft lapā. Paroli ierakstāt tur, nekad ne Inbox Classic.
# review: new
ui-start-intro-apps = Pierakstieties pārlūkprogrammā ar kādu no savām pierakstīšanās lietotnēm (Citas pierakstīšanās iespējas) vai pievienojiet jebkuru e-pasta kontu ar savu vārdu un adresi tālāk.
# review: new
ui-use-app-password = Izmantot lietotnes paroli
# review: new
ui-the-provider = pakalpojumu sniedzējs
# review: new
ui-provider-intro = Pierakstieties kontā { $email } pakalpojumu sniedzēja vietnē ({ $provider }). Jūsu parole netiek kopīgota ar Inbox Classic. Varat arī izmantot lietotnes paroli, kas izveidota jūsu konta drošības iestatījumos.
# review: new
ui-provider-intro-apps = Pierakstieties kontā { $email } pakalpojumu sniedzēja vietnē ({ $provider }), izmantojot kādu no savām pierakstīšanās lietotnēm (Citas pierakstīšanās iespējas). Varat arī izmantot lietotnes paroli, kas izveidota jūsu konta drošības iestatījumos.
# review: new
ui-finish = Pabeigt
# review: new
ui-logon = Pierakstīšanās
# review: new
ui-enter-password = Ievadiet konta { $account } paroli.
# review: new
ui-signs-in-with = Pierakstīšanās lietotne: { $app }. Pierakstīšanās notiek pārlūkprogrammā, un konts izmanto šīs lietotnes serverus.
# review: new
ui-keep-password = Atstājiet paroles lauku tukšu, lai paturētu pašreizējo paroli.
# review: new
ui-remove-account = Noņemt kontu
# review: new
ui-remove-account-ask = Vai noņemt šo kontu no Inbox Classic? Tā pasts paliek serverī; kopija šajā datorā un saglabātā parole tiek noņemta.
# review: new
ui-col-email = E-pasta adrese
# review: new
ui-col-incoming = Ienākošā pasta serveris
# review: new
ui-type-email = Ierakstiet savu e-pasta adresi, vards@example.com.
# review: new
ui-ai-agent = MI aģents
# review: new
ui-ai-agent-access = MI aģenta piekļuve
# review: new
ui-ai-agents = MI aģenti
# review: new
ui-program-path = Programma: { $path }
# review: new
ui-it-may = Atļautās darbības:
# review: new
ui-accounts-it-may-use = Atļautie konti:
# review: new
ui-send-message-ask = Vai nosūtīt ziņojumu?
# review: new
ui-col-name = Nosaukums
# review: new
ui-never = Nekad
# review: new
ui-connect-agent = Pievienot MI aģentu
# review: new
ui-connect-agent-intro = Pievienojiet šo sava aģenta MCP serveriem (Claude Desktop: Settings > Developer > Edit Config):
# review: new
ui-col-program = Programma
# review: new
ui-col-may = Atļaujas
# review: new
ui-col-last-used = Pēdējoreiz izmantots
# review: new
ui-col-when = Kad
# review: new
ui-col-what = Darbība
# review: new
ui-sign-in-app = Pierakstīšanās lietotne
# review: new
ui-sign-in-apps = Pierakstīšanās lietotnes
# review: new
ui-add-sign-in-app-title = Pievienot pierakstīšanās lietotni
# review: new
ui-preset-app-name = { $provider } pierakstīšanās lietotne
# review: new
ui-issuer-not-checked = izdevēju nevar pārbaudīt
# review: new
ui-checking-issuer = Pārbauda { $issuer }...
# review: new
ui-issuer-unusable = Izdevēju nevar izmantot: { $reason }
# review: new
ui-issuer-usable = Izdevēju var izmantot.
# review: new
ui-sign-in-app-not-saved = Pierakstīšanās lietotni nevarēja saglabāt: { $reason }
# review: new
ui-check = &Pārbaudīt
# review: new
ui-fill-in-for = Izmantot iestatījumus:
# review: new
ui-app-name = Nosaukums:
# review: new
ui-issuer = Izdevējs:
# review: new
ui-client-id = Klienta ID:
# review: new
ui-client-secret = Klienta noslēpums:
# review: new
ui-scopes = Atļaujas (scopes):
# review: new
ui-imap-server = IMAP serveris:
# review: new
ui-smtp-server = SMTP serveris:
# review: new
ui-redirect-uri = Novirzīšanas URI:
# review: new
ui-sign-in-app-intro = Pierakstīšanās lietotne ir OAuth klients, ko reģistrējat pie sava pakalpojumu sniedzēja, lai pierakstītos pārlūkprogrammā. Izvēlieties pakalpojumu sniedzēju, lai aizpildītu tā iestatījumus, pēc tam pievienojiet klienta ID un klienta noslēpumu, ja pakalpojumu sniedzējs tādu deva.
# review: new
ui-remove-secret = Klienta noslēpums ir saglabāts. Ievadiet jaunu, lai to aizstātu, vai noņemiet saglabāto noslēpumu
# review: new
ui-register-it = Reģistrējiet lietotni pie sava pakalpojumu sniedzēja
# review: new
ui-built-in-note = { $name } ir iebūvēta. Varat mainīt tikai to, vai tā tiek piedāvāta jauniem kontiem.
# review: new
ui-client-with-secret = Klienta ID: { $client }, ar klienta noslēpumu.
# review: new
ui-client-public = Klienta ID: { $client }, publisks klients (bez noslēpuma).
# review: new
ui-no-accounts = Nav kontu
# review: new
ui-remove-sign-in-app = Noņemt pierakstīšanās lietotni
# review: new
ui-remove-sign-in-app-ask = Vai noņemt pierakstīšanās lietotni { $name } un tās saglabāto klienta noslēpumu?
# review: new
ui-sign-in-app-not-removed = Pierakstīšanās lietotne netika noņemta. { $reason }
# review: new
ui-sign-in-apps-intro = Pierakstīšanās lietotnes ļauj kontiem pierakstīties pārlūkprogrammā. Lietotne, kas nav atzīmēta, netiek piedāvāta jauniem kontiem; konti, kas to jau izmanto, turpina darboties.
# review: new
ui-col-issuer = Izdevējs
# review: new
ui-col-used-by = Izmanto
# review: new
ui-options-system-default = Sistēmas noklusējums ({ $language })
# review: new
ui-settings-general = Vispārīgi
# review: new
ui-settings-reading = Lasīšana
# review: new
ui-settings-new-mail = Jauns pasts
# review: new
ui-settings-sending = Sūtīšana
# review: new
ui-settings-default-apps = Noklusējuma lietotnes
# review: new
ui-settings-message-list = Ziņojumu saraksts
# review: new
ui-settings-messages = Ziņojumi
# review: new
ui-settings-encryption = Šifrēšana
# review: new
ui-settings-language = Valoda
# review: new
ui-settings-label = { $label }:
# review: new
ui-apply = &Lietot
# review: new
ui-language-label = &Valoda:
# review: new
ui-restart-note = Restartējiet Inbox Classic, lai mainītu valodu.
# review: new
ui-restart-ask = Pēc restartēšanas Inbox Classic būs šajā valodā: { $language }. Restartēt tūlīt?
# review: new
ui-notify-new-mail = &Paziņot, kad pienāk jauns pasts
# review: new
ui-new-folder-title = Jauna mape
# review: new
ui-rename-folder-title = Pārdēvēt mapi
# review: new
ui-delete-folder-question = Vai dzēst mapi „{ $folder }” ar tās ziņojumiem un tajā esošajām mapēm? Tā tiks izdzēsta arī serverī.
ui-properties = R&ekvizīti
# review: new
ui-account-sync = Sūtīt un saņe&mt
# review: new
ui-account-properties = &Rekvizīti...
# review: new
ui-account-move-up = Pārvietot &augšup
# review: new
ui-account-move-down = Pārvietot l&ejup
ui-menu-open = &Atvērt
ui-menu-flag = &Karodziņš
ui-menu-view-source = Skatīt p&irmkodu
# review: new
ui-save-attachments = Saglabāt pielikumus
# review: new
ui-attachment-open = Atvērt
# review: new
ui-attachment-save-as = Saglabāt kā...
# review: new
ui-attachment-save-all = Saglabāt visus...
# review: new
ui-attachment-show-in-message = Rādīt vēstulē
# review: new
ui-attachments-strip = Pielikumi
# review: new
ui-attachment-note-title = Šī faila atvēršana
# review: new
ui-attachment-program-tip = Šāda veida failiem atvēršana ir izslēgta: tie var palaist programmas. Saglabājiet failu, lai to atvērtu paši.
# review: new
ui-clear-flag = &Notīrīt karodziņu
# review: new
ui-button-move = &Pārvietot
# review: new
ui-button-copy = &Kopēt
# review: new
ui-find-folder = Meklēt mapi
# review: new
ui-new-folder-in = Jaunā mape tiks izveidota mapē { $folder }.
# review: new
ui-outbox-send-all = &Sūtīt visus tagad
# review: new
ui-yes = Jā
# review: new
ui-no = Nē
# review: new
ui-try-again = Mēģināt vēlreiz
ui-remove = Noņem&t
ui-signature-of = Paraksta teksts: { $account }
# review: new
ui-sign-in-with = Pierakstīties ar { $provider }
# review: new
ui-sign-in-in-browser-yours = Pierakstieties savā kontā atvērtajā pārlūkprogrammas logā, pēc tam atgriezieties šeit.
# review: new
ui-browser-sign-in-server = { $server } (pierakstīšanās pārlūkprogrammā)
# review: new
ui-dont-allow = Neatļaut
# review: new
ui-allow = &Atļaut
# review: new
ui-dont-send = Nesūtīt
ui-dont-unsubscribe = Neatteikties
# review: new
ui-edit-first = &Vispirms rediģēt
# review: new
ui-new-address = Jauna adrese
# review: new
ui-turn-away = A&traidīt
# review: new
ui-clear-agent-log = Vai notīrīt aģentu darbību vēsturi?
# review: new
ui-clear-agent-log-detail = Tas neatsauks aģentu veiktās izmaiņas.
# review: new
ui-let-agents-connect = Ļaut &MI aģentiem pieslēgties Inbox Classic
# review: new
ui-change-button = Mainīt…
# review: new
ui-undo-button = Atsaukt
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
ui-undo-since-button = Atsaukt kopš…
# review: new
ui-undo-since-span = Atsaukt, ko šī programma darīja:
# review: new
ui-take-back = Atsaukt
# review: new
ui-rules-title = Ziņojumu kārtulas
# review: new
ui-rules-intro = Kārtulas kārto jaunos iesūtnes ziņojumus, kamēr Inbox Classic darbojas. Atbilstošās kārtulas tiek izpildītas pēc kārtas. Kad kārtula pārvieto ziņojumu ārpus iesūtnes, citas kārtulas tam vairs netiek piemērotas.
# review: new
ui-rules-none = Vēl nav kārtulu. Noklikšķiniet uz Jauna, lai to izveidotu.
# review: new
ui-rule-new = &Jauna...
# review: new
ui-rule-edit = &Rediģēt...
# review: new
ui-rule-delete-button = &Dzēst
# review: new
ui-rule-title = Ziņojumu kārtula
# review: new
ui-rule-name = Nosaukums:
# review: new
ui-rule-account = Konts:
# review: new
ui-rule-all-accounts = Visi konti
# review: new
ui-rule-query = Meklēšanas kritēriji:
# review: new
ui-rule-query-hint = Izmantojiet meklēšanas vārdus, piemēram, from:ann@example.com, subject:rēķins vai list:news.example.com, tāpat kā meklēšanas lodziņā.
# review: new
ui-rule-count = { $count ->
    [one] Pašlaik šiem kritērijiem atbilst { $count } iesūtnes ziņojums.
   *[other] Pašlaik šiem kritērijiem atbilst { $count } iesūtnes ziņojumi.
}
# review: new
ui-rule-show = &Rādīt
# review: new
ui-rule-actions = Darbības:
# review: new
ui-rule-move = &Pārvietot uz:
# review: new
ui-rule-mark-read = Atzīmēt kā &lasītu
# review: new
ui-rule-flag = Atzīmēt ar &karodziņu
# review: new
ui-rule-archive = &Arhivēt
# review: new
ui-rule-junk = Pārvietot uz mapi &Nevēlamais e-pasts
# review: new
ui-rule-delete = &Dzēst
# review: new
ui-rule-quiet = Ne&ziņot man par to
# review: new
ui-rule-apply-now = Piemērot arī ziņojumiem, kas jau ir &iesūtnē
# review: new
ui-rule-delete-ask = Vai dzēst kārtulu „{ $name }”?
# review: new
ui-create-rule = Izveidot kārtulu...
# review: new
ui-rules-applied = { $count ->
    [one] Jūsu kārtulas sakārtoja { $count } ziņojumu
   *[other] Jūsu kārtulas sakārtoja { $count } ziņojumus
}
# review: new
ui-col-rule-matches = Kritēriji
# review: new
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
