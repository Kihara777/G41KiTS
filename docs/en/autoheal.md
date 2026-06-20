# autoheal

[中文](autoheal.md) | [English](../en/autoheal.md) | [日本語](../ja/autoheal.md)

Auto-restart unhealthy containers

## Info

| Item | Value |
|------|-----|
| 类型 | service |
| 依赖 | core, dsock |
| 容器 | ah |
| 镜像 | local build |

## Install

```bash
./g41.sh kits add autoheal
```

## Notes

- Local build based on willfarrell/autoheal
- Supports TCP socket connection to dsock proxy
