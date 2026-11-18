# Ελληνικά. Προσχέδιο, περιμένει έλεγχο από φυσικό ομιλητή (βλ. core/locales/GLOSSARY.md).
# The words of the Windows app's own windows (app/src), ids starting with win-. Placeables in { $braces } are filled in
# by the app; an & marks a menu or button letter (&& is an ampersand).

## The main window

win-still-running-detail = Το Inbox Classic συνεχίζει να ελέγχει για νέα αλληλογραφία στο παρασκήνιο. Κάντε κλικ στο εικονίδιο για να το ανοίξετε. Για έξοδο, κάντε δεξί κλικ στο εικονίδιο και χρησιμοποιήστε το μενού του.
win-default-app-not-installed = Αυτό το αντίγραφο του Inbox Classic δεν εγκαταστάθηκε, οπότε τα Windows δεν το εμφανίζουν ως εφαρμογή αλληλογραφίας. Εγκαταστήστε το για να μπορείτε να το επιλέξετε.
win-default-app-settings = Τα Windows θα ανοίξουν τις ρυθμίσεις Προεπιλεγμένες εφαρμογές. Επιλέξτε το Inbox Classic για το άνοιγμα των συνδέσμων MAILTO.
win-no-unread = Δεν υπάρχουν αδιάβαστα μηνύματα
win-unread-messages = { $count ->
    [one] { $count } αδιάβαστο μήνυμα
   *[other] { $count } αδιάβαστα μηνύματα
}
win-print-failed = Δεν ήταν δυνατή η εκτύπωση του μηνύματος.
win-print-title-of = Εκτύπωση: { $subject }
win-no-bodies = Δεν είναι δυνατή η εμφάνιση του κειμένου των μηνυμάτων.
win-webview-failed = Δεν ήταν δυνατή η εκκίνηση του WebView2.
win-webview-missing = Το WebView2 Runtime δεν είναι διαθέσιμο.
win-list-loading = Φόρτωση...

## Buttons and words used in many windows

win-delete-button = Διαγ&ραφή
win-find-label = &Εύρεση:
win-save-as-button = Αποθήκευση &ως...
win-too-many-files = Πάρα πολλά αρχεία ταυτόχρονα: επιλέξτε λιγότερα.

## The Outbox


## The compose window

win-editor-failed = Δεν είναι δυνατή η σύνταξη μηνυμάτων.
win-ctrl-click-to-open = ({ $ctrl }+κλικ για άνοιγμα)
win-format-bold = Έντονα ({ $ctrl }+B)
win-format-italic = Πλάγια ({ $ctrl }+I)
win-format-underline = Υπογράμμιση ({ $ctrl }+U)
win-format-link = Υπερσύνδεση ({ $ctrl }+K)
win-show-cc = &Κοιν.
win-show-bcc = &Ιδ. κοιν.
win-signature-title = Υπογραφή: { $account }

## The folders, the message list and the reading pane

win-search-found-all = { $count ->
    [0] Κανένα αποτέλεσμα για «{ $words }» σε όλους τους φακέλους
    [one] { $count } αποτέλεσμα για «{ $words }» σε όλους τους φακέλους
   *[other] { $count } αποτελέσματα για «{ $words }» σε όλους τους φακέλους
}
win-search-found-in = { $count ->
    [0] Κανένα αποτέλεσμα για «{ $words }» στον φάκελο «{ $folder }»
    [one] { $count } αποτέλεσμα για «{ $words }» στον φάκελο «{ $folder }»
   *[other] { $count } αποτελέσματα για «{ $words }» στον φάκελο «{ $folder }»
}
win-search-indexing = { $count ->
    [one] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος
   *[other] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων
}
win-no-match-indexing = { $count ->
    [one] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος, οπότε ίσως εμφανιστούν σύντομα περισσότερα αποτελέσματα.
   *[other] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων, οπότε ίσως εμφανιστούν σύντομα περισσότερα αποτελέσματα.
}
win-files = { $count ->
    [one] { $count } αρχείο
   *[other] { $count } αρχεία
}
win-click-to-retry = Κάντε κλικ εδώ για να δοκιμάσετε ξανά.
win-save-attachments = &Αποθήκευση συνημμένων...
win-files-not-saved = Αρχεία που δεν αποθηκεύτηκαν: { $failed } από { $count }.
win-new-folder-in-highlighted = Ο νέος φάκελος θα δημιουργηθεί μέσα στον επιλεγμένο φάκελο.
win-delete-folder-ask = Να διαγραφεί ο φάκελος «{ $folder }» μαζί με τα μηνύματά του και τους φακέλους που περιέχει; Διαγράφεται και από τον διακομιστή.
win-rename = &Μετονομασία...
win-messages-not-saved = Δεν ήταν δυνατή η αποθήκευση των μηνυμάτων.
win-messages-not-forwarded = Δεν ήταν δυνατή η προώθηση των μηνυμάτων.

## Accounts

win-sign-in-google = Σύνδεση με Google
win-sign-in-microsoft = Σύνδεση με Microsoft
win-next = &Επόμενο >
win-your-account = ο λογαριασμός σας
win-browser-sign-in = (σύνδεση μέσω προγράμματος περιήγησης)
win-add = &Προσθήκη...
win-properties-button = Ιδιό&τητες...
win-signature-button = &Υπογραφή...
win-sign-in-apps-button = Εφαρμογές σύν&δεσης...

## AI agents

win-dont-allow = &Να μην επιτρέπεται
win-col-address = Διεύθυνση
win-never-written-to = Δεν έχετε γράψει ποτέ
win-book-find-label = Πληκτρολογήστε όνομα ή διεύθυνση ηλεκτρονικού ταχυδρομείου:
win-send = &Αποστολή
win-dont-send = Να &μη σταλεί
win-unsubscribe = &Κατάργηση εγγραφής
win-dont-unsubscribe = &Διατήρηση εγγραφής
win-forget-program-ask = Θέλετε να αφαιρέσετε αυτό το πρόγραμμα από τη λίστα και να διαγράψετε τα δικαιώματά του και το ιστορικό δραστηριότητας των πρακτόρων του; Θα σας ζητηθεί ξανά άδεια την επόμενη φορά που θα συνδεθεί.
win-clear-log-ask = Να διαγραφεί το ιστορικό δραστηριότητας των πρακτόρων; Αυτό δεν αναιρεί τις αλλαγές που έκαναν οι πράκτορες.
win-agent-programs = &Προγράμματα των οποίων οι πράκτορες ζήτησαν πρόσβαση στην αλληλογραφία σας:
win-change = &Αλλαγή...
win-what-agents-did = &Δραστηριότητα πρακτόρων:
# review: new
win-agent-reads = Τι διαβάστηκε από { $from } έως { $to }:
# review: new
win-agent-reads-hint = Επιλέξτε παραπάνω μια γραμμή αναγνώσεων για να δείτε τι διαβάστηκε.
win-how-to-connect = Πώς να συνδέσετε έναν πράκτορα

## Sign-in apps

win-built-in = (ενσωματωμένη)
win-edit = &Επεξεργασία...

## Options

win-folders-hide = Απόκρυψη της λίστας φακέλων
win-folders-pin = Διατήρηση της λίστας φακέλων δίπλα στα μηνύματα
win-folders-show = Εμφάνιση των φακέλων

## The installer

# the installer's own words (installer/inbox-classic.nsi), made into installer/languages.nsh by the build;
# { $version } and { $installed } are version numbers, 0.18.0
win-installer-start = Εκκίνηση του Inbox Classic
win-installer-welcome-new =
    Θα εγκατασταθεί το Inbox Classic { $version }, ένα πρόγραμμα ηλεκτρονικού ταχυδρομείου.

    Δεν απαιτούνται δικαιώματα διαχειριστή. Η εγκατάσταση γίνεται μόνο για τον δικό σας λογαριασμό χρήστη των Windows.
win-installer-welcome-same =
    Το Inbox Classic { $version } είναι ήδη εγκατεστημένο. Θα εγκατασταθεί ξανά.

    Οι λογαριασμοί και η αλληλογραφία σας διατηρούνται.
win-installer-welcome-update =
    Το Inbox Classic { $installed } θα ενημερωθεί στην έκδοση { $version }.

    Αν εκτελείται, θα κλείσει πρώτα. Οι λογαριασμοί και η αλληλογραφία σας διατηρούνται.
win-installer-older-ask = Η εγκατεστημένη έκδοση του Inbox Classic ({ $installed }) είναι νεότερη από την έκδοση { $version }. Θέλετε να εγκαταστήσετε την παλαιότερη έκδοση;
win-installer-still-running = Το Inbox Classic εκτελείται ακόμη. Κλείστε το και δοκιμάστε ξανά.
win-installer-remove-mail-ask = Θέλετε να διαγραφούν επίσης οι λογαριασμοί και τα τοπικά αντίγραφα αλληλογραφίας που αποθηκεύει το Inbox Classic; Η αλληλογραφία στους διακομιστές θα παραμείνει.
