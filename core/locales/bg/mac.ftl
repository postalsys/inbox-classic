# Български. Чернова, очаква преглед от носител на езика (вж. core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, curly quotes. Bulgarian menus use sentence case.

## The app and its menus

mac-quit = Изход от Inbox Classic
mac-settings = Настройки…
mac-services = Услуги
mac-hide = Скриване на Inbox Classic
mac-hide-others = Скриване на другите
mac-show-all = Показване на всички
mac-check-updates = Проверка за обновления…
mac-close-window = Затваряне на прозореца
mac-redo = Повтаряне
mac-cut = Изрязване
mac-paste = Поставяне
mac-menu-window = Прозорец
mac-minimize = Минимизиране
mac-zoom = Увеличаване на прозореца
mac-no-updates = Тази версия на Inbox Classic не поддържа автоматични обновления. Изтеглете последната версия от inboxclassic.com.

## Settings

mac-settings-title = Настройки
mac-check-updates-automatically = Автоматична проверка за обновления
mac-settings-updates = Обновления

## Dialogs

mac-choose = Избиране

## The main window

mac-still-running-detail = Inbox Classic продължава да проверява за нова поща във фонов режим. Щракнете върху иконата ѝ в Dock, за да отворите приложението.
mac-outbox-waiting =
    { $count ->
        [one] { $count } съобщение в „Изходящи“
       *[other] { $count } съобщения в „Изходящи“
    }
mac-sending = Изпращане на { $subject }…
mac-checking = Проверка за нови съобщения в { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Това копие на Inbox Classic не е пакет на приложение (.app) и не може да бъде зададено като пощенска програма по подразбиране.
mac-not-made-default = Inbox Classic не беше зададена като пощенска програма по подразбиране: { $reason }
mac-tool-search = Търсене

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Текстът на { $count } съобщение все още се индексира, затова скоро може да се появят още резултати.
       *[other] Текстът на { $count } съобщения все още се индексира, затова скоро може да се появят още резултати.
    }
mac-results-everywhere =
    { $count ->
        [0] Няма резултати за „{ $words }“ във всички папки
        [one] { $count } резултат за „{ $words }“ във всички папки
       *[other] { $count } резултата за „{ $words }“ във всички папки
    }
mac-results-in =
    { $count ->
        [0] Няма резултати за „{ $words }“ в „{ $folder }“
        [one] { $count } резултат за „{ $words }“ в „{ $folder }“
       *[other] { $count } резултата за „{ $words }“ в „{ $folder }“
    }
mac-still-indexing =
    { $count ->
        [one] текстът на { $count } съобщение все още се индексира
       *[other] текстът на { $count } съобщения все още се индексира
    }
mac-folder-unread = { $folder }, непрочетени: { $count }
mac-import-messages = Импортиране на съобщения
mac-save-messages = Запазване на съобщения
mac-save-attachments-menu = Запазване на прикачените файлове…
mac-files-not-saved =
    { $count ->
       *[other] Неуспешно запазване: { $failed } от общо { $count } файла.
    }
mac-no-calendar-app = Поканата (файл .ics) не можа да се отвори с програма за календар. Проверете дали такава програма е инсталирана и настроена да отваря .ics файлове.
mac-file-not-saved = Файлът не можа да бъде запазен.
mac-unsubscribing = Отписване от { $target }…
mac-loading-list = Зареждане…

## The compose window

mac-bold = Удебелен
mac-italic = Курсив
mac-underline = Подчертан
mac-bcc = Скрито копие
mac-command-click-to-open = ⌘-щракване за отваряне
mac-saving-to-drafts = Запазване в „Чернови“…
mac-dont-save = Не запазвай

## The reading pane

mac-files =
    { $count ->
        [one] { $count } файл
       *[other] { $count } файла
    }

## Accounts

mac-next = Напред
mac-name-placeholder = Мария Иванова
mac-more-sign-in-options = Още начини за влизане…
mac-add-sign-in-app = Добавяне на приложение за влизане…
mac-looking-up = Търсене на настройките за { $domain }…
mac-add-button = Добавяне…
mac-properties-button = Свойства…
mac-signature-button = Подпис…
mac-security-button = Защита…
mac-sign-in-apps-button = Приложения за влизане…

## AI agents

mac-forget-program = Искате ли да премахнете запазените разрешения на тази програма и историята на действията на агентите ѝ?
mac-forget-program-detail = Разрешенията на програмата ще бъдат изтрити. Следващия път, когато се свърже, ще бъдете попитани отново за разрешение.

## Sign-in apps

mac-checking-issuer = Проверка на { $issuer }…
mac-edit-button = Редактиране…
mac-use-for-new-accounts = Използване на { $name } за нови акаунти
mac-built-in = { $name } (вградено)

## Other windows

mac-new-folder-button = Нова папка…
mac-edit-link = Редактиране на връзката…
