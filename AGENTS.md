# G41KiTS — 代理开发指南

## 初次启动

每个新 session 启动时，首先执行完整项目审计并汇报发现。审计范围包括：所有模块状态（kits/）、部署环境（compose.yaml）、依赖完整性、持久化数据完整性，以及未提交变更。

## 目标

构建和维护 G41KiTS —— 模块化自托管 Docker Compose 技术栈，包含 Metro/WP8.1 风格首页、Redis 配置 API、多语言 i18n、KITS 模块系统。

## 总览

单 VPS 自托管 Docker Compose 技术栈，提供：
- **首页** — Metro/WP8.1 风格的磁贴与状态码页面
- **博客** — Hexo 个人博客
- **直播聊天** — Bilibili 直播弹幕
- DNS-over-HTTPS/TLS/QUIC 代理、BT Tracker、WebDAV、Nix 缓存镜像
- Hysteria2 代理与 nginx 共用 443 端口

## 基础设施

```
互联网 → [nginx:80/443] → 静态文件、反向代理到各后端
       → [hy2:443/udp] → Hysteria2 代理（与 nginx 端口复用）

后端：服务/容器名在各模块的 info.json 的 `docker` 字段中声明。
全部容器使用 2 字母缩写（例如 nginx→gx、redis→rd、autoheal→ah）。
```

## 目录结构

```
G41KiTS/
├── compose.yaml              # 模块化 include 文件 → 服务
├── g41.sh                    # 引导脚本 + 模块管理
├── .env                       # 密钥 + G41_CORE、G41_PREFIX、G41_KITS
├── .env.example              # 新部署模板
├── .gitignore                 # .env + .*/（保留 .git/）
│
├── kits/                     # 模块化服务（每个模块一个目录）
│   └── <模块名>/
│       ├── info.json         # 元数据、依赖、provides、compose、docker、local
│       ├── compose.yaml      # Docker Compose 片段
│       ├── Dockerfile        # 容器构建（仅 compose=file）
│       ├── tile.json         # 首页磁贴
│       ├── app.json          # 应用列表条目
│       ├── link.json         # 短链接条目
│       ├── site/             # Nginx 配置片段（zone/upstream/server/location.conf）
│       ├── i18n/             # 翻译（ja/zh/en.json）
│       ├── store/            # 持久化配置文件
│       ├── webroot/          # Web 资源
│       ├── data/             # 静态数据文件
│       └── .local/           # 部署专属文件（gitignored）
│
├── .ca/     (证书)            ├── .hq/    (hy2)       ├── .ns/    (dns)
├── .gx/     (nginx)          ├── .fb/    (文件管理)    ├── .lc/    (直播聊天)
├── .tr/     (bt)             ├── .ad/    (aria2)     ├── .hx/    (hexo)
├── .wr/     (webroot)        └── .rd/    (redis+API)
│
└── README.md                  # 项目概览
```

持久化目录（`.ca` `.gx` `.rd` `.wr` 等）通过 `.gitignore` 中的 `.*/` 排除。源码文件位于 `kits/` 下。

## 核心原则

### 硬链接，非符号链接
所有模块安装均使用**硬链接**（`ln -f`）。文件与对应的 kit 源码共享同一 inode。Docker 容器**无需**挂载 `/kits`。

### KITS 模块系统
每个服务、磁贴、站点组件都是 `kits/` 下的一个模块。每个模块在 `info.json` 中声明其完整的文件集：
- `depends` — 依赖链（通过完整树递归解析）
- `compose` — `none` / `hub` / `file`（Docker Hub 镜像 vs 本地构建）
- `docker` — 服务 → 容器名映射
- `provides` — 为依赖方提供的目录 + 文件类型（含 `file`、`ext`、`layout`、`check` 子字段）
- `store` — 持久化配置文件
- `webroot` — Web 资源（基础路径来自 nginx provides）
- `persist` — 运行时数据目录（含有 `local` 的模块必需；survive 标志可在周期之间保留）
- `local` — 部署专属文件的安装（合并自原 `local.json`）

### 模块命名约定

- **`tile_*`** — `compose: "none"` 纯磁贴模块（例如 `tile_apps`、`tile_gh-proxy`）
- **`link_*`** — `compose: "none"` 纯短链接模块（例如 `link_7zip`、`link_vscode`）
- **裸名** — Docker 服务模块（例如 `nginx`、`redis`、`aria2`、`hy2`）

前缀是模块目录名的一部分，必须与 `tile.json` / `link.json` 的 `id` 字段匹配。

### compose 模式

| 模式 | 说明 | 示例 |
|------|------|------|
| `none` | 无 Docker 服务；仅 tile/link/data | tile_*、link_*、home |
| `hub` | 从 Docker Hub 拉取镜像 | blc、dns、hako、hy2、dsock |
| `file` | 本地 Dockerfile 构建 | redis、bt、aria2、acme、autoheal、hexo、tracker |

`compose: "file"` 模块需要 `Dockerfile` + `compose.yaml`（含 `build: .` 而非 `image:`）。

### `.local/` 部署模式

模块可附带 gitignored 的 `.local/` 目录，用于部署者专属、**不可提交**的文件：

| `.local/` 路径 | 安装目标 | 示例 |
|----------------|----------|------|
| `.local/site/*.conf` | `.gx/conf.d/`（nginx） | hy2 私有 location |
| `.local/webroot/*` | `.wr/`（Web 资源） | hy2 订阅文件 |
| `.local/<config>` | 持久化目录 | `hysteria.yaml`、`settings.json` |

`g41.sh` 将 `.local/` 文件视同其公开副本——相同硬链接 + provides 解析。唯一区别是 `.gitignore` 排除。

### 健康检查标准

`compose.yaml` 中声明的健康检查必须遵循以下优先级：

| 优先级 | 模式 | 使用场景 |
|--------|------|----------|
| 1 | `wget -q -O /dev/null http://127.0.0.1:<port>/` | HTTP 服务（blc、hako、redis API、tracker） |
| 2 | `nc -zw1 127.0.0.1 <port>` | 纯 TCP 服务（dns、aria2、bt） |
| 3 | `kill -0 1` | 无 TCP 端点的 Go 服务（最后手段） |

禁止对 Node.js 服务使用 `kill -0 1`（事件循环可能在进程不崩溃的情况下阻塞）。

### 镜像版本锁定

所有镜像和基础镜像必须固定为**精确版本标签**：

- `FROM alpine:3.23.4` — 不允许 `FROM alpine` 或 `FROM alpine:latest`
- `FROM node:24.16.0-alpine` — 不允许 `FROM node:lts-alpine`
- compose.yaml 中的 `image: adguard/dnsproxy:v0.81.3` — 不允许浮动标签
- Dockerfile 中的远程 URL 下载需使用 `ADD --checksum=sha256:...`
- 全局 npm 包需使用 `npm install -g <pkg>@<version>`

### `provides` 系统
模块声明它们提供的目录以及接受的文件类型。安装器通过完整依赖树递归解析所有 `provides`。路径不硬编码——每个目标目录在安装时通过 `kit_resolve` 从 `info.json` 中发现。

基础设施提供者：nginx（站点配置 + webroot）、redis（数据根目录）、home（磁贴 + i18n）、apps（应用条目）、links（短链接）。每个提供者声明 `accepts`、`file`、`ext` 以及可选的 `layout`。

### 类型驱动安装
安装器从依赖链中收集所有 `accepts` 类型并分类处理：
- `tile`/`app`/`link` → 单个 JSON 文件硬链接
- `i18n` → 按文件硬链接到子目录
- `site` → 基于布局的安装，含前缀命名

Store、data、webroot、persist 和 local 文件分别处理。

### 前缀系统
站点配置使用数字前缀控制 nginx 加载顺序。提供者模块声明自己的前缀；消费者模块使用 `.env` 中的 `G41_PREFIX`（默认 `999`）。

### i18n
3 种语言：JA、ZH、EN。通过 API 提供（`/data/i18n_ja|zh|en`）。每个模块有自己的 `i18n/` 目录。首页模块提供全局 i18n。

### 配置即数据，非代码
所有站点配置以 JSON 形式存放在持久化数据目录中，启动时加载到 Redis 的 `data:` 前缀下。前端通过 API 从 Redis 的 `/data/` 端点获取。

### 禁止在 Docker 守护进程中设置 `iptables: false`
这会破坏 Docker 桥接网络并导致 DNS 解析失效。

### 保留机制
带有 `persist: {"dir": "<dir>", "survive": true}` 的模块在卸载/重装周期中保留其数据。卸载时目录移动至 `kits/<mod>/`，重装时恢复。

## 模块生命周期

### 安装
```bash
./g41.sh kits add <module> [-y] [-C]     # 自动安装依赖，执行验证
./g41.sh kits add -y all                  # 安装全部
```
- 安装前执行 `kits verify`（L1-L4 验证）
- `-C` 绕过"已安装"检查
- `all` 安装 `kits/` 下的每个模块

### 卸载
```bash
./g41.sh kits del <module> [-y] [-C]     # -C 用于核心模块
./g41.sh kits del -C -y all              # 级联卸载（叶子优先）
```
- 核心依赖模块不带 `-C` 时阻止卸载
- `all` 按反向依赖顺序卸载
- 持久化目录：保留（移动到 kits/）或清除（删除）

### 验证
```bash
./g41.sh kits verify <module>    # L1 自身 → L2 依赖 → L3 provides → L4 .local
./g41.sh kits check <module>     # 发现已安装的构件
```

## 开发工作流

### Git 仓库

```bash
cd G41KiTS
git init
git remote add origin https://github.com/<user>/G41KiTS.git
git add -A
git commit -m "Initial commit"
git push -u origin main
```

`.gitignore` 排除 `.env`、`.*/`（持久化目录）、`.local.sh` 和备份文件。全部源码位于 `kits/` 下，可安全提交。

### 推送变更（rsync — 强制安全协议）

> **⚠️ 每次 rsync 前必须执行 dry-run，确认变更范围后再执行。**

```bash
# 1. Dry-run：预览所有变更
rsync -avn --delete \
  --exclude='.git/' --exclude='.*/' --exclude='*.bak' \
  --exclude='G41KiTS_*.tar.gz' --exclude='.deepseek/' \
  G41KiTS/ $HOST:$PATH/

# 2. 检查输出
#   - 没有 "deleting" 行 → 安全
#   - 有 "deleting" 行 → 确认这些文件确实应该删除
#   - 持久化目录 (.*/) 被排除，不会被触碰

# 3. 确认安全后，完整备份
ssh $HOST "cp -a $PATH $PATH.bak"

# 4. 执行同步
rsync -av --delete \
  --exclude='.git/' --exclude='.*/' --exclude='*.bak' \
  --exclude='G41KiTS_*.tar.gz' --exclude='.deepseek/' \
  G41KiTS/ $HOST:$PATH/
```

### 重建特定模块
```bash
ssh $HOST "cd $PATH && ./g41.sh kits add -C -y <module> && docker compose up -d <service>"
```

### 配置数据变更后
清除数据加载标志并重启 API：
```bash
ssh $HOST "docker compose exec redis redis-cli -a \$REDIS_PASSWORD DEL data:loaded && docker compose restart api"
```
等待约 60 秒完成配置重新导入（加载期间 API 会 crash-restart 2-3 次）。

### 归档包
通过 `./g41.sh kits pack` 构建，使用以下标志：
- `-A`（agents）— AGENTS.md + skills/
- `-D`（docs）— docs/ + README.md
- `-L`（local）— .env + 所有 .local/ 目录
- `-S`（store）— 所有持久化目录（完整备份）

标志组合后按字母序命名：`-SAL` → `G41KiTS_ALS.tar.gz`。

```bash
./g41.sh kits pack          # 标准：严格遵循 .gitignore
./g41.sh kits pack -L       # 额外添加 .env + .local/
./g41.sh kits pack -SAL     # 完整备份
./g41.sh kits pack -AD      # agents + docs
```

## 常见问题

### 磁贴不渲染
1. JS 是否加载：`curl -sk -o /dev/null -w "%{http_code}" https://<domain>/js/G41.js`
2. 数据端点：`curl -sk https://<domain>/data/tiles | jq empty`

### nginx 崩溃循环
```bash
docker compose logs nginx | grep emerg
docker compose exec nginx nginx -t
```

### API 返回 HTML 而非 JSON
```bash
docker compose exec redis redis-cli DEL data:loaded && docker compose restart api
```

### Redis 权限错误
```bash
chown -R 999:999 .rd/ && docker compose restart redis
```

### API 返回 HTML 而非 JSON → 404
如果 Redis 重启时 `.env` 中没有 `REDIS_PASSWORD`：
```bash
# 确保 .env 中有密码
grep REDIS_PASSWORD .env || echo 'REDIS_PASSWORD=<password>' >> .env
# 带密码重建 Redis
docker compose up -d --force-recreate redis
# 清除加载标志并重启 API
docker compose exec redis redis-cli -a $REDIS_PASSWORD DEL data:loaded
docker compose restart api
```
### docker.sock 安全
直接挂载 docker.sock 已被 `dsock` 模块取代：
- acme → `DOCKER_HOST=tcp://ds:2375`
- autoheal → `DOCKER_SOCK=tcp://ds:2375`
- dsock 本身以**只读**方式（`:ro`）挂载 docker.sock，并限制 API 端点

### upstream 主机未找到
确保所有引用的后端容器正在运行。nginx 在任何 upstream 主机名不可解析时会启动失败。