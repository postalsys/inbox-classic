# Dansk. Udkast, venter på gennemsyn af en person med dansk som modersmål (se core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Danish: [one] and *[other].

## Counts and sizes

messages = { $count ->
    [one] { $count } meddelelse
   *[other] { $count } meddelelser
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
send-delay-off = Fra
send-delay-seconds = { $count ->
    [one] { $count } sekund
   *[other] { $count } sekunder
}
# the status bar: "12 meddelelser, 3 ulæste"
list-counts = { $messages }, { $unread ->
    [one] 1 ulæst
   *[other] { $unread } ulæste
}
list-counts-selected = { $messages }, { $unread ->
    [one] 1 ulæst
   *[other] { $unread } ulæste
    }, { $selected } markerede
# the status bar while searching: "12 fundet, 3 ulæste"
list-counts-found = { $found } fundet, { $unread ->
    [one] 1 ulæst
   *[other] { $unread } ulæste
}
list-counts-found-selected = { $found } fundet, { $unread ->
    [one] 1 ulæst
   *[other] { $unread } ulæste
    }, { $selected } markerede
list-counts-none = Ingen meddelelser fundet

## Special folders, as Outlook names them in Danish

folder-inbox = Indbakke
folder-sent = Sendt post
folder-deleted = Slettet post
folder-drafts = Kladder
folder-junk = Uønsket mail
folder-archive = Arkiv

## The reading pane

reader-no-message = Der er ikke markeret nogen meddelelse.
reader-downloading = Henter meddelelsen…
reader-downloading-detail = Meddelelsen vises her, når den er hentet.
reader-downloading-size = Meddelelsen fylder { $size }. Den vises her, når den er hentet.
reader-failed = Meddelelsen kunne ikke hentes
reader-failed-network = Der kunne ikke oprettes forbindelse til mailserveren ({ $reason }).
reader-failed-sign-in = Mailserveren godtog ikke login ({ $reason }). Kontrollér adgangskoden, eller log på igen under Filer > Konti.
reader-failed-security = Der kunne ikke oprettes en sikker forbindelse til mailserveren ({ $reason }).
reader-failed-other = Mailserveren svarede: { $reason }.
reader-retry-note = Inbox Classic prøver igen, når forbindelsen til kontoen er genoprettet.
reader-unreadable = Meddelelsen kan ikke vises: { $error }
message-source-title = Meddelelseskilde: { $subject }
message-source-untitled = Meddelelseskilde

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Fra
header-date = Dato
header-to = Til
header-cc = Cc
header-sent = Sendt
header-subject = Emne
header-security = Sikkerhed
header-part = Del { $number }
quote-original = ----- Oprindelig meddelelse -----
fold-show-earlier = Vis de tidligere meddelelser

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Din meddelelse blev ikke leveret
bounce-delayed = Din meddelelse er ikke leveret endnu
bounce-delayed-note = Din mailserver prøver stadig at levere den. Du behøver ikke at sende den igen.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Vis den meddelelse, der kom retur
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Vis den forsinkede meddelelse
bounce-what-to-do = Det kan du gøre:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Du behøver ikke gøre noget endnu. Hvis meddelelsen stadig ikke kan leveres, får du en ny meddelelse om det.
bounce-delayed-row-do = Du behøver ikke gøre noget endnu. Din mailserver prøver stadig at levere meddelelsen. Du får besked, hvis det ikke lykkes.
# folds the receiving server's own words
bounce-details = Detaljer
# a recipient the notice does not name
bounce-someone = En modtager
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Rapporteret af: { $server }
bounce-retry-minutes = Modtagerens server bad om at vente { $count ->
    [one] et minut
   *[other] { $count } minutter
} før næste forsøg.
bounce-retry-hours = Modtagerens server bad om at vente { $count ->
    [one] en time
   *[other] { $count } timer
} før næste forsøg.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Blokeringsliste: { $lists }
bounce-user-unknown = Adressen findes ikke
bounce-user-unknown-why = Modtagerens server har ingen postkasse med denne adresse. Den kan være stavet forkert, eller personen bruger den måske ikke længere.
bounce-user-unknown-do = Kontrollér, at adressen er skrevet korrekt, eller bed modtageren om den aktuelle adresse.
bounce-invalid-address = Adressen er ikke gyldig
bounce-invalid-address-why = Adressen har et ugyldigt format, så der kan ikke sendes mail til den.
bounce-invalid-address-do = Se efter tastefejl, fx et mellemrum, et manglende bogstav eller ingenting efter @.
bounce-mailbox-disabled = Postkassen er lukket
bounce-mailbox-disabled-why = Adressen findes, men postkassen er slået fra eller bruges ikke længere.
bounce-mailbox-disabled-do = Kontakt modtageren på en anden måde, og bed om en aktuel e-mailadresse.
bounce-mailbox-full = Postkassen er fuld
bounce-mailbox-full-why = Modtagerens postkasse har ikke plads til ny mail.
bounce-mailbox-full-do = Send den igen om nogle dage, eller giv personen besked på en anden måde. Store vedhæftede filer afvises først.
bounce-spam-blocked = Afvist som spam
bounce-spam-blocked-why = Modtagerens server opfattede meddelelsen som spam.
bounce-spam-blocked-do = Send den igen uden det, der ligner spam, fx mange links, forkortede links eller en stor vedhæftet fil. Hvis det bliver ved med at ske, så spørg din mailudbyder.
bounce-virus-detected = Afvist på grund af virus
bounce-virus-detected-why = Modtagerens server fandt en virus eller andet skadeligt indhold i meddelelsen eller dens vedhæftede filer.
bounce-virus-detected-do = Kontrollér de vedhæftede filer med et antivirusprogram. Nogle servere afviser alle programmer og arkiver, så del i stedet sådanne filer som et link.
bounce-ip-blocklisted = Din mailserver er på en blokeringsliste
bounce-ip-blocklisted-why = Modtagerens server afviser mail fra din mailserver, fordi dens IP-adresse står på en blokeringsliste.
bounce-ip-blocklisted-do = Problemet ligger ikke i meddelelsen. Videresend denne fejlmeddelelse til din mailudbyder, og bed om at få serveren fjernet fra listen.
bounce-domain-blocklisted = Et domæne er på en blokeringsliste
bounce-domain-blocklisted-why = Modtagerens server afviser meddelelsen, fordi domænet i din adresse eller i et af meddelelsens links står på en blokeringsliste.
bounce-domain-blocklisted-do = Prøv at sende meddelelsen uden links. Hvis den ikke indeholder links, skal du videresende fejlmeddelelsen til administratoren for dit maildomæne.
bounce-policy-blocked = Afvist på grund af regler på modtagerens server
bounce-policy-blocked-why = Reglerne på modtagerens server blokerer meddelelsen, fx på grund af størrelse, vedhæftede filer eller afsender.
bounce-policy-blocked-do = Serverens svar under Detaljer forklarer ofte årsagen. Spørg modtageren, om det er muligt at modtage denne type mail.
bounce-geo-blocked = Afvist på grund af serverens land eller netværk
bounce-geo-blocked-why = Modtagerens server tager ikke imod mail fra det land eller netværk, din mailserver er i.
bounce-geo-blocked-do = Kontakt personen på en anden måde, eller spørg din mailudbyder om det.
bounce-relay-denied = Serveren ville ikke sende den videre
bounce-relay-denied-why = En server nægtede at levere meddelelsen videre, ofte fordi den blev sendt uden login eller gennem en server, der ikke håndterer denne modtager.
bounce-relay-denied-do = Kontrollér kontoens udgående server under Filer > Konti, og sørg for, at kontoen logger på serveren ved afsendelse.
bounce-auth-failure = Din afsenderadresse kunne ikke bekræftes
bounce-auth-failure-why = Modtagerens server kunne ikke bekræfte, at meddelelsen virkelig kom fra dit domæne (SPF, DKIM eller DMARC).
bounce-auth-failure-do = Videresend denne fejlmeddelelse til administratoren for dit maildomæne, så indstillingerne kan blive rettet. Indtil da kan det hjælpe at sende via din udbyders egen server.
bounce-rate-limited = For meget mail på én gang
bounce-rate-limited-why = Modtagerens server tager indtil videre imod færre meddelelser fra din mailserver.
bounce-rate-limited-do = Vent lidt, og send den igen. Når du skriver til mange personer, så send til færre ad gangen.
bounce-greylisting = Levering midlertidigt udsat
bounce-greylisting-why = Modtagerens server beder ukendte afsendere om at prøve igen lidt senere. Det er en almindelig metode til at begrænse spam.
bounce-greylisting-do = Du behøver ikke gøre noget. Mailservere prøver automatisk igen, og meddelelsen leveres som regel inden for en time.
bounce-server-error = Modtagerens server havde et problem
bounce-server-error-why = Modtagerens server kunne ikke kontaktes eller kunne ikke modtage meddelelsen på grund af en fejl på serveren.
bounce-server-error-do = Send den igen senere. Hvis det bliver ved med at mislykkes, så kontrollér delen af adressen efter @ for tastefejl.
bounce-unknown = Ikke leveret
bounce-unknown-why = Fejlmeddelelsen angiver ikke en klar årsag.
bounce-unknown-do = Serverens svar under Detaljer kan give flere oplysninger. Videresend fejlmeddelelsen til din mailudbyder, hvis svaret ikke hjælper.

## Several messages selected

selection-title = { $count ->
    [one] { $count } meddelelse markeret
   *[other] { $count } meddelelser markeret
}
selection-unread = { $count ->
    [one] 1 ulæst
   *[other] { $count } ulæste
}
selection-flagged = { $count } med flag
delete-for-good-one = Denne meddelelse bliver slettet permanent. Vil du slette den?
delete-for-good-all = Disse { $count } meddelelser bliver slettet permanent. Vil du slette dem?
delete-for-good-some = { $count } af de { $total } meddelelser bliver slettet permanent. Vil du slette meddelelserne?
done-read = { $count ->
    [one] Markerede { $messages } som læst
   *[other] Markerede { $messages } som læste
}
done-unread = { $count ->
    [one] Markerede { $messages } som ulæst
   *[other] Markerede { $messages } som ulæste
}
done-flagged = { $count ->
   *[other] Satte flag på { $messages }
}
done-unflagged = Fjernede flaget fra { $messages }
done-deleted-for-good = { $count ->
   *[other] Slettede { $messages } permanent
}
done-archived = { $count ->
   *[other] Arkiverede { $messages }
}
done-moved = { $count ->
   *[other] Flyttede { $messages } til { $folder }
}
done-copied = { $count ->
   *[other] Kopierede { $messages } til { $folder }
}
done-moving = { $count ->
   *[other] Flytter { $messages } til { $folder }...
}
done-copying = { $count ->
   *[other] Kopierer { $messages } til { $folder }...
}
done-moved-back = { $count ->
   *[other] Flyttede { $messages } tilbage til { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Følger samtalen
   *[other] Følger { $count } samtaler
}
done-unwatched = { $count ->
    [one] Følger ikke længere samtalen
   *[other] Følger ikke længere { $count } samtaler
}
done-ignored = { $count ->
    [one] Ignorerer samtalen
   *[other] Ignorerer { $count } samtaler
}
done-unignored = { $count ->
    [one] Ignorerer ikke længere samtalen
   *[other] Ignorerer ikke længere { $count } samtaler
}
their-folders = deres mapper
undo-move = Fortryd flytning
undo-delete = Fortryd sletning
undo-archive = Fortryd arkivering
undo-junk = Fortryd markering som uønsket
undo-not-junk = Fortryd markering som ikke uønsket
undo-send = Fortryd afsendelse
nothing-to-undo = Der er intet at fortryde.
messages-gone = Meddelelserne er der ikke længere.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Denne mappe kan ikke indeholde meddelelser.
not-archived-here = Meddelelser i denne mappe kan ikke arkiveres.
not-emptied-here = Kun Slettet post og Uønsket mail kan tømmes.
next-unread-question = Der er ikke flere ulæste meddelelser i { $folder }.

    Vil du gå til { $next }, den næste mappe med ulæste meddelelser?
no-unread-left = Der er ikke flere ulæste meddelelser.
empty-question = { $count ->
    [one] Vil du tømme { $folder }?

        Meddelelsen i mappen bliver slettet permanent. Den kan ikke hentes tilbage.
   *[other] Vil du tømme { $folder }?

        De { $messages } i mappen bliver slettet permanent. De kan ikke hentes tilbage.
}
no-junk-folder = Denne konto har ingen mappe til uønsket mail, som meddelelserne kan flyttes til.
no-inbox-folder = Denne konto har ingen indbakke, som meddelelserne kan flyttes til.
# the status bar after a flag in a colour: "Satte rødt flag på 2 meddelelser"
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

move-window-title-move = { $count ->
    [one] Flyt meddelelse
   *[other] Flyt { $count } meddelelser
}
move-window-title-copy = { $count ->
    [one] Kopier meddelelse
   *[other] Kopier { $count } meddelelser
}
move-window-prompt-move = { $count ->
    [one] Flyt den markerede meddelelse til:
   *[other] Flyt de { $count } markerede meddelelser til:
}
move-window-prompt-copy = { $count ->
    [one] Kopier den markerede meddelelse til:
   *[other] Kopier de { $count } markerede meddelelser til:
}
# the folders used last, over the folder tree
targets-recent = Senest brugte
# the folder the messages are in, which can not be chosen
target-current = { $folder } (aktuel)
# a folder used last, with its account when there are several: "Arkiv (Arbejde)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Flytter { $done } af { $messages } til { $folder }...
transfer-copying = Kopierer { $done } af { $messages } til { $folder }...
transfer-another-account = en anden konto
transfer-folder-gone = mappen, den skulle til, findes ikke længere
transfer-not-on-server = meddelelsen er ikke længere på serveren
transfer-not-moved = { $count ->
   *[other] { $messages } kunne ikke flyttes til en anden konto: { $reason }
}
transfer-not-copied = { $count ->
   *[other] { $messages } kunne ikke kopieres til en anden konto: { $reason }
}
transfer-none-moved = Ingen meddelelser kunne flyttes
transfer-none-copied = Ingen meddelelser kunne kopieres

## Messages as files

export-not-in-time = meddelelsen kunne ikke hentes i tide
export-not-saved = { $failed } af { $messages } kunne ikke gemmes ({ $problems })
export-not-attached = meddelelserne kunne ikke vedhæftes: { $error }
# the status bar after Save As with several: "Gemte 3 meddelelser i Skrivebord"
saved-to = { $count ->
   *[other] Gemte { $messages } i { $folder }
}
download-progress = Henter { $done } af { $total }
download-done = Hentede { $size }
downloading-messages = { $count ->
   *[other] Henter { $messages }...
}
# the status bar after files are dropped on a folder: "Lagde 3 meddelelser i Arkiv"
import-put = { $count ->
   *[other] Importerede { $messages } til { $folder }
}
import-not-put = Disse meddelelser blev ikke importeret til mappen:

    { $problems }

## Problems the windows show

error-store = lokalt lager: { $error }
error-not-found = ikke fundet
error-closed = lukker ned
error-other-account = browseren loggede på { $email }, ikke på denne konto
# a password or sign-in the mail server refused, with the server's words
failure-authentication = serveren godtog ikke login ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = forbindelsen til serveren mislykkedes ({ $reason })
error-in-use = den kan ikke fjernes, så længe konti logger på med den: { $accounts }
error-turned-off = denne login-app er slået fra for nye konti
error-folder-name = mappenavnet skal være på 1 til 200 tegn og må ikke indeholde kontroltegn
error-folder-separator = et mappenavn må ikke indeholde »{ $separator }« på denne server
error-folder-special = Indbakke og systemmapperne kan ikke omdøbes eller slettes
error-no-recipients = meddelelsen har ingen modtagere
error-bad-address = »{ $address }« er ikke en e-mailadresse
error-not-own-address = { $address } er ikke en af kontoens afsenderadresser. Føj den til »Andre adresser, du sender fra« i kontoens egenskaber.
rule-query-refused = Regler kan ikke filtrere efter mappe eller dato ({ $words }).
rule-no-query = Angiv søgekriterier for indgående meddelelser.
rule-no-action = Vælg mindst én handling for reglen.
error-attachment = { $path } kunne ikke læses: { $error }
error-no-drafts = kontoen har ingen mappe til kladder, som meddelelsen kan gemmes i
error-draft-attachment = en vedhæftet fil i kladden kunne ikke gemmes: { $error }
error-password-not-saved = adgangskoden kunne ikke gemmes til næste gang, du starter programmet: { $error }
error-sign-in-not-saved = de nye loginoplysninger kunne ikke gemmes til næste gang, du starter programmet: { $error }
error-import-unreadable = { $path } kan ikke læses: { $error }
error-import-too-large = { $path } er større end 50 MB
error-import-not-mail = { $path } er ikke en e-mailmeddelelse
error-list-answered = mailinglistens server svarede med status { $status }
error-not-built = meddelelsen kunne ikke oprettes
error-outbox-waits = { $count ->
    [one] meddelelsen venter i Udbakke. Inbox Classic prøver at sende den igen ved næste Send/modtag
   *[other] { $count } meddelelser venter i Udbakke. Inbox Classic prøver at sende dem igen ved næste Send/modtag
}
error-draft-not-removed = den tidligere kladde af meddelelsen kunne ikke fjernes fra Kladder: { $reason }
error-sent-but = meddelelsen blev sendt, men { $problem }
error-sent-still-in-outbox = den ligger stadig i Udbakke: { $error }
error-sent-no-copy = der kunne ikke gemmes en kopi i Sendt post: { $reason }
error-no-password = ingen adgangskode til denne konto
error-no-sign-in = der er ingen gemte loginoplysninger til denne konto
error-provider-missing = denne version kan ikke logge på { $provider }: er login-appen fjernet?
error-provider-servers = kontoens servere passer ikke med login-appens servere
error-app-scopes = { $reason }. Mailserveren godtog ikke login-appens token: kontrollér, at appens tilladelser (scopes) giver adgang til mail
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google har endnu ikke godkendt Inbox Classic, så kun testbrugere kan logge på med den. Brug din egen login-app til Google eller en appadgangskode, eller slå den til under Login-apps (Filer > Konti), hvis du er testbruger.
sign-in-off-other = Den blev slået fra under Login-apps (Filer > Konti), hvor den kan slås til igen.
sign-in-app-no-name = login-appen skal have et navn
sign-in-app-no-client = klient-id mangler
sign-in-app-no-scopes = login-appen skal have de tilladelser (scopes), der giver adgang til mail
sign-in-app-bad-host = serveradressen for { $server } mangler eller er ikke et gyldigt værtsnavn
sign-in-app-plain = serveren til { $server } skal bruge SSL/TLS eller STARTTLS
sign-in-app-not-checked = udstederen er ikke kontrolleret endnu
sign-in-app-issuer-changed = udstederen er ændret: skriv klienthemmeligheden igen, eller fjern den
sign-in-register-google = Opret en OAuth-klient af typen Desktop app i Google Cloud Console med tilladelsen (scope) https://mail.google.com/ på dens samtykkeskærm. Så længe appen er i test, kan kun dens testbrugere logge på.
sign-in-register-microsoft = Registrer en app i Microsoft Entra. Vælg platformen Mobile and desktop applications, angiv omdirigerings-URI’en http://localhost, og tillad offentlige klientflows. Tilføj de delegerede tilladelser IMAP.AccessAsUser.All, SMTP.Send og offline_access. Hvis appen kun skal bruges i din organisation, skal udstederen være https://login.microsoftonline.com/<tenant-id>/v2.0.
sign-in-register-other = Registrer en offentlig klient til et installeret program med omdirigerings-URI’en nedenfor. Udbyderen skal tillade en vilkårlig port på adressen (RFC 8252). Tilføj den tilladelse (scope), udbyderen kræver for adgang til mail.

## Calendar invitations

repeats = Gentages
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
repeats-on = { $repeats } på { $days }
# "Hver uge, 10 gange"
repeats-times = { $count ->
    [one] { $repeats }, én gang
   *[other] { $repeats }, { $count } gange
}
day-monday = mandag
day-tuesday = tirsdag
day-wednesday = onsdag
day-thursday = torsdag
day-friday = fredag
day-saturday = lørdag
day-sunday = søndag

## AI agents

agent-level-read = Læse mail: mapper, meddelelseslisten, søgning og meddelelser
agent-level-organize = Organisere mail: ændre læst/ulæst og flag, markere som uønsket, flytte og slette til Slettet post
agent-level-drafts = Skrive kladder, som du selv sender
agent-level-send = Sende mail, men kun efter din godkendelse af hver meddelelse
agent-connect-title = { $program } vil bruge din mail
agent-connect-detail = En AI-agent har bedt om adgang til Inbox Classic. Vælg, hvad den må gøre, og hvilke konti den må se. Du kan ændre det senere under Funktioner > AI-agenter.

    Agenter læser mail fra andre, som kan indeholde vildledende instruktioner. Inbox Classic beder altid om din godkendelse, før agenten sender mail gennem programmet.
agent-reply-to = Svar på »{ $subject }«
agent-reply-all-on = Svar alle på »{ $subject }«
agent-forward-of = Videresendelse af »{ $subject }«
agent-never-written-one = Du har aldrig skrevet til { $address }.
agent-never-written-many = Du har aldrig skrevet til { $count } af disse adresser.
agent-send-title = { $program } vil sende denne meddelelse
agent-send-detail = Kontrollér modtagerne og meddelelsens indhold. Når du bekræfter, venter meddelelsen { $seconds } sekunder i Udbakke, hvor du stadig kan slette den.
agent-change-title = Tilladelser for { $program }
agent-change-allowed = Rediger tilladelserne for dette programs AI-agenter til at arbejde med din mail.
agent-change-refused = Du har afvist adgang for dette program. Klik på Tillad for at give dets agenter adgang til din mail.
agent-log-taken-back = { $entry } (fortrudt)
agent-files = Filer: { $files }
agent-undo-refused = Det kan ikke fortrydes.
agent-undo-refused-why = Det kan ikke fortrydes: { $reason }.
agent-undo-impossible = dette kan ikke fortrydes
agent-undo-not-in-folder = meddelelsen er ikke længere i den mappe
agent-undo-not-arrived = meddelelsen er endnu ikke i den mappe, den blev flyttet til
agent-undo-sent = meddelelsen er allerede sendt
agent-original-not-downloaded = den oprindelige meddelelse er ikke hentet endnu. Åbn den først
agent-turned-away = Afvist
agent-can-nothing = Intet
agent-can-read = læse
agent-can-organize = organisere
agent-can-drafts = skrive kladder
agent-can-send = sende efter din godkendelse
# "Læse, organisere og skrive kladder"
agent-can-list = { $first } og { $last }
agent-accounts = { $count ->
    [0] ingen konti
    [one] 1 konto
   *[other] { $count } konti
}
# "Læse og organisere; 1 konto"
agent-access = { $can }; { $accounts }
agent-unreadable = Denne meddelelse kan ikke læses.
agent-encrypted-original = Meddelelsen er krypteret. En agent kan ikke svare på den eller videresende den gennem Inbox Classic, da agenten ikke kan kryptere mail her.
# review: new
agent-encrypted = Denne meddelelse er krypteret. Kun brugeren kan læse den, i Inbox Classic.
# review: new
list-encrypted = Krypteret meddelelse
agent-log-composed = Åbnede »{ $subject }« i en ny meddelelse, som du kan gøre færdig
agent-log-refused = Du sendte ikke »{ $subject }«
agent-log-sent = Satte »{ $subject }« i kø til afsendelse til { $to }
agent-log-draft = Gemte kladden »{ $subject }«
agent-log-read = Markerede »{ $subject }« som læst
agent-log-unread = Markerede »{ $subject }« som ulæst
agent-log-flagged = Satte flag på »{ $subject }«
agent-log-unflagged = Fjernede flaget fra »{ $subject }«
agent-log-deleted = Slettede »{ $subject }«
agent-log-moved = Flyttede »{ $subject }« til { $folder }
agent-log-junk = Markerede »{ $subject }« som uønsket
agent-log-not-junk = Markerede »{ $subject }« som ikke uønsket
agent-log-archived = Arkiverede »{ $subject }«
agent-log-folder = Oprettede mappen »{ $name }«
agent-log-unsubscribed = Afmeldte mailinglisten bag »{ $subject }«

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Skift
key-del = Delete
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = udbyderen gav intet opdateringstoken
sign-in-no-account = udbyderen oplyste ikke, hvilken konto der loggede på
sign-in-not-finished = login er ikke afsluttet
secrets-unavailable = { $store } er ikke tilgængelig
secrets-unavailable-why = { $store } er ikke tilgængelig: { $error }
secrets-windows = Legitimationsstyring
secrets-mac = nøgleringen
secrets-linux = systemets nøglering (Secret Service)
error-no-such-file = filen findes ikke
cards-file-too-big = Denne fil er for stor til at være et adressekartotek.
ui-sender-added = { $name } blev føjet til adressekartoteket.
ui-sender-known = { $name } er allerede i adressekartoteket.
ui-sender-none = Afsenderen af denne meddelelse har ingen e-mailadresse, der kan tilføjes.
card-name-needed = Kontakten har hverken navn eller e-mailadresse.
# a file of Import Address Book that could not be read: "contacts.vcf: filen findes ikke"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Kode fra { $domain }
otp-copy = Kopier
otp-note = Indtast den kun på en side fra { $domain }.
otp-old = Koden blev sendt mere end en time før, du åbnede meddelelsen, og er sandsynligvis udløbet.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } deltager
       *[other] { $count } deltagere
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } er din kode til { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Gyldig
pgp-key-expires = Gyldig til { $date }
pgp-key-expired = Udløb { $date }
pgp-key-revoked = Tilbagekaldt
pgp-key-revoked-why = Tilbagekaldt: { $reason }
pgp-key-not-valid = Ikke gyldig
pgp-key-locked = Nøglen kan ikke bruges, fordi dens beskyttelsesnøgle mangler i { $store }. Importer en sikkerhedskopi af den private nøgle igen.
pgp-source-own = Oprettet i Inbox Classic
pgp-source-file = Importeret fra en fil
pgp-source-paste = Indsat
pgp-source-attachment = Fra en meddelelse
pgp-source-vcard = Fra et kontaktkort
pgp-source-wkd = Fra afsenderens mailudbyder
pgp-source-keyserver = Fra keys.openpgp.org
pgp-source-autocrypt = Fra en meddelelses Autocrypt-header
pgp-error-no-store = Private nøgler beskyttes med en nøgle i { $store }, som ikke kan bruges: { $error }
pgp-error-wrong-passphrase = Adgangsfrasen er forkert.
pgp-error-not-a-key = Dette er ikke en OpenPGP-nøgle.
pgp-error-too-large = Nøglen er for stor.
pgp-error-unusable = Nøglen bruger gammel eller svag kryptografi og kan ikke bruges.
pgp-imported-private = { $count ->
    [one] Din private nøgle blev importeret.
   *[other] { $count } private nøgler blev importeret.
}
pgp-imported-public = { $count ->
    [one] Én nøgle blev importeret.
   *[other] { $count } nøgler blev importeret.
}
pgp-imported-pending = Der bruges allerede en anden nøgle til { $addresses }. Den nye nøgle ligger klar i kontaktens egenskaber, indtil du vælger den.
pgp-error-needs-passphrase = Den private nøgle er beskyttet af en adgangsfrase. Skriv den for at importere nøglen.
pgp-error-mismatch = Den private og den offentlige nøgle hører ikke sammen. Nøglen kan være blevet ændret.
pgp-file-name-public = { $who } offentlig nøgle.asc
pgp-file-name-private = { $who } sikkerhedskopi af privat nøgle.asc
pgp-pending = Der blev fundet en anden nøgle til { $address } den { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Digitalt signeret af { $signer }, nøglens ejerskab er bekræftet
pgp-part-signed = Digitalt signeret af { $signer } (nøglens ejerskab er ikke bekræftet)
pgp-part-other = Digitalt signeret af { $signer }, som ikke er afsenderen
pgp-part-unknown-key = Digitalt signeret, men nøglen er ukendt
pgp-part-not-signed = Ikke digitalt signeret
pgp-part-not-checked = Den digitale signatur er ikke kontrolleret
pgp-part-encrypted = Krypteret. { $signature }
pgp-part-no-key = Krypteret med en nøgle, du ikke har den private del af
pgp-part-changed = Den krypterede del blev ændret undervejs og vises ikke
pgp-part-unprotected = Krypteret uden beskyttelse mod ændringer, vises ikke
pgp-part-broken = Den krypterede del kan ikke læses
pgp-why-mismatch = Den digitale signatur stemmer ikke overens med teksten
pgp-why-weak-hash = Den digitale signatur bruger { $hash }, som ikke længere er sikker
pgp-why-key-expired = Signeret efter at nøglen udløb { $date }
pgp-why-key-revoked = Signeret med en nøgle, der er tilbagekaldt
pgp-why-not-signing-key = Signeret med en nøgle, der ikke kan bruges til digital signering
pgp-why-from-future = Den digitale signatur har en dato i fremtiden
pgp-why-signature-expired = Den digitale signatur er udløbet
pgp-why-key-not-valid = Signeret med en nøgle, der ikke er gyldig
pgp-why-not-for-you = Signeret til andre modtagere og sendt videre til dig
pgp-part-pictures-loaded = { $label }. Billeder blev hentet fra internettet
pgp-error-no-own-key = Du har ingen nøgle til { $address } at signere eller kryptere med. Opret en under Funktioner > Krypteringsnøgler, eller slå Signer og Krypter fra.
pgp-error-missing-keys = { $count ->
    [one] { $addresses } har ingen nøgle at kryptere til.
   *[other] Disse modtagere har ingen nøgle at kryptere til: { $addresses }.
}
pgp-error-encrypted-quote = Denne meddelelse citerer eller videresender en krypteret meddelelse, så den kan kun sendes krypteret. Slå Krypter til, eller fjern den citerede tekst.
pgp-error-protect = Meddelelsen kunne ikke signeres eller krypteres: { $reason }
pgp-found-keys = Der er fundet nøgler til: { $addresses }.
pgp-found-none = Der blev ikke fundet nogen nøgle til { $addresses }. Bed modtageren eller modtagerne om at sende deres offentlige nøgle.
pgp-found-no-key = Der blev ikke fundet nogen nøgle.
pgp-find-unavailable = Nøgler kunne ikke slås op lige nu: { $error }
pgp-publish-pending = keys.openpgp.org har sendt et bekræftelseslink til hver af disse adresser: { $addresses }. Bekræft hver adresse, så andre kan finde din nøgle ved hjælp af den.
pgp-publish-done = Din nøgle er offentliggjort på keys.openpgp.org for { $addresses }.
pgp-publish-failed = Nøglen kunne ikke offentliggøres: { $error }
# review: changed
pgp-keyserver-off = Søgning efter nøgler på keys.openpgp.org er slået fra under { $settings }.
pgp-details-part = Del { $number }: { $label }
pgp-details-signed = Signeret { $when } med nøglen { $key }
pgp-details-unknown-key = Signeret med nøglen { $key }, som du ikke har
pgp-details-opened = Dekrypteret med din nøgle { $key }
pgp-details-for = Krypteret til { $keys }
pgp-details-plain = Hverken digitalt signeret eller krypteret
pgp-bar-parts = Denne meddelelse har { $count } dele: { $list }. Hver del viser, hvordan den er beskyttet.
pgp-bar-count-verified = { $count } med bekræftet nøgle
pgp-bar-count-good = { $count ->
    [one] 1 signeret eller krypteret
   *[other] { $count } signerede eller krypterede
}
pgp-bar-count-warning = { $count ->
    [one] 1 kræver opmærksomhed
   *[other] { $count } kræver opmærksomhed
}
pgp-bar-count-neutral = { $count } uden bekræftet digital signatur
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Indstillinger
setup-part-preferences = Vinduesindstillinger
setup-part-accounts = Konti
setup-part-sign-in-apps = Login-apps
setup-part-contacts = Kontakter og grupper
setup-part-keys = Krypteringsnøgler
setup-part-rules = Meddelelsesregler
setup-part-trusted-senders = Betroede afsendere
setup-holds-settings = { $count ->
    [one] 1 indstilling
   *[other] { $count } indstillinger
}
setup-holds-preferences = { $count ->
    [one] 1 vinduesindstilling
   *[other] { $count } vinduesindstillinger
}
setup-holds-accounts = { $count ->
    [one] 1 konto
   *[other] { $count } konti
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 login-app
   *[other] { $count } login-apps
}
setup-holds-built-in = Hvilke indbyggede login-apps der er slået til
setup-holds-contacts = { $count ->
    [one] 1 kontakt
   *[other] { $count } kontakter
}
setup-holds-groups = { $count ->
    [one] 1 gruppe
   *[other] { $count } grupper
}
setup-holds-own-keys = { $count ->
    [one] 1 af dine egne nøgler
   *[other] { $count } af dine egne nøgler
}
setup-holds-contact-keys = { $count ->
    [one] 1 nøgle tilhørende en kontakt
   *[other] { $count } nøgler tilhørende kontakter
}
setup-holds-rules = { $count ->
    [one] 1 regel
   *[other] { $count } regler
}
setup-holds-trusted-senders = { $count ->
    [one] 1 betroet afsender
   *[other] { $count } betroede afsendere
}
setup-sign-in-password = Adgangskode
setup-account-secret-password = Adgangskoden er i filen.
setup-account-secret-token = Loginoplysningerne er gemt i filen.
setup-account-asks-password = Du skal indtaste kontoens adgangskode efter importen.
setup-account-signs-in-again = Du skal logge på kontoen igen efter importen.
setup-account-here = Den er allerede konfigureret her, så den springes over.
setup-account-no-app = Den logger på med { $app }, som ikke er konfigureret her. Importer også login-apps.
setup-invalid-address = »{ $address }« er ikke en e-mailadresse.
setup-invalid-server = Serveren til { $server } har ikke et gyldigt navn eller portnummer.
setup-invalid-user = Den har intet brugernavn.
setup-invalid-sign-in = Kontoen bruger en loginmetode, som Inbox Classic ikke understøtter.
setup-error-empty = Filen er tom.
setup-error-too-large = Filen er for stor til at være en opsætningsfil til Inbox Classic.
setup-error-not-setup = Filen indeholder ikke en opsætning til Inbox Classic.
setup-error-damaged = Opsætningsfilen er beskadiget og kan ikke læses.
setup-error-newer = Opsætningen blev gemt med en nyere version af Inbox Classic ({ $version }). Opdater programmet, og prøv at importere igen.
setup-error-needs-passphrase = Denne opsætning er beskyttet af en adgangsfrase. Skriv den adgangsfrase, den blev gemt med.
setup-error-wrong-passphrase = Det er ikke den adgangsfrase, opsætningen blev gemt med.
setup-error-changed = Opsætningsfilen blev ændret eller beskadiget, efter den blev gemt, så den kan ikke importeres.
setup-error-read = Opsætningsfilen kunne ikke læses: { $error }
setup-error-write = Opsætningen kunne ikke gemmes: { $error }
setup-error-no-parts = Vælg mindst én del.
setup-left-out = { $count ->
    [one] 1 post i { $part } kan ikke bruges og udelades.
   *[other] { $count } poster i { $part } kan ikke bruges og udelades.
}
setup-imported-settings = Indstillingerne blev erstattet.
setup-imported-preferences = Vinduesindstillingerne blev erstattet.
setup-added-accounts = { $count ->
    [one] Tilføjede 1 konto.
   *[other] Tilføjede { $count } konti.
}
setup-skipped-here = { $address } er allerede konfigureret her, så den blev sprunget over.
setup-skipped-no-app = { $address } blev sprunget over: den logger på med { $app }, som ikke er konfigureret her.
setup-skipped-invalid = { $address } blev sprunget over: { $reason }
setup-asks-password = Du bliver bedt om adgangskoden til { $address }, når kontoen opretter forbindelse.
setup-signs-in-again = Du bliver bedt om at logge på { $address } igen i browseren, når kontoen opretter forbindelse.
setup-added-sign-in-apps = { $count ->
    [one] Tilføjede 1 login-app.
   *[other] Tilføjede { $count } login-apps.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 login-app er allerede konfigureret her.
   *[other] { $count } login-apps er allerede konfigureret her.
}
setup-added-contacts = { $count ->
    [one] Tilføjede 1 kontakt til adressekartoteket.
   *[other] Tilføjede { $count } kontakter til adressekartoteket.
}
setup-skipped-contacts = { $count ->
    [one] 1 kontakt er allerede i adressekartoteket.
   *[other] { $count } kontakter er allerede i adressekartoteket.
}
setup-added-groups = { $count ->
    [one] 1 gruppe tilføjet eller suppleret med medlemmer.
   *[other] { $count } grupper tilføjet eller suppleret med medlemmer.
}
setup-added-own-keys = { $count ->
    [one] Tilføjede 1 af dine egne nøgler.
   *[other] Tilføjede { $count } af dine egne nøgler.
}
setup-added-contact-keys = { $count ->
    [one] Tilføjede 1 nøgle tilhørende en kontakt.
   *[other] Tilføjede { $count } nøgler tilhørende kontakter.
}
setup-added-rules = { $count ->
    [one] Tilføjede 1 meddelelsesregel.
   *[other] Tilføjede { $count } meddelelsesregler.
}
setup-skipped-rules = { $count ->
    [one] 1 meddelelsesregel findes allerede her.
   *[other] { $count } meddelelsesregler findes allerede her.
}
setup-skipped-rules-account = { $count ->
    [one] 1 meddelelsesregel gælder en konto, der ikke er her, så den blev sprunget over.
   *[other] { $count } meddelelsesregler gælder konti, der ikke er her, så de blev sprunget over.
}
setup-rules-waiting = { $count ->
    [one] Destinationsmappen for 1 meddelelsesregel findes, når kontoens mapper er synkroniseret.
   *[other] Destinationsmapperne for { $count } meddelelsesregler findes, når kontienes mapper er synkroniseret.
}
setup-added-trusted-senders = { $count ->
    [one] Tilføjede 1 betroet afsender.
   *[other] Tilføjede { $count } betroede afsendere.
}
setup-nothing = Intet blev importeret.
setup-account-servers = { $imap } og { $smtp } ({ $signin })
setup-file-name = Inbox Classic-indstillinger og -konti
setup-skipped-unreachable = { $name } blev sprunget over: dens logintjeneste kunne ikke nås. Tilføj den igen under Login-apps.
attachment-runs-programs = Filen »{ $name }« kan køre programmer, så Inbox Classic åbner den ikke. Gem den, og åbn den selv, hvis du stoler på, hvor den kommer fra.
attachment-decrypted-note = Den vedhæftede fil kommer fra en krypteret meddelelse. For at åbne den gemmer Inbox Classic en ukrypteret kopi i en midlertidig mappe til din brugerkonto. Kopier, der er over et døgn gamle, fjernes, når programmet starter.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Serveren flyttede ikke { $messages } til { $folder }, så den er tilbage i { $from }: { $reason }
   *[other] Serveren flyttede ikke { $messages } til { $folder }, så de er tilbage i { $from }: { $reason }
}
undone-delete = { $count ->
    [one] Serveren slettede ikke { $messages }, så den er tilbage i { $from }: { $reason }
   *[other] Serveren slettede ikke { $messages }, så de er tilbage i { $from }: { $reason }
}
undone-archive = { $count ->
    [one] Serveren arkiverede ikke { $messages }, så den er tilbage i { $from }: { $reason }
   *[other] Serveren arkiverede ikke { $messages }, så de er tilbage i { $from }: { $reason }
}
undone-read = { $count ->
    [one] Serveren markerede ikke { $messages } som læst, så den er ulæst igen: { $reason }
   *[other] Serveren markerede ikke { $messages } som læste, så de er ulæste igen: { $reason }
}
undone-unread = { $count ->
    [one] Serveren markerede ikke { $messages } som ulæst, så den er læst igen: { $reason }
   *[other] Serveren markerede ikke { $messages } som ulæste, så de er læste igen: { $reason }
}
undone-flags = { $count ->
    [one] Serveren ændrede ikke flagene på { $messages }, så ændringen er fortrudt: { $reason }
   *[other] Serveren ændrede ikke flagene på { $messages }, så ændringen er fortrudt: { $reason }
}
