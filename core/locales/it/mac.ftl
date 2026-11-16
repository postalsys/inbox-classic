# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, Title Case in menus and on buttons, curly quotes and apostrophes.
# Italian: only the first word capitalized, as Apple's Italian menus write them.

## The app and its menus

mac-quit = Esci da Inbox Classic
mac-settings = Impostazioni…
mac-services = Servizi
mac-hide = Nascondi Inbox Classic
mac-hide-others = Nascondi altre
mac-show-all = Mostra tutte
mac-check-updates = Controlla aggiornamenti…
mac-close-window = Chiudi finestra
mac-redo = Ripeti
mac-cut = Taglia
mac-paste = Incolla
mac-menu-window = Finestra
mac-minimize = Contrai
mac-zoom = Zoom
mac-no-updates = Questa versione di Inbox Classic non supporta gli aggiornamenti automatici. Scarica l’ultima versione da inboxclassic.com.

## Settings

mac-settings-title = Impostazioni
mac-language-label = Lingua:
mac-restart-hint = Riavvia Inbox Classic per cambiare la lingua.
mac-notify-new-mail = Avvisami quando arriva nuova posta
mac-restart-question = Riavviare ora Inbox Classic per cambiare la lingua?

## Dialogs

mac-choose = Scegli

## The main window

mac-still-running-detail = Inbox Classic continua a verificare la presenza di nuova posta in background. Fai clic sulla sua icona nel Dock per aprire l’app.
mac-outbox-waiting =
    { $count ->
        [one] { $count } messaggio in Posta in uscita
       *[other] { $count } messaggi in Posta in uscita
    }
mac-sending = Invio di { $subject }…
mac-checking = Ricerca di nuovi messaggi: { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Questa copia di Inbox Classic non è contenuta in un pacchetto applicazione (.app), quindi non può essere impostata come app di posta predefinita.
mac-not-made-default = Non è stato possibile impostare Inbox Classic come app di posta predefinita: { $reason }
mac-tool-search = Cerca

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Il testo di { $count } messaggio è ancora in fase di indicizzazione, quindi presto potrebbero comparire altri risultati.
       *[other] Il testo di { $count } messaggi è ancora in fase di indicizzazione, quindi presto potrebbero comparire altri risultati.
    }
mac-results-everywhere =
    { $count ->
        [0] Nessun risultato per “{ $words }” in tutte le cartelle
        [one] { $count } risultato per “{ $words }” in tutte le cartelle
       *[other] { $count } risultati per “{ $words }” in tutte le cartelle
    }
mac-results-in =
    { $count ->
        [0] Nessun risultato per “{ $words }” in { $folder }
        [one] { $count } risultato per “{ $words }” in { $folder }
       *[other] { $count } risultati per “{ $words }” in { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] indicizzazione del testo di { $count } messaggio in corso
       *[other] indicizzazione del testo di { $count } messaggi in corso
    }
mac-folder-unread = { $folder }, { $count } da leggere
mac-import-messages = Importa messaggi
mac-save-messages = Salva messaggi
mac-save-attachments-menu = Salva allegati…
mac-files-not-saved =
    { $count ->
       *[other] File non salvati: { $failed } su { $count }.
    }
mac-no-calendar-app = Su questo Mac non c’è un’app di calendario per aprire gli inviti (file .ics).
mac-file-not-saved = Non è stato possibile salvare il file.
mac-unsubscribing = Annullamento dell’iscrizione: { $target }…

## The compose window

mac-bold = Grassetto
mac-italic = Corsivo
mac-underline = Sottolineato
mac-bcc = Ccn
mac-command-click-to-open = ⌘-clic per aprire
mac-saving-to-drafts = Salvataggio in Bozze…
mac-dont-save = Non salvare

## The reading pane

mac-files =
    { $count ->
        [one] { $count } file
       *[other] { $count } file
    }

## Accounts

mac-next = Avanti
mac-name-placeholder = Anna Rossi
mac-more-sign-in-options = Altre opzioni di accesso…
mac-add-sign-in-app = Aggiungi un’app di accesso…
mac-looking-up = Ricerca delle impostazioni di { $domain }…
mac-add-button = Aggiungi…
mac-properties-button = Proprietà…
mac-signature-button = Firma…
mac-security-button = Sicurezza…
mac-sign-in-apps-button = App di accesso…

## AI agents

mac-forget-program = Rimuovere questo programma e la cronologia delle attività dei suoi agenti?
mac-forget-program-detail = Le autorizzazioni del programma verranno eliminate. Alla prossima connessione ti verrà chiesta di nuovo l’autorizzazione.

## Sign-in apps

mac-checking-issuer = Controllo di { $issuer }…
mac-edit-button = Modifica…
mac-use-for-new-accounts = Usa { $name } per i nuovi account
mac-built-in = { $name } (integrata)

## Other windows

mac-new-folder-button = Nuova cartella…
mac-edit-link = Modifica collegamento…
