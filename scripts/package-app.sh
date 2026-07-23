#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
BUILD_ROOT="${LIMITER_BUILD_ROOT:-$HOME/Library/Caches/LimiterBuild}"
DIST="$ROOT/dist"
APP="$BUILD_ROOT/Limiter.app"
CONTENTS="$APP/Contents"

rm -rf "$BUILD_ROOT"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$DIST"

swift build \
  --package-path "$ROOT" \
  --scratch-path "$BUILD_ROOT/swift-arm64" \
  --configuration release \
  --arch arm64 \
  --disable-sandbox

swift build \
  --package-path "$ROOT" \
  --scratch-path "$BUILD_ROOT/swift-x86_64" \
  --configuration release \
  --arch x86_64 \
  --disable-sandbox

lipo -create \
  "$BUILD_ROOT/swift-arm64/arm64-apple-macosx/release/Limiter" \
  "$BUILD_ROOT/swift-x86_64/x86_64-apple-macosx/release/Limiter" \
  -output "$CONTENTS/MacOS/Limiter"

cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$CONTENTS/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$CONTENTS/Info.plist"

ICONSET="$BUILD_ROOT/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$ROOT/Resources/AppIcon.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" "$ROOT/Resources/AppIcon.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$CONTENTS/Resources/AppIcon.icns"

chmod +x "$CONTENTS/MacOS/Limiter"
codesign --force --deep --options runtime --sign - "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

STAGE="$BUILD_ROOT/dmg"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/Limiter.app"
ln -s /Applications "$STAGE/Applications"

DMG="$DIST/Limiter-$VERSION.dmg"
rm -f "$DMG"
hdiutil create \
  -volname "Limiter" \
  -srcfolder "$STAGE" \
  -format UDZO \
  -ov \
  "$DMG" >/dev/null

shasum -a 256 "$DMG" > "$DMG.sha256"

printf 'Built %s\n' "$APP"
printf 'Packaged %s\n' "$DMG"
