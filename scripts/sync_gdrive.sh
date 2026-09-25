#!/usr/bin/env bash
# ==============================================================================
# sync_gdrive.sh: Selective & On-Demand Synchronization Helper for Google Drive
# Designed for AI Agent environments to avoid disk bloat and unnecessary syncs.
# ==============================================================================
set -euo pipefail

REMOTE_NAME="${GDRIVE_REMOTE:-gdrive:}"
LOCAL_PATH="${GDRIVE_LOCAL_PATH:-$HOME/workspace/gdrive}"

usage() {
    cat << 'EOF'
Usage: sync_gdrive.sh <command> [arguments]

Commands:
  cat <remote_path>           - Read remote file text directly to stdout (zero disk usage)
  list [remote_path]          - List remote files without downloading
  pull <file_or_subfolder>   - Selectively pull a single file or subfolder to local
  push <file_or_subfolder>   - Selectively push a modified file or subfolder to cloud
  pull-all                    - [Caution] Pull entire drive (excludes media/** by default)
  push-all                    - [Caution] Push entire local directory to cloud
  status                      - Display cloud storage usage and local disk usage

Examples:
  ./sync_gdrive.sh cat docs/architecture/ai-agents/design.md
  ./sync_gdrive.sh list docs/topics/
  ./sync_gdrive.sh pull docs/topics/golang/effective-go.md
  ./sync_gdrive.sh push docs/topics/golang/effective-go.md
  ./sync_gdrive.sh status
EOF
    exit 1
}

ACTION="${1:-}"

if [[ -z "$ACTION" ]]; then
    usage
fi

if ! command -v rclone >/dev/null 2>&1; then
    echo "Error: rclone is not installed or not in PATH." >&2
    exit 1
fi

mkdir -p "$LOCAL_PATH"

case "$ACTION" in
    cat)
        TARGET="${2:-}"
        if [[ -z "$TARGET" ]]; then
            echo "Error: Please specify the remote file path to cat." >&2
            exit 1
        fi
        rclone cat "${REMOTE_NAME}${TARGET}"
        ;;

    list)
        TARGET_SUBPATH="${2:-}"
        echo "==> Listing: ${REMOTE_NAME}${TARGET_SUBPATH}"
        rclone lsf "${REMOTE_NAME}${TARGET_SUBPATH}"
        ;;

    pull)
        TARGET="${2:-}"
        if [[ -z "$TARGET" ]]; then
            echo "Error: Please specify the file or subfolder to pull." >&2
            echo "Tip: To pull the entire drive, use 'pull-all'." >&2
            exit 1
        fi
        SRC="${REMOTE_NAME}${TARGET}"
        DEST="${LOCAL_PATH}/${TARGET}"
        
        # Check if remote target is a single file or directory
        if rclone lsf "$SRC" 2>/dev/null | grep -q "/$"; then
            # Directory
            echo "==> Selectively pulling directory: ${SRC} -> ${DEST}"
            mkdir -p "$DEST"
            rclone sync "$SRC" "$DEST" --progress --exclude "media/**"
        else
            # File or directory without trailing slash
            echo "==> Selectively pulling: ${SRC} -> ${DEST}"
            mkdir -p "$(dirname "$DEST")"
            rclone copyto "$SRC" "$DEST" --progress
        fi
        echo "==> Selective pull completed."
        ;;

    push)
        TARGET="${2:-}"
        if [[ -z "$TARGET" ]]; then
            echo "Error: Please specify the local file or subfolder to push." >&2
            echo "Tip: To push the entire local drive, use 'push-all'." >&2
            exit 1
        fi
        SRC="${LOCAL_PATH}/${TARGET}"
        DEST="${REMOTE_NAME}${TARGET}"

        if [[ ! -e "$SRC" ]]; then
            echo "Error: Local path '${SRC}' does not exist." >&2
            exit 1
        fi

        if [[ -d "$SRC" ]]; then
            echo "==> Selectively pushing directory: ${SRC} -> ${DEST}"
            rclone copy "$SRC" "$DEST" --progress
        else
            echo "==> Selectively pushing file: ${SRC} -> ${DEST}"
            rclone copyto "$SRC" "$DEST" --progress
        fi
        echo "==> Selective push completed."
        ;;

    pull-all)
        echo "==> Pulling all drive files (excluding media/**) to prevent disk bloat..."
        rclone sync "${REMOTE_NAME}" "${LOCAL_PATH}" --progress --exclude "media/**"
        echo "==> Sync completed."
        ;;

    push-all)
        echo "==> Pushing all local files to ${REMOTE_NAME} ..."
        rclone copy "${LOCAL_PATH}" "${REMOTE_NAME}" --progress
        echo "==> Push completed."
        ;;

    status)
        echo "==> Google Drive Cloud Storage Usage:"
        rclone size "${REMOTE_NAME}"
        echo ""
        echo "==> Local Workspace Disk Usage (${LOCAL_PATH}):"
        du -sh "${LOCAL_PATH}"
        ;;

    *)
        usage
        ;;
esac
