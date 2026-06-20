# redis

[中文](redis.md) | [English](../en/redis.md) | [日本語](../ja/redis.md)

Redis config store + Node.js HTTP API bridge

## Info

| Item | Value |
|------|-----|
| 类型 | service |
| 依赖 | core, nginx |
| 容器 | rd |
| 镜像 | local build |

## Install

```bash
./g41.sh kits add redis
```

## Notes

- In-memory DB with Node.js API (server.js)
- Auth via REDIS_PASSWORD env var
