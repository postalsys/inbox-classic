# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = Die Suche durchsucht Betreff, Personen, Dateinamen und Text der Nachrichten in { $place }. Prüfen Sie die Schreibweise, oder versuchen Sie es mit weniger Wörtern.
gtk-search-still-indexing = { $count ->
    [one] Der Text von 1 Nachricht wird noch indiziert, es kann also bald mehr gefunden werden.
   *[other] Der Text von { $count } Nachrichten wird noch indiziert, es kann also bald mehr gefunden werden.
}
gtk-search-results-everywhere = { $count ->
    [0] Keine Ergebnisse
    [one] 1 Ergebnis
   *[other] { $count } Ergebnisse
} für „{ $words }“ in allen Ordnern
gtk-search-results-in = { $count ->
    [0] Keine Ergebnisse
    [one] 1 Ergebnis
   *[other] { $count } Ergebnisse
} für „{ $words }“ in { $place }
gtk-search-indexing = { $count ->
    [one] der Text von 1 Nachricht wird noch indiziert
   *[other] der Text von { $count } Nachrichten wird noch indiziert
}
gtk-menu-rename = Umbenennen...
gtk-import-one-question = Die Nachricht { $file } in den Ordner { $folder } legen?
gtk-files-not-saved = { $failed } der { $total } Dateien konnten nicht gespeichert werden.
gtk-unsubscribe-one-click =
    Diese Mailingliste verlassen?

    Inbox Classic bittet { $target }, Ihnen nichts mehr zu senden. Es öffnet sich keine Seite und es wird keine Nachricht gesendet.
gtk-unsubscribe-mail =
    Diese Mailingliste verlassen?

    Die Liste möchte eine Nachricht an { $target }. Inbox Classic schreibt sie für Sie; senden Sie sie, um abzubestellen.
gtk-unsubscribe-web =
    Diese Mailingliste verlassen?

    Die Seite der Liste dafür öffnet sich in Ihrem Browser ({ $target }).
gtk-unsubscribe-failed = Abbestellen nicht möglich: { $problem }
gtk-toolbar-create-mail-menu = Eine Nachricht von einem Konto
gtk-toolbar-send-recv-menu = Ein Konto senden und empfangen
gtk-main-menu = Hauptmenü
gtk-quit = Beenden

## The Move and Copy window

gtk-new-folder-at-top-of = Der neue Ordner wird auf der obersten Ebene von { $account } angelegt.

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Keine ungelesenen Nachrichten
    [one] 1 ungelesene Nachricht
   *[other] { $count } ungelesene Nachrichten
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Nichts wartet auf das Senden.
gtk-outbox-row = An: { $to }  ·  Eingereiht { $queued }  ·  { $status }

## The app

gtk-new-messages = { $count } neue Nachrichten
gtk-still-running-detail = Es ruft weiter neue E-Mails ab. Sein Symbol in der oberen Leiste öffnet es wieder oder beendet es.
gtk-sign-in-again-ask =
    Die Anmeldung von { $account } wurde abgelehnt oder ist abgelaufen.

    Im Browser erneut anmelden?
gtk-default-app-not-installed = Diese Kopie von Inbox Classic wurde nicht installiert, daher führt das System sie nicht als E-Mail-Programm. Installieren Sie sie, um sie auszuwählen.
gtk-default-app-now = Inbox Classic ist jetzt Ihr Standard-E-Mail-Programm: E-Mail-Links öffnen hier eine neue Nachricht.
gtk-default-app-failed = Inbox Classic konnte nicht als Standard-E-Mail-Programm festgelegt werden.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Datum:
gtk-reader-files = Die Dateien der Nachricht
gtk-pictures-blocked = Einige Bilder wurden blockiert, damit der Absender Ihren Computer nicht erkennen kann.
gtk-download-pictures = Bilder herunterladen
gtk-save-attachments-menu = Anlagen speichern...
gtk-invitation = { $kind ->
    [update] Geänderte Einladung: { $summary }
    [cancel] Abgesagt: { $summary }
    [reply] Antwort auf eine Einladung: { $summary }
   *[request] Einladung: { $summary }
}
gtk-organizer = Organisator: { $organizer }
gtk-attendees = { $count ->
    [one] 1 Teilnehmer
   *[other] { $count } Teilnehmer
}
gtk-day-and-time = { $day }, { $time }

## The compose window

gtk-format-bold = Fett (Strg+B)
gtk-format-italic = Kursiv (Strg+I)
gtk-format-underline = Unterstrichen (Strg+U)
gtk-format-hyperlink = Hyperlink (Strg+K)
gtk-font = Schriftart
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-save-tip = Speichern (Strg+S)
gtk-link-status = { $link }    (Strg+Klick zum Öffnen)

## Accounts

gtk-plain-warning =
    Ohne Verschlüsselung gehen Ihr Kennwort und Ihre E-Mails lesbar für jeden auf dem Weg durch das Netz. Verwenden Sie das nur für einen Server auf Ihrem eigenen Computer oder in Ihrem Netzwerk.

    Fortfahren?
gtk-display-name-title = Anzeigename
gtk-turned-off-why = { $button } ist auf diesem Computer ausgeschaltet. { $reason }
gtk-turned-off-why-long =
    { $button } ist auf diesem Computer ausgeschaltet.

    { $reason }
gtk-next = Weiter >
gtk-provider-sign-in = { $address } meldet sich auf der Seite von { $provider } an, ohne Inbox Classic Ihr Kennwort zu geben. Oder verwenden Sie ein App-Kennwort aus den Sicherheitseinstellungen Ihres Kontos.
gtk-provider-sign-in-apps = { $address } kann sich auf der Seite von { $provider } mit einer Ihrer Anmelde-Apps anmelden (Weitere Anmeldeoptionen). Oder verwenden Sie ein App-Kennwort aus den Sicherheitseinstellungen Ihres Kontos.
gtk-accounts-add = Hinzufügen...
gtk-accounts-properties = Eigenschaften...
gtk-accounts-signature = Signatur...
gtk-accounts-sign-in-apps = Anmelde-Apps...

## Sign-in apps

gtk-app-server = { $kind }-Server
gtk-app-port = { $kind }-Port
gtk-app-security = { $kind }-Sicherheit
gtk-issuer-found =
    Anmeldeseite: { $page }
    Token-Endpunkt: { $endpoint }
gtk-client-id = Client-ID
gtk-client-secret = Client-Geheimnis
gtk-scopes = Bereiche (Scopes)
gtk-redirect-uri = Umleitungs-URI
gtk-issuer-usable =
    Der Aussteller kann verwendet werden.

    { $found }
gtk-app-built-in = { $app } ist eingebaut: Nur ob sie für neue Konten verwendet wird, lässt sich ändern. { $reason }
gtk-built-in = { $app } (eingebaut)
gtk-offered-for-new = Für neue Konten angeboten
gtk-edit-button = Bearbeiten...
gtk-remove-app-ask = Die Anmelde-App { $app } und ihr gespeichertes Client-Geheimnis entfernen?
gtk-sign-in-apps-intro = Mit Anmelde-Apps melden sich Konten über den Browser an. Eine ausgeschaltete wird für neue Konten nicht angeboten; Konten, die sie schon verwenden, funktionieren weiter.

## AI agents

gtk-agent-it-may = Es darf
gtk-agent-accounts = Konten, die es verwenden darf
gtk-never-used = Nie verwendet
gtk-last-used = Zuletzt verwendet { $date }
gtk-forget-program = Dieses Programm vergessen?
gtk-forget-program-detail = Es wird beim nächsten Verbinden erneut gefragt, und was seine Agenten getan haben, wird vergessen.
gtk-no-agents-yet = Noch hat kein Agent gefragt, Ihre E-Mails verwenden zu dürfen.
gtk-nothing-yet = Noch nichts.

## Preferences

gtk-preferences = Einstellungen
gtk-language = Sprache
gtk-language-subtitle = Die Wörter der Fenster und der Hilfe
gtk-new-mail-group = Neue E-Mail
gtk-notify-subtitle = Eine Benachrichtigung, wenn neue Nachrichten eintreffen, während das Fenster im Hintergrund ist
gtk-restart-to-change = Inbox Classic startet neu, um die Sprache zu ändern.
