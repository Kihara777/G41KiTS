# autoheal

[中文](../zh/autoheal.md) | [English](autoheal.md) | [日本語](../ja/autoheal.md)

Auto-restart unhealthy Docker containers

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core,dsock |
| 容器 | ah |
| 镜像 | 本地构建 |

## Install

```bash
./g41.sh kits add autoheal
```

## Notes

- 自定义 Dockerfile（基于 willfarrell/autoheal），支持 TCP socket\n- 通过 DOCKER_SOCK=tcp://ds:2375 连接 dsock\n- 每 5 秒检查一次容器健康状态
