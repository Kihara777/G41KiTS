# hy2

[中文](../zh/hy2.md) | [English](hy2.md) | [日本語](../ja/hy2.md)

Hysteria2 proxy sharing port 443 with nginx via port reuse.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | nginx |
| Container | hq |

## Install

```bash
./g41.sh kits add hy2
```

## Notes

- Uses host networking for port reuse with nginx
- Private config (hysteria.yaml) in `.local/`
- Subscription file and location config installed via `.local/` (not public)
- Health check: `kill -0 1` (host network limitation)
- Resource limits: 512m / 2.0 CPU
