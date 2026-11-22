//! Text compared without its case, the same whatever the language: Unicode's small letters with no locale, and
//! Turkish's two i's as one letter, so dotted İ/i and dotless I/ı match each other in any language (`ILKER`, `ilker`
//! and `İlker`; `IŞIK` and `ışık`). SQLite's own NOCASE and LIKE fold only ASCII, and FTS5's unicode61 folds I and İ
//! to i but keeps ı a letter of its own. Full width letters and digits (ＡＢＣ１２３, common in Japanese mail) are
//! their ASCII forms.
//!
//! And text as the search index takes it ([`segment`]): Chinese and Japanese write words without spaces between
//! them, and Korean writes endings onto its words (회의에서, "at the meeting"), so unicode61 would make one word of a
//! whole sentence. Each of their characters is a word of the index instead, and a search for several is a phrase of
//! them (search.rs): found inside longer words, as most mail programs find them.

use std::borrow::Cow;

/// `text` in small letters for comparing, with ı and İ as i and full width letters and digits as ASCII
pub(crate) fn fold(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    for c in text.chars().map(narrow) {
        match c {
            'ı' | 'İ' => out.push('i'),
            c => out.extend(c.to_lowercase()),
        }
    }
    out
}

/// A full width letter, digit or sign (U+FF01 to U+FF5E) as its ASCII form; any other character as it is
pub fn narrow(c: char) -> char {
    match c {
        '\u{FF01}'..='\u{FF5E}' => char::from_u32(c as u32 - 0xFEE0).unwrap_or(c),
        c => c,
    }
}

/// A character of a script written without spaces between its words, or of Korean's syllables: Han (the rare ones
/// beyond U+FFFF too), Hiragana, Katakana (half width too) and Hangul. Each is a word of the index.
pub(crate) fn is_segmented(c: char) -> bool {
    matches!(c,
        // Hangul Jamo
        '\u{1100}'..='\u{11FF}'
        // 々 〆 〇
        | '\u{3005}'..='\u{3007}'
        // Hiragana, its iteration marks
        | '\u{3041}'..='\u{3096}'
        | '\u{309D}'..='\u{309F}'
        // Katakana but its middle dot, which is punctuation
        | '\u{30A1}'..='\u{30FA}'
        | '\u{30FC}'..='\u{30FF}'
        // Hangul compatibility Jamo, Katakana phonetic extensions
        | '\u{3131}'..='\u{318E}'
        | '\u{31F0}'..='\u{31FF}'
        // Han, extension A and the unified ideographs
        | '\u{3400}'..='\u{4DBF}'
        | '\u{4E00}'..='\u{9FFF}'
        // Hangul Jamo extended A, the syllables, Jamo extended B
        | '\u{A960}'..='\u{A97F}'
        | '\u{AC00}'..='\u{D7FF}'
        // Han compatibility ideographs
        | '\u{F900}'..='\u{FAFF}'
        // half width Katakana and Hangul
        | '\u{FF66}'..='\u{FF9D}'
        | '\u{FFA0}'..='\u{FFDC}'
        // Han beyond U+FFFF: extensions B to I and the compatibility supplement
        | '\u{20000}'..='\u{3FFFF}'
    )
}

/// A mark that belongs to the character before it: combining marks, the kana voicing marks, variation selectors (the
/// ideographic ones too), the joiners. Kept with that character, never made a word of its own.
fn is_mark(c: char) -> bool {
    matches!(c,
        '\u{0300}'..='\u{036F}'
        | '\u{1AB0}'..='\u{1AFF}'
        | '\u{1DC0}'..='\u{1DFF}'
        | '\u{200C}'..='\u{200D}'
        | '\u{20D0}'..='\u{20FF}'
        | '\u{302A}'..='\u{302F}'
        | '\u{3099}'..='\u{309C}'
        | '\u{FE00}'..='\u{FE0F}'
        | '\u{FE20}'..='\u{FE2F}'
        | '\u{FF9E}'..='\u{FF9F}'
        | '\u{E0100}'..='\u{E01EF}'
    )
}

/// Whether [`segment`] changes `text`
pub(crate) fn segments(text: &str) -> bool {
    text.chars().any(|c| is_segmented(c) || narrow(c) != c)
}

/// `text` as the search index takes it: a space between each character of [`is_segmented`] and what is next to it, a
/// mark kept with its character, full width letters and digits as ASCII; any other text as it is. Only spaces are
/// added, so taking them out gives the text back with full width written as ASCII.
pub fn segment(text: &str) -> Cow<'_, str> {
    if !segments(text) {
        return Cow::Borrowed(text);
    }
    let mut out = String::with_capacity(text.len() + text.len() / 2);
    // the character written last was one of those segmented (or a mark on one): what follows is a word of its own
    let mut after = false;
    for c in text.chars().map(narrow) {
        if after && is_mark(c) {
            out.push(c);
            continue;
        }
        let segmented = is_segmented(c);
        if (segmented || after)
            && !c.is_whitespace()
            && out.chars().next_back().is_some_and(|last| !last.is_whitespace())
        {
            out.push(' ');
        }
        out.push(c);
        after = segmented;
    }
    Cow::Owned(out)
}

/// `text` as the search index has it: segmented, and ı as i, which unicode61 does not fold (the schema's trigger
/// does the same)
pub(crate) fn indexed(text: &str) -> String {
    segment(text).replace('ı', "i")
}

/// `fold(text)`, `segment(text)` and `segments(text)` in SQL. `fold` for the address completion, the To order and the migration that
/// writes the sort keys; `segment` for the search index's rows the store writes. Neither in a trigger or index, which
/// an older version must be able to write without them.
pub(crate) fn register(db: &rusqlite::Connection) -> rusqlite::Result<()> {
    use rusqlite::functions::FunctionFlags;
    fn text_function<T: rusqlite::ToSql + Default + 'static>(
        db: &rusqlite::Connection,
        name: &str,
        f: fn(&str) -> T,
    ) -> rusqlite::Result<()> {
        db.create_scalar_function(
            name,
            1,
            FunctionFlags::SQLITE_UTF8 | FunctionFlags::SQLITE_DETERMINISTIC,
            move |ctx| {
                Ok(match ctx.get_raw(0) {
                    rusqlite::types::ValueRef::Text(text) => f(&String::from_utf8_lossy(text)),
                    _ => T::default(),
                })
            },
        )
    }
    text_function(db, "fold", |text| Some(fold(text)))?;
    text_function(db, "segment", |text| Some(segment(text).into_owned()))?;
    // whether segment changes it, without writing it out (the migration that indexes such messages again)
    text_function(db, "segments", segments)
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

    #[test]
    fn folds_full_width_letters_and_digits_as_ascii() {
        assert_eq!(fold("ＡＢＣ１２３"), "abc123");
        assert_eq!(fold("ｒｅｐｏｒｔ！"), "report!");
        // the full width space and the ideographic letters stay
        assert_eq!(fold("会議\u{3000}Ｑ３"), "会議\u{3000}q3");
    }

    #[test]
    fn segments_each_character_of_words_without_spaces() {
        // Han, Hiragana, Katakana, Hangul
        assert_eq!(segment("会议纪要"), "会 议 纪 要");
        assert_eq!(segment("打ち合わせ"), "打 ち 合 わ せ");
        assert_eq!(segment("ミーティング"), "ミ ー テ ィ ン グ");
        assert_eq!(segment("회의에서"), "회 의 에 서");
        // half width Katakana, its voicing mark kept with it
        assert_eq!(segment("ｶﾞｲﾄﾞ"), "ｶﾞ ｲ ﾄﾞ");
        // mixed with Latin, spaces and punctuation as they were
        assert_eq!(segment("Q3会议report"), "Q3 会 议 report");
        assert_eq!(segment("Re: 会议, ok"), "Re: 会 议 , ok");
        assert_eq!(segment("会议\n报告"), "会 议\n报 告");
        assert_eq!(segment("会议\u{3000}报告"), "会 议\u{3000}报 告");
        // full width letters and digits as ASCII, a word as any other
        assert_eq!(segment("ＡＢＣ１２３"), "ABC123");
        assert_eq!(segment("見積書ＡＢＣ"), "見 積 書 ABC");
        assert_eq!(segment("＂会＂"), "\" 会 \"");
        // a combining mark stays with its character, a variation selector with its ideograph
        assert_eq!(segment("か\u{3099}き"), "か\u{3099} き");
        assert_eq!(segment("葛\u{E0100}城"), "葛\u{E0100} 城");
        // Han beyond U+FFFF
        assert_eq!(segment("𠮷野家"), "𠮷 野 家");
        assert_eq!(segment("𩸽𠀋"), "𩸽 𠀋");
        assert_eq!(segment(""), "");
        assert_eq!(segment("会"), "会");
    }

    #[test]
    fn leaves_other_scripts_as_they_are() {
        for text in [
            "Quarterly report",
            "Kvartali aruanne: õhtu ja äärmus",
            "Новости недели",
            "Ελληνικά νέα",
            "Tiếng Việt có dấu",
            "Türkçe ışık",
            "café\u{301}",
            "חדשות",
            "",
        ] {
            assert!(matches!(segment(text), Cow::Borrowed(_)), "{text}");
            assert!(!segments(text), "{text}");
        }
    }

    #[test]
    fn segmenting_only_adds_spaces() {
        // random strings of every kind of character: without spaces, the segmented text is the text with full width
        // as ASCII
        let pieces = [
            "会",
            "議",
            "ち",
            "ー",
            "グ",
            "회",
            "의",
            "ｶ",
            "ﾞ",
            "\u{3099}",
            "\u{E0100}",
            "𠮷",
            "Ａ",
            "１",
            "＂",
            "a",
            "Z",
            "9",
            " ",
            "\u{3000}",
            "\n",
            "é",
            "\u{301}",
            "ı",
            "Ж",
            "\"",
            "*",
            ":",
            "-",
            "(",
            "",
        ];
        let mut rng = pe_testkit::Rng::new(0x5e9_3e47);
        for _ in 0..5000 {
            let text: String = (0..rng.below(24)).map(|_| *rng.pick(&pieces)).collect();
            let segmented = segment(&text);
            let narrowed: String = text.chars().map(narrow).filter(|c| *c != ' ').collect();
            assert_eq!(segmented.replace(' ', ""), narrowed, "{text:?}");
            // and again changes nothing
            assert_eq!(segment(&segmented), segmented, "{text:?}");
        }
    }
}
