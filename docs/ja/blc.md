# blc

[中文](../zh/blc.md) | [English](../en/blc.md) | [日本語](blc.md)

Bilibili ライブチャット（AI 翻訳付き）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,nginx |
| コンテナ | lc |
| イメージ | xfgryujk/blivechat |

## インストール

```bash
./g41.sh kits add blc
```

## 注意

- server_name: blc.*
- WebSocket: /api/chat
- ヘルスチェック: wget http://127.0.0.1:12450/
