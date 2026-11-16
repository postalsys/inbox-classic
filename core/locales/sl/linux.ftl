# Slovenščina. Osnutek, čaka na pregled naravnega govorca (glej core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-; an _ marks a button's mnemonic letter.

## The main window

# review: new
gtk-search-looks-in = Iskanje v { $place } zajema zadeve, pošiljatelje, prejemnike, imena priponk in besedilo sporočil. Preverite črkovanje ali poskusite z manj besedami.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Besedilo { $count } sporočila se še indeksira. Kmalu se lahko pojavi več rezultatov.
   *[other] Besedilo { $count } sporočil se še indeksira. Kmalu se lahko pojavi več rezultatov.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Ni rezultatov
    [one] { $count } rezultat
    [two] { $count } rezultata
    [few] { $count } rezultati
   *[other] { $count } rezultatov
} za »{ $words }« v vseh mapah
# review: new
gtk-search-results-in = { $count ->
    [0] Ni rezultatov
    [one] { $count } rezultat
    [two] { $count } rezultata
    [few] { $count } rezultati
   *[other] { $count } rezultatov
} za »{ $words }« v { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] besedilo { $count } sporočila se še indeksira
   *[other] besedilo { $count } sporočil se še indeksira
}
gtk-list-loading = Nalaganje...
# review: new
gtk-menu-rename = Preimenuj...
# review: new
gtk-import-one-question = Želite uvoziti sporočilo { $file } v { $folder }?
# review: new
gtk-files-not-saved = Ni bilo mogoče shraniti { $failed } od { $total } datotek.
# review: new
gtk-unsubscribe-one-click =
    Se želite odjaviti s tega poštnega seznama?

    Inbox Classic bo poslal zahtevo za odjavo na { $target }. Nobena spletna stran se ne bo odprla in nobeno e-poštno sporočilo ne bo poslano.
# review: new
gtk-unsubscribe-mail =
    Se želite odjaviti s tega poštnega seznama?

    Za odjavo pošljite e-poštno sporočilo na { $target }. Inbox Classic ga bo pripravil namesto vas. Pošljite sporočilo, da potrdite.
# review: new
gtk-unsubscribe-web =
    Se želite odjaviti s tega poštnega seznama?

    Stran za odjavo s poštnega seznama se bo odprla v brskalniku ({ $target }).
# review: new
gtk-unsubscribe-failed = Odjava ni uspela: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Piši iz določenega računa
# review: new
gtk-toolbar-send-recv-menu = Pošlji in prejmi pošto za določen račun
# review: new
gtk-main-menu = Glavni meni
# review: new
gtk-folder-list = Seznam map
# review: new
gtk-quit = Končaj

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Nova mapa bo na najvišji ravni računa { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Ni neprebranih sporočil
    [one] { $count } neprebrano sporočilo
    [two] { $count } neprebrani sporočili
    [few] { $count } neprebrana sporočila
   *[other] { $count } neprebranih sporočil
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Nobeno sporočilo ne čaka na pošiljanje.
# review: new
gtk-outbox-row = Za: { $to }  ·  V vrsti od { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic v ozadju še naprej preverja novo pošto. Z ikono v zgornji vrstici odprete ali končate program.
# review: new
gtk-sign-in-again-ask =
    Prijava v { $account } je bila zavrnjena ali pa je seja potekla.

    Se želite znova prijaviti v brskalniku?
# review: new
gtk-default-app-not-installed = Ta kopija programa Inbox Classic ni bila nameščena, zato je sistem ne navaja kot poštni program. Namestite jo, da jo lahko izberete.
# review: new
gtk-default-app-now = Inbox Classic je zdaj vaš privzeti poštni program: e-poštne povezave tukaj odprejo novo sporočilo.
# review: new
gtk-default-app-failed = Inbox Classic ni bilo mogoče nastaviti kot privzeti poštni program.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Datum:
# review: new
gtk-reader-files = Priponke sporočila
# review: new
gtk-files = { $count ->
    [one] { $count } datoteka
    [two] { $count } datoteki
    [few] { $count } datoteke
   *[other] { $count } datotek
}
# review: new
gtk-pictures-blocked = Nekatere slike so bile blokirane, da pošiljatelj ne bi mogel prepoznati vašega računalnika.
# review: new
gtk-download-pictures = Prenesi slike
# review: new
gtk-save-attachments-menu = Shrani priponke...

## The compose window

# review: new
gtk-format-bold = Krepko (Ctrl+B)
# review: new
gtk-format-italic = Ležeče (Ctrl+I)
# review: new
gtk-format-underline = Podčrtano (Ctrl+U)
# review: new
gtk-format-hyperlink = Hiperpovezava (Ctrl+K)
# review: new
gtk-font = Pisava
# review: new
gtk-show-cc = _Kp
# review: new
gtk-show-bcc = _Skp
# review: new
gtk-save-tip = Shrani (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl + klik za odpiranje)

## Accounts

# review: new
gtk-plain-warning =
    Brez šifriranja lahko vsakdo, ki prestreže vaš omrežni promet, prebere vaše geslo in sporočila. To povezavo uporabljajte samo s strežnikom v svojem računalniku ali lokalnem omrežju.

    Želite nadaljevati?
# review: new
gtk-account-name-title = Ime računa
# review: new
gtk-display-name-title = Prikazno ime
# review: new
gtk-turned-off-why = Možnost »{ $button }« je v tem računalniku onemogočena. { $reason }
# review: new
gtk-turned-off-why-long =
    Možnost »{ $button }« je v tem računalniku onemogočena.

    { $reason }
# review: new
gtk-next = Naprej >
# review: new
gtk-provider-sign-in = Prijavite se v { $address } na spletni strani ponudnika ({ $provider }). Vaše geslo ni deljeno z Inbox Classic. Uporabite lahko tudi geslo za aplikacije, ustvarjeno v varnostnih nastavitvah računa.
# review: new
gtk-provider-sign-in-apps = Prijavite se v { $address } na spletni strani ponudnika ({ $provider }) z eno od svojih aplikacij za prijavo (Več možnosti prijave). Uporabite lahko tudi geslo za aplikacije, ustvarjeno v varnostnih nastavitvah računa.
# review: new
gtk-accounts-add = Dodaj...
# review: new
gtk-accounts-properties = Lastnosti...
# review: new
gtk-accounts-signature = Podpis...
# review: new
gtk-accounts-sign-in-apps = Aplikacije za prijavo...

## Sign-in apps

# review: new
gtk-app-server = Strežnik { $kind }
# review: new
gtk-app-port = Vrata { $kind }
# review: new
gtk-app-security = Varnost { $kind }
# review: new
gtk-issuer-found =
    Stran za prijavo: { $page }
    Končna točka za žetone: { $endpoint }
# review: new
gtk-client-id = ID odjemalca
# review: new
gtk-client-secret = Skrivnost odjemalca
# review: new
gtk-scopes = Dovoljenja (scopes)
# review: new
gtk-redirect-uri = Preusmeritveni URI
# review: new
gtk-issuer-usable =
    Izdajatelja je mogoče uporabiti.

    { $found }
# review: new
gtk-app-built-in = { $app } je vgrajena. Spremenite lahko samo, ali je na voljo za nove račune. { $reason }
# review: new
gtk-built-in = { $app } (vgrajena)
# review: new
gtk-offered-for-new = Na voljo za nove račune
# review: new
gtk-edit-button = Uredi...
# review: new
gtk-remove-app-ask = Želite odstraniti aplikacijo za prijavo { $app } in njeno shranjeno skrivnost odjemalca?
# review: new
gtk-sign-in-apps-intro = Z aplikacijami za prijavo se računi prijavljajo prek brskalnika. Izklopljena aplikacija ni na voljo za nove račune; računi, ki jo že uporabljajo, delujejo naprej.

## AI agents

# review: new
gtk-agent-it-may = Dovoljena dejanja
# review: new
gtk-agent-accounts = Dovoljeni računi
# review: new
gtk-never-used = Še ni bil uporabljen
# review: new
gtk-last-used = Nazadnje uporabljen { $date }
# review: new
gtk-forget-program = Želite odstraniti ta program?
# review: new
gtk-forget-program-detail = Dovoljenja programa in zgodovina dejavnosti njegovih agentov bodo izbrisani. Ko se bo naslednjič povezal, boste znova vprašani za dovoljenje.
# review: new
gtk-no-agents-yet = Noben agent še ni zaprosil za uporabo vaše pošte.
# review: new
gtk-nothing-yet = Še nič.

## Preferences

# review: new
gtk-preferences = Nastavitve
# review: new
gtk-language = Jezik
# review: new
gtk-language-subtitle = Jezik programa in pomoči
# review: new
gtk-new-mail-group = Nova pošta
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Obvesti o novi pošti
# review: new
gtk-notify-subtitle = Obvestilo, ko prispejo nova sporočila, medtem ko je okno v ozadju
# review: new
gtk-restart-to-change = Inbox Classic se za spremembo jezika znova zažene.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords: each ended by a
# semicolon, in your language only
# review: new
gtk-desktop-generic-name = Poštni odjemalec
# review: new
gtk-desktop-comment = Branje in pisanje e-pošte: hiter, preprost poštni program
# review: new
gtk-desktop-keywords = pošta;e-pošta;sporočila;prejeto;elektronska pošta;
# review: new
gtk-metainfo-summary = Hiter, preprost poštni program
# review: new
gtk-metainfo-description = Inbox Classic bere in piše e-pošto z mapami na levi, sporočili zgoraj in sporočilom spodaj, kot so to nekoč počeli poštni programi. Deluje s katerim koli računom IMAP in SMTP ter se v Outlook.com in Microsoft 365 prijavi prek brskalnika.
# review: new
gtk-metainfo-feature-sanitized = Vsako sporočilo je prikazano prečiščeno, brez skriptov, slike z interneta pa samo, če jih dovolite
# review: new
gtk-metainfo-feature-search = Iskanje, ki najde besede v zadevi, osebah, imenih datotek in besedilu, z Gmailovimi operatorji
# review: new
gtk-metainfo-feature-replies = Odgovori skrijejo starejša sporočila, ki jih navajajo
# review: new
gtk-metainfo-feature-offline = Pošta je berljiva tudi brez povezave; gesla so shranjena v vaši shrambi ključev
