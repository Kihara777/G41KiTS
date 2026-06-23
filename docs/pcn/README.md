# G41KiTS

[中文](../../README.md) | [English](../README.en.md) | [日本語](../README.ja.md) | [ｶﾀﾘｯｼｭ](../katalish/README.md) | 偽中国語

部品型 Docker Compose 堆 — Metro/WP8.1 風首頁、Redis 設定 API、多言語 i18n、KITS 部品体系。

## 配備

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# .env にドメインと Cloudflare 認証情報を記入
./g41.sh kits add -y all
```

### 初期化

`./g41.sh init` `.local/` 通専用之設定注入以、VPS 情報倉庫於於済。

**模式**（推奨）：
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

**書類模式**（旧版互換）：
```bash
cat <<'EOF' > .local.sh
do_init_local() {
  hostnamectl set-hostname myserver
}
EOF
```

両模式與任意。存在場合、`init` 設定、Docker 之導入與之之実行。

## 基盤

関門、貯蔵、証明書、之骨組提供服務。

| 部品 | 説明 | 文書 |
|-----------|------|-------------|
| nginx | TLS 1.3 / HTTP/3 関門、全之代理 | [docs/ja/nginx.md](ja/nginx.md) |
| redis | Redis 設定 + Node.js HTTP API | [docs/ja/redis.md](ja/redis.md) |
| acme | SSL 証明書管理（acme.sh + ZeroSSL/Cloudflare DNS） | [docs/ja/acme.md](ja/acme.md) |
| autoheal | 異常 Docker 之自動再起動 | [docs/ja/autoheal.md](ja/autoheal.md) |
| dsock | Docker API 安全代理（docker.sock 直接之代替） | [docs/ja/dsock.md](ja/dsock.md) |
| home | 資料 — 、、、i18n | [docs/ja/home.md](ja/home.md) |

## 服務

nginx 代理通公開向服務。

| 部品 | 説明 | 文書 |
|-----------|------|-------------|
| aria2 | 並列下載（WebUI 與 WebDAV 共有付） | [docs/ja/aria2.md](ja/aria2.md) |
| blc | Bilibili （AI 翻訳付） | [docs/ja/blc.md](ja/blc.md) |
| bt | BitTorrent 依頼者（WebUI 與 WebDAV 共有付） | [docs/ja/bt.md](ja/bt.md) |
| dns | AdGuard 再帰 DNS（DoT/DoH/DoQ 対応） | [docs/ja/dns.md](ja/dns.md) |
| hako | Web 書類（公開 WebDAV 共有付） | [docs/ja/hako.md](ja/hako.md) |
| hexo | 個人 | [docs/ja/hexo.md](ja/hexo.md) |
| hy2 | Hysteria2 代理（nginx 與 443 共有） | [docs/ja/hy2.md](ja/hy2.md) |
| tracker | 軽量 HTTPS BitTorrent | [docs/ja/tracker.md](ja/tracker.md) |
| attic | Nix 二進緩衝伺服器（atticd） | [docs/ja/attic.md](ja/attic.md) |

## 代理與

代理與緩衝高速化服務。

| 部品 | 説明 | 文書 |
|-----------|------|-------------|
| gh-proxy | raw.githubusercontent.com 之代理 | [docs/ja/tile_gh-proxy.md](ja/tile_gh-proxy.md) |
| nix-cache | NixOS 二進緩衝 — channels、cache、releases | [docs/ja/tile_nix-cache.md](ja/tile_nix-cache.md) |

## 導航

首頁磁貼、一覧、短縮連結体系。

| 部品 | 説明 | 文書 |
|-----------|------|-------------|
| apps | 一覧磁貼 — 全服務之首頁入口 | [docs/ja/tile_apps.md](ja/tile_apps.md) |
| links | Redis API 経由之短縮連結体系 | [docs/ja/tile_links.md](ja/tile_links.md) |
| shortlinks | Redis API 経由之動的短縮連結 | [docs/ja/shortlinks.md](ja/shortlinks.md) |

## 外部道具連結

外部下載指首頁上之静的連結磁貼（Docker 服務）。

| 部品 | 説明 | 文書 |
|-----------|------|-------------|
| 7zip | 高圧縮書類 | [docs/ja/link_7zip.md](ja/link_7zip.md) |
| dotnet | Microsoft .NET 開発框架 | [docs/ja/link_dotnet.md](ja/link_dotnet.md) |
| dx11 | 旧版 DirectX 実行時 | [docs/ja/link_dx11.md](ja/link_dx11.md) |
| vcredist | Visual C++ 再頒布可能包 | [docs/ja/link_vcredist.md](ja/link_vcredist.md) |
| vs | Visual Studio Community IDE | [docs/ja/link_vs.md](ja/link_vs.md) |
| vscode | Visual Studio Code 編輯器 | [docs/ja/link_vscode.md](ja/link_vscode.md) |

## 展示

| 部品 | 説明 | 文書 |
|-----------|------|-------------|
| flake | 個人 Nix flake 倉庫 — 包、overlay、NixOS 部品 | [docs/ja/tile_flake.md](ja/tile_flake.md) |
| bilibili | Bilibili — 配信者紹介 | [docs/ja/tile_bilibili.md](ja/tile_bilibili.md) |
| attic | Attic Nix 二進緩衝利用 | [docs/ja/tile_attic.md](ja/tile_attic.md) |
| mail | MailKits — Cloudflare Email Workers 透過郵件代理 | [docs/ja/tile_mail.md](ja/tile_mail.md) |
| kihara777 | GitHub 概要 — 計画、貢献、連絡先 | [docs/ja/tile_kihara777.md](ja/tile_kihara777.md) |

## 仕様

| 説明 | 文書 |
|------|-------------|
| KITS 部品体系完全定義 | [kits/README.md](../kits/README.md) |
| 資産於関声明 | [NOTICE.md](NOTICE.ja.md) |
| 記録 | [MAINTENANCE.md](MAINTENANCE.ja.md) |
| 代理（構造、部品体系、開発） | [AGENTS.md](../AGENTS.md) |

## 作者

- **狐莉 (キツのり)** — 作成與保守
- **小爪 (キツのめ)** — 設計開発 feat. deepseek-v4-pro (Max)


## 許諾

[MIT](../LICENSE)