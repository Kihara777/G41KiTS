# G41KiTS

[中文](../../README.md) | [English](../README.en.md) | [日本語](../README.ja.md) | [ｶﾀﾘｯｼｭ](../katalish/README.md) | 偽中国語

部品型セルフホスト Docker Compose スタック — Metro/WP8.1 風ホームページ、Redis 設定 API、多言語 i18n、KITS 部品体系。

## デプロイ

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# .env にドメインと Cloudflare 認証情報を記入
./g41.sh kits add -y all
```

### ローカル初期化

`./g41.sh init`  `.local/` ディレクトリ通じてデプロイ専用之ホスト設定注入以き、VPS 情報リポジトリ於コミットせず於済む。

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

**書類モード**（旧版互換）：
```bash
cat <<'EOF' > .local.sh
do_init_local() {
  hostnamectl set-hostname myserver
}
EOF
```

両モード與も任意。どちらも存在し場合、`init` ホスト設定スキップし、Docker 之導入與コンテナ之デプロイ之み実行。

## 基盤

関門、貯蔵、証明書、サイト之骨組み提供コア服務。

| 部品 | 説明 | ドキュメント |
|-----------|------|-------------|
| nginx | TLS 1.3 / HTTP/3 関門、全バックエンドへ之リバース代理 | [docs/ja/nginx.md](ja/nginx.md) |
| redis | Redis 設定ストア + Node.js HTTP API ブリッジ | [docs/ja/redis.md](ja/redis.md) |
| acme | SSL 証明書管理（acme.sh + ZeroSSL/Cloudflare DNS） | [docs/ja/acme.md](ja/acme.md) |
| autoheal | 異常な Docker コンテナ之自動再起動 | [docs/ja/autoheal.md](ja/autoheal.md) |
| dsock | Docker API セキュリティ代理（docker.sock 直接マウント之代替） | [docs/ja/dsock.md](ja/dsock.md) |
| home | サイトコアデータ — キャラクターメッセージ、テーマカラー、ステータスコード、i18n | [docs/ja/home.md](ja/home.md) |

## サイト服務

nginx リバース代理通じて公開ユーザー向け服務。

| 部品 | 説明 | ドキュメント |
|-----------|------|-------------|
| aria2 | 並列ダウンロードマネージャ（WebUI 與 WebDAV 共有付き） | [docs/ja/aria2.md](ja/aria2.md) |
| blc | Bilibili ライブチャット（AI 翻訳付き） | [docs/ja/blc.md](ja/blc.md) |
| bt | BitTorrent クライアント（WebUI 與 WebDAV 共有付き） | [docs/ja/bt.md](ja/bt.md) |
| dns | AdGuard 再帰 DNS（DoT/DoH/DoQ 対応） | [docs/ja/dns.md](ja/dns.md) |
| hako | Web 書類マネージャ（公開 WebDAV 共有付き） | [docs/ja/hako.md](ja/hako.md) |
| hexo | 個人ブログエンジン | [docs/ja/hexo.md](ja/hexo.md) |
| hy2 | Hysteria2 代理（nginx 與 443 ポート共有） | [docs/ja/hy2.md](ja/hy2.md) |
| tracker | 軽量 HTTPS BitTorrent トラッカー | [docs/ja/tracker.md](ja/tracker.md) |
| attic | セルフホスト Nix バイナリキャッシュ伺服器（atticd） | [docs/ja/attic.md](ja/attic.md) |

## 代理與ミラー

リバース代理與キャッシュ高速化服務。

| 部品 | 説明 | ドキュメント |
|-----------|------|-------------|
| gh-proxy | raw.githubusercontent.com 之リバース代理 | [docs/ja/tile_gh-proxy.md](ja/tile_gh-proxy.md) |
| nix-cache | NixOS バイナリキャッシュミラー — channels、cache、releases | [docs/ja/tile_nix-cache.md](ja/tile_nix-cache.md) |

## ナビゲーション

ホームページタイル、アプリ一覧、短縮リンク体系。

| 部品 | 説明 | ドキュメント |
|-----------|------|-------------|
| apps | アプリ一覧タイル — 全服務之ホームページ入口 | [docs/ja/tile_apps.md](ja/tile_apps.md) |
| links | Redis API 経由之短縮リンク体系 | [docs/ja/tile_links.md](ja/tile_links.md) |
| shortlinks | Redis API 経由之動的短縮リンク | [docs/ja/shortlinks.md](ja/shortlinks.md) |

## 外部ツールリンク

外部ダウンロード指すホームページ上之静的リンクタイル（Docker 服務なし）。

| 部品 | 説明 | ドキュメント |
|-----------|------|-------------|
| 7zip | 高圧縮書類アーカイバ | [docs/ja/link_7zip.md](ja/link_7zip.md) |
| dotnet | Microsoft .NET 開発フレームワーク | [docs/ja/link_dotnet.md](ja/link_dotnet.md) |
| dx11 | 旧バージョン DirectX エンドユーザーランタイム | [docs/ja/link_dx11.md](ja/link_dx11.md) |
| vcredist | Visual C++ 再頒布可能包 | [docs/ja/link_vcredist.md](ja/link_vcredist.md) |
| vs | Visual Studio Community IDE | [docs/ja/link_vs.md](ja/link_vs.md) |
| vscode | Visual Studio Code エディタ | [docs/ja/link_vscode.md](ja/link_vscode.md) |

## ショーケース

| 部品 | 説明 | ドキュメント |
|-----------|------|-------------|
| flake | 個人 Nix flake リポジトリ — カスタム包、overlay、NixOS 部品 | [docs/ja/tile_flake.md](ja/tile_flake.md) |
| bilibili | Bilibili スペース — バーチャル配信者紹介 | [docs/ja/tile_bilibili.md](ja/tile_bilibili.md) |
| attic | Attic Nix バイナリキャッシュ利用ガイド | [docs/ja/tile_attic.md](ja/tile_attic.md) |
| mail | MailKits — Cloudflare Email Workers 透過メール代理 | [docs/ja/tile_mail.md](ja/tile_mail.md) |
| kihara777 | GitHub プロフィール — プロジェクト、貢献、連絡先 | [docs/ja/tile_kihara777.md](ja/tile_kihara777.md) |

## 仕様

| 説明 | ドキュメント |
|------|-------------|
| KITS 部品体系完全定義 | [kits/README.md](../kits/README.md) |
| サードパーティ資産於関声明 | [NOTICE.md](NOTICE.ja.md) |
| メンテナンス記録 | [MAINTENANCE.md](MAINTENANCE.ja.md) |
| エージェントガイド（アーキテクチャ、部品体系、開発ワークフロー） | [AGENTS.md](../AGENTS.md) |

## 作者

- **狐莉 (キツ之り)** — 作成與保守
- **小爪 (キツ之め)** — 設計・開発 feat. deepseek-v4-pro (Max)


## ライセンス

[MIT](../LICENSE)