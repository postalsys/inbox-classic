# Українська. Чернетка, чекає на перевірку носієм мови (див. core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-.

## The main window

win-still-running-detail = Inbox Classic і далі перевіряє нову пошту у фоновому режимі. Клацніть значок, щоб відкрити програму. Щоб вийти, клацніть значок правою кнопкою миші й скористайтеся його меню.
win-default-app-not-installed = Цю копію Inbox Classic не встановлено, тому Windows не показує її серед поштових програм. Установіть її, щоб вибрати.
win-default-app-settings = Windows відкриє параметри типових програм. Виберіть Inbox Classic для відкриття посилань MAILTO.
win-no-unread = Немає непрочитаних повідомлень
win-unread-messages = { $count ->
    [one] { $count } непрочитане повідомлення
    [few] { $count } непрочитані повідомлення
    [many] { $count } непрочитаних повідомлень
   *[other] { $count } непрочитаного повідомлення
}
win-print-failed = Не вдалося надрукувати повідомлення.
win-print-title-of = Друк - { $subject }
win-no-bodies = Неможливо показати вміст повідомлень.
win-webview-failed = Не вдалося створити WebView2.
win-webview-missing = Середовище виконання WebView2 недоступне.
win-list-loading = Завантаження...

## Buttons and words used in many windows

win-delete-button = Вида&лити
win-find-label = &Знайти:
win-save-as-button = Зберегти &як...
win-too-many-files = Забагато файлів одночасно: виберіть менше.

## The Outbox


## The compose window

win-editor-failed = Неможливо писати повідомлення.
win-ctrl-click-to-open = ({ $ctrl }+клацання, щоб відкрити)
win-format-bold = Напівжирний ({ $ctrl }+B)
win-format-italic = Курсив ({ $ctrl }+I)
win-format-underline = Підкреслений ({ $ctrl }+U)
win-format-link = Гіперпосилання ({ $ctrl }+K)
win-show-cc = &Копія
win-show-bcc = &Прихована
win-signature-title = Текстовий підпис: { $account }
## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Немає результатів для «{ $words }» у всіх папках
    [one] { $count } результат для «{ $words }» у всіх папках
    [few] { $count } результати для «{ $words }» у всіх папках
    [many] { $count } результатів для «{ $words }» у всіх папках
   *[other] { $count } результату для «{ $words }» у всіх папках
}
win-search-found-in = { $count ->
    [0] Немає результатів для «{ $words }» у папці «{ $folder }»
    [one] { $count } результат для «{ $words }» у папці «{ $folder }»
    [few] { $count } результати для «{ $words }» у папці «{ $folder }»
    [many] { $count } результатів для «{ $words }» у папці «{ $folder }»
   *[other] { $count } результату для «{ $words }» у папці «{ $folder }»
}
win-search-indexing = { $count ->
    [one] ще індексується текст { $count } повідомлення
    [few] ще індексується текст { $count } повідомлень
    [many] ще індексується текст { $count } повідомлень
   *[other] ще індексується текст { $count } повідомлення
}
win-no-match-indexing = { $count ->
    [one] Текст { $count } повідомлення ще індексується, тому незабаром може знайтися більше.
    [few] Текст { $count } повідомлень ще індексується, тому незабаром може знайтися більше.
    [many] Текст { $count } повідомлень ще індексується, тому незабаром може знайтися більше.
   *[other] Текст { $count } повідомлення ще індексується, тому незабаром може знайтися більше.
}
win-files = { $count ->
    [one] { $count } файл
    [few] { $count } файли
    [many] { $count } файлів
   *[other] { $count } файлу
}
win-save-attachments = Зберегти &вкладення...
win-files-not-saved = Не збережено: { $failed }. Усього файлів: { $count }.
win-new-folder-in-highlighted = Нову папку буде створено всередині виділеної папки.
win-delete-folder-ask = Видалити папку «{ $folder }» разом із її повідомленнями та вкладеними папками? Її буде видалено й на сервері.
win-rename = Пере&йменувати...
win-messages-not-saved = Не вдалося зберегти повідомлення.
win-messages-not-forwarded = Не вдалося переслати повідомлення.

## Accounts

win-sign-in-google = Увійти через Google
win-sign-in-microsoft = Увійти через Microsoft
win-next = &Далі >
win-your-account = ваш обліковий запис
win-browser-sign-in = (вхід через браузер)
win-add = &Додати...
win-properties-button = &Властивості...
win-signature-button = Текстовий &підпис...
win-sign-in-apps-button = &Застосунки для входу...

## AI agents

win-dont-allow = &Не дозволяти
win-col-address = Адреса
win-never-written-to = Ще не надсилали повідомлень
win-book-find-label = Введіть ім’я або адресу електронної пошти:
win-send = &Надіслати
win-dont-send = Н&е надсилати
win-unsubscribe = &Скасувати підписку
win-dont-unsubscribe = &Не скасовувати підписку
win-forget-program-ask = Вилучити запис про цю програму, її дозволи та історію дій її агентів? Під час наступного під’єднання програма знову запитає дозвіл.
win-clear-log-ask = Очистити історію дій агентів? Це не скасує змін, які зробили агенти.
win-agent-programs = &Програми, агенти яких запитували доступ до вашої пошти:
win-change = &Змінити...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Скасувати з&а період...
win-take-back = &Скасувати зміни
win-what-agents-did = &Дії агентів:
win-agent-reads = Прочитані дані за період { $from } - { $to }:
win-agent-reads-hint = Виберіть вище рядок читання, щоб переглянути подробиці.

## Sign-in apps

win-built-in = (вбудований)
win-edit = &Змінити...

## Options

win-folders-hide = Сховати список папок
win-folders-pin = Закріпити список папок поруч із повідомленнями
win-folders-show = Показати папки

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Запустити Inbox Classic
win-installer-welcome-new = Буде встановлено поштову програму Inbox Classic { $version }.

    Права адміністратора не потрібні: програму буде встановлено лише для вашого облікового запису Windows.
win-installer-welcome-same =
    Inbox Classic { $version } уже встановлено. Програму буде встановлено ще раз.

    Ваші облікові записи й пошту буде збережено.
win-installer-welcome-update =
    Inbox Classic { $installed } буде оновлено до версії { $version }.

    Якщо програма працює, її спершу буде закрито. Ваші облікові записи й пошту буде збережено.
win-installer-older-ask = Уже встановлено Inbox Classic { $installed }. Ця версія новіша за { $version }. Усе одно встановити старішу версію?
win-installer-still-running = Inbox Classic досі працює. Закрийте програму й спробуйте знову.
win-installer-remove-mail-ask = Видалити також усі локальні дані Inbox Classic, зокрема облікові записи, повідомлення, контакти, параметри та ключі? Пошта на серверах залишиться. Записи в системному сховищі облікових даних залишаться.