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
decimal-separator = ,
# review: new
list-separator = { ", " }
size-bytes = { $count ->
    [one] { $count } bajt
    [two] { $count } bajta
    [few] { $count } bajti
   *[other] { $count } bajtov
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Izklopljeno
send-delay-seconds = { $count ->
    [one] { $count } sekunda
    [two] { $count } sekundi
    [few] { $count } sekunde
   *[other] { $count } sekund
}
# the status bar: "12 messages, 3 unread"
list-counts = { $messages }, neprebrana: { $unread }
list-counts-selected = { $messages }, neprebrana: { $unread }, izbrana: { $selected }
# the status bar while searching: "12 found, 3 unread"
list-counts-found = Najdena: { $found }, neprebrana: { $unread }
list-counts-found-selected = Najdena: { $found }, neprebrana: { $unread }, izbrana: { $selected }
list-counts-none = Ni najdenih sporočil

## Special folders, as Outlook names them

folder-inbox = Prejeto
folder-sent = Poslano
folder-deleted = Izbrisano
folder-drafts = Osnutki
folder-junk = Neželena e-pošta
folder-archive = Arhiv

## The reading pane

reader-no-message = Nobeno sporočilo ni izbrano.
reader-downloading = Prenašanje sporočila…
reader-downloading-detail = Sporočilo bo prikazano tukaj, ko bo prenos končan.
reader-downloading-size = Sporočilo je veliko { $size }. Prikazano bo tukaj, ko bo preneseno.
reader-failed = Sporočila ni bilo mogoče prenesti
reader-failed-network = Povezave s poštnim strežnikom ni bilo mogoče vzpostaviti ali pa je bila prekinjena ({ $reason }).
reader-failed-sign-in = Poštni strežnik ni sprejel prijave ({ $reason }). Preverite geslo ali se znova prijavite v nastavitvah računa.
reader-failed-security = Povezave s poštnim strežnikom ni bilo mogoče zavarovati ({ $reason }).
reader-failed-other = Poštni strežnik je odgovoril: { $reason }.
reader-retry-note = Poskus se bo ponovil, ko se račun znova poveže.
reader-unreadable = Tega sporočila ni mogoče prikazati: { $error }
message-source-title = Izvorna koda sporočila: { $subject }
message-source-untitled = Izvorna koda sporočila

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Od
header-date = Datum
header-to = Za
header-cc = Kp
header-sent = Poslano
header-subject = Zadeva
header-security = Varnost
header-part = Del { $number }
quote-original = ----- Izvirno sporočilo -----
fold-show-earlier = Pokaži starejša sporočila

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Vaše sporočilo ni bilo dostavljeno
bounce-delayed = Vaše sporočilo še ni bilo dostavljeno
bounce-delayed-note = Vaš poštni strežnik ga še vedno poskuša dostaviti. Ni ga treba poslati znova.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Pokaži vrnjeno sporočilo
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Pokaži zakasnjeno sporočilo
bounce-what-to-do = Kaj lahko storite:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Zaenkrat nič. Če ga še vedno ne bo mogoče dostaviti, boste prejeli novo obvestilo.
bounce-delayed-row-do = Zaenkrat nič. Vaš poštni strežnik ga še poskuša dostaviti, in če mu ne bo uspelo, boste prejeli novo obvestilo.
# folds the receiving server's own words
bounce-details = Podrobnosti
# a recipient the notice does not name
bounce-someone = Prejemnik
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Strežnik: { $server }
bounce-status = Stanje: { $status }
bounce-reported-by = Sporočil: { $server }
bounce-retry-minutes = Prejemni strežnik je prosil, naj se pred naslednjim poskusom počaka { $count ->
    [one] { $count } minuto
    [two] { $count } minuti
    [few] { $count } minute
   *[other] { $count } minut
}.
bounce-retry-hours = Prejemni strežnik je prosil, naj se pred naslednjim poskusom počaka { $count ->
    [one] { $count } uro
    [two] { $count } uri
    [few] { $count } ure
   *[other] { $count } ur
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Črni seznam: { $lists }
bounce-user-unknown = Naslov ne obstaja
bounce-user-unknown-why = Prejemni strežnik nima poštnega predala s tem naslovom. Morda je napačno vpisan ali pa ga oseba ne uporablja več.
bounce-user-unknown-do = Preverite črkovanje naslova ali vprašajte osebo, kateri naslov uporablja zdaj.
bounce-invalid-address = Naslov ni veljaven
bounce-invalid-address-why = Naslov ni zapisan v obliki, na katero je mogoče poslati pošto.
bounce-invalid-address-do = Poiščite tipkarske napake, na primer presledek, manjkajočo črko ali nič za znakom @.
bounce-mailbox-disabled = Poštni predal je zaprt
bounce-mailbox-disabled-why = Naslov obstaja, vendar je njegov poštni predal izklopljen ali se ne uporablja več.
bounce-mailbox-disabled-do = Osebo obvestite po drugi poti in jo prosite za naslov, ki ga uporablja zdaj.
bounce-mailbox-full = Poštni predal je poln
bounce-mailbox-full-why = V prejemnikovem poštnem predalu ni prostora za novo pošto.
bounce-mailbox-full-do = Čez nekaj dni poskusite sporočilo poslati znova ali prejemnika obvestite po drugi poti.
bounce-spam-blocked = Zavrnjeno kot vsiljena pošta
bounce-spam-blocked-why = Prejemni strežnik je sporočilo prepoznal kot vsiljeno pošto.
bounce-spam-blocked-do = Poskusite sporočilo poslati brez elementov, ki bi lahko bili videti kot vsiljena pošta, na primer številnih ali skrajšanih povezav oziroma velike priponke. Če se težava ponavlja, se obrnite na ponudnika e-pošte.
bounce-virus-detected = Zavrnjeno zaradi virusa
bounce-virus-detected-why = Prejemni strežnik je v sporočilu ali priponkah zaznal virus ali drugo škodljivo vsebino in jo navedel kot razlog zavrnitve.
bounce-virus-detected-do = Priponke preverite s protivirusnim programom. Nekateri strežniki zavrnejo vsak program ali arhiv, zato take datoteke raje delite s povezavo.
bounce-ip-blocklisted = Vaš poštni strežnik je na črnem seznamu
bounce-ip-blocklisted-why = Prejemni strežnik zavrača pošto s strežnika, ki je poslal vašo, ker je naslov tega strežnika na črnem seznamu.
bounce-ip-blocklisted-do = Težava ni v sporočilu. To obvestilo posredujte svojemu ponudniku e-pošte in ga prosite, naj strežnik odstrani s seznama.
bounce-domain-blocklisted = Domena je na črnem seznamu
bounce-domain-blocklisted-why = Prejemni strežnik zavrača sporočilo, ker je domena vašega naslova ali domena iz povezav v sporočilu na črnem seznamu.
bounce-domain-blocklisted-do = Če ima sporočilo povezave, ga poskusite poslati brez njih. Sicer to obvestilo posredujte tistemu, ki skrbi za pošto vaše domene.
bounce-policy-blocked = Zavrnjeno po pravilih prejemnega strežnika
bounce-policy-blocked-why = Pravila prejemnega strežnika tega sporočila ne prepustijo, na primer zaradi velikosti, priponk ali pošiljatelja.
bounce-policy-blocked-do = Razlog je pogosto naveden v odgovoru strežnika pod možnostjo Podrobnosti. Prejemnika vprašajte, ali lahko sprejme takšno pošto.
bounce-geo-blocked = Zavrnjeno zaradi izvora
bounce-geo-blocked-why = Prejemni strežnik ne sprejema pošte iz države ali omrežja, v katerem je vaš poštni strežnik.
bounce-geo-blocked-do = Osebo obvestite po drugi poti ali se obrnite na ponudnika e-pošte.
bounce-relay-denied = Strežnik ga ni posredoval naprej
bounce-relay-denied-why = Strežnik ni hotel posredovati sporočila naprej, pogosto zato, ker je bilo poslano brez prijave ali prek strežnika, ki ne skrbi za tega prejemnika.
bounce-relay-denied-do = V nastavitvah računa preverite strežnik za odhodno pošto in podatke za prijavo vanj.
bounce-auth-failure = Vašega naslova pošiljatelja ni bilo mogoče preveriti
bounce-auth-failure-why = Prejemni strežnik ni mogel potrditi, da je sporočilo res prišlo iz vaše domene (SPF, DKIM ali DMARC).
bounce-auth-failure-do = To obvestilo posredujte tistemu, ki skrbi za pošto vaše domene: njene nastavitve je treba popraviti. Medtem morda pomaga pošiljanje prek strežnika vašega ponudnika.
bounce-rate-limited = Preveč pošte naenkrat
bounce-rate-limited-why = Prejemni strežnik zaenkrat sprejema manj sporočil z vašega poštnega strežnika.
bounce-rate-limited-do = Malo počakajte in ga pošljite znova. Ko pišete veliko ljudem, pošiljajte manjšemu številu naenkrat.
bounce-greylisting = Začasno zadržano
bounce-greylisting-why = Prejemni strežnik neznane pošiljatelje prosi, naj poskusijo malo pozneje, kar je pogosta zaščita pred vsiljeno pošto.
bounce-greylisting-do = Če obvestilo navaja zamudo, lahko strežnik za pošiljanje poskusi znova. Če je dostava dokončno spodletela, poskusite sporočilo poslati pozneje.
bounce-server-error = Prejemni strežnik je imel težavo
bounce-server-error-why = Prejemni strežnik ni bil dosegljiv ali zaradi lastne težave ni mogel sprejeti sporočila.
bounce-server-error-do = Poskusite sporočilo poslati pozneje. Če težava ostaja, preverite, ali je del naslova za znakom @ pravilno napisan.
bounce-unknown = Ni dostavljeno
bounce-unknown-why = Obvestilo ne pove jasno, zakaj.
bounce-unknown-do = Več informacij je lahko v odgovoru strežnika pod možnostjo Podrobnosti. Če ne pomagajo, obvestilo posredujte ponudniku e-pošte.

## Several messages selected

selection-title = { $count ->
    [one] { $count } izbrano sporočilo
    [two] { $count } izbrani sporočili
    [few] { $count } izbrana sporočila
   *[other] { $count } izbranih sporočil
}
selection-unread = Neprebrana: { $count }
selection-flagged = Z zastavico: { $count }
delete-for-good-one = To sporočilo bo trajno izbrisano. Ga želite izbrisati?
delete-for-good-all = Vsa izbrana sporočila ({ $count }) bodo trajno izbrisana. Jih želite izbrisati?
delete-for-good-some = Nekatera sporočila ({ $count } od { $total }) bodo trajno izbrisana. Želite izbrisati sporočila?
done-read = { $count ->
   *[other] Označeno kot prebrano: { $messages }
}
done-unread = { $count ->
   *[other] Označeno kot neprebrano: { $messages }
}
done-flagged = { $count ->
   *[other] Označeno z zastavico: { $messages }
}
done-unflagged = Zastavica odstranjena: { $messages }
done-deleted-for-good = { $count ->
   *[other] Trajno izbrisano: { $messages }
}
done-archived = { $count ->
   *[other] Arhivirano: { $messages }
}
done-moved = { $count ->
   *[other] Premaknjeno v { $folder }: { $messages }
}
done-copied = { $count ->
   *[other] Kopirano v { $folder }: { $messages }
}
done-moving = { $count ->
   *[other] Premikanje v { $folder }: { $messages }...
}
done-copying = { $count ->
   *[other] Kopiranje v { $folder }: { $messages }...
}
done-moved-back = { $count ->
   *[other] Vrnjeno v { $folder }: { $messages }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Spremljate { $count } pogovor
    [two] Spremljate { $count } pogovora
    [few] Spremljate { $count } pogovore
   *[other] Spremljate { $count } pogovorov
}
done-unwatched = { $count ->
    [one] Prenehali ste spremljati { $count } pogovor
    [two] Prenehali ste spremljati { $count } pogovora
    [few] Prenehali ste spremljati { $count } pogovore
   *[other] Prenehali ste spremljati { $count } pogovorov
}
done-ignored = { $count ->
    [one] { $count } pogovor je prezrt
    [two] { $count } pogovora sta prezrta
    [few] { $count } pogovori so prezrti
   *[other] { $count } pogovorov je prezrtih
}
done-unignored = { $count ->
    [one] { $count } pogovor ni več prezrt
    [two] { $count } pogovora nista več prezrta
    [few] { $count } pogovori niso več prezrti
   *[other] { $count } pogovorov ni več prezrtih
}
their-folders = njihove mape
undo-move = Razveljavi premik
undo-delete = Razveljavi brisanje
undo-archive = Razveljavi arhiviranje
undo-junk = Razveljavi označitev kot neželeno
undo-not-junk = Razveljavi označitev kot želeno
undo-send = Razveljavi pošiljanje
nothing-to-undo = Ničesar ni mogoče razveljaviti.
messages-gone = Sporočil ni več.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Ta mapa ne more vsebovati sporočil.
not-archived-here = Sporočil v tej mapi ni mogoče arhivirati.
not-emptied-here = Izprazniti je mogoče samo mapi Izbrisano in Neželena e-pošta.
next-unread-question = V mapi { $folder } ni več neprebranih sporočil.

    Želite odpreti { $next }, naslednjo mapo z neprebranimi sporočili?
no-unread-left = Ni več neprebranih sporočil.
empty-question = { $count ->
    [1] Želite izprazniti mapo »{ $folder }«?

        Sporočilo v njej bo trajno izbrisano. Ni ga mogoče obnoviti.
   *[other] Želite izprazniti mapo »{ $folder }«?

        Vsebina ({ $messages }) bo trajno izbrisana. Ni je mogoče obnoviti.
}
no-junk-folder = Ta račun nima mape Neželena e-pošta, v katero bi lahko premaknili sporočila.
no-inbox-folder = Ta račun nima mape Prejeto, v katero bi lahko premaknili sporočila.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
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

move-window-title-move = { $count ->
    [one] Premakni { $count } sporočilo
    [two] Premakni { $count } sporočili
    [few] Premakni { $count } sporočila
   *[other] Premakni { $count } sporočil
}
move-window-title-copy = { $count ->
    [one] Kopiraj { $count } sporočilo
    [two] Kopiraj { $count } sporočili
    [few] Kopiraj { $count } sporočila
   *[other] Kopiraj { $count } sporočil
}
move-window-prompt-move = { $count ->
    [one] Premaknite { $count } izbrano sporočilo v:
    [two] Premaknite { $count } izbrani sporočili v:
    [few] Premaknite { $count } izbrana sporočila v:
   *[other] Premaknite { $count } izbranih sporočil v:
}
move-window-prompt-copy = { $count ->
    [one] Kopirajte { $count } izbrano sporočilo v:
    [two] Kopirajte { $count } izbrani sporočili v:
    [few] Kopirajte { $count } izbrana sporočila v:
   *[other] Kopirajte { $count } izbranih sporočil v:
}
# the folders used last, over the folder tree
targets-recent = Nedavno
# the folder the messages are in, which can not be chosen
target-current = { $folder } (trenutna)
# a folder used last, with its account when there are several: "Archive (Work)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Premikanje v { $folder }: { $messages } (trenutno { $done })...
transfer-copying = Kopiranje v { $folder }: { $messages } (trenutno { $done })...
transfer-another-account = drug račun
transfer-folder-gone = mape, v katero je bilo namenjeno, ni več
transfer-not-on-server = sporočila ni več na strežniku
transfer-not-moved = { $count ->
   *[other] Premik v drug račun ni uspel ({ $messages }): { $reason }
}
transfer-not-copied = { $count ->
   *[other] Kopiranje v drug račun ni uspelo ({ $messages }): { $reason }
}
transfer-none-moved = Nobenega sporočila ni bilo mogoče premakniti
transfer-none-copied = Nobenega sporočila ni bilo mogoče kopirati

## Messages as files

export-not-in-time = sporočila ni bilo mogoče pravočasno prenesti
export-not-saved = Shranjevanje ni uspelo: { $failed }; skupaj: { $messages } ({ $problems })
export-not-attached = sporočil ni bilo mogoče pripeti: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
   *[other] Shranjeno v { $folder }: { $messages }
}
download-progress = Prenos: { $done } / { $total }
download-done = Preneseno: { $size }
downloading-messages = { $count ->
   *[other] Prenašanje: { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
   *[other] V čakalni vrsti za uvoz v { $folder }: { $messages }
}
import-not-put = Tega ni bilo mogoče dodati v mapo:

    { $problems }

## Problems the windows show

error-store = lokalna shramba: { $error }
error-not-found = ni najdeno
error-closed = zapiranje
error-other-account = v brskalniku ste prijavljeni v račun »{ $email }«, ne v ta račun
# a password or sign-in the mail server refused, with the server's words
failure-authentication = strežnik ni sprejel prijave ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = povezave s strežnikom ni bilo mogoče vzpostaviti ali pa je bila prekinjena ({ $reason })
error-in-use = ni je mogoče odstraniti, dokler se z njo prijavljajo računi: { $accounts }
error-turned-off = ta aplikacija za prijavo je za nove račune izklopljena
error-folder-name = ime mape mora imeti od 1 do 200 znakov in ne sme vsebovati kontrolnih znakov
error-folder-separator = ime mape na tem strežniku ne sme vsebovati znaka »{ $separator }«
error-folder-special = mape Prejeto in posebnih map ni mogoče preimenovati ali izbrisati
error-no-recipients = sporočilo nima prejemnikov
error-bad-address = »{ $address }« ni e-poštni naslov
error-not-own-address = { $address } ni med naslovi pošiljatelja tega računa. Dodajte ga v polje »Drugi naslovi, s katerih pošiljate« v lastnostih računa.
rule-query-refused = Pravila ne morejo filtrirati po mapi ali datumu ({ $words }).
rule-no-query = Vnesite iskalne pogoje za dohodna sporočila.
rule-no-action = Izberite vsaj eno dejanje za pravilo.
error-attachment = Datoteke { $path } ni bilo mogoče prebrati: { $error }
error-no-drafts = račun nima mape Osnutki, v katero bi lahko shranili sporočilo
error-draft-attachment = priponke osnutka ni bilo mogoče ohraniti: { $error }
error-password-not-saved = gesla ni bilo mogoče shraniti za naslednji zagon: { $error }
error-sign-in-not-saved = novih podatkov za prijavo ni bilo mogoče shraniti za naslednji zagon: { $error }
error-import-unreadable = Datoteke { $path } ni mogoče prebrati: { $error }
error-import-too-large = Datoteka { $path } je večja od 50 MB
error-import-not-mail = Datoteka { $path } ni e-poštno sporočilo
error-list-answered = strežnik poštnega seznama je vrnil stanje { $status }
error-not-built = sporočila ni bilo mogoče sestaviti
error-outbox-waits = { $count ->
    [one] v mapi Odpošiljanje čaka { $count } sporočilo; ob naslednjem pošiljanju/prejemanju bo program znova poskusil poslati čakajočo pošto
    [two] v mapi Odpošiljanje čakata { $count } sporočili; ob naslednjem pošiljanju/prejemanju bo program znova poskusil poslati čakajočo pošto
    [few] v mapi Odpošiljanje čakajo { $count } sporočila; ob naslednjem pošiljanju/prejemanju bo program znova poskusil poslati čakajočo pošto
   *[other] v mapi Odpošiljanje čaka { $count } sporočil; ob naslednjem pošiljanju/prejemanju bo program znova poskusil poslati čakajočo pošto
}
error-draft-not-removed = prejšnjega osnutka sporočila ni bilo mogoče odstraniti iz mape Osnutki: { $reason }
error-sent-but = sporočilo je bilo poslano, vendar { $problem }
error-sent-still-in-outbox = je še vedno v mapi Odpošiljanje: { $error }
error-sent-no-copy = kopije ni bilo mogoče shraniti v mapo Poslano: { $reason }
error-no-password = za ta račun ni gesla
error-no-sign-in = za ta račun ni shranjenih podatkov za prijavo
error-provider-missing = ta različica ne more uporabiti nastavitev prijave »{ $provider }«. Preverite, ali je bila aplikacija za prijavo odstranjena
error-provider-servers = strežniki tega računa se ne ujemajo s strežniki njegove aplikacije za prijavo
error-app-scopes = { $reason }. Poštni strežnik ni sprejel žetona aplikacije za prijavo: preverite, ali dovoljenja (scopes) aplikacije omogočajo dostop do pošte
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Vgrajena Googlova aplikacija za prijavo je v tej različici privzeto izklopljena. Uporabite svojo Googlovo aplikacijo za prijavo ali geslo za aplikacije, če ga račun podpira. Če imate dostop kot preizkusni uporabnik, lahko vgrajeno aplikacijo vklopite v oknu Aplikacije za prijavo, ki ga odprete v oknu Računi.
sign-in-off-other = Izklopljena je v oknu Aplikacije za prijavo, kjer jo lahko znova vklopite. Do njega pridete prek okna Računi.
sign-in-app-no-name = aplikacija za prijavo potrebuje ime
sign-in-app-no-client = manjka ID odjemalca
sign-in-app-no-scopes = aplikacija za prijavo potrebuje dovoljenja (scopes), ki omogočajo dostop do pošte
sign-in-app-bad-host = nastavitve strežnika { $server } niso veljavne ali niso popolne. Preverite ime gostitelja in vrata
sign-in-app-plain = strežnik { $server } mora uporabljati SSL/TLS ali STARTTLS
sign-in-app-not-checked = izdajatelj še ni bil preverjen
sign-in-app-issuer-changed = izdajatelj se je spremenil: znova vnesite skrivnost odjemalca ali jo odstranite
sign-in-register-google = V konzoli Google Cloud Console ustvarite odjemalca OAuth vrste Desktop app z dovoljenjem https://mail.google.com/ na zaslonu za soglasje. Dokler je aplikacija v preizkušanju, se lahko prijavijo samo njeni preizkusni uporabniki.
sign-in-register-microsoft = V storitvi Microsoft Entra registrirajte aplikacijo s platformo Mobile and desktop applications, preusmeritvenim URI-jem http://localhost in dovoljenimi tokovi javnega odjemalca ter z delegiranimi dovoljenji IMAP.AccessAsUser.All, SMTP.Send in offline_access. Samo za svojo organizacijo kot izdajatelja uporabite https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Registrirajte izvornega (javnega) odjemalca s spodnjim preusmeritvenim URI-jem; ponudnik mora na njem dovoliti katera koli vrata (RFC 8252). Dodajte dovoljenje (scope), s katerim ponudnik omogoča dostop do pošte.

## Calendar invitations

repeats = Ponavljanje
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Vsak dan
       *[other] Vsak { $interval }. dan
    }
    [week] { $interval ->
        [1] Vsak teden
       *[other] Vsak { $interval }. teden
    }
    [month] { $interval ->
        [1] Vsak mesec
       *[other] Vsak { $interval }. mesec
    }
   *[year] { $interval ->
        [1] Vsako leto
       *[other] Vsako { $interval }. leto
    }
}
# "Every week on Monday, Wednesday"
repeats-on = { $repeats }, ob dnevih: { $days }
# "Every week, 10 times"
repeats-times = { $count ->
    [1] { $repeats }, enkrat
   *[other] { $repeats }, { $count }-krat
}
day-monday = ponedeljek
day-tuesday = torek
day-wednesday = sreda
day-thursday = četrtek
day-friday = petek
day-saturday = sobota
day-sunday = nedelja

## AI agents

agent-level-read = Branje pošte: mape, seznami sporočil, pogovori, iskanje, sporočila in njihove priponke, pravila za sporočila ter stiki
agent-level-organize = Urejanje pošte: spreminjanje prebranosti, zastavic in njihovih barv, označevanje neželene pošte, premikanje in arhiviranje sporočil, ustvarjanje in preimenovanje map, spremljanje in prezrtje pogovorov, brisanje v mapo Izbrisano ter odjava s poštnih seznamov po vaši potrditvi
agent-level-drafts = Pisanje osnutkov, ki jih pošljete sami
agent-level-send = Pošiljanje pošte samo z vašo potrditvijo vsakega sporočila
agent-connect-title = { $program } želi dostop do vaše pošte
agent-connect-detail = Agent UI želi dostop do vaše pošte prek programa Inbox Classic. Izberite dovoljena dejanja in račune, do katerih sme dostopati. To lahko pozneje spremenite v meniju Orodja > Agenti UI.

    Sporočila drugih ljudi lahko vsebujejo navodila, namenjena zavajanju agenta. Preden agent pošlje sporočilo, Inbox Classic vedno zahteva vašo potrditev.
agent-reply-to = Odgovor na sporočilo »{ $subject }«
agent-reply-all-on = Odgovor vsem na sporočilo »{ $subject }«
agent-forward-of = Posredovanje sporočila »{ $subject }«
agent-never-written-one = Na naslov { $address } še niste pisali.
agent-never-written-many = Število naslovov, na katere še niste pisali: { $count }.
agent-send-title = { $program } želi poslati to sporočilo
agent-send-detail = Preverite prejemnike in vsebino sporočila. Po potrditvi sporočilo čaka v mapi Odpošiljanje najmanj { $seconds } sekund. Dokler ni poslano, ga lahko izbrišete.
agent-change-title = Kaj sme početi { $program }
agent-change-allowed = Izberite, kaj smejo agenti UI tega programa početi z vašo pošto.
agent-change-refused = Temu programu ste zavrnili dostop. Znova mu ga lahko dovolite, da bodo njegovi agenti lahko delali z vašo pošto.
agent-log-taken-back = { $entry } (vsaj delno razveljavljeno)
agent-files = Datoteke: { $files }
agent-undo-refused = Tega dejanja ni mogoče razveljaviti.
agent-undo-refused-why = Tega dejanja ni mogoče razveljaviti: { $reason }.
agent-undo-impossible = tega dejanja ni mogoče razveljaviti
agent-undo-not-in-folder = sporočila ni več v tej mapi
agent-undo-not-arrived = sporočila še ni v ciljni mapi
agent-undo-sent = sporočila ni več v mapi Odpošiljanje
agent-original-not-downloaded = izvirno sporočilo še ni bilo preneseno. Najprej ga odprite
agent-turned-away = Dostop zavrnjen
agent-can-nothing = Nič
agent-can-read = branje
agent-can-organize = urejanje
agent-can-drafts = pisanje osnutkov
agent-can-send = pošiljanje z vašo potrditvijo
# "Read, organize and write drafts"
agent-can-list = { $first } in { $last }
agent-accounts = { $count ->
    [0] noben račun
    [one] { $count } račun
    [two] { $count } računa
    [few] { $count } računi
   *[other] { $count } računov
}
# "Read and organize; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Tega sporočila ni mogoče prebrati.
agent-encrypted-original = To sporočilo je šifrirano: agent nanj ne more odgovoriti ali ga posredovati, ker ne zna šifrirati.
agent-encrypted = To sporočilo je šifrirano, zato agent ne more prebrati njegove vsebine. Odprete ga lahko v programu Inbox Classic.
agent-too-many-changes = Preveč sprememb v zadnjih 30 dneh: ta agent jih je naredil toliko, kolikor jih Inbox Classic za en program hrani v dnevniku. Več jih bo lahko naredil, ko bodo najstarejše stare 30 dni.
agent-too-many-reads = Preveč branja v zadnjih 30 dneh: ta agent je prebral toliko, kolikor Inbox Classic za en program hrani v dnevniku. Več bo lahko bral, ko bodo najstarejša branja stara 30 dni.
list-encrypted = Šifrirano sporočilo
agent-log-composed = Odprl novo sporočilo za urejanje. Zadeva: »{ $subject }«
agent-log-refused = Niste dovolili pošiljanja sporočila »{ $subject }«
agent-log-sent = Uvrstil sporočilo »{ $subject }« v čakalno vrsto za pošiljanje. Prejemniki: { $to }
agent-log-draft = Shranil osnutek »{ $subject }«
agent-log-draft-replaced = Zamenjal osnutek »{ $subject }«
agent-log-draft-discarded = Zahteval trajni izbris osnutka »{ $subject }«
agent-draft-note = Ta osnutek je pripravil agent UI programa »{ $program }«. Pred pošiljanjem preverite prejemnike in besedilo.
agent-log-read = Označil sporočilo »{ $subject }« kot prebrano
agent-log-unread = Označil sporočilo »{ $subject }« kot neprebrano
agent-log-flagged = Označil sporočilo »{ $subject }« z zastavico
agent-log-unflagged = Odstranil zastavico s sporočila »{ $subject }«
agent-log-deleted = Izbrisal sporočilo »{ $subject }«
agent-log-moved = Premaknil sporočilo »{ $subject }« v mapo »{ $folder }«
agent-log-junk = Označil sporočilo »{ $subject }« kot neželeno
agent-log-not-junk = Odstranil oznako neželene pošte s sporočila »{ $subject }«
agent-log-archived = Arhiviral sporočilo »{ $subject }«
agent-log-folder = Zahteval ustvarjanje mape »{ $name }«
agent-log-unsubscribed = Odobrili ste zahtevo za odjavo s poštnega seznama. Sporočilo: »{ $subject }«
agent-log-unsubscribe-failed = Zahteva za odjavo ni uspela. Sporočilo: »{ $subject }«. Razlog: { $reason }
agent-log-unsubscribe-refused = Odjave niste dovolili. Pošiljatelji: { $senders }
agent-unsubscribe-title = { $count ->
    [1] { $program } vas želi odjaviti s poštnega seznama
    [one] { $program } vas želi odjaviti s poštnih seznamov ({ $count })
    [two] { $program } vas želi odjaviti s poštnih seznamov ({ $count })
    [few] { $program } vas želi odjaviti s poštnih seznamov ({ $count })
   *[other] { $program } vas želi odjaviti s poštnih seznamov ({ $count })
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic bo spodaj navedenemu poštnemu seznamu poslal zahtevo za odjavo. Uporabil bo možnost odjave z enim klikom, ki jo seznam ponuja. Pri tem se e-pošta ne pošilja, prejeta sporočila pa ostanejo nespremenjena.
   *[other] Inbox Classic bo vsakemu spodaj navedenemu poštnemu seznamu poslal zahtevo za odjavo. Uporabil bo možnost odjave z enim klikom, ki jo ponuja posamezni seznam. Pri tem se e-pošta ne pošilja, prejeta sporočila pa ostanejo nespremenjena.
}
agent-log-flag-color = Označil sporočilo »{ $subject }« { $color ->
    [red] z rdečo zastavico
    [orange] z oranžno zastavico
    [yellow] z rumeno zastavico
    [green] z zeleno zastavico
    [blue] z modro zastavico
    [purple] z vijolično zastavico
   *[gray] s sivo zastavico
}
agent-log-renamed = Zahteval preimenovanje mape »{ $old }« v »{ $name }«
agent-log-watched = Začel spremljati pogovor »{ $subject }«
agent-log-ignored = Prezrl pogovor »{ $subject }«
agent-log-unmarked = Odstranil oznako spremljanja ali prezrtja pogovora »{ $subject }«
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = sporočilo je bilo medtem spremenjeno
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Označil { $count } sporočilo kot prebrano (iskanje: { $query })
    [two] Označil { $count } sporočili kot prebrani (iskanje: { $query })
    [few] Označil { $count } sporočila kot prebrana (iskanje: { $query })
   *[other] Označil { $count } sporočil kot prebrana (iskanje: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Označil { $count } sporočilo kot neprebrano (iskanje: { $query })
    [two] Označil { $count } sporočili kot neprebrani (iskanje: { $query })
    [few] Označil { $count } sporočila kot neprebrana (iskanje: { $query })
   *[other] Označil { $count } sporočil kot neprebrana (iskanje: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Označil { $count } sporočilo z zastavico (iskanje: { $query })
    [two] Označil { $count } sporočili z zastavico (iskanje: { $query })
    [few] Označil { $count } sporočila z zastavico (iskanje: { $query })
   *[other] Označil { $count } sporočil z zastavico (iskanje: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Odstranil zastavico pri { $count } sporočilu (iskanje: { $query })
    [two] Odstranil zastavico pri { $count } sporočilih (iskanje: { $query })
    [few] Odstranil zastavico pri { $count } sporočilih (iskanje: { $query })
   *[other] Odstranil zastavico pri { $count } sporočilih (iskanje: { $query })
}
agent-log-bulk-color = { $count ->
    [one] Označil { $count } sporočilo
    [two] Označil { $count } sporočili
    [few] Označil { $count } sporočila
   *[other] Označil { $count } sporočil
} { $color ->
    [red] z rdečo zastavico
    [orange] z oranžno zastavico
    [yellow] z rumeno zastavico
    [green] z zeleno zastavico
    [blue] z modro zastavico
    [purple] z vijolično zastavico
   *[gray] s sivo zastavico
} (iskanje: { $query })
agent-log-bulk-moved = { $count ->
    [one] Premaknil { $count } sporočilo v mapo »{ $folder }« (iskanje: { $query })
    [two] Premaknil { $count } sporočili v mapo »{ $folder }« (iskanje: { $query })
    [few] Premaknil { $count } sporočila v mapo »{ $folder }« (iskanje: { $query })
   *[other] Premaknil { $count } sporočil v mapo »{ $folder }« (iskanje: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Arhiviral { $count } sporočilo (iskanje: { $query })
    [two] Arhiviral { $count } sporočili (iskanje: { $query })
    [few] Arhiviral { $count } sporočila (iskanje: { $query })
   *[other] Arhiviral { $count } sporočil (iskanje: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Označil { $count } sporočilo kot neželeno (iskanje: { $query })
    [two] Označil { $count } sporočili kot neželeni (iskanje: { $query })
    [few] Označil { $count } sporočila kot neželena (iskanje: { $query })
   *[other] Označil { $count } sporočil kot neželena (iskanje: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Odstranil oznako neželene pošte pri { $count } sporočilu (iskanje: { $query })
    [two] Odstranil oznako neželene pošte pri { $count } sporočilih (iskanje: { $query })
    [few] Odstranil oznako neželene pošte pri { $count } sporočilih (iskanje: { $query })
   *[other] Odstranil oznako neželene pošte pri { $count } sporočilih (iskanje: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Izbrisal { $count } sporočilo (iskanje: { $query })
    [two] Izbrisal { $count } sporočili (iskanje: { $query })
    [few] Izbrisal { $count } sporočila (iskanje: { $query })
   *[other] Izbrisal { $count } sporočil (iskanje: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] V zadnjih 15 minutah
    [hour] V zadnji uri
    [hours] V zadnjih 4 urah
    [day] V zadnjih 24 urah
    [week] V zadnjih 7 dneh
   *[all] V zadnjih 30 dneh
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] Program { $program } v tem času ni naredil sprememb, ki bi jih bilo mogoče razveljaviti.
    [one] Želite razveljaviti { $count } spremembo, ki jo je program { $program } naredil v tem času?
    [two] Želite razveljaviti { $count } spremembi, ki ju je program { $program } naredil v tem času?
    [few] Želite razveljaviti { $count } spremembe, ki jih je program { $program } naredil v tem času?
   *[other] Želite razveljaviti { $count } sprememb, ki jih je program { $program } naredil v tem času?
}
agent-undo-since-detail = Program poskusi sporočila vrniti v prejšnje mape ter obnoviti prebranost in zastavice. Sporočila, ki še čakajo v mapi Odpošiljanje, izbriše. Pri tem preveri stanje, povezano s posameznim dejanjem, in preskoči neustrezna sporočila. Odstranitev zastavice lahko odstrani tudi barvo, ki ste jo spremenili pozneje.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Nič ni bilo razveljavljeno.
    [one] V celoti ali delno razveljavljeno { $count } dejanje.
    [two] V celoti ali delno razveljavljeni { $count } dejanji.
    [few] V celoti ali delno razveljavljena { $count } dejanja.
   *[other] V celoti ali delno razveljavljenih { $count } dejanj.
}
agent-undo-left-gone = { $count ->
    [one] { $count } sporočilo ni bilo več tam, kamor ga je postavila sprememba.
    [two] { $count } sporočili nista bili več tam, kamor ju je postavila sprememba.
    [few] { $count } sporočila niso bila več tam, kamor jih je postavila sprememba.
   *[other] { $count } sporočil ni bilo več tam, kamor jih je postavila sprememba.
}
agent-undo-left-changed = { $count ->
    [one] { $count } sporočilo je bilo medtem spremenjeno, z vaše strani ali na strežniku, in je ostalo, kot je.
    [two] { $count } sporočili sta bili medtem spremenjeni, z vaše strani ali na strežniku, in sta ostali, kot sta.
    [few] { $count } sporočila so bila medtem spremenjena, z vaše strani ali na strežniku, in so ostala, kot so.
   *[other] { $count } sporočil je bilo medtem spremenjenih, z vaše strani ali na strežniku, in je ostalo, kot je.
}
agent-undo-left-sent = { $count ->
    [one] { $count } sporočilo je že zapustilo mapo Odpošiljanje.
    [two] { $count } sporočili sta že zapustili mapo Odpošiljanje.
    [few] { $count } sporočila so že zapustila mapo Odpošiljanje.
   *[other] { $count } sporočil je že zapustilo mapo Odpošiljanje.
}
agent-undo-left-impossible = { $count ->
   *[other] Število sprememb, ki jih ni mogoče razveljaviti: { $count }.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] S tem sporočilom sprejmete povabilo »{ $summary }« ({ $when }).
    [tentative] S tem sporočilom pogojno sprejmete povabilo »{ $summary }« ({ $when }).
   *[decline] S tem sporočilom zavrnete povabilo »{ $summary }« ({ $when }).
} Odgovor je namenjen koledarskemu programu organizatorja. Stanje vašega odgovora v programu Inbox Classic se spremeni po uspešnem pošiljanju, ne po potrditvi organizatorja.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Sprejeto: { $summary }
    [tentative] Pogojno sprejeto: { $summary }
   *[decline] Zavrnjeno: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } sprejema to povabilo.
    [tentative] { $name } pogojno sprejema to povabilo.
   *[decline] { $name } zavrača to povabilo.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] prebral { $count } sporočilo
    [two] prebral { $count } sporočili
    [few] prebral { $count } sporočila
   *[other] prebral { $count } sporočil
}
agent-reads-attachments = { $count ->
    [one] zahteval { $count } priponko
    [two] zahteval { $count } priponki
    [few] zahteval { $count } priponke
   *[other] zahteval { $count } priponk
}
agent-reads-searches = { $count ->
    [one] iskal { $count }-krat
    [two] iskal { $count }-krat
    [few] iskal { $count }-krat
   *[other] iskal { $count }-krat
}
agent-reads-lists = { $count ->
    [one] pregledal seznam sporočil { $count }-krat
    [two] pregledal sezname sporočil { $count }-krat
    [few] pregledal sezname sporočil { $count }-krat
   *[other] pregledal sezname sporočil { $count }-krat
}
# each read under that row
agent-read-message = Prebral sporočilo »{ $subject }«
agent-read-conversation = { $count ->
    [one] Prebral pogovor »{ $subject }« ({ $count } sporočilo)
    [two] Prebral pogovor »{ $subject }« ({ $count } sporočili)
    [few] Prebral pogovor »{ $subject }« ({ $count } sporočila)
   *[other] Prebral pogovor »{ $subject }« ({ $count } sporočil)
}
agent-read-attachment = Zahteval priponko »{ $name }« sporočila »{ $subject }«
agent-read-search = { $count ->
    [one] Iskal »{ $query }«: { $count } sporočilo
    [two] Iskal »{ $query }«: { $count } sporočili
    [few] Iskal »{ $query }«: { $count } sporočila
   *[other] Iskal »{ $query }«: { $count } sporočil
}
agent-read-people = Iskal osebe, katerih ime ali naslov se začne z »{ $query }«
agent-read-list = { $count ->
    [one] Pregledal { $count } vrstico na seznamu »{ $folder }«
    [two] Pregledal { $count } vrstici na seznamu »{ $folder }«
    [few] Pregledal { $count } vrstice na seznamu »{ $folder }«
   *[other] Pregledal { $count } vrstic na seznamu »{ $folder }«
}
agent-read-changes = { $count ->
    [one] Pregledal podatke o { $count } novem sporočilu
    [two] Pregledal podatke o { $count } novih sporočilih
    [few] Pregledal podatke o { $count } novih sporočilih
   *[other] Pregledal podatke o { $count } novih sporočilih
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Iz aplikacije { $terminal } zagnani programi
agent-terminal-programs-windows = Iz terminala ({ $terminal }) zagnani programi
agent-terminal-programs-linux = Iz terminala ({ $terminal }) zagnani programi
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Iz aplikacije { $terminal } zagnan program
agent-terminal-program-windows = Iz terminala ({ $terminal }) zagnan program
agent-terminal-program-linux = Iz terminala ({ $terminal }) zagnan program
agent-connect-title-terminal = { $programs } želijo dostop do vaše pošte
agent-connect-terminal-detail = Agenti, zagnani iz iste prepoznane terminalske aplikacije, si delijo dostop, ki ga dovolite tukaj. Za ločeno upravljanje agenta v njegovih nastavitvah MCP med argumente dodajte --name in poljubno ime. Ime ne potrjuje identitete programa.
agent-connect-claimed = Program se je predstavil kot { $claimed }. Inbox Classic je preveril, kateri program ga je zagnal: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = ponudnik ni dal žetona za osvežitev
sign-in-no-account = ponudnik ni povedal, kateri račun se je prijavil
sign-in-not-finished = prijava še ni končana
secrets-unavailable = { $store } ni na voljo
secrets-unavailable-why = { $store } ni na voljo: { $error }
secrets-windows = Upravitelj poverilnic
secrets-mac = Obesek za ključe
secrets-linux = Sistemska shramba ključev (Secret Service)
error-no-such-file = take datoteke ni
cards-file-too-big = Datoteka presega omejitev velikosti za uvoz imenika.
ui-sender-added = Stik »{ $name }« je dodan v Imenik.
ui-sender-known = Stik »{ $name }« je že v Imeniku.
ui-sender-none = Pošiljatelj tega sporočila nima e-poštnega naslova, ki bi ga lahko dodali.
card-name-needed = Stik nima imena in nima e-poštnega naslova.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Koda iz domene { $domain }
otp-copy = Kopiraj
otp-note = Vnesite jo samo na strani domene { $domain }.
otp-old = Glede na datum sporočila je bila koda poslana več kot eno uro pred odprtjem in je verjetno že potekla.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } udeleženec
        [two] { $count } udeleženca
        [few] { $count } udeleženci
       *[other] { $count } udeležencev
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = Koda iz domene { $domain }: { $code }

## OpenPGP keys (keys.rs)
pgp-key-valid = Veljaven
pgp-key-expires = Veljaven do { $date }
pgp-key-expired = Potekel { $date }
pgp-key-revoked = Preklican
pgp-key-revoked-why = Preklican: { $reason }
pgp-key-not-valid = Ni veljaven
pgp-key-locked = Zasebnega ključa ni mogoče odpreti. Preverite, ali je shramba ({ $store }) dostopna in odklenjena. Če je bil zaščitni ključ izgubljen ali ponastavljen, znova uvozite varnostno kopijo zasebnega ključa.
pgp-source-own = Ustvarjen v programu Inbox Classic
pgp-source-file = Uvožen iz datoteke
pgp-source-paste = Prilepljen
pgp-source-attachment = Iz sporočila
pgp-source-vcard = Iz vizitke stika
pgp-source-wkd = Od ponudnika e-pošte pošiljatelja
pgp-source-keyserver = S strežnika keys.openpgp.org
pgp-source-autocrypt = Iz glave Autocrypt sporočila
pgp-error-no-store = Zasebnih ključev ni mogoče zaščititi s shrambo { $store }: { $error }
pgp-error-wrong-passphrase = Zaščitno geslo ni pravilno.
pgp-error-not-a-key = To ni ključ OpenPGP.
pgp-error-too-large = Ključ je prevelik.
pgp-error-unusable = Ključ nima uporabnih delov za zahtevano dejanje ali uporablja nepodprte kriptografske algoritme.
pgp-imported-private = { $count ->
    [one] Uvožen je bil { $count } zasebni ključ.
    [two] Uvožena sta bila { $count } zasebna ključa.
    [few] Uvoženi so bili { $count } zasebni ključi.
   *[other] Uvoženih je bilo { $count } zasebnih ključev.
}
pgp-imported-public = { $count ->
    [one] Uvožen je bil { $count } ključ.
    [two] Uvožena sta bila { $count } ključa.
    [few] Uvoženi so bili { $count } ključi.
   *[other] Uvoženih je bilo { $count } ključev.
}
pgp-imported-pending = Za naslove { $addresses } se že uporablja drug ključ. Novega lahko izberete v lastnostih stika.
pgp-error-needs-passphrase = Zasebni ključ je zaščiten z zaščitnim geslom. Vnesite ga, da uvozite ključ.
pgp-error-mismatch = Zasebni ključ ne pripada svojemu javnemu ključu. Morda je bil spremenjen.
pgp-file-name-public = { $who } javni ključ.asc
pgp-file-name-private = { $who } varnostna kopija zasebnega ključa.asc
pgp-pending = Za naslov { $address } je bil najden drug ključ. Datum: { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Podpisnik: { $signer }; lastnik ključa je potrjen
pgp-part-signed = Podpisnik: { $signer } (lastnik ključa ni potrjen)
pgp-part-other = Podpisnik: { $signer } (ni pošiljatelj sporočila)
pgp-part-unknown-key = Podpisano, vendar ključ ni znan
pgp-part-not-signed = Ni podpisano
pgp-part-not-checked = Podpis ni preverjen
pgp-part-encrypted = Šifrirano. { $signature }
pgp-part-no-key = Šifrirano za ključ, ki ga nimate
pgp-part-changed = Celovitosti šifriranega dela ni bilo mogoče potrditi, zato ni prikazan
pgp-part-unprotected = Šifrirano brez zaščite pred spremembami, ni prikazano
pgp-part-broken = Šifriranega dela ni mogoče prebrati
pgp-why-mismatch = Podpis se ne ujema s tem besedilom
pgp-why-weak-hash = Podpis uporablja zgoščevalni algoritem { $hash }, ki ni več varen
pgp-why-key-expired = Podpisano po tem, ko je ključ potekel { $date }
pgp-why-key-revoked = Podpisano s preklicanim ključem
pgp-why-not-signing-key = Podpisano s ključem, ki ne sme podpisovati
pgp-why-from-future = Podpis ima datum v prihodnosti
pgp-why-signature-expired = Podpis je potekel
pgp-why-key-not-valid = Podpisano z neveljavnim ključem
pgp-why-not-for-you = Podpisano za druge prejemnike in posredovano vam
pgp-why-not-key-in-use = Ključ podpisa se razlikuje od ključa, izbranega za naslov { $address }
pgp-part-pictures-loaded = { $label }. Slike so bile naložene z interneta
pgp-error-no-own-key = Za { $address } nimate ključa, s katerim bi podpisovali ali šifrirali. Ustvarite ga v meniju Orodja > Šifrirni ključi ali izklopite Podpiši in Šifriraj.
pgp-error-missing-keys = { $count ->
    [1] Prejemnik { $addresses } nima uporabnega ključa za šifriranje.
   *[other] Ti prejemniki nimajo uporabnih ključev za šifriranje: { $addresses }.
}
pgp-error-encrypted-quote = To sporočilo vsebuje besedilo, slike ali priponke iz šifriranega sporočila, zato ga lahko pošljete samo šifrirano. Vklopite Šifriraj ali odstranite vso vsebino, prevzeto iz šifriranega sporočila.
pgp-error-protect = Sporočila ni bilo mogoče podpisati ali šifrirati: { $reason }
pgp-found-keys = Ključi so bili najdeni za naslove: { $addresses }.
pgp-found-none = Za naslove { $addresses } ni bilo mogoče najti ključev. Prejemnike prosite za njihove javne ključe.
pgp-found-no-key = Noben ključ ni bil najden.
pgp-find-unavailable = Ključev zdaj ni bilo mogoče poiskati: { $error }
pgp-publish-pending = keys.openpgp.org je poslal potrditveno povezavo na naslednje naslove: { $addresses }. Potrdite vsak naslov posebej, da bo ključ mogoče poiskati po njem.
pgp-publish-done = Vaš ključ je objavljen na keys.openpgp.org za { $addresses }.
pgp-publish-failed = Ključa ni bilo mogoče objaviti: { $error }
pgp-keyserver-off = Iskanje ključev na keys.openpgp.org je izklopljeno. Mesto nastavitve: { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [1] Sporočilo bo ob pošiljanju šifrirano in digitalno podpisano. Vsebino boste lahko prebrali le vi in { $addresses }.
    [one] Sporočilo bo ob pošiljanju šifrirano in digitalno podpisano. Vsebino boste lahko prebrali le vi in { $count } prejemnik.
    [two] Sporočilo bo ob pošiljanju šifrirano in digitalno podpisano. Vsebino boste lahko prebrali le vi in { $count } prejemnika.
    [few] Sporočilo bo ob pošiljanju šifrirano in digitalno podpisano. Vsebino boste lahko prebrali le vi in { $count } prejemniki.
   *[other] Sporočilo bo ob pošiljanju šifrirano in digitalno podpisano. Vsebino boste lahko prebrali le vi in { $count } prejemnikov.
}
pgp-compose-encrypt-ready = Ob pošiljanju bo sporočilo šifrirano in digitalno podpisano. Dodajte prejemnike, katerih ključe imate.
pgp-compose-missing = { $count ->
    [1] Prejemnik nima uporabnega ključa: { $addresses }. Sporočila še ni mogoče šifrirati.
    [one] { $count } prejemnik nima uporabnega ključa: { $addresses }. Sporočila še ni mogoče šifrirati.
    [two] { $count } prejemnika nimata uporabnih ključev: { $addresses }. Sporočila še ni mogoče šifrirati.
    [few] { $count } prejemniki nimajo uporabnih ključev: { $addresses }. Sporočila še ni mogoče šifrirati.
   *[other] { $count } prejemnikov nima uporabnih ključev: { $addresses }. Sporočila še ni mogoče šifrirati.
}
pgp-compose-looking = Iskanje ključev prejemnikov: { $addresses }...
pgp-compose-signed = Sporočilo bo ob pošiljanju digitalno podpisano. Prejemniki bodo lahko preverili, s katerim ključem je podpisano in ali se je vsebina po podpisu spremenila.
pgp-compose-reply-clear = Sporočilo bo poslano brez šifriranja, čeprav je bilo izvirno sporočilo šifrirano.
pgp-compose-encrypted-files = Sporočilo vsebuje priponke iz šifriranega sporočila, zato ga ni mogoče poslati brez šifriranja. Vklopite možnost »Šifriraj« ali odstranite te priponke.
pgp-compose-sign-tip = Digitalno podpišite sporočilo s svojim ključem, da bodo prejemniki lahko preverili uporabljeni ključ in morebitne spremembe vsebine po podpisu
pgp-compose-sign-tip-encrypted = Sporočila, poslana v šifrirani obliki, so tudi digitalno podpisana
pgp-compose-encrypt-tip = Šifrirajte vsebino sporočila, da bo dostopna le vam in prejemnikom
pgp-compose-make-key = Za naslov { $address } še nimate lastnega ključa. Ga želite ustvariti zdaj? Z njim boste lahko digitalno podpisovali in šifrirali sporočila.
pgp-compose-key-unusable =
    Vašega ključa za naslov { $address } ni mogoče uporabiti.

    Razlog: { $state }

    V oknu »Šifrirni ključi« preverite njegovo stanje. Če je zasebni ključ začasno nedostopen, preverite sistemsko shrambo ključev. Po potrebi lahko uvozite varnostno kopijo ključa ali ustvarite nov ključ.
pgp-compose-encrypt-off-quote = Sporočilo vsebuje besedilo, slike ali priponke iz šifriranega sporočila. Brez šifriranja ga lahko pošljete šele, ko odstranite to vsebino. Ali želite kljub temu izklopiti šifriranje?
pgp-compose-encrypt-off-reply = Odgovarjate na šifrirano sporočilo ali ga posredujete. Brez šifriranja lahko vsebino vašega sporočila preberejo tudi strežniki, prek katerih potuje. Ali želite izklopiti šifriranje?
pgp-recipient-verified = Lastnik ključa je potrjen
pgp-recipient-found = Lastnik ključa ni potrjen
pgp-recipient-own = Vaš ključ
pgp-recipient-looking = Iskanje ključa...
pgp-recipient-missing = Ni ključa
pgp-recipient-not-found = Ključ ni bil najden. Zadnje iskanje: { $date }
pgp-recipient-unusable = Ključa ni mogoče uporabiti: { $state }
pgp-recipients-intro = Ob pošiljanju se sporočilo šifrira s ključi prejemnikov in z vašim ključem.
pgp-recipients-intro-missing = { $count ->
    [1] { $count } prejemnik nima uporabnega ključa za šifriranje. Poiščite njegov ključ, odstranite prejemnika iz sporočila ali sporočilo pošljite brez šifriranja, če ne vsebuje besedila, slik ali priponk iz šifriranih sporočil.
    [2] { $count } prejemnika nimata uporabnih ključev za šifriranje. Poiščite njuna ključa, odstranite oba prejemnika iz sporočila ali sporočilo pošljite brez šifriranja, če ne vsebuje besedila, slik ali priponk iz šifriranih sporočil.
    [one] { $count } prejemnik nima uporabnega ključa za šifriranje. Poiščite manjkajoče ključe, odstranite prejemnike brez uporabnih ključev iz sporočila ali sporočilo pošljite brez šifriranja, če ne vsebuje besedila, slik ali priponk iz šifriranih sporočil.
    [two] { $count } prejemnika nimata uporabnih ključev za šifriranje. Poiščite manjkajoče ključe, odstranite prejemnike brez uporabnih ključev iz sporočila ali sporočilo pošljite brez šifriranja, če ne vsebuje besedila, slik ali priponk iz šifriranih sporočil.
    [few] { $count } prejemniki nimajo uporabnih ključev za šifriranje. Poiščite manjkajoče ključe, odstranite prejemnike brez uporabnih ključev iz sporočila ali sporočilo pošljite brez šifriranja, če ne vsebuje besedila, slik ali priponk iz šifriranih sporočil.
   *[other] { $count } prejemnikov nima uporabnih ključev za šifriranje. Poiščite manjkajoče ključe, odstranite prejemnike brez uporabnih ključev iz sporočila ali sporočilo pošljite brez šifriranja, če ne vsebuje besedila, slik ali priponk iz šifriranih sporočil.
}
pgp-details-part = Del { $number }: { $label }
attachment-from-part = Iz dela { $number }: { $label }
pgp-details-signed = Podpisano { $when } s ključem { $key }
pgp-details-unknown-key = Podpisano s ključem { $key }, ki ga nimate
pgp-details-opened = Dešifrirano z vašim ključem { $key }
pgp-details-for = Šifrirano za { $keys }
pgp-details-plain = Ni podpisano in ni šifrirano
pgp-bar-parts = To sporočilo ima več delov ({ $count }): { $list }. Pri vsakem delu piše, kako je zaščiten.
pgp-bar-count-verified = Podpisani s potrjenim lastnikom ključa: { $count }
pgp-bar-count-encrypted-signed = Šifrirani in podpisani: { $count }
pgp-bar-count-encrypted = Šifrirani: { $count }
pgp-bar-count-signed = Podpisani: { $count }
pgp-bar-count-warning = { $count ->
   *[other] Zahtevajo pozornost: { $count }
}
pgp-bar-count-neutral = Brez potrjenega podpisa: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Nastavitve
setup-part-preferences = Nastavitve oken
setup-part-accounts = Računi
setup-part-sign-in-apps = Aplikacije za prijavo
setup-part-contacts = Stiki in skupine
setup-part-keys = Šifrirni ključi
setup-part-rules = Pravila za sporočila
setup-part-trusted-senders = Zaupanja vredni pošiljatelji
setup-holds-settings = { $count ->
    [one] { $count } nastavitev
    [two] { $count } nastavitvi
    [few] { $count } nastavitve
   *[other] { $count } nastavitev
}
setup-holds-preferences = { $count ->
    [one] { $count } nastavitev okna
    [two] { $count } nastavitvi oken
    [few] { $count } nastavitve oken
   *[other] { $count } nastavitev oken
}
setup-holds-accounts = { $count ->
    [one] { $count } račun
    [two] { $count } računa
    [few] { $count } računi
   *[other] { $count } računov
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavo
    [two] { $count } aplikaciji za prijavo
    [few] { $count } aplikacije za prijavo
   *[other] { $count } aplikacij za prijavo
}
setup-holds-built-in = Katere vgrajene aplikacije za prijavo so vklopljene
setup-holds-contacts = { $count ->
    [one] { $count } stik
    [two] { $count } stika
    [few] { $count } stiki
   *[other] { $count } stikov
}
setup-holds-groups = { $count ->
    [one] { $count } skupina
    [two] { $count } skupini
    [few] { $count } skupine
   *[other] { $count } skupin
}
setup-holds-own-keys = { $count ->
    [one] { $count } lastni ključ
    [two] { $count } lastna ključa
    [few] { $count } lastni ključi
   *[other] { $count } lastnih ključev
}
setup-holds-contact-keys = { $count ->
    [one] { $count } ključ stika
    [two] { $count } ključa stikov
    [few] { $count } ključi stikov
   *[other] { $count } ključev stikov
}
setup-holds-rules = { $count ->
    [one] { $count } pravilo
    [two] { $count } pravili
    [few] { $count } pravila
   *[other] { $count } pravil
}
setup-holds-trusted-senders = { $count ->
    [one] { $count } zaupanja vreden pošiljatelj
    [two] { $count } zaupanja vredna pošiljatelja
    [few] { $count } zaupanja vredni pošiljatelji
   *[other] { $count } zaupanja vrednih pošiljateljev
}
setup-sign-in-password = Geslo
setup-account-secret-password = Njegovo geslo je v datoteki.
setup-account-secret-token = Podatki za prijavo v račun so v datoteki.
setup-account-asks-password = Po uvozu bo zahteval geslo.
setup-account-signs-in-again = Po uvozu se boste vanj znova prijavili.
setup-account-here = Tukaj je že nastavljen, zato je preskočen.
setup-account-no-app = Prijavlja se z aplikacijo { $app }, ki tukaj ni nastavljena. Uvozite tudi aplikacije za prijavo.
setup-invalid-address = »{ $address }« ni e-poštni naslov.
setup-invalid-server = Nastavitve strežnika { $server } niso veljavne. Preverite ime gostitelja, vrata in način zaščite povezave.
setup-invalid-user = Nima uporabniškega imena.
setup-invalid-sign-in = Inbox Classic ne more uporabiti teh nastavitev prijave.
setup-error-empty = Datoteka je prazna.
setup-error-too-large = Datoteka presega omejitev velikosti za prenos nastavitev programa Inbox Classic.
setup-error-not-setup = Ta datoteka ne vsebuje nastavitev programa Inbox Classic.
setup-error-damaged = Datoteka z nastavitvami je poškodovana in je ni mogoče prebrati.
setup-error-newer = Datoteko z nastavitvami je shranila novejša različica programa Inbox Classic ({ $version }). Posodobite program in datoteko znova uvozite.
setup-error-needs-passphrase = Datoteka z nastavitvami je zaščitena z zaščitnim geslom. Vnesite geslo, s katerim je bila shranjena.
setup-error-wrong-passphrase = To ni zaščitno geslo, s katerim je bila shranjena datoteka z nastavitvami.
setup-error-changed = Celovitosti datoteke z nastavitvami ni bilo mogoče potrditi. Morda je spremenjena ali poškodovana, zato je ni mogoče uvoziti.
setup-error-read = Datoteke z nastavitvami ni bilo mogoče prebrati: { $error }
setup-error-write = Datoteke z nastavitvami ni bilo mogoče shraniti: { $error }
setup-error-no-parts = Izberite vsaj eno kategorijo podatkov.
setup-left-out = { $count ->
    [one] { $count } vnos iz kategorije »{ $part }« ni uporaben, zato je izpuščen.
    [two] { $count } vnosa iz kategorije »{ $part }« nista uporabna, zato sta izpuščena.
    [few] { $count } vnosi iz kategorije »{ $part }« niso uporabni, zato so izpuščeni.
   *[other] { $count } vnosov iz kategorije »{ $part }« ni uporabnih, zato so izpuščeni.
}
setup-imported-settings = Nastavitve so bile zamenjane.
setup-imported-preferences = Nastavitve oken so bile zamenjane.
setup-added-accounts = { $count ->
    [one] Dodan je { $count } račun.
    [two] Dodana sta { $count } računa.
    [few] Dodani so { $count } računi.
   *[other] Dodanih je { $count } računov.
}
setup-skipped-here = Račun »{ $address }« je tukaj že nastavljen, zato je bil preskočen.
setup-skipped-no-app = Račun »{ $address }« je bil preskočen: uporablja aplikacijo za prijavo »{ $app }«, ki tukaj ni nastavljena.
setup-skipped-invalid = Račun »{ $address }« je bil preskočen: { $reason }
setup-asks-password = Ob povezovanju boste morali vnesti geslo za račun »{ $address }«.
setup-signs-in-again = Ob povezovanju se boste morali znova prijaviti v račun »{ $address }«.
setup-added-sign-in-apps = { $count ->
    [one] Dodana je { $count } aplikacija za prijavo.
    [two] Dodani sta { $count } aplikaciji za prijavo.
    [few] Dodane so { $count } aplikacije za prijavo.
   *[other] Dodanih je { $count } aplikacij za prijavo.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavo je tukaj že nastavljena.
    [two] { $count } aplikaciji za prijavo sta tukaj že nastavljeni.
    [few] { $count } aplikacije za prijavo so tukaj že nastavljene.
   *[other] { $count } aplikacij za prijavo je tukaj že nastavljenih.
}
setup-added-contacts = { $count ->
    [one] V imenik je dodan { $count } stik.
    [two] V imenik sta dodana { $count } stika.
    [few] V imenik so dodani { $count } stiki.
   *[other] V imenik je dodanih { $count } stikov.
}
setup-skipped-contacts = { $count ->
    [one] { $count } stik je že v imeniku.
    [two] { $count } stika sta že v imeniku.
    [few] { $count } stiki so že v imeniku.
   *[other] { $count } stikov je že v imeniku.
}
setup-added-groups = { $count ->
    [one] Dodana ali dopolnjena je { $count } skupina.
    [two] Dodani ali dopolnjeni sta { $count } skupini.
    [few] Dodane ali dopolnjene so { $count } skupine.
   *[other] Dodanih ali dopolnjenih je { $count } skupin.
}
setup-added-own-keys = { $count ->
    [one] Dodan je { $count } lastni ključ.
    [two] Dodana sta { $count } lastna ključa.
    [few] Dodani so { $count } lastni ključi.
   *[other] Dodanih je { $count } lastnih ključev.
}
setup-added-contact-keys = { $count ->
    [one] Dodan je { $count } ključ stika.
    [two] Dodana sta { $count } ključa stikov.
    [few] Dodani so { $count } ključi stikov.
   *[other] Dodanih je { $count } ključev stikov.
}
setup-added-rules = { $count ->
    [one] Dodano je { $count } pravilo za sporočila.
    [two] Dodani sta { $count } pravili za sporočila.
    [few] Dodana so { $count } pravila za sporočila.
   *[other] Dodanih je { $count } pravil za sporočila.
}
setup-skipped-rules = { $count ->
    [one] { $count } pravilo za sporočila je tukaj že.
    [two] { $count } pravili za sporočila sta tukaj že.
    [few] { $count } pravila za sporočila so tukaj že.
   *[other] { $count } pravil za sporočila je tukaj že.
}
setup-skipped-rules-account = { $count ->
    [one] { $count } pravilo za sporočila se nanaša na račun, ki ga tukaj ni, zato je bilo preskočeno.
    [two] { $count } pravili za sporočila se nanašata na račune, ki jih tukaj ni, zato sta bili preskočeni.
    [few] { $count } pravila za sporočila se nanašajo na račune, ki jih tukaj ni, zato so bila preskočena.
   *[other] { $count } pravil za sporočila se nanaša na račune, ki jih tukaj ni, zato so bila preskočena.
}
setup-rules-waiting = { $count ->
    [one] { $count } pravilo za sporočila čaka na prepoznavo ciljne mape po sinhronizaciji računa.
    [two] { $count } pravili za sporočila čakata na prepoznavo ciljnih map po sinhronizaciji računov.
    [few] { $count } pravila za sporočila čakajo na prepoznavo ciljnih map po sinhronizaciji računov.
   *[other] { $count } pravil za sporočila čaka na prepoznavo ciljnih map po sinhronizaciji računov.
}
setup-added-trusted-senders = { $count ->
    [one] Dodan je { $count } zaupanja vreden pošiljatelj.
    [two] Dodana sta { $count } zaupanja vredna pošiljatelja.
    [few] Dodani so { $count } zaupanja vredni pošiljatelji.
   *[other] Dodanih je { $count } zaupanja vrednih pošiljateljev.
}
setup-nothing = Nič ni bilo uvoženo.
setup-account-servers = { $imap } in { $smtp } ({ $signin })
setup-file-name = Nastavitve in računi Inbox Classic
setup-skipped-unreachable = Vnos »{ $name }« je bil preskočen: nastavitev storitve za prijavo ni bilo mogoče preveriti. V oknu Aplikacije za prijavo znova dodajte potrebno aplikacijo.
attachment-runs-programs = Datoteka »{ $name }« lahko zažene programe, zato je Inbox Classic ne odpre. Shranite jo in jo nato odprite sami, če zaupate njenemu izvoru.
attachment-decrypted-note = Ta priponka je iz šifriranega sporočila. Za odpiranje Inbox Classic shrani nešifrirano kopijo v začasno mapo vašega uporabniškega računa. Ob zagonu poskusi odstraniti kopije, starejše od enega dne.
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

preview-pdf-option = Prikaži datoteke PDF v sporočilih
preview-pdf-off = Datoteke PDF se v sporočilih ne prikazujejo.
preview-pdf-off-crashed = Predogled je bil prekinjen zaradi nepričakovanega zaprtja ali zastoja. Iz previdnosti so predogledi PDF izklopljeni, slike pa se še prikazujejo. Za ponovni prikaz datotek PDF vklopite možnost »{ $option }«. Mesto nastavitve: { $settings }.
preview-pdf-details = { $count ->
    [one] { $count } stran, { $size }
    [two] { $count } strani, { $size }
    [few] { $count } strani, { $size }
   *[other] { $count } strani, { $size }
}
preview-page-alt = { $name }, stran { $page } od { $count }
preview-more-pages = { $count ->
    [1] Odprite datoteko za ogled strani
   *[other] Odprite datoteko za ogled vseh strani ({ $count })
}
preview-more-files = { $count ->
    [one] Še { $count } datoteka je na seznamu zgoraj
    [two] Še { $count } datoteki sta na seznamu zgoraj
    [few] Še { $count } datoteke so na seznamu zgoraj
   *[other] Še { $count } datotek je na seznamu zgoraj
}
preview-tile-downloading = Prenašanje…
preview-tile-preparing = Pripravljanje…
preview-tile-format = Slike { $format } se še ne prikazujejo
preview-tile-password = Zaščiteno z geslom: odprite ga, da vnesete geslo
preview-tile-too-large = Presežena omejitev za predogled
preview-tile-unreadable = Ni mogoče prikazati
preview-tile-timed-out = Priprava predogleda je trajala predolgo
preview-tile-crashed = Prejšnji predogled je bil prekinjen ali je zastal
preview-tile-off = Ni prikazano, dokler se Inbox Classic znova ne zažene
preview-not-printed = Datoteka »{ $name }« ({ $details }) ni vključena v izpis. Za tiskanje jo odprite.
