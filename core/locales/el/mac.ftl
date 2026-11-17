# Ελληνικά. Προσχέδιο, περιμένει έλεγχο από φυσικό ομιλητή (βλ. core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, curly quotes («» in Greek).

## The app and its menus

mac-quit = Τερματισμός Inbox Classic
mac-settings = Ρυθμίσεις…
mac-services = Υπηρεσίες
mac-hide = Απόκρυψη Inbox Classic
mac-hide-others = Απόκρυψη άλλων
mac-show-all = Εμφάνιση όλων
mac-check-updates = Έλεγχος για ενημερώσεις…
mac-close-window = Κλείσιμο παραθύρου
mac-redo = Επανάληψη
mac-cut = Αποκοπή
mac-paste = Επικόλληση
mac-menu-window = Παράθυρο
mac-minimize = Ελαχιστοποίηση
mac-zoom = Ζουμ
mac-no-updates = Αυτή η έκδοση του Inbox Classic δεν υποστηρίζει αυτόματες ενημερώσεις. Κατεβάστε την πιο πρόσφατη έκδοση από το inboxclassic.com.

## Settings

mac-settings-title = Ρυθμίσεις
# review: new
mac-check-updates-automatically = Αυτόματος έλεγχος για ενημερώσεις
# review: new
mac-settings-updates = Ενημερώσεις

## Dialogs

mac-choose = Επιλογή

## The main window

mac-still-running-detail = Το Inbox Classic συνεχίζει να ελέγχει για νέα αλληλογραφία στο παρασκήνιο. Κάντε κλικ στο εικονίδιό του στο Dock για να ανοίξετε την εφαρμογή.
mac-outbox-waiting =
    { $count ->
        [one] { $count } μήνυμα στα Εξερχόμενα
       *[other] { $count } μηνύματα στα Εξερχόμενα
    }
mac-sending = Αποστολή μηνύματος { $subject }…
mac-checking = Έλεγχος για νέα μηνύματα: { $account }…
mac-account-said = { $account }: { $message }
mac-not-bundle = Αυτό το αντίγραφο του Inbox Classic δεν είναι πακέτο εφαρμογής, οπότε δεν μπορεί να γίνει η προεπιλεγμένη εφαρμογή αλληλογραφίας.
mac-not-made-default = Το Inbox Classic δεν ορίστηκε ως προεπιλεγμένη εφαρμογή αλληλογραφίας: { $reason }
mac-tool-search = Αναζήτηση

## The folders and the message list

mac-still-indexing-more =
    { $count ->
        [one] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος, οπότε ίσως εμφανιστούν σύντομα περισσότερα αποτελέσματα.
       *[other] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων, οπότε ίσως εμφανιστούν σύντομα περισσότερα αποτελέσματα.
    }
mac-results-everywhere =
    { $count ->
        [0] Κανένα αποτέλεσμα για «{ $words }» σε όλους τους φακέλους
        [one] { $count } αποτέλεσμα για «{ $words }» σε όλους τους φακέλους
       *[other] { $count } αποτελέσματα για «{ $words }» σε όλους τους φακέλους
    }
mac-results-in =
    { $count ->
        [0] Κανένα αποτέλεσμα για «{ $words }» στον φάκελο «{ $folder }»
        [one] { $count } αποτέλεσμα για «{ $words }» στον φάκελο «{ $folder }»
       *[other] { $count } αποτελέσματα για «{ $words }» στον φάκελο «{ $folder }»
    }
mac-still-indexing =
    { $count ->
        [one] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος
       *[other] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων
    }
mac-folder-unread = { $folder }, { $count ->
    [one] { $count } αδιάβαστο
   *[other] { $count } αδιάβαστα
}
mac-import-messages = Εισαγωγή μηνυμάτων
mac-save-messages = Αποθήκευση μηνυμάτων
mac-save-attachments-menu = Αποθήκευση συνημμένων…
mac-files-not-saved =
    { $count ->
       *[other] Αρχεία που δεν αποθηκεύτηκαν: { $failed } από { $count }.
    }
mac-no-calendar-app = Δεν υπάρχει εφαρμογή ημερολογίου σε αυτό το Mac για το άνοιγμα προσκλήσεων (αρχεία .ics).
mac-file-not-saved = Δεν ήταν δυνατή η αποθήκευση του αρχείου.
mac-unsubscribing = Κατάργηση εγγραφής από { $target }…
mac-loading-list = Φόρτωση…

## The compose window

mac-bold = Έντονα
mac-italic = Πλάγια
mac-underline = Υπογράμμιση
mac-bcc = Ιδ. κοιν.
mac-command-click-to-open = ⌘-κλικ για άνοιγμα
mac-saving-to-drafts = Αποθήκευση στα Πρόχειρα…
mac-dont-save = Χωρίς αποθήκευση

## The reading pane

mac-files =
    { $count ->
        [one] { $count } αρχείο
       *[other] { $count } αρχεία
    }

## Accounts

mac-next = Επόμενο
mac-name-placeholder = Άννα Παπαδοπούλου
mac-more-sign-in-options = Περισσότεροι τρόποι σύνδεσης…
mac-add-sign-in-app = Προσθήκη εφαρμογής σύνδεσης…
mac-looking-up = Αναζήτηση ρυθμίσεων για τον τομέα { $domain }…
mac-add-button = Προσθήκη…
mac-properties-button = Ιδιότητες…
mac-signature-button = Υπογραφή…
mac-security-button = Ασφάλεια…
mac-sign-in-apps-button = Εφαρμογές σύνδεσης…

## AI agents

mac-forget-program = Θέλετε να αφαιρέσετε αυτό το πρόγραμμα από τη λίστα και να διαγράψετε το ιστορικό δραστηριότητας των πρακτόρων του;
mac-forget-program-detail = Τα δικαιώματα του προγράμματος θα διαγραφούν. Θα σας ζητηθεί ξανά άδεια την επόμενη φορά που θα συνδεθεί.

## Sign-in apps

mac-checking-issuer = Έλεγχος εκδότη: { $issuer }…
mac-edit-button = Επεξεργασία…
mac-use-for-new-accounts = Χρήση της εφαρμογής { $name } για νέους λογαριασμούς
mac-built-in = { $name } (ενσωματωμένη)

## Other windows

mac-new-folder-button = Νέος φάκελος…
mac-edit-link = Επεξεργασία συνδέσμου…
