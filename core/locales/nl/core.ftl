# Nederlands. Concept, wacht op controle door een moedertaalspreker.
# What the core says, the same on every platform. Plurals: [one] and *[other] in Dutch.

## Counts and sizes

messages = { $count ->
    [one] { $count } bericht
   *[other] { $count } berichten
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] { $count } byte
   *[other] { $count } bytes
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Uit
send-delay-seconds = { $count ->
    [one] { $count } seconde
   *[other] { $count } seconden
}
# the status bar: "12 berichten, 3 ongelezen"
list-counts = { $messages }, { $unread } ongelezen
list-counts-selected = { $messages }, { $unread } ongelezen, { $selected } geselecteerd
# the status bar while searching: "12 gevonden, 3 ongelezen"
list-counts-found = { $found } gevonden, { $unread } ongelezen
list-counts-found-selected = { $found } gevonden, { $unread } ongelezen, { $selected } geselecteerd
list-counts-none = Geen berichten gevonden

## Special folders, as Outlook names them

folder-inbox = Postvak IN
folder-sent = Verzonden items
folder-deleted = Verwijderde items
folder-drafts = Concepten
folder-junk = Ongewenste e-mail
folder-archive = Archief

## The reading pane

reader-no-message = Er is geen bericht geselecteerd.
reader-downloading = Het bericht wordt gedownload…
reader-downloading-detail = Het bericht verschijnt hier zodra het downloaden is voltooid.
reader-downloading-size = Het bericht is { $size }. Het verschijnt hier zodra het is gedownload.
reader-failed = Het bericht kon niet worden gedownload
reader-failed-network = De mailserver kon niet worden bereikt ({ $reason }).
reader-failed-sign-in = De mailserver heeft de aanmelding niet geaccepteerd ({ $reason }). Controleer het wachtwoord of meld je opnieuw aan via Bestand > Accounts.
reader-failed-security = De verbinding met de mailserver kon niet worden beveiligd ({ $reason }).
reader-failed-other = De mailserver antwoordde: { $reason }.
reader-retry-note = Het wordt opnieuw geprobeerd wanneer het account weer verbinding maakt.
reader-unreadable = Dit bericht kan niet worden getoond: { $error }
message-source-title = Berichtbron: { $subject }
message-source-untitled = Berichtbron

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Van
header-date = Datum
header-to = Aan
header-cc = Cc
header-sent = Verzonden
header-subject = Onderwerp
header-security = Beveiliging
header-part = Deel { $number }
quote-original = ----- Oorspronkelijk bericht -----
fold-show-earlier = Eerdere berichten weergeven

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Je bericht is niet bezorgd
bounce-delayed = Je bericht is nog niet bezorgd
bounce-delayed-note = Je mailserver probeert het nog steeds te bezorgen. Je hoeft het niet opnieuw te verzenden.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Onbestelbaar bericht weergeven
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Vertraagd bericht weergeven
bounce-what-to-do = Wat je kunt doen:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Nog niets. Als het nog steeds niet kan worden bezorgd, krijg je een nieuwe melding.
bounce-delayed-row-do = Nog niets. Je mailserver probeert het nog steeds te bezorgen, en je krijgt een nieuwe melding als dat niet lukt.
# folds the receiving server's own words
bounce-details = Details
# a recipient the notice does not name
bounce-someone = Een ontvanger
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Gemeld door: { $server }
bounce-retry-minutes = De ontvangende server vroeg om { $count ->
    [one] een minuut
   *[other] { $count } minuten
} te wachten voor de volgende poging.
bounce-retry-hours = De ontvangende server vroeg om { $count ->
    [one] een uur
   *[other] { $count } uur
} te wachten voor de volgende poging.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Blokkeerlijst: { $lists }
bounce-user-unknown = Het adres bestaat niet
bounce-user-unknown-why = De ontvangende server heeft geen postvak met dit adres. Het is misschien verkeerd getypt, of de persoon gebruikt het niet meer.
bounce-user-unknown-do = Controleer het adres op typefouten of vraag de ontvanger welk adres je kunt gebruiken.
bounce-invalid-address = Het adres is niet geldig
bounce-invalid-address-why = Het adres heeft geen geldig e-mailformaat. Er kan geen e-mail naartoe worden verzonden.
bounce-invalid-address-do = Controleer het adres op typefouten, zoals een spatie, een ontbrekende letter of een ontbrekend domein na de @.
bounce-mailbox-disabled = Het postvak is gesloten
bounce-mailbox-disabled-why = Het adres bestaat, maar het postvak is uitgeschakeld of wordt niet meer gebruikt.
bounce-mailbox-disabled-do = Neem op een andere manier contact op met de ontvanger en vraag om een e-mailadres dat nog in gebruik is.
bounce-mailbox-full = Het postvak is vol
bounce-mailbox-full-why = Het postvak van de ontvanger heeft geen ruimte voor nieuwe e-mail.
bounce-mailbox-full-do = Verzend het bericht over een paar dagen opnieuw of laat het de ontvanger op een andere manier weten. Berichten met grote bijlagen worden als eerste geweigerd.
bounce-spam-blocked = Geweigerd als spam
bounce-spam-blocked-why = De ontvangende server zag het bericht aan voor spam.
bounce-spam-blocked-do = Verwijder inhoud die op spam kan lijken, zoals grote aantallen links, verkorte links of een grote bijlage, en verzend het bericht opnieuw. Neem contact op met je e-mailprovider als dit blijft gebeuren.
bounce-virus-detected = Geweigerd vanwege een virus
bounce-virus-detected-why = De ontvangende server heeft een virus of andere schadelijke inhoud gevonden in het bericht of de bijlagen.
bounce-virus-detected-do = Controleer de bijlagen met een virusscanner. Sommige servers weigeren alle programma’s en archiefbestanden. Deel zulke bestanden in dat geval via een link.
bounce-ip-blocklisted = Je mailserver staat op een blokkeerlijst
bounce-ip-blocklisted-why = De ontvangende server weigert e-mail van de server die jouw bericht verzond, omdat het adres van die server op een blokkeerlijst staat.
bounce-ip-blocklisted-do = Het probleem ligt bij de mailserver. Stuur deze melding door naar je e-mailprovider en vraag om de server van de blokkeerlijst te laten verwijderen.
bounce-domain-blocklisted = Een domein staat op een blokkeerlijst
bounce-domain-blocklisted-why = De ontvangende server weigert het bericht omdat het domein van je adres, of een domein in de links van het bericht, op een blokkeerlijst staat.
bounce-domain-blocklisted-do = Als het bericht links bevat, probeer het dan zonder. Stuur deze melding anders door naar degene die de e-mail voor je domein beheert.
bounce-policy-blocked = Geweigerd door de regels van de ontvangende server
bounce-policy-blocked-why = De regels van de ontvangende server laten dit bericht niet door, bijvoorbeeld vanwege de grootte, de bijlagen of de afzender.
bounce-policy-blocked-do = Het antwoord van de server onder Details vermeldt vaak de reden. Vraag de ontvanger of berichten zoals dit zijn toegestaan.
bounce-geo-blocked = Geweigerd vanwege de herkomst
bounce-geo-blocked-why = De ontvangende server neemt geen e-mail aan uit het land of netwerk waarin je mailserver staat.
bounce-geo-blocked-do = Neem op een andere manier contact op met de persoon, of vraag je e-mailprovider ernaar.
bounce-relay-denied = De server weigerde het bericht door te sturen
bounce-relay-denied-why = Een server weigerde het bericht verder te bezorgen, vaak omdat het zonder aanmelding is verzonden of via een server die deze ontvanger niet afhandelt.
bounce-relay-denied-do = Controleer via Bestand > Accounts of de juiste server voor uitgaande e-mail is ingesteld en of je account zich daarbij aanmeldt.
bounce-auth-failure = Je afzenderadres kon niet worden geverifieerd
bounce-auth-failure-why = De ontvangende server kon niet bevestigen dat het bericht echt van je domein kwam (SPF, DKIM of DMARC).
bounce-auth-failure-do = Stuur deze melding door naar degene die de e-mail voor je domein beheert: de instellingen moeten worden gecorrigeerd. Verzenden via de eigen server van je provider kan intussen helpen.
bounce-rate-limited = Te veel e-mail tegelijk
bounce-rate-limited-why = De ontvangende server neemt voorlopig minder berichten aan van je mailserver.
bounce-rate-limited-do = Wacht even en verzend het opnieuw. Als je aan veel mensen schrijft, verzend dan aan minder mensen tegelijk.
bounce-greylisting = Even tegengehouden
bounce-greylisting-why = De ontvangende server vraagt onbekende afzenders het iets later opnieuw te proberen, een gangbare controle tegen spam.
bounce-greylisting-do = Niets. Mailservers proberen het zelf opnieuw, en het bericht wordt meestal binnen het uur bezorgd.
bounce-server-error = De ontvangende server had een probleem
bounce-server-error-why = De ontvangende server kon niet worden bereikt, of kon het bericht niet aannemen door een eigen probleem.
bounce-server-error-do = Verzend het later opnieuw. Als het blijft mislukken, controleer dan het deel van het adres na de @ op typefouten.
bounce-unknown = Niet bezorgd
bounce-unknown-why = De melding zegt niet duidelijk waarom.
bounce-unknown-do = Het antwoord van de server onder Details geeft misschien meer informatie. Stuur deze melding door naar je e-mailprovider als de oorzaak onduidelijk blijft.

## Several messages selected

selection-title = { $count ->
    [one] { $count } bericht geselecteerd
   *[other] { $count } berichten geselecteerd
}
selection-unread = { $count } ongelezen
selection-flagged = { $count } gemarkeerd
delete-for-good-one = Dit bericht wordt definitief verwijderd. Verwijderen?
delete-for-good-all = Deze { $count } berichten worden definitief verwijderd. Verwijderen?
delete-for-good-some = { $count } van de { $total } berichten worden definitief verwijderd. De berichten verwijderen?
done-read = { $count ->
   *[other] { $messages } gemarkeerd als gelezen
}
done-unread = { $count ->
   *[other] { $messages } gemarkeerd als ongelezen
}
done-flagged = { $count ->
   *[other] { $messages } gemarkeerd
}
done-unflagged = Markering verwijderd van { $messages }
done-deleted-for-good = { $count ->
   *[other] { $messages } definitief verwijderd
}
done-archived = { $count ->
   *[other] { $messages } gearchiveerd
}
done-moved = { $count ->
   *[other] { $messages } verplaatst naar { $folder }
}
done-copied = { $count ->
   *[other] { $messages } gekopieerd naar { $folder }
}
done-moving = { $count ->
    [one] { $messages } wordt verplaatst naar { $folder }...
   *[other] { $messages } worden verplaatst naar { $folder }...
}
done-copying = { $count ->
    [one] { $messages } wordt gekopieerd naar { $folder }...
   *[other] { $messages } worden gekopieerd naar { $folder }...
}
done-moved-back = { $count ->
   *[other] { $messages } teruggezet naar { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Het gesprek wordt gevolgd
   *[other] { $count } gesprekken worden gevolgd
}
done-unwatched = { $count ->
    [one] Het gesprek wordt niet meer gevolgd
   *[other] { $count } gesprekken worden niet meer gevolgd
}
done-ignored = { $count ->
    [one] Het gesprek wordt genegeerd
   *[other] { $count } gesprekken worden genegeerd
}
done-unignored = { $count ->
    [one] Het gesprek wordt niet meer genegeerd
   *[other] { $count } gesprekken worden niet meer genegeerd
}
their-folders = hun mappen
undo-move = Verplaatsen ongedaan maken
undo-delete = Verwijderen ongedaan maken
undo-archive = Archiveren ongedaan maken
undo-junk = Markeren als ongewenst ongedaan maken
undo-not-junk = Markeren als gewenst ongedaan maken
undo-send = Verzenden ongedaan maken
nothing-to-undo = Er is niets om ongedaan te maken.
messages-gone = De berichten zijn er niet meer.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Deze map kan geen berichten bevatten.
not-archived-here = Berichten in deze map kunnen niet worden gearchiveerd.
not-emptied-here = Alleen Verwijderde items en Ongewenste e-mail kunnen worden leeggemaakt.
next-unread-question = Er zijn geen ongelezen berichten meer in { $folder }.

    Naar { $next } gaan, de volgende map met ongelezen berichten?
no-unread-left = Er zijn geen ongelezen berichten meer.
empty-question = { $count ->
    [one] { $folder } leegmaken?

        Het bericht erin wordt definitief verwijderd. Het kan niet worden teruggehaald.
   *[other] { $folder } leegmaken?

        De { $messages } erin worden definitief verwijderd. Ze kunnen niet worden teruggehaald.
}
no-junk-folder = Dit account heeft geen map Ongewenste e-mail om de berichten naartoe te verplaatsen.
no-inbox-folder = Dit account heeft geen map Postvak IN om de berichten naartoe te verplaatsen.
# the status bar after a flag in a colour: "2 berichten blauw gemarkeerd"
done-flagged-color = { $messages } { $color ->
    [red] rood
    [orange] oranje
    [yellow] geel
    [green] groen
    [blue] blauw
    [purple] paars
   *[gray] grijs
} gemarkeerd
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Rood
    [orange] Oranje
    [yellow] Geel
    [green] Groen
    [blue] Blauw
    [purple] Paars
   *[gray] Grijs
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Bericht verplaatsen
   *[other] { $count } berichten verplaatsen
}
move-window-title-copy = { $count ->
    [one] Bericht kopiëren
   *[other] { $count } berichten kopiëren
}
move-window-prompt-move = { $count ->
    [one] Het geselecteerde bericht verplaatsen naar:
   *[other] De { $count } geselecteerde berichten verplaatsen naar:
}
move-window-prompt-copy = { $count ->
    [one] Het geselecteerde bericht kopiëren naar:
   *[other] De { $count } geselecteerde berichten kopiëren naar:
}
# the folders used last, over the folder tree
targets-recent = Recent
# the folder the messages are in, which can not be chosen
target-current = { $folder } (huidige)
# a folder used last, with its account when there are several: "Archief (Werk)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Verplaatsen naar { $folder }: { $done } van { $messages }...
transfer-copying = Kopiëren naar { $folder }: { $done } van { $messages }...
transfer-another-account = een ander account
transfer-folder-gone = de map waar het naartoe ging, bestaat niet meer
transfer-not-on-server = het bericht staat niet meer op de server
transfer-not-moved = { $count ->
    [one] { $messages } kon niet naar een ander account worden verplaatst: { $reason }
   *[other] { $messages } konden niet naar een ander account worden verplaatst: { $reason }
}
transfer-not-copied = { $count ->
    [one] { $messages } kon niet naar een ander account worden gekopieerd: { $reason }
   *[other] { $messages } konden niet naar een ander account worden gekopieerd: { $reason }
}
transfer-none-moved = Er kon geen bericht worden verplaatst
transfer-none-copied = Er kon geen bericht worden gekopieerd

## Messages as files

export-not-in-time = het bericht kon niet op tijd worden gedownload
export-not-saved = Opslaan mislukt voor { $failed } van { $messages } ({ $problems })
export-not-attached = de berichten konden niet worden bijgevoegd: { $error }
# the status bar after Save As with several: "3 berichten opgeslagen in Bureaublad"
saved-to = { $count ->
   *[other] { $messages } opgeslagen in { $folder }
}
download-progress = Downloaden: { $done } van { $total }
download-done = { $size } gedownload
downloading-messages = { $count ->
   *[other] Downloaden: { $messages }...
}
# the status bar after files are dropped on a folder: "3 berichten in Archief gezet"
import-put = { $count ->
   *[other] { $messages } toegevoegd aan { $folder }
}
import-not-put = Deze berichten konden niet aan de map worden toegevoegd:

    { $problems }

## Problems the windows show

error-store = lokale opslag: { $error }
error-not-found = niet gevonden
error-closed = wordt afgesloten
error-other-account = je bent via de browser aangemeld bij { $email }, niet bij dit account
# a password or sign-in the mail server refused, with the server's words
failure-authentication = de server heeft de aanmelding niet geaccepteerd ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = de verbinding met de server is mislukt ({ $reason })
error-in-use = de aanmeldapp kan niet worden verwijderd zolang deze accounts hem gebruiken: { $accounts }
error-turned-off = deze aanmeldapp is uitgeschakeld voor nieuwe accounts
error-folder-name = de mapnaam moet 1 tot 200 tekens lang zijn en mag geen besturingstekens bevatten
error-folder-separator = een mapnaam mag op deze server geen “{ $separator }” bevatten
error-folder-special = Postvak IN en de speciale mappen kunnen niet worden hernoemd of verwijderd
error-no-recipients = het bericht heeft geen ontvangers
error-bad-address = “{ $address }” is geen e-mailadres
error-not-own-address = { $address } is geen afzenderadres van dit account. Voeg dit adres toe aan het veld “Andere afzenderadressen” in de accounteigenschappen.
rule-query-refused = Regels kunnen niet filteren op map of datum ({ $words }).
rule-no-query = Typ zoekcriteria voor binnenkomende berichten.
rule-no-action = Kies ten minste één actie voor de regel.
error-attachment = { $path } kon niet worden gelezen: { $error }
error-no-drafts = het account heeft geen map Concepten om het bericht in op te slaan
error-draft-attachment = een bijlage van het concept kon niet worden behouden: { $error }
error-password-not-saved = het wachtwoord kon niet worden bewaard voor de volgende keer dat je Inbox Classic start: { $error }
error-sign-in-not-saved = de nieuwe aanmeldgegevens konden niet worden bewaard voor de volgende keer dat je Inbox Classic start: { $error }
error-import-unreadable = { $path } kan niet worden gelezen: { $error }
error-import-too-large = { $path } is groter dan 50 MB
error-import-not-mail = { $path } is geen e-mailbericht
error-list-answered = de server van de mailinglijst gaf status { $status }
error-not-built = het bericht kon niet worden samengesteld
error-outbox-waits = { $count ->
    [one] het bericht wacht in Postvak UIT en wordt verzonden bij de volgende keer Verzenden/ontvangen
   *[other] { $count } berichten wachten in Postvak UIT en worden verzonden bij de volgende keer Verzenden/ontvangen
}
error-draft-not-removed = het eerdere concept van het bericht kon niet uit Concepten worden verwijderd: { $reason }
error-sent-but = het bericht is verzonden, maar { $problem }
error-sent-still-in-outbox = het staat nog in Postvak UIT: { $error }
error-sent-no-copy = er kon geen kopie worden opgeslagen in Verzonden items: { $reason }
error-no-password = geen wachtwoord voor dit account
error-no-sign-in = geen aanmeldgegevens voor dit account
error-provider-missing = deze versie van Inbox Classic kan je niet aanmelden bij { $provider }. Mogelijk is de bijbehorende aanmeldapp verwijderd
error-provider-servers = de servers van dit account komen niet overeen met de servers van de aanmeldapp
error-app-scopes = { $reason }. De mailserver heeft het token van de aanmeldapp niet geaccepteerd: controleer of de machtigingen (scopes) van de app toegang tot e-mail geven
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google heeft Inbox Classic nog niet geverifieerd, dus alleen testgebruikers kunnen zich ermee aanmelden. Gebruik je eigen Google-aanmeldapp of een app-wachtwoord, of schakel het in bij Aanmeldapps (Bestand > Accounts) als je een testgebruiker bent.
sign-in-off-other = Deze aanmeldapp is uitgeschakeld. Je kunt hem weer inschakelen via Bestand > Accounts > Aanmeldapps.
sign-in-app-no-name = de aanmeldapp heeft een naam nodig
sign-in-app-no-client = de client-ID ontbreekt
sign-in-app-no-scopes = de aanmeldapp heeft de machtigingen (scopes) nodig die toegang tot e-mail geven
sign-in-app-bad-host = het serveradres voor { $server } ontbreekt of is geen geldige hostnaam
sign-in-app-plain = de server voor { $server } moet SSL/TLS of STARTTLS gebruiken
sign-in-app-not-checked = de uitgever is nog niet gecontroleerd
sign-in-app-issuer-changed = de uitgever is gewijzigd: typ het clientgeheim opnieuw, of verwijder het
sign-in-register-google = Maak in Google Cloud Console een OAuth-client van het type Desktop app, met de scope https://mail.google.com/ op het toestemmingsscherm. Zolang de app in de testfase is, kunnen alleen de testgebruikers ervan zich aanmelden.
sign-in-register-microsoft = Registreer in Microsoft Entra een app met het platform Mobile and desktop applications, de omleidings-URI http://localhost en public client flows toegestaan, en de gedelegeerde machtigingen IMAP.AccessAsUser.All, SMTP.Send en offline_access. Gebruik alleen voor je eigen organisatie https://login.microsoftonline.com/<tenant ID>/v2.0 als uitgever.
sign-in-register-other = Registreer een native (openbare) client met de omleidings-URI hieronder; de provider moet daarop elke poort toestaan (RFC 8252). Voeg de scope toe waarmee de provider toegang tot e-mail geeft.

## Calendar invitations

repeats = Herhaalt
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Elke dag
       *[other] Elke { $interval } dagen
    }
    [week] { $interval ->
        [one] Elke week
       *[other] Elke { $interval } weken
    }
    [month] { $interval ->
        [one] Elke maand
       *[other] Elke { $interval } maanden
    }
   *[year] { $interval ->
        [one] Elk jaar
       *[other] Elke { $interval } jaar
    }
}
# "Elke week op maandag, woensdag"
repeats-on = { $repeats } op { $days }
# "Elke week, 10 keer"
repeats-times = { $count ->
    [one] { $repeats }, één keer
   *[other] { $repeats }, { $count } keer
}
day-monday = maandag
day-tuesday = dinsdag
day-wednesday = woensdag
day-thursday = donderdag
day-friday = vrijdag
day-saturday = zaterdag
day-sunday = zondag

## AI agents

agent-level-read = E-mail lezen: mappen en berichten bekijken en doorzoeken
agent-level-organize = E-mail ordenen: leesstatus en markeringen wijzigen, ongewenste e-mail markeren, berichten verplaatsen en verwijderen (naar Verwijderde items)
agent-level-drafts = Concepten schrijven die jij verzendt
agent-level-send = E-mail verzenden, met jouw toestemming voor elk bericht
agent-connect-title = { $program } wil je e-mail gebruiken
agent-connect-detail = Een AI-agent wil met Inbox Classic werken. Kies wat de agent mag doen en tot welke accounts de agent toegang krijgt. Je kunt dit later wijzigen via Extra > AI-agents.

    Agents lezen e-mail van anderen. Die berichten kunnen instructies bevatten die de agent proberen te misleiden. Inbox Classic vraagt altijd om jouw toestemming voordat een agent iets verzendt.
agent-reply-to = Antwoord op “{ $subject }”
agent-reply-all-on = Antwoord aan allen op “{ $subject }”
agent-forward-of = Doorsturen van “{ $subject }”
agent-never-written-one = Je hebt nog nooit geschreven aan { $address }.
agent-never-written-many = Je hebt nog nooit geschreven aan { $count } van deze adressen.
agent-send-title = { $program } wil dit bericht verzenden
agent-send-detail = Controleer de ontvangers en de inhoud van het bericht. Zodra je bevestigt, wacht het bericht { $seconds } seconden in Postvak UIT, waar je het nog kunt verwijderen.
agent-change-title = Wat { $program } mag doen
agent-change-allowed = Wijzig wat de AI-agents van dit programma met je e-mail mogen doen.
agent-change-refused = Je hebt dit programma toegang geweigerd. Geef het programma toestemming om de bijbehorende agents weer toegang tot je e-mail te geven.
agent-log-taken-back = { $entry } (teruggedraaid)
agent-files = Bestanden: { $files }
agent-undo-refused = Dit kan niet worden teruggedraaid.
agent-undo-refused-why = Dit kan niet worden teruggedraaid: { $reason }.
agent-undo-impossible = dit kan niet worden teruggedraaid
agent-undo-not-in-folder = het bericht staat niet meer in die map
agent-undo-not-arrived = het bericht staat (nog) niet in de map waar het naartoe ging
agent-undo-sent = het bericht staat niet meer in Postvak UIT
agent-original-not-downloaded = het oorspronkelijke bericht is nog niet gedownload. Open het eerst
agent-turned-away = Geweigerd
agent-can-nothing = Niets
agent-can-read = lezen
agent-can-organize = ordenen
agent-can-drafts = concepten schrijven
agent-can-send = verzenden met jouw toestemming
# "lezen, ordenen en concepten schrijven"
agent-can-list = { $first } en { $last }
agent-accounts = { $count ->
    [0] geen accounts
    [one] { $count } account
   *[other] { $count } accounts
}
# "lezen en ordenen; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Dit bericht kan niet worden gelezen.
agent-encrypted-original = Dit bericht is versleuteld: een agent kan het niet beantwoorden of doorsturen, omdat hij niet kan versleutelen.
agent-encrypted = Dit bericht is versleuteld. AI-agents kunnen de inhoud niet lezen. De gebruiker moet het in Inbox Classic openen.
list-encrypted = Versleuteld bericht
agent-log-composed = “{ $subject }” geopend als nieuw bericht dat je zelf kunt afmaken
agent-log-refused = Je hebt “{ $subject }” niet verzonden
agent-log-sent = “{ $subject }” klaargezet voor verzending aan { $to }
agent-log-draft = Het concept “{ $subject }” opgeslagen
agent-log-read = “{ $subject }” gemarkeerd als gelezen
agent-log-unread = “{ $subject }” gemarkeerd als ongelezen
agent-log-flagged = “{ $subject }” gemarkeerd
agent-log-unflagged = Markering verwijderd van “{ $subject }”
agent-log-deleted = “{ $subject }” verwijderd
agent-log-moved = “{ $subject }” verplaatst naar { $folder }
agent-log-junk = “{ $subject }” gemarkeerd als ongewenst
agent-log-not-junk = “{ $subject }” gemarkeerd als gewenst
agent-log-archived = “{ $subject }” gearchiveerd
agent-log-folder = De map “{ $name }” gemaakt
agent-log-unsubscribed = Afgemeld voor de mailinglijst bij het bericht “{ $subject }”

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = de provider heeft geen vernieuwingstoken gegeven
sign-in-no-account = de provider heeft niet gezegd welk account zich heeft aangemeld
sign-in-not-finished = het aanmelden is nog niet voltooid
secrets-unavailable = { $store } is niet beschikbaar
secrets-unavailable-why = { $store } is niet beschikbaar: { $error }
secrets-windows = Referentiebeheer
secrets-mac = de sleutelhanger
secrets-linux = de sleutelbos van het systeem (Secret Service)
error-no-such-file = dit bestand bestaat niet
cards-file-too-big = Dit bestand is te groot om een adresboek te zijn.
ui-sender-added = { $name } is toegevoegd aan het Adresboek.
ui-sender-known = { $name } staat al in het Adresboek.
ui-sender-none = De afzender van dit bericht heeft geen e-mailadres om toe te voegen.
card-name-needed = De contactpersoon heeft geen naam en geen e-mailadres.
# a file of Import Address Book that could not be read: "contacts.vcf: dit bestand bestaat niet"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Code van { $domain }
otp-copy = Kopiëren
otp-note = Vul deze alleen in op een pagina van { $domain }.
otp-old = Deze code is meer dan een uur voor het openen van het bericht verzonden en is waarschijnlijk verlopen.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } deelnemer
       *[other] { $count } deelnemers
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } is je code voor { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Geldig
pgp-key-expires = Geldig tot { $date }
pgp-key-expired = Verlopen op { $date }
pgp-key-revoked = Ingetrokken
pgp-key-revoked-why = Ingetrokken: { $reason }
pgp-key-not-valid = Niet geldig
pgp-key-locked = Deze privésleutel kan niet worden gebruikt: de beveiligingssleutel ontbreekt in { $store }. Importeer de back-up van je privésleutel opnieuw.
pgp-source-own = Gemaakt in Inbox Classic
pgp-source-file = Geïmporteerd uit een bestand
pgp-source-paste = Geplakt
pgp-source-attachment = Uit een bericht
pgp-source-vcard = Uit een visitekaartje
pgp-source-wkd = Van de e-mailprovider van de afzender
pgp-source-keyserver = Van keys.openpgp.org
pgp-source-autocrypt = Uit de Autocrypt-header van een bericht
pgp-error-no-store = Privésleutels worden beveiligd via { $store }. Deze opslag kan niet worden gebruikt: { $error }
pgp-error-wrong-passphrase = De wachtwoordzin klopt niet.
pgp-error-not-a-key = Dit is geen OpenPGP-sleutel.
pgp-error-too-large = De sleutel is te groot.
pgp-error-unusable = De sleutel gebruikt oude of zwakke cryptografie en kan niet worden gebruikt.
pgp-imported-private = { $count ->
    [one] Je privésleutel is geïmporteerd.
   *[other] { $count } privésleutels zijn geïmporteerd.
}
pgp-imported-public = { $count ->
    [one] Eén sleutel is geïmporteerd.
   *[other] { $count } sleutels zijn geïmporteerd.
}
pgp-imported-pending = Voor deze adressen is al een andere sleutel in gebruik: { $addresses }. De nieuwe sleutel staat bij de contactpersoon, maar wordt pas gebruikt als je hem kiest.
pgp-error-needs-passphrase = De privésleutel is beschermd door een wachtwoordzin. Typ die om de sleutel te importeren.
pgp-error-mismatch = De privésleutel hoort niet bij de openbare sleutel. Hij is mogelijk gewijzigd.
pgp-file-name-public = Openbare sleutel van { $who }.asc
pgp-file-name-private = Back-up van privésleutel van { $who }.asc
pgp-pending = Op { $date } is een andere sleutel voor { $address } gevonden.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Ondertekend door { $signer }, sleutel geverifieerd
pgp-part-signed = Ondertekend door { $signer } (sleutel niet geverifieerd)
pgp-part-other = Ondertekend door { $signer }, die niet de afzender is
pgp-part-unknown-key = Ondertekend, maar de sleutel is onbekend
pgp-part-not-signed = Niet ondertekend
pgp-part-not-checked = Handtekening niet gecontroleerd
pgp-part-encrypted = Versleuteld. { $signature }
pgp-part-no-key = Versleuteld; geen bijbehorende privésleutel beschikbaar
pgp-part-changed = Het versleutelde deel is onderweg gewijzigd en wordt niet getoond
pgp-part-unprotected = Versleuteld zonder bescherming tegen wijzigingen, niet getoond
pgp-part-broken = Het versleutelde deel kan niet worden gelezen
pgp-why-mismatch = De digitale handtekening komt niet overeen met deze tekst
pgp-why-weak-hash = De handtekening gebruikt { $hash }, dat niet meer veilig is
pgp-why-key-expired = Ondertekend nadat de sleutel op { $date } was verlopen
pgp-why-key-revoked = Ondertekend met een sleutel die is ingetrokken
pgp-why-not-signing-key = Ondertekend met een sleutel die niet geschikt is voor ondertekening
pgp-why-from-future = De handtekening is gedateerd in de toekomst
pgp-why-signature-expired = De handtekening is verlopen
pgp-why-key-not-valid = Ondertekend met een sleutel die niet geldig is
pgp-why-not-for-you = Ondertekend voor andere ontvangers en aan jou doorgegeven
pgp-part-pictures-loaded = { $label }. Er zijn afbeeldingen van internet geladen
pgp-error-no-own-key = Je hebt geen sleutel voor { $address } om mee te ondertekenen of te versleutelen. Maak er een via Extra > Versleutelingssleutels, of zet Ondertekenen en Versleutelen uit.
pgp-error-missing-keys = { $count ->
    [one] Er is geen sleutel beschikbaar om het bericht te versleutelen voor: { $addresses }.
   *[other] Er zijn geen sleutels beschikbaar om het bericht te versleutelen voor deze ontvangers: { $addresses }.
}
pgp-error-encrypted-quote = Dit bericht citeert of stuurt een versleuteld bericht door, dus het kan alleen versleuteld worden verzonden. Zet Versleutelen aan, of verwijder de geciteerde tekst.
pgp-error-protect = Het bericht kon niet worden ondertekend of versleuteld: { $reason }
pgp-found-keys = Sleutels gevonden voor: { $addresses }.
pgp-found-none = Geen sleutel gevonden voor: { $addresses }. Vraag de benodigde openbare sleutels op.
pgp-found-no-key = Er is geen sleutel gevonden.
pgp-find-unavailable = De sleutels konden niet worden opgezocht: { $error }
pgp-publish-pending = keys.openpgp.org heeft een bevestigingslink gestuurd naar deze adressen: { $addresses }. Bevestig elk adres afzonderlijk zodat je sleutel via dat adres kan worden gevonden.
pgp-publish-done = Je sleutel is gepubliceerd op keys.openpgp.org voor { $addresses }.
pgp-publish-failed = De sleutel kon niet worden gepubliceerd: { $error }
pgp-keyserver-off = Sleutels zoeken op keys.openpgp.org staat uit bij { $settings }.
pgp-details-part = Deel { $number }: { $label }
pgp-details-signed = Ondertekend op { $when } met de sleutel { $key }
pgp-details-unknown-key = Ondertekend met de sleutel { $key }, die je niet hebt
pgp-details-opened = Ontsleuteld met je sleutel { $key }
pgp-details-for = Versleuteld voor { $keys }
pgp-details-plain = Niet ondertekend en niet versleuteld
pgp-bar-parts = Dit bericht heeft { $count } delen: { $list }. Bij elk deel staat hoe het is beschermd.
pgp-bar-count-verified = { $count } geverifieerd
pgp-bar-count-good = { $count ->
    [one] { $count } ondertekend of versleuteld
   *[other] { $count } ondertekend of versleuteld
}
pgp-bar-count-warning = { $count ->
    [one] { $count } vraagt aandacht
   *[other] { $count } vragen aandacht
}
pgp-bar-count-neutral = { $count } zonder bevestigde handtekening
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Instellingen
setup-part-preferences = Vensterinstellingen
setup-part-accounts = Accounts
setup-part-sign-in-apps = Aanmeldapps
setup-part-contacts = Contactpersonen en groepen
setup-part-keys = Versleutelingssleutels
setup-part-rules = Berichtenregels
setup-part-trusted-senders = Vertrouwde afzenders
setup-holds-settings = { $count ->
    [one] { $count } instelling
   *[other] { $count } instellingen
}
setup-holds-preferences = { $count ->
    [one] { $count } vensterinstelling
   *[other] { $count } vensterinstellingen
}
setup-holds-accounts = { $count ->
    [one] { $count } account
   *[other] { $count } accounts
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } aanmeldapp
   *[other] { $count } aanmeldapps
}
setup-holds-built-in = Welke ingebouwde aanmeldapps zijn ingeschakeld
setup-holds-contacts = { $count ->
    [one] { $count } contactpersoon
   *[other] { $count } contactpersonen
}
setup-holds-groups = { $count ->
    [one] { $count } groep
   *[other] { $count } groepen
}
setup-holds-own-keys = { $count ->
    [one] { $count } eigen sleutel
   *[other] { $count } eigen sleutels
}
setup-holds-contact-keys = { $count ->
    [one] { $count } sleutel van een contactpersoon
   *[other] { $count } sleutels van contactpersonen
}
setup-holds-rules = { $count ->
    [one] { $count } regel
   *[other] { $count } regels
}
setup-holds-trusted-senders = { $count ->
    [one] { $count } vertrouwde afzender
   *[other] { $count } vertrouwde afzenders
}
setup-sign-in-password = Wachtwoord
setup-account-secret-password = Het wachtwoord staat in het bestand.
setup-account-secret-token = De aanmeldgegevens staan in het bestand.
setup-account-asks-password = Na het importeren wordt om het wachtwoord gevraagd.
setup-account-signs-in-again = Na het importeren meld je je er opnieuw bij aan.
setup-account-here = Dit account staat hier al, dus het wordt overgeslagen.
setup-account-no-app = Dit account gebruikt de aanmeldapp { $app }, die hier niet is ingesteld. Importeer ook de aanmeldapps.
setup-invalid-address = “{ $address }” is geen e-mailadres.
setup-invalid-server = Het serveradres of poortnummer voor { $server } is ongeldig of ontbreekt.
setup-invalid-user = Er is geen gebruikersnaam.
setup-invalid-sign-in = Dit account gebruikt een aanmeldmethode die Inbox Classic niet ondersteunt.
setup-error-empty = Het bestand is leeg.
setup-error-too-large = Het bestand is te groot om een instellingenbestand van Inbox Classic te zijn.
setup-error-not-setup = Dit bestand is geen instellingenbestand van Inbox Classic.
setup-error-damaged = Het instellingenbestand is beschadigd en kan niet worden gelezen.
setup-error-newer = Dit bestand is opgeslagen met een nieuwere versie van Inbox Classic ({ $version }). Werk Inbox Classic bij en importeer het bestand opnieuw.
setup-error-needs-passphrase = Dit bestand is beveiligd met een wachtwoordzin. Typ de wachtwoordzin waarmee het is opgeslagen.
setup-error-wrong-passphrase = Dat is niet de wachtwoordzin waarmee dit bestand is opgeslagen.
setup-error-changed = Het instellingenbestand is na het opslaan gewijzigd of beschadigd, dus het kan niet worden geïmporteerd.
setup-error-read = Het instellingenbestand kon niet worden gelezen: { $error }
setup-error-write = De instellingen konden niet worden opgeslagen: { $error }
setup-error-no-parts = Kies ten minste één onderdeel.
setup-left-out = { $count ->
    [one] { $count } item van { $part } kan niet worden gebruikt en wordt weggelaten.
   *[other] { $count } items van { $part } kunnen niet worden gebruikt en worden weggelaten.
}
setup-imported-settings = De instellingen zijn vervangen.
setup-imported-preferences = De vensterinstellingen zijn vervangen.
setup-added-accounts = { $count ->
    [one] { $count } account toegevoegd.
   *[other] { $count } accounts toegevoegd.
}
setup-skipped-here = Het account met adres { $address } is al ingesteld en is daarom overgeslagen.
setup-skipped-no-app = { $address } is overgeslagen: het meldt zich aan met { $app }, die hier niet is ingesteld.
setup-skipped-invalid = { $address } is overgeslagen: { $reason }
setup-asks-password = Bij de eerstvolgende verbinding wordt om het wachtwoord voor { $address } gevraagd.
setup-signs-in-again = Bij de eerstvolgende verbinding moet je je opnieuw aanmelden bij { $address }.
setup-added-sign-in-apps = { $count ->
    [one] { $count } aanmeldapp toegevoegd.
   *[other] { $count } aanmeldapps toegevoegd.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aanmeldapp is hier al ingesteld.
   *[other] { $count } aanmeldapps zijn hier al ingesteld.
}
setup-added-contacts = { $count ->
    [one] { $count } contactpersoon toegevoegd aan het adresboek.
   *[other] { $count } contactpersonen toegevoegd aan het adresboek.
}
setup-skipped-contacts = { $count ->
    [one] { $count } contactpersoon staat al in het adresboek.
   *[other] { $count } contactpersonen staan al in het adresboek.
}
setup-added-groups = { $count ->
    [one] { $count } groep toegevoegd of aangevuld.
   *[other] { $count } groepen toegevoegd of aangevuld.
}
setup-added-own-keys = { $count ->
    [one] { $count } eigen sleutel toegevoegd.
   *[other] { $count } eigen sleutels toegevoegd.
}
setup-added-contact-keys = { $count ->
    [one] { $count } sleutel van een contactpersoon toegevoegd.
   *[other] { $count } sleutels van contactpersonen toegevoegd.
}
setup-added-rules = { $count ->
    [one] { $count } berichtenregel toegevoegd.
   *[other] { $count } berichtenregels toegevoegd.
}
setup-skipped-rules = { $count ->
    [one] { $count } berichtenregel staat hier al.
   *[other] { $count } berichtenregels staan hier al.
}
setup-skipped-rules-account = { $count ->
    [one] { $count } berichtenregel overgeslagen omdat het bijbehorende account hier niet is ingesteld.
   *[other] { $count } berichtenregels overgeslagen omdat de bijbehorende accounts hier niet zijn ingesteld.
}
setup-rules-waiting = { $count ->
    [one] { $count } berichtenregel verplaatst berichten naar een map die verschijnt zodra het account is gesynchroniseerd.
   *[other] { $count } berichtenregels verplaatsen berichten naar mappen die verschijnen zodra de accounts zijn gesynchroniseerd.
}
setup-added-trusted-senders = { $count ->
    [one] { $count } vertrouwde afzender toegevoegd.
   *[other] { $count } vertrouwde afzenders toegevoegd.
}
setup-nothing = Er is niets geïmporteerd.
setup-account-servers = { $imap } en { $smtp } ({ $signin })
setup-file-name = Instellingen en accounts van Inbox Classic
setup-skipped-unreachable = De aanmeldapp { $name } is overgeslagen: de bijbehorende aanmeldservice kon niet worden bereikt. Voeg de app opnieuw toe via Aanmeldapps.
attachment-runs-programs = “{ $name }” kan programma’s uitvoeren, dus Inbox Classic opent het niet. Sla het op en open het daarna zelf als je vertrouwt waar het vandaan komt.
attachment-decrypted-note = Deze bijlage komt uit een versleuteld bericht. Om de bijlage te openen, slaat Inbox Classic een onversleutelde kopie op in een tijdelijke map voor jouw gebruikersaccount. Kopieën die ouder zijn dan een dag worden verwijderd wanneer Inbox Classic start.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] De server heeft { $messages } niet naar { $folder } verplaatst, dus het staat weer in { $from }: { $reason }
   *[other] De server heeft { $messages } niet naar { $folder } verplaatst, dus ze staan weer in { $from }: { $reason }
}
undone-delete = { $count ->
    [one] De server heeft { $messages } niet verwijderd, dus het staat weer in { $from }: { $reason }
   *[other] De server heeft { $messages } niet verwijderd, dus ze staan weer in { $from }: { $reason }
}
undone-archive = { $count ->
    [one] De server heeft { $messages } niet gearchiveerd, dus het staat weer in { $from }: { $reason }
   *[other] De server heeft { $messages } niet gearchiveerd, dus ze staan weer in { $from }: { $reason }
}
undone-read = { $count ->
    [one] De server heeft { $messages } niet als gelezen gemarkeerd, dus het is weer ongelezen: { $reason }
   *[other] De server heeft { $messages } niet als gelezen gemarkeerd, dus ze zijn weer ongelezen: { $reason }
}
undone-unread = { $count ->
    [one] De server heeft { $messages } niet als ongelezen gemarkeerd, dus het is weer gelezen: { $reason }
   *[other] De server heeft { $messages } niet als ongelezen gemarkeerd, dus ze zijn weer gelezen: { $reason }
}
undone-flags = { $count ->
    [one] De server heeft de markeringen van { $messages } niet gewijzigd, dus de wijziging is teruggedraaid: { $reason }
   *[other] De server heeft de markeringen van { $messages } niet gewijzigd, dus de wijziging is teruggedraaid: { $reason }
}
