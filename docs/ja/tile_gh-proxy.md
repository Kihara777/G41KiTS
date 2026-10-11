# tile_gh-proxy
[中文](../zh/tile_gh-proxy.md) | [English](../en/tile_gh-proxy.md) | 日本語

raw.githubusercontent.com のリバースプロキシ。**ホームページのタイルは
2026-10-12 に撤去しました** —— サービス自体は残り、ホームページで紹介しなくなっただけです。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | proxy（タイルなし） |
| 依存 | nginx |
| パス | `/gr/` |

## インストール

```bash
./g41.sh kits add tile_gh-proxy
```

インストールされるのは nginx の断片（`zones` と `locations` に各 1 ファイル）のみで、
`tile.json` / `i18n/` は含まれません。

## 注意

- ディレクトリ名が `tile_` 接頭辞のままなのは歴史的な理由です。改名するとデプロイ済みの
  nginx 断片名（`999-tile_gh-proxy.conf`）と `G41_KITS` の記帳も一緒に変わるため、
  見合わないと判断してそのままにしています。
- タイル撤去に伴い `depends` を `home, nginx` から `nginx` に絞りました —— このモジュールは
  もう `home` が提供する `tile` / `i18n` 型を消費しません。**代償**：`kits del` は依存ツリーの
  `accepts` から削除対象を見つけるため、絞った後は旧来の
  `.rd/data/tiles/tile_gh-proxy.json` と `.rd/data/i18n/tile_gh-proxy/` を掃除しません。
  これらは一度手作業で削除済みです。

## 関連

- ホームページタイルの描画ロジック：[home](home.md)
- 代わりに置いた自己紹介タイル：[tile_kitsunome](tile_kitsunome.md)
