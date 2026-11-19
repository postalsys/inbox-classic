# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions in Swedish:
# an ellipsis (…) after a command that asks for more, sentence case as macOS writes Swedish, ” ” and ’.

## The app and its menus

mac-quit = Avsluta Inbox Classic
mac-settings = Inställningar…
mac-services = Tjänster
mac-hide = Göm Inbox Classic
mac-hide-others = Göm övriga
mac-show-all = Visa alla
mac-check-updates = Sök efter uppdateringar…
mac-close-window = Stäng fönster
mac-redo = Gör om
mac-cut = Klipp ut
mac-paste = Klistra in
mac-menu-window = Fönster
mac-minimize = Minimera
mac-zoom = Zooma
mac-no-updates = Den här versionen av Inbox Classic har inte stöd för automatiska uppdateringar. Hämta den senaste versionen från inboxclassic.com.

## Settings

mac-settings-title = Inställningar
mac-check-updates-automatically = Sök efter uppdateringar automatiskt
mac-settings-updates = Uppdateringar

## Dialogs

mac-choose = Välj

## The main window

mac-still-running-detail = Inbox Classic fortsätter att söka efter ny e-post i bakgrunden. Klicka på symbolen i Dock för att öppna appen.
mac-outbox-waiting =
    { $count ->
        [one] { $count } meddelande i Utkorgen
       *[other] { $count } meddelanden i Utkorgen
    }
mac-sending = Skickar { $subject }…
mac-checking = Söker efter nya meddelanden på { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Den här kopian av Inbox Classic är inte paketerad som en Mac-app och kan därför inte anges som standardprogram för e-post.
mac-not-made-default = Inbox Classic blev inte standardprogram för e-post: { $reason }
mac-tool-search = Sök

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Texten i { $count } meddelande indexeras fortfarande, så fler träffar kan snart hittas.
       *[other] Texten i { $count } meddelanden indexeras fortfarande, så fler träffar kan snart hittas.
    }
mac-results-everywhere =
    { $count ->
        [0] Inga resultat för ”{ $words }” i alla mappar
        [one] { $count } resultat för ”{ $words }” i alla mappar
       *[other] { $count } resultat för ”{ $words }” i alla mappar
    }
mac-results-in =
    { $count ->
        [0] Inga resultat för ”{ $words }” i { $folder }
        [one] { $count } resultat för ”{ $words }” i { $folder }
       *[other] { $count } resultat för ”{ $words }” i { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] indexerar fortfarande texten i { $count } meddelande
       *[other] indexerar fortfarande texten i { $count } meddelanden
    }
mac-folder-unread = { $folder }, olästa: { $count }
mac-import-messages = Importera meddelanden
mac-save-messages = Spara meddelanden
mac-save-attachments-menu = Spara bilagor…
mac-files-not-saved = { $count ->
   *[other] Filer som inte kunde sparas: { $failed } av { $count }.
}
mac-no-calendar-app = Det gick inte att öppna inbjudan. Kontrollera att ett kalenderprogram är valt för .ics-filer.
mac-file-not-saved = Det gick inte att spara filen.
mac-unsubscribing = Avslutar prenumerationen hos { $target }…
mac-loading-list = Läser in…

## The compose window

mac-bold = Fet
mac-italic = Kursiv
mac-underline = Understruken
mac-bcc = Hemlig kopia
mac-command-click-to-open = ⌘-klicka för att öppna
mac-saving-to-drafts = Sparar i Utkast…
mac-dont-save = Spara inte

## The reading pane

mac-files =
    { $count ->
        [one] { $count } fil
       *[other] { $count } filer
    }

## Accounts

mac-next = Nästa
mac-name-placeholder = Anna Andersson
mac-more-sign-in-options = Fler inloggningsalternativ…
mac-add-sign-in-app = Lägg till en inloggningsapp…
mac-looking-up = Söker efter inställningarna för { $domain }…
mac-add-button = Lägg till…
mac-properties-button = Egenskaper…
mac-signature-button = Textsignatur…
mac-security-button = Säkerhet…
mac-sign-in-apps-button = Inloggningsappar…

## AI agents

mac-forget-program = Vill du ta bort programmets åtkomst och agenternas aktivitetshistorik?
mac-forget-program-detail = Programmets behörigheter tas bort, men programmet avinstalleras inte. Du tillfrågas om behörighet igen nästa gång det ansluter.
## Sign-in apps

mac-checking-issuer = Kontrollerar { $issuer }…
mac-edit-button = Redigera…
mac-use-for-new-accounts = Använd { $name } för nya konton
mac-built-in = { $name } (inbyggd)

## Other windows

mac-new-folder-button = Ny mapp…
mac-edit-link = Redigera länk…
