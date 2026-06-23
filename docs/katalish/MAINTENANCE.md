# Maintenance Log

[中文](../../MAINTENANCE.md) | [English](../MAINTENANCE.en.md) | [日本語](../MAINTENANCE.ja.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/MAINTENANCE.md)

## 2026-06-20

- Open-sourced: pushed `main` branch to GitHub
- Trilingual docs ﾗｲﾌﾞ (27 ﾓｼﾞｭｰﾙs + ﾓｼﾞｭｰﾙ spec): zh:29 / en:29 / ja:29
- ｴｰｼﾞｪﾝﾄS.md rewritten in Chinese (292 lines), covering ｱｰｷﾃｸﾁｬ, ﾃﾞｨﾍﾞﾛｯﾌﾟﾒﾝﾄ ﾜｰｸﾌﾛｰ, common issues
- README ｱﾄﾞed `.ﾛｰｶﾙ/` ﾛｰｶﾙ ｲﾆｯﾄ section
- Trilingual ﾒﾝﾃﾅﾝｽ ﾛｸﾞs (ﾒﾝﾃﾅﾝｽ.md / en / ja)
- Trilingual ﾉｰﾃｨｽ.md (ｻｰﾄﾞﾊﾟｰﾃｨ ｱｾｯﾂ ﾉｰﾃｨｽ)

## 2026-06-18

- Removed ｵｰﾙ Docker ﾊﾞｰｼﾞｮﾝ locks: Dockerﾌｧｲﾙ ﾌﾛﾑ lines, compose image tags, npm ﾊﾟｯｹｰｼﾞ ﾊﾞｰｼﾞｮﾝs, ｱﾄﾞ --checksum ｵｰﾙ switched to floating ﾊﾞｰｼﾞｮﾝs
- Fixed `g41.sh kｲｯﾂ pack` failing on `ｾｯﾄ -e` due to missing `ｽｷﾙs/` ﾃﾞｨﾚｸﾄﾘ
- ﾌﾙ stack ﾌｫｱced reﾋﾞﾙﾄﾞ, 14/14 healthy

## 2026-06-16

- Two rounds of ﾌﾙ security audｲｯﾂ (4 sub-ｴｰｼﾞｪﾝﾄs in ﾊﾟﾗﾚﾙ): 24 issues found, ｵｰﾙ fixed ｵﾗ accepted
- g41.sh hardening: `ｾｯﾄ -o pipefail`, `sed -i` → atomic writes (`sed > tmp && mv`), compose ｲﾝｸﾙｰﾄﾞ ﾕｰｽﾞs line-number precise insertion
- autoheal crash fix: switched ﾌﾛﾑ willfarrell/autoheal Hub image to custom Dockerﾌｧｲﾙ (master ｴﾝﾄﾘpoint, TCP socket ｻﾎﾟｰﾄ)
- CSP security headers layered ｺﾝﾌｨｸﾞuﾚｲｼｵn: strict ﾌｫｱ main ｻｲﾄ + relaxed ﾌｫｱ aria2/nix-ｷｬｯｼｭ/gh-ﾌﾟﾛｸｼ ﾌﾟﾛｸｼ paths
- tiles.js ﾄﾗｯｶｰ embed XSS fix: `innerHTML` → `ｸﾘｴｲﾄElement` + `textContent`
- G41.js fetch ｱﾄﾞed 5s timeout (`AbortSignal.timeout(5000)`)
- ｻｰﾊﾞｰ.js ｵｰﾙ `catch(e){}` silent errors now ﾛｸﾞ ｳﾞｨｱ `console.error`
- Open-source readiness audit passed: zero hardcoded ﾄﾞﾒｲﾝs/secrets, ｵｰﾙ sensitive ﾌｧｲﾙs excluded ｳﾞｨｱ `.gitignore`
- tile_bilibili ﾓｼﾞｭｰﾙ ｸﾘｴｲﾄd: Bilibili VTuber tile (trilingual i18n)
- tile_flake tile populated: 13 NixKｲｯﾂ ﾊﾟｯｹｰｼﾞｽﾞ/ﾊﾟｯﾁes/ｽｷﾙs entries
- tile_gh-ﾌﾟﾛｸｼ i18n hardcoded `g41.moe` → `__HOST__` placeholder
- g41.sh TUI switched to ANSI escape sequence incremental rendering (eliminates flicker)
- GitHub ﾘﾎﾟｼﾞﾄﾘ ｸﾘｴｲﾄd ｳｨｽﾞ topics

## 2026-06-11 ~ 2026-06-12

- ﾃﾞｲﾀ/function sepaﾚｲｼｵn (A/B/C layers): compose variable substitution, nginx ｻｲﾄ ｺﾝﾌｨｸﾞ generalization, ｻｰﾊﾞｰ.js ｴﾝﾌﾞｲﾗｵﾝﾒﾝﾄ injection
- Security hardening: dsock ﾆｭｰ ﾓｼﾞｭｰﾙ (Docker API ﾌﾟﾛｸｼ), BT supply chain locking, Redis password auｻﾞntication
- Health check stｱﾝﾄﾞardization (HTTP endpoint > ﾎﾟｰﾄ probe > kill -0 1)
- ﾓｼﾞｭｰﾙ renaming: pure tiles → `tile_*` prefix (5 ﾓｼﾞｭｰﾙs), pure ﾘﾝｸｽ → `ﾘﾝｸ_*` prefix (6 ﾓｼﾞｭｰﾙs)
- Frontend fixes: error ｺｰﾄﾞ pages, loading flicker, 404 response
- hy2 ﾓｼﾞｭｰﾙ privatization: `.ﾛｰｶﾙ/` hides subscription ﾌｧｲﾙs ｱﾝﾄﾞ nginx ｺﾝﾌｨｸﾞs
- g41.sh extended: auto-discoﾍﾞﾘｰ of `.ﾛｰｶﾙ/ｻｲﾄ/` ｱﾝﾄﾞ `.ﾛｰｶﾙ/ｳｪﾌﾞroot/`
- ｻｰﾊﾞｰ.js refactored: raw TCP socket → `redis` npm ﾊﾟｯｹｰｼﾞ ｳｨｽﾞ ﾊﾟｰsistent connection + pipeline batch writes

## 2026-06-10

- Initial audit: compose.yaml, g41.sh, ｵｰﾙ kｲｯﾂ/ ﾓｼﾞｭｰﾙs
