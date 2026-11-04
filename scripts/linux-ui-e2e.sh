#!/usr/bin/env bash
# Runs the UI end-to-end test of the Linux app in the container of linux/Dockerfile: ImapKit from core/e2e, the app
# built with the e2e feature (its driver is in linux/src/e2e.rs: it drives the real widgets in-process and takes the
# screenshots), under Xvfb with a D-Bus session and GTK's cairo renderer, so no GPU or desktop is needed. The log and
# the screenshots land in build/ui-e2e-linux (`node scripts/feature-map.mjs build/ui-e2e-linux` makes the page of
# them). The argument is the architecture, arm64 (the default) or amd64. The same commands run in CI.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${1:-}" = arm64 ] || [ "${1:-}" = amd64 ]; then
    LINUX_ARCH=$1
    shift
fi
. scripts/linux-env.sh
mkdir -p build/ui-e2e-linux
linux_run "
    $LINUX_E2E_MODULES
    cargo build --locked --features e2e
    /src/scripts/linux-ui-e2e-run.sh \$CARGO_TARGET_DIR/debug/inbox-classic /src/build/ui-e2e-linux
"
