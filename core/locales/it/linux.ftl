# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

# review: new
gtk-search-looks-in = La ricerca in { $place } comprende oggetto, mittenti, destinatari, nomi degli allegati e testo dei messaggi. Controlla l’ortografia o prova con meno parole.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Il testo di 1 messaggio è ancora in fase di indicizzazione. Presto potrebbero comparire altri risultati.
   *[other] Il testo di { $count } messaggi è ancora in fase di indicizzazione. Presto potrebbero comparire altri risultati.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Nessun risultato
    [one] 1 risultato
   *[other] { $count } risultati
} per “{ $words }” in tutte le cartelle
# review: new
gtk-search-results-in = { $count ->
    [0] Nessun risultato
    [one] 1 risultato
   *[other] { $count } risultati
} per “{ $words }” in { $place }
# review: new
gtk-search-indexing = { $count ->
    [one] indicizzazione del testo di 1 messaggio in corso
   *[other] indicizzazione del testo di { $count } messaggi in corso
}
# review: new
gtk-list-loading = Caricamento...
# review: new
gtk-menu-rename = Rinomina...
# review: new
gtk-import-one-question = Importare il messaggio { $file } in { $folder }?
# review: new
gtk-files-not-saved = Non è stato possibile salvare { $failed } dei { $total } file.
# review: new
gtk-unsubscribe-one-click =
    Lasciare questa mailing list?

    Inbox Classic invierà una richiesta di annullamento dell’iscrizione a { $target }. Non si aprirà nessuna pagina web e non verrà inviata nessuna e-mail.
# review: new
gtk-unsubscribe-mail =
    Lasciare questa mailing list?

    Per annullare l’iscrizione, invia un’e-mail a { $target }. Inbox Classic la preparerà per te. Invia il messaggio per confermare.
# review: new
gtk-unsubscribe-web =
    Lasciare questa mailing list?

    La pagina di annullamento dell’iscrizione della mailing list si aprirà nel browser ({ $target }).
# review: new
gtk-unsubscribe-failed = Impossibile annullare l’iscrizione: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Scrivi da un account specifico
# review: new
gtk-toolbar-send-recv-menu = Invia e ricevi la posta di un account specifico
# review: new
gtk-main-menu = Menu principale
# review: new
gtk-folder-list = Elenco cartelle
# review: new
gtk-quit = Esci

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = La nuova cartella verrà creata al livello più alto di { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Nessun messaggio da leggere
    [one] 1 messaggio da leggere
   *[other] { $count } messaggi da leggere
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Nessun messaggio in attesa di invio.
# review: new
gtk-outbox-row = A: { $to }  ·  In coda { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Inbox Classic continua a controllare la posta in arrivo in background. Usa la sua icona nella barra superiore per aprire l’app o uscire.
# review: new
gtk-sign-in-again-ask =
    L’accesso a { $account } è stato rifiutato o la sessione è scaduta.

    Accedere di nuovo nel browser?
# review: new
gtk-default-app-not-installed = Questa copia di Inbox Classic non è stata installata, quindi il sistema non la elenca tra le app di posta. Installala per poterla scegliere.
# review: new
gtk-default-app-now = Inbox Classic è ora la tua app di posta predefinita: i collegamenti e-mail aprono qui un nuovo messaggio.
# review: new
gtk-default-app-failed = Non è stato possibile impostare Inbox Classic come app di posta predefinita.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Data:
# review: new
gtk-reader-files = Allegati del messaggio
# review: new
gtk-files = { $count ->
    [one] { $count } file
   *[other] { $count } file
}
# review: new
gtk-pictures-blocked = Alcune immagini sono state bloccate per impedire al mittente di identificare il tuo computer.
# review: new
gtk-download-pictures = Scarica immagini
# review: new
gtk-save-attachments-menu = Salva allegati...

## The compose window

# review: new
gtk-format-bold = Grassetto (Ctrl+B)
# review: new
gtk-format-italic = Corsivo (Ctrl+I)
# review: new
gtk-format-underline = Sottolineato (Ctrl+U)
# review: new
gtk-format-hyperlink = Collegamento ipertestuale (Ctrl+K)
# review: new
gtk-font = Carattere
# review: new
gtk-show-cc = _Cc
# review: new
gtk-show-bcc = C_cn
# review: new
gtk-save-tip = Salva (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+clic per aprire)

## Accounts

# review: new
gtk-plain-warning =
    Senza crittografia, chiunque intercetti il tuo traffico di rete può leggere la tua password e i tuoi messaggi. Usa questa connessione solo con un server sul tuo computer o nella tua rete locale.

    Continuare?
# review: new
gtk-account-name-title = Nome account
# review: new
gtk-display-name-title = Nome visualizzato
# review: new
gtk-turned-off-why = L’opzione “{ $button }” è disattivata su questo computer. { $reason }
# review: new
gtk-turned-off-why-long =
    L’opzione “{ $button }” è disattivata su questo computer.

    { $reason }
# review: new
gtk-next = Avanti >
# review: new
gtk-provider-sign-in = Accedi a { $address } sul sito web del provider ({ $provider }). La tua password non viene condivisa con Inbox Classic. Puoi anche usare una password per le app creata nelle impostazioni di sicurezza del tuo account.
# review: new
gtk-provider-sign-in-apps = Accedi a { $address } sul sito web del provider ({ $provider }) con una delle tue app di accesso (Altre opzioni di accesso). Puoi anche usare una password per le app creata nelle impostazioni di sicurezza del tuo account.
# review: new
gtk-accounts-add = Aggiungi...
# review: new
gtk-accounts-properties = Proprietà...
# review: new
gtk-accounts-signature = Firma...
# review: new
gtk-accounts-sign-in-apps = App di accesso...

## Sign-in apps

# review: new
gtk-app-server = Server { $kind }
# review: new
gtk-app-port = Porta { $kind }
# review: new
gtk-app-security = Sicurezza { $kind }
# review: new
gtk-issuer-found =
    Pagina di accesso: { $page }
    Endpoint del token: { $endpoint }
# review: new
gtk-client-id = ID client
# review: new
gtk-client-secret = Segreto client
# review: new
gtk-scopes = Autorizzazioni (scope)
# review: new
gtk-redirect-uri = URI di reindirizzamento
# review: new
gtk-issuer-usable =
    L’emittente può essere usato.

    { $found }
# review: new
gtk-app-built-in = { $app } è integrata. Puoi solo scegliere se proporla per i nuovi account. { $reason }
# review: new
gtk-built-in = { $app } (integrata)
# review: new
gtk-offered-for-new = Proposta per i nuovi account
# review: new
gtk-edit-button = Modifica...
# review: new
gtk-remove-app-ask = Rimuovere l’app di accesso { $app } e il suo segreto client salvato?
# review: new
gtk-sign-in-apps-intro = Le app di accesso permettono agli account di accedere tramite il browser. Un’app disattivata non viene proposta per i nuovi account; gli account che la usano già continuano a funzionare.

## AI agents

# review: new
gtk-agent-it-may = Azioni consentite
# review: new
gtk-agent-accounts = Account consentiti
# review: new
gtk-never-used = Mai usato
# review: new
gtk-last-used = Ultimo uso: { $date }
# review: new
gtk-forget-program = Rimuovere questo programma?
# review: new
gtk-forget-program-detail = Le autorizzazioni del programma e la cronologia delle attività dei suoi agenti verranno eliminate. Alla prossima connessione ti verrà chiesta di nuovo l’autorizzazione.
# review: new
gtk-no-agents-yet = Nessun agente ha ancora chiesto di usare la tua posta.
# review: new
gtk-nothing-yet = Ancora niente.

## Preferences

# review: new
gtk-preferences = Preferenze
# review: new
gtk-language = Lingua
# review: new
gtk-language-subtitle = Lingua dell’app e della guida
# review: new
gtk-new-mail-group = Nuova posta
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Notifica la nuova posta
# review: new
gtk-notify-subtitle = Una notifica quando arrivano nuovi messaggi mentre la finestra è in background
# review: new
gtk-restart-to-change = Inbox Classic si riavvia per cambiare la lingua.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Client di posta
# review: new
gtk-desktop-comment = Leggi e scrivi e-mail: un programma di posta veloce e semplice
# review: new
gtk-desktop-keywords = posta;posta elettronica;e-mail;messaggi;posta in arrivo;
# review: new
gtk-metainfo-summary = Un programma di posta veloce e semplice
# review: new
gtk-metainfo-description = Inbox Classic legge e scrive e-mail con le cartelle a sinistra, i messaggi in alto e il messaggio sotto, come facevano i programmi di posta di una volta. Funziona con qualsiasi account IMAP e SMTP e accede a Outlook.com e Microsoft 365 tramite il browser.
# review: new
gtk-metainfo-feature-sanitized = Ogni messaggio viene mostrato ripulito, senza script, e le immagini da internet solo quando lo consenti
# review: new
gtk-metainfo-feature-search = Una ricerca che trova le parole nell’oggetto, nei mittenti e destinatari, nei nomi dei file e nel testo, con gli operatori di Gmail
# review: new
gtk-metainfo-feature-replies = Le risposte nascondono i messaggi precedenti che citano
# review: new
gtk-metainfo-feature-offline = La posta resta leggibile offline; le password sono conservate nel tuo portachiavi
