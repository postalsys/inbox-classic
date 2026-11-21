# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Inställningar, Avsluta).

## The main window

gtk-search-looks-in = Sökningen i { $place } omfattar ämnen, avsändare, mottagare, namn på bilagor och meddelandetext. Kontrollera stavningen eller försök med färre ord.
gtk-search-still-indexing = { $count ->
    [one] Texten i { $count } meddelande indexeras fortfarande. Fler resultat kan snart visas.
   *[other] Texten i { $count } meddelanden indexeras fortfarande. Fler resultat kan snart visas.
}
gtk-search-results-everywhere = { $count ->
    [0] Inga resultat
    [one] { $count } resultat
   *[other] { $count } resultat
} för ”{ $words }” i alla mappar
gtk-search-results-in = { $count ->
    [0] Inga resultat
    [one] { $count } resultat
   *[other] { $count } resultat
} för ”{ $words }” i { $place }
gtk-search-indexing = { $count ->
    [one] indexerar fortfarande texten i { $count } meddelande
   *[other] indexerar fortfarande texten i { $count } meddelanden
}
gtk-list-loading = Läser in...
gtk-menu-rename = Byt namn...
gtk-import-one-question = Vill du importera meddelandet { $file } till { $folder }?
gtk-files-not-saved = Filer som inte kunde sparas: { $failed } av { $total }.
gtk-unsubscribe-one-click =
    Lämna den här e-postlistan?

    Inbox Classic skickar en begäran om att avsluta prenumerationen till { $target }. Ingen webbsida öppnas och inget e-postmeddelande skickas.
gtk-unsubscribe-mail =
    Lämna den här e-postlistan?

    Skicka ett e-postmeddelande till { $target } för att avsluta prenumerationen. Inbox Classic förbereder det åt dig. Skicka meddelandet för att bekräfta.
gtk-unsubscribe-web =
    Lämna den här e-postlistan?

    E-postlistans sida för att avsluta prenumerationen öppnas i webbläsaren ({ $target }).
gtk-unsubscribe-failed = Det gick inte att avsluta prenumerationen: { $problem }
gtk-toolbar-create-mail-menu = Skriv från ett visst konto
gtk-toolbar-send-recv-menu = Skicka och ta emot e-post för ett visst konto
gtk-main-menu = Huvudmeny
gtk-folder-list = Mapplista
gtk-quit = Avsluta

## The Move and Copy window

gtk-new-folder-at-top-of = Den nya mappen hamnar på översta nivån i { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Inga olästa meddelanden
    [one] { $count } oläst meddelande
   *[other] { $count } olästa meddelanden
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Inga meddelanden väntar på att skickas.
gtk-outbox-row = Till: { $to }  ·  Köat { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic fortsätter att söka efter ny e-post i bakgrunden. Använd ikonen i systempanelen för att öppna eller avsluta programmet.
gtk-sign-in-again-ask =
    Inloggningen till { $account } avvisades eller så har sessionen gått ut.

    Logga in igen i webbläsaren?
gtk-default-app-not-installed = Den här kopian av Inbox Classic har inte installerats, så systemet visar den inte som ett e-postprogram. Installera den för att kunna välja den.
gtk-default-app-now = Inbox Classic är nu ditt standardprogram för e-post: e-postlänkar öppnar ett nytt meddelande här.
gtk-default-app-failed = Inbox Classic kunde inte göras till standardprogram för e-post.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Datum:
gtk-reader-files = Meddelandets bilagor
gtk-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
gtk-download-pictures = Hämta bilder
gtk-save-attachments-menu = Spara bilagor...

## The compose window

gtk-format-bold = Fet (Ctrl+B)
gtk-format-italic = Kursiv (Ctrl+I)
gtk-format-underline = Understruken (Ctrl+U)
gtk-format-hyperlink = Hyperlänk (Ctrl+K)
gtk-font = Typsnitt
gtk-show-cc = _Kopia
gtk-show-bcc = _Hemlig kopia
gtk-save-tip = Spara (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+klicka för att öppna)

## Accounts

gtk-plain-warning = Utan kryptering kan den som avlyssnar din nätverkstrafik läsa ditt lösenord och dina meddelanden. Fortsätt bara om anslutningen skyddas på annat sätt. Ett lokalt nätverk innebär inte i sig att anslutningen är säker.

    Vill du fortsätta?
gtk-account-name-title = Kontonamn
gtk-display-name-title = Visningsnamn
gtk-turned-off-why = Alternativet ”{ $button }” är avstängt på den här datorn. { $reason }
gtk-turned-off-why-long =
    Alternativet ”{ $button }” är avstängt på den här datorn.

    { $reason }
gtk-next = Nästa >
gtk-provider-sign-in = Logga in på { $address } på webbplatsen för { $provider }. Ditt lösenord delas inte med Inbox Classic. Om kontot tillåter applösenord för e-post kan du också använda ett som du har skapat i kontots säkerhetsinställningar. Outlook.com och Microsoft 365 kräver inloggning via webbläsaren.
gtk-provider-sign-in-apps = Logga in på { $address } på webbplatsen för { $provider } med en av dina inloggningsappar (Fler inloggningsalternativ). Om kontot tillåter applösenord för e-post kan du också använda ett som du har skapat i kontots säkerhetsinställningar. Outlook.com och Microsoft 365 kräver inloggning via webbläsaren.
gtk-accounts-add = Lägg till...
gtk-accounts-properties = Egenskaper...
gtk-accounts-signature = Textsignatur...
gtk-accounts-sign-in-apps = Inloggningsappar...

## Sign-in apps

gtk-app-server = Server för { $kind }
gtk-app-port = Port för { $kind }
gtk-app-security = Säkerhet för { $kind }
gtk-issuer-found =
    Inloggningssida: { $page }
    Token-slutpunkt: { $endpoint }
gtk-client-id = Klient-ID
gtk-client-secret = Klienthemlighet
gtk-scopes = Behörigheter (scopes)
gtk-redirect-uri = Omdirigerings-URI
gtk-issuer-usable =
    Utfärdaren kan användas.

    { $found }
gtk-app-built-in = { $app } är inbyggd. Du kan bara ändra om den erbjuds för nya konton. { $reason }
gtk-built-in = { $app } (inbyggd)
gtk-offered-for-new = Erbjuds för nya konton
gtk-edit-button = Redigera...
gtk-remove-app-ask = Vill du ta bort inloggningsappen { $app } och dess sparade klienthemlighet?
gtk-sign-in-apps-intro = Med inloggningsappar kan konton logga in via webbläsaren. En app som är avstängd erbjuds inte för nya konton; konton som redan använder den fortsätter att fungera.

## AI agents

gtk-agent-it-may = Tillåtna åtgärder
gtk-agent-accounts = Tillåtna konton
gtk-never-used = Aldrig använd
gtk-last-used = Senast använd { $date }
gtk-forget-program = Vill du ta bort programmets åtkomst?
gtk-forget-program-detail = Programmets behörigheter och agenternas aktivitetshistorik tas bort. Programmet avinstalleras inte. Du tillfrågas om behörighet igen nästa gång det ansluter.
gtk-no-agents-yet = Ingen agent har bett om att få använda din e-post ännu.
gtk-nothing-yet = Inget ännu.

## Preferences

gtk-preferences = Inställningar
gtk-notify-subtitle = Bara medan Inbox Classic är i bakgrunden


## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = E-postklient
gtk-desktop-comment = Läs och skriv e-post: ett snabbt och enkelt e-postprogram
gtk-desktop-keywords = e-post;epost;mejl;brev;inkorg;
gtk-metainfo-summary = Ett snabbt och enkelt e-postprogram
gtk-metainfo-description = Med Inbox Classic kan du läsa och skriva e-post i ett klassiskt gränssnitt med mappar till vänster, meddelandelistan överst och det valda meddelandet nedanför. Programmet stöder konton med IMAP och SMTP och inloggning via webbläsaren för Outlook.com och Microsoft 365.
gtk-metainfo-feature-sanitized = Meddelanden visas utan skript. Du bestämmer när bilder från internet får hämtas
gtk-metainfo-feature-search = Sök i ämnen, avsändare, mottagare, bilagenamn och meddelandetext med sökvillkor som liknar Gmails
gtk-metainfo-feature-replies = Citerade meddelanden fälls ihop i svar så att din egen text får plats
gtk-metainfo-feature-offline = E-post kan läsas utan internet så länge den lokala kopian finns kvar; inloggningsuppgifter sparas normalt i systemets nyckelring när den är tillgänglig