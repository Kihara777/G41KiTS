# home

[中文](../zh/home.md) | [English](../en/home.md) | [日本語](home.md)

サイトコアデータ — キャラクターメッセージ、テーマカラー、ステータスコード、i18n。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | データ |
| 依存 | core, nginx, redis |
| コンテナ | — |

## インストール

```bash
./g41.sh kits add home
```

## 注意

- データ専用モジュール、Docker サービスなし（`compose: none`）
- グローバル i18n 翻訳を提供（ja/zh/en）
- ホームページタイルの `error_page` 設定を管理
- サイトメタデータは `data/` ディレクトリに定義：キャラクター（chars.json）、テーマカラー（colors.json）、ステータスコード（status.json）
- Webroot に G41.html、CSS、JS、画像アセットを含む
