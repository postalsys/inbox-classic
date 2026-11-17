# Ελληνικά. Προσχέδιο, περιμένει έλεγχο από φυσικό ομιλητή (βλ. core/locales/GLOSSARY.md).
# What the core says, the same on every platform. Placeables in { $braces } are filled in by the code. Plurals in
# Greek: [one] and *[other].

## Counts and sizes

# review: new
messages = { $count ->
    [one] { $count } μήνυμα
   *[other] { $count } μηνύματα
}
# the separator of decimals in sizes: 2,4 MB
# review: new
decimal-separator = ,
# review: new
size-bytes = { $count ->
    [one] { $count } byte
   *[other] { $count } byte
}
# review: new
size-kb = { $size } KB
# review: new
size-mb = { $size } MB
# review: new
size-gb = { $size } GB
# review: new
send-delay-off = Ανενεργό
# review: new
send-delay-seconds = { $count ->
    [one] { $count } δευτερόλεπτο
   *[other] { $count } δευτερόλεπτα
}
# the status bar: "12 μηνύματα, 3 αδιάβαστα"
# review: new
list-counts = { $messages }, { $unread } αδιάβαστα
# review: new
list-counts-selected = { $messages }, { $unread } αδιάβαστα, { $selected } επιλεγμένα
# the status bar while searching: "12 βρέθηκαν, 3 αδιάβαστα"
# review: new
list-counts-found = { $found } βρέθηκαν, { $unread } αδιάβαστα
# review: new
list-counts-found-selected = { $found } βρέθηκαν, { $unread } αδιάβαστα, { $selected } επιλεγμένα
# review: new
list-counts-none = Δεν βρέθηκαν μηνύματα

## Special folders, as Outlook names them in Greek

# review: new
folder-inbox = Εισερχόμενα
# review: new
folder-sent = Απεσταλμένα
# review: new
folder-deleted = Διαγραμμένα
# review: new
folder-drafts = Πρόχειρα
# review: new
folder-junk = Ανεπιθύμητη αλληλογραφία
# review: new
folder-archive = Αρχειοθέτηση

## The reading pane

# review: new
reader-no-message = Δεν έχει επιλεγεί μήνυμα.
# review: new
reader-downloading = Γίνεται λήψη του μηνύματος…
# review: new
reader-downloading-detail = Το μήνυμα θα εμφανιστεί εδώ μόλις ολοκληρωθεί η λήψη.
# review: new
reader-downloading-size = Το μήνυμα έχει μέγεθος { $size }. Θα εμφανιστεί εδώ μόλις γίνει η λήψη του.
# review: new
reader-failed = Δεν ήταν δυνατή η λήψη του μηνύματος
# review: new
reader-failed-network = Ο διακομιστής αλληλογραφίας δεν ήταν προσβάσιμος ({ $reason }).
# review: new
reader-failed-sign-in = Ο διακομιστής αλληλογραφίας δεν δέχτηκε τη σύνδεση ({ $reason }). Ελέγξτε τον κωδικό πρόσβασης ή συνδεθείτε ξανά από το Αρχείο > Λογαριασμοί.
# review: new
reader-failed-security = Δεν ήταν δυνατή η ασφαλής σύνδεση με τον διακομιστή αλληλογραφίας ({ $reason }).
# review: new
reader-failed-other = Ο διακομιστής αλληλογραφίας απάντησε: { $reason }.
# review: new
reader-retry-note = Θα γίνει νέα προσπάθεια όταν ο λογαριασμός συνδεθεί ξανά.
# review: new
reader-unreadable = Δεν είναι δυνατή η εμφάνιση αυτού του μηνύματος: { $error }
# review: new
message-source-title = Κώδικας μηνύματος: { $subject }
# review: new
message-source-untitled = Κώδικας μηνύματος

## Printing a message, and the header of a message quoted in a reply or forward

# review: new
header-from = Από
# review: new
header-date = Ημερομηνία
# review: new
header-to = Προς
# review: new
header-cc = Κοιν.
# review: new
header-sent = Στάλθηκε
# review: new
header-subject = Θέμα
# review: new
header-security = Ασφάλεια
# review: new
header-part = Τμήμα { $number }
# review: new
quote-original = ----- Αρχικό μήνυμα -----
# review: new
fold-show-earlier = Εμφάνιση των προηγούμενων μηνυμάτων

## Bounces: the card at the top of a notice that a message was not delivered

# review: new
bounce-failed = Το μήνυμά σας δεν παραδόθηκε
# review: new
bounce-delayed = Το μήνυμά σας δεν έχει παραδοθεί ακόμη
# review: new
bounce-delayed-note = Ο διακομιστής αλληλογραφίας σας εξακολουθεί να προσπαθεί να το παραδώσει. Δεν χρειάζεται να το στείλετε ξανά.
# the link to the message the notice is about, in Sent Items or another folder
# review: new
bounce-show-message = Εμφάνιση του μηνύματος που επιστράφηκε
# the link of a delay's card to the message that is still on its way
# review: new
bounce-show-delayed = Εμφάνιση του μηνύματος που καθυστερεί
# review: new
bounce-what-to-do = Τι μπορείτε να κάνετε:
# what to do about a recipient the message is still on its way to: in the card of a delay, and in the card of a failure
# review: new
bounce-delayed-do = Τίποτα προς το παρόν. Αν εξακολουθεί να μην μπορεί να παραδοθεί, θα λάβετε νέα ειδοποίηση.
# review: new
bounce-delayed-row-do = Τίποτα προς το παρόν. Ο διακομιστής αλληλογραφίας σας εξακολουθεί να προσπαθεί να το παραδώσει και θα λάβετε νέα ειδοποίηση αν δεν τα καταφέρει.
# folds the receiving server's own words
# review: new
bounce-details = Λεπτομέρειες
# a recipient the notice does not name
# review: new
bounce-someone = Ένας παραλήπτης
# in Details: the server that refused the message, the status code it gave, and the server that wrote the notice
# review: new
bounce-server = Διακομιστής: { $server }
# review: new
bounce-status = Κατάσταση: { $status }
# review: new
bounce-reported-by = Αναφέρθηκε από: { $server }
# review: new
bounce-retry-minutes = Ο διακομιστής παραλήπτη ζήτησε αναμονή { $count ->
    [one] ενός λεπτού
   *[other] { $count } λεπτών
} πριν από την επόμενη προσπάθεια.
# review: new
bounce-retry-hours = Ο διακομιστής παραλήπτη ζήτησε αναμονή { $count ->
    [one] μίας ώρας
   *[other] { $count } ωρών
} πριν από την επόμενη προσπάθεια.
# the names of the blocklists, "Spamhaus ZEN, Barracuda"
# review: new
bounce-blocklist = Λίστα αποκλεισμού: { $lists }
# review: new
bounce-user-unknown = Η διεύθυνση δεν υπάρχει
# review: new
bounce-user-unknown-why = Ο διακομιστής παραλήπτη δεν έχει γραμματοκιβώτιο με αυτή τη διεύθυνση. Ίσως γράφτηκε λάθος ή το άτομο δεν τη χρησιμοποιεί πια.
# review: new
bounce-user-unknown-do = Ελέγξτε την ορθογραφία της διεύθυνσης ή ζητήστε από το άτομο τη διεύθυνση που χρησιμοποιεί τώρα.
# review: new
bounce-invalid-address = Η διεύθυνση δεν είναι έγκυρη
# review: new
bounce-invalid-address-why = Η διεύθυνση δεν είναι γραμμένη σε μορφή στην οποία μπορεί να σταλεί αλληλογραφία.
# review: new
bounce-invalid-address-do = Αναζητήστε λάθη πληκτρολόγησης, όπως ένα κενό, ένα γράμμα που λείπει ή τίποτα μετά το @.
# review: new
bounce-mailbox-disabled = Το γραμματοκιβώτιο έχει κλείσει
# review: new
bounce-mailbox-disabled-why = Η διεύθυνση υπάρχει, αλλά το γραμματοκιβώτιό της έχει απενεργοποιηθεί ή δεν χρησιμοποιείται πια.
# review: new
bounce-mailbox-disabled-do = Επικοινωνήστε με το άτομο με άλλον τρόπο και ζητήστε μια διεύθυνση που χρησιμοποιεί τώρα.
# review: new
bounce-mailbox-full = Το γραμματοκιβώτιο είναι γεμάτο
# review: new
bounce-mailbox-full-why = Το γραμματοκιβώτιο του παραλήπτη δεν έχει χώρο για νέα αλληλογραφία.
# review: new
bounce-mailbox-full-do = Στείλτε το ξανά σε λίγες ημέρες ή ενημερώστε το άτομο με άλλον τρόπο. Τα μεγάλα συνημμένα απορρίπτονται πρώτα.
# review: new
bounce-spam-blocked = Απορρίφθηκε ως ανεπιθύμητο
# review: new
bounce-spam-blocked-why = Ο διακομιστής παραλήπτη θεώρησε το μήνυμα ανεπιθύμητο.
# review: new
bounce-spam-blocked-do = Στείλτε το ξανά χωρίς ό,τι μοιάζει με ανεπιθύμητη αλληλογραφία, όπως πολλούς συνδέσμους, συντομευμένους συνδέσμους ή ένα μεγάλο συνημμένο. Αν συνεχίσει να συμβαίνει, ρωτήστε τον πάροχο αλληλογραφίας σας.
# review: new
bounce-virus-detected = Απορρίφθηκε λόγω ιού
# review: new
bounce-virus-detected-why = Ο διακομιστής παραλήπτη βρήκε ιό ή άλλο επιβλαβές περιεχόμενο στο μήνυμα ή στα συνημμένα του.
# review: new
bounce-virus-detected-do = Ελέγξτε τα συνημμένα με ένα πρόγραμμα προστασίας από ιούς. Ορισμένοι διακομιστές απορρίπτουν κάθε πρόγραμμα ή αρχείο συμπίεσης, οπότε μοιραστείτε τέτοια αρχεία ως σύνδεσμο.
# review: new
bounce-ip-blocklisted = Ο διακομιστής αλληλογραφίας σας είναι σε λίστα αποκλεισμού
# review: new
bounce-ip-blocklisted-why = Ο διακομιστής παραλήπτη απορρίπτει αλληλογραφία από τον διακομιστή που έστειλε τη δική σας, επειδή η διεύθυνση αυτού του διακομιστή είναι σε λίστα αποκλεισμού.
# review: new
bounce-ip-blocklisted-do = Το πρόβλημα δεν είναι το μήνυμα. Προωθήστε αυτή την ειδοποίηση στον πάροχο αλληλογραφίας σας και ζητήστε του να αφαιρεθεί ο διακομιστής από τη λίστα.
# review: new
bounce-domain-blocklisted = Ένας τομέας είναι σε λίστα αποκλεισμού
# review: new
bounce-domain-blocklisted-why = Ο διακομιστής παραλήπτη απορρίπτει το μήνυμα επειδή ο τομέας της διεύθυνσής σας, ή ένας τομέας στους συνδέσμους του μηνύματος, είναι σε λίστα αποκλεισμού.
# review: new
bounce-domain-blocklisted-do = Αν το μήνυμα έχει συνδέσμους, δοκιμάστε το χωρίς αυτούς. Διαφορετικά, προωθήστε αυτή την ειδοποίηση σε όποιον διαχειρίζεται την αλληλογραφία του τομέα σας.
# review: new
bounce-policy-blocked = Απορρίφθηκε από τους κανόνες του διακομιστή παραλήπτη
# review: new
bounce-policy-blocked-why = Οι κανόνες του διακομιστή παραλήπτη δεν αφήνουν να περάσει αυτό το μήνυμα, για παράδειγμα λόγω του μεγέθους του, των συνημμένων του ή του αποστολέα του.
# review: new
bounce-policy-blocked-do = Τα λόγια του ίδιου του διακομιστή στις Λεπτομέρειες συχνά δίνουν την αιτία. Ρωτήστε τον παραλήπτη αν μπορεί να δεχτεί τέτοια αλληλογραφία.
# review: new
bounce-geo-blocked = Απορρίφθηκε λόγω προέλευσης
# review: new
bounce-geo-blocked-why = Ο διακομιστής παραλήπτη δεν δέχεται αλληλογραφία από τη χώρα ή το δίκτυο όπου βρίσκεται ο διακομιστής αλληλογραφίας σας.
# review: new
bounce-geo-blocked-do = Επικοινωνήστε με το άτομο με άλλον τρόπο ή ρωτήστε σχετικά τον πάροχο αλληλογραφίας σας.
# review: new
bounce-relay-denied = Ο διακομιστής δεν το προώθησε
# review: new
bounce-relay-denied-why = Ένας διακομιστής αρνήθηκε να παραδώσει το μήνυμα παρακάτω, συχνά επειδή στάλθηκε χωρίς σύνδεση ή μέσω διακομιστή που δεν εξυπηρετεί αυτόν τον παραλήπτη.
# review: new
bounce-relay-denied-do = Ελέγξτε τον διακομιστή εξερχομένων του λογαριασμού στο Αρχείο > Λογαριασμοί, καθώς και ότι συνδέεται.
# review: new
bounce-auth-failure = Δεν ήταν δυνατή η επαλήθευση της διεύθυνσης αποστολέα σας
# review: new
bounce-auth-failure-why = Ο διακομιστής παραλήπτη δεν μπόρεσε να επιβεβαιώσει ότι το μήνυμα προήλθε πράγματι από τον τομέα σας (SPF, DKIM ή DMARC).
# review: new
bounce-auth-failure-do = Προωθήστε αυτή την ειδοποίηση σε όποιον διαχειρίζεται την αλληλογραφία του τομέα σας: οι ρυθμίσεις του χρειάζονται διόρθωση. Στο μεταξύ, μπορεί να βοηθήσει η αποστολή μέσω του διακομιστή του παρόχου σας.
# review: new
bounce-rate-limited = Πάρα πολλή αλληλογραφία ταυτόχρονα
# review: new
bounce-rate-limited-why = Ο διακομιστής παραλήπτη δέχεται προς το παρόν λιγότερα μηνύματα από τον διακομιστή αλληλογραφίας σας.
# review: new
bounce-rate-limited-do = Περιμένετε λίγο και στείλτε το ξανά. Όταν γράφετε σε πολλούς, στέλνετε σε λιγότερους κάθε φορά.
# review: new
bounce-greylisting = Κρατήθηκε για λίγο
# review: new
bounce-greylisting-why = Ο διακομιστής παραλήπτη ζητά από άγνωστους αποστολείς να δοκιμάσουν ξανά λίγο αργότερα, ένας συνηθισμένος έλεγχος κατά της ανεπιθύμητης αλληλογραφίας.
# review: new
bounce-greylisting-do = Τίποτα. Οι διακομιστές αλληλογραφίας δοκιμάζουν ξανά μόνοι τους και το μήνυμα συνήθως παραδίδεται μέσα σε μία ώρα.
# review: new
bounce-server-error = Ο διακομιστής παραλήπτη είχε πρόβλημα
# review: new
bounce-server-error-why = Ο διακομιστής παραλήπτη δεν ήταν προσβάσιμος ή δεν μπόρεσε να δεχτεί το μήνυμα λόγω δικού του προβλήματος.
# review: new
bounce-server-error-do = Στείλτε το ξανά αργότερα. Αν συνεχίσει να αποτυγχάνει, ελέγξτε το τμήμα της διεύθυνσης μετά το @ για λάθη πληκτρολόγησης.
# review: new
bounce-unknown = Δεν παραδόθηκε
# review: new
bounce-unknown-why = Η ειδοποίηση δεν λέει με σαφήνεια γιατί.
# review: new
bounce-unknown-do = Τα λόγια του ίδιου του διακομιστή στις Λεπτομέρειες ίσως πουν περισσότερα. Αν δεν βοηθούν, προωθήστε αυτή την ειδοποίηση στον πάροχο αλληλογραφίας σας.

## Several messages selected

# review: new
selection-title = { $count ->
    [one] { $count } επιλεγμένο μήνυμα
   *[other] { $count } επιλεγμένα μηνύματα
}
# review: new
selection-unread = { $count } αδιάβαστα
# review: new
selection-flagged = { $count } με σημαία
# review: new
delete-for-good-one = Αυτό το μήνυμα θα διαγραφεί οριστικά. Να διαγραφεί;
# review: new
delete-for-good-all = Αυτά τα { $count } μηνύματα θα διαγραφούν οριστικά. Να διαγραφούν;
# review: new
delete-for-good-some = { $count } από τα { $total } μηνύματα θα διαγραφούν οριστικά. Να διαγραφούν τα μηνύματα;
# review: new
done-read = { $count ->
    [one] { $messages } επισημάνθηκε ως αναγνωσμένο
   *[other] { $messages } επισημάνθηκαν ως αναγνωσμένα
}
# review: new
done-unread = { $count ->
    [one] { $messages } επισημάνθηκε ως αδιάβαστο
   *[other] { $messages } επισημάνθηκαν ως αδιάβαστα
}
# review: new
done-flagged = { $count ->
    [one] Προστέθηκε σημαία σε { $messages }
   *[other] Προστέθηκε σημαία σε { $messages }
}
# review: new
done-unflagged = Αφαιρέθηκε η σημαία από { $messages }
# review: new
done-deleted-for-good = { $count ->
    [one] { $messages } διαγράφηκε οριστικά
   *[other] { $messages } διαγράφηκαν οριστικά
}
# review: new
done-archived = { $count ->
    [one] { $messages } αρχειοθετήθηκε
   *[other] { $messages } αρχειοθετήθηκαν
}
# review: new
done-moved = { $count ->
    [one] Μετακινήθηκε { $messages } σε: { $folder }
   *[other] Μετακινήθηκαν { $messages } σε: { $folder }
}
# review: new
done-copied = { $count ->
    [one] Αντιγράφηκε { $messages } σε: { $folder }
   *[other] Αντιγράφηκαν { $messages } σε: { $folder }
}
# review: new
done-moving = { $count ->
   *[other] Μετακίνηση { $messages } σε: { $folder }...
}
# review: new
done-copying = { $count ->
   *[other] Αντιγραφή { $messages } σε: { $folder }...
}
# review: new
done-moved-back = { $count ->
    [one] Μετακινήθηκε ξανά { $messages } σε: { $folder }
   *[other] Μετακινήθηκαν ξανά { $messages } σε: { $folder }
}
# the status bar after Watch Conversation and Ignore Conversation, and after either again on a marked one
# review: new
done-watched = { $count ->
    [one] Παρακολουθείτε τη συζήτηση
   *[other] Παρακολουθείτε { $count } συζητήσεις
}
# review: new
done-unwatched = { $count ->
    [one] Σταματήσατε να παρακολουθείτε τη συζήτηση
   *[other] Σταματήσατε να παρακολουθείτε { $count } συζητήσεις
}
# review: new
done-ignored = { $count ->
    [one] Αγνοείτε τη συζήτηση
   *[other] Αγνοείτε { $count } συζητήσεις
}
# review: new
done-unignored = { $count ->
    [one] Σταματήσατε να αγνοείτε τη συζήτηση
   *[other] Σταματήσατε να αγνοείτε { $count } συζητήσεις
}
# review: new
their-folders = αρχικοί φάκελοι
# review: new
undo-move = Αναίρεση μετακίνησης
# review: new
undo-delete = Αναίρεση διαγραφής
# review: new
undo-archive = Αναίρεση αρχειοθέτησης
# review: new
undo-junk = Αναίρεση επισήμανσης ως ανεπιθύμητου
# review: new
undo-not-junk = Αναίρεση επισήμανσης ως μη ανεπιθύμητου
# review: new
undo-send = Αναίρεση αποστολής
# review: new
nothing-to-undo = Δεν υπάρχει τίποτα για αναίρεση.
# review: new
messages-gone = Τα μηνύματα δεν υπάρχουν πια.
# A non-selectable IMAP folder cannot contain messages; this does not mean it is empty.
# review: new
folder-holds-no-messages = Αυτός ο φάκελος δεν μπορεί να περιέχει μηνύματα.
# review: new
not-archived-here = Τα μηνύματα αυτού του φακέλου δεν μπορούν να αρχειοθετηθούν.
# review: new
not-emptied-here = Μόνο τα Διαγραμμένα και η Ανεπιθύμητη αλληλογραφία μπορούν να αδειάσουν.
# review: new
next-unread-question = Δεν υπάρχουν άλλα αδιάβαστα μηνύματα στον φάκελο «{ $folder }».

    Να γίνει μετάβαση στον φάκελο «{ $next }», τον επόμενο φάκελο με αδιάβαστα μηνύματα;
# review: new
no-unread-left = Δεν έχουν μείνει αδιάβαστα μηνύματα.
# review: new
empty-question = { $count ->
    [one] Να αδειάσει ο φάκελος «{ $folder }»;

        Το μήνυμα που περιέχει διαγράφεται οριστικά. Δεν μπορεί να ανακτηθεί.
   *[other] Να αδειάσει ο φάκελος «{ $folder }»;

        Τα { $messages } που περιέχει διαγράφονται οριστικά. Δεν μπορούν να ανακτηθούν.
}
# review: new
no-junk-folder = Αυτός ο λογαριασμός δεν έχει φάκελο Ανεπιθύμητης αλληλογραφίας για να μετακινηθούν εκεί τα μηνύματα.
# review: new
no-inbox-folder = Αυτός ο λογαριασμός δεν έχει φάκελο Εισερχομένων για να μετακινηθούν εκεί τα μηνύματα.
# the status bar after a flag in a colour: "Σε 2 μηνύματα προστέθηκε κόκκινη σημαία"
# review: new
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
# review: new
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

# review: new
move-window-title-move = { $count ->
    [one] Μετακίνηση μηνύματος
   *[other] Μετακίνηση { $count } μηνυμάτων
}
# review: new
move-window-title-copy = { $count ->
    [one] Αντιγραφή μηνύματος
   *[other] Αντιγραφή { $count } μηνυμάτων
}
# review: new
move-window-prompt-move = { $count ->
    [one] Μετακίνηση του επιλεγμένου μηνύματος σε:
   *[other] Μετακίνηση των { $count } επιλεγμένων μηνυμάτων σε:
}
# review: new
move-window-prompt-copy = { $count ->
    [one] Αντιγραφή του επιλεγμένου μηνύματος σε:
   *[other] Αντιγραφή των { $count } επιλεγμένων μηνυμάτων σε:
}
# the folders used last, over the folder tree
# review: new
targets-recent = Πρόσφατα
# the folder the messages are in, which can not be chosen
# review: new
target-current = { $folder } (τρέχων)
# a folder used last, with its account when there are several: "Αρχειοθέτηση (Εργασία)"
# review: new
target-recent = { $folder } ({ $account })

## Moving and copying to another account

# review: new
transfer-moving = Μετακίνηση { $done } από τα { $messages } σε: { $folder }...
# review: new
transfer-copying = Αντιγραφή { $done } από τα { $messages } σε: { $folder }...
# review: new
transfer-another-account = άλλος λογαριασμός
# review: new
transfer-folder-gone = ο φάκελος προορισμού δεν υπάρχει πια
# review: new
transfer-not-on-server = το μήνυμα δεν υπάρχει πια στον διακομιστή
# review: new
transfer-not-moved = { $count ->
   *[other] Δεν ήταν δυνατή η μετακίνηση { $messages } σε άλλο λογαριασμό: { $reason }
}
# review: new
transfer-not-copied = { $count ->
   *[other] Δεν ήταν δυνατή η αντιγραφή { $messages } σε άλλο λογαριασμό: { $reason }
}
# review: new
transfer-none-moved = Δεν ήταν δυνατή η μετακίνηση κανενός μηνύματος
# review: new
transfer-none-copied = Δεν ήταν δυνατή η αντιγραφή κανενός μηνύματος

## Messages as files

# review: new
export-not-in-time = δεν ήταν δυνατή η λήψη του μηνύματος εγκαίρως
# review: new
export-not-saved = Δεν ήταν δυνατή η αποθήκευση { $failed } από τα { $messages } ({ $problems })
# review: new
export-not-attached = δεν ήταν δυνατή η επισύναψη των μηνυμάτων: { $error }
# the status bar after Save As with several: "Αποθηκεύτηκαν 3 μηνύματα στην Επιφάνεια εργασίας"
# review: new
saved-to = { $count ->
    [one] Αποθηκεύτηκε { $messages } στον φάκελο «{ $folder }»
   *[other] Αποθηκεύτηκαν { $messages } στον φάκελο «{ $folder }»
}
# review: new
download-progress = Λήψη { $done } από { $total }
# review: new
download-done = Έγινε λήψη { $size }
# review: new
downloading-messages = { $count ->
   *[other] Λήψη { $messages }...
}
# the status bar after files are dropped on a folder: "Μπήκαν 3 μηνύματα στην Αρχειοθέτηση"
# review: new
import-put = { $count ->
    [one] Προστέθηκε { $messages } στον φάκελο «{ $folder }»
   *[other] Προστέθηκαν { $messages } στον φάκελο «{ $folder }»
}
# review: new
import-not-put = Αυτά δεν μπήκαν στον φάκελο:

    { $problems }

## Problems the windows show

# review: new
error-store = τοπική αποθήκη: { $error }
# review: new
error-not-found = δεν βρέθηκε
# review: new
error-closed = γίνεται τερματισμός
# review: new
error-other-account = το πρόγραμμα περιήγησης συνδέθηκε ως { $email }, όχι σε αυτόν τον λογαριασμό
# a password or sign-in the mail server refused, with the server's words
# review: new
failure-authentication = ο διακομιστής δεν δέχτηκε τη σύνδεση ({ $reason })
# the mail server could not be reached or the connection broke, with the reason
# review: new
failure-network = η σύνδεση με τον διακομιστή απέτυχε ({ $reason })
# review: new
error-in-use = δεν μπορεί να καταργηθεί όσο συνδέονται λογαριασμοί με αυτήν: { $accounts }
# review: new
error-turned-off = αυτή η εφαρμογή σύνδεσης είναι απενεργοποιημένη για νέους λογαριασμούς
# review: new
error-folder-name = το όνομα του φακέλου πρέπει να έχει από 1 έως 200 χαρακτήρες και δεν μπορεί να περιέχει χαρακτήρες ελέγχου
# review: new
error-folder-separator = σε αυτόν τον διακομιστή ένα όνομα φακέλου δεν μπορεί να περιέχει «{ $separator }»
# review: new
error-folder-special = τα Εισερχόμενα και οι ειδικοί φάκελοι δεν μπορούν να μετονομαστούν ή να διαγραφούν
# review: new
error-no-recipients = το μήνυμα δεν έχει παραλήπτες
# review: new
error-bad-address = το «{ $address }» δεν είναι διεύθυνση ηλεκτρονικού ταχυδρομείου
# review: new
error-not-own-address = Η διεύθυνση { $address } δεν είναι μία από τις διευθύνσεις αποστολέα αυτού του λογαριασμού. Προσθέστε τη στο «Άλλες διευθύνσεις από τις οποίες στέλνετε» στις ιδιότητες του λογαριασμού.
# review: new
rule-query-refused = Οι κανόνες δεν μπορούν να φιλτράρουν κατά φάκελο ή ημερομηνία ({ $words }).
# review: new
rule-no-query = Εισαγάγετε κριτήρια αναζήτησης για τα εισερχόμενα μηνύματα.
# review: new
rule-no-action = Επιλέξτε τουλάχιστον μία ενέργεια για τον κανόνα.
# review: new
error-attachment = Δεν ήταν δυνατή η ανάγνωση του αρχείου { $path }: { $error }
# review: new
error-no-drafts = ο λογαριασμός δεν έχει φάκελο Πρόχειρα για να αποθηκευτεί το μήνυμα
# review: new
error-draft-attachment = δεν ήταν δυνατή η διατήρηση ενός συνημμένου του πρόχειρου: { $error }
# review: new
error-password-not-saved = δεν ήταν δυνατή η αποθήκευση του κωδικού πρόσβασης για την επόμενη εκκίνηση: { $error }
# review: new
error-sign-in-not-saved = δεν ήταν δυνατή η αποθήκευση των νέων στοιχείων σύνδεσης για την επόμενη εκκίνηση: { $error }
# review: new
error-import-unreadable = Δεν είναι δυνατή η ανάγνωση του αρχείου { $path }: { $error }
# review: new
error-import-too-large = Το αρχείο { $path } είναι μεγαλύτερο από 50 MB
# review: new
error-import-not-mail = Το αρχείο { $path } δεν είναι μήνυμα ηλεκτρονικού ταχυδρομείου
# review: new
error-list-answered = ο διακομιστής της λίστας αλληλογραφίας επέστρεψε την κατάσταση { $status }
# review: new
error-not-built = δεν ήταν δυνατή η δημιουργία του μηνύματος
# review: new
error-outbox-waits = { $count ->
    [one] το μήνυμα περιμένει στα Εξερχόμενα και θα σταλεί με την επόμενη Αποστολή/Λήψη
   *[other] { $count } μηνύματα περιμένουν στα Εξερχόμενα και θα σταλούν με την επόμενη Αποστολή/Λήψη
}
# review: new
error-draft-not-removed = δεν ήταν δυνατή η κατάργηση του προηγούμενου πρόχειρου του μηνύματος από τα Πρόχειρα: { $reason }
# review: new
error-sent-but = το μήνυμα στάλθηκε, αλλά { $problem }
# review: new
error-sent-still-in-outbox = βρίσκεται ακόμη στα Εξερχόμενα: { $error }
# review: new
error-sent-no-copy = δεν ήταν δυνατή η αποθήκευση αντιγράφου στα Απεσταλμένα: { $reason }
# review: new
error-no-password = δεν υπάρχει κωδικός πρόσβασης για αυτόν τον λογαριασμό
# review: new
error-no-sign-in = δεν υπάρχει σύνδεση για αυτόν τον λογαριασμό
# review: new
error-provider-missing = αυτή η έκδοση δεν μπορεί να συνδεθεί σε: { $provider }. Μήπως καταργήθηκε η εφαρμογή σύνδεσης;
# review: new
error-provider-servers = οι διακομιστές αυτού του λογαριασμού δεν ταιριάζουν με τους διακομιστές της εφαρμογής σύνδεσής του
# review: new
error-app-scopes = { $reason }. Ο διακομιστής αλληλογραφίας δεν δέχτηκε το διακριτικό της εφαρμογής σύνδεσης: ελέγξτε ότι τα δικαιώματα (scopes) της εφαρμογής δίνουν πρόσβαση στην αλληλογραφία
# review: new
error-in-folder = { $folder }: { $reason }

## Sign-in apps

# review: new
sign-in-off-google = Η Google δεν έχει επαληθεύσει ακόμη το Inbox Classic, οπότε επιτρέπει τη σύνδεση μέσω αυτού μόνο σε χρήστες δοκιμών. Χρησιμοποιήστε τη δική σας εφαρμογή σύνδεσης Google ή έναν κωδικό πρόσβασης εφαρμογής, ή ενεργοποιήστε την στις Εφαρμογές σύνδεσης (Αρχείο > Λογαριασμοί) αν είστε χρήστης δοκιμών.
# review: new
sign-in-off-other = Απενεργοποιήθηκε στις Εφαρμογές σύνδεσης (Αρχείο > Λογαριασμοί), όπου μπορεί να ενεργοποιηθεί ξανά.
# review: new
sign-in-app-no-name = η εφαρμογή σύνδεσης χρειάζεται όνομα
# review: new
sign-in-app-no-client = λείπει το αναγνωριστικό πελάτη
# review: new
sign-in-app-no-scopes = η εφαρμογή σύνδεσης χρειάζεται τα δικαιώματα (scopes) που δίνουν πρόσβαση στην αλληλογραφία
# review: new
sign-in-app-bad-host = η διεύθυνση του διακομιστή { $server } λείπει ή δεν είναι έγκυρο όνομα κεντρικού υπολογιστή
# review: new
sign-in-app-plain = ο διακομιστής { $server } πρέπει να χρησιμοποιεί SSL/TLS ή STARTTLS
# review: new
sign-in-app-not-checked = ο εκδότης δεν έχει ελεγχθεί ακόμη
# review: new
sign-in-app-issuer-changed = ο εκδότης άλλαξε: πληκτρολογήστε ξανά το μυστικό πελάτη ή καταργήστε το
# review: new
sign-in-register-google = Στο Google Cloud Console, δημιουργήστε έναν πελάτη OAuth τύπου Desktop app, με το δικαίωμα https://mail.google.com/ στην οθόνη συναίνεσής του. Όσο η εφαρμογή είναι σε δοκιμή, μόνο οι χρήστες δοκιμών της μπορούν να συνδεθούν.
# review: new
sign-in-register-microsoft = Στο Microsoft Entra, καταχωρίστε μια εφαρμογή με την πλατφόρμα Mobile and desktop applications, το URI ανακατεύθυνσης http://localhost, επιτρεπόμενες ροές δημόσιου πελάτη (public client flows) και τα εξουσιοδοτημένα δικαιώματα IMAP.AccessAsUser.All, SMTP.Send και offline_access. Μόνο για τον οργανισμό σας, χρησιμοποιήστε ως εκδότη το https://login.microsoftonline.com/<tenant ID>/v2.0.
# review: new
sign-in-register-other = Καταχωρίστε έναν εγγενή (δημόσιο) πελάτη με το παρακάτω URI ανακατεύθυνσης· ο πάροχος πρέπει να επιτρέπει οποιαδήποτε θύρα σε αυτό (RFC 8252). Προσθέστε το δικαίωμα με το οποίο ο πάροχος δίνει πρόσβαση στην αλληλογραφία.

## Calendar invitations

# review: new
repeats = Επανάληψη
# review: new
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
# review: new
repeats-on = { $repeats }: { $days }
# "Κάθε εβδομάδα, 10 φορές"
# review: new
repeats-times = { $count ->
    [one] { $repeats }, μία φορά
   *[other] { $repeats }, { $count } φορές
}
# review: new
day-monday = Δευτέρα
# review: new
day-tuesday = Τρίτη
# review: new
day-wednesday = Τετάρτη
# review: new
day-thursday = Πέμπτη
# review: new
day-friday = Παρασκευή
# review: new
day-saturday = Σάββατο
# review: new
day-sunday = Κυριακή

## AI agents

# review: new
agent-level-read = Ανάγνωση αλληλογραφίας: φάκελοι, λίστα μηνυμάτων, αναζήτηση και μηνύματα
# review: changed
agent-level-organize = Οργάνωση αλληλογραφίας: κατάσταση ανάγνωσης, σημαίες, ανεπιθύμητα, μετακίνηση, αρχειοθέτηση, νέοι φάκελοι, διαγραφή στα Διαγραμμένα και κατάργηση εγγραφής από λίστες αλληλογραφίας αφού συμφωνήσετε
# review: new
agent-level-drafts = Σύνταξη πρόχειρων που στέλνετε εσείς
# review: new
agent-level-send = Αποστολή αλληλογραφίας, κάθε μηνύματος μόνο αφού συμφωνήσετε
# review: new
agent-connect-title = Το πρόγραμμα { $program } θέλει να χρησιμοποιήσει την αλληλογραφία σας
# review: new
agent-connect-detail = Ένας πράκτορας ΤΝ ζήτησε να συνεργαστεί με το Inbox Classic. Επιλέξτε τι μπορεί να κάνει και ποιους λογαριασμούς μπορεί να βλέπει· μπορείτε να το αλλάξετε αργότερα στα Εργαλεία > Πράκτορες ΤΝ.

    Οι πράκτορες διαβάζουν αλληλογραφία που έγραψαν άλλοι, και ένα μήνυμα μπορεί να προσπαθήσει να τους ξεγελάσει. Το Inbox Classic σάς ρωτά πάντα πριν ένας πράκτορας στείλει οτιδήποτε.
# review: new
agent-reply-to = Απάντηση στο «{ $subject }»
# review: new
agent-reply-all-on = Απάντηση σε όλους στο «{ $subject }»
# review: new
agent-forward-of = Προώθηση του «{ $subject }»
# review: new
agent-never-written-one = Δεν έχετε γράψει ποτέ στη διεύθυνση { $address }.
# review: new
agent-never-written-many = Δεν έχετε γράψει ποτέ σε { $count } από αυτές τις διευθύνσεις.
# review: new
agent-send-title = Το πρόγραμμα { $program } θέλει να στείλει αυτό το μήνυμα
# review: new
agent-send-detail = Ελέγξτε τους παραλήπτες και το περιεχόμενο του μηνύματος. Μόλις επιβεβαιώσετε, το μήνυμα περιμένει { $seconds } δευτερόλεπτα στα Εξερχόμενα, όπου μπορείτε ακόμη να το διαγράψετε.
# review: new
agent-change-title = Τι μπορεί να κάνει το πρόγραμμα { $program }
# review: new
agent-change-allowed = Αλλάξτε τι μπορούν να κάνουν οι πράκτορες ΤΝ αυτού του προγράμματος με την αλληλογραφία σας.
# review: new
agent-change-refused = Αρνηθήκατε την πρόσβαση σε αυτό το πρόγραμμα. Επιτρέψτε την για να δώσετε ξανά στους πράκτορές του πρόσβαση στην αλληλογραφία σας.
# review: new
agent-log-taken-back = { $entry } (αναιρέθηκε)
# review: new
agent-files = Αρχεία: { $files }
# review: new
agent-undo-refused = Δεν μπορεί να αναιρεθεί.
# review: new
agent-undo-refused-why = Δεν μπορεί να αναιρεθεί: { $reason }.
# review: new
agent-undo-impossible = αυτό δεν μπορεί να αναιρεθεί
# review: new
agent-undo-not-in-folder = το μήνυμα δεν βρίσκεται πια σε αυτόν τον φάκελο
# review: new
agent-undo-not-arrived = το μήνυμα δεν βρίσκεται (ακόμη) στον φάκελο όπου μετακινήθηκε
# review: new
agent-undo-sent = το μήνυμα έχει ήδη σταλεί
# review: new
agent-original-not-downloaded = δεν έχει γίνει ακόμη λήψη του αρχικού μηνύματος. Ανοίξτε το πρώτα
# review: new
agent-turned-away = Απορρίφθηκε
# review: new
agent-can-nothing = Τίποτα
# review: new
agent-can-read = ανάγνωση
# review: new
agent-can-organize = οργάνωση
# review: new
agent-can-drafts = σύνταξη πρόχειρων
# review: new
agent-can-send = αποστολή με τη συγκατάθεσή σας
# "Ανάγνωση, οργάνωση και σύνταξη πρόχειρων"
# review: new
agent-can-list = { $first } και { $last }
# review: new
agent-accounts = { $count ->
    [0] κανένας λογαριασμός
    [one] { $count } λογαριασμός
   *[other] { $count } λογαριασμοί
}
# "Ανάγνωση και οργάνωση· 1 λογαριασμός"
# review: new
agent-access = { $can }· { $accounts }
# review: new
agent-unreadable = Δεν είναι δυνατή η ανάγνωση αυτού του μηνύματος.
# review: new
agent-encrypted-original = Αυτό το μήνυμα είναι κρυπτογραφημένο: ένας πράκτορας δεν μπορεί να του απαντήσει ή να το προωθήσει, καθώς δεν μπορεί να κρυπτογραφήσει.
# review: new
agent-encrypted = Αυτό το μήνυμα είναι κρυπτογραφημένο. Μόνο ο χρήστης μπορεί να το διαβάσει, στο Inbox Classic.
# review: new
list-encrypted = Κρυπτογραφημένο μήνυμα
# review: new
agent-log-composed = Άνοιξε το «{ $subject }» σε νέο μήνυμα για να το ολοκληρώσετε
# review: new
agent-log-refused = Δεν στείλατε το «{ $subject }»
# review: new
agent-log-sent = Στάλθηκε το «{ $subject }» προς { $to }
# review: new
agent-log-draft = Αποθηκεύτηκε το πρόχειρο «{ $subject }»
# review: new
agent-log-read = Επισημάνθηκε ως αναγνωσμένο το «{ $subject }»
# review: new
agent-log-unread = Επισημάνθηκε ως αδιάβαστο το «{ $subject }»
# review: new
agent-log-flagged = Προστέθηκε σημαία στο «{ $subject }»
# review: new
agent-log-unflagged = Αφαιρέθηκε η σημαία από το «{ $subject }»
# review: new
agent-log-deleted = Διαγράφηκε το «{ $subject }»
# review: new
agent-log-moved = Μετακινήθηκε το «{ $subject }» στον φάκελο «{ $folder }»
# review: new
agent-log-junk = Επισημάνθηκε ως ανεπιθύμητο το «{ $subject }»
# review: new
agent-log-not-junk = Επισημάνθηκε ως μη ανεπιθύμητο το «{ $subject }»
# review: new
agent-log-archived = Αρχειοθετήθηκε το «{ $subject }»
# review: new
agent-log-folder = Δημιουργήθηκε ο φάκελος «{ $name }»
# review: new
agent-log-unsubscribed = Έγινε κατάργηση εγγραφής από τη λίστα του «{ $subject }»
# review: new
agent-log-unsubscribe-failed = Δεν ήταν δυνατή η κατάργηση εγγραφής από τη λίστα του «{ $subject }»: { $reason }
# review: new
agent-log-unsubscribe-refused = Δεν καταργήσατε την εγγραφή σας από: { $senders }
# review: new
agent-unsubscribe-title = { $count ->
    [one] Το πρόγραμμα { $program } θέλει να καταργήσει την εγγραφή σας από μια λίστα αλληλογραφίας
   *[other] Το πρόγραμμα { $program } θέλει να καταργήσει την εγγραφή σας από { $count } λίστες αλληλογραφίας
}
# review: new
agent-unsubscribe-detail = Το Inbox Classic ζητά από κάθε λίστα παρακάτω να σταματήσει να σας στέλνει μηνύματα, με τον τρόπο ενός κλικ που προσφέρει η λίστα. Δεν στέλνεται τίποτε άλλο, και τα μηνύματα που έχετε μένουν εκεί που είναι.

## Keys as the keyboards of the language name them, in the help (Windows and Linux)

# review: new
key-ctrl = Ctrl
# review: new
key-alt = Alt
# review: new
key-shift = Shift
# review: new
key-del = Del
# review: new
key-enter = Enter

## Signing in and passwords

# review: new
sign-in-no-refresh = ο πάροχος δεν έδωσε διακριτικό ανανέωσης
# review: new
sign-in-no-account = ο πάροχος δεν είπε ποιος λογαριασμός συνδέθηκε
# review: new
sign-in-not-finished = η σύνδεση δεν έχει ολοκληρωθεί
# review: new
secrets-unavailable = Μη διαθέσιμο: { $store }
# review: new
secrets-unavailable-why = Μη διαθέσιμο: { $store } ({ $error })
# review: new
secrets-windows = Διαχείριση διαπιστευτηρίων
# review: new
secrets-mac = Κλειδοθήκη
# review: new
secrets-linux = Κλειδοθήκη συστήματος (Secret Service)
# review: new
error-no-such-file = δεν υπάρχει τέτοιο αρχείο
# review: new
cards-file-too-big = Αυτό το αρχείο είναι πολύ μεγάλο για να είναι βιβλίο διευθύνσεων.
# review: new
ui-sender-added = Η επαφή { $name } προστέθηκε στο Βιβλίο διευθύνσεων.
# review: new
ui-sender-known = Η επαφή { $name } υπάρχει ήδη στο Βιβλίο διευθύνσεων.
# review: new
ui-sender-none = Ο αποστολέας αυτού του μηνύματος δεν έχει διεύθυνση ηλεκτρονικού ταχυδρομείου για προσθήκη.
# review: new
card-name-needed = Η επαφή δεν έχει όνομα ούτε διεύθυνση ηλεκτρονικού ταχυδρομείου.
# a file of Import Address Book that could not be read: "contacts.vcf: δεν υπάρχει τέτοιο αρχείο"
# review: new
cards-file-failed = { $file }: { $reason }

## One-time codes: the card at the top of a message with a sign-in or verification code

# the domain the code is for, which signed the message
# review: new
otp-heading = Κωδικός από { $domain }
# review: new
otp-copy = Αντιγραφή
# review: new
otp-note = Εισαγάγετέ τον μόνο σε σελίδα του { $domain }.
# review: new
otp-old = Αυτός ο κωδικός στάλθηκε περισσότερο από μία ώρα πριν τον ανοίξετε και πιθανότατα έχει λήξει.

# how many are invited, in the card of an event
# review: new
event-attendees =
    { $count ->
        [one] { $count } συμμετέχων
       *[other] { $count } συμμετέχοντες
    }

# the first line of a new message's notification when it has a code, for a domain that signed it
# review: new
otp-notification = { $code }: ο κωδικός σας για { $domain }

## OpenPGP keys (keys.rs)
# review: new
pgp-key-valid = Έγκυρο
# review: new
pgp-key-expires = Έγκυρο έως { $date }
# review: new
pgp-key-expired = Έληξε στις { $date }
# review: new
pgp-key-revoked = Ανακλήθηκε
# review: new
pgp-key-revoked-why = Ανακλήθηκε: { $reason }
# review: new
pgp-key-not-valid = Μη έγκυρο
# review: new
pgp-key-locked = Δεν μπορεί να χρησιμοποιηθεί: το κλειδί που το προστατεύει δεν υπάρχει πια σε: { $store }. Εισαγάγετε ξανά το αντίγραφο ασφαλείας του.
# review: new
pgp-source-own = Δημιουργήθηκε στο Inbox Classic
# review: new
pgp-source-file = Εισήχθη από αρχείο
# review: new
pgp-source-paste = Επικολλήθηκε
# review: new
pgp-source-attachment = Από μήνυμα
# review: new
pgp-source-vcard = Από κάρτα επαφής
# review: new
pgp-source-wkd = Από τον πάροχο αλληλογραφίας του αποστολέα
# review: new
pgp-source-keyserver = Από το keys.openpgp.org
# review: new
pgp-source-autocrypt = Από την κεφαλίδα Autocrypt ενός μηνύματος
# review: new
pgp-error-no-store = Τα ιδιωτικά κλειδιά προστατεύονται από: { $store }, που δεν μπορεί να χρησιμοποιηθεί: { $error }
# review: new
pgp-error-wrong-passphrase = Η φράση πρόσβασης δεν είναι σωστή.
# review: new
pgp-error-not-a-key = Αυτό δεν είναι κλειδί OpenPGP.
# review: new
pgp-error-too-large = Το κλειδί είναι πολύ μεγάλο.
# review: new
pgp-error-unusable = Το κλειδί χρησιμοποιεί παλιά ή αδύναμη κρυπτογραφία και δεν μπορεί να χρησιμοποιηθεί.
# review: new
pgp-imported-private = { $count ->
    [one] Το ιδιωτικό σας κλειδί εισήχθη.
   *[other] Εισήχθησαν { $count } ιδιωτικά κλειδιά.
}
# review: new
pgp-imported-public = { $count ->
    [one] Εισήχθη ένα κλειδί.
   *[other] Εισήχθησαν { $count } κλειδιά.
}
# review: new
pgp-imported-pending = Χρησιμοποιείται ήδη άλλο κλειδί για { $addresses }: το νέο περιμένει στην επαφή μέχρι να το επιλέξετε.
# review: new
pgp-error-needs-passphrase = Το ιδιωτικό κλειδί προστατεύεται με φράση πρόσβασης. Πληκτρολογήστε την για να εισαγάγετε το κλειδί.
# review: new
pgp-error-mismatch = Το ιδιωτικό κλειδί δεν ανήκει στο δημόσιο κλειδί του. Ίσως έχει αλλοιωθεί.
# review: new
pgp-file-name-public = { $who } δημόσιο κλειδί.asc
# review: new
pgp-file-name-private = { $who } αντίγραφο ασφαλείας ιδιωτικού κλειδιού.asc
# review: new
pgp-pending = Βρέθηκε διαφορετικό κλειδί για { $address } στις { $date }.

## Reading signed and encrypted mail (protect.rs)
# review: new
pgp-part-verified = Υπογραφή από { $signer }, επαληθευμένο κλειδί
# review: new
pgp-part-signed = Υπογραφή από { $signer } (μη επαληθευμένο κλειδί)
# review: new
pgp-part-other = Υπογραφή από { $signer }, που δεν είναι ο αποστολέας
# review: new
pgp-part-unknown-key = Υπογεγραμμένο, αλλά το κλειδί δεν είναι γνωστό
# review: new
pgp-part-not-signed = Χωρίς υπογραφή
# review: new
pgp-part-not-checked = Η υπογραφή δεν ελέγχθηκε
# review: new
pgp-part-encrypted = Κρυπτογραφημένο. { $signature }
# review: new
pgp-part-no-key = Κρυπτογραφημένο για κλειδί που δεν έχετε
# review: new
pgp-part-changed = Το κρυπτογραφημένο τμήμα άλλαξε στη διαδρομή και δεν εμφανίζεται
# review: new
pgp-part-unprotected = Κρυπτογραφημένο χωρίς προστασία από αλλαγές, δεν εμφανίζεται
# review: new
pgp-part-broken = Δεν είναι δυνατή η ανάγνωση του κρυπτογραφημένου τμήματος
# review: new
pgp-why-mismatch = Η υπογραφή δεν ταιριάζει με αυτό το κείμενο
# review: new
pgp-why-weak-hash = Η υπογραφή χρησιμοποιεί { $hash }, που δεν είναι πια ασφαλές
# review: new
pgp-why-key-expired = Υπογράφηκε αφού έληξε το κλειδί στις { $date }
# review: new
pgp-why-key-revoked = Υπογράφηκε με κλειδί που ανακλήθηκε
# review: new
pgp-why-not-signing-key = Υπογράφηκε με κλειδί που δεν επιτρέπεται να υπογράφει
# review: new
pgp-why-from-future = Η υπογραφή έχει ημερομηνία στο μέλλον
# review: new
pgp-why-signature-expired = Η υπογραφή έχει λήξει
# review: new
pgp-why-key-not-valid = Υπογράφηκε με κλειδί που δεν είναι έγκυρο
# review: new
pgp-why-not-for-you = Υπογράφηκε για άλλους παραλήπτες και προωθήθηκε σε εσάς
# review: new
pgp-why-not-key-in-use = Υπογράφηκε με διαφορετικό κλειδί από αυτό που χρησιμοποιείται για { $address }
# review: new
pgp-part-pictures-loaded = { $label }. Φορτώθηκαν εικόνες από το διαδίκτυο
# review: new
pgp-error-no-own-key = Δεν έχετε κλειδί για { $address } για υπογραφή ή κρυπτογράφηση. Δημιουργήστε ένα στα Εργαλεία > Κλειδιά κρυπτογράφησης ή απενεργοποιήστε την Υπογραφή και την Κρυπτογράφηση.
# review: new
pgp-error-missing-keys = { $count ->
    [one] Ο παραλήπτης { $addresses } δεν έχει κλειδί για κρυπτογράφηση.
   *[other] Αυτοί οι παραλήπτες δεν έχουν κλειδί για κρυπτογράφηση: { $addresses }.
}
# review: new
pgp-error-encrypted-quote = Αυτό το μήνυμα παραθέτει ή προωθεί κρυπτογραφημένο μήνυμα, οπότε μπορεί να σταλεί μόνο κρυπτογραφημένο. Ενεργοποιήστε την Κρυπτογράφηση ή αφαιρέστε το κείμενο της παράθεσης.
# review: new
pgp-error-protect = Δεν ήταν δυνατή η υπογραφή ή η κρυπτογράφηση του μηνύματος: { $reason }
# review: new
pgp-found-keys = Βρέθηκε το κλειδί για { $addresses }.
# review: new
pgp-found-none = Δεν βρέθηκε κλειδί για { $addresses }. Ζητήστε τους να σας στείλουν το δημόσιο κλειδί τους.
# review: new
pgp-found-no-key = Δεν βρέθηκε κλειδί.
# review: new
pgp-find-unavailable = Δεν ήταν δυνατή η αναζήτηση κλειδιών τώρα: { $error }
# review: new
pgp-publish-pending = Το keys.openpgp.org έστειλε σύνδεσμο επιβεβαίωσης σε: { $addresses }. Το κλειδί σας δημοσιεύεται εκεί μόλις τον πατήσετε.
# review: new
pgp-publish-done = Το κλειδί σας δημοσιεύτηκε στο keys.openpgp.org για { $addresses }.
# review: new
pgp-publish-failed = Δεν ήταν δυνατή η δημοσίευση του κλειδιού: { $error }
# review: changed
pgp-keyserver-off = Η αναζήτηση κλειδιών στο keys.openpgp.org είναι απενεργοποιημένη στο { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
# review: new
pgp-compose-encrypted = { $count ->
    [one] Κρυπτογραφημένο και υπογεγραμμένο: μόνο εσείς και ο παραλήπτης { $addresses } μπορείτε να το διαβάσετε.
   *[other] Κρυπτογραφημένο και υπογεγραμμένο: μόνο εσείς και οι { $count } παραλήπτες του μπορείτε να το διαβάσετε.
}
# review: new
pgp-compose-encrypt-ready = Θα κρυπτογραφηθεί και θα υπογραφεί. Προσθέστε παραλήπτες των οποίων έχετε τα κλειδιά.
# review: new
pgp-compose-missing = { $count ->
    [one] Ο παραλήπτης { $addresses } δεν έχει κλειδί, οπότε το μήνυμα δεν μπορεί ακόμη να κρυπτογραφηθεί.
   *[other] { $count } παραλήπτες δεν έχουν κλειδί, οπότε το μήνυμα δεν μπορεί ακόμη να κρυπτογραφηθεί: { $addresses }.
}
# review: new
pgp-compose-looking = Αναζήτηση των κλειδιών για { $addresses }...
# review: new
pgp-compose-signed = Υπογεγραμμένο: οι παραλήπτες μπορούν να ελέγξουν ότι προέρχεται από εσάς και ότι δεν άλλαξε.
# review: new
pgp-compose-reply-clear = Δεν είναι κρυπτογραφημένο, αν και το μήνυμα στο οποίο απαντά ή που προωθεί ήταν κρυπτογραφημένο.
# review: new
pgp-compose-encrypted-files = Έχουν επισυναφθεί αρχεία ενός κρυπτογραφημένου μηνύματος, οπότε αυτό το μήνυμα μπορεί να σταλεί μόνο κρυπτογραφημένο. Ενεργοποιήστε την Κρυπτογράφηση ή αφαιρέστε αυτά τα αρχεία.
# review: new
pgp-compose-sign-tip = Υπογραφή του μηνύματος με το κλειδί σας, ώστε οι παραλήπτες να μπορούν να ελέγξουν ότι προέρχεται από εσάς και ότι δεν άλλαξε
# review: new
pgp-compose-sign-tip-encrypted = Ένα κρυπτογραφημένο μήνυμα είναι πάντα και υπογεγραμμένο
# review: new
pgp-compose-encrypt-tip = Κρυπτογράφηση του μηνύματος, ώστε να μπορείτε να το διαβάσετε μόνο εσείς και οι παραλήπτες του
# review: new
pgp-compose-make-key = Δεν έχετε ακόμη κλειδί για { $address }. Να δημιουργηθεί τώρα; Με αυτό, τα μηνύματά σας μπορούν να υπογράφονται και να κρυπτογραφούνται.
# review: new
pgp-compose-key-unusable = Το κλειδί σας για { $address } δεν μπορεί να χρησιμοποιηθεί ({ $state }). Ανοίξτε τα Κλειδιά κρυπτογράφησης για να εισαγάγετε το αντίγραφο ασφαλείας του ή να δημιουργήσετε νέο κλειδί.
# review: new
pgp-compose-encrypt-off-quote = Αυτό το μήνυμα παραθέτει ή προωθεί κρυπτογραφημένο μήνυμα. Χωρίς κρυπτογράφηση, δεν μπορεί να σταλεί μέχρι να αφαιρέσετε το κείμενο της παράθεσης. Να απενεργοποιηθεί η κρυπτογράφηση ούτως ή άλλως;
# review: new
pgp-compose-encrypt-off-reply = Αυτό το μήνυμα απαντά σε κρυπτογραφημένο μήνυμα ή το προωθεί. Χωρίς κρυπτογράφηση, όποιος χειρίζεται το μήνυμά σας στη διαδρομή μπορεί να το διαβάσει. Να απενεργοποιηθεί η κρυπτογράφηση;
# review: new
pgp-recipient-verified = Επαληθευμένο κλειδί
# review: new
pgp-recipient-found = Μη επαληθευμένο κλειδί
# review: new
pgp-recipient-own = Το δικό σας κλειδί
# review: new
pgp-recipient-looking = Αναζήτηση κλειδιού...
# review: new
pgp-recipient-missing = Χωρίς κλειδί
# review: new
pgp-recipient-not-found = Χωρίς κλειδί: δεν βρέθηκε κανένα στις { $date }
# review: new
pgp-recipient-unusable = Το κλειδί δεν μπορεί να χρησιμοποιηθεί: { $state }
# review: new
pgp-recipients-intro = Το μήνυμα κρυπτογραφείται για το κλειδί κάθε παραλήπτη και για το δικό σας.
# review: new
pgp-recipients-intro-missing = { $count ->
    [one] Ένας παραλήπτης δεν έχει κλειδί για κρυπτογράφηση. Βρείτε το κλειδί του, αφαιρέστε τον από αυτό το μήνυμα ή στείλτε το μήνυμα χωρίς κρυπτογράφηση.
   *[other] { $count } παραλήπτες δεν έχουν κλειδί για κρυπτογράφηση. Βρείτε τα κλειδιά τους, αφαιρέστε τους από αυτό το μήνυμα ή στείλτε το μήνυμα χωρίς κρυπτογράφηση.
}
# review: new
pgp-details-part = Τμήμα { $number }: { $label }
# review: new
pgp-details-signed = Υπογράφηκε { $when } με το κλειδί { $key }
# review: new
pgp-details-unknown-key = Υπογράφηκε με το κλειδί { $key }, που δεν έχετε
# review: new
pgp-details-opened = Κρυπτογραφημένο για το κλειδί σας { $key }
# review: new
pgp-details-for = Κρυπτογραφημένο για { $keys }
# review: new
pgp-details-plain = Χωρίς υπογραφή και χωρίς κρυπτογράφηση
# review: new
pgp-bar-parts = Αυτό το μήνυμα έχει { $count } τμήματα: { $list }. Κάθε τμήμα δείχνει πώς προστατεύεται.
# review: new
pgp-bar-count-verified = { $count } επαληθευμένα
# review: new
pgp-bar-count-good = { $count ->
    [one] { $count } υπογεγραμμένο ή κρυπτογραφημένο
   *[other] { $count } υπογεγραμμένα ή κρυπτογραφημένα
}
# review: new
pgp-bar-count-warning = { $count ->
    [one] { $count } χρειάζεται προσοχή
   *[other] { $count } χρειάζονται προσοχή
}
# review: new
pgp-bar-count-neutral = { $count } χωρίς επιβεβαιωμένη υπογραφή
# the setup file: settings, accounts, contacts and keys carried to another computer
# review: new
setup-part-settings = Ρυθμίσεις
# review: new
setup-part-preferences = Προτιμήσεις παραθύρων
# review: new
setup-part-accounts = Λογαριασμοί
# review: new
setup-part-sign-in-apps = Εφαρμογές σύνδεσης
# review: new
setup-part-contacts = Επαφές και ομάδες
# review: new
setup-part-keys = Κλειδιά κρυπτογράφησης
# review: new
setup-part-rules = Κανόνες μηνυμάτων
# review: new
setup-part-trusted-senders = Αξιόπιστοι αποστολείς
# review: new
setup-holds-settings = { $count ->
    [one] { $count } ρύθμιση
   *[other] { $count } ρυθμίσεις
}
# review: new
setup-holds-preferences = { $count ->
    [one] { $count } προτίμηση
   *[other] { $count } προτιμήσεις
}
# review: new
setup-holds-accounts = { $count ->
    [one] { $count } λογαριασμός
   *[other] { $count } λογαριασμοί
}
# review: new
setup-holds-sign-in-apps = { $count ->
    [one] { $count } εφαρμογή σύνδεσης
   *[other] { $count } εφαρμογές σύνδεσης
}
# review: new
setup-holds-built-in = Ποιες ενσωματωμένες εφαρμογές σύνδεσης είναι ενεργές
# review: new
setup-holds-contacts = { $count ->
    [one] { $count } επαφή
   *[other] { $count } επαφές
}
# review: new
setup-holds-groups = { $count ->
    [one] { $count } ομάδα
   *[other] { $count } ομάδες
}
# review: new
setup-holds-own-keys = { $count ->
    [one] { $count } δικό σας κλειδί
   *[other] { $count } δικά σας κλειδιά
}
# review: new
setup-holds-contact-keys = { $count ->
    [one] { $count } κλειδί επαφής
   *[other] { $count } κλειδιά επαφών
}
# review: new
setup-holds-rules = { $count ->
    [one] { $count } κανόνας
   *[other] { $count } κανόνες
}
# review: new
setup-holds-trusted-senders = { $count ->
    [one] { $count } αξιόπιστος αποστολέας
   *[other] { $count } αξιόπιστοι αποστολείς
}
# review: new
setup-sign-in-password = Κωδικός πρόσβασης
# review: new
setup-account-secret-password = Ο κωδικός πρόσβασής του βρίσκεται στο αρχείο.
# review: new
setup-account-secret-token = Η σύνδεσή του βρίσκεται στο αρχείο.
# review: new
setup-account-asks-password = Ζητά τον κωδικό πρόσβασής του μετά την εισαγωγή.
# review: new
setup-account-signs-in-again = Συνδέεστε ξανά σε αυτόν μετά την εισαγωγή.
# review: new
setup-account-here = Έχει ήδη ρυθμιστεί εδώ, οπότε παραλείπεται.
# review: new
setup-account-no-app = Συνδέεται με { $app }, που δεν έχει ρυθμιστεί εδώ. Εισαγάγετε και τις εφαρμογές σύνδεσης.
# review: new
setup-invalid-address = Το «{ $address }» δεν είναι διεύθυνση ηλεκτρονικού ταχυδρομείου.
# review: new
setup-invalid-server = Ο διακομιστής { $server } δεν έχει χρησιμοποιήσιμο όνομα ή θύρα.
# review: new
setup-invalid-user = Δεν έχει όνομα χρήστη.
# review: new
setup-invalid-sign-in = Συνδέεται με τρόπο που το Inbox Classic δεν γνωρίζει.
# review: new
setup-error-empty = Το αρχείο είναι κενό.
# review: new
setup-error-too-large = Το αρχείο είναι πολύ μεγάλο για να είναι ρύθμιση του Inbox Classic.
# review: new
setup-error-not-setup = Αυτό το αρχείο δεν είναι ρύθμιση του Inbox Classic.
# review: new
setup-error-damaged = Το αρχείο ρύθμισης είναι κατεστραμμένο και δεν μπορεί να διαβαστεί.
# review: new
setup-error-newer = Αυτή η ρύθμιση αποθηκεύτηκε από νεότερο Inbox Classic ({ $version }). Ενημερώστε το Inbox Classic και εισαγάγετέ τη ξανά.
# review: new
setup-error-needs-passphrase = Αυτή η ρύθμιση προστατεύεται με φράση πρόσβασης. Πληκτρολογήστε τη φράση πρόσβασης με την οποία αποθηκεύτηκε.
# review: new
setup-error-wrong-passphrase = Αυτή δεν είναι η φράση πρόσβασης με την οποία αποθηκεύτηκε αυτή η ρύθμιση.
# review: new
setup-error-changed = Το αρχείο ρύθμισης άλλαξε ή καταστράφηκε μετά την αποθήκευσή του, οπότε δεν μπορεί να εισαχθεί.
# review: new
setup-error-read = Δεν ήταν δυνατή η ανάγνωση του αρχείου ρύθμισης: { $error }
# review: new
setup-error-write = Δεν ήταν δυνατή η αποθήκευση της ρύθμισης: { $error }
# review: new
setup-error-no-parts = Επιλέξτε τουλάχιστον ένα μέρος.
# review: new
setup-left-out = { $count ->
    [one] { $count } καταχώριση του μέρους «{ $part }» δεν μπορεί να χρησιμοποιηθεί και παραλείπεται.
   *[other] { $count } καταχωρίσεις του μέρους «{ $part }» δεν μπορούν να χρησιμοποιηθούν και παραλείπονται.
}
# review: new
setup-imported-settings = Οι ρυθμίσεις αντικαταστάθηκαν.
# review: new
setup-imported-preferences = Οι προτιμήσεις παραθύρων αντικαταστάθηκαν.
# review: new
setup-added-accounts = { $count ->
    [one] Προστέθηκε { $count } λογαριασμός.
   *[other] Προστέθηκαν { $count } λογαριασμοί.
}
# review: new
setup-skipped-here = Ο λογαριασμός { $address } έχει ήδη ρυθμιστεί εδώ, οπότε παραλείφθηκε.
# review: new
setup-skipped-no-app = Ο λογαριασμός { $address } παραλείφθηκε: συνδέεται με { $app }, που δεν έχει ρυθμιστεί εδώ.
# review: new
setup-skipped-invalid = Ο λογαριασμός { $address } παραλείφθηκε: { $reason }
# review: new
setup-asks-password = Ο λογαριασμός { $address } ζητά τον κωδικό πρόσβασής του όταν συνδέεται.
# review: new
setup-signs-in-again = Ο λογαριασμός { $address } σας ζητά να συνδεθείτε ξανά όταν συνδέεται.
# review: new
setup-added-sign-in-apps = { $count ->
    [one] Προστέθηκε { $count } εφαρμογή σύνδεσης.
   *[other] Προστέθηκαν { $count } εφαρμογές σύνδεσης.
}
# review: new
setup-skipped-sign-in-apps = { $count ->
    [one] { $count } εφαρμογή σύνδεσης έχει ήδη ρυθμιστεί εδώ.
   *[other] { $count } εφαρμογές σύνδεσης έχουν ήδη ρυθμιστεί εδώ.
}
# review: new
setup-added-contacts = { $count ->
    [one] Προστέθηκε { $count } επαφή στο βιβλίο διευθύνσεων.
   *[other] Προστέθηκαν { $count } επαφές στο βιβλίο διευθύνσεων.
}
# review: new
setup-skipped-contacts = { $count ->
    [one] { $count } επαφή υπάρχει ήδη στο βιβλίο διευθύνσεων.
   *[other] { $count } επαφές υπάρχουν ήδη στο βιβλίο διευθύνσεων.
}
# review: new
setup-added-groups = { $count ->
    [one] Προστέθηκε ή συμπληρώθηκε { $count } ομάδα.
   *[other] Προστέθηκαν ή συμπληρώθηκαν { $count } ομάδες.
}
# review: new
setup-added-own-keys = { $count ->
    [one] Προστέθηκε { $count } δικό σας κλειδί.
   *[other] Προστέθηκαν { $count } δικά σας κλειδιά.
}
# review: new
setup-added-contact-keys = { $count ->
    [one] Προστέθηκε { $count } κλειδί επαφής.
   *[other] Προστέθηκαν { $count } κλειδιά επαφών.
}
# review: new
setup-added-rules = { $count ->
    [one] Προστέθηκε { $count } κανόνας μηνυμάτων.
   *[other] Προστέθηκαν { $count } κανόνες μηνυμάτων.
}
# review: new
setup-skipped-rules = { $count ->
    [one] { $count } κανόνας μηνυμάτων υπάρχει ήδη εδώ.
   *[other] { $count } κανόνες μηνυμάτων υπάρχουν ήδη εδώ.
}
# review: new
setup-skipped-rules-account = { $count ->
    [one] { $count } κανόνας μηνυμάτων αφορά λογαριασμό που δεν υπάρχει εδώ, οπότε παραλείφθηκε.
   *[other] { $count } κανόνες μηνυμάτων αφορούν λογαριασμούς που δεν υπάρχουν εδώ, οπότε παραλείφθηκαν.
}
# review: new
setup-rules-waiting = { $count ->
    [one] { $count } κανόνας μηνυμάτων μετακινεί μηνύματα σε φάκελο που θα εμφανιστεί μόλις συγχρονιστεί ο λογαριασμός του.
   *[other] { $count } κανόνες μηνυμάτων μετακινούν μηνύματα σε φακέλους που θα εμφανιστούν μόλις συγχρονιστούν οι λογαριασμοί τους.
}
# review: new
setup-added-trusted-senders = { $count ->
    [one] Προστέθηκε { $count } αξιόπιστος αποστολέας.
   *[other] Προστέθηκαν { $count } αξιόπιστοι αποστολείς.
}
# review: new
setup-nothing = Δεν εισήχθη τίποτα.
# review: new
setup-account-servers = { $imap } και { $smtp } ({ $signin })
# review: new
setup-file-name = Ρυθμίσεις και λογαριασμοί Inbox Classic
# review: new
setup-skipped-unreachable = Η εφαρμογή σύνδεσης { $name } παραλείφθηκε: η υπηρεσία σύνδεσής του δεν ήταν προσβάσιμη. Προσθέστε το ξανά στις Εφαρμογές σύνδεσης.
# review: new
attachment-runs-programs = Το αρχείο «{ $name }» μπορεί να εκτελέσει προγράμματα, γι’ αυτό το Inbox Classic δεν το ανοίγει. Αποθηκεύστε το και ανοίξτε το μόνοι σας, αν εμπιστεύεστε την προέλευσή του.
# review: new
attachment-decrypted-note = Αυτό το συνημμένο προέρχεται από κρυπτογραφημένο μήνυμα. Για να το ανοίξει, το Inbox Classic το αποθηκεύει αποκρυπτογραφημένο σε αυτόν τον υπολογιστή, σε έναν φάκελό σας που το Inbox Classic αδειάζει μετά από μία ημέρα.
# a bar over the list when the server did not do what the user asked of messages, so they are as they were again
# review: new
undone-move = { $count ->
    [one] Ο διακομιστής δεν μετακίνησε { $messages } στον φάκελο «{ $folder }», οπότε βρίσκεται ξανά στον φάκελο «{ $from }»: { $reason }
   *[other] Ο διακομιστής δεν μετακίνησε { $messages } στον φάκελο «{ $folder }», οπότε βρίσκονται ξανά στον φάκελο «{ $from }»: { $reason }
}
# review: new
undone-delete = { $count ->
    [one] Ο διακομιστής δεν διέγραψε { $messages }, οπότε βρίσκεται ξανά στον φάκελο «{ $from }»: { $reason }
   *[other] Ο διακομιστής δεν διέγραψε { $messages }, οπότε βρίσκονται ξανά στον φάκελο «{ $from }»: { $reason }
}
# review: new
undone-archive = { $count ->
    [one] Ο διακομιστής δεν αρχειοθέτησε { $messages }, οπότε βρίσκεται ξανά στον φάκελο «{ $from }»: { $reason }
   *[other] Ο διακομιστής δεν αρχειοθέτησε { $messages }, οπότε βρίσκονται ξανά στον φάκελο «{ $from }»: { $reason }
}
# review: new
undone-read = { $count ->
    [one] Ο διακομιστής δεν επισήμανε { $messages } ως αναγνωσμένο, οπότε είναι ξανά αδιάβαστο: { $reason }
   *[other] Ο διακομιστής δεν επισήμανε { $messages } ως αναγνωσμένα, οπότε είναι ξανά αδιάβαστα: { $reason }
}
# review: new
undone-unread = { $count ->
    [one] Ο διακομιστής δεν επισήμανε { $messages } ως αδιάβαστο, οπότε είναι ξανά αναγνωσμένο: { $reason }
   *[other] Ο διακομιστής δεν επισήμανε { $messages } ως αδιάβαστα, οπότε είναι ξανά αναγνωσμένα: { $reason }
}
# review: new
undone-flags = { $count ->
    [one] Ο διακομιστής δεν άλλαξε τις σημαίες για { $messages }, οπότε παραμένει όπως ήταν: { $reason }
   *[other] Ο διακομιστής δεν άλλαξε τις σημαίες για { $messages }, οπότε παραμένουν όπως ήταν: { $reason }
}
