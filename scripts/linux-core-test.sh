#!/usr/bin/env bash
# Runs the core's tests (cargo test --workspace in core/) on Linux in the container of linux/Dockerfile, with
# ImapKit for the end-to-end tests and a GNOME Keyring unlocked in a D-Bus session of its own, so the Secret Service
# backend of the passwords (PE_KEYRING_TESTS) is tested too. The Cargo target is build/cargo-linux-core-<arch>.
# The argument is the architecture, arm64 (the default) or amd64; extra arguments go to cargo test
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${1:-}" = arm64 ] || [ "${1:-}" = amd64 ]; then
    LINUX_ARCH=$1
    shift
fi
. scripts/linux-env.sh
LINUX_DOCKER="-e CARGO_TARGET_DIR=/src/build/cargo-linux-core-$LINUX_ARCH -e PE_KEYRING_TESTS=1 -e PE_E2E_REQUIRED=1" linux_run "
    $LINUX_E2E_MODULES
    cd /src/core
    dbus-run-session -- bash -euo pipefail -c '
        echo -n test-password | gnome-keyring-daemon --unlock --components=secrets >/dev/null
        # the keyring answers before the tests use it
        echo -n check | secret-tool store --label=check service inbox-classic-check account check
        [ \"\$(secret-tool lookup service inbox-classic-check account check)\" = check ] && echo the keyring answers
        cargo test --workspace --locked $*
    '
"
