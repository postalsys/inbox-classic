# Hrvatski. Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] { $count } poruka
    [few] { $count } poruke
   *[other] { $count } poruka
}
decimal-separator = ,
size-bytes = { $count ->
    [one] { $count } bajt
    [few] { $count } bajta
   *[other] { $count } bajtova
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Isključeno
send-delay-seconds = { $count ->
    [one] { $count } sekunda
    [few] { $count } sekunde
   *[other] { $count } sekundi
}
list-counts = { $messages }, nepročitano: { $unread }
list-counts-selected = { $messages }, nepročitano: { $unread }, odabrano: { $selected }
list-counts-found = Pronađeno: { $found }, nepročitano: { $unread }
list-counts-found-selected = Pronađeno: { $found }, nepročitano: { $unread }, odabrano: { $selected }
list-counts-none = Nije pronađena nijedna poruka

## Special folders, as Outlook names them

folder-inbox = Ulazna pošta
folder-sent = Poslane stavke
folder-deleted = Izbrisane stavke
folder-drafts = Skice
folder-junk = Neželjena e-pošta
folder-archive = Arhiva

## The reading pane

reader-no-message = Nije odabrana nijedna poruka.
reader-downloading = Preuzimanje poruke…
reader-downloading-detail = Poruka će se pojaviti ovdje kad preuzimanje završi.
reader-downloading-size = Veličina poruke: { $size }. Prikazat će se nakon preuzimanja.
reader-failed = Poruku nije moguće preuzeti
reader-failed-network = Poslužitelj e-pošte nije dostupan ({ $reason }).
reader-failed-sign-in = Poslužitelj e-pošte nije prihvatio prijavu ({ $reason }). Provjerite lozinku ili se ponovno prijavite u izborniku Datoteka > Računi.
reader-failed-security = Vezu s poslužiteljem e-pošte nije moguće zaštititi ({ $reason }).
reader-failed-other = Poslužitelj e-pošte odgovorio je: { $reason }.
reader-retry-note = Inbox Classic pokušat će ponovno preuzeti poruku kad se račun poveže.
reader-unreadable = Ova se poruka ne može prikazati: { $error }
message-source-title = Izvorni kod poruke: { $subject }
message-source-untitled = Izvorni kod poruke

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Od
header-date = Datum
header-to = Za
header-cc = Kopija
header-sent = Poslano
header-subject = Predmet
header-security = Sigurnost
header-part = Dio { $number }
quote-original = ----- Izvorna poruka -----
fold-show-earlier = Prikaži ranije poruke

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Vaša poruka nije isporučena
bounce-delayed = Vaša poruka još nije isporučena
bounce-delayed-note = Vaš poslužitelj e-pošte još je pokušava isporučiti. Ne morate je ponovno slati.
bounce-show-message = Prikaži vraćenu poruku
bounce-show-delayed = Prikaži odgođenu poruku
bounce-what-to-do = Što možete učiniti:
bounce-delayed-do = Zasad ništa. Ako se i dalje ne bude mogla isporučiti, dobit ćete novu obavijest.
bounce-delayed-row-do = Zasad ništa. Vaš poslužitelj e-pošte još je pokušava isporučiti, a ako ne uspije, dobit ćete novu obavijest.
bounce-details = Pojedinosti
bounce-someone = Primatelj
bounce-server = Poslužitelj: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Izvor obavijesti: { $server }
bounce-retry-minutes = Poslužitelj primatelja zatražio je da se prije sljedećeg pokušaja pričeka { $count ->
    [1] minutu
    [one] { $count } minutu
    [few] { $count } minute
   *[other] { $count } minuta
}.
bounce-retry-hours = Poslužitelj primatelja zatražio je da se prije sljedećeg pokušaja pričeka { $count ->
    [1] sat
    [one] { $count } sat
    [few] { $count } sata
   *[other] { $count } sati
}.
bounce-blocklist = Popis blokiranih: { $lists }
bounce-user-unknown = Adresa ne postoji
bounce-user-unknown-why = Poslužitelj primatelja nema poštanski sandučić s ovom adresom. Možda je pogrešno upisana ili je osoba više ne koristi.
bounce-user-unknown-do = Provjerite je li adresa točno napisana ili pitajte osobu koju adresu sada koristi.
bounce-invalid-address = Adresa nije valjana
bounce-invalid-address-why = Adresa nije u ispravnom obliku za slanje e-pošte.
bounce-invalid-address-do = Provjerite ima li u adresi razmaka, nedostaje li slovo ili dio iza znaka @.
bounce-mailbox-disabled = Poštanski sandučić nije aktivan
bounce-mailbox-disabled-why = Adresa postoji, ali je njezin poštanski sandučić onemogućen ili se više ne koristi.
bounce-mailbox-disabled-do = Javite se osobi na drugi način i pitajte je koju adresu sada koristi.
bounce-mailbox-full = Poštanski sandučić je pun
bounce-mailbox-full-why = U poštanskom sandučiću primatelja nema mjesta za novu poštu.
bounce-mailbox-full-do = Pošaljite je ponovno za nekoliko dana ili obavijestite osobu na drugi način. Veliki privici odbijaju se prvi.
bounce-spam-blocked = Odbijeno kao neželjena pošta
bounce-spam-blocked-why = Poslužitelj primatelja smatrao je poruku neželjenom poštom.
bounce-spam-blocked-do = Pokušajte ponovno poslati poruku bez sadržaja koji bi mogao izgledati kao neželjena pošta, primjerice velikog broja poveznica, skraćenih poveznica ili velikog privitka. Ako se problem ponavlja, obratite se svojem davatelju usluge e-pošte.
bounce-virus-detected = Odbijeno zbog virusa
bounce-virus-detected-why = Poslužitelj primatelja pronašao je virus ili drugi štetni sadržaj u poruci ili njezinim privicima.
bounce-virus-detected-do = Provjerite privitke antivirusnim programom. Neki poslužitelji odbijaju sve programske datoteke ili arhive. Takve datoteke možete podijeliti slanjem poveznice za preuzimanje.
bounce-ip-blocklisted = Vaš poslužitelj e-pošte nalazi se na popisu blokiranih
bounce-ip-blocklisted-why = Poslužitelj primatelja odbija poštu s poslužitelja koji je poslao vašu poruku jer je adresa tog poslužitelja na popisu blokiranih.
bounce-ip-blocklisted-do = Problem nije u poruci. Proslijedite ovu obavijest svojem davatelju usluge e-pošte i zamolite ga da poslužitelj ukloni s popisa.
bounce-domain-blocklisted = Domena se nalazi na popisu blokiranih
bounce-domain-blocklisted-why = Poslužitelj primatelja odbija poruku jer je domena vaše adrese ili domena iz poveznica u poruci na popisu blokiranih.
bounce-domain-blocklisted-do = Ako poruka sadrži poveznice, pokušajte je poslati bez njih. U suprotnom proslijedite ovu obavijest osobi koja upravlja e-poštom vaše domene.
bounce-policy-blocked = Odbijeno prema pravilima poslužitelja primatelja
bounce-policy-blocked-why = Poslužitelj primatelja odbija poruku zbog svojih pravila, primjerice zbog veličine poruke, privitaka ili pošiljatelja.
bounce-policy-blocked-do = Razlog se često vidi u porukama samog poslužitelja u odjeljku Pojedinosti. Pitajte primatelja može li primati takvu poštu.
bounce-geo-blocked = Odbijeno zbog zemlje ili mreže vašeg poslužitelja
bounce-geo-blocked-why = Poslužitelj primatelja ne prima poštu iz zemlje ili mreže u kojoj je vaš poslužitelj e-pošte.
bounce-geo-blocked-do = Javite se osobi na drugi način ili se obratite svojem davatelju usluge e-pošte.
bounce-relay-denied = Poslužitelj je odbio proslijediti poruku
bounce-relay-denied-why = Poslužitelj je odbio proslijediti poruku. To se često događa ako je poruka poslana bez prijave ili preko poslužitelja koji ne obrađuje poštu za tog primatelja.
bounce-relay-denied-do = U izborniku Datoteka > Računi provjerite postavke poslužitelja za odlaznu poštu i koristi li račun prijavu na taj poslužitelj.
bounce-auth-failure = Adresu pošiljatelja nije moguće potvrditi
bounce-auth-failure-why = Poslužitelj primatelja nije mogao potvrditi da je poruka zaista stigla s vaše domene (SPF, DKIM ili DMARC).
bounce-auth-failure-do = Proslijedite ovu obavijest osobi koja upravlja e-poštom vaše domene: njezine postavke treba ispraviti. U međuvremenu može pomoći slanje preko poslužitelja vašeg davatelja usluge.
bounce-rate-limited = Previše pošte odjednom
bounce-rate-limited-why = Poslužitelj primatelja zasad prima manje poruka s vašeg poslužitelja e-pošte.
bounce-rate-limited-do = Pričekajte neko vrijeme i pošaljite je ponovno. Kad pišete mnogim ljudima, šaljite manjem broju odjednom.
bounce-greylisting = Isporuka je privremeno odgođena
bounce-greylisting-why = Poslužitelj primatelja traži od nepoznatih pošiljatelja da pokušaju malo kasnije, što je uobičajena zaštita od neželjene pošte.
bounce-greylisting-do = Ništa. Poslužitelji e-pošte sami pokušavaju ponovno i poruka se obično isporuči unutar sat vremena.
bounce-server-error = Problem na poslužitelju primatelja
bounce-server-error-why = Poslužitelj primatelja nije bio dostupan ili nije mogao primiti poruku zbog vlastitog problema.
bounce-server-error-do = Pošaljite je ponovno kasnije. Ako i dalje ne uspijeva, provjerite ima li pogrešaka u dijelu adrese iza znaka @.
bounce-unknown = Nije isporučeno
bounce-unknown-why = U obavijesti nije jasno naveden razlog neuspjele isporuke.
bounce-unknown-do = Više informacija možda ćete naći u odgovoru poslužitelja u odjeljku Pojedinosti. Ako vam ne pomognu, proslijedite ovu obavijest svojem davatelju usluge e-pošte.

## Several messages selected

selection-title = { $count ->
    [one] { $count } odabrana poruka
    [few] { $count } odabrane poruke
   *[other] { $count } odabranih poruka
}
selection-unread = Nepročitano: { $count }
selection-flagged = Označeno zastavicom: { $count }
delete-for-good-one = Ova će se poruka trajno izbrisati. Želite li je izbrisati?
delete-for-good-all = Odabrane poruke ({ $count }) trajno će se izbrisati. Želite li ih izbrisati?
delete-for-good-some = Broj poruka za trajno brisanje: { $count } od ukupno { $total }. Želite li nastaviti s brisanjem?
done-read = { $count ->
   *[other] Označeno kao pročitano: { $messages }
}
done-unread = { $count ->
   *[other] Označeno kao nepročitano: { $messages }
}
done-flagged = { $count ->
   *[other] Označeno zastavicom: { $messages }
}
done-unflagged = Uklonjena zastavica: { $messages }
done-deleted-for-good = { $count ->
   *[other] Trajno izbrisano: { $messages }
}
done-archived = { $count ->
   *[other] Arhivirano: { $messages }
}
done-moved = { $count ->
   *[other] Premješteno: { $messages } (odredište: { $folder })
}
done-copied = { $count ->
   *[other] Kopirano: { $messages } (odredište: { $folder })
}
done-moving = { $count ->
   *[other] Premještanje: { $messages } (odredište: { $folder })...
}
done-copying = { $count ->
   *[other] Kopiranje: { $messages } (odredište: { $folder })...
}
done-moved-back = { $count ->
   *[other] Vraćeno: { $messages } (odredište: { $folder })
}
done-watched = { $count ->
    [1] Pratite razgovor
    [one] Pratite { $count } razgovor
   *[other] Pratite { $count } razgovora
}
done-unwatched = { $count ->
    [1] Više ne pratite razgovor
    [one] Više ne pratite { $count } razgovor
   *[other] Više ne pratite { $count } razgovora
}
done-ignored = { $count ->
    [1] Zanemarujete razgovor
    [one] Zanemarujete { $count } razgovor
   *[other] Zanemarujete { $count } razgovora
}
done-unignored = { $count ->
    [1] Više ne zanemarujete razgovor
    [one] Više ne zanemarujete { $count } razgovor
   *[other] Više ne zanemarujete { $count } razgovora
}
their-folders = njihove izvorne mape
undo-move = Poništi premještanje
undo-delete = Poništi brisanje
undo-archive = Poništi arhiviranje
undo-junk = Poništi označavanje kao neželjenu poštu
undo-not-junk = Poništi označavanje kao poželjnu poštu
undo-send = Poništi slanje
nothing-to-undo = Nema radnji koje se mogu poništiti.
messages-gone = Poruke više nisu dostupne.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Ova mapa ne može sadržavati poruke.
not-archived-here = Poruke u ovoj mapi ne mogu se arhivirati.
not-emptied-here = Mogu se isprazniti samo mape Izbrisane stavke i Neželjena e-pošta.
next-unread-question = U mapi { $folder } nema više nepročitanih poruka.

    Želite li prijeći u sljedeću mapu s nepročitanim porukama: { $next }?
no-unread-left = Nema više nepročitanih poruka.
empty-question = { $count ->
    [1] Isprazniti mapu { $folder }?

        Poruka u njoj trajno će se izbrisati. Neće se moći vratiti.
   *[other] Isprazniti mapu { $folder }?

        Sve poruke u njoj ({ $messages }) trajno će se izbrisati. Neće se moći vratiti.
}
no-junk-folder = Ovaj račun nema mapu Neželjena e-pošta u koju bi se poruke premjestile.
no-inbox-folder = Ovaj račun nema mapu Ulazna pošta u koju bi se poruke premjestile.
done-flagged-color = Označeno zastavicom: { $messages }, boja: { $color ->
    [red] crvena
    [orange] narančasta
    [yellow] žuta
    [green] zelena
    [blue] plava
    [purple] ljubičasta
   *[gray] siva
}
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

move-window-title-move = { $count ->
    [1] Premjesti poruku
    [one] Premjesti { $count } poruku
    [few] Premjesti { $count } poruke
   *[other] Premjesti { $count } poruka
}
move-window-title-copy = { $count ->
    [1] Kopiraj poruku
    [one] Kopiraj { $count } poruku
    [few] Kopiraj { $count } poruke
   *[other] Kopiraj { $count } poruka
}
move-window-prompt-move = { $count ->
    [1] Premjestite odabranu poruku u:
    [one] Premjestite { $count } odabranu poruku u:
    [few] Premjestite { $count } odabrane poruke u:
   *[other] Premjestite { $count } odabranih poruka u:
}
move-window-prompt-copy = { $count ->
    [1] Kopirajte odabranu poruku u:
    [one] Kopirajte { $count } odabranu poruku u:
    [few] Kopirajte { $count } odabrane poruke u:
   *[other] Kopirajte { $count } odabranih poruka u:
}
targets-recent = Nedavno korišteno
target-current = { $folder } (trenutačna)
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Premještanje u tijeku: { $done } (ukupno: { $messages }, odredište: { $folder })...
transfer-copying = Kopiranje u tijeku: { $done } (ukupno: { $messages }, odredište: { $folder })...
transfer-another-account = drugi račun
transfer-folder-gone = odredišna mapa više ne postoji
transfer-not-on-server = poruka više nije na poslužitelju
transfer-not-moved = { $count ->
   *[other] Nije moguće premjestiti na drugi račun ({ $messages }): { $reason }
}
transfer-not-copied = { $count ->
   *[other] Nije moguće kopirati na drugi račun ({ $messages }): { $reason }
}
transfer-none-moved = Nijedna poruka nije premještena
transfer-none-copied = Nijedna poruka nije kopirana

## Messages as files

export-not-in-time = poruku nije bilo moguće preuzeti na vrijeme
export-not-saved = Nije spremljeno: { $failed } (ukupno: { $messages }). Pojedinosti: { $problems }
export-not-attached = poruke nije moguće priložiti: { $error }
saved-to = { $count ->
   *[other] Spremljeno u mapu { $folder }: { $messages }
}
download-progress = Preuzimanje: { $done } od { $total }
download-done = Preuzeto: { $size }
downloading-messages = { $count ->
   *[other] Preuzimanje: { $messages }...
}
import-put = { $count ->
   *[other] Uvezeno u mapu { $folder }: { $messages }
}
import-not-put = Ove datoteke nije bilo moguće uvesti:

    { $problems }

## Problems the windows show

error-store = baza pošte: { $error }
error-not-found = nije pronađeno
error-closed = zatvaranje u tijeku
error-other-account = u pregledniku ste se prijavili na račun { $email }, a ne na ovaj račun
failure-authentication = poslužitelj nije prihvatio prijavu ({ $reason })
failure-network = nije se moguće povezati s poslužiteljem ({ $reason })
error-in-use = aplikaciju nije moguće ukloniti jer je sljedeći računi koriste za prijavu: { $accounts }
error-turned-off = ova je aplikacija za prijavu isključena za nove račune
error-folder-name = naziv mape mora imati od 1 do 200 znakova i ne smije sadržavati kontrolne znakove
error-folder-separator = na ovom poslužitelju naziv mape ne smije sadržavati „{ $separator }“
error-folder-special = mapa Ulazna pošta i posebne mape ne mogu se preimenovati ni izbrisati
error-no-recipients = poruka nema primatelja
error-bad-address = „{ $address }“ nije adresa e-pošte
error-not-own-address = { $address } nije jedna od adresa pošiljatelja ovog računa. Dodajte je u polje „Druge adrese s kojih šaljete“ u svojstvima računa.
rule-query-refused = Pravila ne mogu filtrirati po mapi ni datumu ({ $words }).
rule-no-query = Unesite kriterije pretraživanja za dolazne poruke.
rule-no-action = Odaberite barem jednu radnju za pravilo.
error-attachment = Datoteku { $path } nije moguće pročitati: { $error }
error-no-drafts = račun nema mapu Skice u koju bi se poruka spremila
error-draft-attachment = privitak skice nije moguće spremiti: { $error }
error-password-not-saved = lozinku nije moguće spremiti za sljedeće pokretanje: { $error }
error-sign-in-not-saved = nove podatke za prijavu nije moguće spremiti za sljedeće pokretanje: { $error }
error-import-unreadable = Datoteka { $path } ne može se pročitati: { $error }
error-import-too-large = Datoteka { $path } veća je od 50 MB
error-import-not-mail = Datoteka { $path } nije poruka e-pošte
error-list-answered = poslužitelj liste e-pošte vratio je status { $status }
error-not-built = poruku nije moguće sastaviti
error-outbox-waits = { $count ->
    [1] poruka čeka u mapi Izlazna pošta. Slanje će se ponovno pokušati pri sljedećoj provjeri pošte
    [one] { $count } poruka čeka u mapi Izlazna pošta. Slanje će se ponovno pokušati pri sljedećoj provjeri pošte
    [few] { $count } poruke čekaju u mapi Izlazna pošta. Slanje će se ponovno pokušati pri sljedećoj provjeri pošte
   *[other] { $count } poruka čeka u mapi Izlazna pošta. Slanje će se ponovno pokušati pri sljedećoj provjeri pošte
}
error-draft-not-removed = raniju skicu poruke nije moguće ukloniti iz mape Skice: { $reason }
error-sent-but = poruka je poslana, ali { $problem }
error-sent-still-in-outbox = još je u mapi Izlazna pošta: { $error }
error-sent-no-copy = kopiju nije moguće spremiti u mapu Poslane stavke: { $reason }
error-no-password = nema lozinke za ovaj račun
error-no-sign-in = nema podataka za prijavu za ovaj račun
error-provider-missing = ova se verzija ne može prijaviti kod davatelja { $provider }: je li njegova aplikacija za prijavu uklonjena?
error-provider-servers = poslužitelji ovog računa ne odgovaraju poslužiteljima njegove aplikacije za prijavu
error-app-scopes = { $reason }. Poslužitelj e-pošte nije prihvatio token aplikacije za prijavu: provjerite daju li dozvole (scopes) aplikacije pristup pošti
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google još nije potvrdio Inbox Classic pa dopušta prijavu samo testnim korisnicima. Upotrijebite vlastitu aplikaciju za prijavu na Google ili lozinku za aplikaciju. Ako ste testni korisnik, ugrađenu aplikaciju možete uključiti u prozoru Aplikacije za prijavu (Datoteka > Računi).
sign-in-off-other = Isključena je u prozoru Aplikacije za prijavu (Datoteka > Računi), gdje se može ponovno uključiti.
sign-in-app-no-name = aplikacija za prijavu mora imati naziv
sign-in-app-no-client = nedostaje ID klijenta
sign-in-app-no-scopes = za aplikaciju za prijavu treba navesti dozvole (scopes) za pristup pošti
sign-in-app-bad-host = adresa poslužitelja { $server } nedostaje ili nije valjan naziv poslužitelja
sign-in-app-plain = poslužitelj { $server } mora koristiti SSL/TLS ili STARTTLS
sign-in-app-not-checked = izdavatelj još nije provjeren
sign-in-app-issuer-changed = izdavatelj se promijenio: ponovno upišite tajnu klijenta ili je uklonite
sign-in-register-google = U konzoli Google Cloud Console izradite OAuth klijenta vrste Desktop app, a na zaslonu za pristanak dodajte dozvolu https://mail.google.com/. Dok je aplikacija u fazi testiranja, prijaviti se mogu samo njezini testni korisnici.
sign-in-register-microsoft = U servisu Microsoft Entra registrirajte aplikaciju s platformom Mobile and desktop applications, URI-jem za preusmjeravanje http://localhost, dopuštenim tokovima javnog klijenta i delegiranim dozvolama IMAP.AccessAsUser.All, SMTP.Send i offline_access. Samo za svoju tvrtku ili ustanovu kao izdavatelja koristite https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Registrirajte nativnu aplikaciju (javni klijent) s URI-jem za preusmjeravanje navedenim u nastavku. Davatelj mora dopustiti bilo koji priključak na toj adresi (RFC 8252). Dodajte dozvolu koja omogućuje pristup pošti.

## Calendar invitations

repeats = Ponavlja se
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Svaki dan
        [one] Razmak između ponavljanja: { $interval } dan
        [few] Razmak između ponavljanja: { $interval } dana
       *[other] Razmak između ponavljanja: { $interval } dana
    }
    [week] { $interval ->
        [1] Svaki tjedan
        [one] Razmak između ponavljanja: { $interval } tjedan
        [few] Razmak između ponavljanja: { $interval } tjedna
       *[other] Razmak između ponavljanja: { $interval } tjedana
    }
    [month] { $interval ->
        [1] Svaki mjesec
        [one] Razmak između ponavljanja: { $interval } mjesec
        [few] Razmak između ponavljanja: { $interval } mjeseca
       *[other] Razmak između ponavljanja: { $interval } mjeseci
    }
   *[year] { $interval ->
        [1] Svake godine
        [one] Razmak između ponavljanja: { $interval } godina
        [few] Razmak između ponavljanja: { $interval } godine
       *[other] Razmak između ponavljanja: { $interval } godina
    }
}
# "Every week: Monday, Wednesday"
repeats-on = { $repeats } ({ $days })
repeats-times = { $count ->
    [1] { $repeats }, jednom
    [one] { $repeats }, { $count } put
    [few] { $repeats }, { $count } puta
   *[other] { $repeats }, { $count } puta
}
day-monday = ponedjeljak
day-tuesday = utorak
day-wednesday = srijeda
day-thursday = četvrtak
day-friday = petak
day-saturday = subota
day-sunday = nedjelja

## AI agents

agent-level-read = Čitanje pošte: mape, popis poruka, pretraživanje i poruke
# review: changed
agent-level-organize = Organiziranje pošte: pročitanost, zastavice, neželjena pošta, premještanje i brisanje (u Izbrisane stavke)
agent-level-drafts = Pisanje skica koje ćete vi poslati
agent-level-send = Slanje pošte, svake poruke tek nakon vašeg odobrenja
agent-connect-title = { $program } želi koristiti vašu poštu
agent-connect-detail = AI agent zatražio je pristup vašoj pošti putem programa Inbox Classic. Odaberite što smije raditi i kojim računima smije pristupiti. To možete kasnije promijeniti u izborniku Alati > AI agenti.

    Agenti čitaju poruke drugih ljudi, koje mogu sadržavati upute kojima ih netko pokušava prevariti. Inbox Classic uvijek traži vaše odobrenje prije nego što agent pošalje poruku.
agent-reply-to = Odgovor na „{ $subject }“
agent-reply-all-on = Odgovor svima na „{ $subject }“
agent-forward-of = Prosljeđivanje poruke „{ $subject }“
agent-never-written-one = Još niste slali poruke na adresu { $address }.
agent-never-written-many = Broj adresa s ovog popisa na koje još niste slali poruke: { $count }.
agent-send-title = { $program } želi poslati ovu poruku
agent-send-detail = Provjerite primatelje i sadržaj poruke. Nakon vašeg odobrenja poruka čeka na slanje { $seconds } s u mapi Izlazna pošta. Za to je vrijeme još možete izbrisati.
agent-change-title = Što smije { $program }
agent-change-allowed = Promijenite što AI agenti ovog programa smiju raditi s vašom poštom putem programa Inbox Classic.
agent-change-refused = Ovom ste programu odbili pristup. Dopustite mu pristup kako bi njegovi agenti ponovno mogli raditi s vašom poštom putem programa Inbox Classic.
agent-log-taken-back = { $entry } (poništeno)
agent-files = Datoteke: { $files }
agent-undo-refused = Ne može se poništiti.
agent-undo-refused-why = Ne može se poništiti: { $reason }.
agent-undo-impossible = ovo se ne može poništiti
agent-undo-not-in-folder = poruka više nije u toj mapi
agent-undo-not-arrived = poruka (još) nije u mapi u koju je premještena
agent-undo-sent = poruka više nije u mapi Izlazna pošta
agent-original-not-downloaded = izvorna poruka još nije preuzeta. Najprije je otvorite
agent-turned-away = Odbijeno
agent-can-nothing = Ništa
agent-can-read = čitanje
agent-can-organize = organiziranje
agent-can-drafts = pisanje skica
agent-can-send = slanje uz vaše odobrenje
# "Read, organize and write drafts"
agent-can-list = { $first } i { $last }
agent-accounts = { $count ->
    [0] nijedan račun
    [one] { $count } račun
    [few] { $count } računa
   *[other] { $count } računa
}
# "Read and organize; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Inbox Classic ne može pročitati ovu poruku.
agent-encrypted-original = Ova je poruka šifrirana: agent na nju ne može odgovoriti niti je proslijediti jer ne može šifrirati.
agent-encrypted = Ova je poruka šifrirana. AI agenti ne mogu pročitati njezin sadržaj. Korisnik je treba otvoriti u programu Inbox Classic.
list-encrypted = Šifrirana poruka
agent-log-composed = Otvorena je nova poruka „{ $subject }“ koju možete dovršiti
agent-log-refused = Odbili ste slanje poruke „{ $subject }“
agent-log-sent = Poruka „{ $subject }“ dodana je u red za slanje primateljima: { $to }
agent-log-draft = Spremljena skica „{ $subject }“
# review: new
agent-log-draft-replaced = Zamijenjena skica „{ $subject }“
# review: new
agent-log-draft-discarded = Odbačena skica „{ $subject }“
# review: new
agent-draft-note = { $program }, AI agent, napisao je ovu skicu. Provjerite primatelje i tekst prije nego što je pošaljete.
agent-log-read = Poruka „{ $subject }“ označena je kao pročitana
agent-log-unread = Poruka „{ $subject }“ označena je kao nepročitana
agent-log-flagged = Poruka „{ $subject }“ označena je zastavicom
agent-log-unflagged = S poruke „{ $subject }“ uklonjena je zastavica
agent-log-deleted = Poruka „{ $subject }“ je izbrisana
agent-log-moved = Poruka „{ $subject }“ premještena je u mapu { $folder }
agent-log-junk = Poruka „{ $subject }“ označena je kao neželjena pošta
agent-log-not-junk = Poruka „{ $subject }“ označena je kao poželjna pošta
agent-log-archived = Poruka „{ $subject }“ je arhivirana
agent-log-folder = Stvorena mapa „{ $name }“
agent-log-unsubscribed = Odobrili ste zahtjev za otkazivanje pretplate. Poruka: „{ $subject }“
# review: new
agent-log-unsubscribe-failed = Otkazivanje pretplate na popis poruke „{ $subject }“ nije uspjelo: { $reason }
# review: new
agent-log-unsubscribe-refused = Niste otkazali pretplatu na { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [one] { $program } želi otkazati vašu pretplatu na { $count } popis za slanje
    [few] { $program } želi otkazati vašu pretplatu na { $count } popisa za slanje
   *[other] { $program } želi otkazati vašu pretplatu na { $count } popisa za slanje
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic traži od popisa u nastavku da vam prestane slati poruke, na način jednim klikom koji nudi. Ništa drugo se ne šalje, a poruke koje imate ostaju gdje jesu.
   *[other] Inbox Classic traži od svakog popisa u nastavku da vam prestane slati poruke, na način jednim klikom koji popis nudi. Ništa drugo se ne šalje, a poruke koje imate ostaju gdje jesu.
}

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = davatelj nije dao token za osvježavanje
sign-in-no-account = davatelj nije naveo koji se račun prijavio
sign-in-not-finished = prijava nije dovršena
secrets-unavailable = { $store } nije dostupan
secrets-unavailable-why = { $store } nije dostupan: { $error }
secrets-windows = Upravitelj vjerodajnicama
secrets-mac = privjesak ključeva
secrets-linux = sustavski privjesak ključeva (Secret Service)
error-no-such-file = ta datoteka ne postoji
cards-file-too-big = Datoteka adresara premašuje dopuštenu veličinu.
ui-sender-added = Kontakt je dodan u Adresar: { $name }.
ui-sender-known = { $name } već je u Adresaru.
ui-sender-none = Pošiljatelj ove poruke nema adresu e-pošte koja bi se mogla dodati.
card-name-needed = Kontakt nema ni ime ni adresu e-pošte.
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

otp-heading = Kôd s domene { $domain }
otp-copy = Kopiraj
otp-note = Unesite ga samo na stranici domene { $domain }.
otp-old = Ovaj je kôd poslan više od sat vremena prije otvaranja poruke pa je vjerojatno istekao.

event-attendees =
    { $count ->
        [one] { $count } sudionik
        [few] { $count } sudionika
       *[other] { $count } sudionika
    }

otp-notification = { $code } vaš je kôd za { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Valjan
pgp-key-expires = Valjan do { $date }
pgp-key-expired = Istekao { $date }
pgp-key-revoked = Opozvan
pgp-key-revoked-why = Opozvan: { $reason }
pgp-key-not-valid = Nije valjan
pgp-key-locked = Privatni ključ nije moguće koristiti jer ključ za njegovu zaštitu nedostaje u sustavu za pohranu ({ $store }). Ponovno uvezite sigurnosnu kopiju privatnog ključa.
pgp-source-own = Stvoren u programu Inbox Classic
pgp-source-file = Uvezen iz datoteke
pgp-source-paste = Zalijepljen
pgp-source-attachment = Iz poruke
pgp-source-vcard = Iz kartice kontakta
pgp-source-wkd = Od davatelja usluge e-pošte pošiljatelja
pgp-source-keyserver = S poslužitelja keys.openpgp.org
pgp-source-autocrypt = Iz zaglavlja Autocrypt poruke
pgp-error-no-store = Privatne ključeve štiti { $store }, koji se ne može koristiti: { $error }
pgp-error-wrong-passphrase = Pristupna fraza nije točna.
pgp-error-not-a-key = Ovo nije ključ OpenPGP.
pgp-error-too-large = Ključ je prevelik.
pgp-error-unusable = Ključ koristi staru ili slabu kriptografiju i ne može se koristiti.
pgp-imported-private = { $count ->
    [1] Vaš privatni ključ je uvezen.
    [one] Uvezen je { $count } privatni ključ.
    [few] Uvezena su { $count } privatna ključa.
   *[other] Uvezeno je { $count } privatnih ključeva.
}
pgp-imported-public = { $count ->
    [1] Uvezen je jedan ključ.
    [one] Uvezen je { $count } ključ.
    [few] Uvezena su { $count } ključa.
   *[other] Uvezeno je { $count } ključeva.
}
pgp-imported-pending = Za sljedeće adrese već je odabran ključ: { $addresses }. Novopronađeni ključ možete odabrati u podacima odgovarajućeg kontakta.
pgp-error-needs-passphrase = Privatni ključ zaštićen je pristupnom frazom. Upišite je da biste uvezli ključ.
pgp-error-mismatch = Privatni ključ ne odgovara javnom ključu. Možda je izmijenjen.
pgp-file-name-public = Javni ključ - { $who }.asc
pgp-file-name-private = Sigurnosna kopija privatnog ključa - { $who }.asc
pgp-pending = Drugi ključ za { $address } pronađen je { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Digitalno potpisano: { $signer } (vlasništvo ključa potvrđeno)
pgp-part-signed = Digitalno potpisano: { $signer } (vlasništvo ključa nije potvrđeno)
pgp-part-other = Digitalni potpis: { $signer }. Potpisnik se ne podudara s pošiljateljem
pgp-part-unknown-key = Digitalno potpisano, ali ključ nije poznat
pgp-part-not-signed = Nije digitalno potpisano
pgp-part-not-checked = Digitalni potpis nije provjeren
pgp-part-encrypted = Šifrirano. { $signature }
pgp-part-no-key = Šifrirano. Nemate potreban privatni ključ za dešifriranje
pgp-part-changed = Šifrirani dio poruke izmijenjen je tijekom prijenosa pa se ne prikazuje
pgp-part-unprotected = Šifrirano bez zaštite od izmjena, ne prikazuje se
pgp-part-broken = Šifrirani dio poruke nije moguće pročitati
pgp-why-mismatch = Digitalni potpis ne odgovara ovom tekstu
pgp-why-weak-hash = Digitalni potpis koristi algoritam { $hash }, koji se više ne smatra sigurnim
pgp-why-key-expired = Potpisano nakon što je ključ istekao { $date }
pgp-why-key-revoked = Potpisano opozvanim ključem
pgp-why-not-signing-key = Potpisano ključem koji nije namijenjen digitalnom potpisivanju
pgp-why-from-future = Datum digitalnog potpisa je u budućnosti
pgp-why-signature-expired = Digitalni potpis je istekao
pgp-why-key-not-valid = Potpisano ključem koji nije valjan
pgp-why-not-for-you = Potpisano za druge primatelje i proslijeđeno vama
pgp-why-not-key-in-use = Ključ kojim je poruka potpisana razlikuje se od ključa odabranog za adresu { $address }
pgp-part-pictures-loaded = { $label }. Slike su učitane s interneta
pgp-error-no-own-key = Nemate ključ za adresu { $address } kojim biste digitalno potpisivali ili šifrirali poruke. Stvorite ga u izborniku Alati > Ključevi za šifriranje ili isključite mogućnosti Potpiši i Šifriraj.
pgp-error-missing-keys = { $count ->
    [1] { $addresses } nema ključ za šifriranje.
   *[other] Ovi primatelji nemaju ključ za šifriranje: { $addresses }.
}
pgp-error-encrypted-quote = Ova poruka citira ili prosljeđuje šifriranu poruku, pa se može poslati samo šifrirana. Uključite Šifriraj ili uklonite citirani tekst.
pgp-error-protect = Poruku nije moguće digitalno potpisati ili šifrirati: { $reason }
pgp-found-keys = Adrese za koje je pronađen ključ: { $addresses }.
pgp-found-none = Za sljedeće adrese nije pronađen nijedan ključ: { $addresses }. Zatražite javni ključ od primatelja.
pgp-found-no-key = Nije pronađen nijedan ključ.
pgp-find-unavailable = Ključeve sada nije moguće potražiti: { $error }
pgp-publish-pending = Poslužitelj keys.openpgp.org poslao je poveznice za potvrdu na ove adrese: { $addresses }. Potvrdite svaku adresu kako bi se vaš ključ mogao pronaći po njoj.
pgp-publish-done = Vaš je ključ objavljen na keys.openpgp.org za { $addresses }.
pgp-publish-failed = Ključ nije moguće objaviti: { $error }
pgp-keyserver-off = Traženje ključeva na keys.openpgp.org isključeno je u postavkama { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [1] Šifrirano i potpisano: mogu je pročitati samo vi i { $addresses }.
   *[other] Šifrirano i potpisano: mogu je pročitati samo vi i njezini primatelji ({ $count }).
}
# review: new
pgp-compose-encrypt-ready = Bit će šifrirana i potpisana. Dodajte primatelje čije ključeve imate.
# review: new
pgp-compose-missing = { $count ->
    [1] { $addresses } nema ključ, pa se poruka još ne može šifrirati.
   *[other] Primatelji bez ključa ({ $count }): { $addresses }. Zato se poruka još ne može šifrirati.
}
# review: new
pgp-compose-looking = Traže se ključevi za: { $addresses }...
# review: new
pgp-compose-signed = Potpisano: primatelji mogu provjeriti da je od vas i da nije mijenjana.
# review: new
pgp-compose-reply-clear = Nije šifrirano, iako je poruka na koju odgovara ili koju prosljeđuje bila šifrirana.
# review: new
pgp-compose-encrypted-files = Priložene su datoteke šifrirane poruke, pa se ova poruka može poslati samo šifrirana. Uključite Šifriraj ili uklonite te datoteke.
# review: new
pgp-compose-sign-tip = Potpišite poruku svojim ključem kako bi primatelji mogli provjeriti da je od vas i da nije mijenjana
# review: new
pgp-compose-sign-tip-encrypted = Šifrirana poruka uvijek je potpisana
# review: new
pgp-compose-encrypt-tip = Šifrirajte poruku kako bi je mogli pročitati samo vi i njezini primatelji
# review: new
pgp-compose-make-key = Još nemate ključ za { $address }. Želite li ga sada stvoriti? S njim se vaše poruke mogu potpisivati i šifrirati.
# review: new
pgp-compose-key-unusable = Vaš ključ za { $address } ne može se koristiti ({ $state }). Otvorite prozor Ključevi za šifriranje kako biste uvezli njegovu sigurnosnu kopiju ili stvorili novi ključ.
# review: new
pgp-compose-encrypt-off-quote = Ova poruka citira ili prosljeđuje šifriranu poruku. Bez šifriranja ne može se poslati dok ne uklonite citirani sadržaj. Želite li ipak isključiti šifriranje?
# review: new
pgp-compose-encrypt-off-reply = Ova poruka odgovara na šifriranu poruku ili je prosljeđuje. Bez šifriranja vašu poruku može pročitati svatko tko njome rukuje na putu. Želite li isključiti šifriranje?
# review: new
pgp-recipient-verified = Ključ provjeren
# review: new
pgp-recipient-found = Ključ nije provjeren
# review: new
pgp-recipient-own = Vaš ključ
# review: new
pgp-recipient-looking = Traži se ključ...
# review: new
pgp-recipient-missing = Nema ključa
# review: new
pgp-recipient-not-found = Nema ključa: { $date } nije pronađen nijedan
# review: new
pgp-recipient-unusable = Ključ se ne može koristiti: { $state }
# review: new
pgp-recipients-intro = Poruka se šifrira ključem svakog primatelja i vašim.
# review: new
pgp-recipients-intro-missing = { $count ->
    [1] Jedan primatelj nema ključ za šifriranje. Pronađite njegov ključ, uklonite ga iz ove poruke ili je pošaljite bez šifriranja.
    [one] { $count } primatelj nema ključ za šifriranje. Pronađite njihove ključeve, uklonite ih iz ove poruke ili je pošaljite bez šifriranja.
    [few] { $count } primatelja nemaju ključ za šifriranje. Pronađite njihove ključeve, uklonite ih iz ove poruke ili je pošaljite bez šifriranja.
   *[other] { $count } primatelja nema ključ za šifriranje. Pronađite njihove ključeve, uklonite ih iz ove poruke ili je pošaljite bez šifriranja.
}
pgp-details-part = Dio { $number }: { $label }
pgp-details-signed = Potpisano { $when } ključem { $key }
pgp-details-unknown-key = Potpisano ključem { $key }, koji nemate
pgp-details-opened = Dešifrirano vašim ključem { $key }
pgp-details-for = Ključevi za koje je poruka šifrirana: { $keys }
pgp-details-plain = Nije digitalno potpisano ni šifrirano
pgp-bar-parts = Ova poruka ima više dijelova ({ $count }): { $list }. Za svaki je dio navedeno kako je zaštićen.
pgp-bar-count-verified = Potvrđeno vlasništvo ključa: { $count }
pgp-bar-count-good = { $count ->
    [one] { $count } potpisan ili šifriran
    [few] { $count } potpisana ili šifrirana
   *[other] { $count } potpisanih ili šifriranih
}
pgp-bar-count-warning = { $count ->
    [one] { $count } dio treba provjeriti
    [few] { $count } dijela treba provjeriti
   *[other] { $count } dijelova treba provjeriti
}
pgp-bar-count-neutral = Bez potvrđenog potpisa: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Postavke
setup-part-preferences = Postavke prozora
setup-part-accounts = Računi
setup-part-sign-in-apps = Aplikacije za prijavu
setup-part-contacts = Kontakti i grupe
setup-part-keys = Ključevi za šifriranje
setup-part-rules = Pravila za poruke
setup-part-trusted-senders = Pouzdani pošiljatelji
setup-holds-settings = { $count ->
    [one] { $count } postavka
    [few] { $count } postavke
   *[other] { $count } postavki
}
setup-holds-preferences = { $count ->
    [one] { $count } postavka prozora
    [few] { $count } postavke prozora
   *[other] { $count } postavki prozora
}
setup-holds-accounts = { $count ->
    [one] { $count } račun
    [few] { $count } računa
   *[other] { $count } računa
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavu
    [few] { $count } aplikacije za prijavu
   *[other] { $count } aplikacija za prijavu
}
setup-holds-built-in = Koje su ugrađene aplikacije za prijavu uključene
setup-holds-contacts = { $count ->
    [one] { $count } kontakt
    [few] { $count } kontakta
   *[other] { $count } kontakata
}
setup-holds-groups = { $count ->
    [one] { $count } grupa
    [few] { $count } grupe
   *[other] { $count } grupa
}
setup-holds-own-keys = { $count ->
    [one] { $count } vlastiti ključ
    [few] { $count } vlastita ključa
   *[other] { $count } vlastitih ključeva
}
setup-holds-contact-keys = { $count ->
    [one] { $count } ključ kontakta
    [few] { $count } ključa kontakata
   *[other] { $count } ključeva kontakata
}
setup-holds-rules = { $count ->
    [one] { $count } pravilo
    [few] { $count } pravila
   *[other] { $count } pravila
}
setup-holds-trusted-senders = { $count ->
    [one] { $count } pouzdani pošiljatelj
    [few] { $count } pouzdana pošiljatelja
   *[other] { $count } pouzdanih pošiljatelja
}
setup-sign-in-password = Lozinka
setup-account-secret-password = Lozinka računa spremljena je u datoteci.
setup-account-secret-token = Podaci za prijavu spremljeni su u datoteci.
setup-account-asks-password = Nakon uvoza morat ćete unijeti lozinku računa.
setup-account-signs-in-again = Nakon uvoza morat ćete se ponovno prijaviti na račun.
setup-account-here = Račun je već postavljen na ovom računalu pa se preskače.
setup-account-no-app = Prijavljuje se aplikacijom { $app }, koja ovdje nije postavljena. Uvezite i aplikacije za prijavu.
setup-invalid-address = „{ $address }“ nije adresa e-pošte.
setup-invalid-server = Postavke poslužitelja { $server } ne sadrže valjanu adresu i broj priključka.
setup-invalid-user = Nema korisničkog imena.
setup-invalid-sign-in = Način prijave ovog računa nije podržan.
setup-error-empty = Datoteka je prazna.
setup-error-too-large = Datoteka s postavkama programa Inbox Classic premašuje dopuštenu veličinu.
setup-error-not-setup = Ova datoteka ne sadrži postavke programa Inbox Classic.
setup-error-damaged = Datoteka s postavkama oštećena je i nije je moguće pročitati.
setup-error-newer = Ove su postavke spremljene u novijoj verziji programa Inbox Classic ({ $version }). Ažurirajte Inbox Classic pa ih ponovno uvezite.
setup-error-needs-passphrase = Ova datoteka s postavkama zaštićena je pristupnom frazom. Unesite frazu kojom je zaštićena pri spremanju.
setup-error-wrong-passphrase = Pristupna fraza nije točna za ovu datoteku s postavkama.
setup-error-changed = Datoteka s postavkama promijenjena je ili oštećena nakon spremanja pa je nije moguće uvesti.
setup-error-read = Datoteku s postavkama nije moguće pročitati: { $error }
setup-error-write = Postavke nije moguće spremiti: { $error }
setup-error-no-parts = Odaberite barem jednu skupinu podataka.
setup-left-out = { $count ->
    [one] { $count } stavka (dio: { $part }) ne može se koristiti i izostavljena je.
    [few] { $count } stavke (dio: { $part }) ne mogu se koristiti i izostavljene su.
   *[other] { $count } stavki (dio: { $part }) ne može se koristiti i izostavljeno je.
}
setup-imported-settings = Postavke su zamijenjene.
setup-imported-preferences = Postavke prozora su zamijenjene.
setup-added-accounts = { $count ->
    [one] Dodan je { $count } račun.
    [few] Dodana su { $count } računa.
   *[other] Dodano je { $count } računa.
}
setup-skipped-here = Račun { $address } već je postavljen na ovom računalu pa je preskočen.
setup-skipped-no-app = Račun { $address } preskočen je jer za prijavu koristi aplikaciju { $app }, koja nije postavljena na ovom računalu.
setup-skipped-invalid = Račun { $address } je preskočen: { $reason }
setup-asks-password = Pri povezivanju računa { $address } morat ćete unijeti lozinku.
setup-signs-in-again = Pri povezivanju računa { $address } morat ćete se ponovno prijaviti.
setup-added-sign-in-apps = { $count ->
    [one] Dodana je { $count } aplikacija za prijavu.
    [few] Dodane su { $count } aplikacije za prijavu.
   *[other] Dodano je { $count } aplikacija za prijavu.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavu ovdje je već postavljena.
    [few] { $count } aplikacije za prijavu ovdje su već postavljene.
   *[other] { $count } aplikacija za prijavu ovdje je već postavljeno.
}
setup-added-contacts = { $count ->
    [one] U adresar je dodan { $count } kontakt.
    [few] U adresar su dodana { $count } kontakta.
   *[other] U adresar je dodano { $count } kontakata.
}
setup-skipped-contacts = { $count ->
    [one] { $count } kontakt već je u adresaru.
    [few] { $count } kontakta već su u adresaru.
   *[other] { $count } kontakata već je u adresaru.
}
setup-added-groups = { $count ->
    [one] Dodana je ili dopunjena { $count } grupa.
    [few] Dodane su ili dopunjene { $count } grupe.
   *[other] Dodano je ili dopunjeno { $count } grupa.
}
setup-added-own-keys = { $count ->
    [one] Dodan je { $count } vlastiti ključ.
    [few] Dodana su { $count } vlastita ključa.
   *[other] Dodano je { $count } vlastitih ključeva.
}
setup-added-contact-keys = { $count ->
    [one] Dodan je { $count } ključ kontakta.
    [few] Dodana su { $count } ključa kontakata.
   *[other] Dodano je { $count } ključeva kontakata.
}
setup-added-rules = { $count ->
    [one] Dodano je { $count } pravilo za poruke.
    [few] Dodana su { $count } pravila za poruke.
   *[other] Dodano je { $count } pravila za poruke.
}
setup-skipped-rules = { $count ->
    [one] { $count } pravilo za poruke već postoji.
    [few] { $count } pravila za poruke već postoje.
   *[other] { $count } pravila za poruke već postoji.
}
setup-skipped-rules-account = { $count ->
    [1] 1 pravilo za poruke odnosi se na račun koji nije postavljen na ovom računalu, pa je preskočeno.
    [one] { $count } pravilo za poruke odnosi se na račune koji nisu postavljeni na ovom računalu, pa je preskočeno.
    [few] { $count } pravila za poruke odnose se na račune koji nisu postavljeni na ovom računalu, pa su preskočena.
   *[other] { $count } pravila za poruke odnosi se na račune koji nisu postavljeni na ovom računalu, pa je preskočeno.
}
setup-rules-waiting = { $count ->
    [1] 1 pravilo za poruke premješta poruke u mapu koja će se pojaviti kad se njezin račun sinkronizira.
    [one] { $count } pravilo za poruke premješta poruke u mape koje će se pojaviti kad se njihovi računi sinkroniziraju.
    [few] { $count } pravila za poruke premještaju poruke u mape koje će se pojaviti kad se njihovi računi sinkroniziraju.
   *[other] { $count } pravila za poruke premješta poruke u mape koje će se pojaviti kad se njihovi računi sinkroniziraju.
}
setup-added-trusted-senders = { $count ->
    [one] Dodan je { $count } pouzdani pošiljatelj.
    [few] Dodana su { $count } pouzdana pošiljatelja.
   *[other] Dodano je { $count } pouzdanih pošiljatelja.
}
setup-nothing = Ništa nije uvezeno.
setup-account-servers = { $imap } i { $smtp } ({ $signin })
setup-file-name = Postavke i računi programa Inbox Classic
setup-skipped-unreachable = Preskočeno: { $name }. Usluga za prijavu nije dostupna. U prozoru Aplikacije za prijavu ponovno dodajte odgovarajuću aplikaciju.
attachment-runs-programs = Datoteka „{ $name }“ može pokretati programe pa je Inbox Classic ne otvara. Spremite je, a zatim je sami otvorite ako vjerujete njezinu izvoru.
attachment-decrypted-note = Ovaj privitak potječe iz šifrirane poruke. Pri otvaranju Inbox Classic sprema nešifriranu kopiju u privremenu mapu vašeg korisničkog računa. Kopije starije od jednog dana uklanjaju se pri pokretanju programa.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [1] Poslužitelj nije premjestio poruku u mapu { $folder }, pa je { $messages } ponovno u mapi { $from }: { $reason }
    [one] Poslužitelj nije premjestio poruke u mapu { $folder }, pa je { $messages } ponovno u mapi { $from }: { $reason }
    [few] Poslužitelj nije premjestio poruke u mapu { $folder }, pa su { $messages } ponovno u mapi { $from }: { $reason }
   *[other] Poslužitelj nije premjestio poruke u mapu { $folder }, pa je { $messages } ponovno u mapi { $from }: { $reason }
}
undone-delete = { $count ->
    [1] Poslužitelj nije izbrisao poruku, pa je { $messages } ponovno u mapi { $from }: { $reason }
    [one] Poslužitelj nije izbrisao poruke, pa je { $messages } ponovno u mapi { $from }: { $reason }
    [few] Poslužitelj nije izbrisao poruke, pa su { $messages } ponovno u mapi { $from }: { $reason }
   *[other] Poslužitelj nije izbrisao poruke, pa je { $messages } ponovno u mapi { $from }: { $reason }
}
undone-archive = { $count ->
    [1] Poslužitelj nije arhivirao poruku, pa je { $messages } ponovno u mapi { $from }: { $reason }
    [one] Poslužitelj nije arhivirao poruke, pa je { $messages } ponovno u mapi { $from }: { $reason }
    [few] Poslužitelj nije arhivirao poruke, pa su { $messages } ponovno u mapi { $from }: { $reason }
   *[other] Poslužitelj nije arhivirao poruke, pa je { $messages } ponovno u mapi { $from }: { $reason }
}
undone-read = { $count ->
    [1] Poslužitelj nije označio poruku kao pročitanu, pa je { $messages } ponovno nepročitana: { $reason }
    [one] Poslužitelj nije označio poruke kao pročitane, pa je { $messages } ponovno nepročitana: { $reason }
    [few] Poslužitelj nije označio poruke kao pročitane, pa su { $messages } ponovno nepročitane: { $reason }
   *[other] Poslužitelj nije označio poruke kao pročitane, pa je { $messages } ponovno nepročitanih: { $reason }
}
undone-unread = { $count ->
    [1] Poslužitelj nije označio poruku kao nepročitanu, pa je { $messages } ponovno pročitana: { $reason }
    [one] Poslužitelj nije označio poruke kao nepročitane, pa je { $messages } ponovno pročitana: { $reason }
    [few] Poslužitelj nije označio poruke kao nepročitane, pa su { $messages } ponovno pročitane: { $reason }
   *[other] Poslužitelj nije označio poruke kao nepročitane, pa je { $messages } ponovno pročitanih: { $reason }
}
undone-flags = { $count ->
    [1] Poslužitelj nije promijenio zastavice poruke, pa je promjena poništena ({ $messages }): { $reason }
    [one] Poslužitelj nije promijenio zastavice poruka, pa je promjena poništena ({ $messages }): { $reason }
    [few] Poslužitelj nije promijenio zastavice poruka, pa je promjena poništena ({ $messages }): { $reason }
   *[other] Poslužitelj nije promijenio zastavice poruka, pa je promjena poništena ({ $messages }): { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Prikaži PDF datoteke u porukama
# review: new
preview-pdf-off = PDF datoteke ne prikazuju se u porukama.
# review: new
preview-pdf-off-crashed = PDF datoteka zatvorila je Inbox Classic dok se prikazivala, pa se PDF datoteke više ne prikazuju u porukama. Slike se i dalje prikazuju. Za ponovni prikaz PDF datoteka uključite { $option } u { $settings }.
# review: new
preview-pdf-details = { $count ->
    [one] { $count } stranica, { $size }
    [few] { $count } stranice, { $size }
   *[other] { $count } stranica, { $size }
}
# review: new
preview-page-alt = { $name }, stranica { $page } od { $count }
# review: new
preview-more-pages = { $count ->
    [one] Otvorite datoteku za prikaz svih { $count } stranice
    [few] Otvorite datoteku za prikaz sve { $count } stranice
   *[other] Otvorite datoteku za prikaz svih { $count } stranica
}
