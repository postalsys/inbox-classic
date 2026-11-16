# Українська. Чернетка, чекає на перевірку носієм мови (див. core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-. Mac conventions: an ellipsis (…)
# after a command that asks for more, typographic quotes and apostrophes.

## The app and its menus

# review: new
mac-quit = Вийти з Inbox Classic
# review: new
mac-settings = Параметри…
# review: new
mac-services = Послуги
# review: new
mac-hide = Сховати Inbox Classic
# review: new
mac-hide-others = Сховати інші
# review: new
mac-show-all = Показати всі
# review: new
mac-check-updates = Перевірити наявність оновлень…
# review: new
mac-close-window = Закрити вікно
# review: new
mac-redo = Повторити
# review: new
mac-cut = Вирізати
# review: new
mac-paste = Вставити
# review: new
mac-menu-window = Вікно
# review: new
mac-minimize = Згорнути
# review: new
mac-zoom = Масштабувати
# review: new
mac-no-updates = Ця версія Inbox Classic не підтримує автоматичних оновлень. Завантажте найновішу версію з inboxclassic.com.

## Settings

# review: new
mac-settings-title = Параметри
# review: new
mac-language-label = Мова:
# review: new
mac-restart-hint = Щоб змінити мову, перезапустіть Inbox Classic.
# review: new
mac-notify-new-mail = Сповіщати мене про нову пошту
# review: new
mac-restart-question = Перезапустити Inbox Classic зараз, щоб змінити мову?

## Dialogs

# review: new
mac-choose = Вибрати

## The main window

# review: new
mac-still-running-detail = Inbox Classic і далі перевіряє нову пошту у фоновому режимі. Клацніть його значок у Dock, щоб відкрити програму.
# review: new
mac-outbox-waiting =
    { $count ->
        [many] { $count } повідомлень у папці «Вихідні»
       *[other] { $count } повідомлення в папці «Вихідні»
    }
# review: new
mac-sending = Надсилання { $subject }…
# review: new
mac-checking = Перевірка нових повідомлень у { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Ця копія Inbox Classic не є пакетом програми, тому вона не може бути типовою поштовою програмою.
# review: new
mac-not-made-default = Inbox Classic не зроблено типовою поштовою програмою: { $reason }
# review: new
mac-tool-search = Пошук

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Текст { $count } повідомлення ще індексується, тому незабаром може знайтися більше.
        [few] Текст { $count } повідомлень ще індексується, тому незабаром може знайтися більше.
        [many] Текст { $count } повідомлень ще індексується, тому незабаром може знайтися більше.
       *[other] Текст { $count } повідомлення ще індексується, тому незабаром може знайтися більше.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Немає результатів для «{ $words }» у всіх папках
        [one] { $count } результат для «{ $words }» у всіх папках
        [few] { $count } результати для «{ $words }» у всіх папках
        [many] { $count } результатів для «{ $words }» у всіх папках
       *[other] { $count } результату для «{ $words }» у всіх папках
    }
# review: new
mac-results-in =
    { $count ->
        [0] Немає результатів для «{ $words }» у папці «{ $folder }»
        [one] { $count } результат для «{ $words }» у папці «{ $folder }»
        [few] { $count } результати для «{ $words }» у папці «{ $folder }»
        [many] { $count } результатів для «{ $words }» у папці «{ $folder }»
       *[other] { $count } результату для «{ $words }» у папці «{ $folder }»
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] ще індексується текст { $count } повідомлення
        [few] ще індексується текст { $count } повідомлень
        [many] ще індексується текст { $count } повідомлень
       *[other] ще індексується текст { $count } повідомлення
    }
# review: new
mac-folder-unread = { $folder }, непрочитаних: { $count }
# review: new
mac-import-messages = Імпортувати повідомлення
# review: new
mac-save-messages = Зберегти повідомлення
# review: new
mac-save-attachments-menu = Зберегти вкладення…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Не вдалося зберегти файлів: { $failed } з { $count }.
    }
# review: new
mac-no-calendar-app = На цьому Mac немає програми календаря, щоб відкривати запрошення (файли .ics).
# review: new
mac-file-not-saved = Не вдалося зберегти файл.
# review: new
mac-unsubscribing = Скасування підписки на { $target }…

## The compose window

# review: new
mac-bold = Жирний
# review: new
mac-italic = Курсив
# review: new
mac-underline = Підкреслений
# review: new
mac-bcc = Прихована
# review: new
mac-command-click-to-open = ⌘-клацання, щоб відкрити
# review: new
mac-saving-to-drafts = Збереження в «Чернетки»…
# review: new
mac-dont-save = Не зберігати

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } файл
        [few] { $count } файли
        [many] { $count } файлів
       *[other] { $count } файлу
    }

## Accounts

# review: new
mac-next = Далі
# review: new
mac-name-placeholder = Оксана Коваленко
# review: new
mac-more-sign-in-options = Інші способи входу…
# review: new
mac-add-sign-in-app = Додати застосунок для входу…
# review: new
mac-looking-up = Пошук параметрів для { $domain }…
# review: new
mac-add-button = Додати…
# review: new
mac-properties-button = Властивості…
# review: new
mac-signature-button = Підпис…
# review: new
mac-security-button = Безпека…
# review: new
mac-sign-in-apps-button = Застосунки для входу…

## AI agents

# review: new
mac-forget-program = Вилучити цю програму й історію дій її агентів?
# review: new
mac-forget-program-detail = Дозволи програми буде видалено. Наступного разу, коли вона під’єднається, у вас знову запитають дозвіл.

## Sign-in apps

# review: new
mac-checking-issuer = Перевірка { $issuer }…
# review: new
mac-edit-button = Змінити…
# review: new
mac-use-for-new-accounts = Використовувати { $name } для нових облікових записів
# review: new
mac-built-in = { $name } (вбудований)

## Other windows

# review: new
mac-new-folder-button = Нова папка…
# review: new
mac-edit-link = Змінити посилання…
