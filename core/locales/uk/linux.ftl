# Українська. Чернетка, чекає на перевірку носієм мови (див. core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. An _ marks a button's mnemonic letter.
# GNOME words where GNOME has them (Налаштування, Вийти).

## The main window

# review: new
gtk-search-looks-in = Пошук у { $place } охоплює теми, відправників, одержувачів, назви вкладень і текст повідомлень. Перевірте написання або спробуйте менше слів.
# review: new
gtk-search-still-indexing = { $count ->
    [1] Текст одного повідомлення ще індексується. Незабаром можуть з’явитися інші результати.
    [one] Текст { $count } повідомлення ще індексується. Незабаром можуть з’явитися інші результати.
    [few] Текст { $count } повідомлень ще індексується. Незабаром можуть з’явитися інші результати.
    [many] Текст { $count } повідомлень ще індексується. Незабаром можуть з’явитися інші результати.
   *[other] Текст { $count } повідомлення ще індексується. Незабаром можуть з’явитися інші результати.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Немає результатів
    [one] { $count } результат
    [few] { $count } результати
    [many] { $count } результатів
   *[other] { $count } результату
} для «{ $words }» у всіх папках
# review: new
gtk-search-results-in = { $count ->
    [0] Немає результатів
    [one] { $count } результат
    [few] { $count } результати
    [many] { $count } результатів
   *[other] { $count } результату
} для «{ $words }» у { $place }
# review: new
gtk-search-indexing = { $count ->
    [1] ще індексується текст одного повідомлення
    [one] ще індексується текст { $count } повідомлення
    [few] ще індексується текст { $count } повідомлень
    [many] ще індексується текст { $count } повідомлень
   *[other] ще індексується текст { $count } повідомлення
}
# review: new
gtk-list-loading = Завантаження...
# review: new
gtk-menu-rename = Перейменувати...
# review: new
gtk-import-one-question = Імпортувати повідомлення { $file } у { $folder }?
# review: new
gtk-files-not-saved = Не вдалося зберегти файлів: { $failed } з { $total }.
# review: new
gtk-unsubscribe-one-click =
    Вийти з цього списку розсилки?

    Inbox Classic надішле запит на скасування підписки до { $target }. Жодна вебсторінка не відкриється, і жоден лист не буде надіслано.
# review: new
gtk-unsubscribe-mail =
    Вийти з цього списку розсилки?

    Щоб скасувати підписку, надішліть лист на { $target }. Inbox Classic підготує його для вас. Надішліть повідомлення, щоб підтвердити.
# review: new
gtk-unsubscribe-web =
    Вийти з цього списку розсилки?

    Сторінка скасування підписки списку розсилки відкриється у вашому браузері ({ $target }).
# review: new
gtk-unsubscribe-failed = Не вдалося скасувати підписку: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Написати з певного облікового запису
# review: new
gtk-toolbar-send-recv-menu = Надіслати й отримати пошту певного облікового запису
# review: new
gtk-main-menu = Головне меню
# review: new
gtk-folder-list = Список папок
# review: new
gtk-quit = Вийти

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Нова папка буде на верхньому рівні { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Немає непрочитаних повідомлень
    [one] { $count } непрочитане повідомлення
    [few] { $count } непрочитані повідомлення
    [many] { $count } непрочитаних повідомлень
   *[other] { $count } непрочитаного повідомлення
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Немає повідомлень, що чекають на надсилання.
# review: new
gtk-outbox-row = Кому: { $to }  ·  У черзі з { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic і далі перевіряє нову пошту у фоновому режимі. Скористайтеся його значком на верхній панелі, щоб відкрити програму або вийти з неї.
# review: new
gtk-sign-in-again-ask =
    Вхід у { $account } відхилено, або термін дії сеансу сплив.

    Увійти знову в браузері?
# review: new
gtk-default-app-not-installed = Цю копію Inbox Classic не встановлено, тому система не показує її серед поштових програм. Установіть її, щоб вибрати.
# review: new
gtk-default-app-now = Тепер Inbox Classic є вашою типовою поштовою програмою: посилання електронної пошти відкривають тут нове повідомлення.
# review: new
gtk-default-app-failed = Не вдалося зробити Inbox Classic типовою поштовою програмою.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Дата:
# review: new
gtk-reader-files = Вкладення повідомлення
# review: new
gtk-files = { $count ->
    [one] { $count } файл
    [few] { $count } файли
    [many] { $count } файлів
   *[other] { $count } файлу
}
# review: new
gtk-pictures-blocked = Деякі зображення заблоковано, щоб відправник не міг ідентифікувати ваш комп’ютер.
# review: new
gtk-download-pictures = Завантажити зображення
# review: new
gtk-save-attachments-menu = Зберегти вкладення...

## The compose window

# review: new
gtk-format-bold = Жирний (Ctrl+B)
# review: new
gtk-format-italic = Курсив (Ctrl+I)
# review: new
gtk-format-underline = Підкреслений (Ctrl+U)
# review: new
gtk-format-hyperlink = Гіперпосилання (Ctrl+K)
# review: new
gtk-font = Шрифт
# review: new
gtk-show-cc = _Копія
# review: new
gtk-show-bcc = _Прихована
# review: new
gtk-save-tip = Зберегти (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+клацання, щоб відкрити)

## Accounts

# review: new
gtk-plain-warning =
    Без шифрування будь-хто, хто перехоплює ваш мережевий трафік, може прочитати ваш пароль і повідомлення. Використовуйте таке з’єднання лише із сервером на вашому комп’ютері або в локальній мережі.

    Продовжити?
# review: new
gtk-account-name-title = Назва облікового запису
# review: new
gtk-display-name-title = Показуване ім’я
# review: new
gtk-turned-off-why = Параметр «{ $button }» вимкнено на цьому комп’ютері. { $reason }
# review: new
gtk-turned-off-why-long =
    Параметр «{ $button }» вимкнено на цьому комп’ютері.

    { $reason }
# review: new
gtk-next = Далі >
# review: new
gtk-provider-sign-in = Увійдіть у { $address } на вебсайті { $provider }. Ваш пароль не передається в Inbox Classic. Можна також використати пароль застосунку, створений у параметрах безпеки облікового запису.
# review: new
gtk-provider-sign-in-apps = Увійдіть у { $address } на вебсайті { $provider } за допомогою одного з ваших застосунків для входу (Інші способи входу). Можна також використати пароль застосунку, створений у параметрах безпеки облікового запису.
# review: new
gtk-accounts-add = Додати...
# review: new
gtk-accounts-properties = Властивості...
# review: new
gtk-accounts-signature = Підпис...
# review: new
gtk-accounts-sign-in-apps = Застосунки для входу...

## Sign-in apps

# review: new
gtk-app-server = Сервер { $kind }
# review: new
gtk-app-port = Порт { $kind }
# review: new
gtk-app-security = Безпека { $kind }
# review: new
gtk-issuer-found =
    Сторінка входу: { $page }
    Кінцева точка токенів: { $endpoint }
# review: new
gtk-client-id = Ідентифікатор клієнта
# review: new
gtk-client-secret = Секрет клієнта
# review: new
gtk-scopes = Дозволи (scopes)
# review: new
gtk-redirect-uri = URI переспрямування
# review: new
gtk-issuer-usable =
    Цього видавця можна використати.

    { $found }
# review: new
gtk-app-built-in = { $app } вбудовано. Можна лише змінити, чи пропонувати його для нових облікових записів. { $reason }
# review: new
gtk-built-in = { $app } (вбудований)
# review: new
gtk-offered-for-new = Пропонується для нових облікових записів
# review: new
gtk-edit-button = Змінити...
# review: new
gtk-remove-app-ask = Вилучити застосунок для входу { $app } і його збережений секрет клієнта?
# review: new
gtk-sign-in-apps-intro = Застосунки для входу дають обліковим записам змогу входити через браузер. Вимкнений застосунок не пропонується для нових облікових записів; ті, що вже ним користуються, працюють далі.

## AI agents

# review: new
gtk-agent-it-may = Дозволені дії
# review: new
gtk-agent-accounts = Дозволені облікові записи
# review: new
gtk-never-used = Ще не використовувалася
# review: new
gtk-last-used = Востаннє використано { $date }
# review: new
gtk-forget-program = Вилучити цю програму?
# review: new
gtk-forget-program-detail = Дозволи програми й історію дій її агентів буде видалено. Наступного разу, коли вона під’єднається, у вас знову запитають дозвіл.
# review: new
gtk-no-agents-yet = Жоден агент ще не просив доступу до вашої пошти.
# review: new
gtk-nothing-yet = Поки нічого.

## Preferences

# review: new
gtk-preferences = Налаштування
# review: new
gtk-language-subtitle = Мова програми й довідки
# review: new
gtk-notify-subtitle = Сповіщення, коли надходять нові повідомлення, а вікно у фоні

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Поштовий клієнт
# review: new
gtk-desktop-comment = Читайте й пишіть електронні листи: швидка й проста поштова програма
# review: new
gtk-desktop-keywords = пошта;електронна пошта;лист;листи;вхідні;поштовий клієнт;
# review: new
gtk-metainfo-summary = Швидка й проста поштова програма
# review: new
gtk-metainfo-description = Inbox Classic читає й пише електронну пошту так, як це робили класичні поштові програми: папки ліворуч, повідомлення вгорі, а вміст повідомлення під ними. Він працює з будь-яким обліковим записом IMAP і SMTP та входить в Outlook.com і Microsoft 365 через браузер.
# review: new
gtk-metainfo-feature-sanitized = Кожне повідомлення показується очищеним, без скриптів, а зображення з інтернету лише тоді, коли ви дозволите
# review: new
gtk-metainfo-feature-search = Пошук слів у темі, людях, назвах файлів і тексті, з операторами Gmail
# review: new
gtk-metainfo-feature-replies = Відповіді згортають попередні повідомлення, які вони цитують
# review: new
gtk-metainfo-feature-offline = Пошта доступна без інтернету; паролі зберігаються у вашій в’язці ключів
