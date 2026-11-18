# Magyar. Vázlat, anyanyelvi átnézésre vár.
# A Windows-alkalmazás saját ablakainak szavai (app/src), win- kezdetű azonosítók. Az & a menü- vagy gombbetűt jelöli.

## The main window

win-still-running-detail = Az Inbox Classic a háttérben továbbra is figyeli az új leveleket. A megnyitásához kattintson az ikonra. A kilépéshez kattintson jobb gombbal az ikonra, és válassza a Kilépés parancsot.
win-default-app-not-installed = Az Inbox Classic ezen példánya nincs telepítve, ezért a Windows nem sorolja a levelezőprogramok közé. Telepítse, hogy kiválaszthassa.
win-default-app-settings = A Windows megnyitja az Alapértelmezett alkalmazások beállításait. A MAILTO-hivatkozások megnyitásához válassza az Inbox Classicot.
win-no-unread = Nincs olvasatlan üzenet
win-unread-messages = { $count ->
    [one] 1 olvasatlan üzenet
   *[other] { $count } olvasatlan üzenet
}
win-print-failed = Az üzenetet nem sikerült kinyomtatni.
win-print-title-of = Nyomtatás - { $subject }
win-no-bodies = Az üzenetek tartalma nem jeleníthető meg.
win-webview-failed = A WebView2 létrehozása nem sikerült.
win-webview-missing = A WebView2 futtatókörnyezet nem érhető el.
win-list-loading = Betöltés...

## Buttons and words used in many windows

win-delete-button = &Törlés
win-find-label = &Keresés:
win-save-as-button = Mentés &másként...
win-too-many-files = Túl sok fájl egyszerre: válasszon kevesebbet.

## The Outbox


## The compose window

win-editor-failed = Nem lehet üzenetet írni.
win-ctrl-click-to-open = (megnyitás: { $ctrl }+kattintás)
win-format-bold = Félkövér ({ $ctrl }+B)
win-format-italic = Dőlt ({ $ctrl }+I)
win-format-underline = Aláhúzott ({ $ctrl }+U)
win-format-link = Hivatkozás ({ $ctrl }+K)
win-show-cc = &Másolat
win-show-bcc = &Titkos másolat
win-signature-title = Aláírás: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Nincs találat erre: „{ $words }” (összes mappa)
    [one] { $count } találat erre: „{ $words }” (összes mappa)
   *[other] { $count } találat erre: „{ $words }” (összes mappa)
}
win-search-found-in = { $count ->
    [0] Nincs találat erre: „{ $words }” (mappa: { $folder })
    [one] { $count } találat erre: „{ $words }” (mappa: { $folder })
   *[other] { $count } találat erre: „{ $words }” (mappa: { $folder })
}
win-search-indexing = { $count ->
    [one] { $count } üzenet szövegének indexelése még folyamatban
   *[other] { $count } üzenet szövegének indexelése még folyamatban
}
win-no-match-indexing = { $count ->
    [one] { $count } üzenet szövegének indexelése még folyamatban van, így hamarosan több találat is lehet.
   *[other] { $count } üzenet szövegének indexelése még folyamatban van, így hamarosan több találat is lehet.
}
win-files = { $count ->
    [one] { $count } fájl
   *[other] { $count } fájl
}
win-click-to-retry = Kattintson ide az újrapróbálkozáshoz.
win-save-attachments = Mellékletek &mentése...
win-files-not-saved = Nem sikerült menteni: { $failed } fájl. Összesen: { $count } fájl.
win-new-folder-in-highlighted = Az új mappa a kijelölt mappán belül jön létre.
win-delete-folder-ask = Törli ezt a mappát az üzeneteivel és a benne lévő mappákkal együtt: „{ $folder }”? A kiszolgálón is törlődik.
win-rename = Át&nevezés...
win-messages-not-saved = Az üzeneteket nem sikerült menteni.
win-messages-not-forwarded = Az üzeneteket nem sikerült továbbítani.

## Accounts

win-sign-in-google = Bejelentkezés Google-fiókkal
win-sign-in-microsoft = Bejelentkezés Microsoft-fiókkal
win-next = &Tovább >
win-your-account = a fiókja
win-browser-sign-in = (böngészős bejelentkezés)
win-add = &Hozzáadás...
win-properties-button = &Tulajdonságok...
win-signature-button = &Aláírás...
win-sign-in-apps-button = &Bejelentkezési alkalmazások...

## AI agents

win-dont-allow = &Tiltás
win-col-address = Cím
win-never-written-to = Még nem írt ide
win-book-find-label = Írjon be egy nevet vagy e-mail-címet:
win-send = &Küldés
win-dont-send = &Nincs küldés
win-unsubscribe = &Leiratkozás
win-dont-unsubscribe = &Nincs leiratkozás
win-forget-program-ask = Eltávolítja a programot a listából, és törli az engedélyeit, valamint az ügynökei tevékenységnaplóját? A következő csatlakozáskor az Inbox Classic ismét engedélyt kér.
win-clear-log-ask = Törli az ügynökök tevékenységnaplóját? Ez nem vonja vissza az ügynökök által végzett módosításokat.
win-agent-programs = &Programok, amelyek ügynökei hozzáférést kértek a leveleihez:
win-change = &Módosítás...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
win-undo-since = Visszavonás &időszakra...
# review: new
win-take-back = &Visszavonás
win-what-agents-did = Ügynöki &tevékenység:
# review: new
win-agent-reads = Olvasva { $from } és { $to } között:
# review: new
win-agent-reads-hint = Jelöljön ki fent egy olvasásokat összegző sort, hogy lássa, mit olvasott.
win-how-to-connect = Hogyan csatlakoztatható egy ügynök

## Sign-in apps

win-built-in = (beépített)
win-edit = &Szerkesztés...

## Options

win-folders-hide = A mappalista elrejtése
win-folders-pin = A mappalista rögzítése az üzenetek mellett
win-folders-show = A mappák megjelenítése

## The installer

# a telepítő saját szavai (installer/inbox-classic.nsi); { $version } és { $installed } verziószámok, 0.18.0
win-installer-start = Az Inbox Classic indítása
win-installer-welcome-new = A telepítő az Inbox Classic levelezőprogram következő verzióját telepíti: { $version }.

    A program csak az aktuális Windows-felhasználó számára települ, ezért nincs szükség rendszergazdai jogosultságra.
win-installer-welcome-same = Az Inbox Classic már telepítve van (verzió: { $version }). A telepítő újratelepíti a programot.

    A fiókok és a levelek megmaradnak.
win-installer-welcome-update = A telepítő frissíti az Inbox Classicot. Telepített verzió: { $installed }. Új verzió: { $version }.

    Ha a program fut, a telepítő előbb bezárja. A fiókok és a levelek megmaradnak.
win-installer-older-ask = Az Inbox Classic telepített verziója ({ $installed }) újabb a telepítőben lévőnél ({ $version }). Mégis telepíti a régebbi verziót?
win-installer-still-running = Az Inbox Classic még fut. Zárja be, és próbálja újra.
win-installer-remove-mail-ask = A fiókokat és az Inbox Classic által ezen a számítógépen tárolt leveleket is eltávolítja? A kiszolgálókon lévő levelek megmaradnak.
