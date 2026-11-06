# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = Otsing vaatab kirjade teemat, inimesi, failinimesid ja teksti asukohas { $place }. Kontrollige õigekirja või proovige vähemate sõnadega.
gtk-search-still-indexing = { $count ->
    [one] { $count } kirja teksti indekseeritakse veel, nii et peagi võib leiduda rohkem.
   *[other] { $count } kirja teksti indekseeritakse veel, nii et peagi võib leiduda rohkem.
}
gtk-search-results-everywhere = { $count ->
    [0] Tulemusi pole
    [one] { $count } tulemus
   *[other] { $count } tulemust
} päringule „{ $words }” kõigis kaustades
gtk-search-results-in = { $count ->
    [0] Tulemusi pole
    [one] { $count } tulemus
   *[other] { $count } tulemust
} päringule „{ $words }” asukohas { $place }
gtk-search-indexing = { $count ->
    [one] { $count } kirja teksti indekseeritakse veel
   *[other] { $count } kirja teksti indekseeritakse veel
}
gtk-menu-rename = Nimeta ümber...
gtk-import-one-question = Kas panna kiri { $file } kausta { $folder }?
gtk-files-not-saved = { $total } failist { $failed } ei õnnestunud salvestada.
gtk-unsubscribe-one-click =
    Kas lahkuda sellest postiloendist?

    Inbox Classic palub aadressil { $target } teile enam mitte saata. Ühtki lehte ei avata ja ühtki kirja ei saadeta.
gtk-unsubscribe-mail =
    Kas lahkuda sellest postiloendist?

    Loend soovib kirja aadressile { $target }. Inbox Classic kirjutab selle teie eest; loobumiseks saatke see ära.
gtk-unsubscribe-web =
    Kas lahkuda sellest postiloendist?

    Loendi vastav leht avaneb teie brauseris ({ $target }).
gtk-unsubscribe-failed = Tellimusest ei õnnestunud loobuda: { $problem }
gtk-toolbar-create-mail-menu = Kiri ühelt kontolt
gtk-toolbar-send-recv-menu = Saada ja võta vastu üks konto
gtk-main-menu = Peamenüü
gtk-quit = Lõpeta

## The Move and Copy window

gtk-new-folder-at-top-of = Uus kaust luuakse konto { $account } ülemisele tasemele.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Lugemata kirju pole
    [one] { $count } lugemata kiri
   *[other] { $count } lugemata kirja
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Midagi ei oota saatmist.
gtk-outbox-row = Saaja: { $to }  ·  Järjekorras { $queued }  ·  { $status }

## The app

gtk-new-messages = { $count } uut kirja
gtk-still-running-detail = See kontrollib edasi uut posti. Selle ikoon ülemisel ribal avab selle uuesti või lõpetab selle töö.
gtk-sign-in-again-ask =
    Konto { $account } sisselogimine lükati tagasi või aegus.

    Kas logida brauseris uuesti sisse?
gtk-default-app-not-installed = Seda Inbox Classicu koopiat ei paigaldatud, seega ei näita süsteem seda meilirakendusena. Paigaldage see, et seda valida.
gtk-default-app-now = Inbox Classic on nüüd teie vaikimisi meilirakendus: e-posti lingid avavad siin uue kirja.
gtk-default-app-failed = Inbox Classicut ei õnnestunud vaikimisi meilirakenduseks teha.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Kuupäev:
gtk-reader-files = Kirja failid
gtk-pictures-blocked = Mõned pildid blokeeriti, et saatja ei saaks teie arvutit tuvastada.
gtk-download-pictures = Laadi pildid alla
gtk-save-attachments-menu = Salvesta manused...
gtk-invitation = { $kind ->
    [update] Muudetud kutse: { $summary }
    [cancel] Tühistatud: { $summary }
    [reply] Vastus kutsele: { $summary }
   *[request] Kutse: { $summary }
}
gtk-organizer = Korraldaja: { $organizer }
gtk-attendees = { $count ->
    [one] { $count } osaleja
   *[other] { $count } osalejat
}
gtk-day-and-time = { $day }, { $time }

## The compose window

gtk-format-bold = Paks (Ctrl+B)
gtk-format-italic = Kaldkiri (Ctrl+I)
gtk-format-underline = Allakriipsutus (Ctrl+U)
gtk-format-hyperlink = Hüperlink (Ctrl+K)
gtk-font = Font
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Salvesta (Ctrl+S)
gtk-link-status = { $link }    (avamiseks Ctrl+klõps)

## Accounts

gtk-plain-warning =
    Krüptimata liiguvad teie parool ja post võrgus loetavana kõigile, kes on teel. Kasutage seda ainult oma arvutis või võrgus oleva serveri puhul.

    Kas jätkata?
gtk-display-name-title = Kuvatav nimi
gtk-turned-off-why = { $button } on selles arvutis välja lülitatud. { $reason }
gtk-turned-off-why-long =
    { $button } on selles arvutis välja lülitatud.

    { $reason }
gtk-next = Edasi >
gtk-provider-sign-in = { $address } logib sisse teenusepakkuja { $provider } enda lehel, ilma et Inbox Classic teie parooli saaks. Või kasutage oma konto turvasätetes loodud rakenduse parooli.
gtk-provider-sign-in-apps = { $address } saab sisse logida teenusepakkuja { $provider } enda lehel mõne teie sisselogimisrakendusega (Veel sisselogimisvõimalusi). Või kasutage oma konto turvasätetes loodud rakenduse parooli.
gtk-accounts-add = Lisa...
gtk-accounts-properties = Atribuudid...
gtk-accounts-signature = Allkiri...
gtk-accounts-sign-in-apps = Sisselogimisrakendused...

## Sign-in apps

gtk-app-server = { $kind }-server
gtk-app-port = { $kind }-port
gtk-app-security = { $kind }-turve
gtk-issuer-found =
    Sisselogimisleht: { $page }
    Tõendi otspunkt: { $endpoint }
gtk-client-id = Kliendi ID
gtk-client-secret = Kliendi saladus
gtk-scopes = Ulatused (scopes)
gtk-redirect-uri = Ümbersuunamise URI
gtk-issuer-usable =
    Väljaandjat saab kasutada.

    { $found }
gtk-app-built-in = { $app } on sisseehitatud: muuta saab ainult seda, kas seda uute kontode jaoks kasutatakse. { $reason }
gtk-built-in = { $app } (sisseehitatud)
gtk-offered-for-new = Pakutakse uutele kontodele
gtk-edit-button = Muuda...
gtk-remove-app-ask = Kas eemaldada sisselogimisrakendus { $app } ja selle salvestatud kliendi saladus?
gtk-sign-in-apps-intro = Sisselogimisrakendused lasevad kontodel brauseri kaudu sisse logida. Väljalülitatut ei pakuta uutele kontodele; kontod, mis seda juba kasutavad, töötavad edasi.

## AI agents

gtk-agent-it-may = See võib
gtk-agent-accounts = Kontod, mida see võib kasutada
gtk-never-used = Pole kasutatud
gtk-last-used = Viimati kasutatud { $date }
gtk-forget-program = Kas unustada see programm?
gtk-forget-program-detail = Järgmisel ühendumisel küsitakse uuesti ja see, mida selle agendid tegid, unustatakse.
gtk-no-agents-yet = Ükski agent pole veel teie posti kasutada palunud.
gtk-nothing-yet = Veel mitte midagi.

## Preferences

gtk-preferences = Eelistused
gtk-language = Keel
gtk-language-subtitle = Akende ja abi sõnad
gtk-new-mail-group = Uus post
gtk-notify-subtitle = Teade, kui uusi kirju saabub ajal, mil aken on taustal
gtk-restart-to-change = Inbox Classic taaskäivitub, et keelt muuta.
