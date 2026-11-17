# Română. Ciornă, așteaptă revizuirea unui vorbitor nativ (vezi core/locales/GLOSSARY.md).
# Plurals: [one] 1, [few] 0 and 2 to 19 (and 101 to 119...), *[other] 20 and up, which takes "de": "20 de mesaje".

## Counts and sizes

messages = { $count ->
    [one] 1 mesaj
    [few] { $count } mesaje
   *[other] { $count } de mesaje
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] 1 octet
    [few] { $count } octeți
   *[other] { $count } de octeți
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Dezactivat
# review: new
send-delay-seconds = { $count ->
    [one] 1 secundă
    [few] { $count } secunde
   *[other] { $count } de secunde
}
# the status bar: "12 mesaje, necitite: 3"
# review: new
list-counts = { $messages }, necitite: { $unread }
# review: new
list-counts-selected = { $messages }, necitite: { $unread }, selectate: { $selected }
# the status bar while searching
# review: new
list-counts-found = Găsite: { $found }, necitite: { $unread }
# review: new
list-counts-found-selected = Găsite: { $found }, necitite: { $unread }, selectate: { $selected }
# review: new
list-counts-none = Nu s-au găsit mesaje

## Special folders, as Outlook names them

# review: new
folder-inbox = Mesaje primite
# review: new
folder-sent = Elemente trimise
# review: new
folder-deleted = Elemente șterse
# review: new
folder-drafts = Schițe
# review: new
folder-junk = E-mail nedorit
# review: new
folder-archive = Arhivă

## The reading pane

# review: new
reader-no-message = Nu este selectat niciun mesaj.
# review: new
reader-downloading = Se descarcă mesajul…
# review: new
reader-downloading-detail = Mesajul va apărea aici după ce se termină descărcarea.
# review: new
reader-downloading-size = Mesajul are { $size }. Va apărea aici după ce este descărcat.
# review: new
reader-failed = Mesajul nu a putut fi descărcat
# review: new
reader-failed-network = Serverul de e-mail nu a putut fi contactat ({ $reason }).
# review: new
reader-failed-sign-in = Serverul de e-mail nu a acceptat conectarea ({ $reason }). Verificați parola sau conectați-vă din nou în Fișier > Conturi.
# review: new
reader-failed-security = Conexiunea cu serverul de e-mail nu a putut fi securizată ({ $reason }).
# review: new
reader-failed-other = Serverul de e-mail a răspuns: { $reason }.
# review: new
reader-retry-note = Se va încerca din nou când contul se reconectează.
# review: new
reader-unreadable = Acest mesaj nu poate fi afișat: { $error }
# review: new
message-source-title = Sursa mesajului: { $subject }
# review: new
message-source-untitled = Sursa mesajului

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = De la
# review: new
header-date = Dată
# review: new
header-to = Către
# review: new
header-cc = Cc
# review: new
header-sent = Trimis
# review: new
header-subject = Subiect
# review: new
header-security = Securitate
# review: new
header-part = Partea { $number }
# review: new
quote-original = ----- Mesaj original -----
# review: new
fold-show-earlier = Afișați mesajele anterioare

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Mesajul dvs. nu a fost livrat
# review: new
bounce-delayed = Mesajul dvs. nu a fost livrat încă
# review: new
bounce-delayed-note = Serverul dvs. de e-mail încă încearcă să îl livreze. Nu trebuie să îl trimiteți din nou.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Afișați mesajul returnat
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Afișați mesajul întârziat
# review: new
bounce-what-to-do = Ce puteți face:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Deocamdată nimic. Dacă tot nu poate fi livrat, veți primi o altă notificare.
# review: new
bounce-delayed-row-do = Deocamdată nimic. Serverul dvs. de e-mail încă încearcă să îl livreze și veți primi o altă notificare dacă nu reușește.
# folds the receiving server's own words
# review: new
bounce-details = Detalii
# a recipient the notice does not name
# review: new
bounce-someone = Un destinatar
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Stare: { $status }
# review: new
bounce-reported-by = Raportat de: { $server }
# review: new
bounce-retry-minutes = Serverul destinatar a cerut o pauză de { $count ->
    [one] un minut
    [few] { $count } minute
   *[other] { $count } de minute
} înainte de următoarea încercare.
# review: new
bounce-retry-hours = Serverul destinatar a cerut o pauză de { $count ->
    [one] o oră
    [few] { $count } ore
   *[other] { $count } de ore
} înainte de următoarea încercare.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Listă de blocare: { $lists }
# review: new
bounce-user-unknown = Adresa nu există
# review: new
bounce-user-unknown-why = Serverul destinatar nu are nicio căsuță poștală cu această adresă. Poate fi scrisă greșit sau persoana nu o mai folosește.
# review: new
bounce-user-unknown-do = Verificați cum este scrisă adresa sau cereți persoanei adresa pe care o folosește acum.
# review: new
bounce-invalid-address = Adresa nu este validă
# review: new
bounce-invalid-address-why = Adresa nu este scrisă într-o formă la care se poate trimite e-mail.
# review: new
bounce-invalid-address-do = Căutați greșeli de scriere, de exemplu un spațiu, o literă lipsă sau nimic după @.
# review: new
bounce-mailbox-disabled = Căsuța poștală este închisă
# review: new
bounce-mailbox-disabled-why = Adresa există, dar căsuța ei poștală a fost dezactivată sau nu mai este folosită.
# review: new
bounce-mailbox-disabled-do = Contactați persoana pe altă cale și cereți-i o adresă pe care o folosește acum.
# review: new
bounce-mailbox-full = Căsuța poștală este plină
# review: new
bounce-mailbox-full-why = Căsuța poștală a destinatarului nu mai are loc pentru mesaje noi.
# review: new
bounce-mailbox-full-do = Trimiteți-l din nou peste câteva zile sau anunțați persoana pe altă cale. Atașările mari sunt refuzate primele.
# review: new
bounce-spam-blocked = Refuzat ca spam
# review: new
bounce-spam-blocked-why = Serverul destinatar a considerat mesajul spam.
# review: new
bounce-spam-blocked-do = Trimiteți-l din nou fără ce pare spam, de exemplu multe linkuri, linkuri scurtate sau o atașare mare. Dacă se repetă, întrebați furnizorul de e-mail.
# review: new
bounce-virus-detected = Refuzat din cauza unui virus
# review: new
bounce-virus-detected-why = Serverul destinatar a găsit un virus sau alt conținut periculos în mesaj sau în atașările lui.
# review: new
bounce-virus-detected-do = Verificați atașările cu un antivirus. Unele servere refuză orice program sau arhivă, așa că partajați astfel de fișiere printr-un link.
# review: new
bounce-ip-blocklisted = Serverul dvs. de e-mail este pe o listă de blocare
# review: new
bounce-ip-blocklisted-why = Serverul destinatar refuză e-mailurile de la serverul care l-a trimis pe al dvs., pentru că adresa acelui server este pe o listă de blocare.
# review: new
bounce-ip-blocklisted-do = Problema nu este mesajul. Redirecționați această notificare furnizorului de e-mail și cereți-i să scoată serverul de pe listă.
# review: new
bounce-domain-blocklisted = Un domeniu este pe o listă de blocare
# review: new
bounce-domain-blocklisted-why = Serverul destinatar refuză mesajul pentru că domeniul adresei dvs. sau un domeniu din linkurile mesajului este pe o listă de blocare.
# review: new
bounce-domain-blocklisted-do = Dacă mesajul are linkuri, încercați fără ele. Altfel, redirecționați această notificare celui care administrează e-mailul domeniului dvs.
# review: new
bounce-policy-blocked = Refuzat de regulile serverului destinatar
# review: new
bounce-policy-blocked-why = Regulile serverului destinatar nu lasă să treacă acest mesaj, de exemplu din cauza mărimii, a atașărilor sau a expeditorului.
# review: new
bounce-policy-blocked-do = Cuvintele serverului de sub Detalii spun adesea motivul. Întrebați destinatarul dacă poate accepta astfel de mesaje.
# review: new
bounce-geo-blocked = Refuzat din cauza locului de proveniență
# review: new
bounce-geo-blocked-why = Serverul destinatar nu acceptă e-mail din țara sau rețeaua în care se află serverul dvs. de e-mail.
# review: new
bounce-geo-blocked-do = Contactați persoana pe altă cale sau întrebați furnizorul de e-mail.
# review: new
bounce-relay-denied = Serverul nu l-a transmis mai departe
# review: new
bounce-relay-denied-why = Un server a refuzat să livreze mai departe mesajul, adesea pentru că a fost trimis fără conectare sau printr-un server care nu se ocupă de acest destinatar.
# review: new
bounce-relay-denied-do = Verificați serverul de ieșire al contului în Fișier > Conturi și dacă acesta se conectează.
# review: new
bounce-auth-failure = Adresa dvs. de expeditor nu a putut fi verificată
# review: new
bounce-auth-failure-why = Serverul destinatar nu a putut confirma că mesajul vine într-adevăr de la domeniul dvs. (SPF, DKIM sau DMARC).
# review: new
bounce-auth-failure-do = Redirecționați această notificare celui care administrează e-mailul domeniului dvs.: setările lui trebuie corectate. Între timp poate ajuta trimiterea prin serverul furnizorului dvs.
# review: new
bounce-rate-limited = Prea multe mesaje deodată
# review: new
bounce-rate-limited-why = Deocamdată, serverul destinatar acceptă mai puține mesaje de la serverul dvs. de e-mail.
# review: new
bounce-rate-limited-do = Așteptați puțin și trimiteți-l din nou. Când scrieți multor persoane, trimiteți la mai puține deodată.
# review: new
bounce-greylisting = Reținut pentru scurt timp
# review: new
bounce-greylisting-why = Serverul destinatar le cere expeditorilor necunoscuți să încerce din nou puțin mai târziu, o verificare obișnuită împotriva spamului.
# review: new
bounce-greylisting-do = Nimic. Serverele de e-mail încearcă din nou singure, iar mesajul este livrat de obicei în decurs de o oră.
# review: new
bounce-server-error = Serverul destinatar a avut o problemă
# review: new
bounce-server-error-why = Serverul destinatar nu a putut fi contactat sau nu a putut prelua mesajul din cauza unei probleme proprii.
# review: new
bounce-server-error-do = Trimiteți-l din nou mai târziu. Dacă tot nu reușește, verificați partea adresei de după @ pentru greșeli de scriere.
# review: new
bounce-unknown = Nelivrat
# review: new
bounce-unknown-why = Notificarea nu spune clar de ce.
# review: new
bounce-unknown-do = Cuvintele serverului de sub Detalii pot spune mai mult. Dacă nu ajută, redirecționați această notificare furnizorului de e-mail.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] 1 mesaj selectat
    [few] { $count } mesaje selectate
   *[other] { $count } de mesaje selectate
}
# review: new
selection-unread = Necitite: { $count }
# review: new
selection-flagged = Semnalizate: { $count }
# review: new
delete-for-good-one = Acest mesaj va fi șters definitiv. Îl ștergeți?
# review: new
delete-for-good-all = { $count ->
    [few] Aceste { $count } mesaje vor fi șterse definitiv. Le ștergeți?
   *[other] Aceste { $count } de mesaje vor fi șterse definitiv. Le ștergeți?
}
# review: new
delete-for-good-some = { $total ->
    [few] Dintre cele { $total } mesaje, { $count } vor fi șterse definitiv. Ștergeți mesajele?
   *[other] Dintre cele { $total } de mesaje, { $count } vor fi șterse definitiv. Ștergeți mesajele?
}
# review: new
done-read = { $count ->
    [one] { $messages } marcat ca citit
   *[other] { $messages } marcate ca citite
}
# review: new
done-unread = { $count ->
    [one] { $messages } marcat ca necitit
   *[other] { $messages } marcate ca necitite
}
# review: new
done-flagged = { $count ->
    [one] { $messages } semnalizat
   *[other] { $messages } semnalizate
}
# review: new
done-unflagged = S-a scos semnalizarea de la { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] { $messages } șters definitiv
   *[other] { $messages } șterse definitiv
}
# review: new
done-archived = { $count ->
    [one] { $messages } arhivat
   *[other] { $messages } arhivate
}
# review: new
done-moved = { $count ->
    [one] { $messages } mutat în { $folder }
   *[other] { $messages } mutate în { $folder }
}
# review: new
done-copied = { $count ->
    [one] { $messages } copiat în { $folder }
   *[other] { $messages } copiate în { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Se mută { $messages } în { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Se copiază { $messages } în { $folder }...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } mutat înapoi în { $folder }
   *[other] { $messages } mutate înapoi în { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Conversația este urmărită
    [few] { $count } conversații sunt urmărite
   *[other] { $count } de conversații sunt urmărite
}
# review: new
done-unwatched = { $count ->
    [one] Conversația nu mai este urmărită
    [few] { $count } conversații nu mai sunt urmărite
   *[other] { $count } de conversații nu mai sunt urmărite
}
# review: new
done-ignored = { $count ->
    [one] Conversația este ignorată
    [few] { $count } conversații sunt ignorate
   *[other] { $count } de conversații sunt ignorate
}
# review: new
done-unignored = { $count ->
    [one] Conversația nu mai este ignorată
    [few] { $count } conversații nu mai sunt ignorate
   *[other] { $count } de conversații nu mai sunt ignorate
}
# review: new
their-folders = folderele lor
# review: new
undo-move = Anulare mutare
# review: new
undo-delete = Anulare ștergere
# review: new
undo-archive = Anulare arhivare
# review: new
undo-junk = Anulare marcare ca nedorit
# review: new
undo-not-junk = Anulare marcare ca dorit
# review: new
undo-send = Anulare trimitere
# review: new
nothing-to-undo = Nu există nimic de anulat.
# review: new
messages-gone = Mesajele nu mai sunt acolo.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Acest folder nu poate conține mesaje.
# review: new
not-archived-here = Mesajele din acest folder nu pot fi arhivate.
# review: new
not-emptied-here = Numai Elemente șterse și E-mail nedorit pot fi golite.
# review: new
next-unread-question = Nu mai există mesaje necitite în { $folder }.

    Treceți la { $next }, următorul folder cu mesaje necitite?
# review: new
no-unread-left = Nu mai există mesaje necitite.
# review: new
empty-question = { $count ->
    [one] Goliți { $folder }?

        Mesajul din acest folder se șterge definitiv. Nu mai poate fi recuperat.
   *[other] Goliți { $folder }?

        Cele { $messages } din acest folder se șterg definitiv. Nu mai pot fi recuperate.
}
# review: new
no-junk-folder = Acest cont nu are un folder E-mail nedorit în care să fie mutate mesajele.
# review: new
no-inbox-folder = Acest cont nu are un folder Mesaje primite în care să fie mutate mesajele.
# the status bar after a flag in a colour: "Pentru 2 mesaje s-a pus semnalizarea albastră"
# review: new
done-flagged-color = Pentru { $messages } s-a pus semnalizarea { $color ->
    [red] roșie
    [orange] portocalie
    [yellow] galbenă
    [green] verde
    [blue] albastră
    [purple] violet
   *[gray] gri
}
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Roșu
    [orange] Portocaliu
    [yellow] Galben
    [green] Verde
    [blue] Albastru
    [purple] Violet
   *[gray] Gri
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [one] Mutare mesaj
    [few] Mutare { $count } mesaje
   *[other] Mutare { $count } de mesaje
}
# review: new
move-window-title-copy = { $count ->
    [one] Copiere mesaj
    [few] Copiere { $count } mesaje
   *[other] Copiere { $count } de mesaje
}
# review: new
move-window-prompt-move = { $count ->
    [one] Mutați mesajul selectat în:
    [few] Mutați cele { $count } mesaje selectate în:
   *[other] Mutați cele { $count } de mesaje selectate în:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Copiați mesajul selectat în:
    [few] Copiați cele { $count } mesaje selectate în:
   *[other] Copiați cele { $count } de mesaje selectate în:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Recente
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (curent)
# a folder used last, with its account when there are several: "Arhivă (Serviciu)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Se mută { $done } din { $messages } în { $folder }...
# review: new
transfer-copying = Se copiază { $done } din { $messages } în { $folder }...
# review: new
transfer-another-account = alt cont
# review: new
transfer-folder-gone = folderul de destinație nu mai există
# review: new
transfer-not-on-server = mesajul nu mai este pe server
# review: new
transfer-not-moved = { $count ->
    [one] { $messages } nu a putut fi mutat în alt cont: { $reason }
   *[other] { $messages } nu au putut fi mutate în alt cont: { $reason }
}
# review: new
transfer-not-copied = { $count ->
    [one] { $messages } nu a putut fi copiat în alt cont: { $reason }
   *[other] { $messages } nu au putut fi copiate în alt cont: { $reason }
}
# review: new
transfer-none-moved = Niciun mesaj nu a putut fi mutat
# review: new
transfer-none-copied = Niciun mesaj nu a putut fi copiat

## Messages as files

# review: new
export-not-in-time = mesajul nu a putut fi descărcat la timp
# review: new
export-not-saved = { $failed } din { $messages } nu au putut fi salvate ({ $problems })
# review: new
export-not-attached = mesajele nu au putut fi atașate: { $error }
# the status bar after Save As with several: "3 mesaje salvate în Desktop"
# review: new
saved-to = { $count ->
    [one] { $messages } salvat în { $folder }
   *[other] { $messages } salvate în { $folder }
}
# review: new
download-progress = Se descarcă { $done } din { $total }
# review: new
download-done = S-au descărcat { $size }
# review: new
downloading-messages = { $count ->
   *[other] Se descarcă { $messages }...
}
# the status bar after files are dropped on a folder: "3 mesaje puse în Arhivă"
# review: new
import-put = { $count ->
    [one] { $messages } pus în { $folder }
   *[other] { $messages } puse în { $folder }
}
# review: new
import-not-put = Acestea nu au fost puse în folder:

    { $problems }

## Problems the windows show

# review: new
error-store = stocare locală: { $error }
# review: new
error-not-found = nu a fost găsit
# review: new
error-closed = se închide
# review: new
error-other-account = browserul s-a conectat la { $email }, nu la acest cont
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = serverul nu a acceptat conectarea ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = conexiunea cu serverul nu a reușit ({ $reason })
# review: new
error-in-use = nu poate fi eliminată cât timp conturi se conectează cu ea: { $accounts }
# review: new
error-turned-off = această aplicație de conectare este dezactivată pentru conturile noi
# review: new
error-folder-name = numele folderului trebuie să aibă între 1 și 200 de caractere și nu poate conține caractere de control
# review: new
error-folder-separator = pe acest server, numele unui folder nu poate conține „{ $separator }”
# review: new
error-folder-special = Mesaje primite și folderele speciale nu pot fi redenumite sau șterse
# review: new
error-no-recipients = mesajul nu are destinatari
# review: new
error-bad-address = „{ $address }” nu este o adresă de e-mail
# review: new
error-not-own-address = { $address } nu este una dintre adresele de expeditor ale acestui cont. Adăugați-o la „Alte adrese de la care trimiteți” în proprietățile contului.
# review: new
rule-query-refused = Regulile nu pot filtra după folder sau dată ({ $words }).
# review: new
rule-no-query = Introduceți criterii de căutare pentru mesajele primite.
# review: new
rule-no-action = Alegeți cel puțin o acțiune pentru regulă.
# review: new
error-attachment = { $path } nu a putut fi citit: { $error }
# review: new
error-no-drafts = contul nu are un folder Schițe în care să fie salvat mesajul
# review: new
error-draft-attachment = o atașare a schiței nu a putut fi păstrată: { $error }
# review: new
error-password-not-saved = parola nu a putut fi salvată pentru următoarea pornire: { $error }
# review: new
error-sign-in-not-saved = noile date de conectare nu au putut fi salvate pentru următoarea pornire: { $error }
# review: new
error-import-unreadable = { $path } nu poate fi citit: { $error }
# review: new
error-import-too-large = { $path } are mai mult de 50 MB
# review: new
error-import-not-mail = { $path } nu este un mesaj de e-mail
# review: new
error-list-answered = serverul listei de corespondență a răspuns cu starea { $status }
# review: new
error-not-built = mesajul nu a putut fi construit
# review: new
error-outbox-waits = { $count ->
    [one] mesajul așteaptă în Mesaje de trimis și pleacă la următoarea Trimitere/primire
    [few] { $count } mesaje așteaptă în Mesaje de trimis și pleacă la următoarea Trimitere/primire
   *[other] { $count } de mesaje așteaptă în Mesaje de trimis și pleacă la următoarea Trimitere/primire
}
# review: new
error-draft-not-removed = schița anterioară a mesajului nu a putut fi eliminată din Schițe: { $reason }
# review: new
error-sent-but = mesajul a fost trimis, dar { $problem }
# review: new
error-sent-still-in-outbox = este încă în Mesaje de trimis: { $error }
# review: new
error-sent-no-copy = nu s-a putut salva nicio copie în Elemente trimise: { $reason }
# review: new
error-no-password = nu există parolă pentru acest cont
# review: new
error-no-sign-in = nu există date de conectare pentru acest cont
# review: new
error-provider-missing = această versiune nu se poate conecta la { $provider }: a fost eliminată aplicația ei de conectare?
# review: new
error-provider-servers = serverele acestui cont nu se potrivesc cu serverele aplicației sale de conectare
# review: new
error-app-scopes = { $reason }. Serverul de e-mail nu a acceptat tokenul aplicației de conectare: verificați dacă permisiunile (scopes) aplicației dau acces la e-mail
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google nu a verificat încă Inbox Classic, așa că permite conectarea prin el doar utilizatorilor de test. Folosiți propria aplicație de conectare Google sau o parolă de aplicație, ori activați-o în Aplicații de conectare (Fișier > Conturi) dacă sunteți utilizator de test.
# review: new
sign-in-off-other = A fost dezactivată în Aplicații de conectare (Fișier > Conturi), unde poate fi activată din nou.
# review: new
sign-in-app-no-name = aplicația de conectare are nevoie de un nume
# review: new
sign-in-app-no-client = lipsește ID-ul client
# review: new
sign-in-app-no-scopes = aplicația de conectare are nevoie de permisiunile (scopes) care dau acces la e-mail
# review: new
sign-in-app-bad-host = adresa serverului { $server } lipsește sau nu este un nume de gazdă valid
# review: new
sign-in-app-plain = serverul { $server } trebuie să folosească SSL/TLS sau STARTTLS
# review: new
sign-in-app-not-checked = emitentul nu a fost verificat încă
# review: new
sign-in-app-issuer-changed = emitentul s-a schimbat: introduceți din nou secretul client sau eliminați-l
# review: new
sign-in-register-google = În Google Cloud Console, creați un client OAuth de tipul Desktop app, cu permisiunea https://mail.google.com/ pe ecranul de consimțământ. Cât timp aplicația este în testare, doar utilizatorii ei de test se pot conecta.
# review: new
sign-in-register-microsoft = În Microsoft Entra, înregistrați o aplicație cu platforma Mobile and desktop applications, URI-ul de redirecționare http://localhost și fluxurile de client public permise, plus permisiunile delegate IMAP.AccessAsUser.All, SMTP.Send și offline_access. Doar pentru organizația dvs., folosiți ca emitent https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Înregistrați un client nativ (public) cu URI-ul de redirecționare de mai jos; furnizorul trebuie să permită orice port pe el (RFC 8252). Adăugați permisiunea cu care furnizorul dă acces la e-mail.

## Calendar invitations

# review: new
repeats = Se repetă
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [one] În fiecare zi
        [few] La fiecare { $interval } zile
       *[other] La fiecare { $interval } de zile
    }
    [week] { $interval ->
        [one] În fiecare săptămână
        [few] La fiecare { $interval } săptămâni
       *[other] La fiecare { $interval } de săptămâni
    }
    [month] { $interval ->
        [one] În fiecare lună
        [few] La fiecare { $interval } luni
       *[other] La fiecare { $interval } de luni
    }
   *[year] { $interval ->
        [one] În fiecare an
        [few] La fiecare { $interval } ani
       *[other] La fiecare { $interval } de ani
    }
}
# "În fiecare săptămână: luni, miercuri"
# review: new
repeats-on = { $repeats }: { $days }
# "În fiecare săptămână, de 10 ori"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, o dată
    [few] { $repeats }, de { $count } ori
   *[other] { $repeats }, de { $count } de ori
}
# review: new
day-monday = luni
# review: new
day-tuesday = marți
# review: new
day-wednesday = miercuri
# review: new
day-thursday = joi
# review: new
day-friday = vineri
# review: new
day-saturday = sâmbătă
# review: new
day-sunday = duminică

## AI agents

# review: new
agent-level-read = Citirea e-mailului: foldere, lista de mesaje, căutare și mesaje
# review: new
agent-level-organize = Organizarea e-mailului: stare de citire, semnalizări, nedorite, mutare, arhivare, foldere noi, ștergere în Elemente șterse și dezabonare de la liste de corespondență după ce sunteți de acord
# review: new
agent-level-drafts = Scrierea de schițe pe care le trimiteți dvs.
# review: new
agent-level-send = Trimiterea de e-mail, fiecare mesaj doar după ce spuneți da
# review: new
agent-connect-title = { $program } vrea să vă folosească e-mailul
# review: new
agent-connect-detail = Un agent IA a cerut să lucreze cu Inbox Classic. Alegeți ce poate face și ce conturi poate vedea; puteți schimba asta mai târziu în Instrumente > Agenți IA.

    Agenții citesc e-mailuri scrise de alte persoane, iar un mesaj poate încerca să îi păcălească. Inbox Classic vă întreabă întotdeauna înainte ca un agent să trimită ceva.
# review: new
agent-reply-to = Răspuns la „{ $subject }”
# review: new
agent-reply-all-on = Răspuns tuturor la „{ $subject }”
# review: new
agent-forward-of = Redirecționare a „{ $subject }”
# review: new
agent-never-written-one = Nu ați scris niciodată la { $address }.
# review: new
agent-never-written-many = Nu ați scris niciodată la { $count } dintre aceste adrese.
# review: new
agent-send-title = { $program } vrea să trimită acest mesaj
# review: new
agent-send-detail = Verificați destinatarii și conținutul mesajului. După ce confirmați, mesajul așteaptă { $seconds } secunde în Mesaje de trimis, unde îl puteți încă șterge.
# review: new
agent-change-title = Ce poate face { $program }
# review: new
agent-change-allowed = Schimbați ce pot face agenții IA ai acestui program cu e-mailul dvs.
# review: new
agent-change-refused = Ați refuzat accesul acestui program. Permiteți-l pentru a le da din nou agenților lui acces la e-mailul dvs.
# review: new
agent-log-taken-back = { $entry } (anulat)
# review: new
agent-files = Fișiere: { $files }
# review: new
agent-undo-refused = Nu poate fi anulat.
# review: new
agent-undo-refused-why = Nu poate fi anulat: { $reason }.
# review: new
agent-undo-impossible = acest lucru nu poate fi anulat
# review: new
agent-undo-not-in-folder = mesajul nu mai este în acel folder
# review: new
agent-undo-not-arrived = mesajul nu este (încă) în folderul în care a fost mutat
# review: new
agent-undo-sent = mesajul a fost deja trimis
# review: new
agent-original-not-downloaded = mesajul original nu a fost descărcat încă. Deschideți-l mai întâi
# review: new
agent-turned-away = Refuzat
# review: new
agent-can-nothing = Nimic
# review: new
agent-can-read = citire
# review: new
agent-can-organize = organizare
# review: new
agent-can-drafts = scriere de schițe
# review: new
agent-can-send = trimitere cu acordul dvs.
# "Citire, organizare și scriere de schițe"
# review: new
agent-can-list = { $first } și { $last }
# review: new
agent-accounts = { $count ->
    [0] niciun cont
    [one] 1 cont
    [few] { $count } conturi
   *[other] { $count } de conturi
}
# "Citire și organizare; 1 cont"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Acest mesaj nu poate fi citit.
# review: new
agent-encrypted-original = Acest mesaj este criptat: un agent nu poate să îi răspundă sau să îl redirecționeze, deoarece nu poate cripta.
# review: new
agent-encrypted = Acest mesaj este criptat. Doar utilizatorul îl poate citi, în Inbox Classic.
# review: new
list-encrypted = Mesaj criptat
# review: new
agent-log-composed = A deschis „{ $subject }” într-un mesaj nou, pe care să îl terminați dvs.
# review: new
agent-log-refused = Nu ați trimis „{ $subject }”
# review: new
agent-log-sent = A trimis „{ $subject }” către { $to }
# review: new
agent-log-draft = A salvat schița „{ $subject }”
# review: new
agent-log-read = A marcat ca citit „{ $subject }”
# review: new
agent-log-unread = A marcat ca necitit „{ $subject }”
# review: new
agent-log-flagged = A semnalizat „{ $subject }”
# review: new
agent-log-unflagged = A scos semnalizarea de la „{ $subject }”
# review: new
agent-log-deleted = A șters „{ $subject }”
# review: new
agent-log-moved = A mutat „{ $subject }” în { $folder }
# review: new
agent-log-junk = A marcat „{ $subject }” ca nedorit
# review: new
agent-log-not-junk = A marcat „{ $subject }” ca dorit
# review: new
agent-log-archived = A arhivat „{ $subject }”
# review: new
agent-log-folder = A creat folderul „{ $name }”
# review: new
agent-log-unsubscribed = S-a dezabonat de la lista lui „{ $subject }”
# review: new
agent-log-unsubscribe-failed = Dezabonarea de la lista lui „{ $subject }” nu a reușit: { $reason }
# review: new
agent-log-unsubscribe-refused = Nu v-ați dezabonat de la { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [one] { $program } vrea să vă dezaboneze de la o listă de corespondență
    [few] { $program } vrea să vă dezaboneze de la { $count } liste de corespondență
   *[other] { $program } vrea să vă dezaboneze de la { $count } de liste de corespondență
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic cere listei de mai jos să nu vă mai trimită mesaje, prin dezabonarea cu un clic pe care o oferă. Nu se trimite nimic altceva, iar mesajele pe care le aveți rămân unde sunt.
   *[other] Inbox Classic cere fiecărei liste de mai jos să nu vă mai trimită mesaje, prin dezabonarea cu un clic pe care o oferă lista. Nu se trimite nimic altceva, iar mesajele pe care le aveți rămân unde sunt.
}

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
sign-in-no-refresh = furnizorul nu a dat niciun token de reîmprospătare
# review: new
sign-in-no-account = furnizorul nu a spus ce cont s-a conectat
# review: new
sign-in-not-finished = conectarea nu s-a terminat
# review: new
secrets-unavailable = { $store } nu este disponibil
# review: new
secrets-unavailable-why = { $store } nu este disponibil: { $error }
# review: new
secrets-windows = Managerul de acreditări
# review: new
secrets-mac = Portchei
# review: new
secrets-linux = portcheiul sistemului (Secret Service)
# review: new
error-no-such-file = fișierul nu există
# review: new
cards-file-too-big = Acest fișier este prea mare pentru a fi o agendă.
# review: new
ui-sender-added = { $name } a fost adăugat în Agendă.
# review: new
ui-sender-known = { $name } este deja în Agendă.
# review: new
ui-sender-none = Expeditorul acestui mesaj nu are o adresă de e-mail de adăugat.
# review: new
card-name-needed = Contactul nu are nici nume, nici adresă de e-mail.
# a file of Import Address Book that could not be read: "contacts.vcf: fișierul nu există"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Cod de la { $domain }
# review: new
otp-copy = Copiere
# review: new
otp-note = Introduceți-l doar pe o pagină a { $domain }.
# review: new
otp-old = Acest cod a fost trimis cu peste o oră înainte să îl deschideți și probabil a expirat.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } participant
        [few] { $count } participanți
       *[other] { $count } de participanți
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } este codul dvs. pentru { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Validă
# review: new
pgp-key-expires = Validă până la { $date }
# review: new
pgp-key-expired = A expirat pe { $date }
# review: new
pgp-key-revoked = Revocată
# review: new
pgp-key-revoked-why = Revocată: { $reason }
# review: new
pgp-key-not-valid = Nevalidă
# review: new
pgp-key-locked = Nu poate fi folosită: cheia care o protejează nu mai este în { $store }. Importați din nou copia ei de rezervă.
# review: new
pgp-source-own = Creată în Inbox Classic
# review: new
pgp-source-file = Importată dintr-un fișier
# review: new
pgp-source-paste = Lipită
# review: new
pgp-source-attachment = Dintr-un mesaj
# review: new
pgp-source-vcard = Dintr-o carte de vizită
# review: new
pgp-source-wkd = De la furnizorul de e-mail al expeditorului
# review: new
pgp-source-keyserver = De pe keys.openpgp.org
# review: new
pgp-source-autocrypt = Din antetul Autocrypt al unui mesaj
# review: new
pgp-error-no-store = Cheile private sunt protejate de { $store }, care nu poate fi folosit: { $error }
# review: new
pgp-error-wrong-passphrase = Fraza-parolă nu este corectă.
# review: new
pgp-error-not-a-key = Aceasta nu este o cheie OpenPGP.
# review: new
pgp-error-too-large = Cheia este prea mare.
# review: new
pgp-error-unusable = Cheia folosește criptografie veche sau slabă și nu poate fi folosită.
# review: new
pgp-imported-private = { $count ->
    [one] Cheia dvs. privată a fost importată.
    [few] Au fost importate { $count } chei private.
   *[other] Au fost importate { $count } de chei private.
}
# review: new
pgp-imported-public = { $count ->
    [one] A fost importată o cheie.
    [few] Au fost importate { $count } chei.
   *[other] Au fost importate { $count } de chei.
}
# review: new
pgp-imported-pending = Pentru { $addresses } se folosește deja altă cheie: cea nouă așteaptă în contact până când o alegeți.
# review: new
pgp-error-needs-passphrase = Cheia privată este protejată de o frază-parolă. Introduceți-o pentru a importa cheia.
# review: new
pgp-error-mismatch = Cheia privată nu aparține cheii ei publice. Este posibil să fi fost modificată.
# review: new
pgp-file-name-public = { $who } cheie publică.asc
# review: new
pgp-file-name-private = { $who } copie de rezervă cheie privată.asc
# review: new
pgp-pending = Pe { $date } s-a găsit o altă cheie pentru { $address }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Semnat de { $signer }, cheie verificată
# review: new
pgp-part-signed = Semnat de { $signer } (cheie neverificată)
# review: new
pgp-part-other = Semnat de { $signer }, care nu este expeditorul
# review: new
pgp-part-unknown-key = Semnat, dar cheia nu este cunoscută
# review: new
pgp-part-not-signed = Nesemnat
# review: new
pgp-part-not-checked = Semnătură neverificată
# review: new
pgp-part-encrypted = Criptat. { $signature }
# review: new
pgp-part-no-key = Criptat pentru o cheie pe care nu o aveți
# review: new
pgp-part-changed = Partea criptată a fost modificată pe drum și nu este afișată
# review: new
pgp-part-unprotected = Criptat fără protecție împotriva modificărilor, nu este afișat
# review: new
pgp-part-broken = Partea criptată nu poate fi citită
# review: new
pgp-why-mismatch = Semnătura nu se potrivește cu acest text
# review: new
pgp-why-weak-hash = Semnătura folosește { $hash }, care nu mai este sigur
# review: new
pgp-why-key-expired = Semnat după ce cheia a expirat pe { $date }
# review: new
pgp-why-key-revoked = Semnat cu o cheie care a fost revocată
# review: new
pgp-why-not-signing-key = Semnat cu o cheie care nu are voie să semneze
# review: new
pgp-why-from-future = Semnătura este datată în viitor
# review: new
pgp-why-signature-expired = Semnătura a expirat
# review: new
pgp-why-key-not-valid = Semnat cu o cheie care nu este validă
# review: new
pgp-why-not-for-you = Semnat pentru alți destinatari și transmis mai departe către dvs.
pgp-why-not-key-in-use = Semnat cu o altă cheie decât cea folosită pentru { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Imaginile au fost încărcate de pe internet
# review: new
pgp-error-no-own-key = Nu aveți o cheie pentru { $address } cu care să semnați sau să criptați. Creați una în Instrumente > Chei de criptare sau dezactivați Semnare și Criptare.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } nu are o cheie pentru criptare.
   *[other] Acești destinatari nu au o cheie pentru criptare: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Acest mesaj citează sau redirecționează un mesaj criptat, deci poate fi trimis doar criptat. Activați Criptare sau eliminați textul citat.
# review: new
pgp-error-protect = Mesajul nu a putut fi semnat sau criptat: { $reason }
# review: new
pgp-found-keys = S-a găsit cheia pentru { $addresses }.
# review: new
pgp-found-none = Nu s-a găsit nicio cheie pentru { $addresses }. Cereți-le să vă trimită cheia lor publică.
# review: new
pgp-found-no-key = Nu s-a găsit nicio cheie.
# review: new
pgp-find-unavailable = Cheile nu pot fi căutate acum: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org a trimis un link de confirmare la { $addresses }. Cheia dvs. este publicată acolo după ce faceți clic pe el.
# review: new
pgp-publish-done = Cheia dvs. este publicată pe keys.openpgp.org pentru { $addresses }.
# review: new
pgp-publish-failed = Cheia nu a putut fi publicată: { $error }
# review: changed
pgp-keyserver-off = Căutarea cheilor pe keys.openpgp.org este dezactivată în { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Criptat și semnat: doar dvs. și { $addresses } îl puteți citi.
    [few] Criptat și semnat: doar dvs. și cei { $count } destinatari ai săi îl puteți citi.
   *[other] Criptat și semnat: doar dvs. și cei { $count } de destinatari ai săi îl puteți citi.
}
# review: new
pgp-compose-encrypt-ready = Va fi criptat și semnat. Adăugați destinatari ale căror chei le aveți.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } nu are o cheie, deci mesajul nu poate fi criptat încă.
    [few] { $count } destinatari nu au o cheie, deci mesajul nu poate fi criptat încă: { $addresses }.
   *[other] { $count } de destinatari nu au o cheie, deci mesajul nu poate fi criptat încă: { $addresses }.
}
# review: new
pgp-compose-looking = Se caută cheile pentru { $addresses }...
# review: new
pgp-compose-signed = Semnat: destinatarii pot verifica faptul că provine de la dvs. și nu a fost modificat.
# review: new
pgp-compose-reply-clear = Necriptat, deși mesajul la care răspunde sau pe care îl redirecționează era criptat.
# review: new
pgp-compose-encrypted-files = Sunt atașate fișiere ale unui mesaj criptat, deci acest mesaj poate fi trimis doar criptat. Activați Criptare sau eliminați acele fișiere.
# review: new
pgp-compose-sign-tip = Semnați mesajul cu cheia dvs., ca destinatarii să poată verifica faptul că provine de la dvs. și nu a fost modificat
# review: new
pgp-compose-sign-tip-encrypted = Un mesaj criptat este întotdeauna și semnat
# review: new
pgp-compose-encrypt-tip = Criptați mesajul, ca doar dvs. și destinatarii lui să îl poată citi
# review: new
pgp-compose-make-key = Nu aveți încă o cheie pentru { $address }. Creați una acum? Cu ea, mesajele dvs. pot fi semnate și criptate.
# review: new
pgp-compose-key-unusable = Cheia dvs. pentru { $address } nu poate fi folosită ({ $state }). Deschideți Chei de criptare pentru a importa copia ei de rezervă sau pentru a crea o cheie nouă.
# review: new
pgp-compose-encrypt-off-quote = Acest mesaj citează sau redirecționează un mesaj criptat. Fără criptare, nu poate fi trimis până nu eliminați textul citat. Dezactivați totuși criptarea?
# review: new
pgp-compose-encrypt-off-reply = Acest mesaj răspunde la un mesaj criptat sau îl redirecționează. Fără criptare, oricine vă gestionează mesajul pe drum îl poate citi. Dezactivați criptarea?
# review: new
pgp-recipient-verified = Cheie verificată
# review: new
pgp-recipient-found = Cheie neverificată
# review: new
pgp-recipient-own = Cheia dvs.
# review: new
pgp-recipient-looking = Se caută o cheie...
# review: new
pgp-recipient-missing = Nicio cheie
# review: new
pgp-recipient-not-found = Nicio cheie: nu s-a găsit niciuna la { $date }
# review: new
pgp-recipient-unusable = Cheia nu poate fi folosită: { $state }
# review: new
pgp-recipients-intro = Mesajul este criptat pentru cheia fiecărui destinatar și pentru a dvs.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Un destinatar nu are o cheie pentru criptare. Găsiți-i cheia, eliminați-l din acest mesaj sau trimiteți mesajul fără criptare.
    [few] { $count } destinatari nu au o cheie pentru criptare. Găsiți-le cheile, eliminați-i din acest mesaj sau trimiteți mesajul fără criptare.
   *[other] { $count } de destinatari nu au o cheie pentru criptare. Găsiți-le cheile, eliminați-i din acest mesaj sau trimiteți mesajul fără criptare.
}
# review: new
pgp-details-part = Partea { $number }: { $label }
# review: new
pgp-details-signed = Semnat { $when } cu cheia { $key }
# review: new
pgp-details-unknown-key = Semnat cu cheia { $key }, pe care nu o aveți
# review: new
pgp-details-opened = Criptat pentru cheia dvs. { $key }
# review: new
pgp-details-for = Criptat pentru { $keys }
# review: new
pgp-details-plain = Nesemnat și necriptat
# review: new
pgp-bar-parts = Acest mesaj are { $count } părți: { $list }. Fiecare parte arată cum este protejată.
# review: new
pgp-bar-count-verified = Verificate: { $count }
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 semnată sau criptată
    [few] { $count } semnate sau criptate
   *[other] { $count } de semnate sau criptate
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 necesită atenție
    [few] { $count } necesită atenție
   *[other] { $count } de părți necesită atenție
}
# review: new
pgp-bar-count-neutral = Fără semnătură confirmată: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Setări
# review: new
setup-part-preferences = Preferințele ferestrelor
# review: new
setup-part-accounts = Conturi
# review: new
setup-part-sign-in-apps = Aplicații de conectare
# review: new
setup-part-contacts = Contacte și grupuri
# review: new
setup-part-keys = Chei de criptare
# review: new
setup-part-rules = Reguli pentru mesaje
# review: new
setup-part-trusted-senders = Expeditori de încredere
# review: new
setup-holds-settings = { $count ->
    [one] 1 setare
    [few] { $count } setări
   *[other] { $count } de setări
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 preferință
    [few] { $count } preferințe
   *[other] { $count } de preferințe
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 cont
    [few] { $count } conturi
   *[other] { $count } de conturi
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 aplicație de conectare
    [few] { $count } aplicații de conectare
   *[other] { $count } de aplicații de conectare
}
# review: new
setup-holds-built-in = Ce aplicații de conectare integrate sunt activate
# review: new
setup-holds-contacts = { $count ->
    [one] 1 contact
    [few] { $count } contacte
   *[other] { $count } de contacte
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 grup
    [few] { $count } grupuri
   *[other] { $count } de grupuri
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 cheie proprie
    [few] { $count } chei proprii
   *[other] { $count } de chei proprii
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 cheie a unui contact
    [few] { $count } chei ale contactelor
   *[other] { $count } de chei ale contactelor
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 regulă
    [few] { $count } reguli
   *[other] { $count } de reguli
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 expeditor de încredere
    [few] { $count } expeditori de încredere
   *[other] { $count } de expeditori de încredere
}
# review: new
setup-sign-in-password = Parolă
# review: new
setup-account-secret-password = Parola lui este în fișier.
# review: new
setup-account-secret-token = Datele lui de conectare sunt în fișier.
# review: new
setup-account-asks-password = Vă cere parola după import.
# review: new
setup-account-signs-in-again = Vă conectați din nou la el după import.
# review: new
setup-account-here = Este deja configurat aici, așa că este omis.
# review: new
setup-account-no-app = Se conectează cu { $app }, care nu este configurată aici. Importați și aplicațiile de conectare.
# review: new
setup-invalid-address = „{ $address }” nu este o adresă de e-mail.
# review: new
setup-invalid-server = Serverul { $server } nu are un nume sau un port utilizabil.
# review: new
setup-invalid-user = Nu are nume de utilizator.
# review: new
setup-invalid-sign-in = Se conectează într-un mod pe care Inbox Classic nu îl cunoaște.
# review: new
setup-error-empty = Fișierul este gol.
# review: new
setup-error-too-large = Fișierul este prea mare pentru a fi o configurație Inbox Classic.
# review: new
setup-error-not-setup = Acest fișier nu este o configurație Inbox Classic.
# review: new
setup-error-damaged = Fișierul de configurație este deteriorat și nu poate fi citit.
# review: new
setup-error-newer = Această configurație a fost salvată de o versiune mai nouă de Inbox Classic ({ $version }). Actualizați Inbox Classic, apoi importați-o din nou.
# review: new
setup-error-needs-passphrase = Această configurație este protejată de o frază-parolă. Introduceți fraza-parolă cu care a fost salvată.
# review: new
setup-error-wrong-passphrase = Aceasta nu este fraza-parolă cu care a fost salvată configurația.
# review: new
setup-error-changed = Fișierul de configurație a fost modificat sau deteriorat după salvare, așa că nu poate fi importat.
# review: new
setup-error-read = Fișierul de configurație nu a putut fi citit: { $error }
# review: new
setup-error-write = Configurația nu a putut fi salvată: { $error }
# review: new
setup-error-no-parts = Alegeți cel puțin o parte.
# review: new
setup-left-out = { $count ->
    [one] O intrare din { $part } nu poate fi folosită și este omisă.
    [few] { $count } intrări din { $part } nu pot fi folosite și sunt omise.
   *[other] { $count } de intrări din { $part } nu pot fi folosite și sunt omise.
}
# review: new
setup-imported-settings = Setările au fost înlocuite.
# review: new
setup-imported-preferences = Preferințele ferestrelor au fost înlocuite.
# review: new
setup-added-accounts = { $count ->
    [one] S-a adăugat 1 cont.
    [few] S-au adăugat { $count } conturi.
   *[other] S-au adăugat { $count } de conturi.
}
# review: new
setup-skipped-here = { $address } este deja configurat aici, așa că a fost omis.
# review: new
setup-skipped-no-app = { $address } a fost omis: se conectează cu { $app }, care nu este configurată aici.
# review: new
setup-skipped-invalid = { $address } a fost omis: { $reason }
# review: new
setup-asks-password = { $address } vă cere parola când se conectează.
# review: new
setup-signs-in-again = { $address } vă cere să vă conectați din nou când se conectează.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] S-a adăugat 1 aplicație de conectare.
    [few] S-au adăugat { $count } aplicații de conectare.
   *[other] S-au adăugat { $count } de aplicații de conectare.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 aplicație de conectare este deja configurată aici.
    [few] { $count } aplicații de conectare sunt deja configurate aici.
   *[other] { $count } de aplicații de conectare sunt deja configurate aici.
}
# review: new
setup-added-contacts = { $count ->
    [one] S-a adăugat 1 contact în agendă.
    [few] S-au adăugat { $count } contacte în agendă.
   *[other] S-au adăugat { $count } de contacte în agendă.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 contact este deja în agendă.
    [few] { $count } contacte sunt deja în agendă.
   *[other] { $count } de contacte sunt deja în agendă.
}
# review: new
setup-added-groups = { $count ->
    [one] S-a adăugat sau completat 1 grup.
    [few] S-au adăugat sau completat { $count } grupuri.
   *[other] S-au adăugat sau completat { $count } de grupuri.
}
# review: new
setup-added-own-keys = { $count ->
    [one] S-a adăugat 1 cheie proprie.
    [few] S-au adăugat { $count } chei proprii.
   *[other] S-au adăugat { $count } de chei proprii.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] S-a adăugat 1 cheie a unui contact.
    [few] S-au adăugat { $count } chei ale contactelor.
   *[other] S-au adăugat { $count } de chei ale contactelor.
}
# review: new
setup-added-rules = { $count ->
    [one] S-a adăugat 1 regulă pentru mesaje.
    [few] S-au adăugat { $count } reguli pentru mesaje.
   *[other] S-au adăugat { $count } de reguli pentru mesaje.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 regulă pentru mesaje există deja aici.
    [few] { $count } reguli pentru mesaje există deja aici.
   *[other] { $count } de reguli pentru mesaje există deja aici.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 regulă pentru mesaje este pentru un cont care nu este aici, așa că a fost omisă.
    [few] { $count } reguli pentru mesaje sunt pentru conturi care nu sunt aici, așa că au fost omise.
   *[other] { $count } de reguli pentru mesaje sunt pentru conturi care nu sunt aici, așa că au fost omise.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 regulă pentru mesaje mută mesajele într-un folder care apare după sincronizarea contului său.
    [few] { $count } reguli pentru mesaje mută mesajele în foldere care apar după sincronizarea conturilor lor.
   *[other] { $count } de reguli pentru mesaje mută mesajele în foldere care apar după sincronizarea conturilor lor.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] S-a adăugat 1 expeditor de încredere.
    [few] S-au adăugat { $count } expeditori de încredere.
   *[other] S-au adăugat { $count } de expeditori de încredere.
}
# review: new
setup-nothing = Nu s-a importat nimic.
# review: new
setup-account-servers = { $imap } și { $smtp } ({ $signin })
# review: new
setup-file-name = Setări și conturi Inbox Classic
# review: new
setup-skipped-unreachable = { $name } a fost omis: serviciul lui de conectare nu a putut fi contactat. Adăugați-l din nou în Aplicații de conectare.
# review: new
attachment-runs-programs = „{ $name }” poate rula programe, de aceea Inbox Classic nu îl deschide. Salvați-l, apoi deschideți-l dvs. dacă aveți încredere în sursa lui.
# review: new
attachment-decrypted-note = Această atașare provine dintr-un mesaj criptat. Pentru a o deschide, Inbox Classic o stochează decriptată pe acest computer, într-un folder al dvs. pe care Inbox Classic îl golește după o zi.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Serverul nu a mutat { $messages } în { $folder }, așa că este din nou în { $from }: { $reason }
   *[other] Serverul nu a mutat { $messages } în { $folder }, așa că sunt din nou în { $from }: { $reason }
}
undone-delete = { $count ->
    [one] Serverul nu a șters { $messages }, așa că este din nou în { $from }: { $reason }
   *[other] Serverul nu a șters { $messages }, așa că sunt din nou în { $from }: { $reason }
}
undone-archive = { $count ->
    [one] Serverul nu a arhivat { $messages }, așa că este din nou în { $from }: { $reason }
   *[other] Serverul nu a arhivat { $messages }, așa că sunt din nou în { $from }: { $reason }
}
undone-read = { $count ->
    [one] Serverul nu a marcat { $messages } ca citit, așa că apare din nou ca necitit: { $reason }
   *[other] Serverul nu a marcat { $messages } ca citite, așa că apar din nou ca necitite: { $reason }
}
undone-unread = { $count ->
    [one] Serverul nu a marcat { $messages } ca necitit, așa că apare din nou ca citit: { $reason }
   *[other] Serverul nu a marcat { $messages } ca necitite, așa că apar din nou ca citite: { $reason }
}
undone-flags = { $count ->
    [one] Serverul nu a schimbat semnalizările pentru { $messages }, așa că modificarea a fost anulată: { $reason }
   *[other] Serverul nu a schimbat semnalizările pentru { $messages }, așa că modificarea a fost anulată: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Afișează fișierele PDF în mesaje
# review: new
preview-pdf-off = Fișierele PDF nu sunt afișate în mesaje.
# review: new
preview-pdf-off-crashed = Un fișier PDF a închis Inbox Classic în timp ce era afișat, așa că fișierele PDF nu mai sunt afișate în mesaje. Imaginile sunt afișate în continuare. Pentru a afișa din nou fișierele PDF, activați { $option } în opțiunile de citire.
