# bt
[中文](../zh/bt.md) | English | [日本語](../ja/bt.md)

BitTorrent client with WebUI and WebDAV share

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps,hako,nginx |
| Container | tr |
| Image | alpine + transmission-daemon（Dockerfile 本地构建） |

## Install

```bash
./g41.sh kits add bt
```

## Notes

- WebUI: /transmission/
- WebDAV: /transmission/share
- Health check: nc -zw1 127.0.0.1 9091
