# Български. Чернова, очаква преглед от носител на езика (вж. core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in Bulgarian too.

## Counts and sizes

# review: new
messages = { $count ->
    [one] 1 съобщение
   *[other] { $count } съобщения
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] 1 байт
   *[other] { $count } байта
}
# review: new
size-kb = { $size } КБ
# review: new
size-mb = { $size } МБ
# review: new
size-gb = { $size } ГБ
# review: new
send-delay-off = Изключено
# review: new
send-delay-seconds = { $count ->
    [one] 1 секунда
   *[other] { $count } секунди
}
# the status bar: "12 messages, 3 unread"
# review: new
list-counts = { $messages }, непрочетени: { $unread }
# review: new
list-counts-selected = { $messages }, непрочетени: { $unread }, избрани: { $selected }
# the status bar while searching: "12 found, 3 unread"
# review: new
list-counts-found = Намерени: { $found }, непрочетени: { $unread }
# review: new
list-counts-found-selected = Намерени: { $found }, непрочетени: { $unread }, избрани: { $selected }
# review: new
list-counts-none = Няма намерени съобщения

## Special folders, as Outlook names them

# review: new
folder-inbox = Входящи
# review: new
folder-sent = Изпратени
# review: new
folder-deleted = Изтрити
# review: new
folder-drafts = Чернови
# review: new
folder-junk = Нежелана поща
# review: new
folder-archive = Архив

## The reading pane

# review: new
reader-no-message = Няма избрано съобщение.
# review: new
reader-downloading = Съобщението се изтегля…
# review: new
reader-downloading-detail = Съобщението ще се покаже тук, когато изтеглянето завърши.
# review: new
reader-downloading-size = Съобщението е { $size }. То ще се покаже тук, когато бъде изтеглено.
# review: new
reader-failed = Съобщението не можа да бъде изтеглено
# review: new
reader-failed-network = Пощенският сървър е недостъпен ({ $reason }).
# review: new
reader-failed-sign-in = Пощенският сървър не прие влизането ({ $reason }). Проверете паролата или влезте отново от Файл > Акаунти.
# review: new
reader-failed-security = Връзката с пощенския сървър не можа да бъде защитена ({ $reason }).
# review: new
reader-failed-other = Пощенският сървър отговори: { $reason }.
# review: new
reader-retry-note = Ще бъде направен нов опит, когато акаунтът се свърже отново.
# review: new
reader-unreadable = Това съобщение не може да бъде показано: { $error }
# review: new
message-source-title = Източник на съобщението: { $subject }
# review: new
message-source-untitled = Източник на съобщението

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = От
# review: new
header-date = Дата
# review: new
header-to = До
# review: new
header-cc = Копие
# review: new
header-sent = Изпратено
# review: new
header-subject = Тема
# review: new
header-security = Защита
# review: new
header-part = Част { $number }
# review: new
quote-original = ----- Оригинално съобщение -----
# review: new
fold-show-earlier = Показване на по-ранните съобщения

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Съобщението ви не беше доставено
# review: new
bounce-delayed = Съобщението ви все още не е доставено
# review: new
bounce-delayed-note = Пощенският ви сървър все още се опитва да го достави. Не е нужно да го изпращате отново.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Показване на върнатото съобщение
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Показване на забавеното съобщение
# review: new
bounce-what-to-do = Какво можете да направите:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Засега нищо. Ако все пак не може да бъде доставено, ще получите ново известие.
# review: new
bounce-delayed-row-do = Засега нищо. Пощенският ви сървър все още се опитва да го достави и ще получите ново известие, ако не успее.
# folds the receiving server's own words
# review: new
bounce-details = Подробности
# a recipient the notice does not name
# review: new
bounce-someone = Получател
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Сървър: { $server }
# review: new
bounce-status = Състояние: { $status }
# review: new
bounce-reported-by = Съобщено от: { $server }
# review: new
bounce-retry-minutes = Получаващият сървър поиска да се изчака { $count ->
    [one] една минута
   *[other] { $count } минути
} преди следващия опит.
# review: new
bounce-retry-hours = Получаващият сървър поиска да се изчака { $count ->
    [one] един час
   *[other] { $count } часа
} преди следващия опит.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Черен списък: { $lists }
# review: new
bounce-user-unknown = Адресът не съществува
# review: new
bounce-user-unknown-why = Получаващият сървър няма пощенска кутия с този адрес. Възможно е адресът да е сгрешен или човекът вече да не го използва.
# review: new
bounce-user-unknown-do = Проверете как е изписан адресът или попитайте човека кой адрес използва сега.
# review: new
bounce-invalid-address = Адресът не е валиден
# review: new
bounce-invalid-address-why = Адресът не е написан във вид, на който може да се изпраща поща.
# review: new
bounce-invalid-address-do = Потърсете грешки при въвеждането, например интервал, липсваща буква или нищо след @.
# review: new
bounce-mailbox-disabled = Пощенската кутия е закрита
# review: new
bounce-mailbox-disabled-why = Адресът съществува, но пощенската му кутия е изключена или вече не се използва.
# review: new
bounce-mailbox-disabled-do = Свържете се с човека по друг начин и го помолете за адрес, който използва сега.
# review: new
bounce-mailbox-full = Пощенската кутия е пълна
# review: new
bounce-mailbox-full-why = В пощенската кутия на получателя няма място за нова поща.
# review: new
bounce-mailbox-full-do = Изпратете го отново след няколко дни или уведомете човека по друг начин. Големите прикачени файлове се отказват първи.
# review: new
bounce-spam-blocked = Отказано като спам
# review: new
bounce-spam-blocked-why = Получаващият сървър прие съобщението за спам.
# review: new
bounce-spam-blocked-do = Изпратете го отново без това, което прилича на спам, например много връзки, съкратени връзки или голям прикачен файл. Ако това продължава, попитайте доставчика на пощата си.
# review: new
bounce-virus-detected = Отказано заради вирус
# review: new
bounce-virus-detected-why = Получаващият сървър откри вирус или друго вредно съдържание в съобщението или в прикачените му файлове.
# review: new
bounce-virus-detected-do = Проверете прикачените файлове с антивирусна програма. Някои сървъри отказват всяка програма или архив, затова споделяйте такива файлове като връзка.
# review: new
bounce-ip-blocklisted = Пощенският ви сървър е в черен списък
# review: new
bounce-ip-blocklisted-why = Получаващият сървър отказва поща от сървъра, който е изпратил вашата, защото адресът на този сървър е в черен списък.
# review: new
bounce-ip-blocklisted-do = Проблемът не е в съобщението. Препратете това известие на доставчика на пощата си и го помолете сървърът да бъде изваден от списъка.
# review: new
bounce-domain-blocklisted = Домейн е в черен списък
# review: new
bounce-domain-blocklisted-why = Получаващият сървър отказва съобщението, защото домейнът на адреса ви или домейн от връзките в съобщението е в черен списък.
# review: new
bounce-domain-blocklisted-do = Ако съобщението има връзки, опитайте без тях. В противен случай препратете това известие на този, който поддържа пощата на домейна ви.
# review: new
bounce-policy-blocked = Отказано от правилата на получаващия сървър
# review: new
bounce-policy-blocked-why = Правилата на получаващия сървър не пропускат това съобщение, например заради размера му, прикачените файлове или подателя.
# review: new
bounce-policy-blocked-do = Думите на самия сървър в „Подробности“ често посочват причината. Попитайте получателя дали може да приема такава поща.
# review: new
bounce-geo-blocked = Отказано заради произхода
# review: new
bounce-geo-blocked-why = Получаващият сървър не приема поща от държавата или мрежата, в която е пощенският ви сървър.
# review: new
bounce-geo-blocked-do = Свържете се с човека по друг начин или попитайте доставчика на пощата си.
# review: new
bounce-relay-denied = Сървърът отказа да го предаде нататък
# review: new
bounce-relay-denied-why = Сървър отказа да предаде съобщението нататък, често защото е изпратено без влизане или през сървър, който не обслужва този получател.
# review: new
bounce-relay-denied-do = Проверете изходящия сървър на акаунта във Файл > Акаунти и дали той изисква влизане.
# review: new
bounce-auth-failure = Адресът на подателя не можа да бъде потвърден
# review: new
bounce-auth-failure-why = Получаващият сървър не можа да потвърди, че съобщението наистина идва от вашия домейн (SPF, DKIM или DMARC).
# review: new
bounce-auth-failure-do = Препратете това известие на този, който поддържа пощата на домейна ви: настройките му трябва да бъдат поправени. Междувременно може да помогне изпращането през собствения сървър на доставчика ви.
# review: new
bounce-rate-limited = Твърде много поща наведнъж
# review: new
bounce-rate-limited-why = Получаващият сървър засега приема по-малко съобщения от пощенския ви сървър.
# review: new
bounce-rate-limited-do = Изчакайте малко и го изпратете отново. Когато пишете на много хора, изпращайте на по-малко наведнъж.
# review: new
bounce-greylisting = Задържано за малко
# review: new
bounce-greylisting-why = Получаващият сървър моли непознатите податели да опитат отново малко по-късно, което е често срещана защита от спам.
# review: new
bounce-greylisting-do = Нищо. Пощенските сървъри опитват отново сами и обикновено съобщението се доставя до един час.
# review: new
bounce-server-error = Получаващият сървър имаше проблем
# review: new
bounce-server-error-why = Получаващият сървър беше недостъпен или не можа да приеме съобщението заради собствен проблем.
# review: new
bounce-server-error-do = Изпратете го отново по-късно. Ако продължава да не успява, проверете частта от адреса след @ за грешки при въвеждането.
# review: new
bounce-unknown = Не е доставено
# review: new
bounce-unknown-why = Известието не посочва ясно защо.
# review: new
bounce-unknown-do = Думите на самия сървър в „Подробности“ може да казват повече. Ако не помагат, препратете това известие на доставчика на пощата си.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] Избрано е 1 съобщение
   *[other] Избрани са { $count } съобщения
}
# review: new
selection-unread = Непрочетени: { $count }
# review: new
selection-flagged = С флаг: { $count }
# review: new
delete-for-good-one = Това съобщение ще бъде изтрито окончателно. Да се изтрие ли?
# review: new
delete-for-good-all = Тези { $count } съобщения ще бъдат изтрити окончателно. Да се изтрият ли?
# review: new
delete-for-good-some = { $count } от общо { $total } съобщения ще бъдат изтрити окончателно. Да се изтрият ли съобщенията?
# review: new
done-read = { $count ->
    [one] { $messages } е маркирано като прочетено
   *[other] { $messages } са маркирани като прочетени
}
# review: new
done-unread = { $count ->
    [one] { $messages } е маркирано като непрочетено
   *[other] { $messages } са маркирани като непрочетени
}
# review: new
done-flagged = { $count ->
    [one] { $messages } е маркирано с флаг
   *[other] { $messages } са маркирани с флаг
}
# review: new
done-unflagged = Флагът е премахнат от { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] { $messages } е изтрито окончателно
   *[other] { $messages } са изтрити окончателно
}
# review: new
done-archived = { $count ->
    [one] { $messages } е архивирано
   *[other] { $messages } са архивирани
}
# review: new
done-moved = { $count ->
    [one] { $messages } е преместено в { $folder }
   *[other] { $messages } са преместени в { $folder }
}
# review: new
done-copied = { $count ->
    [one] { $messages } е копирано в { $folder }
   *[other] { $messages } са копирани в { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Преместване на { $messages } в { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Копиране на { $messages } в { $folder }...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } е върнато обратно в { $folder }
   *[other] { $messages } са върнати обратно в { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Разговорът се следи
   *[other] Следят се { $count } разговора
}
# review: new
done-unwatched = { $count ->
    [one] Разговорът вече не се следи
   *[other] { $count } разговора вече не се следят
}
# review: new
done-ignored = { $count ->
    [one] Разговорът се пренебрегва
   *[other] Пренебрегват се { $count } разговора
}
# review: new
done-unignored = { $count ->
    [one] Разговорът вече не се пренебрегва
   *[other] { $count } разговора вече не се пренебрегват
}
# review: new
their-folders = техните папки
# review: new
undo-move = Отмяна на преместването
# review: new
undo-delete = Отмяна на изтриването
# review: new
undo-archive = Отмяна на архивирането
# review: new
undo-junk = Отмяна на маркирането като нежелана
# review: new
undo-not-junk = Отмяна на маркирането като желана
# review: new
undo-send = Отмяна на изпращането
# review: new
nothing-to-undo = Няма нищо за отмяна.
# review: new
messages-gone = Съобщенията вече ги няма.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Тази папка не може да съдържа съобщения.
# review: new
not-archived-here = Съобщенията в тази папка не могат да бъдат архивирани.
# review: new
not-emptied-here = Могат да се изпразват само „Изтрити“ и „Нежелана поща“.
# review: new
next-unread-question = В { $folder } няма повече непрочетени съобщения.

    Да се отиде ли в { $next }, следващата папка с непрочетени съобщения?
# review: new
no-unread-left = Не са останали непрочетени съобщения.
# review: new
empty-question = { $count ->
    [one] Да се изпразни ли { $folder }?

        Съобщението в нея ще бъде изтрито окончателно. То не може да бъде възстановено.
   *[other] Да се изпразни ли { $folder }?

        { $messages } в нея ще бъдат изтрити окончателно. Те не могат да бъдат възстановени.
}
# review: new
no-junk-folder = Този акаунт няма папка „Нежелана поща“, в която да се преместят съобщенията.
# review: new
no-inbox-folder = Този акаунт няма папка „Входящи“, в която да се преместят съобщенията.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
# review: new
done-flagged-color = Поставен е флаг на { $messages }: { $color ->
    [red] червен
    [orange] оранжев
    [yellow] жълт
    [green] зелен
    [blue] син
    [purple] лилав
   *[gray] сив
}
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Червен
    [orange] Оранжев
    [yellow] Жълт
    [green] Зелен
    [blue] Син
    [purple] Лилав
   *[gray] Сив
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [one] Преместване на съобщението
   *[other] Преместване на { $count } съобщения
}
# review: new
move-window-title-copy = { $count ->
    [one] Копиране на съобщението
   *[other] Копиране на { $count } съобщения
}
# review: new
move-window-prompt-move = { $count ->
    [one] Преместване на избраното съобщение в:
   *[other] Преместване на { $count } избрани съобщения в:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Копиране на избраното съобщение в:
   *[other] Копиране на { $count } избрани съобщения в:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Последни
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (текуща)
# a folder used last, with its account when there are several: "Archive (Work)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Преместване на { $done } от { $messages } в { $folder }...
# review: new
transfer-copying = Копиране на { $done } от { $messages } в { $folder }...
# review: new
transfer-another-account = друг акаунт
# review: new
transfer-folder-gone = папката, в която трябваше да отиде, вече я няма
# review: new
transfer-not-on-server = съобщението вече не е на сървъра
# review: new
transfer-not-moved = { $count ->
    [one] { $messages } не можа да бъде преместено в друг акаунт: { $reason }
   *[other] { $messages } не можаха да бъдат преместени в друг акаунт: { $reason }
}
# review: new
transfer-not-copied = { $count ->
    [one] { $messages } не можа да бъде копирано в друг акаунт: { $reason }
   *[other] { $messages } не можаха да бъдат копирани в друг акаунт: { $reason }
}
# review: new
transfer-none-moved = Нито едно съобщение не можа да бъде преместено
# review: new
transfer-none-copied = Нито едно съобщение не можа да бъде копирано

## Messages as files

# review: new
export-not-in-time = съобщението не можа да бъде изтеглено навреме
# review: new
export-not-saved = { $failed } от { $messages } не можаха да бъдат запазени ({ $problems })
# review: new
export-not-attached = съобщенията не можаха да бъдат прикачени: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
# review: new
saved-to = { $count ->
    [one] { $messages } е запазено в { $folder }
   *[other] { $messages } са запазени в { $folder }
}
# review: new
download-progress = Изтегляне на { $done } от { $total }
# review: new
download-done = Изтеглено: { $size }
# review: new
downloading-messages = { $count ->
   *[other] Изтегляне на { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
# review: new
import-put = { $count ->
    [one] { $messages } е поставено в { $folder }
   *[other] { $messages } са поставени в { $folder }
}
# review: new
import-not-put = Тези не бяха поставени в папката:

    { $problems }

## Problems the windows show

# review: new
error-store = локално хранилище: { $error }
# review: new
error-not-found = не е намерено
# review: new
error-closed = затваряне
# review: new
error-other-account = браузърът влезе в { $email }, а не в този акаунт
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = сървърът не прие влизането ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = връзката със сървъра не успя ({ $reason })
# review: new
error-in-use = не може да бъде премахнато, докато акаунти влизат чрез него: { $accounts }
# review: new
error-turned-off = това приложение за влизане е изключено за нови акаунти
# review: new
error-folder-name = името на папката трябва да е от 1 до 200 знака и не може да съдържа управляващи знаци
# review: new
error-folder-separator = на този сървър името на папка не може да съдържа „{ $separator }“
# review: new
error-folder-special = „Входящи“ и специалните папки не могат да бъдат преименувани или изтрити
# review: new
error-no-recipients = съобщението няма получатели
# review: new
error-bad-address = „{ $address }“ не е имейл адрес
# review: new
error-not-own-address = { $address } не е сред адресите за изпращане на този акаунт. Добавете го в „Други адреси, от които изпращате“ в свойствата на акаунта.
# review: new
rule-query-refused = Правилата не могат да филтрират по папка или дата ({ $words }).
# review: new
rule-no-query = Въведете критерии за търсене за входящите съобщения.
# review: new
rule-no-action = Изберете поне едно действие за правилото.
# review: new
error-attachment = { $path } не можа да бъде прочетен: { $error }
# review: new
error-no-drafts = акаунтът няма папка „Чернови“, в която да се запази съобщението
# review: new
error-draft-attachment = прикачен файл на черновата не можа да бъде запазен: { $error }
# review: new
error-password-not-saved = паролата не можа да бъде запазена за следващото стартиране: { $error }
# review: new
error-sign-in-not-saved = новите данни за влизане не можаха да бъдат запазени за следващото стартиране: { $error }
# review: new
error-import-unreadable = { $path } не може да бъде прочетен: { $error }
# review: new
error-import-too-large = { $path } е по-голям от 50 МБ
# review: new
error-import-not-mail = { $path } не е имейл съобщение
# review: new
error-list-answered = сървърът на пощенския списък върна състояние { $status }
# review: new
error-not-built = съобщението не можа да бъде съставено
# review: new
error-outbox-waits = { $count ->
    [one] съобщението чака в „Изходящи“ и ще бъде изпратено при следващото изпращане и получаване
   *[other] { $count } съобщения чакат в „Изходящи“ и ще бъдат изпратени при следващото изпращане и получаване
}
# review: new
error-draft-not-removed = предишната чернова на съобщението не можа да бъде премахната от „Чернови“: { $reason }
# review: new
error-sent-but = съобщението беше изпратено, но { $problem }
# review: new
error-sent-still-in-outbox = то все още е в „Изходящи“: { $error }
# review: new
error-sent-no-copy = не можа да бъде запазено копие в „Изпратени“: { $reason }
# review: new
error-no-password = няма парола за този акаунт
# review: new
error-no-sign-in = няма данни за влизане за този акаунт
# review: new
error-provider-missing = тази версия не може да влиза в { $provider }: премахнато ли е приложението му за влизане?
# review: new
error-provider-servers = сървърите на този акаунт не съвпадат със сървърите на приложението му за влизане
# review: new
error-app-scopes = { $reason }. Пощенският сървър не прие маркера на приложението за влизане: проверете дали обхватите на приложението дават достъп до пощата
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google все още не е потвърдил Inbox Classic, затова позволява влизане чрез него само на тестови потребители. Използвайте свое приложение за влизане в Google или парола за приложение, или го включете в „Приложения за влизане“ (Файл > Акаунти), ако сте тестов потребител.
# review: new
sign-in-off-other = То е изключено в „Приложения за влизане“ (Файл > Акаунти), където може да бъде включено отново.
# review: new
sign-in-app-no-name = приложението за влизане трябва да има име
# review: new
sign-in-app-no-client = липсва ИД на клиента
# review: new
sign-in-app-no-scopes = приложението за влизане трябва да има обхватите, които дават достъп до пощата
# review: new
sign-in-app-bad-host = адресът на сървъра { $server } липсва или не е валидно име на хост
# review: new
sign-in-app-plain = сървърът { $server } трябва да използва SSL/TLS или STARTTLS
# review: new
sign-in-app-not-checked = издателят все още не е проверен
# review: new
sign-in-app-issuer-changed = издателят е променен: въведете отново тайната на клиента или я премахнете
# review: new
sign-in-register-google = В Google Cloud Console създайте OAuth клиент от типа Desktop app с обхвата https://mail.google.com/ на екрана му за съгласие. Докато приложението е в тестов режим, в него могат да влизат само тестовите му потребители.
# review: new
sign-in-register-microsoft = В Microsoft Entra регистрирайте приложение с платформата Mobile and desktop applications, URI за пренасочване http://localhost, разрешени потоци за публичен клиент и делегираните разрешения IMAP.AccessAsUser.All, SMTP.Send и offline_access. Само за вашата организация използвайте https://login.microsoftonline.com/<ИД на клиента в Entra>/v2.0 като издател.
# review: new
sign-in-register-other = Регистрирайте собствен (публичен) клиент с URI за пренасочване по-долу; доставчикът трябва да разрешава всеки порт за него (RFC 8252). Добавете обхвата, с който доставчикът дава достъп до пощата.

## Calendar invitations

# review: new
repeats = Повторение
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Всеки ден
       *[other] На всеки { $interval } дни
    }
    [week] { $interval ->
        [one] Всяка седмица
       *[other] На всеки { $interval } седмици
    }
    [month] { $interval ->
        [one] Всеки месец
       *[other] На всеки { $interval } месеца
    }
   *[year] { $interval ->
        [one] Всяка година
       *[other] На всеки { $interval } години
    }
}
# "Every week on Monday, Wednesday"
# review: new
repeats-on = { $repeats }: { $days }
# "Every week, 10 times"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, веднъж
   *[other] { $repeats }, { $count } пъти
}
# review: new
day-monday = понеделник
# review: new
day-tuesday = вторник
# review: new
day-wednesday = сряда
# review: new
day-thursday = четвъртък
# review: new
day-friday = петък
# review: new
day-saturday = събота
# review: new
day-sunday = неделя

## AI agents

# review: new
agent-level-read = Четене на поща: папки, списък със съобщения, търсене и съобщения
# review: new
agent-level-organize = Подреждане на поща: прочетено, флагове, нежелана поща, преместване, изтриване в „Изтрити“
# review: new
agent-level-drafts = Писане на чернови, които вие изпращате
# review: new
agent-level-send = Изпращане на поща, всяко съобщение само след вашето „да“
# review: new
agent-connect-title = { $program } иска да използва пощата ви
# review: new
agent-connect-detail = ИИ агент поиска да работи с Inbox Classic. Изберете какво може да прави и кои акаунти може да вижда; можете да промените това по-късно в Инструменти > ИИ агенти.

    Агентите четат поща, написана от други хора, и някое съобщение може да се опита да ги заблуди. Inbox Classic винаги ви пита, преди агент да изпрати каквото и да е.
# review: new
agent-reply-to = Отговор на „{ $subject }“
# review: new
agent-reply-all-on = Отговор до всички на „{ $subject }“
# review: new
agent-forward-of = Препращане на „{ $subject }“
# review: new
agent-never-written-one = Никога не сте писали на { $address }.
# review: new
agent-never-written-many = Никога не сте писали на { $count } от тези адреси.
# review: new
agent-send-title = { $program } иска да изпрати това съобщение
# review: new
agent-send-detail = Проверете получателите и съдържанието на съобщението. След като потвърдите, съобщението чака { $seconds } секунди в „Изходящи“, където все още можете да го изтриете.
# review: new
agent-change-title = Какво може да прави { $program }
# review: new
agent-change-allowed = Променете какво могат да правят с пощата ви ИИ агентите на тази програма.
# review: new
agent-change-refused = Отказахте достъп на тази програма. Разрешете го, за да дадете отново на агентите ѝ достъп до пощата ви.
# review: new
agent-log-taken-back = { $entry } (отменено)
# review: new
agent-files = Файлове: { $files }
# review: new
agent-undo-refused = Това не може да бъде отменено.
# review: new
agent-undo-refused-why = Това не може да бъде отменено: { $reason }.
# review: new
agent-undo-impossible = това не може да бъде отменено
# review: new
agent-undo-not-in-folder = съобщението вече не е в тази папка
# review: new
agent-undo-not-arrived = съобщението (все още) не е в папката, в която отиде
# review: new
agent-undo-sent = съобщението вече е изпратено
# review: new
agent-original-not-downloaded = оригиналното съобщение все още не е изтеглено. Първо го отворете
# review: new
agent-turned-away = Отказан
# review: new
agent-can-nothing = Нищо
# review: new
agent-can-read = четене
# review: new
agent-can-organize = подреждане
# review: new
agent-can-drafts = писане на чернови
# review: new
agent-can-send = изпращане с ваше съгласие
# "Read, organize and write drafts"
# review: new
agent-can-list = { $first } и { $last }
# review: new
agent-accounts = { $count ->
    [0] нито един акаунт
    [one] 1 акаунт
   *[other] { $count } акаунта
}
# "Read and organize; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Това съобщение не може да бъде прочетено.
# review: new
agent-encrypted-original = Това съобщение е шифровано: агент не може да отговори на него или да го препрати, тъй като не може да шифрова.
# review: new
agent-encrypted = Това съобщение е шифровано. Само потребителят може да го прочете, в Inbox Classic.
# review: new
list-encrypted = Шифровано съобщение
# review: new
agent-log-composed = „{ $subject }“ е отворено в ново съобщение, за да го довършите
# review: new
agent-log-refused = Не изпратихте „{ $subject }“
# review: new
agent-log-sent = „{ $subject }“ е изпратено до { $to }
# review: new
agent-log-draft = Черновата „{ $subject }“ е запазена
# review: new
agent-log-read = „{ $subject }“ е маркирано като прочетено
# review: new
agent-log-unread = „{ $subject }“ е маркирано като непрочетено
# review: new
agent-log-flagged = „{ $subject }“ е маркирано с флаг
# review: new
agent-log-unflagged = Флагът на „{ $subject }“ е премахнат
# review: new
agent-log-deleted = „{ $subject }“ е изтрито
# review: new
agent-log-moved = „{ $subject }“ е преместено в { $folder }
# review: new
agent-log-junk = „{ $subject }“ е маркирано като нежелана поща
# review: new
agent-log-not-junk = „{ $subject }“ е маркирано като желана поща
# review: new
agent-log-archived = „{ $subject }“ е архивирано
# review: new
agent-log-folder = Създадена е папката „{ $name }“
# review: new
agent-log-unsubscribed = Отписване от списъка на „{ $subject }“

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
sign-in-no-refresh = доставчикът не даде маркер за опресняване
# review: new
sign-in-no-account = доставчикът не посочи кой акаунт е влязъл
# review: new
sign-in-not-finished = влизането не е завършило
# review: new
secrets-unavailable = { $store } не е достъпен
# review: new
secrets-unavailable-why = { $store } не е достъпен: { $error }
# review: new
secrets-windows = Диспечер на идентификационни данни
# review: new
secrets-mac = Ключодържател
# review: new
secrets-linux = Системен ключодържател (Secret Service)
# review: new
error-no-such-file = няма такъв файл
# review: new
cards-file-too-big = Този файл е твърде голям, за да бъде адресна книга.
# review: new
ui-sender-added = { $name } е добавен в адресната книга.
# review: new
ui-sender-known = { $name } вече е в адресната книга.
# review: new
ui-sender-none = Подателят на това съобщение няма имейл адрес, който да бъде добавен.
# review: new
card-name-needed = Контактът няма име и имейл адрес.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Код от { $domain }
# review: new
otp-copy = Копиране
# review: new
otp-note = Въвеждайте го само на страница на { $domain }.
# review: new
otp-old = Този код е изпратен повече от час преди да го отворите и вероятно вече е изтекъл.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } участник
       *[other] { $count } участници
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } е кодът ви за { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Валиден
# review: new
pgp-key-expires = Валиден до { $date }
# review: new
pgp-key-expired = Изтекъл на { $date }
# review: new
pgp-key-revoked = Отменен
# review: new
pgp-key-revoked-why = Отменен: { $reason }
# review: new
pgp-key-not-valid = Невалиден
# review: new
pgp-key-locked = Не може да се използва: ключът, който го защитава, вече не е в { $store }. Импортирайте отново резервното му копие.
# review: new
pgp-source-own = Създаден в Inbox Classic
# review: new
pgp-source-file = Импортиран от файл
# review: new
pgp-source-paste = Поставен
# review: new
pgp-source-attachment = От съобщение
# review: new
pgp-source-vcard = От визитка на контакт
# review: new
pgp-source-wkd = От пощенския доставчик на подателя
# review: new
pgp-source-keyserver = От keys.openpgp.org
# review: new
pgp-source-autocrypt = От заглавката Autocrypt на съобщение
# review: new
pgp-error-no-store = Частните ключове се пазят защитени от { $store }, който не може да бъде използван: { $error }
# review: new
pgp-error-wrong-passphrase = Фразата за достъп е грешна.
# review: new
pgp-error-not-a-key = Това не е OpenPGP ключ.
# review: new
pgp-error-too-large = Ключът е твърде голям.
# review: new
pgp-error-unusable = Ключът използва стара или слаба криптография и не може да бъде използван.
# review: new
pgp-imported-private = { $count ->
    [one] Частният ви ключ е импортиран.
   *[other] Импортирани са { $count } частни ключа.
}
# review: new
pgp-imported-public = { $count ->
    [one] Импортиран е един ключ.
   *[other] Импортирани са { $count } ключа.
}
# review: new
pgp-imported-pending = За { $addresses } вече се използва друг ключ: новият чака в контакта, докато не го изберете.
# review: new
pgp-error-needs-passphrase = Частният ключ е защитен с фраза за достъп. Въведете я, за да импортирате ключа.
# review: new
pgp-error-mismatch = Частният ключ не принадлежи на публичния си ключ. Възможно е да е бил променен.
# review: new
pgp-file-name-public = Публичен ключ на { $who }.asc
# review: new
pgp-file-name-private = Резервно копие на частния ключ на { $who }.asc
# review: new
pgp-pending = На { $date } беше намерен друг ключ за { $address }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Подписано от { $signer }, ключът е потвърден
# review: new
pgp-part-signed = Подписано от { $signer } (ключът не е потвърден)
# review: new
pgp-part-other = Подписано от { $signer }, който не е подателят
# review: new
pgp-part-unknown-key = Подписано, но ключът не е известен
# review: new
pgp-part-not-signed = Не е подписано
# review: new
pgp-part-not-checked = Подписът не е проверен
# review: new
pgp-part-encrypted = Шифровано. { $signature }
# review: new
pgp-part-no-key = Шифровано за ключ, който нямате
# review: new
pgp-part-changed = Шифрованата част е била променена по пътя и не се показва
# review: new
pgp-part-unprotected = Шифровано без защита срещу промени, не се показва
# review: new
pgp-part-broken = Шифрованата част не може да бъде прочетена
# review: new
pgp-why-mismatch = Подписът не съответства на този текст
# review: new
pgp-why-weak-hash = Подписът използва { $hash }, който вече не е сигурен
# review: new
pgp-why-key-expired = Подписано, след като ключът е изтекъл на { $date }
# review: new
pgp-why-key-revoked = Подписано с ключ, който е бил отменен
# review: new
pgp-why-not-signing-key = Подписано с ключ, който няма право да подписва
# review: new
pgp-why-from-future = Подписът е с дата в бъдещето
# review: new
pgp-why-signature-expired = Подписът е изтекъл
# review: new
pgp-why-key-not-valid = Подписано с ключ, който не е валиден
# review: new
pgp-why-not-for-you = Подписано за други получатели и препратено до вас
# review: new
pgp-part-pictures-loaded = { $label }. Изображенията са заредени от интернет
# review: new
pgp-error-no-own-key = Нямате ключ за { $address }, с който да подписвате или шифровате. Създайте такъв в Инструменти > Ключове за шифроване или изключете „Подписване“ и „Шифроване“.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } няма ключ, за който да се шифрова.
   *[other] Тези получатели нямат ключ, за който да се шифрова: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Това съобщение цитира или препраща шифровано съобщение, затова може да бъде изпратено само шифровано. Включете „Шифроване“ или премахнете цитирания текст.
# review: new
pgp-error-protect = Съобщението не можа да бъде подписано или шифровано: { $reason }
# review: new
pgp-found-keys = Намерен е ключът на { $addresses }.
# review: new
pgp-found-none = Не е намерен ключ за { $addresses }. Помолете да ви изпратят публичния си ключ.
# review: new
pgp-found-no-key = Не е намерен ключ.
# review: new
pgp-find-unavailable = В момента не може да се търсят ключове: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org изпрати връзка за потвърждение до { $addresses }. Ключът ви ще бъде публикуван там, след като щракнете върху нея.
# review: new
pgp-publish-done = Ключът ви е публикуван в keys.openpgp.org за { $addresses }.
# review: new
pgp-publish-failed = Ключът не можа да бъде публикуван: { $error }
# review: changed
pgp-keyserver-off = Търсенето на ключове в keys.openpgp.org е изключено в { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Шифровано и подписано: само вие и { $addresses } можете да го прочетете.
   *[other] Шифровано и подписано: само вие и неговите { $count } получатели можете да го прочетете.
}
# review: new
pgp-compose-encrypt-ready = Ще бъде шифровано и подписано. Добавете получатели, чиито ключове имате.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } няма ключ, затова съобщението все още не може да бъде шифровано.
   *[other] { $count } получатели нямат ключ, затова съобщението все още не може да бъде шифровано: { $addresses }.
}
# review: new
pgp-compose-looking = Търсене на ключовете на { $addresses }...
# review: new
pgp-compose-signed = Подписано: получателите могат да проверят, че е от вас и не е променяно.
# review: new
pgp-compose-reply-clear = Не е шифровано, въпреки че съобщението, на което отговаря или което препраща, беше шифровано.
# review: new
pgp-compose-encrypted-files = Прикачени са файлове от шифровано съобщение, затова това съобщение може да бъде изпратено само шифровано. Включете „Шифроване“ или премахнете тези файлове.
# review: new
pgp-compose-sign-tip = Подписване на съобщението с вашия ключ, за да могат получателите да проверят, че е от вас и не е променяно
# review: new
pgp-compose-sign-tip-encrypted = Шифрованото съобщение винаги е и подписано
# review: new
pgp-compose-encrypt-tip = Шифроване на съобщението, така че само вие и получателите му да могат да го прочетат
# review: new
pgp-compose-make-key = Все още нямате ключ за { $address }. Да бъде ли създаден сега? С него съобщенията ви могат да бъдат подписвани и шифровани.
# review: new
pgp-compose-key-unusable = Ключът ви за { $address } не може да бъде използван ({ $state }). Отворете „Ключове за шифроване“, за да импортирате резервното му копие или да създадете нов ключ.
# review: new
pgp-compose-encrypt-off-quote = Това съобщение цитира или препраща шифровано съобщение. Без шифроване то не може да бъде изпратено, докато не премахнете цитирания текст. Да бъде ли изключено шифроването въпреки това?
# review: new
pgp-compose-encrypt-off-reply = Това съобщение отговаря на шифровано съобщение или го препраща. Без шифроване всеки, през когото минава съобщението ви по пътя, може да го прочете. Да бъде ли изключено шифроването?
# review: new
pgp-recipient-verified = Ключът е потвърден
# review: new
pgp-recipient-found = Ключът не е потвърден
# review: new
pgp-recipient-own = Вашият собствен ключ
# review: new
pgp-recipient-looking = Търсене на ключ...
# review: new
pgp-recipient-missing = Няма ключ
# review: new
pgp-recipient-not-found = Няма ключ: не е намерен на { $date }
# review: new
pgp-recipient-unusable = Ключът не може да бъде използван: { $state }
# review: new
pgp-recipients-intro = Съобщението се шифрова за ключа на всеки получател и за вашия.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Един получател няма ключ, за който да се шифрова. Намерете ключа му, премахнете го от това съобщение или изпратете съобщението без шифроване.
   *[other] { $count } получатели нямат ключ, за който да се шифрова. Намерете ключовете им, премахнете ги от това съобщение или изпратете съобщението без шифроване.
}
# review: new
pgp-details-part = Част { $number }: { $label }
# review: new
pgp-details-signed = Подписано на { $when } с ключа { $key }
# review: new
pgp-details-unknown-key = Подписано с ключа { $key }, който нямате
# review: new
pgp-details-opened = Шифровано за вашия ключ { $key }
# review: new
pgp-details-for = Шифровано за { $keys }
# review: new
pgp-details-plain = Нито подписано, нито шифровано
# review: new
pgp-bar-parts = Това съобщение има { $count } части: { $list }. Всяка част показва как е защитена.
# review: new
pgp-bar-count-verified = потвърдени: { $count }
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 подписана или шифрована
   *[other] { $count } подписани или шифровани
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 изисква внимание
   *[other] { $count } изискват внимание
}
# review: new
pgp-bar-count-neutral = без потвърден подпис: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Настройки
# review: new
setup-part-preferences = Предпочитания за прозорците
# review: new
setup-part-accounts = Акаунти
# review: new
setup-part-sign-in-apps = Приложения за влизане
# review: new
setup-part-contacts = Контакти и групи
# review: new
setup-part-keys = Ключове за шифроване
# review: new
setup-part-rules = Правила за съобщения
# review: new
setup-part-trusted-senders = Доверени податели
# review: new
setup-holds-settings = { $count ->
    [one] 1 настройка
   *[other] { $count } настройки
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 предпочитание
   *[other] { $count } предпочитания
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 акаунт
   *[other] { $count } акаунта
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 приложение за влизане
   *[other] { $count } приложения за влизане
}
# review: new
setup-holds-built-in = Кои вградени приложения за влизане са включени
# review: new
setup-holds-contacts = { $count ->
    [one] 1 контакт
   *[other] { $count } контакта
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 група
   *[other] { $count } групи
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 ваш ключ
   *[other] { $count } ваши ключа
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 ключ на контакт
   *[other] { $count } ключа на контакти
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 правило
   *[other] { $count } правила
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 доверен подател
   *[other] { $count } доверени податели
}
# review: new
setup-sign-in-password = Парола
# review: new
setup-account-secret-password = Паролата му е във файла.
# review: new
setup-account-secret-token = Данните му за влизане са във файла.
# review: new
setup-account-asks-password = Ще поиска паролата си след импортирането.
# review: new
setup-account-signs-in-again = След импортирането ще влезете в него отново.
# review: new
setup-account-here = Вече е настроен тук, затова се пропуска.
# review: new
setup-account-no-app = Влиза чрез { $app }, което не е настроено тук. Импортирайте и приложенията за влизане.
# review: new
setup-invalid-address = „{ $address }“ не е имейл адрес.
# review: new
setup-invalid-server = Сървърът { $server } няма използваемо име или порт.
# review: new
setup-invalid-user = Няма потребителско име.
# review: new
setup-invalid-sign-in = Влиза по начин, който Inbox Classic не познава.
# review: new
setup-error-empty = Файлът е празен.
# review: new
setup-error-too-large = Файлът е твърде голям, за да бъде настройка на Inbox Classic.
# review: new
setup-error-not-setup = Този файл не е настройка на Inbox Classic.
# review: new
setup-error-damaged = Файлът с настройките е повреден и не може да бъде прочетен.
# review: new
setup-error-newer = Тези настройки са запазени от по-нова версия на Inbox Classic ({ $version }). Обновете Inbox Classic и ги импортирайте отново.
# review: new
setup-error-needs-passphrase = Тези настройки са защитени с фраза за достъп. Въведете фразата, с която са запазени.
# review: new
setup-error-wrong-passphrase = Това не е фразата за достъп, с която са запазени тези настройки.
# review: new
setup-error-changed = Файлът с настройките е бил променен или повреден след запазването, затова не може да бъде импортиран.
# review: new
setup-error-read = Файлът с настройките не можа да бъде прочетен: { $error }
# review: new
setup-error-write = Настройките не можаха да бъдат запазени: { $error }
# review: new
setup-error-no-parts = Изберете поне една част.
# review: new
setup-left-out = { $count ->
    [one] 1 запис от „{ $part }“ не може да бъде използван и е пропуснат.
   *[other] { $count } записа от „{ $part }“ не могат да бъдат използвани и са пропуснати.
}
# review: new
setup-imported-settings = Настройките бяха заменени.
# review: new
setup-imported-preferences = Предпочитанията за прозорците бяха заменени.
# review: new
setup-added-accounts = { $count ->
    [one] Добавен е 1 акаунт.
   *[other] Добавени са { $count } акаунта.
}
# review: new
setup-skipped-here = { $address } вече е настроен тук, затова беше пропуснат.
# review: new
setup-skipped-no-app = { $address } беше пропуснат: влиза чрез { $app }, което не е настроено тук.
# review: new
setup-skipped-invalid = { $address } беше пропуснат: { $reason }
# review: new
setup-asks-password = { $address } ще поиска паролата си, когато се свърже.
# review: new
setup-signs-in-again = { $address } ще ви помоли да влезете отново, когато се свърже.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Добавено е 1 приложение за влизане.
   *[other] Добавени са { $count } приложения за влизане.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 приложение за влизане вече е настроено тук.
   *[other] { $count } приложения за влизане вече са настроени тук.
}
# review: new
setup-added-contacts = { $count ->
    [one] Добавен е 1 контакт в адресната книга.
   *[other] Добавени са { $count } контакта в адресната книга.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 контакт вече е в адресната книга.
   *[other] { $count } контакта вече са в адресната книга.
}
# review: new
setup-added-groups = { $count ->
    [one] Добавена или допълнена е 1 група.
   *[other] Добавени или допълнени са { $count } групи.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Добавен е 1 ваш ключ.
   *[other] Добавени са { $count } ваши ключа.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Добавен е 1 ключ на контакт.
   *[other] Добавени са { $count } ключа на контакти.
}
# review: new
setup-added-rules = { $count ->
    [one] Добавено е 1 правило за съобщения.
   *[other] Добавени са { $count } правила за съобщения.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 правило за съобщения вече е тук.
   *[other] { $count } правила за съобщения вече са тук.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 правило за съобщения е за акаунт, който не е тук, затова беше пропуснато.
   *[other] { $count } правила за съобщения са за акаунти, които не са тук, затова бяха пропуснати.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 правило за съобщения премества съобщения в папка, която ще се появи, когато акаунтът ѝ се синхронизира.
   *[other] { $count } правила за съобщения преместват съобщения в папки, които ще се появят, когато акаунтите им се синхронизират.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Добавен е 1 доверен подател.
   *[other] Добавени са { $count } доверени податели.
}
# review: new
setup-nothing = Нищо не беше импортирано.
# review: new
setup-account-servers = { $imap } и { $smtp } ({ $signin })
# review: new
setup-file-name = Настройки и акаунти на Inbox Classic
# review: new
setup-skipped-unreachable = { $name } беше пропуснат: услугата му за влизане беше недостъпна. Добавете го отново в „Приложения за влизане“.
# review: new
attachment-runs-programs = Файлът „{ $name }“ може да стартира програми, затова Inbox Classic не го отваря. Запазете го и след това го отворете сами, ако имате доверие на източника му.
# review: new
attachment-decrypted-note = Този прикачен файл е от шифровано съобщение. За да го отвори, Inbox Classic го съхранява дешифриран на този компютър, в ваша папка, която Inbox Classic изпразва след един ден.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Сървърът не премести { $messages } в папка { $folder }, затова съобщението отново е в папка { $from }: { $reason }
   *[other] Сървърът не премести { $messages } в папка { $folder }, затова съобщенията отново са в папка { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Сървърът не изтри { $messages }, затова съобщението отново е в папка { $from }: { $reason }
   *[other] Сървърът не изтри { $messages }, затова съобщенията отново са в папка { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Сървърът не архивира { $messages }, затова съобщението отново е в папка { $from }: { $reason }
   *[other] Сървърът не архивира { $messages }, затова съобщенията отново са в папка { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Сървърът не маркира { $messages } като прочетено, затова съобщението отново е непрочетено: { $reason }
   *[other] Сървърът не маркира { $messages } като прочетени, затова съобщенията отново са непрочетени: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Сървърът не маркира { $messages } като непрочетено, затова съобщението отново е прочетено: { $reason }
   *[other] Сървърът не маркира { $messages } като непрочетени, затова съобщенията отново са прочетени: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Сървърът не промени флаговете на { $messages }, затова съобщението е както преди: { $reason }
   *[other] Сървърът не промени флаговете на { $messages }, затова съобщенията са както преди: { $reason }
}
