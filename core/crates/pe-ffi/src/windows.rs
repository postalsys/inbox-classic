//! What agents need of Windows itself: the named pipe the app listens on, which only the user running it can open,
//! the process at the other end of a connection to it, and each process's executable and parent, by which pe-mcp
//! finds the program that started the relay.

use std::ffi::c_void;
use std::sync::Arc;

use pe_core::Core;
use tokio::net::windows::named_pipe::{NamedPipeServer, ServerOptions};
use windows_sys::Win32::Foundation::{CloseHandle, FILETIME, HANDLE, HLOCAL, INVALID_HANDLE_VALUE, LocalFree};
use windows_sys::Win32::Security::Authorization::{
    ConvertSidToStringSidW, ConvertStringSecurityDescriptorToSecurityDescriptorW, SDDL_REVISION_1,
};
use windows_sys::Win32::Security::{
    GetTokenInformation, PSECURITY_DESCRIPTOR, SECURITY_ATTRIBUTES, TOKEN_QUERY, TOKEN_USER, TokenUser,
};
use windows_sys::Win32::System::Diagnostics::ToolHelp::{
    CreateToolhelp32Snapshot, PROCESSENTRY32W, Process32FirstW, Process32NextW, TH32CS_SNAPPROCESS,
};
use windows_sys::Win32::System::Pipes::{GetNamedPipeClientProcessId, GetNamedPipeServerProcessId};
use windows_sys::Win32::System::Threading::{
    GetCurrentProcess, GetProcessTimes, OpenProcess, OpenProcessToken, PROCESS_NAME_WIN32,
    PROCESS_QUERY_LIMITED_INFORMATION, QueryFullProcessImageNameW,
};

/// A security descriptor that lets only the current user (and nobody else, not even administrators through it) open
/// the pipe, freed when dropped
struct UserOnly(PSECURITY_DESCRIPTOR);

// SAFETY: the descriptor is plain memory, read by the system while a pipe is created
unsafe impl Send for UserOnly {}

impl Drop for UserOnly {
    fn drop(&mut self) {
        // SAFETY: from ConvertStringSecurityDescriptorToSecurityDescriptorW, freed once
        unsafe { LocalFree(self.0 as HLOCAL) };
    }
}

/// The SID of the user running this process, as text (`S-1-5-21-...`)
fn user_sid() -> Option<String> {
    // SAFETY: the current process's pseudo handle needs no closing
    unsafe { process_sid(GetCurrentProcess()) }
}

/// The SID of the user `process` runs as, as text
///
/// # Safety
/// `process` must be a process handle with query rights, or the current process's pseudo handle.
unsafe fn process_sid(process: HANDLE) -> Option<String> {
    // SAFETY: the token and the buffer are this function's own, closed and freed on every path
    unsafe {
        let mut token: HANDLE = std::ptr::null_mut();
        if OpenProcessToken(process, TOKEN_QUERY, &mut token) == 0 {
            return None;
        }
        let mut size = 0u32;
        GetTokenInformation(token, TokenUser, std::ptr::null_mut(), 0, &mut size);
        let mut buffer = vec![0u8; size as usize];
        let ok = GetTokenInformation(token, TokenUser, buffer.as_mut_ptr().cast(), size, &mut size);
        CloseHandle(token);
        if ok == 0 {
            return None;
        }
        let user = &*(buffer.as_ptr().cast::<TOKEN_USER>());
        let mut text: *mut u16 = std::ptr::null_mut();
        if ConvertSidToStringSidW(user.User.Sid, &mut text) == 0 {
            return None;
        }
        let length = (0..).take_while(|&i| *text.add(i) != 0).count();
        let sid = String::from_utf16_lossy(std::slice::from_raw_parts(text, length));
        LocalFree(text as HLOCAL);
        Some(sid)
    }
}

fn user_only() -> std::io::Result<UserOnly> {
    let sid = user_sid().ok_or_else(std::io::Error::last_os_error)?;
    // protected DACL, full access for this user alone
    let sddl: Vec<u16> = format!("D:P(A;;GA;;;{sid})").encode_utf16().chain([0]).collect();
    let mut descriptor: PSECURITY_DESCRIPTOR = std::ptr::null_mut();
    // SAFETY: a NUL-terminated string; the descriptor is freed by UserOnly
    let ok = unsafe {
        ConvertStringSecurityDescriptorToSecurityDescriptorW(
            sddl.as_ptr(),
            SDDL_REVISION_1,
            &mut descriptor,
            std::ptr::null_mut(),
        )
    };
    if ok == 0 {
        return Err(std::io::Error::last_os_error());
    }
    Ok(UserOnly(descriptor))
}

/// An instance of the pipe `name`, the first one refused when another app has the name
fn instance(name: &str, first: bool, security: &UserOnly) -> std::io::Result<NamedPipeServer> {
    let mut attributes = SECURITY_ATTRIBUTES {
        nLength: size_of::<SECURITY_ATTRIBUTES>() as u32,
        lpSecurityDescriptor: security.0,
        bInheritHandle: 0,
    };
    // SAFETY: the attributes and the descriptor they point to live through the call
    unsafe {
        ServerOptions::new()
            .first_pipe_instance(first)
            .reject_remote_clients(true)
            .create_with_security_attributes_raw(name, (&mut attributes as *mut SECURITY_ATTRIBUTES).cast::<c_void>())
    }
}

/// Listens for relays on the named pipe `name`
pub(crate) fn listen_pipe(core: Arc<Core>, name: &str) -> std::io::Result<pe_mcp::McpServer> {
    let security = user_only()?;
    let name = name.to_string();
    // the first instance is made here, so a name another app holds is refused now; its handle is made in the
    // server's runtime, as tokio wants
    let (ready, made) = std::sync::mpsc::channel();
    let server = pe_mcp::McpServer::start(move || {
        Box::pin(async move {
            let mut next = match instance(&name, true, &security) {
                Ok(server) => {
                    let _ = ready.send(Ok(()));
                    server
                }
                Err(error) => {
                    let _ = ready.send(Err(error));
                    return;
                }
            };
            loop {
                let connected = next.connect().await.is_ok();
                let current = std::mem::replace(
                    &mut next,
                    match instance(&name, false, &security) {
                        Ok(server) => server,
                        Err(_) => return,
                    },
                );
                if connected {
                    let client = client_process(&current);
                    tokio::spawn(pe_mcp::serve(core.clone(), current, client));
                }
            }
        })
    })?;
    made.recv().unwrap_or(Err(std::io::ErrorKind::Other.into()))?;
    Ok(server)
}

/// The process at the other end of a connected instance of the pipe, as the system tells it
fn client_process(pipe: &NamedPipeServer) -> Option<u32> {
    use std::os::windows::io::AsRawHandle;
    let mut pid = 0u32;
    // SAFETY: a live pipe handle the server holds
    let ok = unsafe { GetNamedPipeClientProcessId(pipe.as_raw_handle() as HANDLE, &mut pid) };
    (ok != 0 && pid != 0).then_some(pid)
}

/// Whether the server of the named pipe `pipe` (a client's handle) runs as this user: the relay's check, so an agent
/// is never handed to a pipe another user made under the app's name
pub(crate) fn pipe_server_is_mine(pipe: std::os::windows::io::RawHandle) -> bool {
    let mut pid = 0u32;
    // SAFETY: `pipe` is a live pipe handle the relay holds; the process handle is closed on every path
    unsafe {
        if GetNamedPipeServerProcessId(pipe as HANDLE, &mut pid) == 0 {
            return false;
        }
        let process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, pid);
        if process.is_null() {
            return false;
        }
        let server = process_sid(process);
        CloseHandle(process);
        server.is_some() && server == user_sid()
    }
}

/// The parent of process `pid`, from a snapshot of the processes
fn parent(pid: u32) -> Option<u32> {
    // SAFETY: the snapshot is closed on every path; the entry is sized as the call wants
    unsafe {
        let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if snapshot == INVALID_HANDLE_VALUE {
            return None;
        }
        let mut entry: PROCESSENTRY32W = std::mem::zeroed();
        entry.dwSize = size_of::<PROCESSENTRY32W>() as u32;
        let mut more = Process32FirstW(snapshot, &mut entry) != 0;
        let mut found = None;
        while more {
            if entry.th32ProcessID == pid {
                found = Some(entry.th32ParentProcessID);
                break;
            }
            more = Process32NextW(snapshot, &mut entry) != 0;
        }
        CloseHandle(snapshot);
        found
    }
}

/// The executable of process `pid` and when it started (in 100 ns since 1601)
fn image(pid: u32) -> Option<(String, u64)> {
    // SAFETY: the process handle is closed on every path; the buffer and the times are sized as the calls are told
    unsafe {
        let process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, pid);
        if process.is_null() {
            return None;
        }
        let mut buffer = [0u16; 1024];
        let mut length = buffer.len() as u32;
        let ok = QueryFullProcessImageNameW(process, PROCESS_NAME_WIN32, buffer.as_mut_ptr(), &mut length);
        let zero = FILETIME {
            dwLowDateTime: 0,
            dwHighDateTime: 0,
        };
        let (mut created, mut exited, mut kernel, mut user) = (zero, zero, zero, zero);
        let timed = GetProcessTimes(process, &mut created, &mut exited, &mut kernel, &mut user);
        CloseHandle(process);
        if ok == 0 {
            return None;
        }
        let started = if timed != 0 {
            (u64::from(created.dwHighDateTime) << 32) | u64::from(created.dwLowDateTime)
        } else {
            0
        };
        Some((String::from_utf16_lossy(&buffer[..length as usize]), started))
    }
}

/// Process `pid` as Windows tells it: pe-mcp's lookup here. The parent a snapshot names may be gone and its number
/// taken by another process; pe-mcp tells by the times they started.
pub(crate) fn process(pid: u32) -> Option<pe_mcp::Process> {
    let (path, started) = image(pid)?;
    Some(pe_mcp::Process {
        path,
        parent: parent(pid)?,
        started,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn windows_tells_this_process() {
        let own = process(std::process::id()).unwrap();
        assert!(
            own.path
                .eq_ignore_ascii_case(&std::env::current_exe().unwrap().to_string_lossy()),
            "{own:?}"
        );
        assert!(own.started > 0);
        if let Some(parent) = process(own.parent) {
            assert!(parent.started <= own.started);
        }
        assert!(process(u32::MAX - 2).is_none());
    }

    #[tokio::test]
    async fn a_pipe_tells_its_client() {
        let name = format!(r"\\.\pipe\InboxClassic-test-{}", std::process::id());
        let security = user_only().unwrap();
        let server = instance(&name, true, &security).unwrap();
        let client = tokio::net::windows::named_pipe::ClientOptions::new()
            .open(&name)
            .unwrap();
        server.connect().await.unwrap();
        assert_eq!(client_process(&server), Some(std::process::id()));
        use std::os::windows::io::AsRawHandle;
        assert!(pipe_server_is_mine(client.as_raw_handle()));
    }
}
