//! Parses one framed response line (see `framing`) into a [`Response`]. A port of imapflow's
//! `imap-parser.ts`, `parser-instance.ts` and `token-parser.ts`, on bytes, with the same
//! tolerance for the ways real servers break the grammar and the same limits against hostile
//! ones. The tokenizer is iterative; only the conversion of its tree into tokens recurses, and
//! that is bounded by [`MAX_DEPTH`].

use crate::error::ParseError;
use crate::framing::RawResponse;
use crate::syntax::{is_atom_char, is_command_char, is_space, is_status_command, is_tag_char, trim};
use crate::types::{Atom, Response, Token};

/// Deepest nesting of lists and sections. A message can nest its MIME parts as deep as its
/// sender likes, so a FETCH data item that goes deeper is replaced by NIL instead of failing the
/// whole row; anything else that does fails to parse.
pub const MAX_DEPTH: u32 = 100;

/// The depth of the data items of a FETCH response: the tree, the item list, a key or value
const FETCH_DATA_ITEM_DEPTH: u32 = 2;

/// Default for [`ParserOptions::max_tokens`]
pub const MAX_RESPONSE_TOKENS: usize = 1_000_000;

#[derive(Debug, Clone, Copy)]
pub struct ParserOptions {
    /// Most parse tree nodes one response may produce. Every token costs memory far beyond its
    /// size on the wire, so this bounds what a server can make one line cost.
    pub max_tokens: usize,
}

impl Default for ParserOptions {
    fn default() -> Self {
        ParserOptions {
            max_tokens: MAX_RESPONSE_TOKENS,
        }
    }
}

impl RawResponse {
    /// Parses this response with the default limits
    pub fn parse(self) -> Result<Response, ParseError> {
        parse_with(&self.line, self.literals, &ParserOptions::default())
    }

    pub fn parse_with(self, options: &ParserOptions) -> Result<Response, ParseError> {
        parse_with(&self.line, self.literals, options)
    }
}

/// Parses a framed line with its literals, using the default limits.
pub fn parse(line: &[u8], literals: Vec<Vec<u8>>) -> Result<Response, ParseError> {
    parse_with(line, literals, &ParserOptions::default())
}

pub fn parse_with(line: &[u8], literals: Vec<Vec<u8>>, options: &ParserOptions) -> Result<Response, ParseError> {
    let bad = |attributes| Response {
        tag: "*".into(),
        command: "BAD".into(),
        attributes,
        ..Default::default()
    };

    // Some servers pad their lines with leading NUL bytes
    let null_bytes = line.iter().take_while(|c| **c == 0).count();
    if null_bytes > 0 && null_bytes == line.len() {
        return Ok(bad(Vec::new()));
    }
    let input = &line[null_bytes..];

    // Exchange sometimes answers with "Server Unavailable." instead of a response
    if let Some(rest) = input.strip_prefix(b"Server Unavailable.")
        && rest.first().is_none_or(|c| is_space(*c))
    {
        return Ok(bad(vec![Token::Text(input.to_vec())]));
    }

    let mut reader = LineReader::new(input);
    match reader.read(literals, options) {
        Ok(mut response) => {
            response.null_bytes_removed = null_bytes;
            Ok(response)
        }
        Err(mut error) => {
            error.tag = reader.tag;
            Err(error)
        }
    }
}

/// An error at `position` of a line, with imapflow's message format: "Unexpected char at position
/// 5 [E2: 'x']" for the code `ParserError2`
fn positioned(code: &'static str, message: &str, position: usize, at: Option<u8>, input: &[u8]) -> ParseError {
    let id = code.strip_prefix("ParserError").unwrap_or(code);
    let message = match at {
        Some(c) => format!("{message} at position {position} [E{id}: {:?}]", c as char),
        None => format!("{message} at position {position} [E{id}]"),
    };
    ParseError::new(code, message, Some(position), input)
}

/// Reads the tag, the command and the response text of a line, and hands the rest to the
/// [`Tokenizer`]
struct LineReader<'a> {
    input: &'a [u8],
    rest: &'a [u8],
    pos: usize,
    tag: Option<String>,
    human: Option<&'a [u8]>,
}

impl<'a> LineReader<'a> {
    fn new(input: &'a [u8]) -> Self {
        LineReader {
            input,
            rest: input,
            pos: 0,
            tag: None,
            human: None,
        }
    }

    fn error(&self, code: &'static str, message: &str, at: Option<u8>) -> ParseError {
        positioned(code, message, self.pos, at, self.input)
    }

    fn read(&mut self, literals: Vec<Vec<u8>>, options: &ParserOptions) -> Result<Response, ParseError> {
        let tag = lossy(self.element(is_tag_char)?);
        self.tag = Some(tag.clone());
        self.space()?;
        let mut command = self.command()?;

        if command.eq_ignore_ascii_case("UID") || command.eq_ignore_ascii_case("AUTHENTICATE") {
            self.space()?;
            command = format!("{command} {}", lossy(self.element(is_command_char)?));
        }

        let mut response = Response {
            tag,
            command,
            ..Default::default()
        };

        if response.tag == "*"
            && response.command.eq_ignore_ascii_case("SEARCH")
            && let Some((numbers, attributes)) = read_search_response(self.rest)
        {
            response.numbers = Some(numbers);
            response.attributes = attributes;
            return Ok(response);
        }

        if !trim(self.rest).is_empty() {
            self.space()?;
            if self.rest.first().is_some_and(|c| is_space(*c)) {
                return Err(self.error("ParserError7", "Unexpected whitespace", None));
            }
            let mut tokenizer = Tokenizer::new(self.rest, self.pos, &response.command, literals, options);
            response.attributes = tokenizer.attributes()?;
            response.truncated_attributes = tokenizer.truncated;
        }

        if let Some(human) = self.human.filter(|text| !text.is_empty()) {
            response.attributes.push(Token::Text(human.to_vec()));
        }
        Ok(response)
    }

    /// The next run of non-space bytes, all of them accepted by `allowed`
    fn element(&mut self, allowed: fn(u8) -> bool) -> Result<&'a [u8], ParseError> {
        if self.rest.first().is_some_and(|c| is_space(*c)) {
            return Err(self.error("ParserError1", "Unexpected whitespace", None));
        }
        let length = self.rest.iter().position(|c| is_space(*c)).unwrap_or(self.rest.len());
        if length == 0 {
            return Err(self.error("ParserError3", "Unexpected end of input", None));
        }
        let element = &self.rest[..length];
        if let Some(bad) = element.iter().position(|c| !allowed(*c)) {
            let at = self.pos + bad;
            return Err(positioned(
                "ParserError2",
                "Unexpected char",
                at,
                Some(element[bad]),
                self.input,
            ));
        }
        self.pos += length;
        self.rest = &self.rest[length..];
        Ok(element)
    }

    fn space(&mut self) -> Result<(), ParseError> {
        match self.rest.first() {
            // an empty continuation request, "+"
            None if self.tag.as_deref() == Some("+") && self.pos == 1 => Ok(()),
            None => Err(self.error("ParserError4", "Unexpected end of input", None)),
            Some(b' ') => {
                self.pos += 1;
                self.rest = &self.rest[1..];
                Ok(())
            }
            Some(other) => Err(self.error("ParserError5", "Unexpected char", Some(*other))),
        }
    }

    /// The response name. For a status response the human readable text is split off here, so
    /// that only the response code is left for the tokenizer.
    fn command(&mut self) -> Result<String, ParseError> {
        if self.tag.as_deref() == Some("+") {
            self.human = Some(trim(self.rest));
            self.rest = &[];
            return Ok(String::new());
        }
        let command = lossy(self.element(is_command_char)?);
        if is_status_command(&command) {
            self.split_status_text();
        }
        Ok(command)
    }

    fn split_status_text(&mut self) {
        let spaces = self.rest.iter().take_while(|c| is_space(**c)).count();
        if spaces == 0 || self.rest.get(spaces) != Some(&b'[') {
            self.human = Some(trim(self.rest));
            self.rest = &[];
            return;
        }
        // The ']' that closes the response code. Brackets inside it are matched, servers put
        // bracketed keywords in a PERMANENTFLAGS list; without a match the code ends at the first
        // ']', which the free-text form of a code allows only once.
        let start = spaces + 1;
        let mut nesting = 1;
        let mut end = None;
        for (i, c) in self.rest.iter().enumerate().skip(start) {
            match c {
                b'[' => nesting += 1,
                b']' => nesting -= 1,
                _ => {}
            }
            if nesting == 0 {
                end = Some(i);
                break;
            }
        }
        let end = end.or_else(|| self.rest[start..].iter().position(|c| *c == b']').map(|p| p + start));
        if let Some(end) = end {
            self.human = Some(trim(&self.rest[end + 1..]));
            self.rest = &self.rest[..=end];
        }
    }
}

fn lossy(bytes: &[u8]) -> String {
    String::from_utf8_lossy(bytes).into_owned()
}

/// The numbers of an untagged SEARCH response, the part after the command (" 2 5 9"), with the
/// MODSEQ of a CONDSTORE `(MODSEQ n)` list at the end. A SEARCH answer holds one number per
/// matching message, millions on a large mailbox, so it skips the tokenizer. None leaves the line
/// to the tokenizer.
fn read_search_response(rest: &[u8]) -> Option<(Vec<u64>, Vec<Token>)> {
    if trim(rest).last() != Some(&b')') {
        return read_search_numbers(rest).map(|numbers| (numbers, Vec::new()));
    }
    let open = rest.windows(2).rposition(|pair| pair == b" (")?;
    let modseq = read_modseq_list(&rest[open..])?;
    let numbers = read_search_numbers(&rest[..open])?;
    let atom = |value: &[u8]| {
        Token::Atom(Atom {
            value: value.to_vec(),
            ..Default::default()
        })
    };
    Some((numbers, vec![Token::List(vec![atom(b"MODSEQ"), atom(modseq)])]))
}

/// ` (MODSEQ 1234)` followed by spaces only, the number up to 19 digits
fn read_modseq_list(list: &[u8]) -> Option<&[u8]> {
    let inner = list.strip_prefix(b" (")?;
    if inner.len() < 7 || !inner[..7].eq_ignore_ascii_case(b"MODSEQ ") {
        return None;
    }
    let inner = &inner[7..];
    let digits = inner.iter().take_while(|c| c.is_ascii_digit()).count();
    if digits == 0 || digits > 19 || inner.get(digits) != Some(&b')') {
        return None;
    }
    inner[digits + 1..]
        .iter()
        .all(|c| *c == b' ')
        .then_some(&inner[..digits])
}

/// " 2 5 9" with trailing spaces allowed. None for anything else, or a number past 2^53, which
/// the tokenizer then reads.
fn read_search_numbers(rest: &[u8]) -> Option<Vec<u64>> {
    let end = rest.len() - rest.iter().rev().take_while(|c| **c == b' ').count();
    if end < 2 || rest[0] != b' ' {
        return None;
    }
    const MAX_SAFE: u64 = (1 << 53) - 1;
    let mut numbers = Vec::with_capacity(end / 2);
    let mut value: Option<u64> = None;
    for c in &rest[1..end] {
        match c {
            b' ' => numbers.push(value.take()?),
            b'0'..=b'9' => {
                let next = value.unwrap_or(0) * 10 + u64::from(c - b'0');
                if next > MAX_SAFE {
                    return None;
                }
                value = Some(next);
            }
            _ => return None,
        }
    }
    numbers.push(value?);
    Some(numbers)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Kind {
    Tree,
    Atom,
    String,
    Literal,
    Sequence,
    List,
    Section,
    Partial,
}

#[derive(Debug)]
struct Node {
    kind: Kind,
    value: Vec<u8>,
    closed: bool,
    parent: Option<usize>,
    depth: u32,
    children: Vec<usize>,
    /// A FETCH data item nested deeper than MAX_DEPTH
    truncated: bool,
}

impl Node {
    fn new(kind: Kind, parent: Option<usize>, depth: u32) -> Self {
        Node {
            kind,
            value: Vec::new(),
            closed: true,
            parent,
            depth,
            children: Vec::new(),
            truncated: false,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum State {
    Normal,
    Atom,
    String,
    Partial,
    Literal,
    Sequence,
}

/// Facts about the token being read that would otherwise take a scan of its value
#[derive(Debug, Clone, Copy)]
struct TokenFacts {
    digits_only: bool,
    has_star: bool,
    has_dot: bool,
}

impl Default for TokenFacts {
    fn default() -> Self {
        TokenFacts {
            digits_only: true,
            has_star: false,
            has_dot: false,
        }
    }
}

fn is_digit(c: Option<u8>) -> bool {
    c.is_some_and(|c| c.is_ascii_digit())
}

/// Turns the attributes part of a line into a tree of nodes, then into tokens
struct Tokenizer<'a> {
    input: &'a [u8],
    /// Position of `input` in the line, for error messages
    base: usize,
    command: &'a str,
    /// A status response: a `[` at the start is a response code
    status: bool,
    /// OK, NO and BAD: atoms accept any byte, servers put free text in their codes
    lenient: bool,
    literals: Vec<Vec<u8>>,
    literal_index: usize,
    /// While a literal size marker is read: None before its first digit, then whether the
    /// digits so far are a single 0
    literal_zero: Option<bool>,
    max_tokens: usize,
    nodes: Vec<Node>,
    current: usize,
    state: State,
    i: usize,
    facts: TokenFacts,
    string_start: usize,
    string_escaped: bool,
    truncated: Vec<String>,
}

type Step = Result<(), ParseError>;

impl<'a> Tokenizer<'a> {
    fn new(input: &'a [u8], base: usize, command: &'a str, literals: Vec<Vec<u8>>, options: &ParserOptions) -> Self {
        Tokenizer {
            input,
            base,
            command,
            status: is_status_command(command),
            lenient: ["NO", "BAD", "OK"]
                .iter()
                .any(|name| command.eq_ignore_ascii_case(name)),
            literals,
            literal_index: 0,
            literal_zero: None,
            max_tokens: options.max_tokens,
            nodes: vec![Node::new(Kind::Tree, None, 0)],
            current: 0,
            state: State::Normal,
            i: 0,
            facts: TokenFacts::default(),
            string_start: 0,
            string_escaped: false,
            truncated: Vec::new(),
        }
    }

    fn error(&self, code: &'static str, message: &str, offset: usize, with_char: bool) -> ParseError {
        let at = self.input.get(offset).copied().filter(|_| with_char);
        positioned(code, message, self.base + offset, at, self.input)
    }

    fn at(&self, offset: usize) -> Option<u8> {
        self.input.get(offset).copied()
    }

    fn node(&mut self) -> &mut Node {
        &mut self.nodes[self.current]
    }

    fn value(&self) -> &[u8] {
        &self.nodes[self.current].value
    }

    /// The last and the second to last byte of the token being read
    fn last_two(&self) -> (Option<u8>, Option<u8>) {
        let value = self.value();
        (value.last().copied(), value.len().checked_sub(2).map(|i| value[i]))
    }

    fn parent_of(&self, index: usize) -> usize {
        self.nodes[index].parent.unwrap_or(0)
    }

    fn create_node(&mut self, parent: usize, kind: Kind) -> Result<usize, ParseError> {
        // the tree itself is not a token
        if self.nodes.len() > self.max_tokens {
            return Err(ParseError::new(
                "TooManyTokens",
                format!("Response has more than {} tokens", self.max_tokens),
                Some(self.base + self.i),
                self.input,
            ));
        }
        let depth = self.nodes[parent].depth + 1;
        if depth > MAX_DEPTH {
            if !self.is_fetch_response() {
                return Err(ParseError::new(
                    "MAX_IMAP_NESTING_REACHED",
                    "Too much nesting in IMAP string",
                    Some(self.base + self.i),
                    self.input,
                ));
            }
            if self.nodes[parent].depth == MAX_DEPTH {
                self.truncate_fetch_data_item(parent);
            }
        }
        self.nodes.push(Node::new(kind, Some(parent), depth));
        let index = self.nodes.len() - 1;
        self.nodes[parent].children.push(index);
        Ok(index)
    }

    /// Creates a node that stays open until its closing delimiter, and makes it current
    fn open_node(&mut self, kind: Kind) -> Step {
        self.current = self.create_node(self.current, kind)?;
        self.node().closed = false;
        Ok(())
    }

    /// `* 12 FETCH (...)`: a numeric command with FETCH as the first attribute
    fn is_fetch_response(&self) -> bool {
        !self.command.is_empty()
            && self.command.bytes().all(|c| c.is_ascii_digit())
            && self.nodes[0].children.first().is_some_and(|first| {
                let node = &self.nodes[*first];
                node.kind == Kind::Atom && node.value.eq_ignore_ascii_case(b"FETCH")
            })
    }

    /// Marks the FETCH data item that `node` belongs to as truncated and records its key
    fn truncate_fetch_data_item(&mut self, node: usize) {
        let mut item = node;
        while self.nodes[item].depth > FETCH_DATA_ITEM_DEPTH && self.nodes[item].parent.is_some() {
            item = self.parent_of(item);
        }
        if self.nodes[item].truncated {
            return;
        }
        self.nodes[item].truncated = true;
        let siblings = &self.nodes[self.parent_of(item)].children;
        let key = siblings.len().checked_sub(2).map(|k| &self.nodes[siblings[k]]);
        let name = match key {
            Some(key) if key.kind == Kind::Atom => String::from_utf8_lossy(&key.value).to_ascii_uppercase(),
            _ => "?".into(),
        };
        self.truncated.push(name);
    }

    fn closes(&self, c: Option<u8>, node: Option<usize>) -> bool {
        let Some(node) = node else { return false };
        let kind = self.nodes[node].kind;
        (c == Some(b')') && kind == Kind::List) || (c == Some(b']') && kind == Kind::Section)
    }

    /// Skips the spaces after a closing delimiter
    fn skip_spaces(&mut self) {
        while self.at(self.i + 1) == Some(b' ') {
            self.i += 1;
        }
    }

    fn start_token(&mut self, first: Option<u8>) {
        self.node().value.clear();
        self.facts = TokenFacts::default();
        if let Some(c) = first {
            self.append(c);
        }
    }

    fn append(&mut self, c: u8) {
        self.node().value.push(c);
        let facts = &mut self.facts;
        facts.digits_only &= c.is_ascii_digit();
        facts.has_star |= c == b'*';
        facts.has_dot |= c == b'.';
    }

    /// Any ATOM-CHAR starts an atom, also `\` for system flags, `%` for LIST patterns and 8-bit
    /// bytes, which servers send for unquoted UTF-8 names
    fn start_atom(&mut self, c: u8) -> Step {
        if !is_atom_char(c) && c != b'\\' && c != b'%' && c < 0x80 {
            return Err(self.error("ParserError13", "Unexpected char", self.i, true));
        }
        self.current = self.create_node(self.current, Kind::Atom)?;
        self.start_token(Some(c));
        self.state = State::Atom;
        Ok(())
    }

    fn close_current(&mut self) {
        self.node().closed = true;
        self.current = self.parent_of(self.current);
    }

    fn take_literal(&mut self) -> Result<Vec<u8>, ParseError> {
        let Some(literal) = self.literals.get_mut(self.literal_index) else {
            return Err(self.error("ParserError35", "Literal without data", self.i, true));
        };
        self.literal_index += 1;
        Ok(std::mem::take(literal))
    }

    fn attributes(&mut self) -> Result<Vec<Token>, ParseError> {
        self.process()?;
        let mut out = Vec::new();
        self.walk(0, &mut out)?;
        Ok(out)
    }

    fn process(&mut self) -> Step {
        while self.i < self.input.len() {
            let c = self.input[self.i];
            // a sequence that turns out to be an atom reads its byte again
            let reread = match self.state {
                State::Sequence => self.sequence(c)?,
                _ => {
                    self.step(c)?;
                    false
                }
            };
            if !reread {
                self.i += 1;
            }
        }
        self.end_of_input();
        Ok(())
    }

    fn step(&mut self, c: u8) -> Step {
        match self.state {
            State::Normal => self.normal(c),
            State::Atom => self.atom(c),
            State::String => self.string(c),
            State::Partial => self.partial(c),
            State::Literal => self.literal(c),
            State::Sequence => unreachable!("handled by process"),
        }
    }

    fn end_of_input(&mut self) {
        if self.state != State::Sequence {
            return;
        }
        let (last, prev) = self.last_two();
        let has_star = self.facts.has_star;
        let node = self.node();
        // a digit-led token that ends the input on a dangling separator, "10:"
        if matches!(last, Some(b':' | b',')) && !has_star {
            node.kind = Kind::Atom;
        }
        // a star-led sequence set is closed under the rules a space applies, a bare "*" is an atom
        if !node.closed {
            if is_digit(last) || (last == Some(b'*') && prev == Some(b':')) {
                node.closed = true;
            } else if node.value == b"*" {
                node.closed = true;
                node.kind = Kind::Atom;
            }
        }
    }

    fn normal(&mut self, c: u8) -> Step {
        match c {
            b'"' => {
                self.open_node(Kind::String)?;
                self.state = State::String;
                self.string_start = self.i + 1;
                self.string_escaped = false;
            }
            b'(' => self.open_node(Kind::List)?,
            b')' | b']' => {
                let (kind, code, message) = match c {
                    b')' => (Kind::List, "ParserError10", "Unexpected list terminator )"),
                    _ => (Kind::Section, "ParserError11", "Unexpected section terminator ]"),
                };
                if self.nodes[self.current].kind != kind {
                    return Err(self.error(code, message, self.i, false));
                }
                self.close_current();
                self.skip_spaces();
            }
            // a partial range only right after the ']' of a section, BODY[]<0.1024>
            b'<' if self.i > 0 && self.input[self.i - 1] == b']' => {
                self.open_node(Kind::Partial)?;
                self.start_token(None);
                self.state = State::Partial;
            }
            // literal8, ~{size}, or an atom that starts with '~'
            b'~' => {
                let next = self.at(self.i + 1);
                if next == Some(b'{') {
                    // the literal follows, its data is the same either way
                } else if next.is_none()
                    || next == Some(b' ')
                    || next.is_some_and(is_atom_char)
                    || self.closes(next, Some(self.current))
                {
                    self.start_atom(c)?;
                } else {
                    return Err(self.error("ParserError12", "Unexpected literal8 marker", self.i, false));
                }
            }
            b'{' => {
                self.open_node(Kind::Literal)?;
                self.literal_zero = None;
                self.state = State::Literal;
            }
            b'*' => {
                self.open_node(Kind::Sequence)?;
                self.start_token(Some(c));
                self.state = State::Sequence;
            }
            b' ' => {}
            b'[' if self.current == 0 && self.status => self.response_code()?,
            _ => self.start_atom(c)?,
        }
        Ok(())
    }

    /// The `[code ...]` of a status response: an empty atom with a section
    fn response_code(&mut self) -> Step {
        self.current = self.create_node(self.current, Kind::Atom)?;
        self.open_node(Kind::Section)?;

        // REFERRAL carries an IMAP URL, read up to the closing ']' as one atom. The URL can hold a
        // bracketed IPv6 host, so brackets opened inside it are matched first.
        let ahead = self.input.get(self.i + 1..self.i + 10);
        if ahead.is_some_and(|word| word.eq_ignore_ascii_case(b"REFERRAL ")) {
            let referral = self.create_node(self.current, Kind::Atom)?;
            self.nodes[referral].value = b"REFERRAL".to_vec();
            let url = self.create_node(self.current, Kind::Atom)?;
            let start = self.i + 10;
            let mut depth = 0;
            self.i = start;
            while self.i < self.input.len() {
                match self.input[self.i] {
                    b'[' => depth += 1,
                    b']' if depth == 0 => break,
                    b']' => depth -= 1,
                    _ => {}
                }
                self.i += 1;
            }
            // without a closing ']' the URL takes the rest of the line
            self.nodes[url].value = self.input[start..self.i].to_vec();
            // close the section, the current node is the empty atom again
            self.close_current();
            self.skip_spaces();
        }
        Ok(())
    }

    fn atom(&mut self, c: u8) -> Step {
        if c == b' ' {
            self.current = self.parent_of(self.current);
            self.state = State::Normal;
            return Ok(());
        }

        // ')' or ']' ends the atom and closes the list or section around it
        let parent = self.nodes[self.current].parent;
        if self.closes(Some(c), parent) {
            self.current = self.parent_of(self.current);
            self.close_current();
            self.state = State::Normal;
            self.skip_spaces();
            return Ok(());
        }

        // Two flags without the space between them, "\Sent\HasNoChildren" (home.pl). Only an atom
        // that is a flag already is split, and only when a flag name follows.
        if c == b'\\' {
            let value = self.value();
            let next = self.at(self.i + 1);
            if parent.is_some_and(|p| self.nodes[p].kind == Kind::List)
                && value.len() > 1
                && value[0] == b'\\'
                && next.is_some_and(|n| is_atom_char(n) || n == b'*')
            {
                self.current = self.parent_of(self.current);
                return self.start_atom(c);
            }
        }

        // digits followed by ',' or ':' are a sequence set, "1:5" or "1,3,5"
        if (c == b',' || c == b':') && !self.value().is_empty() && self.facts.digits_only {
            self.node().kind = Kind::Sequence;
            self.state = State::Sequence;
        }

        // '[' starts the section of BODY, BODY.PEEK, BINARY and BINARY.PEEK
        if c == b'['
            && [&b"BODY"[..], b"BODY.PEEK", b"BINARY", b"BINARY.PEEK"]
                .iter()
                .any(|name| self.value().eq_ignore_ascii_case(name))
        {
            self.current = self.parent_of(self.current);
            self.open_node(Kind::Section)?;
            self.state = State::Normal;
            return Ok(());
        }

        let value = self.value();
        if !is_atom_char(c) && c < 0x80 && c != b']' && !(c == b'*' && value == b"\\") && !self.lenient {
            return Err(self.error("ParserError16", "Unexpected char", self.i, true));
        } else if value == b"\\*" {
            return Err(self.error("ParserError17", "Unexpected char", self.i, true));
        }

        self.append(c);
        Ok(())
    }

    fn string(&mut self, c: u8) -> Step {
        match c {
            b'"' => {
                let raw = &self.input[self.string_start..self.i];
                let value = if self.string_escaped {
                    unescape(raw)
                } else {
                    raw.to_vec()
                };
                self.node().value = value;
                self.close_current();
                self.state = State::Normal;
                self.skip_spaces();
            }
            // the escaped byte is skipped here so it can not end the string
            b'\\' => {
                self.i += 1;
                if self.i >= self.input.len() {
                    return Err(self.error("ParserError18", "Unexpected end of input", self.i, false));
                }
                self.string_escaped = true;
            }
            _ => {}
        }
        Ok(())
    }

    fn partial(&mut self, c: u8) -> Step {
        let (last, prev) = self.last_two();
        let length = self.value().len();
        if c == b'>' {
            if last == Some(b'.') {
                return Err(self.error("ParserError19", "Unexpected end of partial", self.i, true));
            }
            self.close_current();
            self.state = State::Normal;
            self.skip_spaces();
            return Ok(());
        }
        if c == b'.' && (length == 0 || self.facts.has_dot) {
            return Err(self.error("ParserError20", "Unexpected partial separator .", self.i, false));
        }
        if !c.is_ascii_digit() && c != b'.' {
            return Err(self.error("ParserError21", "Unexpected char", self.i, true));
        }
        if last == Some(b'0') && (length == 1 || prev == Some(b'.')) && c != b'.' {
            return Err(self.error("ParserError22", "Invalid partial", self.i, true));
        }
        self.append(c);
        Ok(())
    }

    fn literal(&mut self, c: u8) -> Step {
        if c == b'}' {
            if self.literal_zero.is_none() {
                return Err(self.error("ParserError23", "Unexpected literal prefix end char }", self.i, false));
            }
            if self.at(self.i + 1) == Some(b'\n') {
                self.i += 1;
            } else if self.at(self.i + 1) == Some(b'\r') && self.at(self.i + 2) == Some(b'\n') {
                self.i += 2;
            } else {
                return Err(self.error("ParserError24", "Unexpected char", self.i, true));
            }
            // the framer split the data of every marker off the line, {0} included
            let value = self.take_literal()?;
            self.node().value = value;
            self.close_current();
            self.state = State::Normal;
            self.skip_spaces();
            return Ok(());
        }
        if !c.is_ascii_digit() {
            return Err(self.error("ParserError25", "Unexpected char", self.i, true));
        }
        if self.literal_zero == Some(true) {
            return Err(self.error("ParserError26", "Invalid literal", self.i, false));
        }
        self.literal_zero = Some(self.literal_zero.is_none() && c == b'0');
        Ok(())
    }

    /// A digit-led token is only a guess at a sequence set: `2024:Q1` or `1,a` are valid atoms.
    /// When the sequence grammar breaks, a token without `*` is read on as an atom from the current
    /// byte (returns true, the byte is read again); one with `*` can not be an atom and fails.
    fn atom_or_fail(&mut self, code: &'static str, message: &str, with_char: bool) -> Result<bool, ParseError> {
        if self.facts.has_star {
            return Err(self.error(code, message, self.i, with_char));
        }
        self.node().kind = Kind::Atom;
        self.state = State::Atom;
        Ok(true)
    }

    /// Returns whether the byte has to be read again (in the atom state)
    fn sequence(&mut self, c: u8) -> Result<bool, ParseError> {
        let (last, prev) = self.last_two();
        let parent = self.nodes[self.current].parent;
        let closes_parent = self.closes(Some(c), parent);
        let last_ends_range = is_digit(last) || last == Some(b'*');

        if c == b' ' || closes_parent {
            if !last_ends_range {
                // a dangling separator, "10:" or "1,"
                return self.atom_or_fail("ParserError27", "Unexpected end of sequence", true);
            }
            if self.value() != b"*" && last == Some(b'*') && prev != Some(b':') {
                return Err(self.error("ParserError28", "Unexpected end of sequence", self.i, true));
            }
            self.close_current();
            self.state = State::Normal;
            if closes_parent {
                self.close_current();
                self.skip_spaces();
            }
            return Ok(false);
        }

        match c {
            b':' if !last_ends_range => {
                return self.atom_or_fail("ParserError29", "Unexpected range separator :", false);
            }
            b'*' if !matches!(last, Some(b',' | b':')) => {
                return Err(self.error("ParserError30", "Unexpected range wildcard", self.i, false));
            }
            b',' if !last_ends_range => {
                return self.atom_or_fail("ParserError31", "Unexpected sequence separator ,", false);
            }
            b',' if last == Some(b'*') && prev != Some(b':') => {
                return Err(self.error("ParserError32", "Unexpected sequence separator ,", self.i, false));
            }
            b':' | b'*' | b',' => {}
            _ if !c.is_ascii_digit() => return self.atom_or_fail("ParserError33", "Unexpected char", true),
            _ if last == Some(b'*') => return Err(self.error("ParserError34", "Unexpected number", self.i, true)),
            _ => {}
        }
        self.append(c);
        Ok(false)
    }

    fn walk_children(&mut self, children: Vec<usize>) -> Result<Vec<Token>, ParseError> {
        let mut items = Vec::with_capacity(children.len());
        for child in children {
            self.walk(child, &mut items)?;
        }
        Ok(items)
    }

    /// Converts the subtree of `index` into tokens, appended to `out`
    fn walk(&mut self, index: usize, out: &mut Vec<Token>) -> Step {
        let end = self.input.len().saturating_sub(1);
        let node = &mut self.nodes[index];
        if !node.closed {
            return Err(self.error("ParserError9", "Unexpected end of input", end, false));
        }
        if node.truncated {
            // nested deeper than MAX_DEPTH: a list becomes NIL so the data items keep pairing up as
            // key and value, a section is dropped with the item it belongs to
            if node.kind == Kind::List {
                out.push(Token::Nil);
            }
            return Ok(());
        }

        let value = std::mem::take(&mut node.value);
        let children = std::mem::take(&mut node.children);
        match node.kind {
            Kind::Tree => {}
            Kind::Literal => out.push(Token::Literal(value)),
            Kind::String => out.push(Token::String(value)),
            Kind::Sequence => out.push(Token::Sequence(
                String::from_utf8(value).unwrap_or_else(|e| String::from_utf8_lossy(e.as_bytes()).into_owned()),
            )),
            Kind::Atom if value.eq_ignore_ascii_case(b"NIL") => out.push(Token::Nil),
            Kind::Atom => out.push(Token::Atom(Atom {
                value,
                ..Default::default()
            })),
            Kind::List => {
                let items = self.walk_children(children)?;
                out.push(Token::List(items));
                return Ok(());
            }
            Kind::Section => {
                if !matches!(out.last(), Some(Token::Atom(_))) {
                    return Err(self.error("ParserErrorInternal", "Section without an atom", end, false));
                }
                let section = self.walk_children(children)?;
                if let Some(Token::Atom(atom)) = out.last_mut() {
                    atom.section = Some(section);
                }
                return Ok(());
            }
            Kind::Partial => {
                let Some(Token::Atom(atom)) = out.last_mut() else {
                    return Err(self.error("ParserErrorInternal", "Partial range without an atom", end, false));
                };
                // the grammar of the partial state allows digits and one dot only
                let numbers = value
                    .split(|c| *c == b'.')
                    .map(|part| std::str::from_utf8(part).ok().and_then(|p| p.parse().ok()).unwrap_or(0))
                    .collect();
                atom.partial = Some(numbers);
            }
        }
        for child in children {
            self.walk(child, out)?;
        }
        Ok(())
    }
}

/// Removes the backslash before every escaped byte of a quoted string
fn unescape(raw: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(raw.len());
    let mut bytes = raw.iter();
    while let Some(c) = bytes.next() {
        if *c == b'\\' {
            if let Some(escaped) = bytes.next() {
                out.push(*escaped);
            }
        } else {
            out.push(*c);
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn atom(value: &str) -> Token {
        Token::Atom(Atom {
            value: value.as_bytes().to_vec(),
            ..Default::default()
        })
    }

    fn parse_str(line: &str) -> Result<Response, ParseError> {
        parse(line.as_bytes(), Vec::new())
    }

    #[test]
    fn tag_and_command() {
        let response = parse_str("TAG1 UID FETCH").unwrap();
        assert_eq!(
            (response.tag.as_str(), response.command.as_str()),
            ("TAG1", "UID FETCH")
        );
        assert!(parse_str(" TAG CMD").is_err());
        assert!(parse_str("").is_err());
        assert!(parse_str("TAG1").is_err());
        assert!(parse_str("TAG1  CMD").is_err());
        let error = parse_str("TAG1 CM=D").unwrap_err();
        assert_eq!(error.code, "ParserError2");
        assert_eq!(error.message, "Unexpected char at position 7 [E2: '=']");
    }

    #[test]
    fn continuation() {
        let response = parse_str("+ go ahead").unwrap();
        assert!(response.is_continuation());
        assert_eq!(response.attributes, vec![Token::Text(b"go ahead".to_vec())]);
        assert!(parse_str("+").unwrap().attributes.is_empty());
    }

    #[test]
    fn status_with_code() {
        let response = parse_str("* OK [UIDNEXT 5] Predicted").unwrap();
        let (name, args) = response.code().unwrap();
        assert_eq!(name, "UIDNEXT");
        assert_eq!(args[0].number(), Some(5));
        assert_eq!(response.text().as_deref(), Some("Predicted"));
    }

    #[test]
    fn literals_come_from_the_framer() {
        let raw = RawResponse {
            line: b"* 1 FETCH (BODY[] {5}\r\n FLAGS (\\Seen))".to_vec(),
            literals: vec![b"hello".to_vec()],
        };
        let response = raw.parse().unwrap();
        let list = response.attributes[1].as_list().unwrap();
        assert_eq!(list[1], Token::Literal(b"hello".to_vec()));
        assert_eq!(
            parse(b"* 1 FETCH (BODY[] {5}\r\n)", Vec::new()).unwrap_err().code,
            "ParserError35"
        );
    }

    #[test]
    fn search_numbers() {
        let response = parse_str("* SEARCH 1 2 3 (MODSEQ 917162500)").unwrap();
        assert_eq!(response.numbers, Some(vec![1, 2, 3]));
        assert_eq!(
            response.attributes,
            vec![Token::List(vec![atom("MODSEQ"), atom("917162500")])]
        );
        let response = parse_str("* SEARCH 1 x").unwrap();
        assert_eq!(response.numbers, None);
        assert_eq!(response.attributes, vec![atom("1"), atom("x")]);
    }

    #[test]
    fn deep_nesting() {
        let depth = MAX_DEPTH as usize + 5;
        let line = format!(
            "* 1 FETCH (UID 1 BODYSTRUCTURE {}{} FLAGS ())",
            "(".repeat(depth),
            ")".repeat(depth)
        );
        let response = parse_str(&line).unwrap();
        assert_eq!(response.truncated_attributes, vec!["BODYSTRUCTURE".to_string()]);
        let items = response.attributes[1].as_list().unwrap();
        assert_eq!(items[3], Token::Nil);
        assert!(items[4].is_atom("FLAGS"));

        let line = format!("* LIST {}{}", "(".repeat(depth), ")".repeat(depth));
        assert_eq!(parse_str(&line).unwrap_err().code, "MAX_IMAP_NESTING_REACHED");
    }

    #[test]
    fn token_limit() {
        let options = ParserOptions { max_tokens: 3 };
        assert!(parse_with(b"* X a b c", Vec::new(), &options).is_ok());
        assert_eq!(
            parse_with(b"* X a b c d", Vec::new(), &options).unwrap_err().code,
            "TooManyTokens"
        );
    }

    #[test]
    fn errors_keep_the_tag() {
        let error = parse_str("A1 OK [").unwrap_err();
        assert_eq!(error.tag.as_deref(), Some("A1"));
    }

    #[test]
    fn padding_and_exchange() {
        let response = parse(b"\0\0* OK hi", Vec::new()).unwrap();
        assert_eq!(response.null_bytes_removed, 2);
        assert_eq!(parse(b"\0\0", Vec::new()).unwrap().command, "BAD");
        let response = parse_str("Server Unavailable. 15").unwrap();
        assert_eq!(response.command, "BAD");
        assert_eq!(parse_str("Server Unavailable.x").unwrap_err().code, "ParserError2");
    }
}
