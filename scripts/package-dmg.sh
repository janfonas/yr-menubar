#!/usr/bin/env bash
set -euo pipefail

# Package YrMenuBar.app into .dmg and .zip for distribution.
# Requires create-dmg (brew install create-dmg). Falls back to hdiutil if absent.

VERSION="${1:-0.0.0-dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/YrMenuBar.app"

if [[ ! -d "$APP" ]]; then
    echo "Run scripts/build-app.sh first." >&2
    exit 1
fi

cd "$DIST"

ZIP_NAME="YrMenuBar-$VERSION.zip"
echo "==> Creating $ZIP_NAME"
ditto -c -k --sequesterRsrc --keepParent "YrMenuBar.app" "$ZIP_NAME"

DMG_NAME="YrMenuBar-$VERSION.dmg"
echo "==> Creating $DMG_NAME"
if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
        --volname "YrMenuBar $VERSION" \
        --window-size 480 300 \
        --icon-size 96 \
        --icon "YrMenuBar.app" 120 140 \
        --app-drop-link 360 140 \
        --no-internet-enable \
        "$DMG_NAME" "YrMenuBar.app" || true
fi

if [[ ! -f "$DMG_NAME" ]]; then
    echo "==> Falling back to hdiutil"
    rm -rf staging
    mkdir staging
    cp -R "YrMenuBar.app" staging/
    ln -s /Applications staging/Applications
    hdiutil create -volname "YrMenuBar $VERSION" -srcfolder staging -ov -format UDZO "$DMG_NAME"
    rm -rf staging
fi

ls -lh "$ZIP_NAME" "$DMG_NAME"
