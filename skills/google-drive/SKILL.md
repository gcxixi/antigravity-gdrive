---
name: google-drive
description: Manage and selectively synchronize files between local workspace and Google Drive using rclone. Use when the user wants to inspect, search, read, download, upload, or sync files/folders with Google Drive (gdrive). 中文触发词包括“同步网盘”“拉取云盘”“上传到Google Drive”“下载网盘文件”“查看网盘”“Google Drive同步”“备份到云端”。
---

# Google Drive Integration Skill for Antigravity

本技能定义了 Antigravity 与 Google Drive 协作的核心规则与操作规范。
**核心原则：轻量化按需获取、杜绝无意义的全量拉取；多轮任务本地沉浸编辑，待终态或用户明确要求时再执行精准同步。**

---

## 1. 核心行为准则 (Strict Operational Guidelines)

### 规则 1：严禁默认进行全量同步 (Never Full-Sync by Default)
- **原因**：云端文件随着时间会持续膨胀（音视频素材、大体积 PDF、备份数据等），全量同步会瞬间侵占大量本地磁盘空间并拖慢响应。
- **准则**：
  1. **查询目录/搜索**：直接在线读取远端元数据（`rclone lsf` / `rclone ls --include`），不要先下载到本地。
  2. **查阅/解析文件内容**：优先使用 `rclone cat gdrive:<path>` 直接在内存/标准输出中查看文件正文，实现零磁盘占用。
  3. **必须拉取到本地编辑时**：只**精确下载目标文件或最小颗粒度子目录**（如 `rclone copyto gdrive:<path> <local_path>`），严禁拉取根目录。
  4. **默认排除重媒体**：任何拉取操作必须默认规避 `media/**` 等大体积视频目录。

### 规则 2：多轮任务本地沉浸，终态或用户主动要求时再同步 (Lazy & Deferred Sync)
- **原因**：本地多轮任务中，代码或技术方案可能会经历反复修改与调试，频繁在中间轮次上传草稿会浪费 API 配额，并污染云端版本历史。
- **准则**：
  1. **任务进行中**：在本地工作区（`$WORKSPACE_ROOT/gdrive/`）尽情迭代、创建、重构与校验，**不向云端发起同步**。
  2. **何时触发同步**：
     - **触发条件 A（用户显式要求）**：用户在对话中明确要求“同步到网盘”、“备份上去”、“推送到云端”；
     - **触发条件 B（任务整体交付）**：当前大型多轮迭代彻底完成交付时，向用户确认或由任务流程驱动精确归档。

### 规则 3：精准单文件/子目录推送代替全局镜像 (Precise Incremental Push)
- **准则**：
  - 推送时**只推送本次任务改动或新增的文件**（使用 `rclone copyto <local_file> gdrive:<remote_file>`），严禁对整个网盘根目录做盲目的全量全量扫描。

---

## 2. 常用操作命令 (Command Reference)

配置约定：
- **Remote 标识**: `gdrive:`
- **本地工作区映射路径**: `$WORKSPACE_ROOT/gdrive` (或 `~/workspace/gdrive`)
- **配置文件**: `~/.config/rclone/rclone.conf`

### 1. 零磁盘占用的在线查阅 (Preferred for Inspection)
```bash
# 在线列出目录结构（不下载任何文件）
rclone lsf gdrive:docs/
rclone lsf gdrive:docs/architecture/

# 在线搜索特定文件
rclone ls gdrive: --include "*.md"

# 直接在终端/内存中阅读远端文件正文（完全不占用本地磁盘）
rclone cat gdrive:docs/architecture/ai-agents/coding-agent-project-memory-design.md
```

### 2. 精确按需拉取 (Selective Pull)
```bash
# 只拉取某单个指定文件到本地
rclone copyto gdrive:docs/topics/golang/effective-go.md "$WORKSPACE_ROOT/gdrive/docs/topics/golang/effective-go.md"

# 只拉取某个具体的技术专题子目录（排除媒体）
rclone sync gdrive:docs/topics/clickhouse "$WORKSPACE_ROOT/gdrive/docs/topics/clickhouse" --exclude "media/**"
```

### 3. 任务交付时的精准推送 (Precise Push)
```bash
# 精确上传本地新建或修改的单个文件到云端
rclone copyto "$WORKSPACE_ROOT/gdrive/docs/architecture/new-spec.md" gdrive:docs/architecture/new-spec.md

# 精确增量上传指定子目录（不触碰其他无关目录）
rclone copy "$WORKSPACE_ROOT/gdrive/docs/architecture/ai-agents" gdrive:docs/architecture/ai-agents
```

### 4. 辅助脚本（推荐）
```bash
# 查看本地与云端存储占用情况
./scripts/sync_gdrive.sh status

# 在线查看远端文件
./scripts/sync_gdrive.sh cat docs/architecture/new-spec.md

# 精确拉取或推送
./scripts/sync_gdrive.sh pull docs/topics/golang/effective-go.md
./scripts/sync_gdrive.sh push docs/topics/golang/effective-go.md
```
