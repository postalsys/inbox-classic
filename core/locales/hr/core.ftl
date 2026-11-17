# Hrvatski. Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

## Counts and sizes

# review: new
messages = { $count ->
    [one] { $count } poruka
    [few] { $count } poruke
   *[other] { $count } poruka
}
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] { $count } bajt
    [few] { $count } bajta
   *[other] { $count } bajtova
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Isključeno
# review: new
send-delay-seconds = { $count ->
    [one] { $count } sekunda
    [few] { $count } sekunde
   *[other] { $count } sekundi
}
# review: new
list-counts = { $messages }, nepročitano: { $unread }
# review: new
list-counts-selected = { $messages }, nepročitano: { $unread }, odabrano: { $selected }
# review: new
list-counts-found = Pronađeno: { $found }, nepročitano: { $unread }
# review: new
list-counts-found-selected = Pronađeno: { $found }, nepročitano: { $unread }, odabrano: { $selected }
# review: new
list-counts-none = Nije pronađena nijedna poruka

## Special folders, as Outlook names them

# review: new
folder-inbox = Ulazna pošta
# review: new
folder-sent = Poslane stavke
# review: new
folder-deleted = Izbrisane stavke
# review: new
folder-drafts = Skice
# review: new
folder-junk = Neželjena e-pošta
# review: new
folder-archive = Arhiva

## The reading pane

# review: new
reader-no-message = Nije odabrana nijedna poruka.
# review: new
reader-downloading = Preuzimanje poruke…
# review: new
reader-downloading-detail = Poruka će se pojaviti ovdje kad preuzimanje završi.
# review: new
reader-downloading-size = Poruka ima { $size }. Pojavit će se ovdje kad se preuzme.
# review: new
reader-failed = Poruku nije moguće preuzeti
# review: new
reader-failed-network = Poslužitelj e-pošte nije dostupan ({ $reason }).
# review: new
reader-failed-sign-in = Poslužitelj e-pošte nije prihvatio prijavu ({ $reason }). Provjerite lozinku ili se ponovno prijavite u izborniku Datoteka > Računi.
# review: new
reader-failed-security = Vezu s poslužiteljem e-pošte nije moguće zaštititi ({ $reason }).
# review: new
reader-failed-other = Poslužitelj e-pošte odgovorio je: { $reason }.
# review: new
reader-retry-note = Ponovno će se pokušati kad se račun ponovno poveže.
# review: new
reader-unreadable = Ova se poruka ne može prikazati: { $error }
# review: new
message-source-title = Izvorni kod poruke: { $subject }
# review: new
message-source-untitled = Izvorni kod poruke

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Od
# review: new
header-date = Datum
# review: new
header-to = Za
# review: new
header-cc = Kopija
# review: new
header-sent = Poslano
# review: new
header-subject = Predmet
# review: new
header-security = Sigurnost
# review: new
header-part = Dio { $number }
# review: new
quote-original = ----- Izvorna poruka -----
# review: new
fold-show-earlier = Prikaži ranije poruke

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Vaša poruka nije isporučena
# review: new
bounce-delayed = Vaša poruka još nije isporučena
# review: new
bounce-delayed-note = Vaš poslužitelj e-pošte još je pokušava isporučiti. Ne morate je ponovno slati.
# review: new
bounce-show-message = Prikaži vraćenu poruku
# review: new
bounce-show-delayed = Prikaži odgođenu poruku
# review: new
bounce-what-to-do = Što možete učiniti:
# review: new
bounce-delayed-do = Zasad ništa. Ako se i dalje ne bude mogla isporučiti, dobit ćete novu obavijest.
# review: new
bounce-delayed-row-do = Zasad ništa. Vaš poslužitelj e-pošte još je pokušava isporučiti, a ako ne uspije, dobit ćete novu obavijest.
# review: new
bounce-details = Pojedinosti
# review: new
bounce-someone = Primatelj
# review: new
bounce-server = Poslužitelj: { $server }
# review: new
bounce-status = Status: { $status }
# review: new
bounce-reported-by = Prijavio: { $server }
# review: new
bounce-retry-minutes = Poslužitelj primatelja zatražio je da se prije sljedećeg pokušaja pričeka { $count ->
    [1] minutu
    [one] { $count } minutu
    [few] { $count } minute
   *[other] { $count } minuta
}.
# review: new
bounce-retry-hours = Poslužitelj primatelja zatražio je da se prije sljedećeg pokušaja pričeka { $count ->
    [1] sat
    [one] { $count } sat
    [few] { $count } sata
   *[other] { $count } sati
}.
# review: new
bounce-blocklist = Popis blokiranih: { $lists }
# review: new
bounce-user-unknown = Adresa ne postoji
# review: new
bounce-user-unknown-why = Poslužitelj primatelja nema poštanski sandučić s ovom adresom. Možda je pogrešno upisana ili je osoba više ne koristi.
# review: new
bounce-user-unknown-do = Provjerite je li adresa točno napisana ili pitajte osobu koju adresu sada koristi.
# review: new
bounce-invalid-address = Adresa nije valjana
# review: new
bounce-invalid-address-why = Adresa nije napisana u obliku na koji se može slati pošta.
# review: new
bounce-invalid-address-do = Potražite pogreške u pisanju, na primjer razmak, slovo koje nedostaje ili ništa iza znaka @.
# review: new
bounce-mailbox-disabled = Poštanski sandučić je zatvoren
# review: new
bounce-mailbox-disabled-why = Adresa postoji, ali je njezin poštanski sandučić isključen ili se više ne koristi.
# review: new
bounce-mailbox-disabled-do = Javite se osobi na drugi način i pitajte je koju adresu sada koristi.
# review: new
bounce-mailbox-full = Poštanski sandučić je pun
# review: new
bounce-mailbox-full-why = U poštanskom sandučiću primatelja nema mjesta za novu poštu.
# review: new
bounce-mailbox-full-do = Pošaljite je ponovno za nekoliko dana ili obavijestite osobu na drugi način. Veliki privici odbijaju se prvi.
# review: new
bounce-spam-blocked = Odbijeno kao neželjena pošta
# review: new
bounce-spam-blocked-why = Poslužitelj primatelja smatrao je poruku neželjenom poštom.
# review: new
bounce-spam-blocked-do = Pošaljite je ponovno bez onoga što izgleda kao neželjena pošta, na primjer mnogo poveznica, skraćenih poveznica ili velikog privitka. Ako se to ponavlja, obratite se svojem davatelju usluge e-pošte.
# review: new
bounce-virus-detected = Odbijeno zbog virusa
# review: new
bounce-virus-detected-why = Poslužitelj primatelja pronašao je virus ili drugi štetni sadržaj u poruci ili njezinim privicima.
# review: new
bounce-virus-detected-do = Provjerite privitke antivirusnim programom. Neki poslužitelji odbijaju svaki program ili arhivu, pa takve datoteke podijelite kao poveznicu.
# review: new
bounce-ip-blocklisted = Vaš poslužitelj e-pošte nalazi se na popisu blokiranih
# review: new
bounce-ip-blocklisted-why = Poslužitelj primatelja odbija poštu s poslužitelja koji je poslao vašu poruku jer je adresa tog poslužitelja na popisu blokiranih.
# review: new
bounce-ip-blocklisted-do = Problem nije u poruci. Proslijedite ovu obavijest svojem davatelju usluge e-pošte i zamolite ga da poslužitelj ukloni s popisa.
# review: new
bounce-domain-blocklisted = Domena se nalazi na popisu blokiranih
# review: new
bounce-domain-blocklisted-why = Poslužitelj primatelja odbija poruku jer je domena vaše adrese ili domena iz poveznica u poruci na popisu blokiranih.
# review: new
bounce-domain-blocklisted-do = Ako poruka sadrži poveznice, pokušajte je poslati bez njih. U suprotnom proslijedite ovu obavijest osobi koja upravlja e-poštom vaše domene.
# review: new
bounce-policy-blocked = Odbijeno prema pravilima poslužitelja primatelja
# review: new
bounce-policy-blocked-why = Pravila poslužitelja primatelja ne propuštaju ovu poruku, na primjer zbog njezine veličine, privitaka ili pošiljatelja.
# review: new
bounce-policy-blocked-do = Razlog se često vidi u porukama samog poslužitelja u odjeljku Pojedinosti. Pitajte primatelja može li primati takvu poštu.
# review: new
bounce-geo-blocked = Odbijeno zbog mjesta odakle je stigla
# review: new
bounce-geo-blocked-why = Poslužitelj primatelja ne prima poštu iz zemlje ili mreže u kojoj je vaš poslužitelj e-pošte.
# review: new
bounce-geo-blocked-do = Javite se osobi na drugi način ili se obratite svojem davatelju usluge e-pošte.
# review: new
bounce-relay-denied = Poslužitelj je nije htio proslijediti
# review: new
bounce-relay-denied-why = Poslužitelj je odbio isporučiti poruku dalje, često zato što je poslana bez prijave ili preko poslužitelja koji ne poslužuje ovog primatelja.
# review: new
bounce-relay-denied-do = Provjerite poslužitelj za odlaznu poštu računa u izborniku Datoteka > Računi i prijavljuje li se on.
# review: new
bounce-auth-failure = Adresu pošiljatelja nije moguće potvrditi
# review: new
bounce-auth-failure-why = Poslužitelj primatelja nije mogao potvrditi da je poruka zaista stigla s vaše domene (SPF, DKIM ili DMARC).
# review: new
bounce-auth-failure-do = Proslijedite ovu obavijest osobi koja upravlja e-poštom vaše domene: njezine postavke treba ispraviti. U međuvremenu može pomoći slanje preko poslužitelja vašeg davatelja usluge.
# review: new
bounce-rate-limited = Previše pošte odjednom
# review: new
bounce-rate-limited-why = Poslužitelj primatelja zasad prima manje poruka s vašeg poslužitelja e-pošte.
# review: new
bounce-rate-limited-do = Pričekajte neko vrijeme i pošaljite je ponovno. Kad pišete mnogim ljudima, šaljite manjem broju odjednom.
# review: new
bounce-greylisting = Zadržano na trenutak
# review: new
bounce-greylisting-why = Poslužitelj primatelja traži od nepoznatih pošiljatelja da pokušaju malo kasnije, što je uobičajena zaštita od neželjene pošte.
# review: new
bounce-greylisting-do = Ništa. Poslužitelji e-pošte sami pokušavaju ponovno i poruka se obično isporuči unutar sat vremena.
# review: new
bounce-server-error = Poslužitelj primatelja imao je problem
# review: new
bounce-server-error-why = Poslužitelj primatelja nije bio dostupan ili nije mogao primiti poruku zbog vlastitog problema.
# review: new
bounce-server-error-do = Pošaljite je ponovno kasnije. Ako i dalje ne uspijeva, provjerite ima li pogrešaka u dijelu adrese iza znaka @.
# review: new
bounce-unknown = Nije isporučeno
# review: new
bounce-unknown-why = Obavijest ne navodi jasno zašto.
# review: new
bounce-unknown-do = Poruka samog poslužitelja u odjeljku Pojedinosti možda govori više. Ako ne pomogne, proslijedite ovu obavijest svojem davatelju usluge e-pošte.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } odabrana poruka
    [few] { $count } odabrane poruke
   *[other] { $count } odabranih poruka
}
# review: new
selection-unread = Nepročitano: { $count }
# review: new
selection-flagged = Označeno zastavicom: { $count }
# review: new
delete-for-good-one = Ova će se poruka trajno izbrisati. Izbrisati je?
# review: new
delete-for-good-all = Ove će se poruke ({ $count }) trajno izbrisati. Izbrisati ih?
# review: new
delete-for-good-some = Trajno će se izbrisati { $count } od ukupno { $total } poruka. Izbrisati poruke?
# review: new
done-read = { $count ->
   *[other] Označeno kao pročitano: { $messages }
}
# review: new
done-unread = { $count ->
   *[other] Označeno kao nepročitano: { $messages }
}
# review: new
done-flagged = { $count ->
   *[other] Označeno zastavicom: { $messages }
}
# review: new
done-unflagged = Uklonjena zastavica: { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Trajno izbrisano: { $messages }
}
# review: new
done-archived = { $count ->
   *[other] Arhivirano: { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Premješteno: { $messages } (odredište: { $folder })
}
# review: new
done-copied = { $count ->
   *[other] Kopirano: { $messages } (odredište: { $folder })
}
# review: new
done-moving = { $count ->
   *[other] Premještanje: { $messages } (odredište: { $folder })...
}
# review: new
done-copying = { $count ->
   *[other] Kopiranje: { $messages } (odredište: { $folder })...
}
# review: new
done-moved-back = { $count ->
   *[other] Vraćeno: { $messages } (odredište: { $folder })
}
# review: new
done-watched = { $count ->
    [1] Pratite razgovor
    [one] Pratite { $count } razgovor
   *[other] Pratite { $count } razgovora
}
# review: new
done-unwatched = { $count ->
    [1] Više ne pratite razgovor
    [one] Više ne pratite { $count } razgovor
   *[other] Više ne pratite { $count } razgovora
}
# review: new
done-ignored = { $count ->
    [1] Zanemarujete razgovor
    [one] Zanemarujete { $count } razgovor
   *[other] Zanemarujete { $count } razgovora
}
# review: new
done-unignored = { $count ->
    [1] Više ne zanemarujete razgovor
    [one] Više ne zanemarujete { $count } razgovor
   *[other] Više ne zanemarujete { $count } razgovora
}
# review: new
their-folders = njihove izvorne mape
# review: new
undo-move = Poništi premještanje
# review: new
undo-delete = Poništi brisanje
# review: new
undo-archive = Poništi arhiviranje
# review: new
undo-junk = Poništi označavanje kao neželjeno
# review: new
undo-not-junk = Poništi označavanje kao poželjno
# review: new
undo-send = Poništi slanje
# review: new
nothing-to-undo = Nema se što poništiti.
# review: new
messages-gone = Poruke više nisu ovdje.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Ova mapa ne može sadržavati poruke.
# review: new
not-archived-here = Poruke u ovoj mapi ne mogu se arhivirati.
# review: new
not-emptied-here = Mogu se isprazniti samo mape Izbrisane stavke i Neželjena e-pošta.
# review: new
next-unread-question = U mapi { $folder } nema više nepročitanih poruka.

    Prijeći u mapu { $next }, sljedeću mapu s nepročitanim porukama?
# review: new
no-unread-left = Nema više nepročitanih poruka.
# review: new
empty-question = { $count ->
    [1] Isprazniti mapu { $folder }?

        Poruka u njoj trajno će se izbrisati. Neće se moći vratiti.
   *[other] Isprazniti mapu { $folder }?

        Sve poruke u njoj ({ $messages }) trajno će se izbrisati. Neće se moći vratiti.
}
# review: new
no-junk-folder = Ovaj račun nema mapu Neželjena e-pošta u koju bi se poruke premjestile.
# review: new
no-inbox-folder = Ovaj račun nema mapu Ulazna pošta u koju bi se poruke premjestile.
# review: new
done-flagged-color = Označeno zastavicom: { $messages }, boja: { $color ->
    [red] crvena
    [orange] narančasta
    [yellow] žuta
    [green] zelena
    [blue] plava
    [purple] ljubičasta
   *[gray] siva
}
# review: new
flag-color = { $color ->
    [red] Crvena
    [orange] Narančasta
    [yellow] Žuta
    [green] Zelena
    [blue] Plava
    [purple] Ljubičasta
   *[gray] Siva
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [1] Premjesti poruku
    [one] Premjesti { $count } poruku
    [few] Premjesti { $count } poruke
   *[other] Premjesti { $count } poruka
}
# review: new
move-window-title-copy = { $count ->
    [1] Kopiraj poruku
    [one] Kopiraj { $count } poruku
    [few] Kopiraj { $count } poruke
   *[other] Kopiraj { $count } poruka
}
# review: new
move-window-prompt-move = { $count ->
    [1] Premjesti odabranu poruku u:
    [one] Premjesti { $count } odabranu poruku u:
    [few] Premjesti { $count } odabrane poruke u:
   *[other] Premjesti { $count } odabranih poruka u:
}
# review: new
move-window-prompt-copy = { $count ->
    [1] Kopiraj odabranu poruku u:
    [one] Kopiraj { $count } odabranu poruku u:
    [few] Kopiraj { $count } odabrane poruke u:
   *[other] Kopiraj { $count } odabranih poruka u:
}
# review: new
targets-recent = Nedavno korišteno
# review: new
target-current = { $folder } (trenutačna)
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Premještanje: { $done } od { $messages } (odredište: { $folder })...
# review: new
transfer-copying = Kopiranje: { $done } od { $messages } (odredište: { $folder })...
# review: new
transfer-another-account = drugi račun
# review: new
transfer-folder-gone = odredišna mapa više ne postoji
# review: new
transfer-not-on-server = poruka više nije na poslužitelju
# review: new
transfer-not-moved = { $count ->
   *[other] Nije moguće premjestiti na drugi račun ({ $messages }): { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] Nije moguće kopirati na drugi račun ({ $messages }): { $reason }
}
# review: new
transfer-none-moved = Nijedna poruka nije premještena
# review: new
transfer-none-copied = Nijedna poruka nije kopirana

## Messages as files

# review: new
export-not-in-time = poruku nije bilo moguće preuzeti na vrijeme
# review: new
export-not-saved = Nije spremljeno: { $failed } od { $messages } ({ $problems })
# review: new
export-not-attached = poruke nije moguće priložiti: { $error }
# review: new
saved-to = { $count ->
   *[other] Spremljeno u mapu { $folder }: { $messages }
}
# review: new
download-progress = Preuzimanje: { $done } od { $total }
# review: new
download-done = Preuzeto: { $size }
# review: new
downloading-messages = { $count ->
   *[other] Preuzimanje: { $messages }...
}
# review: new
import-put = { $count ->
   *[other] Stavljeno u mapu { $folder }: { $messages }
}
# review: new
import-not-put = Ove datoteke nisu stavljene u mapu:

    { $problems }

## Problems the windows show

# review: new
error-store = lokalna pohrana: { $error }
# review: new
error-not-found = nije pronađeno
# review: new
error-closed = zatvaranje u tijeku
# review: new
error-other-account = preglednik se prijavio na račun { $email }, a ne na ovaj račun
# review: new
failure-authentication = poslužitelj nije prihvatio prijavu ({ $reason })
# review: new
failure-network = veza s poslužiteljem nije uspjela ({ $reason })
# review: new
error-in-use = ne može se ukloniti dok se njome prijavljuju računi: { $accounts }
# review: new
error-turned-off = ova je aplikacija za prijavu isključena za nove račune
# review: new
error-folder-name = naziv mape mora imati od 1 do 200 znakova i ne smije sadržavati kontrolne znakove
# review: new
error-folder-separator = na ovom poslužitelju naziv mape ne smije sadržavati „{ $separator }“
# review: new
error-folder-special = mapa Ulazna pošta i posebne mape ne mogu se preimenovati ni izbrisati
# review: new
error-no-recipients = poruka nema primatelja
# review: new
error-bad-address = „{ $address }“ nije adresa e-pošte
# review: new
error-not-own-address = { $address } nije jedna od adresa pošiljatelja ovog računa. Dodajte je u polje „Druge adrese s kojih šaljete“ u svojstvima računa.
# review: new
rule-query-refused = Pravila ne mogu filtrirati po mapi ni datumu ({ $words }).
# review: new
rule-no-query = Unesite kriterije pretraživanja za dolazne poruke.
# review: new
rule-no-action = Odaberite barem jednu radnju za pravilo.
# review: new
error-attachment = Datoteku { $path } nije moguće pročitati: { $error }
# review: new
error-no-drafts = račun nema mapu Skice u koju bi se poruka spremila
# review: new
error-draft-attachment = privitak skice nije moguće zadržati: { $error }
# review: new
error-password-not-saved = lozinku nije moguće spremiti za sljedeće pokretanje: { $error }
# review: new
error-sign-in-not-saved = nove podatke za prijavu nije moguće spremiti za sljedeće pokretanje: { $error }
# review: new
error-import-unreadable = Datoteka { $path } ne može se pročitati: { $error }
# review: new
error-import-too-large = Datoteka { $path } veća je od 50 MB
# review: new
error-import-not-mail = Datoteka { $path } nije poruka e-pošte
# review: new
error-list-answered = poslužitelj popisa za slanje vratio je status { $status }
# review: new
error-not-built = poruku nije moguće sastaviti
# review: new
error-outbox-waits = { $count ->
    [1] poruka čeka u mapi Izlazna pošta i poslat će se pri sljedećem slanju i primanju
    [one] { $count } poruka čeka u mapi Izlazna pošta i poslat će se pri sljedećem slanju i primanju
    [few] { $count } poruke čekaju u mapi Izlazna pošta i poslat će se pri sljedećem slanju i primanju
   *[other] { $count } poruka čeka u mapi Izlazna pošta i poslat će se pri sljedećem slanju i primanju
}
# review: new
error-draft-not-removed = raniju skicu poruke nije moguće ukloniti iz mape Skice: { $reason }
# review: new
error-sent-but = poruka je poslana, ali { $problem }
# review: new
error-sent-still-in-outbox = još je u mapi Izlazna pošta: { $error }
# review: new
error-sent-no-copy = kopiju nije moguće spremiti u poslane stavke: { $reason }
# review: new
error-no-password = nema lozinke za ovaj račun
# review: new
error-no-sign-in = nema podataka za prijavu za ovaj račun
# review: new
error-provider-missing = ova se verzija ne može prijaviti kod davatelja { $provider }: je li njegova aplikacija za prijavu uklonjena?
# review: new
error-provider-servers = poslužitelji ovog računa ne odgovaraju poslužiteljima njegove aplikacije za prijavu
# review: new
error-app-scopes = { $reason }. Poslužitelj e-pošte nije prihvatio token aplikacije za prijavu: provjerite daju li dozvole (scopes) aplikacije pristup pošti
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google još nije potvrdio Inbox Classic, pa dopušta prijavu samo testnim korisnicima. Koristite vlastitu Googleovu aplikaciju za prijavu ili lozinku za aplikaciju, ili je uključite u prozoru Aplikacije za prijavu (Datoteka > Računi) ako ste testni korisnik.
# review: new
sign-in-off-other = Isključena je u prozoru Aplikacije za prijavu (Datoteka > Računi), gdje se može ponovno uključiti.
# review: new
sign-in-app-no-name = aplikacija za prijavu mora imati naziv
# review: new
sign-in-app-no-client = nedostaje ID klijenta
# review: new
sign-in-app-no-scopes = aplikacija za prijavu treba dozvole (scopes) koje daju pristup pošti
# review: new
sign-in-app-bad-host = adresa poslužitelja { $server } nedostaje ili nije valjan naziv glavnog računala
# review: new
sign-in-app-plain = poslužitelj { $server } mora koristiti SSL/TLS ili STARTTLS
# review: new
sign-in-app-not-checked = izdavatelj još nije provjeren
# review: new
sign-in-app-issuer-changed = izdavatelj se promijenio: ponovno upišite tajnu klijenta ili je uklonite
# review: new
sign-in-register-google = U konzoli Google Cloud Console stvorite OAuth klijent vrste Desktop app s dozvolom https://mail.google.com/ na zaslonu za pristanak. Dok je aplikacija u fazi testiranja, prijaviti se mogu samo njezini testni korisnici.
# review: new
sign-in-register-microsoft = U servisu Microsoft Entra registrirajte aplikaciju s platformom Mobile and desktop applications, URI-jem za preusmjeravanje http://localhost, dopuštenim tokovima javnog klijenta i delegiranim dozvolama IMAP.AccessAsUser.All, SMTP.Send i offline_access. Samo za svoju tvrtku ili ustanovu kao izdavatelja koristite https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Registrirajte izvorni (javni) klijent s URI-jem za preusmjeravanje navedenim u nastavku; davatelj mora na njemu dopustiti bilo koji priključak (RFC 8252). Dodajte dozvolu kojom davatelj daje pristup pošti.

## Calendar invitations

# review: new
repeats = Ponavlja se
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Svaki dan
        [one] Svakih { $interval } dan
        [few] Svaka { $interval } dana
       *[other] Svakih { $interval } dana
    }
    [week] { $interval ->
        [1] Svaki tjedan
        [one] Svakih { $interval } tjedan
        [few] Svaka { $interval } tjedna
       *[other] Svakih { $interval } tjedana
    }
    [month] { $interval ->
        [1] Svaki mjesec
        [one] Svakih { $interval } mjesec
        [few] Svaka { $interval } mjeseca
       *[other] Svakih { $interval } mjeseci
    }
   *[year] { $interval ->
        [1] Svake godine
        [one] Svake { $interval } godine
        [few] Svake { $interval } godine
       *[other] Svakih { $interval } godina
    }
}
# "Every week: Monday, Wednesday"
# review: new
repeats-on = { $repeats }: { $days }
# review: new
repeats-times = { $count ->
    [1] { $repeats }, jednom
    [one] { $repeats }, { $count } put
    [few] { $repeats }, { $count } puta
   *[other] { $repeats }, { $count } puta
}
# review: new
day-monday = ponedjeljak
# review: new
day-tuesday = utorak
# review: new
day-wednesday = srijeda
# review: new
day-thursday = četvrtak
# review: new
day-friday = petak
# review: new
day-saturday = subota
# review: new
day-sunday = nedjelja

## AI agents

# review: new
agent-level-read = Čitanje pošte: mape, popis poruka, pretraživanje i poruke
# review: new
agent-level-organize = Organiziranje pošte: stanje pročitanosti, zastavice, neželjena pošta, premještanje, brisanje u Izbrisane stavke
# review: new
agent-level-drafts = Pisanje skica koje ćete vi poslati
# review: new
agent-level-send = Slanje pošte, svake poruke tek nakon vašeg odobrenja
# review: new
agent-connect-title = { $program } želi koristiti vašu poštu
# review: new
agent-connect-detail = AI agent zatražio je rad s programom Inbox Classic. Odaberite što smije raditi i koje račune smije vidjeti; to možete kasnije promijeniti u izborniku Alati > AI agenti.

    Agenti čitaju poštu koju su napisali drugi ljudi, a poruka ih može pokušati prevariti. Inbox Classic uvijek vas pita prije nego što agent bilo što pošalje.
# review: new
agent-reply-to = Odgovor na „{ $subject }“
# review: new
agent-reply-all-on = Odgovor svima na „{ $subject }“
# review: new
agent-forward-of = Prosljeđivanje poruke „{ $subject }“
# review: new
agent-never-written-one = Nikad niste pisali adresi { $address }.
# review: new
agent-never-written-many = Na neke od ovih adresa ({ $count }) nikad niste pisali.
# review: new
agent-send-title = { $program } želi poslati ovu poruku
# review: new
agent-send-detail = Provjerite primatelje i sadržaj poruke. Kad potvrdite, poruka čeka u mapi Izlazna pošta još { $seconds } s, a za to je vrijeme još možete izbrisati.
# review: new
agent-change-title = Što smije { $program }
# review: new
agent-change-allowed = Promijenite što AI agenti ovog programa smiju raditi s vašom poštom.
# review: new
agent-change-refused = Odbili ste pristup ovom programu. Dopustite ga kako bi njegovi agenti ponovno dobili pristup vašoj pošti.
# review: new
agent-log-taken-back = { $entry } (poništeno)
# review: new
agent-files = Datoteke: { $files }
# review: new
agent-undo-refused = Ne može se poništiti.
# review: new
agent-undo-refused-why = Ne može se poništiti: { $reason }.
# review: new
agent-undo-impossible = ovo se ne može poništiti
# review: new
agent-undo-not-in-folder = poruka više nije u toj mapi
# review: new
agent-undo-not-arrived = poruka (još) nije u mapi u koju je premještena
# review: new
agent-undo-sent = poruka je već poslana
# review: new
agent-original-not-downloaded = izvorna poruka još nije preuzeta. Najprije je otvorite
# review: new
agent-turned-away = Odbijeno
# review: new
agent-can-nothing = Ništa
# review: new
agent-can-read = čitanje
# review: new
agent-can-organize = organiziranje
# review: new
agent-can-drafts = pisanje skica
# review: new
agent-can-send = slanje uz vaše odobrenje
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first } i { $last }
# review: new
agent-accounts = { $count ->
    [0] nijedan račun
    [one] { $count } račun
    [few] { $count } računa
   *[other] { $count } računa
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Ova se poruka ne može pročitati.
# review: new
agent-encrypted-original = Ova je poruka šifrirana: agent na nju ne može odgovoriti niti je proslijediti jer ne može šifrirati.
# review: new
agent-encrypted = Ova je poruka šifrirana. Može je pročitati samo korisnik, u aplikaciji Inbox Classic.
# review: new
list-encrypted = Šifrirana poruka
# review: new
agent-log-composed = Poruka „{ $subject }“ otvorena je kao nova poruka koju ćete dovršiti
# review: new
agent-log-refused = Niste poslali poruku „{ $subject }“
# review: new
agent-log-sent = Poruka „{ $subject }“ poslana je na { $to }
# review: new
agent-log-draft = Spremljena skica „{ $subject }“
# review: new
agent-log-read = Označeno kao pročitano: „{ $subject }“
# review: new
agent-log-unread = Označeno kao nepročitano: „{ $subject }“
# review: new
agent-log-flagged = Označeno zastavicom: „{ $subject }“
# review: new
agent-log-unflagged = Uklonjena zastavica: „{ $subject }“
# review: new
agent-log-deleted = Izbrisano: „{ $subject }“
# review: new
agent-log-moved = Premješteno: „{ $subject }“ (odredište: { $folder })
# review: new
agent-log-junk = Označeno kao neželjeno: „{ $subject }“
# review: new
agent-log-not-junk = Označeno kao poželjno: „{ $subject }“
# review: new
agent-log-archived = Arhivirano: „{ $subject }“
# review: new
agent-log-folder = Stvorena mapa „{ $name }“
# review: new
agent-log-unsubscribed = Otkazana pretplata na popis poruke „{ $subject }“

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
sign-in-no-refresh = davatelj nije dao token za osvježavanje
# review: new
sign-in-no-account = davatelj nije naveo koji se račun prijavio
# review: new
sign-in-not-finished = prijava nije dovršena
# review: new
secrets-unavailable = { $store } nije dostupan
# review: new
secrets-unavailable-why = { $store } nije dostupan: { $error }
# review: new
secrets-windows = Upravitelj vjerodajnicama
# review: new
secrets-mac = privjesak ključeva
# review: new
secrets-linux = sustavski privjesak ključeva (Secret Service)
# review: new
error-no-such-file = ta datoteka ne postoji
# review: new
cards-file-too-big = Ova je datoteka prevelika da bi bila adresar.
# review: new
ui-sender-added = { $name } dodan je u Adresar.
# review: new
ui-sender-known = { $name } već je u Adresaru.
# review: new
ui-sender-none = Pošiljatelj ove poruke nema adresu e-pošte koja bi se mogla dodati.
# review: new
card-name-needed = Kontakt nema ni ime ni adresu e-pošte.
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# review: new
otp-heading = Kôd s domene { $domain }
# review: new
otp-copy = Kopiraj
# review: new
otp-note = Unesite ga samo na stranici domene { $domain }.
# review: new
otp-old = Ovaj je kôd poslan više od sat vremena prije nego što ste ga otvorili i vjerojatno je istekao.

# review: new
event-attendees =
    { $count ->
        [one] { $count } sudionik
        [few] { $count } sudionika
       *[other] { $count } sudionika
    }

# review: new
otp-notification = { $code } vaš je kôd za { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Valjan
# review: new
pgp-key-expires = Valjan do { $date }
# review: new
pgp-key-expired = Istekao { $date }
# review: new
pgp-key-revoked = Opozvan
# review: new
pgp-key-revoked-why = Opozvan: { $reason }
# review: new
pgp-key-not-valid = Nije valjan
# review: new
pgp-key-locked = Ne može se koristiti: ključ koji ga štiti više nije spremljen ({ $store }). Ponovno uvezite njegovu sigurnosnu kopiju.
# review: new
pgp-source-own = Stvoren u programu Inbox Classic
# review: new
pgp-source-file = Uvezen iz datoteke
# review: new
pgp-source-paste = Zalijepljen
# review: new
pgp-source-attachment = Iz poruke
# review: new
pgp-source-vcard = Iz kartice kontakta
# review: new
pgp-source-wkd = Od davatelja usluge e-pošte pošiljatelja
# review: new
pgp-source-keyserver = S poslužitelja keys.openpgp.org
# review: new
pgp-source-autocrypt = Iz zaglavlja Autocrypt poruke
# review: new
pgp-error-no-store = Privatne ključeve štiti { $store }, koji se ne može koristiti: { $error }
# review: new
pgp-error-wrong-passphrase = Pristupna fraza nije točna.
# review: new
pgp-error-not-a-key = Ovo nije ključ OpenPGP.
# review: new
pgp-error-too-large = Ključ je prevelik.
# review: new
pgp-error-unusable = Ključ koristi staru ili slabu kriptografiju i ne može se koristiti.
# review: new
pgp-imported-private = { $count ->
    [1] Vaš privatni ključ je uvezen.
    [one] Uvezen je { $count } privatni ključ.
    [few] Uvezena su { $count } privatna ključa.
   *[other] Uvezeno je { $count } privatnih ključeva.
}
# review: new
pgp-imported-public = { $count ->
    [1] Uvezen je jedan ključ.
    [one] Uvezen je { $count } ključ.
    [few] Uvezena su { $count } ključa.
   *[other] Uvezeno je { $count } ključeva.
}
# review: new
pgp-imported-pending = Za { $addresses } već se koristi drugi ključ: novi čeka u kontaktu dok ga ne odaberete.
# review: new
pgp-error-needs-passphrase = Privatni ključ zaštićen je pristupnom frazom. Upišite je da biste uvezli ključ.
# review: new
pgp-error-mismatch = Privatni ključ ne pripada svojem javnom ključu. Možda je izmijenjen.
# review: new
pgp-file-name-public = { $who } javni ključ.asc
# review: new
pgp-file-name-private = { $who } sigurnosna kopija privatnog ključa.asc
# review: new
pgp-pending = Drugi ključ za { $address } pronađen je { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Potpisao { $signer }, ključ provjeren
# review: new
pgp-part-signed = Potpisao { $signer } (ključ nije provjeren)
# review: new
pgp-part-other = Potpisao { $signer }, koji nije pošiljatelj
# review: new
pgp-part-unknown-key = Potpisano, ali ključ nije poznat
# review: new
pgp-part-not-signed = Nije potpisano
# review: new
pgp-part-not-checked = Potpis nije provjeren
# review: new
pgp-part-encrypted = Šifrirano. { $signature }
# review: new
pgp-part-no-key = Šifrirano za ključ koji nemate
# review: new
pgp-part-changed = Šifrirani dio promijenjen je usput i ne prikazuje se
# review: new
pgp-part-unprotected = Šifrirano bez zaštite od izmjena, ne prikazuje se
# review: new
pgp-part-broken = Šifrirani dio ne može se pročitati
# review: new
pgp-why-mismatch = Potpis ne odgovara ovom tekstu
# review: new
pgp-why-weak-hash = Potpis koristi { $hash }, koji više nije siguran
# review: new
pgp-why-key-expired = Potpisano nakon što je ključ istekao { $date }
# review: new
pgp-why-key-revoked = Potpisano opozvanim ključem
# review: new
pgp-why-not-signing-key = Potpisano ključem koji ne smije potpisivati
# review: new
pgp-why-from-future = Potpis ima datum u budućnosti
# review: new
pgp-why-signature-expired = Potpis je istekao
# review: new
pgp-why-key-not-valid = Potpisano ključem koji nije valjan
# review: new
pgp-why-not-for-you = Potpisano za druge primatelje i proslijeđeno vama
# review: new
pgp-part-pictures-loaded = { $label }. Slike su učitane s interneta
# review: new
pgp-error-no-own-key = Nemate ključ za { $address } kojim biste potpisivali ili šifrirali. Stvorite ga u izborniku Alati > Ključevi za šifriranje ili isključite Potpiši i Šifriraj.
# review: new
pgp-error-missing-keys = { $count ->
    [1] { $addresses } nema ključ za šifriranje.
   *[other] Ovi primatelji nemaju ključ za šifriranje: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Ova poruka citira ili prosljeđuje šifriranu poruku, pa se može poslati samo šifrirana. Uključite Šifriraj ili uklonite citirani tekst.
# review: new
pgp-error-protect = Poruku nije moguće potpisati ni šifrirati: { $reason }
# review: new
pgp-found-keys = Pronađen je ključ za: { $addresses }.
# review: new
pgp-found-none = Nije pronađen ključ za: { $addresses }. Zamolite ih da vam pošalju svoj javni ključ.
# review: new
pgp-found-no-key = Nije pronađen nijedan ključ.
# review: new
pgp-find-unavailable = Ključeve sada nije moguće potražiti: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org poslao je poveznicu za potvrdu na { $addresses }. Vaš će se ključ ondje objaviti kad je kliknete.
# review: new
pgp-publish-done = Vaš je ključ objavljen na keys.openpgp.org za { $addresses }.
# review: new
pgp-publish-failed = Ključ nije moguće objaviti: { $error }
# review: new
pgp-keyserver-off = Traženje ključeva na keys.openpgp.org isključeno je u Mogućnostima.
# review: new
pgp-details-part = Dio { $number }: { $label }
# review: new
pgp-details-signed = Potpisano { $when } ključem { $key }
# review: new
pgp-details-unknown-key = Potpisano ključem { $key }, koji nemate
# review: new
pgp-details-opened = Šifrirano za vaš ključ { $key }
# review: new
pgp-details-for = Šifrirano za { $keys }
# review: new
pgp-details-plain = Nije potpisano ni šifrirano
# review: new
pgp-bar-parts = Ova poruka ima više dijelova ({ $count }): { $list }. Za svaki je dio navedeno kako je zaštićen.
# review: new
pgp-bar-count-verified = Provjereno: { $count }
# review: new
pgp-bar-count-good = { $count ->
    [one] { $count } potpisan ili šifriran
    [few] { $count } potpisana ili šifrirana
   *[other] { $count } potpisanih ili šifriranih
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] { $count } traži pažnju
    [few] { $count } traže pažnju
   *[other] { $count } traži pažnju
}
# review: new
pgp-bar-count-neutral = Bez potvrđenog potpisa: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Postavke
# review: new
setup-part-preferences = Postavke prozora
# review: new
setup-part-accounts = Računi
# review: new
setup-part-sign-in-apps = Aplikacije za prijavu
# review: new
setup-part-contacts = Kontakti i grupe
# review: new
setup-part-keys = Ključevi za šifriranje
# review: new
setup-part-rules = Pravila za poruke
# review: new
setup-part-trusted-senders = Pouzdani pošiljatelji
# review: new
setup-holds-settings = { $count ->
    [one] { $count } postavka
    [few] { $count } postavke
   *[other] { $count } postavki
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } postavka prozora
    [few] { $count } postavke prozora
   *[other] { $count } postavki prozora
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } račun
    [few] { $count } računa
   *[other] { $count } računa
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavu
    [few] { $count } aplikacije za prijavu
   *[other] { $count } aplikacija za prijavu
}
# review: new
setup-holds-built-in = Koje su ugrađene aplikacije za prijavu uključene
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } kontakt
    [few] { $count } kontakta
   *[other] { $count } kontakata
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } grupa
    [few] { $count } grupe
   *[other] { $count } grupa
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } vlastiti ključ
    [few] { $count } vlastita ključa
   *[other] { $count } vlastitih ključeva
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } ključ kontakta
    [few] { $count } ključa kontakata
   *[other] { $count } ključeva kontakata
}
# review: new
setup-holds-rules = { $count ->
    [one] { $count } pravilo
    [few] { $count } pravila
   *[other] { $count } pravila
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] { $count } pouzdani pošiljatelj
    [few] { $count } pouzdana pošiljatelja
   *[other] { $count } pouzdanih pošiljatelja
}
# review: new
setup-sign-in-password = Lozinka
# review: new
setup-account-secret-password = Njegova je lozinka u datoteci.
# review: new
setup-account-secret-token = Njegovi su podaci za prijavu u datoteci.
# review: new
setup-account-asks-password = Nakon uvoza tražit će lozinku.
# review: new
setup-account-signs-in-again = Nakon uvoza ponovno ćete se prijaviti u njega.
# review: new
setup-account-here = Ovdje je već postavljen, pa se preskače.
# review: new
setup-account-no-app = Prijavljuje se aplikacijom { $app }, koja ovdje nije postavljena. Uvezite i aplikacije za prijavu.
# review: new
setup-invalid-address = „{ $address }“ nije adresa e-pošte.
# review: new
setup-invalid-server = Poslužitelj { $server } nema upotrebljiv naziv ili priključak.
# review: new
setup-invalid-user = Nema korisničkog imena.
# review: new
setup-invalid-sign-in = Prijavljuje se na način koji Inbox Classic ne poznaje.
# review: new
setup-error-empty = Datoteka je prazna.
# review: new
setup-error-too-large = Datoteka je prevelika da bi bila postava programa Inbox Classic.
# review: new
setup-error-not-setup = Ova datoteka nije postava programa Inbox Classic.
# review: new
setup-error-damaged = Datoteka postave je oštećena i ne može se pročitati.
# review: new
setup-error-newer = Ovu je postavu spremila novija verzija programa Inbox Classic ({ $version }). Ažurirajte Inbox Classic pa je ponovno uvezite.
# review: new
setup-error-needs-passphrase = Ova je postava zaštićena pristupnom frazom. Upišite pristupnu frazu s kojom je spremljena.
# review: new
setup-error-wrong-passphrase = To nije pristupna fraza s kojom je ova postava spremljena.
# review: new
setup-error-changed = Datoteka postave promijenjena je ili oštećena nakon spremanja, pa se ne može uvesti.
# review: new
setup-error-read = Datoteku postave nije moguće pročitati: { $error }
# review: new
setup-error-write = Postavu nije moguće spremiti: { $error }
# review: new
setup-error-no-parts = Odaberite barem jedan dio.
# review: new
setup-left-out = { $count ->
    [one] { $count } stavka (dio: { $part }) ne može se koristiti i izostavljena je.
    [few] { $count } stavke (dio: { $part }) ne mogu se koristiti i izostavljene su.
   *[other] { $count } stavki (dio: { $part }) ne može se koristiti i izostavljeno je.
}
# review: new
setup-imported-settings = Postavke su zamijenjene.
# review: new
setup-imported-preferences = Postavke prozora su zamijenjene.
# review: new
setup-added-accounts = { $count ->
    [one] Dodan je { $count } račun.
    [few] Dodana su { $count } računa.
   *[other] Dodano je { $count } računa.
}
# review: new
setup-skipped-here = { $address } ovdje je već postavljen, pa je preskočen.
# review: new
setup-skipped-no-app = { $address } je preskočen: prijavljuje se aplikacijom { $app }, koja ovdje nije postavljena.
# review: new
setup-skipped-invalid = { $address } je preskočen: { $reason }
# review: new
setup-asks-password = { $address } tražit će lozinku kad se poveže.
# review: new
setup-signs-in-again = { $address } tražit će da se ponovno prijavite kad se poveže.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Dodana je { $count } aplikacija za prijavu.
    [few] Dodane su { $count } aplikacije za prijavu.
   *[other] Dodano je { $count } aplikacija za prijavu.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavu ovdje je već postavljena.
    [few] { $count } aplikacije za prijavu ovdje su već postavljene.
   *[other] { $count } aplikacija za prijavu ovdje je već postavljeno.
}
# review: new
setup-added-contacts = { $count ->
    [one] U adresar je dodan { $count } kontakt.
    [few] U adresar su dodana { $count } kontakta.
   *[other] U adresar je dodano { $count } kontakata.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } kontakt već je u adresaru.
    [few] { $count } kontakta već su u adresaru.
   *[other] { $count } kontakata već je u adresaru.
}
# review: new
setup-added-groups = { $count ->
    [one] Dodana ili dopunjena je { $count } grupa.
    [few] Dodane ili dopunjene su { $count } grupe.
   *[other] Dodano ili dopunjeno je { $count } grupa.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Dodan je { $count } vlastiti ključ.
    [few] Dodana su { $count } vlastita ključa.
   *[other] Dodano je { $count } vlastitih ključeva.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Dodan je { $count } ključ kontakta.
    [few] Dodana su { $count } ključa kontakata.
   *[other] Dodano je { $count } ključeva kontakata.
}
# review: new
setup-added-rules = { $count ->
    [one] Dodano je { $count } pravilo za poruke.
    [few] Dodana su { $count } pravila za poruke.
   *[other] Dodano je { $count } pravila za poruke.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } pravilo za poruke već postoji.
    [few] { $count } pravila za poruke već postoje.
   *[other] { $count } pravila za poruke već postoji.
}
# review: new
setup-skipped-rules-account = { $count ->
    [1] 1 pravilo za poruke odnosi se na račun kojeg ovdje nema, pa je preskočeno.
    [one] { $count } pravilo za poruke odnosi se na račune kojih ovdje nema, pa je preskočeno.
    [few] { $count } pravila za poruke odnose se na račune kojih ovdje nema, pa su preskočena.
   *[other] { $count } pravila za poruke odnosi se na račune kojih ovdje nema, pa je preskočeno.
}
# review: new
setup-rules-waiting = { $count ->
    [1] 1 pravilo za poruke premješta poruke u mapu koja će se pojaviti kad se njezin račun sinkronizira.
    [one] { $count } pravilo za poruke premješta poruke u mape koje će se pojaviti kad se njihovi računi sinkroniziraju.
    [few] { $count } pravila za poruke premještaju poruke u mape koje će se pojaviti kad se njihovi računi sinkroniziraju.
   *[other] { $count } pravila za poruke premješta poruke u mape koje će se pojaviti kad se njihovi računi sinkroniziraju.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Dodan je { $count } pouzdani pošiljatelj.
    [few] Dodana su { $count } pouzdana pošiljatelja.
   *[other] Dodano je { $count } pouzdanih pošiljatelja.
}
# review: new
setup-nothing = Ništa nije uvezeno.
# review: new
setup-account-servers = { $imap } i { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic postavke i računi
# review: new
setup-skipped-unreachable = { $name } je preskočen: njegova usluga prijave nije dostupna. Ponovno ga dodajte u prozoru Aplikacije za prijavu.
# review: new
attachment-runs-programs = Datoteka „{ $name }“ može pokretati programe pa je Inbox Classic ne otvara. Spremite je, a zatim je sami otvorite ako vjerujete njezinu izvoru.
# review: new
attachment-decrypted-note = Ovaj privitak potječe iz šifrirane poruke. Da bi ga otvorio, Inbox Classic ga sprema dešifriranog na ovo računalo, u vašu mapu koju Inbox Classic prazni nakon jednog dana.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Poslužitelj nije premjestio poruku u mapu { $folder }, pa je { $messages } ponovno u mapi { $from }: { $reason }
    [few] Poslužitelj nije premjestio poruke u mapu { $folder }, pa su { $messages } ponovno u mapi { $from }: { $reason }
   *[other] Poslužitelj nije premjestio poruke u mapu { $folder }, pa je { $messages } ponovno u mapi { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Poslužitelj nije izbrisao poruku, pa je { $messages } ponovno u mapi { $from }: { $reason }
    [few] Poslužitelj nije izbrisao poruke, pa su { $messages } ponovno u mapi { $from }: { $reason }
   *[other] Poslužitelj nije izbrisao poruke, pa je { $messages } ponovno u mapi { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Poslužitelj nije arhivirao poruku, pa je { $messages } ponovno u mapi { $from }: { $reason }
    [few] Poslužitelj nije arhivirao poruke, pa su { $messages } ponovno u mapi { $from }: { $reason }
   *[other] Poslužitelj nije arhivirao poruke, pa je { $messages } ponovno u mapi { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Poslužitelj nije označio poruku kao pročitanu, pa je { $messages } ponovno nepročitana: { $reason }
    [few] Poslužitelj nije označio poruke kao pročitane, pa su { $messages } ponovno nepročitane: { $reason }
   *[other] Poslužitelj nije označio poruke kao pročitane, pa je { $messages } ponovno nepročitano: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Poslužitelj nije označio poruku kao nepročitanu, pa je { $messages } ponovno pročitana: { $reason }
    [few] Poslužitelj nije označio poruke kao nepročitane, pa su { $messages } ponovno pročitane: { $reason }
   *[other] Poslužitelj nije označio poruke kao nepročitane, pa je { $messages } ponovno pročitano: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Poslužitelj nije promijenio zastavice poruke, pa { $messages } ostaje kao prije: { $reason }
    [few] Poslužitelj nije promijenio zastavice poruka, pa { $messages } ostaju kao prije: { $reason }
   *[other] Poslužitelj nije promijenio zastavice poruka, pa { $messages } ostaje kao prije: { $reason }
}
