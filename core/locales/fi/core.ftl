# Suomi. Luonnos, odottaa äidinkielisen tarkistusta (katso core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Finnish: [one] and *[other]. Placeables are never inflected: a head noun takes the case, or a label and a colon.

## Counts and sizes

# review: new
messages = { $count ->
    [one] { $count } viesti
   *[other] { $count } viestiä
}
# the separator of decimals in sizes: 2,4 Mt
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] { $count } tavu
   *[other] { $count } tavua
}
# review: new
size-kb = { $size } kt
# review: new
size-mb = { $size } Mt
# review: new
size-gb = { $size } Gt
# review: new
send-delay-off = Ei käytössä
# review: new
send-delay-seconds = { $count ->
    [one] { $count } sekunti
   *[other] { $count } sekuntia
}
# the status bar: "12 viestiä, 3 lukematonta"
# review: new
list-counts = { $messages }, lukemattomia { $unread }
# review: new
list-counts-selected = { $messages }, lukemattomia { $unread }, valittuna { $selected }
# the status bar while searching: "löytyi 12, lukemattomia 3"
# review: new
list-counts-found = Löytyi { $found }, lukemattomia { $unread }
# review: new
list-counts-found-selected = Löytyi { $found }, lukemattomia { $unread }, valittuna { $selected }
# review: new
list-counts-none = Viestejä ei löytynyt

## Special folders, as Outlook names them

# review: new
folder-inbox = Saapuneet
# review: new
folder-sent = Lähetetyt
# review: new
folder-deleted = Poistetut
# review: new
folder-drafts = Luonnokset
# review: new
folder-junk = Roskaposti
# review: new
folder-archive = Arkisto

## The reading pane

# review: new
reader-no-message = Viestiä ei ole valittu.
# review: new
reader-downloading = Ladataan viestiä…
# review: new
reader-downloading-detail = Viesti näkyy tässä, kun lataus on valmis.
# review: new
reader-downloading-size = Viestin koko on { $size }. Se näkyy tässä, kun se on ladattu.
# review: new
reader-failed = Viestiä ei voitu ladata
# review: new
reader-failed-network = Postipalvelimeen ei saatu yhteyttä ({ $reason }).
# review: new
reader-failed-sign-in = Postipalvelin ei hyväksynyt kirjautumista ({ $reason }). Tarkista salasana tai kirjaudu uudelleen kohdassa Tiedosto > Tilit.
# review: new
reader-failed-security = Yhteyttä postipalvelimeen ei voitu suojata ({ $reason }).
# review: new
reader-failed-other = Postipalvelin vastasi: { $reason }.
# review: new
reader-retry-note = Latausta yritetään uudelleen, kun tilin yhteys palaa.
# review: new
reader-unreadable = Tätä viestiä ei voi näyttää: { $error }
# review: new
message-source-title = Viestin lähdekoodi: { $subject }
# review: new
message-source-untitled = Viestin lähdekoodi

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Lähettäjä
# review: new
header-date = Päivämäärä
# review: new
header-to = Vastaanottaja
# review: new
header-cc = Kopio
# review: new
header-sent = Lähetetty
# review: new
header-subject = Aihe
# review: new
header-security = Suojaus
# review: new
header-part = Osa { $number }
# review: new
quote-original = ----- Alkuperäinen viesti -----
# review: new
fold-show-earlier = Näytä aiemmat viestit

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Viestiäsi ei toimitettu
# review: new
bounce-delayed = Viestiäsi ei ole vielä toimitettu
# review: new
bounce-delayed-note = Postipalvelimesi yrittää yhä toimittaa sitä. Sitä ei tarvitse lähettää uudelleen.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Näytä palautunut viesti
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Näytä viivästynyt viesti
# review: new
bounce-what-to-do = Mitä voit tehdä:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Ei vielä mitään. Jos viestiä ei edelleenkään voida toimittaa, saat uuden ilmoituksen.
# review: new
bounce-delayed-row-do = Ei vielä mitään. Postipalvelimesi yrittää yhä toimittaa viestiä, ja saat uuden ilmoituksen, jos se ei onnistu.
# folds the receiving server's own words
# review: new
bounce-details = Tiedot
# a recipient the notice does not name
# review: new
bounce-someone = Vastaanottaja
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Palvelin: { $server }
# review: new
bounce-status = Tila: { $status }
# review: new
bounce-reported-by = Ilmoittaja: { $server }
# review: new
bounce-retry-minutes = Vastaanottava palvelin pyysi odottamaan { $count ->
    [one] minuutin
   *[other] { $count } minuuttia
} ennen seuraavaa yritystä.
# review: new
bounce-retry-hours = Vastaanottava palvelin pyysi odottamaan { $count ->
    [one] tunnin
   *[other] { $count } tuntia
} ennen seuraavaa yritystä.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Estolista: { $lists }
# review: new
bounce-user-unknown = Osoitetta ei ole olemassa
# review: new
bounce-user-unknown-why = Vastaanottavalla palvelimella ei ole tällä osoitteella postilaatikkoa. Osoitteessa voi olla kirjoitusvirhe, tai henkilö on ehkä siirtynyt muualle.
# review: new
bounce-user-unknown-do = Tarkista osoitteen kirjoitusasu tai kysy henkilöltä osoitetta, jota hän nyt käyttää.
# review: new
bounce-invalid-address = Osoite ei kelpaa
# review: new
bounce-invalid-address-why = Osoite ei ole muodossa, johon postia voi lähettää.
# review: new
bounce-invalid-address-do = Etsi kirjoitusvirheitä, kuten välilyönti, puuttuva kirjain tai tyhjä kohta @-merkin jälkeen.
# review: new
bounce-mailbox-disabled = Postilaatikko on suljettu
# review: new
bounce-mailbox-disabled-why = Osoite on olemassa, mutta sen postilaatikko on poistettu käytöstä tai se ei ole enää käytössä.
# review: new
bounce-mailbox-disabled-do = Tavoita henkilö muulla tavalla ja kysy osoitetta, jota hän nyt käyttää.
# review: new
bounce-mailbox-full = Postilaatikko on täynnä
# review: new
bounce-mailbox-full-why = Vastaanottajan postilaatikossa ei ole tilaa uudelle postille.
# review: new
bounce-mailbox-full-do = Lähetä viesti uudelleen muutaman päivän kuluttua tai ilmoita asiasta henkilölle muulla tavalla. Suuret liitteet torjutaan ensimmäisinä.
# review: new
bounce-spam-blocked = Torjuttu roskapostina
# review: new
bounce-spam-blocked-why = Vastaanottava palvelin piti viestiä roskapostina.
# review: new
bounce-spam-blocked-do = Lähetä viesti uudelleen ilman sitä, mikä näyttää roskapostilta, kuten monia linkkejä, lyhennettyjä linkkejä tai suurta liitettä. Jos näin käy toistuvasti, kysy postipalveluntarjoajaltasi.
# review: new
bounce-virus-detected = Torjuttu viruksen vuoksi
# review: new
bounce-virus-detected-why = Vastaanottava palvelin löysi viestistä tai sen liitteistä viruksen tai muuta haitallista sisältöä.
# review: new
bounce-virus-detected-do = Tarkista liitteet virustorjuntaohjelmalla. Jotkin palvelimet torjuvat kaikki ohjelmat ja arkistot, joten jaa tällaiset tiedostot mieluummin linkkinä.
# review: new
bounce-ip-blocklisted = Postipalvelimesi on estolistalla
# review: new
bounce-ip-blocklisted-why = Vastaanottava palvelin torjuu postin palvelimelta, joka lähetti viestisi, koska sen palvelimen osoite on estolistalla.
# review: new
bounce-ip-blocklisted-do = Vika ei ole viestissä. Välitä tämä ilmoitus postipalveluntarjoajallesi ja pyydä heitä poistattamaan palvelin listalta.
# review: new
bounce-domain-blocklisted = Verkkotunnus on estolistalla
# review: new
bounce-domain-blocklisted-why = Vastaanottava palvelin torjuu viestin, koska osoitteesi verkkotunnus tai jokin viestin linkkien verkkotunnus on estolistalla.
# review: new
bounce-domain-blocklisted-do = Jos viestissä on linkkejä, kokeile lähettää se ilman niitä. Muuten välitä tämä ilmoitus sille, joka hoitaa verkkotunnuksesi postin.
# review: new
bounce-policy-blocked = Torjuttu vastaanottavan palvelimen sääntöjen vuoksi
# review: new
bounce-policy-blocked-why = Vastaanottavan palvelimen säännöt eivät päästä tätä viestiä läpi esimerkiksi sen koon, liitteiden tai lähettäjän vuoksi.
# review: new
bounce-policy-blocked-do = Palvelimen omat sanat kohdassa Tiedot kertovat usein syyn. Kysy vastaanottajalta, voiko hän ottaa vastaan tällaista postia.
# review: new
bounce-geo-blocked = Torjuttu lähtöpaikan vuoksi
# review: new
bounce-geo-blocked-why = Vastaanottava palvelin ei ota vastaan postia siitä maasta tai verkosta, jossa postipalvelimesi on.
# review: new
bounce-geo-blocked-do = Tavoita henkilö muulla tavalla tai kysy asiasta postipalveluntarjoajaltasi.
# review: new
bounce-relay-denied = Palvelin ei välittänyt viestiä eteenpäin
# review: new
bounce-relay-denied-why = Palvelin kieltäytyi toimittamasta viestiä eteenpäin, usein koska se lähetettiin kirjautumatta tai palvelimen kautta, joka ei käsittele tämän vastaanottajan postia.
# review: new
bounce-relay-denied-do = Tarkista tilin lähtevän postin palvelin kohdassa Tiedosto > Tilit ja että se kirjautuu.
# review: new
bounce-auth-failure = Lähettäjän osoitettasi ei voitu vahvistaa
# review: new
bounce-auth-failure-why = Vastaanottava palvelin ei voinut varmistaa, että viesti todella tuli verkkotunnuksestasi (SPF, DKIM tai DMARC).
# review: new
bounce-auth-failure-do = Välitä tämä ilmoitus sille, joka hoitaa verkkotunnuksesi postin: sen asetukset on korjattava. Sillä välin lähettäminen palveluntarjoajasi oman palvelimen kautta voi auttaa.
# review: new
bounce-rate-limited = Liikaa postia kerralla
# review: new
bounce-rate-limited-why = Vastaanottava palvelin ottaa toistaiseksi vastaan vähemmän viestejä postipalvelimeltasi.
# review: new
bounce-rate-limited-do = Odota hetki ja lähetä viesti uudelleen. Kun kirjoitat monille, lähetä harvemmille kerrallaan.
# review: new
bounce-greylisting = Pidätetty hetkeksi
# review: new
bounce-greylisting-why = Vastaanottava palvelin pyytää tuntemattomia lähettäjiä yrittämään hieman myöhemmin uudelleen. Se on yleinen roskapostin torjuntakeino.
# review: new
bounce-greylisting-do = Ei mitään. Postipalvelimet yrittävät uudelleen itse, ja viesti toimitetaan yleensä tunnin kuluessa.
# review: new
bounce-server-error = Vastaanottavalla palvelimella oli ongelma
# review: new
bounce-server-error-why = Vastaanottavaan palvelimeen ei saatu yhteyttä, tai se ei voinut ottaa viestiä vastaan oman ongelmansa vuoksi.
# review: new
bounce-server-error-do = Lähetä viesti myöhemmin uudelleen. Jos se epäonnistuu yhä, tarkista osoitteen @-merkin jälkeinen osa kirjoitusvirheiden varalta.
# review: new
bounce-unknown = Ei toimitettu
# review: new
bounce-unknown-why = Ilmoitus ei kerro selvästi syytä.
# review: new
bounce-unknown-do = Palvelimen omat sanat kohdassa Tiedot voivat kertoa enemmän. Jos niistä ei ole apua, välitä tämä ilmoitus postipalveluntarjoajallesi.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } viesti valittuna
   *[other] { $count } viestiä valittuna
}
# review: new
selection-unread = Lukemattomia { $count }
# review: new
selection-flagged = Liputettuja { $count }
# review: new
delete-for-good-one = Tämä viesti poistetaan pysyvästi. Poistetaanko se?
# review: new
delete-for-good-all = Nämä viestit ({ $count }) poistetaan pysyvästi. Poistetaanko ne?
# review: new
delete-for-good-some = Viesteistä { $count }/{ $total } poistetaan pysyvästi. Poistetaanko viestit?
# review: new
done-read = { $count ->
    [one] Merkitty luetuksi: { $messages }
   *[other] Merkitty luetuiksi: { $messages }
}
# review: new
done-unread = { $count ->
    [one] Merkitty lukemattomaksi: { $messages }
   *[other] Merkitty lukemattomiksi: { $messages }
}
# review: new
done-flagged = { $count ->
   *[other] Liputettu: { $messages }
}
# review: new
done-unflagged = Lippu poistettu: { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Poistettu pysyvästi: { $messages }
}
# review: new
done-archived = { $count ->
   *[other] Arkistoitu: { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Siirretty: { $messages }. Kohde: { $folder }
}
# review: new
done-copied = { $count ->
   *[other] Kopioitu: { $messages }. Kohde: { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Siirretään: { $messages }. Kohde: { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Kopioidaan: { $messages }. Kohde: { $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] Siirretty takaisin: { $messages }. Kohde: { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Keskustelua seurataan
   *[other] Seurataan keskusteluja: { $count }
}
# review: new
done-unwatched = { $count ->
    [one] Keskustelun seuraaminen lopetettu
   *[other] Keskustelujen seuraaminen lopetettu: { $count }
}
# review: new
done-ignored = { $count ->
    [one] Keskustelu ohitetaan
   *[other] Ohitetaan keskusteluja: { $count }
}
# review: new
done-unignored = { $count ->
    [one] Keskustelun ohittaminen lopetettu
   *[other] Keskustelujen ohittaminen lopetettu: { $count }
}
# review: new
their-folders = alkuperäiset kansiot
# review: new
undo-move = Kumoa siirto
# review: new
undo-delete = Kumoa poisto
# review: new
undo-archive = Kumoa arkistointi
# review: new
undo-junk = Kumoa roskapostiksi merkintä
# review: new
undo-not-junk = Kumoa ei-roskapostiksi merkintä
# review: new
undo-send = Kumoa lähetys
# review: new
nothing-to-undo = Ei mitään kumottavaa.
# review: new
messages-gone = Viestejä ei ole enää.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Tässä kansiossa ei voi olla viestejä.
# review: new
not-archived-here = Tämän kansion viestejä ei voi arkistoida.
# review: new
not-emptied-here = Vain Poistetut- ja Roskaposti-kansion voi tyhjentää.
# review: new
next-unread-question = Kansiossa { $folder } ei ole enempää lukemattomia viestejä.

    Siirrytäänkö seuraavaan kansioon, jossa on lukemattomia viestejä: { $next }?
# review: new
no-unread-left = Lukemattomia viestejä ei ole jäljellä.
# review: new
empty-question = { $count ->
    [one] Tyhjennetäänkö kansio { $folder }?

        Sen viesti poistetaan pysyvästi. Sitä ei voi palauttaa.
   *[other] Tyhjennetäänkö kansio { $folder }?

        Sen viestit ({ $messages }) poistetaan pysyvästi. Niitä ei voi palauttaa.
}
# review: new
no-junk-folder = Tilillä ei ole Roskaposti-kansiota, johon viestit voisi siirtää.
# review: new
no-inbox-folder = Tilillä ei ole Saapuneet-kansiota, johon viestit voisi siirtää.
# the status bar after a flag in a colour: "2 viestiä liputettiin punaisella lipulla"
# review: new
done-flagged-color = { $messages } liputettiin { $color ->
    [red] punaisella
    [orange] oranssilla
    [yellow] keltaisella
    [green] vihreällä
    [blue] sinisellä
    [purple] violetilla
   *[gray] harmaalla
} lipulla
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Punainen
    [orange] Oranssi
    [yellow] Keltainen
    [green] Vihreä
    [blue] Sininen
    [purple] Violetti
   *[gray] Harmaa
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [one] Siirrä viesti
   *[other] Siirrä { $count } viestiä
}
# review: new
move-window-title-copy = { $count ->
    [one] Kopioi viesti
   *[other] Kopioi { $count } viestiä
}
# review: new
move-window-prompt-move = { $count ->
    [one] Siirrä valittu viesti kohteeseen:
   *[other] Siirrä valitut { $count } viestiä kohteeseen:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Kopioi valittu viesti kohteeseen:
   *[other] Kopioi valitut { $count } viestiä kohteeseen:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Viimeisimmät
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (nykyinen)
# a folder used last, with its account when there are several: "Arkisto (Työ)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Siirretään { $done }/{ $messages }. Kohde: { $folder }...
# review: new
transfer-copying = Kopioidaan { $done }/{ $messages }. Kohde: { $folder }...
# review: new
transfer-another-account = toinen tili
# review: new
transfer-folder-gone = kohdekansiota ei ole enää
# review: new
transfer-not-on-server = viesti ei ole enää palvelimella
# review: new
transfer-not-moved = { $count ->
   *[other] Toiselle tilille ei voitu siirtää: { $messages } ({ $reason })
}
# review: new
transfer-not-copied = { $count ->
   *[other] Toiselle tilille ei voitu kopioida: { $messages } ({ $reason })
}
# review: new
transfer-none-moved = Yhtään viestiä ei voitu siirtää
# review: new
transfer-none-copied = Yhtään viestiä ei voitu kopioida

## Messages as files

# review: new
export-not-in-time = viestiä ei voitu ladata ajoissa
# review: new
export-not-saved = Tallentamatta jäi { $failed }/{ $messages } ({ $problems })
# review: new
export-not-attached = viestejä ei voitu liittää: { $error }
# the status bar after Save As with several: "Tallennettu: 3 viestiä. Kohde: Työpöytä"
# review: new
saved-to = { $count ->
   *[other] Tallennettu: { $messages }. Kohde: { $folder }
}
# review: new
download-progress = Ladataan { $done }/{ $total }
# review: new
download-done = Ladattu { $size }
# review: new
downloading-messages = { $count ->
   *[other] Ladataan: { $messages }...
}
# the status bar after files are dropped on a folder: "Lisätty: 3 viestiä. Kohde: Arkisto"
# review: new
import-put = { $count ->
   *[other] Lisätty: { $messages }. Kohde: { $folder }
}
# review: new
import-not-put = Näitä ei lisätty kansioon:

    { $problems }

## Problems the windows show

# review: new
error-store = paikallinen tietovarasto: { $error }
# review: new
error-not-found = ei löytynyt
# review: new
error-closed = sovellus sulkeutuu
# review: new
error-other-account = selain kirjautui tilille { $email }, ei tälle tilille
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = palvelin ei hyväksynyt kirjautumista ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = yhteys palvelimeen epäonnistui ({ $reason })
# review: new
error-in-use = sitä ei voi poistaa, kun tilit kirjautuvat sillä: { $accounts }
# review: new
error-turned-off = tämä kirjautumissovellus on poistettu käytöstä uusilta tileiltä
# review: new
error-folder-name = kansion nimessä on oltava 1-200 merkkiä, eikä siinä saa olla ohjausmerkkejä
# review: new
error-folder-separator = tällä palvelimella kansion nimessä ei voi olla merkkiä ”{ $separator }”
# review: new
error-folder-special = Saapuneet-kansiota ja erikoiskansioita ei voi nimetä uudelleen tai poistaa
# review: new
error-no-recipients = viestillä ei ole vastaanottajia
# review: new
error-bad-address = ”{ $address }” ei ole sähköpostiosoite
# review: new
error-not-own-address = { $address } ei ole tämän tilin lähettäjäosoitteita. Lisää se tilin ominaisuuksien kenttään ”Muut osoitteet, joista lähetät”.
# review: new
rule-query-refused = Säännöt eivät voi suodattaa kansion tai päivämäärän mukaan ({ $words }).
# review: new
rule-no-query = Anna saapuvien viestien hakuehdot.
# review: new
rule-no-action = Valitse säännölle vähintään yksi toiminto.
# review: new
error-attachment = Tiedostoa { $path } ei voitu lukea: { $error }
# review: new
error-no-drafts = tilillä ei ole Luonnokset-kansiota, johon viestin voisi tallentaa
# review: new
error-draft-attachment = luonnoksen liitettä ei voitu säilyttää: { $error }
# review: new
error-password-not-saved = salasanaa ei voitu tallentaa seuraavaa käynnistystä varten: { $error }
# review: new
error-sign-in-not-saved = uusia kirjautumistietoja ei voitu tallentaa seuraavaa käynnistystä varten: { $error }
# review: new
error-import-unreadable = Tiedostoa { $path } ei voi lukea: { $error }
# review: new
error-import-too-large = Tiedosto { $path } on suurempi kuin 50 Mt
# review: new
error-import-not-mail = Tiedosto { $path } ei ole sähköpostiviesti
# review: new
error-list-answered = postituslistan palvelin palautti tilan { $status }
# review: new
error-not-built = viestiä ei voitu muodostaa
# review: new
error-outbox-waits = { $count ->
    [one] viesti odottaa Lähtevät-kansiossa ja lähetetään seuraavalla lähetyksellä ja vastaanotolla
   *[other] { $count } viestiä odottaa Lähtevät-kansiossa ja ne lähetetään seuraavalla lähetyksellä ja vastaanotolla
}
# review: new
error-draft-not-removed = viestin aiempaa luonnosta ei voitu poistaa Luonnokset-kansiosta: { $reason }
# review: new
error-sent-but = viesti lähetettiin, mutta { $problem }
# review: new
error-sent-still-in-outbox = se on yhä Lähtevät-kansiossa: { $error }
# review: new
error-sent-no-copy = kopiota ei voitu tallentaa Lähetetyt-kansioon: { $reason }
# review: new
error-no-password = tilillä ei ole salasanaa
# review: new
error-no-sign-in = tilillä ei ole kirjautumista
# review: new
error-provider-missing = tämä versio ei voi kirjautua palveluun { $provider }: onko sen kirjautumissovellus poistettu?
# review: new
error-provider-servers = tämän tilin palvelimet eivät vastaa sen kirjautumissovelluksen palvelimia
# review: new
error-app-scopes = { $reason }. Postipalvelin ei hyväksynyt kirjautumissovelluksen tunnusta: tarkista, että sovelluksen käyttöoikeudet (scopes) sallivat postin käytön
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google ei ole vielä vahvistanut Inbox Classicia, joten se sallii kirjautumisen sillä vain testikäyttäjille. Käytä omaa Google-kirjautumissovellustasi tai sovellussalasanaa, tai ota se käyttöön kohdassa Kirjautumissovellukset (Tiedosto > Tilit), jos olet testikäyttäjä.
# review: new
sign-in-off-other = Se poistettiin käytöstä kohdassa Kirjautumissovellukset (Tiedosto > Tilit), jossa sen voi ottaa uudelleen käyttöön.
# review: new
sign-in-app-no-name = kirjautumissovellus tarvitsee nimen
# review: new
sign-in-app-no-client = asiakastunnus puuttuu
# review: new
sign-in-app-no-scopes = kirjautumissovellus tarvitsee käyttöoikeudet (scopes), jotka antavat pääsyn postiin
# review: new
sign-in-app-bad-host = palvelimen { $server } osoite puuttuu tai ei ole kelvollinen palvelimen nimi
# review: new
sign-in-app-plain = palvelimen { $server } on käytettävä SSL/TLS- tai STARTTLS-suojausta
# review: new
sign-in-app-not-checked = myöntäjää ei ole vielä tarkistettu
# review: new
sign-in-app-issuer-changed = myöntäjä muuttui: kirjoita asiakassalaisuus uudelleen tai poista se
# review: new
sign-in-register-google = Luo Google Cloud Consolessa OAuth-asiakas, jonka tyyppi on Desktop app, ja lisää sen suostumusnäyttöön käyttöoikeus https://mail.google.com/. Kun sovellus on testivaiheessa, vain sen testikäyttäjät voivat kirjautua.
# review: new
sign-in-register-microsoft = Rekisteröi Microsoft Entrassa sovellus, jonka alusta on Mobile and desktop applications, uudelleenohjaus-URI http://localhost ja julkiset asiakasvuot sallittuina, sekä delegoidut käyttöoikeudet IMAP.AccessAsUser.All, SMTP.Send ja offline_access. Jos sovellus on vain organisaatiollesi, käytä myöntäjänä osoitetta https://login.microsoftonline.com/<vuokraajan tunnus>/v2.0.
# review: new
sign-in-register-other = Rekisteröi natiivi (julkinen) asiakas alla olevalla uudelleenohjaus-URI:lla. Palveluntarjoajan on sallittava siinä mikä tahansa portti (RFC 8252). Lisää käyttöoikeus, jolla palveluntarjoaja antaa pääsyn postiin.

## Calendar invitations

# review: new
repeats = Toistuu
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Joka päivä
       *[other] { $interval } päivän välein
    }
    [week] { $interval ->
        [one] Joka viikko
       *[other] { $interval } viikon välein
    }
    [month] { $interval ->
        [one] Joka kuukausi
       *[other] { $interval } kuukauden välein
    }
   *[year] { $interval ->
        [one] Joka vuosi
       *[other] { $interval } vuoden välein
    }
}
# "Joka viikko, päivinä: maanantai, keskiviikko"
# review: new
repeats-on = { $repeats }, päivinä: { $days }
# "Joka viikko, 10 kertaa"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, kerran
   *[other] { $repeats }, { $count } kertaa
}
# review: new
day-monday = maanantai
# review: new
day-tuesday = tiistai
# review: new
day-wednesday = keskiviikko
# review: new
day-thursday = torstai
# review: new
day-friday = perjantai
# review: new
day-saturday = lauantai
# review: new
day-sunday = sunnuntai

## AI agents

# review: new
agent-level-read = Lukea postia: kansiot, viestiluettelo, haku ja viestit
# review: changed
agent-level-organize = Järjestellä postia: luettu-tila, liput, roskaposti, siirtäminen, arkistointi, uudet kansiot, poistaminen Poistetut-kansioon ja postituslistojen tilausten peruuttaminen, kun hyväksyt sen
# review: new
agent-level-drafts = Kirjoittaa luonnoksia, jotka sinä lähetät
# review: new
agent-level-send = Lähettää postia, jokaisen viestin vasta hyväksyntäsi jälkeen
# review: new
agent-connect-title = { $program } haluaa käyttää postiasi
# review: new
agent-connect-detail = Tekoälyagentti pyysi saada toimia Inbox Classicin kanssa. Valitse, mitä se saa tehdä ja mitkä tilit se näkee. Voit muuttaa tätä myöhemmin kohdassa Työkalut > Tekoälyagentit.

    Agentit lukevat muiden kirjoittamaa postia, ja viesti voi yrittää huijata niitä. Inbox Classic kysyy sinulta aina, ennen kuin agentti lähettää mitään.
# review: new
agent-reply-to = Vastaus viestiin ”{ $subject }”
# review: new
agent-reply-all-on = Vastaus kaikille viestiin ”{ $subject }”
# review: new
agent-forward-of = Edelleenvälitys: ”{ $subject }”
# review: new
agent-never-written-one = Et ole koskaan kirjoittanut osoitteeseen { $address }.
# review: new
agent-never-written-many = Et ole koskaan kirjoittanut { $count } näistä osoitteista.
# review: new
agent-send-title = { $program } haluaa lähettää tämän viestin
# review: new
agent-send-detail = Tarkista vastaanottajat ja viestin sisältö. Kun vahvistat, viesti odottaa { $seconds } sekuntia Lähtevät-kansiossa, jossa voit vielä poistaa sen.
# review: new
agent-change-title = Mitä { $program } saa tehdä
# review: new
agent-change-allowed = Muuta, mitä tämän ohjelman tekoälyagentit saavat tehdä postillesi.
# review: new
agent-change-refused = Estit tämän ohjelman käyttöoikeuden. Salli se, jotta sen agentit saavat taas pääsyn postiisi.
# review: new
agent-log-taken-back = { $entry } (peruttu)
# review: new
agent-files = Tiedostot: { $files }
# review: new
agent-undo-refused = Sitä ei voi perua.
# review: new
agent-undo-refused-why = Sitä ei voi perua: { $reason }.
# review: new
agent-undo-impossible = tätä ei voi perua
# review: new
agent-undo-not-in-folder = viesti ei ole enää siinä kansiossa
# review: new
agent-undo-not-arrived = viesti ei ole (vielä) kansiossa, johon se siirrettiin
# review: new
agent-undo-sent = viesti on jo lähetetty
# review: new
agent-original-not-downloaded = alkuperäistä viestiä ei ole vielä ladattu. Avaa se ensin
# review: new
agent-turned-away = Torjuttu
# review: new
agent-can-nothing = Ei mitään
# review: new
agent-can-read = lukea
# review: new
agent-can-organize = järjestellä
# review: new
agent-can-drafts = kirjoittaa luonnoksia
# review: new
agent-can-send = lähettää hyväksynnälläsi
# "lukea, järjestellä ja kirjoittaa luonnoksia"
# review: new
agent-can-list = { $first } ja { $last }
# review: new
agent-accounts = { $count ->
    [0] ei tilejä
    [one] { $count } tili
   *[other] { $count } tiliä
}
# "lukea ja järjestellä; 1 tili"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Tätä viestiä ei voi lukea.
# review: new
agent-encrypted-original = Tämä viesti on salattu: agentti ei voi vastata siihen tai välittää sitä, koska se ei osaa salata.
# review: new
agent-encrypted = Tämä viesti on salattu. Vain käyttäjä voi lukea sen Inbox Classicissa.
# review: new
list-encrypted = Salattu viesti
# review: new
agent-log-composed = Avasi viestin ”{ $subject }” uutena viestinä, jonka viimeistelet
# review: new
agent-log-refused = Et lähettänyt viestiä ”{ $subject }”
# review: new
agent-log-sent = Lähetti viestin ”{ $subject }”, vastaanottaja: { $to }
# review: new
agent-log-draft = Tallensi luonnoksen ”{ $subject }”
# review: new
agent-log-read = Merkitsi luetuksi: ”{ $subject }”
# review: new
agent-log-unread = Merkitsi lukemattomaksi: ”{ $subject }”
# review: new
agent-log-flagged = Liputti: ”{ $subject }”
# review: new
agent-log-unflagged = Poisti lipun: ”{ $subject }”
# review: new
agent-log-deleted = Poisti: ”{ $subject }”
# review: new
agent-log-moved = Siirsi: ”{ $subject }”. Kohde: { $folder }
# review: new
agent-log-junk = Merkitsi roskapostiksi: ”{ $subject }”
# review: new
agent-log-not-junk = Merkitsi ei-roskapostiksi: ”{ $subject }”
# review: new
agent-log-archived = Arkistoi: ”{ $subject }”
# review: new
agent-log-folder = Loi kansion ”{ $name }”
# review: new
agent-log-unsubscribed = Peruutti tilauksen listalta, jolta tuli ”{ $subject }”
# review: new
agent-log-unsubscribe-failed = Tilauksen peruuttaminen listalta, jolta tuli ”{ $subject }”, epäonnistui: { $reason }
# review: new
agent-log-unsubscribe-refused = Et peruuttanut tilausta: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [one] { $program } haluaa peruuttaa tilauksesi postituslistalta
   *[other] { $program } haluaa peruuttaa tilauksesi { $count } postituslistalta
}
# review: new
agent-unsubscribe-detail = Inbox Classic pyytää jokaista alla olevaa listaa lopettamaan lähettämisen sinulle sillä yhden napsautuksen tavalla, jota lista tarjoaa. Mitään muuta ei lähetetä, ja jo saamasi viestit pysyvät paikoillaan.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = palveluntarjoaja ei antanut päivitystunnusta (refresh token)
# review: new
sign-in-no-account = palveluntarjoaja ei kertonut, mikä tili kirjautui
# review: new
sign-in-not-finished = kirjautuminen ei ole päättynyt
# review: new
secrets-unavailable = { $store } ei ole käytettävissä
# review: new
secrets-unavailable-why = { $store } ei ole käytettävissä: { $error }
# review: new
secrets-windows = Tunnistetietojen hallinta
# review: new
secrets-mac = Avainnippu
# review: new
secrets-linux = järjestelmän avainnippu (Secret Service)
# review: new
error-no-such-file = tiedostoa ei ole olemassa
# review: new
cards-file-too-big = Tämä tiedosto on liian suuri ollakseen osoitekirja.
# review: new
ui-sender-added = { $name } lisättiin osoitekirjaan.
# review: new
ui-sender-known = { $name } on jo osoitekirjassa.
# review: new
ui-sender-none = Tämän viestin lähettäjällä ei ole lisättävää sähköpostiosoitetta.
# review: new
card-name-needed = Yhteystiedolla ei ole nimeä eikä sähköpostiosoitetta.
# a file of Import Address Book that could not be read: "contacts.vcf: tiedostoa ei ole olemassa"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Koodi lähettäjältä { $domain }
# review: new
otp-copy = Kopioi
# review: new
otp-note = Syötä se vain sivustolla { $domain }.
# review: new
otp-old = Tämä koodi lähetettiin yli tuntia ennen kuin avasit sen, ja se on luultavasti vanhentunut.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } osallistuja
       *[other] { $count } osallistujaa
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } on koodisi palveluun { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Voimassa
# review: new
pgp-key-expires = Voimassa { $date } asti
# review: new
pgp-key-expired = Vanhentui { $date }
# review: new
pgp-key-revoked = Mitätöity
# review: new
pgp-key-revoked-why = Mitätöity: { $reason }
# review: new
pgp-key-not-valid = Ei voimassa
# review: new
pgp-key-locked = Ei käytettävissä: avainta suojaava avain ei ole enää tallessa ({ $store }). Tuo sen varmuuskopio uudelleen.
# review: new
pgp-source-own = Luotu Inbox Classicissa
# review: new
pgp-source-file = Tuotu tiedostosta
# review: new
pgp-source-paste = Liitetty
# review: new
pgp-source-attachment = Viestistä
# review: new
pgp-source-vcard = Yhteystietokortista
# review: new
pgp-source-wkd = Lähettäjän postipalveluntarjoajalta
# review: new
pgp-source-keyserver = Palvelusta keys.openpgp.org
# review: new
pgp-source-autocrypt = Viestin Autocrypt-otsakkeesta
# review: new
pgp-error-no-store = Yksityisiä avaimia suojaa { $store }, jota ei voi käyttää: { $error }
# review: new
pgp-error-wrong-passphrase = Salalause on väärä.
# review: new
pgp-error-not-a-key = Tämä ei ole OpenPGP-avain.
# review: new
pgp-error-too-large = Avain on liian suuri.
# review: new
pgp-error-unusable = Avain käyttää vanhaa tai heikkoa salausta, eikä sitä voi käyttää.
# review: new
pgp-imported-private = { $count ->
    [one] Yksityinen avaimesi tuotiin.
   *[other] Yksityisiä avaimia tuotiin: { $count }.
}
# review: new
pgp-imported-public = { $count ->
    [one] Yksi avain tuotiin.
   *[other] Avaimia tuotiin: { $count }.
}
# review: new
pgp-imported-pending = Osoitteille { $addresses } on jo käytössä toinen avain: uusi odottaa yhteystiedossa, kunnes valitset sen.
# review: new
pgp-error-needs-passphrase = Yksityinen avain on suojattu salalauseella. Kirjoita se, niin avain tuodaan.
# review: new
pgp-error-mismatch = Yksityinen avain ei kuulu julkiseen avaimeensa. Sitä on ehkä muutettu.
# review: new
pgp-file-name-public = { $who } julkinen avain.asc
# review: new
pgp-file-name-private = { $who } yksityisen avaimen varmuuskopio.asc
# review: new
pgp-pending = Osoitteelle { $address } löytyi eri avain { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Allekirjoittaja: { $signer }, avain vahvistettu
# review: new
pgp-part-signed = Allekirjoittaja: { $signer } (avainta ei ole vahvistettu)
# review: new
pgp-part-other = Allekirjoittaja: { $signer }, joka ei ole lähettäjä
# review: new
pgp-part-unknown-key = Allekirjoitettu, mutta avain on tuntematon
# review: new
pgp-part-not-signed = Ei allekirjoitettu
# review: new
pgp-part-not-checked = Allekirjoitusta ei tarkistettu
# review: new
pgp-part-encrypted = Salattu. { $signature }
# review: new
pgp-part-no-key = Salattu avaimelle, jota sinulla ei ole
# review: new
pgp-part-changed = Salattua osaa muutettiin matkalla, eikä sitä näytetä
# review: new
pgp-part-unprotected = Salattu ilman suojausta muutoksia vastaan, ei näytetä
# review: new
pgp-part-broken = Salattua osaa ei voi lukea
# review: new
pgp-why-mismatch = Allekirjoitus ei vastaa tätä tekstiä
# review: new
pgp-why-weak-hash = Allekirjoitus käyttää algoritmia { $hash }, joka ei ole enää turvallinen
# review: new
pgp-why-key-expired = Allekirjoitettu sen jälkeen, kun avain vanhentui { $date }
# review: new
pgp-why-key-revoked = Allekirjoitettu mitätöidyllä avaimella
# review: new
pgp-why-not-signing-key = Allekirjoitettu avaimella, jolla ei saa allekirjoittaa
# review: new
pgp-why-from-future = Allekirjoitus on päivätty tulevaisuuteen
# review: new
pgp-why-signature-expired = Allekirjoitus on vanhentunut
# review: new
pgp-why-key-not-valid = Allekirjoitettu avaimella, joka ei ole voimassa
# review: new
pgp-why-not-for-you = Allekirjoitettu muille vastaanottajille ja välitetty sinulle
# review: new
pgp-why-not-key-in-use = Allekirjoitettu eri avaimella kuin osoitteelle { $address } käytetty
# review: new
pgp-part-pictures-loaded = { $label }. Kuvat ladattiin internetistä
# review: new
pgp-error-no-own-key = Sinulla ei ole osoitteelle { $address } avainta, jolla allekirjoittaa tai salata. Luo avain kohdassa Työkalut > Salausavaimet tai poista Allekirjoita ja Salaa käytöstä.
# review: new
pgp-error-missing-keys = { $count ->
    [one] Vastaanottajalla { $addresses } ei ole avainta, jolle salata.
   *[other] Näillä vastaanottajilla ei ole avainta, jolle salata: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Tämä viesti lainaa tai välittää salatun viestin, joten sen voi lähettää vain salattuna. Ota Salaa käyttöön tai poista lainattu teksti.
# review: new
pgp-error-protect = Viestiä ei voitu allekirjoittaa tai salata: { $reason }
# review: new
pgp-found-keys = Avain löytyi: { $addresses }.
# review: new
pgp-found-none = Avainta ei löytynyt: { $addresses }. Pyydä heitä lähettämään sinulle julkinen avaimensa.
# review: new
pgp-found-no-key = Avainta ei löytynyt.
# review: new
pgp-find-unavailable = Avaimia ei voitu hakea nyt: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org lähetti vahvistuslinkin osoitteeseen { $addresses }. Avaimesi julkaistaan siellä, kun napsautat linkkiä.
# review: new
pgp-publish-done = Avaimesi on julkaistu palvelussa keys.openpgp.org osoitteelle { $addresses }.
# review: new
pgp-publish-failed = Avainta ei voitu julkaista: { $error }
# review: changed
pgp-keyserver-off = Avainten haku palvelusta keys.openpgp.org on poistettu käytöstä kohdassa { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Salattu ja allekirjoitettu: vain sinä ja { $addresses } voitte lukea sen.
   *[other] Salattu ja allekirjoitettu: vain sinä ja sen { $count } vastaanottajaa voitte lukea sen.
}
# review: new
pgp-compose-encrypt-ready = Viesti salataan ja allekirjoitetaan. Lisää vastaanottajia, joiden avaimet sinulla on.
# review: new
pgp-compose-missing = { $count ->
    [one] Vastaanottajalla { $addresses } ei ole avainta, joten viestiä ei voi vielä salata.
   *[other] { $count } vastaanottajalla ei ole avainta, joten viestiä ei voi vielä salata: { $addresses }.
}
# review: new
pgp-compose-looking = Haetaan avaimia: { $addresses }...
# review: new
pgp-compose-signed = Allekirjoitettu: vastaanottajat voivat tarkistaa, että viesti on sinulta eikä sitä ole muutettu.
# review: new
pgp-compose-reply-clear = Ei salattu, vaikka viesti, johon se vastaa tai jonka se välittää, oli salattu.
# review: new
pgp-compose-encrypted-files = Viestiin on liitetty salatun viestin tiedostoja, joten sen voi lähettää vain salattuna. Ota Salaa käyttöön tai poista nämä tiedostot.
# review: new
pgp-compose-sign-tip = Allekirjoita viesti avaimellasi, niin vastaanottajat voivat tarkistaa, että se on sinulta eikä sitä ole muutettu
# review: new
pgp-compose-sign-tip-encrypted = Salattu viesti allekirjoitetaan aina
# review: new
pgp-compose-encrypt-tip = Salaa viesti, niin vain sinä ja sen vastaanottajat voitte lukea sen
# review: new
pgp-compose-make-key = Sinulla ei ole vielä avainta osoitteelle { $address }. Luodaanko avain nyt? Sen avulla viestisi voidaan allekirjoittaa ja salata.
# review: new
pgp-compose-key-unusable = Avaintasi osoitteelle { $address } ei voi käyttää ({ $state }). Avaa Salausavaimet ja tuo sen varmuuskopio tai luo uusi avain.
# review: new
pgp-compose-encrypt-off-quote = Tämä viesti lainaa tai välittää salatun viestin. Ilman salausta sitä ei voi lähettää, ennen kuin poistat lainatun sisällön. Poistetaanko salaus silti käytöstä?
# review: new
pgp-compose-encrypt-off-reply = Tämä viesti vastaa salattuun viestiin tai välittää sen. Ilman salausta kuka tahansa, joka käsittelee viestiäsi matkalla, voi lukea sen. Poistetaanko salaus käytöstä?
# review: new
pgp-recipient-verified = Avain vahvistettu
# review: new
pgp-recipient-found = Avainta ei ole vahvistettu
# review: new
pgp-recipient-own = Oma avaimesi
# review: new
pgp-recipient-looking = Haetaan avainta...
# review: new
pgp-recipient-missing = Ei avainta
# review: new
pgp-recipient-not-found = Ei avainta: avainta ei löytynyt { $date }
# review: new
pgp-recipient-unusable = Avainta ei voi käyttää: { $state }
# review: new
pgp-recipients-intro = Viesti salataan jokaisen vastaanottajan avaimelle ja omallesi.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Yhdellä vastaanottajalla ei ole avainta, jolle salata. Etsi hänen avaimensa, poista hänet viestistä tai lähetä viesti ilman salausta.
   *[other] { $count } vastaanottajalla ei ole avainta, jolle salata. Etsi heidän avaimensa, poista heidät viestistä tai lähetä viesti ilman salausta.
}
# review: new
pgp-details-part = Osa { $number }: { $label }
# review: new
pgp-details-signed = Allekirjoitettu { $when } avaimella { $key }
# review: new
pgp-details-unknown-key = Allekirjoitettu avaimella { $key }, jota sinulla ei ole
# review: new
pgp-details-opened = Salattu avaimellesi { $key }
# review: new
pgp-details-for = Salattu avaimille { $keys }
# review: new
pgp-details-plain = Ei allekirjoitettu eikä salattu
# review: new
pgp-bar-parts = Tässä viestissä on { $count } osaa: { $list }. Jokainen osa kertoo, miten se on suojattu.
# review: new
pgp-bar-count-verified = vahvistettuja { $count }
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 allekirjoitettu tai salattu
   *[other] { $count } allekirjoitettua tai salattua
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 vaatii huomiota
   *[other] { $count } vaatii huomiota
}
# review: new
pgp-bar-count-neutral = ilman vahvistettua allekirjoitusta { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Asetukset
# review: new
setup-part-preferences = Ikkunoiden asetukset
# review: new
setup-part-accounts = Tilit
# review: new
setup-part-sign-in-apps = Kirjautumissovellukset
# review: new
setup-part-contacts = Yhteystiedot ja ryhmät
# review: new
setup-part-keys = Salausavaimet
# review: new
setup-part-rules = Viestisäännöt
# review: new
setup-part-trusted-senders = Luotetut lähettäjät
# review: new
setup-holds-settings = { $count ->
    [one] 1 asetus
   *[other] { $count } asetusta
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 ikkunan asetus
   *[other] { $count } ikkunoiden asetusta
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 tili
   *[other] { $count } tiliä
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 kirjautumissovellus
   *[other] { $count } kirjautumissovellusta
}
# review: new
setup-holds-built-in = Mitkä sisäänrakennetut kirjautumissovellukset ovat käytössä
# review: new
setup-holds-contacts = { $count ->
    [one] 1 yhteystieto
   *[other] { $count } yhteystietoa
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 ryhmä
   *[other] { $count } ryhmää
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 oma avain
   *[other] { $count } omaa avainta
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 yhteystiedon avain
   *[other] { $count } yhteystietojen avainta
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 sääntö
   *[other] { $count } sääntöä
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 luotettu lähettäjä
   *[other] { $count } luotettua lähettäjää
}
# review: new
setup-sign-in-password = Salasana
# review: new
setup-account-secret-password = Sen salasana on tiedostossa.
# review: new
setup-account-secret-token = Sen kirjautuminen on tiedostossa.
# review: new
setup-account-asks-password = Se kysyy salasanaansa tuonnin jälkeen.
# review: new
setup-account-signs-in-again = Kirjaudut siihen uudelleen tuonnin jälkeen.
# review: new
setup-account-here = Se on jo määritetty tässä, joten se ohitetaan.
# review: new
setup-account-no-app = Se kirjautuu sovelluksella { $app }, jota ei ole määritetty tässä. Tuo myös kirjautumissovellukset.
# review: new
setup-invalid-address = ”{ $address }” ei ole sähköpostiosoite.
# review: new
setup-invalid-server = Palvelimella { $server } ei ole käyttökelpoista nimeä tai porttia.
# review: new
setup-invalid-user = Sillä ei ole käyttäjänimeä.
# review: new
setup-invalid-sign-in = Se kirjautuu tavalla, jota Inbox Classic ei tunne.
# review: new
setup-error-empty = Tiedosto on tyhjä.
# review: new
setup-error-too-large = Tiedosto on liian suuri ollakseen Inbox Classicin asetustiedosto.
# review: new
setup-error-not-setup = Tämä tiedosto ei ole Inbox Classicin asetustiedosto.
# review: new
setup-error-damaged = Asetustiedosto on vioittunut, eikä sitä voi lukea.
# review: new
setup-error-newer = Tämä asetustiedosto on tallennettu uudemmalla Inbox Classicilla ({ $version }). Päivitä Inbox Classic ja tuo tiedosto sitten uudelleen.
# review: new
setup-error-needs-passphrase = Tämä asetustiedosto on suojattu salalauseella. Kirjoita salalause, jolla se tallennettiin.
# review: new
setup-error-wrong-passphrase = Tämä ei ole salalause, jolla asetustiedosto tallennettiin.
# review: new
setup-error-changed = Asetustiedostoa muutettiin tai se vioittui tallennuksen jälkeen, joten sitä ei voi tuoda.
# review: new
setup-error-read = Asetustiedostoa ei voitu lukea: { $error }
# review: new
setup-error-write = Asetuksia ei voitu tallentaa: { $error }
# review: new
setup-error-no-parts = Valitse vähintään yksi osa.
# review: new
setup-left-out = { $count ->
    [one] Osasta { $part } yhtä kohtaa ei voi käyttää, ja se jätetään pois.
   *[other] Osasta { $part } { $count } kohtaa ei voi käyttää, ja ne jätetään pois.
}
# review: new
setup-imported-settings = Asetukset korvattiin.
# review: new
setup-imported-preferences = Ikkunoiden asetukset korvattiin.
# review: new
setup-added-accounts = { $count ->
    [one] Lisättiin 1 tili.
   *[other] Lisättiin { $count } tiliä.
}
# review: new
setup-skipped-here = { $address } on jo määritetty tässä, joten se ohitettiin.
# review: new
setup-skipped-no-app = { $address } ohitettiin: se kirjautuu sovelluksella { $app }, jota ei ole määritetty tässä.
# review: new
setup-skipped-invalid = { $address } ohitettiin: { $reason }
# review: new
setup-asks-password = { $address } kysyy salasanaansa, kun se muodostaa yhteyden.
# review: new
setup-signs-in-again = { $address } pyytää sinua kirjautumaan uudelleen, kun se muodostaa yhteyden.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Lisättiin 1 kirjautumissovellus.
   *[other] Lisättiin { $count } kirjautumissovellusta.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 kirjautumissovellus on jo määritetty tässä.
   *[other] { $count } kirjautumissovellusta on jo määritetty tässä.
}
# review: new
setup-added-contacts = { $count ->
    [one] Osoitekirjaan lisättiin 1 yhteystieto.
   *[other] Osoitekirjaan lisättiin { $count } yhteystietoa.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 yhteystieto on jo osoitekirjassa.
   *[other] { $count } yhteystietoa on jo osoitekirjassa.
}
# review: new
setup-added-groups = { $count ->
    [one] Lisättiin tai täydennettiin 1 ryhmä.
   *[other] Lisättiin tai täydennettiin { $count } ryhmää.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Lisättiin 1 oma avain.
   *[other] Lisättiin { $count } omaa avainta.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Lisättiin 1 yhteystiedon avain.
   *[other] Lisättiin { $count } yhteystietojen avainta.
}
# review: new
setup-added-rules = { $count ->
    [one] Lisättiin 1 viestisääntö.
   *[other] Lisättiin { $count } viestisääntöä.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 viestisääntö on jo täällä.
   *[other] { $count } viestisääntöä on jo täällä.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 viestisääntö koskee tiliä, jota täällä ei ole, joten se ohitettiin.
   *[other] { $count } viestisääntöä koskee tilejä, joita täällä ei ole, joten ne ohitettiin.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 viestisääntö siirtää viestejä kansioon, joka ilmestyy, kun sen tili synkronoidaan.
   *[other] { $count } viestisääntöä siirtää viestejä kansioihin, jotka ilmestyvät, kun niiden tilit synkronoidaan.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Lisättiin 1 luotettu lähettäjä.
   *[other] Lisättiin { $count } luotettua lähettäjää.
}
# review: new
setup-nothing = Mitään ei tuotu.
# review: new
setup-account-servers = { $imap } ja { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classicin asetukset ja tilit
# review: new
setup-skipped-unreachable = { $name } ohitettiin: sen kirjautumispalveluun ei saatu yhteyttä. Lisää se uudelleen kohdassa Kirjautumissovellukset.
# review: new
attachment-runs-programs = ”{ $name }” voi suorittaa ohjelmia, joten Inbox Classic ei avaa sitä. Tallenna se ja avaa se sitten itse, jos luotat sen lähteeseen.
# review: new
attachment-decrypted-note = Tämä liite on peräisin salatusta viestistä. Jotta liitteen voi avata, Inbox Classic tallentaa sen salaamattomana tähän tietokoneeseen omaan kansioosi, jonka Inbox Classic tyhjentää vuorokauden kuluttua.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Palvelin ei siirtänyt viestiä kansioon { $folder }, joten { $messages } on taas kansiossa { $from }: { $reason }
   *[other] Palvelin ei siirtänyt viestejä kansioon { $folder }, joten { $messages } on taas kansiossa { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Palvelin ei poistanut viestiä, joten { $messages } on taas kansiossa { $from }: { $reason }
   *[other] Palvelin ei poistanut viestejä, joten { $messages } on taas kansiossa { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Palvelin ei arkistoinut viestiä, joten { $messages } on taas kansiossa { $from }: { $reason }
   *[other] Palvelin ei arkistoinut viestejä, joten { $messages } on taas kansiossa { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Palvelin ei merkinnyt viestiä luetuksi, joten { $messages } on taas lukematta: { $reason }
   *[other] Palvelin ei merkinnyt viestejä luetuiksi, joten { $messages } on taas lukematta: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Palvelin ei merkinnyt viestiä lukemattomaksi, joten { $messages } on taas luettu: { $reason }
   *[other] Palvelin ei merkinnyt viestejä lukemattomiksi, joten { $messages } on taas luettu: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Palvelin ei muuttanut viestin lippuja, joten { $messages } on ennallaan: { $reason }
   *[other] Palvelin ei muuttanut viestien lippuja, joten { $messages } on ennallaan: { $reason }
}
