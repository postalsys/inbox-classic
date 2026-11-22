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
# review: new
list-separator = { ", " }
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
reader-failed-network = Povezivanje sa serverom e-pošte nije uspelo ili je veza prekinuta ({ $reason }).
reader-failed-sign-in = Server e-pošte nije prihvatio prijavu ({ $reason }). Proverite lozinku ili se ponovo prijavite u podešavanjima naloga.
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
bounce-virus-detected-why = Server primaoca navodi da je pronašao virus ili drugi štetni sadržaj u poruci ili njenim prilozima.
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
bounce-relay-denied-do = U podešavanjima naloga proverite server odlazne pošte i da li je uključena prijava na taj server.
bounce-auth-failure = Domen pošiljaoca nije moguće potvrditi
bounce-auth-failure-why = Server primaoca nije mogao da potvrdi da je poruka zaista stigla sa vašeg domena (SPF, DKIM ili DMARC).
bounce-auth-failure-do = Prosledite ovo obaveštenje osobi koja upravlja e-poštom vašeg domena da proveri podešavanja. U međuvremenu pokušajte da šaljete preko servera svog pružaoca usluge.
bounce-rate-limited = Previše pošte odjednom
bounce-rate-limited-why = Server primaoca zasad prima manje poruka sa vašeg servera e-pošte.
bounce-rate-limited-do = Sačekajte neko vreme i pošaljite je ponovo. Kada pišete mnogim ljudima, šaljite poruku manjem broju njih odjednom.
bounce-greylisting = Isporuka je privremeno odložena
bounce-greylisting-why = Server primaoca traži od nepoznatih pošiljalaca da pokušaju ponovo malo kasnije, što je uobičajena zaštita od neželjene pošte.
bounce-greylisting-do = Kod privremenog odlaganja server obično pokušava ponovo. Ako izveštaj pokazuje konačni neuspeh isporuke, pokušajte kasnije ponovo da pošaljete poruku.
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
   *[other] Dodato u red za uvoz: { $messages } (odredište: { $folder })
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
error-provider-missing = aplikacija za prijavljivanje nije dostupna. Identifikator: { $provider }. Možda je uklonjena
error-provider-servers = serveri ovog naloga ne odgovaraju serverima njegove aplikacije za prijavljivanje
error-app-scopes = { $reason }. Server e-pošte nije prihvatio token aplikacije za prijavljivanje: proverite da li opsezi (scopes) aplikacije daju pristup pošti
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Ugrađena Google aplikacija podrazumevano se ne nudi za nove naloge. Odobreni test korisnici mogu da je uključe u prozoru Aplikacije za prijavljivanje (Datoteka > Nalozi). Možete da koristite i sopstvenu Google aplikaciju ili lozinku za aplikaciju ako je nalog podržava.
sign-in-off-other = Ne nudi se za nove naloge. Možete da je uključite u prozoru Aplikacije za prijavljivanje (Datoteka > Nalozi).
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

agent-level-read = Čitanje pošte: fascikle, lista poruka, razgovori, pretraga, poruke i prilozi, pravila za poruke i osobe kojima pišete
agent-level-organize = Organizovanje pošte: promena stanja pročitanosti, zastavica i njihovih boja, upravljanje neželjenom poštom, premeštanje i arhiviranje poruka, pravljenje i preimenovanje fascikli, praćenje i zanemarivanje razgovora, brisanje poruka premeštanjem u Izbrisane stavke i otkazivanje pretplata uz vaše odobrenje
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
agent-too-many-changes = Dostignuto je ograničenje broja promena koje dnevnik čuva za ovaj program tokom 30 dana. Nove promene biće moguće kada najstariji zapisi isteknu.
agent-too-many-reads = Dostignuto je ograničenje čitanja koje dnevnik čuva za ovaj program tokom 30 dana. Novo čitanje biće moguće kada najstariji zapisi isteknu.
list-encrypted = Šifrovana poruka
agent-log-composed = Poruka „{ $subject }“ je otvorena za uređivanje da biste je dovršili
agent-log-refused = Odbili ste slanje poruke „{ $subject }“
agent-log-sent = Poruka „{ $subject }“ je stavljena u red za slanje; primaoci: { $to }
agent-log-draft = Sačuvana radna verzija „{ $subject }“
agent-log-draft-replaced = Zamenjena radna verzija „{ $subject }“
agent-log-draft-discarded = Zatraženo trajno brisanje radne verzije „{ $subject }“
agent-draft-note = { $program }, AI agent, napisao je ovu radnu verziju. Pre slanja proverite primaoce i tekst.
agent-log-read = Označeno kao pročitano: „{ $subject }“
agent-log-unread = Označeno kao nepročitano: „{ $subject }“
agent-log-flagged = Označeno zastavicom: „{ $subject }“
agent-log-unflagged = Uklonjena zastavica: „{ $subject }“
agent-log-deleted = Poruka „{ $subject }“ je premeštena u fasciklu Izbrisane stavke
agent-log-moved = Premešteno: „{ $subject }“ (odredište: { $folder })
agent-log-junk = Označeno kao neželjena pošta: „{ $subject }“
agent-log-not-junk = Označeno kao poželjna pošta: „{ $subject }“
agent-log-archived = Arhivirano: „{ $subject }“
agent-log-folder = Zatraženo pravljenje fascikle „{ $name }“
agent-log-unsubscribed = Odobrili ste zahtev za otkazivanje pretplate. Poruka: „{ $subject }“
agent-log-unsubscribe-failed = Otkazivanje pretplate na listu sa koje je stigla poruka „{ $subject }“ nije uspelo: { $reason }
agent-log-unsubscribe-refused = Niste odobrili otkazivanje pretplata. Pošiljaoci: { $senders }
agent-unsubscribe-title = { $count ->
    [1] { $program } želi da otkaže vašu pretplatu na listu za slanje pošte
    [one] { $program } želi da otkaže vaše pretplate na { $count } listu za slanje pošte
    [few] { $program } želi da otkaže vaše pretplate na { $count } liste za slanje pošte
   *[other] { $program } želi da otkaže vaše pretplate na { $count } lista za slanje pošte
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic šalje zahtev da vam sa navedene liste više ne stižu poruke, koristeći opciju za otkazivanje pretplate jednim klikom. Ništa drugo se ne šalje. Postojeće poruke se ne menjaju niti premeštaju.
   *[other] Inbox Classic šalje zahtev da vam sa svake od navedenih lista više ne stižu poruke, koristeći opciju za otkazivanje pretplate jednim klikom. Ništa drugo se ne šalje. Postojeće poruke se ne menjaju niti premeštaju.
}
agent-log-flag-color = Označeno zastavicom: „{ $subject }“, boja: { $color ->
    [red] crvena
    [orange] narandžasta
    [yellow] žuta
    [green] zelena
    [blue] plava
    [purple] ljubičasta
   *[gray] siva
}
agent-log-renamed = Zatražena promena naziva fascikle „{ $old }“ u „{ $name }“
agent-log-watched = Uključeno praćenje razgovora: „{ $subject }“
agent-log-ignored = Uključeno zanemarivanje razgovora: „{ $subject }“
agent-log-unmarked = Isključeno praćenje ili zanemarivanje razgovora: „{ $subject }“
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = poruka je u međuvremenu promenjena
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Označeno kao pročitano: { $count } poruka (pretraga: { $query })
    [few] Označeno kao pročitano: { $count } poruke (pretraga: { $query })
   *[other] Označeno kao pročitano: { $count } poruka (pretraga: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Označeno kao nepročitano: { $count } poruka (pretraga: { $query })
    [few] Označeno kao nepročitano: { $count } poruke (pretraga: { $query })
   *[other] Označeno kao nepročitano: { $count } poruka (pretraga: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Označeno zastavicom: { $count } poruka (pretraga: { $query })
    [few] Označeno zastavicom: { $count } poruke (pretraga: { $query })
   *[other] Označeno zastavicom: { $count } poruka (pretraga: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Uklonjena zastavica: { $count } poruka (pretraga: { $query })
    [few] Uklonjena zastavica: { $count } poruke (pretraga: { $query })
   *[other] Uklonjena zastavica: { $count } poruka (pretraga: { $query })
}
agent-log-bulk-color = { $count ->
    [one] Označeno zastavicom: { $count } poruka
    [few] Označeno zastavicom: { $count } poruke
   *[other] Označeno zastavicom: { $count } poruka
}, boja: { $color ->
    [red] crvena
    [orange] narandžasta
    [yellow] žuta
    [green] zelena
    [blue] plava
    [purple] ljubičasta
   *[gray] siva
} (pretraga: { $query })
agent-log-bulk-moved = { $count ->
    [one] Premešteno: { $count } poruka, odredište: { $folder } (pretraga: { $query })
    [few] Premešteno: { $count } poruke, odredište: { $folder } (pretraga: { $query })
   *[other] Premešteno: { $count } poruka, odredište: { $folder } (pretraga: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Arhivirano: { $count } poruka (pretraga: { $query })
    [few] Arhivirano: { $count } poruke (pretraga: { $query })
   *[other] Arhivirano: { $count } poruka (pretraga: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Označeno kao neželjena pošta: { $count } poruka (pretraga: { $query })
    [few] Označeno kao neželjena pošta: { $count } poruke (pretraga: { $query })
   *[other] Označeno kao neželjena pošta: { $count } poruka (pretraga: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Označeno kao poželjna pošta: { $count } poruka (pretraga: { $query })
    [few] Označeno kao poželjna pošta: { $count } poruke (pretraga: { $query })
   *[other] Označeno kao poželjna pošta: { $count } poruka (pretraga: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Premešteno u fasciklu Izbrisane stavke: { $count } poruka (pretraga: { $query })
    [few] Premešteno u fasciklu Izbrisane stavke: { $count } poruke (pretraga: { $query })
   *[other] Premešteno u fasciklu Izbrisane stavke: { $count } poruka (pretraga: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] U poslednjih 15 minuta
    [hour] U poslednjih sat vremena
    [hours] U poslednja 4 sata
    [day] U poslednja 24 sata
    [week] U poslednjih 7 dana
   *[all] U poslednjih 30 dana
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] Program { $program } u ovom periodu nema zabeleženih promena koje mogu da se opozovu.
    [one] Da li želite da pokušate da opozovete promene iz dnevnika programa { $program } za ovaj period? Broj zapisa: { $count }.
    [few] Da li želite da pokušate da opozovete promene iz dnevnika programa { $program } za ovaj period? Broj zapisa: { $count }.
   *[other] Da li želite da pokušate da opozovete promene iz dnevnika programa { $program } za ovaj period? Broj zapisa: { $count }.
}
agent-undo-since-detail = Inbox Classic pokušava da vrati poruke u prethodne fascikle, obnovi stanje pročitanosti i zastavice i izbriše poruke koje još čekaju u fascikli Izlazno sanduče. Promene koje više ne mogu da se opozovu preskaču se. Neke naknadne promene boje zastavice ipak mogu da budu prepisane.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Ništa nije opozvano.
    [one] Opozvana je { $count } promena, u potpunosti ili delimično.
    [few] Opozvane su { $count } promene, u potpunosti ili delimično.
   *[other] Opozvano je { $count } promena, u potpunosti ili delimično.
}
agent-undo-left-gone = { $count ->
    [one] { $count } poruka više nije bila u fascikli u koju je premeštena.
    [few] { $count } poruke više nisu bile u fasciklama u koje su premeštene.
   *[other] { $count } poruka više nije bilo u fasciklama u koje su premeštene.
}
agent-undo-left-changed = { $count ->
    [one] { $count } poruka je u međuvremenu promenjena na vašem računaru ili na serveru, pa je ostavljena kakva jeste.
    [few] { $count } poruke su u međuvremenu promenjene na vašem računaru ili na serveru, pa su ostavljene kakve jesu.
   *[other] { $count } poruka je u međuvremenu promenjeno na vašem računaru ili na serveru, pa su ostavljene kakve jesu.
}
agent-undo-left-sent = { $count ->
    [one] { $count } poruka više nije bila u fascikli Izlazno sanduče i nije mogla da se opozove ovde.
    [few] { $count } poruke više nisu bile u fascikli Izlazno sanduče i nisu mogle da se opozovu ovde.
   *[other] { $count } poruka više nije bilo u fascikli Izlazno sanduče i nisu mogle da se opozovu ovde.
}
agent-undo-left-impossible = { $count ->
    [one] { $count } promena ne može da se opozove.
    [few] { $count } promene ne mogu da se opozovu.
   *[other] { $count } promena ne može da se opozove.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Ova poruka prihvata pozivnicu „{ $summary }“ ({ $when }).
    [tentative] Ova poruka uslovno prihvata pozivnicu „{ $summary }“ ({ $when }).
   *[decline] Ova poruka odbija pozivnicu „{ $summary }“ ({ $when }).
} Odgovor se šalje organizatoru navedenom u pozivnici. Lokalni status menja se kada server prihvati slanje, što ne potvrđuje da je kalendar organizatora ažuriran.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Prihvaćeno: { $summary }
    [tentative] Uslovno prihvaćeno: { $summary }
   *[decline] Odbijeno: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } prihvata ovu pozivnicu.
    [tentative] { $name } uslovno prihvata ovu pozivnicu.
   *[decline] { $name } odbija ovu pozivnicu.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] pročitana { $count } poruka
    [few] pročitane { $count } poruke
   *[other] pročitano { $count } poruka
}
agent-reads-attachments = { $count ->
    [one] zatražen { $count } prilog
    [few] zatražena { $count } priloga
   *[other] zatraženo { $count } priloga
}
agent-reads-searches = { $count ->
    [one] { $count } pretraga
    [few] { $count } pretrage
   *[other] { $count } pretraga
}
agent-reads-lists = { $count ->
    [one] { $count } pregled liste poruka
    [few] { $count } pregleda liste poruka
   *[other] { $count } pregleda liste poruka
}
# each read under that row
agent-read-message = Pročitano: „{ $subject }“
agent-read-conversation = { $count ->
    [one] Pročitan razgovor „{ $subject }“ ({ $count } poruka)
    [few] Pročitan razgovor „{ $subject }“ ({ $count } poruke)
   *[other] Pročitan razgovor „{ $subject }“ ({ $count } poruka)
}
agent-read-attachment = Zatražen prilog „{ $name }“ iz poruke „{ $subject }“
agent-read-search = { $count ->
    [one] Pretraga za „{ $query }“: { $count } poruka
    [few] Pretraga za „{ $query }“: { $count } poruke
   *[other] Pretraga za „{ $query }“: { $count } poruka
}
agent-read-people = Pretraga osoba po početku imena ili adrese: „{ $query }“
agent-read-list = { $count ->
    [one] Pregled liste: { $count } stavka. Opseg: { $folder }
    [few] Pregled liste: { $count } stavke. Opseg: { $folder }
   *[other] Pregled liste: { $count } stavki. Opseg: { $folder }
}
agent-read-changes = { $count ->
    [one] Pregledani podaci o novim porukama: { $count } poruka
    [few] Pregledani podaci o novim porukama: { $count } poruke
   *[other] Pregledani podaci o novim porukama: { $count } poruka
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Programi pokrenuti iz aplikacije { $terminal }
agent-terminal-programs-windows = Programi pokrenuti iz terminala ({ $terminal })
agent-terminal-programs-linux = Programi pokrenuti iz terminala ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Program pokrenut iz aplikacije { $terminal }
agent-terminal-program-windows = Program pokrenut iz terminala ({ $terminal })
agent-terminal-program-linux = Program pokrenut iz terminala ({ $terminal })
agent-connect-title-terminal = { $programs } žele da koriste vašu poštu
agent-connect-terminal-detail = AI agenti pokrenuti iz iste prepoznate terminalske aplikacije dele pristup koji ovde dozvolite. Za zasebne dozvole dodajte --name i naziv po izboru među argumente u MCP podešavanjima agenta. Taj naziv ne potvrđuje identitet programa.
agent-connect-claimed = Program se predstavio kao { $claimed }. Inbox Classic je proverio koji ga je program pokrenuo: { $program }.

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
cards-file-too-big = Datoteka premašuje dozvoljenu veličinu za uvoz adresara.
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
pgp-key-locked = Ključ ne može da se koristi jer zaštitni ključ nije dostupan u skladištu { $store }. Proverite da li je skladište dostupno i otključano. Ako zaštitni ključ nedostaje, uvezite rezervnu kopiju privatnog ključa.
pgp-source-own = Napravljen u programu Inbox Classic
pgp-source-file = Uvezen iz datoteke
pgp-source-paste = Nalepljen
pgp-source-attachment = Iz poruke
pgp-source-vcard = Iz kartice kontakta
pgp-source-wkd = Iz servisa ključeva domena (WKD)
pgp-source-keyserver = Sa servera keys.openpgp.org
pgp-source-autocrypt = Iz Autocrypt zaglavlja poruke
pgp-error-no-store = Privatni ključevi šifrovani su zaštitnim ključem u sistemskom skladištu { $store }, koje nije dostupno: { $error }
pgp-error-wrong-passphrase = Pristupna fraza nije tačna.
pgp-error-not-a-key = Ovo nije OpenPGP ključ.
pgp-error-too-large = Ključ je prevelik.
pgp-error-unusable = Ključ ne može da se koristi. Možda nema upotrebljiv potključ ili koristi nepodržanu kriptografiju.
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
pgp-part-other = Potpisnik: { $signer } (nije pošiljalac)
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
pgp-why-not-key-in-use = Potpisano ključem koji se razlikuje od onog izabranog za adresu { $address }
pgp-part-pictures-loaded = { $label }. Slike su učitane sa interneta
pgp-error-no-own-key = Nemate ključ za { $address } kojim biste potpisivali ili šifrovali. Napravite ga u meniju Alatke > Ključevi za šifrovanje ili isključite Potpiši i Šifruj.
pgp-error-missing-keys = { $count ->
    [1] Nema upotrebljivog ključa za šifrovanje za ovog primaoca: { $addresses }.
   *[other] Nema upotrebljivih ključeva za šifrovanje za ove primaoce: { $addresses }.
}
pgp-error-encrypted-quote = Poruka sadrži tekst, slike ili priloge iz šifrovane poruke i može da se pošalje samo šifrovana. Uključite Šifruj ili uklonite sav taj sadržaj.
pgp-error-protect = Poruku nije moguće potpisati ni šifrovati: { $reason }
pgp-found-keys = Pronađeni su ključevi za sledeće adrese: { $addresses }.
pgp-found-none = Nisu pronađeni ključevi za sledeće adrese: { $addresses }. Zamolite primaoce da vam pošalju svoje javne ključeve.
pgp-found-no-key = Nije pronađen nijedan ključ.
pgp-find-unavailable = Ključeve sada nije moguće potražiti: { $error }
pgp-publish-pending = keys.openpgp.org je poslao poruke sa vezama za potvrdu na sledeće adrese: { $addresses }. Kliknite na vezu u svakoj poruci da bi ključ mogao da se pronađe pretragom te adrese.
pgp-publish-done = Vaš ključ može da se pronađe na keys.openpgp.org pretragom sledećih adresa: { $addresses }.
pgp-publish-failed = Ključ nije moguće objaviti: { $error }
pgp-keyserver-off = Pretraga ključeva na serveru keys.openpgp.org isključena je u podešavanjima { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [1] Poruka će biti šifrovana i potpisana pri slanju. Sadržaj možete da pročitate samo vi i { $addresses }.
    [one] Poruka će biti šifrovana i potpisana pri slanju. Sadržaj možete da pročitate samo vi i { $count } primalac.
    [few] Poruka će biti šifrovana i potpisana pri slanju. Sadržaj možete da pročitate samo vi i { $count } primaoca.
   *[other] Poruka će biti šifrovana i potpisana pri slanju. Sadržaj možete da pročitate samo vi i { $count } primalaca.
}
pgp-compose-encrypt-ready = Poruka će biti šifrovana i potpisana pri slanju. Dodajte primaoce za koje imate upotrebljive ključeve.
pgp-compose-missing = { $count ->
    [1] Za ovog primaoca nema upotrebljivog ključa: { $addresses }. Poruka još ne može da se šifruje.
    [one] { $count } primalac nema upotrebljiv ključ: { $addresses }. Poruka još ne može da se šifruje.
    [few] { $count } primaoca nemaju upotrebljiv ključ: { $addresses }. Poruka još ne može da se šifruje.
   *[other] { $count } primalaca nema upotrebljiv ključ: { $addresses }. Poruka još ne može da se šifruje.
}
pgp-compose-looking = Traže se ključevi za: { $addresses }...
pgp-compose-signed = Poruka će biti digitalno potpisana pri slanju. Primaoci će moći da provere potpis i da li je sadržaj izmenjen.
pgp-compose-reply-clear = Šifrovanje je isključeno, iako je izvorna poruka bila šifrovana.
pgp-compose-encrypted-files = Poruka sadrži priloge iz šifrovane poruke i može da se pošalje samo šifrovana. Uključite opciju „Šifruj“ ili uklonite te priloge.
pgp-compose-sign-tip = Digitalno potpišite poruku pri slanju da bi primaoci mogli da provere potpis i da li je sadržaj izmenjen
pgp-compose-sign-tip-encrypted = Šifrovane poruke se uvek potpisuju pri slanju
pgp-compose-encrypt-tip = Šifrujte sadržaj poruke pri slanju tako da ga možete pročitati samo vi i primaoci
pgp-compose-make-key = Još niste podesili sopstveni ključ za adresu { $address }. Da li želite da ga napravite sada? Njime možete da potpisujete i šifrujete poruke.
pgp-compose-key-unusable = Vaš ključ za adresu { $address } ne može da se koristi. Razlog: { $state }
    Otvorite prozor „Ključevi za šifrovanje“ da biste uvezli rezervnu kopiju tog ključa ili napravili novi.
pgp-compose-encrypt-off-quote = Poruka još sadrži tekst, slike ili priloge iz šifrovane poruke. Uklonite taj sadržaj pre slanja bez šifrovanja. Da li ipak želite da isključite šifrovanje?
pgp-compose-encrypt-off-reply = Izvorna poruka je bila šifrovana. Ako odgovor ili prosleđenu poruku pošaljete bez šifrovanja, serveri e-pošte mogu da pročitaju sadržaj. Da li želite da isključite šifrovanje?
pgp-recipient-verified = Ključ proveren
pgp-recipient-found = Ključ nije proveren
pgp-recipient-own = Vaš ključ
pgp-recipient-looking = Traži se ključ...
pgp-recipient-missing = Nema ključa
pgp-recipient-not-found = Nije pronađen ključ. Poslednja pretraga: { $date }
pgp-recipient-unusable = Ključ ne može da se koristi: { $state }
pgp-recipients-intro = Poruka će biti šifrovana ključevima primalaca i vašim ključem.
pgp-recipients-intro-missing = { $count ->
    [1] Jedan primalac nema upotrebljiv ključ. Pronađite ključ ili uklonite primaoca iz poruke. Slanje bez šifrovanja je moguće samo ako poruka ne sadrži tekst, slike ili priloge iz šifrovanih poruka.
    [one] { $count } primalac nema upotrebljiv ključ. Pronađite ključeve ili uklonite te primaoce iz poruke. Slanje bez šifrovanja je moguće samo ako poruka ne sadrži tekst, slike ili priloge iz šifrovanih poruka.
    [few] { $count } primaoca nemaju upotrebljiv ključ. Pronađite ključeve ili uklonite te primaoce iz poruke. Slanje bez šifrovanja je moguće samo ako poruka ne sadrži tekst, slike ili priloge iz šifrovanih poruka.
   *[other] { $count } primalaca nema upotrebljiv ključ. Pronađite ključeve ili uklonite te primaoce iz poruke. Slanje bez šifrovanja je moguće samo ako poruka ne sadrži tekst, slike ili priloge iz šifrovanih poruka.
}
pgp-details-part = Deo { $number }: { $label }
attachment-from-part = Iz dela { $number }: { $label }
pgp-details-signed = Potpisano { $when } ključem { $key }
pgp-details-unknown-key = Potpisano ključem { $key }, koji nemate
pgp-details-opened = Dešifrovano vašim ključem { $key }
pgp-details-for = Šifrovano za { $keys }
pgp-details-plain = Nije potpisano ni šifrovano
pgp-bar-parts = Ova poruka ima više delova ({ $count }): { $list }. Za svaki deo je navedeno kako je zaštićen.
pgp-bar-count-verified = Provereno: { $count }
pgp-bar-count-encrypted-signed = { $count ->
    [one] { $count } šifrovan i potpisan deo
    [few] { $count } šifrovana i potpisana dela
   *[other] { $count } šifrovanih i potpisanih delova
}
pgp-bar-count-encrypted = { $count ->
    [one] { $count } šifrovan deo
    [few] { $count } šifrovana dela
   *[other] { $count } šifrovanih delova
}
pgp-bar-count-signed = { $count ->
    [one] { $count } potpisan deo
    [few] { $count } potpisana dela
   *[other] { $count } potpisanih delova
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
setup-invalid-server = podešavanja za { $server } imaju nevažeći naziv servera, port ili nepoznatu bezbednosnu opciju
setup-invalid-user = Nalog nema korisničko ime.
setup-invalid-sign-in = stavka ima nevažeća podešavanja prijavljivanja
setup-error-empty = Datoteka je prazna.
setup-error-too-large = Datoteka podešavanja premašuje dozvoljenu veličinu.
setup-error-not-setup = Ova datoteka nije datoteka podešavanja programa Inbox Classic.
setup-error-damaged = Datoteka podešavanja je oštećena i ne može da se pročita.
setup-error-newer = Ovu datoteku je sačuvala novija verzija programa Inbox Classic ({ $version }). Ažurirajte Inbox Classic, a zatim je ponovo uvezite.
setup-error-needs-passphrase = Ova datoteka je zaštićena pristupnom frazom. Unesite pristupnu frazu sa kojom je sačuvana.
setup-error-wrong-passphrase = To nije pristupna fraza sa kojom je ova datoteka sačuvana.
setup-error-changed = Nije moguće potvrditi celovitost datoteke podešavanja. Možda je izmenjena ili oštećena i ne može da se uveze.
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
setup-skipped-unreachable = Preskočeno: { $name }. Usluga za prijavljivanje nije mogla da se dosegne ili proveri. Proverite potrebnu aplikaciju u prozoru Aplikacije za prijavljivanje pre ponovnog pokušaja.
attachment-runs-programs = Datoteka „{ $name }“ može da izvršava kôd, pa je Inbox Classic ne otvara direktno. Sačuvajte je i otvorite sami samo ako verujete njenom izvoru.
attachment-decrypted-note = Ovaj prilog potiče iz šifrovane poruke. Za otvaranje u drugom programu Inbox Classic čuva nešifrovanu kopiju u privremenoj fascikli vašeg korisničkog naloga. Pri pokretanju pokušava da ukloni kopije starije od jednog dana.
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

## Previews of attachments: the pictures and PDF files shown in a message

preview-pdf-option = Prikaži PDF datoteke u porukama
preview-pdf-off = PDF datoteke se ne prikazuju u porukama.
preview-pdf-off-crashed = Inbox Classic se zatvorio tokom prikazivanja datoteke u poruci, pa je pregled PDF datoteka isključen. Slike se i dalje prikazuju. Da biste ponovo prikazivali PDF datoteke, uključite { $option } u { $settings }.
preview-pdf-details = { $count ->
    [one] { $count } stranica, { $size }
    [few] { $count } stranice, { $size }
   *[other] { $count } stranica, { $size }
}
preview-page-alt = { $name }, stranica { $page } od { $count }
preview-more-pages = { $count ->
    [1] Otvorite datoteku da biste videli stranicu
   *[other] Otvorite datoteku da biste videli sve stranice. Ukupno: { $count }
}
preview-more-files = { $count ->
    [one] Još { $count } datoteka se nalazi na listi iznad
    [few] Još { $count } datoteke se nalaze na listi iznad
   *[other] Još { $count } datoteka se nalazi na listi iznad
}
preview-tile-downloading = Preuzimanje…
preview-tile-preparing = Priprema se…
preview-tile-format = Slike u formatu { $format } još nisu podržane u pregledu
preview-tile-password = Datoteka je zaštićena lozinkom. Otvorite je da biste uneli lozinku
preview-tile-too-large = Prevelika za prikaz
preview-tile-unreadable = Ne može da se prikaže
preview-tile-timed-out = Priprema pregleda trajala je predugo
preview-tile-crashed = Pregled nije dostupan: Inbox Classic se zatvorio pri ranijem prikazivanju ove datoteke
preview-tile-off = Nije prikazano dok se Inbox Classic ponovo ne pokrene
preview-not-printed = { $name } ({ $details }) se ne štampa. Otvorite datoteku da biste je odštampali.
