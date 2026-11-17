# Srpski (latinica). Nacrt, čeka pregled izvornog govornika (vidi core/locales/GLOSSARY.md).

# The words of the windows, the same on every platform. An & marks the letter of a menu item that Alt and the letter
# choose on Windows and Linux (&& is an ampersand); the Mac leaves it out. Put it on a letter of your word, a different
# one for each item of a menu where you can.

## The menus

menu-file = &Datoteka
menu-edit = &Uređivanje
menu-view = &Prikaz
menu-tools = &Alatke
menu-message = Po&ruka
menu-help = Po&moć
menu-layout = &Raspored
menu-sort-by = &Sortiraj po
menu-text-size = &Veličina teksta
menu-folder = &Fascikla

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = &Novi nalog...
cmd-exit = Iz&laz
cmd-sync = Pošalji i primi poštu sa &svih naloga
cmd-mark-read = O&znači kao pročitano
cmd-mark-unread = Označi kao &nepročitano
cmd-pictures = Preuzmi s&like
cmd-about = &O programu Inbox Classic
cmd-new-mail = &Nova poruka
cmd-reply = Od&govori pošiljaocu
cmd-reply-all = Odgovori &svima
cmd-forward = &Prosledi
cmd-help = &Sadržaj
cmd-delete = Iz&briši poruku
cmd-move = Pre&mesti u fasciklu...
cmd-flag = Označi &zastavicom
cmd-new-folder = Nova &fascikla...
cmd-rename-folder = Pr&eimenuj fasciklu...
cmd-delete-folder = Iz&briši fasciklu
cmd-empty-folder = Ispra&zni fasciklu
ui-empty-button = Isprazni
cmd-accounts = Naloz&i...
cmd-find = &Pronađi poruku
cmd-save-as = &Sačuvaj kao...
cmd-print = Od&štampaj...
cmd-import = &Uvezi poruke...
cmd-outbox = &Izlazno sanduče...
cmd-properties = Svo&jstva
cmd-mark-all-read = Označi &sve kao pročitano
cmd-junk = Ozna&či kao neželjenu poštu
cmd-not-junk = Označi kao po&željnu poštu
cmd-archive = &Arhiviraj
cmd-watch-conversation = Pra&ti razgovor
cmd-ignore-conversation = Zan&emari razgovor
cmd-next-message = Sledeća por&uka
cmd-previous-message = &Prethodna poruka
cmd-next-unread = Sledeća &nepročitana poruka
cmd-go-to-folder = &Idi u fasciklu...
cmd-find-in-message = Pronađi u o&voj poruci...
ui-go-to-prompt = Idi u fasciklu:
ui-find-in-message-hint = Pronađi u ovoj poruci
ui-find-not-found = „{ $words }“ nije u ovoj poruci
cmd-expand-all-threads = Proširi sve r&azgovore
cmd-collapse-all-threads = Sažmi sve ra&zgovore
ui-group-by-conversation = &Grupiši poruke po razgovoru
cmd-folder-list = Lista &fascikli
cmd-layout-automatic = &Automatski
cmd-layout-classic = &Klasični
cmd-layout-columns = K&olone
cmd-sort-date = &Datum
cmd-sort-from = &Pošiljalac
cmd-sort-subject = &Tema
cmd-sort-size = &Veličina
cmd-sort-ascending = Rast&uće
cmd-sort-descending = &Opadajuće
cmd-text-size-largest = &Najveća
cmd-text-size-larger = &Veća
cmd-text-size-medium = &Srednja
cmd-text-size-smaller = &Manja
cmd-text-size-smallest = Najm&anja
cmd-hide-ignored = Sakrij zan&emarene razgovore
cmd-hide-read = Sakrij pr&očitane poruke
cmd-notify = O&baveštenja o novoj pošti
cmd-open = &Otvori Inbox Classic
cmd-default-app = Postavi kao podra&zumevanu aplikaciju za poštu...
cmd-view-source = Izvorni &kod poruke
cmd-ai-agents = &AI agenti...
cmd-options = &Opcije...
cmd-message-rules = &Pravila za poruke...
cmd-encryption-keys = &Ključevi za šifrovanje...
cmd-create-rule-from-message = Napravi pravi&lo iz poruke...
cmd-select-all = &Izaberi sve
cmd-undo = &Opozovi
cmd-copy = Kopiraj &u fasciklu...
cmd-address-book = A&dresar...
cmd-add-sender-to-book = Dodaj pošiljaoca u adresa&r
cmd-import-address-book = Uvezi &adresar...
cmd-export-address-book = Iz&vezi adresar...
cmd-export-setup = Izvezi podešavanja i nalo&ge...
cmd-import-setup = Uvezi po&dešavanja i naloge...

## The tray icon's menu

tray-check = &Proveri da li ima nove pošte
tray-no-accounts = Još nema naloga

## Words the windows of more than one platform share

ui-tb-create-mail = Nova poruka
ui-tb-reply = Odgovori
ui-tb-reply-all = Odgovori svima
ui-tb-forward = Prosledi
ui-tb-print = Odštampaj
ui-tb-delete = Izbriši
ui-tb-junk = Neželjena pošta
ui-tb-not-junk = Poželjna pošta
ui-tb-archive = Arhiviraj
ui-tb-previous = Prethodna
ui-tb-next = Sledeća
ui-previous-tip = Prethodna poruka
ui-next-tip = Sledeća poruka
ui-tb-sync = Pošalji/primi
ui-tb-mark-read = Pročitano
ui-tb-mark-unread = Nepročitano
ui-still-running = Inbox Classic i dalje radi
ui-no-subject = (bez teme)
ui-quoted = „{ $subject }“
ui-newest-from = Najnovija poruka, pošiljalac { $sender }: { $subject }
ui-new-messages = { $count ->
    [one] { $count } nova poruka
    [few] { $count } nove poruke
   *[other] { $count } novih poruka
}
ui-outbox-waiting = { $count ->
        [one] { $count } poruka u Izlaznom sandučetu
        [few] { $count } poruke u Izlaznom sandučetu
       *[other] { $count } poruka u Izlaznom sandučetu
}
ui-outbox-waits = { $subject } čeka u Izlaznom sandučetu
ui-outbox-sending = Slanje: { $subject }...
ui-from-account = Sa naloga { $account }
ui-sign-in-refused = Prijava na nalog { $account } je odbijena ili je sesija istekla.
ui-sign-in-again-ask = Da li želite ponovo da se prijavite u pregledaču?
ui-sign-in-again-failed = Ponovna prijava nije uspela: { $reason }
ui-unknown-reason = nepoznat razlog
ui-checking = Provera novih poruka na nalogu { $account }...
ui-done = Gotovo
ui-sent-at = Poruka { $subject } je poslata u { $time }
ui-draft-saved = Poruka je sačuvana u fascikli Radne verzije
ui-draft-not-saved = Poruka nije sačuvana u fascikli Radne verzije: { $reason }
ui-about-core = Jezgro { $version }
ui-add-account-first = Najpre dodajte nalog e-pošte.
ui-add-account-first-link = Najpre dodajte nalog e-pošte, a zatim ponovo kliknite vezu e-pošte.
ui-default-app-is = Inbox Classic je podrazumevana aplikacija za e-poštu. Veze ka adresama e-pošte otvaraju novu poruku u ovom programu.
ui-select-message-first = Najpre izaberite poruku.
ui-store-not-opened = Skladište pošte nije moguće otvoriti.
ui-store-or-cert-not-opened = Skladište pošte ili datoteku sertifikata nije moguće otvoriti.
ui-help-title = Pomoć za Inbox Classic
ui-help-missing = U ovoj kopiji programa Inbox Classic nedostaje pomoć.
ui-ok = U redu
ui-cancel = Otkaži
ui-close = Zatvori
ui-col-subject = Tema
ui-col-from = Od
ui-col-to = Za
ui-col-received = Primljeno
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Razgovor koji pratite
ui-col-sent = Poslato
ui-col-size = Veličina
ui-col-folder = Fascikla
ui-col-account = Nalog
ui-col-queued = Dodato u red
ui-col-status = Status
ui-outbox-title = Izlazno sanduče
ui-outbox-status-waiting = Čeka
ui-outbox-status-not-sent = Nije poslato: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = AI agent je stavio poruku u red; slanje u { $time }
ui-outbox-delete-ask = Da li želite da izbrišete ovu poruku bez slanja?
ui-open-link = Otvori vezu
ui-edit-link = Uredi vezu...
ui-remove-link = Ukloni vezu
ui-insert-attachment = Umetni prilog
ui-insert-picture = Umetni sliku
ui-filter-all = Sve datoteke
ui-filter-pictures = Slike
ui-filter-messages = Poruke e-pošte
ui-save-attachment-as = Sačuvaj prilog kao
ui-not-sent = Poruku nije moguće poslati.
ui-attachment-forgotten = Napisali ste „{ $word }“, ali nije priložena nijedna datoteka. Da li ipak želite da pošaljete poruku?
ui-send-anyway = Ipak pošalji
ui-go-back = Nazad
ui-not-saved = Poruku nije moguće sačuvati.
ui-saving-draft = Čuvanje u fascikli Radne verzije...
ui-compose-saved-at = Sačuvano u fascikli Radne verzije u { $time }
ui-compose-restored = Vraćeno nakon neočekivanog zatvaranja programa Inbox Classic
ui-compose-not-saved = Nije sačuvano u fascikli Radne verzije: { $reason }
ui-save-changes-ask = Da li želite da sačuvate promene ove poruke u fascikli Radne verzije?
ui-new-message-title = Nova poruka
ui-link-invalid = Unesite veb-adresu (https://...) ili vezu e-pošte (mailto:...).
ui-link-address = Adresa:
ui-hyperlink = Hiperveza
ui-hyperlink-intro = Adresa na koju će voditi veza u izabranom tekstu.
ui-edit-hyperlink = Uredi hipervezu
ui-edit-hyperlink-intro = Odredišna adresa veze. Izbrišite adresu da biste uklonili vezu i zadržali tekst.
ui-not-a-picture = Ova datoteka nije PNG, JPEG ili GIF slika ili je veća od 10 MB.
ui-format-color = Boja fonta
ui-format-numbers = Numerisana lista
ui-format-bullets = Lista sa znakovima za nabrajanje
ui-format-outdent = Smanji uvlaku
ui-format-indent = Povećaj uvlaku
ui-format-left = Poravnaj levo
ui-format-center = Centriraj
ui-format-right = Poravnaj desno
ui-format-line = Umetni vodoravnu crtu
ui-tb-send = Pošalji
ui-tb-save = Sačuvaj
ui-tb-attach = Priloži
ui-field-from = Od:
ui-field-to = Za:
ui-field-cc = Cc:
ui-field-bcc = Bcc:
ui-field-subject = Tema:
ui-field-attach = Prilozi:
ui-signature = Potpis
ui-signature-hint = Dodaje se novim porukama, odgovorima i prosleđenim porukama sa ovog naloga.
ui-signature-not-saved = Potpis nije moguće sačuvati.
ui-all-inboxes = Sva prijemna sandučad
ui-all-sent = Sve poslato
ui-all-drafts = Sve radne verzije
ui-flagged-folder = Označeno zastavicom
ui-all-folders = Sve fascikle
ui-the-account = nalog
ui-folder-name = Naziv fascikle:
ui-find-hint = Pretraži poštu
ui-find-tip = Pretražuje teme, pošiljaoce, primaoce, nazive priloga i tekst poruka.
ui-clear-search = Poništi pretragu
ui-no-match = Nijedna poruka ne odgovara upitu „{ $words }“.
ui-no-match-all = Pretraga obuhvata teme, pošiljaoce, primaoce, nazive priloga i tekst poruka u svim fasciklama. Proverite pravopis ili pokušajte sa manje reči.
ui-no-match-in = Pretraga u fascikli { $folder } obuhvata teme, pošiljaoce, primaoce, nazive priloga i tekst poruka. Proverite pravopis ili pokušajte sa manje reči.
ui-no-items = U ovom prikazu nema stavki.
ui-choose-folder = Izaberite fasciklu da biste videli njene poruke.
ui-unsubscribe = Otkaži pretplatu
ui-open-in-calendar = Otvori u kalendaru
ui-pictures-blocked = Neke slike su blokirane da bi se sprečilo praćenje. Kliknite ovde da biste ih preuzeli.
ui-not-shown = Poruku nije moguće prikazati.
ui-attachment-not-read = Prilog nije moguće pročitati.
ui-attachment-not-saved = Prilog nije moguće sačuvati.
ui-not-downloaded = Poruka još nije preuzeta.
ui-leave-list = Da li želite da se odjavite sa ove liste za slanje?
ui-leave-one-click = Inbox Classic će poslati zahtev za otkazivanje pretplate na { $target }. Neće se otvoriti nijedna veb-stranica niti će biti poslata poruka e-pošte.
ui-leave-mail = Da biste otkazali pretplatu, pošaljite poruku e-pošte na { $target }. Inbox Classic će je pripremiti za vas. Pošaljite poruku kao potvrdu.
ui-leave-web = Stranica za odjavu sa liste otvoriće se u pregledaču ({ $target }).
ui-unsubscribing = Otkazivanje pretplate: { $target }...
ui-cannot-unsubscribe = Ova poruka ne nudi opciju za otkazivanje pretplate.
ui-unsubscribed = Zahtev za otkazivanje pretplate je prihvaćen. Prema odgovoru liste, ove poruke vam više neće stizati.
ui-not-unsubscribed = Otkazivanje pretplate nije uspelo: { $reason }
ui-event-span = { $start } do { $end }
ui-event-floating = { $when } (vreme pošiljaoca)
ui-invitation = Pozivnica: { $title }
ui-invitation-updated = Ažurirana pozivnica: { $title }
ui-invitation-canceled = Otkazano: { $title }
ui-invitation-answer = Odgovor na pozivnicu: { $title }
ui-no-title = (bez naslova)
ui-organizer = Organizator: { $name }
ui-invitation-not-read = Pozivnicu nije moguće pročitati.
ui-no-calendar = Na ovom računaru nema aplikacije za kalendar koja može da otvori pozivnice (datoteke .ics).
ui-messages-not-changed = Poruke nije moguće promeniti.
ui-new-folder-in-selected = Nova fascikla biće napravljena unutar izabrane fascikle.
ui-new-folder-at-top = Nova fascikla biće napravljena na najvišem nivou naloga.
ui-folder-not-created = Fasciklu nije moguće napraviti.
ui-folder-not-renamed = Fasciklu nije moguće preimenovati.
ui-folder-not-deleted = Fasciklu nije moguće izbrisati.
ui-rename-folder-intro = Unesite novi naziv za fasciklu „{ $folder }“.
ui-properties-of = Svojstva: { $subject }
ui-internet-headers = Internet zaglavlja ove poruke:
ui-save-messages-in = Sačuvaj poruke u
ui-save-message-as = Sačuvaj poruku kao
ui-import-choose-folder = Najpre izaberite fasciklu u koju želite da uvezete poruke.
ui-add-account-title = Dodaj nalog e-pošte
ui-accounts-title = Nalozi
ui-security-none = Nema (nešifrovano)
ui-field-required = Popunite polje „{ $field }“.
ui-email-invalid = Adresa e-pošte nije važeća.
ui-ports-invalid = Portovi su brojevi od 1 do 65535.
ui-looking-up = Traženje podešavanja za { $domain }...
ui-found-none = Unesite podatke o nalogu koje ste dobili od pružaoca usluge e-pošte.
ui-found-change = Promenite ova podešavanja ako vam je pružalac usluge dao drugačija.
ui-found-guess = Za ovu adresu nisu pronađena podešavanja. Predloženi nazivi servera su pretpostavke. Proverite ih kod pružaoca usluge.
ui-found-mx = Inbox Classic je prepoznao vašeg pružaoca usluge e-pošte i popunio podešavanja servera.
ui-found-srv = Ova podešavanja su pronađena u DNS zapisima vašeg domena.
ui-found-autodiscover = Ova podešavanja je pronašao Microsoft Autodiscover (Exchange).
ui-found-other = Za ovu adresu su pronađena ova podešavanja.
ui-app-password-needed = { $provider } ne prihvata vašu uobičajenu lozinku u programima za e-poštu. U podešavanjima naloga kod tog pružaoca usluge napravite lozinku za aplikaciju i unesite je u polje Lozinka u sledećem koraku.
ui-app-password-open = { $provider }: Da li želite da otvorite uputstvo u pregledaču?
ui-plain-warning = Bez šifrovanja svako ko presretne vaš mrežni saobraćaj može da pročita vašu lozinku i poruke. Ovu vezu koristite samo sa serverom na svom računaru ili u lokalnoj mreži.
ui-continue-ask = Da li želite da nastavite?
ui-add-sign-in-app = Dodaj aplikaciju za prijavljivanje...
ui-turned-off = Aplikacija { $name } je isključena na ovom računaru.
ui-off-here = Isključeno na ovom računaru.
ui-why = Zašto?
ui-more-sign-in = Još opcija za prijavljivanje...
ui-other-account = Da biste dodali drugi nalog e-pošte, unesite svoju adresu e-pošte i ime koje primaoci treba da vide. Podešavanja servera biće potražena u sledećem koraku.
ui-field-account-name = Naziv naloga:
ui-field-name = Ime za prikaz:
ui-field-email = Adresa e-pošte:
ui-field-user = Korisničko ime:
ui-field-password = Lozinka:
ui-field-imap-host = Server dolazne pošte (IMAP):
ui-field-imap-port = IMAP port:
ui-field-imap-security = IMAP bezbednost:
ui-field-smtp-host = Server odlazne pošte (SMTP):
ui-field-smtp-port = SMTP port:
ui-field-smtp-security = SMTP bezbednost:
ui-field-other-addresses = Dodatne adrese za slanje:
ui-sign-in-not-started = Prijavu putem pregledača nije moguće pokrenuti.
ui-sign-in-in-browser = Prijavite se na nalog { $account } u prozoru pregledača koji se otvorio, a zatim se vratite ovamo.
ui-sign-in-failed = Prijava nije uspela: { $reason }
ui-account-not-saved = Nalog nije moguće sačuvati.
ui-start-intro = Gmail, Google Workspace, Outlook.com i Microsoft 365: prijavite se na stranici kompanije Google ili Microsoft. Lozinku unosite tamo, nikad u Inbox Classic.
ui-start-intro-apps = Prijavite se putem pregledača pomoću jedne od svojih aplikacija za prijavljivanje (Još opcija za prijavljivanje) ili unesite ime i adresu ispod da biste dodali drugi nalog e-pošte.
ui-use-app-password = Koristi lozinku za aplikaciju
ui-the-provider = Vaš pružalac usluge e-pošte
ui-provider-intro = { $provider }: Prijavite se na nalog { $email } na veb-sajtu pružaoca usluge. Inbox Classic ne dobija vašu lozinku. Ako vaš nalog podržava lozinke za aplikacije, možete da napravite jednu u bezbednosnim podešavanjima. Za Outlook.com i Microsoft 365 prijavite se putem pregledača.
ui-provider-intro-apps = { $provider }: Prijavite se na nalog { $email } na veb-sajtu pružaoca usluge pomoću jedne od svojih aplikacija za prijavljivanje (Još opcija za prijavljivanje). Ako vaš nalog podržava lozinke za aplikacije, možete da napravite jednu u bezbednosnim podešavanjima. Za Outlook.com i Microsoft 365 prijavite se putem pregledača.
ui-finish = Završi
ui-logon = Prijava
ui-enter-password = Unesite lozinku za nalog { $account }.
ui-signs-in-with = Aplikacija za prijavljivanje: { $app }. Prijavljivanje se obavlja u pregledaču, a nalog koristi servere ove aplikacije.
ui-keep-password = Ostavite polje lozinke prazno da biste zadržali trenutnu lozinku.
ui-remove-account = Ukloni nalog
ui-remove-account-ask = Da li želite da uklonite ovaj nalog iz programa Inbox Classic? Pošta ostaje na serveru. Sa ovog računara uklanjaju se lokalne kopije poruka i sačuvani podaci za prijavu.
ui-col-email = Adresa e-pošte
ui-col-incoming = Server dolazne pošte
ui-type-email = Unesite svoju adresu e-pošte, na primer ime@example.com.
ui-ai-agent = AI agent
ui-ai-agent-access = Pristup AI agenta
ui-ai-agents = AI agenti
ui-program-path = Program: { $path }
ui-it-may = Dozvoljene radnje:
ui-accounts-it-may-use = Dozvoljeni nalozi:
ui-send-message-ask = Da li želite da pošaljete poruku?
ui-col-name = Ime
ui-never = Nikad
ui-connect-agent = Poveži AI agenta
ui-connect-agent-intro = Dodajte sledeću konfiguraciju u spisak MCP servera svog agenta (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Program
ui-col-may = Dozvole
ui-col-last-used = Poslednja upotreba
ui-col-when = Kada
ui-col-what = Radnja
ui-sign-in-app = Aplikacija za prijavljivanje
ui-sign-in-apps = Aplikacije za prijavljivanje
ui-add-sign-in-app-title = Dodaj aplikaciju za prijavljivanje
ui-preset-app-name = Aplikacija za prijavljivanje: { $provider }
ui-issuer-not-checked = izdavaoca nije moguće proveriti
ui-checking-issuer = Provera izdavaoca { $issuer }...
ui-issuer-unusable = Izdavalac se ne može koristiti: { $reason }
ui-issuer-usable = Izdavalac se može koristiti.
ui-sign-in-app-not-saved = Aplikaciju za prijavljivanje nije moguće sačuvati: { $reason }
ui-check = Pro&veri
ui-fill-in-for = Koristi podešavanja za:
ui-app-name = Naziv:
ui-issuer = Izdavalac:
ui-client-id = ID klijenta:
ui-client-secret = Tajna klijenta:
ui-scopes = Opsezi (scopes):
ui-imap-server = IMAP server:
ui-smtp-server = SMTP server:
ui-redirect-uri = URI za preusmeravanje:
ui-sign-in-app-intro = Aplikacija za prijavljivanje je OAuth klijent koji registrujete kod pružaoca usluge da biste se prijavljivali putem pregledača. Izaberite uslugu da biste popunili podešavanja, pa unesite ID klijenta i tajnu klijenta, ako ste je dobili.
ui-remove-secret = Tajna klijenta je sačuvana. Unesite novu da biste je zamenili ili uklonite sačuvanu tajnu
ui-register-it = Registrujte aplikaciju kod pružaoca usluge
ui-built-in-note = Aplikacija { $name } je ugrađena. Možete samo da promenite da li se nudi za nove naloge.
ui-client-with-secret = ID klijenta: { $client }, sa tajnom klijenta.
ui-client-public = ID klijenta: { $client }, javni OAuth klijent bez tajne klijenta.
ui-no-accounts = Nema naloga
ui-remove-sign-in-app = Ukloni aplikaciju za prijavljivanje
ui-remove-sign-in-app-ask = Da li želite da uklonite aplikaciju za prijavljivanje { $name } i njenu sačuvanu tajnu klijenta?
ui-sign-in-app-not-removed = Aplikacija za prijavljivanje nije uklonjena. { $reason }
ui-sign-in-apps-intro = Aplikacije za prijavljivanje omogućavaju nalozima da se prijave putem pregledača. Aplikacija koja nije označena ne nudi se za nove naloge; nalozi koji je već koriste i dalje rade.
ui-col-issuer = Izdavalac
ui-col-used-by = Nalozi koji je koriste
ui-options-system-default = Podrazumevano u sistemu ({ $language })
ui-settings-general = Opšte
ui-settings-reading = Čitanje
ui-settings-new-mail = Nova pošta
ui-settings-sending = Slanje
ui-settings-default-apps = Podrazumevane aplikacije
ui-settings-message-list = Lista poruka
ui-settings-messages = Poruke
# review: new
ui-settings-encryption = Šifrovanje
ui-settings-language = Jezik
ui-settings-label = { $label }:
ui-apply = &Primeni
ui-language-label = &Jezik:
ui-restart-note = Ponovo pokrenite Inbox Classic da biste promenili jezik.
ui-restart-ask = Izabrani jezik ({ $language }) biće primenjen kada ponovo pokrenete Inbox Classic. Da li želite da ga ponovo pokrenete sada?
ui-notify-new-mail = &Obavesti me kada stigne nova pošta
ui-new-folder-title = Nova fascikla
ui-rename-folder-title = Preimenuj fasciklu
ui-delete-folder-question = Da li želite da izbrišete fasciklu „{ $folder }“ sa njenim porukama i fasciklama u njoj? Briše se i na serveru.
ui-properties = Svo&jstva
ui-account-sync = Pošalji i pri&mi
ui-account-properties = Svo&jstva...
ui-account-move-up = Premesti &gore
ui-account-move-down = Premesti d&ole
ui-menu-open = &Otvori
ui-menu-flag = Zasta&vica
ui-menu-view-source = Prikaži izvorni ko&d
ui-save-attachments = Sačuvaj priloge
ui-attachment-open = Otvori
ui-attachment-save-as = Sačuvaj kao...
ui-attachment-save-all = Sačuvaj sve...
ui-attachments-strip = Prilozi
ui-attachment-note-title = Otvaranje ove datoteke
ui-attachment-program-tip = Otvaranje je isključeno za ovu vrstu datoteke jer može da pokreće programe. Sačuvajte je da biste je sami otvorili.
ui-clear-flag = &Ukloni zastavicu
ui-button-move = &Premesti
ui-button-copy = &Kopiraj
ui-find-folder = Pronađi fasciklu
ui-new-folder-in = Nova fascikla biće napravljena u fascikli { $folder }.
ui-outbox-send-all = Pošalji &sve sada
ui-yes = Da
ui-no = Ne
ui-try-again = Pokušaj ponovo
ui-remove = Uk&loni
ui-signature-of = Potpis: { $account }
ui-sign-in-with = Prijavite se pomoću naloga { $provider }
ui-sign-in-in-browser-yours = Prijavite se na svoj nalog u prozoru pregledača koji se otvorio, a zatim se vratite ovamo.
ui-browser-sign-in-server = { $server } (prijava putem pregledača)
ui-dont-allow = Nemoj dozvoliti
ui-allow = &Dozvoli
ui-dont-send = Nemoj poslati
ui-edit-first = Najpre &uredi
ui-new-address = Nova adresa
ui-turn-away = &Odbij
ui-clear-agent-log = Da li želite da obrišete istoriju aktivnosti agenata?
ui-clear-agent-log-detail = Time se neće opozvati promene koje su agenti napravili.
ui-let-agents-connect = &Dozvoli AI agentima da se povežu sa programom Inbox Classic
ui-change-button = Promeni…
ui-undo-button = Opozovi
ui-rules-title = Pravila za poruke
ui-rules-intro = Pravila obrađuju nove poruke u Prijemnom sandučetu dok Inbox Classic radi. Primenjuju se redom na poruke koje ispunjavaju njihove kriterijume. Kada pravilo premesti poruku iz Prijemnog sandučeta, na nju se više ne primenjuju druga pravila.
ui-rules-none = Još nema pravila. Kliknite Novo da biste ga napravili.
ui-rule-new = &Novo...
ui-rule-edit = &Uredi...
ui-rule-delete-button = Iz&briši
ui-rule-title = Pravilo za poruke
ui-rule-name = Naziv:
ui-rule-account = Nalog:
ui-rule-all-accounts = Svi nalozi
ui-rule-query = Kriterijumi pretrage:
ui-rule-query-hint = Koristite izraze za pretragu kao što su from:ana@primer.rs, subject:faktura ili list:vesti.primer.rs, isto kao u polju za pretragu.
ui-rule-count = { $count ->
        [one] { $count } poruka u Prijemnom sandučetu trenutno odgovara ovim kriterijumima.
        [few] { $count } poruke u Prijemnom sandučetu trenutno odgovaraju ovim kriterijumima.
       *[other] { $count } poruka u Prijemnom sandučetu trenutno odgovara ovim kriterijumima.
}
ui-rule-show = Prika&ži
ui-rule-actions = Radnje:
ui-rule-move = Pre&mesti je u:
ui-rule-mark-read = Označi &je kao pročitanu
ui-rule-flag = Označi je &zastavicom
ui-rule-archive = &Arhiviraj je
ui-rule-junk = Premesti je u fasciklu &Neželjena e-pošta
ui-rule-delete = &Izbriši je
ui-rule-quiet = Nemoj me &obavestiti o njoj
ui-rule-apply-now = Primeni pravilo i na postojeće poruke u &Prijemnom sandučetu
ui-rule-delete-ask = Da li želite da izbrišete pravilo „{ $name }“?
ui-create-rule = Napravi pravilo...
ui-rules-applied = { $count ->
        [one] Vaša pravila su obradila { $count } poruku
        [few] Vaša pravila su obradila { $count } poruke
       *[other] Vaša pravila su obradila { $count } poruka
}
ui-col-rule-matches = Kriterijumi
ui-clear-button = O&briši
ui-how-to-connect = Kako povezati agenta…
ui-agent-programs = Programi čiji su agenti zatražili pristup vašoj pošti
ui-what-agents-did = Aktivnost agenata
ui-restart-now = &Ponovo pokreni sada
ui-restart-later = &Kasnije

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Novi kontakt
ui-tb-new-group = Nova grupa
ui-tb-properties = Svojstva
ui-tb-write-to = Napiši poruku
ui-menu-new-contact = Novi &kontakt...
ui-menu-new-group = Nova &grupa...
ui-menu-write-to = Na&piši poruku
ui-menu-delete = &Izbriši
ui-book-find-hint = Unesite ime ili adresu e-pošte
ui-book-all-contacts = Svi kontakti
ui-col-phone = Telefon
ui-book-empty = Adresar je prazan. Kliknite Novi kontakt da biste nekoga dodali ili uvezite datoteku vCard ili CSV iz menija Datoteka.
ui-book-no-match = Nijedan kontakt ne odgovara upitu „{ $words }“.
ui-book-delete-ask = { $count ->
    [1] Da li želite da izbrišete ovaj kontakt iz Adresara?
   *[other] Da li želite da izbrišete ove kontakte ({ $count }) iz Adresara?
}
ui-group-delete-ask = Da li želite da izbrišete grupu „{ $name }“? Kontakti ostaju u Adresaru.
ui-book-no-address = Kontakt { $name } nema adresu e-pošte.
ui-new-contact-title = Novi kontakt
ui-contact-title = Svojstva: { $name }
ui-contact-first = Ime:
ui-contact-last = Prezime:
ui-contact-display = Ime za prikaz:
ui-contact-nickname = Nadimak:
ui-contact-company = Preduzeće:
ui-contact-addresses = Adrese e-pošte:
ui-contact-address-hint = Unesite adresu e-pošte
ui-contact-add = &Dodaj
ui-contact-set-default = Postavi kao podra&zumevanu
ui-contact-default = { $address } (podrazumevana)
ui-contact-phones = Telefonski brojevi:
ui-phone-home = Kućni
ui-phone-work = Poslovni
ui-phone-mobile = Mobilni
ui-phone-other = Drugi
ui-contact-notes = Beleške:
ui-contact-name-needed = Unesite ime ili adresu e-pošte kontakta.
ui-contact-address-invalid = „{ $address }“ nije važeća adresa e-pošte.
ui-contact-not-saved = Kontakt nije moguće sačuvati: { $reason }
ui-new-group-title = Nova grupa
ui-group-title = Svojstva: { $name }
ui-group-name = Naziv grupe:
ui-group-members = Članovi:
ui-group-select-members = &Izaberi članove...
ui-group-new-member = Dodajte adresu e-pošte koja nije u Adresaru:
ui-group-name-needed = Unesite naziv grupe.
ui-group-not-saved = Grupu nije moguće sačuvati: { $reason }
ui-group-members-count = { $count ->
    [one] { $count } član
    [few] { $count } člana
   *[other] { $count } članova
}
ui-select-recipients = Izaberi primaoce
ui-select-members = Izaberi članove grupe
ui-pick-intro = Unesite ime ili ga izaberite sa liste:
ui-pick-recipients = Primaoci poruke:
ui-pick-members = Članovi grupe:
ui-pick-to = &Za →
ui-pick-cc = &Cc →
ui-pick-bcc = &Bcc →
ui-pick-add = &Dodaj →
ui-pick-tip = Izaberite primaoce iz Adresara
ui-filter-address-books = Adresari (vCard, CSV)
ui-filter-vcard = Datoteke vCard
ui-book-export-name = Adresar
ui-book-imported = { $added ->
    [one] Dodat je { $added } kontakt
    [few] Dodata su { $added } kontakta
   *[other] Dodato je { $added } kontakata
}, { $skipped ->
    [one] preskočen je { $skipped } postojeći kontakt.
    [few] preskočena su { $skipped } postojeća kontakta.
   *[other] preskočeno je { $skipped } postojećih kontakata.
}
ui-book-not-imported = Adresar nije moguće uvesti: { $reason }
ui-book-exported = { $count ->
    [one] { $count } kontakt je sačuvan u datoteku { $file }.
    [few] { $count } kontakta su sačuvana u datoteku { $file }.
   *[other] { $count } kontakata je sačuvano u datoteku { $file }.
}
ui-book-not-exported = Adresar nije moguće sačuvati: { $reason }
ui-code-copied = Kôd je kopiran
ui-codes-in-notifications = Pri&kaži kodove za prijavu u obaveštenjima o novoj pošti
ui-tool-unread-only = Nepročitano
ui-no-unread = Ovde nema nepročitanih poruka.
ui-pictures-always-sender = Uvek preuzimaj slike ovog pošiljaoca: { $sender }
ui-pictures-always-domain = Uvek preuzmi slike od svih sa domena { $domain }
ui-pictures-unconfirmed = Domen pošiljaoca ({ $domain }) nije moguće potvrditi, pa se slike u ovoj poruci ne preuzimaju automatski.
ui-pictures-always-option = Pre&uzimaj slike u svim porukama
ui-pictures-always-warning = Pošiljaoci tada mogu da vide kada čitate njihove poruke.
ui-protection-details = &Detalji...
ui-protection-details-title = Bezbednosni detalji
ui-download-heading = Preuzimanje
ui-download-ahead = &Unapred preuzimaj poruke:
ui-download-ahead-recent = Nedavne poruke veličine do 1 MB po poruci
ui-download-ahead-all = Sve poruke
ui-download-ahead-never = Samo pri otvaranju
ui-download-limit = Ograničenje pr&ostora po nalogu:
ui-send-delay = Odlaganje pre &slanja:
ui-send-delay-note = Dok poruka čeka na slanje, slanje možete da otkažete komandom Opozovi.
ui-dark-messages = Prikazuj poruke na tamnoj pozadini kada je sistem u tamnom režimu
ui-sending-in = Poruka { $subject } se šalje za { $count ->
    [one] { $count } sekundu
    [few] { $count } sekunde
   *[other] { $count } sekundi
}
ui-send-undone = Poruka { $subject } nije poslata. Ponovo je otvorena za uređivanje.
ui-send-too-late = Poruka { $subject } je već poslata.
ui-outbox-status-undo = Šalje se u { $time }
ui-download-note = Unapred preuzete poruke otvaraju se odmah. Kada se prekorači ograničenje skladišta, najstarije lokalne kopije se uklanjaju i ponovo preuzimaju kada ih otvorite.
ui-attachment-downloading = Preuzimanje ove poruke nije završeno. Pokušajte ponovo kada se preuzimanje završi.
ui-trusted-senders-button = P&ouzdani pošiljaoci...
ui-trusted-senders-title = Pouzdani pošiljaoci
ui-trusted-senders-note = Slike u porukama ovih pošiljalaca preuzimaju se automatski kada vaš pružalac usluge e-pošte potvrdi domen pošiljaoca.
ui-trusted-everyone-at = Svi sa domena { $domain }
ui-trusted-senders-empty = Još nije dodat nijedan pouzdani pošiljalac.
# review: new
ui-search-encrypted = Pretraži &šifrovane poruke
# review: new
ui-search-encrypted-note = Šifrovane poruke se dešifruju na ovom računaru kada se preuzmu ili otvore, kako bi se njihove reči mogle pronaći, a lista prikazala njihovu pravu temu. Indeks nije šifrovan i AI agenti ga nikada ne pretražuju. Isključite ovo da biste ih uklonili iz indeksa.
# review: new
ui-pgp-keyserver = &Traži ključeve na keys.openpgp.org
# review: new
ui-pgp-keyserver-note = Kada šifrujete poruku ili tražite ključ, tražena adresa se šalje na keys.openpgp.org. Najpre se pita sopstveni domen adrese.
ui-eml-default = Otvaraj &datoteke .eml u programu Inbox Classic
ui-eml-default-done = Inbox Classic sada otvara datoteke .eml.
ui-eml-default-failed = Inbox Classic nije moguće postaviti kao podrazumevanu aplikaciju za datoteke .eml: { $reason }
ui-folders = Fascikle
ui-sorted-by = Sortirano po: { $field }
ui-layout-label = &Raspored:
ui-columns-note = Prozor je dovoljno širok za raspored u kolonama. Raspored možete promeniti u meniju Prikaz > Raspored.
ui-row-unread = Nepročitano
ui-row-flagged = Označeno zastavicom
ui-row-attachments = Ima priloge
# review: new
ui-row-encrypted = Šifrovano
# review: new
ui-row-signed = Potpisano
ui-row-messages = { $count ->
    [one] { $count } poruka
    [few] { $count } poruke
   *[other] { $count } poruka
}
ui-list-pictures = Prikazuj &slike pošiljalaca na listi poruka
ui-list-pictures-note = U rasporedu sa kolonama prikazuje logotipe brendova ili slike iz Adresara kada je potvrđen domen pošiljaoca. Ako nema slike, prikazuju se inicijali. Preuzeti logotipi se čuvaju i ponovo koriste za više poruka.
ui-card-picture = Slika:
ui-card-picture-choose = &Izaberi...
ui-picture-not-picture = Ova datoteka nije PNG ili JPEG slika.
ui-picture-too-large = Ova slika je prevelika. Izaberite sliku od najviše 10 MB, čija širina i visina nisu veće od 8000 piksela.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
ui-keys-title = Ključevi za šifrovanje
ui-keys-intro = Vaši ključevi služe za digitalno potpisivanje poruka i dešifrovanje pošte namenjene vama. Ključevi kontakata služe za proveru njihovih digitalnih potpisa i šifrovanje pošte koju im šaljete.
ui-keys-empty = Još nema ključeva. Kliknite Novi ključ da biste napravili svoj ili Uvezi da biste dodali ključ koji već imate.
ui-keys-col-name = Ime
ui-keys-col-address = Adresa
ui-keys-col-kind = Vrsta
ui-keys-col-status = Status
ui-keys-kind-own = Vaš ključ
ui-keys-kind-contact = Kontakt
ui-keys-status-verified = { $status }, proveren
ui-keys-new = &Novi ključ...
ui-keys-import = U&vezi...
ui-keys-export = &Izvezi...
ui-keys-backup = Rezervna &kopija...
ui-keys-verify = &Proveri...
ui-keys-new-title = Novi ključ
ui-keys-new-for = Napravi ključ za:
ui-keys-new-make = &Napravi ključ
ui-keys-no-account = Najpre dodajte nalog e-pošte: ključ se pravi za adrese naloga.
ui-keys-memory-only = Podaci za prijavu čuvaju se samo u memoriji. Zato privatni ključ koji sada napravite ili uvezete neće moći da se koristi nakon zatvaranja programa Inbox Classic.
ui-keys-backup-offer = Vaš novi ključ je spreman. Da li želite sada da sačuvate njegovu rezervnu kopiju? Ako se ovaj računar izgubi ili vrati na fabrička podešavanja, ključ može da se vrati samo iz rezervne kopije.
ui-keys-backup-now = &Sačuvaj rezervnu kopiju...
ui-keys-later = &Kasnije
ui-keys-backup-title = Rezervna kopija ključa
ui-keys-backup-intro = Rezervna kopija je zaštićena pristupnom frazom. Datoteku i frazu čuvajte odvojeno, na bezbednim mestima. Za vraćanje ključa potrebne su vam obe.
ui-keys-passphrase = &Pristupna fraza:
ui-keys-passphrase-again = &Unesite je ponovo:
ui-keys-passphrase-differ = Pristupne fraze nisu iste.
ui-keys-passphrase-short = Koristite pristupnu frazu od najmanje 8 znakova.
ui-keys-backup-saved = Rezervna kopija je sačuvana.
ui-keys-import-title = Uvezi ključ
ui-keys-import-passphrase = Ovaj privatni ključ je zaštićen pristupnom frazom. Unesite je da biste uvezli ključ:
ui-keys-file-filter = OpenPGP ključevi
ui-keys-use-for = Da li želite da koristite ovaj ključ za sledeće adrese: { $addresses }? Poruke koje šaljete sa tih adresa biće potpisane ovim ključem. Moći ćete i da čitate poruke šifrovane njegovim javnim delom.
ui-keys-use = &Koristi ga
ui-keys-not-now = &Ne sada
ui-keys-remove-own = Da li želite da uklonite svoj ključ { $fingerprint }? Za poruke koje se mogu dešifrovati samo tim ključem moraćete ponovo da uvezete rezervnu kopiju privatnog ključa.
ui-keys-remove-contact = Da li želite da uklonite ovaj ključ ({ $name })? Dok ga ponovo ne dodate, njime nećete moći da proveravate digitalne potpise niti da šifrujete poruke.
ui-key-properties-title = Svojstva ključa
ui-key-names = Imena:
ui-key-fingerprint = Otisak ključa:
ui-key-status = Status:
ui-key-created = Napravljen:
ui-key-expires = Ističe:
ui-key-never = Nikad
ui-key-algorithm = Algoritam:
ui-key-source = Izvor:
ui-key-addresses = Adrese:
ui-key-address-verified = { $address } (proverena)
ui-key-address-not-verified = { $address } (nije proverena)
ui-verify-title = Proveri ključ
ui-verify-intro = Proveravate ključ za: { $name }. Zamolite vlasnika da vam uživo ili telefonom pročita otisak ključa iz svoje aplikacije. Ne koristite otisak poslat e-poštom za poređenje. Neko ko može da zameni ključ u poruci može da zameni i taj otisak.
ui-verify-fingerprint = Otisak sačuvanog ključa:
ui-verify-marks = { $count ->
    [1] Proverite da li ova adresa pripada vlasniku ključa: { $addresses }. Kliknite Podudaraju se samo ako se poklapaju i otisak i adresa. U suprotnom kliknite Razlikuju se.
   *[other] Proverite da li sve ove adrese pripadaju vlasniku ključa: { $addresses }. Kliknite Podudaraju se samo ako se poklapaju i otisak i sve adrese. U suprotnom kliknite Razlikuju se.
}
ui-verify-match = &Podudaraju se
ui-verify-differ = &Razlikuju se
ui-verify-differs = Sačuvani ključ ({ $name }) ne podudara se sa ključem vlasnika. Uklonite ga i zatražite ispravan ključ.
ui-verify-unmark = Označi kao &neprovereno
ui-account-security = Bezbednost
ui-account-security-intro = Ključ vam omogućava da digitalno potpisujete poruke i primate šifrovanu poštu.
ui-account-key = &Ključ za ovaj nalog:
ui-account-key-none = Nema
ui-account-key-new = &Novi ključ...
ui-account-autocrypt = &Šalji moj javni ključ uz moje poruke (Autocrypt)
ui-contact-key = Ključ za šifrovanje:
ui-contact-key-none = Nema ključa
ui-contact-key-use-new = Koristi &novi ključ
ui-contact-key-keep = &Zadrži trenutni
ui-setup-export-title = Izvezi podešavanja i naloge
ui-setup-import-title = Uvezi podešavanja i naloge
ui-setup-export-intro = Izaberite šta želite da prenesete na drugi računar. Datoteka ne sadrži poruke: tamo se ponovo preuzimaju.
ui-setup-use-passphrase = &Zaštiti datoteku pristupnom frazom
ui-setup-passphrase-note = Uz pristupnu frazu datoteka je šifrovana i sadrži sačuvane lozinke, podatke za prijavu i privatne ključeve. Bez pristupne fraze moraćete ponovo da se prijavite na naloge na drugom računaru, lozinkom ili putem pregledača.
ui-setup-export-button = &Izvezi...
ui-setup-file-filter = Podešavanja i nalozi programa Inbox Classic
ui-setup-ask-passphrase = Ova datoteka je zaštićena pristupnom frazom. Unesite je da biste videli šta datoteka sadrži:
ui-setup-import-intro = Izaberite šta želite da uvezete. Nalozi koji su već na ovom računaru ostaju nepromenjeni.
ui-setup-from = Sačuvao Inbox Classic { $version }, { $date }.
ui-setup-import-button = &Uvezi
ui-setup-done = Gotovo
ui-setup-first-run = Uvezi podešavanja i naloge sa drugog računara...
