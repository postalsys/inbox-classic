#!/usr/bin/env bash
# Builds, signs and publishes a release of Inbox Classic for every platform from the release Mac, like
# emailengine-api/upload.sh:
#
#   scripts/release.sh                       the release of the version in core/Cargo.toml, all platforms
#   BUILD_ONLY=yes scripts/release.sh        builds, signs and checks, uploads nothing
#   PLATFORMS=mac scripts/release.sh         builds only these (windows, mac, linux, comma separated) and uploads
#                                            what is in dist/, to finish a release one of whose builds failed
#   ALLOW_UNREVIEWED=1 scripts/release.sh    releases although translations wait for a review (it refuses otherwise)
#   ALLOW_NO_DEEP=1 scripts/release.sh       releases without a passing deep test of the commit (it refuses otherwise)
#
# release-please drafts the release and pushes the tag when its release PR is merged (.github/workflows/release.yaml).
# This builds from that tag:
#   Windows  dist/InboxClassic-Setup.exe on the Windows build machine (scripts/build-installer.sh), the exe, the
#            uninstaller and the installer signed with Azure Artifact Signing, the exe started with --version there
#   Mac      dist/InboxClassic.dmg here (scripts/mac-package.sh): Developer ID, notarized and stapled, the app in the
#            image started with --version
#   Linux    the x86_64 packages on the Windows build machine, in Docker in its WSL (scripts/build-machine.sh), while
#            the rest builds; the arm64 ones in Docker here, natively (on the build machine they would be emulated):
#            dist/InboxClassic-amd64.deb and dist/InboxClassic-arm64.deb (scripts/linux-package.sh),
#            each installed into a clean Ubuntu container and started with --version, and after the release
#            published to the apt repository https://apt.inboxclassic.com (scripts/apt-repo.sh), and
#            dist/InboxClassic-x86_64.pkg.tar.zst and -aarch64 for Arch Linux and Omarchy (scripts/arch-package.sh),
#            each installed into a clean Arch container and started; Omarchy's package repository also builds
#            linux/arch/PKGBUILD from the tag by itself, and dist/InboxClassic-x86_64.rpm and -aarch64.rpm for
#            Fedora 44 and newer (scripts/fedora-package.sh, signed by scripts/rpm-sign.sh), each installed into
#            clean Fedora 44 and 45 containers and started, and after the release published to the dnf repository
#            https://rpm.inboxclassic.com (scripts/dnf-repo.sh)
# then writes hashes.txt signed with the release GPG key, uploads all of it to the draft release and publishes it,
# and puts the Mac update (Sparkle's appcast.xml, signed with the update key in this Mac's keychain) on the homepage.
#
# Needs: SIGN_WIN_ACCOUNT and SIGN_WIN_PROFILE (and the keychain item of scripts/sign-win.sh), the Developer ID
# certificate and the notarytool profile (scripts/mac-package.sh), Docker, gpg with the release key, rpmsign
# (brew install rpm), gh, makensis,
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
FILES=(InboxClassic-Setup.exe InboxClassic.dmg InboxClassic-amd64.deb InboxClassic-arm64.deb
    InboxClassic-x86_64.pkg.tar.zst InboxClassic-aarch64.pkg.tar.zst InboxClassic-x86_64.rpm InboxClassic-aarch64.rpm)

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
# translations never block a pull request, a release they do: every one reviewed (no marks left), every new or changed
# one marked, every language with every message and help topic. ALLOW_UNREVIEWED=1 releases anyway.
translations_ok=yes
if ! waiting=$(node scripts/i18n-review.mjs --summary); then
    translations_ok=no
    echo "Translations wait for a native review (node scripts/i18n-review.mjs [--language <code>] [--html out.html] lists them):" >&2
    echo "$waiting" | sed 's/^/  /' >&2
fi
if ! unmarked=$(node scripts/i18n-review.mjs --check 2>&1); then
    translations_ok=no
    echo "New or changed translations without a review mark (node scripts/i18n-review.mjs --check):" >&2
    echo "$unmarked" | sed 's/^/  /' >&2
fi
if ! complete=$(cd core && cargo test -q --locked -p pe-i18n -p pe-html -- --ignored 2>&1); then
    translations_ok=no
    echo "A language lacks messages or help topics (cd core && cargo test -p pe-i18n -p pe-html -- --ignored):" >&2
    echo "$complete" | grep -E "panicked|lacks|missing" | sed 's/^/  /' >&2 || true
fi
if [ "$translations_ok" = "no" ]; then
    if [ "${ALLOW_UNREVIEWED:-}" = "1" ]; then
        echo "" >&2
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
        echo "!!  ALLOW_UNREVIEWED=1: releasing with the translations above NOT reviewed     !!" >&2
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
        echo "" >&2
        sleep 5
    else
        fail "No release while translations wait: review them on master first, or ALLOW_UNREVIEWED=1 to release anyway"
    fi
fi
# the deep test (docs/deep-test-plan.md): a passing run of the deep workflow on this commit for every platform that has
# a driver, started by hand (gh workflow run deep.yml --ref <tag>) while CI runs. ALLOW_NO_DEEP=1 releases anyway.
DEEP_PLATFORMS="linux mac windows"
deep_job() {
    case "$1" in
        linux) echo "The Linux app" ;;
        mac) echo "The Mac app" ;;
        windows) echo "The Windows app" ;;
    esac
}
deep_passed=$(gh run list --repo "$REPO" --workflow deep.yml --commit "$(git rev-parse HEAD)" --event workflow_dispatch \
    --json databaseId --jq '.[].databaseId' 2>/dev/null | while read -r run; do
    gh run view "$run" --repo "$REPO" --json jobs --jq '.jobs[] | select(.conclusion == "success") | .name'
done || true)
deep_missing=""
for platform in $DEEP_PLATFORMS; do
    grep -qxF "$(deep_job "$platform")" <<<"$deep_passed" || deep_missing="$deep_missing $platform"
done
if [ -n "$deep_missing" ]; then
    if [ "${ALLOW_NO_DEEP:-}" = "1" ]; then
        echo "!!  ALLOW_NO_DEEP=1: releasing without a passing deep test of:${deep_missing}" >&2
        sleep 5
    else
        fail "No passing deep test of this commit for:${deep_missing} (gh workflow run deep.yml --ref ${TAG}), or ALLOW_NO_DEEP=1 to release anyway"
    fi
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
    . scripts/win-env.sh
    ssh -o ConnectTimeout=10 "$WIN_HOST" "wsl -d Ubuntu-24.04 -u root -e docker info" >/dev/null 2>&1 ||
        fail "Docker in the build machine's WSL (${WIN_HOST}) does not answer, for the x86_64 Linux packages"
    command -v rpmsign >/dev/null || fail "rpmsign is missing, for the Fedora packages: brew install rpm"
    [ "$BUILD_ONLY" = "yes" ] || ssh -o ConnectTimeout=10 andris@srv-04.emailengine.dev true || fail "srv-04, the apt and dnf repositories' server, does not answer"
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

# the x86_64 Linux packages on the build machine meanwhile, from the release's tarball as Omarchy and Fedora build
# them; their log in dist/linux-x86_64.log
linux_x86=""
if building linux; then
    (
        set -e
        ./scripts/build-machine.sh --fetch dist/InboxClassic-amd64.deb scripts/linux-package.sh amd64
        ./scripts/build-machine.sh --fetch dist/InboxClassic-x86_64.pkg.tar.zst --fetch dist/arch \
            scripts/arch-package.sh --release x86_64
        ./scripts/build-machine.sh --fetch dist/InboxClassic-x86_64.rpm scripts/fedora-package.sh --release x86_64
    ) >dist/linux-x86_64.log 2>&1 &
    linux_x86=$!
    echo "Building the x86_64 Linux packages on ${WIN_HOST}, log in dist/linux-x86_64.log"
fi

# Windows first: it takes longest, on another machine
if building windows; then
    ./scripts/build-installer.sh
    said=$(ssh -n "$WIN_HOST" "$WIN_DIR\\dist\\InboxClassic\\InboxClassic.exe --version" | tr -d '\r')
    [ "$said" = "Inbox Classic ${VERSION}" ] || fail "The Windows app says '${said}', not Inbox Classic ${VERSION}"
fi
if building mac; then
    ./scripts/mac-package.sh
fi
if building linux; then
    ./scripts/linux-package.sh arm64
    # the Arch packages, from the release's tarball as Omarchy builds it; `curl -LO` then `sudo pacman -U` installs them
    ./scripts/arch-package.sh --release aarch64
    # the Fedora packages, from the release's tarball, signed before hashes.txt so GitHub and the repository have the
    # same files; `sudo dnf install ./<file>` installs one and adds the repository
    ./scripts/fedora-package.sh --release aarch64
    wait "$linux_x86" || {
        tail -30 dist/linux-x86_64.log >&2
        fail "The x86_64 Linux packages failed on ${WIN_HOST}, the whole log in dist/linux-x86_64.log"
    }
    ./scripts/rpm-sign.sh
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

# the Linux packages to the apt repository, where Linux users get their updates
if building linux; then
    ./scripts/apt-repo.sh
    ./scripts/dnf-repo.sh
    # Omarchy's package repository builds the release from its source on its own (an upstream watch on our GitHub
    # Releases, omacom-io/omarchy-pkgs pkgbuilds/inbox-classic); its bot's pull request is where to follow it
    echo "Omarchy picks up ${TAG} at https://github.com/omacom-io/omarchy-pkgs/pulls?q=inbox-classic"
fi

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
# the help of the release on the website
scripts/homepage-help.sh
git -C "$HOMEPAGE" add appcast.xml help
git -C "$HOMEPAGE" commit -q -m "Inbox Classic ${VERSION} for the Mac updater, and its help"
git -C "$HOMEPAGE" push -q
echo "The appcast of ${VERSION} is on the homepage"
