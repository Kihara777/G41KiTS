# KITS 模块规范
中文 | [English](../en/kits-spec.md) | [日本語](../ja/kits-spec.md) | [ｶﾀﾘｯｼｭ](../katalish/kits-spec.md) | [偽中国語](../pcn/kits-spec.md)

定义 G41KiTS 的模块系统约定、`info.json` 字段 schema 及目录结构。

## info.json 字段

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `name` | string | ✅ | 显示名称 |
| `desc` | string | ✅ | 描述 |
| `depends` | string[] | ✅ | 依赖模块，解析时全树遍历 |
| `compose` | enum | ✅ | `none` / `hub` / `file` |
| `docker` | object | compose≠none | `service`（服务名）和 `container`（2 字母缩写） |
| `provides` | object | 基础设施 | 向依赖方公开的目录和文件类型 |
| `store` | object | 持久化配置 | 从 `store/` hardlink 的文件 |
| `webroot` | object | web 资源 | `target`（目标 provider）和 `method`（`hardlink`） |
| `persist` | object | 持久化状态 | `dir` 和可选 `survive` 标志 |
| `local` | object[] | 部署文件 | 从 `.local/` hardlink 到 persist 目录 |

## 模块类型

| 类型 | compose | 文件 | 命名 |
|------|---------|------|------|
| service | `hub`/`file` | compose.yaml（+Dockerfile） | 裸名称 |
| tile | `none` | tile.json + i18n/ | `tile_` 前缀 |
| link | `none` | link.json | `link_` 前缀 |
| app | `none` | app.json | 裸名称 |

## compose 模式

| 模式 | 含义 | 片段 |
|------|------|------|
| `none` | 无 Docker 服务 | 无 compose.yaml |
| `hub` | Docker Hub 拉取 | `image: org/img` |
| `file` | 本地 Dockerfile 构建 | `build: .` |

## 容器命名

`docker.container` 使用 2 字母缩写：

| 容器 | 模块 |
|------|------|
| gx | nginx |
| rd | redis |
| ah | autoheal |
| ca | acme |
| ds | dsock |
| lc | blc |
| ns | dns |
| fb | hako |
| hx | hexo |
| hq | hy2 |
| tr | bt |
| ad | aria2 |
| wt | tracker |
| ra | redis API |

## 目录结构

```
kits/<module>/
├── info.json          # 清单（必需）
├── compose.yaml       # Docker Compose 片段（compose≠none）
├── Dockerfile         # 构建（compose=file）
├── tile.json          # 首页磁贴
├── app.json           # 应用列表
├── link.json          # 短链接
├── site/              # nginx 配置片段
│   ├── zone.conf      # proxy_cache_path
│   ├── upstream.conf  # upstream 块
│   ├── server.conf    # 完整 server 块
│   └── location.conf  # location 块
├── i18n/              # 三语翻译（ja/zh/en）
├── store/             # 配置文件
├── webroot/           # web 资源
├── data/              # 静态数据
└── .local/            # 部署专属文件（gitignored）
```

## .local/ 部署模式

| .local/ 路径 | 安装目标 | 用途 |
|-------------|---------|------|
| `.local/site/*.conf` | `.gx/conf.d/` | 私有 nginx 配置 |
| `.local/webroot/*` | `.wr/` | 私有 web 资源 |
| `.local/<config>` | persist 目录 | 运行时配置 |

## site 加载顺序

| 文件 | 阶段 | 用途 |
|------|------|------|
| `zones/*.conf` | http 块 | cache/limit 定义 |
| `upstreams/*.conf` | http 块 | upstream 定义 |
| `locations/*.conf` | server 块 | location 块 |
| `servers/*.conf` | http 块 | 虚拟主机 server 块 |

## 健康检查

| 优先级 | 模式 | 场景 |
|--------|------|------|
| 1 | `wget http://127.0.0.1:<port>/` | HTTP 服务 |
| 2 | `nc -zw1 127.0.0.1 <port>` | TCP 服务 |
| 3 | `kill -0 1` | 无 TCP 端点 |

Node.js 服务禁用 `kill -0 1`（事件循环阻塞不崩溃）。

## 镜像版本

- `FROM alpine` → 不允许 `FROM alpine:latest`
- `FROM node:alpine` → 不允许 `FROM node:lts-alpine`
- compose `image:` 不允许浮动标签
- `ADD --checksum=sha256:` 用于远程 URL
- `npm install -g <pkg>@<version>` 用于 npm 包

## i18n

3 种语言：JA / ZH / EN。磁贴和链接标签为翻译键。全局 i18n 由 `home` 模块提供。API 端点：`/data/i18n_ja|zh|en`。
