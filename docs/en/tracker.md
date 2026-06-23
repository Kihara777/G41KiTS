# tracker
[中文](../zh/tracker.md) | English | [日本語](../ja/tracker.md)

Lightweight HTTPS BitTorrent tracker

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | hako,home,nginx |
| Container | wt |
| Image | node + bittorrent-tracker（Dockerfile 本地构建） |

## Install

```bash
./g41.sh kits add tracker
```

## Notes

- HTTP/UDP/WebSocket multi-protocol
- Embed: /tracker (status page)
- UDP 6969 open to public (UFW)
- Health check: wget http://127.0.0.1:8000/stats
