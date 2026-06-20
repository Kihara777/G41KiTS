# KITS Module Specification

[中文](../zh/kits-spec.md) | [English](kits-spec.md) | [日本語](../ja/kits-spec.md)

Defines the G41KiTS module system conventions, `info.json` field schema, and directory layout.

## info.json Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | ✅ | Display name |
| `desc` | string | ✅ | Description |
| `depends` | string[] | ✅ | Dependency chain, full tree resolution |
| `compose` | enum | ✅ | `none` / `hub` / `file` |
| `docker` | object | compose≠none | `service` name and `container` (2-letter) |
| `provides` | object | infra modules | Directories and file types offered to dependents |
| `store` | object | persistent config | Files hardlinked from `store/` |
| `webroot` | object | web assets | `target` provider and `method` (`hardlink`) |
| `persist` | object | runtime state | `dir` and optional `survive` flag |
| `local` | object[] | deployment files | Hardlinks from `.local/` to persist dir |

## Module Types

| Type | compose | Files | Naming |
|------|---------|-------|--------|
| service | `hub`/`file` | compose.yaml (+Dockerfile) | bare name |
| tile | `none` | tile.json + i18n/ | `tile_` prefix |
| link | `none` | link.json | `link_` prefix |
| app | `none` | app.json | bare name |

## compose Modes

| Mode | Meaning | Fragment |
|------|---------|----------|
| `none` | No Docker service | No compose.yaml |
| `hub` | Pull from Docker Hub | `image: org/img` |
| `file` | Build from Dockerfile | `build: .` |

## Container Naming

`docker.container` uses 2-letter abbreviations:

| Container | Module |
|-----------|--------|
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

## Directory Layout

```
kits/<module>/
├── info.json          # Manifest (required)
├── compose.yaml       # Docker Compose fragment (compose≠none)
├── Dockerfile         # Build (compose=file)
├── tile.json          # Homepage tile
├── app.json           # App list entry
├── link.json          # Short link
├── site/              # Nginx config fragments
│   ├── zone.conf      # proxy_cache_path
│   ├── upstream.conf  # upstream block
│   ├── server.conf    # Full server block
│   └── location.conf  # location block
├── i18n/              # Translations (ja/zh/en)
├── store/             # Config files
├── webroot/           # Web assets
├── data/              # Static data
└── .local/            # Deployment files (gitignored)
```

## .local/ Deployment Pattern

| .local/ Path | Install Target | Use |
|-------------|---------------|-----|
| `.local/site/*.conf` | `.gx/conf.d/` | Private nginx config |
| `.local/webroot/*` | `.wr/` | Private web assets |
| `.local/<config>` | persist dir | Runtime config |

## site Load Order

| File | Stage | Use |
|------|-------|-----|
| `zones/*.conf` | http block | cache/limit definitions |
| `upstreams/*.conf` | http block | upstream definitions |
| `locations/*.conf` | server block | location blocks |
| `servers/*.conf` | http block | virtual host server blocks |

## Health Checks

| Priority | Pattern | When |
|----------|---------|------|
| 1 | `wget http://127.0.0.1:<port>/` | HTTP services |
| 2 | `nc -zw1 127.0.0.1 <port>` | TCP services |
| 3 | `kill -0 1` | No TCP endpoint |

Never use `kill -0 1` for Node.js services.

## Image Versions

- `FROM alpine` — never `FROM alpine:latest`
- `FROM node:alpine` — never `FROM node:lts-alpine`
- No floating tags in compose `image:`
- `ADD --checksum=sha256:` for remote URLs
- `npm install -g <pkg>@<version>` for npm packages

## i18n

3 languages: JA / ZH / EN. Tile and link labels use translation keys. Global i18n provided by `home` module. API endpoints: `/data/i18n_ja|zh|en`.
