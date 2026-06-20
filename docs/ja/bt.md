# bt

[中文](../zh/bt.md) | [English](../en/bt.md) | [日本語](bt.md)

BitTorrent クライアント、WebUI と WebDAV 共有付き。

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

- WebUI は `/transmission/`（transmission-web-control）
- RPC エンドポイント `/transmission/rpc`
- WebDAV 共有 `/transmission/share`、PUT/DELETE/MKCOL 対応
- 永続化ディレクトリ `.tr/`、設定は `.local/` でデプロイ