# G41KiTS

[中文](../README.md) | [English](README.en.md) | [日本語](README.ja.md)

Modular self-hosted Docker Compose stack — Metro/WP8.1 style homepage, Redis-backed config API, multi-language i18n, KITS module system.

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
| redis | Redis config store + Node.js HTTP API bridge | [docs/en/redis.md](en/redis.md) |
| acme | SSL certificate management | [docs/en/acme.md](en/acme.md) |
| autoheal | Auto-restart unhealthy containers | [docs/en/autoheal.md](en/autoheal.md) |
| dsock | Docker API security proxy | [docs/en/dsock.md](en/dsock.md) |
| home | Site core data — messages, theme, status codes, i18n | [docs/en/home.md](en/home.md) |

## Site Services
| Module | Description | Docs |
|--------|-------------|------|
| aria2 | Download manager with WebUI and WebDAV | [docs/en/aria2.md](en/aria2.md) |
| blc | Bilibili live chat with AI translation | [docs/en/blc.md](en/blc.md) |
| bt | BitTorrent client with WebUI and WebDAV | [docs/en/bt.md](en/bt.md) |
| dns | AdGuard recursive DNS (DoT/DoH/DoQ) | [docs/en/dns.md](en/dns.md) |
| hako | Web file manager with public WebDAV | [docs/en/hako.md](en/hako.md) |
| hexo | Personal blog engine | [docs/en/hexo.md](en/hexo.md) |
| hy2 | Hysteria2 proxy sharing port 443 with nginx | [docs/en/hy2.md](en/hy2.md) |
| tracker | Lightweight HTTPS BitTorrent tracker | [docs/en/tracker.md](en/tracker.md) |

## Proxy & Mirror
| Module | Description | Docs |
|--------|-------------|------|
| gh-proxy | Reverse proxy for raw.githubusercontent.com | [docs/en/gh-proxy.md](en/gh-proxy.md) |
| nix-cache | NixOS binary cache mirror | [docs/en/nix-cache.md](en/nix-cache.md) |

## Navigation
| Module | Description | Docs |
|--------|-------------|------|
| apps | Application list tile | [docs/en/apps.md](en/apps.md) |
| links | Short link system | [docs/en/links.md](en/links.md) |
| shortlinks | Dynamic short links | [docs/en/shortlinks.md](en/shortlinks.md) |

## External Tool Links
| Module | Description | Docs |
|--------|-------------|------|
| 7zip | High-compression file archiver | [docs/en/7zip.md](en/7zip.md) |
| dotnet | Microsoft .NET framework | [docs/en/dotnet.md](en/dotnet.md) |
| dx11 | Legacy DirectX Runtime | [docs/en/dx11.md](en/dx11.md) |
| vcredist | Visual C++ Redistributable | [docs/en/vcredist.md](en/vcredist.md) |
| vs | Visual Studio IDE | [docs/en/vs.md](en/vs.md) |
| vscode | Visual Studio Code editor | [docs/en/vscode.md](en/vscode.md) |

## Showcase
| Module | Description | Docs |
|--------|-------------|------|
| flake | Nix flake repository | [docs/en/flake.md](en/flake.md) |

## Spec
| Doc | Description |
|-----|-------------|
| [docs/en/module-spec.md](en/module-spec.md) | KITS module system format reference |

## Author
- **Kitsunori (キツのり)** — Creator and maintainer
- **Kitsunome (キツのめ)** — Design & development
- **Kitsunome Jr. (キツのめ)** — Hardware inference infra

## License
[MIT](../LICENSE)