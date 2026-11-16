# Русский. Черновик, ожидает проверки носителем языка (см. core/locales/GLOSSARY.md).

## The main window

# review: new
win-still-running-detail = Inbox Classic продолжает проверять новую почту в фоновом режиме. Щелкните значок, чтобы открыть программу. Чтобы выйти, щелкните значок правой кнопкой мыши и воспользуйтесь его меню.
# review: new
win-default-app-not-installed = Эта копия Inbox Classic не установлена, поэтому Windows не показывает ее в списке почтовых программ. Установите ее, чтобы выбрать.
# review: new
win-default-app-settings = Windows откроет параметры приложений по умолчанию. Выберите Inbox Classic для открытия ссылок MAILTO.
# review: new
win-no-unread = Нет непрочитанных сообщений
# review: new
win-unread-messages = { $count ->
    [one] { $count } непрочитанное сообщение
    [few] { $count } непрочитанных сообщения
    [many] { $count } непрочитанных сообщений
   *[other] { $count } непрочитанного сообщения
}
# review: new
win-print-failed = Не удалось напечатать сообщение.
# review: new
win-print-title-of = Печать: { $subject }
# review: new
win-no-bodies = Невозможно показать текст сообщений.
# review: new
win-webview-failed = Не удалось создать WebView2.
# review: new
win-webview-missing = Среда выполнения WebView2 недоступна.
# review: new
win-list-loading = Загрузка...

## Buttons and words used in many windows

# review: new
win-delete-button = &Удалить
# review: new
win-find-label = &Найти:
# review: new
win-save-as-button = Сохранить &как...
# review: new
win-too-many-files = Слишком много файлов сразу: выберите меньше.

## The compose window

# review: new
win-editor-failed = Невозможно создавать сообщения.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+щелчок, чтобы открыть)
# review: new
win-format-bold = Полужирный ({ $ctrl }+B)
# review: new
win-format-italic = Курсив ({ $ctrl }+I)
# review: new
win-format-underline = Подчеркнутый ({ $ctrl }+U)
# review: new
win-format-link = Гиперссылка ({ $ctrl }+K)
# review: new
win-show-cc = &Копия
# review: new
win-show-bcc = &Скрытая
# review: new
win-signature-title = Подпись: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Нет результатов по запросу «{ $words }» во всех папках
    [one] { $count } результат по запросу «{ $words }» во всех папках
    [few] { $count } результата по запросу «{ $words }» во всех папках
    [many] { $count } результатов по запросу «{ $words }» во всех папках
   *[other] { $count } результата по запросу «{ $words }» во всех папках
}
# review: new
win-search-found-in = { $count ->
    [0] Нет результатов по запросу «{ $words }» в папке «{ $folder }»
    [one] { $count } результат по запросу «{ $words }» в папке «{ $folder }»
    [few] { $count } результата по запросу «{ $words }» в папке «{ $folder }»
    [many] { $count } результатов по запросу «{ $words }» в папке «{ $folder }»
   *[other] { $count } результата по запросу «{ $words }» в папке «{ $folder }»
}
# review: new
win-search-indexing = { $count ->
    [one] еще индексируется текст { $count } сообщения
   *[other] еще индексируется текст { $count } сообщений
}
# review: new
win-no-match-indexing = { $count ->
    [one] Текст { $count } сообщения еще индексируется, поэтому скоро может найтись больше.
   *[other] Текст { $count } сообщений еще индексируется, поэтому скоро может найтись больше.
}
# review: new
win-files = { $count ->
    [one] { $count } файл
    [few] { $count } файла
    [many] { $count } файлов
   *[other] { $count } файла
}
# review: new
win-click-to-retry = Щелкните здесь, чтобы повторить попытку.
# review: new
win-save-attachments = &Сохранить вложения...
# review: new
win-files-not-saved = Не удалось сохранить { $failed } из { $count } файлов.
# review: new
win-new-folder-in-highlighted = Новая папка будет создана внутри выбранной папки.
# review: new
win-delete-folder-ask = Удалить папку «{ $folder }» вместе с ее сообщениями и вложенными папками? Она будет удалена и на сервере.
# review: new
win-rename = &Переименовать...
# review: new
win-messages-not-saved = Не удалось сохранить сообщения.
# review: new
win-messages-not-forwarded = Не удалось переслать сообщения.

## Accounts

# review: new
win-sign-in-google = Войти через Google
# review: new
win-sign-in-microsoft = Войти через Microsoft
# review: new
win-next = &Далее >
# review: new
win-your-account = вашу учетную запись
# review: new
win-browser-sign-in = (вход через браузер)
# review: new
win-add = &Добавить...
# review: new
win-properties-button = &Свойства...
# review: new
win-signature-button = &Подпись...
# review: new
win-sign-in-apps-button = Прило&жения для входа...

## AI agents

# review: new
win-dont-allow = &Не разрешать
# review: new
win-col-address = Адрес
# review: new
win-never-written-to = Вы сюда не писали
# review: new
win-book-find-label = Введите имя или адрес электронной почты:
# review: new
win-send = &Отправить
# review: new
win-dont-send = &Не отправлять
# review: new
win-forget-program-ask = Удалить эту программу, ее разрешения и журнал действий ее агентов? При следующем подключении она снова запросит разрешение.
# review: new
win-clear-log-ask = Очистить журнал действий агентов? Изменения, сделанные агентами, не будут отменены.
# review: new
win-agent-programs = &Программы, агенты которых запросили доступ к вашей почте:
# review: new
win-change = &Изменить...
# review: new
win-what-agents-did = &Действия агентов:
# review: new
win-how-to-connect = Как подключить агента

## Sign-in apps

# review: new
win-built-in = (встроенное)
# review: new
win-edit = &Изменить...

## Options

# review: new
win-options-language-label = &Язык Inbox Classic:
# review: new
win-options-restart-note = Чтобы сменить язык, перезапустите Inbox Classic.
# review: new
win-options-notify = &Уведомлять о новой почте
# review: new
win-restart-ask = Inbox Classic перейдет на язык «{ $language }» после перезапуска. Перезапустить сейчас?
# review: new
win-folders-hide = Скрыть список папок
# review: new
win-folders-pin = Закрепить список папок рядом с сообщениями
# review: new
win-folders-show = Показать папки

## The installer

# review: new
win-installer-start = Запустить Inbox Classic
# review: new
win-installer-welcome-new =
    Будет установлена почтовая программа Inbox Classic { $version }.

    Права администратора не нужны: программа устанавливается только для вашей учетной записи.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } уже установлена. Она будет установлена заново.

    Ваши учетные записи и почта сохранятся.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } будет обновлена до версии { $version }.

    Если программа запущена, сначала она будет закрыта. Ваши учетные записи и почта сохранятся.
# review: new
win-installer-older-ask = Установлена Inbox Classic { $installed }, более новая, чем { $version }. Все равно установить старую версию?
# review: new
win-installer-still-running = Inbox Classic все еще работает. Закройте ее и повторите попытку.
# review: new
win-installer-remove-mail-ask = Удалить также учетные записи и почту, которые Inbox Classic хранит на этом компьютере? Почта на серверах останется.
