# aria2

[中文](../zh/aria2.md) | [English](../en/aria2.md) | [日本語](aria2.md)

並列ダウンロードマネージャ、WebUI と WebDAV 共有付き。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps, hako, nginx |
| コンテナ | ad |

## インストール

```bash
./g41.sh kits add aria2
```

## 注意

- WebUI は `/aria2/`（AriaNg、ローカル Dockerfile でビルド）
- RPC エンドポイント `/aria2rpc`（nginx 経由 WebSocket プロキシ）
- WebDAV 共有は `/aria2/`、PUT/DELETE/MKCOL 対応
- ヘルスチェックは `nc -zw1 127.0.0.1 6800`（TCP ポート検出）