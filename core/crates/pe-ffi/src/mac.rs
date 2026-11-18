//! What agents need of the Mac itself: a process's executable and parent as the kernel tells them (proc_pidpath and
//! proc_pidinfo), so the app finds the program at the other end of an agent's connection by what it is, not by what
//! it calls itself (`ps` gives the name a process gives itself).

use std::ffi::{c_int, c_void};

/// The process `pid`: its executable, its parent and when it started, in microseconds
pub(crate) fn process(pid: u32) -> Option<pe_mcp::Process> {
    let pid = c_int::try_from(pid).ok()?;
    let mut buffer = vec![0u8; libc::PROC_PIDPATHINFO_MAXSIZE as usize];
    // SAFETY: the buffer is as long as the call is told
    let length = unsafe { libc::proc_pidpath(pid, buffer.as_mut_ptr().cast::<c_void>(), buffer.len() as u32) };
    let length = usize::try_from(length).ok().filter(|n| *n > 0)?;
    // SAFETY: plain data that the call fills, sized as the call is told
    let mut info: libc::proc_bsdinfo = unsafe { std::mem::zeroed() };
    let size = size_of::<libc::proc_bsdinfo>() as c_int;
    // SAFETY: as above
    let filled = unsafe {
        libc::proc_pidinfo(
            pid,
            libc::PROC_PIDTBSDINFO,
            0,
            (&mut info as *mut libc::proc_bsdinfo).cast::<c_void>(),
            size,
        )
    };
    if filled != size {
        return None;
    }
    Some(pe_mcp::Process {
        path: String::from_utf8_lossy(&buffer[..length]).into_owned(),
        parent: info.pbi_ppid,
        started: info
            .pbi_start_tvsec
            .saturating_mul(1_000_000)
            .saturating_add(info.pbi_start_tvusec),
    })
}

#[cfg(test)]
mod tests {
    #[test]
    fn the_kernel_tells_this_process() {
        let own = super::process(std::process::id()).unwrap();
        assert_eq!(
            std::path::Path::new(&own.path).canonicalize().unwrap(),
            std::env::current_exe().unwrap().canonicalize().unwrap()
        );
        assert_eq!(own.parent, std::os::unix::process::parent_id());
        let parent = super::process(own.parent).unwrap();
        assert!(parent.started <= own.started && own.started > 0);
        assert!(super::process(u32::MAX).is_none());
    }
}
