# Русский. Черновик, ожидает проверки носителем языка (см. core/locales/GLOSSARY.md).

## The main window

win-still-running-detail = Inbox Classic продолжает проверять почту в фоновом режиме. Щелкните значок, чтобы открыть программу. Чтобы выйти, щелкните значок правой кнопкой мыши и выберите команду выхода в меню.
win-default-app-not-installed = Эта копия Inbox Classic не установлена, поэтому Windows не показывает ее в списке почтовых программ. Установите Inbox Classic, чтобы выбрать ее почтовой программой по умолчанию.
win-default-app-settings = Откроется раздел параметров Windows «Приложения по умолчанию». Выберите Inbox Classic для открытия ссылок MAILTO.
win-no-unread = Нет непрочитанных сообщений
win-unread-messages = { $count ->
    [one] { $count } непрочитанное сообщение
    [few] { $count } непрочитанных сообщения
    [many] { $count } непрочитанных сообщений
   *[other] { $count } непрочитанного сообщения
}
win-print-failed = Не удалось напечатать сообщение.
win-print-title-of = Печать: { $subject }
win-no-bodies = Не удается отобразить содержимое сообщений.
win-webview-failed = Не удалось создать WebView2.
win-webview-missing = Среда выполнения WebView2 недоступна.
win-list-loading = Загрузка...

## Buttons and words used in many windows

win-delete-button = &Удалить
win-find-label = &Найти:
win-save-as-button = &Сохранить как...
win-too-many-files = Слишком много файлов сразу: выберите меньше.

## The compose window

win-editor-failed = Невозможно создавать сообщения.
win-ctrl-click-to-open = ({ $ctrl }+щелчок, чтобы открыть)
win-format-bold = Полужирный ({ $ctrl }+B)
win-format-italic = Курсив ({ $ctrl }+I)
win-format-underline = Подчеркнутый ({ $ctrl }+U)
win-format-link = Гиперссылка ({ $ctrl }+K)
win-show-cc = &Копия
win-show-bcc = &Скрытая
win-signature-title = Текстовая подпись: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Нет результатов по запросу «{ $words }» во всех папках
    [one] { $count } результат по запросу «{ $words }» во всех папках
    [few] { $count } результата по запросу «{ $words }» во всех папках
    [many] { $count } результатов по запросу «{ $words }» во всех папках
   *[other] { $count } результата по запросу «{ $words }» во всех папках
}
win-search-found-in = { $count ->
    [0] Нет результатов по запросу «{ $words }» в «{ $folder }»
    [one] { $count } результат по запросу «{ $words }» в «{ $folder }»
    [few] { $count } результата по запросу «{ $words }» в «{ $folder }»
    [many] { $count } результатов по запросу «{ $words }» в «{ $folder }»
   *[other] { $count } результата по запросу «{ $words }» в «{ $folder }»
}
win-search-indexing = { $count ->
    [one] еще индексируется текст { $count } сообщения
   *[other] еще индексируется текст { $count } сообщений
}
win-no-match-indexing = { $count ->
    [one] Текст { $count } сообщения еще индексируется, поэтому вскоре могут появиться новые результаты.
   *[other] Текст { $count } сообщений еще индексируется, поэтому вскоре могут появиться новые результаты.
}
win-files = { $count ->
    [one] { $count } файл
    [few] { $count } файла
    [many] { $count } файлов
   *[other] { $count } файла
}
win-save-attachments = &Сохранить вложения...
win-files-not-saved = Не удалось сохранить { $failed } из { $count } файлов.
win-new-folder-in-highlighted = Новая папка будет создана внутри выбранной папки.
win-delete-folder-ask = Удалить папку «{ $folder }» вместе с ее сообщениями и вложенными папками? Она будет удалена и на сервере.
win-rename = &Переименовать...
win-messages-not-saved = Не удалось сохранить сообщения.
win-messages-not-forwarded = Не удалось переслать сообщения.

## Accounts

win-sign-in-google = Войти через Google
win-sign-in-microsoft = Войти через Microsoft
win-next = &Далее >
win-your-account = вашу учетную запись
win-browser-sign-in = (вход через браузер)
win-add = &Добавить...
win-properties-button = &Свойства...
win-signature-button = Текстовая &подпись...
win-sign-in-apps-button = Прило&жения для входа...

## AI agents

win-dont-allow = &Не разрешать
win-col-address = Адрес
win-never-written-to = Вы еще не писали на этот адрес
win-book-find-label = Введите имя или адрес электронной почты:
win-send = &Отправить
win-dont-send = &Не отправлять
win-unsubscribe = &Отписаться
win-dont-unsubscribe = &Не отписываться
win-forget-program-ask = Удалить запись об этой программе, ее разрешения и журнал действий ее агентов? При следующем подключении программа снова запросит разрешение.
win-clear-log-ask = Очистить журнал действий агентов? Изменения, сделанные агентами, не будут отменены.
win-agent-programs = &Программы, агенты которых запросили доступ к вашей почте:
win-change = &Изменить...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Отменить &за период...
win-take-back = &Отменить действия
win-what-agents-did = &Действия агентов:
win-agent-reads = Что прочитано с { $from } до { $to }:
win-agent-reads-hint = Выберите выше запись о чтении, чтобы увидеть подробности.

## Sign-in apps

win-built-in = (встроенное)
win-edit = &Изменить...

## Options

win-folders-hide = Скрыть список папок
win-folders-pin = Закрепить список папок рядом с сообщениями
win-folders-show = Показать папки

## The installer

win-installer-start = Запустить Inbox Classic
win-installer-welcome-new =
    Будет установлена почтовая программа Inbox Classic { $version }.

    Права администратора не нужны: программа устанавливается только для текущего пользователя Windows.
win-installer-welcome-same =
    Inbox Classic { $version } уже установлена. Она будет установлена заново.

    Ваши учетные записи и почта сохранятся.
win-installer-welcome-update =
    Inbox Classic { $installed } будет обновлена до версии { $version }.

    Если программа запущена, сначала она будет закрыта. Ваши учетные записи и почта сохранятся.
win-installer-older-ask = Уже установлена более новая версия Inbox Classic { $installed }. Все равно установить версию { $version }?
win-installer-still-running = Inbox Classic все еще работает. Закройте ее и повторите попытку.
win-installer-remove-mail-ask = Удалить также все локальные данные Inbox Classic, включая учётные записи, загруженную почту, очередь отправки, настройки, контакты, правила и ключи шифрования? Почта на серверах и записи в системном хранилище учётных данных останутся.
