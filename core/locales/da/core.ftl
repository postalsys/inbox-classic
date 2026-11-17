# Dansk. Udkast, venter på gennemsyn af en person med dansk som modersmål (se core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Danish: [one] and *[other].

## Counts and sizes

# review: new
messages = { $count ->
    [one] { $count } meddelelse
   *[other] { $count } meddelelser
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
send-delay-off = Fra
# review: new
send-delay-seconds = { $count ->
    [one] { $count } sekund
   *[other] { $count } sekunder
}
# the status bar: "12 meddelelser, 3 ulæste"
# review: new
list-counts = { $messages }, { $unread } ulæste
# review: new
list-counts-selected = { $messages }, { $unread } ulæste, { $selected } markeret
# the status bar while searching: "12 fundet, 3 ulæste"
# review: new
list-counts-found = { $found } fundet, { $unread } ulæste
# review: new
list-counts-found-selected = { $found } fundet, { $unread } ulæste, { $selected } markeret
# review: new
list-counts-none = Ingen meddelelser fundet

## Special folders, as Outlook names them in Danish

# review: new
folder-inbox = Indbakke
# review: new
folder-sent = Sendt post
# review: new
folder-deleted = Slettet post
# review: new
folder-drafts = Kladder
# review: new
folder-junk = Uønsket mail
# review: new
folder-archive = Arkiv

## The reading pane

# review: new
reader-no-message = Der er ikke markeret nogen meddelelse.
# review: new
reader-downloading = Henter meddelelsen…
# review: new
reader-downloading-detail = Meddelelsen vises her, når den er hentet.
# review: new
reader-downloading-size = Meddelelsen fylder { $size }. Den vises her, når den er hentet.
# review: new
reader-failed = Meddelelsen kunne ikke hentes
# review: new
reader-failed-network = Mailserveren kunne ikke nås ({ $reason }).
# review: new
reader-failed-sign-in = Mailserveren godtog ikke login ({ $reason }). Kontrollér adgangskoden, eller log på igen under Filer > Konti.
# review: new
reader-failed-security = Forbindelsen til mailserveren kunne ikke gøres sikker ({ $reason }).
# review: new
reader-failed-other = Mailserveren svarede: { $reason }.
# review: new
reader-retry-note = Der prøves igen, når kontoen får forbindelse igen.
# review: new
reader-unreadable = Meddelelsen kan ikke vises: { $error }
# review: new
message-source-title = Meddelelseskilde: { $subject }
# review: new
message-source-untitled = Meddelelseskilde

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Fra
# review: new
header-date = Dato
# review: new
header-to = Til
# review: new
header-cc = Cc
# review: new
header-sent = Sendt
# review: new
header-subject = Emne
# review: new
header-security = Sikkerhed
# review: new
header-part = Del { $number }
# review: new
quote-original = ----- Oprindelig meddelelse -----
# review: new
fold-show-earlier = Vis de tidligere meddelelser

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Din meddelelse blev ikke leveret
# review: new
bounce-delayed = Din meddelelse er ikke leveret endnu
# review: new
bounce-delayed-note = Din mailserver prøver stadig at levere den. Du behøver ikke at sende den igen.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Vis den meddelelse, der kom retur
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Vis den forsinkede meddelelse
# review: new
bounce-what-to-do = Det kan du gøre:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Intet endnu. Hvis den stadig ikke kan leveres, får du en ny besked.
# review: new
bounce-delayed-row-do = Intet endnu. Din mailserver prøver stadig at levere den, og du får en ny besked, hvis det ikke lykkes.
# folds the receiving server's own words
# review: new
bounce-details = Detaljer
# a recipient the notice does not name
# review: new
bounce-someone = En modtager
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Status: { $status }
# review: new
bounce-reported-by = Rapporteret af: { $server }
# review: new
bounce-retry-minutes = Den modtagende server bad om at vente { $count ->
    [one] et minut
   *[other] { $count } minutter
} før næste forsøg.
# review: new
bounce-retry-hours = Den modtagende server bad om at vente { $count ->
    [one] en time
   *[other] { $count } timer
} før næste forsøg.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Blokeringsliste: { $lists }
# review: new
bounce-user-unknown = Adressen findes ikke
# review: new
bounce-user-unknown-why = Den modtagende server har ingen postkasse med denne adresse. Den kan være stavet forkert, eller personen bruger den måske ikke længere.
# review: new
bounce-user-unknown-do = Kontrollér stavningen af adressen, eller spørg personen, hvilken adresse de bruger nu.
# review: new
bounce-invalid-address = Adressen er ikke gyldig
# review: new
bounce-invalid-address-why = Adressen er ikke skrevet på en måde, så der kan sendes mail til den.
# review: new
bounce-invalid-address-do = Se efter tastefejl, fx et mellemrum, et manglende bogstav eller ingenting efter @.
# review: new
bounce-mailbox-disabled = Postkassen er lukket
# review: new
bounce-mailbox-disabled-why = Adressen findes, men postkassen er slået fra eller bruges ikke længere.
# review: new
bounce-mailbox-disabled-do = Kontakt personen på en anden måde, og spørg efter en adresse, de bruger nu.
# review: new
bounce-mailbox-full = Postkassen er fuld
# review: new
bounce-mailbox-full-why = Modtagerens postkasse har ikke plads til ny mail.
# review: new
bounce-mailbox-full-do = Send den igen om nogle dage, eller giv personen besked på en anden måde. Store vedhæftede filer afvises først.
# review: new
bounce-spam-blocked = Afvist som spam
# review: new
bounce-spam-blocked-why = Den modtagende server opfattede meddelelsen som spam.
# review: new
bounce-spam-blocked-do = Send den igen uden det, der ligner spam, fx mange links, forkortede links eller en stor vedhæftet fil. Hvis det bliver ved med at ske, så spørg din mailudbyder.
# review: new
bounce-virus-detected = Afvist på grund af virus
# review: new
bounce-virus-detected-why = Den modtagende server fandt en virus eller andet skadeligt indhold i meddelelsen eller dens vedhæftede filer.
# review: new
bounce-virus-detected-do = Kontrollér de vedhæftede filer med et antivirusprogram. Nogle servere afviser alle programmer og arkiver, så del i stedet sådanne filer som et link.
# review: new
bounce-ip-blocklisted = Din mailserver er på en blokeringsliste
# review: new
bounce-ip-blocklisted-why = Den modtagende server afviser mail fra den server, der sendte din, fordi den servers adresse er på en blokeringsliste.
# review: new
bounce-ip-blocklisted-do = Meddelelsen er ikke problemet. Videresend denne besked til din mailudbyder, og bed dem om at få serveren fjernet fra listen.
# review: new
bounce-domain-blocklisted = Et domæne er på en blokeringsliste
# review: new
bounce-domain-blocklisted-why = Den modtagende server afviser meddelelsen, fordi domænet i din adresse, eller et domæne i meddelelsens links, er på en blokeringsliste.
# review: new
bounce-domain-blocklisted-do = Hvis meddelelsen har links, så prøv uden dem. Ellers skal du videresende denne besked til den, der står for mail på dit domæne.
# review: new
bounce-policy-blocked = Afvist af den modtagende servers regler
# review: new
bounce-policy-blocked-why = Den modtagende servers regler lukker ikke denne meddelelse igennem, fx på grund af dens størrelse, dens vedhæftede filer eller afsenderen.
# review: new
bounce-policy-blocked-do = Serverens egne ord under Detaljer giver ofte årsagen. Spørg modtageren, om de kan tage imod den slags mail.
# review: new
bounce-geo-blocked = Afvist på grund af afsenderstedet
# review: new
bounce-geo-blocked-why = Den modtagende server tager ikke imod mail fra det land eller netværk, din mailserver er i.
# review: new
bounce-geo-blocked-do = Kontakt personen på en anden måde, eller spørg din mailudbyder om det.
# review: new
bounce-relay-denied = Serveren ville ikke sende den videre
# review: new
bounce-relay-denied-why = En server nægtede at levere meddelelsen videre, ofte fordi den blev sendt uden login eller gennem en server, der ikke håndterer denne modtager.
# review: new
bounce-relay-denied-do = Kontrollér kontoens udgående server under Filer > Konti, og at den logger på.
# review: new
bounce-auth-failure = Din afsenderadresse kunne ikke bekræftes
# review: new
bounce-auth-failure-why = Den modtagende server kunne ikke bekræfte, at meddelelsen virkelig kom fra dit domæne (SPF, DKIM eller DMARC).
# review: new
bounce-auth-failure-do = Videresend denne besked til den, der står for mail på dit domæne: indstillingerne skal rettes. I mellemtiden kan det hjælpe at sende via din udbyders egen server.
# review: new
bounce-rate-limited = For meget mail på én gang
# review: new
bounce-rate-limited-why = Den modtagende server tager indtil videre imod færre meddelelser fra din mailserver.
# review: new
bounce-rate-limited-do = Vent lidt, og send den igen. Når du skriver til mange personer, så send til færre ad gangen.
# review: new
bounce-greylisting = Holdt tilbage et øjeblik
# review: new
bounce-greylisting-why = Den modtagende server beder ukendte afsendere om at prøve igen lidt senere, en almindelig kontrol mod spam.
# review: new
bounce-greylisting-do = Intet. Mailservere prøver selv igen, og meddelelsen leveres som regel inden for en time.
# review: new
bounce-server-error = Den modtagende server havde et problem
# review: new
bounce-server-error-why = Den modtagende server kunne ikke nås, eller den kunne ikke tage imod meddelelsen på grund af et problem hos sig selv.
# review: new
bounce-server-error-do = Send den igen senere. Hvis det bliver ved med at mislykkes, så kontrollér delen af adressen efter @ for tastefejl.
# review: new
bounce-unknown = Ikke leveret
# review: new
bounce-unknown-why = Beskeden siger ikke tydeligt hvorfor.
# review: new
bounce-unknown-do = Serverens egne ord under Detaljer kan fortælle mere. Hvis de ikke hjælper, så videresend denne besked til din mailudbyder.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } meddelelse markeret
   *[other] { $count } meddelelser markeret
}
# review: new
selection-unread = { $count } ulæste
# review: new
selection-flagged = { $count } med flag
# review: new
delete-for-good-one = Denne meddelelse bliver slettet permanent. Vil du slette den?
# review: new
delete-for-good-all = Disse { $count } meddelelser bliver slettet permanent. Vil du slette dem?
# review: new
delete-for-good-some = { $count } af de { $total } meddelelser bliver slettet permanent. Vil du slette meddelelserne?
# review: new
done-read = { $count ->
    [one] Markerede { $messages } som læst
   *[other] Markerede { $messages } som læste
}
# review: new
done-unread = { $count ->
    [one] Markerede { $messages } som ulæst
   *[other] Markerede { $messages } som ulæste
}
# review: new
done-flagged = { $count ->
   *[other] Satte flag på { $messages }
}
# review: new
done-unflagged = Fjernede flaget fra { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Slettede { $messages } permanent
}
# review: new
done-archived = { $count ->
   *[other] Arkiverede { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Flyttede { $messages } til { $folder }
}
# review: new
done-copied = { $count ->
   *[other] Kopierede { $messages } til { $folder }
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
   *[other] Flyttede { $messages } tilbage til { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Følger samtalen
   *[other] Følger { $count } samtaler
}
# review: new
done-unwatched = { $count ->
    [one] Følger ikke længere samtalen
   *[other] Følger ikke længere { $count } samtaler
}
# review: new
done-ignored = { $count ->
    [one] Ignorerer samtalen
   *[other] Ignorerer { $count } samtaler
}
# review: new
done-unignored = { $count ->
    [one] Ignorerer ikke længere samtalen
   *[other] Ignorerer ikke længere { $count } samtaler
}
# review: new
their-folders = deres mapper
# review: new
undo-move = Fortryd flytning
# review: new
undo-delete = Fortryd sletning
# review: new
undo-archive = Fortryd arkivering
# review: new
undo-junk = Fortryd Marker som uønsket
# review: new
undo-not-junk = Fortryd Marker som ikke uønsket
# review: new
undo-send = Fortryd afsendelse
# review: new
nothing-to-undo = Der er intet at fortryde.
# review: new
messages-gone = Meddelelserne er der ikke længere.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Denne mappe kan ikke indeholde meddelelser.
# review: new
not-archived-here = Meddelelser i denne mappe kan ikke arkiveres.
# review: new
not-emptied-here = Kun Slettet post og Uønsket mail kan tømmes.
# review: new
next-unread-question = Der er ikke flere ulæste meddelelser i { $folder }.

    Vil du gå til { $next }, den næste mappe med ulæste meddelelser?
# review: new
no-unread-left = Der er ikke flere ulæste meddelelser.
# review: new
empty-question = { $count ->
    [one] Vil du tømme { $folder }?

        Meddelelsen i mappen bliver slettet permanent. Den kan ikke hentes tilbage.
   *[other] Vil du tømme { $folder }?

        De { $messages } i mappen bliver slettet permanent. De kan ikke hentes tilbage.
}
# review: new
no-junk-folder = Denne konto har ingen mappe til uønsket mail, som meddelelserne kan flyttes til.
# review: new
no-inbox-folder = Denne konto har ingen indbakke, som meddelelserne kan flyttes til.
# the status bar after a flag in a colour: "Satte rødt flag på 2 meddelelser"
# review: new
done-flagged-color = { $color ->
    [red] Satte rødt flag på { $messages }
    [orange] Satte orange flag på { $messages }
    [yellow] Satte gult flag på { $messages }
    [green] Satte grønt flag på { $messages }
    [blue] Satte blåt flag på { $messages }
    [purple] Satte lilla flag på { $messages }
   *[gray] Satte gråt flag på { $messages }
}
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Rød
    [orange] Orange
    [yellow] Gul
    [green] Grøn
    [blue] Blå
    [purple] Lilla
   *[gray] Grå
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [one] Flyt meddelelse
   *[other] Flyt { $count } meddelelser
}
# review: new
move-window-title-copy = { $count ->
    [one] Kopier meddelelse
   *[other] Kopier { $count } meddelelser
}
# review: new
move-window-prompt-move = { $count ->
    [one] Flyt den markerede meddelelse til:
   *[other] Flyt de { $count } markerede meddelelser til:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Kopier den markerede meddelelse til:
   *[other] Kopier de { $count } markerede meddelelser til:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Senest brugte
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (aktuel)
# a folder used last, with its account when there are several: "Arkiv (Arbejde)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Flytter { $done } af { $messages } til { $folder }...
# review: new
transfer-copying = Kopierer { $done } af { $messages } til { $folder }...
# review: new
transfer-another-account = en anden konto
# review: new
transfer-folder-gone = mappen, den skulle til, findes ikke længere
# review: new
transfer-not-on-server = meddelelsen er ikke længere på serveren
# review: new
transfer-not-moved = { $count ->
   *[other] { $messages } kunne ikke flyttes til en anden konto: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] { $messages } kunne ikke kopieres til en anden konto: { $reason }
}
# review: new
transfer-none-moved = Ingen meddelelser kunne flyttes
# review: new
transfer-none-copied = Ingen meddelelser kunne kopieres

## Messages as files

# review: new
export-not-in-time = meddelelsen kunne ikke hentes i tide
# review: new
export-not-saved = { $failed } af { $messages } kunne ikke gemmes ({ $problems })
# review: new
export-not-attached = meddelelserne kunne ikke vedhæftes: { $error }
# the status bar after Save As with several: "Gemte 3 meddelelser i Skrivebord"
# review: new
saved-to = { $count ->
   *[other] Gemte { $messages } i { $folder }
}
# review: new
download-progress = Henter { $done } af { $total }
# review: new
download-done = Hentede { $size }
# review: new
downloading-messages = { $count ->
   *[other] Henter { $messages }...
}
# the status bar after files are dropped on a folder: "Lagde 3 meddelelser i Arkiv"
# review: new
import-put = { $count ->
   *[other] Lagde { $messages } i { $folder }
}
# review: new
import-not-put = Disse blev ikke lagt i mappen:

    { $problems }

## Problems the windows show

# review: new
error-store = lokalt lager: { $error }
# review: new
error-not-found = ikke fundet
# review: new
error-closed = lukker ned
# review: new
error-other-account = browseren loggede på { $email }, ikke på denne konto
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = serveren godtog ikke login ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = forbindelsen til serveren mislykkedes ({ $reason })
# review: new
error-in-use = den kan ikke fjernes, så længe konti logger på med den: { $accounts }
# review: new
error-turned-off = denne login-app er slået fra for nye konti
# review: new
error-folder-name = mappenavnet skal være på 1 til 200 tegn og må ikke indeholde kontroltegn
# review: new
error-folder-separator = et mappenavn må ikke indeholde »{ $separator }« på denne server
# review: new
error-folder-special = Indbakke og de særlige mapper kan ikke omdøbes eller slettes
# review: new
error-no-recipients = meddelelsen har ingen modtagere
# review: new
error-bad-address = »{ $address }« er ikke en e-mailadresse
# review: new
error-not-own-address = { $address } er ikke en af kontoens afsenderadresser. Føj den til »Andre adresser, du sender fra« i kontoens egenskaber.
# review: new
rule-query-refused = Regler kan ikke filtrere efter mappe eller dato ({ $words }).
# review: new
rule-no-query = Angiv søgekriterier for indgående meddelelser.
# review: new
rule-no-action = Vælg mindst én handling for reglen.
# review: new
error-attachment = { $path } kunne ikke læses: { $error }
# review: new
error-no-drafts = kontoen har ingen mappe til kladder, som meddelelsen kan gemmes i
# review: new
error-draft-attachment = en vedhæftet fil i kladden kunne ikke beholdes: { $error }
# review: new
error-password-not-saved = adgangskoden kunne ikke gemmes til næste start: { $error }
# review: new
error-sign-in-not-saved = de nye loginoplysninger kunne ikke gemmes til næste start: { $error }
# review: new
error-import-unreadable = { $path } kan ikke læses: { $error }
# review: new
error-import-too-large = { $path } er større end 50 MB
# review: new
error-import-not-mail = { $path } er ikke en e-mailmeddelelse
# review: new
error-list-answered = mailinglistens server svarede med status { $status }
# review: new
error-not-built = meddelelsen kunne ikke oprettes
# review: new
error-outbox-waits = { $count ->
    [one] meddelelsen venter i Udbakke og sendes ved næste Send/modtag
   *[other] { $count } meddelelser venter i Udbakke og sendes ved næste Send/modtag
}
# review: new
error-draft-not-removed = den tidligere kladde af meddelelsen kunne ikke fjernes fra Kladder: { $reason }
# review: new
error-sent-but = meddelelsen blev sendt, men { $problem }
# review: new
error-sent-still-in-outbox = den ligger stadig i Udbakke: { $error }
# review: new
error-sent-no-copy = der kunne ikke gemmes en kopi i Sendt post: { $reason }
# review: new
error-no-password = ingen adgangskode til denne konto
# review: new
error-no-sign-in = intet login til denne konto
# review: new
error-provider-missing = denne version kan ikke logge på { $provider }: er login-appen fjernet?
# review: new
error-provider-servers = kontoens servere passer ikke med login-appens servere
# review: new
error-app-scopes = { $reason }. Mailserveren godtog ikke login-appens token: kontrollér, at appens tilladelser (scopes) giver adgang til mail
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google har endnu ikke godkendt Inbox Classic, så kun testbrugere kan logge på med den. Brug din egen login-app til Google eller en appadgangskode, eller slå den til under Login-apps (Filer > Konti), hvis du er testbruger.
# review: new
sign-in-off-other = Den blev slået fra under Login-apps (Filer > Konti), hvor den kan slås til igen.
# review: new
sign-in-app-no-name = login-appen skal have et navn
# review: new
sign-in-app-no-client = klient-id mangler
# review: new
sign-in-app-no-scopes = login-appen skal have de tilladelser (scopes), der giver adgang til mail
# review: new
sign-in-app-bad-host = adressen på { $server }-serveren mangler eller er ikke et gyldigt værtsnavn
# review: new
sign-in-app-plain = { $server }-serveren skal bruge SSL/TLS eller STARTTLS
# review: new
sign-in-app-not-checked = udstederen er ikke kontrolleret endnu
# review: new
sign-in-app-issuer-changed = udstederen er ændret: skriv klienthemmeligheden igen, eller fjern den
# review: new
sign-in-register-google = Opret en OAuth-klient af typen Desktop app i Google Cloud Console med tilladelsen (scope) https://mail.google.com/ på dens samtykkeskærm. Så længe appen er i test, kan kun dens testbrugere logge på.
# review: new
sign-in-register-microsoft = Registrer en app i Microsoft Entra med platformen Mobile and desktop applications, omdirigerings-URI'en http://localhost og offentlige klientforløb tilladt, samt de delegerede tilladelser IMAP.AccessAsUser.All, SMTP.Send og offline_access. Hvis den kun er til din organisation, så brug https://login.microsoftonline.com/<tenant-id>/v2.0 som udsteder.
# review: new
sign-in-register-other = Registrer en native (offentlig) klient med omdirigerings-URI'en nedenfor; udbyderen skal tillade enhver port på den (RFC 8252). Tilføj den tilladelse (scope), som udbyderen giver adgang til mail med.

## Calendar invitations

# review: new
repeats = Gentages
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Hver dag
       *[other] Hver { $interval }. dag
    }
    [week] { $interval ->
        [one] Hver uge
       *[other] Hver { $interval }. uge
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
# "Hver uge om mandagen, onsdagen": "Hver uge på mandag, onsdag"
# review: new
repeats-on = { $repeats } på { $days }
# "Hver uge, 10 gange"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, én gang
   *[other] { $repeats }, { $count } gange
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
agent-level-read = Læse mail: mapper, meddelelseslisten, søgning og meddelelser
# review: new
agent-level-organize = Organisere mail: læst/ulæst, flag, uønsket, flytning, sletning til Slettet post
# review: new
agent-level-drafts = Skrive kladder, som du selv sender
# review: new
agent-level-send = Sende mail, hver meddelelse først når du siger ja
# review: new
agent-connect-title = { $program } vil bruge din mail
# review: new
agent-connect-detail = En AI-agent har bedt om at arbejde med Inbox Classic. Vælg, hvad den må, og hvilke konti den må se; du kan ændre det senere under Funktioner > AI-agenter.

    Agenter læser mail, som andre har skrevet, og en meddelelse kan forsøge at narre dem. Inbox Classic spørger dig altid, før en agent sender noget.
# review: new
agent-reply-to = Svar på »{ $subject }«
# review: new
agent-reply-all-on = Svar alle på »{ $subject }«
# review: new
agent-forward-of = Videresendelse af »{ $subject }«
# review: new
agent-never-written-one = Du har aldrig skrevet til { $address }.
# review: new
agent-never-written-many = Du har aldrig skrevet til { $count } af disse adresser.
# review: new
agent-send-title = { $program } vil sende denne meddelelse
# review: new
agent-send-detail = Kontrollér modtagerne og meddelelsens indhold. Når du bekræfter, venter meddelelsen { $seconds } sekunder i Udbakke, hvor du stadig kan slette den.
# review: new
agent-change-title = Det må { $program }
# review: new
agent-change-allowed = Skift, hvad dette programs AI-agenter må gøre med din mail.
# review: new
agent-change-refused = Du har nægtet dette program adgang. Tillad det for at give dets agenter adgang til din mail igen.
# review: new
agent-log-taken-back = { $entry } (fortrudt)
# review: new
agent-files = Filer: { $files }
# review: new
agent-undo-refused = Det kan ikke fortrydes.
# review: new
agent-undo-refused-why = Det kan ikke fortrydes: { $reason }.
# review: new
agent-undo-impossible = dette kan ikke fortrydes
# review: new
agent-undo-not-in-folder = meddelelsen er ikke længere i den mappe
# review: new
agent-undo-not-arrived = meddelelsen er ikke (endnu) i den mappe, den blev flyttet til
# review: new
agent-undo-sent = meddelelsen er allerede sendt
# review: new
agent-original-not-downloaded = den oprindelige meddelelse er ikke hentet endnu. Åbn den først
# review: new
agent-turned-away = Afvist
# review: new
agent-can-nothing = Intet
# review: new
agent-can-read = læse
# review: new
agent-can-organize = organisere
# review: new
agent-can-drafts = skrive kladder
# review: new
agent-can-send = sende med dit ja
# "Læse, organisere og skrive kladder"
# review: new
agent-can-list = { $first } og { $last }
# review: new
agent-accounts = { $count ->
    [0] ingen konti
    [one] 1 konto
   *[other] { $count } konti
}
# "Læse og organisere; 1 konto"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Denne meddelelse kan ikke læses.
# review: new
agent-encrypted-original = Denne meddelelse er krypteret: en agent kan ikke svare på den eller videresende den, da den ikke kan kryptere.
# review: new
agent-encrypted = Denne meddelelse er krypteret. Kun brugeren kan læse den, i Inbox Classic.
# review: new
list-encrypted = Krypteret meddelelse
# review: new
agent-log-composed = Åbnede »{ $subject }« i en ny meddelelse, som du kan gøre færdig
# review: new
agent-log-refused = Du sendte ikke »{ $subject }«
# review: new
agent-log-sent = Sendte »{ $subject }« til { $to }
# review: new
agent-log-draft = Gemte kladden »{ $subject }«
# review: new
agent-log-read = Markerede »{ $subject }« som læst
# review: new
agent-log-unread = Markerede »{ $subject }« som ulæst
# review: new
agent-log-flagged = Satte flag på »{ $subject }«
# review: new
agent-log-unflagged = Fjernede flaget fra »{ $subject }«
# review: new
agent-log-deleted = Slettede »{ $subject }«
# review: new
agent-log-moved = Flyttede »{ $subject }« til { $folder }
# review: new
agent-log-junk = Markerede »{ $subject }« som uønsket
# review: new
agent-log-not-junk = Markerede »{ $subject }« som ikke uønsket
# review: new
agent-log-archived = Arkiverede »{ $subject }«
# review: new
agent-log-folder = Oprettede mappen »{ $name }«
# review: new
agent-log-unsubscribed = Afmeldte listen for »{ $subject }«

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Skift
# review: new
key-del = Delete
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = udbyderen gav intet opdateringstoken
# review: new
sign-in-no-account = udbyderen oplyste ikke, hvilken konto der loggede på
# review: new
sign-in-not-finished = login er ikke afsluttet
# review: new
secrets-unavailable = { $store } er ikke tilgængelig
# review: new
secrets-unavailable-why = { $store } er ikke tilgængelig: { $error }
# review: new
secrets-windows = Legitimationsstyring
# review: new
secrets-mac = nøgleringen
# review: new
secrets-linux = systemets nøglering (Secret Service)
# review: new
error-no-such-file = filen findes ikke
# review: new
cards-file-too-big = Denne fil er for stor til at være et adressekartotek.
# review: new
ui-sender-added = { $name } blev føjet til adressekartoteket.
# review: new
ui-sender-known = { $name } er allerede i adressekartoteket.
# review: new
ui-sender-none = Afsenderen af denne meddelelse har ingen e-mailadresse, der kan tilføjes.
# review: new
card-name-needed = Kontakten har hverken navn eller e-mailadresse.
# a file of Import Address Book that could not be read: "contacts.vcf: filen findes ikke"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Kode fra { $domain }
# review: new
otp-copy = Kopier
# review: new
otp-note = Indtast den kun på en side fra { $domain }.
# review: new
otp-old = Denne kode blev sendt mere end en time før, du åbnede den, og er sandsynligvis udløbet.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } deltager
       *[other] { $count } deltagere
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } er din kode til { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Gyldig
# review: new
pgp-key-expires = Gyldig til { $date }
# review: new
pgp-key-expired = Udløb { $date }
# review: new
pgp-key-revoked = Tilbagekaldt
# review: new
pgp-key-revoked-why = Tilbagekaldt: { $reason }
# review: new
pgp-key-not-valid = Ikke gyldig
# review: new
pgp-key-locked = Kan ikke bruges: den nøgle, der beskytter den, er ikke længere i { $store }. Importer sikkerhedskopien af den igen.
# review: new
pgp-source-own = Oprettet i Inbox Classic
# review: new
pgp-source-file = Importeret fra en fil
# review: new
pgp-source-paste = Indsat
# review: new
pgp-source-attachment = Fra en meddelelse
# review: new
pgp-source-vcard = Fra et kontaktkort
# review: new
pgp-source-wkd = Fra afsenderens mailudbyder
# review: new
pgp-source-keyserver = Fra keys.openpgp.org
# review: new
pgp-source-autocrypt = Fra en meddelelses Autocrypt-header
# review: new
pgp-error-no-store = Private nøgler beskyttes af { $store }, som ikke kan bruges: { $error }
# review: new
pgp-error-wrong-passphrase = Adgangsfrasen er forkert.
# review: new
pgp-error-not-a-key = Dette er ikke en OpenPGP-nøgle.
# review: new
pgp-error-too-large = Nøglen er for stor.
# review: new
pgp-error-unusable = Nøglen bruger gammel eller svag kryptografi og kan ikke bruges.
# review: new
pgp-imported-private = { $count ->
    [one] Din private nøgle blev importeret.
   *[other] { $count } private nøgler blev importeret.
}
# review: new
pgp-imported-public = { $count ->
    [one] Én nøgle blev importeret.
   *[other] { $count } nøgler blev importeret.
}
# review: new
pgp-imported-pending = En anden nøgle bruges allerede til { $addresses }: den nye venter i kontakten, indtil du vælger den.
# review: new
pgp-error-needs-passphrase = Den private nøgle er beskyttet af en adgangsfrase. Skriv den for at importere nøglen.
# review: new
pgp-error-mismatch = Den private nøgle hører ikke til sin offentlige nøgle. Den kan være blevet ændret.
# review: new
pgp-file-name-public = { $who } offentlig nøgle.asc
# review: new
pgp-file-name-private = { $who } sikkerhedskopi af privat nøgle.asc
# review: new
pgp-pending = Der blev fundet en anden nøgle til { $address } den { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Signeret af { $signer }, nøglen er bekræftet
# review: new
pgp-part-signed = Signeret af { $signer } (nøglen er ikke bekræftet)
# review: new
pgp-part-other = Signeret af { $signer }, som ikke er afsenderen
# review: new
pgp-part-unknown-key = Signeret, men nøglen er ukendt
# review: new
pgp-part-not-signed = Ikke signeret
# review: new
pgp-part-not-checked = Signaturen er ikke kontrolleret
# review: new
pgp-part-encrypted = Krypteret. { $signature }
# review: new
pgp-part-no-key = Krypteret til en nøgle, du ikke har
# review: new
pgp-part-changed = Den krypterede del blev ændret undervejs og vises ikke
# review: new
pgp-part-unprotected = Krypteret uden beskyttelse mod ændringer, vises ikke
# review: new
pgp-part-broken = Den krypterede del kan ikke læses
# review: new
pgp-why-mismatch = Signaturen passer ikke med denne tekst
# review: new
pgp-why-weak-hash = Signaturen bruger { $hash }, som ikke længere er sikker
# review: new
pgp-why-key-expired = Signeret efter at nøglen udløb { $date }
# review: new
pgp-why-key-revoked = Signeret med en nøgle, der er tilbagekaldt
# review: new
pgp-why-not-signing-key = Signeret med en nøgle, der ikke må signere
# review: new
pgp-why-from-future = Signaturen er dateret ud i fremtiden
# review: new
pgp-why-signature-expired = Signaturen er udløbet
# review: new
pgp-why-key-not-valid = Signeret med en nøgle, der ikke er gyldig
# review: new
pgp-why-not-for-you = Signeret til andre modtagere og sendt videre til dig
# review: new
pgp-part-pictures-loaded = { $label }. Billeder blev hentet fra internettet
# review: new
pgp-error-no-own-key = Du har ingen nøgle til { $address } at signere eller kryptere med. Opret en under Funktioner > Krypteringsnøgler, eller slå Signer og Krypter fra.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } har ingen nøgle at kryptere til.
   *[other] Disse modtagere har ingen nøgle at kryptere til: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Denne meddelelse citerer eller videresender en krypteret meddelelse, så den kan kun sendes krypteret. Slå Krypter til, eller fjern den citerede tekst.
# review: new
pgp-error-protect = Meddelelsen kunne ikke signeres eller krypteres: { $reason }
# review: new
pgp-found-keys = Nøglen til { $addresses } blev fundet.
# review: new
pgp-found-none = Der blev ikke fundet nogen nøgle til { $addresses }. Bed dem om at sende dig deres offentlige nøgle.
# review: new
pgp-found-no-key = Der blev ikke fundet nogen nøgle.
# review: new
pgp-find-unavailable = Nøgler kunne ikke slås op lige nu: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org har sendt et bekræftelseslink til { $addresses }. Din nøgle bliver offentliggjort der, når du klikker på det.
# review: new
pgp-publish-done = Din nøgle er offentliggjort på keys.openpgp.org for { $addresses }.
# review: new
pgp-publish-failed = Nøglen kunne ikke offentliggøres: { $error }
# review: changed
pgp-keyserver-off = Søgning efter nøgler på keys.openpgp.org er slået fra under { $settings }.
# review: new
pgp-keyserver-off = Opslag af nøgler på keys.openpgp.org er slået fra i Indstillinger.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Krypteret og signeret: kun du og { $addresses } kan læse den.
   *[other] Krypteret og signeret: kun du og dens { $count } modtagere kan læse den.
}
# review: new
pgp-compose-encrypt-ready = Den bliver krypteret og signeret. Tilføj modtagere, hvis nøgler du har.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } har ingen nøgle, så meddelelsen kan ikke krypteres endnu.
   *[other] { $count } modtagere har ingen nøgle, så meddelelsen kan ikke krypteres endnu: { $addresses }.
}
# review: new
pgp-compose-looking = Søger efter nøglerne til { $addresses }...
# review: new
pgp-compose-signed = Signeret: modtagerne kan kontrollere, at den kommer fra dig og ikke er blevet ændret.
# review: new
pgp-compose-reply-clear = Ikke krypteret, selvom den meddelelse, den besvarer eller videresender, var det.
# review: new
pgp-compose-encrypted-files = Der er vedhæftet filer fra en krypteret meddelelse, så denne meddelelse kan kun sendes krypteret. Slå Krypter til, eller fjern de filer.
# review: new
pgp-compose-sign-tip = Signer meddelelsen med din nøgle, så modtagerne kan kontrollere, at den kommer fra dig og ikke er blevet ændret
# review: new
pgp-compose-sign-tip-encrypted = En krypteret meddelelse er altid signeret
# review: new
pgp-compose-encrypt-tip = Krypter meddelelsen, så kun du og dens modtagere kan læse den
# review: new
pgp-compose-make-key = Du har endnu ingen nøgle til { $address }. Vil du oprette en nu? Med den kan dine meddelelser signeres og krypteres.
# review: new
pgp-compose-key-unusable = Din nøgle til { $address } kan ikke bruges ({ $state }). Åbn Krypteringsnøgler for at importere sikkerhedskopien af den eller oprette en ny nøgle.
# review: new
pgp-compose-encrypt-off-quote = Denne meddelelse citerer eller videresender en krypteret meddelelse. Uden kryptering kan den ikke sendes, før du fjerner det, den citerer. Vil du slå kryptering fra alligevel?
# review: new
pgp-compose-encrypt-off-reply = Denne meddelelse besvarer eller videresender en krypteret meddelelse. Uden kryptering kan alle, der håndterer din meddelelse undervejs, læse den. Vil du slå kryptering fra?
# review: new
pgp-recipient-verified = Nøglen er bekræftet
# review: new
pgp-recipient-found = Nøglen er ikke bekræftet
# review: new
pgp-recipient-own = Din egen nøgle
# review: new
pgp-recipient-looking = Søger efter en nøgle...
# review: new
pgp-recipient-missing = Ingen nøgle
# review: new
pgp-recipient-not-found = Ingen nøgle: der blev ikke fundet nogen den { $date }
# review: new
pgp-recipient-unusable = Nøglen kan ikke bruges: { $state }
# review: new
pgp-recipients-intro = Meddelelsen krypteres til hver modtagers nøgle og til din.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Én modtager har ingen nøgle at kryptere til. Find modtagerens nøgle, fjern modtageren fra denne meddelelse, eller send den uden kryptering.
   *[other] { $count } modtagere har ingen nøgle at kryptere til. Find deres nøgler, fjern dem fra denne meddelelse, eller send den uden kryptering.
}
# review: new
pgp-details-part = Del { $number }: { $label }
# review: new
pgp-details-signed = Signeret { $when } med nøglen { $key }
# review: new
pgp-details-unknown-key = Signeret med nøglen { $key }, som du ikke har
# review: new
pgp-details-opened = Krypteret til din nøgle { $key }
# review: new
pgp-details-for = Krypteret til { $keys }
# review: new
pgp-details-plain = Ikke signeret og ikke krypteret
# review: new
pgp-bar-parts = Denne meddelelse har { $count } dele: { $list }. Hver del viser, hvordan den er beskyttet.
# review: new
pgp-bar-count-verified = { $count } bekræftet
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 signeret eller krypteret
   *[other] { $count } signeret eller krypteret
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 kræver opmærksomhed
   *[other] { $count } kræver opmærksomhed
}
# review: new
pgp-bar-count-neutral = { $count } uden bekræftet signatur
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Indstillinger
# review: new
setup-part-preferences = Vinduesindstillinger
# review: new
setup-part-accounts = Konti
# review: new
setup-part-sign-in-apps = Login-apps
# review: new
setup-part-contacts = Kontakter og grupper
# review: new
setup-part-keys = Krypteringsnøgler
# review: new
setup-part-rules = Meddelelsesregler
# review: new
setup-part-trusted-senders = Betroede afsendere
# review: new
setup-holds-settings = { $count ->
    [one] 1 indstilling
   *[other] { $count } indstillinger
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 vinduesindstilling
   *[other] { $count } vinduesindstillinger
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 konto
   *[other] { $count } konti
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 login-app
   *[other] { $count } login-apps
}
# review: new
setup-holds-built-in = Hvilke indbyggede login-apps der er slået til
# review: new
setup-holds-contacts = { $count ->
    [one] 1 kontakt
   *[other] { $count } kontakter
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 gruppe
   *[other] { $count } grupper
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 af dine egne nøgler
   *[other] { $count } af dine egne nøgler
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 nøgle tilhørende en kontakt
   *[other] { $count } nøgler tilhørende kontakter
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 regel
   *[other] { $count } regler
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 betroet afsender
   *[other] { $count } betroede afsendere
}
# review: new
setup-sign-in-password = Adgangskode
# review: new
setup-account-secret-password = Adgangskoden er i filen.
# review: new
setup-account-secret-token = Login er i filen.
# review: new
setup-account-asks-password = Den beder om adgangskoden efter importen.
# review: new
setup-account-signs-in-again = Du logger på den igen efter importen.
# review: new
setup-account-here = Den er allerede konfigureret her, så den springes over.
# review: new
setup-account-no-app = Den logger på med { $app }, som ikke er konfigureret her. Importer også login-apps.
# review: new
setup-invalid-address = »{ $address }« er ikke en e-mailadresse.
# review: new
setup-invalid-server = { $server }-serveren har intet brugbart navn eller port.
# review: new
setup-invalid-user = Den har intet brugernavn.
# review: new
setup-invalid-sign-in = Den logger på på en måde, Inbox Classic ikke kender.
# review: new
setup-error-empty = Filen er tom.
# review: new
setup-error-too-large = Filen er for stor til at være en Inbox Classic-opsætning.
# review: new
setup-error-not-setup = Denne fil er ikke en Inbox Classic-opsætning.
# review: new
setup-error-damaged = Opsætningsfilen er beskadiget og kan ikke læses.
# review: new
setup-error-newer = Denne opsætning blev gemt af en nyere Inbox Classic ({ $version }). Opdater Inbox Classic, og importer den så igen.
# review: new
setup-error-needs-passphrase = Denne opsætning er beskyttet af en adgangsfrase. Skriv den adgangsfrase, den blev gemt med.
# review: new
setup-error-wrong-passphrase = Det er ikke den adgangsfrase, opsætningen blev gemt med.
# review: new
setup-error-changed = Opsætningsfilen blev ændret eller beskadiget, efter den blev gemt, så den kan ikke importeres.
# review: new
setup-error-read = Opsætningsfilen kunne ikke læses: { $error }
# review: new
setup-error-write = Opsætningen kunne ikke gemmes: { $error }
# review: new
setup-error-no-parts = Vælg mindst én del.
# review: new
setup-left-out = { $count ->
    [one] 1 post i { $part } kan ikke bruges og udelades.
   *[other] { $count } poster i { $part } kan ikke bruges og udelades.
}
# review: new
setup-imported-settings = Indstillingerne blev erstattet.
# review: new
setup-imported-preferences = Vinduesindstillingerne blev erstattet.
# review: new
setup-added-accounts = { $count ->
    [one] Tilføjede 1 konto.
   *[other] Tilføjede { $count } konti.
}
# review: new
setup-skipped-here = { $address } er allerede konfigureret her, så den blev sprunget over.
# review: new
setup-skipped-no-app = { $address } blev sprunget over: den logger på med { $app }, som ikke er konfigureret her.
# review: new
setup-skipped-invalid = { $address } blev sprunget over: { $reason }
# review: new
setup-asks-password = { $address } beder om sin adgangskode, når den opretter forbindelse.
# review: new
setup-signs-in-again = { $address } beder dig logge på igen, når den opretter forbindelse.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Tilføjede 1 login-app.
   *[other] Tilføjede { $count } login-apps.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 login-app er allerede konfigureret her.
   *[other] { $count } login-apps er allerede konfigureret her.
}
# review: new
setup-added-contacts = { $count ->
    [one] Tilføjede 1 kontakt til adressekartoteket.
   *[other] Tilføjede { $count } kontakter til adressekartoteket.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 kontakt er allerede i adressekartoteket.
   *[other] { $count } kontakter er allerede i adressekartoteket.
}
# review: new
setup-added-groups = { $count ->
    [one] Tilføjede eller fuldførte 1 gruppe.
   *[other] Tilføjede eller fuldførte { $count } grupper.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Tilføjede 1 af dine egne nøgler.
   *[other] Tilføjede { $count } af dine egne nøgler.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Tilføjede 1 nøgle tilhørende en kontakt.
   *[other] Tilføjede { $count } nøgler tilhørende kontakter.
}
# review: new
setup-added-rules = { $count ->
    [one] Tilføjede 1 meddelelsesregel.
   *[other] Tilføjede { $count } meddelelsesregler.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 meddelelsesregel findes allerede her.
   *[other] { $count } meddelelsesregler findes allerede her.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 meddelelsesregel gælder en konto, der ikke er her, så den blev sprunget over.
   *[other] { $count } meddelelsesregler gælder konti, der ikke er her, så de blev sprunget over.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 meddelelsesregel flytter meddelelser til en mappe, der dukker op, når kontoen er synkroniseret.
   *[other] { $count } meddelelsesregler flytter meddelelser til mapper, der dukker op, når kontiene er synkroniseret.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Tilføjede 1 betroet afsender.
   *[other] Tilføjede { $count } betroede afsendere.
}
# review: new
setup-nothing = Intet blev importeret.
# review: new
setup-account-servers = { $imap } og { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic-indstillinger og -konti
# review: new
setup-skipped-unreachable = { $name } blev sprunget over: dens logintjeneste kunne ikke nås. Tilføj den igen under Login-apps.
# review: new
attachment-runs-programs = Filen »{ $name }« kan køre programmer, så Inbox Classic åbner den ikke. Gem den, og åbn den selv, hvis du stoler på, hvor den kommer fra.
# review: new
attachment-decrypted-note = Denne vedhæftede fil kommer fra en krypteret meddelelse. For at åbne den gemmer Inbox Classic den dekrypteret på denne computer i en af dine mapper, som Inbox Classic tømmer efter et døgn.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Serveren flyttede ikke { $messages } til { $folder }, så den er tilbage i { $from }: { $reason }
   *[other] Serveren flyttede ikke { $messages } til { $folder }, så de er tilbage i { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Serveren slettede ikke { $messages }, så den er tilbage i { $from }: { $reason }
   *[other] Serveren slettede ikke { $messages }, så de er tilbage i { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Serveren arkiverede ikke { $messages }, så den er tilbage i { $from }: { $reason }
   *[other] Serveren arkiverede ikke { $messages }, så de er tilbage i { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Serveren markerede ikke { $messages } som læst, så den er ulæst igen: { $reason }
   *[other] Serveren markerede ikke { $messages } som læste, så de er ulæste igen: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Serveren markerede ikke { $messages } som ulæst, så den er læst igen: { $reason }
   *[other] Serveren markerede ikke { $messages } som ulæste, så de er læste igen: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Serveren ændrede ikke flagene på { $messages }, så den er som før: { $reason }
   *[other] Serveren ændrede ikke flagene på { $messages }, så de er som før: { $reason }
}
