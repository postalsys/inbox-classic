# Suomi. Luonnos, odottaa äidinkielisen tarkistusta (katso core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Finnish: [one] and *[other]. Placeables are never inflected: a head noun takes the case, or a label and a colon.

## Counts and sizes

messages = { $count ->
    [one] { $count } viesti
   *[other] { $count } viestiä
}
# the separator of decimals in sizes: 2,4 Mt
decimal-separator = ,
size-bytes = { $count ->
    [one] { $count } tavu
   *[other] { $count } tavua
}
size-kb = { $size } kt
size-mb = { $size } Mt
size-gb = { $size } Gt
send-delay-off = Ei käytössä
send-delay-seconds = { $count ->
    [one] { $count } sekunti
   *[other] { $count } sekuntia
}
# the status bar: "12 viestiä, 3 lukematonta"
list-counts = { $messages }, lukemattomia { $unread }
list-counts-selected = { $messages }, lukemattomia { $unread }, valittuna { $selected }
# the status bar while searching: "löytyi 12, lukemattomia 3"
list-counts-found = Löytyi { $found }, lukemattomia { $unread }
list-counts-found-selected = Löytyi { $found }, lukemattomia { $unread }, valittuna { $selected }
list-counts-none = Viestejä ei löytynyt

## Special folders, as Outlook names them

folder-inbox = Saapuneet
folder-sent = Lähetetyt
folder-deleted = Poistetut
folder-drafts = Luonnokset
folder-junk = Roskaposti
folder-archive = Arkisto

## The reading pane

reader-no-message = Viestiä ei ole valittu.
reader-downloading = Ladataan viestiä…
reader-downloading-detail = Viesti näkyy tässä, kun lataus on valmis.
reader-downloading-size = Viestin koko on { $size }. Se näkyy tässä, kun se on ladattu.
reader-failed = Viestiä ei voitu ladata
reader-failed-network = Postipalvelimeen ei saatu yhteyttä ({ $reason }).
reader-failed-sign-in = Postipalvelin ei hyväksynyt kirjautumista ({ $reason }). Tarkista salasana tai kirjaudu uudelleen kohdassa Tiedosto > Tilit.
reader-failed-security = Yhteyttä postipalvelimeen ei voitu suojata ({ $reason }).
reader-failed-other = Postipalvelin vastasi: { $reason }.
reader-retry-note = Latausta yritetään uudelleen, kun yhteys tiliin palautuu.
reader-unreadable = Tätä viestiä ei voi näyttää: { $error }
message-source-title = Viestin lähdekoodi: { $subject }
message-source-untitled = Viestin lähdekoodi

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Lähettäjä
header-date = Päivämäärä
header-to = Vastaanottaja
header-cc = Kopio
header-sent = Lähetetty
header-subject = Aihe
header-security = Suojaus
header-part = Osa { $number }
quote-original = ----- Alkuperäinen viesti -----
fold-show-earlier = Näytä aiemmat viestit

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Viestiäsi ei toimitettu
bounce-delayed = Viestiäsi ei ole vielä toimitettu
bounce-delayed-note = Postipalvelimesi yrittää yhä toimittaa sitä. Sitä ei tarvitse lähettää uudelleen.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Näytä palautunut viesti
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Näytä viivästynyt viesti
bounce-what-to-do = Mitä voit tehdä:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Ei vielä mitään. Jos viestiä ei edelleenkään voida toimittaa, saat uuden ilmoituksen.
bounce-delayed-row-do = Ei vielä mitään. Postipalvelimesi yrittää yhä toimittaa viestiä, ja saat uuden ilmoituksen, jos se ei onnistu.
# folds the receiving server's own words
bounce-details = Tiedot
# a recipient the notice does not name
bounce-someone = Vastaanottaja
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Palvelin: { $server }
bounce-status = Tila: { $status }
bounce-reported-by = Ilmoittaja: { $server }
bounce-retry-minutes = Vastaanottava palvelin pyysi odottamaan { $count ->
    [one] minuutin
   *[other] { $count } minuuttia
} ennen seuraavaa yritystä.
bounce-retry-hours = Vastaanottava palvelin pyysi odottamaan { $count ->
    [one] tunnin
   *[other] { $count } tuntia
} ennen seuraavaa yritystä.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Estolista: { $lists }
bounce-user-unknown = Osoitetta ei ole olemassa
bounce-user-unknown-why = Vastaanottavalla palvelimella ei ole tämän osoitteen postilaatikkoa. Osoitteessa voi olla kirjoitusvirhe, tai se on voinut poistua käytöstä.
bounce-user-unknown-do = Tarkista osoitteen kirjoitusasu tai kysy henkilöltä osoitetta, jota hän nyt käyttää.
bounce-invalid-address = Osoite ei kelpaa
bounce-invalid-address-why = Osoite ei ole muodossa, johon postia voi lähettää.
bounce-invalid-address-do = Tarkista, onko osoitteessa kirjoitusvirheitä, kuten välilyöntejä tai puuttuvia kirjaimia. Tarkista myös, ettei @-merkin jälkeinen osa puutu.
bounce-mailbox-disabled = Postilaatikko on suljettu
bounce-mailbox-disabled-why = Osoite on olemassa, mutta postilaatikko on suljettu tai sitä ei enää käytetä.
bounce-mailbox-disabled-do = Ota henkilöön yhteyttä muulla tavalla ja kysy hänen nykyistä sähköpostiosoitettaan.
bounce-mailbox-full = Postilaatikko on täynnä
bounce-mailbox-full-why = Vastaanottajan postilaatikossa ei ole tilaa uudelle postille.
bounce-mailbox-full-do = Lähetä viesti uudelleen muutaman päivän kuluttua tai ilmoita asiasta henkilölle muulla tavalla. Suuret liitteet torjutaan ensimmäisinä.
bounce-spam-blocked = Torjuttu roskapostina
bounce-spam-blocked-why = Vastaanottava palvelin piti viestiä roskapostina.
bounce-spam-blocked-do = Poista viestistä roskapostilta vaikuttavaa sisältöä, kuten runsaita tai lyhennettyjä linkkejä ja suuria liitteitä, ja lähetä viesti uudelleen. Jos ongelma toistuu, ota yhteyttä postipalveluntarjoajaasi.
bounce-virus-detected = Torjuttu viruksen vuoksi
bounce-virus-detected-why = Vastaanottava palvelin löysi viestistä tai sen liitteistä viruksen tai muuta haitallista sisältöä.
bounce-virus-detected-do = Tarkista liitteet virustorjuntaohjelmalla. Jotkin palvelimet torjuvat kaikki ohjelmat ja arkistot, joten jaa tällaiset tiedostot mieluummin linkkinä.
bounce-ip-blocklisted = Postipalvelimesi on estolistalla
bounce-ip-blocklisted-why = Vastaanottava palvelin torjuu postin palvelimelta, joka lähetti viestisi, koska sen palvelimen osoite on estolistalla.
bounce-ip-blocklisted-do = Vika ei ole viestissä. Välitä tämä ilmoitus postipalveluntarjoajallesi ja pyydä heitä poistattamaan palvelin estolistalta.
bounce-domain-blocklisted = Verkkotunnus on estolistalla
bounce-domain-blocklisted-why = Vastaanottava palvelin torjuu viestin, koska osoitteesi verkkotunnus tai jokin viestin linkkien verkkotunnus on estolistalla.
bounce-domain-blocklisted-do = Jos viestissä on linkkejä, kokeile lähettää se ilman niitä. Muuten välitä tämä ilmoitus sille, joka hoitaa verkkotunnuksesi postin.
bounce-policy-blocked = Torjuttu vastaanottavan palvelimen sääntöjen vuoksi
bounce-policy-blocked-why = Vastaanottavan palvelimen säännöt eivät päästä tätä viestiä läpi esimerkiksi sen koon, liitteiden tai lähettäjän vuoksi.
bounce-policy-blocked-do = Palvelimen ilmoitus Tiedot-kohdassa kertoo usein syyn. Kysy vastaanottajalta, voiko hän ottaa vastaan tällaista postia.
bounce-geo-blocked = Torjuttu lähtöpaikan vuoksi
bounce-geo-blocked-why = Vastaanottava palvelin ei ota vastaan postia siitä maasta tai verkosta, jossa postipalvelimesi on.
bounce-geo-blocked-do = Ota henkilöön yhteyttä muulla tavalla tai kysy asiasta postipalveluntarjoajaltasi.
bounce-relay-denied = Palvelin ei välittänyt viestiä eteenpäin
bounce-relay-denied-why = Palvelin kieltäytyi toimittamasta viestiä eteenpäin, usein koska se lähetettiin kirjautumatta tai palvelimen kautta, joka ei käsittele tämän vastaanottajan postia.
bounce-relay-denied-do = Tarkista tilin lähtevän postin palvelin kohdassa Tiedosto > Tilit. Varmista myös, että palvelimelle kirjaudutaan.
bounce-auth-failure = Lähettäjäosoitettasi ei voitu vahvistaa
bounce-auth-failure-why = Vastaanottava palvelin ei voinut varmistaa, että viesti todella tuli verkkotunnuksestasi (SPF, DKIM tai DMARC).
bounce-auth-failure-do = Välitä tämä ilmoitus sille, joka hoitaa verkkotunnuksesi postin: sen asetukset on korjattava. Sillä välin lähettäminen palveluntarjoajasi oman palvelimen kautta voi auttaa.
bounce-rate-limited = Liikaa postia kerralla
bounce-rate-limited-why = Vastaanottava palvelin ottaa toistaiseksi vastaan vähemmän viestejä postipalvelimeltasi.
bounce-rate-limited-do = Odota hetki ja lähetä viesti uudelleen. Kun kirjoitat monille, lähetä harvemmille kerrallaan.
bounce-greylisting = Toimitusta lykätty hetkeksi
bounce-greylisting-why = Vastaanottava palvelin pyytää tuntemattomia lähettäjiä yrittämään hieman myöhemmin uudelleen. Se on yleinen roskapostin torjuntakeino.
bounce-greylisting-do = Ei mitään. Postipalvelimet yrittävät uudelleen itse, ja viesti toimitetaan yleensä tunnin kuluessa.
bounce-server-error = Vastaanottavalla palvelimella oli ongelma
bounce-server-error-why = Vastaanottavaan palvelimeen ei saatu yhteyttä, tai se ei voinut ottaa viestiä vastaan oman ongelmansa vuoksi.
bounce-server-error-do = Lähetä viesti myöhemmin uudelleen. Jos se epäonnistuu yhä, tarkista osoitteen @-merkin jälkeinen osa kirjoitusvirheiden varalta.
bounce-unknown = Ei toimitettu
bounce-unknown-why = Ilmoitus ei kerro selvästi syytä.
bounce-unknown-do = Palvelimen ilmoitus Tiedot-kohdassa voi kertoa lisää. Jos siitä ei ole apua, välitä ilmoitus postipalveluntarjoajallesi.

## Several messages selected

selection-title = { $count ->
    [one] { $count } viesti valittuna
   *[other] { $count } viestiä valittuna
}
selection-unread = Lukemattomia { $count }
selection-flagged = Liputettuja { $count }
delete-for-good-one = Tämä viesti poistetaan pysyvästi. Poistetaanko se?
delete-for-good-all = Nämä viestit ({ $count }) poistetaan pysyvästi. Poistetaanko ne?
delete-for-good-some = Viesteistä { $count }/{ $total } poistetaan pysyvästi. Poistetaanko viestit?
done-read = { $count ->
    [one] Merkitty luetuksi: { $messages }
   *[other] Merkitty luetuiksi: { $messages }
}
done-unread = { $count ->
    [one] Merkitty lukemattomaksi: { $messages }
   *[other] Merkitty lukemattomiksi: { $messages }
}
done-flagged = { $count ->
   *[other] Liputettu: { $messages }
}
done-unflagged = Lippu poistettu: { $messages }
done-deleted-for-good = { $count ->
   *[other] Poistettu pysyvästi: { $messages }
}
done-archived = { $count ->
   *[other] Arkistoitu: { $messages }
}
done-moved = { $count ->
   *[other] Siirretty: { $messages }. Kohde: { $folder }
}
done-copied = { $count ->
   *[other] Kopioitu: { $messages }. Kohde: { $folder }
}
done-moving = { $count ->
   *[other] Siirretään: { $messages }. Kohde: { $folder }...
}
done-copying = { $count ->
   *[other] Kopioidaan: { $messages }. Kohde: { $folder }...
}
done-moved-back = { $count ->
   *[other] Siirretty takaisin: { $messages }. Kohde: { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Keskustelua seurataan
   *[other] Seurataan { $count } keskustelua
}
done-unwatched = { $count ->
    [one] Keskustelun seuraaminen lopetettu
   *[other] { $count } keskustelun seuraaminen lopetettu
}
done-ignored = { $count ->
    [one] Keskustelu ohitetaan
   *[other] Ohitetaan { $count } keskustelua
}
done-unignored = { $count ->
    [one] Keskustelun ohittaminen lopetettu
   *[other] { $count } keskustelun ohittaminen lopetettu
}
their-folders = alkuperäiset kansiot
undo-move = Kumoa siirto
undo-delete = Kumoa poisto
undo-archive = Kumoa arkistointi
undo-junk = Kumoa roskapostimerkintä
undo-not-junk = Kumoa Ei roskapostia -merkintä
undo-send = Kumoa lähetys
nothing-to-undo = Ei mitään kumottavaa.
messages-gone = Viestejä ei ole enää.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Tässä kansiossa ei voi olla viestejä.
not-archived-here = Tämän kansion viestejä ei voi arkistoida.
not-emptied-here = Vain Poistetut- ja Roskaposti-kansiot voi tyhjentää.
next-unread-question = Kansiossa { $folder } ei ole enempää lukemattomia viestejä.

    Siirrytäänkö seuraavaan kansioon, jossa on lukemattomia viestejä: { $next }?
no-unread-left = Lukemattomia viestejä ei ole jäljellä.
empty-question = { $count ->
    [one] Tyhjennetäänkö kansio { $folder }?

        Sen viesti poistetaan pysyvästi. Sitä ei voi palauttaa.
   *[other] Tyhjennetäänkö kansio { $folder }?

        Sen viestit ({ $messages }) poistetaan pysyvästi. Niitä ei voi palauttaa.
}
no-junk-folder = Tilillä ei ole Roskaposti-kansiota, johon viestit voisi siirtää.
no-inbox-folder = Tilillä ei ole Saapuneet-kansiota, johon viestit voisi siirtää.
# the status bar after a flag in a colour: "2 viestiä liputettiin punaisella lipulla"
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

move-window-title-move = { $count ->
    [one] Siirrä viesti
   *[other] Siirrä { $count } viestiä
}
move-window-title-copy = { $count ->
    [one] Kopioi viesti
   *[other] Kopioi { $count } viestiä
}
move-window-prompt-move = { $count ->
    [one] Siirrä valittu viesti kohteeseen:
   *[other] Siirrä valitut { $count } viestiä kohteeseen:
}
move-window-prompt-copy = { $count ->
    [one] Kopioi valittu viesti kohteeseen:
   *[other] Kopioi valitut { $count } viestiä kohteeseen:
}
# the folders used last, over the folder tree
targets-recent = Viimeisimmät
# the folder the messages are in, which can not be chosen
target-current = { $folder } (nykyinen)
# a folder used last, with its account when there are several: "Arkisto (Työ)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Siirretään { $done }/{ $messages }. Kohde: { $folder }...
transfer-copying = Kopioidaan { $done }/{ $messages }. Kohde: { $folder }...
transfer-another-account = toinen tili
transfer-folder-gone = kohdekansiota ei ole enää
transfer-not-on-server = viesti ei ole enää palvelimella
transfer-not-moved = { $count ->
   *[other] Toiselle tilille ei voitu siirtää: { $messages } ({ $reason })
}
transfer-not-copied = { $count ->
   *[other] Toiselle tilille ei voitu kopioida: { $messages } ({ $reason })
}
transfer-none-moved = Yhtään viestiä ei voitu siirtää
transfer-none-copied = Yhtään viestiä ei voitu kopioida

## Messages as files

export-not-in-time = viestiä ei voitu ladata ajoissa
export-not-saved = Tallentamatta jäi { $failed }/{ $messages } ({ $problems })
export-not-attached = viestejä ei voitu liittää: { $error }
# the status bar after Save As with several: "Tallennettu: 3 viestiä. Kohde: Työpöytä"
saved-to = { $count ->
   *[other] Tallennettu: { $messages }. Kohde: { $folder }
}
download-progress = Ladataan { $done }/{ $total }
download-done = Ladattu { $size }
downloading-messages = { $count ->
   *[other] Ladataan: { $messages }...
}
# the status bar after files are dropped on a folder: "Lisätty: 3 viestiä. Kohde: Arkisto"
import-put = { $count ->
   *[other] Lisätty: { $messages }. Kohde: { $folder }
}
import-not-put = Näitä ei lisätty kansioon:

    { $problems }

## Problems the windows show

error-store = paikallinen postitietokanta: { $error }
error-not-found = ei löytynyt
error-closed = sovellus sulkeutuu
error-other-account = selaimessa kirjauduttiin toiselle tilille ({ $email })
# a password or sign-in the mail server refused, with the server's words
failure-authentication = palvelin ei hyväksynyt kirjautumista ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = yhteys palvelimeen epäonnistui ({ $reason })
error-in-use = sitä ei voi poistaa, koska seuraavat tilit käyttävät sitä kirjautumiseen: { $accounts }
error-turned-off = tämä kirjautumissovellus on poistettu käytöstä uusilta tileiltä
error-folder-name = kansion nimessä on oltava 1-200 merkkiä, eikä siinä saa olla ohjausmerkkejä
error-folder-separator = tällä palvelimella kansion nimessä ei voi olla merkkiä ”{ $separator }”
error-folder-special = Saapuneet-kansiota ja erikoiskansioita ei voi nimetä uudelleen tai poistaa
error-no-recipients = viestillä ei ole vastaanottajia
error-bad-address = ”{ $address }” ei ole sähköpostiosoite
error-not-own-address = { $address } ei ole tämän tilin lähettäjäosoitteita. Lisää se tilin ominaisuuksien kenttään ”Muut osoitteet, joista lähetät”.
rule-query-refused = Säännöt eivät voi suodattaa kansion tai päivämäärän mukaan ({ $words }).
rule-no-query = Anna saapuvien viestien hakuehdot.
rule-no-action = Valitse säännölle vähintään yksi toiminto.
error-attachment = Tiedostoa { $path } ei voitu lukea: { $error }
error-no-drafts = tilillä ei ole Luonnokset-kansiota, johon viestin voisi tallentaa
error-draft-attachment = luonnoksen liitettä ei voitu säilyttää: { $error }
error-password-not-saved = salasanaa ei voitu tallentaa seuraavaa käynnistystä varten: { $error }
error-sign-in-not-saved = uusia kirjautumistietoja ei voitu tallentaa seuraavaa käynnistystä varten: { $error }
error-import-unreadable = Tiedostoa { $path } ei voi lukea: { $error }
error-import-too-large = Tiedosto { $path } on suurempi kuin 50 Mt
error-import-not-mail = Tiedosto { $path } ei ole sähköpostiviesti
error-list-answered = postituslistan palvelin palautti tilan { $status }
error-not-built = viestiä ei voitu muodostaa
error-outbox-waits = { $count ->
    [one] viesti odottaa Lähtevät-kansiossa ja lähetetään, kun seuraavan kerran valitset Lähetä ja vastaanota kaikki
   *[other] { $count } viestiä odottaa Lähtevät-kansiossa, ja ne lähetetään, kun seuraavan kerran valitset Lähetä ja vastaanota kaikki
}
error-draft-not-removed = viestin aiempaa luonnosta ei voitu poistaa Luonnokset-kansiosta: { $reason }
error-sent-but = viesti lähetettiin, mutta { $problem }
error-sent-still-in-outbox = se on yhä Lähtevät-kansiossa: { $error }
error-sent-no-copy = kopiota ei voitu tallentaa Lähetetyt-kansioon: { $reason }
error-no-password = tilin salasana puuttuu
error-no-sign-in = tilin kirjautumistiedot puuttuvat
error-provider-missing = tämä versio ei voi kirjautua palveluun { $provider }: onko sen kirjautumissovellus poistettu?
error-provider-servers = tämän tilin palvelimet eivät vastaa sen kirjautumissovelluksen palvelimia
error-app-scopes = { $reason }. Postipalvelin ei hyväksynyt kirjautumissovelluksen käyttöoikeustunnusta: tarkista, että sovelluksen käyttöoikeudet (scopes) sallivat postin käytön
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google ei ole vielä vahvistanut Inbox Classicia, joten se sallii kirjautumisen sillä vain testikäyttäjille. Käytä omaa Google-kirjautumissovellustasi tai sovellussalasanaa, tai ota se käyttöön kohdassa Kirjautumissovellukset (Tiedosto > Tilit), jos olet testikäyttäjä.
sign-in-off-other = Se poistettiin käytöstä kohdassa Kirjautumissovellukset (Tiedosto > Tilit), jossa sen voi ottaa uudelleen käyttöön.
sign-in-app-no-name = kirjautumissovellus tarvitsee nimen
sign-in-app-no-client = asiakastunnus puuttuu
sign-in-app-no-scopes = kirjautumissovellus tarvitsee käyttöoikeudet (scopes), jotka antavat pääsyn postiin
sign-in-app-bad-host = palvelimen { $server } osoite puuttuu tai ei ole kelvollinen palvelimen nimi
sign-in-app-plain = palvelimen { $server } on käytettävä SSL/TLS- tai STARTTLS-suojausta
sign-in-app-not-checked = myöntäjää ei ole vielä tarkistettu
sign-in-app-issuer-changed = myöntäjä muuttui: kirjoita asiakassalaisuus uudelleen tai poista se
sign-in-register-google = Luo Google Cloud Consolessa OAuth-asiakas, jonka tyyppi on Desktop app, ja lisää sen suostumusnäyttöön käyttöoikeus https://mail.google.com/. Kun sovellus on testivaiheessa, vain sen testikäyttäjät voivat kirjautua.
sign-in-register-microsoft = Rekisteröi Microsoft Entrassa sovellus. Valitse alustaksi Mobile and desktop applications, aseta uudelleenohjaus-URI:ksi http://localhost ja salli julkisen asiakkaan kirjautuminen. Lisää delegoidut käyttöoikeudet IMAP.AccessAsUser.All, SMTP.Send ja offline_access. Jos sovellus on tarkoitettu vain organisaatiollesi, käytä myöntäjänä osoitetta https://login.microsoftonline.com/<vuokraajan tunnus>/v2.0.
sign-in-register-other = Rekisteröi natiivi (julkinen) asiakas alla olevalla uudelleenohjaus-URI:lla. Palveluntarjoajan on sallittava siinä mikä tahansa portti (RFC 8252). Lisää käyttöoikeus, jolla palveluntarjoaja antaa pääsyn postiin.

## Calendar invitations

repeats = Toistuu
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
repeats-on = { $repeats }, päivinä: { $days }
# "Joka viikko, 10 kertaa"
repeats-times = { $count ->
    [one] { $repeats }, kerran
   *[other] { $repeats }, { $count } kertaa
}
day-monday = maanantai
day-tuesday = tiistai
day-wednesday = keskiviikko
day-thursday = torstai
day-friday = perjantai
day-saturday = lauantai
day-sunday = sunnuntai

## AI agents

agent-level-read = Lukea postia: kansiot, viestiluettelo, haku ja viestit
# review: changed
agent-level-organize = Järjestellä: luettu/lukematon, liput, roskaposti, siirto, poisto Poistettuihin
agent-level-drafts = Kirjoittaa luonnoksia, jotka sinä lähetät
agent-level-send = Lähettää postia, jokaisen viestin vasta hyväksyntäsi jälkeen
agent-connect-title = { $program } haluaa käyttää postiasi
agent-connect-detail = Tekoälyagentti pyysi pääsyä postiisi Inbox Classicin kautta. Valitse, mitä se saa tehdä ja mitkä tilit se näkee. Voit muuttaa näitä oikeuksia myöhemmin kohdassa Työkalut > Tekoälyagentit.

    Agentit lukevat muiden kirjoittamia viestejä, jotka voivat sisältää harhaanjohtavia ohjeita. Inbox Classic kysyy aina hyväksyntäsi, ennen kuin agentti voi lähettää viestin sen kautta.
agent-reply-to = Vastaus viestiin ”{ $subject }”
agent-reply-all-on = Vastaus kaikille: ”{ $subject }”
agent-forward-of = Edelleenvälitys: ”{ $subject }”
agent-never-written-one = Et ole koskaan kirjoittanut osoitteeseen { $address }.
agent-never-written-many = Osoitteita, joihin et ole koskaan kirjoittanut: { $count }.
agent-send-title = { $program } haluaa lähettää tämän viestin
agent-send-detail = Tarkista vastaanottajat ja viestin sisältö. Kun vahvistat, viesti odottaa { $seconds } sekuntia Lähtevät-kansiossa, jossa voit vielä poistaa sen.
agent-change-title = Mitä { $program } saa tehdä
agent-change-allowed = Muuta, mitä tämän ohjelman tekoälyagentit saavat tehdä postillesi.
agent-change-refused = Olet estänyt tämän ohjelman pääsyn postiisi. Salli pääsy uudelleen, jos haluat sen agenttien voivan käyttää postiasi.
agent-log-taken-back = { $entry } (peruttu)
agent-files = Tiedostot: { $files }
agent-undo-refused = Sitä ei voi perua.
agent-undo-refused-why = Sitä ei voi perua: { $reason }.
agent-undo-impossible = tätä ei voi perua
agent-undo-not-in-folder = viesti ei ole enää siinä kansiossa
agent-undo-not-arrived = viesti ei ole (vielä) kansiossa, johon se siirrettiin
agent-undo-sent = viesti ei ole enää Lähtevät-kansiossa
agent-original-not-downloaded = alkuperäistä viestiä ei ole vielä ladattu. Avaa se ensin
agent-turned-away = Torjuttu
agent-can-nothing = Ei mitään
agent-can-read = lukea
agent-can-organize = järjestellä
agent-can-drafts = kirjoittaa luonnoksia
agent-can-send = lähettää hyväksynnälläsi
# "lukea, järjestellä ja kirjoittaa luonnoksia"
agent-can-list = { $first } ja { $last }
agent-accounts = { $count ->
    [0] ei tilejä
    [one] { $count } tili
   *[other] { $count } tiliä
}
# "lukea ja järjestellä; 1 tili"
agent-access = { $can }; { $accounts }
agent-unreadable = Tätä viestiä ei voi lukea.
agent-encrypted-original = Tämä viesti on salattu: agentti ei voi vastata siihen tai välittää sitä, koska se ei osaa salata.
agent-encrypted = Tämä viesti on salattu. Tekoälyagentit eivät voi lukea sen sisältöä. Käyttäjän on avattava viesti Inbox Classicissa.
list-encrypted = Salattu viesti
agent-log-composed = Avasi viestin ”{ $subject }” uutena viestinä, jonka viimeistelet
agent-log-refused = Et lähettänyt viestiä ”{ $subject }”
agent-log-sent = Lisäsi viestin ”{ $subject }” lähetysjonoon. Vastaanottajat: { $to }
agent-log-draft = Tallensi luonnoksen ”{ $subject }”
agent-log-read = Merkitsi luetuksi: ”{ $subject }”
agent-log-unread = Merkitsi lukemattomaksi: ”{ $subject }”
agent-log-flagged = Liputti: ”{ $subject }”
agent-log-unflagged = Poisti lipun: ”{ $subject }”
agent-log-deleted = Poisti: ”{ $subject }”
agent-log-moved = Siirsi: ”{ $subject }”. Kohde: { $folder }
agent-log-junk = Merkitsi roskapostiksi: ”{ $subject }”
agent-log-not-junk = Poisti roskapostimerkinnän: ”{ $subject }”
agent-log-archived = Arkistoi: ”{ $subject }”
agent-log-folder = Loi kansion ”{ $name }”
agent-log-unsubscribed = Peruutti tilauksen postituslistalta, jolta viesti ”{ $subject }” tuli
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
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic pyytää alla olevaa listaa lopettamaan lähettämisen sinulle sillä yhden napsautuksen tavalla, jota lista tarjoaa. Mitään muuta ei lähetetä, ja jo saamasi viestit pysyvät paikoillaan.
   *[other] Inbox Classic pyytää jokaista alla olevaa listaa lopettamaan lähettämisen sinulle sillä yhden napsautuksen tavalla, jota lista tarjoaa. Mitään muuta ei lähetetä, ja jo saamasi viestit pysyvät paikoillaan.
}

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = palveluntarjoaja ei antanut päivitystunnusta (refresh token)
sign-in-no-account = palveluntarjoaja ei kertonut, mikä tili kirjautui
sign-in-not-finished = kirjautuminen on vielä kesken
secrets-unavailable = { $store } ei ole käytettävissä
secrets-unavailable-why = { $store } ei ole käytettävissä: { $error }
secrets-windows = Tunnistetietojen hallinta
secrets-mac = Avainnippu
secrets-linux = järjestelmän avainnippu (Secret Service)
error-no-such-file = tiedostoa ei ole olemassa
cards-file-too-big = Tiedosto on liian suuri tuotavaksi osoitekirjaan.
ui-sender-added = { $name } lisättiin osoitekirjaan.
ui-sender-known = { $name } on jo osoitekirjassa.
ui-sender-none = Tämän viestin lähettäjällä ei ole lisättävää sähköpostiosoitetta.
card-name-needed = Yhteystiedolla ei ole nimeä eikä sähköpostiosoitetta.
# a file of Import Address Book that could not be read: "contacts.vcf: tiedostoa ei ole olemassa"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Koodi lähettäjältä { $domain }
otp-copy = Kopioi
otp-note = Syötä se vain sivustolla { $domain }.
otp-old = Tämä koodi lähetettiin yli tuntia ennen kuin avasit sen, ja se on luultavasti vanhentunut.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } osallistuja
       *[other] { $count } osallistujaa
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } on koodisi palveluun { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Voimassa
pgp-key-expires = Voimassa { $date } asti
pgp-key-expired = Vanhentui { $date }
pgp-key-revoked = Mitätöity
pgp-key-revoked-why = Mitätöity: { $reason }
pgp-key-not-valid = Ei voimassa
pgp-key-locked = Ei käytettävissä: yksityisen avaimen suojausavain puuttuu järjestelmän säilöstä ({ $store }). Tuo yksityinen avain uudelleen sen varmuuskopiosta.
pgp-source-own = Luotu Inbox Classicissa
pgp-source-file = Tuotu tiedostosta
pgp-source-paste = Liitetty
pgp-source-attachment = Viestistä
pgp-source-vcard = Yhteystietokortista
pgp-source-wkd = Lähettäjän postipalveluntarjoajalta
pgp-source-keyserver = Palvelusta keys.openpgp.org
pgp-source-autocrypt = Viestin Autocrypt-otsakkeesta
pgp-error-no-store = Yksityisiä avaimia suojaa { $store }, jota ei voi käyttää: { $error }
pgp-error-wrong-passphrase = Salalause on väärä.
pgp-error-not-a-key = Tämä ei ole OpenPGP-avain.
pgp-error-too-large = Avain on liian suuri.
pgp-error-unusable = Avain käyttää vanhaa tai heikkoa salausta, eikä sitä voi käyttää.
pgp-imported-private = { $count ->
    [one] Yksityinen avaimesi tuotiin.
   *[other] Tuotiin { $count } yksityistä avainta.
}
pgp-imported-public = { $count ->
    [one] Yksi avain tuotiin.
   *[other] Tuotiin { $count } avainta.
}
pgp-imported-pending = Näille osoitteille on jo käytössä toinen avain: { $addresses }. Uusi avain odottaa yhteystietokortissa, kunnes otat sen käyttöön.
pgp-error-needs-passphrase = Yksityinen avain on suojattu salalauseella. Kirjoita se, niin avain tuodaan.
pgp-error-mismatch = Yksityinen avain ei vastaa julkista avainta. Sitä on ehkä muutettu.
pgp-file-name-public = { $who } julkinen avain.asc
pgp-file-name-private = { $who } yksityisen avaimen varmuuskopio.asc
pgp-pending = Osoitteelle { $address } löytyi eri avain { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Allekirjoittaja: { $signer }, avaimen haltija vahvistettu
pgp-part-signed = Allekirjoittaja: { $signer } (avaimen haltijaa ei ole vahvistettu)
pgp-part-other = Allekirjoittaja: { $signer }, joka ei ole lähettäjä
pgp-part-unknown-key = Allekirjoitettu digitaalisesti, mutta avain on tuntematon
pgp-part-not-signed = Ei digitaalista allekirjoitusta
pgp-part-not-checked = Digitaalista allekirjoitusta ei tarkistettu
pgp-part-encrypted = Salattu. { $signature }
pgp-part-no-key = Salauksen purkamiseen tarvittava yksityinen avain puuttuu
pgp-part-changed = Salattua osaa muutettiin matkalla, eikä sitä näytetä
pgp-part-unprotected = Salattu ilman suojausta muutoksia vastaan, ei näytetä
pgp-part-broken = Salattua osaa ei voi lukea
pgp-why-mismatch = Allekirjoitus ei vastaa tätä tekstiä
pgp-why-weak-hash = Allekirjoitus käyttää algoritmia { $hash }, joka ei ole enää turvallinen
pgp-why-key-expired = Allekirjoitettu sen jälkeen, kun avain vanhentui { $date }
pgp-why-key-revoked = Allekirjoitettu mitätöidyllä avaimella
pgp-why-not-signing-key = Allekirjoitettu avaimella, joka ei kelpaa digitaaliseen allekirjoittamiseen
pgp-why-from-future = Allekirjoitus on päivätty tulevaisuuteen
pgp-why-signature-expired = Allekirjoitus on vanhentunut
pgp-why-key-not-valid = Allekirjoitettu avaimella, joka ei ole voimassa
pgp-why-not-for-you = Allekirjoitettu muille vastaanottajille ja välitetty sinulle
pgp-why-not-key-in-use = Allekirjoituksessa käytetty avain ei ole osoitteelle { $address } valittu avain
pgp-part-pictures-loaded = { $label }. Kuvat ladattiin internetistä
pgp-error-no-own-key = Sinulla ei ole osoitteelle { $address } avainta, jolla allekirjoittaa tai salata. Luo avain kohdassa Työkalut > Salausavaimet tai poista Allekirjoita ja Salaa käytöstä.
pgp-error-missing-keys = { $count ->
    [one] Vastaanottajalle { $addresses } ei ole julkista avainta viestin salaamiseen.
   *[other] Näille vastaanottajille ei ole julkisia avaimia viestin salaamiseen: { $addresses }.
}
pgp-error-encrypted-quote = Tämä viesti lainaa tai välittää salatun viestin, joten sen voi lähettää vain salattuna. Ota Salaa käyttöön tai poista lainattu teksti.
pgp-error-protect = Viestiä ei voitu allekirjoittaa tai salata: { $reason }
pgp-found-keys = Seuraaville osoitteille löytyi julkinen avain: { $addresses }.
pgp-found-none = Avainta ei löytynyt seuraaville osoitteille: { $addresses }. Pyydä kunkin osoitteen haltijalta hänen julkinen avaimensa.
pgp-found-no-key = Avainta ei löytynyt.
pgp-find-unavailable = Avaimia ei voitu hakea nyt: { $error }
pgp-publish-pending = keys.openpgp.org lähetti vahvistuslinkin jokaiseen seuraavista osoitteista: { $addresses }. Vahvista jokainen osoite, jotta avaimesi löytyy sen avulla.
pgp-publish-done = Avaimesi on julkaistu palvelussa keys.openpgp.org. Sähköpostiosoitteet: { $addresses }.
pgp-publish-failed = Avainta ei voitu julkaista: { $error }
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
pgp-details-part = Osa { $number }: { $label }
pgp-details-signed = Allekirjoitettu { $when } avaimella { $key }
pgp-details-unknown-key = Allekirjoitettu avaimella { $key }, jota sinulla ei ole
pgp-details-opened = Salaus purettu avaimella { $key }
pgp-details-for = Salattu avaimille { $keys }
pgp-details-plain = Ei allekirjoitettu eikä salattu
pgp-bar-parts = Tässä viestissä on { $count } osaa: { $list }. Kunkin osan kohdalla näkyy, miten se on suojattu.
pgp-bar-count-verified = vahvistettuja { $count }
pgp-bar-count-good = { $count ->
    [one] 1 allekirjoitettu tai salattu
   *[other] { $count } allekirjoitettua tai salattua
}
pgp-bar-count-warning = { $count ->
    [one] 1 vaatii huomiota
   *[other] { $count } vaatii huomiota
}
pgp-bar-count-neutral = ilman tarkistettua digitaalista allekirjoitusta: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Asetukset
setup-part-preferences = Ikkunoiden asetukset
setup-part-accounts = Tilit
setup-part-sign-in-apps = Kirjautumissovellukset
setup-part-contacts = Yhteystiedot ja ryhmät
setup-part-keys = Salausavaimet
setup-part-rules = Viestisäännöt
setup-part-trusted-senders = Luotetut lähettäjät
setup-holds-settings = { $count ->
    [one] 1 asetus
   *[other] { $count } asetusta
}
setup-holds-preferences = { $count ->
    [one] 1 ikkunan asetus
   *[other] { $count } ikkunoiden asetusta
}
setup-holds-accounts = { $count ->
    [one] 1 tili
   *[other] { $count } tiliä
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 kirjautumissovellus
   *[other] { $count } kirjautumissovellusta
}
setup-holds-built-in = Mitkä sisäänrakennetut kirjautumissovellukset ovat käytössä
setup-holds-contacts = { $count ->
    [one] 1 yhteystieto
   *[other] { $count } yhteystietoa
}
setup-holds-groups = { $count ->
    [one] 1 ryhmä
   *[other] { $count } ryhmää
}
setup-holds-own-keys = { $count ->
    [one] 1 oma avain
   *[other] { $count } omaa avainta
}
setup-holds-contact-keys = { $count ->
    [one] 1 yhteystiedon avain
   *[other] { $count } yhteystietojen avainta
}
setup-holds-rules = { $count ->
    [one] 1 sääntö
   *[other] { $count } sääntöä
}
setup-holds-trusted-senders = { $count ->
    [one] 1 luotettu lähettäjä
   *[other] { $count } luotettua lähettäjää
}
setup-sign-in-password = Salasana
setup-account-secret-password = Sen salasana on tiedostossa.
setup-account-secret-token = Tilin kirjautumistiedot ovat tiedostossa.
setup-account-asks-password = Tilin salasanaa kysytään tuonnin jälkeen.
setup-account-signs-in-again = Tilille on kirjauduttava uudelleen tuonnin jälkeen.
setup-account-here = Tili on jo lisätty tähän tietokoneeseen, joten se ohitetaan.
setup-account-no-app = Tilille kirjaudutaan sovelluksella { $app }, jota ei ole lisätty tähän tietokoneeseen. Tuo myös kirjautumissovellukset.
setup-invalid-address = ”{ $address }” ei ole sähköpostiosoite.
setup-invalid-server = Palvelimella { $server } ei ole käyttökelpoista nimeä tai porttia.
setup-invalid-user = Tilin käyttäjänimi puuttuu.
setup-invalid-sign-in = Tilin kirjautumistapaa ei tueta Inbox Classicissa.
setup-error-empty = Tiedosto on tyhjä.
setup-error-too-large = Tiedosto on liian suuri tuotavaksi Inbox Classicin asetustiedostona.
setup-error-not-setup = Tämä tiedosto ei ole Inbox Classicin asetustiedosto.
setup-error-damaged = Asetustiedosto on vioittunut, eikä sitä voi lukea.
setup-error-newer = Tämä asetustiedosto on tallennettu uudemmalla Inbox Classicilla ({ $version }). Päivitä Inbox Classic ja tuo tiedosto sitten uudelleen.
setup-error-needs-passphrase = Tämä asetustiedosto on suojattu salalauseella. Kirjoita salalause, jolla se tallennettiin.
setup-error-wrong-passphrase = Tämä ei ole salalause, jolla asetustiedosto tallennettiin.
setup-error-changed = Asetustiedostoa muutettiin tai se vioittui tallennuksen jälkeen, joten sitä ei voi tuoda.
setup-error-read = Asetustiedostoa ei voitu lukea: { $error }
setup-error-write = Asetuksia ei voitu tallentaa: { $error }
setup-error-no-parts = Valitse vähintään yksi osa.
setup-left-out = { $count ->
    [one] Osasta { $part } jätetään pois 1 kohta, jota ei voi käyttää.
   *[other] Osasta { $part } jätetään pois { $count } kohtaa, joita ei voi käyttää.
}
setup-imported-settings = Asetukset korvattiin.
setup-imported-preferences = Ikkunoiden asetukset korvattiin.
setup-added-accounts = { $count ->
    [one] Lisättiin 1 tili.
   *[other] Lisättiin { $count } tiliä.
}
setup-skipped-here = Tili { $address } on jo lisätty tähän tietokoneeseen, joten se ohitettiin.
setup-skipped-no-app = Tili { $address } ohitettiin: sen kirjautumissovellusta ({ $app }) ei ole lisätty tähän tietokoneeseen.
setup-skipped-invalid = { $address } ohitettiin: { $reason }
setup-asks-password = Tilin { $address } salasanaa kysytään, kun siihen muodostetaan yhteys.
setup-signs-in-again = Tilille { $address } on kirjauduttava uudelleen, kun siihen muodostetaan yhteys.
setup-added-sign-in-apps = { $count ->
    [one] Lisättiin 1 kirjautumissovellus.
   *[other] Lisättiin { $count } kirjautumissovellusta.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 kirjautumissovellus on jo lisätty tähän tietokoneeseen.
   *[other] { $count } kirjautumissovellusta on jo lisätty tähän tietokoneeseen.
}
setup-added-contacts = { $count ->
    [one] Osoitekirjaan lisättiin 1 yhteystieto.
   *[other] Osoitekirjaan lisättiin { $count } yhteystietoa.
}
setup-skipped-contacts = { $count ->
    [one] 1 yhteystieto on jo osoitekirjassa.
   *[other] { $count } yhteystietoa on jo osoitekirjassa.
}
setup-added-groups = { $count ->
    [one] Lisättiin tai täydennettiin 1 ryhmä.
   *[other] Lisättiin tai täydennettiin { $count } ryhmää.
}
setup-added-own-keys = { $count ->
    [one] Lisättiin 1 oma avain.
   *[other] Lisättiin { $count } omaa avainta.
}
setup-added-contact-keys = { $count ->
    [one] Lisättiin 1 yhteystiedon avain.
   *[other] Lisättiin { $count } yhteystietojen avainta.
}
setup-added-rules = { $count ->
    [one] Lisättiin 1 viestisääntö.
   *[other] Lisättiin { $count } viestisääntöä.
}
setup-skipped-rules = { $count ->
    [one] 1 viestisääntö on jo tallennettu tähän tietokoneeseen.
   *[other] { $count } viestisääntöä on jo tallennettu tähän tietokoneeseen.
}
setup-skipped-rules-account = { $count ->
    [one] 1 viestisääntö ohitettiin, koska sen tiliä ei ole lisätty tähän tietokoneeseen.
   *[other] { $count } viestisääntöä ohitettiin, koska niiden tilejä ei ole lisätty tähän tietokoneeseen.
}
setup-rules-waiting = { $count ->
    [one] 1 viestisääntö siirtää viestejä kansioon, joka ilmestyy, kun sen tili synkronoidaan.
   *[other] { $count } viestisääntöä siirtää viestejä kansioihin, jotka ilmestyvät, kun niiden tilit synkronoidaan.
}
setup-added-trusted-senders = { $count ->
    [one] Lisättiin 1 luotettu lähettäjä.
   *[other] Lisättiin { $count } luotettua lähettäjää.
}
setup-nothing = Mitään ei tuotu.
setup-account-servers = { $imap } ja { $smtp } ({ $signin })
setup-file-name = Inbox Classicin asetukset ja tilit
setup-skipped-unreachable = { $name } ohitettiin: sen kirjautumispalveluun ei saatu yhteyttä. Lisää se uudelleen kohdassa Kirjautumissovellukset.
attachment-runs-programs = ”{ $name }” voi suorittaa ohjelmia, joten Inbox Classic ei avaa sitä. Tallenna se ja avaa se sitten itse, jos luotat sen lähteeseen.
attachment-decrypted-note = Tämä liite on peräisin salatusta viestistä. Liitteen avaamista varten Inbox Classic tallentaa siitä salaamattoman kopion käyttäjätilisi väliaikaiseen kansioon. Yli vuorokauden vanhat kopiot poistetaan sovelluksen käynnistyessä.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Palvelin ei siirtänyt viestiä kansioon { $folder }, joten { $messages } on taas kansiossa { $from }: { $reason }
   *[other] Palvelin ei siirtänyt viestejä kansioon { $folder }, joten { $messages } on taas kansiossa { $from }: { $reason }
}
undone-delete = { $count ->
    [one] Palvelin ei poistanut viestiä, joten { $messages } on taas kansiossa { $from }: { $reason }
   *[other] Palvelin ei poistanut viestejä, joten { $messages } on taas kansiossa { $from }: { $reason }
}
undone-archive = { $count ->
    [one] Palvelin ei arkistoinut viestiä, joten { $messages } on taas kansiossa { $from }: { $reason }
   *[other] Palvelin ei arkistoinut viestejä, joten { $messages } on taas kansiossa { $from }: { $reason }
}
undone-read = { $count ->
    [one] Palvelin ei merkinnyt viestiä luetuksi, joten { $messages } on taas lukematta: { $reason }
   *[other] Palvelin ei merkinnyt viestejä luetuiksi, joten { $messages } on taas lukematta: { $reason }
}
undone-unread = { $count ->
    [one] Palvelin ei merkinnyt viestiä lukemattomaksi, joten { $messages } on taas luettu: { $reason }
   *[other] Palvelin ei merkinnyt viestejä lukemattomiksi, joten { $messages } on taas luettu: { $reason }
}
undone-flags = { $count ->
    [one] Palvelin ei muuttanut viestin lippuja, joten { $messages } on ennallaan: { $reason }
   *[other] Palvelin ei muuttanut viestien lippuja, joten { $messages } on ennallaan: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Näytä PDF-tiedostot viesteissä
# review: new
preview-pdf-off = PDF-tiedostoja ei näytetä viesteissä.
# review: new
preview-pdf-off-crashed = PDF-tiedosto sulki Inbox Classicin näytettäessä, joten PDF-tiedostoja ei enää näytetä viesteissä. Kuvat näytetään edelleen. Voit näyttää PDF-tiedostot uudelleen ottamalla asetuksen { $option } käyttöön lukuasetuksissa.
