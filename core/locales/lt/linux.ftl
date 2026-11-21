# Lietuvių. Juodraštis, laukia gimtakalbio peržiūros (žr. core/locales/GLOSSARY.md).

## The main window

gtk-search-looks-in = Ieškoma laiškų temose, siuntėjų ir gavėjų varduose bei adresuose, priedų pavadinimuose ir laiškų tekste. Paieškos vieta: { $place }. Patikrinkite rašybą arba įveskite mažiau žodžių.
gtk-search-still-indexing = { $count ->
    [one] Dar indeksuojamas { $count } laiško tekstas. Netrukus gali atsirasti daugiau rezultatų.
   *[other] Dar indeksuojami { $count } laiškų tekstai. Netrukus gali atsirasti daugiau rezultatų.
}
gtk-search-results-everywhere = { $count ->
    [0] Nėra rezultatų
    [one] { $count } rezultatas
    [few] { $count } rezultatai
   *[other] { $count } rezultatų
} pagal „{ $words }“ visuose aplankuose
gtk-search-results-in = { $count ->
    [0] Nėra rezultatų
    [one] { $count } rezultatas
    [few] { $count } rezultatai
   *[other] { $count } rezultatų
} pagal „{ $words }“ ({ $place })
gtk-search-indexing = { $count ->
    [one] dar indeksuojamas { $count } laiško tekstas
   *[other] dar indeksuojami { $count } laiškų tekstai
}
gtk-list-loading = Įkeliama...
gtk-menu-rename = Pervardyti...
gtk-import-one-question = Importuoti laišką iš failo „{ $file }“ į aplanką „{ $folder }“?
gtk-files-not-saved = Nepavyko įrašyti failų: { $failed }. Iš viso: { $total }.
gtk-unsubscribe-one-click = Atsisakyti šio adresatų sąrašo prenumeratos?

    Inbox Classic išsiųs prašymą atsisakyti prenumeratos į serverį { $target }. Naršyklės puslapis nebus atvertas ir el. laiškas nebus siunčiamas.
gtk-unsubscribe-mail = Atsisakyti šio adresatų sąrašo prenumeratos?

    Inbox Classic paruoš prašymą adresu { $target }. Kad pateiktumėte prašymą atsisakyti prenumeratos, išsiųskite paruoštą laišką.
gtk-unsubscribe-web = Atsisakyti šio adresatų sąrašo prenumeratos?

    Naršyklėje bus atvertas prenumeratos atsisakymo puslapis svetainėje { $target }.
gtk-unsubscribe-failed = Nepavyko atsisakyti prenumeratos: { $problem }
gtk-toolbar-create-mail-menu = Pasirinkti paskyrą laiškui rašyti
gtk-toolbar-send-recv-menu = Pasirinkti paskyrą paštui siųsti ir gauti
gtk-main-menu = Pagrindinis meniu
gtk-folder-list = Aplankų sąrašas
gtk-quit = Išeiti

## The Move and Copy window

gtk-new-folder-at-top-of = Naujas aplankas bus sukurtas paskyros „{ $account }“ viršutiniame lygmenyje.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Neskaitytų laiškų nėra
    [one] { $count } neskaitytas laiškas
    [few] { $count } neskaityti laiškai
   *[other] { $count } neskaitytų laiškų
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Išsiuntimo laukiančių laiškų nėra.
gtk-outbox-row = Kam: { $to }  ·  Įtraukimo į eilę laikas: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic fone ir toliau tikrina, ar yra naujų laiškų. Programą galite atverti arba užverti naudodami jos piktogramą sistemos juostoje.
gtk-sign-in-again-ask = Prisijungimas prie paskyros „{ $account }“ atmestas arba seansas baigėsi.

    Prisijungti iš naujo naršyklėje?
gtk-default-app-not-installed = Ši Inbox Classic kopija nebuvo įdiegta, todėl sistema jos nerodo tarp pašto programų. Įdiekite ją, kad galėtumėte ją pasirinkti.
gtk-default-app-now = Inbox Classic dabar yra jūsų numatytoji pašto programa. El. pašto nuorodos atvers naujo laiško langą šioje programoje.
gtk-default-app-failed = Nepavyko nustatyti Inbox Classic kaip numatytosios pašto programos.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Data:
gtk-reader-files = Laiško priedai
gtk-files = { $count ->
    [one] { $count } failas
    [few] { $count } failai
   *[other] { $count } failų
}
gtk-download-pictures = Atsisiųsti paveikslėlius
gtk-save-attachments-menu = Įrašyti priedus...

## The compose window

gtk-format-bold = Pusjuodis (Ctrl+B)
gtk-format-italic = Kursyvas (Ctrl+I)
gtk-format-underline = Pabrauktas (Ctrl+U)
gtk-format-hyperlink = Hipersaitas (Ctrl+K)
gtk-font = Šriftas
gtk-show-cc = _Kopija
gtk-show-bcc = _Slapta kopija
gtk-save-tip = Įrašyti (Ctrl+S)
gtk-link-status = { $link }    (Atidaryti: Ctrl + pelės spustelėjimas)

## Accounts

gtk-plain-warning =
    Be šifravimo bet kas, perimantis jūsų tinklo srautą, gali perskaityti jūsų slaptažodį ir laiškus. Naudokite šį ryšį tik su serveriu, esančiu jūsų kompiuteryje arba vietiniame tinkle.

    Tęsti?
gtk-account-name-title = Paskyros pavadinimas
gtk-display-name-title = Rodomas vardas
gtk-turned-off-why = Parinktis „{ $button }“ šiame kompiuteryje išjungta. { $reason }
gtk-turned-off-why-long =
    Parinktis „{ $button }“ šiame kompiuteryje išjungta.

    { $reason }
gtk-next = Toliau >
gtk-provider-sign-in = Prisijunkite prie paskyros { $address } svetainėje, kurią valdo { $provider }. Inbox Classic negaus jūsų slaptažodžio. Jei jūsų paskyroje leidžiama naudoti programos slaptažodį paštui, galite jį sukurti paskyros saugos nustatymuose. Prie Outlook.com ir Microsoft 365 paskyrų čia prisijungiama tik per naršyklę.
gtk-provider-sign-in-apps = Prisijunkite prie paskyros { $address } svetainėje, kurią valdo { $provider }, naudodami vieną iš savo prisijungimo programų (parinktis „Daugiau prisijungimo būdų“). Jei jūsų paskyroje leidžiama naudoti programos slaptažodį paštui, galite jį sukurti paskyros saugos nustatymuose. Prie Outlook.com ir Microsoft 365 paskyrų čia prisijungiama tik per naršyklę.
gtk-accounts-add = Pridėti...
gtk-accounts-properties = Ypatybės...
gtk-accounts-signature = Parašo tekstas...
gtk-accounts-sign-in-apps = Prisijungimo programos...

## Sign-in apps

gtk-app-server = { $kind } serveris
gtk-app-port = { $kind } prievadas
gtk-app-security = { $kind } sauga
gtk-issuer-found =
    Prisijungimo puslapis: { $page }
    Prieigos raktų galinis taškas: { $endpoint }
gtk-client-id = Kliento ID
gtk-client-secret = Kliento paslaptis
gtk-scopes = Teisės (scopes)
gtk-redirect-uri = Peradresavimo URI
gtk-issuer-usable =
    Išdavėją galima naudoti.

    { $found }
gtk-app-built-in = Prisijungimo programa „{ $app }“ yra įtaisyta. Galite tik pasirinkti, ar ji bus siūloma naujoms paskyroms. { $reason }
gtk-built-in = { $app } (įtaisytoji)
gtk-offered-for-new = Siūloma naujoms paskyroms
gtk-edit-button = Keisti...
gtk-remove-app-ask = Pašalinti prisijungimo programą „{ $app }“ ir jos įrašytą kliento paslaptį?
gtk-sign-in-apps-intro = Prisijungimo programos leidžia paskyroms prisijungti per naršyklę. Išjungta programa naujoms paskyroms nesiūloma; ją jau naudojančios paskyros veikia toliau.

## AI agents

gtk-agent-it-may = Leidžiami veiksmai
gtk-agent-accounts = Prieiga prie paskyrų
gtk-never-used = Prieiga dar nenaudota
gtk-last-used = Paskutinė prieiga: { $date }
gtk-forget-program = Pašalinti šią programą iš sąrašo?
gtk-forget-program-detail = Bus panaikintos programos prieigos teisės ir jos agentų veiklos istorija. Kitą kartą jai prisijungus vėl bus paprašyta leidimo.
gtk-no-agents-yet = Dar joks agentas neprašė naudotis jūsų paštu.
gtk-nothing-yet = Kol kas nieko.

## Preferences

gtk-preferences = Nuostatos
gtk-notify-subtitle = Tik kai pagrindinis langas nėra aktyvus

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Pašto programa
gtk-desktop-comment = Skaitykite ir rašykite el. laiškus: greita, paprasta pašto programa
gtk-desktop-keywords = paštas;el. paštas;laiškai;gauti laiškai;
gtk-metainfo-summary = Greita, paprasta pašto programa
gtk-metainfo-description = Inbox Classic yra el. pašto programa su įprastu išdėstymu: aplankai kairėje, laiškų sąrašas viršuje, o skaitomas laiškas apačioje. Ji palaiko IMAP ir SMTP paskyras. Prie Outlook.com ir Microsoft 365 prisijungiama per naršyklę.
gtk-metainfo-feature-sanitized = Prieš rodant iš laiškų pašalinami scenarijai ir kitas neleidžiamas turinys; paveikslėliai iš interneto atsisiunčiami tik jums leidus
gtk-metainfo-feature-search = Paieška pagal laiškų temas, siuntėjų ir gavėjų vardus bei adresus, priedų pavadinimus ir tekstą, su Gmail stiliaus paieškos operatoriais
gtk-metainfo-feature-replies = Atsakymuose suskleidžiami ankstesni cituojami laiškai
gtk-metainfo-feature-offline = Laiškus galima skaityti be interneto, kol išsaugota vietinė kopija; prisijungimo duomenys paprastai saugomi sistemos raktinėje, jei ji pasiekiama
