# KITS Module Specification

[中文](../kits/README.md) | [English](kits-spec.md) | [日本語](../ja/kits-spec.md)

A module is a directory containing an `info.json` manifest and optional service definitions, static files, nginx configs, and translations. All modules live under `kits/<module>/`.

## info.json schema

```json
{
  "name": "Human-readable name",
  "desc": "One-line description",
  "depends": ["module", "names"],
  "compose": "none | hub | file",
  "docker": {"service": "svc", "container": "xx"},
  "provides": { ... },
  "store": { "src": "files to hardlink" },
  "webroot": { "target": "provider", "method": "hardlink" },
  "persist": {"dir": ".xx", "survive": true},
  "local": [{"file": "fname", "to": "fname"}]
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | ✅ | Display name |
| `desc` | string | ✅ | One-line description (shown at bottom of `./g41.sh kits` UI) |
| `depends` | string[] | ✅ | Dependency list. Resolved with **full tree traversal**. Must include at least `core` or `nginx` |
| `compose` | enum | ✅ | `none` / `hub` / `file` (see compose modes below) |
| `docker` | object | required if compose≠none | `service` (compose service name) and `container` (2-letter abbreviation) |
| `provides` | object | required for infra modules | Declares directories and file types exposed to dependents |
| `store` | string/object | required if persistent config | Config files copied or hardlinked from `store/` |
| `webroot` | object | required if web assets | `target` (provides target) and `method` (usually `hardlink`) |
| `persist` | object | required if compose≠none and has persistent state | `dir` (e.g. `.rd`) and optional `survive` flag |
| `local` | object[] | only if deployer-specific files exist | Files hardlinked directly from `.local/` to persist dir |

## Module Types

| Type | compose | Contains | Naming |
|------|---------|----------|--------|
| **service** | `hub` or `file` | `compose.yaml` (+ `Dockerfile` if compose=file) | bare name (`nginx`, `aria2`) |
| **tile** | `none` | `tile.json` + `i18n/` | `tile_` prefix (`tile_apps`, `tile_flake`) |
| **link** | `none` | `link.json` | `link_` prefix (`link_7zip`, `link_vscode`) |
| **app** | `none` | `app.json` | bare name (`blc`, `bt`) |

## compose Modes

| Mode | Meaning | Docker Compose Snippet |
|------|--------|------------------------|
| `none` | No Docker service | No `compose.yaml` |
| `hub` | Pull image from Docker Hub | `image: org/img:v1.2.3` |
| `file` | Build from local Dockerfile | `build: .` (no `image:`) |

## Container Naming

`docker.container` field uses **2-letter abbreviations**:

| Container | Module |
|-----------|--------|
| `gx` | nginx |
| `rd` | redis |
| `ah` | autoheal |
| `ca` | acme |
| `ds` | dsock |
| `lc` | blc |
| `ns` | dns |
| `fb` | hako |
| `hx` | hexo |
| `hq` | hy2 |
| `tr` | bt |
| `ad` | aria2 |
| `wt` | tracker |
| `ra` | redis API (runs as part of redis compose) |

## Directory Structure

```
kits/<module>/
├── info.json          # Manifest (required)
├── compose.yaml       # Docker Compose fragment (compose≠none)
├── Dockerfile         # Build file (compose=file)
├── tile.json          # Homepage tile entry
├── app.json           # App list entry
├── link.json          # Short link entry
├── site/              # Nginx config fragments
│   ├── zone.conf      # proxy_cache_path / limit_req_zone
│   ├── upstream.conf  # upstream block
│   ├── server.conf    # Full server block (virtual hosts)
│   └── location.conf  # location block
├── i18n/              # Translations (if tile/link)
│   ├── ja.json
│   ├── zh.json
│   └── en.json
├── store/             # Config files (hardlinked to persist dir)
├── webroot/           # Web assets (hardlinked to provider target)
├── data/              # Static data files (loaded into Redis)
└── .local/            # Deployment-specific files (gitignored)
    ├── site/          # Hidden nginx config copy
    ├── webroot/       # Private web assets
    └── <config>       # Runtime config files (hy2's hysteria.yaml, etc.)
```

## `.local/` Deployment Pattern

Deployers may have files that must exist on the server but **never be committed**. `.local/` solves this:

| `.local/` Path | Install Target | Purpose |
|----------------|---------------|---------|
| `.local/site/*.conf` | `.gx/conf.d/` | Private nginx config |
| `.local/webroot/*` | `.wr/` | Private web assets |
| `.local/<config>` | persist dir | Runtime config with credentials |

## provides System

Infra modules declare `provides` objects describing directories and file types they accept. Resolved recursively through the full dependency tree. No paths are hardcoded.

## site Load Order

Nginx config fragments are loaded by numeric filename prefix:

| File | Load Stage | Purpose |
|------|-----------|---------|
| `zones/*.conf` | http block | `proxy_cache_path`, `limit_req_zone` |
| `upstreams/*.conf` | http block | `upstream` definitions |
| `locations/*.conf` | server block | `location` blocks |
| `servers/*.conf` | end of http | Full virtual host `server` blocks |

## Health Checks

Health checks declared in `compose.yaml` follow this priority:

| Priority | Pattern | When |
|----------|---------|------|
| 1 | `wget -q -O /dev/null http://127.0.0.1:<port>/` | HTTP services |
| 2 | `nc -zw1 127.0.0.1 <port>` | TCP-only services |
| 3 | `kill -0 1` | Go services with no TCP endpoint |

## i18n

3 languages: **JA, ZH, EN**. Tile and link labels are translation keys. Global i18n provided by `home` module.