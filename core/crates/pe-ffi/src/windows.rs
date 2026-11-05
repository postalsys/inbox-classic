//! What agents need of Windows itself: the named pipe the app listens on, which only the user running it can open,
//! and the program that started the relay, up the line of parent processes.

use std::ffi::c_void;
use std::sync::Arc;

use pe_core::Core;
use tokio::net::windows::named_pipe::{NamedPipeServer, ServerOptions};
use windows_sys::Win32::Foundation::{CloseHandle, HANDLE, HLOCAL, INVALID_HANDLE_VALUE, LocalFree};
use windows_sys::Win32::Security::Authorization::{
    ConvertSidToStringSidW, ConvertStringSecurityDescriptorToSecurityDescriptorW, SDDL_REVISION_1,
};
use windows_sys::Win32::Security::{
    GetTokenInformation, PSECURITY_DESCRIPTOR, SECURITY_ATTRIBUTES, TOKEN_QUERY, TOKEN_USER, TokenUser,
};
use windows_sys::Win32::System::Diagnostics::ToolHelp::{
    CreateToolhelp32Snapshot, PROCESSENTRY32W, Process32FirstW, Process32NextW, TH32CS_SNAPPROCESS,
};
use windows_sys::Win32::System::Pipes::GetNamedPipeServerProcessId;
use windows_sys::Win32::System::Threading::{
    GetCurrentProcess, GetCurrentProcessId, OpenProcess, OpenProcessToken, PROCESS_NAME_WIN32,
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
                    tokio::spawn(pe_mcp::serve(core.clone(), current));
                }
            }
        })
    })?;
    made.recv().unwrap_or(Err(std::io::ErrorKind::Other.into()))?;
    Ok(server)
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

/// Each process's parent, from a snapshot
fn processes() -> std::collections::HashMap<u32, u32> {
    let mut parents = std::collections::HashMap::new();
    // SAFETY: the snapshot is closed on every path; the entry is sized as the call wants
    unsafe {
        let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if snapshot == INVALID_HANDLE_VALUE {
            return parents;
        }
        let mut entry: PROCESSENTRY32W = std::mem::zeroed();
        entry.dwSize = size_of::<PROCESSENTRY32W>() as u32;
        let mut more = Process32FirstW(snapshot, &mut entry) != 0;
        while more {
            parents.insert(entry.th32ProcessID, entry.th32ParentProcessID);
            more = Process32NextW(snapshot, &mut entry) != 0;
        }
        CloseHandle(snapshot);
    }
    parents
}

/// The executable of process `pid`
fn image(pid: u32) -> Option<String> {
    // SAFETY: the process handle is closed on every path; the buffer is sized as the call is told
    unsafe {
        let process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, pid);
        if process.is_null() {
            return None;
        }
        let mut buffer = [0u16; 1024];
        let mut length = buffer.len() as u32;
        let ok = QueryFullProcessImageNameW(process, PROCESS_NAME_WIN32, buffer.as_mut_ptr(), &mut length);
        CloseHandle(process);
        (ok != 0).then(|| String::from_utf16_lossy(&buffer[..length as usize]))
    }
}

/// The program that started this relay, past the shells and runtimes agents start their servers through
pub(crate) fn launching_program() -> pe_core::agents::HostInfo {
    let parents = processes();
    // SAFETY: no arguments
    let mut pid = unsafe { GetCurrentProcessId() };
    let mut line = Vec::new();
    for _ in 0..6 {
        let Some(&parent) = parents.get(&pid) else { break };
        if parent == 0 || parent == pid {
            break;
        }
        let Some(path) = image(parent) else { break };
        line.push(path);
        pid = parent;
    }
    // the first that is not a launcher
    pe_mcp::host_of(&line)
}
