# Русский. Черновик, ожидает проверки носителем языка (см. core/locales/GLOSSARY.md).

## The main window

gtk-search-looks-in = Область поиска: «{ $place }». Поиск выполняется по темам и тексту сообщений, именам и адресам отправителей и получателей, а также именам вложений. Проверьте написание или введите меньше слов.
gtk-search-still-indexing = { $count ->
    [one] Текст { $count } сообщения еще индексируется. Скоро могут появиться новые результаты.
   *[other] Текст { $count } сообщений еще индексируется. Скоро могут появиться новые результаты.
}
gtk-search-results-everywhere = { $count ->
    [0] Нет результатов
    [one] { $count } результат
    [few] { $count } результата
    [many] { $count } результатов
   *[other] { $count } результата
} по запросу «{ $words }» во всех папках
gtk-search-results-in = { $count ->
    [0] Нет результатов
    [one] { $count } результат
    [few] { $count } результата
    [many] { $count } результатов
   *[other] { $count } результата
} по запросу «{ $words }» в «{ $place }»
gtk-search-indexing = { $count ->
    [one] еще индексируется текст { $count } сообщения
   *[other] еще индексируется текст { $count } сообщений
}
gtk-list-loading = Загрузка...
gtk-menu-rename = Переименовать...
gtk-import-one-question = Импортировать сообщение из файла «{ $file }» в папку «{ $folder }»?
gtk-files-not-saved = Не удалось сохранить { $failed } из { $total } файлов.
gtk-unsubscribe-one-click =
    Отписаться от этой рассылки?

    Inbox Classic отправит запрос на отписку по адресу { $target }. Веб-страница не откроется, и сообщение по электронной почте отправлено не будет.
gtk-unsubscribe-mail =
    Отписаться от этой рассылки?

    Чтобы отписаться, отправьте сообщение по адресу { $target }. Inbox Classic подготовит его для вас. Отправьте это сообщение, чтобы подтвердить отписку.
gtk-unsubscribe-web =
    Отписаться от этой рассылки?

    Страница отписки от рассылки откроется в браузере ({ $target }).
gtk-unsubscribe-failed = Не удалось отписаться: { $problem }
gtk-toolbar-create-mail-menu = Написать сообщение с выбранной учетной записи
gtk-toolbar-send-recv-menu = Отправить и получить почту для выбранной учетной записи
gtk-main-menu = Главное меню
gtk-folder-list = Список папок
gtk-quit = Выйти

## The Move and Copy window

gtk-new-folder-at-top-of = Новая папка будет создана на верхнем уровне учетной записи «{ $account }».

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Нет непрочитанных сообщений
    [one] { $count } непрочитанное сообщение
    [few] { $count } непрочитанных сообщения
    [many] { $count } непрочитанных сообщений
   *[other] { $count } непрочитанного сообщения
}

## The Outbox

gtk-outbox-empty = Нет сообщений, ожидающих отправки.
gtk-outbox-row = Кому: { $to }  ·  В очереди с { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic продолжает проверять почту в фоновом режиме. Чтобы открыть программу или выйти из нее, используйте ее значок на верхней панели.
gtk-sign-in-again-ask =
    Вход в учетную запись «{ $account }» отклонен или срок действия сеанса истек.

    Войти снова через браузер?
gtk-default-app-not-installed = Эта копия Inbox Classic не установлена, поэтому система не показывает ее в списке почтовых программ. Установите Inbox Classic, чтобы выбрать ее почтовой программой по умолчанию.
gtk-default-app-now = Теперь Inbox Classic используется для почты по умолчанию: при нажатии на ссылку с адресом электронной почты здесь открывается новое сообщение.
gtk-default-app-failed = Не удалось сделать Inbox Classic почтовой программой по умолчанию.

## The reading pane

gtk-reader-date = Дата:
gtk-reader-files = Вложения сообщения
gtk-files = { $count ->
    [one] { $count } файл
    [few] { $count } файла
    [many] { $count } файлов
   *[other] { $count } файла
}
gtk-save-attachments-menu = Сохранить вложения...

## The compose window

gtk-format-bold = Полужирный (Ctrl+B)
gtk-format-italic = Курсив (Ctrl+I)
gtk-format-underline = Подчеркнутый (Ctrl+U)
gtk-format-hyperlink = Гиперссылка (Ctrl+K)
gtk-font = Шрифт
gtk-show-cc = _Копия
gtk-show-bcc = _Скрытая
gtk-save-tip = Сохранить (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+щелчок, чтобы открыть)

## Accounts

gtk-plain-warning =
    Без шифрования любой, кто перехватывает ваш сетевой трафик, может прочитать ваш пароль и сообщения. Продолжайте только при защите подключения другим способом; сама по себе локальная сеть не обеспечивает шифрование.

    Продолжить?
gtk-account-name-title = Имя учетной записи
gtk-display-name-title = Отображаемое имя
gtk-turned-off-why = Способ входа «{ $button }» отключен на этом компьютере. { $reason }
gtk-turned-off-why-long =
    Способ входа «{ $button }» отключен на этом компьютере.

    { $reason }
gtk-next = Далее >
gtk-provider-sign-in = Войдите в учетную запись { $address } на сайте { $provider }. Ваш пароль не передается Inbox Classic. Если учетная запись поддерживает пароли приложений для почты, можно использовать такой пароль, созданный в ее настройках безопасности. Для Outlook.com и Microsoft 365 доступен только вход через браузер.
gtk-provider-sign-in-apps = Войдите в учетную запись { $address } на сайте { $provider } с помощью приложения для входа («Другие способы входа»). Если учетная запись поддерживает пароли приложений для почты, можно использовать такой пароль, созданный в ее настройках безопасности. Для Outlook.com и Microsoft 365 доступен только вход через браузер.
gtk-accounts-add = Добавить...
gtk-accounts-properties = Свойства...
gtk-accounts-signature = Текстовая подпись...
gtk-accounts-sign-in-apps = Приложения для входа...

## Sign-in apps

gtk-app-server = Сервер { $kind }
gtk-app-port = Порт { $kind }
gtk-app-security = Защита подключения { $kind }
gtk-issuer-found =
    Страница входа: { $page }
    Адрес получения токена: { $endpoint }
gtk-client-id = Идентификатор клиента
gtk-client-secret = Секрет клиента
gtk-scopes = Области доступа (scopes)
gtk-redirect-uri = URI перенаправления
gtk-issuer-usable =
    Сервер авторизации можно использовать для входа.

    { $found }
gtk-app-built-in = Приложение «{ $app }» встроено в Inbox Classic. Можно только выбрать, предлагать ли его для новых учетных записей. { $reason }
gtk-built-in = { $app } (встроенное)
gtk-offered-for-new = Предлагается для новых учетных записей
gtk-edit-button = Изменить...
gtk-remove-app-ask = Удалить приложение для входа «{ $app }» и сохраненный секрет клиента?
gtk-sign-in-apps-intro = Приложения для входа позволяют входить в почтовые учетные записи через браузер. Если отключить приложение, оно не будет предлагаться для новых учетных записей. Учетные записи, которые уже используют его, продолжат работать.

## AI agents

gtk-agent-it-may = Разрешенные действия
gtk-agent-accounts = Разрешенные учетные записи
gtk-never-used = Доступ еще не использовался
gtk-last-used = Последнее использование: { $date }
gtk-forget-program = Удалить запись об этой программе?
gtk-forget-program-detail = Разрешения программы и журнал действий ее агентов будут удалены. При следующем подключении она снова запросит разрешение.
gtk-no-agents-yet = Ни один агент пока не запрашивал доступ к вашей почте.
gtk-nothing-yet = Пока ничего.

## Preferences

gtk-preferences = Параметры
gtk-notify-subtitle = Только когда главное окно не на переднем плане

## The desktop entry and the page of the software stores

gtk-desktop-generic-name = Почтовый клиент
gtk-desktop-comment = Быстрая и простая программа для работы с электронной почтой
gtk-desktop-keywords = почта;письмо;сообщение;входящие;
gtk-metainfo-summary = Быстрая и простая почтовая программа
gtk-metainfo-description = В Inbox Classic папки находятся слева, список сообщений сверху, а выбранное сообщение под ним, как в классических почтовых программах. Поддерживаются учетные записи с IMAP и SMTP, а для Outlook.com и Microsoft 365 используется вход через браузер.
gtk-metainfo-feature-sanitized = Сообщения отображаются без скриптов, а изображения из интернета загружаются только с вашего разрешения
gtk-metainfo-feature-search = Поиск по темам и тексту сообщений, именам и адресам отправителей и получателей, а также именам файлов с поддержкой операторов Gmail
gtk-metainfo-feature-replies = Предыдущие сообщения в ответах отображаются в виде свернутых цитат
gtk-metainfo-feature-offline = Почту можно читать без сети, пока сохранена локальная копия; данные для входа обычно хранятся в системном хранилище ключей, если оно доступно
