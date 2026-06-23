# bt
[中文](../zh/bt.md) | [English](../en/bt.md) | 日本語 | [ｶﾀﾘｯｼｭ](../katalish/bt.md) | [偽中国語](../pcn/bt.md)

BitTorrent クライアント（WebUI と WebDAV 共有付き）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,hako,nginx |
| コンテナ | tr |
| イメージ | alpine + transmission-daemon（Dockerfile 本地构建） |

## インストール

```bash
./g41.sh kits add bt
```

## 注意

- WebUI: /transmission/
- WebDAV: /transmission/share
- ヘルスチェック: nc -zw1 127.0.0.1 9091
