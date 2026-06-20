# hako

[中文](../zh/hako.md) | [English](../en/hako.md) | [日本語](hako.md)

Web ファイルマネージャ（公開 WebDAV 共有付き）。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps, nginx |
| コンテナ | fb |
| イメージ | filebrowser/filebrowser |

## インストール

```bash
./g41.sh kits add hako
```

## 注意

- Web ファイル管理 UI（アップロード・ダウンロード・プレビュー）
- 公開 WebDAV 共有パス `/hako/`
- 設定ファイル `filebrowser.db` と `settings.json` は .local 経由でデプロイ
