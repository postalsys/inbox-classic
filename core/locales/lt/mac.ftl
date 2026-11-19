# Lietuvių. Juodraštis, laukia gimtakalbio peržiūros (žr. core/locales/GLOSSARY.md).

## The app and its menus

mac-quit = Išeiti iš Inbox Classic
mac-settings = Nustatymai…
mac-services = Paslaugos
mac-hide = Slėpti Inbox Classic
mac-hide-others = Slėpti kitas programas
mac-show-all = Rodyti visas programas
mac-check-updates = Ieškoti naujinių…
mac-close-window = Uždaryti langą
mac-redo = Grąžinti
mac-cut = Iškirpti
mac-paste = Įklijuoti
mac-menu-window = Langas
mac-minimize = Sumažinti
mac-zoom = Keisti lango dydį
mac-no-updates = Ši Inbox Classic versija nepalaiko automatinių naujinimų. Naujausią versiją atsisiųskite iš inboxclassic.com.

## Settings

mac-settings-title = Nustatymai
mac-check-updates-automatically = Automatiškai ieškoti naujinių
mac-settings-updates = Naujiniai

## Dialogs

mac-choose = Pasirinkti

## The main window

mac-still-running-detail = Inbox Classic fone ir toliau tikrina, ar yra naujų laiškų. Norėdami atverti programą, spustelėkite jos piktogramą juostoje Dock.
mac-outbox-waiting =
    { $count ->
        [one] { $count } laiškas aplanke „Siunčiami laiškai“
        [few] { $count } laiškai aplanke „Siunčiami laiškai“
       *[other] { $count } laiškų aplanke „Siunčiami laiškai“
    }
mac-sending = Siunčiama { $subject }…
mac-checking = Tikrinama, ar paskyroje „{ $account }“ yra naujų laiškų…
mac-account-said = { $account }: { $message }
mac-not-bundle = Ši Inbox Classic kopija nėra programos paketas, todėl ji negali būti numatytoji pašto programa.
mac-not-made-default = Inbox Classic nenustatyta kaip numatytoji pašto programa: { $reason }
mac-tool-search = Ieškoti

## The folders and the message list

mac-still-indexing-more = { $count ->
        [one] Dar indeksuojamas { $count } laiško tekstas, todėl netrukus gali atsirasti daugiau rezultatų.
       *[other] Dar indeksuojami { $count } laiškų tekstai, todėl netrukus gali atsirasti daugiau rezultatų.
    }
mac-results-everywhere =
    { $count ->
        [0] Visuose aplankuose nėra rezultatų pagal „{ $words }“
        [one] Visuose aplankuose pagal „{ $words }“ rastas { $count } rezultatas
        [few] Visuose aplankuose pagal „{ $words }“ rasti { $count } rezultatai
       *[other] Visuose aplankuose pagal „{ $words }“ rasta rezultatų: { $count }
    }
mac-results-in =
    { $count ->
        [0] Aplanke „{ $folder }“ nėra rezultatų pagal „{ $words }“
        [one] Aplanke „{ $folder }“ pagal „{ $words }“ rastas { $count } rezultatas
        [few] Aplanke „{ $folder }“ pagal „{ $words }“ rasti { $count } rezultatai
       *[other] Aplanke „{ $folder }“ pagal „{ $words }“ rasta rezultatų: { $count }
    }
mac-still-indexing =
    { $count ->
        [one] dar indeksuojamas { $count } laiško tekstas
       *[other] dar indeksuojami { $count } laiškų tekstai
    }
mac-folder-unread = { $folder }, neskaitytų: { $count }
mac-import-messages = Importuoti laiškus
mac-save-messages = Įrašyti laiškus
mac-save-attachments-menu = Įrašyti priedus…
mac-files-not-saved = { $count ->
   *[other] Nepavyko įrašyti failų: { $failed }. Iš viso: { $count }.
}
mac-no-calendar-app = Šio kvietimo (.ics failo) nepavyko atidaryti. Patikrinkite, ar įdiegta kalendoriaus programa.
mac-file-not-saved = Failo įrašyti nepavyko.
mac-unsubscribing = Atsisakoma prenumeratos: { $target }…
mac-loading-list = Įkeliama…

## The compose window

mac-bold = Pusjuodis
mac-italic = Kursyvas
mac-underline = Pabrauktas
mac-bcc = Slapta kopija
mac-command-click-to-open = Atidaryti: ⌘ + pelės spustelėjimas
mac-saving-to-drafts = Įrašoma į aplanką „Juodraščiai“…
mac-dont-save = Neįrašyti

## The reading pane

mac-files =
    { $count ->
        [one] { $count } failas
        [few] { $count } failai
       *[other] { $count } failų
    }

## Accounts

mac-next = Toliau
mac-name-placeholder = Rūta Petraitienė
mac-more-sign-in-options = Daugiau prisijungimo būdų…
mac-add-sign-in-app = Pridėti prisijungimo programą…
mac-looking-up = Ieškoma domeno { $domain } nustatymų…
mac-add-button = Pridėti…
mac-properties-button = Ypatybės…
mac-signature-button = Parašo tekstas…
mac-security-button = Sauga…
mac-sign-in-apps-button = Prisijungimo programos…

## AI agents

mac-forget-program = Pašalinti šią programą iš sąrašo ir panaikinti jos agentų veiklos istoriją?
mac-forget-program-detail = Bus panaikintos programos prieigos teisės. Kitą kartą jai prisijungus vėl bus paprašyta leidimo.

## Sign-in apps

mac-checking-issuer = Tikrinamas išdavėjas: { $issuer }…
mac-edit-button = Keisti…
mac-use-for-new-accounts = Naudoti prisijungimo programą „{ $name }“ naujoms paskyroms
mac-built-in = { $name } (įtaisytoji)

## Other windows

mac-new-folder-button = Naujas aplankas…
mac-edit-link = Redaguoti nuorodą…
