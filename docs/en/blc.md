# blc

[中文](../zh/blc.md) | [English](blc.md) | [日本語](../ja/blc.md)

Bilibili live chat with AI translation.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps, nginx |
| Container | lc |

## Install

```bash
./g41.sh kits add blc
```

## Notes

- Virtual host `server_name blc.*`
- `/api/chat` endpoint with WebSocket upgrade support
- Includes 000-home.conf (shared error_page handling)
- All requests proxied through nginx to `http://lc`