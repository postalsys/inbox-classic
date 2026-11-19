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
# review: new
ui-open-in-calendar = Открыть в календаре
# review: new
ui-pictures-blocked = Некоторые изображения заблокированы, чтобы отправитель не смог распознать ваш компьютер. Щелкните здесь, чтобы загрузить изображения.
# review: new
ui-not-shown = Не удалось показать сообщение.
# review: new
ui-attachment-not-read = Не удалось прочитать вложение.
# review: new
ui-attachment-not-saved = Не удалось сохранить вложение.
# review: new
ui-not-downloaded = Сообщение еще не загружено.
# review: new
ui-leave-list = Отписаться от этой рассылки?
# review: new
ui-leave-one-click = Inbox Classic отправит запрос на отписку на { $target }. Веб-страница не откроется, и письмо не будет отправлено.
# review: new
ui-leave-mail = Чтобы отписаться, отправьте письмо на { $target }. Inbox Classic подготовит его за вас. Отправьте сообщение, чтобы подтвердить.
# review: new
ui-leave-web = Страница отписки от рассылки откроется в браузере ({ $target }).
# review: new
ui-unsubscribing = Отписка от { $target }...
# review: new
ui-cannot-unsubscribe = В этом сообщении нет возможности отписаться.
# review: new
ui-unsubscribed = Запрос на отписку принят. Рассылка сообщает, что больше не будет присылать эти сообщения.
# review: new
ui-not-unsubscribed = Не удалось отписаться: { $reason }
# review: new
ui-event-span = с { $start } до { $end }
# review: new
ui-event-floating = { $when } (по времени отправителя)
# review: new
ui-invitation = Приглашение: { $title }
# review: new
ui-invitation-updated = Обновленное приглашение: { $title }
# review: new
ui-invitation-canceled = Отменено: { $title }
# review: new
ui-invitation-answer = Ответ на приглашение: { $title }
# review: new
ui-no-title = (без названия)
# review: new
ui-organizer = Организатор: { $name }
# review: new
ui-invitation-not-read = Не удалось прочитать приглашение.
# review: new
ui-no-calendar = На этом компьютере нет программы календаря, чтобы открывать приглашения (файлы .ics).
# review: new
ui-messages-not-changed = Не удалось изменить сообщения.
# review: new
ui-new-folder-in-selected = Новая папка будет создана внутри выбранной папки.
# review: new
ui-new-folder-at-top = Новая папка будет создана на верхнем уровне учетной записи.
# review: new
ui-folder-not-created = Не удалось создать папку.
# review: new
ui-folder-not-renamed = Не удалось переименовать папку.
# review: new
ui-folder-not-deleted = Не удалось удалить папку.
# review: new
ui-rename-folder-intro = Введите новое имя для папки «{ $folder }».
# review: new
ui-properties-of = Свойства: { $subject }
# review: new
ui-internet-headers = Интернет-заголовки этого сообщения:
# review: new
ui-save-messages-in = Сохранить сообщения в
# review: new
ui-save-message-as = Сохранить сообщение как
# review: new
ui-import-choose-folder = Сначала выберите папку, в которую нужно импортировать сообщения.
# review: new
ui-add-account-title = Добавить учетную запись почты
# review: new
ui-accounts-title = Учетные записи
# review: new
ui-security-none = Нет (без шифрования)
# review: new
ui-field-required = Поле «{ $field }» обязательно.
# review: new
ui-email-invalid = Недопустимый адрес электронной почты.
# review: new
ui-ports-invalid = Порт задается числом от 1 до 65535.
# review: new
ui-looking-up = Поиск параметров для { $domain }...
# review: new
ui-found-none = Введите данные учетной записи, предоставленные вашим почтовым провайдером.
# review: new
ui-found-change = Измените эти параметры, если провайдер указал другие.
# review: new
ui-found-guess = Для этого адреса параметры не найдены. Предложенные имена серверов являются догадками. Уточните их у провайдера.
# review: new
ui-found-mx = Inbox Classic распознала вашего почтового провайдера и заполнила параметры его серверов.
# review: new
ui-found-srv = Эти параметры найдены в записях DNS вашего домена.
# review: new
ui-found-autodiscover = Эти параметры найдены с помощью Microsoft Autodiscover (Exchange).
# review: new
ui-found-other = Для этого адреса найдены эти параметры.
# review: new
ui-app-password-needed = { $provider } не принимает ваш обычный пароль в почтовых программах. Создайте пароль приложения в своей учетной записи { $provider } и введите его в поле «Пароль» в следующей форме.
# review: new
ui-app-password-open = Открыть инструкции { $provider } в браузере?
# review: new
ui-plain-warning = Без шифрования любой, кто перехватывает ваш сетевой трафик, может прочитать ваш пароль и сообщения. Используйте такое подключение только с сервером на вашем компьютере или в вашей локальной сети.
# review: new
ui-continue-ask = Продолжить?
# review: new
ui-add-sign-in-app = Добавить приложение для входа...
# review: new
ui-turned-off = { $name }: отключено на этом компьютере.
# review: new
ui-off-here = Отключено на этом компьютере.
# review: new
ui-why = Почему?
# review: new
ui-more-sign-in = Другие способы входа...
# review: new
ui-other-account = Чтобы добавить другую учетную запись электронной почты, введите свой адрес и имя, которое будут видеть получатели. Затем будут найдены параметры серверов.
# review: new
ui-field-account-name = Имя учетной записи:
# review: new
ui-field-name = Отображаемое имя:
# review: new
ui-field-email = Адрес электронной почты:
# review: new
ui-field-user = Имя пользователя:
# review: new
ui-field-password = Пароль:
# review: new
ui-field-imap-host = Сервер входящей почты (IMAP):
# review: new
ui-field-imap-port = Порт IMAP:
# review: new
ui-field-imap-security = Безопасность IMAP:
# review: new
ui-field-smtp-host = Сервер исходящей почты (SMTP):
# review: new
ui-field-smtp-port = Порт SMTP:
# review: new
ui-field-smtp-security = Безопасность SMTP:
# review: new
ui-field-other-addresses = Другие адреса, с которых вы отправляете:
# review: new
ui-sign-in-not-started = Не удалось начать вход через браузер.
# review: new
ui-sign-in-in-browser = Войдите в { $account } в открывшемся окне браузера, затем вернитесь сюда.
# review: new
ui-sign-in-failed = Не удалось войти: { $reason }
# review: new
ui-account-not-saved = Не удалось сохранить учетную запись.
# review: new
ui-start-intro = Gmail, Google Workspace, Outlook.com и Microsoft 365: войдите на собственной странице Google или Microsoft. Пароль вводится там, а не в Inbox Classic.
# review: new
ui-start-intro-apps = Войдите через браузер с одним из ваших приложений для входа (Другие способы входа) или добавьте любую учетную запись электронной почты, указав ниже имя и адрес.
# review: new
ui-use-app-password = Использовать пароль приложения
# review: new
ui-the-provider = провайдера
# review: new
ui-provider-intro = Войдите в { $email } на сайте { $provider }. Ваш пароль не передается Inbox Classic. Можно также использовать пароль приложения, созданный в настройках безопасности вашей учетной записи.
# review: new
ui-provider-intro-apps = Войдите в { $email } на сайте { $provider } с одним из ваших приложений для входа (Другие способы входа). Можно также использовать пароль приложения, созданный в настройках безопасности вашей учетной записи.
# review: new
ui-finish = Готово
# review: new
ui-logon = Вход
# review: new
ui-enter-password = Введите пароль для { $account }.
# review: new
ui-signs-in-with = Приложение для входа: { $app }. Вход выполняется в браузере, и учетная запись использует серверы этого приложения.
# review: new
ui-keep-password = Оставьте поле пароля пустым, чтобы сохранить текущий пароль.
# review: new
ui-remove-account = Удалить учетную запись
# review: new
ui-remove-account-ask = Удалить эту учетную запись из Inbox Classic? Почта останется на сервере; копия на этом компьютере и сохраненный пароль будут удалены.
# review: new
ui-col-email = Адрес электронной почты
# review: new
ui-col-incoming = Сервер входящей почты
# review: new
ui-type-email = Введите адрес электронной почты, например name@example.com.
# review: new
ui-ai-agent = ИИ-агент
# review: new
ui-ai-agent-access = Доступ ИИ-агента
# review: new
ui-ai-agents = ИИ-агенты
# review: new
ui-program-path = Программа: { $path }
# review: new
ui-it-may = Разрешенные действия:
# review: new
ui-accounts-it-may-use = Разрешенные учетные записи:
# review: new
ui-send-message-ask = Отправить сообщение?
# review: new
ui-col-name = Имя
# review: new
ui-never = Никогда
# review: new
ui-connect-agent = Подключение ИИ-агента
# review: new
ui-connect-agent-intro = Добавьте это в список серверов MCP вашего агента (Claude Desktop: Settings > Developer > Edit Config):
# review: new
ui-col-program = Программа
# review: new
ui-col-may = Разрешения
# review: new
ui-col-last-used = Последнее использование
# review: new
ui-col-when = Когда
# review: new
ui-col-what = Действие
# review: new
ui-sign-in-app = Приложение для входа
# review: new
ui-sign-in-apps = Приложения для входа
# review: new
ui-add-sign-in-app-title = Добавить приложение для входа
# review: new
ui-preset-app-name = Приложение для входа { $provider }
# review: new
ui-issuer-not-checked = издателя невозможно проверить
# review: new
ui-checking-issuer = Проверка { $issuer }...
# review: new
ui-issuer-unusable = Этого издателя нельзя использовать: { $reason }
# review: new
ui-issuer-usable = Этого издателя можно использовать.
# review: new
ui-sign-in-app-not-saved = Не удалось сохранить приложение для входа: { $reason }
# review: new
ui-check = &Проверить
# review: new
ui-fill-in-for = Параметры для:
# review: new
ui-app-name = Имя:
# review: new
ui-issuer = Издатель:
# review: new
ui-client-id = Идентификатор клиента:
# review: new
ui-client-secret = Секрет клиента:
# review: new
ui-scopes = Области доступа (scopes):
# review: new
ui-imap-server = Сервер IMAP:
# review: new
ui-smtp-server = Сервер SMTP:
# review: new
ui-redirect-uri = URI перенаправления:
# review: new
ui-sign-in-app-intro = Приложение для входа является клиентом OAuth, который вы регистрируете у провайдера, чтобы входить через браузер. Выберите провайдера, чтобы заполнить его параметры, затем добавьте идентификатор клиента и секрет клиента, если провайдер его выдал.
# review: new
ui-remove-secret = Секрет клиента сохранен. Введите новый, чтобы заменить его, или удалите сохраненный секрет
# review: new
ui-register-it = Зарегистрируйте приложение у провайдера
# review: new
ui-built-in-note = { $name } встроено. Можно только выбрать, предлагать ли его для новых учетных записей.
# review: new
ui-client-with-secret = Идентификатор клиента: { $client }, с секретом клиента.
# review: new
ui-client-public = Идентификатор клиента: { $client }, общедоступный клиент (без секрета).
# review: new
ui-no-accounts = Нет учетных записей
# review: new
ui-remove-sign-in-app = Удалить приложение для входа
# review: new
ui-remove-sign-in-app-ask = Удалить приложение для входа { $name } и его сохраненный секрет клиента?
# review: new
ui-sign-in-app-not-removed = Приложение для входа не удалено. { $reason }
# review: new
ui-sign-in-apps-intro = Приложения для входа позволяют учетным записям входить через браузер. Приложение без флажка не предлагается для новых учетных записей; учетные записи, которые уже его используют, продолжают работать.
# review: new
ui-col-issuer = Издатель
# review: new
ui-col-used-by = Используется
# review: new
ui-options-system-default = Как в системе ({ $language })
# review: new
ui-settings-general = Общие
# review: new
ui-settings-reading = Чтение
# review: new
ui-settings-new-mail = Новая почта
# review: new
ui-settings-sending = Отправка
# review: new
ui-settings-default-apps = Приложения по умолчанию
# review: new
ui-settings-message-list = Список сообщений
# review: new
ui-settings-messages = Сообщения
# review: new
ui-settings-encryption = Шифрование
# review: new
ui-settings-language = Язык
# review: new
ui-settings-label = { $label }:
# review: new
ui-apply = &Применить
# review: new
ui-language-label = &Язык:
# review: new
ui-restart-note = Чтобы сменить язык, перезапустите Inbox Classic.
# review: new
ui-restart-ask = Inbox Classic перейдет на язык «{ $language }» после перезапуска. Перезапустить сейчас?
# review: new
ui-notify-new-mail = &Уведомлять о новой почте
# review: new
ui-new-folder-title = Новая папка
# review: new
ui-rename-folder-title = Переименование папки
# review: new
ui-delete-folder-question = Удалить папку «{ $folder }» вместе с ее сообщениями и вложенными папками? Она будет удалена и на сервере.
ui-properties = Сво&йства
# review: new
ui-account-sync = Отправить и &получить
# review: new
ui-account-properties = &Свойства...
# review: new
ui-account-move-up = &Вверх
# review: new
ui-account-move-down = В&низ
ui-menu-open = &Открыть
ui-menu-flag = &Флажок
ui-menu-view-source = Ис&ходный текст
# review: new
ui-save-attachments = Сохранить вложения
# review: new
ui-attachment-open = Открыть
# review: new
ui-attachment-save-as = Сохранить как...
# review: new
ui-attachment-save-all = Сохранить все...
# review: new
ui-attachment-show-in-message = Показать в письме
# review: new
ui-attachments-strip = Вложения
# review: new
ui-attachment-note-title = Открытие этого файла
# review: new
ui-attachment-program-tip = Команда «Открыть» недоступна для файлов этого типа: они могут запускать программы. Сохраните файл и откройте его сами.
# review: new
ui-clear-flag = &Снять флажок
# review: new
ui-button-move = &Переместить
# review: new
ui-button-copy = &Копировать
# review: new
ui-find-folder = Найти папку
# review: new
ui-new-folder-in = Новая папка будет создана в папке «{ $folder }».
# review: new
ui-outbox-send-all = &Отправить все сейчас
# review: new
ui-yes = Да
# review: new
ui-no = Нет
# review: new
ui-try-again = Повторить
ui-remove = &Удалить
ui-signature-of = Текстовая подпись: { $account }
# review: new
ui-sign-in-with = Войти через { $provider }
# review: new
ui-sign-in-in-browser-yours = Войдите в свою учетную запись в открывшемся окне браузера, затем вернитесь сюда.
# review: new
ui-browser-sign-in-server = { $server } (вход через браузер)
# review: new
ui-dont-allow = Не разрешать
# review: new
ui-allow = &Разрешить
# review: new
ui-dont-send = Не отправлять
ui-dont-unsubscribe = Не отписываться
# review: new
ui-edit-first = &Сначала изменить
# review: new
ui-new-address = Новый адрес
# review: new
ui-turn-away = &Отклонить
# review: new
ui-clear-agent-log = Очистить журнал действий агентов?
# review: new
ui-clear-agent-log-detail = Изменения, сделанные агентами, не будут отменены.
# review: new
ui-let-agents-connect = &Разрешить ИИ-агентам подключаться к Inbox Classic
# review: new
ui-change-button = Изменить…
# review: new
ui-undo-button = Отменить
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
ui-undo-since-button = Отменить за период…
# review: new
ui-undo-since-span = Отменить то, что сделала эта программа:
# review: new
ui-take-back = Отменить
# review: new
ui-rules-title = Правила для сообщений
# review: new
ui-rules-intro = Правила сортируют новые сообщения в папке «Входящие», пока Inbox Classic работает. Подходящие правила выполняются по порядку. Как только правило перемещает сообщение из папки «Входящие», следующие правила к нему не применяются.
# review: new
ui-rules-none = Правил пока нет. Нажмите «Создать», чтобы создать правило.
# review: new
ui-rule-new = &Создать...
# review: new
ui-rule-edit = &Изменить...
# review: new
ui-rule-delete-button = &Удалить
# review: new
ui-rule-title = Правило для сообщений
# review: new
ui-rule-name = Имя:
# review: new
ui-rule-account = Учетная запись:
# review: new
ui-rule-all-accounts = Все учетные записи
# review: new
ui-rule-query = Условия поиска:
# review: new
ui-rule-query-hint = Используйте условия поиска, например from:ann@example.com, subject:счет или list:news.example.com, так же как в поле поиска.
# review: new
ui-rule-count = { $count ->
    [one] Сейчас этим условиям соответствует { $count } сообщение в папке «Входящие».
    [few] Сейчас этим условиям соответствуют { $count } сообщения в папке «Входящие».
    [many] Сейчас этим условиям соответствуют { $count } сообщений в папке «Входящие».
   *[other] Сейчас этим условиям соответствуют { $count } сообщения в папке «Входящие».
}
# review: new
ui-rule-show = Пока&зать
# review: new
ui-rule-actions = Действия:
# review: new
ui-rule-move = &Переместить в:
# review: new
ui-rule-mark-read = Пометить как прочи&танное
# review: new
ui-rule-flag = Пометить &флажком
# review: new
ui-rule-archive = &Архивировать
# review: new
ui-rule-junk = Переместить в папку «&Нежелательная почта»
# review: new
ui-rule-delete = У&далить
# review: new
ui-rule-quiet = Не &уведомлять меня о нем
# review: new
ui-rule-apply-now = Применить также к сообщениям, которые уже есть в папке «&Входящие»
# review: new
ui-rule-delete-ask = Удалить правило «{ $name }»?
# review: new
ui-create-rule = Создать правило...
# review: new
ui-rules-applied = { $count ->
    [one] Ваши правила отсортировали { $count } сообщение
    [few] Ваши правила отсортировали { $count } сообщения
    [many] Ваши правила отсортировали { $count } сообщений
   *[other] Ваши правила отсортировали { $count } сообщения
}
# review: new
ui-col-rule-matches = Условия
# review: new
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
