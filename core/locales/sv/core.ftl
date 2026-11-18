# Svenska. Utkast, väntar på granskning av en person med svenska som modersmål (se core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Swedish: [one] and *[other].

## Counts and sizes

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

# review: changed
agent-level-read = Läsa e-post: visa mappar, meddelandelistan och meddelanden samt söka i e-posten
# review: changed
agent-level-organize = Hantera e-post: ändra lästmarkeringar, flaggor och deras färger samt skräppostmarkeringar, flytta och arkivera meddelanden, skapa och byta namn på mappar, bevaka och ignorera konversationer, flytta meddelanden till Borttaget och avsluta prenumerationer på e-postlistor med ditt godkännande
agent-level-drafts = Skriva utkast som du kan skicka själv
agent-level-send = Skicka e-post när du har godkänt varje meddelande
agent-connect-title = { $program } vill ha åtkomst till din e-post
agent-connect-detail = En AI-agent vill arbeta med din e-post via Inbox Classic. Välj vad den får göra och vilka konton den får komma åt. Det kan du ändra senare under Verktyg > AI-agenter.

    E-post kan innehålla instruktioner som är avsedda att lura agenten. Inbox Classic ber alltid om ditt godkännande innan agenten skickar ett meddelande.
agent-reply-to = Svar på ”{ $subject }”
agent-reply-all-on = Svar till alla på ”{ $subject }”
agent-forward-of = Vidarebefordran av ”{ $subject }”
agent-never-written-one = Du har aldrig skrivit till { $address }.
agent-never-written-many = Du har aldrig skrivit till { $count } av de här adresserna.
agent-send-title = { $program } vill skicka det här meddelandet
agent-send-detail = Kontrollera mottagarna och meddelandets innehåll. När du har godkänt meddelandet ligger det i Utkorgen i minst { $seconds } sekunder. Du kan ta bort det där innan det skickas.
agent-change-title = Vad { $program } får göra
agent-change-allowed = Ändra vad programmets AI-agenter får göra med din e-post.
agent-change-refused = Du har nekat programmet åtkomst. Tillåt åtkomst för att låta dess agenter arbeta med din e-post igen.
agent-log-taken-back = { $entry } (ångrat)
agent-files = Filer: { $files }
agent-undo-refused = Det kan inte ångras.
agent-undo-refused-why = Det kan inte ångras: { $reason }.
agent-undo-impossible = det här kan inte ångras
agent-undo-not-in-folder = meddelandet finns inte längre i den mappen
agent-undo-not-arrived = meddelandet finns ännu inte i målmappen
agent-undo-sent = meddelandet finns inte längre i Utkorgen
agent-original-not-downloaded = det ursprungliga meddelandet har inte hämtats ännu. Öppna det först
agent-turned-away = Åtkomst nekad
agent-can-nothing = Inget
agent-can-read = läsa
agent-can-organize = hantera
agent-can-drafts = skriva utkast
agent-can-send = skicka med ditt godkännande
# "Läsa, ordna och skriva utkast"
agent-can-list = { $first } och { $last }
agent-accounts = { $count ->
    [0] inga konton
    [one] { $count } konto
   *[other] { $count } konton
}
# "Läsa och ordna; 1 konto"
agent-access = { $can }; { $accounts }
agent-unreadable = Det här meddelandet kan inte läsas.
agent-encrypted-original = Det här meddelandet är krypterat: en agent kan inte svara på det eller vidarebefordra det, eftersom den inte kan kryptera.
agent-encrypted = Det här meddelandet är krypterat och agenten kan inte läsa innehållet. Du kan öppna det i Inbox Classic.
# review: new
agent-too-many-changes = För många ändringar de senaste 30 dagarna: den här agenten har gjort så många som Inbox Classic sparar i loggen för ett program. Den kan göra fler när de äldsta är 30 dagar gamla.
# review: new
agent-too-many-reads = För mycket läst de senaste 30 dagarna: den här agenten har läst så mycket som Inbox Classic sparar i loggen för ett program. Den kan läsa mer när de äldsta läsningarna är 30 dagar gamla.
# review: new
list-encrypted = Krypterat meddelande
agent-log-composed = Öppnade ett nytt meddelande för redigering. Ämne: ”{ $subject }”
agent-log-refused = Du avböjde att skicka meddelandet ”{ $subject }”
agent-log-sent = Lade meddelandet ”{ $subject }” i kö för att skickas. Mottagare: { $to }
agent-log-draft = Sparade utkastet ”{ $subject }”
agent-log-draft-replaced = Ersatte utkastet ”{ $subject }”
agent-log-draft-discarded = Tog bort utkastet ”{ $subject }” permanent
agent-draft-note = AI-agenten { $program } skrev det här utkastet. Kontrollera mottagarna och texten innan du skickar det.
agent-log-read = Markerade ”{ $subject }” som läst
agent-log-unread = Markerade ”{ $subject }” som oläst
agent-log-flagged = Flaggade ”{ $subject }”
agent-log-unflagged = Tog bort flaggan från ”{ $subject }”
agent-log-deleted = Tog bort ”{ $subject }”
agent-log-moved = Flyttade ”{ $subject }” till mappen ”{ $folder }”
agent-log-junk = Markerade ”{ $subject }” som skräppost
agent-log-not-junk = Tog bort skräppostmarkeringen från ”{ $subject }”
agent-log-archived = Arkiverade ”{ $subject }”
agent-log-folder = Skapade mappen ”{ $name }”
agent-log-unsubscribed = Du godkände begäran om att avsluta prenumerationen. Meddelande: ”{ $subject }”
agent-log-unsubscribe-failed = Begäran om att avsluta prenumerationen misslyckades. Meddelande: ”{ $subject }”. Orsak: { $reason }
agent-log-unsubscribe-refused = Du avböjde begäran om avanmälan. Avsändare: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } vill avsluta din prenumeration på en e-postlista
   *[other] { $program } vill avsluta dina prenumerationer på { $count } e-postlistor
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic ber e-postlistan nedan att avsluta din prenumeration via listans funktion för avanmälan med ett klick. Inget e-postmeddelande skickas och dina befintliga meddelanden ändras inte.
   *[other] Inbox Classic ber varje e-postlista nedan att avsluta din prenumeration via listans funktion för avanmälan med ett klick. Inget e-postmeddelande skickas och dina befintliga meddelanden ändras inte.
}
# review: new
agent-log-flag-color = Gav ”{ $subject }” { $color ->
    [red] röd
    [orange] orange
    [yellow] gul
    [green] grön
    [blue] blå
    [purple] lila
   *[gray] grå
} flagga
# review: new
agent-log-renamed = Bytte namn på mappen ”{ $old }” till ”{ $name }”
# review: new
agent-log-watched = Började bevaka konversationen ”{ $subject }”
# review: new
agent-log-ignored = Började ignorera konversationen ”{ $subject }”
# review: new
agent-log-unmarked = Slutade bevaka eller ignorera konversationen ”{ $subject }”
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = { $count ->
    [one] läste 1 meddelande
   *[other] läste { $count } meddelanden
}
# review: new
agent-reads-attachments = { $count ->
    [one] öppnade 1 bilaga
   *[other] öppnade { $count } bilagor
}
# review: new
agent-reads-searches = { $count ->
    [one] sökte en gång
   *[other] sökte { $count } gånger
}
# review: new
agent-reads-lists = { $count ->
    [one] tittade på en meddelandelista en gång
   *[other] tittade på meddelandelistor { $count } gånger
}
# each read under that row
# review: new
agent-read-message = Läste ”{ $subject }”
# review: new
agent-read-conversation = { $count ->
    [one] Läste konversationen ”{ $subject }” (1 meddelande)
   *[other] Läste konversationen ”{ $subject }” ({ $count } meddelanden)
}
# review: new
agent-read-attachment = Öppnade ”{ $name }” i ”{ $subject }”
# review: new
agent-read-search = { $count ->
    [one] Sökte efter ”{ $query }”: 1 meddelande
   *[other] Sökte efter ”{ $query }”: { $count } meddelanden
}
# review: new
agent-read-people = Slog upp personer som börjar med ”{ $query }”
# review: new
agent-read-list = { $count ->
    [one] Tittade på 1 meddelande i mappen ”{ $folder }”
   *[other] Tittade på { $count } meddelanden i mappen ”{ $folder }”
}
# review: new
agent-read-changes = { $count ->
    [one] Tittade på 1 nytt meddelande
   *[other] Tittade på { $count } nya meddelanden
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = Program som startats från { $terminal }
# review: new
agent-terminal-programs-windows = Program som startats från en terminal ({ $terminal })
# review: new
agent-terminal-programs-linux = Program som startats från en terminal ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = Ett program som startats från { $terminal }
# review: new
agent-terminal-program-windows = Ett program som startats från en terminal ({ $terminal })
# review: new
agent-terminal-program-linux = Ett program som startats från en terminal ({ $terminal })
# review: new
agent-connect-title-terminal = { $programs } vill ha åtkomst till din e-post
# review: new
agent-connect-terminal-detail = Alla AI-agenter som du startar från den här terminalen delar den åtkomst du tillåter här. Om du vill ge en agent egen åtkomst lägger du till --name och ett valfritt namn bland dess argument i agentens MCP-inställningar.

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
pgp-part-encrypted = Krypterat. { $signature }
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
pgp-why-not-key-in-use = Signerat med en annan nyckel än den som används för { $address }
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
# review: changed
pgp-keyserver-off = Sökning efter nycklar på keys.openpgp.org är avstängd under { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Meddelandet krypteras och signeras digitalt när det skickas. Bara du och { $addresses } kan läsa innehållet.
   *[other] Meddelandet krypteras och signeras digitalt när det skickas. Bara du och de { $count } mottagarna kan läsa innehållet.
}
pgp-compose-encrypt-ready = Meddelandet krypteras och signeras digitalt när det skickas. Lägg till mottagare vars nycklar du har.
pgp-compose-missing = { $count ->
    [one] En användbar krypteringsnyckel saknas för { $addresses }. Meddelandet kan ännu inte krypteras.
   *[other] { $count } mottagare saknar användbara krypteringsnycklar: { $addresses }. Meddelandet kan ännu inte krypteras.
}
pgp-compose-looking = Söker efter nycklar för { $addresses }...
pgp-compose-signed = Meddelandet signeras digitalt när det skickas. Mottagarna kan kontrollera om innehållet har ändrats efter signeringen.
pgp-compose-reply-clear = Meddelandet skickas utan kryptering, trots att det ursprungliga meddelandet var krypterat.
pgp-compose-encrypted-files = Meddelandet innehåller bilagor från ett krypterat meddelande och kan därför bara skickas krypterat. Aktivera ”Kryptera” eller ta bort bilagorna.
pgp-compose-sign-tip = Signera meddelandet digitalt med din nyckel så att mottagarna kan kontrollera om innehållet har ändrats efter signeringen
pgp-compose-sign-tip-encrypted = Meddelanden som skickas krypterade signeras också digitalt
pgp-compose-encrypt-tip = Kryptera innehållet så att bara du och mottagarna kan läsa det
pgp-compose-make-key = Du har ännu ingen egen nyckel för adressen { $address }. Vill du skapa en nu? Med den kan du signera och kryptera meddelanden.
pgp-compose-key-unusable =
    Din nyckel för adressen { $address } kan inte användas.

    Orsak: { $state }

    Öppna ”Krypteringsnycklar” för att importera en säkerhetskopia av nyckeln eller skapa en ny nyckel.
pgp-compose-encrypt-off-quote = Meddelandet innehåller text, bilder eller bilagor från ett krypterat meddelande. Du måste ta bort det innehållet innan du kan skicka utan kryptering. Vill du ändå stänga av krypteringen?
pgp-compose-encrypt-off-reply = Du svarar på eller vidarebefordrar ett krypterat meddelande. Utan kryptering kan även servrar som förmedlar ditt meddelande läsa innehållet. Vill du stänga av krypteringen?
pgp-recipient-verified = Nyckelns ägare är verifierad
pgp-recipient-found = Nyckelns ägare är inte verifierad
pgp-recipient-own = Din egen nyckel
pgp-recipient-looking = Söker efter en nyckel...
pgp-recipient-missing = Ingen nyckel
pgp-recipient-not-found = Ingen nyckel hittades. Senaste sökning: { $date }
pgp-recipient-unusable = Nyckeln kan inte användas: { $state }
pgp-recipients-intro = När meddelandet skickas krypteras det med mottagarnas nycklar och din egen nyckel.
pgp-recipients-intro-missing = { $count ->
    [one] En mottagare saknar en användbar krypteringsnyckel. Sök efter mottagarens nyckel, ta bort mottagaren från meddelandet eller skicka det utan kryptering.
   *[other] { $count } mottagare saknar användbara krypteringsnycklar. Sök efter deras nycklar, ta bort mottagarna från meddelandet eller skicka det utan kryptering.
}
# review: new
pgp-details-part = Del { $number }: { $label }
# review: new
attachment-from-part = Från del { $number }: { $label }
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
pgp-bar-count-encrypted-signed = { $count ->
    [one] { $count } krypterad och signerad
   *[other] { $count } krypterade och signerade
}
# review: new
pgp-bar-count-encrypted = { $count ->
    [one] { $count } krypterad
   *[other] { $count } krypterade
}
# review: new
pgp-bar-count-signed = { $count ->
    [one] { $count } signerad
   *[other] { $count } signerade
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
# review: new
attachment-runs-programs = ”{ $name }” kan köra program, så Inbox Classic öppnar den inte. Spara den och öppna den sedan själv om du litar på var den kommer ifrån.
# review: new
attachment-decrypted-note = Den här bilagan kommer från ett krypterat meddelande. För att kunna öppna den sparar Inbox Classic den dekrypterad på den här datorn, i en mapp som tillhör dig och som Inbox Classic tömmer efter en dag.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Servern flyttade inte { $messages } till { $folder }, så det ligger i { $from } igen: { $reason }
   *[other] Servern flyttade inte { $messages } till { $folder }, så de ligger i { $from } igen: { $reason }
}
undone-delete = { $count ->
    [one] Servern tog inte bort { $messages }, så det ligger i { $from } igen: { $reason }
   *[other] Servern tog inte bort { $messages }, så de ligger i { $from } igen: { $reason }
}
undone-archive = { $count ->
    [one] Servern arkiverade inte { $messages }, så det ligger i { $from } igen: { $reason }
   *[other] Servern arkiverade inte { $messages }, så de ligger i { $from } igen: { $reason }
}
undone-read = { $count ->
    [one] Servern markerade inte { $messages } som läst, så det är oläst igen: { $reason }
   *[other] Servern markerade inte { $messages } som lästa, så de är olästa igen: { $reason }
}
undone-unread = { $count ->
    [one] Servern markerade inte { $messages } som oläst, så det är läst igen: { $reason }
   *[other] Servern markerade inte { $messages } som olästa, så de är lästa igen: { $reason }
}
undone-flags = { $count ->
    [one] Servern ändrade inte flaggorna för { $messages }, så ändringen har ångrats: { $reason }
   *[other] Servern ändrade inte flaggorna för { $messages }, så ändringen har ångrats: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Visa PDF-filer i meddelanden
# review: new
preview-pdf-off = PDF-filer visas inte i meddelanden.
# review: new
preview-pdf-off-crashed = En PDF-fil stängde Inbox Classic medan den visades, så PDF-filer visas inte längre i meddelanden. Bilder visas fortfarande. Slå på { $option } under { $settings } för att visa PDF-filer igen.
# review: new
preview-pdf-details = { $count ->
    [one] 1 sida, { $size }
   *[other] { $count } sidor, { $size }
}
# review: new
preview-page-alt = { $name }, sida { $page } av { $count }
# review: new
preview-more-pages = { $count ->
    [one] Öppna filen för att se sidan
   *[other] Öppna filen för att se alla { $count } sidor
}
# review: new
preview-more-files = { $count ->
    [one] 1 fil till finns i listan ovan
   *[other] { $count } filer till finns i listan ovan
}
# review: new
preview-tile-downloading = Hämtar…
# review: new
preview-tile-preparing = Förbereder…
# review: new
preview-tile-format = { $format }-bilder visas inte ännu
# review: new
preview-tile-password = Skyddad med lösenord: öppna den för att ange lösenordet
# review: new
preview-tile-too-large = För stor för att visas
# review: new
preview-tile-unreadable = Kan inte visas
# review: new
preview-tile-timed-out = Det tog för lång tid att visa
# review: new
preview-tile-crashed = Visas inte: filen stängde Inbox Classic en gång
# review: new
preview-tile-off = Visas inte förrän Inbox Classic startas igen
# review: new
preview-not-printed = { $name } ({ $details }) skrivs inte ut. Öppna filen för att skriva ut den.
