# G41KiTS — Agent Guide

## Goal

Build and maintain G41KiTS — a modular self-hosted Docker Compose stack with Metro/WP8.1 homepage, Redis-backed config API, multi-language i18n, and a KITS module system for service management.

## Overview

Self-hosted Docker Compose stack on a single VPS, serving:
- **Homepage** — Metro/WP8.1 style tiles, status code pages
- **Blog** — Hexo personal blog
- **Live chat** — Bilibili live chat
- DNS-over-HTTPS/TLS/QUIC proxy, BT tracker, WebDAV, Nix cache mirror
- Hysteria2 proxy sharing port 443 with nginx

## Infrastructure

```
Internet → [nginx:80/443] → static files, reverse proxy to backends
         → [hy2:443/udp] → Hysteria2 proxy (port-reuse with nginx)

Backends: service / container names declared in each module's info.json `docker` field.
All containers use 2-letter abbreviations (e.g., nginx→gx, redis→rd, autoheal→ah).
```

## Directory structure

```
G41KiTS/
├── compose.yaml              # Modular include files → services
├── g41.sh                    # Bootstrap + module management
├── .env                       # Secrets + G41_CORE, G41_PREFIX, G41_KITS
├── .env.example              # Template for new deployments
├── .gitignore                 # .env + .*/ (negate .git/)
│
├── kits/                     # Modular services (one directory per module)
│   └── <module>/
│       ├── info.json         # Metadata, deps, provides, compose, docker, local
│       ├── compose.yaml      # Docker Compose fragment
│       ├── Dockerfile        # Container build (compose=file only)
│       ├── tile.json         # Homepage tile
│       ├── app.json          # Apps list entry
│       ├── link.json         # Short link entry
│       ├── site/             # Nginx config fragments (zone/upstream/server/location.conf)
│       ├── i18n/             # Translations (ja/zh/en.json)
│       ├── store/            # Persistent config files
│       ├── webroot/          # Web assets
│       ├── data/             # Static data files
│       └── .local/           # Deployment files (gitignored)
│
├── .ca/     (certs)          ├── .hq/    (hy2)       ├── .ns/    (dns)
├── .gx/     (nginx)          ├── .fb/    (filebrowser)├── .lc/    (blivechat)
├── .tr/     (bt)             ├── .ad/    (aria2)     ├── .hx/    (hexo)
├── .wr/     (webroot)        └── .rd/    (redis+API)
│
└── README.md                 # Project overview
```

Persistent directories (`.ca` `.gx` `.rd` `.wr` etc.) excluded via `.*/` in `.gitignore`. Source files live in `kits/`.

## Key principles

### Hard links, not symlinks
All module installations use **hard links** (`ln -f`). Files share the same inode with their kit source. Docker containers do NOT need `/kits` mounted.

### KITS module system
Every service, tile, and site component is a module under `kits/`. Each module declares its entire file set in `info.json`:
- `depends` — dependency chain (resolved recursively through full tree)
- `compose` — `none` / `hub` / `file` (Docker Hub image vs local build)
- `docker` — service → container name mapping
- `provides` — directories + file types offered to dependents (with `file`, `ext`, `layout`, `check` sub-fields)
- `store` — persistent config files
- `webroot` — web assets (base path from nginx provides)
- `persist` — runtime data dir (required if module has `local`; survive flag preserves across cycles)
- `local` — deployment file installs (merged from former `local.json`)

### `provides` system
Modules declare what data directories they offer and what file types they accept. The installer recursively resolves all `provides` through the full dependency tree. No paths are hardcoded — every target directory is discovered from `info.json` at install time via `kit_resolve`.

Infrastructure providers: nginx (site config + webroot), redis (data root), home (tiles + i18n), apps (app entries), links (short links). Each provider declares `accepts`, `file`, `ext`, and optional `layout`.

### Type-driven install
The installer collects all `accepts` types from the dependency chain and dispatches each:
- `tile`/`app`/`link` → single JSON file hard link
- `i18n` → per-file hard links into subdirectory
- `site` → layout-based install with prefix naming

Store, data, webroot, persist, and local files are handled separately.

### Prefix system
Site configs use numeric prefixes for nginx load order. Provider modules declare their own prefix; consumer modules use `G41_PREFIX` from `.env` (default `999`).

### i18n
3 languages: JA, ZH, EN. Served from API (`/data/i18n_ja|zh|en`). Each module has its own `i18n/` directory. The homepage module provides global i18n.

### Config is data, not code
All site configuration lives in persistent data directories as JSON, loaded into Redis at startup under `data:` prefix. The frontend fetches from Redis via the API at `/data/` endpoint.

### Never set `iptables: false` in Docker daemon
This breaks Docker bridge networking and kills DNS resolution.

### Survive mechanism
Modules with `persist: {"dir": "<dir>", "survive": true}` preserve their data across uninstall/reinstall cycles. On uninstall, the directory moves into `kits/<mod>/`. On reinstall, it's restored.

## Module lifecycle

### Install
```bash
./g41.sh kits add <module> [-y] [-C]     # auto-installs deps, runs verify
./g41.sh kits add -y all                  # install everything
```
- `kits verify` runs L1-L4 before install
- `-C` bypasses "already installed" check
- `all` installs every module in `kits/`

### Uninstall
```bash
./g41.sh kits del <module> [-y] [-C]     # -C for core modules
./g41.sh kits del -C -y all              # cascading uninstall (leaf-first)
```
- Core-dependent modules blocked without `-C`
- `all` uninstalls in reverse dependency order
- Persist dirs: survive (move to kits/) or purge (delete)

### Verify
```bash
./g41.sh kits verify <module>    # L1 self→L2 deps→L3 provides→L4 .local
./g41.sh kits check <module>     # Discover installed artifacts
```

## Development workflow

### Push changes (rsync — mandatory safety protocol)

> **⚠️ 每次 rsync 前必须执行 dry-run，确认变更范围后再执行。**

```bash
# 1. Dry-run：预览所有变更
rsync -avn --delete \
  --exclude='.git/' --exclude='.*/' --exclude='*.bak' \
  --exclude='G41KiTS_*.tar.gz' --exclude='.deepseek/' \
  G41KiTS/ $HOST:$PATH/

# 2. 检查输出
#   - 没有 "deleting" 行 → 安全
#   - 有 "deleting" 行 → 确认这些文件确实应该删除
#   - 持久化目录 (.*/) 被排除，不会被触碰

# 3. 确认安全后，完整备份
ssh $HOST "cp -a $PATH $PATH.bak"

# 4. 执行同步
rsync -av --delete \
  --exclude='.git/' --exclude='.*/' --exclude='*.bak' \
  --exclude='G41KiTS_*.tar.gz' --exclude='.deepseek/' \
  G41KiTS/ $HOST:$PATH/
```

### Rebuild specific modules
```bash
ssh $HOST "cd $PATH && ./g41.sh kits add -C -y <module> && docker compose up -d <service>"
```

### After config data changes
Clear the data-load flag and restart the API:
```bash
ssh $HOST "docker compose exec redis redis-cli -a \$REDIS_PASSWORD DEL data:loaded && docker compose restart api"
```
Wait ~60 seconds for config re-import (API crash-restarts 2-3 times during loading).

### Archive packages
Build with `./g41.sh kits pack` using flags:
- `-A` (agents) — AGENTS.md + skills/
- `-D` (docs) — docs/ + README.md
- `-L` (local) — .env + all .local/ directories
- `-S` (store) — all persistent directories (full backup)

Flags combine and name archives alphabetically by flag: `-SAL` → `G41KiTS_ALS.tar.gz`.

```bash
./g41.sh kits pack          # Standard: strict .gitignore
./g41.sh kits pack -L       # adds .env + .local/
./g41.sh kits pack -SAL     # full backup
./g41.sh kits pack -AD      # agents + docs
```

## Common issues

### Tiles not rendering
1. JS loads: `curl -sk -o /dev/null -w "%{http_code}" https://<domain>/js/G41.js`
2. Data endpoints: `curl -sk https://<domain>/data/tiles | jq empty`

### nginx crash loop
```bash
docker compose logs nginx | grep emerg
docker compose exec nginx nginx -t
```

### API returning HTML instead of JSON
```bash
docker compose exec redis redis-cli DEL data:loaded && docker compose restart api
```

### Redis permission error
```bash
chown -R 999:999 .rd/ && docker compose restart redis
```

### API returning HTML instead of JSON → 404
If Redis was restarted without `REDIS_PASSWORD` in `.env`:
```bash
# Ensure password in .env
grep REDIS_PASSWORD .env || echo 'REDIS_PASSWORD=<password>' >> .env
# Recreate Redis with password
docker compose up -d --force-recreate redis
# Clear load flag and restart API
docker compose exec redis redis-cli -a $REDIS_PASSWORD DEL data:loaded
docker compose restart api
```
### docker.sock security
Direct docker.sock mounts have been replaced by the `dsock` module:
- acme → `DOCKER_HOST=tcp://ds:2375`
- autoheal → `DOCKER_SOCK=tcp://ds:2375`
- dsock itself mounts docker.sock **read-only** (`:ro`) with restricted API endpoints

### Upstream host not found
Ensure all referenced backend containers are running. nginx fails to start if any upstream hostname is unresolvable.


