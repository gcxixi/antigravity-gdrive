# Antigravity 智能体技能（Skill）深度集成

通过将 Google Drive 能力封装为 Google Antigravity 的标准 **Skill**，AI 助手不再只是被动响应，而是能自主理解用户的跨端协作意图，实现全自动的文档读取、修改、保存与云端同步。

---

## 1. Antigravity Skill 机制简介

在 Antigravity 中，Skill 是一套遵循开放规范的指令与上下文集合，通常由一个 `SKILL.md` 文件及相关脚本组成：
- **存储路径**：
  - 全局技能：`~/.gemini/config/skills/<skill-name>/SKILL.md`
  - 仓库工作区技能：`.agents/skills/<skill-name>/SKILL.md`
- **渐进式披露（Progressive Disclosure）**：
  - 默认情况下，Skill 不会占用模型宝贵的系统提示词上下文窗口，系统仅向模型注入 Skill 的名称（Name）与简短描述（Description）。
  - 当对话内容命中了触发词或意图时，Antigravity 才会按需挂载该 Skill 的完整操作指南。

---

## 2. 技能定义解析 (`SKILL.md`)

```yaml
---
name: google-drive
description: Manage and synchronize files between local workspace and Google Drive using rclone. Use when the user wants to list, search, read, download, upload, or synchronize files/folders with Google Drive (gdrive). 中文触发词包括“同步网盘”“拉取云盘”“上传到Google Drive”“下载网盘文件”“查看网盘”“Google Drive同步”。
---
```

### 关键指令设计：
1. **明确约定远端名称与本地目录**：
   - 远端标识约定为 `gdrive:`。
   - 本地统一落地在 `$WORKSPACE_ROOT/gdrive`（或工程子目录），保证文件组织结构清晰。
2. **区分拉取（Pull）与推送（Push）的安全性**：
   - 上传时推荐使用 `rclone copy` 而非 `rclone sync`，防止本地误删导致云端数据意外丢失。
   - 云端镜像更新时采用 `rclone sync`，确保本地文件与云端保持最新一致。
3. **支持轻量级单文件直读**：
   - 提供 `rclone cat gdrive:<path>` 操作，当用户只想快速查看远端某个单文档内容时，无需先全量下载几十兆的目录。

---

## 3. 典型智能体使用范式与 Prompt 示例

打通之后，用户可以使用完全自然的语言与 Antigravity 交互：

### 场景 1：需求检索与分析
> **用户输入**：“*帮我看下 Google Drive 里最近更新的架构设计文档，提取关于状态机的核心逻辑并进行总结。*”  
> **Agent 内部流转**：
> 1. 触发 `google-drive` Skill；
> 2. 自动检查本地 `gdrive/` 目录；如果文件未同步，自动执行 `rclone sync gdrive: gdrive/`；
> 3. 使用 `view_file` 原生工具快速读取 Markdown 文档并提炼总结。

### 场景 2：代码与文档生成自动归档
> **用户输入**：“*将我们刚才推演生成的分布式缓存高可用架构方案整理成文档，直接存放到 Google Drive 的‘架构设计’目录下，并同步上云。*”  
> **Agent 内部流转**：
> 1. 调用 `write_to_file` 将结构化文档保存至 `gdrive/架构设计/cache-ha.md`；
> 2. 调用终端执行 `rclone copy gdrive/架构设计 gdrive:架构设计`；
> 3. 汇报完成，并给出云端与本地路径索引。

### 场景 3：定时任务与自动化同步
结合 Antigravity 的 `/schedule` 斜杠指令，可以轻松配置每天或每小时的自动双向同步：
```text
/schedule 每 30 分钟同步一次本地工作区与 Google Drive 的变更
```
Agent 将在后台挂载轻量 Cron 任务执行 `sync_gdrive.sh pull` 与 `push`。
