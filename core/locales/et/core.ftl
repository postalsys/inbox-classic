# Eesti. Mustand, ootab emakeelse kõneleja ülevaatust (vt core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] 1 kiri
   *[other] { $count } kirja
}
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 bait
   *[other] { $count } baiti
}
size-kb = { $size } KB
size-mb = { $size } MB
list-counts = { $messages }, { $unread } lugemata
list-counts-selected = { $messages }, { $unread } lugemata, { $selected } valitud
list-counts-found = { $found } leitud, { $unread } lugemata
list-counts-found-selected = { $found } leitud, { $unread } lugemata, { $selected } valitud
list-counts-none = Kirju ei leitud

## Special folders

folder-inbox = Sisendkaust
folder-sent = Saadetud kirjad
folder-deleted = Kustutatud kirjad
folder-drafts = Mustandid
folder-junk = Rämpspost

## The reading pane

reader-no-message = Ühtegi kirja pole valitud.
reader-downloading = Kirja laaditakse alla…
reader-downloading-detail = Kiri kuvatakse siin kohe, kui see on kohale jõudnud.
reader-failed = Kirja ei saanud alla laadida
reader-failed-network = Meiliserveriga ei saanud ühendust ({ $reason }).
reader-failed-sign-in = Meiliserver ei võtnud sisselogimist vastu ({ $reason }). Kontrollige parooli või logige uuesti sisse menüüs Fail > Kontod.
reader-failed-security = Ühendust meiliserveriga ei saanud turvaliseks muuta ({ $reason }).
reader-failed-other = Meiliserver vastas: { $reason }.
reader-retry-note = Alla laadimata. Proovitakse uuesti, kui konto on taas võrgus.
reader-unreadable = Seda kirja ei saa kuvada: { $error }
message-source-title = Kirja lähtekood: { $subject }
message-source-untitled = Kirja lähtekood

## Printing and quoting

header-from = Saatja
header-date = Kuupäev
header-to = Adressaat
header-cc = Koopia
header-sent = Saadetud
header-subject = Teema
quote-original = ----- Algne kiri -----
fold-show-earlier = Näita varasemaid kirju

## Several messages selected

selection-title = { $count ->
    [one] 1 kiri valitud
   *[other] { $count } kirja valitud
}
selection-unread = { $count } lugemata
selection-flagged = { $count } lipuga
delete-for-good-one = See kiri kustutatakse jäädavalt. Kas kustutada?
delete-for-good-all = Need { $count } kirja kustutatakse jäädavalt. Kas kustutada?
delete-for-good-some = { $total } kirjast { $count } kustutatakse jäädavalt. Kas kustutada kirjad?
done-read = { $messages } märgiti loetuks
done-unread = { $messages } märgiti lugemata
done-flagged = { $messages } märgiti lipuga
done-unflagged = { $messages } lipp eemaldati
done-deleted-for-good = { $messages } kustutati jäädavalt
done-moved = { $messages } teisaldati kausta { $folder }
done-copied = { $messages } kopeeriti kausta { $folder }
done-moving = { $messages } teisaldatakse kausta { $folder }...
done-copying = { $messages } kopeeritakse kausta { $folder }...
done-moved-back = { $messages } teisaldati tagasi kausta { $folder }
their-folders = oma kaustadesse
undo-move = Võta teisaldamine tagasi
undo-delete = Võta kustutamine tagasi
undo-junk = Võta rämpspostiks märkimine tagasi
undo-not-junk = Võta mitte-rämpspostiks märkimine tagasi
nothing-to-undo = Pole midagi tagasi võtta.
messages-gone = Neid kirju pole enam.
folder-holds-no-messages = Selles kaustas ei saa kirju hoida.
no-junk-folder = Sellel kontol pole rämpspostikausta, kuhu kirjad teisaldada.
no-inbox-folder = Sellel kontol pole sisendkausta, kuhu kirjad teisaldada.
done-flagged-color = { $messages } märgiti { $color ->
    [red] punase
    [orange] oranži
    [yellow] kollase
    [green] rohelise
    [blue] sinise
    [purple] lilla
   *[gray] halli
} lipuga
flag-color = { $color ->
    [red] Punane
    [orange] Oranž
    [yellow] Kollane
    [green] Roheline
    [blue] Sinine
    [purple] Lilla
   *[gray] Hall
}

## Teisaldamise ja kopeerimise aken

move-window-title-move = { $count ->
    [one] Teisalda kiri
   *[other] Teisalda { $count } kirja
}
move-window-title-copy = { $count ->
    [one] Kopeeri kiri
   *[other] Kopeeri { $count } kirja
}
move-window-prompt-move = { $count ->
    [one] Teisalda valitud kiri kausta:
   *[other] Teisalda { $count } valitud kirja kausta:
}
move-window-prompt-copy = { $count ->
    [one] Kopeeri valitud kiri kausta:
   *[other] Kopeeri { $count } valitud kirja kausta:
}
targets-recent = Viimati kasutatud
target-current = { $folder } (praegune)
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Teisaldatakse { $done }/{ $messages } kausta { $folder }...
transfer-copying = Kopeeritakse { $done }/{ $messages } kausta { $folder }...
transfer-another-account = teine konto
transfer-folder-gone = sihtkausta pole enam olemas
transfer-not-on-server = kirja pole enam serveris
transfer-not-moved = { $messages } ei saanud teise kontosse teisaldada: { $reason }
transfer-not-copied = { $messages } ei saanud teise kontosse kopeerida: { $reason }
transfer-none-moved = Ühtegi kirja ei saanud teisaldada
transfer-none-copied = Ühtegi kirja ei saanud kopeerida

## Messages as files

export-not-in-time = kirja ei saanud õigeks ajaks alla laadida
export-not-saved = { $messages } hulgast ei saanud salvestada { $failed } ({ $problems })
export-not-attached = kirju ei saanud manustada: { $error }
saved-to = { $messages } salvestati kausta { $folder }
downloading-messages = Laaditakse alla { $messages }...
import-put = { $messages } pandi kausta { $folder }
import-not-put = Neid ei pandud kausta:

    { $problems }

## Problems the windows show

error-store = kohalik andmeladu: { $error }
error-not-found = ei leitud
error-closed = suletakse
error-other-account = brauser logis sisse kontole { $email }, mitte sellele kontole
error-in-use = seda ei saa eemaldada, kuni kontod sellega sisse logivad: { $accounts }
error-turned-off = see sisselogimisrakendus on uute kontode jaoks välja lülitatud
error-folder-name = kausta nimi pikkusega 1 kuni 200 märki, ilma juhtmärkideta
error-folder-separator = kausta nimes ei tohi selles serveris olla märki „{ $separator }“
error-folder-special = sisendkausta ja erikaustu ei saa ümber nimetada ega kustutada
error-no-recipients = kirjal pole adressaate
error-bad-address = „{ $address }“ pole e-posti aadress
error-attachment = faili { $path } ei saanud lugeda: { $error }
error-no-drafts = kontol pole mustandite kausta, kuhu kirja salvestada
error-draft-attachment = mustandi manust ei saanud alles hoida: { $error }
error-password-not-saved = parooli ei saanud järgmiseks käivituseks salvestada: { $error }
error-sign-in-not-saved = uut sisselogimist ei saanud järgmiseks käivituseks salvestada: { $error }
error-import-unreadable = faili { $path } ei saa lugeda: { $error }
error-import-too-large = { $path } on suurem kui 50 MB
error-import-not-mail = { $path } pole e-kiri
error-list-answered = postiloend vastas { $status }
error-not-built = kirja ei saanud koostada
error-outbox-waits = { $count ->
    [one] kiri ootab väljundkaustas ja saadetakse järgmise saatmise ja vastuvõtmisega
   *[other] { $count } kirja ootavad väljundkaustas ja saadetakse järgmise saatmise ja vastuvõtmisega
}
error-draft-not-removed = kirja varasemat mustandit ei saanud mustandite kaustast eemaldada: { $reason }
error-sent-but = kiri saadeti, aga { $problem }
error-sent-still-in-outbox = see on endiselt väljundkaustas: { $error }
error-sent-no-copy = koopiat ei saanud saadetud kirjade kausta salvestada: { $reason }
error-no-password = selle konto jaoks pole parooli
error-no-sign-in = selle konto jaoks pole sisselogimist
error-provider-missing = see versioon ei saa teenusesse { $provider } sisse logida: kas selle sisselogimisrakendus on eemaldatud?
error-provider-servers = selle konto serverid pole need, kuhu see sisse logib
error-app-scopes = { $reason }. Meiliserver ei võtnud sisselogimisrakenduse luba vastu: kontrollige, et rakenduse õigused (scopes) annavad juurdepääsu e-postile
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google pole Inbox Classicut veel kinnitanud, seega lubab ta sellega sisse logida ainult testkasutajatel. Kasutage oma Google'i sisselogimisrakendust või rakenduse parooli või lülitage see sisse jaotises Sisselogimisrakendused (Fail > Kontod), kui olete testkasutaja.
sign-in-off-other = See lülitati välja jaotises Sisselogimisrakendused (Fail > Kontod), kus selle saab uuesti sisse lülitada.
sign-in-app-no-name = sisselogimisrakendus vajab nime
sign-in-app-no-client = kliendi ID puudub
sign-in-app-no-scopes = sisselogimisrakendus vajab õigusi (scopes), mis annavad juurdepääsu e-postile
sign-in-app-bad-host = { $server }-server puudub või pole hostinimi
sign-in-app-plain = { $server }-server peab kasutama SSL/TLS-i või STARTTLS-i
sign-in-app-not-checked = väljaandjat pole veel kontrollitud
sign-in-app-issuer-changed = väljaandja muutus: sisestage kliendi saladus uuesti või eemaldage see

## Calendar invitations

repeats = Kordub
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Iga päev
       *[other] Iga { $interval } päeva järel
    }
    [week] { $interval ->
        [one] Iga nädal
       *[other] Iga { $interval } nädala järel
    }
    [month] { $interval ->
        [one] Iga kuu
       *[other] Iga { $interval } kuu järel
    }
   *[year] { $interval ->
        [one] Iga aasta
       *[other] Iga { $interval } aasta järel
    }
}
repeats-on = { $repeats }: { $days }
repeats-times = { $repeats }, { $count } korda
day-monday = esmaspäeval
day-tuesday = teisipäeval
day-wednesday = kolmapäeval
day-thursday = neljapäeval
day-friday = reedel
day-saturday = laupäeval
day-sunday = pühapäeval

## AI agents

agent-level-read = Lugeda e-posti: kaustad, kirjade loend, otsing ja kirjad
agent-level-organize = Korraldada e-posti: lugemise olek, lipud, rämpspost, teisaldamine, kustutamine kausta Kustutatud kirjad
agent-level-drafts = Kirjutada mustandeid, mille teie saadate
agent-level-send = Saata e-posti, iga kiri alles pärast teie nõusolekut
agent-connect-title = { $program } soovib kasutada teie e-posti
agent-connect-detail = Tehisintellekti agent soovib Inbox Classicuga töötada. Valige, mida see teha tohib ja milliseid kontosid näha; saate seda hiljem muuta menüüs Tööriistad > Tehisintellekti agendid.

    Agendid loevad kirju, mida on kirjutanud teised inimesed, ja kiri võib proovida neid petta. Inbox Classic küsib teilt alati enne, kui agent midagi saadab.
agent-reply-to = Vastus kirjale „{ $subject }“
agent-reply-all-on = Vastus kõigile kirjale „{ $subject }“
agent-forward-of = Kirja „{ $subject }“ edastus
agent-never-written-one = Te pole kunagi kirjutanud aadressile { $address }.
agent-never-written-many = Te pole kunagi kirjutanud { $count } aadressile nendest.
agent-send-title = { $program } soovib selle kirja saata
agent-send-detail = Kontrollige, kellele see läheb ja mida see ütleb. Kui saadate selle, ootab see { $seconds } sekundit väljundkaustas, kus saate selle veel kustutada.
agent-change-title = Mida { $program } teha tohib
agent-change-allowed = Muutke, mida selle programmi tehisintellekti agendid teie e-postiga teha tohivad.
agent-change-refused = Te keelasite selle programmi. Lubage see, et selle agendid saaksid jälle teie e-posti kasutada.
agent-log-taken-back = { $entry } (tagasi võetud)
agent-files = Failid: { $files }
agent-undo-refused = Seda ei saa tagasi võtta.
agent-undo-refused-why = Seda ei saa tagasi võtta: { $reason }.
agent-undo-impossible = seda ei saa tagasi võtta
agent-undo-not-in-folder = kiri pole enam selles kaustas
agent-undo-not-arrived = kiri pole (veel) sihtkaustas
agent-undo-sent = kiri on juba saadetud
agent-original-not-downloaded = vastatud kiri pole veel alla laaditud: lugege see kõigepealt läbi
agent-turned-away = Keelatud
agent-can-nothing = Mitte midagi
agent-can-read = lugeda
agent-can-organize = korraldada
agent-can-drafts = mustandeid kirjutada
agent-can-send = teie nõusolekul saata
agent-can-list = { $first } ja { $last }
agent-accounts = { $count ->
    [0] ühtegi kontot
    [one] 1 konto
   *[other] { $count } kontot
}
agent-access = { $can }; { $accounts }
agent-unreadable = Seda kirja ei saa lugeda.
agent-log-composed = „{ $subject }“ avati uues kirjas, et saaksite selle lõpetada
agent-log-refused = Te ei saatnud kirja „{ $subject }“
agent-log-sent = „{ $subject }“ saadeti adressaadile { $to }
agent-log-draft = Mustand „{ $subject }“ salvestati
agent-log-read = „{ $subject }“ märgiti loetuks
agent-log-unread = „{ $subject }“ märgiti lugemata
agent-log-flagged = „{ $subject }“ märgiti lipuga
agent-log-unflagged = Kirjalt „{ $subject }“ eemaldati lipp
agent-log-deleted = „{ $subject }“ kustutati
agent-log-moved = „{ $subject }“ teisaldati kausta { $folder }
agent-log-junk = „{ $subject }“ märgiti rämpspostiks
agent-log-not-junk = „{ $subject }“ märgiti mitte-rämpspostiks
agent-log-folder = Loodi kaust „{ $name }“
agent-log-unsubscribed = Loobuti kirja „{ $subject }“ postiloendist

## Keys

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = teenusepakkuja ei andnud värskendusluba
sign-in-no-account = teenusepakkuja ei öelnud, milline konto sisse logis
sign-in-not-finished = sisselogimine pole lõppenud
secrets-unavailable = { $store } pole saadaval
secrets-unavailable-why = { $store } pole saadaval: { $error }
secrets-windows = mandaadihaldur
secrets-mac = võtmehoidja
secrets-linux = süsteemi võtmehoidja (Secret Service)
error-no-such-file = sellist faili pole
