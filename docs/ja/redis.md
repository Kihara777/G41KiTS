# redis

[中文](../zh/redis.md) | [English](../en/redis.md) | [日本語](redis.md)

Redis 構成ストア + Node.js HTTP API ブリッジ。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core |
| コンテナ | rd / ra（API） |

## インストール

```bash
./g41.sh kits add redis
```

## 注意

- Dockerfile からローカルビルド（`FROM redis:8.4.0-alpine` + `FROM node:24.16.0-alpine`）
- Redis は `REDIS_PASSWORD` 環境変数で `--requirepass` 認証を有効化
- API コンテナは `depends_on` + pipeline でデータをバッチロード
- データエンドポイント `/data/<key>` は Redis から読み取り JSON で返却
- 短縮リンク `/link/<name>` は `__HOST__` プレースホルダを現在のドメインに解決
- ロードフェーズは `data:loaded` + `data:loading` チェックポイントで二重ロード防止
- `multi()` pipeline バッチ書き込みで crash-restart ループを削減