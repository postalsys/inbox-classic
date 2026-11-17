# Suomi. Luonnos, odottaa äidinkielisen tarkistusta (katso core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions in Finnish:
# an ellipsis (…) after a command that asks for more, sentence case, ” quotes, macOS's own words (Kätke, Sijoita).

## The app and its menus

mac-quit = Lopeta Inbox Classic
mac-settings = Asetukset…
mac-services = Palvelut
mac-hide = Kätke Inbox Classic
mac-hide-others = Kätke muut
mac-show-all = Näytä kaikki
mac-check-updates = Tarkista päivitykset…
mac-close-window = Sulje ikkuna
mac-redo = Tee uudelleen
mac-cut = Leikkaa
mac-paste = Sijoita
mac-menu-window = Ikkuna
mac-minimize = Pienennä
mac-zoom = Zoomaa
mac-no-updates = Tämä Inbox Classicin versio ei tue automaattisia päivityksiä. Lataa uusin versio osoitteesta inboxclassic.com.

## Settings

mac-settings-title = Asetukset
mac-check-updates-automatically = Tarkista päivitykset automaattisesti
mac-settings-updates = Päivitykset

## Dialogs

mac-choose = Valitse

## The main window

mac-still-running-detail = Inbox Classic tarkistaa taustalla, onko uutta postia saapunut. Avaa apin ikkuna osoittamalla sen kuvaketta Dockissa.
mac-outbox-waiting =
    { $count ->
        [one] { $count } viesti Lähtevät-kansiossa
       *[other] { $count } viestiä Lähtevät-kansiossa
    }
mac-sending = Lähetetään { $subject }…
mac-checking = { $account }: tarkistetaan uudet viestit…
mac-account-said = { $account }: { $message }
mac-not-bundle = Inbox Classic on käynnissä ilman appipakettia, joten sitä ei voi asettaa oletussähköpostiappiksi.
mac-not-made-default = Inbox Classicia ei voitu asettaa oletussähköpostiappiksi: { $reason }
mac-tool-search = Haku

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] { $count } viestin tekstiä indeksoidaan vielä, joten tuloksia voi löytyä pian lisää.
       *[other] { $count } viestin tekstiä indeksoidaan vielä, joten tuloksia voi löytyä pian lisää.
    }
mac-results-everywhere =
    { $count ->
        [0] Ei tuloksia haulla ”{ $words }” kaikista kansioista
        [one] { $count } tulos haulla ”{ $words }” kaikista kansioista
       *[other] { $count } tulosta haulla ”{ $words }” kaikista kansioista
    }
mac-results-in =
    { $count ->
        [0] Ei tuloksia haulla ”{ $words }” kansiosta { $folder }
        [one] { $count } tulos haulla ”{ $words }” kansiosta { $folder }
       *[other] { $count } tulosta haulla ”{ $words }” kansiosta { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] { $count } viestin tekstiä indeksoidaan vielä
       *[other] { $count } viestin tekstiä indeksoidaan vielä
    }
mac-folder-unread = { $folder }, lukemattomia { $count }
mac-import-messages = Tuo viestejä
mac-save-messages = Tallenna viestit
mac-save-attachments-menu = Tallenna liitteet…
mac-files-not-saved = { $count ->
       *[other] { $failed } tiedoston tallentaminen epäonnistui. Tiedostoja yhteensä: { $count }.
    }
mac-no-calendar-app = Tässä Macissa ei ole kalenteriappia kutsujen (.ics-tiedostojen) avaamiseen.
mac-file-not-saved = Tiedostoa ei voitu tallentaa.
mac-unsubscribing = Peruutetaan tilausta: { $target }…
mac-loading-list = Ladataan…

## The compose window

mac-bold = Lihavointi
mac-italic = Kursivointi
mac-underline = Alleviivaus
mac-bcc = Piilokopio
mac-command-click-to-open = Avaa ⌘-osoittamalla
mac-saving-to-drafts = Tallennetaan Luonnokset-kansioon…
mac-dont-save = Älä tallenna

## The reading pane

mac-files =
    { $count ->
        [one] { $count } tiedosto
       *[other] { $count } tiedostoa
    }

## Accounts

mac-next = Seuraava
mac-name-placeholder = Maija Virtanen
mac-more-sign-in-options = Lisää kirjautumisvaihtoehtoja…
mac-add-sign-in-app = Lisää kirjautumissovellus…
mac-looking-up = Haetaan verkkotunnuksen { $domain } asetuksia…
mac-add-button = Lisää…
mac-properties-button = Ominaisuudet…
mac-signature-button = Allekirjoitus…
mac-security-button = Suojaus…
mac-sign-in-apps-button = Kirjautumissovellukset…

## AI agents

mac-forget-program = Poistetaanko tämä ohjelma ja sen agenttien toimintahistoria?
mac-forget-program-detail = Ohjelman käyttöoikeudet poistetaan. Sinulta kysytään lupaa uudelleen, kun se seuraavan kerran muodostaa yhteyden.

## Sign-in apps

mac-checking-issuer = Tarkistetaan { $issuer }…
mac-edit-button = Muokkaa…
mac-use-for-new-accounts = Käytä uusille tileille: { $name }
mac-built-in = { $name } (sisäänrakennettu)

## Other windows

mac-new-folder-button = Uusi kansio…
mac-edit-link = Muokkaa linkkiä…
