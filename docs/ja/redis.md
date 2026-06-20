# redis

[中文](../zh/redis.md) | [English](../en/redis.md) | [日本語](redis.md)

Redis 設定ストア + Node.js HTTP API ブリッジ。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core, nginx |
| コンテナ | rd（Redis）、ra（API） |
| イメージ | ローカルビルド |

## インストール

```bash
./g41.sh kits add redis
```

## 注意

- Redis は `REDIS_PASSWORD` で認証（`--requirepass`）
- API は 5800 ポートで `/data/` と `/link/` エンドポイントを提供
- `.rd/data/` から Redis にデータをロード、`data:loaded` フラグで制御
- ロード時は `multi()` pipeline でバッチ書き込み
- 他のコンテナは Redis に直接アクセス不可