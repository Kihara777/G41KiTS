# G41KiTS
[中文](../../README.md) | [English](../README.en.md) | [日本語](../README.ja.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/README.md)


Modular ｾﾙﾌﾎｽﾄ Docker ｺﾝﾎﾟｰｽﾞ ｽﾀｯｸ — Metro/WP8.1 ｽﾀｲﾙ ﾎｰﾑﾍﾟｰｼﾞ, Redis-基盤 ｺﾝﾌｨｸﾞ API, 複数-language i18n, KITS ﾓｼﾞｭｰﾙ ｼｽﾃﾑ.

## 配備

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# Edit .env with your domain and Cloudflare credentials
./g41.sh kits add -y all
```

### ﾛｰｶﾙ ｲﾃｯﾄ

`./g41.sh init` ｻﾎﾟｰﾄ injecting deployer-特定 host ｺﾝﾌｨｸﾞ via `.local/`, avoiding committing VPS 詳細 ﾄｩ ｻﾞ ﾘﾎﾟ.

**ﾃﾞｨﾚｸﾄﾘ ﾓｰﾄﾞ** (推奨):
```bash
mkdir -p .local
cat <<'EOF' > .local/install.sh
do_init_local() {
  hostnamectl set-hostname myserver
  timedatectl set-timezone Asia/Tokyo
  # UFW, netplan, crontab, etc.
}
EOF
```

**ﾌｧｲﾙ ﾓｰﾄﾞ** (ﾚｶﾞｼｰ):
```bash
cat <<'EOF' > .local.sh
do_init_local() {
  hostnamectl set-hostname myserver
}
EOF
```

Both ﾓｰﾄﾞ ｱｰ 任意. ｲﾌ どちらもない exists, `init` skips host 準備, ｵﾝﾘｰ 導入中 Docker ｱﾝﾄﾞ 配備中 ｺﾝﾃﾅ.

## ｲﾝﾌﾗ

ｺｱ services 提供中 ｹﾞｰﾄｳｪｲ, ｽﾄﾚｰｼﾞ, 証明書, ｱﾝﾄﾞ ｻｲﾄ 骨組.

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | Docs |
|--------|-------------|------|
| nginx | TLS 1.3 / HTTP/3 ｹﾞｰﾄｳｪｲ, ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ ﾄｩ ｵｰﾙ ﾊﾞｯｸｴﾝﾄﾞｽﾞ | [docs/katalish/nginx.md](./nginx.md) |
| redis | Redis ｺﾝﾌｨｸﾞ ｽﾄｱ + Node.js HTTP API 橋渡 | [docs/katalish/redis.md](./redis.md) |
| acme | SSL ｻｰﾃｨﾌｨｹｰﾄ management (acme.sh + ZeroSSL/Cloudflare DNS) | [docs/katalish/acme.md](./acme.md) |
| autoheal | ｵｰﾄ-再起動 unhealthy Docker ｺﾝﾃﾅ | [docs/katalish/autoheal.md](./autoheal.md) |
| dsock | Docker API security ﾌﾟﾛｸｼ (置換 直接 docker.sock ﾏｳﾝﾄ) | [docs/katalish/dsock.md](./dsock.md) |
| home | ｻｲﾄ ｺｱ ﾃﾞｲﾀ — ｷｬﾗｸﾀｰ ﾒｯｾｰｼﾞ, ﾃｰﾏ ｶﾗｰ, ｽﾃｰﾀｽ ｺｰﾄﾞ, i18n | [docs/katalish/home.md](./home.md) |

## ｻｲﾄｻｰﾋﾞｽ

ﾕｰｻﾞｰ-面向 services 露出済 経由 nginx ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ.

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | Docs |
|--------|-------------|------|
| aria2 | 並列 ﾀﾞｳﾝﾛｰﾄﾞ ﾑｱﾝｱｼﾞｴﾗ ｳｨｽﾞ WebUI ｱﾝﾄﾞ WebDAV ｼｪｱ | [docs/katalish/aria2.md](./aria2.md) |
| blc | Bilibili ﾗｲﾌﾞ ﾁｬｯﾄ ｳｨｽﾞ AI ﾄﾗﾝｽﾚｰｼｮﾝ | [docs/katalish/blc.md](./blc.md) |
| bt | BitTorrent ｸﾗｲｱﾝﾄ ｳｨｽﾞ WebUI ｱﾝﾄﾞ WebDAV ｼｪｱ | [docs/katalish/bt.md](./bt.md) |
| dns | AdGuard ﾘｶｰｼﾌﾞ DNS ｳｨｽﾞ DoT/DoH/DoQ | [docs/katalish/dns.md](./dns.md) |
| hako | ｳｪﾌﾞ ﾌｧｲﾙ ﾑｱﾝｱｼﾞｴﾗ ｳｨｽﾞ ﾊﾟﾌﾞﾘｯｸ WebDAV ｼｪｱ | [docs/katalish/hako.md](./hako.md) |
| hexo | 個人 ﾌﾞﾛｸﾞ ｴﾝｼﾞﾝ | [docs/katalish/hexo.md](./hexo.md) |
| hy2 | Hysteria2 ﾌﾟﾛｸｼ 共有 ﾎﾟｰﾄ 443 ｳｨｽﾞ nginx | [docs/katalish/hy2.md](./hy2.md) |
| ﾄﾗｯｶｰ | ﾗｲﾄｳｪｲﾄ HTTPS BitTorrent ﾄﾗｯｶｰ | [docs/katalish/tracker.md](./tracker.md) |
| attic | ｾﾙﾌﾎｽﾄ Nix ﾊﾞｲﾅﾘ ｷｬｯｼｭ ｻｰﾊﾞｰ (atticd) | [docs/katalish/attic.md](./attic.md) |

## ﾌﾟﾛｸｼ & ﾐﾗｰ

ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ ｱﾝﾄﾞ ｷｬｯｼｭ 加速 services.

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | Docs |
|--------|-------------|------|
| gh-ﾌﾟﾛｸｼ | ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ ﾌｫｱ 生.githubusercontent.com | [docs/katalish/tile_gh-proxy.md](./tile_gh-proxy.md) |
| nix-ｷｬｯｼｭ | NixOS ﾊﾞｲﾅﾘ ｷｬｯｼｭ ﾐﾗｰ — channels, ｷｬｯｼｭ, ﾘﾘｰｽ | [docs/katalish/tile_nix-cache.md](./tile_nix-cache.md) |

## ﾅﾋﾞｹﾞｰｼｮﾝ

ﾎｰﾑﾍﾟｰｼﾞ ﾀｲﾙ, app ﾘｽﾄ, ｼｮｰﾄ ﾘﾝｸ ｼｽﾃﾑ.

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | Docs |
|--------|-------------|------|
| apps | ｱﾌﾟﾘｹｰｼｮﾝ ﾘｽﾄ ﾀｲﾙ — ﾎｰﾑﾍﾟｰｼﾞ ｴﾝﾄﾘ ﾌｫｱ ｵｰﾙ services | [docs/katalish/tile_apps.md](./tile_apps.md) |
| ﾘﾝｸ | ｼｮｰﾄ ﾘﾝｸ ｼｽﾃﾑ 代理経由 経由 Redis API | [docs/katalish/tile_links.md](./tile_links.md) |
| shortlinks | ﾀﾞｲﾅﾐｯｸ ｼｮｰﾄ ﾘﾝｸ 代理経由 経由 Redis API | [docs/katalish/shortlinks.md](./shortlinks.md) |

## ｴｸｽﾀｰﾅﾙ ﾂｰﾙ ﾘﾝｸｽ

ｽﾀﾃｨｯｸ ﾘﾝｸ ﾀｲﾙ ｵﾝ ｻﾞ ﾎｰﾑﾍﾟｰｼﾞ 指向 ﾄｩ ｴｸｽﾀｰﾅﾙ ﾀﾞｳﾝﾛｰﾄﾞ (ﾉｰ Docker services).

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | Docs |
|--------|-------------|------|
| 7zip | ﾌｧｲﾙ ｱｰｶｲﾊﾞ ｳｨｽﾞ ﾊｲ 圧縮 率 | [docs/katalish/link_7zip.md](./link_7zip.md) |
| dotnet | Microsoft .NET ﾃﾞｨﾍﾞﾛｯﾌﾟﾒﾝﾄ ﾌﾚｰﾑﾜｰｸ | [docs/katalish/link_dotnet.md](./link_dotnet.md) |
| dx11 | ﾚｶﾞｼｰ DirectX End-ﾕｰｻﾞｰ ﾗﾝﾀｲﾑ | [docs/katalish/link_dx11.md](./link_dx11.md) |
| vcredist | Visual C++ 再配布可能 | [docs/katalish/link_vcredist.md](./link_vcredist.md) |
| vs | Visual Studio ｺﾐｭﾆﾃｨ IDE | [docs/katalish/link_vs.md](./link_vs.md) |
| vscode | Visual Studio ｺｰﾄﾞ ｴﾃﾞｨﾀ | [docs/katalish/link_vscode.md](./link_vscode.md) |

## ｼｮｰｹｰｽ

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | Docs |
|--------|-------------|------|
| ﾌﾚｲｸ | 個人 Nix ﾌﾚｲｸ ﾘﾎﾟｼﾞﾄﾘ — ｶｽﾀﾑ ﾊﾟｯｹｰｼﾞ, ｵｰﾊﾞｰﾚｲ, NixOS ﾓｼﾞｭｰﾙ | [docs/katalish/tile_flake.md](./tile_flake.md) |
| bilibili | Bilibili ｽﾍﾟｰｽ — ﾊﾞｰﾁｬﾙ ｽﾄﾘｰﾏｰ 紹介 | [docs/katalish/tile_bilibili.md](./tile_bilibili.md) |
| attic | Attic Nix ﾊﾞｲﾅﾘ ｷｬｯｼｭ 利用法 ｶﾞｲﾄﾞ | [docs/katalish/tile_attic.md](./tile_attic.md) |
| mail | MailKits — Cloudflare Email ﾜｰｶｰ 透過 ﾌﾟﾛｸｼ | [docs/katalish/tile_mail.md](./tile_mail.md) |
| kihara777 | GitHub ﾌﾟﾛﾌｧｲﾙ — ﾌﾟﾛｼﾞｪｸﾄ, 貢献 & 連絡 | [docs/katalish/tile_kihara777.md](./tile_kihara777.md) |

## 仕様

| ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | Doc |
|-------------|-----|
| KITS ﾓｼﾞｭｰﾙ ｼｽﾃﾑ ﾌﾙ 定義 | [kits/README.md](../../kits/README.md) |
| ｻｰﾄﾞ-ﾊﾟｰﾃｨ ｱｾｯﾂ notice | [NOTICE.md](./NOTICE.md) |
| ﾒﾝﾃﾅﾝｽ log | [MAINTENANCE.md](./MAINTENANCE.md) |
| ｴｰｼﾞｪﾝﾄ ｶﾞｲﾄﾞ — ｱｰｷﾃｸﾁｬ, ﾓｼﾞｭｰﾙ ｼｽﾃﾑ, ﾃﾞｨﾍﾞﾛｯﾌﾟﾒﾝﾄ ﾜｰｸﾌﾛｰ | [AGENTS.md](../../AGENTS.md) |

## 作者

- **Kitsunori (キツのり)** — 作成者 ｱﾝﾄﾞ ﾒﾝﾃﾅｰ
- **Kitsunome (キツのめ)** — ﾃﾞｻﾞｲﾝ & ﾃﾞｨﾍﾞﾛｯﾌﾟﾒﾝﾄ 協力. deepseek-v4-pro (Max)


## ﾗｲｾﾝｽ

[MIT](../../LICENSE)