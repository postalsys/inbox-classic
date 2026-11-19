# Svenska. Utkast, väntar på granskning av en person med svenska som modersmål (se core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Swedish: [one] and *[other].

## Counts and sizes

messages = { $count ->
    [one] { $count } meddelande
   *[other] { $count } meddelanden
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] { $count } byte
   *[other] { $count } byte
}
size-kb = { $size } kB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Av
send-delay-seconds = { $count ->
    [one] { $count } sekund
   *[other] { $count } sekunder
}
# the status bar: "12 meddelanden, 3 olästa"
list-counts = { $messages }, olästa: { $unread }
list-counts-selected = { $messages }, olästa: { $unread }, markerade: { $selected }
# the status bar while searching: "12 hittade, 3 olästa"
list-counts-found = Sökträffar: { $found }, olästa: { $unread }
list-counts-found-selected = Sökträffar: { $found }, olästa: { $unread }, markerade: { $selected }
list-counts-none = Inga meddelanden hittades

## Special folders, as Outlook names them in Swedish

folder-inbox = Inkorgen
folder-sent = Skickat
folder-deleted = Borttaget
folder-drafts = Utkast
folder-junk = Skräppost
folder-archive = Arkiv

## The reading pane

reader-no-message = Inget meddelande är markerat.
reader-downloading = Hämtar meddelandet…
reader-downloading-detail = Meddelandet visas här när hämtningen är klar.
reader-downloading-size = Meddelandet är { $size }. Det visas här när det har hämtats.
reader-failed = Det gick inte att hämta meddelandet
reader-failed-network = Anslutningen till e-postservern misslyckades eller avbröts ({ $reason }).
reader-failed-sign-in = E-postservern godtog inte inloggningen ({ $reason }). Kontrollera lösenordet eller logga in igen i kontoinställningarna.
reader-failed-security = Anslutningen till e-postservern kunde inte göras säker ({ $reason }).
reader-failed-other = E-postservern svarade: { $reason }.
reader-retry-note = Ett nytt försök görs när kontot ansluter igen.
reader-unreadable = Det här meddelandet kan inte visas: { $error }
message-source-title = Meddelandets källkod: { $subject }
message-source-untitled = Meddelandets källkod

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Från
header-date = Datum
header-to = Till
header-cc = Kopia
header-sent = Skickat
header-subject = Ämne
header-security = Säkerhet
header-part = Del { $number }
quote-original = ----- Ursprungligt meddelande -----
fold-show-earlier = Visa tidigare meddelanden

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Ditt meddelande levererades inte
bounce-delayed = Ditt meddelande har inte levererats ännu
bounce-delayed-note = Din e-postserver försöker fortfarande leverera det. Du behöver inte skicka det igen.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Visa meddelandet som studsade
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Visa det fördröjda meddelandet
bounce-what-to-do = Det här kan du göra:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Inget ännu. Om det fortfarande inte kan levereras får du ett nytt meddelande om det.
bounce-delayed-row-do = Inget ännu. Din e-postserver försöker fortfarande leverera det, och du får ett nytt meddelande om det inte går.
# folds the receiving server's own words
bounce-details = Detaljer
# a recipient the notice does not name
bounce-someone = En mottagare
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Rapporterat av: { $server }
bounce-retry-minutes = Den mottagande servern bad att nästa försök skulle göras om { $count ->
    [one] en minut
   *[other] { $count } minuter
}.
bounce-retry-hours = Den mottagande servern bad att nästa försök skulle göras om { $count ->
    [one] en timme
   *[other] { $count } timmar
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Blocklista: { $lists }
bounce-user-unknown = Adressen finns inte
bounce-user-unknown-why = Den mottagande servern har ingen brevlåda med den här adressen. Adressen kan vara felskriven eller inte längre användas.
bounce-user-unknown-do = Kontrollera att adressen är rättstavad eller be personen om en aktuell adress.
bounce-invalid-address = Adressen är inte giltig
bounce-invalid-address-why = Adressen är inte skriven så att e-post kan skickas till den.
bounce-invalid-address-do = Leta efter skrivfel, till exempel ett mellanslag, en bokstav som saknas eller inget efter @.
bounce-mailbox-disabled = Brevlådan är stängd
bounce-mailbox-disabled-why = Adressen finns, men brevlådan har stängts av eller används inte längre.
bounce-mailbox-disabled-do = Kontakta personen på något annat sätt och be om en aktuell adress.
bounce-mailbox-full = Brevlådan är full
bounce-mailbox-full-why = Mottagarens brevlåda har inte plats för ny e-post.
bounce-mailbox-full-do = Försök igen om några dagar eller meddela personen på något annat sätt. Du kan också prova att skicka utan stora bilagor.
bounce-spam-blocked = Avvisat som skräppost
bounce-spam-blocked-why = Den mottagande servern bedömde meddelandet som skräppost.
bounce-spam-blocked-do = Skicka det igen utan det som ser ut som skräppost, till exempel många länkar, förkortade länkar eller en stor bilaga. Om det fortsätter att hända kan du fråga din e-postleverantör.
bounce-virus-detected = Avvisat på grund av virus
bounce-virus-detected-why = Enligt den mottagande servern innehåller meddelandet eller dess bilagor virus eller annat skadligt innehåll.
bounce-virus-detected-do = Kontrollera bilagorna med ett antivirusprogram. Vissa servrar avvisar alla program och arkiv, så dela sådana filer som en länk i stället.
bounce-ip-blocklisted = Din e-postserver finns på en blocklista
bounce-ip-blocklisted-why = Den mottagande servern avvisar e-post från servern som skickade din, eftersom den serverns adress finns på en blocklista.
bounce-ip-blocklisted-do = Det är inte meddelandet som är problemet. Vidarebefordra det här meddelandet till din e-postleverantör och be dem att få servern borttagen från listan.
bounce-domain-blocklisted = En domän finns på en blocklista
bounce-domain-blocklisted-why = Den mottagande servern avvisar meddelandet eftersom domänen i din adress, eller en domän i meddelandets länkar, finns på en blocklista.
bounce-domain-blocklisted-do = Om meddelandet innehåller länkar kan du försöka utan dem. Annars vidarebefordrar du det här meddelandet till den som sköter e-posten för din domän.
bounce-policy-blocked = Avvisat av den mottagande serverns regler
bounce-policy-blocked-why = Den mottagande serverns regler släpper inte igenom meddelandet, till exempel på grund av dess storlek, bilagor eller avsändare.
bounce-policy-blocked-do = Serverns svar under Detaljer anger ofta orsaken. Fråga mottagaren om den här typen av e-post kan tas emot.
bounce-geo-blocked = Avvisat på grund av ursprung
bounce-geo-blocked-why = Den mottagande servern tar inte emot e-post från det land eller nätverk där din e-postserver finns.
bounce-geo-blocked-do = Kontakta personen på något annat sätt eller fråga din e-postleverantör om saken.
bounce-relay-denied = Servern vägrade skicka meddelandet vidare
bounce-relay-denied-why = En server vägrade att leverera meddelandet vidare, ofta för att det skickades utan inloggning eller via en server som inte hanterar den här mottagaren.
bounce-relay-denied-do = Kontrollera servern för utgående e-post och inloggningen i kontoinställningarna.
bounce-auth-failure = Din avsändaradress kunde inte verifieras
bounce-auth-failure-why = Den mottagande servern kunde inte bekräfta att meddelandet verkligen kom från din domän (SPF, DKIM eller DMARC).
bounce-auth-failure-do = Vidarebefordra det här meddelandet till den som sköter e-posten för din domän: dess inställningar behöver rättas. Under tiden kan det hjälpa att skicka via din leverantörs egen server.
bounce-rate-limited = För mycket e-post på en gång
bounce-rate-limited-why = Den mottagande servern tar för tillfället emot färre meddelanden från din e-postserver.
bounce-rate-limited-do = Vänta en stund och skicka det igen. När du skriver till många personer kan du skicka till färre åt gången.
bounce-greylisting = Tillfälligt fördröjt
bounce-greylisting-why = Den mottagande servern ber okända avsändare att försöka igen lite senare, en vanlig kontroll mot skräppost.
bounce-greylisting-do = Vänta om servern fortfarande försöker leverera meddelandet. Om leveransförsöken har upphört kan du skicka det igen senare.
bounce-server-error = Den mottagande servern hade ett problem
bounce-server-error-why = Den mottagande servern kunde inte nås, eller kunde inte ta emot meddelandet på grund av ett eget problem.
bounce-server-error-do = Skicka det igen senare. Om det fortsätter att misslyckas kan du kontrollera delen av adressen efter @ för skrivfel.
bounce-unknown = Inte levererat
bounce-unknown-why = Meddelandet anger inte tydligt varför.
bounce-unknown-do = Serverns egna ord under Detaljer kan säga mer. Om de inte hjälper kan du vidarebefordra det här meddelandet till din e-postleverantör.

## Several messages selected

selection-title = { $count ->
    [one] { $count } meddelande markerat
   *[other] { $count } meddelanden markerade
}
selection-unread = Olästa: { $count }
selection-flagged = Flaggade: { $count }
delete-for-good-one = Meddelandet tas bort permanent. Vill du ta bort det?
delete-for-good-all = De här { $count } meddelandena tas bort permanent. Vill du ta bort dem?
delete-for-good-some = { $count } av de { $total } meddelandena tas bort permanent. Vill du ta bort meddelandena?
done-read = { $count ->
    [one] { $messages } markerades som läst
   *[other] { $messages } markerades som lästa
}
done-unread = { $count ->
    [one] { $messages } markerades som oläst
   *[other] { $messages } markerades som olästa
}
done-flagged = { $count ->
   *[other] { $messages } flaggades
}
done-unflagged = Flaggan togs bort från { $messages }
done-deleted-for-good = { $count ->
   *[other] { $messages } togs bort permanent
}
done-archived = { $count ->
   *[other] { $messages } arkiverades
}
done-moved = { $count ->
   *[other] { $messages } flyttades till { $folder }
}
done-copied = { $count ->
   *[other] { $messages } kopierades till { $folder }
}
done-moving = { $count ->
   *[other] Flyttar { $messages } till { $folder }...
}
done-copying = { $count ->
   *[other] Kopierar { $messages } till { $folder }...
}
done-moved-back = { $count ->
   *[other] { $messages } flyttades tillbaka till { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Bevakar konversationen
   *[other] Bevakar { $count } konversationer
}
done-unwatched = { $count ->
    [one] Slutade bevaka konversationen
   *[other] Slutade bevaka { $count } konversationer
}
done-ignored = { $count ->
    [one] Ignorerar konversationen
   *[other] Ignorerar { $count } konversationer
}
done-unignored = { $count ->
    [one] Slutade ignorera konversationen
   *[other] Slutade ignorera { $count } konversationer
}
their-folders = respektive mapp
undo-move = Ångra flytt
undo-delete = Ångra borttagning
undo-archive = Ångra arkivering
undo-junk = Ångra skräppostmarkering
undo-not-junk = Ångra borttagen skräppostmarkering
undo-send = Ångra sändning
nothing-to-undo = Det finns inget att ångra.
messages-gone = Meddelandena finns inte längre kvar.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Den här mappen kan inte innehålla meddelanden.
not-archived-here = Meddelanden i den här mappen kan inte arkiveras.
not-emptied-here = Bara Borttaget och Skräppost kan tömmas.
next-unread-question = Det finns inga fler olästa meddelanden i { $folder }.

    Vill du gå till { $next }, nästa mapp med olästa meddelanden?
no-unread-left = Det finns inga olästa meddelanden kvar.
empty-question = { $count ->
    [one] Vill du tömma { $folder }?

        Meddelandet i mappen tas bort permanent. Det kan inte återställas.
   *[other] Vill du tömma { $folder }?

        Alla { $messages } i mappen tas bort permanent. De kan inte återställas.
}
no-junk-folder = Kontot har ingen mapp för skräppost att flytta meddelandena till.
no-inbox-folder = Kontot har ingen Inkorg att flytta meddelandena till.
# the status bar after a flag in a colour: "2 meddelanden fick röd flagga"
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

move-window-title-move = { $count ->
    [one] Flytta meddelande
   *[other] Flytta { $count } meddelanden
}
move-window-title-copy = { $count ->
    [one] Kopiera meddelande
   *[other] Kopiera { $count } meddelanden
}
move-window-prompt-move = { $count ->
    [one] Flytta det markerade meddelandet till:
   *[other] Flytta de { $count } markerade meddelandena till:
}
move-window-prompt-copy = { $count ->
    [one] Kopiera det markerade meddelandet till:
   *[other] Kopiera de { $count } markerade meddelandena till:
}
# the folders used last, over the folder tree
targets-recent = Senaste
# the folder the messages are in, which can not be chosen
target-current = { $folder } (nuvarande)
# a folder used last, with its account when there are several: "Arkiv (Arbete)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Flyttar { $done } av { $messages } till { $folder }...
transfer-copying = Kopierar { $done } av { $messages } till { $folder }...
transfer-another-account = ett annat konto
transfer-folder-gone = mappen som det skulle till finns inte längre
transfer-not-on-server = meddelandet finns inte längre på servern
transfer-not-moved = { $count ->
   *[other] { $messages } kunde inte flyttas till ett annat konto: { $reason }
}
transfer-not-copied = { $count ->
   *[other] { $messages } kunde inte kopieras till ett annat konto: { $reason }
}
transfer-none-moved = Inget meddelande kunde flyttas
transfer-none-copied = Inget meddelande kunde kopieras

## Messages as files

export-not-in-time = meddelandet kunde inte hämtas i tid
export-not-saved = { $failed } av { $messages } kunde inte sparas ({ $problems })
export-not-attached = meddelandena kunde inte bifogas: { $error }
# the status bar after Save As with several: "3 meddelanden sparades i Skrivbord"
saved-to = { $count ->
   *[other] { $messages } sparades i { $folder }
}
download-progress = Hämtar { $done } av { $total }
download-done = { $size } hämtat
downloading-messages = { $count ->
   *[other] Hämtar { $messages }...
}
# the status bar after files are dropped on a folder: "3 meddelanden lades i Arkiv"
import-put = { $count ->
   *[other] { $messages } har köats för import till { $folder }
}
import-not-put = Följande kunde inte köas för import:

    { $problems }
## Problems the windows show

error-store = lokalt lager: { $error }
error-not-found = hittades inte
error-closed = avslutas
error-other-account = webbläsaren loggade in på { $email }, inte på det här kontot
# a password or sign-in the mail server refused, with the server's words
failure-authentication = servern godtog inte inloggningen ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = anslutningen till servern misslyckades ({ $reason })
error-in-use = den kan inte tas bort medan konton loggar in med den: { $accounts }
error-turned-off = den här inloggningsappen är avstängd för nya konton
error-folder-name = mappnamnet måste vara 1 till 200 tecken långt och får inte innehålla styrtecken
error-folder-separator = ett mappnamn får inte innehålla ”{ $separator }” på den här servern
error-folder-special = det går inte att byta namn på eller ta bort Inkorgen och specialmapparna
error-no-recipients = meddelandet har inga mottagare
error-bad-address = ”{ $address }” är inte en e-postadress
error-not-own-address = { $address } är inte en av kontots avsändaradresser. Lägg till den i ”Andra adresser du skickar från” i kontots egenskaper.
rule-query-refused = Regler kan inte filtrera efter mapp eller datum ({ $words }).
rule-no-query = Ange sökvillkor för inkommande meddelanden.
rule-no-action = Välj minst en åtgärd för regeln.
error-attachment = { $path } kunde inte läsas: { $error }
error-no-drafts = kontot har ingen mapp för utkast att spara meddelandet i
error-draft-attachment = en bilaga i utkastet kunde inte behållas: { $error }
error-password-not-saved = lösenordet kunde inte sparas till nästa start: { $error }
error-sign-in-not-saved = de nya inloggningsuppgifterna kunde inte sparas till nästa start: { $error }
error-import-unreadable = { $path } kan inte läsas: { $error }
error-import-too-large = { $path } är större än 50 MB
error-import-not-mail = { $path } är inte ett e-postmeddelande
error-list-answered = e-postlistans server svarade med status { $status }
error-not-built = meddelandet kunde inte skapas
error-outbox-waits = { $count ->
    [one] meddelandet väntar i Utkorgen. Ett nytt försök att skicka det görs vid nästa Skicka/ta emot
   *[other] { $count } meddelanden väntar i Utkorgen. Ett nytt försök att skicka dem görs vid nästa Skicka/ta emot
}
error-draft-not-removed = det tidigare utkastet av meddelandet kunde inte tas bort från Utkast: { $reason }
error-sent-but = meddelandet skickades, men { $problem }
error-sent-still-in-outbox = det finns fortfarande i Utkorgen: { $error }
error-sent-no-copy = ingen kopia kunde sparas i Skickat: { $reason }
error-no-password = inget lösenord för det här kontot
error-no-sign-in = ingen inloggning för det här kontot
error-provider-missing = den här versionen kan inte logga in på { $provider }: har dess inloggningsapp tagits bort?
error-provider-servers = kontots servrar stämmer inte med inloggningsappens servrar
error-app-scopes = { $reason }. E-postservern godtog inte inloggningsappens token: kontrollera att appens behörigheter (scopes) ger åtkomst till e-post
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Den inbyggda inloggningsappen för Google har begränsad användning, till exempel för testanvändare, och är avstängd från början. Använd en egen inloggningsapp för Google eller ett applösenord om kontot tillåter det. Om du har rätt att använda den inbyggda appen kan du slå på den i Inloggningsappar (Arkiv > Konton).
sign-in-off-other = Den stängdes av i Inloggningsappar (Arkiv > Konton), där den kan slås på igen.
sign-in-app-no-name = inloggningsappen behöver ett namn
sign-in-app-no-client = klient-ID saknas
sign-in-app-no-scopes = inloggningsappen behöver de behörigheter (scopes) som ger åtkomst till e-post
sign-in-app-bad-host = serveradressen för { $server } saknas eller har ett ogiltigt värdnamn eller portnummer
sign-in-app-plain = servern för { $server } måste använda SSL/TLS eller STARTTLS
sign-in-app-not-checked = utfärdaren har inte kontrollerats ännu
sign-in-app-issuer-changed = utfärdaren har ändrats: skriv klienthemligheten igen, eller ta bort den
sign-in-register-google = Skapa en OAuth-klient av typen Desktop app i Google Cloud Console, med behörigheten https://mail.google.com/ på dess samtyckesskärm. Medan appen är i testläge kan bara dess testanvändare logga in.
sign-in-register-microsoft = Registrera en app i Microsoft Entra med plattformen Mobile and desktop applications, omdirigerings-URI:n http://localhost och offentliga klientflöden tillåtna, samt de delegerade behörigheterna IMAP.AccessAsUser.All, SMTP.Send och offline_access. Om bara din organisation ska använda den anger du https://login.microsoftonline.com/<klientorganisations-ID>/v2.0 som utfärdare.
sign-in-register-other = Registrera en offentlig klient för en installerad app med omdirigerings-URI:n nedan. Leverantören måste tillåta valfri port för denna URI (RFC 8252). Lägg till den behörighet som leverantören kräver för åtkomst till e-post.
## Calendar invitations

repeats = Upprepas
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Varje dag
       *[other] Med { $interval } dagars mellanrum
    }
    [week] { $interval ->
        [one] Varje vecka
       *[other] Med { $interval } veckors mellanrum
    }
    [month] { $interval ->
        [one] Varje månad
       *[other] Med { $interval } månaders mellanrum
    }
   *[year] { $interval ->
        [one] Varje år
       *[other] Med { $interval } års mellanrum
    }
}
# "Varje vecka på måndag, onsdag"
repeats-on = { $repeats } på { $days }
# "Varje vecka, 10 gånger"
repeats-times = { $repeats }, antal tillfällen: { $count }
day-monday = måndag
day-tuesday = tisdag
day-wednesday = onsdag
day-thursday = torsdag
day-friday = fredag
day-saturday = lördag
day-sunday = söndag

## AI agents

agent-level-read = Läsa e-post: mappar, meddelandelistor, konversationer, sökningar, meddelanden och deras filer, meddelanderegler och personer du skriver till
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
agent-too-many-changes = För många ändringar de senaste 30 dagarna: den här agenten har gjort så många som Inbox Classic sparar i loggen för ett program. Den kan göra fler när de äldsta är 30 dagar gamla.
agent-too-many-reads = För mycket läst de senaste 30 dagarna: den här agenten har läst så mycket som Inbox Classic sparar i loggen för ett program. Den kan läsa mer när de äldsta läsningarna är 30 dagar gamla.
list-encrypted = Krypterat meddelande
agent-log-composed = Öppnade ett nytt meddelande för redigering. Ämne: ”{ $subject }”
agent-log-refused = Du avböjde att skicka meddelandet ”{ $subject }”
agent-log-sent = Lade meddelandet ”{ $subject }” i kö för att skickas. Mottagare: { $to }
agent-log-draft = Sparade utkastet ”{ $subject }”
agent-log-draft-replaced = Ersatte utkastet ”{ $subject }”
agent-log-draft-discarded = Begärde permanent borttagning av utkastet ”{ $subject }”
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
agent-log-folder = Begärde att mappen ”{ $name }” skulle skapas
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
agent-log-flag-color = Gav ”{ $subject }” { $color ->
    [red] röd
    [orange] orange
    [yellow] gul
    [green] grön
    [blue] blå
    [purple] lila
   *[gray] grå
} flagga
agent-log-renamed = Begärde namnbyte på mappen ”{ $old }” till ”{ $name }”
agent-log-watched = Började bevaka konversationen ”{ $subject }”
agent-log-ignored = Började ignorera konversationen ”{ $subject }”
agent-log-unmarked = Slutade bevaka eller ignorera konversationen ”{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = meddelandet har ändrats sedan dess
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Markerade 1 meddelande som läst (sökning: { $query })
   *[other] Markerade { $count } meddelanden som lästa (sökning: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Markerade 1 meddelande som oläst (sökning: { $query })
   *[other] Markerade { $count } meddelanden som olästa (sökning: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Flaggade 1 meddelande (sökning: { $query })
   *[other] Flaggade { $count } meddelanden (sökning: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Tog bort flaggan från 1 meddelande (sökning: { $query })
   *[other] Tog bort flaggan från { $count } meddelanden (sökning: { $query })
}
agent-log-bulk-color = { $count ->
    [one] Gav 1 meddelande
   *[other] Gav { $count } meddelanden
} { $color ->
    [red] röd
    [orange] orange
    [yellow] gul
    [green] grön
    [blue] blå
    [purple] lila
   *[gray] grå
} flagga (sökning: { $query })
agent-log-bulk-moved = { $count ->
    [one] Flyttade 1 meddelande till mappen ”{ $folder }” (sökning: { $query })
   *[other] Flyttade { $count } meddelanden till mappen ”{ $folder }” (sökning: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Arkiverade 1 meddelande (sökning: { $query })
   *[other] Arkiverade { $count } meddelanden (sökning: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Markerade 1 meddelande som skräppost (sökning: { $query })
   *[other] Markerade { $count } meddelanden som skräppost (sökning: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Tog bort skräppostmarkeringen från 1 meddelande (sökning: { $query })
   *[other] Tog bort skräppostmarkeringen från { $count } meddelanden (sökning: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Tog bort 1 meddelande (sökning: { $query })
   *[other] Tog bort { $count } meddelanden (sökning: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] Under de senaste 15 minuterna
    [hour] Under den senaste timmen
    [hours] Under de senaste 4 timmarna
    [day] Under de senaste 24 timmarna
    [week] Under de senaste 7 dagarna
   *[all] Under de senaste 30 dagarna
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] { $program } gjorde inga ändringar under den här tiden som kan ångras.
    [one] Vill du ångra ändringen som { $program } gjorde under den här tiden?
   *[other] Vill du ångra de { $count } ändringar som { $program } gjorde under den här tiden?
}
agent-undo-since-detail = Meddelanden flyttas tillbaka, lästmarkeringar och flaggor återställs och meddelanden som väntar i Utkorgen tas bort. Varje åtgärd kontrolleras innan den ångras och kan hoppas över om förutsättningarna har ändrats. Andra senare ändringar skyddas inte alltid; till exempel kan en senare vald flaggfärg tas bort.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Ingenting ångrades.
    [one] Ångrade 1 ändring, helt eller delvis.
   *[other] Ångrade { $count } ändringar, helt eller delvis.
}
agent-undo-left-gone = { $count ->
    [one] 1 meddelande fanns inte längre där ändringen lade det.
   *[other] { $count } meddelanden fanns inte längre där ändringen lade dem.
}
agent-undo-left-changed = { $count ->
    [one] 1 meddelande har ändrats sedan dess, av dig eller på servern, och lämnades som det är.
   *[other] { $count } meddelanden har ändrats sedan dess, av dig eller på servern, och lämnades som de är.
}
agent-undo-left-sent = { $count ->
    [one] 1 meddelande hade redan lämnat Utkorgen.
   *[other] { $count } meddelanden hade redan lämnat Utkorgen.
}
agent-undo-left-impossible = { $count ->
    [one] 1 ändring kan inte ångras.
   *[other] { $count } ändringar kan inte ångras.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Det här meddelandet tackar ja till inbjudan ”{ $summary }” ({ $when }).
    [tentative] Det här meddelandet tackar preliminärt ja till inbjudan ”{ $summary }” ({ $when }).
   *[decline] Det här meddelandet tackar nej till inbjudan ”{ $summary }” ({ $when }).
} Svaret skickas till organisatören. Inbox Classic uppdaterar ditt svar på inbjudan när meddelandet har skickats.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Accepterat: { $summary }
    [tentative] Preliminärt: { $summary }
   *[decline] Avböjt: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } har accepterat den här inbjudan.
    [tentative] { $name } har preliminärt accepterat den här inbjudan.
   *[decline] { $name } har avböjt den här inbjudan.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] läste 1 meddelande
   *[other] läste { $count } meddelanden
}
agent-reads-attachments = { $count ->
    [one] begärde innehållet i 1 bilaga
   *[other] begärde innehållet i { $count } bilagor
}
agent-reads-searches = { $count ->
    [one] sökte en gång
   *[other] sökte { $count } gånger
}
agent-reads-lists = { $count ->
    [one] tittade på en meddelandelista en gång
   *[other] tittade på meddelandelistor { $count } gånger
}
# each read under that row
agent-read-message = Läste ”{ $subject }”
agent-read-conversation = { $count ->
    [one] Läste konversationen ”{ $subject }” (1 meddelande)
   *[other] Läste konversationen ”{ $subject }” ({ $count } meddelanden)
}
agent-read-attachment = Begärde innehållet i bilagan ”{ $name }” från meddelandet ”{ $subject }”
agent-read-search = { $count ->
    [one] Sökte efter ”{ $query }”: 1 meddelande
   *[other] Sökte efter ”{ $query }”: { $count } meddelanden
}
agent-read-people = Sökte efter namn och adresser som börjar med ”{ $query }”
agent-read-list = { $count ->
    [one] Läste 1 rad i meddelandelistan. Område: { $folder }
   *[other] Läste { $count } rader i meddelandelistan. Område: { $folder }
}
agent-read-changes = { $count ->
    [one] Hämtade uppgifter om 1 nytt meddelande
   *[other] Hämtade uppgifter om { $count } nya meddelanden
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Program som startats från { $terminal }
agent-terminal-programs-windows = Program som startats från en terminal ({ $terminal })
agent-terminal-programs-linux = Program som startats från en terminal ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Ett program som startats från { $terminal }
agent-terminal-program-windows = Ett program som startats från en terminal ({ $terminal })
agent-terminal-program-linux = Ett program som startats från en terminal ({ $terminal })
agent-connect-title-terminal = { $programs } vill ha åtkomst till din e-post
agent-connect-terminal-detail = Agenter som startas från samma identifierade terminalprogram delar den åtkomst du tillåter här. För att hantera en agent separat lägger du till --name och ett valfritt namn bland argumenten i dess MCP-inställningar. Namnet bekräftar inte vilket program det är.
agent-connect-claimed = Programmet uppgav att det var { $claimed }. Inbox Classic har kontrollerat vilket program som startade det: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Skift
key-del = Del
key-enter = Retur

## Signing in and passwords

sign-in-no-refresh = leverantören gav ingen uppdateringstoken
sign-in-no-account = leverantören angav inte vilket konto som loggade in
sign-in-not-finished = inloggningen har inte slutförts
secrets-unavailable = { $store } är inte tillgänglig
secrets-unavailable-why = { $store } är inte tillgänglig: { $error }
secrets-windows = Autentiseringshanteraren
secrets-mac = nyckelringen
secrets-linux = systemets nyckelring (Secret Service)
error-no-such-file = filen finns inte
cards-file-too-big = Filen överskrider storleksgränsen för import av en adressbok.
ui-sender-added = { $name } lades till i adressboken.
ui-sender-known = { $name } finns redan i adressboken.
ui-sender-none = Avsändaren av det här meddelandet har ingen e-postadress att lägga till.
card-name-needed = Kontakten har inget namn och ingen e-postadress.
# a file of Import Address Book that could not be read: "kontakter.vcf: filen finns inte"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Kod från { $domain }
otp-copy = Kopiera
otp-note = Ange den bara på en sida som tillhör { $domain }.
otp-old = Enligt meddelandets datum är koden mer än en timme gammal. Den kan ha slutat gälla.
# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } deltagare
       *[other] { $count } deltagare
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } är din kod för { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Giltig
pgp-key-expires = Giltig till { $date }
pgp-key-expired = Gick ut { $date }
pgp-key-revoked = Återkallad
pgp-key-revoked-why = Återkallad: { $reason }
pgp-key-not-valid = Inte giltig
pgp-key-locked = Nyckeln kan inte låsas upp med { $store }. Kontrollera att lagret är tillgängligt och att åtkomst tillåts. Om skyddsnyckeln saknas behöver du importera säkerhetskopian av din privata nyckel.
pgp-source-own = Skapad i Inbox Classic
pgp-source-file = Importerad från en fil
pgp-source-paste = Inklistrad
pgp-source-attachment = Från ett meddelande
pgp-source-vcard = Från ett kontaktkort
pgp-source-wkd = Från avsändarens e-postleverantör
pgp-source-keyserver = Från keys.openpgp.org
pgp-source-autocrypt = Från ett meddelandes Autocrypt-huvud
pgp-error-no-store = Privata nycklar skyddas av { $store }, som inte kan användas: { $error }
pgp-error-wrong-passphrase = Lösenfrasen är inte rätt.
pgp-error-not-a-key = Det här är inte en OpenPGP-nyckel.
pgp-error-too-large = Nyckeln är för stor.
pgp-error-unusable = Nyckeln kan inte användas för åtgärden. En användbar undernyckel kan saknas, eller så stöds inte kryptografin.
pgp-imported-private = { $count ->
    [one] Din privata nyckel importerades.
   *[other] { $count } privata nycklar importerades.
}
pgp-imported-public = { $count ->
    [one] En nyckel importerades.
   *[other] { $count } nycklar importerades.
}
pgp-imported-pending = En annan nyckel används redan för { $addresses }: den nya väntar i kontakten tills du väljer den.
pgp-error-needs-passphrase = Den privata nyckeln skyddas med en lösenfras. Skriv den för att importera nyckeln.
pgp-error-mismatch = Den privata nyckeln hör inte till sin offentliga nyckel. Den kan ha ändrats.
pgp-file-name-public = { $who } offentlig nyckel.asc
pgp-file-name-private = { $who } säkerhetskopia av privat nyckel.asc
pgp-pending = En annan nyckel för { $address } hittades { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Signerad av { $signer }, nyckelns ägare verifierad
pgp-part-signed = Signerad av { $signer } (nyckelns ägare inte verifierad)
pgp-part-other = Signerad av { $signer }, som inte är avsändaren
pgp-part-unknown-key = Signerad, men nyckeln är okänd
pgp-part-not-signed = Inte signerad
pgp-part-not-checked = Signaturen har inte kontrollerats
pgp-part-encrypted = Krypterad. { $signature }
pgp-part-no-key = Krypterad med en nyckel som du inte har
pgp-part-changed = Den krypterade delens integritet kunde inte bekräftas, så den visas inte
pgp-part-unprotected = Krypterad utan skydd mot ändringar, visas inte
pgp-part-broken = Den krypterade delen kan inte läsas
pgp-why-mismatch = Signaturen stämmer inte med den här texten
pgp-why-weak-hash = Signaturen använder { $hash }, som inte längre är säker
pgp-why-key-expired = Signerad efter att nyckeln gick ut { $date }
pgp-why-key-revoked = Signerad med en nyckel som har återkallats
pgp-why-not-signing-key = Signerad med en nyckel som inte får signera
pgp-why-from-future = Signaturen är daterad i framtiden
pgp-why-signature-expired = Signaturen har gått ut
pgp-why-key-not-valid = Signerad med en nyckel som inte är giltig
pgp-why-not-for-you = Signaturen gäller andra mottagare
pgp-why-not-key-in-use = Signerat med en annan nyckel än den som används för { $address }
pgp-part-pictures-loaded = { $label }. Bilder hämtades från internet
pgp-error-no-own-key = Du har ingen nyckel för { $address } att signera eller kryptera med. Skapa en i Verktyg > Krypteringsnycklar, eller stäng av Signera och Kryptera.
pgp-error-missing-keys = { $count ->
    [one] En användbar krypteringsnyckel saknas för { $addresses }.
   *[other] Användbara krypteringsnycklar saknas för följande mottagare: { $addresses }.
}
pgp-error-encrypted-quote = Meddelandet innehåller text, bilder eller bilagor från ett krypterat meddelande. Aktivera Kryptera eller ta bort det innehållet innan du skickar.
pgp-error-protect = Meddelandet kunde inte signeras eller krypteras: { $reason }
pgp-found-keys = Nycklar hittades för: { $addresses }.
pgp-found-none = Ingen nyckel hittades för { $addresses }. Be om att få deras offentliga nyckel.
pgp-found-no-key = Ingen nyckel hittades.
pgp-find-unavailable = Nycklar kunde inte sökas upp just nu: { $error }
pgp-publish-pending = keys.openpgp.org skickade en bekräftelselänk till följande adresser: { $addresses }. Bekräfta varje adress så att nyckeln kan hittas med den adressen.
pgp-publish-done = Din nyckel är publicerad på keys.openpgp.org för { $addresses }.
pgp-publish-failed = Nyckeln kunde inte publiceras: { $error }
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
pgp-compose-key-unusable = Din nyckel för adressen { $address } kan inte användas.

    Orsak: { $state }

    Öppna ”Krypteringsnycklar” och kontrollera nyckelns status och tillgången till systemets nyckellager. Du kan behöva importera en säkerhetskopia eller skapa en ny nyckel.
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
    [one] En mottagare saknar en användbar krypteringsnyckel. Sök efter mottagarens nyckel, ta bort mottagaren från meddelandet eller skicka det utan kryptering om det inte innehåller text, bilder eller bilagor från krypterade meddelanden.
   *[other] { $count } mottagare saknar användbara krypteringsnycklar. Sök efter deras nycklar, ta bort mottagarna från meddelandet eller skicka det utan kryptering om det inte innehåller text, bilder eller bilagor från krypterade meddelanden.
}
pgp-details-part = Del { $number }: { $label }
attachment-from-part = Från del { $number }: { $label }
pgp-details-signed = Signerad { $when } med nyckeln { $key }
pgp-details-unknown-key = Signerad med nyckeln { $key }, som du inte har
pgp-details-opened = Dekrypterad med din nyckel { $key }
pgp-details-for = Krypterad med nycklarna: { $keys }
pgp-details-plain = Inte signerad och inte krypterad
pgp-bar-parts = Meddelandet har { $count } delar: { $list }. Varje del anger hur den är skyddad.
pgp-bar-count-verified = med verifierad nyckelägare: { $count }
pgp-bar-count-encrypted-signed = { $count ->
    [one] { $count } krypterad och signerad
   *[other] { $count } krypterade och signerade
}
pgp-bar-count-encrypted = { $count ->
    [one] { $count } krypterad
   *[other] { $count } krypterade
}
pgp-bar-count-signed = { $count ->
    [one] { $count } signerad
   *[other] { $count } signerade
}
pgp-bar-count-warning = { $count ->
    [one] { $count } behöver åtgärdas
   *[other] { $count } behöver åtgärdas
}
pgp-bar-count-neutral = { $count } utan bekräftad signatur
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Inställningar
setup-part-preferences = Fönsterinställningar
setup-part-accounts = Konton
setup-part-sign-in-apps = Inloggningsappar
setup-part-contacts = Kontakter och grupper
setup-part-keys = Krypteringsnycklar
setup-part-rules = Meddelanderegler
setup-part-trusted-senders = Betrodda avsändare
setup-holds-settings = { $count ->
    [one] { $count } inställning
   *[other] { $count } inställningar
}
setup-holds-preferences = { $count ->
    [one] { $count } fönsterinställning
   *[other] { $count } fönsterinställningar
}
setup-holds-accounts = { $count ->
    [one] { $count } konto
   *[other] { $count } konton
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } inloggningsapp
   *[other] { $count } inloggningsappar
}
setup-holds-built-in = Vilka inbyggda inloggningsappar som är påslagna
setup-holds-contacts = { $count ->
    [one] { $count } kontakt
   *[other] { $count } kontakter
}
setup-holds-groups = { $count ->
    [one] { $count } grupp
   *[other] { $count } grupper
}
setup-holds-own-keys = { $count ->
    [one] { $count } egen nyckel
   *[other] { $count } egna nycklar
}
setup-holds-contact-keys = { $count ->
    [one] { $count } nyckel för en kontakt
   *[other] { $count } nycklar för kontakter
}
setup-holds-rules = { $count ->
    [one] { $count } regel
   *[other] { $count } regler
}
setup-holds-trusted-senders = { $count ->
    [one] { $count } betrodd avsändare
   *[other] { $count } betrodda avsändare
}
setup-sign-in-password = Lösenord
setup-account-secret-password = Lösenordet finns i filen.
setup-account-secret-token = Inloggningsuppgifterna finns i filen.
setup-account-asks-password = Det frågar efter sitt lösenord efter importen.
setup-account-signs-in-again = Du loggar in på det igen efter importen.
setup-account-here = Det är redan konfigurerat här, så det hoppas över.
setup-account-no-app = Det loggar in med { $app }, som inte är konfigurerad här. Importera inloggningsapparna också.
setup-invalid-address = ”{ $address }” är inte en e-postadress.
setup-invalid-server = Servern { $server } har ett ogiltigt namn, portnummer eller säkerhetsalternativ.
setup-invalid-user = Det har inget användarnamn.
setup-invalid-sign-in = Kontots inloggningsinställningar är ogiltiga.
setup-error-empty = Filen är tom.
setup-error-too-large = Filen överskrider storleksgränsen för import av inställningar och konton.
setup-error-not-setup = Filen är inte en konfiguration från Inbox Classic.
setup-error-damaged = Konfigurationsfilen är skadad och kan inte läsas.
setup-error-newer = Konfigurationen sparades av en nyare Inbox Classic ({ $version }). Uppdatera Inbox Classic och importera den sedan igen.
setup-error-needs-passphrase = Konfigurationen skyddas med en lösenfras. Skriv lösenfrasen som den sparades med.
setup-error-wrong-passphrase = Det är inte lösenfrasen som konfigurationen sparades med.
setup-error-changed = Konfigurationsfilens integritet kunde inte bekräftas. Filen kan inte importeras.
setup-error-read = Konfigurationsfilen kunde inte läsas: { $error }
setup-error-write = Konfigurationen kunde inte sparas: { $error }
setup-error-no-parts = Välj minst en del.
setup-left-out = { $count ->
    [one] { $count } post i { $part } kan inte användas och utelämnas.
   *[other] { $count } poster i { $part } kan inte användas och utelämnas.
}
setup-imported-settings = De valda inställningarna ersattes.
setup-imported-preferences = De valda fönsterinställningarna ersattes.
setup-added-accounts = { $count ->
    [one] { $count } konto lades till.
   *[other] { $count } konton lades till.
}
setup-skipped-here = { $address } är redan konfigurerat här, så det hoppades över.
setup-skipped-no-app = { $address } hoppades över: det loggar in med { $app }, som inte är konfigurerad här.
setup-skipped-invalid = { $address } hoppades över: { $reason }
setup-asks-password = { $address } frågar efter sitt lösenord när det ansluter.
setup-signs-in-again = { $address } ber dig logga in igen när det ansluter.
setup-added-sign-in-apps = { $count ->
    [one] { $count } inloggningsapp lades till.
   *[other] { $count } inloggningsappar lades till.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } inloggningsapp är redan konfigurerad här.
   *[other] { $count } inloggningsappar är redan konfigurerade här.
}
setup-added-contacts = { $count ->
    [one] { $count } kontakt lades till i adressboken.
   *[other] { $count } kontakter lades till i adressboken.
}
setup-skipped-contacts = { $count ->
    [one] { $count } kontakt finns redan i adressboken.
   *[other] { $count } kontakter finns redan i adressboken.
}
setup-added-groups = { $count ->
    [one] { $count } grupp lades till eller kompletterades.
   *[other] { $count } grupper lades till eller kompletterades.
}
setup-added-own-keys = { $count ->
    [one] { $count } egen nyckel lades till.
   *[other] { $count } egna nycklar lades till.
}
setup-added-contact-keys = { $count ->
    [one] { $count } nyckel för en kontakt lades till.
   *[other] { $count } nycklar för kontakter lades till.
}
setup-added-rules = { $count ->
    [one] { $count } meddelanderegel lades till.
   *[other] { $count } meddelanderegler lades till.
}
setup-skipped-rules = { $count ->
    [one] { $count } meddelanderegel finns redan här.
   *[other] { $count } meddelanderegler finns redan här.
}
setup-skipped-rules-account = { $count ->
    [one] { $count } meddelanderegel gäller ett konto som inte finns här, så den hoppades över.
   *[other] { $count } meddelanderegler gäller konton som inte finns här, så de hoppades över.
}
setup-rules-waiting = { $count ->
    [one] { $count } meddelanderegel väntar på att målmappen ska bli tillgänglig efter synkronisering.
   *[other] { $count } meddelanderegler väntar på att målmapparna ska bli tillgängliga efter synkronisering.
}
setup-added-trusted-senders = { $count ->
    [one] { $count } betrodd avsändare lades till.
   *[other] { $count } betrodda avsändare lades till.
}
setup-nothing = Inget importerades.
setup-account-servers = { $imap } och { $smtp } ({ $signin })
setup-file-name = Inställningar och konton för Inbox Classic
setup-skipped-unreachable = { $name } hoppades över eftersom inloggningstjänsten inte kunde kontrolleras. Kontrollera den nödvändiga appen under Inloggningsappar och försök igen.
attachment-runs-programs = ”{ $name }” kan köra program, så Inbox Classic öppnar den inte. Spara den och öppna den sedan själv om du litar på var den kommer ifrån.
attachment-decrypted-note = Bilagan kommer från ett krypterat meddelande. För att öppna den sparar Inbox Classic en okrypterad kopia i en tillfällig mapp för ditt användarkonto. När programmet startar försöker det ta bort kopior som är äldre än ett dygn.
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

preview-pdf-option = Visa PDF-filer i meddelanden
preview-pdf-off = PDF-filer visas inte i meddelanden.
preview-pdf-off-crashed = Inbox Classic avslutades under förhandsvisningen av en fil. Därför har förhandsvisning av PDF-filer stängts av. Bilder visas fortfarande. Aktivera { $option } under { $settings } för att visa PDF-filer igen.
preview-pdf-details = { $count ->
    [one] 1 sida, { $size }
   *[other] { $count } sidor, { $size }
}
preview-page-alt = { $name }, sida { $page } av { $count }
preview-more-pages = { $count ->
    [one] Öppna filen för att se sidan
   *[other] Öppna filen för att se alla { $count } sidor
}
preview-more-files = { $count ->
    [one] 1 fil till finns i listan ovan
   *[other] { $count } filer till finns i listan ovan
}
preview-tile-downloading = Hämtar…
preview-tile-preparing = Förbereder…
preview-tile-format = Bilder i formatet { $format } kan inte visas ännu
preview-tile-password = Skyddad med lösenord: öppna den för att ange lösenordet
preview-tile-too-large = För stor för att visas
preview-tile-unreadable = Kan inte visas
preview-tile-timed-out = Det tog för lång tid att förbereda förhandsvisningen
preview-tile-crashed = Visas inte: Inbox Classic avslutades under en tidigare förhandsvisning
preview-tile-off = Visas inte förrän Inbox Classic startas igen
preview-not-printed = { $name } ({ $details }) skrivs inte ut. Öppna filen för att skriva ut den.
