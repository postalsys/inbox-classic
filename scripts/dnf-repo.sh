#!/usr/bin/env bash
# Publishes the Fedora packages in dist/ to the dnf repository https://rpm.inboxclassic.com, so that Fedora users who
# installed a package from the homepage (which adds the repository and its key) get each release with their system
# updates:
#
#   scripts/dnf-repo.sh      after scripts/fedora-package.sh and scripts/rpm-sign.sh, or with the release's signed
#                            .rpm files downloaded into dist/
#
# The repository is plain static files (x86_64 and aarch64 together): the metadata is made by createrepo_c in a
# fedora:44 container, repomd.xml is signed here with the release GPG key (repomd.xml.asc, for repo_gpgcheck), and the
# files go by rsync to the Caddy vhost rpm.inboxclassic.com on srv-04 (/var/www/rpm.inboxclassic.com). packages/
# keeps every version uploaded; the metadata lists only this one. The key is not published there: the package brings
# it, so whoever could write to the host could not swap it. Last, clean Fedora 44 and 45 containers of each
# architecture install the package as the homepage says (#linux-fedora), then install it again from the repository.
set -euo pipefail
cd "$(dirname "$0")/.."
# "Postalsys Releases <releases@postalsys.com>", the key hashes.txt and the packages are signed with
GPG_KEY="B6F07B59064F9CCA"
HOST="andris@srv-04.emailengine.dev"
# STAGING=<name> publishes under /<name>/ of the host instead, to try the whole path without touching the repository
DIR="/var/www/rpm.inboxclassic.com${STAGING:+/$STAGING}"
URL="https://rpm.inboxclassic.com${STAGING:+/$STAGING}"
ARCHES=(x86_64 aarch64)
FEDORAS=(44 45)

fail() {
    echo "$*" >&2
    exit 1
}

for arch in "${ARCHES[@]}"; do
    [ -f "dist/InboxClassic-${arch}.rpm" ] || fail "dist/InboxClassic-${arch}.rpm is missing"
done
docker info >/dev/null 2>&1 || fail "Docker is not running"

repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT
# the key to check the packages with here, never published by the repository (the package brings it)
gpg --export --armor "$GPG_KEY" >"$repo/key.asc"

# the packages under their own names, checked to be signed with the key, and the metadata, made where the tools are
docker run --rm -v "$PWD/dist:/dist:ro" -v "$repo:/repo" fedora:44 bash -euo pipefail -c '
    dnf -y -q install createrepo_c >/dev/null
    rpm --import /repo/key.asc
    rm /repo/key.asc
    mkdir -p /repo/packages
    for arch in '"${ARCHES[*]}"'; do
        rpm=/dist/InboxClassic-$arch.rpm
        [ "$(rpm -qp --qf "%{ARCH}" "$rpm")" = "$arch" ] || { echo "$rpm is not $arch" >&2; exit 1; }
        rpm -K "$rpm" | grep -q "signatures OK" || { echo "$rpm is not signed with the release key" >&2; exit 1; }
        cp "$rpm" "/repo/packages/$(rpm -qp --qf "%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}" "$rpm").rpm"
    done
    createrepo_c -q --general-compress-type=zstd /repo
'
version=$(cd "$repo/packages" && ls | sed -n 's/^inbox-classic-\([0-9.]*\)-.*/\1/p' | head -1)
[ -n "$version" ] || fail "No package in the repository"

gpg --default-key "$GPG_KEY" --digest-algo SHA512 --armor --detach-sign --output "$repo/repodata/repomd.xml.asc" "$repo/repodata/repomd.xml"
gpg --verify --status-fd 1 "$repo/repodata/repomd.xml.asc" "$repo/repodata/repomd.xml" 2>/dev/null |
    grep -q "^\[GNUPG:\] VALIDSIG [0-9A-F]*${GPG_KEY} " || fail "repomd.xml is not signed with ${GPG_KEY}"
chmod -R u=rwX,go=rX "$repo"

# the packages first, so the metadata never names a file that is not there yet, then the metadata in one swap
ssh "$HOST" "mkdir -p $DIR"
rsync -rt "$repo/packages/" "$HOST:$DIR/packages/"
rsync -rt "$repo/repodata/" "$HOST:$DIR/repodata.new/"
ssh "$HOST" "set -e; cd $DIR; rm -rf repodata.old; [ ! -d repodata ] || mv repodata repodata.old; mv repodata.new repodata; rm -rf repodata.old"
echo "Published inbox-classic ${version} to ${URL}"

# installed as the homepage says (the package, which adds the repository and its key), then installed again from the
# repository alone, on each Fedora and architecture
for arch in "${ARCHES[@]}"; do
    platform=linux/amd64
    [ "$arch" = aarch64 ] && platform=linux/arm64
    for fedora in "${FEDORAS[@]}"; do
        said=$(docker run --rm --platform "$platform" -v "$PWD/dist:/dist:ro" "fedora:$fedora" bash -euo pipefail -c "
            dnf -y -q install /dist/InboxClassic-$arch.rpm >/dev/null
            sed -i 's|^baseurl=.*|baseurl=${URL}/|' /etc/yum.repos.d/inboxclassic.repo
            dnf -y -q --disablerepo='*' --enablerepo=inboxclassic reinstall inbox-classic >/dev/null
            dnf -q repoquery --installed --qf '%{from_repo}' inbox-classic | grep -qx inboxclassic
            inbox-classic --version
        ")
        [ "$said" = "Inbox Classic ${version}" ] || fail "The ${arch} app on Fedora ${fedora} from ${URL} says '${said}', not Inbox Classic ${version}"
        echo "${arch} on Fedora ${fedora}: ${said} from ${URL}"
    done
done
