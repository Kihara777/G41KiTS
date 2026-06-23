# Maintenance Log

[中文](../../MAINTENANCE.md) | [English](../MAINTENANCE.en.md) | [日本語](../MAINTENANCE.ja.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/MAINTENANCE.md)

## 2026-06-20

- Open-sourced: pushed `main` branch to GitHub
- Trilingual docs ﾗｲﾌﾞ (27 modules + ﾓｼﾞｭｰﾙ spec): zh:29 / en:29 / ja:29
- AGENTS.md rewritten in Chinese (292 lines), covering ｱｰｷﾃｸﾁｬ, ﾃﾞｨﾍﾞﾛｯﾌﾟﾒﾝﾄ ﾜｰｸﾌﾛｰ, common issues
- README added `.ﾛｰｶﾙ/` ﾛｰｶﾙ ｲﾆｯﾄ section
- Trilingual ﾒﾝﾃﾅﾝｽ logs (ﾒﾝﾃﾅﾝｽ.md / en / ja)
- Trilingual ﾉｰﾃｨｽ.md (ｻｰﾄﾞﾊﾟｰﾃｨ ｱｾｯﾂ ﾉｰﾃｨｽ)

## 2026-06-18

- Removed ｵｰﾙ Docker ﾊﾞｰｼﾞｮﾝ locks: Dockerfile ﾌﾛﾑ lines, compose image tags, npm ﾊﾟｯｹｰｼﾞ versions, ｱﾄﾞ --checksum ｵｰﾙ switched to floating versions
- Fixed `g41.sh kits pack` failing on `ｾｯﾄ -e` due to missing `skills/` ﾃﾞｨﾚｸﾄﾘ
- ﾌﾙ stack forced rebuild, 14/14 healthy

## 2026-06-16

- Two rounds of ﾌﾙ security audits (4 sub-agents in ﾊﾟﾗﾚﾙ): 24 issues found, ｵｰﾙ fixed ｵﾗ accepted
- g41.sh hardening: `ｾｯﾄ -o pipefail`, `sed -i` → atomic writes (`sed > tmp && mv`), compose ｲﾝｸﾙｰﾄﾞ uses line-number precise insertion
- autoheal crash fix: switched ﾌﾛﾑ willfarrell/autoheal Hub image to custom Dockerfile (master entrypoint, TCP socket ｻﾎﾟｰﾄ)
- CSP security headers layered configuration: strict ﾌｫｱ main ｻｲﾄ + relaxed ﾌｫｱ aria2/nix-ｷｬｯｼｭ/gh-ﾌﾟﾛｸｼ ﾌﾟﾛｸｼ paths
- tiles.js ﾄﾗｯｶｰ embed XSS fix: `innerHTML` → `createElement` + `textContent`
- G41.js fetch added 5s timeout (`AbortSignal.timeout(5000)`)
- ｻｰﾊﾞｰ.js ｵｰﾙ `catch(e){}` silent errors now ﾛｸﾞ ｳﾞｨｱ `console.error`
- Open-source readiness audit passed: zero hardcoded domains/secrets, ｵｰﾙ sensitive files excluded ｳﾞｨｱ `.gitignore`
- tile_bilibili ﾓｼﾞｭｰﾙ created: Bilibili VTuber tile (trilingual i18n)
- tile_flake tile populated: 13 NixKits ﾊﾟｯｹｰｼﾞｽﾞ/patches/skills entries
- tile_gh-ﾌﾟﾛｸｼ i18n hardcoded `g41.moe` → `__HOST__` placeholder
- g41.sh TUI switched to ANSI escape sequence incremental rendering (eliminates flicker)
- GitHub ﾘﾎﾟｼﾞﾄﾘ created ｳｨｽﾞ topics

## 2026-06-11 ~ 2026-06-12

- ﾃﾞｲﾀ/function separation (A/B/C layers): compose variable substitution, nginx ｻｲﾄ ｺﾝﾌｨｸﾞ generalization, ｻｰﾊﾞｰ.js ｴﾝﾌﾞｲﾗｵﾝﾒﾝﾄ injection
- Security hardening: dsock ﾆｭｰ ﾓｼﾞｭｰﾙ (Docker API ﾌﾟﾛｸｼ), BT supply chain locking, Redis password authentication
- Health check standardization (HTTP endpoint > ﾎﾟｰﾄ probe > kill -0 1)
- ﾓｼﾞｭｰﾙ renaming: pure tiles → `tile_*` prefix (5 modules), pure ﾘﾝｸｽ → `link_*` prefix (6 modules)
- Frontend fixes: error code pages, loading flicker, 404 response
- hy2 ﾓｼﾞｭｰﾙ privatization: `.ﾛｰｶﾙ/` hides subscription files ｱﾝﾄﾞ nginx configs
- g41.sh extended: auto-discovery of `.ﾛｰｶﾙ/ｻｲﾄ/` ｱﾝﾄﾞ `.ﾛｰｶﾙ/webroot/`
- ｻｰﾊﾞｰ.js refactored: raw TCP socket → `redis` npm ﾊﾟｯｹｰｼﾞ ｳｨｽﾞ persistent connection + pipeline batch writes

## 2026-06-10

- Initial audit: compose.yaml, g41.sh, ｵｰﾙ kits/ modules
- ｲﾝﾌﾗｽﾄﾗｸﾁｬｰ setup: Metro/WP8.1 style ﾎｰﾑﾍﾟｰｼﾞ, Redis ｺﾝﾌｨｸﾞ API, multi-ﾗﾝｹﾞｰｼﾞ i18n, KITS ﾓｼﾞｭｰﾙ ｼｽﾃﾑ
