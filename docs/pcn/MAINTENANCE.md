# メンテナンス記録

[中文](../../MAINTENANCE.md) | [English](../MAINTENANCE.en.md) | [日本語](../MAINTENANCE.ja.md) | [ｶﾀﾘｯｼｭ](../katalish/MAINTENANCE.md) | [偽中国語](MAINTENANCE.md)

## 2026-06-20

- オープンソース化: `main` ブランチを GitHub にプッシュ
- 三言語ドキュメント公開（27 モジュール + モジュール仕様）: zh:29 / en:29 / ja:29
- AGENTS.md を中国語で完全書き直し（292 行）、アーキテクチャ・開発ワークフロー・よくある問題を網羅
- README に `.local/` ローカル初期化セクションを追加
- 三言語メンテナンス記録（MAINTENANCE.md / en / ja）
- 三言語 NOTICE.md（サードパーティ資産に関する声明）

## 2026-06-18

- 全 Docker バージョンロック解除: Dockerfile FROM 行、compose image タグ、npm パッケージバージョン、ADD --checksum をすべてフローティングバージョンに変更
- `skills/` 不在による `g41.sh kits pack` の `set -e` エラーを修正
- 全スタックコンテナ強制再構築、14/14 healthy

## 2026-06-16

- 2 回の全面セキュリティ監査（4 サブエージェント並列）: 24 件の問題を発見、すべて修正または許容
- g41.sh 強化: `set -o pipefail`、`sed -i` → アトミック書き込み、compose include 行番号による正確な挿入
- autoheal クラッシュ修正: willfarrell/autoheal Hub イメージからカスタム Dockerfile に変更（TCP ソケット対応の master 版 entrypoint）
- CSP セキュリティヘッダの階層化: メインサイトは厳格、aria2/nix-cache/gh-proxy プロキシパスは緩和
- tiles.js tracker 埋め込み XSS 修正: `innerHTML` → `createElement` + `textContent`
- G41.js fetch に 5 秒タイムアウト追加（`AbortSignal.timeout(5000)`）
- server.js の全 `catch(e){}` サイレントエラーに `console.error` ログ追加
- オープンソース準備監査合格: ハードコードされたドメイン・シークレットをゼロに、全センシティブファイルを `.gitignore` で除外
- tile_bilibili モジュール新規作成: Bilibili VTuber タイル（三言語 i18n）
- tile_flake タイルに 13 件の NixKits パッケージ/パッチ/スキルを入力
- tile_gh-proxy i18n のハードコード `g41.moe` → `__HOST__` プレースホルダ
- g41.sh TUI を ANSI エスケープシーケンス増分レンダリングに変更（ちらつき解消）
- GitHub リポジトリ作成とトピック設定

## 2026-06-11 ~ 2026-06-12

- データと機能の分離（A/B/C 層）: compose 変数化、nginx site 設定の汎化、server.js 環境変数注入
- セキュリティ強化: dsock 新モジュール（Docker API プロキシ）、BT サプライチェーンロック、Redis パスワード認証
- ヘルスチェック標準化（HTTP エンドポイント > ポートプローブ > kill -0 1）
- モジュール名変更: 純粋タイル → `tile_*` 接頭辞（5 件）、純粋リンク → `link_*` 接頭辞（6 件）
- フロントエンド修正: エラーコードページ、読み込みちらつき、404 応答
- hy2 モジュール秘匿化: `.local/` でサブスクリプションファイルと nginx 設定を隠蔽
- g41.sh 拡張: `.local/site/` と `.local/webroot/` の自動検出
- server.js 再構築: 生 TCP ソケット → `redis` npm パッケージ永続接続 + パイプラインバッチ書き込み

## 2026-06-10

- 初期監査: compose.yaml、g41.sh、全 kits/ モジュール
- 基盤構築: Metro/WP8.1 風ホームページ、Redis 設定 API、多言語 i18n、KITS モジュールシステム