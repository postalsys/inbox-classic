# Українська. Чернетка, чекає на перевірку носієм мови (див. core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-. Mac conventions: an ellipsis (…)
# after a command that asks for more, typographic quotes and apostrophes.

## The app and its menus

mac-quit = Вийти з Inbox Classic
mac-settings = Параметри…
mac-services = Служби
mac-hide = Сховати Inbox Classic
mac-hide-others = Сховати інші програми
mac-show-all = Показати всі програми
mac-check-updates = Перевірити наявність оновлень…
mac-close-window = Закрити вікно
mac-redo = Повторити скасоване
mac-cut = Вирізати
mac-paste = Вставити
mac-menu-window = Вікно
mac-minimize = Згорнути
mac-zoom = Змінити розмір вікна
mac-no-updates = Ця версія Inbox Classic не підтримує автоматичних оновлень. Завантажте найновішу версію з inboxclassic.com.

## Settings

mac-settings-title = Параметри
mac-check-updates-automatically = Автоматично перевіряти наявність оновлень
mac-settings-updates = Оновлення

## Dialogs

mac-choose = Вибрати

## The main window

mac-still-running-detail = Inbox Classic і далі перевіряє пошту у фоновому режимі. Клацніть значок програми в Dock, щоб відкрити її.
mac-outbox-waiting =
    { $count ->
        [many] { $count } повідомлень у папці «Вихідні»
       *[other] { $count } повідомлення в папці «Вихідні»
    }
mac-sending = Надсилання повідомлення { $subject }…
mac-checking = Перевірка нової пошти в обліковому записі «{ $account }»…
mac-account-said = { $account }: { $message }
mac-not-bundle = Ця копія Inbox Classic не є пакетом програми, тому вона не може бути типовою поштовою програмою.
mac-not-made-default = Не вдалося зробити Inbox Classic типовою поштовою програмою: { $reason }
mac-tool-search = Пошук

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Текст { $count } повідомлення ще індексується, тому незабаром може знайтися більше.
        [few] Текст { $count } повідомлень ще індексується, тому незабаром може знайтися більше.
        [many] Текст { $count } повідомлень ще індексується, тому незабаром може знайтися більше.
       *[other] Текст { $count } повідомлення ще індексується, тому незабаром може знайтися більше.
    }
mac-results-everywhere =
    { $count ->
        [0] Немає результатів для «{ $words }» у всіх папках
        [one] { $count } результат для «{ $words }» у всіх папках
        [few] { $count } результати для «{ $words }» у всіх папках
        [many] { $count } результатів для «{ $words }» у всіх папках
       *[other] { $count } результату для «{ $words }» у всіх папках
    }
mac-results-in =
    { $count ->
        [0] Немає результатів для «{ $words }» у папці «{ $folder }»
        [one] { $count } результат для «{ $words }» у папці «{ $folder }»
        [few] { $count } результати для «{ $words }» у папці «{ $folder }»
        [many] { $count } результатів для «{ $words }» у папці «{ $folder }»
       *[other] { $count } результату для «{ $words }» у папці «{ $folder }»
    }
mac-still-indexing =
    { $count ->
        [one] ще індексується текст { $count } повідомлення
        [few] ще індексується текст { $count } повідомлень
        [many] ще індексується текст { $count } повідомлень
       *[other] ще індексується текст { $count } повідомлення
    }
mac-folder-unread = { $folder }, непрочитаних: { $count }
mac-import-messages = Імпортувати повідомлення
mac-save-messages = Зберегти повідомлення
mac-save-attachments-menu = Зберегти вкладення…
mac-files-not-saved = { $count ->
   *[other] Не збережено: { $failed }. Усього файлів: { $count }.
}
mac-no-calendar-app = Не вдалося відкрити запрошення. Перевірте, чи встановлено на цьому Mac програму календаря для файлів .ics.
mac-file-not-saved = Не вдалося зберегти файл.
mac-unsubscribing = Надсилання запиту на скасування підписки. Сервер: { $target }…
mac-loading-list = Завантаження…

## The compose window

mac-bold = Напівжирний
mac-italic = Курсив
mac-underline = Підкреслений
mac-bcc = Прихована
mac-command-click-to-open = ⌘-клацання, щоб відкрити
mac-saving-to-drafts = Збереження в папці «Чернетки»…
mac-dont-save = Не зберігати

## The reading pane

mac-files =
    { $count ->
        [one] { $count } файл
        [few] { $count } файли
        [many] { $count } файлів
       *[other] { $count } файлу
    }

## Accounts

mac-next = Далі
mac-name-placeholder = Оксана Коваленко
mac-more-sign-in-options = Інші способи входу…
mac-add-sign-in-app = Додати застосунок для входу…
mac-looking-up = Пошук параметрів для домену { $domain }…
mac-add-button = Додати…
mac-properties-button = Властивості…
mac-signature-button = Текстовий підпис…
mac-security-button = Безпека…
mac-sign-in-apps-button = Застосунки для входу…

## AI agents

mac-forget-program = Вилучити запис про цю програму та історію дій її агентів?
mac-forget-program-detail = Дозволи програми буде видалено. Наступного разу, коли вона під’єднається, у вас знову запитають дозвіл.

## Sign-in apps

mac-checking-issuer = Перевірка сервера авторизації: { $issuer }…
mac-edit-button = Змінити…
mac-use-for-new-accounts = Використовувати застосунок «{ $name }» для нових облікових записів
mac-built-in = { $name } (вбудований)

## Other windows

mac-new-folder-button = Нова папка…
mac-edit-link = Змінити посилання…
