# Български. Чернова, очаква преглед от носител на езика (вж. core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Настройки, Изход).

## The main window

# review: new
gtk-search-looks-in = Търсенето в { $place } обхваща темите, подателите, получателите, имената на прикачените файлове и текста на съобщенията. Проверете правописа или опитайте с по-малко думи.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Текстът на 1 съобщение все още се индексира. Скоро може да се появят още резултати.
   *[other] Текстът на { $count } съобщения все още се индексира. Скоро може да се появят още резултати.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Няма резултати
    [one] 1 резултат
   *[other] { $count } резултата
} за „{ $words }“ във всички папки
# review: new
gtk-search-results-in = { $count ->
    [0] Няма резултати
    [one] 1 резултат
   *[other] { $count } резултата
} за „{ $words }“ в { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] текстът на 1 съобщение все още се индексира
   *[other] текстът на { $count } съобщения все още се индексира
}
# review: new
gtk-menu-rename = Преименуване...
# review: new
gtk-import-one-question = Да се импортира ли съобщението { $file } в { $folder }?
# review: new
gtk-files-not-saved = { $failed } от { $total } файла не можаха да бъдат запазени.
# review: new
gtk-unsubscribe-one-click =
    Да се напусне ли този пощенски списък?

    Inbox Classic ще изпрати заявка за отписване до { $target }. Няма да се отвори уеб страница и няма да бъде изпратен имейл.
# review: new
gtk-unsubscribe-mail =
    Да се напусне ли този пощенски списък?

    За да се отпишете, изпратете имейл до { $target }. Inbox Classic ще го подготви за вас. Изпратете съобщението, за да потвърдите.
# review: new
gtk-unsubscribe-web =
    Да се напусне ли този пощенски списък?

    Страницата за отписване от пощенския списък ще се отвори в браузъра ви ({ $target }).
# review: new
gtk-unsubscribe-failed = Отписването не успя: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Писане от определен акаунт
# review: new
gtk-toolbar-send-recv-menu = Изпращане и получаване на поща за определен акаунт
# review: new
gtk-main-menu = Главно меню
# review: new
gtk-folder-list = Списък с папки
# review: new
gtk-quit = Изход

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Новата папка ще бъде на най-горното ниво на { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Няма непрочетени съобщения
    [one] 1 непрочетено съобщение
   *[other] { $count } непрочетени съобщения
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Няма съобщения, които чакат да бъдат изпратени.
# review: new
gtk-outbox-row = До: { $to }  ·  В опашката от { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic продължава да проверява за нова поща във фонов режим. Използвайте иконата ѝ в горната лента, за да отворите приложението или да излезете от него.
# review: new
gtk-sign-in-again-ask =
    Влизането в { $account } беше отхвърлено или сесията е изтекла.

    Да влезете ли отново в браузъра?
# review: new
gtk-default-app-not-installed = Това копие на Inbox Classic не е инсталирано, затова системата не го показва като пощенска програма. Инсталирайте го, за да го изберете.
# review: new
gtk-default-app-now = Inbox Classic вече е пощенската ви програма по подразбиране: имейл връзките отварят ново съобщение тук.
# review: new
gtk-default-app-failed = Inbox Classic не можа да бъде зададена като пощенска програма по подразбиране.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Дата:
# review: new
gtk-reader-files = Прикачени файлове на съобщението
# review: new
gtk-files = { $count ->
    [one] { $count } файл
   *[other] { $count } файла
}
# review: new
gtk-pictures-blocked = Някои изображения са блокирани, за да не може подателят да разпознае компютъра ви.
# review: new
gtk-download-pictures = Изтегляне на изображенията
# review: new
gtk-save-attachments-menu = Запазване на прикачените файлове...

## The compose window

# review: new
gtk-format-bold = Удебелен (Ctrl+B)
# review: new
gtk-format-italic = Курсив (Ctrl+I)
# review: new
gtk-format-underline = Подчертан (Ctrl+U)
# review: new
gtk-format-hyperlink = Хипервръзка (Ctrl+K)
# review: new
gtk-font = Шрифт
# review: new
gtk-show-cc = _Копие
# review: new
gtk-show-bcc = _Скрито копие
# review: new
gtk-save-tip = Запазване (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+щракване за отваряне)

## Accounts

# review: new
gtk-plain-warning =
    Без шифроване всеки, който прихване мрежовия ви трафик, може да прочете паролата и съобщенията ви. Използвайте тази връзка само със сървър на собствения си компютър или в локалната си мрежа.

    Да се продължи ли?
# review: new
gtk-account-name-title = Име на акаунта
# review: new
gtk-display-name-title = Показвано име
# review: new
gtk-turned-off-why = Възможността „{ $button }“ е изключена на този компютър. { $reason }
# review: new
gtk-turned-off-why-long =
    Възможността „{ $button }“ е изключена на този компютър.

    { $reason }
# review: new
gtk-next = Напред >
# review: new
gtk-provider-sign-in = Влезте в { $address } на уебсайта на { $provider }. Паролата ви не се споделя с Inbox Classic. Можете да използвате и парола за приложение, създадена в настройките за сигурност на акаунта ви.
# review: new
gtk-provider-sign-in-apps = Влезте в { $address } на уебсайта на { $provider } с едно от приложенията си за влизане („Още начини за влизане“). Можете да използвате и парола за приложение, създадена в настройките за сигурност на акаунта ви.
# review: new
gtk-accounts-add = Добавяне...
# review: new
gtk-accounts-properties = Свойства...
# review: new
gtk-accounts-signature = Подпис...
# review: new
gtk-accounts-sign-in-apps = Приложения за влизане...

## Sign-in apps

# review: new
gtk-app-server = { $kind } сървър
# review: new
gtk-app-port = { $kind } порт
# review: new
gtk-app-security = { $kind } защита
# review: new
gtk-issuer-found =
    Страница за влизане: { $page }
    Крайна точка за маркери: { $endpoint }
# review: new
gtk-client-id = ИД на клиента
# review: new
gtk-client-secret = Тайна на клиента
# review: new
gtk-scopes = Обхвати (scopes)
# review: new
gtk-redirect-uri = URI за пренасочване
# review: new
gtk-issuer-usable =
    Издателят може да бъде използван.

    { $found }
# review: new
gtk-app-built-in = { $app } е вградено. Можете да промените само дали да се предлага за нови акаунти. { $reason }
# review: new
gtk-built-in = { $app } (вградено)
# review: new
gtk-offered-for-new = Предлага се за нови акаунти
# review: new
gtk-edit-button = Редактиране...
# review: new
gtk-remove-app-ask = Да се премахне ли приложението за влизане { $app } и запазената му тайна на клиента?
# review: new
gtk-sign-in-apps-intro = Приложенията за влизане позволяват на акаунтите да влизат чрез браузъра. Изключено приложение не се предлага за нови акаунти; акаунтите, които вече го използват, продължават да работят.

## AI agents

# review: new
gtk-agent-it-may = Разрешени действия
# review: new
gtk-agent-accounts = Разрешени акаунти
# review: new
gtk-never-used = Никога не е използвана
# review: new
gtk-last-used = Последно използване: { $date }
# review: new
gtk-forget-program = Да се премахне ли тази програма?
# review: new
gtk-forget-program-detail = Разрешенията на програмата и историята на действията на агентите ѝ ще бъдат изтрити. Следващия път, когато се свърже, ще бъдете попитани отново за разрешение.
# review: new
gtk-no-agents-yet = Все още никой агент не е поискал да използва пощата ви.
# review: new
gtk-nothing-yet = Все още нищо.

## Preferences

# review: new
gtk-preferences = Настройки
# review: new
gtk-language = Език
# review: new
gtk-language-subtitle = Език на приложението и помощта
# review: new
gtk-new-mail-group = Нова поща
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Уведомяване за нова поща
# review: new
gtk-notify-subtitle = Известие, когато пристигнат нови съобщения, докато прозорецът е във фонов режим
# review: new
gtk-restart-to-change = Inbox Classic се рестартира, за да смени езика.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Пощенски клиент
# review: new
gtk-desktop-comment = Четене и писане на имейли: бърза и проста пощенска програма
# review: new
gtk-desktop-keywords = поща;имейл;електронна поща;писмо;съобщения;входящи;
# review: new
gtk-metainfo-summary = Бърза и проста пощенска програма
# review: new
gtk-metainfo-description = Inbox Classic чете и пише имейли с папките вляво, съобщенията отгоре и самото съобщение отдолу, както някога са правили пощенските програми. Работи с всеки IMAP и SMTP акаунт и влиза в Outlook.com и Microsoft 365 чрез браузъра.
# review: new
gtk-metainfo-feature-sanitized = Всяко съобщение се показва изчистено, без скриптове, а изображенията от интернет само когато ги разрешите
# review: new
gtk-metainfo-feature-search = Търсене, което намира думи в темата, хората, имената на файловете и текста, с операторите на Gmail
# review: new
gtk-metainfo-feature-replies = Отговорите скриват по-ранните съобщения, които цитират
# review: new
gtk-metainfo-feature-offline = Пощата остава четима и без връзка; паролите се пазят в ключодържателя ви
