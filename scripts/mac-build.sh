#!/usr/bin/env bash
# Builds the Mac app, build/mac/Inbox Classic.app, on this Mac: the Rust core as a static library (cargo, in core/ so
# it reads core/.cargo/config.toml), the Swift package in mac/ against it, then the bundle with its icons (the Fluent
# SVGs of app/res/icons as PDFs, the app icon from app/res/app-icon.svg), the sign-in buttons and Info.plist.
#
#   scripts/mac-build.sh            a release build, signed ad hoc to run here
#   CONFIG=debug scripts/mac-build.sh
#   TEST=1 scripts/mac-build.sh     also the UI end-to-end test, put in the bundle beside the app (scripts/mac-ui-e2e.sh)
#
# Signing for others to run is scripts/mac-package.sh. Needs Xcode's command line tools, rustup and librsvg
# (brew install librsvg).
set -euo pipefail
cd "$(dirname "$0")/.."
CONFIG=${CONFIG:-release}
VERSION=$(sed -n 's/^version = "\([0-9.]*\)"/\1/p' core/Cargo.toml | head -1)
APP="build/mac/Inbox Classic.app"
# the oldest macOS the app runs on, for Rust as for Swift (mac/Package.swift)
export MACOSX_DEPLOYMENT_TARGET=26.0
# Sparkle, the updater, as its release ships it (the version is the one scripts/release.sh makes the appcast with)
SPARKLE_VERSION="2.10.0"
if [ ! -d build/sparkle/Sparkle.framework ] || ! grep -q ">${SPARKLE_VERSION}<" build/sparkle/Sparkle.framework/Resources/Info.plist; then
    rm -rf build/sparkle
    mkdir -p build/sparkle
    curl -sSfL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" | tar -xJ -C build/sparkle
fi

echo "Building Inbox Classic ${VERSION} for the Mac"
(cd core && CARGO_TARGET_DIR=../build/cargo cargo build --release --locked -p pe-ffi --target aarch64-apple-darwin)
# the Swift package links build/cargo/release/libpe_ffi.a
mkdir -p build/cargo/release
cp build/cargo/aarch64-apple-darwin/release/libpe_ffi.a build/cargo/release/libpe_ffi.a
for product in InboxClassic ${TEST:+InboxClassicUITest}; do
    swift build --package-path mac -c "$CONFIG" --product "$product" --scratch-path build/swift
done
BIN=$(swift build --package-path mac -c "$CONFIG" --scratch-path build/swift --show-bin-path)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/icons" "$APP/Contents/Resources/brands" "$APP/Contents/Frameworks"
# Sparkle, for updates (mac/Package.swift)
ditto build/sparkle/Sparkle.framework "$APP/Contents/Frameworks/Sparkle.framework"
cp "$BIN/InboxClassic" "$APP/Contents/MacOS/Inbox Classic"
if [ -n "${TEST:-}" ]; then
    cp "$BIN/InboxClassicUITest" "$APP/Contents/MacOS/InboxClassicUITest"
fi
sed "s/VERSION/${VERSION}/g" mac/Resources/Info.plist > "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
# the languages there are catalogs of (core/locales), so the system offers them for the app (System Settings >
# General > Language & Region > Applications) and AppKit's own words (Services, Enter Full Screen) follow the app's
/usr/libexec/PlistBuddy -c "Add :CFBundleLocalizations array" "$APP/Contents/Info.plist"
for dir in core/locales/*/; do
    code=$(basename "$dir")
    /usr/libexec/PlistBuddy -c "Add :CFBundleLocalizations: string $code" "$APP/Contents/Info.plist"
    mkdir -p "$APP/Contents/Resources/$code.lproj"
done

# the icons, as PDFs drawn as template images (Icons.swift), in the color the system gives them
for svg in app/res/icons/*.svg; do
    name=$(basename "$svg" .svg)
    rsvg-convert -f pdf "$svg" -o "$APP/Contents/Resources/icons/$name.pdf"
done
cp app/res/brands/google-sign-in.png app/res/brands/microsoft-sign-in.png "$APP/Contents/Resources/brands/"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
if [ -f dist/mac/THIRD-PARTY-NOTICES.txt ]; then
    cp dist/mac/THIRD-PARTY-NOTICES.txt "$APP/Contents/Resources/"
fi

# the app icon: the sizes of an .icns, drawn from the SVG
iconset=$(mktemp -d)/AppIcon.iconset
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    rsvg-convert -w "$size" -h "$size" app/res/app-icon.svg -o "$iconset/icon_${size}x${size}.png"
    rsvg-convert -w $((size * 2)) -h $((size * 2)) app/res/app-icon.svg -o "$iconset/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$iconset" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$iconset")"

# signed ad hoc, so it runs here; mac-package.sh signs it with the Developer ID and the hardened runtime (which an ad
# hoc signature can not have here: its library validation wants Sparkle signed by the same team as the app)
codesign --force --deep --sign - "$APP/Contents/Frameworks/Sparkle.framework"
codesign --force --sign - --entitlements mac/Resources/InboxClassic.entitlements "$APP/Contents/MacOS/Inbox Classic"
if [ -n "${TEST:-}" ]; then
    codesign --force --sign - "$APP/Contents/MacOS/InboxClassicUITest"
fi
codesign --force --sign - --entitlements mac/Resources/InboxClassic.entitlements "$APP"
echo "Built $APP"
