# Die Wörter der Fenster der Windows-App (app/src), Kennungen mit win- am Anfang. Platzhalter in { $Klammern } füllt die
# App; ein & markiert den Buchstaben eines Menüpunkts oder einer Schaltfläche (&& ist ein kaufmännisches Und).

## Das Hauptfenster

win-tb-create-mail = Neue E-Mail
win-tb-reply = Antworten
win-tb-reply-all = Allen antw.
win-tb-forward = Weiterleiten
win-tb-print = Drucken
win-tb-delete = Löschen
win-tb-junk = Junk
win-tb-not-junk = Kein Junk
win-tb-sync = Senden/Empfangen
win-tb-mark-read = Gelesen
win-tb-mark-unread = Ungelesen
win-flag-menu = &Kennzeichnung
win-still-running = Inbox Classic läuft weiter
win-still-running-detail = Es sucht hier weiter nach neuer E-Mail. Klicken Sie auf das Symbol, um es zu öffnen, oder klicken Sie mit der rechten Maustaste darauf, um es zu beenden.
win-no-subject = (kein Betreff)
win-quoted = „{ $subject }“
win-new-messages = { $count ->
    [one] { $count } neue Nachricht
   *[other] { $count } neue Nachrichten
}
win-newest-from = Die neueste von { $sender }: { $subject }
win-outbox-waiting = { $count ->
    [one] { $count } Nachricht im Postausgang
   *[other] { $count } Nachrichten im Postausgang
}
win-outbox-waits = { $subject } wartet im Postausgang
win-outbox-sending = { $subject } wird gesendet...
win-from-account = Von { $account }
win-sign-in-refused = Die Anmeldung von { $account } wurde abgelehnt oder ist abgelaufen.
win-sign-in-again-ask = Im Browser erneut anmelden?
win-sign-in-again-failed = Die erneute Anmeldung hat nicht funktioniert: { $reason }
win-unknown-reason = unbekannter Grund
win-checking = Neue Nachrichten von { $account } werden abgerufen...
win-done = Fertig
win-sent-at = { $subject } um { $time } gesendet
win-draft-saved = Nachricht in Entwürfe gespeichert.
win-draft-not-saved = Die Nachricht wurde nicht in Entwürfe gespeichert: { $reason }
win-about-core = Kern { $version }
win-add-account-first = Fügen Sie zuerst ein E-Mail-Konto hinzu.
win-add-account-first-link = Fügen Sie zuerst ein E-Mail-Konto hinzu und klicken Sie dann erneut auf den E-Mail-Link.
win-default-app-is = Inbox Classic ist Ihr Standard-E-Mail-Programm: E-Mail-Links öffnen hier eine neue Nachricht.
win-default-app-not-installed = Diese Kopie von Inbox Classic wurde nicht installiert, deshalb führt Windows sie nicht als E-Mail-Programm. Installieren Sie sie, um sie auszuwählen.
win-default-app-settings = Windows öffnet seine Einstellungen für Standard-Apps bei Inbox Classic. Wählen Sie es dort für MAILTO.
win-select-message-first = Wählen Sie zuerst eine Nachricht aus.
win-store-not-opened = Der E-Mail-Speicher konnte nicht geöffnet werden.
win-store-or-cert-not-opened = Der E-Mail-Speicher oder die Zertifikatsdatei konnte nicht geöffnet werden.
win-no-unread = Keine ungelesenen Nachrichten
win-unread-messages = { $count ->
    [one] { $count } ungelesene Nachricht
   *[other] { $count } ungelesene Nachrichten
}
win-help-title = Inbox Classic-Hilfe
win-help-missing = Die Hilfe fehlt in dieser Kopie von Inbox Classic.
win-print-failed = Die Nachricht konnte nicht gedruckt werden.
win-print-title = Drucken
win-print-title-of = Drucken: { $subject }
win-no-bodies = Nachrichtentexte können nicht angezeigt werden.
win-webview-failed = WebView2 konnte nicht erstellt werden.
win-webview-missing = Die WebView2-Laufzeit ist nicht verfügbar.

## Schaltflächen und Wörter vieler Fenster

win-ok = OK
win-cancel = Abbrechen
win-close = Schließen
win-delete-button = &Löschen
win-find-label = &Suchen:
win-col-subject = Betreff
win-col-to = An
win-col-from = Von
win-col-received = Erhalten
win-col-size = Größe
win-col-folder = Ordner
win-col-account = Konto
win-col-queued = Eingereiht
win-col-status = Status
win-save-as-button = Speichern &unter...
win-too-many-files = Zu viele Dateien auf einmal: Wählen Sie weniger aus.

## Der Postausgang

win-outbox-title = Postausgang
win-outbox-status-waiting = Wartet
win-outbox-status-not-sent = Nicht gesendet: { $reason }
win-outbox-status-agent = Von einem KI-Agenten gesendet; geht um { $time } hinaus
win-outbox-delete-ask = Diese Nachricht löschen, ohne sie zu senden?
win-outbox-send-all = Alle jetzt &senden

## Das Fenster zum Schreiben

win-editor-failed = Nachrichten können nicht geschrieben werden.
win-open-link = Link öffnen
win-edit-link = Link bearbeiten...
win-remove-link = Link entfernen
win-ctrl-click-to-open = ({ $ctrl }+Klick zum Öffnen)
win-insert-attachment = Anlage einfügen
win-insert-picture = Bild einfügen
win-filter-all = Alle Dateien
win-filter-pictures = Bilder
win-filter-messages = E-Mail-Nachrichten
win-save-attachment-as = Anlage speichern unter
win-remove-file = &Entfernen
win-not-sent = Die Nachricht konnte nicht gesendet werden.
win-not-saved = Die Nachricht konnte nicht gespeichert werden.
win-saving-draft = Wird in Entwürfe gespeichert...
win-compose-saved-at = Um { $time } in Entwürfe gespeichert
win-compose-not-saved = Nicht in Entwürfe gespeichert: { $reason }
win-save-changes-ask = Möchten Sie die Änderungen an dieser Nachricht in Entwürfe speichern?
win-new-message-title = Neue Nachricht
win-link-invalid = Geben Sie eine Webadresse (https://...) oder einen E-Mail-Link (mailto:...) ein.
win-link-address = Adresse:
win-hyperlink = Hyperlink
win-hyperlink-intro = Die Adresse, auf die der markierte Text verweist.
win-edit-hyperlink = Hyperlink bearbeiten
win-edit-hyperlink-intro = Wohin der Link führt. Leeren Sie die Adresse, um den Link zu entfernen und seinen Text zu behalten.
win-not-a-picture = Diese Datei ist kein PNG-, JPEG- oder GIF-Bild, oder sie ist größer als 10 MB.
win-format-bold = Fett ({ $ctrl }+B)
win-format-italic = Kursiv ({ $ctrl }+I)
win-format-underline = Unterstrichen ({ $ctrl }+U)
win-format-color = Schriftfarbe
win-format-numbers = Nummerierung
win-format-bullets = Aufzählungszeichen
win-format-outdent = Einzug verkleinern
win-format-indent = Einzug vergrößern
win-format-left = Linksbündig
win-format-center = Zentriert
win-format-right = Rechtsbündig
win-format-link = Hyperlink ({ $ctrl }+K)
win-format-line = Horizontale Linie einfügen
win-tb-send = Senden
win-tb-save = Speichern
win-tb-attach = Anfügen
win-field-from = Von:
win-field-to = An:
win-field-cc = Cc:
win-field-bcc = Bcc:
win-field-subject = Betreff:
win-field-attach = Anlagen:
win-show-cc = &Cc
win-show-bcc = &Bcc
win-signature = Signatur
win-signature-title = Signatur: { $account }
win-signature-hint = Wird neuen Nachrichten, Antworten und Weiterleitungen von diesem Konto angefügt.
win-signature-not-saved = Die Signatur konnte nicht gespeichert werden.

## Die Ordner, die Nachrichtenliste und der Lesebereich

win-all-inboxes = Alle Posteingänge
win-all-folders = Alle Ordner
win-the-account = das Konto
win-folder-name = Ordnername:
win-find-hint = E-Mail durchsuchen
win-find-tip = Findet Wörter im Betreff, in den Personen, in den Dateinamen und im Text der Nachrichten.
win-clear-search = Suche löschen
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
win-no-match = Keine Nachrichten entsprechen „{ $words }“.
win-no-match-all = Die Suche durchsucht den Betreff, die Personen, die Dateinamen und den Text der Nachrichten in allen Ordnern. Prüfen Sie die Schreibweise, oder versuchen Sie es mit weniger Wörtern.
win-no-match-in = Die Suche durchsucht den Betreff, die Personen, die Dateinamen und den Text der Nachrichten in { $folder }. Prüfen Sie die Schreibweise, oder versuchen Sie es mit weniger Wörtern.
win-no-match-indexing = { $count ->
    [one] Der Text von { $count } Nachricht wird noch indiziert, es kann also bald mehr gefunden werden.
   *[other] Der Text von { $count } Nachrichten wird noch indiziert, es kann also bald mehr gefunden werden.
}
win-no-items = Diese Ansicht enthält keine Elemente.
win-choose-folder = Wählen Sie einen Ordner, um seine Nachrichten zu sehen.
win-unsubscribe = Abbestellen
win-open-in-calendar = Im Kalender öffnen
win-files = { $count ->
    [one] { $count } Datei
   *[other] { $count } Dateien
}
win-pictures-blocked = Einige Bilder wurden blockiert, damit der Absender Ihren Computer nicht erkennen kann. Klicken Sie hier, um die Bilder herunterzuladen.
win-click-to-retry = Klicken Sie hier, um es erneut zu versuchen.
win-not-shown = Die Nachricht konnte nicht angezeigt werden.
win-save-attachments = Anlagen &speichern...
win-attachment-not-read = Die Anlage konnte nicht gelesen werden.
win-attachment-not-saved = Die Anlage konnte nicht gespeichert werden.
win-not-downloaded = Die Nachricht ist noch nicht heruntergeladen.
win-files-not-saved = { $failed } der { $count } Dateien konnten nicht gespeichert werden.
win-leave-list = Diese Mailingliste verlassen?
win-leave-one-click = Inbox Classic bittet { $target }, Ihnen keine Nachrichten mehr zu senden. Es öffnet sich keine Seite und es wird keine Nachricht gesendet.
win-leave-mail = Die Liste möchte eine Nachricht an { $target }. Inbox Classic schreibt sie für Sie; senden Sie sie, um abzubestellen.
win-leave-web = Die Seite der Liste dafür öffnet sich in Ihrem Browser ({ $target }).
win-unsubscribing = Abbestellen bei { $target }...
win-cannot-unsubscribe = Mit dieser Nachricht können Sie nicht abbestellen.
win-unsubscribed = Abbestellt. Die Liste sagt, dass sie diese E-Mails nicht mehr sendet.
win-not-unsubscribed = Abbestellen nicht möglich: { $reason }
win-event-span = { $start } bis { $end }
win-event-floating = { $when } (Zeit des Absenders)
win-invitation = Einladung: { $title }
win-invitation-updated = Geänderte Einladung: { $title }
win-invitation-canceled = Abgesagt: { $title }
win-invitation-answer = Antwort auf eine Einladung: { $title }
win-no-title = (kein Titel)
win-organizer = Organisator: { $name }
win-attendees = { $count ->
    [one] { $count } Teilnehmer
   *[other] { $count } Teilnehmer
}
win-invitation-not-read = Die Einladung konnte nicht gelesen werden.
win-no-calendar = Kein Kalenderprogramm auf diesem Computer öffnet Einladungen (.ics-Dateien).
win-messages-not-changed = Die Nachrichten konnten nicht geändert werden.
win-copy-button = &Kopieren
win-move-button = &Verschieben
win-new-folder-in-highlighted = Der neue Ordner kommt in den hervorgehobenen Ordner.
win-new-folder-in-selected = Der neue Ordner kommt in den ausgewählten Ordner.
win-new-folder-at-top = Der neue Ordner kommt auf die oberste Ebene des Kontos.
win-folder-not-created = Der Ordner konnte nicht erstellt werden.
win-folder-not-renamed = Der Ordner konnte nicht umbenannt werden.
win-folder-not-deleted = Der Ordner konnte nicht gelöscht werden.
win-rename-folder-intro = Der neue Name des Ordners { $folder }.
win-delete-folder-ask = Den Ordner „{ $folder }“ mit seinen Nachrichten und den Ordnern darin löschen? Er wird auch auf dem Server gelöscht.
win-clear-flag = Kennzeichnung &löschen
win-rename = &Umbenennen...
win-open = Ö&ffnen
win-view-source = &Quelltext anzeigen
win-properties = &Eigenschaften
win-properties-of = Eigenschaften von { $subject }
win-internet-headers = Internetkopfzeilen dieser Nachricht:
win-save-messages-in = Nachrichten speichern in
win-save-message-as = Nachricht speichern unter
win-messages-not-saved = Die Nachrichten konnten nicht gespeichert werden.
win-messages-not-forwarded = Die Nachrichten konnten nicht weitergeleitet werden.
win-import-choose-folder = Wählen Sie zuerst den Ordner, in den die Nachrichten kommen sollen.

## Konten

win-add-account-title = E-Mail-Konto hinzufügen
win-accounts-title = Konten
win-security-none = Keine (unverschlüsselt)
win-field-required = { $field } ist erforderlich.
win-email-invalid = Die E-Mail-Adresse ist ungültig.
win-ports-invalid = Ports sind Zahlen von 1 bis 65535.
win-looking-up = Die Einstellungen von { $domain } werden gesucht...
win-found-none = Geben Sie die Kontodaten ein, die Ihr E-Mail-Anbieter Ihnen gegeben hat.
win-found-change = Ändern Sie sie, wenn Ihr Anbieter Ihnen andere gegeben hat.
win-found-guess = Für diese Adresse wurden keine Einstellungen gefunden: Dies sind die üblichen Namen, prüfen Sie sie bei Ihrem Anbieter.
win-found-mx = Ihre E-Mail wird von einem Anbieter verwaltet, den Inbox Classic kennt; dies sind seine Server.
win-found-srv = Diese Einstellungen wurden in den DNS-Einträgen Ihrer Domain gefunden.
win-found-autodiscover = Diese Einstellungen wurden von Microsoft Autodiscover (Exchange) gefunden.
win-found-other = Diese Einstellungen wurden für diese Adresse gefunden.
win-app-password-needed = { $provider } nimmt Ihr normales Kennwort in E-Mail-Programmen nicht an. Erstellen Sie in Ihrem Konto bei { $provider } ein App-Kennwort und geben Sie es im nächsten Formular in das Feld Kennwort ein.
win-app-password-open = Die Anleitung von { $provider } im Browser öffnen?
win-plain-warning = Ohne Verschlüsselung gehen Ihr Kennwort und Ihre E-Mail lesbar für jeden auf dem Weg durch das Netz. Verwenden Sie dies nur für einen Server auf Ihrem eigenen Computer oder in Ihrem eigenen Netz.
win-continue-ask = Fortfahren?
win-sign-in-google = Mit Google anmelden
win-sign-in-microsoft = Mit Microsoft anmelden
win-add-sign-in-app = Anmelde-App hinzufügen...
win-turned-off = { $name } ist auf diesem Computer ausgeschaltet.
win-off-here = Auf diesem Computer ausgeschaltet.
win-why = Warum?
win-more-sign-in = Weitere Anmeldeoptionen...
win-next = &Weiter >
win-other-account = Jedes andere E-Mail-Konto: Ihr Name, wie andere ihn sehen, und Ihre E-Mail-Adresse. Seine Server werden als Nächstes gesucht.
win-field-name = Anzeigename:
win-field-email = E-Mail-Adresse:
win-field-user = Benutzername:
win-field-password = Kennwort:
win-field-imap-host = Posteingangsserver (IMAP):
win-field-imap-port = IMAP-Port:
win-field-imap-security = IMAP-Sicherheit:
win-field-smtp-host = Postausgangsserver (SMTP):
win-field-smtp-port = SMTP-Port:
win-field-smtp-security = SMTP-Sicherheit:
win-sign-in-not-started = Die Anmeldung im Browser konnte nicht beginnen.
win-your-account = Ihr Konto
win-sign-in-in-browser = Melden Sie sich im geöffneten Browserfenster bei { $account } an und kehren Sie dann hierher zurück.
win-sign-in-failed = Die Anmeldung hat nicht funktioniert: { $reason }
win-account-not-saved = Das Konto konnte nicht gespeichert werden.
win-start-intro = Gmail, Google Workspace, Outlook.com und Microsoft 365: Melden Sie sich auf der Seite von Google oder Microsoft an. Ihr Kennwort geben Sie dort ein, nie in Inbox Classic.
win-start-intro-apps = Melden Sie sich im Browser mit einer Ihrer Anmelde-Apps an (Weitere Anmeldeoptionen), oder fügen Sie unten ein beliebiges E-Mail-Konto mit Ihrem Namen und Ihrer Adresse hinzu.
win-use-app-password = App-Kennwort verwenden
win-the-provider = Ihrem Anbieter
win-provider-intro = { $email } meldet sich auf der Seite von { $provider } an, ohne Inbox Classic Ihr Kennwort zu geben. Oder verwenden Sie ein App-Kennwort aus den Sicherheitseinstellungen Ihres Kontos.
win-provider-intro-apps = { $email } kann sich auf der Seite von { $provider } mit einer Ihrer Anmelde-Apps anmelden (Weitere Anmeldeoptionen). Oder verwenden Sie ein App-Kennwort aus den Sicherheitseinstellungen Ihres Kontos.
win-finish = Fertig stellen
win-logon = Anmelden
win-enter-password = Geben Sie das Kennwort von { $account } ein.
win-browser-sign-in = (Anmeldung im Browser)
win-signs-in-with = Meldet sich an mit: { $app }. Es meldet sich im Browser an und verwendet die Server seiner Anmeldung.
win-keep-password = Lassen Sie das Kennwort leer, um Ihr bisheriges zu behalten.
win-remove-account = Konto entfernen
win-remove-account-ask = Dieses Konto aus Inbox Classic entfernen? Seine E-Mails bleiben auf dem Server; die Kopie auf diesem Computer und das gespeicherte Kennwort werden entfernt.
win-col-email = E-Mail-Adresse
win-col-incoming = Posteingangsserver
win-add = &Hinzufügen...
win-properties-button = &Eigenschaften...
win-signature-button = &Signatur...
win-sign-in-apps-button = &Anmelde-Apps...
win-type-email = Geben Sie Ihre E-Mail-Adresse ein, name@example.com.

## KI-Agenten

win-ai-agent = KI-Agent
win-ai-agent-access = Zugriff für KI-Agenten
win-ai-agents = KI-Agenten
win-program-path = Programm: { $path }
win-it-may = Es darf:
win-accounts-it-may-use = Konten, die es verwenden darf:
win-allow = &Zulassen
win-dont-allow = &Nicht zulassen
win-turn-away = &Abweisen
win-send-message-ask = Nachricht senden?
win-col-address = Adresse
win-col-name = Name
win-never-written-to = Nie angeschrieben
win-send = &Senden
win-edit-first = Zuerst &bearbeiten
win-dont-send = &Nicht senden
win-never = Nie
win-forget-program-ask = Dieses Programm vergessen und was seine Agenten getan haben? Beim nächsten Verbinden wird erneut gefragt.
win-clear-log-ask = Die Liste dessen löschen, was Agenten getan haben? Was sie getan haben, bleibt getan.
win-connect-agent = KI-Agenten verbinden
win-connect-agent-intro = Fügen Sie dies den MCP-Servern Ihres Agenten hinzu (Claude Desktop: Settings > Developer > Edit Config):
win-let-agents-connect = KI-Agenten die Verbindung mit Inbox Classic &erlauben
win-agent-programs = &Programme, deren Agenten Ihre E-Mail verwenden wollten:
win-col-program = Programm
win-col-may = Darf
win-col-last-used = Zuletzt verwendet
win-change = Ä&ndern...
win-what-agents-did = &Was Agenten getan haben:
win-col-when = Wann
win-col-what = Was
win-clear = &Leeren
win-how-to-connect = So verbinden Sie einen Agenten

## Anmelde-Apps

win-sign-in-app = Anmelde-App
win-sign-in-apps = Anmelde-Apps
win-add-sign-in-app-title = Anmelde-App hinzufügen
win-preset-app-name = Anmelde-App für { $provider }
win-issuer-not-checked = der Aussteller kann nicht geprüft werden
win-checking-issuer = { $issuer } wird geprüft...
win-issuer-unusable = Der Aussteller kann nicht verwendet werden: { $reason }
win-issuer-usable = Der Aussteller kann verwendet werden.
win-sign-in-app-not-saved = Die Anmelde-App konnte nicht gespeichert werden: { $reason }
win-check = Prüfen
win-check-button = &Prüfen
win-copy = &Kopieren
win-fill-in-for = Ausfüllen für:
win-app-name = Name:
win-issuer = Aussteller:
win-client-id = Client-ID:
win-client-secret = Clientschlüssel:
win-scopes = Bereiche:
win-imap-server = IMAP-Server:
win-smtp-server = SMTP-Server:
win-redirect-uri = Umleitungs-URI:
win-sign-in-app-intro = Ein OAuth-Client, den Sie bei Ihrem Anbieter registriert haben, für Konten, die sich im Browser anmelden. Füllen Sie ihn für einen Anbieter aus und fügen Sie dann die Client-ID hinzu (und den Schlüssel, falls der Anbieter einen gegeben hat).
win-remove-secret = Ein Schlüssel ist gespeichert; geben Sie einen anderen ein, um ihn zu ersetzen, oder entfernen Sie ihn
win-register-it = Registrieren Sie ihn bei Ihrem Anbieter
win-built-in-note = { $name } ist eingebaut: Nur ob es für neue Konten verwendet wird, lässt sich ändern.
win-client-with-secret = Client-ID: { $client }, mit einem Clientschlüssel.
win-client-public = Client-ID: { $client }, ein öffentlicher Client (ohne Schlüssel).
win-built-in = (eingebaut)
win-no-accounts = Keine Konten
win-remove-sign-in-app = Anmelde-App entfernen
win-remove-sign-in-app-ask = Die Anmelde-App { $name } und ihren gespeicherten Clientschlüssel entfernen?
win-sign-in-app-not-removed = Die Anmelde-App wurde nicht entfernt: { $reason }
win-sign-in-apps-intro = Mit Anmelde-Apps melden sich Konten im Browser an. Eine nicht angehakte wird neuen Konten nicht angeboten; die Konten, die sie schon verwenden, funktionieren weiter.
win-col-issuer = Aussteller
win-col-used-by = Verwendet von
win-edit = &Bearbeiten...

## Optionen

win-options-language-group = Sprache
win-options-language-label = Inbox Classic &anzeigen in:
win-options-system-default = Systemstandard ({ $language })
win-options-restart-note = Inbox Classic startet neu, um eine andere Sprache anzuzeigen.
win-options-notify-group = Benachrichtigungen
win-options-notify = Bei neuer E-Mail &benachrichtigen
win-restart-ask = Inbox Classic zeigt { $language } nach einem Neustart an. Jetzt neu starten?
win-restart-now = Jetzt &neu starten
win-restart-later = &Später
