# tracker

[中文](../zh/tracker.md) | [English](tracker.md) | [日本語](../ja/tracker.md)

Lightweight HTTPS BitTorrent tracker.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | hako, home, nginx |
| Container | wt |
| Image | local build |

## Install

```bash
./g41.sh kits add tracker
```

## Notes

- `/announce` endpoint handles BitTorrent tracking requests
- `/tracker` endpoint returns HTML stats, embeddable in tile detail page
- UDP port 6969 open to public via UFW
