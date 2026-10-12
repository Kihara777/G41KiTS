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

## 初回表示（起動リングと失敗状態）

初回表示は `G41.js` の 6 本のデータ要求（tiles / chars / status / 3 言語の i18n）が
すべて揃うまで `init()` を待ち、それまで `#g41-app` は `opacity:0` のままです。
その空白を埋めるのが `#g41-loading` の **WP8 起動リング**：純粋な CSS（`base.css` の
`.g41-ring`）なので、JS が届く前の最初のフレームから見えます。`prefers-reduced-motion`
では**静止した 5 点**に退化します。

| 状態 | 切り替える側 | 表示 |
|------|-------------|------|
| 起動中 | なし（CSS のみ） | 琥珀色の 5 点リング（ビューポート中央） |
| 準備完了 | `applyStatus()` 内の `endLoading()` | リングがフェードアウトし `#g41-app` がフェードイン（ステータスコード頁も同じ経路） |
| 起動失敗 | `bootFailed()` | リングを「読み込みに失敗しました / Failed to load」＋実際のエラー文に置換 |

**リングを回しっぱなしにしてはいけません** —— 回り続けることは「まだ読んでいる」という主張です。
`bootFailed()` が存在する理由はそこにあります。

### スクリプトの順序は判据であって、趣味ではありません

```html
<script src="/js/tiles.js"></script>   <!-- 先に実行：closeDetail / buildTiles はここ -->
<script src="/js/G41.js"></script>     <!-- 実行と同時にデータ要求を始め、そのコールバックが上を使う -->
```

逆順だとコールドスタート（キャッシュなし）でデータが先に返ることがあり、`init()` が
`ReferenceError: closeDetail is not defined` を投げて頁全体が `opacity:0` のまま止まります。
**2026-10-12 の実測：修正前はコールドスタート 5/5 が白画面**。`tiles.js` を 3 秒遅らせれば
ローカルのスタブで確定的に再現できます。`tiles.js` のトップレベルは関数宣言だけで
`G41.js` に依存しないため、先に実行しても安全です。
