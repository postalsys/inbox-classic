# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Inbox Classic continua a verificare la presenza di nuova posta in background. Fai clic sull’icona per aprirlo. Per uscire, fai clic con il pulsante destro sull’icona e usa il menu.
win-default-app-not-installed = Questa copia di Inbox Classic non è stata installata, quindi Windows non la elenca tra le app di posta. Installala per poterla scegliere.
win-default-app-settings = Windows aprirà le impostazioni App predefinite. Scegli Inbox Classic per aprire i collegamenti MAILTO.
win-no-unread = Nessun messaggio da leggere
win-unread-messages = { $count ->
    [one] 1 messaggio da leggere
   *[other] { $count } messaggi da leggere
}
win-print-failed = Non è stato possibile stampare il messaggio.
win-print-title-of = Stampa: { $subject }
win-no-bodies = Non è possibile mostrare il testo dei messaggi.
win-webview-failed = Non è stato possibile inizializzare WebView2.
win-webview-missing = Il runtime WebView2 non è disponibile.
# review: new
win-list-loading = Caricamento...

## Buttons and words used in many windows

win-delete-button = &Elimina
win-find-label = &Trova:
win-save-as-button = Salva su &file...
win-too-many-files = Troppi file in una volta: scegline meno.

## The Outbox


## The compose window

win-editor-failed = Non è possibile scrivere messaggi.
win-ctrl-click-to-open = ({ $ctrl }+clic per aprire)
win-format-bold = Grassetto ({ $ctrl }+B)
win-format-italic = Corsivo ({ $ctrl }+I)
win-format-underline = Sottolineato ({ $ctrl }+U)
win-format-link = Collegamento ipertestuale ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = Cc&n
win-signature-title = Firma: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Nessun risultato per “{ $words }” in tutte le cartelle
    [one] { $count } risultato per “{ $words }” in tutte le cartelle
   *[other] { $count } risultati per “{ $words }” in tutte le cartelle
}
win-search-found-in = { $count ->
    [0] Nessun risultato per “{ $words }” in { $folder }
    [one] { $count } risultato per “{ $words }” in { $folder }
   *[other] { $count } risultati per “{ $words }” in { $folder }
}
win-search-indexing = { $count ->
    [one] indicizzazione del testo di { $count } messaggio in corso
   *[other] indicizzazione del testo di { $count } messaggi in corso
}
win-no-match-indexing = { $count ->
    [one] Il testo di { $count } messaggio è ancora in fase di indicizzazione, quindi presto potrebbero comparire altri risultati.
   *[other] Il testo di { $count } messaggi è ancora in fase di indicizzazione, quindi presto potrebbero comparire altri risultati.
}
win-files = { $count ->
    [one] { $count } file
   *[other] { $count } file
}
win-click-to-retry = Fai clic qui per riprovare.
win-save-attachments = &Salva allegati...
win-files-not-saved = File non salvati: { $failed } su { $count }.
win-new-folder-in-highlighted = La nuova cartella verrà creata all’interno della cartella selezionata.
win-delete-folder-ask = Eliminare la cartella “{ $folder }” con i suoi messaggi e le cartelle che contiene? Verrà eliminata anche sul server.
win-rename = &Rinomina...
win-messages-not-saved = Non è stato possibile salvare i messaggi.
win-messages-not-forwarded = Non è stato possibile inoltrare i messaggi.

## Accounts

win-sign-in-google = Accedi con Google
win-sign-in-microsoft = Accedi con Microsoft
win-next = &Avanti >
win-your-account = il tuo account
win-browser-sign-in = (accesso dal browser)
win-add = A&ggiungi...
win-properties-button = &Proprietà...
win-signature-button = &Firma...
win-sign-in-apps-button = &App di accesso...

## AI agents

win-dont-allow = &Non consentire
win-col-address = Indirizzo
win-never-written-to = Nessun messaggio inviato
win-book-find-label = Digita un nome o un indirizzo e-mail:
win-send = &Invia
win-dont-send = &Non inviare
win-forget-program-ask = Rimuovere questo programma, le sue autorizzazioni e la cronologia delle attività dei suoi agenti? Alla prossima connessione ti verrà chiesta di nuovo l’autorizzazione.
win-clear-log-ask = Cancellare la cronologia delle attività degli agenti? Le modifiche fatte dagli agenti non verranno annullate.
win-agent-programs = &Programmi i cui agenti hanno chiesto l’accesso alla tua posta:
win-change = &Modifica...
win-what-agents-did = At&tività degli agenti:
win-how-to-connect = Come connettere un agente

## Sign-in apps

win-built-in = (integrata)
win-edit = &Modifica...

## Options

win-options-language-label = &Mostra Inbox Classic in:
win-options-restart-note = Riavvia Inbox Classic per cambiare la lingua.
win-options-notify = &Avvisami quando arriva nuova posta
win-restart-ask = Al riavvio, la lingua di Inbox Classic sarà { $language }. Riavviare ora?
win-folders-hide = Nascondi l’elenco delle cartelle
win-folders-pin = Tieni l’elenco delle cartelle accanto ai messaggi
win-folders-show = Mostra le cartelle

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Avvia Inbox Classic
win-installer-welcome-new =
    Verrà installato Inbox Classic { $version }, un programma di posta elettronica.

    Non servono privilegi di amministratore: il programma verrà installato solo per il tuo account utente di Windows.
win-installer-welcome-same =
    Inbox Classic { $version } è già installato. Verrà installato di nuovo.

    I tuoi account e la tua posta verranno conservati.
win-installer-welcome-update =
    Inbox Classic { $installed } verrà aggiornato alla versione { $version }.

    Se è in esecuzione, verrà prima chiuso. I tuoi account e la tua posta verranno conservati.
win-installer-older-ask = È installato Inbox Classic { $installed }, più recente di { $version }. Installare comunque la versione precedente?
win-installer-still-running = Inbox Classic è ancora in esecuzione. Chiudilo e riprova.
win-installer-remove-mail-ask = Rimuovere anche gli account e la posta che Inbox Classic conserva su questo computer? La posta sui server verrà conservata.
