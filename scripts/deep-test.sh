#!/usr/bin/env bash
# The deep test (docs/deep-test-plan.md): the conductor (core/crates/pe-deep) drives a target through the journeys
# of scripts/ui-e2e/DEEP.md and the walk on mailboxes the size people have, with the checks after every step. It is
# run on demand and before a release, never on a pull request.
#   scripts/deep-test.sh core|linux|mac [--profile small|standard|overnight] [--seed N] [--steps N] [--until N]
#                                       [--journeys D2,D4|all|none] [--no-walk] [--shrink]
#                                       [--corpus DIR]
# The report is build/deep/<target>/report.html, the outcome build/deep/<target>/result.json. --corpus fills the
# world with real messages from a folder of .eml files: on this computer only (the world stays under build/, which is
# never committed; CI never names a corpus). Windows runs in CI
# (.github/workflows/deep.yml): its driver is scripts/deep-driver.ps1 on a desktop.
set -euo pipefail
cd "$(dirname "$0")/.."
target=${1:-}
shift || true
case "$target" in
    core)
        (cd core/e2e && [ -d node_modules ] || npm ci --no-audit --no-fund --silent)
        cargo build --release --locked --manifest-path core/Cargo.toml -p pe-deep
        exec core/target/release/pe-deep run --target core --out build/deep/core --worlds build/deep "$@"
        ;;
    linux)
        if [ "${1:-}" = arm64 ] || [ "${1:-}" = amd64 ]; then
            LINUX_ARCH=$1
            shift
        fi
        . scripts/linux-env.sh
        # a corpus is mounted read-only into the container under /corpus
        rest=()
        while [ $# -gt 0 ]; do
            if [ "$1" = --corpus ] && [ $# -gt 1 ]; then
                LINUX_DOCKER="${LINUX_DOCKER:-} -v $(cd "$2" && pwd):/corpus:ro"
                rest+=(--corpus /corpus)
                shift 2
            else
                rest+=("$1")
                shift
            fi
        done
        set -- ${rest[@]+"${rest[@]}"}
        args=$(printf ' %q' "$@")
        linux_run "
            $LINUX_E2E_MODULES
            # optimized: the core's syncs at every step's barrier take seconds unoptimized
            cargo build --release --locked --features e2e
            (cd /src/core && cargo build --release --locked -p pe-deep)
            cd /src
            \$CARGO_TARGET_DIR/release/pe-deep run --target linux --out build/deep/linux --worlds build/deep $args \
                --driver /src/scripts/linux-deep-driver.sh \$CARGO_TARGET_DIR/release/inbox-classic
        "
        ;;
    mac)
        (cd core/e2e && [ -d node_modules ] || npm ci --no-audit --no-fund --silent)
        TEST=1 scripts/mac-build.sh
        cargo build --release --locked --manifest-path core/Cargo.toml -p pe-deep
        exec core/target/release/pe-deep run --target mac --out build/deep/mac --worlds build/deep "$@" \
            --driver "build/mac/Inbox Classic.app/Contents/MacOS/InboxClassicUITest" --deep
        ;;
    *)
        echo "usage: scripts/deep-test.sh core|linux|mac [options]" >&2
        exit 2
        ;;
esac
