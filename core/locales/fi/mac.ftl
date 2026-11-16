# Suomi. Luonnos, odottaa äidinkielisen tarkistusta (katso core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions in Finnish:
# an ellipsis (…) after a command that asks for more, sentence case, ” quotes, macOS's own words (Kätke, Sijoita).

## The app and its menus

# review: new
mac-quit = Lopeta Inbox Classic
# review: new
mac-settings = Asetukset…
# review: new
mac-services = Palvelut
# review: new
mac-hide = Kätke Inbox Classic
# review: new
mac-hide-others = Kätke muut
# review: new
mac-show-all = Näytä kaikki
# review: new
mac-check-updates = Tarkista päivitykset…
# review: new
mac-close-window = Sulje ikkuna
# review: new
mac-redo = Tee uudelleen
# review: new
mac-cut = Leikkaa
# review: new
mac-paste = Sijoita
# review: new
mac-menu-window = Ikkuna
# review: new
mac-minimize = Pienennä
# review: new
mac-zoom = Zoomaa
# review: new
mac-no-updates = Tämä Inbox Classicin versio ei tue automaattisia päivityksiä. Lataa uusin versio osoitteesta inboxclassic.com.

## Settings

# review: new
mac-settings-title = Asetukset
# review: new
mac-language-label = Kieli:
# review: new
mac-restart-hint = Kieli vaihtuu, kun Inbox Classic käynnistetään uudelleen.
# review: new
mac-notify-new-mail = Ilmoita, kun uutta postia saapuu
# review: new
mac-restart-question = Käynnistetäänkö Inbox Classic nyt uudelleen kielen vaihtamiseksi?

## Dialogs

# review: new
mac-choose = Valitse

## The main window

# review: new
mac-still-running-detail = Inbox Classic tarkistaa uutta postia edelleen taustalla. Avaa apin ikkuna osoittamalla sen kuvaketta Dockissa.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } viesti Lähtevät-kansiossa
       *[other] { $count } viestiä Lähtevät-kansiossa
    }
# review: new
mac-sending = Lähetetään { $subject }…
# review: new
mac-checking = Tarkistetaan tilin { $account } uusia viestejä…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Tämä Inbox Classicin kopio ei ole appipaketti, joten siitä ei voi tehdä oletussähköpostiappia.
# review: new
mac-not-made-default = Inbox Classicista ei tehty oletussähköpostiappia: { $reason }
# review: new
mac-tool-search = Haku

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] { $count } viestin tekstiä indeksoidaan vielä, joten tuloksia voi löytyä pian lisää.
       *[other] { $count } viestin tekstiä indeksoidaan vielä, joten tuloksia voi löytyä pian lisää.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Ei tuloksia haulla ”{ $words }” kaikista kansioista
        [one] { $count } tulos haulla ”{ $words }” kaikista kansioista
       *[other] { $count } tulosta haulla ”{ $words }” kaikista kansioista
    }
# review: new
mac-results-in =
    { $count ->
        [0] Ei tuloksia haulla ”{ $words }” kansiosta { $folder }
        [one] { $count } tulos haulla ”{ $words }” kansiosta { $folder }
       *[other] { $count } tulosta haulla ”{ $words }” kansiosta { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] { $count } viestin tekstiä indeksoidaan vielä
       *[other] { $count } viestin tekstiä indeksoidaan vielä
    }
# review: new
mac-folder-unread = { $folder }, lukemattomia { $count }
# review: new
mac-import-messages = Tuo viestejä
# review: new
mac-save-messages = Tallenna viestit
# review: new
mac-save-attachments-menu = Tallenna liitteet…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Tiedostoista { $failed }/{ $count } ei voitu tallentaa.
    }
# review: new
mac-no-calendar-app = Tässä Macissa ei ole kalenteriappia kutsujen (.ics-tiedostojen) avaamiseen.
# review: new
mac-file-not-saved = Tiedostoa ei voitu tallentaa.
# review: new
mac-unsubscribing = Peruutetaan tilausta: { $target }…

## The compose window

# review: new
mac-bold = Lihavointi
# review: new
mac-italic = Kursivointi
# review: new
mac-underline = Alleviivaus
# review: new
mac-bcc = Piilokopio
# review: new
mac-command-click-to-open = Avaa ⌘-osoittamalla
# review: new
mac-saving-to-drafts = Tallennetaan Luonnokset-kansioon…
# review: new
mac-dont-save = Älä tallenna

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } tiedosto
       *[other] { $count } tiedostoa
    }

## Accounts

# review: new
mac-next = Seuraava
# review: new
mac-name-placeholder = Maija Virtanen
# review: new
mac-more-sign-in-options = Lisää kirjautumisvaihtoehtoja…
# review: new
mac-add-sign-in-app = Lisää kirjautumissovellus…
# review: new
mac-looking-up = Haetaan verkkotunnuksen { $domain } asetuksia…
# review: new
mac-add-button = Lisää…
# review: new
mac-properties-button = Ominaisuudet…
# review: new
mac-signature-button = Allekirjoitus…
# review: new
mac-security-button = Suojaus…
# review: new
mac-sign-in-apps-button = Kirjautumissovellukset…

## AI agents

# review: new
mac-forget-program = Poistetaanko tämä ohjelma ja sen agenttien toimintahistoria?
# review: new
mac-forget-program-detail = Ohjelman käyttöoikeudet poistetaan. Sinulta kysytään lupaa uudelleen, kun se seuraavan kerran muodostaa yhteyden.

## Sign-in apps

# review: new
mac-checking-issuer = Tarkistetaan { $issuer }…
# review: new
mac-edit-button = Muokkaa…
# review: new
mac-use-for-new-accounts = Käytä uusille tileille: { $name }
# review: new
mac-built-in = { $name } (sisäänrakennettu)

## Other windows

# review: new
mac-new-folder-button = Uusi kansio…
# review: new
mac-edit-link = Muokkaa linkkiä…
