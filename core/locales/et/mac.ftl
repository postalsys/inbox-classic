# Eesti. Mustand, ootab emakeelse kõneleja ülevaatust.

## The app and its menus

mac-quit = Välju rakendusest Inbox Classic
mac-settings = Seaded…
mac-services = Teenused
mac-hide = Peida Inbox Classic
mac-hide-others = Peida teised
mac-show-all = Näita kõiki
mac-check-updates = Otsi uuendusi…
mac-close-window = Sulge aken
mac-redo = Tee uuesti
mac-cut = Lõika
mac-paste = Kleebi
mac-menu-window = Aken
mac-minimize = Minimeeri
mac-zoom = Suumi
mac-no-updates = See Inbox Classicu koopia ei uuenda end ise. Uusima versiooni leiate aadressilt inboxclassic.com.

## Settings

mac-settings-title = Seaded
mac-language-label = Keel:
mac-restart-hint = Keele vahetamiseks käivitub Inbox Classic uuesti.
mac-notify-new-mail = Teavita mind uue posti saabumisest
mac-restart-question = Kas käivitada Inbox Classic keele vahetamiseks kohe uuesti?

## Dialogs

mac-choose = Vali

## The main window

mac-still-running-detail = See kontrollib edasi uut posti. Uuesti avamiseks klõpsake selle ikooni Dockis.
mac-outbox-waiting =
    { $count ->
        [one] { $count } kiri väljundkaustas
       *[other] { $count } kirja väljundkaustas
    }
mac-sending = Saadan: { $subject }…
mac-checking = Kontrollin uusi kirju kontol { $account }…
mac-account-said = { $account }: { $message }
mac-new-messages =
    { $count ->
        [one] { $count } uus kiri
       *[other] { $count } uut kirja
    }
mac-newest-from = Uusim saatjalt { $from }: { $subject }
mac-not-bundle = See Inbox Classicu koopia ei ole rakenduse pakett, seega ei saa see olla vaikimisi e-posti rakendus.
mac-not-made-default = Inbox Classicut ei tehtud vaikimisi e-posti rakenduseks: { $reason }
mac-tool-search = Otsi

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] { $count } kirja teksti alles indekseeritakse, nii et peagi võib leiduda rohkem.
       *[other] { $count } kirja teksti alles indekseeritakse, nii et peagi võib leiduda rohkem.
    }
mac-results-everywhere =
    { $count ->
        [0] Otsingul „{ $words }“ pole kõigis kaustades tulemusi
        [one] { $count } tulemus otsingule „{ $words }“ kõigis kaustades
       *[other] { $count } tulemust otsingule „{ $words }“ kõigis kaustades
    }
mac-results-in =
    { $count ->
        [0] Otsingul „{ $words }“ pole kaustas { $folder } tulemusi
        [one] { $count } tulemus otsingule „{ $words }“ kaustas { $folder }
       *[other] { $count } tulemust otsingule „{ $words }“ kaustas { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] { $count } kirja teksti indekseeritakse veel
       *[other] { $count } kirja teksti indekseeritakse veel
    }
mac-folder-unread = { $folder }, { $count } lugemata
mac-import-messages = Impordi kirjad
mac-save-messages = Salvesta kirjad
mac-save-attachments-menu = Salvesta manused…
mac-files-not-saved =
    { $count ->
       *[other] { $count } failist { $failed } ei saanud salvestada.
    }
mac-no-calendar-app = Ükski selle Maci kalendrirakendus ei ava kutseid (.ics-faile).
mac-unsubscribing = Loobun tellimusest: { $target }…

## The compose window

mac-bold = Paks
mac-italic = Kaldkiri
mac-underline = Allajoonitud
mac-bcc = Bcc
mac-command-click-to-open = avamiseks ⌘-klõps
mac-saving-to-drafts = Salvestan mustanditesse…
mac-dont-save = Ära salvesta

## The reading pane

mac-files =
    { $count ->
        [one] { $count } fail
       *[other] { $count } faili
    }
mac-attendees =
    { $count ->
        [one] { $count } osaleja
       *[other] { $count } osalejat
    }

## Accounts

mac-next = Edasi
mac-name-placeholder = Mari Maasikas
mac-more-sign-in-options = Rohkem sisselogimisviise…
mac-add-sign-in-app = Lisa sisselogimisrakendus…
mac-looking-up = Otsin domeeni { $domain } seadeid…
mac-add-button = Lisa…
mac-properties-button = Atribuudid…
mac-signature-button = Allkiri…
mac-sign-in-apps-button = Sisselogimisrakendused…

## AI agents

mac-forget-program = Kas unustada see programm ja see, mida selle agendid tegid?
mac-forget-program-detail = Seda küsitakse uuesti, kui see järgmine kord ühendub.

## Sign-in apps

mac-checking-issuer = Kontrollin: { $issuer }…
mac-edit-button = Muuda…
mac-use-for-new-accounts = Kasuta rakendust { $name } uute kontode jaoks
mac-built-in = { $name } (sisseehitatud)

## Other windows

mac-new-folder-button = Uus kaust…
mac-edit-link = Muuda linki…
