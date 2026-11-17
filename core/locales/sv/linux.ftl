# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Inställningar, Avsluta).

## The main window

# review: new
gtk-search-looks-in = Sökningen i { $place } omfattar ämnen, avsändare, mottagare, namn på bilagor och meddelandetext. Kontrollera stavningen eller försök med färre ord.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Texten i { $count } meddelande indexeras fortfarande. Fler resultat kan snart visas.
   *[other] Texten i { $count } meddelanden indexeras fortfarande. Fler resultat kan snart visas.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Inga resultat
    [one] { $count } resultat
   *[other] { $count } resultat
} för ”{ $words }” i alla mappar
# review: new
gtk-search-results-in = { $count ->
    [0] Inga resultat
    [one] { $count } resultat
   *[other] { $count } resultat
} för ”{ $words }” i { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] indexerar fortfarande texten i { $count } meddelande
   *[other] indexerar fortfarande texten i { $count } meddelanden
}
# review: new
gtk-list-loading = Läser in...
# review: new
gtk-menu-rename = Byt namn...
# review: new
gtk-import-one-question = Vill du importera meddelandet { $file } till { $folder }?
# review: new
gtk-files-not-saved = { $failed } av de { $total } filerna kunde inte sparas.
# review: new
gtk-unsubscribe-one-click =
    Lämna den här e-postlistan?

    Inbox Classic skickar en begäran om att avsluta prenumerationen till { $target }. Ingen webbsida öppnas och inget e-postmeddelande skickas.
# review: new
gtk-unsubscribe-mail =
    Lämna den här e-postlistan?

    Skicka ett e-postmeddelande till { $target } för att avsluta prenumerationen. Inbox Classic förbereder det åt dig. Skicka meddelandet för att bekräfta.
# review: new
gtk-unsubscribe-web =
    Lämna den här e-postlistan?

    E-postlistans sida för att avsluta prenumerationen öppnas i webbläsaren ({ $target }).
# review: new
gtk-unsubscribe-failed = Det gick inte att avsluta prenumerationen: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Skriv från ett visst konto
# review: new
gtk-toolbar-send-recv-menu = Skicka och ta emot e-post för ett visst konto
# review: new
gtk-main-menu = Huvudmeny
# review: new
gtk-folder-list = Mapplista
# review: new
gtk-quit = Avsluta

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Den nya mappen hamnar på översta nivån i { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Inga olästa meddelanden
    [one] { $count } oläst meddelande
   *[other] { $count } olästa meddelanden
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Inga meddelanden väntar på att skickas.
# review: new
gtk-outbox-row = Till: { $to }  ·  Köat { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic fortsätter att söka efter ny e-post i bakgrunden. Använd ikonen i den övre raden för att öppna eller avsluta appen.
# review: new
gtk-sign-in-again-ask =
    Inloggningen till { $account } avvisades eller så har sessionen gått ut.

    Logga in igen i webbläsaren?
# review: new
gtk-default-app-not-installed = Den här kopian av Inbox Classic har inte installerats, så systemet visar den inte som ett e-postprogram. Installera den för att kunna välja den.
# review: new
gtk-default-app-now = Inbox Classic är nu ditt standardprogram för e-post: e-postlänkar öppnar ett nytt meddelande här.
# review: new
gtk-default-app-failed = Inbox Classic kunde inte göras till standardprogram för e-post.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Datum:
# review: new
gtk-reader-files = Meddelandets bilagor
# review: new
gtk-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
# review: new
gtk-pictures-blocked = Vissa bilder har blockerats för att hindra avsändaren från att identifiera din dator.
# review: new
gtk-download-pictures = Hämta bilder
# review: new
gtk-save-attachments-menu = Spara bilagor...

## The compose window

# review: new
gtk-format-bold = Fet (Ctrl+B)
# review: new
gtk-format-italic = Kursiv (Ctrl+I)
# review: new
gtk-format-underline = Understruken (Ctrl+U)
# review: new
gtk-format-hyperlink = Hyperlänk (Ctrl+K)
# review: new
gtk-font = Typsnitt
# review: new
gtk-show-cc = _Kopia
# review: new
gtk-show-bcc = _Hemlig kopia
# review: new
gtk-save-tip = Spara (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+klicka för att öppna)

## Accounts

# review: new
gtk-plain-warning =
    Utan kryptering kan alla som avlyssnar din nätverkstrafik läsa ditt lösenord och dina meddelanden. Använd bara den här anslutningen med en server på din egen dator eller ditt lokala nätverk.

    Vill du fortsätta?
# review: new
gtk-account-name-title = Kontonamn
# review: new
gtk-display-name-title = Visningsnamn
# review: new
gtk-turned-off-why = Alternativet ”{ $button }” är avstängt på den här datorn. { $reason }
# review: new
gtk-turned-off-why-long =
    Alternativet ”{ $button }” är avstängt på den här datorn.

    { $reason }
# review: new
gtk-next = Nästa >
# review: new
gtk-provider-sign-in = Logga in på { $address } på webbplatsen för { $provider }. Ditt lösenord delas inte med Inbox Classic. Du kan också använda ett applösenord som du har skapat i kontots säkerhetsinställningar.
# review: new
gtk-provider-sign-in-apps = Logga in på { $address } på webbplatsen för { $provider } med en av dina inloggningsappar (Fler inloggningsalternativ). Du kan också använda ett applösenord som du har skapat i kontots säkerhetsinställningar.
# review: new
gtk-accounts-add = Lägg till...
# review: new
gtk-accounts-properties = Egenskaper...
# review: new
gtk-accounts-signature = Signatur...
# review: new
gtk-accounts-sign-in-apps = Inloggningsappar...

## Sign-in apps

# review: new
gtk-app-server = { $kind }-server
# review: new
gtk-app-port = { $kind }-port
# review: new
gtk-app-security = { $kind }-säkerhet
# review: new
gtk-issuer-found =
    Inloggningssida: { $page }
    Token-slutpunkt: { $endpoint }
# review: new
gtk-client-id = Klient-ID
# review: new
gtk-client-secret = Klienthemlighet
# review: new
gtk-scopes = Behörigheter (scopes)
# review: new
gtk-redirect-uri = Omdirigerings-URI
# review: new
gtk-issuer-usable =
    Utfärdaren kan användas.

    { $found }
# review: new
gtk-app-built-in = { $app } är inbyggd. Du kan bara ändra om den erbjuds för nya konton. { $reason }
# review: new
gtk-built-in = { $app } (inbyggd)
# review: new
gtk-offered-for-new = Erbjuds för nya konton
# review: new
gtk-edit-button = Redigera...
# review: new
gtk-remove-app-ask = Vill du ta bort inloggningsappen { $app } och dess sparade klienthemlighet?
# review: new
gtk-sign-in-apps-intro = Med inloggningsappar kan konton logga in via webbläsaren. En app som är avstängd erbjuds inte för nya konton; konton som redan använder den fortsätter att fungera.

## AI agents

# review: new
gtk-agent-it-may = Tillåtna åtgärder
# review: new
gtk-agent-accounts = Tillåtna konton
# review: new
gtk-never-used = Aldrig använd
# review: new
gtk-last-used = Senast använd { $date }
# review: new
gtk-forget-program = Vill du ta bort programmet?
# review: new
gtk-forget-program-detail = Programmets behörigheter och dess agenters aktivitetshistorik raderas. Du tillfrågas om behörighet igen nästa gång det ansluter.
# review: new
gtk-no-agents-yet = Ingen agent har bett om att få använda din e-post ännu.
# review: new
gtk-nothing-yet = Inget ännu.

## Preferences

# review: new
gtk-preferences = Inställningar
# review: changed
gtk-notify-subtitle = Bara medan Inbox Classic är i bakgrunden


## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = E-postklient
# review: new
gtk-desktop-comment = Läs och skriv e-post: ett snabbt och enkelt e-postprogram
# review: new
gtk-desktop-keywords = e-post;epost;mejl;brev;inkorg;
# review: new
gtk-metainfo-summary = Ett snabbt och enkelt e-postprogram
# review: new
gtk-metainfo-description = Inbox Classic läser och skriver e-post med mapparna till vänster, meddelandena överst och meddelandet nedanför, som e-postprogram brukade se ut. Det fungerar med alla IMAP- och SMTP-konton och loggar in på Outlook.com och Microsoft 365 via webbläsaren.
# review: new
gtk-metainfo-feature-sanitized = Varje meddelande visas rensat, utan skript, och bilder från internet bara när du tillåter det
# review: new
gtk-metainfo-feature-search = En sökning som hittar ord i ämnet, personerna, filnamnen och texten, med Gmails operatorer
# review: new
gtk-metainfo-feature-replies = Svar fäller ihop de tidigare meddelanden som de citerar
# review: new
gtk-metainfo-feature-offline = E-posten går att läsa offline; lösenorden förvaras i din nyckelring
