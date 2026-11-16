# Suomi. Luonnos, odottaa äidinkielisen tarkistusta (katso core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic tarkistaa uutta postia edelleen taustalla. Avaa se napsauttamalla kuvaketta. Jos haluat lopettaa, napsauta kuvaketta hiiren kakkospainikkeella ja käytä sen valikkoa.
# review: new
win-default-app-not-installed = Tätä Inbox Classicin kopiota ei ole asennettu, joten Windows ei näytä sitä sähköpostisovellusten joukossa. Asenna se, niin voit valita sen.
# review: new
win-default-app-settings = Windows avaa Oletussovellukset-asetukset. Valitse Inbox Classic avaamaan MAILTO-linkit.
# review: new
win-no-unread = Ei lukemattomia viestejä
# review: new
win-unread-messages = { $count ->
    [one] 1 lukematon viesti
   *[other] { $count } lukematonta viestiä
}
# review: new
win-print-failed = Viestiä ei voitu tulostaa.
# review: new
win-print-title-of = Tulosta - { $subject }
# review: new
win-no-bodies = Viestien sisältöä ei voi näyttää.
# review: new
win-webview-failed = WebView2:n luominen epäonnistui.
# review: new
win-webview-missing = WebView2-suoritusympäristö ei ole käytettävissä.

## Buttons and words used in many windows

# review: new
win-delete-button = &Poista
# review: new
win-find-label = &Etsi:
# review: new
win-save-as-button = Tallenna &nimellä...
# review: new
win-too-many-files = Liian monta tiedostoa kerralla: valitse vähemmän.

## The Outbox


## The compose window

# review: new
win-editor-failed = Viestejä ei voi kirjoittaa.
# review: new
win-ctrl-click-to-open = (avaa painamalla { $ctrl } ja napsauttamalla)
# review: new
win-format-bold = Lihavointi ({ $ctrl }+B)
# review: new
win-format-italic = Kursivointi ({ $ctrl }+I)
# review: new
win-format-underline = Alleviivaus ({ $ctrl }+U)
# review: new
win-format-link = Hyperlinkki ({ $ctrl }+K)
# review: new
win-show-cc = &Kopio
# review: new
win-show-bcc = &Piilokopio
# review: new
win-signature-title = Allekirjoitus: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Ei tuloksia haulla ”{ $words }” kaikista kansioista
    [one] { $count } tulos haulla ”{ $words }” kaikista kansioista
   *[other] { $count } tulosta haulla ”{ $words }” kaikista kansioista
}
# review: new
win-search-found-in = { $count ->
    [0] Ei tuloksia haulla ”{ $words }” kansiosta { $folder }
    [one] { $count } tulos haulla ”{ $words }” kansiosta { $folder }
   *[other] { $count } tulosta haulla ”{ $words }” kansiosta { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] { $count } viestin tekstiä indeksoidaan vielä
   *[other] { $count } viestin tekstiä indeksoidaan vielä
}
# review: new
win-no-match-indexing = { $count ->
    [one] { $count } viestin tekstiä indeksoidaan vielä, joten tuloksia voi löytyä pian lisää.
   *[other] { $count } viestin tekstiä indeksoidaan vielä, joten tuloksia voi löytyä pian lisää.
}
# review: new
win-files = { $count ->
    [one] { $count } tiedosto
   *[other] { $count } tiedostoa
}
# review: new
win-click-to-retry = Yritä uudelleen napsauttamalla tätä.
# review: new
win-save-attachments = &Tallenna liitteet...
# review: new
win-files-not-saved = Tiedostoista { $failed }/{ $count } ei voitu tallentaa.
# review: new
win-new-folder-in-highlighted = Uusi kansio luodaan valitun kansion sisään.
# review: new
win-delete-folder-ask = Poistetaanko kansio ”{ $folder }” viesteineen ja sen sisältämine kansioineen? Se poistetaan myös palvelimelta.
# review: new
win-rename = &Nimeä uudelleen...
# review: new
win-messages-not-saved = Viestejä ei voitu tallentaa.
# review: new
win-messages-not-forwarded = Viestejä ei voitu välittää edelleen.

## Accounts

# review: new
win-sign-in-google = Kirjaudu Googlella
# review: new
win-sign-in-microsoft = Kirjaudu Microsoftilla
# review: new
win-next = &Seuraava >
# review: new
win-your-account = tilisi
# review: new
win-browser-sign-in = (kirjautuminen selaimessa)
# review: new
win-add = &Lisää...
# review: new
win-properties-button = &Ominaisuudet...
# review: new
win-signature-button = &Allekirjoitus...
# review: new
win-sign-in-apps-button = &Kirjautumissovellukset...

## AI agents

# review: new
win-dont-allow = Ä&lä salli
# review: new
win-col-address = Osoite
# review: new
win-never-written-to = Ei koskaan kirjoitettu
# review: new
win-book-find-label = Kirjoita nimi tai sähköpostiosoite:
# review: new
win-send = &Lähetä
# review: new
win-dont-send = Ä&lä lähetä
# review: new
win-forget-program-ask = Poistetaanko tämä ohjelma, sen käyttöoikeudet ja sen agenttien toimintahistoria? Sinulta kysytään lupaa uudelleen, kun se seuraavan kerran muodostaa yhteyden.
# review: new
win-clear-log-ask = Tyhjennetäänkö agenttien toimintahistoria? Tämä ei kumoa agenttien tekemiä muutoksia.
# review: new
win-agent-programs = &Ohjelmat, joiden agentit ovat pyytäneet pääsyä postiisi:
# review: new
win-change = &Muuta...
# review: new
win-what-agents-did = Agenttien &toiminta:
# review: new
win-how-to-connect = Agentin yhdistäminen

## Sign-in apps

# review: new
win-built-in = (sisäänrakennettu)
# review: new
win-edit = &Muokkaa...

## Options

# review: new
win-options-language-label = &Inbox Classicin kieli:
# review: new
win-options-restart-note = Kieli vaihtuu, kun Inbox Classic käynnistetään uudelleen.
# review: new
win-options-notify = &Ilmoita, kun uutta postia saapuu
# review: new
win-restart-ask = Inbox Classic näytetään kielellä { $language }, kun se käynnistyy uudelleen. Käynnistetäänkö uudelleen nyt?
# review: new
win-folders-hide = Piilota kansioluettelo
# review: new
win-folders-pin = Pidä kansioluettelo viestien vieressä
# review: new
win-folders-show = Näytä kansiot

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Käynnistä Inbox Classic
# review: new
win-installer-welcome-new =
    Tämä asentaa sähköpostiohjelman Inbox Classic { $version }.

    Järjestelmänvalvojan oikeuksia ei tarvita, sillä ohjelma asennetaan vain sinun tilillesi.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } on jo asennettu. Tämä asentaa sen uudelleen.

    Tilisi ja postisi säilyvät.
# review: new
win-installer-welcome-update =
    Tämä päivittää Inbox Classicin version { $installed } versioon { $version }.

    Jos ohjelma on käynnissä, se suljetaan ensin. Tilisi ja postisi säilyvät.
# review: new
win-installer-older-ask = Asennettuna on Inbox Classic { $installed }, joka on uudempi kuin { $version }. Asennetaanko vanhempi versio silti?
# review: new
win-installer-still-running = Inbox Classic on yhä käynnissä. Sulje se ja yritä uudelleen.
# review: new
win-installer-remove-mail-ask = Poistetaanko myös tilit ja posti, jotka Inbox Classic säilyttää tässä tietokoneessa? Palvelimilla oleva posti säilyy.
