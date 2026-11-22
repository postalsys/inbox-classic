# Polski. Wersja robocza, czeka na przegląd przez native speakera.

## The menus

menu-file = &Plik
menu-edit = &Edycja
menu-view = &Widok
menu-tools = &Narzędzia
menu-message = Wi&adomość
menu-help = Pomo&c
menu-layout = &Układ
menu-sort-by = &Sortuj według
menu-text-size = &Rozmiar tekstu
menu-folder = &Folder
menu-insert = Ws&taw

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = Nowe &konto...
cmd-exit = &Zakończ
cmd-sync = Wyśl&ij i odbierz na wszystkich kontach
cmd-mark-read = O&znacz jako przeczytane
cmd-mark-unread = Oznacz jako &nieprzeczytane
cmd-pictures = Pobierz &obrazy
cmd-about = &O programie Inbox Classic
cmd-new-mail = &Nowa wiadomość
cmd-reply = Odpowiedz nadawc&y
cmd-reply-all = Odpowiedz w&szystkim
cmd-forward = &Prześlij dalej
cmd-help = &Spis treści
cmd-delete = &Usuń wiadomość
cmd-move = Przenieś do &folderu...
cmd-flag = Oznacz &flagą
cmd-new-folder = &Nowy folder...
cmd-rename-folder = Zmień nazwę &folderu...
cmd-delete-folder = &Usuń folder
cmd-empty-folder = &Opróżnij folder
ui-empty-button = Opróżnij
cmd-accounts = Kon&ta...
cmd-find = Zn&ajdź wiadomość
cmd-save-as = Zapisz &jako...
cmd-print = &Drukuj...
cmd-import = &Importuj wiadomości...
cmd-outbox = Skrzynka &nadawcza...
cmd-properties = &Właściwości
cmd-mark-all-read = Oznacz wszystkie jako prz&eczytane
cmd-junk = Oznacz jako ś&mieci
cmd-not-junk = Usuń oznacz&enie śmieci
cmd-archive = &Archiwizuj
cmd-watch-conversation = O&bserwuj konwersację
cmd-ignore-conversation = &Ignoruj konwersację
cmd-next-message = &Następna wiadomość
cmd-previous-message = &Poprzednia wiadomość
cmd-next-unread = Następna nieprzeczy&tana wiadomość
cmd-go-to-folder = Przejdź &do folderu...
cmd-find-in-message = Znajdź w &tej wiadomości...
ui-go-to-prompt = Przejdź do folderu:
ui-find-in-message-hint = Znajdź w tej wiadomości
ui-find-not-found = W tej wiadomości nie ma „{ $words }”
cmd-expand-all-threads = Rozwiń wszystkie &konwersacje
cmd-collapse-all-threads = &Zwiń wszystkie konwersacje
ui-group-by-conversation = &Grupuj wiadomości według konwersacji
cmd-folder-list = Lista &folderów
cmd-layout-automatic = &Automatyczny
cmd-layout-classic = &Klasyczny
cmd-layout-columns = K&olumny
cmd-sort-date = &Data
cmd-sort-from = &Nadawca
cmd-sort-subject = &Temat
cmd-sort-size = &Rozmiar
cmd-sort-ascending = Sortuj ro&snąco
cmd-sort-descending = Sortuj &malejąco
cmd-text-size-largest = &Największy
cmd-text-size-larger = &Większy
cmd-text-size-medium = Ś&redni
cmd-text-size-smaller = &Mniejszy
cmd-text-size-smallest = Najmn&iejszy
cmd-hide-ignored = Ukryj &ignorowane konwersacje
cmd-hide-read = Ukryj prz&eczytane wiadomości
cmd-notify = &Powiadamiaj o nowej poczcie
cmd-open = &Otwórz Inbox Classic
cmd-default-app = Ustaw jako &domyślny program pocztowy...
cmd-view-source = Źródło &wiadomości
cmd-ai-agents = &Agenci AI...
cmd-options = &Opcje...
cmd-message-rules = &Reguły wiadomości...
cmd-encryption-keys = Klucze &szyfrowania...
cmd-create-rule-from-message = U&twórz regułę z wiadomości...
cmd-unsubscribe = Wypisz się z &listy...
cmd-select-all = Zaznacz &wszystko
cmd-undo = &Cofnij
cmd-copy = &Kopiuj do folderu...
cmd-address-book = &Książka adresowa...
cmd-add-sender-to-book = Dodaj nada&wcę do książki adresowej
cmd-import-address-book = Importuj książkę &adresową...
cmd-export-address-book = &Eksportuj książkę adresową...
cmd-export-setup = Eksportuj u&stawienia i konta...
cmd-import-setup = Im&portuj ustawienia i konta...
cmd-compose-sign = &Podpisz cyfrowo
cmd-compose-encrypt = &Szyfruj
cmd-attach-my-key = Załącz swój klucz &publiczny

## The tray icon's menu

tray-check = &Sprawdź nową pocztę
tray-no-accounts = Nie ma jeszcze kont

## Words the windows of more than one platform share

ui-tb-create-mail = Utwórz wiadomość
ui-tb-reply = Odpowiedz
ui-tb-reply-all = Odpowiedz wszystkim
ui-tb-forward = Prześlij dalej
ui-tb-print = Drukuj
ui-tb-delete = Usuń
ui-tb-junk = Śmieci
ui-tb-not-junk = To nie śmieci
ui-tb-archive = Archiwizuj
ui-tb-previous = Poprzednia
ui-tb-next = Następna
ui-previous-tip = Poprzednia wiadomość
ui-next-tip = Następna wiadomość
ui-tb-sync = Wyślij/Odbierz
ui-tb-mark-read = Przeczytane
ui-tb-mark-unread = Nieprzeczytane
ui-still-running = Inbox Classic nadal działa
ui-no-subject = (bez tematu)
ui-quoted = „{ $subject }”
ui-newest-from = Najnowsza wiadomość: { $subject } (nadawca: { $sender })
ui-new-messages = { $count ->
    [one] { $count } nowa wiadomość
    [few] { $count } nowe wiadomości
    [many] { $count } nowych wiadomości
   *[other] { $count } nowych wiadomości
}
ui-outbox-waiting = { $count ->
    [one] 1 wiadomość w Skrzynce nadawczej
    [few] { $count } wiadomości w Skrzynce nadawczej
    [many] { $count } wiadomości w Skrzynce nadawczej
   *[other] { $count } wiadomości w Skrzynce nadawczej
}
ui-outbox-waits = { $subject } czeka w Skrzynce nadawczej
ui-outbox-sending = Wysyłanie: { $subject }...
ui-from-account = Z konta „{ $account }”
ui-sign-in-refused = Logowanie do konta „{ $account }” zostało odrzucone lub sesja wygasła.
ui-sign-in-again-ask = Zalogować się ponownie w przeglądarce?
ui-sign-in-again-failed = Nie udało się zalogować ponownie: { $reason }
ui-unknown-reason = nieznana przyczyna
ui-checking = Sprawdzanie poczty na koncie „{ $account }”...
ui-done = Gotowe
ui-sent-at = Wysłano { $subject } o { $time }
ui-draft-saved = Wiadomość zapisano w folderze Wersje robocze
ui-draft-not-saved = Wiadomości nie zapisano w folderze Wersje robocze: { $reason }
ui-about-core = Silnik programu: { $version }
ui-add-account-first = Najpierw dodaj konto pocztowe.
ui-add-account-first-link = Najpierw dodaj konto pocztowe, a potem ponownie kliknij link e-mail.
ui-default-app-is = Inbox Classic jest Twoim domyślnym programem pocztowym: linki e-mail otwierają tutaj nową wiadomość.
ui-select-message-first = Najpierw zaznacz wiadomość.
ui-store-not-opened = Nie udało się otworzyć lokalnej bazy poczty.
ui-store-or-cert-not-opened = Nie udało się otworzyć lokalnej bazy poczty lub pliku certyfikatu.
ui-help-title = Pomoc Inbox Classic
ui-help-missing = W tej kopii Inbox Classic brakuje pomocy.
ui-ok = OK
ui-cancel = Anuluj
ui-close = Zamknij
ui-col-subject = Temat
ui-col-from = Nadawca
ui-col-to = Odbiorcy
ui-col-received = Odebrano
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Obserwowana konwersacja
ui-col-sent = Wysłano
ui-col-size = Rozmiar
ui-col-folder = Folder
ui-col-account = Konto
ui-col-queued = W kolejce od
ui-col-status = Stan
ui-outbox-title = Skrzynka nadawcza
ui-outbox-status-waiting = Oczekuje
ui-outbox-status-not-sent = Nie wysłano: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = Agent AI dodał do kolejki; wysyłka najwcześniej o { $time }
ui-outbox-delete-ask = Usunąć tę wiadomość bez wysyłania?
ui-open-link = Otwórz link
ui-edit-link = Edytuj link...
ui-remove-link = Usuń link
ui-insert-attachment = Wstaw załącznik
ui-insert-picture = Wstaw obraz
ui-filter-all = Wszystkie pliki
ui-filter-pictures = Obrazy
ui-filter-messages = Wiadomości e-mail
ui-save-attachment-as = Zapisz załącznik jako
ui-not-sent = Nie udało się wysłać wiadomości.
ui-attachment-forgotten = W wiadomości pojawia się „{ $word }”, ale nie ma załącznika. Wysłać ją mimo to?
ui-send-anyway = Wyślij mimo to
ui-go-back = Wróć
ui-not-saved = Nie udało się zapisać wiadomości.
ui-saving-draft = Zapisywanie w folderze Wersje robocze...
ui-compose-saved-at = Zapisano w folderze Wersje robocze o { $time }
ui-compose-restored = Przywrócono po nieoczekiwanym zamknięciu Inbox Classic
ui-compose-not-saved = Nie zapisano w folderze Wersje robocze: { $reason }
ui-save-changes-ask = Zapisać zmienioną wiadomość w folderze Wersje robocze?
ui-new-message-title = Nowa wiadomość
ui-link-invalid = Wpisz adres strony (https://...) lub link e-mail (mailto:...).
ui-link-address = Adres:
ui-hyperlink = Hiperłącze
ui-hyperlink-intro = Adres, do którego prowadzi zaznaczony tekst.
ui-edit-hyperlink = Edytuj hiperłącze
ui-edit-hyperlink-intro = Adres docelowy linku. Wyczyść adres, aby usunąć link i zachować tekst.
ui-not-a-picture = Nie udało się wstawić obrazu. Wybierz plik PNG, JPEG, GIF lub WebP o rozmiarze nie większym niż 10 MB.
ui-format-color = Kolor czcionki
ui-format-numbers = Lista numerowana
ui-format-bullets = Lista punktowana
ui-format-outdent = Zmniejsz wcięcie
ui-format-indent = Zwiększ wcięcie
ui-format-left = Wyrównaj do lewej
ui-format-center = Wyśrodkuj
ui-format-right = Wyrównaj do prawej
ui-format-line = Wstaw linię poziomą
ui-tb-send = Wyślij
ui-tb-save = Zapisz
ui-tb-attach = Załącz
ui-tb-sign = Podpisz
ui-tb-encrypt = Szyfruj
ui-field-keys = Klucze:
ui-field-from = Od:
ui-field-to = Do:
ui-field-cc = DW:
ui-field-bcc = UDW:
ui-field-subject = Temat:
ui-field-attach = Załączniki:
ui-signature = Tekst podpisu
ui-signature-hint = Dodawany do nowych wiadomości, odpowiedzi i wiadomości przesyłanych dalej z tego konta.
ui-signature-not-saved = Nie udało się zapisać tekstu podpisu.
ui-all-inboxes = Wszystkie skrzynki odbiorcze
ui-all-sent = Wszystkie wysłane
ui-all-drafts = Wszystkie wersje robocze
ui-flagged-folder = Z flagą
ui-all-folders = Wszystkie foldery
ui-the-account = konto
ui-folder-name = Nazwa folderu:
ui-find-hint = Szukaj w poczcie
ui-find-tip = Przeszukuje tematy, nadawców, odbiorców, nazwy załączników i treść wiadomości.
ui-clear-search = Wyczyść wyszukiwanie
ui-no-match = Żadna wiadomość nie pasuje do „{ $words }”.
ui-no-match-all = Wyszukiwanie obejmuje tematy, nadawców, odbiorców, nazwy załączników i treść wiadomości we wszystkich folderach. Sprawdź pisownię lub wpisz mniej słów.
ui-no-match-in = Zakres wyszukiwania: „{ $folder }”. Przeszukiwane są tematy, dane nadawców i odbiorców, nazwy załączników oraz treść wiadomości. Sprawdź pisownię lub wpisz mniej słów.
ui-no-items = W tym widoku nie ma żadnych elementów.
ui-choose-folder = Wybierz folder, aby zobaczyć jego wiadomości.
ui-unsubscribe = Wypisz się
ui-open-in-calendar = Otwórz w kalendarzu
ui-pictures-blocked = Niektóre obrazy zostały zablokowane, aby ograniczyć śledzenie przez nadawcę.
ui-not-shown = Nie udało się wyświetlić wiadomości.
ui-attachment-not-read = Nie udało się odczytać załącznika.
ui-attachment-not-saved = Nie udało się zapisać załącznika.
ui-not-downloaded = Wiadomość nie została jeszcze pobrana.
ui-leave-list = Wypisać się z tej listy mailingowej?
ui-leave-one-click = Inbox Classic wyśle prośbę o wypisanie do serwera { $target }. Nie otworzy się żadna strona i nie zostanie wysłany żaden e-mail.
ui-leave-mail = Aby się wypisać, wyślij wiadomość e-mail na adres { $target }. Inbox Classic przygotuje jej treść. Wyślij ją, aby potwierdzić wypisanie.
ui-leave-web = Strona wypisywania z listy mailingowej otworzy się w przeglądarce ({ $target }).
ui-unsubscribing = Wysyłanie prośby o wypisanie: { $target }...
ui-cannot-unsubscribe = Ta wiadomość nie zawiera opcji wypisania się z listy mailingowej.
ui-unsubscribed = Prośba o wypisanie została przyjęta.
ui-not-unsubscribed = Nie udało się wypisać: { $reason }
ui-list-bar = Ta wiadomość pochodzi z listy mailingowej ({ $domain }).
ui-list-bar-plain = Ta wiadomość pochodzi z listy mailingowej.
ui-list-bar-asked = Prośbę o wypisanie z tej listy wysłano { $date }.
ui-list-bar-came-after = Prośbę o wypisanie wysłano { $date }, ale ta wiadomość dotarła ponad dwa dni później.
ui-list-bar-opened = Stronę wypisywania z tej listy otwarto { $date }.
ui-list-bar-failed = Prośba o wypisanie nie powiodła się: { $reason }
ui-unsubscribe-ask = Wypisz się…
ui-unsubscribe-again = Wypisz się ponownie…
ui-event-span = Od { $start } do { $end }
ui-event-floating = { $when } (bez przeliczenia strefy czasowej)
ui-invitation = Zaproszenie: { $title }
ui-invitation-updated = Zaktualizowane zaproszenie: { $title }
ui-invitation-canceled = Odwołane: { $title }
ui-invitation-answer = Odpowiedź na zaproszenie: { $title }
ui-no-title = (bez tytułu)
ui-organizer = Organizator: { $name }
ui-invitation-not-read = Nie udało się odczytać zaproszenia.
ui-no-calendar = Nie udało się otworzyć zaproszenia. Sprawdź, czy aplikacja kalendarza na tym komputerze obsługuje pliki .ics.
ui-messages-not-changed = Nie udało się zmienić wiadomości.
ui-new-folder-in-selected = Nowy folder zostanie utworzony wewnątrz zaznaczonego folderu.
ui-new-folder-at-top = Nowy folder zostanie utworzony na najwyższym poziomie konta.
ui-folder-not-created = Nie udało się utworzyć folderu.
ui-folder-not-renamed = Nie udało się zmienić nazwy folderu.
ui-folder-not-deleted = Nie udało się usunąć folderu.
ui-rename-folder-intro = Wpisz nową nazwę folderu „{ $folder }”.
ui-properties-of = Właściwości: { $subject }
ui-internet-headers = Nagłówki internetowe tej wiadomości:
ui-save-messages-in = Wybierz folder do zapisu wiadomości
ui-save-message-as = Zapisz wiadomość jako
ui-import-choose-folder = Najpierw wybierz folder, do którego chcesz zaimportować wiadomości.
ui-add-account-title = Dodaj konto pocztowe
ui-accounts-title = Konta
ui-security-none = Brak (bez szyfrowania)
ui-field-required = Uzupełnij pole „{ $field }”.
ui-email-invalid = Adres e-mail jest nieprawidłowy.
ui-ports-invalid = Numery portów muszą mieścić się w zakresie od 1 do 65535.
ui-looking-up = Wyszukiwanie ustawień dla { $domain }...
ui-found-none = Wpisz dane konta podane przez dostawcę poczty.
ui-found-change = Zmień te ustawienia, jeśli dostawca podał inne.
ui-found-guess = Nie znaleziono ustawień dla tego adresu. Podane nazwy serwerów są jedynie propozycjami. Potwierdź je u dostawcy poczty.
ui-found-mx = Inbox Classic rozpoznał Twojego dostawcę poczty i uzupełnił ustawienia jego serwerów.
ui-found-srv = Te ustawienia znaleziono w rekordach DNS Twojej domeny.
ui-found-autodiscover = Te ustawienia znaleziono za pomocą Microsoft Autodiscover (Exchange).
ui-found-other = Dla tego adresu znaleziono te ustawienia.
ui-app-password-needed = Dostawca: { $provider }. Jeśli Twoje konto obsługuje hasła aplikacji, utwórz takie hasło w jego ustawieniach zabezpieczeń i wpisz je w polu Hasło w następnym formularzu. Outlook.com i Microsoft 365 wymagają logowania przez przeglądarkę.
ui-app-password-open = Otworzyć w przeglądarce instrukcje dostawcy ({ $provider })?
ui-plain-warning = Bez szyfrowania każdy, kto przechwyci ruch w Twojej sieci, może odczytać Twoje hasło i wiadomości. Kontynuuj tylko wtedy, gdy połączenie jest chronione w inny sposób; sama sieć lokalna nie zapewnia szyfrowania.
ui-continue-ask = Kontynuować?
ui-add-sign-in-app = Dodaj aplikację logowania...
ui-turned-off = Opcja „{ $name }” jest wyłączona na tym komputerze.
ui-off-here = Wyłączone na tym komputerze.
ui-why = Dlaczego?
ui-more-sign-in = Więcej opcji logowania...
ui-other-account = Aby dodać inne konto e-mail, wpisz swój adres e-mail i nazwę, którą zobaczą odbiorcy. Następnie zostaną wyszukane ustawienia serwerów.
ui-field-account-name = Nazwa konta:
ui-field-name = Nazwa wyświetlana:
ui-field-email = Adres e-mail:
ui-field-user = Nazwa użytkownika:
ui-field-password = Hasło:
ui-field-imap-host = Serwer poczty przychodzącej (IMAP):
ui-field-imap-port = Port IMAP:
ui-field-imap-security = Zabezpieczenia IMAP:
ui-field-smtp-host = Serwer poczty wychodzącej (SMTP):
ui-field-smtp-port = Port SMTP:
ui-field-smtp-security = Zabezpieczenia SMTP:
ui-field-other-addresses = Inne adresy, z których wysyłasz:
ui-sign-in-not-started = Nie udało się rozpocząć logowania przez przeglądarkę.
ui-sign-in-in-browser = Zaloguj się do konta „{ $account }” w otwartym oknie przeglądarki, a potem wróć tutaj.
ui-sign-in-failed = Nie udało się zalogować: { $reason }
ui-account-not-saved = Nie udało się zapisać konta.
ui-start-intro = Gmail, Google Workspace, Outlook.com i Microsoft 365: zaloguj się na stronie Google lub Microsoft. Hasło wpisujesz tam, nigdy w Inbox Classic.
ui-start-intro-apps = Zaloguj się przez przeglądarkę za pomocą jednej ze swoich aplikacji logowania (Więcej opcji logowania) albo dodaj dowolne konto e-mail, podając poniżej nazwę i adres.
ui-use-app-password = Użyj hasła aplikacji
ui-the-provider = dostawca
ui-provider-intro = Zaloguj się na konto { $email } na stronie dostawcy ({ $provider }). Inbox Classic nie otrzyma Twojego hasła. Jeśli konto pozwala używać haseł aplikacji w programach pocztowych, możesz też użyć hasła aplikacji utworzonego w ustawieniach zabezpieczeń konta. Outlook.com i Microsoft 365 obsługują wyłącznie logowanie przez przeglądarkę.
ui-provider-intro-apps = Zaloguj się na konto { $email } na stronie dostawcy ({ $provider }) za pomocą jednej ze swoich aplikacji logowania (Więcej opcji logowania). Jeśli konto pozwala używać haseł aplikacji w programach pocztowych, możesz też użyć hasła aplikacji utworzonego w ustawieniach zabezpieczeń konta. Outlook.com i Microsoft 365 obsługują wyłącznie logowanie przez przeglądarkę.
ui-finish = Zakończ
ui-logon = Logowanie
ui-enter-password = Wpisz hasło do konta „{ $account }”.
ui-signs-in-with = Aplikacja logowania: { $app }. Logowanie odbywa się w przeglądarce, a konto korzysta z serwerów wskazanych w ustawieniach tej aplikacji.
ui-keep-password = Pozostaw pole hasła puste, aby zachować bieżące hasło.
ui-remove-account = Usuń konto
ui-remove-account-ask = Usunąć to konto z Inbox Classic? Zostaną usunięte jego lokalne dane, w tym poczta oczekująca na wysłanie, oraz zapisane dane logowania. Wiadomości przechowywane na serwerze pozostaną na nim; wiadomości dostępne tylko na tym komputerze zostaną utracone.
ui-col-email = Adres e-mail
ui-col-incoming = Serwer poczty przychodzącej
ui-type-email = Wpisz swój adres e-mail, np. nazwa@example.com.
ui-ai-agent = Agent AI
ui-ai-agent-access = Dostęp agenta AI
ui-ai-agents = Agenci AI
ui-program-path = Program: { $path }
ui-it-may = Dozwolone działania:
ui-accounts-it-may-use = Dozwolone konta:
ui-send-message-ask = Wysłać wiadomość?
ui-col-name = Nazwa
ui-never = Nigdy
ui-connect-agent = Połącz agenta AI
ui-connect-agent-intro = Dodaj poniższą konfigurację do listy serwerów MCP swojego agenta (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Program
ui-col-may = Uprawnienia
ui-col-last-used = Ostatnie użycie
ui-col-when = Kiedy
ui-col-what = Działanie
ui-sign-in-app = Aplikacja logowania
ui-sign-in-apps = Aplikacje logowania
ui-add-sign-in-app-title = Dodaj aplikację logowania
ui-preset-app-name = Aplikacja logowania { $provider }
ui-issuer-not-checked = nie można sprawdzić ustawień wystawcy
ui-checking-issuer = Sprawdzanie { $issuer }...
ui-issuer-unusable = Nie można użyć tego wystawcy do logowania: { $reason }
ui-issuer-usable = Ten wystawca może być używany do logowania.
ui-sign-in-app-not-saved = Nie udało się zapisać aplikacji logowania: { $reason }
ui-check = &Sprawdź
ui-fill-in-for = Użyj ustawień dla:
ui-app-name = Nazwa:
ui-issuer = Wystawca:
ui-client-id = Identyfikator klienta:
ui-client-secret = Klucz tajny klienta:
ui-scopes = Zakresy uprawnień (scopes):
ui-imap-server = Serwer IMAP:
ui-smtp-server = Serwer SMTP:
ui-redirect-uri = URI przekierowania:
ui-sign-in-app-intro = Aplikacja logowania to klient OAuth, którego rejestrujesz u dostawcy poczty, aby logować się przez przeglądarkę. Wybierz dostawcę, aby uzupełnić jego ustawienia. Następnie podaj identyfikator klienta i klucz tajny klienta, jeśli dostawca go udostępnił.
ui-remove-secret = Klucz tajny klienta jest zapisany. Wpisz nowy, aby go zastąpić, albo usuń zapisany klucz
ui-register-it = Zarejestruj aplikację u dostawcy
ui-built-in-note = Aplikacja „{ $name }” jest wbudowana. Możesz jedynie zdecydować, czy ma być proponowana przy dodawaniu kont.
ui-client-with-secret = Identyfikator klienta: { $client }. Zapisano klucz tajny klienta.
ui-client-public = Identyfikator klienta: { $client }. Klient publiczny, bez klucza tajnego.
ui-no-accounts = Brak kont
ui-remove-sign-in-app = Usuń aplikację logowania
ui-remove-sign-in-app-ask = Usunąć aplikację logowania „{ $name }” i jej zapisany klucz tajny klienta?
ui-sign-in-app-not-removed = Nie usunięto aplikacji logowania. { $reason }
ui-sign-in-apps-intro = Aplikacje logowania umożliwiają logowanie się do kont przez przeglądarkę. Niezaznaczone aplikacje nie są proponowane przy dodawaniu kont. Konta, które już z nich korzystają, nadal działają.
ui-col-issuer = Wystawca
ui-col-used-by = Używana przez
ui-options-system-default = Język systemu ({ $language })
ui-settings-general = Ogólne
ui-settings-reading = Czytanie
ui-settings-new-mail = Nowa poczta
ui-settings-sending = Wysyłanie
ui-settings-default-apps = Aplikacje domyślne
ui-settings-message-list = Lista wiadomości
ui-settings-messages = Wiadomości
ui-settings-encryption = Szyfrowanie
ui-settings-language = Język
ui-settings-label = { $label }:
ui-apply = &Zastosuj
ui-language-label = &Język:
ui-restart-note = Uruchom ponownie Inbox Classic, aby zmienić język.
ui-restart-ask = Wybrany język: { $language }. Zmiana zacznie obowiązywać po ponownym uruchomieniu Inbox Classic. Uruchomić ponownie teraz?
ui-notify-new-mail = &Powiadamiaj mnie o nowej poczcie
ui-new-folder-title = Nowy folder
ui-rename-folder-title = Zmień nazwę folderu
ui-delete-folder-question = Usunąć folder „{ $folder }” wraz ze wszystkimi wiadomościami i podfolderami? Zostanie usunięty także z serwera.
ui-properties = Właś&ciwości
ui-account-sync = Wyśl&ij i odbierz
ui-account-properties = &Właściwości...
ui-account-move-up = Przenieś w &górę
ui-account-move-down = Przenieś w &dół
ui-menu-open = &Otwórz
ui-menu-flag = Fla&ga
ui-menu-view-source = Pokaż ź&ródło
# Context menu: the same action as cmd-unsubscribe, with its own access key.
ui-menu-unsubscribe = Wypisz się z &listy...
ui-save-attachments = Zapisz załączniki
ui-attachment-open = Otwórz
ui-attachment-save-as = Zapisz jako...
ui-attachment-save-all = Zapisz wszystkie...
ui-attachment-show-in-message = Pokaż w wiadomości
ui-attachments-strip = Załączniki
ui-attachment-note-title = Otwieranie tego pliku
ui-attachment-program-tip = Otwieranie jest wyłączone dla tego typu plików: mogą one uruchamiać programy. Zapisz plik, aby otworzyć go samodzielnie.
ui-clear-flag = &Usuń flagę
ui-button-move = &Przenieś
ui-button-copy = &Kopiuj
ui-find-folder = Znajdź folder
ui-new-folder-in = Nowy folder zostanie utworzony w folderze „{ $folder }”.
ui-outbox-send-all = &Wyślij wszystkie teraz
ui-yes = Tak
ui-no = Nie
ui-try-again = Spróbuj ponownie
ui-remove = U&suń
ui-signature-of = Tekst podpisu: { $account }
ui-sign-in-with = Zaloguj się przez { $provider }
ui-sign-in-in-browser-yours = Zaloguj się do swojego konta w otwartym oknie przeglądarki, a potem wróć tutaj.
ui-browser-sign-in-server = { $server } (logowanie w przeglądarce)
ui-dont-allow = Nie zezwalaj
ui-allow = &Zezwól
ui-dont-send = Nie wysyłaj
ui-dont-unsubscribe = Nie wypisuj
ui-edit-first = Najpierw &edytuj
ui-new-address = Nowy adres
ui-turn-away = &Odrzuć
ui-clear-agent-log = Wyczyścić historię działań agentów?
ui-clear-agent-log-detail = Nie cofnie to zmian wprowadzonych przez agentów.
ui-let-agents-connect = &Pozwól agentom AI łączyć się z Inbox Classic
ui-change-button = Zmień…
ui-undo-button = Cofnij
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Cofnij od…
ui-undo-since-span = Cofnij to, co zrobił ten program:
ui-take-back = Cofnij
ui-rules-title = Reguły wiadomości
ui-rules-intro = Reguły porządkują nowe wiadomości w Skrzynce odbiorczej, gdy Inbox Classic działa. Są wykonywane po kolei dla pasujących wiadomości. Gdy reguła przeniesie wiadomość ze Skrzynki odbiorczej, kolejne reguły już jej nie dotyczą.
ui-rules-none = Nie ma jeszcze reguł. Kliknij Nowa, aby ją utworzyć.
ui-rule-new = &Nowa...
ui-rule-edit = &Edytuj...
ui-rule-delete-button = &Usuń
ui-rule-title = Reguła wiadomości
ui-rule-name = Nazwa:
ui-rule-account = Konto:
ui-rule-all-accounts = Wszystkie konta
ui-rule-query = Kryteria wyszukiwania:
ui-rule-query-hint = Używaj wyrażeń wyszukiwania, takich jak from:ann@example.com, subject:faktura czy list:news.example.com, tak samo jak w polu wyszukiwania.
ui-rule-count = { $count ->
    [one] Obecnie 1 wiadomość w Skrzynce odbiorczej pasuje do tych kryteriów.
    [few] Obecnie { $count } wiadomości w Skrzynce odbiorczej pasują do tych kryteriów.
    [many] Obecnie { $count } wiadomości w Skrzynce odbiorczej pasuje do tych kryteriów.
   *[other] Obecnie { $count } wiadomości w Skrzynce odbiorczej pasuje do tych kryteriów.
}
ui-rule-show = &Pokaż
ui-rule-actions = Działania:
ui-rule-move = P&rzenieś do:
ui-rule-mark-read = Oznacz jako prze&czytaną
ui-rule-flag = Oznacz &flagą
ui-rule-archive = &Archiwizuj
ui-rule-junk = Przenieś do folderu Wiadomości-ś&mieci
ui-rule-delete = &Usuń
ui-rule-quiet = &Nie powiadamiaj mnie o niej
ui-rule-apply-now = Zastosuj też do wiadomości, które już są w Skrzynce &odbiorczej
ui-rule-delete-ask = Usunąć regułę „{ $name }”?
ui-create-rule = Utwórz regułę...
ui-rules-applied = { $count ->
    [one] 1 wiadomość przetworzona przez Twoje reguły
    [few] { $count } wiadomości przetworzone przez Twoje reguły
    [many] { $count } wiadomości przetworzonych przez Twoje reguły
   *[other] { $count } wiadomości przetworzonych przez Twoje reguły
}
ui-col-rule-matches = Kryteria
ui-clear-button = &Wyczyść
ui-how-to-connect = Jak połączyć agenta…
ui-agent-programs = Programy, których agenci poprosili o dostęp do Twojej poczty
ui-what-agents-did = Działania agentów
ui-restart-now = &Uruchom ponownie teraz
ui-restart-later = &Później

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Nowy kontakt
ui-tb-new-group = Nowa grupa
ui-tb-properties = Właściwości
ui-tb-write-to = Napisz do
ui-menu-new-contact = Nowy &kontakt...
ui-menu-new-group = Nowa &grupa...
ui-menu-write-to = &Napisz do
ui-menu-delete = &Usuń
ui-book-find-hint = Wpisz nazwę lub adres e-mail
ui-book-all-contacts = Wszystkie kontakty
ui-col-phone = Telefon
ui-book-empty = Książka adresowa jest pusta. Kliknij Nowy kontakt, aby kogoś dodać, albo zaimportuj plik vCard lub CSV z menu Plik.
ui-book-no-match = Żaden kontakt nie pasuje do „{ $words }”.
ui-book-delete-ask = { $count ->
    [one] Usunąć ten kontakt z Książki adresowej?
    [few] Usunąć te kontakty ({ $count }) z Książki adresowej?
    [many] Usunąć te kontakty ({ $count }) z Książki adresowej?
   *[other] Usunąć te kontakty ({ $count }) z Książki adresowej?
}
ui-group-delete-ask = Usunąć grupę „{ $name }”? Osoby z tej grupy pozostaną w Książce adresowej.
ui-book-no-address = Kontakt „{ $name }” nie ma adresu e-mail.
ui-new-contact-title = Nowy kontakt
ui-contact-title = Właściwości: { $name }
ui-contact-first = Imię:
ui-contact-last = Nazwisko:
ui-contact-display = Nazwa wyświetlana:
ui-contact-nickname = Pseudonim:
ui-contact-company = Firma:
ui-contact-addresses = Adresy e-mail:
ui-contact-address-hint = Wpisz adres e-mail
ui-contact-add = &Dodaj
ui-contact-set-default = Ustaw jako do&myślny
ui-contact-default = { $address } (domyślny)
ui-contact-phones = Numery telefonów:
ui-phone-home = Domowy
ui-phone-work = Służbowy
ui-phone-mobile = Komórkowy
ui-phone-other = Inny
ui-contact-notes = Notatki:
ui-contact-name-needed = Wpisz nazwę lub adres e-mail kontaktu.
ui-contact-address-invalid = „{ $address }” nie jest prawidłowym adresem e-mail.
ui-contact-not-saved = Nie udało się zapisać kontaktu: { $reason }
ui-new-group-title = Nowa grupa
ui-group-title = Właściwości: { $name }
ui-group-name = Nazwa grupy:
ui-group-members = Członkowie:
ui-group-select-members = &Wybierz członków...
ui-group-new-member = Dodaj adres e-mail, którego nie ma w Książce adresowej:
ui-group-name-needed = Wpisz nazwę grupy.
ui-group-not-saved = Nie udało się zapisać grupy: { $reason }
ui-group-members-count = { $count ->
    [one] 1 członek
    [few] { $count } członków
    [many] { $count } członków
   *[other] { $count } członków
}
ui-select-recipients = Wybierz odbiorców
ui-select-members = Wybierz członków grupy
ui-pick-intro = Wpisz nazwę lub wybierz ją z listy:
ui-pick-recipients = Odbiorcy wiadomości:
ui-pick-members = Członkowie grupy:
ui-pick-to = &Do →
ui-pick-cc = D&W →
ui-pick-bcc = &UDW →
ui-pick-add = Dod&aj →
ui-pick-tip = Wybierz odbiorców z Książki adresowej
ui-filter-address-books = Książki adresowe (vCard, CSV)
ui-filter-vcard = Pliki vCard
ui-book-export-name = Książka adresowa
ui-book-imported = { $added ->
    [one] Dodano 1 kontakt
    [few] Dodano { $added } kontakty
    [many] Dodano { $added } kontaktów
   *[other] Dodano { $added } kontaktów
}, { $skipped ->
    [one] pominięto 1, który już jest w Książce adresowej.
    [few] pominięto { $skipped }, które już są w Książce adresowej.
    [many] pominięto { $skipped }, które już są w Książce adresowej.
   *[other] pominięto { $skipped }, które już są w Książce adresowej.
}
ui-book-not-imported = Nie udało się zaimportować książki adresowej: { $reason }
ui-book-exported = { $count ->
    [one] Zapisano 1 kontakt w pliku { $file }.
    [few] Zapisano { $count } kontakty w pliku { $file }.
    [many] Zapisano { $count } kontaktów w pliku { $file }.
   *[other] Zapisano { $count } kontaktów w pliku { $file }.
}
ui-book-not-exported = Nie udało się zapisać książki adresowej: { $reason }
ui-code-copied = Skopiowano kod
ui-codes-in-notifications = Po&kazuj kody logowania w powiadomieniach o nowej poczcie
ui-tool-unread-only = Nieprzeczytane
ui-no-unread = Nie ma tu nieprzeczytanych wiadomości.
ui-pictures-always-sender = Zawsze pobieraj obrazy (nadawca: { $sender })
ui-pictures-always-domain = Zawsze pobieraj obrazy od wszystkich z domeny { $domain }
ui-pictures-unconfirmed = Nie udało się zweryfikować domeny nadawcy ({ $domain }), więc obrazy w tej wiadomości nie są pobierane automatycznie.
ui-pictures-always-option = P&obieraj obrazy we wszystkich wiadomościach
ui-pictures-always-warning = Nadawcy mogą wtedy dowiedzieć się, kiedy czytasz ich wiadomości.
ui-protection-details = &Szczegóły...
ui-protection-details-title = Szczegóły zabezpieczeń
ui-download-heading = Pobieranie
ui-download-ahead = &Pobieraj wiadomości z wyprzedzeniem:
ui-download-ahead-recent = Najnowsze wiadomości o rozmiarze do 1 MB każda
ui-download-ahead-all = Wszystkie wiadomości
ui-download-ahead-never = Tylko po otwarciu
ui-download-limit = &Limit miejsca na konto:
ui-send-delay = &Opóźnienie przed wysłaniem:
ui-send-delay-note = Podczas odliczania możesz anulować wysyłkę poleceniem Cofnij. Ta możliwość kończy się wraz z odliczaniem, nawet jeśli wiadomość nadal czeka na wysłanie.
ui-dark-messages = Pokazuj wiadomości na ciemnym tle, gdy system jest w trybie ciemnym
ui-preview-show = Pokazuj z&ałączniki w wiadomościach
ui-preview-show-note = Pokazuje obrazy i pierwsze strony plików PDF pod tekstem wiadomości. Inbox Classic sam tworzy podglądy, bez uruchamiania skryptów zawartych w plikach.
ui-preview-pdfs = Pokazuj pliki PD&F w wiadomościach
ui-sending-in = Wysyłanie { $subject } za { $count ->
    [one] 1 sekundę
    [few] { $count } sekundy
    [many] { $count } sekund
   *[other] { $count } sekund
}
ui-send-undone = Nie wysłano { $subject }. Wiadomość została ponownie otwarta do edycji.
ui-send-too-late = Nie można już cofnąć wysłania wiadomości { $subject }.
ui-outbox-status-undo = Wysyłka najwcześniej o { $time }
ui-download-note = Wiadomości pobrane z wyprzedzeniem można otwierać bez czekania na pobranie. Po przekroczeniu limitu program usuwa najstarsze pobrane kopie treści, z wyjątkiem wersji roboczych i wiadomości otwartych od uruchomienia programu. Usunięta treść jest pobierana ponownie przy otwarciu wiadomości. Limit nie obejmuje wszystkich danych aplikacji.
ui-attachment-downloading = Ta wiadomość nie została jeszcze w pełni pobrana. Spróbuj ponownie po zakończeniu pobierania.
ui-trusted-senders-button = Zaufa&ni nadawcy...
ui-trusted-senders-title = Zaufani nadawcy
ui-trusted-senders-note = Obrazy w wiadomościach od tych nadawców są pobierane automatycznie, gdy dostawca poczty zweryfikuje domenę nadawcy.
ui-trusted-everyone-at = Wszyscy z domeny { $domain }
ui-trusted-senders-empty = Nie dodano jeszcze zaufanych nadawców.
ui-search-encrypted = &Szukaj w zaszyfrowanych wiadomościach
ui-search-encrypted-note = Po pobraniu lub otwarciu wiadomości program próbuje ją odszyfrować za pomocą dostępnego klucza. Odszyfrowaną treść można wtedy przeszukiwać, a lista może pokazać jej chroniony temat. Indeks jest przechowywany lokalnie bez szyfrowania; agenci AI nie przeszukują odszyfrowanych treści. Wyłączenie tej opcji usuwa te dane z indeksu i przywraca zewnętrzne tematy wiadomości.
ui-pgp-keyserver = Szukaj &kluczy na keys.openpgp.org
ui-pgp-keyserver-note = Przy szukaniu klucza dla adresu e-mail program najpierw pyta domenę tego adresu, a potem, jeśli ta opcja jest włączona, wysyła adres do keys.openpgp.org. Wyszukiwanie po odcisku lub identyfikatorze klucza wysyła ten identyfikator zamiast adresu.
ui-eml-default = Otwi&eraj pliki .eml w Inbox Classic
ui-eml-default-done = Inbox Classic otwiera teraz pliki .eml.
ui-eml-default-failed = Nie udało się ustawić Inbox Classic jako domyślnej aplikacji dla plików .eml: { $reason }
ui-folders = Foldery
ui-sorted-by = Sortowanie: { $field }
ui-layout-label = &Układ:
ui-columns-note = Okno jest wystarczająco szerokie na układ kolumnowy. Układ możesz zmienić w menu Widok > Układ.
ui-row-unread = Nieprzeczytana
ui-row-flagged = Z flagą
ui-row-attachments = Ma załączniki
ui-row-encrypted = Zaszyfrowana
ui-row-signed = Podpisana cyfrowo
ui-row-messages = { $count ->
    [one] { $count } wiadomość
    [few] { $count } wiadomości
    [many] { $count } wiadomości
   *[other] { $count } wiadomości
}
ui-list-pictures = &Pokazuj obrazy nadawców na liście wiadomości
ui-list-pictures-note = W układzie kolumnowym pokazuje logotypy marek lub zdjęcia z Książki adresowej, gdy dostawca potwierdzi domenę nadawcy. W pozostałych przypadkach pokazuje inicjały. Logotypy są przechowywane lokalnie i ponownie wykorzystywane; ich pobranie lub odświeżenie może wymagać połączenia z internetem.
ui-card-picture = Zdjęcie:
ui-card-picture-choose = &Wybierz...
ui-picture-not-picture = Ten plik nie jest prawidłowym obrazem PNG ani JPEG.
ui-picture-too-large = To zdjęcie jest za duże. Wybierz plik o rozmiarze do 10 MB, którego szerokość i wysokość nie przekraczają 8000 pikseli.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)

ui-keys-title = Klucze szyfrowania
ui-keys-intro = Twoje klucze służą do cyfrowego podpisywania wiadomości i odszyfrowywania poczty adresowanej do Ciebie. Klucze kontaktów pozwalają sprawdzać ich podpisy cyfrowe i szyfrować wiadomości do nich.
ui-keys-empty = Nie ma jeszcze kluczy. Kliknij Nowy klucz, aby utworzyć swój, albo Importuj, aby dodać klucz, który już masz.
ui-keys-col-name = Nazwa
ui-keys-col-address = Adres
ui-keys-col-kind = Rodzaj
ui-keys-col-status = Stan
ui-keys-kind-own = Twój klucz
ui-keys-kind-contact = Klucz kontaktu
ui-keys-status-verified = { $status }; potwierdzono właściciela klucza
ui-keys-new = &Nowy klucz...
ui-keys-import = &Importuj...
ui-keys-export = &Eksportuj...
ui-keys-backup = &Kopia zapasowa...
ui-keys-verify = &Zweryfikuj...
ui-keys-new-title = Nowy klucz
ui-keys-new-for = Utwórz klucz dla:
ui-keys-new-make = &Utwórz klucz
ui-keys-no-account = Najpierw dodaj konto pocztowe: klucz tworzy się dla adresów konta.
ui-keys-memory-only = Hasła są przechowywane tylko w pamięci, więc utworzonego lub zaimportowanego teraz klucza prywatnego nie będzie można użyć po zamknięciu Inbox Classic.
ui-keys-backup-offer = Twój nowy klucz jest gotowy. Zapisać teraz jego kopię zapasową? Jeśli utracisz komputer lub przywrócisz go do ustawień fabrycznych, klucz odzyskasz tylko z kopii zapasowej.
ui-keys-backup-now = &Zapisz kopię zapasową...
ui-keys-later = &Później
ui-keys-backup-title = Kopia zapasowa klucza
ui-keys-backup-intro = Kopia zapasowa jest zabezpieczona hasłem. Przechowuj plik i hasło w różnych bezpiecznych miejscach. Do przywrócenia klucza potrzebujesz obu.
ui-keys-passphrase = &Hasło:
ui-keys-passphrase-again = Po&wtórz hasło:
ui-keys-passphrase-differ = Hasła nie są takie same.
ui-keys-passphrase-short = Użyj hasła o długości co najmniej 8 znaków.
ui-keys-backup-saved = Kopia zapasowa została zapisana.
ui-keys-import-title = Importuj klucz
ui-keys-import-passphrase = Ten klucz prywatny jest zabezpieczony hasłem. Wpisz je, aby zaimportować klucz:
ui-keys-file-filter = Klucze OpenPGP
ui-keys-use-for = Przypisać klucze do adresów: { $addresses }? Będą służyć do cyfrowego podpisywania wiadomości z tych adresów i odszyfrowywania poczty do nich.
ui-keys-use = &Użyj go
ui-keys-not-now = &Nie teraz
ui-keys-remove-own = Usunąć Twój klucz { $fingerprint }? Bez ponownego importu jego kopii zapasowej nie będzie można używać go do odszyfrowywania wiadomości. Już odszyfrowane dane nie zostaną przez to usunięte.
ui-keys-remove-contact = Usunąć klucz kontaktu „{ $name }”? Dopóki ponownie go nie dodasz, nie będzie można używać tego klucza do sprawdzania podpisów cyfrowych ani szyfrowania poczty.
ui-key-properties-title = Właściwości klucza
ui-key-names = Nazwy:
ui-key-fingerprint = Odcisk klucza:
ui-key-status = Stan:
ui-key-created = Utworzono:
ui-key-expires = Wygasa:
ui-key-never = Nigdy
ui-key-algorithm = Algorytm:
ui-key-source = Źródło:
ui-key-addresses = Adresy:
ui-key-address-verified = { $address } (potwierdzono właściciela klucza)
ui-key-address-not-verified = { $address } (nie potwierdzono właściciela klucza)
ui-verify-title = Zweryfikuj klucz
ui-verify-intro = Kontakt: { $name }. Poproś tę osobę, aby podczas spotkania lub rozmowy telefonicznej odczytała Ci odcisk klucza ze swojej aplikacji. Nie porównuj go z odciskiem przesłanym e-mailem: ktoś, kto podmienił klucz, mógł też zmienić treść wiadomości.
ui-verify-fingerprint = Odcisk klucza, który masz:
ui-verify-marks = { $count ->
    [0] Ten klucz nie zawiera adresów e-mail. Nie można zapisać potwierdzenia jego właściciela.
    [one] Jeśli odciski są zgodne, potwierdzisz właściciela klucza dla adresu: { $addresses }. Jeśli ten adres nie należy do tej osoby, kliknij „Są różne”.
    [few] Jeśli odciski są zgodne, potwierdzisz właściciela klucza dla adresów: { $addresses }. Jeśli któryś z tych adresów nie należy do tej osoby, kliknij „Są różne”.
    [many] Jeśli odciski są zgodne, potwierdzisz właściciela klucza dla adresów: { $addresses }. Jeśli któryś z tych adresów nie należy do tej osoby, kliknij „Są różne”.
   *[other] Jeśli odciski są zgodne, potwierdzisz właściciela klucza dla adresów: { $addresses }. Jeśli któryś z tych adresów nie należy do tej osoby, kliknij „Są różne”.
}
ui-verify-match = Są &zgodne
ui-verify-differ = Są &różne
ui-verify-differs = Odcisk klucza nie zgadza się z odciskiem podanym przez kontakt „{ $name }”. Usuń ten klucz i poproś tę osobę o ponowne przesłanie jej klucza.
ui-verify-unmark = Usuń potwierdze&nie właściciela
ui-account-security = Zabezpieczenia
ui-account-security-intro = Klucz pozwala cyfrowo podpisywać wiadomości i odbierać zaszyfrowaną pocztę od innych osób.
ui-account-key = &Klucz dla tego konta:
ui-account-key-none = Brak
ui-account-key-new = &Nowy klucz...
ui-account-autocrypt = &Wysyłaj mój klucz publiczny z wiadomościami (Autocrypt)
ui-contact-key = Klucz szyfrowania:
ui-contact-key-none = Brak klucza
ui-contact-key-use-new = Użyj &nowego klucza
ui-contact-key-keep = &Zachowaj bieżący
ui-recipient-keys-title = Klucze odbiorców
ui-recipient-col-recipient = Odbiorca
ui-recipient-col-key = Klucz
ui-recipient-find-key = Znajdź &klucz
ui-recipient-remove = &Usuń z wiadomości
ui-send-unencrypted = Wyślij &bez szyfrowania
ui-compose-make-key = &Utwórz klucz...
ui-compose-show-keys = &Klucze szyfrowania...
ui-compose-encrypt-off = &Wyłącz szyfrowanie
ui-compose-keep-encrypted = &Zachowaj szyfrowanie
ui-setup-export-title = Eksportuj ustawienia i konta
ui-setup-import-title = Importuj ustawienia i konta
ui-setup-export-intro = Wybierz, co przenieść na inny komputer. Plik nie zawiera wiadomości. Na drugim komputerze można ponownie pobrać pocztę z serwera; poczta przechowywana tylko lokalnie nie zostanie przeniesiona.
ui-setup-use-passphrase = &Chroń plik hasłem
ui-setup-passphrase-note = Plik zabezpieczony hasłem jest zaszyfrowany i może zawierać dostępne zapisane hasła, dane logowania i klucze prywatne z wybranych części konfiguracji. Jeśli nie zabezpieczysz pliku hasłem, na drugim komputerze trzeba będzie ponownie zalogować się do kont.
ui-setup-export-button = &Eksportuj...
ui-setup-file-filter = Ustawienia i konta Inbox Classic
ui-setup-ask-passphrase = Ten plik jest zabezpieczony hasłem. Wpisz je, aby zobaczyć zawartość pliku:
ui-setup-import-intro = Wybierz, co zaimportować. Konta, które już są na tym komputerze, pozostaną bez zmian.
ui-setup-from = Zapisano w Inbox Classic { $version }. Data: { $date }.
ui-setup-import-button = &Importuj
ui-setup-done = Gotowe
ui-setup-first-run = Importuj ustawienia i konta z innego komputera...
