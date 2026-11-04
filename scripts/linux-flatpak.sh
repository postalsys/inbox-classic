#!/usr/bin/env bash
# Builds the Flatpak of the Linux app (linux/flatpak/com.inboxclassic.InboxClassic.yml) in a privileged Ubuntu
# container, as flatpak-builder needs its sandbox: the crates of linux/Cargo.lock listed for an offline build
# (flatpak-cargo-generator, into linux/flatpak/cargo-sources.json, committed), the GNOME runtime from Flathub, then the
# bundle dist/InboxClassic.flatpak, which is installed in the container and started with --version.
#
#   scripts/linux-flatpak.sh [arm64|amd64]     the architecture of this Mac (arm64) by default
set -euo pipefail
cd "$(dirname "$0")/.."
ARCH=${1:-arm64}
docker run --rm --privileged --platform "linux/$ARCH" -v "$PWD:/src" -w /src ubuntu:26.04 bash -euo pipefail -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null
    apt-get install -y -qq --no-install-recommends flatpak flatpak-builder elfutils ca-certificates curl git python3 python3-aiohttp python3-tomlkit python3-yaml >/dev/null
    # the crates of the lock file, for the build without network
    curl -sSfL -o /tmp/flatpak-cargo-generator.py https://raw.githubusercontent.com/flatpak/flatpak-builder-tools/master/cargo/flatpak-cargo-generator.py
    python3 /tmp/flatpak-cargo-generator.py linux/Cargo.lock -o linux/flatpak/cargo-sources.json
    flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak-builder --user --install-deps-from=flathub --force-clean --disable-rofiles-fuse --state-dir=/tmp/state --repo=/tmp/repo /tmp/build linux/flatpak/com.inboxclassic.InboxClassic.yml
    mkdir -p dist
    flatpak build-bundle /tmp/repo dist/InboxClassic-$ARCH.flatpak com.inboxclassic.InboxClassic
    flatpak install --user -y --noninteractive dist/InboxClassic-$ARCH.flatpak >/dev/null
    flatpak run com.inboxclassic.InboxClassic --version
"
ls -l "dist/InboxClassic-$ARCH.flatpak"
