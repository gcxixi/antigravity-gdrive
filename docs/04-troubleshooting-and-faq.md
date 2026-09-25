# 常见问题、排错指南与最佳实践 (FAQ & Troubleshooting)

---

## 1. 凭据与安全问题

### Q1: OAuth Token 是否会过期？需要经常重新授权吗？
**答：不会频繁过期。**  
通过本方案生成的凭据中包含 `refresh_token`：
- `access_token` 的寿命通常为 1 小时；
- 每次 `rclone` 访问 Google Drive 时，如果检测到 `access_token` 即将过期，会自动在后台静默使用 `refresh_token` 向 Google 服务器刷新并换取新的访问令牌，这一过程对用户和 Agent 都是完全透明的；
- 只有当你在 Google 账号的安全管理页面中主动吊销了授权，或者密码被重置时，才需要重新走一遍授权流程。

### Q2: 凭证文件存放安全吗？
**答：非常安全。**  
- 凭证保存在本地的 `~/.config/rclone/rclone.conf` 文件中。
- 建议将该文件的文件系统权限收敛至仅当前用户可读写：
  ```bash
  chmod 600 ~/.config/rclone/rclone.conf
  ```
- **严禁**将包含 Token 的 `rclone.conf` 提交到公开或团队共享的代码仓库中（仓库根目录已配置 `.gitignore` 进行阻断）。

---

## 2. 网络与代理相关

### Q3: 运行 `curl` 或 `rclone` 时出现 SSL 证书错误 (Error 60)
**现象**：
```text
curl: (60) SSL certificate problem: unable to get local issuer certificate
```
**原因**：环境内配置了企业中间人代理（Corporate MITM Proxy），或者系统未正确信任根证书证书链。  
**解法**：
1. 临时跳过证书检查（仅用于验证链路）：`curl -k ...`
2. 或者在终端中配置标准系统根证书路径：
   ```bash
   export SSL_CERT_FILE=/etc/ssl/cert.pem
   export CURL_CA_BUNDLE=/etc/ssl/cert.pem
   ```
3. 如需通过本地代理访问 Google API，可在终端或脚本前设置代理变量：
   ```bash
   export HTTP_PROXY="http://127.0.0.1:7890"
   export HTTPS_PROXY="http://127.0.0.1:7890"
   ```

---

## 3. Google 云端文档处理 (Google Docs / Sheets)

### Q4: 为什么下载下来的 Google Docs 变成了 `.docx`，表格变成了 `.xlsx`？
**原因**：Google Docs、Google Sheets、Google Slides 是保存在 Google 内部服务器上的在线富文本数据，在云端并不是单纯的文件。  
**机制**：`rclone` 会根据默认规则自动将其导出为开放标准格式：
- Google Docs $\rightarrow$ `.docx`
- Google Sheets $\rightarrow$ `.xlsx`
- Google Slides $\rightarrow$ `.pptx`
- Google Drawings $\rightarrow$ `.png`

如果你更希望将 Google Docs 默认导出为 Markdown 或纯文本以供 AI 深度解析，可以在 `rclone.conf` 中追加导出格式偏好：
```ini
[gdrive]
type = drive
scope = drive
export_formats = md,docx,pdf
```

---

## 4. 双向冲突与同步策略选择

### Q5: `rclone sync` 与 `rclone copy` 究竟有什么区别？
- **`rclone copy <src> <dst>`（安全推荐）**：
  仅把源目录（`<src>`）中新增或修改的文件复制到目标目录（`<dst>`）。如果目标目录中有源目录不存在的文件，**绝不删除**。非常适合将本地撰写的文档增量推送上云。
- **`rclone sync <src> <dst>`（严格镜像）**：
  强制让目标目录完全变为源目录的镜像。如果目标目录中有文件在源目录中不存在，**会被直接删除**。适合从云端单向全量镜像更新到本地。

### Q6: 是否支持类似 Dropbox 的实时双向冲突自动合并（Bisync）？
`rclone` 官方提供了实验性的双向同步子命令：
```bash
rclone bisync gdrive: ~/workspace/gdrive --resync
```
在正式自动化前，建议优先使用有明确方向的主动式 `pull` 和 `push` 操作，以避免产生冲突版本标记文件。
