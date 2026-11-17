# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic fortsätter att söka efter ny e-post i bakgrunden. Klicka på ikonen för att öppna programmet. Om du vill avsluta högerklickar du på ikonen och använder dess meny.
# review: new
win-default-app-not-installed = Den här kopian av Inbox Classic har inte installerats, så Windows visar den inte som ett e-postprogram. Installera den för att kunna välja den.
# review: new
win-default-app-settings = Windows öppnar inställningarna för standardappar. Välj Inbox Classic för att öppna MAILTO-länkar.
# review: new
win-no-unread = Inga olästa meddelanden
# review: new
win-unread-messages = { $count ->
    [one] { $count } oläst meddelande
   *[other] { $count } olästa meddelanden
}
# review: new
win-print-failed = Det gick inte att skriva ut meddelandet.
# review: new
win-print-title-of = Skriv ut - { $subject }
# review: new
win-no-bodies = Meddelandetexter kan inte visas.
# review: new
win-webview-failed = Det gick inte att skapa WebView2.
# review: new
win-webview-missing = WebView2-körningen är inte tillgänglig.
# review: new
win-list-loading = Läser in...

## Buttons and words used in many windows

# review: new
win-delete-button = &Ta bort
# review: new
win-find-label = &Sök:
# review: new
win-save-as-button = Spara &som...
# review: new
win-too-many-files = För många filer på en gång: välj färre.

## The Outbox


## The compose window

# review: new
win-editor-failed = Det går inte att skriva meddelanden.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+klicka för att öppna)
# review: new
win-format-bold = Fet ({ $ctrl }+B)
# review: new
win-format-italic = Kursiv ({ $ctrl }+I)
# review: new
win-format-underline = Understruken ({ $ctrl }+U)
# review: new
win-format-link = Hyperlänk ({ $ctrl }+K)
# review: new
win-show-cc = &Kopia
# review: new
win-show-bcc = &Hemlig kopia
# review: new
win-signature-title = Signatur: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Inga resultat för ”{ $words }” i alla mappar
    [one] { $count } resultat för ”{ $words }” i alla mappar
   *[other] { $count } resultat för ”{ $words }” i alla mappar
}
# review: new
win-search-found-in = { $count ->
    [0] Inga resultat för ”{ $words }” i { $folder }
    [one] { $count } resultat för ”{ $words }” i { $folder }
   *[other] { $count } resultat för ”{ $words }” i { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] indexerar fortfarande texten i { $count } meddelande
   *[other] indexerar fortfarande texten i { $count } meddelanden
}
# review: new
win-no-match-indexing = { $count ->
    [one] Texten i { $count } meddelande indexeras fortfarande, så fler träffar kan snart hittas.
   *[other] Texten i { $count } meddelanden indexeras fortfarande, så fler träffar kan snart hittas.
}
# review: new
win-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
# review: new
win-click-to-retry = Klicka här för att försöka igen.
# review: new
win-save-attachments = &Spara bilagor...
# review: new
win-files-not-saved = { $failed } av de { $count } filerna kunde inte sparas.
# review: new
win-new-folder-in-highlighted = Den nya mappen skapas i den markerade mappen.
# review: new
win-delete-folder-ask = Vill du ta bort mappen ”{ $folder }” med dess meddelanden och mapparna i den? Den tas även bort på servern.
# review: new
win-rename = &Byt namn...
# review: new
win-messages-not-saved = Det gick inte att spara meddelandena.
# review: new
win-messages-not-forwarded = Det gick inte att vidarebefordra meddelandena.

## Accounts

# review: new
win-sign-in-google = Logga in med Google
# review: new
win-sign-in-microsoft = Logga in med Microsoft
# review: new
win-next = &Nästa >
# review: new
win-your-account = ditt konto
# review: new
win-browser-sign-in = (inloggning via webbläsaren)
# review: new
win-add = &Lägg till...
# review: new
win-properties-button = &Egenskaper...
# review: new
win-signature-button = Si&gnatur...
# review: new
win-sign-in-apps-button = Inloggnings&appar...

## AI agents

# review: new
win-dont-allow = Tillåt &inte
# review: new
win-col-address = Adress
# review: new
win-never-written-to = Aldrig skrivit till
# review: new
win-book-find-label = Skriv ett namn eller en e-postadress:
# review: new
win-send = &Skicka
# review: new
win-dont-send = Skicka &inte
# review: new
win-unsubscribe = &Avsluta prenumeration
# review: new
win-dont-unsubscribe = Avsluta &inte
# review: new
win-forget-program-ask = Vill du ta bort programmet, dess behörigheter och dess agenters aktivitetshistorik? Du tillfrågas om behörighet igen nästa gång det ansluter.
# review: new
win-clear-log-ask = Rensa agenternas aktivitetshistorik? Det ångrar inte ändringar som agenterna har gjort.
# review: new
win-agent-programs = &Program vars agenter har begärt åtkomst till din e-post:
# review: new
win-change = &Ändra...
# review: new
win-what-agents-did = Agent&aktivitet:
# review: new
win-how-to-connect = Så ansluter du en agent

## Sign-in apps

# review: new
win-built-in = (inbyggd)
# review: new
win-edit = &Redigera...

## Options

# review: new
win-folders-hide = Dölj mapplistan
# review: new
win-folders-pin = Behåll mapplistan bredvid meddelandena
# review: new
win-folders-show = Visa mapparna


## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Starta Inbox Classic
# review: new
win-installer-welcome-new =
    Inbox Classic { $version }, ett e-postprogram, installeras nu.

    Inga administratörsrättigheter behövs, programmet installeras bara för ditt konto.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } är redan installerat. Det installeras nu igen.

    Dina konton och din e-post behålls.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } uppdateras nu till { $version }.

    Om programmet körs stängs det först. Dina konton och din e-post behålls.
# review: new
win-installer-older-ask = Inbox Classic { $installed } är installerat, vilket är nyare än { $version }. Vill du installera den äldre versionen ändå?
# review: new
win-installer-still-running = Inbox Classic körs fortfarande. Stäng programmet och försök igen.
# review: new
win-installer-remove-mail-ask = Vill du även ta bort kontona och e-posten som Inbox Classic sparar på den här datorn? E-posten på servrarna finns kvar.
