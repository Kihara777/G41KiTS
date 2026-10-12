# メンテナンス記録

[中文](../MAINTENANCE.md) | [English](MAINTENANCE.en.md) | 日本語 

## 2026-10-12

- **gh-proxy のホームページタイルを撤去し、自己紹介タイル `tile_kitsunome` を追加**（保守者の要望）：
  - `tile_gh-proxy` から `tile.json` + `i18n/` を削除し、`depends` を `home, nginx` から `nginx` に
    絞りました。**タイルは撤去、サービスは存続** —— `/gr/` は従来どおり。ディレクトリ名は変更しません
    （改名するとデプロイ済みの断片名と `G41_KITS` の記帳も変わるため）。AGENTS.md に「既知の例外」
    として記録し、新モジュールはこの形を真似しないよう明記
  - 新タイル `tile_kitsunome`（🐾 / 短名 `kitsunome` / `guide` 三段）は保守者が誰で、どう検証するかを
    紹介。3 言語の i18n を一度に用意。文案は**外向けの部分のみ**（G41KiTS は公開リポジトリで CD が
    自動デプロイ）。デプロイの詳細やローカルの私的記録はこのリポジトリに入れません —— 境界は
    `docs/*/tile_kitsunome.md` に記載
  - デプロイ：`kits add tile_kitsunome` + 旧来の残置 2 件を手作業で削除
    （`.rd/data/tiles/tile_gh-proxy.json`、`.rd/data/i18n/tile_gh-proxy/` —— `depends` を絞った後は
    `kits del` が見つけません）+ ホットリロード
  - 実測：`/data/tiles` は 12 件、`tile_kitsunome` を含み `tile_gh-proxy` を含まない。3 言語とも
    `kitsunome_*` が入り `ghp_*` は消滅。3 言語の並び順は一致（kitsunome は kihara777 の直後）。
    ホームページと `/gr/` はともに 200
  - タイルに**公開ページへのリンク**を追加（保守者の指摘）：<https://grg41.github.io/>（3 ページ × 3 言語）。
    リンクのテキストは 3 言語共通で、**href はホームページの言語に追随**（zh → `/`、ja → `/ja/`、
    en → `/en/`）。段落の値はインライン HTML ではなく i18n キーにして、L1b のキー網羅チェックが
    3 言語すべてを書くよう強制するようにしています
- **`kits verify` の静黙故障を修正**：`local m="$1" md="kits/$m"` では `$m` が代入**前**に展開されるため
  `md` は常に `kits/` でした。結果として L1/L3/L4 と「モジュールが無い」エラーがすべて空振りし、
  実測で `kits verify no-such-module` が PASS / exit 0 を返していました（`kits add` はこれを関門に
  しています）。代入を分割した後、31 モジュールすべてが再度 PASS（偽陽性なし）。4 つの反例
  （キー欠落 / 壊れた JSON / 空の i18n ディレクトリ / Dockerfile 無しの compose=file）がそれぞれ FAIL に転じます
- **L1 にタイル i18n キー網羅チェックを追加**：キー欠落、i18n が正しい JSON でない、`i18n/` に
  `*.json` が無い、の 3 件がそれぞれ ERR。キー欠落はページ上で**エラーになりません**
  （`t()` がキー名をそのまま描画）。パース失敗も server.js では `console.error` 止まりです
- **`kits reload` の修正 2 件 + 記帳の修正 1 件**：k8s 分岐は `deploy/api` を叩いていましたが、api は
  **redis Deployment の 2 番目のコンテナ**であり、この構成ではその exec は決して成功しません。
  compose 分岐の失敗時は pod ラベルで本当の診断（backend のドリフト）を出すようにし、
  `kits add --dry-run` は `G41_KITS` を書かなくなりました
- **実機での発見（未修正、保守者の判断に委ねる）**：
  - VPS の `.env` に `G41_BACKEND=k8s` が無く（デプロイはとうに k3s）、`kits reload` は必ず compose
    分岐に落ちていました。今回は `./g41.sh backend k8s` で補完。**注意：`deploy-local.sh` は `.env` を
    丸ごと送り、ローカルの `.env` にこのキーが無いため、次回の送信で再び消えます**
  - VPS の `.env` に `RELOAD_SECRET` が無く（コンテナ内では空）、server.js は expected が空のとき
    チェックを**行いません**。現在 `/admin/` は nginx に代理されておらず露出していませんが、リポジトリの
    `kits/redis/site/location.conf` は `/admin/` を含むため、redis を再インストールすると
    無認証のリロード端点が公開されます
  - `.gx/conf.d/locations/999-redis.conf` はリポジトリのソースと **inode が異なり内容も古い**（`/data/` のみ）
    —— rsync にハードリンクを置き換えられた後、再インストールされていない典型形で、実機とリポジトリが食い違っています
  - この保守記録は 3 言語版が以前から分岐しています（zh のみ 2026-08-24 / 06-24 / 06-22、
    en·ja のみ 2026-07-14）。今回の項目は 3 言語で同期し、過去の分岐は触っていません
- **タイル文案の修正（彼女の指摘）**：名前の行は「キツのめ は『狐の目』」と書いていましたが、それは
  **私の読み方**で、名前の来歴ではありません。保守者によれば `kitsunome` は **つめ**（爪）を意識して
  名付けられ、「小爪」はそこから来ています。3 言語の i18n とドキュメントを両方の半分
  （キツ（狐）・の・め + 私の読み方 + 内なる つめ（爪）→ 小爪）に書き換えました
- **初回表示の空白に WP8 起動リングを追加 —— そしてコールドスタート白画面の原因を捕まえました**
  （保守者の観測「タイルの読み込みに時間がかかるようになった」）：
  - まず計測：サーバはボトルネックではありません（コンテナ内から API 直結で `/data/tiles` **2.6ms**、
    `/data/i18n_zh` **2.7ms**、初回表示の転送量は約 45KB）。コストは**構造**側 —— 6 本の要求が
    揃うまで `init()` が走らず、その間 `#g41-app` は `opacity:0` のままです
  - `#g41-loading` を追加（純 CSS の 5 点リング。JS 到着前の最初のフレームから見え、
    `prefers-reduced-motion` では静止した 5 点に退化）。`endLoading()` は `applyStatus()` の中
    （通常頁とステータスコード頁が同じ経路）、`bootFailed()` はリングを
    「読み込みに失敗しました / Failed to load」＋実際のエラー文に置換 ——
    **回り続けるリングは「まだ読んでいる」という主張で、置き換えた白画面より悪い**
  - 失敗状態は投入直後に**自分自身を捕まえました**：キャッシュなしのコールドスタートが **5/5** で
    `closeDetail is not defined`、頁は `opacity:0` で停止。原因は `tiles.js` が `G41.js` の
    **後ろ**にあり、`G41.js` は実行と同時にデータ要求を始め、その `init()` コールバックが
    `tiles.js` の関数を必要とするため、データが先に返ると ReferenceError になること
    （旧版に失敗状態が無かったので「白画面 + console 一行」に見えていました。感じられた「遅さ」は
    おそらくこれです）
  - 修正：`tiles.js` を `G41.js` の前に移動（トップレベルは関数宣言のみで `G41.js` に依存しない）。
    その後、実機のコールドスタートは **5/5 通過**
  - 判据：ローカルのスタブで `tiles.js` を 3 秒遅らせると、修正前は `is-failed` + ReferenceError +
    appOpacity 0、修正後は同じ条件でリングが消え appOpacity 1・エラーなし。実機はヘッドレス
    chromium（CDP で同一セッションのうちに状態を読んでから画素を取得）で起動・失敗・完了の 3 状態を撮影
- **起動リング第二版（拡大 + 見える文案 + 暗幕）と静的アセットの `Cache-Control`**
  （保守者が手機のスクリーンショットを送信：「読み込みアニメーションが出ない、あるいは目立たない」）：
  - 実測：リングは確かに弱すぎました —— 412×915 で第一版は 64px の環＋6px の点
    （直径は画面幅の 15%、点は 1.4%）。現在は `vmin` でスケール（手機で約 99px / 9px）、
    環の下に**見える**「読み込み中 / Loading」、全体に `rgba(0,0,0,.55)` の暗幕。
    失敗状態は変更なし。文案が可視になったため `.g41-sr` は削除
  - 判据：ローカルのスタブ＋手機ビューポート（412×915 @2.6）で前後比較のスクリーンショット。
    CDP で overlay が (0,0,412,915) を覆い、環＋文案の列がちょうど中央
    （跨度 384–530、中心 457 = 915/2）であることを計測
  - **「古いファイルが配られていた」構造的な原因も修正**：サイトは `Cache-Control` を
    一切送っておらず、ブラウザは `Last-Modified` によるヒューリスティック（10%）を使うため
    「古い HTML と新しい JS/CSS」の混合世代になり得ました。`kits/nginx/store/nginx.conf` の
    server ブロックに `add_header Cache-Control "no-cache" always` を追加。
    実機で `no-cache` が付き、`If-None-Match` が 304 を返すことを確認（再検証は安価）
  - **発見（未修正 —— 直すには pod 再起動が必要。保守者の判断に委ねる）**：
    `kits/nginx/k8s/deployment.yaml` の `reloader` コンテナは ① **volumeMounts が一つも無く**、
    自分のイメージ内のディレクトリを走査するためマウントされた ConfigMap/Secret を見られません
    （`/tmp/.last` は 2026-09-26 で停止）② 仮にマウントしても `kill -HUP 1` は誤ったプロセスを撃ちます
    —— pod は `shareProcessNamespace` を有効にしているので PID 1 は **pause** です。
    結果として `k8s conf` / CD が ConfigMap を再描画しても **nginx は古い設定のまま動き続け**、
    pod の再起動だけが反映します —— 今回は手作業の `kubectl exec … nginx -s reload` で
    `Cache-Control` を反映させました。`k8s/host/g41-cert-reload.sh` の
    「reloader sidecar がホットリロードする」という記述はしたがって誤りです
- **起動リング第三版：五点を一本の鎖に、環をしまう順序、読み込み中は背景を出さない**
  （保守者が同日さらに三点を指摘、スクリーンショット 3 枚付き）：
  - **一本の鎖**：旧実装は各点が keyframes 全体（自分の停止を含む）を走るため、位相は分布を
    保証しても順序を保証しません —— 実測である瞬間の隣接間隔は **96°/282°/81°/147°/114°**
    （二点がほぼ重なる）。「各自が勝手に動いている」は正確な表現でした。現在は五点が同一の回転曲線
    （2.4 秒 / `cubic-bezier(.5,.08,.5,.92)`）を共有し、負の遅延だけが位相をずらします：順序は
    決して崩れず、イージングが弧長を呼吸させ、点径 100/85/70/55/42% が彗星の尾を作ります。
    実測の内部間隔は **38–44°** で単調
  - **環をしまうタイミング**：`main-entry` は以前 `init()` で付いていたため、入場アニメーションが
    `opacity:0` の舞台裏で終わっていました。`revealApp()` に移し、環を先にしまい、
    `requestAnimationFrame` で入場クラスを付けてフェードイン。実機の実測：
    `ring 1 →（0.28 かつ entry:true・tiles:12）→ app 1 → 環が消える`
  - **読み込み中は背景を出さない**：オーバーレイを半透明の暗幕から**不透明な黒**へ
    （WP8 の起動画面はもともと純色）。立ち絵が視線を奪う問題が消えました
  - 判据：ローカルのスタブ＋CDP による定量サンプリング（角度間隔・就緒順序）。
    `--reduced` では `animationName=none`（静止リング）
- **初回表示を splashscreen のように優先：スタイルを全て内聯 + gzip 有効化**
  （保守者：読み込みアニメーションが出る前に長く待たせないで）：
  - 原因を計測：head の 3 つの `<link rel="stylesheet">`（計 15.4KB）が**描画をブロック**しており、
    HTML が届いても白画面のままでした。スタブでスタイルシートを 3 秒遅延させた実測は
    **FCP = 3024 / 6908ms**（＝スタイルシートが届いた瞬間）
  - 三つの CSS を **`G41.html` の `<style>` に全て内聯**（スクリプトで移し、逐バイト一致を自証）。
    `.css` のソースは削除（単一の出所）。同一条件の実測は **FCP = 36 / 928ms**、
    `performance` 上の `/css/` 要求は **0**。CSP は既に `style-src 'self' 'unsafe-inline'` を
    含むため、`<style>` の内聯にポリシー変更は不要
  - **サイトには圧縮が一切ありませんでした**（nginx の既定は off、本倉の nginx.conf に `gzip` 指令なし）：
    `gzip on` / `gzip_vary on` 等を追加。実機実測でホームページ HTML は **19728 → 6873 バイト**
  - デプロイ：`kits add home -C` ＋ 残置した `.wr/G41/css/` を手作業で削除（再インストールは
    ソースが消えた旧ハードリンクを消しません）＋ `kits add nginx -C` ＋ `k8s conf` ＋ `nginx -t`
    ＋ 手作業の `nginx -s reload`（reloader は未修正のまま）
  - 実機実測：ナビゲート後 600ms で起動リングが既に描画（`bg=rgb(0,0,0)`、`css:[]`、FCP 568ms）
  - 計器の落とし穴：`curl -H 'Accept-Encoding: gzip'` は**解凍しません** —— grep に流すとバイナリを
    読むことになり、「外部スタイルシートが残っていないか」の検査は `--compressed` でやり直すまで
    無効でした
- **起動リング v4（点径固定＋進場/回転/退場）と入口文書の `no-store`**（保守者による同日 3 回目の指摘）：
  - **アニメーション構造**：前版の彗星の尾をやめ（点径を段階化しない）、五点は同径。環全体が回転し、
    各点は透明度だけを変え、五点が 0.12 秒ずつずれる → 順に点灯（進場）/ 五点が見えて回転（回転）/
    順に消える（退場）、周期の終わりに短い空白。判据（1 周期のサンプリング）：可視点数の系列
    `5×11 4 2 1 0 0 0 1 2 3 4 5`；点径 `[9,9,9,9,9]` が全て等しい；環の角度は単調；`--reduced` では
    両アニメーションが切れ、五点が静止して全点灯
  - **手機の「刷新」で新版が来ない**（彼女の言葉：ローカルキャッシュを消して初めて新しい環が見えた）：
    `no-cache` は「再検証」を求めるだけですが、モバイルの刷新は再検証を保証しません → 入口文書を
    **`no-store`** に（そもそも保存させない）。実装は `map $uri $g41_cache_control` と
    **サーバーレベル**の `add_header` で、新しい `location` は作りません —— location レベルの
    `add_header` はサーバーレベルのセキュリティヘッダの**継承を打ち切る**ため
    （CSP/HSTS が黙って消えます）。実測：キャッシュを有効にしたまま 2 回続けてナビゲートし、
    どちらも `fromCache:false`・`transferSize 7501`、CSP と HSTS も健在

| コミット | 説明 |
|----------|------|
| `ba86aba` | fix(g41.sh): kits verify の L1/L3/L4 が実行されていなかった。タイル i18n キー網羅を追加 |
| `4435b12` | feat(home): 自己紹介タイル tile_kitsunome（小爪 / キツのめ） |
| `8451fe9` | refactor(tile_gh-proxy): ホームページタイル撤去、依存を nginx に絞る |
| `26afe10` | docs: tile_kitsunome / gh-proxy / kits-spec / AGENTS.md の 3 言語同期 |
| `45b16f0` | fix(g41.sh): kits reload の k8s ターゲット誤り —— api は独立 Deployment ではない |
| `b324278` | fix(tile_kitsunome): 名前の行に つめ（爪）を戻す —— 「狐の目」は私の読み方であり、名前の来歴ではない |
| `e95ac78` | feat(tile_kitsunome): タイルに公開ページへのリンクを追加（3 言語がそれぞれの版を指す） |
| `8b35b39` | feat(home): 初回表示の空白に WP8 起動リングを追加、起動失敗を可視化 |
| `7d3b7b8` | fix(home): コールドスタート白画面の原因は G41.js と tiles.js の読み込み順 |
| `f2d7197` | fix(home): 起動リングを拡大＋見える文案＋暗幕、`Cache-Control: no-cache` を追加 |
| `e243c0c` | fix(home): リング第三版 —— 五点を一本の鎖に、収納タイミング、読み込み中の背景非表示 |
| `cb8cd28` | perf: 初回表示を待たせない —— スタイル全内聯 + nginx gzip 有効化 |
| `923a306` | feat(home): 起動リング v4 —— 点径固定＋進場/回転/退場、入口文書 `no-store` |

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
- **hexo ブログモジュールと attic サービスを削除**（メンテナの要請）：
  - `kits/hexo`（`.hx` データと `.wr/hexo` 静的出力を含む。削除前に VPS の
    `/root/g41-removed-backup/` へバックアップ済み）、`kits/attic`、および attic に
    ハード依存するタイル `kits/tile_attic` を削除。併せてモジュール文書 9 件
  - k8s 側：attic の Deployment/Service、hx Service、hexo-build Job を削除。
    `.gx` に残った site 断片を消して nginx ConfigMap を再レンダリング
    —— さもないと Service 消滅後に upstream `attic:8080` が原因で
    **nginx が起動に失敗**する。Redis の `data:tiles/tile_attic` を削除し
    `data:loaded` を空にして再インポートを発火
  - 同期：compose.yaml、G41_KITS、g41.sh（`k8s hexo` サブコマンドを削除）、
    運用スクリプト 2 本のモジュール一覧、AGENTS.md、README（3 言語）、
    k8s/README.md、kits-spec.md、1gb-stability.md
  - attic の永続ディレクトリ `.attic` は保持（データ未削除、後日復元可能）。
    `docs/*/k8s-migration.md` は歴史的記録として保持
  - 実測：Deployment 7 件すべて Running、サイト 200、`/attic/` → 404、
    `/data/tiles` は 11 件で tile_attic を含まず、タイマー 2 本とも exit 0
- **`tile_friends` フレンドリンクタイルを追加**（12 枚目、ホームのグリッドを補完）：
  - `list` 型タイル。クリックでフレンドリンク一覧を展開。最初の項目は
    「汐霧の霧星パン工房」（`https://shiogiri.com`、相互リンク）
  - 3 言語 i18n + 3 言語ドキュメント + README 展示表の項目
  - 11 → 12 枚：4 列グリッドでちょうど 3 行、6 色 METRO 循環でちょうど 2 巡、欠けなし
- **静かな半故障を 1 件修正**（新タイル追加時のリロードで顕在化）：
  - `kits/redis/k8s/deployment.yaml`：`REDIS_PASSWORD` の secretKeyRef を
    `optional: true` から**必須**へ変更。optional だと `g41-env` にキーが無い場合
    Kubernetes はエラーではなく**空文字列**を注入 → redis が `--requirepass ""` で起動し
    api が認証できず（`NOAUTH HELLO`）、`/data/*` が **502** になるのに Pod は Running のまま。
    実測でこれがデータエンドポイント停止の原因だった。必須化によりキー欠落時は
    Pod が Pending になり明確なエラーが出る。
  - `g41.sh k8s_apply_base`：`.env` に `REDIS_PASSWORD` があるか事前検証し、
    無ければ早期に失敗。キー欠落の Secret を二度と生成しない。
    （`RELOAD_SECRET` は対象外 —— ホットリロード端点のみに影響し独自のエラーがある。）
  - 併せて VPS の `.env` に `REDIS_PASSWORD` を追加（従来欠落、既知の落とし穴）
- 追加後の確認：Pod 7 件すべて Running、新 redis Pod は**再起動 0 回**、
  `/data/tiles` は **12** 件で tile_friends を含み、3 言語 i18n も正常に解決
- **陳腐化した内容を整理し、GC 欠如を修正**（k3s 施設評価中に発見）：
  - **根本原因**：kubelet の image GC は**ディスク使用率が 85% を超えた時のみ**
    発火する（既定閾値）。本機は常時 30% 前後 → GC が一度も走らず、
    孤児スナップショットが無制限に蓄積
  - 実測でイメージ庫が **8.6GB** まで膨張、実際の使用は 2.7GB のみ ——
    **5.9GB が削除済み／切替済みイメージの孤児スナップショット**
  - 修正：`g41-image-update.sh` の末尾に能動的回収を追加
    （`nerdctl system prune`。「コンテナから参照されているか」で判定し
    使用中のイメージは全て保持。`ctr images prune --all` より安全 ——
    後者はタグごと削除し再取得を強いる）
  - 参照ゼロを確認した 7 イメージを明示削除：`tracker:local` 440MB、
    `local-path-provisioner` 85MB、`attic` 83MB、`hexo:local` 79MB、
    `acme:local` 36MB、`stakater/reloader` 15MB、
    `cert-manager-startupapicheck` 14MB、および孤児 digest 参照
  - 残存データを整理：`.rd/data/i18n/tile_attic/`、`.rd/data/tile_apps/hexo.json`
  - **実測**：containerd 8.6GB → **2.7GB**（5.9GB 解放）、ディスク 32G → 26G、
    Pod 7 件は終始 Running。GC は冪等（2 回目は「回収対象なし」）
- **nginx ネイティブ ACME による cert-manager 代替を評価：不可行**、現行機構を維持。
  決定的な阻害要因：`ngx_http_acme_module` の公式文書とソース README がいずれも
  **HTTP-01 のみ対応**と明記。一方われわれの証明書は `*.g41.moe` ワイルドカードを含み、
  RFC 8555 はワイルドカードを **DNS-01 のみ**で検証するよう規定している。
  副次的な問題：追加ドメイン `maidkihara.moe`/`kitsunori.moe` は本機ではなく
  Cloudflare に解決される；本モジュールは k8s Secret を生成せず hy2/dns が証明書源を
  失う；パッケージは nginx 本体バージョンに固定（1.29.8 が必要、本機は 1.31.5）。
  詳細は `docs/zh/nginx-native-acme-assessment.md`
- **ホームのタイルを正面の短名でソートするよう変更**：サーバーは `id` の辞書順
  （`tile_apps`、`tile_friends`…）で返しており、これはユーザーが読む文字とは無関係で
  順序に規則性がなかった。`buildTiles()` の描画前に `label[0]`（タイル正面の短名）で
  ソートするよう変更。欠落時は `label[1]`、さらに `id` へフォールバック。ソートは
  `METRO[idx%6]` の配色決定**より前**に実行し、配色が返却順で揺れないようにした
  - 3 言語で順序が完全に一致することを実測：apps → bilibili → dns → flake → friends →
    github → homete → kihara777 → links → mail → nix → tracker
  - 併せて不適切な英語説明を 2 件修正：`proxy`→`Reverse Proxy`、`resolve`→`DNS Resolver`
  - ⚠️ **落とし穴**：変更は `g41.sh kits add -C` でインストールする必要がある。素の rsync で
    `kits/` のソースを上書きすると inode が置き換わり、**`.wr/G41/`（nginx が実際に配信する
    パス）へのハードリンクが切れる**。「編集したのにサイトが変わらない」という症状になり、
    今回まさにそれで反映済みと誤認した
  - 併せて陳腐化した i18n ディレクトリ 6 件（`apps`/`flake`/`gh-proxy`/`links`/`nix-cache`/
    `tile_homete`、旧モジュール名の残骸）を削除。内容は現行版と**異なり**、ローダーは
    `Object.assign` でマージするため、古い値が現行値と競合していた

| コミット | 説明 |
|----------|------|
| `8fdb78c` | feat(k8s): 証明書配布と週次イメージ更新のタイマーを追加 |
| `031a146` | fix(k8s): 単一ノードのロールアウト欠陥 3 件を修正し文書を更新 |
| `5a8ff40` | feat(k8s): ローカルイメージを containerd ネイティブ経路でビルド（dockerd 不要） |
| `1e164a3` | feat: hexo ブログモジュールと attic サービスを削除 |
| `8e87063` | feat: tile_friends フレンドリンクタイルを追加し 12 枚目を補完 |
| `ba4126e` | docs: nginx ネイティブ ACME による cert-manager 代替を評価（不可行） |
| `c8aa095` | docs: k3s 施設評価を追加 — リソース余力と全量 k3s 移行 |
| `f4fdbc3` | feat(k8s): 週次イメージタスクに GC を追加し孤児スナップショットを回収 |
| `98b6441` | feat(home): タイルを正面の短名でソート |

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