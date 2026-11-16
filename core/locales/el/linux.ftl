# Ελληνικά. Προσχέδιο, περιμένει έλεγχο από φυσικό ομιλητή (βλ. core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Προτιμήσεις, Έξοδος).

## The main window

# review: new
gtk-search-looks-in = Η αναζήτηση στο «{ $place }» καλύπτει θέματα, αποστολείς, παραλήπτες, ονόματα συνημμένων και κείμενο μηνυμάτων. Ελέγξτε την ορθογραφία ή δοκιμάστε λιγότερες λέξεις.
# review: new
gtk-search-still-indexing = { $count ->
    [one] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος. Ίσως εμφανιστούν σύντομα περισσότερα αποτελέσματα.
   *[other] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων. Ίσως εμφανιστούν σύντομα περισσότερα αποτελέσματα.
}
# review: new
gtk-search-results-everywhere = { $count ->
    [0] Κανένα αποτέλεσμα
    [one] { $count } αποτέλεσμα
   *[other] { $count } αποτελέσματα
} για «{ $words }» σε όλους τους φακέλους
# review: new
gtk-search-results-in = { $count ->
    [0] Κανένα αποτέλεσμα
    [one] { $count } αποτέλεσμα
   *[other] { $count } αποτελέσματα
} για «{ $words }» στο «{ $place }»
# review: new
gtk-search-indexing = { $count ->
    [one] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος
   *[other] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων
}
# review: new
gtk-list-loading = Φόρτωση...
# review: new
gtk-menu-rename = Μετονομασία...
# review: new
gtk-import-one-question = Να εισαχθεί το μήνυμα { $file } στον φάκελο «{ $folder }»;
# review: new
gtk-files-not-saved = Δεν ήταν δυνατή η αποθήκευση { $failed } από τα { $total } αρχεία.
# review: new
gtk-unsubscribe-one-click =
    Να γίνει αποχώρηση από αυτή τη λίστα αλληλογραφίας;

    Το Inbox Classic θα στείλει αίτημα κατάργησης εγγραφής σε: { $target }. Δεν θα ανοίξει καμία ιστοσελίδα και δεν θα σταλεί κανένα μήνυμα.
# review: new
gtk-unsubscribe-mail =
    Να γίνει αποχώρηση από αυτή τη λίστα αλληλογραφίας;

    Για να καταργήσετε την εγγραφή, στείλτε ένα μήνυμα στο { $target }. Το Inbox Classic θα το ετοιμάσει για εσάς. Στείλτε το μήνυμα για επιβεβαίωση.
# review: new
gtk-unsubscribe-web =
    Να γίνει αποχώρηση από αυτή τη λίστα αλληλογραφίας;

    Η σελίδα κατάργησης εγγραφής της λίστας αλληλογραφίας θα ανοίξει στο πρόγραμμα περιήγησης ({ $target }).
# review: new
gtk-unsubscribe-failed = Δεν ήταν δυνατή η κατάργηση εγγραφής: { $problem }
# review: new
gtk-toolbar-create-mail-menu = Σύνταξη από συγκεκριμένο λογαριασμό
# review: new
gtk-toolbar-send-recv-menu = Αποστολή και λήψη αλληλογραφίας για συγκεκριμένο λογαριασμό
# review: new
gtk-main-menu = Κύριο μενού
# review: new
gtk-folder-list = Λίστα φακέλων
# review: new
gtk-quit = Έξοδος

## The Move and Copy window

# review: new
gtk-new-folder-at-top-of = Ο νέος φάκελος μπαίνει στο ανώτατο επίπεδο του { $account }.

## The message list

## Help

## Notifications and the tray

# review: new
gtk-unread-messages = { $count ->
    [0] Δεν υπάρχουν αδιάβαστα μηνύματα
    [one] { $count } αδιάβαστο μήνυμα
   *[other] { $count } αδιάβαστα μηνύματα
}

## The compose window's link menu

## The Outbox

# review: new
gtk-outbox-empty = Δεν υπάρχουν μηνύματα που περιμένουν να σταλούν.
# review: new
gtk-outbox-row = Προς: { $to }  ·  Σε αναμονή από { $queued }  ·  { $status }

## The app

# review: new
gtk-still-running-detail = Το Inbox Classic συνεχίζει να ελέγχει για νέα αλληλογραφία στο παρασκήνιο. Χρησιμοποιήστε το εικονίδιό του στην πάνω γραμμή για να ανοίξετε ή να κλείσετε την εφαρμογή.
# review: new
gtk-sign-in-again-ask =
    Η σύνδεση στο { $account } απορρίφθηκε ή η περίοδος λειτουργίας έληξε.

    Να γίνει ξανά σύνδεση στο πρόγραμμα περιήγησης;
# review: new
gtk-default-app-not-installed = Αυτό το αντίγραφο του Inbox Classic δεν εγκαταστάθηκε, οπότε το σύστημα δεν το εμφανίζει ως εφαρμογή αλληλογραφίας. Εγκαταστήστε το για να μπορείτε να το επιλέξετε.
# review: new
gtk-default-app-now = Το Inbox Classic είναι πλέον η προεπιλεγμένη εφαρμογή αλληλογραφίας σας: οι σύνδεσμοι ηλεκτρονικού ταχυδρομείου ανοίγουν νέο μήνυμα εδώ.
# review: new
gtk-default-app-failed = Δεν ήταν δυνατό να οριστεί το Inbox Classic ως προεπιλεγμένη εφαρμογή αλληλογραφίας.

## Buttons and words used in many windows

## The reading pane

# review: new
gtk-reader-date = Ημερομηνία:
# review: new
gtk-reader-files = Συνημμένα μηνύματος
# review: new
gtk-files = { $count ->
    [one] { $count } αρχείο
   *[other] { $count } αρχεία
}
# review: new
gtk-pictures-blocked = Ορισμένες εικόνες αποκλείστηκαν, ώστε να μην μπορεί ο αποστολέας να αναγνωρίσει τον υπολογιστή σας.
# review: new
gtk-download-pictures = Λήψη εικόνων
# review: new
gtk-save-attachments-menu = Αποθήκευση συνημμένων...

## The compose window

# review: new
gtk-format-bold = Έντονα (Ctrl+B)
# review: new
gtk-format-italic = Πλάγια (Ctrl+I)
# review: new
gtk-format-underline = Υπογράμμιση (Ctrl+U)
# review: new
gtk-format-hyperlink = Υπερσύνδεση (Ctrl+K)
# review: new
gtk-font = Γραμματοσειρά
# review: new
gtk-show-cc = _Κοιν.
# review: new
gtk-show-bcc = _Ιδ. κοιν.
# review: new
gtk-save-tip = Αποθήκευση (Ctrl+S)
# review: new
gtk-link-status = { $link }    (Ctrl+κλικ για άνοιγμα)

## Accounts

# review: new
gtk-plain-warning =
    Χωρίς κρυπτογράφηση, όποιος υποκλέψει την κίνηση του δικτύου σας μπορεί να διαβάσει τον κωδικό πρόσβασης και τα μηνύματά σας. Χρησιμοποιήστε αυτή τη σύνδεση μόνο με διακομιστή στον δικό σας υπολογιστή ή στο τοπικό σας δίκτυο.

    Συνέχεια;
# review: new
gtk-account-name-title = Όνομα λογαριασμού
# review: new
gtk-display-name-title = Εμφανιζόμενο όνομα
# review: new
gtk-turned-off-why = Η επιλογή «{ $button }» είναι απενεργοποιημένη σε αυτόν τον υπολογιστή. { $reason }
# review: new
gtk-turned-off-why-long =
    Η επιλογή «{ $button }» είναι απενεργοποιημένη σε αυτόν τον υπολογιστή.

    { $reason }
# review: new
gtk-next = Επόμενο >
# review: new
gtk-provider-sign-in = Συνδεθείτε στο { $address } στον ιστότοπο του παρόχου ({ $provider }). Ο κωδικός πρόσβασής σας δεν κοινοποιείται στο Inbox Classic. Μπορείτε επίσης να χρησιμοποιήσετε έναν κωδικό πρόσβασης εφαρμογής που δημιουργήσατε στις ρυθμίσεις ασφαλείας του λογαριασμού σας.
# review: new
gtk-provider-sign-in-apps = Συνδεθείτε στο { $address } στον ιστότοπο του παρόχου ({ $provider }) με μία από τις εφαρμογές σύνδεσής σας (Περισσότεροι τρόποι σύνδεσης). Μπορείτε επίσης να χρησιμοποιήσετε έναν κωδικό πρόσβασης εφαρμογής που δημιουργήσατε στις ρυθμίσεις ασφαλείας του λογαριασμού σας.
# review: new
gtk-accounts-add = Προσθήκη...
# review: new
gtk-accounts-properties = Ιδιότητες...
# review: new
gtk-accounts-signature = Υπογραφή...
# review: new
gtk-accounts-sign-in-apps = Εφαρμογές σύνδεσης...

## Sign-in apps

# review: new
gtk-app-server = Διακομιστής { $kind }
# review: new
gtk-app-port = Θύρα { $kind }
# review: new
gtk-app-security = Ασφάλεια { $kind }
# review: new
gtk-issuer-found =
    Σελίδα σύνδεσης: { $page }
    Τελικό σημείο διακριτικών: { $endpoint }
# review: new
gtk-client-id = Αναγνωριστικό πελάτη
# review: new
gtk-client-secret = Μυστικό πελάτη
# review: new
gtk-scopes = Δικαιώματα (scopes)
# review: new
gtk-redirect-uri = URI ανακατεύθυνσης
# review: new
gtk-issuer-usable =
    Ο εκδότης μπορεί να χρησιμοποιηθεί.

    { $found }
# review: new
gtk-app-built-in = Η εφαρμογή { $app } είναι ενσωματωμένη. Μπορείτε να αλλάξετε μόνο αν προσφέρεται για νέους λογαριασμούς. { $reason }
# review: new
gtk-built-in = { $app } (ενσωματωμένη)
# review: new
gtk-offered-for-new = Προσφέρεται για νέους λογαριασμούς
# review: new
gtk-edit-button = Επεξεργασία...
# review: new
gtk-remove-app-ask = Να καταργηθεί η εφαρμογή σύνδεσης { $app } και το αποθηκευμένο μυστικό πελάτη της;
# review: new
gtk-sign-in-apps-intro = Οι εφαρμογές σύνδεσης επιτρέπουν στους λογαριασμούς να συνδέονται μέσω του προγράμματος περιήγησης. Όποια είναι απενεργοποιημένη δεν προσφέρεται για νέους λογαριασμούς· οι λογαριασμοί που ήδη τη χρησιμοποιούν συνεχίζουν να λειτουργούν.

## AI agents

# review: new
gtk-agent-it-may = Επιτρεπόμενες ενέργειες
# review: new
gtk-agent-accounts = Επιτρεπόμενοι λογαριασμοί
# review: new
gtk-never-used = Δεν έχει χρησιμοποιηθεί ποτέ
# review: new
gtk-last-used = Τελευταία χρήση { $date }
# review: new
gtk-forget-program = Να καταργηθεί αυτό το πρόγραμμα;
# review: new
gtk-forget-program-detail = Τα δικαιώματα του προγράμματος και το ιστορικό δραστηριότητας των πρακτόρων του θα διαγραφούν. Θα σας ζητηθεί ξανά άδεια την επόμενη φορά που θα συνδεθεί.
# review: new
gtk-no-agents-yet = Κανένας πράκτορας δεν έχει ζητήσει ακόμη να χρησιμοποιήσει την αλληλογραφία σας.
# review: new
gtk-nothing-yet = Τίποτα ακόμη.

## Preferences

# review: new
gtk-preferences = Προτιμήσεις
# review: new
gtk-language = Γλώσσα
# review: new
gtk-language-subtitle = Γλώσσα της εφαρμογής και της βοήθειας
# review: new
gtk-new-mail-group = Νέα αλληλογραφία
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
# review: new
gtk-notify-new-mail = Ειδοποίηση για νέα αλληλογραφία
# review: new
gtk-notify-subtitle = Ειδοποίηση όταν φτάνουν νέα μηνύματα ενώ το παράθυρο είναι στο παρασκήνιο
# review: new
gtk-restart-to-change = Το Inbox Classic θα επανεκκινηθεί για να αλλάξει η γλώσσα.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
# review: new
gtk-desktop-generic-name = Πρόγραμμα ηλεκτρονικού ταχυδρομείου
# review: new
gtk-desktop-comment = Διαβάστε και γράψτε email: ένα γρήγορο, απλό πρόγραμμα αλληλογραφίας
# review: new
gtk-desktop-keywords = αλληλογραφία;ηλεκτρονικό ταχυδρομείο;μήνυμα;εισερχόμενα;
# review: new
gtk-metainfo-summary = Ένα γρήγορο, απλό πρόγραμμα αλληλογραφίας
# review: new
gtk-metainfo-description = Το Inbox Classic διαβάζει και γράφει email με τους φακέλους αριστερά, τα μηνύματα επάνω και το μήνυμα από κάτω, όπως τα παλιά προγράμματα αλληλογραφίας. Λειτουργεί με οποιονδήποτε λογαριασμό IMAP και SMTP και συνδέεται στο Outlook.com και στο Microsoft 365 μέσω του προγράμματος περιήγησης.
# review: new
gtk-metainfo-feature-sanitized = Κάθε μήνυμα εμφανίζεται καθαρισμένο, χωρίς σενάρια εντολών, και οι εικόνες από το διαδίκτυο μόνο όταν το επιτρέψετε
# review: new
gtk-metainfo-feature-search = Αναζήτηση που βρίσκει λέξεις στο θέμα, στους αποστολείς και παραλήπτες, στα ονόματα αρχείων και στο κείμενο, με τους τελεστές του Gmail
# review: new
gtk-metainfo-feature-replies = Οι απαντήσεις αναδιπλώνουν τα προηγούμενα μηνύματα που παραθέτουν
# review: new
gtk-metainfo-feature-offline = Η αλληλογραφία μένει αναγνώσιμη χωρίς σύνδεση· οι κωδικοί πρόσβασης φυλάσσονται στην κλειδοθήκη σας
