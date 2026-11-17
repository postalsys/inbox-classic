# Deutsch. Entwurf, wartet auf die Durchsicht durch Muttersprachler (siehe core/locales/GLOSSARY.md).

## Counts and sizes

messages = { $count ->
    [one] 1 Nachricht
   *[other] { $count } Nachrichten
}
decimal-separator = ,
size-bytes = { $count ->
    [one] 1 Byte
   *[other] { $count } Bytes
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Aus
send-delay-seconds = { $count ->
    [one] 1 Sekunde
   *[other] { $count } Sekunden
}
list-counts = { $messages }, { $unread } ungelesen
list-counts-selected = { $messages }, { $unread } ungelesen, { $selected } ausgewählt
list-counts-found = { $found } gefunden, { $unread } ungelesen
list-counts-found-selected = { $found } gefunden, { $unread } ungelesen, { $selected } ausgewählt
list-counts-none = Keine Nachrichten gefunden

## Special folders

folder-inbox = Posteingang
folder-sent = Gesendete Objekte
folder-deleted = Gelöschte Objekte
folder-drafts = Entwürfe
folder-junk = Junk-E-Mail
folder-archive = Archiv

## The reading pane

reader-no-message = Es ist keine Nachricht ausgewählt.
reader-downloading = Die Nachricht wird heruntergeladen…
reader-downloading-detail = Die Nachricht wird angezeigt, sobald der Download abgeschlossen ist.
reader-downloading-size = Die Nachricht ist { $size } groß. Sie erscheint hier, sobald sie heruntergeladen ist.
reader-failed = Die Nachricht konnte nicht heruntergeladen werden
reader-failed-network = Der Mailserver war nicht erreichbar ({ $reason }).
reader-failed-sign-in = Der Mailserver hat die Anmeldung nicht angenommen ({ $reason }). Prüfen Sie das Passwort oder melden Sie sich unter Datei > Konten erneut an.
reader-failed-security = Es konnte keine sichere Verbindung zum Mailserver hergestellt werden ({ $reason }).
reader-failed-other = Der Mailserver antwortete: { $reason }.
reader-retry-note = Der Download wird erneut versucht, sobald die Verbindung zum Konto wiederhergestellt ist.
reader-unreadable = Diese Nachricht kann nicht angezeigt werden: { $error }
message-source-title = Nachrichtenquelltext: { $subject }
message-source-untitled = Nachrichten-Quelltext

## Printing and quoting

header-from = Von
header-date = Datum
header-to = An
header-cc = Cc
header-sent = Gesendet
header-subject = Betreff
# review: new
header-security = Sicherheit
# review: new
header-part = Teil { $number }
quote-original = ----- Ursprüngliche Nachricht -----
fold-show-earlier = Frühere Nachrichten anzeigen

## Unzustellbarkeitsberichte: die Karte über einer Nachricht, die nicht zugestellt wurde

bounce-failed = Ihre Nachricht wurde nicht zugestellt
bounce-delayed = Ihre Nachricht wurde noch nicht zugestellt
bounce-delayed-note = Ihr Mailserver versucht weiterhin, sie zuzustellen. Sie müssen sie nicht erneut senden.
bounce-show-message = Nachricht anzeigen, die nicht zugestellt wurde
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Noch nicht zugestellte Nachricht anzeigen
bounce-what-to-do = Was Sie tun können:
bounce-delayed-do = Sie müssen vorerst nichts tun. Falls die Nachricht nicht zugestellt werden kann, erhalten Sie eine weitere Benachrichtigung.
bounce-delayed-row-do = Sie müssen vorerst nichts tun. Ihr Mailserver versucht weiterhin, die Nachricht zuzustellen. Falls das nicht gelingt, erhalten Sie eine weitere Benachrichtigung.
bounce-details = Details
bounce-someone = Ein Empfänger
bounce-server = Server: { $server }
bounce-status = Status: { $status }
bounce-reported-by = Gemeldet von: { $server }
bounce-retry-minutes = Der empfangende Server bittet, { $count ->
    [one] eine Minute
   *[other] { $count } Minuten
} bis zum nächsten Versuch zu warten.
bounce-retry-hours = Der empfangende Server bittet, { $count ->
    [one] eine Stunde
   *[other] { $count } Stunden
} bis zum nächsten Versuch zu warten.
bounce-blocklist = Sperrliste: { $lists }
bounce-user-unknown = Die Adresse existiert nicht
bounce-user-unknown-why = Auf dem empfangenden Server gibt es kein Postfach mit dieser Adresse. Möglicherweise enthält die Adresse einen Tippfehler oder wird vom Empfänger nicht mehr verwendet.
bounce-user-unknown-do = Prüfen Sie die Schreibweise der Adresse oder fragen Sie den Empfänger nach seiner aktuellen E-Mail-Adresse.
bounce-invalid-address = Die Adresse ist ungültig
bounce-invalid-address-why = Das Format der Adresse ist ungültig. An diese Adresse können keine E-Mails gesendet werden.
bounce-invalid-address-do = Prüfen Sie die Adresse auf Tippfehler, etwa überflüssige Leerzeichen, fehlende Buchstaben oder einen fehlenden Domainnamen nach dem @-Zeichen.
bounce-mailbox-disabled = Das Postfach ist deaktiviert
bounce-mailbox-disabled-why = Die Adresse existiert, aber ihr Postfach wurde abgeschaltet oder wird nicht mehr verwendet.
bounce-mailbox-disabled-do = Kontaktieren Sie den Empfänger auf anderem Weg und fragen Sie nach seiner aktuellen E-Mail-Adresse.
bounce-mailbox-full = Das Postfach ist voll
bounce-mailbox-full-why = Im Postfach des Empfängers ist kein Platz für neue E-Mails.
bounce-mailbox-full-do = Senden Sie die Nachricht in ein paar Tagen erneut oder benachrichtigen Sie den Empfänger auf anderem Weg. Nachrichten mit großen Anlagen werden zuerst abgelehnt.
bounce-spam-blocked = Als Spam abgelehnt
bounce-spam-blocked-why = Der empfangende Server hat die Nachricht für Spam gehalten.
bounce-spam-blocked-do = Entfernen Sie Inhalte, die als Spam eingestuft werden könnten, etwa zahlreiche oder gekürzte Links oder große Anlagen. Senden Sie die Nachricht dann erneut. Wenn das Problem weiterhin auftritt, wenden Sie sich an Ihren E-Mail-Anbieter.
bounce-virus-detected = Wegen eines Virus abgelehnt
bounce-virus-detected-why = Der empfangende Server hat in der Nachricht oder ihren Anlagen einen Virus oder andere schädliche Inhalte gefunden.
bounce-virus-detected-do = Prüfen Sie die Anlagen mit einem Virenscanner. Manche Server lehnen jedes Programm und jedes Archiv ab; teilen Sie solche Dateien stattdessen als Link.
bounce-ip-blocklisted = Ihr Mailserver steht auf einer Sperrliste
bounce-ip-blocklisted-why = Der empfangende Server lehnt Nachrichten von Ihrem Mailserver ab, weil dessen IP-Adresse auf einer Sperrliste steht.
bounce-ip-blocklisted-do = Es liegt nicht an der Nachricht. Leiten Sie diesen Bericht an Ihren E-Mail-Anbieter weiter, und bitten Sie ihn, den Server von der Liste entfernen zu lassen.
bounce-domain-blocklisted = Eine Domain steht auf einer Sperrliste
bounce-domain-blocklisted-why = Der empfangende Server lehnt die Nachricht ab, weil die Domain Ihrer Adresse oder eine Domain in den Links der Nachricht auf einer Sperrliste steht.
bounce-domain-blocklisted-do = Wenn die Nachricht Links enthält, versuchen Sie es ohne diese Links. Falls das nicht hilft oder keine Links enthalten sind, leiten Sie diesen Bericht an den E-Mail-Administrator Ihrer Domain weiter.
bounce-policy-blocked = Aufgrund der Regeln des empfangenden Servers abgelehnt
bounce-policy-blocked-why = Die Regeln des empfangenden Servers lassen diese Nachricht nicht durch, zum Beispiel wegen ihrer Größe, ihrer Anlagen oder ihres Absenders.
bounce-policy-blocked-do = Die Serverantwort unter „Details“ nennt häufig den Grund. Fragen Sie den Empfänger, ob er solche Nachrichten empfangen kann.
bounce-geo-blocked = Wegen der Herkunft abgelehnt
bounce-geo-blocked-why = Der empfangende Server nimmt keine E-Mail aus dem Land oder Netz an, in dem Ihr Mailserver steht.
bounce-geo-blocked-do = Kontaktieren Sie den Empfänger auf anderem Weg oder wenden Sie sich an Ihren E-Mail-Anbieter.
bounce-relay-denied = Der Server hat die Weiterleitung abgelehnt
bounce-relay-denied-why = Ein Server hat die Zustellung abgelehnt, oft weil ohne Anmeldung gesendet wurde oder über einen Server, der für diesen Empfänger nicht zuständig ist.
bounce-relay-denied-do = Prüfen Sie unter Datei > Konten die Einstellungen des Postausgangsservers und ob die Anmeldung am Server eingerichtet ist.
bounce-auth-failure = Ihre Absenderadresse konnte nicht bestätigt werden
bounce-auth-failure-why = Der empfangende Server konnte nicht bestätigen, dass die Nachricht wirklich von Ihrer Domain kommt (SPF, DKIM oder DMARC).
bounce-auth-failure-do = Leiten Sie diesen Bericht an den E-Mail-Administrator Ihrer Domain weiter, damit er die Domain-Einstellungen korrigieren kann. Bis dahin kann es helfen, über den Server Ihres Anbieters zu senden.
bounce-rate-limited = Zu viele Nachrichten auf einmal
bounce-rate-limited-why = Der empfangende Server begrenzt derzeit die Anzahl der Nachrichten, die er von Ihrem Mailserver annimmt.
bounce-rate-limited-do = Warten Sie eine Weile und senden Sie die Nachricht erneut. Wenn Sie an viele Personen schreiben, senden Sie jeweils an weniger Empfänger gleichzeitig.
bounce-greylisting = Zustellung vorübergehend zurückgestellt
bounce-greylisting-why = Der empfangende Server bittet unbekannte Absender, es etwas später erneut zu versuchen. Das ist eine übliche Maßnahme zum Schutz vor Spam.
bounce-greylisting-do = Sie müssen nichts tun. Mailserver versuchen die Zustellung automatisch erneut. Meist wird die Nachricht innerhalb einer Stunde zugestellt.
bounce-server-error = Der empfangende Server hatte ein Problem
bounce-server-error-why = Der empfangende Server war nicht erreichbar oder konnte die Nachricht wegen eines eigenen Problems nicht annehmen.
bounce-server-error-do = Senden Sie die Nachricht später erneut. Wenn das Problem weiterhin auftritt, prüfen Sie den Teil der Adresse nach dem @-Zeichen auf Tippfehler.
bounce-unknown = Nicht zugestellt
bounce-unknown-why = Der Bericht enthält keinen eindeutigen Grund für die fehlgeschlagene Zustellung.
bounce-unknown-do = Die Serverantwort unter „Details“ enthält möglicherweise weitere Informationen. Wenn diese nicht helfen, leiten Sie den Bericht an Ihren E-Mail-Anbieter weiter.

## Several messages selected

selection-title = { $count ->
    [one] 1 Nachricht ausgewählt
   *[other] { $count } Nachrichten ausgewählt
}
selection-unread = { $count } ungelesen
selection-flagged = { $count } gekennzeichnet
delete-for-good-one = Diese Nachricht wird endgültig gelöscht. Löschen?
delete-for-good-all = Diese { $count } Nachrichten werden endgültig gelöscht. Löschen?
delete-for-good-some = { $count } der { $total } Nachrichten werden endgültig gelöscht. Die Nachrichten löschen?
done-read = { $count ->
    [one] { $messages } als gelesen markiert
   *[other] { $messages } als gelesen markiert
}
done-unread = { $count ->
    [one] { $messages } als ungelesen markiert
   *[other] { $messages } als ungelesen markiert
}
done-flagged = { $count ->
    [one] { $messages } gekennzeichnet
   *[other] { $messages } gekennzeichnet
}
done-unflagged = Kennzeichnung entfernt: { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } endgültig gelöscht
   *[other] { $messages } endgültig gelöscht
}
done-archived = { $count ->
    [one] { $messages } archiviert
   *[other] { $messages } archiviert
}
done-moved = { $count ->
    [one] { $messages } in { $folder } verschoben
   *[other] { $messages } in { $folder } verschoben
}
done-copied = { $count ->
    [one] { $messages } in { $folder } kopiert
   *[other] { $messages } in { $folder } kopiert
}
done-moving = { $count ->
    [one] { $messages } wird in { $folder } verschoben...
   *[other] { $messages } werden in { $folder } verschoben...
}
done-copying = { $count ->
    [one] { $messages } wird in { $folder } kopiert...
   *[other] { $messages } werden in { $folder } kopiert...
}
done-moved-back = { $count ->
    [one] { $messages } zurück in { $folder } verschoben
   *[other] { $messages } zurück in { $folder } verschoben
}
done-watched = { $count ->
    [one] Unterhaltung wird beobachtet
   *[other] { $count } Unterhaltungen werden beobachtet
}
done-unwatched = { $count ->
    [one] Unterhaltung wird nicht mehr beobachtet
   *[other] { $count } Unterhaltungen werden nicht mehr beobachtet
}
done-ignored = { $count ->
    [one] Unterhaltung wird ignoriert
   *[other] { $count } Unterhaltungen werden ignoriert
}
done-unignored = { $count ->
    [one] Unterhaltung wird nicht mehr ignoriert
   *[other] { $count } Unterhaltungen werden nicht mehr ignoriert
}
their-folders = die jeweiligen Ordner
undo-move = Verschieben rückgängig machen
undo-delete = Löschen rückgängig machen
undo-archive = Archivieren rückgängig machen
undo-junk = Als Junk markieren rückgängig machen
undo-not-junk = Als Nicht-Junk markieren rückgängig machen
undo-send = Senden rückgängig machen
nothing-to-undo = Es gibt nichts rückgängig zu machen.
messages-gone = Die Nachrichten sind nicht mehr da.
folder-holds-no-messages = In diesem Ordner können keine Nachrichten gespeichert werden.
not-archived-here = Nachrichten in diesem Ordner können nicht archiviert werden.
not-emptied-here = Nur Gelöschte Objekte und Junk-E-Mail können geleert werden.
next-unread-question = In { $folder } gibt es keine ungelesenen Nachrichten mehr.

    Zu { $next } wechseln, dem nächsten Ordner mit ungelesenen Nachrichten?
no-unread-left = Es gibt keine ungelesenen Nachrichten mehr.
empty-question = { $count ->
    [one] { $folder } leeren?

        Die Nachricht darin wird endgültig gelöscht. Sie kann nicht wiederhergestellt werden.
   *[other] { $folder } leeren?

        Die { $messages } darin werden endgültig gelöscht. Sie können nicht wiederhergestellt werden.
}
no-junk-folder = Dieses Konto hat keinen Junk-E-Mail-Ordner, in den die Nachrichten verschoben werden könnten.
no-inbox-folder = Dieses Konto hat keinen Posteingang, in den die Nachrichten verschoben werden könnten.
done-flagged-color = { $messages } { $color ->
    [red] rot
    [orange] orange
    [yellow] gelb
    [green] grün
    [blue] blau
    [purple] lila
   *[gray] grau
} gekennzeichnet
flag-color = { $color ->
    [red] Rot
    [orange] Orange
    [yellow] Gelb
    [green] Grün
    [blue] Blau
    [purple] Lila
   *[gray] Grau
}

## Das Fenster Verschieben und Kopieren

move-window-title-move = { $count ->
    [one] Nachricht verschieben
   *[other] { $count } Nachrichten verschieben
}
move-window-title-copy = { $count ->
    [one] Nachricht kopieren
   *[other] { $count } Nachrichten kopieren
}
move-window-prompt-move = { $count ->
    [one] Die ausgewählte Nachricht verschieben nach:
   *[other] Die { $count } ausgewählten Nachrichten verschieben nach:
}
move-window-prompt-copy = { $count ->
    [one] Die ausgewählte Nachricht kopieren nach:
   *[other] Die { $count } ausgewählten Nachrichten kopieren nach:
}
targets-recent = Zuletzt verwendet
target-current = { $folder } (aktuell)
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Verschieben in { $folder }: { $done } von insgesamt { $messages }...
transfer-copying = Kopieren in { $folder }: { $done } von insgesamt { $messages }...
transfer-another-account = ein anderes Konto
transfer-folder-gone = der Zielordner ist nicht mehr vorhanden
transfer-not-on-server = die Nachricht ist nicht mehr auf dem Server
transfer-not-moved = { $count ->
    [one] { $messages } konnte nicht in ein anderes Konto verschoben werden: { $reason }
   *[other] { $messages } konnten nicht in ein anderes Konto verschoben werden: { $reason }
}
transfer-not-copied = { $count ->
    [one] { $messages } konnte nicht in ein anderes Konto kopiert werden: { $reason }
   *[other] { $messages } konnten nicht in ein anderes Konto kopiert werden: { $reason }
}
transfer-none-moved = Keine Nachricht konnte verschoben werden
transfer-none-copied = Keine Nachricht konnte kopiert werden

## Messages as files

export-not-in-time = die Nachricht konnte nicht rechtzeitig heruntergeladen werden
export-not-saved = { $failed ->
    [one] { $failed } von { $messages } konnte nicht gespeichert werden ({ $problems })
   *[other] { $failed } von { $messages } konnten nicht gespeichert werden ({ $problems })
}
export-not-attached = die Nachrichten konnten nicht angehängt werden: { $error }
saved-to = { $count ->
    [one] { $messages } in { $folder } gespeichert
   *[other] { $messages } in { $folder } gespeichert
}
download-progress = { $done } von { $total } heruntergeladen
download-done = { $size } heruntergeladen
downloading-messages = { $count ->
    [one] { $messages } wird heruntergeladen...
   *[other] { $messages } werden heruntergeladen...
}
import-put = { $count ->
    [one] { $messages } in { $folder } abgelegt
   *[other] { $messages } in { $folder } abgelegt
}
import-not-put = Folgende Nachrichten konnten nicht importiert werden:

    { $problems }

## Problems the windows show

error-store = lokaler Speicher: { $error }
error-not-found = nicht gefunden
error-closed = wird beendet
error-other-account = der Browser hat sich bei { $email } angemeldet, nicht bei diesem Konto
# a password or sign-in the mail server refused, with the server's words
failure-authentication = der Server hat die Anmeldung nicht angenommen ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = die Verbindung zum Server ist fehlgeschlagen ({ $reason })
error-in-use = die App kann nicht entfernt werden, da folgende Konten sie verwenden: { $accounts }
error-turned-off = diese Anmelde-App ist für neue Konten ausgeschaltet
error-folder-name = der Ordnername muss 1 bis 200 Zeichen lang sein und darf keine Steuerzeichen enthalten
error-folder-separator = ein Ordnername darf auf diesem Server kein „{ $separator }“ enthalten
error-folder-special = der Posteingang und die Spezialordner können nicht umbenannt oder gelöscht werden
error-no-recipients = die Nachricht hat keine Empfänger
error-bad-address = „{ $address }“ ist keine E-Mail-Adresse
error-not-own-address = { $address } gehört nicht zu den Absenderadressen dieses Kontos. Fügen Sie die Adresse in den Kontoeigenschaften unter „Weitere Absenderadressen“ hinzu.
rule-query-refused = Regeln unterstützen keine Ordner- oder Datumsfilter ({ $words }).
rule-no-query = Geben Sie Suchkriterien für eingehende Nachrichten ein.
rule-no-action = Wählen Sie mindestens eine Aktion für die Regel aus.
error-attachment = { $path } konnte nicht gelesen werden: { $error }
error-no-drafts = das Konto hat keinen Entwürfe-Ordner, in dem die Nachricht gespeichert werden kann
error-draft-attachment = eine Anlage des Entwurfs konnte nicht übernommen werden: { $error }
error-password-not-saved = das Passwort konnte für den nächsten Start nicht gespeichert werden: { $error }
error-sign-in-not-saved = die neuen Anmeldedaten konnten für den nächsten Start nicht gespeichert werden: { $error }
error-import-unreadable = { $path } kann nicht gelesen werden: { $error }
error-import-too-large = { $path } ist größer als 50 MB
error-import-not-mail = { $path } ist keine E-Mail-Nachricht
error-list-answered = der Server der Mailingliste hat mit Status { $status } geantwortet
error-not-built = die Nachricht konnte nicht erstellt werden
error-outbox-waits = { $count ->
    [one] die Nachricht wartet im Postausgang und wird beim nächsten Senden/Empfangen gesendet
   *[other] { $count } Nachrichten warten im Postausgang und werden beim nächsten Senden/Empfangen gesendet
}
error-draft-not-removed = der frühere Entwurf der Nachricht konnte nicht aus den Entwürfen entfernt werden: { $reason }
error-sent-but = die Nachricht wurde gesendet, aber { $problem }
error-sent-still-in-outbox = sie ist noch im Postausgang: { $error }
error-sent-no-copy = es konnte keine Kopie im Ordner „Gesendete Objekte“ gespeichert werden: { $reason }
error-no-password = kein Passwort für dieses Konto
error-no-sign-in = keine Anmeldedaten für dieses Konto vorhanden
error-provider-missing = diese Version kann sich nicht bei { $provider } anmelden: wurde die Anmelde-App entfernt?
error-provider-servers = die Server dieses Kontos stimmen nicht mit denen der Anmelde-App überein
error-app-scopes = { $reason }. Der Mailserver hat das Token der Anmelde-App abgelehnt. Prüfen Sie, ob die Berechtigungen (Scopes) der App den Zugriff auf E-Mails erlauben
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Google hat Inbox Classic noch nicht verifiziert. Deshalb können sich damit nur Testnutzer anmelden. Verwenden Sie Ihre eigene Google-Anmelde-App oder ein App-Passwort. Als Testnutzer können Sie die integrierte App unter Anmelde-Apps (Datei > Konten) aktivieren.
sign-in-off-other = Sie wurde unter Anmelde-Apps (Datei > Konten) ausgeschaltet und kann dort wieder eingeschaltet werden.
sign-in-app-no-name = die Anmelde-App braucht einen Namen
sign-in-app-no-client = die Client-ID fehlt
sign-in-app-no-scopes = der Anmelde-App fehlen die Berechtigungen (Scopes) für den Zugriff auf E-Mails
sign-in-app-bad-host = die Adresse des { $server }-Servers fehlt oder ist kein gültiger Hostname
sign-in-app-plain = der { $server }-Server muss SSL/TLS oder STARTTLS verwenden
sign-in-app-not-checked = der Aussteller wurde noch nicht geprüft
sign-in-app-issuer-changed = der Aussteller hat sich geändert: geben Sie das Client-Geheimnis erneut ein oder entfernen Sie es
sign-in-register-google = Erstellen Sie in der Google Cloud Console einen OAuth-Client vom Typ Desktop-App, mit der Berechtigung (Scope) https://mail.google.com/ auf seinem Zustimmungsbildschirm. Solange die App im Test ist, können sich nur ihre Testnutzer anmelden.
sign-in-register-microsoft = Registrieren Sie in Microsoft Entra eine App mit der Plattform Mobilgerät- und Desktopanwendungen, dem Weiterleitungs-URI http://localhost, erlaubten öffentlichen Clientflows und den delegierten Berechtigungen IMAP.AccessAsUser.All, SMTP.Send und offline_access. Nur für Ihre Organisation verwenden Sie https://login.microsoftonline.com/<Mandanten-ID>/v2.0 als Aussteller.
sign-in-register-other = Registrieren Sie einen nativen (öffentlichen) Client mit dem Weiterleitungs-URI unten; der Anbieter muss jeden Port darauf erlauben (RFC 8252). Fügen Sie die vom Anbieter vorgegebene Berechtigung (Scope) für den Zugriff auf E-Mails hinzu.

## Calendar invitations

repeats = Wiederholt sich
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Jeden Tag
       *[other] Alle { $interval } Tage
    }
    [week] { $interval ->
        [one] Jede Woche
       *[other] Alle { $interval } Wochen
    }
    [month] { $interval ->
        [one] Jeden Monat
       *[other] Alle { $interval } Monate
    }
   *[year] { $interval ->
        [one] Jedes Jahr
       *[other] Alle { $interval } Jahre
    }
}
repeats-on = { $repeats }: { $days }
repeats-times = { $count ->
    [one] { $repeats }, einmal
   *[other] { $repeats }, { $count } Mal
}
day-monday = Montag
day-tuesday = Dienstag
day-wednesday = Mittwoch
day-thursday = Donnerstag
day-friday = Freitag
day-saturday = Samstag
day-sunday = Sonntag

## AI agents

agent-level-read = E-Mails lesen: Ordner und Nachrichten anzeigen und durchsuchen
# review: changed
agent-level-organize = E-Mails verwalten: Lesestatus und Kennzeichnungen ändern, Junk verwalten, Nachrichten verschieben, archivieren und löschen, neue Ordner erstellen und nach Ihrer Zustimmung Mailinglisten abbestellen. Gelöschte Nachrichten landen im Ordner Gelöschte Objekte.
agent-level-drafts = Entwürfe erstellen, die Sie selbst senden
agent-level-send = E-Mail senden, jede Nachricht erst nach Ihrer Zustimmung
agent-connect-title = { $program } möchte auf Ihre E-Mails zugreifen
agent-connect-detail = Ein KI-Agent möchte auf Inbox Classic zugreifen. Legen Sie fest, was er tun darf und auf welche Konten er zugreifen kann. Sie können diese Berechtigungen später unter Extras > KI-Agenten ändern.

    Agenten lesen E-Mails von anderen Personen. Diese Nachrichten können Anweisungen enthalten, die den Agenten täuschen sollen. Inbox Classic bittet Sie immer um Bestätigung, bevor ein Agent eine Nachricht sendet.
agent-reply-to = Antwort auf „{ $subject }“
agent-reply-all-on = Antwort an alle auf „{ $subject }“
agent-forward-of = Weiterleitung von „{ $subject }“
agent-never-written-one = Sie haben noch nie an { $address } geschrieben.
agent-never-written-many = Sie haben noch nie an { $count } dieser Adressen geschrieben.
agent-send-title = { $program } möchte diese Nachricht senden
agent-send-detail = Prüfen Sie die Empfänger und den Inhalt. Nach Ihrer Bestätigung wartet die Nachricht { $seconds } Sekunden im Postausgang. Dort können Sie sie noch löschen.
agent-change-title = Was { $program } tun darf
agent-change-allowed = Ändern Sie, was die KI-Agenten dieses Programms mit Ihren E-Mails tun dürfen.
agent-change-refused = Sie haben diesem Programm den Zugriff verweigert. Lassen Sie es zu, damit seine Agenten wieder auf Ihre E-Mails zugreifen können.
agent-log-taken-back = { $entry } (rückgängig gemacht)
agent-files = Dateien: { $files }
agent-undo-refused = Das kann nicht rückgängig gemacht werden.
agent-undo-refused-why = Das kann nicht rückgängig gemacht werden: { $reason }.
agent-undo-impossible = das kann nicht rückgängig gemacht werden
agent-undo-not-in-folder = die Nachricht ist nicht mehr in diesem Ordner
agent-undo-not-arrived = die Nachricht ist (noch) nicht im Zielordner
agent-undo-sent = die Nachricht wurde bereits gesendet
agent-original-not-downloaded = die ursprüngliche Nachricht wurde noch nicht heruntergeladen. Öffnen Sie sie zuerst
agent-turned-away = Abgewiesen
agent-can-nothing = Nichts
agent-can-read = lesen
agent-can-organize = verwalten
agent-can-drafts = Entwürfe schreiben
agent-can-send = mit Ihrer Zustimmung senden
agent-can-list = { $first } und { $last }
agent-accounts = { $count ->
    [0] keine Konten
    [one] 1 Konto
   *[other] { $count } Konten
}
agent-access = { $can }; { $accounts }
agent-unreadable = Diese Nachricht kann nicht gelesen werden.
# review: new
agent-encrypted-original = Diese Nachricht ist verschlüsselt: Ein Agent kann nicht darauf antworten und sie nicht weiterleiten, da er nicht verschlüsseln kann.
# review: new
agent-encrypted = Diese Nachricht ist verschlüsselt. Nur der Benutzer kann sie in Inbox Classic lesen.
# review: new
list-encrypted = Verschlüsselte Nachricht
agent-log-composed = „{ $subject }“ zum Fertigstellen im Nachrichtenfenster geöffnet
agent-log-refused = Sie haben „{ $subject }“ nicht gesendet
agent-log-sent = „{ $subject }“ an { $to } gesendet
agent-log-draft = Entwurf „{ $subject }“ gespeichert
agent-log-read = „{ $subject }“ als gelesen markiert
agent-log-unread = „{ $subject }“ als ungelesen markiert
agent-log-flagged = „{ $subject }“ gekennzeichnet
agent-log-unflagged = Kennzeichnung von „{ $subject }“ entfernt
agent-log-deleted = „{ $subject }“ gelöscht
agent-log-moved = „{ $subject }“ nach { $folder } verschoben
agent-log-junk = „{ $subject }“ als Junk markiert
agent-log-not-junk = „{ $subject }“ als Nicht-Junk markiert
agent-log-archived = „{ $subject }“ archiviert
agent-log-folder = Ordner „{ $name }“ erstellt
agent-log-unsubscribed = Mailingliste der Nachricht „{ $subject }“ abbestellt
# review: new
agent-log-unsubscribe-failed = Mailingliste der Nachricht „{ $subject }“ konnte nicht abbestellt werden: { $reason }
# review: new
agent-log-unsubscribe-refused = Sie haben { $senders } nicht abbestellt
# review: new
agent-unsubscribe-title = { $count ->
    [one] { $program } möchte eine Mailingliste für Sie abbestellen
   *[other] { $program } möchte { $count } Mailinglisten für Sie abbestellen
}
# review: new
agent-unsubscribe-detail = Inbox Classic bittet jede der folgenden Listen, Ihnen nichts mehr zu senden, auf dem Weg mit einem Klick, den die Liste anbietet. Sonst wird nichts gesendet, und Ihre vorhandenen Nachrichten bleiben, wo sie sind.

## Keys

key-ctrl = Strg
key-alt = Alt
key-shift = Umschalt
key-del = Entf
key-enter = Eingabe

## Signing in and passwords

sign-in-no-refresh = der Anbieter hat kein Aktualisierungstoken geliefert
sign-in-no-account = der Anbieter hat nicht mitgeteilt, welches Konto sich angemeldet hat
sign-in-not-finished = die Anmeldung ist noch nicht abgeschlossen
secrets-unavailable = { $store } ist nicht verfügbar
secrets-unavailable-why = { $store } ist nicht verfügbar: { $error }
secrets-windows = die Anmeldeinformationsverwaltung
secrets-mac = der Schlüsselbund
secrets-linux = der Systemschlüsselbund (Secret Service)
error-no-such-file = diese Datei gibt es nicht
cards-file-too-big = Diese Datei ist zu groß, um sie als Adressbuch zu importieren.
ui-sender-added = { $name } wurde zum Adressbuch hinzugefügt.
ui-sender-known = { $name } ist bereits im Adressbuch.
ui-sender-none = Der Absender dieser Nachricht hat keine E-Mail-Adresse, die hinzugefügt werden kann.
card-name-needed = Der Kontakt hat weder einen Namen noch eine E-Mail-Adresse.
# a file of Import Address Book that could not be read: "contacts.vcf: there is no such file"
cards-file-failed = { $file }: { $reason }

otp-heading = Code von { $domain }
otp-copy = Kopieren
otp-note = Geben Sie ihn nur auf einer Seite von { $domain } ein.
otp-old = Dieser Code wurde mehr als eine Stunde vor dem Öffnen dieser Nachricht gesendet und ist wahrscheinlich abgelaufen.

event-attendees =
    { $count ->
        [one] { $count } Teilnehmer
       *[other] { $count } Teilnehmer
    }

otp-notification = { $code } ist Ihr Code für { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Gültig
# review: new
pgp-key-expires = Gültig bis { $date }
# review: new
pgp-key-expired = Abgelaufen am { $date }
# review: new
pgp-key-revoked = Widerrufen
# review: new
pgp-key-revoked-why = Widerrufen: { $reason }
# review: new
pgp-key-not-valid = Nicht gültig
# review: new
pgp-key-locked = Nicht verwendbar, denn { $store } enthält den schützenden Schlüssel nicht mehr. Importieren Sie seine Sicherung erneut.
# review: new
pgp-source-own = In Inbox Classic erstellt
# review: new
pgp-source-file = Aus einer Datei importiert
# review: new
pgp-source-paste = Eingefügt
# review: new
pgp-source-attachment = Aus einer Nachricht
# review: new
pgp-source-vcard = Aus einer Visitenkarte
# review: new
pgp-source-wkd = Vom E-Mail-Anbieter des Absenders
# review: new
pgp-source-keyserver = Von keys.openpgp.org
# review: new
pgp-source-autocrypt = Aus dem Autocrypt-Header einer Nachricht
# review: new
pgp-error-no-store = Für private Schlüssel wird { $store } benötigt, steht aber nicht zur Verfügung: { $error }
# review: new
pgp-error-wrong-passphrase = Die Passphrase ist nicht richtig.
# review: new
# review: new
pgp-error-not-a-key = Dies ist kein OpenPGP-Schlüssel.
# review: new
pgp-error-too-large = Der Schlüssel ist zu groß.
# review: new
pgp-error-unusable = Der Schlüssel verwendet alte oder schwache Kryptografie und kann nicht verwendet werden.
# review: new
pgp-imported-private = { $count ->
    [one] Ihr privater Schlüssel wurde importiert.
   *[other] { $count } private Schlüssel wurden importiert.
}
# review: new
pgp-imported-public = { $count ->
    [one] Ein Schlüssel wurde importiert.
   *[other] { $count } Schlüssel wurden importiert.
}
# review: new
pgp-imported-pending = Für { $addresses } wird bereits ein anderer Schlüssel verwendet: Der neue wartet im Kontakt, bis Sie ihn auswählen.
# review: new
pgp-error-needs-passphrase = Der private Schlüssel ist durch eine Passphrase geschützt. Geben Sie sie ein, um den Schlüssel zu importieren.
# review: new
pgp-error-mismatch = Der private Schlüssel gehört nicht zu seinem öffentlichen Schlüssel. Er wurde möglicherweise verändert.
# review: new
pgp-file-name-public = { $who } öffentlicher Schlüssel.asc
# review: new
pgp-file-name-private = { $who } Sicherung des privaten Schlüssels.asc
# review: new
pgp-pending = Für { $address } wurde am { $date } ein anderer Schlüssel gefunden.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Signiert von { $signer }, Schlüssel überprüft
# review: new
pgp-part-signed = Signiert von { $signer } (Schlüssel nicht überprüft)
# review: new
pgp-part-other = Signiert von { $signer }, nicht vom Absender
# review: new
pgp-part-unknown-key = Signiert, aber der Schlüssel ist nicht bekannt
# review: new
pgp-part-not-signed = Nicht signiert
# review: new
pgp-part-not-checked = Signatur nicht geprüft
# review: new
pgp-part-encrypted = Verschlüsselt. { $signature }
# review: new
pgp-part-no-key = Verschlüsselt für einen Schlüssel, den Sie nicht haben
# review: new
pgp-part-changed = Der verschlüsselte Teil wurde unterwegs verändert und wird nicht angezeigt
# review: new
pgp-part-unprotected = Ohne Schutz gegen Veränderung verschlüsselt, nicht angezeigt
# review: new
pgp-part-broken = Der verschlüsselte Teil kann nicht gelesen werden
# review: new
pgp-why-mismatch = Die Signatur passt nicht zu diesem Text
# review: new
pgp-why-weak-hash = Die Signatur verwendet { $hash }, das nicht mehr sicher ist
# review: new
pgp-why-key-expired = Signiert, nachdem der Schlüssel am { $date } abgelaufen war
# review: new
pgp-why-key-revoked = Mit einem widerrufenen Schlüssel signiert
# review: new
pgp-why-not-signing-key = Mit einem Schlüssel signiert, der nicht signieren darf
# review: new
pgp-why-from-future = Die Signatur ist in die Zukunft datiert
# review: new
pgp-why-signature-expired = Die Signatur ist abgelaufen
# review: new
pgp-why-key-not-valid = Mit einem ungültigen Schlüssel signiert
# review: new
pgp-why-not-for-you = Für andere Empfänger signiert und an Sie weitergegeben
# review: new
pgp-why-not-key-in-use = Mit einem anderen Schlüssel signiert als dem, der für { $address } verwendet wird
# review: new
pgp-part-pictures-loaded = { $label }. Bilder wurden aus dem Internet geladen
# review: new
pgp-error-no-own-key = Sie haben keinen Schlüssel für { $address }, um zu signieren oder zu verschlüsseln. Erstellen Sie einen unter Extras > Verschlüsselungsschlüssel, oder schalten Sie Signieren und Verschlüsseln aus.
# review: new
pgp-error-missing-keys = { $count ->
    [one] { $addresses } hat keinen Schlüssel zum Verschlüsseln.
   *[other] Diese Empfänger haben keinen Schlüssel zum Verschlüsseln: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Diese Nachricht zitiert oder leitet eine verschlüsselte Nachricht weiter und kann daher nur verschlüsselt gesendet werden. Schalten Sie Verschlüsseln ein, oder entfernen Sie den zitierten Text.
# review: new
pgp-error-protect = Die Nachricht konnte nicht signiert oder verschlüsselt werden: { $reason }
# review: new
pgp-found-keys = Der Schlüssel von { $addresses } wurde gefunden.
# review: new
pgp-found-none = Für { $addresses } wurde kein Schlüssel gefunden. Bitten Sie darum, Ihnen den öffentlichen Schlüssel zu senden.
# review: new
pgp-found-no-key = Es wurde kein Schlüssel gefunden.
# review: new
pgp-find-unavailable = Schlüssel können gerade nicht gesucht werden: { $error }
# review: new
pgp-publish-pending = keys.openpgp.org hat einen Bestätigungslink an { $addresses } gesendet. Ihr Schlüssel wird dort veröffentlicht, sobald Sie darauf klicken.
# review: new
pgp-publish-done = Ihr Schlüssel ist auf keys.openpgp.org für { $addresses } veröffentlicht.
# review: new
pgp-publish-failed = Der Schlüssel konnte nicht veröffentlicht werden: { $error }
# review: changed
pgp-keyserver-off = Die Schlüsselsuche auf keys.openpgp.org ist unter { $settings } ausgeschaltet.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Verschlüsselt und signiert: Nur Sie und { $addresses } können die Nachricht lesen.
   *[other] Verschlüsselt und signiert: Nur Sie und die { $count } Empfänger können die Nachricht lesen.
}
# review: new
pgp-compose-encrypt-ready = Die Nachricht wird verschlüsselt und signiert. Fügen Sie Empfänger hinzu, deren Schlüssel Sie haben.
# review: new
pgp-compose-missing = { $count ->
    [one] { $addresses } hat keinen Schlüssel, daher kann die Nachricht noch nicht verschlüsselt werden.
   *[other] { $count } Empfänger haben keinen Schlüssel, daher kann die Nachricht noch nicht verschlüsselt werden: { $addresses }.
}
# review: new
pgp-compose-looking = Die Schlüssel von { $addresses } werden gesucht...
# review: new
pgp-compose-signed = Signiert: Die Empfänger können prüfen, dass die Nachricht von Ihnen stammt und nicht verändert wurde.
# review: new
pgp-compose-reply-clear = Nicht verschlüsselt, obwohl die beantwortete oder weitergeleitete Nachricht verschlüsselt war.
# review: new
pgp-compose-encrypted-files = Dateien einer verschlüsselten Nachricht sind angehängt, daher kann diese Nachricht nur verschlüsselt gesendet werden. Schalten Sie Verschlüsseln ein, oder entfernen Sie diese Dateien.
# review: new
pgp-compose-sign-tip = Die Nachricht mit Ihrem Schlüssel signieren, damit die Empfänger prüfen können, dass sie von Ihnen stammt und nicht verändert wurde
# review: new
pgp-compose-sign-tip-encrypted = Eine verschlüsselte Nachricht wird immer signiert
# review: new
pgp-compose-encrypt-tip = Die Nachricht verschlüsseln, damit nur Sie und die Empfänger sie lesen können
# review: new
pgp-compose-make-key = Sie haben noch keinen Schlüssel für { $address }. Jetzt einen erstellen? Damit können Ihre Nachrichten signiert und verschlüsselt werden.
# review: new
pgp-compose-key-unusable = Ihr Schlüssel für { $address } kann nicht verwendet werden ({ $state }). Öffnen Sie Verschlüsselungsschlüssel, um seine Sicherung zu importieren oder einen neuen Schlüssel zu erstellen.
# review: new
pgp-compose-encrypt-off-quote = Diese Nachricht zitiert oder leitet eine verschlüsselte Nachricht weiter. Ohne Verschlüsselung kann sie erst gesendet werden, wenn Sie das Zitierte entfernen. Verschlüsselung trotzdem ausschalten?
# review: new
pgp-compose-encrypt-off-reply = Diese Nachricht beantwortet eine verschlüsselte Nachricht oder leitet sie weiter. Ohne Verschlüsselung kann jeder, der Ihre Nachricht unterwegs befördert, sie lesen. Verschlüsselung ausschalten?
# review: new
pgp-recipient-verified = Schlüssel überprüft
# review: new
pgp-recipient-found = Schlüssel nicht überprüft
# review: new
pgp-recipient-own = Ihr eigener Schlüssel
# review: new
pgp-recipient-looking = Schlüssel wird gesucht...
# review: new
pgp-recipient-missing = Kein Schlüssel
# review: new
pgp-recipient-not-found = Kein Schlüssel: Am { $date } wurde keiner gefunden
# review: new
pgp-recipient-unusable = Schlüssel nicht verwendbar: { $state }
# review: new
pgp-recipients-intro = Die Nachricht wird für den Schlüssel jedes Empfängers verschlüsselt und für Ihren.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Ein Empfänger hat keinen Schlüssel zum Verschlüsseln. Suchen Sie seinen Schlüssel, entfernen Sie ihn aus dieser Nachricht, oder senden Sie die Nachricht ohne Verschlüsselung.
   *[other] { $count } Empfänger haben keinen Schlüssel zum Verschlüsseln. Suchen Sie ihre Schlüssel, entfernen Sie sie aus dieser Nachricht, oder senden Sie die Nachricht ohne Verschlüsselung.
}
# review: new
pgp-details-part = Teil { $number }: { $label }
# review: new
pgp-details-signed = Signiert { $when } mit dem Schlüssel { $key }
# review: new
pgp-details-unknown-key = Signiert mit dem Schlüssel { $key }, den Sie nicht haben
# review: new
pgp-details-opened = Verschlüsselt für Ihren Schlüssel { $key }
# review: new
pgp-details-for = Verschlüsselt für { $keys }
# review: new
pgp-details-plain = Weder signiert noch verschlüsselt
# review: new
pgp-bar-parts = Diese Nachricht hat { $count } Teile: { $list }. Jeder Teil sagt, wie er geschützt ist.
# review: new
pgp-bar-count-verified = { $count } überprüft
# review: new
pgp-bar-count-good = { $count } signiert oder verschlüsselt
# review: new
pgp-bar-count-warning = { $count ->
    [one] 1 braucht Aufmerksamkeit
   *[other] { $count } brauchen Aufmerksamkeit
}
# review: new
pgp-bar-count-neutral = { $count } ohne bestätigte Signatur
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Einstellungen
# review: new
setup-part-preferences = Fenstereinstellungen
# review: new
setup-part-accounts = Konten
# review: new
setup-part-sign-in-apps = Anmelde-Apps
# review: new
setup-part-contacts = Kontakte und Gruppen
# review: new
setup-part-keys = Verschlüsselungsschlüssel
# review: new
setup-part-rules = Nachrichtenregeln
# review: new
setup-part-trusted-senders = Vertrauenswürdige Absender
# review: new
setup-holds-settings = { $count ->
    [one] 1 Einstellung
   *[other] { $count } Einstellungen
}
# review: new
setup-holds-preferences = { $count ->
    [one] 1 Fenstereinstellung
   *[other] { $count } Fenstereinstellungen
}
# review: new
setup-holds-accounts = { $count ->
    [one] 1 Konto
   *[other] { $count } Konten
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] 1 Anmelde-App
   *[other] { $count } Anmelde-Apps
}
# review: new
setup-holds-built-in = Welche integrierten Anmelde-Apps eingeschaltet sind
# review: new
setup-holds-contacts = { $count ->
    [one] 1 Kontakt
   *[other] { $count } Kontakte
}
# review: new
setup-holds-groups = { $count ->
    [one] 1 Gruppe
   *[other] { $count } Gruppen
}
# review: new
setup-holds-own-keys = { $count ->
    [one] 1 eigener Schlüssel
   *[other] { $count } eigene Schlüssel
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] 1 Schlüssel eines Kontakts
   *[other] { $count } Schlüssel von Kontakten
}
# review: new
setup-holds-rules = { $count ->
    [one] 1 Regel
   *[other] { $count } Regeln
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] 1 vertrauenswürdiger Absender
   *[other] { $count } vertrauenswürdige Absender
}
# review: new
setup-sign-in-password = Passwort
# review: new
setup-account-secret-password = Das Passwort ist in der Datei enthalten.
# review: new
setup-account-secret-token = Die Anmeldung ist in der Datei enthalten.
# review: new
setup-account-asks-password = Nach dem Import wird nach dem Passwort gefragt.
# review: new
setup-account-signs-in-again = Sie melden sich nach dem Import erneut an.
# review: new
setup-account-here = Das Konto ist hier bereits eingerichtet und wird übersprungen.
# review: new
setup-account-no-app = Das Konto meldet sich mit { $app } an, das hier nicht eingerichtet ist. Importieren Sie auch die Anmelde-Apps.
# review: new
setup-invalid-address = „{ $address }“ ist keine E-Mail-Adresse.
# review: new
setup-invalid-server = Der { $server }-Server hat keinen verwendbaren Namen oder Port.
# review: new
setup-invalid-user = Das Konto hat keinen Benutzernamen.
# review: new
setup-invalid-sign-in = Das Konto meldet sich auf eine Weise an, die Inbox Classic nicht kennt.
# review: new
setup-error-empty = Die Datei ist leer.
# review: new
setup-error-too-large = Die Datei ist zu groß für eine Inbox-Classic-Einrichtung.
# review: new
setup-error-not-setup = Diese Datei ist keine Inbox-Classic-Einrichtung.
# review: new
setup-error-damaged = Die Einrichtungsdatei ist beschädigt und kann nicht gelesen werden.
# review: new
setup-error-newer = Diese Einrichtung wurde von einer neueren Version von Inbox Classic ({ $version }) gespeichert. Aktualisieren Sie Inbox Classic und importieren Sie sie dann erneut.
# review: new
setup-error-needs-passphrase = Diese Einrichtung ist mit einer Passphrase geschützt. Geben Sie die Passphrase ein, mit der sie gespeichert wurde.
# review: new
setup-error-wrong-passphrase = Das ist nicht die Passphrase, mit der diese Einrichtung gespeichert wurde.
# review: new
setup-error-changed = Die Einrichtungsdatei wurde nach dem Speichern verändert oder beschädigt und kann daher nicht importiert werden.
# review: new
setup-error-read = Die Einrichtungsdatei konnte nicht gelesen werden: { $error }
# review: new
setup-error-write = Die Einrichtung konnte nicht gespeichert werden: { $error }
# review: new
setup-error-no-parts = Wählen Sie mindestens einen Teil aus.
# review: new
setup-left-out = { $count ->
    [one] 1 Eintrag von „{ $part }“ ist nicht verwendbar und wird ausgelassen.
   *[other] { $count } Einträge von „{ $part }“ sind nicht verwendbar und werden ausgelassen.
}
# review: new
setup-imported-settings = Die Einstellungen wurden ersetzt.
# review: new
setup-imported-preferences = Die Fenstereinstellungen wurden ersetzt.
# review: new
setup-added-accounts = { $count ->
    [one] 1 Konto hinzugefügt.
   *[other] { $count } Konten hinzugefügt.
}
# review: new
setup-skipped-here = { $address } ist hier bereits eingerichtet und wurde übersprungen.
# review: new
setup-skipped-no-app = { $address } wurde übersprungen: Das Konto meldet sich mit { $app } an, das hier nicht eingerichtet ist.
# review: new
setup-skipped-invalid = { $address } wurde übersprungen: { $reason }
# review: new
setup-asks-password = { $address } fragt beim Verbinden nach dem Passwort.
# review: new
setup-signs-in-again = { $address } bittet Sie beim Verbinden, sich erneut anzumelden.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] 1 Anmelde-App hinzugefügt.
   *[other] { $count } Anmelde-Apps hinzugefügt.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] 1 Anmelde-App ist hier bereits eingerichtet.
   *[other] { $count } Anmelde-Apps sind hier bereits eingerichtet.
}
# review: new
setup-added-contacts = { $count ->
    [one] 1 Kontakt zum Adressbuch hinzugefügt.
   *[other] { $count } Kontakte zum Adressbuch hinzugefügt.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] 1 Kontakt ist bereits im Adressbuch.
   *[other] { $count } Kontakte sind bereits im Adressbuch.
}
# review: new
setup-added-groups = { $count ->
    [one] 1 Gruppe hinzugefügt oder ergänzt.
   *[other] { $count } Gruppen hinzugefügt oder ergänzt.
}
# review: new
setup-added-own-keys = { $count ->
    [one] 1 eigenen Schlüssel hinzugefügt.
   *[other] { $count } eigene Schlüssel hinzugefügt.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] 1 Schlüssel eines Kontakts hinzugefügt.
   *[other] { $count } Schlüssel von Kontakten hinzugefügt.
}
# review: new
setup-added-rules = { $count ->
    [one] 1 Nachrichtenregel hinzugefügt.
   *[other] { $count } Nachrichtenregeln hinzugefügt.
}
# review: new
setup-skipped-rules = { $count ->
    [one] 1 Nachrichtenregel ist bereits vorhanden.
   *[other] { $count } Nachrichtenregeln sind bereits vorhanden.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] 1 Nachrichtenregel gilt für ein Konto, das hier nicht vorhanden ist, und wurde übersprungen.
   *[other] { $count } Nachrichtenregeln gelten für Konten, die hier nicht vorhanden sind, und wurden übersprungen.
}
# review: new
setup-rules-waiting = { $count ->
    [one] 1 Nachrichtenregel verschiebt Nachrichten in einen Ordner, der erscheint, sobald sein Konto synchronisiert ist.
   *[other] { $count } Nachrichtenregeln verschieben Nachrichten in Ordner, die erscheinen, sobald ihre Konten synchronisiert sind.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] 1 vertrauenswürdigen Absender hinzugefügt.
   *[other] { $count } vertrauenswürdige Absender hinzugefügt.
}
# review: new
setup-nothing = Es wurde nichts importiert.
# review: new
setup-account-servers = { $imap } und { $smtp } ({ $signin })
# review: new
setup-file-name = Inbox Classic-Einstellungen und -Konten
# review: new
setup-skipped-unreachable = { $name } wurde übersprungen: Der Anmeldedienst war nicht erreichbar. Fügen Sie die Anmelde-App unter „Anmelde-Apps“ erneut hinzu.
# review: new
attachment-runs-programs = „{ $name }“ kann Programme ausführen, daher öffnet Inbox Classic die Datei nicht. Speichern Sie sie und öffnen Sie sie selbst, wenn Sie der Herkunft vertrauen.
# review: new
attachment-decrypted-note = Dieser Anhang stammt aus einer verschlüsselten Nachricht. Zum Öffnen speichert Inbox Classic ihn entschlüsselt auf diesem Computer, in einem Ordner von Ihnen, den Inbox Classic nach einem Tag leert.
# review: new
undone-move = { $count ->
    [one] Der Server hat { $messages } nicht in { $folder } verschoben, daher ist sie wieder in { $from }: { $reason }
   *[other] Der Server hat { $messages } nicht in { $folder } verschoben, daher sind sie wieder in { $from }: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Der Server hat { $messages } nicht gelöscht, daher ist sie wieder in { $from }: { $reason }
   *[other] Der Server hat { $messages } nicht gelöscht, daher sind sie wieder in { $from }: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Der Server hat { $messages } nicht archiviert, daher ist sie wieder in { $from }: { $reason }
   *[other] Der Server hat { $messages } nicht archiviert, daher sind sie wieder in { $from }: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Der Server hat { $messages } nicht als gelesen markiert, daher ist sie wieder ungelesen: { $reason }
   *[other] Der Server hat { $messages } nicht als gelesen markiert, daher sind sie wieder ungelesen: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Der Server hat { $messages } nicht als ungelesen markiert, daher ist sie wieder gelesen: { $reason }
   *[other] Der Server hat { $messages } nicht als ungelesen markiert, daher sind sie wieder gelesen: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Der Server hat die Kennzeichnungen von { $messages } nicht geändert, daher ist sie wie zuvor: { $reason }
   *[other] Der Server hat die Kennzeichnungen von { $messages } nicht geändert, daher sind sie wie zuvor: { $reason }
}
