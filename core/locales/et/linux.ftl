# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = Asukohas { $place } otsitakse kirjade teemast, saatjate ja saajate nimedest ja aadressidest, manuste nimedest ning kirjade sisust. Kontrollige õigekirja või proovige vähemate sõnadega.
gtk-search-still-indexing = { $count ->
   *[other] { $count } kirja sisu veel indekseeritakse. Otsingutulemusi võib lisanduda.
}
gtk-search-results-everywhere = { $count ->
    [0] Tulemusi pole
    [one] { $count } tulemus
   *[other] { $count } tulemust
} päringule „{ $words }“ kõigis kaustades
gtk-search-results-in = { $count ->
    [0] Tulemusi pole
    [one] { $count } tulemus
   *[other] { $count } tulemust
} päringule „{ $words }“ asukohas { $place }
gtk-search-indexing = { $count ->
    [one] { $count } kirja teksti indekseeritakse veel
   *[other] { $count } kirja teksti indekseeritakse veel
}
gtk-menu-rename = Nimeta ümber...
gtk-import-one-question = Kas importida kiri { $file } kausta { $folder }?
gtk-files-not-saved = { $total } failist { $failed } ei õnnestunud salvestada.
gtk-unsubscribe-one-click =
    Kas lahkuda sellest meililistist?

    Inbox Classic saadab aadressile { $target } tellimusest loobumise taotluse. Veebilehte ei avata ega e-kirja ei saadeta.
gtk-unsubscribe-mail =
    Kas lahkuda sellest meililistist?

    Tellimusest loobumiseks tuleb saata kiri aadressile { $target }. Inbox Classic koostab kirja teie eest. Loobumise kinnitamiseks saatke see ära.
gtk-unsubscribe-web =
    Kas lahkuda sellest meililistist?

    Brauseris avaneb tellimusest loobumise leht ({ $target }).
gtk-unsubscribe-failed = Tellimusest ei õnnestunud loobuda: { $problem }
gtk-toolbar-create-mail-menu = Koosta kiri valitud kontolt
gtk-toolbar-send-recv-menu = Saada ja võta vastu valitud konto kirjad
gtk-main-menu = Peamenüü
gtk-quit = Lõpeta

## The Move and Copy window

gtk-new-folder-at-top-of = Uus kaust luuakse konto { $account } juurkausta.

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

gtk-outbox-empty = Saatmist ootavaid kirju pole.
gtk-outbox-row = Saaja: { $to }  ·  Lisatud järjekorda: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic kontrollib taustal uute kirjade saabumist. Rakenduse avamiseks või sulgemiseks kasutage ülaribal olevat ikooni.
gtk-sign-in-again-ask =
    Konto { $account } sisselogimine ebaõnnestus või seanss aegus.

    Kas logida brauseris uuesti sisse?
gtk-default-app-not-installed = Inbox Classic pole paigaldatud, mistõttu ei kuvata seda süsteemi meilirakenduste loendis. Vaikerakenduseks valimiseks paigaldage Inbox Classic.
gtk-default-app-now = Inbox Classic on nüüd teie vaikimisi meilirakendus: e-posti lingid avavad siin uue kirja.
gtk-default-app-failed = Inbox Classicut ei õnnestunud vaikimisi meilirakenduseks määrata.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Kuupäev:
gtk-reader-files = Kirja manused
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

gtk-format-bold = Paks kiri (Ctrl+B)
gtk-format-italic = Kaldkiri (Ctrl+I)
gtk-format-underline = Allajoonitud (Ctrl+U)
gtk-format-hyperlink = Hüperlink (Ctrl+K)
gtk-font = Font
gtk-show-cc = _Koopia
gtk-show-bcc = _Pimekoopia
gtk-save-tip = Salvesta (Ctrl+S)
gtk-link-status = { $link }    (avamiseks Ctrl+klõps)

## Accounts

gtk-plain-warning =
    Krüptimata ühenduse korral saavad võrguliiklust jälgivad isikud lugeda teie parooli ja kirju. Kasutage seda ainult oma arvutis või kohalikus võrgus oleva serveriga.

    Kas jätkata?
gtk-display-name-title = Kuvatav nimi
gtk-turned-off-why = Valik „{ $button }“ on selles arvutis välja lülitatud. { $reason }
gtk-turned-off-why-long =
    Valik „{ $button }“ on selles arvutis välja lülitatud.

    { $reason }
gtk-next = Edasi >
gtk-provider-sign-in = Kontole { $address } saate sisse logida teenusepakkuja { $provider } veebilehel. Inbox Classic teie parooli ei näe. Teise võimalusena kasutage konto turvasätetes loodud rakenduse parooli.
gtk-provider-sign-in-apps = Kontole { $address } saate sisse logida teenusepakkuja { $provider } veebilehel mõne oma sisselogimisrakendusega („Muud sisselogimisviisid“). Teise võimalusena kasutage konto turvasätetes loodud rakenduse parooli.
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
    Juurdepääsutõendi lõpp-punkt: { $endpoint }
gtk-client-id = Kliendi ID
gtk-client-secret = Kliendi saladus
gtk-scopes = Juurdepääsuõigused (scopes)
gtk-redirect-uri = Ümbersuunamise URI
gtk-issuer-usable =
    Väljaandjat saab kasutada.

    { $found }
gtk-app-built-in = { $app } on sisseehitatud: muuta saab ainult seda, kas seda uute kontode jaoks kasutatakse. { $reason }
gtk-built-in = { $app } (sisseehitatud)
gtk-offered-for-new = Pakutakse uutele kontodele
gtk-edit-button = Muuda...
gtk-remove-app-ask = Kas eemaldada sisselogimisrakendus { $app } ja selle salvestatud kliendi saladus?
gtk-sign-in-apps-intro = Sisselogimisrakendused võimaldavad kontodele brauseris sisse logida. Väljalülitatud rakendusi uutele kontodele ei pakuta. Olemasolevad kontod saavad neid endiselt kasutada.

## AI agents

gtk-agent-it-may = Lubatud tegevused
gtk-agent-accounts = Lubatud kontod
gtk-never-used = Pole kasutatud
gtk-last-used = Viimati kasutatud { $date }
gtk-forget-program = Kas eemaldada see programm?
gtk-forget-program-detail = Programmi õigused ja agentide tegevusajalugu kustutatakse. Järgmisel ühendumisel küsitakse juurdepääsuluba uuesti.
gtk-no-agents-yet = Ükski agent pole veel taotlenud juurdepääsu teie e-postile.
gtk-nothing-yet = Veel mitte midagi.

## Preferences

gtk-preferences = Eelistused
gtk-language = Keel
gtk-language-subtitle = Rakenduse ja spikri keel
gtk-new-mail-group = Uus post
gtk-notify-subtitle = Teade, kui uusi kirju saabub ajal, mil aken on taustal
gtk-restart-to-change = Inbox Classic taaskäivitub, et keelt muuta.
