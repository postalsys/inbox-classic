# Srpski (latinica). Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in English, the forms your
# language has in yours.

## Counts and sizes

messages = { $count ->
    [one] { $count } poruka
    [few] { $count } poruke
   *[other] { $count } poruka
}
# the separator of decimals in sizes: 2.4 MB
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
# the status bar: "12 messages, 3 unread"
list-counts = { $messages }, nepročitano: { $unread }
list-counts-selected = { $messages }, nepročitano: { $unread }, izabrano: { $selected }
# the status bar while searching: "12 found, 3 unread"
list-counts-found = Pronađeno: { $found }, nepročitano: { $unread }
list-counts-found-selected = Pronađeno: { $found }, nepročitano: { $unread }, izabrano: { $selected }
list-counts-none = Nije pronađena nijedna poruka

## Special folders, as Outlook Express names them

folder-inbox = Prijemno sanduče
folder-sent = Poslate stavke
folder-deleted = Izbrisane stavke
folder-drafts = Radne verzije
folder-junk = Neželjena e-pošta
folder-archive = Arhiva

## The reading pane

reader-no-message = Nije izabrana nijedna poruka.
reader-downloading = Preuzimanje poruke…
reader-downloading-detail = Poruka će se pojaviti ovde kada se preuzimanje završi.
reader-downloading-size = Veličina poruke je { $size }. Poruka će se prikazati kada se preuzimanje završi.
reader-failed = Poruku nije moguće preuzeti
reader-failed-network = Server e-pošte nije dostupan ({ $reason }).
reader-failed-sign-in = Server e-pošte nije prihvatio prijavu ({ $reason }). Proverite lozinku ili se ponovo prijavite u meniju Datoteka > Nalozi.
reader-failed-security = Nije moguće uspostaviti bezbednu vezu sa serverom e-pošte ({ $reason }).
reader-failed-other = Server e-pošte je odgovorio: { $reason }.
reader-retry-note = Inbox Classic će pokušati ponovo kada se nalog ponovo poveže.
reader-unreadable = Ova poruka ne može da se prikaže: { $error }
message-source-title = Izvorni kod poruke: { $subject }
message-source-untitled = Izvorni kod poruke

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Od
header-date = Datum
header-to = Za
header-cc = Cc
header-sent = Poslato
header-subject = Tema
header-security = Bezbednost
header-part = Deo { $number }
quote-original = ----- Originalna poruka -----
fold-show-earlier = Prikaži ranije poruke

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Vaša poruka nije isporučena
bounce-delayed = Vaša poruka još nije isporučena
bounce-delayed-note = Vaš server e-pošte još uvek pokušava da je isporuči. Ne morate ponovo da je šaljete.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Prikaži vraćenu poruku
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Prikaži odloženu poruku
bounce-what-to-do = Šta možete da uradite:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Sačekajte sledeći pokušaj isporuke. Ako poruka i dalje ne bude mogla da se isporuči, dobićete novo obaveštenje.
bounce-delayed-row-do = Vaš server e-pošte i dalje pokušava da isporuči poruku. Dobićete novo obaveštenje ako ne uspe.
# folds the receiving server's own words
bounce-details = Detalji
# a recipient the notice does not name
bounce-someone = Primalac
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Prijavio: { $server }
bounce-retry-minutes = Server primaoca je zatražio da se pre sledećeg pokušaja sačeka { $count ->
    [1] minut
    [one] { $count } minut
    [few] { $count } minuta
   *[other] { $count } minuta
}.
bounce-retry-hours = Server primaoca je zatražio da se pre sledećeg pokušaja sačeka { $count ->
    [1] sat
    [one] { $count } sat
    [few] { $count } sata
   *[other] { $count } sati
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Lista blokiranih: { $lists }
bounce-user-unknown = Adresa ne postoji
bounce-user-unknown-why = Server primaoca nema poštansko sanduče sa ovom adresom. Možda je pogrešno uneta ili je osoba više ne koristi.
bounce-user-unknown-do = Proverite da li je adresa tačno napisana ili pitajte osobu koju adresu sada koristi.
bounce-invalid-address = Adresa nije važeća
bounce-invalid-address-why = Adresa nije u formatu koji se može koristiti za slanje e-pošte.
bounce-invalid-address-do = Proverite da li ima grešaka u kucanju, na primer razmaka, slova koje nedostaje ili nedostajućeg domena iza znaka @.
bounce-mailbox-disabled = Poštansko sanduče je zatvoreno
bounce-mailbox-disabled-why = Adresa postoji, ali je njeno poštansko sanduče isključeno ili se više ne koristi.
bounce-mailbox-disabled-do = Javite se osobi na drugi način i pitajte je koju adresu sada koristi.
bounce-mailbox-full = Poštansko sanduče je puno
bounce-mailbox-full-why = U poštanskom sandučetu primaoca nema mesta za novu poštu.
bounce-mailbox-full-do = Pokušajte ponovo za nekoliko dana ili obavestite primaoca na drugi način. Može da pomogne slanje bez velikih priloga.
bounce-spam-blocked = Odbijeno kao neželjena pošta
bounce-spam-blocked-why = Server primaoca je poruku smatrao neželjenom poštom.
bounce-spam-blocked-do = Pokušajte ponovo bez sadržaja koji može da aktivira filter za neželjenu poštu, na primer mnogo veza, skraćenih veza ili velikog priloga. Ako se problem ponavlja, obratite se pružaocu usluge e-pošte.
bounce-virus-detected = Odbijeno zbog virusa
bounce-virus-detected-why = Server primaoca je pronašao virus ili drugi štetni sadržaj u poruci ili njenim prilozima.
bounce-virus-detected-do = Proverite priloge antivirusnim programom. Neki serveri odbijaju sve programe i arhive. Takve datoteke možete da postavite na servis za deljenje i pošaljete vezu ka njima.
bounce-ip-blocklisted = Vaš server e-pošte se nalazi na listi blokiranih
bounce-ip-blocklisted-why = Server primaoca odbija poštu sa servera koji je poslao vašu poruku jer se njegova IP adresa nalazi na listi blokiranih.
bounce-ip-blocklisted-do = Problem nije u sadržaju poruke. Prosledite ovo obaveštenje pružaocu usluge e-pošte i zatražite da ukloni server sa liste blokiranih.
bounce-domain-blocklisted = Domen se nalazi na listi blokiranih
bounce-domain-blocklisted-why = Server primaoca odbija poruku jer je domen vaše adrese ili domen iz veza u poruci na listi blokiranih.
bounce-domain-blocklisted-do = Ako poruka sadrži veze, pokušajte da je pošaljete bez njih. U suprotnom prosledite ovo obaveštenje osobi koja upravlja e-poštom vašeg domena.
bounce-policy-blocked = Odbijeno prema pravilima servera primaoca
bounce-policy-blocked-why = Pravila servera primaoca ne propuštaju ovu poruku, na primer zbog njene veličine, priloga ili pošiljaoca.
bounce-policy-blocked-do = Odgovor servera u odeljku Detalji često objašnjava razlog. Pitajte primaoca da li je prijem takve pošte dozvoljen.
bounce-geo-blocked = Odbijeno zbog geografskog porekla
bounce-geo-blocked-why = Server primaoca ne prima poštu iz zemlje ili mreže u kojoj je vaš server e-pošte.
bounce-geo-blocked-do = Kontaktirajte primaoca na drugi način ili se obratite pružaocu usluge e-pošte.
bounce-relay-denied = Server je odbio prosleđivanje poruke
bounce-relay-denied-why = Server je odbio da isporuči poruku dalje, često zato što je poslata bez prijave ili preko servera koji ne opslužuje ovog primaoca.
bounce-relay-denied-do = Proverite podešavanja servera odlazne pošte u meniju Datoteka > Nalozi. Proverite i da li je uključena prijava na taj server.
bounce-auth-failure = Domen pošiljaoca nije moguće potvrditi
bounce-auth-failure-why = Server primaoca nije mogao da potvrdi da je poruka zaista stigla sa vašeg domena (SPF, DKIM ili DMARC).
bounce-auth-failure-do = Prosledite ovo obaveštenje osobi koja upravlja e-poštom vašeg domena da proveri podešavanja. U međuvremenu pokušajte da šaljete preko servera svog pružaoca usluge.
bounce-rate-limited = Previše pošte odjednom
bounce-rate-limited-why = Server primaoca zasad prima manje poruka sa vašeg servera e-pošte.
bounce-rate-limited-do = Sačekajte neko vreme i pošaljite je ponovo. Kada pišete mnogim ljudima, šaljite poruku manjem broju njih odjednom.
bounce-greylisting = Isporuka je privremeno odložena
bounce-greylisting-why = Server primaoca traži od nepoznatih pošiljalaca da pokušaju ponovo malo kasnije, što je uobičajena zaštita od neželjene pošte.
bounce-greylisting-do = Sačekajte automatski ponovni pokušaj isporuke. Poruka se obično isporuči u roku od sat vremena.
bounce-server-error = Server primaoca je imao problem
bounce-server-error-why = Server primaoca nije bio dostupan ili nije mogao da primi poruku zbog sopstvenog problema.
bounce-server-error-do = Pošaljite je ponovo kasnije. Ako i dalje ne uspeva, proverite da li ima grešaka u delu adrese iza znaka @.
bounce-unknown = Nije isporučeno
bounce-unknown-why = Obaveštenje o isporuci ne navodi jasan razlog.
bounce-unknown-do = Odgovor servera u odeljku Detalji može da pruži više informacija. Ako ne razjasni problem, prosledite obaveštenje pružaocu usluge e-pošte.

## Several messages selected

selection-title = { $count ->
    [one] { $count } izabrana poruka
    [few] { $count } izabrane poruke
   *[other] { $count } izabranih poruka
}
selection-unread = Nepročitano: { $count }
selection-flagged = Označeno zastavicom: { $count }
delete-for-good-one = Ova poruka će biti trajno izbrisana. Da li želite da je izbrišete?
delete-for-good-all = Ove poruke ({ $count }) biće trajno izbrisane. Da li želite da ih izbrišete?
delete-for-good-some = Poruke za trajno brisanje: { $count } (ukupno izabrano: { $total }). Da li želite da nastavite?
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
   *[other] Premešteno: { $messages } (odredište: { $folder })
}
done-copied = { $count ->
   *[other] Kopirano: { $messages } (odredište: { $folder })
}
done-moving = { $count ->
   *[other] Premeštanje: { $messages } (odredište: { $folder })...
}
done-copying = { $count ->
   *[other] Kopiranje: { $messages } (odredište: { $folder })...
}
done-moved-back = { $count ->
   *[other] Vraćeno: { $messages } (odredište: { $folder })
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
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
their-folders = njihove izvorne fascikle
undo-move = Opozovi premeštanje
undo-delete = Opozovi brisanje
undo-archive = Opozovi arhiviranje
undo-junk = Opozovi označavanje kao neželjenu poštu
undo-not-junk = Opozovi označavanje kao poželjnu poštu
undo-send = Opozovi slanje
nothing-to-undo = Nema radnji koje mogu da se opozovu.
messages-gone = Poruke više nisu dostupne.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Ova fascikla ne može da sadrži poruke.
not-archived-here = Poruke u ovoj fascikli ne mogu da se arhiviraju.
not-emptied-here = Mogu da se isprazne samo fascikle Izbrisane stavke i Neželjena e-pošta.
next-unread-question = U fascikli { $folder } nema više nepročitanih poruka.

    Da li želite da pređete u fasciklu { $next }, sledeću fasciklu sa nepročitanim porukama?
no-unread-left = Nema više nepročitanih poruka.
empty-question = { $count ->
    [1] Da li želite da ispraznite fasciklu { $folder }?

        Poruka u njoj biće trajno izbrisana. Neće moći da se vrati.
   *[other] Da li želite da ispraznite fasciklu { $folder }?

        Sve poruke u njoj ({ $messages }) biće trajno izbrisane. Neće moći da se vrate.
}
no-junk-folder = Ovaj nalog nema fasciklu Neželjena e-pošta u koju bi se poruke premestile.
no-inbox-folder = Ovaj nalog nema fasciklu Prijemno sanduče u koju bi se poruke premestile.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
done-flagged-color = Označeno zastavicom: { $messages }, boja: { $color ->
    [red] crvena
    [orange] narandžasta
    [yellow] žuta
    [green] zelena
    [blue] plava
    [purple] ljubičasta
   *[gray] siva
}
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Crvena
    [orange] Narandžasta
    [yellow] Žuta
    [green] Zelena
    [blue] Plava
    [purple] Ljubičasta
   *[gray] Siva
}

## The Move and Copy window

move-window-title-move = { $count ->
    [1] Premesti poruku
    [one] Premesti { $count } poruku
    [few] Premesti { $count } poruke
   *[other] Premesti { $count } poruka
}
move-window-title-copy = { $count ->
    [1] Kopiraj poruku
    [one] Kopiraj { $count } poruku
    [few] Kopiraj { $count } poruke
   *[other] Kopiraj { $count } poruka
}
move-window-prompt-move = { $count ->
    [1] Premesti izabranu poruku u:
    [one] Premesti { $count } izabranu poruku u:
    [few] Premesti { $count } izabrane poruke u:
   *[other] Premesti { $count } izabranih poruka u:
}
move-window-prompt-copy = { $count ->
    [1] Kopiraj izabranu poruku u:
    [one] Kopiraj { $count } izabranu poruku u:
    [few] Kopiraj { $count } izabrane poruke u:
   *[other] Kopiraj { $count } izabranih poruka u:
}
# the folders used last, over the folder tree
targets-recent = Nedavno korišćene
# the folder the messages are in, which can not be chosen
target-current = { $folder } (trenutna)
# a folder used last, with its account when there are several: "Archive (Work)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Premešteno: { $done }; ukupno: { $messages }; odredište: { $folder }...
transfer-copying = Kopirano: { $done }; ukupno: { $messages }; odredište: { $folder }...
transfer-another-account = drugi nalog
transfer-folder-gone = odredišna fascikla više ne postoji
transfer-not-on-server = poruka više nije na serveru
transfer-not-moved = { $count ->
   *[other] Nije moguće premestiti na drugi nalog ({ $messages }): { $reason }
}
transfer-not-copied = { $count ->
   *[other] Nije moguće kopirati na drugi nalog ({ $messages }): { $reason }
}
transfer-none-moved = Nijedna poruka nije premeštena
transfer-none-copied = Nijedna poruka nije kopirana

## Messages as files

export-not-in-time = poruku nije bilo moguće preuzeti na vreme
export-not-saved = Broj nesačuvanih poruka: { $failed }; ukupno: { $messages }. Razlozi: { $problems }
export-not-attached = poruke nije moguće priložiti: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
   *[other] Sačuvano u fasciklu { $folder }: { $messages }
}
download-progress = Preuzimanje: { $done } od { $total }
download-done = Preuzeto: { $size }
downloading-messages = { $count ->
   *[other] Preuzimanje: { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
   *[other] Uvezeno u fasciklu { $folder }: { $messages }
}
import-not-put = Ove datoteke nisu uvezene:

    { $problems }

## Problems the windows show

error-store = lokalno skladište: { $error }
error-not-found = nije pronađeno
error-closed = zatvaranje u toku
error-other-account = pregledač se prijavio na nalog { $email }, a ne na ovaj nalog
# a password or sign-in the mail server refused, with the server's words
failure-authentication = server nije prihvatio prijavu ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = veza sa serverom nije uspela ({ $reason })
error-in-use = aplikacija za prijavljivanje ne može da se ukloni jer je koriste sledeći nalozi: { $accounts }
error-turned-off = ova aplikacija za prijavljivanje je isključena za nove naloge
error-folder-name = naziv fascikle mora da ima od 1 do 200 znakova i ne sme da sadrži kontrolne znakove
error-folder-separator = na ovom serveru naziv fascikle ne sme da sadrži „{ $separator }“
error-folder-special = Prijemno sanduče i posebne fascikle ne mogu da se preimenuju ni izbrišu
error-no-recipients = poruka nema primalaca
error-bad-address = „{ $address }“ nije adresa e-pošte
error-not-own-address = { $address } nije jedna od adresa za slanje sa ovog naloga. Dodajte je u polje „Dodatne adrese za slanje“ u svojstvima naloga.
rule-query-refused = Pravila ne mogu da filtriraju po fascikli ni datumu ({ $words }).
rule-no-query = Unesite kriterijume pretrage za dolazne poruke.
rule-no-action = Izaberite bar jednu radnju za pravilo.
error-attachment = Datoteku { $path } nije moguće pročitati: { $error }
error-no-drafts = nalog nema fasciklu Radne verzije u koju bi se poruka sačuvala
error-draft-attachment = prilog radne verzije nije moguće zadržati: { $error }
error-password-not-saved = lozinku nije moguće sačuvati za sledeće pokretanje: { $error }
error-sign-in-not-saved = nove podatke za prijavu nije moguće sačuvati za sledeće pokretanje: { $error }
error-import-unreadable = Datoteka { $path } ne može da se pročita: { $error }
error-import-too-large = Datoteka { $path } je veća od 50 MB
error-import-not-mail = Datoteka { $path } nije poruka e-pošte
error-list-answered = server liste za slanje je vratio status { $status }
error-not-built = poruku nije moguće sastaviti
error-outbox-waits = { $count ->
    [1] poruka čeka u Izlaznom sandučetu do sledećeg pokušaja slanja
    [one] { $count } poruka čeka u Izlaznom sandučetu do sledećeg pokušaja slanja
    [few] { $count } poruke čekaju u Izlaznom sandučetu do sledećeg pokušaja slanja
   *[other] { $count } poruka čeka u Izlaznom sandučetu do sledećeg pokušaja slanja
}
error-draft-not-removed = raniju radnu verziju poruke nije moguće ukloniti iz fascikle Radne verzije: { $reason }
error-sent-but = poruka je poslata, ali { $problem }
error-sent-still-in-outbox = još uvek je u Izlaznom sandučetu: { $error }
error-sent-no-copy = kopiju nije moguće sačuvati u fascikli Poslate stavke: { $reason }
error-no-password = nema lozinke za ovaj nalog
error-no-sign-in = nema podataka za prijavu za ovaj nalog
error-provider-missing = aplikacija za prijavljivanje za uslugu { $provider } nije dostupna u ovoj verziji. Možda je uklonjena
error-provider-servers = serveri ovog naloga ne odgovaraju serverima njegove aplikacije za prijavljivanje
error-app-scopes = { $reason }. Server e-pošte nije prihvatio token aplikacije za prijavljivanje: proverite da li opsezi (scopes) aplikacije daju pristup pošti
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google još nije potvrdio Inbox Classic, pa ugrađenu aplikaciju za prijavljivanje mogu da koriste samo test korisnici. Koristite sopstvenu aplikaciju za prijavljivanje na Google ili lozinku za aplikaciju. Ako ste test korisnik, uključite ugrađenu aplikaciju u prozoru Aplikacije za prijavljivanje (Datoteka > Nalozi).
sign-in-off-other = Isključena je u prozoru Aplikacije za prijavljivanje (Datoteka > Nalozi), gde može ponovo da se uključi.
sign-in-app-no-name = aplikacija za prijavljivanje mora da ima naziv
sign-in-app-no-client = nedostaje ID klijenta
sign-in-app-no-scopes = aplikaciji za prijavljivanje potrebni su opsezi (scopes) koji daju pristup pošti
sign-in-app-bad-host = adresa servera { $server } nedostaje ili nije važeće ime hosta
sign-in-app-plain = server { $server } mora da koristi SSL/TLS ili STARTTLS
sign-in-app-not-checked = izdavalac još nije proveren
sign-in-app-issuer-changed = izdavalac se promenio: ponovo unesite tajnu klijenta ili je uklonite
sign-in-register-google = U konzoli Google Cloud Console napravite OAuth klijent tipa Desktop app sa opsegom https://mail.google.com/ na ekranu za pristanak. Dok je aplikacija u fazi testiranja, mogu da se prijave samo njeni probni korisnici.
sign-in-register-microsoft = U servisu Microsoft Entra registrujte aplikaciju sa platformom Mobile and desktop applications, URI-jem za preusmeravanje http://localhost, dozvoljenim tokovima javnog klijenta i delegiranim dozvolama IMAP.AccessAsUser.All, SMTP.Send i offline_access. Ako je aplikacija namenjena samo vašoj organizaciji, kao izdavaoca koristite https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Registrujte javni OAuth klijent za instaliranu aplikaciju sa URI-jem za preusmeravanje navedenim ispod. Pružalac usluge mora da dozvoli proizvoljan port u toj adresi (RFC 8252). Dodajte opseg koji omogućava pristup e-pošti kod tog pružaoca usluge.

## Calendar invitations

repeats = Ponavlja se
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Svaki dan
        [one] Svaki { $interval }. dan
        [few] Svaka { $interval } dana
       *[other] Svakih { $interval } dana
}
    [week] { $interval ->
        [1] Svake nedelje
        [one] Svake { $interval }. nedelje
        [few] Svake { $interval } nedelje
       *[other] Svakih { $interval } nedelja
}
    [month] { $interval ->
        [1] Svakog meseca
        [one] Svakog { $interval }. meseca
        [few] Svaka { $interval } meseca
       *[other] Svakih { $interval } meseci
}
   *[year] { $interval ->
        [1] Svake godine
        [one] Svake { $interval }. godine
        [few] Svake { $interval } godine
       *[other] Svakih { $interval } godina
}
}
# "Every week on Monday, Wednesday"
repeats-on = { $repeats }: { $days }
# "Every week, 10 times"
repeats-times = { $count ->
    [1] { $repeats }, jednom
    [one] { $repeats }, { $count } put
    [few] { $repeats }, { $count } puta
   *[other] { $repeats }, { $count } puta
}
day-monday = ponedeljak
day-tuesday = utorak
day-wednesday = sreda
day-thursday = četvrtak
day-friday = petak
day-saturday = subota
day-sunday = nedelja

## AI agents

agent-level-read = Čitanje pošte: fascikle, lista poruka, pretraga i poruke
agent-level-organize = Organizovanje pošte: menjanje oznaka pročitanosti i zastavica, označavanje neželjene pošte, premeštanje poruka i brisanje u fasciklu Izbrisane stavke
agent-level-drafts = Pisanje radnih verzija koje ćete vi poslati
agent-level-send = Slanje pošte, svake poruke tek nakon vašeg odobrenja
agent-connect-title = { $program } želi da koristi vašu poštu
agent-connect-detail = AI agent je zatražio da radi sa programom Inbox Classic. Izaberite šta sme da radi i koje naloge sme da vidi; to možete kasnije da promenite u meniju Alatke > AI agenti.

    Agenti čitaju poštu koju su napisali drugi ljudi, a poruka može da pokuša da ih prevari. Inbox Classic vas uvek pita pre nego što agent bilo šta pošalje.
agent-reply-to = Odgovor na „{ $subject }“
agent-reply-all-on = Odgovor svima na „{ $subject }“
agent-forward-of = Prosleđivanje poruke „{ $subject }“
agent-never-written-one = Nikad niste slali poruke na adresu { $address }.
agent-never-written-many = Broj adresa sa ove liste na koje nikad niste slali poruke: { $count }.
agent-send-title = { $program } želi da pošalje ovu poruku
agent-send-detail = Proverite primaoce i sadržaj poruke. Kada odobrite slanje, poruka će čekati u Izlaznom sandučetu { $seconds } s. Za to vreme možete da je izbrišete pre nego što bude poslata.
agent-change-title = Šta { $program } sme da radi
agent-change-allowed = Promenite šta AI agenti ovog programa smeju da rade sa vašom poštom.
agent-change-refused = Odbili ste pristup ovom programu. Dozvolite ga da bi njegovi agenti ponovo dobili pristup vašoj pošti.
agent-log-taken-back = { $entry } (opozvano)
agent-files = Datoteke: { $files }
agent-undo-refused = Ne može da se opozove.
agent-undo-refused-why = Ne može da se opozove: { $reason }.
agent-undo-impossible = ovo ne može da se opozove
agent-undo-not-in-folder = poruka više nije u toj fascikli
agent-undo-not-arrived = poruka (još) nije u fascikli u koju je premeštena
agent-undo-sent = poruka više nije u izlaznom sandučetu
agent-original-not-downloaded = originalna poruka još nije preuzeta. Najpre je otvorite
agent-turned-away = Odbijeno
agent-can-nothing = Ništa
agent-can-read = čitanje
agent-can-organize = organizovanje
agent-can-drafts = pisanje radnih verzija
agent-can-send = slanje uz vaše odobrenje
# "Read, organize and write drafts"
agent-can-list = { $first } i { $last }
agent-accounts = { $count ->
    [0] nijedan nalog
    [one] { $count } nalog
    [few] { $count } naloga
   *[other] { $count } naloga
}
# "Read and organize; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Ova poruka ne može da se pročita.
agent-encrypted-original = Ova poruka je šifrovana: agent ne može na nju da odgovori niti da je prosledi jer ne može da šifruje.
agent-encrypted = Ova poruka je šifrovana. AI agenti ne mogu da pročitaju njen sadržaj. Korisnik treba da je otvori u aplikaciji Inbox Classic.
list-encrypted = Šifrovana poruka
agent-log-composed = Poruka „{ $subject }“ je otvorena za uređivanje da biste je dovršili
agent-log-refused = Odbili ste slanje poruke „{ $subject }“
agent-log-sent = Poruka „{ $subject }“ je stavljena u red za slanje; primaoci: { $to }
agent-log-draft = Sačuvana radna verzija „{ $subject }“
agent-log-read = Označeno kao pročitano: „{ $subject }“
agent-log-unread = Označeno kao nepročitano: „{ $subject }“
agent-log-flagged = Označeno zastavicom: „{ $subject }“
agent-log-unflagged = Uklonjena zastavica: „{ $subject }“
agent-log-deleted = Poruka „{ $subject }“ je premeštena u fasciklu Izbrisane stavke
agent-log-moved = Premešteno: „{ $subject }“ (odredište: { $folder })
agent-log-junk = Označeno kao neželjena pošta: „{ $subject }“
agent-log-not-junk = Označeno kao poželjna pošta: „{ $subject }“
agent-log-archived = Arhivirano: „{ $subject }“
agent-log-folder = Napravljena fascikla „{ $name }“
agent-log-unsubscribed = Poslat je zahtev za odjavu sa liste za poruku „{ $subject }“

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = pružalac usluge nije vratio token za osvežavanje
sign-in-no-account = pružalac usluge nije naveo koji se nalog prijavio
sign-in-not-finished = prijavljivanje nije dovršeno
secrets-unavailable = { $store } nije dostupan
secrets-unavailable-why = { $store } nije dostupan: { $error }
secrets-windows = Upravljač akreditivima
secrets-mac = privezak ključeva
secrets-linux = sistemski privezak ključeva (Secret Service)
error-no-such-file = ta datoteka ne postoji
cards-file-too-big = Ova datoteka je prevelika da bi bila adresar.
ui-sender-added = U Adresar je dodat kontakt: { $name }.
ui-sender-known = Kontakt { $name } je već u Adresaru.
ui-sender-none = Pošiljalac ove poruke nema adresu e-pošte koja bi mogla da se doda.
card-name-needed = Kontakt nema ni ime ni adresu e-pošte.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Kôd sa domena { $domain }
otp-copy = Kopiraj
otp-note = Unesite ga samo na stranici domena { $domain }.
otp-old = Ovaj kôd je poslat više od sat vremena pre nego što ste otvorili poruku i verovatno je istekao.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } učesnik
        [few] { $count } učesnika
       *[other] { $count } učesnika
}

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } je vaš kôd za { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Važeći
pgp-key-expires = Važeći do { $date }
pgp-key-expired = Istekao { $date }
pgp-key-revoked = Opozvan
pgp-key-revoked-why = Opozvan: { $reason }
pgp-key-not-valid = Nije važeći
pgp-key-locked = Ključ ne može da se koristi jer ključ za njegovu zaštitu više nije dostupan u sistemskom skladištu ({ $store }). Ponovo uvezite rezervnu kopiju privatnog ključa.
pgp-source-own = Napravljen u programu Inbox Classic
pgp-source-file = Uvezen iz datoteke
pgp-source-paste = Nalepljen
pgp-source-attachment = Iz poruke
pgp-source-vcard = Iz kartice kontakta
pgp-source-wkd = Iz servisa ključeva domena (WKD)
pgp-source-keyserver = Sa servera keys.openpgp.org
pgp-source-autocrypt = Iz Autocrypt zaglavlja poruke
pgp-error-no-store = Sistemsko skladište koje štiti privatne ključeve ({ $store }) nije dostupno: { $error }
pgp-error-wrong-passphrase = Pristupna fraza nije tačna.
pgp-error-not-a-key = Ovo nije OpenPGP ključ.
pgp-error-too-large = Ključ je prevelik.
pgp-error-unusable = Ključ koristi staru ili slabu kriptografiju i ne može da se koristi.
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
pgp-imported-pending = Za sledeće adrese već se koristi drugi ključ: { $addresses }. Novi ključ možete da izaberete u svojstvima kontakta.
pgp-error-needs-passphrase = Privatni ključ je zaštićen pristupnom frazom. Unesite je da biste uvezli ključ.
pgp-error-mismatch = Privatni ključ ne odgovara javnom ključu. Podaci o ključu su možda izmenjeni.
pgp-file-name-public = { $who } - javni ključ.asc
pgp-file-name-private = { $who } - rezervna kopija privatnog ključa.asc
pgp-pending = Drugi ključ za { $address } je pronađen { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Potpisnik: { $signer }; vlasništvo nad ključem je provereno
pgp-part-signed = Potpisnik: { $signer }; vlasništvo nad ključem nije provereno
pgp-part-other = Potpisnik: { $signer }; potpis ne odgovara adresi pošiljaoca
pgp-part-unknown-key = Potpisano, ali ključ nije poznat
pgp-part-not-signed = Nije potpisano
pgp-part-not-checked = Potpis nije proveren
pgp-part-encrypted = Šifrovano. { $signature }
pgp-part-no-key = Šifrovano za ključ koji nemate
pgp-part-changed = Nije moguće potvrditi da je šifrovani deo neizmenjen, pa se ne prikazuje
pgp-part-unprotected = Šifrovano bez zaštite od izmena, ne prikazuje se
pgp-part-broken = Šifrovani deo ne može da se pročita
pgp-why-mismatch = Potpis ne odgovara ovom tekstu
pgp-why-weak-hash = Potpis koristi heš funkciju { $hash }, koja se više ne smatra bezbednom
pgp-why-key-expired = Potpisano nakon što je ključ istekao { $date }
pgp-why-key-revoked = Potpisano opozvanim ključem
pgp-why-not-signing-key = Potpisano ključem koji nije namenjen za potpisivanje
pgp-why-from-future = Potpis ima datum u budućnosti
pgp-why-signature-expired = Potpis je istekao
pgp-why-key-not-valid = Potpisano ključem koji nije važeći
pgp-why-not-for-you = Potpisano za druge primaoce i prosleđeno vama
pgp-part-pictures-loaded = { $label }. Slike su učitane sa interneta
pgp-error-no-own-key = Nemate ključ za { $address } kojim biste potpisivali ili šifrovali. Napravite ga u meniju Alatke > Ključevi za šifrovanje ili isključite Potpiši i Šifruj.
pgp-error-missing-keys = { $count ->
    [1] { $addresses } nema ključ za šifrovanje.
   *[other] Ovi primaoci nemaju ključ za šifrovanje: { $addresses }.
}
pgp-error-encrypted-quote = Ova poruka citira ili prosleđuje šifrovanu poruku, pa može da se pošalje samo šifrovana. Uključite Šifruj ili uklonite citirani tekst.
pgp-error-protect = Poruku nije moguće potpisati ni šifrovati: { $reason }
pgp-found-keys = Pronađeni su ključevi za sledeće adrese: { $addresses }.
pgp-found-none = Nisu pronađeni ključevi za sledeće adrese: { $addresses }. Zamolite primaoce da vam pošalju svoje javne ključeve.
pgp-found-no-key = Nije pronađen nijedan ključ.
pgp-find-unavailable = Ključeve sada nije moguće potražiti: { $error }
pgp-publish-pending = keys.openpgp.org je poslao poruke sa vezama za potvrdu na sledeće adrese: { $addresses }. Kliknite na vezu u svakoj poruci da bi ključ mogao da se pronađe pretragom te adrese.
pgp-publish-done = Vaš ključ može da se pronađe na keys.openpgp.org pretragom sledećih adresa: { $addresses }.
pgp-publish-failed = Ključ nije moguće objaviti: { $error }
pgp-keyserver-off = Pretraga ključeva na serveru keys.openpgp.org isključena je u podešavanjima { $settings }.
pgp-details-part = Deo { $number }: { $label }
pgp-details-signed = Potpisano { $when } ključem { $key }
pgp-details-unknown-key = Potpisano ključem { $key }, koji nemate
pgp-details-opened = Dešifrovano vašim ključem { $key }
pgp-details-for = Šifrovano za { $keys }
pgp-details-plain = Nije potpisano ni šifrovano
pgp-bar-parts = Ova poruka ima više delova ({ $count }): { $list }. Za svaki deo je navedeno kako je zaštićen.
pgp-bar-count-verified = Provereno: { $count }
pgp-bar-count-good = { $count ->
    [one] { $count } potpisan ili šifrovan deo
    [few] { $count } potpisana ili šifrovana dela
   *[other] { $count } potpisanih ili šifrovanih delova
}
pgp-bar-count-warning = { $count ->
    [one] { $count } traži pažnju
    [few] { $count } traže pažnju
   *[other] { $count } traži pažnju
}
pgp-bar-count-neutral = Bez potvrđenog potpisa: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Podešavanja
setup-part-preferences = Podešavanja prozora
setup-part-accounts = Nalozi
setup-part-sign-in-apps = Aplikacije za prijavljivanje
setup-part-contacts = Kontakti i grupe
setup-part-keys = Ključevi za šifrovanje
setup-part-rules = Pravila za poruke
setup-part-trusted-senders = Pouzdani pošiljaoci
setup-holds-settings = { $count ->
    [one] { $count } podešavanje
    [few] { $count } podešavanja
   *[other] { $count } podešavanja
}
setup-holds-preferences = { $count ->
    [one] { $count } podešavanje prozora
    [few] { $count } podešavanja prozora
   *[other] { $count } podešavanja prozora
}
setup-holds-accounts = { $count ->
    [one] { $count } nalog
    [few] { $count } naloga
   *[other] { $count } naloga
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavljivanje
    [few] { $count } aplikacije za prijavljivanje
   *[other] { $count } aplikacija za prijavljivanje
}
setup-holds-built-in = Koje su ugrađene aplikacije za prijavljivanje uključene
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
    [one] { $count } vaš ključ
    [few] { $count } vaša ključa
   *[other] { $count } vaših ključeva
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
    [one] { $count } pouzdani pošiljalac
    [few] { $count } pouzdana pošiljaoca
   *[other] { $count } pouzdanih pošiljalaca
}
setup-sign-in-password = Lozinka
setup-account-secret-password = Sačuvana lozinka je uključena u datoteku.
setup-account-secret-token = Sačuvani podaci za prijavu su uključeni u datoteku.
setup-account-asks-password = Nakon uvoza moraćete da unesete lozinku.
setup-account-signs-in-again = Nakon uvoza moraćete ponovo da se prijavite putem pregledača.
setup-account-here = Nalog je već podešen na ovom računaru i biće preskočen.
setup-account-no-app = Nalog koristi aplikaciju za prijavljivanje { $app }, koja ovde nije podešena. Uvezite i aplikacije za prijavljivanje.
setup-invalid-address = „{ $address }“ nije adresa e-pošte.
setup-invalid-server = Naziv servera ili port za { $server } nije važeći.
setup-invalid-user = Nalog nema korisničko ime.
setup-invalid-sign-in = Nalog koristi način prijavljivanja koji Inbox Classic ne podržava.
setup-error-empty = Datoteka je prazna.
setup-error-too-large = Datoteka je prevelika da bi bila datoteka podešavanja programa Inbox Classic.
setup-error-not-setup = Ova datoteka nije datoteka podešavanja programa Inbox Classic.
setup-error-damaged = Datoteka podešavanja je oštećena i ne može da se pročita.
setup-error-newer = Ovu datoteku je sačuvala novija verzija programa Inbox Classic ({ $version }). Ažurirajte Inbox Classic, a zatim je ponovo uvezite.
setup-error-needs-passphrase = Ova datoteka je zaštićena pristupnom frazom. Unesite pristupnu frazu sa kojom je sačuvana.
setup-error-wrong-passphrase = To nije pristupna fraza sa kojom je ova datoteka sačuvana.
setup-error-changed = Datoteka podešavanja je promenjena ili oštećena nakon čuvanja, pa ne može da se uveze.
setup-error-read = Datoteku podešavanja nije moguće pročitati: { $error }
setup-error-write = Podešavanja nije moguće sačuvati: { $error }
setup-error-no-parts = Izaberite bar jednu kategoriju.
setup-left-out = { $count ->
    [one] { $count } stavka (kategorija: { $part }) ne može da se koristi i izostavljena je.
    [few] { $count } stavke (kategorija: { $part }) ne mogu da se koriste i izostavljene su.
   *[other] { $count } stavki (kategorija: { $part }) ne može da se koristi i izostavljeno je.
}
setup-imported-settings = Podešavanja su zamenjena.
setup-imported-preferences = Podešavanja prozora su zamenjena.
setup-added-accounts = { $count ->
    [one] Dodat je { $count } nalog.
    [few] Dodata su { $count } naloga.
   *[other] Dodato je { $count } naloga.
}
setup-skipped-here = Nalog { $address } je već podešen na ovom računaru i preskočen je.
setup-skipped-no-app = Nalog { $address } je preskočen jer aplikacija za prijavljivanje { $app } nije podešena na ovom računaru.
setup-skipped-invalid = Nalog { $address } je preskočen: { $reason }
setup-asks-password = Pri povezivanju naloga { $address } biće zatražena lozinka.
setup-signs-in-again = Pri povezivanju naloga { $address } biće zatražena ponovna prijava putem pregledača.
setup-added-sign-in-apps = { $count ->
    [one] Dodata je { $count } aplikacija za prijavljivanje.
    [few] Dodate su { $count } aplikacije za prijavljivanje.
   *[other] Dodato je { $count } aplikacija za prijavljivanje.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavljivanje je već podešena ovde.
    [few] { $count } aplikacije za prijavljivanje su već podešene ovde.
   *[other] { $count } aplikacija za prijavljivanje je već podešeno ovde.
}
setup-added-contacts = { $count ->
    [one] U adresar je dodat { $count } kontakt.
    [few] U adresar su dodata { $count } kontakta.
   *[other] U adresar je dodato { $count } kontakata.
}
setup-skipped-contacts = { $count ->
    [one] { $count } kontakt je već u adresaru.
    [few] { $count } kontakta su već u adresaru.
   *[other] { $count } kontakata je već u adresaru.
}
setup-added-groups = { $count ->
    [one] Dodata ili dopunjena je { $count } grupa.
    [few] Dodate ili dopunjene su { $count } grupe.
   *[other] Dodato ili dopunjeno je { $count } grupa.
}
setup-added-own-keys = { $count ->
    [one] Dodat je { $count } vaš ključ.
    [few] Dodata su { $count } vaša ključa.
   *[other] Dodato je { $count } vaših ključeva.
}
setup-added-contact-keys = { $count ->
    [one] Dodat je { $count } ključ kontakta.
    [few] Dodata su { $count } ključa kontakata.
   *[other] Dodato je { $count } ključeva kontakata.
}
setup-added-rules = { $count ->
    [one] Dodato je { $count } pravilo za poruke.
    [few] Dodata su { $count } pravila za poruke.
   *[other] Dodato je { $count } pravila za poruke.
}
setup-skipped-rules = { $count ->
    [one] { $count } pravilo za poruke već postoji.
    [few] { $count } pravila za poruke već postoje.
   *[other] { $count } pravila za poruke već postoji.
}
setup-skipped-rules-account = { $count ->
    [1] 1 pravilo za poruke odnosi se na nalog koji ovde ne postoji, pa je preskočeno.
    [one] { $count } pravilo za poruke odnosi se na naloge koji ovde ne postoje, pa je preskočeno.
    [few] { $count } pravila za poruke odnose se na naloge koji ovde ne postoje, pa su preskočena.
   *[other] { $count } pravila za poruke odnosi se na naloge koji ovde ne postoje, pa je preskočeno.
}
setup-rules-waiting = { $count ->
    [1] Odredišnu fasciklu za 1 pravilo treba pronaći pri sinhronizaciji naloga.
    [one] Broj pravila čije odredišne fascikle treba pronaći pri sinhronizaciji naloga: { $count }.
    [few] Broj pravila čije odredišne fascikle treba pronaći pri sinhronizaciji naloga: { $count }.
   *[other] Broj pravila čije odredišne fascikle treba pronaći pri sinhronizaciji naloga: { $count }.
}
setup-added-trusted-senders = { $count ->
    [one] Dodat je { $count } pouzdani pošiljalac.
    [few] Dodata su { $count } pouzdana pošiljaoca.
   *[other] Dodato je { $count } pouzdanih pošiljalaca.
}
setup-nothing = Ništa nije uvezeno.
setup-account-servers = { $imap } i { $smtp } ({ $signin })
setup-file-name = Podešavanja i nalozi programa Inbox Classic
setup-skipped-unreachable = Aplikacija { $name } je preskočena jer njena usluga za prijavljivanje nije dostupna. Ponovo je dodajte u prozoru Aplikacije za prijavljivanje.
attachment-runs-programs = Datoteka „{ $name }“ može da izvršava kôd, pa je Inbox Classic ne otvara direktno. Sačuvajte je i otvorite sami samo ako verujete njenom izvoru.
attachment-decrypted-note = Ovaj prilog potiče iz šifrovane poruke. Da bi ga otvorio u drugom programu, Inbox Classic čuva privremenu dešifrovanu kopiju u fascikli vašeg korisničkog naloga. Kopije starije od 24 sata uklanjaju se pri sledećem pokretanju programa.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [1] Server nije premestio poruku u fasciklu { $folder } ({ $messages }), pa je ona ponovo u fascikli { $from }: { $reason }
   *[other] Server nije premestio poruke u fasciklu { $folder } ({ $messages }), pa su one ponovo u fascikli { $from }: { $reason }
}
undone-delete = { $count ->
    [1] Server nije izbrisao poruku ({ $messages }), pa je ona ponovo u fascikli { $from }: { $reason }
   *[other] Server nije izbrisao poruke ({ $messages }), pa su one ponovo u fascikli { $from }: { $reason }
}
undone-archive = { $count ->
    [1] Server nije arhivirao poruku ({ $messages }), pa je ona ponovo u fascikli { $from }: { $reason }
   *[other] Server nije arhivirao poruke ({ $messages }), pa su one ponovo u fascikli { $from }: { $reason }
}
undone-read = { $count ->
    [1] Server nije označio poruku kao pročitanu ({ $messages }), pa je ona ponovo nepročitana: { $reason }
   *[other] Server nije označio poruke kao pročitane ({ $messages }), pa su one ponovo nepročitane: { $reason }
}
undone-unread = { $count ->
    [1] Server nije označio poruku kao nepročitanu ({ $messages }), pa je ona ponovo pročitana: { $reason }
   *[other] Server nije označio poruke kao nepročitane ({ $messages }), pa su one ponovo pročitane: { $reason }
}
undone-flags = { $count ->
    [1] Server nije promenio zastavice poruke ({ $messages }), pa je promena poništena: { $reason }
   *[other] Server nije promenio zastavice poruka ({ $messages }), pa je promena poništena: { $reason }
}
