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
| redis | Redis 設定ストア + Node.js HTTP API ブリッジ | [docs/ja/redis.md](ja/redis.md) |
| acme | SSL 証明書管理 | [docs/ja/acme.md](ja/acme.md) |
| autoheal | 異常なコンテナの自動再起動 | [docs/ja/autoheal.md](ja/autoheal.md) |
| dsock | Docker API セキュリティプロキシ | [docs/ja/dsock.md](ja/dsock.md) |
| home | サイトコアデータ | [docs/ja/home.md](ja/home.md) |

## サイトサービス
| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| aria2 | 並列ダウンロードマネージャ | [docs/ja/aria2.md](ja/aria2.md) |
| blc | Bilibili ライブチャット（AI 翻訳付き） | [docs/ja/blc.md](ja/blc.md) |
| bt | BitTorrent クライアント | [docs/ja/bt.md](ja/bt.md) |
| dns | AdGuard 再帰 DNS（DoT/DoH/DoQ） | [docs/ja/dns.md](ja/dns.md) |
| hako | Web ファイルマネージャ | [docs/ja/hako.md](ja/hako.md) |
| hexo | 個人ブログエンジン | [docs/ja/hexo.md](ja/hexo.md) |
| hy2 | Hysteria2 プロキシ | [docs/ja/hy2.md](ja/hy2.md) |
| tracker | 軽量 HTTPS BitTorrent トラッカー | [docs/ja/tracker.md](ja/tracker.md) |

## プロキシとミラー
| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| gh-proxy | raw.githubusercontent.com のリバースプロキシ | [docs/ja/gh-proxy.md](ja/gh-proxy.md) |
| nix-cache | NixOS バイナリキャッシュミラー | [docs/ja/nix-cache.md](ja/nix-cache.md) |

## ナビゲーション
| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| apps | アプリ一覧タイル | [docs/ja/apps.md](ja/apps.md) |
| links | 短縮リンクシステム | [docs/ja/links.md](ja/links.md) |
| shortlinks | 動的短縮リンク | [docs/ja/shortlinks.md](ja/shortlinks.md) |

## 外部ツールリンク
| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| 7zip | 高圧縮ファイルアーカイバ | [docs/ja/7zip.md](ja/7zip.md) |
| dotnet | Microsoft .NET フレームワーク | [docs/ja/dotnet.md](ja/dotnet.md) |
| dx11 | DirectX ランタイム | [docs/ja/dx11.md](ja/dx11.md) |
| vcredist | Visual C++ 再頒布可能パッケージ | [docs/ja/vcredist.md](ja/vcredist.md) |
| vs | Visual Studio IDE | [docs/ja/vs.md](ja/vs.md) |
| vscode | Visual Studio Code エディタ | [docs/ja/vscode.md](ja/vscode.md) |

## ショーケース
| モジュール | 説明 | ドキュメント |
|-----------|------|-------------|
| flake | Nix flake リポジトリ | [docs/ja/flake.md](ja/flake.md) |

## 仕様
| ドキュメント | 説明 |
|-------------|------|
| [docs/ja/module-spec.md](ja/module-spec.md) | KITS モジュールシステムのフォーマット定義 |

## 作者
- **狐莉 (キツのり)** — 作成と保守
- **小爪 (キツのめ)** — 設計・開発
- **小小爪 (キツのめ)** — ハードウェア推論基盤

## ライセンス
[MIT](../LICENSE)