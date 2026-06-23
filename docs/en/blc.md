# blc
[中文](../zh/blc.md) | English | [日本語](../ja/blc.md)

Bilibili live chat with AI translation

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps,nginx |
| Container | lc |
| Image | xfgryujk/blivechat |

## Install

```bash
./g41.sh kits add blc
```

## Notes

- server_name: blc.*
- WebSocket: /api/chat
- Health check: wget http://127.0.0.1:12450/
