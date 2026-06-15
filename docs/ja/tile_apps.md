# tile_apps

[中文](../zh/tile_apps.md) | [English](../en/tile_apps.md) | [日本語](../ja/tile_apps.md)

> アプリ一覧タイル — 全サービスのホームページエントリ。

## 基本情報

| 項目 | 値 |
|------|-----|
| タイプ | tile |
| 依存 | core, home, nginx |
| Compose | none |

## インストール

```bash
./g41.sh kits add tile_apps
```

## 注意

- すべての `app.json` モジュールからアプリエントリを集約
- 各エントリは名前、アイコン、説明、リンクを含む
- Docker サービスなし — Redis API 経由でタイルデータを提供