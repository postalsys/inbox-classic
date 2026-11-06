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
mac-no-updates = See Inbox Classicu versioon ei toeta automaatseid uuendusi. Uusima versiooni saate alla laadida aadressilt inboxclassic.com.

## Settings

mac-settings-title = Seaded
mac-language-label = Keel:
mac-restart-hint = Keele vahetamiseks käivitub Inbox Classic uuesti.
mac-notify-new-mail = Teavita mind uue posti saabumisest
mac-restart-question = Kas käivitada Inbox Classic keele vahetamiseks kohe uuesti?

## Dialogs

mac-choose = Vali

## The main window

mac-still-running-detail = Inbox Classic kontrollib taustal uute kirjade saabumist. Rakenduse avamiseks klõpsake selle ikooni Dockis.
mac-outbox-waiting =
    { $count ->
        [one] { $count } kiri väljundkaustas
       *[other] { $count } kirja väljundkaustas
    }
mac-sending = Saadetakse { $subject }…
mac-checking = Kontrollitakse konto { $account } uusi kirju…
mac-account-said = { $account }: { $message }
mac-new-messages =
    { $count ->
        [one] { $count } uus kiri
       *[other] { $count } uut kirja
    }
mac-newest-from = Uusim saatjalt { $from }: { $subject }
mac-not-bundle = See Inbox Classicu koopia ei ole rakenduse pakett, seega ei saa see olla vaikimisi e-posti rakendus.
mac-not-made-default = Inbox Classicut ei õnnestunud vaikimisi meilirakenduseks määrata: { $reason }
mac-tool-search = Otsi

## The folders and the message list

mac-still-indexing-more =
    { $count ->
       *[other] { $count } kirja sisu veel indekseeritakse. Otsingutulemusi võib lisanduda.
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
mac-unsubscribing = Loobutakse tellimusest { $target }…

## The compose window

mac-bold = Paks kiri
mac-italic = Kaldkiri
mac-underline = Allajoonitud
mac-bcc = Pimekoopia
mac-command-click-to-open = avamiseks ⌘-klõps
mac-saving-to-drafts = Salvestatakse mustanditesse…
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
mac-more-sign-in-options = Muud sisselogimisviisid…
mac-add-sign-in-app = Lisa sisselogimisrakendus…
mac-looking-up = Otsitakse domeeni { $domain } sätteid…
mac-add-button = Lisa…
mac-properties-button = Atribuudid…
mac-signature-button = Allkiri…
mac-sign-in-apps-button = Sisselogimisrakendused…

## AI agents

mac-forget-program = Kas eemaldada see programm koos agentide tegevusajalooga?
mac-forget-program-detail = Programmi õigused kustutatakse. Järgmisel ühendumisel küsitakse juurdepääsuluba uuesti.

## Sign-in apps

mac-checking-issuer = Kontrollitakse väljaandjat { $issuer }…
mac-edit-button = Muuda…
mac-use-for-new-accounts = Kasuta rakendust { $name } uute kontode jaoks
mac-built-in = { $name } (sisseehitatud)

## Other windows

mac-new-folder-button = Uus kaust…
mac-edit-link = Muuda linki…
