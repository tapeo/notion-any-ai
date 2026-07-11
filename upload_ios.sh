#!/usr/bin/env bash
set -euo pipefail

# upload_ios.sh - Build and upload the any-ai-for-notion iOS app to TestFlight
#
# Usage:
#   ./upload_ios.sh                  # build + upload to TestFlight
#   ./upload_ios.sh --build-only     # build IPA, skip upload
#   ./upload_ios.sh --skip-build      # upload existing IPA, skip build
#
# Requires: fvm, Xcode, .env with credentials
# Flutter signs the IPA automatically (cloud signing), no local distribution cert needed.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

echo "==> iOS build/upload to TestFlight"
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

# --- Build the IPA ----------------------------------------------------------

ARCHIVE_PATH="$PROJECT_DIR/build/ios/archive/Runner.xcarchive"
IPA_DIR="$PROJECT_DIR/build/ios/ipa"

if [ "$SKIP_BUILD" = false ]; then
  echo "==> Building IPA (flutter build ipa --release --dart-define-from-file env.json)"
  fvm flutter build ipa --release --dart-define-from-file env.json
  echo "    Archive: $ARCHIVE_PATH"
else
  echo "==> Skipping build, using existing IPA"
fi

# --- Locate the IPA ---------------------------------------------------------

IPA_FILE=$(ls "$IPA_DIR"/*.ipa 2>/dev/null | head -1)
if [ -z "$IPA_FILE" ]; then
  echo "ERROR: No .ipa file found in $IPA_DIR" >&2
  echo "Run without --skip-build, or check the build output above." >&2
  exit 1
fi
IPA_NAME=$(basename "$IPA_FILE")
echo "    IPA:       $IPA_FILE"

if [ "$BUILD_ONLY" = true ]; then
  echo "==> Build-only mode, IPA saved to: $IPA_FILE"
  echo "==> Done"
  exit 0
fi

# --- Upload to TestFlight via altool -----------------------------------------

echo "==> Uploading IPA to TestFlight"
echo "    API Key:   $API_KEY_ID"
echo "    Issuer ID: $API_ISSUER_ID"
echo "    IPA:       $IPA_NAME"
echo ""

xcrun altool --upload-app \
  --type ios \
  -f "$IPA_FILE" \
  --apiKey "$API_KEY_ID" \
  --apiIssuer "$API_ISSUER_ID"

echo ""
echo "==> Upload complete. Build should appear in TestFlight within 15-30 minutes."
echo "==> Done"