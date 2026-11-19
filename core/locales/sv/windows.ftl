# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic fortsätter att söka efter ny e-post i bakgrunden. Klicka på ikonen för att öppna programmet. Om du vill avsluta högerklickar du på ikonen och använder dess meny.
win-default-app-not-installed = Den här kopian av Inbox Classic har inte installerats, så Windows visar den inte som ett e-postprogram. Installera den för att kunna välja den.
win-default-app-settings = Windows öppnar inställningarna för standardappar. Välj Inbox Classic för att öppna MAILTO-länkar.
win-no-unread = Inga olästa meddelanden
win-unread-messages = { $count ->
    [one] { $count } oläst meddelande
   *[other] { $count } olästa meddelanden
}
win-print-failed = Det gick inte att skriva ut meddelandet.
win-print-title-of = Skriv ut - { $subject }
win-no-bodies = Meddelandetexter kan inte visas.
win-webview-failed = Det gick inte att starta WebView2.
win-webview-missing = Körmiljön WebView2 Runtime är inte tillgänglig.
win-list-loading = Läser in...

## Buttons and words used in many windows

win-delete-button = &Ta bort
win-find-label = &Sök:
win-save-as-button = Spara so&m...
win-too-many-files = För många filer på en gång: välj färre.

## The Outbox


## The compose window

win-editor-failed = Det går inte att skriva meddelanden.
win-ctrl-click-to-open = ({ $ctrl }+klicka för att öppna)
win-format-bold = Fet ({ $ctrl }+B)
win-format-italic = Kursiv ({ $ctrl }+I)
win-format-underline = Understruken ({ $ctrl }+U)
win-format-link = Hyperlänk ({ $ctrl }+K)
win-show-cc = &Kopia
win-show-bcc = &Hemlig kopia
win-signature-title = Textsignatur: { $account }
## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Inga resultat för ”{ $words }” i alla mappar
    [one] { $count } resultat för ”{ $words }” i alla mappar
   *[other] { $count } resultat för ”{ $words }” i alla mappar
}
win-search-found-in = { $count ->
    [0] Inga resultat för ”{ $words }” i { $folder }
    [one] { $count } resultat för ”{ $words }” i { $folder }
   *[other] { $count } resultat för ”{ $words }” i { $folder }
}
win-search-indexing = { $count ->
    [one] indexerar fortfarande texten i { $count } meddelande
   *[other] indexerar fortfarande texten i { $count } meddelanden
}
win-no-match-indexing = { $count ->
    [one] Texten i { $count } meddelande indexeras fortfarande, så fler träffar kan snart hittas.
   *[other] Texten i { $count } meddelanden indexeras fortfarande, så fler träffar kan snart hittas.
}
win-files = { $count ->
    [one] { $count } fil
   *[other] { $count } filer
}
win-click-to-retry = Klicka här för att försöka igen.
win-save-attachments = &Spara bilagor...
win-files-not-saved = Filer som inte kunde sparas: { $failed } av { $count }.
win-new-folder-in-highlighted = Den nya mappen skapas i den markerade mappen.
win-delete-folder-ask = Vill du ta bort mappen ”{ $folder }” med dess meddelanden och mapparna i den? Den tas även bort på servern.
win-rename = &Byt namn...
win-messages-not-saved = Det gick inte att spara meddelandena.
win-messages-not-forwarded = Det gick inte att vidarebefordra meddelandena.

## Accounts

win-sign-in-google = Logga in med Google
win-sign-in-microsoft = Logga in med Microsoft
win-next = &Nästa >
win-your-account = ditt konto
win-browser-sign-in = (inloggning via webbläsaren)
win-add = &Lägg till...
win-properties-button = &Egenskaper...
win-signature-button = Textsi&gnatur...
win-sign-in-apps-button = Inloggnings&appar...

## AI agents

win-dont-allow = Tillåt &inte
win-col-address = Adress
win-never-written-to = Aldrig skrivit till
win-book-find-label = Skriv ett namn eller en e-postadress:
win-send = &Skicka
win-dont-send = Skicka &inte
win-unsubscribe = &Avsluta prenumeration
win-dont-unsubscribe = Avsluta &inte
win-forget-program-ask = Vill du ta bort programmets åtkomst och agenternas aktivitetshistorik? Programmet avinstalleras inte. Du tillfrågas om behörighet igen nästa gång det ansluter.
win-clear-log-ask = Rensa agenternas aktivitetshistorik? Det ångrar inte ändringar som agenterna har gjort.
win-agent-programs = &Program vars agenter har begärt åtkomst till din e-post:
win-change = &Ändra...
# Tools > AI Agents: takes back everything the selected program did in a span the user picks
win-undo-since = Ångra allt &sedan...
win-take-back = &Ångra
win-what-agents-did = Agent&aktivitet:
win-agent-reads = Vad som lästes från { $from } till { $to }:
win-agent-reads-hint = Markera en rad med läsningar ovan för att se vad som lästes.
win-how-to-connect = Så ansluter du en agent

## Sign-in apps

win-built-in = (inbyggd)
win-edit = &Redigera...

## Options

win-folders-hide = Dölj mapplistan
win-folders-pin = Behåll mapplistan bredvid meddelandena
win-folders-show = Visa mapparna


## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Starta Inbox Classic
win-installer-welcome-new =
    Inbox Classic { $version }, ett e-postprogram, installeras nu.

    Inga administratörsrättigheter behövs, programmet installeras bara för ditt konto.
win-installer-welcome-same =
    Inbox Classic { $version } är redan installerat. Det installeras nu igen.

    Dina konton och din e-post behålls.
win-installer-welcome-update =
    Inbox Classic { $installed } uppdateras nu till { $version }.

    Om programmet körs stängs det först. Dina konton och din e-post behålls.
win-installer-older-ask = Inbox Classic { $installed } är installerat, vilket är nyare än { $version }. Vill du installera den äldre versionen ändå?
win-installer-still-running = Inbox Classic körs fortfarande. Stäng programmet och försök igen.
win-installer-remove-mail-ask = Vill du även ta bort alla lokala data för Inbox Classic, inklusive konton, inställningar, sparad e-post och meddelanden som väntar i Utkorgen? E-post på servrarna och poster i Windows Autentiseringshanterare finns kvar.