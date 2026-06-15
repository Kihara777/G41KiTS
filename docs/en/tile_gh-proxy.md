# tile_gh-proxy

[中文](../zh/tile_gh-proxy.md) | [English](tile_gh-proxy.md) | [日本語](../ja/tile_gh-proxy.md)

> Reverse proxy for raw.githubusercontent.com, served under `/gr/`.

## Info

| Field | Value |
|-------|-------|
| Type | tile |
| Depends | home, nginx |
| Compose | none |

## Install

```bash
./g41.sh kits add tile_gh-proxy
```

## Paths

| URL | Target |
|-----|--------|
| `/gr/` | `https://raw.githubusercontent.com/` |

## Notes

- Provides a home-page tile with usage instructions in three languages
- Upstream CSP header is stripped for compatibility
- No Docker service — pure nginx proxy configuration
- `__HOST__` in example URLs is dynamically replaced with the current domain