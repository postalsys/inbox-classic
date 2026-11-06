# Die Wörter der Fenster der Windows-App (app/src), Kennungen mit win- am Anfang. Platzhalter in { $Klammern } füllt die
# App; ein & markiert den Buchstaben eines Menüpunkts oder einer Schaltfläche (&& ist ein kaufmännisches Und).

## Das Hauptfenster

win-still-running-detail = Es sucht hier weiter nach neuer E-Mail. Klicken Sie auf das Symbol, um es zu öffnen, oder klicken Sie mit der rechten Maustaste darauf, um es zu beenden.
win-new-messages = { $count ->
    [one] { $count } neue Nachricht
   *[other] { $count } neue Nachrichten
}
win-default-app-not-installed = Diese Kopie von Inbox Classic wurde nicht installiert, deshalb führt Windows sie nicht als E-Mail-Programm. Installieren Sie sie, um sie auszuwählen.
win-default-app-settings = Windows öffnet seine Einstellungen für Standard-Apps bei Inbox Classic. Wählen Sie es dort für MAILTO.
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
    [one] Der Text von { $count } Nachricht wird noch indiziert, es kann also bald mehr gefunden werden.
   *[other] Der Text von { $count } Nachrichten wird noch indiziert, es kann also bald mehr gefunden werden.
}
win-files = { $count ->
    [one] { $count } Datei
   *[other] { $count } Dateien
}
win-click-to-retry = Klicken Sie hier, um es erneut zu versuchen.
win-save-attachments = Anlagen &speichern...
win-files-not-saved = { $failed } der { $count } Dateien konnten nicht gespeichert werden.
win-attendees = { $count ->
    [one] { $count } Teilnehmer
   *[other] { $count } Teilnehmer
}
win-new-folder-in-highlighted = Der neue Ordner kommt in den hervorgehobenen Ordner.
win-delete-folder-ask = Den Ordner „{ $folder }“ mit seinen Nachrichten und den Ordnern darin löschen? Er wird auch auf dem Server gelöscht.
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
win-forget-program-ask = Dieses Programm vergessen und was seine Agenten getan haben? Beim nächsten Verbinden wird erneut gefragt.
win-clear-log-ask = Die Liste dessen löschen, was Agenten getan haben? Was sie getan haben, bleibt getan.
win-agent-programs = &Programme, deren Agenten Ihre E-Mail verwenden wollten:
win-change = Ä&ndern...
win-what-agents-did = &Was Agenten getan haben:
win-how-to-connect = So verbinden Sie einen Agenten

## Anmelde-Apps

win-built-in = (eingebaut)
win-edit = &Bearbeiten...

## Optionen

win-options-language-label = Inbox Classic &anzeigen in:
win-options-restart-note = Inbox Classic startet neu, um eine andere Sprache anzuzeigen.
win-options-notify = Bei neuer E-Mail &benachrichtigen
win-restart-ask = Inbox Classic zeigt { $language } nach einem Neustart an. Jetzt neu starten?
