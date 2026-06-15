# G41KiTS

[中文](../README.md) | [English](README.en.md) | [日本語](README.ja.md)

モジュラー自ホスト Docker Compose スタック — Metro/WP8.1 スタイルホームページ、Redis 設定 API、多言語 i18n、KITS モジュールシステム。

## デプロイ

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# .env にドメインと Cloudflare 認証情報を記入
./g41.sh kits add -y all
```

## インフラ

ゲートウェイ、ストレージ、証明書、サイト骨格を提供するコアサービス。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| nginx | TLS 1.3 / HTTP/3 ゲートウェイ、全バックエンドのリバースプロキシ | [docs/ja/nginx.md](ja/nginx.md) |
| redis | Redis 設定ストア + Node.js HTTP API ブリッジ | [docs/ja/redis.md](ja/redis.md) |
| acme | SSL 証明書管理（acme.sh + ZeroSSL/Cloudflare DNS） | [docs/ja/acme.md](ja/acme.md) |
| autoheal | 異常な Docker コンテナの自動再起動 | [docs/ja/autoheal.md](ja/autoheal.md) |
| dsock | Docker API セキュアプロキシ（docker.sock 直接マウントの代替） | [docs/ja/dsock.md](ja/dsock.md) |
| home | サイトコアデータ — キャラクターメッセージ、テーマ、ステータスコード、i18n | [docs/ja/home.md](ja/home.md) |

## サイトサービス

nginx リバースプロキシを通じて公開されるユーザー向け機能サービス。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| aria2 | 並列ダウンロードマネージャー（WebUI と WebDAV 共有付き） | [docs/ja/aria2.md](ja/aria2.md) |
| blc | Bilibili ライブチャット（AI 翻訳付き） | [docs/ja/blc.md](ja/blc.md) |
| bt | BitTorrent クライアント（WebUI と WebDAV 共有付き） | [docs/ja/bt.md](ja/bt.md) |
| dns | AdGuard 再帰 DNS（DoT/DoH/DoQ 対応） | [docs/ja/dns.md](ja/dns.md) |
| hako | Web ファイルマネージャー（公開 WebDAV 共有付き） | [docs/ja/hako.md](ja/hako.md) |
| hexo | 個人ブログエンジン | [docs/ja/hexo.md](ja/hexo.md) |
| hy2 | Hysteria2 プロキシ（nginx と 443 ポートを共有） | [docs/ja/hy2.md](ja/hy2.md) |
| tracker | 軽量 HTTPS BitTorrent トラッカー | [docs/ja/tracker.md](ja/tracker.md) |

## プロキシとミラー

リバースプロキシとキャッシュ高速化サービス。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| tile_gh-proxy | raw.githubusercontent.com リバースプロキシ | [docs/ja/tile_gh-proxy.md](ja/tile_gh-proxy.md) |
| tile_nix-cache | NixOS バイナリキャッシュミラー — channels、cache、releases | [docs/ja/tile_nix-cache.md](ja/tile_nix-cache.md) |

## ナビゲーションとエントリ

ホームページタイル、アプリ一覧、短縮リンクシステム。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| tile_apps | アプリ一覧タイル — 全サービスのホームページ入口 | [docs/ja/tile_apps.md](ja/tile_apps.md) |
| tile_links | 短縮リンクタイル（Redis API プロキシ経由） | [docs/ja/tile_links.md](ja/tile_links.md) |
| shortlinks | 動的短縮リンク（Redis API プロキシ経由） | [docs/ja/shortlinks.md](ja/shortlinks.md) |

## 外部ツールリンク

外部ダウンロードを指すホームページ上の静的リンクタイル（Docker サービスなし）。

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| link_7zip | 高圧縮ファイルアーカイバー | [docs/ja/link_7zip.md](ja/link_7zip.md) |
| link_dotnet | Microsoft .NET 開発フレームワーク | [docs/ja/link_dotnet.md](ja/link_dotnet.md) |
| link_dx11 | レガシー DirectX エンドユーザーランタイム | [docs/ja/link_dx11.md](ja/link_dx11.md) |
| link_vcredist | Visual C++ 再配布可能パッケージ | [docs/ja/link_vcredist.md](ja/link_vcredist.md) |
| link_vs | Visual Studio Community IDE | [docs/ja/link_vs.md](ja/link_vs.md) |
| link_vscode | Visual Studio Code エディター | [docs/ja/link_vscode.md](ja/link_vscode.md) |

## ショーケース

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| tile_flake | 個人 Nix flake リポジトリ — カスタムパッケージ、overlay、NixOS モジュール | [docs/ja/tile_flake.md](ja/tile_flake.md) |
| tile_bilibili | Bilibili プロフィール — VTuber 紹介 | [docs/ja/tile_bilibili.md](ja/tile_bilibili.md) |

## 作者

- **狐莉（キツのり）** — 作成・保守
- **小爪（キツのめ）** — 設計・開発 feat. deepseek-v4-pro (Max)
- **小小爪（キツのめ）** — ハードウェア推論インフラ feat. llama-cpp-rocm

## ライセンス

[MIT](../LICENSE)