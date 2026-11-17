# Ciò che dice il core, uguale su ogni piattaforma. I segnaposto tra { $graffe } sono compilati dal codice; vanno
# mantenuti, nel punto in cui la lingua li richiede. I plurali scelgono in base al numero: [one] e *[other] in
# italiano.

## Counts and sizes

# review: new
messages = { $count ->
    [one] 1 messaggio
   *[other] { $count } messaggi
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] 1 byte
   *[other] { $count } byte
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Disattivato
# review: new
send-delay-seconds = { $count ->
    [one] 1 secondo
   *[other] { $count } secondi
}
# the status bar: "12 messaggi, 3 da leggere"
# review: new
list-counts = { $messages }, { $unread } da leggere
# review: new
list-counts-selected = { $messages }, { $unread } da leggere, { $selected } selezionati
# the status bar while searching: "12 trovati, 3 da leggere"
# review: new
list-counts-found = { $found } trovati, { $unread } da leggere
# review: new
list-counts-found-selected = { $found } trovati, { $unread } da leggere, { $selected } selezionati
# review: new
list-counts-none = Nessun messaggio trovato

## Special folders, as Outlook Express names them

# review: new
folder-inbox = Posta in arrivo
# review: new
folder-sent = Posta inviata
# review: new
folder-deleted = Posta eliminata
# review: new
folder-drafts = Bozze
# review: new
folder-junk = Posta indesiderata
# review: new
folder-archive = Archivio

## The reading pane

# review: new
reader-no-message = Nessun messaggio selezionato.
# review: new
reader-downloading = Download del messaggio in corso…
# review: new
reader-downloading-detail = Il messaggio apparirà qui al termine del download.
# review: new
reader-downloading-size = Il messaggio è di { $size }. Apparirà qui quando sarà scaricato.
# review: new
reader-failed = Impossibile scaricare il messaggio
# review: new
reader-failed-network = Impossibile raggiungere il server di posta ({ $reason }).
# review: new
reader-failed-sign-in = Il server di posta non ha accettato l’accesso ({ $reason }). Controlla la password o accedi di nuovo in File > Account.
# review: new
reader-failed-security = Impossibile rendere sicura la connessione al server di posta ({ $reason }).
# review: new
reader-failed-other = Risposta del server di posta: { $reason }.
# review: new
reader-retry-note = Verrà ritentato quando l’account si riconnette.
# review: new
reader-unreadable = Impossibile mostrare questo messaggio: { $error }
# review: new
message-source-title = Origine messaggio: { $subject }
# review: new
message-source-untitled = Origine messaggio

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Da
# review: new
header-date = Data
# review: new
header-to = A
# review: new
header-cc = Cc
# review: new
header-sent = Inviato
# review: new
header-subject = Oggetto
# review: new
header-security = Sicurezza
# review: new
header-part = Parte { $number }
# review: new
quote-original = ----- Messaggio originale -----
# review: new
fold-show-earlier = Mostra i messaggi precedenti

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Il tuo messaggio non è stato recapitato
# review: new
bounce-delayed = Il tuo messaggio non è ancora stato recapitato
# review: new
bounce-delayed-note = Il tuo server di posta sta ancora cercando di recapitarlo. Non è necessario inviarlo di nuovo.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Mostra il messaggio non recapitato
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Mostra il messaggio in ritardo
# review: new
bounce-what-to-do = Cosa puoi fare:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Per ora niente. Se non sarà possibile recapitarlo, riceverai un altro avviso.
# review: new
bounce-delayed-row-do = Per ora niente. Il tuo server di posta sta ancora cercando di recapitarlo e, se non ci riuscirà, riceverai un altro avviso.
# folds the receiving server's own words
# review: new
bounce-details = Dettagli
# a recipient the notice does not name
# review: new
bounce-someone = Un destinatario
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Server: { $server }
# review: new
bounce-status = Stato: { $status }
# review: new
bounce-reported-by = Segnalato da: { $server }
# review: new
bounce-retry-minutes = Il server di destinazione ha chiesto di attendere { $count ->
    [one] un minuto
   *[other] { $count } minuti
} prima del prossimo tentativo.
# review: new
bounce-retry-hours = Il server di destinazione ha chiesto di attendere { $count ->
    [one] un’ora
   *[other] { $count } ore
} prima del prossimo tentativo.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Blocklist: { $lists }
# review: new
bounce-user-unknown = L’indirizzo non esiste
# review: new
bounce-user-unknown-why = Il server di destinazione non ha una casella con questo indirizzo. Potrebbe contenere un errore di battitura, o la persona potrebbe non usarlo più.
# review: new
bounce-user-unknown-do = Controlla come è scritto l’indirizzo, o chiedi alla persona l’indirizzo che usa ora.
# review: new
bounce-invalid-address = L’indirizzo non è valido
# review: new
bounce-invalid-address-why = L’indirizzo non è scritto in una forma a cui si possa inviare posta.
# review: new
bounce-invalid-address-do = Cerca errori di battitura, come uno spazio, una lettera mancante o niente dopo la @.
# review: new
bounce-mailbox-disabled = La casella è chiusa
# review: new
bounce-mailbox-disabled-why = L’indirizzo esiste, ma la sua casella è stata disattivata o non è più in uso.
# review: new
bounce-mailbox-disabled-do = Contatta la persona in un altro modo e chiedile un indirizzo che usa ora.
# review: new
bounce-mailbox-full = La casella è piena
# review: new
bounce-mailbox-full-why = La casella del destinatario non ha spazio per nuova posta.
# review: new
bounce-mailbox-full-do = Invialo di nuovo tra qualche giorno, o avvisa la persona in un altro modo. Gli allegati grandi sono i primi a essere rifiutati.
# review: new
bounce-spam-blocked = Rifiutato come spam
# review: new
bounce-spam-blocked-why = Il server di destinazione ha scambiato il messaggio per spam.
# review: new
bounce-spam-blocked-do = Invialo di nuovo senza ciò che sembra spam, come molti link, link abbreviati o un allegato grande. Se succede ancora, rivolgiti al tuo provider di posta.
# review: new
bounce-virus-detected = Rifiutato per un virus
# review: new
bounce-virus-detected-why = Il server di destinazione ha trovato un virus o altro contenuto dannoso nel messaggio o nei suoi allegati.
# review: new
bounce-virus-detected-do = Controlla gli allegati con un antivirus. Alcuni server rifiutano ogni programma o archivio, quindi condividi questi file tramite un link.
# review: new
bounce-ip-blocklisted = Il tuo server di posta è in una blocklist
# review: new
bounce-ip-blocklisted-why = Il server di destinazione rifiuta la posta del server che ha inviato la tua, perché l’indirizzo di quel server è in una blocklist.
# review: new
bounce-ip-blocklisted-do = Il problema non è il messaggio. Inoltra questo avviso al tuo provider di posta e chiedigli di far togliere il server dalla lista.
# review: new
bounce-domain-blocklisted = Un dominio è in una blocklist
# review: new
bounce-domain-blocklisted-why = Il server di destinazione rifiuta il messaggio perché il dominio del tuo indirizzo, o un dominio dei link del messaggio, è in una blocklist.
# review: new
bounce-domain-blocklisted-do = Se il messaggio contiene link, prova senza. Altrimenti inoltra questo avviso a chi gestisce la posta del tuo dominio.
# review: new
bounce-policy-blocked = Rifiutato dalle regole del server di destinazione
# review: new
bounce-policy-blocked-why = Le regole del server di destinazione non lasciano passare questo messaggio, per esempio per le sue dimensioni, i suoi allegati o il mittente.
# review: new
bounce-policy-blocked-do = Le parole del server in Dettagli spesso indicano il motivo. Chiedi al destinatario se può accettare posta di questo tipo.
# review: new
bounce-geo-blocked = Rifiutato per la sua provenienza
# review: new
bounce-geo-blocked-why = Il server di destinazione non accetta posta dal paese o dalla rete in cui si trova il tuo server di posta.
# review: new
bounce-geo-blocked-do = Contatta la persona in un altro modo, o chiedi informazioni al tuo provider di posta.
# review: new
bounce-relay-denied = Il server non l’ha inoltrato
# review: new
bounce-relay-denied-why = Un server ha rifiutato di inoltrare il messaggio, spesso perché è stato inviato senza accesso o tramite un server che non gestisce questo destinatario.
# review: new
bounce-relay-denied-do = Controlla il server della posta in uscita dell’account in File > Account, e che esegua l’accesso.
# review: new
bounce-auth-failure = Impossibile verificare il tuo indirizzo di mittente
# review: new
bounce-auth-failure-why = Il server di destinazione non ha potuto confermare che il messaggio provenga davvero dal tuo dominio (SPF, DKIM o DMARC).
# review: new
bounce-auth-failure-do = Inoltra questo avviso a chi gestisce la posta del tuo dominio: le sue impostazioni vanno corrette. Nel frattempo può aiutare inviare tramite il server del tuo provider.
# review: new
bounce-rate-limited = Troppa posta in una volta
# review: new
bounce-rate-limited-why = Per ora il server di destinazione accetta meno messaggi dal tuo server di posta.
# review: new
bounce-rate-limited-do = Attendi un po’ e invialo di nuovo. Quando scrivi a molte persone, invia a meno destinatari alla volta.
# review: new
bounce-greylisting = Trattenuto per un momento
# review: new
bounce-greylisting-why = Il server di destinazione chiede ai mittenti sconosciuti di riprovare poco dopo, un controllo comune contro lo spam.
# review: new
bounce-greylisting-do = Niente. I server di posta riprovano da soli e di solito il messaggio viene recapitato entro un’ora.
# review: new
bounce-server-error = Il server di destinazione ha avuto un problema
# review: new
bounce-server-error-why = Il server di destinazione non era raggiungibile, o non ha potuto accettare il messaggio per un suo problema.
# review: new
bounce-server-error-do = Invialo di nuovo più tardi. Se continua a non riuscire, controlla che non ci siano errori di battitura nella parte dell’indirizzo dopo la @.
# review: new
bounce-unknown = Non recapitato
# review: new
bounce-unknown-why = L’avviso non spiega chiaramente il motivo.
# review: new
bounce-unknown-do = Le parole del server in Dettagli potrebbero dire di più. Se non aiutano, inoltra questo avviso al tuo provider di posta.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] 1 messaggio selezionato
   *[other] { $count } messaggi selezionati
}
# review: new
selection-unread = { $count } da leggere
# review: new
selection-flagged = { $count } contrassegnati
# review: new
delete-for-good-one = Questo messaggio verrà eliminato definitivamente. Eliminarlo?
# review: new
delete-for-good-all = Questi { $count } messaggi verranno eliminati definitivamente. Eliminarli?
# review: new
delete-for-good-some = { $count } dei { $total } messaggi verranno eliminati definitivamente. Eliminare i messaggi?
# review: new
done-read = { $count ->
    [one] { $messages } segnato come letto
   *[other] { $messages } segnati come letti
}
# review: new
done-unread = { $count ->
    [one] { $messages } segnato come da leggere
   *[other] { $messages } segnati come da leggere
}
# review: new
done-flagged = { $count ->
    [one] { $messages } contrassegnato
   *[other] { $messages } contrassegnati
}
# review: new
done-unflagged = Contrassegno rimosso da { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] { $messages } eliminato definitivamente
   *[other] { $messages } eliminati definitivamente
}
# review: new
done-archived = { $count ->
    [one] { $messages } archiviato
   *[other] { $messages } archiviati
}
# review: new
done-moved = { $count ->
    [one] { $messages } spostato in { $folder }
   *[other] { $messages } spostati in { $folder }
}
# review: new
done-copied = { $count ->
    [one] { $messages } copiato in { $folder }
   *[other] { $messages } copiati in { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Spostamento di { $messages } in { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Copia di { $messages } in { $folder }...
}
# review: new
done-moved-back = { $count ->
    [one] { $messages } riportato in { $folder }
   *[other] { $messages } riportati in { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Conversazione seguita
   *[other] { $count } conversazioni seguite
}
# review: new
done-unwatched = { $count ->
    [one] Non segui più la conversazione
   *[other] Non segui più { $count } conversazioni
}
# review: new
done-ignored = { $count ->
    [one] Conversazione ignorata
   *[other] { $count } conversazioni ignorate
}
# review: new
done-unignored = { $count ->
    [one] Non ignori più la conversazione
   *[other] Non ignori più { $count } conversazioni
}
# review: new
their-folders = cartelle diverse
# review: new
undo-move = Annulla spostamento
# review: new
undo-delete = Annulla eliminazione
# review: new
undo-archive = Annulla archiviazione
# review: new
undo-junk = Annulla Segna come indesiderata
# review: new
undo-not-junk = Annulla Segna come posta desiderata
# review: new
undo-send = Annulla invio
# review: new
nothing-to-undo = Non c’è niente da annullare.
# review: new
messages-gone = I messaggi non ci sono più.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Questa cartella non può contenere messaggi.
# review: new
not-archived-here = I messaggi di questa cartella non possono essere archiviati.
# review: new
not-emptied-here = Si possono svuotare solo Posta eliminata e Posta indesiderata.
# review: new
next-unread-question = Non ci sono altri messaggi da leggere in { $folder }.

    Passare a { $next }, la prossima cartella con messaggi da leggere?
# review: new
no-unread-left = Non ci sono più messaggi da leggere.
# review: new
empty-question = { $count ->
    [one] Svuotare { $folder }?

        Il messaggio che contiene viene eliminato definitivamente. Non potrà essere recuperato.
   *[other] Svuotare { $folder }?

        I { $messages } che contiene vengono eliminati definitivamente. Non potranno essere recuperati.
}
# review: new
no-junk-folder = Questo account non ha una cartella Posta indesiderata in cui spostare i messaggi.
# review: new
no-inbox-folder = Questo account non ha una cartella Posta in arrivo in cui spostare i messaggi.
# the status bar after a flag in a colour: "Contrassegno aggiunto a 2 messaggi: blu"
# review: new
done-flagged-color = Contrassegno aggiunto a { $messages }: { $color ->
    [red] rosso
    [orange] arancione
    [yellow] giallo
    [green] verde
    [blue] blu
    [purple] viola
   *[gray] grigio
}
# the Flag menu: the colours of Apple Mail's flags
# review: new
flag-color = { $color ->
    [red] Rosso
    [orange] Arancione
    [yellow] Giallo
    [green] Verde
    [blue] Blu
    [purple] Viola
   *[gray] Grigio
}

## The Move and Copy window

# review: new
move-window-title-move = { $count ->
    [one] Sposta messaggio
   *[other] Sposta { $count } messaggi
}
# review: new
move-window-title-copy = { $count ->
    [one] Copia messaggio
   *[other] Copia { $count } messaggi
}
# review: new
move-window-prompt-move = { $count ->
    [one] Sposta il messaggio selezionato in:
   *[other] Sposta i { $count } messaggi selezionati in:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Copia il messaggio selezionato in:
   *[other] Copia i { $count } messaggi selezionati in:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Recenti
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (attuale)
# a folder used last, with its account when there are several: "Archivio (Lavoro)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Spostamento di { $done } di { $messages } in { $folder }...
# review: new
transfer-copying = Copia di { $done } di { $messages } in { $folder }...
# review: new
transfer-another-account = un altro account
# review: new
transfer-folder-gone = la cartella di destinazione non esiste più
# review: new
transfer-not-on-server = il messaggio non è più sul server
# review: new
transfer-not-moved = { $count ->
    [one] Impossibile spostare { $messages } in un altro account: { $reason }
   *[other] Impossibile spostare { $messages } in un altro account: { $reason }
}
# review: new
transfer-not-copied = { $count ->
    [one] Impossibile copiare { $messages } in un altro account: { $reason }
   *[other] Impossibile copiare { $messages } in un altro account: { $reason }
}
# review: new
transfer-none-moved = Non è stato possibile spostare nessun messaggio
# review: new
transfer-none-copied = Non è stato possibile copiare nessun messaggio

## Messages as files

# review: new
export-not-in-time = non è stato possibile scaricare il messaggio in tempo
# review: new
export-not-saved = Impossibile salvare { $failed } di { $messages } ({ $problems })
# review: new
export-not-attached = impossibile allegare i messaggi: { $error }
# the status bar after Save As with several: "3 messaggi salvati in Scrivania"
# review: new
saved-to = { $count ->
    [one] { $messages } salvato in { $folder }
   *[other] { $messages } salvati in { $folder }
}
# review: new
download-progress = Download di { $done } di { $total }
# review: new
download-done = Scaricati { $size }
# review: new
downloading-messages = { $count ->
   *[other] Download di { $messages }...
}
# the status bar after files are dropped on a folder: "3 messaggi messi in Archivio"
# review: new
import-put = { $count ->
    [one] { $messages } messo in { $folder }
   *[other] { $messages } messi in { $folder }
}
# review: new
import-not-put = Questi non sono stati messi nella cartella:

    { $problems }

## Problems the windows show

# review: new
error-store = archivio locale: { $error }
# review: new
error-not-found = non trovato
# review: new
error-closed = chiusura in corso
# review: new
error-other-account = il browser ha eseguito l’accesso a { $email }, non a questo account
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = il server non ha accettato l’accesso ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = la connessione al server non è riuscita ({ $reason })
# review: new
error-in-use = non può essere rimossa finché questi account accedono con essa: { $accounts }
# review: new
error-turned-off = questa app di accesso è disattivata per i nuovi account
# review: new
error-folder-name = il nome della cartella deve avere da 1 a 200 caratteri e non può contenere caratteri di controllo
# review: new
error-folder-separator = su questo server il nome di una cartella non può contenere “{ $separator }”
# review: new
error-folder-special = la Posta in arrivo e le cartelle speciali non possono essere rinominate o eliminate
# review: new
error-no-recipients = il messaggio non ha destinatari
# review: new
error-bad-address = “{ $address }” non è un indirizzo e-mail
# review: new
error-not-own-address = { $address } non è uno degli indirizzi di mittente di questo account. Aggiungilo ad “Altri indirizzi da cui invii” nelle proprietà dell’account.
# review: new
rule-query-refused = Le regole non possono filtrare per cartella o data ({ $words }).
# review: new
rule-no-query = Inserisci i criteri di ricerca per i messaggi in arrivo.
# review: new
rule-no-action = Scegli almeno un’azione per la regola.
# review: new
error-attachment = impossibile leggere { $path }: { $error }
# review: new
error-no-drafts = l’account non ha una cartella Bozze in cui salvare il messaggio
# review: new
error-draft-attachment = impossibile mantenere un allegato della bozza: { $error }
# review: new
error-password-not-saved = impossibile salvare la password per il prossimo avvio: { $error }
# review: new
error-sign-in-not-saved = impossibile salvare i nuovi dati di accesso per il prossimo avvio: { $error }
# review: new
error-import-unreadable = impossibile leggere { $path }: { $error }
# review: new
error-import-too-large = { $path } è più grande di 50 MB
# review: new
error-import-not-mail = { $path } non è un messaggio e-mail
# review: new
error-list-answered = il server della mailing list ha restituito lo stato { $status }
# review: new
error-not-built = impossibile creare il messaggio
# review: new
error-outbox-waits = { $count ->
    [one] il messaggio attende in Posta in uscita e verrà inviato al prossimo Invia/Ricevi
   *[other] { $count } messaggi attendono in Posta in uscita e verranno inviati al prossimo Invia/Ricevi
}
# review: new
error-draft-not-removed = impossibile rimuovere da Bozze la bozza precedente del messaggio: { $reason }
# review: new
error-sent-but = il messaggio è stato inviato, ma { $problem }
# review: new
error-sent-still-in-outbox = è ancora in Posta in uscita: { $error }
# review: new
error-sent-no-copy = impossibile salvare una copia in Posta inviata: { $reason }
# review: new
error-no-password = nessuna password per questo account
# review: new
error-no-sign-in = nessun accesso per questo account
# review: new
error-provider-missing = questa versione non può accedere a { $provider }: la sua app di accesso è stata rimossa?
# review: new
error-provider-servers = i server di questo account non corrispondono ai server della sua app di accesso
# review: new
error-app-scopes = { $reason }. Il server di posta non ha accettato il token dell’app di accesso: controlla che le autorizzazioni (scope) dell’app diano accesso alla posta
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Google non ha ancora verificato Inbox Classic, quindi consente l’accesso solo agli utenti di test. Usa la tua app di accesso Google o una password per le app, oppure attivala in App di accesso (File > Account) se sei un utente di test.
# review: new
sign-in-off-other = È stata disattivata in App di accesso (File > Account), dove si può riattivare.
# review: new
sign-in-app-no-name = l’app di accesso deve avere un nome
# review: new
sign-in-app-no-client = manca l’ID client
# review: new
sign-in-app-no-scopes = l’app di accesso richiede le autorizzazioni (scope) che danno accesso alla posta
# review: new
sign-in-app-bad-host = l’indirizzo del server { $server } manca o non è un nome host valido
# review: new
sign-in-app-plain = il server { $server } deve usare SSL/TLS o STARTTLS
# review: new
sign-in-app-not-checked = l’emittente non è ancora stato verificato
# review: new
sign-in-app-issuer-changed = l’emittente è cambiato: inserisci di nuovo il segreto client, o rimuovilo
# review: new
sign-in-register-google = In Google Cloud Console, crea un client OAuth di tipo App desktop, con l’autorizzazione (scope) https://mail.google.com/ nella schermata di consenso. Finché l’app è in fase di test, solo i suoi utenti di test possono accedere.
# review: new
sign-in-register-microsoft = In Microsoft Entra, registra un’app con la piattaforma Applicazioni per dispositivi mobili e desktop, l’URI di reindirizzamento http://localhost, i flussi client pubblici consentiti e le autorizzazioni delegate IMAP.AccessAsUser.All, SMTP.Send e offline_access. Solo per la tua organizzazione, usa https://login.microsoftonline.com/<ID tenant>/v2.0 come emittente.
# review: new
sign-in-register-other = Registra un client nativo (pubblico) con l’URI di reindirizzamento qui sotto; il provider deve consentire qualsiasi porta (RFC 8252). Aggiungi l’autorizzazione (scope) con cui il provider dà accesso alla posta.

## Calendar invitations

# review: new
repeats = Si ripete
# review: new
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Ogni giorno
       *[other] Ogni { $interval } giorni
    }
    [week] { $interval ->
        [one] Ogni settimana
       *[other] Ogni { $interval } settimane
    }
    [month] { $interval ->
        [one] Ogni mese
       *[other] Ogni { $interval } mesi
    }
   *[year] { $interval ->
        [one] Ogni anno
       *[other] Ogni { $interval } anni
    }
}
# "Ogni settimana, il lunedì, mercoledì"
# review: new
repeats-on = { $repeats }: { $days }
# "Ogni settimana, 10 volte"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, una volta
   *[other] { $repeats }, { $count } volte
}
# review: new
day-monday = lunedì
# review: new
day-tuesday = martedì
# review: new
day-wednesday = mercoledì
# review: new
day-thursday = giovedì
# review: new
day-friday = venerdì
# review: new
day-saturday = sabato
# review: new
day-sunday = domenica

## AI agents

# review: new
agent-level-read = Leggere la posta: cartelle, elenco messaggi, ricerca e messaggi
# review: new
agent-level-organize = Organizzare la posta: stato di lettura, contrassegni, posta indesiderata, spostamento, eliminazione in Posta eliminata
# review: new
agent-level-drafts = Scrivere bozze che invierai tu
# review: new
agent-level-send = Inviare posta, ogni messaggio solo dopo il tuo sì
# review: new
agent-connect-title = { $program } vuole usare la tua posta
# review: new
agent-connect-detail = Un agente IA ha chiesto di lavorare con Inbox Classic. Scegli cosa può fare e quali account può vedere; puoi cambiarlo in seguito in Strumenti > Agenti IA.

    Gli agenti leggono posta scritta da altre persone, e un messaggio può cercare di ingannarli. Inbox Classic ti chiede sempre conferma prima che un agente invii qualcosa.
# review: new
agent-reply-to = Risposta a “{ $subject }”
# review: new
agent-reply-all-on = Risposta a tutti su “{ $subject }”
# review: new
agent-forward-of = Inoltro di “{ $subject }”
# review: new
agent-never-written-one = Non hai mai scritto a { $address }.
# review: new
agent-never-written-many = Non hai mai scritto a { $count } di questi indirizzi.
# review: new
agent-send-title = { $program } vuole inviare questo messaggio
# review: new
agent-send-detail = Controlla i destinatari e il contenuto del messaggio. Dopo la tua conferma, il messaggio attende { $seconds } secondi in Posta in uscita, dove puoi ancora eliminarlo.
# review: new
agent-change-title = Cosa può fare { $program }
# review: new
agent-change-allowed = Cambia cosa possono fare con la tua posta gli agenti IA di questo programma.
# review: new
agent-change-refused = Hai negato l’accesso a questo programma. Consentilo per dare di nuovo ai suoi agenti l’accesso alla tua posta.
# review: new
agent-log-taken-back = { $entry } (annullato)
# review: new
agent-files = File: { $files }
# review: new
agent-undo-refused = Non può essere annullato.
# review: new
agent-undo-refused-why = Non può essere annullato: { $reason }.
# review: new
agent-undo-impossible = questa azione non può essere annullata
# review: new
agent-undo-not-in-folder = il messaggio non è più in quella cartella
# review: new
agent-undo-not-arrived = il messaggio non è (ancora) nella cartella di destinazione
# review: new
agent-undo-sent = il messaggio è già stato inviato
# review: new
agent-original-not-downloaded = il messaggio originale non è ancora stato scaricato. Aprilo prima
# review: new
agent-turned-away = Respinto
# review: new
agent-can-nothing = Niente
# review: new
agent-can-read = leggere
# review: new
agent-can-organize = organizzare
# review: new
agent-can-drafts = scrivere bozze
# review: new
agent-can-send = inviare con il tuo sì
# "Leggere, organizzare e scrivere bozze"
# review: new
agent-can-list = { $first } e { $last }
# review: new
agent-accounts = { $count ->
    [0] nessun account
    [one] 1 account
   *[other] { $count } account
}
# "Leggere e organizzare; 1 account"
# review: new
agent-access = { $can }; { $accounts }
# review: new
agent-unreadable = Questo messaggio non può essere letto.
# review: new
agent-encrypted-original = Questo messaggio è crittografato: un agente non può rispondere o inoltrarlo, perché non può crittografare.
# review: new
agent-encrypted = Questo messaggio è crittografato. Solo l’utente può leggerlo, in Inbox Classic.
# review: new
list-encrypted = Messaggio crittografato
# review: new
agent-log-composed = Aperto “{ $subject }” in un nuovo messaggio da completare
# review: new
agent-log-refused = Non hai inviato “{ $subject }”
# review: new
agent-log-sent = Inviato “{ $subject }” a { $to }
# review: new
agent-log-draft = Salvata la bozza “{ $subject }”
# review: new
agent-log-read = Segnato come letto “{ $subject }”
# review: new
agent-log-unread = Segnato come da leggere “{ $subject }”
# review: new
agent-log-flagged = Contrassegnato “{ $subject }”
# review: new
agent-log-unflagged = Rimosso il contrassegno da “{ $subject }”
# review: new
agent-log-deleted = Eliminato “{ $subject }”
# review: new
agent-log-moved = Spostato “{ $subject }” in { $folder }
# review: new
agent-log-junk = Segnato “{ $subject }” come posta indesiderata
# review: new
agent-log-not-junk = Segnato “{ $subject }” come posta desiderata
# review: new
agent-log-archived = Archiviato “{ $subject }”
# review: new
agent-log-folder = Creata la cartella “{ $name }”
# review: new
agent-log-unsubscribed = Annullata l’iscrizione alla lista di “{ $subject }”

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Maiusc
# review: new
key-del = Canc
# review: new
key-enter = Invio

## Signing in and passwords

# review: new
sign-in-no-refresh = il provider non ha fornito un token di aggiornamento
# review: new
sign-in-no-account = il provider non ha indicato quale account ha eseguito l’accesso
# review: new
sign-in-not-finished = l’accesso non è ancora terminato
# review: new
secrets-unavailable = { $store } non è disponibile
# review: new
secrets-unavailable-why = { $store } non è disponibile: { $error }
# review: new
secrets-windows = Gestione credenziali
# review: new
secrets-mac = il portachiavi
# review: new
secrets-linux = il portachiavi di sistema (Secret Service)
# review: new
error-no-such-file = il file non esiste
# review: new
cards-file-too-big = Questo file è troppo grande per essere una rubrica.
# review: new
ui-sender-added = { $name } è stato aggiunto alla Rubrica.
# review: new
ui-sender-known = { $name } è già nella Rubrica.
# review: new
ui-sender-none = Il mittente di questo messaggio non ha un indirizzo e-mail da aggiungere.
# review: new
card-name-needed = Il contatto non ha né un nome né un indirizzo e-mail.
# a file of Import Address Book that could not be read: "contatti.vcf: il file non esiste"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Codice da { $domain }
# review: new
otp-copy = Copia
# review: new
otp-note = Inseriscilo solo su una pagina di { $domain }.
# review: new
otp-old = Questo codice è stato inviato più di un’ora prima che lo aprissi, e probabilmente è scaduto.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } partecipante
       *[other] { $count } partecipanti
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code } è il tuo codice per { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Valida
# review: new
pgp-key-expires = Valida fino al { $date }
# review: new
pgp-key-expired = Scaduta il { $date }
# review: new
pgp-key-revoked = Revocata
# review: new
pgp-key-revoked-why = Revocata: { $reason }
# review: new
pgp-key-not-valid = Non valida
# review: new
pgp-key-locked = Non utilizzabile: la chiave che la protegge non è più in { $store }. Importa di nuovo il suo backup.
# review: new
pgp-source-own = Creata in Inbox Classic
# review: new
pgp-source-file = Importata da un file
# review: new
pgp-source-paste = Incollata
# review: new
pgp-source-attachment = Da un messaggio
# review: new
pgp-source-vcard = Da una scheda contatto
# review: new
pgp-source-wkd = Dal provider di posta del mittente
# review: new
pgp-source-keyserver = Da keys.openpgp.org
# review: new
pgp-source-autocrypt = Dall’intestazione Autocrypt di un messaggio
# review: new
pgp-error-no-store = Le chiavi private sono protette da { $store }, che non può essere usato: { $error }
# review: new
pgp-error-wrong-passphrase = La passphrase non è corretta.
# review: new
pgp-error-not-a-key = Questa non è una chiave OpenPGP.
# review: new
pgp-error-too-large = La chiave è troppo grande.
# review: new
pgp-error-unusable = La chiave usa una crittografia vecchia o debole e non può essere usata.
# review: new
pgp-imported-private = { $count ->
    [one] La tua chiave privata è stata importata.
   *[other] Sono state importate { $count } chiavi private.
}
# review: new
pgp-imported-public = { $count ->
    [one] È stata importata una chiave.
   *[other] Sono state importate { $count } chiavi.
}
# review: new
pgp-imported-pending = Un’altra chiave è già usata per { $addresses }: quella nuova attende nel contatto finché non la scegli.
# review: new
pgp-error-needs-passphrase = La chiave privata è protetta da una passphrase. Inseriscila per importare la chiave.
# review: new
pgp-error-mismatch = La chiave privata non appartiene alla sua chiave pubblica. Potrebbe essere stata alterata.
# review: new
pgp-file-name-public = Chiave pubblica di { $who }.asc
# review: new
pgp-file-name-private = Backup della chiave privata di { $who }.asc
# review: new
pgp-pending = Il { $date } è stata trovata una chiave diversa per { $address }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Firmato da { $signer }, chiave verificata
# review: new
pgp-part-signed = Firmato da { $signer } (chiave non verificata)
# review: new
pgp-part-other = Firmato da { $signer }, che non è il mittente
# review: new
pgp-part-unknown-key = Firmato, ma la chiave non è nota
# review: new
pgp-part-not-signed = Non firmato
# review: new
pgp-part-not-checked = Firma non verificata
# review: new
pgp-part-encrypted = Crittografato. { $signature }
# review: new
pgp-part-no-key = Crittografato per una chiave che non hai
# review: new
pgp-part-changed = La parte crittografata è stata modificata durante il percorso e non viene mostrata
# review: new
pgp-part-unprotected = Crittografato senza protezione contro le modifiche, non mostrato
# review: new
pgp-part-broken = La parte crittografata non può essere letta
# review: new
pgp-why-mismatch = La firma non corrisponde a questo testo
# review: new
pgp-why-weak-hash = La firma usa { $hash }, che non è più sicuro
# review: new
pgp-why-key-expired = Firmato dopo la scadenza della chiave, il { $date }
# review: new
pgp-why-key-revoked = Firmato con una chiave revocata
# review: new
pgp-why-not-signing-key = Firmato con una chiave che non può firmare
# review: new
pgp-why-from-future = La firma ha una data nel futuro
# review: new
pgp-why-signature-expired = La firma è scaduta
# review: new
pgp-why-key-not-valid = Firmato con una chiave non valida
# review: new
pgp-why-not-for-you = Firmato per altri destinatari, e poi passato a te
# review: new
pgp-part-pictures-loaded = { $label }. Le immagini sono state caricate da internet
# review: new
pgp-error-no-own-key = Non hai una chiave per { $address } con cui firmare o crittografare. Creane una in Strumenti > Chiavi di crittografia, o disattiva Firma e Crittografa.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } non ha una chiave per cui crittografare.
   *[other] Questi destinatari non hanno una chiave per cui crittografare: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Questo messaggio cita o inoltra un messaggio crittografato, quindi può essere inviato solo crittografato. Attiva Crittografa, o rimuovi il testo citato.
# review: new
pgp-error-protect = Impossibile firmare o crittografare il messaggio: { $reason }
# review: new
pgp-found-keys = Trovata la chiave di { $addresses }.
# review: new
pgp-found-none = Nessuna chiave trovata per { $addresses }. Chiedi di inviarti la loro chiave pubblica.
# review: new
pgp-found-no-key = Nessuna chiave trovata.
# review: new
pgp-find-unavailable = Al momento non è possibile cercare le chiavi: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org ha inviato un link di conferma a { $addresses }. La tua chiave sarà pubblicata lì dopo che ci avrai fatto clic.
# review: new
pgp-publish-done = La tua chiave è pubblicata su keys.openpgp.org per { $addresses }.
# review: new
pgp-publish-failed = Impossibile pubblicare la chiave: { $error }
# review: changed
pgp-keyserver-off = La ricerca delle chiavi su keys.openpgp.org è disattivata in { $settings }.
# review: new
pgp-details-part = Parte { $number }: { $label }
# review: new
pgp-details-signed = Firmato { $when } con la chiave { $key }
# review: new
pgp-details-unknown-key = Firmato con la chiave { $key }, che non hai
# review: new
pgp-details-opened = Crittografato per la tua chiave { $key }
# review: new
pgp-details-for = Crittografato per { $keys }
# review: new
pgp-details-plain = Non firmato e non crittografato
# review: new
pgp-bar-parts = Questo messaggio ha { $count } parti: { $list }. Ogni parte indica come è protetta.
# review: new
pgp-bar-count-verified = { $count } verificate
# review: new
pgp-bar-count-good = { $count ->
    [one] 1 firmata o crittografata
   *[other] { $count } firmate o crittografate
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 richiede attenzione
   *[other] { $count } richiedono attenzione
}
# review: new
pgp-bar-count-neutral = { $count } senza una firma confermata
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Impostazioni
# review: new
setup-part-preferences = Preferenze delle finestre
# review: new
setup-part-accounts = Account
# review: new
setup-part-sign-in-apps = App di accesso
# review: new
setup-part-contacts = Contatti e gruppi
# review: new
setup-part-keys = Chiavi di crittografia
# review: new
setup-part-rules = Regole messaggi
# review: new
setup-part-trusted-senders = Mittenti attendibili
# review: new
setup-holds-settings = { $count ->
    [one] 1 impostazione
   *[other] { $count } impostazioni
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 preferenza
   *[other] { $count } preferenze
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 account
   *[other] { $count } account
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 app di accesso
   *[other] { $count } app di accesso
}
# review: new
setup-holds-built-in = Quali app di accesso integrate sono attive
# review: new
setup-holds-contacts = { $count ->
    [one] 1 contatto
   *[other] { $count } contatti
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 gruppo
   *[other] { $count } gruppi
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 chiave tua
   *[other] { $count } chiavi tue
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 chiave di un contatto
   *[other] { $count } chiavi di contatti
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 regola
   *[other] { $count } regole
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 mittente attendibile
   *[other] { $count } mittenti attendibili
}
# review: new
setup-sign-in-password = Password
# review: new
setup-account-secret-password = La sua password è nel file.
# review: new
setup-account-secret-token = Il suo accesso è nel file.
# review: new
setup-account-asks-password = Chiede la sua password dopo l’importazione.
# review: new
setup-account-signs-in-again = Dovrai accedere di nuovo dopo l’importazione.
# review: new
setup-account-here = È già configurato qui, quindi viene saltato.
# review: new
setup-account-no-app = Accede con { $app }, che qui non è configurata. Importa anche le app di accesso.
# review: new
setup-invalid-address = “{ $address }” non è un indirizzo e-mail.
# review: new
setup-invalid-server = Il server { $server } non ha un nome o una porta utilizzabili.
# review: new
setup-invalid-user = Non ha un nome utente.
# review: new
setup-invalid-sign-in = Accede in un modo che Inbox Classic non conosce.
# review: new
setup-error-empty = Il file è vuoto.
# review: new
setup-error-too-large = Il file è troppo grande per essere una configurazione di Inbox Classic.
# review: new
setup-error-not-setup = Questo file non è una configurazione di Inbox Classic.
# review: new
setup-error-damaged = Il file di configurazione è danneggiato e non può essere letto.
# review: new
setup-error-newer = Questa configurazione è stata salvata da una versione più recente di Inbox Classic ({ $version }). Aggiorna Inbox Classic, poi importala di nuovo.
# review: new
setup-error-needs-passphrase = Questa configurazione è protetta da una passphrase. Inserisci la passphrase con cui è stata salvata.
# review: new
setup-error-wrong-passphrase = Non è la passphrase con cui è stata salvata questa configurazione.
# review: new
setup-error-changed = Il file di configurazione è stato modificato o danneggiato dopo il salvataggio, quindi non può essere importato.
# review: new
setup-error-read = Impossibile leggere il file di configurazione: { $error }
# review: new
setup-error-write = Impossibile salvare la configurazione: { $error }
# review: new
setup-error-no-parts = Scegli almeno una parte.
# review: new
setup-left-out = { $count ->
    [one] 1 voce di { $part } non può essere usata e viene esclusa.
   *[other] { $count } voci di { $part } non possono essere usate e vengono escluse.
}
# review: new
setup-imported-settings = Le impostazioni sono state sostituite.
# review: new
setup-imported-preferences = Le preferenze delle finestre sono state sostituite.
# review: new
setup-added-accounts = { $count ->
    [one] Aggiunto 1 account.
   *[other] Aggiunti { $count } account.
}
# review: new
setup-skipped-here = { $address } è già configurato qui, quindi è stato saltato.
# review: new
setup-skipped-no-app = { $address } è stato saltato: accede con { $app }, che qui non è configurata.
# review: new
setup-skipped-invalid = { $address } è stato saltato: { $reason }
# review: new
setup-asks-password = { $address } chiederà la sua password quando si connette.
# review: new
setup-signs-in-again = { $address } ti chiederà di accedere di nuovo quando si connette.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Aggiunta 1 app di accesso.
   *[other] Aggiunte { $count } app di accesso.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 app di accesso è già configurata qui.
   *[other] { $count } app di accesso sono già configurate qui.
}
# review: new
setup-added-contacts = { $count ->
    [one] Aggiunto 1 contatto alla rubrica.
   *[other] Aggiunti { $count } contatti alla rubrica.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 contatto è già nella rubrica.
   *[other] { $count } contatti sono già nella rubrica.
}
# review: new
setup-added-groups = { $count ->
    [one] Aggiunto o completato 1 gruppo.
   *[other] Aggiunti o completati { $count } gruppi.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Aggiunta 1 chiave tua.
   *[other] Aggiunte { $count } chiavi tue.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Aggiunta 1 chiave di un contatto.
   *[other] Aggiunte { $count } chiavi di contatti.
}
# review: new
setup-added-rules = { $count ->
    [one] Aggiunta 1 regola messaggi.
   *[other] Aggiunte { $count } regole messaggi.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 regola messaggi è già presente.
   *[other] { $count } regole messaggi sono già presenti.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 regola messaggi riguarda un account che qui non c’è, quindi è stata saltata.
   *[other] { $count } regole messaggi riguardano account che qui non ci sono, quindi sono state saltate.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 regola messaggi sposta i messaggi in una cartella che apparirà dopo la sincronizzazione del suo account.
   *[other] { $count } regole messaggi spostano i messaggi in cartelle che appariranno dopo la sincronizzazione dei loro account.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Aggiunto 1 mittente attendibile.
   *[other] Aggiunti { $count } mittenti attendibili.
}
# review: new
setup-nothing = Non è stato importato niente.
# review: new
setup-account-servers = { $imap } e { $smtp } ({ $signin })
# review: new
setup-file-name = Impostazioni e account di Inbox Classic
# review: new
setup-skipped-unreachable = { $name } è stato saltato: il suo servizio di accesso non era raggiungibile. Aggiungilo di nuovo in App di accesso.
# review: new
attachment-runs-programs = “{ $name }” può eseguire programmi, quindi Inbox Classic non lo apre. Salvalo, poi aprilo tu stesso se ti fidi della sua provenienza.
# review: new
attachment-decrypted-note = Questo allegato proviene da un messaggio crittografato. Per aprirlo, Inbox Classic lo conserva decrittografato su questo computer, in una tua cartella che Inbox Classic svuota dopo un giorno.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Il server non ha spostato { $messages } in { $folder }, quindi è di nuovo in { $from }: { $reason }
   *[other] Il server non ha spostato { $messages } in { $folder }, quindi sono di nuovo in { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Il server non ha eliminato { $messages }, quindi è di nuovo in { $from }: { $reason }
   *[other] Il server non ha eliminato { $messages }, quindi sono di nuovo in { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Il server non ha archiviato { $messages }, quindi è di nuovo in { $from }: { $reason }
   *[other] Il server non ha archiviato { $messages }, quindi sono di nuovo in { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Il server non ha segnato { $messages } come letto, quindi è di nuovo da leggere: { $reason }
   *[other] Il server non ha segnato { $messages } come letti, quindi sono di nuovo da leggere: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Il server non ha segnato { $messages } come da leggere, quindi è di nuovo letto: { $reason }
   *[other] Il server non ha segnato { $messages } come da leggere, quindi sono di nuovo letti: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Il server non ha cambiato i contrassegni di { $messages }, quindi è com’era: { $reason }
   *[other] Il server non ha cambiato i contrassegni di { $messages }, quindi sono com’erano: { $reason }
}
