# Lietuvių. Juodraštis, laukia gimtakalbio peržiūros (žr. core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] { $count } laiškas
    [few] { $count } laiškai
   *[other] { $count } laiškų
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] { $count } baitas
    [few] { $count } baitai
   *[other] { $count } baitų
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Išjungta
# review: new
send-delay-seconds = { $count ->
    [one] { $count } sekundė
    [few] { $count } sekundės
   *[other] { $count } sekundžių
}
# the status bar: "12 laiškų, neskaitytų: 3"
# review: new
list-counts = { $messages }, neskaitytų: { $unread }
# review: new
list-counts-selected = { $messages }, neskaitytų: { $unread }, pažymėtų: { $selected }
# the status bar while searching: "Rasta: 12, neskaitytų: 3"
# review: new
list-counts-found = Rasta: { $found }, neskaitytų: { $unread }
# review: new
list-counts-found-selected = Rasta: { $found }, neskaitytų: { $unread }, pažymėtų: { $selected }
# review: new
list-counts-none = Laiškų nerasta

## Special folders, as Outlook names them

# review: new
folder-inbox = Gauti laiškai
# review: new
folder-sent = Išsiųsti laiškai
# review: new
folder-deleted = Panaikinti laiškai
# review: new
folder-drafts = Juodraščiai
# review: new
folder-junk = Nepageidaujami laiškai
# review: new
folder-archive = Archyvas

## The reading pane

# review: new
reader-no-message = Nepažymėtas joks laiškas.
# review: new
reader-downloading = Atsisiunčiamas laiškas…
# review: new
reader-downloading-detail = Laiškas bus parodytas čia, kai atsisiuntimas baigsis.
# review: new
reader-downloading-size = Laiško dydis: { $size }. Jis bus parodytas čia, kai bus atsisiųstas.
# review: new
reader-failed = Laiško atsisiųsti nepavyko
# review: new
reader-failed-network = Nepavyko pasiekti pašto serverio ({ $reason }).
# review: new
reader-failed-sign-in = Pašto serveris nepriėmė prisijungimo ({ $reason }). Patikrinkite slaptažodį arba vėl prisijunkite per Failas > Paskyros.
# review: new
reader-failed-security = Nepavyko apsaugoti ryšio su pašto serveriu ({ $reason }).
# review: new
reader-failed-other = Pašto serveris atsakė: { $reason }.
# review: new
reader-retry-note = Bus bandoma dar kartą, kai paskyra vėl prisijungs.
# review: new
reader-unreadable = Šio laiško parodyti negalima: { $error }
# review: new
message-source-title = Laiško šaltinis: { $subject }
# review: new
message-source-untitled = Laiško šaltinis

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Nuo
# review: new
header-date = Data
# review: new
header-to = Kam
# review: new
header-cc = Kopija
# review: new
header-sent = Išsiųsta
# review: new
header-subject = Tema
# review: new
header-security = Sauga
# review: new
header-part = { $number } dalis
# review: new
quote-original = ----- Pradinis laiškas -----
# review: new
fold-show-earlier = Rodyti ankstesnius laiškus

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Jūsų laiškas nebuvo pristatytas
# review: new
bounce-delayed = Jūsų laiškas dar nepristatytas
# review: new
bounce-delayed-note = Jūsų pašto serveris vis dar bando jį pristatyti. Siųsti jo dar kartą nereikia.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Rodyti nepristatytą laišką
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Rodyti vėluojantį laišką
# review: new
bounce-what-to-do = Ką galite padaryti:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Kol kas nieko. Jei laiško vis tiek nepavyks pristatyti, gausite dar vieną pranešimą.
# review: new
bounce-delayed-row-do = Kol kas nieko. Jūsų pašto serveris vis dar bando jį pristatyti, o jei nepavyks, gausite dar vieną pranešimą.
# folds the receiving server's own words
# review: new
bounce-details = Išsami informacija
# a recipient the notice does not name
# review: new
bounce-someone = Gavėjas
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Serveris: { $server }
# review: new
bounce-status = Būsena: { $status }
# review: new
bounce-reported-by = Pranešė: { $server }
# review: new
bounce-retry-minutes = Gaunantysis serveris paprašė prieš kitą bandymą palaukti { $count ->
    [one] { $count } minutę
    [few] { $count } minutes
   *[other] { $count } minučių
}.
# review: new
bounce-retry-hours = Gaunantysis serveris paprašė prieš kitą bandymą palaukti { $count ->
    [one] { $count } valandą
    [few] { $count } valandas
   *[other] { $count } valandų
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Juodasis sąrašas: { $lists }
# review: new
bounce-user-unknown = Tokio adreso nėra
# review: new
bounce-user-unknown-why = Gaunančiajame serveryje nėra pašto dėžutės šiuo adresu. Adresas gali būti parašytas su klaida, arba žmogus juo nebesinaudoja.
# review: new
bounce-user-unknown-do = Patikrinkite, ar adresas parašytas teisingai, arba paklauskite žmogaus, kokiu adresu jis dabar naudojasi.
# review: new
bounce-invalid-address = Adresas netinkamas
# review: new
bounce-invalid-address-why = Adresas parašytas taip, kad juo negalima išsiųsti laiško.
# review: new
bounce-invalid-address-do = Ieškokite rašybos klaidų, pavyzdžiui, tarpo, trūkstamos raidės ar tuščios vietos po @.
# review: new
bounce-mailbox-disabled = Pašto dėžutė uždaryta
# review: new
bounce-mailbox-disabled-why = Adresas yra, bet jo pašto dėžutė išjungta arba nebenaudojama.
# review: new
bounce-mailbox-disabled-do = Susisiekite su žmogumi kitu būdu ir paklauskite, kokiu adresu jis dabar naudojasi.
# review: new
bounce-mailbox-full = Pašto dėžutė pilna
# review: new
bounce-mailbox-full-why = Gavėjo pašto dėžutėje nebėra vietos naujiems laiškams.
# review: new
bounce-mailbox-full-do = Išsiųskite laišką dar kartą po kelių dienų arba praneškite žmogui kitu būdu. Pirmiausia atmetami dideli priedai.
# review: new
bounce-spam-blocked = Atmestas kaip brukalas
# review: new
bounce-spam-blocked-why = Gaunantysis serveris palaikė laišką brukalu.
# review: new
bounce-spam-blocked-do = Išsiųskite laišką dar kartą be to, kas atrodo kaip brukalas, pavyzdžiui, be daugybės nuorodų, sutrumpintų nuorodų ar didelio priedo. Jei tai kartojasi, kreipkitės į savo pašto paslaugų teikėją.
# review: new
bounce-virus-detected = Atmestas dėl viruso
# review: new
bounce-virus-detected-why = Gaunantysis serveris laiške arba jo prieduose rado virusą ar kitą kenksmingą turinį.
# review: new
bounce-virus-detected-do = Patikrinkite priedus antivirusine programa. Kai kurie serveriai atmeta visas programas ir archyvus, todėl tokiais failais dalinkitės nuoroda.
# review: new
bounce-ip-blocklisted = Jūsų pašto serveris yra juodajame sąraše
# review: new
bounce-ip-blocklisted-why = Gaunantysis serveris nepriima laiškų iš serverio, kuris siuntė jūsiškį, nes to serverio adresas yra juodajame sąraše.
# review: new
bounce-ip-blocklisted-do = Problema ne laiške. Persiųskite šį pranešimą savo pašto paslaugų teikėjui ir paprašykite, kad serveris būtų išbrauktas iš sąrašo.
# review: new
bounce-domain-blocklisted = Domenas yra juodajame sąraše
# review: new
bounce-domain-blocklisted-why = Gaunantysis serveris atmeta laišką, nes jūsų adreso domenas arba domenas iš laiško nuorodų yra juodajame sąraše.
# review: new
bounce-domain-blocklisted-do = Jei laiške yra nuorodų, pabandykite išsiųsti jį be jų. Kitu atveju persiųskite šį pranešimą tam, kas tvarko jūsų domeno paštą.
# review: new
bounce-policy-blocked = Atmestas pagal gaunančiojo serverio taisykles
# review: new
bounce-policy-blocked-why = Gaunančiojo serverio taisyklės šio laiško nepraleidžia, pavyzdžiui, dėl jo dydžio, priedų ar siuntėjo.
# review: new
bounce-policy-blocked-do = Priežastis dažnai nurodyta paties serverio žodžiuose, skiltyje „Išsami informacija“. Paklauskite gavėjo, ar jis gali priimti tokius laiškus.
# review: new
bounce-geo-blocked = Atmestas dėl kilmės vietos
# review: new
bounce-geo-blocked-why = Gaunantysis serveris nepriima laiškų iš šalies ar tinklo, kuriame yra jūsų pašto serveris.
# review: new
bounce-geo-blocked-do = Susisiekite su žmogumi kitu būdu arba kreipkitės į savo pašto paslaugų teikėją.
# review: new
bounce-relay-denied = Serveris laiško neperdavė
# review: new
bounce-relay-denied-why = Serveris atsisakė perduoti laišką toliau, dažnai todėl, kad jis išsiųstas neprisijungus arba per serverį, kuris šio gavėjo neaptarnauja.
# review: new
bounce-relay-denied-do = Patikrinkite paskyros siunčiamųjų laiškų serverį per Failas > Paskyros ir ar jis prisijungia.
# review: new
bounce-auth-failure = Jūsų siuntėjo adreso patvirtinti nepavyko
# review: new
bounce-auth-failure-why = Gaunantysis serveris negalėjo patvirtinti, kad laiškas tikrai atėjo iš jūsų domeno (SPF, DKIM arba DMARC).
# review: new
bounce-auth-failure-do = Persiųskite šį pranešimą tam, kas tvarko jūsų domeno paštą: reikia pataisyti jo nustatymus. Kol kas gali padėti siuntimas per paties paslaugų teikėjo serverį.
# review: new
bounce-rate-limited = Per daug laiškų vienu metu
# review: new
bounce-rate-limited-why = Gaunantysis serveris kol kas priima mažiau laiškų iš jūsų pašto serverio.
# review: new
bounce-rate-limited-do = Palaukite ir išsiųskite laišką dar kartą. Rašydami daugeliui žmonių, siųskite mažesnėmis grupėmis.
# review: new
bounce-greylisting = Trumpam sulaikytas
# review: new
bounce-greylisting-why = Gaunantysis serveris prašo nežinomų siuntėjų pabandyti šiek tiek vėliau. Tai įprasta apsauga nuo brukalo.
# review: new
bounce-greylisting-do = Nieko. Pašto serveriai bando dar kartą patys, ir laiškas paprastai pristatomas per valandą.
# review: new
bounce-server-error = Gaunančiajame serveryje kilo problema
# review: new
bounce-server-error-why = Gaunančiojo serverio nepavyko pasiekti arba jis negalėjo priimti laiško dėl savo paties problemos.
# review: new
bounce-server-error-do = Išsiųskite laišką vėliau. Jei vis nepavyksta, patikrinkite, ar adreso dalyje po @ nėra rašybos klaidų.
# review: new
bounce-unknown = Nepristatytas
# review: new
bounce-unknown-why = Pranešime aiškiai nenurodyta, kodėl.
# review: new
bounce-unknown-do = Daugiau gali paaiškinti paties serverio žodžiai, skiltyje „Išsami informacija“. Jei jie nepadeda, persiųskite šį pranešimą savo pašto paslaugų teikėjui.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] Pažymėtas { $count } laiškas
    [few] Pažymėti { $count } laiškai
   *[other] Pažymėta { $count } laiškų
}
# review: new
selection-unread = { $count ->
    [one] { $count } neskaitytas
    [few] { $count } neskaityti
   *[other] { $count } neskaitytų
}
# review: new
selection-flagged = { $count ->
    [one] { $count } su vėliavėle
    [few] { $count } su vėliavėlėmis
   *[other] { $count } su vėliavėlėmis
}
# review: new
delete-for-good-one = Šis laiškas bus panaikintas visam laikui. Panaikinti jį?
# review: new
delete-for-good-all = Visam laikui bus panaikinta laiškų: { $count }. Panaikinti juos?
# review: new
delete-for-good-some = Visam laikui bus panaikinta laiškų: { $count } iš { $total }. Panaikinti laiškus?
# review: new
done-read = { $count ->
   *[other] Pažymėta kaip skaityti: { $messages }
}
# review: new
done-unread = { $count ->
   *[other] Pažymėta kaip neskaityti: { $messages }
}
# review: new
done-flagged = { $count ->
   *[other] Pažymėta vėliavėle: { $messages }
}
# review: new
done-unflagged = Vėliavėlė nuimta: { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Visam laikui panaikinta: { $messages }
}
# review: new
done-archived = { $count ->
   *[other] Archyvuota: { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Perkelta: { $messages } (paskirtis: { $folder })
}
# review: new
done-copied = { $count ->
   *[other] Nukopijuota: { $messages } (paskirtis: { $folder })
}
# review: new
done-moving = { $count ->
   *[other] Perkeliama: { $messages } (paskirtis: { $folder })...
}
# review: new
done-copying = { $count ->
   *[other] Kopijuojama: { $messages } (paskirtis: { $folder })...
}
# review: new
done-moved-back = { $count ->
   *[other] Grąžinta: { $messages } (paskirtis: { $folder })
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Pokalbis stebimas
    [few] Stebimi { $count } pokalbiai
   *[other] Stebima pokalbių: { $count }
}
# review: new
done-unwatched = { $count ->
    [one] Pokalbis nebestebimas
    [few] Nebestebimi { $count } pokalbiai
   *[other] Nebestebima pokalbių: { $count }
}
# review: new
done-ignored = { $count ->
    [one] Pokalbis ignoruojamas
    [few] Ignoruojami { $count } pokalbiai
   *[other] Ignoruojama pokalbių: { $count }
}
# review: new
done-unignored = { $count ->
    [one] Pokalbis nebeignoruojamas
    [few] Nebeignoruojami { $count } pokalbiai
   *[other] Nebeignoruojama pokalbių: { $count }
}
# review: new
their-folders = jų aplankai
# review: new
undo-move = Atšaukti perkėlimą
# review: new
undo-delete = Atšaukti panaikinimą
# review: new
undo-archive = Atšaukti archyvavimą
# review: new
undo-junk = Atšaukti žymėjimą nepageidaujamu
# review: new
undo-not-junk = Atšaukti žymėjimą pageidaujamu
# review: new
undo-send = Atšaukti siuntimą
# review: new
nothing-to-undo = Nėra ko atšaukti.
# review: new
messages-gone = Šių laiškų nebėra.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Šiame aplanke negali būti laiškų.
# review: new
not-archived-here = Šiame aplanke esančių laiškų archyvuoti negalima.
# review: new
not-emptied-here = Išvalyti galima tik aplankus „Panaikinti laiškai“ ir „Nepageidaujami laiškai“.
# review: new
next-unread-question = Aplanke „{ $folder }“ neskaitytų laiškų nebėra.

    Pereiti į aplanką „{ $next }“, kitą aplanką su neskaitytais laiškais?
# review: new
no-unread-left = Neskaitytų laiškų nebeliko.
# review: new
empty-question = { $count ->
    [one] Išvalyti aplanką „{ $folder }“?

        Jame esantis laiškas bus panaikintas visam laikui. Jo atkurti nebus galima.
   *[other] Išvalyti aplanką „{ $folder }“?

        Jame esantys laiškai ({ $messages }) bus panaikinti visam laikui. Jų atkurti nebus galima.
}
# review: new
no-junk-folder = Šioje paskyroje nėra aplanko „Nepageidaujami laiškai“, į kurį būtų galima perkelti laiškus.
# review: new
no-inbox-folder = Šioje paskyroje nėra aplanko „Gauti laiškai“, į kurį būtų galima perkelti laiškus.
# the status bar after a flag in a colour: "2 laiškai: pažymėta mėlyna vėliavėle"
# review: new
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
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Perkelti laišką
   *[other] Perkelti laiškus ({ $count })
}
# review: new
move-window-title-copy = { $count ->
    [one] Kopijuoti laišką
   *[other] Kopijuoti laiškus ({ $count })
}
# review: new
move-window-prompt-move = { $count ->
    [one] Perkelti pažymėtą laišką į:
   *[other] Perkelti pažymėtus laiškus ({ $count }) į:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Kopijuoti pažymėtą laišką į:
   *[other] Kopijuoti pažymėtus laiškus ({ $count }) į:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Neseniai naudoti
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (dabartinis)
# a folder used last, with its account when there are several: "Archyvas (Darbas)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Perkeliama { $done } iš { $messages } (paskirtis: { $folder })...
# review: new
transfer-copying = Kopijuojama { $done } iš { $messages } (paskirtis: { $folder })...
# review: new
transfer-another-account = kita paskyra
# review: new
transfer-folder-gone = paskirties aplanko nebėra
# review: new
transfer-not-on-server = laiško serveryje nebėra
# review: new
transfer-not-moved = { $count ->
   *[other] Nepavyko perkelti į kitą paskyrą: { $messages } ({ $reason })
}
# review: new
transfer-not-copied = { $count ->
   *[other] Nepavyko nukopijuoti į kitą paskyrą: { $messages } ({ $reason })
}
# review: new
transfer-none-moved = Nepavyko perkelti nė vieno laiško
# review: new
transfer-none-copied = Nepavyko nukopijuoti nė vieno laiško

## Messages as files

# review: new
export-not-in-time = laiško nepavyko laiku atsisiųsti
# review: new
export-not-saved = Nepavyko įrašyti { $failed } iš { $messages } ({ $problems })
# review: new
export-not-attached = laiškų nepavyko pridėti: { $error }
# the status bar after Save As with several: "Įrašyta: 3 laiškai (paskirtis: Darbalaukis)"
# review: new
saved-to = { $count ->
   *[other] Įrašyta: { $messages } (paskirtis: { $folder })
}
# review: new
download-progress = Atsisiunčiama { $done } iš { $total }
# review: new
download-done = Atsisiųsta { $size }
# review: new
downloading-messages = { $count ->
   *[other] Atsisiunčiama: { $messages }...
}
# the status bar after files are dropped on a folder: "Įdėta: 3 laiškai (paskirtis: Archyvas)"
# review: new
import-put = { $count ->
   *[other] Įdėta: { $messages } (paskirtis: { $folder })
}
# review: new
import-not-put = Šie failai nebuvo įdėti į aplanką:

    { $problems }

## Problems the windows show

# review: new
error-store = vietinė saugykla: { $error }
# review: new
error-not-found = nerasta
# review: new
error-closed = baigiamas darbas
# review: new
error-other-account = naršyklėje prisijungta kaip { $email }, o ne prie šios paskyros
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = serveris nepriėmė prisijungimo ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = nepavyko prisijungti prie serverio ({ $reason })
# review: new
error-in-use = jos negalima pašalinti, kol per ją jungiasi paskyros: { $accounts }
# review: new
error-turned-off = ši prisijungimo programa naujoms paskyroms išjungta
# review: new
error-folder-name = aplanko pavadinimas turi būti nuo 1 iki 200 simbolių ilgio ir negali turėti valdymo simbolių
# review: new
error-folder-separator = šiame serveryje aplanko pavadinime negali būti „{ $separator }“
# review: new
error-folder-special = aplanko „Gauti laiškai“ ir specialiųjų aplankų pervardyti ar panaikinti negalima
# review: new
error-no-recipients = laiškas neturi gavėjų
# review: new
error-bad-address = „{ $address }“ nėra el. pašto adresas
# review: new
error-not-own-address = { $address } nėra vienas iš šios paskyros siuntėjo adresų. Įtraukite jį į lauką „Kiti adresai, iš kurių siunčiate“ paskyros ypatybėse.
# review: new
rule-query-refused = Taisyklės negali filtruoti pagal aplanką ar datą ({ $words }).
# review: new
rule-no-query = Įveskite gaunamų laiškų paieškos kriterijus.
# review: new
rule-no-action = Pasirinkite bent vieną taisyklės veiksmą.
# review: new
error-attachment = Nepavyko perskaityti { $path }: { $error }
# review: new
error-no-drafts = paskyroje nėra aplanko „Juodraščiai“, į kurį būtų galima įrašyti laišką
# review: new
error-draft-attachment = nepavyko išsaugoti juodraščio priedo: { $error }
# review: new
error-password-not-saved = nepavyko įrašyti slaptažodžio kitam paleidimui: { $error }
# review: new
error-sign-in-not-saved = nepavyko įrašyti naujų prisijungimo duomenų kitam paleidimui: { $error }
# review: new
error-import-unreadable = Negalima perskaityti { $path }: { $error }
# review: new
error-import-too-large = { $path } yra didesnis nei 50 MB
# review: new
error-import-not-mail = { $path } nėra el. laiškas
# review: new
error-list-answered = adresatų sąrašo serveris grąžino būseną { $status }
# review: new
error-not-built = laiško nepavyko sudaryti
# review: new
error-outbox-waits = { $count ->
    [one] { $count } laiškas laukia aplanke „Siunčiami laiškai“ ir bus išsiųstas kito siuntimo ir gavimo metu
    [few] { $count } laiškai laukia aplanke „Siunčiami laiškai“ ir bus išsiųsti kito siuntimo ir gavimo metu
   *[other] { $count } laiškų laukia aplanke „Siunčiami laiškai“ ir bus išsiųsta kito siuntimo ir gavimo metu
}
# review: new
error-draft-not-removed = ankstesnio laiško juodraščio nepavyko pašalinti iš aplanko „Juodraščiai“: { $reason }
# review: new
error-sent-but = laiškas išsiųstas, bet { $problem }
# review: new
error-sent-still-in-outbox = jis vis dar yra aplanke „Siunčiami laiškai“: { $error }
# review: new
error-sent-no-copy = nepavyko įrašyti kopijos į aplanką „Išsiųsti laiškai“: { $reason }
# review: new
error-no-password = šiai paskyrai nėra slaptažodžio
# review: new
error-no-sign-in = šiai paskyrai nėra prisijungimo duomenų
# review: new
error-provider-missing = ši versija negali prisijungti prie { $provider }: gal jos prisijungimo programa pašalinta?
# review: new
error-provider-servers = šios paskyros serveriai nesutampa su jos prisijungimo programos serveriais
# review: new
error-app-scopes = { $reason }. Pašto serveris nepriėmė prisijungimo programos prieigos rakto: patikrinkite, ar programos teisės (scopes) suteikia prieigą prie pašto
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google dar nepatvirtino Inbox Classic, todėl leidžia prisijungti tik bandomiesiems naudotojams. Naudokite savo Google prisijungimo programą arba programos slaptažodį, o jei esate bandomasis naudotojas, įjunkite ją lange „Prisijungimo programos“ (Failas > Paskyros).
# review: new
sign-in-off-other = Ji buvo išjungta lange „Prisijungimo programos“ (Failas > Paskyros), kur ją galima vėl įjungti.
# review: new
sign-in-app-no-name = prisijungimo programai reikia pavadinimo
# review: new
sign-in-app-no-client = trūksta kliento ID
# review: new
sign-in-app-no-scopes = prisijungimo programai reikia teisių (scopes), kurios suteikia prieigą prie pašto
# review: new
sign-in-app-bad-host = { $server } serverio adreso trūksta arba jis nėra tinkamas pagrindinio kompiuterio vardas
# review: new
sign-in-app-plain = { $server } serveris turi naudoti SSL/TLS arba STARTTLS
# review: new
sign-in-app-not-checked = išdavėjas dar nepatikrintas
# review: new
sign-in-app-issuer-changed = išdavėjas pasikeitė: įveskite kliento paslaptį dar kartą arba ją pašalinkite
# review: new
sign-in-register-google = Google Cloud Console sukurkite OAuth klientą, kurio tipas Desktop app, o jo sutikimo ekrane nurodykite teisę https://mail.google.com/. Kol programa bandoma, prisijungti gali tik jos bandomieji naudotojai.
# review: new
sign-in-register-microsoft = Microsoft Entra užregistruokite programą su platforma Mobile and desktop applications, peradresavimo URI http://localhost, leistais viešojo kliento srautais ir deleguotomis teisėmis IMAP.AccessAsUser.All, SMTP.Send ir offline_access. Jei tik savo organizacijai, kaip išdavėją naudokite https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Užregistruokite vietinį (viešąjį) klientą su toliau nurodytu peradresavimo URI; paslaugų teikėjas turi leisti bet kurį jo prievadą (RFC 8252). Įtraukite teisę, kuria paslaugų teikėjas suteikia prieigą prie pašto.

## Calendar invitations

# review: new
repeats = Kartojasi
# review: new
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
# review: new
repeats-on = { $repeats }: { $days }
# "Kas savaitę, 10 kartų"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, { $count } kartą
    [few] { $repeats }, { $count } kartus
   *[other] { $repeats }, { $count } kartų
}
# review: new
day-monday = pirmadienis
# review: new
day-tuesday = antradienis
# review: new
day-wednesday = trečiadienis
# review: new
day-thursday = ketvirtadienis
# review: new
day-friday = penktadienis
# review: new
day-saturday = šeštadienis
# review: new
day-sunday = sekmadienis

## AI agents

agent-level-read = Skaityti paštą: peržiūrėti aplankus, laiškus ir pokalbius, ieškoti laiškų bei kontaktų ir peržiūrėti laiškų taisykles
# review: changed
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
# review: new
agent-too-many-changes = Per daug pakeitimų per pastarąsias 30 dienų: šis agentas jų atliko tiek, kiek Inbox Classic vienai programai saugo žurnale. Daugiau galės atlikti, kai seniausiems sukaks 30 dienų.
# review: new
agent-too-many-reads = Per daug skaityta per pastarąsias 30 dienų: šis agentas perskaitė tiek, kiek Inbox Classic vienai programai saugo žurnale. Daugiau galės skaityti, kai seniausiems skaitymams sukaks 30 dienų.
# review: new
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
# review: new
agent-log-flag-color = Pažymėtas { $color ->
    [red] raudona vėliavėle
    [orange] oranžine vėliavėle
    [yellow] geltona vėliavėle
    [green] žalia vėliavėle
    [blue] mėlyna vėliavėle
    [purple] violetine vėliavėle
   *[gray] pilka vėliavėle
}: „{ $subject }“
# review: new
agent-log-renamed = Aplankas „{ $old }“ pervardytas į „{ $name }“
# review: new
agent-log-watched = Pradėtas stebėti pokalbis „{ $subject }“
# review: new
agent-log-ignored = Pradėtas ignoruoti pokalbis „{ $subject }“
# review: new
agent-log-unmarked = Nebestebimas ir nebeignoruojamas pokalbis „{ $subject }“
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = { $count ->
    [one] perskaitytas { $count } laiškas
    [few] perskaityti { $count } laiškai
   *[other] perskaityta { $count } laiškų
}
# review: new
agent-reads-attachments = { $count ->
    [one] atidarytas { $count } priedas
    [few] atidaryti { $count } priedai
   *[other] atidaryta { $count } priedų
}
# review: new
agent-reads-searches = { $count ->
    [one] ieškota { $count } kartą
    [few] ieškota { $count } kartus
   *[other] ieškota { $count } kartų
}
# review: new
agent-reads-lists = { $count ->
    [one] laiškų sąrašai peržiūrėti { $count } kartą
    [few] laiškų sąrašai peržiūrėti { $count } kartus
   *[other] laiškų sąrašai peržiūrėti { $count } kartų
}
# each read under that row
# review: new
agent-read-message = Perskaitytas laiškas „{ $subject }“
# review: new
agent-read-conversation = { $count ->
    [one] Perskaitytas pokalbis „{ $subject }“ ({ $count } laiškas)
    [few] Perskaitytas pokalbis „{ $subject }“ ({ $count } laiškai)
   *[other] Perskaitytas pokalbis „{ $subject }“ ({ $count } laiškų)
}
# review: new
agent-read-attachment = Atidarytas laiško „{ $subject }“ priedas „{ $name }“
# review: new
agent-read-search = { $count ->
    [one] Ieškota „{ $query }“: rastas { $count } laiškas
    [few] Ieškota „{ $query }“: rasti { $count } laiškai
   *[other] Ieškota „{ $query }“: rasta { $count } laiškų
}
# review: new
agent-read-people = Ieškota kontaktų, kurių vardas ar adresas prasideda „{ $query }“
# review: new
agent-read-list = { $count ->
    [one] Peržiūrėtas { $count } laiškas aplanke „{ $folder }“
    [few] Peržiūrėti { $count } laiškai aplanke „{ $folder }“
   *[other] Peržiūrėta { $count } laiškų aplanke „{ $folder }“
}
# review: new
agent-read-changes = { $count ->
    [one] Peržiūrėtas { $count } naujas laiškas
    [few] Peržiūrėti { $count } nauji laiškai
   *[other] Peržiūrėta { $count } naujų laiškų
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = Iš programėlės { $terminal } paleistos programos
# review: new
agent-terminal-programs-windows = Iš terminalo ({ $terminal }) paleistos programos
# review: new
agent-terminal-programs-linux = Iš terminalo ({ $terminal }) paleistos programos
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = Iš programėlės { $terminal } paleista programa
# review: new
agent-terminal-program-windows = Iš terminalo ({ $terminal }) paleista programa
# review: new
agent-terminal-program-linux = Iš terminalo ({ $terminal }) paleista programa
# review: new
agent-connect-title-terminal = { $programs } nori naudotis jūsų paštu
# review: new
agent-connect-terminal-detail = Visi DI agentai, kuriuos paleidžiate iš šio terminalo, bendrai naudojasi čia suteikta prieiga. Norėdami suteikti agentui atskirą prieigą, agento MCP nustatymuose į jo argumentus įtraukite --name ir savo pasirinktą pavadinimą.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = paslaugų teikėjas nepateikė atnaujinimo rakto (refresh token)
# review: new
sign-in-no-account = paslaugų teikėjas nenurodė, kuri paskyra prisijungė
# review: new
sign-in-not-finished = prisijungimas nebaigtas
# review: new
secrets-unavailable = { $store } nepasiekiama
# review: new
secrets-unavailable-why = { $store } nepasiekiama: { $error }
# review: new
secrets-windows = Kredencialų tvarkytuvė
# review: new
secrets-mac = Raktinė
# review: new
secrets-linux = sistemos raktinė (Secret Service)
# review: new
error-no-such-file = tokio failo nėra
# review: new
cards-file-too-big = Šis failas per didelis, kad būtų adresų knygelė.
# review: new
ui-sender-added = Įtraukta į adresų knygelę: { $name }.
# review: new
ui-sender-known = Jau yra adresų knygelėje: { $name }.
# review: new
ui-sender-none = Šio laiško siuntėjas neturi el. pašto adreso, kurį būtų galima įtraukti.
# review: new
card-name-needed = Kontaktas neturi nei vardo, nei el. pašto adreso.
# a file of Import Address Book that could not be read: "contacts.vcf: tokio failo nėra"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Kodas iš { $domain }
# review: new
otp-copy = Kopijuoti
# review: new
otp-note = Įveskite jį tik { $domain } puslapyje.
# review: new
otp-old = Šis kodas išsiųstas daugiau nei valandą prieš jums atidarant laišką, todėl tikriausiai nebegalioja.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } dalyvis
        [few] { $count } dalyviai
       *[other] { $count } dalyvių
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code }: jūsų kodas svetainei { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Galioja
# review: new
pgp-key-expires = Galioja iki { $date }
# review: new
pgp-key-expired = Nebegalioja nuo { $date }
# review: new
pgp-key-revoked = Atšauktas
# review: new
pgp-key-revoked-why = Atšauktas: { $reason }
# review: new
pgp-key-not-valid = Negalioja
# review: new
pgp-key-locked = Naudoti negalima: jį saugantis raktas nebėra vietoje „{ $store }“. Vėl importuokite jo atsarginę kopiją.
# review: new
pgp-source-own = Sukurtas Inbox Classic
# review: new
pgp-source-file = Importuotas iš failo
# review: new
pgp-source-paste = Įklijuotas
# review: new
pgp-source-attachment = Iš laiško
# review: new
pgp-source-vcard = Iš kontakto kortelės
# review: new
pgp-source-wkd = Iš siuntėjo pašto paslaugų teikėjo
# review: new
pgp-source-keyserver = Iš keys.openpgp.org
# review: new
pgp-source-autocrypt = Iš laiško Autocrypt antraštės
# review: new
pgp-error-no-store = Privatieji raktai saugomi vietoje „{ $store }“, kurios naudoti negalima: { $error }
# review: new
pgp-error-wrong-passphrase = Slaptafrazė neteisinga.
# review: new
pgp-error-not-a-key = Tai nėra OpenPGP raktas.
# review: new
pgp-error-too-large = Raktas per didelis.
# review: new
pgp-error-unusable = Raktas naudoja seną arba silpną kriptografiją, todėl jo naudoti negalima.
# review: new
pgp-imported-private = { $count ->
    [one] Importuotas { $count } privatusis raktas.
    [few] Importuoti { $count } privatieji raktai.
   *[other] Importuota privačiųjų raktų: { $count }.
}
# review: new
pgp-imported-public = { $count ->
    [one] Importuotas { $count } raktas.
    [few] Importuoti { $count } raktai.
   *[other] Importuota raktų: { $count }.
}
# review: new
pgp-imported-pending = Adresams { $addresses } jau naudojamas kitas raktas: naujasis laukia kontakte, kol jį pasirinksite.
# review: new
pgp-error-needs-passphrase = Privatusis raktas apsaugotas slaptafraze. Įveskite ją, kad importuotumėte raktą.
# review: new
pgp-error-mismatch = Privatusis raktas nepriklauso savo viešajam raktui. Jis galėjo būti pakeistas.
# review: new
pgp-file-name-public = Viešasis raktas ({ $who }).asc
# review: new
pgp-file-name-private = Privačiojo rakto atsarginė kopija ({ $who }).asc
# review: new
pgp-pending = { $date } rastas kitas { $address } raktas.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Pasirašė { $signer }, raktas patikrintas
# review: new
pgp-part-signed = Pasirašė { $signer } (raktas nepatikrintas)
# review: new
pgp-part-other = Pasirašė { $signer }, kuris nėra siuntėjas
# review: new
pgp-part-unknown-key = Pasirašyta, bet raktas nežinomas
# review: new
pgp-part-not-signed = Nepasirašyta
# review: new
pgp-part-not-checked = Parašas netikrintas
# review: new
pgp-part-encrypted = Užšifruota. { $signature }
# review: new
pgp-part-no-key = Užšifruota raktu, kurio neturite
# review: new
pgp-part-changed = Užšifruota dalis pakeista pakeliui, todėl nerodoma
# review: new
pgp-part-unprotected = Užšifruota be apsaugos nuo pakeitimų, todėl nerodoma
# review: new
pgp-part-broken = Užšifruotos dalies perskaityti negalima
# review: new
pgp-why-mismatch = Parašas neatitinka šio teksto
# review: new
pgp-why-weak-hash = Parašas naudoja { $hash }, kuris nebėra saugus
# review: new
pgp-why-key-expired = Pasirašyta po to, kai raktas nustojo galioti ({ $date })
# review: new
pgp-why-key-revoked = Pasirašyta atšauktu raktu
# review: new
pgp-why-not-signing-key = Pasirašyta raktu, kuriuo pasirašyti negalima
# review: new
pgp-why-from-future = Parašo data yra ateityje
# review: new
pgp-why-signature-expired = Parašas nebegalioja
# review: new
pgp-why-key-not-valid = Pasirašyta negaliojančiu raktu
# review: new
pgp-why-not-for-you = Pasirašyta kitiems gavėjams ir persiųsta jums
pgp-why-not-key-in-use = Pasirašyta kitu raktu nei naudojamas adresui { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Paveikslėliai įkelti iš interneto
# review: new
pgp-error-no-own-key = Neturite { $address } rakto, kuriuo būtų galima pasirašyti ar šifruoti. Sukurkite jį per Įrankiai > Šifravimo raktai arba išjunkite pasirašymą ir šifravimą.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } neturi rakto, kuriuo būtų galima šifruoti.
   *[other] Šie gavėjai neturi rakto, kuriuo būtų galima šifruoti: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Šis laiškas cituoja arba persiunčia užšifruotą laišką, todėl jį galima siųsti tik užšifruotą. Įjunkite šifravimą arba pašalinkite cituojamą tekstą.
# review: new
pgp-error-protect = Laiško nepavyko pasirašyti ar užšifruoti: { $reason }
# review: new
pgp-found-keys = Rastas raktas: { $addresses }.
# review: new
pgp-found-none = Rakto nerasta: { $addresses }. Paprašykite atsiųsti jums savo viešąjį raktą.
# review: new
pgp-found-no-key = Rakto nerasta.
# review: new
pgp-find-unavailable = Šiuo metu raktų ieškoti nepavyko: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org išsiuntė patvirtinimo nuorodą adresu { $addresses }. Ją spustelėjus, jūsų raktas ten bus paskelbtas.
# review: new
pgp-publish-done = Jūsų raktas paskelbtas keys.openpgp.org adresams { $addresses }.
# review: new
pgp-publish-failed = Rakto paskelbti nepavyko: { $error }
# review: changed
pgp-keyserver-off = Raktų paieška keys.openpgp.org išjungta skiltyje { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Užšifruota ir pasirašyta: perskaityti gali tik jūs ir { $addresses }.
    [few] Užšifruota ir pasirašyta: perskaityti gali tik jūs ir { $count } jo gavėjai.
   *[other] Užšifruota ir pasirašyta: perskaityti gali tik jūs ir { $count } jo gavėjų.
}
# review: new
pgp-compose-encrypt-ready = Laiškas bus užšifruotas ir pasirašytas. Pridėkite gavėjų, kurių raktus turite.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } neturi rakto, todėl laiško dar negalima užšifruoti.
    [few] { $count } gavėjai neturi rakto, todėl laiško dar negalima užšifruoti: { $addresses }.
   *[other] { $count } gavėjų neturi rakto, todėl laiško dar negalima užšifruoti: { $addresses }.
}
# review: new
pgp-compose-looking = Ieškoma raktų: { $addresses }...
# review: new
pgp-compose-signed = Pasirašyta: gavėjai gali patikrinti, kad laiškas yra nuo jūsų ir nebuvo pakeistas.
# review: new
pgp-compose-reply-clear = Neužšifruota, nors laiškas, į kurį atsakoma arba kuris persiunčiamas, buvo užšifruotas.
# review: new
pgp-compose-encrypted-files = Pridėti užšifruoto laiško failai, todėl šį laišką galima siųsti tik užšifruotą. Įjunkite šifravimą arba pašalinkite tuos failus.
# review: new
pgp-compose-sign-tip = Pasirašyti laišką savo raktu, kad gavėjai galėtų patikrinti, jog jis nuo jūsų ir nebuvo pakeistas
# review: new
pgp-compose-sign-tip-encrypted = Užšifruotas laiškas visada pasirašomas
# review: new
pgp-compose-encrypt-tip = Užšifruoti laišką, kad jį galėtumėte perskaityti tik jūs ir jo gavėjai
# review: new
pgp-compose-make-key = Dar neturite { $address } rakto. Sukurti jį dabar? Su juo jūsų laiškus bus galima pasirašyti ir užšifruoti.
# review: new
pgp-compose-key-unusable = Jūsų { $address } rakto naudoti negalima ({ $state }). Atidarykite Šifravimo raktai, kad importuotumėte jo atsarginę kopiją arba sukurtumėte naują raktą.
# review: new
pgp-compose-encrypt-off-quote = Šis laiškas cituoja arba persiunčia užšifruotą laišką. Be šifravimo jo negalima išsiųsti, kol nepašalinsite to, ką jis cituoja. Vis tiek išjungti šifravimą?
# review: new
pgp-compose-encrypt-off-reply = Šis laiškas atsako į užšifruotą laišką arba jį persiunčia. Be šifravimo jūsų laišką pakeliui gali perskaityti bet kas, kas jį tvarko. Išjungti šifravimą?
# review: new
pgp-recipient-verified = Raktas patikrintas
# review: new
pgp-recipient-found = Raktas nepatikrintas
# review: new
pgp-recipient-own = Jūsų raktas
# review: new
pgp-recipient-looking = Ieškoma rakto...
# review: new
pgp-recipient-missing = Rakto nėra
# review: new
pgp-recipient-not-found = Rakto nėra: { $date } nerasta
# review: new
pgp-recipient-unusable = Rakto naudoti negalima: { $state }
# review: new
pgp-recipients-intro = Laiškas šifruojamas kiekvieno gavėjo raktu ir jūsų raktu.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] { $count } gavėjas neturi rakto, kuriuo būtų galima šifruoti. Raskite jo raktą, pašalinkite jį iš šio laiško arba išsiųskite laišką nešifruotą.
    [few] { $count } gavėjai neturi rakto, kuriuo būtų galima šifruoti. Raskite jų raktus, pašalinkite juos iš šio laiško arba išsiųskite laišką nešifruotą.
   *[other] { $count } gavėjų neturi rakto, kuriuo būtų galima šifruoti. Raskite jų raktus, pašalinkite juos iš šio laiško arba išsiųskite laišką nešifruotą.
}
# review: new
pgp-details-part = { $number } dalis: { $label }
# review: new
pgp-details-signed = Pasirašyta { $when } raktu { $key }
# review: new
pgp-details-unknown-key = Pasirašyta raktu { $key }, kurio neturite
# review: new
pgp-details-opened = Užšifruota jūsų raktu { $key }
# review: new
pgp-details-for = Užšifruota raktais: { $keys }
# review: new
pgp-details-plain = Nepasirašyta ir neužšifruota
# review: new
pgp-bar-parts = Šio laiško dalys ({ $count }): { $list }. Kiekviena dalis nurodo, kaip ji apsaugota.
# review: new
pgp-bar-count-verified = patikrinta: { $count }
# review: new
pgp-bar-count-good = { $count ->
    [one] { $count } pasirašyta arba užšifruota
    [few] { $count } pasirašytos arba užšifruotos
   *[other] { $count } pasirašytų arba užšifruotų
}
# review: new
pgp-bar-count-warning = reikia dėmesio: { $count }
# review: new
pgp-bar-count-neutral = be patvirtinto parašo: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Nustatymai
# review: new
setup-part-preferences = Langų nuostatos
# review: new
setup-part-accounts = Paskyros
# review: new
setup-part-sign-in-apps = Prisijungimo programos
# review: new
setup-part-contacts = Kontaktai ir grupės
# review: new
setup-part-keys = Šifravimo raktai
# review: new
setup-part-rules = Laiškų taisyklės
# review: new
setup-part-trusted-senders = Patikimi siuntėjai
# review: new
setup-holds-settings = { $count ->
    [one] { $count } nustatymas
    [few] { $count } nustatymai
   *[other] { $count } nustatymų
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } nuostata
    [few] { $count } nuostatos
   *[other] { $count } nuostatų
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } paskyra
    [few] { $count } paskyros
   *[other] { $count } paskyrų
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } prisijungimo programa
    [few] { $count } prisijungimo programos
   *[other] { $count } prisijungimo programų
}
# review: new
setup-holds-built-in = Kurios įtaisytosios prisijungimo programos įjungtos
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } kontaktas
    [few] { $count } kontaktai
   *[other] { $count } kontaktų
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } grupė
    [few] { $count } grupės
   *[other] { $count } grupių
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } jūsų raktas
    [few] { $count } jūsų raktai
   *[other] { $count } jūsų raktų
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } kontakto raktas
    [few] { $count } kontaktų raktai
   *[other] { $count } kontaktų raktų
}
# review: new
setup-holds-rules = { $count ->
    [one] { $count } taisyklė
    [few] { $count } taisyklės
   *[other] { $count } taisyklių
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] { $count } patikimas siuntėjas
    [few] { $count } patikimi siuntėjai
   *[other] { $count } patikimų siuntėjų
}
# review: new
setup-sign-in-password = Slaptažodis
# review: new
setup-account-secret-password = Jos slaptažodis yra faile.
# review: new
setup-account-secret-token = Jos prisijungimas yra faile.
# review: new
setup-account-asks-password = Po importo ji paprašys slaptažodžio.
# review: new
setup-account-signs-in-again = Po importo prie jos prisijungsite iš naujo.
# review: new
setup-account-here = Ji čia jau nustatyta, todėl praleidžiama.
# review: new
setup-account-no-app = Ji jungiasi per { $app }, kuri čia nenustatyta. Importuokite ir prisijungimo programas.
# review: new
setup-invalid-address = „{ $address }“ nėra el. pašto adresas.
# review: new
setup-invalid-server = { $server } serveris neturi tinkamo vardo arba prievado.
# review: new
setup-invalid-user = Ji neturi naudotojo vardo.
# review: new
setup-invalid-sign-in = Ji jungiasi būdu, kurio Inbox Classic nežino.
# review: new
setup-error-empty = Failas tuščias.
# review: new
setup-error-too-large = Failas per didelis, kad būtų Inbox Classic sąranka.
# review: new
setup-error-not-setup = Šis failas nėra Inbox Classic sąranka.
# review: new
setup-error-damaged = Sąrankos failas sugadintas, jo perskaityti negalima.
# review: new
setup-error-newer = Šią sąranką įrašė naujesnė Inbox Classic versija ({ $version }). Atnaujinkite Inbox Classic ir importuokite ją dar kartą.
# review: new
setup-error-needs-passphrase = Ši sąranka apsaugota slaptafraze. Įveskite slaptafrazę, su kuria ji buvo įrašyta.
# review: new
setup-error-wrong-passphrase = Tai ne ta slaptafrazė, su kuria buvo įrašyta ši sąranka.
# review: new
setup-error-changed = Sąrankos failas po įrašymo buvo pakeistas arba sugadintas, todėl jo importuoti negalima.
# review: new
setup-error-read = Sąrankos failo perskaityti nepavyko: { $error }
# review: new
setup-error-write = Sąrankos įrašyti nepavyko: { $error }
# review: new
setup-error-no-parts = Pasirinkite bent vieną dalį.
# review: new
setup-left-out = { $count ->
    [one] Dalyje „{ $part }“ yra { $count } įrašas, kurio negalima naudoti, todėl jis praleidžiamas.
    [few] Dalyje „{ $part }“ yra { $count } įrašai, kurių negalima naudoti, todėl jie praleidžiami.
   *[other] Dalyje „{ $part }“ yra { $count } įrašų, kurių negalima naudoti, todėl jie praleidžiami.
}
# review: new
setup-imported-settings = Nustatymai pakeisti.
# review: new
setup-imported-preferences = Langų nuostatos pakeistos.
# review: new
setup-added-accounts = { $count ->
    [one] Pridėta { $count } paskyra.
    [few] Pridėtos { $count } paskyros.
   *[other] Pridėta paskyrų: { $count }.
}
# review: new
setup-skipped-here = { $address } čia jau nustatyta, todėl praleista.
# review: new
setup-skipped-no-app = { $address } praleista: ji jungiasi per { $app }, kuri čia nenustatyta.
# review: new
setup-skipped-invalid = { $address } praleista: { $reason }
# review: new
setup-asks-password = { $address } paprašys slaptažodžio, kai jungsis.
# review: new
setup-signs-in-again = { $address } paprašys prisijungti iš naujo, kai jungsis.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Pridėta { $count } prisijungimo programa.
    [few] Pridėtos { $count } prisijungimo programos.
   *[other] Pridėta prisijungimo programų: { $count }.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } prisijungimo programa čia jau nustatyta.
    [few] { $count } prisijungimo programos čia jau nustatytos.
   *[other] Prisijungimo programų, kurios čia jau nustatytos: { $count }.
}
# review: new
setup-added-contacts = { $count ->
    [one] Į adresų knygelę pridėtas { $count } kontaktas.
    [few] Į adresų knygelę pridėti { $count } kontaktai.
   *[other] Į adresų knygelę pridėta kontaktų: { $count }.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } kontaktas jau yra adresų knygelėje.
    [few] { $count } kontaktai jau yra adresų knygelėje.
   *[other] Kontaktų, kurie jau yra adresų knygelėje: { $count }.
}
# review: new
setup-added-groups = { $count ->
    [one] Pridėta arba papildyta { $count } grupė.
    [few] Pridėtos arba papildytos { $count } grupės.
   *[other] Pridėta arba papildyta grupių: { $count }.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Pridėtas { $count } jūsų raktas.
    [few] Pridėti { $count } jūsų raktai.
   *[other] Pridėta jūsų raktų: { $count }.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Pridėtas { $count } kontakto raktas.
    [few] Pridėti { $count } kontaktų raktai.
   *[other] Pridėta kontaktų raktų: { $count }.
}
# review: new
setup-added-rules = { $count ->
    [one] Pridėta { $count } laiškų taisyklė.
    [few] Pridėtos { $count } laiškų taisyklės.
   *[other] Pridėta laiškų taisyklių: { $count }.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } laiškų taisyklė čia jau yra.
    [few] { $count } laiškų taisyklės čia jau yra.
   *[other] Laiškų taisyklių, kurios čia jau yra: { $count }.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } laiškų taisyklė skirta paskyrai, kurios čia nėra, todėl praleista.
    [few] { $count } laiškų taisyklės skirtos paskyroms, kurių čia nėra, todėl praleistos.
   *[other] Laiškų taisyklių, skirtų paskyroms, kurių čia nėra, praleista: { $count }.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } laiškų taisyklė perkelia laiškus į aplanką, kuris atsiras, kai jo paskyra bus sinchronizuota.
    [few] { $count } laiškų taisyklės perkelia laiškus į aplankus, kurie atsiras, kai jų paskyros bus sinchronizuotos.
   *[other] Laiškų taisyklių, kurios perkelia laiškus į aplankus, atsirasiančius sinchronizavus jų paskyras: { $count }.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Pridėtas { $count } patikimas siuntėjas.
    [few] Pridėti { $count } patikimi siuntėjai.
   *[other] Pridėta patikimų siuntėjų: { $count }.
}
# review: new
setup-nothing = Nieko neimportuota.
# review: new
setup-account-servers = { $imap } ir { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic nustatymai ir paskyros
# review: new
setup-skipped-unreachable = { $name } praleista: nepavyko pasiekti jos prisijungimo paslaugos. Pridėkite ją dar kartą lange „Prisijungimo programos“.
# review: new
attachment-runs-programs = Failas „{ $name }“ gali paleisti programas, todėl Inbox Classic jo neatidaro. Įrašykite jį, tada atidarykite patys, jei pasitikite jo šaltiniu.
# review: new
attachment-decrypted-note = Šis priedas yra iš užšifruoto laiško. Kad galėtų jį atidaryti, Inbox Classic laiko jį iššifruotą šiame kompiuteryje, jūsų aplanke, kurį Inbox Classic ištuština po paros.
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

# review: new
preview-pdf-option = Rodyti PDF failus laiškuose
# review: new
preview-pdf-off = PDF failai laiškuose nerodomi.
# review: new
preview-pdf-off-crashed = PDF failas uždarė Inbox Classic, kol buvo rodomas, todėl PDF failai laiškuose nebėra rodomi. Paveikslėliai vis dar rodomi. Norėdami vėl rodyti PDF failus, skiltyje { $settings } įjunkite { $option }.
# review: new
preview-pdf-details = { $count ->
    [one] { $count } puslapis, { $size }
    [few] { $count } puslapiai, { $size }
    [many] { $count } puslapio, { $size }
   *[other] { $count } puslapių, { $size }
}
# review: new
preview-page-alt = { $name }, { $page } puslapis iš { $count }
# review: new
preview-more-pages = { $count ->
    [one] Atidarykite, kad matytumėte visą { $count } puslapį
    [few] Atidarykite, kad matytumėte visus { $count } puslapius
    [many] Atidarykite, kad matytumėte visus { $count } puslapio
   *[other] Atidarykite, kad matytumėte visus { $count } puslapių
}
# review: new
preview-more-files = { $count ->
    [one] Dar { $count } failas yra sąraše viršuje
    [few] Dar { $count } failai yra sąraše viršuje
    [many] Dar { $count } failo yra sąraše viršuje
   *[other] Dar { $count } failų yra sąraše viršuje
}
# review: new
preview-tile-downloading = Atsisiunčiama…
# review: new
preview-tile-format = { $format } paveikslėliai kol kas nerodomi
# review: new
preview-tile-password = Apsaugota slaptažodžiu: atidarykite, kad įvestumėte slaptažodį
# review: new
preview-tile-too-large = Per didelis, kad būtų rodomas
# review: new
preview-tile-unreadable = Negalima parodyti
# review: new
preview-tile-timed-out = Rodymas užtruko per ilgai
# review: new
preview-tile-crashed = Nerodoma: šis failas kartą uždarė Inbox Classic
# review: new
preview-tile-off = Nerodoma, kol Inbox Classic nebus paleista iš naujo
# review: new
preview-not-printed = { $name } ({ $details }) nespausdinamas. Atidarykite jį, kad atspausdintumėte.
