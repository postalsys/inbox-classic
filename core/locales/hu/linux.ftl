# Magyar. Vázlat, anyanyelvi átnézésre vár.
# A Linux-alkalmazás saját ablakainak szavai (linux/src), gtk- kezdetű azonosítók. Az _ a gomb gyorsbillentyűjét jelöli.
# GNOME-szavak, ahol a GNOME-nak vannak (Beállítások, Kilépés).

## The main window

gtk-search-looks-in = A keresés a tárgyra, a feladókra és címzettekre, a mellékletek nevére és az üzenetek szövegére terjed ki. Keresés helye: { $place }. Ellenőrizze a beírt szavakat, vagy próbálkozzon kevesebb szóval.
gtk-search-still-indexing = { $count ->
    [one] 1 üzenet szövegének indexelése még folyamatban van. Hamarosan több találat is megjelenhet.
   *[other] { $count } üzenet szövegének indexelése még folyamatban van. Hamarosan több találat is megjelenhet.
}
gtk-search-results-everywhere = { $count ->
    [0] Nincs találat
    [one] 1 találat
   *[other] { $count } találat
} erre: „{ $words }” (összes mappa)
gtk-search-results-in = { $count ->
    [0] Nincs találat
    [one] 1 találat
   *[other] { $count } találat
} erre: „{ $words }” (hely: { $place })
gtk-search-indexing = { $count ->
    [one] 1 üzenet szövegének indexelése még folyamatban
   *[other] { $count } üzenet szövegének indexelése még folyamatban
}
gtk-list-loading = Betöltés...
gtk-menu-rename = Átnevezés...
gtk-import-one-question = Importálja ezt az üzenetet: { $file }? Célmappa: { $folder }
gtk-files-not-saved = Nem sikerült menteni: { $failed } fájl. Összesen: { $total } fájl.
gtk-unsubscribe-one-click = Leiratkozik erről a levelezőlistáról?

    Az Inbox Classic leiratkozási kérést küld ide: { $target }. Nem nyit meg weboldalt, és nem küld e-mailt.
gtk-unsubscribe-mail = Leiratkozik erről a levelezőlistáról?

    A leiratkozáshoz e-mailt kell küldeni ide: { $target }. Az Inbox Classic előkészíti az üzenetet. A leiratkozás megerősítéséhez küldje el.
gtk-unsubscribe-web =
    Leiratkozik erről a levelezőlistáról?

    A levelezőlista leiratkozási oldala megnyílik a böngészőben ({ $target }).
gtk-unsubscribe-failed = Nem sikerült leiratkozni: { $problem }
gtk-toolbar-create-mail-menu = Levélírás egy adott fiókból
gtk-toolbar-send-recv-menu = Levelek küldése és fogadása egy adott fiókban
gtk-main-menu = Főmenü
gtk-folder-list = Mappalista
gtk-quit = Kilépés

## The Move and Copy window

gtk-new-folder-at-top-of = Az új mappa a fiók legfelső szintjére kerül: { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Nincs olvasatlan üzenet
    [one] 1 olvasatlan üzenet
   *[other] { $count } olvasatlan üzenet
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Nincs küldésre váró üzenet.
gtk-outbox-row = Címzett: { $to }  ·  Sorba állítva: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Az Inbox Classic a háttérben továbbra is figyeli az új leveleket. Az alkalmazás megnyitásához vagy a kilépéshez használja az ikonját a felső sávon.
gtk-sign-in-again-ask =
    A bejelentkezést elutasították, vagy a munkamenet lejárt: { $account }.

    Újra bejelentkezik a böngészőben?
gtk-default-app-not-installed = Az Inbox Classic ezen példánya nincs telepítve, ezért a rendszer nem sorolja a levelezőalkalmazások közé. Telepítse, hogy kiválaszthassa.
gtk-default-app-now = Az Inbox Classic mostantól az alapértelmezett levelezőalkalmazás: az e-mail-hivatkozások itt nyitnak új üzenetet.
gtk-default-app-failed = Az Inbox Classicot nem sikerült alapértelmezett levelezőalkalmazássá tenni.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Dátum:
gtk-reader-files = Az üzenet mellékletei
gtk-files = { $count ->
    [one] { $count } fájl
   *[other] { $count } fájl
}
gtk-save-attachments-menu = Mellékletek mentése...

## The compose window

gtk-format-bold = Félkövér (Ctrl+B)
gtk-format-italic = Dőlt (Ctrl+I)
gtk-format-underline = Aláhúzott (Ctrl+U)
gtk-format-hyperlink = Hivatkozás (Ctrl+K)
gtk-font = Betűtípus
gtk-show-cc = _Másolat
gtk-show-bcc = _Titkos másolat
gtk-save-tip = Mentés (Ctrl+S)
gtk-link-status = { $link }    (megnyitás: Ctrl+kattintás)

## Accounts

gtk-plain-warning =
    Titkosítás nélkül bárki, aki lehallgatja a hálózati forgalmát, elolvashatja a jelszavát és az üzeneteit. Csak akkor folytassa, ha a kapcsolat más módon védett; a helyi hálózat önmagában nem biztosít titkosítást.

    Folytatja?
gtk-account-name-title = Fiók neve
gtk-display-name-title = Megjelenített név
gtk-turned-off-why = Ez a lehetőség ezen a számítógépen nem használható: „{ $button }”. { $reason }
gtk-turned-off-why-long = Ez a lehetőség ezen a számítógépen nem használható: „{ $button }”.

    { $reason }
gtk-next = Tovább >
gtk-provider-sign-in = Jelentkezzen be a szolgáltató webhelyén ({ $provider }) ezzel a fiókkal: { $address }. A jelszava nem jut el az Inbox Classichoz. Ha a fiókja támogatja az alkalmazásjelszavakat, a biztonsági beállításaiban létrehozhat egyet. Outlook.com és Microsoft 365 esetén használja a böngészős bejelentkezést.
gtk-provider-sign-in-apps = Jelentkezzen be a szolgáltató webhelyén ({ $provider }) ezzel a fiókkal: { $address }. Ehhez a További bejelentkezési lehetőségek alatt választhat bejelentkezési alkalmazást. Ha a fiókja támogatja az alkalmazásjelszavakat, a biztonsági beállításaiban létrehozhat egyet. Outlook.com és Microsoft 365 esetén használja a böngészős bejelentkezést.
gtk-accounts-add = Hozzáadás...
gtk-accounts-properties = Tulajdonságok...
gtk-accounts-signature = Aláírás...
gtk-accounts-sign-in-apps = Bejelentkezési alkalmazások...

## Sign-in apps

gtk-app-server = Kiszolgáló ({ $kind })
gtk-app-port = Port ({ $kind })
gtk-app-security = Kapcsolat biztonsága ({ $kind })
gtk-issuer-found = Bejelentkezési oldal: { $page }
    Tokenvégpont: { $endpoint }
gtk-client-id = Ügyfél-azonosító
gtk-client-secret = Titkos ügyfélkulcs
gtk-scopes = Hatókörök
gtk-redirect-uri = Átirányítási URI
gtk-issuer-usable =
    A kibocsátó használható.

    { $found }
gtk-app-built-in = Beépített bejelentkezési alkalmazás: { $app }. Csak azt módosíthatja, hogy megjelenjen-e az új fiókok bejelentkezési lehetőségei között. { $reason }
gtk-built-in = { $app } (beépített)
gtk-offered-for-new = Választható új fiókokhoz
gtk-edit-button = Szerkesztés...
gtk-remove-app-ask = Eltávolítja ezt a bejelentkezési alkalmazást és a mentett titkos ügyfélkulcsát: { $app }?
gtk-sign-in-apps-intro = A bejelentkezési alkalmazásokkal a böngészőben jelentkezhet be a fiókjaiba. Csak a bejelöltek választhatók új fiókok hozzáadásakor. A többit már használó fiókok továbbra is működnek.

## AI agents

gtk-agent-it-may = Engedélyezett műveletek
gtk-agent-accounts = Engedélyezett fiókok
gtk-never-used = Még nem használta a hozzáférést
gtk-last-used = Utoljára használva: { $date }
gtk-forget-program = Eltávolítja a programot a listából?
gtk-forget-program-detail = Az Inbox Classic törli a program mentett engedélyeit és ügynökeinek tevékenységnaplóját. A következő csatlakozáskor ismét engedélyt kér.
gtk-no-agents-yet = Még egy ügynök sem kért hozzáférést a leveleihez.
gtk-nothing-yet = Még semmi.

## Preferences

gtk-preferences = Beállítások
gtk-notify-subtitle = Csak amikor a főablak nem aktív

## The desktop entry and the page of the software stores

# a kulcsszavak, amelyek alapján az alkalmazáskeresés megtalálja az Inbox Classicot, mindegyik pontosvesszővel lezárva,
# csak magyarul: az angolok elé kerülnek
gtk-desktop-generic-name = Levelezőprogram
gtk-desktop-comment = E-mailek olvasása és írása: gyors, egyszerű levelezőprogram
gtk-desktop-keywords = levél;levelezés;posta;email;üzenet;beérkezett;
gtk-metainfo-summary = Gyors, egyszerű levelezőprogram
gtk-metainfo-description = Az Inbox Classic a hagyományos levelezőprogramok elrendezését követi: bal oldalon a mappák, felül az üzenetlista, alatta a kijelölt üzenet jelenik meg. IMAP- és SMTP-fiókokkal használható. Az Outlook.com és a Microsoft 365 esetén a böngészőben jelentkezhet be.
gtk-metainfo-feature-sanitized = Az üzenetekből az alkalmazás eltávolítja a szkripteket, az internetes képeket pedig csak engedéllyel tölti le
gtk-metainfo-feature-search = Keresés a tárgyban, a feladók és címzettek adataiban, a mellékletnevekben és az üzenetszövegben, a Gmailből ismert keresőoperátorokkal
gtk-metainfo-feature-replies = A válaszokban az alkalmazás elrejti az idézett korábbi üzeneteket
gtk-metainfo-feature-offline = A letöltött levél helyi másolata internet nélkül is olvasható, amíg megmarad; a bejelentkezési adatokat rendszerint a rendszer elérhető kulcstartója tárolja
