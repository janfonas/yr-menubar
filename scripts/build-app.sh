#!/usr/bin/env bash
set -euo pipefail

# Build YrMenuBar.app bundle from SwiftPM output.
# Usage: ./scripts/build-app.sh [version] [build]
#   version: defaults to "0.0.0-dev"
#   build:   defaults to current epoch seconds

VERSION="${1:-0.0.0-dev}"
BUILD="${2:-$(date +%s)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/YrMenuBar.app"

echo "==> Building YrMenuBar v$VERSION ($BUILD)"

# Detect arch and build universal when xcbuild is available (full Xcode installed)
ARCH_FLAGS=()
if xcrun --find xcbuild >/dev/null 2>&1 && [[ -x "/Library/Developer/SharedFrameworks/XCBuild.framework/Versions/A/Support/xcbuild" || -x "$(xcode-select -p 2>/dev/null)/../SharedFrameworks/XCBuild.framework/Versions/A/Support/xcbuild" ]]; then
    if [[ "$(uname -m)" == "arm64" ]]; then
        ARCH_FLAGS=(--arch arm64 --arch x86_64)
    fi
fi

cd "$ROOT"
rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> swift build (release${ARCH_FLAGS:+, universal})"
if [[ ${#ARCH_FLAGS[@]} -gt 0 ]]; then
    swift build -c release "${ARCH_FLAGS[@]}" --product YrMenuBar
    BIN="$(swift build -c release --show-bin-path "${ARCH_FLAGS[@]}")/YrMenuBar"
else
    swift build -c release --product YrMenuBar
    BIN="$(swift build -c release --show-bin-path)/YrMenuBar"
fi
if [[ ! -f "$BIN" ]]; then
    echo "Executable not found at $BIN" >&2
    exit 1
fi

cp "$BIN" "$APP/Contents/MacOS/YrMenuBar"
chmod +x "$APP/Contents/MacOS/YrMenuBar"

# Info.plist with version substitution
sed -e "s/__VERSION__/$VERSION/g" -e "s/__BUILD__/$BUILD/g" \
    "$ROOT/Resources/Info.plist" > "$APP/Contents/Info.plist"

# App icon — (re)generate if missing or stale, then copy into the bundle.
ICNS="$ROOT/Resources/AppIcon.icns"
if [[ ! -f "$ICNS" || "$ROOT/scripts/generate-icon.swift" -nt "$ICNS" ]]; then
    echo "==> Generating AppIcon.icns"
    (cd "$ROOT" && swift scripts/generate-icon.swift >/dev/null)
fi
if [[ -f "$ICNS" ]]; then
    cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"
else
    echo "warning: AppIcon.icns not found, bundle will use the generic icon" >&2
fi

# Bundle the SwiftPM resource bundle if present
if [[ ${#ARCH_FLAGS[@]} -gt 0 ]]; then
    BUNDLE_DIR="$(swift build -c release --show-bin-path "${ARCH_FLAGS[@]}")"
else
    BUNDLE_DIR="$(swift build -c release --show-bin-path)"
fi
for b in "$BUNDLE_DIR"/*.bundle; do
    if [[ -d "$b" ]]; then
        cp -R "$b" "$APP/Contents/Resources/"
    fi
done

# Ad-hoc codesign so Gatekeeper accepts after right-click → Open
echo "==> Ad-hoc codesigning"
codesign --force --deep --sign - "$APP"

echo "==> Built $APP"
du -sh "$APP"
