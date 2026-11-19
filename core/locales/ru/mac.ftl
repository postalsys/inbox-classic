# Русский. Черновик, ожидает проверки носителем языка (см. core/locales/GLOSSARY.md).

## The app and its menus

mac-quit = Завершить Inbox Classic
mac-settings = Настройки…
mac-services = Службы
mac-hide = Скрыть Inbox Classic
mac-hide-others = Скрыть остальные
mac-show-all = Показать все
mac-check-updates = Проверить обновления…
mac-close-window = Закрыть окно
mac-redo = Повторить
mac-cut = Вырезать
mac-paste = Вставить
mac-menu-window = Окно
mac-minimize = Свернуть
mac-zoom = Изменить масштаб
mac-no-updates = Эта версия Inbox Classic не поддерживает автоматические обновления. Загрузите последнюю версию с inboxclassic.com.

## Settings

mac-settings-title = Настройки
mac-check-updates-automatically = Автоматически проверять наличие обновлений
mac-settings-updates = Обновления

## Dialogs

mac-choose = Выбрать

## The main window

mac-still-running-detail = Inbox Classic продолжает проверять почту в фоновом режиме. Нажмите значок программы в Dock, чтобы открыть ее.
mac-outbox-waiting =
    { $count ->
        [one] { $count } сообщение в папке «Исходящие»
        [few] { $count } сообщения в папке «Исходящие»
        [many] { $count } сообщений в папке «Исходящие»
       *[other] { $count } сообщения в папке «Исходящие»
    }
mac-sending = Отправка { $subject }…
mac-checking = Проверка новой почты в учетной записи «{ $account }»…
mac-account-said = { $account }: { $message }
mac-not-bundle = Эта копия Inbox Classic запущена не из пакета приложения (.app), поэтому ее нельзя выбрать почтовой программой по умолчанию.
mac-not-made-default = Не удалось сделать Inbox Classic почтовой программой по умолчанию: { $reason }
mac-tool-search = Поиск

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Текст { $count } сообщения еще индексируется, поэтому вскоре могут появиться новые результаты.
       *[other] Текст { $count } сообщений еще индексируется, поэтому вскоре могут появиться новые результаты.
    }
mac-results-everywhere =
    { $count ->
        [0] Нет результатов по запросу «{ $words }» во всех папках
        [one] { $count } результат по запросу «{ $words }» во всех папках
        [few] { $count } результата по запросу «{ $words }» во всех папках
        [many] { $count } результатов по запросу «{ $words }» во всех папках
       *[other] { $count } результата по запросу «{ $words }» во всех папках
    }
mac-results-in =
    { $count ->
        [0] Нет результатов по запросу «{ $words }» в «{ $folder }»
        [one] { $count } результат по запросу «{ $words }» в «{ $folder }»
        [few] { $count } результата по запросу «{ $words }» в «{ $folder }»
        [many] { $count } результатов по запросу «{ $words }» в «{ $folder }»
       *[other] { $count } результата по запросу «{ $words }» в «{ $folder }»
    }
mac-still-indexing =
    { $count ->
        [one] еще индексируется текст { $count } сообщения
       *[other] еще индексируется текст { $count } сообщений
    }
mac-folder-unread = { $folder }, непрочитанных: { $count }
mac-import-messages = Импорт сообщений
mac-save-messages = Сохранить сообщения
mac-save-attachments-menu = Сохранить вложения…
mac-files-not-saved =
    { $count ->
       *[other] Не удалось сохранить { $failed } из { $count } файлов.
    }
mac-no-calendar-app = Не удалось открыть приглашение в календаре. Проверьте, установлена ли на этом Mac программа для открытия файлов .ics.
mac-file-not-saved = Не удалось сохранить файл.
mac-unsubscribing = Отправка запроса на отписку: { $target }…
mac-loading-list = Загрузка…

## The compose window

mac-bold = Полужирный
mac-italic = Курсив
mac-underline = Подчеркнутый
mac-bcc = Скрытая
mac-command-click-to-open = Нажмите ⌘ и щелкните, чтобы открыть
mac-saving-to-drafts = Сохранение в папку «Черновики»…
mac-dont-save = Не сохранять

## The reading pane

mac-files =
    { $count ->
        [one] { $count } файл
        [few] { $count } файла
        [many] { $count } файлов
       *[other] { $count } файла
    }

## Accounts

mac-next = Далее
mac-name-placeholder = Анна Смирнова
mac-more-sign-in-options = Другие способы входа…
mac-add-sign-in-app = Добавить приложение для входа…
mac-looking-up = Поиск параметров для { $domain }…
mac-add-button = Добавить…
mac-properties-button = Свойства…
mac-signature-button = Текстовая подпись…
mac-security-button = Безопасность…
mac-sign-in-apps-button = Приложения для входа…

## AI agents

mac-forget-program = Удалить запись об этой программе и журнал действий ее агентов?
mac-forget-program-detail = Разрешения программы будут удалены. При следующем подключении она снова запросит разрешение.

## Sign-in apps

mac-checking-issuer = Проверка сервера авторизации: { $issuer }…
mac-edit-button = Изменить…
mac-use-for-new-accounts = Предлагать приложение «{ $name }» для новых учетных записей
mac-built-in = { $name } (встроенное)

## Other windows

mac-new-folder-button = Новая папка…
mac-edit-link = Изменить ссылку…
