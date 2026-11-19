# Română. Ciornă, așteaptă revizuirea unui vorbitor nativ (vezi core/locales/GLOSSARY.md).
# Plurals: [one] 1, [few] 0 and 2 to 19 (and 101 to 119...), *[other] 20 and up, which takes "de": "20 de mesaje".

## Counts and sizes

messages = { $count ->
    [one] 1 mesaj
    [few] { $count } mesaje
   *[other] { $count } de mesaje
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 octet
    [few] { $count } octeți
   *[other] { $count } de octeți
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Dezactivat
send-delay-seconds = { $count ->
    [one] 1 secundă
    [few] { $count } secunde
   *[other] { $count } de secunde
}
# the status bar: "12 mesaje, necitite: 3"
list-counts = { $messages }, necitite: { $unread }
list-counts-selected = { $messages }, necitite: { $unread }, selectate: { $selected }
# the status bar while searching
list-counts-found = Găsite: { $found }, necitite: { $unread }
list-counts-found-selected = Găsite: { $found }, necitite: { $unread }, selectate: { $selected }
list-counts-none = Nu s-au găsit mesaje

## Special folders, as Outlook names them

folder-inbox = Mesaje primite
folder-sent = Elemente trimise
folder-deleted = Elemente șterse
folder-drafts = Schițe
folder-junk = E-mail nedorit
folder-archive = Arhivă

## The reading pane

reader-no-message = Nu este selectat niciun mesaj.
reader-downloading = Se descarcă mesajul…
reader-downloading-detail = Mesajul va apărea aici după ce se termină descărcarea.
reader-downloading-size = Mesajul are { $size }. Va apărea aici după ce este descărcat.
reader-failed = Mesajul nu a putut fi descărcat
reader-failed-network = Conexiunea cu serverul de e-mail nu a putut fi stabilită sau a fost întreruptă ({ $reason }).
reader-failed-sign-in = Serverul de e-mail nu a acceptat conectarea ({ $reason }). Verificați parola sau conectați-vă din nou din setările contului.
reader-failed-security = Conexiunea cu serverul de e-mail nu a putut fi securizată ({ $reason }).
reader-failed-other = Serverul de e-mail a răspuns: { $reason }.
reader-retry-note = Se va încerca din nou descărcarea după reconectarea contului.
reader-unreadable = Acest mesaj nu poate fi afișat: { $error }
message-source-title = Sursa mesajului: { $subject }
message-source-untitled = Sursa mesajului

## Printing a message, and the header of a message quoted in a reply or forward

header-from = De la
header-date = Dată
header-to = Către
header-cc = Cc
header-sent = Trimis
header-subject = Subiect
header-security = Securitate
header-part = Partea { $number }
quote-original = ----- Mesaj original -----
fold-show-earlier = Afișați mesajele anterioare

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Mesajul dvs. nu a fost livrat
bounce-delayed = Mesajul dvs. nu a fost livrat încă
bounce-delayed-note = Serverul dvs. de e-mail încă încearcă să îl livreze. Nu trebuie să îl trimiteți din nou.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Afișați mesajul returnat
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Afișați mesajul întârziat
bounce-what-to-do = Ce puteți face:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Deocamdată nu trebuie să faceți nimic. Dacă mesajul nu poate fi livrat, veți primi o altă notificare.
bounce-delayed-row-do = Deocamdată nu trebuie să faceți nimic. Serverul dvs. de e-mail încă încearcă să livreze mesajul. Veți primi o altă notificare dacă nu reușește.
# folds the receiving server's own words
bounce-details = Detalii
# a recipient the notice does not name
bounce-someone = Un destinatar
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Stare: { $status }
bounce-reported-by = Raportat de: { $server }
bounce-retry-minutes = Serverul destinatar a cerut o pauză de { $count ->
    [one] un minut
    [few] { $count } minute
   *[other] { $count } de minute
} înainte de următoarea încercare.
bounce-retry-hours = Serverul destinatar a cerut o pauză de { $count ->
    [one] o oră
    [few] { $count } ore
   *[other] { $count } de ore
} înainte de următoarea încercare.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Listă de blocare: { $lists }
bounce-user-unknown = Adresa nu există
bounce-user-unknown-why = Serverul destinatar nu are nicio căsuță poștală cu această adresă. Poate fi scrisă greșit sau persoana nu o mai folosește.
bounce-user-unknown-do = Verificați cum este scrisă adresa sau cereți persoanei adresa pe care o folosește acum.
bounce-invalid-address = Adresa nu este validă
bounce-invalid-address-why = Adresa nu are un format valid pentru trimiterea mesajelor.
bounce-invalid-address-do = Căutați greșeli de scriere, de exemplu un spațiu, o literă lipsă sau nimic după @.
bounce-mailbox-disabled = Căsuța poștală este închisă
bounce-mailbox-disabled-why = Adresa există, dar căsuța ei poștală a fost dezactivată sau nu mai este folosită.
bounce-mailbox-disabled-do = Contactați persoana pe altă cale și cereți-i o adresă pe care o folosește acum.
bounce-mailbox-full = Căsuța poștală este plină
bounce-mailbox-full-why = Căsuța poștală a destinatarului nu mai are loc pentru mesaje noi.
bounce-mailbox-full-do = Încercați să retrimiteți mesajul peste câteva zile sau anunțați destinatarul pe altă cale.
bounce-spam-blocked = Refuzat ca spam
bounce-spam-blocked-why = Serverul destinatar a considerat mesajul spam.
bounce-spam-blocked-do = Încercați să retrimiteți mesajul fără elemente care pot părea spam, cum ar fi multe linkuri, linkuri scurtate sau atașări mari. Dacă problema persistă, contactați furnizorul de e-mail.
bounce-virus-detected = Refuzat din cauza unui virus
bounce-virus-detected-why = Serverul destinatar a raportat un virus sau alt conținut periculos în mesaj ori în atașările lui.
bounce-virus-detected-do = Verificați atașările cu un antivirus. Unele servere refuză orice program sau arhivă, așa că partajați astfel de fișiere printr-un link.
bounce-ip-blocklisted = Serverul dvs. de e-mail este pe o listă de blocare
bounce-ip-blocklisted-why = Serverul destinatar refuză mesajele trimise de serverul dvs. de e-mail deoarece adresa IP a acestuia se află pe o listă de blocare.
bounce-ip-blocklisted-do = Problema nu este mesajul. Redirecționați această notificare furnizorului de e-mail și cereți-i să scoată serverul de pe listă.
bounce-domain-blocklisted = Un domeniu este pe o listă de blocare
bounce-domain-blocklisted-why = Serverul destinatar refuză mesajul pentru că domeniul adresei dvs. sau un domeniu din linkurile mesajului este pe o listă de blocare.
bounce-domain-blocklisted-do = Dacă mesajul are linkuri, încercați fără ele. Altfel, redirecționați această notificare celui care administrează e-mailul domeniului dvs.
bounce-policy-blocked = Refuzat de regulile serverului destinatar
bounce-policy-blocked-why = Regulile serverului destinatar nu permit primirea acestui mesaj, de exemplu din cauza dimensiunii, a atașărilor sau a expeditorului.
bounce-policy-blocked-do = Răspunsul serverului din secțiunea „Detalii” indică adesea motivul. Întrebați destinatarul dacă poate primi astfel de mesaje.
bounce-geo-blocked = Refuzat din cauza locului de proveniență
bounce-geo-blocked-why = Serverul destinatar nu acceptă e-mail din țara sau rețeaua în care se află serverul dvs. de e-mail.
bounce-geo-blocked-do = Contactați persoana pe altă cale sau întrebați furnizorul de e-mail.
bounce-relay-denied = Serverul nu l-a transmis mai departe
bounce-relay-denied-why = Un server a refuzat să transmită mai departe mesajul, adesea pentru că a fost trimis fără autentificare sau printr-un server care nu deservește acest destinatar.
bounce-relay-denied-do = În setările contului, verificați serverul de trimitere și datele folosite pentru autentificare.
bounce-auth-failure = Adresa dvs. de expeditor nu a putut fi verificată
bounce-auth-failure-why = Serverul destinatar nu a putut confirma că mesajul vine într-adevăr de la domeniul dvs. (SPF, DKIM sau DMARC).
bounce-auth-failure-do = Redirecționați această notificare celui care administrează e-mailul domeniului dvs.: setările lui trebuie corectate. Între timp poate ajuta trimiterea prin serverul furnizorului dvs.
bounce-rate-limited = Prea multe mesaje deodată
bounce-rate-limited-why = Deocamdată, serverul destinatar acceptă mai puține mesaje de la serverul dvs. de e-mail.
bounce-rate-limited-do = Așteptați puțin și trimiteți-l din nou. Când scrieți multor persoane, trimiteți la mai puține deodată.
bounce-greylisting = Reținut pentru scurt timp
bounce-greylisting-why = Serverul destinatar le cere expeditorilor necunoscuți să încerce din nou puțin mai târziu, o verificare obișnuită împotriva spamului.
bounce-greylisting-do = Dacă livrarea este doar întârziată, serverul de trimitere poate încerca din nou. Dacă notificarea anunță un eșec definitiv, încercați să retrimiteți mesajul mai târziu.
bounce-server-error = Serverul destinatar a avut o problemă
bounce-server-error-why = Serverul destinatar nu a putut fi contactat sau nu a putut prelua mesajul din cauza unei probleme proprii.
bounce-server-error-do = Trimiteți-l din nou mai târziu. Dacă tot nu reușește, verificați partea adresei de după @ pentru greșeli de scriere.
bounce-unknown = Nelivrat
bounce-unknown-why = Notificarea nu precizează motivul.
bounce-unknown-do = Răspunsul serverului din secțiunea „Detalii” poate oferi mai multe informații. Dacă nu vă ajută, redirecționați această notificare furnizorului de e-mail.

## Several messages selected

selection-title = { $count ->
    [one] 1 mesaj selectat
    [few] { $count } mesaje selectate
   *[other] { $count } de mesaje selectate
}
selection-unread = Necitite: { $count }
selection-flagged = Semnalizate: { $count }
delete-for-good-one = Acest mesaj va fi șters definitiv. Îl ștergeți?
delete-for-good-all = { $count ->
    [few] Aceste { $count } mesaje vor fi șterse definitiv. Le ștergeți?
   *[other] Aceste { $count } de mesaje vor fi șterse definitiv. Le ștergeți?
}
delete-for-good-some = { $count ->
    [one] Un mesaj din selecție va fi șters definitiv.
    [few] { $count } mesaje din selecție vor fi șterse definitiv.
   *[other] { $count } de mesaje din selecție vor fi șterse definitiv.
} Ștergeți mesajele selectate (în total: { $total })?
done-read = { $count ->
    [one] { $messages } marcat ca citit
   *[other] { $messages } marcate ca citite
}
done-unread = { $count ->
    [one] { $messages } marcat ca necitit
   *[other] { $messages } marcate ca necitite
}
done-flagged = { $count ->
    [one] { $messages } semnalizat
   *[other] { $messages } semnalizate
}
done-unflagged = Semnalizarea a fost eliminată pentru { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } șters definitiv
   *[other] { $messages } șterse definitiv
}
done-archived = { $count ->
    [one] { $messages } arhivat
   *[other] { $messages } arhivate
}
done-moved = { $count ->
    [one] { $messages } mutat în { $folder }
   *[other] { $messages } mutate în { $folder }
}
done-copied = { $count ->
    [one] { $messages } copiat în { $folder }
   *[other] { $messages } copiate în { $folder }
}
done-moving = { $count ->
   *[other] Se mută { $messages } în { $folder }...
}
done-copying = { $count ->
   *[other] Se copiază { $messages } în { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } mutat înapoi în { $folder }
   *[other] { $messages } mutate înapoi în { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Conversația este urmărită
    [few] { $count } conversații sunt urmărite
   *[other] { $count } de conversații sunt urmărite
}
done-unwatched = { $count ->
    [one] Conversația nu mai este urmărită
    [few] { $count } conversații nu mai sunt urmărite
   *[other] { $count } de conversații nu mai sunt urmărite
}
done-ignored = { $count ->
    [one] Conversația este ignorată
    [few] { $count } conversații sunt ignorate
   *[other] { $count } de conversații sunt ignorate
}
done-unignored = { $count ->
    [one] Conversația nu mai este ignorată
    [few] { $count } conversații nu mai sunt ignorate
   *[other] { $count } de conversații nu mai sunt ignorate
}
their-folders = folderele lor
undo-move = Anulare mutare
undo-delete = Anulare ștergere
undo-archive = Anulare arhivare
undo-junk = Anulare marcare ca nedorit
undo-not-junk = Restabilire marcaj de e-mail nedorit
undo-send = Anulare trimitere
nothing-to-undo = Nu există nimic de anulat.
messages-gone = Mesajele nu mai sunt acolo.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Acest folder nu poate conține mesaje.
not-archived-here = Mesajele din acest folder nu pot fi arhivate.
not-emptied-here = Numai folderele „Elemente șterse” și „E-mail nedorit” pot fi golite.
next-unread-question = Nu mai există mesaje necitite în „{ $folder }”.

    Treceți la „{ $next }”, următorul folder cu mesaje necitite?
no-unread-left = Nu mai există mesaje necitite.
empty-question = { $count ->
    [one] Goliți { $folder }?

        Mesajul din acest folder se șterge definitiv. Nu mai poate fi recuperat.
   *[other] Goliți { $folder }?

        Cele { $messages } din acest folder se șterg definitiv. Nu mai pot fi recuperate.
}
no-junk-folder = Acest cont nu are un folder „E-mail nedorit” în care să fie mutate mesajele.
no-inbox-folder = Acest cont nu are un folder „Mesaje primite” în care să fie mutate mesajele.
# the status bar after a flag in a colour: "Pentru 2 mesaje s-a pus semnalizarea albastră"
done-flagged-color = Pentru { $messages } s-a aplicat semnalizarea { $color ->
    [red] roșie
    [orange] portocalie
    [yellow] galbenă
    [green] verde
    [blue] albastră
    [purple] violetă
   *[gray] cenușie
}
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Roșu
    [orange] Portocaliu
    [yellow] Galben
    [green] Verde
    [blue] Albastru
    [purple] Violet
   *[gray] Cenușiu
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Mutare mesaj
    [few] Mutare { $count } mesaje
   *[other] Mutare { $count } de mesaje
}
move-window-title-copy = { $count ->
    [one] Copiere mesaj
    [few] Copiere { $count } mesaje
   *[other] Copiere { $count } de mesaje
}
move-window-prompt-move = { $count ->
    [one] Mutați mesajul selectat în:
    [few] Mutați cele { $count } mesaje selectate în:
   *[other] Mutați cele { $count } de mesaje selectate în:
}
move-window-prompt-copy = { $count ->
    [one] Copiați mesajul selectat în:
    [few] Copiați cele { $count } mesaje selectate în:
   *[other] Copiați cele { $count } de mesaje selectate în:
}
# the folders used last, over the folder tree
targets-recent = Recente
# the folder the messages are in, which can not be chosen
target-current = { $folder } (curent)
# a folder used last, with its account when there are several: "Arhivă (Serviciu)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Se mută { $done } din { $messages } în { $folder }...
transfer-copying = Se copiază { $done } din { $messages } în { $folder }...
transfer-another-account = alt cont
transfer-folder-gone = folderul de destinație nu mai există
transfer-not-on-server = mesajul nu mai este pe server
transfer-not-moved = { $count ->
    [one] { $messages } nu a putut fi mutat în alt cont: { $reason }
   *[other] { $messages } nu au putut fi mutate în alt cont: { $reason }
}
transfer-not-copied = { $count ->
    [one] { $messages } nu a putut fi copiat în alt cont: { $reason }
   *[other] { $messages } nu au putut fi copiate în alt cont: { $reason }
}
transfer-none-moved = Niciun mesaj nu a putut fi mutat
transfer-none-copied = Niciun mesaj nu a putut fi copiat

## Messages as files

export-not-in-time = mesajul nu a putut fi descărcat la timp
export-not-saved = Salvare nereușită pentru { $failed } din { $messages } ({ $problems })
export-not-attached = mesajele nu au putut fi atașate: { $error }
# the status bar after Save As with several: "3 mesaje salvate în Desktop"
saved-to = { $count ->
    [one] { $messages } salvat în { $folder }
   *[other] { $messages } salvate în { $folder }
}
download-progress = Se descarcă { $done } din { $total }
download-done = Descărcat: { $size }
downloading-messages = { $count ->
   *[other] Se descarcă { $messages }...
}
# the status bar after files are dropped on a folder: "3 mesaje puse în Arhivă"
import-put = { $count ->
    [one] Import în așteptare în { $folder }: { $messages }
   *[other] Import în așteptare în { $folder }: { $messages }
}
import-not-put = Următoarele mesaje nu au fost importate în folder:

    { $problems }

## Problems the windows show

error-store = baza de date locală: { $error }
error-not-found = elementul nu a fost găsit
error-closed = aplicația se închide
error-other-account = browserul s-a conectat la { $email }, nu la acest cont
# a password or sign-in the mail server refused, with the server's words
failure-authentication = serverul nu a acceptat conectarea ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = conexiunea cu serverul nu a putut fi stabilită sau a fost întreruptă ({ $reason })
error-in-use = aplicația nu poate fi eliminată deoarece este folosită de următoarele conturi: { $accounts }
error-turned-off = această aplicație de conectare este dezactivată pentru conturile noi
error-folder-name = numele folderului trebuie să aibă între 1 și 200 de caractere și nu poate conține caractere de control
error-folder-separator = pe acest server, numele unui folder nu poate conține „{ $separator }”
error-folder-special = folderul „Mesaje primite” și celelalte foldere speciale nu pot fi redenumite sau șterse
error-no-recipients = mesajul nu are destinatari
error-bad-address = „{ $address }” nu este o adresă de e-mail
error-not-own-address = { $address } nu este una dintre adresele de expeditor ale acestui cont. Adăugați-o la „Alte adrese de la care trimiteți” în proprietățile contului.
rule-query-refused = Regulile nu pot filtra după folder sau dată ({ $words }).
rule-no-query = Introduceți criterii de căutare pentru mesajele primite.
rule-no-action = Alegeți cel puțin o acțiune pentru regulă.
error-attachment = fișierul „{ $path }” nu a putut fi citit: { $error }
error-no-drafts = contul nu are un folder „Schițe” în care să fie salvat mesajul
error-draft-attachment = o atașare a schiței nu a putut fi păstrată: { $error }
error-password-not-saved = parola nu a putut fi salvată pentru următoarea pornire: { $error }
error-sign-in-not-saved = noile date de conectare nu au putut fi salvate pentru următoarea pornire: { $error }
error-import-unreadable = fișierul „{ $path }” nu poate fi citit: { $error }
error-import-too-large = fișierul „{ $path }” are mai mult de 50 MB
error-import-not-mail = fișierul „{ $path }” nu conține un mesaj de e-mail valid
error-list-answered = serverul listei de corespondență a răspuns cu codul de stare { $status }
error-not-built = mesajul nu a putut fi creat
error-outbox-waits = { $count ->
    [one] mesajul așteaptă în folderul „Mesaje de trimis”; se va încerca din nou trimiterea la următoarea operație „Trimitere/primire”
    [few] { $count } mesaje așteaptă în folderul „Mesaje de trimis”; se va încerca din nou trimiterea la următoarea operație „Trimitere/primire”
   *[other] { $count } de mesaje așteaptă în folderul „Mesaje de trimis”; se va încerca din nou trimiterea la următoarea operație „Trimitere/primire”
}
error-draft-not-removed = schița anterioară a mesajului nu a putut fi eliminată din folderul „Schițe”: { $reason }
error-sent-but = mesajul a fost trimis, dar { $problem }
error-sent-still-in-outbox = este încă în folderul „Mesaje de trimis”: { $error }
error-sent-no-copy = nu s-a putut salva nicio copie în folderul „Elemente trimise”: { $reason }
error-no-password = nu există parolă pentru acest cont
error-no-sign-in = nu există date de conectare pentru acest cont
error-provider-missing = această versiune nu poate folosi configurația de conectare „{ $provider }”. Verificați dacă aplicația de conectare a fost eliminată
error-provider-servers = serverele acestui cont nu se potrivesc cu serverele aplicației sale de conectare
error-app-scopes = { $reason }. Serverul de e-mail nu a acceptat tokenul aplicației de conectare: verificați dacă permisiunile (scopes) aplicației dau acces la e-mail
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Aplicația de conectare Google integrată este dezactivată implicit în această versiune. Folosiți propria aplicație de conectare Google sau, dacă este permisă pentru contul dvs., o parolă de aplicație. Dacă aveți acces ca utilizator de test, puteți activa aplicația integrată din fereastra Aplicații de conectare, accesibilă din Conturi.
sign-in-off-other = A fost dezactivată în fereastra Aplicații de conectare, accesibilă din Conturi. O puteți activa din nou acolo.
sign-in-app-no-name = aplicația de conectare are nevoie de un nume
sign-in-app-no-client = lipsește ID-ul client
sign-in-app-no-scopes = aplicația de conectare are nevoie de permisiunile (scopes) care dau acces la e-mail
sign-in-app-bad-host = configurația serverului { $server } este incompletă sau nevalidă. Verificați numele gazdei și portul
sign-in-app-plain = serverul { $server } trebuie să folosească SSL/TLS sau STARTTLS
sign-in-app-not-checked = emitentul nu a fost verificat încă
sign-in-app-issuer-changed = emitentul s-a schimbat: introduceți din nou secretul client sau eliminați-l
sign-in-register-google = În Google Cloud Console, creați un client OAuth de tipul Desktop app, cu permisiunea https://mail.google.com/ pe ecranul de consimțământ. Cât timp aplicația este în testare, doar utilizatorii ei de test se pot conecta.
sign-in-register-microsoft = În Microsoft Entra, înregistrați o aplicație cu platforma Mobile and desktop applications și URI-ul de redirecționare http://localhost. Permiteți fluxurile de autentificare pentru clienți publici și adăugați permisiunile delegate IMAP.AccessAsUser.All, SMTP.Send și offline_access. Dacă aplicația este destinată doar organizației dvs., folosiți ca emitent https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Înregistrați un client nativ (public) cu URI-ul de redirecționare de mai jos. Furnizorul trebuie să permită folosirea oricărui port pentru acest URI (RFC 8252). Adăugați permisiunea prin care furnizorul acordă acces la e-mail.

## Calendar invitations

repeats = Se repetă
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
repeats-on = { $repeats }: { $days }
# "În fiecare săptămână, de 10 ori"
repeats-times = { $count ->
    [one] { $repeats }, o dată
    [few] { $repeats }, de { $count } ori
   *[other] { $repeats }, de { $count } de ori
}
day-monday = luni
day-tuesday = marți
day-wednesday = miercuri
day-thursday = joi
day-friday = vineri
day-saturday = sâmbătă
day-sunday = duminică

## AI agents

agent-level-read = Citirea mesajelor: foldere, lista de mesaje, conversații, căutare, mesaje și fișierele lor, regulile pentru mesaje și persoanele cărora le scrieți
agent-level-organize = Organizarea mesajelor: marcare ca citite sau necitite, semnalizare și culorile semnalizărilor, marcare ca nedorite, mutare, arhivare, creare și redenumire de foldere, urmărirea și ignorarea conversațiilor, mutare în folderul „Elemente șterse” și dezabonare de la liste de corespondență cu acordul dvs.
agent-level-drafts = Crearea de schițe pe care să le trimiteți dvs.
agent-level-send = Trimiterea mesajelor, numai cu aprobarea dvs. pentru fiecare mesaj
agent-connect-title = { $program } solicită acces la mesajele dvs.
agent-connect-detail = Un agent IA solicită acces prin Inbox Classic. Alegeți ce poate face și la ce conturi are acces. Puteți modifica ulterior aceste permisiuni în Instrumente > Agenți IA.

    Agenții citesc mesaje scrise de alte persoane, iar acestea pot conține instrucțiuni înșelătoare. Inbox Classic vă cere întotdeauna acordul înainte ca un agent să trimită un mesaj.
agent-reply-to = Răspuns la mesajul „{ $subject }”
agent-reply-all-on = Răspuns tuturor la mesajul „{ $subject }”
agent-forward-of = Redirecționarea mesajului „{ $subject }”
agent-never-written-one = Nu ați trimis niciodată mesaje la adresa { $address }.
agent-never-written-many = Nu ați trimis niciodată mesaje la { $count } dintre aceste adrese.
agent-send-title = { $program } vrea să trimită acest mesaj
agent-send-detail = Verificați destinatarii și conținutul mesajului. După confirmare, mesajul rămâne în folderul Mesaje de trimis timp de { $seconds } de secunde. Îl puteți șterge de acolo înainte de trimitere.
agent-change-title = Ce poate face { $program }
agent-change-allowed = Alegeți ce pot face agenții IA ai acestui program cu mesajele dvs.
agent-change-refused = Ați refuzat accesul acestui program. Permiteți accesul pentru ca agenții săi să poată lucra din nou cu mesajele dvs.
agent-log-taken-back = { $entry } (acțiune anulată)
agent-files = Fișiere: { $files }
agent-undo-refused = Acțiunea nu poate fi anulată.
agent-undo-refused-why = Acțiunea nu poate fi anulată: { $reason }.
agent-undo-impossible = această acțiune nu poate fi anulată
agent-undo-not-in-folder = mesajul nu mai este în acel folder
agent-undo-not-arrived = mesajul nu se află încă în folderul de destinație
agent-undo-sent = mesajul nu se mai află în folderul Mesaje de trimis
agent-original-not-downloaded = mesajul original nu a fost descărcat încă. Deschideți-l mai întâi
agent-turned-away = Acces refuzat
agent-can-nothing = Nimic
agent-can-read = citire
agent-can-organize = organizare
agent-can-drafts = creare de schițe
agent-can-send = trimitere cu acordul dvs.
# "Citire, organizare și scriere de schițe"
agent-can-list = { $first } și { $last }
agent-accounts = { $count ->
    [0] niciun cont
    [one] 1 cont
    [few] { $count } conturi
   *[other] { $count } de conturi
}
# "Citire și organizare; 1 cont"
agent-access = { $can }; { $accounts }
agent-unreadable = Acest mesaj nu poate fi citit.
agent-encrypted-original = Acest mesaj este criptat. Agentul nu poate nici să răspundă la el, nici să îl redirecționeze, deoarece nu poate cripta mesaje.
agent-encrypted = Acest mesaj este criptat. Agentul nu îi poate citi conținutul. Îl puteți deschide în Inbox Classic.
agent-too-many-changes = S-a atins limita modificărilor înregistrate în ultimele 30 de zile pentru acest program. Agentul va putea face alte modificări după ce cele mai vechi înregistrări împlinesc 30 de zile.
agent-too-many-reads = S-a atins limita operațiunilor de citire înregistrate în ultimele 30 de zile pentru acest program. Agentul va putea citi din nou după ce cele mai vechi înregistrări împlinesc 30 de zile.
list-encrypted = Mesaj criptat
agent-log-composed = A deschis un mesaj nou pentru editare. Subiect: „{ $subject }”
agent-log-refused = Nu ați aprobat trimiterea mesajului „{ $subject }”
agent-log-sent = A pus mesajul „{ $subject }” în coada de trimitere. Destinatari: { $to }
agent-log-draft = A salvat schița „{ $subject }”
agent-log-draft-replaced = A înlocuit schița „{ $subject }”
agent-log-draft-discarded = A șters definitiv schița „{ $subject }”
agent-draft-note = Agentul IA { $program } a redactat această schiță. Verificați destinatarii și textul înainte de a o trimite.
agent-log-read = A marcat mesajul „{ $subject }” ca citit
agent-log-unread = A marcat mesajul „{ $subject }” ca necitit
agent-log-flagged = A semnalizat mesajul „{ $subject }”
agent-log-unflagged = A eliminat semnalizarea mesajului „{ $subject }”
agent-log-deleted = A șters mesajul „{ $subject }”
agent-log-moved = A mutat mesajul „{ $subject }” în folderul „{ $folder }”
agent-log-junk = A marcat mesajul „{ $subject }” ca nedorit
agent-log-not-junk = A eliminat marcajul de e-mail nedorit pentru mesajul „{ $subject }”
agent-log-archived = A arhivat mesajul „{ $subject }”
agent-log-folder = A cerut crearea folderului „{ $name }”
agent-log-unsubscribed = Ați aprobat cererea de dezabonare. Mesaj: „{ $subject }”
agent-log-unsubscribe-failed = Cererea de dezabonare nu a reușit. Mesaj: „{ $subject }”. Motiv: { $reason }
agent-log-unsubscribe-refused = Nu ați aprobat dezabonarea. Expeditori: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } vrea să vă dezaboneze de la o listă de corespondență
    [few] { $program } vrea să vă dezaboneze de la { $count } liste de corespondență
   *[other] { $program } vrea să vă dezaboneze de la { $count } de liste de corespondență
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic trimite listei de mai jos o cerere de dezabonare, folosind opțiunea de dezabonare cu un clic oferită de listă. Nu trimite niciun e-mail și nu modifică mesajele pe care le aveți deja.
   *[other] Inbox Classic trimite fiecărei liste de mai jos o cerere de dezabonare, folosind opțiunea de dezabonare cu un clic oferită de listă. Nu trimite niciun e-mail și nu modifică mesajele pe care le aveți deja.
}
agent-log-flag-color = A aplicat semnalizarea { $color ->
    [red] roșie
    [orange] portocalie
    [yellow] galbenă
    [green] verde
    [blue] albastră
    [purple] violetă
   *[gray] cenușie
} pentru mesajul „{ $subject }”
agent-log-renamed = A cerut redenumirea folderului „{ $old }” în „{ $name }”
agent-log-watched = A început să urmărească conversația „{ $subject }”
agent-log-ignored = A început să ignore conversația „{ $subject }”
agent-log-unmarked = A oprit urmărirea sau ignorarea conversației „{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = mesajul a fost modificat între timp
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] A marcat 1 mesaj ca citit (căutare: { $query })
    [few] A marcat { $count } mesaje ca citite (căutare: { $query })
   *[other] A marcat { $count } de mesaje ca citite (căutare: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] A marcat 1 mesaj ca necitit (căutare: { $query })
    [few] A marcat { $count } mesaje ca necitite (căutare: { $query })
   *[other] A marcat { $count } de mesaje ca necitite (căutare: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] A semnalizat 1 mesaj (căutare: { $query })
    [few] A semnalizat { $count } mesaje (căutare: { $query })
   *[other] A semnalizat { $count } de mesaje (căutare: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] A eliminat semnalizarea pentru 1 mesaj (căutare: { $query })
    [few] A eliminat semnalizarea pentru { $count } mesaje (căutare: { $query })
   *[other] A eliminat semnalizarea pentru { $count } de mesaje (căutare: { $query })
}
agent-log-bulk-color = A aplicat semnalizarea { $color ->
    [red] roșie
    [orange] portocalie
    [yellow] galbenă
    [green] verde
    [blue] albastră
    [purple] violetă
   *[gray] cenușie
} pentru { $count ->
    [one] 1 mesaj
    [few] { $count } mesaje
   *[other] { $count } de mesaje
} (căutare: { $query })
agent-log-bulk-moved = { $count ->
    [one] A mutat 1 mesaj în folderul „{ $folder }” (căutare: { $query })
    [few] A mutat { $count } mesaje în folderul „{ $folder }” (căutare: { $query })
   *[other] A mutat { $count } de mesaje în folderul „{ $folder }” (căutare: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] A arhivat 1 mesaj (căutare: { $query })
    [few] A arhivat { $count } mesaje (căutare: { $query })
   *[other] A arhivat { $count } de mesaje (căutare: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] A marcat 1 mesaj ca nedorit (căutare: { $query })
    [few] A marcat { $count } mesaje ca nedorite (căutare: { $query })
   *[other] A marcat { $count } de mesaje ca nedorite (căutare: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] A eliminat marcajul de e-mail nedorit pentru 1 mesaj (căutare: { $query })
    [few] A eliminat marcajul de e-mail nedorit pentru { $count } mesaje (căutare: { $query })
   *[other] A eliminat marcajul de e-mail nedorit pentru { $count } de mesaje (căutare: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] A șters 1 mesaj (căutare: { $query })
    [few] A șters { $count } mesaje (căutare: { $query })
   *[other] A șters { $count } de mesaje (căutare: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] În ultimele 15 minute
    [hour] În ultima oră
    [hours] În ultimele 4 ore
    [day] În ultimele 24 de ore
    [week] În ultimele 7 zile
   *[all] În ultimele 30 de zile
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] { $program } nu a făcut în acest interval nicio modificare care poate fi anulată.
    [one] Anulați modificarea făcută de { $program } în acest interval?
    [few] Anulați cele { $count } modificări făcute de { $program } în acest interval?
   *[other] Anulați cele { $count } de modificări făcute de { $program } în acest interval?
}
agent-undo-since-detail = Se încearcă readucerea mesajelor în folderele inițiale și restabilirea stării de citire și a semnalizărilor. Mesajele care încă așteaptă în folderul „Mesaje de trimis” sunt șterse. Mesajele a căror poziție sau stare relevantă nu mai corespunde sunt omise. Unele modificări ulterioare ale culorii unei semnalizări pot fi totuși anulate.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Nu s-a anulat nimic.
    [one] Anulare completă sau parțială pentru 1 operație.
    [few] Anulare completă sau parțială pentru { $count } operații.
   *[other] Anulare completă sau parțială pentru { $count } de operații.
}
agent-undo-left-gone = { $count ->
    [one] 1 mesaj nu mai era la locul în care se afla după acțiunea agentului.
    [few] { $count } mesaje nu mai erau la locul în care se aflau după acțiunea agentului.
   *[other] { $count } de mesaje nu mai erau la locul în care se aflau după acțiunea agentului.
}
agent-undo-left-changed = { $count ->
    [one] 1 mesaj fusese modificat între timp de dvs. sau pe server și a fost păstrat în starea actuală.
    [few] { $count } mesaje fuseseră modificate între timp de dvs. sau pe server și au fost păstrate în starea actuală.
   *[other] { $count } de mesaje fuseseră modificate între timp de dvs. sau pe server și au fost păstrate în starea actuală.
}
agent-undo-left-sent = { $count ->
    [one] 1 mesaj nu mai era în folderul „Mesaje de trimis”.
    [few] { $count } mesaje nu mai erau în folderul „Mesaje de trimis”.
   *[other] { $count } de mesaje nu mai erau în folderul „Mesaje de trimis”.
}
agent-undo-left-impossible = { $count ->
    [one] 1 modificare nu poate fi anulată.
    [few] { $count } modificări nu pot fi anulate.
   *[other] { $count } de modificări nu pot fi anulate.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Prin acest mesaj acceptați invitația „{ $summary }” ({ $when }).
    [tentative] Prin acest mesaj acceptați provizoriu invitația „{ $summary }” ({ $when }).
   *[decline] Prin acest mesaj refuzați invitația „{ $summary }” ({ $when }).
} Răspunsul este trimis organizatorului pentru a fi prelucrat de aplicația sa de calendar. Starea invitației din Inbox Classic se schimbă numai după trimiterea cu succes a mesajului.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Invitație acceptată: { $summary }
    [tentative] Acceptare provizorie: { $summary }
   *[decline] Invitație refuzată: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } a acceptat această invitație.
    [tentative] { $name } a acceptat provizoriu această invitație.
   *[decline] { $name } a refuzat această invitație.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] a citit 1 mesaj
    [few] a citit { $count } mesaje
   *[other] a citit { $count } de mesaje
}
agent-reads-attachments = { $count ->
    [one] a citit 1 atașare
    [few] a citit { $count } atașări
   *[other] a citit { $count } de atașări
}
agent-reads-searches = { $count ->
    [one] a căutat o dată
    [few] a căutat de { $count } ori
   *[other] a căutat de { $count } de ori
}
agent-reads-lists = { $count ->
    [one] a consultat o listă de mesaje o dată
    [few] a consultat liste de mesaje de { $count } ori
   *[other] a consultat liste de mesaje de { $count } de ori
}
# each read under that row
agent-read-message = A citit mesajul „{ $subject }”
agent-read-conversation = { $count ->
    [one] A citit conversația „{ $subject }” (1 mesaj)
    [few] A citit conversația „{ $subject }” ({ $count } mesaje)
   *[other] A citit conversația „{ $subject }” ({ $count } de mesaje)
}
agent-read-attachment = A citit atașarea „{ $name }” din mesajul „{ $subject }”
agent-read-search = { $count ->
    [one] A căutat „{ $query }”: 1 mesaj
    [few] A căutat „{ $query }”: { $count } mesaje
   *[other] A căutat „{ $query }”: { $count } de mesaje
}
agent-read-people = A căutat persoane al căror nume sau adresă începe cu „{ $query }”
agent-read-list = { $count ->
    [one] A consultat 1 rând din lista „{ $folder }”
    [few] A consultat { $count } rânduri din lista „{ $folder }”
   *[other] A consultat { $count } de rânduri din lista „{ $folder }”
}
agent-read-changes = { $count ->
    [one] A consultat datele despre 1 mesaj nou
    [few] A consultat datele despre { $count } mesaje noi
   *[other] A consultat datele despre { $count } de mesaje noi
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Programe pornite din { $terminal }
agent-terminal-programs-windows = Programe pornite dintr-un terminal ({ $terminal })
agent-terminal-programs-linux = Programe pornite dintr-un terminal ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Un program pornit din { $terminal }
agent-terminal-program-windows = Un program pornit dintr-un terminal ({ $terminal })
agent-terminal-program-linux = Un program pornit dintr-un terminal ({ $terminal })
agent-connect-title-terminal = { $programs } solicită acces la mesajele dvs.
agent-connect-terminal-detail = Toți agenții IA pe care îi porniți din acest terminal folosesc accesul pe care îl permiteți aici. Pentru ca un agent să aibă propriul acces, adăugați --name și un nume ales de dvs. la argumentele sale din setările MCP ale agentului.
agent-connect-claimed = Programul s-a prezentat ca { $claimed }. Inbox Classic a verificat ce program l-a pornit: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = furnizorul nu a furnizat niciun token de reîmprospătare
sign-in-no-account = furnizorul nu a indicat contul la care s-a făcut conectarea
sign-in-not-finished = conectarea nu s-a terminat
secrets-unavailable = { $store } nu este disponibil
secrets-unavailable-why = { $store } nu este disponibil: { $error }
secrets-windows = Managerul de acreditări
secrets-mac = Portchei
secrets-linux = portcheiul sistemului (Secret Service)
error-no-such-file = fișierul nu există
cards-file-too-big = Fișierul depășește limita de dimensiune pentru importul agendei.
ui-sender-added = Contactul „{ $name }” a fost adăugat în Agendă.
ui-sender-known = { $name } este deja în Agendă.
ui-sender-none = Expeditorul acestui mesaj nu are o adresă de e-mail de adăugat.
card-name-needed = Contactul nu are nici nume, nici adresă de e-mail.
# a file of Import Address Book that could not be read: "contacts.vcf: fișierul nu există"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Cod de la { $domain }
otp-copy = Copiere
otp-note = Introduceți-l doar pe o pagină din domeniul „{ $domain }”.
otp-old = Acest cod a fost trimis cu peste o oră înainte de deschiderea mesajului și probabil a expirat.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } participant
        [few] { $count } participanți
       *[other] { $count } de participanți
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } este codul dvs. pentru { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Utilizabilă
pgp-key-expires = Utilizabilă până la { $date }
pgp-key-expired = A expirat pe { $date }
pgp-key-revoked = Revocată
pgp-key-revoked-why = Revocată: { $reason }
pgp-key-not-valid = Neutilizabilă
pgp-key-locked = Cheia privată nu poate fi deschisă. Verificați dacă { $store } este disponibil și deblocat. Dacă cheia de protecție a fost pierdută sau resetată, importați din nou copia de rezervă a cheii private.
pgp-source-own = Creată în Inbox Classic
pgp-source-file = Importată dintr-un fișier
pgp-source-paste = Adăugată prin lipire
pgp-source-attachment = Dintr-un mesaj
pgp-source-vcard = Dintr-o fișă de contact
pgp-source-wkd = De la furnizorul de e-mail al expeditorului
pgp-source-keyserver = De pe keys.openpgp.org
pgp-source-autocrypt = Din antetul Autocrypt al unui mesaj
pgp-error-no-store = Nu se poate folosi { $store } pentru protejarea cheilor private: { $error }
pgp-error-wrong-passphrase = Fraza-parolă nu este corectă.
pgp-error-not-a-key = Aceasta nu este o cheie OpenPGP.
pgp-error-too-large = Cheia este prea mare.
pgp-error-unusable = Cheia nu conține componente utilizabile pentru operația cerută sau folosește algoritmi criptografici neacceptați.
pgp-imported-private = { $count ->
    [one] Cheia dvs. privată a fost importată.
    [few] Au fost importate { $count } chei private.
   *[other] Au fost importate { $count } de chei private.
}
pgp-imported-public = { $count ->
    [one] A fost importată o cheie.
    [few] Au fost importate { $count } chei.
   *[other] Au fost importate { $count } de chei.
}
pgp-imported-pending = Pentru { $addresses } se folosește deja altă cheie. Cheia nouă rămâne în așteptare în fișa contactului până când o alegeți.
pgp-error-needs-passphrase = Cheia privată este protejată de o frază-parolă. Introduceți-o pentru a importa cheia.
pgp-error-mismatch = Cheia privată nu corespunde cheii publice asociate. Este posibil să fi fost modificată.
pgp-file-name-public = { $who } cheie publică.asc
pgp-file-name-private = { $who } copie de rezervă cheie privată.asc
pgp-pending = Pe { $date } s-a găsit o altă cheie pentru { $address }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Semnat de { $signer }; proprietarul cheii a fost confirmat
pgp-part-signed = Semnat de { $signer } (proprietarul cheii nu a fost confirmat)
pgp-part-other = Semnat de { $signer }; semnătura nu a fost asociată expeditorului mesajului
pgp-part-unknown-key = Semnat, dar cheia nu este cunoscută
pgp-part-not-signed = Nesemnat
pgp-part-not-checked = Semnătura nu a fost verificată
pgp-part-encrypted = Criptat. { $signature }
pgp-part-no-key = Criptat pentru o cheie pe care nu o aveți
pgp-part-changed = Integritatea părții criptate nu a putut fi confirmată, așa că aceasta nu este afișată
pgp-part-unprotected = Criptat fără protecție împotriva modificărilor, nu este afișat
pgp-part-broken = Partea criptată nu poate fi citită
pgp-why-mismatch = Semnătura nu corespunde acestui text
pgp-why-weak-hash = Semnătura folosește algoritmul { $hash }, care nu mai este sigur
pgp-why-key-expired = Semnat după ce cheia a expirat pe { $date }
pgp-why-key-revoked = Semnat cu o cheie care a fost revocată
pgp-why-not-signing-key = Semnat cu o cheie care nu este destinată semnării
pgp-why-from-future = Semnătura este datată în viitor
pgp-why-signature-expired = Semnătura a expirat
pgp-why-key-not-valid = Semnat cu o cheie care nu este validă
pgp-why-not-for-you = Semnat pentru alți destinatari și transmis mai departe către dvs.
pgp-why-not-key-in-use = Semnat cu o altă cheie decât cea folosită pentru { $address }
pgp-part-pictures-loaded = { $label }. Imaginile au fost încărcate de pe internet
pgp-error-no-own-key = Nu aveți o cheie pentru { $address } cu care să semnați sau să criptați. Creați una în Instrumente > Chei de criptare sau dezactivați Semnare și Criptare.
pgp-error-missing-keys = { $count ->
    [one] { $addresses } nu are o cheie pentru criptare.
   *[other] Acești destinatari nu au o cheie pentru criptare: { $addresses }.
}
pgp-error-encrypted-quote = Acest mesaj conține text, imagini sau atașări dintr-un mesaj criptat și poate fi trimis doar criptat. Activați Criptare sau eliminați tot conținutul preluat din mesajul criptat.
pgp-error-protect = Mesajul nu a putut fi semnat sau criptat: { $reason }
pgp-found-keys = Chei găsite pentru: { $addresses }.
pgp-found-none = Nu s-a găsit nicio cheie pentru adresele: { $addresses }. Cereți destinatarilor cheile publice corespunzătoare.
pgp-found-no-key = Nu s-a găsit nicio cheie.
pgp-find-unavailable = Cheile nu pot fi căutate acum: { $error }
pgp-publish-pending = keys.openpgp.org a trimis un link de confirmare la fiecare dintre aceste adrese: { $addresses }. Confirmați fiecare adresă pentru ca cheia dvs. să poată fi găsită folosind adresa respectivă.
pgp-publish-done = Cheia dvs. este publicată pe keys.openpgp.org pentru { $addresses }.
pgp-publish-failed = Cheia nu a putut fi publicată: { $error }
pgp-keyserver-off = Căutarea cheilor pe keys.openpgp.org este dezactivată în { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Mesajul va fi criptat și semnat digital la trimitere. Numai dvs. și { $addresses } veți putea citi conținutul.
    [few] Mesajul va fi criptat și semnat digital la trimitere. Numai dvs. și cei { $count } destinatari veți putea citi conținutul.
   *[other] Mesajul va fi criptat și semnat digital la trimitere. Numai dvs. și cei { $count } de destinatari veți putea citi conținutul.
}
pgp-compose-encrypt-ready = Mesajul va fi criptat și semnat digital la trimitere. Adăugați destinatari pentru care aveți chei.
pgp-compose-missing = { $count ->
    [one] Destinatar fără cheie utilizabilă: { $addresses }. Mesajul nu poate fi criptat încă.
    [few] { $count } destinatari fără chei utilizabile: { $addresses }. Mesajul nu poate fi criptat încă.
   *[other] { $count } de destinatari fără chei utilizabile: { $addresses }. Mesajul nu poate fi criptat încă.
}
pgp-compose-looking = Se caută cheile pentru { $addresses }...
pgp-compose-signed = Mesajul va fi semnat digital la trimitere. Destinatarii vor putea verifica dacă a fost modificat după semnare.
pgp-compose-reply-clear = Mesajul va fi trimis fără criptare, deși mesajul original era criptat.
pgp-compose-encrypted-files = Mesajul conține atașări dintr-un mesaj criptat și poate fi trimis doar criptat. Activați opțiunea „Criptare” sau eliminați aceste atașări.
pgp-compose-sign-tip = Semnați digital mesajul cu cheia dvs., pentru ca destinatarii să poată verifica dacă a fost modificat după semnare
pgp-compose-sign-tip-encrypted = Mesajele trimise în formă criptată sunt și semnate digital
pgp-compose-encrypt-tip = Criptați conținutul mesajului, astfel încât să poată fi citit doar de dvs. și de destinatari
pgp-compose-make-key = Nu aveți încă o cheie pentru adresa { $address }. Doriți să creați una acum? O puteți folosi pentru a semna digital și a cripta mesaje.
pgp-compose-key-unusable =
    Cheia dvs. pentru adresa { $address } nu poate fi folosită.

    Motiv: { $state }

    Deschideți fereastra „Chei de criptare” pentru a importa copia de rezervă a acestei chei sau pentru a crea o cheie nouă.
pgp-compose-encrypt-off-quote = Mesajul conține text, imagini sau atașări dintr-un mesaj criptat. Îl puteți trimite fără criptare doar după ce eliminați acest conținut. Dezactivați totuși criptarea?
pgp-compose-encrypt-off-reply = Răspundeți la un mesaj criptat sau îl redirecționați. Fără criptare, conținutul mesajului dvs. poate fi citit și de serverele prin care trece. Dezactivați criptarea?
pgp-recipient-verified = Proprietarul cheii a fost confirmat
pgp-recipient-found = Proprietarul cheii nu a fost confirmat
pgp-recipient-own = Cheia dvs.
pgp-recipient-looking = Se caută o cheie...
pgp-recipient-missing = Nicio cheie
pgp-recipient-not-found = Nu s-a găsit nicio cheie. Ultima căutare: { $date }
pgp-recipient-unusable = Cheia nu poate fi folosită: { $state }
pgp-recipients-intro = Mesajul este criptat cu cheia fiecărui destinatar și cu cheia dvs.
pgp-recipients-intro-missing = { $count ->
    [one] Un destinatar nu are o cheie utilizabilă pentru criptare. Căutați cheia lui, eliminați destinatarul din mesaj sau trimiteți mesajul fără criptare.
    [few] { $count } destinatari nu au chei utilizabile pentru criptare. Căutați cheile lor, eliminați acești destinatari din mesaj sau trimiteți mesajul fără criptare.
   *[other] { $count } de destinatari nu au chei utilizabile pentru criptare. Căutați cheile lor, eliminați acești destinatari din mesaj sau trimiteți mesajul fără criptare.
}
pgp-details-part = Partea { $number }: { $label }
attachment-from-part = Din partea { $number }: { $label }
pgp-details-signed = Semnătură creată: { $when }; cheie: { $key }
pgp-details-unknown-key = Semnat cu cheia { $key }, pe care nu o aveți
pgp-details-opened = Decriptat cu cheia dvs. { $key }
pgp-details-for = Criptat pentru { $keys }
pgp-details-plain = Nesemnat și necriptat
pgp-bar-parts = Mesajul conține următoarele părți (total: { $count }): { $list }. Fiecare parte indică modul în care este protejată.
pgp-bar-count-verified = Cu proprietarul cheii confirmat: { $count }
pgp-bar-count-encrypted-signed = Criptate și semnate: { $count }
pgp-bar-count-encrypted = Criptate: { $count }
pgp-bar-count-signed = Semnate: { $count }
pgp-bar-count-warning = Necesită atenție: { $count }
pgp-bar-count-neutral = Fără semnătură confirmată: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Setări
setup-part-preferences = Preferințele ferestrelor
setup-part-accounts = Conturi
setup-part-sign-in-apps = Aplicații de conectare
setup-part-contacts = Contacte și grupuri
setup-part-keys = Chei de criptare
setup-part-rules = Reguli pentru mesaje
setup-part-trusted-senders = Expeditori de încredere
setup-holds-settings = { $count ->
    [one] 1 setare
    [few] { $count } setări
   *[other] { $count } de setări
}
setup-holds-preferences = { $count ->
    [one] 1 preferință
    [few] { $count } preferințe
   *[other] { $count } de preferințe
}
setup-holds-accounts = { $count ->
    [one] 1 cont
    [few] { $count } conturi
   *[other] { $count } de conturi
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 aplicație de conectare
    [few] { $count } aplicații de conectare
   *[other] { $count } de aplicații de conectare
}
setup-holds-built-in = Ce aplicații de conectare integrate sunt activate
setup-holds-contacts = { $count ->
    [one] 1 contact
    [few] { $count } contacte
   *[other] { $count } de contacte
}
setup-holds-groups = { $count ->
    [one] 1 grup
    [few] { $count } grupuri
   *[other] { $count } de grupuri
}
setup-holds-own-keys = { $count ->
    [one] 1 cheie proprie
    [few] { $count } chei proprii
   *[other] { $count } de chei proprii
}
setup-holds-contact-keys = { $count ->
    [one] 1 cheie a unui contact
    [few] { $count } chei ale contactelor
   *[other] { $count } de chei ale contactelor
}
setup-holds-rules = { $count ->
    [one] 1 regulă
    [few] { $count } reguli
   *[other] { $count } de reguli
}
setup-holds-trusted-senders = { $count ->
    [one] 1 expeditor de încredere
    [few] { $count } expeditori de încredere
   *[other] { $count } de expeditori de încredere
}
setup-sign-in-password = Parolă
setup-account-secret-password = Parola contului este inclusă în fișier.
setup-account-secret-token = Datele de conectare ale contului sunt incluse în fișier.
setup-account-asks-password = După import, va trebui să introduceți parola contului.
setup-account-signs-in-again = După import, va trebui să vă conectați din nou la acest cont.
setup-account-here = Contul este deja configurat pe acest computer și va fi omis.
setup-account-no-app = Acest cont folosește aplicația de conectare „{ $app }”, care nu este configurată aici. Importați și aplicațiile de conectare.
setup-invalid-address = „{ $address }” nu este o adresă de e-mail.
setup-invalid-server = Configurația serverului { $server } nu este utilizabilă. Verificați numele gazdei, portul și opțiunea de securitate.
setup-invalid-user = Nu are nume de utilizator.
setup-invalid-sign-in = Configurația de conectare nu poate fi folosită de Inbox Classic.
setup-error-empty = Fișierul este gol.
setup-error-too-large = Fișierul depășește limita de dimensiune pentru o configurație Inbox Classic.
setup-error-not-setup = Acesta nu este un fișier de configurare Inbox Classic.
setup-error-damaged = Fișierul de configurație este deteriorat și nu poate fi citit.
setup-error-newer = Această configurație a fost salvată de o versiune mai nouă de Inbox Classic ({ $version }). Actualizați Inbox Classic, apoi importați-o din nou.
setup-error-needs-passphrase = Această configurație este protejată de o frază-parolă. Introduceți fraza-parolă cu care a fost salvată.
setup-error-wrong-passphrase = Aceasta nu este fraza-parolă cu care a fost salvată configurația.
setup-error-changed = Integritatea fișierului de configurație nu a putut fi confirmată. Fișierul poate fi modificat sau deteriorat și nu poate fi importat.
setup-error-read = Fișierul de configurație nu a putut fi citit: { $error }
setup-error-write = Configurația nu a putut fi salvată: { $error }
setup-error-no-parts = Alegeți cel puțin o categorie de date.
setup-left-out = { $count ->
    [one] O intrare din categoria „{ $part }” nu poate fi folosită și este omisă.
    [few] { $count } intrări din categoria „{ $part }” nu pot fi folosite și sunt omise.
   *[other] { $count } de intrări din categoria „{ $part }” nu pot fi folosite și sunt omise.
}
setup-imported-settings = Setările au fost înlocuite.
setup-imported-preferences = Preferințele ferestrelor au fost înlocuite.
setup-added-accounts = { $count ->
    [one] S-a adăugat 1 cont.
    [few] S-au adăugat { $count } conturi.
   *[other] S-au adăugat { $count } de conturi.
}
setup-skipped-here = Contul „{ $address }” este deja configurat pe acest computer și a fost omis.
setup-skipped-no-app = Contul „{ $address }” a fost omis: folosește aplicația de conectare „{ $app }”, care nu este configurată aici.
setup-skipped-invalid = Contul „{ $address }” a fost omis: { $reason }
setup-asks-password = La conectarea la contul „{ $address }”, vi se va cere parola.
setup-signs-in-again = Contul „{ $address }” va solicita o nouă conectare la prima sincronizare.
setup-added-sign-in-apps = { $count ->
    [one] S-a adăugat 1 aplicație de conectare.
    [few] S-au adăugat { $count } aplicații de conectare.
   *[other] S-au adăugat { $count } de aplicații de conectare.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 aplicație de conectare este deja configurată aici.
    [few] { $count } aplicații de conectare sunt deja configurate aici.
   *[other] { $count } de aplicații de conectare sunt deja configurate aici.
}
setup-added-contacts = { $count ->
    [one] S-a adăugat 1 contact în Agendă.
    [few] S-au adăugat { $count } contacte în Agendă.
   *[other] S-au adăugat { $count } de contacte în Agendă.
}
setup-skipped-contacts = { $count ->
    [one] 1 contact este deja în Agendă.
    [few] { $count } contacte sunt deja în Agendă.
   *[other] { $count } de contacte sunt deja în Agendă.
}
setup-added-groups = { $count ->
    [one] S-a adăugat sau completat 1 grup.
    [few] S-au adăugat sau completat { $count } grupuri.
   *[other] S-au adăugat sau completat { $count } de grupuri.
}
setup-added-own-keys = { $count ->
    [one] S-a adăugat 1 cheie proprie.
    [few] S-au adăugat { $count } chei proprii.
   *[other] S-au adăugat { $count } de chei proprii.
}
setup-added-contact-keys = { $count ->
    [one] S-a adăugat 1 cheie a unui contact.
    [few] S-au adăugat { $count } chei ale contactelor.
   *[other] S-au adăugat { $count } de chei ale contactelor.
}
setup-added-rules = { $count ->
    [one] S-a adăugat 1 regulă pentru mesaje.
    [few] S-au adăugat { $count } reguli pentru mesaje.
   *[other] S-au adăugat { $count } de reguli pentru mesaje.
}
setup-skipped-rules = { $count ->
    [one] 1 regulă pentru mesaje există deja aici.
    [few] { $count } reguli pentru mesaje există deja aici.
   *[other] { $count } de reguli pentru mesaje există deja aici.
}
setup-skipped-rules-account = { $count ->
    [one] 1 regulă pentru mesaje se referă la un cont care nu este configurat pe acest computer și a fost omisă.
    [few] { $count } reguli pentru mesaje se referă la conturi care nu sunt configurate pe acest computer și au fost omise.
   *[other] { $count } de reguli pentru mesaje se referă la conturi care nu sunt configurate pe acest computer și au fost omise.
}
setup-rules-waiting = { $count ->
    [one] 1 regulă pentru mesaje așteaptă identificarea folderului de destinație după sincronizarea contului.
    [few] { $count } reguli pentru mesaje așteaptă identificarea folderelor de destinație după sincronizarea conturilor.
   *[other] { $count } de reguli pentru mesaje așteaptă identificarea folderelor de destinație după sincronizarea conturilor.
}
setup-added-trusted-senders = { $count ->
    [one] S-a adăugat 1 expeditor de încredere.
    [few] S-au adăugat { $count } expeditori de încredere.
   *[other] S-au adăugat { $count } de expeditori de încredere.
}
setup-nothing = Nu s-a importat nimic.
setup-account-servers = { $imap } și { $smtp } ({ $signin })
setup-file-name = Setări și conturi Inbox Classic
setup-skipped-unreachable = Nu s-a putut importa „{ $name }”: configurația serviciului de conectare nu a putut fi verificată. Adăugați din nou aplicația de conectare necesară în Aplicații de conectare.
attachment-runs-programs = Fișierul „{ $name }” poate rula programe, de aceea Inbox Classic nu îl deschide. Salvați-l, apoi deschideți-l manual dacă aveți încredere în sursa lui.
attachment-decrypted-note = Această atașare provine dintr-un mesaj criptat. Pentru a o deschide, Inbox Classic salvează o copie necriptată într-un folder temporar al contului dvs. de utilizator. La pornire, aplicația încearcă să elimine copiile mai vechi de o zi.
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

preview-pdf-option = Afișare fișiere PDF în mesaje
preview-pdf-off = Fișierele PDF nu sunt afișate în mesaje.
preview-pdf-off-crashed = O previzualizare a fost întreruptă de o închidere neașteptată sau de un blocaj. Ca măsură de precauție, fișierele PDF nu mai sunt afișate în mesaje, dar imaginile sunt afișate în continuare. Pentru a afișa din nou fișierele PDF, activați „{ $option }” în { $settings }.
preview-pdf-details = { $count ->
    [one] 1 pagină, { $size }
    [few] { $count } pagini, { $size }
   *[other] { $count } de pagini, { $size }
}
preview-page-alt = { $name }, pagina { $page } din { $count }
preview-more-pages = { $count ->
    [one] Deschideți fișierul pentru a vedea pagina
    [few] Deschideți fișierul pentru a vedea toate cele { $count } pagini
   *[other] Deschideți fișierul pentru a vedea toate cele { $count } de pagini
}
preview-more-files = { $count ->
    [one] Încă 1 fișier este în lista de mai sus
    [few] Încă { $count } fișiere sunt în lista de mai sus
   *[other] Încă { $count } de fișiere sunt în lista de mai sus
}
preview-tile-downloading = Se descarcă…
preview-tile-preparing = Se pregătește…
preview-tile-format = Imaginile { $format } nu sunt încă afișate
preview-tile-password = Protejat cu parolă: deschideți-l pentru a introduce parola
preview-tile-too-large = Depășește limita de previzualizare
preview-tile-unreadable = Nu poate fi afișat
preview-tile-timed-out = Afișarea a durat prea mult
preview-tile-crashed = Previzualizarea anterioară a fost întreruptă sau s-a blocat
preview-tile-off = Nu este afișat până la repornirea Inbox Classic
preview-not-printed = Fișierul „{ $name }” ({ $details }) nu este inclus la imprimare. Deschideți-l pentru a-l imprima.
