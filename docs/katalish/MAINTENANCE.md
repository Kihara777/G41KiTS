# Maintenance Log

[中文](../../MAINTENANCE.md) | [English](../MAINTENANCE.en.md) | [日本語](../MAINTENANCE.ja.md) | [ｶﾀﾘｯｼｭ](MAINTENANCE.md) | [偽中国語](../pcn/MAINTENANCE.md)

## 2026-06-20

- Open-sourced: pushed `main` branch to GitHub
- Trilingual docs live (27 modules + module spec): zh:29 / en:29 / ja:29
- AGENTS.md rewritten in Chinese (292 lines), covering architecture, development workflow, common issues
- README added `.local/` local init section
- Trilingual maintenance logs (MAINTENANCE.md / en / ja)
- Trilingual NOTICE.md (third-party assets notice)

## 2026-06-18

- Removed all Docker version locks: Dockerfile FROM lines, compose image tags, npm package versions, ADD --checksum all switched to floating versions
- Fixed `g41.sh kits pack` failing on `set -e` due to missing `skills/` directory
- Full stack forced rebuild, 14/14 healthy

## 2026-06-16

- Two rounds of full security audits (4 sub-agents in parallel): 24 issues found, all fixed or accepted
- g41.sh hardening: `set -o pipefail`, `sed -i` → atomic writes (`sed > tmp && mv`), compose include uses line-number precise insertion
- autoheal crash fix: switched from willfarrell/autoheal Hub image to custom Dockerfile (master entrypoint, TCP socket support)
- CSP security headers layered configuration: strict for main site + relaxed for aria2/nix-cache/gh-proxy proxy paths
- tiles.js tracker embed XSS fix: `innerHTML` → `createElement` + `textContent`
- G41.js fetch added 5s timeout (`AbortSignal.timeout(5000)`)
- server.js all `catch(e){}` silent errors now log via `console.error`
- Open-source readiness audit passed: zero hardcoded domains/secrets, all sensitive files excluded via `.gitignore`
- tile_bilibili module created: Bilibili VTuber tile (trilingual i18n)
- tile_flake tile populated: 13 NixKits packages/patches/skills entries
- tile_gh-proxy i18n hardcoded `g41.moe` → `__HOST__` placeholder
- g41.sh TUI switched to ANSI escape sequence incremental rendering (eliminates flicker)
- GitHub repository created with topics

## 2026-06-11 ~ 2026-06-12

- Data/function separation (A/B/C layers): compose variable substitution, nginx site config generalization, server.js environment injection
- Security hardening: dsock new module (Docker API proxy), BT supply chain locking, Redis password authentication
- Health check standardization (HTTP endpoint > port probe > kill -0 1)
- Module renaming: pure tiles → `tile_*` prefix (5 modules), pure links → `link_*` prefix (6 modules)
- Frontend fixes: error code pages, loading flicker, 404 response
- hy2 module privatization: `.local/` hides subscription files and nginx configs
- g41.sh extended: auto-discovery of `.local/site/` and `.local/webroot/`
- server.js refactored: raw TCP socket → `redis` npm package with persistent connection + pipeline batch writes

## 2026-06-10

- Initial audit: compose.yaml, g41.sh, all kits/ modules
- Infrastructure setup: Metro/WP8.1 style homepage, Redis config API, multi-language i18n, KITS module system