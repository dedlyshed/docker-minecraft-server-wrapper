#!/bin/ash

set -Eeuo pipefail

LOCAL_FILE="${1:?Usage: s3-upload.sh <local-file> <backup-id>}"
BACKUP_ID="${2:?Usage: s3-upload.sh <local-file> <backup-id>}"

S3_BUCKET="${S3_BUCKET:?S3_BUCKET is required}"
S3_PREFIX="${S3_PREFIX:-backups/}"
S3_ENDPOINT="${S3_ENDPOINT:-}"
BACKUP_RETAIN="${BACKUP_RETAIN:-7}"

# AWS credentials are read from standard env vars:
#   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION / AWS_DEFAULT_REGION

ENDPOINT_FLAG=""
if [ -n "$S3_ENDPOINT" ]; then
    ENDPOINT_FLAG="--endpoint-url $S3_ENDPOINT"
fi

OBJECT_NAME="$(basename "$LOCAL_FILE")"
S3_TARGET="s3://${S3_BUCKET}/${S3_PREFIX}${OBJECT_NAME}"

echo "[S3 Upload] Uploading $LOCAL_FILE → $S3_TARGET"
# shellcheck disable=SC2086
s5cmd $ENDPOINT_FLAG cp --show-progress "$LOCAL_FILE" "$S3_TARGET"
echo "[S3 Upload] Upload complete."

# Rotate S3 backups scoped to BACKUP_ID
echo "[S3 Upload] Rotating S3 backups for ID '$BACKUP_ID' (keeping $BACKUP_RETAIN)..."

# shellcheck disable=SC2086
OLD_OBJECTS=$(
    s5cmd $ENDPOINT_FLAG ls "s3://${S3_BUCKET}/${S3_PREFIX}" \
    | awk '{print $NF}' \
    | grep "/${BACKUP_ID}-[0-9].*\.tar\.gz$" \
    | sort \
    | head -n -"$BACKUP_RETAIN"
)

if [ -n "$OLD_OBJECTS" ]; then
    echo "$OLD_OBJECTS" | while IFS= read -r obj; do
        echo "[S3 Upload] Deleting old backup: $obj"
        # shellcheck disable=SC2086
        s5cmd $ENDPOINT_FLAG rm "$obj"
    done
else
    echo "[S3 Upload] No old backups to delete."
fi

echo "[S3 Upload] Done."
