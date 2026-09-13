# Maintenance Log

[中文](../MAINTENANCE.md) | English | [日本語](MAINTENANCE.ja.md) 

## 2026-09-13

- **Two new operational timers added** (k8s/host/), closing the automation gaps of k8s mode:
  - `g41-cert-reload.timer` (every 15 min): distributes the certificate to each consumer pod after
    cert-manager renewal. Handled per capability — nginx ships a reloader sidecar and hot-loads via
    SIGHUP (**no restart**); hy2/dns have no hot-reload and must be rolled. Idempotent via the
    sha256 of `tls.crt`; an expired certificate is rejected with `openssl -checkend 0` before distribution.
  - `g41-image-update.timer` (Sundays 04:30): compares upstream digests of floating tags and rolls out updates
  - `g41-notify.py`: SMTP notification with no third-party dependency; silently skipped when `G41_SMTP_*` is unset
- **Fixed three single-node deployment defects** (all verified in practice; guards and docs added):
  - `kits/nginx/k8s/deployment.yaml` gained `imagePullPolicy: Always` — `nginx:alpine` is a floating
    tag and defaults to `IfNotPresent` when unset, so `rollout restart` only reuses the cached image and
    an upstream release is **never pulled** (two earlier "successful updates" left the digest unchanged)
  - `maxSurge` zeroed for `dns`(53/853) and `download`(51413) — same reason as nginx(80/443): with
    `hostPort` on a single node, `maxSurge>0` leaves the new pod Pending forever on a held port
  - `k3s-standalone.service` gained `Conflicts=k3s.service`, and the timers now depend on
    `k3s-standalone` — the legacy `k3s.service` (disabled but still on disk, `Restart=always`) would
    fight standalone for `127.0.0.1:6444` and crash-loop the apiserver (restart counter reached 41)
- Docs corrected: `k8s/README.md` clarifies that this deployment does **not** install stakater/reloader,
  so the `reloader.stakater.com/auto` annotations on hy2/dns are inert; added "Certificate rotation"
  and "Scheduled tasks" sections
- `install-1gb.sh` now installs both timers; `.env.example` gained `G41_SMTP_*`; `.gitignore` ignores `__pycache__`
- **Local image builds moved to the native containerd path**: dockerd is disabled in k8s mode, so
  `docker build` + `save | ctr import` could not run. Now uses nerdctl + BuildKit's containerd worker
  (`buildkitd.service`); images are built straight into k3s's k8s.io namespace and overlayfs
  snapshotter, dropping the save/import steps
  - New `g41-image-build.sh`: auto-discovers deployed `compose=file` modules (skipping retired ones
    such as autoheal/dsock/acme) and infers the build context from the COPY path style
  - `g41.sh k8s build` prefers this path and falls back to docker when nerdctl is unavailable
  - The weekly task now decides whether to rebuild from a content hash of the Dockerfile plus every
    COPYed file, skipping unchanged modules and rolling the affected Deployment afterwards
  - Verified: bt/aria2/hexo/redis all rebuilt; a second run skipped everything, so it is idempotent
- **Removed the hexo blog module and the attic service** (at maintainer's request):
  - Deleted `kits/hexo` (including its `.hx` data and `.wr/hexo` static output, backed up to
    `/root/g41-removed-backup/` on the VPS beforehand), `kits/attic`, and the tile
    `kits/tile_attic` that hard-depends on attic; plus 9 module docs
  - k8s side: deleted the attic Deployment/Service, the hx Service and the hexo-build Job;
    cleared the leftover `.gx` site fragments and re-rendered the nginx ConfigMap — otherwise the
    `attic:8080` upstream would make **nginx fail to start** once the Service was gone; cleared
    Redis `data:tiles/tile_attic` and blanked `data:loaded` to trigger a re-import
  - Kept in sync: compose.yaml, G41_KITS, g41.sh (dropped the `k8s hexo` subcommand), the module
    lists in both ops scripts, AGENTS.md, the READMEs (3 languages), k8s/README.md, kits-spec.md
    and 1gb-stability.md
  - Retained the attic persist directory `.attic` (data not deleted, so it can be restored later);
    `docs/*/k8s-migration.md` stays as a historical record
  - Verified: all 7 Deployments Running, site 200, `/attic/` → 404, `/data/tiles` returns 11
    entries without tile_attic, both timers exit 0
- **Added the `tile_friends` friend-links tile** (the 12th tile, completing the homepage grid):
  - A `list`-type tile that expands the friend links on click; first entry is
    "Shiogiri's Mist-Star Bakery" (`https://shiogiri.com`, a mutual link)
  - Trilingual i18n, trilingual docs and a README showcase entry
  - 11 → 12 tiles: exactly 3 rows in the 4-column grid and 2 full cycles of the 6 METRO colours
- **Fixed a silent half-failure defect** (surfaced when the new tile triggered a reload):
  - `kits/redis/k8s/deployment.yaml`: the `REDIS_PASSWORD` secretKeyRef changed from
    `optional: true` to **required**. With `optional`, a missing key in `g41-env` is injected as
    an **empty string** instead of an error → redis starts with `--requirepass ""` and the api
    cannot authenticate (`NOAUTH HELLO`), showing up as `/data/*` returning **502** while the Pod
    still reads Running. This was the actual cause of the data-endpoint outage; requiring the key
    makes a missing key leave the Pod Pending with a clear error.
  - `g41.sh k8s_apply_base`: pre-flight check that `.env` contains `REDIS_PASSWORD`, failing early
    so a keyless Secret is never generated again. (`RELOAD_SECRET` is excluded — it only affects
    the hot-reload endpoint and already reports its own error.)
  - Also added `REDIS_PASSWORD` to the VPS `.env` (it had been missing, a known pitfall)
- Post-check: all 7 Pods Running with the new redis pod at **0 restarts**, `/data/tiles` returns
  **12** entries including tile_friends, and all three i18n locales resolve correctly
- **Cleaned up stale content and fixed a missing GC** (found while assessing the k3s facility):
  - **Root cause**: kubelet's image GC only fires once **disk usage exceeds 85%** (default
    threshold), while this box has sat around 30% — so GC never ran and orphaned snapshots
    accumulated without bound
  - Measured the image store at **8.6 GB** against only 2.7 GB actually in use — **5.9 GB of
    orphaned snapshots** left by deleted/rolled-out images
  - Fix: `g41-image-update.sh` now performs active reclamation at the end
    (`nerdctl system prune`, which keys off "referenced by a container" and keeps every in-use
    image; safer than `ctr images prune --all`, which also drops tags and forces re-pulls)
  - Explicitly deleted 7 images verified to have no references: `tracker:local` 440MB,
    `local-path-provisioner` 85MB, `attic` 83MB, `hexo:local` 79MB, `acme:local` 36MB,
    `stakater/reloader` 15MB, `cert-manager-startupapicheck` 14MB, plus their orphaned digest refs
  - Cleaned leftover data: `.rd/data/i18n/tile_attic/`, `.rd/data/tile_apps/hexo.json`
  - **Measured**: containerd 8.6 GB → **2.7 GB** (5.9 GB freed), disk 32G → 26G, all 7 Pods
    Running throughout; the GC step is idempotent (a second run reports "nothing to reclaim")
- **Assessed replacing cert-manager with nginx's native ACME: not viable**, keeping the current
  mechanism. The decisive blocker: the official docs and the source README of
  `ngx_http_acme_module` both state it supports **HTTP-01 only**, while our certificate carries
  the `*.g41.moe` wildcard — and RFC 8555 requires wildcards to be validated via **DNS-01 only**.
  Secondary issues: the extra domains `maidkihara.moe`/`kitsunori.moe` resolve to Cloudflare
  rather than this host; the module produces no k8s Secret, which would leave hy2/dns without a
  certificate source; and the package is version-locked to the nginx release (needs 1.29.8, this
  box runs 1.31.5). See `docs/zh/nginx-native-acme-assessment.md`
- **Homepage tiles now sort by their front-facing short name**: the server returned tiles in
  `id` order (`tile_apps`, `tile_friends`, …), which is unrelated to what users read and left the
  order without any discernible rule. `buildTiles()` now sorts by `label[0]` (the short name shown
  on the tile) before rendering, falling back to `label[1]` and then `id`; the sort runs **before**
  the `METRO[idx%6]` colour assignment so each tile keeps its colour instead of drifting with the
  returned order
  - Verified identical order across all three languages: apps → bilibili → dns → flake → friends →
    github → homete → kihara777 → links → mail → nix → tracker
  - Also fixed two non-conforming English descriptions: `proxy`→`Reverse Proxy`,
    `resolve`→`DNS Resolver`
  - ⚠️ **Pitfall**: the change must be installed via `g41.sh kits add -C`. Overwriting the `kits/`
    source with plain rsync replaces the inode and **breaks the hard link to `.wr/G41/`** (the path
    nginx actually serves), which looks like "edited but the site never changed" — exactly the
    false positive hit here
  - Also removed 6 stale i18n directories (`apps`/`flake`/`gh-proxy`/`links`/`nix-cache`/
    `tile_homete`, leftovers from old module names). Their contents **differ** from the current
    ones and the loader merges via `Object.assign`, so the stale values competed with the live ones

| Commit | Description |
|--------|-------------|
| `8fdb78c` | feat(k8s): add certificate distribution and weekly image update timers |
| `031a146` | fix(k8s): fix three single-node rollout defects and update docs |
| `5a8ff40` | feat(k8s): build local images via the native containerd path (no dockerd) |
| `1e164a3` | feat: remove the hexo blog module and the attic service |
| `8e87063` | feat: add the tile_friends friend-links tile, completing the 12th tile |
| `ba4126e` | docs: assess nginx native ACME as a cert-manager replacement (not viable) |
| `c8aa095` | docs: add the k3s facility assessment — resource headroom and full k3s migration |
| `f4fdbc3` | feat(k8s): add GC to the weekly image task to reclaim orphaned snapshots |
| `98b6441` | feat(home): sort tiles by their front-facing short name |

## 2026-08-27

- **RAM upgrade landed**: VPS 958MB → 1.6GB (target 2GB); cert-manager switched from monthly-window renewal to **always-on** (replicas=1); the renewal-window cron entries were removed (only the apt-upgrade task remains)
- **CD pipeline verified**: GitHub Actions `deploy.yml` (ssh-deploy@v6 + ssh-action@v1) passed end-to-end (~28s), secrets configured; rsync added `--exclude=.env --exclude=.local.sh` to protect VPS private content
- Added `docs/zh/1gb-stability.md`: 1GB stability research conclusion (tmpfs kine + swap tiering + component slimming)
- Extra domains conclusion: cert-manager has a cleanup race when several domains share one `_acme-challenge` CNAME target — deferred; reissue needs unique per-domain CNAME targets
- git fully pushed to GitHub (ee62381); image policy unified to floating tags

## 2026-08-26

- **Completed k3s migration**: Docker Compose → Kubernetes (k3s v1.36.3); 12 pods consolidated into 8
  (hexo static-ified, tracker merged into api process, api merged into redis pod, aria2+bt merged)
- Control plane: tmpfs kine (state backup/restore units), k3s-standalone (file-log decoupled from
  journald, MemoryMin 400M, OOM protection); cert-manager issued cert (g41.moe + *.g41.moe)
- g41.sh: `init k8s`, `k8s stage|conf|hexo` subcommands, generative include rewrite
- 1GB host tuning scripted: journald volatile / zram / swappiness / snapd disabled / fail2ban allowlist
- CD pipeline: GitHub Actions (public content) + deploy-local.sh (private content via local SSH)
- i18n full audit passed; home desc updated to k3s, tile_flake synced to current NixKits
- Root causes fixed: journald freeze, k3s.service unit, bittorrent-tracker ESM, REDIS_HOST hardcode, redis auth mismatch

## 2026-07-14

- Added `blc_template` provides type to blc module: dependent modules can distribute blivechat custom templates via `blc_template/` directory
- Added `custom_public/templates` volume mount to blc compose.yaml (container path `/mnt/data/data/custom_public/templates`)
- Added full blc_template type handling to g41.sh: install, uninstall, and check (kits_add / kits_del / kits_check)
- Updated blc trilingual docs (ja/en/zh) with template distribution usage
- Created blct_tts module: TTS voice broadcast custom template for blivechat
  - Hybrid mode: default-style visual rendering + Web Speech API voice
  - Language-adaptive: kana → ja-JP with Chinese engine fallback
  - Dual queue: sequential normal + priority queue for gifts/members
  - Interrupted danmaku replay, right-click settings panel (localStorage)
  - Fixed blc server.conf: added proxy_pass to custom_public location

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