# Slovenčina. Návrh, čaká na kontrolu rodeným hovoriacim (pozri core/locales/GLOSSARY.md).

## The main window

gtk-search-looks-in = Rozsah vyhľadávania: „{ $place }“. Vyhľadávanie zahŕňa predmety, mená a adresy odosielateľov a príjemcov, názvy príloh a text správ. Skontrolujte pravopis alebo skúste zadať menej slov.
gtk-search-still-indexing = { $count ->
    [one] Text 1 správy sa ešte indexuje. Čoskoro sa môžu objaviť ďalšie výsledky.
   *[other] Text správ ({ $count }) sa ešte indexuje. Čoskoro sa môžu objaviť ďalšie výsledky.
}
gtk-search-results-everywhere = { $count ->
    [0] Žiadne výsledky
    [one] 1 výsledok
    [few] { $count } výsledky
   *[other] { $count } výsledkov
} pre „{ $words }“ vo všetkých priečinkoch
gtk-search-results-in = { $count ->
    [0] Žiadne výsledky
    [one] 1 výsledok
    [few] { $count } výsledky
   *[other] { $count } výsledkov
} pre „{ $words }“ (rozsah: { $place })
gtk-search-indexing = { $count ->
    [one] text 1 správy sa ešte indexuje
   *[other] text správ ({ $count }) sa ešte indexuje
}
gtk-list-loading = Načítava sa...
gtk-menu-rename = Premenovať...
gtk-import-one-question = Importovať správu zo súboru „{ $file }“ do priečinka „{ $folder }“?
gtk-files-not-saved = Nepodarilo sa uložiť súbory: { $failed } z { $total }.
gtk-unsubscribe-one-click =
    Odhlásiť odber týchto správ?

    Inbox Classic pošle žiadosť o odhlásenie odberu na server { $target }. Neotvorí sa žiadna webová stránka a neodošle sa žiadny e-mail.
gtk-unsubscribe-mail =
    Odhlásiť odber týchto správ?

    Ak chcete odhlásiť odber, pošlite e-mail na adresu { $target }. Inbox Classic ho pre vás pripraví. Žiadosť potom odošlite.
gtk-unsubscribe-web =
    Odhlásiť odber týchto správ?

    V prehliadači sa otvorí stránka na odhlásenie odberu ({ $target }).
gtk-unsubscribe-failed = Odber sa nepodarilo odhlásiť: { $problem }
gtk-toolbar-create-mail-menu = Napísať z konkrétneho konta
gtk-toolbar-send-recv-menu = Odoslať a prijať poštu konkrétneho konta
gtk-main-menu = Hlavná ponuka
gtk-folder-list = Zoznam priečinkov
gtk-quit = Ukončiť

## The Move and Copy window

gtk-new-folder-at-top-of = Nový priečinok bude na najvyššej úrovni konta { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Žiadne neprečítané správy
    [one] 1 neprečítaná správa
    [few] { $count } neprečítané správy
   *[other] { $count } neprečítaných správ
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Na odoslanie nečakajú žiadne správy.
gtk-outbox-row = Komu: { $to }  ·  Zaradené na odoslanie: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic naďalej kontroluje novú poštu na pozadí. Aplikáciu otvoríte alebo ukončíte jej ikonou na hornej lište.
gtk-sign-in-again-ask =
    Prihlásenie do konta { $account } bolo odmietnuté alebo relácia vypršala.

    Prihlásiť sa znova v prehliadači?
gtk-default-app-not-installed = Táto kópia Inbox Classic nebola nainštalovaná, preto ju systém neuvádza medzi poštovými aplikáciami. Ak ju chcete vybrať, nainštalujte ju.
gtk-default-app-now = Inbox Classic je teraz vaša predvolená poštová aplikácia: e-mailové odkazy tu otvoria novú správu.
gtk-default-app-failed = Inbox Classic sa nepodarilo nastaviť ako predvolenú poštovú aplikáciu.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Dátum:
gtk-reader-files = Prílohy správy
gtk-files = { $count ->
    [one] { $count } súbor
    [few] { $count } súbory
   *[other] { $count } súborov
}
gtk-save-attachments-menu = Uložiť prílohy...

## The compose window

gtk-format-bold = Tučné (Ctrl+B)
gtk-format-italic = Kurzíva (Ctrl+I)
gtk-format-underline = Podčiarknuté (Ctrl+U)
gtk-format-hyperlink = Hypertextový odkaz (Ctrl+K)
gtk-font = Písmo
gtk-show-cc = _Kópia
gtk-show-bcc = _Skrytá kópia
gtk-save-tip = Uložiť (Ctrl+S)
gtk-link-status = { $link }    (otvoríte kliknutím so stlačeným Ctrl)

## Accounts

gtk-plain-warning =
    Bez šifrovania môže ktokoľvek, kto zachytí vašu sieťovú komunikáciu, prečítať vaše heslo a správy. Samotná lokálna sieť neposkytuje šifrovanie. Pokračujte len vtedy, ak je pripojenie chránené iným spôsobom.

    Pokračovať?
gtk-account-name-title = Názov konta
gtk-display-name-title = Zobrazované meno
gtk-turned-off-why = Možnosť „{ $button }“ je v tomto počítači vypnutá. { $reason }
gtk-turned-off-why-long =
    Možnosť „{ $button }“ je v tomto počítači vypnutá.

    { $reason }
gtk-next = Ďalej >
gtk-provider-sign-in = Prihláste sa ku kontu { $address } cez { $provider } na jeho webovej stránke. Inbox Classic nedostane vaše heslo. Ak konto podporuje heslá aplikácií pre poštové programy, môžete použiť aj takéto heslo vytvorené v nastaveniach zabezpečenia konta. Outlook.com a Microsoft 365 podporujú iba prihlásenie cez prehliadač.
gtk-provider-sign-in-apps = Prihláste sa ku kontu { $address } cez { $provider } na jeho webovej stránke pomocou jednej zo svojich prihlasovacích aplikácií (Ďalšie možnosti prihlásenia). Ak konto podporuje heslá aplikácií pre poštové programy, môžete použiť aj takéto heslo vytvorené v nastaveniach zabezpečenia konta. Outlook.com a Microsoft 365 podporujú iba prihlásenie cez prehliadač.
gtk-accounts-add = Pridať...
gtk-accounts-properties = Vlastnosti...
gtk-accounts-signature = Textový podpis...
gtk-accounts-sign-in-apps = Prihlasovacie aplikácie...

## Sign-in apps

gtk-app-server = Server { $kind }
gtk-app-port = Port { $kind }
gtk-app-security = Zabezpečenie { $kind }
gtk-issuer-found =
    Prihlasovacia stránka: { $page }
    Koncový bod tokenov: { $endpoint }
gtk-client-id = ID klienta
gtk-client-secret = Tajný kód klienta
gtk-scopes = Rozsahy oprávnení
gtk-redirect-uri = URI presmerovania
gtk-issuer-usable =
    Vydavateľa možno použiť.

    { $found }
gtk-app-built-in = Aplikácia „{ $app }“ je vstavaná. Môžete len zmeniť, či sa má ponúkať pri pridávaní kont. { $reason }
gtk-built-in = { $app } (vstavaná)
gtk-offered-for-new = Ponúkať pre nové kontá
gtk-edit-button = Upraviť...
gtk-remove-app-ask = Odstrániť prihlasovaciu aplikáciu { $app } aj s jej uloženým tajným kódom klienta?
gtk-sign-in-apps-intro = Prihlasovacie aplikácie umožňujú kontám prihlasovať sa cez prehliadač. Vypnutá aplikácia sa pre nové kontá neponúka; kontá, ktoré ju už používajú, fungujú ďalej.

## AI agents

gtk-agent-it-may = Povolené akcie
gtk-agent-accounts = Povolené kontá
gtk-never-used = Zatiaľ nepoužité
gtk-last-used = Naposledy použité: { $date }
gtk-forget-program = Odstrániť uložené oprávnenia tohto programu?
gtk-forget-program-detail = Oprávnenia programu a história aktivity jeho agentov sa odstránia. Pri ďalšom pripojení vás Inbox Classic znova požiada o povolenie.
gtk-no-agents-yet = Zatiaľ žiadny agent nepožiadal o používanie vašej pošty.
gtk-nothing-yet = Zatiaľ nič.

## Preferences

gtk-preferences = Predvoľby
gtk-notify-subtitle = Len keď hlavné okno nie je v popredí

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Poštový klient
gtk-desktop-comment = Čítanie a písanie e-mailov: rýchly a jednoduchý poštový program
gtk-desktop-keywords = pošta;e-mail;email;správa;správy;doručená pošta;
gtk-metainfo-summary = Rýchly a jednoduchý poštový program
gtk-metainfo-description = Inbox Classic umožňuje čítať a písať e-maily v klasickom rozložení: priečinky vľavo, zoznam správ hore a obsah vybranej správy pod ním. Podporuje kontá IMAP a SMTP aj prihlásenie do Outlook.com a Microsoft 365 cez prehliadač.
gtk-metainfo-feature-sanitized = Správy sa zobrazujú bez skriptov a ďalších aktívnych prvkov; obrázky z internetu sa načítajú iba s vaším súhlasom
gtk-metainfo-feature-search = Vyhľadávanie v predmetoch, údajoch odosielateľov a príjemcov, názvoch príloh aj texte správ, s operátormi známymi z Gmailu
gtk-metainfo-feature-replies = Citované staršie správy sú v odpovediach zbalené
gtk-metainfo-feature-offline = Poštu možno čítať bez internetu, kým je uložená jej miestna kópia; prihlasovacie údaje sa zvyčajne uchovávajú v systémovom úložisku, ak je dostupné
