# Suomi. Luonnos, odottaa äidinkielisen tarkistusta (katso core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic tarkistaa taustalla, onko uutta postia saapunut. Avaa se napsauttamalla kuvaketta. Lopeta ohjelma napsauttamalla kuvaketta hiiren kakkospainikkeella ja valitsemalla Lopeta.
win-default-app-not-installed = Inbox Classicia käytetään ilman asennusta, joten Windows ei näytä sitä sähköpostisovellusten joukossa. Asenna ohjelma, jotta voit valita sen oletussovellukseksi.
win-default-app-settings = Windows avaa Oletussovellukset-asetukset. Valitse Inbox Classic avaamaan MAILTO-linkit.
win-no-unread = Ei lukemattomia viestejä
win-unread-messages = { $count ->
    [one] 1 lukematon viesti
   *[other] { $count } lukematonta viestiä
}
win-print-failed = Viestiä ei voitu tulostaa.
win-print-title-of = Tulosta - { $subject }
win-no-bodies = Viestien sisältöä ei voi näyttää.
win-webview-failed = WebView2:n luominen epäonnistui.
win-webview-missing = WebView2-suoritusympäristö ei ole käytettävissä.
win-list-loading = Ladataan...

## Buttons and words used in many windows

win-delete-button = &Poista
win-find-label = &Etsi:
win-save-as-button = Tallenna &nimellä...
win-too-many-files = Liian monta tiedostoa kerralla: valitse vähemmän.

## The Outbox


## The compose window

win-editor-failed = Viestejä ei voi kirjoittaa.
win-ctrl-click-to-open = (avaa pitämällä näppäintä { $ctrl } painettuna ja napsauttamalla)
win-format-bold = Lihavointi ({ $ctrl }+B)
win-format-italic = Kursivointi ({ $ctrl }+I)
win-format-underline = Alleviivaus ({ $ctrl }+U)
win-format-link = Hyperlinkki ({ $ctrl }+K)
win-show-cc = &Kopio
win-show-bcc = &Piilokopio
win-signature-title = Allekirjoitus: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Ei tuloksia haulla ”{ $words }” kaikista kansioista
    [one] { $count } tulos haulla ”{ $words }” kaikista kansioista
   *[other] { $count } tulosta haulla ”{ $words }” kaikista kansioista
}
win-search-found-in = { $count ->
    [0] Ei tuloksia haulla ”{ $words }” kansiosta { $folder }
    [one] { $count } tulos haulla ”{ $words }” kansiosta { $folder }
   *[other] { $count } tulosta haulla ”{ $words }” kansiosta { $folder }
}
win-search-indexing = { $count ->
    [one] { $count } viestin tekstiä indeksoidaan vielä
   *[other] { $count } viestin tekstiä indeksoidaan vielä
}
win-no-match-indexing = { $count ->
    [one] { $count } viestin tekstiä indeksoidaan vielä, joten tuloksia voi löytyä pian lisää.
   *[other] { $count } viestin tekstiä indeksoidaan vielä, joten tuloksia voi löytyä pian lisää.
}
win-files = { $count ->
    [one] { $count } tiedosto
   *[other] { $count } tiedostoa
}
win-click-to-retry = Yritä uudelleen napsauttamalla tätä.
win-save-attachments = &Tallenna liitteet...
win-files-not-saved = { $failed } tiedoston tallentaminen epäonnistui. Tiedostoja yhteensä: { $count }.
win-new-folder-in-highlighted = Uusi kansio luodaan valitun kansion sisään.
win-delete-folder-ask = Poistetaanko kansio ”{ $folder }” viesteineen ja sen sisältämine kansioineen? Se poistetaan myös palvelimelta.
win-rename = &Nimeä uudelleen...
win-messages-not-saved = Viestejä ei voitu tallentaa.
win-messages-not-forwarded = Viestejä ei voitu välittää edelleen.

## Accounts

win-sign-in-google = Kirjaudu Googlella
win-sign-in-microsoft = Kirjaudu Microsoftilla
win-next = &Seuraava >
win-your-account = tilisi
win-browser-sign-in = (kirjautuminen selaimessa)
win-add = &Lisää...
win-properties-button = &Ominaisuudet...
win-signature-button = &Allekirjoitus...
win-sign-in-apps-button = &Kirjautumissovellukset...

## AI agents

win-dont-allow = Ä&lä salli
win-col-address = Osoite
win-never-written-to = Ei aiempia lähetyksiä
win-book-find-label = Kirjoita nimi tai sähköpostiosoite:
win-send = &Lähetä
win-dont-send = Älä lä&hetä
# review: new
win-unsubscribe = &Peruuta tilaus
# review: new
win-dont-unsubscribe = Ä&lä peruuta tilausta
win-forget-program-ask = Poistetaanko tämä ohjelma, sen käyttöoikeudet ja sen agenttien toimintahistoria? Sinulta kysytään lupaa uudelleen, kun se seuraavan kerran muodostaa yhteyden.
win-clear-log-ask = Tyhjennetäänkö agenttien toimintahistoria? Tämä ei kumoa agenttien tekemiä muutoksia.
win-agent-programs = &Ohjelmat, joiden agentit ovat pyytäneet pääsyä postiisi:
win-change = &Muuta...
win-what-agents-did = Agenttien &toiminta:
win-how-to-connect = Agentin yhdistäminen

## Sign-in apps

win-built-in = (sisäänrakennettu)
win-edit = &Muokkaa...

## Options

win-folders-hide = Piilota kansioluettelo
win-folders-pin = Pidä kansioluettelo viestien vieressä
win-folders-show = Näytä kansiot

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Käynnistä Inbox Classic
win-installer-welcome-new = Asennetaan sähköpostiohjelma Inbox Classic { $version }.

    Järjestelmänvalvojan oikeuksia ei tarvita, sillä ohjelma asennetaan vain omalle Windows-käyttäjätilillesi.
win-installer-welcome-same = Inbox Classic { $version } on jo asennettu. Ohjelma asennetaan uudelleen.

    Sähköpostitilisi ja viestisi säilyvät.
win-installer-welcome-update = Inbox Classic päivitetään versiosta { $installed } versioon { $version }.

    Jos ohjelma on käynnissä, se suljetaan ensin. Sähköpostitilisi ja viestisi säilyvät.
win-installer-older-ask = Asennettuna on Inbox Classic { $installed }, joka on uudempi kuin { $version }. Asennetaanko vanhempi versio silti?
win-installer-still-running = Inbox Classic on yhä käynnissä. Sulje se ja yritä uudelleen.
win-installer-remove-mail-ask = Poistetaanko myös Inbox Classiciin lisätyt tilit ja tähän tietokoneeseen tallennetut viestit? Viestit säilyvät palvelimilla.
