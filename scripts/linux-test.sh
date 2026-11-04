#!/usr/bin/env bash
# Checks the Linux app in the container of linux/Dockerfile: rustfmt, clippy with warnings as errors (with and
# without the e2e feature), and its unit tests, as CI does. The argument is the architecture, arm64 (the default) or
# amd64; extra arguments go to cargo test
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${1:-}" = arm64 ] || [ "${1:-}" = amd64 ]; then
    LINUX_ARCH=$1
    shift
fi
. scripts/linux-env.sh
linux_run "
    cargo fmt --check
    cargo clippy --locked --all-targets -- -D warnings
    cargo clippy --locked --all-targets --features e2e -- -D warnings
    cargo test --locked $*
"
