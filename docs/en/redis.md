# redis
[中文](../zh/redis.md) | [English](redis.md) | [日本語](../ja/redis.md) | [ｶﾀﾘｯｼｭ](../katalish/redis.md) | [偽中国語](../pcn/redis.md)

Redis config store + Node.js HTTP API bridge

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core,nginx |
| 容器 | rd |
| 镜像 | redis |

## Install

```bash
./g41.sh kits add redis
```

## Notes

- 需要 REDIS_PASSWORD 环境变量\n- API 在 5800 端口，通过 /data/ 端点提供数据\n- 健康检查：redis-cli -a ${REDIS_PASSWORD} ping
