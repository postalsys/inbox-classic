# Ελληνικά. Προσχέδιο, περιμένει έλεγχο από φυσικό ομιλητή (βλ. core/locales/GLOSSARY.md).
# The words of the Mac app's own windows (mac/Sources), ids starting with mac-; the menus and the words every platform
# shares are in app.ftl and core.ftl. Placeables in { $braces } are filled in by the app. Mac conventions: an ellipsis
# (…) after a command that asks for more, curly quotes («» in Greek).

## The app and its menus

# review: new
mac-quit = Τερματισμός Inbox Classic
# review: new
mac-settings = Ρυθμίσεις…
# review: new
mac-services = Υπηρεσίες
# review: new
mac-hide = Απόκρυψη Inbox Classic
# review: new
mac-hide-others = Απόκρυψη άλλων
# review: new
mac-show-all = Εμφάνιση όλων
# review: new
mac-check-updates = Έλεγχος για ενημερώσεις…
# review: new
mac-close-window = Κλείσιμο παραθύρου
# review: new
mac-redo = Επανάληψη
# review: new
mac-cut = Αποκοπή
# review: new
mac-paste = Επικόλληση
# review: new
mac-menu-window = Παράθυρο
# review: new
mac-minimize = Ελαχιστοποίηση
# review: new
mac-zoom = Ζουμ
# review: new
mac-no-updates = Αυτή η έκδοση του Inbox Classic δεν υποστηρίζει αυτόματες ενημερώσεις. Κατεβάστε την πιο πρόσφατη έκδοση από το inboxclassic.com.

## Settings

# review: new
mac-settings-title = Ρυθμίσεις
# review: new
mac-language-label = Γλώσσα:
# review: new
mac-restart-hint = Επανεκκινήστε το Inbox Classic για να αλλάξει η γλώσσα.
# review: new
mac-notify-new-mail = Ειδοποίηση όταν φτάνει νέα αλληλογραφία
# review: new
mac-restart-question = Να γίνει τώρα επανεκκίνηση του Inbox Classic για να αλλάξει η γλώσσα;

## Dialogs

# review: new
mac-choose = Επιλογή

## The main window

# review: new
mac-still-running-detail = Το Inbox Classic συνεχίζει να ελέγχει για νέα αλληλογραφία στο παρασκήνιο. Κάντε κλικ στο εικονίδιό του στο Dock για να ανοίξετε την εφαρμογή.
# review: new
mac-outbox-waiting =
    { $count ->
        [one] { $count } μήνυμα στα Εξερχόμενα
       *[other] { $count } μηνύματα στα Εξερχόμενα
    }
# review: new
mac-sending = Αποστολή του { $subject }…
# review: new
mac-checking = Έλεγχος για νέα μηνύματα στο { $account }…
# review: new
mac-account-said = { $account }: { $message }
# review: new
mac-not-bundle = Αυτό το αντίγραφο του Inbox Classic δεν είναι πακέτο εφαρμογής, οπότε δεν μπορεί να γίνει η προεπιλεγμένη εφαρμογή αλληλογραφίας.
# review: new
mac-not-made-default = Το Inbox Classic δεν ορίστηκε ως προεπιλεγμένη εφαρμογή αλληλογραφίας: { $reason }
# review: new
mac-tool-search = Αναζήτηση

## The folders and the message list

# review: new
mac-still-indexing-more =
    { $count ->
        [one] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος, οπότε ίσως βρεθούν σύντομα περισσότερα.
       *[other] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων, οπότε ίσως βρεθούν σύντομα περισσότερα.
    }
# review: new
mac-results-everywhere =
    { $count ->
        [0] Κανένα αποτέλεσμα για «{ $words }» σε όλους τους φακέλους
        [one] { $count } αποτέλεσμα για «{ $words }» σε όλους τους φακέλους
       *[other] { $count } αποτελέσματα για «{ $words }» σε όλους τους φακέλους
    }
# review: new
mac-results-in =
    { $count ->
        [0] Κανένα αποτέλεσμα για «{ $words }» στον φάκελο «{ $folder }»
        [one] { $count } αποτέλεσμα για «{ $words }» στον φάκελο «{ $folder }»
       *[other] { $count } αποτελέσματα για «{ $words }» στον φάκελο «{ $folder }»
    }
# review: new
mac-still-indexing =
    { $count ->
        [one] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος
       *[other] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων
    }
# review: new
mac-folder-unread = { $folder }, { $count } αδιάβαστα
# review: new
mac-import-messages = Εισαγωγή μηνυμάτων
# review: new
mac-save-messages = Αποθήκευση μηνυμάτων
# review: new
mac-save-attachments-menu = Αποθήκευση συνημμένων…
# review: new
mac-files-not-saved =
    { $count ->
       *[other] Δεν ήταν δυνατή η αποθήκευση { $failed } από τα { $count } αρχεία.
    }
# review: new
mac-no-calendar-app = Δεν υπάρχει εφαρμογή ημερολογίου σε αυτό το Mac για το άνοιγμα προσκλήσεων (αρχεία .ics).
# review: new
mac-file-not-saved = Δεν ήταν δυνατή η αποθήκευση του αρχείου.
# review: new
mac-unsubscribing = Κατάργηση εγγραφής από { $target }…

## The compose window

# review: new
mac-bold = Έντονα
# review: new
mac-italic = Πλάγια
# review: new
mac-underline = Υπογράμμιση
# review: new
mac-bcc = Ιδ. κοιν.
# review: new
mac-command-click-to-open = ⌘-κλικ για άνοιγμα
# review: new
mac-saving-to-drafts = Αποθήκευση στα Πρόχειρα…
# review: new
mac-dont-save = Χωρίς αποθήκευση

## The reading pane

# review: new
mac-files =
    { $count ->
        [one] { $count } αρχείο
       *[other] { $count } αρχεία
    }

## Accounts

# review: new
mac-next = Επόμενο
# review: new
mac-name-placeholder = Άννα Παπαδοπούλου
# review: new
mac-more-sign-in-options = Περισσότεροι τρόποι σύνδεσης…
# review: new
mac-add-sign-in-app = Προσθήκη εφαρμογής σύνδεσης…
# review: new
mac-looking-up = Αναζήτηση των ρυθμίσεων του { $domain }…
# review: new
mac-add-button = Προσθήκη…
# review: new
mac-properties-button = Ιδιότητες…
# review: new
mac-signature-button = Υπογραφή…
# review: new
mac-security-button = Ασφάλεια…
# review: new
mac-sign-in-apps-button = Εφαρμογές σύνδεσης…

## AI agents

# review: new
mac-forget-program = Να καταργηθεί αυτό το πρόγραμμα και το ιστορικό δραστηριότητας των πρακτόρων του;
# review: new
mac-forget-program-detail = Τα δικαιώματα του προγράμματος θα διαγραφούν. Θα σας ζητηθεί ξανά άδεια την επόμενη φορά που θα συνδεθεί.

## Sign-in apps

# review: new
mac-checking-issuer = Έλεγχος του { $issuer }…
# review: new
mac-edit-button = Επεξεργασία…
# review: new
mac-use-for-new-accounts = Χρήση της εφαρμογής { $name } για νέους λογαριασμούς
# review: new
mac-built-in = { $name } (ενσωματωμένη)

## Other windows

# review: new
mac-new-folder-button = Νέος φάκελος…
# review: new
mac-edit-link = Επεξεργασία συνδέσμου…
