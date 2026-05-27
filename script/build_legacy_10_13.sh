#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="SlackerBuddyLegacy"
BUILD_PRODUCT="SlackerBuddyLegacy"
BUNDLE_ID="com.xyue.SlackerBuddyLegacy"
MIN_SYSTEM_VERSION="10.13.1"
TARGET_TRIPLE="x86_64-apple-macosx10.13"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEGACY_DIR="$ROOT_DIR/Legacy"
DIST_DIR="$ROOT_DIR/dist/legacy"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

if [[ -z "${DEVELOPER_DIR:-}" && -d /Library/Developer/CommandLineTools ]]; then
  export DEVELOPER_DIR=/Library/Developer/CommandLineTools
fi

export MACOSX_DEPLOYMENT_TARGET="$MIN_SYSTEM_VERSION"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --package-path "$LEGACY_DIR" --configuration release --product "$BUILD_PRODUCT" --triple "$TARGET_TRIPLE"
BUILD_DIR="$(swift build --package-path "$LEGACY_DIR" --configuration release --triple "$TARGET_TRIPLE" --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$BUILD_PRODUCT"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$APP_FRAMEWORKS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BINARY" 2>/dev/null || true

xcrun swift-stdlib-tool \
  --copy \
  --platform macosx \
  --scan-executable "$APP_BINARY" \
  --destination "$APP_FRAMEWORKS" \
  --sign - >/dev/null
find "$APP_FRAMEWORKS" -name "*.original" -delete

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>SlackerBuddy</string>
  <key>CFBundleDisplayName</key>
  <string>SlackerBuddy Legacy</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --build-only|build-only)
    ;;
  *)
    echo "usage: $0 [run|--verify|--build-only]" >&2
    exit 2
    ;;
esac
