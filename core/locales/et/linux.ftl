# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-mail = Otsi postist
gtk-find-tip = Otsib sõnu kirjade teemast, inimestest, failinimedest ja tekstist.
gtk-clear-search = Tühjenda otsing
gtk-from-account = Kontolt { $account }
gtk-the-account = konto
gtk-column-folder = Kaust
gtk-column-account = Konto
gtk-search-looks-everywhere = Otsing vaatab kõigi kaustade kirjade teemat, inimesi, failinimesid ja teksti. Kontrollige õigekirja või proovige vähemate sõnadega.
gtk-search-looks-in = Otsing vaatab kirjade teemat, inimesi, failinimesid ja teksti asukohas { $place }. Kontrollige õigekirja või proovige vähemate sõnadega.
gtk-search-still-indexing = { $count ->
    [one] { $count } kirja teksti indekseeritakse veel, nii et peagi võib leiduda rohkem.
   *[other] { $count } kirja teksti indekseeritakse veel, nii et peagi võib leiduda rohkem.
}
gtk-search-no-match = Päringule „{ $words }” ei vasta ükski kiri.
gtk-list-empty = Selles vaates pole midagi.
gtk-list-choose-folder = Valige kaust, et selle kirju näha.
gtk-all-inboxes = Kõik sisendkaustad
gtk-all-folders = Kõik kaustad
gtk-search-results-everywhere = { $count ->
    [0] Tulemusi pole
    [one] { $count } tulemus
   *[other] { $count } tulemust
} päringule „{ $words }” kõigis kaustades
gtk-search-results-in = { $count ->
    [0] Tulemusi pole
    [one] { $count } tulemus
   *[other] { $count } tulemust
} päringule „{ $words }” asukohas { $place }
gtk-search-indexing = { $count ->
    [one] { $count } kirja teksti indekseeritakse veel
   *[other] { $count } kirja teksti indekseeritakse veel
}
gtk-toolbar-junk = Rämps
gtk-toolbar-not-junk = Pole rämps
gtk-menu-rename = Nimeta ümber...
gtk-menu-delete = Kustuta
gtk-new-folder-in-selected = Uus kaust luuakse valitud kausta sisse.
gtk-new-folder-at-top = Uus kaust luuakse konto ülemisele tasemele.
gtk-new-folder-title = Uus kaust
gtk-rename-folder-intro = Kausta { $folder } uus nimi.
gtk-rename-folder-title = Nimeta kaust ümber
gtk-delete-folder-question = Kas kustutada kaust „{ $folder }” koos selle kirjade ja alamkaustadega? See kustutatakse ka serverist.
gtk-not-downloaded = Kirja pole veel alla laaditud.
gtk-mail-messages = E-kirjad
gtk-save-message-as = Salvesta kiri nimega
gtk-message-not-saved = Kirja ei õnnestunud salvestada.
gtk-save-messages-in = Salvesta kirjad kausta
gtk-select-message-first = Valige esmalt kiri.
gtk-properties = Atribuudid
gtk-properties-of = { $subject }: atribuudid
gtk-internet-headers = Selle kirja Interneti päised:
gtk-menu-open = Ava
gtk-menu-flag = Lipp
gtk-menu-view-source = Kuva lähtekood
gtk-import-choose-folder = Valige esmalt kaust, kuhu kirjad panna.
gtk-import-one-question = Kas panna kiri { $file } kausta { $folder }?
gtk-attachment-not-read = Manust ei õnnestunud lugeda.
gtk-save-attachment-as = Salvesta manus nimega
gtk-attachment-not-saved = Manust ei õnnestunud salvestada.
gtk-save-attachments = Salvesta manused
gtk-files-not-saved = { $total } failist { $failed } ei õnnestunud salvestada.
gtk-invitation-not-read = Kutset ei õnnestunud lugeda.
gtk-no-calendar-program = Selles arvutis pole kalendriprogrammi, mis avaks kutseid (.ics-faile).
gtk-cancel = Loobu
gtk-ok = OK
gtk-unsubscribe = Loobu tellimusest
gtk-unsubscribe-one-click =
    Kas lahkuda sellest postiloendist?

    Inbox Classic palub aadressil { $target } teile enam mitte saata. Ühtki lehte ei avata ja ühtki kirja ei saadeta.
gtk-unsubscribing = Loendist { $target } loobumine...
gtk-can-not-unsubscribe = Selle kirjaga ei saa tellimusest loobuda.
gtk-unsubscribe-mail =
    Kas lahkuda sellest postiloendist?

    Loend soovib kirja aadressile { $target }. Inbox Classic kirjutab selle teie eest; loobumiseks saatke see ära.
gtk-unsubscribe-web =
    Kas lahkuda sellest postiloendist?

    Loendi vastav leht avaneb teie brauseris ({ $target }).
gtk-unsubscribed = Tellimusest loobutud. Loend ütleb, et ei saada seda posti enam.
gtk-unsubscribe-failed = Tellimusest ei õnnestunud loobuda: { $problem }
gtk-toolbar-create-mail = Uus kiri
gtk-toolbar-create-mail-menu = Kiri ühelt kontolt
gtk-toolbar-send-recv = Saada/Võta vastu
gtk-toolbar-send-recv-menu = Saada ja võta vastu üks konto
gtk-toolbar-reply = Vasta
gtk-toolbar-reply-all = Vasta kõigile
gtk-toolbar-forward = Edasta
gtk-toolbar-print = Prindi
gtk-toolbar-delete = Kustuta
gtk-toolbar-mark-read = Loetud
gtk-toolbar-mark-unread = Lugemata
gtk-main-menu = Peamenüü
gtk-quit = Lõpeta
gtk-clear-flag = Eemalda lipp

## The Move and Copy window

gtk-button-move = Teisalda
gtk-button-copy = Kopeeri
gtk-find-folder = Otsi kausta
gtk-new-folder-in = Uus kaust luuakse kausta { $folder }.
gtk-new-folder-at-top-of = Uus kaust luuakse konto { $account } ülemisele tasemele.

## The message list

gtk-column-from = Saatja
gtk-column-subject = Teema
gtk-column-received = Saabunud
gtk-column-size = Suurus

## Help

gtk-help-title = Inbox Classicu abi

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Lugemata kirju pole
    [one] { $count } lugemata kiri
   *[other] { $count } lugemata kirja
}
gtk-done = Valmis

## The compose window's link menu

gtk-open-link = Ava link
gtk-edit-link = Muuda linki...
gtk-remove-link = Eemalda link

## The Outbox

gtk-no-subject = (teemata)
gtk-outbox-title = Väljundkaust
gtk-outbox-empty = Midagi ei oota saatmist.
gtk-outbox-send-all = Saada kõik kohe
gtk-outbox-delete = Kustuta
gtk-outbox-delete-ask = Kas kustutada see kiri ilma saatmata?
gtk-outbox-waiting = Ootel
gtk-outbox-not-sent = Saatmata: { $reason }
gtk-outbox-agent = Saatis tehisintellekti agent; läheb kell { $time }
gtk-outbox-row = Saaja: { $to }  ·  Järjekorras { $queued }  ·  { $status }

## The app

gtk-store-not-opened = Postihoidlat ei õnnestunud avada.
gtk-store-or-cert-not-opened = Postihoidlat või sertifikaadifaili ei õnnestunud avada.
gtk-checking = Uute kirjade kontrollimine kontol { $account }...
gtk-sent-at = { $subject } saadetud kell { $time }
gtk-draft-saved = Kiri salvestati kausta Mustandid.
gtk-draft-not-saved = Kirja ei salvestatud kausta Mustandid: { $reason }
gtk-newest-from = Uusim, saatjalt { $sender }: { $subject }
gtk-new-messages = { $count } uut kirja
gtk-outbox-waits = { $subject } ootab väljundkaustas
gtk-outbox-sending = Saadetakse { $subject }...
gtk-outbox-count = { $count ->
    [one] { $count } kiri väljundkaustas
   *[other] { $count } kirja väljundkaustas
}
gtk-still-running = Inbox Classic töötab edasi
gtk-still-running-detail = See kontrollib edasi uut posti. Selle ikoon ülemisel ribal avab selle uuesti või lõpetab selle töö.
gtk-add-account-first = Lisage esmalt meilikonto.
gtk-add-account-first-link = Lisage esmalt meilikonto ja klõpsake siis uuesti e-posti lingil.
gtk-quoted = „{ $subject }”
gtk-sign-in-again-ask =
    Konto { $account } sisselogimine lükati tagasi või aegus.

    Kas logida brauseris uuesti sisse?
gtk-sign-in-again-failed = Uuesti sisselogimine ei õnnestunud: { $reason }
gtk-default-app-not-installed = Seda Inbox Classicu koopiat ei paigaldatud, seega ei näita süsteem seda meilirakendusena. Paigaldage see, et seda valida.
gtk-default-app-is = Inbox Classic on teie vaikimisi meilirakendus: e-posti lingid avavad siin uue kirja.
gtk-default-app-now = Inbox Classic on nüüd teie vaikimisi meilirakendus: e-posti lingid avavad siin uue kirja.
gtk-default-app-failed = Inbox Classicut ei õnnestunud vaikimisi meilirakenduseks teha.
gtk-about-core = Tuum { $version }

## Buttons and words used in many windows

gtk-yes = Jah
gtk-no = Ei
gtk-folder-name = Kausta nimi:
gtk-all-files = Kõik failid

## The reading pane

gtk-reader-from = Saatja:
gtk-reader-to = Saaja:
gtk-reader-date = Kuupäev:
gtk-reader-files = Kirja failid
gtk-open-in-calendar = Ava kalendris
gtk-pictures-blocked = Mõned pildid blokeeriti, et saatja ei saaks teie arvutit tuvastada.
gtk-download-pictures = Laadi pildid alla
gtk-try-again = Proovi uuesti
gtk-message-not-shown = Kirja ei õnnestunud kuvada.
gtk-save-attachments-menu = Salvesta manused...
gtk-no-title = (pealkirjata)
gtk-invitation = { $kind ->
    [update] Muudetud kutse: { $summary }
    [cancel] Tühistatud: { $summary }
    [reply] Vastus kutsele: { $summary }
   *[request] Kutse: { $summary }
}
gtk-organizer = Korraldaja: { $organizer }
gtk-attendees = { $count ->
    [one] { $count } osaleja
   *[other] { $count } osalejat
}
gtk-from-to = { $start } kuni { $end }
gtk-day-and-time = { $day }, { $time }
gtk-senders-time = { $when } (saatja aeg)

## The compose window

gtk-format-bold = Paks (Ctrl+B)
gtk-format-italic = Kaldkiri (Ctrl+I)
gtk-format-underline = Allakriipsutus (Ctrl+U)
gtk-format-font-color = Fondi värv
gtk-format-numbered-list = Nummerdatud loend
gtk-format-bulleted-list = Täpploend
gtk-format-decrease-indent = Vähenda taanet
gtk-format-increase-indent = Suurenda taanet
gtk-format-align-left = Joonda vasakule
gtk-format-center = Joonda keskele
gtk-format-align-right = Joonda paremale
gtk-format-hyperlink = Hüperlink (Ctrl+K)
gtk-format-insert-horizontal-line = Lisa horisontaaljoon
gtk-format-insert-picture = Lisa pilt
gtk-font = Font
gtk-font-size = Suurus
gtk-link-invalid = Sisestage veebiaadress (https://...) või e-posti link (mailto:...).
gtk-edit-hyperlink = Muuda hüperlinki
gtk-edit-hyperlink-intro = Kuhu link viib. Tühjendage aadress, et link eemaldada ja selle tekst alles jätta.
gtk-hyperlink = Hüperlink
gtk-hyperlink-intro = Aadress, millele valitud tekst viitab.
gtk-link-address = Aadress:
gtk-pictures = Pildid
gtk-insert-picture = Lisa pilt
gtk-not-a-picture = See fail pole PNG-, JPEG- ega GIF-pilt või on suurem kui 10 MB.
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-compose-from = Saatja:
gtk-compose-to = Saaja:
gtk-compose-cc = Cc:
gtk-compose-bcc = Bcc:
gtk-compose-subject = Teema:
gtk-compose-attach = Manus:
gtk-send = Saada
gtk-save-tip = Salvesta (Ctrl+S)
gtk-attach-tip = Manusta
gtk-new-message = Uus kiri
gtk-remove = Eemalda
gtk-link-status = { $link }    (avamiseks Ctrl+klõps)
gtk-insert-attachment = Lisa manus
gtk-saving-draft = Salvestamine kausta Mustandid...
gtk-save-changes = Kas salvestada selle kirja muudatused kausta Mustandid?
gtk-not-saved-in-drafts = Ei salvestatud kausta Mustandid: { $reason }
gtk-saved-in-drafts-at = Salvestati kausta Mustandid kell { $time }
gtk-signature-hint = Lisatakse selle konto uutele kirjadele, vastustele ja edastustele.
gtk-signature-of = Allkiri - { $account }
gtk-signature = Allkiri
gtk-signature-not-saved = Allkirja ei õnnestunud salvestada.

## Accounts

gtk-add-mail-account = Lisa meilikonto
gtk-account-not-saved = Kontot ei õnnestunud salvestada.
gtk-security-none = Puudub (krüptimata)
gtk-field-required = { $field } on kohustuslik.
gtk-address-not-valid = E-posti aadress pole korrektne.
gtk-ports-are-numbers = Pordid on arvud 1 kuni 65535.
gtk-display-name = Kuvatav nimi:
gtk-email-address = E-posti aadress:
gtk-user-name = Kasutajanimi:
gtk-password = Parool:
gtk-imap-server = Sissetuleva posti server (IMAP):
gtk-imap-port = IMAP-port:
gtk-imap-security = IMAP-turve:
gtk-smtp-server = Väljamineva posti server (SMTP):
gtk-smtp-port = SMTP-port:
gtk-smtp-security = SMTP-turve:
gtk-plain-warning =
    Krüptimata liiguvad teie parool ja post võrgus loetavana kõigile, kes on teel. Kasutage seda ainult oma arvutis või võrgus oleva serveri puhul.

    Kas jätkata?
gtk-sign-in-with = Logi sisse teenusega { $provider }
gtk-the-provider = teie teenusepakkuja
gtk-more-sign-in = Veel sisselogimisvõimalusi...
gtk-display-name-title = Kuvatav nimi
gtk-email-address-title = E-posti aadress
gtk-other-account-intro = Mis tahes muu meilikonto: teie nimi, nagu teised seda näevad, ja teie e-posti aadress. Selle servereid otsitakse järgmisena.
gtk-type-address = Sisestage oma e-posti aadress, nimi@example.com.
gtk-turned-off-why = { $button } on selles arvutis välja lülitatud. { $reason }
gtk-turned-off-why-long =
    { $button } on selles arvutis välja lülitatud.

    { $reason }
gtk-turned-off = Selles arvutis välja lülitatud.
gtk-why = Miks?
gtk-add-sign-in-app = Lisa sisselogimisrakendus...
gtk-browser-sign-in-not-started = Brauseri kaudu sisselogimist ei õnnestunud alustada.
gtk-sign-in-in-browser = Logige avanenud brauseriaknas sisse kontole { $account } ja tulge siis siia tagasi.
gtk-sign-in-in-browser-yours = Logige avanenud brauseriaknas oma kontole sisse ja tulge siis siia tagasi.
gtk-signing-in-failed = Sisselogimine ei õnnestunud: { $reason }
gtk-looking-up = Domeeni { $domain } sätete otsimine...
gtk-found-none = Sisestage konto andmed, mille teie meiliteenuse pakkuja teile andis.
gtk-found-guess = Selle aadressi jaoks sätteid ei leitud: need on tavalised nimed, kontrollige neid oma teenusepakkujalt.
gtk-found-mx = Teie posti haldab teenusepakkuja, keda Inbox Classic tunneb; need on tema serverid.
gtk-found-srv = Need sätted leiti teie domeeni DNS-kirjetest.
gtk-found-autodiscover = Need sätted leidis Microsoft Autodiscover (Exchange).
gtk-found-other = Need sätted leiti selle aadressi jaoks.
gtk-found-change = Muutke neid, kui teenusepakkuja andis teile teised.
gtk-app-password-needed = { $provider } ei võta meiliprogrammides vastu teie tavalist parooli. Looge oma { $provider } kontol rakenduse parool ja sisestage see järgmise vormi väljale Parool.
gtk-open-instructions = Kas avada { $provider } juhised brauseris?
gtk-start-intro = Gmail, Google Workspace, Outlook.com ja Microsoft 365: logige sisse Google'i või Microsofti enda lehel. Teie parool sisestatakse seal, mitte kunagi Inbox Classicusse.
gtk-start-intro-apps = Logige brauseri kaudu sisse mõne oma sisselogimisrakendusega (Veel sisselogimisvõimalusi) või lisage mis tahes meilikonto oma nime ja aadressiga allpool.
gtk-next = Edasi >
gtk-provider-sign-in = { $address } logib sisse teenusepakkuja { $provider } enda lehel, ilma et Inbox Classic teie parooli saaks. Või kasutage oma konto turvasätetes loodud rakenduse parooli.
gtk-provider-sign-in-apps = { $address } saab sisse logida teenusepakkuja { $provider } enda lehel mõne teie sisselogimisrakendusega (Veel sisselogimisvõimalusi). Või kasutage oma konto turvasätetes loodud rakenduse parooli.
gtk-use-app-password = Kasuta rakenduse parooli
gtk-finish = Lõpeta
gtk-enter-password = Sisestage konto { $account } parool.
gtk-logon = Sisselogimine
gtk-signs-in-with = Logib sisse rakendusega { $app }. See logib sisse brauseri kaudu ja kasutab oma sisselogimise servereid.
gtk-keep-password = Jätke parool tühjaks, et praegune alles jätta.
gtk-browser-sign-in-server = { $server } (sisselogimine brauseris)
gtk-accounts-add = Lisa...
gtk-accounts-properties = Atribuudid...
gtk-accounts-signature = Allkiri...
gtk-accounts-sign-in-apps = Sisselogimisrakendused...
gtk-accounts-title = Kontod
gtk-remove-account = Eemalda konto
gtk-remove-account-ask = Kas eemaldada see konto Inbox Classicust? Selle post jääb serverisse; koopia selles arvutis ja salvestatud parool eemaldatakse.

## Sign-in apps

gtk-sign-in-app = Sisselogimisrakendus
gtk-remove-sign-in-app = Eemalda sisselogimisrakendus
gtk-check = Kontrolli
gtk-app-server = { $kind }-server
gtk-app-port = { $kind }-port
gtk-app-security = { $kind }-turve
gtk-preset-name = { $provider } sisselogimisrakendus
gtk-checking-issuer = { $issuer } kontrollimine...
gtk-issuer-found =
    Sisselogimisleht: { $page }
    Tõendi otspunkt: { $endpoint }
gtk-app-editor-intro = OAuthi klient, mille registreerisite oma teenusepakkuja juures, brauseri kaudu sisselogivate kontode jaoks. Täitke see teenusepakkuja jaoks ja lisage siis kliendi ID (ja saladus, kui teenusepakkuja selle andis).
gtk-fill-in-for = Täida teenusele:
gtk-app-name = Nimi
gtk-issuer = Väljaandja
gtk-client-id = Kliendi ID
gtk-client-secret = Kliendi saladus
gtk-secret-saved = Saladus on salvestatud; asendamiseks sisestage uus või eemaldage see
gtk-scopes = Ulatused (scopes)
gtk-register-it = Registreerige see oma teenusepakkuja juures
gtk-redirect-uri = Ümbersuunamise URI
gtk-copy-button = Kopeeri
gtk-add-sign-in-app-title = Lisa sisselogimisrakendus
gtk-issuer-usable =
    Väljaandjat saab kasutada.

    { $found }
gtk-issuer-not-usable = Väljaandjat ei saa kasutada: { $reason }
gtk-app-not-saved = Sisselogimisrakendust ei õnnestunud salvestada: { $reason }
gtk-app-built-in = { $app } on sisseehitatud: muuta saab ainult seda, kas seda uute kontode jaoks kasutatakse. { $reason }
gtk-client-with-secret = Kliendi ID: { $client }, kliendi saladusega.
gtk-client-public = Kliendi ID: { $client }, avalik klient (saladuseta).
gtk-no-accounts = Kontosid pole
gtk-built-in = { $app } (sisseehitatud)
gtk-offered-for-new = Pakutakse uutele kontodele
gtk-edit-button = Muuda...
gtk-sign-in-apps-title = Sisselogimisrakendused
gtk-remove-app-ask = Kas eemaldada sisselogimisrakendus { $app } ja selle salvestatud kliendi saladus?
gtk-app-not-removed = Sisselogimisrakendust ei eemaldatud: { $reason }
gtk-sign-in-apps-intro = Sisselogimisrakendused lasevad kontodel brauseri kaudu sisse logida. Väljalülitatut ei pakuta uutele kontodele; kontod, mis seda juba kasutavad, töötavad edasi.

## AI agents

gtk-agent-program = Programm: { $path }
gtk-agent-it-may = See võib
gtk-agent-accounts = Kontod, mida see võib kasutada
gtk-dont-allow = Ära luba
gtk-allow = Luba
gtk-dont-send = Ära saada
gtk-edit-first = Muuda enne
gtk-new-address = Uus aadress
gtk-never-used = Pole kasutatud
gtk-last-used = Viimati kasutatud { $date }
gtk-turn-away = Keeldu
gtk-forget-program = Kas unustada see programm?
gtk-forget-program-detail = Järgmisel ühendumisel küsitakse uuesti ja see, mida selle agendid tegid, unustatakse.
gtk-ai-agents = Tehisintellekti agendid
gtk-clear-agent-log = Kas tühjendada agentide tegevuste loend?
gtk-clear-agent-log-detail = Mis tehtud, jääb tehtuks.
gtk-let-agents-connect = Luba tehisintellekti agentidel Inbox Classicuga ühenduda
gtk-no-agents-yet = Ükski agent pole veel teie posti kasutada palunud.
gtk-nothing-yet = Veel mitte midagi.
gtk-change-button = Muuda…
gtk-undo-button = Võta tagasi
gtk-clear-button = Tühjenda
gtk-how-to-connect = Kuidas agenti ühendada…
gtk-agent-programs = Programmid, mille agendid palusid teie posti kasutada
gtk-what-agents-did = Mida agendid tegid
gtk-connect-agent = Ühenda tehisintellekti agent
gtk-connect-agent-intro = Lisage see oma agendi MCP-serverite hulka (Claude Desktop: Settings > Developer > Edit Config):

## Preferences

gtk-preferences = Eelistused
gtk-language = Keel
gtk-language-subtitle = Akende ja abi sõnad
gtk-system-default = Süsteemi vaikimisi ({ $language })
gtk-new-mail-group = Uus post
gtk-notify-subtitle = Teade, kui uusi kirju saabub ajal, mil aken on taustal
gtk-restart-to-change = Inbox Classic taaskäivitub, et keelt muuta.
gtk-restart-now = Taaskäivita kohe
gtk-restart-later = Hiljem
