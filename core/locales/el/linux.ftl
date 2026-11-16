# Ελληνικά. Προσχέδιο, περιμένει έλεγχο από φυσικό ομιλητή (βλ. core/locales/GLOSSARY.md).
# The words of the Linux app's own windows (linux/src), ids starting with gtk-. Placeables in { $braces } are filled in
# by the app; an _ marks a button's mnemonic letter. GNOME words where GNOME has them (Προτιμήσεις, Έξοδος).

## The main window

gtk-search-looks-in = Περιοχή αναζήτησης: { $place }. Η αναζήτηση καλύπτει θέματα, αποστολείς, παραλήπτες, ονόματα συνημμένων και κείμενο μηνυμάτων. Ελέγξτε την ορθογραφία ή δοκιμάστε λιγότερες λέξεις.
gtk-search-still-indexing = { $count ->
    [one] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος. Ίσως εμφανιστούν σύντομα περισσότερα αποτελέσματα.
   *[other] Γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων. Ίσως εμφανιστούν σύντομα περισσότερα αποτελέσματα.
}
gtk-search-results-everywhere = { $count ->
    [0] Κανένα αποτέλεσμα
    [one] { $count } αποτέλεσμα
   *[other] { $count } αποτελέσματα
} για «{ $words }» σε όλους τους φακέλους
gtk-search-results-in = { $count ->
    [0] Κανένα αποτέλεσμα
    [one] { $count } αποτέλεσμα
   *[other] { $count } αποτελέσματα
} για «{ $words }» στο «{ $place }»
gtk-search-indexing = { $count ->
    [one] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνύματος
   *[other] γίνεται ακόμη ευρετηρίαση του κειμένου { $count } μηνυμάτων
}
gtk-list-loading = Φόρτωση...
gtk-menu-rename = Μετονομασία...
gtk-import-one-question = Να εισαχθεί το μήνυμα { $file } στον φάκελο «{ $folder }»;
gtk-files-not-saved = Αρχεία που δεν αποθηκεύτηκαν: { $failed } από { $total }.
gtk-unsubscribe-one-click =
    Θέλετε να καταργήσετε την εγγραφή σας σε αυτή τη λίστα αλληλογραφίας;

    Το Inbox Classic θα στείλει αίτημα κατάργησης εγγραφής σε: { $target }. Δεν θα ανοίξει καμία ιστοσελίδα και δεν θα σταλεί κανένα μήνυμα.
gtk-unsubscribe-mail =
    Θέλετε να καταργήσετε την εγγραφή σας σε αυτή τη λίστα αλληλογραφίας;

    Για να καταργήσετε την εγγραφή, στείλτε ένα μήνυμα στο { $target }. Το Inbox Classic θα το ετοιμάσει για εσάς. Στείλτε το μήνυμα για επιβεβαίωση.
gtk-unsubscribe-web =
    Θέλετε να καταργήσετε την εγγραφή σας σε αυτή τη λίστα αλληλογραφίας;

    Η σελίδα κατάργησης εγγραφής της λίστας αλληλογραφίας θα ανοίξει στο πρόγραμμα περιήγησης ({ $target }).
gtk-unsubscribe-failed = Δεν ήταν δυνατή η κατάργηση εγγραφής: { $problem }
gtk-toolbar-create-mail-menu = Σύνταξη μηνύματος από συγκεκριμένο λογαριασμό
gtk-toolbar-send-recv-menu = Αποστολή και λήψη αλληλογραφίας για συγκεκριμένο λογαριασμό
gtk-main-menu = Κύριο μενού
gtk-folder-list = Λίστα φακέλων
gtk-quit = Έξοδος

## The Move and Copy window

gtk-new-folder-at-top-of = Ο νέος φάκελος θα δημιουργηθεί στο ανώτατο επίπεδο του λογαριασμού «{ $account }».

## The message list

## Help

## Notifications and the tray

gtk-unread-messages = { $count ->
    [0] Δεν υπάρχουν αδιάβαστα μηνύματα
    [one] { $count } αδιάβαστο μήνυμα
   *[other] { $count } αδιάβαστα μηνύματα
}

## The compose window's link menu

## The Outbox

gtk-outbox-empty = Δεν υπάρχουν μηνύματα που περιμένουν να σταλούν.
gtk-outbox-row = Προς: { $to }  ·  Σε αναμονή από { $queued }  ·  { $status }

## The app

gtk-still-running-detail = Το Inbox Classic συνεχίζει να ελέγχει για νέα αλληλογραφία στο παρασκήνιο. Χρησιμοποιήστε το εικονίδιό του στην πάνω γραμμή για να ανοίξετε ή να κλείσετε την εφαρμογή.
gtk-sign-in-again-ask =
    { $account }: Η σύνδεση απορρίφθηκε ή η περίοδος σύνδεσης έληξε.

    Θέλετε να συνδεθείτε ξανά μέσω του προγράμματος περιήγησης;
gtk-default-app-not-installed = Αυτό το αντίγραφο του Inbox Classic δεν εγκαταστάθηκε, οπότε το σύστημα δεν το εμφανίζει ως εφαρμογή αλληλογραφίας. Εγκαταστήστε το για να μπορείτε να το επιλέξετε.
gtk-default-app-now = Το Inbox Classic είναι πλέον η προεπιλεγμένη εφαρμογή αλληλογραφίας σας: οι σύνδεσμοι ηλεκτρονικού ταχυδρομείου ανοίγουν νέο μήνυμα εδώ.
gtk-default-app-failed = Δεν ήταν δυνατό να οριστεί το Inbox Classic ως προεπιλεγμένη εφαρμογή αλληλογραφίας.

## Buttons and words used in many windows

## The reading pane

gtk-reader-date = Ημερομηνία:
gtk-reader-files = Συνημμένα μηνύματος
gtk-files = { $count ->
    [one] { $count } αρχείο
   *[other] { $count } αρχεία
}
gtk-pictures-blocked = Ορισμένες εικόνες αποκλείστηκαν για να περιοριστεί η δυνατότητα παρακολούθησης από τον αποστολέα.
gtk-download-pictures = Λήψη εικόνων
gtk-save-attachments-menu = Αποθήκευση συνημμένων...

## The compose window

gtk-format-bold = Έντονα (Ctrl+B)
gtk-format-italic = Πλάγια (Ctrl+I)
gtk-format-underline = Υπογράμμιση (Ctrl+U)
gtk-format-hyperlink = Υπερσύνδεση (Ctrl+K)
gtk-font = Γραμματοσειρά
gtk-show-cc = _Κοιν.
gtk-show-bcc = _Ιδ. κοιν.
gtk-save-tip = Αποθήκευση (Ctrl+S)
gtk-link-status = { $link }    (Ctrl+κλικ για άνοιγμα)

## Accounts

gtk-plain-warning =
    Χωρίς κρυπτογράφηση, όποιος υποκλέψει την κίνηση του δικτύου σας μπορεί να διαβάσει τον κωδικό πρόσβασης και τα μηνύματά σας. Χρησιμοποιήστε αυτή τη σύνδεση μόνο με διακομιστή στον δικό σας υπολογιστή ή στο τοπικό σας δίκτυο.

    Συνέχεια;
gtk-account-name-title = Όνομα λογαριασμού
gtk-display-name-title = Εμφανιζόμενο όνομα
gtk-turned-off-why = Η επιλογή «{ $button }» είναι απενεργοποιημένη σε αυτόν τον υπολογιστή. { $reason }
gtk-turned-off-why-long =
    Η επιλογή «{ $button }» είναι απενεργοποιημένη σε αυτόν τον υπολογιστή.

    { $reason }
gtk-next = Επόμενο >
gtk-provider-sign-in = Συνδεθείτε στον λογαριασμό { $address } στον ιστότοπο του παρόχου ({ $provider }). Ο κωδικός πρόσβασής σας δεν κοινοποιείται στο Inbox Classic. Μπορείτε επίσης να χρησιμοποιήσετε έναν κωδικό πρόσβασης εφαρμογής που δημιουργήσατε στις ρυθμίσεις ασφαλείας του λογαριασμού σας.
gtk-provider-sign-in-apps = Συνδεθείτε στον λογαριασμό { $address } στον ιστότοπο του παρόχου ({ $provider }) με μία από τις εφαρμογές σύνδεσής σας (Περισσότεροι τρόποι σύνδεσης). Μπορείτε επίσης να χρησιμοποιήσετε έναν κωδικό πρόσβασης εφαρμογής που δημιουργήσατε στις ρυθμίσεις ασφαλείας του λογαριασμού σας.
gtk-accounts-add = Προσθήκη...
gtk-accounts-properties = Ιδιότητες...
gtk-accounts-signature = Υπογραφή...
gtk-accounts-sign-in-apps = Εφαρμογές σύνδεσης...

## Sign-in apps

gtk-app-server = Διακομιστής { $kind }
gtk-app-port = Θύρα { $kind }
gtk-app-security = Ασφάλεια { $kind }
gtk-issuer-found =
    Σελίδα σύνδεσης: { $page }
    Τελικό σημείο διακριτικών: { $endpoint }
gtk-client-id = Αναγνωριστικό πελάτη
gtk-client-secret = Μυστικό πελάτη
gtk-scopes = Δικαιώματα (scopes)
gtk-redirect-uri = URI ανακατεύθυνσης
gtk-issuer-usable =
    Ο εκδότης μπορεί να χρησιμοποιηθεί.

    { $found }
gtk-app-built-in = Η εφαρμογή { $app } είναι ενσωματωμένη. Μπορείτε να αλλάξετε μόνο αν προσφέρεται για νέους λογαριασμούς. { $reason }
gtk-built-in = { $app } (ενσωματωμένη)
gtk-offered-for-new = Προσφέρεται για νέους λογαριασμούς
gtk-edit-button = Επεξεργασία...
gtk-remove-app-ask = Να καταργηθεί η εφαρμογή σύνδεσης { $app } και το αποθηκευμένο μυστικό πελάτη της;
gtk-sign-in-apps-intro = Οι εφαρμογές σύνδεσης επιτρέπουν στους λογαριασμούς να συνδέονται μέσω του προγράμματος περιήγησης. Όποια είναι απενεργοποιημένη δεν προσφέρεται για νέους λογαριασμούς· οι λογαριασμοί που ήδη τη χρησιμοποιούν συνεχίζουν να λειτουργούν.

## AI agents

gtk-agent-it-may = Επιτρεπόμενες ενέργειες
gtk-agent-accounts = Επιτρεπόμενοι λογαριασμοί
gtk-never-used = Δεν έχει χρησιμοποιηθεί ποτέ
gtk-last-used = Τελευταία χρήση { $date }
gtk-forget-program = Θέλετε να αφαιρέσετε αυτό το πρόγραμμα από τη λίστα;
gtk-forget-program-detail = Τα δικαιώματα του προγράμματος και το ιστορικό δραστηριότητας των πρακτόρων του θα διαγραφούν. Θα σας ζητηθεί ξανά άδεια την επόμενη φορά που θα συνδεθεί.
gtk-no-agents-yet = Κανένας πράκτορας δεν έχει ζητήσει ακόμη πρόσβαση στην αλληλογραφία σας.
gtk-nothing-yet = Τίποτα ακόμη.

## Preferences

gtk-preferences = Προτιμήσεις
gtk-language = Γλώσσα
gtk-language-subtitle = Γλώσσα της εφαρμογής και της βοήθειας
gtk-new-mail-group = Νέα αλληλογραφία
# the row of Preferences that turns the new mail notification on, in sentence case as GNOME writes it
gtk-notify-new-mail = Ειδοποίηση για νέα αλληλογραφία
gtk-notify-subtitle = Ειδοποίηση όταν φτάνουν νέα μηνύματα ενώ το παράθυρο είναι στο παρασκήνιο
gtk-restart-to-change = Το Inbox Classic θα επανεκκινηθεί για να αλλάξει η γλώσσα.

## The desktop entry and the page of the software stores

# linux/data/com.inboxclassic.InboxClassic.desktop and .metainfo.xml, made by the build. The keywords are the words a
# search of the applications finds Inbox Classic by, each ended by a semicolon, in your language only: the English
# ones are added before them
gtk-desktop-generic-name = Πρόγραμμα ηλεκτρονικού ταχυδρομείου
gtk-desktop-comment = Διαβάστε και γράψτε email: ένα γρήγορο, απλό πρόγραμμα αλληλογραφίας
gtk-desktop-keywords = αλληλογραφία;ηλεκτρονικό ταχυδρομείο;μήνυμα;εισερχόμενα;
gtk-metainfo-summary = Ένα γρήγορο, απλό πρόγραμμα αλληλογραφίας
gtk-metainfo-description = Με το Inbox Classic διαβάζετε και γράφετε email σε γνώριμη διάταξη: οι φάκελοι αριστερά, η λίστα μηνυμάτων επάνω και το περιεχόμενο του επιλεγμένου μηνύματος από κάτω. Υποστηρίζει λογαριασμούς IMAP και SMTP, καθώς και σύνδεση στο Outlook.com και στο Microsoft 365 μέσω του προγράμματος περιήγησης.
gtk-metainfo-feature-sanitized = Αφαίρεση επικίνδυνου περιεχομένου και σεναρίων από τα μηνύματα· λήψη εικόνων από το διαδίκτυο μόνο με την άδειά σας
gtk-metainfo-feature-search = Αναζήτηση σε θέματα, αποστολείς, παραλήπτες, ονόματα συνημμένων και κείμενο μηνυμάτων, με τελεστές τύπου Gmail
gtk-metainfo-feature-replies = Σύμπτυξη των προηγούμενων μηνυμάτων που παρατίθενται στις απαντήσεις
gtk-metainfo-feature-offline = Ανάγνωση των μηνυμάτων που έχουν ληφθεί ακόμη και χωρίς σύνδεση· αποθήκευση κωδικών πρόσβασης στην κλειδοθήκη σας
