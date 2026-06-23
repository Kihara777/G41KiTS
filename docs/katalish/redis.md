# redis
[中文](../zh/redis.md) | [English](../en/redis.md) | [日本語](../ja/redis.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/redis.md)

Redis ｺﾝﾌｨｸﾞ ｽﾄｱ + Node.js HTTP API 橋渡

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | ｺｱ,nginx |
| 容器 | rd |
| 镜像 | redis |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add redis
```

## 注意

- 需要 REDIS_ﾊﾟｽﾜｰﾄﾞ 环境变量\n- API 在 5800 端口，通过 /ﾃﾞｲﾀ/ 端点提供数据\n- 健康检查：redis-cli -a ${REDIS_ﾊﾟｽﾜｰﾄﾞ} ping