# redis
[中文](redis.md) | [English](../en/redis.md) | [日本語](../ja/redis.md) | [ｶﾀﾘｯｼｭ](../katalish/redis.md) | [偽中国語](../pcn/redis.md)

Redis 配置存储 + Node.js HTTP API 桥接

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core,nginx |
| 容器 | rd |
| 镜像 | redis |

## 安装

```bash
./g41.sh kits add redis
```

## 注意

- 需要 REDIS_PASSWORD 环境变量\n- API 在 5800 端口，通过 /data/ 端点提供数据\n- 健康检查：redis-cli -a ${REDIS_PASSWORD} ping
