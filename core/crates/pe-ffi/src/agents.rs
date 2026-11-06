//! AI agents through C: the MCP server of the running app and the `--mcp` relay, the questions the user answers (a
//! program that connects for the first time, a message an agent wants to send), the programs let in and what they may
//! do, and the log of what they did. The rules are pe-core's; the windows show and answer.

use std::ffi::c_char;
use std::ptr::{null, null_mut};

use pe_core::agents::{AgentAnswer, AgentAsk, AgentLevels};

use crate::core::{PeCore, Rows, Strings, arg, draft_handle, handed, take_back, with};
use crate::{PeDraft, guard, into_c_string};

// literals, as cbindgen writes only those to the header; the test below keeps them the core's

/// What an agent may do, bits for `levels`: read mail
pub const PE_AGENT_READ: u32 = 1;
/// Organize it: read state, flags, junk, moves, deletes to Deleted Items
pub const PE_AGENT_ORGANIZE: u32 = 2;
/// Write drafts
pub const PE_AGENT_DRAFTS: u32 = 4;
/// Send, each message after the user says yes
pub const PE_AGENT_SEND: u32 = 8;
/// What a program the user lets in is offered first
pub const PE_AGENT_DEFAULT: u32 = 3;
/// How long a message an agent sent waits in the Outbox, in seconds
pub const PE_AGENT_SEND_DELAY: i64 = 30;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_constants_are_the_cores() {
        assert_eq!(
            [
                PE_AGENT_READ,
                PE_AGENT_ORGANIZE,
                PE_AGENT_DRAFTS,
                PE_AGENT_SEND,
                PE_AGENT_DEFAULT
            ],
            [
                AgentLevels::READ,
                AgentLevels::ORGANIZE,
                AgentLevels::DRAFTS,
                AgentLevels::SEND,
                AgentLevels::DEFAULT.0
            ]
        );
        assert_eq!(PE_AGENT_SEND_DELAY, pe_core::agents::SEND_DELAY);
        assert_eq!(PE_AGENT_LEVEL_COUNT, pe_core::agents::LEVELS.len());
        assert_eq!(pe_agent_level_bit(0), PE_AGENT_READ);
        assert!(!pe_agent_level_label(3).is_null() && pe_agent_level_label(4).is_null());
    }
}

// ---- the server and the relay ----

/// Starts the MCP server agents reach this app on (a socket or named pipe of its own, for this store and this user);
/// false when it could not (another app has this store open). Stopped by `pe_core_close`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_mcp_start(core: *const PeCore) -> bool {
    // SAFETY: as the caller guarantees
    let Some(handle) = (unsafe { core.as_ref() }) else {
        return false;
    };
    guard(|| {
        let mut mcp = handle.mcp.lock().unwrap_or_else(|p| p.into_inner());
        if mcp.is_none() {
            #[cfg(unix)]
            let started = pe_mcp::McpServer::for_store(handle.core.clone(), &handle.store);
            #[cfg(windows)]
            let started = crate::windows::listen_pipe(
                handle.core.clone(),
                &pe_mcp::Endpoint::for_store(&handle.store).path().to_string_lossy(),
            );
            *mcp = started.ok();
        }
        mcp.is_some()
    })
    .unwrap_or(false)
}

/// `--mcp`: relays stdin and stdout to the app that has the store at `store` open, for the program that started
/// this process, until either side closes; the process should then end. When the app is not running it is started
/// with `--background` (and `--store store_argument` when that is not NULL). 0 when the relay ran, 1 when the app could
/// not be reached (the reason on stderr).
///
/// # Safety
/// `store` must be a NUL-terminated string; `store_argument` NULL or one.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_mcp_relay(store: *const c_char, store_argument: *const c_char) -> i32 {
    // SAFETY: as the caller guarantees
    let (Some(store), argument) = (unsafe { arg(store) }, unsafe { arg(store_argument) }) else {
        return 1;
    };
    guard(|| {
        #[cfg(windows)]
        let host = {
            pe_mcp::set_pipe_check(crate::windows::pipe_server_is_mine);
            crate::windows::launching_program()
        };
        #[cfg(not(windows))]
        let host = pe_mcp::launching_program();
        match pe_mcp::relay_for_store(std::path::Path::new(store), argument.map(std::path::Path::new), &host) {
            Ok(()) => 0,
            Err(error) => {
                eprintln!("{error}");
                1
            }
        }
    })
    .unwrap_or(1)
}

/// The levels an agent may be given, as the windows offer them: `count` of them
pub const PE_AGENT_LEVEL_COUNT: usize = 4;

/// The bit (PE_AGENT_*) of level `index`, 0 past the end
#[unsafe(no_mangle)]
pub extern "C" fn pe_agent_level_bit(index: usize) -> u32 {
    pe_core::agents::LEVELS.get(index).map_or(0, |(bit, _)| *bit)
}

/// What level `index` lets an agent do, in the language in use: a string kept for the rest of the run, not freed;
/// NULL past the end
#[unsafe(no_mangle)]
pub extern "C" fn pe_agent_level_label(index: usize) -> *const c_char {
    type Labels = std::collections::HashMap<&'static str, Vec<std::ffi::CString>>;
    // one set a language: a handful of strings at most, so the pointers handed out stay valid
    static LABELS: std::sync::Mutex<Option<Labels>> = std::sync::Mutex::new(None);
    let mut labels = LABELS.lock().unwrap_or_else(|e| e.into_inner());
    let labels = labels.get_or_insert_with(Labels::new);
    let set = labels.entry(pe_i18n::language()).or_insert_with(|| {
        pe_core::agents::LEVELS
            .iter()
            .map(|(bit, _)| crate::c_string(pe_core::agents::level_text(*bit)))
            .collect()
    });
    set.get(index).map_or(null(), |label| label.as_ptr())
}

/// What an agent's settings name to start this app as its MCP server: a JSON block for the `mcpServers` of Claude
/// Desktop, Cursor and the like, with this executable and `--mcp` (and `--store` when the store is not the usual
/// one, `store_argument` not NULL). Free with `pe_string_free`.
///
/// # Safety
/// `store_argument` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_mcp_config(store_argument: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let store = unsafe { arg(store_argument) };
    guard(|| {
        let exe = std::env::current_exe()
            .map(|p| p.to_string_lossy().into_owned())
            .unwrap_or_default();
        into_c_string(pe_core::agents::mcp_config(&exe, store))
    })
    .unwrap_or(null_mut())
}

// ---- questions ----

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeAgentAskKind {
    /// Answered already, or no such question
    None = 0,
    /// A program wants to connect: `pe_agent_connect_info`, answered with `pe_agent_answer_connect`
    Connect = 1,
    /// An agent wants to send a message: `pe_agent_send_info`, answered with `pe_agent_answer_send`
    Send = 2,
}

/// What question `request` (an `AgentAsk` event) is
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_ask_kind(core: *const PeCore, request: u64) -> PeAgentAskKind {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, PeAgentAskKind::None, |core| match core.agent_ask(request) {
            Some(AgentAsk::Connect { .. }) => PeAgentAskKind::Connect,
            Some(AgentAsk::Send(_)) => PeAgentAskKind::Send,
            None => PeAgentAskKind::None,
        })
    }
}

/// A program that wants to connect
#[repr(C)]
pub struct PeAgentConnect {
    /// Its file
    pub path: *const c_char,
    /// The question for the dialog: "Claude wants to use your mail"
    pub title: *const c_char,
    /// What the dialog says under it
    pub detail: *const c_char,
}

pub struct PeAgentConnectInfo {
    info: PeAgentConnect,
    _strings: Strings,
}

/// The program of question `request`, NULL when it is not a Connect question. Free with `pe_agent_connect_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_connect_info(core: *const PeCore, request: u64) -> *mut PeAgentConnectInfo {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Some(AgentAsk::Connect { host, .. }) = core.agent_ask(request) else {
                return null_mut();
            };
            let mut strings = Strings::default();
            let (title, detail) = pe_core::agents::connect_text(&host);
            let info = PeAgentConnect {
                path: strings.add(&host.path),
                title: strings.add(&title),
                detail: strings.add(&detail),
            };
            handed(PeAgentConnectInfo {
                info,
                _strings: strings,
            })
        })
    }
}

/// # Safety
/// `info` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_connect(info: *const PeAgentConnectInfo) -> *const PeAgentConnect {
    // SAFETY: as the caller guarantees
    unsafe { info.as_ref() }.map_or(null(), |info| &info.info)
}

/// # Safety
/// `info` must be NULL or not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_connect_free(info: *mut PeAgentConnectInfo) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(info) }
}

/// Answers a Connect question: let the program in with `levels` (PE_AGENT_* bits) on the `count` accounts in
/// `accounts`, or turn it away (`allow` false; it is not asked about again). False when the question was answered
/// already.
///
/// # Safety
/// `core` must be a live handle; `accounts` must point to `count` ids (NULL when 0).
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_answer_connect(
    core: *const PeCore,
    request: u64,
    allow: bool,
    levels: u32,
    accounts: *const i64,
    count: usize,
) -> bool {
    // SAFETY: as the caller guarantees
    let accounts = unsafe { ids(accounts, count) };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, false, |core| {
            let answer = if allow {
                AgentAnswer::Allow {
                    levels: AgentLevels(levels),
                    accounts,
                }
            } else {
                AgentAnswer::Deny
            };
            core.agent_answer(request, answer).is_ok()
        })
    }
}

/// `count` ids at `ids`
///
/// # Safety
/// `ids` must point to `count` values, or be NULL with 0.
unsafe fn ids(ids: *const i64, count: usize) -> Vec<i64> {
    if ids.is_null() || count == 0 {
        return Vec::new();
    }
    // SAFETY: as the caller guarantees
    unsafe { std::slice::from_raw_parts(ids, count) }.to_vec()
}

/// A recipient of a message an agent wants to send
#[repr(C)]
pub struct PeAgentRecipient {
    /// `To`, `Cc` or `Bcc`
    pub field: *const c_char,
    pub name: *const c_char,
    pub address: *const c_char,
    /// The user never wrote to this address
    pub new_address: bool,
}

/// A message an agent wants to send, as the confirmation shows it
#[repr(C)]
pub struct PeAgentSend {
    /// The account it goes from
    pub account: i64,
    /// The dialog's title line: "Claude wants to send this message"
    pub title: *const c_char,
    /// What the dialog says under it
    pub detail: *const c_char,
    /// The account, as From shows it
    pub from: *const c_char,
    pub subject: *const c_char,
    /// What goes, as plain text (the quoted message of a reply after it, as the mail program adds it)
    pub text: *const c_char,
    /// "Reply to "Plans"", "Forward of ..."; empty for a new message
    pub original: *const c_char,
    /// One line, "You have never written to a@b.c", empty when none is new
    pub warning: *const c_char,
    /// The files that go with it, one line ("Files: a.pdf (13 KB)"), empty without any
    pub files: *const c_char,
}

pub struct PeAgentSendInfo {
    info: PeAgentSend,
    recipients: Rows<PeAgentRecipient>,
    _strings: Strings,
}

/// The message of question `request`, NULL when it is not a Send question. Free with `pe_agent_send_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_send_info(core: *const PeCore, request: u64) -> *mut PeAgentSendInfo {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Some(AgentAsk::Send(ask)) = core.agent_ask(request) else {
                return null_mut();
            };
            let text = pe_core::agents::send_text(&ask);
            let mut strings = Strings::default();
            let info = PeAgentSend {
                account: ask.account,
                title: strings.add(&text.title),
                detail: strings.add(&text.detail),
                from: strings.add(&ask.from),
                subject: strings.add(&ask.subject),
                text: strings.add(&ask.text),
                original: strings.add(&text.original),
                warning: strings.add(&text.warning),
                files: strings.add(&pe_core::agents::files_text(&ask)),
            };
            let recipients = Rows::new(&ask.recipients, |r, strings| PeAgentRecipient {
                field: strings.add(r.field),
                name: strings.add(&r.name),
                address: strings.add(&r.address),
                new_address: r.new,
            });
            handed(PeAgentSendInfo {
                info,
                recipients,
                _strings: strings,
            })
        })
    }
}

/// # Safety
/// `info` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_send(info: *const PeAgentSendInfo) -> *const PeAgentSend {
    // SAFETY: as the caller guarantees
    unsafe { info.as_ref() }.map_or(null(), |info| &info.info)
}

/// # Safety
/// `info` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_send_recipient_count(info: *const PeAgentSendInfo) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { info.as_ref() }.map(|info| &info.recipients))
}

/// Recipient `index`, NULL past the end
///
/// # Safety
/// `info` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_send_recipient(
    info: *const PeAgentSendInfo,
    index: usize,
) -> *const PeAgentRecipient {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { info.as_ref() }.map(|info| &info.recipients), index)
}

/// # Safety
/// `info` must be NULL or not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_send_free(info: *mut PeAgentSendInfo) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(info) }
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeAgentSendAnswer {
    /// Into the Outbox, to go after PE_AGENT_SEND_DELAY seconds
    Send = 0,
    /// Nothing sent: the draft comes back, for the window that writes a message
    Compose = 1,
    DontSend = 2,
}

/// Answers a Send question. For Compose the draft to open in a new message comes back (free with
/// `pe_draft_free`); NULL otherwise, or when the question was answered already.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_answer_send(
    core: *const PeCore,
    request: u64,
    answer: PeAgentSendAnswer,
) -> *mut PeDraft {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let answer = match answer {
                PeAgentSendAnswer::Send => AgentAnswer::Send,
                PeAgentSendAnswer::Compose => AgentAnswer::Compose,
                PeAgentSendAnswer::DontSend => AgentAnswer::DontSend,
            };
            match core.agent_answer(request, answer) {
                Ok(Some(draft)) => draft_handle(&draft),
                _ => null_mut(),
            }
        })
    }
}

// ---- the programs let in, and the log ----

/// Whether agents may connect at all
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agents_enabled(core: *const PeCore) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.agents_enabled().unwrap_or(false)) }
}

/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agents_set_enabled(core: *const PeCore, enabled: bool) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.set_agents_enabled(enabled).is_ok()) }
}

/// A program the user decided about
#[repr(C)]
pub struct PeAgentHost {
    pub id: i64,
    pub name: *const c_char,
    pub path: *const c_char,
    pub allowed: bool,
    /// PE_AGENT_* bits
    pub levels: u32,
    /// What it may do, in words: "Read and organize mail, 1 account", "Turned away"
    pub access: *const c_char,
    /// Seconds since the Unix epoch, 0 when never
    pub last_used: i64,
    /// The heading and the words of Change for it
    pub change_title: *const c_char,
    pub change_detail: *const c_char,
}

pub struct PeAgentHostList {
    rows: Rows<PeAgentHost>,
    accounts: Vec<Vec<i64>>,
}

/// The programs the user decided about, by name. Free with `pe_agent_host_list_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_hosts(core: *const PeCore) -> *mut PeAgentHostList {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(hosts) = core.agent_hosts() else {
                return null_mut();
            };
            let rows = Rows::new(&hosts, |h, strings| {
                let (change_title, change_detail) = pe_core::agents::change_text(h);
                PeAgentHost {
                    id: h.id,
                    name: strings.add(&h.name),
                    path: strings.add(&h.path),
                    allowed: h.allowed,
                    levels: h.levels.0,
                    access: strings.add(&pe_core::agents::access_text(h)),
                    last_used: h.last_used.unwrap_or(0),
                    change_title: strings.add(&change_title),
                    change_detail: strings.add(&change_detail),
                }
            });
            handed(PeAgentHostList {
                rows,
                accounts: hosts.iter().map(|h| h.accounts.clone()).collect(),
            })
        })
    }
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_host_list_count(list: *const PeAgentHostList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.rows))
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_host_list_get(list: *const PeAgentHostList, index: usize) -> *const PeAgentHost {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.rows), index)
}

/// Whether host `index` of the list may use `account`
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_host_list_has_account(
    list: *const PeAgentHostList,
    index: usize,
    account: i64,
) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { list.as_ref() }
        .and_then(|list| list.accounts.get(index))
        .is_some_and(|accounts| accounts.contains(&account))
}

/// # Safety
/// `list` must be NULL or not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_host_list_free(list: *mut PeAgentHostList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Changes what a program may do
///
/// # Safety
/// `core` must be a live handle; `accounts` must point to `count` ids (NULL when 0).
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_host_update(
    core: *const PeCore,
    id: i64,
    allowed: bool,
    levels: u32,
    accounts: *const i64,
    count: usize,
) -> bool {
    // SAFETY: as the caller guarantees
    let accounts = unsafe { ids(accounts, count) };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, false, |core| {
            core.update_agent_host(id, allowed, AgentLevels(levels), &accounts)
                .is_ok()
        })
    }
}

/// Forgets a program and what it did: it is asked about again the next time it connects
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_host_remove(core: *const PeCore, id: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.remove_agent_host(id).is_ok()) }
}

/// What an agent did
#[repr(C)]
pub struct PeAgentLogEntry {
    pub id: i64,
    /// The program
    pub host: *const c_char,
    /// Seconds since the Unix epoch
    pub at: i64,
    /// `Moved "Invoice 12" to Archive`, with "(taken back)" once it was
    pub summary: *const c_char,
    /// `pe_agent_undo` can take it back
    pub can_undo: bool,
    /// It was taken back
    pub undone: bool,
}

pub struct PeAgentLog(Rows<PeAgentLogEntry>);

/// The newest `limit` entries of what agents did, newest first. Free with `pe_agent_log_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_log(core: *const PeCore, limit: u64) -> *mut PeAgentLog {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(log) = core.agent_log(limit) else {
                return null_mut();
            };
            handed(PeAgentLog(Rows::new(&log, |e, strings| PeAgentLogEntry {
                id: e.id,
                host: strings.add(&e.host_name),
                at: e.at,
                summary: strings.add(&pe_core::agents::log_text(e)),
                can_undo: e.entry.undo.is_some() && !e.undone,
                undone: e.undone,
            })))
        })
    }
}

/// # Safety
/// `log` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_log_count(log: *const PeAgentLog) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { log.as_ref() }.map(|log| &log.0))
}

/// # Safety
/// `log` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_log_get(log: *const PeAgentLog, index: usize) -> *const PeAgentLogEntry {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { log.as_ref() }.map(|log| &log.0), index)
}

/// # Safety
/// `log` must be NULL or not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_log_free(log: *mut PeAgentLog) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(log) }
}

/// Takes back what log entry `id` did: NULL when it was, else why not (free with `pe_string_free`)
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_undo(core: *const PeCore, id: i64) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.agent_undo(id) {
            Ok(()) => null_mut(),
            Err(error) => into_c_string(pe_core::agents::undo_refusal(&error)),
        })
    }
}

/// Forgets what agents did
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_agent_log_clear(core: *const PeCore) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.clear_agent_log().is_ok()) }
}
