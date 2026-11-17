# Български. Чернова, очаква преглед от носител на езика (вж. core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code; keep them, in
# the place the language puts them. Plurals choose by the number: [one] and *[other] in Bulgarian too.

## Counts and sizes

messages = { $count ->
    [one] 1 съобщение
   *[other] { $count } съобщения
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 байт
   *[other] { $count } байта
}
size-kb = { $size } КБ
size-mb = { $size } МБ
size-gb = { $size } ГБ
send-delay-off = Изключено
send-delay-seconds = { $count ->
    [one] 1 секунда
   *[other] { $count } секунди
}
# the status bar: "12 messages, 3 unread"
list-counts = { $messages }, непрочетени: { $unread }
list-counts-selected = { $messages }, непрочетени: { $unread }, избрани: { $selected }
# the status bar while searching: "12 found, 3 unread"
list-counts-found = Намерени: { $found }, непрочетени: { $unread }
list-counts-found-selected = Намерени: { $found }, непрочетени: { $unread }, избрани: { $selected }
list-counts-none = Няма намерени съобщения

## Special folders, as Outlook names them

folder-inbox = Входящи
folder-sent = Изпратени
folder-deleted = Изтрити
folder-drafts = Чернови
folder-junk = Нежелана поща
folder-archive = Архив

## The reading pane

reader-no-message = Няма избрано съобщение.
reader-downloading = Съобщението се изтегля…
reader-downloading-detail = Съобщението ще се покаже тук, когато изтеглянето завърши.
reader-downloading-size = Размер на съобщението: { $size }. То ще се покаже тук, когато бъде изтеглено.
reader-failed = Съобщението не можа да бъде изтеглено
reader-failed-network = Пощенският сървър е недостъпен ({ $reason }).
reader-failed-sign-in = Пощенският сървър не прие влизането ({ $reason }). Проверете паролата или влезте отново от Файл > Акаунти.
reader-failed-security = Не можа да се установи защитена връзка с пощенския сървър ({ $reason }).
reader-failed-other = Пощенският сървър отговори: { $reason }.
reader-retry-note = Ще бъде направен нов опит, когато акаунтът се свърже отново.
reader-unreadable = Това съобщение не може да бъде показано: { $error }
message-source-title = Източник на съобщението: { $subject }
message-source-untitled = Източник на съобщението

## Printing a message, and the header of a message quoted in a reply or forward

header-from = От
header-date = Дата
header-to = До
header-cc = Копие
header-sent = Изпратено
header-subject = Тема
header-security = Защита
header-part = Част { $number }
quote-original = ----- Оригинално съобщение -----
fold-show-earlier = Показване на по-ранните съобщения

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Съобщението ви не беше доставено
bounce-delayed = Съобщението ви все още не е доставено
bounce-delayed-note = Пощенският ви сървър все още се опитва да го достави. Не е нужно да го изпращате отново.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Показване на недоставеното съобщение
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Показване на забавеното съобщение
bounce-what-to-do = Какво можете да направите:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Изчакайте. Ако съобщението не може да бъде доставено, ще получите ново известие.
bounce-delayed-row-do = Изчакайте. Пощенският ви сървър все още се опитва да достави съобщението. Ще получите ново известие, ако не успее.
# folds the receiving server's own words
bounce-details = Подробности
# a recipient the notice does not name
bounce-someone = Получател
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Сървър: { $server }
bounce-status = Състояние: { $status }
bounce-reported-by = Съобщено от: { $server }
bounce-retry-minutes = Сървърът на получателя поиска да се изчака { $count ->
    [one] една минута
   *[other] { $count } минути
} преди следващия опит.
bounce-retry-hours = Сървърът на получателя поиска да се изчака { $count ->
    [one] един час
   *[other] { $count } часа
} преди следващия опит.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Черен списък: { $lists }
bounce-user-unknown = Адресът не съществува
bounce-user-unknown-why = Сървърът на получателя няма пощенска кутия с този адрес. Възможно е адресът да е сгрешен или човекът вече да не го използва.
bounce-user-unknown-do = Проверете как е изписан адресът или попитайте човека кой адрес използва сега.
bounce-invalid-address = Адресът не е валиден
bounce-invalid-address-why = Адресът не е в правилния формат за имейл адрес.
bounce-invalid-address-do = Проверете за грешки, например интервал, липсваща буква или липсващ домейн след @.
bounce-mailbox-disabled = Пощенската кутия е закрита
bounce-mailbox-disabled-why = Адресът съществува, но пощенската му кутия е изключена или вече не се използва.
bounce-mailbox-disabled-do = Свържете се с човека по друг начин и го помолете за адрес, който използва сега.
bounce-mailbox-full = Пощенската кутия е пълна
bounce-mailbox-full-why = В пощенската кутия на получателя няма място за нова поща.
bounce-mailbox-full-do = Изпратете съобщението отново след няколко дни или уведомете получателя по друг начин. Можете да опитате и с по-малки прикачени файлове.
bounce-spam-blocked = Отказано като спам
bounce-spam-blocked-why = Сървърът на получателя прие съобщението за спам.
bounce-spam-blocked-do = Опитайте да изпратите съобщението без многобройните или съкратените връзки и големите прикачени файлове, заради които може да е определено като спам. Ако отказът се повтаря, обърнете се към доставчика на пощата си.
bounce-virus-detected = Отказано заради вирус
bounce-virus-detected-why = Сървърът на получателя откри вирус или друго вредно съдържание в съобщението или в прикачените му файлове.
bounce-virus-detected-do = Проверете прикачените файлове с антивирусна програма. Някои сървъри отказват всяка програма или архив, затова споделяйте такива файлове като връзка.
bounce-ip-blocklisted = Пощенският ви сървър е в черен списък
bounce-ip-blocklisted-why = Сървърът на получателя отказва поща от вашия пощенски сървър, защото неговият IP адрес е в черен списък.
bounce-ip-blocklisted-do = Проблемът не е в съобщението. Препратете това известие на доставчика на пощата си и го помолете сървърът да бъде изваден от списъка.
bounce-domain-blocklisted = Домейн е в черен списък
bounce-domain-blocklisted-why = Сървърът на получателя отказва съобщението, защото домейнът на адреса ви или домейн от връзките в съобщението е в черен списък.
bounce-domain-blocklisted-do = Ако съобщението съдържа връзки, опитайте без тях. Иначе препратете това известие на администратора на пощата за вашия домейн.
bounce-policy-blocked = Отказано според правилата на сървъра на получателя
bounce-policy-blocked-why = Правилата на сървъра на получателя не позволяват доставянето на съобщението, например заради размера, прикачените файлове или подателя.
bounce-policy-blocked-do = Отговорът на сървъра в „Подробности“ често посочва причината. Попитайте получателя дали може да приема такава поща.
bounce-geo-blocked = Отказано заради държавата или мрежата на изпращане
bounce-geo-blocked-why = Сървърът на получателя не приема поща от държавата или мрежата, в която е пощенският ви сървър.
bounce-geo-blocked-do = Свържете се с човека по друг начин или попитайте доставчика на пощата си.
bounce-relay-denied = Сървърът отказа да препрати съобщението
bounce-relay-denied-why = Сървърът отказа да препрати съобщението. Често това означава, че не сте удостоверени пред него или че той не обслужва този получател.
bounce-relay-denied-do = Проверете изходящия сървър на акаунта във Файл > Акаунти и дали той изисква влизане.
bounce-auth-failure = Домейнът на подателя не можа да бъде потвърден
bounce-auth-failure-why = Сървърът на получателя не можа да потвърди, че съобщението наистина идва от вашия домейн (SPF, DKIM или DMARC).
bounce-auth-failure-do = Препратете това известие на администратора на пощата за вашия домейн, за да коригира настройките. Междувременно опитайте да изпратите съобщението през пощенския сървър на доставчика си.
bounce-rate-limited = Твърде много поща наведнъж
bounce-rate-limited-why = Сървърът на получателя засега приема по-малко съобщения от пощенския ви сървър.
bounce-rate-limited-do = Изчакайте малко и изпратете съобщението отново. Ако пишете на много хора, разделете получателите на по-малки групи.
bounce-greylisting = Временно отложено
bounce-greylisting-why = Сървърът на получателя моли непознатите податели да опитат отново малко по-късно, което е често срещана защита от спам.
bounce-greylisting-do = Изчакайте. Пощенските сървъри опитват отново автоматично и обикновено съобщението се доставя до един час.
bounce-server-error = Сървърът на получателя имаше проблем
bounce-server-error-why = Сървърът на получателя беше недостъпен или не можа да приеме съобщението заради собствен проблем.
bounce-server-error-do = Изпратете съобщението отново по-късно. Ако отново не успее, проверете за грешки в домейна след @.
bounce-unknown = Не е доставено
bounce-unknown-why = Известието не посочва ясно защо.
bounce-unknown-do = Отговорът на сървъра в „Подробности“ може да посочва причината. Ако не е ясен, препратете това известие на доставчика на пощата си.

## Several messages selected

selection-title = { $count ->
    [one] Избрано е 1 съобщение
   *[other] Избрани са { $count } съобщения
}
selection-unread = Непрочетени: { $count }
selection-flagged = С флаг: { $count }
delete-for-good-one = Това съобщение ще бъде изтрито окончателно. Да се изтрие ли?
delete-for-good-all = Тези { $count } съобщения ще бъдат изтрити окончателно. Да се изтрият ли?
delete-for-good-some = Предстои окончателно изтриване на { $count } от общо { $total } съобщения. Искате ли да продължите?
done-read = { $count ->
    [one] { $messages } е маркирано като прочетено
   *[other] { $messages } са маркирани като прочетени
}
done-unread = { $count ->
    [one] { $messages } е маркирано като непрочетено
   *[other] { $messages } са маркирани като непрочетени
}
done-flagged = { $count ->
    [one] { $messages } е маркирано с флаг
   *[other] { $messages } са маркирани с флаг
}
done-unflagged = Флагът е премахнат от { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } е изтрито окончателно
   *[other] { $messages } са изтрити окончателно
}
done-archived = { $count ->
    [one] { $messages } е архивирано
   *[other] { $messages } са архивирани
}
done-moved = { $count ->
    [one] { $messages } е преместено в { $folder }
   *[other] { $messages } са преместени в { $folder }
}
done-copied = { $count ->
    [one] { $messages } е копирано в { $folder }
   *[other] { $messages } са копирани в { $folder }
}
done-moving = { $count ->
   *[other] Преместване на { $messages } в { $folder }...
}
done-copying = { $count ->
   *[other] Копиране на { $messages } в { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } е върнато в { $folder }
   *[other] { $messages } са върнати в { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Разговорът се следи
   *[other] Следят се { $count } разговора
}
done-unwatched = { $count ->
    [one] Разговорът вече не се следи
   *[other] { $count } разговора вече не се следят
}
done-ignored = { $count ->
    [one] Разговорът се пренебрегва
   *[other] Пренебрегват се { $count } разговора
}
done-unignored = { $count ->
    [one] Разговорът вече не се пренебрегва
   *[other] { $count } разговора вече не се пренебрегват
}
their-folders = техните папки
undo-move = Отмяна на преместването
undo-delete = Отмяна на изтриването
undo-archive = Отмяна на архивирането
undo-junk = Отмяна на маркирането като нежелана поща
undo-not-junk = Отмяна на маркирането като желана поща
undo-send = Отмяна на изпращането
nothing-to-undo = Няма нищо за отмяна.
messages-gone = Съобщенията вече не са налични.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Тази папка не може да съдържа съобщения.
not-archived-here = Съобщенията в тази папка не могат да бъдат архивирани.
not-emptied-here = Могат да се изпразват само „Изтрити“ и „Нежелана поща“.
next-unread-question = В „{ $folder }“ няма повече непрочетени съобщения.

    Искате ли да отидете в „{ $next }“, следващата папка с непрочетени съобщения?
no-unread-left = Не са останали непрочетени съобщения.
empty-question = { $count ->
    [one] Да се изпразни ли „{ $folder }“?

        Съобщението в нея ще бъде изтрито окончателно. То не може да бъде възстановено.
   *[other] Да се изпразни ли „{ $folder }“?

        { $messages } в нея ще бъдат изтрити окончателно. Те не могат да бъдат възстановени.
}
no-junk-folder = Този акаунт няма папка „Нежелана поща“, в която да се преместят съобщенията.
no-inbox-folder = Този акаунт няма папка „Входящи“, в която да се преместят съобщенията.
# the status bar after a flag in a colour: "Flagged 2 messages blue"
done-flagged-color = Поставен флаг на { $messages }: { $color ->
    [red] червен
    [orange] оранжев
    [yellow] жълт
    [green] зелен
    [blue] син
    [purple] лилав
   *[gray] сив
}
# the Flag menu: the colours of Apple Mail's flags
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

move-window-title-move = { $count ->
    [one] Преместване на съобщението
   *[other] Преместване на { $count } съобщения
}
move-window-title-copy = { $count ->
    [one] Копиране на съобщението
   *[other] Копиране на { $count } съобщения
}
move-window-prompt-move = { $count ->
    [one] Преместване на избраното съобщение в:
   *[other] Преместване на { $count } избрани съобщения в:
}
move-window-prompt-copy = { $count ->
    [one] Копиране на избраното съобщение в:
   *[other] Копиране на { $count } избрани съобщения в:
}
# the folders used last, over the folder tree
targets-recent = Последно използвани
# the folder the messages are in, which can not be chosen
target-current = { $folder } (текуща)
# a folder used last, with its account when there are several: "Archive (Work)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Преместване на { $done } от { $messages } в { $folder }...
transfer-copying = Копиране на { $done } от { $messages } в { $folder }...
transfer-another-account = друг акаунт
transfer-folder-gone = целевата папка вече не съществува
transfer-not-on-server = съобщението вече не е на сървъра
transfer-not-moved = { $count ->
    [one] { $messages } не можа да бъде преместено в друг акаунт: { $reason }
   *[other] { $messages } не можаха да бъдат преместени в друг акаунт: { $reason }
}
transfer-not-copied = { $count ->
    [one] { $messages } не можа да бъде копирано в друг акаунт: { $reason }
   *[other] { $messages } не можаха да бъдат копирани в друг акаунт: { $reason }
}
transfer-none-moved = Нито едно съобщение не можа да бъде преместено
transfer-none-copied = Нито едно съобщение не можа да бъде копирано

## Messages as files

export-not-in-time = съобщението не можа да бъде изтеглено навреме
export-not-saved = Неуспешно запазване: { $failed } от { $messages } ({ $problems })
export-not-attached = съобщенията не можаха да бъдат прикачени: { $error }
# the status bar after Save As with several: "Saved 3 messages to Desktop"
saved-to = { $count ->
    [one] { $messages } е запазено в { $folder }
   *[other] { $messages } са запазени в { $folder }
}
download-progress = Изтегляне на { $done } от { $total }
download-done = Изтеглено: { $size }
downloading-messages = { $count ->
   *[other] Изтегляне на { $messages }...
}
# the status bar after files are dropped on a folder: "Put 3 messages in Archive"
import-put = { $count ->
    [one] { $messages } е поставено в { $folder }
   *[other] { $messages } са поставени в { $folder }
}
import-not-put = Неуспешно импортиране в папката:

    { $problems }

## Problems the windows show

error-store = локално хранилище: { $error }
error-not-found = не е намерено
error-closed = приложението се затваря
error-other-account = в браузъра влязохте в { $email }, а не в избрания акаунт
# a password or sign-in the mail server refused, with the server's words
failure-authentication = сървърът не прие влизането ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = връзката със сървъра не успя ({ $reason })
error-in-use = приложението не може да бъде премахнато, защото тези акаунти го използват за влизане: { $accounts }
error-turned-off = това приложение за влизане е изключено за нови акаунти
error-folder-name = името на папката трябва да е от 1 до 200 знака и не може да съдържа управляващи знаци
error-folder-separator = на този сървър името на папка не може да съдържа „{ $separator }“
error-folder-special = „Входящи“ и специалните папки не могат да бъдат преименувани или изтрити
error-no-recipients = съобщението няма получатели
error-bad-address = „{ $address }“ не е имейл адрес
error-not-own-address = { $address } не е сред адресите за изпращане на този акаунт. Добавете го в „Допълнителни адреси за изпращане“ в свойствата на акаунта.
rule-query-refused = Правилата не могат да филтрират по папка или дата ({ $words }).
rule-no-query = Въведете критерии за търсене за входящите съобщения.
rule-no-action = Изберете поне едно действие за правилото.
error-attachment = { $path } не можа да бъде прочетен: { $error }
error-no-drafts = акаунтът няма папка „Чернови“, в която да се запази съобщението
error-draft-attachment = прикачен файл на черновата не можа да бъде запазен: { $error }
error-password-not-saved = паролата не можа да бъде запазена за следващото стартиране: { $error }
error-sign-in-not-saved = новите данни за влизане не можаха да бъдат запазени за следващото стартиране: { $error }
error-import-unreadable = { $path } не може да бъде прочетен: { $error }
error-import-too-large = { $path } е по-голям от 50 МБ
error-import-not-mail = { $path } не е имейл съобщение
error-list-answered = сървърът на пощенския списък върна състояние { $status }
error-not-built = съобщението не можа да бъде съставено
error-outbox-waits = { $count ->
    [one] съобщението чака в „Изходящи“ и ще бъде изпратено при следващото изпращане и получаване
   *[other] { $count } съобщения чакат в „Изходящи“ и ще бъдат изпратени при следващото изпращане и получаване
}
error-draft-not-removed = предишната чернова на съобщението не можа да бъде премахната от „Чернови“: { $reason }
error-sent-but = съобщението беше изпратено, но { $problem }
error-sent-still-in-outbox = то все още е в „Изходящи“: { $error }
error-sent-no-copy = не можа да бъде запазено копие в „Изпратени“: { $reason }
error-no-password = няма парола за този акаунт
error-no-sign-in = няма данни за влизане за този акаунт
error-provider-missing = тази версия не може да използва { $provider } за влизане. Проверете дали приложението за влизане не е премахнато
error-provider-servers = сървърите на този акаунт не съвпадат със сървърите на приложението му за влизане
error-app-scopes = { $reason }. Пощенският сървър не прие маркера на приложението за влизане: проверете дали обхватите на приложението дават достъп до пощата
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google все още не е одобрил Inbox Classic за влизане, затова достъп имат само тестови потребители. Използвайте собствено приложение за влизане в Google или парола за приложение, ако акаунтът ви поддържа такава. Ако сте тестов потребител, можете да включите вграденото приложение в „Приложения за влизане“ (Файл > Акаунти).
sign-in-off-other = Приложението е изключено в „Приложения за влизане“ (Файл > Акаунти). Можете да го включите отново там.
sign-in-app-no-name = приложението за влизане трябва да има име
sign-in-app-no-client = липсва ИД на клиента
sign-in-app-no-scopes = приложението за влизане трябва да има обхватите, които дават достъп до пощата
sign-in-app-bad-host = адресът на сървъра { $server } липсва или не е валидно име на хост
sign-in-app-plain = сървърът { $server } трябва да използва SSL/TLS или STARTTLS
sign-in-app-not-checked = издателят все още не е проверен
sign-in-app-issuer-changed = издателят е променен: въведете отново тайната на клиента или я премахнете
sign-in-register-google = В Google Cloud Console създайте OAuth клиент от типа Desktop app с обхвата https://mail.google.com/ на екрана му за съгласие. Докато приложението е в тестов режим, в него могат да влизат само тестовите му потребители.
sign-in-register-microsoft = В Microsoft Entra регистрирайте приложение с платформата Mobile and desktop applications, URI за пренасочване http://localhost, разрешени потоци за публичен клиент и делегираните разрешения IMAP.AccessAsUser.All, SMTP.Send и offline_access. За достъп само от вашата организация използвайте https://login.microsoftonline.com/<ИД на организацията (tenant)>/v2.0 като издател.
sign-in-register-other = Регистрирайте собствен публичен клиент с посочения по-долу URI за пренасочване. Доставчикът трябва да допуска произволен порт за този URI (RFC 8252). Добавете необходимия обхват за достъп до пощата.

## Calendar invitations

repeats = Повторение
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
repeats-on = { $repeats }: { $days }
# "Every week, 10 times"
repeats-times = { $count ->
    [one] { $repeats }, веднъж
   *[other] { $repeats }, { $count } пъти
}
day-monday = понеделник
day-tuesday = вторник
day-wednesday = сряда
day-thursday = четвъртък
day-friday = петък
day-saturday = събота
day-sunday = неделя

## AI agents

agent-level-read = Четене на поща: преглед на папки и съобщения, търсене
agent-level-organize = Подреждане на поща: маркиране като прочетено, поставяне на флагове, нежелана поща, преместване и изтриване в „Изтрити“
agent-level-drafts = Писане на чернови, които вие изпращате
agent-level-send = Изпращане на поща: всяко съобщение изисква вашето потвърждение
agent-connect-title = { $program } иска да използва пощата ви
agent-connect-detail = ИИ агент поиска достъп до Inbox Classic. Изберете разрешените действия и акаунти. Можете да промените разрешенията по-късно от Инструменти > ИИ агенти.

    Агентите четат поща от други хора, която може да съдържа подвеждащи инструкции. Inbox Classic винаги иска вашето потвърждение, преди да изпрати съобщение по заявка на агент.
agent-reply-to = Отговор на „{ $subject }“
agent-reply-all-on = Отговор до всички на „{ $subject }“
agent-forward-of = Препращане на „{ $subject }“
agent-never-written-one = Никога не сте писали на { $address }.
agent-never-written-many = Никога не сте писали на { $count } от тези адреси.
agent-send-title = { $program } иска да изпрати това съобщение
agent-send-detail = Проверете получателите и съдържанието на съобщението. След като потвърдите, съобщението чака { $seconds } секунди в „Изходящи“, където все още можете да го изтриете.
agent-change-title = Какво може да прави { $program }
agent-change-allowed = Променете какво могат да правят с пощата ви ИИ агентите на тази програма.
agent-change-refused = Отказахте достъп на тази програма. Разрешете го, за да дадете отново на агентите ѝ достъп до пощата ви.
agent-log-taken-back = Отменено действие: { $entry }
agent-files = Файлове: { $files }
agent-undo-refused = Това действие не може да бъде отменено.
agent-undo-refused-why = Това действие не може да бъде отменено: { $reason }.
agent-undo-impossible = това не може да бъде отменено
agent-undo-not-in-folder = съобщението вече не е в тази папка
agent-undo-not-arrived = съобщението все още не е в целевата папка
agent-undo-sent = съобщението вече не е в „Изходящи“
agent-original-not-downloaded = оригиналното съобщение все още не е изтеглено. Първо го отворете
agent-turned-away = Отказан достъп
agent-can-nothing = Нищо
agent-can-read = четене
agent-can-organize = подреждане
agent-can-drafts = писане на чернови
agent-can-send = изпращане с ваше съгласие
# "Read, organize and write drafts"
agent-can-list = { $first } и { $last }
agent-accounts = { $count ->
    [0] нито един акаунт
    [one] 1 акаунт
   *[other] { $count } акаунта
}
# "Read and organize; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Това съобщение не може да бъде прочетено.
agent-encrypted-original = Това съобщение е шифровано: агент не може да отговори на него или да го препрати, тъй като не може да шифрова.
agent-encrypted = Това съобщение е шифровано. Агентите с ИИ не могат да прочетат съдържанието му. Потребителят трябва да го отвори в Inbox Classic.
list-encrypted = Шифровано съобщение
agent-log-composed = Отворено за довършване: „{ $subject }“
agent-log-refused = Отказано изпращане: „{ $subject }“
agent-log-sent = Добавено в опашката за изпращане до { $to }: „{ $subject }“
agent-log-draft = Черновата „{ $subject }“ е запазена
agent-log-read = Маркирано като прочетено: „{ $subject }“
agent-log-unread = Маркирано като непрочетено: „{ $subject }“
agent-log-flagged = Маркирано с флаг: „{ $subject }“
agent-log-unflagged = Флагът на „{ $subject }“ е премахнат
agent-log-deleted = Преместено в „Изтрити“: „{ $subject }“
agent-log-moved = Преместено в „{ $folder }“: „{ $subject }“
agent-log-junk = Маркирано като нежелана поща: „{ $subject }“
agent-log-not-junk = Маркирано като желана поща: „{ $subject }“
agent-log-archived = Архивирано: „{ $subject }“
agent-log-folder = Създадена е папката „{ $name }“
agent-log-unsubscribed = Изпратена заявка за отписване от пощенския списък на „{ $subject }“

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = доставчикът не даде маркер за опресняване
sign-in-no-account = доставчикът не посочи кой акаунт е влязъл
sign-in-not-finished = влизането не е завършило
secrets-unavailable = { $store } не е достъпен
secrets-unavailable-why = { $store } не е достъпен: { $error }
secrets-windows = Диспечер на идентификационни данни
secrets-mac = Ключодържател
secrets-linux = Системен ключодържател (Secret Service)
error-no-such-file = няма такъв файл
cards-file-too-big = Този файл е твърде голям, за да бъде адресна книга.
ui-sender-added = Добавено в адресната книга: { $name }.
ui-sender-known = { $name } вече е в адресната книга.
ui-sender-none = Подателят на това съобщение няма имейл адрес, който да бъде добавен.
card-name-needed = Контактът няма име и имейл адрес.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Код от { $domain }
otp-copy = Копиране
otp-note = Въвеждайте го само на страница на { $domain }.
otp-old = Този код е изпратен повече от час преди отварянето на съобщението и вероятно вече е невалиден.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } участник
       *[other] { $count } участници
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } е кодът ви за { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Валиден
pgp-key-expires = Валиден до { $date }
pgp-key-expired = Изтекъл на { $date }
pgp-key-revoked = Отменен
pgp-key-revoked-why = Отменен: { $reason }
pgp-key-not-valid = Невалиден
pgp-key-locked = Този частен ключ не може да се използва, защото защитният ключ вече липсва от { $store }. Възстановете частния ключ от резервното му копие.
pgp-source-own = Създаден в Inbox Classic
pgp-source-file = Импортиран от файл
pgp-source-paste = Поставен от клипборда
pgp-source-attachment = От съобщение
pgp-source-vcard = От визитка на контакт
pgp-source-wkd = От доставчика на поща на подателя
pgp-source-keyserver = От keys.openpgp.org
pgp-source-autocrypt = От заглавката Autocrypt на съобщение
pgp-error-no-store = Хранилището { $store } е необходимо за защитата на частните ключове, но е недостъпно: { $error }
pgp-error-wrong-passphrase = Фразата за достъп е грешна.
pgp-error-not-a-key = Това не е OpenPGP ключ.
pgp-error-too-large = Ключът е твърде голям.
pgp-error-unusable = Ключът използва стара или слаба криптография и не може да бъде използван.
pgp-imported-private = { $count ->
    [one] Частният ви ключ е импортиран.
   *[other] Импортирани са { $count } частни ключа.
}
pgp-imported-public = { $count ->
    [one] Импортиран е един ключ.
   *[other] Импортирани са { $count } ключа.
}
pgp-imported-pending = За тези адреси вече се използва друг ключ: { $addresses }. Новият е запазен в данните на контакта; изберете го там, за да го използвате.
pgp-error-needs-passphrase = Частният ключ е защитен с фраза за достъп. Въведете я, за да импортирате ключа.
pgp-error-mismatch = Частният ключ не съответства на публичния. Възможно е ключът да е бил подменен.
pgp-file-name-public = Публичен ключ на { $who }.asc
pgp-file-name-private = Резервно копие на частния ключ на { $who }.asc
pgp-pending = На { $date } беше намерен друг ключ за { $address }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Подписано от { $signer }, ключът е потвърден
pgp-part-signed = Подписано от { $signer } (ключът не е потвърден)
pgp-part-other = Подписано от лице, различно от подателя: { $signer }
pgp-part-unknown-key = Подписано, но ключът не е известен
pgp-part-not-signed = Не е подписано
pgp-part-not-checked = Подписът не е проверен
pgp-part-encrypted = Шифровано. { $signature }
pgp-part-no-key = Липсва частен ключ за дешифриране
pgp-part-changed = Шифрованата част е променена при пренасянето и не се показва
pgp-part-unprotected = Шифровано без защита срещу промени, не се показва
pgp-part-broken = Шифрованата част не може да бъде прочетена
pgp-why-mismatch = Подписът не съответства на този текст
pgp-why-weak-hash = Подписът използва { $hash }, който вече не е сигурен
pgp-why-key-expired = Подписано, след като ключът е изтекъл на { $date }
pgp-why-key-revoked = Подписано с ключ, който е бил отменен
pgp-why-not-signing-key = Подписано с ключ, който не е предназначен за подписване
pgp-why-from-future = Подписът е с дата в бъдещето
pgp-why-signature-expired = Подписът е изтекъл
pgp-why-key-not-valid = Подписано с ключ, който не е валиден
pgp-why-not-for-you = Подписано за други получатели и препратено до вас
pgp-why-not-key-in-use = Подписано с ключ, различен от използвания за { $address }
pgp-part-pictures-loaded = { $label }. Изображенията са заредени от интернет
pgp-error-no-own-key = Нямате ключ за { $address }, с който да подписвате или шифровате. Създайте такъв в Инструменти > Ключове за шифроване или изключете „Подписване“ и „Шифроване“.
pgp-error-missing-keys = { $count ->
    [one] Липсва ключ за шифроване за получателя: { $addresses }.
   *[other] Липсват ключове за шифроване за получателите: { $addresses }.
}
pgp-error-encrypted-quote = Това съобщение цитира или препраща шифровано съобщение, затова може да бъде изпратено само шифровано. Включете „Шифроване“ или премахнете цитирания текст.
pgp-error-protect = Съобщението не можа да бъде подписано или шифровано: { $reason }
pgp-found-keys = Намерени ключове за: { $addresses }.
pgp-found-none = Не са намерени ключове за: { $addresses }. Поискайте публичен ключ за всеки адрес.
pgp-found-no-key = Не е намерен ключ.
pgp-find-unavailable = В момента не може да се търсят ключове: { $error }
pgp-publish-pending = keys.openpgp.org изпрати връзки за потвърждение до: { $addresses }. Потвърдете всеки адрес, за да може ключът ви да бъде намерен чрез него.
pgp-publish-done = Ключът ви е публикуван в keys.openpgp.org за { $addresses }.
pgp-publish-failed = Ключът не можа да бъде публикуван: { $error }
pgp-keyserver-off = Търсенето на ключове в keys.openpgp.org е изключено в { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Съобщението ще бъде шифровано и подписано при изпращане. Само вие и { $addresses } ще можете да прочетете съдържанието.
   *[other] Съобщението ще бъде шифровано и подписано при изпращане. Само вие и { $count } получатели ще можете да прочетете съдържанието.
}
pgp-compose-encrypt-ready = Съобщението ще бъде шифровано и подписано при изпращане. Добавете получатели, за които имате използваеми ключове.
pgp-compose-missing = { $count ->
    [one] Няма използваем ключ за този получател: { $addresses }. Съобщението все още не може да се шифрова.
   *[other] Няма използваеми ключове за { $count } получатели: { $addresses }. Съобщението все още не може да се шифрова.
}
pgp-compose-looking = Търсене на ключовете на { $addresses }...
pgp-compose-signed = Съобщението ще бъде подписано цифрово при изпращане. Получателите ще могат да проверят подписа и дали съдържанието е променено.
pgp-compose-reply-clear = Не е шифровано, въпреки че оригиналното съобщение е било шифровано.
pgp-compose-encrypted-files = Съобщението съдържа прикачени файлове от шифровано съобщение и може да се изпрати само шифровано. Включете „Шифроване“ или премахнете тези прикачени файлове.
pgp-compose-sign-tip = Цифрово подписване на съобщението при изпращане, за да могат получателите да проверят подписа и дали съдържанието е променено
pgp-compose-sign-tip-encrypted = Шифрованите съобщения винаги се подписват при изпращане
pgp-compose-encrypt-tip = Шифроване на съдържанието при изпращане, така че само вие и получателите да можете да го прочетете
pgp-compose-make-key = Все още не сте настроили собствен ключ за адреса { $address }. Искате ли да създадете ключ сега? С него можете да подписвате и шифровате съобщения.
pgp-compose-key-unusable = Ключът ви за адреса { $address } не може да се използва. Причина: { $state }
    Отворете „Ключове за шифроване“, за да импортирате резервно копие на този ключ или да създадете нов.
pgp-compose-encrypt-off-quote = В съобщението все още има текст, изображения или прикачени файлове от шифровано съобщение. Премахнете ги, за да го изпратите без шифроване. Искате ли въпреки това да изключите шифроването?
pgp-compose-encrypt-off-reply = Оригиналното съобщение е било шифровано. Ако изпратите отговора или препратеното съобщение без шифроване, пощенските сървъри ще могат да прочетат съдържанието. Искате ли да изключите шифроването?
pgp-recipient-verified = Ключът е потвърден
pgp-recipient-found = Ключът не е потвърден
pgp-recipient-own = Вашият собствен ключ
pgp-recipient-looking = Търсене на ключ...
pgp-recipient-missing = Няма ключ
pgp-recipient-not-found = Не е намерен ключ. Последно търсене: { $date }
pgp-recipient-unusable = Ключът не може да бъде използван: { $state }
pgp-recipients-intro = Съобщението ще бъде шифровано с ключовете на получателите и с вашия ключ.
pgp-recipients-intro-missing = { $count ->
    [one] За един получател няма използваем ключ. Намерете ключа му или премахнете получателя от съобщението. Можете да изпратите без шифроване само ако в съобщението няма текст, изображения или прикачени файлове от шифровани съобщения.
   *[other] За { $count } получатели няма използваеми ключове. Намерете ключовете им или премахнете тези получатели от съобщението. Можете да изпратите без шифроване само ако в съобщението няма текст, изображения или прикачени файлове от шифровани съобщения.
}
pgp-details-part = Част { $number }: { $label }
pgp-details-signed = Подписано на { $when } с ключа { $key }
pgp-details-unknown-key = Подписано с ключа { $key }, който нямате
pgp-details-opened = Дешифрирано с вашия ключ { $key }
pgp-details-for = Шифровано за { $keys }
pgp-details-plain = Нито подписано, нито шифровано
pgp-bar-parts = Това съобщение има { $count } части: { $list }. Всяка част показва как е защитена.
pgp-bar-count-verified = потвърдени: { $count }
pgp-bar-count-good = { $count ->
    [one] 1 подписана или шифрована
   *[other] { $count } подписани или шифровани
}
pgp-bar-count-warning = { $count ->
    [one] 1 изисква внимание
   *[other] { $count } изискват внимание
}
pgp-bar-count-neutral = без потвърден подпис: { $count }
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Настройки
setup-part-preferences = Предпочитания за прозорците
setup-part-accounts = Акаунти
setup-part-sign-in-apps = Приложения за влизане
setup-part-contacts = Контакти и групи
setup-part-keys = Ключове за шифроване
setup-part-rules = Правила за съобщения
setup-part-trusted-senders = Доверени податели
setup-holds-settings = { $count ->
    [one] 1 настройка
   *[other] { $count } настройки
}
setup-holds-preferences = { $count ->
    [one] 1 предпочитание
   *[other] { $count } предпочитания
}
setup-holds-accounts = { $count ->
    [one] 1 акаунт
   *[other] { $count } акаунта
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 приложение за влизане
   *[other] { $count } приложения за влизане
}
setup-holds-built-in = Кои вградени приложения за влизане са включени
setup-holds-contacts = { $count ->
    [one] 1 контакт
   *[other] { $count } контакта
}
setup-holds-groups = { $count ->
    [one] 1 група
   *[other] { $count } групи
}
setup-holds-own-keys = { $count ->
    [one] 1 ваш ключ
   *[other] { $count } ваши ключа
}
setup-holds-contact-keys = { $count ->
    [one] 1 ключ на контакт
   *[other] { $count } ключа на контакти
}
setup-holds-rules = { $count ->
    [one] 1 правило
   *[other] { $count } правила
}
setup-holds-trusted-senders = { $count ->
    [one] 1 доверен подател
   *[other] { $count } доверени податели
}
setup-sign-in-password = Парола
setup-account-secret-password = Паролата му е във файла.
setup-account-secret-token = Данните му за влизане са във файла.
setup-account-asks-password = След импортирането ще трябва да въведете паролата за акаунта.
setup-account-signs-in-again = След импортирането ще трябва да влезете отново в акаунта.
setup-account-here = Вече е настроен тук, затова се пропуска.
setup-account-no-app = За влизане се използва приложението { $app }, което не е настроено тук. Импортирайте и приложенията за влизане.
setup-invalid-address = „{ $address }“ не е имейл адрес.
setup-invalid-server = Невалидно име или порт на сървъра { $server }.
setup-invalid-user = Няма потребителско име.
setup-invalid-sign-in = Акаунтът използва начин за влизане, който Inbox Classic не поддържа.
setup-error-empty = Файлът е празен.
setup-error-too-large = Файлът е твърде голям, за да бъде файл с настройки и акаунти на Inbox Classic.
setup-error-not-setup = Това не е файл с настройки и акаунти на Inbox Classic.
setup-error-damaged = Файлът с настройките е повреден и не може да бъде прочетен.
setup-error-newer = Тези настройки са запазени от по-нова версия на Inbox Classic ({ $version }). Обновете Inbox Classic и ги импортирайте отново.
setup-error-needs-passphrase = Файлът с настройки е защитен с фраза за достъп. Въведете фразата, използвана при запазването му.
setup-error-wrong-passphrase = Фразата за достъп не съвпада с използваната при запазването на файла.
setup-error-changed = Файлът с настройките е бил променен или повреден след запазването, затова не може да бъде импортиран.
setup-error-read = Файлът с настройките не можа да бъде прочетен: { $error }
setup-error-write = Настройките не можаха да бъдат запазени: { $error }
setup-error-no-parts = Изберете поне една категория.
setup-left-out = { $count ->
    [one] 1 запис от „{ $part }“ не може да бъде използван и е пропуснат.
   *[other] { $count } записа от „{ $part }“ не могат да бъдат използвани и са пропуснати.
}
setup-imported-settings = Настройките бяха заменени.
setup-imported-preferences = Предпочитанията за прозорците бяха заменени.
setup-added-accounts = { $count ->
    [one] Добавен е 1 акаунт.
   *[other] Добавени са { $count } акаунта.
}
setup-skipped-here = { $address } вече е настроен тук, затова беше пропуснат.
setup-skipped-no-app = Акаунтът { $address } е пропуснат: приложението { $app }, което използва за влизане, не е настроено тук.
setup-skipped-invalid = { $address } беше пропуснат: { $reason }
setup-asks-password = При свързване с акаунта { $address } ще трябва да въведете паролата му.
setup-signs-in-again = При свързване с акаунта { $address } ще трябва да влезете отново.
setup-added-sign-in-apps = { $count ->
    [one] Добавено е 1 приложение за влизане.
   *[other] Добавени са { $count } приложения за влизане.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 приложение за влизане вече е настроено тук.
   *[other] { $count } приложения за влизане вече са настроени тук.
}
setup-added-contacts = { $count ->
    [one] Добавен е 1 контакт в адресната книга.
   *[other] Добавени са { $count } контакта в адресната книга.
}
setup-skipped-contacts = { $count ->
    [one] 1 контакт вече е в адресната книга.
   *[other] { $count } контакта вече са в адресната книга.
}
setup-added-groups = { $count ->
    [one] Добавена или допълнена е 1 група.
   *[other] Добавени или допълнени са { $count } групи.
}
setup-added-own-keys = { $count ->
    [one] Добавен е 1 ваш ключ.
   *[other] Добавени са { $count } ваши ключа.
}
setup-added-contact-keys = { $count ->
    [one] Добавен е 1 ключ на контакт.
   *[other] Добавени са { $count } ключа на контакти.
}
setup-added-rules = { $count ->
    [one] Добавено е 1 правило за съобщения.
   *[other] Добавени са { $count } правила за съобщения.
}
setup-skipped-rules = { $count ->
    [one] 1 правило за съобщения вече е тук.
   *[other] { $count } правила за съобщения вече са тук.
}
setup-skipped-rules-account = { $count ->
    [one] 1 правило за съобщения е за акаунт, който не е тук, затова беше пропуснато.
   *[other] { $count } правила за съобщения са за акаунти, които не са тук, затова бяха пропуснати.
}
setup-rules-waiting = { $count ->
    [one] 1 правило за съобщения премества съобщения в папка, която ще се появи, когато акаунтът ѝ се синхронизира.
   *[other] { $count } правила за съобщения преместват съобщения в папки, които ще се появят, когато акаунтите им се синхронизират.
}
setup-added-trusted-senders = { $count ->
    [one] Добавен е 1 доверен подател.
   *[other] Добавени са { $count } доверени податели.
}
setup-nothing = Нищо не беше импортирано.
setup-account-servers = { $imap } и { $smtp } ({ $signin })
setup-file-name = Настройки и акаунти на Inbox Classic
setup-skipped-unreachable = Приложението { $name } е пропуснато, защото услугата му за влизане е недостъпна. Добавете го отново в „Приложения за влизане“.
attachment-runs-programs = Файлът „{ $name }“ може да изпълнява програмен код, затова Inbox Classic не го отваря. Можете да го запазите и да го отворите сами, ако имате доверие на източника му.
attachment-decrypted-note = Този прикачен файл е от шифровано съобщение. За да го отвори с друга програма, Inbox Classic запазва нешифровано копие във временна папка за вашия потребителски акаунт. При стартиране на Inbox Classic се изтриват копията, по-стари от един ден.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Сървърът не премести { $messages } в папка „{ $folder }“, затова съобщението отново е в папка „{ $from }“: { $reason }
   *[other] Сървърът не премести { $messages } в папка „{ $folder }“, затова съобщенията отново са в папка „{ $from }“: { $reason }
}
undone-delete = { $count ->
    [one] Сървърът не изтри { $messages }, затова съобщението отново е в папка „{ $from }“: { $reason }
   *[other] Сървърът не изтри { $messages }, затова съобщенията отново са в папка „{ $from }“: { $reason }
}
undone-archive = { $count ->
    [one] Сървърът не архивира { $messages }, затова съобщението отново е в папка „{ $from }“: { $reason }
   *[other] Сървърът не архивира { $messages }, затова съобщенията отново са в папка „{ $from }“: { $reason }
}
undone-read = { $count ->
    [one] Сървърът не маркира { $messages } като прочетено, затова съобщението отново е непрочетено: { $reason }
   *[other] Сървърът не маркира { $messages } като прочетени, затова съобщенията отново са непрочетени: { $reason }
}
undone-unread = { $count ->
    [one] Сървърът не маркира { $messages } като непрочетено, затова съобщението отново е прочетено: { $reason }
   *[other] Сървърът не маркира { $messages } като непрочетени, затова съобщенията отново са прочетени: { $reason }
}
undone-flags = { $count ->
    [one] Сървърът не промени флаговете на { $messages }, затова промяната е отменена: { $reason }
   *[other] Сървърът не промени флаговете на { $messages }, затова промяната е отменена: { $reason }
}
