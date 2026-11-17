# Norsk bokmål. Utkast, venter på gjennomgang av en person med norsk som morsmål (se core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Norwegian Bokmål: [one] and *[other].

## Counts and sizes

# review: new
messages = { $count ->
    [one] { $count } melding
   *[other] { $count } meldinger
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] { $count } byte
   *[other] { $count } byte
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Av
# review: new
send-delay-seconds = { $count ->
    [one] { $count } sekund
   *[other] { $count } sekunder
}
# the status bar: "12 meldinger, 3 uleste"
# review: new
list-counts = { $messages }, { $unread } uleste
# review: new
list-counts-selected = { $messages }, { $unread } uleste, { $selected } merket
# the status bar while searching: "12 funnet, 3 uleste"
# review: new
list-counts-found = { $found } funnet, { $unread } uleste
# review: new
list-counts-found-selected = { $found } funnet, { $unread } uleste, { $selected } merket
# review: new
list-counts-none = Fant ingen meldinger

## Special folders, as Outlook names them

# review: new
folder-inbox = Innboks
# review: new
folder-sent = Sendte elementer
# review: new
folder-deleted = Slettede elementer
# review: new
folder-drafts = Utkast
# review: new
folder-junk = Søppelpost
# review: new
folder-archive = Arkiv

## The reading pane

# review: new
reader-no-message = Ingen melding er valgt.
# review: new
reader-downloading = Laster ned meldingen…
# review: new
reader-downloading-detail = Meldingen vises her når nedlastingen er ferdig.
# review: new
reader-downloading-size = Meldingen er på { $size }. Den vises her når den er lastet ned.
# review: new
reader-failed = Meldingen kunne ikke lastes ned
# review: new
reader-failed-network = E-postserveren kunne ikke nås ({ $reason }).
# review: new
reader-failed-sign-in = E-postserveren godtok ikke påloggingen ({ $reason }). Kontroller passordet, eller logg på igjen under Fil > Kontoer.
# review: new
reader-failed-security = Tilkoblingen til e-postserveren kunne ikke gjøres sikker ({ $reason }).
# review: new
reader-failed-other = E-postserveren svarte: { $reason }.
# review: new
reader-retry-note = Det blir prøvd igjen når kontoen kobler til på nytt.
# review: new
reader-unreadable = Denne meldingen kan ikke vises: { $error }
# review: new
message-source-title = Meldingskilde: { $subject }
# review: new
message-source-untitled = Meldingskilde

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Fra
# review: new
header-date = Dato
# review: new
header-to = Til
# review: new
header-cc = Kopi
# review: new
header-sent = Sendt
# review: new
header-subject = Emne
# review: new
header-security = Sikkerhet
# review: new
header-part = Del { $number }
# review: new
quote-original = ----- Opprinnelig melding -----
# review: new
fold-show-earlier = Vis de tidligere meldingene

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Meldingen din ble ikke levert
# review: new
bounce-delayed = Meldingen din er ikke levert ennå
# review: new
bounce-delayed-note = E-postserveren din prøver fortsatt å levere den. Du trenger ikke å sende den på nytt.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Vis meldingen som kom i retur
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Vis den forsinkede meldingen
# review: new
bounce-what-to-do = Dette kan du gjøre:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Ingenting ennå. Hvis den fortsatt ikke kan leveres, får du et nytt varsel.
# review: new
bounce-delayed-row-do = Ingenting ennå. E-postserveren din prøver fortsatt å levere den, og du får et nytt varsel hvis det ikke lykkes.
# folds the receiving server's own words
# review: new
bounce-details = Detaljer
# a recipient the notice does not name
# review: new
bounce-someone = En mottaker
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Status: { $status }
# review: new
bounce-reported-by = Rapportert av: { $server }
# review: new
bounce-retry-minutes = Mottakerserveren ba om å vente { $count ->
    [one] ett minutt
   *[other] { $count } minutter
} før neste forsøk.
# review: new
bounce-retry-hours = Mottakerserveren ba om å vente { $count ->
    [one] én time
   *[other] { $count } timer
} før neste forsøk.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Blokkeringsliste: { $lists }
# review: new
bounce-user-unknown = Adressen finnes ikke
# review: new
bounce-user-unknown-why = Mottakerserveren har ingen postkasse med denne adressen. Den kan være feilskrevet, eller personen kan ha sluttet å bruke den.
# review: new
bounce-user-unknown-do = Kontroller stavemåten av adressen, eller spør personen hvilken adresse de bruker nå.
# review: new
bounce-invalid-address = Adressen er ikke gyldig
# review: new
bounce-invalid-address-why = Adressen er ikke skrevet på en form som e-post kan sendes til.
# review: new
bounce-invalid-address-do = Se etter skrivefeil, for eksempel et mellomrom, en manglende bokstav eller ingenting etter @.
# review: new
bounce-mailbox-disabled = Postkassen er stengt
# review: new
bounce-mailbox-disabled-why = Adressen finnes, men postkassen er slått av eller brukes ikke lenger.
# review: new
bounce-mailbox-disabled-do = Kontakt personen på en annen måte, og spør etter en adresse de bruker nå.
# review: new
bounce-mailbox-full = Postkassen er full
# review: new
bounce-mailbox-full-why = Mottakerens postkasse har ikke plass til ny e-post.
# review: new
bounce-mailbox-full-do = Send den på nytt om noen dager, eller gi personen beskjed på en annen måte. Store vedlegg blir avvist først.
# review: new
bounce-spam-blocked = Avvist som spam
# review: new
bounce-spam-blocked-why = Mottakerserveren oppfattet meldingen som spam.
# review: new
bounce-spam-blocked-do = Send den på nytt uten det som ligner spam, for eksempel mange lenker, forkortede lenker eller et stort vedlegg. Hvis det skjer igjen, spør e-postleverandøren din.
# review: new
bounce-virus-detected = Avvist på grunn av virus
# review: new
bounce-virus-detected-why = Mottakerserveren fant et virus eller annet skadelig innhold i meldingen eller vedleggene.
# review: new
bounce-virus-detected-do = Kontroller vedleggene med et antivirusprogram. Noen servere avviser alle programmer og arkiver, så del slike filer som en lenke i stedet.
# review: new
bounce-ip-blocklisted = E-postserveren din står på en blokkeringsliste
# review: new
bounce-ip-blocklisted-why = Mottakerserveren avviser e-post fra serveren som sendte din, fordi adressen til den serveren står på en blokkeringsliste.
# review: new
bounce-ip-blocklisted-do = Det er ikke meldingen som er problemet. Videresend dette varselet til e-postleverandøren din, og be dem få serveren fjernet fra listen.
# review: new
bounce-domain-blocklisted = Et domene står på en blokkeringsliste
# review: new
bounce-domain-blocklisted-why = Mottakerserveren avviser meldingen fordi domenet i adressen din, eller et domene i lenkene i meldingen, står på en blokkeringsliste.
# review: new
bounce-domain-blocklisted-do = Hvis meldingen har lenker, prøv uten dem. Ellers videresender du dette varselet til den som drifter e-posten for domenet ditt.
# review: new
bounce-policy-blocked = Avvist av mottakerserverens regler
# review: new
bounce-policy-blocked-why = Reglene på mottakerserveren slipper ikke gjennom denne meldingen, for eksempel på grunn av størrelsen, vedleggene eller hvem som sendte den.
# review: new
bounce-policy-blocked-do = Serverens egne ord under Detaljer forteller ofte årsaken. Spør mottakeren om de kan ta imot slik e-post.
# review: new
bounce-geo-blocked = Avvist på grunn av hvor den kom fra
# review: new
bounce-geo-blocked-why = Mottakerserveren tar ikke imot e-post fra landet eller nettverket e-postserveren din er i.
# review: new
bounce-geo-blocked-do = Kontakt personen på en annen måte, eller spør e-postleverandøren din om det.
# review: new
bounce-relay-denied = Serveren ville ikke sende den videre
# review: new
bounce-relay-denied-why = En server nektet å levere meldingen videre, ofte fordi den ble sendt uten pålogging eller gjennom en server som ikke håndterer denne mottakeren.
# review: new
bounce-relay-denied-do = Kontroller kontoens server for utgående e-post under Fil > Kontoer, og at den logger på.
# review: new
bounce-auth-failure = Avsenderadressen din kunne ikke bekreftes
# review: new
bounce-auth-failure-why = Mottakerserveren kunne ikke bekrefte at meldingen virkelig kom fra domenet ditt (SPF, DKIM eller DMARC).
# review: new
bounce-auth-failure-do = Videresend dette varselet til den som drifter e-posten for domenet ditt: innstillingene må rettes. I mellomtiden kan det hjelpe å sende gjennom leverandørens egen server.
# review: new
bounce-rate-limited = For mye e-post på en gang
# review: new
bounce-rate-limited-why = Mottakerserveren tar imot færre meldinger fra e-postserveren din inntil videre.
# review: new
bounce-rate-limited-do = Vent en stund, og send den på nytt. Når du skriver til mange, send til færre om gangen.
# review: new
bounce-greylisting = Holdt tilbake en liten stund
# review: new
bounce-greylisting-why = Mottakerserveren ber ukjente avsendere prøve igjen litt senere, en vanlig kontroll mot spam.
# review: new
bounce-greylisting-do = Ingenting. E-postservere prøver igjen av seg selv, og meldingen blir vanligvis levert innen en time.
# review: new
bounce-server-error = Mottakerserveren hadde et problem
# review: new
bounce-server-error-why = Fikk ikke kontakt med mottakerserveren, eller den kunne ikke ta imot meldingen på grunn av et eget problem.
# review: new
bounce-server-error-do = Send den på nytt senere. Hvis det fortsatt mislykkes, se etter skrivefeil i delen av adressen etter @.
# review: new
bounce-unknown = Ikke levert
# review: new
bounce-unknown-why = Varselet sier ikke tydelig hvorfor.
# review: new
bounce-unknown-do = Serverens egne ord under Detaljer kan si mer. Hvis de ikke hjelper, videresend dette varselet til e-postleverandøren din.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } melding merket
   *[other] { $count } meldinger merket
}
# review: new
selection-unread = { $count } uleste
# review: new
selection-flagged = { $count } med flagg
# review: new
delete-for-good-one = Denne meldingen blir slettet permanent. Vil du slette den?
# review: new
delete-for-good-all = Disse { $count } meldingene blir slettet permanent. Vil du slette dem?
# review: new
delete-for-good-some = { $count } av de { $total } meldingene blir slettet permanent. Vil du slette meldingene?
# review: new
done-read = { $count ->
   *[other] Merket { $messages } som lest
}
# review: new
done-unread = { $count ->
   *[other] Merket { $messages } som ulest
}
# review: new
done-flagged = { $count ->
   *[other] Satte flagg på { $messages }
}
# review: new
done-unflagged = Fjernet flagget fra { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Slettet { $messages } permanent
}
# review: new
done-archived = { $count ->
   *[other] Arkiverte { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Flyttet { $messages } til { $folder }
}
# review: new
done-copied = { $count ->
   *[other] Kopierte { $messages } til { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Flytter { $messages } til { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Kopierer { $messages } til { $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] Flyttet { $messages } tilbake til { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Følger samtalen
   *[other] Følger { $count } samtaler
}
# review: new
done-unwatched = { $count ->
    [one] Sluttet å følge samtalen
   *[other] Sluttet å følge { $count } samtaler
}
# review: new
done-ignored = { $count ->
    [one] Ignorerer samtalen
   *[other] Ignorerer { $count } samtaler
}
# review: new
done-unignored = { $count ->
    [one] Sluttet å ignorere samtalen
   *[other] Sluttet å ignorere { $count } samtaler
}
# review: new
their-folders = de opprinnelige mappene
# review: new
undo-move = Angre flytting
# review: new
undo-delete = Angre sletting
# review: new
undo-archive = Angre arkivering
# review: new
undo-junk = Angre Merk som søppelpost
# review: new
undo-not-junk = Angre Merk som ikke søppelpost
# review: new
undo-send = Angre sending
# review: new
nothing-to-undo = Det er ingenting å angre.
# review: new
messages-gone = Meldingene finnes ikke lenger.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Denne mappen kan ikke inneholde meldinger.
# review: new
not-archived-here = Meldinger i denne mappen kan ikke arkiveres.
# review: new
not-emptied-here = Bare Slettede elementer og Søppelpost kan tømmes.
# review: new
next-unread-question = Det er ingen flere uleste meldinger i { $folder }.

    Vil du gå til { $next }, den neste mappen med uleste meldinger?
# review: new
no-unread-left = Det er ingen uleste meldinger igjen.
# review: new
empty-question = { $count ->
    [one] Vil du tømme { $folder }?

        Meldingen i mappen blir slettet permanent. Den kan ikke hentes tilbake.
   *[other] Vil du tømme { $folder }?

        De { $messages } i mappen blir slettet permanent. De kan ikke hentes tilbake.
}
# review: new
no-junk-folder = Denne kontoen har ingen søppelpostmappe å flytte meldingene til.
# review: new
no-inbox-folder = Denne kontoen har ingen innboks å flytte meldingene til.
# the status bar after a flag in a colour: "Satte blått flagg på 2 meldinger"
# review: new
done-flagged-color = Satte { $color ->
    [red] rødt
    [orange] oransje
    [yellow] gult
    [green] grønt
    [blue] blått
    [purple] lilla
   *[gray] grått
   } flagg på { $messages }
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Rød
    [orange] Oransje
    [yellow] Gul
    [green] Grønn
    [blue] Blå
    [purple] Lilla
   *[gray] Grå
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [one] Flytt melding
   *[other] Flytt { $count } meldinger
}
# review: new
move-window-title-copy = { $count ->
    [one] Kopier melding
   *[other] Kopier { $count } meldinger
}
# review: new
move-window-prompt-move = { $count ->
    [one] Flytt den merkede meldingen til:
   *[other] Flytt de { $count } merkede meldingene til:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Kopier den merkede meldingen til:
   *[other] Kopier de { $count } merkede meldingene til:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Nylig brukt
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (gjeldende)
# a folder used last, with its account when there are several: "Arkiv (Jobb)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Flytter { $done } av { $messages } til { $folder }...
# review: new
transfer-copying = Kopierer { $done } av { $messages } til { $folder }...
# review: new
transfer-another-account = en annen konto
# review: new
transfer-folder-gone = mappen den skulle til, finnes ikke lenger
# review: new
transfer-not-on-server = meldingen finnes ikke lenger på serveren
# review: new
transfer-not-moved = { $count ->
   *[other] { $messages } kunne ikke flyttes til en annen konto: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] { $messages } kunne ikke kopieres til en annen konto: { $reason }
}
# review: new
transfer-none-moved = Ingen meldinger kunne flyttes
# review: new
transfer-none-copied = Ingen meldinger kunne kopieres

## Messages as files

# review: new
export-not-in-time = meldingen kunne ikke lastes ned i tide
# review: new
export-not-saved = { $failed } av { $messages } kunne ikke lagres ({ $problems })
# review: new
export-not-attached = meldingene kunne ikke legges ved: { $error }
# the status bar after Save As with several: "Lagret 3 meldinger i Skrivebord"
# review: new
saved-to = { $count ->
   *[other] Lagret { $messages } i { $folder }
}
# review: new
download-progress = Laster ned { $done } av { $total }
# review: new
download-done = Lastet ned { $size }
# review: new
downloading-messages = { $count ->
   *[other] Laster ned { $messages }...
}
# the status bar after files are dropped on a folder: "La 3 meldinger i Arkiv"
# review: new
import-put = { $count ->
   *[other] La { $messages } i { $folder }
}
# review: new
import-not-put = Disse ble ikke lagt i mappen:

    { $problems }

## Problems the windows show

# review: new
error-store = lokalt lager: { $error }
# review: new
error-not-found = ikke funnet
# review: new
error-closed = avslutter
# review: new
error-other-account = nettleseren logget på { $email }, ikke på denne kontoen
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = serveren godtok ikke påloggingen ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = tilkoblingen til serveren mislyktes ({ $reason })
# review: new
error-in-use = den kan ikke fjernes mens kontoer logger på med den: { $accounts }
# review: new
error-turned-off = denne påloggingsappen er slått av for nye kontoer
# review: new
error-folder-name = mappenavnet må være 1 til 200 tegn langt og kan ikke inneholde kontrolltegn
# review: new
error-folder-separator = et mappenavn kan ikke inneholde «{ $separator }» på denne serveren
# review: new
error-folder-special = innboksen og spesialmappene kan ikke gis nytt navn eller slettes
# review: new
error-no-recipients = meldingen har ingen mottakere
# review: new
error-bad-address = «{ $address }» er ikke en e-postadresse
# review: new
error-not-own-address = { $address } er ikke en av avsenderadressene til denne kontoen. Legg den til i «Andre adresser du sender fra» i kontoens egenskaper.
# review: new
rule-query-refused = Regler kan ikke filtrere på mappe eller dato ({ $words }).
# review: new
rule-no-query = Skriv inn søkekriterier for innkommende meldinger.
# review: new
rule-no-action = Velg minst én handling for regelen.
# review: new
error-attachment = { $path } kunne ikke leses: { $error }
# review: new
error-no-drafts = kontoen har ingen Utkast-mappe å lagre meldingen i
# review: new
error-draft-attachment = et vedlegg i utkastet kunne ikke beholdes: { $error }
# review: new
error-password-not-saved = passordet kunne ikke lagres til neste oppstart: { $error }
# review: new
error-sign-in-not-saved = de nye påloggingsopplysningene kunne ikke lagres til neste oppstart: { $error }
# review: new
error-import-unreadable = { $path } kan ikke leses: { $error }
# review: new
error-import-too-large = { $path } er større enn 50 MB
# review: new
error-import-not-mail = { $path } er ikke en e-postmelding
# review: new
error-list-answered = serveren for e-postlisten svarte med status { $status }
# review: new
error-not-built = meldingen kunne ikke lages
# review: new
error-outbox-waits = { $count ->
    [one] meldingen venter i Utboks og blir sendt ved neste Send/motta
   *[other] { $count } meldinger venter i Utboks og blir sendt ved neste Send/motta
}
# review: new
error-draft-not-removed = det tidligere utkastet av meldingen kunne ikke fjernes fra Utkast: { $reason }
# review: new
error-sent-but = meldingen ble sendt, men { $problem }
# review: new
error-sent-still-in-outbox = den ligger fortsatt i Utboks: { $error }
# review: new
error-sent-no-copy = ingen kopi kunne lagres i Sendte elementer: { $reason }
# review: new
error-no-password = ikke noe passord for denne kontoen
# review: new
error-no-sign-in = ingen pålogging for denne kontoen
# review: new
error-provider-missing = denne versjonen kan ikke logge på { $provider }: er påloggingsappen fjernet?
# review: new
error-provider-servers = serverne til denne kontoen samsvarer ikke med serverne til påloggingsappen
# review: new
error-app-scopes = { $reason }. E-postserveren godtok ikke tokenet fra påloggingsappen: kontroller at appens tillatelser gir tilgang til e-post
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google har ikke bekreftet Inbox Classic ennå, så bare testbrukere kan logge på med den. Bruk din egen påloggingsapp for Google eller et app-passord, eller slå den på under Påloggingsapper (Fil > Kontoer) hvis du er testbruker.
# review: new
sign-in-off-other = Den ble slått av under Påloggingsapper (Fil > Kontoer), der den kan slås på igjen.
# review: new
sign-in-app-no-name = påloggingsappen må ha et navn
# review: new
sign-in-app-no-client = klient-ID mangler
# review: new
sign-in-app-no-scopes = påloggingsappen trenger tillatelsene som gir tilgang til e-post
# review: new
sign-in-app-bad-host = { $server }-serveradressen mangler eller er ikke et gyldig vertsnavn
# review: new
sign-in-app-plain = { $server }-serveren må bruke SSL/TLS eller STARTTLS
# review: new
sign-in-app-not-checked = utstederen er ikke kontrollert ennå
# review: new
sign-in-app-issuer-changed = utstederen er endret: skriv inn klienthemmeligheten på nytt, eller fjern den
# review: new
sign-in-register-google = Opprett en OAuth-klient av typen Desktop app i Google Cloud Console, med tillatelsen https://mail.google.com/ på samtykkeskjermen. Mens appen er i testmodus, kan bare testbrukerne logge på.
# review: new
sign-in-register-microsoft = Registrer en app i Microsoft Entra med plattformen Mobile and desktop applications, omdirigerings-URI-en http://localhost, offentlige klientflyter tillatt og de delegerte tillatelsene IMAP.AccessAsUser.All, SMTP.Send og offline_access. Bare for din organisasjon bruker du https://login.microsoftonline.com/<tenant ID>/v2.0 som utsteder.
# review: new
sign-in-register-other = Registrer en innebygd (offentlig) klient med omdirigerings-URI-en nedenfor; leverandøren må tillate hvilken som helst port på den (RFC 8252). Legg til tillatelsen som leverandøren gir tilgang til e-post med.

## Calendar invitations

# review: new
repeats = Gjentas
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Hver dag
       *[other] Hver { $interval }. dag
    }
    [week] { $interval ->
        [one] Hver uke
       *[other] Hver { $interval }. uke
    }
    [month] { $interval ->
        [one] Hver måned
       *[other] Hver { $interval }. måned
    }
   *[year] { $interval ->
        [one] Hvert år
       *[other] Hvert { $interval }. år
    }
}
# "Hver uke på mandag, onsdag"
# review: new
repeats-on = { $repeats } på { $days }
# "Hver uke, 10 ganger"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, én gang
   *[other] { $repeats }, { $count } ganger
}
# review: new
day-monday = mandag
# review: new
day-tuesday = tirsdag
# review: new
day-wednesday = onsdag
# review: new
day-thursday = torsdag
# review: new
day-friday = fredag
# review: new
day-saturday = lørdag
# review: new
day-sunday = søndag

## AI agents

# review: new
agent-level-read = Lese e-post: mapper, meldingslisten, søk og meldinger
# review: new
agent-level-organize = Organisere e-post: lest-status, flagg, søppelpost, flytting, sletting til Slettede elementer
# review: new
agent-level-drafts = Skrive utkast som du sender selv
# review: new
agent-level-send = Sende e-post, hver melding først etter at du har sagt ja
# review: new
agent-connect-title = { $program } vil bruke e-posten din
# review: new
agent-connect-detail = En KI-agent ba om å få arbeide med Inbox Classic. Velg hva den kan gjøre og hvilke kontoer den kan se; du kan endre dette senere under Verktøy > KI-agenter.

    Agenter leser e-post som andre har skrevet, og en melding kan prøve å lure dem. Inbox Classic spør deg alltid før en agent sender noe.
# review: new
agent-reply-to = Svar på «{ $subject }»
# review: new
agent-reply-all-on = Svar alle på «{ $subject }»
# review: new
agent-forward-of = Videresending av «{ $subject }»
# review: new
agent-never-written-one = Du har aldri skrevet til { $address }.
# review: new
agent-never-written-many = Du har aldri skrevet til { $count } av disse adressene.
# review: new
agent-send-title = { $program } vil sende denne meldingen
# review: new
agent-send-detail = Kontroller mottakerne og innholdet i meldingen. Når du bekrefter, venter meldingen { $seconds } sekunder i Utboks, der du fortsatt kan slette den.
# review: new
agent-change-title = Hva { $program } kan gjøre
# review: new
agent-change-allowed = Endre hva KI-agentene til dette programmet kan gjøre med e-posten din.
# review: new
agent-change-refused = Du nektet dette programmet tilgang. Tillat det for å gi agentene tilgang til e-posten din igjen.
# review: new
agent-log-taken-back = { $entry } (angret)
# review: new
agent-files = Filer: { $files }
# review: new
agent-undo-refused = Det kan ikke angres.
# review: new
agent-undo-refused-why = Det kan ikke angres: { $reason }.
# review: new
agent-undo-impossible = dette kan ikke angres
# review: new
agent-undo-not-in-folder = meldingen ligger ikke lenger i den mappen
# review: new
agent-undo-not-arrived = meldingen ligger ikke (ennå) i mappen den ble flyttet til
# review: new
agent-undo-sent = meldingen er allerede sendt
# review: new
agent-original-not-downloaded = den opprinnelige meldingen er ikke lastet ned ennå. Åpne den først
# review: new
agent-turned-away = Avvist
# review: new
agent-can-nothing = Ingenting
# review: new
agent-can-read = lese
# review: new
agent-can-organize = organisere
# review: new
agent-can-drafts = skrive utkast
# review: new
agent-can-send = sende med ditt ja
# "Lese, organisere og skrive utkast"
# review: new
agent-can-list = { $first } og { $last }
# review: new
agent-accounts = { $count ->
    [0] ingen kontoer
    [one] { $count } konto
   *[other] { $count } kontoer
}
# "Lese og organisere; 1 konto"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Denne meldingen kan ikke leses.
# review: new
agent-encrypted-original = Denne meldingen er kryptert: en agent kan ikke svare på den eller videresende den, siden den ikke kan kryptere.
# review: new
agent-encrypted = Denne meldingen er kryptert. Bare brukeren kan lese den, i Inbox Classic.
# review: new
list-encrypted = Kryptert melding
# review: new
agent-log-composed = Åpnet «{ $subject }» i en ny melding som du kan gjøre ferdig
# review: new
agent-log-refused = Du sendte ikke «{ $subject }»
# review: new
agent-log-sent = Sendte «{ $subject }» til { $to }
# review: new
agent-log-draft = Lagret utkastet «{ $subject }»
# review: new
agent-log-read = Merket «{ $subject }» som lest
# review: new
agent-log-unread = Merket «{ $subject }» som ulest
# review: new
agent-log-flagged = Satte flagg på «{ $subject }»
# review: new
agent-log-unflagged = Fjernet flagget fra «{ $subject }»
# review: new
agent-log-deleted = Slettet «{ $subject }»
# review: new
agent-log-moved = Flyttet «{ $subject }» til { $folder }
# review: new
agent-log-junk = Merket «{ $subject }» som søppelpost
# review: new
agent-log-not-junk = Merket «{ $subject }» som ikke søppelpost
# review: new
agent-log-archived = Arkiverte «{ $subject }»
# review: new
agent-log-folder = Opprettet mappen «{ $name }»
# review: new
agent-log-unsubscribed = Meldte av listen til «{ $subject }»

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Skift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = leverandøren ga ikke noe oppdateringstoken
# review: new
sign-in-no-account = leverandøren oppga ikke hvilken konto som logget på
# review: new
sign-in-not-finished = påloggingen er ikke fullført
# review: new
secrets-unavailable = { $store } er ikke tilgjengelig
# review: new
secrets-unavailable-why = { $store } er ikke tilgjengelig: { $error }
# review: new
secrets-windows = Legitimasjonsbehandling
# review: new
secrets-mac = nøkkelringen
# review: new
secrets-linux = systemets nøkkelring (Secret Service)
# review: new
error-no-such-file = filen finnes ikke
# review: new
cards-file-too-big = Denne filen er for stor til å være en adressebok.
# review: new
ui-sender-added = { $name } ble lagt til i adresseboken.
# review: new
ui-sender-known = { $name } er allerede i adresseboken.
# review: new
ui-sender-none = Avsenderen av denne meldingen har ingen e-postadresse som kan legges til.
# review: new
card-name-needed = Kontakten har verken navn eller e-postadresse.
# a file of Import Address Book that could not be read: "kontakter.vcf: filen finnes ikke"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Kode fra { $domain }
# review: new
otp-copy = Kopier
# review: new
otp-note = Skriv den bare inn på en side som tilhører { $domain }.
# review: new
otp-old = Denne koden ble sendt mer enn en time før du åpnet den, og har sannsynligvis utløpt.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } deltaker
       *[other] { $count } deltakere
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } er koden din for { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Gyldig
# review: new
pgp-key-expires = Gyldig til { $date }
# review: new
pgp-key-expired = Utløpt { $date }
# review: new
pgp-key-revoked = Tilbakekalt
# review: new
pgp-key-revoked-why = Tilbakekalt: { $reason }
# review: new
pgp-key-not-valid = Ikke gyldig
# review: new
pgp-key-locked = Kan ikke brukes: nøkkelen som beskytter den, finnes ikke lenger i { $store }. Importer sikkerhetskopien på nytt.
# review: new
pgp-source-own = Laget i Inbox Classic
# review: new
pgp-source-file = Importert fra en fil
# review: new
pgp-source-paste = Limt inn
# review: new
pgp-source-attachment = Fra en melding
# review: new
pgp-source-vcard = Fra et kontaktkort
# review: new
pgp-source-wkd = Fra avsenderens e-postleverandør
# review: new
pgp-source-keyserver = Fra keys.openpgp.org
# review: new
pgp-source-autocrypt = Fra Autocrypt-hodet i en melding
# review: new
pgp-error-no-store = Private nøkler beskyttes av { $store }, som ikke kan brukes: { $error }
# review: new
pgp-error-wrong-passphrase = Passfrasen er feil.
# review: new
pgp-error-not-a-key = Dette er ikke en OpenPGP-nøkkel.
# review: new
pgp-error-too-large = Nøkkelen er for stor.
# review: new
pgp-error-unusable = Nøkkelen bruker gammel eller svak kryptografi og kan ikke brukes.
# review: new
pgp-imported-private = { $count ->
    [one] Den private nøkkelen din ble importert.
   *[other] { $count } private nøkler ble importert.
}
# review: new
pgp-imported-public = { $count ->
    [one] Én nøkkel ble importert.
   *[other] { $count } nøkler ble importert.
}
# review: new
pgp-imported-pending = En annen nøkkel brukes allerede for { $addresses }: den nye venter i kontakten til du velger den.
# review: new
pgp-error-needs-passphrase = Den private nøkkelen er beskyttet med en passfrase. Skriv den inn for å importere nøkkelen.
# review: new
pgp-error-mismatch = Den private nøkkelen hører ikke til den offentlige nøkkelen. Den kan ha blitt endret.
# review: new
pgp-file-name-public = { $who } offentlig nøkkel.asc
# review: new
pgp-file-name-private = { $who } sikkerhetskopi av privat nøkkel.asc
# review: new
pgp-pending = En annen nøkkel for { $address } ble funnet { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Signert av { $signer }, nøkkelen er bekreftet
# review: new
pgp-part-signed = Signert av { $signer } (nøkkelen er ikke bekreftet)
# review: new
pgp-part-other = Signert av { $signer }, som ikke er avsenderen
# review: new
pgp-part-unknown-key = Signert, men nøkkelen er ukjent
# review: new
pgp-part-not-signed = Ikke signert
# review: new
pgp-part-not-checked = Signaturen er ikke kontrollert
# review: new
pgp-part-encrypted = Kryptert. { $signature }
# review: new
pgp-part-no-key = Kryptert til en nøkkel du ikke har
# review: new
pgp-part-changed = Den krypterte delen ble endret underveis og vises ikke
# review: new
pgp-part-unprotected = Kryptert uten beskyttelse mot endringer, vises ikke
# review: new
pgp-part-broken = Den krypterte delen kan ikke leses
# review: new
pgp-why-mismatch = Signaturen samsvarer ikke med denne teksten
# review: new
pgp-why-weak-hash = Signaturen bruker { $hash }, som ikke lenger er trygg
# review: new
pgp-why-key-expired = Signert etter at nøkkelen utløp { $date }
# review: new
pgp-why-key-revoked = Signert med en nøkkel som er tilbakekalt
# review: new
pgp-why-not-signing-key = Signert med en nøkkel som ikke kan signere
# review: new
pgp-why-from-future = Signaturen er datert fram i tid
# review: new
pgp-why-signature-expired = Signaturen har utløpt
# review: new
pgp-why-key-not-valid = Signert med en nøkkel som ikke er gyldig
# review: new
pgp-why-not-for-you = Signert for andre mottakere og videresendt til deg
# review: new
pgp-why-not-key-in-use = Signert med en annen nøkkel enn den som brukes for { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Bilder ble lastet fra internett
# review: new
pgp-error-no-own-key = Du har ingen nøkkel for { $address } å signere eller kryptere med. Lag en under Verktøy > Krypteringsnøkler, eller slå av Signer og Krypter.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } har ingen nøkkel å kryptere til.
   *[other] Disse mottakerne har ingen nøkkel å kryptere til: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Denne meldingen siterer eller videresender en kryptert melding, så den kan bare sendes kryptert. Slå på Krypter, eller fjern den siterte teksten.
# review: new
pgp-error-protect = Meldingen kunne ikke signeres eller krypteres: { $reason }
# review: new
pgp-found-keys = Fant nøkkelen til { $addresses }.
# review: new
pgp-found-none = Fant ingen nøkkel for { $addresses }. Be dem sende deg den offentlige nøkkelen sin.
# review: new
pgp-found-no-key = Fant ingen nøkkel.
# review: new
pgp-find-unavailable = Kunne ikke slå opp nøkler nå: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org sendte en bekreftelseslenke til { $addresses }. Nøkkelen din blir publisert der når du klikker på den.
# review: new
pgp-publish-done = Nøkkelen din er publisert på keys.openpgp.org for { $addresses }.
# review: new
pgp-publish-failed = Nøkkelen kunne ikke publiseres: { $error }
# review: changed
pgp-keyserver-off = Søk etter nøkler på keys.openpgp.org er slått av under { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Kryptert og signert: bare du og { $addresses } kan lese den.
   *[other] Kryptert og signert: bare du og de { $count } mottakerne kan lese den.
}
# review: new
pgp-compose-encrypt-ready = Den blir kryptert og signert. Legg til mottakere du har nøklene til.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } har ingen nøkkel, så meldingen kan ikke krypteres ennå.
   *[other] { $count } mottakere har ingen nøkkel, så meldingen kan ikke krypteres ennå: { $addresses }.
}
# review: new
pgp-compose-looking = Ser etter nøklene til { $addresses }...
# review: new
pgp-compose-signed = Signert: mottakerne kan kontrollere at den kommer fra deg og ikke er endret.
# review: new
pgp-compose-reply-clear = Ikke kryptert, selv om meldingen den svarer på eller videresender, var det.
# review: new
pgp-compose-encrypted-files = Filer fra en kryptert melding er lagt ved, så denne meldingen kan bare sendes kryptert. Slå på Krypter, eller fjern de filene.
# review: new
pgp-compose-sign-tip = Signer meldingen med nøkkelen din, så mottakerne kan kontrollere at den kommer fra deg og ikke er endret
# review: new
pgp-compose-sign-tip-encrypted = En kryptert melding blir alltid signert
# review: new
pgp-compose-encrypt-tip = Krypter meldingen, så bare du og mottakerne kan lese den
# review: new
pgp-compose-make-key = Du har ingen nøkkel for { $address } ennå. Vil du lage en nå? Med den kan meldingene dine signeres og krypteres.
# review: new
pgp-compose-key-unusable = Nøkkelen din for { $address } kan ikke brukes ({ $state }). Åpne Krypteringsnøkler for å importere sikkerhetskopien eller lage en ny nøkkel.
# review: new
pgp-compose-encrypt-off-quote = Denne meldingen siterer eller videresender en kryptert melding. Uten kryptering kan den ikke sendes før du fjerner det den siterer. Vil du slå av kryptering likevel?
# review: new
pgp-compose-encrypt-off-reply = Denne meldingen svarer på eller videresender en kryptert melding. Uten kryptering kan alle som håndterer meldingen din underveis, lese den. Vil du slå av kryptering?
# review: new
pgp-recipient-verified = Nøkkelen er bekreftet
# review: new
pgp-recipient-found = Nøkkelen er ikke bekreftet
# review: new
pgp-recipient-own = Din egen nøkkel
# review: new
pgp-recipient-looking = Ser etter en nøkkel...
# review: new
pgp-recipient-missing = Ingen nøkkel
# review: new
pgp-recipient-not-found = Ingen nøkkel: ingen ble funnet { $date }
# review: new
pgp-recipient-unusable = Nøkkelen kan ikke brukes: { $state }
# review: new
pgp-recipients-intro = Meldingen krypteres til nøkkelen til hver mottaker, og til din.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Én mottaker har ingen nøkkel å kryptere til. Finn nøkkelen, fjern mottakeren fra denne meldingen, eller send den uten kryptering.
   *[other] { $count } mottakere har ingen nøkkel å kryptere til. Finn nøklene deres, fjern dem fra denne meldingen, eller send den uten kryptering.
}
# review: new
pgp-details-part = Del { $number }: { $label }
# review: new
pgp-details-signed = Signert { $when } med nøkkelen { $key }
# review: new
pgp-details-unknown-key = Signert med nøkkelen { $key }, som du ikke har
# review: new
pgp-details-opened = Kryptert til nøkkelen din { $key }
# review: new
pgp-details-for = Kryptert til { $keys }
# review: new
pgp-details-plain = Ikke signert og ikke kryptert
# review: new
pgp-bar-parts = Denne meldingen har { $count } deler: { $list }. Hver del viser hvordan den er beskyttet.
# review: new
pgp-bar-count-verified = { $count } bekreftet
# review: new
pgp-bar-count-good = { $count ->
    [one] { $count } signert eller kryptert
   *[other] { $count } signert eller kryptert
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] { $count } trenger oppmerksomhet
   *[other] { $count } trenger oppmerksomhet
}
# review: new
pgp-bar-count-neutral = { $count } uten bekreftet signatur
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Innstillinger
# review: new
setup-part-preferences = Vindusinnstillinger
# review: new
setup-part-accounts = Kontoer
# review: new
setup-part-sign-in-apps = Påloggingsapper
# review: new
setup-part-contacts = Kontakter og grupper
# review: new
setup-part-keys = Krypteringsnøkler
# review: new
setup-part-rules = Meldingsregler
# review: new
setup-part-trusted-senders = Klarerte avsendere
# review: new
setup-holds-settings = { $count ->
    [one] { $count } innstilling
   *[other] { $count } innstillinger
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } vindusinnstilling
   *[other] { $count } vindusinnstillinger
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } konto
   *[other] { $count } kontoer
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } påloggingsapp
   *[other] { $count } påloggingsapper
}
# review: new
setup-holds-built-in = Hvilke innebygde påloggingsapper som er slått på
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } kontakt
   *[other] { $count } kontakter
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } gruppe
   *[other] { $count } grupper
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } egen nøkkel
   *[other] { $count } egne nøkler
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } nøkkel til en kontakt
   *[other] { $count } nøkler til kontakter
}
# review: new
setup-holds-rules = { $count ->
    [one] { $count } regel
   *[other] { $count } regler
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] { $count } klarert avsender
   *[other] { $count } klarerte avsendere
}
# review: new
setup-sign-in-password = Passord
# review: new
setup-account-secret-password = Passordet ligger i filen.
# review: new
setup-account-secret-token = Påloggingen ligger i filen.
# review: new
setup-account-asks-password = Den ber om passordet etter importen.
# review: new
setup-account-signs-in-again = Du logger på den igjen etter importen.
# review: new
setup-account-here = Den er allerede konfigurert her, så den hoppes over.
# review: new
setup-account-no-app = Den logger på med { $app }, som ikke er konfigurert her. Importer påloggingsappene også.
# review: new
setup-invalid-address = «{ $address }» er ikke en e-postadresse.
# review: new
setup-invalid-server = { $server }-serveren har ikke noe brukbart navn eller port.
# review: new
setup-invalid-user = Den har ikke noe brukernavn.
# review: new
setup-invalid-sign-in = Den logger på på en måte som Inbox Classic ikke kjenner.
# review: new
setup-error-empty = Filen er tom.
# review: new
setup-error-too-large = Filen er for stor til å være et Inbox Classic-oppsett.
# review: new
setup-error-not-setup = Denne filen er ikke et Inbox Classic-oppsett.
# review: new
setup-error-damaged = Oppsettfilen er skadet og kan ikke leses.
# review: new
setup-error-newer = Dette oppsettet ble lagret av en nyere Inbox Classic ({ $version }). Oppdater Inbox Classic, og importer det på nytt.
# review: new
setup-error-needs-passphrase = Dette oppsettet er beskyttet med en passfrase. Skriv inn passfrasen det ble lagret med.
# review: new
setup-error-wrong-passphrase = Det er ikke passfrasen dette oppsettet ble lagret med.
# review: new
setup-error-changed = Oppsettfilen ble endret eller skadet etter at den ble lagret, så den kan ikke importeres.
# review: new
setup-error-read = Oppsettfilen kunne ikke leses: { $error }
# review: new
setup-error-write = Oppsettet kunne ikke lagres: { $error }
# review: new
setup-error-no-parts = Velg minst én del.
# review: new
setup-left-out = { $count ->
    [one] { $count } oppføring i { $part } kan ikke brukes og er utelatt.
   *[other] { $count } oppføringer i { $part } kan ikke brukes og er utelatt.
}
# review: new
setup-imported-settings = Innstillingene ble erstattet.
# review: new
setup-imported-preferences = Vindusinnstillingene ble erstattet.
# review: new
setup-added-accounts = { $count ->
    [one] La til { $count } konto.
   *[other] La til { $count } kontoer.
}
# review: new
setup-skipped-here = { $address } er allerede konfigurert her, så den ble hoppet over.
# review: new
setup-skipped-no-app = { $address } ble hoppet over: den logger på med { $app }, som ikke er konfigurert her.
# review: new
setup-skipped-invalid = { $address } ble hoppet over: { $reason }
# review: new
setup-asks-password = { $address } ber om passordet når den kobler til.
# review: new
setup-signs-in-again = { $address } ber deg logge på igjen når den kobler til.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] La til { $count } påloggingsapp.
   *[other] La til { $count } påloggingsapper.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } påloggingsapp er allerede konfigurert her.
   *[other] { $count } påloggingsapper er allerede konfigurert her.
}
# review: new
setup-added-contacts = { $count ->
    [one] La til { $count } kontakt i adresseboken.
   *[other] La til { $count } kontakter i adresseboken.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } kontakt er allerede i adresseboken.
   *[other] { $count } kontakter er allerede i adresseboken.
}
# review: new
setup-added-groups = { $count ->
    [one] La til eller fullførte { $count } gruppe.
   *[other] La til eller fullførte { $count } grupper.
}
# review: new
setup-added-own-keys = { $count ->
    [one] La til { $count } egen nøkkel.
   *[other] La til { $count } egne nøkler.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] La til { $count } nøkkel til en kontakt.
   *[other] La til { $count } nøkler til kontakter.
}
# review: new
setup-added-rules = { $count ->
    [one] La til { $count } meldingsregel.
   *[other] La til { $count } meldingsregler.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } meldingsregel finnes allerede her.
   *[other] { $count } meldingsregler finnes allerede her.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } meldingsregel gjelder en konto som ikke finnes her, så den ble hoppet over.
   *[other] { $count } meldingsregler gjelder kontoer som ikke finnes her, så de ble hoppet over.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } meldingsregel flytter meldinger til en mappe som dukker opp når kontoen er synkronisert.
   *[other] { $count } meldingsregler flytter meldinger til mapper som dukker opp når kontoene er synkronisert.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] La til { $count } klarert avsender.
   *[other] La til { $count } klarerte avsendere.
}
# review: new
setup-nothing = Ingenting ble importert.
# review: new
setup-account-servers = { $imap } og { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic-innstillinger og kontoer
# review: new
setup-skipped-unreachable = { $name } ble hoppet over: påloggingstjenesten kunne ikke nås. Legg den til på nytt under Påloggingsapper.
# review: new
attachment-runs-programs = «{ $name }» kan kjøre programmer, så Inbox Classic åpner den ikke. Lagre den, og åpne den selv hvis du stoler på hvor den kommer fra.
# review: new
attachment-decrypted-note = Dette vedlegget kommer fra en kryptert melding. For å åpne det lagrer Inbox Classic det dekryptert på denne datamaskinen, i en av mappene dine som Inbox Classic tømmer etter et døgn.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Serveren flyttet ikke { $messages } til { $folder }, så den er tilbake i { $from }: { $reason }
   *[other] Serveren flyttet ikke { $messages } til { $folder }, så de er tilbake i { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Serveren slettet ikke { $messages }, så den er tilbake i { $from }: { $reason }
   *[other] Serveren slettet ikke { $messages }, så de er tilbake i { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Serveren arkiverte ikke { $messages }, så den er tilbake i { $from }: { $reason }
   *[other] Serveren arkiverte ikke { $messages }, så de er tilbake i { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Serveren merket ikke { $messages } som lest, så den er ulest igjen: { $reason }
   *[other] Serveren merket ikke { $messages } som lest, så de er uleste igjen: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Serveren merket ikke { $messages } som ulest, så den er lest igjen: { $reason }
   *[other] Serveren merket ikke { $messages } som ulest, så de er lest igjen: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Serveren endret ikke flaggene på { $messages }, så den er som før: { $reason }
   *[other] Serveren endret ikke flaggene på { $messages }, så de er som før: { $reason }
}
