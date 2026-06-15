# G41KiTS

[中文](../README.md) | [English](README.en.md) | [日本語](README.ja.md)

Modular self-hosted Docker Compose stack — Metro/WP8.1 style homepage, Redis-backed config API, multi-language i18n, KITS module system.

## Deploy

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# Edit .env with domain and Cloudflare credentials
./g41.sh kits add -y all
```

## Infrastructure

Core services providing gateway, storage, certs, and site skeleton.

| Module | Description | Docs |
|--------|-------------|------|
| nginx | TLS 1.3 / HTTP/3 gateway, reverse proxy for all backends | [docs/en/nginx.md](en/nginx.md) |
| redis | Redis config store + Node.js HTTP API bridge | [docs/en/redis.md](en/redis.md) |
| acme | SSL cert management (acme.sh + ZeroSSL/Cloudflare DNS) | [docs/en/acme.md](en/acme.md) |
| autoheal | Auto-restart unhealthy Docker containers | [docs/en/autoheal.md](en/autoheal.md) |
| dsock | Docker API secure proxy (replaces direct docker.sock mount) | [docs/en/dsock.md](en/dsock.md) |
| home | Site core data — character messages, themes, status codes, i18n | [docs/en/home.md](en/home.md) |

## Site Services

User-facing functional services exposed through nginx reverse proxy.

| Module | Description | Docs |
|--------|-------------|------|
| aria2 | Parallel download manager with WebUI & WebDAV share | [docs/en/aria2.md](en/aria2.md) |
| blc | Bilibili live chat with AI translation | [docs/en/blc.md](en/blc.md) |
| bt | BitTorrent client with WebUI & WebDAV share | [docs/en/bt.md](en/bt.md) |
| dns | AdGuard recursive DNS (DoT/DoH/DoQ) | [docs/en/dns.md](en/dns.md) |
| hako | Web file manager with public WebDAV share | [docs/en/hako.md](en/hako.md) |
| hexo | Personal blog engine | [docs/en/hexo.md](en/hexo.md) |
| hy2 | Hysteria2 proxy sharing port 443 with nginx | [docs/en/hy2.md](en/hy2.md) |
| tracker | Lightweight HTTPS BitTorrent tracker | [docs/en/tracker.md](en/tracker.md) |

## Proxy & Mirror

Reverse proxy and cache acceleration services.

| Module | Description | Docs |
|--------|-------------|------|
| tile_gh-proxy | raw.githubusercontent.com reverse proxy | [docs/en/tile_gh-proxy.md](en/tile_gh-proxy.md) |
| tile_nix-cache | NixOS binary cache mirror — channels, cache, releases | [docs/en/tile_nix-cache.md](en/tile_nix-cache.md) |

## Navigation & Entry

Homepage tiles, app list, short link system.

| Module | Description | Docs |
|--------|-------------|------|
| tile_apps | App list tile — homepage entry for all services | [docs/en/tile_apps.md](en/tile_apps.md) |
| tile_links | Short link tile via Redis API proxy | [docs/en/tile_links.md](en/tile_links.md) |
| shortlinks | Dynamic short links via Redis API proxy | [docs/en/shortlinks.md](en/shortlinks.md) |

## External Tool Links

Static link tiles on homepage pointing to external downloads (no Docker service).

| Module | Description | Docs |
|--------|-------------|------|
| link_7zip | High-compression file archiver | [docs/en/link_7zip.md](en/link_7zip.md) |
| link_dotnet | Microsoft .NET development framework | [docs/en/link_dotnet.md](en/link_dotnet.md) |
| link_dx11 | Legacy DirectX End-User Runtime | [docs/en/link_dx11.md](en/link_dx11.md) |
| link_vcredist | Visual C++ Redistributable | [docs/en/link_vcredist.md](en/link_vcredist.md) |
| link_vs | Visual Studio Community IDE | [docs/en/link_vs.md](en/link_vs.md) |
| link_vscode | Visual Studio Code editor | [docs/en/link_vscode.md](en/link_vscode.md) |

## Showcase

| Module | Description | Docs |
|--------|-------------|------|
| tile_flake | Personal Nix flake repo — custom packages, overlays, NixOS modules | [docs/en/tile_flake.md](en/tile_flake.md) |
| tile_bilibili | Bilibili profile — VTuber introduction | [docs/en/tile_bilibili.md](en/tile_bilibili.md) |

## Authors

- **狐莉 (Kitsunori)** — creator and maintainer
- **小爪 (Kitsunome)** — design, development feat. deepseek-v4-pro (Max)
- **小小爪 (Kitsunome)** — hardware inference infrastructure feat. llama-cpp-rocm

## License

[MIT](../LICENSE)