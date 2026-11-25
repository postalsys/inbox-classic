# Polski. Wersja robocza, czeka na przegląd przez native speakera (zob. core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] 1 wiadomość
    [few] { $count } wiadomości
    [many] { $count } wiadomości
   *[other] { $count } wiadomości
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
list-separator = { ", " }
size-bytes = { $count ->
    [one] 1 bajt
    [few] { $count } bajty
    [many] { $count } bajtów
   *[other] { $count } bajtów
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Wyłączone
send-delay-seconds = { $count ->
    [one] 1 sekunda
    [few] { $count } sekundy
    [many] { $count } sekund
   *[other] { $count } sekund
}
# the status bar: "12 wiadomości, nieprzeczytane: 3"
list-counts = { $messages }, nieprzeczytane: { $unread }
list-counts-selected = { $messages }, nieprzeczytane: { $unread }, zaznaczone: { $selected }
list-counts-found = Znalezione: { $found }, nieprzeczytane: { $unread }
list-counts-found-selected = Znalezione: { $found }, nieprzeczytane: { $unread }, zaznaczone: { $selected }
list-counts-none = Nie znaleziono wiadomości

## Special folders, as Outlook names them

folder-inbox = Skrzynka odbiorcza
folder-sent = Elementy wysłane
folder-deleted = Elementy usunięte
folder-drafts = Wersje robocze
folder-junk = Wiadomości-śmieci
folder-archive = Archiwum

## The reading pane

reader-no-message = Nie zaznaczono żadnej wiadomości.
reader-downloading = Pobieranie wiadomości…
reader-downloading-detail = Wiadomość pojawi się tutaj po zakończeniu pobierania.
reader-downloading-size = Rozmiar wiadomości: { $size }. Pojawi się tutaj po pobraniu.
reader-failed = Nie udało się pobrać wiadomości
reader-failed-network = Nie udało się połączyć z serwerem poczty lub połączenie zostało przerwane ({ $reason }).
reader-failed-sign-in = Serwer poczty nie zaakceptował logowania ({ $reason }). Sprawdź hasło lub zaloguj się ponownie w ustawieniach konta.
reader-failed-security = Nie udało się zabezpieczyć połączenia z serwerem poczty ({ $reason }).
reader-failed-other = Serwer poczty odpowiedział: { $reason }.
reader-retry-note = Program spróbuje ponownie po nawiązaniu połączenia z kontem.
reader-unreadable = Nie można wyświetlić tej wiadomości: { $error }
message-source-title = Źródło wiadomości: { $subject }
message-source-untitled = Źródło wiadomości

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Od
header-date = Data
header-to = Do
header-cc = DW
header-sent = Wysłano
header-subject = Temat
header-security = Zabezpieczenia
header-part = Część { $number }
quote-original = ----- Wiadomość oryginalna -----
fold-show-earlier = Pokaż wcześniejsze wiadomości

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Twoja wiadomość nie została dostarczona
bounce-delayed = Twoja wiadomość nie została jeszcze dostarczona
bounce-delayed-note = Twój serwer poczty wciąż próbuje ją dostarczyć. Nie musisz wysyłać jej ponownie.
bounce-show-message = Pokaż niedostarczoną wiadomość
bounce-show-delayed = Pokaż opóźnioną wiadomość
bounce-what-to-do = Co możesz zrobić:
bounce-delayed-do = Na razie nie musisz nic robić. Jeśli nadal nie będzie można dostarczyć wiadomości, otrzymasz kolejne powiadomienie.
bounce-delayed-row-do = Na razie nic. Twój serwer poczty wciąż próbuje ją dostarczyć, a jeśli mu się nie uda, otrzymasz kolejne powiadomienie.
bounce-details = Szczegóły
bounce-someone = Odbiorca
bounce-server = Serwer: { $server }
bounce-status = Stan: { $status }
bounce-reported-by = Zgłoszone przez: { $server }
bounce-retry-minutes = Serwer odbiorcy poprosił o odczekanie { $count ->
    [one] minuty
    [few] { $count } minut
    [many] { $count } minut
   *[other] { $count } minut
} przed kolejną próbą.
bounce-retry-hours = Serwer odbiorcy poprosił o odczekanie { $count ->
    [one] godziny
    [few] { $count } godzin
    [many] { $count } godzin
   *[other] { $count } godzin
} przed kolejną próbą.
bounce-blocklist = Czarna lista: { $lists }
bounce-user-unknown = Adres nie istnieje
bounce-user-unknown-why = Serwer odbiorcy nie ma skrzynki o tym adresie. Adres może zawierać literówkę albo odbiorca przestał go używać.
bounce-user-unknown-do = Sprawdź pisownię adresu albo zapytaj tę osobę, jakiego adresu teraz używa.
bounce-invalid-address = Adres jest nieprawidłowy
bounce-invalid-address-why = Adres ma nieprawidłowy format, więc nie można na niego wysłać poczty.
bounce-invalid-address-do = Sprawdź, czy w adresie nie ma literówek, zbędnych spacji lub brakujących znaków, zwłaszcza po znaku @.
bounce-mailbox-disabled = Skrzynka jest wyłączona
bounce-mailbox-disabled-why = Adres istnieje, ale jego skrzynka została wyłączona albo nie jest już używana.
bounce-mailbox-disabled-do = Skontaktuj się z tą osobą w inny sposób i zapytaj o adres, którego teraz używa.
bounce-mailbox-full = Skrzynka jest pełna
bounce-mailbox-full-why = W skrzynce odbiorcy nie ma miejsca na nową pocztę.
bounce-mailbox-full-do = Wyślij ją ponownie za kilka dni albo daj znać tej osobie w inny sposób.
bounce-spam-blocked = Odrzucona jako spam
bounce-spam-blocked-why = Serwer odbiorcy uznał wiadomość za spam.
bounce-spam-blocked-do = Wyślij ją ponownie bez tego, co wygląda na spam, na przykład wielu linków, skróconych linków czy dużego załącznika. Jeśli to się powtarza, zapytaj swojego dostawcę poczty.
bounce-virus-detected = Odrzucona z powodu wirusa
bounce-virus-detected-why = Serwer odbiorcy zgłosił wirusa lub inną szkodliwą zawartość w wiadomości albo w jej załącznikach.
bounce-virus-detected-do = Sprawdź załączniki programem antywirusowym. Niektóre serwery odrzucają wszystkie programy i archiwa, więc takie pliki udostępnij jako link.
bounce-ip-blocklisted = Twój serwer poczty jest na czarnej liście
bounce-ip-blocklisted-why = Serwer odbiorcy odrzuca pocztę z serwera, który wysłał Twoją wiadomość, bo adres tego serwera jest na czarnej liście.
bounce-ip-blocklisted-do = Problem nie leży w wiadomości. Prześlij to powiadomienie swojemu dostawcy poczty i poproś o usunięcie serwera z listy.
bounce-domain-blocklisted = Domena jest na czarnej liście
bounce-domain-blocklisted-why = Serwer odbiorcy odrzuca wiadomość, bo domena Twojego adresu albo domena z linków w wiadomości jest na czarnej liście.
bounce-domain-blocklisted-do = Jeśli wiadomość zawiera linki, spróbuj bez nich. W przeciwnym razie prześlij to powiadomienie osobie, która obsługuje pocztę Twojej domeny.
bounce-policy-blocked = Odrzucona przez reguły serwera odbiorcy
bounce-policy-blocked-why = Reguły serwera odbiorcy nie przepuszczają tej wiadomości, na przykład z powodu jej rozmiaru, załączników albo nadawcy.
bounce-policy-blocked-do = Komunikat serwera w sekcji Szczegóły często wyjaśnia przyczynę. Zapytaj odbiorcę, czy może przyjmować taką pocztę.
bounce-geo-blocked = Odrzucona ze względu na pochodzenie
bounce-geo-blocked-why = Serwer odbiorcy blokuje pocztę z kraju, w którym znajduje się Twój serwer poczty, lub z sieci, do której jest podłączony.
bounce-geo-blocked-do = Skontaktuj się z tą osobą w inny sposób albo zapytaj o to swojego dostawcę poczty.
bounce-relay-denied = Serwer nie przekazał jej dalej
bounce-relay-denied-why = Serwer odmówił przekazania wiadomości dalej, często dlatego, że wysłano ją bez logowania albo przez serwer, który nie obsługuje tego odbiorcy.
bounce-relay-denied-do = W ustawieniach konta sprawdź serwer poczty wychodzącej i wymagane dane logowania.
bounce-auth-failure = Nie udało się zweryfikować Twojego adresu nadawcy
bounce-auth-failure-why = Serwer odbiorcy nie mógł potwierdzić, że wiadomość naprawdę pochodzi z Twojej domeny (SPF, DKIM lub DMARC).
bounce-auth-failure-do = Prześlij to powiadomienie osobie, która obsługuje pocztę Twojej domeny: jej ustawienia trzeba poprawić. Do tego czasu może pomóc wysyłanie przez serwer Twojego dostawcy.
bounce-rate-limited = Za dużo poczty naraz
bounce-rate-limited-why = Serwer odbiorcy przyjmuje na razie mniej wiadomości z Twojego serwera poczty.
bounce-rate-limited-do = Odczekaj chwilę i wyślij ją ponownie. Pisząc do wielu osób, wysyłaj do mniejszej liczby naraz.
bounce-greylisting = Wstrzymana na chwilę
bounce-greylisting-why = Serwer odbiorcy prosi nieznanych nadawców o ponowną próbę nieco później. To częsty sposób ochrony przed spamem.
bounce-greylisting-do = Jeśli raport dotyczy opóźnienia, serwer może ponowić próbę wysłania. Jeśli zgłasza ostateczne niepowodzenie, spróbuj wysłać wiadomość ponownie później.
bounce-server-error = Serwer odbiorcy miał problem
bounce-server-error-why = Nie można było połączyć się z serwerem odbiorcy albo nie mógł on przyjąć wiadomości z powodu własnego problemu.
bounce-server-error-do = Wyślij ją ponownie później. Jeśli nadal się nie uda, sprawdź, czy w części adresu po znaku @ nie ma literówek.
bounce-unknown = Nie dostarczono
bounce-unknown-why = W powiadomieniu nie podano jednoznacznej przyczyny.
bounce-unknown-do = Komunikat serwera w sekcji Szczegóły może zawierać więcej informacji. Jeśli nie pomoże, prześlij to powiadomienie swojemu dostawcy poczty.

## Several messages selected

selection-title = { $count ->
    [one] Zaznaczono 1 wiadomość
    [few] Zaznaczono { $count } wiadomości
    [many] Zaznaczono { $count } wiadomości
   *[other] Zaznaczono { $count } wiadomości
}
selection-unread = Nieprzeczytane: { $count }
selection-flagged = Z flagą: { $count }
delete-for-good-one = Ta wiadomość zostanie trwale usunięta. Usunąć ją?
delete-for-good-all = Te wiadomości ({ $count }) zostaną trwale usunięte. Usunąć je?
delete-for-good-some = { $count ->
    [one] { $count } z { $total } wiadomości zostanie trwale usunięta. Usunąć wiadomości?
    [few] { $count } z { $total } wiadomości zostaną trwale usunięte. Usunąć wiadomości?
    [many] { $count } z { $total } wiadomości zostanie trwale usuniętych. Usunąć wiadomości?
   *[other] { $count } z { $total } wiadomości zostanie trwale usuniętych. Usunąć wiadomości?
}
done-read = { $count ->
   *[other] Oznaczono jako przeczytane: { $messages }
}
done-unread = { $count ->
   *[other] Oznaczono jako nieprzeczytane: { $messages }
}
done-flagged = { $count ->
   *[other] Oznaczono flagą: { $messages }
}
done-unflagged = Usunięto flagę: { $messages }
done-deleted-for-good = { $count ->
   *[other] Trwale usunięto: { $messages }
}
done-archived = { $count ->
   *[other] Zarchiwizowano: { $messages }
}
done-moved = { $count ->
   *[other] Przeniesiono { $messages } (cel: { $folder })
}
done-copied = { $count ->
   *[other] Skopiowano { $messages } (cel: { $folder })
}
done-moving = { $count ->
   *[other] Przenoszenie: { $messages } (cel: { $folder })...
}
done-copying = { $count ->
   *[other] Kopiowanie: { $messages } (cel: { $folder })...
}
done-moved-back = { $count ->
   *[other] Przeniesiono z powrotem { $messages } (cel: { $folder })
}
done-watched = { $count ->
    [one] Obserwujesz konwersację
    [few] Obserwujesz { $count } konwersacje
    [many] Obserwujesz { $count } konwersacji
   *[other] Obserwujesz { $count } konwersacji
}
done-unwatched = { $count ->
    [one] Przestano obserwować konwersację
    [few] Przestano obserwować { $count } konwersacje
    [many] Przestano obserwować { $count } konwersacji
   *[other] Przestano obserwować { $count } konwersacji
}
done-ignored = { $count ->
    [one] Ignorujesz konwersację
    [few] Ignorujesz { $count } konwersacje
    [many] Ignorujesz { $count } konwersacji
   *[other] Ignorujesz { $count } konwersacji
}
done-unignored = { $count ->
    [one] Przestano ignorować konwersację
    [few] Przestano ignorować { $count } konwersacje
    [many] Przestano ignorować { $count } konwersacji
   *[other] Przestano ignorować { $count } konwersacji
}
their-folders = odpowiednie foldery
undo-move = Cofnij przeniesienie
undo-delete = Cofnij usunięcie
undo-archive = Cofnij archiwizację
undo-junk = Cofnij oznaczenie jako śmieci
undo-not-junk = Cofnij usunięcie oznaczenia śmieci
undo-send = Cofnij wysłanie
nothing-to-undo = Nie ma nic do cofnięcia.
messages-gone = Tych wiadomości już nie ma.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Ten folder nie może zawierać wiadomości.
not-archived-here = Wiadomości w tym folderze nie można archiwizować.
not-emptied-here = Opróżnić można tylko foldery Elementy usunięte i Wiadomości-śmieci.
next-unread-question = W folderze { $folder } nie ma więcej nieprzeczytanych wiadomości.

    Przejść do folderu { $next }, następnego z nieprzeczytanymi wiadomościami?
no-unread-left = Nie ma już nieprzeczytanych wiadomości.
empty-question = { $count ->
    [one] Opróżnić folder „{ $folder }”?

        Znajdująca się w nim wiadomość zostanie trwale usunięta i nie będzie można jej przywrócić.
   *[other] Opróżnić folder „{ $folder }”?

        Trwale usunięte zostaną: { $messages }. Nie będzie można ich przywrócić.
}
no-junk-folder = To konto nie ma folderu Wiadomości-śmieci, do którego można przenieść wiadomości.
no-inbox-folder = To konto nie ma folderu Skrzynka odbiorcza, do którego można przenieść wiadomości.
# the status bar after a flag in a colour: "Oznaczono 2 wiadomości flagą niebieską"
done-flagged-color = Oznaczono { $messages } flagą { $color ->
    [red] czerwoną
    [orange] pomarańczową
    [yellow] żółtą
    [green] zieloną
    [blue] niebieską
    [purple] fioletową
   *[gray] szarą
}
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Czerwona
    [orange] Pomarańczowa
    [yellow] Żółta
    [green] Zielona
    [blue] Niebieska
    [purple] Fioletowa
   *[gray] Szara
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Przenieś wiadomość
    [few] Przenieś { $count } wiadomości
    [many] Przenieś { $count } wiadomości
   *[other] Przenieś { $count } wiadomości
}
move-window-title-copy = { $count ->
    [one] Kopiuj wiadomość
    [few] Kopiuj { $count } wiadomości
    [many] Kopiuj { $count } wiadomości
   *[other] Kopiuj { $count } wiadomości
}
move-window-prompt-move = { $count ->
    [one] Przenieś zaznaczoną wiadomość do:
    [few] Przenieś { $count } zaznaczone wiadomości do:
    [many] Przenieś { $count } zaznaczonych wiadomości do:
   *[other] Przenieś { $count } zaznaczonych wiadomości do:
}
move-window-prompt-copy = { $count ->
    [one] Kopiuj zaznaczoną wiadomość do:
    [few] Kopiuj { $count } zaznaczone wiadomości do:
    [many] Kopiuj { $count } zaznaczonych wiadomości do:
   *[other] Kopiuj { $count } zaznaczonych wiadomości do:
}
targets-recent = Ostatnio używane
target-current = { $folder } (bieżący)
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Przenoszenie: { $done } z { $messages } (cel: { $folder })...
transfer-copying = Kopiowanie: { $done } z { $messages } (cel: { $folder })...
transfer-another-account = inne konto
transfer-folder-gone = folder docelowy już nie istnieje
transfer-not-on-server = wiadomości nie ma już na serwerze
transfer-not-moved = { $count ->
   *[other] Nie udało się przenieść na inne konto ({ $messages }): { $reason }
}
transfer-not-copied = { $count ->
   *[other] Nie udało się skopiować na inne konto ({ $messages }): { $reason }
}
transfer-none-moved = Nie udało się przenieść żadnej wiadomości
transfer-none-copied = Nie udało się skopiować żadnej wiadomości

## Messages as files

export-not-in-time = nie udało się pobrać wiadomości na czas
export-not-saved = Nie udało się zapisać { $failed } z { $messages } ({ $problems })
export-not-attached = nie udało się załączyć wiadomości: { $error }
# the status bar after Save As with several: "Zapisano 3 wiadomości w folderze Pulpit"
saved-to = { $count ->
   *[other] Zapisano { $messages } w folderze { $folder }
}
download-progress = Pobieranie: { $done } z { $total }
download-done = Pobrano { $size }
downloading-messages = { $count ->
   *[other] Pobieranie: { $messages }...
}
# the status bar after files are dropped on a folder: "Umieszczono 3 wiadomości w folderze Archiwum"
import-put = { $count ->
   *[other] Zlecono import. Wiadomości: { $messages }. Folder docelowy: { $folder }
}
import-not-put = Tych plików nie umieszczono w folderze:

    { $problems }

## Problems the windows show

error-store = lokalna baza poczty: { $error }
error-not-found = nie znaleziono
error-closed = trwa zamykanie
error-other-account = przeglądarka zalogowała się na konto { $email }, a nie na to konto
failure-authentication = serwer nie zaakceptował logowania ({ $reason })
failure-network = nie udało się połączyć z serwerem lub połączenie zostało przerwane ({ $reason })
error-in-use = nie można usunąć aplikacji, ponieważ jest używana do logowania na kontach: { $accounts }
error-turned-off = ta aplikacja logowania jest wyłączona dla nowych kont
error-folder-name = nazwa folderu musi mieć od 1 do 200 znaków i nie może zawierać znaków sterujących
error-folder-separator = na tym serwerze nazwa folderu nie może zawierać znaku „{ $separator }”
error-folder-special = nie można zmienić nazwy ani usunąć Skrzynki odbiorczej i folderów specjalnych
error-no-recipients = wiadomość nie ma odbiorców
error-bad-address = „{ $address }” nie jest adresem e-mail
error-not-own-address = { $address } nie jest jednym z adresów nadawcy tego konta. Dodaj go w polu „Inne adresy, z których wysyłasz” we właściwościach konta.
rule-query-refused = Reguły nie mogą filtrować według folderu ani daty ({ $words }).
rule-no-query = Wpisz kryteria wyszukiwania dla wiadomości przychodzących.
rule-no-action = Wybierz co najmniej jedno działanie dla reguły.
error-attachment = Nie można odczytać pliku { $path }: { $error }
error-no-drafts = konto nie ma folderu Wersje robocze, w którym można zapisać wiadomość
error-draft-attachment = nie udało się zachować załącznika wersji roboczej: { $error }
error-password-not-saved = nie udało się zapisać hasła na następne uruchomienie: { $error }
error-sign-in-not-saved = nie udało się zapisać nowych danych logowania na następne uruchomienie: { $error }
error-import-unreadable = nie można odczytać pliku { $path }: { $error }
error-import-too-large = plik { $path } jest większy niż 50 MB
error-import-not-mail = plik { $path } nie jest wiadomością e-mail
error-list-answered = serwer listy mailingowej zwrócił kod odpowiedzi { $status }
error-not-built = nie udało się utworzyć wiadomości
error-outbox-waits = { $count ->
    [one] wiadomość czeka w Skrzynce nadawczej; przy następnym wysyłaniu/odbieraniu program ponowi próbę jej wysłania
    [few] { $count } wiadomości czekają w Skrzynce nadawczej; przy następnym wysyłaniu/odbieraniu program ponowi próbę ich wysłania
    [many] { $count } wiadomości czeka w Skrzynce nadawczej; przy następnym wysyłaniu/odbieraniu program ponowi próbę ich wysłania
   *[other] { $count } wiadomości czeka w Skrzynce nadawczej; przy następnym wysyłaniu/odbieraniu program ponowi próbę ich wysłania
}
error-draft-not-removed = nie udało się usunąć wcześniejszej wersji roboczej wiadomości z folderu Wersje robocze: { $reason }
error-sent-but = wiadomość została wysłana, ale { $problem }
error-sent-still-in-outbox = nadal jest w Skrzynce nadawczej: { $error }
error-sent-no-copy = nie udało się zapisać kopii w folderze Elementy wysłane: { $reason }
error-no-password = brak hasła dla tego konta
error-no-sign-in = brak danych logowania dla tego konta
error-provider-missing = ta wersja nie może użyć zapisanej konfiguracji logowania ({ $provider }). Sprawdź, czy jej aplikacja logowania nie została usunięta
error-provider-servers = serwery tego konta nie zgadzają się z serwerami jego aplikacji logowania
error-app-scopes = { $reason }. Serwer poczty nie przyjął tokenu aplikacji logowania: sprawdź, czy zakresy uprawnień aplikacji dają dostęp do poczty
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Wbudowana aplikacja logowania Google jest wyłączona. Możesz użyć własnej aplikacji logowania Google lub hasła aplikacji, jeśli konto je obsługuje. Jeśli jesteś użytkownikiem testowym wbudowanej aplikacji, włącz ją w oknie Aplikacje logowania dostępnym z ustawień kont.
sign-in-off-other = Ta opcja została wyłączona w oknie Aplikacje logowania, dostępnym z ustawień kont. Można ją tam ponownie włączyć.
sign-in-app-no-name = aplikacja logowania musi mieć nazwę
sign-in-app-no-client = brak identyfikatora klienta
sign-in-app-no-scopes = aplikacja logowania potrzebuje zakresów uprawnień, które dają dostęp do poczty
sign-in-app-bad-host = konfiguracja serwera { $server } jest nieprawidłowa: sprawdź nazwę hosta i port
sign-in-app-plain = serwer { $server } musi używać SSL/TLS lub STARTTLS
sign-in-app-not-checked = wystawca nie został jeszcze sprawdzony
sign-in-app-issuer-changed = wystawca się zmienił: wpisz ponownie klucz tajny klienta albo go usuń
sign-in-register-google = W Google Cloud Console utwórz klienta OAuth typu Aplikacja komputerowa, z zakresem https://mail.google.com/ na ekranie zgody. Dopóki aplikacja jest w fazie testów, logować się mogą tylko jej użytkownicy testowi.
sign-in-register-microsoft = W Microsoft Entra zarejestruj aplikację z platformą Aplikacje mobilne i klasyczne, identyfikatorem URI przekierowania http://localhost, dozwolonymi przepływami klienta publicznego oraz uprawnieniami delegowanymi IMAP.AccessAsUser.All, SMTP.Send i offline_access. Tylko dla swojej organizacji użyj jako wystawcy https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Zarejestruj natywnego (publicznego) klienta z poniższym identyfikatorem URI przekierowania; dostawca musi zezwalać na dowolny port (RFC 8252). Dodaj zakres uprawnień wymagany przez dostawcę do obsługi poczty.

## Calendar invitations

repeats = Powtarza się
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Codziennie
        [few] Co { $interval } dni
        [many] Co { $interval } dni
       *[other] Co { $interval } dni
    }
    [week] { $interval ->
        [one] Co tydzień
        [few] Co { $interval } tygodnie
        [many] Co { $interval } tygodni
       *[other] Co { $interval } tygodni
    }
    [month] { $interval ->
        [one] Co miesiąc
        [few] Co { $interval } miesiące
        [many] Co { $interval } miesięcy
       *[other] Co { $interval } miesięcy
    }
   *[year] { $interval ->
        [one] Co rok
        [few] Co { $interval } lata
        [many] Co { $interval } lat
       *[other] Co { $interval } lat
    }
}
# "Co tydzień, w dni: poniedziałek, środa"
repeats-on = { $repeats }, w dni: { $days }
# "Co tydzień, 10 razy"
repeats-times = { $count ->
    [one] { $repeats }, jeden raz
    [few] { $repeats }, { $count } razy
    [many] { $repeats }, { $count } razy
   *[other] { $repeats }, { $count } razy
}
day-monday = poniedziałek
day-tuesday = wtorek
day-wednesday = środa
day-thursday = czwartek
day-friday = piątek
day-saturday = sobota
day-sunday = niedziela

## AI agents

agent-level-read = Czytanie poczty: przeglądanie folderów, list wiadomości, konwersacji, treści i załączników, wyszukiwanie wiadomości i kontaktów oraz przeglądanie reguł wiadomości
agent-level-organize = Porządkowanie poczty: oznaczanie wiadomości jako przeczytane lub nieprzeczytane, zmiana flag, ich kolorów i oznaczeń śmieci, przenoszenie i archiwizowanie wiadomości, tworzenie folderów i zmiana ich nazw, obserwowanie i ignorowanie konwersacji, usuwanie wiadomości przez przeniesienie do folderu Elementy usunięte oraz wypisywanie z list mailingowych za Twoją zgodą
agent-level-drafts = Pisanie wersji roboczych, które możesz wysłać
agent-level-send = Wysyłanie poczty, każdej wiadomości dopiero po Twojej zgodzie
agent-connect-title = { $program } chce korzystać z Twojej poczty
agent-connect-detail = Agent AI prosi o dostęp do Twojej poczty w programie Inbox Classic. Wybierz, co może robić i z których kont może korzystać. Uprawnienia możesz później zmienić w menu Narzędzia > Agenci AI.

    Agenci czytają wiadomości od innych ludzi, a ich treść może zawierać próby oszukania agenta. Przed wysłaniem każdej wiadomości przez Inbox Classic agent musi uzyskać Twoją zgodę.
agent-reply-to = Odpowiedź na wiadomość „{ $subject }”
agent-reply-all-on = Odpowiedź wszystkim na wiadomość „{ $subject }”
agent-forward-of = Przesłanie dalej wiadomości „{ $subject }”
agent-never-written-one = Na adres { $address } nie wysłano jeszcze żadnej wiadomości.
agent-never-written-many = Liczba adresów, na które nie wysłano jeszcze żadnej wiadomości: { $count }.
agent-send-title = { $program } chce wysłać tę wiadomość
agent-send-detail = Sprawdź odbiorców i treść wiadomości. Po potwierdzeniu wiadomość będzie czekać w Skrzynce nadawczej przez co najmniej { $seconds } s. W tym czasie możesz ją usunąć, aby anulować wysyłanie.
agent-change-title = Co może robić { $program }
agent-change-allowed = Zmień, co agenci AI tego programu mogą robić z Twoją pocztą.
agent-change-refused = Ten program nie ma zgody na dostęp do Twojej poczty. Możesz jej udzielić, aby jego agenci mogli z niej korzystać.
agent-log-taken-back = { $entry } (cofnięte)
agent-files = Pliki: { $files }
agent-undo-refused = Tego działania nie można cofnąć.
agent-undo-refused-why = Tego działania nie można cofnąć: { $reason }.
agent-undo-impossible = tego nie można cofnąć
agent-undo-not-in-folder = wiadomości nie ma już w tym folderze
agent-undo-not-arrived = wiadomości nie ma jeszcze w folderze docelowym
agent-undo-sent = wiadomości nie ma już w Skrzynce nadawczej
agent-original-not-downloaded = oryginalna wiadomość nie została jeszcze pobrana. Najpierw ją otwórz
agent-turned-away = Odmowa dostępu
agent-can-nothing = Nic
agent-can-read = czytanie
agent-can-organize = porządkowanie
agent-can-drafts = pisanie wersji roboczych
agent-can-send = wysyłanie za Twoją zgodą
# "czytanie, porządkowanie i pisanie wersji roboczych"
agent-can-list = { $first } i { $last }
agent-accounts = { $count ->
    [0] brak kont
    [one] 1 konto
    [few] { $count } konta
    [many] { $count } kont
   *[other] { $count } kont
}
# "czytanie i porządkowanie; 1 konto"
agent-access = { $can }; { $accounts }
agent-unreadable = Nie można odczytać tej wiadomości.
agent-encrypted-original = Ta wiadomość jest zaszyfrowana. Agent nie może na nią odpowiedzieć ani przesłać jej dalej, ponieważ nie może szyfrować wiadomości.
agent-encrypted = Ta wiadomość jest zaszyfrowana. Agent nie może odczytać jej treści. Użytkownik musi ją otworzyć w programie Inbox Classic.
agent-too-many-changes = Zbyt wiele zmian w ciągu ostatnich 30 dni: ten agent wprowadził ich tyle, ile Inbox Classic przechowuje w dzienniku dla jednego programu. Będzie mógł wprowadzić kolejne, gdy najstarsze będą miały 30 dni.
agent-too-many-reads = Zbyt wiele odczytów w ciągu ostatnich 30 dni: ten agent przeczytał tyle, ile Inbox Classic przechowuje w dzienniku dla jednego programu. Będzie mógł czytać dalej, gdy najstarsze odczyty będą miały 30 dni.
list-encrypted = Zaszyfrowana wiadomość
agent-log-composed = Otwarto nową wiadomość „{ $subject }”, którą możesz dokończyć
agent-log-refused = Odrzucono prośbę o wysłanie wiadomości „{ $subject }”
agent-log-sent = Dodano wiadomość „{ $subject }” do kolejki wysyłania. Odbiorcy: { $to }
agent-log-draft = Zapisano wersję roboczą „{ $subject }”
agent-log-draft-replaced = Zastąpiono wersję roboczą „{ $subject }”
agent-log-draft-discarded = Zlecono trwałe usunięcie wersji roboczej „{ $subject }”
agent-draft-note = Tę wersję roboczą napisał agent AI { $program }. Sprawdź odbiorców i tekst, zanim ją wyślesz.
agent-log-read = Oznaczono jako przeczytaną „{ $subject }”
agent-log-unread = Oznaczono jako nieprzeczytaną „{ $subject }”
agent-log-flagged = Oznaczono flagą „{ $subject }”
agent-log-unflagged = Usunięto flagę z wiadomości „{ $subject }”
agent-log-deleted = Usunięto „{ $subject }”
agent-log-moved = Przeniesiono „{ $subject }” (cel: { $folder })
agent-log-junk = Oznaczono wiadomość „{ $subject }” jako śmieci
agent-log-not-junk = Usunięto oznaczenie „śmieci” z wiadomości „{ $subject }”
agent-log-archived = Zarchiwizowano „{ $subject }”
agent-log-folder = Zlecono utworzenie folderu „{ $name }”
agent-log-unsubscribed = Zatwierdzono prośbę o wypisanie z listy mailingowej. Wiadomość: „{ $subject }”
agent-log-unsubscribe-failed = Nie udało się wypisać z listy mailingowej. Wiadomość: „{ $subject }”. Powód: { $reason }
agent-log-unsubscribe-refused = Odrzucono prośbę o wypisanie z list mailingowych. Nadawcy: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } chce wypisać Cię z listy mailingowej
    [few] { $program } chce wypisać Cię z { $count } list mailingowych
    [many] { $program } chce wypisać Cię z { $count } list mailingowych
   *[other] { $program } chce wypisać Cię z { $count } list mailingowych
}
agent-unsubscribe-detail = { $count ->
    [1] Po zatwierdzeniu Inbox Classic poprosi poniższą listę o zaprzestanie wysyłania Ci wiadomości za pomocą dostępnej funkcji wypisania jednym kliknięciem. Nie są wysyłane wiadomości e-mail. Twoje dotychczasowe wiadomości nie są zmieniane, przenoszone ani usuwane.
   *[other] Po zatwierdzeniu Inbox Classic poprosi każdą z poniższych list o zaprzestanie wysyłania Ci wiadomości za pomocą dostępnej funkcji wypisania jednym kliknięciem. Nie są wysyłane wiadomości e-mail. Twoje dotychczasowe wiadomości nie są zmieniane, przenoszone ani usuwane.
}
agent-log-flag-color = Oznaczono wiadomość „{ $subject }” flagą { $color ->
    [red] czerwoną
    [orange] pomarańczową
    [yellow] żółtą
    [green] zieloną
    [blue] niebieską
    [purple] fioletową
   *[gray] szarą
}
agent-log-renamed = Zlecono zmianę nazwy folderu „{ $old }” na „{ $name }”
agent-log-watched = Zaczęto obserwować konwersację „{ $subject }”
agent-log-ignored = Zaczęto ignorować konwersację „{ $subject }”
agent-log-unmarked = Przestano obserwować lub ignorować konwersację „{ $subject }”
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = wiadomość została od tego czasu zmieniona
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Oznaczono 1 wiadomość jako przeczytaną (wyszukiwanie: { $query })
    [few] Oznaczono { $count } wiadomości jako przeczytane (wyszukiwanie: { $query })
    [many] Oznaczono { $count } wiadomości jako przeczytane (wyszukiwanie: { $query })
   *[other] Oznaczono { $count } wiadomości jako przeczytane (wyszukiwanie: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Oznaczono 1 wiadomość jako nieprzeczytaną (wyszukiwanie: { $query })
    [few] Oznaczono { $count } wiadomości jako nieprzeczytane (wyszukiwanie: { $query })
    [many] Oznaczono { $count } wiadomości jako nieprzeczytane (wyszukiwanie: { $query })
   *[other] Oznaczono { $count } wiadomości jako nieprzeczytane (wyszukiwanie: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Oznaczono flagą 1 wiadomość (wyszukiwanie: { $query })
    [few] Oznaczono flagą { $count } wiadomości (wyszukiwanie: { $query })
    [many] Oznaczono flagą { $count } wiadomości (wyszukiwanie: { $query })
   *[other] Oznaczono flagą { $count } wiadomości (wyszukiwanie: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Usunięto flagę z 1 wiadomości (wyszukiwanie: { $query })
    [few] Usunięto flagę z { $count } wiadomości (wyszukiwanie: { $query })
    [many] Usunięto flagę z { $count } wiadomości (wyszukiwanie: { $query })
   *[other] Usunięto flagę z { $count } wiadomości (wyszukiwanie: { $query })
}
agent-log-bulk-color = { $count ->
    [one] Oznaczono 1 wiadomość
    [few] Oznaczono { $count } wiadomości
    [many] Oznaczono { $count } wiadomości
   *[other] Oznaczono { $count } wiadomości
} flagą { $color ->
    [red] czerwoną
    [orange] pomarańczową
    [yellow] żółtą
    [green] zieloną
    [blue] niebieską
    [purple] fioletową
   *[gray] szarą
} (wyszukiwanie: { $query })
agent-log-bulk-moved = { $count ->
    [one] Przeniesiono 1 wiadomość do folderu { $folder } (wyszukiwanie: { $query })
    [few] Przeniesiono { $count } wiadomości do folderu { $folder } (wyszukiwanie: { $query })
    [many] Przeniesiono { $count } wiadomości do folderu { $folder } (wyszukiwanie: { $query })
   *[other] Przeniesiono { $count } wiadomości do folderu { $folder } (wyszukiwanie: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Zarchiwizowano 1 wiadomość (wyszukiwanie: { $query })
    [few] Zarchiwizowano { $count } wiadomości (wyszukiwanie: { $query })
    [many] Zarchiwizowano { $count } wiadomości (wyszukiwanie: { $query })
   *[other] Zarchiwizowano { $count } wiadomości (wyszukiwanie: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Oznaczono 1 wiadomość jako śmieci (wyszukiwanie: { $query })
    [few] Oznaczono { $count } wiadomości jako śmieci (wyszukiwanie: { $query })
    [many] Oznaczono { $count } wiadomości jako śmieci (wyszukiwanie: { $query })
   *[other] Oznaczono { $count } wiadomości jako śmieci (wyszukiwanie: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Usunięto oznaczenie „śmieci” z 1 wiadomości (wyszukiwanie: { $query })
    [few] Usunięto oznaczenie „śmieci” z { $count } wiadomości (wyszukiwanie: { $query })
    [many] Usunięto oznaczenie „śmieci” z { $count } wiadomości (wyszukiwanie: { $query })
   *[other] Usunięto oznaczenie „śmieci” z { $count } wiadomości (wyszukiwanie: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Usunięto 1 wiadomość (wyszukiwanie: { $query })
    [few] Usunięto { $count } wiadomości (wyszukiwanie: { $query })
    [many] Usunięto { $count } wiadomości (wyszukiwanie: { $query })
   *[other] Usunięto { $count } wiadomości (wyszukiwanie: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] W ciągu ostatnich 15 minut
    [hour] W ciągu ostatniej godziny
    [hours] W ciągu ostatnich 4 godzin
    [day] W ciągu ostatnich 24 godzin
    [week] W ciągu ostatnich 7 dni
   *[all] W ciągu ostatnich 30 dni
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] W tym czasie program { $program } nie wprowadził żadnych zmian, które można cofnąć.
    [one] Cofnąć zmianę wprowadzoną w tym czasie przez program { $program }?
    [few] Cofnąć { $count } zmiany wprowadzone w tym czasie przez program { $program }?
    [many] Cofnąć { $count } zmian wprowadzonych w tym czasie przez program { $program }?
   *[other] Cofnąć { $count } zmian wprowadzonych w tym czasie przez program { $program }?
}
agent-undo-since-detail = Program spróbuje przywrócić poprzednie foldery, stan przeczytania i flagi oraz usunąć wiadomości nadal czekające w Skrzynce nadawczej. Cofanie zależy od bieżącego stanu wiadomości i może udać się tylko częściowo. Usunięcie flagi może też usunąć jej później zmieniony kolor.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Niczego nie cofnięto.
    [one] Cofnięto 1 zmianę, w całości lub częściowo.
    [few] Cofnięto { $count } zmiany, w całości lub częściowo.
    [many] Cofnięto { $count } zmian, w całości lub częściowo.
   *[other] Cofnięto { $count } zmian, w całości lub częściowo.
}
agent-undo-left-gone = { $count ->
    [one] Nie znaleziono 1 wiadomości w oczekiwanym miejscu.
    [few] Nie znaleziono { $count } wiadomości w oczekiwanym miejscu.
    [many] Nie znaleziono { $count } wiadomości w oczekiwanym miejscu.
   *[other] Nie znaleziono { $count } wiadomości w oczekiwanym miejscu.
}
agent-undo-left-changed = { $count ->
    [one] 1 wiadomość została od tego czasu zmieniona przez Ciebie lub na serwerze i pozostała bez zmian.
    [few] { $count } wiadomości zostały od tego czasu zmienione przez Ciebie lub na serwerze i pozostały bez zmian.
    [many] { $count } wiadomości zostało od tego czasu zmienionych przez Ciebie lub na serwerze i pozostało bez zmian.
   *[other] { $count } wiadomości zostało od tego czasu zmienionych przez Ciebie lub na serwerze i pozostało bez zmian.
}
agent-undo-left-sent = { $count ->
    [one] 1 wiadomość opuściła już Skrzynkę nadawczą.
    [few] { $count } wiadomości opuściły już Skrzynkę nadawczą.
    [many] { $count } wiadomości opuściło już Skrzynkę nadawczą.
   *[other] { $count } wiadomości opuściło już Skrzynkę nadawczą.
}
agent-undo-left-impossible = { $count ->
    [one] Nie można cofnąć 1 zmiany.
    [few] Nie można cofnąć { $count } zmian.
    [many] Nie można cofnąć { $count } zmian.
   *[other] Nie można cofnąć { $count } zmian.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Ta wiadomość zawiera potwierdzenie udziału w wydarzeniu „{ $summary }” ({ $when }).
    [tentative] Ta wiadomość zawiera wstępne potwierdzenie udziału w wydarzeniu „{ $summary }” ({ $when }).
   *[decline] Ta wiadomość zawiera odmowę udziału w wydarzeniu „{ $summary }” ({ $when }).
} Odpowiedź zostanie wysłana do organizatora w formacie obsługiwanym przez kalendarze. Status zaproszenia w Inbox Classic zmieni się dopiero po wysłaniu wiadomości; nie potwierdza to jej przetworzenia przez kalendarz organizatora.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Zaakceptowano: { $summary }
    [tentative] Wstępnie zaakceptowano: { $summary }
   *[decline] Odrzucono: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } akceptuje to zaproszenie.
    [tentative] { $name } wstępnie akceptuje to zaproszenie.
   *[decline] { $name } odrzuca to zaproszenie.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] przeczytano 1 wiadomość
    [few] przeczytano { $count } wiadomości
    [many] przeczytano { $count } wiadomości
   *[other] przeczytano { $count } wiadomości
}
agent-reads-attachments = { $count ->
    [one] poproszono o zawartość 1 załącznika
    [few] poproszono o zawartość { $count } załączników
    [many] poproszono o zawartość { $count } załączników
   *[other] poproszono o zawartość { $count } załączników
}
agent-reads-searches = { $count ->
    [one] wyszukiwano raz
    [few] wyszukiwano { $count } razy
    [many] wyszukiwano { $count } razy
   *[other] wyszukiwano { $count } razy
}
agent-reads-lists = { $count ->
    [one] przejrzano listę wiadomości raz
    [few] przeglądano listy wiadomości { $count } razy
    [many] przeglądano listy wiadomości { $count } razy
   *[other] przeglądano listy wiadomości { $count } razy
}
# each read under that row
agent-read-message = Przeczytano wiadomość „{ $subject }”
agent-read-conversation = { $count ->
    [one] Przeczytano konwersację „{ $subject }” (1 wiadomość)
    [few] Przeczytano konwersację „{ $subject }” ({ $count } wiadomości)
    [many] Przeczytano konwersację „{ $subject }” ({ $count } wiadomości)
   *[other] Przeczytano konwersację „{ $subject }” ({ $count } wiadomości)
}
agent-read-attachment = Poproszono o zawartość załącznika „{ $name }” z wiadomości „{ $subject }”
agent-read-search = { $count ->
    [one] Wyszukano „{ $query }”: 1 wiadomość
    [few] Wyszukano „{ $query }”: { $count } wiadomości
    [many] Wyszukano „{ $query }”: { $count } wiadomości
   *[other] Wyszukano „{ $query }”: { $count } wiadomości
}
agent-read-people = Wyszukano kontakty według nazwy lub adresu: „{ $query }”
agent-read-list = { $count ->
    [one] Odczytano 1 pozycję listy: { $folder }
    [few] Odczytano pozycje listy „{ $folder }”: { $count }
    [many] Odczytano pozycje listy „{ $folder }”: { $count }
   *[other] Odczytano pozycje listy „{ $folder }”: { $count }
}
agent-read-changes = { $count ->
    [one] Odczytano dane 1 nowej wiadomości
    [few] Odczytano dane { $count } nowych wiadomości
    [many] Odczytano dane { $count } nowych wiadomości
   *[other] Odczytano dane { $count } nowych wiadomości
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Programy uruchomione z aplikacji { $terminal }
agent-terminal-programs-windows = Programy uruchomione z terminala ({ $terminal })
agent-terminal-programs-linux = Programy uruchomione z terminala ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Program uruchomiony z aplikacji { $terminal }
agent-terminal-program-windows = Program uruchomiony z terminala ({ $terminal })
agent-terminal-program-linux = Program uruchomiony z terminala ({ $terminal })
agent-connect-title-terminal = { $programs } chcą korzystać z Twojej poczty
agent-connect-terminal-detail = Agenci uruchamiani z tego samego rozpoznanego programu terminala współdzielą dostęp, na który tu zezwolisz. Aby zarządzać agentem osobno, dodaj --name i wybraną nazwę do jego argumentów w ustawieniach MCP. Nazwa nie potwierdza tożsamości programu.
agent-connect-claimed = Program przedstawił się jako { $claimed }. Inbox Classic sprawdził, który program go uruchomił: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = dostawca nie przekazał tokenu odświeżania
sign-in-no-account = dostawca nie podał, które konto się zalogowało
sign-in-not-finished = logowanie nie zostało ukończone
secrets-unavailable = { $store } jest niedostępny
secrets-unavailable-why = { $store } jest niedostępny: { $error }
secrets-windows = Menedżer poświadczeń
secrets-mac = Pęk kluczy
secrets-linux = Systemowy pęk kluczy (Secret Service)
error-no-such-file = nie ma takiego pliku
cards-file-too-big = Ten plik przekracza dopuszczalny rozmiar książki adresowej.
ui-sender-added = Dodano kontakt do Książki adresowej: { $name }.
ui-sender-known = { $name } jest już w Książce adresowej.
ui-sender-none = Nadawca tej wiadomości nie ma adresu e-mail, który można dodać.
card-name-needed = Kontakt nie ma nazwy ani adresu e-mail.
# a file of Import Address Book that could not be read: "kontakty.vcf: nie ma takiego pliku"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

otp-heading = Kod z domeny { $domain }
otp-copy = Kopiuj
otp-note = Wpisz go tylko na stronie { $domain }.
otp-old = Ten kod został wysłany ponad godzinę przed otwarciem wiadomości i prawdopodobnie już wygasł.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } uczestnik
        [few] { $count } uczestników
        [many] { $count } uczestników
       *[other] { $count } uczestników
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } to Twój kod dla domeny { $domain }

## OpenPGP keys (keys.rs)

pgp-key-valid = Ważny
pgp-key-expires = Ważny do { $date }
pgp-key-expired = Wygasł { $date }
pgp-key-revoked = Unieważniony
pgp-key-revoked-why = Unieważniony: { $reason }
pgp-key-not-valid = Nieważny
pgp-key-locked = Nie można otworzyć części prywatnej klucza. Sprawdź dostęp do magazynu danych logowania: { $store }. Jeśli klucza chroniącego te dane rzeczywiście brakuje, zaimportuj ponownie kopię zapasową klucza prywatnego.
pgp-source-own = Utworzony w Inbox Classic
pgp-source-file = Zaimportowany z pliku
pgp-source-paste = Wklejony
pgp-source-attachment = Z wiadomości
pgp-source-vcard = Z wizytówki kontaktu
pgp-source-wkd = Od dostawcy poczty nadawcy
pgp-source-keyserver = Z keys.openpgp.org
pgp-source-autocrypt = Z nagłówka Autocrypt wiadomości
pgp-error-no-store = Klucze prywatne są chronione przez { $store }, którego nie można użyć: { $error }
pgp-error-wrong-passphrase = Hasło jest nieprawidłowe.
pgp-error-not-a-key = To nie jest klucz OpenPGP.
pgp-error-too-large = Klucz jest za duży.
pgp-error-unusable = Klucz nie nadaje się do wymaganej operacji podpisywania lub szyfrowania. Może nie zawierać odpowiedniego klucza podrzędnego albo używać nieobsługiwanej kryptografii.
pgp-imported-private = { $count ->
    [one] Zaimportowano Twój klucz prywatny.
    [few] Zaimportowano { $count } klucze prywatne.
    [many] Zaimportowano { $count } kluczy prywatnych.
   *[other] Zaimportowano { $count } kluczy prywatnych.
}
pgp-imported-public = { $count ->
    [one] Zaimportowano jeden klucz.
    [few] Zaimportowano { $count } klucze.
    [many] Zaimportowano { $count } kluczy.
   *[other] Zaimportowano { $count } kluczy.
}
pgp-imported-pending = Dla adresów { $addresses } jest już używany inny klucz. Nowy klucz czeka na wybór we właściwościach kontaktu.
pgp-error-needs-passphrase = Klucz prywatny jest zabezpieczony hasłem. Wpisz je, aby zaimportować klucz.
pgp-error-mismatch = Klucz prywatny nie pasuje do swojego klucza publicznego. Mógł zostać zmieniony.
pgp-file-name-public = { $who } klucz publiczny.asc
pgp-file-name-private = { $who } kopia zapasowa klucza prywatnego.asc
pgp-pending = { $date } znaleziono inny klucz dla { $address }.

## Reading signed and encrypted mail (protect.rs)

pgp-part-verified = Poprawny podpis cyfrowy: { $signer }; potwierdzono właściciela klucza
pgp-part-signed = Poprawny podpis cyfrowy: { $signer } (nie potwierdzono właściciela klucza)
pgp-part-other = Poprawny podpis cyfrowy: { $signer } (osoba inna niż nadawca)
pgp-part-unknown-key = Podpis cyfrowy niesprawdzony: nieznany klucz
pgp-part-not-signed = Bez podpisu cyfrowego
pgp-part-not-checked = Nie sprawdzono podpisu cyfrowego
pgp-part-encrypted = Zaszyfrowana. { $signature }
pgp-part-no-key = Brak klucza do odszyfrowania tej części
pgp-part-changed = Nie udało się potwierdzić integralności zaszyfrowanej części. Nie jest wyświetlana
pgp-part-unprotected = Zaszyfrowana część nie ma ochrony przed zmianami i nie jest wyświetlana
pgp-part-broken = Nie można odczytać zaszyfrowanej części
pgp-why-mismatch = Podpis nie pasuje do tego tekstu
pgp-why-weak-hash = Podpis używa algorytmu { $hash }, który nie jest już bezpieczny
pgp-why-key-expired = Podpis złożono po wygaśnięciu klucza (data wygaśnięcia: { $date })
pgp-why-key-revoked = Podpis złożono unieważnionym kluczem
pgp-why-not-signing-key = Klucz nie jest przeznaczony do podpisywania
pgp-why-from-future = Podpis ma datę z przyszłości
pgp-why-signature-expired = Podpis wygasł
pgp-why-key-not-valid = Podpis złożono nieważnym kluczem
pgp-why-not-for-you = Wiadomość podpisano dla innych odbiorców i przekazano Tobie
pgp-why-not-key-in-use = Podpisano innym kluczem niż klucz wybrany dla adresu { $address }
pgp-part-pictures-loaded = { $label }. Obrazy zostały pobrane z internetu
pgp-error-no-own-key = Nie masz klucza dla { $address }, którym można podpisywać lub szyfrować. Utwórz go w menu Narzędzia > Klucze szyfrowania albo wyłącz Podpisz i Szyfruj.
pgp-error-missing-keys = { $count ->
    [one] Brak odpowiedniego klucza do szyfrowania wiadomości do odbiorcy: { $addresses }.
   *[other] Brak odpowiednich kluczy do szyfrowania wiadomości do odbiorców: { $addresses }.
}
pgp-error-encrypted-quote = Wiadomość zawiera tekst, obrazy lub załączniki z zaszyfrowanej wiadomości, więc można ją wysłać tylko po zaszyfrowaniu. Włącz opcję „Szyfruj” albo usuń całą tę zawartość.
pgp-error-protect = Nie udało się podpisać ani zaszyfrować wiadomości: { $reason }
pgp-found-keys = Znaleziono klucze dla adresów: { $addresses }.
pgp-found-none = Nie znaleziono klucza dla: { $addresses }. Poproś o przesłanie klucza publicznego.
pgp-found-no-key = Nie znaleziono klucza.
pgp-find-unavailable = Nie można teraz wyszukać kluczy: { $error }
pgp-publish-pending = Serwis keys.openpgp.org wysłał linki potwierdzające na adresy: { $addresses }. Potwierdź każdy adres, aby można było znaleźć Twój klucz na jego podstawie.
pgp-publish-done = Twój klucz jest opublikowany na keys.openpgp.org dla { $addresses }.
pgp-publish-failed = Nie udało się opublikować klucza: { $error }
pgp-keyserver-off = Wyszukiwanie kluczy na keys.openpgp.org jest wyłączone w { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Wiadomość zostanie wysłana zaszyfrowana i podpisana cyfrowo. Treść będzie dostępna tylko dla Ciebie i odbiorcy: { $addresses }.
   *[other] Wiadomość zostanie wysłana zaszyfrowana i podpisana cyfrowo. Treść będzie dostępna tylko dla Ciebie i odbiorców ({ $count }).
}
pgp-compose-encrypt-ready = Zostanie zaszyfrowana i podpisana. Dodaj odbiorców, których klucze masz.
pgp-compose-missing = { $count ->
    [one] Brak odpowiedniego klucza dla odbiorcy: { $addresses }. Nie można jeszcze zaszyfrować wiadomości.
   *[other] Odbiorcy bez odpowiedniego klucza ({ $count }): { $addresses }. Nie można jeszcze zaszyfrować wiadomości.
}
pgp-compose-looking = Wyszukiwanie kluczy dla: { $addresses }...
pgp-compose-signed = Wiadomość zostanie podpisana cyfrowo przy wysyłaniu. Odbiorcy będą mogli sprawdzić, czy jej treść nie zmieniła się od chwili podpisania.
pgp-compose-reply-clear = Wiadomość zostanie wysłana bez szyfrowania, choć oryginalna wiadomość była zaszyfrowana.
pgp-compose-encrypted-files = Wiadomość zawiera załączniki z zaszyfrowanej wiadomości, więc można ją wysłać tylko po zaszyfrowaniu. Włącz opcję „Szyfruj” albo usuń te załączniki.
pgp-compose-sign-tip = Podpisz wiadomość cyfrowo swoim kluczem, aby odbiorcy mogli sprawdzić, czy jej treść nie została zmieniona
pgp-compose-sign-tip-encrypted = Wiadomość wysyłana w postaci zaszyfrowanej jest też podpisywana cyfrowo
pgp-compose-encrypt-tip = Zaszyfruj treść wiadomości, aby była dostępna tylko dla Ciebie i odbiorców
pgp-compose-make-key = Nie masz jeszcze klucza dla adresu { $address }. Utworzyć go teraz? Za jego pomocą możesz cyfrowo podpisywać i szyfrować wiadomości.
pgp-compose-key-unusable =
    Nie można użyć Twojego klucza dla adresu { $address }.

    Powód: { $state }

    Otwórz okno „Klucze szyfrowania” i sprawdź przyczynę. Jeśli nie da się przywrócić dostępu do klucza, zaimportuj jego kopię zapasową albo utwórz nowy klucz.
pgp-compose-encrypt-off-quote = Wiadomość zawiera tekst, obrazy lub załączniki pochodzące z zaszyfrowanej wiadomości. Można ją wysłać bez szyfrowania dopiero po usunięciu tej zawartości. Mimo to wyłączyć szyfrowanie?
pgp-compose-encrypt-off-reply = Odpowiadasz na zaszyfrowaną wiadomość lub przesyłasz ją dalej. Bez szyfrowania treść Twojej wiadomości mogą odczytać także serwery, przez które jest przesyłana. Wyłączyć szyfrowanie?
pgp-recipient-verified = Potwierdzono właściciela klucza
pgp-recipient-found = Nie potwierdzono właściciela klucza
pgp-recipient-own = Twój klucz
pgp-recipient-looking = Wyszukiwanie klucza...
pgp-recipient-missing = Brak klucza
pgp-recipient-not-found = Nie znaleziono klucza. Ostatnie wyszukiwanie: { $date }
pgp-recipient-unusable = Nie można użyć klucza: { $state }
pgp-recipients-intro = Wiadomość jest szyfrowana kluczem każdego odbiorcy oraz Twoim.
pgp-recipients-intro-missing = { $count ->
    [one] Jeden odbiorca nie ma odpowiedniego klucza do szyfrowania. Znajdź jego klucz, usuń odbiorcę z wiadomości albo wyślij ją bez szyfrowania, jeśli nie zawiera tekstu, obrazów ani załączników z zaszyfrowanych wiadomości.
    [few] { $count } odbiorcy nie mają odpowiednich kluczy do szyfrowania. Znajdź ich klucze, usuń tych odbiorców z wiadomości albo wyślij ją bez szyfrowania, jeśli nie zawiera tekstu, obrazów ani załączników z zaszyfrowanych wiadomości.
    [many] { $count } odbiorców nie ma odpowiednich kluczy do szyfrowania. Znajdź ich klucze, usuń tych odbiorców z wiadomości albo wyślij ją bez szyfrowania, jeśli nie zawiera tekstu, obrazów ani załączników z zaszyfrowanych wiadomości.
   *[other] { $count } odbiorców nie ma odpowiednich kluczy do szyfrowania. Znajdź ich klucze, usuń tych odbiorców z wiadomości albo wyślij ją bez szyfrowania, jeśli nie zawiera tekstu, obrazów ani załączników z zaszyfrowanych wiadomości.
}
pgp-details-part = Część { $number }: { $label }
attachment-from-part = Z części { $number }: { $label }
pgp-details-signed = Podpisano cyfrowo { $when } kluczem { $key }
pgp-details-unknown-key = Podpisano kluczem { $key }, którego nie masz
pgp-details-opened = Odszyfrowano Twoim kluczem { $key }
pgp-details-for = Zaszyfrowano dla: { $keys }
pgp-details-plain = Bez podpisu cyfrowego i szyfrowania
pgp-bar-parts = Części wiadomości ({ $count }): { $list }. Przy każdej części podano, jak jest chroniona.
pgp-bar-count-verified = podpisane kluczem o potwierdzonym właścicielu: { $count }
pgp-bar-count-encrypted-signed = { $count ->
    [one] 1 zaszyfrowana i podpisana
    [few] { $count } zaszyfrowane i podpisane
    [many] { $count } zaszyfrowanych i podpisanych
   *[other] { $count } zaszyfrowanych i podpisanych
}
pgp-bar-count-encrypted = { $count ->
    [one] 1 zaszyfrowana
    [few] { $count } zaszyfrowane
    [many] { $count } zaszyfrowanych
   *[other] { $count } zaszyfrowanych
}
pgp-bar-count-signed = { $count ->
    [one] 1 podpisana
    [few] { $count } podpisane
    [many] { $count } podpisanych
   *[other] { $count } podpisanych
}
pgp-bar-count-warning = { $count ->
    [one] 1 wymaga uwagi
    [few] { $count } wymagają uwagi
    [many] { $count } wymaga uwagi
   *[other] { $count } wymaga uwagi
}
pgp-bar-count-neutral = bez sprawdzonego podpisu cyfrowego: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Ustawienia
setup-part-preferences = Preferencje okien
setup-part-accounts = Konta
setup-part-sign-in-apps = Aplikacje logowania
setup-part-contacts = Kontakty i grupy
setup-part-keys = Klucze szyfrowania
setup-part-rules = Reguły wiadomości
setup-part-trusted-senders = Zaufani nadawcy
setup-holds-settings = { $count ->
    [one] 1 ustawienie
    [few] { $count } ustawienia
    [many] { $count } ustawień
   *[other] { $count } ustawień
}
setup-holds-preferences = { $count ->
    [one] 1 preferencja
    [few] { $count } preferencje
    [many] { $count } preferencji
   *[other] { $count } preferencji
}
setup-holds-accounts = { $count ->
    [one] 1 konto
    [few] { $count } konta
    [many] { $count } kont
   *[other] { $count } kont
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 aplikacja logowania
    [few] { $count } aplikacje logowania
    [many] { $count } aplikacji logowania
   *[other] { $count } aplikacji logowania
}
setup-holds-built-in = Które wbudowane aplikacje logowania są włączone
setup-holds-contacts = { $count ->
    [one] 1 kontakt
    [few] { $count } kontakty
    [many] { $count } kontaktów
   *[other] { $count } kontaktów
}
setup-holds-groups = { $count ->
    [one] 1 grupa
    [few] { $count } grupy
    [many] { $count } grup
   *[other] { $count } grup
}
setup-holds-own-keys = { $count ->
    [one] 1 Twój klucz
    [few] { $count } Twoje klucze
    [many] { $count } Twoich kluczy
   *[other] { $count } Twoich kluczy
}
setup-holds-contact-keys = { $count ->
    [one] 1 klucz kontaktu
    [few] { $count } klucze kontaktów
    [many] { $count } kluczy kontaktów
   *[other] { $count } kluczy kontaktów
}
setup-holds-rules = { $count ->
    [one] 1 reguła
    [few] { $count } reguły
    [many] { $count } reguł
   *[other] { $count } reguł
}
setup-holds-trusted-senders = { $count ->
    [one] 1 zaufany nadawca
    [few] { $count } zaufanych nadawców
    [many] { $count } zaufanych nadawców
   *[other] { $count } zaufanych nadawców
}
setup-sign-in-password = Hasło
setup-account-secret-password = Jego hasło jest w pliku.
setup-account-secret-token = Jego dane logowania są w pliku.
setup-account-asks-password = Po imporcie poprosi o hasło.
setup-account-signs-in-again = Po imporcie zalogujesz się do niego ponownie.
setup-account-here = Jest już tutaj skonfigurowane, więc zostanie pominięte.
setup-account-no-app = Konto korzysta z aplikacji logowania „{ $app }”, której tutaj nie ma. Zaimportuj także aplikacje logowania.
setup-invalid-address = „{ $address }” nie jest adresem e-mail.
setup-invalid-server = Nazwa, port lub ustawienie zabezpieczeń serwera { $server } są nieprawidłowe albo nie zostały podane.
setup-invalid-user = Nie ma nazwy użytkownika.
setup-invalid-sign-in = Konfiguracja logowania tego konta jest nieprawidłowa lub nieobsługiwana przez Inbox Classic.
setup-error-empty = Plik jest pusty.
setup-error-too-large = Plik przekracza dopuszczalny rozmiar konfiguracji Inbox Classic.
setup-error-not-setup = Ten plik nie jest konfiguracją Inbox Classic.
setup-error-damaged = Plik konfiguracji jest uszkodzony i nie można go odczytać.
setup-error-newer = Tę konfigurację zapisała nowsza wersja Inbox Classic ({ $version }). Zaktualizuj Inbox Classic i zaimportuj ją ponownie.
setup-error-needs-passphrase = Ten plik konfiguracji jest zabezpieczony hasłem. Wpisz hasło użyte przy jego zapisywaniu.
setup-error-wrong-passphrase = To hasło nie pasuje do pliku konfiguracji.
setup-error-changed = Nie można potwierdzić integralności pliku konfiguracji. Mógł zostać zmieniony lub uszkodzony, więc nie można go zaimportować.
# review: new
sync-wrong-passphrase = To nie jest hasło synchronizacji tego sejfu. Wpisz hasło wybrane podczas konfigurowania synchronizacji na pierwszym komputerze.
# review: new
sync-place = { $place }, jako „{ $name }”
# review: new
sync-news-removed = { $count ->
    [one] Synchronizacja usunęła konto { $accounts }, ponieważ zostało usunięte na innym komputerze.
   *[other] Synchronizacja usunęła konta, ponieważ zostały usunięte na innym komputerze: { $accounts }
}
# review: new
sync-news-lost = { $count ->
    [one] Zmiana wprowadzona w tym samym czasie na innym komputerze została zastąpiona zmianą wprowadzoną tutaj. Zachowano ją w historii synchronizacji.
    [few] { $count } zmiany wprowadzone w tym samym czasie na innych komputerach zostały zastąpione zmianami wprowadzonymi tutaj. Zachowano je w historii synchronizacji.
    [many] { $count } zmian wprowadzonych w tym samym czasie na innych komputerach zostało zastąpionych zmianami wprowadzonymi tutaj. Zachowano je w historii synchronizacji.
   *[other] { $count } zmian wprowadzonych w tym samym czasie na innych komputerach zostało zastąpionych zmianami wprowadzonymi tutaj. Zachowano je w historii synchronizacji.
}
# review: new
sync-status-busy = Synchronizowanie…
# review: new
sync-status-never = Jeszcze nie synchronizowano.
# review: new
sync-status-last = Ostatnia synchronizacja: { $when }.
# review: new
sync-status-today = Ostatnia synchronizacja: dziś o { $time }.
# review: new
sync-when-today = dziś o { $time }
# review: new
sync-status-problem = Nie udało się zsynchronizować: { $problem }
# review: new
sync-removed-here = Ten komputer został usunięty z synchronizacji na innym komputerze. Wyłącz synchronizację, a potem skonfiguruj ją ponownie, aby dołączyć.
# review: new
sync-item-account = Konto { $name }
# review: new
sync-item-contact = Kontakt { $name }
# review: new
sync-item-group = Grupa { $name }
# review: new
sync-item-key = Klucz { $name }
# review: new
sync-item-rule = Reguła { $name }
# review: new
sync-item-trusted = Zaufany nadawca { $name }
# review: new
sync-item-sign-in-app = Aplikacja logowania { $name }
# review: new
sync-item-settings = Ustawienia
# review: new
sync-another-computer = inny komputer
# review: new
sync-no-key = Ten komputer nie ma już klucza sejfu synchronizacji. Wyłącz synchronizację i włącz ją ponownie, podając hasło synchronizacji.
setup-error-read = Nie udało się odczytać pliku konfiguracji: { $error }
setup-error-write = Nie udało się zapisać konfiguracji: { $error }
setup-error-no-parts = Wybierz co najmniej jedną część.
setup-left-out = { $count ->
    [one] 1 wpis z części { $part } nie nadaje się do użycia i zostanie pominięty.
    [few] { $count } wpisy z części { $part } nie nadają się do użycia i zostaną pominięte.
    [many] { $count } wpisów z części { $part } nie nadaje się do użycia i zostanie pominiętych.
   *[other] { $count } wpisów z części { $part } nie nadaje się do użycia i zostanie pominiętych.
}
setup-imported-settings = Ustawienia zostały zastąpione.
setup-imported-preferences = Preferencje okien zostały zastąpione.
setup-added-accounts = { $count ->
    [one] Dodano 1 konto.
    [few] Dodano { $count } konta.
    [many] Dodano { $count } kont.
   *[other] Dodano { $count } kont.
}
setup-skipped-here = Pominięto konto { $address }, ponieważ jest już skonfigurowane na tym komputerze.
setup-skipped-no-app = Pominięto konto { $address }, ponieważ brakuje aplikacji logowania „{ $app }”.
setup-skipped-invalid = Pominięto { $address }: { $reason }
setup-asks-password = Przy połączeniu z kontem { $address } trzeba będzie podać hasło.
setup-signs-in-again = Przy połączeniu z kontem { $address } trzeba będzie ponownie zalogować się w przeglądarce.
setup-added-sign-in-apps = { $count ->
    [one] Dodano 1 aplikację logowania.
    [few] Dodano { $count } aplikacje logowania.
    [many] Dodano { $count } aplikacji logowania.
   *[other] Dodano { $count } aplikacji logowania.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 aplikacja logowania jest już tutaj skonfigurowana.
    [few] { $count } aplikacje logowania są już tutaj skonfigurowane.
    [many] { $count } aplikacji logowania jest już tutaj skonfigurowanych.
   *[other] { $count } aplikacji logowania jest już tutaj skonfigurowanych.
}
setup-added-contacts = { $count ->
    [one] Dodano 1 kontakt do książki adresowej.
    [few] Dodano { $count } kontakty do książki adresowej.
    [many] Dodano { $count } kontaktów do książki adresowej.
   *[other] Dodano { $count } kontaktów do książki adresowej.
}
setup-skipped-contacts = { $count ->
    [one] 1 kontakt jest już w książce adresowej.
    [few] { $count } kontakty są już w książce adresowej.
    [many] { $count } kontaktów jest już w książce adresowej.
   *[other] { $count } kontaktów jest już w książce adresowej.
}
setup-added-groups = { $count ->
    [one] Dodano lub uzupełniono 1 grupę.
    [few] Dodano lub uzupełniono { $count } grupy.
    [many] Dodano lub uzupełniono { $count } grup.
   *[other] Dodano lub uzupełniono { $count } grup.
}
setup-added-own-keys = { $count ->
    [one] Dodano 1 Twój klucz.
    [few] Dodano { $count } Twoje klucze.
    [many] Dodano { $count } Twoich kluczy.
   *[other] Dodano { $count } Twoich kluczy.
}
setup-added-contact-keys = { $count ->
    [one] Dodano 1 klucz kontaktu.
    [few] Dodano { $count } klucze kontaktów.
    [many] Dodano { $count } kluczy kontaktów.
   *[other] Dodano { $count } kluczy kontaktów.
}
setup-added-rules = { $count ->
    [one] Dodano 1 regułę wiadomości.
    [few] Dodano { $count } reguły wiadomości.
    [many] Dodano { $count } reguł wiadomości.
   *[other] Dodano { $count } reguł wiadomości.
}
setup-skipped-rules = { $count ->
    [one] 1 reguła wiadomości już tu jest.
    [few] { $count } reguły wiadomości już tu są.
    [many] { $count } reguł wiadomości już tu jest.
   *[other] { $count } reguł wiadomości już tu jest.
}
setup-skipped-rules-account = { $count ->
    [one] 1 reguła wiadomości dotyczy konta, którego tu nie ma, więc została pominięta.
    [few] { $count } reguły wiadomości dotyczą kont, których tu nie ma, więc zostały pominięte.
    [many] { $count } reguł wiadomości dotyczy kont, których tu nie ma, więc zostały pominięte.
   *[other] { $count } reguł wiadomości dotyczy kont, których tu nie ma, więc zostały pominięte.
}
setup-rules-waiting = { $count ->
    [one] 1 reguła wiadomości oczekuje na odnalezienie folderu docelowego podczas synchronizacji konta.
    [few] { $count } reguły wiadomości oczekują na odnalezienie folderów docelowych podczas synchronizacji kont.
    [many] { $count } reguł wiadomości oczekuje na odnalezienie folderów docelowych podczas synchronizacji kont.
   *[other] { $count } reguł wiadomości oczekuje na odnalezienie folderów docelowych podczas synchronizacji kont.
}
setup-added-trusted-senders = { $count ->
    [one] Dodano 1 zaufanego nadawcę.
    [few] Dodano { $count } zaufanych nadawców.
    [many] Dodano { $count } zaufanych nadawców.
   *[other] Dodano { $count } zaufanych nadawców.
}
setup-nothing = Nic nie zostało zaimportowane.
setup-account-servers = { $imap } i { $smtp } ({ $signin })
setup-file-name = Ustawienia i konta Inbox Classic
setup-skipped-unreachable = Pominięto: { $name }. Nie udało się sprawdzić konfiguracji usługi logowania. Dodaj ponownie potrzebną aplikację w oknie Aplikacje logowania.
attachment-runs-programs = Plik „{ $name }” może uruchamiać programy, więc Inbox Classic go nie otwiera. Zapisz go, a potem otwórz samodzielnie, jeśli ufasz jego źródłu.
attachment-decrypted-note = Ten załącznik pochodzi z zaszyfrowanej wiadomości. Aby otworzyć go w innym programie, Inbox Classic zapisuje jego niezaszyfrowaną kopię w folderze tymczasowym przeznaczonym dla Ciebie. Przy uruchamianiu programu program próbuje usunąć kopie starsze niż jeden dzień.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Serwer nie przeniósł wiadomości do folderu { $folder }, więc { $messages } jest znowu w folderze { $from }: { $reason }
    [few] Serwer nie przeniósł wiadomości do folderu { $folder }, więc { $messages } są znowu w folderze { $from }: { $reason }
    [many] Serwer nie przeniósł wiadomości do folderu { $folder }, więc { $messages } jest znowu w folderze { $from }: { $reason }
   *[other] Serwer nie przeniósł wiadomości do folderu { $folder }, więc { $messages } jest znowu w folderze { $from }: { $reason }
}
undone-delete = { $count ->
    [one] Serwer nie usunął wiadomości, więc { $messages } jest znowu w folderze { $from }: { $reason }
    [few] Serwer nie usunął wiadomości, więc { $messages } są znowu w folderze { $from }: { $reason }
    [many] Serwer nie usunął wiadomości, więc { $messages } jest znowu w folderze { $from }: { $reason }
   *[other] Serwer nie usunął wiadomości, więc { $messages } jest znowu w folderze { $from }: { $reason }
}
undone-archive = { $count ->
    [one] Serwer nie zarchiwizował wiadomości, więc { $messages } jest znowu w folderze { $from }: { $reason }
    [few] Serwer nie zarchiwizował wiadomości, więc { $messages } są znowu w folderze { $from }: { $reason }
    [many] Serwer nie zarchiwizował wiadomości, więc { $messages } jest znowu w folderze { $from }: { $reason }
   *[other] Serwer nie zarchiwizował wiadomości, więc { $messages } jest znowu w folderze { $from }: { $reason }
}
undone-read = { $count ->
    [one] Serwer nie oznaczył wiadomości jako przeczytanej, więc { $messages } jest znowu nieprzeczytana: { $reason }
    [few] Serwer nie oznaczył wiadomości jako przeczytanych, więc { $messages } są znowu nieprzeczytane: { $reason }
    [many] Serwer nie oznaczył wiadomości jako przeczytanych, więc { $messages } jest znowu nieprzeczytanych: { $reason }
   *[other] Serwer nie oznaczył wiadomości jako przeczytanych, więc { $messages } jest znowu nieprzeczytanych: { $reason }
}
undone-unread = { $count ->
    [one] Serwer nie oznaczył wiadomości jako nieprzeczytanej, więc { $messages } jest znowu przeczytana: { $reason }
    [few] Serwer nie oznaczył wiadomości jako nieprzeczytanych, więc { $messages } są znowu przeczytane: { $reason }
    [many] Serwer nie oznaczył wiadomości jako nieprzeczytanych, więc { $messages } jest znowu przeczytanych: { $reason }
   *[other] Serwer nie oznaczył wiadomości jako nieprzeczytanych, więc { $messages } jest znowu przeczytanych: { $reason }
}
undone-flags = { $count ->
    [one] Serwer nie zmienił flag wiadomości, więc cofnięto tę zmianę ({ $messages }): { $reason }
    [few] Serwer nie zmienił flag wiadomości, więc cofnięto tę zmianę ({ $messages }): { $reason }
    [many] Serwer nie zmienił flag wiadomości, więc cofnięto tę zmianę ({ $messages }): { $reason }
   *[other] Serwer nie zmienił flag wiadomości, więc cofnięto tę zmianę ({ $messages }): { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

preview-pdf-option = Pokazuj pliki PDF w wiadomościach
preview-pdf-off = Pliki PDF nie są pokazywane w wiadomościach.
preview-pdf-off-crashed = Inbox Classic zamknął się podczas wyświetlania pliku. Podgląd plików PDF został wyłączony. Obrazy są nadal wyświetlane. Aby ponownie włączyć podgląd PDF, zaznacz opcję „{ $option }” w { $settings }.
preview-pdf-details = { $count ->
    [one] 1 strona, { $size }
    [few] { $count } strony, { $size }
    [many] { $count } stron, { $size }
   *[other] { $count } stron, { $size }
}
preview-page-alt = { $name }, strona { $page } z { $count }
preview-more-pages = { $count ->
    [one] Otwórz plik, aby zobaczyć stronę
    [few] Otwórz plik, aby zobaczyć wszystkie strony ({ $count })
    [many] Otwórz plik, aby zobaczyć wszystkie strony ({ $count })
   *[other] Otwórz plik, aby zobaczyć wszystkie strony ({ $count })
}
preview-more-files = { $count ->
    [one] Jeszcze 1 plik jest na liście powyżej
    [few] Jeszcze { $count } pliki są na liście powyżej
    [many] Jeszcze { $count } plików jest na liście powyżej
   *[other] Jeszcze { $count } plików jest na liście powyżej
}
preview-tile-downloading = Pobieranie…
preview-tile-preparing = Przygotowywanie…
preview-tile-format = Obrazy { $format } nie są jeszcze pokazywane
preview-tile-password = Plik jest zabezpieczony hasłem. Otwórz go, aby wpisać hasło
preview-tile-too-large = Przekroczono limit rozmiaru podglądów
preview-tile-unreadable = Nie można wyświetlić
preview-tile-timed-out = Przygotowanie podglądu trwało zbyt długo
preview-tile-crashed = Podgląd niedostępny: poprzednia próba wyświetlenia tego pliku nie została zakończona
preview-tile-off = Podgląd wyłączony do ponownego uruchomienia Inbox Classic
preview-not-printed = Plik { $name } ({ $details }) nie jest uwzględniany na wydruku. Otwórz go, aby go wydrukować.

pgp-error-attached-private = Ten załącznik zawiera klucz prywatny. Bezpośrednio z poczty można importować tylko klucze publiczne. Aby przywrócić własny klucz prywatny, zapisz załącznik, a następnie zaimportuj jego plik w oknie Klucze szyfrowania.
pgp-part-find-key = Znajdź klucz
