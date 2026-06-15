# hexo

[中文](../zh/hexo.md) | [English](../en/hexo.md) | [日本語](hexo.md)

個人ブログエンジン。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps, hako, nginx |
| コンテナ | hx |

## インストール

```bash
./g41.sh kits add hexo
```

## 注意

- Dockerfile からローカルビルド（`FROM node:24.16.0-alpine` + hexo-cli@4.3.2）
- バーチャルホスト `server_name log.*`
- ヘルスチェック：`wget -q http://127.0.0.1:4000/`
- 永続化ディレクトリ `.hx`（survive フラグ付き）
