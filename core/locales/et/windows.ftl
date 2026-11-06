# Windowsi rakenduse akende sõnad (app/src), tunnused algavad win-. Rakendus täidab { $sulgudes } kohad; & märgib
# menüüelemendi või nupu tähte (&& on ampersand).

## Põhiaken

win-tb-create-mail = Uus kiri
win-tb-reply = Vasta
win-tb-reply-all = Vasta kõigile
win-tb-forward = Edasta
win-tb-print = Prindi
win-tb-delete = Kustuta
win-tb-junk = Rämps
win-tb-not-junk = Pole rämps
win-tb-sync = Saada/Võta vastu
win-tb-mark-read = Loetud
win-tb-mark-unread = Lugemata
win-flag-menu = &Lipp
win-still-running = Inbox Classic töötab edasi
win-still-running-detail = See kontrollib siin edasi uusi kirju. Avamiseks klõpsake ikooni, sulgemiseks paremklõpsake seda.
win-no-subject = (teemata)
win-quoted = „{ $subject }“
win-new-messages = { $count ->
    [one] { $count } uus kiri
   *[other] { $count } uut kirja
}
win-newest-from = Uusim saatjalt { $sender }: { $subject }
win-outbox-waiting = { $count ->
    [one] { $count } kiri väljundkaustas
   *[other] { $count } kirja väljundkaustas
}
win-outbox-waits = { $subject } ootab väljundkaustas
win-outbox-sending = Saadetakse { $subject }...
win-from-account = Kontolt { $account }
win-sign-in-refused = Konto { $account } sisselogimine lükati tagasi või aegus.
win-sign-in-again-ask = Kas logida brauseris uuesti sisse?
win-sign-in-again-failed = Uuesti sisselogimine ei õnnestunud: { $reason }
win-unknown-reason = tundmatu põhjus
win-checking = Kontrollitakse konto { $account } uusi kirju...
win-done = Valmis
win-sent-at = { $subject } saadeti kell { $time }
win-draft-saved = Kiri salvestati mustanditesse.
win-draft-not-saved = Kirja ei salvestatud mustanditesse: { $reason }
win-about-core = Tuum { $version }
win-add-account-first = Lisage kõigepealt meilikonto.
win-add-account-first-link = Lisage kõigepealt meilikonto ja klõpsake siis uuesti meililinki.
win-default-app-is = Inbox Classic on teie vaikimisi meiliprogramm: meililingid avavad siin uue kirja.
win-default-app-not-installed = Seda Inbox Classicu koopiat pole installitud, seega ei näita Windows seda meiliprogrammina. Selle valimiseks installige see.
win-default-app-settings = Windows avab Inbox Classicu vaikerakenduste sätted. Valige see seal MAILTO jaoks.
win-select-message-first = Valige kõigepealt kiri.
win-store-not-opened = Kirjade hoidlat ei saanud avada.
win-store-or-cert-not-opened = Kirjade hoidlat või sertifikaadifaili ei saanud avada.
win-no-unread = Lugemata kirju pole
win-unread-messages = { $count ->
    [one] { $count } lugemata kiri
   *[other] { $count } lugemata kirja
}
win-help-title = Inbox Classicu spikker
win-help-missing = Selles Inbox Classicu koopias pole spikrit.
win-print-failed = Kirja ei saanud printida.
win-print-title = Prindi
win-print-title-of = Prindi: { $subject }
win-no-bodies = Kirjade sisu ei saa näidata.
win-webview-failed = WebView2 loomine ebaõnnestus.
win-webview-missing = WebView2 käituskeskkond pole saadaval.

## Mitme akna nupud ja sõnad

win-ok = OK
win-cancel = Loobu
win-close = Sulge
win-delete-button = &Kustuta
win-find-label = &Otsi:
win-col-subject = Teema
win-col-to = Saaja
win-col-from = Saatja
win-col-received = Saabunud
win-col-size = Suurus
win-col-folder = Kaust
win-col-account = Konto
win-col-queued = Järjekorras
win-col-status = Olek
win-save-as-button = Salvesta &nimega...
win-too-many-files = Liiga palju faile korraga: valige vähem.

## Väljundkaust

win-outbox-title = Väljundkaust
win-outbox-status-waiting = Ootab
win-outbox-status-not-sent = Saatmata: { $reason }
win-outbox-status-agent = Saatis tehisintellekti agent; läheb teele kell { $time }
win-outbox-delete-ask = Kas kustutada see kiri ilma saatmata?
win-outbox-send-all = &Saada kõik kohe

## Kirjutamise aken

win-editor-failed = Kirju ei saa kirjutada.
win-open-link = Ava link
win-edit-link = Muuda linki...
win-remove-link = Eemalda link
win-ctrl-click-to-open = ({ $ctrl }+klõps avab)
win-insert-attachment = Lisa manus
win-insert-picture = Lisa pilt
win-filter-all = Kõik failid
win-filter-pictures = Pildid
win-filter-messages = Meilikirjad
win-save-attachment-as = Salvesta manus nimega
win-remove-file = &Eemalda
win-not-sent = Kirja ei saanud saata.
win-not-saved = Kirja ei saanud salvestada.
win-saving-draft = Salvestatakse mustanditesse...
win-compose-saved-at = Salvestati mustanditesse kell { $time }
win-compose-not-saved = Mustanditesse ei salvestatud: { $reason }
win-save-changes-ask = Kas salvestada selle kirja muudatused mustanditesse?
win-new-message-title = Uus kiri
win-link-invalid = Sisestage veebiaadress (https://...) või meililink (mailto:...).
win-link-address = Aadress:
win-hyperlink = Hüperlink
win-hyperlink-intro = Aadress, kuhu valitud tekst viitab.
win-edit-hyperlink = Muuda hüperlinki
win-edit-hyperlink-intro = Kuhu link viib. Lingi eemaldamiseks ja teksti alleshoidmiseks tühjendage aadress.
win-not-a-picture = See fail pole PNG-, JPEG- ega GIF-pilt või on suurem kui 10 MB.
win-format-bold = Paks ({ $ctrl }+B)
win-format-italic = Kaldkiri ({ $ctrl }+I)
win-format-underline = Allakriipsutus ({ $ctrl }+U)
win-format-color = Fondi värv
win-format-numbers = Nummerdatud loend
win-format-bullets = Täpploend
win-format-outdent = Vähenda taanet
win-format-indent = Suurenda taanet
win-format-left = Joonda vasakule
win-format-center = Keskele
win-format-right = Joonda paremale
win-format-link = Hüperlink ({ $ctrl }+K)
win-format-line = Lisa horisontaaljoon
win-tb-send = Saada
win-tb-save = Salvesta
win-tb-attach = Manusta
win-field-from = Saatja:
win-field-to = Saaja:
win-field-cc = Koopia:
win-field-bcc = Pimekoopia:
win-field-subject = Teema:
win-field-attach = Manused:
win-show-cc = &Koopia
win-show-bcc = &Pimekoopia
win-signature = Allkiri
win-signature-title = Allkiri: { $account }
win-signature-hint = Lisatakse selle konto uutele kirjadele, vastustele ja edastustele.
win-signature-not-saved = Allkirja ei saanud salvestada.

## Kaustad, kirjade loend ja lugemispaan

win-all-inboxes = Kõik sisendkaustad
win-all-folders = Kõik kaustad
win-the-account = konto
win-folder-name = Kausta nimi:
win-find-hint = Otsi kirjadest
win-find-tip = Leiab sõnu kirjade teemast, inimestest, failinimedest ja tekstist.
win-clear-search = Tühjenda otsing
win-search-found-all = { $count ->
    [0] Päringule „{ $words }“ ei leitud kõigist kaustadest midagi
    [one] { $count } tulemus päringule „{ $words }“ kõigis kaustades
   *[other] { $count } tulemust päringule „{ $words }“ kõigis kaustades
}
win-search-found-in = { $count ->
    [0] Päringule „{ $words }“ ei leitud kaustast { $folder } midagi
    [one] { $count } tulemus päringule „{ $words }“ kaustas { $folder }
   *[other] { $count } tulemust päringule „{ $words }“ kaustas { $folder }
}
win-search-indexing = { $count ->
    [one] { $count } kirja teksti alles indekseeritakse
   *[other] { $count } kirja teksti alles indekseeritakse
}
win-no-match = Päringule „{ $words }“ ei vasta ükski kiri.
win-no-match-all = Otsing vaatab kõigi kaustade kirjade teemat, inimesi, failinimesid ja teksti. Kontrollige õigekirja või proovige vähemate sõnadega.
win-no-match-in = Otsing vaatab kausta { $folder } kirjade teemat, inimesi, failinimesid ja teksti. Kontrollige õigekirja või proovige vähemate sõnadega.
win-no-match-indexing = { $count ->
    [one] { $count } kirja teksti alles indekseeritakse, nii et peagi võib leida rohkem.
   *[other] { $count } kirja teksti alles indekseeritakse, nii et peagi võib leida rohkem.
}
win-no-items = Selles vaates pole üksusi.
win-choose-folder = Kirjade nägemiseks valige kaust.
win-unsubscribe = Loobu tellimusest
win-open-in-calendar = Ava kalendris
win-files = { $count ->
    [one] { $count } fail
   *[other] { $count } faili
}
win-pictures-blocked = Mõned pildid blokeeriti, et saatja ei saaks teie arvutit tuvastada. Piltide allalaadimiseks klõpsake siin.
win-click-to-retry = Uuesti proovimiseks klõpsake siin.
win-not-shown = Kirja ei saanud näidata.
win-save-attachments = &Salvesta manused...
win-attachment-not-read = Manust ei saanud lugeda.
win-attachment-not-saved = Manust ei saanud salvestada.
win-not-downloaded = Kiri pole veel alla laaditud.
win-files-not-saved = { $count } failist { $failed } ei saanud salvestada.
win-leave-list = Kas lahkuda sellest meililistist?
win-leave-one-click = Inbox Classic palub aadressil { $target } selle saatmise lõpetada. Ühtki lehte ei avata ega kirja ei saadeta.
win-leave-mail = List soovib kirja aadressile { $target }. Inbox Classic kirjutab selle teie eest; tellimusest loobumiseks saatke see.
win-leave-web = Listi selleks mõeldud leht avaneb teie brauseris ({ $target }).
win-unsubscribing = Loobutakse tellimusest { $target }...
win-cannot-unsubscribe = Selle kirjaga ei saa tellimusest loobuda.
win-unsubscribed = Tellimusest loobuti. List ütleb, et lõpetab nende kirjade saatmise.
win-not-unsubscribed = Tellimusest ei saanud loobuda: { $reason }
win-event-span = { $start } kuni { $end }
win-event-floating = { $when } (saatja aja järgi)
win-invitation = Kutse: { $title }
win-invitation-updated = Uuendatud kutse: { $title }
win-invitation-canceled = Tühistatud: { $title }
win-invitation-answer = Vastus kutsele: { $title }
win-no-title = (pealkirjata)
win-organizer = Korraldaja: { $name }
win-attendees = { $count ->
    [one] { $count } osaleja
   *[other] { $count } osalejat
}
win-invitation-not-read = Kutset ei saanud lugeda.
win-no-calendar = Ükski selle arvuti kalendriprogramm ei ava kutseid (.ics-faile).
win-messages-not-changed = Kirju ei saanud muuta.
win-copy-button = &Kopeeri
win-move-button = &Teisalda
win-new-folder-in-highlighted = Uus kaust tuleb esiletõstetud kausta.
win-new-folder-in-selected = Uus kaust tuleb valitud kausta.
win-new-folder-at-top = Uus kaust tuleb konto ülemisele tasemele.
win-folder-not-created = Kausta ei saanud luua.
win-folder-not-renamed = Kausta ei saanud ümber nimetada.
win-folder-not-deleted = Kausta ei saanud kustutada.
win-rename-folder-intro = Kausta { $folder } uus nimi.
win-delete-folder-ask = Kas kustutada kaust „{ $folder }“ koos selle kirjade ja kaustadega? See kustutatakse ka serverist.
win-clear-flag = &Eemalda lipp
win-rename = &Nimeta ümber...
win-open = &Ava
win-view-source = Vaata &lähteteksti
win-properties = &Atribuudid
win-properties-of = { $subject }: atribuudid
win-internet-headers = Selle kirja Interneti-päised:
win-save-messages-in = Salvesta kirjad kausta
win-save-message-as = Salvesta kiri nimega
win-messages-not-saved = Kirju ei saanud salvestada.
win-messages-not-forwarded = Kirju ei saanud edastada.
win-import-choose-folder = Valige kõigepealt kaust, kuhu kirjad panna.

## Kontod

win-add-account-title = Lisa meilikonto
win-accounts-title = Kontod
win-security-none = Puudub (krüptimata)
win-field-required = { $field } on kohustuslik.
win-email-invalid = Meiliaadress pole kehtiv.
win-ports-invalid = Pordid on arvud vahemikus 1 kuni 65535.
win-looking-up = Otsitakse domeeni { $domain } sätteid...
win-found-none = Sisestage konto andmed, mille teie meiliteenuse pakkuja andis.
win-found-change = Muutke neid, kui teenusepakkuja andis teile teised.
win-found-guess = Selle aadressi sätteid ei leitud: need on tavalised nimed, kontrollige neid oma teenusepakkujalt.
win-found-mx = Teie kirju haldab teenusepakkuja, keda Inbox Classic tunneb; need on tema serverid.
win-found-srv = Need sätted leiti teie domeeni DNS-kirjetest.
win-found-autodiscover = Need sätted leidis Microsofti automaattuvastus (Exchange).
win-found-other = Need sätted leiti selle aadressi jaoks.
win-app-password-needed = { $provider } ei võta meiliprogrammides vastu teie tavalist parooli. Looge oma { $provider } kontol rakenduse parool ja sisestage see järgmise vormi väljale Parool.
win-app-password-open = Kas avada { $provider } juhised brauseris?
win-plain-warning = Krüptimata liiguvad teie parool ja kirjad võrgus loetavana kõigile teel olijatele. Kasutage seda ainult oma arvutis või võrgus oleva serveri puhul.
win-continue-ask = Kas jätkata?
win-sign-in-google = Logi sisse Google'iga
win-sign-in-microsoft = Logi sisse Microsoftiga
win-add-sign-in-app = Lisa sisselogimisrakendus...
win-turned-off = { $name } on selles arvutis välja lülitatud.
win-off-here = Selles arvutis välja lülitatud.
win-why = Miks?
win-more-sign-in = Muud sisselogimisviisid...
win-next = &Edasi >
win-other-account = Mis tahes muu meilikonto: teie nimi nii, nagu teised seda näevad, ja teie meiliaadress. Selle servereid otsitakse järgmisena.
win-field-name = Kuvatav nimi:
win-field-email = Meiliaadress:
win-field-user = Kasutajanimi:
win-field-password = Parool:
win-field-imap-host = Sissetulevate server (IMAP):
win-field-imap-port = IMAP-port:
win-field-imap-security = IMAP-turve:
win-field-smtp-host = Väljaminevate server (SMTP):
win-field-smtp-port = SMTP-port:
win-field-smtp-security = SMTP-turve:
win-sign-in-not-started = Brauseris sisselogimist ei saanud alustada.
win-your-account = teie konto
win-sign-in-in-browser = Logige avanenud brauseriaknas sisse ({ $account }) ja tulge siis siia tagasi.
win-sign-in-failed = Sisselogimine ei õnnestunud: { $reason }
win-account-not-saved = Kontot ei saanud salvestada.
win-start-intro = Gmail, Google Workspace, Outlook.com ja Microsoft 365: logige sisse Google'i või Microsofti enda lehel. Parool sisestatakse seal, mitte kunagi Inbox Classicusse.
win-start-intro-apps = Logige brauseris sisse mõne oma sisselogimisrakendusega (Muud sisselogimisviisid) või lisage allpool mis tahes meilikonto oma nime ja aadressiga.
win-use-app-password = Kasuta rakenduse parooli
win-the-provider = teenusepakkuja
win-provider-intro = { $email } logib sisse { $provider } enda lehel, ilma et Inbox Classic teie parooli saaks. Või kasutage rakenduse parooli, mis on loodud teie konto turvasätetes.
win-provider-intro-apps = { $email } saab sisse logida { $provider } enda lehel mõne teie sisselogimisrakendusega (Muud sisselogimisviisid). Või kasutage rakenduse parooli, mis on loodud teie konto turvasätetes.
win-finish = Valmis
win-logon = Sisselogimine
win-enter-password = Sisestage konto { $account } parool.
win-browser-sign-in = (brauseris sisselogimine)
win-signs-in-with = Logib sisse rakendusega { $app }. See logib sisse brauseris ja kasutab oma sisselogimise servereid.
win-keep-password = Praeguse parooli säilitamiseks jätke parool tühjaks.
win-remove-account = Eemalda konto
win-remove-account-ask = Kas eemaldada see konto Inbox Classicust? Selle kirjad jäävad serverisse; selle arvuti koopia ja salvestatud parool eemaldatakse.
win-col-email = Meiliaadress
win-col-incoming = Sissetulevate server
win-add = &Lisa...
win-properties-button = &Atribuudid...
win-signature-button = A&llkiri...
win-sign-in-apps-button = &Sisselogimisrakendused...
win-type-email = Sisestage oma meiliaadress, nimi@example.com.

## Tehisintellekti agendid

win-ai-agent = Tehisintellekti agent
win-ai-agent-access = Tehisintellekti agendi juurdepääs
win-ai-agents = Tehisintellekti agendid
win-program-path = Programm: { $path }
win-it-may = See võib:
win-accounts-it-may-use = Kontod, mida see võib kasutada:
win-allow = &Luba
win-dont-allow = Ä&ra luba
win-turn-away = &Keela
win-send-message-ask = Kas saata kiri?
win-col-address = Aadress
win-col-name = Nimi
win-never-written-to = Pole kunagi kirjutanud
win-send = &Saada
win-edit-first = &Muuda enne
win-dont-send = Ä&ra saada
win-never = Mitte kunagi
win-forget-program-ask = Kas unustada see programm ja see, mida selle agendid tegid? Järgmisel ühendumisel küsitakse uuesti.
win-clear-log-ask = Kas tühjendada loend sellest, mida agendid tegid? Mis tehtud, see jääb tehtuks.
win-connect-agent = Ühenda tehisintellekti agent
win-connect-agent-intro = Lisage see oma agendi MCP-serveritele (Claude Desktop: Settings > Developer > Edit Config):
win-let-agents-connect = &Luba tehisintellekti agentidel Inbox Classicuga ühenduda
win-agent-programs = &Programmid, mille agendid soovisid teie kirju kasutada:
win-col-program = Programm
win-col-may = Võib
win-col-last-used = Viimati kasutatud
win-change = &Muuda...
win-what-agents-did = &Mida agendid tegid:
win-col-when = Millal
win-col-what = Mida
win-clear = &Tühjenda
win-how-to-connect = Kuidas agenti ühendada

## Sisselogimisrakendused

win-sign-in-app = Sisselogimisrakendus
win-sign-in-apps = Sisselogimisrakendused
win-add-sign-in-app-title = Lisa sisselogimisrakendus
win-preset-app-name = { $provider } sisselogimisrakendus
win-issuer-not-checked = väljaandjat ei saa kontrollida
win-checking-issuer = Kontrollitakse väljaandjat { $issuer }...
win-issuer-unusable = Väljaandjat ei saa kasutada: { $reason }
win-issuer-usable = Väljaandjat saab kasutada.
win-sign-in-app-not-saved = Sisselogimisrakendust ei saanud salvestada: { $reason }
win-check = Kontrolli
win-check-button = &Kontrolli
win-copy = K&opeeri
win-fill-in-for = Täida:
win-app-name = Nimi:
win-issuer = Väljaandja:
win-client-id = Kliendi ID:
win-client-secret = Kliendi saladus:
win-scopes = Ulatused:
win-imap-server = IMAP-server:
win-smtp-server = SMTP-server:
win-redirect-uri = Ümbersuunamise URI:
win-sign-in-app-intro = OAuth-klient, mille registreerisite oma teenusepakkuja juures, brauseris sisselogivate kontode jaoks. Täitke see teenusepakkuja jaoks ja lisage siis kliendi ID (ja saladus, kui teenusepakkuja selle andis).
win-remove-secret = Saladus on salvestatud; selle asendamiseks sisestage uus või eemaldage see
win-register-it = Registreerige see oma teenusepakkuja juures
win-built-in-note = { $name } on sisseehitatud: muuta saab ainult seda, kas seda kasutatakse uute kontode jaoks.
win-client-with-secret = Kliendi ID: { $client }, kliendi saladusega.
win-client-public = Kliendi ID: { $client }, avalik klient (saladuseta).
win-built-in = (sisseehitatud)
win-no-accounts = Kontosid pole
win-remove-sign-in-app = Eemalda sisselogimisrakendus
win-remove-sign-in-app-ask = Kas eemaldada sisselogimisrakendus { $name } ja selle salvestatud kliendi saladus?
win-sign-in-app-not-removed = Sisselogimisrakendust ei eemaldatud: { $reason }
win-sign-in-apps-intro = Sisselogimisrakendustega logivad kontod brauseris sisse. Märkimata rakendust uutele kontodele ei pakuta; kontod, mis seda juba kasutavad, töötavad edasi.
win-col-issuer = Väljaandja
win-col-used-by = Kasutab
win-edit = &Muuda...

## Suvandid

win-options-language-group = Keel
win-options-language-label = &Inbox Classicu keel:
win-options-system-default = Süsteemi keel ({ $language })
win-options-restart-note = Teise keele näitamiseks taaskäivitub Inbox Classic.
win-options-notify-group = Teavitused
win-options-notify = &Teavita mind uute kirjade saabumisest
win-restart-ask = Inbox Classic näitab valitud keelt ({ $language }) pärast taaskäivitust. Kas taaskäivitada kohe?
win-restart-now = &Taaskäivita kohe
win-restart-later = &Hiljem
