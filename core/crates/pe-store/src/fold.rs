//! Text compared without its case, the same whatever the language: Unicode's small letters with no locale, and
//! Turkish's two i's as one letter, so dotted İ/i and dotless I/ı match each other in any language (`ILKER`, `ilker`
//! and `İlker`; `IŞIK` and `ışık`). SQLite's own NOCASE and LIKE fold only ASCII, and FTS5's unicode61 folds I and İ
//! to i but keeps ı a letter of its own.

/// `text` in small letters for comparing, with ı and İ as i
pub(crate) fn fold(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    for c in text.chars() {
        match c {
            'ı' | 'İ' => out.push('i'),
            c => out.extend(c.to_lowercase()),
        }
    }
    out
}

/// `column` with ı and İ as i, in SQLite's own functions only: the schema's indexes have it, which an older version of
/// the app must still be able to write
pub(crate) fn dotless_as_i(column: &str) -> String {
    format!("replace(replace({column}, 'İ', 'i'), 'ı', 'i')")
}

/// `column` as the message list orders it: [`dotless_as_i`], then NOCASE for the ASCII letters
pub(crate) fn order_key(column: &str) -> String {
    format!("{} COLLATE NOCASE", dotless_as_i(column))
}

/// `text` as the search index has it: ı as i, which unicode61 does not fold (the schema's trigger does the same)
pub(crate) fn indexed(text: &str) -> String {
    text.replace('ı', "i")
}

/// `fold(text)` in SQL, for the address completion (never in the schema, which an older version reads without it)
pub(crate) fn register(db: &rusqlite::Connection) -> rusqlite::Result<()> {
    use rusqlite::functions::FunctionFlags;
    db.create_scalar_function(
        "fold",
        1,
        FunctionFlags::SQLITE_UTF8 | FunctionFlags::SQLITE_DETERMINISTIC,
        |ctx| {
            Ok(match ctx.get_raw(0) {
                rusqlite::types::ValueRef::Text(text) => Some(fold(&String::from_utf8_lossy(text))),
                _ => None,
            })
        },
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn folds_case_and_the_turkish_i() {
        assert_eq!(fold("İSTANBUL"), "istanbul");
        assert_eq!(fold("IŞIK"), "işik");
        assert_eq!(fold("ışık"), "işik");
        assert_eq!(fold("Çağlar ÖZ"), "çağlar öz");
        assert_eq!(fold("Straße ÉTÉ"), "straße été");
        assert_eq!(indexed("ışık IŞIK"), "işik IŞIK");
    }
}
