# nginx

[中文](../zh/nginx.md) | [English](../en/nginx.md) | [日本語](nginx.md)

TLS 1.3 / HTTP/3 ゲートウェイ、全バックエンドのリバースプロキシ。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core |
| コンテナ | gx |

## インストール

```bash
./g41.sh kits add nginx
```

## 注意

- Dockerfile からローカルビルド（`FROM alpine:3.23.4`）
- store/ で nginx.conf + mime.types 基本設定を提供
- 全ロケーションは `include /etc/nginx/conf.d/locations/*.conf` で動的ロード
- セキュリティヘッダー：HSTS、X-Content-Type-Options、X-Frame-Options、Referrer-Policy、CSP
- プロキシパス（/nichan/、/gr/ など）は CSP を緩和ポリシーで上書き
- QUIC/HTTP3 は `quic_bpf on` で有効化