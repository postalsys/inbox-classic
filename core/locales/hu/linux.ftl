# Magyar. Vázlat, anyanyelvi átnézésre vár.
# A Linux-alkalmazás saját ablakainak szavai (linux/src), gtk- kezdetű azonosítók. Az _ a gomb gyorsbillentyűjét jelöli.
# GNOME-szavak, ahol a GNOME-nak vannak (Beállítások, Kilépés).

## The main window

# review: new
gtk-search-looks-in = A keresés itt ({ $place }) a tárgyra, a feladókra, a címzettekre, a mellékletek nevére és az üzenetek szövegére terjed ki. Ellenőrizze a helyesírást, vagy próbáljon kevesebb szóval.
# review: new
gtk-search-still-indexing = { $count ->
    [one] 1 üzenet szövegének indexelése még folyamatban van. Hamarosan több találat is megjelenhet.
   *[other] { $count } üzenet szövegének indexelése még folyamatban van. Hamarosan több találat is megjelenhet.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Nincs találat
    [one] 1 találat
   *[other] { $count } találat
} erre: „{ $words }”, az összes mappában
# review: new
gtk-search-results-in = { $count ->
    [0] Nincs találat
    [one] 1 találat
   *[other] { $count } találat
} erre: „{ $words }” (hely: { $place })
# review: new
gtk-search-indexing = { $count ->
    [one] 1 üzenet szövegének indexelése még folyamatban
   *[other] { $count } üzenet szövegének indexelése még folyamatban
}
# review: new
gtk-list-loading = Betöltés...
# review: new
gtk-menu-rename = Átnevezés...
# review: new
gtk-import-one-question = Importálja ezt az üzenetet: { $file }? Célmappa: { $folder }
# review: new
gtk-files-not-saved = { $total } fájlból { $failed } nem menthető.
# review: new
gtk-unsubscribe-one-click =
    Leiratkozik erről a levelezőlistáról?

    Az Inbox Classic leiratkozási kérést küld ide: { $target }. Nem nyílik meg weboldal, és nem megy el e-mail.
# review: new
gtk-unsubscribe-mail =
    Leiratkozik erről a levelezőlistáról?

    A leiratkozáshoz e-mailt kell küldeni ide: { $target }. Az Inbox Classic előkészíti Önnek. A megerősítéshez küldje el az üzenetet.
# review: new
gtk-unsubscribe-web =
    Leiratkozik erről a levelezőlistáról?

    A levelezőlista leiratkozási oldala megnyílik a böngészőben ({ $target }).
# review: new
gtk-unsubscribe-failed = Nem sikerült leiratkozni: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Levélírás egy adott fiókból
# review: new
gtk-toolbar-send-recv-menu = Levelek küldése és fogadása egy adott fiókban
# review: new
gtk-main-menu = Főmenü
# review: new
gtk-folder-list = Mappalista
# review: new
gtk-quit = Kilépés

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Az új mappa a fiók legfelső szintjére kerül: { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Nincs olvasatlan üzenet
    [one] 1 olvasatlan üzenet
   *[other] { $count } olvasatlan üzenet
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Nincs küldésre váró üzenet.
# review: new
gtk-outbox-row = Címzett: { $to }  ·  Sorba állítva: { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Az Inbox Classic a háttérben továbbra is figyeli az új leveleket. Az alkalmazás megnyitásához vagy bezárásához használja az ikonját a felső sávon.
# review: new
gtk-sign-in-again-ask =
    A bejelentkezést elutasították, vagy a munkamenet lejárt: { $account }.

    Újra bejelentkezik a böngészőben?
# review: new
gtk-default-app-not-installed = Az Inbox Classic ezen példánya nincs telepítve, ezért a rendszer nem sorolja a levelezőalkalmazások közé. Telepítse, hogy kiválaszthassa.
# review: new
gtk-default-app-now = Az Inbox Classic mostantól az alapértelmezett levelezőalkalmazás: az e-mail-hivatkozások itt nyitnak új üzenetet.
# review: new
gtk-default-app-failed = Az Inbox Classicot nem sikerült alapértelmezett levelezőalkalmazássá tenni.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Dátum:
# review: new
gtk-reader-files = Az üzenet mellékletei
# review: new
gtk-files = { $count ->
    [one] { $count } fájl
   *[other] { $count } fájl
}
# review: new
gtk-pictures-blocked = Néhány kép le lett tiltva, hogy a feladó ne azonosíthassa a számítógépét.
# review: new
gtk-download-pictures = Képek letöltése
# review: new
gtk-save-attachments-menu = Mellékletek mentése...

## The compose window

# review: new
gtk-format-bold = Félkövér (Ctrl+B)
# review: new
gtk-format-italic = Dőlt (Ctrl+I)
# review: new
gtk-format-underline = Aláhúzott (Ctrl+U)
# review: new
gtk-format-hyperlink = Hivatkozás (Ctrl+K)
# review: new
gtk-font = Betűtípus
# review: new
gtk-show-cc = _Másolat
# review: new
gtk-show-bcc = _Titkos másolat
# review: new
gtk-save-tip = Mentés (Ctrl+S)
# review: new
gtk-link-status = { $link }    (megnyitás: Ctrl+kattintás)

## Accounts

# review: new
gtk-plain-warning =
    Titkosítás nélkül bárki, aki lehallgatja a hálózati forgalmát, elolvashatja a jelszavát és az üzeneteit. Ezt a kapcsolatot csak a saját számítógépén vagy helyi hálózatán futó kiszolgálóval használja.

    Folytatja?
# review: new
gtk-account-name-title = Fiók neve
# review: new
gtk-display-name-title = Megjelenített név
# review: new
gtk-turned-off-why = Ez a lehetőség ki van kapcsolva ezen a számítógépen: „{ $button }”. { $reason }
# review: new
gtk-turned-off-why-long =
    Ez a lehetőség ki van kapcsolva ezen a számítógépen: „{ $button }”.

    { $reason }
# review: new
gtk-next = Tovább >
# review: new
gtk-provider-sign-in = Jelentkezzen be { $provider } webhelyén ezzel a fiókkal: { $address }. A jelszava nem jut el az Inbox Classichoz. Használhat alkalmazásjelszót is, amelyet a fiókja biztonsági beállításaiban hozhat létre.
# review: new
gtk-provider-sign-in-apps = Jelentkezzen be { $provider } webhelyén valamelyik bejelentkezési alkalmazásával (További bejelentkezési lehetőségek) ezzel a fiókkal: { $address }. Használhat alkalmazásjelszót is, amelyet a fiókja biztonsági beállításaiban hozhat létre.
# review: new
gtk-accounts-add = Hozzáadás...
# review: new
gtk-accounts-properties = Tulajdonságok...
# review: new
gtk-accounts-signature = Aláírás...
# review: new
gtk-accounts-sign-in-apps = Bejelentkezési alkalmazások...

## Sign-in apps

# review: new
gtk-app-server = { $kind } kiszolgáló
# review: new
gtk-app-port = { $kind } port
# review: new
gtk-app-security = { $kind } biztonság
# review: new
gtk-issuer-found =
    Bejelentkezési oldal: { $page }
    Token végpont: { $endpoint }
# review: new
gtk-client-id = Ügyfél-azonosító
# review: new
gtk-client-secret = Titkos ügyfélkulcs
# review: new
gtk-scopes = Hatókörök
# review: new
gtk-redirect-uri = Átirányítási URI
# review: new
gtk-issuer-usable =
    A kibocsátó használható.

    { $found }
# review: new
gtk-app-built-in = { $app } beépített. Csak azt módosíthatja, hogy felkínálja-e az új fiókokhoz. { $reason }
# review: new
gtk-built-in = { $app } (beépített)
# review: new
gtk-offered-for-new = Felkínálva új fiókokhoz
# review: new
gtk-edit-button = Szerkesztés...
# review: new
gtk-remove-app-ask = Eltávolítja ezt a bejelentkezési alkalmazást és a mentett titkos ügyfélkulcsát: { $app }?
# review: new
gtk-sign-in-apps-intro = A bejelentkezési alkalmazásokkal a fiókok a böngészőben jelentkezhetnek be. Amelyik ki van kapcsolva, azt nem kínáljuk fel új fiókokhoz; az azt már használó fiókok továbbra is működnek.

## AI agents

# review: new
gtk-agent-it-may = Engedélyezett műveletek
# review: new
gtk-agent-accounts = Engedélyezett fiókok
# review: new
gtk-never-used = Még nem használta
# review: new
gtk-last-used = Utoljára használva: { $date }
# review: new
gtk-forget-program = Eltávolítja ezt a programot?
# review: new
gtk-forget-program-detail = A program engedélyei és az ügynökei tevékenységnaplója törlődik. A következő csatlakozáskor újra engedélyt kér.
# review: new
gtk-no-agents-yet = Még egy ügynök sem kért hozzáférést a leveleihez.
# review: new
gtk-nothing-yet = Még semmi.

## Preferences

# review: new
gtk-preferences = Beállítások
# review: new
gtk-language = Nyelv
# review: new
gtk-language-subtitle = Az alkalmazás és a súgó nyelve
# review: new
gtk-new-mail-group = Új levelek
# a Beállítások sora, amely bekapcsolja az új levél értesítését, GNOME-stílusú mondatkezdő nagybetűvel
# review: new
gtk-notify-new-mail = Értesítés új levélről
# review: new
gtk-notify-subtitle = Értesítés, ha új üzenetek érkeznek, miközben az ablak a háttérben van
# review: new
gtk-restart-to-change = Az Inbox Classic újraindul a nyelv módosításához.

## The desktop entry and the page of the software stores

# a kulcsszavak, amelyek alapján az alkalmazáskeresés megtalálja az Inbox Classicot, mindegyik pontosvesszővel lezárva,
# csak magyarul: az angolok elé kerülnek
# review: new
gtk-desktop-generic-name = Levelezőprogram
# review: new
gtk-desktop-comment = E-mailek olvasása és írása: gyors, egyszerű levelezőprogram
# review: new
gtk-desktop-keywords = levél;levelezés;posta;email;üzenet;beérkezett;
# review: new
gtk-metainfo-summary = Gyors, egyszerű levelezőprogram
# review: new
gtk-metainfo-description = Az Inbox Classic úgy olvassa és írja az e-maileket, ahogy a levelezőprogramok régen: bal oldalon a mappák, felül az üzenetek, alattuk az üzenet. Bármilyen IMAP- és SMTP-fiókkal működik, és a böngészőn keresztül jelentkezik be az Outlook.com és a Microsoft 365 szolgáltatásba.
# review: new
gtk-metainfo-feature-sanitized = Minden üzenet megtisztítva, szkriptek nélkül jelenik meg, és az internetről származó képek csak az Ön engedélyével
# review: new
gtk-metainfo-feature-search = Keresés, amely megtalálja a szavakat a tárgyban, a feladókban és címzettekben, a fájlnevekben és a szövegben, a Gmail keresőoperátoraival
# review: new
gtk-metainfo-feature-replies = A válaszok elrejtik az általuk idézett korábbi üzeneteket
# review: new
gtk-metainfo-feature-offline = A levelek internet nélkül is olvashatók; a jelszavak a kulcstartójában vannak
