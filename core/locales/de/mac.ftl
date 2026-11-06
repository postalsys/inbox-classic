# Deutsch. Entwurf, wartet auf die Durchsicht durch Muttersprachler.

## The app and its menus

mac-store-not-opened = Der Nachrichtenspeicher konnte nicht geöffnet werden.
mac-store-or-certificate-not-opened = Der Nachrichtenspeicher oder die Zertifikatsdatei konnte nicht geöffnet werden.
mac-quit = Inbox Classic beenden
mac-settings = Einstellungen…
mac-services = Dienste
mac-hide = Inbox Classic ausblenden
mac-hide-others = Andere ausblenden
mac-show-all = Alle einblenden
mac-check-updates = Nach Updates suchen…
mac-close-window = Fenster schließen
mac-redo = Wiederholen
mac-cut = Ausschneiden
mac-copy = Kopieren
mac-paste = Einsetzen
mac-menu-window = Fenster
mac-minimize = Im Dock ablegen
mac-zoom = Zoomen
mac-help-title = Inbox Classic-Hilfe
mac-no-updates = Diese Kopie von Inbox Classic aktualisiert sich nicht selbst. Die neueste Version gibt es auf inboxclassic.com.
mac-flag = Kennzeichnung
mac-clear-flag = Kennzeichnung löschen

## Settings

mac-settings-title = Einstellungen
mac-language-label = Sprache:
mac-system-default = Systemstandard ({ $language })
mac-restart-hint = Inbox Classic startet neu, um die Sprache zu wechseln.
mac-notify-new-mail = Bei neuen Nachrichten benachrichtigen
mac-restart-question = Inbox Classic jetzt neu starten, um die Sprache zu wechseln?
mac-restart-now = Jetzt neu starten
mac-restart-later = Später

## Dialogs

mac-ok = OK
mac-cancel = Abbrechen
mac-yes = Ja
mac-no = Nein
mac-folder-name = Ordnername:
mac-save-attachment-as = Anlage speichern unter
mac-choose = Auswählen
mac-messages-not-changed = Die Nachrichten konnten nicht geändert werden.

## The main window

mac-still-running = Inbox Classic läuft weiter
mac-still-running-detail = Es sucht weiter nach neuen Nachrichten. Klicken Sie auf das Symbol im Dock, um es wieder zu öffnen.
mac-no-subject = (kein Betreff)
mac-quoted = „{ $subject }“
mac-outbox-waiting =
    { $count ->
        [one] { $count } Nachricht im Postausgang
       *[other] { $count } Nachrichten im Postausgang
    }
mac-outbox-waits = { $subject } wartet im Postausgang
mac-sending = { $subject } wird gesendet…
mac-checking = Neue Nachrichten von { $account } werden abgerufen…
mac-done = Fertig
mac-sent-at = { $subject } um { $time } gesendet
mac-draft-saved = Nachricht in Entwürfe gespeichert.
mac-draft-not-saved = Die Nachricht wurde nicht in Entwürfe gespeichert: { $reason }
mac-account-said = { $account }: { $message }
mac-new-messages =
    { $count ->
        [one] { $count } neue Nachricht
       *[other] { $count } neue Nachrichten
    }
mac-newest-from = Die neueste von { $from }: { $subject }
mac-sign-in-refused = Die Anmeldung von { $account } wurde abgelehnt oder ist abgelaufen.
mac-sign-in-again = Im Browser erneut anmelden?
mac-sign-in-failed = Die erneute Anmeldung hat nicht funktioniert: { $reason }
mac-unknown-reason = unbekannter Grund
mac-core-version = Kern { $version }
mac-add-account-first = Fügen Sie zuerst ein E-Mail-Konto hinzu.
mac-add-account-first-link = Fügen Sie zuerst ein E-Mail-Konto hinzu und klicken Sie dann erneut auf den E-Mail-Link.
mac-select-message-first = Wählen Sie zuerst eine Nachricht aus.
mac-not-bundle = Diese Kopie von Inbox Classic ist kein App-Paket und kann daher nicht die Standard-E-Mail-App sein.
mac-is-default = Inbox Classic ist Ihre Standard-E-Mail-App: E-Mail-Links öffnen hier eine neue Nachricht.
mac-not-made-default = Inbox Classic wurde nicht zur Standard-E-Mail-App gemacht: { $reason }
mac-tool-create-mail = Neue E-Mail
mac-tool-reply = Antworten
mac-tool-reply-all = Allen antworten
mac-tool-forward = Weiterleiten
mac-tool-print = Drucken
mac-tool-delete = Löschen
mac-tool-junk = Junk
mac-tool-not-junk = Kein Junk
mac-tool-sync = Senden/Empfangen
mac-tool-mark-read = Gelesen
mac-tool-mark-unread = Ungelesen
mac-tool-search = Suchen
mac-search-mail = E-Mail durchsuchen
mac-find-tip = Sucht Wörter im Betreff, in den Personen, den Dateinamen und im Text der Nachrichten.
mac-from-account = Von { $account }

## The folders and the message list

mac-clear-search = Suche löschen
mac-all-inboxes = Alle Posteingänge
mac-the-account = das Konto
mac-all-folders = Alle Ordner
mac-column-received = Erhalten
mac-column-size = Größe
mac-column-folder = Ordner
mac-column-account = Konto
mac-no-match = Keine Nachrichten passen zu „{ $words }“.
mac-search-looks-everywhere = Die Suche durchsucht den Betreff, die Personen, die Dateinamen und den Text der Nachrichten in allen Ordnern. Prüfen Sie die Schreibweise oder versuchen Sie es mit weniger Wörtern.
mac-search-looks-in = Die Suche durchsucht den Betreff, die Personen, die Dateinamen und den Text der Nachrichten in { $folder }. Prüfen Sie die Schreibweise oder versuchen Sie es mit weniger Wörtern.
mac-still-indexing-more =
    { $count ->
        [one] Der Text von { $count } Nachricht wird noch indiziert, es kann also bald mehr gefunden werden.
       *[other] Der Text von { $count } Nachrichten wird noch indiziert, es kann also bald mehr gefunden werden.
    }
mac-no-items = In dieser Ansicht gibt es keine Elemente.
mac-choose-folder = Wählen Sie einen Ordner, um seine Nachrichten zu sehen.
mac-results-everywhere =
    { $count ->
        [0] Keine Ergebnisse für „{ $words }“ in allen Ordnern
        [one] { $count } Ergebnis für „{ $words }“ in allen Ordnern
       *[other] { $count } Ergebnisse für „{ $words }“ in allen Ordnern
    }
mac-results-in =
    { $count ->
        [0] Keine Ergebnisse für „{ $words }“ in { $folder }
        [one] { $count } Ergebnis für „{ $words }“ in { $folder }
       *[other] { $count } Ergebnisse für „{ $words }“ in { $folder }
    }
mac-still-indexing =
    { $count ->
        [one] Text von { $count } Nachricht wird noch indiziert
       *[other] Text von { $count } Nachrichten wird noch indiziert
    }
mac-folder-unread = { $folder }, { $count } ungelesen
mac-message-not-shown = Die Nachricht konnte nicht angezeigt werden.
mac-delete = Löschen
mac-move-button = Verschieben
mac-copy-button = Kopieren
mac-new-folder = Neuer Ordner
mac-new-folder-in-selected = Der neue Ordner wird im ausgewählten Ordner angelegt.
mac-new-folder-at-top = Der neue Ordner wird auf oberster Ebene des Kontos angelegt.
mac-folder-not-created = Der Ordner konnte nicht erstellt werden.
mac-rename-folder = Ordner umbenennen
mac-rename-folder-intro = Der neue Name des Ordners { $folder }.
mac-folder-not-renamed = Der Ordner konnte nicht umbenannt werden.
mac-delete-folder-question = Den Ordner „{ $folder }“ mit seinen Nachrichten und den Ordnern darin löschen? Er wird auch auf dem Server gelöscht.
mac-folder-not-deleted = Der Ordner konnte nicht gelöscht werden.
mac-not-downloaded = Die Nachricht ist noch nicht heruntergeladen.
mac-save-message-as = Nachricht speichern unter
mac-message-not-saved = Die Nachricht konnte nicht gespeichert werden.
mac-properties = Eigenschaften
mac-properties-of = Eigenschaften von { $subject }
mac-internet-headers = Internetkopfzeilen dieser Nachricht:
mac-close = Schließen
mac-open = Öffnen
mac-view-source = Quelltext anzeigen
mac-import-messages = Nachrichten importieren
mac-import-choose-folder = Wählen Sie zuerst den Ordner, in den die Nachrichten kommen sollen.
mac-save-messages = Nachrichten speichern
mac-save-attachments-menu = Anlagen speichern…
mac-save-attachments = Anlagen speichern
mac-attachment-not-read = Die Anlage konnte nicht gelesen werden.
mac-attachment-not-saved = Die Anlage konnte nicht gespeichert werden.
mac-files-not-saved =
    { $count ->
       *[other] { $failed } von { $count } Dateien konnten nicht gespeichert werden.
    }
mac-invitation-not-read = Die Einladung konnte nicht gelesen werden.
mac-no-calendar-app = Keine Kalender-App auf diesem Mac öffnet Einladungen (.ics-Dateien).
mac-leave-list = Diese Mailingliste verlassen?
mac-unsubscribe = Abbestellen
mac-unsubscribe-one-click = Inbox Classic bittet { $target }, Ihnen keine Nachrichten mehr zu senden. Es öffnet sich keine Seite und es wird keine Nachricht gesendet.
mac-unsubscribe-mail = Die Liste möchte eine Nachricht an { $target }. Inbox Classic schreibt sie für Sie; senden Sie sie, um abzubestellen.
mac-unsubscribe-web = Die Seite der Liste dafür öffnet sich in Ihrem Browser ({ $target }).
mac-unsubscribing = Abbestellen bei { $target }…
mac-can-not-unsubscribe = Mit dieser Nachricht können Sie nicht abbestellen.
mac-unsubscribed = Abbestellt. Die Liste sagt, dass sie diese E-Mails nicht mehr sendet.
mac-not-unsubscribed = Abbestellen nicht möglich: { $reason }

## The compose window

mac-bold = Fett
mac-italic = Kursiv
mac-underline = Unterstrichen
mac-numbered-list = Nummerierte Liste
mac-bulleted-list = Aufzählung
mac-align-left = Linksbündig
mac-center = Zentriert
mac-align-right = Rechtsbündig
mac-font-color = Schriftfarbe
mac-decrease-indent = Einzug verkleinern
mac-increase-indent = Einzug vergrößern
mac-hyperlink = Hyperlink
mac-edit-hyperlink = Hyperlink bearbeiten
mac-hyperlink-intro = Die Adresse, auf die der ausgewählte Text verweist.
mac-edit-hyperlink-intro = Wohin der Link führt. Leeren Sie die Adresse, um den Link zu entfernen und seinen Text zu behalten.
mac-link-address = Adresse:
mac-link-invalid = Geben Sie eine Webadresse (https://...) oder einen E-Mail-Link (mailto:...) ein.
mac-horizontal-line = Horizontale Linie einfügen
mac-insert-picture = Bild einfügen
mac-not-a-picture = Diese Datei ist kein PNG-, JPEG- oder GIF-Bild oder ist größer als 10 MB.
mac-bcc = Bcc
mac-new-message = Neue Nachricht
mac-field-from = Von:
mac-field-to = An:
mac-field-cc = Cc:
mac-field-bcc = Bcc:
mac-field-subject = Betreff:
mac-field-attach = Anlage:
mac-command-click-to-open = ⌘-Klick zum Öffnen
mac-remove = Entfernen
mac-insert-attachment = Anlage einfügen
mac-message-not-sent = Die Nachricht konnte nicht gesendet werden.
mac-saving-to-drafts = Wird in Entwürfe gespeichert…
mac-save-changes-question = Möchten Sie die Änderungen an dieser Nachricht in Entwürfe speichern?
mac-save = Speichern
mac-dont-save = Nicht speichern
mac-saved-in-drafts-at = Um { $time } in Entwürfe gespeichert
mac-not-saved-in-drafts = Nicht in Entwürfe gespeichert: { $reason }
mac-send = Senden
mac-attach = Anhängen
mac-signature = Signatur
mac-signature-title = Signatur - { $account }
mac-signature-hint = Wird neuen Nachrichten, Antworten und Weiterleitungen von diesem Konto hinzugefügt.
mac-signature-not-saved = Die Signatur konnte nicht gespeichert werden.

## The reading pane

mac-open-in-calendar = Im Kalender öffnen
mac-try-again = Erneut versuchen
mac-pictures-blocked = Einige Bilder wurden blockiert, damit der Absender Ihren Computer nicht erkennen kann. Klicken Sie hier, um die Bilder herunterzuladen.
mac-files =
    { $count ->
        [one] { $count } Datei
       *[other] { $count } Dateien
    }
mac-invitation = Einladung: { $title }
mac-invitation-updated = Geänderte Einladung: { $title }
mac-invitation-canceled = Abgesagt: { $title }
mac-invitation-answer = Antwort auf eine Einladung: { $title }
mac-no-title = (ohne Titel)
mac-organizer = Organisator: { $name }
mac-attendees =
    { $count ->
        [one] { $count } Teilnehmer
       *[other] { $count } Teilnehmer
    }
mac-from-to = { $start } bis { $end }
mac-senders-time = { $when } (Zeit des Absenders)

## Accounts

mac-security-none = Keine (unverschlüsselt)
mac-field-required = { $field } ist erforderlich.
mac-email-invalid = Die E-Mail-Adresse ist ungültig.
mac-ports-invalid = Ports sind Zahlen von 1 bis 65535.
mac-plain-warning = Ohne Verschlüsselung gehen Ihr Kennwort und Ihre E-Mails für jeden auf dem Weg lesbar durch das Netz. Verwenden Sie das nur für einen Server auf Ihrem eigenen Computer oder in Ihrem eigenen Netzwerk.
mac-continue-question = Fortfahren?
mac-display-name = Anzeigename:
mac-email-address = E-Mail-Adresse:
mac-user-name = Benutzername:
mac-password = Kennwort:
mac-imap-server = Posteingangsserver (IMAP):
mac-imap-port = IMAP-Port:
mac-imap-security = IMAP-Sicherheit:
mac-smtp-server = Postausgangsserver (SMTP):
mac-smtp-port = SMTP-Port:
mac-smtp-security = SMTP-Sicherheit:
mac-sign-in-not-started = Die Anmeldung über den Browser konnte nicht starten.
mac-sign-in-waiting = Melden Sie sich im geöffneten Browserfenster bei { $account } an und kommen Sie dann hierher zurück.
mac-sign-in-waiting-any = Melden Sie sich im geöffneten Browserfenster bei Ihrem Konto an und kommen Sie dann hierher zurück.
mac-add-mail-account = E-Mail-Konto hinzufügen
mac-sign-in-did-not-work = Die Anmeldung hat nicht funktioniert: { $reason }
mac-sign-in-with = Mit { $provider } anmelden
mac-next = Weiter
mac-name-placeholder = Anna Schmidt
mac-more-sign-in-options = Weitere Anmeldeoptionen…
mac-any-other-account = Jedes andere E-Mail-Konto: Ihr Name, wie andere ihn sehen, und Ihre E-Mail-Adresse. Die Server werden als Nächstes gesucht.
mac-turned-off-named = { $name } ist auf diesem Computer ausgeschaltet.
mac-turned-off = Auf diesem Computer ausgeschaltet.
mac-why = Warum?
mac-add-sign-in-app = Anmelde-App hinzufügen…
mac-type-email = Geben Sie Ihre E-Mail-Adresse ein, name@example.com.
mac-found-none = Geben Sie die Kontodaten ein, die Ihr E-Mail-Anbieter Ihnen gegeben hat.
mac-found-change = Ändern Sie sie, wenn Ihr Anbieter Ihnen andere gegeben hat.
mac-found-guess = Für diese Adresse wurden keine Einstellungen gefunden: Dies sind die üblichen Namen, prüfen Sie sie bei Ihrem Anbieter.
mac-found-mx = Ihre E-Mails werden von einem Anbieter verwaltet, den Inbox Classic kennt; dies sind seine Server.
mac-found-srv = Diese Einstellungen wurden in den DNS-Einträgen Ihrer Domain gefunden.
mac-found-autodiscover = Diese Einstellungen wurden von Microsoft Autodiscover (Exchange) gefunden.
mac-found-other = Diese Einstellungen wurden für diese Adresse gefunden.
mac-app-password-needed = { $provider } nimmt Ihr normales Kennwort in E-Mail-Programmen nicht an. Erstellen Sie ein App-Kennwort in Ihrem { $provider }-Konto und geben Sie es im Feld Kennwort des nächsten Formulars ein.
mac-open-instructions = Die Anleitung von { $provider } im Browser öffnen?
mac-account-not-saved = Das Konto konnte nicht gespeichert werden.
mac-start-intro = Gmail, Google Workspace, Outlook.com und Microsoft 365: Melden Sie sich auf der eigenen Seite von Google oder Microsoft an. Ihr Kennwort geben Sie dort ein, nie in Inbox Classic.
mac-start-intro-apps = Melden Sie sich über den Browser mit einer Ihrer Anmelde-Apps an (Weitere Anmeldeoptionen) oder fügen Sie unten ein beliebiges E-Mail-Konto mit Ihrem Namen und Ihrer Adresse hinzu.
mac-looking-up = Einstellungen von { $domain } werden gesucht…
mac-use-app-password = App-Kennwort verwenden
mac-the-provider = dem Anbieter
mac-signs-in-at = { $email } meldet sich auf der eigenen Seite von { $provider } an, ohne Inbox Classic Ihr Kennwort zu geben. Oder verwenden Sie ein App-Kennwort aus den Sicherheitseinstellungen Ihres Kontos.
mac-can-sign-in-at = { $email } kann sich mit einer Ihrer Anmelde-Apps auf der eigenen Seite von { $provider } anmelden (Weitere Anmeldeoptionen). Oder verwenden Sie ein App-Kennwort aus den Sicherheitseinstellungen Ihres Kontos.
mac-finish = Fertig stellen
mac-logon = Anmelden
mac-enter-password = Geben Sie das Kennwort von { $account } ein.
mac-signs-in-with = Meldet sich an mit: { $app }. Es meldet sich über den Browser an und verwendet die Server seiner Anmeldung.
mac-keep-password = Lassen Sie das Kennwort leer, um das bisherige zu behalten.
mac-accounts = Konten
mac-column-email = E-Mail-Adresse
mac-column-incoming = Posteingangsserver
mac-add-button = Hinzufügen…
mac-properties-button = Eigenschaften…
mac-signature-button = Signatur…
mac-sign-in-apps-button = Anmelde-Apps…
mac-browser-sign-in = { $server } (Anmeldung im Browser)
mac-remove-account = Konto entfernen
mac-remove-account-question = Dieses Konto aus Inbox Classic entfernen? Die E-Mails bleiben auf dem Server; die Kopie auf diesem Computer und das gespeicherte Kennwort werden entfernt.

## AI agents

mac-ai-agent = KI-Agent
mac-allow = Erlauben
mac-dont-allow = Nicht erlauben
mac-program-path = Programm: { $path }
mac-it-may = Er darf:
mac-accounts-it-may-use = Konten, die er verwenden darf:
mac-new-address = Neue Adresse
mac-send-message-question = Nachricht senden?
mac-edit-first = Erst bearbeiten
mac-dont-send = Nicht senden
mac-let-agents-connect = KI-Agenten erlauben, sich mit Inbox Classic zu verbinden
mac-change-button = Ändern…
mac-undo-button = Rückgängig
mac-clear = Leeren
mac-ai-agents = KI-Agenten
mac-column-program = Programm
mac-column-may = Darf
mac-column-last-used = Zuletzt verwendet
mac-column-when = Wann
mac-column-what = Was
mac-how-to-connect = Einen Agenten verbinden…
mac-agent-programs = Programme, deren Agenten Ihre E-Mails verwenden wollten
mac-agent-log = Was Agenten getan haben
mac-never = Nie
mac-ai-agent-access = Zugriff des KI-Agenten
mac-turn-away = Abweisen
mac-forget-program = Dieses Programm und was seine Agenten getan haben vergessen?
mac-forget-program-detail = Es wird erneut gefragt, wenn es sich das nächste Mal verbindet.
mac-clear-log = Die Liste dessen leeren, was Agenten getan haben?
mac-clear-log-detail = Was sie getan haben, bleibt getan.
mac-connect-agent = Einen KI-Agenten verbinden
mac-connect-agent-intro = Fügen Sie dies den MCP-Servern Ihres Agenten hinzu (Claude Desktop: Settings > Developer > Edit Config):

## Sign-in apps

mac-secret-saved = Ein Geheimnis ist gespeichert; geben Sie ein anderes ein, um es zu ersetzen, oder entfernen Sie es
mac-add-sign-in-app-title = Anmelde-App hinzufügen
mac-sign-in-app = Anmelde-App
mac-sign-in-apps = Anmelde-Apps
mac-sign-in-app-intro = Ein OAuth-Client, den Sie bei Ihrem Anbieter registriert haben, für Konten, die sich über den Browser anmelden. Füllen Sie ihn für einen Anbieter aus und fügen Sie dann die Client-ID hinzu (und das Geheimnis, falls der Anbieter eines gegeben hat).
mac-check = Prüfen
mac-fill-in-for = Ausfüllen für:
mac-app-name = Name:
mac-issuer = Aussteller:
mac-client-id = Client-ID:
mac-client-secret = Client-Geheimnis:
mac-scopes = Bereiche:
mac-app-imap-server = IMAP-Server:
mac-app-smtp-server = SMTP-Server:
mac-register-it = Bei Ihrem Anbieter registrieren
mac-redirect-uri = Weiterleitungs-URI:
mac-preset-app-name = Anmelde-App für { $provider }
mac-issuer-not-checked = der Aussteller kann nicht geprüft werden
mac-checking-issuer = { $issuer } wird geprüft…
mac-issuer-usable = Der Aussteller kann verwendet werden.
mac-issuer-not-usable = Der Aussteller kann nicht verwendet werden: { $reason }
mac-sign-in-app-not-saved = Die Anmelde-App konnte nicht gespeichert werden: { $reason }
mac-edit-button = Bearbeiten…
mac-column-name = Name
mac-column-issuer = Aussteller
mac-column-used-by = Verwendet von
mac-sign-in-apps-intro = Mit Anmelde-Apps melden sich Konten über den Browser an. Eine nicht angehakte wird für neue Konten nicht angeboten; Konten, die sie schon verwenden, funktionieren weiter.
mac-use-for-new-accounts = { $name } für neue Konten verwenden
mac-built-in = { $name } (integriert)
mac-no-accounts = Keine Konten
mac-built-in-note = { $name } ist integriert: Nur ob sie für neue Konten verwendet wird, kann geändert werden.
mac-client-with-secret = Client-ID: { $client }, mit einem Client-Geheimnis.
mac-client-public = Client-ID: { $client }, ein öffentlicher Client (ohne Geheimnis).
mac-remove-sign-in-app = Anmelde-App entfernen
mac-remove-sign-in-app-question = Die Anmelde-App { $name } und ihr gespeichertes Client-Geheimnis entfernen?
mac-sign-in-app-not-removed = Die Anmelde-App wurde nicht entfernt: { $reason }

## Other windows

mac-find-folder = Ordner suchen
mac-new-folder-button = Neuer Ordner…
mac-new-folder-in = Der neue Ordner wird in { $folder } angelegt.
mac-send-all-now = Alle jetzt senden
mac-outbox = Postausgang
mac-column-queued = Eingereiht
mac-column-status = Status
mac-not-sent = Nicht gesendet: { $reason }
mac-agent-goes-at = Von einem KI-Agenten gesendet; geht um { $time } hinaus
mac-waiting = Wartet
mac-delete-unsent = Diese Nachricht löschen, ohne sie zu senden?
mac-open-link = Link öffnen
mac-edit-link = Link bearbeiten…
mac-remove-link = Link entfernen
mac-help-missing = Die Hilfe fehlt in dieser Kopie von Inbox Classic.
