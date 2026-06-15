# blc

[中文](../zh/blc.md) | [English](blc.md) | [日本語](../ja/blc.md)

Bilibili live chat with AI translation.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps, nginx |
| Container | lc |
| Compose | hub |
| Image | `xfgryujk/blivechat:v1.10.3` |

## Install

```bash
./g41.sh kits add blc
```

## Notes

- Pre-built image pulled from Docker Hub, version tag pinned
- WebSocket endpoint `/api/chat` proxied through nginx
- `config.ini` in `.local/` for deployer-specific settings (room ID, etc.)
- Persist dir `.lc` (database + config) excluded by `.gitignore`
- server_name uses wildcard `blc.*` for domain-agnostic deployment
