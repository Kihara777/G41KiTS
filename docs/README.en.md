# G41KiTS

[中文](../README.md) | [English](README.en.md) | [日本語](README.ja.md)

Modular self-hosted Docker Compose stack — Metro/WP8.1 homepage, Redis config API, multi-language i18n, KITS module system.

## Deploy

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
./g41.sh kits add -y all
```

## Infrastructure

| Module | Description | Docs |
|--------|-------------|------|
| nginx | TLS 1.3 / HTTP/3 gateway | [docs/en/nginx.md](en/nginx.md) |
| redis | Redis store + Node.js API bridge | [docs/en/redis.md](en/redis.md) |
| acme | SSL management via acme.sh | [docs/en/acme.md](en/acme.md) |
| autoheal | Auto-restart unhealthy containers | [docs/en/autoheal.md](en/autoheal.md) |
| dsock | Docker API security proxy | [docs/en/dsock.md](en/dsock.md) |
| home | Site core data + i18n | [docs/en/home.md](en/home.md) |

## Site Services

| Module | Description | Docs |
|--------|-------------|------|
| aria2 | Download manager + WebUI + WebDAV | [docs/en/aria2.md](en/aria2.md) |
| blc | Bilibili live chat + AI translation | [docs/en/blc.md](en/blc.md) |
| bt | BitTorrent client + WebUI + WebDAV | [docs/en/bt.md](en/bt.md) |
| dns | AdGuard recursive DNS (DoT/DoH/DoQ) | [docs/en/dns.md](en/dns.md) |
| hako | Web file manager + WebDAV | [docs/en/hako.md](en/hako.md) |
| hexo | Personal blog engine | [docs/en/hexo.md](en/hexo.md) |
| hy2 | Hysteria2 proxy (port share) | [docs/en/hy2.md](en/hy2.md) |
| tracker | Lightweight HTTPS BT tracker | [docs/en/tracker.md](en/tracker.md) |

## Proxy & Mirror

| Module | Description | Docs |
|--------|-------------|------|
| tile_gh-proxy | raw.githubusercontent.com proxy | [docs/en/tile_gh-proxy.md](en/tile_gh-proxy.md) |
| tile_nix-cache | NixOS binary cache mirror | [docs/en/tile_nix-cache.md](en/tile_nix-cache.md) |

## Navigation

| Module | Description | Docs |
|--------|-------------|------|
| tile_apps | App list tile | [docs/en/tile_apps.md](en/tile_apps.md) |
| tile_bilibili | Bilibili space tile | [docs/en/tile_bilibili.md](en/tile_bilibili.md) |
| tile_flake | Nix flake repo tile | [docs/en/tile_flake.md](en/tile_flake.md) |
| tile_links | Short links tile | [docs/en/tile_links.md](en/tile_links.md) |
| shortlinks | Dynamic short links | [docs/en/shortlinks.md](en/shortlinks.md) |

## External Links

| Module | Description | Docs |
|--------|-------------|------|
| link_7zip | 7-Zip archiver | [docs/en/link_7zip.md](en/link_7zip.md) |
| link_dotnet | .NET SDK | [docs/en/link_dotnet.md](en/link_dotnet.md) |
| link_dx11 | DirectX 11 Runtime | [docs/en/link_dx11.md](en/link_dx11.md) |
| link_vcredist | VC++ Redist | [docs/en/link_vcredist.md](en/link_vcredist.md) |
| link_vs | Visual Studio IDE | [docs/en/link_vs.md](en/link_vs.md) |
| link_vscode | VS Code editor | [docs/en/link_vscode.md](en/link_vscode.md) |

## Author

- **Kitsunori (キツのり)** — Creator & maintainer
- **Kitsunome (キツのめ)** — Design & dev feat. deepseek-v4-pro (Max)
- **Kitsunome Jr. (キツのめ)** — HW inference infra feat. llama-cpp-rocm

## License

[MIT](../LICENSE)