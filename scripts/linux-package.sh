#!/usr/bin/env bash
# Builds the .deb packages of the Linux app in the container of linux/Dockerfile, one per architecture: arm64
# natively and amd64 through Rosetta, into dist/InboxClassic-arm64.deb and dist/InboxClassic-amd64.deb. Each has the
# release build, the desktop file, the metainfo, the icon and THIRD-PARTY-NOTICES.txt (scripts/notices.mjs --linux);
# cargo-deb takes the libraries it needs from dpkg-shlibdeps. Each package is then installed into a clean
# ubuntu:26.04 container of its architecture and started with --version, the release's boot test. Give the
# architectures as arguments to build only those (scripts/linux-package.sh arm64)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
architectures=("$@")
[ ${#architectures[@]} -gt 0 ] || architectures=(arm64 amd64)
for LINUX_ARCH in "${architectures[@]}"; do
    . scripts/linux-env.sh
    echo "== $LINUX_ARCH"
    linux_run "
        cargo build --release --locked
        mkdir -p /src/build/linux-notices
        node /src/scripts/notices.mjs --linux /src/build/linux-notices
        cargo deb --no-build --locked --output /src/dist/InboxClassic-$LINUX_ARCH.deb
        dpkg-deb --info /src/dist/InboxClassic-$LINUX_ARCH.deb
        dpkg-deb --contents /src/dist/InboxClassic-$LINUX_ARCH.deb
    "
    # installed where nothing else is, and started once
    docker run --rm --platform "linux/$LINUX_ARCH" -v "$PWD/dist:/dist:ro" ubuntu:26.04 bash -euo pipefail -c "
        apt-get update -qq >/dev/null
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq /dist/InboxClassic-$LINUX_ARCH.deb >/dev/null
        inbox-classic --version
    "
done
ls -l dist/InboxClassic-*.deb
