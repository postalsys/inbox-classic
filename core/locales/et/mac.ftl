# Eesti. Mustand, ootab emakeelse kõneleja ülevaatust.

## The app and its menus

mac-store-not-opened = Postihoidlat ei saanud avada.
mac-store-or-certificate-not-opened = Postihoidlat või sertifikaadifaili ei saanud avada.
mac-quit = Välju rakendusest Inbox Classic
mac-settings = Seaded…
mac-services = Teenused
mac-hide = Peida Inbox Classic
mac-hide-others = Peida teised
mac-show-all = Näita kõiki
mac-check-updates = Otsi uuendusi…
mac-close-window = Sulge aken
mac-redo = Tee uuesti
mac-cut = Lõika
mac-copy = Kopeeri
mac-paste = Kleebi
mac-menu-window = Aken
mac-minimize = Minimeeri
mac-zoom = Suumi
mac-help-title = Inbox Classicu abi
mac-no-updates = See Inbox Classicu koopia ei uuenda end ise. Uusima versiooni leiate aadressilt inboxclassic.com.
mac-flag = Lipp
mac-clear-flag = Eemalda lipp

## Settings

mac-settings-title = Seaded
mac-language-label = Keel:
mac-system-default = Süsteemi vaikimisi ({ $language })
mac-restart-hint = Keele vahetamiseks käivitub Inbox Classic uuesti.
mac-notify-new-mail = Teavita mind uue posti saabumisest
mac-restart-question = Kas käivitada Inbox Classic keele vahetamiseks kohe uuesti?
mac-restart-now = Käivita kohe uuesti
mac-restart-later = Hiljem

## Dialogs

mac-ok = OK
mac-cancel = Loobu
mac-yes = Jah
mac-no = Ei
mac-folder-name = Kausta nimi:
mac-save-attachment-as = Salvesta manus nimega
mac-choose = Vali
mac-messages-not-changed = Kirju ei saanud muuta.

## The main window

mac-still-running = Inbox Classic töötab edasi
mac-still-running-detail = See kontrollib edasi uut posti. Uuesti avamiseks klõpsake selle ikooni Dockis.
mac-no-subject = (teemata)
mac-quoted = „{ $subject }“
mac-outbox-waiting =
    { $count ->
        [one] { $count } kiri väljundkaustas
       *[other] { $count } kirja väljundkaustas
    }
mac-outbox-waits = { $subject } ootab väljundkaustas
mac-sending = Saadan: { $subject }…
mac-checking = Kontrollin uusi kirju kontol { $account }…
mac-done = Valmis
mac-sent-at = { $subject } saadetud kell { $time }
mac-draft-saved = Kiri salvestati mustanditesse.
mac-draft-not-saved = Kirja ei salvestatud mustanditesse: { $reason }
mac-account-said = { $account }: { $message }
mac-new-messages =
    { $count ->
        [one] { $count } uus kiri
       *[other] { $count } uut kirja
    }
mac-newest-from = Uusim saatjalt { $from }: { $subject }
mac-sign-in-refused = Konto { $account } sisselogimine lükati tagasi või aegus.
mac-sign-in-again = Kas logida brauseris uuesti sisse?
mac-sign-in-failed = Uuesti sisselogimine ei õnnestunud: { $reason }
mac-unknown-reason = tundmatu põhjus
mac-core-version = Tuum { $version }
mac-add-account-first = Lisage kõigepealt e-posti konto.
mac-add-account-first-link = Lisage kõigepealt e-posti konto ja klõpsake siis uuesti e-posti lingil.
mac-select-message-first = Valige kõigepealt kiri.
mac-not-bundle = See Inbox Classicu koopia ei ole rakenduse pakett, seega ei saa see olla vaikimisi e-posti rakendus.
mac-is-default = Inbox Classic on teie vaikimisi e-posti rakendus: e-posti lingid avavad siin uue kirja.
mac-not-made-default = Inbox Classicut ei tehtud vaikimisi e-posti rakenduseks: { $reason }
mac-tool-create-mail = Uus kiri
mac-tool-reply = Vasta
mac-tool-reply-all = Vasta kõigile
mac-tool-forward = Edasta
mac-tool-print = Prindi
mac-tool-delete = Kustuta
mac-tool-junk = Rämpspost
mac-tool-not-junk = Pole rämpspost
mac-tool-sync = Saada/Võta vastu
mac-tool-mark-read = Loetuks
mac-tool-mark-unread = Lugemata
mac-tool-search = Otsi
mac-search-mail = Otsi postist
mac-find-tip = Otsib sõnu kirjade teemast, inimestest, failinimedest ja tekstist.
mac-from-account = Kontolt { $account }

## The folders and the message list

mac-clear-search = Tühjenda otsing
mac-all-inboxes = Kõik sisendkaustad
mac-the-account = konto
mac-all-folders = Kõik kaustad
mac-column-received = Saabunud
mac-column-size = Suurus
mac-column-folder = Kaust
mac-column-account = Konto
mac-no-match = Otsingule „{ $words }“ ei vasta ükski kiri.
mac-search-looks-everywhere = Otsing vaatab kõigi kaustade kirjade teemat, inimesi, failinimesid ja teksti. Kontrollige õigekirja või proovige vähemate sõnadega.
mac-search-looks-in = Otsing vaatab kausta { $folder } kirjade teemat, inimesi, failinimesid ja teksti. Kontrollige õigekirja või proovige vähemate sõnadega.
mac-still-indexing-more =
    { $count ->
        [one] { $count } kirja teksti alles indekseeritakse, nii et peagi võib leiduda rohkem.
       *[other] { $count } kirja teksti alles indekseeritakse, nii et peagi võib leiduda rohkem.
    }
mac-no-items = Selles vaates pole ühtegi üksust.
mac-choose-folder = Valige kaust, et näha selle kirju.
mac-results-everywhere =
    { $count ->
        [0] Otsingul „{ $words }“ pole kõigis kaustades tulemusi
        [one] { $count } tulemus otsingule „{ $words }“ kõigis kaustades
       *[other] { $count } tulemust otsingule „{ $words }“ kõigis kaustades
    }
mac-results-in =
    { $count ->
        [0] Otsingul „{ $words }“ pole kaustas { $folder } tulemusi
        [one] { $count } tulemus otsingule „{ $words }“ kaustas { $folder }
       *[other] { $count } tulemust otsingule „{ $words }“ kaustas { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] { $count } kirja teksti indekseeritakse veel
       *[other] { $count } kirja teksti indekseeritakse veel
    }
mac-folder-unread = { $folder }, { $count } lugemata
mac-message-not-shown = Kirja ei saanud näidata.
mac-delete = Kustuta
mac-move-button = Teisalda
mac-copy-button = Kopeeri
mac-new-folder = Uus kaust
mac-new-folder-in-selected = Uus kaust tuleb valitud kausta sisse.
mac-new-folder-at-top = Uus kaust tuleb konto ülemisele tasemele.
mac-folder-not-created = Kausta ei saanud luua.
mac-rename-folder = Nimeta kaust ümber
mac-rename-folder-intro = Kausta { $folder } uus nimi.
mac-folder-not-renamed = Kausta ei saanud ümber nimetada.
mac-delete-folder-question = Kas kustutada kaust „{ $folder }“ koos selle kirjade ja alamkaustadega? See kustutatakse ka serverist.
mac-folder-not-deleted = Kausta ei saanud kustutada.
mac-not-downloaded = Kiri pole veel alla laaditud.
mac-save-message-as = Salvesta kiri nimega
mac-message-not-saved = Kirja ei saanud salvestada.
mac-properties = Atribuudid
mac-properties-of = { $subject }: atribuudid
mac-internet-headers = Selle kirja Interneti-päised:
mac-close = Sulge
mac-open = Ava
mac-view-source = Näita lähteteksti
mac-import-messages = Impordi kirjad
mac-import-choose-folder = Valige kõigepealt kaust, kuhu kirjad panna.
mac-save-messages = Salvesta kirjad
mac-save-attachments-menu = Salvesta manused…
mac-save-attachments = Salvesta manused
mac-attachment-not-read = Manust ei saanud lugeda.
mac-attachment-not-saved = Manust ei saanud salvestada.
mac-files-not-saved =
    { $count ->
       *[other] { $count } failist { $failed } ei saanud salvestada.
    }
mac-invitation-not-read = Kutset ei saanud lugeda.
mac-no-calendar-app = Ükski selle Maci kalendrirakendus ei ava kutseid (.ics-faile).
mac-leave-list = Kas lahkuda sellest postiloendist?
mac-unsubscribe = Loobu tellimusest
mac-unsubscribe-one-click = Inbox Classic palub aadressil { $target } lõpetada teile saatmise. Ühtegi lehte ei avata ja ühtegi kirja ei saadeta.
mac-unsubscribe-mail = Loend soovib kirja aadressile { $target }. Inbox Classic kirjutab selle teie eest; tellimusest loobumiseks saatke see.
mac-unsubscribe-web = Loendi vastav leht avaneb teie brauseris ({ $target }).
mac-unsubscribing = Loobun tellimusest: { $target }…
mac-can-not-unsubscribe = Selle kirjaga ei saa tellimusest loobuda.
mac-unsubscribed = Tellimusest loobutud. Loend ütleb, et lõpetab selle posti saatmise.
mac-not-unsubscribed = Tellimusest ei saanud loobuda: { $reason }

## The compose window

mac-bold = Paks
mac-italic = Kaldkiri
mac-underline = Allajoonitud
mac-numbered-list = Nummerdatud loend
mac-bulleted-list = Täpploend
mac-align-left = Joonda vasakule
mac-center = Keskele
mac-align-right = Joonda paremale
mac-font-color = Fondi värv
mac-decrease-indent = Vähenda taanet
mac-increase-indent = Suurenda taanet
mac-hyperlink = Hüperlink
mac-edit-hyperlink = Muuda hüperlinki
mac-hyperlink-intro = Aadress, millele valitud tekst viitab.
mac-edit-hyperlink-intro = Kuhu link viib. Lingi eemaldamiseks ja selle teksti alles jätmiseks tühjendage aadress.
mac-link-address = Aadress:
mac-link-invalid = Sisestage veebiaadress (https://...) või e-posti link (mailto:...).
mac-horizontal-line = Lisa horisontaaljoon
mac-insert-picture = Lisa pilt
mac-not-a-picture = See fail ei ole PNG-, JPEG- ega GIF-pilt või on suurem kui 10 MB.
mac-bcc = Bcc
mac-new-message = Uus kiri
mac-field-from = Saatja:
mac-field-to = Adressaat:
mac-field-cc = Cc:
mac-field-bcc = Bcc:
mac-field-subject = Teema:
mac-field-attach = Manus:
mac-command-click-to-open = avamiseks ⌘-klõps
mac-remove = Eemalda
mac-insert-attachment = Lisa manus
mac-message-not-sent = Kirja ei saanud saata.
mac-saving-to-drafts = Salvestan mustanditesse…
mac-save-changes-question = Kas salvestada selle kirja muudatused mustanditesse?
mac-save = Salvesta
mac-dont-save = Ära salvesta
mac-saved-in-drafts-at = Salvestatud mustanditesse kell { $time }
mac-not-saved-in-drafts = Ei salvestatud mustanditesse: { $reason }
mac-send = Saada
mac-attach = Manusta
mac-signature = Allkiri
mac-signature-title = Allkiri - { $account }
mac-signature-hint = Lisatakse selle konto uutele kirjadele, vastustele ja edastustele.
mac-signature-not-saved = Allkirja ei saanud salvestada.

## The reading pane

mac-open-in-calendar = Ava kalendris
mac-try-again = Proovi uuesti
mac-pictures-blocked = Mõned pildid on blokeeritud, et saatja ei saaks teie arvutit tuvastada. Piltide allalaadimiseks klõpsake siin.
mac-files =
    { $count ->
        [one] { $count } fail
       *[other] { $count } faili
    }
mac-invitation = Kutse: { $title }
mac-invitation-updated = Muudetud kutse: { $title }
mac-invitation-canceled = Tühistatud: { $title }
mac-invitation-answer = Vastus kutsele: { $title }
mac-no-title = (pealkirjata)
mac-organizer = Korraldaja: { $name }
mac-attendees =
    { $count ->
        [one] { $count } osaleja
       *[other] { $count } osalejat
    }
mac-from-to = { $start } kuni { $end }
mac-senders-time = { $when } (saatja aeg)

## Accounts

mac-security-none = Puudub (krüpteerimata)
mac-field-required = { $field } on kohustuslik.
mac-email-invalid = E-posti aadress ei sobi.
mac-ports-invalid = Pordid on arvud 1 kuni 65535.
mac-plain-warning = Ilma krüpteerimiseta liiguvad teie parool ja post võrgus kõigile teel olijatele loetavalt. Kasutage seda ainult oma arvutis või võrgus oleva serveri jaoks.
mac-continue-question = Kas jätkata?
mac-display-name = Kuvatav nimi:
mac-email-address = E-posti aadress:
mac-user-name = Kasutajanimi:
mac-password = Parool:
mac-imap-server = Sissetulev (IMAP) server:
mac-imap-port = IMAP-port:
mac-imap-security = IMAP-turve:
mac-smtp-server = Väljuv (SMTP) server:
mac-smtp-port = SMTP-port:
mac-smtp-security = SMTP-turve:
mac-sign-in-not-started = Brauseri kaudu sisselogimist ei saanud alustada.
mac-sign-in-waiting = Logige avanenud brauseriaknas sisse kontole { $account } ja tulge siis siia tagasi.
mac-sign-in-waiting-any = Logige avanenud brauseriaknas oma kontole sisse ja tulge siis siia tagasi.
mac-add-mail-account = Lisa e-posti konto
mac-sign-in-did-not-work = Sisselogimine ei õnnestunud: { $reason }
mac-sign-in-with = Logi sisse teenusega { $provider }
mac-next = Edasi
mac-name-placeholder = Mari Maasikas
mac-more-sign-in-options = Rohkem sisselogimisviise…
mac-any-other-account = Mis tahes muu e-posti konto: teie nimi, nagu teised seda näevad, ja teie e-posti aadress. Selle serverid otsitakse järgmisena.
mac-turned-off-named = { $name } on selles arvutis välja lülitatud.
mac-turned-off = Selles arvutis välja lülitatud.
mac-why = Miks?
mac-add-sign-in-app = Lisa sisselogimisrakendus…
mac-type-email = Sisestage oma e-posti aadress, nimi@example.com.
mac-found-none = Sisestage konto andmed, mille teie e-posti teenusepakkuja andis.
mac-found-change = Muutke neid, kui teenusepakkuja andis teile teised.
mac-found-guess = Selle aadressi jaoks ei leitud seadeid: need on tavalised nimed, kontrollige neid oma teenusepakkujalt.
mac-found-mx = Teie posti haldab teenusepakkuja, keda Inbox Classic tunneb; need on tema serverid.
mac-found-srv = Need seaded leiti teie domeeni DNS-kirjetest.
mac-found-autodiscover = Need seaded leidis Microsoft Autodiscover (Exchange).
mac-found-other = Need seaded leiti selle aadressi jaoks.
mac-app-password-needed = { $provider } ei võta e-posti programmides vastu teie tavalist parooli. Looge oma { $provider } kontol rakenduse parool ja sisestage see järgmise vormi väljale Parool.
mac-open-instructions = Kas avada { $provider } juhised brauseris?
mac-account-not-saved = Kontot ei saanud salvestada.
mac-start-intro = Gmail, Google Workspace, Outlook.com ja Microsoft 365: logige sisse Google'i või Microsofti enda lehel. Parool sisestatakse seal, mitte kunagi Inbox Classicusse.
mac-start-intro-apps = Logige brauseri kaudu sisse mõne oma sisselogimisrakendusega (Rohkem sisselogimisviise) või lisage allpool mis tahes e-posti konto oma nime ja aadressiga.
mac-looking-up = Otsin domeeni { $domain } seadeid…
mac-use-app-password = Kasuta rakenduse parooli
mac-the-provider = teenusepakkuja
mac-signs-in-at = { $email } logib sisse teenuse { $provider } enda lehel, ilma et annaksite Inbox Classicule oma parooli. Või kasutage konto turvaseadetes loodud rakenduse parooli.
mac-can-sign-in-at = { $email } saab teenuse { $provider } enda lehel sisse logida mõne teie sisselogimisrakendusega (Rohkem sisselogimisviise). Või kasutage konto turvaseadetes loodud rakenduse parooli.
mac-finish = Lõpeta
mac-logon = Sisselogimine
mac-enter-password = Sisestage konto { $account } parool.
mac-signs-in-with = Logib sisse rakendusega: { $app }. See logib sisse brauseri kaudu ja kasutab oma sisselogimise servereid.
mac-keep-password = Praeguse parooli säilitamiseks jätke parool tühjaks.
mac-accounts = Kontod
mac-column-email = E-posti aadress
mac-column-incoming = Sissetulev server
mac-add-button = Lisa…
mac-properties-button = Atribuudid…
mac-signature-button = Allkiri…
mac-sign-in-apps-button = Sisselogimisrakendused…
mac-browser-sign-in = { $server } (sisselogimine brauseris)
mac-remove-account = Eemalda konto
mac-remove-account-question = Kas eemaldada see konto Inbox Classicust? Selle post jääb serverisse; selles arvutis olev koopia ja salvestatud parool eemaldatakse.

## AI agents

mac-ai-agent = Tehisintellekti agent
mac-allow = Luba
mac-dont-allow = Ära luba
mac-program-path = Programm: { $path }
mac-it-may = See tohib:
mac-accounts-it-may-use = Kontod, mida see tohib kasutada:
mac-new-address = Uus aadress
mac-send-message-question = Kas saata kiri?
mac-edit-first = Muuda enne
mac-dont-send = Ära saada
mac-let-agents-connect = Luba tehisintellekti agentidel Inbox Classicuga ühenduda
mac-change-button = Muuda…
mac-undo-button = Võta tagasi
mac-clear = Tühjenda
mac-ai-agents = Tehisintellekti agendid
mac-column-program = Programm
mac-column-may = Tohib
mac-column-last-used = Viimati kasutatud
mac-column-when = Millal
mac-column-what = Mida
mac-how-to-connect = Kuidas agenti ühendada…
mac-agent-programs = Programmid, mille agendid soovisid teie posti kasutada
mac-agent-log = Mida agendid tegid
mac-never = Mitte kunagi
mac-ai-agent-access = Tehisintellekti agendi juurdepääs
mac-turn-away = Keeldu
mac-forget-program = Kas unustada see programm ja see, mida selle agendid tegid?
mac-forget-program-detail = Seda küsitakse uuesti, kui see järgmine kord ühendub.
mac-clear-log = Kas tühjendada nimekiri sellest, mida agendid tegid?
mac-clear-log-detail = Mida nad tegid, jääb tehtuks.
mac-connect-agent = Ühenda tehisintellekti agent
mac-connect-agent-intro = Lisage see oma agendi MCP-serverite hulka (Claude Desktop: Settings > Developer > Edit Config):

## Sign-in apps

mac-secret-saved = Saladus on salvestatud; selle asendamiseks sisestage uus või eemaldage see
mac-add-sign-in-app-title = Lisa sisselogimisrakendus
mac-sign-in-app = Sisselogimisrakendus
mac-sign-in-apps = Sisselogimisrakendused
mac-sign-in-app-intro = OAuth-klient, mille registreerisite oma teenusepakkuja juures, brauseri kaudu sisse logivate kontode jaoks. Täitke see teenusepakkuja jaoks ja lisage siis kliendi ID (ja saladus, kui teenusepakkuja selle andis).
mac-check = Kontrolli
mac-fill-in-for = Täida teenusele:
mac-app-name = Nimi:
mac-issuer = Väljastaja:
mac-client-id = Kliendi ID:
mac-client-secret = Kliendi saladus:
mac-scopes = Ulatused:
mac-app-imap-server = IMAP-server:
mac-app-smtp-server = SMTP-server:
mac-register-it = Registreerige see oma teenusepakkuja juures
mac-redirect-uri = Ümbersuunamise URI:
mac-preset-app-name = { $provider } sisselogimisrakendus
mac-issuer-not-checked = väljastajat ei saa kontrollida
mac-checking-issuer = Kontrollin: { $issuer }…
mac-issuer-usable = Väljastajat saab kasutada.
mac-issuer-not-usable = Väljastajat ei saa kasutada: { $reason }
mac-sign-in-app-not-saved = Sisselogimisrakendust ei saanud salvestada: { $reason }
mac-edit-button = Muuda…
mac-column-name = Nimi
mac-column-issuer = Väljastaja
mac-column-used-by = Kasutab
mac-sign-in-apps-intro = Sisselogimisrakendustega logivad kontod sisse brauseri kaudu. Märkimata rakendust uutele kontodele ei pakuta; kontod, mis seda juba kasutavad, töötavad edasi.
mac-use-for-new-accounts = Kasuta rakendust { $name } uute kontode jaoks
mac-built-in = { $name } (sisseehitatud)
mac-no-accounts = Kontosid pole
mac-built-in-note = { $name } on sisseehitatud: muuta saab ainult seda, kas seda kasutatakse uute kontode jaoks.
mac-client-with-secret = Kliendi ID: { $client }, kliendi saladusega.
mac-client-public = Kliendi ID: { $client }, avalik klient (saladuseta).
mac-remove-sign-in-app = Eemalda sisselogimisrakendus
mac-remove-sign-in-app-question = Kas eemaldada sisselogimisrakendus { $name } ja selle salvestatud kliendi saladus?
mac-sign-in-app-not-removed = Sisselogimisrakendust ei eemaldatud: { $reason }

## Other windows

mac-find-folder = Otsi kausta
mac-new-folder-button = Uus kaust…
mac-new-folder-in = Uus kaust tuleb kausta { $folder } sisse.
mac-send-all-now = Saada kõik kohe
mac-outbox = Väljundkaust
mac-column-queued = Järjekorras alates
mac-column-status = Olek
mac-not-sent = Saatmata: { $reason }
mac-agent-goes-at = Saatis tehisintellekti agent; läheb teele kell { $time }
mac-waiting = Ootab
mac-delete-unsent = Kas kustutada see kiri seda saatmata?
mac-open-link = Ava link
mac-edit-link = Muuda linki…
mac-remove-link = Eemalda link
mac-help-missing = Selles Inbox Classicu koopias puudub abi.
