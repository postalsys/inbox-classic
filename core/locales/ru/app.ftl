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
ui-pictures-blocked = Некоторые изображения заблокированы для защиты от отслеживания отправителем. Щелкните здесь, чтобы загрузить изображения.
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
ui-app-password-needed = { $provider } не принимает ваш обычный пароль в почтовых программах. Создайте пароль приложения в своей учетной записи { $provider } и введите его в поле «Пароль» в следующей форме.
ui-app-password-open = Открыть инструкции { $provider } в браузере?
ui-plain-warning = Без шифрования любой, кто перехватывает ваш сетевой трафик, может прочитать ваш пароль и сообщения. Используйте такое подключение только с сервером на вашем компьютере или в вашей локальной сети.
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
ui-remove-account-ask = Удалить эту учетную запись из Inbox Classic? Сообщения на сервере останутся. Данные учетной записи на этом компьютере, включая сообщения и сохраненный пароль, будут удалены.
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
ui-account-move-up = &Вверх
ui-account-move-down = В&низ
ui-menu-open = &Открыть
ui-menu-flag = &Флажок
ui-menu-view-source = Ис&ходный текст
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
# review: new
ui-how-to-connect = Как подключить агента…
# review: new
ui-agent-programs = Программы, агенты которых запросили доступ к вашей почте
# review: new
ui-what-agents-did = Действия агентов
# review: new
ui-restart-now = &Перезапустить
# review: new
ui-restart-later = По&зже

## The Address Book (Tools > Address Book), Contact and Group Properties, Select Recipients

# review: new
ui-tb-new-contact = Новый контакт
# review: new
ui-tb-new-group = Новая группа
# review: new
ui-tb-properties = Свойства
# review: new
ui-tb-write-to = Написать
# review: new
ui-menu-new-contact = &Новый контакт...
# review: new
ui-menu-new-group = Новая &группа...
# review: new
ui-menu-write-to = На&писать
# review: new
ui-menu-delete = &Удалить
# review: new
ui-book-find-hint = Введите имя или адрес электронной почты
# review: new
ui-book-all-contacts = Все контакты
# review: new
ui-col-phone = Телефон
# review: new
ui-book-empty = Адресная книга пуста. Нажмите «Новый контакт», чтобы добавить человека, или импортируйте файл vCard или CSV через меню «Файл».
# review: new
ui-book-no-match = Нет контактов, соответствующих запросу «{ $words }».
# review: new
ui-book-delete-ask = { $count ->
    [one] Удалить этот контакт из адресной книги?
   *[other] Удалить эти контакты ({ $count }) из адресной книги?
}
# review: new
ui-group-delete-ask = Удалить группу «{ $name }»? Ее участники останутся в адресной книге.
# review: new
ui-book-no-address = У контакта { $name } нет адреса электронной почты.
# review: new
ui-new-contact-title = Новый контакт
# review: new
ui-contact-title = Свойства: { $name }
# review: new
ui-contact-first = Имя:
# review: new
ui-contact-last = Фамилия:
# review: new
ui-contact-display = Отображаемое имя:
# review: new
ui-contact-nickname = Псевдоним:
# review: new
ui-contact-company = Организация:
# review: new
ui-contact-addresses = Адреса электронной почты:
# review: new
ui-contact-address-hint = Введите адрес электронной почты
# review: new
ui-contact-add = &Добавить
# review: new
ui-contact-set-default = Сделать &основным
# review: new
ui-contact-default = { $address } (основной)
# review: new
ui-contact-phones = Номера телефонов:
# review: new
ui-phone-home = Домашний
# review: new
ui-phone-work = Рабочий
# review: new
ui-phone-mobile = Мобильный
# review: new
ui-phone-other = Другой
# review: new
ui-contact-notes = Заметки:
# review: new
ui-contact-name-needed = Введите имя или адрес электронной почты контакта.
# review: new
ui-contact-address-invalid = «{ $address }» не является допустимым адресом электронной почты.
# review: new
ui-contact-not-saved = Не удалось сохранить контакт: { $reason }
# review: new
ui-new-group-title = Новая группа
# review: new
ui-group-title = Свойства: { $name }
# review: new
ui-group-name = Имя группы:
# review: new
ui-group-members = Участники:
# review: new
ui-group-select-members = &Выбрать участников...
# review: new
ui-group-new-member = Добавить адрес электронной почты, которого нет в адресной книге:
# review: new
ui-group-name-needed = Введите имя группы.
# review: new
ui-group-not-saved = Не удалось сохранить группу: { $reason }
# review: new
ui-group-members-count = { $count ->
    [one] { $count } участник
    [few] { $count } участника
    [many] { $count } участников
   *[other] { $count } участника
}
# review: new
ui-select-recipients = Выбор получателей
# review: new
ui-select-members = Выбор участников группы
# review: new
ui-pick-intro = Введите имя или выберите его в списке:
# review: new
ui-pick-recipients = Получатели сообщения:
# review: new
ui-pick-members = Участники группы:
# review: new
ui-pick-to = &Кому →
# review: new
ui-pick-cc = К&опия →
# review: new
ui-pick-bcc = &Скрытая →
# review: new
ui-pick-add = &Добавить →
# review: new
ui-pick-tip = Выбрать получателей из адресной книги
# review: new
ui-filter-address-books = Адресные книги (vCard, CSV)
# review: new
ui-filter-vcard = Файлы vCard
# review: new
ui-book-export-name = Адресная книга
# review: new
ui-book-imported = { $added ->
    [one] Добавлен { $added } контакт
    [few] Добавлено { $added } контакта
    [many] Добавлено { $added } контактов
   *[other] Добавлено { $added } контакта
}, { $skipped ->
   *[other] пропущено (уже есть в адресной книге): { $skipped }.
}
# review: new
ui-book-not-imported = Не удалось импортировать адресную книгу: { $reason }
# review: new
ui-book-exported = { $count ->
    [one] { $count } контакт сохранен в { $file }.
    [few] { $count } контакта сохранены в { $file }.
    [many] { $count } контактов сохранены в { $file }.
   *[other] { $count } контакта сохранены в { $file }.
}
# review: new
ui-book-not-exported = Не удалось сохранить адресную книгу: { $reason }
# review: new
ui-code-copied = Код скопирован
# review: changed
ui-codes-in-notifications = По&казывать коды для входа в уведомлениях о новой почте
# review: new
ui-tool-unread-only = Непрочитанные
# review: new
ui-no-unread = Здесь нет непрочитанных сообщений.
# review: new
ui-pictures-always-sender = Всегда загружать изображения от { $sender }
# review: new
ui-pictures-always-domain = Всегда загружать изображения от всех отправителей из { $domain }
# review: new
ui-pictures-unconfirmed = Не удалось проверить домен отправителя ({ $domain }), поэтому изображения в этом сообщении не загружаются автоматически.
# review: changed
ui-pictures-always-option = &Загружать изображения во всех сообщениях
# review: new
ui-pictures-always-warning = Тогда отправители смогут видеть, когда вы читаете их сообщения.
# review: new
ui-protection-details = &Подробности...
# review: new
ui-protection-details-title = Сведения о защите
# review: new
ui-download-heading = Загрузка
# review: changed
ui-download-ahead = &Загружать сообщения заранее:
# review: new
ui-download-ahead-recent = Недавние сообщения размером до 1 МБ
# review: new
ui-download-ahead-all = Все сообщения
# review: new
ui-download-ahead-never = Только при открытии
# review: changed
ui-download-limit = &Лимит хранилища на учетную запись:
# review: changed
ui-send-delay = &Задержка перед отправкой:
# review: new
ui-send-delay-note = Пока сообщение ждет отправки, ее можно отменить командой «Отменить».
# review: new
ui-dark-messages = Показывать сообщения на темном фоне, когда в системе включен темный режим
# review: new
ui-preview-show = Показывать &вложения в письмах
# review: new
ui-preview-show-note = Показывает изображения и первые страницы PDF-файлов после текста письма. Inbox Classic сам создаёт эти превью, поэтому ничто в файле не может запуститься.
# review: new
ui-preview-pdfs = Показывать PDF-&файлы в письмах
# review: new
ui-sending-in = { $subject } будет отправлено через { $count ->
    [one] { $count } секунду
    [few] { $count } секунды
    [many] { $count } секунд
   *[other] { $count } секунды
}
# review: new
ui-send-undone = { $subject } не отправлено. Сообщение снова открыто для редактирования.
# review: new
ui-send-too-late = { $subject } уже отправлено.
# review: new
ui-outbox-status-undo = Будет отправлено в { $time }
# review: new
ui-download-note = Сообщения, загруженные заранее, открываются сразу. Когда лимит хранилища превышен, самые старые локальные копии удаляются и загружаются снова при открытии.
# review: new
ui-attachment-downloading = Это сообщение еще не загружено полностью. Повторите попытку, когда загрузка завершится.
# review: changed
ui-trusted-senders-button = &Надежные отправители...
# review: new
ui-trusted-senders-title = Надежные отправители
# review: new
ui-trusted-senders-note = Изображения в сообщениях от этих отправителей загружаются автоматически, если ваш почтовый провайдер подтверждает домен отправителя.
# review: new
ui-trusted-everyone-at = Все из { $domain }
# review: new
ui-trusted-senders-empty = Надежные отправители пока не добавлены.
# review: new
ui-search-encrypted = Искать в за&шифрованных сообщениях
# review: new
ui-search-encrypted-note = Зашифрованные сообщения расшифровываются на этом компьютере после загрузки или открытия, чтобы их слова можно было найти, а список показывал их настоящую тему. Индекс не зашифрован, и агенты ИИ никогда не выполняют в нем поиск. Выключите этот параметр, чтобы удалить их из индекса.
# review: new
ui-pgp-keyserver = Искать &ключи на keys.openpgp.org
# review: new
ui-pgp-keyserver-note = Когда вы шифруете сообщение или ищете ключ, искомый адрес отправляется на keys.openpgp.org. Сначала запрос идет к домену самого адреса.
# review: changed
ui-eml-default = &Открывать файлы .eml в Inbox Classic
# review: new
ui-eml-default-done = Теперь Inbox Classic открывает файлы .eml.
# review: new
ui-eml-default-failed = Не удалось сделать Inbox Classic программой по умолчанию для файлов .eml: { $reason }
# review: new
ui-folders = Папки
# review: new
ui-sorted-by = Сортировка: { $field }
# review: changed
ui-layout-label = &Макет:
# review: new
ui-columns-note = Окно достаточно широкое для макета со столбцами. Макет можно изменить в меню Вид > Макет.
# review: new
ui-row-unread = Непрочитано
# review: new
ui-row-flagged = С флажком
# review: new
ui-row-attachments = Есть вложения
# review: new
ui-row-encrypted = Зашифровано
# review: new
ui-row-signed = Подписано
# review: new
ui-row-messages = { $count ->
    [one] { $count } сообщение
    [few] { $count } сообщения
    [many] { $count } сообщений
   *[other] { $count } сообщения
}
# review: changed
ui-list-pictures = Показывать &изображения отправителей в списке сообщений
# review: changed
ui-list-pictures-note = Показывает логотипы брендов или изображения из адресной книги для проверенных отправителей и инициалы, если изображения нет. Логотипы загружаются один раз для каждого бренда, а не для каждого сообщения.
# review: new
ui-card-picture = Изображение:
# review: new
ui-card-picture-choose = &Выбрать...
# review: new
ui-picture-not-picture = Этот файл не является изображением PNG или JPEG.
# review: new
ui-picture-too-large = Это изображение слишком большое. Выберите изображение не больше 10 МБ, шириной и высотой не более 8000 пикселей.

## Encryption keys (Tools > Encryption Keys, Account Properties > Security, a contact's key)
# review: new
ui-keys-title = Ключи шифрования
# review: new
ui-keys-intro = Ваши ключи подписывают ваши сообщения и открывают почту, зашифрованную для вас. Ключи ваших контактов проверяют их подписи и шифруют почту для них.
# review: new
ui-keys-empty = Ключей пока нет. Нажмите «Создать ключ», чтобы создать свой, или «Импорт», чтобы добавить уже имеющийся ключ.
# review: new
ui-keys-col-name = Имя
# review: new
ui-keys-col-address = Адрес
# review: new
ui-keys-col-kind = Тип
# review: new
ui-keys-col-status = Состояние
# review: new
ui-keys-kind-own = Ваш ключ
# review: new
ui-keys-kind-contact = Контакт
# review: new
ui-keys-status-verified = { $status }, проверен
# review: new
ui-keys-new = &Создать ключ...
# review: new
ui-keys-import = &Импорт...
# review: new
ui-keys-export = &Экспорт...
# review: new
ui-keys-backup = &Резервная копия...
# review: new
ui-keys-verify = &Проверить...
# review: new
ui-keys-new-title = Новый ключ
# review: new
ui-keys-new-for = Создать ключ для:
# review: new
ui-keys-new-make = &Создать ключ
# review: new
ui-keys-no-account = Сначала добавьте учетную запись почты: ключ создается для адресов учетной записи.
# review: new
ui-keys-memory-only = Пароли хранятся только в памяти, поэтому закрытый ключ, созданный или импортированный сейчас, нельзя будет использовать после закрытия Inbox Classic.
# review: new
ui-keys-backup-offer = Ваш новый ключ готов. Сохранить его резервную копию сейчас? Если этот компьютер будет утерян или сброшен, ключ можно будет восстановить только из резервной копии.
# review: new
ui-keys-backup-now = &Сохранить резервную копию...
# review: new
ui-keys-later = &Позже
# review: new
ui-keys-backup-title = Резервная копия ключа
# review: new
ui-keys-backup-intro = Резервная копия защищена парольной фразой. Храните файл и парольную фразу в разных надежных местах: чтобы восстановить ключ, нужно и то и другое.
# review: new
ui-keys-passphrase = &Парольная фраза:
# review: new
ui-keys-passphrase-again = П&овторите:
# review: new
ui-keys-passphrase-differ = Парольные фразы не совпадают.
# review: new
ui-keys-passphrase-short = Используйте парольную фразу длиной не менее 8 символов.
# review: new
ui-keys-backup-saved = Резервная копия сохранена.
# review: new
ui-keys-import-title = Импорт ключа
# review: new
ui-keys-import-passphrase = Этот закрытый ключ защищен парольной фразой. Введите ее, чтобы импортировать ключ:
# review: new
ui-keys-file-filter = Ключи OpenPGP
# review: new
ui-keys-use-for = Использовать этот ключ для { $addresses }? Ваши сообщения с этих адресов будут подписываться им, а почту, зашифрованную для него, можно будет читать здесь.
# review: new
ui-keys-use = &Использовать
# review: new
ui-keys-not-now = &Не сейчас
# review: new
ui-keys-remove-own = Удалить ваш ключ { $fingerprint }? Почту, зашифрованную для него, больше нельзя будет прочитать здесь, если вы снова не импортируете его резервную копию.
# review: new
ui-keys-remove-contact = Удалить ключ контакта { $name }? Его подписи нельзя будет проверить, а почту для него нельзя будет зашифровать, пока вы снова не добавите его ключ.
# review: new
ui-key-properties-title = Свойства ключа
# review: new
ui-key-names = Имена:
# review: new
ui-key-fingerprint = Отпечаток:
# review: new
ui-key-status = Состояние:
# review: new
ui-key-created = Создан:
# review: new
ui-key-expires = Действителен до:
# review: new
ui-key-never = Бессрочно
# review: new
ui-key-algorithm = Алгоритм:
# review: new
ui-key-source = Источник:
# review: new
ui-key-addresses = Адреса:
# review: new
ui-key-address-verified = { $address } (проверен)
# review: new
ui-key-address-not-verified = { $address } (не проверен)
# review: new
ui-verify-title = Проверка ключа
# review: new
ui-verify-intro = Попросите контакт { $name } зачитать вам отпечаток своего ключа из своей программы, лично или по телефону. Не сравнивайте его с отпечатком, присланным по почте: тот, кто смог подменить ключ, может подменить и его.
# review: new
ui-verify-fingerprint = Отпечаток ключа, который есть у вас:
# review: new
ui-verify-marks = { $count ->
    [one] Если они совпадают, ключ будет отмечен как принадлежащий этому человеку для { $addresses }. Если этот адрес ему не принадлежит, нажмите «Различаются».
   *[other] Если они совпадают, ключ будет отмечен как принадлежащий этому человеку для { $addresses }. Если один из этих адресов ему не принадлежит, нажмите «Различаются».
}
# review: new
ui-verify-match = &Совпадают
# review: new
ui-verify-differ = &Различаются
# review: new
ui-verify-differs = Ваш ключ не совпадает с ключом контакта { $name }. Удалите его и снова попросите ключ у этого человека.
# review: new
ui-verify-unmark = Пометить как &непроверенный
# review: new
ui-account-security = Безопасность
# review: new
ui-account-security-intro = С ключом ваши сообщения можно подписывать, а другие люди могут отправлять вам зашифрованную почту.
# review: new
ui-account-key = &Ключ для этой учетной записи:
# review: new
ui-account-key-none = Нет
# review: new
ui-account-key-new = &Создать ключ...
# review: new
ui-account-autocrypt = &Отправлять мой открытый ключ вместе с сообщениями (Autocrypt)
# review: new
ui-contact-key = Ключ шифрования:
# review: new
ui-contact-key-none = Нет ключа
# review: new
ui-contact-key-use-new = &Использовать новый ключ
# review: new
ui-contact-key-keep = &Оставить текущий
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
# review: new
ui-setup-export-title = Экспорт настроек и учетных записей
# review: new
ui-setup-import-title = Импорт настроек и учетных записей
# review: new
ui-setup-export-intro = Выберите, что перенести на другой компьютер. Файл не содержит сообщений: там они загрузятся снова.
# review: new
ui-setup-use-passphrase = &Защитить файл парольной фразой
# review: new
ui-setup-passphrase-note = С парольной фразой файл шифруется и содержит также ваши пароли, данные для входа и закрытые ключи. Без нее каждая учетная запись запросит пароль на другом компьютере.
# review: new
ui-setup-export-button = &Экспорт...
# review: new
ui-setup-file-filter = Настройки и учетные записи Inbox Classic
# review: new
ui-setup-ask-passphrase = Этот файл защищен парольной фразой. Введите ее, чтобы увидеть содержимое файла:
# review: new
ui-setup-import-intro = Выберите, что импортировать. Учетные записи, которые уже есть на этом компьютере, останутся без изменений.
# review: new
ui-setup-from = Сохранено в Inbox Classic { $version } { $date }.
# review: new
ui-setup-import-button = &Импорт
# review: new
ui-setup-done = Готово
# review: new
ui-setup-first-run = Импортировать настройки и учетные записи с другого компьютера...
