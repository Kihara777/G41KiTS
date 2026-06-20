# 维护记录

[中文](MAINTENANCE.md) | [English](docs/MAINTENANCE.en.md) | [日本語](docs/MAINTENANCE.ja.md)

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