# redis

[中文](redis.md) | [English](../en/redis.md) | [日本語](../ja/redis.md)

Redis 設定ストア + Node.js API ブリッジ

## 基本情報

| 項目 | 値 |
|------|-----|
| 类型 | service |
| 依赖 | core, nginx |
| 容器 | rd |
| 镜像 | ローカルビルド |

## インストール

```bash
./g41.sh kits add redis
```

## 注意

- インメモリ DB + Node.js API（server.js）
- REDIS_PASSWORD 環境変数で認証
