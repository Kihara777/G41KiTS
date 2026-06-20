# home

[中文](../zh/home.md) | [English](../en/home.md) | [日本語](home.md)

サイトコアデータ — キャラクターメッセージ、テーマカラー、ステータスコード、i18n。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | data |
| 依存 | core, nginx, redis |

## インストール

```bash
./g41.sh kits add home
```

## 注意

- Docker サービスなし、純粋なデータモジュール
- `data/` の JSON ファイルは API 起動時に Redis に読み込み
- `webroot/` はホームページ HTML/JS/CSS とサイトアイコンを提供
- `i18n/` はグローバル多言語翻訳を提供
- chars.json の host フィールドは API が `G41_DOMAIN` 環境変数から動的注入