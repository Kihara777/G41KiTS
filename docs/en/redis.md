# redis

[中文](../zh/redis.md) | [English](redis.md) | [日本語](../ja/redis.md)

Redis config store + Node.js HTTP API bridge.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core, nginx |
| Container | rd (Redis), ra (API) |
| Image | local build |

## Install

```bash
./g41.sh kits add redis
```

## Notes

- Redis authenticated via `REDIS_PASSWORD` (`--requirepass`)
- API serves `/data/` and `/link/` endpoints on port 5800
- Data loaded from `.rd/data/` into Redis, gated by `data:loaded` flag
- Load phase uses `multi()` pipeline for batch writes
- Other containers cannot access Redis directly