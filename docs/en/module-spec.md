# Module Specification

[中文](../zh/module-spec.md) | [English](module-spec.md) | [日本語](../ja/module-spec.md)

KITS module system format reference.

## info.json

```json
{
  "name": "Display name",
  "desc": "One-line description",
  "depends": ["module", "names"],
  "compose": "none | hub | file",
  "docker": {"service": "svc", "container": "xx"},
  "provides": {...},
  "store": {"src": "files"},
  "webroot": {"target": "provider", "method": "hardlink"},
  "persist": {"dir": ".xx", "survive": true},
  "local": [{"file": "fname", "to": "fname"}]
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Display name |
| `desc` | ✅ | One-line description |
| `depends` | ✅ | Dependency chain (full tree traversal) |
| `compose` | ✅ | `none` / `hub` / `file` |
| `docker` | compose≠none | `service` (compose service name) + `container` (2-letter) |
| `provides` | infra modules | Exposed directories and file types |
| `store` | persistent config | Config files hardlinked to persist dir |
| `webroot` | web assets | Provider target directory |
| `persist` | persistent state | Persist directory + `survive` flag |
| `local` | deployment files | Files hardlinked from `.local/` |

## Module Types

| Type | compose | Contains | Naming |
|------|---------|----------|--------|
| service | `hub` / `file` | `compose.yaml` | bare name |
| tile | `none` | `tile.json` + `i18n/` | `tile_` prefix |
| link | `none` | `link.json` | `link_` prefix |
| app | `none` | `app.json` | bare name |

## compose Modes

| Mode | Meaning |
|------|---------|
| `none` | No Docker service |
| `hub` | Docker Hub image (`image: org/img`) |
| `file` | Local Dockerfile build (`build: .`) |

## Directory Structure

```
kits/<module>/
├── info.json          # Manifest (required)
├── compose.yaml       # compose≠none
├── Dockerfile         # compose=file
├── tile.json          # Tile entry
├── app.json           # App entry
├── link.json          # Short link entry
├── site/              # Nginx config
├── i18n/              # ja/zh/en.json
├── store/             # Persistent config
├── webroot/           # Web assets
├── data/              # Static data
└── .local/            # Deployment-only (gitignored)
```

## .local/ Deployment Pattern

| `.local/` Path | Install Target | Purpose |
|----------------|---------------|---------|
| `.local/site/*.conf` | `.gx/conf.d/` | Private nginx config |
| `.local/webroot/*` | `.wr/` | Private web assets |
| `.local/<config>` | persist dir | Runtime config |

## provides System

Infrastructure modules declare `provides` objects, resolved recursively through the full dependency tree. No paths are hardcoded.

## site Load Order

| File | Load Stage | Purpose |
|------|-----------|---------|
| `zones/*.conf` | http block | proxy_cache_path |
| `upstreams/*.conf` | http block | upstream definitions |
| `locations/*.conf` | server block | location blocks |
| `servers/*.conf` | end of http | virtual host server blocks |

## Health Checks

| Priority | Pattern | When |
|----------|---------|------|
| 1 | `wget http://127.0.0.1:<port>/` | HTTP services |
| 2 | `nc -zw1 127.0.0.1 <port>` | TCP services |
| 3 | `kill -0 1` | Go services, no TCP endpoint |

## i18n

3 languages: JA, ZH, EN. Tile and link labels are translation keys. Global i18n provided by `home` module.