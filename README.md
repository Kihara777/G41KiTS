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
| nginx | TLS 1.3 / HTTP/3 网关，反向代理全部后端 | [docs/zh/nginx.md](docs/zh/nginx.md) |
| redis | Redis 配置存储 + Node.js HTTP API 桥接 | [docs/zh/redis.md](docs/zh/redis.md) |
| acme | SSL 证书管理（acme.sh + ZeroSSL/Cloudflare DNS） | [docs/zh/acme.md](docs/zh/acme.md) |
| autoheal | 自动重启不健康的 Docker 容器 | [docs/zh/autoheal.md](docs/zh/autoheal.md) |
| dsock | Docker API 安全代理（替代 docker.sock 直接挂载） | [docs/zh/dsock.md](docs/zh/dsock.md) |
| home | 站点核心数据 — 角色消息、主题色、状态码、i18n | [docs/zh/home.md](docs/zh/home.md) |

## 站点服务

面向用户的功能服务，通过 nginx 反向代理对外暴露。

| 模块 | 说明 | 文档 |
|------|------|------|
| aria2 | 并行下载管理器，含 WebUI 与 WebDAV 共享 | [docs/zh/aria2.md](docs/zh/aria2.md) |
| blc | Bilibili 直播聊天，含 AI 翻译 | [docs/zh/blc.md](docs/zh/blc.md) |
| bt | BitTorrent 客户端，含 WebUI 与 WebDAV 共享 | [docs/zh/bt.md](docs/zh/bt.md) |
| dns | AdGuard 递归 DNS，支持 DoT/DoH/DoQ | [docs/zh/dns.md](docs/zh/dns.md) |
| hako | Web 文件管理器，含公开 WebDAV 共享 | [docs/zh/hako.md](docs/zh/hako.md) |
| hexo | 个人博客引擎 | [docs/zh/hexo.md](docs/zh/hexo.md) |
| hy2 | Hysteria2 代理，与 nginx 共用 443 端口 | [docs/zh/hy2.md](docs/zh/hy2.md) |
| tracker | 轻量 HTTPS BitTorrent Tracker | [docs/zh/tracker.md](docs/zh/tracker.md) |

## 代理与镜像

反向代理与缓存加速服务。

| 模块 | 说明 | 文档 |
|------|------|------|
| tile_gh-proxy | raw.githubusercontent.com 反向代理 | [docs/zh/tile_gh-proxy.md](docs/zh/tile_gh-proxy.md) |
| tile_nix-cache | NixOS 二进制缓存镜像 — channels、cache、releases | [docs/zh/tile_nix-cache.md](docs/zh/tile_nix-cache.md) |

## 导航与入口

首页磁贴、应用列表、短链接系统。

| 模块 | 说明 | 文档 |
|------|------|------|
| tile_apps | 应用列表磁贴 — 全部服务的首页入口 | [docs/zh/tile_apps.md](docs/zh/tile_apps.md) |
| tile_links | 短链接系统，通过 Redis API 代理 | [docs/zh/tile_links.md](docs/zh/tile_links.md) |
| shortlinks | 动态短链接，通过 Redis API 代理 | [docs/zh/shortlinks.md](docs/zh/shortlinks.md) |

## 外部工具链接

首页上指向外部下载的静态链接磁贴（无 Docker 服务）。

| 模块 | 说明 | 文档 |
|------|------|------|
| link_7zip | 高压缩比文件归档工具 | [docs/zh/link_7zip.md](docs/zh/link_7zip.md) |
| link_dotnet | Microsoft .NET 开发框架 | [docs/zh/link_dotnet.md](docs/zh/link_dotnet.md) |
| link_dx11 | 旧版 DirectX 最终用户运行时 | [docs/zh/link_dx11.md](docs/zh/link_dx11.md) |
| link_vcredist | Visual C++ 可再发行组件包 | [docs/zh/link_vcredist.md](docs/zh/link_vcredist.md) |
| link_vs | Visual Studio Community IDE | [docs/zh/link_vs.md](docs/zh/link_vs.md) |
| link_vscode | Visual Studio Code 编辑器 | [docs/zh/link_vscode.md](docs/zh/link_vscode.md) |

## 展示

| 模块 | 说明 | 文档 |
|------|------|------|
| tile_flake | 个人 Nix flake 仓库 — 自定义包、overlay、NixOS 模块 | [docs/zh/tile_flake.md](docs/zh/tile_flake.md) |
| tile_bilibili | Bilibili 个人主页 — 虚拟主播介绍 | [docs/zh/tile_bilibili.md](docs/zh/tile_bilibili.md) |

## 作者

- **狐莉 (キツのり)** — 创建和维护
- **小爪 (キツのめ)** — 设计、开发 feat. deepseek-v4-pro (Max)
- **小小爪 (キツのめ)** — 硬件推理基础设施 feat. llama-cpp-rocm: Qwen3.6-27B-MTP (UD-Q4_K_XL) · Qwen3.6-35B-A3B-MTP (UD-Q4_K_XL) · Qwen3.5-122B-A10B-MTP (UD-Q4_K_XL) · Qwen3-Coder-Next (UD-Q4_K_XL) · MiniMax-M2.7 (UD-Q2_K_XL)

## 许可

[MIT](LICENSE)