#!/usr/bin/env bash
# Runs a built UI test binary of the Linux app (`cargo build --features e2e`) headless: Xvfb, a D-Bus session of its
# own, GTK's cairo renderer. Used by scripts/linux-ui-e2e.sh in the container and by CI.
#   scripts/linux-ui-e2e-run.sh <inbox-classic built with e2e> <output folder>
# WebKit's web process sandbox (bubblewrap) needs user namespaces, which a container does not give: it is turned off
# here, for the test only.
set -euo pipefail
binary=$1
out=$2
mkdir -p "$out"
export GSK_RENDERER=cairo
export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1
export LIBGL_ALWAYS_SOFTWARE=1
export NO_AT_BRIDGE=1
export GTK_A11Y=none
export LANG=${LANG:-C.UTF-8}
# a GLib, GTK or WebKit critical ends the test where it happens, its stack printed (linux/src/e2e.rs
# trace_criticals), rather than a crash some steps later or a pass that hides it
export G_DEBUG=${G_DEBUG:-fatal-criticals}
# dates in a regional format other than the C locale's US one, so the test sees them follow LC_TIME (linux/Dockerfile
# and CI generate en_GB.UTF-8; without it the dates stay in the C locale's format)
if [ -z "${LC_TIME:-}" ] && locale -a 2>/dev/null | grep -qix 'en_GB\.utf-\?8'; then
    export LC_TIME=en_GB.UTF-8
fi
# a crash leaves a core dump, read by gdb once the app has ended (the run is not slowed by a debugger), so the log
# shows where it crashed. The kernel's core_pattern says where cores go: a file name (relative: the app's working
# directory, this one) lands here; a pipe (|...) hands it to the host's crash handler, outside a container
ulimit -c unlimited 2>/dev/null || true
started=$(mktemp)
status=0
xvfb-run -a -s "-screen 0 1600x1100x24" dbus-run-session -- "$binary" --e2e "$out" || status=$?
cat "$out/result.txt" 2>/dev/null || echo "no result"
echo
if [ "$status" -gt 128 ]; then
    echo "the app ended with signal $((status - 128))"
    pattern=$(cat /proc/sys/kernel/core_pattern 2>/dev/null || true)
    core=$(find "$PWD" "$out" -maxdepth 1 -type f -name 'core*' -newer "$started" 2>/dev/null | head -n 1)
    if [ -z "$core" ]; then
        echo "no core dump here (the kernel's core_pattern is: $pattern)"
    elif ! command -v gdb >/dev/null; then
        echo "a core dump is in $core, but gdb is not installed to read it"
    else
        echo "the stacks of the app's threads when it ended, from $core:"
        gdb -batch -nx -q -ex "set pagination off" -ex "thread apply all bt" "$binary" "$core" 2>&1 || true
        rm -f "$core"
    fi
fi
rm -f "$started"
exit $status
