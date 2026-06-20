# G41KiTS

[中文](README.md) | [English](docs/README.en.md) | [日本語](docs/README.ja.md)

模块化自托管 Docker Compose 技术栈 — Metro/WP8.1 风格首页、Redis 配置 API、多语言 i18n、KITS 模块系统。

## 部署

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# 编辑 .env 填入域名与 Cloudflare 凭证
./g41.sh kits add -y all
```

## 基础设施

核心服务，提供网关、存储、证书与站点骨架。

| 模块 | 说明 | 文档 |
|------|------|------|
| nginx | TLS 1.3 / HTTP/3 网关 | [docs/zh/nginx.md](docs/zh/nginx.md) |
| redis | Redis 存储 + API 桥接 | [docs/zh/redis.md](docs/zh/redis.md) |
| acme | SSL 证书管理 | [docs/zh/acme.md](docs/zh/acme.md) |
| autoheal | 自动重启异常容器 | [docs/zh/autoheal.md](docs/zh/autoheal.md) |
| dsock | Docker API 安全代理 | [docs/zh/dsock.md](docs/zh/dsock.md) |
| home | 站点数据与 i18n | [docs/zh/home.md](docs/zh/home.md) |

## 站点服务

面向用户的功能服务，通过 nginx 反向代理对外暴露。

| 模块 | 说明 | 文档 |
|------|------|------|
| aria2 | 下载管理器 + WebDAV | [docs/zh/aria2.md](docs/zh/aria2.md) |
| blc | Bilibili 直播聊天 | [docs/zh/blc.md](docs/zh/blc.md) |
| bt | BitTorrent 客户端 | [docs/zh/bt.md](docs/zh/bt.md) |
| dns | AdGuard 递归 DNS | [docs/zh/dns.md](docs/zh/dns.md) |
| hako | Web 文件管理器 | [docs/zh/hako.md](docs/zh/hako.md) |
| hexo | 个人博客引擎 | [docs/zh/hexo.md](docs/zh/hexo.md) |
| hy2 | Hysteria2 代理 | [docs/zh/hy2.md](docs/zh/hy2.md) |
| tracker | BT Tracker | [docs/zh/tracker.md](docs/zh/tracker.md) |

## 代理与镜像

反向代理与缓存加速。

| 模块 | 说明 | 文档 |
|------|------|------|
| gh-proxy | GitHub 文件反向代理 | [docs/zh/tile_gh-proxy.md](docs/zh/tile_gh-proxy.md) |
| nix-cache | NixOS 缓存镜像 | [docs/zh/tile_nix-cache.md](docs/zh/tile_nix-cache.md) |

## 导航与入口

首页磁贴与短链接系统。

| 模块 | 说明 | 文档 |
|------|------|------|
| apps | 应用列表磁贴 | [docs/zh/tile_apps.md](docs/zh/tile_apps.md) |
| links | 短链接磁贴 | [docs/zh/tile_links.md](docs/zh/tile_links.md) |
| shortlinks | 动态短链接 | [docs/zh/shortlinks.md](docs/zh/shortlinks.md) |

## 外部工具链接

首页上的静态下载链接磁贴（无 Docker 服务）。

| 模块 | 说明 | 文档 |
|------|------|------|
| 7zip | 高压缩比文件归档 | [docs/zh/link_7zip.md](docs/zh/link_7zip.md) |
| dotnet | .NET 开发框架 | [docs/zh/link_dotnet.md](docs/zh/link_dotnet.md) |
| dx11 | DirectX 运行时 | [docs/zh/link_dx11.md](docs/zh/link_dx11.md) |
| vcredist | VC++ Redist | [docs/zh/link_vcredist.md](docs/zh/link_vcredist.md) |
| vs | Visual Studio IDE | [docs/zh/link_vs.md](docs/zh/link_vs.md) |
| vscode | VS Code 编辑器 | [docs/zh/link_vscode.md](docs/zh/link_vscode.md) |

## 展示

| 模块 | 说明 | 文档 |
|------|------|------|
| flake | Nix flake 仓库 | [docs/zh/tile_flake.md](docs/zh/tile_flake.md) |
| bilibili | Bilibili 主页 | [docs/zh/tile_bilibili.md](docs/zh/tile_bilibili.md) |

## 规范

| 文档 | 说明 |
|------|------|
| [docs/zh/module-spec.md](docs/zh/module-spec.md) | KITS 模块系统格式定义 |

## 作者

- **狐莉 (キツのり)** — 创建和维护
- **小爪 (キツのめ)** — 设计、开发 feat. deepseek-v4-pro (Max)
- **小小爪 (キツのめ)** — 硬件推理基础设施 feat. llama-cpp-rocm

## 许可

[MIT](LICENSE)