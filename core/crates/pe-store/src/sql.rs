//! The expressions the list orders and counts share, as macros of string literals: the queries (with `""`, a column
//! of the row read) and the schema's triggers (with `"NEW."` or `"OLD."`) say them once, and a migration made of them
//! stays one `&'static str`. Each takes the prefix of the columns: `""`, `"m."`, `"NEW."`.

/// When a message was written as the Date order sorts it: its Date header, never later than its arrival
/// ([`crate::Message::display_date`])
macro_rules! list_date {
    ($r:literal) => {
        concat!(
            "COALESCE(MIN(",
            $r,
            "date, ",
            $r,
            "internal_date), ",
            $r,
            "date, ",
            $r,
            "internal_date)"
        )
    };
}

/// When a message arrived, as a conversation's first message is found (threads.rs ARRIVED), one without a date first
macro_rules! arrived_key {
    ($r:literal) => {
        concat!("COALESCE(", $r, "internal_date, ", $r, "date, -9223372036854775807)")
    };
}

/// What the From order sorts by: the sort key the store writes, or the name (the address when there is none)
macro_rules! from_key {
    ($r:literal) => {
        concat!(
            "COALESCE(",
            $r,
            "sort_from, CASE ",
            $r,
            "from_name WHEN '' THEN ",
            $r,
            "from_address ELSE ",
            $r,
            "from_name END)"
        )
    };
}

/// What the Subject order sorts by
macro_rules! subject_key {
    ($r:literal) => {
        concat!("COALESCE(", $r, "sort_subject, ", $r, "subject)")
    };
}

/// Flagged as the Flagged folder finds it (the words of the index `messages_flagged`)
macro_rules! is_flagged {
    ($r:literal) => {
        concat!("instr(' ' || ", $r, "flags || ' ', ' \\Flagged ') > 0")
    };
}

/// Flagged in any case, as a selection counts it
macro_rules! any_flagged {
    ($r:literal) => {
        concat!("instr(' ' || lower(", $r, "flags) || ' ', ' \\flagged ') > 0")
    };
}

/// The message an upsert of `conversations` brings arrived before the conversation's first one there
macro_rules! first_earlier {
    () => {
        "(excluded.first_at, excluded.first_uid, excluded.first_id) < (first_at, first_uid, first_id)"
    };
}

/// The message `$r` counted in its folder and its conversation (a row of `conversations` made, or its numbers, newest
/// dates and first message brought up to date with it): the schema's triggers
macro_rules! count_message {
    ($r:literal) => {
        concat!(
            "UPDATE folders SET total = total + 1, unread = unread + (", $r, "seen = 0), flagged = flagged + (",
            is_flagged!($r), ") WHERE id = ", $r, "folder_id;
    INSERT INTO conversations (folder_id, thread_id, total, unread, flagged, newest, newest_received, first_id,
        first_at, first_uid, first_from, first_subject, first_size)
    VALUES (", $r, "folder_id, ", $r, "thread_id, 1, ", $r, "seen = 0, ", any_flagged!($r), ", ", list_date!($r), ", ",
            $r, "internal_date, ", $r, "id, ", arrived_key!($r), ", ", $r, "uid, ", from_key!($r), ", ",
            subject_key!($r), ", ", $r, "size)
    ON CONFLICT (folder_id, thread_id) DO UPDATE SET total = total + 1, unread = unread + excluded.unread,
        flagged = flagged + excluded.flagged,
        newest = CASE WHEN excluded.newest > COALESCE(newest, -9223372036854775807) THEN excluded.newest ELSE newest END,
        newest_received = CASE WHEN excluded.newest_received > COALESCE(newest_received, -9223372036854775807)
            THEN excluded.newest_received ELSE newest_received END,
        first_id = CASE WHEN ", first_earlier!(), " THEN excluded.first_id ELSE first_id END,
        first_at = CASE WHEN ", first_earlier!(), " THEN excluded.first_at ELSE first_at END,
        first_uid = CASE WHEN ", first_earlier!(), " THEN excluded.first_uid ELSE first_uid END,
        first_from = CASE WHEN ", first_earlier!(), " THEN excluded.first_from ELSE first_from END,
        first_subject = CASE WHEN ", first_earlier!(), " THEN excluded.first_subject ELSE first_subject END,
        first_size = CASE WHEN ", first_earlier!(), " THEN excluded.first_size ELSE first_size END;
"
        )
    };
}

/// The message `$r` taken out of its folder's counts and its conversation, whose newest dates and first message are
/// found again when they were its (a conversation left without messages goes)
macro_rules! uncount_message {
    ($r:literal) => {
        concat!(
            "UPDATE folders SET total = total - 1, unread = unread - (",
            $r,
            "seen = 0), flagged = flagged - (",
            is_flagged!($r),
            ") WHERE id = ",
            $r,
            "folder_id;
    UPDATE conversations SET total = total - 1, unread = unread - (",
            $r,
            "seen = 0), flagged = flagged - (",
            any_flagged!($r),
            ")
    WHERE folder_id = ",
            $r,
            "folder_id AND thread_id = ",
            $r,
            "thread_id;
    DELETE FROM conversations WHERE folder_id = ",
            $r,
            "folder_id AND thread_id = ",
            $r,
            "thread_id AND total <= 0;
    UPDATE conversations SET
        newest = (SELECT MAX(",
            list_date!("m."),
            ") FROM messages m
            WHERE m.folder_id = ",
            $r,
            "folder_id AND m.thread_id = ",
            $r,
            "thread_id),
        newest_received = (SELECT MAX(m.internal_date) FROM messages m
            WHERE m.folder_id = ",
            $r,
            "folder_id AND m.thread_id = ",
            $r,
            "thread_id)
    WHERE folder_id = ",
            $r,
            "folder_id AND thread_id = ",
            $r,
            "thread_id
        AND (newest IS ",
            list_date!($r),
            " OR newest_received IS ",
            $r,
            "internal_date);
    UPDATE conversations SET (first_id, first_at, first_uid, first_from, first_subject, first_size) = (
        SELECT m.id, ",
            arrived_key!("m."),
            ", m.uid, ",
            from_key!("m."),
            ", ",
            subject_key!("m."),
            ", m.size
        FROM messages m WHERE m.folder_id = ",
            $r,
            "folder_id AND m.thread_id = ",
            $r,
            "thread_id
        ORDER BY ",
            arrived_key!("m."),
            ", m.uid, m.id LIMIT 1)
    WHERE folder_id = ",
            $r,
            "folder_id AND thread_id = ",
            $r,
            "thread_id AND first_id = ",
            $r,
            "id;
"
        )
    };
}

/// What places a message in its conversation and the list orders, `OLD` against `NEW`: with `"IS NOT"` and `"OR"` one
/// of them changed, with `"IS"` and `"AND"` none did
macro_rules! placed_by_changed {
    ($is:literal, $join:literal) => {
        concat!(
            "OLD.folder_id ",
            $is,
            " NEW.folder_id ",
            $join,
            " OLD.thread_id ",
            $is,
            " NEW.thread_id ",
            $join,
            " OLD.uid ",
            $is,
            " NEW.uid ",
            $join,
            " OLD.date ",
            $is,
            " NEW.date ",
            $join,
            " OLD.internal_date ",
            $is,
            " NEW.internal_date ",
            $join,
            " OLD.size ",
            $is,
            " NEW.size ",
            $join,
            " OLD.sort_from ",
            $is,
            " NEW.sort_from ",
            $join,
            " OLD.sort_subject ",
            $is,
            " NEW.sort_subject ",
            $join,
            " OLD.from_name ",
            $is,
            " NEW.from_name ",
            $join,
            " OLD.from_address ",
            $is,
            " NEW.from_address ",
            $join,
            " OLD.subject ",
            $is,
            " NEW.subject"
        )
    };
}

/// Every conversation of every folder counted from its messages, as `conversations` keeps them: what the migration
/// fills it with, and what the tests compare it with
macro_rules! conversations_counted {
    () => {
        concat!(
            "SELECT folder_id, thread_id, COUNT(*), SUM(seen = 0), SUM(",
            any_flagged!(""),
            "), MAX(",
            list_date!(""),
            "), MAX(internal_date), MAX(CASE r WHEN 1 THEN id END), MAX(CASE r WHEN 1 THEN ",
            arrived_key!(""),
            " END), MAX(CASE r WHEN 1 THEN uid END), MAX(CASE r WHEN 1 THEN ",
            from_key!(""),
            " END), MAX(CASE r WHEN 1 THEN ",
            subject_key!(""),
            " END), MAX(CASE r WHEN 1 THEN size END)
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY folder_id, thread_id ORDER BY ",
            arrived_key!(""),
            ", uid, id) AS r FROM messages)
GROUP BY folder_id, thread_id"
        )
    };
}
