# tile_links

[中文](../zh/tile_links.md) | [English](../en/tile_links.md) | [日本語](../ja/tile_links.md)

> ショートリンクタイル — ホームページ上の外部ツールダウンロードリンクのエントリ。

## 基本情報

| 項目 | 値 |
|------|-----|
| タイプ | tile |
| 依存 | home |
| Compose | none |

## インストール

```bash
./g41.sh kits add tile_links
```

## 注意

- すべての `link_*` モジュールからショートリンクを集約
- 7-Zip、.NET SDK、DirectX、VC++ Redist、Visual Studio、VS Code を含む
- Docker サービスなし — Redis API 経由でタイルデータを提供