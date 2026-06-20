# G41KiTS

[中文](../README.md) | [English](README.en.md) | [日本語](README.ja.md)

モジュール型セルフホスト Docker Compose スタック — Metro/WP8.1 風ホームページ、Redis 設定 API、多言語 i18n、KITS モジュールシステム。

## デプロイ

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
./g41.sh kits add -y all
```

## 基盤

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| nginx | TLS 1.3 / HTTP/3 ゲートウェイ | [docs/ja/nginx.md](ja/nginx.md) |
| redis | Redis 設定ストア + API | [docs/ja/redis.md](ja/redis.md) |
| acme | SSL 証明書管理（acme.sh） | [docs/ja/acme.md](ja/acme.md) |
| autoheal | 異常コンテナ自動再起動 | [docs/ja/autoheal.md](ja/autoheal.md) |
| dsock | Docker API セキュリティプロキシ | [docs/ja/dsock.md](ja/dsock.md) |
| home | サイトコアデータ + i18n | [docs/ja/home.md](ja/home.md) |

## サイトサービス

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| aria2 | ダウンロードマネージャ + WebDAV | [docs/ja/aria2.md](ja/aria2.md) |
| blc | Bilibili ライブチャット | [docs/ja/blc.md](ja/blc.md) |
| bt | BitTorrent クライアント + WebDAV | [docs/ja/bt.md](ja/bt.md) |
| dns | AdGuard 再帰 DNS（DoT/DoH/DoQ） | [docs/ja/dns.md](ja/dns.md) |
| hako | Web ファイルマネージャ + WebDAV | [docs/ja/hako.md](ja/hako.md) |
| hexo | 個人ブログエンジン | [docs/ja/hexo.md](ja/hexo.md) |
| hy2 | Hysteria2 プロキシ（ポート共有） | [docs/ja/hy2.md](ja/hy2.md) |
| tracker | 軽量 HTTPS BT トラッカー | [docs/ja/tracker.md](ja/tracker.md) |

## プロキシとミラー

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| tile_gh-proxy | raw.githubusercontent.com プロキシ | [docs/ja/tile_gh-proxy.md](ja/tile_gh-proxy.md) |
| tile_nix-cache | NixOS バイナリキャッシュミラー | [docs/ja/tile_nix-cache.md](ja/tile_nix-cache.md) |

## ナビゲーション

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| tile_apps | アプリ一覧タイル | [docs/ja/tile_apps.md](ja/tile_apps.md) |
| tile_bilibili | Bilibili スペースタイル | [docs/ja/tile_bilibili.md](ja/tile_bilibili.md) |
| tile_flake | Nix flake リポジトリタイル | [docs/ja/tile_flake.md](ja/tile_flake.md) |
| tile_links | 短縮リンクタイル | [docs/ja/tile_links.md](ja/tile_links.md) |
| shortlinks | 動的短縮リンク | [docs/ja/shortlinks.md](ja/shortlinks.md) |

## 外部リンク

| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| link_7zip | 7-Zip アーカイバ | [docs/ja/link_7zip.md](ja/link_7zip.md) |
| link_dotnet | .NET SDK | [docs/ja/link_dotnet.md](ja/link_dotnet.md) |
| link_dx11 | DirectX 11 Runtime | [docs/ja/link_dx11.md](ja/link_dx11.md) |
| link_vcredist | VC++ Redist | [docs/ja/link_vcredist.md](ja/link_vcredist.md) |
| link_vs | Visual Studio IDE | [docs/ja/link_vs.md](ja/link_vs.md) |
| link_vscode | VS Code エディタ | [docs/ja/link_vscode.md](ja/link_vscode.md) |

## 作者

- **狐莉 (キツのり)** — 作成と保守
- **小爪 (キツのめ)** — 設計・開発 feat. deepseek-v4-pro (Max)
- **小小爪 (キツのめ)** — ハードウェア推論基盤 feat. llama-cpp-rocm

## ライセンス

[MIT](../LICENSE)