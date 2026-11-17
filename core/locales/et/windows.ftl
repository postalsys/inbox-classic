# Windowsi rakenduse akende sõnad (app/src), tunnused algavad win-. Rakendus täidab { $sulgudes } kohad; & märgib
# menüüelemendi või nupu tähte (&& on ampersand).

## Põhiaken

win-still-running-detail = Inbox Classic kontrollib taustal uute kirjade saabumist. Avamiseks klõpsake ikooni. Väljumiseks avage paremklõpsuga ikooni menüü.
win-default-app-not-installed = Inbox Classic pole installitud, mistõttu ei kuvata seda Windowsi meilirakenduste loendis. Vaikerakenduseks valimiseks installige Inbox Classic.
win-default-app-settings = Windows avab vaikerakenduste sätted. Määrake Inbox Classic seal MAILTO-linkide avamiseks.
win-no-unread = Lugemata kirju pole
win-unread-messages = { $count ->
    [one] { $count } lugemata kiri
   *[other] { $count } lugemata kirja
}
win-print-failed = Kirja ei saanud printida.
win-print-title-of = Prindi: { $subject }
win-no-bodies = Kirjade sisu ei saa kuvada.
win-webview-failed = WebView2 loomine ebaõnnestus.
win-webview-missing = WebView2 käituskeskkond pole saadaval.
# review: new
win-list-loading = Laadimine...

## Mitme akna nupud ja sõnad

win-delete-button = &Kustuta
win-find-label = &Otsi:
win-save-as-button = Salvesta &nimega...
win-too-many-files = Liiga palju faile korraga: valige vähem.

## Väljundkaust


## Kirjutamise aken

win-editor-failed = Kirju ei saa kirjutada.
win-ctrl-click-to-open = ({ $ctrl }+klõps avamiseks)
win-format-bold = Paks kiri ({ $ctrl }+B)
win-format-italic = Kaldkiri ({ $ctrl }+I)
win-format-underline = Allajoonitud ({ $ctrl }+U)
win-format-link = Hüperlink ({ $ctrl }+K)
win-show-cc = &Koopia
win-show-bcc = &Pimekoopia
win-signature-title = Allkiri: { $account }

## Kaustad, kirjade loend ja lugemispaan

win-search-found-all = { $count ->
    [0] Päringule „{ $words }“ ei leitud ühestki kaustast vastet
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
win-no-match-indexing = { $count ->
   *[other] { $count } kirja sisu veel indekseeritakse. Otsingutulemusi võib lisanduda.
}
win-files = { $count ->
    [one] { $count } fail
   *[other] { $count } faili
}
win-click-to-retry = Uuesti proovimiseks klõpsake siin.
win-save-attachments = &Salvesta manused...
win-files-not-saved = { $count } failist { $failed } ei saanud salvestada.
win-new-folder-in-highlighted = Uus kaust luuakse valitud kausta alamkaustana.
win-delete-folder-ask = Kas kustutada kaust „{ $folder }“ koos selle kirjade ja alamkaustadega? Need kustutatakse ka serverist.
win-rename = &Nimeta ümber...
win-messages-not-saved = Kirju ei saanud salvestada.
win-messages-not-forwarded = Kirju ei saanud edastada.

## Kontod

win-sign-in-google = Logi sisse Google'iga
win-sign-in-microsoft = Logi sisse Microsoftiga
win-next = &Edasi >
win-your-account = teie konto
win-browser-sign-in = (brauseris sisselogimine)
win-add = &Lisa...
win-properties-button = &Atribuudid...
win-signature-button = A&llkiri...
win-sign-in-apps-button = &Sisselogimisrakendused...

## Tehisintellekti agendid

win-dont-allow = Ä&ra luba
win-col-address = Aadress
win-never-written-to = Pole kunagi kirjutanud
win-book-find-label = Sisestage nimi või e-posti aadress:
win-send = &Saada
win-dont-send = Ä&ra saada
# review: new
win-unsubscribe = &Loobu tellimusest
# review: new
win-dont-unsubscribe = Ä&ra loobu tellimusest
win-forget-program-ask = Kas eemaldada see programm koos õiguste ja agentide tegevusajalooga? Järgmisel ühendumisel küsitakse juurdepääsuluba uuesti.
win-clear-log-ask = Kas tühjendada agentide tegevusajalugu? See ei võta agentide tehtud muudatusi tagasi.
win-agent-programs = &Programmid, mille agendid on taotlenud juurdepääsu teie e-postile:
win-change = &Muuda...
win-what-agents-did = &Agentide tegevusajalugu:
win-how-to-connect = Kuidas agenti ühendada

## Sisselogimisrakendused

win-built-in = (sisseehitatud)
win-edit = &Muuda...

## Suvandid

win-folders-hide = Peida kaustade loend
win-folders-pin = Kinnita kaustade loend kirjade kõrvale
win-folders-show = Näita kaustu

## The installer

# review: new
win-installer-start = Käivita Inbox Classic
# review: new
win-installer-welcome-new =
    See installib meiliprogrammi Inbox Classic { $version }.

    Administraatori õigusi pole vaja, see installitakse ainult teie kontole.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } on juba installitud. See installib selle uuesti.

    Teie kontod ja kirjad jäävad alles.
# review: new
win-installer-welcome-update =
    See uuendab programmi Inbox Classic versioonist { $installed } versioonile { $version }.

    Kui see töötab, suletakse see enne. Teie kontod ja kirjad jäävad alles.
# review: new
win-installer-older-ask = Installitud on Inbox Classic { $installed }, mis on uuem kui { $version }. Kas installida vanem versioon siiski?
# review: new
win-installer-still-running = Inbox Classic töötab endiselt. Sulgege see ja proovige uuesti.
# review: new
win-installer-remove-mail-ask = Kas eemaldada ka kontod ja kirjad, mida Inbox Classic selles arvutis hoiab? Serverites olevad kirjad jäävad alles.
