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

- WebUI at `/transmission/` (transmission-web-control)
- RPC endpoint `/transmission/rpc`
- WebDAV share `/transmission/share`, PUT/DELETE/MKCOL support
- Persist dir `.tr/`, config deployed via `.local/`