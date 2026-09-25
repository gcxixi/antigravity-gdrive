# Antigravity 智能体技能（Skill）深度集成

通过将 Google Drive 能力封装为 Google Antigravity 的标准 **Skill**，AI 助手不再只是被动响应，而是能自主理解用户的跨端协作意图，实现全自动的文档检索、修改、保存与云端按需同步。

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

## 2. 关键设计原则：按需加载与延迟同步 (Lazy & Selective Sync)

在早期的设计中，很多集成方案倾向于使用“启动时全量同步（Full Sync）”。但在实际生产与长线使用中，这种模式存在两大严重缺陷：
1. **本地磁盘膨胀失控**：随着云端积累大量的音视频切片、大体积 PDF 电子书与历史备份，全量镜像下载会迅速占满开发机磁盘。
2. **多轮对话下的中间态污染**：本地多轮任务中，代码或技术方案往往会经历数轮推演与草稿修改。如果在每轮会话中都急于向云端推送，不仅浪费 API 配额，而且会用大量的半成品草稿污染云端历史版本。

因此，本项目制定了三大核心准则：

### 准则 1：零磁盘占用在线查阅（Zero-Disk Inspection）
- **列目录/搜索**：直接在线读取远端元数据（`rclone lsf`），不落本地盘。
- **阅读正文**：使用 `rclone cat gdrive:<path>` 直接在内存/标准输出中查看文件正文，无需先下载几十兆的目录结构。

### 准则 2：本地沉浸式多轮编辑，延迟至终态同步（Deferred Sync）
- **开发与推演中**：本地工作区尽情读写、重构与校验，AI 助手不主动向云端推送中间草稿。
- **触发同步条件**：
  - **显式触发**：用户在对话中明确要求“同步到网盘”、“推送到云端”；
  - **任务完成**：多轮交付流程全部结束，成果定稿后向用户确认归档。

### 准则 3：精准单文件与子目录差量同步（Selective Incremental Push/Pull）
- 拒绝全量根目录 `rclone sync`。
- 拉取或推送仅针对本次修改涉及的具体文件（`rclone copyto`）或细分子目录，且默认过滤 `media/**` 重媒体。

---

## 3. 典型智能体使用范式与 Prompt 示例

打通之后，用户可以使用完全自然的语言与 Antigravity 交互：

### 场景 1：零磁盘占用的技术方案在线检索与解析
> **用户输入**：“*帮我检索 Google Drive 里关于架构设计的文档，总结分布式状态机的核心设计。*”  
> **Agent 内部流转**：
> 1. 触发 `google-drive` Skill；
> 2. 执行 `rclone lsf gdrive:docs/architecture/` 在线发现相关文档；
> 3. 调用 `rclone cat gdrive:docs/architecture/distributed-systems/state-machine.md` 在线读取正文；
> 4. 提炼核心架构要点向用户汇报，全程**本地磁盘零占用**。

### 场景 2：多轮复杂推演与终态精准归档
> **用户输入**：“*根据我们讨论的架构，在本地编写一份 ClickHouse 分布式表高可用选型方案，并进行多轮完善。*”  
> **Agent 内部流转**：
> 1. **第 1~N 轮**：在本地 `gdrive/docs/topics/clickhouse/ha-selection.md` 中进行深度的推演、排版与推敲，中间轮次不触碰云端；
> 2. **交付轮次**：用户输入：“*方案确认无误，同步到 Google Drive 上吧。*”
> 3. Agent 仅针对该文件执行精准推送：
>    ```bash
>    ./scripts/sync_gdrive.sh push docs/topics/clickhouse/ha-selection.md
>    ```
> 4. 汇报同步成功，版本干净且安全。

### 场景 3：定时状态核查
结合 Antigravity 的 `/schedule` 斜杠指令，可以配置轻量的容量检查：
```text
/schedule 每天早晨 10 点检查 Google Drive 云端与本地工作区的存储占用差异
```
Agent 执行 `./scripts/sync_gdrive.sh status` 并向用户输出容量报告。
