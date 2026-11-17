# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions in Swedish:
# an ellipsis (…) after a command that asks for more, sentence case as macOS writes Swedish, ” ” and ’.

## The app and its menus

# review: new
mac-quit = Avsluta Inbox Classic
# review: new
mac-settings = Inställningar…
# review: new
mac-services = Tjänster
# review: new
mac-hide = Göm Inbox Classic
# review: new
mac-hide-others = Göm övriga
# review: new
mac-show-all = Visa alla
# review: new
mac-check-updates = Sök efter uppdateringar…
# review: new
mac-close-window = Stäng fönster
# review: new
mac-redo = Gör om
# review: new
mac-cut = Klipp ut
# review: new
mac-paste = Klistra in
# review: new
mac-menu-window = Fönster
# review: new
mac-minimize = Minimera
# review: new
mac-zoom = Zooma
# review: new
mac-no-updates = Den här versionen av Inbox Classic har inte stöd för automatiska uppdateringar. Hämta den senaste versionen från inboxclassic.com.

## Settings

# review: new
mac-settings-title = Inställningar
# review: new
mac-check-updates-automatically = Sök efter uppdateringar automatiskt
# review: new
mac-settings-updates = Uppdateringar

## Dialogs

# review: new
mac-choose = Välj

## The main window

# review: new
mac-still-running-detail = Inbox Classic fortsätter att söka efter ny e-post i bakgrunden. Klicka på symbolen i Dock för att öppna appen.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } meddelande i Utkorgen
       *[other] { $count } meddelanden i Utkorgen
    }
# review: new
mac-sending = Skickar { $subject }…
# review: new
mac-checking = Söker efter nya meddelanden på { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Den här kopian av Inbox Classic är inte ett appaket, så den kan inte vara standardprogram för e-post.
# review: new
mac-not-made-default = Inbox Classic blev inte standardprogram för e-post: { $reason }
# review: new
mac-tool-search = Sök

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Texten i { $count } meddelande indexeras fortfarande, så fler träffar kan snart hittas.
       *[other] Texten i { $count } meddelanden indexeras fortfarande, så fler träffar kan snart hittas.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Inga resultat för ”{ $words }” i alla mappar
        [one] { $count } resultat för ”{ $words }” i alla mappar
       *[other] { $count } resultat för ”{ $words }” i alla mappar
    }
# review: new
mac-results-in =
    { $count ->
        [0] Inga resultat för ”{ $words }” i { $folder }
        [one] { $count } resultat för ”{ $words }” i { $folder }
       *[other] { $count } resultat för ”{ $words }” i { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] indexerar fortfarande texten i { $count } meddelande
       *[other] indexerar fortfarande texten i { $count } meddelanden
    }
# review: new
mac-folder-unread = { $folder }, { $count } olästa
# review: new
mac-import-messages = Importera meddelanden
# review: new
mac-save-messages = Spara meddelanden
# review: new
mac-save-attachments-menu = Spara bilagor…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] { $failed } av de { $count } filerna kunde inte sparas.
    }
# review: new
mac-no-calendar-app = Det finns inget kalenderprogram på den här Mac-datorn som kan öppna inbjudningar (.ics-filer).
# review: new
mac-file-not-saved = Det gick inte att spara filen.
# review: new
mac-unsubscribing = Avslutar prenumerationen hos { $target }…
# review: new
mac-loading-list = Läser in…

## The compose window

# review: new
mac-bold = Fet
# review: new
mac-italic = Kursiv
# review: new
mac-underline = Understruken
# review: new
mac-bcc = Hemlig kopia
# review: new
mac-command-click-to-open = ⌘-klicka för att öppna
# review: new
mac-saving-to-drafts = Sparar i Utkast…
# review: new
mac-dont-save = Spara inte

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } fil
       *[other] { $count } filer
    }

## Accounts

# review: new
mac-next = Nästa
# review: new
mac-name-placeholder = Anna Andersson
# review: new
mac-more-sign-in-options = Fler inloggningsalternativ…
# review: new
mac-add-sign-in-app = Lägg till en inloggningsapp…
# review: new
mac-looking-up = Söker efter inställningarna för { $domain }…
# review: new
mac-add-button = Lägg till…
# review: new
mac-properties-button = Egenskaper…
# review: new
mac-signature-button = Signatur…
# review: new
mac-security-button = Säkerhet…
# review: new
mac-sign-in-apps-button = Inloggningsappar…

## AI agents

# review: new
mac-forget-program = Vill du ta bort programmet och dess agenters aktivitetshistorik?
# review: new
mac-forget-program-detail = Programmets behörigheter raderas. Du tillfrågas om behörighet igen nästa gång det ansluter.

## Sign-in apps

# review: new
mac-checking-issuer = Kontrollerar { $issuer }…
# review: new
mac-edit-button = Redigera…
# review: new
mac-use-for-new-accounts = Använd { $name } för nya konton
# review: new
mac-built-in = { $name } (inbyggd)

## Other windows

# review: new
mac-new-folder-button = Ny mapp…
# review: new
mac-edit-link = Redigera länk…
