#!/usr/bin/env bash
set -euo pipefail

# upload_macos.sh - Build and upload the any-ai-for-notion macOS app to TestFlight
#
# Usage:
#   ./upload_macos.sh                  # build + upload to TestFlight
#   ./upload_macos.sh --build-only     # build .pkg, skip upload
#   ./upload_macos.sh --skip-build     # upload existing .pkg, skip build
#
# Requires: fvm, Xcode, .env with App Store Connect API key credentials.
# Reuses the same IOS_* App Store Connect API key as upload_ios.sh.
# Flutter signs the app automatically (cloud signing), no local distribution cert needed.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Stable macOS release build to stamp into the archive.
# App Review rejects (ITMS-90111) binaries whose BuildMachineOSBuild is a beta
# macOS build. Patch the archive so it carries a release OS build string.
# Update this when Apple ships a new macOS release:
#   https://developer.apple.com/news/releases
STABLE_MACOS_BUILD="25F84"

ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env not found at $ENV_FILE" >&2
  echo "Copy .env.example to .env and fill in your credentials." >&2
  exit 1
fi
set -a; . "$ENV_FILE"; set +a

BUNDLE_ID="${IOS_BUNDLE_ID}"
TEAM_ID="${IOS_TEAM_ID}"
API_KEY_ID="${IOS_API_KEY_ID}"
API_ISSUER_ID="${IOS_API_ISSUER_ID}"
API_KEY_PATH="${IOS_API_KEY_PATH}"

BUILD_ONLY=false
SKIP_BUILD=false

for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=true ;;
    --skip-build) SKIP_BUILD=true ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

echo "==> macOS build/upload to TestFlight"
echo "    Bundle ID:  $BUNDLE_ID"
echo "    Team ID:    $TEAM_ID"
echo "    Build:      $PROJECT_DIR"
echo ""

# --- Pre-flight checks ------------------------------------------------------

if [ "$SKIP_BUILD" = false ]; then
  if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
    echo "ERROR: pubspec.yaml not found in $PROJECT_DIR" >&2
    exit 1
  fi
fi

if [ "$BUILD_ONLY" = false ]; then
  if [ -z "$API_ISSUER_ID" ]; then
    echo "ERROR: IOS_API_ISSUER_ID is not set in .env" >&2
    exit 1
  fi

  if [ ! -f "$API_KEY_PATH" ]; then
    echo "ERROR: App Store Connect API key not found at $API_KEY_PATH" >&2
    exit 1
  fi
fi

# --- Build the app and archive ----------------------------------------------

ARCHIVE_PATH="$PROJECT_DIR/build/macos/archive/Runner.xcarchive"
PKG_DIR="$PROJECT_DIR/build/macos/pkg"

if [ "$SKIP_BUILD" = false ]; then
  echo "==> Building macOS app (flutter build macos --release --dart-define-from-file env.json)"
  fvm flutter build macos --release --dart-define-from-file env.json

  echo "==> Creating Xcode archive"
  xcodebuild -workspace "$PROJECT_DIR/macos/Runner.xcworkspace" \
    -scheme Runner \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM_ID"
  echo "    Archive: $ARCHIVE_PATH"
else
  echo "==> Skipping build, using existing archive"
fi

# --- Patch BuildMachineOSBuild in the archive -------------------------------
# ITMS-90111: App Review rejects binaries whose BuildMachineOSBuild is a beta
# macOS build. Patch the archive to carry a release OS build string, then
# re-export so the .pkg embeds the patched frameworks. Idempotent: skips
# plists that already carry the stable build.
if [ "$SKIP_BUILD" = false ]; then
  echo "==> Patching BuildMachineOSBuild -> $STABLE_MACOS_BUILD"

  APP_PATH=$(ls -d "$ARCHIVE_PATH/Products/Applications/"*.app 2>/dev/null | head -1)
  if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "ERROR: No .app found in archive at $ARCHIVE_PATH/Products/Applications/" >&2
    exit 1
  fi
  echo "    App: $(basename "$APP_PATH")"

  patch_plist() {
    local plist="$1"
    [ -f "$plist" ] || return 0
    local current
    current=$(/usr/libexec/PlistBuddy -c "Print :BuildMachineOSBuild" "$plist" 2>/dev/null || true)
    if [ -z "$current" ]; then
      return 0
    fi
    if [ "$current" = "$STABLE_MACOS_BUILD" ]; then
      return 0
    fi
    echo "    $(basename "$(dirname "$plist")"): $current -> $STABLE_MACOS_BUILD"
    /usr/libexec/PlistBuddy -c "Set :BuildMachineOSBuild $STABLE_MACOS_BUILD" "$plist"
  }

  patch_plist "$APP_PATH/Contents/Info.plist"

  echo "==> Re-exporting archive with corrected OS build"
  mkdir -p "$PKG_DIR"
  EXPORT_OPTIONS="$PKG_DIR/ExportOptions.plist"
  cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>export</string>
  <key>generateAppStoreInformation</key>
  <false/>
  <key>manageAppVersionAndBuildNumber</key>
  <true/>
  <key>method</key>
  <string>app-store-connect</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
  <key>testFlightInternalTestingOnly</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
EOF

  rm -f "$PKG_DIR"/*.pkg
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$PKG_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates

  echo "==> Verifying patched metadata"
  APP_SDK=$(/usr/libexec/PlistBuddy -c "Print :DTSDKName" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "MISSING")
  APP_OS=$(/usr/libexec/PlistBuddy -c "Print :BuildMachineOSBuild" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "MISSING")
  APP_XCODE=$(/usr/libexec/PlistBuddy -c "Print :DTXcode" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "MISSING")
  echo "    Runner.app: DTSDKName=$APP_SDK BuildMachineOSBuild=$APP_OS DTXcode=$APP_XCODE"
  if [ "$APP_OS" != "$STABLE_MACOS_BUILD" ]; then
    echo "ERROR: Runner.app BuildMachineOSBuild is $APP_OS, expected $STABLE_MACOS_BUILD" >&2
    exit 1
  fi
fi

# --- Locate the .pkg --------------------------------------------------------

PKG_FILE=$(ls "$PKG_DIR"/*.pkg 2>/dev/null | head -1)
if [ -z "$PKG_FILE" ]; then
  echo "ERROR: No .pkg file found in $PKG_DIR" >&2
  echo "Run without --skip-build, or check the build output above." >&2
  exit 1
fi
PKG_NAME=$(basename "$PKG_FILE")
echo "    Pkg:       $PKG_FILE"

if [ "$BUILD_ONLY" = true ]; then
  echo "==> Build-only mode, pkg saved to: $PKG_FILE"
  echo "==> Done"
  exit 0
fi

# --- Upload to TestFlight via altool -----------------------------------------

echo "==> Uploading pkg to TestFlight"
echo "    API Key:   $API_KEY_ID"
echo "    Issuer ID: $API_ISSUER_ID"
echo "    Pkg:       $PKG_NAME"
echo ""

xcrun altool --upload-app \
  --type macos \
  -f "$PKG_FILE" \
  --apiKey "$API_KEY_ID" \
  --apiIssuer "$API_ISSUER_ID" \
  --apiKeyPath "$API_KEY_PATH"

echo ""
echo "==> Upload complete. Build should appear in TestFlight within 15-30 minutes."
echo "==> Done"