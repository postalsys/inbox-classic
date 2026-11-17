# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Inbox Classic continua a controllare la posta in arrivo in background. Fai clic sull’icona per aprirlo. Per uscire, fai clic con il pulsante destro sull’icona e usa il suo menu.
# review: new
win-default-app-not-installed = Questa copia di Inbox Classic non è stata installata, quindi Windows non la elenca tra le app di posta. Installala per poterla scegliere.
# review: new
win-default-app-settings = Windows aprirà le impostazioni App predefinite. Scegli Inbox Classic per aprire i collegamenti MAILTO.
# review: new
win-no-unread = Nessun messaggio da leggere
# review: new
win-unread-messages = { $count ->
    [one] 1 messaggio da leggere
   *[other] { $count } messaggi da leggere
}
# review: new
win-print-failed = Non è stato possibile stampare il messaggio.
# review: new
win-print-title-of = Stampa: { $subject }
# review: new
win-no-bodies = Non è possibile mostrare il testo dei messaggi.
# review: new
win-webview-failed = Non è stato possibile creare WebView2.
# review: new
win-webview-missing = Il runtime WebView2 non è disponibile.
# review: new
win-list-loading = Caricamento...

## Buttons and words used in many windows

# review: new
win-delete-button = &Elimina
# review: new
win-find-label = &Trova:
# review: new
win-save-as-button = Salva &con nome...
# review: new
win-too-many-files = Troppi file in una volta: scegline meno.

## The Outbox


## The compose window

# review: new
win-editor-failed = Non è possibile scrivere messaggi.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+clic per aprire)
# review: new
win-format-bold = Grassetto ({ $ctrl }+B)
# review: new
win-format-italic = Corsivo ({ $ctrl }+I)
# review: new
win-format-underline = Sottolineato ({ $ctrl }+U)
# review: new
win-format-link = Collegamento ipertestuale ({ $ctrl }+K)
# review: new
win-show-cc = &Cc
# review: new
win-show-bcc = &Ccn
# review: new
win-signature-title = Firma: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Nessun risultato per “{ $words }” in tutte le cartelle
    [one] { $count } risultato per “{ $words }” in tutte le cartelle
   *[other] { $count } risultati per “{ $words }” in tutte le cartelle
}
# review: new
win-search-found-in = { $count ->
    [0] Nessun risultato per “{ $words }” in { $folder }
    [one] { $count } risultato per “{ $words }” in { $folder }
   *[other] { $count } risultati per “{ $words }” in { $folder }
}
# review: new
win-search-indexing = { $count ->
    [one] indicizzazione del testo di { $count } messaggio in corso
   *[other] indicizzazione del testo di { $count } messaggi in corso
}
# review: new
win-no-match-indexing = { $count ->
    [one] Il testo di { $count } messaggio è ancora in fase di indicizzazione, quindi presto potrebbero comparire altri risultati.
   *[other] Il testo di { $count } messaggi è ancora in fase di indicizzazione, quindi presto potrebbero comparire altri risultati.
}
# review: new
win-files = { $count ->
    [one] { $count } file
   *[other] { $count } file
}
# review: new
win-click-to-retry = Fai clic qui per riprovare.
# review: new
win-save-attachments = &Salva allegati...
# review: new
win-files-not-saved = Non è stato possibile salvare { $failed } dei { $count } file.
# review: new
win-new-folder-in-highlighted = La nuova cartella verrà creata all’interno della cartella selezionata.
# review: new
win-delete-folder-ask = Eliminare la cartella “{ $folder }” con i suoi messaggi e le cartelle che contiene? Verrà eliminata anche sul server.
# review: new
win-rename = &Rinomina...
# review: new
win-messages-not-saved = Non è stato possibile salvare i messaggi.
# review: new
win-messages-not-forwarded = Non è stato possibile inoltrare i messaggi.

## Accounts

# review: new
win-sign-in-google = Accedi con Google
# review: new
win-sign-in-microsoft = Accedi con Microsoft
# review: new
win-next = &Avanti >
# review: new
win-your-account = il tuo account
# review: new
win-browser-sign-in = (accesso dal browser)
# review: new
win-add = A&ggiungi...
# review: new
win-properties-button = &Proprietà...
# review: new
win-signature-button = &Firma...
# review: new
win-sign-in-apps-button = &App di accesso...

## AI agents

# review: new
win-dont-allow = &Non consentire
# review: new
win-col-address = Indirizzo
# review: new
win-never-written-to = Mai scritto
# review: new
win-book-find-label = Digita un nome o un indirizzo e-mail:
# review: new
win-send = &Invia
# review: new
win-dont-send = &Non inviare
# review: new
win-unsubscribe = &Annulla iscrizione
# review: new
win-dont-unsubscribe = &Non annullare l’iscrizione
# review: new
win-forget-program-ask = Rimuovere questo programma, le sue autorizzazioni e la cronologia delle attività dei suoi agenti? Alla prossima connessione ti verrà chiesta di nuovo l’autorizzazione.
# review: new
win-clear-log-ask = Cancellare la cronologia delle attività degli agenti? Le modifiche fatte dagli agenti non verranno annullate.
# review: new
win-agent-programs = &Programmi i cui agenti hanno chiesto l’accesso alla tua posta:
# review: new
win-change = &Modifica...
# review: new
win-what-agents-did = &Attività degli agenti:
# review: new
win-how-to-connect = Come connettere un agente

## Sign-in apps

# review: new
win-built-in = (integrata)
# review: new
win-edit = &Modifica...

## Options

# review: new
win-folders-hide = Nascondi l’elenco delle cartelle
# review: new
win-folders-pin = Tieni l’elenco delle cartelle accanto ai messaggi
# review: new
win-folders-show = Mostra le cartelle

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Avvia Inbox Classic
# review: new
win-installer-welcome-new =
    Verrà installato Inbox Classic { $version }, un programma di posta elettronica.

    Non servono diritti di amministratore: viene installato solo per il tuo account.
# review: new
win-installer-welcome-same =
    Inbox Classic { $version } è già installato. Verrà installato di nuovo.

    I tuoi account e la tua posta vengono mantenuti.
# review: new
win-installer-welcome-update =
    Inbox Classic { $installed } verrà aggiornato alla versione { $version }.

    Se è in esecuzione, verrà prima chiuso. I tuoi account e la tua posta vengono mantenuti.
# review: new
win-installer-older-ask = È installato Inbox Classic { $installed }, più recente di { $version }. Installare comunque la versione precedente?
# review: new
win-installer-still-running = Inbox Classic è ancora in esecuzione. Chiudilo e riprova.
# review: new
win-installer-remove-mail-ask = Rimuovere anche gli account e la posta che Inbox Classic conserva su questo computer? La posta sui server rimane.
