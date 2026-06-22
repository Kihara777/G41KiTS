# 维护记录

## 2026-06-22T23:50:00+09:00

**摘要**：attic — 自托管 Nix 二进制缓存模块 + tile_attic 首页磁贴；AGENTS.md 新增访问控制、初次启动审计、云端部署规则

| 提交 | 说明 |
|------|------|
| `054a758` | feat(attic): add self-hosted Nix binary cache module |
| `af6b661` | feat(tile_attic): add dedicated tile for attic binary cache |
| `08ad54f` | docs(AGENTS): add access control, cloud deployment info, reorder sections |
| `7b2ec2b` | docs(AGENTS): move cloud deployment section after new-session audit |

[中文](MAINTENANCE.md) | [English](docs/MAINTENANCE.en.md) | [日本語](docs/MAINTENANCE.ja.md)

## 2026-06-22

- 新增 attic 模块：自托管 Nix 二进制缓存服务器（atticd）
- 新增 tile_attic 磁贴：Attic 使用指南（三语 i18n + 密钥生成说明）
- tile_attic 全量本地化：代码块转为 i18n 键（attic_pre1/attic_pre2/attic_note）
- 新增 attic / tile_attic 三语文档（zh/en/ja，共 6 篇）
- README 三语同步：站点服务 + 展示表添加 attic 条目
- 新增 tile_mail / tile_homete / tile_kihara777 磁贴（GitHub 项目与主页展示，三语 i18n）
- 新增 Redis API 热重载端点 POST /admin/reload（RELOAD_SECRET 认证，零停机）
- 新增 g41.sh kits reload 命令：一键刷新磁贴/i18n/链接数据（容器内 Node.js HTTP 请求）
- 修复 tile_attic 硬编码中文链接文本 → i18n 键 attic_link
- 修复新磁贴标题格式：统一为小写无 emoji（attic/homete/kihara777/mail）
- home 模块合并 tile_homete：直接提供 homete 磁贴，移除冗余模块
- Redis API 磁贴列表按 id 字母序排列
- home 三语文档更新：补充 homete 磁贴与模块提供内容详情
- 修复 g41.sh kits reload 容器内 wget 不可用问题
- 修复 rsync 后硬链接断裂 → 追加 g41.sh kits add -C 重建链接

## 2026-06-20

- 开源推送 `main` 分支至 GitHub
- 三语文档上线（27 模块 + 模块规范）：zh:29 / en:29 / ja:29
- AGENTS.md 完整重写为中文（292 行），涵盖架构、开发工作流、常见问题
- README 补充 `.local/` 本地初始化章节
- 三语维护记录（MAINTENANCE.md / en / ja）
- 三语 NOTICE.md（第三方资产声明）

## 2026-06-18

- 移除全部 Docker 版本锁定：Dockerfile FROM 行、compose image 标签、npm 包版本、ADD --checksum 均改为浮动版本
- 修复 `g41.sh kits pack` 因 `skills/` 目录缺失导致的 `set -e` 退出
- 全栈容器强制重建，14/14 healthy

## 2026-06-16

- 两轮全面安全审计（4 子代理并行）：发现 24 项问题，全部修复或接受
- g41.sh 安全加固：`set -o pipefail`、`sed -i` 改为原子写入（`sed > tmp && mv`）、compose include 改用行号精确插入
- autoheal 崩溃修复：从 willfarrell/autoheal Hub 镜像改为自定义 Dockerfile（基于 master 版 entrypoint，支持 TCP socket）
- CSP 安全头分层配置：主站严格 + aria2/nix-cache/gh-proxy 代理路径宽松
- tiles.js tracker embed 防 XSS：`innerHTML` → `createElement` + `textContent`
- G41.js fetch 添加 5s 超时（`AbortSignal.timeout(5000)`）
- server.js 所有 `catch(e){}` 静默异常添加 `console.error` 日志
- 开源可行性审计通过：硬编码域名、密钥全部清零，敏感文件全部 `.gitignore` 排除
- tile_bilibili 模块新建：Bilibili 虚拟主播磁贴（三语 i18n）
- tile_flake 磁贴填充：13 个 NixKits 软件包/补丁/技能条目
- tile_gh-proxy i18n 硬编码 `g41.moe` → `__HOST__` 占位符
- g41.sh TUI 交互界面改为 ANSI 转义序列增量渲染（消除闪烁）
- GitHub 仓库创建及 topics 设置

## 2026-06-11 ~ 2026-06-12

- 数据与功能分离（A/B/C 层）：compose 变量化、nginx site 配置泛化、server.js 环境变量注入
- 安全加固：dsock 新模块（Docker API 代理）、BT 供应链锁定、Redis 密码认证
- 健康检查标准化（HTTP 端点 > 端口探测 > kill -0 1）
- 模块重命名：纯磁贴 → `tile_*` 前缀（5 个），纯短链接 → `link_*` 前缀（6 个）
- 前端修复：错误码页面、加载闪烁、404 生效
- hy2 模块私密化：`.local/` 隐藏订阅文件和 nginx 配置
- g41.sh 扩展：自动发现 `.local/site/` 和 `.local/webroot/`
- server.js 重构：原始 TCP socket → `redis` npm 包持久连接 + pipeline 批量写入

## 2026-06-10

- 初始审计：compose.yaml、g41.sh、所有 kits/ 模块
- 基础设施搭建：Metro/WP8.1 风格首页、Redis 配置 API、多语言 i18n、KITS 模块系统