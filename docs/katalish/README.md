# G41KiTS

[中文](../../README.md) | [English](../README.en.md) | [日本語](../README.ja.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/README.md)

Modular self-hosted Docker Compose stack — Metro/WP8.1 style homepage, Redis-backed config API, multi-language i18n, KITS ﾓｼﾞｭｰﾙ ｼｽﾃﾑ.

## ﾃﾞｨﾌﾟﾛｲ

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# Edit .env with your domain and Cloudflare credentials
./g41.sh kits add -y all
```

### ﾛｰｶﾙ ｲﾆｯﾄ

`./g41.sh ｲﾆｯﾄ` supports injecting deployer-specific host config via `.ﾛｰｶﾙ/`, avoiding committing VPS details to ｻﾞ repo.

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

Both modes ｱｰ optional. If neither exists, `ｲﾆｯﾄ` skips host setup, ｵﾝﾘｰ installing Docker ｱﾝﾄﾞ deploying containers.

## Infrastructure

Core services providing gateway, storage, certs, ｱﾝﾄﾞ site skeleton.

| ﾓｼﾞｭｰﾙ | Description | Docs |
|--------|-------------|------|
| nginx | TLS 1.3 / HTTP/3 gateway, reverse proxy to ｵｰﾙ backends | [docs/en/nginx.md](en/nginx.md) |
| redis | Redis config store + Node.js HTTP API bridge | [docs/en/redis.md](en/redis.md) |
| acme | SSL certificate management (acme.sh + ZeroSSL/Cloudflare DNS) | [docs/en/acme.md](en/acme.md) |
| autoheal | Auto-restart unhealthy Docker containers | [docs/en/autoheal.md](en/autoheal.md) |
| dsock | Docker API security proxy (replaces direct docker.sock mounts) | [docs/en/dsock.md](en/dsock.md) |
| home | Site core data — character messages, theme colors, status codes, i18n | [docs/en/home.md](en/home.md) |

## Site Services

User-facing services exposed through nginx reverse proxy.

| ﾓｼﾞｭｰﾙ | Description | Docs |
|--------|-------------|------|
| aria2 | Parallel download ﾑｱﾝｱｼﾞｴﾗ ｳｨｽﾞ WebUI ｱﾝﾄﾞ WebDAV share | [docs/en/aria2.md](en/aria2.md) |
| blc | Bilibili live chat ｳｨｽﾞ AI translation | [docs/en/blc.md](en/blc.md) |
| bt | BitTorrent client ｳｨｽﾞ WebUI ｱﾝﾄﾞ WebDAV share | [docs/en/bt.md](en/bt.md) |
| dns | AdGuard recursive DNS ｳｨｽﾞ DoT/DoH/DoQ | [docs/en/dns.md](en/dns.md) |
| hako | Web file ﾑｱﾝｱｼﾞｴﾗ ｳｨｽﾞ public WebDAV share | [docs/en/hako.md](en/hako.md) |
| hexo | Personal blog engine | [docs/en/hexo.md](en/hexo.md) |
| hy2 | Hysteria2 proxy sharing port 443 ｳｨｽﾞ nginx | [docs/en/hy2.md](en/hy2.md) |
| tracker | Lightweight HTTPS BitTorrent tracker | [docs/en/tracker.md](en/tracker.md) |
| attic | Self-hosted Nix binary cache ｻｰﾊﾞｰ (atticd) | [docs/en/attic.md](en/attic.md) |

## Proxy & Mirror

Reverse proxy ｱﾝﾄﾞ cache acceleration services.

| ﾓｼﾞｭｰﾙ | Description | Docs |
|--------|-------------|------|
| gh-proxy | Reverse proxy ﾌｫｱ raw.githubusercontent.com | [docs/en/tile_gh-proxy.md](en/tile_gh-proxy.md) |
| nix-cache | NixOS binary cache mirror — channels, cache, releases | [docs/en/tile_nix-cache.md](en/tile_nix-cache.md) |

## Navigation

Homepage tiles, app list, short link ｼｽﾃﾑ.

| ﾓｼﾞｭｰﾙ | Description | Docs |
|--------|-------------|------|
| apps | Application list tile — homepage entry ﾌｫｱ ｵｰﾙ services | [docs/en/tile_apps.md](en/tile_apps.md) |
| links | Short link ｼｽﾃﾑ proxied through Redis API | [docs/en/tile_links.md](en/tile_links.md) |
| shortlinks | Dynamic short links proxied through Redis API | [docs/en/shortlinks.md](en/shortlinks.md) |

## External Tool Links

Static link tiles on ｻﾞ homepage pointing to external downloads (no Docker services).

| ﾓｼﾞｭｰﾙ | Description | Docs |
|--------|-------------|------|
| 7zip | File archiver ｳｨｽﾞ high compression ratio | [docs/en/link_7zip.md](en/link_7zip.md) |
| dotnet | Microsoft .NET development framework | [docs/en/link_dotnet.md](en/link_dotnet.md) |
| dx11 | Legacy DirectX End-User Runtime | [docs/en/link_dx11.md](en/link_dx11.md) |
| vcredist | Visual C++ Redistributable | [docs/en/link_vcredist.md](en/link_vcredist.md) |
| vs | Visual Studio Community IDE | [docs/en/link_vs.md](en/link_vs.md) |
| vscode | Visual Studio Code editor | [docs/en/link_vscode.md](en/link_vscode.md) |

## Showcase

| ﾓｼﾞｭｰﾙ | Description | Docs |
|--------|-------------|------|
| flake | Personal Nix flake repository — custom packages, overlays, NixOS modules | [docs/en/tile_flake.md](en/tile_flake.md) |
| bilibili | Bilibili space — virtual streamer introduction | [docs/en/tile_bilibili.md](en/tile_bilibili.md) |
| attic | Attic Nix binary cache usage guide | [docs/en/tile_attic.md](en/tile_attic.md) |
| mail | MailKits — Cloudflare Email Workers transparent proxy | [docs/en/tile_mail.md](en/tile_mail.md) |
| kihara777 | GitHub profile — projects, contributions & contact | [docs/en/tile_kihara777.md](en/tile_kihara777.md) |

## Spec

| Description | Doc |
|-------------|-----|
| KITS ﾓｼﾞｭｰﾙ ｼｽﾃﾑ full definition | [kits/README.md](../kits/README.md) |
| Third-party assets notice | [NOTICE.md](NOTICE.en.md) |
| Maintenance log | [MAINTENANCE.md](MAINTENANCE.en.md) |
| Agent guide — architecture, ﾓｼﾞｭｰﾙ ｼｽﾃﾑ, development workflow | [AGENTS.md](../AGENTS.md) |

## Author

- **Kitsunori (キツのり)** — Creator ｱﾝﾄﾞ maintainer
- **Kitsunome (キツのめ)** — Design & development feat. deepseek-v4-pro (Max)


## License

[MIT](../LICENSE)