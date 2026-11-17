# Magyar. Vázlat, anyanyelvi átnézésre vár.
# A Mac-alkalmazás saját ablakainak szavai (mac/Sources), mac- kezdetű azonosítók. Mac-szokás: három pont (…) a további
# adatot kérő parancsok után, kacskaringós idézőjelek.

## The app and its menus

# review: new
mac-quit = Kilépés az Inbox Classicból
# review: new
mac-settings = Beállítások…
# review: new
mac-services = Szolgáltatások
# review: new
mac-hide = Az Inbox Classic elrejtése
# review: new
mac-hide-others = Egyebek elrejtése
# review: new
mac-show-all = Az összes megjelenítése
# review: new
mac-check-updates = Frissítések keresése…
# review: new
mac-close-window = Ablak bezárása
# review: new
mac-redo = Ismétlés
# review: new
mac-cut = Kivágás
# review: new
mac-paste = Beillesztés
# review: new
mac-menu-window = Ablak
# review: new
mac-minimize = Kis méret
# review: new
mac-zoom = Nagyítás
# review: new
mac-no-updates = Az Inbox Classic ezen verziója nem támogatja az automatikus frissítést. Töltse le a legújabb verziót az inboxclassic.com oldalról.

## Settings

# review: new
mac-settings-title = Beállítások
# review: new
mac-check-updates-automatically = Frissítések automatikus keresése
# review: new
mac-settings-updates = Frissítések

## Dialogs

# review: new
mac-choose = Kiválasztás

## The main window

# review: new
mac-still-running-detail = Az Inbox Classic a háttérben továbbra is figyeli az új leveleket. Az alkalmazás megnyitásához kattintson az ikonjára a Dockban.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } üzenet a Postázandó üzenetek mappában
       *[other] { $count } üzenet a Postázandó üzenetek mappában
    }
# review: new
mac-sending = Küldés: { $subject }…
# review: new
mac-checking = Új üzenetek keresése: { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Az Inbox Classic ezen példánya nem alkalmazáscsomag, ezért nem lehet az alapértelmezett levelezőalkalmazás.
# review: new
mac-not-made-default = Az Inbox Classic nem lett az alapértelmezett levelezőalkalmazás: { $reason }
# review: new
mac-tool-search = Keresés

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] { $count } üzenet szövegének indexelése még folyamatban van, így hamarosan több találat is lehet.
       *[other] { $count } üzenet szövegének indexelése még folyamatban van, így hamarosan több találat is lehet.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Nincs találat erre: „{ $words }”, egyik mappában sem
        [one] { $count } találat erre: „{ $words }”, az összes mappában
       *[other] { $count } találat erre: „{ $words }”, az összes mappában
    }
# review: new
mac-results-in =
    { $count ->
        [0] Nincs találat erre: „{ $words }” (mappa: { $folder })
        [one] { $count } találat erre: „{ $words }” (mappa: { $folder })
       *[other] { $count } találat erre: „{ $words }” (mappa: { $folder })
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] { $count } üzenet szövegének indexelése még folyamatban
       *[other] { $count } üzenet szövegének indexelése még folyamatban
    }
# review: new
mac-folder-unread = { $folder }, { $count } olvasatlan
# review: new
mac-import-messages = Üzenetek importálása
# review: new
mac-save-messages = Üzenetek mentése
# review: new
mac-save-attachments-menu = Mellékletek mentése…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] { $count } fájlból { $failed } nem menthető.
    }
# review: new
mac-no-calendar-app = Ezen a Macen nincs naptáralkalmazás, amely megnyithatná a meghívókat (.ics fájlokat).
# review: new
mac-file-not-saved = A fájlt nem sikerült menteni.
# review: new
mac-unsubscribing = Leiratkozás: { $target }…
# review: new
mac-loading-list = Betöltés…

## The compose window

# review: new
mac-bold = Félkövér
# review: new
mac-italic = Dőlt
# review: new
mac-underline = Aláhúzott
# review: new
mac-bcc = Titkos másolat
# review: new
mac-command-click-to-open = Megnyitás: ⌘-kattintás
# review: new
mac-saving-to-drafts = Mentés a Piszkozatok mappába…
# review: new
mac-dont-save = Nincs mentés

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } fájl
       *[other] { $count } fájl
    }

## Accounts

# review: new
mac-next = Tovább
# review: new
mac-name-placeholder = Kovács Anna
# review: new
mac-more-sign-in-options = További bejelentkezési lehetőségek…
# review: new
mac-add-sign-in-app = Bejelentkezési alkalmazás hozzáadása…
# review: new
mac-looking-up = { $domain } beállításainak keresése…
# review: new
mac-add-button = Hozzáadás…
# review: new
mac-properties-button = Tulajdonságok…
# review: new
mac-signature-button = Aláírás…
# review: new
mac-security-button = Biztonság…
# review: new
mac-sign-in-apps-button = Bejelentkezési alkalmazások…

## AI agents

# review: new
mac-forget-program = Eltávolítja ezt a programot és az ügynökei tevékenységnaplóját?
# review: new
mac-forget-program-detail = A program engedélyei törlődnek. A következő csatlakozáskor újra engedélyt kér.

## Sign-in apps

# review: new
mac-checking-issuer = Ellenőrzés: { $issuer }…
# review: new
mac-edit-button = Szerkesztés…
# review: new
mac-use-for-new-accounts = Használat új fiókokhoz: { $name }
# review: new
mac-built-in = { $name } (beépített)

## Other windows

# review: new
mac-new-folder-button = Új mappa…
# review: new
mac-edit-link = Hivatkozás szerkesztése…
