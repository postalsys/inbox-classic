# Windowsi rakenduse akende sõnad (app/src), tunnused algavad win-. Rakendus täidab { $sulgudes } kohad; & märgib
# menüüelemendi või nupu tähte (&& on ampersand).

## Põhiaken

win-flag-menu = &Lipp
win-still-running-detail = See kontrollib siin edasi uusi kirju. Avamiseks klõpsake ikooni, sulgemiseks paremklõpsake seda.
win-new-messages = { $count ->
    [one] { $count } uus kiri
   *[other] { $count } uut kirja
}
win-default-app-not-installed = Seda Inbox Classicu koopiat pole installitud, seega ei näita Windows seda meiliprogrammina. Selle valimiseks installige see.
win-default-app-settings = Windows avab Inbox Classicu vaikerakenduste sätted. Valige see seal MAILTO jaoks.
win-no-unread = Lugemata kirju pole
win-unread-messages = { $count ->
    [one] { $count } lugemata kiri
   *[other] { $count } lugemata kirja
}
win-print-failed = Kirja ei saanud printida.
win-print-title-of = Prindi: { $subject }
win-no-bodies = Kirjade sisu ei saa näidata.
win-webview-failed = WebView2 loomine ebaõnnestus.
win-webview-missing = WebView2 käituskeskkond pole saadaval.

## Mitme akna nupud ja sõnad

win-delete-button = &Kustuta
win-find-label = &Otsi:
win-col-to = Saaja
win-save-as-button = Salvesta &nimega...
win-too-many-files = Liiga palju faile korraga: valige vähem.

## Väljundkaust

win-outbox-send-all = &Saada kõik kohe

## Kirjutamise aken

win-editor-failed = Kirju ei saa kirjutada.
win-ctrl-click-to-open = ({ $ctrl }+klõps avab)
win-remove-file = &Eemalda
win-format-bold = Paks ({ $ctrl }+B)
win-format-italic = Kaldkiri ({ $ctrl }+I)
win-format-underline = Allakriipsutus ({ $ctrl }+U)
win-format-link = Hüperlink ({ $ctrl }+K)
win-show-cc = &Koopia
win-show-bcc = &Pimekoopia
win-signature-title = Allkiri: { $account }

## Kaustad, kirjade loend ja lugemispaan

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
win-no-match-indexing = { $count ->
    [one] { $count } kirja teksti alles indekseeritakse, nii et peagi võib leida rohkem.
   *[other] { $count } kirja teksti alles indekseeritakse, nii et peagi võib leida rohkem.
}
win-files = { $count ->
    [one] { $count } fail
   *[other] { $count } faili
}
win-click-to-retry = Uuesti proovimiseks klõpsake siin.
win-save-attachments = &Salvesta manused...
win-files-not-saved = { $count } failist { $failed } ei saanud salvestada.
win-attendees = { $count ->
    [one] { $count } osaleja
   *[other] { $count } osalejat
}
win-copy-button = &Kopeeri
win-move-button = &Teisalda
win-new-folder-in-highlighted = Uus kaust tuleb esiletõstetud kausta.
win-delete-folder-ask = Kas kustutada kaust „{ $folder }“ koos selle kirjade ja kaustadega? See kustutatakse ka serverist.
win-clear-flag = &Eemalda lipp
win-rename = &Nimeta ümber...
win-open = &Ava
win-view-source = Vaata &lähteteksti
win-properties = &Atribuudid
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

win-allow = &Luba
win-dont-allow = Ä&ra luba
win-turn-away = &Keela
win-col-address = Aadress
win-never-written-to = Pole kunagi kirjutanud
win-send = &Saada
win-edit-first = &Muuda enne
win-dont-send = Ä&ra saada
win-forget-program-ask = Kas unustada see programm ja see, mida selle agendid tegid? Järgmisel ühendumisel küsitakse uuesti.
win-clear-log-ask = Kas tühjendada loend sellest, mida agendid tegid? Mis tehtud, see jääb tehtuks.
win-let-agents-connect = &Luba tehisintellekti agentidel Inbox Classicuga ühenduda
win-agent-programs = &Programmid, mille agendid soovisid teie kirju kasutada:
win-change = &Muuda...
win-what-agents-did = &Mida agendid tegid:
win-clear = &Tühjenda
win-how-to-connect = Kuidas agenti ühendada

## Sisselogimisrakendused

win-check-button = &Kontrolli
win-copy = K&opeeri
win-built-in = (sisseehitatud)
win-edit = &Muuda...

## Suvandid

win-options-language-label = &Inbox Classicu keel:
win-options-restart-note = Teise keele näitamiseks taaskäivitub Inbox Classic.
win-options-notify = &Teavita mind uute kirjade saabumisest
win-restart-ask = Inbox Classic näitab valitud keelt ({ $language }) pärast taaskäivitust. Kas taaskäivitada kohe?
win-restart-now = &Taaskäivita kohe
win-restart-later = &Hiljem
