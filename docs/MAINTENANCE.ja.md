# メンテナンス記録

[中文](../MAINTENANCE.md) | [English](MAINTENANCE.en.md) | 日本語 

## 2026-09-13

- **運用タイマーを 2 本追加**（k8s/host/）、k8s モードの自動化ギャップを解消：
  - `g41-cert-reload.timer`（15 分ごと）：cert-manager 更新後、証明書を各消費 Pod に配布。
    能力ごとに処理を分岐 —— nginx は reloader sidecar を備え SIGHUP でホットロード（**再起動なし**）、
    hy2/dns はホットロード機構がなくロール再起動が必要。`tls.crt` の sha256 を指紋として冪等化し、
    配布前に `openssl -checkend 0` で期限切れ証明書を拒否。
  - `g41-image-update.timer`（毎週日曜 04:30）：フローティングタグの上流 digest を比較し、新版があればロール更新
  - `g41-notify.py`：サードパーティ依存なしの SMTP 通知。`G41_SMTP_*` 未設定時は静かにスキップ
- **単一ノード配備の欠陥を 3 件修正**（いずれも実測で踏んだ問題、ガードと文書を追加）：
  - `kits/nginx/k8s/deployment.yaml` に `imagePullPolicy: Always` を追加 —— `nginx:alpine` は
    フローティングタグで、未指定時は `IfNotPresent` が既定のため `rollout restart` は
    ローカルキャッシュを再利用するだけで上流の新版を**永遠に取得できない**
    （以前の 2 回の「更新成功」は実際には digest が変化していなかった）
  - `dns`(53/853)、`download`(51413) の `maxSurge` を 0 に —— nginx(80/443) と同理由。
    単一ノードで `hostPort` を使う場合 `maxSurge>0` だと新 Pod がポート占有で永久 Pending になる
  - `k3s-standalone.service` に `Conflicts=k3s.service` を追加し、タイマーの依存先を
    `k3s-standalone` へ変更 —— 旧来の `k3s.service`（disabled だがファイルは残存、`Restart=always`）が
    起動されると standalone と `127.0.0.1:6444` を奪い合い apiserver が crash-loop
    （restart counter が 41 まで到達）
- 文書修正：`k8s/README.md` で本配備が stakater/reloader を**導入していない**ことを明記。
  hy2/dns の `reloader.stakater.com/auto` アノテーションは無効。「証明書ローテーション」
  「定期タスク」の 2 節を追加
- `install-1gb.sh` が両タイマーを導入；`.env.example` に `G41_SMTP_*` を追加；`.gitignore` で `__pycache__` を除外
- **ローカルイメージビルドを containerd ネイティブ経路へ移行**：k8s モードでは dockerd が
  停止しているため、従来の `docker build` + `save | ctr import` は実行できない。
  nerdctl + BuildKit の containerd worker（`buildkitd.service`）に変更し、イメージを
  k3s の k8s.io namespace と overlayfs snapshotter へ直接ビルド。save/import の 2 段階が不要に
  - 新規 `g41-image-build.sh`：k8s で実際に配備される `compose=file` モジュールを自動検出
    （autoheal/dsock/acme など退役済みは除外）、COPY パスの流儀からビルドコンテキストを自動判定
  - `g41.sh k8s build` はこの経路を優先し、nerdctl 不在時は docker へフォールバック
  - 週次タスクは「Dockerfile + COPY されるファイル」の内容ハッシュで再ビルド要否を判定し、
    未変化ならスキップ。再ビルド後は該当 Deployment をロール再起動
  - 実測：bt/aria2/hexo/redis すべて再ビルド成功、2 回目はすべてスキップされ冪等性を確認

| コミット | 説明 |
|----------|------|
| `8fdb78c` | feat(k8s): 証明書配布と週次イメージ更新のタイマーを追加 |
| `031a146` | fix(k8s): 単一ノードのロールアウト欠陥 3 件を修正し文書を更新 |
| `5a8ff40` | feat(k8s): ローカルイメージを containerd ネイティブ経路でビルド（dockerd 不要） |

## 2026-08-27

- **メモリ増強完了**：VPS を 958MB → 1.6GB（目標 2GB）に増強、cert-manager を「毎月更新ウィンドウ」から**常駐**（replicas=1）に変更、crontab のウィンドウ項目を削除（apt アップグレードのみ残置）
- **CD パイプライン検証完了**：GitHub Actions `deploy.yml`（ssh-deploy@v6 + ssh-action@v1）をエンドツーエンドで確認（~28s）、secrets 設定済み；rsync に `--exclude=.env --exclude=.local.sh` を追加し VPS 私有コンテンツを保護
- `docs/zh/1gb-stability.md` を追加：1GB 安定稼働の研究結論（tmpfs kine + swap 階層化 + コンポーネント削減）
- 追加ドメイン結論：複数ドメインが同一 `_acme-challenge` CNAME ターゲットを共有すると cert-manager の並行発行でクリーンアップ競合が発生、見送り；再発行にはドメインごとの独立 CNAME ターゲットが必要
- git を GitHub に全量プッシュ（ee62381）、イメージ方針をフローティングタグに統一

## 2026-08-26

- **k3s 移行完了**：Docker Compose → Kubernetes (k3s v1.36.3)、12 Pod を 8 Pod に統合
  （hexo 静的化、tracker を api プロセスに統合、api を redis Pod に統合、aria2+bt 統合）
- コントロールプレーン：tmpfs kine（状態バックアップ/復元ユニット）、k3s-standalone
  （ファイルログで journald から分離、MemoryMin 400M、OOM 保護）；cert-manager 証明書発行
  （g41.moe + *.g41.moe）
- g41.sh：`init k8s`、`k8s stage|conf|hexo` サブコマンド、include 生成的書き換え
- 1GB ホストチューニングのスクリプト化：journald volatile / zram / swappiness / snapd 停止 / fail2ban 許可リスト
- CD パイプライン：GitHub Actions（共有コンテンツ）+ deploy-local.sh（プライベートコンテンツ）
- i18n 全量監査通過；home 説明を k3s に更新、tile_flake を現行 NixKits に同期
- 根本原因修正：journald フリーズ、k3s.service ユニット、bittorrent-tracker ESM、REDIS_HOST ハードコード等

## 2026-07-14

- blc モジュールに `blc_template` provides タイプを追加: 依存モジュールが `blc_template/` ディレクトリ経由で blivechat カスタムテンプレートを配布可能に
- blc compose.yaml に `custom_public/templates` ボリュームマウントを追加（コンテナパス `/mnt/data/data/custom_public/templates`）
- g41.sh に `blc_template` タイプのインストール・アンインストール・チェックの全処理を追加（kits_add / kits_del / kits_check）
- blc 三言語ドキュメント（ja/en/zh）にテンプレート配布の使い方を追記
- blct_tts モジュール新規作成: blivechat 向け TTS 音声読み上げカスタムテンプレート
  - デフォルト風ビジュアル表示 + Web Speech API 読み上げのハイブリッド
  - 言語自動判定（仮名→ja-JP、中国語エンジンフォールバック）
  - ダブルキュー（通常コメント順次 + ギフト/メンバーシップ割り込み独立キュー）
  - 中断コメント自動リプレイ、右クリック設定パネル（localStorage 保存）
  - blc server.conf 修正: custom_public ロケーションに proxy_pass 追加

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