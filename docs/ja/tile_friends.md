# tile_friends

[中文](../zh/tile_friends.md) | [English](../en/tile_friends.md) | 日本語

フレンドリンクのタイル — 本サイトと相互リンクしているサイトを表示します。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種別 | tile |
| 依存 | home |
| アイコン | 🤝 |
| タイル種別 | `list`（クリックでリンク一覧を展開） |

## インストール

```bash
./g41.sh kits add tile_friends
```

## タイルの内容

タイルをクリックするとフレンドリンクが一覧で展開されます。各行はアイコン・
サイト名・リンク先を持ちます。

| サイト | リンク | 備考 |
|--------|--------|------|
| 汐霧の霧星パン工房 | <https://shiogiri.com> | 「汐霧」氏の個人サイト、相互リンク |

## フレンドリンクの追加

エントリは `tile.json` の `items` 配列にインラインで記述します。サイトごとに
オブジェクトを 1 つ追加してください：

```json
{
  "icon": "🌫",
  "label": "friend_shiogiri",
  "href": "https://shiogiri.com"
}
```

`label` は i18n の**キー**（表示テキストではありません）。`i18n/{zh,ja,en}.json`
のそれぞれに対応する表示名を追加します：

```json
{"friend_shiogiri": "汐霧の霧星パン工房"}
```

## 関連

- タイルとホームページの描画ロジック：[home](home.md)
- アプリ一覧タイル：[tile_apps](tile_apps.md)
