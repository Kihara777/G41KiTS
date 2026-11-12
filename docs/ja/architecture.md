# G41KiTS アーキテクチャ概観
[中文](../zh/architecture.md) | [English](../en/architecture.md) | 日本語 

**モジュールが宣言から本番へどう流れるか、どのパイプラインが運ぶか、各パイプラインの唯一の出所は何か、
判定がどこにあるか**を一枚で示す。

フィールド単位の詳細は [kits-spec.md](kits-spec.md)、移行の経緯は
[k8s-migration.md](k8s-migration.md) を参照。

## 一言で

リポジトリが唯一の出所であり、ホスト側に「もう一つの内容」は無い。下流の生成物はすべて
`kits/` から一方向に生成され、ConfigMap・containerd・クラスタのマニフェストのいずれかに落ちる。

## モジュールとは

```
kits/<名前>/
├── info.json          宣言
├── tile.json          ┐
├── app.json           │ 内容ファイル（どのパイプラインを通るかは provider の provides が決める）
├── link.json          │
├── i18n/<lang>.json   │
├── data/<name>.json   ┘
├── k8s/*.yaml         クラスタのマニフェスト（これがあるモジュールだけが配備される）
├── store/             実行ディレクトリへ hardlink するファイル（一部のモジュール）
└── .local/            配備固有のファイル（コミットしない）
```

## 四つのパイプライン

```
                      ┌──────────────────────────────────────────────┐
   kits/*/info.json   │  リポジトリが唯一の出所                       │
   + 内容ファイル       └──────────────────────────────────────────────┘
          │
          ├──(1) kits content ──→ dist/g41-content.yaml ──apply──→ ConfigMap g41-content
          │        │             （種別 → ディレクトリの対応を _map.json として同梱）
          │        │                                                  │
          │        │                                                  ▼
          │        │                                    redis Pod: /seed ボリューム
          │        │                                                  │
          │        │                                     loader が展開 → Redis へ書き込み
          │        │                                                  │
          │        │                                                  ▼
          │        │                                                フロントエンド
          │        │
          ├──(2) kits api-src ──→ dist/g41-api-src.yaml ──apply──→ ConfigMap g41-api-src
          │                                                          │
          │                                            redis Pod: /app/server.js
          │
          ├──(3) g41-image-build.sh ──→ containerd: g41k8s/<モジュール>:<バージョン>（+:local 別名）
          │
          └──(4) kits export <モジュール> ──→ dist/<モジュール>-<バージョン>.yaml ──kubectl apply──→ クラスタ

  読み込みの条件：Redis に `data:loaded` が無いときだけ読み込む。内容やソースを変えたら
  `DEL data:loaded` してから redis Pod を再起動する——そうしないと Pod は再起動しても
  **読み込み直さない**。
```

## 種別と配置先は provider が決める

モジュールの種別はファイル名ではなく、**何に依存しているか**と、その provider が何を受け取ると
宣言しているかで決まる。

```
home/info.json:
  provides: [{dir:"tiles", accepts:["tile"], file:"tile.json", ext:"json", content:true},
             {dir:"i18n",  accepts:["i18n"], file:"i18n",     ext:"json", content:true}]

kits/tile_friends/   home に依存し tile.json と i18n/ を持つ → tile と i18n の消費者
kits/dns/            tile.json を持ち home に依存 → 同上
```

`kits content` が導いた対応表をシードと一緒に配布する：

```
_map.json = { "tile": {dir:"tiles",  file:"tile.json", ext:"json", shape:"file"},
              "i18n": {dir:"i18n",   file:"i18n",      ext:"json", shape:"dir"},
              "app":  {dir:"tile_apps",  ...}, "link": {dir:"tile_links", ...},
              "data": {dir:"",       ...} }        ← 空の dir は Redis のデータルート

loader の書き側も読み側もこの表を使う——片側だけ変えると「配置は成功したが読めない」になる。
```

`content: true` は「この種別は内容シードを通る」の意。`site`（nginx 設定）、`webroot`（静的資産）、
`blc_template` には印が無く、それぞれ独自の供給経路を持つ。

## リポジトリから本番まで

```
git push
   │
   ├─ GitHub Actions: check.yml（ゲート 21 項、本番には触れない）
   └─ GitHub Actions: deploy.yml
        ├─ ガード：HEAD == origin/main か（異なれば拒否——滞留した古い run が本番を巻き戻さないため）
        ├─ 配備機へ rsync
        ├─ kits content → apply g41-content
        ├─ kits api-src → apply g41-api-src
        └─ k8s apply --all
```

イメージはこの線上に無い：**自前イメージは配備機の containerd にしか無く**、
`/opt/g41/k8s/host/g41-image-build.sh` で構築する（引数なし＝配備済みの全モジュール）。これが復旧経路。

## コマンド一覧

| コマンド | 何をするか | いつ使うか |
|----------|-----------|-----------|
| `kits install <m>` | 検証 → イメージ構築 → シード/ソース更新 → バンドル → apply（依存も導入） | モジュールを一つ入れる |
| `kits uninstall <m>` | オブジェクト削除 + シードから除外（逆依存があれば拒否） | モジュールを一つ外す |
| `kits update <m> --to <v> --build` | バージョン変更 + ビルド + バンドル | 更新 |
| `kits rollback <m>` | `dist/` にある旧バンドルへ戻す | 障害時の切り戻し（**クラスタのみ。リポジトリも直す**） |
| `kits status [--cluster]` | 台帳：バージョン / Pod グループ / イメージ / コンテンツキー | 「いま何が入っているか」 |
| `kits health` | 五項目の点検 | 「本番とリポジトリが一致しているか」 |
| `kits images --verify` | マニフェスト参照のタグが containerd にあるか | apply の前に |
| `kits remote <url>` | 外部 URL からマニフェストを一つ導入 | 外部拡張の導入 |

k8s バックエンドでは `kits add` / `kits del` は `install` / `uninstall` へ**転送**される——
元のホスト組み立て経路には k8s での消費者が無い。

## 判定はどこにあるか

| 判定 | 場所 | 何を実行するか | 失敗の意味 |
|------|------|----------------|-----------|
| ゲート 21 項 | GitHub Actions（push ごと） | 構文、マニフェスト schema、内容シードのバイト一致復元、イメージタグとバージョンの一致、ConfigMap 参照の閉包、README と点検の自己テスト | このコミットは統合すべきでない |
| loader 自己テスト 32 項 | コンテナ内（`G41_FS_SELFTEST=1`） | シードキー解析、マップ駆動、期限切れキー判定、readDir の絞り込み | loader のロジックが壊れている |
| 本番点検 5 項 | 配備機、6 時間ごと（`g41-health.timer`） | イメージの存在、drift、内容シードとリポジトリのキー単位一致、api ソースの一致、サイトが 200 | 本番とリポジトリが分岐；**状態が変わったときだけ通知** |
| 三状態の規約 | すべての判定 | 0 通過 / 1 失敗 / 2 検証できなかった | 2 は通過ではない |

## 既知の限界

1. **新しい種別には依然コードが要る**：`_map` は「どこへ置くか」をデータにしたが、loader の意味論
   （tile は一覧項目、i18n は言語ごとにマージ）は種別名で分岐する。これは ConfigMap 化以前からの性質。
2. **`dir` は Redis のキー名前空間でもある**：`tile_apps` の `dir` を変えるとキー名も変わり、
   フロントエンドが認識しなくなる。「provider が決めた場所へ」はキー空間の外でのみ成立する。
3. **イメージレジストリが無い**：配備機の containerd にしか無い。git から再構築できるが遠隔複製は無い。
4. **`kits add all` は遅い**：25 モジュールがそれぞれ verify + export を走るため分単位。
