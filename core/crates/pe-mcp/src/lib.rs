//! The MCP server (Model Context Protocol, JSON-RPC 2.0 over a stream) that lets the user's own AI agents work on the
//! mailbox, and the relay (`--mcp`) through which agents reach it.
//!
//! Agents run their MCP servers as programs they start and talk to over stdin and stdout, so they start the app's own
//! executable with `--mcp`. That relay opens no window and has no engine: it connects to the running app over a channel
//! only the same user can reach (a Unix socket in a private folder, a named pipe on Windows, which pe-ffi listens on)
//! and passes the bytes both ways, after a first line that names the program it was started by (the app finds that
//! program again itself, from the process the system says is at the other end: [`verified_program`]). The server
//! offers tools, resources (`inboxclassic://`, read through the tools, with subscriptions) and prompts. It lives in
//! the running app, on the same [`pe_core::Core`] as its windows: what an agent changes goes through the methods the
//! menus use, so the windows show it at once. The engine's rules for agents (who may connect, what each may do, the
//! user's yes before every send) are pe-core's `agents`; this crate speaks the protocol and offers the tools.
#![forbid(unsafe_code)]

mod endpoint;
mod host;
mod prompts;
mod protocol;
mod relay;
mod resources;
mod server;
mod tools;

pub use endpoint::Endpoint;
pub use host::{Lookup, Process, launching_program, set_process_lookup, verified_program};
#[cfg(windows)]
pub use relay::set_pipe_check;
pub use relay::{RelayError, named_by_arguments, relay, relay_for_store};
pub use server::{Listener, McpServer, serve};
