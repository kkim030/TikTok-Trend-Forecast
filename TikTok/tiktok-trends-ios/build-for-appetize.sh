#!/usr/bin/env bash
# Build the iOS app for the iPhone Simulator and zip it for Appetize.io upload.
# Usage:  ./build-for-appetize.sh
# Output: ./build/TikTokTrends-appetize.zip  (drag this into appetize.io upload page)

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

PROJECT="TikTokTrends.xcodeproj"
SCHEME="TikTokTrends"
CONFIG="Release"          # Release config → APIClient hits Render URL, not localhost
DERIVED="$SCRIPT_DIR/build/derived"
OUT_DIR="$SCRIPT_DIR/build"

echo "▶︎ Building $SCHEME ($CONFIG) for iPhone Simulator…"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build

APP_PATH=$(find "$DERIVED/Build/Products/$CONFIG-iphonesimulator" -maxdepth 1 -name "*.app" | head -n 1)
if [ -z "$APP_PATH" ]; then
    echo "✗ Couldn't locate built .app under $DERIVED/Build/Products/$CONFIG-iphonesimulator" >&2
    exit 1
fi

ZIP_PATH="$OUT_DIR/TikTokTrends-appetize.zip"
rm -f "$ZIP_PATH"
( cd "$(dirname "$APP_PATH")" && zip -qr "$ZIP_PATH" "$(basename "$APP_PATH")" )

echo ""
echo "✓ Built:  $APP_PATH"
echo "✓ Zipped: $ZIP_PATH"
echo ""
echo "Next:"
echo "  1. Go to https://appetize.io/upload"
echo "  2. Drag $ZIP_PATH into the upload area"
echo "  3. Pick an iPhone device (15 / 16 work fine), iOS 17+"
echo "  4. Copy the public URL Appetize gives you and paste it into the README"
