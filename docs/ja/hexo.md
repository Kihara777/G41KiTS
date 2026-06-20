# hexo

[中文](../zh/hexo.md) | [English](../en/hexo.md) | [日本語](hexo.md)

個人ブログエンジン。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps, hako, nginx |
| コンテナ | hx |
| イメージ | ローカルビルド |

## インストール

```bash
./g41.sh kits add hexo
```

## 注意

- `server_name log.*`、nginx バーチャルホストでマッチ
- ブログコンテンツは `.hx/source/` に保存、hako WebDAV 経由で編集可能
- compose=file、Node.js ベースイメージでローカルビルド
