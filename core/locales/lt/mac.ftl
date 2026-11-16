# Lietuvių. Juodraštis, laukia gimtakalbio peržiūros (žr. core/locales/GLOSSARY.md).

## The app and its menus

# review: new
mac-quit = Išeiti iš Inbox Classic
# review: new
mac-settings = Nustatymai…
# review: new
mac-services = Paslaugos
# review: new
mac-hide = Slėpti Inbox Classic
# review: new
mac-hide-others = Slėpti kitus
# review: new
mac-show-all = Rodyti viską
# review: new
mac-check-updates = Ieškoti naujinių…
# review: new
mac-close-window = Uždaryti langą
# review: new
mac-redo = Pakartoti
# review: new
mac-cut = Iškirpti
# review: new
mac-paste = Įklijuoti
# review: new
mac-menu-window = Langas
# review: new
mac-minimize = Sumažinti
# review: new
mac-zoom = Mastelis
# review: new
mac-no-updates = Ši Inbox Classic versija nepalaiko automatinių naujinimų. Naujausią versiją atsisiųskite iš inboxclassic.com.

## Settings

# review: new
mac-settings-title = Nustatymai
# review: new
mac-language-label = Kalba:
# review: new
mac-restart-hint = Paleiskite Inbox Classic iš naujo, kad pasikeistų kalba.
# review: new
mac-notify-new-mail = Pranešti, kai gaunami nauji laiškai
# review: new
mac-restart-question = Paleisti Inbox Classic iš naujo dabar, kad pasikeistų kalba?

## Dialogs

# review: new
mac-choose = Pasirinkti

## The main window

# review: new
mac-still-running-detail = Inbox Classic ir toliau tikrina, ar yra naujų laiškų, fone. Spustelėkite jos piktogramą Dock juostoje, kad atidarytumėte programą.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } laiškas aplanke „Siunčiami laiškai“
        [few] { $count } laiškai aplanke „Siunčiami laiškai“
       *[other] { $count } laiškų aplanke „Siunčiami laiškai“
    }
# review: new
mac-sending = Siunčiama { $subject }…
# review: new
mac-checking = Tikrinami nauji laiškai: { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Ši Inbox Classic kopija nėra programos paketas, todėl ji negali būti numatytoji pašto programa.
# review: new
mac-not-made-default = Inbox Classic nenustatyta kaip numatytoji pašto programa: { $reason }
# review: new
mac-tool-search = Ieškoti

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Dar indeksuojamas { $count } laiško tekstas, todėl netrukus gali būti rasta daugiau.
       *[other] Dar indeksuojami { $count } laiškų tekstai, todėl netrukus gali būti rasta daugiau.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Visuose aplankuose nėra rezultatų pagal „{ $words }“
        [one] Visuose aplankuose pagal „{ $words }“ rastas { $count } rezultatas
        [few] Visuose aplankuose pagal „{ $words }“ rasti { $count } rezultatai
       *[other] Visuose aplankuose pagal „{ $words }“ rasta rezultatų: { $count }
    }
# review: new
mac-results-in =
    { $count ->
        [0] Aplanke „{ $folder }“ nėra rezultatų pagal „{ $words }“
        [one] Aplanke „{ $folder }“ pagal „{ $words }“ rastas { $count } rezultatas
        [few] Aplanke „{ $folder }“ pagal „{ $words }“ rasti { $count } rezultatai
       *[other] Aplanke „{ $folder }“ pagal „{ $words }“ rasta rezultatų: { $count }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] dar indeksuojamas { $count } laiško tekstas
       *[other] dar indeksuojami { $count } laiškų tekstai
    }
# review: new
mac-folder-unread = { $folder }, neskaitytų: { $count }
# review: new
mac-import-messages = Importuoti laiškus
# review: new
mac-save-messages = Įrašyti laiškus
# review: new
mac-save-attachments-menu = Įrašyti priedus…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Nepavyko įrašyti { $failed } iš { $count } failų.
    }
# review: new
mac-no-calendar-app = Šiame Mac kompiuteryje nėra kalendoriaus programos, kuri atidarytų kvietimus (.ics failus).
# review: new
mac-file-not-saved = Failo įrašyti nepavyko.
# review: new
mac-unsubscribing = Atsisakoma prenumeratos: { $target }…
# review: new
mac-loading-list = Įkeliama…

## The compose window

# review: new
mac-bold = Pusjuodis
# review: new
mac-italic = Kursyvas
# review: new
mac-underline = Pabrauktas
# review: new
mac-bcc = Slapta kopija
# review: new
mac-command-click-to-open = ⌘ ir spustelėkite, kad atidarytumėte
# review: new
mac-saving-to-drafts = Įrašoma į aplanką „Juodraščiai“…
# review: new
mac-dont-save = Neįrašyti

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } failas
        [few] { $count } failai
       *[other] { $count } failų
    }

## Accounts

# review: new
mac-next = Toliau
# review: new
mac-name-placeholder = Rūta Petraitienė
# review: new
mac-more-sign-in-options = Daugiau prisijungimo būdų…
# review: new
mac-add-sign-in-app = Pridėti prisijungimo programą…
# review: new
mac-looking-up = Ieškoma domeno { $domain } nustatymų…
# review: new
mac-add-button = Pridėti…
# review: new
mac-properties-button = Ypatybės…
# review: new
mac-signature-button = Parašas…
# review: new
mac-security-button = Sauga…
# review: new
mac-sign-in-apps-button = Prisijungimo programos…

## AI agents

# review: new
mac-forget-program = Pašalinti šią programą ir jos agentų veiklos istoriją?
# review: new
mac-forget-program-detail = Programos teisės bus panaikintos. Kitą kartą jai prisijungus vėl bus paprašyta leidimo.

## Sign-in apps

# review: new
mac-checking-issuer = Tikrinamas { $issuer }…
# review: new
mac-edit-button = Keisti…
# review: new
mac-use-for-new-accounts = Naudoti { $name } naujoms paskyroms
# review: new
mac-built-in = { $name } (įtaisytoji)

## Other windows

# review: new
mac-new-folder-button = Naujas aplankas…
# review: new
mac-edit-link = Redaguoti nuorodą…
