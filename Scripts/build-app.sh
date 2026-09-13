#!/bin/zsh

set -euo pipefail

PROJECT_ROOT=${0:A:h:h}
CONFIGURATION=${CONFIGURATION:-release}
SIGN_IDENTITY=${SIGN_IDENTITY:--}

cd "$PROJECT_ROOT"
swift build --configuration "$CONFIGURATION" --arch arm64

BIN_DIRECTORY=$(swift build --configuration "$CONFIGURATION" --arch arm64 --show-bin-path)
PRODUCT_DIRECTORY="$PROJECT_ROOT/.build/product"
APP_BUNDLE="$PRODUCT_DIRECTORY/Finder Tweaks.app"
AGENT_BUNDLE="$APP_BUNDLE/Contents/Library/LoginItems/Finder Tweaks Agent.app"

rm -rf "$PRODUCT_DIRECTORY"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$AGENT_BUNDLE/Contents/MacOS"

install -m 755 "$BIN_DIRECTORY/FinderTweaks" "$APP_BUNDLE/Contents/MacOS/FinderTweaks"
install -m 644 "$PROJECT_ROOT/Resources/FinderTweaks-Info.plist" "$APP_BUNDLE/Contents/Info.plist"
install -m 644 "$PROJECT_ROOT/icon.icns" "$APP_BUNDLE/Contents/Resources/FinderTweaks.icns"
xattr -c "$APP_BUNDLE/Contents/Resources/FinderTweaks.icns"

install -m 755 "$BIN_DIRECTORY/FinderTweaksAgent" "$AGENT_BUNDLE/Contents/MacOS/FinderTweaksAgent"
install -m 644 "$PROJECT_ROOT/Resources/FinderTweaksAgent-Info.plist" "$AGENT_BUNDLE/Contents/Info.plist"

codesign --force --options runtime --sign "$SIGN_IDENTITY" "$AGENT_BUNDLE"
codesign --force --options runtime --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

print "$APP_BUNDLE"
