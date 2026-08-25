#!/bin/bash
# Unsigned experimental zip. Not for public distribution.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/dist"
python3 "$ROOT/Tools/generate_xcodeproj.py"
rm -rf "$DEST"
mkdir -p "$DEST/build"
xcodebuild -project "$ROOT/HSMacOSTracker.xcodeproj" -scheme HSMacOSTracker \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  CONFIGURATION_BUILD_DIR="$DEST/build" \
  build
APP="$DEST/build/HSMacOSTracker.app"
ditto -c -k --keepParent "$APP" "$DEST/HSMacOSTracker-unsigned.zip"
echo "unsigned experimental: $DEST/HSMacOSTracker-unsigned.zip"
