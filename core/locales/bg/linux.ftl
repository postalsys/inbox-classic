# Български. Чернова, очаква преглед от носител на езика (вж. core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Настройки, Изход).

## The main window

gtk-search-looks-in = Търсенето в { $place } обхваща темите, подателите, получателите, имената на прикачените файлове и текста на съобщенията. Проверете правописа или опитайте с по-малко думи.
gtk-search-still-indexing = { $count ->
    [one] Текстът на 1 съобщение все още се индексира. Скоро може да се появят още резултати.
   *[other] Текстът на { $count } съобщения все още се индексира. Скоро може да се появят още резултати.
}
gtk-search-results-everywhere = { $count ->
    [0] Няма резултати
    [one] 1 резултат
   *[other] { $count } резултата
} за „{ $words }“ във всички папки
gtk-search-results-in = { $count ->
    [0] Няма резултати
    [one] 1 резултат
   *[other] { $count } резултата
} за „{ $words }“ в { $place }
gtk-search-indexing = { $count ->
    [one] текстът на 1 съобщение все още се индексира
   *[other] текстът на { $count } съобщения все още се индексира
}
gtk-menu-rename = Преименуване...
gtk-import-one-question = Да се импортира ли съобщението { $file } в { $folder }?
gtk-files-not-saved = Неуспешно запазване: { $failed } от общо { $total } файла.
gtk-unsubscribe-one-click =
    Искате ли да се отпишете от този пощенски списък?

    Inbox Classic ще изпрати заявка за отписване до { $target }. Няма да се отвори уеб страница и няма да бъде изпратен имейл.
gtk-unsubscribe-mail =
    Искате ли да се отпишете от този пощенски списък?

    За да се отпишете, изпратете имейл до { $target }. Inbox Classic ще го подготви за вас. Изпратете съобщението, за да потвърдите.
gtk-unsubscribe-web =
    Искате ли да се отпишете от този пощенски списък?

    Страницата за отписване от пощенския списък ще се отвори в браузъра ви ({ $target }).
gtk-unsubscribe-failed = Отписването не успя: { $problem }
gtk-toolbar-create-mail-menu = Ново съобщение от избран акаунт
gtk-toolbar-send-recv-menu = Изпращане и получаване на поща за определен акаунт
gtk-main-menu = Главно меню
gtk-folder-list = Списък с папки
gtk-quit = Изход

## The Move and Copy window

gtk-new-folder-at-top-of = Новата папка ще бъде на най-горното ниво на { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Няма непрочетени съобщения
    [one] 1 непрочетено съобщение
   *[other] { $count } непрочетени съобщения
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Няма съобщения, които чакат да бъдат изпратени.
gtk-outbox-row = До: { $to }  ·  В опашката от { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic продължава да проверява за нова поща във фонов режим. Използвайте иконата ѝ в горната лента, за да отворите приложението или да излезете от него.
gtk-sign-in-again-ask =
    Влизането в { $account } беше отхвърлено или сесията е изтекла.

    Искате ли да влезете отново чрез браузъра?
gtk-default-app-not-installed = Това копие на Inbox Classic не е инсталирано, затова системата не го показва като пощенска програма. Инсталирайте го, за да го изберете.
gtk-default-app-now = Inbox Classic вече е пощенската ви програма по подразбиране: имейл връзките отварят ново съобщение тук.
gtk-default-app-failed = Inbox Classic не можа да бъде зададена като пощенска програма по подразбиране.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Дата:
gtk-reader-files = Прикачени файлове на съобщението
gtk-files = { $count ->
    [one] { $count } файл
   *[other] { $count } файла
}
gtk-pictures-blocked = Някои изображения са блокирани, за да не научи подателят кога отваряте съобщението.
gtk-download-pictures = Изтегляне на изображенията
gtk-save-attachments-menu = Запазване на прикачените файлове...

## The compose window

gtk-format-bold = Удебелен (Ctrl+B)
gtk-format-italic = Курсив (Ctrl+I)
gtk-format-underline = Подчертан (Ctrl+U)
gtk-format-hyperlink = Хипервръзка (Ctrl+K)
gtk-font = Шрифт
gtk-show-cc = _Копие
gtk-show-bcc = _Скрито копие
gtk-save-tip = Запазване (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+щракване за отваряне)

## Accounts

gtk-plain-warning =
    Без шифроване всеки, който прихване мрежовия ви трафик, може да прочете паролата и съобщенията ви. Използвайте тази връзка само със сървър на собствения си компютър или в локалната си мрежа.

    Да се продължи ли?
gtk-account-name-title = Име на акаунта
gtk-display-name-title = Показвано име
gtk-turned-off-why = Възможността „{ $button }“ е изключена на този компютър. { $reason }
gtk-turned-off-why-long =
    Възможността „{ $button }“ е изключена на този компютър.

    { $reason }
gtk-next = Напред >
gtk-provider-sign-in = Влезте в { $address } на уебсайта на { $provider }. Паролата ви не се споделя с Inbox Classic. Ако доставчикът предлага пароли за приложения, можете да създадете такава в настройките за сигурност на акаунта си и да я използвате тук.
gtk-provider-sign-in-apps = Влезте в { $address } на уебсайта на { $provider } с едно от приложенията си за влизане („Още начини за влизане“). Ако доставчикът предлага пароли за приложения, можете да създадете такава в настройките за сигурност на акаунта си и да я използвате тук.
gtk-accounts-add = Добавяне...
gtk-accounts-properties = Свойства...
gtk-accounts-signature = Подпис...
gtk-accounts-sign-in-apps = Приложения за влизане...

## Sign-in apps

gtk-app-server = { $kind } сървър
gtk-app-port = { $kind } порт
gtk-app-security = { $kind } защита
gtk-issuer-found =
    Страница за влизане: { $page }
    Крайна точка за маркери: { $endpoint }
gtk-client-id = ИД на клиента
gtk-client-secret = Тайна на клиента
gtk-scopes = Обхвати (scopes)
gtk-redirect-uri = URI за пренасочване
gtk-issuer-usable =
    Издателят може да бъде използван.

    { $found }
gtk-app-built-in = Приложението „{ $app }“ е вградено. Можете да промените само дали да се предлага за нови акаунти. { $reason }
gtk-built-in = { $app } (вградено)
gtk-offered-for-new = Предлага се за нови акаунти
gtk-edit-button = Редактиране...
gtk-remove-app-ask = Искате ли да премахнете приложението за влизане „{ $app }“ и запазената му тайна на клиента?
gtk-sign-in-apps-intro = Приложенията за влизане позволяват на акаунтите да влизат чрез браузъра. Изключено приложение не се предлага за нови акаунти; акаунтите, които вече го използват, продължават да работят.

## AI agents

gtk-agent-it-may = Разрешени действия
gtk-agent-accounts = Разрешени акаунти
gtk-never-used = Никога не е използвана
gtk-last-used = Последно използване: { $date }
gtk-forget-program = Да се премахне ли тази програма?
gtk-forget-program-detail = Разрешенията на програмата и историята на действията на агентите ѝ ще бъдат изтрити. Следващия път, когато се свърже, ще бъдете попитани отново за разрешение.
gtk-no-agents-yet = Все още никой агент не е поискал да използва пощата ви.
gtk-nothing-yet = Все още няма действия.

## Preferences

gtk-preferences = Настройки
gtk-language = Език
gtk-language-subtitle = Език на приложението и помощта
gtk-new-mail-group = Нова поща
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
gtk-notify-new-mail = Уведомяване за нова поща
gtk-notify-subtitle = Известие, когато пристигнат нови съобщения, докато прозорецът е във фонов режим
gtk-restart-to-change = За да се смени езикът, Inbox Classic ще се рестартира.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Пощенски клиент
gtk-desktop-comment = Бърза и лесна за използване програма за електронна поща
gtk-desktop-keywords = поща;имейл;електронна поща;писмо;съобщения;входящи;
gtk-metainfo-summary = Бърза и лесна за използване програма за електронна поща
gtk-metainfo-description = Inbox Classic е програма за електронна поща с познатото класическо оформление: папките са вляво, списъкът със съобщения е отгоре, а избраното съобщение се показва отдолу. Работи с IMAP и SMTP акаунти и поддържа влизане в Outlook.com и Microsoft 365 чрез браузъра.
gtk-metainfo-feature-sanitized = Съобщенията се показват без скриптове, а изображенията от интернет се изтеглят само с ваше разрешение
gtk-metainfo-feature-search = Търсене в темите, подателите, получателите, имената на прикачените файлове и текста на съобщенията с операторите на Gmail
gtk-metainfo-feature-replies = Цитираният текст от по-ранни съобщения е свит и може да се разгъне при нужда
gtk-metainfo-feature-offline = Изтеглената поща е достъпна и без връзка с интернет; паролите се пазят в системния ключодържател
