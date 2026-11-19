# Polski. Słowa okien aplikacji dla Linuksa (linux/src), identyfikatory gtk-. Znak _ oznacza literę skrótu przycisku.
# Słowa GNOME tam, gdzie GNOME je ma (Preferencje, Zakończ).

## The main window

gtk-search-looks-in = Zakres wyszukiwania: „{ $place }”. Przeszukiwane są tematy, dane nadawców i odbiorców, nazwy załączników oraz treść wiadomości. Sprawdź pisownię lub wpisz mniej słów.
gtk-search-still-indexing = { $count ->
    [one] Tekst 1 wiadomości jest jeszcze indeksowany. Wkrótce może pojawić się więcej wyników.
    [few] Tekst { $count } wiadomości jest jeszcze indeksowany. Wkrótce może pojawić się więcej wyników.
    [many] Tekst { $count } wiadomości jest jeszcze indeksowany. Wkrótce może pojawić się więcej wyników.
   *[other] Tekst { $count } wiadomości jest jeszcze indeksowany. Wkrótce może pojawić się więcej wyników.
}
gtk-search-results-everywhere = { $count ->
    [0] Brak wyników
    [one] 1 wynik
    [few] { $count } wyniki
    [many] { $count } wyników
   *[other] { $count } wyników
} dla „{ $words }” we wszystkich folderach
gtk-search-results-in = { $count ->
    [0] Brak wyników
    [one] 1 wynik
    [few] { $count } wyniki
    [many] { $count } wyników
   *[other] { $count } wyników
} dla „{ $words }” (zakres: „{ $place }”)
gtk-search-indexing = { $count ->
    [one] trwa indeksowanie tekstu 1 wiadomości
    [few] trwa indeksowanie tekstu { $count } wiadomości
    [many] trwa indeksowanie tekstu { $count } wiadomości
   *[other] trwa indeksowanie tekstu { $count } wiadomości
}
gtk-list-loading = Wczytywanie...
gtk-menu-rename = Zmień nazwę...
gtk-import-one-question = Zaimportować wiadomość z pliku „{ $file }” do folderu „{ $folder }”?
gtk-files-not-saved = Nie udało się zapisać plików: { $failed } z { $total }.
gtk-unsubscribe-one-click =
    Wypisać się z tej listy mailingowej?

    Inbox Classic wyśle prośbę o wypisanie do serwera { $target }. Nie otworzy się żadna strona i nie zostanie wysłany żaden e-mail.
gtk-unsubscribe-mail =
    Wypisać się z tej listy mailingowej?

    Aby się wypisać, wyślij wiadomość e-mail na adres { $target }. Inbox Classic przygotuje jej treść. Wyślij ją, aby potwierdzić wypisanie.
gtk-unsubscribe-web =
    Wypisać się z tej listy mailingowej?

    Strona wypisywania z listy mailingowej otworzy się w przeglądarce ({ $target }).
gtk-unsubscribe-failed = Nie udało się wypisać: { $problem }
gtk-toolbar-create-mail-menu = Utwórz wiadomość z wybranego konta
gtk-toolbar-send-recv-menu = Wyślij i odbierz pocztę na wybranym koncie
gtk-main-menu = Menu główne
gtk-folder-list = Lista folderów
gtk-quit = Zakończ

## The Move and Copy window

gtk-new-folder-at-top-of = Nowy folder zostanie utworzony na najwyższym poziomie konta „{ $account }”.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Brak nieprzeczytanych wiadomości
    [one] 1 nieprzeczytana wiadomość
    [few] { $count } nieprzeczytane wiadomości
    [many] { $count } nieprzeczytanych wiadomości
   *[other] { $count } nieprzeczytanych wiadomości
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Żadne wiadomości nie czekają na wysłanie.
gtk-outbox-row = Do: { $to }  ·  W kolejce od { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic nadal sprawdza w tle, czy są nowe wiadomości. Użyj jego ikony na górnym pasku, aby otworzyć lub zamknąć program.
gtk-sign-in-again-ask =
    Logowanie do konta „{ $account }” zostało odrzucone lub sesja wygasła.

    Zalogować się ponownie w przeglądarce?
gtk-default-app-not-installed = Ta kopia Inbox Classic nie została zainstalowana, więc system nie wyświetla jej jako aplikacji pocztowej. Zainstaluj ją, aby móc ją wybrać.
gtk-default-app-now = Inbox Classic jest teraz Twoją domyślną aplikacją pocztową: linki e-mail otwierają tutaj nową wiadomość.
gtk-default-app-failed = Nie udało się ustawić Inbox Classic jako domyślnej aplikacji pocztowej.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Data:
gtk-reader-files = Załączniki wiadomości
gtk-files = { $count ->
    [one] { $count } plik
    [few] { $count } pliki
    [many] { $count } plików
   *[other] { $count } plików
}
gtk-pictures-blocked = Niektóre obrazy zostały zablokowane, aby utrudnić nadawcy identyfikację Twojego komputera.
gtk-download-pictures = Pobierz obrazy
gtk-save-attachments-menu = Zapisz załączniki...

## The compose window

gtk-format-bold = Pogrubienie (Ctrl+B)
gtk-format-italic = Kursywa (Ctrl+I)
gtk-format-underline = Podkreślenie (Ctrl+U)
gtk-format-hyperlink = Hiperłącze (Ctrl+K)
gtk-font = Czcionka
gtk-show-cc = _DW
gtk-show-bcc = _UDW
gtk-save-tip = Zapisz (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+kliknięcie, aby otworzyć)

## Accounts

gtk-plain-warning =
    Bez szyfrowania każdy, kto przechwyci ruch w Twojej sieci, może odczytać Twoje hasło i wiadomości. Używaj tego połączenia tylko z serwerem na własnym komputerze lub w sieci lokalnej.

    Kontynuować?
gtk-account-name-title = Nazwa konta
gtk-display-name-title = Nazwa wyświetlana
gtk-turned-off-why = Opcja „{ $button }” jest wyłączona na tym komputerze. { $reason }
gtk-turned-off-why-long =
    Opcja „{ $button }” jest wyłączona na tym komputerze.

    { $reason }
gtk-next = Dalej >
gtk-provider-sign-in = Zaloguj się na konto { $address } na stronie dostawcy ({ $provider }). Inbox Classic nie otrzyma Twojego hasła. Jeśli konto pozwala używać haseł aplikacji w programach pocztowych, możesz też użyć hasła aplikacji utworzonego w ustawieniach zabezpieczeń konta. Outlook.com i Microsoft 365 obsługują wyłącznie logowanie przez przeglądarkę.
gtk-provider-sign-in-apps = Zaloguj się na konto { $address } na stronie dostawcy ({ $provider }) za pomocą jednej ze swoich aplikacji logowania (Więcej opcji logowania). Jeśli konto pozwala używać haseł aplikacji w programach pocztowych, możesz też użyć hasła aplikacji utworzonego w ustawieniach zabezpieczeń konta. Outlook.com i Microsoft 365 obsługują wyłącznie logowanie przez przeglądarkę.
gtk-accounts-add = Dodaj...
gtk-accounts-properties = Właściwości...
gtk-accounts-signature = Tekst podpisu...
gtk-accounts-sign-in-apps = Aplikacje logowania...

## Sign-in apps

gtk-app-server = Serwer { $kind }
gtk-app-port = Port { $kind }
gtk-app-security = Zabezpieczenia { $kind }
gtk-issuer-found =
    Strona logowania: { $page }
    Punkt końcowy tokenów: { $endpoint }
gtk-client-id = Identyfikator klienta
gtk-client-secret = Klucz tajny klienta
gtk-scopes = Zakresy uprawnień (scopes)
gtk-redirect-uri = URI przekierowania
gtk-issuer-usable =
    Ten wystawca może być używany do logowania.

    { $found }
gtk-app-built-in = Aplikacja „{ $app }” jest wbudowana. Możesz jedynie zdecydować, czy ma być proponowana przy dodawaniu kont. { $reason }
gtk-built-in = { $app } (wbudowana)
gtk-offered-for-new = Proponowana przy dodawaniu kont
gtk-edit-button = Edytuj...
gtk-remove-app-ask = Usunąć aplikację logowania „{ $app }” i jej zapisany klucz tajny klienta?
gtk-sign-in-apps-intro = Aplikacje logowania umożliwiają logowanie się do kont przez przeglądarkę. Wyłączone aplikacje nie są proponowane przy dodawaniu kont. Konta, które już z nich korzystają, nadal działają.

## AI agents

gtk-agent-it-may = Dozwolone działania
gtk-agent-accounts = Dozwolone konta
gtk-never-used = Jeszcze nie użyto
gtk-last-used = Ostatnie użycie: { $date }
gtk-forget-program = Usunąć zapisane uprawnienia tego programu?
gtk-forget-program-detail = Uprawnienia programu i historia działań jego agentów zostaną usunięte. Przy następnym połączeniu Inbox Classic ponownie poprosi o zgodę.
gtk-no-agents-yet = Żaden agent nie poprosił jeszcze o dostęp do Twojej poczty.
gtk-nothing-yet = Na razie nic.

## Preferences

gtk-preferences = Preferencje
gtk-notify-subtitle = Tylko gdy Inbox Classic działa w tle

## The desktop entry and the page of the software stores

# the keywords: only the Polish ones, each ended by a semicolon (the English ones are added before them)
gtk-desktop-generic-name = Klient poczty
gtk-desktop-comment = Czytaj i pisz e-maile: szybki, prosty program pocztowy
gtk-desktop-keywords = poczta;mail;email;e-mail;imap;smtp;wiadomości;skrzynka odbiorcza;
gtk-metainfo-summary = Szybki, prosty program pocztowy
gtk-metainfo-description = Inbox Classic umożliwia czytanie i pisanie poczty w klasycznym układzie: foldery po lewej, lista wiadomości u góry i treść wybranej wiadomości poniżej. Obsługuje konta IMAP i SMTP oraz logowanie do Outlook.com i Microsoft 365 przez przeglądarkę.
gtk-metainfo-feature-sanitized = Wiadomości są wyświetlane po usunięciu skryptów i innych aktywnych elementów, a obrazy z internetu tylko za Twoją zgodą
gtk-metainfo-feature-search = Wyszukiwanie słów w temacie, danych nadawców i odbiorców, nazwach plików i treści, z użyciem operatorów Gmaila
gtk-metainfo-feature-replies = Cytowane wcześniejsze wiadomości są zwijane w odpowiedziach
gtk-metainfo-feature-offline = Pocztę można czytać bez internetu, dopóki zachowana jest kopia lokalna; dane logowania są zwykle przechowywane w systemowym pęku kluczy, jeśli jest dostępny
