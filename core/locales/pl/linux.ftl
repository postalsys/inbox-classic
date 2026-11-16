# Polski. Słowa okien aplikacji dla Linuksa (linux/src), identyfikatory gtk-. Znak _ oznacza literę skrótu przycisku.
# Słowa GNOME tam, gdzie GNOME je ma (Preferencje, Zakończ).

## The main window

# review: new
gtk-search-looks-in = Wyszukiwanie w folderze { $place } obejmuje tematy, nadawców, odbiorców, nazwy załączników i treść wiadomości. Sprawdź pisownię lub wpisz mniej słów.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Tekst 1 wiadomości jest jeszcze indeksowany. Wkrótce może pojawić się więcej wyników.
    [few] Tekst { $count } wiadomości jest jeszcze indeksowany. Wkrótce może pojawić się więcej wyników.
    [many] Tekst { $count } wiadomości jest jeszcze indeksowany. Wkrótce może pojawić się więcej wyników.
   *[other] Tekst { $count } wiadomości jest jeszcze indeksowany. Wkrótce może pojawić się więcej wyników.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Brak wyników
    [one] 1 wynik
    [few] { $count } wyniki
    [many] { $count } wyników
   *[other] { $count } wyników
} dla „{ $words }” we wszystkich folderach
# review: new
gtk-search-results-in = { $count ->
    [0] Brak wyników
    [one] 1 wynik
    [few] { $count } wyniki
    [many] { $count } wyników
   *[other] { $count } wyników
} dla „{ $words }” w folderze { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] trwa indeksowanie tekstu 1 wiadomości
    [few] trwa indeksowanie tekstu { $count } wiadomości
    [many] trwa indeksowanie tekstu { $count } wiadomości
   *[other] trwa indeksowanie tekstu { $count } wiadomości
}
# review: new
gtk-list-loading = Wczytywanie...
# review: new
gtk-menu-rename = Zmień nazwę...
# review: new
gtk-import-one-question = Zaimportować wiadomość { $file } do folderu { $folder }?
# review: new
gtk-files-not-saved = Nie udało się zapisać { $failed } z { $total } plików.
# review: new
gtk-unsubscribe-one-click =
    Wypisać się z tej listy mailingowej?

    Inbox Classic wyśle prośbę o wypisanie do { $target }. Nie otworzy się żadna strona i nie zostanie wysłany żaden e-mail.
# review: new
gtk-unsubscribe-mail =
    Wypisać się z tej listy mailingowej?

    Aby się wypisać, wyślij e-mail na adres { $target }. Inbox Classic go przygotuje. Wyślij wiadomość, aby potwierdzić.
# review: new
gtk-unsubscribe-web =
    Wypisać się z tej listy mailingowej?

    Strona wypisywania z listy mailingowej otworzy się w przeglądarce ({ $target }).
# review: new
gtk-unsubscribe-failed = Nie udało się wypisać: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Napisz z wybranego konta
# review: new
gtk-toolbar-send-recv-menu = Wyślij i odbierz pocztę wybranego konta
# review: new
gtk-main-menu = Menu główne
# review: new
gtk-folder-list = Lista folderów
# review: new
gtk-quit = Zakończ

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Nowy folder trafi na najwyższy poziom konta { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Brak nieprzeczytanych wiadomości
    [one] 1 nieprzeczytana wiadomość
    [few] { $count } nieprzeczytane wiadomości
    [many] { $count } nieprzeczytanych wiadomości
   *[other] { $count } nieprzeczytanych wiadomości
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Żadne wiadomości nie czekają na wysłanie.
# review: new
gtk-outbox-row = Do: { $to }  ·  W kolejce od { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic nadal sprawdza nową pocztę w tle. Użyj jego ikony na górnym pasku, aby otworzyć lub zakończyć aplikację.
# review: new
gtk-sign-in-again-ask =
    Logowanie do konta { $account } zostało odrzucone lub sesja wygasła.

    Zalogować się ponownie w przeglądarce?
# review: new
gtk-default-app-not-installed = Ta kopia Inbox Classic nie została zainstalowana, więc system nie wyświetla jej jako aplikacji pocztowej. Zainstaluj ją, aby móc ją wybrać.
# review: new
gtk-default-app-now = Inbox Classic jest teraz Twoją domyślną aplikacją pocztową: linki e-mail otwierają tutaj nową wiadomość.
# review: new
gtk-default-app-failed = Nie udało się ustawić Inbox Classic jako domyślnej aplikacji pocztowej.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Data:
# review: new
gtk-reader-files = Załączniki wiadomości
# review: new
gtk-files = { $count ->
    [one] { $count } plik
    [few] { $count } pliki
    [many] { $count } plików
   *[other] { $count } plików
}
# review: new
gtk-pictures-blocked = Niektóre obrazy zostały zablokowane, aby nadawca nie mógł zidentyfikować Twojego komputera.
# review: new
gtk-download-pictures = Pobierz obrazy
# review: new
gtk-save-attachments-menu = Zapisz załączniki...

## The compose window

# review: new
gtk-format-bold = Pogrubienie (Ctrl+B)
# review: new
gtk-format-italic = Kursywa (Ctrl+I)
# review: new
gtk-format-underline = Podkreślenie (Ctrl+U)
# review: new
gtk-format-hyperlink = Hiperłącze (Ctrl+K)
# review: new
gtk-font = Czcionka
# review: new
gtk-show-cc = _DW
# review: new
gtk-show-bcc = _UDW
# review: new
gtk-save-tip = Zapisz (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+kliknięcie otwiera)

## Accounts

# review: new
gtk-plain-warning =
    Bez szyfrowania każdy, kto przechwyci ruch w Twojej sieci, może odczytać Twoje hasło i wiadomości. Używaj tego połączenia tylko z serwerem na własnym komputerze lub w sieci lokalnej.

    Kontynuować?
# review: new
gtk-account-name-title = Nazwa konta
# review: new
gtk-display-name-title = Nazwa wyświetlana
# review: new
gtk-turned-off-why = Opcja „{ $button }” jest wyłączona na tym komputerze. { $reason }
# review: new
gtk-turned-off-why-long =
    Opcja „{ $button }” jest wyłączona na tym komputerze.

    { $reason }
# review: new
gtk-next = Dalej >
# review: new
gtk-provider-sign-in = Zaloguj się do { $address } na stronie: { $provider }. Twoje hasło nie jest udostępniane Inbox Classic. Możesz też użyć hasła aplikacji utworzonego w ustawieniach zabezpieczeń konta.
# review: new
gtk-provider-sign-in-apps = Zaloguj się do { $address } na stronie: { $provider }, za pomocą jednej ze swoich aplikacji logowania (Więcej opcji logowania). Możesz też użyć hasła aplikacji utworzonego w ustawieniach zabezpieczeń konta.
# review: new
gtk-accounts-add = Dodaj...
# review: new
gtk-accounts-properties = Właściwości...
# review: new
gtk-accounts-signature = Podpis...
# review: new
gtk-accounts-sign-in-apps = Aplikacje logowania...

## Sign-in apps

# review: new
gtk-app-server = Serwer { $kind }
# review: new
gtk-app-port = Port { $kind }
# review: new
gtk-app-security = Zabezpieczenia { $kind }
# review: new
gtk-issuer-found =
    Strona logowania: { $page }
    Punkt końcowy tokenu: { $endpoint }
# review: new
gtk-client-id = Identyfikator klienta
# review: new
gtk-client-secret = Klucz tajny klienta
# review: new
gtk-scopes = Zakresy (scopes)
# review: new
gtk-redirect-uri = URI przekierowania
# review: new
gtk-issuer-usable =
    Można użyć wystawcy.

    { $found }
# review: new
gtk-app-built-in = { $app } jest wbudowana. Możesz tylko zmienić, czy jest proponowana dla nowych kont. { $reason }
# review: new
gtk-built-in = { $app } (wbudowana)
# review: new
gtk-offered-for-new = Proponowana dla nowych kont
# review: new
gtk-edit-button = Edytuj...
# review: new
gtk-remove-app-ask = Usunąć aplikację logowania { $app } i jej zapisany klucz tajny klienta?
# review: new
gtk-sign-in-apps-intro = Aplikacje logowania pozwalają kontom logować się przez przeglądarkę. Wyłączona aplikacja nie jest proponowana dla nowych kont; konta, które już z niej korzystają, działają dalej.

## AI agents

# review: new
gtk-agent-it-may = Dozwolone działania
# review: new
gtk-agent-accounts = Dozwolone konta
# review: new
gtk-never-used = Nigdy nieużywany
# review: new
gtk-last-used = Ostatnio używany { $date }
# review: new
gtk-forget-program = Usunąć ten program?
# review: new
gtk-forget-program-detail = Uprawnienia programu i historia działań jego agentów zostaną usunięte. Przy następnym połączeniu Inbox Classic ponownie poprosi o zgodę.
# review: new
gtk-no-agents-yet = Żaden agent nie poprosił jeszcze o dostęp do Twojej poczty.
# review: new
gtk-nothing-yet = Na razie nic.

## Preferences

# review: new
gtk-preferences = Preferencje
# review: new
gtk-language-subtitle = Język aplikacji i pomocy
# review: new
gtk-notify-subtitle = Powiadomienie, gdy nadejdą nowe wiadomości, a okno jest w tle

## The desktop entry and the page of the software stores

# the keywords: only the Polish ones, each ended by a semicolon (the English ones are added before them)
# review: new
gtk-desktop-generic-name = Klient poczty
# review: new
gtk-desktop-comment = Czytaj i pisz e-maile: szybki, prosty program pocztowy
# review: new
gtk-desktop-keywords = poczta;e-mail;wiadomości;skrzynka;skrzynka odbiorcza;
# review: new
gtk-metainfo-summary = Szybki, prosty program pocztowy
# review: new
gtk-metainfo-description = Inbox Classic czyta i pisze pocztę e-mail z folderami po lewej, wiadomościami u góry i treścią wiadomości poniżej, tak jak dawniej programy pocztowe. Działa z każdym kontem IMAP i SMTP, a do Outlook.com i Microsoft 365 loguje się przez przeglądarkę.
# review: new
gtk-metainfo-feature-sanitized = Każda wiadomość jest wyświetlana oczyszczona, bez skryptów, a obrazy z internetu tylko wtedy, gdy na to pozwolisz
# review: new
gtk-metainfo-feature-search = Wyszukiwanie słów w temacie, nadawcach i odbiorcach, nazwach plików i treści, z operatorami Gmaila
# review: new
gtk-metainfo-feature-replies = Odpowiedzi zwijają cytowane wcześniejsze wiadomości
# review: new
gtk-metainfo-feature-offline = Poczta jest dostępna offline; hasła są przechowywane w Twoim pęku kluczy
