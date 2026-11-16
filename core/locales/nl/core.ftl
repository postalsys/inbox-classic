# Nederlands. Concept, wacht op controle door een moedertaalspreker.
# What the core says, the same on every platform. Plurals: [one] and *[other] in Dutch.

## Counts and sizes

# review: new
messages = { $count ->
    [one] { $count } bericht
   *[other] { $count } berichten
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] { $count } byte
   *[other] { $count } bytes
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Uit
# review: new
send-delay-seconds = { $count ->
    [one] { $count } seconde
   *[other] { $count } seconden
}
# the status bar: "12 berichten, 3 ongelezen"
# review: new
list-counts = { $messages }, { $unread } ongelezen
# review: new
list-counts-selected = { $messages }, { $unread } ongelezen, { $selected } geselecteerd
# the status bar while searching: "12 gevonden, 3 ongelezen"
# review: new
list-counts-found = { $found } gevonden, { $unread } ongelezen
# review: new
list-counts-found-selected = { $found } gevonden, { $unread } ongelezen, { $selected } geselecteerd
# review: new
list-counts-none = Geen berichten gevonden

## Special folders, as Outlook names them

# review: new
folder-inbox = Postvak IN
# review: new
folder-sent = Verzonden items
# review: new
folder-deleted = Verwijderde items
# review: new
folder-drafts = Concepten
# review: new
folder-junk = Ongewenste e-mail
# review: new
folder-archive = Archief

## The reading pane

# review: new
reader-no-message = Er is geen bericht geselecteerd.
# review: new
reader-downloading = Het bericht wordt gedownload…
# review: new
reader-downloading-detail = Het bericht verschijnt hier zodra het downloaden klaar is.
# review: new
reader-downloading-size = Het bericht is { $size }. Het verschijnt hier zodra het is gedownload.
# review: new
reader-failed = Het bericht kon niet worden gedownload
# review: new
reader-failed-network = De mailserver kon niet worden bereikt ({ $reason }).
# review: new
reader-failed-sign-in = De mailserver heeft de aanmelding niet geaccepteerd ({ $reason }). Controleer het wachtwoord of meld je opnieuw aan via Bestand > Accounts.
# review: new
reader-failed-security = De verbinding met de mailserver kon niet worden beveiligd ({ $reason }).
# review: new
reader-failed-other = De mailserver antwoordde: { $reason }.
# review: new
reader-retry-note = Het wordt opnieuw geprobeerd wanneer het account weer verbinding maakt.
# review: new
reader-unreadable = Dit bericht kan niet worden getoond: { $error }
# review: new
message-source-title = Bron van bericht: { $subject }
# review: new
message-source-untitled = Bron van bericht

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Van
# review: new
header-date = Datum
# review: new
header-to = Aan
# review: new
header-cc = Cc
# review: new
header-sent = Verzonden
# review: new
header-subject = Onderwerp
# review: new
header-security = Beveiliging
# review: new
header-part = Deel { $number }
# review: new
quote-original = ----- Oorspronkelijk bericht -----
# review: new
fold-show-earlier = De eerdere berichten tonen

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Je bericht is niet bezorgd
# review: new
bounce-delayed = Je bericht is nog niet bezorgd
# review: new
bounce-delayed-note = Je mailserver probeert het nog steeds te bezorgen. Je hoeft het niet opnieuw te verzenden.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Het onbestelbare bericht tonen
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Het vertraagde bericht tonen
# review: new
bounce-what-to-do = Wat je kunt doen:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Nog niets. Als het nog steeds niet kan worden bezorgd, krijg je een nieuwe melding.
# review: new
bounce-delayed-row-do = Nog niets. Je mailserver probeert het nog steeds te bezorgen, en je krijgt een nieuwe melding als dat niet lukt.
# folds the receiving server's own words
# review: new
bounce-details = Details
# a recipient the notice does not name
# review: new
bounce-someone = Een ontvanger
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Status: { $status }
# review: new
bounce-reported-by = Gemeld door: { $server }
# review: new
bounce-retry-minutes = De ontvangende server vroeg om { $count ->
    [one] een minuut
   *[other] { $count } minuten
} te wachten voor de volgende poging.
# review: new
bounce-retry-hours = De ontvangende server vroeg om { $count ->
    [one] een uur
   *[other] { $count } uur
} te wachten voor de volgende poging.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Blokkeerlijst: { $lists }
# review: new
bounce-user-unknown = Het adres bestaat niet
# review: new
bounce-user-unknown-why = De ontvangende server heeft geen postvak met dit adres. Het is misschien verkeerd getypt, of de persoon gebruikt het niet meer.
# review: new
bounce-user-unknown-do = Controleer de spelling van het adres, of vraag de persoon welk adres hij of zij nu gebruikt.
# review: new
bounce-invalid-address = Het adres is niet geldig
# review: new
bounce-invalid-address-why = Het adres is niet geschreven in een vorm waarnaar e-mail kan worden verzonden.
# review: new
bounce-invalid-address-do = Zoek naar typefouten, zoals een spatie, een ontbrekende letter of niets na de @.
# review: new
bounce-mailbox-disabled = Het postvak is gesloten
# review: new
bounce-mailbox-disabled-why = Het adres bestaat, maar het postvak is uitgeschakeld of wordt niet meer gebruikt.
# review: new
bounce-mailbox-disabled-do = Neem op een andere manier contact op met de persoon en vraag om een adres dat nu wordt gebruikt.
# review: new
bounce-mailbox-full = Het postvak is vol
# review: new
bounce-mailbox-full-why = Het postvak van de ontvanger heeft geen ruimte voor nieuwe e-mail.
# review: new
bounce-mailbox-full-do = Verzend het over een paar dagen opnieuw, of laat het de persoon op een andere manier weten. Grote bijlagen worden het eerst geweigerd.
# review: new
bounce-spam-blocked = Geweigerd als spam
# review: new
bounce-spam-blocked-why = De ontvangende server zag het bericht aan voor spam.
# review: new
bounce-spam-blocked-do = Verzend het opnieuw zonder wat op spam lijkt, zoals veel links, verkorte links of een grote bijlage. Als het blijft gebeuren, vraag het dan aan je e-mailprovider.
# review: new
bounce-virus-detected = Geweigerd vanwege een virus
# review: new
bounce-virus-detected-why = De ontvangende server heeft een virus of andere schadelijke inhoud gevonden in het bericht of de bijlagen.
# review: new
bounce-virus-detected-do = Controleer de bijlagen met een virusscanner. Sommige servers weigeren elk programma of archief, deel zulke bestanden dan als link.
# review: new
bounce-ip-blocklisted = Je mailserver staat op een blokkeerlijst
# review: new
bounce-ip-blocklisted-why = De ontvangende server weigert e-mail van de server die jouw bericht verzond, omdat het adres van die server op een blokkeerlijst staat.
# review: new
bounce-ip-blocklisted-do = Het bericht is niet het probleem. Stuur deze melding door naar je e-mailprovider en vraag of die de server van de lijst laat halen.
# review: new
bounce-domain-blocklisted = Een domein staat op een blokkeerlijst
# review: new
bounce-domain-blocklisted-why = De ontvangende server weigert het bericht omdat het domein van je adres, of een domein in de links van het bericht, op een blokkeerlijst staat.
# review: new
bounce-domain-blocklisted-do = Als het bericht links bevat, probeer het dan zonder. Stuur deze melding anders door naar degene die de e-mail voor je domein beheert.
# review: new
bounce-policy-blocked = Geweigerd door de regels van de ontvangende server
# review: new
bounce-policy-blocked-why = De regels van de ontvangende server laten dit bericht niet door, bijvoorbeeld vanwege de grootte, de bijlagen of de afzender.
# review: new
bounce-policy-blocked-do = De eigen woorden van de server onder Details geven vaak de reden. Vraag de ontvanger of zulke e-mail kan worden ontvangen.
# review: new
bounce-geo-blocked = Geweigerd vanwege de herkomst
# review: new
bounce-geo-blocked-why = De ontvangende server neemt geen e-mail aan uit het land of netwerk waarin je mailserver staat.
# review: new
bounce-geo-blocked-do = Neem op een andere manier contact op met de persoon, of vraag je e-mailprovider ernaar.
# review: new
bounce-relay-denied = De server wilde het niet doorgeven
# review: new
bounce-relay-denied-why = Een server weigerde het bericht verder te bezorgen, vaak omdat het zonder aanmelding is verzonden of via een server die deze ontvanger niet afhandelt.
# review: new
bounce-relay-denied-do = Controleer de uitgaande server van het account in Bestand > Accounts, en of die zich aanmeldt.
# review: new
bounce-auth-failure = Je afzenderadres kon niet worden geverifieerd
# review: new
bounce-auth-failure-why = De ontvangende server kon niet bevestigen dat het bericht echt van je domein kwam (SPF, DKIM of DMARC).
# review: new
bounce-auth-failure-do = Stuur deze melding door naar degene die de e-mail voor je domein beheert: de instellingen moeten worden gecorrigeerd. Verzenden via de eigen server van je provider kan intussen helpen.
# review: new
bounce-rate-limited = Te veel e-mail tegelijk
# review: new
bounce-rate-limited-why = De ontvangende server neemt voorlopig minder berichten aan van je mailserver.
# review: new
bounce-rate-limited-do = Wacht even en verzend het opnieuw. Als je aan veel mensen schrijft, verzend dan aan minder mensen tegelijk.
# review: new
bounce-greylisting = Even tegengehouden
# review: new
bounce-greylisting-why = De ontvangende server vraagt onbekende afzenders het iets later opnieuw te proberen, een gangbare controle tegen spam.
# review: new
bounce-greylisting-do = Niets. Mailservers proberen het zelf opnieuw, en het bericht wordt meestal binnen het uur bezorgd.
# review: new
bounce-server-error = De ontvangende server had een probleem
# review: new
bounce-server-error-why = De ontvangende server kon niet worden bereikt, of kon het bericht niet aannemen door een eigen probleem.
# review: new
bounce-server-error-do = Verzend het later opnieuw. Als het blijft mislukken, controleer dan het deel van het adres na de @ op typefouten.
# review: new
bounce-unknown = Niet bezorgd
# review: new
bounce-unknown-why = De melding zegt niet duidelijk waarom.
# review: new
bounce-unknown-do = De eigen woorden van de server onder Details zeggen misschien meer. Als die niet helpen, stuur deze melding dan door naar je e-mailprovider.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } bericht geselecteerd
   *[other] { $count } berichten geselecteerd
}
# review: new
selection-unread = { $count } ongelezen
# review: new
selection-flagged = { $count } gemarkeerd
# review: new
delete-for-good-one = Dit bericht wordt definitief verwijderd. Verwijderen?
# review: new
delete-for-good-all = Deze { $count } berichten worden definitief verwijderd. Verwijderen?
# review: new
delete-for-good-some = { $count } van de { $total } berichten worden definitief verwijderd. De berichten verwijderen?
# review: new
done-read = { $count ->
   *[other] { $messages } gemarkeerd als gelezen
}
# review: new
done-unread = { $count ->
   *[other] { $messages } gemarkeerd als ongelezen
}
# review: new
done-flagged = { $count ->
   *[other] { $messages } gemarkeerd
}
# review: new
done-unflagged = Markering verwijderd van { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] { $messages } definitief verwijderd
}
# review: new
done-archived = { $count ->
   *[other] { $messages } gearchiveerd
}
# review: new
done-moved = { $count ->
   *[other] { $messages } verplaatst naar { $folder }
}
# review: new
done-copied = { $count ->
   *[other] { $messages } gekopieerd naar { $folder }
}
# review: new
done-moving = { $count ->
    [one] { $messages } wordt verplaatst naar { $folder }...
   *[other] { $messages } worden verplaatst naar { $folder }...
}
# review: new
done-copying = { $count ->
    [one] { $messages } wordt gekopieerd naar { $folder }...
   *[other] { $messages } worden gekopieerd naar { $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] { $messages } teruggezet naar { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Het gesprek wordt gevolgd
   *[other] { $count } gesprekken worden gevolgd
}
# review: new
done-unwatched = { $count ->
    [one] Het gesprek wordt niet meer gevolgd
   *[other] { $count } gesprekken worden niet meer gevolgd
}
# review: new
done-ignored = { $count ->
    [one] Het gesprek wordt genegeerd
   *[other] { $count } gesprekken worden genegeerd
}
# review: new
done-unignored = { $count ->
    [one] Het gesprek wordt niet meer genegeerd
   *[other] { $count } gesprekken worden niet meer genegeerd
}
# review: new
their-folders = hun mappen
# review: new
undo-move = Verplaatsen ongedaan maken
# review: new
undo-delete = Verwijderen ongedaan maken
# review: new
undo-archive = Archiveren ongedaan maken
# review: new
undo-junk = Markeren als ongewenst ongedaan maken
# review: new
undo-not-junk = Markeren als gewenst ongedaan maken
# review: new
undo-send = Verzenden ongedaan maken
# review: new
nothing-to-undo = Er is niets om ongedaan te maken.
# review: new
messages-gone = De berichten zijn er niet meer.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Deze map kan geen berichten bevatten.
# review: new
not-archived-here = Berichten in deze map kunnen niet worden gearchiveerd.
# review: new
not-emptied-here = Alleen Verwijderde items en Ongewenste e-mail kunnen worden leeggemaakt.
# review: new
next-unread-question = Er zijn geen ongelezen berichten meer in { $folder }.

    Naar { $next } gaan, de volgende map met ongelezen berichten?
# review: new
no-unread-left = Er zijn geen ongelezen berichten meer.
# review: new
empty-question = { $count ->
    [one] { $folder } leegmaken?

        Het bericht erin wordt definitief verwijderd. Het kan niet worden teruggehaald.
   *[other] { $folder } leegmaken?

        De { $messages } erin worden definitief verwijderd. Ze kunnen niet worden teruggehaald.
}
# review: new
no-junk-folder = Dit account heeft geen map Ongewenste e-mail om de berichten naartoe te verplaatsen.
# review: new
no-inbox-folder = Dit account heeft geen map Postvak IN om de berichten naartoe te verplaatsen.
# the status bar after a flag in a colour: "2 berichten blauw gemarkeerd"
# review: new
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
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Bericht verplaatsen
   *[other] { $count } berichten verplaatsen
}
# review: new
move-window-title-copy = { $count ->
    [one] Bericht kopiëren
   *[other] { $count } berichten kopiëren
}
# review: new
move-window-prompt-move = { $count ->
    [one] Het geselecteerde bericht verplaatsen naar:
   *[other] De { $count } geselecteerde berichten verplaatsen naar:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Het geselecteerde bericht kopiëren naar:
   *[other] De { $count } geselecteerde berichten kopiëren naar:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Recent
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (huidige)
# a folder used last, with its account when there are several: "Archief (Werk)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = { $done } van { $messages } verplaatsen naar { $folder }...
# review: new
transfer-copying = { $done } van { $messages } kopiëren naar { $folder }...
# review: new
transfer-another-account = een ander account
# review: new
transfer-folder-gone = de map waar het naartoe ging, bestaat niet meer
# review: new
transfer-not-on-server = het bericht staat niet meer op de server
# review: new
transfer-not-moved = { $count ->
    [one] { $messages } kon niet naar een ander account worden verplaatst: { $reason }
   *[other] { $messages } konden niet naar een ander account worden verplaatst: { $reason }
}
# review: new
transfer-not-copied = { $count ->
    [one] { $messages } kon niet naar een ander account worden gekopieerd: { $reason }
   *[other] { $messages } konden niet naar een ander account worden gekopieerd: { $reason }
}
# review: new
transfer-none-moved = Er kon geen bericht worden verplaatst
# review: new
transfer-none-copied = Er kon geen bericht worden gekopieerd

## Messages as files

# review: new
export-not-in-time = het bericht kon niet op tijd worden gedownload
# review: new
export-not-saved = { $failed } van { $messages } konden niet worden opgeslagen ({ $problems })
# review: new
export-not-attached = de berichten konden niet worden bijgevoegd: { $error }
# the status bar after Save As with several: "3 berichten opgeslagen in Bureaublad"
# review: new
saved-to = { $count ->
   *[other] { $messages } opgeslagen in { $folder }
}
# review: new
download-progress = { $done } van { $total } downloaden
# review: new
download-done = { $size } gedownload
# review: new
downloading-messages = { $count ->
   *[other] { $messages } downloaden...
}
# the status bar after files are dropped on a folder: "3 berichten in Archief gezet"
# review: new
import-put = { $count ->
   *[other] { $messages } in { $folder } gezet
}
# review: new
import-not-put = Deze zijn niet in de map gezet:

    { $problems }

## Problems the windows show

# review: new
error-store = lokale opslag: { $error }
# review: new
error-not-found = niet gevonden
# review: new
error-closed = wordt afgesloten
# review: new
error-other-account = de browser heeft zich aangemeld bij { $email }, niet bij dit account
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = de server heeft de aanmelding niet geaccepteerd ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = de verbinding met de server is mislukt ({ $reason })
# review: new
error-in-use = de app kan niet worden verwijderd zolang accounts zich ermee aanmelden: { $accounts }
# review: new
error-turned-off = deze aanmeldapp is uitgeschakeld voor nieuwe accounts
# review: new
error-folder-name = de mapnaam moet 1 tot 200 tekens lang zijn en mag geen besturingstekens bevatten
# review: new
error-folder-separator = een mapnaam mag op deze server geen “{ $separator }” bevatten
# review: new
error-folder-special = Postvak IN en de speciale mappen kunnen niet worden hernoemd of verwijderd
# review: new
error-no-recipients = het bericht heeft geen ontvangers
# review: new
error-bad-address = “{ $address }” is geen e-mailadres
# review: new
error-not-own-address = { $address } is niet een van de afzenderadressen van dit account. Voeg het toe aan “Andere adressen waarvan je verzendt” in de eigenschappen van het account.
# review: new
rule-query-refused = Regels kunnen niet filteren op map of datum ({ $words }).
# review: new
rule-no-query = Typ zoekcriteria voor binnenkomende berichten.
# review: new
rule-no-action = Kies ten minste één actie voor de regel.
# review: new
error-attachment = { $path } kon niet worden gelezen: { $error }
# review: new
error-no-drafts = het account heeft geen map Concepten om het bericht in op te slaan
# review: new
error-draft-attachment = een bijlage van het concept kon niet worden behouden: { $error }
# review: new
error-password-not-saved = het wachtwoord kon niet worden opgeslagen voor de volgende start: { $error }
# review: new
error-sign-in-not-saved = de nieuwe aanmeldgegevens konden niet worden opgeslagen voor de volgende start: { $error }
# review: new
error-import-unreadable = { $path } kan niet worden gelezen: { $error }
# review: new
error-import-too-large = { $path } is groter dan 50 MB
# review: new
error-import-not-mail = { $path } is geen e-mailbericht
# review: new
error-list-answered = de server van de mailinglijst gaf status { $status }
# review: new
error-not-built = het bericht kon niet worden opgesteld
# review: new
error-outbox-waits = { $count ->
    [one] het bericht wacht in Postvak UIT en wordt verzonden bij de volgende keer Verzenden/ontvangen
   *[other] { $count } berichten wachten in Postvak UIT en worden verzonden bij de volgende keer Verzenden/ontvangen
}
# review: new
error-draft-not-removed = het eerdere concept van het bericht kon niet uit Concepten worden verwijderd: { $reason }
# review: new
error-sent-but = het bericht is verzonden, maar { $problem }
# review: new
error-sent-still-in-outbox = het staat nog in Postvak UIT: { $error }
# review: new
error-sent-no-copy = er kon geen kopie worden opgeslagen in Verzonden items: { $reason }
# review: new
error-no-password = geen wachtwoord voor dit account
# review: new
error-no-sign-in = geen aanmelding voor dit account
# review: new
error-provider-missing = deze versie kan zich niet aanmelden bij { $provider }: is de aanmeldapp ervan verwijderd?
# review: new
error-provider-servers = de servers van dit account komen niet overeen met de servers van de aanmeldapp
# review: new
error-app-scopes = { $reason }. De mailserver heeft het token van de aanmeldapp niet geaccepteerd: controleer of de machtigingen (scopes) van de app toegang tot e-mail geven
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google heeft Inbox Classic nog niet geverifieerd, dus alleen testgebruikers kunnen zich ermee aanmelden. Gebruik je eigen Google-aanmeldapp of een app-wachtwoord, of schakel het in bij Aanmeldapps (Bestand > Accounts) als je een testgebruiker bent.
# review: new
sign-in-off-other = Deze is uitgeschakeld bij Aanmeldapps (Bestand > Accounts), waar je hem weer kunt inschakelen.
# review: new
sign-in-app-no-name = de aanmeldapp heeft een naam nodig
# review: new
sign-in-app-no-client = de client-ID ontbreekt
# review: new
sign-in-app-no-scopes = de aanmeldapp heeft de machtigingen (scopes) nodig die toegang tot e-mail geven
# review: new
sign-in-app-bad-host = het adres van de { $server }-server ontbreekt of is geen geldige hostnaam
# review: new
sign-in-app-plain = de { $server }-server moet SSL/TLS of STARTTLS gebruiken
# review: new
sign-in-app-not-checked = de uitgever is nog niet gecontroleerd
# review: new
sign-in-app-issuer-changed = de uitgever is gewijzigd: typ het clientgeheim opnieuw, of verwijder het
# review: new
sign-in-register-google = Maak in Google Cloud Console een OAuth-client van het type Desktop app, met de scope https://mail.google.com/ op het toestemmingsscherm. Zolang de app in de testfase is, kunnen alleen de testgebruikers ervan zich aanmelden.
# review: new
sign-in-register-microsoft = Registreer in Microsoft Entra een app met het platform Mobile and desktop applications, de omleidings-URI http://localhost en public client flows toegestaan, en de gedelegeerde machtigingen IMAP.AccessAsUser.All, SMTP.Send en offline_access. Gebruik alleen voor je eigen organisatie https://login.microsoftonline.com/<tenant ID>/v2.0 als uitgever.
# review: new
sign-in-register-other = Registreer een native (openbare) client met de omleidings-URI hieronder; de provider moet daarop elke poort toestaan (RFC 8252). Voeg de scope toe waarmee de provider toegang tot e-mail geeft.

## Calendar invitations

# review: new
repeats = Herhaalt
# review: new
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
# review: new
repeats-on = { $repeats } op { $days }
# "Elke week, 10 keer"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, één keer
   *[other] { $repeats }, { $count } keer
}
# review: new
day-monday = maandag
# review: new
day-tuesday = dinsdag
# review: new
day-wednesday = woensdag
# review: new
day-thursday = donderdag
# review: new
day-friday = vrijdag
# review: new
day-saturday = zaterdag
# review: new
day-sunday = zondag

## AI agents

# review: new
agent-level-read = E-mail lezen: mappen, de berichtenlijst, zoeken en berichten
# review: new
agent-level-organize = E-mail ordenen: gelezen of ongelezen, markeringen, ongewenst, verplaatsen, verwijderen naar Verwijderde items
# review: new
agent-level-drafts = Concepten schrijven die jij verzendt
# review: new
agent-level-send = E-mail verzenden, elk bericht pas nadat jij ja zegt
# review: new
agent-connect-title = { $program } wil je e-mail gebruiken
# review: new
agent-connect-detail = Een AI-agent heeft gevraagd om met Inbox Classic te werken. Kies wat hij mag doen en welke accounts hij mag zien; je kunt dit later wijzigen via Extra > AI-agents.

    Agents lezen e-mail die anderen hebben geschreven, en een bericht kan proberen ze te misleiden. Inbox Classic vraagt het je altijd voordat een agent iets verzendt.
# review: new
agent-reply-to = Antwoord op “{ $subject }”
# review: new
agent-reply-all-on = Antwoord aan allen op “{ $subject }”
# review: new
agent-forward-of = Doorgestuurd: “{ $subject }”
# review: new
agent-never-written-one = Je hebt nog nooit geschreven aan { $address }.
# review: new
agent-never-written-many = Je hebt nog nooit geschreven aan { $count } van deze adressen.
# review: new
agent-send-title = { $program } wil dit bericht verzenden
# review: new
agent-send-detail = Controleer de ontvangers en de inhoud van het bericht. Zodra je bevestigt, wacht het bericht { $seconds } seconden in Postvak UIT, waar je het nog kunt verwijderen.
# review: new
agent-change-title = Wat { $program } mag doen
# review: new
agent-change-allowed = Wijzig wat de AI-agents van dit programma met je e-mail mogen doen.
# review: new
agent-change-refused = Je hebt dit programma toegang geweigerd. Sta het toe om de agents ervan weer toegang tot je e-mail te geven.
# review: new
agent-log-taken-back = { $entry } (teruggedraaid)
# review: new
agent-files = Bestanden: { $files }
# review: new
agent-undo-refused = Dit kan niet worden teruggedraaid.
# review: new
agent-undo-refused-why = Dit kan niet worden teruggedraaid: { $reason }.
# review: new
agent-undo-impossible = dit kan niet worden teruggedraaid
# review: new
agent-undo-not-in-folder = het bericht staat niet meer in die map
# review: new
agent-undo-not-arrived = het bericht staat (nog) niet in de map waar het naartoe ging
# review: new
agent-undo-sent = het bericht is al verzonden
# review: new
agent-original-not-downloaded = het oorspronkelijke bericht is nog niet gedownload. Open het eerst
# review: new
agent-turned-away = Geweigerd
# review: new
agent-can-nothing = Niets
# review: new
agent-can-read = lezen
# review: new
agent-can-organize = ordenen
# review: new
agent-can-drafts = concepten schrijven
# review: new
agent-can-send = verzenden met jouw ja
# "lezen, ordenen en concepten schrijven"
# review: new
agent-can-list = { $first } en { $last }
# review: new
agent-accounts = { $count ->
    [0] geen accounts
    [one] { $count } account
   *[other] { $count } accounts
}
# "lezen en ordenen; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Dit bericht kan niet worden gelezen.
# review: new
agent-encrypted-original = Dit bericht is versleuteld: een agent kan het niet beantwoorden of doorsturen, omdat hij niet kan versleutelen.
# review: new
agent-log-composed = “{ $subject }” geopend in een nieuw bericht dat jij afmaakt
# review: new
agent-log-refused = Je hebt “{ $subject }” niet verzonden
# review: new
agent-log-sent = “{ $subject }” verzonden aan { $to }
# review: new
agent-log-draft = Het concept “{ $subject }” opgeslagen
# review: new
agent-log-read = “{ $subject }” gemarkeerd als gelezen
# review: new
agent-log-unread = “{ $subject }” gemarkeerd als ongelezen
# review: new
agent-log-flagged = “{ $subject }” gemarkeerd
# review: new
agent-log-unflagged = Markering verwijderd van “{ $subject }”
# review: new
agent-log-deleted = “{ $subject }” verwijderd
# review: new
agent-log-moved = “{ $subject }” verplaatst naar { $folder }
# review: new
agent-log-junk = “{ $subject }” gemarkeerd als ongewenst
# review: new
agent-log-not-junk = “{ $subject }” gemarkeerd als gewenst
# review: new
agent-log-archived = “{ $subject }” gearchiveerd
# review: new
agent-log-folder = De map “{ $name }” gemaakt
# review: new
agent-log-unsubscribed = Afgemeld bij de lijst van “{ $subject }”

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
sign-in-no-refresh = de provider heeft geen vernieuwingstoken gegeven
# review: new
sign-in-no-account = de provider heeft niet gezegd welk account zich heeft aangemeld
# review: new
sign-in-not-finished = het aanmelden is nog niet voltooid
# review: new
secrets-unavailable = { $store } is niet beschikbaar
# review: new
secrets-unavailable-why = { $store } is niet beschikbaar: { $error }
# review: new
secrets-windows = Referentiebeheer
# review: new
secrets-mac = de sleutelhanger
# review: new
secrets-linux = de sleutelbos van het systeem (Secret Service)
# review: new
error-no-such-file = dit bestand bestaat niet
# review: new
cards-file-too-big = Dit bestand is te groot om een adresboek te zijn.
# review: new
ui-sender-added = { $name } is toegevoegd aan het Adresboek.
# review: new
ui-sender-known = { $name } staat al in het Adresboek.
# review: new
ui-sender-none = De afzender van dit bericht heeft geen e-mailadres om toe te voegen.
# review: new
card-name-needed = De contactpersoon heeft geen naam en geen e-mailadres.
# a file of Import Address Book that could not be read: "contacts.vcf: dit bestand bestaat niet"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Code van { $domain }
# review: new
otp-copy = Kopiëren
# review: new
otp-note = Vul deze alleen in op een pagina van { $domain }.
# review: new
otp-old = Deze code is meer dan een uur voordat je hem opende verzonden, en is waarschijnlijk verlopen.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } deelnemer
       *[other] { $count } deelnemers
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } is je code voor { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Geldig
# review: new
pgp-key-expires = Geldig tot { $date }
# review: new
pgp-key-expired = Verlopen op { $date }
# review: new
pgp-key-revoked = Ingetrokken
# review: new
pgp-key-revoked-why = Ingetrokken: { $reason }
# review: new
pgp-key-not-valid = Niet geldig
# review: new
pgp-key-locked = Kan niet worden gebruikt: de sleutel die hem beschermt, staat niet meer in { $store }. Importeer de back-up ervan opnieuw.
# review: new
pgp-source-own = Gemaakt in Inbox Classic
# review: new
pgp-source-file = Geïmporteerd uit een bestand
# review: new
pgp-source-paste = Geplakt
# review: new
pgp-source-attachment = Uit een bericht
# review: new
pgp-source-vcard = Uit een visitekaartje
# review: new
pgp-source-wkd = Van de e-mailprovider van de afzender
# review: new
pgp-source-keyserver = Van keys.openpgp.org
# review: new
pgp-source-autocrypt = Uit de Autocrypt-header van een bericht
# review: new
pgp-error-no-store = Privésleutels worden beschermd door { $store }, maar dat kan niet worden gebruikt: { $error }
# review: new
pgp-error-wrong-passphrase = De wachtwoordzin klopt niet.
# review: new
pgp-error-not-a-key = Dit is geen OpenPGP-sleutel.
# review: new
pgp-error-too-large = De sleutel is te groot.
# review: new
pgp-error-unusable = De sleutel gebruikt oude of zwakke cryptografie en kan niet worden gebruikt.
# review: new
pgp-imported-private = { $count ->
    [one] Je privésleutel is geïmporteerd.
   *[other] { $count } privésleutels zijn geïmporteerd.
}
# review: new
pgp-imported-public = { $count ->
    [one] Eén sleutel is geïmporteerd.
   *[other] { $count } sleutels zijn geïmporteerd.
}
# review: new
pgp-imported-pending = Er wordt al een andere sleutel gebruikt voor { $addresses }: de nieuwe wacht bij de contactpersoon totdat je hem kiest.
# review: new
pgp-error-needs-passphrase = De privésleutel is beschermd door een wachtwoordzin. Typ die om de sleutel te importeren.
# review: new
pgp-error-mismatch = De privésleutel hoort niet bij de openbare sleutel. Hij is mogelijk gewijzigd.
# review: new
pgp-file-name-public = { $who } openbare sleutel.asc
# review: new
pgp-file-name-private = { $who } back-up privésleutel.asc
# review: new
pgp-pending = Op { $date } is een andere sleutel voor { $address } gevonden.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Ondertekend door { $signer }, sleutel geverifieerd
# review: new
pgp-part-signed = Ondertekend door { $signer } (sleutel niet geverifieerd)
# review: new
pgp-part-other = Ondertekend door { $signer }, die niet de afzender is
# review: new
pgp-part-unknown-key = Ondertekend, maar de sleutel is onbekend
# review: new
pgp-part-not-signed = Niet ondertekend
# review: new
pgp-part-not-checked = Handtekening niet gecontroleerd
# review: new
pgp-part-encrypted = Versleuteld. { $signature }
# review: new
pgp-part-no-key = Versleuteld voor een sleutel die je niet hebt
# review: new
pgp-part-changed = Het versleutelde deel is onderweg gewijzigd en wordt niet getoond
# review: new
pgp-part-unprotected = Versleuteld zonder bescherming tegen wijzigingen, niet getoond
# review: new
pgp-part-broken = Het versleutelde deel kan niet worden gelezen
# review: new
pgp-why-mismatch = De handtekening past niet bij deze tekst
# review: new
pgp-why-weak-hash = De handtekening gebruikt { $hash }, dat niet meer veilig is
# review: new
pgp-why-key-expired = Ondertekend nadat de sleutel op { $date } was verlopen
# review: new
pgp-why-key-revoked = Ondertekend met een sleutel die is ingetrokken
# review: new
pgp-why-not-signing-key = Ondertekend met een sleutel die niet mag ondertekenen
# review: new
pgp-why-from-future = De handtekening is gedateerd in de toekomst
# review: new
pgp-why-signature-expired = De handtekening is verlopen
# review: new
pgp-why-key-not-valid = Ondertekend met een sleutel die niet geldig is
# review: new
pgp-why-not-for-you = Ondertekend voor andere ontvangers en aan jou doorgegeven
# review: new
pgp-part-pictures-loaded = { $label }. Er zijn afbeeldingen van internet geladen
# review: new
pgp-error-no-own-key = Je hebt geen sleutel voor { $address } om mee te ondertekenen of te versleutelen. Maak er een via Extra > Versleutelingssleutels, of zet Ondertekenen en Versleutelen uit.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } heeft geen sleutel om voor te versleutelen.
   *[other] Deze ontvangers hebben geen sleutel om voor te versleutelen: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Dit bericht citeert of stuurt een versleuteld bericht door, dus het kan alleen versleuteld worden verzonden. Zet Versleutelen aan, of verwijder de geciteerde tekst.
# review: new
pgp-error-protect = Het bericht kon niet worden ondertekend of versleuteld: { $reason }
# review: new
pgp-found-keys = De sleutel van { $addresses } is gevonden.
# review: new
pgp-found-none = Er is geen sleutel gevonden voor { $addresses }. Vraag om de openbare sleutel toe te sturen.
# review: new
pgp-found-no-key = Er is geen sleutel gevonden.
# review: new
pgp-find-unavailable = Sleutels kunnen nu niet worden opgezocht: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org heeft een bevestigingslink gestuurd naar { $addresses }. Je sleutel wordt daar gepubliceerd zodra je erop klikt.
# review: new
pgp-publish-done = Je sleutel is gepubliceerd op keys.openpgp.org voor { $addresses }.
# review: new
pgp-publish-failed = De sleutel kon niet worden gepubliceerd: { $error }
# review: new
pgp-keyserver-off = Sleutels opzoeken op keys.openpgp.org is uitgeschakeld in Opties.
# review: new
pgp-details-part = Deel { $number }: { $label }
# review: new
pgp-details-signed = Ondertekend { $when } met de sleutel { $key }
# review: new
pgp-details-unknown-key = Ondertekend met de sleutel { $key }, die je niet hebt
# review: new
pgp-details-opened = Versleuteld voor je sleutel { $key }
# review: new
pgp-details-for = Versleuteld voor { $keys }
# review: new
pgp-details-plain = Niet ondertekend en niet versleuteld
# review: new
pgp-bar-parts = Dit bericht heeft { $count } delen: { $list }. Bij elk deel staat hoe het is beschermd.
# review: new
pgp-bar-count-verified = { $count } geverifieerd
# review: new
pgp-bar-count-good = { $count ->
    [one] { $count } ondertekend of versleuteld
   *[other] { $count } ondertekend of versleuteld
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] { $count } vraagt aandacht
   *[other] { $count } vragen aandacht
}
# review: new
pgp-bar-count-neutral = { $count } zonder bevestigde handtekening
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Instellingen
# review: new
setup-part-preferences = Vensterinstellingen
# review: new
setup-part-accounts = Accounts
# review: new
setup-part-sign-in-apps = Aanmeldapps
# review: new
setup-part-contacts = Contactpersonen en groepen
# review: new
setup-part-keys = Versleutelingssleutels
# review: new
setup-part-rules = Berichtenregels
# review: new
setup-part-trusted-senders = Vertrouwde afzenders
# review: new
setup-holds-settings = { $count ->
    [one] { $count } instelling
   *[other] { $count } instellingen
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } vensterinstelling
   *[other] { $count } vensterinstellingen
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } account
   *[other] { $count } accounts
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } aanmeldapp
   *[other] { $count } aanmeldapps
}
# review: new
setup-holds-built-in = Welke ingebouwde aanmeldapps zijn ingeschakeld
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } contactpersoon
   *[other] { $count } contactpersonen
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } groep
   *[other] { $count } groepen
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } eigen sleutel
   *[other] { $count } eigen sleutels
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } sleutel van een contactpersoon
   *[other] { $count } sleutels van contactpersonen
}
# review: new
setup-holds-rules = { $count ->
    [one] { $count } regel
   *[other] { $count } regels
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] { $count } vertrouwde afzender
   *[other] { $count } vertrouwde afzenders
}
# review: new
setup-sign-in-password = Wachtwoord
# review: new
setup-account-secret-password = Het wachtwoord staat in het bestand.
# review: new
setup-account-secret-token = De aanmelding staat in het bestand.
# review: new
setup-account-asks-password = Na het importeren wordt om het wachtwoord gevraagd.
# review: new
setup-account-signs-in-again = Na het importeren meld je je er opnieuw bij aan.
# review: new
setup-account-here = Dit account staat hier al, dus het wordt overgeslagen.
# review: new
setup-account-no-app = Het meldt zich aan met { $app }, die hier niet is ingesteld. Importeer ook de aanmeldapps.
# review: new
setup-invalid-address = “{ $address }” is geen e-mailadres.
# review: new
setup-invalid-server = De { $server }-server heeft geen bruikbare naam of poort.
# review: new
setup-invalid-user = Er is geen gebruikersnaam.
# review: new
setup-invalid-sign-in = Het meldt zich aan op een manier die Inbox Classic niet kent.
# review: new
setup-error-empty = Het bestand is leeg.
# review: new
setup-error-too-large = Het bestand is te groot om een instellingenbestand van Inbox Classic te zijn.
# review: new
setup-error-not-setup = Dit bestand is geen instellingenbestand van Inbox Classic.
# review: new
setup-error-damaged = Het instellingenbestand is beschadigd en kan niet worden gelezen.
# review: new
setup-error-newer = Dit bestand is opgeslagen door een nieuwere Inbox Classic ({ $version }). Werk Inbox Classic bij en importeer het dan opnieuw.
# review: new
setup-error-needs-passphrase = Dit bestand is beveiligd met een wachtwoordzin. Typ de wachtwoordzin waarmee het is opgeslagen.
# review: new
setup-error-wrong-passphrase = Dat is niet de wachtwoordzin waarmee dit bestand is opgeslagen.
# review: new
setup-error-changed = Het instellingenbestand is na het opslaan gewijzigd of beschadigd, dus het kan niet worden geïmporteerd.
# review: new
setup-error-read = Het instellingenbestand kon niet worden gelezen: { $error }
# review: new
setup-error-write = De instellingen konden niet worden opgeslagen: { $error }
# review: new
setup-error-no-parts = Kies ten minste één onderdeel.
# review: new
setup-left-out = { $count ->
    [one] { $count } item van { $part } kan niet worden gebruikt en wordt weggelaten.
   *[other] { $count } items van { $part } kunnen niet worden gebruikt en worden weggelaten.
}
# review: new
setup-imported-settings = De instellingen zijn vervangen.
# review: new
setup-imported-preferences = De vensterinstellingen zijn vervangen.
# review: new
setup-added-accounts = { $count ->
    [one] { $count } account toegevoegd.
   *[other] { $count } accounts toegevoegd.
}
# review: new
setup-skipped-here = { $address } staat hier al, dus het is overgeslagen.
# review: new
setup-skipped-no-app = { $address } is overgeslagen: het meldt zich aan met { $app }, die hier niet is ingesteld.
# review: new
setup-skipped-invalid = { $address } is overgeslagen: { $reason }
# review: new
setup-asks-password = { $address } vraagt om het wachtwoord wanneer het verbinding maakt.
# review: new
setup-signs-in-again = { $address } vraagt je om je opnieuw aan te melden wanneer het verbinding maakt.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] { $count } aanmeldapp toegevoegd.
   *[other] { $count } aanmeldapps toegevoegd.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aanmeldapp is hier al ingesteld.
   *[other] { $count } aanmeldapps zijn hier al ingesteld.
}
# review: new
setup-added-contacts = { $count ->
    [one] { $count } contactpersoon toegevoegd aan het adresboek.
   *[other] { $count } contactpersonen toegevoegd aan het adresboek.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } contactpersoon staat al in het adresboek.
   *[other] { $count } contactpersonen staan al in het adresboek.
}
# review: new
setup-added-groups = { $count ->
    [one] { $count } groep toegevoegd of aangevuld.
   *[other] { $count } groepen toegevoegd of aangevuld.
}
# review: new
setup-added-own-keys = { $count ->
    [one] { $count } eigen sleutel toegevoegd.
   *[other] { $count } eigen sleutels toegevoegd.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] { $count } sleutel van een contactpersoon toegevoegd.
   *[other] { $count } sleutels van contactpersonen toegevoegd.
}
# review: new
setup-added-rules = { $count ->
    [one] { $count } berichtregel toegevoegd.
   *[other] { $count } berichtenregels toegevoegd.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } berichtregel staat hier al.
   *[other] { $count } berichtenregels staan hier al.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } berichtregel is voor een account dat hier niet is, dus die is overgeslagen.
   *[other] { $count } berichtenregels zijn voor accounts die hier niet zijn, dus die zijn overgeslagen.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } berichtregel verplaatst berichten naar een map die verschijnt zodra het account is gesynchroniseerd.
   *[other] { $count } berichtenregels verplaatsen berichten naar mappen die verschijnen zodra de accounts zijn gesynchroniseerd.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] { $count } vertrouwde afzender toegevoegd.
   *[other] { $count } vertrouwde afzenders toegevoegd.
}
# review: new
setup-nothing = Er is niets geïmporteerd.
# review: new
setup-account-servers = { $imap } en { $smtp } ({ $signin })
# review: new
setup-file-name = Instellingen en accounts van Inbox Classic
# review: new
setup-skipped-unreachable = { $name } is overgeslagen: de aanmeldservice kon niet worden bereikt. Voeg hem opnieuw toe bij Aanmeldapps.
