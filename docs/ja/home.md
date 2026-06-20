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

- compose:none — Docker サービスなし
- グローバル i18n 翻訳を提供（ja/zh/en）
- tiles/apps/links の provides ターゲットディレクトリ
- データファイル（chars.json 等）を Redis にロード