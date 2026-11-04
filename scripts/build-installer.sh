#!/usr/bin/env bash
# Builds the signed installer dist/InboxClassic-Setup.exe, from the Mac:
#
#   1. builds the app and stages it (exe and notices) on the Windows build machine
#   2. copies the staging folder here
#   3. signs InboxClassic.exe, then makensis builds the installer and signs the uninstaller and the installer
#
# Signing uses scripts/sign-win.sh, it needs SIGN_WIN_ACCOUNT and SIGN_WIN_PROFILE (unset: an unsigned build).
# Sign-in through the browser: the Google and Microsoft clients are built in (pe-oauth); PE_GOOGLE_CLIENT_ID,
# PE_GOOGLE_CLIENT_SECRET and PE_MICROSOFT_CLIENT_ID in the environment of the Windows build replace them. Needs makensis 3.08 or newer (brew install makensis)
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/win-env.sh

VERSION=$(sed -n 's/^version = "\([0-9.]*\)"/\1/p' core/Cargo.toml | head -1)
echo "Building Inbox Classic ${VERSION} on ${WIN_HOST}"
win_sync
ssh "$WIN_HOST" "$WIN_DIR\\scripts\\win-package.cmd"

# only what this builds: the Mac and Linux packages of the same release may be in dist/ already
rm -rf dist/InboxClassic dist/InboxClassic-Setup.exe
mkdir -p dist
ssh "$WIN_HOST" "tar -czf - -C $WIN_DIR_FWD/dist InboxClassic" | tar -xzf - -C dist

./scripts/sign-win.sh dist/InboxClassic/InboxClassic.exe

SIGN_FLAG=()
if [ -n "${SIGN_WIN_ACCOUNT:-}" ] && [ -n "${SIGN_WIN_PROFILE:-}" ]; then
    SIGN_FLAG=(-DSIGN)
fi
# no version in the name, so releases/latest/download/InboxClassic-Setup.exe always gets the latest release
OUTFILE="dist/InboxClassic-Setup.exe"
makensis -V2 -NOCD -DVERSION="$VERSION" -DSTAGING=dist/InboxClassic -DOUTFILE="$OUTFILE" "${SIGN_FLAG[@]}" installer/inbox-classic.nsi

shasum -a 256 "$OUTFILE"
