# KITS モジュール仕様

[中文](../zh/kits-spec.md) | [English](../en/kits-spec.md) | [日本語](kits-spec.md)

G41KiTS のモジュールシステム規約、`info.json` フィールドスキーマ、ディレクトリ構成を定義。

## info.json フィールド

| フィールド | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `name` | string | ✅ | 表示名 |
| `desc` | string | ✅ | 説明 |
| `depends` | string[] | ✅ | 依存チェーン、全ツリー解決 |
| `compose` | enum | ✅ | `none` / `hub` / `file` |
| `docker` | object | compose≠none | `service` 名と `container`（2 文字） |
| `provides` | object | 基盤モジュール | 依存先に公開するディレクトリとファイル種別 |
| `store` | object | 永続化設定 | `store/` から hardlink |
| `webroot` | object | web アセット | `target` プロバイダと `method`（`hardlink`） |
| `persist` | object | 永続化状態 | `dir` と任意の `survive` フラグ |
| `local` | object[] | デプロイファイル | `.local/` から persist ディレクトリへ hardlink |

## モジュール種別

| 種別 | compose | ファイル | 命名 |
|------|---------|---------|------|
| service | `hub`/`file` | compose.yaml（+Dockerfile） | 裸名 |
| tile | `none` | tile.json + i18n/ | `tile_` プレフィックス |
| link | `none` | link.json | `link_` プレフィックス |
| app | `none` | app.json | 裸名 |

## compose モード

| モード | 意味 | 断片 |
|------|------|------|
| `none` | Docker サービスなし | compose.yaml なし |
| `hub` | Docker Hub から取得 | `image: org/img` |
| `file` | Dockerfile からビルド | `build: .` |

## コンテナ命名

`docker.container` は 2 文字略称：

| コンテナ | モジュール |
|---------|----------|
| gx | nginx |
| rd | redis |
| ah | autoheal |
| ca | acme |
| ds | dsock |
| lc | blc |
| ns | dns |
| fb | hako |
| hx | hexo |
| hq | hy2 |
| tr | bt |
| ad | aria2 |
| wt | tracker |
| ra | redis API |

## ディレクトリ構成

```
kits/<module>/
├── info.json          # マニフェスト（必須）
├── compose.yaml       # Docker Compose 断片（compose≠none）
├── Dockerfile         # ビルド（compose=file）
├── tile.json          # ホームページタイル
├── app.json           # アプリ一覧
├── link.json          # 短縮リンク
├── site/              # nginx 設定断片
│   ├── zone.conf      # proxy_cache_path
│   ├── upstream.conf  # upstream ブロック
│   ├── server.conf    # 完全な server ブロック
│   └── location.conf  # location ブロック
├── i18n/              # 翻訳（ja/zh/en）
├── store/             # 設定ファイル
├── webroot/           # web アセット
├── data/              # 静的データ
└── .local/            # デプロイ専用ファイル（gitignored）
```

## .local/ デプロイパターン

| .local/ パス | インストール先 | 用途 |
|-------------|-------------|------|
| `.local/site/*.conf` | `.gx/conf.d/` | プライベート nginx 設定 |
| `.local/webroot/*` | `.wr/` | プライベート web アセット |
| `.local/<config>` | persist ディレクトリ | ランタイム設定 |

## site ロード順

| ファイル | 段階 | 用途 |
|---------|------|------|
| `zones/*.conf` | http ブロック | cache/limit 定義 |
| `upstreams/*.conf` | http ブロック | upstream 定義 |
| `locations/*.conf` | server ブロック | location ブロック |
| `servers/*.conf` | http ブロック | 仮想ホスト server ブロック |

## ヘルスチェック

| 優先度 | パターン | 用途 |
|--------|---------|------|
| 1 | `wget http://127.0.0.1:<port>/` | HTTP サービス |
| 2 | `nc -zw1 127.0.0.1 <port>` | TCP サービス |
| 3 | `kill -0 1` | TCP エンドポイントなし |

Node.js サービスでは `kill -0 1` 禁止。

## イメージバージョン

- `FROM alpine` — `FROM alpine:latest` 禁止
- `FROM node:alpine` — `FROM node:lts-alpine` 禁止
- compose `image:` でフローティングタグ禁止
- リモート URL に `ADD --checksum=sha256:`
- npm に `npm install -g <pkg>@<version>`

## i18n

3 言語：JA / ZH / EN。タイルとリンクラベルは翻訳キー使用。グローバル i18n は `home` モジュールが提供。API エンドポイント：`/data/i18n_ja|zh|en`。
