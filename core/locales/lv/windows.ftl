# Latviešu. Melnraksts, gaida dzimtās valodas runātāja pārskatīšanu (sk. core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic turpina fonā pārbaudīt, vai nav jauna pasta. Lai to atvērtu, noklikšķiniet uz ikonas. Lai izietu, ar peles labo pogu noklikšķiniet uz ikonas un izmantojiet tās izvēlni.
# review: new
win-default-app-not-installed = Šī Inbox Classic kopija nav instalēta, tāpēc Windows to nerāda pasta lietotņu sarakstā. Instalējiet to, lai varētu to izvēlēties.
# review: new
win-default-app-settings = Windows atvērs noklusējuma lietotņu iestatījumus. Izvēlieties Inbox Classic, lai atvērtu MAILTO saites.
# review: new
win-no-unread = Nav nelasītu ziņojumu
# review: new
win-unread-messages = { $count ->
    [zero] { $count } nelasītu ziņojumu
    [one] { $count } nelasīts ziņojums
   *[other] { $count } nelasīti ziņojumi
}
# review: new
win-print-failed = Ziņojumu nevarēja izdrukāt.
# review: new
win-print-title-of = Drukāt: { $subject }
# review: new
win-no-bodies = Ziņojumu saturu nevar parādīt.
# review: new
win-webview-failed = Neizdevās izveidot WebView2.
# review: new
win-webview-missing = WebView2 izpildlaiks nav pieejams.
# review: new
win-list-loading = Ielādē...

## Buttons and words used in many windows

# review: new
win-delete-button = &Dzēst
# review: new
win-find-label = &Meklēt:
# review: new
win-save-as-button = Saglabāt &kā...
# review: new
win-too-many-files = Pārāk daudz failu vienlaikus: izvēlieties mazāk.

## The Outbox


## The compose window

# review: new
win-editor-failed = Ziņojumus nevar rakstīt.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+klikšķis, lai atvērtu)
# review: new
win-format-bold = Treknraksts ({ $ctrl }+B)
# review: new
win-format-italic = Slīpraksts ({ $ctrl }+I)
# review: new
win-format-underline = Pasvītrojums ({ $ctrl }+U)
# review: new
win-format-link = Hipersaite ({ $ctrl }+K)
# review: new
win-show-cc = &Kopija
# review: new
win-show-bcc = &Diskrētā kopija
# review: new
win-signature-title = Paraksts: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Visās mapēs nav rezultātu vaicājumam „{ $words }”
    [zero] Visās mapēs { $count } rezultātu vaicājumam „{ $words }”
    [one] Visās mapēs { $count } rezultāts vaicājumam „{ $words }”
   *[other] Visās mapēs { $count } rezultāti vaicājumam „{ $words }”
}
# review: new
win-search-found-in = { $count ->
    [0] Mapē { $folder } nav rezultātu vaicājumam „{ $words }”
    [zero] Mapē { $folder } { $count } rezultātu vaicājumam „{ $words }”
    [one] Mapē { $folder } { $count } rezultāts vaicājumam „{ $words }”
   *[other] Mapē { $folder } { $count } rezultāti vaicājumam „{ $words }”
}
# review: new
win-search-indexing = { $count ->
    [zero] vēl tiek indeksēts { $count } ziņojumu teksts
    [one] vēl tiek indeksēts { $count } ziņojuma teksts
   *[other] vēl tiek indeksēts { $count } ziņojumu teksts
}
# review: new
win-no-match-indexing = { $count ->
    [zero] Vēl tiek indeksēts { $count } ziņojumu teksts, tāpēc drīz var atrasties vairāk.
    [one] Vēl tiek indeksēts { $count } ziņojuma teksts, tāpēc drīz var atrasties vairāk.
   *[other] Vēl tiek indeksēts { $count } ziņojumu teksts, tāpēc drīz var atrasties vairāk.
}
# review: new
win-files = { $count ->
    [zero] { $count } failu
    [one] { $count } fails
   *[other] { $count } faili
}
# review: new
win-click-to-retry = Noklikšķiniet šeit, lai mēģinātu vēlreiz.
# review: new
win-save-attachments = &Saglabāt pielikumus...
# review: new
win-files-not-saved = { $failed } no { $count } failiem nevarēja saglabāt.
# review: new
win-new-folder-in-highlighted = Jaunā mape tiks izveidota atlasītajā mapē.
# review: new
win-delete-folder-ask = Dzēst mapi „{ $folder }” ar tās ziņojumiem un tajā esošajām mapēm? Tā tiek izdzēsta arī serverī.
# review: new
win-rename = &Pārdēvēt...
# review: new
win-messages-not-saved = Ziņojumus nevarēja saglabāt.
# review: new
win-messages-not-forwarded = Ziņojumus nevarēja pārsūtīt.

## Accounts

# review: new
win-sign-in-google = Pierakstīties ar Google
# review: new
win-sign-in-microsoft = Pierakstīties ar Microsoft
# review: new
win-next = &Tālāk >
# review: new
win-your-account = jūsu konts
# review: new
win-browser-sign-in = (pierakstīšanās pārlūkā)
# review: new
win-add = &Pievienot...
# review: new
win-properties-button = &Rekvizīti...
# review: new
win-signature-button = Parak&sts...
# review: new
win-sign-in-apps-button = Pierakstīšanās &lietotnes...

## AI agents

# review: new
win-dont-allow = &Neatļaut
# review: new
win-col-address = Adrese
# review: new
win-never-written-to = Nekad nav rakstīts
# review: new
win-book-find-label = Ierakstiet vārdu vai e-pasta adresi:
# review: new
win-send = &Sūtīt
# review: new
win-dont-send = &Nesūtīt
# review: new
win-forget-program-ask = Noņemt šo programmu, tās atļaujas un tās aģentu darbību vēsturi? Kad tā nākamreiz pieslēgsies, atļauja tiks prasīta vēlreiz.
# review: new
win-clear-log-ask = Notīrīt aģentu darbību vēsturi? Tas neatsauks aģentu veiktās izmaiņas.
# review: new
win-agent-programs = &Programmas, kuru aģenti ir lūguši piekļuvi jūsu pastam:
# review: new
win-change = &Mainīt...
# review: new
win-what-agents-did = Aģentu &darbības:
# review: new
win-how-to-connect = Kā pieslēgt aģentu

## Sign-in apps

# review: new
win-built-in = (iebūvēta)
# review: new
win-edit = &Rediģēt...

## Options

# review: new
win-options-language-label = &Rādīt Inbox Classic šajā valodā:
# review: new
win-options-restart-note = Restartējiet Inbox Classic, lai mainītu valodu.
# review: new
win-options-notify = &Paziņot, kad pienāk jauns pasts
# review: new
win-restart-ask = Pēc restartēšanas Inbox Classic būs šajā valodā: { $language }. Restartēt tūlīt?
# review: new
win-folders-hide = Paslēpt mapju sarakstu
# review: new
win-folders-pin = Rādīt mapju sarakstu blakus ziņojumiem
# review: new
win-folders-show = Rādīt mapes

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Palaist Inbox Classic
# review: new
win-installer-welcome-new =
    Tiks instalēta e-pasta programma Inbox Classic { $version }.

    Administratora tiesības nav vajadzīgas, tā tiek instalēta tikai jūsu kontam.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } jau ir instalēta. Tā tiks instalēta vēlreiz.

    Jūsu konti un pasts tiek saglabāti.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } tiks atjaunināta uz { $version }.

    Ja tā darbojas, tā vispirms tiek aizvērta. Jūsu konti un pasts tiek saglabāti.
# review: new
win-installer-older-ask = Ir instalēta Inbox Classic { $installed }, kas ir jaunāka par { $version }. Tomēr instalēt vecāko versiju?
# review: new
win-installer-still-running = Inbox Classic joprojām darbojas. Aizveriet to un mēģiniet vēlreiz.
# review: new
win-installer-remove-mail-ask = Noņemt arī kontus un pastu, ko Inbox Classic glabā šajā datorā? Pasts serveros paliek.
