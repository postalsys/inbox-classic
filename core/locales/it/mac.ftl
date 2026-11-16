# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.
# Italian: only the first word capitalized, as Apple's Italian menus write them.

## The app and its menus

# review: new
mac-quit = Esci da Inbox Classic
# review: new
mac-settings = Impostazioni…
# review: new
mac-services = Servizi
# review: new
mac-hide = Nascondi Inbox Classic
# review: new
mac-hide-others = Nascondi altre
# review: new
mac-show-all = Mostra tutte
# review: new
mac-check-updates = Controlla aggiornamenti…
# review: new
mac-close-window = Chiudi finestra
# review: new
mac-redo = Ripeti
# review: new
mac-cut = Taglia
# review: new
mac-paste = Incolla
# review: new
mac-menu-window = Finestra
# review: new
mac-minimize = Contrai
# review: new
mac-zoom = Zoom
# review: new
mac-no-updates = Questa versione di Inbox Classic non supporta gli aggiornamenti automatici. Scarica l’ultima versione da inboxclassic.com.

## Settings

# review: new
mac-settings-title = Impostazioni
# review: new
mac-language-label = Lingua:
# review: new
mac-restart-hint = Riavvia Inbox Classic per cambiare la lingua.
# review: new
mac-notify-new-mail = Avvisami quando arriva nuova posta
# review: new
mac-restart-question = Riavviare ora Inbox Classic per cambiare la lingua?

## Dialogs

# review: new
mac-choose = Scegli

## The main window

# review: new
mac-still-running-detail = Inbox Classic continua a controllare la posta in arrivo in background. Fai clic sulla sua icona nel Dock per aprire l’app.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } messaggio in Posta in uscita
       *[other] { $count } messaggi in Posta in uscita
    }
# review: new
mac-sending = Invio di { $subject }…
# review: new
mac-checking = Controllo dei nuovi messaggi su { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Questa copia di Inbox Classic non è un bundle di app, quindi non può essere l’app di posta predefinita.
# review: new
mac-not-made-default = Inbox Classic non è stata impostata come app di posta predefinita: { $reason }
# review: new
mac-tool-search = Cerca

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Il testo di { $count } messaggio è ancora in fase di indicizzazione, quindi presto potrebbero comparire altri risultati.
       *[other] Il testo di { $count } messaggi è ancora in fase di indicizzazione, quindi presto potrebbero comparire altri risultati.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Nessun risultato per “{ $words }” in tutte le cartelle
        [one] { $count } risultato per “{ $words }” in tutte le cartelle
       *[other] { $count } risultati per “{ $words }” in tutte le cartelle
    }
# review: new
mac-results-in =
    { $count ->
        [0] Nessun risultato per “{ $words }” in { $folder }
        [one] { $count } risultato per “{ $words }” in { $folder }
       *[other] { $count } risultati per “{ $words }” in { $folder }
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] indicizzazione del testo di { $count } messaggio in corso
       *[other] indicizzazione del testo di { $count } messaggi in corso
    }
# review: new
mac-folder-unread = { $folder }, { $count } da leggere
# review: new
mac-import-messages = Importa messaggi
# review: new
mac-save-messages = Salva messaggi
# review: new
mac-save-attachments-menu = Salva allegati…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Non è stato possibile salvare { $failed } dei { $count } file.
    }
# review: new
mac-no-calendar-app = Su questo Mac non c’è un’app di calendario per aprire gli inviti (file .ics).
# review: new
mac-file-not-saved = Non è stato possibile salvare il file.
# review: new
mac-unsubscribing = Annullamento dell’iscrizione da { $target }…

## The compose window

# review: new
mac-bold = Grassetto
# review: new
mac-italic = Corsivo
# review: new
mac-underline = Sottolineato
# review: new
mac-bcc = Ccn
# review: new
mac-command-click-to-open = ⌘-clic per aprire
# review: new
mac-saving-to-drafts = Salvataggio in Bozze…
# review: new
mac-dont-save = Non salvare

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } file
       *[other] { $count } file
    }

## Accounts

# review: new
mac-next = Avanti
# review: new
mac-name-placeholder = Anna Rossi
# review: new
mac-more-sign-in-options = Altre opzioni di accesso…
# review: new
mac-add-sign-in-app = Aggiungi un’app di accesso…
# review: new
mac-looking-up = Ricerca delle impostazioni di { $domain }…
# review: new
mac-add-button = Aggiungi…
# review: new
mac-properties-button = Proprietà…
# review: new
mac-signature-button = Firma…
# review: new
mac-security-button = Sicurezza…
# review: new
mac-sign-in-apps-button = App di accesso…

## AI agents

# review: new
mac-forget-program = Rimuovere questo programma e la cronologia delle attività dei suoi agenti?
# review: new
mac-forget-program-detail = Le autorizzazioni del programma verranno eliminate. Alla prossima connessione ti verrà chiesta di nuovo l’autorizzazione.

## Sign-in apps

# review: new
mac-checking-issuer = Controllo di { $issuer }…
# review: new
mac-edit-button = Modifica…
# review: new
mac-use-for-new-accounts = Usa { $name } per i nuovi account
# review: new
mac-built-in = { $name } (integrata)

## Other windows

# review: new
mac-new-folder-button = Nuova cartella…
# review: new
mac-edit-link = Modifica link…
