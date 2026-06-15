# aria2

[中文](../zh/aria2.md) | [English](aria2.md) | [日本語](../ja/aria2.md)

Parallel download manager with WebUI and WebDAV share.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps, hako, nginx |
| Container | ad |
| Compose | file |
| Base image | `alpine:3.23.4` |

## Install

```bash
./g41.sh kits add aria2
```

## Notes

- Locally built from Dockerfile with `ADD --checksum` for AriaNg AllInOne version pinning
- WebUI at `/aria2/` (AriaNg, AngularJS SPA)
- RPC proxied via WebSocket (wss) at `/aria2rpc` through nginx
- WebDAV share at `/aria2/share`, supports PUT/DELETE/MKCOL
- Health check: `nc -zw1 127.0.0.1 6800`
- `rpc.daemon` config moved to `.local/`
- Persist dir `.ad` (downloads + config) excluded by `.gitignore`
