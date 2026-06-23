# メンテナンス記録

[中文](../../MAINTENANCE.md) | [English](../MAINTENANCE.en.md) | [日本語](../MAINTENANCE.ja.md) | [ｶﾀﾘｯｼｭ](../katalish/MAINTENANCE.md) | 偽中国語

## 2026-06-20

- オープンソース化: `main` ブランチ GitHub 於プッシュ
- 三言語ドキュメント公開（27 部品 + 部品仕様）: zh:29 / en:29 / ja:29
- AGENTS.md 中国語以完全書き直し（292 行）、アーキテクチャ・開発ワークフロー・よく問題網羅
- README 於 `.local/` ローカル初期化セクション追加
- 三言語メンテナンス記録（MAINTENANCE.md / en / ja）
- 三言語 NOTICE.md（サードパーティ資産於関声明）

## 2026-06-18

- 全 Docker バージョンロック解除: Dockerfile FROM 行、compose image タグ、npm 包バージョン、ADD --checksum すべてフローティングバージョン於変更
- `skills/` 不在於よる `g41.sh kits pack` 之 `set -e` エラー修正
- 全スタックコンテナ強制再構築、14/14 healthy

## 2026-06-16

- 2 回之全面セキュリティ監査（4 サブエージェント並列）: 24 件之問題発見、すべて修正また許容
- g41.sh 強化: `set -o pipefail`、`sed -i` → アトミック書き込み、compose include 行番号於よる正確な挿入
- autoheal クラッシュ修正: willfarrell/autoheal Hub イメージ自カスタム Dockerfile 於変更（TCP ソケット対応之 master 版 entrypoint）
- CSP セキュリティヘッダ之階層化: メインサイト厳格、aria2/nix-cache/gh-proxy 代理パス緩和
- tiles.js tracker 埋め込み XSS 修正: `innerHTML` → `createElement` + `textContent`
- G41.js fetch 於 5 秒タイムアウト追加（`AbortSignal.timeout(5000)`）
- server.js 之全 `catch(e){}` サイレントエラー於 `console.error` ログ追加
- オープンソース準備監査合格: ハードコードされたドメイン・シークレットゼロ於、全センシティブ書類 `.gitignore` 以除外
- tile_bilibili 部品新規作成: Bilibili VTuber タイル（三言語 i18n）
- tile_flake タイル於 13 件之 NixKits 包/パッチ/スキル入力
- tile_gh-proxy i18n 之ハードコード `g41.moe` → `__HOST__` プレースホルダ
- g41.sh TUI  ANSI エスケープシーケンス増分レンダリング於変更（ちらつき解消）
- GitHub リポジトリ作成與トピック設定

## 2026-06-11 ~ 2026-06-12

- データ與機能之分離（A/B/C 層）: compose 変数化、nginx site 設定之汎化、server.js 環境変数注入
- セキュリティ強化: dsock 新部品（Docker API 代理）、BT サプライチェーンロック、Redis パスワード認証
- ヘルスチェック標準化（HTTP エンドポイント > ポートプローブ > kill -0 1）
- 部品名変更: 純粋タイル → `tile_*` 接頭辞（5 件）、純粋リンク → `link_*` 接頭辞（6 件）
- フロントエンド修正: エラーコードページ、読み込みちらつき、404 応答
- hy2 部品秘匿化: `.local/` 以サブスクリプション書類與 nginx 設定隠蔽
- g41.sh 拡張: `.local/site/` 與 `.local/webroot/` 之自動検出
- server.js 再構築: 生 TCP ソケット → `redis` npm 包永続接続 + パイプラインバッチ書き込み

## 2026-06-10

- 初期監査: compose.yaml、g41.sh、全 kits/ 部品
- 基盤構築: Metro/WP8.1 風ホームページ、Redis 設定 API、多言語 i18n、KITS 部品体系