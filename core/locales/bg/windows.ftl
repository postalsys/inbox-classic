# Български. Чернова, очаква преглед от носител на езика (вж. core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic продължава да проверява за нова поща във фонов режим. Щракнете върху иконата ѝ в областта за уведомяване, за да отворите прозореца. За изход щракнете с десния бутон върху иконата и използвайте менюто ѝ.
win-default-app-not-installed = Това копие на Inbox Classic не е инсталирано, затова Windows не го показва като пощенска програма. Инсталирайте го, за да го изберете.
win-default-app-settings = Windows ще отвори настройките за приложения по подразбиране. Изберете Inbox Classic за отваряне на имейл връзки (MAILTO).
win-no-unread = Няма непрочетени съобщения
win-unread-messages = { $count ->
    [one] 1 непрочетено съобщение
   *[other] { $count } непрочетени съобщения
}
win-print-failed = Съобщението не можа да бъде отпечатано.
win-print-title-of = Печат: { $subject }
win-no-bodies = Текстът на съобщенията не може да бъде показан.
win-webview-failed = Компонентът WebView2 не можа да бъде стартиран.
win-webview-missing = Средата за изпълнение WebView2 не е налична.
win-list-loading = Зареждане...

## Buttons and words used in many windows

win-delete-button = &Изтриване
win-find-label = &Търсене:
win-save-as-button = Запазване ка&то...
win-too-many-files = Твърде много файлове наведнъж: изберете по-малко.

## The Outbox


## The compose window

win-editor-failed = Редакторът за съобщения не можа да бъде отворен.
win-ctrl-click-to-open = ({ $ctrl }+щракване за отваряне)
win-format-bold = Удебелен ({ $ctrl }+B)
win-format-italic = Курсив ({ $ctrl }+I)
win-format-underline = Подчертан ({ $ctrl }+U)
win-format-link = Хипервръзка ({ $ctrl }+K)
win-show-cc = &Копие
win-show-bcc = &Скрито копие
win-signature-title = Подпис: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Няма резултати за „{ $words }“ във всички папки
    [one] { $count } резултат за „{ $words }“ във всички папки
   *[other] { $count } резултата за „{ $words }“ във всички папки
}
win-search-found-in = { $count ->
    [0] Няма резултати за „{ $words }“ в „{ $folder }“
    [one] { $count } резултат за „{ $words }“ в „{ $folder }“
   *[other] { $count } резултата за „{ $words }“ в „{ $folder }“
}
win-search-indexing = { $count ->
    [one] текстът на { $count } съобщение все още се индексира
   *[other] текстът на { $count } съобщения все още се индексира
}
win-no-match-indexing = { $count ->
    [one] Текстът на { $count } съобщение все още се индексира, затова скоро може да се появят още резултати.
   *[other] Текстът на { $count } съобщения все още се индексира, затова скоро може да се появят още резултати.
}
win-files = { $count ->
    [one] { $count } файл
   *[other] { $count } файла
}
win-click-to-retry = Щракнете тук, за да опитате отново.
win-save-attachments = &Запазване на прикачените файлове...
win-files-not-saved = Неуспешно запазване: { $failed } от общо { $count } файла.
win-new-folder-in-highlighted = Новата папка ще бъде създадена в избраната папка.
win-delete-folder-ask = Да се изтрие ли папката „{ $folder }“ заедно със съобщенията и папките в нея? Тя се изтрива и на сървъра.
win-rename = &Преименуване...
win-messages-not-saved = Съобщенията не можаха да бъдат запазени.
win-messages-not-forwarded = Съобщенията не можаха да бъдат препратени.

## Accounts

win-sign-in-google = Вход с Google
win-sign-in-microsoft = Вход с Microsoft
win-next = &Напред >
win-your-account = вашия акаунт
win-browser-sign-in = (влизане чрез браузъра)
win-add = &Добавяне...
win-properties-button = &Свойства...
win-signature-button = &Подпис...
win-sign-in-apps-button = Приложения за &влизане...

## AI agents

win-dont-allow = &Не разрешавам
win-col-address = Адрес
win-never-written-to = Никога не сте писали
win-book-find-label = Въведете име или имейл адрес:
win-send = &Изпращане
win-dont-send = &Не изпращай
win-unsubscribe = &Отписване
win-dont-unsubscribe = &Без отписване
win-forget-program-ask = Искате ли да премахнете тази програма, разрешенията ѝ и историята на действията на агентите ѝ? При следващ опит за свързване отново ще бъдете попитани за разрешение.
win-clear-log-ask = Да се изчисти ли историята на действията на агентите? Това няма да отмени промените, направени от агентите.
win-agent-programs = &Програми, чиито агенти са поискали достъп до пощата ви:
win-change = Пром&яна...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
win-undo-since = Отмяна &за период...
# review: new
win-take-back = &Отмяна
win-what-agents-did = &Действия на агентите:
# review: new
win-agent-reads = Прочетено от { $from } до { $to }:
# review: new
win-agent-reads-hint = Изберете по-горе ред с прочетеното, за да видите какво е прочетено.
win-how-to-connect = Как да свържете агент

## Sign-in apps

win-built-in = (вградено)
win-edit = &Редактиране...

## Options

win-folders-hide = Скриване на списъка с папки
win-folders-pin = Постоянно показване на папките до съобщенията
win-folders-show = Показване на папките

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Стартиране на Inbox Classic
win-installer-welcome-new =
    Ще бъде инсталирана Inbox Classic { $version }, програма за електронна поща.

    Не са нужни администраторски права. Програмата се инсталира само за вашия потребителски акаунт в Windows.
win-installer-welcome-same =
    Inbox Classic { $version } вече е инсталирана. Ще бъде извършено повторно инсталиране.

    Акаунтите и пощата ви се запазват.
win-installer-welcome-update =
    Inbox Classic ще бъде обновена от версия { $installed } до { $version }.

    Ако програмата работи, първо ще бъде затворена. Акаунтите и пощата ви се запазват.
win-installer-older-ask = Инсталирана е Inbox Classic { $installed }, която е по-нова от { $version }. Да се инсталира ли все пак по-старата версия?
win-installer-still-running = Inbox Classic все още работи. Затворете я и опитайте отново.
win-installer-remove-mail-ask = Искате ли да премахнете и акаунтите и локалните копия на пощата, запазени от Inbox Classic на този компютър? Пощата на сървърите се запазва.
