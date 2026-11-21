# Suomi. Luonnos, odottaa äidinkielisen tarkistusta (katso core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Asetukset, Lopeta).

## The main window

gtk-search-looks-in = Hakukohde: { $place }. Viesteistä haetaan aiheen, lähettäjän, vastaanottajien, liitteiden nimien ja tekstin perusteella. Tarkista kirjoitusasu tai kokeile vähemmillä sanoilla.
gtk-search-still-indexing = { $count ->
    [one] 1 viestin tekstiä indeksoidaan vielä. Tuloksia voi ilmestyä pian lisää.
   *[other] { $count } viestin tekstiä indeksoidaan vielä. Tuloksia voi ilmestyä pian lisää.
}
gtk-search-results-everywhere = { $count ->
    [0] Ei tuloksia
    [one] 1 tulos
   *[other] { $count } tulosta
} haulla ”{ $words }” kaikista kansioista
gtk-search-results-in = { $count ->
    [0] Ei tuloksia
    [one] 1 tulos
   *[other] { $count } tulosta
} haulla ”{ $words }” kohteesta { $place }
gtk-search-indexing = { $count ->
    [one] 1 viestin tekstiä indeksoidaan vielä
   *[other] { $count } viestin tekstiä indeksoidaan vielä
}
gtk-list-loading = Ladataan...
gtk-menu-rename = Nimeä uudelleen...
gtk-import-one-question = Tuodaanko viesti { $file } kansioon { $folder }?
gtk-files-not-saved = { $failed } tiedoston tallentaminen epäonnistui. Tiedostoja yhteensä: { $total }.
gtk-unsubscribe-one-click =
    Erotaanko tältä postituslistalta?

    Inbox Classic lähettää tilauksen peruutuspyynnön osoitteeseen { $target }. Mitään verkkosivua ei avata eikä sähköpostia lähetetä.
gtk-unsubscribe-mail = Erotaanko tältä postituslistalta?

    Tilauksen peruuttamista varten on lähetettävä sähköposti osoitteeseen { $target }. Inbox Classic valmistelee viestin puolestasi. Lähetä viesti toimittaaksesi peruutuspyynnön.
gtk-unsubscribe-web =
    Erotaanko tältä postituslistalta?

    Postituslistan tilauksen peruutussivu avautuu selaimeesi ({ $target }).
gtk-unsubscribe-failed = Tilausta ei voitu peruuttaa: { $problem }
gtk-toolbar-create-mail-menu = Kirjoita viesti tietyltä tililtä
gtk-toolbar-send-recv-menu = Lähetä ja vastaanota tietyn tilin posti
gtk-main-menu = Päävalikko
gtk-folder-list = Kansioluettelo
gtk-quit = Lopeta

## The Move and Copy window

gtk-new-folder-at-top-of = Uusi kansio luodaan tilin { $account } ylimmälle tasolle.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Ei lukemattomia viestejä
    [one] 1 lukematon viesti
   *[other] { $count } lukematonta viestiä
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Lähettämistä odottavia viestejä ei ole.
gtk-outbox-row = Vastaanottaja: { $to }  ·  Lisätty jonoon { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic tarkistaa taustalla, onko uutta postia saapunut. Avaa tai lopeta sovellus sen yläpalkin kuvakkeesta.
gtk-sign-in-again-ask =
    Kirjautuminen tilille { $account } hylättiin tai istunto on vanhentunut.

    Kirjaudutaanko uudelleen selaimessa?
gtk-default-app-not-installed = Inbox Classicia käytetään ilman asennusta, joten järjestelmä ei näytä sitä sähköpostisovellusten joukossa. Asenna ohjelma, jotta voit valita sen oletussovellukseksi.
gtk-default-app-now = Inbox Classic on nyt oletussähköpostisovelluksesi. Sähköpostilinkin avaaminen aloittaa uuden viestin Inbox Classicissa.
gtk-default-app-failed = Inbox Classicia ei voitu asettaa oletussähköpostisovellukseksi.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Päivämäärä:
gtk-reader-files = Viestin liitteet
gtk-files = { $count ->
    [one] { $count } tiedosto
   *[other] { $count } tiedostoa
}
gtk-download-pictures = Lataa kuvat
gtk-save-attachments-menu = Tallenna liitteet...

## The compose window

gtk-format-bold = Lihavointi (Ctrl+B)
gtk-format-italic = Kursivointi (Ctrl+I)
gtk-format-underline = Alleviivaus (Ctrl+U)
gtk-format-hyperlink = Hyperlinkki (Ctrl+K)
gtk-font = Fontti
gtk-show-cc = _Kopio
gtk-show-bcc = _Piilokopio
gtk-save-tip = Tallenna (Ctrl+S)
gtk-link-status = { $link }    (avaa Ctrl-napsautuksella)

## Accounts

gtk-plain-warning =
    Ilman salausta kuka tahansa, joka sieppaa verkkoliikenteesi, voi lukea salasanasi ja viestisi. Käytä tätä yhteyttä vain oman tietokoneesi tai lähiverkkosi palvelimen kanssa.

    Jatketaanko?
gtk-account-name-title = Tilin nimi
gtk-display-name-title = Näyttönimi
gtk-turned-off-why = Vaihtoehto ”{ $button }” on poistettu käytöstä tässä tietokoneessa. { $reason }
gtk-turned-off-why-long =
    Vaihtoehto ”{ $button }” on poistettu käytöstä tässä tietokoneessa.

    { $reason }
gtk-next = Seuraava >
gtk-provider-sign-in = { $provider }: kirjaudu tilille { $address } palveluntarjoajan sivustolla. Inbox Classic ei saa salasanaasi. Jos tilisi tukee sovellussalasanoja, voit luoda sellaisen tilin suojausasetuksissa. Outlook.com- ja Microsoft 365 -tileille on kirjauduttava selaimen kautta.
gtk-provider-sign-in-apps = { $provider }: kirjaudu tilille { $address } palveluntarjoajan sivustolla jollakin kirjautumissovelluksellasi (Lisää kirjautumisvaihtoehtoja). Jos tilisi tukee sovellussalasanoja, voit luoda sellaisen tilin suojausasetuksissa. Outlook.com- ja Microsoft 365 -tileille on kirjauduttava selaimen kautta.
gtk-accounts-add = Lisää...
gtk-accounts-properties = Ominaisuudet...
gtk-accounts-signature = Allekirjoitus...
gtk-accounts-sign-in-apps = Kirjautumissovellukset...

## Sign-in apps

gtk-app-server = { $kind }-palvelin
gtk-app-port = { $kind }-portti
gtk-app-security = { $kind }-suojaus
gtk-issuer-found =
    Kirjautumissivu: { $page }
    Tunnuksen päätepiste: { $endpoint }
gtk-client-id = Asiakastunnus
gtk-client-secret = Asiakassalaisuus
gtk-scopes = Käyttöoikeudet (scopes)
gtk-redirect-uri = Uudelleenohjaus-URI
gtk-issuer-usable =
    Myöntäjää voi käyttää.

    { $found }
gtk-app-built-in = { $app } on sisäänrakennettu. Voit vain muuttaa, tarjotaanko sitä uusille tileille. { $reason }
gtk-built-in = { $app } (sisäänrakennettu)
gtk-offered-for-new = Tarjotaan uusille tileille
gtk-edit-button = Muokkaa...
gtk-remove-app-ask = Poistetaanko kirjautumissovellus { $app } ja sen tallennettu asiakassalaisuus?
gtk-sign-in-apps-intro = Kirjautumissovelluksilla voit kirjautua tileille selaimen kautta. Käytöstä poistettua sovellusta ei tarjota uusille tileille. Tilit, jotka jo käyttävät sitä, toimivat edelleen.

## AI agents

gtk-agent-it-may = Sallitut toiminnot
gtk-agent-accounts = Sallitut tilit
gtk-never-used = Ei koskaan käytetty
gtk-last-used = Viimeksi käytetty { $date }
gtk-forget-program = Poistetaanko tämän ohjelman tallennetut käyttöoikeudet?
gtk-forget-program-detail = Ohjelman käyttöoikeudet ja sen agenttien toimintahistoria poistetaan. Sinulta kysytään lupaa uudelleen, kun se seuraavan kerran muodostaa yhteyden.
gtk-no-agents-yet = Mikään agentti ei ole vielä pyytänyt pääsyä postiisi.
gtk-nothing-yet = Ei vielä mitään.

## Preferences

gtk-preferences = Asetukset
gtk-notify-subtitle = Vain kun Inbox Classic on taustalla

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Sähköpostiohjelma
gtk-desktop-comment = Lue ja kirjoita sähköpostia: nopea ja yksinkertainen sähköpostiohjelma
gtk-desktop-keywords = posti;sähköposti;viesti;saapuneet;
gtk-metainfo-summary = Nopea ja yksinkertainen sähköpostiohjelma
gtk-metainfo-description = Inbox Classic on perinteinen sähköpostiohjelma: kansiot vasemmalla, viestiluettelo ylhäällä ja valittu viesti sen alla. Se toimii IMAP- ja SMTP-tilien kanssa ja tukee kirjautumista Outlook.comiin ja Microsoft 365:een selaimen kautta.
gtk-metainfo-feature-sanitized = Viestit näytetään ilman skriptejä ja muuta suoritettavaa sisältöä. Internetin kuvat ladataan vain luvallasi
gtk-metainfo-feature-search = Haku kattaa aiheen, lähettäjät, vastaanottajat, liitteiden nimet ja viestitekstin sekä tukee Gmailin hakuoperaattoreita
gtk-metainfo-feature-replies = Vastausten lainaukset supistetaan, ja ne voi avata tarvittaessa
gtk-metainfo-feature-offline = Ladattua postia voi lukea offline-tilassa, kun paikallinen kopio on tallella; kirjautumistiedot säilytetään yleensä järjestelmän avainnipussa, jos se on käytettävissä
