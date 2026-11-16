# Svenska. Utkast, väntar på granskning av en person med svenska som modersmål (se core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Swedish: [one] and *[other].

## Counts and sizes

# review: new
messages = { $count ->
    [one] { $count } meddelande
   *[other] { $count } meddelanden
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
size-kb = { $size } kB
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
# the status bar: "12 meddelanden, 3 olästa"
# review: new
list-counts = { $messages }, { $unread } olästa
# review: new
list-counts-selected = { $messages }, { $unread } olästa, { $selected } markerade
# the status bar while searching: "12 hittade, 3 olästa"
# review: new
list-counts-found = { $found } hittade, { $unread } olästa
# review: new
list-counts-found-selected = { $found } hittade, { $unread } olästa, { $selected } markerade
# review: new
list-counts-none = Inga meddelanden hittades

## Special folders, as Outlook names them in Swedish

# review: new
folder-inbox = Inkorgen
# review: new
folder-sent = Skickat
# review: new
folder-deleted = Borttaget
# review: new
folder-drafts = Utkast
# review: new
folder-junk = Skräppost
# review: new
folder-archive = Arkiv

## The reading pane

# review: new
reader-no-message = Inget meddelande är markerat.
# review: new
reader-downloading = Hämtar meddelandet…
# review: new
reader-downloading-detail = Meddelandet visas här när hämtningen är klar.
# review: new
reader-downloading-size = Meddelandet är { $size }. Det visas här när det har hämtats.
# review: new
reader-failed = Det gick inte att hämta meddelandet
# review: new
reader-failed-network = Det gick inte att nå e-postservern ({ $reason }).
# review: new
reader-failed-sign-in = E-postservern godtog inte inloggningen ({ $reason }). Kontrollera lösenordet eller logga in igen i Arkiv > Konton.
# review: new
reader-failed-security = Anslutningen till e-postservern kunde inte göras säker ({ $reason }).
# review: new
reader-failed-other = E-postservern svarade: { $reason }.
# review: new
reader-retry-note = Ett nytt försök görs när kontot ansluter igen.
# review: new
reader-unreadable = Det här meddelandet kan inte visas: { $error }
# review: new
message-source-title = Meddelandets källkod: { $subject }
# review: new
message-source-untitled = Meddelandets källkod

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Från
# review: new
header-date = Datum
# review: new
header-to = Till
# review: new
header-cc = Kopia
# review: new
header-sent = Skickat
# review: new
header-subject = Ämne
# review: new
header-security = Säkerhet
# review: new
header-part = Del { $number }
# review: new
quote-original = ----- Ursprungligt meddelande -----
# review: new
fold-show-earlier = Visa tidigare meddelanden

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Ditt meddelande levererades inte
# review: new
bounce-delayed = Ditt meddelande har inte levererats ännu
# review: new
bounce-delayed-note = Din e-postserver försöker fortfarande leverera det. Du behöver inte skicka det igen.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Visa meddelandet som studsade
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Visa det fördröjda meddelandet
# review: new
bounce-what-to-do = Det här kan du göra:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Inget ännu. Om det fortfarande inte kan levereras får du ett nytt meddelande om det.
# review: new
bounce-delayed-row-do = Inget ännu. Din e-postserver försöker fortfarande leverera det, och du får ett nytt meddelande om det inte går.
# folds the receiving server's own words
# review: new
bounce-details = Detaljer
# a recipient the notice does not name
# review: new
bounce-someone = En mottagare
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Status: { $status }
# review: new
bounce-reported-by = Rapporterat av: { $server }
# review: new
bounce-retry-minutes = Den mottagande servern bad om att vänta { $count ->
    [one] en minut
   *[other] { $count } minuter
} före nästa försök.
# review: new
bounce-retry-hours = Den mottagande servern bad om att vänta { $count ->
    [one] en timme
   *[other] { $count } timmar
} före nästa försök.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Blocklista: { $lists }
# review: new
bounce-user-unknown = Adressen finns inte
# review: new
bounce-user-unknown-why = Den mottagande servern har ingen brevlåda med den här adressen. Den kan vara felskriven, eller så har personen gått vidare.
# review: new
bounce-user-unknown-do = Kontrollera stavningen av adressen, eller be personen om den adress hon eller han använder nu.
# review: new
bounce-invalid-address = Adressen är inte giltig
# review: new
bounce-invalid-address-why = Adressen är inte skriven så att e-post kan skickas till den.
# review: new
bounce-invalid-address-do = Leta efter skrivfel, till exempel ett mellanslag, en bokstav som saknas eller inget efter @.
# review: new
bounce-mailbox-disabled = Brevlådan är stängd
# review: new
bounce-mailbox-disabled-why = Adressen finns, men brevlådan har stängts av eller används inte längre.
# review: new
bounce-mailbox-disabled-do = Nå personen på något annat sätt och be om en adress som används nu.
# review: new
bounce-mailbox-full = Brevlådan är full
# review: new
bounce-mailbox-full-why = Mottagarens brevlåda har inte plats för ny e-post.
# review: new
bounce-mailbox-full-do = Skicka det igen om några dagar, eller meddela personen på något annat sätt. Stora bilagor avvisas först.
# review: new
bounce-spam-blocked = Avvisat som skräppost
# review: new
bounce-spam-blocked-why = Den mottagande servern tog meddelandet för skräppost.
# review: new
bounce-spam-blocked-do = Skicka det igen utan det som ser ut som skräppost, till exempel många länkar, förkortade länkar eller en stor bilaga. Om det fortsätter att hända kan du fråga din e-postleverantör.
# review: new
bounce-virus-detected = Avvisat på grund av virus
# review: new
bounce-virus-detected-why = Den mottagande servern hittade ett virus eller annat skadligt innehåll i meddelandet eller dess bilagor.
# review: new
bounce-virus-detected-do = Kontrollera bilagorna med ett antivirusprogram. Vissa servrar avvisar alla program och arkiv, så dela sådana filer som en länk i stället.
# review: new
bounce-ip-blocklisted = Din e-postserver finns på en blocklista
# review: new
bounce-ip-blocklisted-why = Den mottagande servern avvisar e-post från servern som skickade din, eftersom den serverns adress finns på en blocklista.
# review: new
bounce-ip-blocklisted-do = Det är inte meddelandet som är problemet. Vidarebefordra det här meddelandet till din e-postleverantör och be dem att få servern borttagen från listan.
# review: new
bounce-domain-blocklisted = En domän finns på en blocklista
# review: new
bounce-domain-blocklisted-why = Den mottagande servern avvisar meddelandet eftersom domänen i din adress, eller en domän i meddelandets länkar, finns på en blocklista.
# review: new
bounce-domain-blocklisted-do = Om meddelandet innehåller länkar kan du försöka utan dem. Annars vidarebefordrar du det här meddelandet till den som sköter e-posten för din domän.
# review: new
bounce-policy-blocked = Avvisat av den mottagande serverns regler
# review: new
bounce-policy-blocked-why = Den mottagande serverns regler släpper inte igenom meddelandet, till exempel på grund av dess storlek, bilagor eller avsändare.
# review: new
bounce-policy-blocked-do = Serverns egna ord under Detaljer anger ofta orsaken. Fråga mottagaren om hon eller han kan ta emot sådan e-post.
# review: new
bounce-geo-blocked = Avvisat på grund av ursprung
# review: new
bounce-geo-blocked-why = Den mottagande servern tar inte emot e-post från det land eller nätverk där din e-postserver finns.
# review: new
bounce-geo-blocked-do = Nå personen på något annat sätt, eller fråga din e-postleverantör om saken.
# review: new
bounce-relay-denied = Servern skickade inte vidare det
# review: new
bounce-relay-denied-why = En server vägrade att leverera meddelandet vidare, ofta för att det skickades utan inloggning eller via en server som inte hanterar den här mottagaren.
# review: new
bounce-relay-denied-do = Kontrollera kontots utgående server i Arkiv > Konton, och att den loggar in.
# review: new
bounce-auth-failure = Din avsändaradress kunde inte verifieras
# review: new
bounce-auth-failure-why = Den mottagande servern kunde inte bekräfta att meddelandet verkligen kom från din domän (SPF, DKIM eller DMARC).
# review: new
bounce-auth-failure-do = Vidarebefordra det här meddelandet till den som sköter e-posten för din domän: dess inställningar behöver rättas. Under tiden kan det hjälpa att skicka via din leverantörs egen server.
# review: new
bounce-rate-limited = För mycket e-post på en gång
# review: new
bounce-rate-limited-why = Den mottagande servern tar för tillfället emot färre meddelanden från din e-postserver.
# review: new
bounce-rate-limited-do = Vänta en stund och skicka det igen. När du skriver till många personer kan du skicka till färre åt gången.
# review: new
bounce-greylisting = Tillfälligt fördröjt
# review: new
bounce-greylisting-why = Den mottagande servern ber okända avsändare att försöka igen lite senare, en vanlig kontroll mot skräppost.
# review: new
bounce-greylisting-do = Inget. E-postservrar försöker igen av sig själva, och meddelandet levereras oftast inom en timme.
# review: new
bounce-server-error = Den mottagande servern hade ett problem
# review: new
bounce-server-error-why = Den mottagande servern kunde inte nås, eller kunde inte ta emot meddelandet på grund av ett eget problem.
# review: new
bounce-server-error-do = Skicka det igen senare. Om det fortsätter att misslyckas kan du kontrollera delen av adressen efter @ för skrivfel.
# review: new
bounce-unknown = Inte levererat
# review: new
bounce-unknown-why = Meddelandet anger inte tydligt varför.
# review: new
bounce-unknown-do = Serverns egna ord under Detaljer kan säga mer. Om de inte hjälper kan du vidarebefordra det här meddelandet till din e-postleverantör.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } meddelande markerat
   *[other] { $count } meddelanden markerade
}
# review: new
selection-unread = { $count } olästa
# review: new
selection-flagged = { $count } flaggade
# review: new
delete-for-good-one = Meddelandet tas bort permanent. Vill du ta bort det?
# review: new
delete-for-good-all = De här { $count } meddelandena tas bort permanent. Vill du ta bort dem?
# review: new
delete-for-good-some = { $count } av de { $total } meddelandena tas bort permanent. Vill du ta bort meddelandena?
# review: new
done-read = { $count ->
    [one] { $messages } markerades som läst
   *[other] { $messages } markerades som lästa
}
# review: new
done-unread = { $count ->
    [one] { $messages } markerades som oläst
   *[other] { $messages } markerades som olästa
}
# review: new
done-flagged = { $count ->
   *[other] { $messages } flaggades
}
# review: new
done-unflagged = Flaggan togs bort från { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] { $messages } togs bort permanent
}
# review: new
done-archived = { $count ->
   *[other] { $messages } arkiverades
}
# review: new
done-moved = { $count ->
   *[other] { $messages } flyttades till { $folder }
}
# review: new
done-copied = { $count ->
   *[other] { $messages } kopierades till { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Flyttar { $messages } till { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Kopierar { $messages } till { $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] { $messages } flyttades tillbaka till { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Bevakar konversationen
   *[other] Bevakar { $count } konversationer
}
# review: new
done-unwatched = { $count ->
    [one] Slutade bevaka konversationen
   *[other] Slutade bevaka { $count } konversationer
}
# review: new
done-ignored = { $count ->
    [one] Ignorerar konversationen
   *[other] Ignorerar { $count } konversationer
}
# review: new
done-unignored = { $count ->
    [one] Slutade ignorera konversationen
   *[other] Slutade ignorera { $count } konversationer
}
# review: new
their-folders = respektive mapp
# review: new
undo-move = Ångra flytt
# review: new
undo-delete = Ångra borttagning
# review: new
undo-archive = Ångra arkivering
# review: new
undo-junk = Ångra Markera som skräppost
# review: new
undo-not-junk = Ångra Markera som ej skräppost
# review: new
undo-send = Ångra sändning
# review: new
nothing-to-undo = Det finns inget att ångra.
# review: new
messages-gone = Meddelandena finns inte längre kvar.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Den här mappen kan inte innehålla meddelanden.
# review: new
not-archived-here = Meddelanden i den här mappen kan inte arkiveras.
# review: new
not-emptied-here = Bara Borttaget och Skräppost kan tömmas.
# review: new
next-unread-question = Det finns inga fler olästa meddelanden i { $folder }.

    Vill du gå till { $next }, nästa mapp med olästa meddelanden?
# review: new
no-unread-left = Det finns inga olästa meddelanden kvar.
# review: new
empty-question = { $count ->
    [one] Vill du tömma { $folder }?

        Meddelandet i mappen tas bort permanent. Det kan inte återställas.
   *[other] Vill du tömma { $folder }?

        Alla { $messages } i mappen tas bort permanent. De kan inte återställas.
}
# review: new
no-junk-folder = Kontot har ingen Skräppost-mapp att flytta meddelandena till.
# review: new
no-inbox-folder = Kontot har ingen Inkorg att flytta meddelandena till.
# the status bar after a flag in a colour: "2 meddelanden fick röd flagga"
# review: new
done-flagged-color = { $messages } fick { $color ->
    [red] röd
    [orange] orange
    [yellow] gul
    [green] grön
    [blue] blå
    [purple] lila
   *[gray] grå
} flagga
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Röd
    [orange] Orange
    [yellow] Gul
    [green] Grön
    [blue] Blå
    [purple] Lila
   *[gray] Grå
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [one] Flytta meddelande
   *[other] Flytta { $count } meddelanden
}
# review: new
move-window-title-copy = { $count ->
    [one] Kopiera meddelande
   *[other] Kopiera { $count } meddelanden
}
# review: new
move-window-prompt-move = { $count ->
    [one] Flytta det markerade meddelandet till:
   *[other] Flytta de { $count } markerade meddelandena till:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Kopiera det markerade meddelandet till:
   *[other] Kopiera de { $count } markerade meddelandena till:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Senaste
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (nuvarande)
# a folder used last, with its account when there are several: "Arkiv (Arbete)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Flyttar { $done } av { $messages } till { $folder }...
# review: new
transfer-copying = Kopierar { $done } av { $messages } till { $folder }...
# review: new
transfer-another-account = ett annat konto
# review: new
transfer-folder-gone = mappen som det skulle till finns inte längre
# review: new
transfer-not-on-server = meddelandet finns inte längre på servern
# review: new
transfer-not-moved = { $count ->
   *[other] { $messages } kunde inte flyttas till ett annat konto: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] { $messages } kunde inte kopieras till ett annat konto: { $reason }
}
# review: new
transfer-none-moved = Inget meddelande kunde flyttas
# review: new
transfer-none-copied = Inget meddelande kunde kopieras

## Messages as files

# review: new
export-not-in-time = meddelandet kunde inte hämtas i tid
# review: new
export-not-saved = { $failed } av { $messages } kunde inte sparas ({ $problems })
# review: new
export-not-attached = meddelandena kunde inte bifogas: { $error }
# the status bar after Save As with several: "3 meddelanden sparades i Skrivbord"
# review: new
saved-to = { $count ->
   *[other] { $messages } sparades i { $folder }
}
# review: new
download-progress = Hämtar { $done } av { $total }
# review: new
download-done = { $size } hämtat
# review: new
downloading-messages = { $count ->
   *[other] Hämtar { $messages }...
}
# the status bar after files are dropped on a folder: "3 meddelanden lades i Arkiv"
# review: new
import-put = { $count ->
   *[other] { $messages } lades i { $folder }
}
# review: new
import-not-put = De här lades inte i mappen:

    { $problems }

## Problems the windows show

# review: new
error-store = lokalt lager: { $error }
# review: new
error-not-found = hittades inte
# review: new
error-closed = avslutas
# review: new
error-other-account = webbläsaren loggade in på { $email }, inte på det här kontot
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = servern godtog inte inloggningen ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = anslutningen till servern misslyckades ({ $reason })
# review: new
error-in-use = den kan inte tas bort medan konton loggar in med den: { $accounts }
# review: new
error-turned-off = den här inloggningsappen är avstängd för nya konton
# review: new
error-folder-name = mappnamnet måste vara 1 till 200 tecken långt och får inte innehålla styrtecken
# review: new
error-folder-separator = ett mappnamn får inte innehålla ”{ $separator }” på den här servern
# review: new
error-folder-special = Inkorgen och specialmapparna kan inte byta namn eller tas bort
# review: new
error-no-recipients = meddelandet har inga mottagare
# review: new
error-bad-address = ”{ $address }” är inte en e-postadress
# review: new
error-not-own-address = { $address } är inte en av kontots avsändaradresser. Lägg till den i ”Andra adresser du skickar från” i kontots egenskaper.
# review: new
rule-query-refused = Regler kan inte filtrera efter mapp eller datum ({ $words }).
# review: new
rule-no-query = Ange sökvillkor för inkommande meddelanden.
# review: new
rule-no-action = Välj minst en åtgärd för regeln.
# review: new
error-attachment = { $path } kunde inte läsas: { $error }
# review: new
error-no-drafts = kontot har ingen Utkast-mapp att spara meddelandet i
# review: new
error-draft-attachment = en bilaga i utkastet kunde inte behållas: { $error }
# review: new
error-password-not-saved = lösenordet kunde inte sparas till nästa start: { $error }
# review: new
error-sign-in-not-saved = de nya inloggningsuppgifterna kunde inte sparas till nästa start: { $error }
# review: new
error-import-unreadable = { $path } kan inte läsas: { $error }
# review: new
error-import-too-large = { $path } är större än 50 MB
# review: new
error-import-not-mail = { $path } är inte ett e-postmeddelande
# review: new
error-list-answered = e-postlistans server svarade med status { $status }
# review: new
error-not-built = meddelandet kunde inte skapas
# review: new
error-outbox-waits = { $count ->
    [one] meddelandet väntar i Utkorgen och skickas vid nästa Skicka/ta emot
   *[other] { $count } meddelanden väntar i Utkorgen och skickas vid nästa Skicka/ta emot
}
# review: new
error-draft-not-removed = det tidigare utkastet av meddelandet kunde inte tas bort från Utkast: { $reason }
# review: new
error-sent-but = meddelandet skickades, men { $problem }
# review: new
error-sent-still-in-outbox = det finns fortfarande i Utkorgen: { $error }
# review: new
error-sent-no-copy = ingen kopia kunde sparas i Skickat: { $reason }
# review: new
error-no-password = inget lösenord för det här kontot
# review: new
error-no-sign-in = ingen inloggning för det här kontot
# review: new
error-provider-missing = den här versionen kan inte logga in på { $provider }: har dess inloggningsapp tagits bort?
# review: new
error-provider-servers = kontots servrar stämmer inte med inloggningsappens servrar
# review: new
error-app-scopes = { $reason }. E-postservern godtog inte inloggningsappens token: kontrollera att appens behörigheter (scopes) ger åtkomst till e-post
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google har inte verifierat Inbox Classic ännu, så bara testanvändare kan logga in med den. Använd en egen inloggningsapp för Google eller ett applösenord, eller slå på den i Inloggningsappar (Arkiv > Konton) om du är testanvändare.
# review: new
sign-in-off-other = Den stängdes av i Inloggningsappar (Arkiv > Konton), där den kan slås på igen.
# review: new
sign-in-app-no-name = inloggningsappen behöver ett namn
# review: new
sign-in-app-no-client = klient-ID saknas
# review: new
sign-in-app-no-scopes = inloggningsappen behöver de behörigheter (scopes) som ger åtkomst till e-post
# review: new
sign-in-app-bad-host = adressen till { $server }-servern saknas eller är inte ett giltigt värdnamn
# review: new
sign-in-app-plain = { $server }-servern måste använda SSL/TLS eller STARTTLS
# review: new
sign-in-app-not-checked = utfärdaren har inte kontrollerats ännu
# review: new
sign-in-app-issuer-changed = utfärdaren har ändrats: skriv klienthemligheten igen, eller ta bort den
# review: new
sign-in-register-google = Skapa en OAuth-klient av typen Desktop app i Google Cloud Console, med behörigheten https://mail.google.com/ på dess samtyckesskärm. Medan appen är i testläge kan bara dess testanvändare logga in.
# review: new
sign-in-register-microsoft = Registrera en app i Microsoft Entra med plattformen Mobile and desktop applications, omdirigerings-URI:n http://localhost och offentliga klientflöden tillåtna, samt de delegerade behörigheterna IMAP.AccessAsUser.All, SMTP.Send och offline_access. Om bara din organisation ska använda den anger du https://login.microsoftonline.com/<klientorganisations-ID>/v2.0 som utfärdare.
# review: new
sign-in-register-other = Registrera en intern (offentlig) klient med omdirigerings-URI:n nedan; leverantören måste tillåta vilken port som helst på den (RFC 8252). Lägg till den behörighet som leverantören ger åtkomst till e-post med.

## Calendar invitations

# review: new
repeats = Upprepas
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Varje dag
       *[other] Var { $interval }:e dag
    }
    [week] { $interval ->
        [one] Varje vecka
       *[other] Var { $interval }:e vecka
    }
    [month] { $interval ->
        [one] Varje månad
       *[other] Var { $interval }:e månad
    }
   *[year] { $interval ->
        [one] Varje år
       *[other] Vart { $interval }:e år
    }
}
# "Varje vecka på måndag, onsdag"
# review: new
repeats-on = { $repeats } på { $days }
# "Varje vecka, 10 gånger"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, en gång
   *[other] { $repeats }, { $count } gånger
}
# review: new
day-monday = måndag
# review: new
day-tuesday = tisdag
# review: new
day-wednesday = onsdag
# review: new
day-thursday = torsdag
# review: new
day-friday = fredag
# review: new
day-saturday = lördag
# review: new
day-sunday = söndag

## AI agents

# review: new
agent-level-read = Läsa e-post: mappar, meddelandelistan, sökning och meddelanden
# review: new
agent-level-organize = Ordna e-post: läsläge, flaggor, skräppost, flytt, borttagning till Borttaget
# review: new
agent-level-drafts = Skriva utkast som du skickar
# review: new
agent-level-send = Skicka e-post, varje meddelande först efter att du har sagt ja
# review: new
agent-connect-title = { $program } vill använda din e-post
# review: new
agent-connect-detail = En AI-agent bad om att få arbeta med Inbox Classic. Välj vad den får göra och vilka konton den får se; du kan ändra det senare under Verktyg > AI-agenter.

    Agenter läser e-post som andra har skrivit, och ett meddelande kan försöka lura dem. Inbox Classic frågar dig alltid innan en agent skickar något.
# review: new
agent-reply-to = Svar på ”{ $subject }”
# review: new
agent-reply-all-on = Svar till alla på ”{ $subject }”
# review: new
agent-forward-of = Vidarebefordran av ”{ $subject }”
# review: new
agent-never-written-one = Du har aldrig skrivit till { $address }.
# review: new
agent-never-written-many = Du har aldrig skrivit till { $count } av de här adresserna.
# review: new
agent-send-title = { $program } vill skicka det här meddelandet
# review: new
agent-send-detail = Kontrollera mottagarna och meddelandets innehåll. När du har bekräftat väntar meddelandet { $seconds } sekunder i Utkorgen, där du fortfarande kan ta bort det.
# review: new
agent-change-title = Vad { $program } får göra
# review: new
agent-change-allowed = Ändra vad programmets AI-agenter får göra med din e-post.
# review: new
agent-change-refused = Du nekade programmet åtkomst. Tillåt det för att ge dess agenter åtkomst till din e-post igen.
# review: new
agent-log-taken-back = { $entry } (ångrat)
# review: new
agent-files = Filer: { $files }
# review: new
agent-undo-refused = Det kan inte ångras.
# review: new
agent-undo-refused-why = Det kan inte ångras: { $reason }.
# review: new
agent-undo-impossible = det här kan inte ångras
# review: new
agent-undo-not-in-folder = meddelandet finns inte längre i den mappen
# review: new
agent-undo-not-arrived = meddelandet finns inte (ännu) i mappen som det flyttades till
# review: new
agent-undo-sent = meddelandet har redan skickats
# review: new
agent-original-not-downloaded = det ursprungliga meddelandet har inte hämtats ännu. Öppna det först
# review: new
agent-turned-away = Avvisad
# review: new
agent-can-nothing = Inget
# review: new
agent-can-read = läsa
# review: new
agent-can-organize = ordna
# review: new
agent-can-drafts = skriva utkast
# review: new
agent-can-send = skicka när du säger ja
# "Läsa, ordna och skriva utkast"
# review: new
agent-can-list = { $first } och { $last }
# review: new
agent-accounts = { $count ->
    [0] inga konton
    [one] { $count } konto
   *[other] { $count } konton
}
# "Läsa och ordna; 1 konto"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Det här meddelandet kan inte läsas.
# review: new
agent-encrypted-original = Det här meddelandet är krypterat: en agent kan inte svara på det eller vidarebefordra det, eftersom den inte kan kryptera.
# review: new
agent-log-composed = Öppnade ”{ $subject }” i ett nytt meddelande som du kan göra klart
# review: new
agent-log-refused = Du skickade inte ”{ $subject }”
# review: new
agent-log-sent = Skickade ”{ $subject }” till { $to }
# review: new
agent-log-draft = Sparade utkastet ”{ $subject }”
# review: new
agent-log-read = Markerade ”{ $subject }” som läst
# review: new
agent-log-unread = Markerade ”{ $subject }” som oläst
# review: new
agent-log-flagged = Flaggade ”{ $subject }”
# review: new
agent-log-unflagged = Tog bort flaggan från ”{ $subject }”
# review: new
agent-log-deleted = Tog bort ”{ $subject }”
# review: new
agent-log-moved = Flyttade ”{ $subject }” till { $folder }
# review: new
agent-log-junk = Markerade ”{ $subject }” som skräppost
# review: new
agent-log-not-junk = Markerade ”{ $subject }” som ej skräppost
# review: new
agent-log-archived = Arkiverade ”{ $subject }”
# review: new
agent-log-folder = Skapade mappen ”{ $name }”
# review: new
agent-log-unsubscribed = Avslutade prenumerationen på listan för ”{ $subject }”

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
key-enter = Retur

## Signing in and passwords

# review: new
sign-in-no-refresh = leverantören gav ingen uppdateringstoken
# review: new
sign-in-no-account = leverantören angav inte vilket konto som loggade in
# review: new
sign-in-not-finished = inloggningen har inte slutförts
# review: new
secrets-unavailable = { $store } är inte tillgänglig
# review: new
secrets-unavailable-why = { $store } är inte tillgänglig: { $error }
# review: new
secrets-windows = Autentiseringshanteraren
# review: new
secrets-mac = nyckelringen
# review: new
secrets-linux = systemets nyckelring (Secret Service)
# review: new
error-no-such-file = filen finns inte
# review: new
cards-file-too-big = Filen är för stor för att vara en adressbok.
# review: new
ui-sender-added = { $name } lades till i adressboken.
# review: new
ui-sender-known = { $name } finns redan i adressboken.
# review: new
ui-sender-none = Avsändaren av det här meddelandet har ingen e-postadress att lägga till.
# review: new
card-name-needed = Kontakten har inget namn och ingen e-postadress.
# a file of Import Address Book that could not be read: "kontakter.vcf: filen finns inte"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Kod från { $domain }
# review: new
otp-copy = Kopiera
# review: new
otp-note = Ange den bara på en sida som tillhör { $domain }.
# review: new
otp-old = Koden skickades mer än en timme innan du öppnade den och har troligen gått ut.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } deltagare
       *[other] { $count } deltagare
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } är din kod för { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Giltig
# review: new
pgp-key-expires = Giltig till { $date }
# review: new
pgp-key-expired = Gick ut { $date }
# review: new
pgp-key-revoked = Återkallad
# review: new
pgp-key-revoked-why = Återkallad: { $reason }
# review: new
pgp-key-not-valid = Inte giltig
# review: new
pgp-key-locked = Kan inte användas: nyckeln som skyddar den finns inte längre i { $store }. Importera säkerhetskopian igen.
# review: new
pgp-source-own = Skapad i Inbox Classic
# review: new
pgp-source-file = Importerad från en fil
# review: new
pgp-source-paste = Inklistrad
# review: new
pgp-source-attachment = Från ett meddelande
# review: new
pgp-source-vcard = Från ett kontaktkort
# review: new
pgp-source-wkd = Från avsändarens e-postleverantör
# review: new
pgp-source-keyserver = Från keys.openpgp.org
# review: new
pgp-source-autocrypt = Från ett meddelandes Autocrypt-huvud
# review: new
pgp-error-no-store = Privata nycklar skyddas av { $store }, som inte kan användas: { $error }
# review: new
pgp-error-wrong-passphrase = Lösenfrasen är inte rätt.
# review: new
pgp-error-not-a-key = Det här är inte en OpenPGP-nyckel.
# review: new
pgp-error-too-large = Nyckeln är för stor.
# review: new
pgp-error-unusable = Nyckeln använder gammal eller svag kryptografi och kan inte användas.
# review: new
pgp-imported-private = { $count ->
    [one] Din privata nyckel importerades.
   *[other] { $count } privata nycklar importerades.
}
# review: new
pgp-imported-public = { $count ->
    [one] En nyckel importerades.
   *[other] { $count } nycklar importerades.
}
# review: new
pgp-imported-pending = En annan nyckel används redan för { $addresses }: den nya väntar i kontakten tills du väljer den.
# review: new
pgp-error-needs-passphrase = Den privata nyckeln skyddas med en lösenfras. Skriv den för att importera nyckeln.
# review: new
pgp-error-mismatch = Den privata nyckeln hör inte till sin offentliga nyckel. Den kan ha ändrats.
# review: new
pgp-file-name-public = { $who } offentlig nyckel.asc
# review: new
pgp-file-name-private = { $who } säkerhetskopia av privat nyckel.asc
# review: new
pgp-pending = En annan nyckel för { $address } hittades { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Signerad av { $signer }, nyckeln verifierad
# review: new
pgp-part-signed = Signerad av { $signer } (nyckeln inte verifierad)
# review: new
pgp-part-other = Signerad av { $signer }, som inte är avsändaren
# review: new
pgp-part-unknown-key = Signerad, men nyckeln är okänd
# review: new
pgp-part-not-signed = Inte signerad
# review: new
pgp-part-not-checked = Signaturen har inte kontrollerats
# review: new
pgp-part-encrypted = Krypterad. { $signature }
# review: new
pgp-part-no-key = Krypterad till en nyckel som du inte har
# review: new
pgp-part-changed = Den krypterade delen ändrades på vägen och visas inte
# review: new
pgp-part-unprotected = Krypterad utan skydd mot ändringar, visas inte
# review: new
pgp-part-broken = Den krypterade delen kan inte läsas
# review: new
pgp-why-mismatch = Signaturen stämmer inte med den här texten
# review: new
pgp-why-weak-hash = Signaturen använder { $hash }, som inte längre är säker
# review: new
pgp-why-key-expired = Signerad efter att nyckeln gick ut { $date }
# review: new
pgp-why-key-revoked = Signerad med en nyckel som har återkallats
# review: new
pgp-why-not-signing-key = Signerad med en nyckel som inte får signera
# review: new
pgp-why-from-future = Signaturen är daterad i framtiden
# review: new
pgp-why-signature-expired = Signaturen har gått ut
# review: new
pgp-why-key-not-valid = Signerad med en nyckel som inte är giltig
# review: new
pgp-why-not-for-you = Signerad för andra mottagare och vidarebefordrad till dig
# review: new
pgp-part-pictures-loaded = { $label }. Bilder hämtades från internet
# review: new
pgp-error-no-own-key = Du har ingen nyckel för { $address } att signera eller kryptera med. Skapa en i Verktyg > Krypteringsnycklar, eller stäng av Signera och Kryptera.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } har ingen nyckel att kryptera till.
   *[other] De här mottagarna har ingen nyckel att kryptera till: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Det här meddelandet citerar eller vidarebefordrar ett krypterat meddelande, så det kan bara skickas krypterat. Slå på Kryptera eller ta bort den citerade texten.
# review: new
pgp-error-protect = Meddelandet kunde inte signeras eller krypteras: { $reason }
# review: new
pgp-found-keys = Nyckeln för { $addresses } hittades.
# review: new
pgp-found-none = Ingen nyckel hittades för { $addresses }. Be om att få deras offentliga nyckel.
# review: new
pgp-found-no-key = Ingen nyckel hittades.
# review: new
pgp-find-unavailable = Nycklar kunde inte sökas upp just nu: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org skickade en bekräftelselänk till { $addresses }. Din nyckel publiceras där när du klickar på den.
# review: new
pgp-publish-done = Din nyckel är publicerad på keys.openpgp.org för { $addresses }.
# review: new
pgp-publish-failed = Nyckeln kunde inte publiceras: { $error }
# review: new
pgp-keyserver-off = Sökning efter nycklar på keys.openpgp.org är avstängd i Alternativ.
# review: new
pgp-details-part = Del { $number }: { $label }
# review: new
pgp-details-signed = Signerad { $when } med nyckeln { $key }
# review: new
pgp-details-unknown-key = Signerad med nyckeln { $key }, som du inte har
# review: new
pgp-details-opened = Krypterad till din nyckel { $key }
# review: new
pgp-details-for = Krypterad till { $keys }
# review: new
pgp-details-plain = Inte signerad och inte krypterad
# review: new
pgp-bar-parts = Meddelandet har { $count } delar: { $list }. Varje del anger hur den är skyddad.
# review: new
pgp-bar-count-verified = { $count } verifierade
# review: new
pgp-bar-count-good = { $count ->
    [one] { $count } signerad eller krypterad
   *[other] { $count } signerade eller krypterade
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] { $count } behöver åtgärdas
   *[other] { $count } behöver åtgärdas
}
# review: new
pgp-bar-count-neutral = { $count } utan bekräftad signatur
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Inställningar
# review: new
setup-part-preferences = Fönsterinställningar
# review: new
setup-part-accounts = Konton
# review: new
setup-part-sign-in-apps = Inloggningsappar
# review: new
setup-part-contacts = Kontakter och grupper
# review: new
setup-part-keys = Krypteringsnycklar
# review: new
setup-part-rules = Meddelanderegler
# review: new
setup-part-trusted-senders = Betrodda avsändare
# review: new
setup-holds-settings = { $count ->
    [one] { $count } inställning
   *[other] { $count } inställningar
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } fönsterinställning
   *[other] { $count } fönsterinställningar
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } konto
   *[other] { $count } konton
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } inloggningsapp
   *[other] { $count } inloggningsappar
}
# review: new
setup-holds-built-in = Vilka inbyggda inloggningsappar som är påslagna
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } kontakt
   *[other] { $count } kontakter
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } grupp
   *[other] { $count } grupper
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } egen nyckel
   *[other] { $count } egna nycklar
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } nyckel för en kontakt
   *[other] { $count } nycklar för kontakter
}
# review: new
setup-holds-rules = { $count ->
    [one] { $count } regel
   *[other] { $count } regler
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] { $count } betrodd avsändare
   *[other] { $count } betrodda avsändare
}
# review: new
setup-sign-in-password = Lösenord
# review: new
setup-account-secret-password = Lösenordet finns i filen.
# review: new
setup-account-secret-token = Inloggningen finns i filen.
# review: new
setup-account-asks-password = Det frågar efter sitt lösenord efter importen.
# review: new
setup-account-signs-in-again = Du loggar in på det igen efter importen.
# review: new
setup-account-here = Det är redan konfigurerat här, så det hoppas över.
# review: new
setup-account-no-app = Det loggar in med { $app }, som inte är konfigurerad här. Importera inloggningsapparna också.
# review: new
setup-invalid-address = ”{ $address }” är inte en e-postadress.
# review: new
setup-invalid-server = { $server }-servern har inget användbart namn eller någon användbar port.
# review: new
setup-invalid-user = Det har inget användarnamn.
# review: new
setup-invalid-sign-in = Det loggar in på ett sätt som Inbox Classic inte känner till.
# review: new
setup-error-empty = Filen är tom.
# review: new
setup-error-too-large = Filen är för stor för att vara en konfiguration från Inbox Classic.
# review: new
setup-error-not-setup = Filen är inte en konfiguration från Inbox Classic.
# review: new
setup-error-damaged = Konfigurationsfilen är skadad och kan inte läsas.
# review: new
setup-error-newer = Konfigurationen sparades av en nyare Inbox Classic ({ $version }). Uppdatera Inbox Classic och importera den sedan igen.
# review: new
setup-error-needs-passphrase = Konfigurationen skyddas med en lösenfras. Skriv lösenfrasen som den sparades med.
# review: new
setup-error-wrong-passphrase = Det är inte lösenfrasen som konfigurationen sparades med.
# review: new
setup-error-changed = Konfigurationsfilen ändrades eller skadades efter att den sparades, så den kan inte importeras.
# review: new
setup-error-read = Konfigurationsfilen kunde inte läsas: { $error }
# review: new
setup-error-write = Konfigurationen kunde inte sparas: { $error }
# review: new
setup-error-no-parts = Välj minst en del.
# review: new
setup-left-out = { $count ->
    [one] { $count } post i { $part } kan inte användas och utelämnas.
   *[other] { $count } poster i { $part } kan inte användas och utelämnas.
}
# review: new
setup-imported-settings = Inställningarna ersattes.
# review: new
setup-imported-preferences = Fönsterinställningarna ersattes.
# review: new
setup-added-accounts = { $count ->
    [one] { $count } konto lades till.
   *[other] { $count } konton lades till.
}
# review: new
setup-skipped-here = { $address } är redan konfigurerat här, så det hoppades över.
# review: new
setup-skipped-no-app = { $address } hoppades över: det loggar in med { $app }, som inte är konfigurerad här.
# review: new
setup-skipped-invalid = { $address } hoppades över: { $reason }
# review: new
setup-asks-password = { $address } frågar efter sitt lösenord när det ansluter.
# review: new
setup-signs-in-again = { $address } ber dig logga in igen när det ansluter.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] { $count } inloggningsapp lades till.
   *[other] { $count } inloggningsappar lades till.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } inloggningsapp är redan konfigurerad här.
   *[other] { $count } inloggningsappar är redan konfigurerade här.
}
# review: new
setup-added-contacts = { $count ->
    [one] { $count } kontakt lades till i adressboken.
   *[other] { $count } kontakter lades till i adressboken.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } kontakt finns redan i adressboken.
   *[other] { $count } kontakter finns redan i adressboken.
}
# review: new
setup-added-groups = { $count ->
    [one] { $count } grupp lades till eller kompletterades.
   *[other] { $count } grupper lades till eller kompletterades.
}
# review: new
setup-added-own-keys = { $count ->
    [one] { $count } egen nyckel lades till.
   *[other] { $count } egna nycklar lades till.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] { $count } nyckel för en kontakt lades till.
   *[other] { $count } nycklar för kontakter lades till.
}
# review: new
setup-added-rules = { $count ->
    [one] { $count } meddelanderegel lades till.
   *[other] { $count } meddelanderegler lades till.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } meddelanderegel finns redan här.
   *[other] { $count } meddelanderegler finns redan här.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } meddelanderegel gäller ett konto som inte finns här, så den hoppades över.
   *[other] { $count } meddelanderegler gäller konton som inte finns här, så de hoppades över.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } meddelanderegel flyttar meddelanden till en mapp som visas när dess konto har synkroniserats.
   *[other] { $count } meddelanderegler flyttar meddelanden till mappar som visas när deras konton har synkroniserats.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] { $count } betrodd avsändare lades till.
   *[other] { $count } betrodda avsändare lades till.
}
# review: new
setup-nothing = Inget importerades.
# review: new
setup-account-servers = { $imap } och { $smtp } ({ $signin })
# review: new
setup-file-name = Inställningar och konton för Inbox Classic
# review: new
setup-skipped-unreachable = { $name } hoppades över: dess inloggningstjänst kunde inte nås. Lägg till den igen i Inloggningsappar.
