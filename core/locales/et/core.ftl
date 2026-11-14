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
size-gb = { $size } GB
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
reader-downloading-size = Kirja suurus on { $size }. Kiri kuvatakse siin, kui allalaadimine on lõppenud.
reader-failed = Kirja ei saanud alla laadida
reader-failed-network = Meiliserveriga ei saanud ühendust ({ $reason }).
reader-failed-sign-in = Meiliserver lükkas sisselogimise tagasi ({ $reason }). Kontrollige parooli või logige uuesti sisse menüüs Fail > Kontod.
reader-failed-security = Meiliserveriga ei saanud luua turvalist ühendust ({ $reason }).
reader-failed-other = Meiliserver vastas: { $reason }.
reader-retry-note = Allalaadimist proovitakse uuesti, kui ühendus kontoga taastub.
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

## Tagastatud kirjad: kaart kirja kohal, mis teatab, et kirja ei saanud kätte toimetada

bounce-failed = Teie kirja ei toimetatud kohale
bounce-delayed = Teie kirja pole veel kohale toimetatud
bounce-delayed-note = Teie meiliserver proovib seda endiselt kohale toimetada. Teil pole vaja seda uuesti saata.
bounce-show-message = Näita tagastatud kirja
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Näita kirja, mille kohaletoimetamine viibib
bounce-what-to-do = Mida teha:
bounce-delayed-do = Praegu pole vaja midagi teha. Kui kirja ei õnnestu kohale toimetada, saate uue teate.
bounce-delayed-row-do = Praegu pole vaja midagi teha. Teie meiliserver proovib endiselt kirja kohale toimetada. Kui see ei õnnestu, saate uue teate.
bounce-details = Üksikasjad
bounce-someone = Üks saaja
bounce-server = Server: { $server }
bounce-status = Olek: { $status }
bounce-reported-by = Teatas: { $server }
bounce-retry-minutes = Vastuvõttev server palus enne järgmist katset oodata { $count ->
    [one] üks minut
   *[other] { $count } minutit
}.
bounce-retry-hours = Vastuvõttev server palus enne järgmist katset oodata { $count ->
    [one] üks tund
   *[other] { $count } tundi
}.
bounce-blocklist = Blokeerimisloend: { $lists }
bounce-user-unknown = Seda aadressi pole olemas
bounce-user-unknown-why = Vastuvõtvas serveris pole selle aadressiga postkasti. Aadressis võib olla trükiviga või saaja ei kasuta seda enam.
bounce-user-unknown-do = Kontrollige, kas aadress on õigesti kirjutatud, või küsige saajalt tema praegust e-posti aadressi.
bounce-invalid-address = Aadress pole kehtiv
bounce-invalid-address-why = Aadressi vorming on vigane, mistõttu sellele ei saa kirju saata.
bounce-invalid-address-do = Kontrollige, kas aadressis on üleliigseid tühikuid või puuduvaid tähti ning kas @-märgi järel on domeeninimi.
bounce-mailbox-disabled = Postkast on suletud
bounce-mailbox-disabled-why = Aadress on olemas, kuid selle postkast on välja lülitatud või pole enam kasutusel.
bounce-mailbox-disabled-do = Võtke saajaga muul viisil ühendust ja küsige tema praegust e-posti aadressi.
bounce-mailbox-full = Postkast on täis
bounce-mailbox-full-why = Saaja postkastis pole uute kirjade jaoks ruumi.
bounce-mailbox-full-do = Saatke kiri mõne päeva pärast uuesti või andke saajale muul viisil teada. Suurte manustega kirjad lükatakse tagasi esimesena.
bounce-spam-blocked = Tagasi lükatud rämpspostina
bounce-spam-blocked-why = Vastuvõttev server pidas kirja rämpspostiks.
bounce-spam-blocked-do = Proovige saata kiri uuesti, eemaldades rämpspostile viidata võivad elemendid, näiteks liigsed või lühendatud lingid ja suured manused. Kui probleem kordub, võtke ühendust oma meiliteenuse pakkujaga.
bounce-virus-detected = Tagasi lükatud viiruse tõttu
bounce-virus-detected-why = Vastuvõttev server leidis kirjast või selle manustest viiruse või muu kahjuliku sisu.
bounce-virus-detected-do = Kontrollige manuseid viirusetõrjega. Mõni server lükkab tagasi kõik programmid ja arhiivid, nii et jagage selliseid faile lingina.
bounce-ip-blocklisted = Teie meiliserver on blokeerimisloendis
bounce-ip-blocklisted-why = Vastuvõttev server ei võta vastu kirju serverilt, mis teie kirja saatis, sest selle serveri aadress on blokeerimisloendis.
bounce-ip-blocklisted-do = Viga pole kirjas. Edastage see teade oma e-posti teenusepakkujale ja paluge tal server loendist eemaldada.
bounce-domain-blocklisted = Domeen on blokeerimisloendis
bounce-domain-blocklisted-why = Vastuvõttev server lükkab kirja tagasi, sest teie aadressi domeen või mõni kirja linkides olev domeen on blokeerimisloendis.
bounce-domain-blocklisted-do = Kui kirjas on linke, proovige saata see ilma nendeta. Kui see ei aita või linke pole, edastage see teade oma domeeni e-posti haldajale.
bounce-policy-blocked = Tagasi lükatud vastuvõtva serveri reeglite tõttu
bounce-policy-blocked-why = Vastuvõtva serveri reeglid ei lase seda kirja läbi, näiteks selle suuruse, manuste või saatja tõttu.
bounce-policy-blocked-do = Jaotises „Üksikasjad“ olev serveri vastus selgitab sageli põhjust. Küsige saajalt, kas ta saab selliseid kirju vastu võtta.
bounce-geo-blocked = Tagasi lükatud päritolu tõttu
bounce-geo-blocked-why = Vastuvõttev server ei võta kirju vastu riigist või võrgust, kus teie meiliserver asub.
bounce-geo-blocked-do = Võtke saajaga muul viisil ühendust või küsige abi oma meiliteenuse pakkujalt.
bounce-relay-denied = Server ei saatnud kirja edasi
bounce-relay-denied-why = Server keeldus kirja edasi toimetamast, sageli seetõttu, et see saadeti sisse logimata või serveri kaudu, mis seda saajat ei teeninda.
bounce-relay-denied-do = Kontrollige menüüs Fail > Kontod väljamineva posti serveri sätteid ja veenduge, et serverisse sisselogimine on seadistatud.
bounce-auth-failure = Teie saatja-aadressi ei saanud kinnitada
bounce-auth-failure-why = Vastuvõttev server ei saanud kinnitada, et kiri tuli tõesti teie domeenist (SPF, DKIM või DMARC).
bounce-auth-failure-do = Edastage see teade oma domeeni e-posti haldajale, et ta saaks domeeni sätted parandada. Seni võib aidata saatmine teenusepakkuja enda serveri kaudu.
bounce-rate-limited = Liiga palju kirju korraga
bounce-rate-limited-why = Vastuvõttev server piirab praegu teie meiliserverilt vastuvõetavate kirjade hulka.
bounce-rate-limited-do = Oodake veidi ja saatke kiri uuesti. Kui kirjutate paljudele, saatke korraga vähematele.
bounce-greylisting = Kohaletoimetamine on ajutiselt edasi lükatud
bounce-greylisting-why = Vastuvõttev server palub tundmatutel saatjatel veidi hiljem uuesti proovida. See on levinud rämpspostivastane meede.
bounce-greylisting-do = Midagi pole vaja teha. Meiliserverid proovivad ise uuesti ja kiri jõuab tavaliselt kohale tunni jooksul.
bounce-server-error = Vastuvõtval serveril oli probleem
bounce-server-error-why = Vastuvõtva serveriga ei saanud ühendust või ei saanud see kirja serveripoolse probleemi tõttu vastu võtta.
bounce-server-error-do = Saatke kiri hiljem uuesti. Kui probleem kordub, kontrollige, kas aadressi @-märgi järel olevas domeeninimes on trükivigu.
bounce-unknown = Kohale toimetamata
bounce-unknown-why = Teates pole kohaletoimetamise ebaõnnestumise põhjust selgelt kirjas.
bounce-unknown-do = Lisateavet võib leida jaotises „Üksikasjad“ olevast serveri vastusest. Kui sellest pole abi, edastage see teade oma meiliteenuse pakkujale.

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
    [one] { $messages } märgiti lugemata kirjaks
   *[other] { $messages } märgiti lugemata kirjadeks
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
done-watched = { $count ->
    [one] Vestlust jälgitakse
   *[other] { $count } vestlust jälgitakse
}
done-unwatched = { $count ->
    [one] Vestluse jälgimine lõpetati
   *[other] { $count } vestluse jälgimine lõpetati
}
done-ignored = { $count ->
    [one] Vestlust ignoreeritakse
   *[other] { $count } vestlust ignoreeritakse
}
done-unignored = { $count ->
    [one] Vestluse ignoreerimine lõpetati
   *[other] { $count } vestluse ignoreerimine lõpetati
}
their-folders = vastavad kaustad
undo-move = Võta teisaldamine tagasi
undo-delete = Võta kustutamine tagasi
undo-archive = Võta arhiveerimine tagasi
undo-junk = Võta rämpspostiks märkimine tagasi
undo-not-junk = Võta tavapostiks märkimine tagasi
nothing-to-undo = Pole midagi tagasi võtta.
messages-gone = Neid kirju pole enam.
folder-holds-no-messages = Selles kaustas ei saa kirju hoida.
not-archived-here = Selle kausta kirju ei saa arhiveerida.
not-emptied-here = Tühjendada saab ainult kaustu Kustutatud kirjad ja Rämpspost.
next-unread-question = Kaustas { $folder } pole rohkem lugemata kirju.

    Kas avada järgmine lugemata kirjadega kaust: { $next }?
no-unread-left = Lugemata kirju pole enam.
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
download-progress = Alla laaditud { $done } / { $total }
download-done = Alla laaditud { $size }
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
# a password or sign-in the mail server refused, with the server's words
failure-authentication = server lükkas sisselogimise tagasi ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = ühendus serveriga ebaõnnestus ({ $reason })
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
agent-level-organize = Hallata e-posti: märkida kirju loetuks või lugemata kirjadeks, lisada lippe, hallata rämpsposti, teisaldada kirju ja viia neid kausta Kustutatud kirjad
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
agent-original-not-downloaded = algne kiri pole veel alla laaditud. Avage see kõigepealt
agent-turned-away = Keelatud
agent-can-nothing = Mitte midagi
agent-can-read = lugeda
agent-can-organize = hallata
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
agent-log-composed = Kiri „{ $subject }“ avati koostamisaknas, et saaksite selle valmis kirjutada
agent-log-refused = Te ei saatnud kirja „{ $subject }“
agent-log-sent = „{ $subject }“ saadeti adressaadile { $to }
agent-log-draft = Mustand „{ $subject }“ salvestati
agent-log-read = „{ $subject }“ märgiti loetuks
agent-log-unread = „{ $subject }“ märgiti lugemata kirjaks
agent-log-flagged = „{ $subject }“ märgiti lipuga
agent-log-unflagged = Kirjalt „{ $subject }“ eemaldati lipp
agent-log-deleted = „{ $subject }“ kustutati
agent-log-moved = „{ $subject }“ teisaldati kausta { $folder }
agent-log-junk = „{ $subject }“ märgiti rämpspostiks
agent-log-not-junk = „{ $subject }“ märgiti tavapostiks
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
cards-file-too-big = See fail on aadressiraamatuna importimiseks liiga suur.
ui-sender-added = { $name } lisati aadressiraamatusse.
ui-sender-known = { $name } on juba aadressiraamatus.
ui-sender-none = Selle kirja saatjal pole e-posti aadressi, mida lisada.
card-name-needed = Kontaktil pole nime ega e-posti aadressi.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

otp-heading = Kood saatjalt { $domain }
otp-copy = Kopeeri
otp-note = Sisestage see ainult domeeni { $domain } lehel.
otp-old = See kood saadeti rohkem kui tund enne kirja avamist ja on tõenäoliselt aegunud.

event-attendees =
    { $count ->
        [one] { $count } osaleja
       *[other] { $count } osalejat
    }

otp-notification = { $code } on teie kood domeeni { $domain } jaoks
