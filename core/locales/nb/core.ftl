# Norsk bokmål. Utkast, venter på gjennomgang av en person med norsk som morsmål (se core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Norwegian Bokmål: [one] and *[other].

## Counts and sizes

messages = { $count ->
    [one] { $count } melding
   *[other] { $count } meldinger
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] { $count } byte
   *[other] { $count } byte
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Av
send-delay-seconds = { $count ->
    [one] { $count } sekund
   *[other] { $count } sekunder
}
# the status bar: "12 meldinger, 3 uleste"
list-counts = { $messages }; uleste: { $unread }
list-counts-selected = { $messages }; uleste: { $unread }; merket: { $selected }
# the status bar while searching: "12 funnet, 3 uleste"
list-counts-found = Funnet: { $found }; uleste: { $unread }
list-counts-found-selected = Funnet: { $found }; uleste: { $unread }; merket: { $selected }
list-counts-none = Fant ingen meldinger

## Special folders, as Outlook names them

folder-inbox = Innboks
folder-sent = Sendte elementer
folder-deleted = Slettede elementer
folder-drafts = Utkast
folder-junk = Søppelpost
folder-archive = Arkiv

## The reading pane

reader-no-message = Ingen melding er valgt.
reader-downloading = Laster ned meldingen…
reader-downloading-detail = Meldingen vises her når nedlastingen er ferdig.
reader-downloading-size = Meldingen er på { $size }. Den vises her når den er lastet ned.
reader-failed = Meldingen kunne ikke lastes ned
reader-failed-network = E-postserveren kunne ikke nås ({ $reason }).
reader-failed-sign-in = E-postserveren godtok ikke påloggingen ({ $reason }). Kontroller passordet, eller logg på igjen under Fil > Kontoer.
reader-failed-security = Kunne ikke opprette en sikker tilkobling til e-postserveren ({ $reason }).
reader-failed-other = E-postserveren svarte: { $reason }.
reader-retry-note = Inbox Classic prøver igjen når kontoen er tilkoblet.
reader-unreadable = Denne meldingen kan ikke vises: { $error }
message-source-title = Meldingskilde: { $subject }
message-source-untitled = Meldingskilde

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Fra
header-date = Dato
header-to = Til
header-cc = Kopi
header-sent = Sendt
header-subject = Emne
header-security = Sikkerhet
header-part = Del { $number }
quote-original = ----- Opprinnelig melding -----
fold-show-earlier = Vis de tidligere meldingene

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Meldingen din ble ikke levert
bounce-delayed = Meldingen din er ikke levert ennå
bounce-delayed-note = E-postserveren din prøver fortsatt å levere den. Du trenger ikke å sende den på nytt.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Vis meldingen som kom i retur
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Vis den forsinkede meldingen
bounce-what-to-do = Dette kan du gjøre:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Vent på neste leveringsforsøk. Du får et nytt varsel hvis meldingen fortsatt ikke kan leveres.
bounce-delayed-row-do = E-postserveren din prøver fortsatt å levere meldingen. Du får et nytt varsel hvis det ikke lykkes.
# folds the receiving server's own words
bounce-details = Detaljer
# a recipient the notice does not name
bounce-someone = En mottaker
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Rapportert av: { $server }
bounce-retry-minutes = Mottakerserveren ba om å vente { $count ->
    [one] ett minutt
   *[other] { $count } minutter
} før neste forsøk.
bounce-retry-hours = Mottakerserveren ba om å vente { $count ->
    [one] én time
   *[other] { $count } timer
} før neste forsøk.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Blokkeringsliste: { $lists }
bounce-user-unknown = Adressen finnes ikke
bounce-user-unknown-why = Mottakerserveren har ingen postkasse med denne adressen. Den kan være feilskrevet, eller personen kan ha sluttet å bruke den.
bounce-user-unknown-do = Kontroller stavemåten av adressen, eller spør personen hvilken adresse de bruker nå.
bounce-invalid-address = Adressen er ikke gyldig
bounce-invalid-address-why = Adressen har et format som ikke kan brukes til å sende e-post.
bounce-invalid-address-do = Se etter skrivefeil, for eksempel mellomrom, manglende bokstaver eller et manglende domene etter @.
bounce-mailbox-disabled = Postkassen er stengt
bounce-mailbox-disabled-why = Adressen finnes, men postkassen er slått av eller brukes ikke lenger.
bounce-mailbox-disabled-do = Kontakt personen på en annen måte, og spør etter en adresse de bruker nå.
bounce-mailbox-full = Postkassen er full
bounce-mailbox-full-why = Mottakerens postkasse har ikke plass til ny e-post.
bounce-mailbox-full-do = Prøv å sende meldingen på nytt om noen dager, eller gi mottakeren beskjed på en annen måte. Det kan hjelpe å sende uten store vedlegg.
bounce-spam-blocked = Avvist som søppelpost
bounce-spam-blocked-why = Mottakerserveren oppfattet meldingen som søppelpost.
bounce-spam-blocked-do = Prøv å sende meldingen uten innhold som kan utløse søppelpostfilteret, for eksempel mange lenker, forkortede lenker eller store vedlegg. Kontakt e-postleverandøren din hvis problemet fortsetter.
bounce-virus-detected = Avvist på grunn av virus
bounce-virus-detected-why = Mottakerserveren fant et virus eller annet skadelig innhold i meldingen eller vedleggene.
bounce-virus-detected-do = Kontroller vedleggene med et antivirusprogram. Noen servere avviser alle programmer og arkiver, så del slike filer som en lenke i stedet.
bounce-ip-blocklisted = E-postserveren din står på en blokkeringsliste
bounce-ip-blocklisted-why = Mottakerserveren avviser e-post fra serveren som sendte meldingen din, fordi serverens IP-adresse står på en blokkeringsliste.
bounce-ip-blocklisted-do = Det er ikke meldingen som er problemet. Videresend dette varselet til e-postleverandøren din, og be dem få serveren fjernet fra listen.
bounce-domain-blocklisted = Et domene står på en blokkeringsliste
bounce-domain-blocklisted-why = Mottakerserveren avviser meldingen fordi domenet i adressen din, eller et domene i lenkene i meldingen, står på en blokkeringsliste.
bounce-domain-blocklisted-do = Hvis meldingen har lenker, prøv uten dem. Ellers videresender du dette varselet til den som drifter e-posten for domenet ditt.
bounce-policy-blocked = Avvist av mottakerserverens regler
bounce-policy-blocked-why = Reglene på mottakerserveren slipper ikke gjennom denne meldingen, for eksempel på grunn av størrelsen, vedleggene eller hvem som sendte den.
bounce-policy-blocked-do = Svaret fra serveren under Detaljer forklarer ofte årsaken. Spør mottakeren om denne typen e-post er tillatt.
bounce-geo-blocked = Avvist på grunn av opprinnelsessted
bounce-geo-blocked-why = Mottakerserveren tar ikke imot e-post fra landet eller nettverket e-postserveren din er i.
bounce-geo-blocked-do = Kontakt personen på en annen måte, eller spør e-postleverandøren din om det.
bounce-relay-denied = Serveren nektet å videresende meldingen
bounce-relay-denied-why = En server nektet å levere meldingen videre, ofte fordi den ble sendt uten pålogging eller gjennom en server som ikke håndterer denne mottakeren.
bounce-relay-denied-do = Kontroller innstillingene for utgående server under Fil > Kontoer. Kontroller også at pålogging er aktivert.
bounce-auth-failure = Avsenderdomenet kunne ikke bekreftes
bounce-auth-failure-why = Mottakerserveren kunne ikke bekrefte at meldingen virkelig kom fra domenet ditt (SPF, DKIM eller DMARC).
bounce-auth-failure-do = Videresend dette varselet til den som drifter e-posten for domenet ditt: innstillingene må rettes. I mellomtiden kan det hjelpe å sende gjennom leverandørens egen server.
bounce-rate-limited = For mye e-post på en gang
bounce-rate-limited-why = Mottakerserveren tar imot færre meldinger fra e-postserveren din inntil videre.
bounce-rate-limited-do = Vent en stund, og send den på nytt. Når du skriver til mange, send til færre om gangen.
bounce-greylisting = Midlertidig utsatt av søppelpostfilteret
bounce-greylisting-why = Mottakerserveren ber ukjente avsendere prøve igjen litt senere. Dette er et vanlig tiltak mot søppelpost.
bounce-greylisting-do = Vent på det automatiske leveringsforsøket. Meldingen blir vanligvis levert innen en time.
bounce-server-error = Mottakerserveren hadde et problem
bounce-server-error-why = Mottakerserveren kunne ikke nås, eller et problem hos mottakeren hindret den i å ta imot meldingen.
bounce-server-error-do = Send den på nytt senere. Hvis det fortsatt mislykkes, se etter skrivefeil i delen av adressen etter @.
bounce-unknown = Ikke levert
bounce-unknown-why = Leveringsvarselet oppgir ingen tydelig årsak.
bounce-unknown-do = Svaret fra serveren under Detaljer kan forklare mer. Videresend varselet til e-postleverandøren din hvis det ikke hjelper.

## Several messages selected

selection-title = { $count ->
    [one] { $count } melding merket
   *[other] { $count } meldinger merket
}
selection-unread = Uleste: { $count }
selection-flagged = { $count } med flagg
delete-for-good-one = Denne meldingen blir slettet permanent. Vil du slette den?
delete-for-good-all = Disse { $count } meldingene blir slettet permanent. Vil du slette dem?
delete-for-good-some = Vil du slette { $count } av totalt { $total } meldinger permanent?
done-read = { $count ->
   *[other] Merket { $messages } som lest
}
done-unread = { $count ->
   *[other] Merket { $messages } som ulest
}
done-flagged = { $count ->
   *[other] Satte flagg på { $messages }
}
done-unflagged = Fjernet flagget fra { $messages }
done-deleted-for-good = { $count ->
   *[other] Slettet { $messages } permanent
}
done-archived = { $count ->
   *[other] Arkiverte { $messages }
}
done-moved = { $count ->
   *[other] Flyttet { $messages } til { $folder }
}
done-copied = { $count ->
   *[other] Kopierte { $messages } til { $folder }
}
done-moving = { $count ->
   *[other] Flytter { $messages } til { $folder }...
}
done-copying = { $count ->
   *[other] Kopierer { $messages } til { $folder }...
}
done-moved-back = { $count ->
   *[other] Flyttet { $messages } tilbake til { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Følger samtalen
   *[other] Følger { $count } samtaler
}
done-unwatched = { $count ->
    [one] Sluttet å følge samtalen
   *[other] Sluttet å følge { $count } samtaler
}
done-ignored = { $count ->
    [one] Ignorerer samtalen
   *[other] Ignorerer { $count } samtaler
}
done-unignored = { $count ->
    [one] Sluttet å ignorere samtalen
   *[other] Sluttet å ignorere { $count } samtaler
}
their-folders = de opprinnelige mappene
undo-move = Angre flytting
undo-delete = Angre sletting
undo-archive = Angre arkivering
undo-junk = Angre merking som søppelpost
undo-not-junk = Angre merking som ikke søppelpost
undo-send = Angre sending
nothing-to-undo = Det er ingenting å angre.
messages-gone = Meldingene finnes ikke lenger.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Denne mappen kan ikke inneholde meldinger.
not-archived-here = Meldinger i denne mappen kan ikke arkiveres.
not-emptied-here = Bare Slettede elementer og Søppelpost kan tømmes.
next-unread-question = Det er ingen flere uleste meldinger i { $folder }.

    Vil du gå til { $next }, den neste mappen med uleste meldinger?
no-unread-left = Det er ingen uleste meldinger igjen.
empty-question = { $count ->
    [one] Vil du tømme { $folder }?

        Meldingen i mappen blir slettet permanent. Den kan ikke hentes tilbake.
   *[other] Vil du tømme { $folder }?

        { $messages } i mappen blir slettet permanent. De kan ikke hentes tilbake.
}
no-junk-folder = Denne kontoen har ingen søppelpostmappe å flytte meldingene til.
no-inbox-folder = Denne kontoen har ingen innboks å flytte meldingene til.
# the status bar after a flag in a colour: "Satte blått flagg på 2 meldinger"
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

move-window-title-move = { $count ->
    [one] Flytt melding
   *[other] Flytt { $count } meldinger
}
move-window-title-copy = { $count ->
    [one] Kopier melding
   *[other] Kopier { $count } meldinger
}
move-window-prompt-move = { $count ->
    [one] Flytt den merkede meldingen til:
   *[other] Flytt de { $count } merkede meldingene til:
}
move-window-prompt-copy = { $count ->
    [one] Kopier den merkede meldingen til:
   *[other] Kopier de { $count } merkede meldingene til:
}
# the folders used last, over the folder tree
targets-recent = Nylig brukt
# the folder the messages are in, which can not be chosen
target-current = { $folder } (gjeldende)
# a folder used last, with its account when there are several: "Arkiv (Jobb)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Flytter { $done } av { $messages } til { $folder }...
transfer-copying = Kopierer { $done } av { $messages } til { $folder }...
transfer-another-account = en annen konto
transfer-folder-gone = mappen den skulle til, finnes ikke lenger
transfer-not-on-server = meldingen finnes ikke lenger på serveren
transfer-not-moved = { $count ->
   *[other] { $messages } kunne ikke flyttes til en annen konto: { $reason }
}
transfer-not-copied = { $count ->
   *[other] { $messages } kunne ikke kopieres til en annen konto: { $reason }
}
transfer-none-moved = Ingen meldinger kunne flyttes
transfer-none-copied = Ingen meldinger kunne kopieres

## Messages as files

export-not-in-time = meldingen kunne ikke lastes ned i tide
export-not-saved = { $failed } av { $messages } kunne ikke lagres ({ $problems })
export-not-attached = meldingene kunne ikke legges ved: { $error }
# the status bar after Save As with several: "Lagret 3 meldinger i Skrivebord"
saved-to = { $count ->
   *[other] Lagret { $messages } i { $folder }
}
download-progress = Laster ned { $done } av { $total }
download-done = Lastet ned { $size }
downloading-messages = { $count ->
   *[other] Laster ned { $messages }...
}
# the status bar after files are dropped on a folder: "La 3 meldinger i Arkiv"
import-put = { $count ->
   *[other] La { $messages } i { $folder }
}
import-not-put = Disse ble ikke lagt i mappen:

    { $problems }

## Problems the windows show

error-store = lokalt lager: { $error }
error-not-found = ikke funnet
error-closed = avslutter
error-other-account = nettleseren logget på { $email }, ikke på denne kontoen
# a password or sign-in the mail server refused, with the server's words
failure-authentication = serveren godtok ikke påloggingen ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = tilkoblingen til serveren mislyktes ({ $reason })
error-in-use = påloggingsappen brukes av disse kontoene og kan ikke fjernes: { $accounts }
error-turned-off = denne påloggingsappen er slått av for nye kontoer
error-folder-name = mappenavnet må være 1 til 200 tegn langt og kan ikke inneholde kontrolltegn
error-folder-separator = et mappenavn kan ikke inneholde «{ $separator }» på denne serveren
error-folder-special = innboksen og spesialmappene kan ikke gis nytt navn eller slettes
error-no-recipients = meldingen har ingen mottakere
error-bad-address = «{ $address }» er ikke en e-postadresse
error-not-own-address = { $address } er ikke en av avsenderadressene til denne kontoen. Legg den til i «Andre adresser du sender fra» i kontoens egenskaper.
rule-query-refused = Regler kan ikke filtrere på mappe eller dato ({ $words }).
rule-no-query = Skriv inn søkekriterier for innkommende meldinger.
rule-no-action = Velg minst én handling for regelen.
error-attachment = { $path } kunne ikke leses: { $error }
error-no-drafts = kontoen har ingen Utkast-mappe å lagre meldingen i
error-draft-attachment = et vedlegg i utkastet kunne ikke beholdes: { $error }
error-password-not-saved = passordet kunne ikke lagres til neste oppstart: { $error }
error-sign-in-not-saved = de nye påloggingsopplysningene kunne ikke lagres til neste oppstart: { $error }
error-import-unreadable = { $path } kan ikke leses: { $error }
error-import-too-large = { $path } er større enn 50 MB
error-import-not-mail = { $path } er ikke en e-postmelding
error-list-answered = serveren for e-postlisten svarte med status { $status }
error-not-built = meldingen kunne ikke lages
error-outbox-waits = { $count ->
    [one] meldingen venter i Utboks og blir sendt ved neste Send/motta
   *[other] { $count } meldinger venter i Utboks og blir sendt ved neste Send/motta
}
error-draft-not-removed = det tidligere utkastet av meldingen kunne ikke fjernes fra Utkast: { $reason }
error-sent-but = meldingen ble sendt, men { $problem }
error-sent-still-in-outbox = den ligger fortsatt i Utboks: { $error }
error-sent-no-copy = ingen kopi kunne lagres i Sendte elementer: { $reason }
error-no-password = ikke noe passord for denne kontoen
error-no-sign-in = ingen lagrede påloggingsopplysninger for denne kontoen
error-provider-missing = påloggingsappen for { $provider } er ikke tilgjengelig i denne versjonen. Den kan ha blitt fjernet
error-provider-servers = serverne til denne kontoen samsvarer ikke med serverne til påloggingsappen
error-app-scopes = { $reason }. E-postserveren godtok ikke tokenet fra påloggingsappen: kontroller at appens tillatelser gir tilgang til e-post
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google har ikke bekreftet Inbox Classic ennå, så bare testbrukere kan bruke den innebygde påloggingsappen. Bruk din egen påloggingsapp for Google eller et app-passord. Hvis du er testbruker, kan du slå på den innebygde appen under Påloggingsapper (Fil > Kontoer).
sign-in-off-other = Den ble slått av under Påloggingsapper (Fil > Kontoer), der den kan slås på igjen.
sign-in-app-no-name = påloggingsappen må ha et navn
sign-in-app-no-client = klient-ID mangler
sign-in-app-no-scopes = påloggingsappen trenger tillatelsene som gir tilgang til e-post
sign-in-app-bad-host = serveradressen for { $server } mangler eller er ikke et gyldig vertsnavn
sign-in-app-plain = tilkoblingen til { $server } må bruke SSL/TLS eller STARTTLS
sign-in-app-not-checked = utstederen er ikke kontrollert ennå
sign-in-app-issuer-changed = utstederen er endret: skriv inn klienthemmeligheten på nytt, eller fjern den
sign-in-register-google = Opprett en OAuth-klient av typen Desktop app i Google Cloud Console, med tillatelsen https://mail.google.com/ på samtykkeskjermen. Mens appen er i testmodus, kan bare testbrukerne logge på.
sign-in-register-microsoft = Registrer en app i Microsoft Entra med plattformen Mobile and desktop applications, omdirigerings-URI-en http://localhost, offentlige klientflyter tillatt og de delegerte tillatelsene IMAP.AccessAsUser.All, SMTP.Send og offline_access. Hvis appen bare skal brukes i din organisasjon, bruker du https://login.microsoftonline.com/<tenant ID>/v2.0 som utsteder.
sign-in-register-other = Registrer en offentlig OAuth-klient for en installert app med omdirigerings-URI-en nedenfor. Leverandøren må tillate en vilkårlig port i denne adressen (RFC 8252). Legg til tillatelsen som gir tilgang til e-post hos leverandøren.

## Calendar invitations

repeats = Gjentas
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
repeats-on = { $repeats } på { $days }
# "Hver uke, 10 ganger"
repeats-times = { $count ->
    [one] { $repeats }, én gang
   *[other] { $repeats }, { $count } ganger
}
day-monday = mandag
day-tuesday = tirsdag
day-wednesday = onsdag
day-thursday = torsdag
day-friday = fredag
day-saturday = lørdag
day-sunday = søndag

## AI agents

# review: changed
agent-level-read = Lese e-post: mapper, meldingslisten, søk og meldinger
# review: changed
agent-level-organize = Organisere e-post: merke meldinger som lest eller ulest, endre flagg og fargene deres, håndtere søppelpost, flytte og arkivere meldinger, opprette og gi nytt navn til mapper, følge og ignorere samtaler, slette meldinger (flytte dem til Slettede elementer) og melde deg av e-postlister med din godkjenning
agent-level-drafts = Skrive utkast som du sender selv
agent-level-send = Sende e-post etter at du har godkjent hver melding
agent-connect-title = { $program } vil bruke e-posten din
agent-connect-detail = En KI-agent ba om å få arbeide med Inbox Classic. Velg hva den kan gjøre og hvilke kontoer den kan se; du kan endre dette senere under Verktøy > KI-agenter.

    Agenter leser e-post som andre har skrevet, og en melding kan prøve å lure dem. Inbox Classic spør deg alltid før en agent sender noe.
agent-reply-to = Svar på «{ $subject }»
agent-reply-all-on = Svar alle på «{ $subject }»
agent-forward-of = Videresending av «{ $subject }»
agent-never-written-one = Du har aldri skrevet til { $address }.
agent-never-written-many = Du har aldri skrevet til { $count } av disse adressene.
agent-send-title = { $program } vil sende denne meldingen
agent-send-detail = Kontroller mottakerne og innholdet. Når du godkjenner sendingen, venter meldingen i Utboks i { $seconds } sekunder. Du kan slette den der før den sendes.
agent-change-title = Hva { $program } kan gjøre
agent-change-allowed = Endre hva KI-agentene til dette programmet kan gjøre med e-posten din.
agent-change-refused = Du nektet dette programmet tilgang. Tillat det for å gi agentene tilgang til e-posten din igjen.
agent-log-taken-back = { $entry } (angret)
agent-files = Filer: { $files }
agent-undo-refused = Det kan ikke angres.
agent-undo-refused-why = Det kan ikke angres: { $reason }.
agent-undo-impossible = dette kan ikke angres
agent-undo-not-in-folder = meldingen ligger ikke lenger i den mappen
agent-undo-not-arrived = meldingen ligger ikke (ennå) i mappen den ble flyttet til
agent-undo-sent = meldingen er ikke lenger i Utboks
agent-original-not-downloaded = den opprinnelige meldingen er ikke lastet ned ennå. Åpne den først
agent-turned-away = Avvist
agent-can-nothing = Ingenting
agent-can-read = lese
agent-can-organize = organisere
agent-can-drafts = skrive utkast
agent-can-send = sende med din godkjenning
# "Lese, organisere og skrive utkast"
agent-can-list = { $first } og { $last }
agent-accounts = { $count ->
    [0] ingen kontoer
    [one] { $count } konto
   *[other] { $count } kontoer
}
# "Lese og organisere; 1 konto"
agent-access = { $can }; { $accounts }
agent-unreadable = Denne meldingen kan ikke leses.
agent-encrypted-original = Denne meldingen er kryptert: en agent kan ikke svare på den eller videresende den, siden den ikke kan kryptere.
agent-encrypted = Denne meldingen er kryptert. KI-agenter kan ikke lese innholdet. Brukeren må åpne den i Inbox Classic.
# review: new
agent-too-many-changes = For mange endringer de siste 30 dagene: denne agenten har gjort så mange som Inbox Classic lagrer i loggen for ett program. Den kan gjøre flere når de eldste er 30 dager gamle.
# review: new
agent-too-many-reads = For mye lest de siste 30 dagene: denne agenten har lest så mye som Inbox Classic lagrer i loggen for ett program. Den kan lese mer når de eldste lesingene er 30 dager gamle.
list-encrypted = Kryptert melding
agent-log-composed = Åpnet «{ $subject }» i skrivevinduet slik at du kan gjøre meldingen ferdig
agent-log-refused = Du avslo å sende «{ $subject }»
agent-log-sent = La «{ $subject }» i kø for sending til { $to }
agent-log-draft = Lagret utkastet «{ $subject }»
agent-log-draft-replaced = Erstattet utkastet «{ $subject }»
agent-log-draft-discarded = Forkastet utkastet «{ $subject }»
agent-draft-note = { $program }, en KI-agent, skrev dette utkastet. Kontroller mottakerne og teksten før du sender det.
agent-log-read = Merket «{ $subject }» som lest
agent-log-unread = Merket «{ $subject }» som ulest
agent-log-flagged = Satte flagg på «{ $subject }»
agent-log-unflagged = Fjernet flagget fra «{ $subject }»
agent-log-deleted = Flyttet «{ $subject }» til Slettede elementer
agent-log-moved = Flyttet «{ $subject }» til { $folder }
agent-log-junk = Merket «{ $subject }» som søppelpost
agent-log-not-junk = Merket «{ $subject }» som ikke søppelpost
agent-log-archived = Arkiverte «{ $subject }»
agent-log-folder = Opprettet mappen «{ $name }»
agent-log-unsubscribed = Du godkjente avmeldingsforespørselen. Meddelelse: «{ $subject }»
agent-log-unsubscribe-failed = Kunne ikke melde deg av e-postlisten knyttet til meldingen «{ $subject }»: { $reason }
agent-log-unsubscribe-refused = Du godkjente ikke avmeldingen. Avsendere: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } vil melde deg av en e-postliste
   *[other] { $program } vil melde deg av { $count } e-postlister
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic bruker funksjonen for avmelding med ett klikk til å be e-postlisten nedenfor om å slutte å sende deg meldinger. Ingenting annet sendes. Meldingene dine blir ikke endret eller flyttet.
   *[other] Inbox Classic bruker funksjonen for avmelding med ett klikk til å be hver e-postliste nedenfor om å slutte å sende deg meldinger. Ingenting annet sendes. Meldingene dine blir ikke endret eller flyttet.
}
# review: new
agent-log-flag-color = Satte { $color ->
    [red] rødt
    [orange] oransje
    [yellow] gult
    [green] grønt
    [blue] blått
    [purple] lilla
   *[gray] grått
} flagg på «{ $subject }»
# review: new
agent-log-renamed = Endret navnet på mappen «{ $old }» til «{ $name }»
# review: new
agent-log-watched = Begynte å følge samtalen «{ $subject }»
# review: new
agent-log-ignored = Begynte å ignorere samtalen «{ $subject }»
# review: new
agent-log-unmarked = Sluttet å følge eller ignorere samtalen «{ $subject }»
# the reason one change can not be taken back (agent-undo-refused-why)
# review: new
agent-undo-changed = meldingen er endret siden
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
# review: new
agent-log-bulk-read = { $count ->
    [one] Merket 1 melding som lest (søk: { $query })
   *[other] Merket { $count } meldinger som lest (søk: { $query })
}
# review: new
agent-log-bulk-unread = { $count ->
    [one] Merket 1 melding som ulest (søk: { $query })
   *[other] Merket { $count } meldinger som ulest (søk: { $query })
}
# review: new
agent-log-bulk-flagged = { $count ->
    [one] Satte flagg på 1 melding (søk: { $query })
   *[other] Satte flagg på { $count } meldinger (søk: { $query })
}
# review: new
agent-log-bulk-unflagged = { $count ->
    [one] Fjernet flagget fra 1 melding (søk: { $query })
   *[other] Fjernet flagget fra { $count } meldinger (søk: { $query })
}
# review: new
agent-log-bulk-color = Satte { $color ->
    [red] rødt
    [orange] oransje
    [yellow] gult
    [green] grønt
    [blue] blått
    [purple] lilla
   *[gray] grått
} flagg på { $count ->
    [one] 1 melding
   *[other] { $count } meldinger
} (søk: { $query })
# review: new
agent-log-bulk-moved = { $count ->
    [one] Flyttet 1 melding til { $folder } (søk: { $query })
   *[other] Flyttet { $count } meldinger til { $folder } (søk: { $query })
}
# review: new
agent-log-bulk-archived = { $count ->
    [one] Arkiverte 1 melding (søk: { $query })
   *[other] Arkiverte { $count } meldinger (søk: { $query })
}
# review: new
agent-log-bulk-junk = { $count ->
    [one] Merket 1 melding som søppelpost (søk: { $query })
   *[other] Merket { $count } meldinger som søppelpost (søk: { $query })
}
# review: new
agent-log-bulk-not-junk = { $count ->
    [one] Merket 1 melding som ikke søppelpost (søk: { $query })
   *[other] Merket { $count } meldinger som ikke søppelpost (søk: { $query })
}
# review: new
agent-log-bulk-deleted = { $count ->
    [one] Slettet 1 melding (søk: { $query })
   *[other] Slettet { $count } meldinger (søk: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
# review: new
agent-undo-span = { $span ->
    [quarter] De siste 15 minuttene
    [hour] Den siste timen
    [hours] De siste 4 timene
    [day] De siste 24 timene
    [week] De siste 7 dagene
   *[all] De siste 30 dagene
}
# the question before it takes back what a program did in the span chosen
# review: new
agent-undo-since-question = { $count ->
    [0] { $program } har ikke gjort noen endringer i dette tidsrommet som kan angres.
    [one] Vil du angre endringen { $program } gjorde i dette tidsrommet?
   *[other] Vil du angre de { $count } endringene { $program } gjorde i dette tidsrommet?
}
# review: new
agent-undo-since-detail = Meldinger flyttes tilbake til mappene de kom fra, lest-status og flagg blir som de var, og meldinger som fortsatt venter i Utboks, slettes. Det du eller serveren har endret siden, blir som det er.
# what taking back did, then a line for each kind of message it left as it is
# review: new
agent-undo-done = { $count ->
    [0] Ingenting ble angret.
    [one] Angret 1 endring.
   *[other] Angret { $count } endringer.
}
# review: new
agent-undo-left-gone = { $count ->
    [one] 1 melding lå ikke lenger der endringen la den.
   *[other] { $count } meldinger lå ikke lenger der endringen la dem.
}
# review: new
agent-undo-left-changed = { $count ->
    [one] 1 melding var endret siden, av deg eller på serveren, og ble latt være som den var.
   *[other] { $count } meldinger var endret siden, av deg eller på serveren, og ble latt være som de var.
}
# review: new
agent-undo-left-sent = { $count ->
    [one] 1 melding hadde allerede forlatt Utboks.
   *[other] { $count } meldinger hadde allerede forlatt Utboks.
}
# review: new
agent-undo-left-impossible = { $count ->
    [one] 1 endring kan ikke angres.
   *[other] { $count } endringer kan ikke angres.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
# review: new
agent-invitation-reply = { $response ->
    [accept] Denne meldingen godtar invitasjonen «{ $summary }» ({ $when }).
    [tentative] Denne meldingen godtar foreløpig invitasjonen «{ $summary }» ({ $when }).
   *[decline] Denne meldingen avslår invitasjonen «{ $summary }» ({ $when }).
} Arrangørens kalender registrerer svaret. Svaret ditt på invitasjonen endres først når meldingen er sendt.
# the subject of an answer to an invitation, as calendar programs write it
# review: new
invitation-reply-subject = { $response ->
    [accept] Godtatt: { $summary }
    [tentative] Foreløpig: { $summary }
   *[decline] Avslått: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
# review: new
invitation-reply-text = { $response ->
    [accept] { $name } har godtatt denne invitasjonen.
    [tentative] { $name } har foreløpig godtatt denne invitasjonen.
   *[decline] { $name } har avslått denne invitasjonen.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = { $count ->
    [one] leste 1 melding
   *[other] leste { $count } meldinger
}
# review: new
agent-reads-attachments = { $count ->
    [one] åpnet 1 vedlegg
   *[other] åpnet { $count } vedlegg
}
# review: new
agent-reads-searches = { $count ->
    [one] søkte én gang
   *[other] søkte { $count } ganger
}
# review: new
agent-reads-lists = { $count ->
    [one] så på en meldingsliste én gang
   *[other] så på meldingslister { $count } ganger
}
# each read under that row
# review: new
agent-read-message = Leste «{ $subject }»
# review: new
agent-read-conversation = { $count ->
    [one] Leste samtalen «{ $subject }» (1 melding)
   *[other] Leste samtalen «{ $subject }» ({ $count } meldinger)
}
# review: new
agent-read-attachment = Åpnet «{ $name }» i «{ $subject }»
# review: new
agent-read-search = { $count ->
    [one] Søkte etter «{ $query }»: 1 melding
   *[other] Søkte etter «{ $query }»: { $count } meldinger
}
# review: new
agent-read-people = Slo opp personer som begynner med «{ $query }»
# review: new
agent-read-list = { $count ->
    [one] Så på 1 melding i { $folder }
   *[other] Så på { $count } meldinger i { $folder }
}
# review: new
agent-read-changes = { $count ->
    [one] Så på 1 ny melding
   *[other] Så på { $count } nye meldinger
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = Programmer startet fra { $terminal }
# review: new
agent-terminal-programs-windows = Programmer startet fra en terminal ({ $terminal })
# review: new
agent-terminal-programs-linux = Programmer startet fra en terminal ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = Et program startet fra { $terminal }
# review: new
agent-terminal-program-windows = Et program startet fra en terminal ({ $terminal })
# review: new
agent-terminal-program-linux = Et program startet fra en terminal ({ $terminal })
# review: new
agent-connect-title-terminal = { $programs } vil bruke e-posten din
# review: new
agent-connect-terminal-detail = Alle KI-agenter du starter fra denne terminalen, deler tilgangen du gir her. Vil du gi en agent egen tilgang, legger du til --name og et navn du velger, blant argumentene i MCP-innstillingene til agenten.
# review: new
agent-connect-claimed = Programmet oppga at det var { $claimed }. Inbox Classic har sjekket hvilket program som startet det: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Skift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = leverandøren ga ikke noe oppdateringstoken
sign-in-no-account = leverandøren oppga ikke hvilken konto som logget på
sign-in-not-finished = påloggingen er ikke fullført
secrets-unavailable = { $store } er ikke tilgjengelig
secrets-unavailable-why = { $store } er ikke tilgjengelig: { $error }
secrets-windows = Legitimasjonsbehandling
secrets-mac = nøkkelringen
secrets-linux = systemets nøkkelring (Secret Service)
error-no-such-file = filen finnes ikke
cards-file-too-big = Denne filen er for stor til å være en adressebok.
ui-sender-added = { $name } ble lagt til i adresseboken.
ui-sender-known = { $name } er allerede i adresseboken.
ui-sender-none = Avsenderen av denne meldingen har ingen e-postadresse som kan legges til.
card-name-needed = Kontakten har verken navn eller e-postadresse.
# a file of Import Address Book that could not be read: "kontakter.vcf: filen finnes ikke"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Kode fra { $domain }
otp-copy = Kopier
otp-note = Skriv den bare inn på en side som tilhører { $domain }.
otp-old = Denne koden ble sendt mer enn en time før du åpnet meldingen, og har sannsynligvis utløpt.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } deltaker
       *[other] { $count } deltakere
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } er koden din for { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Gyldig
pgp-key-expires = Gyldig til { $date }
pgp-key-expired = Utløpt { $date }
pgp-key-revoked = Tilbakekalt
pgp-key-revoked-why = Tilbakekalt: { $reason }
pgp-key-not-valid = Ikke gyldig
pgp-key-locked = Kan ikke brukes: beskyttelsesnøkkelen finnes ikke lenger i { $store }. Importer en sikkerhetskopi av den private nøkkelen på nytt.
pgp-source-own = Laget i Inbox Classic
pgp-source-file = Importert fra en fil
pgp-source-paste = Limt inn
pgp-source-attachment = Fra en melding
pgp-source-vcard = Fra et kontaktkort
pgp-source-wkd = Fra domenets nøkkeltjeneste (WKD)
pgp-source-keyserver = Fra keys.openpgp.org
pgp-source-autocrypt = Fra Autocrypt-hodet i en melding
pgp-error-no-store = Private nøkler beskyttes av { $store }, som ikke kan brukes: { $error }
pgp-error-wrong-passphrase = Passfrasen er feil.
pgp-error-not-a-key = Dette er ikke en OpenPGP-nøkkel.
pgp-error-too-large = Nøkkelen er for stor.
pgp-error-unusable = Nøkkelen bruker gammel eller svak kryptografi og kan ikke brukes.
pgp-imported-private = { $count ->
    [one] Den private nøkkelen din ble importert.
   *[other] { $count } private nøkler ble importert.
}
pgp-imported-public = { $count ->
    [one] Én nøkkel ble importert.
   *[other] { $count } nøkler ble importert.
}
pgp-imported-pending = En annen nøkkel brukes allerede for { $addresses }. Du kan velge den nye nøkkelen i kontaktens egenskaper.
pgp-error-needs-passphrase = Den private nøkkelen er beskyttet med en passfrase. Skriv den inn for å importere nøkkelen.
pgp-error-mismatch = Den private nøkkelen hører ikke til den offentlige nøkkelen. Den kan ha blitt endret.
pgp-file-name-public = { $who } - offentlig nøkkel.asc
pgp-file-name-private = { $who } - sikkerhetskopi av privat nøkkel.asc
pgp-pending = En annen nøkkel for { $address } ble funnet { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Signert av { $signer }, nøkkelen er bekreftet
pgp-part-signed = Signert av { $signer } (nøkkelen er ikke bekreftet)
pgp-part-other = Signert av { $signer }, som ikke er avsenderen
pgp-part-unknown-key = Signert, men nøkkelen er ukjent
pgp-part-not-signed = Ikke signert
pgp-part-not-checked = Signaturen er ikke kontrollert
pgp-part-encrypted = Kryptert. { $signature }
pgp-part-no-key = Kryptert til en nøkkel du ikke har
pgp-part-changed = Kunne ikke bekrefte at den krypterte delen er uendret. Den vises ikke
pgp-part-unprotected = Kryptert uten beskyttelse mot endringer, vises ikke
pgp-part-broken = Den krypterte delen kan ikke leses
pgp-why-mismatch = Signaturen samsvarer ikke med denne teksten
pgp-why-weak-hash = Signaturen bruker hashfunksjonen { $hash }, som ikke lenger regnes som sikker
pgp-why-key-expired = Signert etter at nøkkelen utløp { $date }
pgp-why-key-revoked = Signert med en nøkkel som er tilbakekalt
pgp-why-not-signing-key = Signert med en nøkkel som ikke kan signere
pgp-why-from-future = Signaturen har en dato i fremtiden
pgp-why-signature-expired = Signaturen har utløpt
pgp-why-key-not-valid = Signert med en nøkkel som ikke er gyldig
pgp-why-not-for-you = Signert for andre mottakere og videresendt til deg
pgp-why-not-key-in-use = Signert med en annen nøkkel enn den som brukes for { $address }
pgp-part-pictures-loaded = { $label }. Bilder ble lastet fra internett
pgp-error-no-own-key = Du har ingen nøkkel for { $address } å signere eller kryptere med. Lag en under Verktøy > Krypteringsnøkler, eller slå av Signer og Krypter.
pgp-error-missing-keys = { $count ->
    [one] { $addresses } har ingen nøkkel å kryptere til.
   *[other] Disse mottakerne har ingen nøkkel å kryptere til: { $addresses }.
}
pgp-error-encrypted-quote = Denne meldingen siterer eller videresender en kryptert melding, så den kan bare sendes kryptert. Slå på Krypter, eller fjern den siterte teksten.
pgp-error-protect = Meldingen kunne ikke signeres eller krypteres: { $reason }
pgp-found-keys = Fant nøkler for følgende adresser: { $addresses }.
pgp-found-none = Fant ingen nøkkel for følgende adresser: { $addresses }. Be mottakerne sende deg de offentlige nøklene sine.
pgp-found-no-key = Fant ingen nøkkel.
pgp-find-unavailable = Kunne ikke slå opp nøkler nå: { $error }
pgp-publish-pending = keys.openpgp.org har sendt bekreftelseslenker til følgende adresser: { $addresses }. Klikk på lenken i hver e-post for å gjøre nøkkelen søkbar for den adressen.
pgp-publish-done = Nøkkelen din kan nå finnes på keys.openpgp.org ved å søke etter følgende adresser: { $addresses }.
pgp-publish-failed = Nøkkelen kunne ikke publiseres: { $error }
pgp-keyserver-off = Søk etter nøkler på keys.openpgp.org er slått av under { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Meldingen krypteres og signeres når du sender den. Bare du og { $addresses } kan lese innholdet.
   *[other] Meldingen krypteres og signeres når du sender den. Bare du og de { $count } mottakerne kan lese innholdet.
}
pgp-compose-encrypt-ready = Meldingen krypteres og signeres når du sender den. Legg til mottakere du har brukbare nøkler til.
pgp-compose-missing = { $count ->
    [one] Det mangler en brukbar nøkkel for { $addresses }, så meldingen kan ikke krypteres ennå.
   *[other] Det mangler brukbare nøkler for { $count } mottakere: { $addresses }. Meldingen kan ikke krypteres ennå.
}
pgp-compose-looking = Ser etter nøklene til { $addresses }...
pgp-compose-signed = Meldingen signeres digitalt når du sender den. Mottakerne kan kontrollere signaturen og om innholdet er endret.
pgp-compose-reply-clear = Ikke kryptert, selv om den opprinnelige meldingen var kryptert.
pgp-compose-encrypted-files = Meldingen inneholder vedlegg fra en kryptert melding og kan bare sendes kryptert. Slå på «Krypter» eller fjern disse vedleggene.
pgp-compose-sign-tip = Signer meldingen digitalt når du sender den, slik at mottakerne kan kontrollere signaturen og om innholdet er endret
pgp-compose-sign-tip-encrypted = Krypterte meldinger signeres alltid når de sendes
pgp-compose-encrypt-tip = Krypter innholdet når du sender meldingen, slik at bare du og mottakerne kan lese det
pgp-compose-make-key = Du har ikke satt opp en egen nøkkel for { $address }. Vil du lage en nå? Med nøkkelen kan du signere og kryptere meldinger.
pgp-compose-key-unusable = Nøkkelen din for { $address } kan ikke brukes. Årsak: { $state }
    Åpne «Krypteringsnøkler» for å importere en sikkerhetskopi av denne nøkkelen eller lage en ny.
pgp-compose-encrypt-off-quote = Meldingen inneholder fortsatt tekst, bilder eller vedlegg fra en kryptert melding. Fjern dette innholdet før du sender uten kryptering. Vil du slå av krypteringen likevel?
pgp-compose-encrypt-off-reply = Den opprinnelige meldingen var kryptert. Hvis du sender svaret eller videresender meldingen uten kryptering, kan e-postserverne lese innholdet. Vil du slå av krypteringen?
pgp-recipient-verified = Nøkkelen er bekreftet
pgp-recipient-found = Nøkkelen er ikke bekreftet
pgp-recipient-own = Din egen nøkkel
pgp-recipient-looking = Ser etter en nøkkel...
pgp-recipient-missing = Ingen nøkkel
pgp-recipient-not-found = Fant ingen nøkkel. Siste søk: { $date }
pgp-recipient-unusable = Nøkkelen kan ikke brukes: { $state }
pgp-recipients-intro = Meldingen krypteres med mottakernes nøkler og din egen nøkkel.
pgp-recipients-intro-missing = { $count ->
    [one] Én mottaker mangler en brukbar nøkkel. Finn nøkkelen eller fjern mottakeren fra meldingen. Du kan bare sende uten kryptering når meldingen ikke inneholder tekst, bilder eller vedlegg fra krypterte meldinger.
   *[other] { $count } mottakere mangler brukbare nøkler. Finn nøklene eller fjern mottakerne fra meldingen. Du kan bare sende uten kryptering når meldingen ikke inneholder tekst, bilder eller vedlegg fra krypterte meldinger.
}
pgp-details-part = Del { $number }: { $label }
# review: new
attachment-from-part = Fra del { $number }: { $label }
pgp-details-signed = Signert { $when } med nøkkelen { $key }
pgp-details-unknown-key = Signert med nøkkelen { $key }, som du ikke har
pgp-details-opened = Dekryptert med nøkkelen din { $key }
pgp-details-for = Kryptert til { $keys }
pgp-details-plain = Ikke signert og ikke kryptert
pgp-bar-parts = Denne meldingen har { $count } deler: { $list }. Hver del viser hvordan den er beskyttet.
pgp-bar-count-verified = { $count } med bekreftet nøkkel
# review: new
pgp-bar-count-encrypted-signed = { $count ->
    [one] { $count } kryptert og signert del
   *[other] { $count } krypterte og signerte deler
}
# review: new
pgp-bar-count-encrypted = { $count ->
    [one] { $count } kryptert del
   *[other] { $count } krypterte deler
}
# review: new
pgp-bar-count-signed = { $count ->
    [one] { $count } signert del
   *[other] { $count } signerte deler
}
pgp-bar-count-warning = { $count ->
    [one] { $count } trenger oppmerksomhet
   *[other] { $count } trenger oppmerksomhet
}
pgp-bar-count-neutral = { $count } uten bekreftet signatur
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Innstillinger
setup-part-preferences = Vindusinnstillinger
setup-part-accounts = Kontoer
setup-part-sign-in-apps = Påloggingsapper
setup-part-contacts = Kontakter og grupper
setup-part-keys = Krypteringsnøkler
setup-part-rules = Meldingsregler
setup-part-trusted-senders = Klarerte avsendere
setup-holds-settings = { $count ->
    [one] { $count } innstilling
   *[other] { $count } innstillinger
}
setup-holds-preferences = { $count ->
    [one] { $count } vindusinnstilling
   *[other] { $count } vindusinnstillinger
}
setup-holds-accounts = { $count ->
    [one] { $count } konto
   *[other] { $count } kontoer
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } påloggingsapp
   *[other] { $count } påloggingsapper
}
setup-holds-built-in = Hvilke innebygde påloggingsapper som er slått på
setup-holds-contacts = { $count ->
    [one] { $count } kontakt
   *[other] { $count } kontakter
}
setup-holds-groups = { $count ->
    [one] { $count } gruppe
   *[other] { $count } grupper
}
setup-holds-own-keys = { $count ->
    [one] { $count } egen nøkkel
   *[other] { $count } egne nøkler
}
setup-holds-contact-keys = { $count ->
    [one] { $count } nøkkel til en kontakt
   *[other] { $count } nøkler til kontakter
}
setup-holds-rules = { $count ->
    [one] { $count } regel
   *[other] { $count } regler
}
setup-holds-trusted-senders = { $count ->
    [one] { $count } klarert avsender
   *[other] { $count } klarerte avsendere
}
setup-sign-in-password = Passord
setup-account-secret-password = Passordet ligger i filen.
setup-account-secret-token = Lagrede påloggingsopplysninger er tatt med i filen.
setup-account-asks-password = Du må skrive inn passordet etter importen.
setup-account-signs-in-again = Du må logge på kontoen gjennom nettleseren etter importen.
setup-account-here = Kontoen finnes allerede på denne datamaskinen og blir hoppet over.
setup-account-no-app = Kontoen bruker påloggingsappen { $app }, som ikke finnes her. Importer påloggingsappene også.
setup-invalid-address = «{ $address }» er ikke en e-postadresse.
setup-invalid-server = serverinnstillingene for { $server } har et ugyldig vertsnavn eller en ugyldig port
setup-invalid-user = Kontoen mangler brukernavn.
setup-invalid-sign-in = Kontoen bruker en påloggingsmetode som Inbox Classic ikke støtter.
setup-error-empty = Filen er tom.
setup-error-too-large = Filen er for stor til å være en fil med innstillinger og kontoer fra Inbox Classic.
setup-error-not-setup = Dette er ikke en fil med innstillinger og kontoer fra Inbox Classic.
setup-error-damaged = Oppsettfilen er skadet og kan ikke leses.
setup-error-newer = Filen ble lagret med en nyere versjon av Inbox Classic ({ $version }). Oppdater Inbox Classic, og importer filen på nytt.
setup-error-needs-passphrase = Filen er beskyttet med en passfrase. Skriv inn passfrasen som ble brukt da den ble lagret.
setup-error-wrong-passphrase = Passfrasen stemmer ikke med den som ble brukt da filen ble lagret.
setup-error-changed = Oppsettfilen ble endret eller skadet etter at den ble lagret, så den kan ikke importeres.
setup-error-read = Oppsettfilen kunne ikke leses: { $error }
setup-error-write = Oppsettet kunne ikke lagres: { $error }
setup-error-no-parts = Velg minst én kategori.
setup-left-out = { $count ->
    [one] { $count } oppføring i { $part } kan ikke brukes og er utelatt.
   *[other] { $count } oppføringer i { $part } kan ikke brukes og er utelatt.
}
setup-imported-settings = Innstillingene ble erstattet.
setup-imported-preferences = Vindusinnstillingene ble erstattet.
setup-added-accounts = { $count ->
    [one] La til { $count } konto.
   *[other] La til { $count } kontoer.
}
setup-skipped-here = Kontoen { $address } finnes allerede her og ble hoppet over.
setup-skipped-no-app = Kontoen { $address } ble hoppet over fordi påloggingsappen { $app } ikke finnes her.
setup-skipped-invalid = { $address } ble hoppet over: { $reason }
setup-asks-password = Du blir bedt om passordet når kontoen { $address } kobler til.
setup-signs-in-again = Du blir bedt om å logge på i nettleseren når kontoen { $address } kobler til.
setup-added-sign-in-apps = { $count ->
    [one] La til { $count } påloggingsapp.
   *[other] La til { $count } påloggingsapper.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } påloggingsapp er allerede konfigurert her.
   *[other] { $count } påloggingsapper er allerede konfigurert her.
}
setup-added-contacts = { $count ->
    [one] La til { $count } kontakt i adresseboken.
   *[other] La til { $count } kontakter i adresseboken.
}
setup-skipped-contacts = { $count ->
    [one] { $count } kontakt er allerede i adresseboken.
   *[other] { $count } kontakter er allerede i adresseboken.
}
setup-added-groups = { $count ->
    [one] La til eller oppdaterte { $count } gruppe.
   *[other] La til eller oppdaterte { $count } grupper.
}
setup-added-own-keys = { $count ->
    [one] La til { $count } egen nøkkel.
   *[other] La til { $count } egne nøkler.
}
setup-added-contact-keys = { $count ->
    [one] La til { $count } nøkkel til en kontakt.
   *[other] La til { $count } nøkler til kontakter.
}
setup-added-rules = { $count ->
    [one] La til { $count } meldingsregel.
   *[other] La til { $count } meldingsregler.
}
setup-skipped-rules = { $count ->
    [one] { $count } meldingsregel finnes allerede her.
   *[other] { $count } meldingsregler finnes allerede her.
}
setup-skipped-rules-account = { $count ->
    [one] { $count } meldingsregel gjelder en konto som ikke finnes her, så den ble hoppet over.
   *[other] { $count } meldingsregler gjelder kontoer som ikke finnes her, så de ble hoppet over.
}
setup-rules-waiting = { $count ->
    [one] For { $count } meldingsregel må målmappen for flytting finnes ved synkronisering.
   *[other] For { $count } meldingsregler må målmappene for flytting finnes ved synkronisering.
}
setup-added-trusted-senders = { $count ->
    [one] La til { $count } klarert avsender.
   *[other] La til { $count } klarerte avsendere.
}
setup-nothing = Ingenting ble importert.
setup-account-servers = { $imap } og { $smtp } ({ $signin })
setup-file-name = Inbox Classic-innstillinger og kontoer
setup-skipped-unreachable = { $name } ble hoppet over: påloggingstjenesten kunne ikke nås. Legg den til på nytt under Påloggingsapper.
attachment-runs-programs = «{ $name }» kan kjøre programmer, så Inbox Classic åpner den ikke. Lagre den, og åpne den selv hvis du stoler på hvor den kommer fra.
attachment-decrypted-note = Dette vedlegget kommer fra en kryptert melding. For å åpne det i et annet program lagrer Inbox Classic en dekryptert, midlertidig kopi i en mappe for brukeren din. Kopier som er eldre enn 24 timer, fjernes neste gang Inbox Classic starter.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Serveren flyttet ikke { $messages } til { $folder }, så den er tilbake i { $from }: { $reason }
   *[other] Serveren flyttet ikke { $messages } til { $folder }, så de er tilbake i { $from }: { $reason }
}
undone-delete = { $count ->
    [one] Serveren slettet ikke { $messages }, så den er tilbake i { $from }: { $reason }
   *[other] Serveren slettet ikke { $messages }, så de er tilbake i { $from }: { $reason }
}
undone-archive = { $count ->
    [one] Serveren arkiverte ikke { $messages }, så den er tilbake i { $from }: { $reason }
   *[other] Serveren arkiverte ikke { $messages }, så de er tilbake i { $from }: { $reason }
}
undone-read = { $count ->
    [one] Serveren merket ikke { $messages } som lest, så den er ulest igjen: { $reason }
   *[other] Serveren merket ikke { $messages } som lest, så de er uleste igjen: { $reason }
}
undone-unread = { $count ->
    [one] Serveren merket ikke { $messages } som ulest, så den er lest igjen: { $reason }
   *[other] Serveren merket ikke { $messages } som ulest, så de er lest igjen: { $reason }
}
undone-flags = { $count ->
    [one] Serveren endret ikke flaggene på { $messages }, så endringen er angret: { $reason }
   *[other] Serveren endret ikke flaggene på { $messages }, så endringen er angret: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Vis PDF-filer i meldinger
# review: new
preview-pdf-off = PDF-filer vises ikke i meldinger.
# review: new
preview-pdf-off-crashed = En PDF-fil lukket Inbox Classic mens den ble vist, så PDF-filer vises ikke lenger i meldinger. Bilder vises fortsatt. Slå på { $option } under { $settings } for å vise PDF-filer igjen.
# review: new
preview-pdf-details = { $count ->
    [one] 1 side, { $size }
   *[other] { $count } sider, { $size }
}
# review: new
preview-page-alt = { $name }, side { $page } av { $count }
# review: new
preview-more-pages = { $count ->
    [one] Åpne filen for å se siden
   *[other] Åpne filen for å se alle { $count } sidene
}
# review: new
preview-more-files = { $count ->
    [one] 1 fil til er i listen over
   *[other] { $count } filer til er i listen over
}
# review: new
preview-tile-downloading = Laster ned…
# review: new
preview-tile-preparing = Forbereder…
# review: new
preview-tile-format = { $format }-bilder vises ikke ennå
# review: new
preview-tile-password = Beskyttet med passord: åpne den for å skrive inn passordet
# review: new
preview-tile-too-large = For stor til å vises
# review: new
preview-tile-unreadable = Kan ikke vises
# review: new
preview-tile-timed-out = Det tok for lang tid å vise
# review: new
preview-tile-crashed = Vises ikke: filen lukket Inbox Classic én gang
# review: new
preview-tile-off = Vises ikke før Inbox Classic starter igjen
# review: new
preview-not-printed = { $name } ({ $details }) skrives ikke ut. Åpne filen for å skrive den ut.
