# G41KiTS

[中文](../README.md) | [English](README.en.md) | [日本語](README.ja.md)

Modular self-hosted Docker Compose stack — Metro/WP8.1 style homepage, Redis-backed config API, multi-language i18n, KITS module system.

## Deploy

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# Edit .env with your domain and Cloudflare credentials
./g41.sh kits add -y all
```

### Local Init

`./g41.sh init` supports injecting deployer-specific host config via `.local/`, avoiding committing VPS details to the repo.

**Directory mode** (recommended):
```bash
mkdir -p .local
cat <<'EOF' > .local/install.sh
do_init_local() {
  hostnamectl set-hostname myserver
  timedatectl set-timezone Asia/Tokyo
  # UFW, netplan, crontab, etc.
}
EOF
```

**File mode** (legacy):
```bash
cat <<'EOF' > .local.sh
do_init_local() {
  hostnamectl set-hostname myserver
}
EOF
```

Both modes are optional. If neither exists, `init` skips host setup, only installing Docker and deploying containers.

## Infrastructure

Core services providing gateway, storage, certs, and site skeleton.

| Module | Description | Docs |
|--------|-------------|------|
| nginx | TLS 1.3 / HTTP/3 gateway, reverse proxy to all backends | [docs/en/nginx.md](en/nginx.md) |
| redis | Redis config store + Node.js HTTP API bridge | [docs/en/redis.md](en/redis.md) |
| acme | SSL certificate management (acme.sh + ZeroSSL/Cloudflare DNS) | [docs/en/acme.md](en/acme.md) |
| autoheal | Auto-restart unhealthy Docker containers | [docs/en/autoheal.md](en/autoheal.md) |
| dsock | Docker API security proxy (replaces direct docker.sock mounts) | [docs/en/dsock.md](en/dsock.md) |
| home | Site core data — character messages, theme colors, status codes, i18n | [docs/en/home.md](en/home.md) |

## Site Services

User-facing services exposed through nginx reverse proxy.

| Module | Description | Docs |
|--------|-------------|------|
| aria2 | Parallel download manager with WebUI and WebDAV share | [docs/en/aria2.md](en/aria2.md) |
| blc | Bilibili live chat with AI translation | [docs/en/blc.md](en/blc.md) |
| bt | BitTorrent client with WebUI and WebDAV share | [docs/en/bt.md](en/bt.md) |
| dns | AdGuard recursive DNS with DoT/DoH/DoQ | [docs/en/dns.md](en/dns.md) |
| hako | Web file manager with public WebDAV share | [docs/en/hako.md](en/hako.md) |
| hexo | Personal blog engine | [docs/en/hexo.md](en/hexo.md) |
| hy2 | Hysteria2 proxy sharing port 443 with nginx | [docs/en/hy2.md](en/hy2.md) |
| tracker | Lightweight HTTPS BitTorrent tracker | [docs/en/tracker.md](en/tracker.md) |
| attic | Self-hosted Nix binary cache server (atticd) | [docs/en/attic.md](en/attic.md) |

## Proxy & Mirror

Reverse proxy and cache acceleration services.

| Module | Description | Docs |
|--------|-------------|------|
| gh-proxy | Reverse proxy for raw.githubusercontent.com | [docs/en/tile_gh-proxy.md](en/tile_gh-proxy.md) |
| nix-cache | NixOS binary cache mirror — channels, cache, releases | [docs/en/tile_nix-cache.md](en/tile_nix-cache.md) |

## Navigation

Homepage tiles, app list, short link system.

| Module | Description | Docs |
|--------|-------------|------|
| apps | Application list tile — homepage entry for all services | [docs/en/tile_apps.md](en/tile_apps.md) |
| links | Short link system proxied through Redis API | [docs/en/tile_links.md](en/tile_links.md) |
| shortlinks | Dynamic short links proxied through Redis API | [docs/en/shortlinks.md](en/shortlinks.md) |

## External Tool Links

Static link tiles on the homepage pointing to external downloads (no Docker services).

| Module | Description | Docs |
|--------|-------------|------|
| 7zip | File archiver with high compression ratio | [docs/en/link_7zip.md](en/link_7zip.md) |
| dotnet | Microsoft .NET development framework | [docs/en/link_dotnet.md](en/link_dotnet.md) |
| dx11 | Legacy DirectX End-User Runtime | [docs/en/link_dx11.md](en/link_dx11.md) |
| vcredist | Visual C++ Redistributable | [docs/en/link_vcredist.md](en/link_vcredist.md) |
| vs | Visual Studio Community IDE | [docs/en/link_vs.md](en/link_vs.md) |
| vscode | Visual Studio Code editor | [docs/en/link_vscode.md](en/link_vscode.md) |

## Showcase

| Module | Description | Docs |
|--------|-------------|------|
| flake | Personal Nix flake repository — custom packages, overlays, NixOS modules | [docs/en/tile_flake.md](en/tile_flake.md) |
| bilibili | Bilibili space — virtual streamer introduction | [docs/en/tile_bilibili.md](en/tile_bilibili.md) |
| attic | Attic Nix binary cache usage guide | [docs/en/tile_attic.md](en/tile_attic.md) |

## Spec

| Description | Doc |
|-------------|-----|
| KITS module system full definition | [kits/README.md](../kits/README.md) |
| Third-party assets notice | [NOTICE.md](NOTICE.en.md) |
| Maintenance log | [MAINTENANCE.md](MAINTENANCE.en.md) |
| Agent guide — architecture, module system, development workflow | [AGENTS.md](../AGENTS.md) |

## Author

- **Kitsunori (キツのり)** — Creator and maintainer
- **Kitsunome (キツのめ)** — Design & development feat. deepseek-v4-pro (Max)


## License

[MIT](../LICENSE)