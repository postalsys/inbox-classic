# Polski. Słowa okien aplikacji dla Windows (app/src), identyfikatory win-. Wersja robocza.

## The main window

win-still-running-detail = Inbox Classic nadal sprawdza w tle, czy są nowe wiadomości. Kliknij ikonę, aby otworzyć program. Aby go zamknąć, kliknij ikonę prawym przyciskiem myszy i wybierz „Zakończ”.
win-default-app-not-installed = Ta kopia Inbox Classic nie została zainstalowana, więc system Windows nie wyświetla jej jako programu pocztowego. Zainstaluj ją, aby móc ją wybrać.
win-default-app-settings = System Windows otworzy ustawienia Aplikacje domyślne. Wybierz Inbox Classic, aby otwierać linki MAILTO.
win-no-unread = Brak nieprzeczytanych wiadomości
win-unread-messages = { $count ->
    [one] 1 nieprzeczytana wiadomość
    [few] { $count } nieprzeczytane wiadomości
    [many] { $count } nieprzeczytanych wiadomości
   *[other] { $count } nieprzeczytanych wiadomości
}
win-print-failed = Nie udało się wydrukować wiadomości.
win-print-title-of = Drukuj: { $subject }
win-no-bodies = Nie można wyświetlić treści wiadomości.
win-webview-failed = Nie udało się uruchomić składnika WebView2.
win-webview-missing = Środowisko uruchomieniowe WebView2 jest niedostępne.
win-list-loading = Wczytywanie...

## Buttons and words used in many windows

win-delete-button = &Usuń
win-find-label = &Znajdź:
win-save-as-button = Zapisz &jako...
win-too-many-files = Za dużo plików naraz: wybierz mniej.

## The Outbox


## The compose window

win-editor-failed = Nie można pisać wiadomości.
win-ctrl-click-to-open = ({ $ctrl }+kliknięcie, aby otworzyć)
win-format-bold = Pogrubienie ({ $ctrl }+B)
win-format-italic = Kursywa ({ $ctrl }+I)
win-format-underline = Podkreślenie ({ $ctrl }+U)
win-format-link = Hiperłącze ({ $ctrl }+K)
win-show-cc = &DW
win-show-bcc = &UDW
win-signature-title = Tekst podpisu: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Brak wyników dla „{ $words }” we wszystkich folderach
    [one] { $count } wynik dla „{ $words }” we wszystkich folderach
    [few] { $count } wyniki dla „{ $words }” we wszystkich folderach
    [many] { $count } wyników dla „{ $words }” we wszystkich folderach
   *[other] { $count } wyników dla „{ $words }” we wszystkich folderach
}
win-search-found-in = { $count ->
    [0] Brak wyników dla „{ $words }” (zakres: „{ $folder }”)
    [one] { $count } wynik dla „{ $words }” (zakres: „{ $folder }”)
    [few] { $count } wyniki dla „{ $words }” (zakres: „{ $folder }”)
    [many] { $count } wyników dla „{ $words }” (zakres: „{ $folder }”)
   *[other] { $count } wyników dla „{ $words }” (zakres: „{ $folder }”)
}
win-search-indexing = { $count ->
    [one] trwa indeksowanie tekstu { $count } wiadomości
    [few] trwa indeksowanie tekstu { $count } wiadomości
    [many] trwa indeksowanie tekstu { $count } wiadomości
   *[other] trwa indeksowanie tekstu { $count } wiadomości
}
win-no-match-indexing = { $count ->
    [one] Treść { $count } wiadomości jest jeszcze indeksowana. Wkrótce mogą pojawić się kolejne wyniki.
    [few] Treść { $count } wiadomości jest jeszcze indeksowana. Wkrótce mogą pojawić się kolejne wyniki.
    [many] Treść { $count } wiadomości jest jeszcze indeksowana. Wkrótce mogą pojawić się kolejne wyniki.
   *[other] Treść { $count } wiadomości jest jeszcze indeksowana. Wkrótce mogą pojawić się kolejne wyniki.
}
win-files = { $count ->
    [one] { $count } plik
    [few] { $count } pliki
    [many] { $count } plików
   *[other] { $count } plików
}
win-click-to-retry = Kliknij tutaj, aby spróbować ponownie.
win-save-attachments = &Zapisz załączniki...
win-files-not-saved = Nie udało się zapisać plików: { $failed } z { $count }.
win-new-folder-in-highlighted = Nowy folder zostanie utworzony wewnątrz zaznaczonego folderu.
win-delete-folder-ask = Usunąć folder „{ $folder }” wraz ze wszystkimi wiadomościami i podfolderami? Zostanie usunięty także z serwera.
win-rename = &Zmień nazwę...
win-messages-not-saved = Nie udało się zapisać wiadomości.
win-messages-not-forwarded = Nie udało się przesłać wiadomości dalej.

## Accounts

win-sign-in-google = Zaloguj się przez Google
win-sign-in-microsoft = Zaloguj się przez Microsoft
win-next = &Dalej >
win-your-account = Twoje konto
win-browser-sign-in = (logowanie w przeglądarce)
win-add = &Dodaj...
win-properties-button = &Właściwości...
win-signature-button = Tekst &podpisu...
win-sign-in-apps-button = &Aplikacje logowania...

## AI agents

win-dont-allow = &Nie zezwalaj
win-col-address = Adres
win-never-written-to = Nigdy nie wysłano wiadomości
win-book-find-label = Wpisz nazwę lub adres e-mail:
win-send = &Wyślij
win-dont-send = &Nie wysyłaj
win-unsubscribe = &Wypisz się
win-dont-unsubscribe = &Nie wypisuj
win-forget-program-ask = Usunąć ten program, jego uprawnienia i historię działań jego agentów? Przy następnym połączeniu Inbox Classic ponownie poprosi o zgodę.
win-clear-log-ask = Wyczyścić historię działań agentów? Nie cofnie to zmian wprowadzonych przez agentów.
win-agent-programs = Programy, &których agenci poprosili o dostęp do Twojej poczty:
win-change = &Zmień...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Cofnij &od...
win-take-back = &Cofnij
win-what-agents-did = &Działania agentów:
win-agent-reads = Odczytane dane (od { $from } do { $to }):
win-agent-reads-hint = Wybierz powyżej wpis dotyczący odczytu, aby zobaczyć odczytane dane.
win-how-to-connect = Jak połączyć agenta

## Sign-in apps

win-built-in = (wbudowana)
win-edit = &Edytuj...

## Options

win-folders-hide = Ukryj listę folderów
win-folders-pin = Przypnij listę folderów obok wiadomości
win-folders-show = Pokaż foldery

## The installer

# the installer's own words (installer/inbox-classic.nsi); { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Uruchom Inbox Classic
win-installer-welcome-new =
    Zostanie zainstalowany Inbox Classic { $version }, program pocztowy.

    Nie są potrzebne uprawnienia administratora: program instaluje się tylko dla Twojego konta.
win-installer-welcome-same =
    Inbox Classic { $version } jest już zainstalowany. Zostanie zainstalowany ponownie.

    Twoje konta i poczta zostaną zachowane.
win-installer-welcome-update =
    Inbox Classic { $installed } zostanie zaktualizowany do wersji { $version }.

    Jeśli jest uruchomiony, najpierw zostanie zamknięty. Twoje konta i poczta zostaną zachowane.
win-installer-older-ask = Zainstalowany jest Inbox Classic { $installed }, nowszy niż { $version }. Zainstalować mimo to starszą wersję?
win-installer-still-running = Inbox Classic nadal działa. Zamknij go i spróbuj ponownie.
win-installer-remove-mail-ask = Usunąć także konta i pocztę, które Inbox Classic przechowuje na tym komputerze? Poczta na serwerach pozostanie.
