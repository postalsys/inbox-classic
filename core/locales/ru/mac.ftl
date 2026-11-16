# Русский. Черновик, ожидает проверки носителем языка (см. core/locales/GLOSSARY.md).

## The app and its menus

# review: new
mac-quit = Завершить Inbox Classic
# review: new
mac-settings = Настройки…
# review: new
mac-services = Службы
# review: new
mac-hide = Скрыть Inbox Classic
# review: new
mac-hide-others = Скрыть остальные
# review: new
mac-show-all = Показать все
# review: new
mac-check-updates = Проверить обновления…
# review: new
mac-close-window = Закрыть окно
# review: new
mac-redo = Повторить
# review: new
mac-cut = Вырезать
# review: new
mac-paste = Вставить
# review: new
mac-menu-window = Окно
# review: new
mac-minimize = Свернуть
# review: new
mac-zoom = Изменить масштаб
# review: new
mac-no-updates = Эта версия Inbox Classic не поддерживает автоматические обновления. Загрузите последнюю версию с inboxclassic.com.

## Settings

# review: new
mac-settings-title = Настройки
# review: new
mac-language-label = Язык:
# review: new
mac-restart-hint = Чтобы сменить язык, перезапустите Inbox Classic.
# review: new
mac-notify-new-mail = Уведомлять о новой почте
# review: new
mac-restart-question = Перезапустить Inbox Classic сейчас, чтобы сменить язык?

## Dialogs

# review: new
mac-choose = Выбрать

## The main window

# review: new
mac-still-running-detail = Inbox Classic продолжает проверять новую почту в фоновом режиме. Нажмите значок программы в Dock, чтобы открыть ее.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } сообщение в папке «Исходящие»
        [few] { $count } сообщения в папке «Исходящие»
        [many] { $count } сообщений в папке «Исходящие»
       *[other] { $count } сообщения в папке «Исходящие»
    }
# review: new
mac-sending = Отправка { $subject }…
# review: new
mac-checking = Проверка новых сообщений в { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Эта копия Inbox Classic не является пакетом приложения, поэтому не может быть почтовой программой по умолчанию.
# review: new
mac-not-made-default = Inbox Classic не стала почтовой программой по умолчанию: { $reason }
# review: new
mac-tool-search = Поиск

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Текст { $count } сообщения еще индексируется, поэтому скоро может найтись больше.
       *[other] Текст { $count } сообщений еще индексируется, поэтому скоро может найтись больше.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Нет результатов по запросу «{ $words }» во всех папках
        [one] { $count } результат по запросу «{ $words }» во всех папках
        [few] { $count } результата по запросу «{ $words }» во всех папках
        [many] { $count } результатов по запросу «{ $words }» во всех папках
       *[other] { $count } результата по запросу «{ $words }» во всех папках
    }
# review: new
mac-results-in =
    { $count ->
        [0] Нет результатов по запросу «{ $words }» в папке «{ $folder }»
        [one] { $count } результат по запросу «{ $words }» в папке «{ $folder }»
        [few] { $count } результата по запросу «{ $words }» в папке «{ $folder }»
        [many] { $count } результатов по запросу «{ $words }» в папке «{ $folder }»
       *[other] { $count } результата по запросу «{ $words }» в папке «{ $folder }»
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] еще индексируется текст { $count } сообщения
       *[other] еще индексируется текст { $count } сообщений
    }
# review: new
mac-folder-unread = { $folder }, непрочитанных: { $count }
# review: new
mac-import-messages = Импорт сообщений
# review: new
mac-save-messages = Сохранить сообщения
# review: new
mac-save-attachments-menu = Сохранить вложения…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Не удалось сохранить { $failed } из { $count } файлов.
    }
# review: new
mac-no-calendar-app = На этом Mac нет программы календаря, чтобы открывать приглашения (файлы .ics).
# review: new
mac-file-not-saved = Не удалось сохранить файл.
# review: new
mac-unsubscribing = Отписка от { $target }…
mac-loading-list = Загрузка…

## The compose window

# review: new
mac-bold = Жирный
# review: new
mac-italic = Курсив
# review: new
mac-underline = Подчеркнутый
# review: new
mac-bcc = Скрытая копия
# review: new
mac-command-click-to-open = ⌘-нажатие, чтобы открыть
# review: new
mac-saving-to-drafts = Сохранение в папку «Черновики»…
# review: new
mac-dont-save = Не сохранять

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } файл
        [few] { $count } файла
        [many] { $count } файлов
       *[other] { $count } файла
    }

## Accounts

# review: new
mac-next = Далее
# review: new
mac-name-placeholder = Анна Смирнова
# review: new
mac-more-sign-in-options = Другие способы входа…
# review: new
mac-add-sign-in-app = Добавить приложение для входа…
# review: new
mac-looking-up = Поиск параметров для { $domain }…
# review: new
mac-add-button = Добавить…
# review: new
mac-properties-button = Свойства…
# review: new
mac-signature-button = Подпись…
# review: new
mac-security-button = Безопасность…
# review: new
mac-sign-in-apps-button = Приложения для входа…

## AI agents

# review: new
mac-forget-program = Удалить эту программу и журнал действий ее агентов?
# review: new
mac-forget-program-detail = Разрешения программы будут удалены. При следующем подключении она снова запросит разрешение.

## Sign-in apps

# review: new
mac-checking-issuer = Проверка { $issuer }…
# review: new
mac-edit-button = Изменить…
# review: new
mac-use-for-new-accounts = Использовать { $name } для новых учетных записей
# review: new
mac-built-in = { $name } (встроенное)

## Other windows

# review: new
mac-new-folder-button = Новая папка…
# review: new
mac-edit-link = Изменить ссылку…
