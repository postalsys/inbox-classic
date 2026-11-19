# Українська. Чернетка, чекає на перевірку носієм мови (див. core/locales/GLOSSARY.md).
# An & marks the letter of a menu item that Alt and the letter choose on Windows and Linux (&& is an ampersand).

## The menus

menu-file = &Файл
menu-edit = &Редагування
menu-view = &Вигляд
menu-tools = &Сервіс
menu-message = &Повідомлення
menu-help = &Довідка
menu-layout = &Макет
menu-sort-by = &Сортувати за
menu-text-size = Розмір &тексту
menu-folder = &Папка
menu-insert = Вс&тавлення

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = &Новий обліковий запис...
cmd-exit = Ви&хід
cmd-sync = &Надіслати й отримати все
cmd-mark-read = Позначити як п&рочитане
cmd-mark-unread = Позначити як &непрочитане
cmd-pictures = &Завантажити зображення
cmd-about = &Про Inbox Classic
cmd-new-mail = &Нове повідомлення
cmd-reply = &Відповісти відправнику
cmd-reply-all = Відповісти вс&ім
cmd-forward = &Переслати
cmd-help = &Зміст
cmd-delete = &Видалити повідомлення
cmd-move = Пере&містити в папку...
cmd-flag = Позначити п&рапорцем
cmd-new-folder = Но&ва папка...
cmd-rename-folder = Пере&йменувати папку...
cmd-delete-folder = Вида&лити папку
cmd-empty-folder = О&чистити папку
ui-empty-button = Очистити
cmd-accounts = Облікові &записи...
cmd-find = &Знайти повідомлення
cmd-save-as = З&берегти як...
cmd-print = &Друк...
cmd-import = &Імпортувати повідомлення...
cmd-outbox = &Вихідні...
cmd-properties = &Властивості
cmd-mark-all-read = Позначити &усі як прочитані
cmd-junk = Позначити як не&бажане
cmd-not-junk = Позначити як звичайн&е
cmd-archive = &Архівувати
cmd-watch-conversation = Відс&тежувати розмову
cmd-ignore-conversation = І&гнорувати розмову
cmd-next-message = &Наступне повідомлення
cmd-previous-message = П&опереднє повідомлення
cmd-next-unread = Наступне непрочит&ане
cmd-go-to-folder = Пере&йти до папки...
cmd-find-in-message = Знайти в &цьому повідомленні...
ui-go-to-prompt = Перейти до папки:
ui-find-in-message-hint = Знайти в цьому повідомленні
ui-find-not-found = «{ $words }» немає в цьому повідомленні
cmd-expand-all-threads = Розгорнути &всі розмови
cmd-collapse-all-threads = З&горнути всі розмови
ui-group-by-conversation = Гр&упувати повідомлення за розмовами
cmd-folder-list = Список &папок
cmd-layout-automatic = &Автоматично
cmd-layout-classic = &Класичний
cmd-layout-columns = &Стовпці
cmd-sort-date = &Дата
cmd-sort-from = &Відправник
cmd-sort-subject = &Тема
cmd-sort-size = &Розмір
cmd-sort-ascending = За &зростанням
cmd-sort-descending = За с&паданням
cmd-text-size-largest = На&йбільший
cmd-text-size-larger = &Більший
cmd-text-size-medium = &Середній
cmd-text-size-smaller = &Менший
cmd-text-size-smallest = &Найменший
cmd-hide-ignored = Приховати &ігноровані розмови
cmd-hide-read = Приховати п&рочитані повідомлення
cmd-notify = &Сповіщати про нову пошту
cmd-open = &Відкрити Inbox Classic
cmd-default-app = Зробити &типовою поштовою програмою...
cmd-view-source = Ви&хідний текст повідомлення
cmd-ai-agents = &ШІ-агенти...
cmd-options = Пара&метри...
cmd-message-rules = &Правила для повідомлень...
cmd-encryption-keys = &Ключі шифрування...
cmd-create-rule-from-message = &Створити правило з повідомлення...
cmd-select-all = Виді&лити все
cmd-undo = &Скасувати
cmd-copy = &Копіювати в папку...
cmd-address-book = &Адресна книга...
cmd-add-sender-to-book = Додати відправника до адресно&ї книги
cmd-import-address-book = Імпортувати &адресну книгу...
cmd-export-address-book = &Експортувати адресну книгу...
cmd-export-setup = Експортувати параметри й &облікові записи...
cmd-import-setup = Імпортувати пара&метри й облікові записи...
cmd-compose-sign = &Підписати цифровим підписом
cmd-compose-encrypt = &Зашифрувати
cmd-attach-my-key = Вкласти свій &відкритий ключ

## The tray icon's menu

tray-check = &Перевірити нову пошту
tray-no-accounts = Облікових записів ще немає

## Words the windows of more than one platform share

ui-tb-create-mail = Створити
ui-tb-reply = Відповісти
ui-tb-reply-all = Відповісти всім
ui-tb-forward = Переслати
ui-tb-print = Друк
ui-tb-delete = Видалити
ui-tb-junk = Небажане
ui-tb-not-junk = Звичайне
ui-tb-archive = Архівувати
ui-tb-previous = Попереднє
ui-tb-next = Наступне
ui-previous-tip = Попереднє повідомлення
ui-next-tip = Наступне повідомлення
ui-tb-sync = Надіслати й отримати
ui-tb-mark-read = Прочитане
ui-tb-mark-unread = Непрочитане
ui-still-running = Inbox Classic працює далі
ui-no-subject = (без теми)
ui-quoted = «{ $subject }»
ui-newest-from = Останнє повідомлення. Відправник: { $sender }. Тема: { $subject }
ui-new-messages = { $count ->
    [one] { $count } нове повідомлення
    [few] { $count } нові повідомлення
    [many] { $count } нових повідомлень
   *[other] { $count } нового повідомлення
}
ui-outbox-waiting = { $count ->
    [many] { $count } повідомлень у папці «Вихідні»
   *[other] { $count } повідомлення в папці «Вихідні»
}
ui-outbox-waits = Повідомлення { $subject } очікує надсилання в папці «Вихідні».
ui-outbox-sending = Надсилання повідомлення { $subject }...
ui-from-account = Обліковий запис: { $account }
ui-sign-in-refused = Вхід в обліковий запис «{ $account }» відхилено або термін дії сеансу минув.
ui-sign-in-again-ask = Увійти знову в браузері?
ui-sign-in-again-failed = Не вдалося увійти знову: { $reason }
ui-unknown-reason = невідома причина
ui-checking = Перевірка нової пошти в обліковому записі «{ $account }»...
ui-done = Готово
ui-sent-at = { $subject } надіслано о { $time }
ui-draft-saved = Повідомлення збережено в папці «Чернетки»
ui-draft-not-saved = Повідомлення не збережено в папці «Чернетки»: { $reason }
ui-about-core = Ядро { $version }
ui-add-account-first = Спершу додайте поштовий обліковий запис.
ui-add-account-first-link = Спершу додайте поштовий обліковий запис, а тоді знову клацніть посилання електронної пошти.
ui-default-app-is = Inbox Classic є вашою типовою поштовою програмою: посилання електронної пошти відкривають тут нове повідомлення.
ui-select-message-first = Спершу виберіть повідомлення.
ui-store-not-opened = Не вдалося відкрити поштове сховище.
ui-store-or-cert-not-opened = Не вдалося відкрити поштове сховище або файл сертифіката.
ui-help-title = Довідка Inbox Classic
ui-help-missing = У цій копії Inbox Classic немає довідки.
ui-ok = OK
ui-cancel = Скасувати
ui-close = Закрити
ui-col-subject = Тема
ui-col-from = Від
ui-col-to = Кому
ui-col-received = Отримано
# the column of the glasses of a watched conversation (and the sign of an ignored one)
# a notification of new mail in a watched conversation, over who it is from
ui-watched-conversation = Відстежувана розмова
ui-col-sent = Надіслано
ui-col-size = Розмір
ui-col-folder = Папка
ui-col-account = Обліковий запис
ui-col-queued = У черзі з
ui-col-status = Стан
ui-outbox-title = Вихідні
ui-outbox-status-waiting = Очікує
ui-outbox-status-not-sent = Не надіслано: { $reason }
# This message is still queued, during the grace period before an agent’s send.
ui-outbox-status-agent = Додано до черги ШІ-агентом; надсилання заплановано на { $time }
ui-outbox-delete-ask = Видалити це повідомлення, не надсилаючи його?
ui-open-link = Відкрити посилання
ui-edit-link = Змінити посилання...
ui-remove-link = Вилучити посилання
ui-insert-attachment = Вставити вкладення
ui-insert-picture = Вставити зображення
ui-filter-all = Усі файли
ui-filter-pictures = Зображення
ui-filter-messages = Повідомлення електронної пошти
ui-save-attachment-as = Зберегти вкладення як
ui-not-sent = Не вдалося надіслати повідомлення.
ui-attachment-forgotten = Ви написали «{ $word }», але не вклали файл. Усе одно надіслати повідомлення?
ui-send-anyway = Усе одно надіслати
ui-go-back = Повернутися
ui-not-saved = Не вдалося зберегти повідомлення.
ui-saving-draft = Збереження в папці «Чернетки»...
ui-compose-saved-at = Збережено в папці «Чернетки» о { $time }
ui-compose-restored = Відновлено після неочікуваного закриття Inbox Classic
ui-compose-not-saved = Не збережено в папці «Чернетки»: { $reason }
ui-save-changes-ask = Зберегти зміни в цьому повідомленні в папці «Чернетки»?
ui-new-message-title = Нове повідомлення
ui-link-invalid = Введіть вебадресу (https://...) або посилання електронної пошти (mailto:...).
ui-link-address = Адреса:
ui-hyperlink = Гіперпосилання
ui-hyperlink-intro = Адреса, на яку посилається виділений текст.
ui-edit-hyperlink = Змінити гіперпосилання
ui-edit-hyperlink-intro = Адреса призначення посилання. Очистьте адресу, щоб вилучити посилання й залишити текст.
ui-not-a-picture = Не вдалося вставити зображення. Підтримуються файли PNG, JPEG, GIF і WebP розміром до 10 МБ.
ui-format-color = Колір шрифту
ui-format-numbers = Нумерований список
ui-format-bullets = Маркований список
ui-format-outdent = Зменшити відступ
ui-format-indent = Збільшити відступ
ui-format-left = Вирівняти ліворуч
ui-format-center = По центру
ui-format-right = Вирівняти праворуч
ui-format-line = Вставити горизонтальну лінію
ui-tb-send = Надіслати
ui-tb-save = Зберегти
ui-tb-attach = Вкласти
ui-tb-sign = Підписати
ui-tb-encrypt = Зашифрувати
ui-field-keys = Ключі:
ui-field-from = Від:
ui-field-to = Кому:
ui-field-cc = Копія:
ui-field-bcc = Прихована:
ui-field-subject = Тема:
ui-field-attach = Вкладення:
ui-signature = Текстовий підпис
ui-signature-hint = Додається до нових повідомлень, відповідей і пересилань із цього облікового запису.
ui-signature-not-saved = Не вдалося зберегти текстовий підпис.
ui-all-inboxes = Усі вхідні
ui-all-sent = Усі надіслані
ui-all-drafts = Усі чернетки
ui-flagged-folder = З прапорцем
ui-all-folders = Усі папки
ui-the-account = обліковий запис
ui-folder-name = Назва папки:
ui-find-hint = Пошук у пошті
ui-find-tip = Пошук у темах, іменах та адресах відправників і одержувачів, назвах вкладень і тексті повідомлень.
ui-clear-search = Очистити пошук
ui-no-match = Немає повідомлень, що відповідають «{ $words }».
ui-no-match-all = Пошук охоплює теми, відправників, одержувачів, назви вкладень і текст повідомлень у всіх папках. Перевірте написання або спробуйте менше слів.
ui-no-match-in = Пошук у папці «{ $folder }» охоплює теми, відправників, одержувачів, назви вкладень і текст повідомлень. Перевірте написання або спробуйте менше слів.
ui-no-items = У цьому поданні немає елементів.
ui-choose-folder = Виберіть папку, щоб побачити її повідомлення.
ui-unsubscribe = Скасувати підписку
ui-open-in-calendar = Відкрити в календарі
ui-pictures-blocked = Деякі зображення заблоковано, щоб зменшити можливості відстеження. Клацніть тут, щоб завантажити їх.
ui-not-shown = Не вдалося показати повідомлення.
ui-attachment-not-read = Не вдалося прочитати вкладення.
ui-attachment-not-saved = Не вдалося зберегти вкладення.
ui-not-downloaded = Повідомлення ще не завантажено.
ui-leave-list = Скасувати підписку на цю розсилку?
ui-leave-one-click = Inbox Classic надішле запит на скасування підписки на сервер { $target }. Вебсторінка не відкриється, повідомлення електронної пошти не надсилатиметься.
ui-leave-mail = Inbox Classic підготує повідомлення на адресу { $target }. Надішліть його, щоб подати запит на скасування підписки.
ui-leave-web = У браузері відкриється сторінка скасування підписки на розсилку ({ $target }).
ui-unsubscribing = Надсилання запиту на скасування підписки. Сервер: { $target }...
ui-cannot-unsubscribe = Це повідомлення не містить способу скасувати підписку.
ui-unsubscribed = Запит на скасування підписки прийнято.
ui-not-unsubscribed = Не вдалося скасувати підписку: { $reason }
ui-event-span = { $start } - { $end }
ui-event-floating = { $when } (часовий пояс не визначено)
ui-invitation = Запрошення: { $title }
ui-invitation-updated = Оновлене запрошення: { $title }
ui-invitation-canceled = Скасовано: { $title }
ui-invitation-answer = Відповідь на запрошення: { $title }
ui-no-title = (без назви)
ui-organizer = Організатор: { $name }
ui-invitation-not-read = Не вдалося прочитати запрошення.
ui-no-calendar = Не вдалося відкрити запрошення. Перевірте, чи встановлено програму календаря для файлів .ics.
ui-messages-not-changed = Не вдалося змінити повідомлення.
ui-new-folder-in-selected = Нову папку буде створено всередині виділеної папки.
ui-new-folder-at-top = Нову папку буде створено на верхньому рівні облікового запису.
ui-folder-not-created = Не вдалося створити папку.
ui-folder-not-renamed = Не вдалося перейменувати папку.
ui-folder-not-deleted = Не вдалося видалити папку.
ui-rename-folder-intro = Введіть нову назву для папки «{ $folder }».
ui-properties-of = Властивості: { $subject }
ui-internet-headers = Заголовки цього повідомлення:
ui-save-messages-in = Папка для збереження повідомлень
ui-save-message-as = Зберегти повідомлення як
ui-import-choose-folder = Спершу виберіть папку, в яку імпортувати повідомлення.
ui-add-account-title = Додати поштовий обліковий запис
ui-accounts-title = Облікові записи
ui-security-none = Немає (без шифрування)
ui-field-required = Поле «{ $field }» обов’язкове.
ui-email-invalid = Адреса електронної пошти недійсна.
ui-ports-invalid = Порт має бути числом від 1 до 65535.
ui-looking-up = Пошук параметрів для домену { $domain }...
ui-found-none = Введіть дані облікового запису, надані вашим провайдером електронної пошти.
ui-found-change = Змініть ці параметри, якщо ваш провайдер надав інші.
ui-found-guess = Параметрів для цієї адреси не знайдено. Запропоновані назви серверів визначено приблизно. Уточніть їх у провайдера.
ui-found-mx = Визначено вашого поштового провайдера й заповнено параметри його серверів.
ui-found-srv = Ці параметри знайдено в записах DNS вашого домену.
ui-found-autodiscover = Ці параметри знайдено через Microsoft Autodiscover (Exchange).
ui-found-other = Ці параметри знайдено для цієї адреси.
ui-app-password-needed = Для входу поштової програми може знадобитися пароль застосунку, якщо ваш обліковий запис його підтримує. Створіть такий пароль на вебсайті { $provider } і введіть його в поле «Пароль» на наступному кроці. Для Outlook.com і Microsoft 365 використовуйте вхід через браузер.
ui-app-password-open = Відкрити інструкції на вебсайті { $provider } у браузері?
ui-plain-warning = Без шифрування той, хто перехоплює мережевий трафік, може прочитати ваш пароль і повідомлення. Використовуйте таке з’єднання лише із сервером на власному комп’ютері або в довіреній локальній мережі. Сама локальна мережа не шифрує дані.
ui-continue-ask = Продовжити?
ui-add-sign-in-app = Додати застосунок для входу...
ui-turned-off = Спосіб входу «{ $name }» вимкнено на цьому комп’ютері.
ui-off-here = Вимкнено на цьому комп’ютері.
ui-why = Чому?
ui-more-sign-in = Інші способи входу...
ui-other-account = Щоб додати інший поштовий обліковий запис, введіть свою адресу та ім’я, яке бачитимуть одержувачі. Далі Inbox Classic спробує знайти параметри серверів.
ui-field-account-name = Назва облікового запису:
ui-field-name = Ім’я для відображення:
ui-field-email = Адреса електронної пошти:
ui-field-user = Ім’я користувача:
ui-field-password = Пароль:
ui-field-imap-host = Сервер вхідної пошти (IMAP):
ui-field-imap-port = Порт IMAP:
ui-field-imap-security = Захист з’єднання IMAP:
ui-field-smtp-host = Сервер вихідної пошти (SMTP):
ui-field-smtp-port = Порт SMTP:
ui-field-smtp-security = Захист з’єднання SMTP:
ui-field-other-addresses = Інші адреси для надсилання повідомлень:
ui-sign-in-not-started = Не вдалося почати вхід через браузер.
ui-sign-in-in-browser = Увійдіть в обліковий запис «{ $account }» у вікні браузера, що відкрилося, а тоді поверніться сюди.
ui-sign-in-failed = Не вдалося увійти: { $reason }
ui-account-not-saved = Не вдалося зберегти обліковий запис.
ui-start-intro = Для Gmail, Google Workspace, Outlook.com і Microsoft 365 увійдіть на сторінці Google або Microsoft. Пароль ви вводите там, він не передається в Inbox Classic.
ui-start-intro-apps = Увійдіть через браузер за допомогою одного зі своїх застосунків для входу («Інші способи входу») або додайте інший поштовий обліковий запис, вказавши нижче своє ім’я та адресу.
ui-use-app-password = Використати пароль застосунку
# fills { $provider } where a provider has no known name, in the genitive: "на вебсайті вашого провайдера"
ui-the-provider = вашого провайдера
ui-provider-intro = Увійдіть в обліковий запис { $email } на вебсайті { $provider }. Ваш пароль не передається в Inbox Classic. Якщо обліковий запис підтримує паролі застосунків для пошти, можна створити такий пароль у параметрах безпеки. Для Outlook.com і Microsoft 365 використовуйте лише вхід через браузер.
ui-provider-intro-apps = Увійдіть в обліковий запис { $email } на вебсайті { $provider } через один зі своїх застосунків для входу («Інші способи входу»). Якщо обліковий запис підтримує паролі застосунків для пошти, можна створити такий пароль у параметрах безпеки. Для Outlook.com і Microsoft 365 використовуйте лише вхід через браузер.
ui-finish = Готово
ui-logon = Вхід
ui-enter-password = Введіть пароль облікового запису «{ $account }».
ui-signs-in-with = Застосунок для входу: { $app }. Вхід виконується в браузері, і обліковий запис використовує сервери цього застосунку.
ui-keep-password = Залиште поле пароля порожнім, щоб не змінювати поточний пароль.
ui-remove-account = Вилучити обліковий запис
ui-remove-account-ask = Вилучити цей обліковий запис з Inbox Classic? Його локальні дані та збережені дані для входу буде видалено. Пошта на сервері залишиться, але повідомлення, що є лише на цьому комп’ютері, буде втрачено.
ui-col-email = Адреса електронної пошти
ui-col-incoming = Сервер вхідної пошти
ui-type-email = Введіть свою адресу електронної пошти, наприклад name@example.com.
ui-ai-agent = ШІ-агент
ui-ai-agent-access = Доступ ШІ-агента
ui-ai-agents = ШІ-агенти
ui-program-path = Програма: { $path }
ui-it-may = Дозволені дії:
ui-accounts-it-may-use = Дозволені облікові записи:
ui-send-message-ask = Надіслати повідомлення?
ui-col-name = Назва
ui-never = Ніколи
ui-connect-agent = Під’єднати ШІ-агента
ui-connect-agent-intro = Додайте це до серверів MCP свого агента (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Програма
ui-col-may = Дозволи
ui-col-last-used = Останнє використання
ui-col-when = Коли
ui-col-what = Дія
ui-sign-in-app = Застосунок для входу
ui-sign-in-apps = Застосунки для входу
ui-add-sign-in-app-title = Додати застосунок для входу
ui-preset-app-name = Застосунок для входу: { $provider }
ui-issuer-not-checked = не вдалося перевірити сервер авторизації
ui-checking-issuer = Перевірка сервера авторизації: { $issuer }...
ui-issuer-unusable = Цей сервер авторизації не можна використати: { $reason }
ui-issuer-usable = Цей сервер авторизації можна використати.
ui-sign-in-app-not-saved = Не вдалося зберегти застосунок для входу: { $reason }
ui-check = Пе&ревірити
ui-fill-in-for = Використати параметри для:
ui-app-name = Назва:
ui-issuer = Сервер авторизації:
ui-client-id = Ідентифікатор клієнта:
ui-client-secret = Секрет клієнта:
ui-scopes = Області доступу (scopes):
ui-imap-server = Сервер IMAP:
ui-smtp-server = Сервер SMTP:
ui-redirect-uri = URI переспрямування:
ui-sign-in-app-intro = Застосунок для входу є клієнтом OAuth, який ви реєструєте у свого провайдера, щоб входити через браузер. Виберіть провайдера, щоб заповнити його параметри, а тоді додайте ідентифікатор клієнта та секрет клієнта, якщо провайдер його надав.
ui-remove-secret = Секрет клієнта збережено. Введіть новий, щоб замінити його, або вилучіть збережений секрет
ui-register-it = Зареєструйте застосунок у свого провайдера
ui-built-in-note = Застосунок «{ $name }» вбудовано в програму. Можна лише вибрати, чи пропонувати його для нових облікових записів.
ui-client-with-secret = Ідентифікатор клієнта: { $client }. Секрет клієнта збережено.
ui-client-public = Ідентифікатор клієнта: { $client }. Публічний клієнт, секрету немає.
ui-no-accounts = Немає облікових записів
ui-remove-sign-in-app = Вилучити застосунок для входу
ui-remove-sign-in-app-ask = Вилучити застосунок для входу «{ $name }» і збережений секрет його клієнта?
ui-sign-in-app-not-removed = Застосунок для входу не вилучено. { $reason }
ui-sign-in-apps-intro = Застосунки для входу дають змогу входити через браузер. Вимкнений застосунок не пропонується для нових облікових записів. Облікові записи, які вже його використовують, працюють далі.
ui-col-issuer = Сервер авторизації
ui-col-used-by = Використовують
ui-options-system-default = Як у системі ({ $language })
ui-settings-general = Загальні
ui-settings-reading = Читання
ui-settings-new-mail = Нова пошта
ui-settings-sending = Надсилання
ui-settings-default-apps = Типові програми
ui-settings-message-list = Список повідомлень
ui-settings-messages = Повідомлення
ui-settings-encryption = Шифрування
ui-settings-language = Мова
ui-settings-label = { $label }:
ui-apply = &Застосувати
ui-language-label = &Мова:
ui-restart-note = Щоб змінити мову, перезапустіть Inbox Classic.
ui-restart-ask = Inbox Classic буде показано мовою «{ $language }» після перезапуску. Перезапустити зараз?
ui-notify-new-mail = &Сповіщати мене про нову пошту
ui-new-folder-title = Нова папка
ui-rename-folder-title = Перейменувати папку
ui-delete-folder-question = Видалити папку «{ $folder }» разом із її повідомленнями та вкладеними папками? Її буде видалено й на сервері.
ui-properties = Властив&ості
ui-account-sync = Надіслати й &отримати
ui-account-properties = В&ластивості...
ui-account-move-up = В&гору
ui-account-move-down = Вн&из
ui-menu-open = Відкр&ити
ui-menu-flag = Прапоре&ць
ui-menu-view-source = Переглянути ви&хідний текст
ui-save-attachments = Зберегти вкладення
ui-attachment-open = Відкрити
ui-attachment-save-as = Зберегти як...
ui-attachment-save-all = Зберегти всі...
ui-attachment-show-in-message = Показати в повідомленні
ui-attachments-strip = Вкладення
ui-attachment-note-title = Відкриття цього файлу
ui-attachment-program-tip = Команда «Відкрити» недоступна для файлів цього типу: вони можуть запускати програми. Збережіть файл і відкрийте його самостійно.
ui-clear-flag = З&няти прапорець
ui-button-move = &Перемістити
ui-button-copy = &Копіювати
ui-find-folder = Знайти папку
ui-new-folder-in = Нову папку буде створено в папці «{ $folder }».
ui-outbox-send-all = &Надіслати все зараз
ui-yes = Так
ui-no = Ні
ui-try-again = Спробувати знову
ui-remove = В&илучити
ui-signature-of = Текстовий підпис: { $account }
ui-sign-in-with = Увійти через { $provider }
ui-sign-in-in-browser-yours = Увійдіть у свій обліковий запис у вікні браузера, що відкрилося, а тоді поверніться сюди.
ui-browser-sign-in-server = { $server } (вхід через браузер)
ui-dont-allow = Не дозволяти
ui-allow = &Дозволити
ui-dont-send = Не надсилати
ui-dont-unsubscribe = Не скасовувати підписку
ui-edit-first = Спершу &змінити
ui-new-address = Нова адреса
ui-turn-away = &Відхилити
ui-clear-agent-log = Очистити історію дій агентів?
ui-clear-agent-log-detail = Це не скасує змін, які зробили агенти.
ui-let-agents-connect = Дозво&лити ШІ-агентам під’єднуватися до Inbox Classic
ui-change-button = Змінити…
ui-undo-button = Скасувати
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Скасувати за період…
ui-undo-since-span = Скасувати зміни, зроблені цією програмою:
ui-take-back = Скасувати зміни
ui-rules-title = Правила для повідомлень
ui-rules-intro = Правила обробляють нові повідомлення в папці «Вхідні», поки Inbox Classic працює. Правила, умовам яких відповідає повідомлення, виконуються в порядку списку. Якщо правило переміщує повідомлення з папки «Вхідні», наступні правила до нього не застосовуються.
ui-rules-none = Правил ще немає. Клацніть «Створити», щоб додати правило.
ui-rule-new = &Створити...
ui-rule-edit = &Змінити...
ui-rule-delete-button = &Видалити
ui-rule-title = Правило для повідомлень
ui-rule-name = Назва:
ui-rule-account = Обліковий запис:
ui-rule-all-accounts = Усі облікові записи
ui-rule-query = Умови пошуку:
ui-rule-query-hint = Використовуйте пошукові слова, як-от from:ann@example.com, subject:рахунок або list:news.example.com, так само, як у полі пошуку.
ui-rule-count = { $count ->
    [one] Зараз цим умовам відповідає { $count } повідомлення в папці «Вхідні».
    [few] Зараз цим умовам відповідають { $count } повідомлення в папці «Вхідні».
    [many] Зараз цим умовам відповідає { $count } повідомлень у папці «Вхідні».
   *[other] Зараз цим умовам відповідає { $count } повідомлення в папці «Вхідні».
}
ui-rule-show = &Показати
ui-rule-actions = Дії:
ui-rule-move = П&еремістити в:
ui-rule-mark-read = Позначити як п&рочитане
ui-rule-flag = Познач&ити прапорцем
ui-rule-archive = &Архівувати
ui-rule-junk = Перемістити в «&Небажану пошту»
ui-rule-delete = &Видалити
ui-rule-quiet = Не &сповіщати мене про нього
ui-rule-apply-now = Застосувати &також до повідомлень, що вже є у «Вхідних»
ui-rule-delete-ask = Видалити правило «{ $name }»?
ui-create-rule = Створити правило...
ui-rules-applied = { $count ->
    [one] Оброблено за правилами: { $count } повідомлення
    [few] Оброблено за правилами: { $count } повідомлення
    [many] Оброблено за правилами: { $count } повідомлень
   *[other] Оброблено за правилами: { $count } повідомлення
}
ui-col-rule-matches = Умови
ui-clear-button = О&чистити
ui-how-to-connect = Як під’єднати агента…
ui-agent-programs = Програми, агенти яких запитували доступ до вашої пошти
ui-what-agents-did = Дії агентів
ui-restart-now = &Перезапустити зараз
ui-restart-later = П&ізніше
## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Новий контакт
ui-tb-new-group = Нова група
ui-tb-properties = Властивості
ui-tb-write-to = Написати
ui-menu-new-contact = Новий &контакт...
ui-menu-new-group = Нова &група...
ui-menu-write-to = &Написати
ui-menu-delete = &Видалити
ui-book-find-hint = Введіть ім’я або адресу електронної пошти
ui-book-all-contacts = Усі контакти
ui-col-phone = Телефон
ui-book-empty = Адресна книга порожня. Клацніть «Новий контакт», щоб додати когось, або імпортуйте файл vCard чи CSV з меню «Файл».
ui-book-no-match = Немає контактів, що відповідають «{ $words }».
ui-book-delete-ask = { $count ->
    [1] Видалити цей контакт з адресної книги?
   *[other] Видалити ці контакти ({ $count }) з адресної книги?
}
ui-group-delete-ask = Видалити групу «{ $name }»? Її контакти залишаться в адресній книзі.
ui-book-no-address = У контакту «{ $name }» немає адреси електронної пошти.
ui-new-contact-title = Новий контакт
ui-contact-title = Властивості: { $name }
ui-contact-first = Ім’я:
ui-contact-last = Прізвище:
ui-contact-display = Ім’я для відображення:
ui-contact-nickname = Псевдонім:
ui-contact-company = Компанія:
ui-contact-addresses = Адреси електронної пошти:
ui-contact-address-hint = Введіть адресу електронної пошти
ui-contact-add = &Додати
ui-contact-set-default = Зробити &основною
ui-contact-default = { $address } (основна)
ui-contact-phones = Номери телефонів:
ui-phone-home = Домашній
ui-phone-work = Робочий
ui-phone-mobile = Мобільний
ui-phone-other = Інший
ui-contact-notes = Нотатки:
ui-contact-name-needed = Введіть ім’я або адресу електронної пошти контакту.
ui-contact-address-invalid = «{ $address }» не є дійсною адресою електронної пошти.
ui-contact-not-saved = Не вдалося зберегти контакт: { $reason }
ui-new-group-title = Нова група
ui-group-title = Властивості: { $name }
ui-group-name = Назва групи:
ui-group-members = Учасники:
ui-group-select-members = &Вибрати учасників...
ui-group-new-member = Додати адресу електронної пошти, якої немає в адресній книзі:
ui-group-name-needed = Введіть назву групи.
ui-group-not-saved = Не вдалося зберегти групу: { $reason }
ui-group-members-count = { $count ->
    [one] { $count } учасник
    [few] { $count } учасники
    [many] { $count } учасників
   *[other] { $count } учасника
}
ui-select-recipients = Вибрати одержувачів
ui-select-members = Вибрати учасників групи
ui-pick-intro = Введіть ім’я або виберіть його зі списку:
ui-pick-recipients = Одержувачі повідомлення:
ui-pick-members = Учасники групи:
ui-pick-to = &Кому →
ui-pick-cc = Ко&пія →
ui-pick-bcc = П&рихована →
ui-pick-add = &Додати →
ui-pick-tip = Вибрати одержувачів з адресної книги
ui-filter-address-books = Адресні книги (vCard, CSV)
ui-filter-vcard = Файли vCard
ui-book-export-name = Адресна книга
ui-book-imported = { $added ->
    [one] Додано { $added } контакт
    [few] Додано { $added } контакти
    [many] Додано { $added } контактів
   *[other] Додано { $added } контакту
}, { $skipped ->
   *[other] пропущено вже наявних в адресній книзі: { $skipped }.
}
ui-book-not-imported = Не вдалося імпортувати адресну книгу: { $reason }
ui-book-exported = { $count ->
    [one] { $count } контакт збережено у файлі «{ $file }».
    [few] { $count } контакти збережено у файлі «{ $file }».
    [many] { $count } контактів збережено у файлі «{ $file }».
   *[other] { $count } контакту збережено у файлі «{ $file }».
}
ui-book-not-exported = Не вдалося зберегти адресну книгу: { $reason }
ui-code-copied = Код скопійовано
ui-codes-in-notifications = &Показувати коди входу в сповіщеннях про нову пошту
ui-tool-unread-only = Непрочитані
ui-no-unread = Тут немає непрочитаних повідомлень.
ui-pictures-always-sender = Завжди завантажувати зображення. Відправник: { $sender }
ui-pictures-always-domain = Завжди завантажувати зображення від усіх із домену { $domain }
ui-pictures-unconfirmed = Домен відправника ({ $domain }) не вдалося перевірити, тому зображення в цьому повідомленні не завантажуються автоматично.
ui-pictures-always-option = За&вантажувати зображення в усіх повідомленнях
ui-pictures-always-warning = Завантаження зображень може повідомити відправникам, коли ви читаєте їхні повідомлення.
ui-protection-details = &Подробиці...
ui-protection-details-title = Відомості про захист
ui-download-heading = Завантаження
ui-download-ahead = Завантажувати &повідомлення заздалегідь:
ui-download-ahead-recent = Нещодавні повідомлення розміром до 1 МБ кожне
ui-download-ahead-all = Усі повідомлення
ui-download-ahead-never = Лише під час відкриття
ui-download-limit = &Ліміт кешу на обліковий запис:
ui-send-delay = Затримка перед &надсиланням:
ui-send-delay-note = Поки триває відлік, можна скористатися командою «Скасувати», щоб зупинити надсилання.
ui-dark-messages = Показувати повідомлення на темному тлі, коли система в темному режимі
ui-preview-show = Показувати вк&ладення в повідомленнях
ui-preview-show-note = Показує зображення та перші сторінки PDF-файлів після тексту повідомлення. Inbox Classic створює їх локальні зображення без виконання сценаріїв із файлів.
ui-preview-pdfs = Показувати PDF-&файли в повідомленнях
ui-sending-in = До надсилання повідомлення { $subject }: { $count ->
    [one] { $count } секунда
    [few] { $count } секунди
    [many] { $count } секунд
   *[other] { $count } секунди
}
ui-send-undone = { $subject } не надіслано. Повідомлення знову відкрито для редагування.
ui-send-too-late = Надсилання повідомлення { $subject } вже не можна скасувати.
ui-outbox-status-undo = Надсилання заплановано на { $time }
ui-download-note = Заздалегідь завантажені повідомлення відкриваються одразу. Якщо ліміт кешу перевищено, найстаріші локальні копії вмісту видаляються. За потреби вони завантажуються знову, пошта на сервері залишається. Чернетки та повідомлення, відкриті після запуску програми, зберігаються, тому ліміт може бути перевищено.
ui-attachment-downloading = Це повідомлення ще не завантажилося повністю. Спробуйте знову, коли завантаження завершиться.
ui-trusted-senders-button = &Довірені відправники...
ui-trusted-senders-title = Довірені відправники
ui-trusted-senders-note = Зображення від цих відправників завантажуються автоматично, якщо поштовий провайдер підтвердив домен відправника. Це не стосується небажаної пошти; для зашифрованих частин щоразу потрібен окремий дозвіл.
ui-trusted-everyone-at = Усі з домену { $domain }
ui-trusted-senders-empty = Довірених відправників ще не додано.
ui-search-encrypted = Шукати в за&шифрованих повідомленнях
ui-search-encrypted-note = Якщо доступні потрібні закриті ключі, Inbox Classic розшифровує завантажені повідомлення на цьому комп’ютері. Їхній текст стає доступним для пошуку, а захищені теми з’являються у списку. Розшифровані дані зберігаються в локальному індексі без шифрування; ШІ-агенти не можуть шукати в них. Вимкнення параметра видаляє ці дані з індексу та повертає зовнішні теми у список.
ui-pgp-keyserver = Шукати &ключі на keys.openpgp.org
ui-pgp-keyserver-note = Пошук ключа одержувача спочатку перевіряє домен його адреси, а потім передає адресу на keys.openpgp.org. Під час пошуку ключа підпису передається відбиток або ідентифікатор ключа. Пошук відбувається під час шифрування або за вашим запитом.
ui-eml-default = &Відкривати файли .eml в Inbox Classic
ui-eml-default-done = Тепер Inbox Classic відкриває файли .eml.
ui-eml-default-failed = Не вдалося зробити Inbox Classic типовою програмою для файлів .eml: { $reason }
ui-folders = Папки
ui-sorted-by = Сортування: { $field }
ui-layout-label = &Макет:
ui-columns-note = Вікно досить широке для макета зі стовпцями. Макет можна змінити в меню Вигляд > Макет.
ui-row-unread = Непрочитане
ui-row-flagged = З прапорцем
ui-row-attachments = Має вкладення
ui-row-encrypted = Зашифровано
ui-row-signed = Підписано
ui-row-messages = { $count ->
    [one] { $count } повідомлення
    [few] { $count } повідомлення
    [many] { $count } повідомлень
   *[other] { $count } повідомлення
}
ui-list-pictures = &Показувати зображення відправників у списку повідомлень
ui-list-pictures-note = У макеті зі стовпцями показує логотипи брендів або зображення з адресної книги для відправників із підтвердженим доменом. Якщо зображення немає, показує ініціали. Логотипи зберігаються в кеші й періодично оновлюються; завантажувати їх для кожного повідомлення не потрібно.
ui-card-picture = Зображення:
ui-card-picture-choose = Ви&брати...
ui-picture-not-picture = Не вдалося прочитати зображення. Виберіть файл PNG або JPEG.
ui-picture-too-large = Зображення завелике. Виберіть файл розміром до 10 МБ, із шириною та висотою до 8000 пікселів.
## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
ui-keys-title = Ключі шифрування
ui-keys-intro = Ваші ключі дають змогу підписувати повідомлення й розшифровувати пошту, надіслану вам. Ключі контактів потрібні для перевірки їхніх підписів і шифрування пошти для них.
ui-keys-empty = Ключів ще немає. Клацніть «Новий ключ», щоб створити свій, або «Імпортувати», щоб додати наявний ключ.
ui-keys-col-name = Назва
ui-keys-col-address = Адреса
ui-keys-col-kind = Тип
ui-keys-col-status = Стан
ui-keys-kind-own = Ваш ключ
ui-keys-kind-contact = Контакт
ui-keys-status-verified = { $status }, власника підтверджено
ui-keys-new = &Новий ключ...
ui-keys-import = &Імпортувати...
ui-keys-export = &Експортувати...
ui-keys-backup = &Резервна копія...
ui-keys-verify = &Перевірити...
ui-keys-new-title = Новий ключ
ui-keys-new-for = Створити ключ для:
ui-keys-new-make = &Створити ключ
ui-keys-no-account = Спершу додайте поштовий обліковий запис: ключ створюється для адрес облікового запису.
ui-keys-memory-only = Паролі зберігаються лише в пам’яті, тому закритий ключ, створений чи імпортований зараз, не можна буде використати після закриття Inbox Classic.
ui-keys-backup-offer = Новий ключ готовий. Зберегти його резервну копію зараз? Якщо комп’ютер буде втрачено або його дані стерто під час скидання, відновити ключ можна буде лише з резервної копії.
ui-keys-backup-now = &Зберегти резервну копію...
ui-keys-later = &Пізніше
ui-keys-backup-title = Резервна копія ключа
ui-keys-backup-intro = Резервну копію захищено парольною фразою. Зберігайте файл і парольну фразу в різних надійних місцях: для відновлення ключа потрібні обидва.
ui-keys-passphrase = &Парольна фраза:
ui-keys-passphrase-again = &Введіть її ще раз:
ui-keys-passphrase-differ = Парольні фрази не збігаються.
ui-keys-passphrase-short = Використайте парольну фразу щонайменше з 8 символів.
ui-keys-backup-saved = Резервну копію збережено.
ui-keys-import-title = Імпортувати ключ
ui-keys-import-passphrase = Цей закритий ключ захищено парольною фразою. Введіть її, щоб імпортувати ключ:
ui-keys-file-filter = Ключі OpenPGP
ui-keys-use-for = Використовувати цей ключ для адрес: { $addresses }? Ви зможете підписувати ним повідомлення з цих адрес і розшифровувати тут пошту, зашифровану для цього ключа.
ui-keys-use = &Використовувати
ui-keys-not-now = &Не зараз
ui-keys-remove-own = Вилучити ваш ключ { $fingerprint }? Повідомлення, зашифровані для нього, не можна буде розшифрувати, доки ви знову не імпортуєте резервну копію ключа.
ui-keys-remove-contact = Вилучити ключ контакту «{ $name }»? Цей ключ більше не використовуватиметься для перевірки підписів і шифрування повідомлень, доки ви знову його не додасте.
ui-key-properties-title = Властивості ключа
ui-key-names = Імена:
ui-key-fingerprint = Відбиток:
ui-key-status = Стан:
ui-key-created = Створено:
ui-key-expires = Дійсний до:
ui-key-never = Безстроково
ui-key-algorithm = Алгоритм:
ui-key-source = Джерело:
ui-key-addresses = Адреси:
ui-key-address-verified = { $address } (власника підтверджено)
ui-key-address-not-verified = { $address } (власника не підтверджено)
ui-verify-title = Перевірити ключ
ui-verify-intro = Особисто або телефоном попросіть власника ключа «{ $name }» прочитати його відбиток зі своєї програми. Не порівнюйте з відбитком, надісланим електронною поштою: той, хто міг підмінити ключ, міг підмінити й повідомлення.
ui-verify-fingerprint = Відбиток ключа, який маєте ви:
ui-verify-marks = { $count ->
    [0] У ключі немає адрес електронної пошти, тому підтвердження власника не можна зберегти.
    [1] Якщо відбитки збігаються, буде підтверджено власника ключа для адреси { $addresses }. Якщо адреса не належить цій людині, натисніть «Відрізняються».
   *[other] Якщо відбитки збігаються, буде підтверджено власника ключа для адрес: { $addresses }. Якщо хоча б одна адреса не належить цій людині, натисніть «Відрізняються».
}
ui-verify-match = &Збігаються
ui-verify-differ = &Відрізняються
ui-verify-differs = Ваш ключ відрізняється від ключа контакту «{ $name }». Вилучіть його й попросіть контакт надіслати свій ключ знову.
ui-verify-unmark = &Скасувати підтвердження власника
ui-account-security = Безпека
ui-account-security-intro = Ключ дає змогу підписувати ваші повідомлення та отримувати зашифровану пошту.
ui-account-key = &Ключ для цього облікового запису:
ui-account-key-none = Немає
ui-account-key-new = &Новий ключ...
ui-account-autocrypt = Надсилати мі&й відкритий ключ разом із повідомленнями (Autocrypt)
ui-contact-key = Ключ шифрування:
ui-contact-key-none = Немає ключа
ui-contact-key-use-new = Використати &новий ключ
ui-contact-key-keep = &Залишити поточний
ui-recipient-keys-title = Ключі одержувачів
ui-recipient-col-recipient = Одержувач
ui-recipient-col-key = Ключ
ui-recipient-find-key = Знайти &ключ
ui-recipient-remove = &Вилучити з повідомлення
ui-send-unencrypted = Надіслати &без шифрування
ui-compose-make-key = Ст&ворити ключ...
ui-compose-show-keys = &Ключі шифрування...
ui-compose-encrypt-off = &Вимкнути шифрування
ui-compose-keep-encrypted = &Залишити зашифрованим
ui-setup-export-title = Експорт параметрів і облікових записів
ui-setup-import-title = Імпорт параметрів і облікових записів
ui-setup-export-intro = Виберіть, що перенести на інший комп’ютер. Файл не містить повідомлень. На іншому комп’ютері можна знову завантажити пошту із сервера; повідомлення, збережені лише локально, не переносяться.
ui-setup-use-passphrase = &Захистити файл парольною фразою
ui-setup-passphrase-note = Парольна фраза шифрує файл і дає змогу включити доступні збережені паролі, інші дані для входу та закриті ключі з вибраних розділів. Без неї на іншому комп’ютері потрібно буде знову ввійти в облікові записи, зокрема через браузер.
ui-setup-export-button = &Експортувати...
ui-setup-file-filter = Параметри й облікові записи Inbox Classic
ui-setup-ask-passphrase = Цей файл захищено парольною фразою. Введіть її, щоб побачити, що містить файл:
ui-setup-import-intro = Виберіть, що імпортувати. Облікові записи, що вже є на цьому комп’ютері, залишаться без змін.
ui-setup-from = Збережено програмою Inbox Classic { $version }. Дата: { $date }.
ui-setup-import-button = &Імпортувати
ui-setup-done = Готово
ui-setup-first-run = Імпортувати параметри й облікові записи з іншого комп’ютера...
