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
use std::sync::Arc;
use std::time::Duration;

use pe_net::{Security, Stream, Trust};
use tokio::sync::mpsc::{UnboundedReceiver, UnboundedSender, unbounded_channel};

use crate::compiler::{Arg, Command, CompileOptions, compile, to_log_string};
use crate::framing::{FrameLimits, Framer, RawResponse};
use crate::parser::ParserOptions;
use crate::types::{Response, Token};

pub use auth::Credentials;
pub use error::Error;
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
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Direction {
    Client,
    Server,
}

/// Receives the protocol log: commands with secrets and message data hidden, server lines cut at
/// 1000 bytes
pub type WireLog = Arc<dyn Fn(Direction, &str) + Send + Sync>;

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
    /// Sent with ID, `("name", "PostalExpress")`
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
            client_id: vec![("name".into(), "PostalExpress".into())],
            timeouts: Timeouts::default(),
            limits: FrameLimits::default(),
            wire_log: None,
        }
    }
}

/// A change the server reported about the selected mailbox, or about the connection
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Event {
    /// The mailbox has this many messages now
    Exists { count: u32 },
    /// The message with this sequence number is gone, later ones moved down by one
    Expunge { seq: u32 },
    /// Messages with these UIDs are gone (QRESYNC)
    Vanished { uids: String, earlier: bool },
    /// The flags of a message changed
    Flags {
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

/// Decides what to do with an untagged response while a command runs: keep it in the
/// completion or not (it was handled)
type UntaggedHandler<'a> = &'a mut dyn FnMut(Response) -> Result<Option<Response>, Error>;

/// The data to send for a `+` continuation that is not a literal
type ContinuationHandler<'a> = &'a mut dyn FnMut(&Response) -> Result<Vec<u8>, Error>;

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
    /// Whether untagged FETCH responses belong to the running command (FETCH) rather than being
    /// changes to report
    collecting_fetch: bool,
    bye: Option<String>,
    closed: bool,
    /// Set when a response code listed the capabilities, so they need not be asked for
    capabilities_from_code: bool,
    events: UnboundedSender<Event>,
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
            collecting_fetch: false,
            bye: None,
            closed: false,
            capabilities_from_code: false,
            events,
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
        self.capability().await?;
        Ok(())
    }

    async fn id(&mut self) -> Result<(), Error> {
        let fields = self
            .config
            .client_id
            .iter()
            .flat_map(|(k, v)| [Arg::string(k.as_str()), Arg::string(v.as_str())]);
        let args = vec![Arg::List(fields.collect())];
        // ID is informational, a server that refuses it is still usable
        match self.run("ID", args).await {
            Ok(_) | Err(Error::Refused { .. }) => Ok(()),
            Err(error) => Err(error),
        }
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
        match self.run("ENABLE", wanted).await {
            Ok(completion) => {
                for response in completion
                    .untagged
                    .iter()
                    .filter(|r| r.command.eq_ignore_ascii_case("ENABLED"))
                {
                    self.enabled.extend(
                        response
                            .attributes
                            .iter()
                            .filter_map(Token::text)
                            .map(|t| t.to_ascii_uppercase()),
                    );
                }
                Ok(())
            }
            Err(Error::Refused { .. }) => Ok(()),
            Err(error) => Err(error),
        }
    }

    /// Asks for the capabilities again
    pub async fn capability(&mut self) -> Result<(), Error> {
        self.run("CAPABILITY", Vec::new()).await.map(|_| ())
    }

    pub fn has_capability(&self, name: &str) -> bool {
        self.capabilities.contains(&name.to_ascii_uppercase())
    }

    pub fn capabilities(&self) -> &HashSet<String> {
        &self.capabilities
    }

    /// Whether an extension was enabled with ENABLE (CONDSTORE, UTF8=ACCEPT)
    pub fn is_enabled(&self, name: &str) -> bool {
        self.enabled.contains(&name.to_ascii_uppercase())
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

    pub async fn noop(&mut self) -> Result<(), Error> {
        self.run("NOOP", Vec::new()).await.map(|_| ())
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

    fn compile_options(&self) -> CompileOptions {
        CompileOptions {
            literal_plus: self.has_capability("LITERAL+"),
            literal_minus: self.has_capability("LITERAL-"),
            utf8: self.is_enabled("UTF8=ACCEPT"),
        }
    }

    fn log(&self, direction: Direction, line: &str) {
        if let Some(log) = &self.config.wire_log {
            log(direction, line);
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
        self.stream
            .write_all(data)
            .await
            .map_err(|error| self.lost(error.into()))
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
                let line = String::from_utf8_lossy(&raw.line[..raw.line.len().min(LOG_LINE_LIMIT)]).into_owned();
                self.log(Direction::Server, &line);
                match raw.parse_with(&ParserOptions::default()) {
                    Ok(response) => return Ok(response),
                    Err(error) if error.tag.is_some() && error.tag.as_deref() == tag => return Err(error.into()),
                    Err(_) => continue,
                }
            }
            if let Some(error) = self.framing_error.take() {
                return Err(self.lost(error.into()));
            }
            let read = self.stream.read(&mut self.buffer);
            let count = match timeout {
                Some(limit) => match tokio::time::timeout(limit, read).await {
                    Ok(result) => result,
                    Err(_) => return Err(self.lost(Error::Timeout)),
                },
                None => read.await,
            };
            let count = count.map_err(|error| self.lost(error.into()))?;
            if count == 0 {
                return Err(self.lost(Error::Closed(self.bye.clone())));
            }
            let mut framed = Vec::new();
            let result = self.framer.push(&self.buffer[..count], &mut framed);
            self.ready.extend(framed);
            if let Err(error) = result {
                self.framing_error = Some(error);
            }
        }
    }

    fn next_tag(&mut self) -> String {
        let tag = format!("A{}", self.next_tag);
        self.next_tag += 1;
        tag
    }

    pub(crate) async fn run(&mut self, name: &str, args: Vec<Arg>) -> Result<Completion, Error> {
        self.run_with(name, args, &mut |response| Ok(Some(response)), &mut |_| {
            Err(Error::Unexpected("continuation request".into()))
        })
        .await
    }

    /// Sends a command and reads until its completion. Literals wait for the server's
    /// continuation; any other continuation request goes to `continuation`.
    pub(crate) async fn run_with(
        &mut self,
        name: &str,
        args: Vec<Arg>,
        untagged: UntaggedHandler<'_>,
        continuation: ContinuationHandler<'_>,
    ) -> Result<Completion, Error> {
        if self.closed {
            return Err(Error::Closed(self.bye.clone()));
        }
        let command = Command {
            tag: self.next_tag(),
            name: name.to_string(),
            args,
        };
        let segments = compile(&command, &self.compile_options())?;
        self.log(Direction::Client, &to_log_string(&command));
        let mut segments = segments.into_iter();
        if let Some(first) = segments.next() {
            self.write(&first).await?;
        }

        let mut collected = Vec::new();
        loop {
            let response = self
                .read_response(Some(&command.tag), Some(self.config.timeouts.response))
                .await?;
            if response.is_continuation() {
                let data = match segments.next() {
                    Some(segment) => segment,
                    None => continuation(&response)?,
                };
                self.write(&data).await?;
                continue;
            }
            if response.tag == command.tag {
                self.update_from_code(&response);
                return self.complete(name, response, collected);
            }
            if response.is_untagged() {
                self.handle_untagged(&response);
                if let Some(keep) = untagged(response)? {
                    if collected.len() >= MAX_COLLECTED_RESPONSES {
                        return Err(Error::TooManyResponses);
                    }
                    collected.push(keep);
                }
            }
            // a tagged response for some other tag is not ours to handle
        }
    }

    fn complete(&mut self, name: &str, tagged: Response, untagged: Vec<Response>) -> Result<Completion, Error> {
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
            "CAPABILITY" => {
                self.set_capabilities(args);
                self.capabilities_from_code = true;
            }
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
        let command = response.command.to_ascii_uppercase();
        match command.as_str() {
            "CAPABILITY" => self.set_capabilities(&response.attributes),
            "OK" | "NO" | "BAD" => self.update_from_code(response),
            "BYE" => self.bye = Some(response.text().unwrap_or_default()),
            "VANISHED" => self.vanished(response),
            _ => {
                if let Ok(seq) = command.parse::<u32>() {
                    self.message_update(seq, response);
                }
            }
        }
    }

    /// `* 3 EXISTS`, `* 2 EXPUNGE`, `* 5 FETCH (FLAGS (...))`
    fn message_update(&mut self, seq: u32, response: &Response) {
        let Some(selected) = self.selected.as_mut() else { return };
        let Some(kind) = response.attributes.first().and_then(Token::text) else {
            return;
        };
        match kind.to_ascii_uppercase().as_str() {
            "EXISTS" => {
                selected.exists = seq;
                self.emit(Event::Exists { count: seq });
            }
            "EXPUNGE" => {
                selected.exists = selected.exists.saturating_sub(1);
                self.emit(Event::Expunge { seq });
            }
            "FETCH" if !self.collecting_fetch => {
                let message = fetch::parse_fetch(seq, response);
                if let Some(flags) = message.flags {
                    self.emit(Event::Flags {
                        seq,
                        uid: message.uid,
                        flags,
                        modseq: message.modseq,
                    });
                }
            }
            _ => {}
        }
    }

    /// `* VANISHED (EARLIER) 1:3`
    fn vanished(&mut self, response: &Response) {
        let earlier = matches!(response.attributes.first(), Some(Token::List(items)) if items.iter().any(|t| t.is_atom("EARLIER")));
        if let Some(uids) = response.attributes.last().and_then(Token::text) {
            self.emit(Event::Vanished { uids, earlier });
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
