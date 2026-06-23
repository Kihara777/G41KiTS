# home
[中文](../zh/home.md) | [English](../en/home.md) | 日本語

サイトコアデータ — キャラクターメッセージ、テーマカラー、ステータスコード、i18n。homete タイル（G41KiTS プロジェクト紹介）を直接提供します。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | data + tile |
| 依存 | core, nginx, redis |
| compose | none |

## 提供内容

- **タイル**：tile_homete（G41KiTS プロジェクト概要と技術スタック）
- **グローバル i18n**：キャラクター会話、挨拶 — JA / ZH / EN
- **データファイル**：chars.json、colors.json、langs.json、status.json
- **Web リソース**：ホームページ HTML、JS、CSS、画像
- **サイト設定**：SSL/TLS 基本設定、HSTS、エラーページ（prefix=0）

## インストール

```bash
./g41.sh kits add home
```
