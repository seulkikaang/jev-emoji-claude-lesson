#!/usr/bin/env bash
# Builds "build/JEV Emoji.app" from the Swift package.
# Usage: ./scripts/build-app.sh
set -euo pipefail

cd "$(dirname "$0")/.."

APP_DIR="build/JEV Emoji.app"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BIN_DIR/JEVEmoji" "$APP_DIR/Contents/MacOS/JEVEmoji"
cp packaging/Info.plist "$APP_DIR/Contents/Info.plist"

# Remove debug symbols: they embed the builder's local folder paths.
strip -S -x "$APP_DIR/Contents/MacOS/JEVEmoji"

# Ad-hoc signature so macOS can identify the app for the Accessibility list.
codesign --force --sign - "$APP_DIR"

echo "Built: $APP_DIR"
