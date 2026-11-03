//! What is typed in the Find box, read the way Gmail reads its search box: words (matched where words start),
//! `"exact phrases"`, `-word` for none of it, `OR` between alternatives, and operators:
//!
//! - `from:` `to:` `cc:` `bcc:` `subject:` `filename:` a word in that part (to, cc and bcc all mean the recipients)
//! - `is:unread` `is:read` `is:starred` (or `is:flagged`) `is:answered`; `has:attachment`
//! - `in:inbox` `in:sent` `in:drafts` `in:trash` `in:spam` `in:archive`, `in:<folder name>`, `in:anywhere`
//!   (`label:` is the same); a search with `in:` looks in every account
//! - `before:` `after:` a day (2025/01/31 or 2025-01-31), `older_than:` `newer_than:` (2d, 3m, 1y)
//! - `larger:` `smaller:` a size in bytes, or with K, M or G (`larger:5M`)
//!
//! An operator that is not one of these is taken as a word, as are its value's quotes.

/// The part of a message a word is looked for in
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Field {
    Any,
    Subject,
    /// From, Sender and Reply-To
    From,
    /// To, Cc and Bcc
    To,
    /// The names of its files
    Filename,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Word {
    pub field: Field,
    pub text: String,
    /// Quoted: these words in this order, the last one whole
    pub phrase: bool,
}

/// A folder by what `in:` names
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Place {
    /// Every folder
    Anywhere,
    Inbox,
    /// A special-use folder (`\Sent`), or one with the name typed
    Special {
        special_use: &'static str,
        name: String,
    },
    /// A folder by its name or path
    Named(String),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Term {
    /// One of these words (several were joined by OR); negated: none of them
    Text {
        any_of: Vec<Word>,
        negated: bool,
    },
    Seen(bool),
    Flagged(bool),
    Answered(bool),
    Attachment(bool),
    In {
        place: Place,
        negated: bool,
    },
    /// Dated before, or on or after, this time (seconds since the Unix epoch)
    Before(i64),
    After(i64),
    /// Larger or smaller than this many bytes
    Larger(u64),
    Smaller(u64),
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Query {
    pub terms: Vec<Term>,
}

const DAY: i64 = 86_400;

impl Query {
    /// What `text` asks for, `now` (seconds since the Unix epoch) the time `older_than:` counts back from
    pub fn parse(text: &str, now: i64) -> Query {
        let mut terms: Vec<Term> = Vec::new();
        let mut or_next = false;
        for raw in tokens(text) {
            if raw.text == "OR" && !raw.quoted && raw.operator.is_none() && !raw.negated {
                or_next = true;
                continue;
            }
            let term = term(&raw, now);
            let joined = or_next;
            or_next = false;
            // an alternative of the word before it: a OR b
            if joined
                && let (
                    Some(Term::Text { any_of, negated: false }),
                    Term::Text {
                        any_of: more,
                        negated: false,
                    },
                ) = (terms.last_mut(), &term)
            {
                any_of.extend(more.iter().cloned());
                continue;
            }
            terms.push(term);
        }
        Query { terms }
    }

    /// Whether it names folders itself (`in:`), so the search looks beyond the folder shown
    pub fn spans_folders(&self) -> bool {
        self.terms.iter().any(|term| matches!(term, Term::In { .. }))
    }

    pub fn is_empty(&self) -> bool {
        self.terms.is_empty()
    }
}

/// A piece of the text: `-` before it, `operator:` and its value, or a word; quoted values are phrases
struct Token {
    negated: bool,
    operator: Option<String>,
    text: String,
    quoted: bool,
}

fn tokens(text: &str) -> Vec<Token> {
    let chars: Vec<char> = text.chars().collect();
    let mut found = Vec::new();
    let mut i = 0;
    while i < chars.len() {
        if chars[i].is_whitespace() {
            i += 1;
            continue;
        }
        let negated = chars[i] == '-' && chars.get(i + 1).is_some_and(|c| !c.is_whitespace());
        if negated {
            i += 1;
        }
        // an operator: letters and _ then a colon with something after it
        let mut operator = None;
        let start = i;
        let mut j = i;
        while j < chars.len() && (chars[j].is_ascii_alphabetic() || chars[j] == '_') {
            j += 1;
        }
        if j > start && chars.get(j) == Some(&':') && chars.get(j + 1).is_some_and(|c| !c.is_whitespace()) {
            operator = Some(chars[start..j].iter().collect::<String>().to_ascii_lowercase());
            i = j + 1;
        }
        let (text, quoted) = if chars.get(i) == Some(&'"') {
            let end = chars[i + 1..]
                .iter()
                .position(|c| *c == '"')
                .map_or(chars.len(), |p| i + 1 + p);
            let value: String = chars[i + 1..end].iter().collect();
            i = (end + 1).min(chars.len());
            (value, true)
        } else {
            let end = chars[i..]
                .iter()
                .position(|c| c.is_whitespace())
                .map_or(chars.len(), |p| i + p);
            let value: String = chars[i..end].iter().collect();
            i = end;
            (value, false)
        };
        found.push(Token {
            negated,
            operator,
            text,
            quoted,
        });
    }
    found
}

fn word(field: Field, raw: &Token) -> Term {
    Term::Text {
        any_of: vec![Word {
            field,
            text: raw.text.clone(),
            phrase: raw.quoted,
        }],
        negated: raw.negated,
    }
}

/// What a token asks for; one that is no operator, or whose value is not one, is a word as typed
fn term(raw: &Token, now: i64) -> Term {
    let Some(operator) = raw.operator.as_deref() else {
        return word(Field::Any, raw);
    };
    let value = raw.text.to_ascii_lowercase();
    let yes = !raw.negated;
    let field = match operator {
        "from" => Some(Field::From),
        "to" | "cc" | "bcc" => Some(Field::To),
        "subject" => Some(Field::Subject),
        "filename" => Some(Field::Filename),
        _ => None,
    };
    if let Some(field) = field {
        return word(field, raw);
    }
    let known = match (operator, value.as_str()) {
        ("is", "unread") => Some(Term::Seen(!yes)),
        ("is", "read") => Some(Term::Seen(yes)),
        ("is", "starred" | "flagged") => Some(Term::Flagged(yes)),
        ("is", "unstarred" | "unflagged") => Some(Term::Flagged(!yes)),
        ("is", "answered" | "replied") => Some(Term::Answered(yes)),
        ("has", "attachment" | "attachments") => Some(Term::Attachment(yes)),
        ("in" | "label", _) => Some(Term::In {
            place: place(&raw.text),
            negated: raw.negated,
        }),
        ("before", day) => date(day).map(Term::Before),
        ("after", day) => date(day).map(Term::After),
        ("older_than", span) => age(span).map(|age| Term::Before(now - age)),
        ("newer_than", span) => age(span).map(|age| Term::After(now - age)),
        ("larger", size) => bytes(size).map(Term::Larger),
        ("smaller", size) => bytes(size).map(Term::Smaller),
        _ => None,
    };
    known.unwrap_or_else(|| {
        // not an operator after all: the whole of it as a word
        word(
            Field::Any,
            &Token {
                negated: raw.negated,
                operator: None,
                text: format!("{operator}:{}", raw.text),
                quoted: raw.quoted,
            },
        )
    })
}

fn place(name: &str) -> Place {
    let special = |special_use| Place::Special {
        special_use,
        name: name.to_string(),
    };
    match name.to_ascii_lowercase().as_str() {
        "anywhere" | "all" => Place::Anywhere,
        "inbox" => Place::Inbox,
        "sent" => special("\\Sent"),
        "drafts" | "draft" => special("\\Drafts"),
        "trash" | "deleted" => special("\\Trash"),
        "spam" | "junk" => special("\\Junk"),
        "archive" => special("\\Archive"),
        _ => Place::Named(name.to_string()),
    }
}

/// A day, `2025/01/31` or `2025-01-31`, as the start of that day in UTC
fn date(text: &str) -> Option<i64> {
    let parts: Vec<&str> = text.split(['/', '-']).collect();
    let [year, month, day] = parts.as_slice() else {
        return None;
    };
    let (year, month, day): (i64, i64, i64) = (year.parse().ok()?, month.parse().ok()?, day.parse().ok()?);
    if !(1970..=9999).contains(&year) || !(1..=12).contains(&month) || !(1..=31).contains(&day) {
        return None;
    }
    // days from the civil date (Howard Hinnant's days_from_civil)
    let y = if month <= 2 { year - 1 } else { year };
    let era = y.div_euclid(400);
    let yoe = y - era * 400;
    let mp = (month + 9) % 12;
    let doy = (153 * mp + 2) / 5 + day - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    Some((era * 146_097 + doe - 719_468) * DAY)
}

/// `2d`, `3m`, `1y` in seconds (a month is 30 days, a year 365)
fn age(text: &str) -> Option<i64> {
    let (number, unit) = text.split_at(text.len().checked_sub(1)?);
    let number: i64 = number.parse().ok().filter(|n| *n >= 0)?;
    let days = match unit {
        "d" => 1,
        "m" => 30,
        "y" => 365,
        _ => return None,
    };
    number.checked_mul(days * DAY)
}

/// `5000`, `5k`, `5m`, `1g` (also with a trailing b) in bytes
fn bytes(text: &str) -> Option<u64> {
    let text = text.strip_suffix('b').unwrap_or(text);
    let (number, factor) = match text.chars().last()? {
        'k' => (&text[..text.len() - 1], 1024),
        'm' => (&text[..text.len() - 1], 1024 * 1024),
        'g' => (&text[..text.len() - 1], 1024 * 1024 * 1024),
        _ => (text, 1),
    };
    number.parse::<u64>().ok()?.checked_mul(factor)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn words(text: &str, field: Field) -> Term {
        Term::Text {
            any_of: vec![Word {
                field,
                text: text.into(),
                phrase: false,
            }],
            negated: false,
        }
    }

    #[test]
    fn words_phrases_negation_and_or() {
        let query = Query::parse(r#"budget "next year" -draft lunch OR dinner"#, 0);
        assert_eq!(
            query.terms,
            vec![
                words("budget", Field::Any),
                Term::Text {
                    any_of: vec![Word {
                        field: Field::Any,
                        text: "next year".into(),
                        phrase: true,
                    }],
                    negated: false,
                },
                Term::Text {
                    any_of: vec![Word {
                        field: Field::Any,
                        text: "draft".into(),
                        phrase: false,
                    }],
                    negated: true,
                },
                Term::Text {
                    any_of: vec![
                        Word {
                            field: Field::Any,
                            text: "lunch".into(),
                            phrase: false,
                        },
                        Word {
                            field: Field::Any,
                            text: "dinner".into(),
                            phrase: false,
                        },
                    ],
                    negated: false,
                },
            ]
        );
        // a lone dash, and "or" in lowercase, are words
        assert_eq!(Query::parse("a - b", 0).terms.len(), 3);
        assert_eq!(Query::parse("this or that", 0).terms.len(), 3);
    }

    #[test]
    fn operators() {
        let parse = |text: &str| Query::parse(text, 100 * DAY).terms;
        assert_eq!(parse("from:ann"), [words("ann", Field::From)]);
        assert_eq!(parse("TO:bob cc:carol bcc:dave").len(), 3);
        assert_eq!(
            parse("subject:\"q3 plans\"")[0],
            Term::Text {
                any_of: vec![Word {
                    field: Field::Subject,
                    text: "q3 plans".into(),
                    phrase: true
                }],
                negated: false
            }
        );
        assert_eq!(parse("filename:pdf"), [words("pdf", Field::Filename)]);
        assert_eq!(parse("is:unread"), [Term::Seen(false)]);
        assert_eq!(parse("-is:unread"), [Term::Seen(true)]);
        assert_eq!(
            parse("is:read is:starred is:flagged"),
            [Term::Seen(true), Term::Flagged(true), Term::Flagged(true)]
        );
        assert_eq!(parse("is:answered"), [Term::Answered(true)]);
        assert_eq!(
            parse("has:attachment -has:attachment"),
            [Term::Attachment(true), Term::Attachment(false)]
        );
        assert_eq!(
            parse("in:Sent"),
            [Term::In {
                place: Place::Special {
                    special_use: "\\Sent",
                    name: "Sent".into()
                },
                negated: false
            }]
        );
        assert_eq!(
            parse("in:inbox"),
            [Term::In {
                place: Place::Inbox,
                negated: false
            }]
        );
        assert_eq!(
            parse("label:Work"),
            [Term::In {
                place: Place::Named("Work".into()),
                negated: false
            }]
        );
        assert_eq!(
            parse("in:anywhere"),
            [Term::In {
                place: Place::Anywhere,
                negated: false
            }]
        );
        assert!(Query::parse("in:spam x", 0).spans_folders() && !Query::parse("x", 0).spans_folders());
        assert_eq!(parse("before:2025/01/31"), [Term::Before(1_738_281_600)]);
        assert_eq!(parse("after:2025-1-31"), [Term::After(1_738_281_600)]);
        assert_eq!(parse("older_than:2d"), [Term::Before(98 * DAY)]);
        assert_eq!(parse("newer_than:1m"), [Term::After(70 * DAY)]);
        assert_eq!(
            parse("larger:5M smaller:100k"),
            [Term::Larger(5 * 1024 * 1024), Term::Smaller(100 * 1024)]
        );
        // not an operator, or a value it does not take: words as typed
        assert_eq!(parse("http://example.com"), [words("http://example.com", Field::Any)]);
        assert_eq!(parse("is:banana"), [words("is:banana", Field::Any)]);
        assert_eq!(parse("before:yesterday"), [words("before:yesterday", Field::Any)]);
        assert_eq!(parse("from:"), [words("from:", Field::Any)]);
    }

    #[test]
    fn dates_and_sizes() {
        assert_eq!(date("1970/01/01"), Some(0));
        assert_eq!(date("2024/02/29"), Some(1_709_164_800));
        assert_eq!(date("2025/13/01"), None);
        assert_eq!(date("2025/01"), None);
        assert_eq!(age("10y"), Some(3650 * DAY));
        assert_eq!(age("x"), None);
        assert_eq!(bytes("2kb"), Some(2048));
        assert_eq!(bytes("1g"), Some(1 << 30));
        assert_eq!(bytes("lots"), None);
    }
}
