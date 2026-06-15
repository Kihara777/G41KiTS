# tracker

[中文](../zh/tracker.md) | [English](tracker.md) | [日本語](../ja/tracker.md)

Lightweight HTTPS BitTorrent tracker.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | hako, home, nginx |
| Container | wt |

## Install

```bash
./g41.sh kits add tracker
```

## Notes

- Locally built from Dockerfile (`FROM node:24.16.0-alpine` + bittorrent-tracker@11.2.2)
- Status endpoint `/tracker` (embedded in homepage tile detail)
- UDP 6969 open to public via UFW
- Health check: `wget -q http://127.0.0.1:8000/stats`
