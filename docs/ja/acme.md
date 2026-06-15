# acme

[中文](../zh/acme.md) | [English](../en/acme.md) | [日本語](acme.md)

SSL 証明書管理（acme.sh + ZeroSSL/Cloudflare DNS）。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core, dsock |
| コンテナ | ca |

## インストール

```bash
./g41.sh kits add acme
```

## 注意

- Dockerfile からローカルビルド（`FROM neilpang/acme.sh:3.1.3`）
- Docker API は dsock プロキシ経由でアクセス（`DOCKER_HOST=tcp://ds:2375`）
- 環境変数ホワイトリスト：`CF_Key`、`CF_Email`、`G41_DOMAIN` のみ注入
- 証明書は `.ca/fc`（フルチェーン）と `.ca/k`（秘密鍵）に出力
- ヘルスチェック：`acme.sh --list`
- デーモンモードで自動更新