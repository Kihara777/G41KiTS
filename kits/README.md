# KITS Module Specification

[中文](README.md) | [English](../docs/en/kits-spec.md) | [日本語](../docs/ja/kits-spec.md)

单个模块是一个目录，包含一个 `info.json` 清单以及可选的服务定义、静态文件、nginx 配置和翻译。所有模块都位于 `kits/<module>/` 下。

## info.json schema

```json
{
  "name": "Human-readable name",
  "desc": "One-line description",
  "depends": ["module", "names"],
  "compose": "none | hub | file",
  "docker": {"service": "svc", "container": "xx"},
  "provides": { ... },
  "store": { "src": "files to hardlink" },
  "webroot": { "target": "provider", "method": "hardlink" },
  "persist": {"dir": ".xx", "survive": true},
  "local": [{"file": "fname", "to": "fname"}]
}
```

### 字段参考

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `name` | string | ✅ | 显示名称 |
| `desc` | string | ✅ | 一句话描述（显示在 `./g41.sh kits` 界面底部） |
| `depends` | string[] | ✅ | 依赖模块列表。解析时**完整树遍历**。至少包含 `core` 或 `nginx` |
| `compose` | enum | ✅ | `none` / `hub` / `file`（见下方 compose 模式） |
| `docker` | object | compose≠none 时必需 | `service`（compose 服务名）和 `container`（2 字母缩写） |
| `provides` | object | 基础设施模块必需 | 声明向依赖方公开的目录和文件类型（见 provides 系统） |
| `store` | string/object | 如有持久化配置则必需 | 从 `store/` 复制或 hardlink 的配置文件 |
| `webroot` | object | 如有 web 资源则必需 | `target`（provides 目标）和 `method`（通常为 `hardlink`） |
| `persist` | object | compose≠none 且有持久化状态时必需 | `dir`（如 `.rd`）和可选的 `survive` 标志 |
| `local` | object[] | 仅当有部署专属文件时需要 | 直接从 `.local/` hardlink 到 persist 目录的文件 |

## 模块类型

| 类型 | compose | 包含 | 命名 |
|------|---------|------|------|
| **service** | `hub` 或 `file` | `compose.yaml`（+ `Dockerfile` 若 compose=file） | 裸名称（`nginx`、`aria2`） |
| **tile** | `none` | `tile.json` + `i18n/` | `tile_` 前缀（`tile_apps`、`tile_flake`） |
| **link** | `none` | `link.json` | `link_` 前缀（`link_7zip`、`link_vscode`） |
| **app** | `none` | `app.json` | 裸名称（`blc`、`bt`） |

`tile_` 和 `link_` 前缀同时存在于**目录名**和 `tile.json` / `link.json` 的 `id` 字段中。

## compose 模式

| 模式 | 含义 | Docker Compose 片段 |
|------|------|---------------------|
| `none` | 无 Docker 服务 | 无 `compose.yaml` |
| `hub` | 从 Docker Hub 拉取镜像 | `image: org/img:v1.2.3` |
| `file` | 从 `Dockerfile` 本地构建 | `build: .`（无 `image:`） |

镜像标签必须固定为具体版本（无 `:latest`、`lts-alpine` 等）。

## 容器命名

`docker.container` 字段使用 **2 字母缩写**：

| 容器 | 模块 |
|------|------|
| `gx` | nginx |
| `rd` | redis |
| `ah` | autoheal |
| `ca` | acme |
| `ds` | dsock |
| `lc` | blc |
| `ns` | dns |
| `fb` | hako |
| `hx` | hexo |
| `hq` | hy2 |
| `tr` | bt |
| `ad` | aria2 |
| `wt` | tracker |
| `ra` | redis API（作为 redis compose 的一部分运行） |

## 目录结构

```
kits/<module>/
├── info.json          # 清单（必需）
├── compose.yaml       # Docker Compose 片段（compose≠none）
├── Dockerfile         # 构建文件（compose=file）
├── tile.json          # 首页磁贴条目
├── app.json           # 应用列表条目
├── link.json          # 短链接条目
├── site/              # nginx 配置片段
│   ├── zone.conf      # proxy_cache_path / limit_req_zone 定义
│   ├── upstream.conf  # upstream 块
│   ├── server.conf    # 完整 server 块（用于虚拟主机）
│   └── location.conf  # location 块
├── i18n/              # 翻译（若提供 tile/link）
│   ├── ja.json
│   ├── zh.json
│   └── en.json
├── store/             # 配置文件（hardlink 到持久化目录）
├── webroot/           # web 资源（hardlink 到 provider 目标）
├── data/              # 静态数据文件（加载至 Redis）
└── .local/            # 部署专属文件（gitignored）
    ├── site/          # nginx 配置的隐藏副本
    ├── webroot/       # 私有 web 资源
    └── <config>       # 运行时配置文件（hy2 的 hysteria.yaml 等）
```

## `.local/` 部署模式

部署者可能有一些必须在服务器上存在但**永远不会提交**到仓库的文件。`.local/` 通过镜像公开的目录结构解决此问题：

| `.local/` 路径 | 安装目标 | 用途 |
|----------------|---------|------|
| `.local/site/*.conf` | `.gx/conf.d/` | 私有 nginx 配置（如 hy2 的秘密 location） |
| `.local/webroot/*` | `.wr/` | 私有 web 资源（如 hy2 订阅文件） |
| `.local/<config>` | persist 目录 | 包含凭证的运行时配置 |

`g41.sh` 将 `.local/` 文件视为与其公开副本相同的身份——相同的 hardlink、相同的 provides 解析。唯一区别是 `.gitignore` 排除。

## provides 系统

基础设施模块声明 `provides` 对象，以声明它们向依赖方公开的目录及接受的文件类型：

```json
{
  "provides": {
    "<dir>": {
      "file": "<path>",
      "accepts": ["type1", "type2"],
      "ext": [".json", ".conf"],
      "layout": "<name pattern>",
      "check": "<script>"
    }
  }
}
```

安装器通过完整依赖树递归解析所有 `provides`。路径从不硬编码——目标目录在安装时通过 `kit_resolve` 发现。

## site 加载顺序

nginx 配置片段按文件名的数字前缀加载：

| 文件 | 加载阶段 | 用途 |
|------|---------|------|
| `zones/*.conf` | http 块 | `proxy_cache_path`、`limit_req_zone` |
| `upstreams/*.conf` | http 块 | `upstream` 定义 |
| `locations/*.conf` | server 块 | `location` 块 |
| `servers/*.conf` | http 块末尾 | 完整的虚拟主机 `server` 块 |

前缀规则：
- 基础设施模块定义自己的前缀（如 nginx 的 `000`）
- 消费者模块使用 `G41_PREFIX` 环境变量（默认 `999`）

## 健康检查

`compose.yaml` 中声明的健康检查必须遵循以下优先级：

| 优先级 | 模式 | 适用场景 |
|--------|------|---------|
| 1 | `wget -q -O /dev/null http://127.0.0.1:<port>/` | HTTP 服务（blc、hako、redis API、tracker） |
| 2 | `nc -zw1 127.0.0.1 <port>` | 仅 TCP 的服务（dns、aria2、bt） |
| 3 | `kill -0 1` | 无 TCP 端点的 Go 服务（hy2 主机网络） |

## i18n 约定

所有用户可见文本支持 3 种语言：**JA（日文）、ZH（中文）、EN（英文）**。

磁贴和链接标签定义为翻译键，位于各模块的 `i18n/` 目录中。全局 i18n 由 `home` 模块提供。API 在 `/data/i18n_ja|zh|en` 端点提供合并后的翻译。

## 镜像版本锁定

所有镜像和基础镜像必须固定为**精确版本标签**：

- `FROM alpine:3.23.4` — 不允许 `FROM alpine` 或 `FROM alpine:latest`
- `FROM node:24.16.0-alpine` — 不允许 `FROM node:lts-alpine`
- `image: adguard/dnsproxy:v0.81.3`（compose.yaml 中）— 不允许浮动标签
- `ADD --checksum=sha256:...` 用于 Dockerfile 中的远程 URL 下载
- `npm install -g <包名>@<版本>` 用于全局 npm 包