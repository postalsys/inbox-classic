# Русский. Черновик, ожидает проверки носителем языка (см. core/locales/GLOSSARY.md).

## Counts and sizes

# review: new
messages = { $count ->
    [one] { $count } сообщение
    [few] { $count } сообщения
    [many] { $count } сообщений
   *[other] { $count } сообщения
}
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] { $count } байт
    [few] { $count } байта
    [many] { $count } байт
   *[other] { $count } байта
}
# review: new
size-kb = { $size } КБ
# review: new
size-mb = { $size } МБ
# review: new
size-gb = { $size } ГБ
# review: new
send-delay-off = Нет
# review: new
send-delay-seconds = { $count ->
    [one] { $count } секунда
    [few] { $count } секунды
    [many] { $count } секунд
   *[other] { $count } секунды
}
# review: new
list-counts = { $messages }, непрочитанных: { $unread }
# review: new
list-counts-selected = { $messages }, непрочитанных: { $unread }, выделено: { $selected }
# review: new
list-counts-found = Найдено: { $found }, непрочитанных: { $unread }
# review: new
list-counts-found-selected = Найдено: { $found }, непрочитанных: { $unread }, выделено: { $selected }
# review: new
list-counts-none = Сообщения не найдены

## Special folders, as Outlook names them

# review: new
folder-inbox = Входящие
# review: new
folder-sent = Отправленные
# review: new
folder-deleted = Удаленные
# review: new
folder-drafts = Черновики
# review: new
folder-junk = Нежелательная почта
# review: new
folder-archive = Архив

## The reading pane

# review: new
reader-no-message = Сообщение не выбрано.
# review: new
reader-downloading = Загрузка сообщения…
# review: new
reader-downloading-detail = Сообщение появится здесь, когда загрузка завершится.
# review: new
reader-downloading-size = Размер сообщения: { $size }. Оно появится здесь после загрузки.
# review: new
reader-failed = Не удалось загрузить сообщение
# review: new
reader-failed-network = Не удалось связаться с почтовым сервером ({ $reason }).
# review: new
reader-failed-sign-in = Почтовый сервер не принял вход ({ $reason }). Проверьте пароль или войдите снова в меню Файл > Учетные записи.
# review: new
reader-failed-security = Не удалось установить защищенное соединение с почтовым сервером ({ $reason }).
# review: new
reader-failed-other = Ответ почтового сервера: { $reason }.
# review: new
reader-retry-note = Попытка повторится, когда учетная запись снова подключится.
# review: new
reader-unreadable = Это сообщение нельзя показать: { $error }
# review: new
message-source-title = Исходный текст сообщения: { $subject }
# review: new
message-source-untitled = Исходный текст сообщения

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = От
# review: new
header-date = Дата
# review: new
header-to = Кому
# review: new
header-cc = Копия
# review: new
header-sent = Отправлено
# review: new
header-subject = Тема
# review: new
header-security = Безопасность
# review: new
header-part = Часть { $number }
# review: new
quote-original = ----- Исходное сообщение -----
# review: new
fold-show-earlier = Показать предыдущие сообщения

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Ваше сообщение не доставлено
# review: new
bounce-delayed = Ваше сообщение еще не доставлено
# review: new
bounce-delayed-note = Ваш почтовый сервер продолжает попытки доставки. Отправлять сообщение повторно не нужно.
# review: new
bounce-show-message = Показать недоставленное сообщение
# review: new
bounce-show-delayed = Показать задержанное сообщение
# review: new
bounce-what-to-do = Что можно сделать:
# review: new
bounce-delayed-do = Пока ничего. Если доставить так и не удастся, придет еще одно уведомление.
# review: new
bounce-delayed-row-do = Пока ничего. Ваш почтовый сервер продолжает попытки доставки, и если они не удадутся, придет еще одно уведомление.
# review: new
bounce-details = Подробности
# review: new
bounce-someone = Получатель
# review: new
bounce-server = Сервер: { $server }
# review: new
bounce-status = Код состояния: { $status }
# review: new
bounce-reported-by = Уведомление от: { $server }
# review: new
bounce-retry-minutes = Принимающий сервер попросил подождать { $count ->
    [one] { $count } минуту
    [few] { $count } минуты
    [many] { $count } минут
   *[other] { $count } минуты
} перед следующей попыткой.
# review: new
bounce-retry-hours = Принимающий сервер попросил подождать { $count ->
    [one] { $count } час
    [few] { $count } часа
    [many] { $count } часов
   *[other] { $count } часа
} перед следующей попыткой.
# review: new
bounce-blocklist = Черный список: { $lists }
# review: new
bounce-user-unknown = Адрес не существует
# review: new
bounce-user-unknown-why = На принимающем сервере нет почтового ящика с этим адресом. Возможно, в адресе опечатка или человек им больше не пользуется.
# review: new
bounce-user-unknown-do = Проверьте написание адреса или спросите у человека, какой адрес он использует сейчас.
# review: new
bounce-invalid-address = Недопустимый адрес
# review: new
bounce-invalid-address-why = Адрес записан в форме, на которую нельзя отправить почту.
# review: new
bounce-invalid-address-do = Поищите опечатки, например пробел, пропущенную букву или пустое место после @.
# review: new
bounce-mailbox-disabled = Почтовый ящик закрыт
# review: new
bounce-mailbox-disabled-why = Адрес существует, но его почтовый ящик отключен или больше не используется.
# review: new
bounce-mailbox-disabled-do = Свяжитесь с человеком другим способом и спросите адрес, которым он пользуется сейчас.
# review: new
bounce-mailbox-full = Почтовый ящик переполнен
# review: new
bounce-mailbox-full-why = В почтовом ящике получателя нет места для новой почты.
# review: new
bounce-mailbox-full-do = Отправьте сообщение снова через несколько дней или сообщите человеку другим способом. Сообщения с большими вложениями отклоняются первыми.
# review: new
bounce-spam-blocked = Отклонено как спам
# review: new
bounce-spam-blocked-why = Принимающий сервер принял сообщение за спам.
# review: new
bounce-spam-blocked-do = Отправьте его снова без того, что похоже на спам: множества ссылок, сокращенных ссылок или большого вложения. Если это повторяется, обратитесь к своему почтовому провайдеру.
# review: new
bounce-virus-detected = Отклонено из-за вируса
# review: new
bounce-virus-detected-why = Принимающий сервер нашел вирус или другое вредоносное содержимое в сообщении или его вложениях.
# review: new
bounce-virus-detected-do = Проверьте вложения антивирусом. Некоторые серверы отклоняют любые программы и архивы, поэтому такие файлы лучше передавать ссылкой.
# review: new
bounce-ip-blocklisted = Ваш почтовый сервер в черном списке
# review: new
bounce-ip-blocklisted-why = Принимающий сервер отклоняет почту от сервера, который отправил ваше сообщение, потому что адрес этого сервера находится в черном списке.
# review: new
bounce-ip-blocklisted-do = Дело не в сообщении. Перешлите это уведомление своему почтовому провайдеру и попросите исключить сервер из списка.
# review: new
bounce-domain-blocklisted = Домен в черном списке
# review: new
bounce-domain-blocklisted-why = Принимающий сервер отклоняет сообщение, потому что домен вашего адреса или домен одной из ссылок в сообщении находится в черном списке.
# review: new
bounce-domain-blocklisted-do = Если в сообщении есть ссылки, попробуйте отправить его без них. Иначе перешлите это уведомление тому, кто обслуживает почту вашего домена.
# review: new
bounce-policy-blocked = Отклонено правилами принимающего сервера
# review: new
bounce-policy-blocked-why = Правила принимающего сервера не пропускают это сообщение, например из-за его размера, вложений или отправителя.
# review: new
bounce-policy-blocked-do = Причина часто указана в ответе сервера в разделе «Подробности». Спросите получателя, может ли он принимать такую почту.
# review: new
bounce-geo-blocked = Отклонено из-за места отправки
# review: new
bounce-geo-blocked-why = Принимающий сервер не принимает почту из страны или сети, где находится ваш почтовый сервер.
# review: new
bounce-geo-blocked-do = Свяжитесь с человеком другим способом или обратитесь к своему почтовому провайдеру.
# review: new
bounce-relay-denied = Сервер отказался передать сообщение дальше
# review: new
bounce-relay-denied-why = Сервер отказался доставлять сообщение дальше, часто потому, что оно отправлено без входа или через сервер, который не обслуживает этого получателя.
# review: new
bounce-relay-denied-do = Проверьте сервер исходящей почты учетной записи в меню Файл > Учетные записи и то, что на нем выполняется вход.
# review: new
bounce-auth-failure = Не удалось подтвердить ваш адрес отправителя
# review: new
bounce-auth-failure-why = Принимающий сервер не смог убедиться, что сообщение действительно пришло с вашего домена (SPF, DKIM или DMARC).
# review: new
bounce-auth-failure-do = Перешлите это уведомление тому, кто обслуживает почту вашего домена: его настройки нужно исправить. Пока можно попробовать отправлять через собственный сервер вашего провайдера.
# review: new
bounce-rate-limited = Слишком много почты сразу
# review: new
bounce-rate-limited-why = Принимающий сервер временно принимает меньше сообщений от вашего почтового сервера.
# review: new
bounce-rate-limited-do = Подождите немного и отправьте снова. Если пишете многим людям, отправляйте меньшему числу за раз.
# review: new
bounce-greylisting = Временно задержано
# review: new
bounce-greylisting-why = Принимающий сервер просит неизвестных отправителей повторить попытку чуть позже. Это обычная проверка против спама.
# review: new
bounce-greylisting-do = Ничего. Почтовые серверы повторяют попытку сами, и обычно сообщение доставляется в течение часа.
# review: new
bounce-server-error = Сбой на принимающем сервере
# review: new
bounce-server-error-why = С принимающим сервером не удалось связаться, или он не смог принять сообщение из-за собственной ошибки.
# review: new
bounce-server-error-do = Отправьте сообщение позже. Если ошибка повторяется, проверьте часть адреса после @ на опечатки.
# review: new
bounce-unknown = Не доставлено
# review: new
bounce-unknown-why = Уведомление не объясняет причину ясно.
# review: new
bounce-unknown-do = Больше может сказать ответ сервера в разделе «Подробности». Если он не помогает, перешлите это уведомление своему почтовому провайдеру.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] Выделено { $count } сообщение
    [few] Выделено { $count } сообщения
    [many] Выделено { $count } сообщений
   *[other] Выделено { $count } сообщения
}
# review: new
selection-unread = Непрочитанных: { $count }
# review: new
selection-flagged = С флажком: { $count }
# review: new
delete-for-good-one = Это сообщение будет удалено навсегда. Удалить его?
# review: new
delete-for-good-all = Эти сообщения ({ $count }) будут удалены навсегда. Удалить их?
# review: new
delete-for-good-some = Из { $total } сообщений { $count } будут удалены навсегда. Удалить сообщения?
# review: new
done-read = { $count ->
    [one] { $messages } отмечено как прочитанное
   *[other] { $messages } отмечены как прочитанные
}
# review: new
done-unread = { $count ->
    [one] { $messages } отмечено как непрочитанное
   *[other] { $messages } отмечены как непрочитанные
}
# review: new
done-flagged = { $count ->
    [one] { $messages } помечено флажком
   *[other] { $messages } помечены флажком
}
# review: new
done-unflagged = Флажок снят: { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] { $messages } удалено навсегда
   *[other] { $messages } удалены навсегда
}
# review: new
done-archived = { $count ->
    [one] { $messages } перемещено в архив
   *[other] { $messages } перемещены в архив
}
# review: new
done-moved = { $count ->
    [one] { $messages } перемещено в { $folder }
   *[other] { $messages } перемещены в { $folder }
}
# review: new
done-copied = { $count ->
    [one] { $messages } скопировано в { $folder }
   *[other] { $messages } скопированы в { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Перемещение в { $folder }: { $messages }...
}
# review: new
done-copying = { $count ->
   *[other] Копирование в { $folder }: { $messages }...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } возвращено в { $folder }
   *[other] { $messages } возвращены в { $folder }
}
# review: new
done-watched = { $count ->
    [one] Отслеживается { $count } беседа
    [few] Отслеживаются { $count } беседы
    [many] Отслеживаются { $count } бесед
   *[other] Отслеживаются { $count } беседы
}
# review: new
done-unwatched = { $count ->
    [one] Слежение прекращено: { $count } беседа
    [few] Слежение прекращено: { $count } беседы
    [many] Слежение прекращено: { $count } бесед
   *[other] Слежение прекращено: { $count } беседы
}
# review: new
done-ignored = { $count ->
    [one] Игнорируется { $count } беседа
    [few] Игнорируются { $count } беседы
    [many] Игнорируются { $count } бесед
   *[other] Игнорируются { $count } беседы
}
# review: new
done-unignored = { $count ->
    [one] Больше не игнорируется: { $count } беседа
    [few] Больше не игнорируются: { $count } беседы
    [many] Больше не игнорируются: { $count } бесед
   *[other] Больше не игнорируются: { $count } беседы
}
# review: new
their-folders = их папки
# review: new
undo-move = Отменить перемещение
# review: new
undo-delete = Отменить удаление
# review: new
undo-archive = Отменить архивирование
# review: new
undo-junk = Отменить пометку «Нежелательное»
# review: new
undo-not-junk = Отменить пометку «Обычное»
# review: new
undo-send = Отменить отправку
# review: new
nothing-to-undo = Отменять нечего.
# review: new
messages-gone = Этих сообщений больше нет.
# review: new
folder-holds-no-messages = В этой папке не могут храниться сообщения.
# review: new
not-archived-here = Сообщения из этой папки нельзя архивировать.
# review: new
not-emptied-here = Очищать можно только папки «Удаленные» и «Нежелательная почта».
# review: new
next-unread-question = В папке «{ $folder }» больше нет непрочитанных сообщений.

    Перейти в папку «{ $next }», следующую папку с непрочитанными сообщениями?
# review: new
no-unread-left = Непрочитанных сообщений больше нет.
# review: new
empty-question = { $count ->
    [one] Очистить папку «{ $folder }»?

        { $messages } в ней будет удалено навсегда. Восстановить его будет невозможно.
   *[other] Очистить папку «{ $folder }»?

        { $messages } в ней будут удалены навсегда. Восстановить их будет невозможно.
}
# review: new
no-junk-folder = В этой учетной записи нет папки «Нежелательная почта», куда можно переместить сообщения.
# review: new
no-inbox-folder = В этой учетной записи нет папки «Входящие», куда можно переместить сообщения.
# review: new
done-flagged-color = { $messages }: { $color ->
    [red] красный флажок
    [orange] оранжевый флажок
    [yellow] желтый флажок
    [green] зеленый флажок
    [blue] синий флажок
    [purple] фиолетовый флажок
   *[gray] серый флажок
}
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Переместить { $count } сообщение
    [few] Переместить { $count } сообщения
    [many] Переместить { $count } сообщений
   *[other] Переместить { $count } сообщения
}
# review: new
move-window-title-copy = { $count ->
    [one] Копировать { $count } сообщение
    [few] Копировать { $count } сообщения
    [many] Копировать { $count } сообщений
   *[other] Копировать { $count } сообщения
}
# review: new
move-window-prompt-move = { $count ->
    [one] Переместить выделенное сообщение ({ $count }) в:
   *[other] Переместить выделенные сообщения ({ $count }) в:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Копировать выделенное сообщение ({ $count }) в:
   *[other] Копировать выделенные сообщения ({ $count }) в:
}
# review: new
targets-recent = Недавние
# review: new
target-current = { $folder } (текущая)
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Перемещение в { $folder }: { $done } из { $messages }...
# review: new
transfer-copying = Копирование в { $folder }: { $done } из { $messages }...
# review: new
transfer-another-account = другую учетную запись
# review: new
transfer-folder-gone = папки назначения больше нет
# review: new
transfer-not-on-server = сообщения больше нет на сервере
# review: new
transfer-not-moved = { $count ->
    [one] Не удалось переместить в другую учетную запись { $messages }: { $reason }
   *[other] Не удалось переместить в другую учетную запись { $messages }: { $reason }
}
# review: new
transfer-not-copied = { $count ->
    [one] Не удалось скопировать в другую учетную запись { $messages }: { $reason }
   *[other] Не удалось скопировать в другую учетную запись { $messages }: { $reason }
}
# review: new
transfer-none-moved = Не удалось переместить ни одного сообщения
# review: new
transfer-none-copied = Не удалось скопировать ни одного сообщения

## Messages as files

# review: new
export-not-in-time = сообщение не удалось загрузить вовремя
# review: new
export-not-saved = Не удалось сохранить { $failed } из { $messages } ({ $problems })
# review: new
export-not-attached = не удалось вложить сообщения: { $error }
# review: new
saved-to = { $count ->
    [one] { $messages } сохранено в { $folder }
   *[other] { $messages } сохранены в { $folder }
}
# review: new
download-progress = Загрузка: { $done } из { $total }
# review: new
download-done = Загружено: { $size }
# review: new
downloading-messages = { $count ->
   *[other] Загрузка: { $messages }...
}
# review: new
import-put = { $count ->
    [one] { $messages } помещено в { $folder }
   *[other] { $messages } помещены в { $folder }
}
# review: new
import-not-put = Эти файлы не помещены в папку:

    { $problems }

## Problems the windows show

# review: new
error-store = локальное хранилище: { $error }
# review: new
error-not-found = не найдено
# review: new
error-closed = завершение работы
# review: new
error-other-account = в браузере выполнен вход в { $email }, а не в эту учетную запись
# review: new
failure-authentication = сервер не принял вход ({ $reason })
# review: new
failure-network = не удалось подключиться к серверу ({ $reason })
# review: new
error-in-use = его нельзя удалить, пока через него входят учетные записи: { $accounts }
# review: new
error-turned-off = это приложение для входа отключено для новых учетных записей
# review: new
error-folder-name = имя папки должно содержать от 1 до 200 символов и не может содержать управляющие символы
# review: new
error-folder-separator = на этом сервере имя папки не может содержать «{ $separator }»
# review: new
error-folder-special = папку «Входящие» и специальные папки нельзя переименовать или удалить
# review: new
error-no-recipients = у сообщения нет получателей
# review: new
error-bad-address = «{ $address }» не является адресом электронной почты
# review: new
error-not-own-address = { $address } не входит в адреса отправителя этой учетной записи. Добавьте его в поле «Другие адреса, с которых вы отправляете» в свойствах учетной записи.
# review: new
rule-query-refused = Правила не могут отбирать сообщения по папке или дате ({ $words }).
# review: new
rule-no-query = Введите условия поиска для входящих сообщений.
# review: new
rule-no-action = Выберите хотя бы одно действие для правила.
# review: new
error-attachment = не удалось прочитать { $path }: { $error }
# review: new
error-no-drafts = в учетной записи нет папки «Черновики», чтобы сохранить сообщение
# review: new
error-draft-attachment = не удалось сохранить вложение черновика: { $error }
# review: new
error-password-not-saved = не удалось сохранить пароль для следующего запуска: { $error }
# review: new
error-sign-in-not-saved = не удалось сохранить новые данные для входа для следующего запуска: { $error }
# review: new
error-import-unreadable = не удается прочитать { $path }: { $error }
# review: new
error-import-too-large = { $path } больше 50 МБ
# review: new
error-import-not-mail = { $path } не является сообщением электронной почты
# review: new
error-list-answered = сервер списка рассылки вернул код { $status }
# review: new
error-not-built = не удалось сформировать сообщение
# review: new
error-outbox-waits = { $count ->
    [one] сообщения в папке «Исходящие» ({ $count }) будут отправлены при следующей отправке и получении почты
   *[other] сообщения в папке «Исходящие» ({ $count }) будут отправлены при следующей отправке и получении почты
}
# review: new
error-draft-not-removed = не удалось удалить из папки «Черновики» предыдущий черновик сообщения: { $reason }
# review: new
error-sent-but = сообщение отправлено, но { $problem }
# review: new
error-sent-still-in-outbox = оно все еще в папке «Исходящие»: { $error }
# review: new
error-sent-no-copy = не удалось сохранить копию в папке «Отправленные»: { $reason }
# review: new
error-no-password = для этой учетной записи нет пароля
# review: new
error-no-sign-in = для этой учетной записи не выполнен вход
# review: new
error-provider-missing = эта сборка не может выполнить вход в { $provider }: возможно, его приложение для входа удалено?
# review: new
error-provider-servers = серверы этой учетной записи не совпадают с серверами ее приложения для входа
# review: new
error-app-scopes = { $reason }. Почтовый сервер не принял токен приложения для входа: проверьте, что области доступа приложения дают доступ к почте
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google еще не проверил Inbox Classic, поэтому разрешает входить через него только тестовым пользователям. Используйте собственное приложение для входа Google или пароль приложения, либо включите его в окне «Приложения для входа» (Файл > Учетные записи), если вы тестовый пользователь.
# review: new
sign-in-off-other = Оно отключено в окне «Приложения для входа» (Файл > Учетные записи), где его можно снова включить.
# review: new
sign-in-app-no-name = у приложения для входа должно быть имя
# review: new
sign-in-app-no-client = не указан идентификатор клиента
# review: new
sign-in-app-no-scopes = приложению для входа нужны области доступа, дающие доступ к почте
# review: new
sign-in-app-bad-host = адрес сервера { $server } не указан или не является допустимым именем узла
# review: new
sign-in-app-plain = сервер { $server } должен использовать SSL/TLS или STARTTLS
# review: new
sign-in-app-not-checked = издатель еще не проверен
# review: new
sign-in-app-issuer-changed = издатель изменился: введите секрет клиента снова или удалите его
# review: new
sign-in-register-google = В Google Cloud Console создайте клиент OAuth типа Desktop app с областью доступа https://mail.google.com/ на экране согласия. Пока приложение находится в режиме тестирования, входить могут только его тестовые пользователи.
# review: new
sign-in-register-microsoft = В Microsoft Entra зарегистрируйте приложение с платформой Mobile and desktop applications, URI перенаправления http://localhost, разрешенными потоками общедоступного клиента и делегированными разрешениями IMAP.AccessAsUser.All, SMTP.Send и offline_access. Только для своей организации укажите издателем https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Зарегистрируйте собственный (общедоступный) клиент с URI перенаправления, указанным ниже; провайдер должен разрешать для него любой порт (RFC 8252). Добавьте область доступа, через которую провайдер дает доступ к почте.

## Calendar invitations

# review: new
repeats = Повторение
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [1] Каждый день
        [one] Каждый { $interval } день
        [few] Каждые { $interval } дня
        [many] Каждые { $interval } дней
       *[other] Каждые { $interval } дня
    }
    [week] { $interval ->
        [1] Каждую неделю
        [one] Каждую { $interval } неделю
        [few] Каждые { $interval } недели
        [many] Каждые { $interval } недель
       *[other] Каждые { $interval } недели
    }
    [month] { $interval ->
        [1] Каждый месяц
        [one] Каждый { $interval } месяц
        [few] Каждые { $interval } месяца
        [many] Каждые { $interval } месяцев
       *[other] Каждые { $interval } месяца
    }
   *[year] { $interval ->
        [1] Каждый год
        [one] Каждый { $interval } год
        [few] Каждые { $interval } года
        [many] Каждые { $interval } лет
       *[other] Каждые { $interval } года
    }
}
# review: new
repeats-on = { $repeats }: { $days }
# review: new
repeats-times = { $count ->
    [1] { $repeats }, один раз
    [one] { $repeats }, { $count } раз
    [few] { $repeats }, { $count } раза
    [many] { $repeats }, { $count } раз
   *[other] { $repeats }, { $count } раза
}
# review: new
day-monday = понедельник
# review: new
day-tuesday = вторник
# review: new
day-wednesday = среда
# review: new
day-thursday = четверг
# review: new
day-friday = пятница
# review: new
day-saturday = суббота
# review: new
day-sunday = воскресенье

## AI agents

# review: new
agent-level-read = Чтение почты: папки, список сообщений, поиск и сообщения
# review: changed
agent-level-organize = Упорядочивание почты: прочитанность, флажки, нежелательная почта, перемещение, архивирование, новые папки, удаление в папку «Удаленные» и отписка от рассылок после вашего согласия
# review: new
agent-level-drafts = Создание черновиков, которые отправляете вы
# review: new
agent-level-send = Отправка почты, каждого сообщения только после вашего согласия
# review: new
agent-connect-title = { $program } запрашивает доступ к вашей почте
# review: new
agent-connect-detail = ИИ-агент запросил разрешение на работу с Inbox Classic. Выберите, что ему разрешено и какие учетные записи он может видеть; позже это можно изменить в меню Сервис > ИИ-агенты.

    Агенты читают почту, написанную другими людьми, и сообщение может попытаться их обмануть. Inbox Classic всегда спрашивает вас, прежде чем агент что-либо отправит.
# review: new
agent-reply-to = Ответ на «{ $subject }»
# review: new
agent-reply-all-on = Ответ всем на «{ $subject }»
# review: new
agent-forward-of = Пересылка «{ $subject }»
# review: new
agent-never-written-one = Вы никогда не писали на адрес { $address }.
# review: new
agent-never-written-many = На некоторые из этих адресов ({ $count }) вы никогда не писали.
# review: new
agent-send-title = { $program } хочет отправить это сообщение
# review: new
agent-send-detail = Проверьте получателей и содержимое сообщения. После подтверждения сообщение будет ждать в папке «Исходящие» { $seconds } с., и его еще можно будет удалить.
# review: new
agent-change-title = Разрешения программы { $program }
# review: new
agent-change-allowed = Измените, что ИИ-агентам этой программы разрешено делать с вашей почтой.
# review: new
agent-change-refused = Вы запретили этой программе доступ. Разрешите его, чтобы снова дать ее агентам доступ к вашей почте.
# review: new
agent-log-taken-back = { $entry } (отменено)
# review: new
agent-files = Файлы: { $files }
# review: new
agent-undo-refused = Это нельзя отменить.
# review: new
agent-undo-refused-why = Это нельзя отменить: { $reason }.
# review: new
agent-undo-impossible = это нельзя отменить
# review: new
agent-undo-not-in-folder = сообщения больше нет в этой папке
# review: new
agent-undo-not-arrived = сообщения нет (пока) в папке, куда оно перемещено
# review: new
agent-undo-sent = сообщение уже отправлено
# review: new
agent-original-not-downloaded = исходное сообщение еще не загружено. Сначала откройте его
# review: new
agent-turned-away = Отклонено
# review: new
agent-can-nothing = Ничего
# review: new
agent-can-read = чтение
# review: new
agent-can-organize = упорядочивание
# review: new
agent-can-drafts = создание черновиков
# review: new
agent-can-send = отправка с вашего согласия
# review: new
agent-can-list = { $first } и { $last }
# review: new
agent-accounts = { $count ->
    [0] нет учетных записей
    [one] { $count } учетная запись
    [few] { $count } учетные записи
    [many] { $count } учетных записей
   *[other] { $count } учетной записи
}
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Это сообщение невозможно прочитать.
# review: new
agent-encrypted-original = Это сообщение зашифровано: агент не может ответить на него или переслать его, так как не умеет шифровать.
# review: new
agent-encrypted = Это сообщение зашифровано. Прочитать его может только пользователь, в Inbox Classic.
# review: new
list-encrypted = Зашифрованное сообщение
# review: new
agent-log-composed = «{ $subject }» открыто в новом сообщении, чтобы вы его закончили
# review: new
agent-log-refused = Вы не отправили «{ $subject }»
# review: new
agent-log-sent = «{ $subject }» отправлено: { $to }
# review: new
agent-log-draft = Сохранен черновик «{ $subject }»
# review: new
agent-log-read = Отмечено как прочитанное: «{ $subject }»
# review: new
agent-log-unread = Отмечено как непрочитанное: «{ $subject }»
# review: new
agent-log-flagged = Помечено флажком: «{ $subject }»
# review: new
agent-log-unflagged = Флажок снят: «{ $subject }»
# review: new
agent-log-deleted = Удалено: «{ $subject }»
# review: new
agent-log-moved = «{ $subject }» перемещено в { $folder }
# review: new
agent-log-junk = «{ $subject }» помечено как нежелательное
# review: new
agent-log-not-junk = «{ $subject }» помечено как обычное
# review: new
agent-log-archived = В архиве: «{ $subject }»
# review: new
agent-log-folder = Создана папка «{ $name }»
# review: new
agent-log-unsubscribed = Отменена подписка на рассылку «{ $subject }»
# review: new
agent-log-unsubscribe-failed = Не удалось отписаться от рассылки «{ $subject }»: { $reason }
# review: new
agent-log-unsubscribe-refused = Вы не стали отписываться от рассылок: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [1] { $program } хочет отписать вас от рассылки
    [one] { $program } хочет отписать вас от { $count } рассылки
    [few] { $program } хочет отписать вас от { $count } рассылок
    [many] { $program } хочет отписать вас от { $count } рассылок
   *[other] { $program } хочет отписать вас от { $count } рассылки
}
# review: new
agent-unsubscribe-detail = Inbox Classic попросит каждую рассылку ниже больше не присылать вам писем, используя отписку в один щелчок, которую предлагает рассылка. Больше ничего не отправляется, а ваши сообщения остаются на своих местах.

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
sign-in-no-refresh = провайдер не выдал токен обновления
# review: new
sign-in-no-account = провайдер не сообщил, в какую учетную запись выполнен вход
# review: new
sign-in-not-finished = вход еще не завершен
# review: new
secrets-unavailable = Нет доступа к хранилищу паролей ({ $store })
# review: new
secrets-unavailable-why = Нет доступа к хранилищу паролей ({ $store }): { $error }
# review: new
secrets-windows = Диспетчер учетных данных
# review: new
secrets-mac = Связка ключей
# review: new
secrets-linux = Системная связка ключей (Secret Service)
# review: new
error-no-such-file = такого файла нет
# review: new
cards-file-too-big = Этот файл слишком велик для адресной книги.
# review: new
ui-sender-added = { $name }: контакт добавлен в адресную книгу.
# review: new
ui-sender-known = { $name }: контакт уже есть в адресной книге.
# review: new
ui-sender-none = У отправителя этого сообщения нет адреса электронной почты, который можно добавить.
# review: new
card-name-needed = У контакта нет ни имени, ни адреса электронной почты.
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# review: new
otp-heading = Код от { $domain }
# review: new
otp-copy = Копировать
# review: new
otp-note = Вводите его только на странице { $domain }.
# review: new
otp-old = Этот код был отправлен больше чем за час до того, как вы его открыли, и, вероятно, уже недействителен.

# review: new
event-attendees =
    { $count ->
        [one] { $count } участник
        [few] { $count } участника
        [many] { $count } участников
       *[other] { $count } участника
    }

# review: new
otp-notification = { $code }: ваш код для { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Действителен
# review: new
pgp-key-expires = Действителен до { $date }
# review: new
pgp-key-expired = Истек { $date }
# review: new
pgp-key-revoked = Отозван
# review: new
pgp-key-revoked-why = Отозван: { $reason }
# review: new
pgp-key-not-valid = Недействителен
# review: new
pgp-key-locked = Нельзя использовать: ключа, который его защищает, больше нет в хранилище паролей ({ $store }). Импортируйте резервную копию снова.
# review: new
pgp-source-own = Создан в Inbox Classic
# review: new
pgp-source-file = Импортирован из файла
# review: new
pgp-source-paste = Вставлен
# review: new
pgp-source-attachment = Из сообщения
# review: new
pgp-source-vcard = Из карточки контакта
# review: new
pgp-source-wkd = От почтового провайдера отправителя
# review: new
pgp-source-keyserver = С keys.openpgp.org
# review: new
pgp-source-autocrypt = Из заголовка Autocrypt сообщения
# review: new
pgp-error-no-store = Закрытые ключи защищены хранилищем паролей ({ $store }), которое недоступно: { $error }
# review: new
pgp-error-wrong-passphrase = Неверная парольная фраза.
# review: new
pgp-error-not-a-key = Это не ключ OpenPGP.
# review: new
pgp-error-too-large = Ключ слишком велик.
# review: new
pgp-error-unusable = Ключ использует устаревшую или слабую криптографию, и его нельзя использовать.
# review: new
pgp-imported-private = { $count ->
    [one] Импортирован { $count } закрытый ключ.
    [few] Импортировано { $count } закрытых ключа.
    [many] Импортировано { $count } закрытых ключей.
   *[other] Импортировано { $count } закрытого ключа.
}
# review: new
pgp-imported-public = { $count ->
    [one] Импортирован { $count } ключ.
    [few] Импортировано { $count } ключа.
    [many] Импортировано { $count } ключей.
   *[other] Импортировано { $count } ключа.
}
# review: new
pgp-imported-pending = Для { $addresses } уже используется другой ключ: новый будет ждать в контакте, пока вы его не выберете.
# review: new
pgp-error-needs-passphrase = Закрытый ключ защищен парольной фразой. Введите ее, чтобы импортировать ключ.
# review: new
pgp-error-mismatch = Закрытый ключ не соответствует своему открытому ключу. Возможно, он был изменен.
# review: new
pgp-file-name-public = { $who } открытый ключ.asc
# review: new
pgp-file-name-private = { $who } резервная копия закрытого ключа.asc
# review: new
pgp-pending = Для { $address } { $date } найден другой ключ.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Подписано: { $signer }, ключ проверен
# review: new
pgp-part-signed = Подписано: { $signer } (ключ не проверен)
# review: new
pgp-part-other = Подписано: { $signer }, это не отправитель
# review: new
pgp-part-unknown-key = Подписано, но ключ неизвестен
# review: new
pgp-part-not-signed = Не подписано
# review: new
pgp-part-not-checked = Подпись не проверена
# review: new
pgp-part-encrypted = Зашифровано. { $signature }
# review: new
pgp-part-no-key = Зашифровано для ключа, которого у вас нет
# review: new
pgp-part-changed = Зашифрованная часть была изменена при передаче и не показана
# review: new
pgp-part-unprotected = Зашифровано без защиты от изменений, не показано
# review: new
pgp-part-broken = Зашифрованную часть невозможно прочитать
# review: new
pgp-why-mismatch = Подпись не соответствует этому тексту
# review: new
pgp-why-weak-hash = Подпись использует { $hash }, это больше не безопасно
# review: new
pgp-why-key-expired = Подписано после истечения срока ключа { $date }
# review: new
pgp-why-key-revoked = Подписано отозванным ключом
# review: new
pgp-why-not-signing-key = Подписано ключом, который не предназначен для подписи
# review: new
pgp-why-from-future = Подпись датирована будущим
# review: new
pgp-why-signature-expired = Срок действия подписи истек
# review: new
pgp-why-key-not-valid = Подписано недействительным ключом
# review: new
pgp-why-not-for-you = Подписано для других получателей и переслано вам
# review: new
pgp-why-not-key-in-use = Подписано другим ключом, а не тем, что используется для { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Изображения загружены из интернета
# review: new
pgp-error-no-own-key = У вас нет ключа для { $address }, чтобы подписывать или шифровать. Создайте его в меню Сервис > Ключи шифрования или выключите подпись и шифрование.
# review: new
pgp-error-missing-keys = { $count ->
    [one] У { $addresses } нет ключа для шифрования.
   *[other] У этих получателей нет ключа для шифрования: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Это сообщение цитирует или пересылает зашифрованное сообщение, поэтому его можно отправить только зашифрованным. Включите шифрование или удалите цитируемый текст.
# review: new
pgp-error-protect = Не удалось подписать или зашифровать сообщение: { $reason }
# review: new
pgp-found-keys = Найден ключ: { $addresses }.
# review: new
pgp-found-none = Ключ для { $addresses } не найден. Попросите прислать вам открытый ключ.
# review: new
pgp-found-no-key = Ключ не найден.
# review: new
pgp-find-unavailable = Сейчас не удается найти ключи: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org отправил ссылку для подтверждения на { $addresses }. Ваш ключ будет опубликован там, когда вы по ней перейдете.
# review: new
pgp-publish-done = Ваш ключ опубликован на keys.openpgp.org для { $addresses }.
# review: new
pgp-publish-failed = Не удалось опубликовать ключ: { $error }
# review: changed
pgp-keyserver-off = Поиск ключей на keys.openpgp.org выключен в разделе { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [1] Зашифровано и подписано: прочитать его можете только вы и { $addresses }.
    [one] Зашифровано и подписано: прочитать его можете только вы и его { $count } получатель.
    [few] Зашифровано и подписано: прочитать его можете только вы и его { $count } получателя.
    [many] Зашифровано и подписано: прочитать его можете только вы и его { $count } получателей.
   *[other] Зашифровано и подписано: прочитать его можете только вы и его получатели ({ $count }).
}
# review: new
pgp-compose-encrypt-ready = Сообщение будет зашифровано и подписано. Добавьте получателей, ключи которых у вас есть.
# review: new
pgp-compose-missing = { $count ->
    [1] У { $addresses } нет ключа, поэтому сообщение пока нельзя зашифровать.
    [one] У { $count } получателя нет ключа, поэтому сообщение пока нельзя зашифровать: { $addresses }.
    [few] У { $count } получателей нет ключа, поэтому сообщение пока нельзя зашифровать: { $addresses }.
    [many] У { $count } получателей нет ключа, поэтому сообщение пока нельзя зашифровать: { $addresses }.
   *[other] У { $count } получателя нет ключа, поэтому сообщение пока нельзя зашифровать: { $addresses }.
}
# review: new
pgp-compose-looking = Поиск ключей для { $addresses }...
# review: new
pgp-compose-signed = Подписано: получатели смогут проверить, что сообщение от вас и не было изменено.
# review: new
pgp-compose-reply-clear = Не зашифровано, хотя сообщение, на которое вы отвечаете или которое пересылаете, было зашифровано.
# review: new
pgp-compose-encrypted-files = Вложены файлы зашифрованного сообщения, поэтому это сообщение можно отправить только зашифрованным. Включите шифрование или удалите эти файлы.
# review: new
pgp-compose-sign-tip = Подписать сообщение своим ключом, чтобы получатели могли проверить, что оно от вас и не было изменено
# review: new
pgp-compose-sign-tip-encrypted = Зашифрованное сообщение всегда подписывается
# review: new
pgp-compose-encrypt-tip = Зашифровать сообщение, чтобы прочитать его могли только вы и его получатели
# review: new
pgp-compose-make-key = У вас пока нет ключа для { $address }. Создать его сейчас? С ним ваши сообщения можно будет подписывать и шифровать.
# review: new
pgp-compose-key-unusable = Ваш ключ для { $address } нельзя использовать ({ $state }). Откройте «Ключи шифрования», чтобы импортировать его резервную копию или создать новый ключ.
# review: new
pgp-compose-encrypt-off-quote = Это сообщение цитирует или пересылает зашифрованное сообщение. Без шифрования его нельзя будет отправить, пока вы не удалите цитируемый текст. Все равно выключить шифрование?
# review: new
pgp-compose-encrypt-off-reply = Это сообщение отвечает на зашифрованное сообщение или пересылает его. Без шифрования ваше сообщение сможет прочитать любой, через кого оно пройдет по пути. Выключить шифрование?
# review: new
pgp-recipient-verified = Ключ проверен
# review: new
pgp-recipient-found = Ключ не проверен
# review: new
pgp-recipient-own = Ваш собственный ключ
# review: new
pgp-recipient-looking = Поиск ключа...
# review: new
pgp-recipient-missing = Нет ключа
# review: new
pgp-recipient-not-found = Нет ключа: не найден { $date }
# review: new
pgp-recipient-unusable = Ключ нельзя использовать: { $state }
# review: new
pgp-recipients-intro = Сообщение шифруется для ключа каждого получателя и для вашего.
# review: new
pgp-recipients-intro-missing = { $count ->
    [1] У одного получателя нет ключа для шифрования. Найдите его ключ, удалите его из этого сообщения или отправьте сообщение без шифрования.
    [one] У { $count } получателя нет ключа для шифрования. Найдите их ключи, удалите их из этого сообщения или отправьте сообщение без шифрования.
    [few] У { $count } получателей нет ключа для шифрования. Найдите их ключи, удалите их из этого сообщения или отправьте сообщение без шифрования.
    [many] У { $count } получателей нет ключа для шифрования. Найдите их ключи, удалите их из этого сообщения или отправьте сообщение без шифрования.
   *[other] У { $count } получателя нет ключа для шифрования. Найдите их ключи, удалите их из этого сообщения или отправьте сообщение без шифрования.
}
# review: new
pgp-details-part = Часть { $number }: { $label }
# review: new
pgp-details-signed = Подписано { $when } ключом { $key }
# review: new
pgp-details-unknown-key = Подписано ключом { $key }, которого у вас нет
# review: new
pgp-details-opened = Зашифровано для вашего ключа { $key }
# review: new
pgp-details-for = Зашифровано для { $keys }
# review: new
pgp-details-plain = Не подписано и не зашифровано
# review: new
pgp-bar-parts = В этом сообщении есть части ({ $count }): { $list }. У каждой части указано, как она защищена.
# review: new
pgp-bar-count-verified = проверено: { $count }
# review: new
pgp-bar-count-good = { $count ->
   *[other] подписано или зашифровано: { $count }
}
# review: new
pgp-bar-count-warning = { $count ->
   *[other] требует внимания: { $count }
}
# review: new
pgp-bar-count-neutral = без подтвержденной подписи: { $count }
# review: new
setup-part-settings = Настройки
# review: new
setup-part-preferences = Настройки окон
# review: new
setup-part-accounts = Учетные записи
# review: new
setup-part-sign-in-apps = Приложения для входа
# review: new
setup-part-contacts = Контакты и группы
# review: new
setup-part-keys = Ключи шифрования
# review: new
setup-part-rules = Правила для сообщений
# review: new
setup-part-trusted-senders = Надежные отправители
# review: new
setup-holds-settings = { $count ->
    [one] { $count } настройка
    [few] { $count } настройки
    [many] { $count } настроек
   *[other] { $count } настройки
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } параметр окон
    [few] { $count } параметра окон
    [many] { $count } параметров окон
   *[other] { $count } параметра окон
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } учетная запись
    [few] { $count } учетные записи
    [many] { $count } учетных записей
   *[other] { $count } учетной записи
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } приложение для входа
    [few] { $count } приложения для входа
    [many] { $count } приложений для входа
   *[other] { $count } приложения для входа
}
# review: new
setup-holds-built-in = Какие встроенные приложения для входа включены
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } контакт
    [few] { $count } контакта
    [many] { $count } контактов
   *[other] { $count } контакта
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } группа
    [few] { $count } группы
    [many] { $count } групп
   *[other] { $count } группы
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } ваш ключ
    [few] { $count } ваших ключа
    [many] { $count } ваших ключей
   *[other] { $count } вашего ключа
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } ключ контакта
    [few] { $count } ключа контактов
    [many] { $count } ключей контактов
   *[other] { $count } ключа контактов
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
    [one] { $count } надежный отправитель
    [few] { $count } надежных отправителя
    [many] { $count } надежных отправителей
   *[other] { $count } надежного отправителя
}
# review: new
setup-sign-in-password = Пароль
# review: new
setup-account-secret-password = Ее пароль сохранен в файле.
# review: new
setup-account-secret-token = Ее данные для входа сохранены в файле.
# review: new
setup-account-asks-password = После импорта она запросит пароль.
# review: new
setup-account-signs-in-again = После импорта в нее нужно будет войти снова.
# review: new
setup-account-here = Она уже настроена здесь, поэтому будет пропущена.
# review: new
setup-account-no-app = Она входит через { $app }, а это приложение здесь не настроено. Импортируйте и приложения для входа.
# review: new
setup-invalid-address = «{ $address }» не является адресом электронной почты.
# review: new
setup-invalid-server = У сервера { $server } нет пригодного имени или порта.
# review: new
setup-invalid-user = У нее нет имени пользователя.
# review: new
setup-invalid-sign-in = Она использует способ входа, неизвестный Inbox Classic.
# review: new
setup-error-empty = Файл пуст.
# review: new
setup-error-too-large = Файл слишком велик для файла настроек Inbox Classic.
# review: new
setup-error-not-setup = Это не файл настроек Inbox Classic.
# review: new
setup-error-damaged = Файл настроек поврежден, и его невозможно прочитать.
# review: new
setup-error-newer = Эти настройки сохранены более новой версией Inbox Classic ({ $version }). Обновите Inbox Classic и импортируйте их снова.
# review: new
setup-error-needs-passphrase = Эти настройки защищены парольной фразой. Введите парольную фразу, с которой они были сохранены.
# review: new
setup-error-wrong-passphrase = Это не та парольная фраза, с которой были сохранены настройки.
# review: new
setup-error-changed = Файл настроек был изменен или поврежден после сохранения, поэтому его нельзя импортировать.
# review: new
setup-error-read = Не удалось прочитать файл настроек: { $error }
# review: new
setup-error-write = Не удалось сохранить настройки: { $error }
# review: new
setup-error-no-parts = Выберите хотя бы одну часть.
# review: new
setup-left-out = { $count ->
    [one] { $count } запись из раздела «{ $part }» нельзя использовать, она пропущена.
    [few] { $count } записи из раздела «{ $part }» нельзя использовать, они пропущены.
    [many] { $count } записей из раздела «{ $part }» нельзя использовать, они пропущены.
   *[other] { $count } записи из раздела «{ $part }» нельзя использовать, они пропущены.
}
# review: new
setup-imported-settings = Настройки заменены.
# review: new
setup-imported-preferences = Настройки окон заменены.
# review: new
setup-added-accounts = { $count ->
    [one] Добавлена { $count } учетная запись.
    [few] Добавлено { $count } учетные записи.
    [many] Добавлено { $count } учетных записей.
   *[other] Добавлено { $count } учетной записи.
}
# review: new
setup-skipped-here = { $address } уже настроена здесь, поэтому пропущена.
# review: new
setup-skipped-no-app = { $address } пропущена: она входит через { $app }, а это приложение здесь не настроено.
# review: new
setup-skipped-invalid = { $address } пропущена: { $reason }
# review: new
setup-asks-password = { $address } запросит пароль при подключении.
# review: new
setup-signs-in-again = { $address } попросит войти снова при подключении.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Добавлено { $count } приложение для входа.
    [few] Добавлено { $count } приложения для входа.
    [many] Добавлено { $count } приложений для входа.
   *[other] Добавлено { $count } приложения для входа.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } приложение для входа уже настроено здесь.
    [few] { $count } приложения для входа уже настроены здесь.
    [many] { $count } приложений для входа уже настроены здесь.
   *[other] { $count } приложения для входа уже настроены здесь.
}
# review: new
setup-added-contacts = { $count ->
    [one] В адресную книгу добавлен { $count } контакт.
    [few] В адресную книгу добавлено { $count } контакта.
    [many] В адресную книгу добавлено { $count } контактов.
   *[other] В адресную книгу добавлено { $count } контакта.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } контакт уже есть в адресной книге.
    [few] { $count } контакта уже есть в адресной книге.
    [many] { $count } контактов уже есть в адресной книге.
   *[other] { $count } контакта уже есть в адресной книге.
}
# review: new
setup-added-groups = { $count ->
    [one] Добавлена или дополнена { $count } группа.
    [few] Добавлено или дополнено { $count } группы.
    [many] Добавлено или дополнено { $count } групп.
   *[other] Добавлено или дополнено { $count } группы.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Добавлен { $count } ваш ключ.
    [few] Добавлено { $count } ваших ключа.
    [many] Добавлено { $count } ваших ключей.
   *[other] Добавлено { $count } вашего ключа.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Добавлен { $count } ключ контакта.
    [few] Добавлено { $count } ключа контактов.
    [many] Добавлено { $count } ключей контактов.
   *[other] Добавлено { $count } ключа контактов.
}
# review: new
setup-added-rules = { $count ->
    [one] Добавлено { $count } правило для сообщений.
    [few] Добавлено { $count } правила для сообщений.
    [many] Добавлено { $count } правил для сообщений.
   *[other] Добавлено { $count } правила для сообщений.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } правило для сообщений уже есть здесь.
    [few] { $count } правила для сообщений уже есть здесь.
    [many] { $count } правил для сообщений уже есть здесь.
   *[other] { $count } правила для сообщений уже есть здесь.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } правило для сообщений относится к учетной записи, которой здесь нет, поэтому оно пропущено.
    [few] { $count } правила для сообщений относятся к учетным записям, которых здесь нет, поэтому они пропущены.
    [many] { $count } правил для сообщений относятся к учетным записям, которых здесь нет, поэтому они пропущены.
   *[other] { $count } правила для сообщений относятся к учетным записям, которых здесь нет, поэтому они пропущены.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } правило для сообщений перемещает сообщения в папку, которая появится после синхронизации ее учетной записи.
    [few] { $count } правила для сообщений перемещают сообщения в папки, которые появятся после синхронизации их учетных записей.
    [many] { $count } правил для сообщений перемещают сообщения в папки, которые появятся после синхронизации их учетных записей.
   *[other] { $count } правила для сообщений перемещают сообщения в папки, которые появятся после синхронизации их учетных записей.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Добавлен { $count } надежный отправитель.
    [few] Добавлено { $count } надежных отправителя.
    [many] Добавлено { $count } надежных отправителей.
   *[other] Добавлено { $count } надежного отправителя.
}
# review: new
setup-nothing = Ничего не импортировано.
# review: new
setup-account-servers = { $imap } и { $smtp } ({ $signin })
# review: new
setup-file-name = Настройки и учетные записи Inbox Classic
# review: new
setup-skipped-unreachable = { $name } пропущено: не удалось связаться с его службой входа. Добавьте его снова в окне «Приложения для входа».
# review: new
attachment-runs-programs = «{ $name }» может запускать программы, поэтому Inbox Classic не открывает этот файл. Сохраните его и откройте сами, если доверяете его источнику.
# review: new
attachment-decrypted-note = Это вложение из зашифрованного сообщения. Чтобы его открыть, Inbox Classic хранит расшифрованную копию на этом компьютере, в вашей папке, которую Inbox Classic очищает через сутки.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Сервер не переместил { $messages } в папку { $folder }, поэтому оно снова в папке { $from }: { $reason }
   *[other] Сервер не переместил { $messages } в папку { $folder }, поэтому они снова в папке { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Сервер не удалил { $messages }, поэтому оно снова в папке { $from }: { $reason }
   *[other] Сервер не удалил { $messages }, поэтому они снова в папке { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Сервер не заархивировал { $messages }, поэтому оно снова в папке { $from }: { $reason }
   *[other] Сервер не заархивировал { $messages }, поэтому они снова в папке { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Сервер не отметил { $messages } как прочитанное, поэтому оно снова непрочитанное: { $reason }
   *[other] Сервер не отметил { $messages } как прочитанные, поэтому они снова непрочитанные: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Сервер не отметил { $messages } как непрочитанное, поэтому оно снова прочитанное: { $reason }
   *[other] Сервер не отметил { $messages } как непрочитанные, поэтому они снова прочитанные: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Сервер не изменил флажки, поэтому { $messages } осталось без изменений: { $reason }
   *[other] Сервер не изменил флажки, поэтому { $messages } остались без изменений: { $reason }
}
