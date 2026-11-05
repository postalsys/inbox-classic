//! `--mcp`: the program an agent starts as its MCP server. It opens no window and has no engine; it connects to the
//! running app (starting it in the background when it is not running) and passes MCP's lines both ways, after a
//! first line that names the program that started it.

use std::time::{Duration, Instant};

use pe_core::agents::HostInfo;
use tokio::io::{AsyncRead, AsyncWrite, AsyncWriteExt};

use crate::Endpoint;

/// How long a started app has to begin listening
const START_WAIT: Duration = Duration::from_secs(30);

#[derive(Debug)]
pub enum RelayError {
    /// The app is not running and could not be started
    NotRunning(String),
    Io(std::io::Error),
}

impl std::fmt::Display for RelayError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RelayError::NotRunning(why) => write!(f, "Inbox Classic is not running and could not be started: {why}"),
            RelayError::Io(error) => write!(f, "the connection to Inbox Classic failed: {error}"),
        }
    }
}

/// Relays stdin and stdout to the app at `endpoint` for the program `host`; `start` starts the app in the background
/// when it does not answer. Returns once either side closed.
pub fn relay(
    endpoint: &Endpoint,
    host: &HostInfo,
    start: impl FnOnce() -> std::io::Result<()>,
) -> Result<(), RelayError> {
    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .map_err(RelayError::Io)?;
    runtime.block_on(async {
        let stream = match connect(endpoint).await {
            Ok(stream) => stream,
            Err(_) => {
                start().map_err(|error| RelayError::NotRunning(error.to_string()))?;
                let deadline = Instant::now() + START_WAIT;
                loop {
                    tokio::time::sleep(Duration::from_millis(250)).await;
                    match connect(endpoint).await {
                        Ok(stream) => break stream,
                        Err(error) if Instant::now() >= deadline => {
                            return Err(RelayError::NotRunning(error.to_string()));
                        }
                        Err(_) => {}
                    }
                }
            }
        };
        pass(stream, host, tokio::io::stdin(), tokio::io::stdout())
            .await
            .map_err(RelayError::Io)
    })
}

/// `--mcp` of the app with the store at `store` open, for the program `host`: relays to it, starting it with
/// `--background` (and `--store`, when `store_argument` gave one) when it does not answer
pub fn relay_for_store(
    store: &std::path::Path,
    store_argument: Option<&std::path::Path>,
    host: &HostInfo,
) -> Result<(), RelayError> {
    let start = || {
        let mut command = std::process::Command::new(std::env::current_exe()?);
        command.arg("--background");
        if let Some(store) = store_argument {
            command.arg("--store").arg(store);
        }
        command
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
            .map(|_| ())
    };
    relay(&Endpoint::for_store(store), host, start)
}

/// Passes `input` to `stream` after the hello line, and what comes back to `output`, until either closes
pub(crate) async fn pass(
    stream: impl AsyncRead + AsyncWrite + Unpin,
    host: &HostInfo,
    mut input: impl AsyncRead + Unpin,
    mut output: impl AsyncWrite + Unpin,
) -> std::io::Result<()> {
    let (mut from_app, mut to_app) = tokio::io::split(stream);
    let mut hello = crate::server::hello_line(host);
    hello.push('\n');
    to_app.write_all(hello.as_bytes()).await?;
    let up = async {
        let result = tokio::io::copy(&mut input, &mut to_app).await;
        // the agent closed its side: the app sees the end
        let _ = to_app.shutdown().await;
        result
    };
    let down = async {
        let result = tokio::io::copy(&mut from_app, &mut output).await;
        let _ = output.flush().await;
        result
    };
    tokio::select! {
        result = up => result.map(|_| ()),
        result = down => result.map(|_| ()),
    }
}

fn not_ours() -> std::io::Error {
    std::io::Error::new(
        std::io::ErrorKind::PermissionDenied,
        "what answers there is not Inbox Classic of this user",
    )
}

/// This process's user, as the system gives it to a file it makes (reading it directly takes unsafe code)
#[cfg(unix)]
fn own_uid() -> std::io::Result<u32> {
    use std::os::unix::fs::MetadataExt;
    let probe = std::env::temp_dir().join(format!("inbox-classic-relay-{}", std::process::id()));
    let file = std::fs::OpenOptions::new().write(true).create_new(true).open(&probe);
    let uid = file.and_then(|file| file.metadata()).map(|metadata| metadata.uid());
    let _ = std::fs::remove_file(&probe);
    uid
}

/// A connection to the app at `endpoint`, refused when what answers there runs as another user (one who took the
/// name first, on a shared machine): nothing the agent sends reaches anyone else
#[cfg(unix)]
async fn connect(endpoint: &Endpoint) -> std::io::Result<Box<dyn Stream>> {
    match endpoint {
        Endpoint::Socket(path) => {
            let stream = tokio::net::UnixStream::connect(path).await?;
            if stream.peer_cred()?.uid() != own_uid()? {
                return Err(not_ours());
            }
            Ok(Box::new(stream))
        }
        Endpoint::Pipe(_) => Err(std::io::ErrorKind::Unsupported.into()),
    }
}

/// How a named pipe's server is checked: pe-ffi's check that it runs as this user (it takes the system's process
/// calls, so unsafe code)
#[cfg(windows)]
static PIPE_CHECK: std::sync::OnceLock<fn(std::os::windows::io::RawHandle) -> bool> = std::sync::OnceLock::new();

/// Sets the check of the server at the other end of a named pipe, before any relay connects
#[cfg(windows)]
pub fn set_pipe_check(check: fn(std::os::windows::io::RawHandle) -> bool) {
    let _ = PIPE_CHECK.set(check);
}

#[cfg(windows)]
async fn connect(endpoint: &Endpoint) -> std::io::Result<Box<dyn Stream>> {
    use std::os::windows::io::AsRawHandle;
    match endpoint {
        Endpoint::Pipe(name) => {
            let pipe = tokio::net::windows::named_pipe::ClientOptions::new().open(name)?;
            // without the check there is no relay: one that could not tell would hand the agent to anyone
            let check = PIPE_CHECK.get().ok_or_else(not_ours)?;
            if !check(pipe.as_raw_handle()) {
                return Err(not_ours());
            }
            Ok(Box::new(pipe))
        }
        Endpoint::Socket(_) => Err(std::io::ErrorKind::Unsupported.into()),
    }
}

trait Stream: AsyncRead + AsyncWrite + Unpin + Send {}
impl<T: AsyncRead + AsyncWrite + Unpin + Send> Stream for T {}

#[cfg(all(test, unix))]
mod tests {
    use super::*;

    #[tokio::test]
    async fn the_relay_connects_to_this_users_app_only() {
        let dir = std::env::temp_dir().join(format!("inbox-classic-relay-test-{}", std::process::id()));
        let _ = std::fs::create_dir_all(&dir);
        let path = dir.join("mcp.sock");
        let _ = std::fs::remove_file(&path);
        let listener = tokio::net::UnixListener::bind(&path).unwrap();
        // this user's: let through
        let accepted = tokio::spawn(async move { listener.accept().await.map(|_| ()) });
        assert!(connect(&Endpoint::Socket(path.clone())).await.is_ok());
        accepted.await.unwrap().unwrap();
        // nothing there: refused, so the relay starts the app
        let _ = std::fs::remove_file(&path);
        assert!(connect(&Endpoint::Socket(path)).await.is_err());
        let _ = std::fs::remove_dir_all(&dir);
        // the user is read from a file made for it
        assert!(own_uid().is_ok());
    }
}
