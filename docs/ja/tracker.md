# tracker

[中文](../zh/tracker.md) | [English](../en/tracker.md) | [日本語](tracker.md)

軽量 HTTPS BitTorrent トラッカー。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | hako, home, nginx |
| コンテナ | wt |

## インストール

```bash
./g41.sh kits add tracker
```

## 注意

- Dockerfile からローカルビルド（`FROM node:24.16.0-alpine` + bittorrent-tracker@11.2.2）
- ステータスエンドポイント `/tracker`（ホームページタイル詳細に埋め込み）
- UDP 6969 を UFW で公開
- ヘルスチェック：`wget -q http://127.0.0.1:8000/stats`
