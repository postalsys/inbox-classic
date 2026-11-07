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
reader-failed = Die Nachricht konnte nicht heruntergeladen werden
reader-failed-network = Der Mailserver war nicht erreichbar ({ $reason }).
reader-failed-sign-in = Der Mailserver hat die Anmeldung nicht angenommen ({ $reason }). Prüfen Sie das Passwort oder melden Sie sich unter Datei > Konten erneut an.
reader-failed-security = Es konnte keine sichere Verbindung zum Mailserver hergestellt werden ({ $reason }).
reader-failed-other = Der Mailserver antwortete: { $reason }.
reader-retry-note = Noch nicht heruntergeladen. Der Download wird erneut versucht, sobald die Verbindung zum Konto wiederhergestellt ist.
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
quote-original = ----- Ursprüngliche Nachricht -----
fold-show-earlier = Frühere Nachrichten anzeigen

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
# review: new
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
their-folders = die jeweiligen Ordner
undo-move = Verschieben rückgängig machen
undo-delete = Löschen rückgängig machen
# review: new
undo-archive = Archivieren rückgängig machen
undo-junk = Als Junk markieren rückgängig machen
undo-not-junk = Als Nicht-Junk markieren rückgängig machen
nothing-to-undo = Es gibt nichts rückgängig zu machen.
messages-gone = Die Nachrichten sind nicht mehr da.
folder-holds-no-messages = In diesem Ordner können keine Nachrichten gespeichert werden.
# review: new
not-archived-here = Nachrichten in diesem Ordner können nicht archiviert werden.
# review: new
not-emptied-here = Nur Gelöschte Objekte und Junk-E-Mail können geleert werden.
# review: new
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
error-in-use = die App kann nicht entfernt werden, da folgende Konten sie verwenden: { $accounts }
error-turned-off = diese Anmelde-App ist für neue Konten ausgeschaltet
error-folder-name = der Ordnername muss 1 bis 200 Zeichen lang sein und darf keine Steuerzeichen enthalten
error-folder-separator = ein Ordnername darf auf diesem Server kein „{ $separator }“ enthalten
error-folder-special = der Posteingang und die Spezialordner können nicht umbenannt oder gelöscht werden
error-no-recipients = die Nachricht hat keine Empfänger
error-bad-address = „{ $address }“ ist keine E-Mail-Adresse
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
error-sent-no-copy = es konnte keine Kopie in Gesendete Objekte gespeichert werden: { $reason }
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

agent-level-read = E-Mail lesen: Ordner, Nachrichtenliste, Suche und Nachrichten
agent-level-organize = E-Mails verwalten: Lesestatus und Kennzeichnungen ändern, Junk verwalten, Nachrichten verschieben und löschen. Gelöschte Nachrichten landen im Ordner Gelöschte Objekte.
agent-level-drafts = Entwürfe erstellen, die Sie selbst senden
agent-level-send = E-Mail senden, jede Nachricht erst nach Ihrer Zustimmung
agent-connect-title = { $program } möchte Ihre E-Mail verwenden
agent-connect-detail = Ein KI-Agent möchte mit Inbox Classic arbeiten. Wählen Sie, was er tun darf und welche Konten er sehen darf; Sie können das später unter Extras > KI-Agenten ändern.

    Agenten lesen E-Mail, die andere geschrieben haben, und eine Nachricht kann versuchen, sie zu täuschen. Inbox Classic fragt Sie immer, bevor ein Agent etwas sendet.
agent-reply-to = Antwort auf „{ $subject }“
agent-reply-all-on = Antwort an alle auf „{ $subject }“
agent-forward-of = Weiterleitung von „{ $subject }“
agent-never-written-one = Sie haben noch nie an { $address } geschrieben.
agent-never-written-many = Sie haben noch nie an { $count } dieser Adressen geschrieben.
agent-send-title = { $program } möchte diese Nachricht senden
agent-send-detail = Prüfen Sie die Empfänger und den Inhalt. Nach Ihrer Bestätigung wartet die Nachricht { $seconds } Sekunden im Postausgang. Dort können Sie sie noch löschen.
agent-change-title = Was { $program } tun darf
agent-change-allowed = Ändern Sie, was die KI-Agenten dieses Programms mit Ihrer E-Mail tun dürfen.
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
agent-can-organize = ordnen
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
agent-log-composed = „{ $subject }“ in einer neuen Nachricht zum Fertigstellen geöffnet
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
# review: new
agent-log-archived = „{ $subject }“ archiviert
agent-log-folder = Ordner „{ $name }“ erstellt
agent-log-unsubscribed = Mailingliste der Nachricht „{ $subject }“ abbestellt

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
# review: new
cards-file-too-big = Diese Datei ist zu groß für ein Adressbuch.
