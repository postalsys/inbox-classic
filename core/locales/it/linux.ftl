# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = La ricerca in { $place } comprende gli oggetti, i mittenti, i destinatari, i nomi degli allegati e il testo dei messaggi. Controlla l’ortografia o prova con meno parole.
gtk-search-still-indexing = { $count ->
    [one] Il testo di 1 messaggio è ancora in fase di indicizzazione. Presto potrebbero comparire altri risultati.
   *[other] Il testo di { $count } messaggi è ancora in fase di indicizzazione. Presto potrebbero comparire altri risultati.
}
gtk-search-results-everywhere = { $count ->
    [0] Nessun risultato
    [one] 1 risultato
   *[other] { $count } risultati
} per “{ $words }” in tutte le cartelle
gtk-search-results-in = { $count ->
    [0] Nessun risultato
    [one] 1 risultato
   *[other] { $count } risultati
} per “{ $words }” in { $place }
gtk-search-indexing = { $count ->
    [one] indicizzazione del testo di 1 messaggio in corso
   *[other] indicizzazione del testo di { $count } messaggi in corso
}
gtk-list-loading = Caricamento...
gtk-menu-rename = Rinomina...
gtk-import-one-question = Importare il messaggio { $file } in { $folder }?
gtk-files-not-saved = File non salvati: { $failed } su { $total }.
gtk-unsubscribe-one-click =
    Lasciare questa mailing list?

    Inbox Classic invierà una richiesta di annullamento dell’iscrizione a { $target }. Non si aprirà nessuna pagina web e non verrà inviata nessuna e-mail.
gtk-unsubscribe-mail =
    Lasciare questa mailing list?

    Per annullare l’iscrizione, invia un’e-mail a { $target }. Inbox Classic la preparerà per te. Invia il messaggio per confermare.
gtk-unsubscribe-web =
    Lasciare questa mailing list?

    La pagina di annullamento dell’iscrizione della mailing list si aprirà nel browser ({ $target }).
gtk-unsubscribe-failed = Impossibile annullare l’iscrizione: { $problem }
gtk-toolbar-create-mail-menu = Scrivi da un account specifico
gtk-toolbar-send-recv-menu = Invia e ricevi la posta di un account specifico
gtk-main-menu = Menu principale
gtk-folder-list = Elenco cartelle
gtk-quit = Esci

## The Move and Copy window

gtk-new-folder-at-top-of = La nuova cartella verrà creata nel livello principale dell’account { $account }.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Nessun messaggio da leggere
    [one] 1 messaggio da leggere
   *[other] { $count } messaggi da leggere
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Nessun messaggio in attesa di invio.
gtk-outbox-row = A: { $to }  ·  Messo in coda: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic continua a verificare la presenza di nuova posta in background. Usa la sua icona nella barra superiore per aprire l’app o uscire.
gtk-sign-in-again-ask =
    L’accesso a { $account } è stato rifiutato o la sessione è scaduta.

    Accedere di nuovo nel browser?
gtk-default-app-not-installed = Questa copia di Inbox Classic non è stata installata, quindi il sistema non la elenca tra le app di posta. Installala per poterla scegliere.
gtk-default-app-now = Inbox Classic è ora la tua app di posta predefinita: i collegamenti e-mail aprono qui un nuovo messaggio.
gtk-default-app-failed = Non è stato possibile impostare Inbox Classic come app di posta predefinita.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Data:
gtk-reader-files = Allegati del messaggio
gtk-files = { $count ->
    [one] { $count } file
   *[other] { $count } file
}
gtk-pictures-blocked = Alcune immagini sono state bloccate per limitare la possibilità che il mittente identifichi il tuo computer.
gtk-download-pictures = Scarica immagini
gtk-save-attachments-menu = Salva allegati...

## The compose window

gtk-format-bold = Grassetto (Ctrl+B)
gtk-format-italic = Corsivo (Ctrl+I)
gtk-format-underline = Sottolineato (Ctrl+U)
gtk-format-hyperlink = Collegamento ipertestuale (Ctrl+K)
gtk-font = Carattere
gtk-show-cc = _Cc
gtk-show-bcc = Cc_n
gtk-save-tip = Salva (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+clic per aprire)

## Accounts

gtk-plain-warning =
    Senza crittografia, chiunque intercetti il tuo traffico di rete può leggere la tua password e i tuoi messaggi. Usa questa connessione solo con un server sul tuo computer o nella tua rete locale.

    Continuare?
gtk-account-name-title = Nome account
gtk-display-name-title = Nome visualizzato
gtk-turned-off-why = L’opzione “{ $button }” è disattivata su questo computer. { $reason }
gtk-turned-off-why-long =
    L’opzione “{ $button }” è disattivata su questo computer.

    { $reason }
gtk-next = Avanti >
gtk-provider-sign-in = { $provider }: accedi a { $address } sul sito del provider. La tua password non viene condivisa con Inbox Classic. Puoi anche usare una password per le app creata nelle impostazioni di sicurezza del tuo account.
gtk-provider-sign-in-apps = { $provider }: accedi a { $address } sul sito del provider con una delle tue app di accesso (Altre opzioni di accesso). Puoi anche usare una password per le app creata nelle impostazioni di sicurezza del tuo account.
gtk-accounts-add = Aggiungi...
gtk-accounts-properties = Proprietà...
gtk-accounts-signature = Firma...
gtk-accounts-sign-in-apps = App di accesso...

## Sign-in apps

gtk-app-server = Server { $kind }
gtk-app-port = Porta { $kind }
gtk-app-security = Sicurezza { $kind }
gtk-issuer-found =
    Pagina di accesso: { $page }
    Endpoint del token: { $endpoint }
gtk-client-id = ID client
gtk-client-secret = Segreto client
gtk-scopes = Autorizzazioni (scope)
gtk-redirect-uri = URI di reindirizzamento
gtk-issuer-usable =
    L’emittente può essere usato.

    { $found }
gtk-app-built-in = { $app } è integrata. Puoi solo scegliere se proporla per i nuovi account. { $reason }
gtk-built-in = { $app } (integrata)
gtk-offered-for-new = Proposta per i nuovi account
gtk-edit-button = Modifica...
gtk-remove-app-ask = Rimuovere l’app di accesso { $app } e il suo segreto client salvato?
gtk-sign-in-apps-intro = Le app di accesso ti permettono di accedere ai tuoi account tramite il browser. Un’app disattivata non viene proposta per i nuovi account; gli account che la usano già continuano a funzionare.

## AI agents

gtk-agent-it-may = Azioni consentite
gtk-agent-accounts = Account consentiti
gtk-never-used = Mai usato
gtk-last-used = Ultimo utilizzo: { $date }
gtk-forget-program = Rimuovere questo programma?
gtk-forget-program-detail = Le autorizzazioni del programma e la cronologia delle attività dei suoi agenti verranno eliminate. Alla prossima connessione ti verrà chiesta di nuovo l’autorizzazione.
gtk-no-agents-yet = Nessun agente ha ancora chiesto di usare la tua posta.
gtk-nothing-yet = Ancora niente.

## Preferences

gtk-preferences = Preferenze
# review: changed
gtk-notify-subtitle = Solo mentre Inbox Classic è in background

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Client di posta
gtk-desktop-comment = Leggi e scrivi e-mail: un programma di posta veloce e semplice
gtk-desktop-keywords = posta;posta elettronica;e-mail;messaggi;posta in arrivo;
gtk-metainfo-summary = Un programma di posta veloce e semplice
gtk-metainfo-description = Con Inbox Classic leggi e scrivi e-mail in un’interfaccia familiare: cartelle a sinistra, elenco dei messaggi in alto e contenuto del messaggio selezionato sotto. Funziona con qualsiasi account IMAP e SMTP e permette di accedere a Outlook.com e Microsoft 365 tramite il browser.
gtk-metainfo-feature-sanitized = I messaggi vengono visualizzati senza script e altri contenuti potenzialmente pericolosi; le immagini da internet vengono caricate solo con il tuo consenso
gtk-metainfo-feature-search = Ricerca nell’oggetto, nei mittenti, nei destinatari, nei nomi degli allegati e nel testo dei messaggi, con il supporto degli operatori di Gmail
gtk-metainfo-feature-replies = Il testo dei messaggi precedenti citato nelle risposte viene compresso e può essere espanso quando serve
gtk-metainfo-feature-offline = La posta già scaricata si può leggere anche offline; le password vengono conservate nel portachiavi
