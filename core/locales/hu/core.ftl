# Magyar. Vázlat, anyanyelvi átnézésre vár (lásd core/locales/GLOSSARY.md).
# Amit a mag mond, minden platformon ugyanígy. A { $kapcsos } helyőrzőket a program tölti ki; maradjanak meg. A
# helyőrzőkhöz nem kapcsolunk ragot: inkább átfogalmazzuk a mondatot. Többes szám: [one] és *[other].

## Counts and sizes

messages = { $count ->
    [one] 1 üzenet
   *[other] { $count } üzenet
}
# a tizedesjel a méretekben: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] 1 bájt
   *[other] { $count } bájt
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Ki
# review: new
send-delay-seconds = { $count ->
    [one] 1 másodperc
   *[other] { $count } másodperc
}
# az állapotsor: „12 üzenet, 3 olvasatlan”
# review: new
list-counts = { $messages }, { $unread } olvasatlan
# review: new
list-counts-selected = { $messages }, { $unread } olvasatlan, { $selected } kijelölve
# review: new
list-counts-found = { $found } találat, { $unread } olvasatlan
# review: new
list-counts-found-selected = { $found } találat, { $unread } olvasatlan, { $selected } kijelölve
# review: new
list-counts-none = Nincs találat

## Special folders, as Outlook names them

# review: new
folder-inbox = Beérkezett üzenetek
# review: new
folder-sent = Elküldött elemek
# review: new
folder-deleted = Törölt elemek
# review: new
folder-drafts = Piszkozatok
# review: new
folder-junk = Levélszemét
# review: new
folder-archive = Archívum

## The reading pane

# review: new
reader-no-message = Nincs kijelölve üzenet.
# review: new
reader-downloading = Az üzenet letöltése…
# review: new
reader-downloading-detail = Az üzenet itt jelenik meg, amint a letöltés befejeződik.
# review: new
reader-downloading-size = Az üzenet mérete { $size }. Itt jelenik meg, amint letöltődött.
# review: new
reader-failed = Az üzenetet nem sikerült letölteni
# review: new
reader-failed-network = A levelezőkiszolgáló nem érhető el ({ $reason }).
# review: new
reader-failed-sign-in = A levelezőkiszolgáló nem fogadta el a bejelentkezést ({ $reason }). Ellenőrizze a jelszót, vagy jelentkezzen be újra a Fájl > Fiókok ablakban.
# review: new
reader-failed-security = Nem sikerült biztonságos kapcsolatot létesíteni a levelezőkiszolgálóval ({ $reason }).
# review: new
reader-failed-other = A levelezőkiszolgáló válasza: { $reason }.
# review: new
reader-retry-note = Újra megpróbáljuk, amikor a fiók ismét kapcsolódik.
# review: new
reader-unreadable = Ez az üzenet nem jeleníthető meg: { $error }
# review: new
message-source-title = Az üzenet forrása: { $subject }
# review: new
message-source-untitled = Az üzenet forrása

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Feladó
# review: new
header-date = Dátum
# review: new
header-to = Címzett
# review: new
header-cc = Másolat
# review: new
header-sent = Elküldve
# review: new
header-subject = Tárgy
# review: new
header-security = Biztonság
# review: new
header-part = { $number }. rész
# review: new
quote-original = ----- Eredeti üzenet -----
# review: new
fold-show-earlier = A korábbi üzenetek megjelenítése

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Az üzenetet nem sikerült kézbesíteni
# review: new
bounce-delayed = Az üzenet még nincs kézbesítve
# review: new
bounce-delayed-note = A levelezőkiszolgálója még próbálja kézbesíteni. Nem kell újra elküldenie.
# review: new
bounce-show-message = A kézbesíthetetlen üzenet megjelenítése
# review: new
bounce-show-delayed = A késő üzenet megjelenítése
# review: new
bounce-what-to-do = Mit tehet:
# review: new
bounce-delayed-do = Egyelőre semmit. Ha továbbra sem kézbesíthető, újabb értesítést kap.
# review: new
bounce-delayed-row-do = Egyelőre semmit. A levelezőkiszolgálója még próbálja kézbesíteni, és újabb értesítést kap, ha nem sikerül.
# review: new
bounce-details = Részletek
# review: new
bounce-someone = Egy címzett
# review: new
bounce-server = Kiszolgáló: { $server }
# review: new
bounce-status = Állapot: { $status }
# review: new
bounce-reported-by = Jelentette: { $server }
# review: new
bounce-retry-minutes = A fogadó kiszolgáló azt kérte, hogy a következő próbálkozás előtt várjon { $count ->
    [one] egy percet
   *[other] { $count } percet
}.
# review: new
bounce-retry-hours = A fogadó kiszolgáló azt kérte, hogy a következő próbálkozás előtt várjon { $count ->
    [one] egy órát
   *[other] { $count } órát
}.
# review: new
bounce-blocklist = Tiltólista: { $lists }
# review: new
bounce-user-unknown = A cím nem létezik
# review: new
bounce-user-unknown-why = A fogadó kiszolgálón nincs ilyen című postafiók. Lehet, hogy elírták, vagy a címzett már nem használja.
# review: new
bounce-user-unknown-do = Ellenőrizze a cím írásmódját, vagy kérdezze meg a címzettet, melyik címet használja most.
# review: new
bounce-invalid-address = A cím érvénytelen
# review: new
bounce-invalid-address-why = A cím nem olyan formában van megadva, amelyre levelet lehet küldeni.
# review: new
bounce-invalid-address-do = Keressen elírást, például szóközt, hiányzó betűt vagy üres részt a @ után.
# review: new
bounce-mailbox-disabled = A postafiók megszűnt
# review: new
bounce-mailbox-disabled-why = A cím létezik, de a postafiókot kikapcsolták, vagy már nem használják.
# review: new
bounce-mailbox-disabled-do = Keresse a címzettet más módon, és kérdezze meg, melyik címet használja most.
# review: new
bounce-mailbox-full = A postafiók megtelt
# review: new
bounce-mailbox-full-why = A címzett postafiókjában nincs hely új levelek számára.
# review: new
bounce-mailbox-full-do = Küldje el újra néhány nap múlva, vagy értesítse a címzettet más módon. A nagy mellékleteket utasítják vissza elsőként.
# review: new
bounce-spam-blocked = Levélszemétként visszautasítva
# review: new
bounce-spam-blocked-why = A fogadó kiszolgáló levélszemétnek tekintette az üzenetet.
# review: new
bounce-spam-blocked-do = Küldje el újra a levélszemétre emlékeztető részek nélkül, például sok hivatkozás, rövidített hivatkozások vagy nagy melléklet nélkül. Ha ez ismétlődik, forduljon a levelezési szolgáltatójához.
# review: new
bounce-virus-detected = Vírus miatt visszautasítva
# review: new
bounce-virus-detected-why = A fogadó kiszolgáló vírust vagy más kártékony tartalmat talált az üzenetben vagy a mellékleteiben.
# review: new
bounce-virus-detected-do = Ellenőrizze a mellékleteket víruskeresővel. Egyes kiszolgálók minden programot és tömörített fájlt visszautasítanak, ezért az ilyen fájlokat inkább hivatkozásként ossza meg.
# review: new
bounce-ip-blocklisted = A levelezőkiszolgálója tiltólistán van
# review: new
bounce-ip-blocklisted-why = A fogadó kiszolgáló visszautasítja a levelezőkiszolgálójától érkező leveleket, mert annak címe tiltólistán szerepel.
# review: new
bounce-ip-blocklisted-do = Nem az üzenettel van a gond. Továbbítsa ezt az értesítést a levelezési szolgáltatójának, és kérje meg, hogy vetesse le a kiszolgálót a listáról.
# review: new
bounce-domain-blocklisted = Egy tartomány tiltólistán van
# review: new
bounce-domain-blocklisted-why = A fogadó kiszolgáló visszautasítja az üzenetet, mert a címe tartománya vagy az üzenet hivatkozásainak egyik tartománya tiltólistán szerepel.
# review: new
bounce-domain-blocklisted-do = Ha az üzenetben hivatkozások vannak, próbálja meg nélkülük. Egyébként továbbítsa ezt az értesítést annak, aki a tartománya levelezését kezeli.
# review: new
bounce-policy-blocked = A fogadó kiszolgáló szabályai miatt visszautasítva
# review: new
bounce-policy-blocked-why = A fogadó kiszolgáló szabályai nem engedik át ezt az üzenetet, például a mérete, a mellékletei vagy a feladója miatt.
# review: new
bounce-policy-blocked-do = A kiszolgáló saját szavai a Részletek alatt gyakran megadják az okot. Kérdezze meg a címzettet, fogadhat-e ilyen levelet.
# review: new
bounce-geo-blocked = A származási helye miatt visszautasítva
# review: new
bounce-geo-blocked-why = A fogadó kiszolgáló nem fogad levelet abból az országból vagy hálózatból, ahol a levelezőkiszolgálója van.
# review: new
bounce-geo-blocked-do = Keresse a címzettet más módon, vagy kérdezze meg a levelezési szolgáltatóját.
# review: new
bounce-relay-denied = A kiszolgáló nem továbbította
# review: new
bounce-relay-denied-why = Egy kiszolgáló nem volt hajlandó továbbítani az üzenetet, gyakran azért, mert bejelentkezés nélkül vagy olyan kiszolgálón át küldték, amely nem kezeli ezt a címzettet.
# review: new
bounce-relay-denied-do = Ellenőrizze a fiók kimenő kiszolgálóját a Fájl > Fiókok ablakban, és azt, hogy bejelentkezik-e.
# review: new
bounce-auth-failure = A feladócímét nem sikerült hitelesíteni
# review: new
bounce-auth-failure-why = A fogadó kiszolgáló nem tudta megerősíteni, hogy az üzenet valóban az Ön tartományából jött (SPF, DKIM vagy DMARC).
# review: new
bounce-auth-failure-do = Továbbítsa ezt az értesítést annak, aki a tartománya levelezését kezeli: a beállításait javítani kell. Addig segíthet, ha a szolgáltatója saját kiszolgálóján keresztül küld.
# review: new
bounce-rate-limited = Túl sok levél egyszerre
# review: new
bounce-rate-limited-why = A fogadó kiszolgáló egyelőre kevesebb üzenetet fogad a levelezőkiszolgálójától.
# review: new
bounce-rate-limited-do = Várjon egy kicsit, és küldje el újra. Ha sok embernek ír, egyszerre kevesebbnek küldje.
# review: new
bounce-greylisting = Rövid időre visszatartva
# review: new
bounce-greylisting-why = A fogadó kiszolgáló arra kéri az ismeretlen feladókat, hogy kicsit később próbálkozzanak újra. Ez a levélszemét elleni szokásos ellenőrzés.
# review: new
bounce-greylisting-do = Semmit. A levelezőkiszolgálók maguktól újrapróbálkoznak, és az üzenet általában egy órán belül megérkezik.
# review: new
bounce-server-error = A fogadó kiszolgálón hiba történt
# review: new
bounce-server-error-why = A fogadó kiszolgáló nem volt elérhető, vagy saját hibája miatt nem tudta fogadni az üzenetet.
# review: new
bounce-server-error-do = Küldje el újra később. Ha továbbra sem sikerül, ellenőrizze, nincs-e elírás a cím @ utáni részében.
# review: new
bounce-unknown = Nincs kézbesítve
# review: new
bounce-unknown-why = Az értesítés nem mondja meg egyértelműen, miért.
# review: new
bounce-unknown-do = A kiszolgáló saját szavai a Részletek alatt többet mondhatnak. Ha nem segítenek, továbbítsa ezt az értesítést a levelezési szolgáltatójának.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] 1 üzenet kijelölve
   *[other] { $count } üzenet kijelölve
}
# review: new
selection-unread = { $count } olvasatlan
# review: new
selection-flagged = { $count } megjelölt
# review: new
delete-for-good-one = Ez az üzenet véglegesen törlődik. Törli?
# review: new
delete-for-good-all = Ezek az üzenetek ({ $count }) véglegesen törlődnek. Törli őket?
# review: new
delete-for-good-some = { $total } üzenetből { $count } véglegesen törlődik. Törli az üzeneteket?
# review: new
done-read = { $count ->
   *[other] Olvasottként megjelölve: { $messages }
}
# review: new
done-unread = { $count ->
   *[other] Olvasatlanként megjelölve: { $messages }
}
# review: new
done-flagged = { $count ->
   *[other] Jelölővel ellátva: { $messages }
}
# review: new
done-unflagged = Jelölő eltávolítva: { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Véglegesen törölve: { $messages }
}
# review: new
done-archived = { $count ->
   *[other] Archiválva: { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Áthelyezve: { $messages }. Cél: { $folder }
}
# review: new
done-copied = { $count ->
   *[other] Átmásolva: { $messages }. Cél: { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Áthelyezés: { $messages }. Cél: { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Másolás: { $messages }. Cél: { $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] Visszahelyezve: { $messages }. Cél: { $folder }
}
# review: new
done-watched = { $count ->
    [one] A beszélgetés figyelése bekapcsolva
   *[other] { $count } beszélgetés figyelése bekapcsolva
}
# review: new
done-unwatched = { $count ->
    [one] A beszélgetés figyelése kikapcsolva
   *[other] { $count } beszélgetés figyelése kikapcsolva
}
# review: new
done-ignored = { $count ->
    [one] A beszélgetés figyelmen kívül hagyva
   *[other] { $count } beszélgetés figyelmen kívül hagyva
}
# review: new
done-unignored = { $count ->
    [one] A beszélgetés újra figyelembe véve
   *[other] { $count } beszélgetés újra figyelembe véve
}
# review: new
their-folders = eredeti mappáik
# review: new
undo-move = Áthelyezés visszavonása
# review: new
undo-delete = Törlés visszavonása
# review: new
undo-archive = Archiválás visszavonása
# review: new
undo-junk = Levélszemétként jelölés visszavonása
# review: new
undo-not-junk = Nem levélszemétként jelölés visszavonása
# review: new
undo-send = Küldés visszavonása
# review: new
nothing-to-undo = Nincs mit visszavonni.
# review: new
messages-gone = Az üzenetek már nincsenek meg.
# review: new
folder-holds-no-messages = Ez a mappa nem tartalmazhat üzeneteket.
# review: new
not-archived-here = Az ebben a mappában lévő üzenetek nem archiválhatók.
# review: new
not-emptied-here = Csak a Törölt elemek és a Levélszemét mappa üríthető ki.
# review: new
next-unread-question = Nincs több olvasatlan üzenet ebben a mappában: { $folder }.

    Továbblép a következő mappára, amelyben olvasatlan üzenetek vannak? Ez a mappa: { $next }
# review: new
no-unread-left = Nem maradt olvasatlan üzenet.
# review: new
empty-question = { $count ->
    [one] Kiüríti ezt a mappát: { $folder }?

        A benne lévő üzenet véglegesen törlődik. Nem lehet visszaállítani.
   *[other] Kiüríti ezt a mappát: { $folder }?

        A benne lévő üzenetek ({ $messages }) véglegesen törlődnek. Nem lehet visszaállítani őket.
}
# review: new
no-junk-folder = Ennek a fióknak nincs Levélszemét mappája, ahová az üzeneteket át lehetne helyezni.
# review: new
no-inbox-folder = Ennek a fióknak nincs Beérkezett üzenetek mappája, ahová az üzeneteket át lehetne helyezni.
# az állapotsor egy színes jelölő után: „Kék jelölővel ellátva: 2 üzenet”
# review: new
done-flagged-color = { $color ->
    [red] Piros
    [orange] Narancssárga
    [yellow] Sárga
    [green] Zöld
    [blue] Kék
    [purple] Lila
   *[gray] Szürke
    } jelölővel ellátva: { $messages }
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Üzenet áthelyezése
   *[other] { $count } üzenet áthelyezése
}
# review: new
move-window-title-copy = { $count ->
    [one] Üzenet másolása
   *[other] { $count } üzenet másolása
}
# review: new
move-window-prompt-move = { $count ->
    [one] A kijelölt üzenet áthelyezése ide:
   *[other] A kijelölt { $count } üzenet áthelyezése ide:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] A kijelölt üzenet másolása ide:
   *[other] A kijelölt { $count } üzenet másolása ide:
}
# review: new
targets-recent = Legutóbbiak
# review: new
target-current = { $folder } (jelenlegi)
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Áthelyezés: { $done } / { $messages }. Cél: { $folder }...
# review: new
transfer-copying = Másolás: { $done } / { $messages }. Cél: { $folder }...
# review: new
transfer-another-account = másik fiók
# review: new
transfer-folder-gone = a célmappa már nem létezik
# review: new
transfer-not-on-server = az üzenet már nincs a kiszolgálón
# review: new
transfer-not-moved = { $count ->
   *[other] Nem sikerült másik fiókba áthelyezni: { $messages }. Ok: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] Nem sikerült másik fiókba másolni: { $messages }. Ok: { $reason }
}
# review: new
transfer-none-moved = Egy üzenetet sem sikerült áthelyezni
# review: new
transfer-none-copied = Egy üzenetet sem sikerült átmásolni

## Messages as files

# review: new
export-not-in-time = az üzenetet nem sikerült időben letölteni
# review: new
export-not-saved = { $messages } közül { $failed } nem menthető ({ $problems })
# review: new
export-not-attached = az üzeneteket nem sikerült csatolni: { $error }
# az állapotsor a Mentés másként után: „Mentve: 3 üzenet. Hely: Asztal”
# review: new
saved-to = { $count ->
   *[other] Mentve: { $messages }. Hely: { $folder }
}
# review: new
download-progress = Letöltés: { $done } / { $total }
# review: new
download-done = Letöltve: { $size }
# review: new
downloading-messages = { $count ->
   *[other] Letöltés: { $messages }...
}
# review: new
import-put = { $count ->
   *[other] Elhelyezve: { $messages }. Mappa: { $folder }
}
# review: new
import-not-put = Ezek nem kerültek a mappába:

    { $problems }

## Problems the windows show

# review: new
error-store = helyi tároló: { $error }
# review: new
error-not-found = nem található
# review: new
error-closed = leállás folyamatban
# review: new
error-other-account = a böngészőben ezzel a fiókkal történt a bejelentkezés: { $email }. Ez nem ez a fiók
# review: new
failure-authentication = a kiszolgáló nem fogadta el a bejelentkezést ({ $reason })
# review: new
failure-network = nem sikerült kapcsolódni a kiszolgálóhoz ({ $reason })
# review: new
error-in-use = nem távolítható el, amíg ezek a fiókok ezzel jelentkeznek be: { $accounts }
# review: new
error-turned-off = ez a bejelentkezési alkalmazás ki van kapcsolva az új fiókok számára
# review: new
error-folder-name = a mappa neve 1 és 200 karakter közötti hosszúságú lehet, és nem tartalmazhat vezérlőkaraktert
# review: new
error-folder-separator = ezen a kiszolgálón a mappa neve nem tartalmazhatja ezt a karaktert: „{ $separator }”
# review: new
error-folder-special = a Beérkezett üzenetek és a különleges mappák nem nevezhetők át és nem törölhetők
# review: new
error-no-recipients = az üzenetnek nincs címzettje
# review: new
error-bad-address = „{ $address }” nem e-mail-cím
# review: new
error-not-own-address = { $address } nem tartozik a fiók feladócímei közé. Vegye fel a fiók tulajdonságaiban az „Egyéb feladócímek” mezőbe.
# review: new
rule-query-refused = A szabályok nem szűrhetnek mappára vagy dátumra ({ $words }).
# review: new
rule-no-query = Adja meg a bejövő üzenetek keresési feltételeit.
# review: new
rule-no-action = Válasszon legalább egy műveletet a szabályhoz.
# review: new
error-attachment = Nem sikerült beolvasni: { $path }. Ok: { $error }
# review: new
error-no-drafts = a fióknak nincs Piszkozatok mappája, ahová az üzenetet menteni lehetne
# review: new
error-draft-attachment = a piszkozat egyik mellékletét nem sikerült megtartani: { $error }
# review: new
error-password-not-saved = a jelszót nem sikerült elmenteni a következő indításhoz: { $error }
# review: new
error-sign-in-not-saved = az új bejelentkezési adatokat nem sikerült elmenteni a következő indításhoz: { $error }
# review: new
error-import-unreadable = Nem olvasható: { $path }. Ok: { $error }
# review: new
error-import-too-large = 50 MB-nál nagyobb: { $path }
# review: new
error-import-not-mail = Nem e-mail-üzenet: { $path }
# review: new
error-list-answered = a levelezőlista kiszolgálója ezt az állapotot adta vissza: { $status }
# review: new
error-not-built = az üzenetet nem sikerült összeállítani
# review: new
error-outbox-waits = { $count ->
    [one] az üzenet a Postázandó üzenetek mappában vár, és a következő küldéskor/fogadáskor megy el
   *[other] { $count } üzenet vár a Postázandó üzenetek mappában, és a következő küldéskor/fogadáskor mennek el
}
# review: new
error-draft-not-removed = az üzenet korábbi piszkozatát nem sikerült eltávolítani a Piszkozatok mappából: { $reason }
# review: new
error-sent-but = az üzenet elment, de { $problem }
# review: new
error-sent-still-in-outbox = még a Postázandó üzenetek mappában van: { $error }
# review: new
error-sent-no-copy = nem sikerült másolatot menteni az Elküldött elemek mappába: { $reason }
# review: new
error-no-password = ehhez a fiókhoz nincs jelszó
# review: new
error-no-sign-in = ehhez a fiókhoz nincs bejelentkezés
# review: new
error-provider-missing = ez a kiadás nem tud bejelentkezni ehhez a szolgáltatóhoz: { $provider }. Eltávolították a bejelentkezési alkalmazását?
# review: new
error-provider-servers = a fiók kiszolgálói nem egyeznek a bejelentkezési alkalmazásának kiszolgálóival
# review: new
error-app-scopes = { $reason }. A levelezőkiszolgáló nem fogadta el a bejelentkezési alkalmazás tokenjét: ellenőrizze, hogy az alkalmazás hatókörei hozzáférést adnak-e a levelekhez
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = A Google még nem hitelesítette az Inbox Classicot, ezért csak a tesztfelhasználók jelentkezhetnek be vele. Használja saját Google bejelentkezési alkalmazását vagy egy alkalmazásjelszót, vagy ha tesztfelhasználó, kapcsolja be a Bejelentkezési alkalmazások ablakban (Fájl > Fiókok).
# review: new
sign-in-off-other = Ki lett kapcsolva a Bejelentkezési alkalmazások ablakban (Fájl > Fiókok), ahol újra bekapcsolható.
# review: new
sign-in-app-no-name = a bejelentkezési alkalmazásnak nevet kell adni
# review: new
sign-in-app-no-client = hiányzik az ügyfél-azonosító
# review: new
sign-in-app-no-scopes = a bejelentkezési alkalmazásnak szüksége van a levelekhez hozzáférést adó hatókörökre
# review: new
sign-in-app-bad-host = hiányzik a kiszolgáló címe, vagy nem érvényes állomásnév ({ $server })
# review: new
sign-in-app-plain = a kiszolgálónak SSL/TLS vagy STARTTLS titkosítást kell használnia ({ $server })
# review: new
sign-in-app-not-checked = a kibocsátó még nincs ellenőrizve
# review: new
sign-in-app-issuer-changed = a kibocsátó megváltozott: írja be újra a titkos ügyfélkulcsot, vagy távolítsa el
# review: new
sign-in-register-google = A Google Cloud Console-ban hozzon létre egy Desktop app típusú OAuth-ügyfelet, a jóváhagyási képernyőjén a https://mail.google.com/ hatókörrel. Amíg az alkalmazás tesztelési állapotban van, csak a tesztfelhasználói jelentkezhetnek be vele.
# review: new
sign-in-register-microsoft = A Microsoft Entrában regisztráljon egy alkalmazást a Mobile and desktop applications platformmal, a http://localhost átirányítási URI-val, engedélyezett nyilvános ügyfélfolyamatokkal, valamint az IMAP.AccessAsUser.All, SMTP.Send és offline_access delegált engedélyekkel. Ha csak a saját szervezetének szól, kibocsátóként a https://login.microsoftonline.com/<bérlőazonosító>/v2.0 címet adja meg.
# review: new
sign-in-register-other = Regisztráljon egy natív (nyilvános) ügyfelet az alábbi átirányítási URI-val; a szolgáltatónak bármely portot engedélyeznie kell rajta (RFC 8252). Adja hozzá azt a hatókört, amellyel a szolgáltató hozzáférést ad a levelekhez.

## Calendar invitations

# review: new
repeats = Ismétlődés
# review: new
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
# review: new
repeats-on = { $repeats }, ezeken a napokon: { $days }
# „Minden héten, 10 alkalommal”
# review: new
repeats-times = { $count ->
    [one] { $repeats }, egyszer
   *[other] { $repeats }, { $count } alkalommal
}
# review: new
day-monday = hétfő
# review: new
day-tuesday = kedd
# review: new
day-wednesday = szerda
# review: new
day-thursday = csütörtök
# review: new
day-friday = péntek
# review: new
day-saturday = szombat
# review: new
day-sunday = vasárnap

## AI agents

# review: new
agent-level-read = Levelek olvasása: mappák, az üzenetlista, a keresés és az üzenetek
# review: new
agent-level-organize = Levelek rendezése: olvasottság, jelölők, levélszemét, áthelyezés, törlés a Törölt elemek mappába
# review: new
agent-level-drafts = Piszkozatok írása, amelyeket Ön küld el
# review: new
agent-level-send = Levelek küldése, mindegyik csak az Ön jóváhagyása után
# review: new
agent-connect-title = { $program } hozzá szeretne férni a leveleihez
# review: new
agent-connect-detail = Egy MI-ügynök szeretne az Inbox Classickal dolgozni. Válassza ki, mit tehet, és mely fiókokat láthatja; ezt később az Eszközök > MI-ügynökök menüpontban módosíthatja.

    Az ügynökök mások által írt leveleket olvasnak, és egy üzenet megpróbálhatja becsapni őket. Az Inbox Classic mindig megkérdezi Önt, mielőtt egy ügynök bármit elküld.
# review: new
agent-reply-to = Válasz erre: „{ $subject }”
# review: new
agent-reply-all-on = Válasz mindenkinek erre: „{ $subject }”
# review: new
agent-forward-of = Továbbítás: „{ $subject }”
# review: new
agent-never-written-one = Még soha nem írt erre a címre: { $address }.
# review: new
agent-never-written-many = E címek közül { $count } címre még soha nem írt.
# review: new
agent-send-title = { $program } el szeretné küldeni ezt az üzenetet
# review: new
agent-send-detail = Ellenőrizze a címzetteket és az üzenet tartalmát. Jóváhagyás után az üzenet { $seconds } másodpercig a Postázandó üzenetek mappában vár, ahol még törölheti.
# review: new
agent-change-title = { $program } jogosultságai
# review: new
agent-change-allowed = Módosítsa, mit tehetnek a program MI-ügynökei a leveleivel.
# review: new
agent-change-refused = Ön megtagadta a hozzáférést ettől a programtól. Engedélyezze, hogy az ügynökei ismét hozzáférjenek a leveleihez.
# review: new
agent-log-taken-back = { $entry } (visszavonva)
# review: new
agent-files = Fájlok: { $files }
# review: new
agent-undo-refused = Nem vonható vissza.
# review: new
agent-undo-refused-why = Nem vonható vissza: { $reason }.
# review: new
agent-undo-impossible = ez nem vonható vissza
# review: new
agent-undo-not-in-folder = az üzenet már nincs abban a mappában
# review: new
agent-undo-not-arrived = az üzenet (még) nincs a célmappában
# review: new
agent-undo-sent = az üzenet már elment
# review: new
agent-original-not-downloaded = az eredeti üzenet még nincs letöltve. Előbb nyissa meg
# review: new
agent-turned-away = Elutasítva
# review: new
agent-can-nothing = Semmi
# review: new
agent-can-read = olvasás
# review: new
agent-can-organize = rendezés
# review: new
agent-can-drafts = piszkozatok írása
# review: new
agent-can-send = küldés az Ön jóváhagyásával
# „Olvasás, rendezés és piszkozatok írása”
# review: new
agent-can-list = { $first } és { $last }
# review: new
agent-accounts = { $count ->
    [0] nincs fiók
    [one] 1 fiók
   *[other] { $count } fiók
}
# „Olvasás és rendezés; 1 fiók”
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Ez az üzenet nem olvasható.
# review: new
agent-encrypted-original = Ez az üzenet titkosított: az ügynök nem válaszolhat rá és nem továbbíthatja, mert nem tud titkosítani.
# review: new
agent-log-composed = Új üzenetben megnyitva, hogy Ön befejezze: „{ $subject }”
# review: new
agent-log-refused = Ön nem küldte el: „{ $subject }”
# review: new
agent-log-sent = Elküldve: „{ $subject }”. Címzett: { $to }
# review: new
agent-log-draft = Piszkozat mentve: „{ $subject }”
# review: new
agent-log-read = Olvasottként megjelölve: „{ $subject }”
# review: new
agent-log-unread = Olvasatlanként megjelölve: „{ $subject }”
# review: new
agent-log-flagged = Jelölővel ellátva: „{ $subject }”
# review: new
agent-log-unflagged = Jelölő eltávolítva: „{ $subject }”
# review: new
agent-log-deleted = Törölve: „{ $subject }”
# review: new
agent-log-moved = Áthelyezve: „{ $subject }”. Cél: { $folder }
# review: new
agent-log-junk = Levélszemétként megjelölve: „{ $subject }”
# review: new
agent-log-not-junk = Nem levélszemétként megjelölve: „{ $subject }”
# review: new
agent-log-archived = Archiválva: „{ $subject }”
# review: new
agent-log-folder = Mappa létrehozva: „{ $name }”
# review: new
agent-log-unsubscribed = Leiratkozás a levelezőlistáról: „{ $subject }”

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
sign-in-no-refresh = a szolgáltató nem adott frissítési tokent
# review: new
sign-in-no-account = a szolgáltató nem közölte, melyik fiók jelentkezett be
# review: new
sign-in-not-finished = a bejelentkezés nem fejeződött be
# review: new
secrets-unavailable = { $store } nem érhető el
# review: new
secrets-unavailable-why = { $store } nem érhető el: { $error }
# review: new
secrets-windows = a Hitelesítőadat-kezelő
# review: new
secrets-mac = a kulcskarika
# review: new
secrets-linux = a rendszer kulcstartója (Secret Service)
# review: new
error-no-such-file = nincs ilyen fájl
# review: new
cards-file-too-big = Ez a fájl túl nagy ahhoz, hogy címjegyzék legyen.
# review: new
ui-sender-added = Felvéve a Címjegyzékbe: { $name }
# review: new
ui-sender-known = Már szerepel a Címjegyzékben: { $name }
# review: new
ui-sender-none = Az üzenet feladójának nincs felvehető e-mail-címe.
# review: new
card-name-needed = A névjegynek nincs neve és e-mail-címe.
# a Címjegyzék importálása egy be nem olvasható fájlja: „contacts.vcf: nincs ilyen fájl”
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# review: new
otp-heading = { $domain } kódja
# review: new
otp-copy = Másolás
# review: new
otp-note = Csak { $domain } oldalain adja meg.
# review: new
otp-old = Ezt a kódot több mint egy órával a megnyitása előtt küldték, így valószínűleg már lejárt.

# a meghívottak száma egy esemény kártyáján
# review: new
event-attendees =
    { $count ->
        [one] { $count } résztvevő
       *[other] { $count } résztvevő
    }

# egy új üzenet értesítésének első sora, ha kódot tartalmaz
# review: new
otp-notification = { $code }: az Ön kódja ehhez: { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Érvényes
# review: new
pgp-key-expires = Érvényes eddig: { $date }
# review: new
pgp-key-expired = Lejárt: { $date }
# review: new
pgp-key-revoked = Visszavonva
# review: new
pgp-key-revoked-why = Visszavonva: { $reason }
# review: new
pgp-key-not-valid = Érvénytelen
# review: new
pgp-key-locked = Nem használható: az őt védő kulcs már nincs meg itt: { $store }. Importálja újra a biztonsági másolatát.
# review: new
pgp-source-own = Az Inbox Classicban készült
# review: new
pgp-source-file = Fájlból importálva
# review: new
pgp-source-paste = Beillesztve
# review: new
pgp-source-attachment = Üzenetből
# review: new
pgp-source-vcard = Névjegykártyáról
# review: new
pgp-source-wkd = A feladó levelezési szolgáltatójától
# review: new
pgp-source-keyserver = A keys.openpgp.org oldalról
# review: new
pgp-source-autocrypt = Egy üzenet Autocrypt fejlécéből
# review: new
pgp-error-no-store = A titkos kulcsokat ez védi: { $store }, de nem használható: { $error }
# review: new
pgp-error-wrong-passphrase = A jelmondat nem helyes.
# review: new
pgp-error-not-a-key = Ez nem OpenPGP-kulcs.
# review: new
pgp-error-too-large = A kulcs túl nagy.
# review: new
pgp-error-unusable = A kulcs régi vagy gyenge titkosítást használ, ezért nem használható.
# review: new
pgp-imported-private = { $count ->
    [one] A titkos kulcsa importálva.
   *[other] { $count } titkos kulcs importálva.
}
# review: new
pgp-imported-public = { $count ->
    [one] Egy kulcs importálva.
   *[other] { $count } kulcs importálva.
}
# review: new
pgp-imported-pending = Ezekhez a címekhez már egy másik kulcs tartozik: { $addresses }. Az új kulcs a névjegyben vár, amíg ki nem választja.
# review: new
pgp-error-needs-passphrase = A titkos kulcsot jelmondat védi. Írja be a kulcs importálásához.
# review: new
pgp-error-mismatch = A titkos kulcs nem tartozik a nyilvános kulcsához. Lehet, hogy módosították.
# review: new
pgp-file-name-public = { $who } nyilvános kulcsa.asc
# review: new
pgp-file-name-private = { $who } titkos kulcsának biztonsági másolata.asc
# review: new
pgp-pending = Egy másik kulcs került elő ehhez a címhez: { $address } (dátum: { $date }).

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Aláírta: { $signer }, a kulcs ellenőrizve
# review: new
pgp-part-signed = Aláírta: { $signer } (a kulcs nincs ellenőrizve)
# review: new
pgp-part-other = Aláírta: { $signer }, aki nem a feladó
# review: new
pgp-part-unknown-key = Aláírt, de a kulcs ismeretlen
# review: new
pgp-part-not-signed = Nincs aláírva
# review: new
pgp-part-not-checked = Az aláírás nincs ellenőrizve
# review: new
pgp-part-encrypted = Titkosított. { $signature }
# review: new
pgp-part-no-key = Olyan kulcsra titkosítva, amely nincs meg Önnek
# review: new
pgp-part-changed = A titkosított részt útközben módosították, ezért nem jelenik meg
# review: new
pgp-part-unprotected = Módosítás elleni védelem nélkül titkosítva, ezért nem jelenik meg
# review: new
pgp-part-broken = A titkosított rész nem olvasható
# review: new
pgp-why-mismatch = Az aláírás nem egyezik ezzel a szöveggel
# review: new
pgp-why-weak-hash = Az aláírás már nem biztonságos eljárást használ: { $hash }
# review: new
pgp-why-key-expired = A kulcs lejárta után aláírva (lejárat: { $date })
# review: new
pgp-why-key-revoked = Visszavont kulccsal aláírva
# review: new
pgp-why-not-signing-key = Olyan kulccsal aláírva, amely nem írhat alá
# review: new
pgp-why-from-future = Az aláírás dátuma a jövőben van
# review: new
pgp-why-signature-expired = Az aláírás lejárt
# review: new
pgp-why-key-not-valid = Érvénytelen kulccsal aláírva
# review: new
pgp-why-not-for-you = Más címzetteknek aláírva, Önnek továbbítva
# review: new
pgp-part-pictures-loaded = { $label }. A képek az internetről töltődtek be
# review: new
pgp-error-no-own-key = Nincs olyan kulcsa, amellyel ezt a címet aláírhatná vagy titkosíthatná: { $address }. Hozzon létre egyet az Eszközök > Titkosítási kulcsok menüpontban, vagy kapcsolja ki az Aláírást és a Titkosítást.
# review: new
pgp-error-missing-keys = { $count ->
    [one] Ennek a címzettnek nincs kulcsa a titkosításhoz: { $addresses }.
   *[other] Ezeknek a címzetteknek nincs kulcsa a titkosításhoz: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Ez az üzenet egy titkosított üzenetet idéz vagy továbbít, ezért csak titkosítva küldhető el. Kapcsolja be a Titkosítást, vagy távolítsa el az idézett szöveget.
# review: new
pgp-error-protect = Az üzenetet nem sikerült aláírni vagy titkosítani: { $reason }
# review: new
pgp-found-keys = Kulcs megtalálva: { $addresses }.
# review: new
pgp-found-none = Nem található kulcs: { $addresses }. Kérje meg őket, hogy küldjék el a nyilvános kulcsukat.
# review: new
pgp-found-no-key = Nem található kulcs.
# review: new
pgp-find-unavailable = A kulcsokat most nem sikerült megkeresni: { $error }
# review: new
pgp-publish-pending = A keys.openpgp.org megerősítő hivatkozást küldött ide: { $addresses }. A kulcsa akkor jelenik meg ott, amikor rákattint.
# review: new
pgp-publish-done = A kulcsa közzétéve a keys.openpgp.org oldalon ezekhez a címekhez: { $addresses }.
# review: new
pgp-publish-failed = A kulcsot nem sikerült közzétenni: { $error }
# review: new
pgp-keyserver-off = A kulcsok keresése a keys.openpgp.org oldalon ki van kapcsolva a Beállításokban.
# review: new
pgp-details-part = { $number }. rész: { $label }
# review: new
pgp-details-signed = Aláírva, időpont: { $when }, kulcs: { $key }
# review: new
pgp-details-unknown-key = Aláírva ezzel a kulccsal, amely nincs meg Önnek: { $key }
# review: new
pgp-details-opened = Az Ön kulcsára titkosítva: { $key }
# review: new
pgp-details-for = Titkosítva ezekre a kulcsokra: { $keys }
# review: new
pgp-details-plain = Nincs aláírva és nincs titkosítva
# review: new
pgp-bar-parts = Az üzenet részei ({ $count }): { $list }. Minden rész jelzi, hogyan védett.
# review: new
pgp-bar-count-verified = { $count } ellenőrzött
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 aláírt vagy titkosított
   *[other] { $count } aláírt vagy titkosított
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 figyelmet igényel
   *[other] { $count } figyelmet igényel
}
# review: new
pgp-bar-count-neutral = { $count } megerősített aláírás nélkül
# a beállításfájl: beállítások, fiókok, névjegyek és kulcsok átvitele egy másik számítógépre
# review: new
setup-part-settings = Beállítások
# review: new
setup-part-preferences = Ablakbeállítások
# review: new
setup-part-accounts = Fiókok
# review: new
setup-part-sign-in-apps = Bejelentkezési alkalmazások
# review: new
setup-part-contacts = Névjegyek és csoportok
# review: new
setup-part-keys = Titkosítási kulcsok
# review: new
setup-part-rules = Üzenetszabályok
# review: new
setup-part-trusted-senders = Megbízható feladók
# review: new
setup-holds-settings = { $count ->
    [one] 1 beállítás
   *[other] { $count } beállítás
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 ablakbeállítás
   *[other] { $count } ablakbeállítás
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 fiók
   *[other] { $count } fiók
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 bejelentkezési alkalmazás
   *[other] { $count } bejelentkezési alkalmazás
}
# review: new
setup-holds-built-in = Mely beépített bejelentkezési alkalmazások vannak bekapcsolva
# review: new
setup-holds-contacts = { $count ->
    [one] 1 névjegy
   *[other] { $count } névjegy
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 csoport
   *[other] { $count } csoport
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 saját kulcs
   *[other] { $count } saját kulcs
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 névjegyhez tartozó kulcs
   *[other] { $count } névjegyekhez tartozó kulcs
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 szabály
   *[other] { $count } szabály
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 megbízható feladó
   *[other] { $count } megbízható feladó
}
# review: new
setup-sign-in-password = Jelszó
# review: new
setup-account-secret-password = A jelszava benne van a fájlban.
# review: new
setup-account-secret-token = A bejelentkezése benne van a fájlban.
# review: new
setup-account-asks-password = Az importálás után kéri a jelszavát.
# review: new
setup-account-signs-in-again = Az importálás után újra be kell jelentkeznie.
# review: new
setup-account-here = Itt már be van állítva, ezért kimarad.
# review: new
setup-account-no-app = Ezzel jelentkezik be: { $app }, de az itt nincs beállítva. Importálja a bejelentkezési alkalmazásokat is.
# review: new
setup-invalid-address = „{ $address }” nem e-mail-cím.
# review: new
setup-invalid-server = A kiszolgálónak nincs használható neve vagy portja ({ $server }).
# review: new
setup-invalid-user = Nincs felhasználóneve.
# review: new
setup-invalid-sign-in = Olyan módon jelentkezik be, amelyet az Inbox Classic nem ismer.
# review: new
setup-error-empty = A fájl üres.
# review: new
setup-error-too-large = A fájl túl nagy ahhoz, hogy Inbox Classic-beállítás legyen.
# review: new
setup-error-not-setup = Ez a fájl nem Inbox Classic-beállítás.
# review: new
setup-error-damaged = A beállításfájl sérült, és nem olvasható.
# review: new
setup-error-newer = Ezt a beállítást az Inbox Classic egy újabb verziója ({ $version }) mentette. Frissítse az Inbox Classicot, majd importálja újra.
# review: new
setup-error-needs-passphrase = Ezt a beállítást jelmondat védi. Írja be azt a jelmondatot, amellyel mentették.
# review: new
setup-error-wrong-passphrase = Nem ezzel a jelmondattal mentették ezt a beállítást.
# review: new
setup-error-changed = A beállításfájlt a mentése után módosították vagy megsérült, ezért nem importálható.
# review: new
setup-error-read = A beállításfájlt nem sikerült beolvasni: { $error }
# review: new
setup-error-write = A beállítást nem sikerült menteni: { $error }
# review: new
setup-error-no-parts = Válasszon legalább egy részt.
# review: new
setup-left-out = { $count ->
    [one] { $part }: 1 bejegyzés nem használható, ezért kimarad.
   *[other] { $part }: { $count } bejegyzés nem használható, ezért kimaradnak.
}
# review: new
setup-imported-settings = A beállítások lecserélve.
# review: new
setup-imported-preferences = Az ablakbeállítások lecserélve.
# review: new
setup-added-accounts = { $count ->
    [one] 1 fiók hozzáadva.
   *[other] { $count } fiók hozzáadva.
}
# review: new
setup-skipped-here = Itt már be van állítva, ezért kimaradt: { $address }
# review: new
setup-skipped-no-app = Kimaradt: { $address }. Ezzel jelentkezik be: { $app }, de az itt nincs beállítva.
# review: new
setup-skipped-invalid = Kimaradt: { $address }. Ok: { $reason }
# review: new
setup-asks-password = { $address }: kapcsolódáskor kéri a jelszavát.
# review: new
setup-signs-in-again = { $address }: kapcsolódáskor újra be kell jelentkeznie.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] 1 bejelentkezési alkalmazás hozzáadva.
   *[other] { $count } bejelentkezési alkalmazás hozzáadva.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 bejelentkezési alkalmazás már be van itt állítva.
   *[other] { $count } bejelentkezési alkalmazás már be van itt állítva.
}
# review: new
setup-added-contacts = { $count ->
    [one] 1 névjegy hozzáadva a címjegyzékhez.
   *[other] { $count } névjegy hozzáadva a címjegyzékhez.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 névjegy már szerepel a címjegyzékben.
   *[other] { $count } névjegy már szerepel a címjegyzékben.
}
# review: new
setup-added-groups = { $count ->
    [one] 1 csoport hozzáadva vagy kiegészítve.
   *[other] { $count } csoport hozzáadva vagy kiegészítve.
}
# review: new
setup-added-own-keys = { $count ->
    [one] 1 saját kulcs hozzáadva.
   *[other] { $count } saját kulcs hozzáadva.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] 1 névjegyhez tartozó kulcs hozzáadva.
   *[other] { $count } névjegyekhez tartozó kulcs hozzáadva.
}
# review: new
setup-added-rules = { $count ->
    [one] 1 üzenetszabály hozzáadva.
   *[other] { $count } üzenetszabály hozzáadva.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 üzenetszabály már megvan itt.
   *[other] { $count } üzenetszabály már megvan itt.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 üzenetszabály olyan fiókhoz tartozik, amely itt nincs meg, ezért kimaradt.
   *[other] { $count } üzenetszabály olyan fiókokhoz tartozik, amelyek itt nincsenek meg, ezért kimaradtak.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 üzenetszabály olyan mappába helyez át üzeneteket, amely a fiókja szinkronizálása után jelenik meg.
   *[other] { $count } üzenetszabály olyan mappákba helyez át üzeneteket, amelyek a fiókjaik szinkronizálása után jelennek meg.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] 1 megbízható feladó hozzáadva.
   *[other] { $count } megbízható feladó hozzáadva.
}
# review: new
setup-nothing = Semmi sem lett importálva.
# review: new
setup-account-servers = { $imap } és { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic beállítások és fiókok
# review: new
setup-skipped-unreachable = Kimaradt: { $name }. A bejelentkezési szolgáltatása nem volt elérhető. Adja hozzá újra a Bejelentkezési alkalmazások ablakban.
# review: new
attachment-runs-programs = „{ $name }” programokat futtathat, ezért az Inbox Classic nem nyitja meg. Mentse, majd nyissa meg saját maga, ha megbízik a forrásában.
# review: new
attachment-decrypted-note = Ez a melléklet titkosított üzenetből származik. A megnyitásához az Inbox Classic visszafejtve tárolja ezen a számítógépen, egy saját mappában, amelyet az Inbox Classic egy nap után kiürít.
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
