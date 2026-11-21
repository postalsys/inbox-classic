#!/usr/bin/env bash
# The Linux app's deep test driver as the conductor starts it (core/crates/pe-deep): the app built with the e2e
# feature, headless as scripts/linux-ui-e2e-run.sh runs the UI test, reading its requests from standard input.
#   scripts/linux-deep-driver.sh <inbox-classic built with e2e> [the conductor's options...]
set -euo pipefail
binary=$1
shift
export GSK_RENDERER=cairo
export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1
export LIBGL_ALWAYS_SOFTWARE=1
export NO_AT_BRIDGE=1
export GTK_A11Y=none
export LANG=${LANG:-C.UTF-8}
exec xvfb-run -a -s "-screen 0 1600x1100x24" dbus-run-session -- "$binary" --deep "$@"
