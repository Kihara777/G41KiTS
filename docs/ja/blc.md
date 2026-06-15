# blc

[中文](../zh/blc.md) | [English](../en/blc.md) | [日本語](blc.md)

Bilibili ライブチャット（AI 翻訳付き）。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps, nginx |
| コンテナ | lc |
| compose | hub |
| イメージ | `xfgryujk/blivechat:v1.10.3` |

## インストール

```bash
./g41.sh kits add blc
```

## 注意

- Docker Hub からビルド済みイメージを取得、バージョンタグ固定
- WebSocket エンドポイント `/api/chat` は nginx 経由でプロキシ
- `config.ini` は `.local/` に配置（ルーム ID 等、デプロイ固有の設定）
- 永続化ディレクトリ `.lc`（データベース＋設定）は `.gitignore` で除外
- server_name にワイルドカード `blc.*` を使用、ドメイン非依存
