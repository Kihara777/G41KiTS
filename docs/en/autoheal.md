# autoheal

[中文](../zh/autoheal.md) | [English](autoheal.md) | [日本語](../ja/autoheal.md)

Auto-restart unhealthy Docker containers.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core, dsock |
| Container | ah |

## Install

```bash
./g41.sh kits add autoheal
```

## Notes

- Uses custom Dockerfile built locally (based on `willfarrell/autoheal`), **not a Hub image**
- Accesses Docker API via dsock proxy (`DOCKER_SOCK=tcp://ds:2375`)
- Monitors all containers with health checks (`AUTOHEAL_CONTAINER_LABEL=all`)
- Health check uses `pgrep -f autoheal` to verify daemon is running
- Default check interval 5 seconds, startup delay 30 seconds
- Only restarts `health: unhealthy` containers; skips containers in `restarting` state
