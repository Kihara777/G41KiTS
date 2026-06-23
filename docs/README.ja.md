# G41KiTS

[中文](../README.md) | [English](README.en.md) | [日本語](README.ja.md)

モジュール型セルフホスト Docker Compose スタック — Metro/WP8.1 風ホームページ、Redis 設定 API、多言語 i18n、KITS モジュールシステム。

## デプロイ

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# .env にドメインと Cloudflare 認証情報を記入
./g41.sh kits add -y all
```

### ローカル初期化

`./g41.sh init` は `.local/` ディレクトリを通じてデプロイ専用のホスト設定を注入でき、VPS 情報をリポジトリにコミットせずに済む。

**ディレクトリモード**（推奨）：
```bash
mkdir -p .local
cat <<'EOF' > .local/install.sh
do_init_local() {
  hostnamectl set-hostname myserver
  timedatectl set-timezone Asia/Tokyo
  # UFW、netplan、crontab など
}
EOF
```

**ファイルモード**（旧版互換）：
```bash
cat <<'EOF' > .local.sh
do_init_local() {
  hostnamectl set-hostname myserver
}
EOF
```

両モードとも任意。どちらも存在しない場合、`init` はホスト設定をスキップし、Docker のインストールとコンテナのデプロイのみ実行。

## 基盤

ゲートウェイ、ストレージ、証明書、サイトの骨組みを提供するコアサービス。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| nginx | TLS 1.3 / HTTP/3 ゲートウェイ、全バックエンドへのリバースプロキシ | [docs/ja/nginx.md](ja/nginx.md) |
| redis | Redis 設定ストア + Node.js HTTP API ブリッジ | [docs/ja/redis.md](ja/redis.md) |
| acme | SSL 証明書管理（acme.sh + ZeroSSL/Cloudflare DNS） | [docs/ja/acme.md](ja/acme.md) |
| autoheal | 異常な Docker コンテナの自動再起動 | [docs/ja/autoheal.md](ja/autoheal.md) |
| dsock | Docker API セキュリティプロキシ（docker.sock 直接マウントの代替） | [docs/ja/dsock.md](ja/dsock.md) |
| home | サイトコアデータ — キャラクターメッセージ、テーマカラー、ステータスコード、i18n | [docs/ja/home.md](ja/home.md) |

## サイトサービス

nginx リバースプロキシを通じて公開されるユーザー向けサービス。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| aria2 | 並列ダウンロードマネージャ（WebUI と WebDAV 共有付き） | [docs/ja/aria2.md](ja/aria2.md) |
| blc | Bilibili ライブチャット（AI 翻訳付き） | [docs/ja/blc.md](ja/blc.md) |
| bt | BitTorrent クライアント（WebUI と WebDAV 共有付き） | [docs/ja/bt.md](ja/bt.md) |
| dns | AdGuard 再帰 DNS（DoT/DoH/DoQ 対応） | [docs/ja/dns.md](ja/dns.md) |
| hako | Web ファイルマネージャ（公開 WebDAV 共有付き） | [docs/ja/hako.md](ja/hako.md) |
| hexo | 個人ブログエンジン | [docs/ja/hexo.md](ja/hexo.md) |
| hy2 | Hysteria2 プロキシ（nginx と 443 ポート共有） | [docs/ja/hy2.md](ja/hy2.md) |
| tracker | 軽量 HTTPS BitTorrent トラッカー | [docs/ja/tracker.md](ja/tracker.md) |
| attic | セルフホスト Nix バイナリキャッシュサーバー（atticd） | [docs/ja/attic.md](ja/attic.md) |

## プロキシとミラー

リバースプロキシとキャッシュ高速化サービス。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| gh-proxy | raw.githubusercontent.com のリバースプロキシ | [docs/ja/tile_gh-proxy.md](ja/tile_gh-proxy.md) |
| nix-cache | NixOS バイナリキャッシュミラー — channels、cache、releases | [docs/ja/tile_nix-cache.md](ja/tile_nix-cache.md) |

## ナビゲーション

ホームページタイル、アプリ一覧、短縮リンクシステム。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| apps | アプリ一覧タイル — 全サービスのホームページ入口 | [docs/ja/tile_apps.md](ja/tile_apps.md) |
| links | Redis API 経由の短縮リンクシステム | [docs/ja/tile_links.md](ja/tile_links.md) |
| shortlinks | Redis API 経由の動的短縮リンク | [docs/ja/shortlinks.md](ja/shortlinks.md) |

## 外部ツールリンク

外部ダウンロードを指すホームページ上の静的リンクタイル（Docker サービスなし）。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| 7zip | 高圧縮ファイルアーカイバ | [docs/ja/link_7zip.md](ja/link_7zip.md) |
| dotnet | Microsoft .NET 開発フレームワーク | [docs/ja/link_dotnet.md](ja/link_dotnet.md) |
| dx11 | 旧バージョン DirectX エンドユーザーランタイム | [docs/ja/link_dx11.md](ja/link_dx11.md) |
| vcredist | Visual C++ 再頒布可能パッケージ | [docs/ja/link_vcredist.md](ja/link_vcredist.md) |
| vs | Visual Studio Community IDE | [docs/ja/link_vs.md](ja/link_vs.md) |
| vscode | Visual Studio Code エディタ | [docs/ja/link_vscode.md](ja/link_vscode.md) |

## ショーケース

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| flake | 個人 Nix flake リポジトリ — カスタムパッケージ、overlay、NixOS モジュール | [docs/ja/tile_flake.md](ja/tile_flake.md) |
| bilibili | Bilibili スペース — バーチャル配信者紹介 | [docs/ja/tile_bilibili.md](ja/tile_bilibili.md) |
| attic | Attic Nix バイナリキャッシュ利用ガイド | [docs/ja/tile_attic.md](ja/tile_attic.md) |
| mail | MailKits — Cloudflare Email Workers 透過メールプロキシ | [docs/ja/tile_mail.md](ja/tile_mail.md) |
| kihara777 | GitHub プロフィール — プロジェクト、貢献、連絡先 | [docs/ja/tile_kihara777.md](ja/tile_kihara777.md) |

## 仕様

| 説明 | ドキュメント |
|------|-------------|
| KITS モジュールシステム完全定義 | [kits/README.md](../kits/README.md) |
| サードパーティ資産に関する声明 | [NOTICE.md](NOTICE.ja.md) |
| メンテナンス記録 | [MAINTENANCE.md](MAINTENANCE.ja.md) |
| エージェントガイド（アーキテクチャ、モジュールシステム、開発ワークフロー） | [AGENTS.md](../AGENTS.md) |

## 作者

- **狐莉 (キツのり)** — 作成と保守
- **小爪 (キツのめ)** — 設計・開発 feat. deepseek-v4-pro (Max)


## ライセンス

[MIT](../LICENSE)