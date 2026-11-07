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
folder-archive = Arhiiv

## The reading pane

reader-no-message = Ühtegi kirja pole valitud.
reader-downloading = Kirja laaditakse alla…
reader-downloading-detail = Kiri kuvatakse siin, kui allalaadimine on lõppenud.
reader-failed = Kirja ei saanud alla laadida
reader-failed-network = Meiliserveriga ei saanud ühendust ({ $reason }).
reader-failed-sign-in = Meiliserver lükkas sisselogimise tagasi ({ $reason }). Kontrollige parooli või logige uuesti sisse menüüs Fail > Kontod.
reader-failed-security = Meiliserveriga ei saanud luua turvalist ühendust ({ $reason }).
reader-failed-other = Meiliserver vastas: { $reason }.
reader-retry-note = Kiri on alla laadimata. Allalaadimist proovitakse uuesti, kui ühendus kontoga taastub.
reader-unreadable = Seda kirja ei saa kuvada: { $error }
message-source-title = Kirja lähtekood: { $subject }
message-source-untitled = Kirja lähtekood

## Printing and quoting

header-from = Saatja
header-date = Kuupäev
header-to = Saaja
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
done-read = { $count ->
    [one] { $messages } märgiti loetuks
   *[other] { $messages } märgiti loetuks
}
done-unread = { $count ->
   *[other] { $messages } märgiti mitteloetuks
}
done-flagged = { $count ->
    [one] { $messages } märgiti lipuga
   *[other] { $messages } märgiti lipuga
}
done-unflagged = Lipumärgistus eemaldati: { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } kustutati jäädavalt
   *[other] { $messages } kustutati jäädavalt
}
# review: new
done-archived = { $count ->
   *[other] Arhiveeritud: { $messages }
}
done-moved = { $count ->
   *[other] Teisaldatud: { $messages }. Sihtkoht: { $folder }
}
done-copied = { $count ->
   *[other] Kopeeritud: { $messages }. Sihtkoht: { $folder }
}
done-moving = { $count ->
   *[other] Teisaldatakse: { $messages }. Sihtkoht: { $folder }...
}
done-copying = { $count ->
   *[other] Kopeeritakse: { $messages }. Sihtkoht: { $folder }...
}
done-moved-back = { $count ->
   *[other] Tagasi teisaldatud: { $messages }. Sihtkoht: { $folder }
}
their-folders = vastavad kaustad
undo-move = Võta teisaldamine tagasi
undo-delete = Võta kustutamine tagasi
# review: new
undo-archive = Võta arhiveerimine tagasi
undo-junk = Võta rämpspostiks märkimine tagasi
undo-not-junk = Võta tavapostiks märkimine tagasi
nothing-to-undo = Pole midagi tagasi võtta.
messages-gone = Neid kirju pole enam.
folder-holds-no-messages = Selles kaustas ei saa kirju hoida.
# review: new
not-archived-here = Selle kausta kirju ei saa arhiveerida.
# review: new
not-emptied-here = Tühjendada saab ainult kaustu Kustutatud kirjad ja Rämpspost.
# review: new
empty-question = { $count ->
    [one] Kas tühjendada kaust { $folder }?

        Selles olev kiri kustutatakse jäädavalt. Seda ei saa tagasi tuua.
   *[other] Kas tühjendada kaust { $folder }?

        Selles olevad kirjad ({ $messages }) kustutatakse jäädavalt. Neid ei saa tagasi tuua.
}
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

transfer-moving = Teisaldatakse: { $done } / { $messages }. Sihtkoht: { $folder }...
transfer-copying = Kopeeritakse: { $done } / { $messages }. Sihtkoht: { $folder }...
transfer-another-account = teine konto
transfer-folder-gone = sihtkausta pole enam olemas
transfer-not-on-server = kirja pole enam serveris
transfer-not-moved = { $count ->
   *[other] Teisele kontole teisaldamine ebaõnnestus ({ $messages }): { $reason }
}
transfer-not-copied = { $count ->
   *[other] Teisele kontole kopeerimine ebaõnnestus ({ $messages }): { $reason }
}
transfer-none-moved = Ühtegi kirja ei saanud teisaldada
transfer-none-copied = Ühtegi kirja ei saanud kopeerida

## Messages as files

export-not-in-time = kirja ei saanud õigeks ajaks alla laadida
export-not-saved = Salvestamata: { $failed } (kokku { $messages }). { $problems }
export-not-attached = kirju ei saanud manustada: { $error }
saved-to = { $count ->
    [one] { $messages } salvestati kausta { $folder }
   *[other] { $messages } salvestati kausta { $folder }
}
downloading-messages = { $count ->
   *[other] Allalaadimine: { $messages }...
}
import-put = { $count ->
   *[other] { $messages } imporditi kausta { $folder }
}
import-not-put = Järgmisi kirju ei saanud kausta importida:

    { $problems }

## Problems the windows show

error-store = kohalik kirjahoidla: { $error }
error-not-found = ei leitud
error-closed = suletakse
error-other-account = brauser logis sisse kontole { $email }, mitte sellele kontole
error-in-use = rakendust ei saa eemaldada, sest seda kasutavad järgmised kontod: { $accounts }
error-turned-off = see sisselogimisrakendus on uute kontode jaoks välja lülitatud
error-folder-name = kausta nimi peab olema 1 kuni 200 märki pikk ega tohi sisaldada juhtmärke
error-folder-separator = kausta nimes ei tohi selles serveris olla märki „{ $separator }“
error-folder-special = sisendkausta ja erikaustu ei saa ümber nimetada ega kustutada
error-no-recipients = kirjal pole adressaate
error-bad-address = „{ $address }“ pole e-posti aadress
error-attachment = faili { $path } ei saanud lugeda: { $error }
error-no-drafts = kontol pole mustandite kausta, kuhu kirja salvestada
error-draft-attachment = mustandi manust ei saanud alles hoida: { $error }
error-password-not-saved = parooli ei saanud järgmiseks käivituseks salvestada: { $error }
error-sign-in-not-saved = uusi sisselogimisandmeid ei saanud järgmiseks käivituseks salvestada: { $error }
error-import-unreadable = faili { $path } ei saa lugeda: { $error }
error-import-too-large = { $path } on suurem kui 50 MB
error-import-not-mail = { $path } pole e-kiri
error-list-answered = meililisti server vastas olekukoodiga { $status }
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
error-no-sign-in = selle konto sisselogimisandmed puuduvad
error-provider-missing = see versioon ei saa teenusesse { $provider } sisse logida: kas selle sisselogimisrakendus on eemaldatud?
error-provider-servers = konto serverid ei vasta sisselogimisrakenduse serveritele
error-app-scopes = { $reason }. Meiliserver lükkas sisselogimisrakenduse juurdepääsutõendi tagasi. Kontrollige, kas rakenduse juurdepääsuõigused (scopes) lubavad e-posti kasutada
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google pole Inbox Classicut veel kinnitanud, seega lubab ta sellega sisse logida ainult testkasutajatel. Kasutage oma Google'i sisselogimisrakendust või rakenduse parooli või lülitage see sisse jaotises Sisselogimisrakendused (Fail > Kontod), kui olete testkasutaja.
sign-in-off-other = See lülitati välja jaotises Sisselogimisrakendused (Fail > Kontod), kus selle saab uuesti sisse lülitada.
sign-in-app-no-name = sisselogimisrakendus vajab nime
sign-in-app-no-client = kliendi ID puudub
sign-in-app-no-scopes = sisselogimisrakendusele tuleb määrata e-posti kasutamist lubavad juurdepääsuõigused (scopes)
sign-in-app-bad-host = { $server }-serveri aadress puudub või ei ole kehtiv hostinimi
sign-in-app-plain = { $server }-server peab kasutama SSL/TLS-i või STARTTLS-i
sign-in-app-not-checked = väljaandjat pole veel kontrollitud
sign-in-app-issuer-changed = väljaandja muutus: sisestage kliendi saladus uuesti või eemaldage see
sign-in-register-google = Looge Google Cloud Console'is OAuth-klient tüübiga Desktop app ja lisage selle nõusolekuekraanile juurdepääsuõigus (scope) https://mail.google.com/. Kuni rakendus on testimisel, saavad sisse logida ainult selle testkasutajad.
sign-in-register-microsoft = Registreerige Microsoft Entras rakendus platvormiga Mobile and desktop applications, ümbersuunamise URI-ga http://localhost, lubatud avaliku kliendi voogudega ning delegeeritud õigustega IMAP.AccessAsUser.All, SMTP.Send ja offline_access. Ainult oma organisatsiooni jaoks kasutage väljaandjana aadressi https://login.microsoftonline.com/<rentniku ID>/v2.0.
sign-in-register-other = Registreerige natiivne (avalik) klient allpool oleva ümbersuunamise URI-ga; teenusepakkuja peab lubama sellel mis tahes pordi (RFC 8252). Lisage teenusepakkuja määratud juurdepääsuõigus (scope), mis lubab e-posti kasutada.

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
repeats-times = { $count ->
    [one] { $repeats }, üks kord
   *[other] { $repeats }, { $count } korda
}
day-monday = esmaspäeval
day-tuesday = teisipäeval
day-wednesday = kolmapäeval
day-thursday = neljapäeval
day-friday = reedel
day-saturday = laupäeval
day-sunday = pühapäeval

## AI agents

agent-level-read = Lugeda e-posti: vaadata kaustu ja kirju ning kasutada otsingut
agent-level-organize = Hallata e-posti: märkida kirju loetuks või mitteloetuks, lisada lippe, hallata rämpsposti, teisaldada kirju ja kustutada neid kausta Kustutatud kirjad
agent-level-drafts = Koostada mustandeid, mille saadate ise
agent-level-send = Saata kirju, küsides iga kirja jaoks teie nõusolekut
agent-connect-title = { $program } soovib kasutada teie e-posti
agent-connect-detail = Tehisintellekti agent soovib kasutada Inbox Classicut. Valige, mida agent teha tohib ja millistele kontodele ligi pääseb. Õigusi saate hiljem muuta menüüs Tööriistad > Tehisintellekti agendid.

    Agendid loevad teiste inimeste kirju, mis võivad sisaldada eksitavaid juhiseid. Inbox Classic küsib alati teie nõusolekut, enne kui agent kirja saadab.
agent-reply-to = Vastus kirjale „{ $subject }“
agent-reply-all-on = Vastus kõigile kirja „{ $subject }“ adressaatidele
agent-forward-of = Kirja „{ $subject }“ edastus
agent-never-written-one = Te pole kunagi kirjutanud aadressile { $address }.
agent-never-written-many = Nende saajate hulgas on { $count } aadressi, millele te pole varem kirjutanud.
agent-send-title = { $program } soovib selle kirja saata
agent-send-detail = Kontrollige kirja saajaid ja sisu. Pärast saatmise kinnitamist ootab kiri { $seconds } sekundit väljundkaustas, kust saate selle veel kustutada.
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
agent-original-not-downloaded = kiri, millele vastate, pole veel alla laaditud. Avage see kõigepealt
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
agent-log-unread = „{ $subject }“ märgiti mitteloetuks
agent-log-flagged = „{ $subject }“ märgiti lipuga
agent-log-unflagged = Kirjalt „{ $subject }“ eemaldati lipp
agent-log-deleted = „{ $subject }“ kustutati
agent-log-moved = „{ $subject }“ teisaldati kausta { $folder }
agent-log-junk = „{ $subject }“ märgiti rämpspostiks
agent-log-not-junk = „{ $subject }“ märgiti tavapostiks
# review: new
agent-log-archived = „{ $subject }“ arhiveeriti
agent-log-folder = Loodi kaust „{ $name }“
agent-log-unsubscribed = Loobuti kirja „{ $subject }“ saatnud meililisti tellimusest

## Keys

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = teenusepakkuja ei väljastanud värskendustõendit
sign-in-no-account = teenusepakkuja ei tagastanud sisselogitud konto andmeid
sign-in-not-finished = sisselogimine pole lõppenud
secrets-unavailable = { $store } pole saadaval
secrets-unavailable-why = { $store } pole saadaval: { $error }
secrets-windows = mandaadihaldur
secrets-mac = võtmehoidja
secrets-linux = süsteemi võtmehoidja (Secret Service)
error-no-such-file = sellist faili pole
# review: new
cards-file-too-big = See fail on aadressiraamatu jaoks liiga suur.
