# Slovenščina. Osnutek, čaka na pregled naravnega govorca (glej core/locales/GLOSSARY.md).
# An & marks the letter of a menu item that Alt and the letter choose on Windows and Linux (&& is an ampersand).

## The menus

menu-file = &Datoteka
menu-edit = &Urejanje
menu-view = &Pogled
menu-tools = &Orodja
menu-message = &Sporočilo
menu-help = Po&moč
menu-layout = Pos&tavitev
menu-sort-by = Razvrsti p&o
menu-text-size = &Velikost besedila
menu-folder = &Mapa
menu-insert = &Vstavi

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = &Nov račun...
cmd-exit = Iz&hod
cmd-sync = &Pošlji in prejmi vse
cmd-mark-read = Ozna&či kot prebrano
cmd-mark-unread = Označi kot &neprebrano
cmd-pictures = Prenesi s&like
cmd-about = &O programu Inbox Classic
cmd-new-mail = &Novo sporočilo
cmd-reply = &Odgovori pošiljatelju
cmd-reply-all = Odgovori &vsem
cmd-forward = &Posreduj
cmd-help = &Vsebina
cmd-delete = &Izbriši sporočilo
cmd-move = Pre&makni v mapo...
cmd-flag = Označi z &zastavico
cmd-new-folder = Nova &mapa...
cmd-rename-folder = P&reimenuj mapo...
cmd-delete-folder = &Izbriši mapo
cmd-empty-folder = Izprazni map&o
ui-empty-button = Izprazni
cmd-accounts = R&ačuni...
cmd-find = Na&jdi sporočilo
cmd-save-as = &Shrani kot...
cmd-print = Na&tisni...
cmd-import = &Uvozi sporočila...
cmd-outbox = &Odpošiljanje...
cmd-properties = &Lastnosti
cmd-mark-all-read = Označi vse kot pre&brano
cmd-junk = Označi kot n&eželeno
cmd-not-junk = Označi kot &želeno
cmd-archive = &Arhiviraj
cmd-watch-conversation = &Spremljaj pogovor
cmd-ignore-conversation = P&rezri pogovor
cmd-next-message = &Naslednje sporočilo
cmd-previous-message = &Prejšnje sporočilo
cmd-next-unread = Naslednje nepre&brano sporočilo
cmd-go-to-folder = Pojdi v &mapo...
cmd-find-in-message = Najdi v &tem sporočilu...
ui-go-to-prompt = Pojdi v mapo:
ui-find-in-message-hint = Najdi v tem sporočilu
ui-find-not-found = »{ $words }« ni v tem sporočilu
cmd-expand-all-threads = &Razširi vse pogovore
cmd-collapse-all-threads = Strni vse po&govore
ui-group-by-conversation = Z&druži sporočila po pogovorih
cmd-folder-list = &Seznam map
cmd-layout-automatic = &Samodejno
cmd-layout-classic = &Klasično
cmd-layout-columns = S&tolpci
cmd-sort-date = &Datum
cmd-sort-from = &Od
cmd-sort-subject = &Zadeva
cmd-sort-size = &Velikost
cmd-sort-ascending = &Naraščajoče
cmd-sort-descending = &Padajoče
cmd-text-size-largest = Na&jvečja
cmd-text-size-larger = &Večja
cmd-text-size-medium = &Srednja
cmd-text-size-smaller = &Manjša
cmd-text-size-smallest = Najma&njša
cmd-hide-ignored = Skrij pre&zrte pogovore
cmd-hide-read = S&krij prebrana sporočila
cmd-notify = O&bvesti o novi pošti
cmd-open = &Odpri Inbox Classic
cmd-default-app = Nastavi kot pri&vzeti poštni program...
cmd-view-source = &Izvorna koda sporočila
cmd-ai-agents = &Agenti UI...
cmd-options = &Možnosti...
cmd-message-rules = P&ravila za sporočila...
cmd-encryption-keys = Šifrirni &ključi...
cmd-create-rule-from-message = &Ustvari pravilo iz sporočila...
cmd-unsubscribe = O&djavi se s seznama...
cmd-select-all = Izberi &vse
cmd-undo = &Razveljavi
cmd-copy = &Kopiraj v mapo...
cmd-address-book = &Imenik...
cmd-add-sender-to-book = Dodaj pošil&jatelja v imenik
cmd-import-address-book = Uvozi imeni&k...
cmd-export-address-book = Izvozi im&enik...
cmd-export-setup = Izvozi nastavit&ve in račune...
cmd-import-setup = Uvo&zi nastavitve in račune...
cmd-compose-sign = &Digitalno podpiši
cmd-compose-encrypt = Ši&friraj
cmd-attach-my-key = Pripni svoj &javni ključ

## The tray icon's menu

tray-check = Preveri &novo pošto
tray-no-accounts = Še ni računov

## Words the windows of more than one platform share

ui-tb-create-mail = Ustvari sporočilo
ui-tb-reply = Odgovori
ui-tb-reply-all = Odgovori vsem
ui-tb-forward = Posreduj
ui-tb-print = Natisni
ui-tb-delete = Izbriši
ui-tb-junk = Neželeno
ui-tb-not-junk = Želeno
ui-tb-archive = Arhiviraj
ui-tb-previous = Prejšnje
ui-tb-next = Naslednje
ui-previous-tip = Prejšnje sporočilo
ui-next-tip = Naslednje sporočilo
ui-tb-sync = Pošlji/prejmi
ui-tb-mark-read = Prebrano
ui-tb-mark-unread = Neprebrano
ui-still-running = Inbox Classic se še vedno izvaja
ui-no-subject = (brez zadeve)
ui-quoted = »{ $subject }«
ui-newest-from = Zadnje sporočilo, pošiljatelj { $sender }: { $subject }
ui-new-messages = { $count ->
    [one] { $count } novo sporočilo
    [two] { $count } novi sporočili
    [few] { $count } nova sporočila
   *[other] { $count } novih sporočil
}
ui-outbox-waiting = { $count ->
    [one] { $count } sporočilo v mapi Odpošiljanje
    [two] { $count } sporočili v mapi Odpošiljanje
    [few] { $count } sporočila v mapi Odpošiljanje
   *[other] { $count } sporočil v mapi Odpošiljanje
}
ui-outbox-waits = { $subject } čaka v mapi Odpošiljanje
ui-outbox-sending = Pošiljanje { $subject }...
ui-from-account = Z računa »{ $account }«
ui-sign-in-refused = Prijava v račun »{ $account }« je bila zavrnjena ali pa je seja potekla.
ui-sign-in-again-ask = Se želite znova prijaviti v brskalniku?
ui-sign-in-again-failed = Ponovna prijava ni uspela: { $reason }
ui-unknown-reason = neznan razlog
ui-checking = Preverjanje novih sporočil za račun »{ $account }«...
ui-done = Končano
ui-sent-at = { $subject } poslano ob { $time }
ui-draft-saved = Sporočilo shranjeno v mapo Osnutki
ui-draft-not-saved = Sporočilo ni bilo shranjeno v mapo Osnutki: { $reason }
ui-about-core = Jedro { $version }
ui-add-account-first = Najprej dodajte poštni račun.
ui-add-account-first-link = Najprej dodajte poštni račun, nato znova kliknite e-poštno povezavo.
ui-default-app-is = Inbox Classic je vaš privzeti poštni program: e-poštne povezave tukaj odprejo novo sporočilo.
ui-select-message-first = Najprej izberite sporočilo.
ui-store-not-opened = Poštne shrambe ni bilo mogoče odpreti.
ui-store-or-cert-not-opened = Poštne shrambe ali datoteke s potrdilom ni bilo mogoče odpreti.
ui-help-title = Pomoč za Inbox Classic
ui-help-missing = V tej kopiji programa Inbox Classic manjka pomoč.
ui-ok = V redu
ui-cancel = Prekliči
ui-close = Zapri
ui-col-subject = Zadeva
ui-col-from = Od
ui-col-to = Za
ui-col-received = Prejeto
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Spremljan pogovor
ui-col-sent = Poslano
ui-col-size = Velikost
ui-col-folder = Mapa
ui-col-account = Račun
ui-col-queued = V čakalni vrsti
ui-col-status = Stanje
ui-outbox-title = Odpošiljanje
ui-outbox-status-waiting = Čaka
ui-outbox-status-not-sent = Ni poslano: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = V čakalno vrsto ga je dodal agent UI; pošiljanje najprej ob { $time }
ui-outbox-delete-ask = Želite izbrisati to sporočilo, ne da bi ga poslali?
ui-open-link = Odpri povezavo
ui-edit-link = Uredi povezavo...
ui-remove-link = Odstrani povezavo
ui-insert-attachment = Vstavi priponko
ui-insert-picture = Vstavi sliko
ui-filter-all = Vse datoteke
ui-filter-pictures = Slike
ui-filter-messages = Poštna sporočila
ui-save-attachment-as = Shrani priponko kot
ui-not-sent = Sporočila ni bilo mogoče poslati.
ui-attachment-forgotten = Napisali ste »{ $word }«, vendar ni pripeta nobena datoteka. Želite vseeno poslati sporočilo?
ui-send-anyway = Vseeno pošlji
ui-go-back = Nazaj
ui-not-saved = Sporočila ni bilo mogoče shraniti.
ui-saving-draft = Shranjevanje v mapo Osnutki...
ui-compose-saved-at = Shranjeno v mapo Osnutki ob { $time }
ui-compose-restored = Obnovljeno, potem ko se je Inbox Classic nepričakovano zaprl
ui-compose-not-saved = Ni shranjeno v mapo Osnutki: { $reason }
ui-save-changes-ask = Želite shraniti spremembe tega sporočila v mapo Osnutki?
ui-new-message-title = Novo sporočilo
ui-link-invalid = Vnesite spletni naslov (https://...) ali e-poštno povezavo (mailto:...).
ui-link-address = Naslov:
ui-hyperlink = Hiperpovezava
ui-hyperlink-intro = Naslov, na katerega kaže izbrano besedilo.
ui-edit-hyperlink = Uredi hiperpovezavo
ui-edit-hyperlink-intro = Ciljni naslov povezave. Izbrišite naslov, da odstranite povezavo in ohranite besedilo.
ui-not-a-picture = Slike ni bilo mogoče vstaviti. Izberite datoteko PNG, JPEG, GIF ali WebP, veliko največ 10 MB.
ui-format-color = Barva pisave
ui-format-numbers = Oštevilčen seznam
ui-format-bullets = Označen seznam
ui-format-outdent = Zmanjšaj zamik
ui-format-indent = Povečaj zamik
ui-format-left = Poravnaj levo
ui-format-center = Na sredino
ui-format-right = Poravnaj desno
ui-format-line = Vstavi vodoravno črto
ui-tb-send = Pošlji
ui-tb-save = Shrani
ui-tb-attach = Pripni
ui-tb-sign = Podpiši
ui-tb-encrypt = Šifriraj
ui-field-keys = Ključi:
ui-field-from = Od:
ui-field-to = Za:
ui-field-cc = Kp:
ui-field-bcc = Skp:
ui-field-subject = Zadeva:
ui-field-attach = Priponke:
ui-signature = Besedilo podpisa
ui-signature-hint = Doda se novim sporočilom, odgovorom in posredovanim sporočilom iz tega računa.
ui-signature-not-saved = Besedila podpisa ni bilo mogoče shraniti.
ui-all-inboxes = Vsa prejeta pošta
ui-all-sent = Vsa poslana pošta
ui-all-drafts = Vsi osnutki
ui-flagged-folder = Z zastavico
ui-all-folders = Vse mape
ui-the-account = račun
ui-folder-name = Ime mape:
ui-find-hint = Iskanje pošte
ui-find-tip = Išče po zadevah, pošiljateljih, prejemnikih, imenih priponk in besedilu sporočil.
ui-clear-search = Počisti iskanje
ui-no-match = Nobeno sporočilo se ne ujema z »{ $words }«.
ui-no-match-all = Iskanje zajema zadeve, pošiljatelje, prejemnike, imena priponk in besedilo sporočil v vseh mapah. Preverite črkovanje ali poskusite z manj besedami.
ui-no-match-in = Iskanje v pogledu »{ $folder }« zajema zadeve, imena in naslove pošiljateljev ter prejemnikov, imena priponk in besedilo sporočil. Preverite črkovanje ali poskusite z manj besedami.
ui-no-items = V tem pogledu ni sporočil.
ui-choose-folder = Izberite mapo, da vidite njena sporočila.
ui-unsubscribe = Odjavi
ui-open-in-calendar = Odpri v koledarju
ui-pictures-blocked = Nekatere slike so blokirane, da bi omejili pošiljateljevo sledenje odpiranju sporočila.
ui-not-shown = Sporočila ni bilo mogoče prikazati.
ui-attachment-not-read = Priponke ni bilo mogoče prebrati.
ui-attachment-not-saved = Priponke ni bilo mogoče shraniti.
ui-not-downloaded = Sporočilo še ni preneseno.
ui-leave-list = Se želite odjaviti s tega poštnega seznama?
ui-leave-one-click = Inbox Classic bo strežniku { $target } poslal zahtevo za odjavo. Pri tem ne bo odprl spletne strani ali poslal e-poštnega sporočila.
ui-leave-mail = Za odjavo pošljite e-poštno sporočilo na naslov { $target }. Inbox Classic ga bo pripravil za vas. Odjavo potrdite s pošiljanjem sporočila.
ui-leave-web = Stran za odjavo s poštnega seznama se bo odprla v brskalniku ({ $target }).
ui-unsubscribing = Pošiljanje zahteve za odjavo: { $target }...
ui-cannot-unsubscribe = To sporočilo ne ponuja možnosti odjave.
ui-unsubscribed = Zahteva za odjavo je bila sprejeta.
ui-not-unsubscribed = Odjava ni uspela: { $reason }
ui-list-bar = To sporočilo je s poštnega seznama ({ $domain }).
ui-list-bar-plain = To sporočilo je s poštnega seznama.
ui-list-bar-asked = Za odjavo s tega seznama ste zaprosili { $date }.
ui-list-bar-came-after = Za odjavo ste zaprosili { $date }, vendar je to sporočilo prispelo več kot dva dni pozneje.
ui-list-bar-opened = Stran za odjavo s tega seznama ste odprli { $date }.
ui-list-bar-failed = Zahteva za odjavo ni uspela: { $reason }
ui-unsubscribe-ask = Odjavi…
ui-unsubscribe-again = Znova odjavi…
ui-event-span = { $start } do { $end }
ui-event-floating = { $when } (časovni pas ni naveden ali ni prepoznan)
ui-invitation = Povabilo: { $title }
ui-invitation-updated = Posodobljeno povabilo: { $title }
ui-invitation-canceled = Preklicano: { $title }
ui-invitation-answer = Odgovor na povabilo: { $title }
ui-no-title = (brez naslova)
ui-organizer = Organizator: { $name }
ui-invitation-not-read = Povabila ni bilo mogoče prebrati.
ui-no-calendar = Povabila ni bilo mogoče odpreti v koledarskem programu. Preverite program, povezan z datotekami .ics.
ui-messages-not-changed = Sporočil ni bilo mogoče spremeniti.
ui-new-folder-in-selected = Nova mapa bo ustvarjena v izbrani mapi.
ui-new-folder-at-top = Nova mapa bo ustvarjena na najvišji ravni računa.
ui-folder-not-created = Mape ni bilo mogoče ustvariti.
ui-folder-not-renamed = Mape ni bilo mogoče preimenovati.
ui-folder-not-deleted = Mape ni bilo mogoče izbrisati.
ui-rename-folder-intro = Vnesite novo ime za mapo »{ $folder }«.
ui-properties-of = Lastnosti: { $subject }
ui-internet-headers = Internetne glave tega sporočila:
ui-save-messages-in = Mapa za shranjevanje sporočil
ui-save-message-as = Shrani sporočilo kot
ui-import-choose-folder = Najprej izberite mapo, v katero želite uvoziti sporočila.
ui-add-account-title = Dodaj poštni račun
ui-accounts-title = Računi
ui-security-none = Brez (nešifrirano)
ui-field-required = Polje »{ $field }« je obvezno.
ui-email-invalid = E-poštni naslov ni veljaven.
ui-ports-invalid = Vrata so števila od 1 do 65535.
ui-looking-up = Iskanje nastavitev za { $domain }...
ui-found-none = Vnesite podatke računa, ki vam jih je dal ponudnik e-pošte.
ui-found-change = Spremenite te nastavitve, če vam je ponudnik dal drugačne.
ui-found-guess = Za ta naslov ni bilo mogoče najti nastavitev. Predlagana imena strežnikov niso potrjena. Preverite jih pri ponudniku.
ui-found-mx = Inbox Classic je prepoznal vašega ponudnika e-pošte in vnesel nastavitve njegovih strežnikov.
ui-found-srv = Te nastavitve so bile najdene v zapisih DNS vaše domene.
ui-found-autodiscover = Te nastavitve je našla storitev Microsoft Autodiscover (Exchange).
ui-found-other = Te nastavitve so bile najdene za ta naslov.
ui-app-password-needed = Ponudnik { $provider } v poštnih programih ne sprejema običajnega gesla. Če vaš račun podpira gesla za aplikacije, ga ustvarite v njegovih varnostnih nastavitvah in vnesite v polje Geslo v naslednjem obrazcu. Za Outlook.com in Microsoft 365 uporabite prijavo prek brskalnika.
ui-app-password-open = Želite odpreti navodila ponudnika { $provider } v brskalniku?
ui-plain-warning = Brez šifriranja lahko vsakdo, ki prestreže omrežni promet, prebere vaše geslo in sporočila. Tudi lokalno omrežje samo po sebi ne zaščiti povezave. Nadaljujte le, če je povezava zaščitena na drug način.
ui-continue-ask = Želite nadaljevati?
ui-add-sign-in-app = Dodaj aplikacijo za prijavo...
ui-turned-off = Možnost »{ $name }« je v tem računalniku izklopljena.
ui-off-here = V tem računalniku izklopljeno.
ui-why = Zakaj?
ui-more-sign-in = Več možnosti prijave...
ui-other-account = Če želite dodati drug e-poštni račun, vnesite svoj e-poštni naslov in ime, ki naj ga vidijo prejemniki. Nastavitve strežnikov bodo poiskane v naslednjem koraku.
ui-field-account-name = Ime računa:
ui-field-name = Prikazno ime:
ui-field-email = E-poštni naslov:
ui-field-user = Uporabniško ime:
ui-field-password = Geslo:
ui-field-imap-host = Strežnik za dohodno pošto (IMAP):
ui-field-imap-port = Vrata IMAP:
ui-field-imap-security = Varnost IMAP:
ui-field-smtp-host = Strežnik za odhodno pošto (SMTP):
ui-field-smtp-port = Vrata SMTP:
ui-field-smtp-security = Varnost SMTP:
ui-field-other-addresses = Drugi naslovi, s katerih pošiljate:
ui-sign-in-not-started = Prijave prek brskalnika ni bilo mogoče začeti.
ui-sign-in-in-browser = V oknu brskalnika, ki se je odprlo, se prijavite v račun »{ $account }«, nato se vrnite sem.
ui-sign-in-failed = Prijava ni uspela: { $reason }
ui-account-not-saved = Računa ni bilo mogoče shraniti.
ui-start-intro = Gmail, Google Workspace, Outlook.com in Microsoft 365: prijavite se na Googlovi ali Microsoftovi strani. Geslo vnesete tam, nikoli v Inbox Classic.
ui-start-intro-apps = Prijavite se prek brskalnika z eno od svojih aplikacij za prijavo (Več možnosti prijave) ali spodaj dodajte kateri koli e-poštni račun s svojim imenom in naslovom.
ui-use-app-password = Uporabi geslo za aplikacije
ui-the-provider = ponudnik
ui-provider-intro = Na spletni strani ponudnika ({ $provider }) se prijavite v račun »{ $email }«. Inbox Classic ne prejme vašega gesla. Če račun podpira gesla za aplikacije, lahko uporabite geslo, ustvarjeno v njegovih varnostnih nastavitvah. Outlook.com in Microsoft 365 podpirata samo prijavo prek brskalnika.
ui-provider-intro-apps = Na spletni strani ponudnika ({ $provider }) se prijavite v račun »{ $email }« z eno od svojih aplikacij za prijavo (Več možnosti prijave). Če račun podpira gesla za aplikacije, lahko uporabite geslo, ustvarjeno v njegovih varnostnih nastavitvah. Outlook.com in Microsoft 365 podpirata samo prijavo prek brskalnika.
ui-finish = Dokončaj
ui-logon = Prijava
ui-enter-password = Vnesite geslo za račun »{ $account }«.
ui-signs-in-with = Aplikacija za prijavo: { $app }. Prijava poteka v brskalniku in račun uporablja strežnike te aplikacije.
ui-keep-password = Pustite polje za geslo prazno, da obdržite trenutno geslo.
ui-remove-account = Odstrani račun
ui-remove-account-ask = Želite odstraniti ta račun iz programa Inbox Classic? Sporočila na strežniku ostanejo. Lokalni podatki računa, vključno s sporočili v čakalni vrsti za pošiljanje in shranjenimi podatki za prijavo, bodo odstranjeni.
ui-col-email = E-poštni naslov
ui-col-incoming = Strežnik za dohodno pošto
ui-type-email = Vnesite svoj e-poštni naslov, ime@example.com.
ui-ai-agent = Agent UI
ui-ai-agent-access = Dostop agentov UI
ui-ai-agents = Agenti UI
ui-program-path = Program: { $path }
ui-it-may = Dovoljena dejanja:
ui-accounts-it-may-use = Dovoljeni računi:
ui-send-message-ask = Želite poslati sporočilo?
ui-col-name = Ime
ui-never = Nikoli
ui-connect-agent = Poveži agenta UI
ui-connect-agent-intro = To dodajte med strežnike MCP svojega agenta (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Program
ui-col-may = Dovoljenja
ui-col-last-used = Zadnji dostop
ui-col-when = Kdaj
ui-col-what = Dejanje
ui-sign-in-app = Aplikacija za prijavo
ui-sign-in-apps = Aplikacije za prijavo
ui-add-sign-in-app-title = Dodaj aplikacijo za prijavo
ui-preset-app-name = Aplikacija za prijavo ({ $provider })
ui-issuer-not-checked = izdajatelja ni mogoče preveriti
ui-checking-issuer = Preverjanje izdajatelja: { $issuer }...
ui-issuer-unusable = Izdajatelja ni mogoče uporabiti: { $reason }
ui-issuer-usable = Izdajatelja je mogoče uporabiti.
ui-sign-in-app-not-saved = Aplikacije za prijavo ni bilo mogoče shraniti: { $reason }
ui-check = P&reveri
ui-fill-in-for = Uporabi nastavitve za:
ui-app-name = Ime:
ui-issuer = Izdajatelj:
ui-client-id = ID odjemalca:
ui-client-secret = Skrivnost odjemalca:
ui-scopes = Dovoljenja (scopes):
ui-imap-server = Strežnik IMAP:
ui-smtp-server = Strežnik SMTP:
ui-redirect-uri = Preusmeritveni URI:
ui-sign-in-app-intro = Aplikacija za prijavo je odjemalec OAuth, ki ga registrirate pri ponudniku, da se prijavljate prek brskalnika. Izberite ponudnika, da izpolnite njegove nastavitve, nato dodajte ID odjemalca in skrivnost odjemalca, če vam jo je ponudnik dal.
ui-remove-secret = Skrivnost odjemalca je shranjena. Vnesite novo, da jo zamenjate, ali odstranite shranjeno skrivnost
ui-register-it = Registrirajte aplikacijo pri ponudniku
ui-built-in-note = Aplikacija »{ $name }« je vgrajena. Spremenite lahko samo, ali je na voljo za nove račune.
ui-client-with-secret = ID odjemalca: { $client }, s skrivnostjo odjemalca.
ui-client-public = ID odjemalca: { $client }, javni odjemalec (brez skrivnosti).
ui-no-accounts = Ni računov
ui-remove-sign-in-app = Odstrani aplikacijo za prijavo
ui-remove-sign-in-app-ask = Želite odstraniti aplikacijo za prijavo »{ $name }« in njeno shranjeno skrivnost odjemalca?
ui-sign-in-app-not-removed = Aplikacija za prijavo ni bila odstranjena. { $reason }
ui-sign-in-apps-intro = Z aplikacijami za prijavo se računi prijavljajo prek brskalnika. Neoznačena aplikacija ni na voljo za nove račune; računi, ki jo že uporabljajo, delujejo naprej.
ui-col-issuer = Izdajatelj
ui-col-used-by = Uporablja
ui-options-system-default = Privzeto v sistemu ({ $language })
ui-settings-general = Splošno
ui-settings-reading = Branje
ui-settings-new-mail = Nova pošta
ui-settings-sending = Pošiljanje
ui-settings-default-apps = Privzeti programi
ui-settings-message-list = Seznam sporočil
ui-settings-messages = Sporočila
ui-settings-encryption = Šifriranje
ui-settings-language = Jezik
ui-settings-label = { $label }:
ui-apply = &Uporabi
ui-language-label = &Jezik:
ui-restart-note = Za spremembo jezika znova zaženite Inbox Classic.
ui-restart-ask = Po ponovnem zagonu bo Inbox Classic uporabljal jezik: { $language }. Želite program zdaj znova zagnati?
ui-notify-new-mail = &Obvesti me, ko prispe nova pošta
ui-new-folder-title = Nova mapa
ui-rename-folder-title = Preimenuj mapo
ui-delete-folder-question = Želite izbrisati mapo »{ $folder }« z njenimi sporočili in mapami v njej? Izbrisana bo tudi na strežniku.
ui-properties = &Lastnosti
ui-account-sync = &Pošlji in prejmi
ui-account-properties = L&astnosti...
# review: new
ui-account-properties-of = Lastnosti ra&čuna...
ui-account-move-up = Premakni &gor
ui-account-move-down = Premakni &dol
ui-menu-open = O&dpri
ui-menu-flag = Zastavi&ca
ui-menu-view-source = Pokaži i&zvorno kodo
# Context menu: the same action as cmd-unsubscribe, with its own access key.
ui-menu-unsubscribe = O&djavi se s seznama...
ui-save-attachments = Shrani priponke
ui-attachment-open = Odpri
ui-attachment-save-as = Shrani kot...
ui-attachment-save-all = Shrani vse...
ui-attachment-show-in-message = Pokaži v sporočilu
ui-attachments-strip = Priponke
ui-attachment-note-title = Odpiranje te datoteke
ui-attachment-program-tip = Odpiranje je za to vrsto datoteke izklopljeno, ker lahko zažene programe. Shranite jo in jo odprite sami.
ui-clear-flag = Odstrani z&astavico
ui-button-move = &Premakni
ui-button-copy = &Kopiraj
ui-find-folder = Poišči mapo
ui-new-folder-in = Nova mapa bo ustvarjena v mapi »{ $folder }«.
ui-outbox-send-all = &Pošlji vse zdaj
ui-yes = Da
ui-no = Ne
ui-try-again = Poskusi znova
ui-remove = &Odstrani
ui-signature-of = Besedilo podpisa: { $account }
ui-sign-in-with = Prijava: { $provider }
ui-sign-in-in-browser-yours = Prijavite se v svoj račun v oknu brskalnika, ki se je odprlo, nato se vrnite sem.
ui-browser-sign-in-server = { $server } (prijava v brskalniku)
ui-dont-allow = Ne dovoli
ui-allow = &Dovoli
ui-dont-send = Ne pošlji
ui-dont-unsubscribe = Ne odjavi
ui-edit-first = Najprej &uredi
ui-new-address = Nov naslov
ui-turn-away = &Zavrni
ui-clear-agent-log = Želite počistiti zgodovino dejavnosti agentov?
ui-clear-agent-log-detail = S tem ne boste razveljavili sprememb, ki so jih naredili agenti.
ui-let-agents-connect = &Dovoli agentom UI povezavo s programom Inbox Classic
ui-change-button = Spremeni…
ui-undo-button = Razveljavi
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Razveljavi za obdobje…
ui-undo-since-span = Razveljavi, kar je ta program naredil:
ui-take-back = Razveljavi
ui-rules-title = Pravila za sporočila
ui-rules-intro = Pravila urejajo nova sporočila v mapi Prejeto, medtem ko Inbox Classic deluje. Pravila, katerih pogoji so izpolnjeni, se obdelajo po vrsti. Ko pravilo določi premik v razpoložljivo mapo, se nadaljnja pravila za to sporočilo ne obdelajo, tudi če strežnik premika še ni potrdil.
ui-rules-none = Še ni pravil. Kliknite Novo, da ga ustvarite.
ui-rule-new = &Novo...
ui-rule-edit = &Uredi...
ui-rule-delete-button = &Izbriši
ui-rule-title = Pravilo za sporočila
ui-rule-name = Ime:
ui-rule-account = Račun:
ui-rule-all-accounts = Vsi računi
ui-rule-query = Iskalni pogoji:
ui-rule-query-hint = Uporabite iskalne izraze, kot so from:ana@example.com, subject:račun ali list:news.example.com, enako kot v iskalnem polju.
ui-rule-count = { $count ->
    [one] Tem pogojem trenutno ustreza { $count } sporočilo v mapi Prejeto.
    [two] Tem pogojem trenutno ustrezata { $count } sporočili v mapi Prejeto.
    [few] Tem pogojem trenutno ustrezajo { $count } sporočila v mapi Prejeto.
   *[other] Tem pogojem trenutno ustreza { $count } sporočil v mapi Prejeto.
}
ui-rule-show = Po&kaži
ui-rule-actions = Dejanja:
ui-rule-move = Pre&makni ga v:
ui-rule-mark-read = Označi ga kot &prebrano
ui-rule-flag = Označi ga z &zastavico
ui-rule-archive = &Arhiviraj ga
ui-rule-junk = Premakni ga v mapo &Neželena e-pošta
ui-rule-delete = &Izbriši ga
ui-rule-quiet = Ne &obveščaj me o njem
ui-rule-apply-now = Uporabi ga tudi za sporočila, ki so že v mapi Pr&ejeto
ui-rule-delete-ask = Želite izbrisati pravilo »{ $name }«?
ui-create-rule = Ustvari pravilo...
ui-rules-applied = { $count ->
    [one] Vaša pravila so obdelala { $count } sporočilo
    [two] Vaša pravila so obdelala { $count } sporočili
    [few] Vaša pravila so obdelala { $count } sporočila
   *[other] Vaša pravila so obdelala { $count } sporočil
}
ui-col-rule-matches = Pogoji
ui-clear-button = Po&čisti
ui-how-to-connect = Kako povezati agenta…
ui-agent-programs = Programi, katerih agenti so zahtevali dostop do vaše pošte
ui-what-agents-did = Dejavnost agentov
ui-restart-now = Znova zaženi &zdaj
ui-restart-later = &Pozneje

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Nov stik
ui-tb-new-group = Nova skupina
ui-tb-properties = Lastnosti
ui-tb-write-to = Piši
ui-menu-new-contact = Nov &stik...
ui-menu-new-group = Nova s&kupina...
ui-menu-write-to = &Piši
ui-menu-delete = &Izbriši
ui-book-find-hint = Vnesite ime ali e-poštni naslov
ui-book-all-contacts = Vsi stiki
ui-col-phone = Telefon
ui-book-empty = Imenik je prazen. Kliknite Nov stik, da koga dodate, ali v meniju Datoteka uvozite datoteko vCard ali CSV.
ui-book-no-match = Noben stik se ne ujema z »{ $words }«.
ui-book-delete-ask = { $count ->
    [one] Želite iz Imenika izbrisati { $count } stik?
    [two] Želite iz Imenika izbrisati { $count } stika?
    [few] Želite iz Imenika izbrisati { $count } stike?
   *[other] Želite iz Imenika izbrisati { $count } stikov?
}
ui-group-delete-ask = Želite izbrisati skupino »{ $name }«? Osebe v njej ostanejo v Imeniku.
ui-book-no-address = Stik »{ $name }« nima e-poštnega naslova.
ui-new-contact-title = Nov stik
ui-contact-title = Lastnosti: { $name }
ui-contact-first = Ime:
ui-contact-last = Priimek:
ui-contact-display = Prikazno ime:
ui-contact-nickname = Vzdevek:
ui-contact-company = Podjetje:
ui-contact-addresses = E-poštni naslovi:
ui-contact-address-hint = Vnesite e-poštni naslov
ui-contact-add = &Dodaj
ui-contact-set-default = Nastavi kot &privzeto
ui-contact-default = { $address } (privzeto)
ui-contact-phones = Telefonske številke:
ui-phone-home = Doma
ui-phone-work = Služba
ui-phone-mobile = Mobilni
ui-phone-other = Drugo
ui-contact-notes = Opombe:
ui-contact-name-needed = Vnesite ime ali e-poštni naslov stika.
ui-contact-address-invalid = »{ $address }« ni veljaven e-poštni naslov.
ui-contact-not-saved = Stika ni bilo mogoče shraniti: { $reason }
ui-new-group-title = Nova skupina
ui-group-title = Lastnosti: { $name }
ui-group-name = Ime skupine:
ui-group-members = Člani:
ui-group-select-members = &Izberi člane...
ui-group-new-member = Dodajte e-poštni naslov, ki ga ni v Imeniku:
ui-group-name-needed = Vnesite ime skupine.
ui-group-not-saved = Skupine ni bilo mogoče shraniti: { $reason }
ui-group-members-count = { $count ->
    [one] { $count } član
    [two] { $count } člana
    [few] { $count } člani
   *[other] { $count } članov
}
ui-select-recipients = Izberi prejemnike
ui-select-members = Izberi člane skupine
ui-pick-intro = Vnesite ime ali ga izberite s seznama:
ui-pick-recipients = Prejemniki sporočila:
ui-pick-members = Člani skupine:
ui-pick-to = &Za →
ui-pick-cc = &Kp →
ui-pick-bcc = &Skp →
ui-pick-add = &Dodaj →
ui-pick-tip = Izberite prejemnike iz Imenika
ui-filter-address-books = Imeniki (vCard, CSV)
ui-filter-vcard = Datoteke vCard
ui-book-export-name = Imenik
ui-book-imported = { $added ->
    [one] Dodan { $added } stik
    [two] Dodana { $added } stika
    [few] Dodani { $added } stiki
   *[other] Dodanih { $added } stikov
}, { $skipped ->
    [one] preskočen { $skipped }, ki je že v Imeniku.
    [two] preskočena { $skipped }, ki sta že v Imeniku.
    [few] preskočeni { $skipped }, ki so že v Imeniku.
   *[other] preskočenih { $skipped }, ki so že v Imeniku.
}
ui-book-not-imported = Imenika ni bilo mogoče uvoziti: { $reason }
ui-book-exported = { $count ->
    [one] { $count } stik shranjen v { $file }.
    [two] { $count } stika shranjena v { $file }.
    [few] { $count } stiki shranjeni v { $file }.
   *[other] { $count } stikov shranjenih v { $file }.
}
ui-book-not-exported = Imenika ni bilo mogoče shraniti: { $reason }
ui-code-copied = Koda je kopirana
ui-codes-in-notifications = &Pokaži kode za prijavo v obvestilih o novi pošti
ui-tool-unread-only = Neprebrano
ui-no-unread = Tukaj ni neprebranih sporočil.
ui-pictures-always-sender = Vedno prenesi slike pošiljatelja: { $sender }
ui-pictures-always-domain = Vedno prenesi slike vseh pošiljateljev v domeni »{ $domain }«
ui-pictures-unconfirmed = Domene pošiljatelja ({ $domain }) ni bilo mogoče preveriti, zato se slike v tem sporočilu ne prenesejo samodejno.
ui-pictures-always-option = Prenašaj slike &v vseh sporočilih
ui-pictures-always-warning = Pošiljatelji bodo nato lahko videli, kdaj preberete njihova sporočila.
ui-protection-details = &Podrobnosti...
ui-protection-details-title = Varnostne podrobnosti
ui-download-heading = Prenašanje
ui-download-ahead = &Vnaprej prenesi sporočila:
ui-download-ahead-recent = Nedavna sporočila, velika največ 1 MB
ui-download-ahead-all = Vsa sporočila
ui-download-ahead-never = Samo ob odpiranju
ui-download-limit = &Omejitev prostora na račun:
ui-send-delay = &Zakasnitev pred pošiljanjem:
ui-send-delay-note = Do izteka odštevanja lahko pošiljanje prekličete z ukazom Razveljavi.
ui-dark-messages = Pokaži sporočila na temnem ozadju, ko je sistem v temnem načinu
ui-preview-show = Prikaži pripon&ke v sporočilih
ui-preview-show-note = Za besedilom sporočila prikaže slike in prve strani datotek PDF. Inbox Classic predoglede izdela brez izvajanja kode iz datotek.
ui-preview-pdfs = Prikaži datoteke PD&F v sporočilih
ui-sending-in = Pošiljanje { $subject } čez { $count ->
    [one] { $count } sekundo
    [two] { $count } sekundi
    [few] { $count } sekunde
   *[other] { $count } sekund
}
ui-send-undone = Sporočilo { $subject } ni bilo poslano in je znova odprto za urejanje.
ui-send-too-late = Pošiljanja sporočila { $subject } ni več mogoče preklicati.
ui-outbox-status-undo = Pošiljanje najprej ob { $time }
ui-download-note = Vnaprej prenesena sporočila se odprejo takoj. Ko je omejitev prostora presežena, se odstranijo najstarejše lokalne kopije, ki jih je mogoče varno odstraniti. Osnutki in sporočila, odprta med trenutnim delovanjem programa, ostanejo, zato je omejitev lahko presežena. Sporočila na strežniku lahko znova prenesete.
ui-attachment-downloading = Prenos tega sporočila še ni končan. Poskusite znova, ko bo prenos končan.
ui-trusted-senders-button = &Zaupanja vredni pošiljatelji...
ui-trusted-senders-title = Zaupanja vredni pošiljatelji
ui-trusted-senders-note = Slike teh pošiljateljev se lahko prenesejo samodejno, ko ponudnik e-pošte potrdi domeno pošiljatelja. Za šifrirane dele sporočil morate prenos vsakič izrecno dovoliti.
ui-trusted-everyone-at = Vsi pošiljatelji v domeni »{ $domain }«
ui-trusted-senders-empty = Dodan še ni noben zaupanja vreden pošiljatelj.
ui-search-encrypted = Išči v &šifriranih sporočilih
ui-search-encrypted-note = Prenesena sporočila se lahko v tem računalniku dešifrirajo, če so na voljo ustrezni ključi. Besedilo in izvirne zadeve se shranijo v lokalni nešifrirani indeks za iskanje in prikaz na seznamu. Agenti UI ne iščejo po dešifrirani vsebini. Izklop možnosti te podatke odstrani iz indeksa.
ui-pgp-keyserver = &Išči ključe na keys.openpgp.org
ui-pgp-keyserver-note = Pri iskanju ključa za e-poštni naslov se najprej preveri njegova domena, nato po potrebi keys.openpgp.org. Posreduje se iskani naslov. Pri iskanju po prstnem odtisu ali ID-ju ključa se posreduje ta identifikator, ne vsebina sporočil.
ui-eml-default = O&dpiraj datoteke .eml s programom Inbox Classic
ui-eml-default-done = Inbox Classic zdaj odpira datoteke .eml.
ui-eml-default-failed = Inbox Classic ni bilo mogoče nastaviti kot privzeti program za datoteke .eml: { $reason }
ui-folders = Mape
ui-sorted-by = Razvrščeno po: { $field }
ui-layout-label = &Postavitev:
ui-columns-note = Okno je dovolj široko za postavitev s stolpci. Postavitev lahko spremenite v meniju Pogled > Postavitev.
ui-row-unread = Neprebrano
ui-row-flagged = Z zastavico
ui-row-attachments = Ima priponke
ui-row-encrypted = Šifrirano
ui-row-signed = Podpisano
ui-row-messages = { $count ->
    [one] { $count } sporočilo
    [two] { $count } sporočili
    [few] { $count } sporočila
   *[other] { $count } sporočil
}
ui-list-pictures = Pokaži &slike pošiljateljev na seznamu sporočil
ui-list-pictures-note = V postavitvi s stolpci prikaže logotipe ali slike iz Imenika za pošiljatelje s potrjeno domeno. Če slike ni, prikaže začetnice. Preneseni logotipi se shranijo lokalno in uporabljajo tudi po ponovnem zagonu; občasno se osvežijo.
ui-card-picture = Slika:
ui-card-picture-choose = &Izberi...
ui-picture-not-picture = Datoteka ni veljavna slika PNG ali JPEG.
ui-picture-too-large = Ta slika je prevelika. Izberite sliko, ki ni večja od 10 MB ter je široka in visoka največ 8000 slikovnih pik.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
ui-keys-title = Šifrirni ključi
ui-keys-intro = S svojimi ključi podpisujete sporočila in dešifrirate pošto, namenjeno vam. S ključi stikov preverjate njihove podpise in šifrirate pošto zanje.
ui-keys-empty = Še ni ključev. Kliknite Nov ključ, da ustvarite svojega, ali Uvozi, da dodate ključ, ki ga že imate.
ui-keys-col-name = Ime
ui-keys-col-address = Naslov
ui-keys-col-kind = Vrsta
ui-keys-col-status = Stanje
ui-keys-kind-own = Vaš ključ
ui-keys-kind-contact = Stik
ui-keys-status-verified = { $status }, lastnik ključa je potrjen
ui-keys-new = &Nov ključ...
ui-keys-import = &Uvozi...
ui-keys-export = &Izvozi...
ui-keys-backup = &Varnostna kopija...
ui-keys-verify = P&reveri...
ui-keys-new-title = Nov ključ
ui-keys-new-for = Ustvari ključ za:
ui-keys-new-make = &Ustvari ključ
ui-keys-no-account = Najprej dodajte poštni račun: ključ se ustvari za naslove računa.
ui-keys-memory-only = Gesla so shranjena samo v pomnilniku, zato zasebnega ključa, ki ga ustvarite ali uvozite zdaj, po zaprtju programa Inbox Classic ne bo mogoče uporabiti.
ui-keys-backup-offer = Vaš novi ključ je pripravljen. Želite zdaj shraniti njegovo varnostno kopijo? Če se ta računalnik izgubi ali ponastavi, je ključ mogoče obnoviti samo iz varnostne kopije.
ui-keys-backup-now = &Shrani varnostno kopijo...
ui-keys-later = &Pozneje
ui-keys-backup-title = Varnostna kopija ključa
ui-keys-backup-intro = Varnostno kopijo ščiti zaščitno geslo. Datoteko in zaščitno geslo hranite na različnih varnih mestih: za obnovitev ključa potrebujete oboje.
ui-keys-passphrase = &Zaščitno geslo:
ui-keys-passphrase-again = &Vnesite ga znova:
ui-keys-passphrase-differ = Zaščitni gesli se ne ujemata.
ui-keys-passphrase-short = Uporabite zaščitno geslo z vsaj 8 znaki.
ui-keys-backup-saved = Varnostna kopija je shranjena.
ui-keys-import-title = Uvozi ključ
ui-keys-import-passphrase = Ta zasebni ključ je zaščiten z zaščitnim geslom. Vnesite ga, da uvozite ključ:
ui-keys-file-filter = Ključi OpenPGP
ui-keys-use-for = Želite ta ključ povezati z naslovi: { $addresses }? Z njim boste lahko podpisovali sporočila s teh naslovov in tukaj dešifrirali pošto, šifrirano z ustreznim javnim ključem.
ui-keys-use = &Uporabi ga
ui-keys-not-now = &Ne zdaj
ui-keys-remove-own = Želite odstraniti svoj ključ { $fingerprint }? Za ponovno dešifriranje sporočil s tem ključem boste morali uvoziti njegovo varnostno kopijo. Že dešifrirana vsebina se ne izbriše.
ui-keys-remove-contact = Želite odstraniti ključ »{ $name }«? Z njim ne boste mogli preverjati podpisov ali šifrirati sporočil, dokler ga znova ne dodate.
ui-key-properties-title = Lastnosti ključa
ui-key-names = Imena:
ui-key-fingerprint = Prstni odtis:
ui-key-status = Stanje:
ui-key-created = Ustvarjen:
ui-key-expires = Poteče:
ui-key-never = Nikoli
ui-key-algorithm = Algoritem:
ui-key-source = Vir:
ui-key-addresses = Naslovi:
ui-key-address-verified = { $address } (lastnik ključa je potrjen)
ui-key-address-not-verified = { $address } (lastnik ključa ni potrjen)
ui-verify-title = Preveri ključ
ui-verify-intro = Lastnika ključa »{ $name }« osebno ali po telefonu prosite, naj vam iz svojega programa prebere prstni odtis ključa. Ne primerjajte ga s prstnim odtisom, poslanim po e-pošti: kdor lahko zamenja ključ, lahko zamenja tudi poslani prstni odtis.
ui-verify-fingerprint = Prstni odtis ključa, ki ga imate:
ui-verify-marks = { $count ->
    [0] Ta ključ ne vsebuje e-poštnih naslovov, zato potrditve lastnika ni mogoče shraniti.
    [1] Če se prstna odtisa ujemata, potrdite, da ključ pripada osebi, ki uporablja naslov { $addresses }. Če naslov ni njen, kliknite Se ne ujemata.
   *[other] Če se prstna odtisa ujemata, potrdite, da ključ pripada osebi, ki uporablja naslove: { $addresses }. Če kateri od naslovov ni njen, kliknite Se ne ujemata.
}
ui-verify-match = Se &ujemata
ui-verify-differ = Se &ne ujemata
ui-verify-differs = Prstni odtis shranjenega ključa »{ $name }« se ne ujema. Odstranite ga in lastnika znova prosite za ključ.
ui-verify-unmark = &Prekliči potrditev lastnika
ui-account-security = Varnost
ui-account-security-intro = S ključem lahko podpisujete svoja sporočila, drugi pa vam lahko pošiljajo šifrirano pošto.
ui-account-key = &Ključ za ta račun:
ui-account-key-none = Brez
ui-account-key-new = &Nov ključ...
ui-account-autocrypt = &Pošiljaj moj javni ključ s sporočili (Autocrypt)
ui-contact-key = Šifrirni ključ:
ui-contact-key-none = Ni ključa
ui-contact-key-use-new = Uporabi &novi ključ
ui-contact-key-keep = Obdrži &trenutnega
ui-recipient-keys-title = Ključi prejemnikov
ui-recipient-col-recipient = Prejemnik
ui-recipient-col-key = Ključ
ui-recipient-find-key = Najdi &ključ
ui-recipient-remove = Odstrani iz &sporočila
ui-send-unencrypted = Pošlji &brez šifriranja
ui-compose-make-key = &Ustvari ključ...
ui-compose-show-keys = Šifrirni &ključi...
ui-compose-encrypt-off = &Izklopi šifriranje
ui-compose-keep-encrypted = &Ohrani šifriranje
ui-setup-export-title = Izvozi nastavitve in račune
ui-setup-import-title = Uvozi nastavitve in račune
ui-setup-export-intro = Izberite, kaj želite prenesti v drug računalnik. Datoteka ne vsebuje sporočil. V drugem računalniku boste lahko znova prenesli le sporočila, ki so shranjena na strežniku.
ui-setup-use-passphrase = Zaš&čiti datoteko z zaščitnim geslom
ui-setup-passphrase-note = Z zaščitnim geslom je datoteka šifrirana in lahko vsebuje dostopna shranjena gesla, prijavne podatke ter zasebne ključe iz izbranih kategorij. Brez njega se boste morali v račune v drugem računalniku znova prijaviti.
ui-setup-export-button = &Izvozi...
ui-setup-file-filter = Nastavitve in računi Inbox Classic
ui-setup-ask-passphrase = Ta datoteka je zaščitena z zaščitnim geslom. Vnesite ga, da vidite, kaj datoteka vsebuje:
ui-setup-import-intro = Izberite, kaj želite uvoziti. Računi, ki so že v tem računalniku, ostanejo nespremenjeni.
ui-setup-from = Shranjeno s programom Inbox Classic { $version }. Datum: { $date }.
ui-setup-import-button = &Uvozi
ui-setup-done = Končano
ui-setup-first-run = Uvozi nastavitve in račune iz drugega računalnika...

ui-field-verifiers = Zaupanja vredni viri preverjanja pošiljatelja:
ui-attachment-import-key = Uvozi ključ...
ui-book-key-known = Ima šifrirni ključ
ui-book-key-verified = Ima šifrirni ključ s potrjenim lastnikom
ui-keys-publish = Ob&javi...
ui-keys-publish-ask = Želite objaviti svoj javni ključ na keys.openpgp.org, da ga bodo drugi lahko našli? Naslovi v ključu: { $addresses }. Vsak naslov je treba pred uvrstitvijo v imenik potrditi s povezavo, poslano na ta naslov.
ui-keys-publish-now = Objavi
ui-keys-paste = Uvozi iz odlo&žišča
ui-keys-paste-none = Odložišče ne vsebuje ključa OpenPGP.
ui-contact-find-key = Najdi &ključ
