#!/usr/bin/env bash
# Builds the Arch Linux packages of linux/arch/PKGBUILD with scripts/arch-makepkg.sh (which CI's arch job runs too),
# x86_64 and aarch64, each in a container of its architecture, then installs each into a clean container and starts
# it with --version:
#
#   scripts/arch-package.sh [x86_64|aarch64 ...]             from the working tree: a tarball of it stands in for
#                                                            the release's
#   scripts/arch-package.sh --release [x86_64|aarch64 ...]   from the release's own tarball on GitHub (the tag of
#                                                            pkgver), as Omarchy builds it; also writes the PKGBUILD
#                                                            with its checksum and .SRCINFO to dist/arch/inbox-classic/,
#                                                            the recipe for omacom-io/omarchy-pkgs and the AUR
#
# The packages land in dist/InboxClassic-<arch>.pkg.tar.zst, the release assets (no version in the name, so
# releases/latest/download/ always has the latest; downloaded, `sudo pacman -U <file>` installs one). x86_64 builds on the official
# archlinux image (through Rosetta on the Mac); aarch64 natively on Omarchy's published package builder, an Arch Linux
# ARM system bootstrapped from its keyring, pinned by digest. Downloaded packages, crates and builds are kept in Docker
# volumes of each architecture.
set -euo pipefail
cd "$(dirname "$0")/.."
fail() {
    echo "$*" >&2
    exit 1
}
RELEASE=no
if [ "${1:-}" = "--release" ]; then
    RELEASE=yes
    shift
fi
architectures=("$@")
[ ${#architectures[@]} -gt 0 ] || architectures=(x86_64 aarch64)
VERSION=$(sed -n 's/^pkgver=\([0-9.]*\).*/\1/p' linux/arch/PKGBUILD)
[ -n "$VERSION" ] || fail "No pkgver in linux/arch/PKGBUILD"
docker info >/dev/null 2>&1 || fail "Docker is not running"
AARCH64_IMAGE="ghcr.io/omacom/omarchy-pkg-builder@sha256:2a76572b18eeecdc7df221cbd6335fcd8433fea6f3e3e103389ac160f5ef0f80"
# pacman's download sandbox (seccomp, Landlock, the alpm user) does not work in these containers, thrown away after
NOSANDBOX="sed -i '/^\\[options\\]/a DisableSandbox' /etc/pacman.conf"

# a root shell in a container of the architecture, its pacman packages kept between runs
arch_run() {
    local arch=$1
    shift
    local platform=linux/amd64 image=archlinux:latest
    if [ "$arch" = aarch64 ]; then
        platform=linux/arm64
        image=$AARCH64_IMAGE
    fi
    docker run --rm --platform "$platform" --user root --entrypoint bash \
        -v "inbox-classic-arch-pacman-$arch:/var/cache/pacman/pkg" "${@:1:$#-1}" "$image" -euo pipefail -c "$NOSANDBOX
        ${*: -1}"
}

# the source and the recipe, the same for every architecture
work=build/arch
rm -rf "$work" dist/arch
mkdir -p "$work/src"
if [ "$RELEASE" = "yes" ]; then
    curl -sSfL -o "$work/src/inbox-classic-$VERSION.tar.gz" \
        "https://github.com/postalsys/inbox-classic/archive/refs/tags/v$VERSION.tar.gz"
    sum=$(shasum -a 256 "$work/src/inbox-classic-$VERSION.tar.gz" | cut -d' ' -f1)
    sed -e "s/^pkgver=.*/pkgver=$VERSION/" -e "s/^sha256sums=.*/sha256sums=('$sum')/" linux/arch/PKGBUILD >"$work/src/PKGBUILD"
else
    cp linux/arch/PKGBUILD "$work/src/"
    # the working tree as the release's tarball would have it, so makepkg finds the source and downloads nothing
    git ls-files -z --cached --others --exclude-standard |
        COPYFILE_DISABLE=1 tar --null -T - -czf "$work/src/inbox-classic-$VERSION.tar.gz" -s "|^|inbox-classic-$VERSION/|"
fi

for arch in "${architectures[@]}"; do
    [ "$arch" = x86_64 ] || [ "$arch" = aarch64 ] || fail "The architecture is x86_64 or aarch64, not $arch"
    echo "== $arch"
    rm -rf "${work:?}/$arch"
    cp -R "$work/src" "$work/$arch"
    arch_run "$arch" -v "$PWD/$work/$arch:/build" -v "$PWD/scripts/arch-makepkg.sh:/arch-makepkg.sh:ro" \
        -v "inbox-classic-arch-cargo-$arch:/cargo" -v "inbox-classic-arch-target-$arch:/target" \
        -e CARGO_HOME=/cargo -e CARGO_TARGET_DIR=/target "
        pacman -Syu --noconfirm >/dev/null
        /arch-makepkg.sh /build"
    cp "$work/$arch/inbox-classic-$VERSION-"*"-$arch.pkg.tar.zst" "dist/InboxClassic-$arch.pkg.tar.zst"
    # installed where nothing else is, and started once
    said=$(arch_run "$arch" -v "$PWD/dist:/dist:ro" "
        pacman -Syu --noconfirm >/dev/null
        pacman -U --noconfirm /dist/InboxClassic-$arch.pkg.tar.zst >/dev/null
        inbox-classic --version")
    [ "$said" = "Inbox Classic $VERSION" ] || fail "The $arch package says '$said', not Inbox Classic $VERSION"
    echo "dist/InboxClassic-$arch.pkg.tar.zst: $said"
done

if [ "$RELEASE" = "yes" ]; then
    mkdir -p dist/arch/inbox-classic
    cp "$work/${architectures[0]}/PKGBUILD" "$work/${architectures[0]}/.SRCINFO" dist/arch/inbox-classic/
    echo "The recipe of $VERSION for omarchy-pkgs and the AUR is in dist/arch/inbox-classic"
fi
