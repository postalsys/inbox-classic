# Polski. Słowa okien aplikacji dla Windows (app/src), identyfikatory win-. Wersja robocza.

## The main window

# review: new
win-still-running-detail = Inbox Classic nadal sprawdza nową pocztę w tle. Kliknij ikonę, aby go otworzyć. Aby zakończyć, kliknij ikonę prawym przyciskiem myszy i użyj jej menu.
# review: new
win-default-app-not-installed = Ta kopia Inbox Classic nie została zainstalowana, więc system Windows nie wyświetla jej jako programu pocztowego. Zainstaluj ją, aby móc ją wybrać.
# review: new
win-default-app-settings = System Windows otworzy ustawienia Aplikacje domyślne. Wybierz Inbox Classic, aby otwierać linki MAILTO.
# review: new
win-no-unread = Brak nieprzeczytanych wiadomości
# review: new
win-unread-messages = { $count ->
    [one] 1 nieprzeczytana wiadomość
    [few] { $count } nieprzeczytane wiadomości
    [many] { $count } nieprzeczytanych wiadomości
   *[other] { $count } nieprzeczytanych wiadomości
}
# review: new
win-print-failed = Nie udało się wydrukować wiadomości.
# review: new
win-print-title-of = Drukuj: { $subject }
# review: new
win-no-bodies = Nie można wyświetlić treści wiadomości.
# review: new
win-webview-failed = Nie udało się utworzyć WebView2.
# review: new
win-webview-missing = Środowisko uruchomieniowe WebView2 jest niedostępne.
win-list-loading = Wczytywanie...

## Buttons and words used in many windows

# review: new
win-delete-button = &Usuń
# review: new
win-find-label = &Znajdź:
# review: new
win-save-as-button = Zapisz &jako...
# review: new
win-too-many-files = Za dużo plików naraz: wybierz mniej.

## The Outbox


## The compose window

# review: new
win-editor-failed = Nie można pisać wiadomości.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+kliknięcie otwiera)
# review: new
win-format-bold = Pogrubienie ({ $ctrl }+B)
# review: new
win-format-italic = Kursywa ({ $ctrl }+I)
# review: new
win-format-underline = Podkreślenie ({ $ctrl }+U)
# review: new
win-format-link = Hiperłącze ({ $ctrl }+K)
# review: new
win-show-cc = &DW
# review: new
win-show-bcc = &UDW
# review: new
win-signature-title = Podpis: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Brak wyników dla „{ $words }” we wszystkich folderach
    [one] { $count } wynik dla „{ $words }” we wszystkich folderach
    [few] { $count } wyniki dla „{ $words }” we wszystkich folderach
    [many] { $count } wyników dla „{ $words }” we wszystkich folderach
   *[other] { $count } wyników dla „{ $words }” we wszystkich folderach
}
# review: new
win-search-found-in = { $count ->
    [0] Brak wyników dla „{ $words }” w folderze { $folder }
    [one] { $count } wynik dla „{ $words }” w folderze { $folder }
    [few] { $count } wyniki dla „{ $words }” w folderze { $folder }
    [many] { $count } wyników dla „{ $words }” w folderze { $folder }
   *[other] { $count } wyników dla „{ $words }” w folderze { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] trwa indeksowanie tekstu { $count } wiadomości
    [few] trwa indeksowanie tekstu { $count } wiadomości
    [many] trwa indeksowanie tekstu { $count } wiadomości
   *[other] trwa indeksowanie tekstu { $count } wiadomości
}
# review: new
win-no-match-indexing = { $count ->
    [one] Tekst { $count } wiadomości jest jeszcze indeksowany, więc wkrótce może zostać znalezionych więcej.
    [few] Tekst { $count } wiadomości jest jeszcze indeksowany, więc wkrótce może zostać znalezionych więcej.
    [many] Tekst { $count } wiadomości jest jeszcze indeksowany, więc wkrótce może zostać znalezionych więcej.
   *[other] Tekst { $count } wiadomości jest jeszcze indeksowany, więc wkrótce może zostać znalezionych więcej.
}
# review: new
win-files = { $count ->
    [one] { $count } plik
    [few] { $count } pliki
    [many] { $count } plików
   *[other] { $count } plików
}
# review: new
win-click-to-retry = Kliknij tutaj, aby spróbować ponownie.
# review: new
win-save-attachments = &Zapisz załączniki...
# review: new
win-files-not-saved = Nie udało się zapisać { $failed } z { $count } plików.
# review: new
win-new-folder-in-highlighted = Nowy folder zostanie utworzony wewnątrz zaznaczonego folderu.
# review: new
win-delete-folder-ask = Usunąć folder „{ $folder }” razem z jego wiadomościami i folderami, które zawiera? Zostanie usunięty także na serwerze.
# review: new
win-rename = Zmień &nazwę...
# review: new
win-messages-not-saved = Nie udało się zapisać wiadomości.
# review: new
win-messages-not-forwarded = Nie udało się przesłać wiadomości dalej.

## Accounts

# review: new
win-sign-in-google = Zaloguj się przez Google
# review: new
win-sign-in-microsoft = Zaloguj się przez Microsoft
# review: new
win-next = &Dalej >
# review: new
win-your-account = Twoje konto
# review: new
win-browser-sign-in = (logowanie w przeglądarce)
# review: new
win-add = &Dodaj...
# review: new
win-properties-button = &Właściwości...
# review: new
win-signature-button = &Podpis...
# review: new
win-sign-in-apps-button = &Aplikacje logowania...

## AI agents

# review: new
win-dont-allow = &Nie zezwalaj
# review: new
win-col-address = Adres
# review: new
win-never-written-to = Nigdy nie wysłano wiadomości
# review: new
win-book-find-label = Wpisz nazwę lub adres e-mail:
# review: new
win-send = &Wyślij
# review: new
win-dont-send = &Nie wysyłaj
win-unsubscribe = &Wypisz się
win-dont-unsubscribe = &Nie wypisuj
# review: new
win-forget-program-ask = Usunąć ten program, jego uprawnienia i historię działań jego agentów? Przy następnym połączeniu Inbox Classic ponownie poprosi o zgodę.
# review: new
win-clear-log-ask = Wyczyścić historię działań agentów? Nie cofnie to zmian wprowadzonych przez agentów.
# review: new
win-agent-programs = &Programy, których agenci poprosili o dostęp do Twojej poczty:
# review: new
win-change = &Zmień...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
win-undo-since = Cofnij &od...
# review: new
win-take-back = &Cofnij
# review: new
win-what-agents-did = &Działania agentów:
# review: new
win-agent-reads = Co przeczytano od { $from } do { $to }:
# review: new
win-agent-reads-hint = Zaznacz powyżej wiersz z odczytami, aby zobaczyć, co przeczytano.
# review: new
win-how-to-connect = Jak połączyć agenta

## Sign-in apps

# review: new
win-built-in = (wbudowana)
# review: new
win-edit = &Edytuj...

## Options

# review: new
win-folders-hide = Ukryj listę folderów
# review: new
win-folders-pin = Trzymaj listę folderów obok wiadomości
# review: new
win-folders-show = Pokaż foldery

## The installer

# the installer's own words (installer/inbox-classic.nsi); { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Uruchom Inbox Classic
# review: new
win-installer-welcome-new =
    Zostanie zainstalowany Inbox Classic { $version }, program pocztowy.

    Nie są potrzebne uprawnienia administratora: program instaluje się tylko dla Twojego konta.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } jest już zainstalowany. Zostanie zainstalowany ponownie.

    Twoje konta i poczta zostaną zachowane.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } zostanie zaktualizowany do wersji { $version }.

    Jeśli jest uruchomiony, najpierw zostanie zamknięty. Twoje konta i poczta zostaną zachowane.
# review: new
win-installer-older-ask = Zainstalowany jest Inbox Classic { $installed }, nowszy niż { $version }. Zainstalować mimo to starszą wersję?
# review: new
win-installer-still-running = Inbox Classic nadal działa. Zamknij go i spróbuj ponownie.
# review: new
win-installer-remove-mail-ask = Usunąć także konta i pocztę, które Inbox Classic przechowuje na tym komputerze? Poczta na serwerach pozostanie.
