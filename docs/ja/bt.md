# bt

[中文](../zh/bt.md) | [English](../en/bt.md) | [日本語](bt.md)

BitTorrent クライアント（WebUI と WebDAV 共有付き）。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps, hako, nginx |
| コンテナ | tr |

## インストール

```bash
./g41.sh kits add bt
```

## 注意

- Dockerfile からローカルビルド（`FROM alpine:3.23.4` + transmission-daemon）
- WebUI は `/transmission/`（transmission-web-control v1.6.1-update1）
- オリジナル UI は `/transmission/web/index.original.html` に保持
- WebDAV 共有は `/transmission/share`
- ヘルスチェック：`nc -zw1 127.0.0.1 9091`
- settings.json 設定は `.local/` に移行