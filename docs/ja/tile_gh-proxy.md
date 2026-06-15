# tile_gh-proxy

[中文](../zh/tile_gh-proxy.md) | [English](../en/tile_gh-proxy.md) | [日本語](tile_gh-proxy.md)

> raw.githubusercontent.com のリバースプロキシ。`/gr/` で提供。

## 基本情報

| 項目 | 値 |
|------|-----|
| タイプ | タイル |
| 依存 | home, nginx |
| Compose | none |

## インストール

```bash
./g41.sh kits add tile_gh-proxy
```

## パス

| URL | ターゲット |
|-----|-----------|
| `/gr/` | `https://raw.githubusercontent.com/` |

## 注意

- 3 言語の使用説明付きホームページタイルを提供
- 互換性のため上流 CSP ヘッダーを削除
- Docker サービスなし — 純粋な nginx プロキシ設定
- サンプル URL の `__HOST__` は現在のドメインに動的置換