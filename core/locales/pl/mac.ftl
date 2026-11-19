# Polski. Słowa okien aplikacji dla Maca (mac/Sources), identyfikatory mac-. Zwyczaje Maca: wielokropek (…) po
# poleceniu, które o coś pyta, cudzysłowy „ ” i apostrofy typograficzne; w języku polskim wielka litera tylko na
# początku.

## The app and its menus

mac-quit = Zakończ Inbox Classic
mac-settings = Ustawienia…
mac-services = Usługi
mac-hide = Ukryj Inbox Classic
mac-hide-others = Ukryj pozostałe
mac-show-all = Pokaż wszystkie
mac-check-updates = Sprawdź uaktualnienia…
mac-close-window = Zamknij okno
mac-redo = Powtórz
mac-cut = Wytnij
mac-paste = Wklej
mac-menu-window = Okno
mac-minimize = Minimalizuj
mac-zoom = Zmień rozmiar
mac-no-updates = Ta wersja Inbox Classic nie obsługuje automatycznych uaktualnień. Pobierz najnowszą wersję z inboxclassic.com.

## Settings

mac-settings-title = Ustawienia
mac-check-updates-automatically = Automatycznie sprawdzaj uaktualnienia
mac-settings-updates = Uaktualnienia

## Dialogs

mac-choose = Wybierz

## The main window

mac-still-running-detail = Inbox Classic nadal sprawdza w tle, czy są nowe wiadomości. Kliknij jego ikonę w Docku, aby otworzyć program.
mac-outbox-waiting =
    { $count ->
        [one] { $count } wiadomość w Skrzynce nadawczej
        [few] { $count } wiadomości w Skrzynce nadawczej
        [many] { $count } wiadomości w Skrzynce nadawczej
       *[other] { $count } wiadomości w Skrzynce nadawczej
    }
mac-sending = Wysyłanie: { $subject }…
mac-checking = Sprawdzanie poczty na koncie „{ $account }”…
mac-account-said = { $account }: { $message }
mac-not-bundle = Ta kopia Inbox Classic nie jest pakietem aplikacji, więc nie może być domyślną aplikacją pocztową.
mac-not-made-default = Nie ustawiono Inbox Classic jako domyślnej aplikacji pocztowej: { $reason }
mac-tool-search = Szukaj

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Treść { $count } wiadomości jest jeszcze indeksowana. Wkrótce mogą pojawić się kolejne wyniki.
        [few] Treść { $count } wiadomości jest jeszcze indeksowana. Wkrótce mogą pojawić się kolejne wyniki.
        [many] Treść { $count } wiadomości jest jeszcze indeksowana. Wkrótce mogą pojawić się kolejne wyniki.
       *[other] Treść { $count } wiadomości jest jeszcze indeksowana. Wkrótce mogą pojawić się kolejne wyniki.
    }
mac-results-everywhere =
    { $count ->
        [0] Brak wyników dla „{ $words }” we wszystkich folderach
        [one] { $count } wynik dla „{ $words }” we wszystkich folderach
        [few] { $count } wyniki dla „{ $words }” we wszystkich folderach
        [many] { $count } wyników dla „{ $words }” we wszystkich folderach
       *[other] { $count } wyników dla „{ $words }” we wszystkich folderach
    }
mac-results-in =
    { $count ->
        [0] Brak wyników dla „{ $words }” (zakres: „{ $folder }”)
        [one] { $count } wynik dla „{ $words }” (zakres: „{ $folder }”)
        [few] { $count } wyniki dla „{ $words }” (zakres: „{ $folder }”)
        [many] { $count } wyników dla „{ $words }” (zakres: „{ $folder }”)
       *[other] { $count } wyników dla „{ $words }” (zakres: „{ $folder }”)
    }
mac-still-indexing =
    { $count ->
        [one] trwa indeksowanie tekstu { $count } wiadomości
        [few] trwa indeksowanie tekstu { $count } wiadomości
        [many] trwa indeksowanie tekstu { $count } wiadomości
       *[other] trwa indeksowanie tekstu { $count } wiadomości
    }
mac-folder-unread = { $folder }, nieprzeczytane: { $count }
mac-import-messages = Importuj wiadomości
mac-save-messages = Zapisz wiadomości
mac-save-attachments-menu = Zapisz załączniki…
mac-files-not-saved =
    { $count ->
       *[other] Nie udało się zapisać plików: { $failed } z { $count }.
    }
mac-no-calendar-app = Na tym Macu nie ma aplikacji kalendarza obsługującej zaproszenia (pliki .ics).
mac-file-not-saved = Nie udało się zapisać pliku.
mac-unsubscribing = Wysyłanie prośby o wypisanie: { $target }…
mac-loading-list = Wczytywanie…

## The compose window

mac-bold = Pogrubienie
mac-italic = Kursywa
mac-underline = Podkreślenie
mac-bcc = UDW
mac-command-click-to-open = ⌘-kliknięcie, aby otworzyć
mac-saving-to-drafts = Zapisywanie w folderze Wersje robocze…
mac-dont-save = Nie zachowuj

## The reading pane

mac-files =
    { $count ->
        [one] { $count } plik
        [few] { $count } pliki
        [many] { $count } plików
       *[other] { $count } plików
    }

## Accounts

mac-next = Dalej
mac-name-placeholder = Anna Kowalska
mac-more-sign-in-options = Więcej opcji logowania…
mac-add-sign-in-app = Dodaj aplikację logowania…
mac-looking-up = Wyszukiwanie ustawień dla { $domain }…
mac-add-button = Dodaj…
mac-properties-button = Właściwości…
mac-signature-button = Tekst podpisu…
mac-security-button = Zabezpieczenia…
mac-sign-in-apps-button = Aplikacje logowania…

## AI agents

mac-forget-program = Usunąć ten program i historię działań jego agentów?
mac-forget-program-detail = Uprawnienia programu zostaną usunięte. Przy następnym połączeniu Inbox Classic ponownie poprosi o zgodę.

## Sign-in apps

mac-checking-issuer = Sprawdzanie { $issuer }…
mac-edit-button = Edytuj…
mac-use-for-new-accounts = Proponuj aplikację „{ $name }” przy dodawaniu kont
mac-built-in = { $name } (wbudowana)

## Other windows

mac-new-folder-button = Nowy folder…
mac-edit-link = Edytuj link…
