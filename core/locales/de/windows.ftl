# Die Wörter der Fenster der Windows-App (app/src), Kennungen mit win- am Anfang. Platzhalter in { $Klammern } füllt die
# App; ein & markiert den Buchstaben eines Menüpunkts oder einer Schaltfläche (&& ist ein kaufmännisches Und).

## Das Hauptfenster

win-still-running-detail = Inbox Classic prüft im Hintergrund auf neue E-Mails. Klicken Sie zum Öffnen auf das Symbol. Zum Beenden öffnen Sie mit der rechten Maustaste das Symbolmenü.
win-new-messages = { $count ->
    [one] { $count } neue Nachricht
   *[other] { $count } neue Nachrichten
}
win-default-app-not-installed = Inbox Classic ist nicht installiert und wird deshalb von Windows nicht als E-Mail-Programm aufgeführt. Installieren Sie Inbox Classic, um es als Standard auszuwählen.
win-default-app-settings = Windows öffnet die Einstellungen für Standard-Apps. Legen Sie dort Inbox Classic zum Öffnen von MAILTO-Links fest.
win-no-unread = Keine ungelesenen Nachrichten
win-unread-messages = { $count ->
    [one] { $count } ungelesene Nachricht
   *[other] { $count } ungelesene Nachrichten
}
win-print-failed = Die Nachricht konnte nicht gedruckt werden.
win-print-title-of = Drucken: { $subject }
win-no-bodies = Nachrichtentexte können nicht angezeigt werden.
win-webview-failed = WebView2 konnte nicht erstellt werden.
win-webview-missing = Die WebView2-Laufzeit ist nicht verfügbar.

## Schaltflächen und Wörter vieler Fenster

win-delete-button = &Löschen
win-find-label = &Suchen:
win-col-to = An
win-save-as-button = Speichern &unter...
win-too-many-files = Zu viele Dateien auf einmal: Wählen Sie weniger aus.

## Der Postausgang


## Das Fenster zum Schreiben

win-editor-failed = Nachrichten können nicht geschrieben werden.
win-ctrl-click-to-open = ({ $ctrl }+Klick zum Öffnen)
win-format-bold = Fett ({ $ctrl }+B)
win-format-italic = Kursiv ({ $ctrl }+I)
win-format-underline = Unterstrichen ({ $ctrl }+U)
win-format-link = Hyperlink ({ $ctrl }+K)
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature-title = Signatur: { $account }

## Die Ordner, die Nachrichtenliste und der Lesebereich

win-search-found-all = { $count ->
    [0] Keine Ergebnisse für „{ $words }“ in allen Ordnern
    [one] { $count } Ergebnis für „{ $words }“ in allen Ordnern
   *[other] { $count } Ergebnisse für „{ $words }“ in allen Ordnern
}
win-search-found-in = { $count ->
    [0] Keine Ergebnisse für „{ $words }“ in { $folder }
    [one] { $count } Ergebnis für „{ $words }“ in { $folder }
   *[other] { $count } Ergebnisse für „{ $words }“ in { $folder }
}
win-search-indexing = { $count ->
    [one] der Text von { $count } Nachricht wird noch indiziert
   *[other] der Text von { $count } Nachrichten wird noch indiziert
}
win-no-match-indexing = { $count ->
    [one] Der Text einer Nachricht wird noch indiziert. Weitere Suchergebnisse können hinzukommen.
   *[other] Die Texte von { $count } Nachrichten werden noch indiziert. Weitere Suchergebnisse können hinzukommen.
}
win-files = { $count ->
    [one] { $count } Datei
   *[other] { $count } Dateien
}
win-click-to-retry = Klicken Sie hier, um es erneut zu versuchen.
win-save-attachments = Anlagen &speichern...
win-files-not-saved = Nicht gespeicherte Dateien: { $failed } von { $count }.
win-attendees = { $count ->
    [one] { $count } Teilnehmer
   *[other] { $count } Teilnehmer
}
win-new-folder-in-highlighted = Der neue Ordner wird im ausgewählten Ordner angelegt.
win-delete-folder-ask = Den Ordner „{ $folder }“ mit allen Nachrichten und Unterordnern löschen? Diese werden auch auf dem Server gelöscht.
win-rename = &Umbenennen...
win-messages-not-saved = Die Nachrichten konnten nicht gespeichert werden.
win-messages-not-forwarded = Die Nachrichten konnten nicht weitergeleitet werden.

## Konten

win-sign-in-google = Mit Google anmelden
win-sign-in-microsoft = Mit Microsoft anmelden
win-next = &Weiter >
win-your-account = Ihr Konto
win-browser-sign-in = (Anmeldung im Browser)
win-add = &Hinzufügen...
win-properties-button = &Eigenschaften...
win-signature-button = &Signatur...
win-sign-in-apps-button = &Anmelde-Apps...

## KI-Agenten

win-dont-allow = &Nicht zulassen
win-col-address = Adresse
win-never-written-to = Nie angeschrieben
win-send = &Senden
win-dont-send = &Nicht senden
win-forget-program-ask = Dieses Programm mit seinen Berechtigungen und dem Aktivitätsverlauf seiner Agenten entfernen? Bei der nächsten Verbindung wird erneut um Erlaubnis gefragt.
win-clear-log-ask = Aktivitätsverlauf der Agenten löschen? Die vorgenommenen Änderungen werden dadurch nicht rückgängig gemacht.
win-agent-programs = &Programme, deren Agenten Zugriff auf Ihre E-Mails angefordert haben:
win-change = Ä&ndern...
win-what-agents-did = &Aktivitätsverlauf der Agenten:
win-how-to-connect = So verbinden Sie einen Agenten

## Anmelde-Apps

win-built-in = (integriert)
win-edit = &Bearbeiten...

## Optionen

win-options-language-label = &Sprache von Inbox Classic:
win-options-restart-note = Die neue Sprache wird nach einem Neustart von Inbox Classic übernommen.
win-options-notify = Bei neuer E-Mail &benachrichtigen
win-restart-ask = Nach einem Neustart wird Inbox Classic auf { $language } angezeigt. Jetzt neu starten?
