# G41KiTS

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md)

A modular self-hosted Docker Compose stack — Metro/WP8.1 style homepage, Redis-backed config API, multi-language i18n, and a KITS module system.

## Deployment

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# Edit .env with your domain and Cloudflare credentials
./g41.sh kits add -y all
```

## Infrastructure

Core services providing gateway, storage, certificates, and site skeleton.

| Module | Description | Docs |
|--------|-------------|------|
| nginx | TLS 1.3 / HTTP/3 gateway, reverse proxy to all backends | [docs/en/nginx.md](docs/en/nginx.md) |
| redis | Redis config store + Node.js HTTP API bridge | [docs/en/redis.md](docs/en/redis.md) |
| acme | SSL certificate management (acme.sh + ZeroSSL/Cloudflare DNS) | [docs/en/acme.md](docs/en/acme.md) |
| autoheal | Auto-restart unhealthy Docker containers | [docs/en/autoheal.md](docs/en/autoheal.md) |
| home | Site core data — character messages, theme colors, status codes, i18n | [docs/en/home.md](docs/en/home.md) |

## Site Services

User-facing services exposed through nginx reverse proxy.

| Module | Description | Docs |
|--------|-------------|------|
| aria2 | Parallel download manager with WebUI and WebDAV share | [docs/en/aria2.md](docs/en/aria2.md) |
| blc | Bilibili live chat with AI translation | [docs/en/blc.md](docs/en/blc.md) |
| bt | BitTorrent client with WebUI and WebDAV share | [docs/en/bt.md](docs/en/bt.md) |
| dns | AdGuard recursive DNS with DoT/DoH/DoQ | [docs/en/dns.md](docs/en/dns.md) |
| hako | Web file manager with public WebDAV share | [docs/en/hako.md](docs/en/hako.md) |
| hexo | Personal blog engine | [docs/en/hexo.md](docs/en/hexo.md) |
| hy2 | Hysteria2 proxy sharing port 443 with nginx | [docs/en/hy2.md](docs/en/hy2.md) |
| tracker | Lightweight HTTPS BitTorrent tracker | [docs/en/tracker.md](docs/en/tracker.md) |

## Proxy & Mirror

Reverse proxy and caching acceleration services.

| Module | Description | Docs |
|--------|-------------|------|
| gh-proxy | Reverse proxy for raw.githubusercontent.com | [docs/en/gh-proxy.md](docs/en/gh-proxy.md) |
| nix-cache | NixOS binary cache mirror — channels, cache, releases | [docs/en/nix-cache.md](docs/en/nix-cache.md) |

## Navigation

Homepage tiles, app lists, and short link system.

| Module | Description | Docs |
|--------|-------------|------|
| apps | Application list tile — homepage entry points to all services | [docs/en/apps.md](docs/en/apps.md) |
| links | Short link system proxied through Redis API | [docs/en/links.md](docs/en/links.md) |
| shortlinks | Dynamic short links proxied through Redis API | [docs/en/shortlinks.md](docs/en/shortlinks.md) |

## External Tool Links

Static link tiles on the homepage pointing to external downloads (no Docker service).

| Module | Description | Docs |
|--------|-------------|------|
| 7zip | File archiver with high compression ratio | [docs/en/7zip.md](docs/en/7zip.md) |
| dotnet | Microsoft .NET development framework | [docs/en/dotnet.md](docs/en/dotnet.md) |
| dx11 | Legacy DirectX End-User Runtime | [docs/en/dx11.md](docs/en/dx11.md) |
| vcredist | Visual C++ Redistributable | [docs/en/vcredist.md](docs/en/vcredist.md) |
| vs | Visual Studio Community IDE | [docs/en/vs.md](docs/en/vs.md) |
| vscode | Visual Studio Code editor | [docs/en/vscode.md](docs/en/vscode.md) |

## Showcase

| Module | Description | Docs |
|--------|-------------|------|
| flake | Personal Nix flake repo — custom packages, overlays, NixOS modules | [docs/en/flake.md](docs/en/flake.md) |

## Skills

Operational guides for AI coding assistants.

| Skill | Description | Docs |
|-------|-------------|------|
| module-system | info.json schema, install mechanisms, conventions, and command reference | [docs/en/skills/module-system.md](docs/en/skills/module-system.md) |
| env-config | .env configuration management | [docs/en/skills/env-config.md](docs/en/skills/env-config.md) |
| deploy-site | Site deployment workflow | [docs/en/skills/deploy-site.md](docs/en/skills/deploy-site.md) |
| init-server | New server initialization | [docs/en/skills/init-server.md](docs/en/skills/init-server.md) |
| health-check | Service health checks | [docs/en/skills/health-check.md](docs/en/skills/health-check.md) |
| diagnose-api | API container diagnostics, tile rendering issues, config data reload | [docs/en/skills/diagnose-api.md](docs/en/skills/diagnose-api.md) |
| fix-nginx | nginx crash loop diagnostics | [docs/en/skills/fix-nginx.md](docs/en/skills/fix-nginx.md) |
| manage-certs | SSL certificate management | [docs/en/skills/manage-certs.md](docs/en/skills/manage-certs.md) |
| add-domain | Add a new domain | [docs/en/skills/add-domain.md](docs/en/skills/add-domain.md) |
| add-content | Add content module (tiles, i18n) | [docs/en/skills/add-content.md](docs/en/skills/add-content.md) |
| add-docker-service | Add Docker service module | [docs/en/skills/add-docker-service.md](docs/en/skills/add-docker-service.md) |
| kits-simulate-install | Simulate install, preview install plan | [docs/en/skills/kits-simulate-install.md](docs/en/skills/kits-simulate-install.md) |
| manage-i18n | Multi-language translation management | [docs/en/skills/manage-i18n.md](docs/en/skills/manage-i18n.md) |
| backup-restore | Backup and restore | [docs/en/skills/backup-restore.md](docs/en/skills/backup-restore.md) |
| archive-packages | Build archive packages | [docs/en/skills/archive-packages.md](docs/en/skills/archive-packages.md) |
| configure-hexo | Hexo blog configuration | [docs/en/skills/configure-hexo.md](docs/en/skills/configure-hexo.md) |
| clean-stale-files | Clean stale files | [docs/en/skills/clean-stale-files.md](docs/en/skills/clean-stale-files.md) |
| migrate-config | Configuration migration | [docs/en/skills/migrate-config.md](docs/en/skills/migrate-config.md) |
| rename-dir | Directory rename | [docs/en/skills/rename-dir.md](docs/en/skills/rename-dir.md) |
| force-recreate-container | Force recreate container | [docs/en/skills/force-recreate-container.md](docs/en/skills/force-recreate-container.md) |
| troubleshoot-dns | DNS troubleshooting | [docs/en/skills/troubleshoot-dns.md](docs/en/skills/troubleshoot-dns.md) |
| update-chars | Update character messages | [docs/en/skills/update-chars.md](docs/en/skills/update-chars.md) |
| add-mihomo-rule | Add Mihomo rule | [docs/en/skills/add-mihomo-rule.md](docs/en/skills/add-mihomo-rule.md) |

## Authors

- **狐莉 (キツのり)** — Creator and maintainer
- **小爪 (キツのめ)** — Design and development feat. deepseek-v4-pro (Max)
- **小小爪 (キツのめ)** — Hardware inference infrastructure feat. llama-cpp-rocm: Qwen3.6-27B-MTP (UD-Q4_K_XL) · Qwen3.6-35B-A3B-MTP (UD-Q4_K_XL) · Qwen3.5-122B-A10B-MTP (UD-Q4_K_XL) · Qwen3-Coder-Next (UD-Q4_K_XL) · MiniMax-M2.7 (UD-Q2_K_XL)

## License

[MIT](LICENSE)
