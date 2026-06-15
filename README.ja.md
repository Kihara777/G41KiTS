# G41KiTS

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md)

モジュラー型セルフホスト Docker Compose スタック — Metro/WP8.1 スタイルのホームページ、Redis 設定 API、多言語 i18n、KITS モジュールシステム。

## デプロイ

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# .env を編集してドメインと Cloudflare 認証情報を設定
./g41.sh kits add -y all
```

## インフラストラクチャ

ゲートウェイ、ストレージ、証明書、サイト基盤を提供するコアサービス。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| nginx | TLS 1.3 / HTTP/3 ゲートウェイ、全バックエンドへのリバースプロキシ | [docs/ja/nginx.md](docs/ja/nginx.md) |
| redis | Redis 設定ストア + Node.js HTTP API ブリッジ | [docs/ja/redis.md](docs/ja/redis.md) |
| acme | SSL 証明書管理（acme.sh + ZeroSSL/Cloudflare DNS） | [docs/ja/acme.md](docs/ja/acme.md) |
| autoheal | 異常な Docker コンテナの自動再起動 | [docs/ja/autoheal.md](docs/ja/autoheal.md) |
| home | サイトコアデータ — キャラクターメッセージ、テーマカラー、ステータスコード、i18n | [docs/ja/home.md](docs/ja/home.md) |

## サイトサービス

nginx リバースプロキシ経由で公開されるユーザー向け機能サービス。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| aria2 | 並列ダウンロードマネージャー、WebUI と WebDAV 共有付き | [docs/ja/aria2.md](docs/ja/aria2.md) |
| blc | Bilibili ライブチャット、AI 翻訳付き | [docs/ja/blc.md](docs/ja/blc.md) |
| bt | BitTorrent クライアント、WebUI と WebDAV 共有付き | [docs/ja/bt.md](docs/ja/bt.md) |
| dns | AdGuard 再帰 DNS、DoT/DoH/DoQ 対応 | [docs/ja/dns.md](docs/ja/dns.md) |
| hako | Web ファイルマネージャー、公開 WebDAV 共有付き | [docs/ja/hako.md](docs/ja/hako.md) |
| hexo | 個人ブログエンジン | [docs/ja/hexo.md](docs/ja/hexo.md) |
| hy2 | Hysteria2 プロキシ、nginx と 443 ポート共有 | [docs/ja/hy2.md](docs/ja/hy2.md) |
| tracker | 軽量 HTTPS BitTorrent トラッカー | [docs/ja/tracker.md](docs/ja/tracker.md) |

## プロキシとミラー

リバースプロキシとキャッシュ高速化サービス。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| gh-proxy | raw.githubusercontent.com のリバースプロキシ | [docs/ja/gh-proxy.md](docs/ja/gh-proxy.md) |
| nix-cache | NixOS バイナリキャッシュミラー — channels、cache、releases | [docs/ja/nix-cache.md](docs/ja/nix-cache.md) |

## ナビゲーション

ホームページタイル、アプリ一覧、ショートリンクシステム。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| apps | アプリ一覧タイル — 全サービスのホームページ入口 | [docs/ja/apps.md](docs/ja/apps.md) |
| links | ショートリンクシステム、Redis API 経由でプロキシ | [docs/ja/links.md](docs/ja/links.md) |
| shortlinks | 動的ショートリンク、Redis API 経由でプロキシ | [docs/ja/shortlinks.md](docs/ja/shortlinks.md) |

## 外部ツールリンク

ホームページ上の外部ダウンロードへの静的リンクタイル（Docker サービスなし）。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| 7zip | 高圧縮ファイルアーカイバー | [docs/ja/7zip.md](docs/ja/7zip.md) |
| dotnet | Microsoft .NET 開発フレームワーク | [docs/ja/dotnet.md](docs/ja/dotnet.md) |
| dx11 | レガシー DirectX エンドユーザーランタイム | [docs/ja/dx11.md](docs/ja/dx11.md) |
| vcredist | Visual C++ 再配布可能パッケージ | [docs/ja/vcredist.md](docs/ja/vcredist.md) |
| vs | Visual Studio Community IDE | [docs/ja/vs.md](docs/ja/vs.md) |
| vscode | Visual Studio Code エディター | [docs/ja/vscode.md](docs/ja/vscode.md) |

## ショーケース

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| flake | 個人 Nix flake リポジトリ — カスタムパッケージ、overlay、NixOS モジュール | [docs/ja/flake.md](docs/ja/flake.md) |

## スキル

AI コーディングアシスタント向け操作ガイド。

| スキル | 説明 | ドキュメント |
|-------|------|-------------|
| module-system | info.json スキーマ、インストール機構、規約、操作コマンドリファレンス | [docs/ja/skills/module-system.md](docs/ja/skills/module-system.md) |
| env-config | .env 設定管理 | [docs/ja/skills/env-config.md](docs/ja/skills/env-config.md) |
| deploy-site | サイトデプロイワークフロー | [docs/ja/skills/deploy-site.md](docs/ja/skills/deploy-site.md) |
| init-server | 新規サーバー初期化 | [docs/ja/skills/init-server.md](docs/ja/skills/init-server.md) |
| health-check | サービスヘルスチェック | [docs/ja/skills/health-check.md](docs/ja/skills/health-check.md) |
| diagnose-api | API コンテナ診断、タイルレンダリング障害、設定データ再読み込み | [docs/ja/skills/diagnose-api.md](docs/ja/skills/diagnose-api.md) |
| fix-nginx | nginx クラッシュループ診断 | [docs/ja/skills/fix-nginx.md](docs/ja/skills/fix-nginx.md) |
| manage-certs | SSL 証明書管理 | [docs/ja/skills/manage-certs.md](docs/ja/skills/manage-certs.md) |
| add-domain | 新規ドメイン追加 | [docs/ja/skills/add-domain.md](docs/ja/skills/add-domain.md) |
| add-content | コンテンツモジュール追加（タイル、i18n） | [docs/ja/skills/add-content.md](docs/ja/skills/add-content.md) |
| add-docker-service | Docker サービスモジュール追加 | [docs/ja/skills/add-docker-service.md](docs/ja/skills/add-docker-service.md) |
| kits-simulate-install | インストールシミュレーション、インストール計画のプレビュー | [docs/ja/skills/kits-simulate-install.md](docs/ja/skills/kits-simulate-install.md) |
| manage-i18n | 多言語翻訳管理 | [docs/ja/skills/manage-i18n.md](docs/ja/skills/manage-i18n.md) |
| backup-restore | バックアップと復元 | [docs/ja/skills/backup-restore.md](docs/ja/skills/backup-restore.md) |
| archive-packages | アーカイブパッケージのビルド | [docs/ja/skills/archive-packages.md](docs/ja/skills/archive-packages.md) |
| configure-hexo | Hexo ブログ設定 | [docs/ja/skills/configure-hexo.md](docs/ja/skills/configure-hexo.md) |
| clean-stale-files | 古いファイルのクリーンアップ | [docs/ja/skills/clean-stale-files.md](docs/ja/skills/clean-stale-files.md) |
| migrate-config | 設定移行 | [docs/ja/skills/migrate-config.md](docs/ja/skills/migrate-config.md) |
| rename-dir | ディレクトリ名変更 | [docs/ja/skills/rename-dir.md](docs/ja/skills/rename-dir.md) |
| force-recreate-container | コンテナの強制再作成 | [docs/ja/skills/force-recreate-container.md](docs/ja/skills/force-recreate-container.md) |
| troubleshoot-dns | DNS トラブルシューティング | [docs/ja/skills/troubleshoot-dns.md](docs/ja/skills/troubleshoot-dns.md) |
| update-chars | キャラクターメッセージの更新 | [docs/ja/skills/update-chars.md](docs/ja/skills/update-chars.md) |
| add-mihomo-rule | Mihomo ルール追加 | [docs/ja/skills/add-mihomo-rule.md](docs/ja/skills/add-mihomo-rule.md) |

## 作者

- **狐莉 (キツのり)** — 作成とメンテナンス
- **小爪 (キツのめ)** — 設計・開発 feat. deepseek-v4-pro (Max)
- **小小爪 (キツのめ)** — ハードウェア推論インフラ feat. llama-cpp-rocm: Qwen3.6-27B-MTP (UD-Q4_K_XL) · Qwen3.6-35B-A3B-MTP (UD-Q4_K_XL) · Qwen3.5-122B-A10B-MTP (UD-Q4_K_XL) · Qwen3-Coder-Next (UD-Q4_K_XL) · MiniMax-M2.7 (UD-Q2_K_XL)

## ライセンス

[MIT](LICENSE)
