# Български. Чернова, очаква преглед от носител на езика (вж. core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, curly quotes. Bulgarian menus use sentence case.

## The app and its menus

# review: new
mac-quit = Изход от Inbox Classic
# review: new
mac-settings = Настройки…
# review: new
mac-services = Услуги
# review: new
mac-hide = Скриване на Inbox Classic
# review: new
mac-hide-others = Скриване на другите
# review: new
mac-show-all = Показване на всички
# review: new
mac-check-updates = Проверка за обновления…
# review: new
mac-close-window = Затваряне на прозореца
# review: new
mac-redo = Повтаряне
# review: new
mac-cut = Изрязване
# review: new
mac-paste = Поставяне
# review: new
mac-menu-window = Прозорец
# review: new
mac-minimize = Минимизиране
# review: new
mac-zoom = Мащабиране
# review: new
mac-no-updates = Тази версия на Inbox Classic не поддържа автоматични обновления. Изтеглете последната версия от inboxclassic.com.

## Settings

# review: new
mac-settings-title = Настройки
# review: new
mac-check-updates-automatically = Автоматична проверка за обновления
# review: new
mac-settings-updates = Обновления

## Dialogs

# review: new
mac-choose = Избиране

## The main window

# review: new
mac-still-running-detail = Inbox Classic продължава да проверява за нова поща във фонов режим. Щракнете върху иконата ѝ в Dock, за да отворите приложението.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } съобщение в „Изходящи“
       *[other] { $count } съобщения в „Изходящи“
    }
# review: new
mac-sending = Изпращане на { $subject }…
# review: new
mac-checking = Проверка за нови съобщения в { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Това копие на Inbox Classic не е пакет на приложение, затова не може да бъде пощенската програма по подразбиране.
# review: new
mac-not-made-default = Inbox Classic не беше зададена като пощенска програма по подразбиране: { $reason }
# review: new
mac-tool-search = Търсене

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Текстът на { $count } съобщение все още се индексира, затова скоро може да бъдат намерени още.
       *[other] Текстът на { $count } съобщения все още се индексира, затова скоро може да бъдат намерени още.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Няма резултати за „{ $words }“ във всички папки
        [one] { $count } резултат за „{ $words }“ във всички папки
       *[other] { $count } резултата за „{ $words }“ във всички папки
    }
# review: new
mac-results-in =
    { $count ->
        [0] Няма резултати за „{ $words }“ в { $folder }
        [one] { $count } резултат за „{ $words }“ в { $folder }
       *[other] { $count } резултата за „{ $words }“ в { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] текстът на { $count } съобщение все още се индексира
       *[other] текстът на { $count } съобщения все още се индексира
    }
# review: new
mac-folder-unread = { $folder }, непрочетени: { $count }
# review: new
mac-import-messages = Импортиране на съобщения
# review: new
mac-save-messages = Запазване на съобщения
# review: new
mac-save-attachments-menu = Запазване на прикачените файлове…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] { $failed } от { $count } файла не можаха да бъдат запазени.
    }
# review: new
mac-no-calendar-app = На този Mac няма програма за календар, с която да се отварят покани (файлове .ics).
# review: new
mac-file-not-saved = Файлът не можа да бъде запазен.
# review: new
mac-unsubscribing = Отписване от { $target }…
# review: new
mac-loading-list = Зареждане…

## The compose window

# review: new
mac-bold = Удебелен
# review: new
mac-italic = Курсив
# review: new
mac-underline = Подчертан
# review: new
mac-bcc = Скрито копие
# review: new
mac-command-click-to-open = ⌘-щракване за отваряне
# review: new
mac-saving-to-drafts = Запазване в „Чернови“…
# review: new
mac-dont-save = Не запазвай

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } файл
       *[other] { $count } файла
    }

## Accounts

# review: new
mac-next = Напред
# review: new
mac-name-placeholder = Мария Иванова
# review: new
mac-more-sign-in-options = Още начини за влизане…
# review: new
mac-add-sign-in-app = Добавяне на приложение за влизане…
# review: new
mac-looking-up = Търсене на настройките за { $domain }…
# review: new
mac-add-button = Добавяне…
# review: new
mac-properties-button = Свойства…
# review: new
mac-signature-button = Подпис…
# review: new
mac-security-button = Защита…
# review: new
mac-sign-in-apps-button = Приложения за влизане…

## AI agents

# review: new
mac-forget-program = Да се премахне ли тази програма и историята на действията на агентите ѝ?
# review: new
mac-forget-program-detail = Разрешенията на програмата ще бъдат изтрити. Следващия път, когато се свърже, ще бъдете попитани отново за разрешение.

## Sign-in apps

# review: new
mac-checking-issuer = Проверка на { $issuer }…
# review: new
mac-edit-button = Редактиране…
# review: new
mac-use-for-new-accounts = Използване на { $name } за нови акаунти
# review: new
mac-built-in = { $name } (вградено)

## Other windows

# review: new
mac-new-folder-button = Нова папка…
# review: new
mac-edit-link = Редактиране на връзката…
