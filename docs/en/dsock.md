# dsock
[中文](../zh/dsock.md) | English | [日本語](../ja/dsock.md)

Restricted Docker API proxy, replaces direct docker.sock mounts

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core |
| 容器 | ds |
| 镜像 | tecnativa/docker-socket-proxy |

## Install

```bash
./g41.sh kits add dsock
```

## Notes

- 挂载 /var/run/docker.sock 只读（:ro）\n- 限制 API 端点为 CONTAINERS + EXEC + POST
