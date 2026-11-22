# Lietuvių. Juodraštis, laukia gimtakalbio peržiūros (žr. core/locales/GLOSSARY.md).

## The main window

win-still-running-detail = Inbox Classic fone ir toliau tikrina, ar yra naujų laiškų. Spustelėkite programos piktogramą, kad atvertumėte jos langą. Norėdami išeiti, dešiniuoju pelės mygtuku spustelėkite piktogramą ir pasirinkite išėjimo komandą.
win-default-app-not-installed = Ši Inbox Classic kopija nebuvo įdiegta, todėl Windows jos nerodo tarp pašto programų. Įdiekite ją, kad galėtumėte ją pasirinkti.
win-default-app-settings = Windows atidarys numatytųjų programų nustatymus. Pasirinkite Inbox Classic, kad ji atidarytų MAILTO nuorodas.
win-no-unread = Neskaitytų laiškų nėra
win-unread-messages = { $count ->
    [one] { $count } neskaitytas laiškas
    [few] { $count } neskaityti laiškai
   *[other] { $count } neskaitytų laiškų
}
win-print-failed = Laiško išspausdinti nepavyko.
win-print-title-of = Spausdinti: { $subject }
win-no-bodies = Laiškų turinio parodyti negalima.
win-webview-failed = WebView2 komponento paleisti nepavyko.
win-webview-missing = WebView2 vykdymo aplinka nepasiekiama.
win-list-loading = Įkeliama...

## Buttons and words used in many windows

win-delete-button = &Panaikinti
win-find-label = &Ieškoti:
win-save-as-button = &Įrašyti kaip...
win-too-many-files = Per daug failų vienu metu: pasirinkite mažiau.

## The Outbox


## The compose window

win-editor-failed = Laiškų rašyti negalima.
win-ctrl-click-to-open = (Atidaryti: { $ctrl } + pelės spustelėjimas)
win-format-bold = Pusjuodis ({ $ctrl }+B)
win-format-italic = Kursyvas ({ $ctrl }+I)
win-format-underline = Pabrauktas ({ $ctrl }+U)
win-format-link = Hipersaitas ({ $ctrl }+K)
win-show-cc = &Kopija
win-show-bcc = &Slapta kopija
win-signature-title = Parašo tekstas: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Visuose aplankuose nėra rezultatų pagal „{ $words }“
    [one] Visuose aplankuose pagal „{ $words }“ rastas { $count } rezultatas
    [few] Visuose aplankuose pagal „{ $words }“ rasti { $count } rezultatai
   *[other] Visuose aplankuose pagal „{ $words }“ rasta rezultatų: { $count }
}
win-search-found-in = { $count ->
    [0] Aplanke „{ $folder }“ nėra rezultatų pagal „{ $words }“
    [one] Aplanke „{ $folder }“ pagal „{ $words }“ rastas { $count } rezultatas
    [few] Aplanke „{ $folder }“ pagal „{ $words }“ rasti { $count } rezultatai
   *[other] Aplanke „{ $folder }“ pagal „{ $words }“ rasta rezultatų: { $count }
}
win-search-indexing = { $count ->
    [one] dar indeksuojamas { $count } laiško tekstas
   *[other] dar indeksuojami { $count } laiškų tekstai
}
win-no-match-indexing = { $count ->
    [one] Dar indeksuojamas { $count } laiško tekstas, todėl netrukus gali atsirasti daugiau rezultatų.
   *[other] Dar indeksuojami { $count } laiškų tekstai, todėl netrukus gali atsirasti daugiau rezultatų.
}
win-files = { $count ->
    [one] { $count } failas
    [few] { $count } failai
   *[other] { $count } failų
}
win-save-attachments = Įra&šyti priedus...
win-files-not-saved = Nepavyko įrašyti failų: { $failed }. Iš viso: { $count }.
win-new-folder-in-highlighted = Naujas aplankas bus sukurtas pažymėtame aplanke.
win-delete-folder-ask = Panaikinti aplanką „{ $folder }“ su jo laiškais ir jame esančiais aplankais? Jis bus panaikintas ir serveryje.
win-rename = Pe&rvardyti...
win-messages-not-saved = Laiškų įrašyti nepavyko.
win-messages-not-forwarded = Laiškų persiųsti nepavyko.

## Accounts

win-sign-in-google = Prisijungti naudojant Google
win-sign-in-microsoft = Prisijungti naudojant Microsoft
win-next = &Toliau >
win-your-account = jūsų paskyra
win-browser-sign-in = (prisijungimas naršyklėje)
win-add = &Pridėti...
win-properties-button = &Ypatybės...
win-signature-button = Parašo &tekstas...
win-sign-in-apps-button = Prisijungimo pro&gramos...

## AI agents

win-dont-allow = &Neleisti
win-col-address = Adresas
win-never-written-to = Niekada nerašyta
win-book-find-label = Įveskite vardą arba el. pašto adresą:
win-send = &Siųsti
win-dont-send = &Nesiųsti
win-unsubscribe = &Atsisakyti prenumeratos
win-dont-unsubscribe = &Neatsisakyti prenumeratos
win-forget-program-ask = Pašalinti šią programą iš sąrašo, jos prieigos teises ir agentų veiklos istoriją? Kitą kartą jai prisijungus vėl bus paprašyta leidimo.
win-clear-log-ask = Išvalyti agentų veiklos istoriją? Agentų atlikti pakeitimai nebus atšaukti.
win-agent-programs = &Programos, kurių agentai paprašė prieigos prie jūsų pašto:
win-change = &Keisti...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Atšaukti pakei&timus...
win-take-back = &Atšaukti pakeitimus
win-what-agents-did = Agentų &veikla:
win-agent-reads = Pasiekti duomenys nuo { $from } iki { $to }:
win-agent-reads-hint = Viršuje pasirinkite skaitymo veiklos įrašą, kad pamatytumėte, kokie duomenys buvo pasiekti.

## Sign-in apps

win-built-in = (įtaisytoji)
win-edit = &Keisti...

## Options

win-folders-hide = Slėpti aplankų sąrašą
win-folders-pin = Laikyti aplankų sąrašą šalia laiškų
win-folders-show = Rodyti aplankus

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Paleisti Inbox Classic
win-installer-welcome-new = Bus įdiegta el. pašto programa Inbox Classic { $version }.

    Administratoriaus teisių nereikia. Programa bus įdiegta tik jūsų Windows naudotojo paskyrai.
win-installer-welcome-same = Inbox Classic { $version } jau įdiegta. Programa bus įdiegta iš naujo.

    Jūsų pašto paskyros ir laiškai bus išsaugoti.
win-installer-welcome-update = Bus atnaujinta Inbox Classic: versija { $installed } bus pakeista į { $version }.

    Jei programa veikia, ji pirmiausia bus uždaryta. Jūsų pašto paskyros ir laiškai bus išsaugoti.
win-installer-older-ask = Jau įdiegta naujesnė Inbox Classic versija ({ $installed }). Vis tiek įdiegti senesnę versiją ({ $version })?
win-installer-still-running = Inbox Classic vis dar veikia. Uždarykite ją ir bandykite dar kartą.
win-installer-remove-mail-ask = Taip pat pašalinti visus vietinius Inbox Classic duomenis, įskaitant paskyras, laiškus, siuntimo eilę, nuostatas, adresatus, taisykles ir šifravimo raktus? Laiškai serveriuose ir įrašai sistemos prisijungimo duomenų saugykloje liks.
