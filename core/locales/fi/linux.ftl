# Suomi. Luonnos, odottaa äidinkielisen tarkistusta (katso core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Asetukset, Lopeta).

## The main window

# review: new
gtk-search-looks-in = Haku kohteessa { $place } kattaa aiheet, lähettäjät, vastaanottajat, liitteiden nimet ja viestien tekstin. Tarkista kirjoitusasu tai kokeile vähemmillä sanoilla.
# review: new
gtk-search-still-indexing = { $count ->
    [one] 1 viestin tekstiä indeksoidaan vielä. Tuloksia voi ilmestyä pian lisää.
   *[other] { $count } viestin tekstiä indeksoidaan vielä. Tuloksia voi ilmestyä pian lisää.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Ei tuloksia
    [one] 1 tulos
   *[other] { $count } tulosta
} haulla ”{ $words }” kaikista kansioista
# review: new
gtk-search-results-in = { $count ->
    [0] Ei tuloksia
    [one] 1 tulos
   *[other] { $count } tulosta
} haulla ”{ $words }” kohteesta { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] 1 viestin tekstiä indeksoidaan vielä
   *[other] { $count } viestin tekstiä indeksoidaan vielä
}
# review: new
gtk-menu-rename = Nimeä uudelleen...
# review: new
gtk-import-one-question = Tuodaanko viesti { $file } kansioon { $folder }?
# review: new
gtk-files-not-saved = Tiedostoista { $failed }/{ $total } ei voitu tallentaa.
# review: new
gtk-unsubscribe-one-click =
    Erotaanko tältä postituslistalta?

    Inbox Classic lähettää tilauksen peruutuspyynnön osoitteeseen { $target }. Mitään verkkosivua ei avata eikä sähköpostia lähetetä.
# review: new
gtk-unsubscribe-mail =
    Erotaanko tältä postituslistalta?

    Peruuta tilaus lähettämällä sähköposti osoitteeseen { $target }. Inbox Classic valmistelee sen puolestasi. Vahvista lähettämällä viesti.
# review: new
gtk-unsubscribe-web =
    Erotaanko tältä postituslistalta?

    Postituslistan tilauksen peruutussivu avautuu selaimeesi ({ $target }).
# review: new
gtk-unsubscribe-failed = Tilausta ei voitu peruuttaa: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Kirjoita tietyltä tililtä
# review: new
gtk-toolbar-send-recv-menu = Lähetä ja vastaanota tietyn tilin posti
# review: new
gtk-main-menu = Päävalikko
# review: new
gtk-folder-list = Kansioluettelo
# review: new
gtk-quit = Lopeta

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Uusi kansio luodaan ylimmälle tasolle, tili: { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Ei lukemattomia viestejä
    [one] 1 lukematon viesti
   *[other] { $count } lukematonta viestiä
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Lähtöä odottavia viestejä ei ole.
# review: new
gtk-outbox-row = Vastaanottaja: { $to }  ·  Jonossa { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic tarkistaa uutta postia edelleen taustalla. Avaa tai lopeta sovellus sen yläpalkin kuvakkeesta.
# review: new
gtk-sign-in-again-ask =
    Kirjautuminen tilille { $account } hylättiin tai istunto on vanhentunut.

    Kirjaudutaanko uudelleen selaimessa?
# review: new
gtk-default-app-not-installed = Tätä Inbox Classicin kopiota ei ole asennettu, joten järjestelmä ei näytä sitä sähköpostisovellusten joukossa. Asenna se, niin voit valita sen.
# review: new
gtk-default-app-now = Inbox Classic on nyt oletussähköpostisovelluksesi: sähköpostilinkit avaavat uuden viestin täällä.
# review: new
gtk-default-app-failed = Inbox Classicista ei voitu tehdä oletussähköpostisovellusta.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Päivämäärä:
# review: new
gtk-reader-files = Viestin liitteet
# review: new
gtk-pictures-blocked = Joitakin kuvia on estetty, jotta lähettäjä ei voisi tunnistaa tietokonettasi.
# review: new
gtk-download-pictures = Lataa kuvat
# review: new
gtk-save-attachments-menu = Tallenna liitteet...

## The compose window

# review: new
gtk-format-bold = Lihavointi (Ctrl+B)
# review: new
gtk-format-italic = Kursivointi (Ctrl+I)
# review: new
gtk-format-underline = Alleviivaus (Ctrl+U)
# review: new
gtk-format-hyperlink = Hyperlinkki (Ctrl+K)
# review: new
gtk-font = Fontti
# review: new
gtk-show-cc = _Kopio
# review: new
gtk-show-bcc = _Piilokopio
# review: new
gtk-save-tip = Tallenna (Ctrl+S)
# review: new
gtk-link-status = { $link }    (avaa Ctrl-napsautuksella)

## Accounts

# review: new
gtk-plain-warning =
    Ilman salausta kuka tahansa, joka sieppaa verkkoliikenteesi, voi lukea salasanasi ja viestisi. Käytä tätä yhteyttä vain oman tietokoneesi tai lähiverkkosi palvelimen kanssa.

    Jatketaanko?
# review: new
gtk-account-name-title = Tilin nimi
# review: new
gtk-display-name-title = Näyttönimi
# review: new
gtk-turned-off-why = Vaihtoehto ”{ $button }” on poistettu käytöstä tässä tietokoneessa. { $reason }
# review: new
gtk-turned-off-why-long =
    Vaihtoehto ”{ $button }” on poistettu käytöstä tässä tietokoneessa.

    { $reason }
# review: new
gtk-next = Seuraava >
# review: new
gtk-provider-sign-in = Kirjaudu tilille { $address } palveluntarjoajan sivustolla ({ $provider }). Salasanaasi ei jaeta Inbox Classicin kanssa. Voit myös käyttää sovellussalasanaa, jonka olet luonut tilisi suojausasetuksissa.
# review: new
gtk-provider-sign-in-apps = Kirjaudu tilille { $address } palveluntarjoajan sivustolla ({ $provider }) jollakin kirjautumissovelluksellasi (Lisää kirjautumisvaihtoehtoja). Voit myös käyttää sovellussalasanaa, jonka olet luonut tilisi suojausasetuksissa.
# review: new
gtk-accounts-add = Lisää...
# review: new
gtk-accounts-properties = Ominaisuudet...
# review: new
gtk-accounts-signature = Allekirjoitus...
# review: new
gtk-accounts-sign-in-apps = Kirjautumissovellukset...

## Sign-in apps

# review: new
gtk-app-server = { $kind }-palvelin
# review: new
gtk-app-port = { $kind }-portti
# review: new
gtk-app-security = { $kind }-suojaus
# review: new
gtk-issuer-found =
    Kirjautumissivu: { $page }
    Tunnuksen päätepiste: { $endpoint }
# review: new
gtk-client-id = Asiakastunnus
# review: new
gtk-client-secret = Asiakassalaisuus
# review: new
gtk-scopes = Käyttöoikeudet (scopes)
# review: new
gtk-redirect-uri = Uudelleenohjaus-URI
# review: new
gtk-issuer-usable =
    Myöntäjää voi käyttää.

    { $found }
# review: new
gtk-app-built-in = { $app } on sisäänrakennettu. Voit vain muuttaa, tarjotaanko sitä uusille tileille. { $reason }
# review: new
gtk-built-in = { $app } (sisäänrakennettu)
# review: new
gtk-offered-for-new = Tarjotaan uusille tileille
# review: new
gtk-edit-button = Muokkaa...
# review: new
gtk-remove-app-ask = Poistetaanko kirjautumissovellus { $app } ja sen tallennettu asiakassalaisuus?
# review: new
gtk-sign-in-apps-intro = Kirjautumissovellusten avulla tilit voivat kirjautua selaimen kautta. Käytöstä poistettua sovellusta ei tarjota uusille tileille. Tilit, jotka jo käyttävät sitä, toimivat edelleen.

## AI agents

# review: new
gtk-agent-it-may = Sallitut toiminnot
# review: new
gtk-agent-accounts = Sallitut tilit
# review: new
gtk-never-used = Ei koskaan käytetty
# review: new
gtk-last-used = Viimeksi käytetty { $date }
# review: new
gtk-forget-program = Poistetaanko tämä ohjelma?
# review: new
gtk-forget-program-detail = Ohjelman käyttöoikeudet ja sen agenttien toimintahistoria poistetaan. Sinulta kysytään lupaa uudelleen, kun se seuraavan kerran muodostaa yhteyden.
# review: new
gtk-no-agents-yet = Mikään agentti ei ole vielä pyytänyt käyttää postiasi.
# review: new
gtk-nothing-yet = Ei vielä mitään.

## Preferences

# review: new
gtk-preferences = Asetukset
# review: new
gtk-language = Kieli
# review: new
gtk-language-subtitle = Sovelluksen ja ohjeen kieli
# review: new
gtk-new-mail-group = Uusi posti
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Ilmoita uudesta postista
# review: new
gtk-notify-subtitle = Ilmoitus, kun uusia viestejä saapuu ikkunan ollessa taustalla
# review: new
gtk-restart-to-change = Inbox Classic käynnistyy uudelleen kielen vaihtamiseksi.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Sähköpostiohjelma
# review: new
gtk-desktop-comment = Lue ja kirjoita sähköpostia: nopea ja yksinkertainen sähköpostiohjelma
# review: new
gtk-desktop-keywords = posti;sähköposti;viesti;saapuneet;
# review: new
gtk-metainfo-summary = Nopea ja yksinkertainen sähköpostiohjelma
# review: new
gtk-metainfo-description = Inbox Classic lukee ja kirjoittaa sähköpostia niin kuin sähköpostiohjelmat ennen: kansiot vasemmalla, viestit ylhäällä ja valittu viesti alla. Se toimii minkä tahansa IMAP- ja SMTP-tilin kanssa ja kirjautuu Outlook.comiin ja Microsoft 365:een selaimen kautta.
# review: new
gtk-metainfo-feature-sanitized = Jokainen viesti näytetään puhdistettuna, ilman skriptejä, ja internetin kuvat vain, kun sallit ne
# review: new
gtk-metainfo-feature-search = Haku, joka löytää sanat aiheesta, henkilöistä, tiedostonimistä ja tekstistä Gmailin hakuoperaattoreilla
# review: new
gtk-metainfo-feature-replies = Vastaukset piilottavat lainaamansa aiemmat viestit
# review: new
gtk-metainfo-feature-offline = Posti pysyy luettavana ilman verkkoyhteyttä, ja salasanat säilytetään avainnipussasi
