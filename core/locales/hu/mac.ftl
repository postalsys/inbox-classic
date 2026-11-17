# Magyar. Vázlat, anyanyelvi átnézésre vár.
# A Mac-alkalmazás saját ablakainak szavai (mac/Sources), mac- kezdetű azonosítók. Mac-szokás: három pont (…) a további
# adatot kérő parancsok után, kacskaringós idézőjelek.

## The app and its menus

mac-quit = Kilépés az Inbox Classicból
mac-settings = Beállítások…
mac-services = Szolgáltatások
mac-hide = Az Inbox Classic elrejtése
mac-hide-others = Egyebek elrejtése
mac-show-all = Az összes megjelenítése
mac-check-updates = Frissítések keresése…
mac-close-window = Ablak bezárása
mac-redo = Ismétlés
mac-cut = Kivágás
mac-paste = Beillesztés
mac-menu-window = Ablak
mac-minimize = Kis méret
mac-zoom = Nagyítás
mac-no-updates = Az Inbox Classic ezen verziója nem támogatja az automatikus frissítést. Töltse le a legújabb verziót az inboxclassic.com oldalról.

## Settings

mac-settings-title = Beállítások
mac-check-updates-automatically = Frissítések automatikus keresése
mac-settings-updates = Frissítések

## Dialogs

mac-choose = Kiválasztás

## The main window

mac-still-running-detail = Az Inbox Classic a háttérben továbbra is figyeli az új leveleket. Az alkalmazás megnyitásához kattintson az ikonjára a Dockban.
mac-outbox-waiting =
    { $count ->
        [one] { $count } üzenet a Postázandó üzenetek mappában
       *[other] { $count } üzenet a Postázandó üzenetek mappában
    }
mac-sending = Küldés: { $subject }…
mac-checking = Új üzenetek keresése: { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Az Inbox Classic ezen példánya nem alkalmazáscsomag, ezért nem lehet az alapértelmezett levelezőalkalmazás.
mac-not-made-default = Nem sikerült az Inbox Classicot alapértelmezett levelezőalkalmazássá tenni: { $reason }
mac-tool-search = Keresés

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] { $count } üzenet szövegének indexelése még folyamatban van, így hamarosan több találat is lehet.
       *[other] { $count } üzenet szövegének indexelése még folyamatban van, így hamarosan több találat is lehet.
    }
mac-results-everywhere = { $count ->
        [0] Nincs találat erre: „{ $words }” (összes mappa)
        [one] { $count } találat erre: „{ $words }” (összes mappa)
       *[other] { $count } találat erre: „{ $words }” (összes mappa)
    }
mac-results-in =
    { $count ->
        [0] Nincs találat erre: „{ $words }” (mappa: { $folder })
        [one] { $count } találat erre: „{ $words }” (mappa: { $folder })
       *[other] { $count } találat erre: „{ $words }” (mappa: { $folder })
    }
mac-still-indexing =
    { $count ->
        [one] { $count } üzenet szövegének indexelése még folyamatban
       *[other] { $count } üzenet szövegének indexelése még folyamatban
    }
mac-folder-unread = { $folder }, { $count } olvasatlan
mac-import-messages = Üzenetek importálása
mac-save-messages = Üzenetek mentése
mac-save-attachments-menu = Mellékletek mentése…
mac-files-not-saved = { $count ->
       *[other] Nem sikerült menteni: { $failed } fájl. Összesen: { $count } fájl.
    }
mac-no-calendar-app = Ezen a Macen nincs naptáralkalmazás, amely megnyithatná a meghívókat (.ics fájlokat).
mac-file-not-saved = A fájlt nem sikerült menteni.
mac-unsubscribing = Leiratkozás: { $target }…
mac-loading-list = Betöltés…

## The compose window

mac-bold = Félkövér
mac-italic = Dőlt
mac-underline = Aláhúzott
mac-bcc = Titkos másolat
mac-command-click-to-open = Megnyitás: ⌘-kattintás
mac-saving-to-drafts = Mentés a Piszkozatok mappába…
mac-dont-save = Nincs mentés

## The reading pane

mac-files =
    { $count ->
        [one] { $count } fájl
       *[other] { $count } fájl
    }

## Accounts

mac-next = Tovább
mac-name-placeholder = Kovács Anna
mac-more-sign-in-options = További bejelentkezési lehetőségek…
mac-add-sign-in-app = Bejelentkezési alkalmazás hozzáadása…
mac-looking-up = { $domain } beállításainak keresése…
mac-add-button = Hozzáadás…
mac-properties-button = Tulajdonságok…
mac-signature-button = Aláírás…
mac-security-button = Biztonság…
mac-sign-in-apps-button = Bejelentkezési alkalmazások…

## AI agents

mac-forget-program = Eltávolítja a programot a listából, és törli az ügynökei tevékenységnaplóját?
mac-forget-program-detail = A program mentett engedélyei törlődnek. A következő csatlakozáskor az Inbox Classic ismét engedélyt kér.

## Sign-in apps

mac-checking-issuer = Ellenőrzés: { $issuer }…
mac-edit-button = Szerkesztés…
mac-use-for-new-accounts = Használat új fiókokhoz: { $name }
mac-built-in = { $name } (beépített)

## Other windows

mac-new-folder-button = Új mappa…
mac-edit-link = Hivatkozás szerkesztése…
