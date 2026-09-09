#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/Payload/Wasfaty.app"
IPA_PATH="$BUILD_DIR/Wasfaty_iOS15_TrollStore.ipa"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR"

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "Using iPhoneOS SDK: $SDK"

xcrun --sdk iphoneos swiftc \
  "$ROOT_DIR/Sources/WasfatyApp.swift" \
  -parse-as-library \
  -sdk "$SDK" \
  -target arm64-apple-ios15.0 \
  -O \
  -framework UIKit \
  -framework WebKit \
  -o "$APP_DIR/Wasfaty"

chmod +x "$APP_DIR/Wasfaty"
cp "$ROOT_DIR/Info.plist" "$APP_DIR/Info.plist"
cp "$ROOT_DIR/Resources/Icons/AppIcon60x60@2x.png" "$APP_DIR/AppIcon60x60@2x.png"
cp "$ROOT_DIR/Resources/Icons/AppIcon60x60@3x.png" "$APP_DIR/AppIcon60x60@3x.png"

# Ad-hoc signature. TrollStore can install apps outside normal App Store provisioning.
codesign --force --sign - --timestamp=none "$APP_DIR"

(
  cd "$BUILD_DIR"
  /usr/bin/zip -qry "$(basename "$IPA_PATH")" Payload
)

echo "Built: $IPA_PATH"
/usr/bin/file "$APP_DIR/Wasfaty"
/usr/bin/codesign -dv "$APP_DIR" 2>&1 || true
