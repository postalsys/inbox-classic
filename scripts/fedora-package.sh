#!/usr/bin/env bash
# Builds the Fedora packages of linux/fedora/inbox-classic.spec with scripts/fedora-rpmbuild.sh (which CI's fedora job
# runs too), x86_64 and aarch64, each in a Fedora 44 container of its architecture, then installs each into clean
# Fedora 44 and 45 containers and starts it with --version:
#
#   scripts/fedora-package.sh [x86_64|aarch64 ...]             from the working tree: a tarball of it stands in for
#                                                              the release's
#   scripts/fedora-package.sh --release [x86_64|aarch64 ...]   from the release's own tarball on GitHub (the tag of
#                                                              the spec's Version)
#
# Fedora 44 is the oldest Fedora with the GTK (4.20) and libadwaita (1.8) the window needs, so a package built there
# installs on it and on every newer one. The packages land in dist/InboxClassic-<arch>.rpm, the release assets (no
# version in the name, so releases/latest/download/ always has the latest; `sudo dnf install ./<file>` installs one).
# x86_64 builds through Rosetta on the Mac, aarch64 natively. Downloaded packages, crates and builds are kept in Docker
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
VERSION=$(sed -n 's/^Version: *\([0-9.]*\).*/\1/p' linux/fedora/inbox-classic.spec)
[ -n "$VERSION" ] || fail "No Version in linux/fedora/inbox-classic.spec"
docker info >/dev/null 2>&1 || fail "Docker is not running"
BUILD_ON=44
INSTALL_ON=(44 45)

# a root shell in a Fedora container of the architecture, its downloaded packages kept between runs
fedora_run() {
    local arch=$1 release=$2
    shift 2
    local platform=linux/amd64
    [ "$arch" = aarch64 ] && platform=linux/arm64
    docker run --rm --platform "$platform" -v "inbox-classic-fedora-dnf-$release-$arch:/var/cache/libdnf5" \
        "${@:1:$#-1}" "fedora:$release" bash -euo pipefail -c "echo keepcache=True >>/etc/dnf/dnf.conf
        ${*: -1}"
}

# the source and the recipe, the same for every architecture
work=build/fedora
rm -rf "$work"
mkdir -p "$work/src" dist
cp linux/fedora/* "$work/src/"
if [ "$RELEASE" = "yes" ]; then
    curl -sSfL -o "$work/src/inbox-classic-$VERSION.tar.gz" \
        "https://github.com/postalsys/inbox-classic/archive/refs/tags/v$VERSION.tar.gz"
else
    # the working tree as the release's tarball would have it, so rpmbuild finds the source and downloads nothing
    . scripts/tree-tarball.sh
    tree_tarball "$work/src/inbox-classic-$VERSION.tar.gz" "inbox-classic-$VERSION"
fi

for arch in "${architectures[@]}"; do
    [ "$arch" = x86_64 ] || [ "$arch" = aarch64 ] || fail "The architecture is x86_64 or aarch64, not $arch"
    echo "== $arch"
    rm -rf "${work:?}/$arch"
    cp -R "$work/src" "$work/$arch"
    fedora_run "$arch" "$BUILD_ON" -v "$PWD/$work/$arch:/build" -v "$PWD/scripts/fedora-rpmbuild.sh:/fedora-rpmbuild.sh:ro" \
        -v "inbox-classic-fedora-cargo-$arch:/cargo" -v "inbox-classic-fedora-target-$arch:/target" \
        -e CARGO_HOME=/cargo -e CARGO_TARGET_DIR=/target -e TAR="$([ "$arch" = x86_64 ] && echo bsdtar)" \
        "/fedora-rpmbuild.sh /build"
    cp "$work/$arch/RPMS/$arch/inbox-classic-$VERSION-"*".$arch.rpm" "dist/InboxClassic-$arch.rpm"
    # installed where nothing else is, on each Fedora it is for, and started once
    for release in "${INSTALL_ON[@]}"; do
        said=$(fedora_run "$arch" "$release" -v "$PWD/dist:/dist:ro" "
            dnf -y -q install /dist/InboxClassic-$arch.rpm >/dev/null
            test -f /usr/share/help/C/inbox-classic/index.html
            grep -q rpm.inboxclassic.com /etc/yum.repos.d/inboxclassic.repo
            test -f /usr/share/inbox-classic/RPM-GPG-KEY-inboxclassic
            inbox-classic --version")
        [ "$said" = "Inbox Classic $VERSION" ] || fail "The $arch package on Fedora $release says '$said', not Inbox Classic $VERSION"
        echo "dist/InboxClassic-$arch.rpm on Fedora $release: $said"
    done
done
