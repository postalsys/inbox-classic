#!/usr/bin/env bash
# Builds the Linux app (linux/, GTK 4 and libadwaita) in the Ubuntu 26.04 container of linux/Dockerfile, gives
# build/cargo-linux-<arch>/release/inbox-classic. The argument is the architecture, arm64 (the default, native here)
# or amd64 (through Rosetta). Extra arguments go to cargo build
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${1:-}" = arm64 ] || [ "${1:-}" = amd64 ]; then
    LINUX_ARCH=$1
    shift
fi
. scripts/linux-env.sh
linux_run "cargo build --release --locked $*"
echo "build/cargo-linux-$LINUX_ARCH/release/inbox-classic"
