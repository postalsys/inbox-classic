# Lietuvių. Juodraštis, laukia gimtakalbio peržiūros (žr. core/locales/GLOSSARY.md).

## The main window

# review: new
gtk-search-looks-in = Paieška ({ $place }) apima laiškų temas, siuntėjus, gavėjus, priedų pavadinimus ir tekstą. Patikrinkite rašybą arba pabandykite mažiau žodžių.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Dar indeksuojamas { $count } laiško tekstas. Netrukus gali atsirasti daugiau rezultatų.
   *[other] Dar indeksuojami { $count } laiškų tekstai. Netrukus gali atsirasti daugiau rezultatų.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Nėra rezultatų
    [one] { $count } rezultatas
    [few] { $count } rezultatai
   *[other] { $count } rezultatų
} pagal „{ $words }“ visuose aplankuose
# review: new
gtk-search-results-in = { $count ->
    [0] Nėra rezultatų
    [one] { $count } rezultatas
    [few] { $count } rezultatai
   *[other] { $count } rezultatų
} pagal „{ $words }“ ({ $place })
# review: new
gtk-search-indexing = { $count ->
    [one] dar indeksuojamas { $count } laiško tekstas
   *[other] dar indeksuojami { $count } laiškų tekstai
}
# review: new
gtk-menu-rename = Pervardyti...
# review: new
gtk-import-one-question = Importuoti laišką { $file } į aplanką „{ $folder }“?
# review: new
gtk-files-not-saved = Nepavyko įrašyti { $failed } iš { $total } failų.
# review: new
gtk-unsubscribe-one-click =
    Išeiti iš šio adresatų sąrašo?

    Inbox Classic išsiųs prenumeratos atsisakymo užklausą adresu { $target }. Joks tinklalapis nebus atidarytas ir joks el. laiškas nebus išsiųstas.
# review: new
gtk-unsubscribe-mail =
    Išeiti iš šio adresatų sąrašo?

    Norėdami atsisakyti prenumeratos, išsiųskite el. laišką adresu { $target }. Inbox Classic jį jums paruoš. Išsiųskite laišką, kad patvirtintumėte.
# review: new
gtk-unsubscribe-web =
    Išeiti iš šio adresatų sąrašo?

    Adresatų sąrašo prenumeratos atsisakymo puslapis bus atidarytas jūsų naršyklėje ({ $target }).
# review: new
gtk-unsubscribe-failed = Nepavyko atsisakyti prenumeratos: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Rašyti iš konkrečios paskyros
# review: new
gtk-toolbar-send-recv-menu = Siųsti ir gauti laiškus konkrečiai paskyrai
# review: new
gtk-main-menu = Pagrindinis meniu
# review: new
gtk-folder-list = Aplankų sąrašas
# review: new
gtk-quit = Išeiti

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Naujas aplankas bus sukurtas paskyros { $account } viršutiniame lygmenyje.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Neskaitytų laiškų nėra
    [one] { $count } neskaitytas laiškas
    [few] { $count } neskaityti laiškai
   *[other] { $count } neskaitytų laiškų
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Išsiuntimo laukiančių laiškų nėra.
# review: new
gtk-outbox-row = Kam: { $to }  ·  Įtraukta į eilę { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic ir toliau tikrina, ar yra naujų laiškų, fone. Naudokite jos piktogramą viršutinėje juostoje, kad atidarytumėte programą arba iš jos išeitumėte.
# review: new
gtk-sign-in-again-ask =
    Paskyros { $account } prisijungimas atmestas arba seansas baigėsi.

    Prisijungti iš naujo naršyklėje?
# review: new
gtk-default-app-not-installed = Ši Inbox Classic kopija nebuvo įdiegta, todėl sistema jos nerodo tarp pašto programų. Įdiekite ją, kad galėtumėte ją pasirinkti.
# review: new
gtk-default-app-now = Inbox Classic dabar yra jūsų numatytoji pašto programa: el. pašto nuorodos atveria naują laišką čia.
# review: new
gtk-default-app-failed = Nepavyko nustatyti Inbox Classic kaip numatytosios pašto programos.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Data:
# review: new
gtk-reader-files = Laiško priedai
# review: new
gtk-pictures-blocked = Kai kurie paveikslėliai užblokuoti, kad siuntėjas negalėtų atpažinti jūsų kompiuterio.
# review: new
gtk-download-pictures = Atsisiųsti paveikslėlius
# review: new
gtk-save-attachments-menu = Įrašyti priedus...

## The compose window

# review: new
gtk-format-bold = Pusjuodis (Ctrl+B)
# review: new
gtk-format-italic = Kursyvas (Ctrl+I)
# review: new
gtk-format-underline = Pabrauktas (Ctrl+U)
# review: new
gtk-format-hyperlink = Hipersaitas (Ctrl+K)
# review: new
gtk-font = Šriftas
# review: new
gtk-show-cc = _Kopija
# review: new
gtk-show-bcc = _Slapta kopija
# review: new
gtk-save-tip = Įrašyti (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+spustelėkite, kad atidarytumėte)

## Accounts

# review: new
gtk-plain-warning =
    Be šifravimo bet kas, perimantis jūsų tinklo srautą, gali perskaityti jūsų slaptažodį ir laiškus. Naudokite šį ryšį tik su serveriu, esančiu jūsų kompiuteryje arba vietiniame tinkle.

    Tęsti?
# review: new
gtk-account-name-title = Paskyros pavadinimas
# review: new
gtk-display-name-title = Rodomas vardas
# review: new
gtk-turned-off-why = Parinktis „{ $button }“ šiame kompiuteryje išjungta. { $reason }
# review: new
gtk-turned-off-why-long =
    Parinktis „{ $button }“ šiame kompiuteryje išjungta.

    { $reason }
# review: new
gtk-next = Toliau >
# review: new
gtk-provider-sign-in = Prisijunkite prie { $address } svetainėje, kurią valdo { $provider }. Jūsų slaptažodis Inbox Classic neperduodamas. Taip pat galite naudoti programos slaptažodį, sukurtą paskyros saugos nustatymuose.
# review: new
gtk-provider-sign-in-apps = Prisijunkite prie { $address } svetainėje, kurią valdo { $provider }, naudodami vieną iš savo prisijungimo programų (Daugiau prisijungimo būdų). Taip pat galite naudoti programos slaptažodį, sukurtą paskyros saugos nustatymuose.
# review: new
gtk-accounts-add = Pridėti...
# review: new
gtk-accounts-properties = Ypatybės...
# review: new
gtk-accounts-signature = Parašas...
# review: new
gtk-accounts-sign-in-apps = Prisijungimo programos...

## Sign-in apps

# review: new
gtk-app-server = { $kind } serveris
# review: new
gtk-app-port = { $kind } prievadas
# review: new
gtk-app-security = { $kind } sauga
# review: new
gtk-issuer-found =
    Prisijungimo puslapis: { $page }
    Prieigos raktų galinis taškas: { $endpoint }
# review: new
gtk-client-id = Kliento ID
# review: new
gtk-client-secret = Kliento paslaptis
# review: new
gtk-scopes = Teisės (scopes)
# review: new
gtk-redirect-uri = Peradresavimo URI
# review: new
gtk-issuer-usable =
    Išdavėją galima naudoti.

    { $found }
# review: new
gtk-app-built-in = { $app } yra įtaisytoji. Galite keisti tik tai, ar ji siūloma naujoms paskyroms. { $reason }
# review: new
gtk-built-in = { $app } (įtaisytoji)
# review: new
gtk-offered-for-new = Siūloma naujoms paskyroms
# review: new
gtk-edit-button = Keisti...
# review: new
gtk-remove-app-ask = Pašalinti prisijungimo programą { $app } ir jos įrašytą kliento paslaptį?
# review: new
gtk-sign-in-apps-intro = Prisijungimo programos leidžia paskyroms prisijungti per naršyklę. Išjungta programa naujoms paskyroms nesiūloma; ją jau naudojančios paskyros veikia toliau.

## AI agents

# review: new
gtk-agent-it-may = Leidžiami veiksmai
# review: new
gtk-agent-accounts = Leidžiamos paskyros
# review: new
gtk-never-used = Niekada nenaudota
# review: new
gtk-last-used = Paskutinį kartą naudota { $date }
# review: new
gtk-forget-program = Pašalinti šią programą?
# review: new
gtk-forget-program-detail = Programos teisės ir jos agentų veiklos istorija bus panaikintos. Kitą kartą jai prisijungus vėl bus paprašyta leidimo.
# review: new
gtk-no-agents-yet = Dar joks agentas neprašė naudotis jūsų paštu.
# review: new
gtk-nothing-yet = Kol kas nieko.

## Preferences

# review: new
gtk-preferences = Nuostatos
# review: new
gtk-language = Kalba
# review: new
gtk-language-subtitle = Programos ir žinyno kalba
# review: new
gtk-new-mail-group = Nauji laiškai
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Pranešti apie naujus laiškus
# review: new
gtk-notify-subtitle = Pranešimas, kai gaunami nauji laiškai, o langas yra fone
# review: new
gtk-restart-to-change = Inbox Classic pasileis iš naujo, kad pasikeistų kalba.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Pašto programa
# review: new
gtk-desktop-comment = Skaitykite ir rašykite el. laiškus: greita, paprasta pašto programa
# review: new
gtk-desktop-keywords = paštas;el. paštas;laiškai;gauti laiškai;
# review: new
gtk-metainfo-summary = Greita, paprasta pašto programa
# review: new
gtk-metainfo-description = Inbox Classic skaito ir rašo el. laiškus: aplankai kairėje, laiškų sąrašas viršuje, o laiškas po juo, kaip anksčiau pašto programose. Ji veikia su bet kuria IMAP ir SMTP paskyra ir prisijungia prie Outlook.com bei Microsoft 365 per naršyklę.
# review: new
gtk-metainfo-feature-sanitized = Kiekvienas laiškas rodomas išvalytas, be scenarijų, o paveikslėliai iš interneto tik jums leidus
# review: new
gtk-metainfo-feature-search = Paieška, kuri randa žodžius temoje, siuntėjuose ir gavėjuose, failų pavadinimuose ir tekste, su Gmail operatoriais
# review: new
gtk-metainfo-feature-replies = Atsakymuose suskleidžiami ankstesni cituojami laiškai
# review: new
gtk-metainfo-feature-offline = Laiškus galima skaityti ir neprisijungus prie interneto; slaptažodžiai laikomi jūsų raktinėje
