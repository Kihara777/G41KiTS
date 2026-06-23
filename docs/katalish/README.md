# G41KiTS

[中文](../../README.md) | [English](../README.en.md) | [日本語](../README.ja.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/README.md)

ﾓｼﾞｭﾗｰ ｾﾙﾌﾎｽﾄ Docker Compose stack — Metro/WP8.1 style ﾎｰﾑﾍﾟｰｼﾞ, Redis-backed ｺﾝﾌｨｸﾞ API, ﾏﾙﾁ-ﾗﾝｹﾞｰｼﾞ i18n, KITS ﾓｼﾞｭｰﾙ ｼｽﾃﾑ.

## ﾃﾞｨﾌﾟﾛｲ

```bash
git clone https://github.com/Kihara777/G41KiTS.git
cd G41KiTS
cp .env.example .env
# Edit .env with your domain and Cloudflare credentials
./g41.sh kits add -y all
```

### ﾛｰｶﾙ ｲﾆｯﾄ

`./g41.sh ｲﾆｯﾄ` ｻﾎﾟｰﾂ ｲﾝｼﾞｪｸﾃｨﾝｸﾞ ﾃﾞｨﾌﾟﾛｲﾔｰ固有 ﾎｽﾄ ｺﾝﾌｨｸﾞ ｳﾞｨｱ `.ﾛｰｶﾙ/`, 回避 ｺﾐｯﾄ VPS ﾃﾞｨﾃｰﾙｽﾞ to ｻﾞ ﾘﾎﾟ.

**ﾃﾞｨﾚｸﾄﾘ mode** (ﾚｺﾒﾝﾃﾞｯﾄﾞ):
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

**ﾌｧｲﾙ mode** (ﾚｶﾞｼｰ):
```bash
cat <<'EOF' > .local.sh
do_init_local() {
  hostnamectl set-hostname myserver
}
EOF
```

ﾎﾞｰｽ modes ｱｰ ｵﾌﾟｼｮﾅﾙ. ｲﾌ ﾅｲｻﾞｰ ｴｸﾞｼﾞｽﾂ, `ｲﾆｯﾄ` ｽｷｯﾌﾟ ﾎｽﾄ ｾｯﾄｱｯﾌﾟ, ｵﾝﾘｰ ｲﾝｽﾄｰﾘﾝｸﾞ Docker ｱﾝﾄﾞ ﾃﾞｨﾌﾟﾛｲﾝｸﾞ ｺﾝﾃﾅｰｽﾞ.

## ｲﾝﾌﾗｽﾄﾗｸﾁｬｰ

ｺｱ ｻｰﾋﾞｽｽﾞ ﾌﾟﾗｵﾌﾞｲﾃﾞｨﾝｸﾞ ｹﾞｰﾄｳｪｲ, ｽﾄﾚｰｼﾞ, ｻｰﾂ, ｱﾝﾄﾞ ｻｲﾄ ｽｹﾙﾄﾝ.

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | ﾄﾞｷｭﾒﾝﾄ |
|--------|-------------|------|
| nginx | TLS 1.3 / HTTP/3 ｹﾞｰﾄｳｪｲ, ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ to ｵｰﾙ ﾊﾞｯｸｴﾝﾄﾞｽﾞ | [ﾄﾞｷｭﾒﾝﾄ/en/nginx.md](en/nginx.md) |
| redis | Redis ｺﾝﾌｨｸﾞ ｽﾄｱ + Node.js HTTP API ﾌﾞﾘｯｼﾞ | [ﾄﾞｷｭﾒﾝﾄ/en/redis.md](en/redis.md) |
| acme | SSL ｻｰﾃｨﾌｨｹｰﾄ ﾏﾈｼﾞﾒﾝﾄ (acme.sh + ZeroSSL/Cloudflare DNS) | [ﾄﾞｷｭﾒﾝﾄ/en/acme.md](en/acme.md) |
| autoheal | ｵｰﾄﾘｽﾀｰﾄ ｱﾝﾍﾙｼｰ Docker ｺﾝﾃﾅｰｽﾞ | [ﾄﾞｷｭﾒﾝﾄ/en/autoheal.md](en/autoheal.md) |
| dsock | Docker API ｾｷｭﾘﾃｨ ﾌﾟﾛｸｼ (ﾘﾌﾟﾚｲｽｽﾞ ﾀﾞｲﾚｸﾄ docker.sock ﾏｳﾝﾂ) | [ﾄﾞｷｭﾒﾝﾄ/en/dsock.md](en/dsock.md) |
| home | ｻｲﾄ ｺｱ ﾃﾞｲﾀ — ｷｬﾗｸﾀｰ ﾒｯｾｰｼﾞ, ｽｨｰﾑ ｶﾗｰｽﾞ, ｽﾃｰﾀｽ ｺｰﾄﾞｽﾞ, i18n | [ﾄﾞｷｭﾒﾝﾄ/en/home.md](en/home.md) |

## ｻｲﾄ ｻｰﾋﾞｽｽﾞ

ﾕｰｻﾞｰﾌｪｲｼﾝｸﾞ ｻｰﾋﾞｽｽﾞ ｴｸｽﾎﾟｰｽﾞﾄﾞ ｽﾙｰ nginx ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ.

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | ﾄﾞｷｭﾒﾝﾄ |
|--------|-------------|------|
| aria2 | ﾊﾟﾗﾚﾙ ﾀﾞｳﾝﾛｰﾄﾞ ﾑｱﾝｱｼﾞｴﾗ ｳｨｽﾞ WebUI ｱﾝﾄﾞ WebDAV ｼｪｱ | [ﾄﾞｷｭﾒﾝﾄ/en/aria2.md](en/aria2.md) |
| blc | Bilibili ﾗｲﾌﾞ ﾁｬｯﾄ ｳｨｽﾞ AI ﾄﾗﾝｽﾚｰｼｮﾝ | [ﾄﾞｷｭﾒﾝﾄ/en/blc.md](en/blc.md) |
| bt | BitTorrent ｸﾗｲｱﾝﾄ ｳｨｽﾞ WebUI ｱﾝﾄﾞ WebDAV ｼｪｱ | [ﾄﾞｷｭﾒﾝﾄ/en/bt.md](en/bt.md) |
| dns | AdGuard ﾘｶｰｼﾌﾞ DNS ｳｨｽﾞ DoT/DoH/DoQ | [ﾄﾞｷｭﾒﾝﾄ/en/dns.md](en/dns.md) |
| hako | ｳｪﾌﾞ ﾌｧｲﾙ ﾑｱﾝｱｼﾞｴﾗ ｳｨｽﾞ ﾊﾟﾌﾞﾘｯｸ WebDAV ｼｪｱ | [ﾄﾞｷｭﾒﾝﾄ/en/hako.md](en/hako.md) |
| hexo | ﾊﾟｰｿﾅﾙ ﾌﾞﾛｸﾞ ｴﾝｼﾞﾝ | [ﾄﾞｷｭﾒﾝﾄ/en/hexo.md](en/hexo.md) |
| hy2 | Hysteria2 ﾌﾟﾛｸｼ ｼｪｱﾘﾝｸﾞ ﾎﾟｰﾄ 443 ｳｨｽﾞ nginx | [ﾄﾞｷｭﾒﾝﾄ/en/hy2.md](en/hy2.md) |
| ﾄﾗｯｶｰ | ﾗｲﾄｳｪｲﾄ HTTPS BitTorrent ﾄﾗｯｶｰ | [ﾄﾞｷｭﾒﾝﾄ/en/ﾄﾗｯｶｰ.md](en/ﾄﾗｯｶｰ.md) |
| attic | ｾﾙﾌﾎｽﾄ Nix ﾊﾞｲﾅﾘ ｷｬｯｼｭ ｻｰﾊﾞｰ (atticd) | [ﾄﾞｷｭﾒﾝﾄ/en/attic.md](en/attic.md) |

## ﾌﾟﾛｸｼ & ﾐﾗｰ

ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ ｱﾝﾄﾞ ｷｬｯｼｭ ｱｸｾﾗﾚｰｼｮﾝ ｻｰﾋﾞｽｽﾞ.

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | ﾄﾞｷｭﾒﾝﾄ |
|--------|-------------|------|
| gh-ﾌﾟﾛｸｼ | ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ ﾌｫｱ raw.githubusercontent.com | [ﾄﾞｷｭﾒﾝﾄ/en/tile_gh-ﾌﾟﾛｸｼ.md](en/tile_gh-proxy.md) |
| nix-ｷｬｯｼｭ | NixOS ﾊﾞｲﾅﾘ ｷｬｯｼｭ ﾐﾗｰ — channels, ｷｬｯｼｭ, releases | [ﾄﾞｷｭﾒﾝﾄ/en/tile_nix-ｷｬｯｼｭ.md](en/tile_nix-cache.md) |

## ナビゲーション

ﾎｰﾑﾍﾟｰｼﾞ ﾀｲﾙｽﾞ, ｱﾌﾟﾘ ﾘｽﾄ, ｼｮｰﾄ ﾘﾝｸ ｼｽﾃﾑ.

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | ﾄﾞｷｭﾒﾝﾄ |
|--------|-------------|------|
| apps | ｱﾌﾟﾘｹｰｼｮﾝ ﾘｽﾄ tile — ﾎｰﾑﾍﾟｰｼﾞ ｴﾝﾄﾘ ﾌｫｱ ｵｰﾙ ｻｰﾋﾞｽｽﾞ | [ﾄﾞｷｭﾒﾝﾄ/en/tile_apps.md](en/tile_apps.md) |
| ﾘﾝｸｽ | ｼｮｰﾄ ﾘﾝｸ ｼｽﾃﾑ 代理経由 ｽﾙｰ Redis API | [ﾄﾞｷｭﾒﾝﾄ/en/tile_links.md](en/tile_links.md) |
| ｼｮｰﾄﾘﾝｸｽ | ﾀﾞｲﾅﾐｯｸ ｼｮｰﾄ ﾘﾝｸｽ 代理経由 ｽﾙｰ Redis API | [ﾄﾞｷｭﾒﾝﾄ/en/ｼｮｰﾄﾘﾝｸｽ.md](en/shortlinks.md) |

## ｴｸｽﾀｰﾅﾙ ﾂｰﾙ ﾘﾝｸｽ

ｽﾀﾃｨｯｸ ﾘﾝｸ ﾀｲﾙｽﾞ on ｻﾞ ﾎｰﾑﾍﾟｰｼﾞ ﾎﾟｲﾝﾃｨﾝｸﾞ to ｴｸｽﾀｰﾅﾙ ﾀﾞｳﾝﾛｰﾄﾞｽﾞ (ﾉｰ Docker ｻｰﾋﾞｽｽﾞ).

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | ﾄﾞｷｭﾒﾝﾄ |
|--------|-------------|------|
| 7zip | ﾌｧｲﾙ ｱｰｶｲﾊﾞ ｳｨｽﾞ ﾊｲ ｺﾝﾌﾟﾚｯｼｮﾝ ﾚｲｼｵ | [ﾄﾞｷｭﾒﾝﾄ/en/link_7zip.md](en/link_7zip.md) |
| dotnet | Microsoft .NET ﾃﾞｨﾍﾞﾛｯﾌﾟﾒﾝﾄ ﾌﾚｰﾑﾜｰｸ | [ﾄﾞｷｭﾒﾝﾄ/en/link_dotnet.md](en/link_dotnet.md) |
| dx11 | ﾚｶﾞｼｰ DirectX End-User ﾗﾝﾀｲﾑ | [ﾄﾞｷｭﾒﾝﾄ/en/link_dx11.md](en/link_dx11.md) |
| vcredist | Visual C++ 再配布可能 | [ﾄﾞｷｭﾒﾝﾄ/en/link_vcredist.md](en/link_vcredist.md) |
| vs | Visual Studio ｺﾐｭﾆﾃｨ IDE | [ﾄﾞｷｭﾒﾝﾄ/en/link_vs.md](en/link_vs.md) |
| vscode | Visual Studio Code ｴﾃﾞｨﾀ | [ﾄﾞｷｭﾒﾝﾄ/en/link_vscode.md](en/link_vscode.md) |

## ｼｮｰｹｰｽ

| ﾓｼﾞｭｰﾙ | ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | ﾄﾞｷｭﾒﾝﾄ |
|--------|-------------|------|
| flake | ﾊﾟｰｿﾅﾙ Nix flake ﾘﾎﾟｼﾞﾄﾘ — ｶｽﾀﾑ ﾊﾟｯｹｰｼﾞｽﾞ, ｵｰﾊﾞｰﾚｲｽﾞ, NixOS ﾓｼﾞｭｰﾙｽﾞ | [ﾄﾞｷｭﾒﾝﾄ/en/tile_flake.md](en/tile_flake.md) |
| bilibili | Bilibili ｽﾍﾟｰｽ — ﾊﾞｰﾁｬﾙ ｽﾄﾘｰﾏｰ ｲﾝﾄﾛﾀﾞｸｼｮﾝ | [ﾄﾞｷｭﾒﾝﾄ/en/tile_bilibili.md](en/tile_bilibili.md) |
| attic | Attic Nix ﾊﾞｲﾅﾘ ｷｬｯｼｭ ﾕｰｾｰｼﾞ ｶﾞｲﾄﾞ | [ﾄﾞｷｭﾒﾝﾄ/en/tile_attic.md](en/tile_attic.md) |
| mail | MailKits — Cloudflare Email Workers ﾄﾗﾝｽﾍﾟｱﾚﾝﾄ ﾌﾟﾛｸｼ | [ﾄﾞｷｭﾒﾝﾄ/en/tile_mail.md](en/tile_mail.md) |
| kihara777 | GitHub ﾌﾟﾛﾌｧｲﾙ — ﾌﾟﾛｼﾞｪｸﾂ, ｺﾝﾄﾘﾋﾞｭｰｼｮﾝ & ｺﾝﾀｸﾄ | [ﾄﾞｷｭﾒﾝﾄ/en/tile_kihara777.md](en/tile_kihara777.md) |

## ｽﾍﾟｯｸ

| ﾃﾞｨｽｸﾘﾌﾟｼｮﾝ | ﾄﾞｷｭﾒﾝﾄ |
|-------------|-----|
| KITS ﾓｼﾞｭｰﾙ ｼｽﾃﾑ ﾌﾙ ﾃﾞﾌｨﾆｼｮﾝ | [kits/README.md](../kits/README.md) |
| ｻｰﾄﾞﾊﾟｰﾃｨ ｱｾｯﾂ ﾉｰﾃｨｽ | [ﾉｰﾃｨｽ.md](NOTICE.en.md) |
| ﾒﾝﾃﾅﾝｽ ﾛｸﾞ | [ﾒﾝﾃﾅﾝｽ.md](MAINTENANCE.en.md) |
| ｴｰｼﾞｪﾝﾄ ｶﾞｲﾄﾞ — ｱｰｷﾃｸﾁｬ, ﾓｼﾞｭｰﾙ ｼｽﾃﾑ, ﾃﾞｨﾍﾞﾛｯﾌﾟﾒﾝﾄ ﾜｰｸﾌﾛｰ | [AGENTS.md](../AGENTS.md) |

## ｵｰｻｰ

- **Kitsunori (キツのり)** — ｸﾘｴｲﾀｰ ｱﾝﾄﾞ ﾒﾝﾃﾅｰ
- **Kitsunome (キツのめ)** — ﾃﾞｻﾞｲﾝ & ﾃﾞｨﾍﾞﾛｯﾌﾟﾒﾝﾄ ﾌｨｰﾄ. deepseek-v4-pro (Max)


## ﾗｲｾﾝｽ

[MIT](../LICENSE)
