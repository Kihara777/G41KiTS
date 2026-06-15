# redis

[中文](../zh/redis.md) | [English](redis.md) | [日本語](../ja/redis.md)

Redis config store + Node.js HTTP API bridge.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core |
| Container | rd / ra (API) |

## Install

```bash
./g41.sh kits add redis
```

## Notes

- Locally built from Dockerfile (`FROM redis:8.4.0-alpine` + `FROM node:24.16.0-alpine`)
- Redis enables `--requirepass` authentication via `REDIS_PASSWORD` env var
- API container loads data in batches via `depends_on` + pipeline
- Data endpoint `/data/<key>` reads from Redis, returns JSON
- Short link `/link/<name>` resolves `__HOST__` placeholder to current domain
- Load phase uses `data:loaded` + `data:loading` checkpoints to prevent duplicate loads
- `multi()` pipeline batch writes reduce crash-restart loops