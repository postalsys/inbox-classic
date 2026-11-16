# Ελληνικά. Προσχέδιο, περιμένει έλεγχο από φυσικό ομιλητή (βλ. core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

# review: new
win-still-running-detail = Το Inbox Classic συνεχίζει να ελέγχει για νέα αλληλογραφία στο παρασκήνιο. Κάντε κλικ στο εικονίδιο για να το ανοίξετε. Για έξοδο, κάντε δεξί κλικ στο εικονίδιο και χρησιμοποιήστε το μενού του.
# review: new
win-default-app-not-installed = Αυτό το αντίγραφο του Inbox Classic δεν εγκαταστάθηκε, οπότε τα Windows δεν το εμφανίζουν ως εφαρμογή αλληλογραφίας. Εγκαταστήστε το για να μπορείτε να το επιλέξετε.
# review: new
win-default-app-settings = Τα Windows θα ανοίξουν τις ρυθμίσεις Προεπιλεγμένες εφαρμογές. Επιλέξτε το Inbox Classic για το άνοιγμα των συνδέσμων MAILTO.
# review: new
win-no-unread = Δεν υπάρχουν αδιάβαστα μηνύματα
# review: new
win-unread-messages = { $count ->
    [one] { $count } αδιάβαστο μήνυμα
   *[other] { $count } αδιάβαστα μηνύματα
}
# review: new
win-print-failed = Δεν ήταν δυνατή η εκτύπωση του μηνύματος.
# review: new
win-print-title-of = Εκτύπωση: { $subject }
# review: new
win-no-bodies = Δεν είναι δυνατή η εμφάνιση του κειμένου των μηνυμάτων.
# review: new
win-webview-failed = Η δημιουργία του WebView2 απέτυχε.
# review: new
win-webview-missing = Το WebView2 Runtime δεν είναι διαθέσιμο.
# review: new
win-list-loading = Φόρτωση...

## Buttons and words used in many windows

# review: new
win-delete-button = &Διαγραφή
# review: new
win-find-label = &Εύρεση:
# review: new
win-save-as-button = Αποθήκευση &ως...
# review: new
win-too-many-files = Πάρα πολλά αρχεία ταυτόχρονα: επιλέξτε λιγότερα.

## The Outbox


## The compose window

# review: new
win-editor-failed = Δεν είναι δυνατή η σύνταξη μηνυμάτων.
# review: new
win-ctrl-click-to-open = ({ $ctrl }+κλικ για άνοιγμα)
# review: new
win-format-bold = Έντονα ({ $ctrl }+B)
# review: new
win-format-italic = Πλάγια ({ $ctrl }+I)
# review: new
win-format-underline = Υπογράμμιση ({ $ctrl }+U)
# review: new
win-format-link = Υπερσύνδεση ({ $ctrl }+K)
# review: new
win-show-cc = &Κοιν.
# review: new
win-show-bcc = &Ιδ. κοιν.
# review: new
win-signature-title = Υπογραφή: { $account }

## The folders, the message list and the reading pane

# review: new
win-search-found-all = { $count ->
    [0] Κανένα αποτέλεσμα για «{ $words }» σε όλους τους φακέλους
    [one] { $count } αποτέλεσμα για «{ $words }» σε όλους τους φακέλους
   *[other] { $count } αποτελέσματα για «{ $words }» σε όλους τους φακέλους
}
# review: new
win-search-found-in = { $count ->
    [0] Κανένα αποτέλεσμα για «{ $words }» στον φάκελο «{ $folder }»
    [one] { $count } αποτέλεσμα για «{ $words }» στον φάκελο «{ $folder }»
   *[other] { $count } αποτελέσματα για «{ $words }» στον φάκελο «{ $folder }»
}
# review: new
win-search-indexing = { $count ->
    [one] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος
   *[other] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων
}
# review: new
win-no-match-indexing = { $count ->
    [one] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος, οπότε ίσως βρεθούν σύντομα περισσότερα.
   *[other] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων, οπότε ίσως βρεθούν σύντομα περισσότερα.
}
# review: new
win-files = { $count ->
    [one] { $count } αρχείο
   *[other] { $count } αρχεία
}
# review: new
win-click-to-retry = Κάντε κλικ εδώ για να δοκιμάσετε ξανά.
# review: new
win-save-attachments = &Αποθήκευση συνημμένων...
# review: new
win-files-not-saved = Δεν ήταν δυνατή η αποθήκευση { $failed } από τα { $count } αρχεία.
# review: new
win-new-folder-in-highlighted = Ο νέος φάκελος θα δημιουργηθεί μέσα στον επιλεγμένο φάκελο.
# review: new
win-delete-folder-ask = Να διαγραφεί ο φάκελος «{ $folder }» μαζί με τα μηνύματά του και τους φακέλους που περιέχει; Διαγράφεται και από τον διακομιστή.
# review: new
win-rename = &Μετονομασία...
# review: new
win-messages-not-saved = Δεν ήταν δυνατή η αποθήκευση των μηνυμάτων.
# review: new
win-messages-not-forwarded = Δεν ήταν δυνατή η προώθηση των μηνυμάτων.

## Accounts

# review: new
win-sign-in-google = Σύνδεση με Google
# review: new
win-sign-in-microsoft = Σύνδεση με Microsoft
# review: new
win-next = &Επόμενο >
# review: new
win-your-account = ο λογαριασμός σας
# review: new
win-browser-sign-in = (σύνδεση μέσω προγράμματος περιήγησης)
# review: new
win-add = &Προσθήκη...
# review: new
win-properties-button = Ιδιό&τητες...
# review: new
win-signature-button = &Υπογραφή...
# review: new
win-sign-in-apps-button = Εφαρμογές σύν&δεσης...

## AI agents

# review: new
win-dont-allow = &Να μην επιτρέπεται
# review: new
win-col-address = Διεύθυνση
# review: new
win-never-written-to = Δεν έχετε γράψει ποτέ
# review: new
win-book-find-label = Πληκτρολογήστε όνομα ή διεύθυνση ηλεκτρονικού ταχυδρομείου:
# review: new
win-send = &Αποστολή
# review: new
win-dont-send = Να &μη σταλεί
# review: new
win-forget-program-ask = Να καταργηθεί αυτό το πρόγραμμα, τα δικαιώματά του και το ιστορικό δραστηριότητας των πρακτόρων του; Θα σας ζητηθεί ξανά άδεια την επόμενη φορά που θα συνδεθεί.
# review: new
win-clear-log-ask = Να διαγραφεί το ιστορικό δραστηριότητας των πρακτόρων; Αυτό δεν αναιρεί τις αλλαγές που έκαναν οι πράκτορες.
# review: new
win-agent-programs = &Προγράμματα των οποίων οι πράκτορες ζήτησαν πρόσβαση στην αλληλογραφία σας:
# review: new
win-change = &Αλλαγή...
# review: new
win-what-agents-did = &Δραστηριότητα πρακτόρων:
# review: new
win-how-to-connect = Πώς να συνδέσετε έναν πράκτορα

## Sign-in apps

# review: new
win-built-in = (ενσωματωμένη)
# review: new
win-edit = &Επεξεργασία...

## Options

# review: new
win-options-language-label = &Γλώσσα του Inbox Classic:
# review: new
win-options-restart-note = Επανεκκινήστε το Inbox Classic για να αλλάξει η γλώσσα.
# review: new
win-options-notify = &Ειδοποίηση όταν φτάνει νέα αλληλογραφία
# review: new
win-restart-ask = Το Inbox Classic θα εμφανίζεται στα { $language } μετά την επανεκκίνηση. Να γίνει επανεκκίνηση τώρα;
# review: new
win-folders-hide = Απόκρυψη της λίστας φακέλων
# review: new
win-folders-pin = Διατήρηση της λίστας φακέλων δίπλα στα μηνύματα
# review: new
win-folders-show = Εμφάνιση των φακέλων

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
# review: new
win-installer-start = Εκκίνηση του Inbox Classic
# review: new
win-installer-welcome-new =
    Θα εγκατασταθεί το Inbox Classic { $version }, ένα πρόγραμμα ηλεκτρονικού ταχυδρομείου.

    Δεν χρειάζονται δικαιώματα διαχειριστή· εγκαθίσταται μόνο για τον λογαριασμό σας.
# review: new
win-installer-welcome-same =
    Το Inbox Classic { $version } είναι ήδη εγκατεστημένο. Θα εγκατασταθεί ξανά.

    Οι λογαριασμοί και η αλληλογραφία σας διατηρούνται.
# review: new
win-installer-welcome-update =
    Το Inbox Classic { $installed } θα ενημερωθεί στην έκδοση { $version }.

    Αν εκτελείται, θα κλείσει πρώτα. Οι λογαριασμοί και η αλληλογραφία σας διατηρούνται.
# review: new
win-installer-older-ask = Είναι εγκατεστημένο το Inbox Classic { $installed }, που είναι νεότερο από το { $version }. Να εγκατασταθεί παρ’ όλα αυτά η παλαιότερη έκδοση;
# review: new
win-installer-still-running = Το Inbox Classic εκτελείται ακόμη. Κλείστε το και δοκιμάστε ξανά.
# review: new
win-installer-remove-mail-ask = Να καταργηθούν επίσης οι λογαριασμοί και η αλληλογραφία που κρατά το Inbox Classic σε αυτόν τον υπολογιστή; Η αλληλογραφία στους διακομιστές παραμένει.
