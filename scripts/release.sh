#!/usr/bin/env bash
# Builds, signs and publishes a release of Inbox Classic for every platform from the release Mac, like
# emailengine-api/upload.sh:
#
#   scripts/release.sh                       the release of the version in core/Cargo.toml, all platforms
#   BUILD_ONLY=yes scripts/release.sh        builds, signs and checks, uploads nothing
#   PLATFORMS=mac scripts/release.sh         builds only these (windows, mac, linux, comma separated) and uploads
#                                            what is in dist/, to finish a release one of whose builds failed
#
# release-please drafts the release and pushes the tag when its release PR is merged (.github/workflows/release.yaml).
# This builds from that tag:
#   Windows  dist/InboxClassic-Setup.exe on the Windows build machine (scripts/build-installer.sh), the exe, the
#            uninstaller and the installer signed with Azure Artifact Signing, the exe started with --version there
#   Mac      dist/InboxClassic.dmg here (scripts/mac-package.sh): Developer ID, notarized and stapled, the app in the
#            image started with --version
#   Linux    dist/InboxClassic-amd64.deb and dist/InboxClassic-arm64.deb in Docker here (scripts/linux-package.sh),
#            each installed into a clean Ubuntu container and started with --version
# then writes hashes.txt signed with the release GPG key, uploads all of it to the draft release and publishes it,
# and puts the Mac update (Sparkle's appcast.xml, signed with the update key in this Mac's keychain) on the homepage.
#
# Needs: SIGN_WIN_ACCOUNT and SIGN_WIN_PROFILE (and the keychain item of scripts/sign-win.sh), the Developer ID
# certificate and the notarytool profile (scripts/mac-package.sh), Docker, gpg with the release key, gh, makensis,
# jsign, the Windows build machine of scripts/win-env.sh, and the homepage checkout ../inboxclassic.com
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="postalsys/inbox-classic"
# "Postalsys Releases <releases@postalsys.com>", the key EmailEngine releases are signed with
GPG_KEY="B6F07B59064F9CCA"
BUILD_ONLY="${BUILD_ONLY:-no}"
PLATFORMS="${PLATFORMS:-windows,mac,linux}"
VERSION=$(sed -n 's/^version = "\([0-9.]*\)"/\1/p' core/Cargo.toml | head -1)
TAG="v${VERSION}"
HOMEPAGE="../inboxclassic.com"
SPARKLE="build/sparkle"
SPARKLE_VERSION="2.10.0"
# no version in the names, so https://github.com/<repo>/releases/latest/download/<name> always gets the latest
# release (the download links of inboxclassic.com)
FILES=(InboxClassic-Setup.exe InboxClassic.dmg InboxClassic-amd64.deb InboxClassic-arm64.deb)

fail() {
    echo "$*" >&2
    exit 1
}
building() {
    [[ ",${PLATFORMS}," == *",$1,"* ]]
}

# everything that can stop the release is checked before the builds, which take a while
if [ -n "$(git status --porcelain)" ]; then
    fail "The working tree has changes, the release is built from the files on disk and must match the tag"
fi
if building windows; then
    [ -n "${SIGN_WIN_ACCOUNT:-}" ] && [ -n "${SIGN_WIN_PROFILE:-}" ] || fail "SIGN_WIN_ACCOUNT and SIGN_WIN_PROFILE are not set, a release is always signed"
    . scripts/win-env.sh
    ssh -o ConnectTimeout=10 "$WIN_HOST" "ver" >/dev/null || fail "The Windows build machine ${WIN_HOST} does not answer"
fi
if building mac; then
    xcrun notarytool history --keychain-profile notarytool >/dev/null 2>&1 || fail "No notarytool credential profile 'notarytool'"
fi
if building linux; then
    docker info >/dev/null 2>&1 || fail "Docker is not running"
fi
if [ "$BUILD_ONLY" != "yes" ]; then
    gh release view "$TAG" --repo "$REPO" --json isDraft >/dev/null 2>&1 || fail "No release ${TAG}, merge the release PR of release-please first"
    git fetch --quiet --tags origin
    git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null || fail "No tag ${TAG}"
    [ "$(git rev-parse HEAD)" = "$(git rev-parse "${TAG}^{commit}")" ] || fail "HEAD is not ${TAG}, check out the tag (git checkout ${TAG}) and run again"
    CI=$(gh run list --repo "$REPO" --workflow CI --commit "$(git rev-parse HEAD)" --json conclusion --jq '.[0].conclusion')
    [ "$CI" = "success" ] || fail "CI of ${TAG} is '${CI:-not run}', not success"
    [ -d "$HOMEPAGE/.git" ] || fail "No homepage checkout at ${HOMEPAGE}"
    [ -z "$(git -C "$HOMEPAGE" status --porcelain)" ] || fail "The homepage checkout has changes"
fi
if building mac; then
    # Sparkle's tools, for the appcast; the key is the one in this Mac's keychain (generate_keys --account inbox-classic)
    if [ ! -x "$SPARKLE/bin/generate_appcast" ]; then
        mkdir -p "$SPARKLE"
        curl -sSfL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" | tar -xJ -C "$SPARKLE"
    fi
    "$SPARKLE/bin/generate_keys" --account inbox-classic -p >/dev/null || fail "No Sparkle update key in the keychain"
fi
# the GPG passphrase is asked now, not after the builds
gpg --clearsign --default-key "$GPG_KEY" --output /dev/null core/Cargo.toml
mkdir -p dist

# Windows first: it takes longest, on another machine
if building windows; then
    ./scripts/build-installer.sh
    said=$(ssh "$WIN_HOST" "$WIN_DIR\\dist\\InboxClassic\\InboxClassic.exe --version" | tr -d '\r')
    [ "$said" = "Inbox Classic ${VERSION}" ] || fail "The Windows app says '${said}', not Inbox Classic ${VERSION}"
fi
if building mac; then
    ./scripts/mac-package.sh
fi
if building linux; then
    ./scripts/linux-package.sh
fi

cd dist
for file in "${FILES[@]}"; do
    [ -f "$file" ] || fail "dist/${file} is missing: build its platform (PLATFORMS=...) first"
done
{
    echo "Inbox Classic ${VERSION} (https://github.com/${REPO})"
    echo ""
    echo "Signed with ${GPG_KEY}"
    echo "https://api.github.com/users/andris9/gpg_keys"
    echo ""
    echo "Built from $(git rev-parse --short HEAD)"
    echo ""
    for file in "${FILES[@]}"; do
        openssl sha256 "$file"
    done
} >hashes.txt
gpg --clearsign --default-key "$GPG_KEY" hashes.txt
mv hashes.txt.asc hashes.txt
# hashes.txt is what users verify, check that it carries a good signature of the release key in particular
gpg --verify --status-fd 1 hashes.txt 2>/dev/null | grep -q "^\[GNUPG:\] VALIDSIG [0-9A-F]*${GPG_KEY} " || fail "hashes.txt is not signed with ${GPG_KEY}"
cd ..

if [ "$BUILD_ONLY" = "yes" ]; then
    echo "Built $(printf 'dist/%s ' "${FILES[@]}")and dist/hashes.txt, nothing uploaded"
    exit 0
fi
(cd dist && gh release upload "$TAG" "${FILES[@]}" hashes.txt --repo "$REPO" --clobber)
# the draft becomes the latest release now that every platform's package is there
gh release edit "$TAG" --repo "$REPO" --draft=false --latest
echo "Published ${TAG}: https://github.com/${REPO}/releases/tag/${TAG}"

# the Mac update: the appcast lists the DMG of the release, signed with the update key, with the release notes
appcast=$(mktemp -d)
cp dist/InboxClassic.dmg "$appcast/InboxClassic-${VERSION}.dmg"
gh release view "$TAG" --repo "$REPO" --json body --jq .body >"$appcast/InboxClassic-${VERSION}.md"
cp "$HOMEPAGE/appcast.xml" "$appcast/" 2>/dev/null || true
"$SPARKLE/bin/generate_appcast" --account inbox-classic --embed-release-notes \
    --download-url-prefix "https://github.com/${REPO}/releases/download/${TAG}/" -o "$appcast/appcast.xml" "$appcast"
# the download as GitHub names it: the DMG of the release
sed -i '' "s|releases/download/${TAG}/InboxClassic-${VERSION}.dmg|releases/download/${TAG}/InboxClassic.dmg|" "$appcast/appcast.xml"
cp "$appcast/appcast.xml" "$HOMEPAGE/appcast.xml"
rm -rf "$appcast"
git -C "$HOMEPAGE" add appcast.xml
git -C "$HOMEPAGE" commit -q -m "Inbox Classic ${VERSION} for the Mac updater"
git -C "$HOMEPAGE" push -q
echo "The appcast of ${VERSION} is on the homepage"
