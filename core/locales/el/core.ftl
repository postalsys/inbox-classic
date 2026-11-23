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
list-separator = { ", " }
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
    }, { $selected ->
    [one] { $selected } επιλεγμένο
   *[other] { $selected } επιλεγμένα
}
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
reader-failed-network = Δεν ήταν δυνατή η σύνδεση με τον διακομιστή αλληλογραφίας ή η σύνδεση διακόπηκε ({ $reason }).
reader-failed-sign-in = Ο διακομιστής αλληλογραφίας δεν δέχτηκε τη σύνδεση ({ $reason }). Ελέγξτε τον κωδικό πρόσβασης ή συνδεθείτε ξανά από τις ρυθμίσεις του λογαριασμού.
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
bounce-virus-detected-why = Ο διακομιστής του παραλήπτη αναφέρει ότι βρήκε ιό ή άλλο επιβλαβές περιεχόμενο στο μήνυμα ή στα συνημμένα του.
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
bounce-relay-denied-do = Στις ρυθμίσεις του λογαριασμού, ελέγξτε τον διακομιστή εξερχομένων και τα στοιχεία σύνδεσης σε αυτόν.
bounce-auth-failure = Δεν ήταν δυνατή η επαλήθευση της διεύθυνσης αποστολέα σας
bounce-auth-failure-why = Ο διακομιστής του παραλήπτη δεν μπόρεσε να επιβεβαιώσει ότι το μήνυμα προήλθε πράγματι από τον τομέα σας (SPF, DKIM ή DMARC).
bounce-auth-failure-do = Προωθήστε αυτή την ειδοποίηση σε όποιον διαχειρίζεται την αλληλογραφία του τομέα σας: οι ρυθμίσεις του χρειάζονται διόρθωση. Στο μεταξύ, μπορεί να βοηθήσει η αποστολή μέσω του διακομιστή του παρόχου σας.
bounce-rate-limited = Πάρα πολλή αλληλογραφία ταυτόχρονα
bounce-rate-limited-why = Ο διακομιστής του παραλήπτη δέχεται προς το παρόν λιγότερα μηνύματα από τον διακομιστή αλληλογραφίας σας.
bounce-rate-limited-do = Περιμένετε λίγο και στείλτε το ξανά. Όταν γράφετε σε πολλούς, στέλνετε σε λιγότερους κάθε φορά.
bounce-greylisting = Προσωρινή αναβολή παράδοσης
bounce-greylisting-why = Ο διακομιστής του παραλήπτη ζητά από άγνωστους αποστολείς να δοκιμάσουν ξανά λίγο αργότερα. Πρόκειται για συνηθισμένο μέτρο κατά της ανεπιθύμητης αλληλογραφίας.
bounce-greylisting-do = Αν ο διακομιστής συνεχίζει τις προσπάθειες παράδοσης, περιμένετε. Αν τις έχει σταματήσει, δοκιμάστε να στείλετε ξανά το μήνυμα αργότερα.
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
    [one] Το { $messages } μπήκε στην ουρά για εισαγωγή στον φάκελο «{ $folder }»
   *[other] Τα { $messages } μπήκαν στην ουρά για εισαγωγή στον φάκελο «{ $folder }»
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

sign-in-off-google = Η ενσωματωμένη εφαρμογή σύνδεσης Google προορίζεται για περιορισμένη χρήση, όπως για χρήστες δοκιμών, και είναι αρχικά απενεργοποιημένη. Χρησιμοποιήστε δική σας εφαρμογή σύνδεσης ή κωδικό πρόσβασης εφαρμογής, αν το επιτρέπει ο λογαριασμός σας. Μπορείτε να την ενεργοποιήσετε στις Εφαρμογές σύνδεσης (Αρχείο > Λογαριασμοί).
sign-in-off-other = Απενεργοποιήθηκε στις Εφαρμογές σύνδεσης (Αρχείο > Λογαριασμοί), όπου μπορεί να ενεργοποιηθεί ξανά.
sign-in-app-no-name = η εφαρμογή σύνδεσης χρειάζεται όνομα
sign-in-app-no-client = λείπει το αναγνωριστικό πελάτη
sign-in-app-no-scopes = η εφαρμογή σύνδεσης χρειάζεται τα δικαιώματα (scopes) που δίνουν πρόσβαση στην αλληλογραφία
sign-in-app-bad-host = ο διακομιστής { $server } δεν έχει έγκυρη διεύθυνση ή θύρα
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

agent-level-read = Ανάγνωση αλληλογραφίας: φάκελοι, λίστες μηνυμάτων, συζητήσεις, αναζήτηση, μηνύματα και συνημμένα, κανόνες μηνυμάτων και αναζήτηση ατόμων με τα οποία αλληλογραφείτε
agent-level-organize = Οργάνωση αλληλογραφίας: αλλαγή κατάστασης ανάγνωσης, σημαιών και των χρωμάτων τους, διαχείριση ανεπιθύμητης αλληλογραφίας, μετακίνηση και αρχειοθέτηση μηνυμάτων, δημιουργία και μετονομασία φακέλων, παρακολούθηση και αγνόηση συζητήσεων, διαγραφή με μετακίνηση στον φάκελο Διαγραμμένα και κατάργηση εγγραφής από λίστες αλληλογραφίας με την έγκρισή σας
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
agent-undo-sent = το μήνυμα δεν βρίσκεται πλέον στα Εξερχόμενα
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
agent-encrypted = Αυτό το μήνυμα είναι κρυπτογραφημένο. Οι πράκτορες ΤΝ δεν μπορούν να διαβάσουν το περιεχόμενό του. Ο χρήστης πρέπει να το ανοίξει στο Inbox Classic.
agent-too-many-changes = Συμπληρώθηκε το όριο καταγεγραμμένων αλλαγών των τελευταίων 30 ημερών για αυτό το πρόγραμμα. Ο πράκτορας θα μπορεί να κάνει νέες αλλαγές όταν οι παλαιότερες καταγραφές ξεπεράσουν τις 30 ημέρες.
agent-too-many-reads = Συμπληρώθηκε το όριο καταγεγραμμένων αναγνώσεων των τελευταίων 30 ημερών για αυτό το πρόγραμμα. Ο πράκτορας θα μπορεί να διαβάσει ξανά όταν οι παλαιότερες καταγραφές ξεπεράσουν τις 30 ημέρες.
list-encrypted = Κρυπτογραφημένο μήνυμα
agent-log-composed = Άνοιξε το «{ $subject }» σε νέο μήνυμα για να το ολοκληρώσετε
agent-log-refused = Δεν στείλατε το «{ $subject }»
agent-log-sent = Το μήνυμα «{ $subject }» τέθηκε σε αναμονή για αποστολή προς { $to }
agent-log-draft = Αποθηκεύτηκε το πρόχειρο «{ $subject }»
agent-log-draft-replaced = Αντικαταστάθηκε το πρόχειρο «{ $subject }»
agent-log-draft-discarded = Ζητήθηκε η οριστική διαγραφή του πρόχειρου «{ $subject }»
agent-draft-note = Ο πράκτορας ΤΝ { $program } έγραψε αυτό το πρόχειρο. Ελέγξτε τους παραλήπτες και το κείμενο πριν το στείλετε.
agent-log-read = Επισημάνθηκε ως αναγνωσμένο το «{ $subject }»
agent-log-unread = Επισημάνθηκε ως αδιάβαστο το «{ $subject }»
agent-log-flagged = Προστέθηκε σημαία στο «{ $subject }»
agent-log-unflagged = Αφαιρέθηκε η σημαία από το «{ $subject }»
agent-log-deleted = Διαγράφηκε το «{ $subject }»
agent-log-moved = Μετακινήθηκε το «{ $subject }» στον φάκελο «{ $folder }»
agent-log-junk = Επισημάνθηκε ως ανεπιθύμητο το «{ $subject }»
agent-log-not-junk = Επισημάνθηκε ως μη ανεπιθύμητο το «{ $subject }»
agent-log-archived = Αρχειοθετήθηκε το «{ $subject }»
agent-log-folder = Ζητήθηκε η δημιουργία του φακέλου «{ $name }»
agent-log-unsubscribed = Εγκρίνατε το αίτημα κατάργησης εγγραφής. Μήνυμα: «{ $subject }»
agent-log-unsubscribe-failed = Η κατάργηση εγγραφής απέτυχε. Μήνυμα: «{ $subject }». Αιτία: { $reason }
agent-log-unsubscribe-refused = Δεν εγκρίνατε την κατάργηση εγγραφής. Αποστολείς: { $senders }
agent-unsubscribe-title = { $count ->
    [one] Το πρόγραμμα { $program } θέλει να καταργήσει την εγγραφή σας από μια λίστα αλληλογραφίας
   *[other] Το πρόγραμμα { $program } θέλει να καταργήσει την εγγραφή σας από { $count } λίστες αλληλογραφίας
}
agent-unsubscribe-detail = { $count ->
    [1] Το Inbox Classic ζητά από την παρακάτω λίστα να σταματήσει να σας στέλνει μηνύματα. Χρησιμοποιεί τη δυνατότητα κατάργησης εγγραφής με ένα κλικ που προσφέρει η λίστα. Δεν αποστέλλεται τίποτε άλλο. Τα υπάρχοντα μηνύματα δεν αλλάζουν ούτε μετακινούνται.
   *[other] Το Inbox Classic ζητά από κάθε λίστα παρακάτω να σταματήσει να σας στέλνει μηνύματα. Χρησιμοποιεί τη δυνατότητα κατάργησης εγγραφής με ένα κλικ που προσφέρει κάθε λίστα. Δεν αποστέλλεται τίποτε άλλο. Τα υπάρχοντα μηνύματα δεν αλλάζουν ούτε μετακινούνται.
}
agent-log-flag-color = Προστέθηκε σημαία στο «{ $subject }», χρώμα: { $color ->
    [red] κόκκινο
    [orange] πορτοκαλί
    [yellow] κίτρινο
    [green] πράσινο
    [blue] μπλε
    [purple] μωβ
   *[gray] γκρι
}
agent-log-renamed = Ζητήθηκε η μετονομασία του φακέλου «{ $old }» σε «{ $name }»
agent-log-watched = Ξεκίνησε η παρακολούθηση της συζήτησης «{ $subject }»
agent-log-ignored = Αγνοήθηκε η συζήτηση «{ $subject }»
agent-log-unmarked = Σταμάτησε η παρακολούθηση ή η αγνόηση της συζήτησης «{ $subject }»
# the reason one change can not be taken back (agent-undo-refused-why)
agent-undo-changed = το μήνυμα άλλαξε στο μεταξύ
# one change of many messages an agent made with a search (apply_to_search), a row of the log; { $query } is the search
agent-log-bulk-read = { $count ->
    [one] Επισημάνθηκε ως αναγνωσμένο 1 μήνυμα (αναζήτηση: { $query })
   *[other] Επισημάνθηκαν ως αναγνωσμένα { $count } μηνύματα (αναζήτηση: { $query })
}
agent-log-bulk-unread = { $count ->
    [one] Επισημάνθηκε ως αδιάβαστο 1 μήνυμα (αναζήτηση: { $query })
   *[other] Επισημάνθηκαν ως αδιάβαστα { $count } μηνύματα (αναζήτηση: { $query })
}
agent-log-bulk-flagged = { $count ->
    [one] Προστέθηκε σημαία σε 1 μήνυμα (αναζήτηση: { $query })
   *[other] Προστέθηκε σημαία σε { $count } μηνύματα (αναζήτηση: { $query })
}
agent-log-bulk-unflagged = { $count ->
    [one] Αφαιρέθηκε η σημαία από 1 μήνυμα (αναζήτηση: { $query })
   *[other] Αφαιρέθηκε η σημαία από { $count } μηνύματα (αναζήτηση: { $query })
}
agent-log-bulk-color = Προστέθηκε σημαία σε { $count ->
    [one] 1 μήνυμα
   *[other] { $count } μηνύματα
}, χρώμα: { $color ->
    [red] κόκκινο
    [orange] πορτοκαλί
    [yellow] κίτρινο
    [green] πράσινο
    [blue] μπλε
    [purple] μωβ
   *[gray] γκρι
} (αναζήτηση: { $query })
agent-log-bulk-moved = { $count ->
    [one] Μετακινήθηκε 1 μήνυμα στον φάκελο «{ $folder }» (αναζήτηση: { $query })
   *[other] Μετακινήθηκαν { $count } μηνύματα στον φάκελο «{ $folder }» (αναζήτηση: { $query })
}
agent-log-bulk-archived = { $count ->
    [one] Αρχειοθετήθηκε 1 μήνυμα (αναζήτηση: { $query })
   *[other] Αρχειοθετήθηκαν { $count } μηνύματα (αναζήτηση: { $query })
}
agent-log-bulk-junk = { $count ->
    [one] Επισημάνθηκε ως ανεπιθύμητο 1 μήνυμα (αναζήτηση: { $query })
   *[other] Επισημάνθηκαν ως ανεπιθύμητα { $count } μηνύματα (αναζήτηση: { $query })
}
agent-log-bulk-not-junk = { $count ->
    [one] Επισημάνθηκε ως μη ανεπιθύμητο 1 μήνυμα (αναζήτηση: { $query })
   *[other] Επισημάνθηκαν ως μη ανεπιθύμητα { $count } μηνύματα (αναζήτηση: { $query })
}
agent-log-bulk-deleted = { $count ->
    [one] Διαγράφηκε 1 μήνυμα (αναζήτηση: { $query })
   *[other] Διαγράφηκαν { $count } μηνύματα (αναζήτηση: { $query })
}
# Undo Everything Since in the AI Agents window: how far back it reaches
agent-undo-span = { $span ->
    [quarter] Τα τελευταία 15 λεπτά
    [hour] Την τελευταία ώρα
    [hours] Τις τελευταίες 4 ώρες
    [day] Τις τελευταίες 24 ώρες
    [week] Τις τελευταίες 7 ημέρες
   *[all] Τις τελευταίες 30 ημέρες
}
# the question before it takes back what a program did in the span chosen
agent-undo-since-question = { $count ->
    [0] Το πρόγραμμα { $program } δεν έκανε σε αυτό το διάστημα αλλαγές που μπορούν να αναιρεθούν.
    [one] Να αναιρεθεί η αλλαγή που έκανε το πρόγραμμα { $program } σε αυτό το διάστημα;
   *[other] Να αναιρεθούν οι { $count } αλλαγές που έκανε το πρόγραμμα { $program } σε αυτό το διάστημα;
}
agent-undo-since-detail = Γίνεται προσπάθεια επαναφοράς των μηνυμάτων στους προηγούμενους φακέλους και της κατάστασης ανάγνωσης και των σημαιών στις προηγούμενες τιμές τους. Μηνύματα που περιμένουν ακόμη στα Εξερχόμενα διαγράφονται. Κάθε αναίρεση ελέγχει τις σχετικές με την ενέργεια αλλαγές· δεν διατηρούνται απαραίτητα όλες οι μεταγενέστερες αλλαγές.
# what taking back did, then a line for each kind of message it left as it is
agent-undo-done = { $count ->
    [0] Δεν αναιρέθηκε τίποτα.
    [one] Αναιρέθηκε 1 αλλαγή, πλήρως ή εν μέρει.
   *[other] Αναιρέθηκαν { $count } αλλαγές, πλήρως ή εν μέρει.
}
agent-undo-left-gone = { $count ->
    [one] 1 μήνυμα δεν βρισκόταν πλέον στην αναμενόμενη θέση.
   *[other] { $count } μηνύματα δεν βρίσκονταν πλέον στην αναμενόμενη θέση.
}
agent-undo-left-changed = { $count ->
    [one] 1 μήνυμα άλλαξε στο μεταξύ, από εσάς ή στον διακομιστή, και έμεινε ως έχει.
   *[other] { $count } μηνύματα άλλαξαν στο μεταξύ, από εσάς ή στον διακομιστή, και έμειναν ως έχουν.
}
agent-undo-left-sent = { $count ->
    [one] 1 μήνυμα είχε ήδη φύγει από τα Εξερχόμενα.
   *[other] { $count } μηνύματα είχαν ήδη φύγει από τα Εξερχόμενα.
}
agent-undo-left-impossible = { $count ->
    [one] 1 αλλαγή δεν μπορεί να αναιρεθεί.
   *[other] { $count } αλλαγές δεν μπορούν να αναιρεθούν.
}
# the Send question of an agent's answer to a calendar invitation: what it answers, and when the event is
agent-invitation-reply = { $response ->
    [accept] Αυτό το μήνυμα αποδέχεται την πρόσκληση «{ $summary }» ({ $when }).
    [tentative] Αυτό το μήνυμα αποδέχεται με επιφύλαξη την πρόσκληση «{ $summary }» ({ $when }).
   *[decline] Αυτό το μήνυμα απορρίπτει την πρόσκληση «{ $summary }» ({ $when }).
} Το μήνυμα περιέχει απάντηση για το ημερολόγιο του διοργανωτή. Η τοπική κατάσταση της πρόσκλησης ενημερώνεται αφού ο διακομιστής δεχτεί το μήνυμα για αποστολή. Αυτό δεν επιβεβαιώνει ότι ο διοργανωτής επεξεργάστηκε την απάντηση.
# the subject of an answer to an invitation, as calendar programs write it
invitation-reply-subject = { $response ->
    [accept] Αποδοχή: { $summary }
    [tentative] Αποδοχή με επιφύλαξη: { $summary }
   *[decline] Απόρριψη: { $summary }
}
# the text of an answer to an invitation; { $name } is the user's name, or address
invitation-reply-text = { $response ->
    [accept] { $name } αποδέχτηκε αυτήν την πρόσκληση.
    [tentative] { $name } αποδέχτηκε με επιφύλαξη αυτήν την πρόσκληση.
   *[decline] { $name } απέρριψε αυτήν την πρόσκληση.
}
# what a program read in an hour, a row of the log: "Read 14 messages and searched 3 times" (joined by agent-can-list)
agent-reads-messages = { $count ->
    [one] διάβασε 1 μήνυμα
   *[other] διάβασε { $count } μηνύματα
}
agent-reads-attachments = { $count ->
    [one] ζήτησε 1 συνημμένο
   *[other] ζήτησε { $count } συνημμένα
}
agent-reads-searches = { $count ->
    [one] έκανε αναζήτηση μία φορά
   *[other] έκανε αναζήτηση { $count } φορές
}
agent-reads-lists = { $count ->
    [one] είδε μια λίστα μηνυμάτων μία φορά
   *[other] είδε λίστες μηνυμάτων { $count } φορές
}
# each read under that row
agent-read-message = Διάβασε το «{ $subject }»
agent-read-conversation = { $count ->
    [one] Διάβασε τη συζήτηση «{ $subject }» (1 μήνυμα)
   *[other] Διάβασε τη συζήτηση «{ $subject }» ({ $count } μηνύματα)
}
agent-read-attachment = Ζήτησε το συνημμένο «{ $name }» του μηνύματος «{ $subject }»
agent-read-search = { $count ->
    [one] Αναζήτησε «{ $query }»: 1 μήνυμα
   *[other] Αναζήτησε «{ $query }»: { $count } μηνύματα
}
agent-read-people = Αναζήτησε άτομα με βάση το όνομα ή τη διεύθυνση: «{ $query }»
agent-read-list = { $count ->
    [one] Είδε 1 καταχώριση στη λίστα: { $folder }
   *[other] Είδε { $count } καταχωρίσεις στη λίστα: { $folder }
}
agent-read-changes = { $count ->
    [one] Είδε στοιχεία για 1 νέο μήνυμα
   *[other] Είδε στοιχεία για { $count } νέα μηνύματα
}
# the programs started from a terminal app, which share one access: in the list of programs and the question when one connects
agent-terminal-programs-mac = Προγράμματα που εκκινούνται από το { $terminal }
agent-terminal-programs-windows = Προγράμματα που εκκινούνται από τερματικό ({ $terminal })
agent-terminal-programs-linux = Προγράμματα που εκκινούνται από τερματικό ({ $terminal })
# one of them, as the questions to send or unsubscribe name it. In Greek a relative clause, as those sentences put
# "Το πρόγραμμα" before { $program }: "Το πρόγραμμα που εκκινήθηκε από το Terminal θέλει να στείλει αυτό το μήνυμα"
agent-terminal-program-mac = που εκκινήθηκε από το { $terminal }
agent-terminal-program-windows = που εκκινήθηκε από τερματικό ({ $terminal })
agent-terminal-program-linux = που εκκινήθηκε από τερματικό ({ $terminal })
agent-connect-title-terminal = { $programs } ζητούν πρόσβαση στην αλληλογραφία σας
agent-connect-terminal-detail = Οι πράκτορες ΤΝ που ξεκινούν από το ίδιο αναγνωρισμένο πρόγραμμα τερματικού μοιράζονται την πρόσβαση που επιτρέπετε εδώ. Για ξεχωριστή πρόσβαση, προσθέστε --name και ένα όνομα στα ορίσματα των ρυθμίσεων MCP του πράκτορα. Το όνομα δεν επιβεβαιώνει την ταυτότητα του προγράμματος.
agent-connect-claimed = Το πρόγραμμα δήλωσε ότι είναι το { $claimed }. Το Inbox Classic έλεγξε ποιο πρόγραμμα το ξεκίνησε: { $program }.

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
pgp-key-locked = Το ιδιωτικό κλειδί δεν μπορεί να ανοίξει. Ελέγξτε την πρόσβαση στην υπηρεσία αποθήκευσης ({ $store }). Αν λείπει το κλειδί προστασίας, εισαγάγετε ξανά αντίγραφο ασφαλείας του ιδιωτικού κλειδιού.
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
pgp-error-unusable = Το κλειδί δεν μπορεί να χρησιμοποιηθεί. Μπορεί να λείπει κατάλληλο κλειδί υπογραφής ή κρυπτογράφησης ή να χρησιμοποιείται μη υποστηριζόμενη κρυπτογραφία.
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
pgp-part-changed = Ο έλεγχος ακεραιότητας του κρυπτογραφημένου τμήματος απέτυχε και το τμήμα δεν εμφανίζεται
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
pgp-why-not-key-in-use = Υπογράφηκε με διαφορετικό κλειδί από αυτό που χρησιμοποιείται για τη διεύθυνση { $address }
pgp-part-pictures-loaded = { $label }. Φορτώθηκαν εικόνες από το διαδίκτυο
pgp-error-no-own-key = Δεν έχετε κλειδί για υπογραφή ή κρυπτογράφηση με τη διεύθυνση { $address }. Δημιουργήστε ένα από το Εργαλεία > Κλειδιά κρυπτογράφησης ή απενεργοποιήστε τις επιλογές Υπογραφή και Κρυπτογράφηση.
pgp-error-missing-keys = { $count ->
    [one] Δεν υπάρχει κατάλληλο κλειδί κρυπτογράφησης για τον παραλήπτη: { $addresses }.
   *[other] Δεν υπάρχουν κατάλληλα κλειδιά κρυπτογράφησης για τους παραλήπτες: { $addresses }.
}
pgp-error-encrypted-quote = Το μήνυμα περιέχει κείμενο, εικόνες ή συνημμένα από κρυπτογραφημένο μήνυμα και μπορεί να σταλεί μόνο κρυπτογραφημένο. Ενεργοποιήστε την Κρυπτογράφηση ή αφαιρέστε όλο αυτό το περιεχόμενο.
pgp-error-protect = Δεν ήταν δυνατή η υπογραφή ή η κρυπτογράφηση του μηνύματος: { $reason }
pgp-found-keys = Βρέθηκαν κλειδιά για: { $addresses }.
pgp-found-none = Δεν βρέθηκε κλειδί για { $addresses }. Ζητήστε τους να σας στείλουν το δημόσιο κλειδί τους.
pgp-found-no-key = Δεν βρέθηκε κλειδί.
pgp-find-unavailable = Δεν ήταν δυνατή η αναζήτηση κλειδιών τώρα: { $error }
pgp-publish-pending = Το keys.openpgp.org έστειλε συνδέσμους επιβεβαίωσης στις διευθύνσεις: { $addresses }. Επιβεβαιώστε κάθε διεύθυνση ξεχωριστά, ώστε το κλειδί σας να μπορεί να βρεθεί μέσω αυτής.
pgp-publish-done = Το κλειδί σας δημοσιεύτηκε στο keys.openpgp.org για { $addresses }.
pgp-publish-failed = Δεν ήταν δυνατή η δημοσίευση του κλειδιού: { $error }
pgp-keyserver-off = Η αναζήτηση κλειδιών στο keys.openpgp.org είναι απενεργοποιημένη στην ενότητα { $settings }.
# the compose window with Sign and Encrypt: the line under the fields, each recipient's key, the questions
pgp-compose-encrypted = { $count ->
    [one] Θα κρυπτογραφηθεί και θα υπογραφεί κατά την αποστολή. Μόνο εσείς και ο παραλήπτης ({ $addresses }) θα μπορείτε να διαβάσετε το περιεχόμενο.
   *[other] Θα κρυπτογραφηθεί και θα υπογραφεί κατά την αποστολή. Μόνο εσείς και οι { $count } παραλήπτες θα μπορείτε να διαβάσετε το περιεχόμενο.
}
pgp-compose-encrypt-ready = Θα κρυπτογραφηθεί και θα υπογραφεί κατά την αποστολή. Προσθέστε παραλήπτες για τους οποίους έχετε κατάλληλα κλειδιά.
pgp-compose-missing = { $count ->
    [one] Το μήνυμα δεν μπορεί ακόμη να κρυπτογραφηθεί: λείπει κατάλληλο κλειδί για τον παραλήπτη ({ $addresses }).
   *[other] Το μήνυμα δεν μπορεί ακόμη να κρυπτογραφηθεί: λείπουν κατάλληλα κλειδιά για { $count } παραλήπτες ({ $addresses }).
}
pgp-compose-looking = Αναζήτηση κλειδιών: { $addresses }...
pgp-compose-signed = Το μήνυμα θα υπογραφεί ψηφιακά κατά την αποστολή. Οι παραλήπτες θα μπορούν να ελέγξουν την υπογραφή και αν το περιεχόμενο έχει αλλάξει.
pgp-compose-reply-clear = Η κρυπτογράφηση είναι ανενεργή, παρότι το αρχικό μήνυμα ήταν κρυπτογραφημένο.
pgp-compose-encrypted-files = Το μήνυμα περιέχει συνημμένα από κρυπτογραφημένο μήνυμα και μπορεί να σταλεί μόνο με κρυπτογράφηση. Ενεργοποιήστε την επιλογή «Κρυπτογράφηση» ή αφαιρέστε αυτά τα συνημμένα.
pgp-compose-sign-tip = Ψηφιακή υπογραφή κατά την αποστολή, ώστε οι παραλήπτες να μπορούν να ελέγξουν την υπογραφή και αν το περιεχόμενο έχει αλλάξει
pgp-compose-sign-tip-encrypted = Τα κρυπτογραφημένα μηνύματα υπογράφονται πάντα κατά την αποστολή
pgp-compose-encrypt-tip = Κρυπτογράφηση του περιεχομένου κατά την αποστολή, ώστε να μπορείτε να το διαβάσετε μόνο εσείς και οι παραλήπτες
pgp-compose-make-key = Δεν έχετε ακόμη κλειδί για τη διεύθυνση { $address }. Θέλετε να δημιουργήσετε ένα τώρα; Με αυτό θα μπορείτε να υπογράφετε και να κρυπτογραφείτε μηνύματα.
pgp-compose-key-unusable = Το κλειδί σας για τη διεύθυνση { $address } δεν μπορεί να χρησιμοποιηθεί. Αιτία: { $state }
    Αν η ασφαλής αποθήκευση είναι κλειδωμένη ή μη διαθέσιμη, ελέγξτε πρώτα την πρόσβαση. Διαφορετικά, ανοίξτε το παράθυρο «Κλειδιά κρυπτογράφησης» για να εισαγάγετε ένα αντίγραφο ασφαλείας αυτού του κλειδιού ή να δημιουργήσετε νέο.
pgp-compose-encrypt-off-quote = Το μήνυμα περιέχει ακόμη κείμενο, εικόνες ή συνημμένα από κρυπτογραφημένο μήνυμα. Αφαιρέστε τα πριν το στείλετε χωρίς κρυπτογράφηση. Να απενεργοποιηθεί παρ’ όλα αυτά η κρυπτογράφηση;
pgp-compose-encrypt-off-reply = Το αρχικό μήνυμα ήταν κρυπτογραφημένο. Αν στείλετε την απάντηση ή το προωθημένο μήνυμα χωρίς κρυπτογράφηση, οι διακομιστές αλληλογραφίας θα μπορούν να διαβάσουν το περιεχόμενο. Να απενεργοποιηθεί η κρυπτογράφηση;
pgp-recipient-verified = Επαληθευμένο κλειδί
pgp-recipient-found = Μη επαληθευμένο κλειδί
pgp-recipient-own = Το δικό σας κλειδί
pgp-recipient-looking = Αναζήτηση κλειδιού...
pgp-recipient-missing = Χωρίς κλειδί
pgp-recipient-not-found = Δεν βρέθηκε κλειδί. Τελευταία αναζήτηση: { $date }
pgp-recipient-unusable = Το κλειδί δεν μπορεί να χρησιμοποιηθεί: { $state }
pgp-recipients-intro = Το μήνυμα θα κρυπτογραφηθεί με τα κλειδιά των παραληπτών και το δικό σας.
pgp-recipients-intro-missing = { $count ->
    [one] Δεν υπάρχει κατάλληλο κλειδί για έναν παραλήπτη. Βρείτε το κλειδί του ή αφαιρέστε τον από το μήνυμα. Η αποστολή χωρίς κρυπτογράφηση επιτρέπεται μόνο αν το μήνυμα δεν περιέχει κείμενο, εικόνες ή συνημμένα από κρυπτογραφημένα μηνύματα.
   *[other] Δεν υπάρχουν κατάλληλα κλειδιά για { $count } παραλήπτες. Βρείτε τα κλειδιά τους ή αφαιρέστε τους από το μήνυμα. Η αποστολή χωρίς κρυπτογράφηση επιτρέπεται μόνο αν το μήνυμα δεν περιέχει κείμενο, εικόνες ή συνημμένα από κρυπτογραφημένα μηνύματα.
}
pgp-details-part = Τμήμα { $number }: { $label }
attachment-from-part = Από το τμήμα { $number }: { $label }
pgp-details-signed = Υπογράφηκε { $when } με το κλειδί { $key }
pgp-details-unknown-key = Υπογράφηκε με το κλειδί { $key }, που δεν έχετε
pgp-details-opened = Αποκρυπτογραφήθηκε με το κλειδί σας { $key }
pgp-details-for = Κρυπτογραφημένο για { $keys }
pgp-details-plain = Χωρίς υπογραφή και χωρίς κρυπτογράφηση
pgp-bar-parts = Αυτό το μήνυμα έχει { $count } τμήματα: { $list }. Κάθε τμήμα δείχνει πώς προστατεύεται.
pgp-bar-count-verified = { $count } με επαληθευμένο κάτοχο κλειδιού
pgp-bar-count-encrypted-signed = { $count ->
    [one] { $count } κρυπτογραφημένο και υπογεγραμμένο
   *[other] { $count } κρυπτογραφημένα και υπογεγραμμένα
}
pgp-bar-count-encrypted = { $count ->
    [one] { $count } κρυπτογραφημένο
   *[other] { $count } κρυπτογραφημένα
}
pgp-bar-count-signed = { $count ->
    [one] { $count } υπογεγραμμένο
   *[other] { $count } υπογεγραμμένα
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
setup-invalid-server = Οι ρυθμίσεις για { $server } έχουν μη έγκυρο όνομα διακομιστή, θύρα ή επιλογή ασφάλειας.
setup-invalid-user = Δεν έχει οριστεί όνομα χρήστη.
setup-invalid-sign-in = Ο τρόπος σύνδεσης ή οι ρυθμίσεις του δεν υποστηρίζονται από το Inbox Classic.
setup-error-empty = Το αρχείο είναι κενό.
setup-error-too-large = Το αρχείο είναι πολύ μεγάλο για εισαγωγή ρυθμίσεων και λογαριασμών στο Inbox Classic.
setup-error-not-setup = Αυτό δεν είναι αρχείο ρυθμίσεων και λογαριασμών του Inbox Classic.
setup-error-damaged = Το αρχείο ρυθμίσεων είναι κατεστραμμένο και δεν μπορεί να διαβαστεί.
setup-error-newer = Αυτό το αρχείο ρυθμίσεων αποθηκεύτηκε από νεότερη έκδοση του Inbox Classic ({ $version }). Ενημερώστε το πρόγραμμα και δοκιμάστε ξανά την εισαγωγή.
setup-error-needs-passphrase = Αυτό το αρχείο ρυθμίσεων προστατεύεται με φράση πρόσβασης. Πληκτρολογήστε τη φράση πρόσβασης με την οποία αποθηκεύτηκε.
setup-error-wrong-passphrase = Η φράση πρόσβασης δεν είναι αυτή που χρησιμοποιήθηκε για την αποθήκευση του αρχείου ρυθμίσεων.
setup-error-changed = Ο έλεγχος ακεραιότητας του αρχείου ρυθμίσεων απέτυχε. Το αρχείο μπορεί να έχει τροποποιηθεί ή καταστραφεί και δεν μπορεί να εισαχθεί.
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
    [one] { $count } κανόνας περιμένει να βρεθεί ο φάκελος προορισμού κατά τον συγχρονισμό του λογαριασμού.
   *[other] { $count } κανόνες περιμένουν να βρεθούν οι φάκελοι προορισμού κατά τον συγχρονισμό των λογαριασμών.
}
setup-added-trusted-senders = { $count ->
    [one] Προστέθηκε { $count } αξιόπιστος αποστολέας.
   *[other] Προστέθηκαν { $count } αξιόπιστοι αποστολείς.
}
setup-nothing = Δεν εισήχθη τίποτα.
setup-account-servers = { $imap } και { $smtp } ({ $signin })
setup-file-name = Ρυθμίσεις και λογαριασμοί Inbox Classic
setup-skipped-unreachable = Παραλείφθηκε: { $name }. Δεν ήταν δυνατός ο έλεγχος της υπηρεσίας σύνδεσης. Ελέγξτε την απαιτούμενη εφαρμογή στις Εφαρμογές σύνδεσης και δοκιμάστε ξανά.
attachment-runs-programs = Το αρχείο «{ $name }» μπορεί να εκτελέσει προγράμματα, γι’ αυτό το Inbox Classic δεν το ανοίγει. Αποθηκεύστε το και ανοίξτε το μόνοι σας, αν εμπιστεύεστε την προέλευσή του.
attachment-decrypted-note = Αυτό το συνημμένο προέρχεται από κρυπτογραφημένο μήνυμα. Για να το ανοίξει, το Inbox Classic αποθηκεύει ένα μη κρυπτογραφημένο αντίγραφο σε προσωρινό φάκελο του λογαριασμού χρήστη σας. Κατά την εκκίνηση, το πρόγραμμα προσπαθεί να αφαιρέσει αντίγραφα παλαιότερα της μίας ημέρας.
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

## Previews of attachments: the pictures and PDF files shown in a message

preview-pdf-option = Εμφάνιση αρχείων PDF στα μηνύματα
preview-pdf-off = Τα αρχεία PDF δεν εμφανίζονται στα μηνύματα.
preview-pdf-off-crashed = Το Inbox Classic τερματίστηκε κατά την προεπισκόπηση αρχείου, οπότε απενεργοποιήθηκαν οι προεπισκοπήσεις PDF. Οι εικόνες εξακολουθούν να εμφανίζονται. Για να εμφανίζονται ξανά τα PDF, ενεργοποιήστε την επιλογή { $option } στις ρυθμίσεις { $settings }.
preview-pdf-details = { $count ->
    [one] 1 σελίδα, { $size }
   *[other] { $count } σελίδες, { $size }
}
preview-page-alt = { $name }, σελίδα { $page } από { $count }
preview-more-pages = { $count ->
    [one] Ανοίξτε το για να δείτε τη σελίδα
   *[other] Ανοίξτε το για να δείτε και τις { $count } σελίδες
}
preview-more-files = { $count ->
    [one] 1 ακόμη αρχείο βρίσκεται στη λίστα επάνω
   *[other] { $count } ακόμη αρχεία βρίσκονται στη λίστα επάνω
}
preview-tile-downloading = Γίνεται λήψη…
preview-tile-preparing = Προετοιμασία…
preview-tile-format = Οι εικόνες { $format } δεν εμφανίζονται ακόμη
preview-tile-password = Προστατεύεται με κωδικό πρόσβασης: ανοίξτε το για να τον εισαγάγετε
preview-tile-too-large = Πολύ μεγάλο για εμφάνιση
preview-tile-unreadable = Δεν μπορεί να εμφανιστεί
preview-tile-timed-out = Η προεπισκόπηση υπερέβη το χρονικό όριο
preview-tile-crashed = Δεν εμφανίζεται: η προηγούμενη προεπισκόπηση διακόπηκε
preview-tile-off = Δεν εμφανίζεται μέχρι να ξεκινήσει ξανά το Inbox Classic
preview-not-printed = Το { $name } ({ $details }) δεν εκτυπώνεται. Ανοίξτε το για να το εκτυπώσετε.

pgp-error-attached-private = Αυτό το συνημμένο περιέχει ιδιωτικό κλειδί. Μόνο δημόσια κλειδιά μπορούν να εισαχθούν απευθείας από την αλληλογραφία. Για να επαναφέρετε το δικό σας ιδιωτικό κλειδί, αποθηκεύστε το συνημμένο και εισαγάγετε το αρχείο από το παράθυρο «Κλειδιά κρυπτογράφησης».
pgp-part-find-key = Αναζήτηση κλειδιού
