# Magyar. Vázlat, anyanyelvi átnézésre vár (lásd core/locales/GLOSSARY.md).
# Amit a mag mond, minden platformon ugyanígy. A { $kapcsos } helyőrzőket a program tölti ki; maradjanak meg. A
# helyőrzőkhöz nem kapcsolunk ragot: inkább átfogalmazzuk a mondatot. Többes szám: [one] és *[other].

## Counts and sizes

messages = { $count ->
    [one] 1 üzenet
   *[other] { $count } üzenet
}
# a tizedesjel a méretekben: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 bájt
   *[other] { $count } bájt
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Ki
send-delay-seconds = { $count ->
    [one] 1 másodperc
   *[other] { $count } másodperc
}
# az állapotsor: „12 üzenet, 3 olvasatlan”
list-counts = { $messages }, { $unread } olvasatlan
list-counts-selected = { $messages }, { $unread } olvasatlan, { $selected } kijelölve
list-counts-found = { $found } találat, { $unread } olvasatlan
list-counts-found-selected = { $found } találat, { $unread } olvasatlan, { $selected } kijelölve
list-counts-none = Nincs találat

## Special folders, as Outlook names them

folder-inbox = Beérkezett üzenetek
folder-sent = Elküldött elemek
folder-deleted = Törölt elemek
folder-drafts = Piszkozatok
folder-junk = Levélszemét
folder-archive = Archívum

## The reading pane

reader-no-message = Nincs kijelölve üzenet.
reader-downloading = Az üzenet letöltése…
reader-downloading-detail = Az üzenet itt jelenik meg, amint a letöltés befejeződik.
reader-downloading-size = Az üzenet mérete { $size }. Itt jelenik meg, amint letöltődött.
reader-failed = Az üzenetet nem sikerült letölteni
reader-failed-network = A levelezőkiszolgáló nem érhető el ({ $reason }).
reader-failed-sign-in = A levelezőkiszolgáló nem fogadta el a bejelentkezést ({ $reason }). Ellenőrizze a jelszót, vagy jelentkezzen be újra a Fájl > Fiókok ablakban.
reader-failed-security = Nem sikerült biztonságos kapcsolatot létesíteni a levelezőkiszolgálóval ({ $reason }).
reader-failed-other = A levelezőkiszolgáló válasza: { $reason }.
reader-retry-note = A fiók újbóli csatlakozásakor az alkalmazás ismét megpróbálja letölteni az üzenetet.
reader-unreadable = Ez az üzenet nem jeleníthető meg: { $error }
message-source-title = Az üzenet forrása: { $subject }
message-source-untitled = Az üzenet forrása

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Feladó
header-date = Dátum
header-to = Címzett
header-cc = Másolat
header-sent = Elküldve
header-subject = Tárgy
header-security = Biztonság
header-part = { $number }. rész
quote-original = ----- Eredeti üzenet -----
fold-show-earlier = A korábbi üzenetek megjelenítése

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Az üzenetet nem sikerült kézbesíteni
bounce-delayed = Az üzenetet még nem kézbesítették
bounce-delayed-note = A levelezőkiszolgáló még próbálkozik a kézbesítéssel. Nem szükséges újra elküldeni az üzenetet.
bounce-show-message = A kézbesíthetetlen üzenet megjelenítése
bounce-show-delayed = A kézbesítésre váró üzenet megjelenítése
bounce-what-to-do = Teendők:
bounce-delayed-do = Egyelőre nincs teendő. Ha az üzenetet nem sikerül kézbesíteni, újabb értesítést kap.
bounce-delayed-row-do = Egyelőre nincs teendő. A levelezőkiszolgáló még próbálkozik a kézbesítéssel. Ha nem sikerül, újabb értesítést kap.
bounce-details = Részletek
bounce-someone = Egy címzett
bounce-server = Kiszolgáló: { $server }
bounce-status = Állapot: { $status }
bounce-reported-by = Jelentette: { $server }
bounce-retry-minutes = A fogadó kiszolgáló által kért várakozási idő a következő próbálkozásig: { $count ->
    [one] 1 perc
   *[other] { $count } perc
}.
bounce-retry-hours = A fogadó kiszolgáló által kért várakozási idő a következő próbálkozásig: { $count ->
    [one] 1 óra
   *[other] { $count } óra
}.
bounce-blocklist = Tiltólista: { $lists }
bounce-user-unknown = A cím nem létezik
bounce-user-unknown-why = A fogadó kiszolgálón nincs ilyen című postafiók. Lehet, hogy elírták, vagy a címzett már nem használja.
bounce-user-unknown-do = Ellenőrizze a cím írásmódját, vagy kérdezze meg a címzettet, melyik címet használja most.
bounce-invalid-address = A cím érvénytelen
bounce-invalid-address-why = A cím formátuma hibás, ezért nem lehet rá levelet küldeni.
bounce-invalid-address-do = Ellenőrizze, nincs-e szóköz vagy elírás a címben, és nem hiányzik-e a @ utáni rész.
bounce-mailbox-disabled = A postafiók nem használható
bounce-mailbox-disabled-why = A cím létezik, de a postafiókot kikapcsolták, vagy már nem használják.
bounce-mailbox-disabled-do = Keresse a címzettet más módon, és kérdezze meg, melyik címet használja most.
bounce-mailbox-full = A postafiók megtelt
bounce-mailbox-full-why = A címzett postafiókjában nincs hely új levelek számára.
bounce-mailbox-full-do = Küldje el újra néhány nap múlva, vagy értesítse a címzettet más módon. A nagy mellékleteket utasítják vissza elsőként.
bounce-spam-blocked = Levélszemétként visszautasítva
bounce-spam-blocked-why = A fogadó kiszolgáló levélszemétnek tekintette az üzenetet.
bounce-spam-blocked-do = Próbálja meg újra elküldeni az üzenetet kevesebb hivatkozással, rövidített hivatkozások és nagy mellékletek nélkül. Ha a hiba ismétlődik, forduljon a levelezési szolgáltatójához.
bounce-virus-detected = Vírus miatt visszautasítva
bounce-virus-detected-why = A fogadó kiszolgáló vírust vagy más kártékony tartalmat talált az üzenetben vagy a mellékleteiben.
bounce-virus-detected-do = Ellenőrizze a mellékleteket víruskeresővel. Egyes kiszolgálók minden programot és tömörített fájlt visszautasítanak, ezért az ilyen fájlokat inkább hivatkozásként ossza meg.
bounce-ip-blocklisted = A levelezőkiszolgálója tiltólistán van
bounce-ip-blocklisted-why = A fogadó kiszolgáló visszautasítja a levelezőkiszolgálójától érkező leveleket, mert annak címe tiltólistán szerepel.
bounce-ip-blocklisted-do = Nem az üzenettel van a gond. Továbbítsa ezt az értesítést a levelezési szolgáltatójának, és kérje meg, hogy vetesse le a kiszolgálót a listáról.
bounce-domain-blocklisted = Egy tartomány tiltólistán van
bounce-domain-blocklisted-why = A fogadó kiszolgáló visszautasítja az üzenetet, mert a feladócím tartománya vagy az üzenetben hivatkozott tartományok egyike tiltólistán szerepel.
bounce-domain-blocklisted-do = Ha az üzenetben hivatkozások vannak, próbálja meg nélkülük. Egyébként továbbítsa ezt az értesítést annak, aki a tartománya levelezését kezeli.
bounce-policy-blocked = A fogadó kiszolgáló szabályai miatt visszautasítva
bounce-policy-blocked-why = A fogadó kiszolgáló szabályai nem engedik át ezt az üzenetet, például a mérete, a mellékletei vagy a feladója miatt.
bounce-policy-blocked-do = A Részletek alatt látható kiszolgálói válasz gyakran megadja az elutasítás okát. Kérdezze meg a címzettet, fogadhat-e ilyen levelet.
bounce-geo-blocked = A származási helye miatt visszautasítva
bounce-geo-blocked-why = A fogadó kiszolgáló nem fogad levelet abból az országból vagy hálózatból, ahol a levelezőkiszolgálója van.
bounce-geo-blocked-do = Keresse a címzettet más módon, vagy kérdezze meg a levelezési szolgáltatóját.
bounce-relay-denied = A kiszolgáló elutasította a továbbítást
bounce-relay-denied-why = Egy kiszolgáló elutasította az üzenet továbbítását. Ez gyakran akkor történik, ha a küldés bejelentkezés nélkül történt, vagy a kiszolgáló nem kézbesít ennek a címzettnek.
bounce-relay-denied-do = A Fájl > Fiókok ablakban ellenőrizze a kimenő levelezőkiszolgáló beállításait, és hogy be van-e állítva a bejelentkezés.
bounce-auth-failure = A feladócímét nem sikerült hitelesíteni
bounce-auth-failure-why = A fogadó kiszolgáló nem tudta igazolni, hogy az üzenet valóban a feladócím tartományából érkezett (SPF, DKIM vagy DMARC).
bounce-auth-failure-do = Továbbítsa ezt az értesítést annak, aki a tartománya levelezését kezeli: a beállításait javítani kell. Addig segíthet, ha a szolgáltatója saját kiszolgálóján keresztül küld.
bounce-rate-limited = Túl sok levél egyszerre
bounce-rate-limited-why = A fogadó kiszolgáló egyelőre kevesebb üzenetet fogad a levelezőkiszolgálójától.
bounce-rate-limited-do = Várjon egy kicsit, és küldje el újra. Ha sok embernek ír, egyszerre kevesebbnek küldje.
bounce-greylisting = Rövid időre visszatartva
bounce-greylisting-why = A fogadó kiszolgáló arra kéri az ismeretlen feladókat, hogy kicsit később próbálkozzanak újra. Ez a levélszemét elleni szokásos ellenőrzés.
bounce-greylisting-do = Nincs teendő. A levelezőkiszolgálók automatikusan újrapróbálkoznak, és az üzenet általában egy órán belül megérkezik.
bounce-server-error = A fogadó kiszolgálón hiba történt
bounce-server-error-why = A fogadó kiszolgáló nem volt elérhető, vagy saját hibája miatt nem tudta fogadni az üzenetet.
bounce-server-error-do = Küldje el újra később. Ha továbbra sem sikerül, ellenőrizze, nincs-e elírás a cím @ utáni részében.
bounce-unknown = Nincs kézbesítve
bounce-unknown-why = Az értesítés nem ad egyértelmű magyarázatot a sikertelen kézbesítésre.
bounce-unknown-do = A Részletek alatt látható kiszolgálói válasz segíthet megtalálni az okot. Ha ez sem segít, továbbítsa az értesítést a levelezési szolgáltatójának.

## Several messages selected

selection-title = { $count ->
    [one] 1 üzenet kijelölve
   *[other] { $count } üzenet kijelölve
}
selection-unread = { $count } olvasatlan
selection-flagged = { $count } megjelölt
delete-for-good-one = Ez az üzenet véglegesen törlődik. Törli?
delete-for-good-all = Véglegesen törölni szeretné a kijelölt üzeneteket? Összesen: { $count } üzenet.
delete-for-good-some = { $total } üzenetből { $count } véglegesen törlődik. Törli az üzeneteket?
done-read = { $count ->
   *[other] Olvasottként megjelölve: { $messages }
}
done-unread = { $count ->
   *[other] Olvasatlanként megjelölve: { $messages }
}
done-flagged = { $count ->
   *[other] Jelölővel ellátva: { $messages }
}
done-unflagged = Jelölő eltávolítva: { $messages }
done-deleted-for-good = { $count ->
   *[other] Véglegesen törölve: { $messages }
}
done-archived = { $count ->
   *[other] Archiválva: { $messages }
}
done-moved = { $count ->
   *[other] Áthelyezve: { $messages }. Cél: { $folder }
}
done-copied = { $count ->
   *[other] Átmásolva: { $messages }. Cél: { $folder }
}
done-moving = { $count ->
   *[other] Áthelyezés: { $messages }. Cél: { $folder }...
}
done-copying = { $count ->
   *[other] Másolás: { $messages }. Cél: { $folder }...
}
done-moved-back = { $count ->
   *[other] Visszahelyezve: { $messages }. Cél: { $folder }
}
done-watched = { $count ->
    [one] A beszélgetés figyelése bekapcsolva
   *[other] { $count } beszélgetés figyelése bekapcsolva
}
done-unwatched = { $count ->
    [one] A beszélgetés figyelése kikapcsolva
   *[other] { $count } beszélgetés figyelése kikapcsolva
}
done-ignored = { $count ->
    [one] A beszélgetés figyelmen kívül hagyva
   *[other] { $count } beszélgetés figyelmen kívül hagyva
}
done-unignored = { $count ->
    [one] A beszélgetés figyelmen kívül hagyása kikapcsolva
   *[other] { $count } beszélgetés figyelmen kívül hagyása kikapcsolva
}
their-folders = eredeti mappáik
undo-move = Áthelyezés visszavonása
undo-delete = Törlés visszavonása
undo-archive = Archiválás visszavonása
undo-junk = Levélszemétként jelölés visszavonása
undo-not-junk = Nem levélszemétként jelölés visszavonása
undo-send = Küldés visszavonása
nothing-to-undo = Nincs mit visszavonni.
messages-gone = Az üzenetek már nincsenek meg.
folder-holds-no-messages = Ez a mappa nem tartalmazhat üzeneteket.
not-archived-here = Az ebben a mappában lévő üzenetek nem archiválhatók.
not-emptied-here = Csak a Törölt elemek és a Levélszemét mappa üríthető ki.
next-unread-question = Nincs több olvasatlan üzenet ebben a mappában: { $folder }.

    Továbblép a következő olvasatlan üzeneteket tartalmazó mappába ({ $next })?
no-unread-left = Nem maradt olvasatlan üzenet.
empty-question = { $count ->
    [one] Kiüríti ezt a mappát: { $folder }?

        A benne lévő üzenet véglegesen törlődik. Nem lehet visszaállítani.
   *[other] Kiüríti ezt a mappát: { $folder }?

        A mappa összes üzenete véglegesen törlődik, és nem állítható vissza. Törlendő: { $messages }.
}
no-junk-folder = Ennek a fióknak nincs Levélszemét mappája, ahová az üzeneteket át lehetne helyezni.
no-inbox-folder = Ennek a fióknak nincs Beérkezett üzenetek mappája, ahová az üzeneteket át lehetne helyezni.
# az állapotsor egy színes jelölő után: „Kék jelölővel ellátva: 2 üzenet”
done-flagged-color = { $color ->
    [red] Piros
    [orange] Narancssárga
    [yellow] Sárga
    [green] Zöld
    [blue] Kék
    [purple] Lila
   *[gray] Szürke
    } jelölővel ellátva: { $messages }
flag-color = { $color ->
    [red] Piros
    [orange] Narancssárga
    [yellow] Sárga
    [green] Zöld
    [blue] Kék
    [purple] Lila
   *[gray] Szürke
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Üzenet áthelyezése
   *[other] { $count } üzenet áthelyezése
}
move-window-title-copy = { $count ->
    [one] Üzenet másolása
   *[other] { $count } üzenet másolása
}
move-window-prompt-move = { $count ->
    [one] A kijelölt üzenet áthelyezése ide:
   *[other] A kijelölt { $count } üzenet áthelyezése ide:
}
move-window-prompt-copy = { $count ->
    [one] A kijelölt üzenet másolása ide:
   *[other] A kijelölt { $count } üzenet másolása ide:
}
targets-recent = Legutóbbiak
target-current = { $folder } (jelenlegi)
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Áthelyezés: { $done } / { $messages }. Cél: { $folder }...
transfer-copying = Másolás: { $done } / { $messages }. Cél: { $folder }...
transfer-another-account = másik fiók
transfer-folder-gone = a célmappa már nem létezik
transfer-not-on-server = az üzenet már nincs a kiszolgálón
transfer-not-moved = { $count ->
   *[other] Nem sikerült másik fiókba áthelyezni: { $messages }. Ok: { $reason }
}
transfer-not-copied = { $count ->
   *[other] Nem sikerült másik fiókba másolni: { $messages }. Ok: { $reason }
}
transfer-none-moved = Egy üzenetet sem sikerült áthelyezni
transfer-none-copied = Egy üzenetet sem sikerült átmásolni

## Messages as files

export-not-in-time = az üzenetet nem sikerült időben letölteni
export-not-saved = Nem sikerült menteni: { $failed } üzenet. Összesen: { $messages }. Részletek: { $problems }
export-not-attached = az üzeneteket nem sikerült csatolni: { $error }
# az állapotsor a Mentés másként után: „Mentve: 3 üzenet. Hely: Asztal”
saved-to = { $count ->
   *[other] Mentve: { $messages }. Hely: { $folder }
}
download-progress = Letöltés: { $done } / { $total }
download-done = Letöltve: { $size }
downloading-messages = { $count ->
   *[other] Letöltés: { $messages }...
}
import-put = { $count ->
   *[other] Importálva: { $messages }. Mappa: { $folder }
}
import-not-put = Ezek nem kerültek a mappába:

    { $problems }

## Problems the windows show

error-store = helyi levéladatbázis: { $error }
error-not-found = nem található
error-closed = leállás folyamatban
error-other-account = a böngészőben másik fiókkal történt a bejelentkezés: { $email }
failure-authentication = a kiszolgáló nem fogadta el a bejelentkezést ({ $reason })
failure-network = nem sikerült kapcsolódni a kiszolgálóhoz ({ $reason })
error-in-use = nem távolítható el, mert a következő fiókok ezt használják a bejelentkezéshez: { $accounts }
error-turned-off = ez a bejelentkezési alkalmazás új fiókok hozzáadásához nincs engedélyezve
error-folder-name = a mappa neve 1 és 200 karakter közötti hosszúságú lehet, és nem tartalmazhat vezérlőkaraktert
error-folder-separator = ezen a kiszolgálón a mappa neve nem tartalmazhatja ezt a karaktert: „{ $separator }”
error-folder-special = a Beérkezett üzenetek és a különleges mappák nem nevezhetők át és nem törölhetők
error-no-recipients = az üzenetnek nincs címzettje
error-bad-address = „{ $address }” nem e-mail-cím
error-not-own-address = { $address } nem tartozik a fiók feladócímei közé. Vegye fel a fiók tulajdonságaiban az „Egyéb feladócímek” mezőbe.
rule-query-refused = A szabályokban nem használhatók mappára vagy dátumra vonatkozó feltételek ({ $words }).
rule-no-query = Adja meg a bejövő üzenetek keresési feltételeit.
rule-no-action = Válasszon legalább egy műveletet a szabályhoz.
error-attachment = Nem sikerült beolvasni: { $path }. Ok: { $error }
error-no-drafts = a fióknak nincs Piszkozatok mappája, ahová az üzenetet menteni lehetne
error-draft-attachment = a piszkozat egyik mellékletét nem sikerült megtartani: { $error }
error-password-not-saved = a jelszót nem sikerült elmenteni a következő indításhoz: { $error }
error-sign-in-not-saved = az új bejelentkezési adatokat nem sikerült elmenteni a következő indításhoz: { $error }
error-import-unreadable = Nem olvasható: { $path }. Ok: { $error }
error-import-too-large = 50 MB-nál nagyobb: { $path }
error-import-not-mail = Nem e-mail-üzenet: { $path }
error-list-answered = a levelezőlista kiszolgálója ezt az állapotot adta vissza: { $status }
error-not-built = az üzenetet nem sikerült összeállítani
error-outbox-waits = { $count ->
    [one] az üzenet a Postázandó üzenetek mappában vár. A következő küldés/fogadás során az alkalmazás újra megpróbálja elküldeni
   *[other] { $count } üzenet vár a Postázandó üzenetek mappában. A következő küldés/fogadás során az alkalmazás újra megpróbálja elküldeni őket
}
error-draft-not-removed = az üzenet korábbi piszkozatát nem sikerült eltávolítani a Piszkozatok mappából: { $reason }
error-sent-but = az üzenet elküldve, de { $problem }
error-sent-still-in-outbox = még a Postázandó üzenetek mappában van: { $error }
error-sent-no-copy = nem sikerült másolatot menteni az Elküldött elemek mappába: { $reason }
error-no-password = ehhez a fiókhoz nincs jelszó
error-no-sign-in = ehhez a fiókhoz nincsenek bejelentkezési adatok
error-provider-missing = ez a kiadás nem tud bejelentkezni ehhez a szolgáltatóhoz: { $provider }. Eltávolították a bejelentkezési alkalmazását?
error-provider-servers = a fiók kiszolgálói nem egyeznek a bejelentkezési alkalmazásának kiszolgálóival
error-app-scopes = { $reason }. A levelezőkiszolgáló nem fogadta el a bejelentkezési alkalmazás tokenjét: ellenőrizze, hogy az alkalmazás hatókörei hozzáférést adnak-e a levelekhez
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = A Google még nem hitelesítette az Inbox Classicot, ezért csak tesztfelhasználók jelentkezhetnek be vele. Használjon saját Google-bejelentkezési alkalmazást, vagy alkalmazásjelszót, ha a fiók ezt támogatja. Tesztfelhasználóként a Bejelentkezési alkalmazások ablakban (Fájl > Fiókok) is bekapcsolhatja a beépített alkalmazást.
sign-in-off-other = A Bejelentkezési alkalmazások ablakban (Fájl > Fiókok) ki van kapcsolva. Ugyanott újra bekapcsolható.
sign-in-app-no-name = a bejelentkezési alkalmazásnak nevet kell adni
sign-in-app-no-client = hiányzik az ügyfél-azonosító
sign-in-app-no-scopes = a bejelentkezési alkalmazásnak szüksége van a levelekhez hozzáférést adó hatókörökre
sign-in-app-bad-host = hiányzik a kiszolgáló címe, vagy nem érvényes állomásnév ({ $server })
sign-in-app-plain = a kiszolgálónak SSL/TLS vagy STARTTLS titkosítást kell használnia ({ $server })
sign-in-app-not-checked = a kibocsátó még nincs ellenőrizve
sign-in-app-issuer-changed = a kibocsátó megváltozott: írja be újra a titkos ügyfélkulcsot, vagy távolítsa el
sign-in-register-google = A Google Cloud Console felületén hozzon létre egy Desktop app típusú OAuth-ügyfelet. A jóváhagyási képernyőjén adja meg a https://mail.google.com/ hatókört. Amíg az alkalmazás tesztelési állapotban van, csak a tesztfelhasználói jelentkezhetnek be vele.
sign-in-register-microsoft = A Microsoft Entrában regisztráljon egy alkalmazást a Mobile and desktop applications platformmal, a http://localhost átirányítási URI-val, engedélyezett nyilvános ügyfélfolyamatokkal, valamint az IMAP.AccessAsUser.All, SMTP.Send és offline_access delegált engedélyekkel. Ha csak a saját szervezetének szól, kibocsátóként a https://login.microsoftonline.com/<bérlőazonosító>/v2.0 címet adja meg.
sign-in-register-other = Regisztráljon egy natív (nyilvános) ügyfelet az alábbi átirányítási URI-val; a szolgáltatónak bármely portot engedélyeznie kell rajta (RFC 8252). Adja hozzá azt a hatókört, amellyel a szolgáltató hozzáférést ad a levelekhez.

## Calendar invitations

repeats = Ismétlődés
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Minden nap
       *[other] { $interval } naponta
    }
    [week] { $interval ->
        [one] Minden héten
       *[other] { $interval } hetente
    }
    [month] { $interval ->
        [one] Minden hónapban
       *[other] { $interval } havonta
    }
   *[year] { $interval ->
        [one] Minden évben
       *[other] { $interval } évente
    }
}
# „Minden héten, ezeken a napokon: hétfő, szerda”
repeats-on = { $repeats }, ezeken a napokon: { $days }
# „Minden héten, 10 alkalommal”
repeats-times = { $count ->
    [one] { $repeats }, egyszer
   *[other] { $repeats }, { $count } alkalommal
}
day-monday = hétfő
day-tuesday = kedd
day-wednesday = szerda
day-thursday = csütörtök
day-friday = péntek
day-saturday = szombat
day-sunday = vasárnap

## AI agents

agent-level-read = Levelek olvasása: mappák, az üzenetlista, a keresés és az üzenetek
# review: changed
agent-level-organize = Levelek kezelése: olvasottság, jelölők, levélszemét, áthelyezés, törlés a Törölt elemek közé
agent-level-drafts = Piszkozatok írása, amelyeket később elküldhet
agent-level-send = Levélküldés, minden üzenet külön jóváhagyásával
agent-connect-title = { $program } hozzá szeretne férni a leveleihez
agent-connect-detail = Egy MI-ügynök hozzáférést kért az Inbox Classicban kezelt levelekhez. Válassza ki, mit tehet, és mely fiókokhoz férhet hozzá. Ezt később az Eszközök > MI-ügynökök menüpontban módosíthatja.

    Az ügynökök mások leveleit is olvassák, amelyek megtévesztő utasításokat tartalmazhatnak. Az Inbox Classic minden ügynök által kezdeményezett küldés előtt jóváhagyást kér.
agent-reply-to = Válasz erre: „{ $subject }”
agent-reply-all-on = Válasz mindenkinek erre: „{ $subject }”
agent-forward-of = Továbbítás: „{ $subject }”
agent-never-written-one = Még soha nem írt erre a címre: { $address }.
agent-never-written-many = E címek közül { $count } címre még soha nem írt.
agent-send-title = { $program } el szeretné küldeni ezt az üzenetet
agent-send-detail = Ellenőrizze a címzetteket és az üzenet tartalmát. Jóváhagyás után az üzenet { $seconds } másodpercig a Postázandó üzenetek mappában vár, ahol még törölheti.
agent-change-title = { $program } jogosultságai
agent-change-allowed = Módosítsa, mit tehetnek a program MI-ügynökei a leveleivel.
agent-change-refused = A program hozzáférése le van tiltva. Engedélyezze újra, ha azt szeretné, hogy az ügynökei hozzáférjenek a leveleihez.
agent-log-taken-back = { $entry } (visszavonva)
agent-files = Fájlok: { $files }
agent-undo-refused = Nem vonható vissza.
agent-undo-refused-why = Nem vonható vissza: { $reason }.
agent-undo-impossible = ez nem vonható vissza
agent-undo-not-in-folder = az üzenet már nincs abban a mappában
agent-undo-not-arrived = az üzenet (még) nincs a célmappában
agent-undo-sent = az üzenet már nincs a Postázandó üzenetek mappában
agent-original-not-downloaded = az eredeti üzenet még nincs letöltve. Előbb nyissa meg
agent-turned-away = Elutasítva
agent-can-nothing = Semmi
agent-can-read = olvasás
agent-can-organize = kezelés
agent-can-drafts = piszkozatok írása
agent-can-send = küldés jóváhagyással
# „Olvasás, rendezés és piszkozatok írása”
agent-can-list = { $first } és { $last }
agent-accounts = { $count ->
    [0] nincs fiók
    [one] 1 fiók
   *[other] { $count } fiók
}
# „Olvasás és rendezés; 1 fiók”
agent-access = { $can }; { $accounts }
agent-unreadable = Ez az üzenet nem olvasható.
agent-encrypted-original = Ez az üzenet titkosított: az ügynök nem válaszolhat rá és nem továbbíthatja, mert nem tud titkosítani.
agent-encrypted = Ez az üzenet titkosított. Csak a felhasználó olvashatja el, az Inbox Classicban.
list-encrypted = Titkosított üzenet
agent-log-composed = Új üzenetként megnyitva további szerkesztéshez: „{ $subject }”
agent-log-refused = Küldés elutasítva: „{ $subject }”
agent-log-sent = Küldési sorba helyezve: „{ $subject }”. Címzett: { $to }
agent-log-draft = Piszkozat mentve: „{ $subject }”
agent-log-read = Olvasottként megjelölve: „{ $subject }”
agent-log-unread = Olvasatlanként megjelölve: „{ $subject }”
agent-log-flagged = Jelölővel ellátva: „{ $subject }”
agent-log-unflagged = Jelölő eltávolítva: „{ $subject }”
agent-log-deleted = Törölve: „{ $subject }”
agent-log-moved = Áthelyezve: „{ $subject }”. Cél: { $folder }
agent-log-junk = Levélszemétként megjelölve: „{ $subject }”
agent-log-not-junk = Nem levélszemétként megjelölve: „{ $subject }”
agent-log-archived = Archiválva: „{ $subject }”
agent-log-folder = Mappa létrehozva: „{ $name }”
agent-log-unsubscribed = Leiratkozás a levelezőlistáról: „{ $subject }”
# review: new
agent-log-unsubscribe-failed = Sikertelen leiratkozás a levelezőlistáról („{ $subject }”): { $reason }
# review: new
agent-log-unsubscribe-refused = Nem iratkozott le innen: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [one] { $program } le szeretné iratkoztatni Önt egy levelezőlistáról
   *[other] { $program } le szeretné iratkoztatni Önt { $count } levelezőlistáról
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Az Inbox Classic megkéri az alábbi listát, hogy ne küldjön Önnek több levelet, a lista által kínált egykattintásos módon. Mást nem küld el, és a meglévő üzenetei a helyükön maradnak.
   *[other] Az Inbox Classic az alábbi listák mindegyikét megkéri, hogy ne küldjön Önnek több levelet, a lista által kínált egykattintásos módon. Mást nem küld el, és a meglévő üzenetei a helyükön maradnak.
}

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = a szolgáltató nem adott frissítési tokent
sign-in-no-account = a szolgáltató nem közölte, melyik fiók jelentkezett be
sign-in-not-finished = a bejelentkezés nem fejeződött be
secrets-unavailable = { $store } nem érhető el
secrets-unavailable-why = { $store } nem érhető el: { $error }
secrets-windows = a Hitelesítőadat-kezelő
secrets-mac = a kulcskarika
secrets-linux = a rendszer kulcstartója (Secret Service)
error-no-such-file = nincs ilyen fájl
cards-file-too-big = A fájl túl nagy a címjegyzék importálásához.
ui-sender-added = Felvéve a Címjegyzékbe: { $name }
ui-sender-known = Már szerepel a Címjegyzékben: { $name }
ui-sender-none = Az üzenet feladójának nincs felvehető e-mail-címe.
card-name-needed = A névjegyhez sem név, sem e-mail-cím nincs megadva.
# a Címjegyzék importálása egy be nem olvasható fájlja: „contacts.vcf: nincs ilyen fájl”
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

otp-heading = { $domain } kódja
otp-copy = Másolás
otp-note = Csak { $domain } oldalain adja meg.
otp-old = Ezt a kódot több mint egy órával az üzenet megnyitása előtt küldték, így valószínűleg már lejárt.

# a meghívottak száma egy esemény kártyáján
event-attendees =
    { $count ->
        [one] { $count } résztvevő
       *[other] { $count } résztvevő
    }

# egy új üzenet értesítésének első sora, ha kódot tartalmaz
otp-notification = Kód: { $code } ({ $domain })

## OpenPGP keys (keys.rs)
pgp-key-valid = Érvényes
pgp-key-expires = Érvényes eddig: { $date }
pgp-key-expired = Lejárt: { $date }
pgp-key-revoked = Visszavonva
pgp-key-revoked-why = Visszavonva: { $reason }
pgp-key-not-valid = Érvénytelen
pgp-key-locked = A titkos kulcs nem használható, mert hiányzik a védelméhez szükséges kulcs. Tároló: { $store }. Importálja újra a titkos kulcs biztonsági másolatát.
pgp-source-own = Az Inbox Classicban készült
pgp-source-file = Fájlból importálva
pgp-source-paste = Beillesztve
pgp-source-attachment = Üzenetből
pgp-source-vcard = Névjegykártyáról
pgp-source-wkd = A feladó levelezési szolgáltatójától
pgp-source-keyserver = A keys.openpgp.org oldalról
pgp-source-autocrypt = Egy üzenet Autocrypt fejlécéből
pgp-error-no-store = A titkos kulcsok védelméhez szükséges tároló nem érhető el ({ $store }): { $error }
pgp-error-wrong-passphrase = Hibás jelmondat.
pgp-error-not-a-key = Ez nem OpenPGP-kulcs.
pgp-error-too-large = A kulcs túl nagy.
pgp-error-unusable = A kulcs elavult vagy gyenge kriptográfiai eljárást használ, ezért nem használható.
pgp-imported-private = { $count ->
    [one] A titkos kulcsa importálva.
   *[other] { $count } titkos kulcs importálva.
}
pgp-imported-public = { $count ->
    [one] Egy kulcs importálva.
   *[other] { $count } kulcs importálva.
}
pgp-imported-pending = Ezekhez a címekhez már egy másik kulcs tartozik: { $addresses }. Az új kulcsot a névjegyben választhatja ki. Addig a korábbi marad használatban.
pgp-error-needs-passphrase = A titkos kulcsot jelmondat védi. Írja be a kulcs importálásához.
pgp-error-mismatch = A titkos kulcs nem illik a nyilvános kulcshoz. Lehet, hogy módosították.
pgp-file-name-public = { $who } nyilvános kulcsa.asc
pgp-file-name-private = { $who } titkos kulcsának biztonsági másolata.asc
pgp-pending = Egy másik kulcs került elő ehhez a címhez: { $address } (dátum: { $date }).

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Digitális aláíró: { $signer } (a kulcs tulajdonosa ellenőrizve)
pgp-part-signed = Digitális aláíró: { $signer } (a kulcs tulajdonosa nincs ellenőrizve)
pgp-part-other = Digitális aláíró: { $signer } (nem egyezik a feladóval)
pgp-part-unknown-key = Digitálisan aláírt, de a kulcs ismeretlen
pgp-part-not-signed = Nincs digitális aláírás
pgp-part-not-checked = A digitális aláírás nincs ellenőrizve
pgp-part-encrypted = Titkosított. { $signature }
pgp-part-no-key = Titkosított, de a visszafejtéshez szükséges titkos kulcs nem érhető el
pgp-part-changed = A titkosított részt útközben módosították, ezért nem jelenik meg
pgp-part-unprotected = Módosítás elleni védelem nélkül titkosítva, ezért nem jelenik meg
pgp-part-broken = A titkosított rész nem olvasható
pgp-why-mismatch = A digitális aláírás nem érvényes ehhez a szöveghez
pgp-why-weak-hash = Az aláírás már nem biztonságos eljárást használ: { $hash }
pgp-why-key-expired = A kulcs lejárta után aláírva (lejárat: { $date })
pgp-why-key-revoked = Visszavont kulccsal aláírva
pgp-why-not-signing-key = Aláírásra nem használható kulccsal aláírva
pgp-why-from-future = Az aláírás dátuma a jövőben van
pgp-why-signature-expired = Az aláírás lejárt
pgp-why-key-not-valid = Érvénytelen kulccsal aláírva
pgp-why-not-for-you = Más címzettek számára digitálisan aláírt, majd továbbított üzenet
pgp-why-not-key-in-use = Az aláíráshoz használt kulcs eltér az ehhez a címhez beállított kulcstól: { $address }
pgp-part-pictures-loaded = { $label }. A képek az internetről töltődtek be
pgp-error-no-own-key = Ehhez a feladócímhez nincs aláírásra vagy titkosításra használható saját kulcs: { $address }. Hozzon létre kulcsot az Eszközök > Titkosítási kulcsok menüpontban, vagy kapcsolja ki az üzenet digitális aláírását és titkosítását.
pgp-error-missing-keys = { $count ->
    [one] Ennek a címzettnek nincs kulcsa a titkosításhoz: { $addresses }.
   *[other] Ezeknek a címzetteknek nincs kulcsa a titkosításhoz: { $addresses }.
}
pgp-error-encrypted-quote = Ez az üzenet egy titkosított üzenetet idéz vagy továbbít, ezért csak titkosítva küldhető el. Kapcsolja be az üzenet titkosítását, vagy távolítsa el az idézett szöveget.
pgp-error-protect = Az üzenetet nem sikerült digitálisan aláírni vagy titkosítani: { $reason }
pgp-found-keys = Kulcs található a következő címekhez: { $addresses }.
pgp-found-none = Nem található kulcs a következő címekhez: { $addresses }. Kérje el a címzettek nyilvános kulcsát.
pgp-found-no-key = Nem található kulcs.
pgp-find-unavailable = A kulcsokat most nem sikerült megkeresni: { $error }
pgp-publish-pending = A keys.openpgp.org megerősítő hivatkozást küldött a következő címekre: { $addresses }. Erősítse meg mindegyik címet, hogy a kulcsa az adott cím alapján megtalálható legyen.
pgp-publish-done = A kulcsa elérhető a keys.openpgp.org oldalon a következő címekhez: { $addresses }.
pgp-publish-failed = A kulcsot nem sikerült közzétenni: { $error }
pgp-keyserver-off = A kulcsok keresése a keys.openpgp.org oldalon ki van kapcsolva itt: { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Titkosítva és aláírva: csak Ön és ez a címzett olvashatja: { $addresses }.
   *[other] Titkosítva és aláírva: csak Ön és az üzenet { $count } címzettje olvashatja.
}
# review: new
pgp-compose-encrypt-ready = Titkosítva és aláírva lesz elküldve. Adjon hozzá olyan címzetteket, akiknek megvan a kulcsa.
# review: new
pgp-compose-missing = { $count ->
    [one] Ennek a címzettnek nincs kulcsa, ezért az üzenet még nem titkosítható: { $addresses }.
   *[other] { $count } címzettnek nincs kulcsa, ezért az üzenet még nem titkosítható: { $addresses }.
}
# review: new
pgp-compose-looking = Kulcsok keresése: { $addresses }...
# review: new
pgp-compose-signed = Aláírva: a címzettek ellenőrizhetik, hogy az üzenet Öntől származik, és senki nem módosította.
# review: new
pgp-compose-reply-clear = Nincs titkosítva, pedig a megválaszolt vagy továbbított üzenet titkosított volt.
# review: new
pgp-compose-encrypted-files = Egy titkosított üzenet fájljai vannak csatolva, ezért ez az üzenet csak titkosítva küldhető el. Kapcsolja be a Titkosítást, vagy távolítsa el ezeket a fájlokat.
# review: new
pgp-compose-sign-tip = Az üzenet aláírása a saját kulcsával, hogy a címzettek ellenőrizhessék, hogy Öntől származik, és senki nem módosította
# review: new
pgp-compose-sign-tip-encrypted = A titkosított üzenet mindig alá is van írva
# review: new
pgp-compose-encrypt-tip = Az üzenet titkosítása, hogy csak Ön és a címzettjei olvashassák
# review: new
pgp-compose-make-key = Ehhez a címhez még nincs kulcsa: { $address }. Létrehoz most egyet? Ezzel aláírhatja és titkosíthatja az üzeneteit.
# review: new
pgp-compose-key-unusable = Az ehhez a címhez tartozó kulcsa nem használható: { $address } ({ $state }). Nyissa meg a Titkosítási kulcsok ablakot, és importálja a kulcs biztonsági másolatát, vagy hozzon létre új kulcsot.
# review: new
pgp-compose-encrypt-off-quote = Ez az üzenet egy titkosított üzenetet idéz vagy továbbít. Titkosítás nélkül csak akkor küldhető el, ha eltávolítja belőle az idézett szöveget. Mégis kikapcsolja a titkosítást?
# review: new
pgp-compose-encrypt-off-reply = Ez az üzenet egy titkosított üzenetre válaszol, vagy azt továbbítja. Titkosítás nélkül bárki elolvashatja, aki útközben kezeli az üzenetét. Kikapcsolja a titkosítást?
# review: new
pgp-recipient-verified = A kulcs ellenőrizve
# review: new
pgp-recipient-found = A kulcs nincs ellenőrizve
# review: new
pgp-recipient-own = Saját kulcs
# review: new
pgp-recipient-looking = Kulcs keresése...
# review: new
pgp-recipient-missing = Nincs kulcs
# review: new
pgp-recipient-not-found = Nincs kulcs: nem található, keresés ideje: { $date }
# review: new
pgp-recipient-unusable = A kulcs nem használható: { $state }
# review: new
pgp-recipients-intro = Az üzenet minden címzett kulcsára és az Ön kulcsára is titkosítva lesz.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Egy címzettnek nincs kulcsa a titkosításhoz. Keresse meg a kulcsát, távolítsa el őt ebből az üzenetből, vagy küldje el az üzenetet titkosítás nélkül.
   *[other] { $count } címzettnek nincs kulcsa a titkosításhoz. Keresse meg a kulcsaikat, távolítsa el őket ebből az üzenetből, vagy küldje el az üzenetet titkosítás nélkül.
}
pgp-details-part = { $number }. rész: { $label }
pgp-details-signed = Aláírva, időpont: { $when }, kulcs: { $key }
pgp-details-unknown-key = Az aláíráshoz használt kulcs nem érhető el: { $key }
pgp-details-opened = Visszafejtve a következő saját kulccsal: { $key }
pgp-details-for = Titkosítva ezekre a kulcsokra: { $keys }
pgp-details-plain = Nincs aláírva és nincs titkosítva
pgp-bar-parts = Az üzenet részei ({ $count }): { $list }. Minden résznél külön látható a védelmi állapot.
pgp-bar-count-verified = { $count } ellenőrzött
pgp-bar-count-good = { $count ->
    [one] 1 aláírt vagy titkosított
   *[other] { $count } aláírt vagy titkosított
}
pgp-bar-count-warning = { $count ->
    [one] 1 figyelmet igényel
   *[other] { $count } figyelmet igényel
}
pgp-bar-count-neutral = { $count } igazolt digitális aláírás nélkül
# a beállításfájl: beállítások, fiókok, névjegyek és kulcsok átvitele egy másik számítógépre
setup-part-settings = Beállítások
setup-part-preferences = Ablakbeállítások
setup-part-accounts = Fiókok
setup-part-sign-in-apps = Bejelentkezési alkalmazások
setup-part-contacts = Névjegyek és csoportok
setup-part-keys = Titkosítási kulcsok
setup-part-rules = Üzenetszabályok
setup-part-trusted-senders = Megbízható feladók
setup-holds-settings = { $count ->
    [one] 1 beállítás
   *[other] { $count } beállítás
}
setup-holds-preferences = { $count ->
    [one] 1 ablakbeállítás
   *[other] { $count } ablakbeállítás
}
setup-holds-accounts = { $count ->
    [one] 1 fiók
   *[other] { $count } fiók
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 bejelentkezési alkalmazás
   *[other] { $count } bejelentkezési alkalmazás
}
setup-holds-built-in = Mely beépített bejelentkezési alkalmazások vannak bekapcsolva
setup-holds-contacts = { $count ->
    [one] 1 névjegy
   *[other] { $count } névjegy
}
setup-holds-groups = { $count ->
    [one] 1 csoport
   *[other] { $count } csoport
}
setup-holds-own-keys = { $count ->
    [one] 1 saját kulcs
   *[other] { $count } saját kulcs
}
setup-holds-contact-keys = { $count ->
    [one] 1 névjegyhez tartozó kulcs
   *[other] { $count } névjegyekhez tartozó kulcs
}
setup-holds-rules = { $count ->
    [one] 1 szabály
   *[other] { $count } szabály
}
setup-holds-trusted-senders = { $count ->
    [one] 1 megbízható feladó
   *[other] { $count } megbízható feladó
}
setup-sign-in-password = Jelszó
setup-account-secret-password = A jelszava benne van a fájlban.
setup-account-secret-token = A bejelentkezési adatai benne vannak a fájlban.
setup-account-asks-password = Az importálás után kéri a jelszavát.
setup-account-signs-in-again = Az importálás után újra be kell jelentkeznie.
setup-account-here = Itt már be van állítva, ezért kimarad.
setup-account-no-app = A fiókhoz szükséges bejelentkezési alkalmazás itt nincs beállítva: { $app }. Importálja a bejelentkezési alkalmazásokat is.
setup-invalid-address = „{ $address }” nem e-mail-cím.
setup-invalid-server = A kiszolgálónak nincs használható neve vagy portja ({ $server }).
setup-invalid-user = Nincs felhasználóneve.
setup-invalid-sign-in = Olyan módon jelentkezik be, amelyet az Inbox Classic nem ismer.
setup-error-empty = A fájl üres.
setup-error-too-large = A fájl túl nagy a beállítások és fiókok importálásához.
setup-error-not-setup = Ez nem az Inbox Classic beállításait és fiókjait tartalmazó fájl.
setup-error-damaged = A beállításfájl sérült, és nem olvasható.
setup-error-newer = Ezt a beállításfájlt az Inbox Classic egy újabb verziója ({ $version }) mentette. Frissítse az Inbox Classicot, majd importálja újra.
setup-error-needs-passphrase = Ezt a beállításfájlt jelmondat védi. Írja be a mentéskor megadott jelmondatot.
setup-error-wrong-passphrase = Nem ezzel a jelmondattal mentették a beállításfájlt.
setup-error-changed = A beállításfájlt a mentése után módosították vagy megsérült, ezért nem importálható.
setup-error-read = A beállításfájlt nem sikerült beolvasni: { $error }
setup-error-write = A beállításfájlt nem sikerült menteni: { $error }
setup-error-no-parts = Válasszon legalább egy részt.
setup-left-out = { $count ->
    [one] { $part }: 1 bejegyzés nem használható, ezért kimarad.
   *[other] { $part }: { $count } bejegyzés nem használható, ezért kimarad.
}
setup-imported-settings = A beállítások lecserélve.
setup-imported-preferences = Az ablakbeállítások lecserélve.
setup-added-accounts = { $count ->
    [one] 1 fiók hozzáadva.
   *[other] { $count } fiók hozzáadva.
}
setup-skipped-here = Itt már be van állítva, ezért kimaradt: { $address }
setup-skipped-no-app = Kimaradt: { $address }. A fiókhoz szükséges bejelentkezési alkalmazás itt nincs beállítva: { $app }.
setup-skipped-invalid = Kimaradt: { $address }. Ok: { $reason }
setup-asks-password = { $address }: kapcsolódáskor kéri a jelszavát.
setup-signs-in-again = { $address }: kapcsolódáskor újra be kell jelentkeznie.
setup-added-sign-in-apps = { $count ->
    [one] 1 bejelentkezési alkalmazás hozzáadva.
   *[other] { $count } bejelentkezési alkalmazás hozzáadva.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 bejelentkezési alkalmazás már be van itt állítva.
   *[other] { $count } bejelentkezési alkalmazás már be van itt állítva.
}
setup-added-contacts = { $count ->
    [one] 1 névjegy hozzáadva a címjegyzékhez.
   *[other] { $count } névjegy hozzáadva a címjegyzékhez.
}
setup-skipped-contacts = { $count ->
    [one] 1 névjegy már szerepel a címjegyzékben.
   *[other] { $count } névjegy már szerepel a címjegyzékben.
}
setup-added-groups = { $count ->
    [one] 1 csoport hozzáadva vagy kiegészítve.
   *[other] { $count } csoport hozzáadva vagy kiegészítve.
}
setup-added-own-keys = { $count ->
    [one] 1 saját kulcs hozzáadva.
   *[other] { $count } saját kulcs hozzáadva.
}
setup-added-contact-keys = { $count ->
    [one] 1 névjegyhez tartozó kulcs hozzáadva.
   *[other] { $count } névjegyekhez tartozó kulcs hozzáadva.
}
setup-added-rules = { $count ->
    [one] 1 üzenetszabály hozzáadva.
   *[other] { $count } üzenetszabály hozzáadva.
}
setup-skipped-rules = { $count ->
    [one] 1 üzenetszabály már megvan itt.
   *[other] { $count } üzenetszabály már megvan itt.
}
setup-skipped-rules-account = { $count ->
    [one] 1 üzenetszabály kimaradt, mert olyan fiókhoz tartozik, amely itt nincs beállítva.
   *[other] { $count } üzenetszabály kimaradt, mert olyan fiókokhoz tartozik, amelyek itt nincsenek beállítva.
}
setup-rules-waiting = { $count ->
    [one] 1 üzenetszabály olyan mappába helyez át üzeneteket, amely a fiókja szinkronizálása után jelenik meg.
   *[other] { $count } üzenetszabály olyan mappákba helyez át üzeneteket, amelyek a fiókjaik szinkronizálása után jelennek meg.
}
setup-added-trusted-senders = { $count ->
    [one] 1 megbízható feladó hozzáadva.
   *[other] { $count } megbízható feladó hozzáadva.
}
setup-nothing = Semmi sem lett importálva.
setup-account-servers = { $imap } és { $smtp } ({ $signin })
setup-file-name = Az Inbox Classic beállításai és fiókjai
setup-skipped-unreachable = Kimaradt: { $name }. A bejelentkezési szolgáltatás nem volt elérhető. Adja hozzá újra a szükséges bejelentkezési alkalmazást a Bejelentkezési alkalmazások ablakban.
attachment-runs-programs = „{ $name }” programokat futtathat, ezért az Inbox Classic nem nyitja meg. Ha megbízik a forrásában, mentse, majd nyissa meg kézzel.
attachment-decrypted-note = Ez a melléklet titkosított üzenetből származik. A megnyitásához az Inbox Classic titkosítatlan másolatot ment a felhasználói fiókjához tartozó ideiglenes mappába. Az egy napnál régebbi másolatokat az alkalmazás indításkor törli.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] A kiszolgáló nem helyezte át az üzenetet (cél: { $folder }), így { $messages } ismét az eredeti mappájában van ({ $from }): { $reason }
   *[other] A kiszolgáló nem helyezte át az üzeneteket (cél: { $folder }), így { $messages } ismét az eredeti mappájában van ({ $from }): { $reason }
}
undone-delete = { $count ->
    [one] A kiszolgáló nem törölte az üzenetet, így { $messages } ismét az eredeti mappájában van ({ $from }): { $reason }
   *[other] A kiszolgáló nem törölte az üzeneteket, így { $messages } ismét az eredeti mappájában van ({ $from }): { $reason }
}
undone-archive = { $count ->
    [one] A kiszolgáló nem archiválta az üzenetet, így { $messages } ismét az eredeti mappájában van ({ $from }): { $reason }
   *[other] A kiszolgáló nem archiválta az üzeneteket, így { $messages } ismét az eredeti mappájában van ({ $from }): { $reason }
}
undone-read = { $count ->
    [one] A kiszolgáló nem jelölte olvasottként az üzenetet, így { $messages } ismét olvasatlan: { $reason }
   *[other] A kiszolgáló nem jelölte olvasottként az üzeneteket, így { $messages } ismét olvasatlan: { $reason }
}
undone-unread = { $count ->
    [one] A kiszolgáló nem jelölte olvasatlanként az üzenetet, így { $messages } ismét olvasott: { $reason }
   *[other] A kiszolgáló nem jelölte olvasatlanként az üzeneteket, így { $messages } ismét olvasott: { $reason }
}
undone-flags = { $count ->
    [one] A kiszolgáló nem módosította az üzenet jelölőit, ezért visszaállt az eredeti jelölés ({ $messages }): { $reason }
   *[other] A kiszolgáló nem módosította az üzenetek jelölőit, ezért visszaállt az eredeti jelölés ({ $messages }): { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = PDF-fájlok megjelenítése az üzenetekben
# review: new
preview-pdf-off = A PDF-fájlok nem jelennek meg az üzenetekben.
# review: new
preview-pdf-off-crashed = Egy PDF-fájl megjelenítés közben bezárta az Inbox Classicot, ezért a PDF-fájlok már nem jelennek meg az üzenetekben. A képek továbbra is megjelennek. A PDF-fájlok ismételt megjelenítéséhez kapcsolja be az olvasási beállításokban ezt: { $option }.
