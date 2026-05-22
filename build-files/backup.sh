#!/bin/ash

set -Eeuo pipefail

echo "[Backup] Starting backup."

SERVER_DATA_DIR="${SERVER_DATA_DIR:-/server/data}"
BACKUP_DIR="${BACKUP_DIR:-$SERVER_DATA_DIR/backups}"
BACKUP_RETAIN="${BACKUP_RETAIN:-7}"
S3_UPLOAD="${S3_UPLOAD:-false}"

# Resolve world name: env var → server.properties level-name → "world"
WORLD_NAME="${WORLD_NAME:-}"
if [ -z "$WORLD_NAME" ] && [ -f "$SERVER_DATA_DIR/server.properties" ]; then
    WORLD_NAME=$(grep -m1 '^level-name=' "$SERVER_DATA_DIR/server.properties" | cut -d= -f2 | tr -d '[:space:]')
fi
WORLD_NAME="${WORLD_NAME:-world}"

# Resolve backup ID: env var → world name
BACKUP_ID="${BACKUP_ID:-$WORLD_NAME}"

WORLD_DIR="$SERVER_DATA_DIR/$WORLD_NAME"

echo "[Backup] World: $WORLD_DIR"
echo "[Backup] Backup dir: $BACKUP_DIR"
echo "[Backup] Backup ID: $BACKUP_ID"
echo "[Backup] Retain: $BACKUP_RETAIN"

if [ ! -d "$WORLD_DIR" ]; then
    echo >&2 "[Backup] ERROR: World directory not found: $WORLD_DIR"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

# Space check
WORLD_SIZE=$(du -sb "$WORLD_DIR" | awk '{print $1}')
AVAIL_KB=$(df -k "$BACKUP_DIR" | awk 'NR==2 {print $4}')
AVAIL_BYTES=$((AVAIL_KB * 1024))
REQUIRED=$((WORLD_SIZE * 12 / 10))

echo "[Backup] World size: $WORLD_SIZE bytes, available: $AVAIL_BYTES bytes, required: $REQUIRED bytes"

if [ "$AVAIL_BYTES" -lt "$REQUIRED" ]; then
    echo >&2 "[Backup] ERROR: Not enough disk space. Need $REQUIRED bytes, have $AVAIL_BYTES bytes."
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="${BACKUP_ID}-${TIMESTAMP}.tar.gz"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"

echo "[Backup] Creating archive: $BACKUP_FILE"
tar -cvzf "$BACKUP_FILE" -C "$SERVER_DATA_DIR" "$WORLD_NAME"
echo "[Backup] Archive created successfully."

# Rotate local backups (scoped to this BACKUP_ID)
echo "[Backup] Rotating local backups (keeping $BACKUP_RETAIN)..."
find "$BACKUP_DIR" -maxdepth 1 -name "${BACKUP_ID}-[0-9]*.tar.gz" | sort -r | tail -n +$((BACKUP_RETAIN + 1)) | xargs -r rm -v

if [ "$S3_UPLOAD" = "true" ]; then
    echo "[Backup] Uploading to S3..."
    /server/s3-upload.sh "$BACKUP_FILE" "$BACKUP_ID"
fi

echo "[Backup] Done."
