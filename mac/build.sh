#!/bin/bash
# HSC Essay Engine - build script v1.1.1
# Usage:  bash build.sh            (build and open)
#         bash build.sh --install  (build, copy to /Applications, open)
set -euo pipefail
cd "$(dirname "$0")"

APP="HSC Essay Engine.app"
VERSION="1.1.0"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "Swift compiler not found. Run this first, then try again:"
  echo "  xcode-select --install"
  exit 1
fi

echo "Building HSC Essay Engine v${VERSION}..."
rm -rf build "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build

swiftc -O Sources/main.swift -o "$APP/Contents/MacOS/HSCEssayEngine" -framework Cocoa -framework WebKit

cp Resources/index.html "$APP/Contents/Resources/index.html"
cp Resources/Info.plist "$APP/Contents/Info.plist"

ICONSET="build/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s Resources/icon-1024.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z $d $d Resources/icon-1024.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

codesign --force --deep -s - "$APP" >/dev/null 2>&1 || true
rm -rf build
echo "Built: ${APP} (v${VERSION})"

if [[ "${1:-}" == "--install" ]]; then
  rm -rf "/Applications/$APP"
  cp -R "$APP" /Applications/
  rm -rf "$APP"
  echo "Installed to /Applications (no duplicate left in this folder)"
  open "/Applications/$APP"
else
  open "$APP"
fi
