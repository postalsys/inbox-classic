# Slovenčina. Návrh, čaká na kontrolu rodeným hovoriacim (pozri core/locales/GLOSSARY.md).

## The main window

# review: new
gtk-search-looks-in = Hľadanie v priečinku { $place } prehľadáva predmety, odosielateľov, príjemcov, názvy príloh a text správ. Skontrolujte pravopis alebo skúste menej slov.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Text 1 správy sa ešte indexuje. Čoskoro sa môžu objaviť ďalšie výsledky.
   *[other] Text správ ({ $count }) sa ešte indexuje. Čoskoro sa môžu objaviť ďalšie výsledky.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Žiadne výsledky
    [one] 1 výsledok
    [few] { $count } výsledky
   *[other] { $count } výsledkov
} pre „{ $words }“ vo všetkých priečinkoch
# review: new
gtk-search-results-in = { $count ->
    [0] Žiadne výsledky
    [one] 1 výsledok
    [few] { $count } výsledky
   *[other] { $count } výsledkov
} pre „{ $words }“ v priečinku { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] text 1 správy sa ešte indexuje
   *[other] text správ ({ $count }) sa ešte indexuje
}
# review: new
gtk-menu-rename = Premenovať...
# review: new
gtk-import-one-question = Importovať správu { $file } do priečinka { $folder }?
# review: new
gtk-files-not-saved = Nepodarilo sa uložiť { $failed } z { $total } súborov.
# review: new
gtk-unsubscribe-one-click =
    Odhlásiť sa z tohto zoznamu adresátov?

    Inbox Classic pošle žiadosť o odhlásenie na { $target }. Neotvorí sa žiadna webová stránka a neodošle sa žiadny e-mail.
# review: new
gtk-unsubscribe-mail =
    Odhlásiť sa z tohto zoznamu adresátov?

    Ak sa chcete odhlásiť, pošlite e-mail na { $target }. Inbox Classic ho pre vás pripraví. Odoslaním správy odhlásenie potvrdíte.
# review: new
gtk-unsubscribe-web =
    Odhlásiť sa z tohto zoznamu adresátov?

    Stránka na odhlásenie zo zoznamu adresátov sa otvorí v prehliadači ({ $target }).
# review: new
gtk-unsubscribe-failed = Odhlásenie zlyhalo: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Napísať z konkrétneho konta
# review: new
gtk-toolbar-send-recv-menu = Odoslať a prijať poštu konkrétneho konta
# review: new
gtk-main-menu = Hlavná ponuka
# review: new
gtk-folder-list = Zoznam priečinkov
# review: new
gtk-quit = Ukončiť

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Nový priečinok bude na najvyššej úrovni konta { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Žiadne neprečítané správy
    [one] 1 neprečítaná správa
    [few] { $count } neprečítané správy
   *[other] { $count } neprečítaných správ
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Na odoslanie nečakajú žiadne správy.
# review: new
gtk-outbox-row = Komu: { $to }  ·  Zaradené { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic naďalej kontroluje novú poštu na pozadí. Aplikáciu otvoríte alebo ukončíte jej ikonou na hornej lište.
# review: new
gtk-sign-in-again-ask =
    Prihlásenie do konta { $account } bolo odmietnuté alebo relácia vypršala.

    Prihlásiť sa znova v prehliadači?
# review: new
gtk-default-app-not-installed = Táto kópia Inbox Classic nebola nainštalovaná, preto ju systém neuvádza medzi poštovými aplikáciami. Ak ju chcete vybrať, nainštalujte ju.
# review: new
gtk-default-app-now = Inbox Classic je teraz vaša predvolená poštová aplikácia: e-mailové odkazy tu otvoria novú správu.
# review: new
gtk-default-app-failed = Inbox Classic sa nepodarilo nastaviť ako predvolenú poštovú aplikáciu.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Dátum:
# review: new
gtk-reader-files = Prílohy správy
# review: new
gtk-files = { $count ->
    [one] { $count } súbor
    [few] { $count } súbory
   *[other] { $count } súborov
}
# review: new
gtk-pictures-blocked = Niektoré obrázky boli zablokované, aby odosielateľ nemohol identifikovať váš počítač.
# review: new
gtk-download-pictures = Stiahnuť obrázky
# review: new
gtk-save-attachments-menu = Uložiť prílohy...

## The compose window

# review: new
gtk-format-bold = Tučné (Ctrl+B)
# review: new
gtk-format-italic = Kurzíva (Ctrl+I)
# review: new
gtk-format-underline = Podčiarknuté (Ctrl+U)
# review: new
gtk-format-hyperlink = Hypertextový odkaz (Ctrl+K)
# review: new
gtk-font = Písmo
# review: new
gtk-show-cc = _Kópia
# review: new
gtk-show-bcc = _Skrytá kópia
# review: new
gtk-save-tip = Uložiť (Ctrl+S)
# review: new
gtk-link-status = { $link }    (otvoríte kliknutím so stlačeným Ctrl)

## Accounts

# review: new
gtk-plain-warning =
    Bez šifrovania môže ktokoľvek, kto zachytí vašu sieťovú komunikáciu, prečítať vaše heslo a správy. Toto pripojenie používajte iba so serverom vo vlastnom počítači alebo v lokálnej sieti.

    Pokračovať?
# review: new
gtk-account-name-title = Názov konta
# review: new
gtk-display-name-title = Zobrazované meno
# review: new
gtk-turned-off-why = Možnosť „{ $button }“ je v tomto počítači vypnutá. { $reason }
# review: new
gtk-turned-off-why-long =
    Možnosť „{ $button }“ je v tomto počítači vypnutá.

    { $reason }
# review: new
gtk-next = Ďalej >
# review: new
gtk-provider-sign-in = Prihláste sa ku kontu { $address } cez { $provider } na jeho webovej stránke. Vaše heslo sa s Inbox Classic nezdieľa. Môžete použiť aj heslo aplikácie vytvorené v nastaveniach zabezpečenia konta.
# review: new
gtk-provider-sign-in-apps = Prihláste sa ku kontu { $address } cez { $provider } na jeho webovej stránke pomocou jednej zo svojich prihlasovacích aplikácií (Ďalšie možnosti prihlásenia). Môžete použiť aj heslo aplikácie vytvorené v nastaveniach zabezpečenia konta.
# review: new
gtk-accounts-add = Pridať...
# review: new
gtk-accounts-properties = Vlastnosti...
# review: new
gtk-accounts-signature = Podpis...
# review: new
gtk-accounts-sign-in-apps = Prihlasovacie aplikácie...

## Sign-in apps

# review: new
gtk-app-server = Server { $kind }
# review: new
gtk-app-port = Port { $kind }
# review: new
gtk-app-security = Zabezpečenie { $kind }
# review: new
gtk-issuer-found =
    Prihlasovacia stránka: { $page }
    Koncový bod tokenov: { $endpoint }
# review: new
gtk-client-id = ID klienta
# review: new
gtk-client-secret = Tajný kód klienta
# review: new
gtk-scopes = Oprávnenia (scopes)
# review: new
gtk-redirect-uri = URI presmerovania
# review: new
gtk-issuer-usable =
    Vydavateľa možno použiť.

    { $found }
# review: new
gtk-app-built-in = { $app } je vstavaná. Môžete zmeniť iba to, či sa ponúka pre nové kontá. { $reason }
# review: new
gtk-built-in = { $app } (vstavaná)
# review: new
gtk-offered-for-new = Ponúkať pre nové kontá
# review: new
gtk-edit-button = Upraviť...
# review: new
gtk-remove-app-ask = Odstrániť prihlasovaciu aplikáciu { $app } aj s jej uloženým tajným kódom klienta?
# review: new
gtk-sign-in-apps-intro = Prihlasovacie aplikácie umožňujú kontám prihlasovať sa cez prehliadač. Vypnutá aplikácia sa pre nové kontá neponúka; kontá, ktoré ju už používajú, fungujú ďalej.

## AI agents

# review: new
gtk-agent-it-may = Povolené akcie
# review: new
gtk-agent-accounts = Povolené kontá
# review: new
gtk-never-used = Nikdy nepoužité
# review: new
gtk-last-used = Naposledy použité { $date }
# review: new
gtk-forget-program = Odstrániť tento program?
# review: new
gtk-forget-program-detail = Oprávnenia programu a história aktivity jeho agentov sa odstránia. Pri ďalšom pripojení sa vás znova opýta na povolenie.
# review: new
gtk-no-agents-yet = Zatiaľ žiadny agent nepožiadal o používanie vašej pošty.
# review: new
gtk-nothing-yet = Zatiaľ nič.

## Preferences

# review: new
gtk-preferences = Predvoľby
# review: new
gtk-language = Jazyk
# review: new
gtk-language-subtitle = Jazyk aplikácie a pomocníka
# review: new
gtk-new-mail-group = Nová pošta
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Upozorňovať na novú poštu
# review: new
gtk-notify-subtitle = Upozornenie, keď prídu nové správy, kým je okno na pozadí
# review: new
gtk-restart-to-change = Inbox Classic sa na zmenu jazyka reštartuje.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Poštový klient
# review: new
gtk-desktop-comment = Čítanie a písanie e-mailov: rýchly a jednoduchý poštový program
# review: new
gtk-desktop-keywords = pošta;e-mail;email;správa;správy;doručená pošta;
# review: new
gtk-metainfo-summary = Rýchly a jednoduchý poštový program
# review: new
gtk-metainfo-description = Inbox Classic číta a píše e-maily s priečinkami vľavo, správami hore a správou pod nimi, ako to poštové programy kedysi robili. Funguje s ľubovoľným kontom IMAP a SMTP a do Outlook.com a Microsoft 365 sa prihlasuje cez prehliadač.
# review: new
gtk-metainfo-feature-sanitized = Každá správa sa zobrazuje očistená, bez skriptov, a obrázky z internetu iba vtedy, keď ich povolíte
# review: new
gtk-metainfo-feature-search = Hľadanie, ktoré nájde slová v predmete, ľuďoch, názvoch súborov aj texte, s operátormi Gmailu
# review: new
gtk-metainfo-feature-replies = Odpovede skryjú staršie správy, ktoré citujú
# review: new
gtk-metainfo-feature-offline = Pošta zostáva čitateľná aj offline; heslá sa uchovávajú vo vašej kľúčenke
