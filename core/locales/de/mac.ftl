# Deutsch. Entwurf, wartet auf die Durchsicht durch Muttersprachler.

## The app and its menus

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
mac-paste = Einsetzen
mac-menu-window = Fenster
mac-minimize = Im Dock ablegen
mac-zoom = Zoomen
mac-no-updates = Diese Kopie von Inbox Classic aktualisiert sich nicht selbst. Die neueste Version gibt es auf inboxclassic.com.

## Settings

mac-settings-title = Einstellungen
mac-language-label = Sprache:
mac-restart-hint = Inbox Classic startet neu, um die Sprache zu wechseln.
mac-notify-new-mail = Bei neuen Nachrichten benachrichtigen
mac-restart-question = Inbox Classic jetzt neu starten, um die Sprache zu wechseln?

## Dialogs

mac-choose = Auswählen

## The main window

mac-still-running-detail = Es sucht weiter nach neuen Nachrichten. Klicken Sie auf das Symbol im Dock, um es wieder zu öffnen.
mac-outbox-waiting =
    { $count ->
        [one] { $count } Nachricht im Postausgang
       *[other] { $count } Nachrichten im Postausgang
    }
mac-sending = { $subject } wird gesendet…
mac-checking = Neue Nachrichten von { $account } werden abgerufen…
mac-account-said = { $account }: { $message }
mac-new-messages =
    { $count ->
        [one] { $count } neue Nachricht
       *[other] { $count } neue Nachrichten
    }
mac-newest-from = Die neueste von { $from }: { $subject }
mac-not-bundle = Diese Kopie von Inbox Classic ist kein App-Paket und kann daher nicht die Standard-E-Mail-App sein.
mac-not-made-default = Inbox Classic wurde nicht zur Standard-E-Mail-App gemacht: { $reason }
mac-tool-search = Suchen

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Der Text von { $count } Nachricht wird noch indiziert, es kann also bald mehr gefunden werden.
       *[other] Der Text von { $count } Nachrichten wird noch indiziert, es kann also bald mehr gefunden werden.
    }
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
mac-import-messages = Nachrichten importieren
mac-save-messages = Nachrichten speichern
mac-save-attachments-menu = Anlagen speichern…
mac-files-not-saved =
    { $count ->
       *[other] { $failed } von { $count } Dateien konnten nicht gespeichert werden.
    }
mac-no-calendar-app = Keine Kalender-App auf diesem Mac öffnet Einladungen (.ics-Dateien).
mac-unsubscribing = Abbestellen bei { $target }…

## The compose window

mac-bold = Fett
mac-italic = Kursiv
mac-underline = Unterstrichen
mac-bcc = Bcc
mac-command-click-to-open = ⌘-Klick zum Öffnen
mac-saving-to-drafts = Wird in Entwürfe gespeichert…
mac-dont-save = Nicht speichern

## The reading pane

mac-files =
    { $count ->
        [one] { $count } Datei
       *[other] { $count } Dateien
    }
mac-attendees =
    { $count ->
        [one] { $count } Teilnehmer
       *[other] { $count } Teilnehmer
    }

## Accounts

mac-next = Weiter
mac-name-placeholder = Anna Schmidt
mac-more-sign-in-options = Weitere Anmeldeoptionen…
mac-add-sign-in-app = Anmelde-App hinzufügen…
mac-looking-up = Einstellungen von { $domain } werden gesucht…
mac-add-button = Hinzufügen…
mac-properties-button = Eigenschaften…
mac-signature-button = Signatur…
mac-sign-in-apps-button = Anmelde-Apps…

## AI agents

mac-forget-program = Dieses Programm und was seine Agenten getan haben vergessen?
mac-forget-program-detail = Es wird erneut gefragt, wenn es sich das nächste Mal verbindet.

## Sign-in apps

mac-checking-issuer = { $issuer } wird geprüft…
mac-edit-button = Bearbeiten…
mac-use-for-new-accounts = { $name } für neue Konten verwenden
mac-built-in = { $name } (integriert)

## Other windows

mac-new-folder-button = Neuer Ordner…
mac-edit-link = Link bearbeiten…
