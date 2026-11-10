#!/usr/bin/env bash
# Builds the Arch Linux package inside an Arch Linux system, as root (a container): the PKGBUILD's dependencies,
# makepkg as an unprivileged user, .SRCINFO, and namcap on the recipe and the package. scripts/arch-package.sh runs it
# in Docker, CI's arch job in its own container, as linux-ui-e2e.sh and CI share linux-ui-e2e-run.sh.
#
#   scripts/arch-makepkg.sh <folder> [--install]
#
# The folder holds the PKGBUILD and the source as the release's tarball would be (inbox-classic-<pkgver>.tar.gz), so
# makepkg downloads nothing; its checksum is skipped, as the tarball is the working tree, not the release's. A
# CARGO_HOME and CARGO_TARGET_DIR set outside are given to the build, so the crates and the build can be kept between
# runs. --install installs the package here and checks that it starts with --version.
set -euo pipefail
dir=$1
cd "$dir"
version=$(sed -n 's/^pkgver=\([0-9.]*\).*/\1/p' PKGBUILD)
pacman -S --noconfirm --needed base-devel namcap >/dev/null
id builder >/dev/null 2>&1 || useradd -m builder
env=()
for name in CARGO_HOME CARGO_TARGET_DIR; do
    if [ -n "${!name:-}" ]; then
        mkdir -p "${!name}"
        chown -R builder "${!name}"
        env+=("$name=${!name}")
    fi
done
chown -R builder .
# shellcheck disable=SC2046 # the package names, one word each
pacman -S --noconfirm --needed $(su builder -c 'source PKGBUILD; echo "${depends[@]}" "${makedepends[@]}"') >/dev/null
su builder -c "env ${env[*]} makepkg -f --noconfirm --skipchecksums"
su builder -c "makepkg --printsrcinfo" >.SRCINFO
namcap PKGBUILD
namcap inbox-classic-*.pkg.tar.zst
if [ "${2:-}" = "--install" ]; then
    pacman -U --noconfirm inbox-classic-*.pkg.tar.zst >/dev/null
    said=$(inbox-classic --version)
    [ "$said" = "Inbox Classic $version" ] || {
        echo "The package says '$said', not Inbox Classic $version" >&2
        exit 1
    }
    echo "$said"
fi
