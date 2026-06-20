# blc

[中文](../zh/blc.md) | [English](../en/blc.md) | [日本語](blc.md)

Bilibili ライブチャット、AI 翻訳付き。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps, nginx |
| コンテナ | lc |

## インストール

```bash
./g41.sh kits add blc
```

## 注意

- バーチャルホスト `server_name blc.*`
- `/api/chat` エンドポイントは WebSocket アップグレード対応
- 000-home.conf を含む（error_page 処理を共有）
- 全リクエストは nginx 経由で `http://lc` にプロキシ