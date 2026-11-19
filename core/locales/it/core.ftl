# Ciò che dice il core, uguale su ogni piattaforma. I segnaposto tra { $graffe } sono compilati dal codice; vanno
# mantenuti, nel punto in cui la lingua li richiede. I plurali scelgono in base al numero: [one] e *[other] in
# italiano.

## Counts and sizes

messages = { $count ->
    [one] 1 messaggio
   *[other] { $count } messaggi
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 byte
   *[other] { $count } byte
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Disattivato
send-delay-seconds = { $count ->
    [one] 1 secondo
   *[other] { $count } secondi
}
# the status bar: "12 messaggi, 3 da leggere"
list-counts = { $messages     }, { $unread } da leggere
list-counts-selected = { $messages }, { $unread } da leggere, { $selected ->
    [one] 1 selezionato
   *[other] { $selected } selezionati
}
# the status bar while searching: "12 trovati, 3 da leggere"
list-counts-found = { $found ->
    [one] { $found } trovato
   *[other] { $found } trovati
    }, { $unread } da leggere
list-counts-found-selected = { $found } trovati, { $unread } da leggere, { $selected } selezionati
list-counts-none = Nessun messaggio trovato

## Special folders, as Outlook Express names them

folder-inbox = Posta in arrivo
folder-sent = Posta inviata
folder-deleted = Posta eliminata
folder-drafts = Bozze
folder-junk = Posta indesiderata
folder-archive = Archivio

## The reading pane

reader-no-message = Nessun messaggio selezionato.
reader-downloading = Download del messaggio in corso…
reader-downloading-detail = Il messaggio apparirà qui al termine del download.
reader-downloading-size = Il messaggio è di { $size }. Apparirà qui quando sarà scaricato.
reader-failed = Impossibile scaricare il messaggio
reader-failed-network = Impossibile collegarsi al server di posta, oppure la connessione è stata interrotta ({ $reason }).
reader-failed-sign-in = Il server di posta non ha accettato l’accesso ({ $reason }). Controlla la password o accedi di nuovo nelle impostazioni dell’account.
reader-failed-security = Impossibile rendere sicura la connessione al server di posta ({ $reason }).
reader-failed-other = Risposta del server di posta: { $reason }.
reader-retry-note = Il download verrà riprovato quando l’account sarà di nuovo connesso.
reader-unreadable = Impossibile mostrare questo messaggio: { $error }
message-source-title = Origine messaggio: { $subject }
message-source-untitled = Origine messaggio

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Da
header-date = Data
header-to = A
header-cc = Cc
header-sent = Inviato
header-subject = Oggetto
header-security = Sicurezza
header-part = Parte { $number }
quote-original = ----- Messaggio originale -----
fold-show-earlier = Mostra i messaggi precedenti

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Il tuo messaggio non è stato recapitato
bounce-delayed = Il tuo messaggio non è ancora stato recapitato
bounce-delayed-note = Il tuo server di posta sta ancora cercando di recapitarlo. Non è necessario inviarlo di nuovo.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Mostra il messaggio non recapitato
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Mostra il messaggio in ritardo
bounce-what-to-do = Cosa puoi fare:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Per ora niente. Se non sarà possibile recapitarlo, riceverai un altro avviso.
bounce-delayed-row-do = Per ora niente. Il tuo server di posta sta ancora cercando di recapitarlo e, se non ci riuscirà, riceverai un altro avviso.
# folds the receiving server's own words
bounce-details = Dettagli
# a recipient the notice does not name
bounce-someone = Un destinatario
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Server: { $server }
bounce-status = Stato: { $status }
bounce-reported-by = Segnalato da: { $server }
bounce-retry-minutes = Il server di destinazione ha chiesto di attendere { $count ->
    [one] un minuto
   *[other] { $count } minuti
} prima del prossimo tentativo.
bounce-retry-hours = Il server di destinazione ha chiesto di attendere { $count ->
    [one] un’ora
   *[other] { $count } ore
} prima del prossimo tentativo.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Lista di blocco: { $lists }
bounce-user-unknown = L’indirizzo non esiste
bounce-user-unknown-why = Il server di destinazione non ha una casella con questo indirizzo. Potrebbe contenere un errore di battitura, o la persona potrebbe non usarlo più.
bounce-user-unknown-do = Controlla che l’indirizzo sia corretto o chiedi al destinatario quale indirizzo usare.
bounce-invalid-address = L’indirizzo non è valido
bounce-invalid-address-why = L’indirizzo non ha un formato valido, quindi non è possibile inviarvi posta.
bounce-invalid-address-do = Controlla che non ci siano errori di battitura, come spazi, lettere mancanti o un dominio mancante dopo la @.
bounce-mailbox-disabled = La casella è disattivata
bounce-mailbox-disabled-why = L’indirizzo esiste, ma la sua casella è stata disattivata o non è più in uso.
bounce-mailbox-disabled-do = Contatta la persona in un altro modo e chiedile un indirizzo che usa ora.
bounce-mailbox-full = La casella è piena
bounce-mailbox-full-why = La casella del destinatario non ha spazio per nuova posta.
bounce-mailbox-full-do = Riprova a inviare il messaggio più tardi oppure contatta il destinatario in un altro modo, perché possa liberare spazio nella casella.
bounce-spam-blocked = Rifiutato come spam
bounce-spam-blocked-why = Il server di destinazione ha scambiato il messaggio per spam.
bounce-spam-blocked-do = Rimuovi gli elementi che potrebbero sembrare spam, come molti link, link abbreviati o un allegato grande, e riprova a inviare. Se il problema persiste, contatta il tuo provider di posta.
bounce-virus-detected = Rifiutato per un virus
bounce-virus-detected-why = Il server di destinazione ha rifiutato il messaggio perché sospetta un virus o altro contenuto dannoso nel testo o negli allegati.
bounce-virus-detected-do = Controlla gli allegati con un antivirus. Alcuni server rifiutano ogni programma o archivio, quindi condividi questi file tramite un link.
bounce-ip-blocklisted = Il tuo server di posta è in una lista di blocco
bounce-ip-blocklisted-why = Il server di destinazione rifiuta il messaggio perché l’indirizzo del server che lo ha inviato compare in una lista di blocco.
bounce-ip-blocklisted-do = Il problema riguarda il server di posta. Inoltra questo avviso al tuo provider e chiedi di far rimuovere il server dalla lista di blocco.
bounce-domain-blocklisted = Un dominio è in una lista di blocco
bounce-domain-blocklisted-why = Il server di destinazione rifiuta il messaggio perché il dominio del tuo indirizzo, o un dominio presente nei link, compare in una lista di blocco.
bounce-domain-blocklisted-do = Se il messaggio contiene link, prova senza. Altrimenti inoltra questo avviso a chi gestisce la posta del tuo dominio.
bounce-policy-blocked = Rifiutato dalle regole del server di destinazione
bounce-policy-blocked-why = Le regole del server di destinazione non lasciano passare questo messaggio, per esempio per le sue dimensioni, i suoi allegati o il mittente.
bounce-policy-blocked-do = La risposta del server riportata in Dettagli spesso indica il motivo. Chiedi al destinatario se può ricevere messaggi di questo tipo.
bounce-geo-blocked = Rifiutato per la sua provenienza
bounce-geo-blocked-why = Il server di destinazione non accetta posta dal paese o dalla rete in cui si trova il tuo server di posta.
bounce-geo-blocked-do = Contatta la persona in un altro modo, o chiedi informazioni al tuo provider di posta.
bounce-relay-denied = Il server ha rifiutato di inoltrare il messaggio
bounce-relay-denied-why = Un server ha rifiutato di inoltrare il messaggio. Può accadere se non è stato eseguito l’accesso o se il server non gestisce il destinatario.
bounce-relay-denied-do = Nelle impostazioni dell’account, controlla il server della posta in uscita e le credenziali di accesso.
bounce-auth-failure = Impossibile verificare l’indirizzo del mittente
bounce-auth-failure-why = Il server di destinazione non ha potuto confermare che il messaggio provenga davvero dal tuo dominio (SPF, DKIM o DMARC).
bounce-auth-failure-do = Inoltra questo avviso a chi gestisce la posta del tuo dominio: le sue impostazioni vanno corrette. Nel frattempo può aiutare inviare tramite il server del tuo provider.
bounce-rate-limited = Troppa posta in una volta
bounce-rate-limited-why = Per ora il server di destinazione accetta meno messaggi dal tuo server di posta.
bounce-rate-limited-do = Attendi un po’ e invialo di nuovo. Quando scrivi a molte persone, invia a meno destinatari alla volta.
bounce-greylisting = Recapito temporaneamente rinviato
bounce-greylisting-why = Il server di destinazione chiede ai mittenti sconosciuti di riprovare dopo un breve intervallo. È un controllo antispam comune.
bounce-greylisting-do = Il greylisting è normalmente un rifiuto temporaneo e i server di posta spesso riprovano. Se però questa notifica segnala un errore definitivo, prova a inviare di nuovo il messaggio più tardi.
bounce-server-error = Il server di destinazione ha avuto un problema
bounce-server-error-why = Il server di destinazione non era raggiungibile, o non ha potuto accettare il messaggio per un suo problema.
bounce-server-error-do = Prova a inviare di nuovo il messaggio più tardi. Se il problema persiste, controlla che non ci siano errori nella parte dell’indirizzo dopo la @.
bounce-unknown = Non recapitato
bounce-unknown-why = L’avviso non spiega chiaramente il motivo.
bounce-unknown-do = La risposta del server riportata in Dettagli potrebbe fornire altre informazioni. Se il motivo resta poco chiaro, inoltra questo avviso al tuo provider di posta.

## Several messages selected

selection-title = { $count ->
    [one] 1 messaggio selezionato
   *[other] { $count } messaggi selezionati
}
selection-unread = { $count } da leggere
selection-flagged = { $count ->
    [one] { $count } contrassegnato
   *[other] { $count } contrassegnati
}
delete-for-good-one = Questo messaggio verrà eliminato definitivamente. Eliminarlo?
delete-for-good-all = Questi { $count } messaggi verranno eliminati definitivamente. Eliminarli?
delete-for-good-some = { $count ->
    [one] { $count } dei { $total } messaggi verrà eliminato definitivamente. Eliminare i messaggi?
   *[other] { $count } dei { $total } messaggi verranno eliminati definitivamente. Eliminare i messaggi?
}
done-read = { $count ->
    [one] { $messages } segnato come letto
   *[other] { $messages } segnati come letti
}
done-unread = { $count ->
    [one] { $messages } segnato come da leggere
   *[other] { $messages } segnati come da leggere
}
done-flagged = { $count ->
    [one] { $messages } contrassegnato
   *[other] { $messages } contrassegnati
}
done-unflagged = Contrassegno rimosso da { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } eliminato definitivamente
   *[other] { $messages } eliminati definitivamente
}
done-archived = { $count ->
    [one] { $messages } archiviato
   *[other] { $messages } archiviati
}
done-moved = { $count ->
    [one] { $messages } spostato in { $folder }
   *[other] { $messages } spostati in { $folder }
}
done-copied = { $count ->
    [one] { $messages } copiato in { $folder }
   *[other] { $messages } copiati in { $folder }
}
done-moving = { $count ->
   *[other] Spostamento di { $messages } in { $folder }...
}
done-copying = { $count ->
   *[other] Copia di { $messages } in { $folder }...
}
done-moved-back = { $count ->
    [one] { $messages } riportato in { $folder }
   *[other] { $messages } riportati in { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Conversazione seguita
   *[other] { $count } conversazioni seguite
}
done-unwatched = { $count ->
    [one] Non segui più la conversazione
   *[other] Non segui più { $count } conversazioni
}
done-ignored = { $count ->
    [one] Conversazione ignorata
   *[other] { $count } conversazioni ignorate
}
done-unignored = { $count ->
    [one] Non ignori più la conversazione
   *[other] Non ignori più { $count } conversazioni
}
their-folders = cartelle diverse
undo-move = Annulla spostamento
undo-delete = Annulla eliminazione
undo-archive = Annulla archiviazione
undo-junk = Annulla “Segna come indesiderata”
undo-not-junk = Annulla “Segna come posta desiderata”
undo-send = Annulla invio
nothing-to-undo = Non c’è niente da annullare.
messages-gone = I messaggi non sono più disponibili.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Questa cartella non può contenere messaggi.
not-archived-here = I messaggi di questa cartella non possono essere archiviati.
not-emptied-here = Si possono svuotare solo Posta eliminata e Posta indesiderata.
next-unread-question = Non ci sono altri messaggi da leggere in { $folder }.

    Passare a { $next }, la prossima cartella con messaggi da leggere?
no-unread-left = Non ci sono più messaggi da leggere.
empty-question = { $count ->
    [one] Svuotare { $folder }?

        Il messaggio che contiene viene eliminato definitivamente. Non potrà essere recuperato.
   *[other] Svuotare { $folder }?

        I { $messages } che contiene vengono eliminati definitivamente. Non potranno essere recuperati.
}
no-junk-folder = Questo account non ha una cartella Posta indesiderata in cui spostare i messaggi.
no-inbox-folder = Questo account non ha una cartella Posta in arrivo in cui spostare i messaggi.
# the status bar after a flag in a colour: "Contrassegno aggiunto a 2 messaggi: blu"
done-flagged-color = Contrassegno { $color ->
    [red] rosso
    [orange] arancione
    [yellow] giallo
    [green] verde
    [blue] blu
    [purple] viola
   *[gray] grigio
    } aggiunto a { $messages }
# the Flag menu: the colours of Apple Mail's flags
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

move-window-title-move = { $count ->
    [one] Sposta messaggio
   *[other] Sposta { $count } messaggi
}
move-window-title-copy = { $count ->
    [one] Copia messaggio
   *[other] Copia { $count } messaggi
}
move-window-prompt-move = { $count ->
    [one] Sposta il messaggio selezionato in:
   *[other] Sposta i { $count } messaggi selezionati in:
}
move-window-prompt-copy = { $count ->
    [one] Copia il messaggio selezionato in:
   *[other] Copia i { $count } messaggi selezionati in:
}
# the folders used last, over the folder tree
targets-recent = Recenti
# the folder the messages are in, which can not be chosen
target-current = { $folder } (attuale)
# a folder used last, with its account when there are several: "Archivio (Lavoro)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Spostamento in { $folder }: { $done } su { $messages }...
transfer-copying = Copia in { $folder }: { $done } su { $messages }...
transfer-another-account = un altro account
transfer-folder-gone = la cartella di destinazione non esiste più
transfer-not-on-server = il messaggio non è più sul server
transfer-not-moved = { $count ->
    [one] Impossibile spostare { $messages } in un altro account: { $reason }
   *[other] Impossibile spostare { $messages } in un altro account: { $reason }
}
transfer-not-copied = { $count ->
    [one] Impossibile copiare { $messages } in un altro account: { $reason }
   *[other] Impossibile copiare { $messages } in un altro account: { $reason }
}
transfer-none-moved = Non è stato possibile spostare nessun messaggio
transfer-none-copied = Non è stato possibile copiare nessun messaggio

## Messages as files

export-not-in-time = non è stato possibile scaricare il messaggio in tempo
export-not-saved = Salvataggio non riuscito per { $failed } su { $messages } ({ $problems })
export-not-attached = impossibile allegare i messaggi: { $error }
# the status bar after Save As with several: "3 messaggi salvati in Scrivania"
saved-to = { $count ->
    [one] { $messages } salvato in { $folder }
   *[other] { $messages } salvati in { $folder }
}
download-progress = Download: { $done } su { $total }
download-done = Download completato: { $size }
downloading-messages = { $count ->
   *[other] Download di { $messages }...
}
# the status bar after files are dropped on a folder: "3 messaggi messi in Archivio"
import-put = { $count ->
    [one] { $messages } in coda per l’importazione in { $folder }
   *[other] { $messages } in coda per l’importazione in { $folder }
}
import-not-put = Questi messaggi non sono stati aggiunti alla cartella:

    { $problems }

## Problems the windows show

error-store = archivio locale: { $error }
error-not-found = non trovato
error-closed = chiusura in corso
error-other-account = il browser ha eseguito l’accesso a { $email }, non a questo account
# a password or sign-in the mail server refused, with the server's words
failure-authentication = il server non ha accettato l’accesso ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = la connessione al server non è riuscita ({ $reason })
error-in-use = l’app non può essere rimossa perché è ancora usata da questi account: { $accounts }
error-turned-off = questa app di accesso è disattivata per i nuovi account
error-folder-name = il nome della cartella deve avere da 1 a 200 caratteri e non può contenere caratteri di controllo
error-folder-separator = su questo server il nome di una cartella non può contenere “{ $separator }”
error-folder-special = la Posta in arrivo e le cartelle speciali non possono essere rinominate o eliminate
error-no-recipients = il messaggio non ha destinatari
error-bad-address = “{ $address }” non è un indirizzo e-mail
error-not-own-address = { $address } non è un indirizzo di invio di questo account. Aggiungilo al campo “Altri indirizzi da cui invii” nelle proprietà dell’account.
rule-query-refused = Le regole non possono filtrare per cartella o data ({ $words }).
rule-no-query = Inserisci i criteri di ricerca per i messaggi in arrivo.
rule-no-action = Scegli almeno un’azione per la regola.
error-attachment = impossibile leggere { $path }: { $error }
error-no-drafts = l’account non ha una cartella Bozze in cui salvare il messaggio
error-draft-attachment = impossibile mantenere un allegato della bozza: { $error }
error-password-not-saved = impossibile salvare la password per il prossimo avvio: { $error }
error-sign-in-not-saved = impossibile salvare i nuovi dati di accesso per il prossimo avvio: { $error }
error-import-unreadable = impossibile leggere { $path }: { $error }
error-import-too-large = { $path } è più grande di 50 MB
error-import-not-mail = { $path } non è un messaggio e-mail
error-list-answered = il server della mailing list ha restituito lo stato { $status }
error-not-built = impossibile creare il messaggio
error-outbox-waits = { $count ->
    [one] il messaggio attende in Posta in uscita; l’app riproverà a inviarlo al prossimo Invia/Ricevi
   *[other] { $count } messaggi attendono in Posta in uscita; l’app riproverà a inviarli al prossimo Invia/Ricevi
}
error-draft-not-removed = impossibile rimuovere da Bozze la bozza precedente del messaggio: { $reason }
error-sent-but = il messaggio è stato inviato, ma { $problem }
error-sent-still-in-outbox = è ancora in Posta in uscita: { $error }
error-sent-no-copy = impossibile salvare una copia in Posta inviata: { $reason }
error-no-password = nessuna password per questo account
error-no-sign-in = mancano le credenziali di accesso per questo account
error-provider-missing = questa versione di Inbox Classic non può accedere a { $provider }. L’app di accesso potrebbe essere stata rimossa
error-provider-servers = i server di questo account non corrispondono ai server della sua app di accesso
error-app-scopes = { $reason }. Il server di posta non ha accettato il token dell’app di accesso: controlla che le autorizzazioni (scope) dell’app diano accesso alla posta
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = L’app di accesso Google integrata è disattivata per impostazione predefinita. Usa la tua app di accesso o una password per le app, se il tuo account la consente. Puoi attivare l’app integrata in App di accesso se sei autorizzato a usarla.
sign-in-off-other = Questa app è disattivata. Puoi riattivarla in App di accesso, dalla finestra degli account.
sign-in-app-no-name = l’app di accesso deve avere un nome
sign-in-app-no-client = manca l’ID client
sign-in-app-no-scopes = l’app di accesso richiede le autorizzazioni (scope) che danno accesso alla posta
sign-in-app-bad-host = l’indirizzo del server { $server } manca o non è un nome host valido
sign-in-app-plain = il server { $server } deve usare SSL/TLS o STARTTLS
sign-in-app-not-checked = l’emittente non è ancora stato verificato
sign-in-app-issuer-changed = l’emittente è cambiato: inserisci di nuovo il segreto client, o rimuovilo
sign-in-register-google = In Google Cloud Console, crea un client OAuth di tipo App desktop, con l’autorizzazione (scope) https://mail.google.com/ nella schermata di consenso. Finché l’app è in fase di test, solo i suoi utenti di test possono accedere.
sign-in-register-microsoft = In Microsoft Entra, registra un’app con la piattaforma Applicazioni per dispositivi mobili e desktop, l’URI di reindirizzamento http://localhost, i flussi client pubblici consentiti e le autorizzazioni delegate IMAP.AccessAsUser.All, SMTP.Send e offline_access. Solo per la tua organizzazione, usa https://login.microsoftonline.com/<ID tenant>/v2.0 come emittente.
sign-in-register-other = Registra un client nativo (pubblico) con l’URI di reindirizzamento qui sotto; il provider deve consentire qualsiasi porta (RFC 8252). Aggiungi l’autorizzazione (scope) con cui il provider dà accesso alla posta.

## Calendar invitations

repeats = Si ripete
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
repeats-on = { $repeats }: { $days }
# "Ogni settimana, 10 volte"
repeats-times = { $count ->
    [one] { $repeats }, una volta
   *[other] { $repeats }, { $count } volte
}
day-monday = lunedì
day-tuesday = martedì
day-wednesday = mercoledì
day-thursday = giovedì
day-friday = venerdì
day-saturday = sabato
day-sunday = domenica

## AI agents

agent-level-read = Leggere la posta: cartelle, elenchi, messaggi, allegati supportati, ricerche, regole e contatti
agent-level-organize = Organizzare la posta: cambiare lo stato di lettura, i contrassegni e i loro colori, gestire la posta indesiderata, spostare, archiviare ed eliminare messaggi (in Posta eliminata), creare e rinominare cartelle, seguire e ignorare conversazioni e annullare l’iscrizione alle mailing list con il tuo consenso
agent-level-drafts = Scrivere bozze che invierai tu
agent-level-send = Inviare posta, con la tua conferma per ogni messaggio
agent-connect-title = { $program } vuole accedere alla tua posta
agent-connect-detail = Un agente IA vuole collegarsi a Inbox Classic. Scegli quali azioni può eseguire e a quali account può accedere. Puoi cambiare queste autorizzazioni in Strumenti > Agenti IA.

    La posta che un agente legge può contenere istruzioni ingannevoli scritte da altre persone. Inbox Classic chiede sempre la tua conferma prima che un agente invii un messaggio.
agent-reply-to = Risposta a “{ $subject }”
agent-reply-all-on = Risposta a tutti su “{ $subject }”
agent-forward-of = Inoltro di “{ $subject }”
agent-never-written-one = Non hai mai scritto a { $address }.
agent-never-written-many = Non hai mai scritto a { $count } di questi indirizzi.
agent-send-title = { $program } vuole inviare questo messaggio
agent-send-detail = Controlla i destinatari e il contenuto del messaggio. Dopo la tua conferma, il messaggio attende { $seconds } secondi in Posta in uscita, dove puoi ancora eliminarlo.
agent-change-title = Cosa può fare { $program }
agent-change-allowed = Modifica le azioni che gli agenti IA di questo programma possono eseguire sulla tua posta.
agent-change-refused = Hai negato l’accesso a questo programma. Autorizzalo per consentire ai suoi agenti di accedere di nuovo alla tua posta.
agent-log-taken-back = { $entry } (annullato)
agent-files = File: { $files }
agent-undo-refused = Questa azione non può essere annullata.
agent-undo-refused-why = Questa azione non può essere annullata: { $reason }.
agent-undo-impossible = questa azione non può essere annullata
agent-undo-not-in-folder = il messaggio non è più in quella cartella
agent-undo-not-arrived = il messaggio non è (ancora) nella cartella di destinazione
agent-undo-sent = il messaggio non è più in Posta in uscita
agent-original-not-downloaded = il messaggio originale non è ancora stato scaricato. Aprilo prima
agent-turned-away = Respinto
agent-can-nothing = Niente
agent-can-read = leggere
agent-can-organize = organizzare
agent-can-drafts = scrivere bozze
agent-can-send = inviare con la tua conferma
# "Leggere, organizzare e scrivere bozze"
agent-can-list = { $first } e { $last }
agent-accounts = { $count ->
    [0] nessun account
    [one] 1 account
   *[other] { $count } account
}
# "Leggere e organizzare; 1 account"
agent-access = { $can }; { $accounts }
agent-unreadable = Questo messaggio non può essere letto.
agent-encrypted-original = Questo messaggio è crittografato: un agente non può rispondere o inoltrarlo, perché non può crittografare.
agent-encrypted = Questo messaggio è crittografato. Gli agenti IA non possono leggerne il contenuto. L’utente deve aprirlo in Inbox Classic.
agent-too-many-changes = L’agente ha raggiunto il limite di modifiche che Inbox Classic registra per un programma negli ultimi 30 giorni. Potrà effettuarne altre quando le più vecchie avranno 30 giorni.
agent-too-many-reads = L’agente ha raggiunto il limite di letture che Inbox Classic registra per un programma negli ultimi 30 giorni. Potrà leggere altri dati quando le letture più vecchie avranno 30 giorni.
list-encrypted = Messaggio crittografato
agent-log-composed = Aperto “{ $subject }” in un nuovo messaggio da completare
agent-log-refused = Non hai inviato “{ $subject }”
agent-log-sent = “{ $subject }” messo in coda per l’invio a { $to }
agent-log-draft = Salvata la bozza “{ $subject }”
agent-log-draft-replaced = Sostituita la bozza “{ $subject }”
agent-log-draft-discarded = Richiesta l’eliminazione della bozza “{ $subject }”
agent-draft-note = { $program }, un agente IA, ha scritto questa bozza. Controlla i destinatari e il testo prima di inviarla.
agent-log-read = Segnato come letto “{ $subject }”
agent-log-unread = Segnato come da leggere “{ $subject }”
agent-log-flagged = Contrassegnato “{ $subject }”
agent-log-unflagged = Rimosso il contrassegno da “{ $subject }”
agent-log-deleted = Eliminato “{ $subject }”
agent-log-moved = Spostato “{ $subject }” in { $folder }
agent-log-junk = Segnato “{ $subject }” come posta indesiderata
agent-log-not-junk = Segnato “{ $subject }” come posta desiderata
agent-log-archived = Archiviato “{ $subject }”
agent-log-folder = Richiesta la creazione della cartella “{ $name }”
agent-log-unsubscribed = Hai autorizzato la richiesta di annullamento dell’iscrizione. Messaggio: “{ $subject }”
agent-log-unsubscribe-failed = Impossibile annullare l’iscrizione alla mailing list del messaggio “{ $subject }”: { $reason }
agent-log-unsubscribe-refused = Non hai confermato l’annullamento dell’iscrizione. Mittenti: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } vuole annullare la tua iscrizione a una mailing list
   *[other] { $program } vuole annullare la tua iscrizione a { $count } mailing list
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic chiede alla mailing list qui sotto di non inviarti più messaggi, usando la funzione di annullamento dell’iscrizione con un clic. Non viene inviato nient’altro. I messaggi già presenti restano invariati.
   *[other] Inbox Classic chiede a ogni mailing list qui sotto di non inviarti più messaggi, usando la funzione di annullamento dell’iscrizione con un clic. Non viene inviato nient’altro. I messaggi già presenti restano invariati.
}
agent-log-flag-color = Contrassegno { $color ->
    [red] rosso
    [orange] arancione
    [yellow] giallo
    [green] verde
    [blue] blu
    [purple] viola
   *[gray] grigio
} aggiunto a “{ $subject }”
agent-log-renamed = Richiesta la rinomina della cartella “{ $old }” in “{ $name }”
agent-log-watched = Seguita la conversazione “{ $subject }”
agent-log-ignored = Ignorata la conversazione “{ $subject }”
agent-log-unmarked = La conversazione “{ $subject }” non è più seguita né ignorata
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = il messaggio è stato modificato nel frattempo
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Segnato come letto 1 messaggio (ricerca: { $query })
   *[other] Segnati come letti { $count } messaggi (ricerca: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Segnato come da leggere 1 messaggio (ricerca: { $query })
   *[other] Segnati come da leggere { $count } messaggi (ricerca: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Contrassegnato 1 messaggio (ricerca: { $query })
   *[other] Contrassegnati { $count } messaggi (ricerca: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Rimosso il contrassegno da 1 messaggio (ricerca: { $query })
   *[other] Rimosso il contrassegno da { $count } messaggi (ricerca: { $query })
}
agent-log-bulk-color = Contrassegno { $color ->
    [red] rosso
    [orange] arancione
    [yellow] giallo
    [green] verde
    [blue] blu
    [purple] viola
   *[gray] grigio
} aggiunto a { $count ->
    [one] 1 messaggio
   *[other] { $count } messaggi
} (ricerca: { $query })
agent-log-bulk-moved = { $count ->
    [one] Spostato 1 messaggio in { $folder } (ricerca: { $query })
   *[other] Spostati { $count } messaggi in { $folder } (ricerca: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Archiviato 1 messaggio (ricerca: { $query })
   *[other] Archiviati { $count } messaggi (ricerca: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Segnato 1 messaggio come posta indesiderata (ricerca: { $query })
   *[other] Segnati { $count } messaggi come posta indesiderata (ricerca: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Segnato 1 messaggio come posta desiderata (ricerca: { $query })
   *[other] Segnati { $count } messaggi come posta desiderata (ricerca: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Eliminato 1 messaggio (ricerca: { $query })
   *[other] Eliminati { $count } messaggi (ricerca: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] Negli ultimi 15 minuti
    [hour] Nell’ultima ora
    [hours] Nelle ultime 4 ore
    [day] Nelle ultime 24 ore
    [week] Negli ultimi 7 giorni
   *[all] Negli ultimi 30 giorni
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] { $program } non ha fatto modifiche annullabili in questo periodo.
    [one] Annullare la modifica fatta da { $program } in questo periodo?
   *[other] Annullare le { $count } modifiche fatte da { $program } in questo periodo?
}
agent-undo-since-detail = L’app tenta di riportare i messaggi nelle cartelle precedenti e di ripristinare lo stato di lettura e i contrassegni. I messaggi ancora in Posta in uscita vengono eliminati. Prima verifica lo stato interessato dall’operazione. Alcune modifiche successive, come il colore di un contrassegno, possono comunque essere sovrascritte.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Non è stato annullato nulla.
    [one] Annullata 1 modifica, in tutto o in parte.
   *[other] Annullate { $count } modifiche, in tutto o in parte.
}
agent-undo-left-gone = { $count ->
    [one] 1 messaggio non si trovava più nella posizione prevista.
   *[other] { $count } messaggi non si trovavano più nelle posizioni previste.
}
agent-undo-left-changed = { $count ->
    [one] 1 messaggio è stato saltato perché modificato nel frattempo da te o sul server.
   *[other] { $count } messaggi sono stati saltati perché modificati nel frattempo da te o sul server.
}
agent-undo-left-sent = { $count ->
    [one] 1 messaggio aveva già lasciato Posta in uscita.
   *[other] { $count } messaggi avevano già lasciato Posta in uscita.
}
agent-undo-left-impossible = { $count ->
    [one] 1 modifica non può essere annullata.
   *[other] { $count } modifiche non possono essere annullate.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Con questo messaggio accetti l’invito “{ $summary }” ({ $when }).
    [tentative] Con questo messaggio accetti con riserva l’invito “{ $summary }” ({ $when }).
   *[decline] Con questo messaggio rifiuti l’invito “{ $summary }” ({ $when }).
} All’organizzatore viene inviata una risposta di calendario. Inbox Classic aggiorna la tua risposta dopo l’invio, senza attendere una conferma dall’organizzatore.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Accettato: { $summary }
    [tentative] Accettato con riserva: { $summary }
   *[decline] Rifiutato: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } ha accettato questo invito.
    [tentative] { $name } ha accettato questo invito con riserva.
   *[decline] { $name } ha rifiutato questo invito.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] letto 1 messaggio
   *[other] letti { $count } messaggi
}
agent-reads-attachments = { $count ->
    [one] richiesto 1 allegato
   *[other] richiesti { $count } allegati
}
agent-reads-searches = { $count ->
    [one] eseguita 1 ricerca
   *[other] eseguite { $count } ricerche
}
agent-reads-lists = { $count ->
    [one] consultata 1 riga degli elenchi dei messaggi
   *[other] consultate { $count } righe degli elenchi dei messaggi
}
# each read under that row
agent-read-message = Letto “{ $subject }”
agent-read-conversation = { $count ->
    [one] Letta la conversazione “{ $subject }” (1 messaggio)
   *[other] Letta la conversazione “{ $subject }” ({ $count } messaggi)
}
agent-read-attachment = Richiesto l’allegato “{ $name }” del messaggio “{ $subject }”
agent-read-search = { $count ->
    [one] Cercato “{ $query }”: 1 messaggio
   *[other] Cercato “{ $query }”: { $count } messaggi
}
agent-read-people = Cercati contatti con nome o indirizzo che inizia con “{ $query }”
agent-read-list = { $count ->
    [one] Consultati i dati di 1 voce dell’elenco in { $folder }
   *[other] Consultati i dati di { $count } voci dell’elenco in { $folder }
}
agent-read-changes = { $count ->
    [one] Consultati i dati di 1 nuovo messaggio
   *[other] Consultati i dati di { $count } nuovi messaggi
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Programmi avviati da { $terminal }
agent-terminal-programs-windows = Programmi avviati da un terminale ({ $terminal })
agent-terminal-programs-linux = Programmi avviati da un terminale ({ $terminal })
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
agent-terminal-program-mac = Un programma avviato da { $terminal }
agent-terminal-program-windows = Un programma avviato da un terminale ({ $terminal })
agent-terminal-program-linux = Un programma avviato da un terminale ({ $terminal })
agent-connect-title-terminal = { $programs } vogliono accedere alla tua posta
agent-connect-terminal-detail = Gli agenti avviati dallo stesso programma di terminale riconosciuto condividono l’accesso che consenti qui. Per gestire un agente separatamente, aggiungi --name e un nome a tua scelta ai suoi argomenti nelle impostazioni MCP. Il nome non dimostra l’identità del programma.
agent-connect-claimed = Ha dichiarato di essere { $claimed }. Inbox Classic ha verificato quale programma lo ha avviato: { $program }.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Maiusc
key-del = Canc
key-enter = Invio

## Signing in and passwords

sign-in-no-refresh = il provider non ha fornito un token di aggiornamento
sign-in-no-account = il provider non ha indicato quale account ha eseguito l’accesso
sign-in-not-finished = l’accesso non è ancora terminato
secrets-unavailable = { $store } non è disponibile
secrets-unavailable-why = { $store } non è disponibile: { $error }
secrets-windows = Gestione credenziali
secrets-mac = il portachiavi
secrets-linux = il portachiavi di sistema (Secret Service)
error-no-such-file = il file non esiste
cards-file-too-big = Il file supera il limite di dimensione per l’importazione di una rubrica.
ui-sender-added = Aggiunto alla Rubrica il contatto { $name }.
ui-sender-known = { $name } è già nella Rubrica.
ui-sender-none = Il mittente di questo messaggio non ha un indirizzo e-mail da aggiungere.
card-name-needed = Il contatto non ha né un nome né un indirizzo e-mail.
# a file of Import Address Book that could not be read: "contatti.vcf: il file non esiste"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Codice da { $domain }
otp-copy = Copia
otp-note = Inseriscilo solo su una pagina di { $domain }.
otp-old = La data del messaggio precede di oltre un’ora il momento dell’apertura. Il codice potrebbe essere scaduto; Inbox Classic non ne verifica la validità effettiva.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } partecipante
       *[other] { $count } partecipanti
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code } è il tuo codice per { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Valida
pgp-key-expires = Valida fino al { $date }
pgp-key-expired = Scaduta il { $date }
pgp-key-revoked = Revocata
pgp-key-revoked-why = Revocata: { $reason }
pgp-key-not-valid = Non valida
pgp-key-locked = Impossibile recuperare da { $store } la chiave che protegge questa chiave privata. Controlla che l’archivio sia disponibile e sbloccato. Se la chiave di protezione è andata persa, importa di nuovo il backup della chiave privata.
pgp-source-own = Creata in Inbox Classic
pgp-source-file = Importata da un file
pgp-source-paste = Incollata
pgp-source-attachment = Da un messaggio
pgp-source-vcard = Da una scheda contatto
pgp-source-wkd = Dal provider di posta del mittente
pgp-source-keyserver = Da keys.openpgp.org
pgp-source-autocrypt = Dall’intestazione Autocrypt di un messaggio
pgp-error-no-store = { $store } non è disponibile per proteggere le chiavi private: { $error }
pgp-error-wrong-passphrase = La passphrase non è corretta.
pgp-error-not-a-key = Questa non è una chiave OpenPGP.
pgp-error-too-large = La chiave è troppo grande.
pgp-error-unusable = La chiave non è utilizzabile per l’operazione richiesta. Potrebbe mancare una chiave adatta alla firma o alla crittografia, oppure un algoritmo potrebbe non essere supportato.
pgp-imported-private = { $count ->
    [one] La tua chiave privata è stata importata.
   *[other] Sono state importate { $count } chiavi private.
}
pgp-imported-public = { $count ->
    [one] È stata importata una chiave.
   *[other] Sono state importate { $count } chiavi.
}
pgp-imported-pending = Per questi indirizzi è già in uso un’altra chiave: { $addresses }. La nuova chiave è disponibile nelle proprietà del contatto, ma verrà usata solo quando la selezioni.
pgp-error-needs-passphrase = La chiave privata è protetta da una passphrase. Inseriscila per importare la chiave.
pgp-error-mismatch = La chiave privata non corrisponde alla chiave pubblica. Potrebbe essere stata alterata.
pgp-file-name-public = Chiave pubblica di { $who }.asc
pgp-file-name-private = Backup della chiave privata di { $who }.asc
pgp-pending = Il { $date } è stata trovata una chiave diversa per { $address }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Firmato digitalmente da { $signer } (proprietario della chiave verificato)
pgp-part-signed = Firmato digitalmente da { $signer } (proprietario della chiave non verificato)
pgp-part-other = Firmato da { $signer }; non è stato possibile associare con certezza la firma al mittente
pgp-part-unknown-key = Firmato, ma la chiave non è nota
pgp-part-not-signed = Non firmato
pgp-part-not-checked = Firma non verificata
pgp-part-encrypted = Crittografato. { $signature }
pgp-part-no-key = Messaggio crittografato; manca una chiave privata corrispondente
pgp-part-changed = La verifica dell’integrità del contenuto crittografato non è riuscita. Il contenuto non viene mostrato
pgp-part-unprotected = Crittografato senza protezione contro le modifiche, non mostrato
pgp-part-broken = La parte crittografata non può essere letta
pgp-why-mismatch = La firma digitale non corrisponde a questo testo
pgp-why-weak-hash = La firma usa { $hash }, che non è più sicuro
pgp-why-key-expired = La firma è successiva alla scadenza della chiave ({ $date })
pgp-why-key-revoked = Firmato con una chiave revocata
pgp-why-not-signing-key = Firmato con una chiave non utilizzabile per la firma
pgp-why-from-future = La firma ha una data nel futuro
pgp-why-signature-expired = La firma è scaduta
pgp-why-key-not-valid = Firmato con una chiave non valida
pgp-why-not-for-you = Firmato per altri destinatari e successivamente inoltrato a te
pgp-why-not-key-in-use = Firmato con una chiave diversa da quella in uso per { $address }
pgp-part-pictures-loaded = { $label }. Le immagini sono state caricate da internet
pgp-error-no-own-key = Non hai una chiave per { $address } con cui firmare o crittografare. Creane una in Chiavi di crittografia oppure disattiva la firma digitale e la crittografia.
pgp-error-missing-keys = { $count ->
    [one] Non è disponibile una chiave di crittografia utilizzabile per { $addresses }.
   *[other] Non sono disponibili chiavi di crittografia utilizzabili per questi destinatari: { $addresses }.
}
pgp-error-encrypted-quote = Questo messaggio contiene testo, immagini o allegati provenienti da un messaggio crittografato e può essere inviato solo crittografato. Attiva Crittografa oppure rimuovi quel contenuto.
pgp-error-protect = Impossibile firmare o crittografare il messaggio: { $reason }
pgp-found-keys = Chiavi trovate per: { $addresses }.
pgp-found-none = Nessuna chiave trovata per: { $addresses }. Richiedi le chiavi pubbliche necessarie.
pgp-found-no-key = Nessuna chiave trovata.
pgp-find-unavailable = Al momento non è possibile cercare le chiavi: { $error }
pgp-publish-pending = La chiave è stata inviata a keys.openpgp.org e sono stati richiesti link di conferma per: { $addresses }. Apri il link per ogni indirizzo ancora da confermare, così gli altri potranno trovare la chiave tramite quell’indirizzo.
pgp-publish-done = La chiave è stata inviata a keys.openpgp.org per gli indirizzi: { $addresses }.
pgp-publish-failed = Impossibile pubblicare la chiave: { $error }
pgp-keyserver-off = La ricerca delle chiavi su keys.openpgp.org è disattivata in { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Il messaggio verrà crittografato e firmato all’invio. Solo tu e { $addresses } potrete leggerne il contenuto.
   *[other] Il messaggio verrà crittografato e firmato all’invio. Solo tu e i suoi { $count } destinatari potrete leggerne il contenuto.
}
pgp-compose-encrypt-ready = Il messaggio verrà crittografato e firmato all’invio. Aggiungi destinatari di cui hai una chiave utilizzabile.
pgp-compose-missing = { $count ->
    [one] Non c’è una chiave utilizzabile per questo destinatario: { $addresses }. Il messaggio non può ancora essere crittografato.
   *[other] Mancano chiavi utilizzabili per { $count } destinatari: { $addresses }. Il messaggio non può ancora essere crittografato.
}
pgp-compose-looking = Ricerca delle chiavi di { $addresses }...
pgp-compose-signed = Il messaggio verrà firmato digitalmente all’invio. I destinatari potranno verificare la firma e l’integrità del contenuto.
pgp-compose-reply-clear = Non crittografato, anche se il messaggio originale lo era.
pgp-compose-encrypted-files = Questo messaggio contiene allegati provenienti da un messaggio crittografato e può quindi essere inviato solo crittografato. Attiva “Crittografa” o rimuovi quegli allegati.
pgp-compose-sign-tip = Firma digitalmente il messaggio all’invio, così i destinatari possono verificare la firma e l’integrità del contenuto
pgp-compose-sign-tip-encrypted = I messaggi crittografati vengono sempre firmati all’invio
pgp-compose-encrypt-tip = Crittografa il contenuto del messaggio all’invio, così solo tu e i destinatari potete leggerlo
pgp-compose-make-key = Non è ancora configurata una chiave per l’indirizzo { $address }. Vuoi crearne una adesso? Ti permetterà di firmare e crittografare i messaggi.
pgp-compose-key-unusable = La tua chiave per { $address } non è utilizzabile. Motivo: { $state }
    Apri “Chiavi di crittografia” per importare un backup di questa chiave o crearne una nuova.
pgp-compose-encrypt-off-quote = Il messaggio contiene ancora testo, immagini o allegati provenienti da un messaggio crittografato. Rimuovili prima di inviarlo senza crittografia. Vuoi comunque disattivare la crittografia?
pgp-compose-encrypt-off-reply = Il messaggio originale era crittografato. Se invii la risposta o il messaggio inoltrato senza crittografia, i server di posta che lo gestiscono potranno leggerne il contenuto. Vuoi disattivare la crittografia?
pgp-recipient-verified = Chiave verificata
pgp-recipient-found = Chiave non verificata
pgp-recipient-own = La tua chiave
pgp-recipient-looking = Ricerca di una chiave...
pgp-recipient-missing = Nessuna chiave
pgp-recipient-not-found = Nessuna chiave trovata. Ultima ricerca: { $date }
pgp-recipient-unusable = Chiave non utilizzabile: { $state }
pgp-recipients-intro = Inbox Classic userà le chiavi dei destinatari e la tua per crittografare il messaggio.
pgp-recipients-intro-missing = { $count ->
    [one] Manca una chiave utilizzabile per un destinatario. Cerca la sua chiave o rimuovi il destinatario dal messaggio. Puoi inviare il messaggio senza crittografia solo se non contiene più testo, immagini o allegati provenienti da messaggi crittografati.
   *[other] Mancano chiavi utilizzabili per { $count } destinatari. Cerca le loro chiavi o rimuovi quei destinatari dal messaggio. Puoi inviare il messaggio senza crittografia solo se non contiene più testo, immagini o allegati provenienti da messaggi crittografati.
}
pgp-details-part = Parte { $number }: { $label }
attachment-from-part = Dalla parte { $number }: { $label }
pgp-details-signed = Firmato il { $when } con la chiave { $key }
pgp-details-unknown-key = Firmato con la chiave { $key }, che non hai
pgp-details-opened = Decrittografato con la tua chiave { $key }
pgp-details-for = Crittografato per { $keys }
pgp-details-plain = Non firmato e non crittografato
pgp-bar-parts = Questo messaggio ha { $count } parti: { $list }. Ogni parte indica come è protetta.
pgp-bar-count-verified = { $count ->
    [one] { $count } verificata
   *[other] { $count } verificate
}
pgp-bar-count-encrypted-signed = { $count ->
    [one] 1 crittografata e firmata
   *[other] { $count } crittografate e firmate
}
pgp-bar-count-encrypted = { $count ->
    [one] 1 crittografata
   *[other] { $count } crittografate
}
pgp-bar-count-signed = { $count ->
    [one] 1 firmata
   *[other] { $count } firmate
}
pgp-bar-count-warning = { $count ->
    [one] 1 richiede attenzione
   *[other] { $count } richiedono attenzione
}
pgp-bar-count-neutral = { $count } senza una firma confermata
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Impostazioni
setup-part-preferences = Preferenze delle finestre
setup-part-accounts = Account
setup-part-sign-in-apps = App di accesso
setup-part-contacts = Contatti e gruppi
setup-part-keys = Chiavi di crittografia
setup-part-rules = Regole per i messaggi
setup-part-trusted-senders = Mittenti attendibili
setup-holds-settings = { $count ->
    [one] 1 impostazione
   *[other] { $count } impostazioni
}
setup-holds-preferences = { $count ->
    [one] 1 preferenza
   *[other] { $count } preferenze
}
setup-holds-accounts = { $count ->
    [one] 1 account
   *[other] { $count } account
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 app di accesso
   *[other] { $count } app di accesso
}
setup-holds-built-in = Quali app di accesso integrate sono attive
setup-holds-contacts = { $count ->
    [one] 1 contatto
   *[other] { $count } contatti
}
setup-holds-groups = { $count ->
    [one] 1 gruppo
   *[other] { $count } gruppi
}
setup-holds-own-keys = { $count ->
    [one] 1 chiave personale
   *[other] { $count } chiavi personali
}
setup-holds-contact-keys = { $count ->
    [one] 1 chiave di un contatto
   *[other] { $count } chiavi di contatti
}
setup-holds-rules = { $count ->
    [one] 1 regola
   *[other] { $count } regole
}
setup-holds-trusted-senders = { $count ->
    [one] 1 mittente attendibile
   *[other] { $count } mittenti attendibili
}
setup-sign-in-password = Password
setup-account-secret-password = La sua password è nel file.
setup-account-secret-token = Le credenziali di accesso sono incluse nel file.
setup-account-asks-password = Dopo l’importazione verrà richiesta la password dell’account.
setup-account-signs-in-again = Dovrai accedere di nuovo dopo l’importazione.
setup-account-here = L’account è già configurato su questo computer e verrà ignorato.
setup-account-no-app = L’account usa l’app di accesso { $app }, che non è configurata su questo computer. Importa anche le app di accesso.
setup-invalid-address = “{ $address }” non è un indirizzo e-mail.
setup-invalid-server = Il nome, la porta o le impostazioni di sicurezza del server { $server } non sono validi.
setup-invalid-user = Manca il nome utente.
setup-invalid-sign-in = Le impostazioni di accesso dell’account non sono valide.
setup-error-empty = Il file è vuoto.
setup-error-too-large = Il file supera il limite di dimensione per l’importazione di impostazioni e account.
setup-error-not-setup = Questo file non è una configurazione di Inbox Classic.
setup-error-damaged = Il file di configurazione è danneggiato e non può essere letto.
setup-error-newer = Questa configurazione è stata salvata da una versione più recente di Inbox Classic ({ $version }). Aggiorna Inbox Classic, poi importala di nuovo.
setup-error-needs-passphrase = Questa configurazione è protetta da una passphrase. Inserisci la passphrase con cui è stata salvata.
setup-error-wrong-passphrase = Non è la passphrase con cui è stata salvata questa configurazione.
setup-error-changed = La verifica dell’integrità del file di configurazione non è riuscita, quindi il file non può essere importato.
setup-error-read = Impossibile leggere il file di configurazione: { $error }
setup-error-write = Impossibile salvare la configurazione: { $error }
setup-error-no-parts = Scegli almeno un elemento da importare o esportare.
setup-left-out = { $count ->
    [one] 1 voce di { $part } non può essere usata e viene esclusa.
   *[other] { $count } voci di { $part } non possono essere usate e vengono escluse.
}
setup-imported-settings = Le impostazioni sono state sostituite.
setup-imported-preferences = Le preferenze delle finestre sono state sostituite.
setup-added-accounts = { $count ->
    [one] Aggiunto 1 account.
   *[other] Aggiunti { $count } account.
}
setup-skipped-here = { $address } è già configurato qui, quindi è stato saltato.
setup-skipped-no-app = { $address } è stato saltato: accede con { $app }, che qui non è configurata.
setup-skipped-invalid = { $address } è stato saltato: { $reason }
setup-asks-password = Alla prossima connessione verrà richiesta la password per { $address }.
setup-signs-in-again = Alla prossima connessione dovrai accedere di nuovo a { $address }.
setup-added-sign-in-apps = { $count ->
    [one] Aggiunta 1 app di accesso.
   *[other] Aggiunte { $count } app di accesso.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 app di accesso è già configurata qui.
   *[other] { $count } app di accesso sono già configurate qui.
}
setup-added-contacts = { $count ->
    [one] Aggiunto 1 contatto alla rubrica.
   *[other] Aggiunti { $count } contatti alla rubrica.
}
setup-skipped-contacts = { $count ->
    [one] 1 contatto è già nella rubrica.
   *[other] { $count } contatti sono già nella rubrica.
}
setup-added-groups = { $count ->
    [one] Aggiunto o completato 1 gruppo.
   *[other] Aggiunti o completati { $count } gruppi.
}
setup-added-own-keys = { $count ->
    [one] Aggiunta 1 chiave personale.
   *[other] Aggiunte { $count } chiavi personali.
}
setup-added-contact-keys = { $count ->
    [one] Aggiunta 1 chiave di un contatto.
   *[other] Aggiunte { $count } chiavi di contatti.
}
setup-added-rules = { $count ->
    [one] Aggiunta 1 regola per i messaggi.
   *[other] Aggiunte { $count } regole per i messaggi.
}
setup-skipped-rules = { $count ->
    [one] 1 regola per i messaggi è già presente.
   *[other] { $count } regole per i messaggi sono già presenti.
}
setup-skipped-rules-account = { $count ->
    [one] Ignorata 1 regola per i messaggi perché il relativo account non è configurato su questo computer.
   *[other] Ignorate { $count } regole per i messaggi perché i relativi account non sono configurati su questo computer.
}
setup-rules-waiting = { $count ->
    [one] Dopo la sincronizzazione, l’app cercherà la cartella di destinazione di 1 regola per i messaggi.
   *[other] Dopo la sincronizzazione, l’app cercherà le cartelle di destinazione di { $count } regole per i messaggi.
}
setup-added-trusted-senders = { $count ->
    [one] Aggiunto 1 mittente attendibile.
   *[other] Aggiunti { $count } mittenti attendibili.
}
setup-nothing = Non è stato importato niente.
setup-account-servers = { $imap } e { $smtp } ({ $signin })
setup-file-name = Impostazioni e account di Inbox Classic
setup-skipped-unreachable = Voce ignorata: { $name }. Non è stato possibile verificare il servizio di accesso. Controlla l’app necessaria in App di accesso e riprova.
attachment-runs-programs = “{ $name }” può eseguire programmi, quindi Inbox Classic non lo apre. Salvalo, poi aprilo tu stesso se ti fidi della sua provenienza.
attachment-decrypted-note = Questo allegato proviene da un messaggio crittografato. Per aprirlo, Inbox Classic salva una copia in chiaro in una cartella temporanea del tuo account utente. La copia può restare sul disco dopo la chiusura del file. All’avvio, l’app tenta di eliminare le copie più vecchie di un giorno.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Il server non ha spostato { $messages } in { $folder }, quindi è di nuovo in { $from }: { $reason }
   *[other] Il server non ha spostato { $messages } in { $folder }, quindi sono di nuovo in { $from }: { $reason }
}
undone-delete = { $count ->
    [one] Il server non ha eliminato { $messages }, quindi è di nuovo in { $from }: { $reason }
   *[other] Il server non ha eliminato { $messages }, quindi sono di nuovo in { $from }: { $reason }
}
undone-archive = { $count ->
    [one] Il server non ha archiviato { $messages }, quindi è di nuovo in { $from }: { $reason }
   *[other] Il server non ha archiviato { $messages }, quindi sono di nuovo in { $from }: { $reason }
}
undone-read = { $count ->
    [one] Il server non ha segnato { $messages } come letto, quindi è di nuovo da leggere: { $reason }
   *[other] Il server non ha segnato { $messages } come letti, quindi sono di nuovo da leggere: { $reason }
}
undone-unread = { $count ->
    [one] Il server non ha segnato { $messages } come da leggere, quindi risulta di nuovo letto: { $reason }
   *[other] Il server non ha segnato { $messages } come da leggere, quindi risultano di nuovo letti: { $reason }
}
undone-flags = { $count ->
    [one] Il server non ha cambiato i contrassegni di { $messages }, quindi la modifica è stata annullata: { $reason }
   *[other] Il server non ha cambiato i contrassegni di { $messages }, quindi la modifica è stata annullata: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

preview-pdf-option = Mostra i file PDF nei messaggi
preview-pdf-off = I file PDF non vengono mostrati nei messaggi.
preview-pdf-off-crashed = Inbox Classic si è interrotto durante l’anteprima di un file in un messaggio. Le anteprime PDF sono quindi disattivate, mentre le immagini restano visibili. Per mostrare di nuovo i PDF, attiva { $option } in { $settings }.
preview-pdf-details = { $count ->
    [one] 1 pagina, { $size }
   *[other] { $count } pagine, { $size }
}
preview-page-alt = { $name }, pagina { $page } di { $count }
preview-more-pages = { $count ->
    [one] Apri il file per vedere la pagina
   *[other] Apri il file per vedere tutte le { $count } pagine
}
preview-more-files = { $count ->
    [one] 1 altro file è nell’elenco qui sopra
   *[other] Altri { $count } file sono nell’elenco qui sopra
}
preview-tile-downloading = Download in corso…
preview-tile-preparing = Preparazione in corso…
preview-tile-format = Le immagini in formato { $format } non sono ancora supportate
preview-tile-password = Protetto da password: aprilo per inserire la password
preview-tile-too-large = Troppo grande per essere mostrato
preview-tile-unreadable = Impossibile mostrarlo
preview-tile-timed-out = La preparazione dell’anteprima ha richiesto troppo tempo
preview-tile-crashed = Anteprima non disponibile: in precedenza Inbox Classic si è chiuso o ha smesso di rispondere durante la visualizzazione
preview-tile-off = Non mostrato fino al prossimo avvio di Inbox Classic
preview-not-printed = { $name } ({ $details }) non viene stampato. Aprilo per stamparlo.
