---
name: google-drive
description: Manage and synchronize files between local workspace and Google Drive using rclone. Use when the user wants to list, search, read, download, upload, or synchronize files/folders with Google Drive (gdrive). 中文触发词包括“同步网盘”“拉取云盘”“上传到Google Drive”“下载网盘文件”“查看网盘”“Google Drive同步”。
---

# Google Drive Integration Skill for Antigravity

This skill enables Google Antigravity (and other AI coding agents) to interact seamlessly with Google Drive via `rclone`.

## Configuration & Credentials

- **Remote Name**: `gdrive:` (configured in rclone)
- **Local Directory**: `$WORKSPACE_ROOT/gdrive` (or `~/workspace/gdrive`)
- **Config File**: `~/.config/rclone/rclone.conf`

## Common Operations

### 1. Pull / Synchronize from Google Drive to Local Workspace
To fetch the latest files from Google Drive into the local workspace:
```bash
rclone sync gdrive: "$WORKSPACE_ROOT/gdrive"
```

To sync a specific subfolder only:
```bash
rclone sync gdrive:subfolder "$WORKSPACE_ROOT/gdrive/subfolder"
```

### 2. Push / Upload Local Workspace Changes to Google Drive
To upload new or modified local files to Google Drive without deleting remote files:
```bash
rclone copy "$WORKSPACE_ROOT/gdrive" gdrive:
```

To mirror local changes strictly to the remote directory:
```bash
rclone sync "$WORKSPACE_ROOT/gdrive" gdrive:
```

### 3. List & Search Files in Google Drive
List files in root or a specific remote path:
```bash
rclone lsf gdrive:
rclone lsf gdrive:path/to/folder/
```

Search for files matching a pattern:
```bash
rclone ls gdrive: --include "*.md"
```

### 4. Direct View / Read Remote File Contents
Read the text content of a remote file directly into stdout without needing a full directory sync:
```bash
rclone cat gdrive:path/to/remote-file.md
```
