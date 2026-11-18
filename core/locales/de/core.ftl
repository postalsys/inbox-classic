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
header-security = Sicherheit
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
agent-level-organize = E-Mails verwalten: Lesestatus, Kennzeichnungen und ihre Farben ändern, Junk verwalten, Nachrichten verschieben, archivieren und löschen, Ordner erstellen und umbenennen, Unterhaltungen beobachten und ignorieren und nach Ihrer Zustimmung Mailinglisten abbestellen. Gelöschte Nachrichten landen im Ordner Gelöschte Objekte.
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
agent-undo-sent = Die Nachricht ist nicht mehr im Postausgang
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
agent-encrypted-original = Agenten können diese verschlüsselte Nachricht weder beantworten noch weiterleiten, da sie keine Nachrichten verschlüsseln können.
agent-encrypted = Diese Nachricht ist verschlüsselt. KI-Agenten können ihren Inhalt nicht lesen. Der Benutzer muss sie selbst in Inbox Classic öffnen.
list-encrypted = Verschlüsselte Nachricht
agent-log-composed = „{ $subject }“ zum Fertigstellen im Nachrichtenfenster geöffnet
agent-log-refused = Sie haben „{ $subject }“ nicht gesendet
agent-log-sent = „{ $subject }“ an { $to } gesendet
agent-log-draft = Entwurf „{ $subject }“ gespeichert
agent-log-draft-replaced = Entwurf „{ $subject }“ ersetzt
agent-log-draft-discarded = Entwurf „{ $subject }“ verworfen
agent-draft-note = { $program }, ein KI-Agent, hat diesen Entwurf geschrieben. Prüfen Sie die Empfänger und den Text, bevor Sie ihn senden.
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
agent-log-unsubscribed = Sie haben der Abmeldeanfrage zugestimmt. Nachricht: „{ $subject }“
agent-log-unsubscribe-failed = Mailingliste der Nachricht „{ $subject }“ konnte nicht abbestellt werden: { $reason }
agent-log-unsubscribe-refused = Sie haben folgende Mailinglisten nicht abbestellt: { $senders }
agent-unsubscribe-title = { $count ->
    [one] { $program } möchte eine Mailingliste für Sie abbestellen
   *[other] { $program } möchte { $count } Mailinglisten für Sie abbestellen
}
agent-unsubscribe-detail = { $count ->
    [1] Inbox Classic fordert die unten aufgeführte Mailingliste über deren Ein-Klick-Abmeldung auf, Ihnen keine weiteren Nachrichten zu senden. Es wird nur diese Abmeldeanfrage gesendet. Ihre vorhandenen Nachrichten bleiben unverändert.
   *[other] Inbox Classic fordert die unten aufgeführten Mailinglisten über deren Ein-Klick-Abmeldung auf, Ihnen keine weiteren Nachrichten zu senden. Es werden nur diese Abmeldeanfragen gesendet. Ihre vorhandenen Nachrichten bleiben unverändert.
}
# review: new
agent-log-flag-color = „{ $subject }“ { $color ->
    [red] rot
    [orange] orange
    [yellow] gelb
    [green] grün
    [blue] blau
    [purple] lila
   *[gray] grau
} gekennzeichnet
# review: new
agent-log-renamed = Ordner „{ $old }“ in „{ $name }“ umbenannt
# review: new
agent-log-watched = Unterhaltung „{ $subject }“ beobachtet
# review: new
agent-log-ignored = Unterhaltung „{ $subject }“ ignoriert
# review: new
agent-log-unmarked = Unterhaltung „{ $subject }“ nicht mehr beobachtet oder ignoriert
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
# review: new
agent-reads-messages = { $count ->
    [one] 1 Nachricht gelesen
   *[other] { $count } Nachrichten gelesen
}
# review: new
agent-reads-attachments = { $count ->
    [one] 1 Anlage geöffnet
   *[other] { $count } Anlagen geöffnet
}
# review: new
agent-reads-searches = { $count ->
    [one] einmal gesucht
   *[other] { $count }-mal gesucht
}
# review: new
agent-reads-lists = { $count ->
    [one] einmal eine Nachrichtenliste angesehen
   *[other] { $count }-mal Nachrichtenlisten angesehen
}
# each read under that row
# review: new
agent-read-message = „{ $subject }“ gelesen
# review: new
agent-read-conversation = { $count ->
    [one] Unterhaltung „{ $subject }“ gelesen (1 Nachricht)
   *[other] Unterhaltung „{ $subject }“ gelesen ({ $count } Nachrichten)
}
# review: new
agent-read-attachment = „{ $name }“ aus „{ $subject }“ geöffnet
# review: new
agent-read-search = { $count ->
    [one] Nach „{ $query }“ gesucht: 1 Nachricht
   *[other] Nach „{ $query }“ gesucht: { $count } Nachrichten
}
# review: new
agent-read-people = Personen nachgeschlagen, die mit „{ $query }“ beginnen
# review: new
agent-read-list = { $count ->
    [one] 1 Nachricht in { $folder } angesehen
   *[other] { $count } Nachrichten in { $folder } angesehen
}
# review: new
agent-read-changes = { $count ->
    [one] 1 neue Nachricht angesehen
   *[other] { $count } neue Nachrichten angesehen
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
# review: new
agent-terminal-programs-mac = Aus { $terminal } gestartete Programme
# review: new
agent-terminal-programs-windows = Aus einem Terminal ({ $terminal }) gestartete Programme
# review: new
agent-terminal-programs-linux = Aus einem Terminal ({ $terminal }) gestartete Programme
# one of them, as the questions to send or unsubscribe name it: "A program started from Terminal wants to send this message"
# review: new
agent-terminal-program-mac = Ein aus { $terminal } gestartetes Programm
# review: new
agent-terminal-program-windows = Ein aus einem Terminal ({ $terminal }) gestartetes Programm
# review: new
agent-terminal-program-linux = Ein aus einem Terminal ({ $terminal }) gestartetes Programm
# review: new
agent-connect-title-terminal = { $programs } möchten auf Ihre E-Mails zugreifen
# review: new
agent-connect-terminal-detail = Alle KI-Agenten, die Sie aus diesem Terminal starten, teilen sich den Zugriff, den Sie hier erlauben. Um einem Agenten eigenen Zugriff zu geben, fügen Sie in seinen MCP-Einstellungen --name und einen Namen Ihrer Wahl zu seinen Argumenten hinzu.

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
pgp-key-valid = Gültig
pgp-key-expires = Gültig bis { $date }
pgp-key-expired = Abgelaufen am { $date }
pgp-key-revoked = Widerrufen
pgp-key-revoked-why = Widerrufen: { $reason }
pgp-key-not-valid = Nicht gültig
pgp-key-locked = Der Schlüssel zum Entsperren fehlt im Kennwortspeicher ({ $store }). Importieren Sie die Sicherung Ihres privaten Schlüssels erneut.
pgp-source-own = In Inbox Classic erstellt
pgp-source-file = Aus einer Datei importiert
pgp-source-paste = Eingefügt
pgp-source-attachment = Aus einer Nachricht
pgp-source-vcard = Aus einer Visitenkarte
pgp-source-wkd = Vom E-Mail-Anbieter des Absenders
pgp-source-keyserver = Von keys.openpgp.org
pgp-source-autocrypt = Aus dem Autocrypt-Header einer Nachricht
pgp-error-no-store = Der Kennwortspeicher für private Schlüssel ist nicht verfügbar ({ $store }): { $error }
pgp-error-wrong-passphrase = Die Passphrase ist nicht korrekt.
pgp-error-not-a-key = Dies ist kein OpenPGP-Schlüssel.
pgp-error-too-large = Der Schlüssel ist zu groß.
pgp-error-unusable = Der Schlüssel verwendet veraltete oder unsichere Kryptografie und kann daher nicht verwendet werden.
pgp-imported-private = { $count ->
    [one] Ihr privater Schlüssel wurde importiert.
   *[other] { $count } private Schlüssel wurden importiert.
}
pgp-imported-public = { $count ->
    [one] Ein Schlüssel wurde importiert.
   *[other] { $count } Schlüssel wurden importiert.
}
pgp-imported-pending = Für folgende Adressen ist bereits ein anderer Schlüssel hinterlegt: { $addresses }. Den neuen Schlüssel können Sie in den Kontakteigenschaften auswählen.
pgp-error-needs-passphrase = Der private Schlüssel ist durch eine Passphrase geschützt. Geben Sie sie ein, um den Schlüssel zu importieren.
pgp-error-mismatch = Der private und der öffentliche Schlüssel passen nicht zusammen. Der Schlüssel wurde möglicherweise verändert.
pgp-file-name-public = Öffentlicher Schlüssel ({ $who }).asc
pgp-file-name-private = Sicherung des privaten Schlüssels ({ $who }).asc
pgp-pending = Für { $address } wurde am { $date } ein anderer Schlüssel gefunden.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Signiert von { $signer }, Schlüsselinhaber bestätigt
pgp-part-signed = Signiert von { $signer }, Schlüsselinhaber nicht bestätigt
pgp-part-other = Signiert von { $signer }, nicht vom Absender
pgp-part-unknown-key = Signiert, aber der Schlüssel ist nicht bekannt
pgp-part-not-signed = Nicht signiert
pgp-part-not-checked = Signatur nicht geprüft
pgp-part-encrypted = Verschlüsselt. { $signature }
pgp-part-no-key = Kein passender privater Schlüssel zum Entschlüsseln verfügbar
pgp-part-changed = Der verschlüsselte Inhalt wurde bei der Übertragung verändert und wird nicht angezeigt
pgp-part-unprotected = Der verschlüsselte Inhalt ist nicht gegen Veränderungen geschützt und wird nicht angezeigt
pgp-part-broken = Der verschlüsselte Teil kann nicht gelesen werden
pgp-why-mismatch = Die Signatur stimmt nicht mit dem Inhalt überein
pgp-why-weak-hash = Die Signatur verwendet den Hashalgorithmus { $hash }, der nicht mehr als sicher gilt
pgp-why-key-expired = Zum Zeitpunkt der Signatur war der Schlüssel bereits abgelaufen (Ablaufdatum: { $date })
pgp-why-key-revoked = Mit einem widerrufenen Schlüssel signiert
pgp-why-not-signing-key = Der verwendete Schlüssel ist nicht zum Signieren vorgesehen
pgp-why-from-future = Die Signatur ist in die Zukunft datiert
pgp-why-signature-expired = Die Signatur ist abgelaufen
pgp-why-key-not-valid = Mit einem ungültigen Schlüssel signiert
pgp-why-not-for-you = Für andere Empfänger signiert und anschließend an Sie weitergeleitet
pgp-why-not-key-in-use = Der Signaturschlüssel stimmt nicht mit dem aktuell für { $address } verwendeten Schlüssel überein
pgp-part-pictures-loaded = { $label }. Bilder wurden aus dem Internet geladen
pgp-error-no-own-key = Für { $address } ist kein Schlüssel zum Signieren oder Verschlüsseln eingerichtet. Erstellen Sie unter Extras > Verschlüsselungsschlüssel einen Schlüssel oder deaktivieren Sie Signieren und Verschlüsseln.
pgp-error-missing-keys = { $count ->
    [one] Zum Verschlüsseln fehlt der Schlüssel für { $addresses }.
   *[other] Zum Verschlüsseln fehlen die Schlüssel für folgende Empfänger: { $addresses }.
}
pgp-error-encrypted-quote = Diese Nachricht enthält Inhalte aus einer verschlüsselten Nachricht. Aktivieren Sie die Verschlüsselung oder entfernen Sie die zitierten Inhalte, bevor Sie sie senden.
pgp-error-protect = Die Nachricht konnte nicht signiert oder verschlüsselt werden: { $reason }
pgp-found-keys = Schlüssel gefunden für: { $addresses }.
pgp-found-none = Für folgende Adressen wurde kein Schlüssel gefunden: { $addresses }. Bitten Sie die Empfänger, Ihnen ihre öffentlichen Schlüssel zu senden.
pgp-found-no-key = Es wurde kein Schlüssel gefunden.
pgp-find-unavailable = Die Schlüsselsuche ist derzeit nicht verfügbar: { $error }
pgp-publish-pending = keys.openpgp.org hat einen Bestätigungslink an folgende Adressen gesendet: { $addresses }. Bestätigen Sie jede Adresse, damit Ihr Schlüssel darüber gefunden werden kann.
pgp-publish-done = Ihr Schlüssel ist auf keys.openpgp.org für { $addresses } veröffentlicht.
pgp-publish-failed = Der Schlüssel konnte nicht veröffentlicht werden: { $error }
pgp-keyserver-off = Die Schlüsselsuche auf keys.openpgp.org ist unter { $settings } ausgeschaltet.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Beim Senden verschlüsselt und signiert. Den Inhalt können nur Sie und { $addresses } lesen.
   *[other] Beim Senden verschlüsselt und signiert. Den Inhalt können nur Sie und die { $count } Empfänger lesen.
}
pgp-compose-encrypt-ready = Beim Senden wird die Nachricht verschlüsselt und signiert. Fügen Sie Empfänger hinzu, für die ein verwendbarer Schlüssel vorliegt.
pgp-compose-missing = { $count ->
    [one] Für diesen Empfänger fehlt ein verwendbarer Schlüssel: { $addresses }. Die Nachricht kann noch nicht verschlüsselt werden.
   *[other] Für { $count } Empfänger fehlt ein verwendbarer Schlüssel: { $addresses }. Die Nachricht kann noch nicht verschlüsselt werden.
}
pgp-compose-looking = Schlüsselsuche für: { $addresses }...
pgp-compose-signed = Beim Senden digital signiert: Die Empfänger können die Signatur prüfen und Änderungen am Inhalt erkennen.
pgp-compose-reply-clear = Nicht verschlüsselt, obwohl die beantwortete oder weitergeleitete Nachricht verschlüsselt war.
pgp-compose-encrypted-files = Die Nachricht enthält Anlagen aus einer verschlüsselten Nachricht und kann daher nur verschlüsselt gesendet werden. Aktivieren Sie „Verschlüsseln“ oder entfernen Sie diese Anlagen.
pgp-compose-sign-tip = Die Nachricht beim Senden digital signieren, damit die Empfänger die Signatur und die Unversehrtheit des Inhalts prüfen können
pgp-compose-sign-tip-encrypted = Verschlüsselt gesendete Nachrichten werden immer auch signiert
pgp-compose-encrypt-tip = Den Nachrichteninhalt beim Senden verschlüsseln, damit nur Sie und die Empfänger ihn lesen können
pgp-compose-make-key = Für { $address } ist noch kein eigener Schlüssel eingerichtet. Möchten Sie jetzt einen erstellen? Damit können Sie Nachrichten digital signieren und verschlüsseln.
pgp-compose-key-unusable = Ihr Schlüssel für { $address } kann nicht verwendet werden. Grund: { $state }
    Öffnen Sie „Verschlüsselungsschlüssel“, um die Sicherung dieses Schlüssels zu importieren oder einen neuen Schlüssel zu erstellen.
pgp-compose-encrypt-off-quote = Diese Nachricht enthält noch Inhalte aus einer verschlüsselten Nachricht. Entfernen Sie erst die übernommenen Inhalte und Anlagen, bevor Sie die Nachricht unverschlüsselt senden. Verschlüsselung trotzdem ausschalten?
pgp-compose-encrypt-off-reply = Die ursprüngliche Nachricht war verschlüsselt. Wenn Sie diese Antwort oder Weiterleitung unverschlüsselt senden, können beteiligte Mailserver ihren Inhalt lesen. Verschlüsselung ausschalten?
pgp-recipient-verified = Schlüssel überprüft
pgp-recipient-found = Schlüssel nicht überprüft
pgp-recipient-own = Ihr eigener Schlüssel
pgp-recipient-looking = Schlüssel wird gesucht...
pgp-recipient-missing = Kein Schlüssel
pgp-recipient-not-found = Kein Schlüssel gefunden. Letzte Suche: { $date }
pgp-recipient-unusable = Schlüssel nicht verwendbar: { $state }
pgp-recipients-intro = Zum Verschlüsseln verwendet Inbox Classic die Schlüssel aller Empfänger und Ihren eigenen.
pgp-recipients-intro-missing = { $count ->
    [one] Für einen Empfänger fehlt ein verwendbarer Schlüssel. Suchen Sie nach dem Schlüssel oder entfernen Sie den Empfänger aus der Nachricht. Unverschlüsselt senden können Sie nur ohne übernommene Inhalte aus verschlüsselten Nachrichten.
   *[other] Für { $count } Empfänger fehlt ein verwendbarer Schlüssel. Suchen Sie nach den Schlüsseln oder entfernen Sie die Empfänger aus der Nachricht. Unverschlüsselt senden können Sie nur ohne übernommene Inhalte aus verschlüsselten Nachrichten.
}
pgp-details-part = Teil { $number }: { $label }
pgp-details-signed = Am { $when } mit Schlüssel { $key } signiert
pgp-details-unknown-key = Mit Schlüssel { $key } signiert; dieser Schlüssel ist hier nicht vorhanden
pgp-details-opened = Mit Ihrem Schlüssel { $key } entschlüsselt
pgp-details-for = Verschlüsselt mit folgenden Schlüsseln: { $keys }
pgp-details-plain = Weder signiert noch verschlüsselt
pgp-bar-parts = Diese Nachricht besteht aus { $count } Teilen: { $list }. Der Schutzstatus steht jeweils über dem betreffenden Teil.
pgp-bar-count-verified = { $count } überprüft
pgp-bar-count-good = { $count } signiert oder verschlüsselt
pgp-bar-count-warning = { $count ->
    [one] 1 mit Warnhinweis
   *[other] { $count } mit Warnhinweis
}
pgp-bar-count-neutral = { $count } ohne bestätigte Signatur
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Einstellungen
setup-part-preferences = Fenstereinstellungen
setup-part-accounts = Konten
setup-part-sign-in-apps = Anmelde-Apps
setup-part-contacts = Kontakte und Gruppen
setup-part-keys = Verschlüsselungsschlüssel
setup-part-rules = Nachrichtenregeln
setup-part-trusted-senders = Vertrauenswürdige Absender
setup-holds-settings = { $count ->
    [one] 1 Einstellung
   *[other] { $count } Einstellungen
}
setup-holds-preferences = { $count ->
    [one] 1 Fenstereinstellung
   *[other] { $count } Fenstereinstellungen
}
setup-holds-accounts = { $count ->
    [one] 1 Konto
   *[other] { $count } Konten
}
setup-holds-sign-in-apps = { $count ->
    [one] 1 Anmelde-App
   *[other] { $count } Anmelde-Apps
}
setup-holds-built-in = Aktivierung der integrierten Anmelde-Apps
setup-holds-contacts = { $count ->
    [one] 1 Kontakt
   *[other] { $count } Kontakte
}
setup-holds-groups = { $count ->
    [one] 1 Gruppe
   *[other] { $count } Gruppen
}
setup-holds-own-keys = { $count ->
    [one] 1 eigener Schlüssel
   *[other] { $count } eigene Schlüssel
}
setup-holds-contact-keys = { $count ->
    [one] 1 Schlüssel eines Kontakts
   *[other] { $count } Schlüssel von Kontakten
}
setup-holds-rules = { $count ->
    [one] 1 Regel
   *[other] { $count } Regeln
}
setup-holds-trusted-senders = { $count ->
    [one] 1 vertrauenswürdiger Absender
   *[other] { $count } vertrauenswürdige Absender
}
setup-sign-in-password = Kennwort
setup-account-secret-password = Das Kennwort ist in der Datei gespeichert.
setup-account-secret-token = Die gespeicherten Anmeldedaten sind in der Datei enthalten.
setup-account-asks-password = Nach dem Import müssen Sie das Kennwort eingeben.
setup-account-signs-in-again = Nach dem Import müssen Sie sich erneut bei diesem Konto anmelden.
setup-account-here = Das Konto ist hier bereits eingerichtet und wird übersprungen.
setup-account-no-app = Dieses Konto benötigt die Anmelde-App { $app }, die hier noch nicht eingerichtet ist. Importieren Sie auch die Anmelde-Apps.
setup-invalid-address = „{ $address }“ ist keine E-Mail-Adresse.
setup-invalid-server = Der Servername oder Port für { $server } ist ungültig.
setup-invalid-user = Das Konto hat keinen Benutzernamen.
setup-invalid-sign-in = Inbox Classic unterstützt die Anmeldemethode dieses Kontos nicht.
setup-error-empty = Die Datei ist leer.
setup-error-too-large = Die Datei ist zu groß, um Einstellungen und Konten daraus zu importieren.
setup-error-not-setup = Diese Datei ist kein Export von Einstellungen und Konten aus Inbox Classic.
setup-error-damaged = Die Exportdatei ist beschädigt und kann nicht gelesen werden.
setup-error-newer = Die Exportdatei wurde mit einer neueren Version von Inbox Classic ({ $version }) erstellt. Aktualisieren Sie Inbox Classic und versuchen Sie den Import erneut.
setup-error-needs-passphrase = Diese Exportdatei ist mit einer Passphrase geschützt. Geben Sie die beim Export verwendete Passphrase ein.
setup-error-wrong-passphrase = Mit dieser Passphrase lässt sich die Exportdatei nicht öffnen.
setup-error-changed = Die Exportdatei wurde nach dem Speichern verändert oder beschädigt und kann daher nicht importiert werden.
setup-error-read = Die Exportdatei konnte nicht gelesen werden: { $error }
setup-error-write = Die Exportdatei konnte nicht gespeichert werden: { $error }
setup-error-no-parts = Wählen Sie mindestens einen Datenbereich aus.
setup-left-out = { $count ->
    [one] Aus dem Bereich „{ $part }“ wird 1 nicht verwendbarer Eintrag ausgelassen.
   *[other] Aus dem Bereich „{ $part }“ werden { $count } nicht verwendbare Einträge ausgelassen.
}
setup-imported-settings = Die Einstellungen wurden ersetzt.
setup-imported-preferences = Die Fenstereinstellungen wurden ersetzt.
setup-added-accounts = { $count ->
    [one] 1 Konto hinzugefügt.
   *[other] { $count } Konten hinzugefügt.
}
setup-skipped-here = Das Konto { $address } ist auf diesem Computer bereits eingerichtet und wurde nicht erneut importiert.
setup-skipped-no-app = { $address } wurde nicht importiert, weil die benötigte Anmelde-App { $app } hier nicht eingerichtet ist.
setup-skipped-invalid = { $address } wurde übersprungen: { $reason }
setup-asks-password = Beim Verbinden mit { $address } müssen Sie das Kennwort eingeben.
setup-signs-in-again = Für { $address } müssen Sie sich beim ersten Verbindungsaufbau erneut anmelden.
setup-added-sign-in-apps = { $count ->
    [one] 1 Anmelde-App hinzugefügt.
   *[other] { $count } Anmelde-Apps hinzugefügt.
}
setup-skipped-sign-in-apps = { $count ->
    [one] 1 Anmelde-App ist hier bereits eingerichtet.
   *[other] { $count } Anmelde-Apps sind hier bereits eingerichtet.
}
setup-added-contacts = { $count ->
    [one] 1 Kontakt zum Adressbuch hinzugefügt.
   *[other] { $count } Kontakte zum Adressbuch hinzugefügt.
}
setup-skipped-contacts = { $count ->
    [one] 1 Kontakt ist bereits im Adressbuch.
   *[other] { $count } Kontakte sind bereits im Adressbuch.
}
setup-added-groups = { $count ->
    [one] 1 Gruppe hinzugefügt oder ergänzt.
   *[other] { $count } Gruppen hinzugefügt oder ergänzt.
}
setup-added-own-keys = { $count ->
    [one] 1 eigenen Schlüssel hinzugefügt.
   *[other] { $count } eigene Schlüssel hinzugefügt.
}
setup-added-contact-keys = { $count ->
    [one] 1 Schlüssel eines Kontakts hinzugefügt.
   *[other] { $count } Schlüssel von Kontakten hinzugefügt.
}
setup-added-rules = { $count ->
    [one] 1 Nachrichtenregel hinzugefügt.
   *[other] { $count } Nachrichtenregeln hinzugefügt.
}
setup-skipped-rules = { $count ->
    [one] 1 Nachrichtenregel ist bereits vorhanden.
   *[other] { $count } Nachrichtenregeln sind bereits vorhanden.
}
setup-skipped-rules-account = { $count ->
    [one] 1 Nachrichtenregel wurde nicht importiert, weil das zugehörige Konto hier fehlt.
   *[other] { $count } Nachrichtenregeln wurden nicht importiert, weil die zugehörigen Konten hier fehlen.
}
setup-rules-waiting = { $count ->
    [one] Für 1 Nachrichtenregel steht der Zielordner erst nach der Kontosynchronisierung zur Verfügung.
   *[other] Die Zielordner von { $count } Nachrichtenregeln stehen erst nach der Synchronisierung der Konten zur Verfügung.
}
setup-added-trusted-senders = { $count ->
    [one] 1 vertrauenswürdigen Absender hinzugefügt.
   *[other] { $count } vertrauenswürdige Absender hinzugefügt.
}
setup-nothing = Es wurde nichts importiert.
setup-account-servers = { $imap } und { $smtp } ({ $signin })
setup-file-name = Inbox Classic - Einstellungen und Konten
setup-skipped-unreachable = { $name } wurde übersprungen: Der Anmeldedienst war nicht erreichbar. Fügen Sie die Anmelde-App unter „Anmelde-Apps“ erneut hinzu.
attachment-runs-programs = Die Datei „{ $name }“ kann Programme ausführen. Deshalb öffnet Inbox Classic sie nicht. Wenn Sie der Quelle vertrauen, können Sie die Datei speichern und selbst öffnen.
attachment-decrypted-note = Diese Anlage stammt aus einer verschlüsselten Nachricht. Zum Öffnen legt Inbox Classic eine unverschlüsselte Kopie in Ihrem temporären Ordner ab. Kopien, die älter als einen Tag sind, werden beim Start der App gelöscht.
undone-move = { $count ->
    [one] Der Server hat { $messages } nicht in { $folder } verschoben, daher ist sie wieder in { $from }: { $reason }
   *[other] Der Server hat { $messages } nicht in { $folder } verschoben, daher sind sie wieder in { $from }: { $reason }
}
undone-delete = { $count ->
    [one] Der Server hat { $messages } nicht gelöscht, daher ist sie wieder in { $from }: { $reason }
   *[other] Der Server hat { $messages } nicht gelöscht, daher sind sie wieder in { $from }: { $reason }
}
undone-archive = { $count ->
    [one] Der Server hat { $messages } nicht archiviert, daher ist sie wieder in { $from }: { $reason }
   *[other] Der Server hat { $messages } nicht archiviert, daher sind sie wieder in { $from }: { $reason }
}
undone-read = { $count ->
    [one] Der Server hat { $messages } nicht als gelesen markiert, daher ist sie wieder ungelesen: { $reason }
   *[other] Der Server hat { $messages } nicht als gelesen markiert, daher sind sie wieder ungelesen: { $reason }
}
undone-unread = { $count ->
    [one] Der Server hat { $messages } nicht als ungelesen markiert, daher ist sie wieder gelesen: { $reason }
   *[other] Der Server hat { $messages } nicht als ungelesen markiert, daher sind sie wieder gelesen: { $reason }
}
undone-flags = { $count ->
    [one] Der Server hat die Kennzeichnungen von { $messages } nicht geändert, daher ist sie wie zuvor: { $reason }
   *[other] Der Server hat die Kennzeichnungen von { $messages } nicht geändert, daher sind sie wie zuvor: { $reason }
}

## Previews of attachments: the pictures and PDF files shown in a message

# review: new
preview-pdf-option = PDF-Dateien in Nachrichten anzeigen
# review: new
preview-pdf-off = PDF-Dateien werden in Nachrichten nicht angezeigt.
# review: new
preview-pdf-off-crashed = Eine PDF-Datei hat Inbox Classic beim Anzeigen beendet, daher werden PDF-Dateien in Nachrichten nicht mehr angezeigt. Bilder werden weiterhin angezeigt. Um PDF-Dateien wieder anzuzeigen, aktivieren Sie { $option } unter { $settings }.
# review: new
preview-pdf-details = { $count ->
    [one] 1 Seite, { $size }
   *[other] { $count } Seiten, { $size }
}
# review: new
preview-page-alt = { $name }, Seite { $page } von { $count }
# review: new
preview-more-pages = { $count ->
    [one] Öffnen, um die Seite zu sehen
   *[other] Öffnen, um alle { $count } Seiten zu sehen
}
# review: new
preview-more-files = { $count ->
    [one] 1 weitere Datei steht in der Liste oben
   *[other] { $count } weitere Dateien stehen in der Liste oben
}
# review: new
preview-tile-downloading = Wird heruntergeladen…
# review: new
preview-tile-format = { $format }-Bilder werden noch nicht angezeigt
# review: new
preview-tile-password = Mit einem Kennwort geschützt: Öffnen, um das Kennwort einzugeben
# review: new
preview-tile-too-large = Zu groß zum Anzeigen
# review: new
preview-tile-unreadable = Kann nicht angezeigt werden
# review: new
preview-tile-timed-out = Das Anzeigen dauerte zu lange
# review: new
preview-tile-crashed = Nicht angezeigt: Die Datei hat Inbox Classic einmal beendet
# review: new
preview-tile-off = Nicht angezeigt, bis Inbox Classic neu gestartet wird
# review: new
preview-not-printed = { $name } ({ $details }) wird nicht gedruckt. Öffnen Sie die Datei, um sie zu drucken.
