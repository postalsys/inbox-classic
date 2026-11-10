#!/usr/bin/env bash
# Publishes the Linux packages in dist/ to the apt repository https://apt.inboxclassic.com, so that Linux users who
# added it get each release with their system updates (the homepage tells how to add it):
#
#   scripts/apt-repo.sh      after scripts/linux-package.sh, or with the release's .debs downloaded into dist/
#
# The repository is plain static files ("stable main", amd64 and arm64): the indexes are made by apt-ftparchive in
# an ubuntu:26.04 container, Release is signed here with the release GPG key (InRelease and Release.gpg), and the
# files go by rsync to the Caddy vhost apt.inboxclassic.com on srv-04 (/var/www/apt.inboxclassic.com). The pool
# keeps every version uploaded; the indexes list only this one. Last, a clean ubuntu:26.04 container of each
# architecture adds the repository the way the homepage says and installs the app from it.
set -euo pipefail
cd "$(dirname "$0")/.."
# "Postalsys Releases <releases@postalsys.com>", the key hashes.txt is signed with
GPG_KEY="B6F07B59064F9CCA"
HOST="andris@srv-04.emailengine.dev"
DIR="/var/www/apt.inboxclassic.com"
URL="https://apt.inboxclassic.com"
ARCHES=(amd64 arm64)

fail() {
    echo "$*" >&2
    exit 1
}

for arch in "${ARCHES[@]}"; do
    [ -f "dist/InboxClassic-${arch}.deb" ] || fail "dist/InboxClassic-${arch}.deb is missing"
done
docker info >/dev/null 2>&1 || fail "Docker is not running"

repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT

# the pool and the indexes, made where the Debian tools are
docker run --rm -v "$PWD/dist:/dist:ro" -v "$repo:/repo" ubuntu:26.04 bash -euo pipefail -c '
    apt-get update -qq >/dev/null
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apt-utils >/dev/null
    cd /repo
    mkdir -p pool/main/i/inbox-classic
    for arch in '"${ARCHES[*]}"'; do
        deb=/dist/InboxClassic-$arch.deb
        [ "$(dpkg-deb -f "$deb" Architecture)" = "$arch" ] || { echo "$deb is not $arch" >&2; exit 1; }
        cp "$deb" "pool/main/i/inbox-classic/inbox-classic_$(dpkg-deb -f "$deb" Version)_$arch.deb"
    done
    for arch in '"${ARCHES[*]}"'; do
        mkdir -p dists/stable/main/binary-$arch
        apt-ftparchive --arch "$arch" packages pool >dists/stable/main/binary-$arch/Packages
        gzip -9nk dists/stable/main/binary-$arch/Packages
    done
    apt-ftparchive \
        -o APT::FTPArchive::Release::Origin="Inbox Classic" \
        -o APT::FTPArchive::Release::Label="Inbox Classic" \
        -o APT::FTPArchive::Release::Suite=stable \
        -o APT::FTPArchive::Release::Codename=stable \
        -o APT::FTPArchive::Release::Architectures="'"${ARCHES[*]}"'" \
        -o APT::FTPArchive::Release::Components=main \
        -o APT::FTPArchive::Release::Description="Inbox Classic, https://inboxclassic.com" \
        release dists/stable >/tmp/Release
    mv /tmp/Release dists/stable/Release
'
version=$(sed -n 's/^Version: //p' "$repo/dists/stable/main/binary-amd64/Packages" | head -1)
[ -n "$version" ] || fail "No package in the index"

gpg --default-key "$GPG_KEY" --digest-algo SHA512 --clearsign --output "$repo/dists/stable/InRelease" "$repo/dists/stable/Release"
gpg --default-key "$GPG_KEY" --digest-algo SHA512 --armor --detach-sign --output "$repo/dists/stable/Release.gpg" "$repo/dists/stable/Release"
gpg --verify --status-fd 1 "$repo/dists/stable/InRelease" 2>/dev/null | grep -q "^\[GNUPG:\] VALIDSIG [0-9A-F]*${GPG_KEY} " ||
    fail "InRelease is not signed with ${GPG_KEY}"
# the key users add (signed-by), binary as apt wants it
gpg --export "$GPG_KEY" >"$repo/inboxclassic.gpg"
chmod -R u=rwX,go=rX "$repo"

# the packages first, so no index ever names a file that is not there yet, then the indexes in one swap
rsync -rt "$repo/pool/" "$repo/inboxclassic.gpg" "$HOST:$DIR/staging-pool/"
rsync -rt "$repo/dists/" "$HOST:$DIR/dists.new/"
ssh "$HOST" "set -e; cd $DIR; mkdir -p pool; cp -a staging-pool/main pool/; mv staging-pool/inboxclassic.gpg .; rm -rf staging-pool
    rm -rf dists.old; [ ! -d dists ] || mv dists dists.old; mv dists.new dists; rm -rf dists.old"
echo "Published inbox-classic ${version} to ${URL}"

# installed from the repository as a user would, on each architecture
for arch in "${ARCHES[@]}"; do
    said=$(docker run --rm --platform "linux/$arch" ubuntu:26.04 bash -euo pipefail -c "
        apt-get update -qq >/dev/null
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wget ca-certificates >/dev/null
        wget -qO- ${URL}/inboxclassic.gpg >/usr/share/keyrings/inboxclassic.gpg
        echo 'deb [signed-by=/usr/share/keyrings/inboxclassic.gpg] ${URL} stable main' >/etc/apt/sources.list.d/inboxclassic.list
        apt-get update -qq >/dev/null
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq inbox-classic >/dev/null
        inbox-classic --version
    ")
    [ "$said" = "Inbox Classic ${version%%-*}" ] || fail "The ${arch} app from ${URL} says '${said}', not Inbox Classic ${version}"
    echo "${arch}: ${said} from ${URL}"
done
