#!/usr/bin/env bash
set -euo pipefail

# upload_snap.sh - Build and upload the any-ai-for-notion snap via Multipass
#
# Usage:
#   ./upload_snap.sh                  # build + upload to stable
#   ./upload_snap.sh --build-only     # build only, skip upload
#   ./upload_snap.sh --channel=beta   # upload to a specific channel
#   ./upload_snap.sh --clean          # recreate VM from scratch
#
# Requires: multipass, .env with credentials

VM_NAME="snap-build"
BASE_IMAGE="22.04"
CPUS="4"
MEMORY="8G"
DISK="40G"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
REMOTE_DIR="/home/ubuntu/project"

ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env not found at $ENV_FILE" >&2
  echo "Copy .env.example to .env and fill in your credentials." >&2
  exit 1
fi
set -a; . "$ENV_FILE"; set +a

SNAP_STORE_EMAIL="${SNAP_STORE_EMAIL}"
SNAP_STORE_PASSWORD="${SNAP_STORE_PASSWORD}"

CHANNEL="stable"
BUILD_ONLY=false
CLEAN=false

for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=true ;;
    --clean) CLEAN=true ;;
    --channel=*) CHANNEL="${arg#--channel=}" ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

echo "==> Snap build/upload via Multipass"
echo "    VM:       $VM_NAME"
echo "    Channel:  $CHANNEL"
echo "    Build:    $PROJECT_DIR"
echo ""

# --- VM management -----------------------------------------------------------

if [ "$CLEAN" = true ]; then
  echo "==> Cleaning up existing VM"
  multipass delete "$VM_NAME" --purge 2>/dev/null || true
fi

if ! multipass info "$VM_NAME" >/dev/null 2>&1; then
  echo "==> Launching new VM ($BASE_IMAGE, $CPUS cpus, $MEMORY ram, $DISK disk)"
  multipass launch "$BASE_IMAGE" \
    --name "$VM_NAME" \
    --cpus "$CPUS" \
    --memory "$MEMORY" \
    --disk "$DISK"
else
  echo "==> Using existing VM: $VM_NAME"
fi

VM_STATE=$(multipass info "$VM_NAME" --format csv | tail -1 | cut -d, -f2)
if [ "$VM_STATE" != "Running" ]; then
  echo "==> Starting VM"
  multipass start "$VM_NAME"
fi

# --- Install build tools -----------------------------------------------------

echo "==> Checking for snapcraft and lxd in VM"
multipass exec "$VM_NAME" -- bash -c '
  if ! command -v snapcraft >/dev/null 2>&1; then
    echo "    Installing snapcraft..."
    sudo snap install snapcraft --classic
  fi
  if ! command -v lxc >/dev/null 2>&1; then
    echo "    Installing lxd..."
    sudo snap install lxd
  fi
  # Always ensure LXD is initialized
  if ! sudo lxc profile device get default root path >/dev/null 2>&1; then
    echo "    Initializing LXD..."
    sudo lxd init --auto
  fi
  # Install keyring so snapcraft can store login credentials
  if ! dpkg -s gnome-keyring >/dev/null 2>&1; then
    echo "    Installing gnome-keyring..."
    sudo apt-get update -qq && sudo apt-get install -y -qq gnome-keyring dbus-x11 >/dev/null
  fi
'

# --- Copy project into VM ----------------------------------------------------

echo "==> Syncing project to VM (excluding build artifacts)"

TMP_TAR="/tmp/any-ai-for-notion-src.tar.gz"

# Create tarball on host, excluding build artifacts, platform-specific dirs, and macOS metadata
COPYFILE_DISABLE=1 tar czf "$TMP_TAR" \
  --exclude='build' \
  --exclude='.dart_tool' \
  --exclude='.git' \
  --exclude='.fvm' \
  --exclude='ios' \
  --exclude='macos' \
  --exclude='android' \
  --exclude='windows' \
  --exclude='changes' \
  --exclude='linux/flutter/ephemeral' \
  --exclude='upload_snap.sh' \
  --exclude='._*' \
  --exclude='.DS_Store' \
  -C "$PROJECT_DIR" .

# Transfer tarball into the VM via stdin (avoids SFTP write issues)
multipass exec "$VM_NAME" -- mkdir -p "$REMOTE_DIR"
cat "$TMP_TAR" | multipass exec "$VM_NAME" -- bash -c "cat > /tmp/src.tar.gz && rm -rf $REMOTE_DIR/* && tar xzf /tmp/src.tar.gz -C $REMOTE_DIR && rm -f /tmp/src.tar.gz"
rm -f "$TMP_TAR"

# --- Build the snap ----------------------------------------------------------

echo "==> Building snap"
multipass exec "$VM_NAME" -- bash -c "cd $REMOTE_DIR && snapcraft clean && snapcraft pack"

# --- Find the built snap file ------------------------------------------------

SNAP_FILE=$(multipass exec "$VM_NAME" -- bash -c "ls $REMOTE_DIR/*.snap 2>/dev/null | head -1")
if [ -z "$SNAP_FILE" ]; then
  echo "ERROR: No .snap file found after build" >&2
  exit 1
fi
SNAP_NAME=$(basename "$SNAP_FILE")
echo "    Built: $SNAP_NAME"

# --- Upload or copy out ------------------------------------------------------

if [ "$BUILD_ONLY" = true ]; then
  echo "==> Build-only mode, copying snap to host"
  multipass transfer "$VM_NAME:$SNAP_FILE" "$PROJECT_DIR/$SNAP_NAME"
  echo "==> Snap saved to: $PROJECT_DIR/$SNAP_NAME"
else
  # Install expect if missing (needed for non-interactive login)
  multipass exec "$VM_NAME" -- bash -c '
    if ! command -v expect >/dev/null 2>&1; then
      sudo apt-get install -y -qq expect >/dev/null 2>&1
    fi
  '

  # Export credentials non-interactively, then use them for upload
  echo "==> Logging in to Snap Store"
  CRED_FILE="/tmp/snap_creds.txt"
  multipass exec "$VM_NAME" -- bash -c "
    cat > /tmp/snap_export.exp << 'EXPECT_EOF'
#!/usr/bin/expect -f
set timeout 30
spawn snapcraft export-login /tmp/snap_creds.txt
expect {
  \"Email:\" { send \"$SNAP_STORE_EMAIL\r\"; exp_continue }
  \"Password:\" { send \"$SNAP_STORE_PASSWORD\r\"; exp_continue }
  \"Two-factor\" { send \"\r\"; exp_continue }
  eof
}
EXPECT_EOF
    chmod +x /tmp/snap_export.exp
    rm -f /tmp/snap_creds.txt
    /tmp/snap_export.exp || true
    rm -f /tmp/snap_export.exp
  "

  echo "==> Uploading snap to channel: $CHANNEL"
  multipass exec "$VM_NAME" -- bash -c '
    if [ ! -s /tmp/snap_creds.txt ]; then
      echo "ERROR: Credentials file is empty. Login may have failed." >&2
      exit 1
    fi
    cd '"$REMOTE_DIR"' && SNAPCRAFT_STORE_CREDENTIALS="$(cat /tmp/snap_creds.txt)" snapcraft upload --release='"$CHANNEL"' '"$SNAP_NAME"'
  '
  multipass exec "$VM_NAME" -- rm -f /tmp/snap_creds.txt
  echo "==> Upload complete: $CHANNEL"
fi

echo ""
echo "==> Done"