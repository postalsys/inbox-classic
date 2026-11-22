# Русский. Черновик, ожидает проверки носителем языка (см. core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] { $count } сообщение
    [few] { $count } сообщения
    [many] { $count } сообщений
   *[other] { $count } сообщения
}
decimal-separator = ,
list-separator = { ", " }
size-bytes = { $count ->
    [one] { $count } байт
    [few] { $count } байта
    [many] { $count } байт
   *[other] { $count } байта
}
size-kb = { $size } КБ
size-mb = { $size } МБ
size-gb = { $size } ГБ
send-delay-off = Нет
send-delay-seconds = { $count ->
    [one] { $count } секунда
    [few] { $count } секунды
    [many] { $count } секунд
   *[other] { $count } секунды
}
list-counts = { $messages }, непрочитанных: { $unread }
list-counts-selected = { $messages }, непрочитанных: { $unread }, выделено: { $selected }
list-counts-found = Найдено: { $found }, непрочитанных: { $unread }
list-counts-found-selected = Найдено: { $found }, непрочитанных: { $unread }, выделено: { $selected }
list-counts-none = Сообщения не найдены

## Special folders, as Outlook names them

folder-inbox = Входящие
folder-sent = Отправленные
folder-deleted = Удаленные
folder-drafts = Черновики
folder-junk = Нежелательная почта
folder-archive = Архив

## The reading pane

reader-no-message = Сообщение не выбрано.
reader-downloading = Загрузка сообщения…
reader-downloading-detail = Сообщение появится здесь, когда загрузка завершится.
reader-downloading-size = Размер сообщения: { $size }. Оно появится здесь после загрузки.
reader-failed = Не удалось загрузить сообщение
reader-failed-network = Не удалось связаться с почтовым сервером ({ $reason }).
reader-failed-sign-in = Почтовый сервер отклонил вход ({ $reason }). Проверьте пароль или войдите снова в окне «Учетные записи».
reader-failed-security = Не удалось установить защищенное соединение с почтовым сервером ({ $reason }).
reader-failed-other = Ответ почтового сервера: { $reason }.
reader-retry-note = Загрузка повторится после восстановления подключения к учетной записи.
reader-unreadable = Не удалось отобразить сообщение: { $error }
message-source-title = Исходный текст сообщения: { $subject }
message-source-untitled = Исходный текст сообщения

## Printing a message, and the header of a message quoted in a reply or forward

header-from = От
header-date = Дата
header-to = Кому
header-cc = Копия
header-sent = Отправлено
header-subject = Тема
header-security = Безопасность
header-part = Часть { $number }
quote-original = ----- Исходное сообщение -----
fold-show-earlier = Показать предыдущие сообщения

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Ваше сообщение не доставлено
bounce-delayed = Ваше сообщение еще не доставлено
bounce-delayed-note = Ваш почтовый сервер продолжает попытки доставки. Отправлять сообщение повторно не нужно.
bounce-show-message = Показать недоставленное сообщение
bounce-show-delayed = Показать сообщение, доставка которого задерживается
bounce-what-to-do = Что можно сделать:
bounce-delayed-do = Пока ничего делать не нужно. Если сообщение так и не удастся доставить, придет еще одно уведомление.
bounce-delayed-row-do = Пока ничего делать не нужно. Ваш почтовый сервер продолжает попытки доставки. Если они не удадутся, придет еще одно уведомление.
bounce-details = Подробности
bounce-someone = Получатель
bounce-server = Сервер: { $server }
bounce-status = Код состояния: { $status }
bounce-reported-by = Источник уведомления: { $server }
bounce-retry-minutes = Принимающий сервер попросил подождать { $count ->
    [one] { $count } минуту
    [few] { $count } минуты
    [many] { $count } минут
   *[other] { $count } минуты
} перед следующей попыткой.
bounce-retry-hours = Принимающий сервер попросил подождать { $count ->
    [one] { $count } час
    [few] { $count } часа
    [many] { $count } часов
   *[other] { $count } часа
} перед следующей попыткой.
bounce-blocklist = Черный список: { $lists }
bounce-user-unknown = Адрес не существует
bounce-user-unknown-why = На принимающем сервере нет почтового ящика с этим адресом. Возможно, в адресе опечатка или человек им больше не пользуется.
bounce-user-unknown-do = Проверьте написание адреса или спросите у человека, какой адрес он использует сейчас.
bounce-invalid-address = Недопустимый адрес
bounce-invalid-address-why = Формат адреса неверен, поэтому отправить сообщение на него нельзя.
bounce-invalid-address-do = Проверьте, нет ли в адресе лишних пробелов или пропущенных букв. После @ должно быть имя домена.
bounce-mailbox-disabled = Почтовый ящик закрыт
bounce-mailbox-disabled-why = Адрес существует, но его почтовый ящик отключен или больше не используется.
bounce-mailbox-disabled-do = Свяжитесь с человеком другим способом и спросите адрес, которым он пользуется сейчас.
bounce-mailbox-full = Почтовый ящик переполнен
bounce-mailbox-full-why = В почтовом ящике получателя нет места для новой почты.
bounce-mailbox-full-do = Попробуйте отправить сообщение через несколько дней или сообщите получателю другим способом, что его ящик переполнен.
bounce-spam-blocked = Отклонено как спам
bounce-spam-blocked-why = Принимающий сервер принял сообщение за спам.
bounce-spam-blocked-do = Отправьте его снова без того, что похоже на спам: множества ссылок, сокращенных ссылок или большого вложения. Если это повторяется, обратитесь к своему почтовому провайдеру.
bounce-virus-detected = Отклонено из-за вируса
bounce-virus-detected-why = Принимающий сервер сообщил о вирусе или другом вредоносном содержимом в сообщении или его вложениях.
bounce-virus-detected-do = Проверьте вложения антивирусом. Некоторые серверы отклоняют любые программы и архивы, поэтому такие файлы лучше передавать ссылкой.
bounce-ip-blocklisted = Ваш почтовый сервер в черном списке
bounce-ip-blocklisted-why = Принимающий сервер отклоняет почту от сервера, который отправил ваше сообщение, потому что адрес этого сервера находится в черном списке.
bounce-ip-blocklisted-do = Дело не в сообщении. Перешлите это уведомление своему почтовому провайдеру и попросите исключить сервер из списка.
bounce-domain-blocklisted = Домен в черном списке
bounce-domain-blocklisted-why = Принимающий сервер отклоняет сообщение, потому что домен вашего адреса или домен одной из ссылок в сообщении находится в черном списке.
bounce-domain-blocklisted-do = Если в сообщении есть ссылки, попробуйте отправить его без них. Иначе перешлите это уведомление тому, кто обслуживает почту вашего домена.
bounce-policy-blocked = Сообщение отклонено по правилам принимающего сервера
bounce-policy-blocked-why = Правила принимающего сервера запрещают принимать это сообщение, например из-за его размера, вложений или отправителя.
bounce-policy-blocked-do = Причина часто указана в ответе сервера в разделе «Подробности». Спросите получателя, может ли он принимать такую почту.
bounce-geo-blocked = Отклонено из-за места отправки
bounce-geo-blocked-why = Принимающий сервер не принимает почту из страны или сети, где находится ваш почтовый сервер.
bounce-geo-blocked-do = Свяжитесь с человеком другим способом или обратитесь к своему почтовому провайдеру.
bounce-relay-denied = Сервер отказался передать сообщение дальше
bounce-relay-denied-why = Сервер отказался доставлять сообщение дальше, часто потому, что оно отправлено без входа или через сервер, который не обслуживает этого получателя.
bounce-relay-denied-do = В окне «Учетные записи» проверьте параметры сервера исходящей почты и убедитесь, что для него настроен вход.
bounce-auth-failure = Не удалось подтвердить ваш адрес отправителя
bounce-auth-failure-why = Принимающий сервер не смог убедиться, что сообщение действительно пришло с вашего домена (SPF, DKIM или DMARC).
bounce-auth-failure-do = Перешлите это уведомление тому, кто обслуживает почту вашего домена: его настройки нужно исправить. Пока можно попробовать отправлять через собственный сервер вашего провайдера.
bounce-rate-limited = Слишком много почты сразу
bounce-rate-limited-why = Принимающий сервер временно принимает меньше сообщений от вашего почтового сервера.
bounce-rate-limited-do = Подождите немного и отправьте сообщение снова. Если получателей много, отправляйте его небольшим группам.
bounce-greylisting = Временно задержано
bounce-greylisting-why = Принимающий сервер просит неизвестных отправителей повторить попытку чуть позже. Это обычный способ защиты от спама.
bounce-greylisting-do = Если сервер продолжает попытки доставки, подождите. Если уведомление сообщает об окончательной ошибке, попробуйте отправить сообщение повторно позже.
bounce-server-error = Сбой на принимающем сервере
bounce-server-error-why = С принимающим сервером не удалось связаться, или он не смог принять сообщение из-за собственной ошибки.
bounce-server-error-do = Отправьте сообщение позже. Если ошибка повторяется, проверьте часть адреса после @ на опечатки.
bounce-unknown = Не доставлено
bounce-unknown-why = В уведомлении не указана точная причина.
bounce-unknown-do = Посмотрите ответ сервера в разделе «Подробности». Если он не проясняет причину, перешлите уведомление своему почтовому провайдеру.

## Several messages selected

selection-title = { $count ->
    [one] Выделено { $count } сообщение
    [few] Выделено { $count } сообщения
    [many] Выделено { $count } сообщений
   *[other] Выделено { $count } сообщения
}
selection-unread = Непрочитанных: { $count }
selection-flagged = С флажком: { $count }
delete-for-good-one = Это сообщение будет удалено навсегда. Удалить его?
delete-for-good-all = Эти сообщения ({ $count }) будут удалены навсегда. Удалить их?
delete-for-good-some = Удалить выбранные сообщения? Часть из них будет удалена навсегда ({ $count } из { $total }).
done-read = { $count ->
    [one] { $messages } помечено как прочитанное
   *[other] { $messages } помечены как прочитанные
}
done-unread = { $count ->
    [one] { $messages } помечено как непрочитанное
   *[other] { $messages } помечены как непрочитанные
}
done-flagged = { $count ->
    [one] { $messages } помечено флажком
   *[other] { $messages } помечены флажком
}
done-unflagged = Флажок снят: { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } удалено навсегда
   *[other] { $messages } удалены навсегда
}
done-archived = { $count ->
    [one] { $messages } перемещено в архив
   *[other] { $messages } перемещены в архив
}
done-moved = { $count ->
    [one] Перемещено: { $messages }. Назначение: { $folder }
   *[other] Перемещено: { $messages }. Назначение: { $folder }
}
done-copied = { $count ->
    [one] Скопировано: { $messages }. Назначение: { $folder }
   *[other] Скопировано: { $messages }. Назначение: { $folder }
}
done-moving = { $count ->
   *[other] Перемещение: { $messages }. Назначение: { $folder }...
}
done-copying = { $count ->
   *[other] Копирование: { $messages }. Назначение: { $folder }...
}
done-moved-back = { $count ->
    [one] Возвращено: { $messages }. Назначение: { $folder }
   *[other] Возвращено: { $messages }. Назначение: { $folder }
}
done-watched = { $count ->
    [one] Отслеживается { $count } беседа
    [few] Отслеживаются { $count } беседы
    [many] Отслеживаются { $count } бесед
   *[other] Отслеживаются { $count } беседы
}
done-unwatched = { $count ->
    [one] Отслеживание прекращено: { $count } беседа
    [few] Отслеживание прекращено: { $count } беседы
    [many] Отслеживание прекращено: { $count } бесед
   *[other] Отслеживание прекращено: { $count } беседы
}
done-ignored = { $count ->
    [one] Игнорируется { $count } беседа
    [few] Игнорируются { $count } беседы
    [many] Игнорируются { $count } бесед
   *[other] Игнорируются { $count } беседы
}
done-unignored = { $count ->
    [one] Больше не игнорируется: { $count } беседа
    [few] Больше не игнорируются: { $count } беседы
    [many] Больше не игнорируются: { $count } бесед
   *[other] Больше не игнорируются: { $count } беседы
}
their-folders = их папки
undo-move = Отменить перемещение
undo-delete = Отменить удаление
undo-archive = Отменить архивирование
undo-junk = Отменить пометку «Нежелательное»
undo-not-junk = Отменить пометку «Обычное»
undo-send = Отменить отправку
nothing-to-undo = Отменять нечего.
messages-gone = Этих сообщений больше нет.
folder-holds-no-messages = В этой папке не могут храниться сообщения.
not-archived-here = Сообщения из этой папки нельзя архивировать.
not-emptied-here = Очищать можно только папки «Удаленные» и «Нежелательная почта».
next-unread-question = В папке «{ $folder }» больше нет непрочитанных сообщений.

    Перейти в следующую папку с непрочитанными сообщениями: «{ $next }»?
no-unread-left = Непрочитанных сообщений больше нет.
empty-question = { $count ->
    [one] Очистить папку «{ $folder }»?

        Будет удалено навсегда: { $messages }. Восстановление будет невозможно.
   *[other] Очистить папку «{ $folder }»?

        Будут удалены навсегда: { $messages }. Восстановление будет невозможно.
}
no-junk-folder = В этой учетной записи нет папки «Нежелательная почта», куда можно переместить сообщения.
no-inbox-folder = В этой учетной записи нет папки «Входящие», куда можно переместить сообщения.
done-flagged-color = { $messages }: { $color ->
    [red] красный флажок
    [orange] оранжевый флажок
    [yellow] желтый флажок
    [green] зеленый флажок
    [blue] синий флажок
    [purple] фиолетовый флажок
   *[gray] серый флажок
}
flag-color = { $color ->
    [red] Красный
    [orange] Оранжевый
    [yellow] Желтый
    [green] Зеленый
    [blue] Синий
    [purple] Фиолетовый
   *[gray] Серый
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Переместить { $count } сообщение
    [few] Переместить { $count } сообщения
    [many] Переместить { $count } сообщений
   *[other] Переместить { $count } сообщения
}
move-window-title-copy = { $count ->
    [one] Копировать { $count } сообщение
    [few] Копировать { $count } сообщения
    [many] Копировать { $count } сообщений
   *[other] Копировать { $count } сообщения
}
move-window-prompt-move = { $count ->
    [1] Переместить выделенное сообщение в:
   *[other] Переместить выделенные сообщения ({ $count }) в:
}
move-window-prompt-copy = { $count ->
    [1] Копировать выделенное сообщение в:
   *[other] Копировать выделенные сообщения ({ $count }) в:
}
targets-recent = Недавние
target-current = { $folder } (текущая)
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Перемещение: { $messages }, выполнено: { $done }. Назначение: { $folder }...
transfer-copying = Копирование: { $messages }, выполнено: { $done }. Назначение: { $folder }...
transfer-another-account = другая учетная запись
transfer-folder-gone = папки назначения больше нет
transfer-not-on-server = сообщения больше нет на сервере
transfer-not-moved = { $count ->
    [one] Не удалось переместить в другую учетную запись { $messages }: { $reason }
   *[other] Не удалось переместить в другую учетную запись { $messages }: { $reason }
}
transfer-not-copied = { $count ->
    [one] Не удалось скопировать в другую учетную запись { $messages }: { $reason }
   *[other] Не удалось скопировать в другую учетную запись { $messages }: { $reason }
}
transfer-none-moved = Не удалось переместить ни одного сообщения
transfer-none-copied = Не удалось скопировать ни одного сообщения

## Messages as files

export-not-in-time = сообщение не удалось загрузить вовремя
export-not-saved = Всего: { $messages }. Не удалось сохранить: { $failed } ({ $problems })
export-not-attached = не удалось вложить сообщения: { $error }
saved-to = { $count ->
    [one] { $messages } сохранено в «{ $folder }»
   *[other] { $messages } сохранены в «{ $folder }»
}
download-progress = Загрузка: { $done } из { $total }
download-done = Загружено: { $size }
downloading-messages = { $count ->
   *[other] Загрузка: { $messages }...
}
import-put = { $count ->
        [one] { $messages } добавлено в очередь импорта в папку «{ $folder }»
       *[other] { $messages } добавлены в очередь импорта в папку «{ $folder }»
    }
import-not-put = Не удалось импортировать эти файлы в папку:

    { $problems }

## Problems the windows show

error-store = локальное хранилище: { $error }
error-not-found = не найдено
error-closed = завершение работы
error-other-account = в браузере выполнен вход в { $email }, а не в эту учетную запись
failure-authentication = сервер отклонил вход ({ $reason })
failure-network = не удалось подключиться к серверу ({ $reason })
error-in-use = приложение нельзя удалить: оно используется для входа в следующие учетные записи: { $accounts }
error-turned-off = это приложение для входа отключено для новых учетных записей
error-folder-name = имя папки должно содержать от 1 до 200 символов и не может содержать управляющие символы
error-folder-separator = на этом сервере имя папки не может содержать «{ $separator }»
error-folder-special = папку «Входящие» и специальные папки нельзя переименовать или удалить
error-no-recipients = у сообщения нет получателей
error-bad-address = «{ $address }» не является адресом электронной почты
error-not-own-address = Адрес { $address } не указан среди адресов отправителя этой учетной записи. Добавьте его в поле «Другие адреса для отправки сообщений» в свойствах учетной записи.
rule-query-refused = Правила не могут отбирать сообщения по папке или дате ({ $words }).
rule-no-query = Введите условия поиска для входящих сообщений.
rule-no-action = Выберите хотя бы одно действие для правила.
error-attachment = не удалось прочитать файл «{ $path }»: { $error }
error-no-drafts = в учетной записи нет папки «Черновики», куда можно сохранить сообщение
error-draft-attachment = не удалось сохранить вложение черновика: { $error }
error-password-not-saved = не удалось сохранить пароль для следующего запуска: { $error }
error-sign-in-not-saved = не удалось сохранить новые данные для входа, необходимые при следующем запуске: { $error }
error-import-unreadable = не удается прочитать файл «{ $path }»: { $error }
error-import-too-large = размер файла «{ $path }» превышает 50 МБ
error-import-not-mail = файл «{ $path }» не является сообщением электронной почты
error-list-answered = сервер рассылки вернул код { $status }
error-not-built = не удалось сформировать сообщение
error-outbox-waits = { $count ->
    [one] В папке «Исходящие» ожидает отправки { $count } сообщение.
    [few] В папке «Исходящие» ожидают отправки { $count } сообщения.
    [many] В папке «Исходящие» ожидают отправки { $count } сообщений.
   *[other] В папке «Исходящие» ожидают отправки { $count } сообщения.
} Повторная попытка будет при следующей отправке и получении почты
error-draft-not-removed = не удалось удалить из папки «Черновики» предыдущий черновик сообщения: { $reason }
error-sent-but = сообщение отправлено, но { $problem }
error-sent-still-in-outbox = оно все еще в папке «Исходящие»: { $error }
error-sent-no-copy = не удалось сохранить копию в папке «Отправленные»: { $reason }
error-no-password = для этой учетной записи нет пароля
error-no-sign-in = для этой учетной записи не выполнен вход
error-provider-missing = в этой сборке недоступен вход через { $provider }. Возможно, приложение для входа удалено.
error-provider-servers = серверы этой учетной записи не совпадают с серверами ее приложения для входа
error-app-scopes = { $reason }. Почтовый сервер не принял токен приложения для входа: убедитесь, что запрошенные области доступа (scopes) разрешают работу с почтой
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Встроенное приложение для входа через Google настроено для тестовых пользователей и по умолчанию отключено для новых учетных записей. Используйте собственное приложение для входа через Google или пароль приложения, если учетная запись это допускает. Тестовые пользователи могут включить встроенное приложение в окне «Приложения для входа», открыв его из окна «Учетные записи».
sign-in-off-other = Приложение отключено в окне «Приложения для входа». Откройте его из окна «Учетные записи», чтобы снова включить приложение.
sign-in-app-no-name = у приложения для входа должно быть имя
sign-in-app-no-client = не указан идентификатор клиента
sign-in-app-no-scopes = для приложения нужно указать области доступа (scopes), разрешающие работу с почтой
sign-in-app-bad-host = адрес сервера { $server } не указан или не является допустимым именем узла
sign-in-app-plain = сервер { $server } должен использовать SSL/TLS или STARTTLS
sign-in-app-not-checked = сервер авторизации еще не проверен
sign-in-app-issuer-changed = адрес сервера авторизации изменился: введите секрет клиента снова или удалите его
sign-in-register-google = В Google Cloud Console создайте клиент OAuth типа Desktop app с областью доступа https://mail.google.com/ на экране согласия. Пока приложение находится в режиме тестирования, входить могут только его тестовые пользователи.
sign-in-register-microsoft = В Microsoft Entra зарегистрируйте приложение для платформы Mobile and desktop applications. Укажите URI перенаправления http://localhost, разрешите потоки авторизации для публичных клиентов и добавьте делегированные разрешения IMAP.AccessAsUser.All, SMTP.Send и offline_access. Для входа только пользователей вашей организации укажите адрес сервера авторизации https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Зарегистрируйте клиент для настольного приложения (публичный клиент) с URI перенаправления, указанным ниже. Провайдер должен разрешать для него любой порт (RFC 8252). Добавьте область доступа (scope), которую провайдер использует для работы с почтой.

## Calendar invitations

repeats = Повторение
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Каждый день
        [one] Раз в { $interval } день
        [few] Раз в { $interval } дня
        [many] Раз в { $interval } дней
       *[other] Раз в { $interval } дня
    }
    [week] { $interval ->
        [1] Каждую неделю
        [one] Раз в { $interval } неделю
        [few] Раз в { $interval } недели
        [many] Раз в { $interval } недель
       *[other] Раз в { $interval } недели
    }
    [month] { $interval ->
        [1] Каждый месяц
        [one] Раз в { $interval } месяц
        [few] Раз в { $interval } месяца
        [many] Раз в { $interval } месяцев
       *[other] Раз в { $interval } месяца
    }
   *[year] { $interval ->
        [1] Каждый год
        [one] Раз в { $interval } год
        [few] Раз в { $interval } года
        [many] Раз в { $interval } лет
       *[other] Раз в { $interval } года
    }
}
repeats-on = { $repeats }: { $days }
repeats-times = { $count ->
    [1] { $repeats }, один раз
    [one] { $repeats }, { $count } раз
    [few] { $repeats }, { $count } раза
    [many] { $repeats }, { $count } раз
   *[other] { $repeats }, { $count } раза
}
day-monday = понедельник
day-tuesday = вторник
day-wednesday = среда
day-thursday = четверг
day-friday = пятница
day-saturday = суббота
day-sunday = воскресенье

## AI agents

agent-level-read = Чтение почты: папки, список сообщений, беседы, поиск, содержимое сообщений и вложений, ваши правила для сообщений и получатели ваших сообщений
agent-level-organize = Управление почтой: отметки о прочтении, флажки и их цвета, пометка нежелательных сообщений, перемещение, архивирование, создание и переименование папок, отслеживание и игнорирование бесед, удаление в папку «Удаленные» и отписка от рассылок с вашего согласия
agent-level-drafts = Создание черновиков, которые вы сможете отправить сами
agent-level-send = Отправка сообщений с вашим подтверждением каждой отправки
agent-connect-title = { $program } запрашивает доступ к вашей почте
agent-connect-detail = ИИ-агент хочет работать с вашей почтой через Inbox Classic. Выберите разрешенные действия и доступные ему учетные записи. Позже это можно изменить в меню Сервис > ИИ-агенты.

    Письма от других людей могут содержать инструкции, рассчитанные на обман агента. Inbox Classic всегда запрашивает ваше согласие, прежде чем агент отправит сообщение.
agent-reply-to = Ответ на сообщение «{ $subject }»
agent-reply-all-on = Ответ всем на сообщение «{ $subject }»
agent-forward-of = Пересылка сообщения «{ $subject }»
agent-never-written-one = Вы никогда не писали на адрес { $address }.
agent-never-written-many = Вы никогда не писали на { $count } из этих адресов.
agent-send-title = { $program } хочет отправить это сообщение
agent-send-detail = Проверьте получателей и содержимое сообщения. После подтверждения сообщение останется в папке «Исходящие» на { $seconds } секунд. До отправки его можно удалить.
agent-change-title = Разрешения программы { $program }
agent-change-allowed = Укажите, какие действия с вашей почтой разрешены ИИ-агентам этой программы.
agent-change-refused = Вы запретили этой программе доступ. Разрешите доступ, чтобы ее агенты снова могли работать с вашей почтой.
agent-log-taken-back = { $entry } (отменено)
agent-files = Файлы: { $files }
agent-undo-refused = Это действие нельзя отменить.
agent-undo-refused-why = Это действие нельзя отменить: { $reason }.
agent-undo-impossible = это нельзя отменить
agent-undo-not-in-folder = сообщения больше нет в этой папке
agent-undo-not-arrived = сообщения пока нет в папке назначения
agent-undo-sent = сообщения больше нет в папке «Исходящие»
agent-original-not-downloaded = исходное сообщение еще не загружено. Сначала откройте его
agent-turned-away = Доступ запрещен
agent-can-nothing = Ничего
agent-can-read = чтение
agent-can-organize = управление почтой
agent-can-drafts = создание черновиков
agent-can-send = отправка с вашего согласия
agent-can-list = { $first } и { $last }
agent-accounts = { $count ->
    [0] нет учетных записей
    [one] { $count } учетная запись
    [few] { $count } учетные записи
    [many] { $count } учетных записей
   *[other] { $count } учетной записи
}
agent-access = { $can }; { $accounts }
agent-unreadable = Это сообщение невозможно прочитать.
agent-encrypted-original = Это сообщение зашифровано: агент не может ответить на него или переслать его, так как не умеет шифровать.
agent-encrypted = Это сообщение зашифровано, и агент не может прочитать его содержимое. Вы можете открыть его в Inbox Classic.
agent-too-many-changes = За последние 30 дней эта программа достигла лимита изменений, которые Inbox Classic может записать в журнал. Новые изменения станут доступны, когда самым старым записям будет 30 дней.
agent-too-many-reads = За последние 30 дней эта программа достигла лимита операций чтения, которые Inbox Classic может записать в журнал. Новые операции чтения станут доступны, когда самым старым записям будет 30 дней.
list-encrypted = Зашифрованное сообщение
agent-log-composed = Открыто новое сообщение для редактирования. Тема: «{ $subject }»
agent-log-refused = Вы не разрешили отправить сообщение «{ $subject }»
agent-log-sent = Сообщение «{ $subject }» добавлено в очередь отправки. Получатели: { $to }
agent-log-draft = Сохранен черновик «{ $subject }»
agent-log-draft-replaced = Заменен черновик «{ $subject }»
agent-log-draft-discarded = Запрошено безвозвратное удаление черновика «{ $subject }»
agent-draft-note = Этот черновик создал ИИ-агент { $program }. Проверьте получателей и текст перед отправкой.
agent-log-read = Отмечено как прочитанное: «{ $subject }»
agent-log-unread = Отмечено как непрочитанное: «{ $subject }»
agent-log-flagged = Помечено флажком: «{ $subject }»
agent-log-unflagged = Флажок снят: «{ $subject }»
agent-log-deleted = Удалено: «{ $subject }»
agent-log-moved = Сообщение «{ $subject }» перемещено в папку «{ $folder }»
agent-log-junk = «{ $subject }» помечено как нежелательное
agent-log-not-junk = Сообщение «{ $subject }» больше не помечено как нежелательное
agent-log-archived = Сообщение «{ $subject }» архивировано
agent-log-folder = Запрошено создание папки «{ $name }»
agent-log-unsubscribed = Вы одобрили запрос на отмену подписки. Сообщение: «{ $subject }»
agent-log-unsubscribe-failed = Ошибка при отписке от рассылки. Сообщение: «{ $subject }». Причина: { $reason }
agent-log-unsubscribe-refused = Вы не разрешили отписаться от рассылок. Отправители: { $senders }
agent-unsubscribe-title = { $count ->
    [1] { $program } хочет отписать вас от рассылки
    [one] { $program } хочет отписать вас от { $count } рассылки
    [few] { $program } хочет отписать вас от { $count } рассылок
    [many] { $program } хочет отписать вас от { $count } рассылок
   *[other] { $program } хочет отписать вас от { $count } рассылки
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic отправит указанной ниже рассылке запрос прекратить отправку сообщений. Для этого используется предусмотренная рассылкой отписка одним щелчком. Письма при этом не отправляются, а полученные сообщения остаются без изменений.
   *[other] Inbox Classic отправит каждой из указанных ниже рассылок запрос прекратить отправку сообщений. Для этого используется предусмотренная рассылкой отписка одним щелчком. Письма при этом не отправляются, а полученные сообщения остаются без изменений.
}
agent-log-flag-color = Помечено флажком: «{ $subject }», цвет: { $color ->
    [red] красный
    [orange] оранжевый
    [yellow] желтый
    [green] зеленый
    [blue] синий
    [purple] фиолетовый
   *[gray] серый
}
agent-log-renamed = Запрошено переименование папки «{ $old }» в «{ $name }»
agent-log-watched = Включено отслеживание беседы «{ $subject }»
agent-log-ignored = Включено игнорирование беседы «{ $subject }»
agent-log-unmarked = Отменено отслеживание или игнорирование беседы «{ $subject }»
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = сообщение с тех пор было изменено
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Помечено как прочитанное: { $count } сообщение (поиск: { $query })
    [few] Помечены как прочитанные: { $count } сообщения (поиск: { $query })
    [many] Помечены как прочитанные: { $count } сообщений (поиск: { $query })
   *[other] Помечены как прочитанные: { $count } сообщения (поиск: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Помечено как непрочитанное: { $count } сообщение (поиск: { $query })
    [few] Помечены как непрочитанные: { $count } сообщения (поиск: { $query })
    [many] Помечены как непрочитанные: { $count } сообщений (поиск: { $query })
   *[other] Помечены как непрочитанные: { $count } сообщения (поиск: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Помечено флажком: { $count } сообщение (поиск: { $query })
    [few] Помечено флажком: { $count } сообщения (поиск: { $query })
    [many] Помечено флажком: { $count } сообщений (поиск: { $query })
   *[other] Помечено флажком: { $count } сообщения (поиск: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Флажок снят: { $count } сообщение (поиск: { $query })
    [few] Флажок снят: { $count } сообщения (поиск: { $query })
    [many] Флажок снят: { $count } сообщений (поиск: { $query })
   *[other] Флажок снят: { $count } сообщения (поиск: { $query })
}
agent-log-bulk-color = { $count ->
    [one] Помечено флажком: { $count } сообщение
    [few] Помечено флажком: { $count } сообщения
    [many] Помечено флажком: { $count } сообщений
   *[other] Помечено флажком: { $count } сообщения
}, цвет: { $color ->
    [red] красный
    [orange] оранжевый
    [yellow] желтый
    [green] зеленый
    [blue] синий
    [purple] фиолетовый
   *[gray] серый
} (поиск: { $query })
agent-log-bulk-moved = { $count ->
    [one] Перемещено в папку «{ $folder }»: { $count } сообщение (поиск: { $query })
    [few] Перемещено в папку «{ $folder }»: { $count } сообщения (поиск: { $query })
    [many] Перемещено в папку «{ $folder }»: { $count } сообщений (поиск: { $query })
   *[other] Перемещено в папку «{ $folder }»: { $count } сообщения (поиск: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Архивировано: { $count } сообщение (поиск: { $query })
    [few] Архивировано: { $count } сообщения (поиск: { $query })
    [many] Архивировано: { $count } сообщений (поиск: { $query })
   *[other] Архивировано: { $count } сообщения (поиск: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Помечено как нежелательное: { $count } сообщение (поиск: { $query })
    [few] Помечены как нежелательные: { $count } сообщения (поиск: { $query })
    [many] Помечены как нежелательные: { $count } сообщений (поиск: { $query })
   *[other] Помечены как нежелательные: { $count } сообщения (поиск: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Снята пометка нежелательной почты: { $count } сообщение (поиск: { $query })
    [few] Снята пометка нежелательной почты: { $count } сообщения (поиск: { $query })
    [many] Снята пометка нежелательной почты: { $count } сообщений (поиск: { $query })
   *[other] Снята пометка нежелательной почты: { $count } сообщения (поиск: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Удалено: { $count } сообщение (поиск: { $query })
    [few] Удалено: { $count } сообщения (поиск: { $query })
    [many] Удалено: { $count } сообщений (поиск: { $query })
   *[other] Удалено: { $count } сообщения (поиск: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] За последние 15 минут
    [hour] За последний час
    [hours] За последние 4 часа
    [day] За последние 24 часа
    [week] За последние 7 дней
   *[all] За последние 30 дней
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] За это время программа «{ $program }» не внесла изменений, которые можно отменить.
    [one] Отменить { $count } изменение, внесенное программой «{ $program }» за это время?
    [few] Отменить { $count } изменения, внесенные программой «{ $program }» за это время?
    [many] Отменить { $count } изменений, внесенных программой «{ $program }» за это время?
   *[other] Отменить { $count } изменения, внесенные программой «{ $program }» за это время?
}
agent-undo-since-detail = Inbox Classic пытается вернуть сообщения в прежние папки, восстановить состояние прочтения и флажки, а также удалить сообщения, которые еще ждут в папке «Исходящие». Перед отменой проверяется состояние, относящееся к операции. Некоторые последующие изменения, например цвет флажка, все же могут быть перезаписаны.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Ничего не отменено.
    [one] Отменено { $count } изменение, полностью или частично.
    [few] Отменено { $count } изменения, полностью или частично.
    [many] Отменено { $count } изменений, полностью или частично.
   *[other] Отменено { $count } изменения, полностью или частично.
}
agent-undo-left-gone = { $count ->
    [one] { $count } сообщение уже не находится в папке, где оно было после действия агента.
    [few] { $count } сообщения уже не находятся в папке, где они были после действия агента.
    [many] { $count } сообщений уже не находятся в папке, где они были после действия агента.
   *[other] { $count } сообщения уже не находятся в папке, где они были после действия агента.
}
agent-undo-left-changed = { $count ->
    [one] { $count } сообщение с тех пор было изменено вами или на сервере и оставлено как есть.
    [few] { $count } сообщения с тех пор были изменены вами или на сервере и оставлены как есть.
    [many] { $count } сообщений с тех пор были изменены вами или на сервере и оставлены как есть.
   *[other] { $count } сообщения с тех пор были изменены вами или на сервере и оставлены как есть.
}
agent-undo-left-sent = { $count ->
    [one] { $count } сообщение уже покинуло папку «Исходящие».
    [few] { $count } сообщения уже покинули папку «Исходящие».
    [many] { $count } сообщений уже покинули папку «Исходящие».
   *[other] { $count } сообщения уже покинули папку «Исходящие».
}
agent-undo-left-impossible = { $count ->
    [one] { $count } изменение нельзя отменить.
    [few] { $count } изменения нельзя отменить.
    [many] { $count } изменений нельзя отменить.
   *[other] { $count } изменения нельзя отменить.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Ответ на приглашение «{ $summary }» ({ $when }): участие подтверждено.
    [tentative] Ответ на приглашение «{ $summary }» ({ $when }): участие под вопросом.
   *[decline] Ответ на приглашение «{ $summary }» ({ $when }): отказ от участия.
} Ответ предназначен для календаря организатора. Ваш ответ на приглашение изменится только после отправки сообщения.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Принято: { $summary }
    [tentative] Под вопросом: { $summary }
   *[decline] Отклонено: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } принимает это приглашение.
    [tentative] { $name } предварительно принимает это приглашение.
   *[decline] { $name } отклоняет это приглашение.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] прочитано { $count } сообщение
    [few] прочитано { $count } сообщения
    [many] прочитано { $count } сообщений
   *[other] прочитано { $count } сообщения
}
agent-reads-attachments = { $count ->
    [one] запрошено { $count } вложение
    [few] запрошено { $count } вложения
    [many] запрошено { $count } вложений
   *[other] запрошено { $count } вложения
}
agent-reads-searches = { $count ->
    [1] поиск выполнен один раз
    [one] поиск выполнен { $count } раз
    [few] поиск выполнен { $count } раза
    [many] поиск выполнен { $count } раз
   *[other] поиск выполнен { $count } раза
}
agent-reads-lists = { $count ->
    [1] список сообщений просмотрен один раз
    [one] списки сообщений просмотрены { $count } раз
    [few] списки сообщений просмотрены { $count } раза
    [many] списки сообщений просмотрены { $count } раз
   *[other] списки сообщений просмотрены { $count } раза
}
# each read under that row
agent-read-message = Прочитано: «{ $subject }»
agent-read-conversation = { $count ->
    [one] Прочитана беседа «{ $subject }» ({ $count } сообщение)
    [few] Прочитана беседа «{ $subject }» ({ $count } сообщения)
    [many] Прочитана беседа «{ $subject }» ({ $count } сообщений)
   *[other] Прочитана беседа «{ $subject }» ({ $count } сообщения)
}
agent-read-attachment = Запрошено вложение «{ $name }» из сообщения «{ $subject }»
agent-read-search = { $count ->
    [one] Поиск «{ $query }»: { $count } сообщение
    [few] Поиск «{ $query }»: { $count } сообщения
    [many] Поиск «{ $query }»: { $count } сообщений
   *[other] Поиск «{ $query }»: { $count } сообщения
}
agent-read-people = Поиск людей по имени или адресу: «{ $query }»
agent-read-list = { $count ->
    [one] Просмотрена { $count } запись. Список: «{ $folder }»
    [few] Просмотрены { $count } записи. Список: «{ $folder }»
    [many] Просмотрено { $count } записей. Список: «{ $folder }»
   *[other] Просмотрены { $count } записи. Список: «{ $folder }»
}
agent-read-changes = { $count ->
    [one] Просмотрена { $count } новая запись
    [few] Просмотрены { $count } новые записи
    [many] Просмотрено { $count } новых записей
   *[other] Просмотрены { $count } новые записи
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Программы, запущенные из терминала «{ $terminal }»
agent-terminal-programs-windows = Программы, запущенные из терминала ({ $terminal })
agent-terminal-programs-linux = Программы, запущенные из терминала ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Программа, запущенная из терминала «{ $terminal }»
agent-terminal-program-windows = Программа, запущенная из терминала ({ $terminal })
agent-terminal-program-linux = Программа, запущенная из терминала ({ $terminal })
agent-connect-title-terminal = { $programs } запрашивают доступ к вашей почте
agent-connect-terminal-detail = Агенты, запущенные из одной распознанной программы терминала, используют общие разрешения, которые вы выдадите здесь. Для отдельного управления агентом добавьте --name и выбранное имя в список аргументов в его настройках MCP. Имя не подтверждает, какая это программа.
agent-connect-claimed = Заявленное имя: «{ $claimed }». Inbox Classic проверила, какая программа запустила агента: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = провайдер не выдал токен обновления
sign-in-no-account = провайдер не сообщил, в какую учетную запись выполнен вход
sign-in-not-finished = вход еще не завершен
secrets-unavailable = Нет доступа к хранилищу паролей ({ $store })
secrets-unavailable-why = Нет доступа к хранилищу паролей ({ $store }): { $error }
secrets-windows = Диспетчер учетных данных
secrets-mac = Связка ключей
secrets-linux = Системная связка ключей (Secret Service)
error-no-such-file = такого файла нет
cards-file-too-big = Файл слишком большой для импорта адресной книги.
ui-sender-added = { $name }: контакт добавлен в адресную книгу.
ui-sender-known = { $name }: контакт уже есть в адресной книге.
ui-sender-none = У отправителя этого сообщения нет адреса электронной почты, который можно добавить.
card-name-needed = У контакта нет ни имени, ни адреса электронной почты.
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

otp-heading = Код от { $domain }
otp-copy = Копировать
otp-note = Вводите его только на странице сайта { $domain }.
otp-old = Код отправлен более чем за час до открытия сообщения и, вероятно, уже недействителен.

event-attendees =
    { $count ->
        [one] { $count } участник
        [few] { $count } участника
        [many] { $count } участников
       *[other] { $count } участника
    }

otp-notification = { $code }: ваш код для { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Действителен
pgp-key-expires = Действителен до { $date }
pgp-key-expired = Срок действия истек: { $date }
pgp-key-revoked = Отозван
pgp-key-revoked-why = Отозван: { $reason }
pgp-key-not-valid = Недействителен
pgp-key-locked = Нельзя открыть закрытую часть этого ключа. Проверьте доступ к хранилищу паролей ({ $store }). Если защищающий ключ утрачен, снова импортируйте резервную копию закрытого ключа.
pgp-source-own = Создан в Inbox Classic
pgp-source-file = Импортирован из файла
pgp-source-paste = Вставлен
pgp-source-attachment = Из сообщения
pgp-source-vcard = Из карточки контакта
pgp-source-wkd = От почтового провайдера отправителя
pgp-source-keyserver = С keys.openpgp.org
pgp-source-autocrypt = Из заголовка Autocrypt сообщения
pgp-error-no-store = Закрытые ключи защищены хранилищем паролей ({ $store }), которое недоступно: { $error }
pgp-error-wrong-passphrase = Неверная парольная фраза.
pgp-error-not-a-key = Это не ключ OpenPGP.
pgp-error-too-large = Ключ слишком велик.
pgp-error-unusable = Ключ нельзя использовать для этой операции. Возможно, отсутствует подходящий ключ для подписи или шифрования либо применяются неподдерживаемые криптографические алгоритмы.
pgp-imported-private = { $count ->
    [one] Импортирован { $count } закрытый ключ.
    [few] Импортировано { $count } закрытых ключа.
    [many] Импортировано { $count } закрытых ключей.
   *[other] Импортировано { $count } закрытого ключа.
}
pgp-imported-public = { $count ->
    [one] Импортирован { $count } ключ.
    [few] Импортировано { $count } ключа.
    [many] Импортировано { $count } ключей.
   *[other] Импортировано { $count } ключа.
}
pgp-imported-pending = Для следующих адресов уже используется другой ключ: { $addresses }. Новый ключ сохранен в карточке контакта и будет использоваться, когда вы его выберете.
pgp-error-needs-passphrase = Закрытый ключ защищен парольной фразой. Введите ее, чтобы импортировать ключ.
pgp-error-mismatch = Закрытый ключ не соответствует своему открытому ключу. Возможно, он был изменен.
pgp-file-name-public = { $who } открытый ключ.asc
pgp-file-name-private = { $who } резервная копия закрытого ключа.asc
pgp-pending = Обнаружен другой ключ для адреса { $address }. Дата: { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Подписано: { $signer }; владелец ключа подтвержден
pgp-part-signed = Подписано: { $signer } (владелец ключа не подтвержден)
pgp-part-other = Подписано: { $signer } (не отправитель сообщения)
pgp-part-unknown-key = Подписано, но ключ неизвестен
pgp-part-not-signed = Не подписано
pgp-part-not-checked = Подпись не проверена
pgp-part-encrypted = Зашифровано. { $signature }
pgp-part-no-key = Зашифровано для ключа, которого у вас нет
pgp-part-changed = Нарушена целостность зашифрованной части, она не показана
pgp-part-unprotected = Зашифровано без защиты от изменений, не показано
pgp-part-broken = Зашифрованную часть невозможно прочитать
pgp-why-mismatch = Подпись не соответствует этому тексту
pgp-why-weak-hash = Для подписи использован алгоритм { $hash }, который больше не считается безопасным
pgp-why-key-expired = Подпись создана после истечения срока действия ключа ({ $date })
pgp-why-key-revoked = Подписано отозванным ключом
pgp-why-not-signing-key = Подписано ключом, который не предназначен для подписи
pgp-why-from-future = Дата подписи еще не наступила
pgp-why-signature-expired = Срок действия подписи истек
pgp-why-key-not-valid = Подписано недействительным ключом
pgp-why-not-for-you = Подписано для других получателей и переслано вам
pgp-why-not-key-in-use = Ключ подписи отличается от ключа, выбранного для адреса { $address }
pgp-part-pictures-loaded = { $label }. Изображения загружены из интернета
pgp-error-no-own-key = У вас нет ключа для адреса { $address }, необходимого для подписи или шифрования сообщений. Создайте его в окне «Ключи шифрования» или отключите подпись и шифрование.
pgp-error-missing-keys = { $count ->
    [1] У получателя нет подходящего ключа для шифрования: { $addresses }.
   *[other] У этих получателей нет подходящего ключа для шифрования: { $addresses }.
}
pgp-error-encrypted-quote = Сообщение содержит текст, изображения или вложения из зашифрованного сообщения, поэтому его можно отправить только с шифрованием. Включите шифрование или удалите все это содержимое.
pgp-error-protect = Не удалось подписать или зашифровать сообщение: { $reason }
pgp-found-keys = Найдены ключи для адресов: { $addresses }.
pgp-found-none = Для адресов { $addresses } ключи не найдены. Попросите получателей прислать свои открытые ключи.
pgp-found-no-key = Ключ не найден.
pgp-find-unavailable = Сейчас не удается найти ключи: { $error }
pgp-publish-pending = Сервис keys.openpgp.org отправил ссылки для подтверждения на адреса: { $addresses }. Подтвердите каждый адрес, чтобы по нему можно было найти ваш ключ.
pgp-publish-done = Ваш ключ опубликован на keys.openpgp.org для адресов: { $addresses }.
pgp-publish-failed = Не удалось опубликовать ключ: { $error }
pgp-keyserver-off = Поиск ключей на keys.openpgp.org отключен в разделе «{ $settings }».
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [1] При отправке сообщение будет зашифровано и подписано. Прочитать содержимое сможете только вы и { $addresses }.
    [one] При отправке сообщение будет зашифровано и подписано. Прочитать содержимое сможете только вы и { $count } получатель.
    [few] При отправке сообщение будет зашифровано и подписано. Прочитать содержимое сможете только вы и { $count } получателя.
    [many] При отправке сообщение будет зашифровано и подписано. Прочитать содержимое сможете только вы и { $count } получателей.
   *[other] При отправке сообщение будет зашифровано и подписано. Прочитать содержимое сможете только вы и получатели ({ $count }).
}
pgp-compose-encrypt-ready = При отправке сообщение будет зашифровано и подписано. Добавьте получателей, чьи ключи у вас есть.
pgp-compose-missing = { $count ->
    [1] Нет подходящего ключа для получателя: { $addresses }. Сообщение пока нельзя зашифровать.
    [one] У { $count } получателя нет подходящего ключа: { $addresses }. Сообщение пока нельзя зашифровать.
    [few] У { $count } получателей нет подходящих ключей: { $addresses }. Сообщение пока нельзя зашифровать.
    [many] У { $count } получателей нет подходящих ключей: { $addresses }. Сообщение пока нельзя зашифровать.
   *[other] У { $count } получателя нет подходящего ключа: { $addresses }. Сообщение пока нельзя зашифровать.
}
pgp-compose-looking = Поиск ключей для получателей: { $addresses }...
pgp-compose-signed = При отправке сообщение будет подписано. Получатели смогут проверить, не изменилось ли его содержимое после подписания.
pgp-compose-reply-clear = Сообщение будет отправлено без шифрования, хотя исходное сообщение было зашифровано.
pgp-compose-encrypted-files = Сообщение содержит вложения из зашифрованного сообщения, поэтому его можно отправить только с шифрованием. Включите шифрование или удалите эти вложения.
pgp-compose-sign-tip = Подписать сообщение своим ключом, чтобы получатели могли проверить, не изменилось ли его содержимое после подписания
pgp-compose-sign-tip-encrypted = При отправке зашифрованное сообщение всегда подписывается цифровой подписью
pgp-compose-encrypt-tip = Зашифровать содержимое сообщения, чтобы прочитать его могли только вы и получатели
pgp-compose-make-key = Для адреса { $address } у вас пока нет собственного ключа. Создать его? Он понадобится для цифровой подписи и шифрования сообщений.
pgp-compose-key-unusable =
    Ваш ключ для адреса { $address } нельзя использовать.

    Причина: { $state }

    Откройте окно «Ключи шифрования», чтобы импортировать резервную копию этого ключа или создать новый.
pgp-compose-encrypt-off-quote = Сообщение содержит текст, изображения или вложения из зашифрованного сообщения. Отправить его без шифрования можно только после удаления этого содержимого. Все равно выключить шифрование?
pgp-compose-encrypt-off-reply = Вы отвечаете на зашифрованное сообщение или пересылаете его. Без шифрования содержимое вашего сообщения будет доступно и серверам, через которые оно проходит. Выключить шифрование?
pgp-recipient-verified = Владелец ключа подтвержден
pgp-recipient-found = Владелец ключа не подтвержден
pgp-recipient-own = Ваш собственный ключ
pgp-recipient-looking = Поиск ключа...
pgp-recipient-missing = Нет ключа
pgp-recipient-not-found = Ключ не найден. Последний поиск: { $date }
pgp-recipient-unusable = Ключ нельзя использовать: { $state }
pgp-recipients-intro = Сообщение шифруется с помощью вашего ключа и ключей всех получателей.
pgp-recipients-intro-missing = { $count ->
    [1] У одного получателя нет подходящего ключа для шифрования. Найдите его ключ, удалите получателя из сообщения или отправьте сообщение без шифрования, если в нем нет текста, изображений или вложений из зашифрованных сообщений.
    [one] У { $count } получателя нет подходящего ключа для шифрования. Найдите их ключи, удалите этих получателей из сообщения или отправьте сообщение без шифрования, если в нем нет текста, изображений или вложений из зашифрованных сообщений.
    [few] У { $count } получателей нет подходящих ключей для шифрования. Найдите их ключи, удалите этих получателей из сообщения или отправьте сообщение без шифрования, если в нем нет текста, изображений или вложений из зашифрованных сообщений.
    [many] У { $count } получателей нет подходящих ключей для шифрования. Найдите их ключи, удалите этих получателей из сообщения или отправьте сообщение без шифрования, если в нем нет текста, изображений или вложений из зашифрованных сообщений.
   *[other] У { $count } получателя нет подходящего ключа для шифрования. Найдите их ключи, удалите этих получателей из сообщения или отправьте сообщение без шифрования, если в нем нет текста, изображений или вложений из зашифрованных сообщений.
}
pgp-details-part = Часть { $number }: { $label }
attachment-from-part = Из части { $number }: { $label }
pgp-details-signed = Дата подписи: { $when }. Ключ: { $key }
pgp-details-unknown-key = Подписано ключом { $key }, которого у вас нет
pgp-details-opened = Расшифровано с помощью вашего ключа { $key }
pgp-details-for = Зашифровано для ключей: { $keys }
pgp-details-plain = Не подписано и не зашифровано
pgp-bar-parts = В этом сообщении есть части ({ $count }): { $list }. У каждой части указано, как она защищена.
pgp-bar-count-verified = с подтвержденным владельцем ключа: { $count }
pgp-bar-count-encrypted-signed = зашифровано и подписано: { $count }
pgp-bar-count-encrypted = зашифровано: { $count }
pgp-bar-count-signed = подписано: { $count }
pgp-bar-count-warning = { $count ->
   *[other] требует внимания: { $count }
}
pgp-bar-count-neutral = без подтвержденной подписи: { $count }
setup-part-settings = Настройки
setup-part-preferences = Настройки интерфейса
setup-part-accounts = Учетные записи
setup-part-sign-in-apps = Приложения для входа
setup-part-contacts = Контакты и группы
setup-part-keys = Ключи шифрования
setup-part-rules = Правила для сообщений
setup-part-trusted-senders = Надежные отправители
setup-holds-settings = { $count ->
    [one] { $count } настройка
    [few] { $count } настройки
    [many] { $count } настроек
   *[other] { $count } настройки
}
setup-holds-preferences = { $count ->
    [one] { $count } параметр интерфейса
    [few] { $count } параметра интерфейса
    [many] { $count } параметров интерфейса
   *[other] { $count } параметра интерфейса
}
setup-holds-accounts = { $count ->
    [one] { $count } учетная запись
    [few] { $count } учетные записи
    [many] { $count } учетных записей
   *[other] { $count } учетной записи
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } приложение для входа
    [few] { $count } приложения для входа
    [many] { $count } приложений для входа
   *[other] { $count } приложения для входа
}
setup-holds-built-in = Какие встроенные приложения для входа включены
setup-holds-contacts = { $count ->
    [one] { $count } контакт
    [few] { $count } контакта
    [many] { $count } контактов
   *[other] { $count } контакта
}
setup-holds-groups = { $count ->
    [one] { $count } группа
    [few] { $count } группы
    [many] { $count } групп
   *[other] { $count } группы
}
setup-holds-own-keys = { $count ->
    [one] { $count } собственный ключ
    [few] { $count } собственных ключа
    [many] { $count } собственных ключей
   *[other] { $count } собственного ключа
}
setup-holds-contact-keys = { $count ->
    [one] { $count } ключ контакта
    [few] { $count } ключа контактов
    [many] { $count } ключей контактов
   *[other] { $count } ключа контактов
}
setup-holds-rules = { $count ->
    [one] { $count } правило
    [few] { $count } правила
    [many] { $count } правил
   *[other] { $count } правила
}
setup-holds-trusted-senders = { $count ->
    [one] { $count } надежный отправитель
    [few] { $count } надежных отправителя
    [many] { $count } надежных отправителей
   *[other] { $count } надежного отправителя
}
setup-sign-in-password = Пароль
setup-account-secret-password = Ее пароль сохранен в файле.
setup-account-secret-token = Ее данные для входа сохранены в файле.
setup-account-asks-password = После импорта она запросит пароль.
setup-account-signs-in-again = После импорта в нее нужно будет войти снова.
setup-account-here = Она уже настроена здесь, поэтому будет пропущена.
setup-account-no-app = Для входа используется приложение «{ $app }», которое не настроено на этом компьютере. Импортируйте также приложения для входа.
setup-invalid-address = «{ $address }» не является адресом электронной почты.
setup-invalid-server = Некорректные параметры сервера { $server }: имя, порт или способ защиты соединения.
setup-invalid-user = У нее нет имени пользователя.
setup-invalid-sign-in = Для этой учетной записи указан неподдерживаемый способ входа или некорректные параметры авторизации.
setup-error-empty = Файл пуст.
setup-error-too-large = Превышен допустимый размер файла настроек Inbox Classic.
setup-error-not-setup = Это не файл настроек Inbox Classic.
setup-error-damaged = Файл настроек поврежден, и его невозможно прочитать.
setup-error-newer = Эти настройки сохранены более новой версией Inbox Classic ({ $version }). Обновите Inbox Classic и импортируйте их снова.
setup-error-needs-passphrase = Эти настройки защищены парольной фразой. Введите парольную фразу, с которой они были сохранены.
setup-error-wrong-passphrase = Это не та парольная фраза, с которой были сохранены настройки.
setup-error-changed = Нарушена целостность файла настроек: он изменен или поврежден, поэтому его нельзя импортировать.
setup-error-read = Не удалось прочитать файл настроек: { $error }
setup-error-write = Не удалось сохранить настройки: { $error }
setup-error-no-parts = Выберите хотя бы один раздел.
setup-left-out = { $count ->
    [one] { $count } запись из раздела «{ $part }» нельзя использовать, она пропущена.
    [few] { $count } записи из раздела «{ $part }» нельзя использовать, они пропущены.
    [many] { $count } записей из раздела «{ $part }» нельзя использовать, они пропущены.
   *[other] { $count } записи из раздела «{ $part }» нельзя использовать, они пропущены.
}
setup-imported-settings = Настройки заменены.
setup-imported-preferences = Настройки интерфейса заменены.
setup-added-accounts = { $count ->
    [one] Добавлена { $count } учетная запись.
    [few] Добавлены { $count } учетные записи.
    [many] Добавлено { $count } учетных записей.
   *[other] Добавлено { $count } учетной записи.
}
setup-skipped-here = Учетная запись «{ $address }» уже настроена на этом компьютере и пропущена при импорте.
setup-skipped-no-app = Учетная запись «{ $address }» пропущена: для входа используется приложение «{ $app }», которое не настроено на этом компьютере.
setup-skipped-invalid = Учетная запись «{ $address }» пропущена: { $reason }
setup-asks-password = При подключении учетной записи «{ $address }» потребуется ее пароль.
setup-signs-in-again = При подключении учетной записи «{ $address }» потребуется повторно войти.
setup-added-sign-in-apps = { $count ->
    [one] Добавлено { $count } приложение для входа.
    [few] Добавлено { $count } приложения для входа.
    [many] Добавлено { $count } приложений для входа.
   *[other] Добавлено { $count } приложения для входа.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } приложение для входа уже настроено здесь.
    [few] { $count } приложения для входа уже настроены здесь.
    [many] { $count } приложений для входа уже настроены здесь.
   *[other] { $count } приложения для входа уже настроены здесь.
}
setup-added-contacts = { $count ->
    [one] В адресную книгу добавлен { $count } контакт.
    [few] В адресную книгу добавлено { $count } контакта.
    [many] В адресную книгу добавлено { $count } контактов.
   *[other] В адресную книгу добавлено { $count } контакта.
}
setup-skipped-contacts = { $count ->
    [one] { $count } контакт уже есть в адресной книге.
    [few] { $count } контакта уже есть в адресной книге.
    [many] { $count } контактов уже есть в адресной книге.
   *[other] { $count } контакта уже есть в адресной книге.
}
setup-added-groups = { $count ->
    [one] Добавлена или дополнена { $count } группа.
    [few] Добавлены или дополнены { $count } группы.
    [many] Добавлено или дополнено { $count } групп.
   *[other] Добавлено или дополнено { $count } группы.
}
setup-added-own-keys = { $count ->
    [one] Добавлен { $count } собственный ключ.
    [few] Добавлено { $count } собственных ключа.
    [many] Добавлено { $count } собственных ключей.
   *[other] Добавлено { $count } собственного ключа.
}
setup-added-contact-keys = { $count ->
    [one] Добавлен { $count } ключ контакта.
    [few] Добавлено { $count } ключа контактов.
    [many] Добавлено { $count } ключей контактов.
   *[other] Добавлено { $count } ключа контактов.
}
setup-added-rules = { $count ->
    [one] Добавлено { $count } правило для сообщений.
    [few] Добавлено { $count } правила для сообщений.
    [many] Добавлено { $count } правил для сообщений.
   *[other] Добавлено { $count } правила для сообщений.
}
setup-skipped-rules = { $count ->
    [one] { $count } правило для сообщений уже есть здесь.
    [few] { $count } правила для сообщений уже есть здесь.
    [many] { $count } правил для сообщений уже есть здесь.
   *[other] { $count } правила для сообщений уже есть здесь.
}
setup-skipped-rules-account = { $count ->
    [one] { $count } правило для сообщений относится к учетной записи, которой здесь нет, поэтому оно пропущено.
    [few] { $count } правила для сообщений относятся к учетным записям, которых здесь нет, поэтому они пропущены.
    [many] { $count } правил для сообщений относятся к учетным записям, которых здесь нет, поэтому они пропущены.
   *[other] { $count } правила для сообщений относятся к учетным записям, которых здесь нет, поэтому они пропущены.
}
setup-rules-waiting = { $count ->
    [one] Для { $count } правила не найдена папка назначения. Поиск папки продолжится после синхронизации учетной записи.
    [few] Для { $count } правил не найдены папки назначения. Поиск папок продолжится после синхронизации учетных записей.
    [many] Для { $count } правил не найдены папки назначения. Поиск папок продолжится после синхронизации учетных записей.
   *[other] Для { $count } правила не найдены папки назначения. Поиск папок продолжится после синхронизации учетных записей.
}
setup-added-trusted-senders = { $count ->
    [one] Добавлен { $count } надежный отправитель.
    [few] Добавлено { $count } надежных отправителя.
    [many] Добавлено { $count } надежных отправителей.
   *[other] Добавлено { $count } надежного отправителя.
}
setup-nothing = Ничего не импортировано.
setup-account-servers = { $imap } и { $smtp } ({ $signin })
setup-file-name = Настройки и учетные записи Inbox Classic
setup-skipped-unreachable = Запись «{ $name }» пропущена: не удалось проверить службу входа. Настройте нужное приложение в окне «Приложения для входа» и повторите импорт.
attachment-runs-programs = «{ $name }» может запускать программы, поэтому Inbox Classic не открывает этот файл. Сохраните его и откройте сами, если доверяете его источнику.
attachment-decrypted-note = Это вложение из зашифрованного сообщения. Чтобы его открыть, Inbox Classic сохраняет незашифрованную копию во временной папке текущего пользователя. При запуске программа пытается удалить такие копии старше суток.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [1] Сервер не переместил { $messages } в папку «{ $folder }», поэтому оно снова в папке «{ $from }»: { $reason }
    [one] Сервер не переместил { $messages } в папку «{ $folder }», поэтому сообщения снова в папке «{ $from }»: { $reason }
   *[other] Сервер не переместил { $messages } в папку «{ $folder }», поэтому они снова в папке «{ $from }»: { $reason }
}
undone-delete = { $count ->
    [1] Сервер не удалил { $messages }, поэтому оно снова в папке «{ $from }»: { $reason }
    [one] Сервер не удалил { $messages }, поэтому сообщения снова в папке «{ $from }»: { $reason }
   *[other] Сервер не удалил { $messages }, поэтому они снова в папке «{ $from }»: { $reason }
}
undone-archive = { $count ->
    [1] Сервер не заархивировал { $messages }, поэтому оно снова в папке «{ $from }»: { $reason }
    [one] Сервер не заархивировал { $messages }, поэтому сообщения снова в папке «{ $from }»: { $reason }
   *[other] Сервер не заархивировал { $messages }, поэтому они снова в папке «{ $from }»: { $reason }
}
undone-read = { $count ->
    [1] Сервер не отметил { $messages } как прочитанное, поэтому оно снова отмечено как непрочитанное: { $reason }
    [one] Сервер не отметил { $messages } как прочитанное, поэтому сообщения снова отмечены как непрочитанные: { $reason }
   *[other] Сервер не отметил { $messages } как прочитанные, поэтому они снова отмечены как непрочитанные: { $reason }
}
undone-unread = { $count ->
    [1] Сервер не отметил { $messages } как непрочитанное, поэтому оно снова отмечено как прочитанное: { $reason }
    [one] Сервер не отметил { $messages } как непрочитанное, поэтому сообщения снова отмечены как прочитанные: { $reason }
   *[other] Сервер не отметил { $messages } как непрочитанные, поэтому они снова отмечены как прочитанные: { $reason }
}
undone-flags = { $count ->
    [one] Сервер не изменил флажки, поэтому изменение отменено ({ $messages }): { $reason }
   *[other] Сервер не изменил флажки, поэтому изменение отменено ({ $messages }): { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

preview-pdf-option = Показывать PDF-файлы в сообщениях
preview-pdf-off = PDF-файлы в сообщениях не показываются.
preview-pdf-off-crashed = Inbox Classic закрылась во время просмотра вложения. Поэтому просмотр PDF-файлов в сообщениях отключен. Изображения по-прежнему отображаются. Чтобы снова показывать PDF-файлы, включите параметр «{ $option }» в разделе «{ $settings }».
preview-pdf-details = { $count ->
    [one] { $count } страница, { $size }
    [few] { $count } страницы, { $size }
    [many] { $count } страниц, { $size }
   *[other] { $count } страницы, { $size }
}
preview-page-alt = { $name }, страница { $page } из { $count }
preview-more-pages = { $count ->
    [1] Откройте файл, чтобы просмотреть страницу
   *[other] Откройте файл, чтобы просмотреть все страницы ({ $count })
}
preview-more-files = { $count ->
    [one] Еще { $count } файл в списке выше
    [few] Еще { $count } файла в списке выше
    [many] Еще { $count } файлов в списке выше
   *[other] Еще { $count } файла в списке выше
}
preview-tile-downloading = Загрузка…
preview-tile-preparing = Подготовка…
preview-tile-format = Изображения { $format } пока не показываются
preview-tile-password = Файл защищен паролем. Откройте его, чтобы ввести пароль
preview-tile-too-large = Файл слишком большой для просмотра
preview-tile-unreadable = Не удалось отобразить файл
preview-tile-timed-out = Не удалось подготовить просмотр вовремя
preview-tile-crashed = Просмотр отключен: при предыдущей попытке Inbox Classic закрылась
preview-tile-off = Просмотр отключен до перезапуска Inbox Classic
preview-not-printed = Файл «{ $name }» ({ $details }) не включен в печать. Откройте его, чтобы напечатать.
