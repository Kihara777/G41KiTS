# nginx

[中文](../zh/nginx.md) | [English](../en/nginx.md) | [日本語](nginx.md)

TLS 1.3 / HTTP/3 ゲートウェイ — 全バックエンドへのリバースプロキシ。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core |
| コンテナ | gx |
| イメージ | nginx |

## インストール

```bash
./g41.sh kits add nginx
```

## 注意

- 80/443 でリッスン、HTTP/3 QUIC 有効
- セキュリティヘッダー: HSTS、CSP、X-Frame-Options、X-Content-Type-Options、Referrer-Policy
- プロキシパス（nix-cache、gh-proxy）は緩和 CSP で上書き
- 各モジュールの `site/` 設定から location を組み立て
- upstream は `kit_resolve` で検出