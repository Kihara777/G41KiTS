# bt

[中文](../zh/bt.md) | [English](bt.md) | [日本語](../ja/bt.md)

BitTorrent client with WebUI and WebDAV share.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps, hako, nginx |
| Container | tr |

## Install

```bash
./g41.sh kits add bt
```

## Notes

- Locally built from Dockerfile (`FROM alpine:3.23.4` + transmission-daemon)
- WebUI at `/transmission/` (transmission-web-control v1.6.1-update1)
- Original UI preserved at `/transmission/web/index.original.html`
- WebDAV share at `/transmission/share`
- Health check: `nc -zw1 127.0.0.1 9091`
- settings.json config moved to `.local/`