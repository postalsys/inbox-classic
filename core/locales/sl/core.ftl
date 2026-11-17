# Slovenščina. Osnutek, čaka na pregled naravnega govorca (glej core/locales/GLOSSARY.md).
# Placeables in { $braces } are filled in by the code. Plurals: [one], [two], [few] and *[other] (CLDR for sl).

## Counts and sizes

messages = { $count ->
    [one] { $count } sporočilo
    [two] { $count } sporočili
    [few] { $count } sporočila
   *[other] { $count } sporočil
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] { $count } bajt
    [two] { $count } bajta
    [few] { $count } bajti
   *[other] { $count } bajtov
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Izklopljeno
# review: new
send-delay-seconds = { $count ->
    [one] { $count } sekunda
    [two] { $count } sekundi
    [few] { $count } sekunde
   *[other] { $count } sekund
}
# the status bar: "12 messages, 3 unread"
# review: new
list-counts = { $messages }, neprebrana: { $unread }
# review: new
list-counts-selected = { $messages }, neprebrana: { $unread }, izbrana: { $selected }
# the status bar while searching: "12 found, 3 unread"
# review: new
list-counts-found = Najdena: { $found }, neprebrana: { $unread }
# review: new
list-counts-found-selected = Najdena: { $found }, neprebrana: { $unread }, izbrana: { $selected }
# review: new
list-counts-none = Ni najdenih sporočil

## Special folders, as Outlook names them

# review: new
folder-inbox = Prejeto
# review: new
folder-sent = Poslano
# review: new
folder-deleted = Izbrisano
# review: new
folder-drafts = Osnutki
# review: new
folder-junk = Neželena e-pošta
# review: new
folder-archive = Arhiv

## The reading pane

# review: new
reader-no-message = Nobeno sporočilo ni izbrano.
# review: new
reader-downloading = Prenašanje sporočila…
# review: new
reader-downloading-detail = Sporočilo bo prikazano tukaj, ko bo prenos končan.
# review: new
reader-downloading-size = Sporočilo je veliko { $size }. Prikazano bo tukaj, ko bo preneseno.
# review: new
reader-failed = Sporočila ni bilo mogoče prenesti
# review: new
reader-failed-network = Poštni strežnik ni dosegljiv ({ $reason }).
# review: new
reader-failed-sign-in = Poštni strežnik ni sprejel prijave ({ $reason }). Preverite geslo ali se znova prijavite v meniju Datoteka > Računi.
# review: new
reader-failed-security = Povezave s poštnim strežnikom ni bilo mogoče zavarovati ({ $reason }).
# review: new
reader-failed-other = Poštni strežnik je odgovoril: { $reason }.
# review: new
reader-retry-note = Poskus se bo ponovil, ko se račun znova poveže.
# review: new
reader-unreadable = Tega sporočila ni mogoče prikazati: { $error }
# review: new
message-source-title = Izvorna koda sporočila: { $subject }
# review: new
message-source-untitled = Izvorna koda sporočila

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Od
# review: new
header-date = Datum
# review: new
header-to = Za
# review: new
header-cc = Kp
# review: new
header-sent = Poslano
# review: new
header-subject = Zadeva
# review: new
header-security = Varnost
# review: new
header-part = Del { $number }
# review: new
quote-original = ----- Izvirno sporočilo -----
# review: new
fold-show-earlier = Pokaži starejša sporočila

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Vaše sporočilo ni bilo dostavljeno
# review: new
bounce-delayed = Vaše sporočilo še ni bilo dostavljeno
# review: new
bounce-delayed-note = Vaš poštni strežnik ga še vedno poskuša dostaviti. Ni ga treba poslati znova.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Pokaži vrnjeno sporočilo
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Pokaži zakasnjeno sporočilo
# review: new
bounce-what-to-do = Kaj lahko storite:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Zaenkrat nič. Če ga še vedno ne bo mogoče dostaviti, boste prejeli novo obvestilo.
# review: new
bounce-delayed-row-do = Zaenkrat nič. Vaš poštni strežnik ga še poskuša dostaviti, in če mu ne bo uspelo, boste prejeli novo obvestilo.
# folds the receiving server's own words
# review: new
bounce-details = Podrobnosti
# a recipient the notice does not name
# review: new
bounce-someone = Prejemnik
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Strežnik: { $server }
# review: new
bounce-status = Stanje: { $status }
# review: new
bounce-reported-by = Sporočil: { $server }
# review: new
bounce-retry-minutes = Prejemni strežnik je prosil, naj se pred naslednjim poskusom počaka { $count ->
    [one] { $count } minuto
    [two] { $count } minuti
    [few] { $count } minute
   *[other] { $count } minut
}.
# review: new
bounce-retry-hours = Prejemni strežnik je prosil, naj se pred naslednjim poskusom počaka { $count ->
    [one] { $count } uro
    [two] { $count } uri
    [few] { $count } ure
   *[other] { $count } ur
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Črni seznam: { $lists }
# review: new
bounce-user-unknown = Naslov ne obstaja
# review: new
bounce-user-unknown-why = Prejemni strežnik nima poštnega predala s tem naslovom. Morda je napačno vpisan ali pa ga oseba ne uporablja več.
# review: new
bounce-user-unknown-do = Preverite črkovanje naslova ali vprašajte osebo, kateri naslov uporablja zdaj.
# review: new
bounce-invalid-address = Naslov ni veljaven
# review: new
bounce-invalid-address-why = Naslov ni zapisan v obliki, na katero je mogoče poslati pošto.
# review: new
bounce-invalid-address-do = Poiščite tipkarske napake, na primer presledek, manjkajočo črko ali nič za znakom @.
# review: new
bounce-mailbox-disabled = Poštni predal je zaprt
# review: new
bounce-mailbox-disabled-why = Naslov obstaja, vendar je njegov poštni predal izklopljen ali se ne uporablja več.
# review: new
bounce-mailbox-disabled-do = Osebo dosezite drugače in jo vprašajte za naslov, ki ga uporablja zdaj.
# review: new
bounce-mailbox-full = Poštni predal je poln
# review: new
bounce-mailbox-full-why = V prejemnikovem poštnem predalu ni prostora za novo pošto.
# review: new
bounce-mailbox-full-do = Pošljite ga znova čez nekaj dni ali osebo obvestite drugače. Velike priponke so zavrnjene najprej.
# review: new
bounce-spam-blocked = Zavrnjeno kot vsiljena pošta
# review: new
bounce-spam-blocked-why = Prejemni strežnik je sporočilo prepoznal kot vsiljeno pošto.
# review: new
bounce-spam-blocked-do = Pošljite ga znova brez tistega, kar je videti kot vsiljena pošta, na primer veliko povezav, skrajšanih povezav ali velike priponke. Če se to ponavlja, vprašajte svojega ponudnika e-pošte.
# review: new
bounce-virus-detected = Zavrnjeno zaradi virusa
# review: new
bounce-virus-detected-why = Prejemni strežnik je v sporočilu ali njegovih priponkah našel virus ali drugo škodljivo vsebino.
# review: new
bounce-virus-detected-do = Priponke preverite s protivirusnim programom. Nekateri strežniki zavrnejo vsak program ali arhiv, zato take datoteke raje delite s povezavo.
# review: new
bounce-ip-blocklisted = Vaš poštni strežnik je na črnem seznamu
# review: new
bounce-ip-blocklisted-why = Prejemni strežnik zavrača pošto s strežnika, ki je poslal vašo, ker je naslov tega strežnika na črnem seznamu.
# review: new
bounce-ip-blocklisted-do = Težava ni v sporočilu. To obvestilo posredujte svojemu ponudniku e-pošte in ga prosite, naj strežnik odstrani s seznama.
# review: new
bounce-domain-blocklisted = Domena je na črnem seznamu
# review: new
bounce-domain-blocklisted-why = Prejemni strežnik zavrača sporočilo, ker je domena vašega naslova ali domena iz povezav v sporočilu na črnem seznamu.
# review: new
bounce-domain-blocklisted-do = Če ima sporočilo povezave, ga poskusite poslati brez njih. Sicer to obvestilo posredujte tistemu, ki skrbi za pošto vaše domene.
# review: new
bounce-policy-blocked = Zavrnjeno po pravilih prejemnega strežnika
# review: new
bounce-policy-blocked-why = Pravila prejemnega strežnika tega sporočila ne prepustijo, na primer zaradi velikosti, priponk ali pošiljatelja.
# review: new
bounce-policy-blocked-do = Razlog pogosto navaja strežnik sam pod Podrobnostmi. Vprašajte prejemnika, ali lahko sprejme takšno pošto.
# review: new
bounce-geo-blocked = Zavrnjeno zaradi izvora
# review: new
bounce-geo-blocked-why = Prejemni strežnik ne sprejema pošte iz države ali omrežja, v katerem je vaš poštni strežnik.
# review: new
bounce-geo-blocked-do = Osebo dosezite drugače ali o tem vprašajte svojega ponudnika e-pošte.
# review: new
bounce-relay-denied = Strežnik ga ni posredoval naprej
# review: new
bounce-relay-denied-why = Strežnik ni hotel posredovati sporočila naprej, pogosto zato, ker je bilo poslano brez prijave ali prek strežnika, ki ne skrbi za tega prejemnika.
# review: new
bounce-relay-denied-do = V meniju Datoteka > Računi preverite strežnik za odhodno pošto in ali se ta prijavlja.
# review: new
bounce-auth-failure = Vašega naslova pošiljatelja ni bilo mogoče preveriti
# review: new
bounce-auth-failure-why = Prejemni strežnik ni mogel potrditi, da je sporočilo res prišlo iz vaše domene (SPF, DKIM ali DMARC).
# review: new
bounce-auth-failure-do = To obvestilo posredujte tistemu, ki skrbi za pošto vaše domene: njene nastavitve je treba popraviti. Medtem morda pomaga pošiljanje prek strežnika vašega ponudnika.
# review: new
bounce-rate-limited = Preveč pošte naenkrat
# review: new
bounce-rate-limited-why = Prejemni strežnik zaenkrat sprejema manj sporočil z vašega poštnega strežnika.
# review: new
bounce-rate-limited-do = Malo počakajte in ga pošljite znova. Ko pišete veliko ljudem, pošiljajte manjšemu številu naenkrat.
# review: new
bounce-greylisting = Za trenutek zadržano
# review: new
bounce-greylisting-why = Prejemni strežnik neznane pošiljatelje prosi, naj poskusijo malo pozneje, kar je pogosta zaščita pred vsiljeno pošto.
# review: new
bounce-greylisting-do = Nič. Poštni strežniki poskusijo znova sami in sporočilo je navadno dostavljeno v eni uri.
# review: new
bounce-server-error = Prejemni strežnik je imel težavo
# review: new
bounce-server-error-why = Prejemni strežnik ni bil dosegljiv ali zaradi lastne težave ni mogel sprejeti sporočila.
# review: new
bounce-server-error-do = Pošljite ga znova pozneje. Če se napaka ponavlja, preverite del naslova za znakom @, ali je pravilno napisan.
# review: new
bounce-unknown = Ni dostavljeno
# review: new
bounce-unknown-why = Obvestilo ne pove jasno, zakaj.
# review: new
bounce-unknown-do = Več morda povedo besede strežnika pod Podrobnostmi. Če ne pomagajo, to obvestilo posredujte svojemu ponudniku e-pošte.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } izbrano sporočilo
    [two] { $count } izbrani sporočili
    [few] { $count } izbrana sporočila
   *[other] { $count } izbranih sporočil
}
# review: new
selection-unread = Neprebrana: { $count }
# review: new
selection-flagged = Z zastavico: { $count }
# review: new
delete-for-good-one = To sporočilo bo trajno izbrisano. Ga želite izbrisati?
# review: new
delete-for-good-all = Vsa izbrana sporočila ({ $count }) bodo trajno izbrisana. Jih želite izbrisati?
# review: new
delete-for-good-some = Nekatera sporočila ({ $count } od { $total }) bodo trajno izbrisana. Želite izbrisati sporočila?
# review: new
done-read = { $count ->
   *[other] Označeno kot prebrano: { $messages }
}
# review: new
done-unread = { $count ->
   *[other] Označeno kot neprebrano: { $messages }
}
# review: new
done-flagged = { $count ->
   *[other] Označeno z zastavico: { $messages }
}
# review: new
done-unflagged = Zastavica odstranjena: { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Trajno izbrisano: { $messages }
}
# review: new
done-archived = { $count ->
   *[other] Arhivirano: { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Premaknjeno v { $folder }: { $messages }
}
# review: new
done-copied = { $count ->
   *[other] Kopirano v { $folder }: { $messages }
}
# review: new
done-moving = { $count ->
   *[other] Premikanje v { $folder }: { $messages }...
}
# review: new
done-copying = { $count ->
   *[other] Kopiranje v { $folder }: { $messages }...
}
# review: new
done-moved-back = { $count ->
   *[other] Vrnjeno v { $folder }: { $messages }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Spremljate pogovor
   *[other] Spremljate pogovore: { $count }
}
# review: new
done-unwatched = { $count ->
    [one] Pogovora ne spremljate več
   *[other] Pogovorov ne spremljate več: { $count }
}
# review: new
done-ignored = { $count ->
    [one] Pogovor je prezrt
   *[other] Prezrti pogovori: { $count }
}
# review: new
done-unignored = { $count ->
    [one] Pogovor ni več prezrt
   *[other] Pogovori niso več prezrti: { $count }
}
# review: new
their-folders = njihove mape
# review: new
undo-move = Razveljavi premik
# review: new
undo-delete = Razveljavi brisanje
# review: new
undo-archive = Razveljavi arhiviranje
# review: new
undo-junk = Razveljavi označitev kot neželeno
# review: new
undo-not-junk = Razveljavi označitev kot želeno
# review: new
undo-send = Razveljavi pošiljanje
# review: new
nothing-to-undo = Ničesar ni mogoče razveljaviti.
# review: new
messages-gone = Sporočil ni več.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Ta mapa ne more vsebovati sporočil.
# review: new
not-archived-here = Sporočil v tej mapi ni mogoče arhivirati.
# review: new
not-emptied-here = Izprazniti je mogoče samo mapi Izbrisano in Neželena e-pošta.
# review: new
next-unread-question = V mapi { $folder } ni več neprebranih sporočil.

    Želite odpreti { $next }, naslednjo mapo z neprebranimi sporočili?
# review: new
no-unread-left = Ni več neprebranih sporočil.
# review: new
empty-question = { $count ->
    [one] Želite izprazniti mapo { $folder }?

        Sporočilo v njej bo trajno izbrisano. Ni ga mogoče obnoviti.
   *[other] Želite izprazniti mapo { $folder }?

        Vsebina ({ $messages }) bo trajno izbrisana. Ni je mogoče obnoviti.
}
# review: new
no-junk-folder = Ta račun nima mape Neželena e-pošta, v katero bi lahko premaknili sporočila.
# review: new
no-inbox-folder = Ta račun nima mape Prejeto, v katero bi lahko premaknili sporočila.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
# review: new
done-flagged-color = { $color ->
    [red] Označeno z rdečo zastavico: { $messages }
    [orange] Označeno z oranžno zastavico: { $messages }
    [yellow] Označeno z rumeno zastavico: { $messages }
    [green] Označeno z zeleno zastavico: { $messages }
    [blue] Označeno z modro zastavico: { $messages }
    [purple] Označeno z vijolično zastavico: { $messages }
   *[gray] Označeno s sivo zastavico: { $messages }
}
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Rdeča
    [orange] Oranžna
    [yellow] Rumena
    [green] Zelena
    [blue] Modra
    [purple] Vijolična
   *[gray] Siva
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [one] Premakni sporočilo
    [two] Premakni { $count } sporočili
    [few] Premakni { $count } sporočila
   *[other] Premakni { $count } sporočil
}
# review: new
move-window-title-copy = { $count ->
    [one] Kopiraj sporočilo
    [two] Kopiraj { $count } sporočili
    [few] Kopiraj { $count } sporočila
   *[other] Kopiraj { $count } sporočil
}
# review: new
move-window-prompt-move = { $count ->
    [one] Izbrano sporočilo premakni v:
    [two] Izbrani sporočili ({ $count }) premakni v:
    [few] Izbrana sporočila ({ $count }) premakni v:
   *[other] Izbranih sporočil ({ $count }) premakni v:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Izbrano sporočilo kopiraj v:
    [two] Izbrani sporočili ({ $count }) kopiraj v:
    [few] Izbrana sporočila ({ $count }) kopiraj v:
   *[other] Izbranih sporočil ({ $count }) kopiraj v:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Nedavno
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (trenutna)
# a folder used last, with its account when there are several: "Archive (Work)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Premikanje v { $folder }: { $done } od { $messages }...
# review: new
transfer-copying = Kopiranje v { $folder }: { $done } od { $messages }...
# review: new
transfer-another-account = drug račun
# review: new
transfer-folder-gone = mape, v katero je bilo namenjeno, ni več
# review: new
transfer-not-on-server = sporočila ni več na strežniku
# review: new
transfer-not-moved = { $count ->
   *[other] Premik v drug račun ni uspel ({ $messages }): { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] Kopiranje v drug račun ni uspelo ({ $messages }): { $reason }
}
# review: new
transfer-none-moved = Nobenega sporočila ni bilo mogoče premakniti
# review: new
transfer-none-copied = Nobenega sporočila ni bilo mogoče kopirati

## Messages as files

# review: new
export-not-in-time = sporočila ni bilo mogoče pravočasno prenesti
# review: new
export-not-saved = Ni bilo mogoče shraniti { $failed } od { $messages } ({ $problems })
# review: new
export-not-attached = sporočil ni bilo mogoče pripeti: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
   *[other] Shranjeno v { $folder }: { $messages }
}
# review: new
download-progress = Prenašanje { $done } od { $total }
# review: new
download-done = Preneseno { $size }
# review: new
downloading-messages = { $count ->
   *[other] Prenašanje: { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
# review: new
import-put = { $count ->
   *[other] Dodano v { $folder }: { $messages }
}
# review: new
import-not-put = Tega ni bilo mogoče dodati v mapo:

    { $problems }

## Problems the windows show

# review: new
error-store = lokalna shramba: { $error }
# review: new
error-not-found = ni najdeno
# review: new
error-closed = zapiranje
# review: new
error-other-account = brskalnik se je prijavil v { $email }, ne v ta račun
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = strežnik ni sprejel prijave ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = povezava s strežnikom ni uspela ({ $reason })
# review: new
error-in-use = ni je mogoče odstraniti, dokler se z njo prijavljajo računi: { $accounts }
# review: new
error-turned-off = ta aplikacija za prijavo je za nove račune izklopljena
# review: new
error-folder-name = ime mape mora imeti od 1 do 200 znakov in ne sme vsebovati kontrolnih znakov
# review: new
error-folder-separator = ime mape na tem strežniku ne sme vsebovati znaka »{ $separator }«
# review: new
error-folder-special = mape Prejeto in posebnih map ni mogoče preimenovati ali izbrisati
# review: new
error-no-recipients = sporočilo nima prejemnikov
# review: new
error-bad-address = »{ $address }« ni e-poštni naslov
# review: new
error-not-own-address = { $address } ni med naslovi pošiljatelja tega računa. Dodajte ga v polje »Drugi naslovi, s katerih pošiljate« v lastnostih računa.
# review: new
rule-query-refused = Pravila ne morejo filtrirati po mapi ali datumu ({ $words }).
# review: new
rule-no-query = Vnesite iskalne pogoje za dohodna sporočila.
# review: new
rule-no-action = Izberite vsaj eno dejanje za pravilo.
# review: new
error-attachment = Datoteke { $path } ni bilo mogoče prebrati: { $error }
# review: new
error-no-drafts = račun nima mape Osnutki, v katero bi lahko shranili sporočilo
# review: new
error-draft-attachment = priponke osnutka ni bilo mogoče ohraniti: { $error }
# review: new
error-password-not-saved = gesla ni bilo mogoče shraniti za naslednji zagon: { $error }
# review: new
error-sign-in-not-saved = novih podatkov za prijavo ni bilo mogoče shraniti za naslednji zagon: { $error }
# review: new
error-import-unreadable = Datoteke { $path } ni mogoče prebrati: { $error }
# review: new
error-import-too-large = Datoteka { $path } je večja od 50 MB
# review: new
error-import-not-mail = Datoteka { $path } ni e-poštno sporočilo
# review: new
error-list-answered = strežnik poštnega seznama je vrnil stanje { $status }
# review: new
error-not-built = sporočila ni bilo mogoče sestaviti
# review: new
error-outbox-waits = { $count ->
    [one] sporočilo čaka v mapi Odpošiljanje in bo poslano ob naslednjem pošiljanju/prejemanju
   *[other] sporočila ({ $count }) čakajo v mapi Odpošiljanje in bodo poslana ob naslednjem pošiljanju/prejemanju
}
# review: new
error-draft-not-removed = prejšnjega osnutka sporočila ni bilo mogoče odstraniti iz mape Osnutki: { $reason }
# review: new
error-sent-but = sporočilo je bilo poslano, vendar { $problem }
# review: new
error-sent-still-in-outbox = je še vedno v mapi Odpošiljanje: { $error }
# review: new
error-sent-no-copy = kopije ni bilo mogoče shraniti v mapo Poslano: { $reason }
# review: new
error-no-password = za ta račun ni gesla
# review: new
error-no-sign-in = za ta račun ni prijave
# review: new
error-provider-missing = ta različica se ne more prijaviti pri ponudniku { $provider }: je bila njegova aplikacija za prijavo odstranjena?
# review: new
error-provider-servers = strežniki tega računa se ne ujemajo s strežniki njegove aplikacije za prijavo
# review: new
error-app-scopes = { $reason }. Poštni strežnik ni sprejel žetona aplikacije za prijavo: preverite, ali dovoljenja (scopes) aplikacije omogočajo dostop do pošte
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google programa Inbox Classic še ni preveril, zato se z njim lahko prijavijo samo preizkusni uporabniki. Uporabite svojo aplikacijo za prijavo pri Googlu ali geslo za aplikacije, ali pa jo vklopite v Aplikacijah za prijavo (Datoteka > Računi), če ste preizkusni uporabnik.
# review: new
sign-in-off-other = Izklopljena je bila v Aplikacijah za prijavo (Datoteka > Računi), kjer jo lahko znova vklopite.
# review: new
sign-in-app-no-name = aplikacija za prijavo potrebuje ime
# review: new
sign-in-app-no-client = manjka ID odjemalca
# review: new
sign-in-app-no-scopes = aplikacija za prijavo potrebuje dovoljenja (scopes), ki omogočajo dostop do pošte
# review: new
sign-in-app-bad-host = naslov strežnika { $server } manjka ali ni veljavno ime gostitelja
# review: new
sign-in-app-plain = strežnik { $server } mora uporabljati SSL/TLS ali STARTTLS
# review: new
sign-in-app-not-checked = izdajatelj še ni bil preverjen
# review: new
sign-in-app-issuer-changed = izdajatelj se je spremenil: znova vnesite skrivnost odjemalca ali jo odstranite
# review: new
sign-in-register-google = V konzoli Google Cloud Console ustvarite odjemalca OAuth vrste Desktop app z dovoljenjem https://mail.google.com/ na zaslonu za soglasje. Dokler je aplikacija v preizkušanju, se lahko prijavijo samo njeni preizkusni uporabniki.
# review: new
sign-in-register-microsoft = V storitvi Microsoft Entra registrirajte aplikacijo s platformo Mobile and desktop applications, preusmeritvenim URI-jem http://localhost in dovoljenimi tokovi javnega odjemalca ter z delegiranimi dovoljenji IMAP.AccessAsUser.All, SMTP.Send in offline_access. Samo za svojo organizacijo kot izdajatelja uporabite https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Registrirajte izvornega (javnega) odjemalca s spodnjim preusmeritvenim URI-jem; ponudnik mora na njem dovoliti katera koli vrata (RFC 8252). Dodajte dovoljenje (scope), s katerim ponudnik omogoča dostop do pošte.

## Calendar invitations

# review: new
repeats = Ponavljanje
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Vsak dan
        [two] Vsaka { $interval } dneva
        [few] Vsake { $interval } dni
       *[other] Vsakih { $interval } dni
    }
    [week] { $interval ->
        [one] Vsak teden
        [two] Vsaka { $interval } tedna
        [few] Vsake { $interval } tedne
       *[other] Vsakih { $interval } tednov
    }
    [month] { $interval ->
        [one] Vsak mesec
        [two] Vsaka { $interval } meseca
        [few] Vsake { $interval } mesece
       *[other] Vsakih { $interval } mesecev
    }
   *[year] { $interval ->
        [one] Vsako leto
        [two] Vsaki { $interval } leti
        [few] Vsaka { $interval } leta
       *[other] Vsakih { $interval } let
    }
}
# "Every week on Monday, Wednesday"
# review: new
repeats-on = { $repeats }, ob dnevih: { $days }
# "Every week, 10 times"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, enkrat
    [two] { $repeats }, { $count }-krat
    [few] { $repeats }, { $count }-krat
   *[other] { $repeats }, { $count }-krat
}
# review: new
day-monday = ponedeljek
# review: new
day-tuesday = torek
# review: new
day-wednesday = sreda
# review: new
day-thursday = četrtek
# review: new
day-friday = petek
# review: new
day-saturday = sobota
# review: new
day-sunday = nedelja

## AI agents

# review: new
agent-level-read = Branje pošte: mape, seznam sporočil, iskanje in sporočila
# review: new
agent-level-organize = Urejanje pošte: stanje branja, zastavice, neželena pošta, premikanje, arhiviranje, nove mape, brisanje v mapo Izbrisano in odjava s poštnih seznamov po vaši potrditvi
# review: new
agent-level-drafts = Pisanje osnutkov, ki jih pošljete sami
# review: new
agent-level-send = Pošiljanje pošte, vsakega sporočila šele po vaši potrditvi
# review: new
agent-connect-title = { $program } želi uporabljati vašo pošto
# review: new
agent-connect-detail = Agent UI je zaprosil za delo s programom Inbox Classic. Izberite, kaj sme početi in katere račune sme videti; to lahko pozneje spremenite v meniju Orodja > Agenti UI.

    Agenti berejo pošto, ki so jo napisali drugi ljudje, in sporočilo jih lahko poskuša preslepiti. Inbox Classic vas vedno vpraša, preden agent kar koli pošlje.
# review: new
agent-reply-to = Odgovor na »{ $subject }«
# review: new
agent-reply-all-on = Odgovor vsem na »{ $subject }«
# review: new
agent-forward-of = Posredovanje »{ $subject }«
# review: new
agent-never-written-one = Naslovu { $address } še niste nikoli pisali.
# review: new
agent-never-written-many = Nekaterim od teh naslovov ({ $count }) še niste nikoli pisali.
# review: new
agent-send-title = { $program } želi poslati to sporočilo
# review: new
agent-send-detail = Preverite prejemnike in vsebino sporočila. Ko potrdite, sporočilo { $seconds } s čaka v mapi Odpošiljanje, kjer ga lahko še izbrišete.
# review: new
agent-change-title = Kaj sme { $program }
# review: new
agent-change-allowed = Spremenite, kaj smejo agenti UI tega programa početi z vašo pošto.
# review: new
agent-change-refused = Temu programu ste zavrnili dostop. Dovolite ga, da bodo njegovi agenti znova imeli dostop do vaše pošte.
# review: new
agent-log-taken-back = { $entry } (preklicano)
# review: new
agent-files = Datoteke: { $files }
# review: new
agent-undo-refused = Tega ni mogoče preklicati.
# review: new
agent-undo-refused-why = Tega ni mogoče preklicati: { $reason }.
# review: new
agent-undo-impossible = tega ni mogoče preklicati
# review: new
agent-undo-not-in-folder = sporočila ni več v tej mapi
# review: new
agent-undo-not-arrived = sporočila (še) ni v mapi, v katero je bilo premaknjeno
# review: new
agent-undo-sent = sporočilo je že bilo poslano
# review: new
agent-original-not-downloaded = izvirno sporočilo še ni bilo preneseno. Najprej ga odprite
# review: new
agent-turned-away = Zavrnjen
# review: new
agent-can-nothing = Nič
# review: new
agent-can-read = branje
# review: new
agent-can-organize = urejanje
# review: new
agent-can-drafts = pisanje osnutkov
# review: new
agent-can-send = pošiljanje z vašo potrditvijo
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first } in { $last }
# review: new
agent-accounts = { $count ->
    [0] noben račun
    [one] { $count } račun
    [two] { $count } računa
    [few] { $count } računi
   *[other] { $count } računov
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Tega sporočila ni mogoče prebrati.
# review: new
agent-encrypted-original = To sporočilo je šifrirano: agent nanj ne more odgovoriti ali ga posredovati, ker ne zna šifrirati.
# review: new
agent-encrypted = To sporočilo je šifrirano. Prebere ga lahko samo uporabnik, v programu Inbox Classic.
# review: new
list-encrypted = Šifrirano sporočilo
# review: new
agent-log-composed = Odprl »{ $subject }« v novem sporočilu, da ga dokončate
# review: new
agent-log-refused = Niste poslali »{ $subject }«
# review: new
agent-log-sent = Poslal »{ $subject }« za { $to }
# review: new
agent-log-draft = Shranil osnutek »{ $subject }«
# review: new
agent-log-draft-replaced = Zamenjal osnutek »{ $subject }«
# review: new
agent-log-draft-discarded = Zavrgel osnutek »{ $subject }«
# review: new
agent-draft-note = { $program }, agent UI, je napisal ta osnutek. Pred pošiljanjem preverite prejemnike in besedilo.
# review: new
agent-log-read = Označil kot prebrano »{ $subject }«
# review: new
agent-log-unread = Označil kot neprebrano »{ $subject }«
# review: new
agent-log-flagged = Označil z zastavico »{ $subject }«
# review: new
agent-log-unflagged = Odstranil zastavico z »{ $subject }«
# review: new
agent-log-deleted = Izbrisal »{ $subject }«
# review: new
agent-log-moved = Premaknil »{ $subject }« v { $folder }
# review: new
agent-log-junk = Označil »{ $subject }« kot neželeno
# review: new
agent-log-not-junk = Označil »{ $subject }« kot želeno
# review: new
agent-log-archived = Arhiviral »{ $subject }«
# review: new
agent-log-folder = Ustvaril mapo »{ $name }«
# review: new
agent-log-unsubscribed = Odjavil od seznama sporočila »{ $subject }«
# review: new
agent-log-unsubscribe-failed = Odjava s seznama sporočila »{ $subject }« ni uspela: { $reason }
# review: new
agent-log-unsubscribe-refused = Odjavo s seznamov ste zavrnili: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [1] { $program } vas želi odjaviti s poštnega seznama
    [one] { $program } vas želi odjaviti s poštnih seznamov ({ $count })
    [two] { $program } vas želi odjaviti s poštnih seznamov ({ $count })
    [few] { $program } vas želi odjaviti s poštnih seznamov ({ $count })
   *[other] { $program } vas želi odjaviti s poštnih seznamov ({ $count })
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic spodnji seznam prosi, naj vam preneha pošiljati, in sicer z odjavo z enim klikom, ki jo ponuja. Nič drugega se ne pošlje in sporočila, ki jih imate, ostanejo, kjer so.
   *[other] Inbox Classic vsak spodnji seznam prosi, naj vam preneha pošiljati, in sicer z odjavo z enim klikom, ki jo seznam ponuja. Nič drugega se ne pošlje in sporočila, ki jih imate, ostanejo, kjer so.
}

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
sign-in-no-refresh = ponudnik ni dal žetona za osvežitev
# review: new
sign-in-no-account = ponudnik ni povedal, kateri račun se je prijavil
# review: new
sign-in-not-finished = prijava še ni končana
# review: new
secrets-unavailable = { $store } ni na voljo
# review: new
secrets-unavailable-why = { $store } ni na voljo: { $error }
# review: new
secrets-windows = Upravitelj poverilnic
# review: new
secrets-mac = Obesek za ključe
# review: new
secrets-linux = Sistemska shramba ključev (Secret Service)
# review: new
error-no-such-file = take datoteke ni
# review: new
cards-file-too-big = Ta datoteka je prevelika, da bi bila imenik.
# review: new
ui-sender-added = { $name } je bil dodan v Imenik.
# review: new
ui-sender-known = { $name } je že v Imeniku.
# review: new
ui-sender-none = Pošiljatelj tega sporočila nima e-poštnega naslova, ki bi ga lahko dodali.
# review: new
card-name-needed = Stik nima imena in nima e-poštnega naslova.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Koda za { $domain }
# review: new
otp-copy = Kopiraj
# review: new
otp-note = Vnesite jo samo na strani domene { $domain }.
# review: new
otp-old = Ta koda je bila poslana več kot eno uro, preden ste jo odprli, in je verjetno že potekla.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } udeleženec
        [two] { $count } udeleženca
        [few] { $count } udeleženci
       *[other] { $count } udeležencev
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } je vaša koda za { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Veljaven
# review: new
pgp-key-expires = Veljaven do { $date }
# review: new
pgp-key-expired = Potekel { $date }
# review: new
pgp-key-revoked = Preklican
# review: new
pgp-key-revoked-why = Preklican: { $reason }
# review: new
pgp-key-not-valid = Ni veljaven
# review: new
pgp-key-locked = Ni ga mogoče uporabiti: ključa, ki ga ščiti, ni več na voljo ({ $store }). Znova uvozite njegovo varnostno kopijo.
# review: new
pgp-source-own = Ustvarjen v programu Inbox Classic
# review: new
pgp-source-file = Uvožen iz datoteke
# review: new
pgp-source-paste = Prilepljen
# review: new
pgp-source-attachment = Iz sporočila
# review: new
pgp-source-vcard = Iz vizitke stika
# review: new
pgp-source-wkd = Od ponudnika e-pošte pošiljatelja
# review: new
pgp-source-keyserver = S strežnika keys.openpgp.org
# review: new
pgp-source-autocrypt = Iz glave Autocrypt sporočila
# review: new
pgp-error-no-store = Zasebne ključe ščiti { $store }, ki ga ni mogoče uporabiti: { $error }
# review: new
pgp-error-wrong-passphrase = Zaščitno geslo ni pravilno.
# review: new
pgp-error-not-a-key = To ni ključ OpenPGP.
# review: new
pgp-error-too-large = Ključ je prevelik.
# review: new
pgp-error-unusable = Ključ uporablja staro ali šibko kriptografijo in ga ni mogoče uporabiti.
# review: new
pgp-imported-private = { $count ->
    [one] Vaš zasebni ključ je bil uvožen.
    [two] Uvožena sta bila { $count } zasebna ključa.
    [few] Uvoženi so bili { $count } zasebni ključi.
   *[other] Uvoženih je bilo { $count } zasebnih ključev.
}
# review: new
pgp-imported-public = { $count ->
    [one] Uvožen je bil { $count } ključ.
    [two] Uvožena sta bila { $count } ključa.
    [few] Uvoženi so bili { $count } ključi.
   *[other] Uvoženih je bilo { $count } ključev.
}
# review: new
pgp-imported-pending = Za { $addresses } se že uporablja drug ključ: novi čaka v stiku, dokler ga ne izberete.
# review: new
pgp-error-needs-passphrase = Zasebni ključ je zaščiten z zaščitnim geslom. Vnesite ga, da uvozite ključ.
# review: new
pgp-error-mismatch = Zasebni ključ ne pripada svojemu javnemu ključu. Morda je bil spremenjen.
# review: new
pgp-file-name-public = { $who } javni ključ.asc
# review: new
pgp-file-name-private = { $who } varnostna kopija zasebnega ključa.asc
# review: new
pgp-pending = { $date } je bil najden drug ključ za { $address }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Podpisal { $signer }, ključ preverjen
# review: new
pgp-part-signed = Podpisal { $signer } (ključ ni preverjen)
# review: new
pgp-part-other = Podpisal { $signer }, ki ni pošiljatelj
# review: new
pgp-part-unknown-key = Podpisano, vendar ključ ni znan
# review: new
pgp-part-not-signed = Ni podpisano
# review: new
pgp-part-not-checked = Podpis ni preverjen
# review: new
pgp-part-encrypted = Šifrirano. { $signature }
# review: new
pgp-part-no-key = Šifrirano za ključ, ki ga nimate
# review: new
pgp-part-changed = Šifrirani del je bil med potjo spremenjen in ni prikazan
# review: new
pgp-part-unprotected = Šifrirano brez zaščite pred spremembami, ni prikazano
# review: new
pgp-part-broken = Šifriranega dela ni mogoče prebrati
# review: new
pgp-why-mismatch = Podpis se ne ujema s tem besedilom
# review: new
pgp-why-weak-hash = Podpis uporablja { $hash }, ki ni več varen
# review: new
pgp-why-key-expired = Podpisano po tem, ko je ključ potekel { $date }
# review: new
pgp-why-key-revoked = Podpisano s preklicanim ključem
# review: new
pgp-why-not-signing-key = Podpisano s ključem, ki ne sme podpisovati
# review: new
pgp-why-from-future = Podpis ima datum v prihodnosti
# review: new
pgp-why-signature-expired = Podpis je potekel
# review: new
pgp-why-key-not-valid = Podpisano z neveljavnim ključem
# review: new
pgp-why-not-for-you = Podpisano za druge prejemnike in posredovano vam
pgp-why-not-key-in-use = Ključ podpisa se razlikuje od ključa, izbranega za naslov { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Slike so bile naložene z interneta
# review: new
pgp-error-no-own-key = Za { $address } nimate ključa, s katerim bi podpisovali ali šifrirali. Ustvarite ga v meniju Orodja > Šifrirni ključi ali izklopite Podpiši in Šifriraj.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } nima ključa za šifriranje.
   *[other] Ti prejemniki nimajo ključa za šifriranje: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = To sporočilo navaja ali posreduje šifrirano sporočilo, zato ga je mogoče poslati samo šifrirano. Vklopite Šifriraj ali odstranite navedeno besedilo.
# review: new
pgp-error-protect = Sporočila ni bilo mogoče podpisati ali šifrirati: { $reason }
# review: new
pgp-found-keys = Najden ključ za { $addresses }.
# review: new
pgp-found-none = Za { $addresses } ni bil najden noben ključ. Prosite, naj vam pošljejo svoj javni ključ.
# review: new
pgp-found-no-key = Noben ključ ni bil najden.
# review: new
pgp-find-unavailable = Ključev zdaj ni bilo mogoče poiskati: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org je poslal potrditveno povezavo na { $addresses }. Ko jo kliknete, bo vaš ključ tam objavljen.
# review: new
pgp-publish-done = Vaš ključ je objavljen na keys.openpgp.org za { $addresses }.
# review: new
pgp-publish-failed = Ključa ni bilo mogoče objaviti: { $error }
# review: changed
pgp-keyserver-off = Iskanje ključev na keys.openpgp.org je izklopljeno v { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [1] Šifrirano in podpisano: prebrati ga lahko samo vi in { $addresses }.
   *[other] Šifrirano in podpisano: prebrati ga lahko samo vi in njegovi prejemniki ({ $count }).
}
# review: new
pgp-compose-encrypt-ready = Sporočilo bo šifrirano in podpisano. Dodajte prejemnike, katerih ključe imate.
# review: new
pgp-compose-missing = { $count ->
    [1] { $addresses } nima ključa, zato sporočila še ni mogoče šifrirati.
   *[other] Prejemniki brez ključa ({ $count }): { $addresses }. Zato sporočila še ni mogoče šifrirati.
}
# review: new
pgp-compose-looking = Iskanje ključev za { $addresses }...
# review: new
pgp-compose-signed = Podpisano: prejemniki lahko preverijo, da je od vas in da ni bilo spremenjeno.
# review: new
pgp-compose-reply-clear = Ni šifrirano, čeprav je bilo sporočilo, na katero odgovarja ali ki ga posreduje, šifrirano.
# review: new
pgp-compose-encrypted-files = Pripete so datoteke šifriranega sporočila, zato je to sporočilo mogoče poslati samo šifrirano. Vklopite Šifriraj ali odstranite te datoteke.
# review: new
pgp-compose-sign-tip = Podpišite sporočilo s svojim ključem, da lahko prejemniki preverijo, da je od vas in da ni bilo spremenjeno
# review: new
pgp-compose-sign-tip-encrypted = Šifrirano sporočilo je vedno podpisano
# review: new
pgp-compose-encrypt-tip = Šifrirajte sporočilo, da ga lahko preberete samo vi in njegovi prejemniki
# review: new
pgp-compose-make-key = Za { $address } še nimate ključa. Ga želite ustvariti zdaj? Z njim lahko svoja sporočila podpisujete in šifrirate.
# review: new
pgp-compose-key-unusable = Vašega ključa za { $address } ni mogoče uporabiti ({ $state }). Odprite okno Šifrirni ključi, da uvozite njegovo varnostno kopijo ali ustvarite nov ključ.
# review: new
pgp-compose-encrypt-off-quote = To sporočilo navaja ali posreduje šifrirano sporočilo. Brez šifriranja ga ni mogoče poslati, dokler ne odstranite navedenega. Ali želite kljub temu izklopiti šifriranje?
# review: new
pgp-compose-encrypt-off-reply = To sporočilo odgovarja na šifrirano sporočilo ali ga posreduje. Brez šifriranja lahko vaše sporočilo prebere vsak, ki ga obravnava na poti. Ali želite izklopiti šifriranje?
# review: new
pgp-recipient-verified = Ključ preverjen
# review: new
pgp-recipient-found = Ključ ni preverjen
# review: new
pgp-recipient-own = Vaš ključ
# review: new
pgp-recipient-looking = Iskanje ključa...
# review: new
pgp-recipient-missing = Ni ključa
# review: new
pgp-recipient-not-found = Ni ključa: { $date } ni bil najden noben
# review: new
pgp-recipient-unusable = Ključa ni mogoče uporabiti: { $state }
# review: new
pgp-recipients-intro = Sporočilo je šifrirano s ključem vsakega prejemnika in z vašim.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] { $count } prejemnik nima ključa za šifriranje. Poiščite njegov ključ, ga odstranite iz tega sporočila ali sporočilo pošljite brez šifriranja.
    [two] { $count } prejemnika nimata ključa za šifriranje. Poiščite njuna ključa, ju odstranite iz tega sporočila ali sporočilo pošljite brez šifriranja.
    [few] { $count } prejemniki nimajo ključa za šifriranje. Poiščite njihove ključe, jih odstranite iz tega sporočila ali sporočilo pošljite brez šifriranja.
   *[other] { $count } prejemnikov nima ključa za šifriranje. Poiščite njihove ključe, jih odstranite iz tega sporočila ali sporočilo pošljite brez šifriranja.
}
# review: new
pgp-details-part = Del { $number }: { $label }
# review: new
pgp-details-signed = Podpisano { $when } s ključem { $key }
# review: new
pgp-details-unknown-key = Podpisano s ključem { $key }, ki ga nimate
# review: new
pgp-details-opened = Šifrirano za vaš ključ { $key }
# review: new
pgp-details-for = Šifrirano za { $keys }
# review: new
pgp-details-plain = Ni podpisano in ni šifrirano
# review: new
pgp-bar-parts = To sporočilo ima več delov ({ $count }): { $list }. Pri vsakem delu piše, kako je zaščiten.
# review: new
pgp-bar-count-verified = Preverjeni: { $count }
# review: new
pgp-bar-count-good = { $count ->
   *[other] Podpisani ali šifrirani: { $count }
}
# review: new
pgp-bar-count-warning = { $count ->
   *[other] Zahtevajo pozornost: { $count }
}
# review: new
pgp-bar-count-neutral = Brez potrjenega podpisa: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Nastavitve
# review: new
setup-part-preferences = Nastavitve oken
# review: new
setup-part-accounts = Računi
# review: new
setup-part-sign-in-apps = Aplikacije za prijavo
# review: new
setup-part-contacts = Stiki in skupine
# review: new
setup-part-keys = Šifrirni ključi
# review: new
setup-part-rules = Pravila za sporočila
# review: new
setup-part-trusted-senders = Zaupanja vredni pošiljatelji
# review: new
setup-holds-settings = { $count ->
    [one] { $count } nastavitev
    [two] { $count } nastavitvi
    [few] { $count } nastavitve
   *[other] { $count } nastavitev
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } nastavitev okna
    [two] { $count } nastavitvi oken
    [few] { $count } nastavitve oken
   *[other] { $count } nastavitev oken
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } račun
    [two] { $count } računa
    [few] { $count } računi
   *[other] { $count } računov
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavo
    [two] { $count } aplikaciji za prijavo
    [few] { $count } aplikacije za prijavo
   *[other] { $count } aplikacij za prijavo
}
# review: new
setup-holds-built-in = Katere vgrajene aplikacije za prijavo so vklopljene
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } stik
    [two] { $count } stika
    [few] { $count } stiki
   *[other] { $count } stikov
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } skupina
    [two] { $count } skupini
    [few] { $count } skupine
   *[other] { $count } skupin
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } lastni ključ
    [two] { $count } lastna ključa
    [few] { $count } lastni ključi
   *[other] { $count } lastnih ključev
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } ključ stika
    [two] { $count } ključa stikov
    [few] { $count } ključi stikov
   *[other] { $count } ključev stikov
}
# review: new
setup-holds-rules = { $count ->
    [one] { $count } pravilo
    [two] { $count } pravili
    [few] { $count } pravila
   *[other] { $count } pravil
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] { $count } zaupanja vreden pošiljatelj
    [two] { $count } zaupanja vredna pošiljatelja
    [few] { $count } zaupanja vredni pošiljatelji
   *[other] { $count } zaupanja vrednih pošiljateljev
}
# review: new
setup-sign-in-password = Geslo
# review: new
setup-account-secret-password = Njegovo geslo je v datoteki.
# review: new
setup-account-secret-token = Njegova prijava je v datoteki.
# review: new
setup-account-asks-password = Po uvozu bo zahteval geslo.
# review: new
setup-account-signs-in-again = Po uvozu se boste vanj znova prijavili.
# review: new
setup-account-here = Tukaj je že nastavljen, zato je preskočen.
# review: new
setup-account-no-app = Prijavlja se z aplikacijo { $app }, ki tukaj ni nastavljena. Uvozite tudi aplikacije za prijavo.
# review: new
setup-invalid-address = »{ $address }« ni e-poštni naslov.
# review: new
setup-invalid-server = Strežnik { $server } nima uporabnega imena ali vrat.
# review: new
setup-invalid-user = Nima uporabniškega imena.
# review: new
setup-invalid-sign-in = Prijavlja se na način, ki ga Inbox Classic ne pozna.
# review: new
setup-error-empty = Datoteka je prazna.
# review: new
setup-error-too-large = Datoteka je prevelika, da bi bila nastavitev programa Inbox Classic.
# review: new
setup-error-not-setup = Ta datoteka ni nastavitev programa Inbox Classic.
# review: new
setup-error-damaged = Datoteka z nastavitvami je poškodovana in je ni mogoče prebrati.
# review: new
setup-error-newer = To nastavitev je shranila novejša različica programa Inbox Classic ({ $version }). Posodobite Inbox Classic in jo znova uvozite.
# review: new
setup-error-needs-passphrase = Ta nastavitev je zaščitena z zaščitnim geslom. Vnesite zaščitno geslo, s katerim je bila shranjena.
# review: new
setup-error-wrong-passphrase = To ni zaščitno geslo, s katerim je bila ta nastavitev shranjena.
# review: new
setup-error-changed = Datoteka z nastavitvami je bila po shranjevanju spremenjena ali poškodovana, zato je ni mogoče uvoziti.
# review: new
setup-error-read = Datoteke z nastavitvami ni bilo mogoče prebrati: { $error }
# review: new
setup-error-write = Nastavitve ni bilo mogoče shraniti: { $error }
# review: new
setup-error-no-parts = Izberite vsaj en del.
# review: new
setup-left-out = { $count ->
    [one] { $count } vnos iz dela { $part } ni uporaben, zato je izpuščen.
    [two] { $count } vnosa iz dela { $part } nista uporabna, zato sta izpuščena.
    [few] { $count } vnosi iz dela { $part } niso uporabni, zato so izpuščeni.
   *[other] { $count } vnosov iz dela { $part } ni uporabnih, zato so izpuščeni.
}
# review: new
setup-imported-settings = Nastavitve so bile zamenjane.
# review: new
setup-imported-preferences = Nastavitve oken so bile zamenjane.
# review: new
setup-added-accounts = { $count ->
    [one] Dodan je { $count } račun.
    [two] Dodana sta { $count } računa.
    [few] Dodani so { $count } računi.
   *[other] Dodanih je { $count } računov.
}
# review: new
setup-skipped-here = { $address } je tukaj že nastavljen, zato je bil preskočen.
# review: new
setup-skipped-no-app = { $address } je bil preskočen: prijavlja se z aplikacijo { $app }, ki tukaj ni nastavljena.
# review: new
setup-skipped-invalid = { $address } je bil preskočen: { $reason }
# review: new
setup-asks-password = { $address } bo ob povezovanju zahteval geslo.
# review: new
setup-signs-in-again = { $address } vas bo ob povezovanju prosil, da se znova prijavite.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Dodana je { $count } aplikacija za prijavo.
    [two] Dodani sta { $count } aplikaciji za prijavo.
    [few] Dodane so { $count } aplikacije za prijavo.
   *[other] Dodanih je { $count } aplikacij za prijavo.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavo je tukaj že nastavljena.
    [two] { $count } aplikaciji za prijavo sta tukaj že nastavljeni.
    [few] { $count } aplikacije za prijavo so tukaj že nastavljene.
   *[other] { $count } aplikacij za prijavo je tukaj že nastavljenih.
}
# review: new
setup-added-contacts = { $count ->
    [one] V imenik je dodan { $count } stik.
    [two] V imenik sta dodana { $count } stika.
    [few] V imenik so dodani { $count } stiki.
   *[other] V imenik je dodanih { $count } stikov.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } stik je že v imeniku.
    [two] { $count } stika sta že v imeniku.
    [few] { $count } stiki so že v imeniku.
   *[other] { $count } stikov je že v imeniku.
}
# review: new
setup-added-groups = { $count ->
    [one] Dodana ali dopolnjena je { $count } skupina.
    [two] Dodani ali dopolnjeni sta { $count } skupini.
    [few] Dodane ali dopolnjene so { $count } skupine.
   *[other] Dodanih ali dopolnjenih je { $count } skupin.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Dodan je { $count } lastni ključ.
    [two] Dodana sta { $count } lastna ključa.
    [few] Dodani so { $count } lastni ključi.
   *[other] Dodanih je { $count } lastnih ključev.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Dodan je { $count } ključ stika.
    [two] Dodana sta { $count } ključa stikov.
    [few] Dodani so { $count } ključi stikov.
   *[other] Dodanih je { $count } ključev stikov.
}
# review: new
setup-added-rules = { $count ->
    [one] Dodano je { $count } pravilo za sporočila.
    [two] Dodani sta { $count } pravili za sporočila.
    [few] Dodana so { $count } pravila za sporočila.
   *[other] Dodanih je { $count } pravil za sporočila.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } pravilo za sporočila je tukaj že.
    [two] { $count } pravili za sporočila sta tukaj že.
    [few] { $count } pravila za sporočila so tukaj že.
   *[other] { $count } pravil za sporočila je tukaj že.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } pravilo za sporočila velja za račun, ki ga tukaj ni, zato je bilo preskočeno.
    [two] { $count } pravili za sporočila veljata za račune, ki jih tukaj ni, zato sta bili preskočeni.
    [few] { $count } pravila za sporočila veljajo za račune, ki jih tukaj ni, zato so bila preskočena.
   *[other] { $count } pravil za sporočila velja za račune, ki jih tukaj ni, zato so bila preskočena.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } pravilo za sporočila premika sporočila v mapo, ki se bo pojavila, ko se njen račun sinhronizira.
    [two] { $count } pravili za sporočila premikata sporočila v mape, ki se bodo pojavile, ko se njihovi računi sinhronizirajo.
    [few] { $count } pravila za sporočila premikajo sporočila v mape, ki se bodo pojavile, ko se njihovi računi sinhronizirajo.
   *[other] { $count } pravil za sporočila premika sporočila v mape, ki se bodo pojavile, ko se njihovi računi sinhronizirajo.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Dodan je { $count } zaupanja vreden pošiljatelj.
    [two] Dodana sta { $count } zaupanja vredna pošiljatelja.
    [few] Dodani so { $count } zaupanja vredni pošiljatelji.
   *[other] Dodanih je { $count } zaupanja vrednih pošiljateljev.
}
# review: new
setup-nothing = Nič ni bilo uvoženo.
# review: new
setup-account-servers = { $imap } in { $smtp } ({ $signin })
# review: new
setup-file-name = Nastavitve in računi Inbox Classic
# review: new
setup-skipped-unreachable = { $name } je bil preskočen: njegove storitve za prijavo ni bilo mogoče doseči. Znova ga dodajte v Aplikacijah za prijavo.
# review: new
attachment-runs-programs = Datoteka »{ $name }« lahko zažene programe, zato je Inbox Classic ne odpre. Shranite jo in jo nato odprite sami, če zaupate njenemu izvoru.
# review: new
attachment-decrypted-note = Ta priponka je iz šifriranega sporočila. Da jo lahko odpre, jo Inbox Classic shrani dešifrirano v ta računalnik, v vašo mapo, ki jo Inbox Classic po enem dnevu izprazni.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [1] Strežnik sporočila ni premaknil v mapo { $folder }, zato je { $messages } spet v mapi { $from }: { $reason }
    [one] Strežnik sporočil ni premaknil v mapo { $folder }, zato je { $messages } spet v mapi { $from }: { $reason }
    [two] Strežnik sporočil ni premaknil v mapo { $folder }, zato sta { $messages } spet v mapi { $from }: { $reason }
    [few] Strežnik sporočil ni premaknil v mapo { $folder }, zato so { $messages } spet v mapi { $from }: { $reason }
   *[other] Strežnik sporočil ni premaknil v mapo { $folder }, zato je { $messages } spet v mapi { $from }: { $reason }
}
undone-delete = { $count ->
    [1] Strežnik sporočila ni izbrisal, zato je { $messages } spet v mapi { $from }: { $reason }
    [one] Strežnik sporočil ni izbrisal, zato je { $messages } spet v mapi { $from }: { $reason }
    [two] Strežnik sporočil ni izbrisal, zato sta { $messages } spet v mapi { $from }: { $reason }
    [few] Strežnik sporočil ni izbrisal, zato so { $messages } spet v mapi { $from }: { $reason }
   *[other] Strežnik sporočil ni izbrisal, zato je { $messages } spet v mapi { $from }: { $reason }
}
undone-archive = { $count ->
    [1] Strežnik sporočila ni arhiviral, zato je { $messages } spet v mapi { $from }: { $reason }
    [one] Strežnik sporočil ni arhiviral, zato je { $messages } spet v mapi { $from }: { $reason }
    [two] Strežnik sporočil ni arhiviral, zato sta { $messages } spet v mapi { $from }: { $reason }
    [few] Strežnik sporočil ni arhiviral, zato so { $messages } spet v mapi { $from }: { $reason }
   *[other] Strežnik sporočil ni arhiviral, zato je { $messages } spet v mapi { $from }: { $reason }
}
undone-read = { $count ->
    [1] Strežnik sporočila ni označil kot prebranega, zato je { $messages } spet neprebrano: { $reason }
    [one] Strežnik sporočil ni označil kot prebranih, zato je { $messages } spet neprebrano: { $reason }
    [two] Strežnik sporočil ni označil kot prebranih, zato sta { $messages } spet neprebrani: { $reason }
    [few] Strežnik sporočil ni označil kot prebranih, zato so { $messages } spet neprebrana: { $reason }
   *[other] Strežnik sporočil ni označil kot prebranih, zato je { $messages } spet neprebranih: { $reason }
}
undone-unread = { $count ->
    [1] Strežnik sporočila ni označil kot neprebranega, zato je { $messages } spet prebrano: { $reason }
    [one] Strežnik sporočil ni označil kot neprebranih, zato je { $messages } spet prebrano: { $reason }
    [two] Strežnik sporočil ni označil kot neprebranih, zato sta { $messages } spet prebrani: { $reason }
    [few] Strežnik sporočil ni označil kot neprebranih, zato so { $messages } spet prebrana: { $reason }
   *[other] Strežnik sporočil ni označil kot neprebranih, zato je { $messages } spet prebranih: { $reason }
}
undone-flags = { $count ->
    [one] Strežnik ni spremenil zastavic ({ $messages }), zato je bila sprememba razveljavljena: { $reason }
    [two] Strežnik ni spremenil zastavic ({ $messages }), zato je bila sprememba razveljavljena: { $reason }
    [few] Strežnik ni spremenil zastavic ({ $messages }), zato je bila sprememba razveljavljena: { $reason }
   *[other] Strežnik ni spremenil zastavic ({ $messages }), zato je bila sprememba razveljavljena: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Prikaži datoteke PDF v sporočilih
# review: new
preview-pdf-off = Datoteke PDF se v sporočilih ne prikazujejo.
# review: new
preview-pdf-off-crashed = Datoteka PDF je med prikazovanjem zaprla Inbox Classic, zato se datoteke PDF v sporočilih ne prikazujejo več. Slike se še prikazujejo. Če želite znova prikazovati datoteke PDF, v možnostih branja vklopite { $option }.
# review: new
preview-pdf-details = { $count ->
    [one] { $count } stran, { $size }
    [two] { $count } strani, { $size }
    [few] { $count } strani, { $size }
   *[other] { $count } strani, { $size }
}
# review: new
preview-page-alt = { $name }, stran { $page } od { $count }
# review: new
preview-more-pages = { $count ->
    [one] Odprite datoteko za ogled vseh { $count } strani
    [two] Odprite datoteko za ogled obeh { $count } strani
    [few] Odprite datoteko za ogled vseh { $count } strani
   *[other] Odprite datoteko za ogled vseh { $count } strani
}
