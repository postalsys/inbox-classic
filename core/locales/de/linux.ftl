# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Preferences, Quit).

## The main window

gtk-search-mail = E-Mail durchsuchen
gtk-find-tip = Sucht Wörter im Betreff, in den Personen, in den Dateinamen und im Text der Nachrichten.
gtk-clear-search = Suche löschen
gtk-from-account = Von { $account }
gtk-the-account = dem Konto
gtk-column-folder = Ordner
gtk-column-account = Konto
gtk-search-looks-everywhere = Die Suche durchsucht Betreff, Personen, Dateinamen und Text der Nachrichten in allen Ordnern. Prüfen Sie die Schreibweise, oder versuchen Sie es mit weniger Wörtern.
gtk-search-looks-in = Die Suche durchsucht Betreff, Personen, Dateinamen und Text der Nachrichten in { $place }. Prüfen Sie die Schreibweise, oder versuchen Sie es mit weniger Wörtern.
gtk-search-still-indexing = { $count ->
    [one] Der Text von 1 Nachricht wird noch indiziert, es kann also bald mehr gefunden werden.
   *[other] Der Text von { $count } Nachrichten wird noch indiziert, es kann also bald mehr gefunden werden.
}
gtk-search-no-match = Keine Nachricht passt zu „{ $words }“.
gtk-list-empty = In dieser Ansicht gibt es keine Elemente.
gtk-list-choose-folder = Wählen Sie einen Ordner, um seine Nachrichten zu sehen.
gtk-all-inboxes = Alle Posteingänge
gtk-all-folders = Alle Ordner
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
gtk-toolbar-junk = Junk
gtk-toolbar-not-junk = Kein Junk
gtk-menu-rename = Umbenennen...
gtk-menu-delete = Löschen
gtk-new-folder-in-selected = Der neue Ordner wird im ausgewählten Ordner angelegt.
gtk-new-folder-at-top = Der neue Ordner wird auf der obersten Ebene des Kontos angelegt.
gtk-new-folder-title = Neuer Ordner
gtk-rename-folder-intro = Der neue Name des Ordners { $folder }.
gtk-rename-folder-title = Ordner umbenennen
gtk-delete-folder-question = Den Ordner „{ $folder }“ mit seinen Nachrichten und den Ordnern darin löschen? Er wird auch auf dem Server gelöscht.
gtk-not-downloaded = Die Nachricht ist noch nicht heruntergeladen.
gtk-mail-messages = E-Mail-Nachrichten
gtk-save-message-as = Nachricht speichern unter
gtk-message-not-saved = Die Nachricht konnte nicht gespeichert werden.
gtk-save-messages-in = Nachrichten speichern in
gtk-select-message-first = Wählen Sie zuerst eine Nachricht aus.
gtk-properties = Eigenschaften
gtk-properties-of = Eigenschaften von { $subject }
gtk-internet-headers = Internetkopfzeilen dieser Nachricht:
gtk-menu-open = Öffnen
gtk-menu-flag = Kennzeichnung
gtk-menu-view-source = Quelltext anzeigen
gtk-import-choose-folder = Wählen Sie zuerst den Ordner, in den die Nachrichten kommen sollen.
gtk-import-one-question = Die Nachricht { $file } in den Ordner { $folder } legen?
gtk-attachment-not-read = Die Anlage konnte nicht gelesen werden.
gtk-save-attachment-as = Anlage speichern unter
gtk-attachment-not-saved = Die Anlage konnte nicht gespeichert werden.
gtk-save-attachments = Anlagen speichern
gtk-files-not-saved = { $failed } der { $total } Dateien konnten nicht gespeichert werden.
gtk-invitation-not-read = Die Einladung konnte nicht gelesen werden.
gtk-no-calendar-program = Kein Kalenderprogramm auf diesem Computer öffnet Einladungen (.ics-Dateien).
gtk-cancel = Abbrechen
gtk-ok = OK
gtk-unsubscribe = Abbestellen
gtk-unsubscribe-one-click =
    Diese Mailingliste verlassen?

    Inbox Classic bittet { $target }, Ihnen nichts mehr zu senden. Es öffnet sich keine Seite und es wird keine Nachricht gesendet.
gtk-unsubscribing = { $target } wird abbestellt...
gtk-can-not-unsubscribe = Mit dieser Nachricht können Sie nicht abbestellen.
gtk-unsubscribe-mail =
    Diese Mailingliste verlassen?

    Die Liste möchte eine Nachricht an { $target }. Inbox Classic schreibt sie für Sie; senden Sie sie, um abzubestellen.
gtk-unsubscribe-web =
    Diese Mailingliste verlassen?

    Die Seite der Liste dafür öffnet sich in Ihrem Browser ({ $target }).
gtk-unsubscribed = Abbestellt. Die Liste sagt, dass sie diese E-Mails nicht mehr sendet.
gtk-unsubscribe-failed = Abbestellen nicht möglich: { $problem }
gtk-toolbar-create-mail = Neue E-Mail
gtk-toolbar-create-mail-menu = Eine Nachricht von einem Konto
gtk-toolbar-send-recv = Senden/Empfangen
gtk-toolbar-send-recv-menu = Ein Konto senden und empfangen
gtk-toolbar-reply = Antworten
gtk-toolbar-reply-all = Allen antworten
gtk-toolbar-forward = Weiterleiten
gtk-toolbar-print = Drucken
gtk-toolbar-delete = Löschen
gtk-toolbar-mark-read = Gelesen
gtk-toolbar-mark-unread = Ungelesen
gtk-main-menu = Hauptmenü
gtk-quit = Beenden
gtk-clear-flag = Kennzeichnung löschen

## The Move and Copy window

gtk-button-move = Verschieben
gtk-button-copy = Kopieren
gtk-find-folder = Ordner suchen
gtk-new-folder-in = Der neue Ordner wird in { $folder } angelegt.
gtk-new-folder-at-top-of = Der neue Ordner wird auf der obersten Ebene von { $account } angelegt.

## The message list

gtk-column-from = Von
gtk-column-subject = Betreff
gtk-column-received = Erhalten
gtk-column-size = Größe

## Help

gtk-help-title = Inbox Classic-Hilfe

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Keine ungelesenen Nachrichten
    [one] 1 ungelesene Nachricht
   *[other] { $count } ungelesene Nachrichten
}
gtk-done = Fertig

## The compose window's link menu

gtk-open-link = Link öffnen
gtk-edit-link = Link bearbeiten...
gtk-remove-link = Link entfernen

## The Outbox

gtk-no-subject = (kein Betreff)
gtk-outbox-title = Postausgang
gtk-outbox-empty = Nichts wartet auf das Senden.
gtk-outbox-send-all = Alle jetzt senden
gtk-outbox-delete = Löschen
gtk-outbox-delete-ask = Diese Nachricht löschen, ohne sie zu senden?
gtk-outbox-waiting = Wartet
gtk-outbox-not-sent = Nicht gesendet: { $reason }
gtk-outbox-agent = Von einem KI-Agenten gesendet; geht um { $time }
gtk-outbox-row = An: { $to }  ·  Eingereiht { $queued }  ·  { $status }

## The app

gtk-store-not-opened = Der E-Mail-Speicher konnte nicht geöffnet werden.
gtk-store-or-cert-not-opened = Der E-Mail-Speicher oder die Zertifikatsdatei konnte nicht geöffnet werden.
gtk-checking = Neue Nachrichten auf { $account } werden abgerufen...
gtk-sent-at = { $subject } um { $time } gesendet
gtk-draft-saved = Nachricht in Entwürfe gespeichert.
gtk-draft-not-saved = Die Nachricht wurde nicht in Entwürfe gespeichert: { $reason }
gtk-newest-from = Die neueste von { $sender }: { $subject }
gtk-new-messages = { $count } neue Nachrichten
gtk-outbox-waits = { $subject } wartet im Postausgang
gtk-outbox-sending = { $subject } wird gesendet...
gtk-outbox-count = { $count ->
    [one] 1 Nachricht im Postausgang
   *[other] { $count } Nachrichten im Postausgang
}
gtk-still-running = Inbox Classic läuft weiter
gtk-still-running-detail = Es ruft weiter neue E-Mails ab. Sein Symbol in der oberen Leiste öffnet es wieder oder beendet es.
gtk-add-account-first = Fügen Sie zuerst ein E-Mail-Konto hinzu.
gtk-add-account-first-link = Fügen Sie zuerst ein E-Mail-Konto hinzu und klicken Sie dann erneut auf den E-Mail-Link.
gtk-quoted = „{ $subject }“
gtk-sign-in-again-ask =
    Die Anmeldung von { $account } wurde abgelehnt oder ist abgelaufen.

    Im Browser erneut anmelden?
gtk-sign-in-again-failed = Die erneute Anmeldung hat nicht funktioniert: { $reason }
gtk-default-app-not-installed = Diese Kopie von Inbox Classic wurde nicht installiert, daher führt das System sie nicht als E-Mail-Programm. Installieren Sie sie, um sie auszuwählen.
gtk-default-app-is = Inbox Classic ist Ihr Standard-E-Mail-Programm: E-Mail-Links öffnen hier eine neue Nachricht.
gtk-default-app-now = Inbox Classic ist jetzt Ihr Standard-E-Mail-Programm: E-Mail-Links öffnen hier eine neue Nachricht.
gtk-default-app-failed = Inbox Classic konnte nicht als Standard-E-Mail-Programm festgelegt werden.
gtk-about-core = Kern { $version }

## Buttons and words used in many windows

gtk-yes = Ja
gtk-no = Nein
gtk-folder-name = Ordnername:
gtk-all-files = Alle Dateien

## The reading pane

gtk-reader-from = Von:
gtk-reader-to = An:
gtk-reader-date = Datum:
gtk-reader-files = Die Dateien der Nachricht
gtk-open-in-calendar = Im Kalender öffnen
gtk-pictures-blocked = Einige Bilder wurden blockiert, damit der Absender Ihren Computer nicht erkennen kann.
gtk-download-pictures = Bilder herunterladen
gtk-try-again = Erneut versuchen
gtk-message-not-shown = Die Nachricht konnte nicht angezeigt werden.
gtk-save-attachments-menu = Anlagen speichern...
gtk-no-title = (ohne Titel)
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
gtk-from-to = { $start } bis { $end }
gtk-day-and-time = { $day }, { $time }
gtk-senders-time = { $when } (Zeit des Absenders)

## The compose window

gtk-format-bold = Fett (Strg+B)
gtk-format-italic = Kursiv (Strg+I)
gtk-format-underline = Unterstrichen (Strg+U)
gtk-format-font-color = Schriftfarbe
gtk-format-numbered-list = Nummerierung
gtk-format-bulleted-list = Aufzählungszeichen
gtk-format-decrease-indent = Einzug verkleinern
gtk-format-increase-indent = Einzug vergrößern
gtk-format-align-left = Linksbündig
gtk-format-center = Zentriert
gtk-format-align-right = Rechtsbündig
gtk-format-hyperlink = Hyperlink (Strg+K)
gtk-format-insert-horizontal-line = Horizontale Linie einfügen
gtk-format-insert-picture = Bild einfügen
gtk-font = Schriftart
gtk-font-size = Größe
gtk-link-invalid = Geben Sie eine Webadresse (https://...) oder einen E-Mail-Link (mailto:...) ein.
gtk-edit-hyperlink = Hyperlink bearbeiten
gtk-edit-hyperlink-intro = Wohin der Link führt. Leeren Sie die Adresse, um den Link zu entfernen und seinen Text zu behalten.
gtk-hyperlink = Hyperlink
gtk-hyperlink-intro = Die Adresse, auf die der ausgewählte Text verweist.
gtk-link-address = Adresse:
gtk-pictures = Bilder
gtk-insert-picture = Bild einfügen
gtk-not-a-picture = Diese Datei ist kein PNG-, JPEG- oder GIF-Bild, oder sie ist größer als 10 MB.
gtk-show-cc = _Cc
gtk-show-bcc = _Bcc
gtk-compose-from = Von:
gtk-compose-to = An:
gtk-compose-cc = Cc:
gtk-compose-bcc = Bcc:
gtk-compose-subject = Betreff:
gtk-compose-attach = Anlage:
gtk-send = Senden
gtk-save-tip = Speichern (Strg+S)
gtk-attach-tip = Anfügen
gtk-new-message = Neue Nachricht
gtk-remove = Entfernen
gtk-link-status = { $link }    (Strg+Klick zum Öffnen)
gtk-insert-attachment = Anlage einfügen
gtk-saving-draft = Wird in Entwürfe gespeichert...
gtk-save-changes = Möchten Sie die Änderungen an dieser Nachricht in Entwürfe speichern?
gtk-not-saved-in-drafts = Nicht in Entwürfe gespeichert: { $reason }
gtk-saved-in-drafts-at = Um { $time } in Entwürfe gespeichert
gtk-signature-hint = Wird neuen Nachrichten, Antworten und Weiterleitungen von diesem Konto angefügt.
gtk-signature-of = Signatur - { $account }
gtk-signature = Signatur
gtk-signature-not-saved = Die Signatur konnte nicht gespeichert werden.

## Accounts

gtk-add-mail-account = E-Mail-Konto hinzufügen
gtk-account-not-saved = Das Konto konnte nicht gespeichert werden.
gtk-security-none = Keine (unverschlüsselt)
gtk-field-required = { $field } ist erforderlich.
gtk-address-not-valid = Die E-Mail-Adresse ist ungültig.
gtk-ports-are-numbers = Ports sind Zahlen von 1 bis 65535.
gtk-display-name = Anzeigename:
gtk-email-address = E-Mail-Adresse:
gtk-user-name = Benutzername:
gtk-password = Kennwort:
gtk-imap-server = Posteingangsserver (IMAP):
gtk-imap-port = IMAP-Port:
gtk-imap-security = IMAP-Sicherheit:
gtk-smtp-server = Postausgangsserver (SMTP):
gtk-smtp-port = SMTP-Port:
gtk-smtp-security = SMTP-Sicherheit:
gtk-plain-warning =
    Ohne Verschlüsselung gehen Ihr Kennwort und Ihre E-Mails lesbar für jeden auf dem Weg durch das Netz. Verwenden Sie das nur für einen Server auf Ihrem eigenen Computer oder in Ihrem Netzwerk.

    Fortfahren?
gtk-sign-in-with = Mit { $provider } anmelden
gtk-the-provider = Ihrem Anbieter
gtk-more-sign-in = Weitere Anmeldeoptionen...
gtk-display-name-title = Anzeigename
gtk-email-address-title = E-Mail-Adresse
gtk-other-account-intro = Jedes andere E-Mail-Konto: Ihr Name, wie andere ihn sehen, und Ihre E-Mail-Adresse. Seine Server werden als Nächstes gesucht.
gtk-type-address = Geben Sie Ihre E-Mail-Adresse ein, name@example.com.
gtk-turned-off-why = { $button } ist auf diesem Computer ausgeschaltet. { $reason }
gtk-turned-off-why-long =
    { $button } ist auf diesem Computer ausgeschaltet.

    { $reason }
gtk-turned-off = Auf diesem Computer ausgeschaltet.
gtk-why = Warum?
gtk-add-sign-in-app = Anmelde-App hinzufügen...
gtk-browser-sign-in-not-started = Die Anmeldung über den Browser konnte nicht starten.
gtk-sign-in-in-browser = Melden Sie sich im geöffneten Browserfenster bei { $account } an und kehren Sie dann hierher zurück.
gtk-sign-in-in-browser-yours = Melden Sie sich im geöffneten Browserfenster bei Ihrem Konto an und kehren Sie dann hierher zurück.
gtk-signing-in-failed = Die Anmeldung hat nicht funktioniert: { $reason }
gtk-looking-up = Die Einstellungen von { $domain } werden gesucht...
gtk-found-none = Geben Sie die Kontodaten ein, die Ihr E-Mail-Anbieter Ihnen gegeben hat.
gtk-found-guess = Für diese Adresse wurden keine Einstellungen gefunden: Dies sind die üblichen Namen, prüfen Sie sie bei Ihrem Anbieter.
gtk-found-mx = Ihre E-Mail wird von einem Anbieter betreut, den Inbox Classic kennt; dies sind seine Server.
gtk-found-srv = Diese Einstellungen wurden in den DNS-Einträgen Ihrer Domain gefunden.
gtk-found-autodiscover = Diese Einstellungen wurden von Microsoft Autodiscover (Exchange) gefunden.
gtk-found-other = Diese Einstellungen wurden für diese Adresse gefunden.
gtk-found-change = Ändern Sie sie, wenn Ihr Anbieter Ihnen andere gegeben hat.
gtk-app-password-needed = { $provider } nimmt Ihr normales Kennwort in E-Mail-Programmen nicht an. Erstellen Sie in Ihrem { $provider }-Konto ein App-Kennwort und geben Sie es im Feld Kennwort des nächsten Formulars ein.
gtk-open-instructions = Die Anleitung von { $provider } im Browser öffnen?
gtk-start-intro = Gmail, Google Workspace, Outlook.com und Microsoft 365: Melden Sie sich auf der Seite von Google oder Microsoft an. Ihr Kennwort geben Sie dort ein, nie in Inbox Classic.
gtk-start-intro-apps = Melden Sie sich über den Browser mit einer Ihrer Anmelde-Apps an (Weitere Anmeldeoptionen), oder fügen Sie ein beliebiges E-Mail-Konto mit Ihrem Namen und Ihrer Adresse unten hinzu.
gtk-next = Weiter >
gtk-provider-sign-in = { $address } meldet sich auf der Seite von { $provider } an, ohne Inbox Classic Ihr Kennwort zu geben. Oder verwenden Sie ein App-Kennwort aus den Sicherheitseinstellungen Ihres Kontos.
gtk-provider-sign-in-apps = { $address } kann sich auf der Seite von { $provider } mit einer Ihrer Anmelde-Apps anmelden (Weitere Anmeldeoptionen). Oder verwenden Sie ein App-Kennwort aus den Sicherheitseinstellungen Ihres Kontos.
gtk-use-app-password = App-Kennwort verwenden
gtk-finish = Fertig stellen
gtk-enter-password = Geben Sie das Kennwort von { $account } ein.
gtk-logon = Anmelden
gtk-signs-in-with = Meldet sich an mit: { $app }. Es meldet sich über den Browser an und verwendet die Server seiner Anmeldung.
gtk-keep-password = Lassen Sie das Kennwort leer, um das bisherige zu behalten.
gtk-browser-sign-in-server = { $server } (Anmeldung im Browser)
gtk-accounts-add = Hinzufügen...
gtk-accounts-properties = Eigenschaften...
gtk-accounts-signature = Signatur...
gtk-accounts-sign-in-apps = Anmelde-Apps...
gtk-accounts-title = Konten
gtk-remove-account = Konto entfernen
gtk-remove-account-ask = Dieses Konto aus Inbox Classic entfernen? Seine E-Mails bleiben auf dem Server; die Kopie auf diesem Computer und das gespeicherte Kennwort werden entfernt.

## Sign-in apps

gtk-sign-in-app = Anmelde-App
gtk-remove-sign-in-app = Anmelde-App entfernen
gtk-check = Prüfen
gtk-app-server = { $kind }-Server
gtk-app-port = { $kind }-Port
gtk-app-security = { $kind }-Sicherheit
gtk-preset-name = Anmelde-App für { $provider }
gtk-checking-issuer = { $issuer } wird geprüft...
gtk-issuer-found =
    Anmeldeseite: { $page }
    Token-Endpunkt: { $endpoint }
gtk-app-editor-intro = Ein OAuth-Client, den Sie bei Ihrem Anbieter registriert haben, für Konten, die sich über den Browser anmelden. Füllen Sie ihn für einen Anbieter aus und fügen Sie dann die Client-ID hinzu (und das Geheimnis, falls der Anbieter eines vergeben hat).
gtk-fill-in-for = Ausfüllen für:
gtk-app-name = Name
gtk-issuer = Aussteller
gtk-client-id = Client-ID
gtk-client-secret = Client-Geheimnis
gtk-secret-saved = Ein Geheimnis ist gespeichert; geben Sie ein anderes ein, um es zu ersetzen, oder entfernen Sie es
gtk-scopes = Bereiche (Scopes)
gtk-register-it = Registrieren Sie ihn bei Ihrem Anbieter
gtk-redirect-uri = Umleitungs-URI
gtk-copy-button = Kopieren
gtk-add-sign-in-app-title = Anmelde-App hinzufügen
gtk-issuer-usable =
    Der Aussteller kann verwendet werden.

    { $found }
gtk-issuer-not-usable = Der Aussteller kann nicht verwendet werden: { $reason }
gtk-app-not-saved = Die Anmelde-App konnte nicht gespeichert werden: { $reason }
gtk-app-built-in = { $app } ist eingebaut: Nur ob sie für neue Konten verwendet wird, lässt sich ändern. { $reason }
gtk-client-with-secret = Client-ID: { $client }, mit einem Client-Geheimnis.
gtk-client-public = Client-ID: { $client }, ein öffentlicher Client (ohne Geheimnis).
gtk-no-accounts = Keine Konten
gtk-built-in = { $app } (eingebaut)
gtk-offered-for-new = Für neue Konten angeboten
gtk-edit-button = Bearbeiten...
gtk-sign-in-apps-title = Anmelde-Apps
gtk-remove-app-ask = Die Anmelde-App { $app } und ihr gespeichertes Client-Geheimnis entfernen?
gtk-app-not-removed = Die Anmelde-App wurde nicht entfernt: { $reason }
gtk-sign-in-apps-intro = Mit Anmelde-Apps melden sich Konten über den Browser an. Eine ausgeschaltete wird für neue Konten nicht angeboten; Konten, die sie schon verwenden, funktionieren weiter.

## AI agents

gtk-agent-program = Programm: { $path }
gtk-agent-it-may = Es darf
gtk-agent-accounts = Konten, die es verwenden darf
gtk-dont-allow = Nicht erlauben
gtk-allow = Erlauben
gtk-dont-send = Nicht senden
gtk-edit-first = Erst bearbeiten
gtk-new-address = Neue Adresse
gtk-never-used = Nie verwendet
gtk-last-used = Zuletzt verwendet { $date }
gtk-turn-away = Abweisen
gtk-forget-program = Dieses Programm vergessen?
gtk-forget-program-detail = Es wird beim nächsten Verbinden erneut gefragt, und was seine Agenten getan haben, wird vergessen.
gtk-ai-agents = KI-Agenten
gtk-clear-agent-log = Die Liste dessen, was Agenten getan haben, leeren?
gtk-clear-agent-log-detail = Was sie getan haben, bleibt getan.
gtk-let-agents-connect = KI-Agenten mit Inbox Classic verbinden lassen
gtk-no-agents-yet = Noch hat kein Agent gefragt, Ihre E-Mails verwenden zu dürfen.
gtk-nothing-yet = Noch nichts.
gtk-change-button = Ändern…
gtk-undo-button = Rückgängig
gtk-clear-button = Leeren
gtk-how-to-connect = So verbinden Sie einen Agenten…
gtk-agent-programs = Programme, deren Agenten Ihre E-Mails verwenden wollten
gtk-what-agents-did = Was Agenten getan haben
gtk-connect-agent = Einen KI-Agenten verbinden
gtk-connect-agent-intro = Fügen Sie dies den MCP-Servern Ihres Agenten hinzu (Claude Desktop: Settings > Developer > Edit Config):

## Preferences

gtk-preferences = Einstellungen
gtk-language = Sprache
gtk-language-subtitle = Die Wörter der Fenster und der Hilfe
gtk-system-default = Systemstandard ({ $language })
gtk-new-mail-group = Neue E-Mail
gtk-notify-subtitle = Eine Benachrichtigung, wenn neue Nachrichten eintreffen, während das Fenster im Hintergrund ist
gtk-restart-to-change = Inbox Classic startet neu, um die Sprache zu ändern.
gtk-restart-now = Jetzt neu starten
gtk-restart-later = Später
