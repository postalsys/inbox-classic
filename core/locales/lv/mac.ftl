# Latviešu. Melnraksts, gaida dzimtās valodas runātāja pārskatīšanu (sk. core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, curly quotes; Latvian keeps sentence case in menus and on buttons.

## The app and its menus

# review: new
mac-quit = Beigt Inbox Classic
# review: new
mac-settings = Iestatījumi…
# review: new
mac-services = Pakalpojumi
# review: new
mac-hide = Paslēpt Inbox Classic
# review: new
mac-hide-others = Paslēpt citus
# review: new
mac-show-all = Rādīt visu
# review: new
mac-check-updates = Meklēt atjauninājumus…
# review: new
mac-close-window = Aizvērt logu
# review: new
mac-redo = Atkārtot
# review: new
mac-cut = Izgriezt
# review: new
mac-paste = Ielīmēt
# review: new
mac-menu-window = Logs
# review: new
mac-minimize = Minimizēt
# review: new
mac-zoom = Tālummaiņa
# review: new
mac-no-updates = Šī Inbox Classic versija neatbalsta automātiskos atjauninājumus. Lejupielādējiet jaunāko versiju no inboxclassic.com.

## Settings

# review: new
mac-settings-title = Iestatījumi
# review: new
mac-check-updates-automatically = Automātiski meklēt atjauninājumus
# review: new
mac-settings-updates = Atjauninājumi

## Dialogs

# review: new
mac-choose = Izvēlēties

## The main window

# review: new
mac-still-running-detail = Inbox Classic turpina fonā pārbaudīt, vai nav jauna pasta. Lai atvērtu lietotni, noklikšķiniet uz tās ikonas Dock joslā.
# review: new
mac-outbox-waiting =
    { $count ->
        [zero] Izsūtnē ir { $count } ziņojumu
        [one] Izsūtnē ir { $count } ziņojums
       *[other] Izsūtnē ir { $count } ziņojumi
    }
# review: new
mac-sending = Sūta { $subject }…
# review: new
mac-checking = Pārbauda, vai kontā { $account } ir jauni ziņojumi…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Šī Inbox Classic kopija nav lietotnes pakotne, tāpēc tā nevar būt noklusējuma pasta lietotne.
# review: new
mac-not-made-default = Inbox Classic netika iestatīta kā noklusējuma pasta lietotne: { $reason }
# review: new
mac-tool-search = Meklēt

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [zero] Vēl tiek indeksēts { $count } ziņojumu teksts, tāpēc drīz var atrasties vairāk.
        [one] Vēl tiek indeksēts { $count } ziņojuma teksts, tāpēc drīz var atrasties vairāk.
       *[other] Vēl tiek indeksēts { $count } ziņojumu teksts, tāpēc drīz var atrasties vairāk.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Visās mapēs nav rezultātu vaicājumam „{ $words }”
        [zero] Visās mapēs { $count } rezultātu vaicājumam „{ $words }”
        [one] Visās mapēs { $count } rezultāts vaicājumam „{ $words }”
       *[other] Visās mapēs { $count } rezultāti vaicājumam „{ $words }”
    }
# review: new
mac-results-in =
    { $count ->
        [0] Mapē { $folder } nav rezultātu vaicājumam „{ $words }”
        [zero] Mapē { $folder } { $count } rezultātu vaicājumam „{ $words }”
        [one] Mapē { $folder } { $count } rezultāts vaicājumam „{ $words }”
       *[other] Mapē { $folder } { $count } rezultāti vaicājumam „{ $words }”
    }
# review: new
mac-still-indexing =
    { $count ->
        [zero] vēl tiek indeksēts { $count } ziņojumu teksts
        [one] vēl tiek indeksēts { $count } ziņojuma teksts
       *[other] vēl tiek indeksēts { $count } ziņojumu teksts
    }
# review: new
mac-folder-unread = { $folder }, { $count } nelasīti
# review: new
mac-import-messages = Importēt ziņojumus
# review: new
mac-save-messages = Saglabāt ziņojumus
# review: new
mac-save-attachments-menu = Saglabāt pielikumus…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] { $failed } no { $count } failiem nevarēja saglabāt.
    }
# review: new
mac-no-calendar-app = Šajā Mac datorā nav kalendāra lietotnes, ar ko atvērt ielūgumus (.ics failus).
# review: new
mac-file-not-saved = Failu nevarēja saglabāt.
# review: new
mac-unsubscribing = Atsakās no abonēšanas: { $target }…
mac-loading-list = Ielādē…

## The compose window

# review: new
mac-bold = Treknraksts
# review: new
mac-italic = Slīpraksts
# review: new
mac-underline = Pasvītrojums
# review: new
mac-bcc = Diskrētā kopija
# review: new
mac-command-click-to-open = ⌘-klikšķis, lai atvērtu
# review: new
mac-saving-to-drafts = Saglabā mapē Melnraksti…
# review: new
mac-dont-save = Nesaglabāt

## The reading pane

# review: new
mac-files =
    { $count ->
        [zero] { $count } failu
        [one] { $count } fails
       *[other] { $count } faili
    }

## Accounts

# review: new
mac-next = Tālāk
# review: new
mac-name-placeholder = Anna Bērziņa
# review: new
mac-more-sign-in-options = Citas pierakstīšanās iespējas…
# review: new
mac-add-sign-in-app = Pievienot pierakstīšanās lietotni…
# review: new
mac-looking-up = Meklē domēna { $domain } iestatījumus…
# review: new
mac-add-button = Pievienot…
# review: new
mac-properties-button = Rekvizīti…
# review: new
mac-signature-button = Paraksts…
# review: new
mac-security-button = Drošība…
# review: new
mac-sign-in-apps-button = Pierakstīšanās lietotnes…

## AI agents

# review: new
mac-forget-program = Noņemt šo programmu un tās aģentu darbību vēsturi?
# review: new
mac-forget-program-detail = Programmas atļaujas tiks izdzēstas. Kad tā nākamreiz pieslēgsies, atļauja tiks prasīta vēlreiz.

## Sign-in apps

# review: new
mac-checking-issuer = Pārbauda { $issuer }…
# review: new
mac-edit-button = Rediģēt…
# review: new
mac-use-for-new-accounts = Izmantot { $name } jauniem kontiem
# review: new
mac-built-in = { $name } (iebūvēta)

## Other windows

# review: new
mac-new-folder-button = Jauna mape…
# review: new
mac-edit-link = Rediģēt saiti…
