# Latviešu. Melnraksts, gaida dzimtās valodas runātāja pārskatīšanu (sk. core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Iestatījumi, Iziet).

## The main window

# review: new
gtk-search-looks-in = Meklēšana vietā { $place } aptver tēmas, sūtītājus, adresātus, pielikumu nosaukumus un ziņojumu tekstu. Pārbaudiet pareizrakstību vai mēģiniet ar mazāk vārdiem.
# review: new
gtk-search-still-indexing = { $count ->
    [zero] Vēl tiek indeksēts { $count } ziņojumu teksts. Drīz var parādīties vairāk rezultātu.
    [one] Vēl tiek indeksēts { $count } ziņojuma teksts. Drīz var parādīties vairāk rezultātu.
   *[other] Vēl tiek indeksēts { $count } ziņojumu teksts. Drīz var parādīties vairāk rezultātu.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Nav rezultātu
    [zero] { $count } rezultātu
    [one] { $count } rezultāts
   *[other] { $count } rezultāti
} vaicājumam „{ $words }” visās mapēs
# review: new
gtk-search-results-in = { $count ->
    [0] Nav rezultātu
    [zero] { $count } rezultātu
    [one] { $count } rezultāts
   *[other] { $count } rezultāti
} vaicājumam „{ $words }” vietā { $place }
# review: new
gtk-search-indexing = { $count ->
    [zero] vēl tiek indeksēts { $count } ziņojumu teksts
    [one] vēl tiek indeksēts { $count } ziņojuma teksts
   *[other] vēl tiek indeksēts { $count } ziņojumu teksts
}
gtk-list-loading = Ielādē...
# review: new
gtk-menu-rename = Pārdēvēt...
# review: new
gtk-import-one-question = Importēt ziņojumu { $file } mapē { $folder }?
# review: new
gtk-files-not-saved = { $failed } no { $total } failiem nevarēja saglabāt.
# review: new
gtk-unsubscribe-one-click =
    Pamest šo adresātu sarakstu?

    Inbox Classic nosūtīs atteikšanās pieprasījumu uz { $target }. Netiks atvērta neviena tīmekļa lapa un netiks sūtīts neviens e-pasta ziņojums.
# review: new
gtk-unsubscribe-mail =
    Pamest šo adresātu sarakstu?

    Lai atteiktos no abonēšanas, nosūtiet e-pasta ziņojumu uz { $target }. Inbox Classic to sagatavos jūsu vietā. Nosūtiet ziņojumu, lai apstiprinātu.
# review: new
gtk-unsubscribe-web =
    Pamest šo adresātu sarakstu?

    Adresātu saraksta atteikšanās lapa tiks atvērta jūsu pārlūkā ({ $target }).
# review: new
gtk-unsubscribe-failed = Neizdevās atteikties no abonēšanas: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Rakstīt no noteikta konta
# review: new
gtk-toolbar-send-recv-menu = Sūtīt un saņemt pastu noteiktam kontam
# review: new
gtk-main-menu = Galvenā izvēlne
# review: new
gtk-folder-list = Mapju saraksts
# review: new
gtk-quit = Iziet

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Jaunā mape tiek izveidota konta { $account } augšējā līmenī.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Nav nelasītu ziņojumu
    [zero] { $count } nelasītu ziņojumu
    [one] { $count } nelasīts ziņojums
   *[other] { $count } nelasīti ziņojumi
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Neviens ziņojums negaida nosūtīšanu.
# review: new
gtk-outbox-row = Kam: { $to }  ·  Ievietots rindā { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic turpina fonā pārbaudīt, vai nav jauna pasta. Izmantojiet tās ikonu augšējā joslā, lai atvērtu lietotni vai izietu no tās.
# review: new
gtk-sign-in-again-ask =
    Pierakstīšanās kontā { $account } tika noraidīta vai sesija ir beigusies.

    Pierakstīties vēlreiz pārlūkā?
# review: new
gtk-default-app-not-installed = Šī Inbox Classic kopija nav instalēta, tāpēc sistēma to nerāda pasta lietotņu sarakstā. Instalējiet to, lai varētu to izvēlēties.
# review: new
gtk-default-app-now = Inbox Classic tagad ir jūsu noklusējuma pasta lietotne: e-pasta saites atver šeit jaunu ziņojumu.
# review: new
gtk-default-app-failed = Inbox Classic nevarēja iestatīt kā noklusējuma pasta lietotni.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Datums:
# review: new
gtk-reader-files = Ziņojuma pielikumi
# review: new
gtk-files = { $count ->
    [zero] { $count } failu
    [one] { $count } fails
   *[other] { $count } faili
}
# review: new
gtk-pictures-blocked = Daži attēli ir bloķēti, lai sūtītājs nevarētu identificēt jūsu datoru.
# review: new
gtk-download-pictures = Lejupielādēt attēlus
# review: new
gtk-save-attachments-menu = Saglabāt pielikumus...

## The compose window

# review: new
gtk-format-bold = Treknraksts (Ctrl+B)
# review: new
gtk-format-italic = Slīpraksts (Ctrl+I)
# review: new
gtk-format-underline = Pasvītrojums (Ctrl+U)
# review: new
gtk-format-hyperlink = Hipersaite (Ctrl+K)
# review: new
gtk-font = Fonts
# review: new
gtk-show-cc = _Kopija
# review: new
gtk-show-bcc = _Diskrētā kopija
# review: new
gtk-save-tip = Saglabāt (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+klikšķis, lai atvērtu)

## Accounts

# review: new
gtk-plain-warning =
    Bez šifrēšanas ikviens, kas pārtver jūsu tīkla datplūsmu, var izlasīt jūsu paroli un ziņojumus. Izmantojiet šo savienojumu tikai ar serveri savā datorā vai lokālajā tīklā.

    Turpināt?
# review: new
gtk-account-name-title = Konta nosaukums
# review: new
gtk-display-name-title = Parādāmais vārds
# review: new
gtk-turned-off-why = Iespēja „{ $button }” šajā datorā ir izslēgta. { $reason }
# review: new
gtk-turned-off-why-long =
    Iespēja „{ $button }” šajā datorā ir izslēgta.

    { $reason }
# review: new
gtk-next = Tālāk >
# review: new
gtk-provider-sign-in = Pierakstieties kontā { $address } pakalpojuma sniedzēja { $provider } tīmekļa vietnē. Jūsu parole netiek kopīgota ar Inbox Classic. Varat izmantot arī lietotnes paroli, kas izveidota jūsu konta drošības iestatījumos.
# review: new
gtk-provider-sign-in-apps = Pierakstieties kontā { $address } pakalpojuma sniedzēja { $provider } tīmekļa vietnē ar kādu no savām pierakstīšanās lietotnēm (Citas pierakstīšanās iespējas). Varat izmantot arī lietotnes paroli, kas izveidota jūsu konta drošības iestatījumos.
# review: new
gtk-accounts-add = Pievienot...
# review: new
gtk-accounts-properties = Rekvizīti...
# review: new
gtk-accounts-signature = Paraksts...
# review: new
gtk-accounts-sign-in-apps = Pierakstīšanās lietotnes...

## Sign-in apps

# review: new
gtk-app-server = { $kind } serveris
# review: new
gtk-app-port = { $kind } ports
# review: new
gtk-app-security = { $kind } drošība
# review: new
gtk-issuer-found =
    Pierakstīšanās lapa: { $page }
    Marķiera galapunkts: { $endpoint }
# review: new
gtk-client-id = Klienta ID
# review: new
gtk-client-secret = Klienta noslēpums
# review: new
gtk-scopes = Atļaujas (scopes)
# review: new
gtk-redirect-uri = Novirzīšanas URI
# review: new
gtk-issuer-usable =
    Izdevēju var izmantot.

    { $found }
# review: new
gtk-app-built-in = { $app } ir iebūvēta. Varat mainīt tikai to, vai tā tiek piedāvāta jauniem kontiem. { $reason }
# review: new
gtk-built-in = { $app } (iebūvēta)
# review: new
gtk-offered-for-new = Piedāvāt jauniem kontiem
# review: new
gtk-edit-button = Rediģēt...
# review: new
gtk-remove-app-ask = Noņemt pierakstīšanās lietotni { $app } un tās saglabāto klienta noslēpumu?
# review: new
gtk-sign-in-apps-intro = Pierakstīšanās lietotnes ļauj kontiem pierakstīties caur pārlūku. Izslēgta lietotne netiek piedāvāta jauniem kontiem; konti, kas to jau izmanto, turpina darboties.

## AI agents

# review: new
gtk-agent-it-may = Atļautās darbības
# review: new
gtk-agent-accounts = Atļautie konti
# review: new
gtk-never-used = Nekad nav izmantota
# review: new
gtk-last-used = Pēdējoreiz izmantota { $date }
# review: new
gtk-forget-program = Noņemt šo programmu?
# review: new
gtk-forget-program-detail = Programmas atļaujas un tās aģentu darbību vēsture tiks izdzēsta. Kad tā nākamreiz pieslēgsies, atļauja tiks prasīta vēlreiz.
# review: new
gtk-no-agents-yet = Neviens aģents vēl nav lūdzis izmantot jūsu pastu.
# review: new
gtk-nothing-yet = Pagaidām nekā.

## Preferences

# review: new
gtk-preferences = Iestatījumi
# review: changed
gtk-notify-subtitle = Tikai tad, kad Inbox Classic ir fonā

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Pasta klients
# review: new
gtk-desktop-comment = Lasiet un rakstiet e-pastu: ātra, vienkārša pasta programma
# review: new
gtk-desktop-keywords = pasts;e-pasts;vēstules;ziņojumi;iesūtne;
# review: new
gtk-metainfo-summary = Ātra, vienkārša pasta programma
# review: new
gtk-metainfo-description = Inbox Classic lasa un raksta e-pastu ar mapēm kreisajā pusē, ziņojumiem augšā un ziņojumu apakšā, kā to darīja agrākās pasta programmas. Tā darbojas ar jebkuru IMAP un SMTP kontu un pierakstās Outlook.com un Microsoft 365 caur pārlūku.
# review: new
gtk-metainfo-feature-sanitized = Katrs ziņojums tiek parādīts attīrīts, bez skriptiem, un attēli no interneta tikai tad, kad jūs to atļaujat
# review: new
gtk-metainfo-feature-search = Meklēšana, kas atrod vārdus tēmā, sūtītājos un adresātos, failu nosaukumos un tekstā, ar Gmail operatoriem
# review: new
gtk-metainfo-feature-replies = Atbildēs tiek sakļauti agrākie ziņojumi, ko tās citē
# review: new
gtk-metainfo-feature-offline = Pasts ir lasāms arī bezsaistē; paroles glabājas jūsu atslēgu saišķī
