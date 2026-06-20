# aria2

[中文](../zh/aria2.md) | [English](aria2.md) | [日本語](../ja/aria2.md)

Parallel download manager with WebUI and WebDAV share.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps, hako, nginx |
| Container | ad |

## Install

```bash
./g41.sh kits add aria2
```

## Notes

- WebUI at `/aria2/` (AriaNg, built via local Dockerfile)
- RPC endpoint `/aria2rpc` (WebSocket through nginx proxy)
- WebDAV share at `/aria2/`, PUT/DELETE/MKCOL support
- Health check via `nc -zw1 127.0.0.1 6800` (TCP port probe)