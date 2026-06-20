# 模块规范

[中文](module-spec.md) | [English](../en/module-spec.md) | [日本語](../ja/module-spec.md)

KITS 模块系统格式定义。

## info.json

```json
{
  "name": "显示名称",
  "desc": "一句话描述",
  "depends": ["模块", "名称"],
  "compose": "none | hub | file",
  "docker": {"service": "svc", "container": "xx"},
  "provides": {...},
  "store": {"src": "文件"},
  "webroot": {"target": "provider", "method": "hardlink"},
  "persist": {"dir": ".xx", "survive": true},
  "local": [{"file": "fname", "to": "fname"}]
}
```

### 字段

| 字段 | 必需 | 说明 |
|------|------|------|
| `name` | ✅ | 显示名称 |
| `desc` | ✅ | 一句话描述 |
| `depends` | ✅ | 依赖模块（完整树遍历） |
| `compose` | ✅ | `none` / `hub` / `file` |
| `docker` | compose≠none | `service`（compose 服务名）+ `container`（2 字母） |
| `provides` | 基础设施模块 | 公开的目录与文件类型 |
| `store` | 有持久化配置 | hardlink 到持久化目录的配置 |
| `webroot` | 有 web 资源 | provider 目标目录 |
| `persist` | 有持久化状态 | 持久化目录 + `survive` 标志 |
| `local` | 有部署专属文件 | 从 `.local/` hardlink 的文件 |

## 模块类型

| 类型 | compose | 内容 | 命名 |
|------|---------|------|------|
| service | `hub` / `file` | `compose.yaml` | 裸名称 |
| tile | `none` | `tile.json` + `i18n/` | `tile_` 前缀 |
| link | `none` | `link.json` | `link_` 前缀 |
| app | `none` | `app.json` | 裸名称 |

## compose 模式

| 模式 | 含义 |
|------|------|
| `none` | 无 Docker 服务 |
| `hub` | Docker Hub 镜像（`image: org/img`） |
| `file` | 本地 Dockerfile 构建（`build: .`） |

## 目录结构

```
kits/<module>/
├── info.json          # 清单（必需）
├── compose.yaml       # compose≠none
├── Dockerfile         # compose=file
├── tile.json          # 磁贴条目
├── app.json           # 应用条目
├── link.json          # 短链接条目
├── site/              # nginx 配置
├── i18n/              # ja/zh/en.json
├── store/             # 持久化配置
├── webroot/           # web 资源
├── data/              # 静态数据
└── .local/            # 部署专属（gitignored）
```

## .local/ 部署模式

| `.local/` 路径 | 安装目标 | 用途 |
|----------------|---------|------|
| `.local/site/*.conf` | `.gx/conf.d/` | 私有 nginx 配置 |
| `.local/webroot/*` | `.wr/` | 私有 web 资源 |
| `.local/<config>` | persist 目录 | 运行时配置 |

## provides 系统

基础设施模块声明 `provides` 对象，递归解析至完整依赖树。路径从不硬编码。

## site 加载顺序

| 文件 | 加载位置 | 用途 |
|------|---------|------|
| `zones/*.conf` | http 块 | proxy_cache_path |
| `upstreams/*.conf` | http 块 | upstream 定义 |
| `locations/*.conf` | server 块 | location 块 |
| `servers/*.conf` | http 块末尾 | 虚拟主机 server 块 |

## 健康检查

| 优先级 | 模式 | 适用 |
|--------|------|------|
| 1 | `wget http://127.0.0.1:<port>/` | HTTP 服务 |
| 2 | `nc -zw1 127.0.0.1 <port>` | TCP 服务 |
| 3 | `kill -0 1` | 无 TCP 端点的 Go 服务 |

## i18n

3 种语言：JA、ZH、EN。磁贴和链接的标签定义为翻译键。全局 i18n 由 `home` 模块提供。