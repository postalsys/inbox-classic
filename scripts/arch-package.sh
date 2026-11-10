#!/usr/bin/env bash
# Builds the Arch Linux package of linux/arch/PKGBUILD in an archlinux container (x86_64; through Rosetta on the
# Mac) with scripts/arch-makepkg.sh, which CI's arch job runs too, then installs it into a clean archlinux container
# and starts it with --version:
#
#   scripts/arch-package.sh              from the working tree: a tarball of it stands in for the release's
#   scripts/arch-package.sh --release    the PKGBUILD with the checksum of the release's tarball on GitHub, and its
#                                        .SRCINFO, in dist/arch/inbox-classic/: the recipe for omacom-io/omarchy-pkgs
#                                        (pkgbuilds/inbox-classic) and for the AUR
#
# The package lands in dist/arch/. The downloaded packages, the crates and the build are kept in Docker volumes.
# Omarchy's package repository builds the same PKGBUILD from each release by itself (an upstream watch on our GitHub
# Releases).
set -euo pipefail
cd "$(dirname "$0")/.."
fail() {
    echo "$*" >&2
    exit 1
}
VERSION=$(sed -n 's/^pkgver=\([0-9.]*\).*/\1/p' linux/arch/PKGBUILD)
[ -n "$VERSION" ] || fail "No pkgver in linux/arch/PKGBUILD"
docker info >/dev/null 2>&1 || fail "Docker is not running"
# an archlinux container with pacman's packages kept between runs; its download sandbox (seccomp, the alpm user)
# does not work under Rosetta, and the container is thrown away
arch() {
    docker run --rm --platform linux/amd64 -v inbox-classic-arch-pacman:/var/cache/pacman/pkg "$@"
}
NOSANDBOX="sed -i '/^\\[options\\]/a DisableSandbox' /etc/pacman.conf"

work=build/arch
rm -rf "$work" dist/arch
mkdir -p "$work" dist/arch
if [ "${1:-}" = "--release" ]; then
    sum=$(curl -sSfL "https://github.com/postalsys/inbox-classic/archive/refs/tags/v$VERSION.tar.gz" | shasum -a 256 | cut -d' ' -f1)
    sed -e "s/^pkgver=.*/pkgver=$VERSION/" -e "s/^sha256sums=.*/sha256sums=('$sum')/" linux/arch/PKGBUILD >"$work/PKGBUILD"
else
    cp linux/arch/PKGBUILD "$work/"
fi
# the working tree as the release's tarball would have it, so makepkg finds the source and downloads nothing
git ls-files -z --cached --others --exclude-standard |
    COPYFILE_DISABLE=1 tar --null -T - -czf "$work/inbox-classic-$VERSION.tar.gz" -s "|^|inbox-classic-$VERSION/|"

arch -v "$PWD/$work:/build" -v "$PWD/scripts/arch-makepkg.sh:/arch-makepkg.sh:ro" \
    -v inbox-classic-arch-cargo:/cargo -v inbox-classic-arch-target:/target -e CARGO_HOME=/cargo -e CARGO_TARGET_DIR=/target \
    archlinux:latest bash -euo pipefail -c "$NOSANDBOX
        pacman -Syu --noconfirm >/dev/null
        /arch-makepkg.sh /build"
cp "$work"/inbox-classic-*.pkg.tar.zst dist/arch/
pkg=$(basename "$(ls dist/arch/inbox-classic-*.pkg.tar.zst)")

# installed where nothing else is, and started once
said=$(arch -v "$PWD/dist/arch:/dist:ro" archlinux:latest bash -euo pipefail -c "$NOSANDBOX
    pacman -Syu --noconfirm >/dev/null
    pacman -U --noconfirm /dist/$pkg >/dev/null
    inbox-classic --version")
[ "$said" = "Inbox Classic $VERSION" ] || fail "The package says '$said', not Inbox Classic $VERSION"
echo "dist/arch/$pkg: $said"

if [ "${1:-}" = "--release" ]; then
    mkdir -p dist/arch/inbox-classic
    cp "$work/PKGBUILD" "$work/.SRCINFO" dist/arch/inbox-classic/
    echo "The recipe of $VERSION for omarchy-pkgs and the AUR is in dist/arch/inbox-classic"
fi
