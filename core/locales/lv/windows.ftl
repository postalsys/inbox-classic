# Latviešu. Melnraksts, gaida dzimtās valodas runātāja pārskatīšanu (sk. core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic turpina fonā pārbaudīt jauno pastu. Lai atvērtu programmu, noklikšķiniet uz tās ikonas. Lai aizvērtu programmu, ar peles labo pogu noklikšķiniet uz ikonas un izvēlieties „Iziet”.
win-default-app-not-installed = Šī Inbox Classic kopija nav instalēta, tāpēc Windows to nerāda pasta lietotņu sarakstā. Instalējiet to, lai varētu to izvēlēties.
win-default-app-settings = Windows atvērs noklusējuma lietotņu iestatījumus. Izvēlieties Inbox Classic, lai atvērtu MAILTO saites.
win-no-unread = Nav nelasītu ziņojumu
win-unread-messages = { $count ->
    [zero] { $count } nelasītu ziņojumu
    [one] { $count } nelasīts ziņojums
   *[other] { $count } nelasīti ziņojumi
}
win-print-failed = Neizdevās izdrukāt ziņojumu.
win-print-title-of = Drukāt: { $subject }
win-no-bodies = Ziņojumu saturu nevar parādīt.
win-webview-failed = Neizdevās palaist WebView2 komponentu.
win-webview-missing = WebView2 izpildlaiks nav pieejams.
win-list-loading = Ielādē...

## Buttons and words used in many windows

win-delete-button = &Dzēst
win-find-label = &Meklēt:
win-save-as-button = &Saglabāt kā...
win-too-many-files = Pārāk daudz failu vienlaikus: izvēlieties mazāk.

## The Outbox


## The compose window

win-editor-failed = Ziņojumus nevar rakstīt.
win-ctrl-click-to-open = ({ $ctrl }+klikšķis, lai atvērtu)
win-format-bold = Treknraksts ({ $ctrl }+B)
win-format-italic = Slīpraksts ({ $ctrl }+I)
win-format-underline = Pasvītrojums ({ $ctrl }+U)
win-format-link = Hipersaite ({ $ctrl }+K)
win-show-cc = K&opija
win-show-bcc = &Diskrētā kopija
win-signature-title = Paraksta teksts: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Visās mapēs nav rezultātu vaicājumam „{ $words }”
    [zero] Visās mapēs { $count } rezultātu vaicājumam „{ $words }”
    [one] Visās mapēs { $count } rezultāts vaicājumam „{ $words }”
   *[other] Visās mapēs { $count } rezultāti vaicājumam „{ $words }”
}
win-search-found-in = { $count ->
    [0] nav rezultātu vaicājumam „{ $words }” (meklēšanas vieta: „{ $folder }”)
    [zero] { $count } rezultātu vaicājumam „{ $words }” (meklēšanas vieta: „{ $folder }”)
    [one] { $count } rezultāts vaicājumam „{ $words }” (meklēšanas vieta: „{ $folder }”)
   *[other] { $count } rezultāti vaicājumam „{ $words }” (meklēšanas vieta: „{ $folder }”)
}
win-search-indexing = { $count ->
    [zero] vēl tiek indeksēts { $count } ziņojumu teksts
    [one] vēl tiek indeksēts { $count } ziņojuma teksts
   *[other] vēl tiek indeksēts { $count } ziņojumu teksts
}
win-no-match-indexing = { $count ->
    [zero] Vēl tiek indeksēts { $count } ziņojumu teksts, tāpēc drīz var parādīties vairāk rezultātu.
    [one] Vēl tiek indeksēts { $count } ziņojuma teksts, tāpēc drīz var parādīties vairāk rezultātu.
   *[other] Vēl tiek indeksēts { $count } ziņojumu teksts, tāpēc drīz var parādīties vairāk rezultātu.
}
win-files = { $count ->
    [zero] { $count } failu
    [one] { $count } fails
   *[other] { $count } faili
}
win-click-to-retry = Noklikšķiniet šeit, lai mēģinātu vēlreiz.
win-save-attachments = &Saglabāt pielikumus...
win-files-not-saved = Neizdevās saglabāt failus: { $failed } no { $count }.
win-new-folder-in-highlighted = Jaunā mape tiks izveidota atlasītajā mapē.
win-delete-folder-ask = Vai dzēst mapi „{ $folder }”, visus tās ziņojumus un apakšmapes? Tie tiks izdzēsti arī serverī.
win-rename = &Pārdēvēt...
win-messages-not-saved = Ziņojumus nevarēja saglabāt.
win-messages-not-forwarded = Ziņojumus nevarēja pārsūtīt.

## Accounts

win-sign-in-google = Pierakstīties ar Google
win-sign-in-microsoft = Pierakstīties ar Microsoft
win-next = &Tālāk >
win-your-account = jūsu konts
win-browser-sign-in = (pierakstīšanās pārlūkā)
win-add = &Pievienot...
win-properties-button = &Rekvizīti...
win-signature-button = Parak&sta teksts...
win-sign-in-apps-button = Pierakstīšanās &lietotnes...

## AI agents

win-dont-allow = &Neatļaut
win-col-address = Adrese
win-never-written-to = Nekad nav rakstīts
win-book-find-label = Ierakstiet vārdu vai e-pasta adresi:
win-send = &Sūtīt
win-dont-send = &Nesūtīt
win-unsubscribe = &Atteikties no abonēšanas
win-dont-unsubscribe = &Neatteikties
win-forget-program-ask = Vai noņemt šīs programmas piekļuves ierakstu, tās atļaujas un aģentu darbību vēsturi? Nākamajā savienojuma reizē programmai atkal būs jāsaņem jūsu atļauja.
win-clear-log-ask = Notīrīt aģentu darbību vēsturi? Tas neatsauks aģentu veiktās izmaiņas.
win-agent-programs = &Programmas, kuru aģenti ir lūguši piekļuvi jūsu pastam:
win-change = &Mainīt...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Atsaukt darbības lai&kposmā...
win-take-back = &Atsaukt darbības
win-what-agents-did = Aģentu &darbības:
win-agent-reads = Nolasītie dati (no { $from } līdz { $to }):
win-agent-reads-hint = Atlasiet lasīšanas ierakstu augšējā sarakstā, lai redzētu nolasītos datus.
win-how-to-connect = Kā pieslēgt aģentu

## Sign-in apps

win-built-in = (iebūvēta)
win-edit = &Rediģēt...

## Options

win-folders-hide = Paslēpt mapju sarakstu
win-folders-pin = Piespraust mapju sarakstu blakus ziņojumiem
win-folders-show = Rādīt mapes

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Palaist Inbox Classic
win-installer-welcome-new =
    Tiks instalēta e-pasta programma Inbox Classic { $version }.

    Programma tiks instalēta tikai jūsu Windows lietotāja kontam. Administratora tiesības nav vajadzīgas.
win-installer-welcome-same =
    Inbox Classic { $version } jau ir instalēta. Programma tiks instalēta vēlreiz.

    Jūsu konti un pasts tiks saglabāti.
win-installer-welcome-update =
    Inbox Classic { $installed } tiks atjaunināta uz versiju { $version }.

    Ja programma darbojas, tā vispirms tiks aizvērta. Jūsu konti un pasts tiks saglabāti.
win-installer-older-ask = Ir instalēta Inbox Classic { $installed }, kas ir jaunāka par { $version }. Tomēr instalēt vecāko versiju?
win-installer-still-running = Inbox Classic joprojām darbojas. Aizveriet to un mēģiniet vēlreiz.
win-installer-remove-mail-ask = Vai dzēst arī Inbox Classic kontus un šajā datorā saglabātos programmas datus, tostarp pastu un iestatījumus? Pasts serveros paliks.
