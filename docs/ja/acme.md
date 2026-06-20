# acme

[中文](../zh/acme.md) | [English](../en/acme.md) | [日本語](acme.md)

SSL 証明書管理（acme.sh + ZeroSSL/Cloudflare DNS）。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core, dsock |
| コンテナ | ca |
| イメージ | ローカルビルド |

## インストール

```bash
./g41.sh kits add acme
```

## 注意

- `DOCKER_HOST=tcp://ds:2375` で Docker API に接続
- ZeroSSL を CA として使用、Cloudflare DNS 検証
- `CF_Key` と `CF_Email` のみ環境変数として注入
- 証明書は `.ca/` 永続化ディレクトリに保存
- デーモンモードで自動更新