# モジュール仕様

[中文](../zh/module-spec.md) | [English](../en/module-spec.md) | [日本語](module-spec.md)

KITS モジュールシステムのフォーマット定義。

## info.json

```json
{
  "name": "表示名",
  "desc": "一行の説明",
  "depends": ["モジュール", "名"],
  "compose": "none | hub | file",
  "docker": {"service": "svc", "container": "xx"},
  "provides": {...},
  "store": {"src": "ファイル"},
  "webroot": {"target": "provider", "method": "hardlink"},
  "persist": {"dir": ".xx", "survive": true},
  "local": [{"file": "fname", "to": "fname"}]
}
```

### フィールド

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | ✅ | 表示名 |
| `desc` | ✅ | 一行の説明 |
| `depends` | ✅ | 依存モジュール（完全ツリー走査） |
| `compose` | ✅ | `none` / `hub` / `file` |
| `docker` | compose≠none | `service`（compose サービス名）+ `container`（2 文字） |
| `provides` | 基盤モジュール | 公開するディレクトリとファイルタイプ |
| `store` | 永続設定 | 永続ディレクトリに hardlink する設定 |
| `webroot` | web 資産 | プロバイダーターゲットディレクトリ |
| `persist` | 永続状態 | 永続ディレクトリ + `survive` フラグ |
| `local` | デプロイ専用 | `.local/` から hardlink するファイル |

## モジュールタイプ

| タイプ | compose | 内容 | 命名 |
|--------|---------|------|------|
| service | `hub` / `file` | `compose.yaml` | ベア名 |
| tile | `none` | `tile.json` + `i18n/` | `tile_` 接頭辞 |
| link | `none` | `link.json` | `link_` 接頭辞 |
| app | `none` | `app.json` | ベア名 |

## compose モード

| モード | 意味 |
|--------|------|
| `none` | Docker サービスなし |
| `hub` | Docker Hub イメージ（`image: org/img`） |
| `file` | ローカル Dockerfile ビルド（`build: .`） |

## ディレクトリ構造

```
kits/<module>/
├── info.json          # マニフェスト（必須）
├── compose.yaml       # compose≠none
├── Dockerfile         # compose=file
├── tile.json          # タイルエントリ
├── app.json           # アプリエントリ
├── link.json          # 短縮リンクエントリ
├── site/              # nginx 設定
├── i18n/              # ja/zh/en.json
├── store/             # 永続設定
├── webroot/           # web 資産
├── data/              # 静的データ
└── .local/            # デプロイ専用（gitignored）
```

## .local/ デプロイパターン

| `.local/` パス | インストール先 | 用途 |
|----------------|--------------|------|
| `.local/site/*.conf` | `.gx/conf.d/` | プライベート nginx 設定 |
| `.local/webroot/*` | `.wr/` | プライベート web 資産 |
| `.local/<config>` | persist ディレクトリ | ランタイム設定 |

## provides システム

基盤モジュールは `provides` オブジェクトを宣言し、完全な依存ツリーを通じて再帰的に解決。パスはハードコードされない。

## site 読み込み順序

| ファイル | 読み込み位置 | 用途 |
|---------|------------|------|
| `zones/*.conf` | http ブロック | proxy_cache_path |
| `upstreams/*.conf` | http ブロック | upstream 定義 |
| `locations/*.conf` | server ブロック | location ブロック |
| `servers/*.conf` | http ブロック末尾 | バーチャルホスト server ブロック |

## ヘルスチェック

| 優先度 | パターン | 対象 |
|--------|---------|------|
| 1 | `wget http://127.0.0.1:<port>/` | HTTP サービス |
| 2 | `nc -zw1 127.0.0.1 <port>` | TCP サービス |
| 3 | `kill -0 1` | TCP エンドポイントのない Go サービス |

## i18n

3 言語：JA、ZH、EN。タイルとリンクのラベルは翻訳キーとして定義。グローバル i18n は `home` モジュールが提供。