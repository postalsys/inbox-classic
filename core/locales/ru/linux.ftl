# Русский. Черновик, ожидает проверки носителем языка (см. core/locales/GLOSSARY.md).

## The main window

# review: new
gtk-search-looks-in = Поиск в { $place } охватывает темы, отправителей, получателей, имена вложений и текст сообщений. Проверьте написание или введите меньше слов.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Текст { $count } сообщения еще индексируется. Скоро могут появиться новые результаты.
   *[other] Текст { $count } сообщений еще индексируется. Скоро могут появиться новые результаты.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Нет результатов
    [one] { $count } результат
    [few] { $count } результата
    [many] { $count } результатов
   *[other] { $count } результата
} по запросу «{ $words }» во всех папках
# review: new
gtk-search-results-in = { $count ->
    [0] Нет результатов
    [one] { $count } результат
    [few] { $count } результата
    [many] { $count } результатов
   *[other] { $count } результата
} по запросу «{ $words }» в { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] еще индексируется текст { $count } сообщения
   *[other] еще индексируется текст { $count } сообщений
}
gtk-list-loading = Загрузка...
# review: new
gtk-menu-rename = Переименовать...
# review: new
gtk-import-one-question = Импортировать сообщение { $file } в папку «{ $folder }»?
# review: new
gtk-files-not-saved = Не удалось сохранить { $failed } из { $total } файлов.
# review: new
gtk-unsubscribe-one-click =
    Отписаться от этой рассылки?

    Inbox Classic отправит запрос на отписку на { $target }. Веб-страница не откроется, и письмо не будет отправлено.
# review: new
gtk-unsubscribe-mail =
    Отписаться от этой рассылки?

    Чтобы отписаться, отправьте письмо на { $target }. Inbox Classic подготовит его за вас. Отправьте сообщение, чтобы подтвердить.
# review: new
gtk-unsubscribe-web =
    Отписаться от этой рассылки?

    Страница отписки от рассылки откроется в браузере ({ $target }).
# review: new
gtk-unsubscribe-failed = Не удалось отписаться: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Написать из определенной учетной записи
# review: new
gtk-toolbar-send-recv-menu = Отправить и получить почту для определенной учетной записи
# review: new
gtk-main-menu = Главное меню
# review: new
gtk-folder-list = Список папок
# review: new
gtk-quit = Выйти

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Новая папка будет создана на верхнем уровне { $account }.

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Нет непрочитанных сообщений
    [one] { $count } непрочитанное сообщение
    [few] { $count } непрочитанных сообщения
    [many] { $count } непрочитанных сообщений
   *[other] { $count } непрочитанного сообщения
}

## The Outbox

# review: new
gtk-outbox-empty = Нет сообщений, ожидающих отправки.
# review: new
gtk-outbox-row = Кому: { $to }  ·  В очереди с { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic продолжает проверять новую почту в фоновом режиме. Чтобы открыть программу или выйти из нее, используйте ее значок на верхней панели.
# review: new
gtk-sign-in-again-ask =
    Вход в { $account } отклонен, или срок действия сеанса истек.

    Войти снова через браузер?
# review: new
gtk-default-app-not-installed = Эта копия Inbox Classic не установлена, поэтому система не показывает ее в списке почтовых программ. Установите ее, чтобы выбрать.
# review: new
gtk-default-app-now = Теперь Inbox Classic является вашей почтовой программой по умолчанию: ссылки на адреса электронной почты открывают здесь новое сообщение.
# review: new
gtk-default-app-failed = Не удалось сделать Inbox Classic почтовой программой по умолчанию.

## The reading pane

# review: new
gtk-reader-date = Дата:
# review: new
gtk-reader-files = Вложения сообщения
# review: new
gtk-files = { $count ->
    [one] { $count } файл
    [few] { $count } файла
    [many] { $count } файлов
   *[other] { $count } файла
}
# review: new
gtk-pictures-blocked = Некоторые изображения заблокированы, чтобы отправитель не смог распознать ваш компьютер.
# review: new
gtk-download-pictures = Загрузить изображения
# review: new
gtk-save-attachments-menu = Сохранить вложения...

## The compose window

# review: new
gtk-format-bold = Полужирный (Ctrl+B)
# review: new
gtk-format-italic = Курсив (Ctrl+I)
# review: new
gtk-format-underline = Подчеркнутый (Ctrl+U)
# review: new
gtk-format-hyperlink = Гиперссылка (Ctrl+K)
# review: new
gtk-font = Шрифт
# review: new
gtk-show-cc = _Копия
# review: new
gtk-show-bcc = _Скрытая
# review: new
gtk-save-tip = Сохранить (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+щелчок, чтобы открыть)

## Accounts

# review: new
gtk-plain-warning =
    Без шифрования любой, кто перехватывает ваш сетевой трафик, может прочитать ваш пароль и сообщения. Используйте такое подключение только с сервером на вашем компьютере или в вашей локальной сети.

    Продолжить?
# review: new
gtk-account-name-title = Имя учетной записи
# review: new
gtk-display-name-title = Отображаемое имя
# review: new
gtk-turned-off-why = Вариант «{ $button }» отключен на этом компьютере. { $reason }
# review: new
gtk-turned-off-why-long =
    Вариант «{ $button }» отключен на этом компьютере.

    { $reason }
# review: new
gtk-next = Далее >
# review: new
gtk-provider-sign-in = Войдите в { $address } на сайте { $provider }. Ваш пароль не передается Inbox Classic. Можно также использовать пароль приложения, созданный в настройках безопасности вашей учетной записи.
# review: new
gtk-provider-sign-in-apps = Войдите в { $address } на сайте { $provider } с одним из ваших приложений для входа (Другие способы входа). Можно также использовать пароль приложения, созданный в настройках безопасности вашей учетной записи.
# review: new
gtk-accounts-add = Добавить...
# review: new
gtk-accounts-properties = Свойства...
# review: new
gtk-accounts-signature = Подпись...
# review: new
gtk-accounts-sign-in-apps = Приложения для входа...

## Sign-in apps

# review: new
gtk-app-server = Сервер { $kind }
# review: new
gtk-app-port = Порт { $kind }
# review: new
gtk-app-security = Безопасность { $kind }
# review: new
gtk-issuer-found =
    Страница входа: { $page }
    Адрес получения токена: { $endpoint }
# review: new
gtk-client-id = Идентификатор клиента
# review: new
gtk-client-secret = Секрет клиента
# review: new
gtk-scopes = Области доступа (scopes)
# review: new
gtk-redirect-uri = URI перенаправления
# review: new
gtk-issuer-usable =
    Этого издателя можно использовать.

    { $found }
# review: new
gtk-app-built-in = { $app } встроено. Можно только выбрать, предлагать ли его для новых учетных записей. { $reason }
# review: new
gtk-built-in = { $app } (встроенное)
# review: new
gtk-offered-for-new = Предлагается для новых учетных записей
# review: new
gtk-edit-button = Изменить...
# review: new
gtk-remove-app-ask = Удалить приложение для входа { $app } и его сохраненный секрет клиента?
# review: new
gtk-sign-in-apps-intro = Приложения для входа позволяют учетным записям входить через браузер. Выключенное приложение не предлагается для новых учетных записей; учетные записи, которые уже его используют, продолжают работать.

## AI agents

# review: new
gtk-agent-it-may = Разрешенные действия
# review: new
gtk-agent-accounts = Разрешенные учетные записи
# review: new
gtk-never-used = Не использовалась
# review: new
gtk-last-used = Последнее использование: { $date }
# review: new
gtk-forget-program = Удалить эту программу?
# review: new
gtk-forget-program-detail = Разрешения программы и журнал действий ее агентов будут удалены. При следующем подключении она снова запросит разрешение.
# review: new
gtk-no-agents-yet = Ни один агент пока не запрашивал доступ к вашей почте.
# review: new
gtk-nothing-yet = Пока ничего.

## Preferences

# review: new
gtk-preferences = Параметры
# review: new
gtk-language = Язык
# review: new
gtk-language-subtitle = Язык программы и справки
# review: new
gtk-new-mail-group = Новая почта
# review: new
gtk-notify-new-mail = Уведомлять о новой почте
# review: new
gtk-notify-subtitle = Уведомление о новых сообщениях, когда окно находится в фоне
# review: new
gtk-restart-to-change = Чтобы сменить язык, Inbox Classic перезапустится.

## The desktop entry and the page of the software stores

# review: new
gtk-desktop-generic-name = Почтовый клиент
# review: new
gtk-desktop-comment = Чтение и создание электронной почты: быстрая и простая почтовая программа
# review: new
gtk-desktop-keywords = почта;письмо;сообщение;входящие;
# review: new
gtk-metainfo-summary = Быстрая и простая почтовая программа
# review: new
gtk-metainfo-description = Inbox Classic читает и пишет электронную почту: папки слева, список сообщений сверху и сообщение под ним, как в почтовых программах прежних лет. Она работает с любой учетной записью IMAP и SMTP и входит в Outlook.com и Microsoft 365 через браузер.
# review: new
gtk-metainfo-feature-sanitized = Каждое сообщение показывается очищенным, без скриптов, а изображения из интернета загружаются только с вашего разрешения
# review: new
gtk-metainfo-feature-search = Поиск слов в теме, именах отправителей и получателей, именах файлов и тексте, с операторами Gmail
# review: new
gtk-metainfo-feature-replies = В ответах сворачиваются предыдущие сообщения, которые они цитируют
# review: new
gtk-metainfo-feature-offline = Почту можно читать без подключения к сети; пароли хранятся в вашей связке ключей
