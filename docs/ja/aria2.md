# aria2

[中文](../zh/aria2.md) | [English](../en/aria2.md) | [日本語](aria2.md)

並列ダウンロードマネージャ（WebUI と WebDAV 共有付き）。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps, hako, nginx |
| コンテナ | ad |
| compose | file |
| ベースイメージ | `alpine:3.23.4` |

## インストール

```bash
./g41.sh kits add aria2
```

## 注意

- Dockerfile からローカルビルド（`ADD --checksum` で AriaNg バージョンを固定）
- WebUI は `/aria2/`（AriaNg、AngularJS SPA）
- RPC は `/aria2rpc` の WebSocket（wss）で nginx 経由プロキシ
- WebDAV 共有は `/aria2/share`、PUT/DELETE/MKCOL 対応
- ヘルスチェック：`nc -zw1 127.0.0.1 6800`
- `rpc.daemon` 設定は `.local/` に移行
- 永続化ディレクトリ `.ad`（ダウンロード＋設定）は `.gitignore` で除外
