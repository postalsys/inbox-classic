//! Address headers: `"Name" <user@example.com>, group: a@b.c;`. A port of postal-mime's
//! address-parser.ts, which reads what mail software really sends: missing angle brackets,
//! comments, quoted local parts, display names with commas, encoded words. Works on chars, as the
//! original works on JavaScript string positions.

use super::strings::{decode_words, is_encoded_words_only};

/// One address, or a group of them
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParsedAddress {
    Mailbox {
        name: String,
        address: String,
    },
    Group {
        name: String,
        members: Vec<(String, String)>,
    },
}

impl ParsedAddress {
    pub fn name(&self) -> &str {
        match self {
            ParsedAddress::Mailbox { name, .. } | ParsedAddress::Group { name, .. } => name,
        }
    }

    /// The mailboxes, a group's members flattened
    pub fn mailboxes(&self) -> Vec<(String, String)> {
        match self {
            ParsedAddress::Mailbox { name, address } => vec![(name.clone(), address.clone())],
            ParsedAddress::Group { members, .. } => members.clone(),
        }
    }
}

const OPERATOR: u8 = 1;
const NO_BREAK: u8 = 2;
const DIRTY: u8 = 4;
const ESCAPES: u8 = 8;
const STARTS_ESCAPED: u8 = 16;

#[derive(Clone)]
struct Token {
    kind: u8,
    start: usize,
    end: usize,
    /// The value with escapes and control characters removed, for a dirty token
    cleaned: Option<String>,
}

struct Tokens<'a> {
    chars: &'a [char],
    list: Vec<Token>,
}

impl Tokens<'_> {
    fn operator(&self, i: usize) -> Option<char> {
        let token = &self.list[i];
        (token.kind & OPERATOR != 0).then(|| self.chars[token.start])
    }

    fn is_operator(&self, i: usize) -> bool {
        self.list[i].kind & OPERATOR != 0
    }

    fn no_break(&self, i: usize) -> bool {
        self.list[i].kind & NO_BREAK != 0
    }

    fn value(&self, i: usize) -> String {
        let token = &self.list[i];
        token
            .cleaned
            .clone()
            .unwrap_or_else(|| self.chars[token.start..token.end].iter().collect())
    }
}

fn is_space(c: char) -> bool {
    matches!(c as u32, 0x20 | 0x09..=0x0d | 0xa0 | 0x1680 | 0x2000..=0x200a | 0x2028 | 0x2029 | 0x202f | 0x205f | 0x3000 | 0xfeff)
}

fn is_word(c: Option<char>) -> bool {
    c.is_some_and(|c| c.is_ascii_alphanumeric() || c == '_')
}

/// A `\b` of JavaScript regular expressions at char position `at`
fn is_boundary(text: &[char], at: usize) -> bool {
    let before = at.checked_sub(1).and_then(|i| text.get(i).copied());
    is_word(before) != is_word(text.get(at).copied())
}

struct Tokenizer<'a> {
    chars: &'a [char],
    expecting: Option<char>,
    node: Option<usize>,
    escaped: bool,
    in_domain_literal: bool,
    after_at: bool,
    in_group: bool,
    inner_quoted: bool,
    inner_comment: u32,
    inner_literal: bool,
    inner_escaped: bool,
    list: Vec<Token>,
}

fn closer(c: char) -> Option<Option<char>> {
    match c {
        '"' => Some(Some('"')),
        '(' => Some(Some(')')),
        '<' => Some(Some('>')),
        ',' | ':' | ';' => Some(None),
        _ => None,
    }
}

impl<'a> Tokenizer<'a> {
    fn new(chars: &'a [char]) -> Self {
        Tokenizer {
            chars,
            expecting: None,
            node: None,
            escaped: false,
            in_domain_literal: false,
            after_at: false,
            in_group: false,
            inner_quoted: false,
            inner_comment: 0,
            inner_literal: false,
            inner_escaped: false,
            list: Vec::new(),
        }
    }

    fn push(&mut self, kind: u8, start: usize, end: usize) -> usize {
        self.list.push(Token {
            kind,
            start,
            end,
            cleaned: None,
        });
        self.list.len() - 1
    }

    fn close_text(&mut self, end: usize) {
        if let Some(node) = self.node.take() {
            self.list[node].end = end;
        }
    }

    fn reset_inner(&mut self) {
        self.inner_quoted = false;
        self.inner_comment = 0;
        self.inner_literal = false;
        self.inner_escaped = false;
    }

    fn tokenize(mut self) -> Tokens<'a> {
        for i in 0..self.chars.len() {
            self.check(self.chars[i], i);
        }
        self.close_text(self.chars.len());
        let chars = self.chars;
        let mut kept = Vec::with_capacity(self.list.len());
        for mut token in std::mem::take(&mut self.list) {
            if token.kind & DIRTY != 0 {
                let value = clean_value(chars, &token).trim().to_string();
                if value.is_empty() {
                    continue;
                }
                token.cleaned = Some(value);
            } else if token.kind & OPERATOR == 0 {
                while token.start < token.end && is_space(chars[token.start]) {
                    token.start += 1;
                }
                while token.end > token.start && is_space(chars[token.end - 1]) {
                    token.end -= 1;
                }
                if token.start == token.end {
                    continue;
                }
            }
            kept.push(token);
        }
        Tokens { chars, list: kept }
    }

    /// Inside `<...>`: quotes, comments and domain literals that may hold a `>` or `;`
    fn track_inner(&mut self, c: char) -> bool {
        if self.inner_escaped {
            self.inner_escaped = false;
            return true;
        }
        if self.inner_quoted {
            match c {
                '\\' => self.inner_escaped = true,
                '"' => self.inner_quoted = false,
                _ => {}
            }
            return true;
        }
        if self.inner_comment > 0 {
            match c {
                '\\' => self.inner_escaped = true,
                '(' => self.inner_comment += 1,
                ')' => self.inner_comment -= 1,
                _ => {}
            }
            return true;
        }
        if self.inner_literal {
            if c == ']' {
                self.inner_literal = false;
            }
            return true;
        }
        match c {
            '"' => {
                self.inner_quoted = true;
                return true;
            }
            '(' => {
                self.inner_comment = 1;
                return true;
            }
            '[' if self.after_at => {
                self.inner_literal = true;
                return true;
            }
            _ => {}
        }
        if !is_space(c) {
            self.after_at = c == '@';
        }
        false
    }

    fn check(&mut self, c: char, i: usize) {
        if !self.escaped && self.expecting.is_none() {
            if !self.in_domain_literal && c == '[' && self.after_at {
                self.in_domain_literal = true;
            } else if self.in_domain_literal && matches!(c, ']' | ',' | ';') {
                self.in_domain_literal = false;
            }
        }

        let mut nested = false;
        if self.expecting == Some('>') {
            nested = self.track_inner(c);
            if !nested && c == ';' && self.in_group {
                self.close_text(i);
                self.expecting = None;
                self.reset_inner();
            }
        } else if self.expecting == Some(')') && !self.escaped {
            if c == '(' {
                self.inner_comment += 1;
            } else if c == ')' && self.inner_comment > 0 {
                self.inner_comment -= 1;
                nested = true;
            }
        }

        if self.escaped {
            // the escaped character is text
        } else if self.expecting == Some(c) && !nested {
            let next = self.chars.get(i + 1).copied();
            self.close_text(i);
            let kind = match next {
                Some(n) if ![' ', '\t', '\r', '\n', ',', ';'].contains(&n) => OPERATOR | NO_BREAK,
                _ => OPERATOR,
            };
            self.push(kind, i, i + 1);
            if c != ')' {
                self.after_at = false;
            }
            self.expecting = None;
            self.escaped = false;
            self.reset_inner();
            return;
        } else if self.expecting.is_none()
            && !(self.in_domain_literal && c == ':')
            && let Some(closing) = closer(c)
        {
            self.close_text(i);
            self.push(OPERATOR, i, i + 1);
            if c == ':' {
                self.in_group = true;
            } else if c == ';' {
                self.in_group = false;
            }
            if c != '(' {
                self.after_at = false;
            }
            self.expecting = closing;
            self.escaped = false;
            self.reset_inner();
            return;
        } else if matches!(self.expecting, Some('"') | Some(')')) && c == '\\' {
            self.escaped = true;
            if let Some(node) = self.node {
                self.list[node].kind |= DIRTY;
            }
            return;
        }

        let node = match self.node {
            Some(node) => node,
            None => {
                let escapes = if matches!(self.expecting, Some('"') | Some(')')) {
                    ESCAPES
                } else {
                    0
                };
                let starts = if self.escaped { STARTS_ESCAPED } else { 0 };
                let node = self.push(escapes | starts, i, i);
                self.node = Some(node);
                node
            }
        };
        let c = if c == '\n' {
            self.list[node].kind |= DIRTY;
            ' '
        } else {
            c
        };
        if c as u32 >= 0x21 || c == ' ' || c == '\t' {
            if self.expecting.is_none() && c != ' ' && c != '\t' {
                self.after_at = c == '@';
            }
        } else {
            self.list[node].kind |= DIRTY;
        }
        self.escaped = false;
    }
}

fn clean_value(chars: &[char], token: &Token) -> String {
    let escapes = token.kind & ESCAPES != 0;
    let mut escaped = token.kind & STARTS_ESCAPED != 0;
    let mut value = String::new();
    for &c in &chars[token.start..token.end] {
        if escapes && !escaped && c == '\\' {
            escaped = true;
            continue;
        }
        escaped = false;
        if c == '\n' {
            value.push(' ');
        } else if c as u32 >= 0x21 || c == ' ' || c == '\t' {
            value.push(c);
        }
    }
    value
}

#[derive(Default)]
struct Parts {
    address: Vec<String>,
    comment: Vec<String>,
    text: Vec<String>,
    text_was_quoted: Vec<bool>,
    quoted_local_at: Vec<Option<usize>>,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum State {
    Text,
    Address,
    Comment,
}

impl Parts {
    fn list(&mut self, state: State) -> &mut Vec<String> {
        match state {
            State::Text => &mut self.text,
            State::Address => &mut self.address,
            State::Comment => &mut self.comment,
        }
    }
}

fn collect_parts(tokens: &Tokens, from: usize, to: usize) -> (Parts, bool) {
    let mut state = State::Text;
    let mut data = Parts::default();
    let mut last_text_pure_quoted = false;
    let mut inside_quotes = false;
    let mut last_chars = [None::<char>; 3];
    let slot = |s: State| s as usize;
    for i in from..to {
        let value = tokens.value(i);
        let prev_operator = if i > from { tokens.operator(i - 1) } else { None };
        let prev_no_break = i > from && tokens.no_break(i - 1);
        if tokens.is_operator(i) {
            match value.as_str() {
                "<" => {
                    state = State::Address;
                    inside_quotes = false;
                }
                "(" => {
                    state = State::Comment;
                    inside_quotes = false;
                }
                "\"" => {
                    inside_quotes = !inside_quotes;
                    state = State::Text;
                }
                _ => {
                    state = State::Text;
                    inside_quotes = false;
                }
            }
            continue;
        }
        let opens_after_empty_quoted =
            prev_operator == Some('"') && prev_no_break && i > from + 1 && tokens.operator(i - 2) == Some('"');
        let first = value.chars().next();
        let joins = prev_no_break
            && !data.list(state).is_empty()
            && (prev_operator != Some(')') || last_chars[slot(state)] == Some('@') || first == Some('@'));
        if joins {
            let last = data.list(state).len() - 1;
            if state == State::Text && !inside_quotes {
                if last_text_pure_quoted && first == Some('@') {
                    data.quoted_local_at[last] = Some(data.text[last].chars().count());
                }
                last_text_pure_quoted = false;
            }
            data.list(state)[last].push_str(&value);
            if state == State::Text && inside_quotes {
                data.text_was_quoted[last] = true;
            }
        } else {
            data.list(state).push(value.clone());
            if state == State::Text {
                data.text_was_quoted.push(inside_quotes || opens_after_empty_quoted);
                data.quoted_local_at
                    .push((opens_after_empty_quoted && first == Some('@')).then_some(0));
                last_text_pure_quoted = inside_quotes;
            }
        }
        last_chars[slot(state)] = value.chars().last();
    }
    let mut text_from_comment = false;
    if data.text.is_empty() && !data.comment.is_empty() {
        data.text = std::mem::take(&mut data.comment);
        text_from_comment = true;
    }
    (data, text_from_comment)
}

fn has_whitespace(value: &str) -> bool {
    value.chars().any(char::is_whitespace)
}

/// `user@host` without white space, or with a domain literal
fn is_addr_spec(value: &str) -> bool {
    let Some(at) = value.find('@') else { return false };
    let (local, domain) = (&value[..at], &value[at + 1..]);
    let plain = |s: &str| !s.is_empty() && !s.contains('@') && !has_whitespace(s);
    if plain(local) && plain(domain) {
        return true;
    }
    plain(local)
        && domain.starts_with('[')
        && domain.ends_with(']')
        && !domain[1..domain.len() - 1]
            .chars()
            .any(|c| matches!(c, '[' | ']' | '\\') || c.is_whitespace())
}

/// `user@...` with anything but white space after the `@`
fn is_loose_addr_spec(value: &str) -> bool {
    let Some(at) = value.find('@') else { return false };
    let local = &value[..at];
    !local.is_empty() && !has_whitespace(local) && !value[at + 1..].is_empty() && !has_whitespace(&value[at + 1..])
}

/// Where the domain of an address starts, the `@` before a trailing domain literal if any
fn domain_at(address: &str) -> Option<usize> {
    if address.ends_with(']')
        && let Some(open) = address.rfind("@[")
        && !address[open + 2..address.len() - 1].contains(['[', ']', '\\'])
    {
        return Some(open);
    }
    address.rfind('@')
}

fn is_quoted_string(value: &str) -> bool {
    quoted_prefix_len(value) == Some(value.len())
}

/// The length of a quoted string at the start, `"a\"b"`
fn quoted_prefix_len(value: &str) -> Option<usize> {
    let mut chars = value.char_indices();
    if chars.next()?.1 != '"' {
        return None;
    }
    let mut escaped = false;
    for (i, c) in chars {
        if escaped {
            escaped = false;
        } else if c == '\\' {
            escaped = true;
        } else if c == '"' {
            return Some(i + 1);
        }
    }
    None
}

fn quote_local_part(address: &str) -> String {
    let Some(at) = domain_at(address) else {
        return address.to_string();
    };
    let user = &address[..at];
    let atom = !user.is_empty() && !user.chars().any(|c| c.is_whitespace() || "\"(),:;<>@[\\]".contains(c));
    if atom || is_quoted_string(user) {
        return address.to_string();
    }
    let escaped: String = user
        .chars()
        .flat_map(|c| if c == '"' || c == '\\' { vec!['\\', c] } else { vec![c] })
        .collect();
    format!("\"{escaped}\"@{}", &address[at + 1..])
}

fn join_at_spacing(value: &str, at: Option<usize>) -> String {
    let Some(at) = at else { return value.to_string() };
    let chars: Vec<char> = value.chars().collect();
    let at = value[..at].chars().count();
    let mut start = at;
    while start > 0 && is_space(chars[start - 1]) {
        start -= 1;
    }
    let mut end = at + 1;
    while end < chars.len() && is_space(chars[end]) {
        end += 1;
    }
    if start == at && end == at + 1 {
        return value.to_string();
    }
    let mut out: String = chars[..start].iter().collect();
    out.push('@');
    out.extend(&chars[end..]);
    out
}

fn collapse_at_spacing(value: &str) -> String {
    if let Some(quoted) = quoted_prefix_len(value) {
        let rest = &value[quoted..];
        let skipped = rest.len() - rest.trim_start_matches(is_space).len();
        let at = quoted + skipped;
        if value[at..].starts_with('@') && !value[at + 1..].contains('@') {
            return join_at_spacing(value, Some(at));
        }
    }
    let Some(at) = value.find('@') else {
        return value.to_string();
    };
    if value[at + 1..].contains('@') || value.rfind('"').is_some_and(|q| q > at) {
        return value.to_string();
    }
    join_at_spacing(value, Some(at))
}

/// Where an address starts inside free text, "write to me@example.com today"
fn loose_address_start(text: &[char]) -> Option<usize> {
    let len = text.len();
    let mut pos = 0;
    let at_in = |from: usize, to: usize| (from..to).find(|&i| text[i] == '@');
    while pos < len {
        while pos < len && is_space(text[pos]) {
            pos += 1;
        }
        if pos >= len {
            break;
        }
        let run_start = pos;
        let mut run_end = pos;
        while run_end < len && !is_space(text[run_end]) {
            run_end += 1;
        }
        let mut at = at_in(run_start, run_end);
        if at.is_some() {
            let last_boundary = (run_start + 1..=run_end).rev().find(|&k| is_boundary(text, k));
            let mut atom_start = run_start;
            while let (Some(boundary), Some(a)) = (last_boundary, at) {
                if a > atom_start && run_end > a + 1 && boundary > a + 1 {
                    for start in atom_start..a {
                        if is_boundary(text, start) {
                            if start > run_start {
                                return Some(start);
                            }
                            let mut padded = run_start;
                            while padded > 0 && is_space(text[padded - 1]) {
                                padded -= 1;
                            }
                            return Some(padded);
                        }
                    }
                }
                atom_start = a + 1;
                at = at_in(atom_start, run_end);
            }
        }
        pos = run_end;
    }
    None
}

/// `\s*\b[^@\s]+@[^\s]+\b\s*` matched at `start`
fn loose_text_address(text: &[char], start: usize) -> Option<usize> {
    let mut i = start;
    while i < text.len() && text[i].is_whitespace() {
        i += 1;
    }
    if !is_boundary(text, i) {
        return None;
    }
    let local_start = i;
    while i < text.len() && text[i] != '@' && !text[i].is_whitespace() {
        i += 1;
    }
    if i == local_start || text.get(i) != Some(&'@') {
        return None;
    }
    i += 1;
    let domain_start = i;
    while i < text.len() && !text[i].is_whitespace() {
        i += 1;
    }
    // backtrack to a word boundary, as the greedy [^\s]+ followed by \b does
    let mut end = i;
    while end > domain_start && !is_boundary(text, end) {
        end -= 1;
    }
    if end == domain_start {
        return None;
    }
    let mut stop = end;
    while stop < text.len() && text[stop].is_whitespace() {
        stop += 1;
    }
    Some(stop)
}

/// An address with words around it: the address, the words going to the name
fn recover_addr_spec(address: &str, text: &str) -> (String, String) {
    let address = collapse_at_spacing(address);
    if !has_whitespace(&address) {
        return (address, text.to_string());
    }
    let rest: Vec<String>;
    let found: String;
    if let Some(quoted) = quoted_prefix_len(&address)
        && address[quoted..].starts_with('@')
    {
        let after = &address[quoted + 1..];
        let domain_end = after.find(char::is_whitespace).unwrap_or(after.len());
        if domain_end == 0 {
            return (address.clone(), text.to_string());
        }
        let tail = after[domain_end..].trim_start();
        if tail.is_empty() {
            return (address.clone(), text.to_string());
        }
        found = address[..quoted + 1 + domain_end].to_string();
        rest = vec![tail.to_string()];
    } else {
        if address.contains('"') {
            return (address.clone(), text.to_string());
        }
        let mut parts: Vec<String> = address.split_whitespace().map(str::to_string).collect();
        let index = parts
            .iter()
            .position(|p| is_addr_spec(p))
            .or_else(|| parts.iter().position(|p| is_loose_addr_spec(p)));
        let Some(index) = index else {
            return (address.clone(), text.to_string());
        };
        found = parts.remove(index);
        rest = parts;
    }
    let words: Vec<&str> = std::iter::once(text)
        .chain(rest.iter().map(String::as_str))
        .filter(|p| !p.is_empty())
        .collect();
    (found, words.join(" "))
}

/// Comments of an address taken out: `user(comment)@host` gives `user@host` and `comment`
fn strip_address_comments(address: &str) -> (String, Vec<String>) {
    let chars: Vec<char> = address.chars().collect();
    let mut comments = Vec::new();
    let mut result = String::new();
    let mut comment = String::new();
    let mut depth = 0;
    let mut closer: Option<char> = None;
    let mut last = None::<char>;
    let mut pending_space = false;
    let mut first = None::<char>;
    let mut quote_seen = false;
    let mut route_end: Option<usize> = None;
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        if depth > 0 {
            if c == '\\' && i + 1 < chars.len() {
                i += 1;
                comment.push(chars[i]);
            } else if c == '(' {
                depth += 1;
                comment.push(c);
            } else if c == ')' {
                depth -= 1;
                if depth == 0 {
                    comments.push(comment.trim().to_string());
                    comment.clear();
                    pending_space = last != Some('@');
                } else {
                    comment.push(c);
                }
            } else {
                comment.push(c);
            }
            i += 1;
            continue;
        }
        if pending_space && c != '(' {
            pending_space = false;
            if c != '@' && c != '<' && !is_space(c) {
                result.push(' ');
                last = Some(' ');
            }
        }
        match closer {
            Some(close) => {
                if c == '\\' && close == '"' && i + 1 < chars.len() {
                    result.push(c);
                    i += 1;
                    result.push(chars[i]);
                    last = Some(chars[i]);
                    i += 1;
                    continue;
                }
                if c == close {
                    closer = None;
                }
            }
            None => match c {
                '"' => {
                    closer = Some('"');
                    quote_seen = true;
                }
                ':' if route_end.is_none() && first == Some('@') && !quote_seen => {
                    route_end = Some(result.chars().count() + 1);
                }
                '[' => closer = Some(']'),
                '(' => {
                    depth = 1;
                    i += 1;
                    continue;
                }
                '<' => {
                    result.clear();
                    last = None;
                    comments.clear();
                    first = None;
                    quote_seen = false;
                    route_end = None;
                    i += 1;
                    continue;
                }
                _ => {}
            },
        }
        result.push(c);
        last = Some(c);
        if first.is_none() && !is_space(c) {
            first = Some(c);
        }
        i += 1;
    }
    if let Some(end) = route_end {
        let tail: String = result.chars().skip(end).collect();
        if tail.contains('@') {
            result = tail;
        }
    }
    if depth > 0 {
        comments.push(comment.trim().to_string());
    }
    comments.retain(|c| !c.is_empty());
    (result.trim().to_string(), comments)
}

fn group_name(tokens: &Tokens, from: usize, to: usize) -> String {
    decode_words(&collect_parts(tokens, from, to).0.text.join(" "))
}

/// `@domain` or `@[literal]`
fn is_quoted_local_domain(value: &str) -> bool {
    let Some(domain) = value.strip_prefix('@') else {
        return false;
    };
    if let Some(literal) = domain.strip_prefix('[').and_then(|d| d.strip_suffix(']')) {
        return !literal
            .chars()
            .any(|c| matches!(c, '[' | ']' | '\\') || c.is_whitespace());
    }
    !domain.is_empty() && !domain.chars().any(|c| c == '@' || c == '"' || c.is_whitespace())
}

fn handle_address(tokens: &Tokens, from: usize, to: usize) -> (String, String) {
    let (mut data, mut text_from_comment) = collect_parts(tokens, from, to);
    let mut address_comments = Vec::new();
    let mut address_parts = Vec::new();
    for part in &data.address {
        let (stripped, comments) = strip_address_comments(part);
        address_comments.extend(comments);
        if !stripped.is_empty() {
            address_parts.push(stripped);
        }
    }
    data.address = address_parts;

    if data.address.is_empty() && !data.text.is_empty() && !text_from_comment {
        find_address_in_text(&mut data);
    }
    if data.text.is_empty() && !data.comment.is_empty() {
        data.text = std::mem::take(&mut data.comment);
    }
    if data.address.len() > 1 {
        let extra = data.address.split_off(1);
        data.text.extend(extra);
    }

    let address_from_quoted_text = data.address.is_empty() && data.text_was_quoted.iter().any(|q| *q);
    let mut text = data.text.join(" ");
    let mut address = data.address.join(" ");
    if address.is_empty() && is_encoded_words_only(text.trim()) {
        return (decode_words(&text), String::new());
    }
    if address_from_quoted_text && text.contains('@') {
        address = quote_local_part(&join_at_spacing(&text, domain_at(&text)));
        text.clear();
    }
    (address, text) = recover_addr_spec(&address, &text);
    if text.is_empty() && !address_comments.is_empty() {
        text = address_comments.join(" ");
        text_from_comment = true;
    }
    let raw_name = if !text.is_empty() {
        text.clone()
    } else {
        address.clone()
    };
    let mut address = if !address.is_empty() {
        address
    } else if text_from_comment {
        String::new()
    } else {
        text
    };
    let mut name = decode_words(&raw_name);
    if address == raw_name || address == name {
        if address.contains('@') {
            name.clear();
        } else {
            address.clear();
        }
    }
    (name, address)
}

/// No angle brackets: an address in the text, a quoted local part, or a loose one in words
fn find_address_in_text(data: &mut Parts) {
    let candidates: Vec<String> = data.text.iter().map(|p| collapse_at_spacing(p)).collect();
    for (i, candidate) in candidates.iter().enumerate() {
        let quoted_local = match data.quoted_local_at[i] {
            Some(local) if data.text_was_quoted[i] => {
                let tail: String = data.text[i].chars().skip(local).collect();
                if is_quoted_local_domain(&tail) {
                    quote_local_part(&data.text[i])
                } else {
                    String::new()
                }
            }
            _ => String::new(),
        };
        if !quoted_local.is_empty() || (!data.text_was_quoted[i] && is_addr_spec(candidate)) {
            data.address = vec![if quoted_local.is_empty() {
                candidate.clone()
            } else {
                quoted_local
            }];
            data.text.remove(i);
            data.text_was_quoted.remove(i);
            data.quoted_local_at.remove(i);
            return;
        }
    }
    for (i, candidate) in candidates.iter().enumerate() {
        if data.text_was_quoted[i] {
            continue;
        }
        let part: Vec<char> = candidate.chars().collect();
        if let Some(start) = loose_address_start(&part)
            && let Some(end) = loose_text_address(&part, start)
        {
            let matched: String = part[start..end].iter().collect();
            data.address = vec![matched.trim().to_string()];
            let before: String = part[..start].iter().collect();
            let after: String = part[end..].iter().collect();
            data.text[i] = format!("{before} {after}").trim().to_string();
            return;
        }
        data.text[i] = data.text[i].trim().to_string();
    }
}

/// A name without an address followed by an address with a name: the comma was in the name
fn merge_name_fragments(list: Vec<ParsedAddress>) -> Vec<ParsedAddress> {
    let mut merged: Vec<ParsedAddress> = Vec::new();
    for current in list.into_iter().rev() {
        if let ParsedAddress::Mailbox { name, address } = &current
            && address.is_empty()
            && !name.is_empty()
            && let Some(ParsedAddress::Mailbox {
                name: next_name,
                address: next_address,
            }) = merged.last_mut()
            && !next_address.is_empty()
            && !next_name.is_empty()
        {
            *next_name = format!("{name}, {next_name}");
            continue;
        }
        merged.push(current);
    }
    merged.reverse();
    merged
}

/// Parses an address list header value
pub fn parse_addresses(value: &str) -> Vec<ParsedAddress> {
    let chars: Vec<char> = value.chars().collect();
    let tokens = Tokenizer::new(&chars).tokenize();
    let mut parsed = Vec::new();
    let mut group: Option<String> = None;
    let mut members: Vec<ParsedAddress> = Vec::new();
    let mut from = 0;
    let len = tokens.list.len();
    for i in 0..=len {
        let operator = if i < len { tokens.operator(i) } else { None };
        if i < len && !matches!(operator, Some(',' | ';' | ':')) {
            continue;
        }
        if operator == Some(':') {
            if group.is_none() {
                group = Some(group_name(&tokens, from, i));
                members.clear();
            }
            from = i + 1;
            continue;
        }
        if i > from {
            let (name, address) = handle_address(&tokens, from, i);
            let mailbox = ParsedAddress::Mailbox { name, address };
            if group.is_some() {
                members.push(mailbox)
            } else {
                parsed.push(mailbox)
            }
        }
        from = i + 1;
        if group.is_some() && (operator == Some(';') || i == len) {
            let members = merge_name_fragments(std::mem::take(&mut members))
                .into_iter()
                .flat_map(|m| m.mailboxes())
                .collect();
            parsed.push(ParsedAddress::Group {
                name: group.take().unwrap_or_default(),
                members,
            });
        }
    }
    merge_name_fragments(parsed)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mailbox(name: &str, address: &str) -> ParsedAddress {
        ParsedAddress::Mailbox {
            name: name.into(),
            address: address.into(),
        }
    }

    #[test]
    fn common_forms() {
        assert_eq!(
            parse_addresses("andris@example.com"),
            vec![mailbox("", "andris@example.com")]
        );
        assert_eq!(
            parse_addresses("Andris <andris@example.com>"),
            vec![mailbox("Andris", "andris@example.com")]
        );
        assert_eq!(
            parse_addresses("\"Reinman, Andris\" <a@b.c>, d@e.f"),
            vec![mailbox("Reinman, Andris", "a@b.c"), mailbox("", "d@e.f")]
        );
        assert_eq!(parse_addresses("a@b.c (Andris)"), vec![mailbox("Andris", "a@b.c")]);
        assert_eq!(
            parse_addresses("=?UTF-8?Q?J=C3=B5ul?= <j@x.ee>"),
            vec![mailbox("Jõul", "j@x.ee")]
        );
        assert_eq!(
            parse_addresses("Team: a@b.c, Bob <d@e.f>;"),
            vec![ParsedAddress::Group {
                name: "Team".into(),
                members: vec![(String::new(), "a@b.c".into()), ("Bob".into(), "d@e.f".into())]
            }]
        );
        assert_eq!(
            parse_addresses("undisclosed-recipients:;"),
            vec![ParsedAddress::Group {
                name: "undisclosed-recipients".into(),
                members: vec![]
            }]
        );
        assert_eq!(parse_addresses(""), vec![]);
    }
}
