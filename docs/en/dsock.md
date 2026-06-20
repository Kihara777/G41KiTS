# dsock

[中文](../zh/dsock.md) | [English](dsock.md) | [日本語](../ja/dsock.md)

Docker API security proxy — replaces direct docker.sock mounts.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core |
| Container | ds |

## Install

```bash
./g41.sh kits add dsock
```

## Notes

- Mounts `/var/run/docker.sock` read-only (`:ro`)
- Restricts API endpoints to `CONTAINERS` + `EXEC` + `POST`
- acme connects via `DOCKER_HOST=tcp://ds:2375`
- autoheal connects via `DOCKER_SOCK=tcp://ds:2375`
- Replaces direct docker.sock mounts to reduce attack surface