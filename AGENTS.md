# G41KiTS — Agent Guide

## Goal

Build and maintain G41KiTS — a modular self-hosted Docker Compose stack with Metro/WP8.1 homepage, Redis-backed config API, multi-language i18n, and a KITS module system for service management.

## Overview

Self-hosted Docker Compose stack on a single VPS, serving:
- Homepage — Metro/WP8.1 style tiles, status code pages
- Blog — Hexo personal blog
- Live chat — Bilibili live chat
- DNS-over-HTTPS/TLS/QUIC proxy, BT tracker, WebDAV, Nix cache mirror
- Hysteria2 proxy sharing port 443 with nginx

## Key principles

- Hard links, not symlinks — all module installations use `ln -f`
- KITS module system — every service/tile/site is a module under `kits/`
- Module naming: `tile_*` (pure tiles), `link_*` (short links), bare name (Docker services)
- compose modes: `none` (no Docker), `hub` (Docker Hub), `file` (local Dockerfile)
- .local/ deployment pattern for deployer-specific configs
- Health checks: HTTP endpoint > port probe > kill -0 1
- Image version locking recommended but not enforced

## Module lifecycle

```bash
./g41.sh kits add <module> [-y] [-C]    # Install with auto-deps
./g41.sh kits del <module> [-y] [-C]    # Uninstall cascading
./g41.sh kits verify <module>           # L1→L2→L3→L4 checks
./g41.sh kits pack [-ADLS]              # Build archive
```

## Development workflow

1. Edit locally → `rsync --dry-run` → verify → `rsync` to remote
2. Remote: `./g41.sh kits add -C -y <module> && docker compose up -d <service>`
3. After config changes: `docker compose exec redis redis-cli -a $REDIS_PASSWORD DEL data:loaded && docker compose restart api`

## Common issues

- Tiles not rendering: check `curl /js/G41.js` and `/data/tiles`
- nginx crash: `docker compose logs nginx | grep emerg`
- API returns HTML: `redis-cli DEL data:loaded && docker compose restart api`
- Upstream not found: ensure all backend containers are running