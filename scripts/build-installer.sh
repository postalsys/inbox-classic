#!/usr/bin/env bash
# Builds the signed installer dist/PostalExpress-Setup.exe, from the Mac:
#
#   1. builds the app and stages it (exe and notices) on the Windows build machine
#   2. copies the staging folder here
#   3. signs PostalExpress.exe, then makensis builds the installer and signs the uninstaller and the installer
#
# Signing uses scripts/sign-win.sh, it needs SIGN_WIN_ACCOUNT and SIGN_WIN_PROFILE (unset: an unsigned build).
# Sign-in through the browser needs the OAuth client IDs at build time: PE_GOOGLE_CLIENT_ID (and
# PE_GOOGLE_CLIENT_SECRET) and PE_MICROSOFT_CLIENT_ID in the environment of the Windows build; without them the app
# offers passwords only. Needs makensis 3.08 or newer (brew install makensis)
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/win-env.sh

VERSION=$(sed -n 's/^version = "\([0-9.]*\)"/\1/p' core/Cargo.toml | head -1)
echo "Building PostalExpress ${VERSION} on ${WIN_HOST}"
win_sync
ssh "$WIN_HOST" "$WIN_DIR\\scripts\\win-package.cmd"

rm -rf dist
mkdir -p dist
ssh "$WIN_HOST" "tar -czf - -C $WIN_DIR_FWD/dist PostalExpress" | tar -xzf - -C dist

./scripts/sign-win.sh dist/PostalExpress/PostalExpress.exe

SIGN_FLAG=()
if [ -n "${SIGN_WIN_ACCOUNT:-}" ] && [ -n "${SIGN_WIN_PROFILE:-}" ]; then
    SIGN_FLAG=(-DSIGN)
fi
# no version in the name, so releases/latest/download/PostalExpress-Setup.exe always gets the latest release
OUTFILE="dist/PostalExpress-Setup.exe"
makensis -V2 -NOCD -DVERSION="$VERSION" -DSTAGING=dist/PostalExpress -DOUTFILE="$OUTFILE" "${SIGN_FLAG[@]}" installer/postal-express.nsi

shasum -a 256 "$OUTFILE"
