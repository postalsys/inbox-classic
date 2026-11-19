# Lietuvių. Juodraštis, laukia gimtakalbio peržiūros (žr. core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] { $count } laiškas
    [few] { $count } laiškai
   *[other] { $count } laiškų
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] { $count } baitas
    [few] { $count } baitai
   *[other] { $count } baitų
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Išjungta
send-delay-seconds = { $count ->
    [one] { $count } sekundė
    [few] { $count } sekundės
   *[other] { $count } sekundžių
}
# the status bar: "12 laiškų, neskaitytų: 3"
list-counts = { $messages }, neskaitytų: { $unread }
list-counts-selected = { $messages }, neskaitytų: { $unread }, pažymėtų: { $selected }
# the status bar while searching: "Rasta: 12, neskaitytų: 3"
list-counts-found = Rasta: { $found }, neskaitytų: { $unread }
list-counts-found-selected = Rasta: { $found }, neskaitytų: { $unread }, pažymėtų: { $selected }
list-counts-none = Laiškų nerasta

## Special folders, as Outlook names them

folder-inbox = Gauti laiškai
folder-sent = Išsiųsti laiškai
folder-deleted = Panaikinti laiškai
folder-drafts = Juodraščiai
folder-junk = Nepageidaujami laiškai
folder-archive = Archyvas

## The reading pane

reader-no-message = Nepažymėtas joks laiškas.
reader-downloading = Atsisiunčiamas laiškas…
reader-downloading-detail = Laiškas bus parodytas čia, kai atsisiuntimas baigsis.
reader-downloading-size = Laiško dydis: { $size }. Jis bus parodytas čia, kai bus atsisiųstas.
reader-failed = Laiško atsisiųsti nepavyko
reader-failed-network = Nepavyko užmegzti ryšio su pašto serveriu arba ryšys nutrūko ({ $reason }).
reader-failed-sign-in = Pašto serveris atmetė prisijungimą ({ $reason }). Patikrinkite slaptažodį paskyros ypatybėse arba prisijunkite iš naujo lange „Paskyros“.
reader-failed-security = Su pašto serveriu nepavyko užmegzti saugaus ryšio ({ $reason }).
reader-failed-other = Pašto serveris atsakė: { $reason }.
reader-retry-note = Bus bandoma dar kartą, kai paskyra vėl prisijungs.
reader-unreadable = Šio laiško parodyti negalima: { $error }
message-source-title = Laiško šaltinis: { $subject }
message-source-untitled = Laiško šaltinis

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Nuo
header-date = Data
header-to = Kam
header-cc = Kopija
header-sent = Išsiųsta
header-subject = Tema
header-security = Sauga
header-part = { $number } dalis
quote-original = ----- Pradinis laiškas -----
fold-show-earlier = Rodyti ankstesnius laiškus

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Jūsų laiškas nebuvo pristatytas
bounce-delayed = Jūsų laiškas dar nepristatytas
bounce-delayed-note = Jūsų pašto serveris vis dar bando jį pristatyti. Siųsti jo dar kartą nereikia.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Rodyti nepristatytą laišką
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Rodyti vėluojantį laišką
bounce-what-to-do = Ką galite padaryti:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Kol kas nieko. Jei laiško vis tiek nepavyks pristatyti, gausite dar vieną pranešimą.
bounce-delayed-row-do = Kol kas nieko. Jūsų pašto serveris vis dar bando jį pristatyti, o jei nepavyks, gausite dar vieną pranešimą.
# folds the receiving server's own words
bounce-details = Išsami informacija
# a recipient the notice does not name
bounce-someone = Gavėjas
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Serveris: { $server }
bounce-status = Būsena: { $status }
bounce-reported-by = Pranešė: { $server }
bounce-retry-minutes = Gaunantysis serveris paprašė prieš kitą bandymą palaukti { $count ->
    [one] { $count } minutę
    [few] { $count } minutes
   *[other] { $count } minučių
}.
bounce-retry-hours = Gaunantysis serveris paprašė prieš kitą bandymą palaukti { $count ->
    [one] { $count } valandą
    [few] { $count } valandas
   *[other] { $count } valandų
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Juodieji sąrašai: { $lists }
bounce-user-unknown = Tokio adreso nėra
bounce-user-unknown-why = Gaunančiajame serveryje nėra pašto dėžutės šiuo adresu. Adresas gali būti parašytas su klaida, arba žmogus juo nebesinaudoja.
bounce-user-unknown-do = Patikrinkite, ar adresas parašytas teisingai, arba paklauskite žmogaus, kokiu adresu jis dabar naudojasi.
bounce-invalid-address = Adresas netinkamas
bounce-invalid-address-why = Adresas parašytas taip, kad juo negalima išsiųsti laiško.
bounce-invalid-address-do = Ieškokite rašybos klaidų, pavyzdžiui, tarpo, trūkstamos raidės ar tuščios vietos po @.
bounce-mailbox-disabled = Pašto dėžutė uždaryta
bounce-mailbox-disabled-why = Adresas yra, bet jo pašto dėžutė išjungta arba nebenaudojama.
bounce-mailbox-disabled-do = Susisiekite su žmogumi kitu būdu ir paklauskite, kokiu adresu jis dabar naudojasi.
bounce-mailbox-full = Pašto dėžutė pilna
bounce-mailbox-full-why = Gavėjo pašto dėžutėje nebėra vietos naujiems laiškams.
bounce-mailbox-full-do = Išsiųskite laišką dar kartą po kelių dienų arba praneškite gavėjui kitu būdu. Jei laiške yra didelių priedų, pabandykite siųsti be jų.
bounce-spam-blocked = Atmestas kaip brukalas
bounce-spam-blocked-why = Gaunantysis serveris palaikė laišką brukalu.
bounce-spam-blocked-do = Išsiųskite laišką dar kartą be to, kas atrodo kaip brukalas, pavyzdžiui, be daugybės nuorodų, sutrumpintų nuorodų ar didelio priedo. Jei tai kartojasi, kreipkitės į savo pašto paslaugų teikėją.
bounce-virus-detected = Atmestas dėl viruso
bounce-virus-detected-why = Serveris pranešė, kad laiške arba jo prieduose yra virusas ar kitas kenksmingas turinys.
bounce-virus-detected-do = Patikrinkite priedus antivirusine programa. Kai kurie serveriai atmeta visas programas ir archyvus, todėl tokiais failais dalinkitės nuoroda.
bounce-ip-blocklisted = Jūsų pašto serveris yra juodajame sąraše
bounce-ip-blocklisted-why = Gaunantysis serveris nepriima laiškų iš serverio, kuris siuntė jūsiškį, nes to serverio adresas yra juodajame sąraše.
bounce-ip-blocklisted-do = Problema ne laiške. Persiųskite šį pranešimą savo pašto paslaugų teikėjui ir paprašykite, kad serveris būtų išbrauktas iš sąrašo.
bounce-domain-blocklisted = Domenas yra juodajame sąraše
bounce-domain-blocklisted-why = Gaunantysis serveris atmeta laišką, nes jūsų adreso domenas arba domenas iš laiško nuorodų yra juodajame sąraše.
bounce-domain-blocklisted-do = Jei laiške yra nuorodų, pabandykite išsiųsti jį be jų. Kitu atveju persiųskite šį pranešimą tam, kas tvarko jūsų domeno paštą.
bounce-policy-blocked = Atmestas pagal gaunančiojo serverio taisykles
bounce-policy-blocked-why = Gaunančiojo serverio taisyklės šio laiško nepraleidžia, pavyzdžiui, dėl jo dydžio, priedų ar siuntėjo.
bounce-policy-blocked-do = Serverio pateikta informacija skiltyje „Išsami informacija“ dažnai padeda nustatyti priežastį. Paklauskite gavėjo, ar jis gali priimti tokius laiškus.
bounce-geo-blocked = Atmestas dėl kilmės vietos
bounce-geo-blocked-why = Gaunantysis serveris nepriima laiškų iš šalies ar tinklo, kuriame yra jūsų pašto serveris.
bounce-geo-blocked-do = Susisiekite su žmogumi kitu būdu arba kreipkitės į savo pašto paslaugų teikėją.
bounce-relay-denied = Serveris laiško neperdavė
bounce-relay-denied-why = Serveris atsisakė perduoti laišką toliau, dažnai todėl, kad jis išsiųstas neprisijungus arba per serverį, kuris šio gavėjo neaptarnauja.
bounce-relay-denied-do = Atverkite paskyros ypatybes. Patikrinkite siunčiamųjų laiškų serverio nustatymus ir prisijungimo duomenis.
bounce-auth-failure = Jūsų siuntėjo adreso patvirtinti nepavyko
bounce-auth-failure-why = Gaunantysis serveris negalėjo patvirtinti, kad laiškas tikrai atėjo iš jūsų domeno (SPF, DKIM arba DMARC).
bounce-auth-failure-do = Persiųskite šį pranešimą tam, kas tvarko jūsų domeno paštą: reikia pataisyti jo nustatymus. Kol kas gali padėti siuntimas per paties paslaugų teikėjo serverį.
bounce-rate-limited = Per daug laiškų vienu metu
bounce-rate-limited-why = Gaunantysis serveris kol kas priima mažiau laiškų iš jūsų pašto serverio.
bounce-rate-limited-do = Palaukite ir išsiųskite laišką dar kartą. Rašydami daugeliui žmonių, siųskite mažesnėmis grupėmis.
bounce-greylisting = Trumpam sulaikytas
bounce-greylisting-why = Gaunantysis serveris prašo nežinomų siuntėjų pabandyti šiek tiek vėliau. Tai įprasta apsauga nuo brukalo.
bounce-greylisting-do = Jei laiškas dar laukia pristatymo, pašto serveris bandys jį pristatyti dar kartą. Jei gavote galutinį nepristatymo pranešimą, pabandykite išsiųsti laišką vėliau.
bounce-server-error = Gaunančiajame serveryje kilo problema
bounce-server-error-why = Gaunančiojo serverio nepavyko pasiekti arba jis negalėjo priimti laiško dėl savo paties problemos.
bounce-server-error-do = Išsiųskite laišką vėliau. Jei vis nepavyksta, patikrinkite, ar adreso dalyje po @ nėra rašybos klaidų.
bounce-unknown = Nepristatytas
bounce-unknown-why = Pranešime aiškiai nenurodyta, kodėl.
bounce-unknown-do = Daugiau informacijos gali būti skiltyje „Išsami informacija“. Jei ji nepadeda, persiųskite šį pranešimą savo pašto paslaugų teikėjui.

## Several messages selected

selection-title = { $count ->
    [one] Pažymėtas { $count } laiškas
    [few] Pažymėti { $count } laiškai
   *[other] Pažymėta { $count } laiškų
}
selection-unread = { $count ->
    [one] { $count } neskaitytas
    [few] { $count } neskaityti
   *[other] { $count } neskaitytų
}
selection-flagged = { $count ->
    [one] { $count } su vėliavėle
    [few] { $count } su vėliavėlėmis
   *[other] { $count } su vėliavėlėmis
}
delete-for-good-one = Šis laiškas bus panaikintas visam laikui. Panaikinti jį?
delete-for-good-all = Visam laikui bus panaikinta laiškų: { $count }. Panaikinti juos?
delete-for-good-some = Visam laikui bus panaikinta laiškų: { $count } iš { $total }. Panaikinti laiškus?
done-read = { $count ->
   *[other] Pažymėta kaip skaityti: { $messages }
}
done-unread = { $count ->
   *[other] Pažymėta kaip neskaityti: { $messages }
}
done-flagged = { $count ->
   *[other] Pažymėta vėliavėle: { $messages }
}
done-unflagged = Vėliavėlė nuimta: { $messages }
done-deleted-for-good = { $count ->
   *[other] Visam laikui panaikinta: { $messages }
}
done-archived = { $count ->
   *[other] Archyvuota: { $messages }
}
done-moved = { $count ->
   *[other] Perkelta: { $messages } (paskirtis: { $folder })
}
done-copied = { $count ->
   *[other] Nukopijuota: { $messages } (paskirtis: { $folder })
}
done-moving = { $count ->
   *[other] Perkeliama: { $messages } (paskirtis: { $folder })...
}
done-copying = { $count ->
   *[other] Kopijuojama: { $messages } (paskirtis: { $folder })...
}
done-moved-back = { $count ->
   *[other] Grąžinta: { $messages } (paskirtis: { $folder })
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Stebimas { $count } pokalbis
    [few] Stebimi { $count } pokalbiai
   *[other] Stebima { $count } pokalbių
}
done-unwatched = { $count ->
    [one] Nebestebimas { $count } pokalbis
    [few] Nebestebimi { $count } pokalbiai
   *[other] Nebestebima { $count } pokalbių
}
done-ignored = { $count ->
    [one] Ignoruojamas { $count } pokalbis
    [few] Ignoruojami { $count } pokalbiai
   *[other] Ignoruojama { $count } pokalbių
}
done-unignored = { $count ->
    [one] Nebeignoruojamas { $count } pokalbis
    [few] Nebeignoruojami { $count } pokalbiai
   *[other] Nebeignoruojama { $count } pokalbių
}
their-folders = jų aplankai
undo-move = Atšaukti perkėlimą
undo-delete = Atšaukti panaikinimą
undo-archive = Atšaukti archyvavimą
undo-junk = Atšaukti žymėjimą nepageidaujamu
undo-not-junk = Atšaukti žymėjimą pageidaujamu
undo-send = Atšaukti siuntimą
nothing-to-undo = Nėra ko atšaukti.
messages-gone = Šių laiškų nebėra.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Šiame aplanke negali būti laiškų.
not-archived-here = Šiame aplanke esančių laiškų archyvuoti negalima.
not-emptied-here = Išvalyti galima tik aplankus „Panaikinti laiškai“ ir „Nepageidaujami laiškai“.
next-unread-question = Aplanke „{ $folder }“ neskaitytų laiškų nebėra.

    Pereiti į kitą aplanką su neskaitytais laiškais: „{ $next }“?
no-unread-left = Neskaitytų laiškų nebeliko.
empty-question = { $count ->
    [1] Išvalyti aplanką „{ $folder }“?

        Jame esantis laiškas bus panaikintas visam laikui. Jo atkurti nebus galima.
   *[other] Išvalyti aplanką „{ $folder }“?

        Visam laikui bus panaikinta: { $messages }. Šių laiškų atkurti nebus galima.
}
no-junk-folder = Šioje paskyroje nėra aplanko „Nepageidaujami laiškai“, į kurį būtų galima perkelti laiškus.
no-inbox-folder = Šioje paskyroje nėra aplanko „Gauti laiškai“, į kurį būtų galima perkelti laiškus.
# the status bar after a flag in a colour: "2 laiškai: pažymėta mėlyna vėliavėle"
done-flagged-color = { $messages }: pažymėta { $color ->
    [red] raudona vėliavėle
    [orange] oranžine vėliavėle
    [yellow] geltona vėliavėle
    [green] žalia vėliavėle
    [blue] mėlyna vėliavėle
    [purple] violetine vėliavėle
   *[gray] pilka vėliavėle
}
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Raudona
    [orange] Oranžinė
    [yellow] Geltona
    [green] Žalia
    [blue] Mėlyna
    [purple] Violetinė
   *[gray] Pilka
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Perkelti { $count } laišką
    [few] Perkelti { $count } laiškus
   *[other] Perkelti { $count } laiškų
}
move-window-title-copy = { $count ->
    [one] Kopijuoti { $count } laišką
    [few] Kopijuoti { $count } laiškus
   *[other] Kopijuoti { $count } laiškų
}
move-window-prompt-move = { $count ->
    [one] Perkelti { $count } pažymėtą laišką į:
    [few] Perkelti { $count } pažymėtus laiškus į:
   *[other] Perkelti { $count } pažymėtų laiškų į:
}
move-window-prompt-copy = { $count ->
    [one] Kopijuoti { $count } pažymėtą laišką į:
    [few] Kopijuoti { $count } pažymėtus laiškus į:
   *[other] Kopijuoti { $count } pažymėtų laiškų į:
}
# the folders used last, over the folder tree
targets-recent = Neseniai naudoti
# the folder the messages are in, which can not be chosen
target-current = { $folder } (dabartinis)
# a folder used last, with its account when there are several: "Archyvas (Darbas)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Perkeliamas laiškas Nr. { $done } (iš viso: { $messages }; paskirtis: { $folder })...
transfer-copying = Kopijuojamas laiškas Nr. { $done } (iš viso: { $messages }; paskirtis: { $folder })...
transfer-another-account = kita paskyra
transfer-folder-gone = paskirties aplanko nebėra
transfer-not-on-server = laiško serveryje nebėra
transfer-not-moved = { $count ->
   *[other] Nepavyko perkelti į kitą paskyrą: { $messages } ({ $reason })
}
transfer-not-copied = { $count ->
   *[other] Nepavyko nukopijuoti į kitą paskyrą: { $messages } ({ $reason })
}
transfer-none-moved = Nepavyko perkelti nė vieno laiško
transfer-none-copied = Nepavyko nukopijuoti nė vieno laiško

## Messages as files

export-not-in-time = laiško nepavyko laiku atsisiųsti
export-not-saved = Nepavyko įrašyti: { $failed }. Iš viso: { $messages }. Priežastys: { $problems }
export-not-attached = laiškų nepavyko pridėti: { $error }
# the status bar after Save As with several: "Įrašyta: 3 laiškai (paskirtis: Darbalaukis)"
saved-to = { $count ->
   *[other] Įrašyta: { $messages } (paskirtis: { $folder })
}
download-progress = Atsisiunčiama: { $done } (iš viso: { $total })
download-done = Atsisiųsta: { $size }
downloading-messages = { $count ->
   *[other] Atsisiunčiama: { $messages }...
}
# the status bar after files are dropped on a folder: "Įdėta: 3 laiškai (paskirtis: Archyvas)"
import-put = { $count ->
   *[other] Importuojama: { $messages } (paskirtis: { $folder })
}
import-not-put = Šių failų importuoti nepavyko:

    { $problems }

## Problems the windows show

error-store = vietinė saugykla: { $error }
error-not-found = nerasta
error-closed = baigiamas darbas
error-other-account = naršyklėje prisijungta prie kitos paskyros: { $email }
# a password or sign-in the mail server refused, with the server's words
failure-authentication = serveris atmetė prisijungimą ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = nepavyko užmegzti ryšio su serveriu arba ryšys nutrūko ({ $reason })
error-in-use = prisijungimo programos pašalinti negalima, kol ją naudoja šios paskyros: { $accounts }
error-turned-off = ši prisijungimo programa naujoms paskyroms išjungta
error-folder-name = aplanko pavadinimas turi būti nuo 1 iki 200 simbolių ilgio ir negali turėti valdymo simbolių
error-folder-separator = šiame serveryje aplanko pavadinime negali būti „{ $separator }“
error-folder-special = aplanko „Gauti laiškai“ ir specialiųjų aplankų pervardyti ar panaikinti negalima
error-no-recipients = nenurodyti laiško gavėjai
error-bad-address = „{ $address }“ nėra el. pašto adresas
error-not-own-address = { $address } nėra vienas iš šios paskyros siuntėjo adresų. Įtraukite jį į lauką „Kiti adresai, iš kurių siunčiate“ paskyros ypatybėse.
rule-query-refused = Taisyklės negali filtruoti pagal aplanką ar datą ({ $words }).
rule-no-query = Įveskite gaunamų laiškų paieškos kriterijus.
rule-no-action = Pasirinkite bent vieną taisyklės veiksmą.
error-attachment = Nepavyko perskaityti failo „{ $path }“: { $error }
error-no-drafts = paskyroje nėra aplanko „Juodraščiai“, į kurį būtų galima įrašyti laišką
error-draft-attachment = nepavyko išsaugoti juodraščio priedo: { $error }
error-password-not-saved = nepavyko įrašyti slaptažodžio kitam paleidimui: { $error }
error-sign-in-not-saved = nepavyko įrašyti naujų prisijungimo duomenų kitam paleidimui: { $error }
error-import-unreadable = Nepavyko perskaityti failo „{ $path }“: { $error }
error-import-too-large = Failas „{ $path }“ yra didesnis nei 50 MB
error-import-not-mail = Failas „{ $path }“ nėra el. laiškas
error-list-answered = adresatų sąrašo serveris atsakė būsenos kodu { $status }
error-not-built = laiško nepavyko sudaryti
error-outbox-waits = aplanke „Siunčiami laiškai“ laukia { $count ->
    [one] { $count } laiškas
    [few] { $count } laiškai
   *[other] { $count } laiškų
}. Kitą kartą siunčiant ir gaunant paštą bus bandoma siųsti dar kartą
error-draft-not-removed = ankstesnio laiško juodraščio nepavyko pašalinti iš aplanko „Juodraščiai“: { $reason }
error-sent-but = laiškas išsiųstas, bet { $problem }
error-sent-still-in-outbox = jis vis dar yra aplanke „Siunčiami laiškai“: { $error }
error-sent-no-copy = nepavyko įrašyti kopijos į aplanką „Išsiųsti laiškai“: { $reason }
error-no-password = šiai paskyrai nėra slaptažodžio
error-no-sign-in = šiai paskyrai nėra prisijungimo duomenų
error-provider-missing = nepavyko rasti prisijungimo programos šiam teikėjui: { $provider }. Patikrinkite, ar prisijungimo programa nepašalinta
error-provider-servers = šios paskyros serveriai nesutampa su jos prisijungimo programos serveriais
error-app-scopes = { $reason }. Pašto serveris nepriėmė prisijungimo programos prieigos rakto: patikrinkite, ar programos teisės (scopes) suteikia prieigą prie pašto
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google dar nepatvirtino šios Inbox Classic prisijungimo programos, todėl ja gali naudotis tik bandomųjų naudotojų sąraše esančios paskyros. Naudokite savo Google prisijungimo programą arba, jei jūsų paskyrai leidžiama, programos slaptažodį. Jei esate bandomasis naudotojas, lange „Paskyros“ atverkite „Prisijungimo programos“ ir įjunkite šią programą.
sign-in-off-other = Ši prisijungimo programa išjungta. Lange „Paskyros“ atverkite „Prisijungimo programos“ ir galėsite ją vėl įjungti.
sign-in-app-no-name = prisijungimo programai reikia pavadinimo
sign-in-app-no-client = nenurodytas tinkamas kliento ID
sign-in-app-no-scopes = prisijungimo programai reikia teisių (scopes), kurios suteikia prieigą prie pašto
sign-in-app-bad-host = nenurodytas tinkamas { $server } serverio adresas arba prievadas
sign-in-app-plain = { $server } serveris turi naudoti SSL/TLS arba STARTTLS
sign-in-app-not-checked = išdavėjas dar nepatikrintas
sign-in-app-issuer-changed = išdavėjas pasikeitė: įveskite kliento paslaptį dar kartą arba ją pašalinkite
sign-in-register-google = Google Cloud Console sukurkite „Desktop app“ tipo OAuth klientą. Sutikimo nustatymuose pridėkite prieigos teisę https://mail.google.com/. Kol programa veikia bandymo režimu, prisijungti gali tik į bandomųjų naudotojų sąrašą įtrauktos paskyros.
sign-in-register-microsoft = Microsoft Entra užregistruokite programą, pasirinkę platformą „Mobile and desktop applications“ ir peradresavimo URI http://localhost. Leiskite viešojo kliento prisijungimą ir suteikite deleguotąsias teises IMAP.AccessAsUser.All, SMTP.Send bei offline_access. Jei programa skirta tik jūsų organizacijai, išdavėjo laukelyje nurodykite https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Užregistruokite kompiuteryje veikiančios programos viešąjį OAuth klientą su toliau nurodytu peradresavimo URI. Paslaugų teikėjas turi leisti šiame vietiniame adrese naudoti bet kurį prievadą (RFC 8252). Pridėkite teikėjo nurodytą prieigos prie pašto teisę.

## Calendar invitations

repeats = Kartojasi
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Kasdien
        [one] Kas { $interval } dieną
        [few] Kas { $interval } dienas
       *[other] Kas { $interval } dienų
    }
    [week] { $interval ->
        [1] Kas savaitę
        [one] Kas { $interval } savaitę
        [few] Kas { $interval } savaites
       *[other] Kas { $interval } savaičių
    }
    [month] { $interval ->
        [1] Kas mėnesį
        [one] Kas { $interval } mėnesį
        [few] Kas { $interval } mėnesius
       *[other] Kas { $interval } mėnesių
    }
   *[year] { $interval ->
        [1] Kasmet
        [one] Kas { $interval } metus
        [few] Kas { $interval } metus
       *[other] Kas { $interval } metų
    }
}
# "Kas savaitę: pirmadienis, trečiadienis"
repeats-on = { $repeats }: { $days }
# "Kas savaitę, 10 kartų"
repeats-times = { $count ->
    [one] { $repeats }, { $count } kartą
    [few] { $repeats }, { $count } kartus
   *[other] { $repeats }, { $count } kartų
}
day-monday = pirmadienis
day-tuesday = antradienis
day-wednesday = trečiadienis
day-thursday = ketvirtadienis
day-friday = penktadienis
day-saturday = šeštadienis
day-sunday = sekmadienis

## AI agents

agent-level-read = Skaityti paštą: peržiūrėti aplankus, laiškus ir pokalbius, ieškoti laiškų bei kontaktų ir peržiūrėti laiškų taisykles
agent-level-organize = Tvarkyti paštą: žymėti laiškus skaitytais ar neskaitytais, keisti vėliavėles, jų spalvas ir nepageidaujamų laiškų žymas, perkelti ir archyvuoti laiškus, kurti ir pervadinti aplankus, stebėti ir ignoruoti pokalbius, naikinti laiškus perkeliant juos į aplanką „Panaikinti laiškai“ ir jūsų sutikimu atsisakyti adresatų sąrašų prenumeratų
agent-level-drafts = Rašyti juodraščius, kuriuos galėsite išsiųsti
agent-level-send = Siųsti laiškus, kiekvieną tik jums sutikus
agent-connect-title = { $program } nori naudotis jūsų paštu
agent-connect-detail = DI agentas prašo prieigos prie jūsų pašto per Inbox Classic. Pasirinkite, ką jis galės daryti ir kurias paskyras galės pasiekti. Šias teises vėliau galėsite pakeisti pasirinkę „Įrankiai > DI agentai“.

    Agentai skaito kitų žmonių laiškus, kuriuose gali būti bandymų juos apgauti. Prieš siųsdamas laišką per Inbox Classic, agentas turi gauti atskirą jūsų sutikimą.
agent-reply-to = Atsakymas į laišką „{ $subject }“
agent-reply-all-on = Atsakymas visiems į laišką „{ $subject }“
agent-forward-of = Laiško „{ $subject }“ persiuntimas
agent-never-written-one = Niekada nerašėte adresu { $address }.
agent-never-written-many = Adresų, kuriais dar nesate rašę, skaičius: { $count }.
agent-send-title = { $program } nori išsiųsti šį laišką
agent-send-detail = Patikrinkite gavėjus ir laiško turinį. Jums patvirtinus, laiškas bent { $seconds } s lauks aplanke „Siunčiami laiškai“. Per tą laiką galėsite jį panaikinti ir atšaukti siuntimą.
agent-change-title = Ką { $program } gali daryti
agent-change-allowed = Pakeiskite, ką šios programos DI agentai gali daryti su jūsų paštu.
agent-change-refused = Šiai programai prieigos nesuteikėte. Galite ją suteikti, kad programos agentai galėtų naudotis jūsų paštu.
agent-log-taken-back = { $entry } (atšaukta)
agent-files = Failai: { $files }
agent-undo-refused = Šio veiksmo atšaukti negalima.
agent-undo-refused-why = Šio veiksmo atšaukti negalima: { $reason }.
agent-undo-impossible = to atšaukti negalima
agent-undo-not-in-folder = laiško tame aplanke nebėra
agent-undo-not-arrived = laiškas dar nerastas paskirties aplanke
agent-undo-sent = laiško aplanke „Siunčiami laiškai“ nebėra
agent-original-not-downloaded = pradinis laiškas dar neatsisiųstas. Pirmiausia jį atidarykite
agent-turned-away = Prieiga uždrausta
agent-can-nothing = Nieko
agent-can-read = skaityti
agent-can-organize = tvarkyti
agent-can-drafts = rašyti juodraščius
agent-can-send = siųsti jums sutikus
# "Skaityti, tvarkyti ir rašyti juodraščius"
agent-can-list = { $first } ir { $last }
agent-accounts = { $count ->
    [0] jokių paskyrų
    [one] { $count } paskyra
    [few] { $count } paskyros
   *[other] { $count } paskyrų
}
# "Skaityti ir tvarkyti; 1 paskyra"
agent-access = { $can }; { $accounts }
agent-unreadable = Šio laiško perskaityti negalima.
agent-encrypted-original = Šis laiškas užšifruotas: agentas negali į jį atsakyti ar jo persiųsti, nes negali šifruoti.
agent-encrypted = Šis laiškas užšifruotas. Agentas negali perskaityti jo turinio. Laišką turi atidaryti naudotojas programoje Inbox Classic.
agent-too-many-changes = Pasiekta vienai programai taikoma paskutinių 30 dienų veiksmų žurnalo riba. Agentas vėl galės atlikti pakeitimus, kai seniausiems įrašams sukaks 30 dienų.
agent-too-many-reads = Pasiekta vienai programai taikoma paskutinių 30 dienų skaitymo žurnalo riba. Agentas vėl galės skaityti, kai seniausiems įrašams sukaks 30 dienų.
list-encrypted = Užšifruotas laiškas
agent-log-composed = Atidarytas naujas laiškas „{ $subject }“, kurį galite baigti rašyti
agent-log-refused = Atmetėte prašymą išsiųsti laišką „{ $subject }“
agent-log-sent = Laiškas „{ $subject }“ įtrauktas į siuntimo eilę. Gavėjai: { $to }
agent-log-draft = Įrašytas juodraštis „{ $subject }“
agent-log-draft-replaced = Pakeistas juodraštis „{ $subject }“
agent-log-draft-discarded = Atmestas juodraštis „{ $subject }“
agent-draft-note = Šį juodraštį parašė DI agentas { $program }. Prieš siųsdami patikrinkite gavėjus ir tekstą.
agent-log-read = Pažymėtas kaip skaitytas: „{ $subject }“
agent-log-unread = Pažymėtas kaip neskaitytas: „{ $subject }“
agent-log-flagged = Pažymėtas vėliavėle: „{ $subject }“
agent-log-unflagged = Nuimta vėliavėlė: „{ $subject }“
agent-log-deleted = Panaikintas „{ $subject }“
agent-log-moved = „{ $subject }“ perkeltas (paskirtis: { $folder })
agent-log-junk = Pažymėtas kaip nepageidaujamas: „{ $subject }“
agent-log-not-junk = Pažymėtas kaip pageidaujamas: „{ $subject }“
agent-log-archived = Archyvuotas „{ $subject }“
agent-log-folder = Sukurtas aplankas „{ $name }“
agent-log-unsubscribed = Patvirtinote prašymą atsisakyti prenumeratos. Laiškas: „{ $subject }“
agent-log-unsubscribe-failed = Nepavyko atsisakyti prenumeratos. Laiškas: „{ $subject }“. Priežastis: { $reason }
agent-log-unsubscribe-refused = Nepatvirtinote prašymo atsisakyti prenumeratos. Siuntėjai: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } nori jūsų vardu atsisakyti { $count } adresatų sąrašo prenumeratos
    [few] { $program } nori jūsų vardu atsisakyti { $count } adresatų sąrašų prenumeratos
   *[other] { $program } nori jūsų vardu atsisakyti { $count } adresatų sąrašų prenumeratos
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic paprašo toliau nurodyto adresatų sąrašo nebesiųsti jums laiškų. Tam naudojama sąrašo siūloma galimybė atsisakyti prenumeratos vienu spustelėjimu. Daugiau nieko nesiunčiama. Esami laiškai nekeičiami ir neperkeliami.
   *[other] Inbox Classic paprašo kiekvieno toliau nurodyto adresatų sąrašo nebesiųsti jums laiškų. Tam naudojama kiekvieno sąrašo siūloma galimybė atsisakyti prenumeratos vienu spustelėjimu. Daugiau nieko nesiunčiama. Esami laiškai nekeičiami ir neperkeliami.
}
agent-log-flag-color = Laiškas „{ $subject }“ pažymėtas { $color ->
    [red] raudona vėliavėle
    [orange] oranžine vėliavėle
    [yellow] geltona vėliavėle
    [green] žalia vėliavėle
    [blue] mėlyna vėliavėle
    [purple] violetine vėliavėle
   *[gray] pilka vėliavėle
}
agent-log-renamed = Paprašyta pervardyti aplanką „{ $old }“ į „{ $name }“
agent-log-watched = Pradėtas stebėti pokalbis „{ $subject }“
agent-log-ignored = Pradėtas ignoruoti pokalbis „{ $subject }“
agent-log-unmarked = Nebestebimas ir nebeignoruojamas pokalbis „{ $subject }“
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = laiško žymėjimas nuo to laiko pasikeitė
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Pažymėta kaip skaityti: { $count } laiškas (paieška: { $query })
    [few] Pažymėta kaip skaityti: { $count } laiškai (paieška: { $query })
   *[other] Pažymėta kaip skaityti: { $count } laiškų (paieška: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Pažymėta kaip neskaityti: { $count } laiškas (paieška: { $query })
    [few] Pažymėta kaip neskaityti: { $count } laiškai (paieška: { $query })
   *[other] Pažymėta kaip neskaityti: { $count } laiškų (paieška: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Pažymėtas vėliavėle { $count } laiškas (paieška: { $query })
    [few] Pažymėti vėliavėle { $count } laiškai (paieška: { $query })
   *[other] Pažymėta vėliavėle { $count } laiškų (paieška: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Nuimta vėliavėlė nuo { $count } laiško (paieška: { $query })
    [few] Nuimta vėliavėlė nuo { $count } laiškų (paieška: { $query })
   *[other] Nuimta vėliavėlė nuo { $count } laiškų (paieška: { $query })
}
agent-log-bulk-color = { $count ->
    [one] Pažymėtas
    [few] Pažymėti
   *[other] Pažymėta
} { $color ->
    [red] raudona vėliavėle
    [orange] oranžine vėliavėle
    [yellow] geltona vėliavėle
    [green] žalia vėliavėle
    [blue] mėlyna vėliavėle
    [purple] violetine vėliavėle
   *[gray] pilka vėliavėle
} { $count ->
    [one] { $count } laiškas
    [few] { $count } laiškai
   *[other] { $count } laiškų
} (paieška: { $query })
agent-log-bulk-moved = { $count ->
    [one] Perkeltas { $count } laiškas (paskirtis: { $folder }; paieška: { $query })
    [few] Perkelti { $count } laiškai (paskirtis: { $folder }; paieška: { $query })
   *[other] Perkelta { $count } laiškų (paskirtis: { $folder }; paieška: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Archyvuotas { $count } laiškas (paieška: { $query })
    [few] Archyvuoti { $count } laiškai (paieška: { $query })
   *[other] Archyvuota { $count } laiškų (paieška: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Pažymėta kaip nepageidaujami: { $count } laiškas (paieška: { $query })
    [few] Pažymėta kaip nepageidaujami: { $count } laiškai (paieška: { $query })
   *[other] Pažymėta kaip nepageidaujami: { $count } laiškų (paieška: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Pažymėta kaip pageidaujami: { $count } laiškas (paieška: { $query })
    [few] Pažymėta kaip pageidaujami: { $count } laiškai (paieška: { $query })
   *[other] Pažymėta kaip pageidaujami: { $count } laiškų (paieška: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Panaikintas { $count } laiškas (paieška: { $query })
    [few] Panaikinti { $count } laiškai (paieška: { $query })
   *[other] Panaikinta { $count } laiškų (paieška: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] Per pastarąsias 15 minučių
    [hour] Per pastarąją valandą
    [hours] Per pastarąsias 4 valandas
    [day] Per pastarąsias 24 valandas
    [week] Per pastarąsias 7 dienas
   *[all] Per pastarąsias 30 dienų
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] Nėra šio laikotarpio programos „{ $program }“ pakeitimų, kuriuos dabar būtų galima atšaukti.
    [one] Atšaukti { $count } pakeitimą, kurį { $program } atliko per pasirinktą laikotarpį?
    [few] Atšaukti { $count } pakeitimus, kuriuos { $program } atliko per pasirinktą laikotarpį?
   *[other] Atšaukti { $count } pakeitimų, kuriuos { $program } atliko per pasirinktą laikotarpį?
}
agent-undo-since-detail = Programa bando grąžinti laiškus į ankstesnius aplankus ir atkurti jų skaitymo būseną bei vėliavėles. Aplanke „Siunčiami laiškai“ dar esantys laiškai panaikinami. Nerasti laiškai ir pakeitimai, kurių nebegalima atšaukti, praleidžiami.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Nieko neatšaukta.
    [one] Visiškai ar iš dalies atšauktas { $count } pakeitimas.
    [few] Visiškai ar iš dalies atšaukti { $count } pakeitimai.
   *[other] Visiškai ar iš dalies atšaukta { $count } pakeitimų.
}
agent-undo-left-gone = { $count ->
    [one] Numatytoje vietoje nebėra { $count } laiško.
    [few] Numatytoje vietoje nebėra { $count } laiškų.
   *[other] Numatytoje vietoje nebėra { $count } laiškų.
}
agent-undo-left-changed = { $count ->
    [one] Praleistas { $count } laiškas: skaitymo būsena arba vėliavėlė nuo to laiko pasikeitė.
    [few] Praleisti { $count } laiškai: skaitymo būsena arba vėliavėlė nuo to laiko pasikeitė.
   *[other] Praleista { $count } laiškų: skaitymo būsena arba vėliavėlė nuo to laiko pasikeitė.
}
agent-undo-left-sent = { $count ->
    [one] Aplanke „Siunčiami laiškai“ nebėra { $count } laiško.
    [few] Aplanke „Siunčiami laiškai“ nebėra { $count } laiškų.
   *[other] Aplanke „Siunčiami laiškai“ nebėra { $count } laiškų.
}
agent-undo-left-impossible = { $count ->
    [one] { $count } pakeitimo atšaukti negalima.
    [few] { $count } pakeitimų atšaukti negalima.
   *[other] { $count } pakeitimų atšaukti negalima.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Šiuo laišku priimamas kvietimas „{ $summary }“ ({ $when }).
    [tentative] Šiuo laišku preliminariai priimamas kvietimas „{ $summary }“ ({ $when }).
   *[decline] Šiuo laišku atmetamas kvietimas „{ $summary }“ ({ $when }).
} Laiške bus atsakymas organizatoriaus kalendoriaus programai. Inbox Classic jūsų atsakymą į kvietimą atnaujins tik išsiuntusi laišką.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Priimta: { $summary }
    [tentative] Preliminariai priimta: { $summary }
   *[decline] Atmesta: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } priėmė šį kvietimą.
    [tentative] { $name } preliminariai priėmė šį kvietimą.
   *[decline] { $name } atmetė šį kvietimą.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] perskaitytas { $count } laiškas
    [few] perskaityti { $count } laiškai
   *[other] perskaityta { $count } laiškų
}
agent-reads-attachments = { $count ->
    [one] priedų duomenys pasiekti { $count } kartą
    [few] priedų duomenys pasiekti { $count } kartus
   *[other] priedų duomenys pasiekti { $count } kartų
}
agent-reads-searches = { $count ->
    [one] ieškota { $count } kartą
    [few] ieškota { $count } kartus
   *[other] ieškota { $count } kartų
}
agent-reads-lists = { $count ->
    [one] laiškų sąrašai peržiūrėti { $count } kartą
    [few] laiškų sąrašai peržiūrėti { $count } kartus
   *[other] laiškų sąrašai peržiūrėti { $count } kartų
}
# each read under that row
agent-read-message = Perskaitytas laiškas „{ $subject }“
agent-read-conversation = { $count ->
    [one] Perskaitytas pokalbis „{ $subject }“ ({ $count } laiškas)
    [few] Perskaitytas pokalbis „{ $subject }“ ({ $count } laiškai)
   *[other] Perskaitytas pokalbis „{ $subject }“ ({ $count } laiškų)
}
agent-read-attachment = Pasiekti laiško „{ $subject }“ priedo „{ $name }“ duomenys
agent-read-search = { $count ->
    [one] Ieškota „{ $query }“: rastas { $count } laiškas
    [few] Ieškota „{ $query }“: rasti { $count } laiškai
   *[other] Ieškota „{ $query }“: rasta { $count } laiškų
}
agent-read-people = Ieškota kontaktų, kurių vardas ar adresas prasideda „{ $query }“
agent-read-list = { $count ->
    [one] Peržiūrėtas { $count } laiškų sąrašo įrašas. Aplankas: „{ $folder }“.
    [few] Peržiūrėti { $count } laiškų sąrašo įrašai. Aplankas: „{ $folder }“.
   *[other] Peržiūrėta { $count } laiškų sąrašo įrašų. Aplankas: „{ $folder }“.
}
agent-read-changes = { $count ->
    [one] Peržiūrėtas { $count } naujų laiškų sąrašo įrašas.
    [few] Peržiūrėti { $count } naujų laiškų sąrašo įrašai.
   *[other] Peržiūrėta { $count } naujų laiškų sąrašo įrašų.
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Iš programos „{ $terminal }“ paleistos programos
agent-terminal-programs-windows = Iš terminalo ({ $terminal }) paleistos programos
agent-terminal-programs-linux = Iš terminalo ({ $terminal }) paleistos programos
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Iš programos „{ $terminal }“ paleista programa
agent-terminal-program-windows = Iš terminalo ({ $terminal }) paleista programa
agent-terminal-program-linux = Iš terminalo ({ $terminal }) paleista programa
agent-connect-title-terminal = { $programs } nori naudotis jūsų paštu
agent-connect-terminal-detail = Visi DI agentai, kuriuos paleidžiate iš šio terminalo, bendrai naudojasi čia suteikta prieiga. Norėdami suteikti agentui atskirą prieigą, agento MCP nustatymuose į jo argumentus įtraukite --name ir savo pasirinktą pavadinimą.
# review: new
agent-connect-claimed = Programa prisistatė kaip { $claimed }. Inbox Classic patikrino, kuri programa ją paleido: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = paslaugų teikėjas nepateikė atnaujinimo rakto (refresh token)
sign-in-no-account = paslaugų teikėjas nenurodė, kuri paskyra prisijungė
sign-in-not-finished = prisijungimas nebaigtas
secrets-unavailable = Slaptažodžių saugykla „{ $store }“ nepasiekiama
secrets-unavailable-why = Slaptažodžių saugykla „{ $store }“ nepasiekiama: { $error }
secrets-windows = Kredencialų tvarkytuvas
secrets-mac = Raktinė
secrets-linux = sistemos raktinė (Secret Service)
error-no-such-file = tokio failo nėra
cards-file-too-big = Šis failas per didelis, kad jį būtų galima importuoti kaip adresų knygelę.
ui-sender-added = Įtraukta į adresų knygelę: { $name }.
ui-sender-known = Jau yra adresų knygelėje: { $name }.
ui-sender-none = Šio laiško siuntėjas neturi el. pašto adreso, kurį būtų galima įtraukti.
card-name-needed = Kontaktas neturi nei vardo, nei el. pašto adreso.
# a file of Import Address Book that could not be read: "contacts.vcf: tokio failo nėra"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Kodas svetainei: { $domain }
otp-copy = Kopijuoti
otp-note = Įveskite kodą tik šio domeno puslapyje: { $domain }.
otp-old = Šis kodas išsiųstas daugiau nei valandą prieš jums atidarant laišką, todėl tikriausiai nebegalioja.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } dalyvis
        [few] { $count } dalyviai
       *[other] { $count } dalyvių
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code }: jūsų kodas svetainei { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Galioja
pgp-key-expires = Galioja iki { $date }
pgp-key-expired = Nebegalioja nuo { $date }
pgp-key-revoked = Atšauktas
pgp-key-revoked-why = Atšauktas: { $reason }
pgp-key-not-valid = Negalioja
pgp-key-locked = Šio privačiojo rakto atrakinti nepavyko. Patikrinkite, ar prieinama saugykla „{ $store }“. Jei jį saugantis raktas prarastas, importuokite privačiojo rakto atsarginę kopiją.
pgp-source-own = Sukurtas programoje Inbox Classic
pgp-source-file = Importuotas iš failo
pgp-source-paste = Įklijuotas
pgp-source-attachment = Iš laiško
pgp-source-vcard = Iš kontakto kortelės
pgp-source-wkd = Gautas iš el. pašto adreso domeno
pgp-source-keyserver = Iš keys.openpgp.org
pgp-source-autocrypt = Iš laiško Autocrypt antraštės
pgp-error-no-store = Privačiųjų raktų apsaugai naudojama saugykla „{ $store }“, bet jos pasiekti nepavyko: { $error }
pgp-error-wrong-passphrase = Slaptafrazė neteisinga.
pgp-error-not-a-key = Tai nėra OpenPGP raktas.
pgp-error-too-large = Raktas per didelis.
pgp-error-unusable = Šis raktas netinka pasirinktai operacijai arba neatitinka saugumo reikalavimų.
pgp-imported-private = { $count ->
    [one] Importuotas { $count } privatusis raktas.
    [few] Importuoti { $count } privatieji raktai.
   *[other] Importuota privačiųjų raktų: { $count }.
}
pgp-imported-public = { $count ->
    [one] Importuotas { $count } raktas.
    [few] Importuoti { $count } raktai.
   *[other] Importuota raktų: { $count }.
}
pgp-imported-pending = Šiems adresams jau naudojamas kitas raktas: { $addresses }. Naujasis raktas rodomas kontakto ypatybėse; galėsite pasirinkti, ar jį naudoti.
pgp-error-needs-passphrase = Privatusis raktas apsaugotas slaptafraze. Įveskite ją, kad importuotumėte raktą.
pgp-error-mismatch = Privatusis raktas neatitinka viešojo rakto. Jis galėjo būti pakeistas.
pgp-file-name-public = Viešasis raktas ({ $who }).asc
pgp-file-name-private = Privačiojo rakto atsarginė kopija ({ $who }).asc
pgp-pending = Rastas kitas raktas. Adresas: { $address }. Radimo data: { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Pasirašė: { $signer }; rakto savininkas patikrintas
pgp-part-signed = Pasirašė: { $signer } (rakto savininkas nepatikrintas)
pgp-part-other = Nepavyko patvirtinti, kad parašas atitinka laiško siuntėją. Pasirašė: { $signer }
pgp-part-unknown-key = Pasirašyta, bet raktas nežinomas
pgp-part-not-signed = Nepasirašyta
pgp-part-not-checked = Parašas netikrintas
pgp-part-encrypted = Užšifruota. { $signature }
pgp-part-no-key = Užšifruota raktu, kurio neturite
pgp-part-changed = Nepavyko patikrinti užšifruotos dalies vientisumo, todėl ji nerodoma
pgp-part-unprotected = Užšifruota be apsaugos nuo pakeitimų, todėl nerodoma
pgp-part-broken = Užšifruotos dalies perskaityti negalima
pgp-why-mismatch = Parašas neatitinka šio teksto
pgp-why-weak-hash = Parašui naudotas nesaugus maišos algoritmas: { $hash }
pgp-why-key-expired = Pasirašyta po to, kai raktas nustojo galioti ({ $date })
pgp-why-key-revoked = Pasirašyta atšauktu raktu
pgp-why-not-signing-key = Pasirašyta raktu, kuriuo pasirašyti negalima
pgp-why-from-future = Parašo data yra ateityje
pgp-why-signature-expired = Parašas nebegalioja
pgp-why-key-not-valid = Pasirašyta negaliojančiu raktu
pgp-why-not-for-you = Pasirašyta kitiems gavėjams ir persiųsta jums
pgp-why-not-key-in-use = Pasirašyta kitu raktu nei naudojamas adresui { $address }
pgp-part-pictures-loaded = { $label }. Paveikslėliai įkelti iš interneto
pgp-error-no-own-key = Neturite pasirašyti ar šifruoti tinkamo rakto šiam adresui: { $address }. Sukurkite raktą lange „Šifravimo raktai“ arba išjunkite pasirašymą ir šifravimą.
pgp-error-missing-keys = { $count ->
    [1] Šiam gavėjui nėra šifruoti tinkamo rakto: { $addresses }.
   *[other] Šiems gavėjams nėra šifruoti tinkamo rakto: { $addresses }.
}
pgp-error-encrypted-quote = Laiške yra turinio iš užšifruoto laiško. Kad jį išsiųstumėte, įjunkite šifravimą arba pašalinkite šį turinį.
pgp-error-protect = Laiško nepavyko pasirašyti ar užšifruoti: { $reason }
pgp-found-keys = Adresai, kuriems rasti raktai: { $addresses }.
pgp-found-none = Šiems adresams raktų nerasta: { $addresses }. Paprašykite adresų savininkų atsiųsti savo viešuosius raktus.
pgp-found-no-key = Rakto nerasta.
pgp-find-unavailable = Šiuo metu raktų ieškoti nepavyko: { $error }
pgp-publish-pending = keys.openpgp.org išsiuntė patvirtinimo nuorodas šiais adresais: { $addresses }. Patvirtinkite kiekvieną adresą, kad pagal jį būtų galima rasti jūsų raktą.
pgp-publish-done = Jūsų raktą keys.openpgp.org galima rasti pagal šiuos adresus: { $addresses }.
pgp-publish-failed = Rakto paskelbti nepavyko: { $error }
pgp-keyserver-off = Raktų paieška keys.openpgp.org išjungta. Ją galite įjungti čia: { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [1] Laiškas bus išsiųstas užšifruotas ir pasirašytas. Turinį galėsite perskaityti tik jūs ir gavėjas: { $addresses }.
    [one] Laiškas bus išsiųstas užšifruotas ir pasirašytas. Turinį galėsite perskaityti tik jūs ir { $count } gavėjas.
    [few] Laiškas bus išsiųstas užšifruotas ir pasirašytas. Turinį galėsite perskaityti tik jūs ir { $count } gavėjai.
   *[other] Laiškas bus išsiųstas užšifruotas ir pasirašytas. Turinį galėsite perskaityti tik jūs ir { $count } gavėjų.
}
pgp-compose-encrypt-ready = Laiškas bus užšifruotas ir pasirašytas. Pridėkite gavėjų, kurių raktus turite.
pgp-compose-missing = { $count ->
    [one] Tinkamo rakto neturi { $count } gavėjas: { $addresses }. Laiško dar negalima užšifruoti.
    [few] Tinkamo rakto neturi { $count } gavėjai: { $addresses }. Laiško dar negalima užšifruoti.
   *[other] Tinkamo rakto neturi { $count } gavėjų: { $addresses }. Laiško dar negalima užšifruoti.
}
pgp-compose-looking = Ieškoma raktų: { $addresses }...
pgp-compose-signed = Siunčiant laiškas bus pasirašytas skaitmeniniu parašu. Gavėjai galės patikrinti, ar jo turinys po pasirašymo nebuvo pakeistas.
pgp-compose-reply-clear = Laiškas bus išsiųstas nešifruotas, nors pradinis laiškas buvo užšifruotas.
pgp-compose-encrypted-files = Laiške yra priedų iš užšifruoto laiško, todėl jį galima išsiųsti tik užšifruotą. Įjunkite parinktį „Šifruoti“ arba pašalinkite šiuos priedus.
pgp-compose-sign-tip = Skaitmeniškai pasirašyti laišką savo raktu, kad gavėjai galėtų patikrinti, ar jo turinys nepakeistas
pgp-compose-sign-tip-encrypted = Siunčiamas užšifruotas laiškas visada pasirašomas
pgp-compose-encrypt-tip = Užšifruoti laiško turinį, kad jį galėtumėte perskaityti tik jūs ir gavėjai
pgp-compose-make-key = Dar neturite savo rakto šiam adresui: { $address }. Sukurti jį dabar? Šiuo raktu galėsite pasirašyti ir šifruoti laiškus.
pgp-compose-key-unusable =
    Šiam adresui skirto jūsų rakto naudoti negalima: { $address }

    Priežastis: { $state }

    Atidarykite langą „Šifravimo raktai“ ir importuokite šio rakto atsarginę kopiją arba sukurkite naują raktą.
pgp-compose-encrypt-off-quote = Laiške yra teksto, paveikslėlių arba priedų iš užšifruoto laiško. Laišką galima siųsti nešifruotą tik pašalinus šį turinį. Vis tiek išjungti šifravimą?
pgp-compose-encrypt-off-reply = Atsakote į užšifruotą laišką arba jį persiunčiate. Nešifruoto laiško turinį gali perskaityti ir jį perduodantys serveriai. Išjungti šifravimą?
pgp-recipient-verified = Rakto savininkas patikrintas
pgp-recipient-found = Rakto savininkas nepatikrintas
pgp-recipient-own = Jūsų raktas
pgp-recipient-looking = Ieškoma rakto...
pgp-recipient-missing = Rakto nėra
pgp-recipient-not-found = Rakto nerasta. Paskutinė paieška: { $date }
pgp-recipient-unusable = Rakto naudoti negalima: { $state }
pgp-recipients-intro = Laiškas šifruojamas kiekvieno gavėjo raktu ir jūsų raktu.
pgp-recipients-intro-missing = { $count ->
    [1] Vienas gavėjas neturi tinkamo šifravimo rakto. Raskite jo raktą, pašalinkite gavėją iš laiško arba išsiųskite laišką nešifruotą.
    [one] { $count } gavėjas neturi tinkamo šifravimo rakto. Raskite šių gavėjų raktus, pašalinkite gavėjus iš laiško arba išsiųskite laišką nešifruotą.
    [few] { $count } gavėjai neturi tinkamo šifravimo rakto. Raskite šių gavėjų raktus, pašalinkite gavėjus iš laiško arba išsiųskite laišką nešifruotą.
   *[other] { $count } gavėjų neturi tinkamo šifravimo rakto. Raskite šių gavėjų raktus, pašalinkite gavėjus iš laiško arba išsiųskite laišką nešifruotą.
}
pgp-details-part = { $number } dalis: { $label }
attachment-from-part = Iš { $number } dalies: { $label }
pgp-details-signed = Pasirašyta: { $when }. Raktas: { $key }
pgp-details-unknown-key = Pasirašyta raktu { $key }, kurio neturite
pgp-details-opened = Iššifruota jūsų raktu { $key }
pgp-details-for = Užšifruota raktais: { $keys }
pgp-details-plain = Nepasirašyta ir neužšifruota
pgp-bar-parts = Šio laiško dalys ({ $count }): { $list }. Prie kiekvienos dalies nurodyta, kaip ji apsaugota.
pgp-bar-count-verified = su patikrinto savininko parašu: { $count }
pgp-bar-count-encrypted-signed = { $count ->
    [one] { $count } užšifruota ir pasirašyta
    [few] { $count } užšifruotos ir pasirašytos
   *[other] { $count } užšifruotų ir pasirašytų
}
pgp-bar-count-encrypted = { $count ->
    [one] { $count } užšifruota
    [few] { $count } užšifruotos
   *[other] { $count } užšifruotų
}
pgp-bar-count-signed = { $count ->
    [one] { $count } pasirašyta
    [few] { $count } pasirašytos
   *[other] { $count } pasirašytų
}
pgp-bar-count-warning = reikia dėmesio: { $count }
pgp-bar-count-neutral = be patvirtinto parašo: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Nustatymai
setup-part-preferences = Langų nuostatos
setup-part-accounts = Paskyros
setup-part-sign-in-apps = Prisijungimo programos
setup-part-contacts = Kontaktai ir grupės
setup-part-keys = Šifravimo raktai
setup-part-rules = Laiškų taisyklės
setup-part-trusted-senders = Patikimi siuntėjai
setup-holds-settings = { $count ->
    [one] { $count } nustatymas
    [few] { $count } nustatymai
   *[other] { $count } nustatymų
}
setup-holds-preferences = { $count ->
    [one] { $count } nuostata
    [few] { $count } nuostatos
   *[other] { $count } nuostatų
}
setup-holds-accounts = { $count ->
    [one] { $count } paskyra
    [few] { $count } paskyros
   *[other] { $count } paskyrų
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } prisijungimo programa
    [few] { $count } prisijungimo programos
   *[other] { $count } prisijungimo programų
}
setup-holds-built-in = Kurios įtaisytosios prisijungimo programos įjungtos
setup-holds-contacts = { $count ->
    [one] { $count } kontaktas
    [few] { $count } kontaktai
   *[other] { $count } kontaktų
}
setup-holds-groups = { $count ->
    [one] { $count } grupė
    [few] { $count } grupės
   *[other] { $count } grupių
}
setup-holds-own-keys = { $count ->
    [one] { $count } jūsų raktas
    [few] { $count } jūsų raktai
   *[other] { $count } jūsų raktų
}
setup-holds-contact-keys = { $count ->
    [one] { $count } kontakto raktas
    [few] { $count } kontaktų raktai
   *[other] { $count } kontaktų raktų
}
setup-holds-rules = { $count ->
    [one] { $count } taisyklė
    [few] { $count } taisyklės
   *[other] { $count } taisyklių
}
setup-holds-trusted-senders = { $count ->
    [one] { $count } patikimas siuntėjas
    [few] { $count } patikimi siuntėjai
   *[other] { $count } patikimų siuntėjų
}
setup-sign-in-password = Slaptažodis
setup-account-secret-password = Paskyros slaptažodis įtrauktas į failą.
setup-account-secret-token = Prisijungimo duomenys įtraukti į failą.
setup-account-asks-password = Importavus paskyrą reikės įvesti jos slaptažodį.
setup-account-signs-in-again = Importavus paskyrą reikės prisijungti iš naujo.
setup-account-here = Ši paskyra jau pridėta, todėl importuojant bus praleista.
setup-account-no-app = Šiai paskyrai reikia prisijungimo programos „{ $app }“, kurios čia nėra. Importuokite ir reikiamą prisijungimo programą.
setup-invalid-address = „{ $address }“ nėra el. pašto adresas.
setup-invalid-server = Netinkamas { $server } serverio adresas, prievadas arba ryšio saugos nustatymas.
setup-invalid-user = Nenurodytas naudotojo vardas.
setup-invalid-sign-in = Netinkami paskyros prisijungimo nustatymai.
setup-error-empty = Failas tuščias.
setup-error-too-large = Sąrankos duomenys viršija leistiną dydį.
setup-error-not-setup = Tai nėra Inbox Classic sąrankos failas.
setup-error-damaged = Sąrankos failas sugadintas, jo perskaityti negalima.
setup-error-newer = Šią sąranką įrašė naujesnė Inbox Classic versija ({ $version }). Atnaujinkite Inbox Classic ir importuokite ją dar kartą.
setup-error-needs-passphrase = Sąrankos failas apsaugotas slaptafraze. Įveskite ją, kad atrakintumėte failą.
setup-error-wrong-passphrase = Sąrankos failo slaptafrazė neteisinga.
setup-error-changed = Nepavyko patikrinti sąrankos failo vientisumo. Failas gali būti pakeistas arba sugadintas, todėl jo importuoti negalima.
setup-error-read = Sąrankos failo perskaityti nepavyko: { $error }
setup-error-write = Sąrankos failo įrašyti nepavyko: { $error }
setup-error-no-parts = Pasirinkite bent vieną dalį.
setup-left-out = { $count ->
    [one] Dalyje „{ $part }“ yra { $count } įrašas, kurio negalima naudoti, todėl jis praleidžiamas.
    [few] Dalyje „{ $part }“ yra { $count } įrašai, kurių negalima naudoti, todėl jie praleidžiami.
   *[other] Dalyje „{ $part }“ yra { $count } įrašų, kurių negalima naudoti, todėl jie praleidžiami.
}
setup-imported-settings = Nustatymai pakeisti.
setup-imported-preferences = Langų nuostatos pakeistos.
setup-added-accounts = { $count ->
    [one] Pridėta { $count } paskyra.
    [few] Pridėtos { $count } paskyros.
   *[other] Pridėta paskyrų: { $count }.
}
setup-skipped-here = Paskyra „{ $address }“ jau pridėta, todėl praleista.
setup-skipped-no-app = Paskyra „{ $address }“ praleista, nes nėra reikiamos prisijungimo programos „{ $app }“.
setup-skipped-invalid = Paskyra „{ $address }“ praleista: { $reason }
setup-asks-password = Jungiantis prie paskyros „{ $address }“ bus paprašyta įvesti slaptažodį.
setup-signs-in-again = Jungiantis prie paskyros „{ $address }“ bus paprašyta prisijungti iš naujo.
setup-added-sign-in-apps = { $count ->
    [one] Pridėta { $count } prisijungimo programa.
    [few] Pridėtos { $count } prisijungimo programos.
   *[other] Pridėta prisijungimo programų: { $count }.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } prisijungimo programa čia jau nustatyta.
    [few] { $count } prisijungimo programos čia jau nustatytos.
   *[other] Prisijungimo programų, kurios čia jau nustatytos: { $count }.
}
setup-added-contacts = { $count ->
    [one] Į adresų knygelę pridėtas { $count } kontaktas.
    [few] Į adresų knygelę pridėti { $count } kontaktai.
   *[other] Į adresų knygelę pridėta kontaktų: { $count }.
}
setup-skipped-contacts = { $count ->
    [one] { $count } kontaktas jau yra adresų knygelėje.
    [few] { $count } kontaktai jau yra adresų knygelėje.
   *[other] Kontaktų, kurie jau yra adresų knygelėje: { $count }.
}
setup-added-groups = { $count ->
    [one] Pridėta arba papildyta { $count } grupė.
    [few] Pridėtos arba papildytos { $count } grupės.
   *[other] Pridėta arba papildyta grupių: { $count }.
}
setup-added-own-keys = { $count ->
    [one] Pridėtas { $count } jūsų raktas.
    [few] Pridėti { $count } jūsų raktai.
   *[other] Pridėta jūsų raktų: { $count }.
}
setup-added-contact-keys = { $count ->
    [one] Pridėtas { $count } kontakto raktas.
    [few] Pridėti { $count } kontaktų raktai.
   *[other] Pridėta kontaktų raktų: { $count }.
}
setup-added-rules = { $count ->
    [one] Pridėta { $count } laiškų taisyklė.
    [few] Pridėtos { $count } laiškų taisyklės.
   *[other] Pridėta laiškų taisyklių: { $count }.
}
setup-skipped-rules = { $count ->
    [one] { $count } laiškų taisyklė čia jau yra.
    [few] { $count } laiškų taisyklės čia jau yra.
   *[other] Laiškų taisyklių, kurios čia jau yra: { $count }.
}
setup-skipped-rules-account = { $count ->
    [one] Praleista { $count } laiškų taisyklė, nes nėra jai reikalingos paskyros.
    [few] Praleistos { $count } laiškų taisyklės, nes nėra joms reikalingų paskyrų.
   *[other] Praleista { $count } laiškų taisyklių, nes nėra joms reikalingų paskyrų.
}
setup-rules-waiting = { $count ->
    [one] { $count } laiškų taisyklė laukia, kol sinchronizuojant bus rastas paskirties aplankas.
    [few] { $count } laiškų taisyklės laukia, kol sinchronizuojant bus rasti paskirties aplankai.
   *[other] { $count } laiškų taisyklių laukia, kol sinchronizuojant bus rasti paskirties aplankai.
}
setup-added-trusted-senders = { $count ->
    [one] Pridėtas { $count } patikimas siuntėjas.
    [few] Pridėti { $count } patikimi siuntėjai.
   *[other] Pridėta patikimų siuntėjų: { $count }.
}
setup-nothing = Nieko neimportuota.
setup-account-servers = { $imap } ir { $smtp } ({ $signin })
setup-file-name = Inbox Classic nustatymai ir paskyros
setup-skipped-unreachable = Neimportuota: { $name }. Nepavyko patikrinti prisijungimo paslaugos nustatymų. Reikiamą prisijungimo programą galite pridėti lange „Prisijungimo programos“, tada bandykite importuoti dar kartą.
attachment-runs-programs = Failas „{ $name }“ gali paleisti programas, todėl Inbox Classic jo neatidaro. Įrašykite jį, tada atidarykite patys, jei pasitikite jo šaltiniu.
attachment-decrypted-note = Šis priedas yra iš užšifruoto laiško. Kad jį būtų galima atidaryti, Inbox Classic įrašo nešifruotą kopiją į jūsų naudotojo paskyros laikinąjį aplanką. Paleidus programą šalinamos senesnės nei paros kopijos.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [1] Serveris neperkėlė laiško į aplanką „{ $folder }“, todėl jis vėl yra aplanke „{ $from }“ ({ $messages }): { $reason }
   *[other] Serveris neperkėlė laiškų į aplanką „{ $folder }“, todėl jie vėl yra aplanke „{ $from }“ ({ $messages }): { $reason }
}
undone-delete = { $count ->
    [1] Serveris nepanaikino laiško, todėl jis vėl yra aplanke „{ $from }“ ({ $messages }): { $reason }
   *[other] Serveris nepanaikino laiškų, todėl jie vėl yra aplanke „{ $from }“ ({ $messages }): { $reason }
}
undone-archive = { $count ->
    [1] Serveris nearchyvavo laiško, todėl jis vėl yra aplanke „{ $from }“ ({ $messages }): { $reason }
   *[other] Serveris nearchyvavo laiškų, todėl jie vėl yra aplanke „{ $from }“ ({ $messages }): { $reason }
}
undone-read = { $count ->
    [1] Serveris nepažymėjo laiško kaip skaityto, todėl jis vėl neskaitytas ({ $messages }): { $reason }
   *[other] Serveris nepažymėjo laiškų kaip skaitytų, todėl jie vėl neskaityti ({ $messages }): { $reason }
}
undone-unread = { $count ->
    [1] Serveris nepažymėjo laiško kaip neskaityto, todėl jis vėl skaitytas ({ $messages }): { $reason }
   *[other] Serveris nepažymėjo laiškų kaip neskaitytų, todėl jie vėl skaityti ({ $messages }): { $reason }
}
undone-flags = { $count ->
    [1] Serveris nepakeitė laiško vėliavėlių, todėl pakeitimas atšauktas ({ $messages }): { $reason }
   *[other] Serveris nepakeitė laiškų vėliavėlių, todėl pakeitimas atšauktas ({ $messages }): { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

preview-pdf-option = Rodyti PDF failus laiškuose
preview-pdf-off = PDF failai laiškuose nerodomi.
preview-pdf-off-crashed = Inbox Classic užsidarė, kol laiške buvo rodoma failo peržiūra, todėl PDF peržiūros išjungtos. Paveikslėliai ir toliau rodomi. Norėdami vėl matyti PDF peržiūras, įjunkite parinktį „{ $option }“ čia: { $settings }.
preview-pdf-details = { $count ->
    [one] { $count } puslapis, { $size }
    [few] { $count } puslapiai, { $size }
    [many] { $count } puslapio, { $size }
   *[other] { $count } puslapių, { $size }
}
preview-page-alt = { $name }, { $page } puslapis iš { $count }
preview-more-pages = { $count ->
    [1] Atidarykite failą, kad peržiūrėtumėte puslapį
   *[other] Atidarykite failą, kad peržiūrėtumėte visus puslapius ({ $count })
}
preview-more-files = { $count ->
    [one] Dar { $count } failas yra sąraše viršuje
    [few] Dar { $count } failai yra sąraše viršuje
    [many] Dar { $count } failo yra sąraše viršuje
   *[other] Dar { $count } failų yra sąraše viršuje
}
preview-tile-downloading = Atsisiunčiama…
preview-tile-preparing = Ruošiama…
preview-tile-format = { $format } paveikslėliai kol kas nerodomi
preview-tile-password = Failas apsaugotas slaptažodžiu. Atidarykite jį ir įveskite slaptažodį
preview-tile-too-large = Viršyta peržiūros dydžio riba
preview-tile-unreadable = Negalima parodyti
preview-tile-timed-out = Peržiūros parengimas užtruko per ilgai
preview-tile-crashed = Šio failo peržiūra išjungta po ankstesnio sutrikimo
preview-tile-off = Peržiūra išjungta iki kito Inbox Classic paleidimo
preview-not-printed = Failas „{ $name }“ ({ $details }) nespausdinamas kartu su laišku. Norėdami jį išspausdinti, atidarykite failą.
