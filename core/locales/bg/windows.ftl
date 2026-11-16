# Български. Чернова, очаква преглед от носител на езика (вж. core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic продължава да проверява за нова поща във фонов режим. Щракнете върху иконата, за да я отворите. За изход щракнете с десния бутон върху иконата и използвайте менюто ѝ.
# review: new
win-default-app-not-installed = Това копие на Inbox Classic не е инсталирано, затова Windows не го показва като пощенска програма. Инсталирайте го, за да го изберете.
# review: new
win-default-app-settings = Windows ще отвори настройките за приложения по подразбиране. Изберете Inbox Classic, за да се отварят MAILTO връзките.
# review: new
win-no-unread = Няма непрочетени съобщения
# review: new
win-unread-messages = { $count ->
    [one] 1 непрочетено съобщение
   *[other] { $count } непрочетени съобщения
}
# review: new
win-print-failed = Съобщението не можа да бъде отпечатано.
# review: new
win-print-title-of = Печат: { $subject }
# review: new
win-no-bodies = Текстът на съобщенията не може да бъде показан.
# review: new
win-webview-failed = Създаването на WebView2 не успя.
# review: new
win-webview-missing = Средата за изпълнение WebView2 не е налична.

## Buttons and words used in many windows

# review: new
win-delete-button = &Изтриване
# review: new
win-find-label = &Търсене:
# review: new
win-save-as-button = &Запазване като...
# review: new
win-too-many-files = Твърде много файлове наведнъж: изберете по-малко.

## The Outbox


## The compose window

# review: new
win-editor-failed = Не могат да се пишат съобщения.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+щракване за отваряне)
# review: new
win-format-bold = Удебелен ({ $ctrl }+B)
# review: new
win-format-italic = Курсив ({ $ctrl }+I)
# review: new
win-format-underline = Подчертан ({ $ctrl }+U)
# review: new
win-format-link = Хипервръзка ({ $ctrl }+K)
# review: new
win-show-cc = &Копие
# review: new
win-show-bcc = &Скрито копие
# review: new
win-signature-title = Подпис: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Няма резултати за „{ $words }“ във всички папки
    [one] { $count } резултат за „{ $words }“ във всички папки
   *[other] { $count } резултата за „{ $words }“ във всички папки
}
# review: new
win-search-found-in = { $count ->
    [0] Няма резултати за „{ $words }“ в { $folder }
    [one] { $count } резултат за „{ $words }“ в { $folder }
   *[other] { $count } резултата за „{ $words }“ в { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] текстът на { $count } съобщение все още се индексира
   *[other] текстът на { $count } съобщения все още се индексира
}
# review: new
win-no-match-indexing = { $count ->
    [one] Текстът на { $count } съобщение все още се индексира, затова скоро може да бъдат намерени още.
   *[other] Текстът на { $count } съобщения все още се индексира, затова скоро може да бъдат намерени още.
}
# review: new
win-files = { $count ->
    [one] { $count } файл
   *[other] { $count } файла
}
# review: new
win-click-to-retry = Щракнете тук, за да опитате отново.
# review: new
win-save-attachments = &Запазване на прикачените файлове...
# review: new
win-files-not-saved = { $failed } от { $count } файла не можаха да бъдат запазени.
# review: new
win-new-folder-in-highlighted = Новата папка ще бъде създадена в избраната папка.
# review: new
win-delete-folder-ask = Да се изтрие ли папката „{ $folder }“ заедно със съобщенията и папките в нея? Тя се изтрива и на сървъра.
# review: new
win-rename = &Преименуване...
# review: new
win-messages-not-saved = Съобщенията не можаха да бъдат запазени.
# review: new
win-messages-not-forwarded = Съобщенията не можаха да бъдат препратени.

## Accounts

# review: new
win-sign-in-google = Вход с Google
# review: new
win-sign-in-microsoft = Вход с Microsoft
# review: new
win-next = &Напред >
# review: new
win-your-account = вашия акаунт
# review: new
win-browser-sign-in = (влизане чрез браузъра)
# review: new
win-add = &Добавяне...
# review: new
win-properties-button = &Свойства...
# review: new
win-signature-button = &Подпис...
# review: new
win-sign-in-apps-button = Приложения за &влизане...

## AI agents

# review: new
win-dont-allow = &Не разрешавам
# review: new
win-col-address = Адрес
# review: new
win-never-written-to = Никога не сте писали
# review: new
win-book-find-label = Въведете име или имейл адрес:
# review: new
win-send = &Изпращане
# review: new
win-dont-send = &Не изпращай
# review: new
win-forget-program-ask = Да се премахне ли тази програма, разрешенията ѝ и историята на действията на агентите ѝ? Следващия път, когато се свърже, ще бъдете попитани отново за разрешение.
# review: new
win-clear-log-ask = Да се изчисти ли историята на действията на агентите? Това няма да отмени промените, направени от агентите.
# review: new
win-agent-programs = &Програми, чиито агенти са поискали достъп до пощата ви:
# review: new
win-change = Про&мяна...
# review: new
win-what-agents-did = &Действия на агентите:
# review: new
win-how-to-connect = Как да свържете агент

## Sign-in apps

# review: new
win-built-in = (вградено)
# review: new
win-edit = &Редактиране...

## Options

# review: new
win-options-language-label = &Език на Inbox Classic:
# review: new
win-options-restart-note = Рестартирайте Inbox Classic, за да смените езика.
# review: new
win-options-notify = &Уведомяване при пристигане на нова поща
# review: new
win-restart-ask = Inbox Classic ще се покаже на { $language } след рестартиране. Да се рестартира ли сега?
# review: new
win-folders-hide = Скриване на списъка с папки
# review: new
win-folders-pin = Списъкът с папки да стои до съобщенията
# review: new
win-folders-show = Показване на папките

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Стартиране на Inbox Classic
# review: new
win-installer-welcome-new =
    Това ще инсталира Inbox Classic { $version }, програма за електронна поща.

    Не са нужни администраторски права, програмата се инсталира само за вашия акаунт.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } вече е инсталирана. Това ще я инсталира отново.

    Акаунтите и пощата ви се запазват.
# review: new
win-installer-welcome-update =
    Това ще обнови Inbox Classic { $installed } до { $version }.

    Ако програмата работи, тя първо ще бъде затворена. Акаунтите и пощата ви се запазват.
# review: new
win-installer-older-ask = Инсталирана е Inbox Classic { $installed }, която е по-нова от { $version }. Да се инсталира ли все пак по-старата версия?
# review: new
win-installer-still-running = Inbox Classic все още работи. Затворете я и опитайте отново.
# review: new
win-installer-remove-mail-ask = Да се премахнат ли и акаунтите и пощата, които Inbox Classic пази на този компютър? Пощата на сървърите остава.
