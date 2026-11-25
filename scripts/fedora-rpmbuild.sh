#!/usr/bin/env bash
# Builds the Fedora package inside a Fedora system, as root (a container): the spec's build dependencies, rpmbuild,
# and rpmlint on the spec and the package. scripts/fedora-package.sh runs it in Docker, CI's fedora job in its own
# container, as arch-makepkg.sh does for Arch.
#
#   scripts/fedora-rpmbuild.sh <folder> [--install]
#
# The folder holds linux/fedora (the spec, rpmlint.toml) and the source as the release's tarball would be (inbox-classic-<version>.tar.gz), so
# rpmbuild downloads nothing but the crates. A CARGO_HOME and CARGO_TARGET_DIR set outside are used by the build, so
# the crates and the build can be kept between runs. The package lands in <folder>/RPMS/<arch>/. --install installs it
# here and checks that it starts with --version.
set -euo pipefail
dir=$(cd "$1" && pwd)
spec=$dir/inbox-classic.spec
version=$(sed -n 's/^Version: *\([0-9.]*\).*/\1/p' "$spec")
dnf -y -q install rpm-build rpmlint 'dnf-command(builddep)' >/dev/null
dnf -y -q builddep "$spec" >/dev/null
# GNU tar fails in an x86_64 container under Rosetta (as linux/Dockerfile notes), and rpm unpacks the source with
# /usr/bin/tar itself: TAR=bsdtar puts libarchive's in its place, in the container (thrown away after)
if [ "${TAR:-}" = bsdtar ]; then
    dnf -y -q install bsdtar >/dev/null
    ln -sf /usr/bin/bsdtar /usr/bin/tar
fi
rpmbuild -bb "$spec" \
    --define "_topdir $dir" --define "_sourcedir $dir" --define "_builddir $dir/BUILD" --define "_rpmdir $dir/RPMS"
rpmlint -r "$dir/rpmlint.toml" "$spec" "$dir"/RPMS/*/inbox-classic-*.rpm
if [ "${2:-}" = "--install" ]; then
    dnf -y -q install "$dir"/RPMS/*/inbox-classic-*.rpm >/dev/null
    said=$(inbox-classic --version)
    [ "$said" = "Inbox Classic $version" ] || {
        echo "The package says '$said', not Inbox Classic $version" >&2
        exit 1
    }
    echo "$said"
fi
