# hy2

[中文](../zh/hy2.md) | [English](hy2.md) | [日本語](../ja/hy2.md)

Hysteria2 proxy sharing port 443 with nginx via port reuse

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | nginx |
| Container | hq |
| Image | tobyxdd/hysteria |

## Install

```bash
./g41.sh kits add hy2
```

## Notes

- Host network mode
- Port 443 reuse with nginx
- Config in .local/hysteria.yaml (private)
- Subscription file in .local/webroot/ (private)
