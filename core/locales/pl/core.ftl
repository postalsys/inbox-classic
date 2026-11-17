# Polski. Wersja robocza, czeka na przegląd przez native speakera (zob. core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] 1 wiadomość
    [few] { $count } wiadomości
    [many] { $count } wiadomości
   *[other] { $count } wiadomości
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] 1 bajt
    [few] { $count } bajty
    [many] { $count } bajtów
   *[other] { $count } bajtów
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Wyłączone
# review: new
send-delay-seconds = { $count ->
    [one] 1 sekunda
    [few] { $count } sekundy
    [many] { $count } sekund
   *[other] { $count } sekund
}
# the status bar: "12 wiadomości, nieprzeczytane: 3"
# review: new
list-counts = { $messages }, nieprzeczytane: { $unread }
# review: new
list-counts-selected = { $messages }, nieprzeczytane: { $unread }, zaznaczone: { $selected }
# review: new
list-counts-found = Znalezione: { $found }, nieprzeczytane: { $unread }
# review: new
list-counts-found-selected = Znalezione: { $found }, nieprzeczytane: { $unread }, zaznaczone: { $selected }
# review: new
list-counts-none = Nie znaleziono wiadomości

## Special folders, as Outlook names them

# review: new
folder-inbox = Skrzynka odbiorcza
# review: new
folder-sent = Elementy wysłane
# review: new
folder-deleted = Elementy usunięte
# review: new
folder-drafts = Wersje robocze
# review: new
folder-junk = Wiadomości-śmieci
# review: new
folder-archive = Archiwum

## The reading pane

# review: new
reader-no-message = Nie zaznaczono żadnej wiadomości.
# review: new
reader-downloading = Pobieranie wiadomości…
# review: new
reader-downloading-detail = Wiadomość pojawi się tutaj po zakończeniu pobierania.
# review: new
reader-downloading-size = Wiadomość ma { $size }. Pojawi się tutaj po pobraniu.
# review: new
reader-failed = Nie udało się pobrać wiadomości
# review: new
reader-failed-network = Nie można połączyć się z serwerem poczty ({ $reason }).
# review: new
reader-failed-sign-in = Serwer poczty nie zaakceptował logowania ({ $reason }). Sprawdź hasło lub zaloguj się ponownie w menu Plik > Konta.
# review: new
reader-failed-security = Nie udało się zabezpieczyć połączenia z serwerem poczty ({ $reason }).
# review: new
reader-failed-other = Serwer poczty odpowiedział: { $reason }.
# review: new
reader-retry-note = Kolejna próba nastąpi po ponownym połączeniu konta.
# review: new
reader-unreadable = Nie można wyświetlić tej wiadomości: { $error }
# review: new
message-source-title = Źródło wiadomości: { $subject }
# review: new
message-source-untitled = Źródło wiadomości

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Od
# review: new
header-date = Data
# review: new
header-to = Do
# review: new
header-cc = DW
# review: new
header-sent = Wysłano
# review: new
header-subject = Temat
# review: new
header-security = Zabezpieczenia
# review: new
header-part = Część { $number }
# review: new
quote-original = ----- Wiadomość oryginalna -----
# review: new
fold-show-earlier = Pokaż wcześniejsze wiadomości

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Twoja wiadomość nie została dostarczona
# review: new
bounce-delayed = Twoja wiadomość nie została jeszcze dostarczona
# review: new
bounce-delayed-note = Twój serwer poczty wciąż próbuje ją dostarczyć. Nie musisz wysyłać jej ponownie.
# review: new
bounce-show-message = Pokaż wiadomość, która wróciła
# review: new
bounce-show-delayed = Pokaż opóźnioną wiadomość
# review: new
bounce-what-to-do = Co możesz zrobić:
# review: new
bounce-delayed-do = Na razie nic. Jeśli nadal nie będzie można jej dostarczyć, otrzymasz kolejne powiadomienie.
# review: new
bounce-delayed-row-do = Na razie nic. Twój serwer poczty wciąż próbuje ją dostarczyć, a jeśli mu się nie uda, otrzymasz kolejne powiadomienie.
# review: new
bounce-details = Szczegóły
# review: new
bounce-someone = Odbiorca
# review: new
bounce-server = Serwer: { $server }
# review: new
bounce-status = Stan: { $status }
# review: new
bounce-reported-by = Zgłoszone przez: { $server }
# review: new
bounce-retry-minutes = Serwer odbiorcy poprosił o odczekanie { $count ->
    [one] minuty
    [few] { $count } minut
    [many] { $count } minut
   *[other] { $count } minut
} przed kolejną próbą.
# review: new
bounce-retry-hours = Serwer odbiorcy poprosił o odczekanie { $count ->
    [one] godziny
    [few] { $count } godzin
    [many] { $count } godzin
   *[other] { $count } godzin
} przed kolejną próbą.
# review: new
bounce-blocklist = Czarna lista: { $lists }
# review: new
bounce-user-unknown = Adres nie istnieje
# review: new
bounce-user-unknown-why = Serwer odbiorcy nie ma skrzynki o tym adresie. Adres może zawierać literówkę albo osoba już z niego nie korzysta.
# review: new
bounce-user-unknown-do = Sprawdź pisownię adresu albo zapytaj tę osobę, jakiego adresu teraz używa.
# review: new
bounce-invalid-address = Adres jest nieprawidłowy
# review: new
bounce-invalid-address-why = Adres nie ma postaci, na którą można wysłać pocztę.
# review: new
bounce-invalid-address-do = Poszukaj literówek, na przykład spacji, brakującej litery albo braku czegokolwiek po znaku @.
# review: new
bounce-mailbox-disabled = Skrzynka jest zamknięta
# review: new
bounce-mailbox-disabled-why = Adres istnieje, ale jego skrzynka została wyłączona albo nie jest już używana.
# review: new
bounce-mailbox-disabled-do = Skontaktuj się z tą osobą w inny sposób i zapytaj o adres, którego teraz używa.
# review: new
bounce-mailbox-full = Skrzynka jest pełna
# review: new
bounce-mailbox-full-why = W skrzynce odbiorcy nie ma miejsca na nową pocztę.
# review: new
bounce-mailbox-full-do = Wyślij ją ponownie za kilka dni albo daj znać tej osobie w inny sposób. Duże załączniki są odrzucane w pierwszej kolejności.
# review: new
bounce-spam-blocked = Odrzucona jako spam
# review: new
bounce-spam-blocked-why = Serwer odbiorcy uznał wiadomość za spam.
# review: new
bounce-spam-blocked-do = Wyślij ją ponownie bez tego, co wygląda na spam, na przykład wielu linków, skróconych linków czy dużego załącznika. Jeśli to się powtarza, zapytaj swojego dostawcę poczty.
# review: new
bounce-virus-detected = Odrzucona z powodu wirusa
# review: new
bounce-virus-detected-why = Serwer odbiorcy znalazł wirusa lub inną szkodliwą zawartość w wiadomości albo w jej załącznikach.
# review: new
bounce-virus-detected-do = Sprawdź załączniki programem antywirusowym. Niektóre serwery odrzucają wszystkie programy i archiwa, więc takie pliki udostępnij jako link.
# review: new
bounce-ip-blocklisted = Twój serwer poczty jest na czarnej liście
# review: new
bounce-ip-blocklisted-why = Serwer odbiorcy odrzuca pocztę z serwera, który wysłał Twoją wiadomość, bo adres tego serwera jest na czarnej liście.
# review: new
bounce-ip-blocklisted-do = Problem nie leży w wiadomości. Prześlij to powiadomienie swojemu dostawcy poczty i poproś o usunięcie serwera z listy.
# review: new
bounce-domain-blocklisted = Domena jest na czarnej liście
# review: new
bounce-domain-blocklisted-why = Serwer odbiorcy odrzuca wiadomość, bo domena Twojego adresu albo domena z linków w wiadomości jest na czarnej liście.
# review: new
bounce-domain-blocklisted-do = Jeśli wiadomość zawiera linki, spróbuj bez nich. W przeciwnym razie prześlij to powiadomienie osobie, która obsługuje pocztę Twojej domeny.
# review: new
bounce-policy-blocked = Odrzucona przez reguły serwera odbiorcy
# review: new
bounce-policy-blocked-why = Reguły serwera odbiorcy nie przepuszczają tej wiadomości, na przykład z powodu jej rozmiaru, załączników albo nadawcy.
# review: new
bounce-policy-blocked-do = Słowa samego serwera w sekcji Szczegóły często podają przyczynę. Zapytaj odbiorcę, czy może przyjmować taką pocztę.
# review: new
bounce-geo-blocked = Odrzucona ze względu na pochodzenie
# review: new
bounce-geo-blocked-why = Serwer odbiorcy nie przyjmuje poczty z kraju ani sieci, w której jest Twój serwer poczty.
# review: new
bounce-geo-blocked-do = Skontaktuj się z tą osobą w inny sposób albo zapytaj o to swojego dostawcę poczty.
# review: new
bounce-relay-denied = Serwer nie przekazał jej dalej
# review: new
bounce-relay-denied-why = Serwer odmówił przekazania wiadomości dalej, często dlatego, że wysłano ją bez logowania albo przez serwer, który nie obsługuje tego odbiorcy.
# review: new
bounce-relay-denied-do = Sprawdź serwer poczty wychodzącej konta w menu Plik > Konta oraz to, czy się na nim loguje.
# review: new
bounce-auth-failure = Nie udało się zweryfikować Twojego adresu nadawcy
# review: new
bounce-auth-failure-why = Serwer odbiorcy nie mógł potwierdzić, że wiadomość naprawdę pochodzi z Twojej domeny (SPF, DKIM lub DMARC).
# review: new
bounce-auth-failure-do = Prześlij to powiadomienie osobie, która obsługuje pocztę Twojej domeny: jej ustawienia trzeba poprawić. Do tego czasu może pomóc wysyłanie przez serwer Twojego dostawcy.
# review: new
bounce-rate-limited = Za dużo poczty naraz
# review: new
bounce-rate-limited-why = Serwer odbiorcy przyjmuje na razie mniej wiadomości z Twojego serwera poczty.
# review: new
bounce-rate-limited-do = Odczekaj chwilę i wyślij ją ponownie. Pisząc do wielu osób, wysyłaj do mniejszej liczby naraz.
# review: new
bounce-greylisting = Wstrzymana na chwilę
# review: new
bounce-greylisting-why = Serwer odbiorcy prosi nieznanych nadawców o ponowną próbę nieco później. To częsty sposób ochrony przed spamem.
# review: new
bounce-greylisting-do = Nic. Serwery poczty same próbują ponownie i wiadomość zwykle dociera w ciągu godziny.
# review: new
bounce-server-error = Serwer odbiorcy miał problem
# review: new
bounce-server-error-why = Nie można było połączyć się z serwerem odbiorcy albo nie mógł on przyjąć wiadomości z powodu własnego problemu.
# review: new
bounce-server-error-do = Wyślij ją ponownie później. Jeśli nadal się nie uda, sprawdź, czy w części adresu po znaku @ nie ma literówek.
# review: new
bounce-unknown = Nie dostarczono
# review: new
bounce-unknown-why = Powiadomienie nie mówi jasno, dlaczego.
# review: new
bounce-unknown-do = Słowa samego serwera w sekcji Szczegóły mogą powiedzieć więcej. Jeśli nie pomogą, prześlij to powiadomienie swojemu dostawcy poczty.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] Zaznaczono 1 wiadomość
    [few] Zaznaczono { $count } wiadomości
    [many] Zaznaczono { $count } wiadomości
   *[other] Zaznaczono { $count } wiadomości
}
# review: new
selection-unread = Nieprzeczytane: { $count }
# review: new
selection-flagged = Z flagą: { $count }
# review: new
delete-for-good-one = Ta wiadomość zostanie trwale usunięta. Usunąć ją?
# review: new
delete-for-good-all = Te wiadomości ({ $count }) zostaną trwale usunięte. Usunąć je?
# review: new
delete-for-good-some = { $count ->
    [one] { $count } z { $total } wiadomości zostanie trwale usunięta. Usunąć wiadomości?
    [few] { $count } z { $total } wiadomości zostaną trwale usunięte. Usunąć wiadomości?
    [many] { $count } z { $total } wiadomości zostanie trwale usuniętych. Usunąć wiadomości?
   *[other] { $count } z { $total } wiadomości zostanie trwale usuniętych. Usunąć wiadomości?
}
# review: new
done-read = { $count ->
   *[other] Oznaczono jako przeczytane: { $messages }
}
# review: new
done-unread = { $count ->
   *[other] Oznaczono jako nieprzeczytane: { $messages }
}
# review: new
done-flagged = { $count ->
   *[other] Oznaczono flagą: { $messages }
}
# review: new
done-unflagged = Usunięto flagę: { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Trwale usunięto: { $messages }
}
# review: new
done-archived = { $count ->
   *[other] Zarchiwizowano: { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Przeniesiono { $messages } (cel: { $folder })
}
# review: new
done-copied = { $count ->
   *[other] Skopiowano { $messages } (cel: { $folder })
}
# review: new
done-moving = { $count ->
   *[other] Przenoszenie: { $messages } (cel: { $folder })...
}
# review: new
done-copying = { $count ->
   *[other] Kopiowanie: { $messages } (cel: { $folder })...
}
# review: new
done-moved-back = { $count ->
   *[other] Przeniesiono z powrotem { $messages } (cel: { $folder })
}
# review: new
done-watched = { $count ->
    [one] Obserwujesz konwersację
    [few] Obserwujesz { $count } konwersacje
    [many] Obserwujesz { $count } konwersacji
   *[other] Obserwujesz { $count } konwersacji
}
# review: new
done-unwatched = { $count ->
    [one] Przestano obserwować konwersację
    [few] Przestano obserwować { $count } konwersacje
    [many] Przestano obserwować { $count } konwersacji
   *[other] Przestano obserwować { $count } konwersacji
}
# review: new
done-ignored = { $count ->
    [one] Ignorujesz konwersację
    [few] Ignorujesz { $count } konwersacje
    [many] Ignorujesz { $count } konwersacji
   *[other] Ignorujesz { $count } konwersacji
}
# review: new
done-unignored = { $count ->
    [one] Przestano ignorować konwersację
    [few] Przestano ignorować { $count } konwersacje
    [many] Przestano ignorować { $count } konwersacji
   *[other] Przestano ignorować { $count } konwersacji
}
# review: new
their-folders = ich pierwotne foldery
# review: new
undo-move = Cofnij przeniesienie
# review: new
undo-delete = Cofnij usunięcie
# review: new
undo-archive = Cofnij archiwizację
# review: new
undo-junk = Cofnij oznaczenie jako śmieci
# review: new
undo-not-junk = Cofnij oznaczenie jako nie śmieci
# review: new
undo-send = Cofnij wysłanie
# review: new
nothing-to-undo = Nie ma nic do cofnięcia.
# review: new
messages-gone = Tych wiadomości już nie ma.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Ten folder nie może zawierać wiadomości.
# review: new
not-archived-here = Wiadomości z tego folderu nie mogą być archiwizowane.
# review: new
not-emptied-here = Opróżnić można tylko foldery Elementy usunięte i Wiadomości-śmieci.
# review: new
next-unread-question = W folderze { $folder } nie ma więcej nieprzeczytanych wiadomości.

    Przejść do folderu { $next }, następnego z nieprzeczytanymi wiadomościami?
# review: new
no-unread-left = Nie ma już nieprzeczytanych wiadomości.
# review: new
empty-question = { $count ->
    [one] Opróżnić folder { $folder }?

        Znajdująca się w nim wiadomość zostanie trwale usunięta. Nie będzie można jej przywrócić.
   *[other] Opróżnić folder { $folder }?

        Znajdujące się w nim wiadomości ({ $messages }) zostaną trwale usunięte. Nie będzie można ich przywrócić.
}
# review: new
no-junk-folder = To konto nie ma folderu Wiadomości-śmieci, do którego można przenieść wiadomości.
# review: new
no-inbox-folder = To konto nie ma folderu Skrzynka odbiorcza, do którego można przenieść wiadomości.
# the status bar after a flag in a colour: "Oznaczono 2 wiadomości flagą niebieską"
# review: new
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
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Przenieś wiadomość
    [few] Przenieś { $count } wiadomości
    [many] Przenieś { $count } wiadomości
   *[other] Przenieś { $count } wiadomości
}
# review: new
move-window-title-copy = { $count ->
    [one] Kopiuj wiadomość
    [few] Kopiuj { $count } wiadomości
    [many] Kopiuj { $count } wiadomości
   *[other] Kopiuj { $count } wiadomości
}
# review: new
move-window-prompt-move = { $count ->
    [one] Przenieś zaznaczoną wiadomość do:
    [few] Przenieś { $count } zaznaczone wiadomości do:
    [many] Przenieś { $count } zaznaczonych wiadomości do:
   *[other] Przenieś { $count } zaznaczonych wiadomości do:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Kopiuj zaznaczoną wiadomość do:
    [few] Kopiuj { $count } zaznaczone wiadomości do:
    [many] Kopiuj { $count } zaznaczonych wiadomości do:
   *[other] Kopiuj { $count } zaznaczonych wiadomości do:
}
# review: new
targets-recent = Ostatnio używane
# review: new
target-current = { $folder } (bieżący)
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Przenoszenie: { $done } z { $messages } (cel: { $folder })...
# review: new
transfer-copying = Kopiowanie: { $done } z { $messages } (cel: { $folder })...
# review: new
transfer-another-account = inne konto
# review: new
transfer-folder-gone = folder docelowy już nie istnieje
# review: new
transfer-not-on-server = wiadomości nie ma już na serwerze
# review: new
transfer-not-moved = { $count ->
   *[other] Nie udało się przenieść na inne konto ({ $messages }): { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] Nie udało się skopiować na inne konto ({ $messages }): { $reason }
}
# review: new
transfer-none-moved = Nie udało się przenieść żadnej wiadomości
# review: new
transfer-none-copied = Nie udało się skopiować żadnej wiadomości

## Messages as files

# review: new
export-not-in-time = nie udało się pobrać wiadomości na czas
# review: new
export-not-saved = Nie udało się zapisać { $failed } z { $messages } ({ $problems })
# review: new
export-not-attached = nie udało się załączyć wiadomości: { $error }
# the status bar after Save As with several: "Zapisano 3 wiadomości w folderze Pulpit"
# review: new
saved-to = { $count ->
   *[other] Zapisano { $messages } w folderze { $folder }
}
# review: new
download-progress = Pobieranie: { $done } z { $total }
# review: new
download-done = Pobrano { $size }
# review: new
downloading-messages = { $count ->
   *[other] Pobieranie: { $messages }...
}
# the status bar after files are dropped on a folder: "Umieszczono 3 wiadomości w folderze Archiwum"
# review: new
import-put = { $count ->
   *[other] Umieszczono { $messages } w folderze { $folder }
}
# review: new
import-not-put = Tych plików nie umieszczono w folderze:

    { $problems }

## Problems the windows show

# review: new
error-store = lokalny magazyn: { $error }
# review: new
error-not-found = nie znaleziono
# review: new
error-closed = trwa zamykanie
# review: new
error-other-account = przeglądarka zalogowała się na konto { $email }, a nie na to konto
# review: new
failure-authentication = serwer nie zaakceptował logowania ({ $reason })
# review: new
failure-network = połączenie z serwerem nie powiodło się ({ $reason })
# review: new
error-in-use = nie można jej usunąć, dopóki logują się przez nią konta: { $accounts }
# review: new
error-turned-off = ta aplikacja logowania jest wyłączona dla nowych kont
# review: new
error-folder-name = nazwa folderu musi mieć od 1 do 200 znaków i nie może zawierać znaków sterujących
# review: new
error-folder-separator = na tym serwerze nazwa folderu nie może zawierać znaku „{ $separator }”
# review: new
error-folder-special = nie można zmienić nazwy ani usunąć Skrzynki odbiorczej i folderów specjalnych
# review: new
error-no-recipients = wiadomość nie ma odbiorców
# review: new
error-bad-address = „{ $address }” nie jest adresem e-mail
# review: new
error-not-own-address = { $address } nie jest jednym z adresów nadawcy tego konta. Dodaj go w polu „Inne adresy, z których wysyłasz” we właściwościach konta.
# review: new
rule-query-refused = Reguły nie mogą filtrować według folderu ani daty ({ $words }).
# review: new
rule-no-query = Wpisz kryteria wyszukiwania dla wiadomości przychodzących.
# review: new
rule-no-action = Wybierz co najmniej jedną akcję dla reguły.
# review: new
error-attachment = Nie można odczytać pliku { $path }: { $error }
# review: new
error-no-drafts = konto nie ma folderu Wersje robocze, w którym można zapisać wiadomość
# review: new
error-draft-attachment = nie udało się zachować załącznika wersji roboczej: { $error }
# review: new
error-password-not-saved = nie udało się zapisać hasła na następne uruchomienie: { $error }
# review: new
error-sign-in-not-saved = nie udało się zapisać nowych danych logowania na następne uruchomienie: { $error }
# review: new
error-import-unreadable = nie można odczytać pliku { $path }: { $error }
# review: new
error-import-too-large = plik { $path } jest większy niż 50 MB
# review: new
error-import-not-mail = plik { $path } nie jest wiadomością e-mail
# review: new
error-list-answered = serwer listy mailingowej zwrócił stan { $status }
# review: new
error-not-built = nie udało się utworzyć wiadomości
# review: new
error-outbox-waits = { $count ->
    [one] wiadomość czeka w Skrzynce nadawczej i zostanie wysłana przy następnym wysyłaniu/odbieraniu
    [few] { $count } wiadomości czekają w Skrzynce nadawczej i zostaną wysłane przy następnym wysyłaniu/odbieraniu
    [many] { $count } wiadomości czeka w Skrzynce nadawczej i zostanie wysłanych przy następnym wysyłaniu/odbieraniu
   *[other] { $count } wiadomości czeka w Skrzynce nadawczej i zostanie wysłanych przy następnym wysyłaniu/odbieraniu
}
# review: new
error-draft-not-removed = nie udało się usunąć wcześniejszej wersji roboczej wiadomości z folderu Wersje robocze: { $reason }
# review: new
error-sent-but = wiadomość została wysłana, ale { $problem }
# review: new
error-sent-still-in-outbox = nadal jest w Skrzynce nadawczej: { $error }
# review: new
error-sent-no-copy = nie udało się zapisać kopii w folderze Elementy wysłane: { $reason }
# review: new
error-no-password = brak hasła dla tego konta
# review: new
error-no-sign-in = brak danych logowania dla tego konta
# review: new
error-provider-missing = ta wersja nie może logować się do usługi { $provider }: czy jej aplikacja logowania została usunięta?
# review: new
error-provider-servers = serwery tego konta nie zgadzają się z serwerami jego aplikacji logowania
# review: new
error-app-scopes = { $reason }. Serwer poczty nie przyjął tokenu aplikacji logowania: sprawdź, czy zakresy aplikacji dają dostęp do poczty
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google nie zweryfikował jeszcze Inbox Classic, więc pozwala logować się przez nią tylko użytkownikom testowym. Użyj własnej aplikacji logowania Google lub hasła aplikacji albo, jeśli jesteś użytkownikiem testowym, włącz ją w oknie Aplikacje logowania (Plik > Konta).
# review: new
sign-in-off-other = Została wyłączona w oknie Aplikacje logowania (Plik > Konta), gdzie można ją ponownie włączyć.
# review: new
sign-in-app-no-name = aplikacja logowania musi mieć nazwę
# review: new
sign-in-app-no-client = brak identyfikatora klienta
# review: new
sign-in-app-no-scopes = aplikacja logowania potrzebuje zakresów, które dają dostęp do poczty
# review: new
sign-in-app-bad-host = brak adresu serwera { $server } lub nie jest to prawidłowa nazwa hosta
# review: new
sign-in-app-plain = serwer { $server } musi używać SSL/TLS lub STARTTLS
# review: new
sign-in-app-not-checked = wystawca nie został jeszcze sprawdzony
# review: new
sign-in-app-issuer-changed = wystawca się zmienił: wpisz ponownie klucz tajny klienta albo go usuń
# review: new
sign-in-register-google = W Google Cloud Console utwórz klienta OAuth typu Aplikacja komputerowa, z zakresem https://mail.google.com/ na ekranie zgody. Dopóki aplikacja jest w fazie testów, logować się mogą tylko jej użytkownicy testowi.
# review: new
sign-in-register-microsoft = W Microsoft Entra zarejestruj aplikację z platformą Aplikacje mobilne i klasyczne, identyfikatorem URI przekierowania http://localhost, dozwolonymi przepływami klienta publicznego oraz uprawnieniami delegowanymi IMAP.AccessAsUser.All, SMTP.Send i offline_access. Tylko dla swojej organizacji użyj jako wystawcy https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Zarejestruj natywnego (publicznego) klienta z poniższym identyfikatorem URI przekierowania; dostawca musi zezwalać na dowolny port (RFC 8252). Dodaj zakres, którym dostawca daje dostęp do poczty.

## Calendar invitations

# review: new
repeats = Powtarza się
# review: new
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
# review: new
repeats-on = { $repeats }, w dni: { $days }
# "Co tydzień, 10 razy"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, jeden raz
    [few] { $repeats }, { $count } razy
    [many] { $repeats }, { $count } razy
   *[other] { $repeats }, { $count } razy
}
# review: new
day-monday = poniedziałek
# review: new
day-tuesday = wtorek
# review: new
day-wednesday = środa
# review: new
day-thursday = czwartek
# review: new
day-friday = piątek
# review: new
day-saturday = sobota
# review: new
day-sunday = niedziela

## AI agents

# review: new
agent-level-read = Czytanie poczty: foldery, lista wiadomości, wyszukiwanie i wiadomości
# review: new
agent-level-organize = Porządkowanie poczty: stan przeczytania, flagi, śmieci, przenoszenie, usuwanie do Elementów usuniętych
# review: new
agent-level-drafts = Pisanie wersji roboczych do wysłania przez Ciebie
# review: new
agent-level-send = Wysyłanie poczty, każdej wiadomości dopiero po Twojej zgodzie
# review: new
agent-connect-title = { $program } chce korzystać z Twojej poczty
# review: new
agent-connect-detail = Agent AI poprosił o możliwość pracy z Inbox Classic. Wybierz, co może robić i które konta może widzieć; możesz to później zmienić w menu Narzędzia > Agenci AI.

    Agenci czytają pocztę napisaną przez innych ludzi, a wiadomość może próbować ich oszukać. Inbox Classic zawsze pyta Cię, zanim agent cokolwiek wyśle.
# review: new
agent-reply-to = Odpowiedź na „{ $subject }”
# review: new
agent-reply-all-on = Odpowiedź do wszystkich na „{ $subject }”
# review: new
agent-forward-of = Przekazanie „{ $subject }”
# review: new
agent-never-written-one = Nie wysłano jeszcze żadnej wiadomości do { $address }.
# review: new
agent-never-written-many = Do części tych adresów (liczba: { $count }) nie wysłano jeszcze żadnej wiadomości.
# review: new
agent-send-title = { $program } chce wysłać tę wiadomość
# review: new
agent-send-detail = Sprawdź odbiorców i treść wiadomości. Po potwierdzeniu wiadomość czeka w Skrzynce nadawczej { $seconds } s i nadal możesz ją tam usunąć.
# review: new
agent-change-title = Co może robić { $program }
# review: new
agent-change-allowed = Zmień, co agenci AI tego programu mogą robić z Twoją pocztą.
# review: new
agent-change-refused = Odmówiono temu programowi dostępu. Zezwól, aby jego agenci ponownie mieli dostęp do Twojej poczty.
# review: new
agent-log-taken-back = { $entry } (cofnięte)
# review: new
agent-files = Pliki: { $files }
# review: new
agent-undo-refused = Tego nie można cofnąć.
# review: new
agent-undo-refused-why = Tego nie można cofnąć: { $reason }.
# review: new
agent-undo-impossible = tego nie można cofnąć
# review: new
agent-undo-not-in-folder = wiadomości nie ma już w tym folderze
# review: new
agent-undo-not-arrived = wiadomości nie ma (jeszcze) w folderze, do którego trafiła
# review: new
agent-undo-sent = wiadomość została już wysłana
# review: new
agent-original-not-downloaded = oryginalna wiadomość nie została jeszcze pobrana. Najpierw ją otwórz
# review: new
agent-turned-away = Odrzucony
# review: new
agent-can-nothing = Nic
# review: new
agent-can-read = czytanie
# review: new
agent-can-organize = porządkowanie
# review: new
agent-can-drafts = pisanie wersji roboczych
# review: new
agent-can-send = wysyłanie za Twoją zgodą
# "czytanie, porządkowanie i pisanie wersji roboczych"
# review: new
agent-can-list = { $first } i { $last }
# review: new
agent-accounts = { $count ->
    [0] brak kont
    [one] 1 konto
    [few] { $count } konta
    [many] { $count } kont
   *[other] { $count } kont
}
# "czytanie i porządkowanie; 1 konto"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Nie można odczytać tej wiadomości.
# review: new
agent-encrypted-original = Ta wiadomość jest zaszyfrowana: agent nie może na nią odpowiedzieć ani jej przekazać, bo nie potrafi szyfrować.
# review: new
agent-log-composed = Otwarto „{ $subject }” w nowej wiadomości do dokończenia przez Ciebie
# review: new
agent-log-refused = Nie wysłano „{ $subject }”
# review: new
agent-log-sent = Wysłano „{ $subject }” do { $to }
# review: new
agent-log-draft = Zapisano wersję roboczą „{ $subject }”
# review: new
agent-log-read = Oznaczono jako przeczytaną „{ $subject }”
# review: new
agent-log-unread = Oznaczono jako nieprzeczytaną „{ $subject }”
# review: new
agent-log-flagged = Oznaczono flagą „{ $subject }”
# review: new
agent-log-unflagged = Usunięto flagę z „{ $subject }”
# review: new
agent-log-deleted = Usunięto „{ $subject }”
# review: new
agent-log-moved = Przeniesiono „{ $subject }” (cel: { $folder })
# review: new
agent-log-junk = Oznaczono „{ $subject }” jako śmieci
# review: new
agent-log-not-junk = Oznaczono „{ $subject }” jako nie śmieci
# review: new
agent-log-archived = Zarchiwizowano „{ $subject }”
# review: new
agent-log-folder = Utworzono folder „{ $name }”
# review: new
agent-log-unsubscribed = Wypisano się z listy „{ $subject }”

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = dostawca nie przekazał tokenu odświeżania
# review: new
sign-in-no-account = dostawca nie podał, które konto się zalogowało
# review: new
sign-in-not-finished = logowanie nie zostało ukończone
# review: new
secrets-unavailable = { $store } jest niedostępny
# review: new
secrets-unavailable-why = { $store } jest niedostępny: { $error }
# review: new
secrets-windows = Menedżer poświadczeń
# review: new
secrets-mac = Pęk kluczy
# review: new
secrets-linux = Systemowy pęk kluczy (Secret Service)
# review: new
error-no-such-file = nie ma takiego pliku
# review: new
cards-file-too-big = Ten plik jest za duży, aby był książką adresową.
# review: new
ui-sender-added = Dodano { $name } do Książki adresowej.
# review: new
ui-sender-known = { $name } jest już w Książce adresowej.
# review: new
ui-sender-none = Nadawca tej wiadomości nie ma adresu e-mail, który można dodać.
# review: new
card-name-needed = Kontakt nie ma nazwy ani adresu e-mail.
# a file of Import Address Book that could not be read: "kontakty.vcf: nie ma takiego pliku"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# review: new
otp-heading = Kod od { $domain }
# review: new
otp-copy = Kopiuj
# review: new
otp-note = Wpisz go tylko na stronie { $domain }.
# review: new
otp-old = Ten kod został wysłany ponad godzinę przed otwarciem wiadomości i prawdopodobnie już wygasł.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } uczestnik
        [few] { $count } uczestników
        [many] { $count } uczestników
       *[other] { $count } uczestników
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } to Twój kod do { $domain }

## OpenPGP keys (keys.rs)

# review: new
pgp-key-valid = Ważny
# review: new
pgp-key-expires = Ważny do { $date }
# review: new
pgp-key-expired = Wygasł { $date }
# review: new
pgp-key-revoked = Unieważniony
# review: new
pgp-key-revoked-why = Unieważniony: { $reason }
# review: new
pgp-key-not-valid = Nieważny
# review: new
pgp-key-locked = Nie można go użyć: { $store } nie przechowuje już klucza, który go chroni. Zaimportuj ponownie jego kopię zapasową.
# review: new
pgp-source-own = Utworzony w Inbox Classic
# review: new
pgp-source-file = Zaimportowany z pliku
# review: new
pgp-source-paste = Wklejony
# review: new
pgp-source-attachment = Z wiadomości
# review: new
pgp-source-vcard = Z wizytówki kontaktu
# review: new
pgp-source-wkd = Od dostawcy poczty nadawcy
# review: new
pgp-source-keyserver = Z keys.openpgp.org
# review: new
pgp-source-autocrypt = Z nagłówka Autocrypt wiadomości
# review: new
pgp-error-no-store = Klucze prywatne są chronione przez { $store }, którego nie można użyć: { $error }
# review: new
pgp-error-wrong-passphrase = Fraza hasła jest nieprawidłowa.
# review: new
pgp-error-not-a-key = To nie jest klucz OpenPGP.
# review: new
pgp-error-too-large = Klucz jest za duży.
# review: new
pgp-error-unusable = Klucz używa przestarzałej lub słabej kryptografii i nie można go użyć.
# review: new
pgp-imported-private = { $count ->
    [one] Zaimportowano Twój klucz prywatny.
    [few] Zaimportowano { $count } klucze prywatne.
    [many] Zaimportowano { $count } kluczy prywatnych.
   *[other] Zaimportowano { $count } kluczy prywatnych.
}
# review: new
pgp-imported-public = { $count ->
    [one] Zaimportowano jeden klucz.
    [few] Zaimportowano { $count } klucze.
    [many] Zaimportowano { $count } kluczy.
   *[other] Zaimportowano { $count } kluczy.
}
# review: new
pgp-imported-pending = Dla { $addresses } używany jest już inny klucz: nowy czeka w kontakcie, dopóki go nie wybierzesz.
# review: new
pgp-error-needs-passphrase = Klucz prywatny jest chroniony frazą hasła. Wpisz ją, aby zaimportować klucz.
# review: new
pgp-error-mismatch = Klucz prywatny nie pasuje do swojego klucza publicznego. Mógł zostać zmieniony.
# review: new
pgp-file-name-public = { $who } klucz publiczny.asc
# review: new
pgp-file-name-private = { $who } kopia zapasowa klucza prywatnego.asc
# review: new
pgp-pending = { $date } znaleziono inny klucz dla { $address }.

## Reading signed and encrypted mail (protect.rs)

# review: new
pgp-part-verified = Podpisane przez { $signer }, klucz zweryfikowany
# review: new
pgp-part-signed = Podpisane przez { $signer } (klucz niezweryfikowany)
# review: new
pgp-part-other = Podpisane przez { $signer }, a nie przez nadawcę
# review: new
pgp-part-unknown-key = Podpisane, ale klucz jest nieznany
# review: new
pgp-part-not-signed = Niepodpisane
# review: new
pgp-part-not-checked = Podpis niesprawdzony
# review: new
pgp-part-encrypted = Zaszyfrowane. { $signature }
# review: new
pgp-part-no-key = Zaszyfrowane kluczem, którego nie masz
# review: new
pgp-part-changed = Zaszyfrowana część została zmieniona po drodze i nie jest wyświetlana
# review: new
pgp-part-unprotected = Zaszyfrowane bez ochrony przed zmianami, nie jest wyświetlane
# review: new
pgp-part-broken = Nie można odczytać zaszyfrowanej części
# review: new
pgp-why-mismatch = Podpis nie pasuje do tego tekstu
# review: new
pgp-why-weak-hash = Podpis używa algorytmu { $hash }, który nie jest już bezpieczny
# review: new
pgp-why-key-expired = Podpisane po wygaśnięciu klucza { $date }
# review: new
pgp-why-key-revoked = Podpisane kluczem, który został unieważniony
# review: new
pgp-why-not-signing-key = Podpisane kluczem, który nie może podpisywać
# review: new
pgp-why-from-future = Podpis ma datę z przyszłości
# review: new
pgp-why-signature-expired = Podpis wygasł
# review: new
pgp-why-key-not-valid = Podpisane nieważnym kluczem
# review: new
pgp-why-not-for-you = Podpisane dla innych odbiorców i przekazane Tobie
# review: new
pgp-part-pictures-loaded = { $label }. Obrazy zostały pobrane z internetu
# review: new
pgp-error-no-own-key = Nie masz klucza dla { $address }, którym można podpisywać lub szyfrować. Utwórz go w menu Narzędzia > Klucze szyfrowania albo wyłącz Podpisz i Szyfruj.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } nie ma klucza, którym można szyfrować.
   *[other] Ci odbiorcy nie mają klucza, którym można szyfrować: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Ta wiadomość cytuje lub przekazuje zaszyfrowaną wiadomość, więc można ją wysłać tylko zaszyfrowaną. Włącz Szyfruj albo usuń cytowany tekst.
# review: new
pgp-error-protect = Nie udało się podpisać ani zaszyfrować wiadomości: { $reason }
# review: new
pgp-found-keys = Znaleziono klucz dla: { $addresses }.
# review: new
pgp-found-none = Nie znaleziono klucza dla: { $addresses }. Poproś o przesłanie klucza publicznego.
# review: new
pgp-found-no-key = Nie znaleziono klucza.
# review: new
pgp-find-unavailable = Nie można teraz wyszukać kluczy: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org wysłał link potwierdzający na adres { $addresses }. Twój klucz zostanie tam opublikowany po jego kliknięciu.
# review: new
pgp-publish-done = Twój klucz jest opublikowany na keys.openpgp.org dla { $addresses }.
# review: new
pgp-publish-failed = Nie udało się opublikować klucza: { $error }
# review: new
pgp-keyserver-off = Wyszukiwanie kluczy na keys.openpgp.org jest wyłączone w Opcjach.
# review: new
pgp-details-part = Część { $number }: { $label }
# review: new
pgp-details-signed = Podpisane { $when } kluczem { $key }
# review: new
pgp-details-unknown-key = Podpisane kluczem { $key }, którego nie masz
# review: new
pgp-details-opened = Zaszyfrowane Twoim kluczem { $key }
# review: new
pgp-details-for = Zaszyfrowane dla: { $keys }
# review: new
pgp-details-plain = Niepodpisane i niezaszyfrowane
# review: new
pgp-bar-parts = Ta wiadomość ma kilka części ({ $count }): { $list }. Każda część pokazuje, jak jest chroniona.
# review: new
pgp-bar-count-verified = zweryfikowane: { $count }
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 podpisana lub zaszyfrowana
    [few] { $count } podpisane lub zaszyfrowane
    [many] { $count } podpisanych lub zaszyfrowanych
   *[other] { $count } podpisanych lub zaszyfrowanych
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 wymaga uwagi
    [few] { $count } wymagają uwagi
    [many] { $count } wymaga uwagi
   *[other] { $count } wymaga uwagi
}
# review: new
pgp-bar-count-neutral = bez potwierdzonego podpisu: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Ustawienia
# review: new
setup-part-preferences = Preferencje okien
# review: new
setup-part-accounts = Konta
# review: new
setup-part-sign-in-apps = Aplikacje logowania
# review: new
setup-part-contacts = Kontakty i grupy
# review: new
setup-part-keys = Klucze szyfrowania
# review: new
setup-part-rules = Reguły wiadomości
# review: new
setup-part-trusted-senders = Zaufani nadawcy
# review: new
setup-holds-settings = { $count ->
    [one] 1 ustawienie
    [few] { $count } ustawienia
    [many] { $count } ustawień
   *[other] { $count } ustawień
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 preferencja
    [few] { $count } preferencje
    [many] { $count } preferencji
   *[other] { $count } preferencji
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 konto
    [few] { $count } konta
    [many] { $count } kont
   *[other] { $count } kont
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 aplikacja logowania
    [few] { $count } aplikacje logowania
    [many] { $count } aplikacji logowania
   *[other] { $count } aplikacji logowania
}
# review: new
setup-holds-built-in = Które wbudowane aplikacje logowania są włączone
# review: new
setup-holds-contacts = { $count ->
    [one] 1 kontakt
    [few] { $count } kontakty
    [many] { $count } kontaktów
   *[other] { $count } kontaktów
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 grupa
    [few] { $count } grupy
    [many] { $count } grup
   *[other] { $count } grup
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 Twój klucz
    [few] { $count } Twoje klucze
    [many] { $count } Twoich kluczy
   *[other] { $count } Twoich kluczy
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 klucz kontaktu
    [few] { $count } klucze kontaktów
    [many] { $count } kluczy kontaktów
   *[other] { $count } kluczy kontaktów
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 reguła
    [few] { $count } reguły
    [many] { $count } reguł
   *[other] { $count } reguł
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 zaufany nadawca
    [few] { $count } zaufanych nadawców
    [many] { $count } zaufanych nadawców
   *[other] { $count } zaufanych nadawców
}
# review: new
setup-sign-in-password = Hasło
# review: new
setup-account-secret-password = Jego hasło jest w pliku.
# review: new
setup-account-secret-token = Jego dane logowania są w pliku.
# review: new
setup-account-asks-password = Po imporcie poprosi o hasło.
# review: new
setup-account-signs-in-again = Po imporcie zalogujesz się do niego ponownie.
# review: new
setup-account-here = Jest już tutaj skonfigurowane, więc zostanie pominięte.
# review: new
setup-account-no-app = Loguje się przez { $app }, której tutaj nie skonfigurowano. Zaimportuj także aplikacje logowania.
# review: new
setup-invalid-address = „{ $address }” nie jest adresem e-mail.
# review: new
setup-invalid-server = Serwer { $server } nie ma użytecznej nazwy ani portu.
# review: new
setup-invalid-user = Nie ma nazwy użytkownika.
# review: new
setup-invalid-sign-in = Loguje się w sposób, którego Inbox Classic nie zna.
# review: new
setup-error-empty = Plik jest pusty.
# review: new
setup-error-too-large = Plik jest za duży, aby był konfiguracją Inbox Classic.
# review: new
setup-error-not-setup = Ten plik nie jest konfiguracją Inbox Classic.
# review: new
setup-error-damaged = Plik konfiguracji jest uszkodzony i nie można go odczytać.
# review: new
setup-error-newer = Tę konfigurację zapisała nowsza wersja Inbox Classic ({ $version }). Zaktualizuj Inbox Classic i zaimportuj ją ponownie.
# review: new
setup-error-needs-passphrase = Ta konfiguracja jest chroniona frazą hasła. Wpisz frazę hasła, z którą ją zapisano.
# review: new
setup-error-wrong-passphrase = To nie jest fraza hasła, z którą zapisano tę konfigurację.
# review: new
setup-error-changed = Plik konfiguracji został zmieniony lub uszkodzony po zapisaniu, więc nie można go zaimportować.
# review: new
setup-error-read = Nie udało się odczytać pliku konfiguracji: { $error }
# review: new
setup-error-write = Nie udało się zapisać konfiguracji: { $error }
# review: new
setup-error-no-parts = Wybierz co najmniej jedną część.
# review: new
setup-left-out = { $count ->
    [one] 1 wpis z części { $part } nie nadaje się do użycia i zostanie pominięty.
    [few] { $count } wpisy z części { $part } nie nadają się do użycia i zostaną pominięte.
    [many] { $count } wpisów z części { $part } nie nadaje się do użycia i zostanie pominiętych.
   *[other] { $count } wpisów z części { $part } nie nadaje się do użycia i zostanie pominiętych.
}
# review: new
setup-imported-settings = Ustawienia zostały zastąpione.
# review: new
setup-imported-preferences = Preferencje okien zostały zastąpione.
# review: new
setup-added-accounts = { $count ->
    [one] Dodano 1 konto.
    [few] Dodano { $count } konta.
    [many] Dodano { $count } kont.
   *[other] Dodano { $count } kont.
}
# review: new
setup-skipped-here = { $address } jest już tutaj skonfigurowane, więc zostało pominięte.
# review: new
setup-skipped-no-app = Pominięto { $address }: loguje się przez { $app }, której tutaj nie skonfigurowano.
# review: new
setup-skipped-invalid = Pominięto { $address }: { $reason }
# review: new
setup-asks-password = { $address } poprosi o hasło przy połączeniu.
# review: new
setup-signs-in-again = { $address } poprosi o ponowne zalogowanie przy połączeniu.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Dodano 1 aplikację logowania.
    [few] Dodano { $count } aplikacje logowania.
    [many] Dodano { $count } aplikacji logowania.
   *[other] Dodano { $count } aplikacji logowania.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 aplikacja logowania jest już tutaj skonfigurowana.
    [few] { $count } aplikacje logowania są już tutaj skonfigurowane.
    [many] { $count } aplikacji logowania jest już tutaj skonfigurowanych.
   *[other] { $count } aplikacji logowania jest już tutaj skonfigurowanych.
}
# review: new
setup-added-contacts = { $count ->
    [one] Dodano 1 kontakt do książki adresowej.
    [few] Dodano { $count } kontakty do książki adresowej.
    [many] Dodano { $count } kontaktów do książki adresowej.
   *[other] Dodano { $count } kontaktów do książki adresowej.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 kontakt jest już w książce adresowej.
    [few] { $count } kontakty są już w książce adresowej.
    [many] { $count } kontaktów jest już w książce adresowej.
   *[other] { $count } kontaktów jest już w książce adresowej.
}
# review: new
setup-added-groups = { $count ->
    [one] Dodano lub uzupełniono 1 grupę.
    [few] Dodano lub uzupełniono { $count } grupy.
    [many] Dodano lub uzupełniono { $count } grup.
   *[other] Dodano lub uzupełniono { $count } grup.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Dodano 1 Twój klucz.
    [few] Dodano { $count } Twoje klucze.
    [many] Dodano { $count } Twoich kluczy.
   *[other] Dodano { $count } Twoich kluczy.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Dodano 1 klucz kontaktu.
    [few] Dodano { $count } klucze kontaktów.
    [many] Dodano { $count } kluczy kontaktów.
   *[other] Dodano { $count } kluczy kontaktów.
}
# review: new
setup-added-rules = { $count ->
    [one] Dodano 1 regułę wiadomości.
    [few] Dodano { $count } reguły wiadomości.
    [many] Dodano { $count } reguł wiadomości.
   *[other] Dodano { $count } reguł wiadomości.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 reguła wiadomości już tu jest.
    [few] { $count } reguły wiadomości już tu są.
    [many] { $count } reguł wiadomości już tu jest.
   *[other] { $count } reguł wiadomości już tu jest.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 reguła wiadomości dotyczy konta, którego tu nie ma, więc została pominięta.
    [few] { $count } reguły wiadomości dotyczą kont, których tu nie ma, więc zostały pominięte.
    [many] { $count } reguł wiadomości dotyczy kont, których tu nie ma, więc zostały pominięte.
   *[other] { $count } reguł wiadomości dotyczy kont, których tu nie ma, więc zostały pominięte.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 reguła wiadomości przenosi wiadomości do folderu, który pojawi się po synchronizacji jego konta.
    [few] { $count } reguły wiadomości przenoszą wiadomości do folderów, które pojawią się po synchronizacji ich kont.
    [many] { $count } reguł wiadomości przenosi wiadomości do folderów, które pojawią się po synchronizacji ich kont.
   *[other] { $count } reguł wiadomości przenosi wiadomości do folderów, które pojawią się po synchronizacji ich kont.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Dodano 1 zaufanego nadawcę.
    [few] Dodano { $count } zaufanych nadawców.
    [many] Dodano { $count } zaufanych nadawców.
   *[other] Dodano { $count } zaufanych nadawców.
}
# review: new
setup-nothing = Nic nie zostało zaimportowane.
# review: new
setup-account-servers = { $imap } i { $smtp } ({ $signin })
# review: new
setup-file-name = Ustawienia i konta Inbox Classic
# review: new
setup-skipped-unreachable = Pominięto { $name }: nie można połączyć się z jego usługą logowania. Dodaj ją ponownie w oknie Aplikacje logowania.
# review: new
attachment-runs-programs = Plik „{ $name }” może uruchamiać programy, więc Inbox Classic go nie otwiera. Zapisz go, a potem otwórz samodzielnie, jeśli ufasz jego źródłu.
# review: new
attachment-decrypted-note = Ten załącznik pochodzi z zaszyfrowanej wiadomości. Aby go otworzyć, Inbox Classic przechowuje go odszyfrowany na tym komputerze, w Twoim folderze, który Inbox Classic opróżnia po jednym dniu.
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
