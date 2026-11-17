# Srpski (latinica). Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in English, the forms your
# language has in yours.

## Counts and sizes

# review: new
messages = { $count ->
    [one] { $count } poruka
    [few] { $count } poruke
   *[other] { $count } poruka
}
# the separator of decimals in sizes: 2.4 MB
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
# the status bar: "12 messages, 3 unread"
# review: new
list-counts = { $messages }, nepročitano: { $unread }
# review: new
list-counts-selected = { $messages }, nepročitano: { $unread }, izabrano: { $selected }
# the status bar while searching: "12 found, 3 unread"
# review: new
list-counts-found = Pronađeno: { $found }, nepročitano: { $unread }
# review: new
list-counts-found-selected = Pronađeno: { $found }, nepročitano: { $unread }, izabrano: { $selected }
# review: new
list-counts-none = Nije pronađena nijedna poruka

## Special folders, as Outlook Express names them

# review: new
folder-inbox = Prijemno sanduče
# review: new
folder-sent = Poslate stavke
# review: new
folder-deleted = Izbrisane stavke
# review: new
folder-drafts = Radne verzije
# review: new
folder-junk = Neželjena e-pošta
# review: new
folder-archive = Arhiva

## The reading pane

# review: new
reader-no-message = Nije izabrana nijedna poruka.
# review: new
reader-downloading = Preuzimanje poruke…
# review: new
reader-downloading-detail = Poruka će se pojaviti ovde kada se preuzimanje završi.
# review: new
reader-downloading-size = Poruka ima { $size }. Pojaviće se ovde kada se preuzme.
# review: new
reader-failed = Poruku nije moguće preuzeti
# review: new
reader-failed-network = Server e-pošte nije dostupan ({ $reason }).
# review: new
reader-failed-sign-in = Server e-pošte nije prihvatio prijavu ({ $reason }). Proverite lozinku ili se ponovo prijavite u meniju Datoteka > Nalozi.
# review: new
reader-failed-security = Vezu sa serverom e-pošte nije moguće zaštititi ({ $reason }).
# review: new
reader-failed-other = Server e-pošte je odgovorio: { $reason }.
# review: new
reader-retry-note = Biće ponovo pokušano kada se nalog ponovo poveže.
# review: new
reader-unreadable = Ova poruka ne može da se prikaže: { $error }
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
header-cc = Cc
# review: new
header-sent = Poslato
# review: new
header-subject = Tema
# review: new
header-security = Bezbednost
# review: new
header-part = Deo { $number }
# review: new
quote-original = ----- Originalna poruka -----
# review: new
fold-show-earlier = Prikaži ranije poruke

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Vaša poruka nije isporučena
# review: new
bounce-delayed = Vaša poruka još nije isporučena
# review: new
bounce-delayed-note = Vaš server e-pošte još uvek pokušava da je isporuči. Ne morate ponovo da je šaljete.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Prikaži vraćenu poruku
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Prikaži odloženu poruku
# review: new
bounce-what-to-do = Šta možete da uradite:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Zasad ništa. Ako i dalje ne bude mogla da se isporuči, dobićete novo obaveštenje.
# review: new
bounce-delayed-row-do = Zasad ništa. Vaš server e-pošte još uvek pokušava da je isporuči, a ako ne uspe, dobićete novo obaveštenje.
# folds the receiving server's own words
# review: new
bounce-details = Detalji
# a recipient the notice does not name
# review: new
bounce-someone = Primalac
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Status: { $status }
# review: new
bounce-reported-by = Prijavio: { $server }
# review: new
bounce-retry-minutes = Server primaoca je zatražio da se pre sledećeg pokušaja sačeka { $count ->
    [1] minut
    [one] { $count } minut
    [few] { $count } minuta
   *[other] { $count } minuta
}.
# review: new
bounce-retry-hours = Server primaoca je zatražio da se pre sledećeg pokušaja sačeka { $count ->
    [1] sat
    [one] { $count } sat
    [few] { $count } sata
   *[other] { $count } sati
}.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Lista blokiranih: { $lists }
# review: new
bounce-user-unknown = Adresa ne postoji
# review: new
bounce-user-unknown-why = Server primaoca nema poštansko sanduče sa ovom adresom. Možda je pogrešno uneta ili je osoba više ne koristi.
# review: new
bounce-user-unknown-do = Proverite da li je adresa tačno napisana ili pitajte osobu koju adresu sada koristi.
# review: new
bounce-invalid-address = Adresa nije važeća
# review: new
bounce-invalid-address-why = Adresa nije napisana u obliku na koji se može slati pošta.
# review: new
bounce-invalid-address-do = Potražite greške u kucanju, na primer razmak, slovo koje nedostaje ili ništa iza znaka @.
# review: new
bounce-mailbox-disabled = Poštansko sanduče je zatvoreno
# review: new
bounce-mailbox-disabled-why = Adresa postoji, ali je njeno poštansko sanduče isključeno ili se više ne koristi.
# review: new
bounce-mailbox-disabled-do = Javite se osobi na drugi način i pitajte je koju adresu sada koristi.
# review: new
bounce-mailbox-full = Poštansko sanduče je puno
# review: new
bounce-mailbox-full-why = U poštanskom sandučetu primaoca nema mesta za novu poštu.
# review: new
bounce-mailbox-full-do = Pošaljite je ponovo za nekoliko dana ili obavestite osobu na drugi način. Veliki prilozi se prvi odbijaju.
# review: new
bounce-spam-blocked = Odbijeno kao neželjena pošta
# review: new
bounce-spam-blocked-why = Server primaoca je poruku smatrao neželjenom poštom.
# review: new
bounce-spam-blocked-do = Pošaljite je ponovo bez onoga što liči na neželjenu poštu, na primer mnogo veza, skraćenih veza ili velikog priloga. Ako se to ponavlja, obratite se svom dobavljaču usluge e-pošte.
# review: new
bounce-virus-detected = Odbijeno zbog virusa
# review: new
bounce-virus-detected-why = Server primaoca je pronašao virus ili drugi štetni sadržaj u poruci ili njenim prilozima.
# review: new
bounce-virus-detected-do = Proverite priloge antivirusnim programom. Neki serveri odbijaju svaki program ili arhivu, pa takve datoteke podelite kao vezu.
# review: new
bounce-ip-blocklisted = Vaš server e-pošte se nalazi na listi blokiranih
# review: new
bounce-ip-blocklisted-why = Server primaoca odbija poštu sa servera koji je poslao vašu poruku jer je adresa tog servera na listi blokiranih.
# review: new
bounce-ip-blocklisted-do = Problem nije u poruci. Prosledite ovo obaveštenje svom dobavljaču usluge e-pošte i zamolite ga da se server ukloni sa liste.
# review: new
bounce-domain-blocklisted = Domen se nalazi na listi blokiranih
# review: new
bounce-domain-blocklisted-why = Server primaoca odbija poruku jer je domen vaše adrese ili domen iz veza u poruci na listi blokiranih.
# review: new
bounce-domain-blocklisted-do = Ako poruka sadrži veze, pokušajte da je pošaljete bez njih. U suprotnom prosledite ovo obaveštenje osobi koja upravlja e-poštom vašeg domena.
# review: new
bounce-policy-blocked = Odbijeno prema pravilima servera primaoca
# review: new
bounce-policy-blocked-why = Pravila servera primaoca ne propuštaju ovu poruku, na primer zbog njene veličine, priloga ili pošiljaoca.
# review: new
bounce-policy-blocked-do = Razlog se često vidi u rečima samog servera u odeljku Detalji. Pitajte primaoca da li može da prima takvu poštu.
# review: new
bounce-geo-blocked = Odbijeno zbog mesta odakle je stigla
# review: new
bounce-geo-blocked-why = Server primaoca ne prima poštu iz zemlje ili mreže u kojoj je vaš server e-pošte.
# review: new
bounce-geo-blocked-do = Javite se osobi na drugi način ili se obratite svom dobavljaču usluge e-pošte.
# review: new
bounce-relay-denied = Server nije hteo da je prosledi
# review: new
bounce-relay-denied-why = Server je odbio da isporuči poruku dalje, često zato što je poslata bez prijave ili preko servera koji ne opslužuje ovog primaoca.
# review: new
bounce-relay-denied-do = Proverite server za odlaznu poštu naloga u meniju Datoteka > Nalozi i da li se on prijavljuje.
# review: new
bounce-auth-failure = Adresu pošiljaoca nije moguće potvrditi
# review: new
bounce-auth-failure-why = Server primaoca nije mogao da potvrdi da je poruka zaista stigla sa vašeg domena (SPF, DKIM ili DMARC).
# review: new
bounce-auth-failure-do = Prosledite ovo obaveštenje osobi koja upravlja e-poštom vašeg domena: njegova podešavanja treba ispraviti. U međuvremenu može da pomogne slanje preko servera vašeg dobavljača usluge.
# review: new
bounce-rate-limited = Previše pošte odjednom
# review: new
bounce-rate-limited-why = Server primaoca zasad prima manje poruka sa vašeg servera e-pošte.
# review: new
bounce-rate-limited-do = Sačekajte neko vreme i pošaljite je ponovo. Kada pišete mnogim ljudima, šaljite poruku manjem broju njih odjednom.
# review: new
bounce-greylisting = Zadržano na trenutak
# review: new
bounce-greylisting-why = Server primaoca traži od nepoznatih pošiljalaca da pokušaju ponovo malo kasnije, što je uobičajena zaštita od neželjene pošte.
# review: new
bounce-greylisting-do = Ništa. Serveri e-pošte sami pokušavaju ponovo i poruka se obično isporuči u roku od sat vremena.
# review: new
bounce-server-error = Server primaoca je imao problem
# review: new
bounce-server-error-why = Server primaoca nije bio dostupan ili nije mogao da primi poruku zbog sopstvenog problema.
# review: new
bounce-server-error-do = Pošaljite je ponovo kasnije. Ako i dalje ne uspeva, proverite da li ima grešaka u delu adrese iza znaka @.
# review: new
bounce-unknown = Nije isporučeno
# review: new
bounce-unknown-why = Obaveštenje ne navodi jasno zašto.
# review: new
bounce-unknown-do = Reči samog servera u odeljku Detalji možda govore više. Ako ne pomognu, prosledite ovo obaveštenje svom dobavljaču usluge e-pošte.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } izabrana poruka
    [few] { $count } izabrane poruke
   *[other] { $count } izabranih poruka
}
# review: new
selection-unread = Nepročitano: { $count }
# review: new
selection-flagged = Označeno zastavicom: { $count }
# review: new
delete-for-good-one = Ova poruka će biti trajno izbrisana. Da li želite da je izbrišete?
# review: new
delete-for-good-all = Ove poruke ({ $count }) biće trajno izbrisane. Da li želite da ih izbrišete?
# review: new
delete-for-good-some = Trajno će biti izbrisano { $count } od ukupno { $total } poruka. Da li želite da izbrišete poruke?
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
   *[other] Premešteno: { $messages } (odredište: { $folder })
}
# review: new
done-copied = { $count ->
   *[other] Kopirano: { $messages } (odredište: { $folder })
}
# review: new
done-moving = { $count ->
   *[other] Premeštanje: { $messages } (odredište: { $folder })...
}
# review: new
done-copying = { $count ->
   *[other] Kopiranje: { $messages } (odredište: { $folder })...
}
# review: new
done-moved-back = { $count ->
   *[other] Vraćeno: { $messages } (odredište: { $folder })
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
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
their-folders = njihove izvorne fascikle
# review: new
undo-move = Opozovi premeštanje
# review: new
undo-delete = Opozovi brisanje
# review: new
undo-archive = Opozovi arhiviranje
# review: new
undo-junk = Opozovi označavanje kao neželjeno
# review: new
undo-not-junk = Opozovi označavanje kao da nije neželjeno
# review: new
undo-send = Opozovi slanje
# review: new
nothing-to-undo = Nema ničega za opoziv.
# review: new
messages-gone = Poruke više nisu ovde.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Ova fascikla ne može da sadrži poruke.
# review: new
not-archived-here = Poruke u ovoj fascikli ne mogu da se arhiviraju.
# review: new
not-emptied-here = Mogu da se isprazne samo fascikle Izbrisane stavke i Neželjena e-pošta.
# review: new
next-unread-question = U fascikli { $folder } nema više nepročitanih poruka.

    Da li želite da pređete u fasciklu { $next }, sledeću fasciklu sa nepročitanim porukama?
# review: new
no-unread-left = Nema više nepročitanih poruka.
# review: new
empty-question = { $count ->
    [1] Da li želite da ispraznite fasciklu { $folder }?

        Poruka u njoj biće trajno izbrisana. Neće moći da se vrati.
   *[other] Da li želite da ispraznite fasciklu { $folder }?

        Sve poruke u njoj ({ $messages }) biće trajno izbrisane. Neće moći da se vrate.
}
# review: new
no-junk-folder = Ovaj nalog nema fasciklu Neželjena e-pošta u koju bi se poruke premestile.
# review: new
no-inbox-folder = Ovaj nalog nema fasciklu Prijemno sanduče u koju bi se poruke premestile.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
# review: new
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
# review: new
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

# review: new
move-window-title-move = { $count ->
    [1] Premesti poruku
    [one] Premesti { $count } poruku
    [few] Premesti { $count } poruke
   *[other] Premesti { $count } poruka
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
    [1] Premesti izabranu poruku u:
    [one] Premesti { $count } izabranu poruku u:
    [few] Premesti { $count } izabrane poruke u:
   *[other] Premesti { $count } izabranih poruka u:
}
# review: new
move-window-prompt-copy = { $count ->
    [1] Kopiraj izabranu poruku u:
    [one] Kopiraj { $count } izabranu poruku u:
    [few] Kopiraj { $count } izabrane poruke u:
   *[other] Kopiraj { $count } izabranih poruka u:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Nedavno korišćene
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (trenutna)
# a folder used last, with its account when there are several: "Archive (Work)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Premeštanje: { $done } od { $messages } (odredište: { $folder })...
# review: new
transfer-copying = Kopiranje: { $done } od { $messages } (odredište: { $folder })...
# review: new
transfer-another-account = drugi nalog
# review: new
transfer-folder-gone = odredišna fascikla više ne postoji
# review: new
transfer-not-on-server = poruka više nije na serveru
# review: new
transfer-not-moved = { $count ->
   *[other] Nije moguće premestiti na drugi nalog ({ $messages }): { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] Nije moguće kopirati na drugi nalog ({ $messages }): { $reason }
}
# review: new
transfer-none-moved = Nijedna poruka nije premeštena
# review: new
transfer-none-copied = Nijedna poruka nije kopirana

## Messages as files

# review: new
export-not-in-time = poruku nije bilo moguće preuzeti na vreme
# review: new
export-not-saved = Nije sačuvano: { $failed } od { $messages } ({ $problems })
# review: new
export-not-attached = poruke nije moguće priložiti: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
   *[other] Sačuvano u fasciklu { $folder }: { $messages }
}
# review: new
download-progress = Preuzimanje: { $done } od { $total }
# review: new
download-done = Preuzeto: { $size }
# review: new
downloading-messages = { $count ->
   *[other] Preuzimanje: { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
# review: new
import-put = { $count ->
   *[other] Stavljeno u fasciklu { $folder }: { $messages }
}
# review: new
import-not-put = Ove datoteke nisu stavljene u fasciklu:

    { $problems }

## Problems the windows show

# review: new
error-store = lokalno skladište: { $error }
# review: new
error-not-found = nije pronađeno
# review: new
error-closed = zatvaranje u toku
# review: new
error-other-account = pregledač se prijavio na nalog { $email }, a ne na ovaj nalog
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = server nije prihvatio prijavu ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = veza sa serverom nije uspela ({ $reason })
# review: new
error-in-use = ne može da se ukloni dok se pomoću nje prijavljuju nalozi: { $accounts }
# review: new
error-turned-off = ova aplikacija za prijavljivanje je isključena za nove naloge
# review: new
error-folder-name = naziv fascikle mora da ima od 1 do 200 znakova i ne sme da sadrži kontrolne znakove
# review: new
error-folder-separator = na ovom serveru naziv fascikle ne sme da sadrži „{ $separator }“
# review: new
error-folder-special = Prijemno sanduče i posebne fascikle ne mogu da se preimenuju ni izbrišu
# review: new
error-no-recipients = poruka nema primalaca
# review: new
error-bad-address = „{ $address }“ nije adresa e-pošte
# review: new
error-not-own-address = { $address } nije jedna od adresa pošiljaoca ovog naloga. Dodajte je u polje „Druge adrese sa kojih šaljete“ u svojstvima naloga.
# review: new
rule-query-refused = Pravila ne mogu da filtriraju po fascikli ni datumu ({ $words }).
# review: new
rule-no-query = Unesite kriterijume pretrage za dolazne poruke.
# review: new
rule-no-action = Izaberite bar jednu radnju za pravilo.
# review: new
error-attachment = Datoteku { $path } nije moguće pročitati: { $error }
# review: new
error-no-drafts = nalog nema fasciklu Radne verzije u koju bi se poruka sačuvala
# review: new
error-draft-attachment = prilog radne verzije nije moguće zadržati: { $error }
# review: new
error-password-not-saved = lozinku nije moguće sačuvati za sledeće pokretanje: { $error }
# review: new
error-sign-in-not-saved = nove podatke za prijavu nije moguće sačuvati za sledeće pokretanje: { $error }
# review: new
error-import-unreadable = Datoteka { $path } ne može da se pročita: { $error }
# review: new
error-import-too-large = Datoteka { $path } je veća od 50 MB
# review: new
error-import-not-mail = Datoteka { $path } nije poruka e-pošte
# review: new
error-list-answered = server liste za slanje je vratio status { $status }
# review: new
error-not-built = poruku nije moguće sastaviti
# review: new
error-outbox-waits = { $count ->
    [1] poruka čeka u Izlaznom sandučetu i biće poslata pri sledećem slanju i primanju
    [one] { $count } poruka čeka u Izlaznom sandučetu i biće poslata pri sledećem slanju i primanju
    [few] { $count } poruke čekaju u Izlaznom sandučetu i biće poslate pri sledećem slanju i primanju
   *[other] { $count } poruka čeka u Izlaznom sandučetu i biće poslate pri sledećem slanju i primanju
}
# review: new
error-draft-not-removed = raniju radnu verziju poruke nije moguće ukloniti iz fascikle Radne verzije: { $reason }
# review: new
error-sent-but = poruka je poslata, ali { $problem }
# review: new
error-sent-still-in-outbox = još uvek je u Izlaznom sandučetu: { $error }
# review: new
error-sent-no-copy = kopiju nije moguće sačuvati u fascikli Poslate stavke: { $reason }
# review: new
error-no-password = nema lozinke za ovaj nalog
# review: new
error-no-sign-in = nema podataka za prijavu za ovaj nalog
# review: new
error-provider-missing = ova verzija ne može da se prijavi kod dobavljača { $provider }: da li je njegova aplikacija za prijavljivanje uklonjena?
# review: new
error-provider-servers = serveri ovog naloga ne odgovaraju serverima njegove aplikacije za prijavljivanje
# review: new
error-app-scopes = { $reason }. Server e-pošte nije prihvatio token aplikacije za prijavljivanje: proverite da li opsezi (scopes) aplikacije daju pristup pošti
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google još nije potvrdio Inbox Classic, pa dozvoljava prijavu samo probnim korisnicima. Koristite sopstvenu Google aplikaciju za prijavljivanje ili lozinku za aplikaciju, ili je uključite u prozoru Aplikacije za prijavljivanje (Datoteka > Nalozi) ako ste probni korisnik.
# review: new
sign-in-off-other = Isključena je u prozoru Aplikacije za prijavljivanje (Datoteka > Nalozi), gde može ponovo da se uključi.
# review: new
sign-in-app-no-name = aplikacija za prijavljivanje mora da ima naziv
# review: new
sign-in-app-no-client = nedostaje ID klijenta
# review: new
sign-in-app-no-scopes = aplikaciji za prijavljivanje potrebni su opsezi (scopes) koji daju pristup pošti
# review: new
sign-in-app-bad-host = adresa servera { $server } nedostaje ili nije važeće ime hosta
# review: new
sign-in-app-plain = server { $server } mora da koristi SSL/TLS ili STARTTLS
# review: new
sign-in-app-not-checked = izdavalac još nije proveren
# review: new
sign-in-app-issuer-changed = izdavalac se promenio: ponovo unesite tajnu klijenta ili je uklonite
# review: new
sign-in-register-google = U konzoli Google Cloud Console napravite OAuth klijent tipa Desktop app sa opsegom https://mail.google.com/ na ekranu za pristanak. Dok je aplikacija u fazi testiranja, mogu da se prijave samo njeni probni korisnici.
# review: new
sign-in-register-microsoft = U servisu Microsoft Entra registrujte aplikaciju sa platformom Mobile and desktop applications, URI-jem za preusmeravanje http://localhost, dozvoljenim tokovima javnog klijenta i delegiranim dozvolama IMAP.AccessAsUser.All, SMTP.Send i offline_access. Samo za svoju organizaciju kao izdavaoca koristite https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Registrujte izvorni (javni) klijent sa URI-jem za preusmeravanje navedenim ispod; dobavljač mora na njemu da dozvoli bilo koji port (RFC 8252). Dodajte opseg kojim dobavljač daje pristup pošti.

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
        [1] Svake nedelje
        [one] Svakih { $interval } nedelja
        [few] Svake { $interval } nedelje
       *[other] Svakih { $interval } nedelja
}
    [month] { $interval ->
        [1] Svakog meseca
        [one] Svakih { $interval } mesec
        [few] Svaka { $interval } meseca
       *[other] Svakih { $interval } meseci
}
   *[year] { $interval ->
        [1] Svake godine
        [one] Svakih { $interval } godinu
        [few] Svake { $interval } godine
       *[other] Svakih { $interval } godina
}
}
# "Every week on Monday, Wednesday"
# review: new
repeats-on = { $repeats }: { $days }
# "Every week, 10 times"
# review: new
repeats-times = { $count ->
    [1] { $repeats }, jednom
    [one] { $repeats }, { $count } put
    [few] { $repeats }, { $count } puta
   *[other] { $repeats }, { $count } puta
}
# review: new
day-monday = ponedeljak
# review: new
day-tuesday = utorak
# review: new
day-wednesday = sreda
# review: new
day-thursday = četvrtak
# review: new
day-friday = petak
# review: new
day-saturday = subota
# review: new
day-sunday = nedelja

## AI agents

# review: new
agent-level-read = Čitanje pošte: fascikle, lista poruka, pretraga i poruke
# review: changed
agent-level-organize = Organizovanje pošte: stanje pročitanosti, zastavice, neželjena pošta, premeštanje, arhiviranje, nove fascikle, brisanje u fasciklu Izbrisane stavke i napuštanje lista za slanje kada vi to odobrite
# review: new
agent-level-drafts = Pisanje radnih verzija koje ćete vi poslati
# review: new
agent-level-send = Slanje pošte, svake poruke tek nakon vašeg odobrenja
# review: new
agent-connect-title = { $program } želi da koristi vašu poštu
# review: new
agent-connect-detail = AI agent je zatražio da radi sa programom Inbox Classic. Izaberite šta sme da radi i koje naloge sme da vidi; to možete kasnije da promenite u meniju Alatke > AI agenti.

    Agenti čitaju poštu koju su napisali drugi ljudi, a poruka može da pokuša da ih prevari. Inbox Classic vas uvek pita pre nego što agent bilo šta pošalje.
# review: new
agent-reply-to = Odgovor na „{ $subject }“
# review: new
agent-reply-all-on = Odgovor svima na „{ $subject }“
# review: new
agent-forward-of = Prosleđivanje poruke „{ $subject }“
# review: new
agent-never-written-one = Nikad niste pisali adresi { $address }.
# review: new
agent-never-written-many = Na neke od ovih adresa ({ $count }) nikad niste pisali.
# review: new
agent-send-title = { $program } želi da pošalje ovu poruku
# review: new
agent-send-detail = Proverite primaoce i sadržaj poruke. Kada potvrdite, poruka čeka u Izlaznom sandučetu još { $seconds } s, a za to vreme još uvek možete da je izbrišete.
# review: new
agent-change-title = Šta { $program } sme da radi
# review: new
agent-change-allowed = Promenite šta AI agenti ovog programa smeju da rade sa vašom poštom.
# review: new
agent-change-refused = Odbili ste pristup ovom programu. Dozvolite ga da bi njegovi agenti ponovo dobili pristup vašoj pošti.
# review: new
agent-log-taken-back = { $entry } (opozvano)
# review: new
agent-files = Datoteke: { $files }
# review: new
agent-undo-refused = Ne može da se opozove.
# review: new
agent-undo-refused-why = Ne može da se opozove: { $reason }.
# review: new
agent-undo-impossible = ovo ne može da se opozove
# review: new
agent-undo-not-in-folder = poruka više nije u toj fascikli
# review: new
agent-undo-not-arrived = poruka (još) nije u fascikli u koju je premeštena
# review: new
agent-undo-sent = poruka je već poslata
# review: new
agent-original-not-downloaded = originalna poruka još nije preuzeta. Najpre je otvorite
# review: new
agent-turned-away = Odbijeno
# review: new
agent-can-nothing = Ništa
# review: new
agent-can-read = čitanje
# review: new
agent-can-organize = organizovanje
# review: new
agent-can-drafts = pisanje radnih verzija
# review: new
agent-can-send = slanje uz vaše odobrenje
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first } i { $last }
# review: new
agent-accounts = { $count ->
    [0] nijedan nalog
    [one] { $count } nalog
    [few] { $count } naloga
   *[other] { $count } naloga
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Ova poruka ne može da se pročita.
# review: new
agent-encrypted-original = Ova poruka je šifrovana: agent ne može na nju da odgovori niti da je prosledi jer ne može da šifruje.
# review: new
agent-encrypted = Ova poruka je šifrovana. Može da je pročita samo korisnik, u aplikaciji Inbox Classic.
# review: new
list-encrypted = Šifrovana poruka
# review: new
agent-log-composed = Poruka „{ $subject }“ je otvorena kao nova poruka koju ćete dovršiti
# review: new
agent-log-refused = Niste poslali poruku „{ $subject }“
# review: new
agent-log-sent = Poruka „{ $subject }“ je poslata na { $to }
# review: new
agent-log-draft = Sačuvana radna verzija „{ $subject }“
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
agent-log-moved = Premešteno: „{ $subject }“ (odredište: { $folder })
# review: new
agent-log-junk = Označeno kao neželjeno: „{ $subject }“
# review: new
agent-log-not-junk = Označeno kao da nije neželjeno: „{ $subject }“
# review: new
agent-log-archived = Arhivirano: „{ $subject }“
# review: new
agent-log-folder = Napravljena fascikla „{ $name }“
# review: new
agent-log-unsubscribed = Otkazana pretplata na listu poruke „{ $subject }“
# review: new
agent-log-unsubscribe-failed = Otkazivanje pretplate na listu poruke „{ $subject }“ nije uspelo: { $reason }
# review: new
agent-log-unsubscribe-refused = Niste otkazali pretplatu: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [1] { $program } želi da otkaže vašu pretplatu na listu za slanje
    [one] { $program } želi da otkaže vašu pretplatu na { $count } listu za slanje
    [few] { $program } želi da otkaže vašu pretplatu na { $count } liste za slanje
   *[other] { $program } želi da otkaže vašu pretplatu na { $count } lista za slanje
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic traži od liste ispod da vam više ne šalje poruke, otkazivanjem pretplate jednim klikom koje nudi. Ništa drugo se ne šalje, a poruke koje imate ostaju tamo gde jesu.
   *[other] Inbox Classic traži od svake liste ispod da vam više ne šalje poruke, otkazivanjem pretplate jednim klikom koje lista nudi. Ništa drugo se ne šalje, a poruke koje imate ostaju tamo gde jesu.
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
sign-in-no-refresh = dobavljač nije dao token za osvežavanje
# review: new
sign-in-no-account = dobavljač nije naveo koji se nalog prijavio
# review: new
sign-in-not-finished = prijavljivanje nije dovršeno
# review: new
secrets-unavailable = { $store } nije dostupan
# review: new
secrets-unavailable-why = { $store } nije dostupan: { $error }
# review: new
secrets-windows = Upravljač akreditivima
# review: new
secrets-mac = privezak ključeva
# review: new
secrets-linux = sistemski privezak ključeva (Secret Service)
# review: new
error-no-such-file = ta datoteka ne postoji
# review: new
cards-file-too-big = Ova datoteka je prevelika da bi bila adresar.
# review: new
ui-sender-added = { $name } je dodat u Adresar.
# review: new
ui-sender-known = { $name } je već u Adresaru.
# review: new
ui-sender-none = Pošiljalac ove poruke nema adresu e-pošte koja bi mogla da se doda.
# review: new
card-name-needed = Kontakt nema ni ime ni adresu e-pošte.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Kôd sa domena { $domain }
# review: new
otp-copy = Kopiraj
# review: new
otp-note = Unesite ga samo na stranici domena { $domain }.
# review: new
otp-old = Ovaj kôd je poslat više od sat vremena pre nego što ste ga otvorili i verovatno je istekao.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } učesnik
        [few] { $count } učesnika
       *[other] { $count } učesnika
}

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } je vaš kôd za { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Važeći
# review: new
pgp-key-expires = Važeći do { $date }
# review: new
pgp-key-expired = Istekao { $date }
# review: new
pgp-key-revoked = Opozvan
# review: new
pgp-key-revoked-why = Opozvan: { $reason }
# review: new
pgp-key-not-valid = Nije važeći
# review: new
pgp-key-locked = Ne može da se koristi: ključ koji ga štiti više nije sačuvan ({ $store }). Ponovo uvezite njegovu rezervnu kopiju.
# review: new
pgp-source-own = Napravljen u programu Inbox Classic
# review: new
pgp-source-file = Uvezen iz datoteke
# review: new
pgp-source-paste = Nalepljen
# review: new
pgp-source-attachment = Iz poruke
# review: new
pgp-source-vcard = Iz kartice kontakta
# review: new
pgp-source-wkd = Od dobavljača usluge e-pošte pošiljaoca
# review: new
pgp-source-keyserver = Sa servera keys.openpgp.org
# review: new
pgp-source-autocrypt = Iz Autocrypt zaglavlja poruke
# review: new
pgp-error-no-store = Privatne ključeve štiti { $store }, koji ne može da se koristi: { $error }
# review: new
pgp-error-wrong-passphrase = Pristupna fraza nije tačna.
# review: new
pgp-error-not-a-key = Ovo nije OpenPGP ključ.
# review: new
pgp-error-too-large = Ključ je prevelik.
# review: new
pgp-error-unusable = Ključ koristi staru ili slabu kriptografiju i ne može da se koristi.
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
pgp-imported-pending = Za { $addresses } već se koristi drugi ključ: novi čeka u kontaktu dok ga ne izaberete.
# review: new
pgp-error-needs-passphrase = Privatni ključ je zaštićen pristupnom frazom. Unesite je da biste uvezli ključ.
# review: new
pgp-error-mismatch = Privatni ključ ne pripada svom javnom ključu. Možda je izmenjen.
# review: new
pgp-file-name-public = { $who } javni ključ.asc
# review: new
pgp-file-name-private = { $who } rezervna kopija privatnog ključa.asc
# review: new
pgp-pending = Drugi ključ za { $address } je pronađen { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Potpisao { $signer }, ključ proveren
# review: new
pgp-part-signed = Potpisao { $signer } (ključ nije proveren)
# review: new
pgp-part-other = Potpisao { $signer }, koji nije pošiljalac
# review: new
pgp-part-unknown-key = Potpisano, ali ključ nije poznat
# review: new
pgp-part-not-signed = Nije potpisano
# review: new
pgp-part-not-checked = Potpis nije proveren
# review: new
pgp-part-encrypted = Šifrovano. { $signature }
# review: new
pgp-part-no-key = Šifrovano za ključ koji nemate
# review: new
pgp-part-changed = Šifrovani deo je promenjen usput i ne prikazuje se
# review: new
pgp-part-unprotected = Šifrovano bez zaštite od izmena, ne prikazuje se
# review: new
pgp-part-broken = Šifrovani deo ne može da se pročita
# review: new
pgp-why-mismatch = Potpis ne odgovara ovom tekstu
# review: new
pgp-why-weak-hash = Potpis koristi { $hash }, koji više nije bezbedan
# review: new
pgp-why-key-expired = Potpisano nakon što je ključ istekao { $date }
# review: new
pgp-why-key-revoked = Potpisano opozvanim ključem
# review: new
pgp-why-not-signing-key = Potpisano ključem koji ne sme da potpisuje
# review: new
pgp-why-from-future = Potpis ima datum u budućnosti
# review: new
pgp-why-signature-expired = Potpis je istekao
# review: new
pgp-why-key-not-valid = Potpisano ključem koji nije važeći
# review: new
pgp-why-not-for-you = Potpisano za druge primaoce i prosleđeno vama
# review: new
pgp-why-not-key-in-use = Potpisano drugim ključem od onog koji se koristi za { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Slike su učitane sa interneta
# review: new
pgp-error-no-own-key = Nemate ključ za { $address } kojim biste potpisivali ili šifrovali. Napravite ga u meniju Alatke > Ključevi za šifrovanje ili isključite Potpiši i Šifruj.
# review: new
pgp-error-missing-keys = { $count ->
    [1] { $addresses } nema ključ za šifrovanje.
   *[other] Ovi primaoci nemaju ključ za šifrovanje: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Ova poruka citira ili prosleđuje šifrovanu poruku, pa može da se pošalje samo šifrovana. Uključite Šifruj ili uklonite citirani tekst.
# review: new
pgp-error-protect = Poruku nije moguće potpisati ni šifrovati: { $reason }
# review: new
pgp-found-keys = Pronađen je ključ za: { $addresses }.
# review: new
pgp-found-none = Nije pronađen ključ za: { $addresses }. Zamolite ih da vam pošalju svoj javni ključ.
# review: new
pgp-found-no-key = Nije pronađen nijedan ključ.
# review: new
pgp-find-unavailable = Ključeve sada nije moguće potražiti: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org je poslao vezu za potvrdu na { $addresses }. Vaš ključ će tamo biti objavljen kada kliknete na nju.
# review: new
pgp-publish-done = Vaš ključ je objavljen na keys.openpgp.org za { $addresses }.
# review: new
pgp-publish-failed = Ključ nije moguće objaviti: { $error }
# review: changed
pgp-keyserver-off = Traženje ključeva na keys.openpgp.org isključeno je u { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [1] Šifrovano i potpisano: mogu da je pročitaju samo vi i { $addresses }.
   *[other] Šifrovano i potpisano: mogu da je pročitaju samo vi i njeni primaoci ({ $count }).
}
# review: new
pgp-compose-encrypt-ready = Biće šifrovana i potpisana. Dodajte primaoce čije ključeve imate.
# review: new
pgp-compose-missing = { $count ->
    [1] { $addresses } nema ključ, pa poruka još ne može da se šifruje.
   *[other] Primaoci bez ključa ({ $count }): { $addresses }. Zato poruka još ne može da se šifruje.
}
# review: new
pgp-compose-looking = Traže se ključevi za: { $addresses }...
# review: new
pgp-compose-signed = Potpisano: primaoci mogu da provere da je od vas i da nije menjana.
# review: new
pgp-compose-reply-clear = Nije šifrovano, iako je poruka na koju odgovara ili koju prosleđuje bila šifrovana.
# review: new
pgp-compose-encrypted-files = Priložene su datoteke šifrovane poruke, pa ova poruka može da se pošalje samo šifrovana. Uključite Šifruj ili uklonite te datoteke.
# review: new
pgp-compose-sign-tip = Potpišite poruku svojim ključem kako bi primaoci mogli da provere da je od vas i da nije menjana
# review: new
pgp-compose-sign-tip-encrypted = Šifrovana poruka je uvek potpisana
# review: new
pgp-compose-encrypt-tip = Šifrujte poruku kako bi samo vi i njeni primaoci mogli da je pročitaju
# review: new
pgp-compose-make-key = Još nemate ključ za { $address }. Da li želite da ga napravite sada? Sa njim vaše poruke mogu da se potpisuju i šifruju.
# review: new
pgp-compose-key-unusable = Vaš ključ za { $address } ne može da se koristi ({ $state }). Otvorite prozor Ključevi za šifrovanje da biste uvezli njegovu rezervnu kopiju ili napravili novi ključ.
# review: new
pgp-compose-encrypt-off-quote = Ova poruka citira ili prosleđuje šifrovanu poruku. Bez šifrovanja ne može da se pošalje dok ne uklonite citirani sadržaj. Da li ipak želite da isključite šifrovanje?
# review: new
pgp-compose-encrypt-off-reply = Ova poruka odgovara na šifrovanu poruku ili je prosleđuje. Bez šifrovanja vašu poruku može da pročita svako ko njome rukuje usput. Da li želite da isključite šifrovanje?
# review: new
pgp-recipient-verified = Ključ proveren
# review: new
pgp-recipient-found = Ključ nije proveren
# review: new
pgp-recipient-own = Vaš ključ
# review: new
pgp-recipient-looking = Traži se ključ...
# review: new
pgp-recipient-missing = Nema ključa
# review: new
pgp-recipient-not-found = Nema ključa: { $date } nije pronađen nijedan
# review: new
pgp-recipient-unusable = Ključ ne može da se koristi: { $state }
# review: new
pgp-recipients-intro = Poruka se šifruje ključem svakog primaoca i vašim.
# review: new
pgp-recipients-intro-missing = { $count ->
    [1] Jedan primalac nema ključ za šifrovanje. Pronađite njegov ključ, uklonite ga iz ove poruke ili je pošaljite bez šifrovanja.
    [one] { $count } primalac nema ključ za šifrovanje. Pronađite njihove ključeve, uklonite ih iz ove poruke ili je pošaljite bez šifrovanja.
    [few] { $count } primaoca nemaju ključ za šifrovanje. Pronađite njihove ključeve, uklonite ih iz ove poruke ili je pošaljite bez šifrovanja.
   *[other] { $count } primalaca nema ključ za šifrovanje. Pronađite njihove ključeve, uklonite ih iz ove poruke ili je pošaljite bez šifrovanja.
}
# review: new
pgp-details-part = Deo { $number }: { $label }
# review: new
pgp-details-signed = Potpisano { $when } ključem { $key }
# review: new
pgp-details-unknown-key = Potpisano ključem { $key }, koji nemate
# review: new
pgp-details-opened = Šifrovano za vaš ključ { $key }
# review: new
pgp-details-for = Šifrovano za { $keys }
# review: new
pgp-details-plain = Nije potpisano ni šifrovano
# review: new
pgp-bar-parts = Ova poruka ima više delova ({ $count }): { $list }. Za svaki deo je navedeno kako je zaštićen.
# review: new
pgp-bar-count-verified = Provereno: { $count }
# review: new
pgp-bar-count-good = { $count ->
    [one] { $count } potpisan ili šifrovan
    [few] { $count } potpisana ili šifrovana
   *[other] { $count } potpisanih ili šifrovanih
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
setup-part-settings = Podešavanja
# review: new
setup-part-preferences = Podešavanja prozora
# review: new
setup-part-accounts = Nalozi
# review: new
setup-part-sign-in-apps = Aplikacije za prijavljivanje
# review: new
setup-part-contacts = Kontakti i grupe
# review: new
setup-part-keys = Ključevi za šifrovanje
# review: new
setup-part-rules = Pravila za poruke
# review: new
setup-part-trusted-senders = Pouzdani pošiljaoci
# review: new
setup-holds-settings = { $count ->
    [one] { $count } podešavanje
    [few] { $count } podešavanja
   *[other] { $count } podešavanja
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } podešavanje prozora
    [few] { $count } podešavanja prozora
   *[other] { $count } podešavanja prozora
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } nalog
    [few] { $count } naloga
   *[other] { $count } naloga
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavljivanje
    [few] { $count } aplikacije za prijavljivanje
   *[other] { $count } aplikacija za prijavljivanje
}
# review: new
setup-holds-built-in = Koje su ugrađene aplikacije za prijavljivanje uključene
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
    [one] { $count } vaš ključ
    [few] { $count } vaša ključa
   *[other] { $count } vaših ključeva
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
    [one] { $count } pouzdani pošiljalac
    [few] { $count } pouzdana pošiljaoca
   *[other] { $count } pouzdanih pošiljalaca
}
# review: new
setup-sign-in-password = Lozinka
# review: new
setup-account-secret-password = Njegova lozinka je u datoteci.
# review: new
setup-account-secret-token = Njegovi podaci za prijavljivanje su u datoteci.
# review: new
setup-account-asks-password = Nakon uvoza tražiće svoju lozinku.
# review: new
setup-account-signs-in-again = Nakon uvoza ponovo ćete se prijaviti na njega.
# review: new
setup-account-here = Ovde je već podešen, pa se preskače.
# review: new
setup-account-no-app = Prijavljuje se pomoću aplikacije { $app }, koja ovde nije podešena. Uvezite i aplikacije za prijavljivanje.
# review: new
setup-invalid-address = „{ $address }“ nije adresa e-pošte.
# review: new
setup-invalid-server = Server { $server } nema upotrebljiv naziv ili port.
# review: new
setup-invalid-user = Nema korisničkog imena.
# review: new
setup-invalid-sign-in = Prijavljuje se na način koji Inbox Classic ne poznaje.
# review: new
setup-error-empty = Datoteka je prazna.
# review: new
setup-error-too-large = Datoteka je prevelika da bi bila datoteka podešavanja programa Inbox Classic.
# review: new
setup-error-not-setup = Ova datoteka nije datoteka podešavanja programa Inbox Classic.
# review: new
setup-error-damaged = Datoteka podešavanja je oštećena i ne može da se pročita.
# review: new
setup-error-newer = Ovu datoteku je sačuvala novija verzija programa Inbox Classic ({ $version }). Ažurirajte Inbox Classic, a zatim je ponovo uvezite.
# review: new
setup-error-needs-passphrase = Ova datoteka je zaštićena pristupnom frazom. Unesite pristupnu frazu sa kojom je sačuvana.
# review: new
setup-error-wrong-passphrase = To nije pristupna fraza sa kojom je ova datoteka sačuvana.
# review: new
setup-error-changed = Datoteka podešavanja je promenjena ili oštećena nakon čuvanja, pa ne može da se uveze.
# review: new
setup-error-read = Datoteku podešavanja nije moguće pročitati: { $error }
# review: new
setup-error-write = Podešavanja nije moguće sačuvati: { $error }
# review: new
setup-error-no-parts = Izaberite bar jedan deo.
# review: new
setup-left-out = { $count ->
    [one] { $count } stavka (deo: { $part }) ne može da se koristi i izostavljena je.
    [few] { $count } stavke (deo: { $part }) ne mogu da se koriste i izostavljene su.
   *[other] { $count } stavki (deo: { $part }) ne može da se koristi i izostavljeno je.
}
# review: new
setup-imported-settings = Podešavanja su zamenjena.
# review: new
setup-imported-preferences = Podešavanja prozora su zamenjena.
# review: new
setup-added-accounts = { $count ->
    [one] Dodat je { $count } nalog.
    [few] Dodata su { $count } naloga.
   *[other] Dodato je { $count } naloga.
}
# review: new
setup-skipped-here = { $address } je već podešen ovde, pa je preskočen.
# review: new
setup-skipped-no-app = { $address } je preskočen: prijavljuje se pomoću aplikacije { $app }, koja ovde nije podešena.
# review: new
setup-skipped-invalid = { $address } je preskočen: { $reason }
# review: new
setup-asks-password = { $address } će tražiti lozinku kada se poveže.
# review: new
setup-signs-in-again = { $address } će tražiti da se ponovo prijavite kada se poveže.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Dodata je { $count } aplikacija za prijavljivanje.
    [few] Dodate su { $count } aplikacije za prijavljivanje.
   *[other] Dodato je { $count } aplikacija za prijavljivanje.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } aplikacija za prijavljivanje je već podešena ovde.
    [few] { $count } aplikacije za prijavljivanje su već podešene ovde.
   *[other] { $count } aplikacija za prijavljivanje je već podešeno ovde.
}
# review: new
setup-added-contacts = { $count ->
    [one] U adresar je dodat { $count } kontakt.
    [few] U adresar su dodata { $count } kontakta.
   *[other] U adresar je dodato { $count } kontakata.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } kontakt je već u adresaru.
    [few] { $count } kontakta su već u adresaru.
   *[other] { $count } kontakata je već u adresaru.
}
# review: new
setup-added-groups = { $count ->
    [one] Dodata ili dopunjena je { $count } grupa.
    [few] Dodate ili dopunjene su { $count } grupe.
   *[other] Dodato ili dopunjeno je { $count } grupa.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Dodat je { $count } vaš ključ.
    [few] Dodata su { $count } vaša ključa.
   *[other] Dodato je { $count } vaših ključeva.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Dodat je { $count } ključ kontakta.
    [few] Dodata su { $count } ključa kontakata.
   *[other] Dodato je { $count } ključeva kontakata.
}
# review: new
setup-added-rules = { $count ->
    [one] Dodato je { $count } pravilo za poruke.
    [few] Dodata su { $count } pravila za poruke.
   *[other] Dodato je { $count } pravila za poruke.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } pravilo za poruke već postoji.
    [few] { $count } pravila za poruke već postoje.
   *[other] { $count } pravila za poruke već postoji.
}
# review: new
setup-skipped-rules-account = { $count ->
    [1] 1 pravilo za poruke odnosi se na nalog koji ovde ne postoji, pa je preskočeno.
    [one] { $count } pravilo za poruke odnosi se na naloge koji ovde ne postoje, pa je preskočeno.
    [few] { $count } pravila za poruke odnose se na naloge koji ovde ne postoje, pa su preskočena.
   *[other] { $count } pravila za poruke odnosi se na naloge koji ovde ne postoje, pa je preskočeno.
}
# review: new
setup-rules-waiting = { $count ->
    [1] 1 pravilo za poruke premešta poruke u fasciklu koja će se pojaviti kada se njen nalog sinhronizuje.
    [one] { $count } pravilo za poruke premešta poruke u fascikle koje će se pojaviti kada se njihovi nalozi sinhronizuju.
    [few] { $count } pravila za poruke premeštaju poruke u fascikle koje će se pojaviti kada se njihovi nalozi sinhronizuju.
   *[other] { $count } pravila za poruke premešta poruke u fascikle koje će se pojaviti kada se njihovi nalozi sinhronizuju.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Dodat je { $count } pouzdani pošiljalac.
    [few] Dodata su { $count } pouzdana pošiljaoca.
   *[other] Dodato je { $count } pouzdanih pošiljalaca.
}
# review: new
setup-nothing = Ništa nije uvezeno.
# review: new
setup-account-servers = { $imap } i { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic podešavanja i nalozi
# review: new
setup-skipped-unreachable = { $name } je preskočena: njena usluga prijavljivanja nije dostupna. Ponovo je dodajte u prozoru Aplikacije za prijavljivanje.
# review: new
attachment-runs-programs = „{ $name }“ može da pokreće programe, pa ga Inbox Classic ne otvara. Sačuvajte datoteku, a zatim je sami otvorite ako verujete njenom izvoru.
# review: new
attachment-decrypted-note = Ovaj prilog potiče iz šifrovane poruke. Da bi ga otvorio, Inbox Classic ga čuva dešifrovanog na ovom računaru, u vašoj fascikli koju Inbox Classic prazni nakon jednog dana.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Server nije izvršio premeštanje ({ $messages }, odredište: { $folder }), pa je poruka ponovo u fascikli { $from }: { $reason }
    [few] Server nije izvršio premeštanje ({ $messages }, odredište: { $folder }), pa su poruke ponovo u fascikli { $from }: { $reason }
   *[other] Server nije izvršio premeštanje ({ $messages }, odredište: { $folder }), pa su poruke ponovo u fascikli { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Server nije izvršio brisanje ({ $messages }), pa je poruka ponovo u fascikli { $from }: { $reason }
    [few] Server nije izvršio brisanje ({ $messages }), pa su poruke ponovo u fascikli { $from }: { $reason }
   *[other] Server nije izvršio brisanje ({ $messages }), pa su poruke ponovo u fascikli { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Server nije izvršio arhiviranje ({ $messages }), pa je poruka ponovo u fascikli { $from }: { $reason }
    [few] Server nije izvršio arhiviranje ({ $messages }), pa su poruke ponovo u fascikli { $from }: { $reason }
   *[other] Server nije izvršio arhiviranje ({ $messages }), pa su poruke ponovo u fascikli { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Server nije izvršio označavanje kao pročitano ({ $messages }), pa je poruka ponovo nepročitana: { $reason }
    [few] Server nije izvršio označavanje kao pročitano ({ $messages }), pa su poruke ponovo nepročitane: { $reason }
   *[other] Server nije izvršio označavanje kao pročitano ({ $messages }), pa su poruke ponovo nepročitane: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Server nije izvršio označavanje kao nepročitano ({ $messages }), pa je poruka ponovo pročitana: { $reason }
    [few] Server nije izvršio označavanje kao nepročitano ({ $messages }), pa su poruke ponovo pročitane: { $reason }
   *[other] Server nije izvršio označavanje kao nepročitano ({ $messages }), pa su poruke ponovo pročitane: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Server nije promenio zastavice ({ $messages }), pa je poruka ponovo kao pre: { $reason }
    [few] Server nije promenio zastavice ({ $messages }), pa su poruke ponovo kao pre: { $reason }
   *[other] Server nije promenio zastavice ({ $messages }), pa su poruke ponovo kao pre: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Prikaži PDF datoteke u porukama
# review: new
preview-pdf-off = PDF datoteke se ne prikazuju u porukama.
# review: new
preview-pdf-off-crashed = PDF datoteka je zatvorila Inbox Classic dok se prikazivala, pa se PDF datoteke više ne prikazuju u porukama. Slike se i dalje prikazuju. Da biste ponovo prikazivali PDF datoteke, uključite { $option } u opcijama čitanja.
