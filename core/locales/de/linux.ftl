# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-looks-in = Die Suche in { $place } umfasst Betreff, Absender, Empfänger, Anlagennamen und Nachrichtentext. Prüfen Sie die Schreibweise oder versuchen Sie es mit weniger Wörtern.
gtk-search-still-indexing = { $count ->
    [one] Der Text einer Nachricht wird noch indiziert. Weitere Suchergebnisse können hinzukommen.
   *[other] Die Texte von { $count } Nachrichten werden noch indiziert. Weitere Suchergebnisse können hinzukommen.
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
gtk-import-one-question = Die Nachricht { $file } in den Ordner { $folder } importieren?
gtk-files-not-saved = Nicht gespeicherte Dateien: { $failed } von { $total }.
gtk-unsubscribe-one-click =
    Diese Mailingliste verlassen?

    Inbox Classic sendet eine Abmeldeanfrage an { $target }. Dabei wird keine Webseite geöffnet und keine E-Mail versendet.
gtk-unsubscribe-mail =
    Diese Mailingliste verlassen?

    Zum Abbestellen ist eine E-Mail an { $target } erforderlich. Inbox Classic bereitet sie für Sie vor. Senden Sie die Nachricht, um die Abmeldung abzuschließen.
gtk-unsubscribe-web =
    Diese Mailingliste verlassen?

    Die Abmeldeseite der Mailingliste wird im Browser geöffnet ({ $target }).
gtk-unsubscribe-failed = Abbestellen nicht möglich: { $problem }
gtk-toolbar-create-mail-menu = Nachricht von einem bestimmten Konto schreiben
gtk-toolbar-send-recv-menu = Nachrichten für ein bestimmtes Konto senden und empfangen
gtk-main-menu = Hauptmenü
gtk-folder-list = Ordnerliste
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

gtk-outbox-empty = Keine Nachrichten zum Senden vorhanden.
gtk-outbox-row = An: { $to }  ·  In Warteschlange seit: { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Inbox Classic prüft im Hintergrund auf neue E-Mails. Über das Symbol in der oberen Leiste können Sie das Programm öffnen oder beenden.
gtk-sign-in-again-ask = Die Anmeldung bei { $account } wurde abgelehnt oder die Sitzung ist abgelaufen.

    Im Browser erneut anmelden?
gtk-default-app-not-installed = Inbox Classic ist nicht installiert und wird deshalb vom System nicht als E-Mail-Programm aufgeführt. Installieren Sie Inbox Classic, um es als Standard auszuwählen.
gtk-default-app-now = Inbox Classic ist jetzt Ihr Standard-E-Mail-Programm: E-Mail-Links öffnen hier eine neue Nachricht.
gtk-default-app-failed = Inbox Classic konnte nicht als Standard-E-Mail-Programm festgelegt werden.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Datum:
gtk-reader-files = Anlagen der Nachricht
gtk-pictures-blocked = Einige Bilder wurden blockiert, damit der Absender Ihren Computer nicht erkennen kann.
gtk-download-pictures = Bilder herunterladen
gtk-save-attachments-menu = Anlagen speichern...

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
    Bei einer unverschlüsselten Verbindung können Personen, die den Netzwerkverkehr mitlesen, Ihr Passwort und Ihre E-Mails einsehen. Verwenden Sie diese Verbindung nur mit einem Server auf Ihrem eigenen Computer oder im lokalen Netzwerk.

    Fortfahren?
gtk-account-name-title = Kontoname
gtk-display-name-title = Anzeigename
gtk-turned-off-why = Die Option „{ $button }“ ist auf diesem Computer deaktiviert. { $reason }
gtk-turned-off-why-long =
    Die Option „{ $button }“ ist auf diesem Computer deaktiviert.

    { $reason }
gtk-next = Weiter >
gtk-provider-sign-in = Melden Sie sich für { $address } auf der Webseite von { $provider } an. Ihr Passwort wird nicht an Inbox Classic weitergegeben. Alternativ können Sie ein App-Passwort in den Sicherheitseinstellungen Ihres Kontos erstellen.
gtk-provider-sign-in-apps = Melden Sie sich für { $address } auf der Webseite von { $provider } mit einer Ihrer Anmelde-Apps an („Weitere Anmeldeoptionen“). Alternativ können Sie ein App-Passwort in den Sicherheitseinstellungen Ihres Kontos erstellen.
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
gtk-scopes = Berechtigungen (Scopes)
gtk-redirect-uri = Weiterleitungs-URI
gtk-issuer-usable =
    Der Aussteller kann verwendet werden.

    { $found }
gtk-app-built-in = { $app } ist integriert. Sie können nur festlegen, ob diese App für neue Konten angeboten wird. { $reason }
gtk-built-in = { $app } (integriert)
gtk-offered-for-new = Für neue Konten angeboten
gtk-edit-button = Bearbeiten...
gtk-remove-app-ask = Die Anmelde-App { $app } und ihr gespeichertes Client-Geheimnis entfernen?
gtk-sign-in-apps-intro = Anmelde-Apps ermöglichen die Anmeldung im Browser. Deaktivierte Apps werden für neue Konten nicht angeboten. Bestehende Konten können sie weiterhin verwenden.

## AI agents

gtk-agent-it-may = Erlaubte Aktionen
gtk-agent-accounts = Freigegebene Konten
gtk-never-used = Nie verwendet
gtk-last-used = Zuletzt verwendet { $date }
gtk-forget-program = Dieses Programm entfernen?
gtk-forget-program-detail = Die Berechtigungen des Programms und der Aktivitätsverlauf seiner Agenten werden gelöscht. Bei der nächsten Verbindung wird erneut um Erlaubnis gefragt.
gtk-no-agents-yet = Bisher hat kein Agent Zugriff auf Ihre E-Mails angefordert.
gtk-nothing-yet = Noch nichts.

## Preferences

gtk-preferences = Einstellungen
gtk-language = Sprache
gtk-language-subtitle = Sprache der Benutzeroberfläche und der Hilfe
gtk-new-mail-group = Neue E-Mail
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
gtk-notify-new-mail = Bei neuen Nachrichten benachrichtigen
gtk-notify-subtitle = Benachrichtigungen über neue Nachrichten erhalten, wenn das Fenster im Hintergrund ist
gtk-restart-to-change = Inbox Classic startet neu, um die Sprache zu ändern.
