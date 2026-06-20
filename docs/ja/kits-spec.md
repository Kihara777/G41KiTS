# KITS Module Specification

[中文](../kits/README.md) | [English](../en/kits-spec.md) | [日本語](kits-spec.md)

モジュールは `info.json` マニフェストと、オプションのサービス定義、静的ファイル、nginx 設定、翻訳を含むディレクトリです。全モジュールは `kits/<module>/` の下に配置されます。

## info.json スキーマ

```json
{
  "name": "Human-readable name",
  "desc": "One-line description",
  "depends": ["module", "names"],
  "compose": "none | hub | file",
  "docker": {"service": "svc", "container": "xx"},
  "provides": { ... },
  "store": { "src": "files to hardlink" },
  "webroot": { "target": "provider", "method": "hardlink" },
  "persist": {"dir": ".xx", "survive": true},
  "local": [{"file": "fname", "to": "fname"}]
}
```

### フィールド

| フィールド | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `name` | string | ✅ | 表示名 |
| `desc` | string | ✅ | 一行説明（`./g41.sh kits` UI 下部に表示） |
| `depends` | string[] | ✅ | 依存モジュール。**完全ツリー走査**で解決 |
| `compose` | enum | ✅ | `none` / `hub` / `file` |
| `docker` | object | compose≠none で必須 | `service`（compose サービス名）と `container`（2 文字略称） |
| `provides` | object | 基盤モジュールで必須 | 依存モジュール向けの公開ディレクトリとファイルタイプ |
| `store` | string/object | 永続設定がある場合 | `store/` から hardlink される設定ファイル |
| `webroot` | object | web 資産がある場合 | `target`（provides ターゲット）と `method`（通常 `hardlink`） |
| `persist` | object | compose≠none かつ永続状態がある場合 | `dir`（例: `.rd`）とオプションの `survive` フラグ |
| `local` | object[] | デプロイ専用ファイルがある場合 | `.local/` から persist ディレクトリへ hardlink |

## モジュールタイプ

| タイプ | compose | 内容 | 命名 |
|--------|---------|------|------|
| **service** | `hub` または `file` | `compose.yaml`（+ compose=file の場合は `Dockerfile`） | ベア名（`nginx`, `aria2`） |
| **tile** | `none` | `tile.json` + `i18n/` | `tile_` 接頭辞（`tile_apps`, `tile_flake`） |
| **link** | `none` | `link.json` | `link_` 接頭辞（`link_7zip`, `link_vscode`） |
| **app** | `none` | `app.json` | ベア名（`blc`, `bt`） |

## compose モード

| モード | 意味 | Docker Compose スニペット |
|--------|------|--------------------------|
| `none` | Docker サービスなし | `compose.yaml` なし |
| `hub` | Docker Hub からイメージ取得 | `image: org/img:v1.2.3` |
| `file` | ローカル Dockerfile からビルド | `build: .`（`image:` なし） |

## コンテナ命名

`docker.container` フィールドは **2 文字略称** を使用：

| コンテナ | モジュール |
|---------|-----------|
| `gx` | nginx |
| `rd` | redis |
| `ah` | autoheal |
| `ca` | acme |
| `ds` | dsock |
| `lc` | blc |
| `ns` | dns |
| `fb` | hako |
| `hx` | hexo |
| `hq` | hy2 |
| `tr` | bt |
| `ad` | aria2 |
| `wt` | tracker |
| `ra` | redis API（redis compose の一部として実行） |

## ディレクトリ構造

```
kits/<module>/
├── info.json          # マニフェスト（必須）
├── compose.yaml       # Docker Compose 断片（compose≠none）
├── Dockerfile         # ビルドファイル（compose=file）
├── tile.json          # ホームページタイルエントリ
├── app.json           # アプリ一覧エントリ
├── link.json          # 短縮リンクエントリ
├── site/              # nginx 設定断片
│   ├── zone.conf      # proxy_cache_path / limit_req_zone
│   ├── upstream.conf  # upstream ブロック
│   ├── server.conf    # 仮想ホスト用フル server ブロック
│   └── location.conf  # location ブロック
├── i18n/              # 翻訳（tile/link の場合）
│   ├── ja.json
│   ├── zh.json
│   └── en.json
├── store/             # 設定ファイル（永続ディレクトリへ hardlink）
├── webroot/           # web 資産（プロバイダーターゲットへ hardlink）
├── data/              # 静的データファイル（Redis に読み込み）
└── .local/            # デプロイ専用ファイル（gitignored）
    ├── site/          # 隠し nginx 設定
    ├── webroot/       # プライベート web 資産
    └── <config>       # ランタイム設定（hy2 の hysteria.yaml など）
```

## `.local/` デプロイパターン

サーバー上に存在するが **コミットしてはならない** ファイルのための仕組み：

| `.local/` パス | インストール先 | 用途 |
|----------------|-------------|------|
| `.local/site/*.conf` | `.gx/conf.d/` | プライベート nginx 設定 |
| `.local/webroot/*` | `.wr/` | プライベート web 資産 |
| `.local/<config>` | persist ディレクトリ | 認証情報を含むランタイム設定 |

## provides システム

基盤モジュールは `provides` オブジェクトを宣言し、完全な依存ツリーを通じて再帰的に解決されます。パスはハードコードされません。

## site 読み込み順序

nginx 設定断片はファイル名の数値プレフィックス順に読み込まれます。

## ヘルスチェック

`compose.yaml` のヘルスチェックは以下の優先順位に従います：

| 優先度 | パターン | 対象 |
|--------|---------|------|
| 1 | `wget -q -O /dev/null http://127.0.0.1:<port>/` | HTTP サービス |
| 2 | `nc -zw1 127.0.0.1 <port>` | TCP 専用サービス |
| 3 | `kill -0 1` | TCP エンドポイントのない Go サービス |

## i18n

3 言語: **JA, ZH, EN**。タイルとリンクのラベルは翻訳キーとして定義。グローバル i18n は `home` モジュールが提供。