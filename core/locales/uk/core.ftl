# Українська. Чернетка, чекає на перевірку носієм мови (див. core/locales/GLOSSARY.md).
# Plurals: [one] (1, 21, 31...), [few] (2-4, 22-24...), [many] (0, 5-20, 25-30...), *[other] (fractions).

## Counts and sizes

messages = { $count ->
    [one] { $count } повідомлення
    [few] { $count } повідомлення
    [many] { $count } повідомлень
   *[other] { $count } повідомлення
}
# the separator of decimals in sizes: 2,4 МБ
decimal-separator = ,
list-separator = { ", " }
size-bytes = { $count ->
    [one] { $count } байт
    [few] { $count } байти
    [many] { $count } байтів
   *[other] { $count } байта
}
size-kb = { $size } КБ
size-mb = { $size } МБ
size-gb = { $size } ГБ
send-delay-off = Вимкнено
send-delay-seconds = { $count ->
    [one] { $count } секунда
    [few] { $count } секунди
    [many] { $count } секунд
   *[other] { $count } секунди
}
# the status bar: "12 messages, 3 unread"
list-counts = { $messages }, непрочитаних: { $unread }
list-counts-selected = { $messages }, непрочитаних: { $unread }, виділено: { $selected }
# the status bar while searching: "12 found, 3 unread"
list-counts-found = Знайдено: { $found }, непрочитаних: { $unread }
list-counts-found-selected = Знайдено: { $found }, непрочитаних: { $unread }, виділено: { $selected }
list-counts-none = Повідомлень не знайдено

## Special folders, as Outlook names them

folder-inbox = Вхідні
folder-sent = Надіслані
folder-deleted = Видалені
folder-drafts = Чернетки
folder-junk = Небажана пошта
folder-archive = Архів

## The reading pane

reader-no-message = Повідомлення не вибрано.
reader-downloading = Повідомлення завантажується…
reader-downloading-detail = Повідомлення з’явиться тут, щойно завантаження завершиться.
reader-downloading-size = Розмір повідомлення: { $size }. Воно з’явиться тут, щойно завантажиться.
reader-failed = Не вдалося завантажити повідомлення
reader-failed-network = Не вдалося встановити з’єднання з поштовим сервером або воно перервалося ({ $reason }).
reader-failed-security = Не вдалося захистити з’єднання з поштовим сервером ({ $reason }).
reader-failed-other = Відповідь поштового сервера: { $reason }.
reader-retry-note = Спробу буде повторено, коли обліковий запис знову під’єднається.
reader-unreadable = Це повідомлення неможливо показати: { $error }
message-source-title = Вихідний текст повідомлення: { $subject }
message-source-untitled = Вихідний текст повідомлення
## Printing a message, and the header of a message quoted in a reply or forward

header-from = Від
header-date = Дата
header-to = Кому
header-cc = Копія
header-sent = Надіслано
header-subject = Тема
header-security = Безпека
header-part = Частина { $number }
quote-original = ----- Початкове повідомлення -----
fold-show-earlier = Показати попередні повідомлення

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Ваше повідомлення не доставлено
bounce-delayed = Ваше повідомлення ще не доставлено
bounce-delayed-note = Ваш поштовий сервер досі намагається його доставити. Надсилати його знову не потрібно.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Показати недоставлене повідомлення
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Показати повідомлення, доставка якого затримується
bounce-what-to-do = Що можна зробити:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Поки нічого. Якщо доставити його так і не вдасться, ви отримаєте ще одне сповіщення.
bounce-delayed-row-do = Поки нічого. Ваш поштовий сервер досі намагається його доставити, і якщо це не вдасться, ви отримаєте ще одне сповіщення.
# folds the receiving server's own words
bounce-details = Подробиці
# a recipient the notice does not name
bounce-someone = Одержувач
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Сервер: { $server }
bounce-status = Стан: { $status }
bounce-reported-by = Повідомив: { $server }
bounce-retry-minutes = Сервер одержувача попросив зачекати { $count ->
    [1] хвилину
    [one] { $count } хвилину
    [few] { $count } хвилини
    [many] { $count } хвилин
   *[other] { $count } хвилини
} до наступної спроби.
bounce-retry-hours = Сервер одержувача попросив зачекати { $count ->
    [1] годину
    [one] { $count } годину
    [few] { $count } години
    [many] { $count } годин
   *[other] { $count } години
} до наступної спроби.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Чорний список: { $lists }
bounce-user-unknown = Такої адреси не існує
bounce-user-unknown-why = На сервері одержувача немає поштової скриньки з цією адресою. Можливо, в адресі помилка, або людина більше нею не користується.
bounce-user-unknown-do = Перевірте написання адреси або запитайте в людини, якою адресою вона користується зараз.
bounce-invalid-address = Адреса недійсна
bounce-invalid-address-why = Адресу записано неправильно, тому на неї неможливо надіслати пошту.
bounce-invalid-address-do = Перевірте, чи немає помилок: зайвого пробілу, пропущеної літери або відсутньої частини після @.
bounce-mailbox-disabled = Поштову скриньку закрито
bounce-mailbox-disabled-why = Адреса існує, але її поштову скриньку вимкнено або вона більше не використовується.
bounce-mailbox-disabled-do = Зв’яжіться з людиною іншим способом і запитайте адресу, якою вона користується зараз.
bounce-mailbox-full = Поштова скринька переповнена
bounce-mailbox-full-why = У поштовій скриньці одержувача немає місця для нової пошти.
bounce-mailbox-full-do = Надішліть повідомлення знову через кілька днів або зв’яжіться з одержувачем іншим способом.
bounce-spam-blocked = Відхилено як спам
bounce-spam-blocked-why = Сервер одержувача вважав повідомлення спамом.
bounce-spam-blocked-do = Надішліть його знову без того, що схоже на спам, наприклад без великої кількості посилань, скорочених посилань чи великого вкладення. Якщо це повторюється, зверніться до свого поштового провайдера.
bounce-virus-detected = Відхилено через вірус
bounce-virus-detected-why = Сервер одержувача повідомив про вірус або інший шкідливий вміст у повідомленні чи його вкладеннях.
bounce-virus-detected-do = Перевірте вкладення антивірусом. Деякі сервери відхиляють будь-які програми й архіви, тому діліться такими файлами за посиланням.
bounce-ip-blocklisted = Ваш поштовий сервер у чорному списку
bounce-ip-blocklisted-why = Сервер одержувача не приймає пошту від сервера, що надіслав ваше повідомлення, бо адреса того сервера є в чорному списку.
bounce-ip-blocklisted-do = Проблема не в повідомленні. Перешліть це сповіщення своєму поштовому провайдеру й попросіть вилучити сервер зі списку.
bounce-domain-blocklisted = Домен у чорному списку
bounce-domain-blocklisted-why = Сервер одержувача відхиляє повідомлення, бо домен вашої адреси або домен у посиланнях повідомлення є в чорному списку.
bounce-domain-blocklisted-do = Якщо в повідомленні є посилання, спробуйте надіслати його без них. Інакше перешліть це сповіщення тому, хто обслуговує пошту вашого домену.
bounce-policy-blocked = Відхилено правилами сервера одержувача
bounce-policy-blocked-why = Правила сервера одержувача не пропускають це повідомлення, наприклад через його розмір, вкладення або відправника.
bounce-policy-blocked-do = Причину часто видно зі слів самого сервера в розділі «Подробиці». Запитайте одержувача, чи може він приймати таку пошту.
bounce-geo-blocked = Відхилено через місце відправлення
bounce-geo-blocked-why = Сервер одержувача не приймає пошту з країни чи мережі, де розташований ваш поштовий сервер.
bounce-geo-blocked-do = Зв’яжіться з людиною іншим способом або зверніться до свого поштового провайдера.
bounce-relay-denied = Сервер відмовився передати повідомлення далі
bounce-relay-denied-why = Сервер відмовився доставити повідомлення далі, часто тому, що його надіслано без входу або через сервер, який не обслуговує цього одержувача.
bounce-relay-denied-do = У параметрах облікового запису перевірте сервер вихідної пошти та дані для входу на нього.
bounce-auth-failure = Не вдалося перевірити вашу адресу відправника
bounce-auth-failure-why = Сервер одержувача не зміг підтвердити, що повідомлення справді надійшло з вашого домену (SPF, DKIM або DMARC).
bounce-auth-failure-do = Перешліть це сповіщення тому, хто обслуговує пошту вашого домену: його налаштування треба виправити. Тим часом може допомогти надсилання через власний сервер вашого провайдера.
bounce-rate-limited = Забагато пошти водночас
bounce-rate-limited-why = Сервер одержувача тимчасово приймає менше повідомлень від вашого поштового сервера.
bounce-rate-limited-do = Зачекайте трохи й надішліть знову. Якщо одержувачів багато, спробуйте надсилати меншій кількості за раз.
bounce-greylisting = Ненадовго затримано
bounce-greylisting-why = Сервер одержувача просить невідомих відправників спробувати трохи пізніше. Це звичайна перевірка проти спаму.
bounce-greylisting-do = Якщо доставку лише затримано, зачекайте: поштовий сервер зазвичай повторює спробу сам. Якщо повідомлено про остаточну відмову, перевірте подробиці перед повторним надсиланням.
bounce-server-error = Проблема на сервері одержувача
bounce-server-error-why = Сервер одержувача недоступний або не зміг прийняти повідомлення через власну проблему.
bounce-server-error-do = Надішліть повідомлення знову пізніше. Якщо не вдається й далі, перевірте частину адреси після @ на помилки.
bounce-unknown = Не доставлено
bounce-unknown-why = Сповіщення не пояснює чітко, чому.
bounce-unknown-do = Більше можуть сказати слова самого сервера в розділі «Подробиці». Якщо вони не допомагають, перешліть це сповіщення своєму поштовому провайдеру.

## Several messages selected

selection-title = { $count ->
    [one] Виділено { $count } повідомлення
    [few] Виділено { $count } повідомлення
    [many] Виділено { $count } повідомлень
   *[other] Виділено { $count } повідомлення
}
selection-unread = Непрочитаних: { $count }
selection-flagged = З прапорцем: { $count }
delete-for-good-one = Це повідомлення буде видалено назавжди. Видалити його?
delete-for-good-all = Ці повідомлення ({ $count }) буде видалено назавжди. Видалити їх?
delete-for-good-some = Назавжди буде видалено { $count } з { $total }. Видалити повідомлення?
done-read = { $count ->
   *[other] Позначено як прочитані: { $messages }
}
done-unread = { $count ->
   *[other] Позначено як непрочитані: { $messages }
}
done-flagged = { $count ->
   *[other] Позначено прапорцем: { $messages }
}
done-unflagged = Знято прапорець: { $messages }
done-deleted-for-good = { $count ->
   *[other] Видалено назавжди: { $messages }
}
done-archived = { $count ->
   *[other] Заархівовано: { $messages }
}
done-moved = { $count ->
   *[other] Переміщено: { $messages }. Призначення: { $folder }
}
done-copied = { $count ->
   *[other] Скопійовано: { $messages }. Призначення: { $folder }
}
done-moving = { $count ->
   *[other] Переміщення: { $messages }. Призначення: { $folder }...
}
done-copying = { $count ->
   *[other] Копіювання: { $messages }. Призначення: { $folder }...
}
done-moved-back = { $count ->
   *[other] Повернено: { $messages }. Призначення: { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [1] Розмова відстежується
    [one] Відстежується { $count } розмова
    [few] Відстежуються { $count } розмови
    [many] Відстежується { $count } розмов
   *[other] Відстежується { $count } розмови
}
done-unwatched = { $count ->
    [1] Розмова більше не відстежується
    [one] Більше не відстежується { $count } розмова
    [few] Більше не відстежуються { $count } розмови
    [many] Більше не відстежується { $count } розмов
   *[other] Більше не відстежується { $count } розмови
}
done-ignored = { $count ->
    [1] Розмова ігнорується
    [one] Ігнорується { $count } розмова
    [few] Ігноруються { $count } розмови
    [many] Ігнорується { $count } розмов
   *[other] Ігнорується { $count } розмови
}
done-unignored = { $count ->
    [1] Розмова більше не ігнорується
    [one] Більше не ігнорується { $count } розмова
    [few] Більше не ігноруються { $count } розмови
    [many] Більше не ігнорується { $count } розмов
   *[other] Більше не ігнорується { $count } розмови
}
# the destination after "у" (into), in the accusative: "Переміщено 2 повідомлення у свої папки"
their-folders = відповідні папки
undo-move = Скасувати переміщення
undo-delete = Скасувати видалення
undo-archive = Скасувати архівування
undo-junk = Скасувати позначку «Небажане»
undo-not-junk = Скасувати позначку «Звичайне»
undo-send = Скасувати надсилання
nothing-to-undo = Немає чого скасовувати.
messages-gone = Цих повідомлень уже немає.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Ця папка не може містити повідомлень.
not-archived-here = Повідомлення з цієї папки неможливо заархівувати.
not-emptied-here = Очистити можна лише папки «Видалені» та «Небажана пошта».
next-unread-question = У папці «{ $folder }» більше немає непрочитаних повідомлень.

    Перейти до папки «{ $next }», наступної з непрочитаними повідомленнями?
no-unread-left = Непрочитаних повідомлень не залишилося.
empty-question = { $count ->
    [1] Очистити папку «{ $folder }»?

        Повідомлення в ній буде видалено назавжди. Відновити його буде неможливо.
   *[other] Очистити папку «{ $folder }»?

        Усі повідомлення в ній ({ $messages }) буде видалено назавжди. Відновити їх буде неможливо.
}
no-junk-folder = У цьому обліковому записі немає папки «Небажана пошта», куди можна перемістити повідомлення.
no-inbox-folder = У цьому обліковому записі немає папки «Вхідні», куди можна перемістити повідомлення.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
done-flagged-color = Позначено { $color ->
    [red] червоним
    [orange] помаранчевим
    [yellow] жовтим
    [green] зеленим
    [blue] синім
    [purple] фіолетовим
   *[gray] сірим
} прапорцем: { $messages }
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Червоний
    [orange] Помаранчевий
    [yellow] Жовтий
    [green] Зелений
    [blue] Синій
    [purple] Фіолетовий
   *[gray] Сірий
}

## The Move and Copy window

move-window-title-move = { $count ->
    [1] Перемістити повідомлення
    [many] Перемістити { $count } повідомлень
   *[other] Перемістити { $count } повідомлення
}
move-window-title-copy = { $count ->
    [1] Копіювати повідомлення
    [many] Копіювати { $count } повідомлень
   *[other] Копіювати { $count } повідомлення
}
move-window-prompt-move = { $count ->
    [1] Перемістити виділене повідомлення в:
    [many] Перемістити { $count } виділених повідомлень у:
   *[other] Перемістити виділені повідомлення ({ $count }) у:
}
move-window-prompt-copy = { $count ->
    [1] Копіювати виділене повідомлення в:
    [many] Копіювати { $count } виділених повідомлень у:
   *[other] Копіювати виділені повідомлення ({ $count }) у:
}
# the folders used last, over the folder tree
targets-recent = Нещодавні
# the folder the messages are in, which can not be chosen
target-current = { $folder } (поточна)
# a folder used last, with its account when there are several: "Archive (Work)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Переміщення повідомлення №{ $done }. Усього: { $messages }. Призначення: { $folder }...
transfer-copying = Копіювання повідомлення №{ $done }. Усього: { $messages }. Призначення: { $folder }...
# the destination after "у" (into), in the accusative
transfer-another-account = інший обліковий запис
transfer-folder-gone = папки призначення більше немає
transfer-not-on-server = повідомлення вже немає на сервері
transfer-not-moved = { $count ->
   *[other] Не вдалося перемістити в інший обліковий запис { $messages }: { $reason }
}
transfer-not-copied = { $count ->
   *[other] Не вдалося скопіювати в інший обліковий запис { $messages }: { $reason }
}
transfer-none-moved = Не вдалося перемістити жодного повідомлення
transfer-none-copied = Не вдалося скопіювати жодного повідомлення

## Messages as files

export-not-in-time = повідомлення не вдалося вчасно завантажити
export-not-saved = Не збережено: { $failed }. Усього: { $messages } ({ $problems })
export-not-attached = не вдалося вкласти повідомлення: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
   *[other] Збережено { $messages } у папку «{ $folder }»
}
download-progress = Завантаження: { $done } з { $total }
download-done = Завантажено: { $size }
downloading-messages = { $count ->
   *[other] Завантаження: { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
   *[other] Додано до черги імпорту: { $messages }. Папка: «{ $folder }»
}
import-not-put = Не вдалося імпортувати ці файли:

    { $problems }
## Problems the windows show

error-store = локальне сховище: { $error }
error-not-found = не знайдено
error-closed = завершення роботи
error-other-account = у браузері виконано вхід в обліковий запис { $email }, а не в цей обліковий запис
# a password or sign-in the mail server refused, with the server's words
failure-authentication = сервер відхилив вхід ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = не вдалося встановити з’єднання із сервером або воно перервалося ({ $reason })
error-in-use = застосунок неможливо вилучити, поки його використовують для входу ці облікові записи: { $accounts }
error-turned-off = цей застосунок для входу вимкнено для нових облікових записів
error-folder-name = назва папки має містити від 1 до 200 символів і не може містити керівних символів
error-folder-separator = на цьому сервері назва папки не може містити «{ $separator }»
error-folder-special = папку «Вхідні» та спеціальні папки неможливо перейменувати або видалити
error-no-recipients = у повідомлення немає одержувачів
error-bad-address = «{ $address }» не є адресою електронної пошти
error-not-own-address = Адреса { $address } не належить до адрес відправника цього облікового запису. Додайте її в поле «Інші адреси для надсилання повідомлень» у властивостях облікового запису.
rule-query-refused = Правила не можуть фільтрувати за папкою чи датою ({ $words }).
rule-no-query = Введіть умови пошуку для вхідних повідомлень.
rule-no-action = Виберіть принаймні одну дію для правила.
error-attachment = не вдалося прочитати файл «{ $path }»: { $error }
error-no-drafts = в обліковому записі немає папки «Чернетки», щоб зберегти повідомлення
error-draft-attachment = не вдалося зберегти вкладення чернетки: { $error }
error-password-not-saved = не вдалося зберегти пароль для наступного запуску: { $error }
error-sign-in-not-saved = не вдалося зберегти нові дані входу для наступного запуску: { $error }
error-import-unreadable = не вдалося прочитати файл «{ $path }»: { $error }
error-import-too-large = розмір файлу «{ $path }» перевищує 50 МБ
error-import-not-mail = файл «{ $path }» не є повідомленням електронної пошти
error-list-answered = сервер розсилки повернув код відповіді { $status }
error-not-built = не вдалося створити повідомлення
error-outbox-waits = { $count ->
    [1] повідомлення залишається в папці «Вихідні»; наступна перевірка пошти повторить спробу надсилання
    [one] у папці «Вихідні» залишається { $count } повідомлення; наступна перевірка пошти повторить спробу надсилання
    [few] у папці «Вихідні» залишаються { $count } повідомлення; наступна перевірка пошти повторить спробу надсилання
    [many] у папці «Вихідні» залишається { $count } повідомлень; наступна перевірка пошти повторить спробу надсилання
   *[other] у папці «Вихідні» залишається { $count } повідомлення; наступна перевірка пошти повторить спробу надсилання
}
error-draft-not-removed = не вдалося вилучити попередню чернетку повідомлення з папки «Чернетки»: { $reason }
error-sent-but = повідомлення надіслано, але { $problem }
error-sent-still-in-outbox = воно досі в папці «Вихідні»: { $error }
error-sent-no-copy = не вдалося зберегти копію в папці «Надіслані»: { $reason }
error-no-password = для цього облікового запису немає пароля
error-no-sign-in = для цього облікового запису немає даних входу
error-provider-missing = ця версія не може виконати вхід. Провайдер: { $provider }. Можливо, застосунок для входу вилучено
error-provider-servers = сервери цього облікового запису не збігаються із серверами його застосунку для входу
error-app-scopes = { $reason }. Поштовий сервер не прийняв токен застосунку для входу: перевірте, чи області доступу (scopes) застосунку надають доступ до пошти
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Вбудований застосунок для входу Google налаштовано для тестових користувачів і типово вимкнено для нових облікових записів. Скористайтеся власним застосунком для входу Google або паролем застосунку, якщо ваш обліковий запис його підтримує. Тестові користувачі можуть увімкнути вбудований застосунок у вікні «Застосунки для входу», яке відкривається зі списку облікових записів.
sign-in-off-other = Цей застосунок вимкнено у вікні «Застосунки для входу». Відкрийте його зі списку облікових записів, щоб увімкнути застосунок знову.
sign-in-app-no-name = застосунку для входу потрібна назва
sign-in-app-no-client = бракує ідентифікатора клієнта
sign-in-app-no-scopes = для застосунку потрібно вказати області доступу (scopes), що надають доступ до пошти
sign-in-app-bad-host = для сервера { $server } не вказано коректної назви вузла або порту
sign-in-app-plain = сервер { $server } має використовувати SSL/TLS або STARTTLS
sign-in-app-not-checked = сервер авторизації ще не перевірено
sign-in-app-issuer-changed = сервер авторизації змінився: введіть секрет клієнта знову або вилучіть його
sign-in-register-google = У Google Cloud Console створіть клієнт OAuth типу «Desktop app» з областю доступу https://mail.google.com/ на екрані згоди. Поки застосунок у режимі тестування, входити можуть лише його тестові користувачі.
sign-in-register-microsoft = У Microsoft Entra зареєструйте застосунок із платформою «Mobile and desktop applications», URI переспрямування http://localhost, дозволом на способи входу для публічних клієнтів та делегованими дозволами IMAP.AccessAsUser.All, SMTP.Send і offline_access. Лише для своєї організації вкажіть сервером авторизації https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Зареєструйте публічний клієнт для встановлюваної програми з наведеним нижче URI переспрямування. Провайдер має дозволяти в ньому будь-який порт (RFC 8252). Додайте область доступу (scope), яку провайдер використовує для доступу до пошти.
## Calendar invitations

repeats = Повторення
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Щодня
        [one] Раз на { $interval } день
        [few] Раз на { $interval } дні
        [many] Раз на { $interval } днів
       *[other] Раз на { $interval } дня
    }
    [week] { $interval ->
        [1] Щотижня
        [one] Раз на { $interval } тиждень
        [few] Раз на { $interval } тижні
        [many] Раз на { $interval } тижнів
       *[other] Раз на { $interval } тижня
    }
    [month] { $interval ->
        [1] Щомісяця
        [one] Раз на { $interval } місяць
        [few] Раз на { $interval } місяці
        [many] Раз на { $interval } місяців
       *[other] Раз на { $interval } місяця
    }
   *[year] { $interval ->
        [1] Щороку
        [one] Раз на { $interval } рік
        [few] Раз на { $interval } роки
        [many] Раз на { $interval } років
       *[other] Раз на { $interval } року
    }
}
# "Every week on Monday, Wednesday"
repeats-on = { $repeats }, дні: { $days }
# "Every week, 10 times"
repeats-times = { $count ->
    [1] { $repeats }, один раз
    [one] { $repeats }, { $count } раз
    [few] { $repeats }, { $count } рази
    [many] { $repeats }, { $count } разів
   *[other] { $repeats }, { $count } разу
}
day-monday = понеділок
day-tuesday = вівторок
day-wednesday = середа
day-thursday = четвер
day-friday = п’ятниця
day-saturday = субота
day-sunday = неділя

## AI agents

agent-level-read = Читати пошту: папки, списки повідомлень, розмови, результати пошуку, повідомлення та вкладення, правила для повідомлень і відомості про людей, яким ви пишете
agent-level-organize = Упорядковувати пошту: змінювати стан прочитання, прапорці та їхні кольори й позначки небажаної пошти, переміщувати й архівувати повідомлення, створювати й перейменовувати папки, відстежувати розмови та ігнорувати їх, переміщувати повідомлення до папки «Видалені» та скасовувати підписки на розсилки з вашої згоди
agent-level-drafts = Писати чернетки, які ви можете надіслати
agent-level-send = Надсилати пошту лише після вашого схвалення кожного повідомлення
agent-connect-title = { $program } запитує доступ до вашої пошти
agent-connect-detail = ШІ-агент запитує дозвіл працювати з Inbox Classic. Виберіть дозволені дії та облікові записи, до яких він матиме доступ. Згодом ці дозволи можна змінити в меню Сервіс > ШІ-агенти.

    Повідомлення від інших людей можуть містити інструкції, покликані обдурити агента. Inbox Classic завжди просить вашого схвалення, перш ніж агент надішле повідомлення.
agent-reply-to = Відповідь на «{ $subject }»
agent-reply-all-on = Відповідь усім на «{ $subject }»
agent-forward-of = Пересилання «{ $subject }»
agent-never-written-one = Ви ще не писали на адресу { $address }.
agent-never-written-many = Ви ще не писали на { $count } з цих адрес.
agent-send-title = { $program } хоче надіслати це повідомлення
agent-send-detail = Перевірте одержувачів і вміст повідомлення. Після підтвердження повідомлення чекатиме в папці «Вихідні» { $seconds } с, і там його ще можна буде видалити.
agent-change-title = Що може робити { $program }
agent-change-allowed = Виберіть, що ШІ-агенти цієї програми можуть робити з вашою поштою.
agent-change-refused = Ви заборонили цій програмі доступ до пошти. Надайте дозвіл, щоб її агенти знову могли працювати з вашою поштою.
agent-log-taken-back = { $entry } (скасовано)
agent-files = Файли: { $files }
agent-undo-refused = Цю дію неможливо скасувати.
agent-undo-refused-why = Цю дію неможливо скасувати: { $reason }.
agent-undo-impossible = це неможливо скасувати
agent-undo-not-in-folder = повідомлення вже немає в тій папці
agent-undo-not-arrived = повідомлення ще немає в папці призначення
agent-undo-sent = повідомлення вже немає в папці «Вихідні»
agent-original-not-downloaded = початкове повідомлення ще не завантажено. Спершу відкрийте його
agent-turned-away = Доступ заборонено
agent-can-nothing = Нічого
agent-can-read = читати
agent-can-organize = упорядковувати
agent-can-drafts = писати чернетки
agent-can-send = надсилати з вашої згоди
# "Read, organize and write drafts"
agent-can-list = { $first } і { $last }
agent-accounts = { $count ->
    [0] жодного облікового запису
    [one] { $count } обліковий запис
    [few] { $count } облікові записи
    [many] { $count } облікових записів
   *[other] { $count } облікового запису
}
# "Read and organize; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Це повідомлення неможливо прочитати.
agent-encrypted-original = Це повідомлення зашифроване. Агент не може відповісти на нього чи переслати його, оскільки не підтримує шифрування.
agent-encrypted = Це повідомлення зашифроване, тому агент не може прочитати його вміст. Ви можете відкрити його в Inbox Classic.
agent-too-many-changes = Досягнуто ліміту записів про зміни за останні 30 днів для цієї програми. Нові зміни стануть доступними, коли найстаріші записи перевищать цей строк.
agent-too-many-reads = Досягнуто ліміту записів про читання за останні 30 днів для цієї програми. Читання стане доступним, коли найстаріші записи перевищать цей строк.
list-encrypted = Зашифроване повідомлення
agent-log-composed = Відкрито нове повідомлення для редагування. Тема: «{ $subject }»
agent-log-refused = Ви відхилили запит на надсилання повідомлення «{ $subject }»
agent-log-sent = Повідомлення «{ $subject }» додано до черги надсилання. Одержувачі: { $to }
agent-log-draft = Збережено чернетку «{ $subject }»
agent-log-draft-replaced = Замінено чернетку «{ $subject }»
agent-log-draft-discarded = Подано запит на остаточне видалення чернетки «{ $subject }»
agent-draft-note = Цю чернетку створив ШІ-агент { $program }. Перевірте одержувачів і текст, перш ніж надсилати її.
agent-log-read = Позначено «{ $subject }» як прочитане
agent-log-unread = Позначено «{ $subject }» як непрочитане
agent-log-flagged = Позначено прапорцем «{ $subject }»
agent-log-unflagged = Знято прапорець із повідомлення «{ $subject }»
agent-log-deleted = Видалено «{ $subject }»
agent-log-moved = Переміщено «{ $subject }» до папки «{ $folder }»
agent-log-junk = Позначено «{ $subject }» як небажане
agent-log-not-junk = Знято позначку небажаної пошти з повідомлення «{ $subject }»
agent-log-archived = Заархівовано «{ $subject }»
agent-log-folder = Подано запит на створення папки «{ $name }»
agent-log-unsubscribed = Ви схвалили запит на скасування підписки. Повідомлення: «{ $subject }»
agent-log-unsubscribe-failed = Не вдалося скасувати підписку. Повідомлення: «{ $subject }». Причина: { $reason }
agent-log-unsubscribe-refused = Ви відхилили запит на скасування підписок. Відправники: { $senders }
agent-unsubscribe-title = { $count ->
    [1] { $program } хоче скасувати вашу підписку на список розсилки
    [one] { $program } хоче скасувати вашу підписку на { $count } список розсилки
    [few] { $program } хоче скасувати вашу підписку на { $count } списки розсилки
    [many] { $program } хоче скасувати вашу підписку на { $count } списків розсилки
   *[other] { $program } хоче скасувати вашу підписку на { $count } списку розсилки
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic надішле розсилці нижче запит через її функцію скасування підписки одним клацанням. Електронний лист не надсилатиметься, а ваші наявні повідомлення не зміняться.
   *[other] Inbox Classic надішле кожній розсилці нижче запит через її функцію скасування підписки одним клацанням. Електронний лист не надсилатиметься, а ваші наявні повідомлення не зміняться.
}
agent-log-flag-color = Позначено прапорцем «{ $subject }», колір: { $color ->
    [red] червоний
    [orange] помаранчевий
    [yellow] жовтий
    [green] зелений
    [blue] синій
    [purple] фіолетовий
   *[gray] сірий
}
agent-log-renamed = Подано запит на перейменування папки «{ $old }» на «{ $name }»
agent-log-watched = Увімкнено відстеження розмови «{ $subject }»
agent-log-ignored = Увімкнено ігнорування розмови «{ $subject }»
agent-log-unmarked = Скасовано відстеження чи ігнорування розмови «{ $subject }»
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = повідомлення відтоді змінено
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Позначено як прочитане: { $count } повідомлення (пошук: { $query })
    [few] Позначено як прочитані: { $count } повідомлення (пошук: { $query })
    [many] Позначено як прочитані: { $count } повідомлень (пошук: { $query })
   *[other] Позначено як прочитані: { $count } повідомлення (пошук: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Позначено як непрочитане: { $count } повідомлення (пошук: { $query })
    [few] Позначено як непрочитані: { $count } повідомлення (пошук: { $query })
    [many] Позначено як непрочитані: { $count } повідомлень (пошук: { $query })
   *[other] Позначено як непрочитані: { $count } повідомлення (пошук: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Позначено прапорцем: { $count } повідомлення (пошук: { $query })
    [few] Позначено прапорцем: { $count } повідомлення (пошук: { $query })
    [many] Позначено прапорцем: { $count } повідомлень (пошук: { $query })
   *[other] Позначено прапорцем: { $count } повідомлення (пошук: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Знято прапорець: { $count } повідомлення (пошук: { $query })
    [few] Знято прапорець: { $count } повідомлення (пошук: { $query })
    [many] Знято прапорець: { $count } повідомлень (пошук: { $query })
   *[other] Знято прапорець: { $count } повідомлення (пошук: { $query })
}
agent-log-bulk-color = { $count ->
    [one] Позначено прапорцем: { $count } повідомлення
    [few] Позначено прапорцем: { $count } повідомлення
    [many] Позначено прапорцем: { $count } повідомлень
   *[other] Позначено прапорцем: { $count } повідомлення
}, колір: { $color ->
    [red] червоний
    [orange] помаранчевий
    [yellow] жовтий
    [green] зелений
    [blue] синій
    [purple] фіолетовий
   *[gray] сірий
} (пошук: { $query })
agent-log-bulk-moved = { $count ->
    [one] Переміщено до папки «{ $folder }»: { $count } повідомлення (пошук: { $query })
    [few] Переміщено до папки «{ $folder }»: { $count } повідомлення (пошук: { $query })
    [many] Переміщено до папки «{ $folder }»: { $count } повідомлень (пошук: { $query })
   *[other] Переміщено до папки «{ $folder }»: { $count } повідомлення (пошук: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Заархівовано: { $count } повідомлення (пошук: { $query })
    [few] Заархівовано: { $count } повідомлення (пошук: { $query })
    [many] Заархівовано: { $count } повідомлень (пошук: { $query })
   *[other] Заархівовано: { $count } повідомлення (пошук: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Позначено як небажане: { $count } повідомлення (пошук: { $query })
    [few] Позначено як небажані: { $count } повідомлення (пошук: { $query })
    [many] Позначено як небажані: { $count } повідомлень (пошук: { $query })
   *[other] Позначено як небажані: { $count } повідомлення (пошук: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Знято позначку небажаної пошти: { $count } повідомлення (пошук: { $query })
    [few] Знято позначку небажаної пошти: { $count } повідомлення (пошук: { $query })
    [many] Знято позначку небажаної пошти: { $count } повідомлень (пошук: { $query })
   *[other] Знято позначку небажаної пошти: { $count } повідомлення (пошук: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Видалено: { $count } повідомлення (пошук: { $query })
    [few] Видалено: { $count } повідомлення (пошук: { $query })
    [many] Видалено: { $count } повідомлень (пошук: { $query })
   *[other] Видалено: { $count } повідомлення (пошук: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] За останні 15 хвилин
    [hour] За останню годину
    [hours] За останні 4 години
    [day] За останні 24 години
    [week] За останні 7 днів
   *[all] За останні 30 днів
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] За цей час програма { $program } не внесла змін, які можна скасувати.
    [one] Скасувати { $count } зміну, яку програма { $program } внесла за цей час?
    [few] Скасувати { $count } зміни, які програма { $program } внесла за цей час?
    [many] Скасувати { $count } змін, які програма { $program } внесла за цей час?
   *[other] Скасувати { $count } зміни, які програма { $program } внесла за цей час?
}
agent-undo-since-detail = Скасування повертає повідомлення до попередніх папок, відновлює стан прочитання й прапорці та видаляє повідомлення, які ще очікують у папці «Вихідні». Перевіряється стан, якого стосується кожна дія; повідомлення з невідповідним станом пропускаються. Інші пізніші зміни можуть не враховуватися.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Нічого не скасовано.
    [one] Скасовано { $count } зміну, повністю або частково.
    [few] Скасовано { $count } зміни, повністю або частково.
    [many] Скасовано { $count } змін, повністю або частково.
   *[other] Скасовано { $count } зміни, повністю або частково.
}
agent-undo-left-gone = { $count ->
    [one] Не знайдено в очікуваній папці: { $count } повідомлення.
    [few] Не знайдено в очікуваній папці: { $count } повідомлення.
    [many] Не знайдено в очікуваній папці: { $count } повідомлень.
   *[other] Не знайдено в очікуваній папці: { $count } повідомлення.
}
agent-undo-left-changed = { $count ->
    [one] Пропущено { $count } повідомлення через подальші зміни, внесені вами або сервером.
    [few] Пропущено { $count } повідомлення через подальші зміни, внесені вами або сервером.
    [many] Пропущено { $count } повідомлень через подальші зміни, внесені вами або сервером.
   *[other] Пропущено { $count } повідомлення через подальші зміни, внесені вами або сервером.
}
agent-undo-left-sent = { $count ->
    [one] Уже відсутнє в папці «Вихідні»: { $count } повідомлення.
    [few] Уже відсутні в папці «Вихідні»: { $count } повідомлення.
    [many] Уже відсутні в папці «Вихідні»: { $count } повідомлень.
   *[other] Уже відсутні в папці «Вихідні»: { $count } повідомлення.
}
agent-undo-left-impossible = { $count ->
    [one] { $count } зміну неможливо скасувати.
    [few] { $count } зміни неможливо скасувати.
    [many] { $count } змін неможливо скасувати.
   *[other] { $count } зміни неможливо скасувати.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Цим повідомленням ви приймаєте запрошення «{ $summary }» ({ $when }).
    [tentative] Цим повідомленням ви попередньо приймаєте запрошення «{ $summary }» ({ $when }).
   *[decline] Цим повідомленням ви відхиляєте запрошення «{ $summary }» ({ $when }).
} Відповідь призначена для календаря організатора. Стан відповіді в Inbox Classic оновиться лише після успішного надсилання повідомлення.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Прийнято: { $summary }
    [tentative] Попередньо прийнято: { $summary }
   *[decline] Відхилено: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } приймає це запрошення.
    [tentative] { $name } попередньо приймає це запрошення.
   *[decline] { $name } відхиляє це запрошення.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] прочитано { $count } повідомлення
    [few] прочитано { $count } повідомлення
    [many] прочитано { $count } повідомлень
   *[other] прочитано { $count } повідомлення
}
agent-reads-attachments = { $count ->
    [one] запитано { $count } вкладення
    [few] запитано { $count } вкладення
    [many] запитано { $count } вкладень
   *[other] запитано { $count } вкладення
}
agent-reads-searches = { $count ->
    [1] виконано пошук один раз
    [one] виконано пошук { $count } раз
    [few] виконано пошук { $count } рази
    [many] виконано пошук { $count } разів
   *[other] виконано пошук { $count } разу
}
agent-reads-lists = { $count ->
    [1] переглянуто список повідомлень один раз
    [one] переглянуто списки повідомлень { $count } раз
    [few] переглянуто списки повідомлень { $count } рази
    [many] переглянуто списки повідомлень { $count } разів
   *[other] переглянуто списки повідомлень { $count } разу
}
# each read under that row
agent-read-message = Прочитано «{ $subject }»
agent-read-conversation = { $count ->
    [one] Прочитано розмову «{ $subject }» ({ $count } повідомлення)
    [few] Прочитано розмову «{ $subject }» ({ $count } повідомлення)
    [many] Прочитано розмову «{ $subject }» ({ $count } повідомлень)
   *[other] Прочитано розмову «{ $subject }» ({ $count } повідомлення)
}
agent-read-attachment = Запитано вкладення «{ $name }» з повідомлення «{ $subject }»
agent-read-search = { $count ->
    [one] Пошук «{ $query }»: { $count } повідомлення
    [few] Пошук «{ $query }»: { $count } повідомлення
    [many] Пошук «{ $query }»: { $count } повідомлень
   *[other] Пошук «{ $query }»: { $count } повідомлення
}
agent-read-people = Пошук людей за іменем чи адресою: «{ $query }»
agent-read-list = { $count ->
    [one] Переглянуто { $count } запис. Список: «{ $folder }»
    [few] Переглянуто { $count } записи. Список: «{ $folder }»
    [many] Переглянуто { $count } записів. Список: «{ $folder }»
   *[other] Переглянуто { $count } запису. Список: «{ $folder }»
}
agent-read-changes = { $count ->
    [one] Переглянуто { $count } новий запис
    [few] Переглянуто { $count } нові записи
    [many] Переглянуто { $count } нових записів
   *[other] Переглянуто { $count } нового запису
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Програми, запущені з термінала «{ $terminal }»
agent-terminal-programs-windows = Програми, запущені з термінала ({ $terminal })
agent-terminal-programs-linux = Програми, запущені з термінала ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Програма, запущена з термінала «{ $terminal }»
agent-terminal-program-windows = Програма, запущена з термінала ({ $terminal })
agent-terminal-program-linux = Програма, запущена з термінала ({ $terminal })
agent-connect-title-terminal = { $programs } запитують доступ до вашої пошти
agent-connect-terminal-detail = Агенти, запущені з тієї самої розпізнаної програми термінала, спільно використовують доступ, який ви дозволите тут. Щоб керувати агентом окремо, додайте --name та вибране ім’я до його аргументів у налаштуваннях MCP. Ім’я не підтверджує, яка це програма.
agent-connect-claimed = Агент представився як «{ $claimed }». За даними системи, його запустила програма «{ $program }».
## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = провайдер не надав токена оновлення
sign-in-no-account = провайдер не повідомив, який обліковий запис увійшов
sign-in-not-finished = вхід не завершено
secrets-unavailable = Сховище недоступне: { $store }
secrets-unavailable-why = Сховище недоступне: { $store }. Причина: { $error }
secrets-windows = Диспетчер облікових даних
secrets-mac = В’язка ключів
secrets-linux = Системне сховище ключів (Secret Service)
error-no-such-file = такого файлу немає
cards-file-too-big = Розмір файлу перевищує ліміт для імпорту адресної книги.
ui-sender-added = { $name } додано до адресної книги.
ui-sender-known = { $name } уже є в адресній книзі.
ui-sender-none = У відправника цього повідомлення немає адреси електронної пошти, яку можна додати.
card-name-needed = У контакту немає ні імені, ні адреси електронної пошти.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Код від { $domain }
otp-copy = Копіювати
otp-note = Вводьте код лише на сторінці домену { $domain }.
otp-old = Цей код надіслано більш ніж за годину до того, як ви його відкрили, і, імовірно, він уже не дійсний.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } учасник
        [few] { $count } учасники
        [many] { $count } учасників
       *[other] { $count } учасника
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code }: ваш код для { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Дійсний
pgp-key-expires = Дійсний до { $date }
pgp-key-expired = Термін дії сплив { $date }
pgp-key-revoked = Відкликаний
pgp-key-revoked-why = Відкликаний: { $reason }
pgp-key-not-valid = Недійсний
pgp-key-locked = Не вдалося відкрити закриту частину ключа. Перевірте доступ до сховища паролів ({ $store }). Якщо захисний ключ втрачено, знову імпортуйте резервну копію закритого ключа.
pgp-source-own = Створено в Inbox Classic
pgp-source-file = Імпортовано з файлу
pgp-source-paste = Вставлено
pgp-source-attachment = З повідомлення
pgp-source-vcard = З картки контакту
pgp-source-wkd = Від поштового провайдера відправника
pgp-source-keyserver = З keys.openpgp.org
pgp-source-autocrypt = Із заголовка Autocrypt повідомлення
pgp-error-no-store = Сховище, потрібне для захисту закритих ключів, недоступне: { $store }. Причина: { $error }
pgp-error-wrong-passphrase = Парольна фраза неправильна.
pgp-error-not-a-key = Це не ключ OpenPGP.
pgp-error-too-large = Ключ завеликий.
pgp-error-unusable = Цей ключ не можна використати для підписування чи шифрування.
pgp-imported-private = { $count ->
    [1] Ваш закритий ключ імпортовано.
    [one] Імпортовано { $count } закритий ключ.
    [few] Імпортовано { $count } закриті ключі.
    [many] Імпортовано { $count } закритих ключів.
   *[other] Імпортовано { $count } закритого ключа.
}
pgp-imported-public = { $count ->
    [1] Імпортовано один ключ.
    [one] Імпортовано { $count } ключ.
    [few] Імпортовано { $count } ключі.
    [many] Імпортовано { $count } ключів.
   *[other] Імпортовано { $count } ключа.
}
pgp-imported-pending = Для цих адрес уже використовується інший ключ: { $addresses }. Новий ключ очікує у властивостях контакту, доки ви його не виберете.
pgp-error-needs-passphrase = Закритий ключ захищено парольною фразою. Введіть її, щоб імпортувати ключ.
pgp-error-mismatch = Закритий ключ не відповідає своєму відкритому ключу. Можливо, його змінено.
pgp-file-name-public = { $who } відкритий ключ.asc
pgp-file-name-private = { $who } резервна копія закритого ключа.asc
pgp-pending = Знайдено інший ключ для адреси { $address }. Дата: { $date }.
## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Підписано: { $signer }. Власника ключа підтверджено
pgp-part-signed = Підписано: { $signer } (власника ключа не підтверджено)
pgp-part-other = Підписано: { $signer } (не відправник повідомлення)
pgp-part-unknown-key = Підписано, але ключ невідомий
pgp-part-not-signed = Не підписано
pgp-part-not-checked = Підпис не перевірено
pgp-part-encrypted = Зашифровано. { $signature }
pgp-part-no-key = Зашифровано для ключа, якого у вас немає
pgp-part-changed = Цілісність зашифрованої частини порушено, тому її не показано
pgp-part-unprotected = Зашифровано без захисту від змін, тому не показано
pgp-part-broken = Зашифровану частину неможливо прочитати
pgp-why-mismatch = Підпис не відповідає цьому тексту
pgp-why-weak-hash = У підписі використано алгоритм { $hash }, який більше не вважається безпечним
pgp-why-key-expired = Підписано після того, як термін дії ключа сплив { $date }
pgp-why-key-revoked = Підписано відкликаним ключем
pgp-why-not-signing-key = Підписано ключем, не призначеним для підписування
pgp-why-from-future = Дата підпису ще не настала
pgp-why-signature-expired = Термін дії підпису сплив
pgp-why-key-not-valid = Підписано недійсним ключем
pgp-why-not-for-you = Підписано для інших одержувачів і передано вам
pgp-why-not-key-in-use = Для підпису використано інший ключ, ніж вибраний для адреси { $address }
pgp-part-pictures-loaded = { $label }. Зображення завантажено з інтернету
pgp-error-no-own-key = Для адреси { $address } немає ключа, придатного для підписування чи шифрування. Створіть його у вікні «Ключі шифрування» або вимкніть підписування та шифрування.
pgp-error-missing-keys = { $count ->
    [1] Для адреси { $addresses } немає придатного ключа для шифрування.
   *[other] Немає придатних ключів для шифрування для цих одержувачів: { $addresses }.
}
pgp-error-encrypted-quote = Повідомлення містить текст, зображення або вкладення із зашифрованого повідомлення, тому його можна надіслати лише зашифрованим. Увімкніть шифрування або вилучіть цей вміст.
pgp-error-protect = Не вдалося підписати чи зашифрувати повідомлення: { $reason }
pgp-found-keys = Знайдено ключі для адрес: { $addresses }.
pgp-found-none = Не знайдено ключів для адрес: { $addresses }. Попросіть власників надіслати свої відкриті ключі.
pgp-found-no-key = Ключа не знайдено.
pgp-find-unavailable = Зараз неможливо шукати ключі: { $error }
pgp-publish-pending = keys.openpgp.org надіслав посилання для підтвердження на адреси: { $addresses }. Підтвердьте кожну адресу, щоб за нею можна було знайти ваш ключ.
pgp-publish-done = Ваш ключ опубліковано на keys.openpgp.org для адрес: { $addresses }.
pgp-publish-failed = Не вдалося опублікувати ключ: { $error }
pgp-keyserver-off = Пошук ключів на keys.openpgp.org вимкнено в розділі { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [1] Під час надсилання повідомлення буде зашифровано й підписано. Вміст зможете прочитати лише ви та { $addresses }.
    [one] Під час надсилання повідомлення буде зашифровано й підписано. Вміст зможете прочитати лише ви та { $count } одержувач.
    [few] Під час надсилання повідомлення буде зашифровано й підписано. Вміст зможете прочитати лише ви та { $count } одержувачі.
    [many] Під час надсилання повідомлення буде зашифровано й підписано. Вміст зможете прочитати лише ви та { $count } одержувачів.
   *[other] Під час надсилання повідомлення буде зашифровано й підписано. Вміст зможете прочитати лише ви та одержувачі ({ $count }).
}
pgp-compose-encrypt-ready = Під час надсилання повідомлення буде зашифровано й підписано. Додайте одержувачів, для яких у вас є придатні ключі.
pgp-compose-missing = { $count ->
    [1] Одержувач не має придатного ключа: { $addresses }. Повідомлення ще не можна зашифрувати.
    [one] { $count } одержувач не має придатного ключа: { $addresses }. Повідомлення ще не можна зашифрувати.
    [few] { $count } одержувачі не мають придатних ключів: { $addresses }. Повідомлення ще не можна зашифрувати.
    [many] { $count } одержувачів не мають придатних ключів: { $addresses }. Повідомлення ще не можна зашифрувати.
   *[other] Немає придатних ключів для одержувачів ({ $count }): { $addresses }. Повідомлення ще не можна зашифрувати.
}
pgp-compose-looking = Пошук ключів одержувачів: { $addresses }...
pgp-compose-signed = Під час надсилання повідомлення буде підписано цифровим підписом. Одержувачі зможуть перевірити, чи змінювався вміст після підписування.
pgp-compose-reply-clear = Повідомлення буде надіслано без шифрування, хоча початкове повідомлення було зашифроване.
pgp-compose-encrypted-files = Повідомлення містить вкладення із зашифрованого повідомлення, тому його можна надіслати лише зашифрованим. Увімкніть «Зашифрувати» або вилучіть ці вкладення.
pgp-compose-sign-tip = Підписати повідомлення своїм ключем, щоб одержувачі могли перевірити, чи змінювався вміст після підписування
pgp-compose-sign-tip-encrypted = Повідомлення, що надсилаються зашифрованими, також підписуються цифровим підписом
pgp-compose-encrypt-tip = Зашифрувати вміст повідомлення, щоб прочитати його могли лише ви та одержувачі
pgp-compose-make-key = У вас ще немає власного ключа для адреси { $address }. Створити його зараз? З ним ви зможете підписувати й шифрувати повідомлення.
pgp-compose-key-unusable =
    Ваш ключ для адреси { $address } не можна використати.

    Причина: { $state }

    Відкрийте «Ключі шифрування», щоб імпортувати резервну копію цього ключа або створити новий.
pgp-compose-encrypt-off-quote = Повідомлення містить текст, зображення або вкладення із зашифрованого повідомлення. Щоб надіслати його без шифрування, спочатку вилучіть цей вміст. Усе одно вимкнути шифрування?
pgp-compose-encrypt-off-reply = Ви відповідаєте на зашифроване повідомлення або пересилаєте його. Без шифрування вміст вашого повідомлення буде доступний серверам, через які воно проходить. Вимкнути шифрування?
pgp-recipient-verified = Власника ключа підтверджено
pgp-recipient-found = Власника ключа не підтверджено
pgp-recipient-own = Ваш власний ключ
pgp-recipient-looking = Пошук ключа...
pgp-recipient-missing = Немає ключа
pgp-recipient-not-found = Ключ не знайдено. Останній пошук: { $date }
pgp-recipient-unusable = Ключ не можна використати: { $state }
pgp-recipients-intro = Під час надсилання повідомлення шифрується ключами одержувачів і вашим власним ключем.
pgp-recipients-intro-missing = { $count ->
    [1] Один одержувач не має придатного ключа для шифрування. Знайдіть його ключ, вилучіть одержувача з повідомлення або надішліть повідомлення без шифрування, якщо в ньому немає тексту, зображень чи вкладень із зашифрованих повідомлень.
    [one] { $count } одержувач не має придатного ключа для шифрування. Знайдіть відсутні ключі, вилучіть одержувачів без придатних ключів із повідомлення або надішліть повідомлення без шифрування, якщо в ньому немає тексту, зображень чи вкладень із зашифрованих повідомлень.
    [few] { $count } одержувачі не мають придатних ключів для шифрування. Знайдіть їхні ключі, вилучіть цих одержувачів із повідомлення або надішліть повідомлення без шифрування, якщо в ньому немає тексту, зображень чи вкладень із зашифрованих повідомлень.
    [many] { $count } одержувачів не мають придатних ключів для шифрування. Знайдіть їхні ключі, вилучіть цих одержувачів із повідомлення або надішліть повідомлення без шифрування, якщо в ньому немає тексту, зображень чи вкладень із зашифрованих повідомлень.
   *[other] Одержувачів без придатних ключів для шифрування: { $count }. Знайдіть їхні ключі, вилучіть цих одержувачів із повідомлення або надішліть повідомлення без шифрування, якщо в ньому немає тексту, зображень чи вкладень із зашифрованих повідомлень.
}
pgp-details-part = Частина { $number }: { $label }
attachment-from-part = З частини { $number }: { $label }
pgp-details-signed = Підписано { $when } ключем { $key }
pgp-details-unknown-key = Підписано ключем { $key }, якого у вас немає
pgp-details-opened = Розшифровано вашим ключем { $key }
pgp-details-for = Зашифровано для ключів: { $keys }
pgp-details-plain = Не підписано й не зашифровано
pgp-bar-parts = Частин у повідомленні: { $count } ({ $list }). Біля кожної частини вказано, як її захищено.
pgp-bar-count-verified = з підтвердженим власником ключа: { $count }
pgp-bar-count-encrypted-signed = зашифрованих і підписаних: { $count }
pgp-bar-count-encrypted = зашифрованих: { $count }
pgp-bar-count-signed = підписаних: { $count }
pgp-bar-count-warning = { $count ->
   *[other] потребують уваги: { $count }
}
pgp-bar-count-neutral = без підтвердженого підпису: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Параметри
setup-part-preferences = Параметри інтерфейсу
setup-part-accounts = Облікові записи
setup-part-sign-in-apps = Застосунки для входу
setup-part-contacts = Контакти й групи
setup-part-keys = Ключі шифрування
setup-part-rules = Правила для повідомлень
setup-part-trusted-senders = Довірені відправники
setup-holds-settings = { $count ->
    [one] { $count } параметр
    [few] { $count } параметри
    [many] { $count } параметрів
   *[other] { $count } параметра
}
setup-holds-preferences = { $count ->
    [one] { $count } налаштування
    [few] { $count } налаштування
    [many] { $count } налаштувань
   *[other] { $count } налаштування
}
setup-holds-accounts = { $count ->
    [one] { $count } обліковий запис
    [few] { $count } облікові записи
    [many] { $count } облікових записів
   *[other] { $count } облікового запису
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } застосунок для входу
    [few] { $count } застосунки для входу
    [many] { $count } застосунків для входу
   *[other] { $count } застосунку для входу
}
setup-holds-built-in = Які вбудовані застосунки для входу ввімкнено
setup-holds-contacts = { $count ->
    [one] { $count } контакт
    [few] { $count } контакти
    [many] { $count } контактів
   *[other] { $count } контакту
}
setup-holds-groups = { $count ->
    [one] { $count } група
    [few] { $count } групи
    [many] { $count } груп
   *[other] { $count } групи
}
setup-holds-own-keys = { $count ->
    [one] { $count } власний ключ
    [few] { $count } власні ключі
    [many] { $count } власних ключів
   *[other] { $count } власного ключа
}
setup-holds-contact-keys = { $count ->
    [one] { $count } ключ контакту
    [few] { $count } ключі контактів
    [many] { $count } ключів контактів
   *[other] { $count } ключа контактів
}
setup-holds-rules = { $count ->
    [one] { $count } правило
    [few] { $count } правила
    [many] { $count } правил
   *[other] { $count } правила
}
setup-holds-trusted-senders = { $count ->
    [one] { $count } довірений відправник
    [few] { $count } довірені відправники
    [many] { $count } довірених відправників
   *[other] { $count } довіреного відправника
}
setup-sign-in-password = Пароль
setup-account-secret-password = Пароль збережено у файлі.
setup-account-secret-token = Дані для входу збережено у файлі.
setup-account-asks-password = Після імпорту потрібно буде ввести пароль.
setup-account-signs-in-again = Після імпорту потрібно буде ввійти знову.
setup-account-here = Обліковий запис уже налаштовано на цьому комп’ютері, тому його буде пропущено.
setup-account-no-app = Для входу використовується застосунок «{ $app }», який тут ще не налаштовано. Імпортуйте також застосунки для входу.
setup-invalid-address = «{ $address }» не є адресою електронної пошти.
setup-invalid-server = Некоректні параметри сервера { $server }: назва, порт або спосіб захисту з’єднання.
setup-invalid-user = Немає імені користувача.
setup-invalid-sign-in = Спосіб входу не підтримується або параметри авторизації некоректні.
setup-error-empty = Файл порожній.
setup-error-too-large = Розмір файлу параметрів Inbox Classic перевищує допустимий.
setup-error-not-setup = Цей файл не містить налаштувань Inbox Classic.
setup-error-damaged = Файл налаштувань пошкоджено, його неможливо прочитати.
setup-error-newer = Ці налаштування збережено новішою версією Inbox Classic ({ $version }). Оновіть Inbox Classic і імпортуйте їх знову.
setup-error-needs-passphrase = Ці налаштування захищено парольною фразою. Введіть парольну фразу, з якою їх збережено.
setup-error-wrong-passphrase = Це не та парольна фраза, з якою збережено ці налаштування.
setup-error-changed = Цілісність файлу параметрів порушено: його змінено або пошкоджено, тому імпорт неможливий.
sync-wrong-passphrase = Парольна фраза синхронізації неправильна. Введіть фразу, яку ви вибрали під час налаштування синхронізації на першому комп’ютері.
sync-place = { $place }, назва комп’ютера: «{ $name }»
sync-news-removed = { $count ->
    [1] Обліковий запис вилучено під час синхронізації, оскільки його вилучили на іншому комп’ютері: { $accounts }.
    [one] Облікові записи вилучено під час синхронізації, оскільки їх вилучили на іншому комп’ютері: { $accounts }.
    [few] Облікові записи вилучено під час синхронізації, оскільки їх вилучили на іншому комп’ютері: { $accounts }.
    [many] Облікові записи вилучено під час синхронізації, оскільки їх вилучили на іншому комп’ютері: { $accounts }.
   *[other] Облікові записи вилучено під час синхронізації, оскільки їх вилучили на іншому комп’ютері: { $accounts }.
}
sync-news-lost = { $count ->
    [1] Зміну, внесену одночасно на іншому комп’ютері, замінено зміною, внесеною тут. Її збережено в історії синхронізації.
    [one] { $count } зміну, внесену одночасно на інших комп’ютерах, замінено змінами, внесеними тут. Їх збережено в історії синхронізації.
    [few] { $count } зміни, внесені одночасно на інших комп’ютерах, замінено змінами, внесеними тут. Їх збережено в історії синхронізації.
    [many] { $count } змін, внесених одночасно на інших комп’ютерах, замінено змінами, внесеними тут. Їх збережено в історії синхронізації.
   *[other] { $count } зміни, внесені одночасно на інших комп’ютерах, замінено змінами, внесеними тут. Їх збережено в історії синхронізації.
}
sync-status-busy = Синхронізація…
sync-status-never = Ще не синхронізовано.
sync-status-last = Остання синхронізація: { $when }.
sync-status-today = Остання синхронізація: сьогодні о { $time }.
sync-when-today = сьогодні о { $time }
sync-status-problem = Не вдалося синхронізувати: { $problem }
sync-removed-here = Цей комп’ютер вилучено із синхронізації на іншому комп’ютері. Вимкніть синхронізацію, а потім налаштуйте її знову, щоб приєднатися.
sync-item-account = Обліковий запис { $name }
sync-item-contact = Контакт { $name }
sync-item-group = Група { $name }
sync-item-key = Ключ { $name }
sync-item-rule = Правило { $name }
sync-item-trusted = Довірений відправник { $name }
sync-item-sign-in-app = Застосунок для входу { $name }
sync-item-settings = Параметри
sync-another-computer = інший комп’ютер
sync-no-key = На цьому комп’ютері немає ключа шифрування синхронізації. Вимкніть синхронізацію, а потім налаштуйте її знову за допомогою своєї парольної фрази синхронізації.
setup-error-read = Не вдалося прочитати файл налаштувань: { $error }
setup-error-write = Не вдалося зберегти файл параметрів: { $error }
setup-error-no-parts = Виберіть принаймні одну частину.
setup-left-out = { $count ->
    [one] Пропущено { $count } запис розділу «{ $part }»: дані непридатні для використання.
    [few] Пропущено { $count } записи розділу «{ $part }»: дані непридатні для використання.
    [many] Пропущено { $count } записів розділу «{ $part }»: дані непридатні для використання.
   *[other] Пропущено { $count } запису розділу «{ $part }»: дані непридатні для використання.
}
setup-imported-settings = Параметри замінено.
setup-imported-preferences = Параметри інтерфейсу замінено.
setup-added-accounts = { $count ->
    [one] Додано { $count } обліковий запис.
    [few] Додано { $count } облікові записи.
    [many] Додано { $count } облікових записів.
   *[other] Додано { $count } облікового запису.
}
setup-skipped-here = Обліковий запис { $address } уже налаштовано на цьому комп’ютері, тому його пропущено.
setup-skipped-no-app = Обліковий запис { $address } пропущено: потрібний застосунок для входу «{ $app }» тут не налаштовано.
setup-skipped-invalid = { $address } пропущено: { $reason }
setup-asks-password = Під час під’єднання облікового запису { $address } потрібно буде ввести пароль.
setup-signs-in-again = Під час під’єднання облікового запису { $address } потрібно буде ввійти знову.
setup-added-sign-in-apps = { $count ->
    [one] Додано { $count } застосунок для входу.
    [few] Додано { $count } застосунки для входу.
    [many] Додано { $count } застосунків для входу.
   *[other] Додано { $count } застосунку для входу.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } застосунок для входу вже налаштовано тут.
    [few] { $count } застосунки для входу вже налаштовано тут.
    [many] { $count } застосунків для входу вже налаштовано тут.
   *[other] { $count } застосунку для входу вже налаштовано тут.
}
setup-added-contacts = { $count ->
    [one] До адресної книги додано { $count } контакт.
    [few] До адресної книги додано { $count } контакти.
    [many] До адресної книги додано { $count } контактів.
   *[other] До адресної книги додано { $count } контакту.
}
setup-skipped-contacts = { $count ->
    [one] { $count } контакт уже є в адресній книзі.
    [few] { $count } контакти вже є в адресній книзі.
    [many] { $count } контактів уже є в адресній книзі.
   *[other] { $count } контакту вже є в адресній книзі.
}
setup-added-groups = { $count ->
    [one] Додано або доповнено { $count } групу.
    [few] Додано або доповнено { $count } групи.
    [many] Додано або доповнено { $count } груп.
   *[other] Додано або доповнено { $count } групи.
}
setup-added-own-keys = { $count ->
    [one] Додано { $count } власний ключ.
    [few] Додано { $count } власні ключі.
    [many] Додано { $count } власних ключів.
   *[other] Додано { $count } власного ключа.
}
setup-added-contact-keys = { $count ->
    [one] Додано { $count } ключ контакту.
    [few] Додано { $count } ключі контактів.
    [many] Додано { $count } ключів контактів.
   *[other] Додано { $count } ключа контактів.
}
setup-added-rules = { $count ->
    [one] Додано { $count } правило для повідомлень.
    [few] Додано { $count } правила для повідомлень.
    [many] Додано { $count } правил для повідомлень.
   *[other] Додано { $count } правила для повідомлень.
}
setup-skipped-rules = { $count ->
    [one] { $count } правило для повідомлень уже є тут.
    [few] { $count } правила для повідомлень уже є тут.
    [many] { $count } правил для повідомлень уже є тут.
   *[other] { $count } правила для повідомлень уже є тут.
}
setup-skipped-rules-account = { $count ->
    [one] { $count } правило для повідомлень стосується облікового запису, якого тут немає, тому його пропущено.
    [few] { $count } правила для повідомлень стосуються облікових записів, яких тут немає, тому їх пропущено.
    [many] { $count } правил для повідомлень стосуються облікових записів, яких тут немає, тому їх пропущено.
   *[other] { $count } правила для повідомлень стосуються облікових записів, яких тут немає, тому їх пропущено.
}
setup-rules-waiting = { $count ->
    [one] Не знайдено папки призначення для { $count } правила. Пошук продовжиться після синхронізації.
    [few] Не знайдено папок призначення для { $count } правил. Пошук продовжиться після синхронізації.
    [many] Не знайдено папок призначення для { $count } правил. Пошук продовжиться після синхронізації.
   *[other] Не знайдено папки призначення для { $count } правила. Пошук продовжиться після синхронізації.
}
setup-added-trusted-senders = { $count ->
    [one] Додано { $count } довіреного відправника.
    [few] Додано { $count } довірених відправників.
    [many] Додано { $count } довірених відправників.
   *[other] Додано { $count } довіреного відправника.
}
setup-nothing = Нічого не імпортовано.
setup-account-servers = { $imap } і { $smtp } ({ $signin })
setup-file-name = Параметри й облікові записи Inbox Classic
setup-skipped-unreachable = Запис «{ $name }» пропущено: не вдалося перевірити службу входу. Налаштуйте потрібний застосунок у вікні «Застосунки для входу» та повторіть імпорт.
attachment-runs-programs = «{ $name }» може запускати програми, тому Inbox Classic не відкриває цей файл. Збережіть його й відкрийте самостійно, якщо довіряєте його джерелу.
attachment-decrypted-note = Це вкладення із зашифрованого повідомлення. Щоб відкрити його, Inbox Classic зберігає незашифровану копію в тимчасовій папці вашого облікового запису користувача. Під час запуску програма намагається видалити копії, старші за добу.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [1] Сервер не перемістив { $messages } у папку «{ $folder }», тому воно знову в папці «{ $from }»: { $reason }
    [one] Сервер не перемістив { $messages } у папку «{ $folder }», тому повідомлення знову в папці «{ $from }»: { $reason }
   *[other] Сервер не перемістив { $messages } у папку «{ $folder }», тому вони знову в папці «{ $from }»: { $reason }
}
undone-delete = { $count ->
    [1] Сервер не видалив { $messages }, тому воно знову в папці «{ $from }»: { $reason }
    [one] Сервер не видалив { $messages }, тому повідомлення знову в папці «{ $from }»: { $reason }
   *[other] Сервер не видалив { $messages }, тому вони знову в папці «{ $from }»: { $reason }
}
undone-archive = { $count ->
    [1] Сервер не заархівував { $messages }, тому воно знову в папці «{ $from }»: { $reason }
    [one] Сервер не заархівував { $messages }, тому повідомлення знову в папці «{ $from }»: { $reason }
   *[other] Сервер не заархівував { $messages }, тому вони знову в папці «{ $from }»: { $reason }
}
undone-read = { $count ->
   *[other] Сервер не змінив стан прочитання. Відновлено стан «Непрочитане»: { $messages }. Причина: { $reason }
}
undone-unread = { $count ->
   *[other] Сервер не змінив стан прочитання. Відновлено стан «Прочитане»: { $messages }. Причина: { $reason }
}
undone-flags = { $count ->
    [one] Сервер не змінив прапорці, тому зміну скасовано ({ $messages }): { $reason }
   *[other] Сервер не змінив прапорці, тому зміну скасовано ({ $messages }): { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

preview-pdf-option = Показувати PDF-файли в повідомленнях
preview-pdf-off = PDF-файли в повідомленнях не показуються.
preview-pdf-off-crashed = Робота Inbox Classic перервалася під час показу файлу в повідомленні, тому показ PDF-файлів вимкнено. Зображення й далі показуються. Щоб знову показувати PDF-файли, увімкніть параметр «{ $option }» у розділі { $settings }.
preview-pdf-details = { $count ->
    [one] { $count } сторінка, { $size }
    [few] { $count } сторінки, { $size }
    [many] { $count } сторінок, { $size }
   *[other] { $count } сторінки, { $size }
}
preview-page-alt = { $name }, сторінка { $page } з { $count }
preview-more-pages = { $count ->
    [1] Відкрийте файл, щоб переглянути сторінку
   *[other] Відкрийте файл, щоб переглянути всі сторінки ({ $count })
}
preview-more-files = { $count ->
    [one] Ще { $count } файл у списку вище
    [few] Ще { $count } файли у списку вище
    [many] Ще { $count } файлів у списку вище
   *[other] Ще { $count } файлу у списку вище
}
preview-tile-downloading = Завантаження…
preview-tile-preparing = Підготовка…
preview-tile-format = Зображення у форматі { $format } поки не показуються
preview-tile-password = Захищено паролем: відкрийте, щоб ввести пароль
preview-tile-too-large = Перевищено ліміт розміру для показу
preview-tile-unreadable = Неможливо показати
preview-tile-timed-out = Час підготовки зображення вичерпано
preview-tile-crashed = Не показано: попередня спроба показу перервалася або зависла
preview-tile-off = Не показано до перезапуску Inbox Classic
preview-not-printed = Файл «{ $name }» ({ $details }) не включено до друку. Відкрийте його, щоб надрукувати.

pgp-error-attached-private = Це вкладення містить закритий ключ. Безпосередньо з пошти можна імпортувати лише відкриті ключі. Щоб відновити власний закритий ключ, збережіть вкладення та імпортуйте його файл у вікні «Ключі шифрування».
pgp-part-find-key = Знайти ключ
reaction-notification-title = { $name }: реакція { $emoji }
reaction-notification-text = { $count ->
    [1] на повідомлення { $subject }
   *[other] на повідомлення { $subject } (усього нових реакцій: { $count })
}
