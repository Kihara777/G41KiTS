# redis

[中文](../../zh/redis.md) | [English](../../en/redis.md) | [日本語](../../ja/redis.md) | [偽中国語](redis.md) | [ｶﾀﾘｯｼｭ](../../katalish/redis.md)

Redis 設定倉儲 + Node.js HTTP API 橋接

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core,nginx |
| 容器 | rd |
| 镜像 | redis |

## 導入

```bash
./g41.sh kits add redis
```

## 注意

- 需要 REDIS_PASSWORD 环境变量\n- API 在 5800 端口，通过 /data/ 端点提供数据\n- 健康检查：redis-cli -a ${REDIS_PASSWORD} ping