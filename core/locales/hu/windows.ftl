# Magyar. Vázlat, anyanyelvi átnézésre vár.
# A Windows-alkalmazás saját ablakainak szavai (app/src), win- kezdetű azonosítók. Az & a menü- vagy gombbetűt jelöli.

## The main window

# review: new
win-still-running-detail = Az Inbox Classic a háttérben továbbra is figyeli az új leveleket. A megnyitásához kattintson az ikonra. A kilépéshez kattintson jobb gombbal az ikonra, és használja a menüjét.
# review: new
win-default-app-not-installed = Az Inbox Classic ezen példánya nincs telepítve, ezért a Windows nem sorolja a levelezőprogramok közé. Telepítse, hogy kiválaszthassa.
# review: new
win-default-app-settings = A Windows megnyitja az Alapértelmezett alkalmazások beállításait. A MAILTO-hivatkozások megnyitásához válassza az Inbox Classicot.
# review: new
win-no-unread = Nincs olvasatlan üzenet
# review: new
win-unread-messages = { $count ->
    [one] 1 olvasatlan üzenet
   *[other] { $count } olvasatlan üzenet
}
# review: new
win-print-failed = Az üzenetet nem sikerült kinyomtatni.
# review: new
win-print-title-of = Nyomtatás - { $subject }
# review: new
win-no-bodies = Az üzenetek törzse nem jeleníthető meg.
# review: new
win-webview-failed = A WebView2 létrehozása nem sikerült.
# review: new
win-webview-missing = A WebView2 futtatókörnyezet nem érhető el.

## Buttons and words used in many windows

# review: new
win-delete-button = &Törlés
# review: new
win-find-label = &Keresés:
# review: new
win-save-as-button = Mentés &másként...
# review: new
win-too-many-files = Túl sok fájl egyszerre: válasszon kevesebbet.

## The Outbox


## The compose window

# review: new
win-editor-failed = Nem lehet üzenetet írni.
# review: new
win-ctrl-click-to-open = (megnyitás: { $ctrl }+kattintás)
# review: new
win-format-bold = Félkövér ({ $ctrl }+B)
# review: new
win-format-italic = Dőlt ({ $ctrl }+I)
# review: new
win-format-underline = Aláhúzott ({ $ctrl }+U)
# review: new
win-format-link = Hivatkozás ({ $ctrl }+K)
# review: new
win-show-cc = &Másolat
# review: new
win-show-bcc = &Titkos másolat
# review: new
win-signature-title = Aláírás: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Nincs találat erre: „{ $words }”, egyik mappában sem
    [one] { $count } találat erre: „{ $words }”, az összes mappában
   *[other] { $count } találat erre: „{ $words }”, az összes mappában
}
# review: new
win-search-found-in = { $count ->
    [0] Nincs találat erre: „{ $words }” (mappa: { $folder })
    [one] { $count } találat erre: „{ $words }” (mappa: { $folder })
   *[other] { $count } találat erre: „{ $words }” (mappa: { $folder })
}
# review: new
win-search-indexing = { $count ->
    [one] { $count } üzenet szövegének indexelése még folyamatban
   *[other] { $count } üzenet szövegének indexelése még folyamatban
}
# review: new
win-no-match-indexing = { $count ->
    [one] { $count } üzenet szövegének indexelése még folyamatban van, így hamarosan több találat is lehet.
   *[other] { $count } üzenet szövegének indexelése még folyamatban van, így hamarosan több találat is lehet.
}
# review: new
win-files = { $count ->
    [one] { $count } fájl
   *[other] { $count } fájl
}
# review: new
win-click-to-retry = Kattintson ide az újrapróbálkozáshoz.
# review: new
win-save-attachments = Mellékletek &mentése...
# review: new
win-files-not-saved = { $count } fájlból { $failed } nem menthető.
# review: new
win-new-folder-in-highlighted = Az új mappa a kijelölt mappán belül jön létre.
# review: new
win-delete-folder-ask = Törli ezt a mappát az üzeneteivel és a benne lévő mappákkal együtt: „{ $folder }”? A kiszolgálón is törlődik.
# review: new
win-rename = Át&nevezés...
# review: new
win-messages-not-saved = Az üzeneteket nem sikerült menteni.
# review: new
win-messages-not-forwarded = Az üzeneteket nem sikerült továbbítani.

## Accounts

# review: new
win-sign-in-google = Bejelentkezés Google-fiókkal
# review: new
win-sign-in-microsoft = Bejelentkezés Microsoft-fiókkal
# review: new
win-next = &Tovább >
# review: new
win-your-account = a fiókja
# review: new
win-browser-sign-in = (böngészős bejelentkezés)
# review: new
win-add = &Hozzáadás...
# review: new
win-properties-button = &Tulajdonságok...
# review: new
win-signature-button = &Aláírás...
# review: new
win-sign-in-apps-button = &Bejelentkezési alkalmazások...

## AI agents

# review: new
win-dont-allow = &Tiltás
# review: new
win-col-address = Cím
# review: new
win-never-written-to = Még nem írt neki
# review: new
win-book-find-label = Írjon be egy nevet vagy e-mail-címet:
# review: new
win-send = &Küldés
# review: new
win-dont-send = &Nincs küldés
# review: new
win-forget-program-ask = Eltávolítja ezt a programot, az engedélyeit és az ügynökei tevékenységnaplóját? A következő csatlakozáskor újra engedélyt kér.
# review: new
win-clear-log-ask = Törli az ügynökök tevékenységnaplóját? Ez nem vonja vissza az ügynökök által végzett módosításokat.
# review: new
win-agent-programs = &Programok, amelyek ügynökei hozzáférést kértek a leveleihez:
# review: new
win-change = &Módosítás...
# review: new
win-what-agents-did = Ügynöki &tevékenység:
# review: new
win-how-to-connect = Hogyan csatlakoztatható egy ügynök

## Sign-in apps

# review: new
win-built-in = (beépített)
# review: new
win-edit = &Szerkesztés...

## Options

# review: new
win-options-language-label = Az Inbox Classic &nyelve:
# review: new
win-options-restart-note = A nyelv módosításához indítsa újra az Inbox Classicot.
# review: new
win-options-notify = É&rtesítés új levél érkezésekor
# review: new
win-restart-ask = Az Inbox Classic újraindítás után ezen a nyelven jelenik meg: { $language }. Újraindítja most?
# review: new
win-folders-hide = A mappalista elrejtése
# review: new
win-folders-pin = A mappalista rögzítése az üzenetek mellett
# review: new
win-folders-show = A mappák megjelenítése

## The installer

# a telepítő saját szavai (installer/inbox-classic.nsi); { $version } és { $installed } verziószámok, 0.18.0
# review: new
win-installer-start = Az Inbox Classic indítása
# review: new
win-installer-welcome-new =
    Ez telepíti az Inbox Classic { $version } verzióját, egy e-mail-programot.

    Nincs szükség rendszergazdai jogokra, csak az Ön fiókja számára települ.
# review: new
win-installer-welcome-same =
    Az Inbox Classic { $version } már telepítve van. Ez újratelepíti.

    A fiókjai és levelei megmaradnak.
# review: new
win-installer-welcome-update =
    Ez frissíti az Inbox Classicot ({ $installed }) erre a verzióra: { $version }.

    Ha fut, előbb bezárul. A fiókjai és levelei megmaradnak.
# review: new
win-installer-older-ask = Az Inbox Classic { $installed } verziója van telepítve, amely újabb ennél: { $version }. Mégis telepíti a régebbi verziót?
# review: new
win-installer-still-running = Az Inbox Classic még fut. Zárja be, és próbálja újra.
# review: new
win-installer-remove-mail-ask = A fiókokat és az Inbox Classic által ezen a számítógépen tárolt leveleket is eltávolítja? A kiszolgálókon lévő levelek megmaradnak.
