//! SEARCH with a typed query. Text with non-ASCII characters is sent with CHARSET UTF-8, or as it
//! is when UTF8=ACCEPT is enabled. Both plain SEARCH answers and ESEARCH are read. A port of the
//! parts of imapflow's search-compiler.ts a mail client uses.

use super::{Client, Error};
use crate::compiler::Arg;
use crate::types::{Response, Token};

/// The most numbers an ESEARCH range may expand to
const EXPANDED_RANGE_LIMIT: u64 = 0x100_0000;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SearchKey {
    All,
    Seen,
    Unseen,
    Flagged,
    Unflagged,
    Answered,
    Unanswered,
    Deleted,
    Undeleted,
    Draft,
    Undraft,
    Keyword(String),
    Unkeyword(String),
    From(String),
    To(String),
    Cc(String),
    Bcc(String),
    Subject(String),
    Body(String),
    Text(String),
    Header(String, String),
    /// INTERNALDATE on or after this day (seconds since the Unix epoch, UTC day)
    Since(i64),
    Before(i64),
    On(i64),
    /// The Date header on or after this day
    SentSince(i64),
    SentBefore(i64),
    Larger(u64),
    Smaller(u64),
    /// A UID set, `1:100`
    Uid(String),
    /// Messages changed after this MODSEQ (CONDSTORE)
    ModSeq(u64),
    Or(Box<SearchKey>, Box<SearchKey>),
    Not(Box<SearchKey>),
    /// All of these
    And(Vec<SearchKey>),
}

/// `06-Oct-2025` of a timestamp
fn day(timestamp: i64) -> String {
    let date_time = pe_mime::date::format_internal_date(timestamp);
    date_time.split(' ').next().unwrap_or_default().to_string()
}

impl SearchKey {
    fn compile(&self, args: &mut Vec<Arg>) {
        let atom = |args: &mut Vec<Arg>, name: &str| args.push(Arg::atom(name));
        let text = |args: &mut Vec<Arg>, name: &str, value: &str| {
            args.push(Arg::atom(name));
            args.push(Arg::string(value));
        };
        let date = |args: &mut Vec<Arg>, name: &str, timestamp: i64| {
            args.push(Arg::atom(name));
            args.push(Arg::atom(day(timestamp)));
        };
        match self {
            SearchKey::All => atom(args, "ALL"),
            SearchKey::Seen => atom(args, "SEEN"),
            SearchKey::Unseen => atom(args, "UNSEEN"),
            SearchKey::Flagged => atom(args, "FLAGGED"),
            SearchKey::Unflagged => atom(args, "UNFLAGGED"),
            SearchKey::Answered => atom(args, "ANSWERED"),
            SearchKey::Unanswered => atom(args, "UNANSWERED"),
            SearchKey::Deleted => atom(args, "DELETED"),
            SearchKey::Undeleted => atom(args, "UNDELETED"),
            SearchKey::Draft => atom(args, "DRAFT"),
            SearchKey::Undraft => atom(args, "UNDRAFT"),
            SearchKey::Keyword(flag) => text(args, "KEYWORD", flag),
            SearchKey::Unkeyword(flag) => text(args, "UNKEYWORD", flag),
            SearchKey::From(value) => text(args, "FROM", value),
            SearchKey::To(value) => text(args, "TO", value),
            SearchKey::Cc(value) => text(args, "CC", value),
            SearchKey::Bcc(value) => text(args, "BCC", value),
            SearchKey::Subject(value) => text(args, "SUBJECT", value),
            SearchKey::Body(value) => text(args, "BODY", value),
            SearchKey::Text(value) => text(args, "TEXT", value),
            SearchKey::Header(name, value) => {
                text(args, "HEADER", name);
                args.push(Arg::string(value.as_str()));
            }
            SearchKey::Since(t) => date(args, "SINCE", *t),
            SearchKey::Before(t) => date(args, "BEFORE", *t),
            SearchKey::On(t) => date(args, "ON", *t),
            SearchKey::SentSince(t) => date(args, "SENTSINCE", *t),
            SearchKey::SentBefore(t) => date(args, "SENTBEFORE", *t),
            SearchKey::Larger(size) => args.extend([Arg::atom("LARGER"), Arg::Number(*size)]),
            SearchKey::Smaller(size) => args.extend([Arg::atom("SMALLER"), Arg::Number(*size)]),
            SearchKey::Uid(set) => args.extend([Arg::atom("UID"), Arg::Sequence(set.clone())]),
            SearchKey::ModSeq(modseq) => args.extend([Arg::atom("MODSEQ"), Arg::Number(*modseq)]),
            SearchKey::Or(a, b) => {
                atom(args, "OR");
                a.compile_one(args);
                b.compile_one(args);
            }
            SearchKey::Not(key) => {
                atom(args, "NOT");
                key.compile_one(args);
            }
            SearchKey::And(keys) if keys.is_empty() => atom(args, "ALL"),
            SearchKey::And(keys) => keys.iter().for_each(|key| key.compile(args)),
        }
    }

    /// A key where the grammar takes exactly one: several are put in parentheses
    fn compile_one(&self, args: &mut Vec<Arg>) {
        let mut inner = Vec::new();
        self.compile(&mut inner);
        if inner.len() > 1 && matches!(self, SearchKey::And(_)) {
            args.push(Arg::List(inner));
        } else {
            args.extend(inner);
        }
    }

    fn has_non_ascii(&self) -> bool {
        match self {
            SearchKey::Keyword(v)
            | SearchKey::Unkeyword(v)
            | SearchKey::From(v)
            | SearchKey::To(v)
            | SearchKey::Cc(v)
            | SearchKey::Bcc(v)
            | SearchKey::Subject(v)
            | SearchKey::Body(v)
            | SearchKey::Text(v) => !v.is_ascii(),
            SearchKey::Header(name, value) => !name.is_ascii() || !value.is_ascii(),
            SearchKey::Or(a, b) => a.has_non_ascii() || b.has_non_ascii(),
            SearchKey::Not(key) => key.has_non_ascii(),
            SearchKey::And(keys) => keys.iter().any(SearchKey::has_non_ascii),
            _ => false,
        }
    }
}

/// The numbers of `1:3,7`, None past the expansion limit or for a malformed set
fn expand(set: &str) -> Option<Vec<u64>> {
    let mut out = Vec::new();
    for range in set.split(',') {
        let (first, last) = range.split_once(':').unwrap_or((range, range));
        let (first, last): (u64, u64) = (first.parse().ok()?, last.parse().ok()?);
        let (low, high) = (first.min(last), first.max(last));
        if out.len() as u64 + (high - low) >= EXPANDED_RANGE_LIMIT {
            return None;
        }
        out.extend(low..=high);
    }
    Some(out)
}

fn read_results(responses: &[Response]) -> Result<Vec<u64>, Error> {
    let mut found = Vec::new();
    for response in responses {
        match response.command.to_ascii_uppercase().as_str() {
            "SEARCH" => match &response.numbers {
                Some(numbers) => found.extend(numbers),
                // a MODSEQ list or anything else the fast path left to the tokenizer
                None => found.extend(response.attributes.iter().filter_map(Token::number)),
            },
            // * ESEARCH (TAG "A1") UID ALL 1:3,5
            "ESEARCH" => {
                let items = &response.attributes;
                if let Some(index) = items.iter().position(|t| t.is_atom("ALL")) {
                    let set = items.get(index + 1).and_then(Token::text).unwrap_or_default();
                    found.extend(expand(&set).ok_or(Error::TooManyResponses)?);
                }
            }
            _ => {}
        }
    }
    Ok(found)
}

impl Client {
    /// UIDs (or sequence numbers without `uid`) of the matching messages, ascending
    pub async fn search(&mut self, key: &SearchKey, uid: bool) -> Result<Vec<u64>, Error> {
        if self.selected.is_none() {
            return Err(Error::NoMailboxSelected);
        }
        let mut args = Vec::new();
        if key.has_non_ascii() && !self.is_enabled("UTF8=ACCEPT") {
            args.extend([Arg::atom("CHARSET"), Arg::atom("UTF-8")]);
        }
        key.compile(&mut args);
        let command = if uid { "UID SEARCH" } else { "SEARCH" };
        let completion = self.run(command, args).await?;
        let mut found = read_results(&completion.untagged)?;
        found.sort_unstable();
        found.dedup();
        Ok(found)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::compiler::{Command, CompileOptions, compile};

    fn wire(key: &SearchKey) -> String {
        let mut args = Vec::new();
        key.compile(&mut args);
        let command = Command {
            tag: "A1".into(),
            name: "UID SEARCH".into(),
            args,
        };
        let segments = compile(
            &command,
            &CompileOptions {
                utf8: true,
                ..Default::default()
            },
        )
        .unwrap();
        String::from_utf8(segments.concat()).unwrap().trim_end().to_string()
    }

    #[test]
    fn compiles_keys() {
        assert_eq!(wire(&SearchKey::And(vec![])), "A1 UID SEARCH ALL");
        let key = SearchKey::And(vec![
            SearchKey::Unseen,
            SearchKey::From("andris".into()),
            SearchKey::Since(1_759_744_800),
            SearchKey::Or(
                Box::new(SearchKey::Subject("Jõul".into())),
                Box::new(SearchKey::And(vec![SearchKey::Flagged, SearchKey::Larger(100)])),
            ),
            SearchKey::Not(Box::new(SearchKey::Deleted)),
            SearchKey::Header("X-Spam".into(), "yes".into()),
            SearchKey::Uid("1:*".into()),
        ]);
        assert_eq!(
            wire(&key),
            "A1 UID SEARCH UNSEEN FROM \"andris\" SINCE 06-Oct-2025 OR SUBJECT \"Jõul\" (FLAGGED LARGER 100) NOT DELETED HEADER \"X-Spam\" \"yes\" UID 1:*"
        );
        assert!(key.has_non_ascii());
        assert!(!SearchKey::Subject("plain".into()).has_non_ascii());
    }

    #[test]
    fn reads_search_and_esearch() {
        let parse = |line: &str| crate::parse(line.as_bytes(), Vec::new()).unwrap();
        let responses = vec![
            parse("* SEARCH 5 3 9"),
            parse("* ESEARCH (TAG \"A1\") UID MIN 2 COUNT 3 ALL 2,10:11"),
            parse("* SEARCH 4 (MODSEQ 917162500)"),
        ];
        assert_eq!(read_results(&responses).unwrap(), vec![5, 3, 9, 2, 10, 11, 4]);
        assert_eq!(expand("1:3,7"), Some(vec![1, 2, 3, 7]));
        assert_eq!(expand("3:1"), Some(vec![1, 2, 3]));
        assert_eq!(expand("1:99999999999"), None);
        assert_eq!(expand("x"), None);
    }
}
