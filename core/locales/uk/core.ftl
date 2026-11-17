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
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] { $count } байт
    [few] { $count } байти
    [many] { $count } байтів
   *[other] { $count } байта
}
# review: new
size-kb = { $size } КБ
# review: new
size-mb = { $size } МБ
# review: new
size-gb = { $size } ГБ
# review: new
send-delay-off = Вимкнено
# review: new
send-delay-seconds = { $count ->
    [one] { $count } секунда
    [few] { $count } секунди
    [many] { $count } секунд
   *[other] { $count } секунди
}
# the status bar: "12 messages, 3 unread"
# review: new
list-counts = { $messages }, непрочитаних: { $unread }
# review: new
list-counts-selected = { $messages }, непрочитаних: { $unread }, виділено: { $selected }
# the status bar while searching: "12 found, 3 unread"
# review: new
list-counts-found = Знайдено: { $found }, непрочитаних: { $unread }
# review: new
list-counts-found-selected = Знайдено: { $found }, непрочитаних: { $unread }, виділено: { $selected }
# review: new
list-counts-none = Повідомлень не знайдено

## Special folders, as Outlook names them

# review: new
folder-inbox = Вхідні
# review: new
folder-sent = Надіслані
# review: new
folder-deleted = Видалені
# review: new
folder-drafts = Чернетки
# review: new
folder-junk = Небажана пошта
# review: new
folder-archive = Архів

## The reading pane

# review: new
reader-no-message = Повідомлення не вибрано.
# review: new
reader-downloading = Повідомлення завантажується…
# review: new
reader-downloading-detail = Повідомлення з’явиться тут, щойно завантаження завершиться.
# review: new
reader-downloading-size = Розмір повідомлення: { $size }. Воно з’явиться тут, щойно завантажиться.
# review: new
reader-failed = Не вдалося завантажити повідомлення
# review: new
reader-failed-network = Не вдалося зв’язатися з поштовим сервером ({ $reason }).
# review: new
reader-failed-sign-in = Поштовий сервер не прийняв вхід ({ $reason }). Перевірте пароль або увійдіть знову в меню Файл > Облікові записи.
# review: new
reader-failed-security = Не вдалося захистити з’єднання з поштовим сервером ({ $reason }).
# review: new
reader-failed-other = Відповідь поштового сервера: { $reason }.
# review: new
reader-retry-note = Спробу буде повторено, коли обліковий запис знову під’єднається.
# review: new
reader-unreadable = Це повідомлення неможливо показати: { $error }
# review: new
message-source-title = Джерело повідомлення: { $subject }
# review: new
message-source-untitled = Джерело повідомлення

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Від
# review: new
header-date = Дата
# review: new
header-to = Кому
# review: new
header-cc = Копія
# review: new
header-sent = Надіслано
# review: new
header-subject = Тема
# review: new
header-security = Безпека
# review: new
header-part = Частина { $number }
# review: new
quote-original = ----- Початкове повідомлення -----
# review: new
fold-show-earlier = Показати попередні повідомлення

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Ваше повідомлення не доставлено
# review: new
bounce-delayed = Ваше повідомлення ще не доставлено
# review: new
bounce-delayed-note = Ваш поштовий сервер досі намагається його доставити. Надсилати його знову не потрібно.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Показати повернене повідомлення
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Показати затримане повідомлення
# review: new
bounce-what-to-do = Що можна зробити:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Поки нічого. Якщо доставити його так і не вдасться, ви отримаєте ще одне сповіщення.
# review: new
bounce-delayed-row-do = Поки нічого. Ваш поштовий сервер досі намагається його доставити, і якщо це не вдасться, ви отримаєте ще одне сповіщення.
# folds the receiving server's own words
# review: new
bounce-details = Подробиці
# a recipient the notice does not name
# review: new
bounce-someone = Одержувач
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Сервер: { $server }
# review: new
bounce-status = Стан: { $status }
# review: new
bounce-reported-by = Повідомив: { $server }
# review: new
bounce-retry-minutes = Сервер одержувача попросив зачекати { $count ->
    [1] хвилину
    [one] { $count } хвилину
    [few] { $count } хвилини
    [many] { $count } хвилин
   *[other] { $count } хвилини
} до наступної спроби.
# review: new
bounce-retry-hours = Сервер одержувача попросив зачекати { $count ->
    [1] годину
    [one] { $count } годину
    [few] { $count } години
    [many] { $count } годин
   *[other] { $count } години
} до наступної спроби.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Чорний список: { $lists }
# review: new
bounce-user-unknown = Такої адреси не існує
# review: new
bounce-user-unknown-why = На сервері одержувача немає поштової скриньки з цією адресою. Можливо, в адресі помилка, або людина більше нею не користується.
# review: new
bounce-user-unknown-do = Перевірте написання адреси або запитайте в людини, якою адресою вона користується зараз.
# review: new
bounce-invalid-address = Адреса недійсна
# review: new
bounce-invalid-address-why = Адресу записано у формі, на яку неможливо надіслати пошту.
# review: new
bounce-invalid-address-do = Пошукайте помилки, наприклад пробіл, пропущену літеру або порожнє місце після @.
# review: new
bounce-mailbox-disabled = Поштову скриньку закрито
# review: new
bounce-mailbox-disabled-why = Адреса існує, але її поштову скриньку вимкнено або вона більше не використовується.
# review: new
bounce-mailbox-disabled-do = Зв’яжіться з людиною іншим способом і запитайте адресу, якою вона користується зараз.
# review: new
bounce-mailbox-full = Поштова скринька переповнена
# review: new
bounce-mailbox-full-why = У поштовій скриньці одержувача немає місця для нової пошти.
# review: new
bounce-mailbox-full-do = Надішліть повідомлення знову через кілька днів або повідомте людину іншим способом. Великі вкладення відхиляються насамперед.
# review: new
bounce-spam-blocked = Відхилено як спам
# review: new
bounce-spam-blocked-why = Сервер одержувача вважав повідомлення спамом.
# review: new
bounce-spam-blocked-do = Надішліть його знову без того, що схоже на спам, наприклад без великої кількості посилань, скорочених посилань чи великого вкладення. Якщо це повторюється, зверніться до свого поштового провайдера.
# review: new
bounce-virus-detected = Відхилено через вірус
# review: new
bounce-virus-detected-why = Сервер одержувача знайшов вірус або інший шкідливий вміст у повідомленні чи його вкладеннях.
# review: new
bounce-virus-detected-do = Перевірте вкладення антивірусом. Деякі сервери відхиляють будь-які програми й архіви, тому діліться такими файлами за посиланням.
# review: new
bounce-ip-blocklisted = Ваш поштовий сервер у чорному списку
# review: new
bounce-ip-blocklisted-why = Сервер одержувача не приймає пошту від сервера, що надіслав ваше повідомлення, бо адреса того сервера є в чорному списку.
# review: new
bounce-ip-blocklisted-do = Проблема не в повідомленні. Перешліть це сповіщення своєму поштовому провайдеру й попросіть вилучити сервер зі списку.
# review: new
bounce-domain-blocklisted = Домен у чорному списку
# review: new
bounce-domain-blocklisted-why = Сервер одержувача відхиляє повідомлення, бо домен вашої адреси або домен у посиланнях повідомлення є в чорному списку.
# review: new
bounce-domain-blocklisted-do = Якщо в повідомленні є посилання, спробуйте надіслати його без них. Інакше перешліть це сповіщення тому, хто обслуговує пошту вашого домену.
# review: new
bounce-policy-blocked = Відхилено правилами сервера одержувача
# review: new
bounce-policy-blocked-why = Правила сервера одержувача не пропускають це повідомлення, наприклад через його розмір, вкладення або відправника.
# review: new
bounce-policy-blocked-do = Причину часто видно зі слів самого сервера в розділі «Подробиці». Запитайте одержувача, чи може він приймати таку пошту.
# review: new
bounce-geo-blocked = Відхилено через місце відправлення
# review: new
bounce-geo-blocked-why = Сервер одержувача не приймає пошту з країни чи мережі, де розташований ваш поштовий сервер.
# review: new
bounce-geo-blocked-do = Зв’яжіться з людиною іншим способом або зверніться до свого поштового провайдера.
# review: new
bounce-relay-denied = Сервер відмовився передати повідомлення далі
# review: new
bounce-relay-denied-why = Сервер відмовився доставити повідомлення далі, часто тому, що його надіслано без входу або через сервер, який не обслуговує цього одержувача.
# review: new
bounce-relay-denied-do = Перевірте сервер вихідної пошти облікового запису в меню Файл > Облікові записи, а також те, що він виконує вхід.
# review: new
bounce-auth-failure = Не вдалося перевірити вашу адресу відправника
# review: new
bounce-auth-failure-why = Сервер одержувача не зміг підтвердити, що повідомлення справді надійшло з вашого домену (SPF, DKIM або DMARC).
# review: new
bounce-auth-failure-do = Перешліть це сповіщення тому, хто обслуговує пошту вашого домену: його налаштування треба виправити. Тим часом може допомогти надсилання через власний сервер вашого провайдера.
# review: new
bounce-rate-limited = Забагато пошти водночас
# review: new
bounce-rate-limited-why = Сервер одержувача тимчасово приймає менше повідомлень від вашого поштового сервера.
# review: new
bounce-rate-limited-do = Зачекайте трохи й надішліть знову. Коли пишете багатьом людям, надсилайте меншими частинами.
# review: new
bounce-greylisting = Ненадовго затримано
# review: new
bounce-greylisting-why = Сервер одержувача просить невідомих відправників спробувати трохи пізніше. Це звичайна перевірка проти спаму.
# review: new
bounce-greylisting-do = Нічого. Поштові сервери повторюють спробу самі, і повідомлення зазвичай доставляється протягом години.
# review: new
bounce-server-error = Проблема на сервері одержувача
# review: new
bounce-server-error-why = Сервер одержувача недоступний або не зміг прийняти повідомлення через власну проблему.
# review: new
bounce-server-error-do = Надішліть повідомлення знову пізніше. Якщо не вдається й далі, перевірте частину адреси після @ на помилки.
# review: new
bounce-unknown = Не доставлено
# review: new
bounce-unknown-why = Сповіщення не пояснює чітко, чому.
# review: new
bounce-unknown-do = Більше можуть сказати слова самого сервера в розділі «Подробиці». Якщо вони не допомагають, перешліть це сповіщення своєму поштовому провайдеру.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] Виділено { $count } повідомлення
    [few] Виділено { $count } повідомлення
    [many] Виділено { $count } повідомлень
   *[other] Виділено { $count } повідомлення
}
# review: new
selection-unread = Непрочитаних: { $count }
# review: new
selection-flagged = З прапорцем: { $count }
# review: new
delete-for-good-one = Це повідомлення буде видалено назавжди. Видалити його?
# review: new
delete-for-good-all = Ці повідомлення ({ $count }) буде видалено назавжди. Видалити їх?
# review: new
delete-for-good-some = Назавжди буде видалено { $count } з { $total }. Видалити повідомлення?
# review: new
done-read = { $count ->
   *[other] Позначено як прочитані: { $messages }
}
# review: new
done-unread = { $count ->
   *[other] Позначено як непрочитані: { $messages }
}
# review: new
done-flagged = { $count ->
   *[other] Позначено прапорцем: { $messages }
}
# review: new
done-unflagged = Знято прапорець: { $messages }
# review: new
done-deleted-for-good = { $count ->
   *[other] Видалено назавжди: { $messages }
}
# review: new
done-archived = { $count ->
   *[other] Заархівовано: { $messages }
}
# review: new
done-moved = { $count ->
   *[other] Переміщено { $messages } у { $folder }
}
# review: new
done-copied = { $count ->
   *[other] Скопійовано { $messages } у { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Переміщення { $messages } у { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Копіювання { $messages } у { $folder }...
}
# review: new
done-moved-back = { $count ->
   *[other] Повернено { $messages } у { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [1] Розмова відстежується
    [one] Відстежується { $count } розмова
    [few] Відстежуються { $count } розмови
    [many] Відстежується { $count } розмов
   *[other] Відстежується { $count } розмови
}
# review: new
done-unwatched = { $count ->
    [1] Розмова більше не відстежується
    [one] Більше не відстежується { $count } розмова
    [few] Більше не відстежуються { $count } розмови
    [many] Більше не відстежується { $count } розмов
   *[other] Більше не відстежується { $count } розмови
}
# review: new
done-ignored = { $count ->
    [1] Розмова ігнорується
    [one] Ігнорується { $count } розмова
    [few] Ігноруються { $count } розмови
    [many] Ігнорується { $count } розмов
   *[other] Ігнорується { $count } розмови
}
# review: new
done-unignored = { $count ->
    [1] Розмова більше не ігнорується
    [one] Більше не ігнорується { $count } розмова
    [few] Більше не ігноруються { $count } розмови
    [many] Більше не ігнорується { $count } розмов
   *[other] Більше не ігнорується { $count } розмови
}
# the destination after "у" (into), in the accusative: "Переміщено 2 повідомлення у свої папки"
# review: new
their-folders = свої папки
# review: new
undo-move = Скасувати переміщення
# review: new
undo-delete = Скасувати видалення
# review: new
undo-archive = Скасувати архівування
# review: new
undo-junk = Скасувати позначку «Небажане»
# review: new
undo-not-junk = Скасувати позначку «Не небажане»
# review: new
undo-send = Скасувати надсилання
# review: new
nothing-to-undo = Немає чого скасовувати.
# review: new
messages-gone = Цих повідомлень уже немає.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Ця папка не може містити повідомлень.
# review: new
not-archived-here = Повідомлення з цієї папки неможливо заархівувати.
# review: new
not-emptied-here = Очистити можна лише папки «Видалені» та «Небажана пошта».
# review: new
next-unread-question = У папці «{ $folder }» більше немає непрочитаних повідомлень.

    Перейти до папки «{ $next }», наступної з непрочитаними повідомленнями?
# review: new
no-unread-left = Непрочитаних повідомлень не залишилося.
# review: new
empty-question = { $count ->
    [1] Очистити папку «{ $folder }»?

        Повідомлення в ній буде видалено назавжди. Відновити його буде неможливо.
   *[other] Очистити папку «{ $folder }»?

        Усі повідомлення в ній ({ $messages }) буде видалено назавжди. Відновити їх буде неможливо.
}
# review: new
no-junk-folder = У цьому обліковому записі немає папки «Небажана пошта», куди можна перемістити повідомлення.
# review: new
no-inbox-folder = У цьому обліковому записі немає папки «Вхідні», куди можна перемістити повідомлення.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
# review: new
done-flagged-color = Позначено { $messages } { $color ->
    [red] червоним
    [orange] помаранчевим
    [yellow] жовтим
    [green] зеленим
    [blue] синім
    [purple] фіолетовим
   *[gray] сірим
} прапорцем
# the Flag menu: the colours of Apple Mail's flags
# review: new
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

# review: new
move-window-title-move = { $count ->
    [1] Перемістити повідомлення
    [many] Перемістити { $count } повідомлень
   *[other] Перемістити { $count } повідомлення
}
# review: new
move-window-title-copy = { $count ->
    [1] Копіювати повідомлення
    [many] Копіювати { $count } повідомлень
   *[other] Копіювати { $count } повідомлення
}
# review: new
move-window-prompt-move = { $count ->
    [1] Перемістити виділене повідомлення в:
    [many] Перемістити { $count } виділених повідомлень у:
   *[other] Перемістити виділені повідомлення ({ $count }) у:
}
# review: new
move-window-prompt-copy = { $count ->
    [1] Копіювати виділене повідомлення в:
    [many] Копіювати { $count } виділених повідомлень у:
   *[other] Копіювати виділені повідомлення ({ $count }) у:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Нещодавні
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (поточна)
# a folder used last, with its account when there are several: "Archive (Work)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Переміщення { $done } з { $messages } у { $folder }...
# review: new
transfer-copying = Копіювання { $done } з { $messages } у { $folder }...
# the destination after "у" (into), in the accusative
# review: new
transfer-another-account = інший обліковий запис
# review: new
transfer-folder-gone = папки, куди їх надсилали, уже немає
# review: new
transfer-not-on-server = повідомлення вже немає на сервері
# review: new
transfer-not-moved = { $count ->
   *[other] Не вдалося перемістити в інший обліковий запис { $messages }: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] Не вдалося скопіювати в інший обліковий запис { $messages }: { $reason }
}
# review: new
transfer-none-moved = Не вдалося перемістити жодного повідомлення
# review: new
transfer-none-copied = Не вдалося скопіювати жодного повідомлення

## Messages as files

# review: new
export-not-in-time = повідомлення не вдалося вчасно завантажити
# review: new
export-not-saved = Не вдалося зберегти { $failed } з { $messages } ({ $problems })
# review: new
export-not-attached = не вдалося вкласти повідомлення: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
   *[other] Збережено { $messages } у папку «{ $folder }»
}
# review: new
download-progress = Завантаження: { $done } з { $total }
# review: new
download-done = Завантажено { $size }
# review: new
downloading-messages = { $count ->
   *[other] Завантаження: { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
# review: new
import-put = { $count ->
   *[other] Поміщено { $messages } у { $folder }
}
# review: new
import-not-put = Ці файли не поміщено в папку:

    { $problems }

## Problems the windows show

# review: new
error-store = локальне сховище: { $error }
# review: new
error-not-found = не знайдено
# review: new
error-closed = завершення роботи
# review: new
error-other-account = браузер увійшов у { $email }, а не в цей обліковий запис
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = сервер не прийняв вхід ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = не вдалося з’єднатися із сервером ({ $reason })
# review: new
error-in-use = його неможливо вилучити, поки ним входять облікові записи: { $accounts }
# review: new
error-turned-off = цей застосунок для входу вимкнено для нових облікових записів
# review: new
error-folder-name = назва папки має містити від 1 до 200 символів і не може містити керівних символів
# review: new
error-folder-separator = на цьому сервері назва папки не може містити «{ $separator }»
# review: new
error-folder-special = папку «Вхідні» та спеціальні папки неможливо перейменувати або видалити
# review: new
error-no-recipients = у повідомлення немає одержувачів
# review: new
error-bad-address = «{ $address }» не є адресою електронної пошти
# review: new
error-not-own-address = { $address } не є однією з адрес відправника цього облікового запису. Додайте її в поле «Інші адреси, з яких ви надсилаєте» у властивостях облікового запису.
# review: new
rule-query-refused = Правила не можуть фільтрувати за папкою чи датою ({ $words }).
# review: new
rule-no-query = Введіть умови пошуку для вхідних повідомлень.
# review: new
rule-no-action = Виберіть принаймні одну дію для правила.
# review: new
error-attachment = не вдалося прочитати { $path }: { $error }
# review: new
error-no-drafts = в обліковому записі немає папки «Чернетки», щоб зберегти повідомлення
# review: new
error-draft-attachment = не вдалося зберегти вкладення чернетки: { $error }
# review: new
error-password-not-saved = не вдалося зберегти пароль для наступного запуску: { $error }
# review: new
error-sign-in-not-saved = не вдалося зберегти нові дані входу для наступного запуску: { $error }
# review: new
error-import-unreadable = неможливо прочитати { $path }: { $error }
# review: new
error-import-too-large = { $path } більший за 50 МБ
# review: new
error-import-not-mail = { $path } не є повідомленням електронної пошти
# review: new
error-list-answered = сервер списку розсилки повернув стан { $status }
# review: new
error-not-built = не вдалося створити повідомлення
# review: new
error-outbox-waits = { $count ->
    [1] повідомлення чекає в папці «Вихідні» й буде надіслане під час наступного надсилання й отримання
    [one] { $count } повідомлення чекає в папці «Вихідні» й буде надіслане під час наступного надсилання й отримання
    [many] { $count } повідомлень чекають у папці «Вихідні» й будуть надіслані під час наступного надсилання й отримання
   *[other] { $count } повідомлення чекають у папці «Вихідні» й будуть надіслані під час наступного надсилання й отримання
}
# review: new
error-draft-not-removed = не вдалося вилучити попередню чернетку повідомлення з папки «Чернетки»: { $reason }
# review: new
error-sent-but = повідомлення надіслано, але { $problem }
# review: new
error-sent-still-in-outbox = воно досі в папці «Вихідні»: { $error }
# review: new
error-sent-no-copy = не вдалося зберегти копію в папці «Надіслані»: { $reason }
# review: new
error-no-password = для цього облікового запису немає пароля
# review: new
error-no-sign-in = для цього облікового запису немає даних входу
# review: new
error-provider-missing = ця збірка не може виконати вхід у { $provider }: можливо, її застосунок для входу вилучено?
# review: new
error-provider-servers = сервери цього облікового запису не збігаються із серверами його застосунку для входу
# review: new
error-app-scopes = { $reason }. Поштовий сервер не прийняв токен застосунку для входу: перевірте, чи дозволи (scopes) застосунку дають доступ до пошти
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google ще не перевірив Inbox Classic, тому дозволяє входити через нього лише тестовим користувачам. Скористайтеся власним застосунком для входу Google або паролем застосунку, або, якщо ви тестовий користувач, увімкніть його в розділі «Застосунки для входу» (Файл > Облікові записи).
# review: new
sign-in-off-other = Його вимкнено в розділі «Застосунки для входу» (Файл > Облікові записи), де його можна знову ввімкнути.
# review: new
sign-in-app-no-name = застосунку для входу потрібна назва
# review: new
sign-in-app-no-client = бракує ідентифікатора клієнта
# review: new
sign-in-app-no-scopes = застосунку для входу потрібні дозволи (scopes), що дають доступ до пошти
# review: new
sign-in-app-bad-host = адреси сервера { $server } немає, або вона не є дійсною назвою вузла
# review: new
sign-in-app-plain = сервер { $server } має використовувати SSL/TLS або STARTTLS
# review: new
sign-in-app-not-checked = видавця ще не перевірено
# review: new
sign-in-app-issuer-changed = видавець змінився: введіть секрет клієнта знову або вилучіть його
# review: new
sign-in-register-google = У Google Cloud Console створіть клієнт OAuth типу «Desktop app» із дозволом https://mail.google.com/ на екрані згоди. Поки застосунок у режимі тестування, входити можуть лише його тестові користувачі.
# review: new
sign-in-register-microsoft = У Microsoft Entra зареєструйте застосунок із платформою «Mobile and desktop applications», URI переспрямування http://localhost, дозволеними потоками публічного клієнта та делегованими дозволами IMAP.AccessAsUser.All, SMTP.Send і offline_access. Лише для своєї організації вкажіть видавцем https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Зареєструйте нативний (публічний) клієнт із наведеним нижче URI переспрямування; провайдер має дозволяти в ньому будь-який порт (RFC 8252). Додайте дозвіл, яким провайдер надає доступ до пошти.

## Calendar invitations

# review: new
repeats = Повторення
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Щодня
        [one] Кожен { $interval } день
        [few] Кожні { $interval } дні
        [many] Кожні { $interval } днів
       *[other] Кожні { $interval } дня
    }
    [week] { $interval ->
        [1] Щотижня
        [one] Кожен { $interval } тиждень
        [few] Кожні { $interval } тижні
        [many] Кожні { $interval } тижнів
       *[other] Кожні { $interval } тижня
    }
    [month] { $interval ->
        [1] Щомісяця
        [one] Кожен { $interval } місяць
        [few] Кожні { $interval } місяці
        [many] Кожні { $interval } місяців
       *[other] Кожні { $interval } місяця
    }
   *[year] { $interval ->
        [1] Щороку
        [one] Кожен { $interval } рік
        [few] Кожні { $interval } роки
        [many] Кожні { $interval } років
       *[other] Кожні { $interval } року
    }
}
# "Every week on Monday, Wednesday"
# review: new
repeats-on = { $repeats }, дні: { $days }
# "Every week, 10 times"
# review: new
repeats-times = { $count ->
    [1] { $repeats }, один раз
    [one] { $repeats }, { $count } раз
    [few] { $repeats }, { $count } рази
    [many] { $repeats }, { $count } разів
   *[other] { $repeats }, { $count } раза
}
# review: new
day-monday = понеділок
# review: new
day-tuesday = вівторок
# review: new
day-wednesday = середа
# review: new
day-thursday = четвер
# review: new
day-friday = пʼятниця
# review: new
day-saturday = субота
# review: new
day-sunday = неділя

## AI agents

# review: new
agent-level-read = Читати пошту: папки, список повідомлень, пошук і повідомлення
# review: new
agent-level-organize = Упорядковувати пошту: стан прочитання, прапорці, небажана пошта, переміщення, архівування, нові папки, видалення в «Видалені» та вихід зі списків розсилки після вашого «так»
# review: new
agent-level-drafts = Писати чернетки, які надсилаєте ви
# review: new
agent-level-send = Надсилати пошту, кожне повідомлення лише після вашого «так»
# review: new
agent-connect-title = { $program } хоче користуватися вашою поштою
# review: new
agent-connect-detail = ШІ-агент попросив дозволу працювати з Inbox Classic. Виберіть, що йому можна робити і які облікові записи він може бачити; пізніше це можна змінити в меню Сервіс > ШІ-агенти.

    Агенти читають пошту, яку написали інші люди, і повідомлення може спробувати їх обдурити. Inbox Classic завжди запитує вас, перш ніж агент щось надішле.
# review: new
agent-reply-to = Відповідь на «{ $subject }»
# review: new
agent-reply-all-on = Відповідь усім на «{ $subject }»
# review: new
agent-forward-of = Пересилання «{ $subject }»
# review: new
agent-never-written-one = Ви ще ніколи не писали на { $address }.
# review: new
agent-never-written-many = Ви ще ніколи не писали на деякі з цих адрес: { $count }.
# review: new
agent-send-title = { $program } хоче надіслати це повідомлення
# review: new
agent-send-detail = Перевірте одержувачів і вміст повідомлення. Після підтвердження повідомлення чекатиме в папці «Вихідні» { $seconds } с, і там його ще можна буде видалити.
# review: new
agent-change-title = Що може робити { $program }
# review: new
agent-change-allowed = Змініть, що ШІ-агентам цієї програми можна робити з вашою поштою.
# review: new
agent-change-refused = Ви заборонили цій програмі доступ. Дозвольте його, щоб знову надати її агентам доступ до вашої пошти.
# review: new
agent-log-taken-back = { $entry } (скасовано)
# review: new
agent-files = Файли: { $files }
# review: new
agent-undo-refused = Це неможливо скасувати.
# review: new
agent-undo-refused-why = Це неможливо скасувати: { $reason }.
# review: new
agent-undo-impossible = це неможливо скасувати
# review: new
agent-undo-not-in-folder = повідомлення вже немає в тій папці
# review: new
agent-undo-not-arrived = повідомлення (ще) немає в папці, куди його перенесено
# review: new
agent-undo-sent = повідомлення вже надіслано
# review: new
agent-original-not-downloaded = початкове повідомлення ще не завантажено. Спершу відкрийте його
# review: new
agent-turned-away = Відхилено
# review: new
agent-can-nothing = Нічого
# review: new
agent-can-read = читати
# review: new
agent-can-organize = упорядковувати
# review: new
agent-can-drafts = писати чернетки
# review: new
agent-can-send = надсилати з вашої згоди
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first } і { $last }
# review: new
agent-accounts = { $count ->
    [0] жодного облікового запису
    [one] { $count } обліковий запис
    [few] { $count } облікові записи
    [many] { $count } облікових записів
   *[other] { $count } облікового запису
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Це повідомлення неможливо прочитати.
# review: new
agent-encrypted-original = Це повідомлення зашифроване: агент не може відповісти на нього чи переслати його, бо не вміє шифрувати.
# review: new
agent-encrypted = Це повідомлення зашифроване. Прочитати його може лише користувач, в Inbox Classic.
# review: new
list-encrypted = Зашифроване повідомлення
# review: new
agent-log-composed = Відкрито «{ $subject }» у новому повідомленні, щоб ви його завершили
# review: new
agent-log-refused = Ви не надіслали «{ $subject }»
# review: new
agent-log-sent = Надіслано «{ $subject }» до { $to }
# review: new
agent-log-draft = Збережено чернетку «{ $subject }»
# review: new
agent-log-draft-replaced = Замінено чернетку «{ $subject }»
# review: new
agent-log-draft-discarded = Відкинуто чернетку «{ $subject }»
# review: new
agent-draft-note = { $program }, ШІ-агент, написав цю чернетку. Перевірте одержувачів і текст, перш ніж надіслати її.
# review: new
agent-log-read = Позначено як прочитане «{ $subject }»
# review: new
agent-log-unread = Позначено як непрочитане «{ $subject }»
# review: new
agent-log-flagged = Позначено прапорцем «{ $subject }»
# review: new
agent-log-unflagged = Знято прапорець з «{ $subject }»
# review: new
agent-log-deleted = Видалено «{ $subject }»
# review: new
agent-log-moved = Переміщено «{ $subject }» у { $folder }
# review: new
agent-log-junk = Позначено «{ $subject }» як небажане
# review: new
agent-log-not-junk = Позначено «{ $subject }» як не небажане
# review: new
agent-log-archived = Заархівовано «{ $subject }»
# review: new
agent-log-folder = Створено папку «{ $name }»
# review: new
agent-log-unsubscribed = Скасовано підписку на список розсилки «{ $subject }»
# review: new
agent-log-unsubscribe-failed = Не вдалося скасувати підписку на список розсилки «{ $subject }»: { $reason }
# review: new
agent-log-unsubscribe-refused = Ви не скасували підписку: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [1] { $program } хоче скасувати вашу підписку на список розсилки
    [one] { $program } хоче скасувати вашу підписку на { $count } список розсилки
    [few] { $program } хоче скасувати вашу підписку на { $count } списки розсилки
    [many] { $program } хоче скасувати вашу підписку на { $count } списків розсилки
   *[other] { $program } хоче скасувати вашу підписку на { $count } списку розсилки
}
# review: new
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic просить список нижче більше не надсилати вам листів, через скасування підписки одним клацанням, яке він пропонує. Більше нічого не надсилається, а ваші повідомлення залишаються там, де є.
   *[other] Inbox Classic просить кожен список нижче більше не надсилати вам листів, через скасування підписки одним клацанням, яке пропонує список. Більше нічого не надсилається, а ваші повідомлення залишаються там, де є.
}

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = провайдер не надав токена оновлення
# review: new
sign-in-no-account = провайдер не повідомив, який обліковий запис увійшов
# review: new
sign-in-not-finished = вхід не завершено
# review: new
secrets-unavailable = { $store } недоступна
# review: new
secrets-unavailable-why = { $store } недоступна: { $error }
# review: new
secrets-windows = Диспетчер облікових даних
# review: new
secrets-mac = Зв’язка ключів
# review: new
secrets-linux = Системна в’язка ключів (Secret Service)
# review: new
error-no-such-file = такого файлу немає
# review: new
cards-file-too-big = Цей файл завеликий для адресної книги.
# review: new
ui-sender-added = { $name } додано до адресної книги.
# review: new
ui-sender-known = { $name } уже є в адресній книзі.
# review: new
ui-sender-none = У відправника цього повідомлення немає адреси електронної пошти, яку можна додати.
# review: new
card-name-needed = У контакту немає ні імені, ні адреси електронної пошти.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Код від { $domain }
# review: new
otp-copy = Копіювати
# review: new
otp-note = Вводьте його лише на сторінці { $domain }.
# review: new
otp-old = Цей код надіслано більш ніж за годину до того, як ви його відкрили, і, імовірно, він уже не дійсний.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } учасник
        [few] { $count } учасники
        [many] { $count } учасників
       *[other] { $count } учасника
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code }: ваш код для { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Дійсний
# review: new
pgp-key-expires = Дійсний до { $date }
# review: new
pgp-key-expired = Термін дії сплив { $date }
# review: new
pgp-key-revoked = Відкликаний
# review: new
pgp-key-revoked-why = Відкликаний: { $reason }
# review: new
pgp-key-not-valid = Недійсний
# review: new
pgp-key-locked = Неможливо використати: ключа, що його захищає, більше немає в сховищі «{ $store }». Імпортуйте його резервну копію знову.
# review: new
pgp-source-own = Створено в Inbox Classic
# review: new
pgp-source-file = Імпортовано з файлу
# review: new
pgp-source-paste = Вставлено
# review: new
pgp-source-attachment = З повідомлення
# review: new
pgp-source-vcard = З картки контакту
# review: new
pgp-source-wkd = Від поштового провайдера відправника
# review: new
pgp-source-keyserver = З keys.openpgp.org
# review: new
pgp-source-autocrypt = Із заголовка Autocrypt повідомлення
# review: new
pgp-error-no-store = Закриті ключі захищено сховищем «{ $store }», яке неможливо використати: { $error }
# review: new
pgp-error-wrong-passphrase = Парольна фраза неправильна.
# review: new
pgp-error-not-a-key = Це не ключ OpenPGP.
# review: new
pgp-error-too-large = Ключ завеликий.
# review: new
pgp-error-unusable = Ключ використовує застарілу або слабку криптографію, тому його неможливо використати.
# review: new
pgp-imported-private = { $count ->
    [1] Ваш закритий ключ імпортовано.
    [one] Імпортовано { $count } закритий ключ.
    [few] Імпортовано { $count } закриті ключі.
    [many] Імпортовано { $count } закритих ключів.
   *[other] Імпортовано { $count } закритого ключа.
}
# review: new
pgp-imported-public = { $count ->
    [1] Імпортовано один ключ.
    [one] Імпортовано { $count } ключ.
    [few] Імпортовано { $count } ключі.
    [many] Імпортовано { $count } ключів.
   *[other] Імпортовано { $count } ключа.
}
# review: new
pgp-imported-pending = Для { $addresses } уже використовується інший ключ: новий чекає в контакті, доки ви його не виберете.
# review: new
pgp-error-needs-passphrase = Закритий ключ захищено парольною фразою. Введіть її, щоб імпортувати ключ.
# review: new
pgp-error-mismatch = Закритий ключ не відповідає своєму відкритому ключу. Можливо, його змінено.
# review: new
pgp-file-name-public = { $who } відкритий ключ.asc
# review: new
pgp-file-name-private = { $who } резервна копія закритого ключа.asc
# review: new
pgp-pending = { $date } знайдено інший ключ для { $address }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Підписано: { $signer }, ключ перевірено
# review: new
pgp-part-signed = Підписано: { $signer } (ключ не перевірено)
# review: new
pgp-part-other = Підписано: { $signer }, але це не відправник
# review: new
pgp-part-unknown-key = Підписано, але ключ невідомий
# review: new
pgp-part-not-signed = Не підписано
# review: new
pgp-part-not-checked = Підпис не перевірено
# review: new
pgp-part-encrypted = Зашифровано. { $signature }
# review: new
pgp-part-no-key = Зашифровано ключем, якого у вас немає
# review: new
pgp-part-changed = Зашифровану частину змінено дорогою, тому її не показано
# review: new
pgp-part-unprotected = Зашифровано без захисту від змін, тому не показано
# review: new
pgp-part-broken = Зашифровану частину неможливо прочитати
# review: new
pgp-why-mismatch = Підпис не відповідає цьому тексту
# review: new
pgp-why-weak-hash = Підпис використовує { $hash }, що вже не є безпечним
# review: new
pgp-why-key-expired = Підписано після того, як термін дії ключа сплив { $date }
# review: new
pgp-why-key-revoked = Підписано відкликаним ключем
# review: new
pgp-why-not-signing-key = Підписано ключем, якому не дозволено підписувати
# review: new
pgp-why-from-future = Підпис датовано майбутнім
# review: new
pgp-why-signature-expired = Термін дії підпису сплив
# review: new
pgp-why-key-not-valid = Підписано недійсним ключем
# review: new
pgp-why-not-for-you = Підписано для інших одержувачів і передано вам
pgp-why-not-key-in-use = Підписано іншим ключем, ніж той, що використовується для { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Зображення завантажено з інтернету
# review: new
pgp-error-no-own-key = У вас немає ключа для { $address }, щоб підписувати чи шифрувати. Створіть його в меню Сервіс > Ключі шифрування або вимкніть «Підписати» та «Зашифрувати».
# review: new
pgp-error-missing-keys = { $count ->
    [1] Для { $addresses } немає ключа для шифрування.
   *[other] Для цих одержувачів немає ключа для шифрування: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Це повідомлення цитує або пересилає зашифроване повідомлення, тому його можна надіслати лише зашифрованим. Увімкніть «Зашифрувати» або вилучіть цитований текст.
# review: new
pgp-error-protect = Не вдалося підписати чи зашифрувати повідомлення: { $reason }
# review: new
pgp-found-keys = Знайдено ключ для { $addresses }.
# review: new
pgp-found-none = Для { $addresses } ключа не знайдено. Попросіть надіслати вам відкритий ключ.
# review: new
pgp-found-no-key = Ключа не знайдено.
# review: new
pgp-find-unavailable = Зараз неможливо шукати ключі: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org надіслав посилання для підтвердження на { $addresses }. Ваш ключ буде опубліковано там, щойно ви перейдете за ним.
# review: new
pgp-publish-done = Ваш ключ опубліковано на keys.openpgp.org для { $addresses }.
# review: new
pgp-publish-failed = Не вдалося опублікувати ключ: { $error }
# review: changed
pgp-keyserver-off = Пошук ключів на keys.openpgp.org вимкнено в розділі { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [1] Зашифровано й підписано: прочитати його можете лише ви та { $addresses }.
    [one] Зашифровано й підписано: прочитати його можете лише ви та його { $count } одержувач.
    [few] Зашифровано й підписано: прочитати його можете лише ви та його { $count } одержувачі.
    [many] Зашифровано й підписано: прочитати його можете лише ви та його { $count } одержувачів.
   *[other] Зашифровано й підписано: прочитати його можете лише ви та його одержувачі ({ $count }).
}
# review: new
pgp-compose-encrypt-ready = Повідомлення буде зашифровано й підписано. Додайте одержувачів, чиї ключі у вас є.
# review: new
pgp-compose-missing = { $count ->
    [1] Для { $addresses } немає ключа, тому повідомлення ще не можна зашифрувати.
    [one] Для { $count } одержувача немає ключа, тому повідомлення ще не можна зашифрувати: { $addresses }.
    [few] Для { $count } одержувачів немає ключа, тому повідомлення ще не можна зашифрувати: { $addresses }.
    [many] Для { $count } одержувачів немає ключа, тому повідомлення ще не можна зашифрувати: { $addresses }.
   *[other] Для { $count } одержувача немає ключа, тому повідомлення ще не можна зашифрувати: { $addresses }.
}
# review: new
pgp-compose-looking = Пошук ключів для { $addresses }...
# review: new
pgp-compose-signed = Підписано: одержувачі можуть перевірити, що повідомлення від вас і його не змінено.
# review: new
pgp-compose-reply-clear = Не зашифровано, хоча повідомлення, на яке ви відповідаєте або яке пересилаєте, було зашифроване.
# review: new
pgp-compose-encrypted-files = Вкладено файли зашифрованого повідомлення, тому це повідомлення можна надіслати лише зашифрованим. Увімкніть «Зашифрувати» або вилучіть ці файли.
# review: new
pgp-compose-sign-tip = Підписати повідомлення своїм ключем, щоб одержувачі могли перевірити, що воно від вас і його не змінено
# review: new
pgp-compose-sign-tip-encrypted = Зашифроване повідомлення завжди підписується
# review: new
pgp-compose-encrypt-tip = Зашифрувати повідомлення, щоб прочитати його могли лише ви та його одержувачі
# review: new
pgp-compose-make-key = У вас ще немає ключа для { $address }. Створити його зараз? З ним ваші повідомлення можна буде підписувати й шифрувати.
# review: new
pgp-compose-key-unusable = Ваш ключ для { $address } не можна використати ({ $state }). Відкрийте «Ключі шифрування», щоб імпортувати його резервну копію або створити новий ключ.
# review: new
pgp-compose-encrypt-off-quote = Це повідомлення цитує або пересилає зашифроване повідомлення. Без шифрування його не можна буде надіслати, доки ви не вилучите цитований текст. Усе одно вимкнути шифрування?
# review: new
pgp-compose-encrypt-off-reply = Це повідомлення відповідає на зашифроване повідомлення або пересилає його. Без шифрування ваше повідомлення зможе прочитати будь-хто, через кого воно пройде дорогою. Вимкнути шифрування?
# review: new
pgp-recipient-verified = Ключ перевірено
# review: new
pgp-recipient-found = Ключ не перевірено
# review: new
pgp-recipient-own = Ваш власний ключ
# review: new
pgp-recipient-looking = Пошук ключа...
# review: new
pgp-recipient-missing = Немає ключа
# review: new
pgp-recipient-not-found = Немає ключа: не знайдено { $date }
# review: new
pgp-recipient-unusable = Ключ не можна використати: { $state }
# review: new
pgp-recipients-intro = Повідомлення шифрується для ключа кожного одержувача і для вашого.
# review: new
pgp-recipients-intro-missing = { $count ->
    [1] Один одержувач не має ключа для шифрування. Знайдіть його ключ, вилучіть його з цього повідомлення або надішліть повідомлення без шифрування.
    [one] { $count } одержувач не має ключа для шифрування. Знайдіть їхні ключі, вилучіть їх з цього повідомлення або надішліть повідомлення без шифрування.
    [few] { $count } одержувачі не мають ключа для шифрування. Знайдіть їхні ключі, вилучіть їх з цього повідомлення або надішліть повідомлення без шифрування.
    [many] { $count } одержувачів не мають ключа для шифрування. Знайдіть їхні ключі, вилучіть їх з цього повідомлення або надішліть повідомлення без шифрування.
   *[other] Одержувачів без ключа для шифрування: { $count }. Знайдіть їхні ключі, вилучіть їх з цього повідомлення або надішліть повідомлення без шифрування.
}
# review: new
pgp-details-part = Частина { $number }: { $label }
# review: new
pgp-details-signed = Підписано { $when } ключем { $key }
# review: new
pgp-details-unknown-key = Підписано ключем { $key }, якого у вас немає
# review: new
pgp-details-opened = Зашифровано вашим ключем { $key }
# review: new
pgp-details-for = Зашифровано для { $keys }
# review: new
pgp-details-plain = Не підписано й не зашифровано
# review: new
pgp-bar-parts = Частин у цьому повідомленні: { $count } ({ $list }). Кожна частина вказує, як її захищено.
# review: new
pgp-bar-count-verified = перевірених: { $count }
# review: new
pgp-bar-count-good = { $count ->
   *[other] підписаних або зашифрованих: { $count }
}
# review: new
pgp-bar-count-warning = { $count ->
   *[other] потребують уваги: { $count }
}
# review: new
pgp-bar-count-neutral = без підтвердженого підпису: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Параметри
# review: new
setup-part-preferences = Налаштування вікон
# review: new
setup-part-accounts = Облікові записи
# review: new
setup-part-sign-in-apps = Застосунки для входу
# review: new
setup-part-contacts = Контакти й групи
# review: new
setup-part-keys = Ключі шифрування
# review: new
setup-part-rules = Правила для повідомлень
# review: new
setup-part-trusted-senders = Довірені відправники
# review: new
setup-holds-settings = { $count ->
    [one] { $count } параметр
    [few] { $count } параметри
    [many] { $count } параметрів
   *[other] { $count } параметра
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } налаштування
    [few] { $count } налаштування
    [many] { $count } налаштувань
   *[other] { $count } налаштування
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } обліковий запис
    [few] { $count } облікові записи
    [many] { $count } облікових записів
   *[other] { $count } облікового запису
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } застосунок для входу
    [few] { $count } застосунки для входу
    [many] { $count } застосунків для входу
   *[other] { $count } застосунку для входу
}
# review: new
setup-holds-built-in = Які вбудовані застосунки для входу ввімкнено
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } контакт
    [few] { $count } контакти
    [many] { $count } контактів
   *[other] { $count } контакту
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } група
    [few] { $count } групи
    [many] { $count } груп
   *[other] { $count } групи
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } власний ключ
    [few] { $count } власні ключі
    [many] { $count } власних ключів
   *[other] { $count } власного ключа
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } ключ контакту
    [few] { $count } ключі контактів
    [many] { $count } ключів контактів
   *[other] { $count } ключа контактів
}
# review: new
setup-holds-rules = { $count ->
    [one] { $count } правило
    [few] { $count } правила
    [many] { $count } правил
   *[other] { $count } правила
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] { $count } довірений відправник
    [few] { $count } довірені відправники
    [many] { $count } довірених відправників
   *[other] { $count } довіреного відправника
}
# review: new
setup-sign-in-password = Пароль
# review: new
setup-account-secret-password = Його пароль є у файлі.
# review: new
setup-account-secret-token = Його дані входу є у файлі.
# review: new
setup-account-asks-password = Після імпорту він запитає пароль.
# review: new
setup-account-signs-in-again = Після імпорту в нього треба буде увійти знову.
# review: new
setup-account-here = Його вже налаштовано тут, тому його пропущено.
# review: new
setup-account-no-app = Він входить через { $app }, який тут не налаштовано. Імпортуйте також застосунки для входу.
# review: new
setup-invalid-address = «{ $address }» не є адресою електронної пошти.
# review: new
setup-invalid-server = Сервер { $server } не має придатної назви чи порту.
# review: new
setup-invalid-user = Немає імені користувача.
# review: new
setup-invalid-sign-in = Він входить у спосіб, якого Inbox Classic не знає.
# review: new
setup-error-empty = Файл порожній.
# review: new
setup-error-too-large = Файл завеликий для налаштувань Inbox Classic.
# review: new
setup-error-not-setup = Цей файл не містить налаштувань Inbox Classic.
# review: new
setup-error-damaged = Файл налаштувань пошкоджено, його неможливо прочитати.
# review: new
setup-error-newer = Ці налаштування збережено новішою версією Inbox Classic ({ $version }). Оновіть Inbox Classic і імпортуйте їх знову.
# review: new
setup-error-needs-passphrase = Ці налаштування захищено парольною фразою. Введіть парольну фразу, з якою їх збережено.
# review: new
setup-error-wrong-passphrase = Це не та парольна фраза, з якою збережено ці налаштування.
# review: new
setup-error-changed = Файл налаштувань змінено або пошкоджено після збереження, тому його неможливо імпортувати.
# review: new
setup-error-read = Не вдалося прочитати файл налаштувань: { $error }
# review: new
setup-error-write = Не вдалося зберегти налаштування: { $error }
# review: new
setup-error-no-parts = Виберіть принаймні одну частину.
# review: new
setup-left-out = { $count ->
    [one] { $count } запис розділу «{ $part }» неможливо використати, тому його пропущено.
    [few] { $count } записи розділу «{ $part }» неможливо використати, тому їх пропущено.
    [many] { $count } записів розділу «{ $part }» неможливо використати, тому їх пропущено.
   *[other] { $count } запису розділу «{ $part }» неможливо використати, тому їх пропущено.
}
# review: new
setup-imported-settings = Параметри замінено.
# review: new
setup-imported-preferences = Налаштування вікон замінено.
# review: new
setup-added-accounts = { $count ->
    [one] Додано { $count } обліковий запис.
    [few] Додано { $count } облікові записи.
    [many] Додано { $count } облікових записів.
   *[other] Додано { $count } облікового запису.
}
# review: new
setup-skipped-here = { $address } уже налаштовано тут, тому його пропущено.
# review: new
setup-skipped-no-app = { $address } пропущено: він входить через { $app }, який тут не налаштовано.
# review: new
setup-skipped-invalid = { $address } пропущено: { $reason }
# review: new
setup-asks-password = { $address } запитає пароль під час з’єднання.
# review: new
setup-signs-in-again = { $address } попросить вас увійти знову під час з’єднання.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Додано { $count } застосунок для входу.
    [few] Додано { $count } застосунки для входу.
    [many] Додано { $count } застосунків для входу.
   *[other] Додано { $count } застосунку для входу.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } застосунок для входу вже налаштовано тут.
    [few] { $count } застосунки для входу вже налаштовано тут.
    [many] { $count } застосунків для входу вже налаштовано тут.
   *[other] { $count } застосунку для входу вже налаштовано тут.
}
# review: new
setup-added-contacts = { $count ->
    [one] До адресної книги додано { $count } контакт.
    [few] До адресної книги додано { $count } контакти.
    [many] До адресної книги додано { $count } контактів.
   *[other] До адресної книги додано { $count } контакту.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } контакт уже є в адресній книзі.
    [few] { $count } контакти вже є в адресній книзі.
    [many] { $count } контактів уже є в адресній книзі.
   *[other] { $count } контакту вже є в адресній книзі.
}
# review: new
setup-added-groups = { $count ->
    [one] Додано або доповнено { $count } групу.
    [few] Додано або доповнено { $count } групи.
    [many] Додано або доповнено { $count } груп.
   *[other] Додано або доповнено { $count } групи.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Додано { $count } власний ключ.
    [few] Додано { $count } власні ключі.
    [many] Додано { $count } власних ключів.
   *[other] Додано { $count } власного ключа.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Додано { $count } ключ контакту.
    [few] Додано { $count } ключі контактів.
    [many] Додано { $count } ключів контактів.
   *[other] Додано { $count } ключа контактів.
}
# review: new
setup-added-rules = { $count ->
    [one] Додано { $count } правило для повідомлень.
    [few] Додано { $count } правила для повідомлень.
    [many] Додано { $count } правил для повідомлень.
   *[other] Додано { $count } правила для повідомлень.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } правило для повідомлень уже є тут.
    [few] { $count } правила для повідомлень уже є тут.
    [many] { $count } правил для повідомлень уже є тут.
   *[other] { $count } правила для повідомлень уже є тут.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } правило для повідомлень стосується облікового запису, якого тут немає, тому його пропущено.
    [few] { $count } правила для повідомлень стосуються облікових записів, яких тут немає, тому їх пропущено.
    [many] { $count } правил для повідомлень стосуються облікових записів, яких тут немає, тому їх пропущено.
   *[other] { $count } правила для повідомлень стосуються облікових записів, яких тут немає, тому їх пропущено.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } правило для повідомлень переміщує повідомлення в папку, яка з’явиться після синхронізації її облікового запису.
    [few] { $count } правила для повідомлень переміщують повідомлення в папки, які з’являться після синхронізації їхніх облікових записів.
    [many] { $count } правил для повідомлень переміщують повідомлення в папки, які з’являться після синхронізації їхніх облікових записів.
   *[other] { $count } правила для повідомлень переміщують повідомлення в папки, які з’являться після синхронізації їхніх облікових записів.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Додано { $count } довіреного відправника.
    [few] Додано { $count } довірені відправники.
    [many] Додано { $count } довірених відправників.
   *[other] Додано { $count } довіреного відправника.
}
# review: new
setup-nothing = Нічого не імпортовано.
# review: new
setup-account-servers = { $imap } і { $smtp } ({ $signin })
# review: new
setup-file-name = Параметри й облікові записи Inbox Classic
# review: new
setup-skipped-unreachable = { $name } пропущено: його служба входу недоступна. Додайте його знову в розділі «Застосунки для входу».
# review: new
attachment-runs-programs = «{ $name }» може запускати програми, тому Inbox Classic не відкриває цей файл. Збережіть його й відкрийте самостійно, якщо довіряєте його джерелу.
# review: new
attachment-decrypted-note = Це вкладення із зашифрованого повідомлення. Щоб його відкрити, Inbox Classic зберігає розшифровану копію на цьому комп’ютері, у вашій папці, яку Inbox Classic очищає через добу.
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
    [1] Сервер не позначив { $messages } як прочитане, тому воно знову позначене як непрочитане: { $reason }
    [one] Сервер не позначив { $messages } як прочитане, тому повідомлення знову позначені як непрочитані: { $reason }
   *[other] Сервер не позначив { $messages } як прочитані, тому вони знову позначені як непрочитані: { $reason }
}
undone-unread = { $count ->
    [1] Сервер не позначив { $messages } як непрочитане, тому воно знову позначене як прочитане: { $reason }
    [one] Сервер не позначив { $messages } як непрочитане, тому повідомлення знову позначені як прочитані: { $reason }
   *[other] Сервер не позначив { $messages } як непрочитані, тому вони знову позначені як прочитані: { $reason }
}
undone-flags = { $count ->
    [one] Сервер не змінив прапорці, тому зміну скасовано ({ $messages }): { $reason }
   *[other] Сервер не змінив прапорці, тому зміну скасовано ({ $messages }): { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = Показувати PDF-файли в листах
# review: new
preview-pdf-off = PDF-файли в листах не показуються.
# review: new
preview-pdf-off-crashed = PDF-файл закрив Inbox Classic під час показу, тому PDF-файли в листах більше не показуються. Зображення й далі показуються. Щоб знову показувати PDF-файли, увімкніть параметр { $option } у налаштуваннях читання.
