# Ελληνικά. Προσχέδιο, περιμένει έλεγχο από φυσικό ομιλητή (βλ. core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Greek: [one] and *[other].

## Counts and sizes

messages = { $count ->
    [one] { $count } μήνυμα
   *[other] { $count } μηνύματα
}
# the separator of decimals in sizes: 2,4 MB
decimal-separator = ,
size-bytes = { $count ->
    [one] { $count } byte
   *[other] { $count } byte
}
size-kb = { $size } KB
size-mb = { $size } MB
size-gb = { $size } GB
send-delay-off = Ανενεργό
send-delay-seconds = { $count ->
    [one] { $count } δευτερόλεπτο
   *[other] { $count } δευτερόλεπτα
}
# the status bar: "12 μηνύματα, 3 αδιάβαστα"
list-counts = { $messages }, { $unread ->
    [one] { $unread } αδιάβαστο
   *[other] { $unread } αδιάβαστα
}
list-counts-selected = { $messages }, { $unread ->
    [one] { $unread } αδιάβαστο
   *[other] { $unread } αδιάβαστα
    }, { $selected } επιλεγμένα
# the status bar while searching: "12 βρέθηκαν, 3 αδιάβαστα"
list-counts-found = { $found ->
    [one] Βρέθηκε { $found } μήνυμα
   *[other] Βρέθηκαν { $found } μηνύματα
    }, { $unread ->
    [one] { $unread } αδιάβαστο
   *[other] { $unread } αδιάβαστα
}
list-counts-found-selected = { $found ->
    [one] Βρέθηκε { $found } μήνυμα
   *[other] Βρέθηκαν { $found } μηνύματα
    }, { $unread ->
    [one] { $unread } αδιάβαστο
   *[other] { $unread } αδιάβαστα
    }, { $selected } επιλεγμένα
list-counts-none = Δεν βρέθηκαν μηνύματα

## Special folders, as Outlook names them in Greek

folder-inbox = Εισερχόμενα
folder-sent = Απεσταλμένα
folder-deleted = Διαγραμμένα
folder-drafts = Πρόχειρα
folder-junk = Ανεπιθύμητη αλληλογραφία
folder-archive = Αρχειοθέτηση

## The reading pane

reader-no-message = Δεν έχει επιλεγεί μήνυμα.
reader-downloading = Γίνεται λήψη του μηνύματος…
reader-downloading-detail = Το μήνυμα θα εμφανιστεί εδώ μόλις ολοκληρωθεί η λήψη.
reader-downloading-size = Το μήνυμα έχει μέγεθος { $size }. Θα εμφανιστεί εδώ μόλις γίνει η λήψη του.
reader-failed = Δεν ήταν δυνατή η λήψη του μηνύματος
reader-failed-network = Ο διακομιστής αλληλογραφίας δεν ήταν προσβάσιμος ({ $reason }).
reader-failed-sign-in = Ο διακομιστής αλληλογραφίας δεν δέχτηκε τη σύνδεση ({ $reason }). Ελέγξτε τον κωδικό πρόσβασης ή συνδεθείτε ξανά από το Αρχείο > Λογαριασμοί.
reader-failed-security = Δεν ήταν δυνατή η ασφαλής σύνδεση με τον διακομιστή αλληλογραφίας ({ $reason }).
reader-failed-other = Ο διακομιστής αλληλογραφίας απάντησε: { $reason }.
reader-retry-note = Θα γίνει νέα προσπάθεια όταν ο λογαριασμός συνδεθεί ξανά.
reader-unreadable = Δεν είναι δυνατή η εμφάνιση αυτού του μηνύματος: { $error }
message-source-title = Κώδικας μηνύματος: { $subject }
message-source-untitled = Κώδικας μηνύματος

## Printing a message, and the header of a message quoted in a reply or forward

header-from = Από
header-date = Ημερομηνία
header-to = Προς
header-cc = Κοιν.
header-sent = Στάλθηκε
header-subject = Θέμα
header-security = Ασφάλεια
header-part = Τμήμα { $number }
quote-original = ----- Αρχικό μήνυμα -----
fold-show-earlier = Εμφάνιση των προηγούμενων μηνυμάτων

## Bounces: the card at the top of a notice that a message was not delivered

bounce-failed = Το μήνυμά σας δεν παραδόθηκε
bounce-delayed = Το μήνυμά σας δεν έχει παραδοθεί ακόμη
bounce-delayed-note = Ο διακομιστής αλληλογραφίας σας εξακολουθεί να προσπαθεί να το παραδώσει. Δεν χρειάζεται να το στείλετε ξανά.
# the link to the message the notice is about, in Sent Items or another folder
bounce-show-message = Εμφάνιση του μηνύματος που επιστράφηκε
# the link of a delay's card to the message that is still on its way
bounce-show-delayed = Εμφάνιση του μηνύματος που καθυστερεί
bounce-what-to-do = Τι μπορείτε να κάνετε:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
bounce-delayed-do = Προς το παρόν δεν χρειάζεται να κάνετε κάτι. Αν η παράδοση αποτύχει, θα λάβετε νέα ειδοποίηση.
bounce-delayed-row-do = Προς το παρόν δεν χρειάζεται να κάνετε κάτι. Ο διακομιστής αλληλογραφίας σας εξακολουθεί να προσπαθεί να παραδώσει το μήνυμα. Αν δεν τα καταφέρει, θα λάβετε νέα ειδοποίηση.
# folds the receiving server's own words
bounce-details = Λεπτομέρειες
# a recipient the notice does not name
bounce-someone = Ένας παραλήπτης
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
bounce-server = Διακομιστής: { $server }
bounce-status = Κατάσταση: { $status }
bounce-reported-by = Αναφέρθηκε από: { $server }
bounce-retry-minutes = Ο διακομιστής του παραλήπτη ζήτησε αναμονή { $count ->
    [one] ενός λεπτού
   *[other] { $count } λεπτών
} πριν από την επόμενη προσπάθεια.
bounce-retry-hours = Ο διακομιστής του παραλήπτη ζήτησε αναμονή { $count ->
    [one] μίας ώρας
   *[other] { $count } ωρών
} πριν από την επόμενη προσπάθεια.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
bounce-blocklist = Λίστα αποκλεισμού: { $lists }
bounce-user-unknown = Η διεύθυνση δεν υπάρχει
bounce-user-unknown-why = Ο διακομιστής του παραλήπτη δεν έχει γραμματοκιβώτιο με αυτή τη διεύθυνση. Ίσως γράφτηκε λάθος ή το άτομο δεν τη χρησιμοποιεί πια.
bounce-user-unknown-do = Ελέγξτε την ορθογραφία της διεύθυνσης ή ζητήστε από το άτομο τη διεύθυνση που χρησιμοποιεί τώρα.
bounce-invalid-address = Η διεύθυνση δεν είναι έγκυρη
bounce-invalid-address-why = Η μορφή της διεύθυνσης δεν είναι έγκυρη για αποστολή αλληλογραφίας.
bounce-invalid-address-do = Ελέγξτε για λάθη πληκτρολόγησης, όπως περιττά κενά, γράμματα που λείπουν ή απουσία τομέα μετά το @.
bounce-mailbox-disabled = Το γραμματοκιβώτιο έχει κλείσει
bounce-mailbox-disabled-why = Η διεύθυνση υπάρχει, αλλά το γραμματοκιβώτιό της έχει απενεργοποιηθεί ή δεν χρησιμοποιείται πια.
bounce-mailbox-disabled-do = Επικοινωνήστε με το άτομο με άλλον τρόπο και ζητήστε μια διεύθυνση που χρησιμοποιεί τώρα.
bounce-mailbox-full = Το γραμματοκιβώτιο είναι γεμάτο
bounce-mailbox-full-why = Το γραμματοκιβώτιο του παραλήπτη δεν έχει χώρο για νέα αλληλογραφία.
bounce-mailbox-full-do = Στείλτε το ξανά σε λίγες ημέρες ή ενημερώστε τον παραλήπτη με άλλον τρόπο. Τα μεγάλα συνημμένα απαιτούν περισσότερο διαθέσιμο χώρο.
bounce-spam-blocked = Απορρίφθηκε ως ανεπιθύμητο
bounce-spam-blocked-why = Ο διακομιστής του παραλήπτη θεώρησε το μήνυμα ανεπιθύμητο.
bounce-spam-blocked-do = Στείλτε το ξανά χωρίς ό,τι μοιάζει με ανεπιθύμητη αλληλογραφία, όπως πολλούς συνδέσμους, συντομευμένους συνδέσμους ή ένα μεγάλο συνημμένο. Αν συνεχίσει να συμβαίνει, ρωτήστε τον πάροχο αλληλογραφίας σας.
bounce-virus-detected = Απορρίφθηκε λόγω ιού
bounce-virus-detected-why = Ο διακομιστής του παραλήπτη βρήκε ιό ή άλλο επιβλαβές περιεχόμενο στο μήνυμα ή στα συνημμένα του.
bounce-virus-detected-do = Ελέγξτε τα συνημμένα με ένα πρόγραμμα προστασίας από ιούς. Ορισμένοι διακομιστές απορρίπτουν κάθε πρόγραμμα ή αρχείο συμπίεσης, οπότε μοιραστείτε τέτοια αρχεία ως σύνδεσμο.
bounce-ip-blocklisted = Ο διακομιστής αλληλογραφίας σας είναι σε λίστα αποκλεισμού
bounce-ip-blocklisted-why = Ο διακομιστής του παραλήπτη απορρίπτει αλληλογραφία από τον διακομιστή που έστειλε τη δική σας, επειδή η διεύθυνση αυτού του διακομιστή είναι σε λίστα αποκλεισμού.
bounce-ip-blocklisted-do = Το πρόβλημα δεν είναι το μήνυμα. Προωθήστε αυτή την ειδοποίηση στον πάροχο αλληλογραφίας σας και ζητήστε του να αφαιρεθεί ο διακομιστής από τη λίστα.
bounce-domain-blocklisted = Ένας τομέας είναι σε λίστα αποκλεισμού
bounce-domain-blocklisted-why = Ο διακομιστής του παραλήπτη απορρίπτει το μήνυμα επειδή ο τομέας της διεύθυνσής σας, ή ένας τομέας στους συνδέσμους του μηνύματος, είναι σε λίστα αποκλεισμού.
bounce-domain-blocklisted-do = Αν το μήνυμα έχει συνδέσμους, δοκιμάστε το χωρίς αυτούς. Διαφορετικά, προωθήστε αυτή την ειδοποίηση σε όποιον διαχειρίζεται την αλληλογραφία του τομέα σας.
bounce-policy-blocked = Απορρίφθηκε από τους κανόνες του διακομιστή του παραλήπτη
bounce-policy-blocked-why = Οι κανόνες του διακομιστή του παραλήπτη δεν επιτρέπουν την παράδοση αυτού του μηνύματος, για παράδειγμα λόγω του μεγέθους, των συνημμένων ή του αποστολέα του.
bounce-policy-blocked-do = Το αρχικό μήνυμα του διακομιστή στην ενότητα «Λεπτομέρειες» συχνά εξηγεί την αιτία. Ρωτήστε τον παραλήπτη αν μπορεί να δεχτεί τέτοια αλληλογραφία.
bounce-geo-blocked = Απορρίφθηκε λόγω προέλευσης
bounce-geo-blocked-why = Ο διακομιστής του παραλήπτη δεν δέχεται αλληλογραφία από τη χώρα ή το δίκτυο όπου βρίσκεται ο διακομιστής αλληλογραφίας σας.
bounce-geo-blocked-do = Επικοινωνήστε με το άτομο με άλλον τρόπο ή ρωτήστε σχετικά τον πάροχο αλληλογραφίας σας.
bounce-relay-denied = Ο διακομιστής δεν το προώθησε
bounce-relay-denied-why = Ένας διακομιστής αρνήθηκε να προωθήσει το μήνυμα προς τον προορισμό του, συχνά επειδή δεν έγινε σύνδεση στον λογαριασμό ή επειδή ο διακομιστής δεν εξυπηρετεί αυτόν τον παραλήπτη.
bounce-relay-denied-do = Ελέγξτε τις ρυθμίσεις του διακομιστή εξερχομένων στο Αρχείο > Λογαριασμοί και βεβαιωθείτε ότι έχει ρυθμιστεί σύνδεση στον λογαριασμό.
bounce-auth-failure = Δεν ήταν δυνατή η επαλήθευση της διεύθυνσης αποστολέα σας
bounce-auth-failure-why = Ο διακομιστής του παραλήπτη δεν μπόρεσε να επιβεβαιώσει ότι το μήνυμα προήλθε πράγματι από τον τομέα σας (SPF, DKIM ή DMARC).
bounce-auth-failure-do = Προωθήστε αυτή την ειδοποίηση σε όποιον διαχειρίζεται την αλληλογραφία του τομέα σας: οι ρυθμίσεις του χρειάζονται διόρθωση. Στο μεταξύ, μπορεί να βοηθήσει η αποστολή μέσω του διακομιστή του παρόχου σας.
bounce-rate-limited = Πάρα πολλή αλληλογραφία ταυτόχρονα
bounce-rate-limited-why = Ο διακομιστής του παραλήπτη δέχεται προς το παρόν λιγότερα μηνύματα από τον διακομιστή αλληλογραφίας σας.
bounce-rate-limited-do = Περιμένετε λίγο και στείλτε το ξανά. Όταν γράφετε σε πολλούς, στέλνετε σε λιγότερους κάθε φορά.
bounce-greylisting = Προσωρινή αναβολή παράδοσης
bounce-greylisting-why = Ο διακομιστής του παραλήπτη ζητά από άγνωστους αποστολείς να δοκιμάσουν ξανά λίγο αργότερα. Πρόκειται για συνηθισμένο μέτρο κατά της ανεπιθύμητης αλληλογραφίας.
bounce-greylisting-do = Δεν χρειάζεται να κάνετε κάτι. Οι διακομιστές αλληλογραφίας δοκιμάζουν ξανά αυτόματα και το μήνυμα συνήθως παραδίδεται μέσα σε μία ώρα.
bounce-server-error = Ο διακομιστής του παραλήπτη είχε πρόβλημα
bounce-server-error-why = Ο διακομιστής του παραλήπτη δεν ήταν προσβάσιμος ή δεν μπόρεσε να δεχτεί το μήνυμα λόγω δικού του προβλήματος.
bounce-server-error-do = Στείλτε το ξανά αργότερα. Αν συνεχίσει να αποτυγχάνει, ελέγξτε το τμήμα της διεύθυνσης μετά το @ για λάθη πληκτρολόγησης.
bounce-unknown = Δεν παραδόθηκε
bounce-unknown-why = Η ειδοποίηση δεν αναφέρει σαφώς την αιτία.
bounce-unknown-do = Το αρχικό μήνυμα του διακομιστή στην ενότητα «Λεπτομέρειες» μπορεί να δώσει περισσότερες πληροφορίες. Αν δεν σας βοηθήσει, προωθήστε αυτή την ειδοποίηση στον πάροχο αλληλογραφίας σας.

## Several messages selected

selection-title = { $count ->
    [one] { $count } επιλεγμένο μήνυμα
   *[other] { $count } επιλεγμένα μηνύματα
}
selection-unread = { $count ->
    [one] { $count } αδιάβαστο
   *[other] { $count } αδιάβαστα
}
selection-flagged = { $count } με σημαία
delete-for-good-one = Αυτό το μήνυμα θα διαγραφεί οριστικά. Να διαγραφεί;
delete-for-good-all = Αυτά τα { $count } μηνύματα θα διαγραφούν οριστικά. Να διαγραφούν;
delete-for-good-some = Από τα { $total } μηνύματα, { $count ->
    [one] το { $count } θα διαγραφεί οριστικά
   *[other] τα { $count } θα διαγραφούν οριστικά
    }. Να διαγραφούν τα μηνύματα;
done-read = { $count ->
    [one] { $messages } επισημάνθηκε ως αναγνωσμένο
   *[other] { $messages } επισημάνθηκαν ως αναγνωσμένα
}
done-unread = { $count ->
    [one] { $messages } επισημάνθηκε ως αδιάβαστο
   *[other] { $messages } επισημάνθηκαν ως αδιάβαστα
}
done-flagged = { $count ->
    [one] Προστέθηκε σημαία σε { $messages }
   *[other] Προστέθηκε σημαία σε { $messages }
}
done-unflagged = Αφαιρέθηκε η σημαία από { $messages }
done-deleted-for-good = { $count ->
    [one] { $messages } διαγράφηκε οριστικά
   *[other] { $messages } διαγράφηκαν οριστικά
}
done-archived = { $count ->
    [one] { $messages } αρχειοθετήθηκε
   *[other] { $messages } αρχειοθετήθηκαν
}
done-moved = { $count ->
    [one] Μετακινήθηκε { $messages } σε: { $folder }
   *[other] Μετακινήθηκαν { $messages } σε: { $folder }
}
done-copied = { $count ->
    [one] Αντιγράφηκε { $messages } σε: { $folder }
   *[other] Αντιγράφηκαν { $messages } σε: { $folder }
}
done-moving = { $count ->
   *[other] Μετακίνηση: { $messages }. Προορισμός: { $folder }...
}
done-copying = { $count ->
   *[other] Αντιγραφή: { $messages }. Προορισμός: { $folder }...
}
done-moved-back = { $count ->
    [one] Επιστράφηκε { $messages } σε: { $folder }
   *[other] Επιστράφηκαν { $messages } σε: { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
done-watched = { $count ->
    [one] Παρακολουθείτε τη συζήτηση
   *[other] Παρακολουθείτε { $count } συζητήσεις
}
done-unwatched = { $count ->
    [one] Σταματήσατε να παρακολουθείτε τη συζήτηση
   *[other] Σταματήσατε να παρακολουθείτε { $count } συζητήσεις
}
done-ignored = { $count ->
    [one] Αγνοείτε τη συζήτηση
   *[other] Αγνοείτε { $count } συζητήσεις
}
done-unignored = { $count ->
    [one] Σταματήσατε να αγνοείτε τη συζήτηση
   *[other] Σταματήσατε να αγνοείτε { $count } συζητήσεις
}
their-folders = αρχικοί φάκελοι
undo-move = Αναίρεση μετακίνησης
undo-delete = Αναίρεση διαγραφής
undo-archive = Αναίρεση αρχειοθέτησης
undo-junk = Αναίρεση επισήμανσης ως ανεπιθύμητου
undo-not-junk = Αναίρεση επισήμανσης ως μη ανεπιθύμητου
undo-send = Αναίρεση αποστολής
nothing-to-undo = Δεν υπάρχει τίποτα για αναίρεση.
messages-gone = Τα μηνύματα δεν υπάρχουν πια.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
folder-holds-no-messages = Αυτός ο φάκελος δεν μπορεί να περιέχει μηνύματα.
not-archived-here = Τα μηνύματα αυτού του φακέλου δεν μπορούν να αρχειοθετηθούν.
not-emptied-here = Μπορείτε να αδειάσετε μόνο τους φακέλους «Διαγραμμένα» και «Ανεπιθύμητη αλληλογραφία».
next-unread-question = Δεν υπάρχουν άλλα αδιάβαστα μηνύματα στον φάκελο «{ $folder }».

    Να γίνει μετάβαση στον φάκελο «{ $next }», τον επόμενο φάκελο με αδιάβαστα μηνύματα;
no-unread-left = Δεν έχουν μείνει αδιάβαστα μηνύματα.
empty-question = { $count ->
    [one] Θέλετε να αδειάσετε τον φάκελο «{ $folder }»;

        Το μήνυμα που περιέχει θα διαγραφεί οριστικά και δεν θα μπορεί να ανακτηθεί.
   *[other] Θέλετε να αδειάσετε τον φάκελο «{ $folder }»;

        Θα διαγραφούν οριστικά: { $messages }. Δεν θα μπορούν να ανακτηθούν.
}
no-junk-folder = Αυτός ο λογαριασμός δεν έχει φάκελο «Ανεπιθύμητη αλληλογραφία» για τη μετακίνηση των μηνυμάτων.
no-inbox-folder = Αυτός ο λογαριασμός δεν έχει φάκελο «Εισερχόμενα» για τη μετακίνηση των μηνυμάτων.
# the status bar after a flag in a colour: "Σε 2 μηνύματα προστέθηκε κόκκινη σημαία"
done-flagged-color = Σε { $messages } προστέθηκε { $color ->
    [red] κόκκινη
    [orange] πορτοκαλί
    [yellow] κίτρινη
    [green] πράσινη
    [blue] μπλε
    [purple] μωβ
   *[gray] γκρι
} σημαία
# the Flag menu: the colours of Apple Mail's flags
flag-color = { $color ->
    [red] Κόκκινο
    [orange] Πορτοκαλί
    [yellow] Κίτρινο
    [green] Πράσινο
    [blue] Μπλε
    [purple] Μωβ
   *[gray] Γκρι
}

## The Move and Copy window

move-window-title-move = { $count ->
    [one] Μετακίνηση μηνύματος
   *[other] Μετακίνηση { $count } μηνυμάτων
}
move-window-title-copy = { $count ->
    [one] Αντιγραφή μηνύματος
   *[other] Αντιγραφή { $count } μηνυμάτων
}
move-window-prompt-move = { $count ->
    [one] Μετακίνηση του επιλεγμένου μηνύματος σε:
   *[other] Μετακίνηση των { $count } επιλεγμένων μηνυμάτων σε:
}
move-window-prompt-copy = { $count ->
    [one] Αντιγραφή του επιλεγμένου μηνύματος σε:
   *[other] Αντιγραφή των { $count } επιλεγμένων μηνυμάτων σε:
}
# the folders used last, over the folder tree
targets-recent = Πρόσφατα
# the folder the messages are in, which can not be chosen
target-current = { $folder } (τρέχων)
# a folder used last, with its account when there are several: "Αρχειοθέτηση (Εργασία)"
target-recent = { $folder } ({ $account })

## Moving and copying to another account

transfer-moving = Μετακίνηση { $done } από { $messages } σε: { $folder }...
transfer-copying = Αντιγραφή { $done } από { $messages } σε: { $folder }...
transfer-another-account = άλλος λογαριασμός
transfer-folder-gone = ο φάκελος προορισμού δεν υπάρχει πια
transfer-not-on-server = το μήνυμα δεν υπάρχει πια στον διακομιστή
transfer-not-moved = { $count ->
   *[other] Δεν ήταν δυνατή η μετακίνηση σε άλλον λογαριασμό: { $messages }. Αιτία: { $reason }
}
transfer-not-copied = { $count ->
   *[other] Δεν ήταν δυνατή η αντιγραφή σε άλλον λογαριασμό: { $messages }. Αιτία: { $reason }
}
transfer-none-moved = Δεν ήταν δυνατή η μετακίνηση κανενός μηνύματος
transfer-none-copied = Δεν ήταν δυνατή η αντιγραφή κανενός μηνύματος

## Messages as files

export-not-in-time = δεν ήταν δυνατή η λήψη του μηνύματος εγκαίρως
export-not-saved = Αποτυχία αποθήκευσης: { $failed } από { $messages } ({ $problems })
export-not-attached = δεν ήταν δυνατή η επισύναψη των μηνυμάτων: { $error }
# the status bar after Save As with several: "Αποθηκεύτηκαν 3 μηνύματα στην Επιφάνεια εργασίας"
saved-to = { $count ->
    [one] Αποθηκεύτηκε { $messages } στον φάκελο «{ $folder }»
   *[other] Αποθηκεύτηκαν { $messages } στον φάκελο «{ $folder }»
}
download-progress = Λήψη { $done } από { $total }
download-done = Έγινε λήψη { $size }
downloading-messages = { $count ->
   *[other] Λήψη: { $messages }...
}
# the status bar after files are dropped on a folder: "Μπήκαν 3 μηνύματα στην Αρχειοθέτηση"
import-put = { $count ->
    [one] Προστέθηκε { $messages } στον φάκελο «{ $folder }»
   *[other] Προστέθηκαν { $messages } στον φάκελο «{ $folder }»
}
import-not-put = Δεν προστέθηκαν στον φάκελο τα παρακάτω:

    { $problems }

## Problems the windows show

error-store = τοπική αποθήκη: { $error }
error-not-found = δεν βρέθηκε
error-closed = γίνεται τερματισμός
error-other-account = το πρόγραμμα περιήγησης συνδέθηκε ως { $email }, όχι σε αυτόν τον λογαριασμό
# a password or sign-in the mail server refused, with the server's words
failure-authentication = ο διακομιστής δεν δέχτηκε τη σύνδεση ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
failure-network = η σύνδεση με τον διακομιστή απέτυχε ({ $reason })
error-in-use = δεν μπορεί να καταργηθεί όσο συνδέονται λογαριασμοί με αυτήν: { $accounts }
error-turned-off = αυτή η εφαρμογή σύνδεσης είναι απενεργοποιημένη για νέους λογαριασμούς
error-folder-name = το όνομα του φακέλου πρέπει να έχει από 1 έως 200 χαρακτήρες και δεν μπορεί να περιέχει χαρακτήρες ελέγχου
error-folder-separator = σε αυτόν τον διακομιστή ένα όνομα φακέλου δεν μπορεί να περιέχει «{ $separator }»
error-folder-special = τα Εισερχόμενα και οι ειδικοί φάκελοι δεν μπορούν να μετονομαστούν ή να διαγραφούν
error-no-recipients = το μήνυμα δεν έχει παραλήπτες
error-bad-address = η διεύθυνση «{ $address }» δεν είναι έγκυρη διεύθυνση ηλεκτρονικού ταχυδρομείου
error-not-own-address = Η διεύθυνση { $address } δεν είναι μία από τις διευθύνσεις αποστολής αυτού του λογαριασμού. Προσθέστε τη στο πεδίο «Άλλες διευθύνσεις από τις οποίες στέλνετε» στις ιδιότητες του λογαριασμού.
rule-query-refused = Οι κανόνες δεν μπορούν να φιλτράρουν κατά φάκελο ή ημερομηνία ({ $words }).
rule-no-query = Εισαγάγετε κριτήρια αναζήτησης για τα εισερχόμενα μηνύματα.
rule-no-action = Επιλέξτε τουλάχιστον μία ενέργεια για τον κανόνα.
error-attachment = Δεν ήταν δυνατή η ανάγνωση του αρχείου { $path }: { $error }
error-no-drafts = ο λογαριασμός δεν έχει φάκελο Πρόχειρα για να αποθηκευτεί το μήνυμα
error-draft-attachment = δεν ήταν δυνατή η αποθήκευση ενός συνημμένου του πρόχειρου: { $error }
error-password-not-saved = δεν ήταν δυνατή η αποθήκευση του κωδικού πρόσβασης για την επόμενη εκκίνηση: { $error }
error-sign-in-not-saved = δεν ήταν δυνατή η αποθήκευση των νέων στοιχείων σύνδεσης για την επόμενη εκκίνηση: { $error }
error-import-unreadable = Δεν είναι δυνατή η ανάγνωση του αρχείου { $path }: { $error }
error-import-too-large = Το αρχείο { $path } είναι μεγαλύτερο από 50 MB
error-import-not-mail = Το αρχείο { $path } δεν είναι μήνυμα ηλεκτρονικού ταχυδρομείου
error-list-answered = ο διακομιστής της λίστας αλληλογραφίας επέστρεψε κωδικό κατάστασης { $status }
error-not-built = δεν ήταν δυνατή η δημιουργία του μηνύματος
error-outbox-waits = { $count ->
    [one] το μήνυμα παραμένει στα Εξερχόμενα. Θα γίνει νέα προσπάθεια αποστολής με την επόμενη Αποστολή/Λήψη
   *[other] { $count } μηνύματα παραμένουν στα Εξερχόμενα. Θα γίνει νέα προσπάθεια αποστολής με την επόμενη Αποστολή/Λήψη
}
error-draft-not-removed = δεν ήταν δυνατή η κατάργηση του προηγούμενου πρόχειρου του μηνύματος από τα Πρόχειρα: { $reason }
error-sent-but = το μήνυμα στάλθηκε, αλλά { $problem }
error-sent-still-in-outbox = βρίσκεται ακόμη στα Εξερχόμενα: { $error }
error-sent-no-copy = δεν ήταν δυνατή η αποθήκευση αντιγράφου στα Απεσταλμένα: { $reason }
error-no-password = δεν υπάρχει κωδικός πρόσβασης για αυτόν τον λογαριασμό
error-no-sign-in = δεν υπάρχουν αποθηκευμένα στοιχεία σύνδεσης για αυτόν τον λογαριασμό
error-provider-missing = αυτή η έκδοση δεν μπορεί να συνδεθεί σε: { $provider }. Μήπως καταργήθηκε η εφαρμογή σύνδεσης;
error-provider-servers = οι διακομιστές αυτού του λογαριασμού δεν ταιριάζουν με τους διακομιστές της εφαρμογής σύνδεσής του
error-app-scopes = { $reason }. Ο διακομιστής αλληλογραφίας δεν δέχτηκε το διακριτικό της εφαρμογής σύνδεσης: ελέγξτε ότι τα δικαιώματα (scopes) της εφαρμογής δίνουν πρόσβαση στην αλληλογραφία
error-in-folder = { $folder }: { $reason }

## Sign-in apps

sign-in-off-google = Η Google δεν έχει επαληθεύσει ακόμη το Inbox Classic, οπότε επιτρέπει τη σύνδεση μέσω αυτού μόνο σε χρήστες δοκιμών. Χρησιμοποιήστε τη δική σας εφαρμογή σύνδεσης Google ή έναν κωδικό πρόσβασης εφαρμογής, ή ενεργοποιήστε την στις Εφαρμογές σύνδεσης (Αρχείο > Λογαριασμοί) αν είστε χρήστης δοκιμών.
sign-in-off-other = Απενεργοποιήθηκε στις Εφαρμογές σύνδεσης (Αρχείο > Λογαριασμοί), όπου μπορεί να ενεργοποιηθεί ξανά.
sign-in-app-no-name = η εφαρμογή σύνδεσης χρειάζεται όνομα
sign-in-app-no-client = λείπει το αναγνωριστικό πελάτη
sign-in-app-no-scopes = η εφαρμογή σύνδεσης χρειάζεται τα δικαιώματα (scopes) που δίνουν πρόσβαση στην αλληλογραφία
sign-in-app-bad-host = η διεύθυνση του διακομιστή { $server } λείπει ή δεν είναι έγκυρο όνομα κεντρικού υπολογιστή
sign-in-app-plain = ο διακομιστής { $server } πρέπει να χρησιμοποιεί SSL/TLS ή STARTTLS
sign-in-app-not-checked = ο εκδότης δεν έχει ελεγχθεί ακόμη
sign-in-app-issuer-changed = ο εκδότης άλλαξε: πληκτρολογήστε ξανά το μυστικό πελάτη ή καταργήστε το
sign-in-register-google = Στο Google Cloud Console, δημιουργήστε έναν πελάτη OAuth τύπου Desktop app, με το δικαίωμα https://mail.google.com/ στην οθόνη συναίνεσής του. Όσο η εφαρμογή είναι σε δοκιμή, μόνο οι χρήστες δοκιμών της μπορούν να συνδεθούν.
sign-in-register-microsoft = Στο Microsoft Entra, καταχωρίστε μια εφαρμογή με την πλατφόρμα Mobile and desktop applications, το URI ανακατεύθυνσης http://localhost, επιτρεπόμενες ροές δημόσιου πελάτη (public client flows) και τα εξουσιοδοτημένα δικαιώματα IMAP.AccessAsUser.All, SMTP.Send και offline_access. Μόνο για τον οργανισμό σας, χρησιμοποιήστε ως εκδότη το https://login.microsoftonline.com/<tenant ID>/v2.0.
sign-in-register-other = Καταχωρίστε έναν εγγενή (δημόσιο) πελάτη με το παρακάτω URI ανακατεύθυνσης· ο πάροχος πρέπει να επιτρέπει οποιαδήποτε θύρα σε αυτό (RFC 8252). Προσθέστε το δικαίωμα με το οποίο ο πάροχος δίνει πρόσβαση στην αλληλογραφία.

## Calendar invitations

repeats = Επανάληψη
repeats-every = { $unit ->
    [day] { $interval ->
        [one] Κάθε μέρα
       *[other] Κάθε { $interval } ημέρες
    }
    [week] { $interval ->
        [one] Κάθε εβδομάδα
       *[other] Κάθε { $interval } εβδομάδες
    }
    [month] { $interval ->
        [one] Κάθε μήνα
       *[other] Κάθε { $interval } μήνες
    }
   *[year] { $interval ->
        [one] Κάθε χρόνο
       *[other] Κάθε { $interval } χρόνια
    }
}
# "Κάθε εβδομάδα: Δευτέρα, Τετάρτη"
repeats-on = { $repeats }: { $days }
# "Κάθε εβδομάδα, 10 φορές"
repeats-times = { $count ->
    [one] { $repeats }, μία φορά
   *[other] { $repeats }, { $count } φορές
}
day-monday = Δευτέρα
day-tuesday = Τρίτη
day-wednesday = Τετάρτη
day-thursday = Πέμπτη
day-friday = Παρασκευή
day-saturday = Σάββατο
day-sunday = Κυριακή

## AI agents

agent-level-read = Ανάγνωση αλληλογραφίας: φάκελοι, λίστα μηνυμάτων, αναζήτηση και μηνύματα
agent-level-organize = Οργάνωση αλληλογραφίας: επισήμανση ως αναγνωσμένου ή αδιάβαστου, σημαίες, ανεπιθύμητα, μετακίνηση και διαγραφή στα Διαγραμμένα
agent-level-drafts = Σύνταξη πρόχειρων που στέλνετε εσείς
agent-level-send = Αποστολή αλληλογραφίας, με ξεχωριστή έγκριση για κάθε μήνυμα
agent-connect-title = Το πρόγραμμα { $program } ζητά πρόσβαση στην αλληλογραφία σας
agent-connect-detail = Ένας πράκτορας ΤΝ ζήτησε πρόσβαση μέσω του Inbox Classic. Επιλέξτε τις ενέργειες και τους λογαριασμούς που θα του επιτρέψετε. Μπορείτε να αλλάξετε τις επιλογές σας αργότερα από το Εργαλεία > Πράκτορες ΤΝ.

    Οι πράκτορες διαβάζουν αλληλογραφία από άλλους ανθρώπους, και ένα μήνυμα μπορεί να περιέχει παραπλανητικές οδηγίες. Το Inbox Classic ζητά την έγκρισή σας για κάθε μήνυμα που θέλει να στείλει ένας πράκτορας μέσω του προγράμματος.
agent-reply-to = Απάντηση στο «{ $subject }»
agent-reply-all-on = Απάντηση σε όλους στο «{ $subject }»
agent-forward-of = Προώθηση του «{ $subject }»
agent-never-written-one = Δεν έχετε γράψει ποτέ στη διεύθυνση { $address }.
agent-never-written-many = Δεν έχετε γράψει ποτέ σε { $count } από αυτές τις διευθύνσεις.
agent-send-title = Το πρόγραμμα { $program } θέλει να στείλει αυτό το μήνυμα
agent-send-detail = Ελέγξτε τους παραλήπτες και το περιεχόμενο του μηνύματος. Μόλις επιβεβαιώσετε, το μήνυμα περιμένει { $seconds } δευτερόλεπτα στα Εξερχόμενα, όπου μπορείτε ακόμη να το διαγράψετε.
agent-change-title = Τι μπορεί να κάνει το πρόγραμμα { $program }
agent-change-allowed = Αλλάξτε τα δικαιώματα των πρακτόρων ΤΝ αυτού του προγράμματος για την αλληλογραφία σας.
agent-change-refused = Έχετε αρνηθεί την πρόσβαση σε αυτό το πρόγραμμα. Μπορείτε να την επιτρέψετε ξανά, ώστε οι πράκτορές του να έχουν πρόσβαση στην αλληλογραφία σας.
agent-log-taken-back = { $entry } (αναιρέθηκε)
agent-files = Αρχεία: { $files }
agent-undo-refused = Δεν μπορεί να αναιρεθεί.
agent-undo-refused-why = Δεν μπορεί να αναιρεθεί: { $reason }.
agent-undo-impossible = αυτό δεν μπορεί να αναιρεθεί
agent-undo-not-in-folder = το μήνυμα δεν βρίσκεται πια σε αυτόν τον φάκελο
agent-undo-not-arrived = το μήνυμα δεν βρίσκεται (ακόμη) στον φάκελο όπου μετακινήθηκε
agent-undo-sent = το μήνυμα έχει ήδη σταλεί
agent-original-not-downloaded = δεν έχει γίνει ακόμη λήψη του αρχικού μηνύματος. Ανοίξτε το πρώτα
agent-turned-away = Απορρίφθηκε
agent-can-nothing = Τίποτα
agent-can-read = ανάγνωση
agent-can-organize = οργάνωση
agent-can-drafts = σύνταξη πρόχειρων
agent-can-send = αποστολή με την έγκρισή σας
# "Ανάγνωση, οργάνωση και σύνταξη πρόχειρων"
agent-can-list = { $first } και { $last }
agent-accounts = { $count ->
    [0] κανένας λογαριασμός
    [one] { $count } λογαριασμός
   *[other] { $count } λογαριασμοί
}
# "Ανάγνωση και οργάνωση· 1 λογαριασμός"
agent-access = { $can }· { $accounts }
agent-unreadable = Δεν είναι δυνατή η ανάγνωση αυτού του μηνύματος.
agent-encrypted-original = Αυτό το μήνυμα είναι κρυπτογραφημένο. Ένας πράκτορας δεν μπορεί να απαντήσει ή να το προωθήσει μέσω του Inbox Classic, επειδή δεν υποστηρίζεται κρυπτογράφηση για αποστολή από πράκτορες.
# review: new
agent-encrypted = Αυτό το μήνυμα είναι κρυπτογραφημένο. Μόνο ο χρήστης μπορεί να το διαβάσει, στο Inbox Classic.
# review: new
list-encrypted = Κρυπτογραφημένο μήνυμα
agent-log-composed = Άνοιξε το «{ $subject }» σε νέο μήνυμα για να το ολοκληρώσετε
agent-log-refused = Δεν στείλατε το «{ $subject }»
agent-log-sent = Το μήνυμα «{ $subject }» τέθηκε σε αναμονή για αποστολή προς { $to }
agent-log-draft = Αποθηκεύτηκε το πρόχειρο «{ $subject }»
agent-log-read = Επισημάνθηκε ως αναγνωσμένο το «{ $subject }»
agent-log-unread = Επισημάνθηκε ως αδιάβαστο το «{ $subject }»
agent-log-flagged = Προστέθηκε σημαία στο «{ $subject }»
agent-log-unflagged = Αφαιρέθηκε η σημαία από το «{ $subject }»
agent-log-deleted = Διαγράφηκε το «{ $subject }»
agent-log-moved = Μετακινήθηκε το «{ $subject }» στον φάκελο «{ $folder }»
agent-log-junk = Επισημάνθηκε ως ανεπιθύμητο το «{ $subject }»
agent-log-not-junk = Επισημάνθηκε ως μη ανεπιθύμητο το «{ $subject }»
agent-log-archived = Αρχειοθετήθηκε το «{ $subject }»
agent-log-folder = Δημιουργήθηκε ο φάκελος «{ $name }»
agent-log-unsubscribed = Καταργήθηκε η εγγραφή στη λίστα αλληλογραφίας του μηνύματος «{ $subject }»

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

key-ctrl = Ctrl
key-alt = Alt
key-shift = Shift
key-del = Del
key-enter = Enter

## Signing in and passwords

sign-in-no-refresh = ο πάροχος δεν έδωσε διακριτικό ανανέωσης
sign-in-no-account = ο πάροχος δεν προσδιόρισε ποιος λογαριασμός συνδέθηκε
sign-in-not-finished = η σύνδεση δεν έχει ολοκληρωθεί
secrets-unavailable = Μη διαθέσιμο: { $store }
secrets-unavailable-why = Μη διαθέσιμο: { $store } ({ $error })
secrets-windows = Διαχείριση διαπιστευτηρίων
secrets-mac = Κλειδοθήκη
secrets-linux = Κλειδοθήκη συστήματος (Secret Service)
error-no-such-file = δεν υπάρχει τέτοιο αρχείο
cards-file-too-big = Το αρχείο είναι πολύ μεγάλο για εισαγωγή ως βιβλίο διευθύνσεων.
ui-sender-added = Η επαφή { $name } προστέθηκε στο Βιβλίο διευθύνσεων.
ui-sender-known = Η επαφή { $name } υπάρχει ήδη στο Βιβλίο διευθύνσεων.
ui-sender-none = Ο αποστολέας αυτού του μηνύματος δεν έχει διεύθυνση ηλεκτρονικού ταχυδρομείου για προσθήκη.
card-name-needed = Η επαφή δεν έχει όνομα ούτε διεύθυνση ηλεκτρονικού ταχυδρομείου.
# a file of Import Address Book that could not be read: "contacts.vcf: δεν υπάρχει τέτοιο αρχείο"
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
otp-heading = Κωδικός από { $domain }
otp-copy = Αντιγραφή
otp-note = Πληκτρολογήστε τον μόνο σε σελίδα του τομέα { $domain }.
otp-old = Το μήνυμα με αυτόν τον κωδικό στάλθηκε πριν από περισσότερο από μία ώρα. Ο κωδικός πιθανότατα έχει λήξει.

# how many are invited, in the card of an event
event-attendees =
    { $count ->
        [one] { $count } συμμετέχων
       *[other] { $count } συμμετέχοντες
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
otp-notification = { $code }: ο κωδικός σας για { $domain }

## OpenPGP keys (keys.rs)
pgp-key-valid = Έγκυρο
pgp-key-expires = Έγκυρο έως { $date }
pgp-key-expired = Έληξε στις { $date }
pgp-key-revoked = Ανακλήθηκε
pgp-key-revoked-why = Ανακλήθηκε: { $reason }
pgp-key-not-valid = Μη έγκυρο
pgp-key-locked = Το ιδιωτικό κλειδί δεν μπορεί να χρησιμοποιηθεί. Το κλειδί προστασίας του λείπει από την υπηρεσία αποθήκευσης ({ $store }). Εισαγάγετε ξανά το αντίγραφο ασφαλείας του ιδιωτικού κλειδιού.
pgp-source-own = Δημιουργήθηκε στο Inbox Classic
pgp-source-file = Εισήχθη από αρχείο
pgp-source-paste = Επικολλήθηκε
pgp-source-attachment = Από μήνυμα
pgp-source-vcard = Από κάρτα επαφής
pgp-source-wkd = Από τον πάροχο αλληλογραφίας του αποστολέα
pgp-source-keyserver = Από το keys.openpgp.org
pgp-source-autocrypt = Από την κεφαλίδα Autocrypt ενός μηνύματος
pgp-error-no-store = Η υπηρεσία ασφαλούς αποθήκευσης ({ $store }), που προστατεύει τα ιδιωτικά κλειδιά, δεν είναι διαθέσιμη: { $error }
pgp-error-wrong-passphrase = Η φράση πρόσβασης δεν είναι σωστή.
pgp-error-not-a-key = Αυτό δεν είναι κλειδί OpenPGP.
pgp-error-too-large = Το κλειδί είναι πολύ μεγάλο.
pgp-error-unusable = Το κλειδί χρησιμοποιεί παρωχημένη ή ανεπαρκώς ασφαλή κρυπτογραφία και δεν μπορεί να χρησιμοποιηθεί.
pgp-imported-private = { $count ->
    [one] Το ιδιωτικό σας κλειδί εισήχθη.
   *[other] Εισήχθησαν { $count } ιδιωτικά κλειδιά.
}
pgp-imported-public = { $count ->
    [one] Εισήχθη ένα κλειδί.
   *[other] Εισήχθησαν { $count } κλειδιά.
}
pgp-imported-pending = Χρησιμοποιείται ήδη άλλο κλειδί για: { $addresses }. Το νέο κλειδί έχει αποθηκευτεί στα στοιχεία της επαφής και θα χρησιμοποιηθεί όταν το επιλέξετε.
pgp-error-needs-passphrase = Το ιδιωτικό κλειδί προστατεύεται με φράση πρόσβασης. Πληκτρολογήστε την για να εισαγάγετε το κλειδί.
pgp-error-mismatch = Το ιδιωτικό κλειδί δεν αντιστοιχεί στο δημόσιο κλειδί. Ενδέχεται να έχει αλλοιωθεί.
pgp-file-name-public = { $who } δημόσιο κλειδί.asc
pgp-file-name-private = { $who } αντίγραφο ασφαλείας ιδιωτικού κλειδιού.asc
pgp-pending = Βρέθηκε διαφορετικό κλειδί για τη διεύθυνση { $address } στις { $date }.

## Reading signed and encrypted mail (protect.rs)
pgp-part-verified = Υπογραφή από { $signer }, επαληθευμένος κάτοχος κλειδιού
pgp-part-signed = Υπογραφή από { $signer } (χωρίς επαλήθευση κατόχου κλειδιού)
pgp-part-other = Υπογραφή από { $signer }, που δεν είναι ο αποστολέας
pgp-part-unknown-key = Υπογεγραμμένο, αλλά το κλειδί δεν είναι γνωστό
pgp-part-not-signed = Χωρίς υπογραφή
pgp-part-not-checked = Η υπογραφή δεν ελέγχθηκε
pgp-part-encrypted = Κρυπτογραφημένο. { $signature }
pgp-part-no-key = Κρυπτογραφημένο για κλειδί που δεν έχετε
pgp-part-changed = Το κρυπτογραφημένο τμήμα αλλοιώθηκε κατά τη μεταφορά και δεν εμφανίζεται
pgp-part-unprotected = Κρυπτογραφημένο χωρίς προστασία από αλλοίωση, δεν εμφανίζεται
pgp-part-broken = Δεν είναι δυνατή η ανάγνωση του κρυπτογραφημένου τμήματος
pgp-why-mismatch = Η υπογραφή δεν ταιριάζει με αυτό το κείμενο
pgp-why-weak-hash = Η υπογραφή χρησιμοποιεί τον αλγόριθμο { $hash }, ο οποίος δεν θεωρείται πλέον ασφαλής
pgp-why-key-expired = Υπογράφηκε αφού έληξε το κλειδί στις { $date }
pgp-why-key-revoked = Υπογράφηκε με κλειδί που ανακλήθηκε
pgp-why-not-signing-key = Υπογράφηκε με κλειδί που δεν υποστηρίζει ψηφιακή υπογραφή
pgp-why-from-future = Η υπογραφή έχει ημερομηνία στο μέλλον
pgp-why-signature-expired = Η υπογραφή έχει λήξει
pgp-why-key-not-valid = Υπογράφηκε με κλειδί που δεν είναι έγκυρο
pgp-why-not-for-you = Υπογράφηκε για άλλους παραλήπτες και προωθήθηκε σε εσάς
pgp-part-pictures-loaded = { $label }. Φορτώθηκαν εικόνες από το διαδίκτυο
pgp-error-no-own-key = Δεν έχετε κλειδί για υπογραφή ή κρυπτογράφηση με τη διεύθυνση { $address }. Δημιουργήστε ένα από το Εργαλεία > Κλειδιά κρυπτογράφησης ή απενεργοποιήστε τις επιλογές Υπογραφή και Κρυπτογράφηση.
pgp-error-missing-keys = { $count ->
    [one] Ο παραλήπτης { $addresses } δεν έχει κλειδί για κρυπτογράφηση.
   *[other] Αυτοί οι παραλήπτες δεν έχουν κλειδί για κρυπτογράφηση: { $addresses }.
}
pgp-error-encrypted-quote = Αυτό το μήνυμα παραθέτει ή προωθεί κρυπτογραφημένο μήνυμα, οπότε μπορεί να σταλεί μόνο κρυπτογραφημένο. Ενεργοποιήστε την Κρυπτογράφηση ή αφαιρέστε το κείμενο της παράθεσης.
pgp-error-protect = Δεν ήταν δυνατή η υπογραφή ή η κρυπτογράφηση του μηνύματος: { $reason }
pgp-found-keys = Βρέθηκαν κλειδιά για: { $addresses }.
pgp-found-none = Δεν βρέθηκε κλειδί για { $addresses }. Ζητήστε τους να σας στείλουν το δημόσιο κλειδί τους.
pgp-found-no-key = Δεν βρέθηκε κλειδί.
pgp-find-unavailable = Δεν ήταν δυνατή η αναζήτηση κλειδιών τώρα: { $error }
pgp-publish-pending = Το keys.openpgp.org έστειλε συνδέσμους επιβεβαίωσης στις διευθύνσεις: { $addresses }. Επιβεβαιώστε κάθε διεύθυνση ξεχωριστά, ώστε το κλειδί σας να μπορεί να βρεθεί μέσω αυτής.
pgp-publish-done = Το κλειδί σας δημοσιεύτηκε στο keys.openpgp.org για { $addresses }.
pgp-publish-failed = Δεν ήταν δυνατή η δημοσίευση του κλειδιού: { $error }
# review: changed
pgp-keyserver-off = Η αναζήτηση κλειδιών στο keys.openpgp.org είναι απενεργοποιημένη στο { $settings }.
pgp-details-part = Τμήμα { $number }: { $label }
pgp-details-signed = Υπογράφηκε { $when } με το κλειδί { $key }
pgp-details-unknown-key = Υπογράφηκε με το κλειδί { $key }, που δεν έχετε
pgp-details-opened = Αποκρυπτογραφήθηκε με το κλειδί σας { $key }
pgp-details-for = Κρυπτογραφημένο για { $keys }
pgp-details-plain = Χωρίς υπογραφή και χωρίς κρυπτογράφηση
pgp-bar-parts = Αυτό το μήνυμα έχει { $count } τμήματα: { $list }. Κάθε τμήμα δείχνει πώς προστατεύεται.
pgp-bar-count-verified = { $count } με επαληθευμένο κάτοχο κλειδιού
pgp-bar-count-good = { $count ->
    [one] { $count } υπογεγραμμένο ή κρυπτογραφημένο
   *[other] { $count } υπογεγραμμένα ή κρυπτογραφημένα
}
pgp-bar-count-warning = { $count ->
    [one] { $count } χρειάζεται προσοχή
   *[other] { $count } χρειάζονται προσοχή
}
pgp-bar-count-neutral = { $count } χωρίς επιβεβαιωμένη υπογραφή
# the setup file: settings, accounts, contacts and keys carried to another computer
setup-part-settings = Ρυθμίσεις
setup-part-preferences = Προτιμήσεις παραθύρων
setup-part-accounts = Λογαριασμοί
setup-part-sign-in-apps = Εφαρμογές σύνδεσης
setup-part-contacts = Επαφές και ομάδες
setup-part-keys = Κλειδιά κρυπτογράφησης
setup-part-rules = Κανόνες μηνυμάτων
setup-part-trusted-senders = Αξιόπιστοι αποστολείς
setup-holds-settings = { $count ->
    [one] { $count } ρύθμιση
   *[other] { $count } ρυθμίσεις
}
setup-holds-preferences = { $count ->
    [one] { $count } προτίμηση
   *[other] { $count } προτιμήσεις
}
setup-holds-accounts = { $count ->
    [one] { $count } λογαριασμός
   *[other] { $count } λογαριασμοί
}
setup-holds-sign-in-apps = { $count ->
    [one] { $count } εφαρμογή σύνδεσης
   *[other] { $count } εφαρμογές σύνδεσης
}
setup-holds-built-in = Ποιες ενσωματωμένες εφαρμογές σύνδεσης είναι ενεργές
setup-holds-contacts = { $count ->
    [one] { $count } επαφή
   *[other] { $count } επαφές
}
setup-holds-groups = { $count ->
    [one] { $count } ομάδα
   *[other] { $count } ομάδες
}
setup-holds-own-keys = { $count ->
    [one] { $count } δικό σας κλειδί
   *[other] { $count } δικά σας κλειδιά
}
setup-holds-contact-keys = { $count ->
    [one] { $count } κλειδί επαφής
   *[other] { $count } κλειδιά επαφών
}
setup-holds-rules = { $count ->
    [one] { $count } κανόνας
   *[other] { $count } κανόνες
}
setup-holds-trusted-senders = { $count ->
    [one] { $count } αξιόπιστος αποστολέας
   *[other] { $count } αξιόπιστοι αποστολείς
}
setup-sign-in-password = Κωδικός πρόσβασης
setup-account-secret-password = Ο κωδικός πρόσβασής του βρίσκεται στο αρχείο.
setup-account-secret-token = Τα στοιχεία σύνδεσης του λογαριασμού περιλαμβάνονται στο αρχείο.
setup-account-asks-password = Μετά την εισαγωγή θα χρειαστεί να πληκτρολογήσετε τον κωδικό πρόσβασης.
setup-account-signs-in-again = Μετά την εισαγωγή θα χρειαστεί να συνδεθείτε ξανά στον λογαριασμό.
setup-account-here = Έχει ήδη ρυθμιστεί εδώ, οπότε παραλείπεται.
setup-account-no-app = Χρησιμοποιεί την εφαρμογή σύνδεσης { $app }, η οποία δεν έχει ρυθμιστεί εδώ. Εισαγάγετε και τις εφαρμογές σύνδεσης.
setup-invalid-address = Η διεύθυνση «{ $address }» δεν είναι έγκυρη διεύθυνση ηλεκτρονικού ταχυδρομείου.
setup-invalid-server = Ο διακομιστής { $server } δεν έχει έγκυρο όνομα ή θύρα.
setup-invalid-user = Δεν έχει οριστεί όνομα χρήστη.
setup-invalid-sign-in = Ο τρόπος σύνδεσης δεν υποστηρίζεται από το Inbox Classic.
setup-error-empty = Το αρχείο είναι κενό.
setup-error-too-large = Το αρχείο είναι πολύ μεγάλο για εισαγωγή ρυθμίσεων και λογαριασμών στο Inbox Classic.
setup-error-not-setup = Αυτό δεν είναι αρχείο ρυθμίσεων και λογαριασμών του Inbox Classic.
setup-error-damaged = Το αρχείο ρυθμίσεων είναι κατεστραμμένο και δεν μπορεί να διαβαστεί.
setup-error-newer = Αυτό το αρχείο ρυθμίσεων αποθηκεύτηκε από νεότερη έκδοση του Inbox Classic ({ $version }). Ενημερώστε το πρόγραμμα και δοκιμάστε ξανά την εισαγωγή.
setup-error-needs-passphrase = Αυτό το αρχείο ρυθμίσεων προστατεύεται με φράση πρόσβασης. Πληκτρολογήστε τη φράση πρόσβασης με την οποία αποθηκεύτηκε.
setup-error-wrong-passphrase = Η φράση πρόσβασης δεν είναι αυτή που χρησιμοποιήθηκε για την αποθήκευση του αρχείου ρυθμίσεων.
setup-error-changed = Το αρχείο ρυθμίσεων τροποποιήθηκε ή καταστράφηκε μετά την αποθήκευσή του και δεν μπορεί να εισαχθεί.
setup-error-read = Δεν ήταν δυνατή η ανάγνωση του αρχείου ρυθμίσεων: { $error }
setup-error-write = Δεν ήταν δυνατή η αποθήκευση του αρχείου ρυθμίσεων: { $error }
setup-error-no-parts = Επιλέξτε τουλάχιστον μία κατηγορία στοιχείων.
setup-left-out = { $count ->
    [one] { $count } καταχώριση στην κατηγορία «{ $part }» δεν μπορεί να χρησιμοποιηθεί και παραλείπεται.
   *[other] { $count } καταχωρίσεις στην κατηγορία «{ $part }» δεν μπορούν να χρησιμοποιηθούν και παραλείπονται.
}
setup-imported-settings = Οι ρυθμίσεις αντικαταστάθηκαν.
setup-imported-preferences = Οι προτιμήσεις παραθύρων αντικαταστάθηκαν.
setup-added-accounts = { $count ->
    [one] Προστέθηκε { $count } λογαριασμός.
   *[other] Προστέθηκαν { $count } λογαριασμοί.
}
setup-skipped-here = Ο λογαριασμός { $address } έχει ήδη ρυθμιστεί εδώ, οπότε παραλείφθηκε.
setup-skipped-no-app = Ο λογαριασμός { $address } παραλείφθηκε: η εφαρμογή σύνδεσης { $app } που χρησιμοποιεί δεν έχει ρυθμιστεί εδώ.
setup-skipped-invalid = Ο λογαριασμός { $address } παραλείφθηκε: { $reason }
setup-asks-password = Για τη σύνδεση στον λογαριασμό { $address } θα ζητηθεί ο κωδικός πρόσβασης.
setup-signs-in-again = Για τον λογαριασμό { $address } θα ζητηθεί να συνδεθείτε ξανά.
setup-added-sign-in-apps = { $count ->
    [one] Προστέθηκε { $count } εφαρμογή σύνδεσης.
   *[other] Προστέθηκαν { $count } εφαρμογές σύνδεσης.
}
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } εφαρμογή σύνδεσης έχει ήδη ρυθμιστεί εδώ.
   *[other] { $count } εφαρμογές σύνδεσης έχουν ήδη ρυθμιστεί εδώ.
}
setup-added-contacts = { $count ->
    [one] Προστέθηκε { $count } επαφή στο Βιβλίο διευθύνσεων.
   *[other] Προστέθηκαν { $count } επαφές στο Βιβλίο διευθύνσεων.
}
setup-skipped-contacts = { $count ->
    [one] { $count } επαφή υπάρχει ήδη στο Βιβλίο διευθύνσεων.
   *[other] { $count } επαφές υπάρχουν ήδη στο Βιβλίο διευθύνσεων.
}
setup-added-groups = { $count ->
    [one] Προστέθηκε ή συμπληρώθηκε { $count } ομάδα.
   *[other] Προστέθηκαν ή συμπληρώθηκαν { $count } ομάδες.
}
setup-added-own-keys = { $count ->
    [one] Προστέθηκε { $count } δικό σας κλειδί.
   *[other] Προστέθηκαν { $count } δικά σας κλειδιά.
}
setup-added-contact-keys = { $count ->
    [one] Προστέθηκε { $count } κλειδί επαφής.
   *[other] Προστέθηκαν { $count } κλειδιά επαφών.
}
setup-added-rules = { $count ->
    [one] Προστέθηκε { $count } κανόνας μηνυμάτων.
   *[other] Προστέθηκαν { $count } κανόνες μηνυμάτων.
}
setup-skipped-rules = { $count ->
    [one] { $count } κανόνας μηνυμάτων υπάρχει ήδη εδώ.
   *[other] { $count } κανόνες μηνυμάτων υπάρχουν ήδη εδώ.
}
setup-skipped-rules-account = { $count ->
    [one] { $count } κανόνας μηνυμάτων αφορά λογαριασμό που δεν υπάρχει εδώ, οπότε παραλείφθηκε.
   *[other] { $count } κανόνες μηνυμάτων αφορούν λογαριασμούς που δεν υπάρχουν εδώ, οπότε παραλείφθηκαν.
}
setup-rules-waiting = { $count ->
    [one] { $count } κανόνας μηνυμάτων μετακινεί μηνύματα σε φάκελο που θα εμφανιστεί μόλις συγχρονιστεί ο λογαριασμός του.
   *[other] { $count } κανόνες μηνυμάτων μετακινούν μηνύματα σε φακέλους που θα εμφανιστούν μόλις συγχρονιστούν οι λογαριασμοί τους.
}
setup-added-trusted-senders = { $count ->
    [one] Προστέθηκε { $count } αξιόπιστος αποστολέας.
   *[other] Προστέθηκαν { $count } αξιόπιστοι αποστολείς.
}
setup-nothing = Δεν εισήχθη τίποτα.
setup-account-servers = { $imap } και { $smtp } ({ $signin })
setup-file-name = Ρυθμίσεις και λογαριασμοί Inbox Classic
setup-skipped-unreachable = Η εφαρμογή σύνδεσης { $name } παραλείφθηκε: η υπηρεσία σύνδεσής της δεν ήταν προσβάσιμη. Προσθέστε την ξανά στις Εφαρμογές σύνδεσης.
attachment-runs-programs = Το αρχείο «{ $name }» μπορεί να εκτελέσει προγράμματα, γι’ αυτό το Inbox Classic δεν το ανοίγει. Αποθηκεύστε το και ανοίξτε το μόνοι σας, αν εμπιστεύεστε την προέλευσή του.
attachment-decrypted-note = Αυτό το συνημμένο προέρχεται από κρυπτογραφημένο μήνυμα. Για να το ανοίξει, το Inbox Classic αποθηκεύει ένα μη κρυπτογραφημένο αντίγραφο σε προσωρινό φάκελο του λογαριασμού χρήστη σας. Κατά την εκκίνηση του προγράμματος αφαιρούνται αντίγραφα παλαιότερα της μίας ημέρας.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
undone-move = { $count ->
    [one] Ο διακομιστής δεν μετακίνησε { $messages } στον φάκελο «{ $folder }», οπότε βρίσκεται ξανά στον φάκελο «{ $from }»: { $reason }
   *[other] Ο διακομιστής δεν μετακίνησε { $messages } στον φάκελο «{ $folder }», οπότε βρίσκονται ξανά στον φάκελο «{ $from }»: { $reason }
}
undone-delete = { $count ->
    [one] Ο διακομιστής δεν διέγραψε { $messages }, οπότε βρίσκεται ξανά στον φάκελο «{ $from }»: { $reason }
   *[other] Ο διακομιστής δεν διέγραψε { $messages }, οπότε βρίσκονται ξανά στον φάκελο «{ $from }»: { $reason }
}
undone-archive = { $count ->
    [one] Ο διακομιστής δεν αρχειοθέτησε { $messages }, οπότε βρίσκεται ξανά στον φάκελο «{ $from }»: { $reason }
   *[other] Ο διακομιστής δεν αρχειοθέτησε { $messages }, οπότε βρίσκονται ξανά στον φάκελο «{ $from }»: { $reason }
}
undone-read = { $count ->
    [one] Ο διακομιστής δεν επισήμανε { $messages } ως αναγνωσμένο, οπότε είναι ξανά αδιάβαστο: { $reason }
   *[other] Ο διακομιστής δεν επισήμανε { $messages } ως αναγνωσμένα, οπότε είναι ξανά αδιάβαστα: { $reason }
}
undone-unread = { $count ->
    [one] Ο διακομιστής δεν επισήμανε { $messages } ως αδιάβαστο, οπότε είναι ξανά αναγνωσμένο: { $reason }
   *[other] Ο διακομιστής δεν επισήμανε { $messages } ως αδιάβαστα, οπότε είναι ξανά αναγνωσμένα: { $reason }
}
undone-flags = { $count ->
    [one] Ο διακομιστής δεν άλλαξε τις σημαίες για { $messages }, οπότε η αλλαγή αναιρέθηκε: { $reason }
   *[other] Ο διακομιστής δεν άλλαξε τις σημαίες για { $messages }, οπότε η αλλαγή αναιρέθηκε: { $reason }
}
