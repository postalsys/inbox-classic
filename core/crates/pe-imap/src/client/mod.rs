//! An IMAP connection. One command runs at a time; what the server reports about the selected
//! mailbox in between (new messages, expunges, flag changes) arrives as [`Event`]s on the channel
//! [`Client::connect`] returns. A port of the session handling of imapflow's `imap-flow.ts`.
//!
//! The session starts the way imapflow starts it: the greeting, CAPABILITY, STARTTLS when asked
//! for, ID, authentication, CAPABILITY again, NAMESPACE and ENABLE.

mod auth;
mod error;
mod fetch;
mod idle;
mod mailbox;
mod messages;
mod search;

use std::collections::{HashSet, VecDeque};
use std::time::Duration;

use pe_net::{Security, Stream, Trust};
use tokio::sync::mpsc::{UnboundedReceiver, UnboundedSender, unbounded_channel};

use crate::compiler::{Arg, Command, CompileOptions, compile, to_log_string};
use crate::framing::{FrameLimits, Framer, RawResponse};
use crate::parser::ParserOptions;
use crate::sequence::SequenceSet;
use crate::types::{Response, Token};

pub use auth::Credentials;
pub use error::{Error, ErrorKind};
pub use fetch::{FetchQuery, FetchedMessage};
pub use mailbox::{ListedMailbox, MailboxStatus, Namespace, Selected};
pub use messages::{CopyUid, StoreAction};
pub use search::SearchKey;

/// Most untagged responses one command collects. The server decides how many it sends, the
/// memory is this process's.
const MAX_COLLECTED_RESPONSES: usize = 1_000_000;

/// How much of a server line the wire log shows
const LOG_LINE_LIMIT: usize = 1000;

/// Who wrote a line of the wire log
/// Which way a line went, and the receiver of the protocol log: commands with secrets and message data hidden,
/// server lines cut at 1000 bytes
pub use pe_net::{Direction, WireLog};

/// Hears how many bytes of an answer came so far ([`Client::on_received`])
pub type Received = Box<dyn FnMut(u64) + Send + Sync>;

#[derive(Debug, Clone, Copy)]
pub struct Timeouts {
    pub connect: Duration,
    /// For the greeting of the server
    pub greeting: Duration,
    /// For each read while a command runs
    pub response: Duration,
    /// How long one IDLE lasts before it is renewed (servers drop it after 30 minutes)
    pub idle: Duration,
    /// How often a server without IDLE is asked with NOOP while waiting for changes
    pub poll: Duration,
}

impl Default for Timeouts {
    fn default() -> Self {
        Timeouts {
            connect: Duration::from_secs(90),
            greeting: Duration::from_secs(16),
            response: Duration::from_secs(300),
            idle: Duration::from_secs(5 * 60),
            poll: Duration::from_secs(30),
        }
    }
}

#[derive(Clone)]
pub struct Config {
    pub host: String,
    pub port: u16,
    pub security: Security,
    pub trust: Trust,
    pub credentials: Credentials,
    /// Sent with ID, `("name", "Inbox Classic")`
    pub client_id: Vec<(String, String)>,
    pub timeouts: Timeouts,
    pub limits: FrameLimits,
    pub wire_log: Option<WireLog>,
}

impl Config {
    pub fn new(host: impl Into<String>, port: u16, security: Security, credentials: Credentials) -> Self {
        Config {
            host: host.into(),
            port,
            security,
            trust: Trust::Platform,
            credentials,
            client_id: vec![("name".into(), "Inbox Classic".into())],
            timeouts: Timeouts::default(),
            limits: FrameLimits::default(),
            wire_log: None,
        }
    }
}

/// A change the server reported, about a mailbox (the one selected when it was reported) or
/// about the connection
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Event {
    /// The mailbox has this many messages now
    Exists { mailbox: String, count: u32 },
    /// The message with this sequence number is gone, later ones moved down by one
    Expunge { mailbox: String, seq: u32 },
    /// Messages with these UIDs are gone (QRESYNC)
    Vanished {
        mailbox: String,
        uids: SequenceSet,
        earlier: bool,
    },
    /// The flags of a message changed
    Flags {
        mailbox: String,
        seq: u32,
        uid: Option<u64>,
        flags: Vec<String>,
        modseq: Option<u64>,
    },
    /// A message the server wants the user to see (`[ALERT]`)
    Alert(String),
    /// The server closed the connection, with its BYE text if it sent one
    Closed(Option<String>),
}

/// What a successful command left behind: the untagged responses it collected and its tagged
/// completion
#[derive(Debug)]
pub(crate) struct Completion {
    pub untagged: Vec<Response>,
    pub tagged: Response,
}

impl Completion {
    /// The untagged responses named `name`
    pub fn untagged<'a>(&'a self, name: &'a str) -> impl Iterator<Item = &'a Response> {
        self.untagged.iter().filter(move |r| r.is(name))
    }

    /// The lowest UID a command cut short by MESSAGELIMIT (RFC 9738) worked on: the messages
    /// below it are still to do. In the tagged OK, or in an untagged NO when the OK carries
    /// another code.
    pub fn message_limit(&self) -> Option<u64> {
        std::iter::once(&self.tagged)
            .chain(self.untagged("NO"))
            .find_map(|response| response.code_args("MESSAGELIMIT")?.get(1)?.number())
    }
}

/// Sees each untagged response of a command first: returns it to keep it (it is then also
/// applied to the session state and reported), or None when it was the command's own data
type UntaggedHandler<'a> = &'a mut (dyn FnMut(Response) -> Result<Option<Response>, Error> + Send);

/// The data to send for a `+` continuation that is not a literal
type ContinuationHandler<'a> = &'a mut (dyn FnMut(&Response) -> Result<Vec<u8>, Error> + Send);

fn keep(response: Response) -> Result<Option<Response>, Error> {
    Ok(Some(response))
}

/// INBOX in any case is INBOX (RFC 3501 section 5.1)
fn normalize_path(path: &str) -> String {
    if path.eq_ignore_ascii_case("INBOX") {
        "INBOX".into()
    } else {
        path.to_string()
    }
}

/// Whether an uppercase name set has `name`, without allocating for names that are uppercase
fn has_name(set: &HashSet<String>, name: &str) -> bool {
    if name.bytes().any(|c| c.is_ascii_lowercase()) {
        set.contains(&name.to_ascii_uppercase())
    } else {
        set.contains(name)
    }
}

pub struct Client {
    config: Config,
    stream: Stream,
    framer: Framer,
    /// Responses framed but not read yet
    ready: VecDeque<RawResponse>,
    /// A framing failure that comes after the responses in `ready`
    framing_error: Option<crate::ParseError>,
    buffer: Vec<u8>,
    next_tag: u64,
    capabilities: HashSet<String>,
    enabled: HashSet<String>,
    namespace: Option<Namespace>,
    selected: Option<Selected>,
    bye: Option<String>,
    closed: bool,
    events: UnboundedSender<Event>,
    /// When the first bytes of the answer to the last command came
    answered: Option<std::time::Instant>,
    /// How long the first bytes of the answer to the next command may take (Client::limit_next_answer)
    answer_limit: Option<Duration>,
    /// A command was sent and nothing of its answer came yet: with the limit on its first bytes, if it has one
    awaiting_answer: Option<Option<Duration>>,
    /// Told how many bytes of the answer to the command under way came so far (Client::on_received)
    received: Option<(u64, Received)>,
}

impl Client {
    /// Connects, authenticates and enables what the server supports
    pub async fn connect(config: Config) -> Result<(Client, UnboundedReceiver<Event>), Error> {
        let stream = Stream::connect(
            &config.host,
            config.port,
            config.security,
            &config.trust,
            config.timeouts.connect,
        )
        .await?;
        let (events, receiver) = unbounded_channel();
        let mut client = Client {
            framer: Framer::new(config.limits),
            config,
            stream,
            ready: VecDeque::new(),
            framing_error: None,
            buffer: vec![0; 64 * 1024],
            next_tag: 1,
            capabilities: HashSet::new(),
            enabled: HashSet::new(),
            namespace: None,
            selected: None,
            bye: None,
            closed: false,
            events,
            answered: None,
            answer_limit: None,
            awaiting_answer: None,
            received: None,
        };
        client.start_session().await?;
        Ok((client, receiver))
    }

    async fn start_session(&mut self) -> Result<(), Error> {
        let preauth = self.greeting().await?;
        if self.capabilities.is_empty() {
            self.capability().await?;
        }
        if self.config.security == Security::StartTls {
            self.start_tls().await?;
        }
        if self.has_capability("ID") {
            self.id().await?;
        }
        if !preauth {
            self.authenticate().await?;
        }
        if self.has_capability("NAMESPACE") {
            self.namespace = self.fetch_namespace().await?;
        }
        self.enable().await
    }

    /// Reads the greeting, returns whether the session is already authenticated (PREAUTH)
    async fn greeting(&mut self) -> Result<bool, Error> {
        let greeting = self.read_response(None, Some(self.config.timeouts.greeting)).await?;
        let status = greeting.command.to_ascii_uppercase();
        if greeting.tag != "*" || !["OK", "PREAUTH", "BYE"].contains(&status.as_str()) {
            return Err(Error::Unexpected(format!("not an IMAP greeting: {}", greeting.command)));
        }
        if status == "BYE" {
            return Err(Error::Closed(greeting.text()));
        }
        self.update_from_code(&greeting);
        Ok(status == "PREAUTH")
    }

    async fn start_tls(&mut self) -> Result<(), Error> {
        if !self.has_capability("STARTTLS") {
            return Err(Error::StartTlsUnavailable);
        }
        self.run("STARTTLS", Vec::new()).await?;
        // Anything the server sent after its OK and before the handshake came in plaintext and
        // would be read as if it came over TLS: an injection attempt (CVE-2011-0411 class)
        if !self.ready.is_empty() || !self.framer.is_idle() {
            return Err(Error::StartTlsInjection);
        }
        self.stream.upgrade(&self.config.host, &self.config.trust).await?;
        // the capabilities from before the upgrade could have been tampered with
        self.capabilities.clear();
        self.capability().await
    }

    async fn id(&mut self) -> Result<(), Error> {
        let fields = self
            .config
            .client_id
            .iter()
            .flat_map(|(k, v)| [Arg::string(k.as_str()), Arg::string(v.as_str())]);
        // ID is informational, a server that refuses it is still usable
        self.optional("ID", vec![Arg::List(fields.collect())]).await.map(|_| ())
    }

    async fn enable(&mut self) -> Result<(), Error> {
        if !self.has_capability("ENABLE") {
            return Ok(());
        }
        let wanted: Vec<Arg> = ["CONDSTORE", "UTF8=ACCEPT"]
            .into_iter()
            .filter(|extension| self.has_capability(extension))
            .map(Arg::atom)
            .collect();
        if wanted.is_empty() {
            return Ok(());
        }
        if let Some(completion) = self.optional("ENABLE", wanted).await? {
            for response in completion.untagged("ENABLED") {
                self.enabled.extend(
                    response
                        .attributes
                        .iter()
                        .filter_map(Token::text)
                        .map(|t| t.to_ascii_uppercase()),
                );
            }
        }
        Ok(())
    }

    /// Asks for the capabilities again
    pub async fn capability(&mut self) -> Result<(), Error> {
        self.simple("CAPABILITY", Vec::new()).await
    }

    pub fn has_capability(&self, name: &str) -> bool {
        has_name(&self.capabilities, name)
    }

    /// Whether an extension was enabled with ENABLE (CONDSTORE, UTF8=ACCEPT)
    pub fn is_enabled(&self, name: &str) -> bool {
        has_name(&self.enabled, name)
    }

    pub fn namespace(&self) -> Option<&Namespace> {
        self.namespace.as_ref()
    }

    pub fn selected(&self) -> Option<&Selected> {
        self.selected.as_ref()
    }

    pub fn is_secure(&self) -> bool {
        self.stream.is_tls()
    }

    pub fn is_closed(&self) -> bool {
        self.closed
    }

    /// When the first bytes of the answer to the last command came: a FETCH's first byte, for timing what the user
    /// waits for
    pub fn answered_at(&self) -> Option<std::time::Instant> {
        self.answered
    }

    /// `told` hears how many bytes of the answers to the commands from now on came so far, counted from each command
    /// (None: nobody): how far a large message is, as it comes in one FETCH
    pub fn on_received(&mut self, told: Option<Received>) {
        self.received = told.map(|told| (0, told));
    }

    /// How long the server may take to start answering the next command, when shorter than `Timeouts::response`. For
    /// what the user waits for on a connection made a while ago: one the network forgot is found dead in seconds, not
    /// minutes. Once the answer started, each read has `Timeouts::response` again. Running out closes the connection,
    /// as any timeout does.
    pub fn limit_next_answer(&mut self, limit: Duration) {
        self.answer_limit = Some(limit);
    }

    pub async fn noop(&mut self) -> Result<(), Error> {
        self.simple("NOOP", Vec::new()).await
    }

    /// Ends the session politely and closes the connection
    pub async fn logout(&mut self) -> Result<(), Error> {
        if !self.closed {
            // the server answers with BYE and closes, a failure here changes nothing
            let _ = self.run("LOGOUT", Vec::new()).await;
        }
        self.closed = true;
        self.stream.shutdown().await;
        Ok(())
    }

    fn require_selected(&self) -> Result<&Selected, Error> {
        self.selected.as_ref().ok_or(Error::NoMailboxSelected)
    }

    fn compile_options(&self) -> CompileOptions {
        CompileOptions {
            literal_plus: self.has_capability("LITERAL+"),
            literal_minus: self.has_capability("LITERAL-"),
            utf8: self.is_enabled("UTF8=ACCEPT"),
        }
    }

    /// Writes to the wire log, building the line only when there is a log
    fn log(&self, direction: Direction, line: impl FnOnce() -> String) {
        if let Some(log) = &self.config.wire_log {
            log(direction, &line());
        }
    }

    fn emit(&self, event: Event) {
        // nobody listening is fine
        let _ = self.events.send(event);
    }

    async fn write(&mut self, data: &[u8]) -> Result<(), Error> {
        if self.closed {
            return Err(Error::Closed(self.bye.clone()));
        }
        let written = self.stream.write_all(data).await;
        written.map_err(|error| self.lost(pe_net::Error::Io(error).into()))
    }

    /// The connection is gone: reports it once and returns the error
    fn lost(&mut self, error: Error) -> Error {
        if !self.closed {
            self.closed = true;
            self.emit(Event::Closed(self.bye.clone()));
        }
        error
    }

    /// The next response from the server. A line that does not parse is skipped, unless it
    /// carries `tag`, the tag of the running command, which then fails with it.
    async fn read_response(&mut self, tag: Option<&str>, timeout: Option<Duration>) -> Result<Response, Error> {
        loop {
            if let Some(raw) = self.ready.pop_front() {
                if self.awaiting_answer.take().is_some() {
                    self.answered = Some(std::time::Instant::now());
                }
                self.log(Direction::Server, || {
                    String::from_utf8_lossy(&raw.line[..raw.line.len().min(LOG_LINE_LIMIT)]).into_owned()
                });
                match raw.parse_with(&ParserOptions::default()) {
                    Ok(response) => return Ok(response),
                    Err(error) if error.tag.is_some() && error.tag.as_deref() == tag => return Err(error.into()),
                    Err(_) => continue,
                }
            }
            if let Some(error) = self.framing_error.take() {
                return Err(self.lost(error.into()));
            }
            let timeout = match (self.awaiting_answer, timeout) {
                (Some(Some(first)), Some(limit)) => Some(first.min(limit)),
                _ => timeout,
            };
            let read = self.stream.read(&mut self.buffer);
            let count = match timeout {
                Some(limit) => match tokio::time::timeout(limit, read).await {
                    Ok(result) => result,
                    Err(_) => return Err(self.lost(Error::Timeout)),
                },
                None => read.await,
            };
            let count = count.map_err(|error| self.lost(pe_net::Error::Io(error).into()))?;
            if count == 0 {
                return Err(self.lost(Error::Closed(self.bye.clone())));
            }
            if self.awaiting_answer.take().is_some() {
                self.answered = Some(std::time::Instant::now());
            }
            if let Some((so_far, told)) = &mut self.received {
                *so_far += count as u64;
                told(*so_far);
            }
            let mut framed = Vec::new();
            let result = self.framer.push(&self.buffer[..count], &mut framed);
            self.ready.extend(framed);
            if let Err(error) = result {
                self.framing_error = Some(error);
            }
        }
    }

    /// Writes a command, up to its first synchronizing literal. Returns its tag and the parts
    /// that wait for the server's continuation.
    async fn send(&mut self, name: &str, args: Vec<Arg>) -> Result<(String, std::vec::IntoIter<Vec<u8>>), Error> {
        if self.closed {
            return Err(Error::Closed(self.bye.clone()));
        }
        let tag = format!("A{}", self.next_tag);
        self.next_tag += 1;
        let command = Command {
            tag,
            name: name.to_string(),
            args,
        };
        let segments = compile(&command, &self.compile_options())?;
        self.log(Direction::Client, || to_log_string(&command));
        // the arguments, a message for APPEND, are not needed once compiled
        let tag = command.tag;
        let mut segments = segments.into_iter();
        if let Some(first) = segments.next() {
            self.write(&first).await?;
        }
        Ok((tag, segments))
    }

    pub(crate) async fn run(&mut self, name: &str, args: Vec<Arg>) -> Result<Completion, Error> {
        self.run_with(name, args, &mut keep, None).await
    }

    /// Runs a command, Ok(None) when the server refused it: for what a session can do without
    pub(crate) async fn optional(&mut self, name: &str, args: Vec<Arg>) -> Result<Option<Completion>, Error> {
        match self.run(name, args).await {
            Ok(completion) => Ok(Some(completion)),
            Err(Error::Refused { .. }) => Ok(None),
            Err(error) => Err(error),
        }
    }

    pub(crate) async fn simple(&mut self, name: &str, args: Vec<Arg>) -> Result<(), Error> {
        self.run(name, args).await.map(|_| ())
    }

    /// Sends a command and reads until its completion. Literals wait for the server's
    /// continuation; any other continuation request goes to `continuation`.
    pub(crate) async fn run_with(
        &mut self,
        name: &str,
        args: Vec<Arg>,
        untagged: UntaggedHandler<'_>,
        mut continuation: Option<ContinuationHandler<'_>>,
    ) -> Result<Completion, Error> {
        let (tag, mut segments) = self.send(name, args).await?;
        self.answered = None;
        self.awaiting_answer = Some(self.answer_limit.take());
        if let Some((so_far, _)) = &mut self.received {
            *so_far = 0;
        }
        let mut collected = Vec::new();
        loop {
            let response = self
                .read_response(Some(&tag), Some(self.config.timeouts.response))
                .await?;
            if response.is_continuation() {
                let data = match (segments.next(), continuation.as_mut()) {
                    (Some(segment), _) => segment,
                    (None, Some(handler)) => handler(&response)?,
                    (None, None) => return Err(Error::Unexpected("continuation request".into())),
                };
                self.write(&data).await?;
            } else if response.tag == tag {
                return self.complete(name, response, collected);
            } else if response.is_untagged() {
                self.on_untagged(response, untagged, &mut collected)?;
            }
            // a tagged response for some other tag is not ours to handle
        }
    }

    /// An untagged response while a command runs: the command's handler first, then the session
    fn on_untagged(
        &mut self,
        response: Response,
        handler: UntaggedHandler<'_>,
        collected: &mut Vec<Response>,
    ) -> Result<(), Error> {
        let Some(kept) = handler(response)? else {
            return Ok(());
        };
        self.handle_untagged(&kept);
        if collected.len() >= MAX_COLLECTED_RESPONSES {
            return Err(Error::TooManyResponses);
        }
        collected.push(kept);
        Ok(())
    }

    /// The tagged completion of a command
    fn complete(&mut self, name: &str, tagged: Response, untagged: Vec<Response>) -> Result<Completion, Error> {
        self.update_from_code(&tagged);
        if tagged.command.eq_ignore_ascii_case("OK") {
            return Ok(Completion { untagged, tagged });
        }
        Err(Error::Refused {
            command: name.to_string(),
            status: tagged.command.to_ascii_uppercase(),
            code: tagged.code().map(|(code, _)| code),
            text: tagged.text().unwrap_or_default(),
        })
    }

    /// Capabilities and alerts from the response code of a status response
    fn update_from_code(&mut self, response: &Response) {
        let Some((code, args)) = response.code() else { return };
        match code.as_str() {
            "CAPABILITY" => self.set_capabilities(args),
            "ALERT" => self.emit(Event::Alert(response.text().unwrap_or_default())),
            _ => {}
        }
    }

    fn set_capabilities(&mut self, tokens: &[Token]) {
        self.capabilities = tokens
            .iter()
            .filter_map(Token::text)
            .map(|t| t.to_ascii_uppercase())
            .collect();
    }

    /// Keeps the session state current with what the server reports on its own
    fn handle_untagged(&mut self, response: &Response) {
        if let Some((seq, kind)) = response.message_data() {
            self.message_update(seq, kind, response);
            return;
        }
        let command = response.command.as_str();
        if command.eq_ignore_ascii_case("CAPABILITY") {
            self.set_capabilities(&response.attributes);
        } else if ["OK", "NO", "BAD"].iter().any(|s| command.eq_ignore_ascii_case(s)) {
            self.update_from_code(response);
        } else if command.eq_ignore_ascii_case("BYE") {
            self.bye = Some(response.text().unwrap_or_default());
        } else if command.eq_ignore_ascii_case("VANISHED") {
            self.vanished(response);
        }
    }

    /// `* 3 EXISTS`, `* 2 EXPUNGE`, `* 5 FETCH (FLAGS (...))`
    fn message_update(&mut self, seq: u32, kind: &Token, response: &Response) {
        let Some(selected) = self.selected.as_mut() else { return };
        let mailbox = selected.path.clone();
        if kind.is_atom("EXISTS") {
            selected.exists = seq;
            self.emit(Event::Exists { mailbox, count: seq });
        } else if kind.is_atom("EXPUNGE") {
            selected.exists = selected.exists.saturating_sub(1);
            self.emit(Event::Expunge { mailbox, seq });
        } else if kind.is_atom("FETCH")
            && let Some((uid, flags, modseq)) = fetch::flag_update(response)
        {
            self.emit(Event::Flags {
                mailbox,
                seq,
                uid,
                flags,
                modseq,
            });
        }
    }

    /// `* VANISHED (EARLIER) 1:3`
    fn vanished(&mut self, response: &Response) {
        let Some(selected) = &self.selected else { return };
        let earlier = response
            .attributes
            .first()
            .and_then(Token::as_list)
            .is_some_and(|items| items.iter().any(|t| t.is_atom("EARLIER")));
        let uids = response
            .attributes
            .last()
            .and_then(Token::text)
            .and_then(|t| SequenceSet::parse(&t).ok());
        if let Some(uids) = uids {
            self.emit(Event::Vanished {
                mailbox: selected.path.clone(),
                uids,
                earlier,
            });
        }
    }

    /// A mailbox name for the wire: UTF-8 when the server accepts it, modified UTF-7 otherwise
    fn encode_path(&self, path: &str) -> Arg {
        if path.eq_ignore_ascii_case("INBOX") {
            return Arg::atom("INBOX");
        }
        if self.is_enabled("UTF8=ACCEPT") {
            Arg::string(path)
        } else {
            Arg::string(crate::utf7::encode(path))
        }
    }

    /// A mailbox name from the wire
    fn decode_path(&self, raw: &str) -> String {
        if raw.eq_ignore_ascii_case("INBOX") {
            "INBOX".into()
        } else if self.is_enabled("UTF8=ACCEPT") {
            raw.to_string()
        } else {
            crate::utf7::decode(raw)
        }
    }
}
