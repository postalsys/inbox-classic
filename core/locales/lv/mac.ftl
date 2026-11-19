# Latviešu. Melnraksts, gaida dzimtās valodas runātāja pārskatīšanu (sk. core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, curly quotes; Latvian keeps sentence case in menus and on buttons.

## The app and its menus

mac-quit = Beigt Inbox Classic
mac-settings = Iestatījumi…
mac-services = Pakalpojumi
mac-hide = Paslēpt Inbox Classic
mac-hide-others = Paslēpt citus
mac-show-all = Rādīt visu
mac-check-updates = Meklēt atjauninājumus…
mac-close-window = Aizvērt logu
mac-redo = Atcelt atsaukšanu
mac-cut = Izgriezt
mac-paste = Ielīmēt
mac-menu-window = Logs
mac-minimize = Minimizēt
mac-zoom = Mainīt loga lielumu
mac-no-updates = Šī Inbox Classic versija neatbalsta automātiskos atjauninājumus. Lejupielādējiet jaunāko versiju no inboxclassic.com.

## Settings

mac-settings-title = Iestatījumi
mac-check-updates-automatically = Automātiski meklēt atjauninājumus
mac-settings-updates = Atjauninājumi

## Dialogs

mac-choose = Izvēlēties

## The main window

mac-still-running-detail = Inbox Classic turpina fonā pārbaudīt, vai nav jauna pasta. Lai atvērtu lietotni, noklikšķiniet uz tās ikonas Dock joslā.
mac-outbox-waiting =
    { $count ->
        [zero] Izsūtnē ir { $count } ziņojumu
        [one] Izsūtnē ir { $count } ziņojums
       *[other] Izsūtnē ir { $count } ziņojumi
    }
mac-sending = Notiek sūtīšana: { $subject }…
mac-checking = Pārbauda, vai kontā „{ $account }” ir jauni ziņojumi…
mac-account-said = { $account }: { $message }
mac-not-bundle = Šī Inbox Classic kopija nav lietotnes pakotne, tāpēc tā nevar būt noklusējuma pasta lietotne.
mac-not-made-default = Inbox Classic netika iestatīta kā noklusējuma pasta lietotne: { $reason }
mac-tool-search = Meklēt

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [zero] Vēl tiek indeksēts { $count } ziņojumu teksts, tāpēc drīz var parādīties vairāk rezultātu.
        [one] Vēl tiek indeksēts { $count } ziņojuma teksts, tāpēc drīz var parādīties vairāk rezultātu.
       *[other] Vēl tiek indeksēts { $count } ziņojumu teksts, tāpēc drīz var parādīties vairāk rezultātu.
    }
mac-results-everywhere =
    { $count ->
        [0] Visās mapēs nav rezultātu vaicājumam „{ $words }”
        [zero] Visās mapēs { $count } rezultātu vaicājumam „{ $words }”
        [one] Visās mapēs { $count } rezultāts vaicājumam „{ $words }”
       *[other] Visās mapēs { $count } rezultāti vaicājumam „{ $words }”
    }
mac-results-in =
    { $count ->
        [0] nav rezultātu vaicājumam „{ $words }” (meklēšanas vieta: „{ $folder }”)
        [zero] { $count } rezultātu vaicājumam „{ $words }” (meklēšanas vieta: „{ $folder }”)
        [one] { $count } rezultāts vaicājumam „{ $words }” (meklēšanas vieta: „{ $folder }”)
       *[other] { $count } rezultāti vaicājumam „{ $words }” (meklēšanas vieta: „{ $folder }”)
    }
mac-still-indexing =
    { $count ->
        [zero] vēl tiek indeksēts { $count } ziņojumu teksts
        [one] vēl tiek indeksēts { $count } ziņojuma teksts
       *[other] vēl tiek indeksēts { $count } ziņojumu teksts
    }
mac-folder-unread = { $folder }, nelasīti: { $count }
mac-import-messages = Importēt ziņojumus
mac-save-messages = Saglabāt ziņojumus
mac-save-attachments-menu = Saglabāt pielikumus…
mac-files-not-saved =
    { $count ->
       *[other] Neizdevās saglabāt failus: { $failed } no { $count }.
    }
mac-no-calendar-app = Neizdevās atvērt uzaicinājumu (.ics failu). Pārbaudiet, vai Mac datorā ir pieejama kalendāra lietotne.
mac-file-not-saved = Neizdevās saglabāt failu.
mac-unsubscribing = Nosūta atteikšanās pieprasījumu: { $target }…
mac-loading-list = Ielādē…

## The compose window

mac-bold = Treknraksts
mac-italic = Slīpraksts
mac-underline = Pasvītrojums
mac-bcc = Diskrētā kopija
mac-command-click-to-open = ⌘-klikšķis, lai atvērtu
mac-saving-to-drafts = Saglabā mapē „Melnraksti”…
mac-dont-save = Nesaglabāt

## The reading pane

mac-files =
    { $count ->
        [zero] { $count } failu
        [one] { $count } fails
       *[other] { $count } faili
    }

## Accounts

mac-next = Tālāk
mac-name-placeholder = Anna Bērziņa
mac-more-sign-in-options = Citas pierakstīšanās iespējas…
mac-add-sign-in-app = Pievienot pierakstīšanās lietotni…
mac-looking-up = Meklē domēna { $domain } iestatījumus…
mac-add-button = Pievienot…
mac-properties-button = Rekvizīti…
mac-signature-button = Paraksta teksts…
mac-security-button = Drošība…
mac-sign-in-apps-button = Pierakstīšanās lietotnes…

## AI agents

mac-forget-program = Vai noņemt šīs programmas piekļuves ierakstu un tās aģentu darbību vēsturi?
mac-forget-program-detail = Programmas atļaujas tiks izdzēstas. Kad tā nākamreiz pieslēgsies, atļauja tiks prasīta vēlreiz.

## Sign-in apps

mac-checking-issuer = Pārbauda { $issuer }…
mac-edit-button = Rediģēt…
mac-use-for-new-accounts = Jauniem kontiem izmantot lietotni „{ $name }”
mac-built-in = { $name } (iebūvēta)

## Other windows

mac-new-folder-button = Jauna mape…
mac-edit-link = Rediģēt saiti…
