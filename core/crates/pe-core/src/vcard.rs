//! vCard (RFC 2426, 3.0, and RFC 6350, 4.0) and CSV files of address books, read into cards and written out again.
//! What a card here does not edit (birthdays, postal addresses, photos, ...) is kept as its vCard lines and written out
//! as it came; nothing a file names is fetched (a PHOTO given by URL stays a line of text).

use pe_store::Card;

use crate::contentline::{has_type, split, unescape, unfold};

/// The most a file of cards may be, and how many cards it may hold: an address book, not anything bigger
pub const MAX_FILE: usize = 16 * 1024 * 1024;
pub const MAX_CARDS: usize = 50_000;

/// A value escaped for a vCard line
fn escape(value: &str) -> String {
    let mut out = String::with_capacity(value.len());
    for c in value.chars() {
        match c {
            '\\' => out.push_str("\\\\"),
            ',' => out.push_str("\\,"),
            ';' => out.push_str("\\;"),
            '\n' => out.push_str("\\n"),
            '\r' => {}
            other => out.push(other),
        }
    }
    out
}

/// The parts of a structured value (`N:Smith;Mary;;;`), split at `;` not escaped
fn parts(value: &str) -> Vec<String> {
    let mut found = Vec::new();
    let mut current = String::new();
    let mut chars = value.chars();
    while let Some(c) = chars.next() {
        match c {
            '\\' => {
                current.push(c);
                if let Some(next) = chars.next() {
                    current.push(next);
                }
            }
            ';' => found.push(unescape(&std::mem::take(&mut current))),
            other => current.push(other),
        }
    }
    found.push(unescape(&current));
    found
}

/// The cards of a vCard file; a card without a name or an address is left out
pub fn read_vcards(text: &str) -> Vec<Card> {
    let mut cards = Vec::new();
    let mut card: Option<Card> = None;
    for line in unfold(text) {
        let Some((name, parameters, value)) = split(&line) else {
            continue;
        };
        let value = value.as_str();
        match name.as_str() {
            "BEGIN" if value.eq_ignore_ascii_case("VCARD") => card = Some(Card::default()),
            "END" if value.eq_ignore_ascii_case("VCARD") => {
                if let Some(done) = card.take()
                    && (!done.name.is_empty() || !done.addresses.is_empty())
                {
                    cards.push(done);
                    if cards.len() >= MAX_CARDS {
                        break;
                    }
                }
            }
            _ => {
                let Some(card) = card.as_mut() else { continue };
                match name.as_str() {
                    "FN" => card.name = unescape(value),
                    "N" => {
                        let n = parts(value);
                        card.last = n.first().cloned().unwrap_or_default();
                        card.first = n.get(1).cloned().unwrap_or_default();
                    }
                    "NICKNAME" => card.nickname = unescape(value),
                    "ORG" => card.company = parts(value).into_iter().next().unwrap_or_default(),
                    "NOTE" => card.notes = unescape(value),
                    "EMAIL" => {
                        let address = unescape(value).trim().to_string();
                        // the preferred one first
                        if has_type(&parameters, "PREF") {
                            card.addresses.insert(0, address);
                        } else {
                            card.addresses.push(address);
                        }
                    }
                    "TEL" => {
                        let kind = ["CELL", "HOME", "WORK"]
                            .into_iter()
                            .find(|kind| has_type(&parameters, kind))
                            .unwrap_or("")
                            .to_ascii_lowercase();
                        card.phones.push((kind, unescape(value).trim().to_string()));
                    }
                    "VERSION" | "PRODID" | "UID" | "REV" => {}
                    _ => {
                        // kept as it came, without what could end the line or the card where it is written again
                        card.extra.extend(line.chars().filter(|c| !c.is_control()));
                        card.extra.push('\n');
                    }
                }
            }
        }
    }
    cards
}

/// A vCard line, folded at 75 bytes as the standard has it (a fold never inside a character)
fn folded(line: &str) -> String {
    let mut out = String::new();
    let mut width = 0;
    for c in line.chars() {
        if width + c.len_utf8() > 75 {
            out.push_str("\r\n ");
            width = 1;
        }
        out.push(c);
        width += c.len_utf8();
    }
    out.push_str("\r\n");
    out
}

/// Cards as a vCard 3.0 file
pub fn write_vcards(cards: &[Card]) -> String {
    let mut out = String::new();
    for card in cards {
        out.push_str("BEGIN:VCARD\r\nVERSION:3.0\r\n");
        out.push_str(&folded(&format!("FN:{}", escape(&card.name))));
        out.push_str(&folded(&format!("N:{};{};;;", escape(&card.last), escape(&card.first))));
        if !card.nickname.is_empty() {
            out.push_str(&folded(&format!("NICKNAME:{}", escape(&card.nickname))));
        }
        if !card.company.is_empty() {
            out.push_str(&folded(&format!("ORG:{}", escape(&card.company))));
        }
        for (at, address) in card.addresses.iter().enumerate() {
            let preferred = if at == 0 {
                ";TYPE=INTERNET,PREF"
            } else {
                ";TYPE=INTERNET"
            };
            out.push_str(&folded(&format!("EMAIL{preferred}:{}", escape(address))));
        }
        for (kind, number) in &card.phones {
            let kind = if kind.is_empty() {
                String::new()
            } else {
                format!(";TYPE={}", kind.to_ascii_uppercase())
            };
            out.push_str(&folded(&format!("TEL{kind}:{}", escape(number))));
        }
        if !card.notes.is_empty() {
            out.push_str(&folded(&format!("NOTE:{}", escape(&card.notes))));
        }
        for line in card.extra.lines().filter(|l| !l.is_empty()) {
            let line: String = line.chars().filter(|c| !c.is_control()).collect();
            out.push_str(&folded(&line));
        }
        out.push_str("END:VCARD\r\n");
    }
    out
}

/// The fields of a CSV line: commas, double quotes around a field that has them (`""` for a quote in it), a line
/// break inside quotes kept
fn csv_records(text: &str) -> Vec<Vec<String>> {
    let mut records = Vec::new();
    let mut record = Vec::new();
    let mut field = String::new();
    let mut quoted = false;
    let mut chars = text.trim_start_matches('\u{feff}').chars().peekable();
    while let Some(c) = chars.next() {
        match (c, quoted) {
            ('"', true) if chars.peek() == Some(&'"') => {
                chars.next();
                field.push('"');
            }
            ('"', _) => quoted = !quoted,
            (',' | ';' | '\t', false) => record.push(std::mem::take(&mut field)),
            ('\r', false) => {}
            ('\n', false) => {
                record.push(std::mem::take(&mut field));
                records.push(std::mem::take(&mut record));
            }
            (other, _) => field.push(other),
        }
    }
    if !field.is_empty() || !record.is_empty() {
        record.push(field);
        records.push(record);
    }
    records
}

/// The cards of a CSV file whose first line names its columns, as Outlook, Thunderbird and Google export them (and
/// the obvious names otherwise); a row without a name or an address is left out
pub fn read_csv(text: &str) -> Vec<Card> {
    let mut records = csv_records(text).into_iter();
    let Some(header) = records.next() else {
        return Vec::new();
    };
    let header: Vec<String> = header.iter().map(|h| h.trim().to_ascii_lowercase()).collect();
    let column = |names: &[&str]| header.iter().position(|h| names.contains(&h.as_str()));
    let display = column(&["display name", "name", "full name"]);
    let first = column(&["first name", "given name"]);
    let last = column(&["last name", "family name", "surname"]);
    let nickname = column(&["nickname", "nick name"]);
    let company = column(&["company", "organization", "organization 1 - name", "organisation"]);
    let notes = column(&["notes", "note"]);
    let emails: Vec<usize> = header
        .iter()
        .enumerate()
        .filter(|(_, h)| {
            matches!(
                h.as_str(),
                "e-mail address"
                    | "e-mail 2 address"
                    | "e-mail 3 address"
                    | "primary email"
                    | "secondary email"
                    | "email"
                    | "email address"
                    | "e-mail"
            ) || (h.starts_with("e-mail ") && h.ends_with(" - value"))
        })
        .map(|(at, _)| at)
        .collect();
    let phones: Vec<(usize, &str)> = header
        .iter()
        .enumerate()
        .filter_map(|(at, h)| {
            let kind = match h.as_str() {
                "mobile phone" | "mobile number" | "cellular number" => "cell",
                "home phone" | "home phone 2" => "home",
                "business phone" | "business phone 2" | "work phone" => "work",
                h if h.starts_with("phone ") && h.ends_with(" - value") => "",
                _ => return None,
            };
            Some((at, kind))
        })
        .collect();
    let mut cards = Vec::new();
    for record in records.take(MAX_CARDS) {
        let field = |at: Option<usize>| {
            at.and_then(|at| record.get(at))
                .map(|v| v.trim().to_string())
                .unwrap_or_default()
        };
        let mut card = Card {
            first: field(first),
            last: field(last),
            nickname: field(nickname),
            company: field(company),
            notes: field(notes),
            ..Default::default()
        };
        card.name = field(display);
        if card.name.is_empty() {
            card.name = format!("{} {}", card.first, card.last).trim().to_string();
        }
        for &at in &emails {
            // Google puts several in one field, separated by " ::: "
            for address in field(Some(at)).split(":::") {
                let address = address.trim();
                if address.contains('@') {
                    card.addresses.push(address.to_string());
                }
            }
        }
        for &(at, kind) in &phones {
            let number = field(Some(at));
            if !number.is_empty() {
                card.phones.push((kind.to_string(), number));
            }
        }
        if !card.name.is_empty() || !card.addresses.is_empty() {
            cards.push(card);
        }
    }
    cards
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_vcards_of_other_programs() {
        // Apple Contacts and Thunderbird: folded lines, groups, escapes, a preferred address, a photo by URL
        let text = "BEGIN:VCARD\r\nVERSION:3.0\r\nN:Smith;Mary;;;\r\nFN:Mary Smith\r\nORG:Acme\\, Inc.;Sales\r\n\
                    item1.EMAIL;type=INTERNET:mary@home.example\r\nEMAIL;type=INTERNET;type=pref:mary@acme.example\r\n\
                    TEL;type=CELL:+1 555\r\n 0100\r\nNOTE:Line one\\nline two\r\nBDAY:1990-01-02\r\n\
                    PHOTO;VALUE=uri:https://tracker.example/p.jpg\r\nEND:VCARD\r\n\
                    BEGIN:VCARD\nVERSION:4.0\nFN:No Address\nEND:VCARD\nBEGIN:VCARD\nEND:VCARD\n";
        let cards = read_vcards(text);
        assert_eq!(cards.len(), 2, "the empty card left out");
        let mary = &cards[0];
        assert_eq!(
            (mary.name.as_str(), mary.first.as_str(), mary.last.as_str()),
            ("Mary Smith", "Mary", "Smith")
        );
        assert_eq!(mary.company, "Acme, Inc.");
        assert_eq!(
            mary.addresses,
            ["mary@acme.example", "mary@home.example"],
            "the preferred first"
        );
        assert_eq!(mary.phones, [("cell".to_string(), "+1 5550100".to_string())]);
        assert_eq!(mary.notes, "Line one\nline two");
        assert!(
            mary.extra.contains("BDAY:1990-01-02") && mary.extra.contains("PHOTO;VALUE=uri"),
            "kept as lines"
        );
    }

    #[test]
    fn writes_what_it_reads() {
        let card = Card {
            name: "Jüri Õun; the second".into(),
            first: "Jüri".into(),
            last: "Õun".into(),
            nickname: "J".into(),
            company: "Õunad OÜ".into(),
            notes: "A long note that goes on and on, with commas, and; semicolons, past the width of a line.".into(),
            addresses: vec!["juri@example.ee".into(), "j@work.example".into()],
            phones: vec![("work".into(), "+372 555".into())],
            extra: "BDAY:2000-01-01\n".into(),
            ..Default::default()
        };
        let text = write_vcards(std::slice::from_ref(&card));
        assert!(text.lines().all(|line| line.len() <= 76), "folded");
        let back = read_vcards(&text);
        assert_eq!(back, [card]);
    }

    #[test]
    fn reads_csv_of_outlook_thunderbird_and_google() {
        let outlook = "First Name,Last Name,E-mail Address,Mobile Phone,Notes\r\nMary,Smith,mary@example.com,555,\"Said \"\"hi\"\", then left\"\r\n";
        let cards = read_csv(outlook);
        assert_eq!(cards[0].name, "Mary Smith");
        assert_eq!(cards[0].phones, [("cell".to_string(), "555".to_string())]);
        assert_eq!(cards[0].notes, "Said \"hi\", then left");
        let thunderbird = "First Name,Last Name,Display Name,Nickname,Primary Email,Secondary Email\n,,The Team,team,team@example.org,\n";
        assert_eq!(read_csv(thunderbird)[0].addresses, ["team@example.org"]);
        let google = "Name,Given Name,E-mail 1 - Type,E-mail 1 - Value\nAnn Example,Ann,* Home,ann@example.com ::: ann@work.example\n";
        assert_eq!(read_csv(google)[0].addresses, ["ann@example.com", "ann@work.example"]);
        assert!(read_csv("no,header\n,\n").is_empty());
    }
}
