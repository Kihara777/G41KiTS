# dsock

[中文](dsock.md) | [English](../en/dsock.md) | [日本語](../ja/dsock.md)

Docker API security proxy

## Info

| Item | Value |
|------|-----|
| 类型 | service |
| 依赖 | core |
| 容器 | ds |
| 镜像 | tecnativa/docker-socket-proxy |

## Install

```bash
./g41.sh kits add dsock
```

## Notes

- Mounts docker.sock read-only
- Restricts API to CONTAINERS+EXEC+POST
