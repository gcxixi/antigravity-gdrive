#!/usr/bin/env bash
# ==============================================================================
# sync_gdrive.sh: Bi-directional synchronization helper for Google Drive
# ==============================================================================
set -euo pipefail

REMOTE_NAME="${GDRIVE_REMOTE:-gdrive:}"
LOCAL_PATH="${GDRIVE_LOCAL_PATH:-$HOME/workspace/gdrive}"

usage() {
    echo "Usage: $0 [pull|push|status|list [subpath]]"
    echo ""
    echo "Commands:"
    echo "  pull     - Synchronize changes from Google Drive to local directory"
    echo "  push     - Upload local modifications/additions to Google Drive"
    echo "  status   - Show remote storage size and local sync status"
    echo "  list     - List remote files in root or specified path"
    exit 1
}

ACTION="${1:-pull}"

if ! command -v rclone >/dev/null 2>&1; then
    echo "Error: rclone is not installed or not in PATH." >&2
    exit 1
fi

mkdir -p "$LOCAL_PATH"

case "$ACTION" in
    pull)
        echo "==> Pulling from ${REMOTE_NAME} to ${LOCAL_PATH} ..."
        rclone sync "${REMOTE_NAME}" "${LOCAL_PATH}" --progress
        echo "==> Pull completed successfully."
        ;;
    push)
        echo "==> Pushing from ${LOCAL_PATH} to ${REMOTE_NAME} ..."
        rclone copy "${LOCAL_PATH}" "${REMOTE_NAME}" --progress
        echo "==> Push completed successfully."
        ;;
    status)
        echo "==> Checking Google Drive remote size..."
        rclone size "${REMOTE_NAME}"
        echo "==> Local directory size:"
        du -sh "${LOCAL_PATH}"
        ;;
    list)
        TARGET_SUBPATH="${2:-}"
        rclone lsf "${REMOTE_NAME}${TARGET_SUBPATH}"
        ;;
    *)
        usage
        ;;
esac
