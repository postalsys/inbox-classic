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
status=0
xvfb-run -a -s "-screen 0 1600x1100x24" dbus-run-session -- "$binary" --e2e "$out" || status=$?
cat "$out/result.txt" 2>/dev/null || echo "no result"
echo
exit $status
