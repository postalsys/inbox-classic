# Latviešu. Melnraksts, gaida dzimtās valodas runātāja pārskatīšanu (sk. core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Iestatījumi, Iziet).

## The main window

gtk-search-looks-in = Meklēšanas vieta: „{ $place }”. Meklēšana aptver temata, sūtītāju un adresātu vārdus un adreses, pielikumu nosaukumus un ziņojumu tekstu. Pārbaudiet pareizrakstību vai ievadiet mazāk vārdu.
gtk-search-still-indexing = { $count ->
    [zero] Vēl tiek indeksēts { $count } ziņojumu teksts. Drīz var parādīties vairāk rezultātu.
    [one] Vēl tiek indeksēts { $count } ziņojuma teksts. Drīz var parādīties vairāk rezultātu.
   *[other] Vēl tiek indeksēts { $count } ziņojumu teksts. Drīz var parādīties vairāk rezultātu.
}
gtk-search-results-everywhere = { $count ->
    [0] Nav rezultātu
    [zero] { $count } rezultātu
    [one] { $count } rezultāts
   *[other] { $count } rezultāti
} vaicājumam „{ $words }” visās mapēs
gtk-search-results-in = { $count ->
    [0] Nav rezultātu
    [zero] { $count } rezultātu
    [one] { $count } rezultāts
   *[other] { $count } rezultāti
} vaicājumam „{ $words }” (meklēšanas vieta: „{ $place }”)
gtk-search-indexing = { $count ->
    [zero] vēl tiek indeksēts { $count } ziņojumu teksts
    [one] vēl tiek indeksēts { $count } ziņojuma teksts
   *[other] vēl tiek indeksēts { $count } ziņojumu teksts
}
gtk-list-loading = Ielādē...
gtk-menu-rename = Pārdēvēt...
gtk-import-one-question = Vai importēt ziņojumu no faila „{ $file }” mapē „{ $folder }”?
gtk-files-not-saved = Neizdevās saglabāt failus: { $failed } no { $total }.
gtk-unsubscribe-one-click =
    Vai atteikties no šī adresātu saraksta abonēšanas?

    Inbox Classic nosūtīs atteikšanās pieprasījumu serverim { $target }. Netiks atvērta tīmekļa lapa vai nosūtīts e-pasta ziņojums.
gtk-unsubscribe-mail =
    Vai atteikties no šī adresātu saraksta abonēšanas?

    Lai atteiktos, jānosūta e-pasta ziņojums uz adresi { $target }. Inbox Classic to sagatavos. Nosūtiet sagatavoto ziņojumu, lai apstiprinātu atteikšanos.
gtk-unsubscribe-web =
    Vai atteikties no šī adresātu saraksta abonēšanas?

    Pārlūkprogrammā tiks atvērta adresātu saraksta atteikšanās lapa ({ $target }).
gtk-unsubscribe-failed = Neizdevās atteikties no abonēšanas: { $problem }
gtk-toolbar-create-mail-menu = Rakstīt no noteikta konta
gtk-toolbar-send-recv-menu = Sūtīt un saņemt pastu noteiktam kontam
gtk-main-menu = Galvenā izvēlne
gtk-folder-list = Mapju saraksts
gtk-quit = Iziet

## The Move and Copy window

gtk-new-folder-at-top-of = Jaunā mape tiks izveidota konta „{ $account }” augšējā līmenī.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Nav nelasītu ziņojumu
    [zero] { $count } nelasītu ziņojumu
    [one] { $count } nelasīts ziņojums
   *[other] { $count } nelasīti ziņojumi
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Neviens ziņojums negaida nosūtīšanu.
gtk-outbox-row = Kam: { $to }  ·  Pievienots rindai: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic turpina fonā pārbaudīt, vai nav jauna pasta. Izmantojiet tās ikonu augšējā joslā, lai atvērtu lietotni vai izietu no tās.
gtk-sign-in-again-ask =
    Pierakstīšanās kontā „{ $account }” tika noraidīta vai sesijas derīgums ir beidzies.

    Vai pierakstīties vēlreiz pārlūkprogrammā?
gtk-default-app-not-installed = Šī Inbox Classic kopija nav instalēta, tāpēc sistēma to nerāda pasta lietotņu sarakstā. Instalējiet to, lai varētu to izvēlēties.
gtk-default-app-now = Inbox Classic tagad ir jūsu noklusējuma pasta lietotne: e-pasta saites atver šeit jaunu ziņojumu.
gtk-default-app-failed = Inbox Classic nevarēja iestatīt kā noklusējuma pasta lietotni.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Datums:
gtk-reader-files = Ziņojuma pielikumi
gtk-files = { $count ->
    [zero] { $count } failu
    [one] { $count } fails
   *[other] { $count } faili
}
gtk-pictures-blocked = Daži attēli ir bloķēti, lai sūtītājam būtu grūtāk izsekot, kad lasāt ziņojumu.
gtk-download-pictures = Lejupielādēt attēlus
gtk-save-attachments-menu = Saglabāt pielikumus...

## The compose window

gtk-format-bold = Treknraksts (Ctrl+B)
gtk-format-italic = Slīpraksts (Ctrl+I)
gtk-format-underline = Pasvītrojums (Ctrl+U)
gtk-format-hyperlink = Hipersaite (Ctrl+K)
gtk-font = Fonts
gtk-show-cc = K_opija
gtk-show-bcc = _Diskrētā kopija
gtk-save-tip = Saglabāt (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+klikšķis, lai atvērtu)

## Accounts

gtk-plain-warning =
    Bez šifrēšanas ikviens, kas pārtver jūsu tīkla datplūsmu, var izlasīt jūsu paroli un ziņojumus. Izmantojiet šo savienojumu tikai ar serveri savā datorā vai lokālajā tīklā.

    Turpināt?
gtk-account-name-title = Konta nosaukums
gtk-display-name-title = Parādāmais vārds
gtk-turned-off-why = Iespēja „{ $button }” šajā datorā ir izslēgta. { $reason }
gtk-turned-off-why-long =
    Iespēja „{ $button }” šajā datorā ir izslēgta.

    { $reason }
gtk-next = Tālāk >
gtk-provider-sign-in = Pierakstieties kontā „{ $address }” vietnē, ko pārvalda { $provider }. Inbox Classic nesaņem jūsu paroli. Ja kontā ir atļautas lietotņu paroles e-pastam, varat izmantot paroli, kas izveidota konta drošības iestatījumos. Outlook.com un Microsoft 365 kontiem šeit jāizmanto pierakstīšanās pārlūkprogrammā.
gtk-provider-sign-in-apps = Pierakstieties kontā „{ $address }” vietnē, ko pārvalda { $provider }. Izmantojiet kādu no savām pierakstīšanās lietotnēm (izvēle „Citas pierakstīšanās iespējas”). Ja kontā ir atļautas lietotņu paroles e-pastam, varat izmantot paroli, kas izveidota konta drošības iestatījumos. Outlook.com un Microsoft 365 kontiem šeit jāizmanto pierakstīšanās pārlūkprogrammā.
gtk-accounts-add = Pievienot...
gtk-accounts-properties = Rekvizīti...
gtk-accounts-signature = Paraksta teksts...
gtk-accounts-sign-in-apps = Pierakstīšanās lietotnes...

## Sign-in apps

gtk-app-server = { $kind } serveris
gtk-app-port = { $kind } ports
gtk-app-security = { $kind } drošība
gtk-issuer-found =
    Pierakstīšanās lapa: { $page }
    Marķiera galapunkts: { $endpoint }
gtk-client-id = Klienta ID
gtk-client-secret = Klienta noslēpums
gtk-scopes = Atļaujas (scopes)
gtk-redirect-uri = Novirzīšanas URI
gtk-issuer-usable =
    Izdevēju var izmantot.

    { $found }
gtk-app-built-in = Pierakstīšanās lietotne „{ $app }” ir iebūvēta. Varat mainīt tikai to, vai tā tiek piedāvāta jauniem kontiem. { $reason }
gtk-built-in = { $app } (iebūvēta)
gtk-offered-for-new = Piedāvāt jauniem kontiem
gtk-edit-button = Rediģēt...
gtk-remove-app-ask = Vai noņemt pierakstīšanās lietotni „{ $app }” un tās saglabāto klienta noslēpumu?
gtk-sign-in-apps-intro = Pierakstīšanās lietotnes ļauj kontiem pierakstīties caur pārlūku. Izslēgta lietotne netiek piedāvāta jauniem kontiem; konti, kas to jau izmanto, turpina darboties.

## AI agents

gtk-agent-it-may = Atļautās darbības
gtk-agent-accounts = Atļautie konti
gtk-never-used = Piekļuve vēl nav izmantota
gtk-last-used = Piekļuve pēdējoreiz izmantota: { $date }
gtk-forget-program = Vai noņemt šīs programmas piekļuves ierakstu?
gtk-forget-program-detail = Programmas atļaujas un tās aģentu darbību vēsture tiks izdzēsta. Kad tā nākamreiz pieslēgsies, atļauja tiks prasīta vēlreiz.
gtk-no-agents-yet = Neviens aģents vēl nav lūdzis izmantot jūsu pastu.
gtk-nothing-yet = Pagaidām nekā.

## Preferences

gtk-preferences = Iestatījumi
gtk-notify-subtitle = Tikai tad, kad Inbox Classic ir fonā

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Pasta klients
gtk-desktop-comment = Lasiet un rakstiet e-pastu: ātra, vienkārša pasta programma
gtk-desktop-keywords = pasts;e-pasts;vēstules;ziņojumi;iesūtne;
gtk-metainfo-summary = Ātra, vienkārša pasta programma
gtk-metainfo-description = Inbox Classic ir e-pasta programma ar klasisku izkārtojumu: mapes pa kreisi, ziņojumu saraksts augšā un atlasītā ziņojuma saturs apakšā. Tā atbalsta IMAP un SMTP kontus. Outlook.com un Microsoft 365 kontiem var pierakstīties pārlūkprogrammā.
gtk-metainfo-feature-sanitized = Ziņojumi tiek attīrīti no aktīva satura un rādīti bez skriptiem; attēli no interneta tiek ielādēti tikai ar jūsu atļauju
gtk-metainfo-feature-search = Meklējiet ziņojumu tematos un tekstā, sūtītāju un adresātu vārdos un adresēs, kā arī pielikumu nosaukumos; var izmantot Gmail meklēšanai līdzīgus operatorus
gtk-metainfo-feature-replies = Atbildēs citētie iepriekšējie ziņojumi ir sakļauti, un tos var izvērst
gtk-metainfo-feature-offline = Pastu var lasīt bezsaistē, kamēr saglabāta vietējā kopija; pierakstīšanās datus parasti glabā sistēmas paroļu krātuvē, ja tā ir pieejama
