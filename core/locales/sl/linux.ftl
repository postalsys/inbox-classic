# Slovenščina. Osnutek, čaka na pregled naravnega govorca (glej core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-; an _ marks a button's mnemonic letter.

## The main window

gtk-search-looks-in = Iskanje v pogledu »{ $place }« zajema zadeve, imena in naslove pošiljateljev ter prejemnikov, imena priponk in besedilo sporočil. Preverite črkovanje ali poskusite z manj besedami.
gtk-search-still-indexing = { $count ->
    [one] Besedilo { $count } sporočila se še indeksira. Kmalu se lahko pojavi več rezultatov.
   *[other] Besedilo { $count } sporočil se še indeksira. Kmalu se lahko pojavi več rezultatov.
}
gtk-search-results-everywhere = { $count ->
    [0] Ni rezultatov
    [one] { $count } rezultat
    [two] { $count } rezultata
    [few] { $count } rezultati
   *[other] { $count } rezultatov
} za »{ $words }« v vseh mapah
gtk-search-results-in = { $count ->
    [0] Ni rezultatov
    [one] { $count } rezultat
    [two] { $count } rezultata
    [few] { $count } rezultati
   *[other] { $count } rezultatov
} za »{ $words }« v { $place }
gtk-search-indexing = { $count ->
    [one] besedilo { $count } sporočila se še indeksira
   *[other] besedilo { $count } sporočil se še indeksira
}
gtk-list-loading = Nalaganje...
gtk-menu-rename = Preimenuj...
gtk-import-one-question = Želite sporočilo iz datoteke »{ $file }« uvoziti v mapo »{ $folder }«?
gtk-files-not-saved = Datoteke, ki jih ni bilo mogoče shraniti: { $failed }; skupaj: { $total }.
gtk-unsubscribe-one-click = Se želite odjaviti s tega poštnega seznama?

    Inbox Classic bo strežniku { $target } poslal zahtevo za odjavo. Pri tem ne bo odprl spletne strani ali poslal e-poštnega sporočila.
gtk-unsubscribe-mail = Se želite odjaviti s tega poštnega seznama?

    Za odjavo pošljite e-poštno sporočilo na naslov { $target }. Inbox Classic ga bo pripravil za vas. Odjavo potrdite s pošiljanjem sporočila.
gtk-unsubscribe-web =
    Se želite odjaviti s tega poštnega seznama?

    Stran za odjavo s poštnega seznama se bo odprla v brskalniku ({ $target }).
gtk-unsubscribe-failed = Odjava ni uspela: { $problem }
gtk-toolbar-create-mail-menu = Piši iz določenega računa
gtk-toolbar-send-recv-menu = Pošlji in prejmi pošto za določen račun
gtk-main-menu = Glavni meni
gtk-folder-list = Seznam map
gtk-quit = Končaj

## The Move and Copy window

gtk-new-folder-at-top-of = Nova mapa bo na najvišji ravni računa »{ $account }«.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Ni neprebranih sporočil
    [one] { $count } neprebrano sporočilo
    [two] { $count } neprebrani sporočili
    [few] { $count } neprebrana sporočila
   *[other] { $count } neprebranih sporočil
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Nobeno sporočilo ne čaka na pošiljanje.
gtk-outbox-row = Za: { $to }  ·  V čakalni vrsti od { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic v ozadju še naprej preverja novo pošto. Z ikono v zgornji vrstici odprete ali končate program.
gtk-sign-in-again-ask = Prijava v račun »{ $account }« je bila zavrnjena ali pa je seja potekla.

    Se želite znova prijaviti v brskalniku?
gtk-default-app-not-installed = Ta kopija programa Inbox Classic ni bila nameščena, zato je sistem ne navaja kot poštni program. Namestite jo, da jo lahko izberete.
gtk-default-app-now = Inbox Classic je zdaj vaš privzeti poštni program: e-poštne povezave tukaj odprejo novo sporočilo.
gtk-default-app-failed = Inbox Classic ni bilo mogoče nastaviti kot privzeti poštni program.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Datum:
gtk-reader-files = Priponke sporočila
gtk-files = { $count ->
    [one] { $count } datoteka
    [two] { $count } datoteki
    [few] { $count } datoteke
   *[other] { $count } datotek
}
gtk-save-attachments-menu = Shrani priponke...

## The compose window

gtk-format-bold = Krepko (Ctrl+B)
gtk-format-italic = Ležeče (Ctrl+I)
gtk-format-underline = Podčrtano (Ctrl+U)
gtk-format-hyperlink = Hiperpovezava (Ctrl+K)
gtk-font = Pisava
gtk-show-cc = _Kp
gtk-show-bcc = _Skp
gtk-save-tip = Shrani (Ctrl+S)
gtk-link-status = { $link }    (Ctrl + klik za odpiranje)

## Accounts

gtk-plain-warning =
    Brez šifriranja lahko vsakdo, ki prestreže omrežni promet, prebere vaše geslo in sporočila. Tudi lokalno omrežje samo po sebi ne zaščiti povezave. Nadaljujte le, če je povezava zaščitena na drug način.

    Želite nadaljevati?
gtk-account-name-title = Ime računa
gtk-display-name-title = Prikazno ime
gtk-turned-off-why = Možnost »{ $button }« je v tem računalniku onemogočena. { $reason }
gtk-turned-off-why-long =
    Možnost »{ $button }« je v tem računalniku onemogočena.

    { $reason }
gtk-next = Naprej >
gtk-provider-sign-in = Na spletni strani ponudnika ({ $provider }) se prijavite v račun »{ $address }«. Inbox Classic ne prejme vašega gesla. Če račun podpira gesla za aplikacije, lahko uporabite geslo, ustvarjeno v njegovih varnostnih nastavitvah. Outlook.com in Microsoft 365 podpirata samo prijavo prek brskalnika.
gtk-provider-sign-in-apps = Na spletni strani ponudnika ({ $provider }) se prijavite v račun »{ $address }« z eno od svojih aplikacij za prijavo (Več možnosti prijave). Če račun podpira gesla za aplikacije, lahko uporabite geslo, ustvarjeno v njegovih varnostnih nastavitvah. Outlook.com in Microsoft 365 podpirata samo prijavo prek brskalnika.
gtk-accounts-add = Dodaj...
gtk-accounts-properties = Lastnosti...
gtk-accounts-signature = Besedilo podpisa...
gtk-accounts-sign-in-apps = Aplikacije za prijavo...

## Sign-in apps

gtk-app-server = Strežnik { $kind }
gtk-app-port = Vrata { $kind }
gtk-app-security = Varnost { $kind }
gtk-issuer-found =
    Stran za prijavo: { $page }
    Končna točka za žetone: { $endpoint }
gtk-client-id = ID odjemalca
gtk-client-secret = Skrivnost odjemalca
gtk-scopes = Dovoljenja (scopes)
gtk-redirect-uri = Preusmeritveni URI
gtk-issuer-usable =
    Izdajatelja je mogoče uporabiti.

    { $found }
gtk-app-built-in = Aplikacija »{ $app }« je vgrajena. Spremenite lahko samo, ali je na voljo za nove račune. { $reason }
gtk-built-in = { $app } (vgrajena)
gtk-offered-for-new = Na voljo za nove račune
gtk-edit-button = Uredi...
gtk-remove-app-ask = Želite odstraniti aplikacijo za prijavo »{ $app }« in njeno shranjeno skrivnost odjemalca?
gtk-sign-in-apps-intro = Z aplikacijami za prijavo se računi prijavljajo prek brskalnika. Izklopljena aplikacija ni na voljo za nove račune; računi, ki jo že uporabljajo, delujejo naprej.

## AI agents

gtk-agent-it-may = Dovoljena dejanja
gtk-agent-accounts = Dovoljeni računi
gtk-never-used = Še brez dostopa
gtk-last-used = Zadnji dostop: { $date }
gtk-forget-program = Želite odstraniti dostop tega programa?
gtk-forget-program-detail = Dovoljenja programa in zgodovina dejavnosti njegovih agentov bodo izbrisani. Ob naslednji povezavi bo program znova zahteval dovoljenje. S tem se program ne odstrani iz računalnika.
gtk-no-agents-yet = Noben agent še ni zaprosil za uporabo vaše pošte.
gtk-nothing-yet = Še nič.

## Preferences

gtk-preferences = Nastavitve
gtk-notify-subtitle = Samo ko glavno okno ni v ospredju

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords: each ended by a
# semicolon, in your language only
gtk-desktop-generic-name = Poštni odjemalec
gtk-desktop-comment = Branje in pisanje e-pošte: hiter, preprost poštni program
gtk-desktop-keywords = pošta;e-pošta;sporočila;prejeto;elektronska pošta;
gtk-metainfo-summary = Hiter, preprost poštni program
gtk-metainfo-description = Inbox Classic je poštni program s klasično razporeditvijo: mape na levi, seznam sporočil zgoraj in izbrano sporočilo spodaj. Povezuje se z računi IMAP in SMTP ter za Outlook.com in Microsoft 365 uporablja prijavo prek brskalnika.
gtk-metainfo-feature-sanitized = Sporočila se prikažejo brez skriptov in drugih aktivnih elementov, slike z interneta pa se naložijo le z vašim dovoljenjem
gtk-metainfo-feature-search = Iskanje po zadevah, imenih in naslovih pošiljateljev ter prejemnikov, imenih datotek in besedilu sporočil, z iskalnimi operatorji kot v Gmailu
gtk-metainfo-feature-replies = V odgovorih so citirana starejša sporočila zložena
gtk-metainfo-feature-offline = Pošto lahko berete brez povezave, dokler je shranjena lokalna kopija; prijavni podatki se običajno hranijo v sistemski shrambi ključev, če je na voljo
