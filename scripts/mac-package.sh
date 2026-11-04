#!/usr/bin/env bash
# Builds the Mac release, dist/InboxClassic.dmg, on the release Mac: the app (scripts/mac-build.sh) signed with the
# Developer ID Application certificate of Postal Systems OU and the hardened runtime, notarized and stapled, in a disk
# image with an Applications link, which is signed, notarized and stapled too. Then it checks what it made the way
# Gatekeeper does and starts the app from the image with --version.
#
#   scripts/mac-package.sh
#   UNSIGNED=yes scripts/mac-package.sh   signed ad hoc and not notarized, to look at
#
# Needs the certificate in the login keychain and the notarytool credential profile "notarytool"
# (xcrun notarytool store-credentials notarytool), as ../emailengine-api/upload.sh does.
set -euo pipefail
cd "$(dirname "$0")/.."
TEAM_ID="8JM6VJ352Q"
SIGN_ORG="Postal Systems OU"
NOTARY_PROFILE="notarytool"
# only a certificate of Apple's G2 intermediate: the first one expires 2027-02-01 (see emailengine-api/upload.sh)
SIGN_SUBCA_OU="G2"
APP="build/mac/Inbox Classic.app"
DMG="dist/InboxClassic.dmg"
VERSION=$(sed -n 's/^version = "\([0-9.]*\)"/\1/p' core/Cargo.toml | head -1)

fail() {
    echo "$*" >&2
    exit 1
}

# the SHA-1 of the Developer ID Application certificate of the G2 intermediate that expires last
signing_identity() {
    local sha pem best="" best_end=""
    while read -r sha; do
        [ -z "$sha" ] && continue
        pem=$(security find-certificate -a -p -Z 2>/dev/null | awk -v want="$sha" '
            /^SHA-1 hash: / { hit = ($3 == want); next }
            hit && /^-----BEGIN CERTIFICATE/ { printing = 1 }
            printing { print }
            printing && /^-----END CERTIFICATE/ { exit }')
        printf '%s\n' "$pem" | openssl x509 -noout -issuer 2>/dev/null | grep -q "OU=${SIGN_SUBCA_OU}," || continue
        end=$(printf '%s\n' "$pem" | openssl x509 -noout -enddate | sed 's/notAfter=//' | awk '
            BEGIN { split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", M, " "); for (i = 1; i <= 12; i++) m[M[i]] = sprintf("%02d", i) }
            { t = $3; gsub(/:/, "", t); printf "%s%s%02d%s", $4, m[$1], $2, t }')
        if [[ -z "$best_end" || "$end" > "$best_end" ]]; then
            best_end="$end"
            best="$sha"
        fi
    done < <(security find-identity -v -p codesigning | sed -n "s/^ *[0-9]*) *\([0-9A-F]*\) *\"Developer ID Application: ${SIGN_ORG} (${TEAM_ID})\"\$/\1/p")
    printf '%s' "$best"
}

if [ "${UNSIGNED:-}" = yes ]; then
    IDENTITY="-"
else
    IDENTITY=$(signing_identity)
    [ -n "$IDENTITY" ] || fail "No Developer ID Application certificate of ${SIGN_ORG} from the ${SIGN_SUBCA_OU} intermediate in the keychain"
    xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 || fail "No notarytool credential profile '${NOTARY_PROFILE}'"
fi

scripts/mac-build.sh
node scripts/notices.mjs --mac "$APP/Contents/Resources"

# inside out: Sparkle's helpers, its framework, the app's executable, the bundle
sign() {
    if [ "$IDENTITY" = "-" ]; then
        # ad hoc: no hardened runtime, whose library validation wants every part signed by one team
        codesign --force --sign - "$@"
    else
        codesign --force --timestamp --options runtime --sign "$IDENTITY" "$@"
    fi
}
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
for helper in "$SPARKLE"/Versions/B/XPCServices/*.xpc "$SPARKLE/Versions/B/Autoupdate" "$SPARKLE/Versions/B/Updater.app"; do
    [ -e "$helper" ] && sign "$helper"
done
sign "$SPARKLE"
sign --entitlements mac/Resources/InboxClassic.entitlements "$APP/Contents/MacOS/Inbox Classic"
sign --entitlements mac/Resources/InboxClassic.entitlements "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

notarize() {
    [ "$IDENTITY" = "-" ] && return
    local result id
    result=$(xcrun notarytool submit --keychain-profile "$NOTARY_PROFILE" --team-id "$TEAM_ID" --wait --output-format json "$1")
    id=$(printf '%s' "$result" | sed -n 's/.*"id" *: *"\([^"]*\)".*/\1/p')
    if ! printf '%s' "$result" | grep -q '"status" *: *"Accepted"'; then
        xcrun notarytool log --keychain-profile "$NOTARY_PROFILE" "$id" >&2 || true
        fail "Notarization of $1 was not accepted: $result"
    fi
}

# the app notarized and stapled first, so it opens without asking the network even out of the image
mkdir -p dist
ditto -c -k --keepParent "$APP" "dist/InboxClassic-app.zip"
notarize dist/InboxClassic-app.zip
rm -f dist/InboxClassic-app.zip
[ "$IDENTITY" = "-" ] || xcrun stapler staple "$APP"

# the image: the app and a link to Applications to drag it onto
staging=$(mktemp -d)
ditto "$APP" "$staging/Inbox Classic.app"
ln -s /Applications "$staging/Applications"
rm -f "$DMG"
hdiutil create -volname "Inbox Classic ${VERSION}" -srcfolder "$staging" -fs HFS+ -format UDZO -imagekey zlib-level=9 -quiet "$DMG"
rm -rf "$staging"
if [ "$IDENTITY" != "-" ]; then
    codesign --force --timestamp --sign "$IDENTITY" "$DMG"
    notarize "$DMG"
    xcrun stapler staple "$DMG"
    # as Gatekeeper sees it on a user's Mac
    spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"
    xcrun stapler validate "$DMG"
fi

# the boot test: the app as it is in the image
mount=$(mktemp -d)
hdiutil attach -nobrowse -readonly -mountpoint "$mount" -quiet "$DMG"
said=$("$mount/Inbox Classic.app/Contents/MacOS/Inbox Classic" --version)
[ "$IDENTITY" = "-" ] || spctl --assess --type execute --verbose=2 "$mount/Inbox Classic.app"
hdiutil detach -quiet "$mount"
[ "$said" = "Inbox Classic ${VERSION}" ] || fail "The app in the image says '${said}', not Inbox Classic ${VERSION}"
echo "Built ${DMG}: ${said}"
