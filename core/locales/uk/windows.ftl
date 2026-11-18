# Українська. Чернетка, чекає на перевірку носієм мови (див. core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-.

## The main window

# review: new
win-still-running-detail = Inbox Classic і далі перевіряє нову пошту у фоновому режимі. Клацніть значок, щоб відкрити програму. Щоб вийти, клацніть значок правою кнопкою миші й скористайтеся його меню.
# review: new
win-default-app-not-installed = Цю копію Inbox Classic не встановлено, тому Windows не показує її серед поштових програм. Установіть її, щоб вибрати.
# review: new
win-default-app-settings = Windows відкриє параметри «Програми за замовчуванням». Виберіть Inbox Classic для посилань MAILTO.
# review: new
win-no-unread = Немає непрочитаних повідомлень
# review: new
win-unread-messages = { $count ->
    [one] { $count } непрочитане повідомлення
    [few] { $count } непрочитані повідомлення
    [many] { $count } непрочитаних повідомлень
   *[other] { $count } непрочитаного повідомлення
}
# review: new
win-print-failed = Не вдалося надрукувати повідомлення.
# review: new
win-print-title-of = Друк - { $subject }
# review: new
win-no-bodies = Неможливо показати вміст повідомлень.
# review: new
win-webview-failed = Не вдалося створити WebView2.
# review: new
win-webview-missing = Середовище виконання WebView2 недоступне.
win-list-loading = Завантаження...

## Buttons and words used in many windows

# review: new
win-delete-button = &Видалити
# review: new
win-find-label = &Знайти:
# review: new
win-save-as-button = Зберегти &як...
# review: new
win-too-many-files = Забагато файлів одночасно: виберіть менше.

## The Outbox


## The compose window

# review: new
win-editor-failed = Неможливо писати повідомлення.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+клацання, щоб відкрити)
# review: new
win-format-bold = Жирний ({ $ctrl }+B)
# review: new
win-format-italic = Курсив ({ $ctrl }+I)
# review: new
win-format-underline = Підкреслений ({ $ctrl }+U)
# review: new
win-format-link = Гіперпосилання ({ $ctrl }+K)
# review: new
win-show-cc = &Копія
# review: new
win-show-bcc = &Прихована
# review: new
win-signature-title = Підпис: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Немає результатів для «{ $words }» у всіх папках
    [one] { $count } результат для «{ $words }» у всіх папках
    [few] { $count } результати для «{ $words }» у всіх папках
    [many] { $count } результатів для «{ $words }» у всіх папках
   *[other] { $count } результату для «{ $words }» у всіх папках
}
# review: new
win-search-found-in = { $count ->
    [0] Немає результатів для «{ $words }» у папці «{ $folder }»
    [one] { $count } результат для «{ $words }» у папці «{ $folder }»
    [few] { $count } результати для «{ $words }» у папці «{ $folder }»
    [many] { $count } результатів для «{ $words }» у папці «{ $folder }»
   *[other] { $count } результату для «{ $words }» у папці «{ $folder }»
}
# review: new
win-search-indexing = { $count ->
    [one] ще індексується текст { $count } повідомлення
    [few] ще індексується текст { $count } повідомлень
    [many] ще індексується текст { $count } повідомлень
   *[other] ще індексується текст { $count } повідомлення
}
# review: new
win-no-match-indexing = { $count ->
    [one] Текст { $count } повідомлення ще індексується, тому незабаром може знайтися більше.
    [few] Текст { $count } повідомлень ще індексується, тому незабаром може знайтися більше.
    [many] Текст { $count } повідомлень ще індексується, тому незабаром може знайтися більше.
   *[other] Текст { $count } повідомлення ще індексується, тому незабаром може знайтися більше.
}
# review: new
win-files = { $count ->
    [one] { $count } файл
    [few] { $count } файли
    [many] { $count } файлів
   *[other] { $count } файлу
}
# review: new
win-click-to-retry = Клацніть тут, щоб спробувати знову.
# review: new
win-save-attachments = Зберегти &вкладення...
# review: new
win-files-not-saved = Не вдалося зберегти файлів: { $failed } з { $count }.
# review: new
win-new-folder-in-highlighted = Нову папку буде створено всередині виділеної папки.
# review: new
win-delete-folder-ask = Видалити папку «{ $folder }» разом із її повідомленнями та вкладеними папками? Її буде видалено й на сервері.
# review: new
win-rename = Пере&йменувати...
# review: new
win-messages-not-saved = Не вдалося зберегти повідомлення.
# review: new
win-messages-not-forwarded = Не вдалося переслати повідомлення.

## Accounts

# review: new
win-sign-in-google = Увійти через Google
# review: new
win-sign-in-microsoft = Увійти через Microsoft
# review: new
win-next = &Далі >
# review: new
win-your-account = ваш обліковий запис
# review: new
win-browser-sign-in = (вхід через браузер)
# review: new
win-add = &Додати...
# review: new
win-properties-button = &Властивості...
# review: new
win-signature-button = &Підпис...
# review: new
win-sign-in-apps-button = &Застосунки для входу...

## AI agents

# review: new
win-dont-allow = &Не дозволяти
# review: new
win-col-address = Адреса
# review: new
win-never-written-to = Ще не листувалися
# review: new
win-book-find-label = Введіть ім’я або адресу електронної пошти:
# review: new
win-send = &Надіслати
# review: new
win-dont-send = Н&е надсилати
win-unsubscribe = &Скасувати підписку
win-dont-unsubscribe = &Не скасовувати підписку
# review: new
win-forget-program-ask = Вилучити цю програму, її дозволи й історію дій її агентів? Наступного разу, коли вона під’єднається, у вас знову запитають дозвіл.
# review: new
win-clear-log-ask = Очистити історію дій агентів? Це не скасує змін, які зробили агенти.
# review: new
win-agent-programs = &Програми, агенти яких запитували доступ до вашої пошти:
# review: new
win-change = &Змінити...
# review: new
win-what-agents-did = &Дії агентів:
# review: new
win-agent-reads = Що прочитано з { $from } до { $to }:
# review: new
win-agent-reads-hint = Виберіть вище рядок із прочитаним, щоб побачити, що було прочитано.
# review: new
win-how-to-connect = Як під’єднати агента

## Sign-in apps

# review: new
win-built-in = (вбудований)
# review: new
win-edit = &Змінити...

## Options

# review: new
win-folders-hide = Сховати список папок
# review: new
win-folders-pin = Тримати список папок поруч із повідомленнями
# review: new
win-folders-show = Показати папки

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Запустити Inbox Classic
# review: new
win-installer-welcome-new =
    Буде встановлено Inbox Classic { $version }, програму електронної пошти.

    Права адміністратора не потрібні, програму буде встановлено лише для вашого облікового запису.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } уже встановлено. Програму буде встановлено ще раз.

    Ваші облікові записи й пошту буде збережено.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } буде оновлено до версії { $version }.

    Якщо програма працює, її спершу буде закрито. Ваші облікові записи й пошту буде збережено.
# review: new
win-installer-older-ask = Установлено Inbox Classic { $installed }, новішу за { $version }. Однаково встановити старішу версію?
# review: new
win-installer-still-running = Inbox Classic досі працює. Закрийте програму й спробуйте знову.
# review: new
win-installer-remove-mail-ask = Вилучити також облікові записи й пошту, які Inbox Classic зберігає на цьому комп’ютері? Пошта на серверах залишиться.
