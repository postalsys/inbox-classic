# Русский. Черновик, ожидает проверки носителем языка (см. core/locales/GLOSSARY.md).

## The menus

menu-file = &Файл
menu-edit = &Правка
menu-view = &Вид
menu-tools = С&ервис
menu-message = &Сообщение
menu-help = Спр&авка
menu-layout = &Макет
menu-sort-by = &Сортировка
menu-text-size = &Размер текста
menu-folder = Пап&ка
menu-insert = Вс&тавка

## The commands of the menus, the toolbar and the tray (core/commands.toml)

cmd-new-account = &Новая учетная запись...
cmd-exit = &Выход
cmd-sync = &Отправить и получить для всех учетных записей
cmd-mark-read = Пом&етить как прочитанное
cmd-mark-unread = Пометить как &непрочитанное
cmd-pictures = Загрузить изо&бражения
cmd-about = &О программе Inbox Classic
cmd-new-mail = &Создать сообщение
cmd-reply = Ответить отп&равителю
cmd-reply-all = О&тветить всем
cmd-forward = &Переслать
cmd-help = &Содержание
cmd-delete = &Удалить сообщение
cmd-move = Пере&местить в папку...
cmd-flag = П&ометить флажком
cmd-new-folder = Н&овая папка...
cmd-rename-folder = Переи&меновать папку...
cmd-delete-folder = &Удалить папку
cmd-empty-folder = О&чистить папку
ui-empty-button = Очистить
cmd-accounts = Учетные &записи...
cmd-find = Н&айти сообщение
cmd-save-as = С&охранить как...
cmd-print = Печ&ать...
cmd-print-conversation = Печать &беседы...
cmd-import = &Импорт сообщений...
cmd-outbox = &Исходящие...
cmd-properties = &Свойства
cmd-mark-all-read = Помет&ить все как прочитанные
cmd-junk = Помет&ить как нежелательное
cmd-not-junk = Пометить как о&бычное
cmd-archive = &В архив
cmd-watch-conversation = С&ледить за беседой
cmd-ignore-conversation = И&гнорировать беседу
cmd-next-message = С&ледующее сообщение
cmd-previous-message = Пр&едыдущее сообщение
cmd-next-unread = Следующее &непрочитанное
cmd-go-to-folder = Пере&йти в папку...
cmd-find-in-message = Найти в &этом сообщении...
ui-go-to-prompt = Перейти в папку:
ui-find-in-message-hint = Найти в этом сообщении
ui-find-not-found = «{ $words }» нет в этом сообщении
cmd-expand-all-threads = Ра&звернуть все беседы
cmd-collapse-all-threads = Сверну&ть все беседы
ui-group-by-conversation = &Группировать сообщения по беседам
ui-show-whole-conversation = Показывать всю бесе&ду в области чтения
ui-show-whole-conversation-note = Открывайте сообщения беседы вместе, включая свои ответы, черновики и сообщения в других папках. Прочитанные сообщения обычно свернуты в строку; щелкните строку, чтобы развернуть или свернуть сообщение.
ui-conversation-order = Поряд&ок сообщений в беседе:
ui-conversation-oldest-first = Сначала старые
ui-conversation-newest-first = Сначала новые
ui-thread-count = { $new ->
    [0] ({ $count })
    [one] ({ $count }, { $new } новое)
    [few] ({ $count }, { $new } новых)
    [many] ({ $count }, { $new } новых)
   *[other] ({ $count }, { $new } нового)
}
ui-conversation-to = кому: { $people }
ui-conversation-draft = Черновик
ui-conversation-alone = Подписано или зашифровано: открывается отдельно
ui-conversation-downloading = Загрузка…
ui-conversation-earlier = { $count ->
    [one] Показать { $count } более раннее сообщение
    [few] Показать { $count } более ранних сообщения
    [many] Показать { $count } более ранних сообщений
   *[other] Показать { $count } более раннего сообщения
}
ui-conversation-elsewhere = { $count ->
    [one] В этой беседе есть еще { $count } сообщение в другой папке.
    [few] В этой беседе есть еще { $count } сообщения в других папках.
    [many] В этой беседе есть еще { $count } сообщений в других папках.
   *[other] В этой беседе есть еще { $count } сообщения в других папках.
}
ui-conversation-this-folder = &Только эта папка
ui-conversation-whole = &Вся беседа
cmd-folder-list = Список &папок
cmd-layout-automatic = &Автоматический
cmd-layout-classic = &Классический
cmd-layout-columns = В &столбцах
cmd-sort-date = &Дата
cmd-sort-from = &Отправитель
cmd-sort-subject = &Тема
cmd-sort-size = &Размер
cmd-sort-ascending = По &возрастанию
cmd-sort-descending = По &убыванию
cmd-text-size-largest = &Самый крупный
cmd-text-size-larger = &Крупный
cmd-text-size-medium = С&редний
cmd-text-size-smaller = &Мелкий
cmd-text-size-smallest = Самый ме&лкий
cmd-hide-ignored = Скрыть &игнорируемые беседы
cmd-hide-read = Скрыть пр&очитанные сообщения
cmd-notify = &Уведомлять о новой почте
cmd-open = О&ткрыть Inbox Classic
cmd-default-app = Сделать почтовой программой по умол&чанию...
cmd-view-source = Ис&ходный текст сообщения
cmd-ai-agents = ИИ-а&генты...
cmd-options = Пара&метры...
cmd-message-rules = &Правила для сообщений...
cmd-encryption-keys = &Ключи шифрования...
cmd-create-rule-from-message = Со&здать правило из сообщения...
cmd-unsubscribe = Отпис&аться от рассылки...
cmd-select-all = В&ыделить все
cmd-undo = О&тменить
cmd-copy = &Копировать в папку...
cmd-address-book = &Адресная книга...
cmd-add-sender-to-book = &Добавить отправителя в адресную книгу
cmd-import-address-book = Импорт адресной кни&ги...
cmd-export-address-book = &Экспорт адресной книги...
cmd-export-setup = Экспорт нас&троек и учетных записей...
cmd-import-setup = Импорт наст&роек и учетных записей...
cmd-compose-sign = &Подписать цифровой подписью
cmd-compose-encrypt = &Зашифровать
cmd-attach-my-key = Вложить свой &открытый ключ

## The tray icon's menu

tray-check = &Проверить почту
tray-no-accounts = Учетных записей пока нет

## Words the windows of more than one platform share

ui-tb-create-mail = Создать сообщение
ui-tb-reply = Ответить
ui-tb-reply-all = Ответить всем
ui-tb-forward = Переслать
ui-tb-print = Печать
ui-tb-delete = Удалить
ui-tb-junk = Нежелательное
ui-tb-not-junk = Обычное
ui-tb-archive = В архив
ui-tb-previous = Назад
ui-tb-next = Далее
ui-previous-tip = Предыдущее сообщение
ui-next-tip = Следующее сообщение
ui-tb-sync = Отправить/получить
ui-tb-mark-read = Прочитано
ui-tb-mark-unread = Не прочитано
ui-still-running = Inbox Classic продолжает работать
ui-no-subject = (без темы)
ui-quoted = «{ $subject }»
ui-newest-from = Последнее сообщение: { $subject } (отправитель: { $sender })
ui-new-messages = { $count ->
    [one] { $count } новое сообщение
    [few] { $count } новых сообщения
    [many] { $count } новых сообщений
   *[other] { $count } нового сообщения
}
ui-outbox-waiting = { $count ->
    [one] { $count } сообщение в папке «Исходящие»
    [few] { $count } сообщения в папке «Исходящие»
    [many] { $count } сообщений в папке «Исходящие»
   *[other] { $count } сообщения в папке «Исходящие»
}
ui-outbox-waits = Ожидает отправки в папке «Исходящие»: { $subject }
ui-outbox-sending = Отправка { $subject }...
ui-from-account = С учетной записи «{ $account }»
ui-sign-in-refused = Вход в учетную запись «{ $account }» отклонен или срок действия сеанса истек.
ui-sign-in-again-ask = Войти снова через браузер?
ui-sign-in-again-failed = Не удалось войти снова: { $reason }
ui-unknown-reason = неизвестная причина
ui-checking = Проверка новой почты в учетной записи «{ $account }»...
ui-done = Готово
ui-sent-at = Отправлено в { $time }: { $subject }
ui-draft-saved = Сообщение сохранено в папке «Черновики»
ui-draft-not-saved = Сообщение не сохранено в папке «Черновики»: { $reason }
ui-about-core = Ядро { $version }
ui-add-account-first = Сначала добавьте почтовую учетную запись.
ui-add-account-first-link = Сначала добавьте почтовую учетную запись, затем снова щелкните ссылку на адрес электронной почты.
ui-default-app-is = Inbox Classic используется для почты по умолчанию: при нажатии на ссылку с адресом электронной почты здесь открывается новое сообщение.
ui-select-message-first = Сначала выберите сообщение.
ui-store-not-opened = Не удалось открыть хранилище почты.
ui-store-or-cert-not-opened = Не удалось открыть хранилище почты или файл сертификата.
ui-help-title = Справка Inbox Classic
ui-help-missing = В этой копии Inbox Classic нет справки.
ui-ok = ОК
ui-cancel = Отмена
ui-close = Закрыть
ui-col-subject = Тема
ui-col-from = Отправитель
ui-col-to = Кому
ui-col-received = Получено
ui-watched-conversation = Отслеживаемая беседа
ui-col-sent = Отправлено
ui-col-size = Размер
ui-col-folder = Папка
ui-col-account = Учетная запись
ui-col-queued = В очереди с
ui-col-status = Состояние
ui-outbox-title = Исходящие
ui-outbox-status-waiting = Ожидает
ui-outbox-status-not-sent = Не отправлено: { $reason }
ui-outbox-status-agent = Поставлено в очередь ИИ-агентом; отправка не раньше { $time }
ui-outbox-delete-ask = Удалить это сообщение, не отправляя его?
ui-open-link = Открыть ссылку
ui-edit-link = Изменить ссылку...
ui-remove-link = Удалить ссылку
ui-insert-attachment = Вложить файл
ui-insert-picture = Вставить изображение
ui-filter-all = Все файлы
ui-filter-pictures = Изображения
ui-filter-messages = Почтовые сообщения
ui-save-attachment-as = Сохранить вложение как
ui-not-sent = Не удалось отправить сообщение.
ui-attachment-forgotten = Вы написали «{ $word }», но файл не вложен. Все равно отправить сообщение?
ui-send-anyway = Все равно отправить
ui-go-back = Вернуться
ui-not-saved = Не удалось сохранить сообщение.
ui-saving-draft = Сохранение в папку «Черновики»...
ui-compose-saved-at = Сохранено в папке «Черновики» в { $time }
ui-compose-restored = Восстановлено после неожиданного закрытия Inbox Classic
ui-compose-not-saved = Не сохранено в папке «Черновики»: { $reason }
ui-save-changes-ask = Сохранить изменения этого сообщения в папке «Черновики»?
ui-new-message-title = Новое сообщение
ui-link-invalid = Введите веб-адрес (https://...) или ссылку на адрес электронной почты (mailto:...).
ui-link-address = Адрес:
ui-hyperlink = Гиперссылка
ui-hyperlink-intro = Адрес, на который ссылается выделенный текст.
ui-edit-hyperlink = Изменить гиперссылку
ui-edit-hyperlink-intro = Адрес, на который ведет ссылка. Очистите адрес, чтобы удалить ссылку и оставить текст.
ui-not-a-picture = Не удалось вставить изображение. Поддерживаются файлы PNG, JPEG, GIF и WebP размером не более 10 МБ.
ui-format-color = Цвет шрифта
ui-format-numbers = Нумерованный список
ui-format-bullets = Маркированный список
ui-format-outdent = Уменьшить отступ
ui-format-indent = Увеличить отступ
ui-format-left = По левому краю
ui-format-center = По центру
ui-format-right = По правому краю
ui-format-line = Вставить горизонтальную линию
ui-tb-send = Отправить
ui-tb-save = Сохранить
ui-tb-attach = Вложить
ui-tb-sign = Подписать
ui-tb-encrypt = Зашифровать
ui-field-keys = Ключи:
ui-field-from = От:
ui-field-to = Кому:
ui-field-cc = Копия:
ui-field-bcc = Скрытая:
ui-field-subject = Тема:
ui-field-attach = Вложения:
ui-signature = Текстовая подпись
ui-signature-hint = Добавляется к новым сообщениям, ответам и пересылкам с этой учетной записи.
ui-signature-not-saved = Не удалось сохранить текстовую подпись.
ui-all-inboxes = Все входящие
ui-all-sent = Все отправленные
ui-all-drafts = Все черновики
ui-flagged-folder = С флажком
ui-all-folders = Все папки
ui-the-account = учетную запись
ui-folder-name = Имя папки:
ui-find-hint = Поиск в почте
ui-find-tip = Поиск по темам и тексту сообщений, именам и адресам отправителей и получателей, а также именам вложений.
ui-clear-search = Очистить поиск
ui-no-match = По запросу «{ $words }» сообщений не найдено.
ui-no-match-all = Поиск выполняется во всех папках по темам и тексту сообщений, именам и адресам отправителей и получателей, а также именам вложений. Проверьте написание или введите меньше слов.
ui-no-match-in = Область поиска: «{ $folder }». Поиск выполняется по темам и тексту сообщений, именам и адресам отправителей и получателей, а также именам вложений. Проверьте написание или введите меньше слов.
ui-no-items = Здесь нет сообщений.
ui-choose-folder = Выберите папку, чтобы просмотреть сообщения в ней.
ui-unsubscribe = Отписаться
ui-open-in-calendar = Открыть в календаре
ui-pictures-blocked = Некоторые изображения заблокированы для защиты от отслеживания отправителем.
ui-not-shown = Не удалось отобразить сообщение.
ui-attachment-not-read = Не удалось прочитать вложение.
ui-attachment-not-saved = Не удалось сохранить вложение.
ui-not-downloaded = Сообщение еще не загружено.
ui-leave-list = Отписаться от этой рассылки?
ui-leave-one-click = Inbox Classic отправит запрос на отписку по адресу { $target }. Веб-страница не откроется, и сообщение по электронной почте отправлено не будет.
ui-leave-mail = Чтобы отписаться, отправьте сообщение по адресу { $target }. Inbox Classic подготовит его для вас. Отправьте это сообщение, чтобы подтвердить отписку.
ui-leave-web = Страница отписки от рассылки откроется в браузере ({ $target }).
ui-unsubscribing = Отправка запроса на отписку: { $target }...
ui-cannot-unsubscribe = В этом сообщении нет ссылки или адреса для отписки.
ui-unsubscribed = Запрос на отписку принят.
ui-not-unsubscribed = Не удалось отписаться: { $reason }
ui-list-bar = Это сообщение из рассылки ({ $domain }).
ui-list-bar-plain = Это сообщение из рассылки.
ui-list-bar-asked = Вы попросили отписать вас от этой рассылки { $date }.
ui-list-bar-came-after = Вы запросили отписку { $date }, но это сообщение пришло более чем через два дня.
ui-list-bar-opened = Вы открыли страницу отписки от этой рассылки { $date }.
ui-list-bar-failed = Не удалось выполнить запрос на отписку: { $reason }
ui-unsubscribe-ask = Отписаться…
ui-unsubscribe-again = Отписаться снова…
ui-event-span = с { $start } до { $end }
ui-event-floating = { $when } (время из приглашения, без пересчета в ваш часовой пояс)
ui-invitation = Приглашение: { $title }
ui-invitation-updated = Обновленное приглашение: { $title }
ui-invitation-canceled = Отменено: { $title }
ui-invitation-answer = Ответ на приглашение: { $title }
ui-no-title = (без названия)
ui-organizer = Организатор: { $name }
ui-invitation-not-read = Не удалось прочитать приглашение.
ui-no-calendar = Не удалось открыть приглашение в календаре. Проверьте, установлена ли программа для открытия файлов .ics.
ui-messages-not-changed = Не удалось изменить сообщения.
ui-new-folder-in-selected = Новая папка будет создана внутри выбранной папки.
ui-new-folder-at-top = Новая папка будет создана на верхнем уровне учетной записи.
ui-folder-not-created = Не удалось создать папку.
ui-folder-not-renamed = Не удалось переименовать папку.
ui-folder-not-deleted = Не удалось удалить папку.
ui-rename-folder-intro = Введите новое имя для папки «{ $folder }».
ui-properties-of = Свойства: { $subject }
ui-internet-headers = Служебные заголовки сообщения:
ui-save-messages-in = Папка для сохранения сообщений
ui-save-message-as = Сохранить сообщение как
ui-import-choose-folder = Сначала выберите папку, в которую нужно импортировать сообщения.
ui-add-account-title = Добавить почтовую учетную запись
ui-accounts-title = Учетные записи
ui-security-none = Нет (без шифрования)
ui-field-required = Заполните поле «{ $field }».
ui-email-invalid = Недопустимый адрес электронной почты.
ui-ports-invalid = Порт задается числом от 1 до 65535.
ui-looking-up = Поиск параметров для { $domain }...
ui-found-none = Введите данные учетной записи, предоставленные вашим почтовым провайдером.
ui-found-change = Измените эти параметры, если провайдер указал другие.
ui-found-guess = Для этого адреса не удалось найти параметры. Имена серверов подобраны автоматически и могут быть неверными. Уточните их у провайдера.
ui-found-mx = Inbox Classic распознала вашего почтового провайдера и заполнила параметры его серверов.
ui-found-srv = Эти параметры найдены в записях DNS вашего домена.
ui-found-autodiscover = Эти параметры найдены с помощью Microsoft Autodiscover (Exchange).
ui-found-other = Для этого адреса найдены эти параметры.
ui-app-password-needed = Поставщик: { $provider }. Если ваша учётная запись поддерживает пароли приложений, создайте такой пароль в её настройках безопасности и введите его в поле «Пароль» в следующей форме. Иначе войдите через браузер, если это возможно.
ui-app-password-open = Открыть инструкции { $provider } в браузере?
ui-plain-warning = Без шифрования любой, кто перехватывает ваш сетевой трафик, может прочитать ваш пароль и сообщения. Продолжайте только при защите подключения другим способом; сама по себе локальная сеть не обеспечивает шифрование.
ui-continue-ask = Продолжить?
ui-add-sign-in-app = Добавить приложение для входа...
ui-turned-off = Способ входа «{ $name }» отключен на этом компьютере.
ui-off-here = Отключено на этом компьютере.
ui-why = Почему?
ui-more-sign-in = Другие способы входа...
ui-other-account = Чтобы добавить другую почтовую учетную запись, введите свой адрес и имя, которое будут видеть получатели. Затем Inbox Classic попробует найти параметры серверов.
ui-field-account-name = Имя учетной записи:
ui-field-name = Отображаемое имя:
ui-field-email = Адрес электронной почты:
ui-field-user = Имя пользователя:
ui-field-password = Пароль:
ui-field-imap-host = Сервер входящей почты (IMAP):
ui-field-imap-port = Порт IMAP:
ui-field-imap-security = Защита подключения IMAP:
ui-field-smtp-host = Сервер исходящей почты (SMTP):
ui-field-smtp-port = Порт SMTP:
ui-field-smtp-security = Защита подключения SMTP:
ui-field-other-addresses = Другие адреса для отправки сообщений:
ui-sign-in-not-started = Не удалось начать вход через браузер.
ui-sign-in-in-browser = Войдите в { $account } в открывшемся окне браузера, затем вернитесь сюда.
ui-sign-in-failed = Не удалось войти: { $reason }
ui-account-not-saved = Не удалось сохранить учетную запись.
ui-start-intro = Gmail, Google Workspace, Outlook.com и Microsoft 365: войдите на странице Google или Microsoft. Пароль вы вводите на сайте провайдера, а не в Inbox Classic.
ui-start-intro-apps = Войдите через браузер с помощью приложения для входа («Другие способы входа») или добавьте почтовую учетную запись, указав ниже имя и адрес.
ui-use-app-password = Использовать пароль приложения
ui-the-provider = провайдера
ui-provider-intro = Войдите в учетную запись { $email } на сайте { $provider }. Ваш пароль не передается Inbox Classic. Если учетная запись поддерживает пароли приложений для почты, можно использовать такой пароль, созданный в ее настройках безопасности. Для Outlook.com и Microsoft 365 доступен только вход через браузер.
ui-provider-intro-apps = Войдите в учетную запись { $email } на сайте { $provider } с помощью приложения для входа («Другие способы входа»). Если учетная запись поддерживает пароли приложений для почты, можно использовать такой пароль, созданный в ее настройках безопасности. Для Outlook.com и Microsoft 365 доступен только вход через браузер.
ui-finish = Готово
ui-logon = Вход
ui-enter-password = Введите пароль учетной записи «{ $account }».
ui-signs-in-with = Приложение для входа: { $app }. Вход выполняется в браузере, и учетная запись использует серверы этого приложения.
ui-keep-password = Оставьте поле пароля пустым, чтобы сохранить текущий пароль.
ui-remove-account = Удалить учетную запись
ui-remove-account-ask = Удалить эту учётную запись из Inbox Classic? Её локальные данные, включая неотправленные сообщения и сохранённые данные для входа, будут удалены. Почта на сервере останется там.
ui-col-email = Адрес электронной почты
ui-col-incoming = Сервер входящей почты
ui-type-email = Введите адрес электронной почты, например name@example.com.
ui-ai-agent = ИИ-агент
ui-ai-agent-access = Доступ ИИ-агента
ui-ai-agents = ИИ-агенты
ui-program-path = Программа: { $path }
ui-it-may = Разрешенные действия:
ui-accounts-it-may-use = Разрешенные учетные записи:
ui-send-message-ask = Отправить сообщение?
ui-col-name = Имя
ui-never = Никогда
ui-connect-agent = Подключение ИИ-агента
ui-connect-agent-intro = Добавьте эту конфигурацию в список серверов MCP вашего агента (Claude Desktop: Settings > Developer > Edit Config):
ui-col-program = Программа
ui-col-may = Разрешения
ui-col-last-used = Последнее использование
ui-col-when = Когда
ui-col-what = Действие
ui-sign-in-app = Приложение для входа
ui-sign-in-apps = Приложения для входа
ui-add-sign-in-app-title = Добавить приложение для входа
ui-preset-app-name = Приложение для входа через { $provider }
ui-issuer-not-checked = не удалось проверить сервер авторизации
ui-checking-issuer = Проверка сервера авторизации: { $issuer }...
ui-issuer-unusable = Нельзя использовать этот сервер авторизации: { $reason }
ui-issuer-usable = Сервер авторизации можно использовать для входа.
ui-sign-in-app-not-saved = Не удалось сохранить приложение для входа: { $reason }
ui-check = &Проверить
ui-fill-in-for = Параметры для:
ui-app-name = Имя:
ui-issuer = Сервер авторизации:
ui-client-id = Идентификатор клиента:
ui-client-secret = Секрет клиента:
ui-scopes = Области доступа (scopes):
ui-imap-server = Сервер IMAP:
ui-smtp-server = Сервер SMTP:
ui-redirect-uri = URI перенаправления:
ui-sign-in-app-intro = Приложение для входа позволяет входить через браузер. Для этого зарегистрируйте клиент OAuth у своего провайдера. Выберите провайдера, чтобы заполнить параметры, затем укажите идентификатор клиента и секрет, если провайдер его выдал.
ui-remove-secret = Удалить сохраненный секрет клиента. Чтобы заменить его, введите новый секрет в поле выше
ui-register-it = Зарегистрируйте приложение у провайдера
ui-built-in-note = Приложение «{ $name }» встроено в Inbox Classic. Можно только выбрать, предлагать ли его для новых учетных записей.
ui-client-with-secret = Идентификатор клиента: { $client }. Секрет клиента сохранен.
ui-client-public = Идентификатор клиента: { $client }. Публичный клиент (без секрета).
ui-no-accounts = Нет учетных записей
ui-remove-sign-in-app = Удалить приложение для входа
ui-remove-sign-in-app-ask = Удалить приложение для входа «{ $name }» и сохраненный секрет клиента?
ui-sign-in-app-not-removed = Приложение для входа не удалено. { $reason }
ui-sign-in-apps-intro = Приложения для входа позволяют входить в почтовые учетные записи через браузер. Если снять флажок рядом с приложением, оно не будет предлагаться для новых учетных записей. Учетные записи, которые уже используют его, продолжат работать.
ui-col-issuer = Сервер авторизации
ui-col-used-by = Учетные записи
ui-options-system-default = Как в системе ({ $language })
ui-settings-general = Общие
ui-settings-reading = Чтение
ui-settings-new-mail = Новая почта
ui-settings-sending = Отправка
ui-settings-default-apps = Приложения по умолчанию
ui-settings-message-list = Список сообщений
ui-settings-messages = Сообщения
ui-settings-encryption = Шифрование
ui-settings-language = Язык
ui-settings-label = { $label }:
ui-apply = &Применить
ui-settings-sync = Синхронизация
ui-sync-note = Ваши учетные записи, ключи, адресная книга, правила и настройки будут одинаковыми на всех компьютерах. Синхронизация идет через вашу собственную папку или хранилище. Прежде чем покинуть этот компьютер, все данные шифруются парольной фразой синхронизации.
ui-sync-place = Место синхронизации:
ui-sync-status = Состояние:
ui-sync-set-up = &Настроить синхронизацию…
ui-sync-now = Синхронизировать &сейчас
ui-sync-computers = &Компьютеры…
ui-sync-history = &История…
ui-sync-turn-off = &Отключить синхронизацию…
ui-sync-what = Что синхронизировать
ui-sync-what-note = Пароли, данные для входа и закрытые ключи передаются только в зашифрованном виде. Исключите то, что должно остаться только на этом компьютере.
ui-sync-accounts = &Учетные записи
ui-sync-passwords = Па&роли
ui-sync-sign-ins = Данные &входа через Google, Microsoft и приложения для входа
ui-sync-sign-in-apps = Приложения для в&хода
ui-sync-app-secrets = Секре&ты приложений для входа
ui-sync-contacts = &Адресная книга
ui-sync-keys = Кл&ючи
ui-sync-private-keys = Ваши &закрытые ключи
ui-sync-rules = Прави&ла
ui-sync-trusted = Над&ежные отправители
ui-sync-settings = Настро&йки
ui-sync-preferences = &Макет и вид
ui-sync-everything = Все
ui-sync-some-left-out = Выбрано не все
ui-sync-where = Где хранить
ui-sync-folder = Папка
ui-sync-folder-note = Dropbox, OneDrive, iCloud Drive, Google Drive, Nextcloud или Syncthing копирует ее на другие ваши компьютеры.
ui-sync-bucket = Хранилище, совместимое с S3
ui-sync-bucket-note = Amazon S3, Cloudflare R2, Backblaze B2, MinIO или другое хранилище, которое работает как S3.
ui-sync-folder-label = &Папка:
ui-sync-folder-none = Пока не выбрана
ui-sync-choose-folder = В&ыбрать…
ui-sync-choose-folder-title = Выбор папки для синхронизации
ui-sync-endpoint = &Конечная точка:
ui-sync-region = &Регион:
ui-sync-bucket-name = &Бакет:
ui-sync-prefix = Папка в бак&ете:
ui-sync-access-key = &Идентификатор ключа доступа:
ui-sync-secret-key = &Секретный ключ доступа:
ui-sync-next = &Далее
ui-sync-join-title = Присоединение к синхронизации
ui-sync-join-note = Здесь уже хранятся синхронизированные данные. Введите парольную фразу синхронизации, выбранную на первом компьютере.
ui-sync-start-title = Начало синхронизации
ui-sync-start-note = Придумайте парольную фразу синхронизации. Ее нужно ввести один раз на каждом добавляемом компьютере. Храните ее в надежном месте: без нее другие компьютеры не смогут присоединиться.
ui-sync-name = Имя &этого компьютера:
ui-sync-merge-note = Данные этого компьютера объединяются с синхронизированными данными. Совпадающие учетные записи и контакты объединяются в одну запись.
ui-sync-turn-on = В&ключить синхронизацию
ui-sync-on = Синхронизация включена.
ui-sync-turn-off-ask = Отключить синхронизацию на этом компьютере? Все останется как есть, здесь и на других ваших компьютерах. Этот компьютер просто перестанет синхронизироваться.
ui-sync-turn-off-button = Отключить
ui-sync-computers-title = Компьютеры
ui-sync-computers-note = Эти компьютеры синхронизируются через одно и то же место. Удалите компьютер, которым больше не пользуетесь, чтобы прекратить его синхронизацию. Его синхронизированные данные сохранятся.
ui-sync-this-computer = Этот компьютер
ui-sync-seen = Последняя синхронизация: { $when }
ui-sync-remove-ask = Удалить компьютер «{ $name }» из синхронизации? Он перестанет синхронизироваться при следующей попытке. Чтобы снова синхронизировать его, настройте на нем синхронизацию заново.
ui-sync-loading = Чтение…
ui-sync-history-title = История
ui-sync-history-note = При конфликте изменений с разных компьютеров синхронизация сохраняет одну версию. Замененные значения появляются здесь; восстановите нужное значение, чтобы снова его использовать. Пароли, данные для входа и закрытые ключи здесь не сохраняются.
ui-sync-history-empty = Замененных изменений нет.
ui-sync-history-row = Источник: { $source }, { $when }
ui-sync-restore = &Восстановить
ui-sync-restore-points = Точки восстановления
ui-sync-restore-points-note = Точки восстановления сохраняют учетные записи и настройки перед тем, как синхронизация удалит элементы с этого компьютера. Откройте точку, чтобы выбрать, что восстановить.
ui-sync-restore-points-empty = Пока нет.
ui-sync-open-point = &Открыть…
# Set Up Sync on Windows: back from its second step to the first, as a wizard's Back button
win-sync-back = < &Назад
ui-language-label = &Язык:
ui-restart-note = Чтобы сменить язык, перезапустите Inbox Classic.
ui-restart-ask = Inbox Classic перейдет на язык «{ $language }» после перезапуска. Перезапустить сейчас?
ui-notify-new-mail = &Уведомлять о новой почте
ui-new-folder-title = Новая папка
ui-rename-folder-title = Переименование папки
ui-delete-folder-question = Удалить папку «{ $folder }» вместе с ее сообщениями и вложенными папками? Она будет удалена и на сервере.
ui-properties = Сво&йства
ui-account-sync = Отправить и &получить
ui-account-properties = &Свойства...
ui-account-properties-of = &Свойства учетной записи...
ui-account-move-up = &Вверх
ui-account-move-down = В&низ
ui-menu-open = &Открыть
ui-menu-flag = &Флажок
ui-menu-view-source = Ис&ходный текст
# Context menu: the same action as cmd-unsubscribe, with its own access key.
ui-menu-unsubscribe = &Отписаться от рассылки...
ui-save-attachments = Сохранить вложения
ui-attachment-open = Открыть
ui-attachment-save-as = Сохранить как...
ui-attachment-save-all = Сохранить все...
ui-attachment-show-in-message = Показать в сообщении
ui-attachments-strip = Вложения
ui-attachment-note-title = Открытие этого файла
ui-attachment-program-tip = Команда «Открыть» недоступна: файлы этого типа могут запускать программы. Чтобы открыть файл самостоятельно, сначала сохраните его.
ui-clear-flag = С&нять флажок
ui-button-move = &Переместить
ui-button-copy = &Копировать
ui-find-folder = Найти папку
ui-new-folder-in = Новая папка будет создана в папке «{ $folder }».
ui-outbox-send-all = &Отправить все сейчас
ui-yes = Да
ui-no = Нет
ui-try-again = Повторить
ui-remove = &Удалить
ui-signature-of = Текстовая подпись: { $account }
ui-sign-in-with = Войти через { $provider }
ui-sign-in-in-browser-yours = Войдите в свою учетную запись в открывшемся окне браузера, затем вернитесь сюда.
ui-browser-sign-in-server = { $server } (вход через браузер)
ui-dont-allow = Не разрешать
ui-allow = &Разрешить
ui-dont-send = Не отправлять
ui-dont-unsubscribe = Не отписываться
ui-edit-first = &Сначала изменить
ui-new-address = Новый адрес
ui-turn-away = &Отклонить
ui-clear-agent-log = Очистить журнал действий агентов?
ui-clear-agent-log-detail = Изменения, сделанные агентами, не будут отменены.
ui-let-agents-connect = &Разрешить ИИ-агентам подключаться к Inbox Classic
ui-change-button = Изменить…
ui-undo-button = Отменить
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
ui-undo-since-button = Отменить за период…
ui-undo-since-span = Отменить действия этой программы за период:
ui-take-back = Отменить действия
ui-rules-title = Правила для сообщений
ui-rules-intro = Правила обрабатывают новые сообщения в папке «Входящие», пока Inbox Classic работает. Подходящие правила применяются по порядку. Если правило перемещает сообщение из папки «Входящие», следующие правила к нему не применяются.
ui-rules-none = Правил пока нет. Чтобы добавить правило, нажмите «Создать».
ui-rule-new = &Создать...
ui-rule-edit = &Изменить...
ui-rule-delete-button = &Удалить
ui-rule-title = Правило для сообщений
ui-rule-name = Название:
ui-rule-account = Учетная запись:
ui-rule-all-accounts = Все учетные записи
ui-rule-query = Условия поиска:
ui-rule-query-hint = Используйте условия поиска, например from:ann@example.com, subject:счет или list:news.example.com, так же как в поле поиска.
ui-rule-count = { $count ->
    [one] Сейчас этим условиям соответствует { $count } сообщение в папке «Входящие».
    [few] Сейчас этим условиям соответствуют { $count } сообщения в папке «Входящие».
    [many] Сейчас этим условиям соответствуют { $count } сообщений в папке «Входящие».
   *[other] Сейчас этим условиям соответствует { $count } сообщения в папке «Входящие».
}
ui-rule-show = Пока&зать
ui-rule-actions = Действия:
ui-rule-move = &Переместить в:
ui-rule-mark-read = Пометить как прочи&танное
ui-rule-flag = Пометить &флажком
ui-rule-archive = &Архивировать
ui-rule-junk = Переместить в папку «&Нежелательная почта»
ui-rule-delete = У&далить
ui-rule-quiet = Не &уведомлять о сообщении
ui-rule-apply-now = Применить также к сообщениям, которые уже есть в папке «&Входящие»
ui-rule-delete-ask = Удалить правило «{ $name }»?
ui-create-rule = Создать правило...
ui-rules-applied = { $count ->
    [one] По правилам обработано { $count } сообщение
    [few] По правилам обработано { $count } сообщения
    [many] По правилам обработано { $count } сообщений
   *[other] По правилам обработано { $count } сообщения
}
ui-col-rule-matches = Условия
ui-clear-button = &Очистить
ui-how-to-connect = Как подключить агента…
ui-agent-programs = Программы, агенты которых запросили доступ к вашей почте
ui-what-agents-did = Действия агентов
ui-restart-now = &Перезапустить
ui-restart-later = По&зже

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

ui-tb-new-contact = Новый контакт
ui-tb-new-group = Новая группа
ui-tb-properties = Свойства
ui-tb-write-to = Написать
ui-menu-new-contact = &Новый контакт...
ui-menu-new-group = Новая &группа...
ui-menu-write-to = На&писать
ui-menu-delete = &Удалить
ui-book-find-hint = Введите имя или адрес электронной почты
ui-book-all-contacts = Все контакты
ui-col-phone = Телефон
ui-book-empty = Адресная книга пуста. Чтобы добавить контакт, нажмите «Новый контакт» или импортируйте файл vCard или CSV через меню «Файл».
ui-book-no-match = По запросу «{ $words }» контактов не найдено.
ui-book-delete-ask = { $count ->
    [1] Удалить этот контакт из адресной книги?
    [one] Удалить { $count } контакт из адресной книги?
    [few] Удалить { $count } контакта из адресной книги?
    [many] Удалить { $count } контактов из адресной книги?
   *[other] Удалить { $count } контакта из адресной книги?
}
ui-group-delete-ask = Удалить группу «{ $name }»? Ее участники останутся в адресной книге.
ui-book-no-address = У контакта «{ $name }» нет адреса электронной почты.
ui-new-contact-title = Новый контакт
ui-contact-title = Свойства: { $name }
ui-contact-first = Имя:
ui-contact-last = Фамилия:
ui-contact-display = Отображаемое имя:
ui-contact-nickname = Псевдоним:
ui-contact-company = Организация:
ui-contact-addresses = Адреса электронной почты:
ui-contact-address-hint = Введите адрес электронной почты
ui-contact-add = &Добавить
ui-contact-set-default = Сделать &основным
ui-contact-default = { $address } (основной)
ui-contact-phones = Номера телефонов:
ui-phone-home = Домашний
ui-phone-work = Рабочий
ui-phone-mobile = Мобильный
ui-phone-other = Другой
ui-contact-notes = Заметки:
ui-contact-name-needed = Введите имя или адрес электронной почты контакта.
ui-contact-address-invalid = Недопустимый адрес электронной почты: «{ $address }».
ui-contact-not-saved = Не удалось сохранить контакт: { $reason }
ui-new-group-title = Новая группа
ui-group-title = Свойства: { $name }
ui-group-name = Название группы:
ui-group-members = Участники:
ui-group-select-members = &Выбрать участников...
ui-group-new-member = Добавить адрес электронной почты, которого нет в адресной книге:
ui-group-name-needed = Введите название группы.
ui-group-not-saved = Не удалось сохранить группу: { $reason }
ui-group-members-count = { $count ->
    [one] { $count } участник
    [few] { $count } участника
    [many] { $count } участников
   *[other] { $count } участника
}
ui-select-recipients = Выбор получателей
ui-select-members = Выбор участников группы
ui-pick-intro = Введите имя или выберите его в списке:
ui-pick-recipients = Получатели сообщения:
ui-pick-members = Участники группы:
ui-pick-to = &Кому →
ui-pick-cc = К&опия →
ui-pick-bcc = &Скрытая →
ui-pick-add = &Добавить →
ui-pick-tip = Выбрать получателей из адресной книги
ui-filter-address-books = Адресные книги (vCard, CSV)
ui-filter-vcard = Файлы vCard
ui-book-export-name = Адресная книга
ui-book-imported = { $added ->
    [one] Добавлен { $added } контакт
    [few] Добавлено { $added } контакта
    [many] Добавлено { $added } контактов
   *[other] Добавлено { $added } контакта
}, { $skipped ->
   *[other] пропущено (уже есть в адресной книге): { $skipped }.
}
ui-book-not-imported = Не удалось импортировать адресную книгу: { $reason }
ui-book-exported = { $count ->
    [one] В файл «{ $file }» сохранен { $count } контакт.
    [few] В файл «{ $file }» сохранено { $count } контакта.
    [many] В файл «{ $file }» сохранено { $count } контактов.
   *[other] В файл «{ $file }» сохранено { $count } контакта.
}
ui-book-not-exported = Не удалось сохранить адресную книгу: { $reason }
ui-code-copied = Код скопирован
ui-codes-in-notifications = По&казывать коды для входа в уведомлениях о новой почте
ui-tool-unread-only = Непрочитанные
ui-no-unread = Здесь нет непрочитанных сообщений.
ui-pictures-always-sender = Всегда загружать изображения от { $sender }
ui-pictures-always-domain = Всегда загружать изображения от отправителей с адресами в домене { $domain }
ui-pictures-unconfirmed = Не удалось подтвердить домен отправителя ({ $domain }), поэтому изображения в этом сообщении не загружаются автоматически.
ui-pictures-always-option = &Загружать изображения во всех сообщениях
ui-pictures-always-warning = В этом случае отправители могут узнать, когда вы читаете их сообщения.
ui-protection-details = &Подробности...
ui-protection-details-title = Сведения о защите
ui-download-heading = Загрузка
ui-download-ahead = &Загружать сообщения заранее:
ui-download-ahead-recent = Недавние сообщения размером до 1 МБ каждое
ui-download-ahead-all = Все сообщения
ui-download-ahead-never = Только при открытии
ui-download-limit = &Лимит места для сообщений на учетную запись:
ui-send-delay = &Задержка перед отправкой:
ui-send-delay-note = Во время обратного отсчёта отправку можно отменить командой «Отменить». Эта возможность заканчивается вместе с отсчётом, даже если сообщение всё ещё ждёт отправки.
ui-dark-messages = Показывать сообщения на темном фоне, когда в системе включен темный режим
ui-preview-show = Показы&вать вложения в сообщениях
ui-preview-show-note = Показывает изображения и первые страницы PDF-файлов после текста сообщения. Inbox Classic сама создает изображения для просмотра, не выполняя код из вложений.
ui-preview-pdfs = Показывать PDF-&файлы в сообщениях
ui-sending-in = Отправка { $subject } через { $count ->
    [one] { $count } секунду
    [few] { $count } секунды
    [many] { $count } секунд
   *[other] { $count } секунды
}
ui-send-undone = Отправка отменена: { $subject }. Сообщение снова открыто для редактирования.
ui-send-too-late = Отправку сообщения { $subject } уже нельзя отменить.
ui-outbox-status-undo = Отправка не раньше { $time }
ui-download-note = Заранее загруженные сообщения открываются сразу. При превышении лимита удаляются самые старые локальные копии содержимого; при открытии их можно загрузить с сервера заново. Черновики и сообщения, открытые после запуска программы, сохраняются, даже если лимит превышен. Лимит не относится ко всей базе данных.
ui-attachment-downloading = Это сообщение еще не загружено полностью. Повторите попытку, когда загрузка завершится.
ui-trusted-senders-button = &Надежные отправители...
ui-trusted-senders-title = Надежные отправители
ui-trusted-senders-note = Изображения в сообщениях от этих отправителей загружаются автоматически, если ваш почтовый провайдер подтверждает домен отправителя.
ui-trusted-everyone-at = Все отправители с адресами в домене { $domain }
ui-trusted-senders-empty = Надежные отправители пока не добавлены.
ui-search-encrypted = Искать в за&шифрованных сообщениях
ui-search-encrypted-note = После загрузки или открытия Inbox Classic пытается расшифровать сообщение на этом компьютере с помощью доступных закрытых ключей. Если это удается, можно искать по его тексту и показывать в списке защищенную тему. Поисковый индекс не зашифрован. ИИ-агенты не ищут по расшифрованному содержимому. Отключите этот параметр, чтобы удалить расшифрованные данные из индекса.
ui-pgp-keyserver = Искать &ключи на keys.openpgp.org
ui-pgp-keyserver-note = При поиске ключа получателя сначала проверяется домен его адреса, затем при необходимости адрес передается на keys.openpgp.org. При поиске ключа подписи передается отпечаток или идентификатор ключа. Поиск выполняется при шифровании или по вашему запросу.
ui-eml-default = &Открывать файлы .eml в Inbox Classic
ui-eml-default-done = Теперь Inbox Classic открывает файлы .eml.
ui-eml-default-failed = Не удалось сделать Inbox Classic программой по умолчанию для файлов .eml: { $reason }
ui-folders = Папки
ui-sorted-by = Сортировка: { $field }
ui-layout-label = &Макет:
ui-columns-note = Окно достаточно широкое для макета «В столбцах». Макет можно изменить в меню «Вид» > «Макет».
ui-row-unread = Непрочитано
ui-row-flagged = С флажком
ui-row-attachments = Есть вложения
ui-row-encrypted = Зашифровано
ui-row-signed = Подписано
ui-row-messages = { $count ->
    [one] { $count } сообщение
    [few] { $count } сообщения
    [many] { $count } сообщений
   *[other] { $count } сообщения
}
ui-list-pictures = Показывать &изображения отправителей в списке сообщений
ui-list-pictures-note = В макете «В столбцах» показывает логотипы брендов или изображения из адресной книги для отправителей с подтвержденным доменом. Если изображения нет, отображаются инициалы. Логотипы сохраняются в кеше и периодически обновляются; загрузка не нужна для каждого сообщения.
ui-card-picture = Изображение:
ui-card-picture-choose = &Выбрать...
ui-picture-not-picture = Не удалось распознать изображение. Выберите исправный файл PNG или JPEG.
ui-picture-too-large = Изображение слишком большое. Выберите файл размером не более 10 МБ. Ширина и высота изображения не должны превышать 8000 пикселей каждая.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
ui-keys-title = Ключи шифрования
ui-keys-intro = Ваши ключи позволяют подписывать сообщения и читать почту, зашифрованную для вас. Ключи контактов нужны для проверки их цифровых подписей и шифрования сообщений, которые вы им отправляете.
ui-keys-empty = Ключей пока нет. Чтобы создать свой ключ, нажмите «Создать ключ». Чтобы добавить имеющийся ключ, нажмите «Импорт».
ui-keys-col-name = Имя
ui-keys-col-address = Адрес
ui-keys-col-kind = Тип
ui-keys-col-status = Состояние
ui-keys-kind-own = Ваш ключ
ui-keys-kind-contact = Ключ контакта
ui-keys-status-verified = { $status }, владелец ключа подтвержден
ui-keys-new = Создать &ключ...
ui-keys-import = &Импорт...
ui-keys-export = &Экспорт...
ui-keys-backup = &Резервная копия...
ui-keys-verify = &Подтвердить владельца...
ui-keys-new-title = Новый ключ
ui-keys-new-for = Создать ключ для:
ui-keys-new-make = &Создать ключ
ui-keys-no-account = Сначала добавьте почтовую учетную запись: ключ создается для ее адресов.
ui-keys-memory-only = Пароли хранятся только в памяти, поэтому закрытый ключ, созданный или импортированный сейчас, нельзя будет использовать после закрытия Inbox Classic.
ui-keys-backup-offer = Новый ключ готов. Сохранить его резервную копию сейчас? Если компьютер будет утерян или его данные будут стерты при сбросе, ключ можно будет восстановить только из резервной копии.
ui-keys-backup-now = &Сохранить резервную копию...
ui-keys-later = &Позже
ui-keys-backup-title = Резервная копия ключа
ui-keys-backup-intro = Резервная копия защищена парольной фразой. Храните файл и парольную фразу в разных надежных местах: чтобы восстановить ключ, нужно и то и другое.
ui-keys-passphrase = &Парольная фраза:
ui-keys-passphrase-again = П&овторите:
ui-keys-passphrase-differ = Парольные фразы не совпадают.
ui-keys-passphrase-short = Используйте парольную фразу длиной не менее 8 символов.
ui-keys-backup-saved = Резервная копия сохранена.
ui-keys-import-title = Импорт ключа
ui-keys-import-passphrase = Этот закрытый ключ защищен парольной фразой. Введите ее, чтобы импортировать ключ:
ui-keys-file-filter = Ключи OpenPGP
ui-keys-use-for = Использовать этот ключ для адресов { $addresses }? Вы сможете подписывать им сообщения с этих адресов и читать здесь почту, зашифрованную для этого ключа.
ui-keys-use = &Использовать
ui-keys-not-now = &Не сейчас
ui-keys-remove-own = Удалить ваш ключ { $fingerprint }? Чтобы снова расшифровывать почту этим ключом, потребуется импортировать резервную копию его закрытой части. Уже расшифрованное содержимое не удаляется.
ui-keys-remove-contact = Удалить ключ контакта «{ $name }»? Пока вы снова его не добавите, нельзя будет проверять подписи, сделанные этим ключом, или использовать его для шифрования сообщений.
ui-key-properties-title = Свойства ключа
ui-key-names = Имена:
ui-key-fingerprint = Отпечаток:
ui-key-status = Состояние:
ui-key-created = Создан:
ui-key-expires = Действителен до:
ui-key-never = Бессрочно
ui-key-algorithm = Алгоритм:
ui-key-source = Источник:
ui-key-addresses = Адреса:
ui-key-address-verified = { $address } (владелец ключа подтвержден)
ui-key-address-not-verified = { $address } (владелец ключа не подтвержден)
ui-verify-title = Подтверждение владельца ключа
ui-verify-intro = Попросите владельца ключа (контакт: { $name }) зачитать вам его отпечаток из своей программы при личной встрече или по телефону. Не сравнивайте его с отпечатком из сообщения электронной почты: тот, кто смог подменить ключ, мог подменить и этот отпечаток.
ui-verify-fingerprint = Отпечаток ключа, который есть у вас:
ui-verify-marks = { $count ->
    [0] В этом ключе нет адресов электронной почты, поэтому подтверждение владельца сохранить нельзя.
    [1] Если отпечатки совпадают, будет подтверждено, что этот ключ принадлежит владельцу адреса { $addresses }. Если адрес не принадлежит вашему собеседнику, нажмите «Различаются».
   *[other] Если отпечатки совпадают, будет подтверждено, что этот ключ принадлежит владельцу этих адресов: { $addresses }. Если хотя бы один адрес не принадлежит вашему собеседнику, нажмите «Различаются».
}
ui-verify-match = &Совпадают
ui-verify-differ = &Различаются
ui-verify-differs = Сохраненный у вас ключ отличается от ключа контакта «{ $name }». Удалите сохраненный ключ и снова запросите ключ у этого контакта.
ui-verify-unmark = С&нять подтверждение владельца
ui-account-security = Безопасность
ui-account-security-intro = Ключ позволяет подписывать ваши сообщения и получать зашифрованную почту от других людей.
ui-account-key = &Ключ для этой учетной записи:
ui-account-key-none = Нет
ui-account-key-new = &Создать ключ...
ui-account-autocrypt = &Отправлять мой открытый ключ вместе с сообщениями (Autocrypt)
ui-contact-key = Ключ шифрования:
ui-contact-key-none = Нет ключа
ui-contact-key-use-new = &Использовать новый ключ
ui-contact-key-keep = Оставить &текущий
ui-recipient-keys-title = Ключи получателей
ui-recipient-col-recipient = Получатель
ui-recipient-col-key = Ключ
ui-recipient-find-key = &Найти ключ
ui-recipient-remove = &Удалить из сообщения
ui-send-unencrypted = Отправить &без шифрования
ui-compose-make-key = &Создать ключ...
ui-compose-show-keys = &Ключи шифрования...
ui-compose-encrypt-off = &Выключить шифрование
ui-compose-keep-encrypted = Оставить &шифрование
ui-setup-export-title = Экспорт настроек и учетных записей
ui-setup-import-title = Импорт настроек и учетных записей
ui-setup-export-intro = Выберите, что перенести на другой компьютер. Сообщения в этот файл не входят. На другом компьютере снова загрузится только почта, которая есть на сервере.
ui-setup-use-passphrase = &Защитить файл парольной фразой
ui-setup-passphrase-note = Парольная фраза шифрует файл и позволяет включить доступные сохранённые данные для входа и закрытые ключи из выбранных разделов. Без этой защиты они не включаются в файл, и на другом компьютере потребуется заново войти в учётные записи.
ui-setup-export-button = &Экспорт...
ui-setup-file-filter = Настройки и учетные записи Inbox Classic
ui-setup-ask-passphrase = Этот файл защищен парольной фразой. Введите ее, чтобы увидеть содержимое файла:
ui-setup-import-intro = Выберите, что импортировать. Учетные записи, которые уже есть на этом компьютере, останутся без изменений.
ui-setup-from = Сохранено в Inbox Classic { $version }. Дата: { $date }.
ui-setup-import-button = &Импорт
ui-setup-done = Готово
ui-setup-first-run = Импортировать настройки и учетные записи с другого компьютера...
ui-first-run-other = Уже пользуетесь Inbox Classic на другом компьютере? Перенесите сюда его учетные записи и настройки.
ui-first-run-sync = Присоединиться к синхронизации…
ui-first-run-import = Импортировать из файла…

ui-field-verifiers = Доверенные источники проверки отправителя:
ui-attachment-import-key = Импорт ключа...
ui-book-key-known = Есть ключ шифрования
ui-book-key-verified = Есть ключ шифрования с подтвержденным владельцем
ui-keys-publish = Опу&бликовать...
ui-keys-publish-ask = Опубликовать ваш открытый ключ на keys.openpgp.org, чтобы другие могли его найти? Адреса в ключе: { $addresses }. Прежде чем адрес появится в каталоге, его нужно подтвердить по ссылке, отправленной на этот адрес.
ui-keys-publish-now = Опубликовать
ui-keys-paste = Импорт из бу&фера обмена
ui-keys-paste-none = В буфере обмена нет ключа OpenPGP.
ui-contact-find-key = &Найти ключ
ui-reactions-label = Реакции:
ui-reaction-open-email = Открыть письмо с реакцией
ui-reaction-show-as-email = Показать как письмо
ui-reaction-when = Реакция: { $when }
