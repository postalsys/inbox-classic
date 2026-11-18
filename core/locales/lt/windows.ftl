# Lietuvių. Juodraštis, laukia gimtakalbio peržiūros (žr. core/locales/GLOSSARY.md).

## The main window

# review: new
win-still-running-detail = Inbox Classic ir toliau tikrina, ar yra naujų laiškų, fone. Spustelėkite piktogramą, kad atidarytumėte. Norėdami išeiti, dešiniuoju pelės mygtuku spustelėkite piktogramą ir naudokite jos meniu.
# review: new
win-default-app-not-installed = Ši Inbox Classic kopija nebuvo įdiegta, todėl Windows jos nerodo tarp pašto programų. Įdiekite ją, kad galėtumėte ją pasirinkti.
# review: new
win-default-app-settings = Windows atidarys numatytųjų programų nustatymus. Pasirinkite Inbox Classic, kad ji atidarytų MAILTO nuorodas.
# review: new
win-no-unread = Neskaitytų laiškų nėra
# review: new
win-unread-messages = { $count ->
    [one] { $count } neskaitytas laiškas
    [few] { $count } neskaityti laiškai
   *[other] { $count } neskaitytų laiškų
}
# review: new
win-print-failed = Laiško išspausdinti nepavyko.
# review: new
win-print-title-of = Spausdinti: { $subject }
# review: new
win-no-bodies = Laiškų turinio parodyti negalima.
# review: new
win-webview-failed = Nepavyko sukurti WebView2.
# review: new
win-webview-missing = WebView2 vykdymo aplinka nepasiekiama.
win-list-loading = Įkeliama...

## Buttons and words used in many windows

win-delete-button = &Panaikinti
# review: new
win-find-label = &Ieškoti:
win-save-as-button = &Įrašyti kaip...
# review: new
win-too-many-files = Per daug failų vienu metu: pasirinkite mažiau.

## The Outbox


## The compose window

# review: new
win-editor-failed = Laiškų rašyti negalima.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+spustelėkite, kad atidarytumėte)
# review: new
win-format-bold = Pusjuodis ({ $ctrl }+B)
# review: new
win-format-italic = Kursyvas ({ $ctrl }+I)
# review: new
win-format-underline = Pabrauktas ({ $ctrl }+U)
# review: new
win-format-link = Hipersaitas ({ $ctrl }+K)
# review: new
win-show-cc = &Kopija
# review: new
win-show-bcc = &Slapta kopija
win-signature-title = Parašo tekstas: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Visuose aplankuose nėra rezultatų pagal „{ $words }“
    [one] Visuose aplankuose pagal „{ $words }“ rastas { $count } rezultatas
    [few] Visuose aplankuose pagal „{ $words }“ rasti { $count } rezultatai
   *[other] Visuose aplankuose pagal „{ $words }“ rasta rezultatų: { $count }
}
# review: new
win-search-found-in = { $count ->
    [0] Aplanke „{ $folder }“ nėra rezultatų pagal „{ $words }“
    [one] Aplanke „{ $folder }“ pagal „{ $words }“ rastas { $count } rezultatas
    [few] Aplanke „{ $folder }“ pagal „{ $words }“ rasti { $count } rezultatai
   *[other] Aplanke „{ $folder }“ pagal „{ $words }“ rasta rezultatų: { $count }
}
# review: new
win-search-indexing = { $count ->
    [one] dar indeksuojamas { $count } laiško tekstas
   *[other] dar indeksuojami { $count } laiškų tekstai
}
# review: new
win-no-match-indexing = { $count ->
    [one] Dar indeksuojamas { $count } laiško tekstas, todėl netrukus gali būti rasta daugiau.
   *[other] Dar indeksuojami { $count } laiškų tekstai, todėl netrukus gali būti rasta daugiau.
}
# review: new
win-files = { $count ->
    [one] { $count } failas
    [few] { $count } failai
   *[other] { $count } failų
}
# review: new
win-click-to-retry = Spustelėkite čia, kad bandytumėte dar kartą.
# review: new
win-save-attachments = Įra&šyti priedus...
# review: new
win-files-not-saved = Nepavyko įrašyti { $failed } iš { $count } failų.
# review: new
win-new-folder-in-highlighted = Naujas aplankas bus sukurtas pažymėtame aplanke.
# review: new
win-delete-folder-ask = Panaikinti aplanką „{ $folder }“ su jo laiškais ir jame esančiais aplankais? Jis bus panaikintas ir serveryje.
win-rename = Pe&rvardyti...
# review: new
win-messages-not-saved = Laiškų įrašyti nepavyko.
# review: new
win-messages-not-forwarded = Laiškų persiųsti nepavyko.

## Accounts

# review: new
win-sign-in-google = Prisijungti naudojant Google
# review: new
win-sign-in-microsoft = Prisijungti naudojant Microsoft
# review: new
win-next = &Toliau >
# review: new
win-your-account = jūsų paskyra
# review: new
win-browser-sign-in = (prisijungimas naršyklėje)
# review: new
win-add = &Pridėti...
# review: new
win-properties-button = &Ypatybės...
win-signature-button = Parašo &tekstas...
# review: new
win-sign-in-apps-button = Prisijungimo pro&gramos...

## AI agents

# review: new
win-dont-allow = &Neleisti
# review: new
win-col-address = Adresas
# review: new
win-never-written-to = Niekada nerašyta
# review: new
win-book-find-label = Įveskite vardą arba el. pašto adresą:
# review: new
win-send = &Siųsti
# review: new
win-dont-send = &Nesiųsti
win-unsubscribe = &Atsisakyti prenumeratos
win-dont-unsubscribe = &Neatsisakyti prenumeratos
# review: new
win-forget-program-ask = Pašalinti šią programą, jos teises ir jos agentų veiklos istoriją? Kitą kartą jai prisijungus vėl bus paprašyta leidimo.
# review: new
win-clear-log-ask = Išvalyti agentų veiklos istoriją? Agentų atlikti pakeitimai nebus atšaukti.
# review: new
win-agent-programs = &Programos, kurių agentai paprašė prieigos prie jūsų pašto:
# review: new
win-change = &Keisti...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
# review: new
win-undo-since = Atšaukti &nuo...
# review: new
win-take-back = &Atšaukti
# review: new
win-what-agents-did = Agentų &veikla:
# review: new
win-agent-reads = Kas perskaityta nuo { $from } iki { $to }:
# review: new
win-agent-reads-hint = Pažymėkite viršuje skaitymų eilutę, kad pamatytumėte, kas perskaityta.
# review: new
win-how-to-connect = Kaip prijungti agentą

## Sign-in apps

# review: new
win-built-in = (įtaisytoji)
# review: new
win-edit = &Keisti...

## Options

# review: new
win-folders-hide = Slėpti aplankų sąrašą
# review: new
win-folders-pin = Laikyti aplankų sąrašą šalia laiškų
# review: new
win-folders-show = Rodyti aplankus

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Paleisti Inbox Classic
# review: new
win-installer-welcome-new =
    Bus įdiegta el. pašto programa Inbox Classic { $version }.

    Administratoriaus teisių nereikia, ji įdiegiama tik jūsų paskyrai.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } jau įdiegta. Ji bus įdiegta dar kartą.

    Jūsų paskyros ir laiškai išsaugomi.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } bus atnaujinta į { $version }.

    Jei ji veikia, pirmiausia bus uždaryta. Jūsų paskyros ir laiškai išsaugomi.
# review: new
win-installer-older-ask = Įdiegta Inbox Classic { $installed }, kuri naujesnė nei { $version }. Vis tiek įdiegti senesnę versiją?
# review: new
win-installer-still-running = Inbox Classic vis dar veikia. Uždarykite ją ir bandykite dar kartą.
# review: new
win-installer-remove-mail-ask = Taip pat pašalinti paskyras ir laiškus, kuriuos Inbox Classic laiko šiame kompiuteryje? Laiškai serveriuose lieka.
