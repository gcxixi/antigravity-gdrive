#!/usr/bin/env bash
# ==============================================================================
# setup_rclone.sh: Automated installer for rclone (macOS & Linux)
# ==============================================================================
set -euo pipefail

if command -v rclone >/dev/null 2>&1; then
    echo "==> rclone is already installed at: $(command -v rclone)"
    rclone version
    exit 0
fi

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

case "$OS" in
    darwin) PLATFORM="osx-${ARCH}" ;;
    linux)  PLATFORM="linux-${ARCH}" ;;
    *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

DOWNLOAD_URL="https://downloads.rclone.org/rclone-current-${PLATFORM}.zip"
echo "==> Downloading rclone from $DOWNLOAD_URL ..."
curl -fsSL -o "$TEMP_DIR/rclone.zip" "$DOWNLOAD_URL"

echo "==> Extracting rclone package..."
unzip -q "$TEMP_DIR/rclone.zip" -d "$TEMP_DIR"

INSTALL_DIR="/usr/local/bin"
if [[ "$OS" == "darwin" && -d "/opt/homebrew/bin" && -w "/opt/homebrew/bin" ]]; then
    INSTALL_DIR="/opt/homebrew/bin"
elif [[ ! -w "$INSTALL_DIR" ]]; then
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
fi

echo "==> Installing binary to $INSTALL_DIR/rclone..."
cp "$TEMP_DIR"/rclone-*-${PLATFORM}/rclone "$INSTALL_DIR/rclone"
chmod +x "$INSTALL_DIR/rclone"

echo "==> Installation complete!"
"$INSTALL_DIR/rclone" version
