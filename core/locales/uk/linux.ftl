# Українська. Чернетка, чекає на перевірку носієм мови (див. core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. An _ marks a button's mnemonic letter.
# GNOME words where GNOME has them (Налаштування, Вийти).

## The main window

gtk-search-looks-in = Область пошуку: { $place }. Пошук охоплює теми, імена й адреси відправників та одержувачів, назви вкладень і текст повідомлень. Перевірте написання або спробуйте менше слів.
gtk-search-still-indexing = { $count ->
    [1] Текст одного повідомлення ще індексується. Незабаром можуть з’явитися інші результати.
    [one] Текст { $count } повідомлення ще індексується. Незабаром можуть з’явитися інші результати.
    [few] Текст { $count } повідомлень ще індексується. Незабаром можуть з’явитися інші результати.
    [many] Текст { $count } повідомлень ще індексується. Незабаром можуть з’явитися інші результати.
   *[other] Текст { $count } повідомлення ще індексується. Незабаром можуть з’явитися інші результати.
}
gtk-search-results-everywhere = { $count ->
    [0] Немає результатів
    [one] { $count } результат
    [few] { $count } результати
    [many] { $count } результатів
   *[other] { $count } результату
} для «{ $words }» у всіх папках
gtk-search-results-in = { $count ->
    [0] Немає результатів
    [one] { $count } результат
    [few] { $count } результати
    [many] { $count } результатів
   *[other] { $count } результату
} для «{ $words }». Область пошуку: { $place }
gtk-search-indexing = { $count ->
    [1] ще індексується текст одного повідомлення
    [one] ще індексується текст { $count } повідомлення
    [few] ще індексується текст { $count } повідомлень
    [many] ще індексується текст { $count } повідомлень
   *[other] ще індексується текст { $count } повідомлення
}
gtk-list-loading = Завантаження...
gtk-menu-rename = Перейменувати...
gtk-import-one-question = Імпортувати повідомлення з файлу «{ $file }» у папку «{ $folder }»?
gtk-files-not-saved = Не збережено: { $failed }. Усього файлів: { $total }.
gtk-unsubscribe-one-click = Скасувати підписку на цю розсилку?

    Inbox Classic надішле запит на скасування підписки на сервер { $target }. Вебсторінка не відкриється, повідомлення електронної пошти не надсилатиметься.
gtk-unsubscribe-mail = Скасувати підписку на цю розсилку?

    Inbox Classic підготує повідомлення на адресу { $target }. Надішліть його, щоб подати запит на скасування підписки.
gtk-unsubscribe-web = Скасувати підписку на цю розсилку?

    У браузері відкриється сторінка скасування підписки на розсилку ({ $target }).
gtk-unsubscribe-failed = Не вдалося скасувати підписку: { $problem }
gtk-toolbar-create-mail-menu = Створити повідомлення з певного облікового запису
gtk-toolbar-send-recv-menu = Надіслати й отримати пошту певного облікового запису
gtk-main-menu = Головне меню
gtk-folder-list = Список папок
gtk-quit = Вийти

## The Move and Copy window

gtk-new-folder-at-top-of = Нову папку буде створено на верхньому рівні облікового запису «{ $account }».
## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Немає непрочитаних повідомлень
    [one] { $count } непрочитане повідомлення
    [few] { $count } непрочитані повідомлення
    [many] { $count } непрочитаних повідомлень
   *[other] { $count } непрочитаного повідомлення
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Немає повідомлень, що чекають на надсилання.
gtk-outbox-row = Кому: { $to }  ·  У черзі з { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic і далі перевіряє пошту у фоновому режимі. Скористайтеся значком програми в області сповіщень, щоб відкрити її або завершити роботу.
gtk-sign-in-again-ask = Вхід в обліковий запис «{ $account }» відхилено або термін дії сеансу минув.

    Увійти знову в браузері?
gtk-default-app-not-installed = Цю копію Inbox Classic не встановлено, тому система не показує її серед поштових програм. Установіть її, щоб вибрати.
gtk-default-app-now = Тепер Inbox Classic є вашою типовою поштовою програмою: посилання електронної пошти відкривають тут нове повідомлення.
gtk-default-app-failed = Не вдалося зробити Inbox Classic типовою поштовою програмою.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Дата:
gtk-reader-files = Вкладення повідомлення
gtk-files = { $count ->
    [one] { $count } файл
    [few] { $count } файли
    [many] { $count } файлів
   *[other] { $count } файлу
}
gtk-pictures-blocked = Деякі зображення заблоковано, щоб зменшити можливості відстеження.
gtk-download-pictures = Завантажити зображення
gtk-save-attachments-menu = Зберегти вкладення...

## The compose window

gtk-format-bold = Напівжирний (Ctrl+B)
gtk-format-italic = Курсив (Ctrl+I)
gtk-format-underline = Підкреслений (Ctrl+U)
gtk-format-hyperlink = Гіперпосилання (Ctrl+K)
gtk-font = Шрифт
gtk-show-cc = _Копія
gtk-show-bcc = _Прихована
gtk-save-tip = Зберегти (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+клацання, щоб відкрити)

## Accounts

gtk-plain-warning = Без шифрування той, хто перехоплює мережевий трафік, може прочитати ваш пароль і повідомлення. Використовуйте таке з’єднання лише із сервером на власному комп’ютері або в довіреній локальній мережі. Сама локальна мережа не шифрує дані.

    Продовжити?
gtk-account-name-title = Назва облікового запису
gtk-display-name-title = Ім’я для відображення
gtk-turned-off-why = Спосіб входу «{ $button }» вимкнено на цьому комп’ютері. { $reason }
gtk-turned-off-why-long = Спосіб входу «{ $button }» вимкнено на цьому комп’ютері.

    { $reason }
gtk-next = Далі >
gtk-provider-sign-in = Увійдіть в обліковий запис { $address } на вебсайті { $provider }. Ваш пароль не передається в Inbox Classic. Якщо обліковий запис підтримує паролі застосунків для пошти, можна створити такий пароль у параметрах безпеки. Для Outlook.com і Microsoft 365 використовуйте лише вхід через браузер.
gtk-provider-sign-in-apps = Увійдіть в обліковий запис { $address } на вебсайті { $provider } через один зі своїх застосунків для входу («Інші способи входу»). Якщо обліковий запис підтримує паролі застосунків для пошти, можна створити такий пароль у параметрах безпеки. Для Outlook.com і Microsoft 365 використовуйте лише вхід через браузер.
gtk-accounts-add = Додати...
gtk-accounts-properties = Властивості...
gtk-accounts-signature = Текстовий підпис...
gtk-accounts-sign-in-apps = Застосунки для входу...

## Sign-in apps

gtk-app-server = Сервер { $kind }
gtk-app-port = Порт { $kind }
gtk-app-security = Захист з’єднання { $kind }
gtk-issuer-found = Сторінка входу: { $page }
    Адреса отримання токенів: { $endpoint }
gtk-client-id = Ідентифікатор клієнта
gtk-client-secret = Секрет клієнта
gtk-scopes = Області доступу (scopes)
gtk-redirect-uri = URI переспрямування
gtk-issuer-usable = Цей сервер авторизації можна використати.

    { $found }
gtk-app-built-in = Застосунок «{ $app }» вбудовано в програму. Можна лише вибрати, чи пропонувати його для нових облікових записів. { $reason }
gtk-built-in = { $app } (вбудований)
gtk-offered-for-new = Пропонується для нових облікових записів
gtk-edit-button = Змінити...
gtk-remove-app-ask = Вилучити застосунок для входу «{ $app }» і збережений секрет його клієнта?
gtk-sign-in-apps-intro = Застосунки для входу дають змогу входити через браузер. Вимкнений застосунок не пропонується для нових облікових записів. Облікові записи, які вже його використовують, працюють далі.
## AI agents

gtk-agent-it-may = Дозволені дії
gtk-agent-accounts = Дозволені облікові записи
gtk-never-used = Ще не використовувалася
gtk-last-used = Востаннє використано { $date }
gtk-forget-program = Вилучити запис про цю програму?
gtk-forget-program-detail = Дозволи програми й історію дій її агентів буде видалено. Наступного разу, коли вона під’єднається, у вас знову запитають дозвіл.
gtk-no-agents-yet = Жоден агент ще не просив доступу до вашої пошти.
gtk-nothing-yet = Поки нічого.

## Preferences

gtk-preferences = Налаштування
gtk-notify-subtitle = Лише коли головне вікно не на передньому плані
## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Поштовий клієнт
gtk-desktop-comment = Читайте й пишіть електронні листи: швидка й проста поштова програма
gtk-desktop-keywords = пошта;електронна пошта;лист;листи;вхідні;поштовий клієнт;
gtk-metainfo-summary = Швидка й проста поштова програма
gtk-metainfo-description = Inbox Classic дає змогу читати й писати електронну пошту у звичному класичному макеті: папки ліворуч, список повідомлень угорі, а вміст вибраного повідомлення під ним. Програма підтримує облікові записи IMAP і SMTP та вхід в Outlook.com і Microsoft 365 через браузер.
gtk-metainfo-feature-sanitized = Повідомлення очищуються від сценаріїв, а зображення з інтернету завантажуються з вашого дозволу
gtk-metainfo-feature-search = Пошук у темах, іменах та адресах людей, назвах вкладень і тексті повідомлень з операторами, як у Gmail
gtk-metainfo-feature-replies = Цитований текст попередніх повідомлень у відповіді можна згорнути
gtk-metainfo-feature-offline = Завантажену пошту можна читати без мережі; паролі за замовчуванням зберігаються в системному сховищі ключів