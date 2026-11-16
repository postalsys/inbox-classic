# Polski. Słowa okien aplikacji dla Maca (mac/Sources), identyfikatory mac-. Zwyczaje Maca: wielokropek (…) po
# poleceniu, które o coś pyta, cudzysłowy „ ” i apostrofy typograficzne; w języku polskim wielka litera tylko na
# początku.

## The app and its menus

# review: new
mac-quit = Zakończ Inbox Classic
# review: new
mac-settings = Ustawienia…
# review: new
mac-services = Usługi
# review: new
mac-hide = Ukryj Inbox Classic
# review: new
mac-hide-others = Ukryj pozostałe
# review: new
mac-show-all = Pokaż wszystkie
# review: new
mac-check-updates = Sprawdź uaktualnienia…
# review: new
mac-close-window = Zamknij okno
# review: new
mac-redo = Powtórz
# review: new
mac-cut = Wytnij
# review: new
mac-paste = Wklej
# review: new
mac-menu-window = Okno
# review: new
mac-minimize = Minimalizuj
# review: new
mac-zoom = Zmień rozmiar
# review: new
mac-no-updates = Ta wersja Inbox Classic nie obsługuje automatycznych uaktualnień. Pobierz najnowszą wersję z inboxclassic.com.

## Settings

# review: new
mac-settings-title = Ustawienia
# review: new
mac-language-label = Język:
# review: new
mac-restart-hint = Uruchom ponownie Inbox Classic, aby zmienić język.
# review: new
mac-notify-new-mail = Powiadamiaj mnie o nowej poczcie
# review: new
mac-restart-question = Uruchomić ponownie Inbox Classic teraz, aby zmienić język?

## Dialogs

# review: new
mac-choose = Wybierz

## The main window

# review: new
mac-still-running-detail = Inbox Classic nadal sprawdza nową pocztę w tle. Kliknij jego ikonę w Docku, aby otworzyć aplikację.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } wiadomość w Skrzynce nadawczej
        [few] { $count } wiadomości w Skrzynce nadawczej
        [many] { $count } wiadomości w Skrzynce nadawczej
       *[other] { $count } wiadomości w Skrzynce nadawczej
    }
# review: new
mac-sending = Wysyłanie: { $subject }…
# review: new
mac-checking = Sprawdzanie nowych wiadomości na koncie { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Ta kopia Inbox Classic nie jest pakietem aplikacji, więc nie może być domyślną aplikacją pocztową.
# review: new
mac-not-made-default = Nie ustawiono Inbox Classic jako domyślnej aplikacji pocztowej: { $reason }
# review: new
mac-tool-search = Szukaj

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Tekst { $count } wiadomości jest jeszcze indeksowany, więc wkrótce może zostać znalezionych więcej.
        [few] Tekst { $count } wiadomości jest jeszcze indeksowany, więc wkrótce może zostać znalezionych więcej.
        [many] Tekst { $count } wiadomości jest jeszcze indeksowany, więc wkrótce może zostać znalezionych więcej.
       *[other] Tekst { $count } wiadomości jest jeszcze indeksowany, więc wkrótce może zostać znalezionych więcej.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Brak wyników dla „{ $words }” we wszystkich folderach
        [one] { $count } wynik dla „{ $words }” we wszystkich folderach
        [few] { $count } wyniki dla „{ $words }” we wszystkich folderach
        [many] { $count } wyników dla „{ $words }” we wszystkich folderach
       *[other] { $count } wyników dla „{ $words }” we wszystkich folderach
    }
# review: new
mac-results-in =
    { $count ->
        [0] Brak wyników dla „{ $words }” w folderze { $folder }
        [one] { $count } wynik dla „{ $words }” w folderze { $folder }
        [few] { $count } wyniki dla „{ $words }” w folderze { $folder }
        [many] { $count } wyników dla „{ $words }” w folderze { $folder }
       *[other] { $count } wyników dla „{ $words }” w folderze { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] trwa indeksowanie tekstu { $count } wiadomości
        [few] trwa indeksowanie tekstu { $count } wiadomości
        [many] trwa indeksowanie tekstu { $count } wiadomości
       *[other] trwa indeksowanie tekstu { $count } wiadomości
    }
# review: new
mac-folder-unread = { $folder }, nieprzeczytane: { $count }
# review: new
mac-import-messages = Importuj wiadomości
# review: new
mac-save-messages = Zapisz wiadomości
# review: new
mac-save-attachments-menu = Zapisz załączniki…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Nie udało się zapisać { $failed } z { $count } plików.
    }
# review: new
mac-no-calendar-app = Na tym Macu nie ma aplikacji kalendarza, która otworzy zaproszenia (pliki .ics).
# review: new
mac-file-not-saved = Nie udało się zapisać pliku.
# review: new
mac-unsubscribing = Wypisywanie z { $target }…

## The compose window

# review: new
mac-bold = Pogrubienie
# review: new
mac-italic = Kursywa
# review: new
mac-underline = Podkreślenie
# review: new
mac-bcc = UDW
# review: new
mac-command-click-to-open = ⌘-kliknięcie otwiera
# review: new
mac-saving-to-drafts = Zapisywanie w folderze Wersje robocze…
# review: new
mac-dont-save = Nie zachowuj

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } plik
        [few] { $count } pliki
        [many] { $count } plików
       *[other] { $count } plików
    }

## Accounts

# review: new
mac-next = Dalej
# review: new
mac-name-placeholder = Anna Kowalska
# review: new
mac-more-sign-in-options = Więcej opcji logowania…
# review: new
mac-add-sign-in-app = Dodaj aplikację logowania…
# review: new
mac-looking-up = Wyszukiwanie ustawień dla { $domain }…
# review: new
mac-add-button = Dodaj…
# review: new
mac-properties-button = Właściwości…
# review: new
mac-signature-button = Podpis…
# review: new
mac-security-button = Zabezpieczenia…
# review: new
mac-sign-in-apps-button = Aplikacje logowania…

## AI agents

# review: new
mac-forget-program = Usunąć ten program i historię działań jego agentów?
# review: new
mac-forget-program-detail = Uprawnienia programu zostaną usunięte. Przy następnym połączeniu Inbox Classic ponownie poprosi o zgodę.

## Sign-in apps

# review: new
mac-checking-issuer = Sprawdzanie { $issuer }…
# review: new
mac-edit-button = Edytuj…
# review: new
mac-use-for-new-accounts = Używaj { $name } dla nowych kont
# review: new
mac-built-in = { $name } (wbudowana)

## Other windows

# review: new
mac-new-folder-button = Nowy folder…
# review: new
mac-edit-link = Edytuj link…
