# Maintenance Log

[中文](../MAINTENANCE.md) | English | [日本語](MAINTENANCE.ja.md) 

## 2026-10-12

- **Retired the gh-proxy homepage tile and added a self-introduction tile, `tile_kitsunome`** (maintainer's request):
  - `tile_gh-proxy` lost `tile.json` + `i18n/`, and `depends` narrowed from `home, nginx` to `nginx`;
    **the tile is gone, the service is not** — `/gr/` still proxies. The directory name stays
    (renaming it would rename the deployed fragment and the `G41_KITS` entry); AGENTS.md now
    records it as a known exception and tells new modules not to copy the shape
  - The new tile `tile_kitsunome` (🐾 / short name `kitsunome` / `guide` with three blocks) says who
    maintains the site and how the work is verified; all three languages written in one pass. The copy
    carries only the front-facing part (G41KiTS is public and CD deploys it automatically); deployment
    details and private local records stay out of this repo — the boundary lives in `docs/*/tile_kitsunome.md`
  - Deployment: `kits add tile_kitsunome`, plus a manual removal of two leftovers
    (`.rd/data/tiles/tile_gh-proxy.json`, `.rd/data/i18n/tile_gh-proxy/` — after the `depends`
    narrowing `kits del` no longer finds them), then a hot reload
  - Measured: `/data/tiles` returns 12 items including `tile_kitsunome` and no `tile_gh-proxy`; the
    `kitsunome_*` keys exist in all three languages and `ghp_*` is gone; the three languages sort
    identically (kitsunome right after kihara777); homepage and `/gr/` both 200
  - The tile gained a **front-page link** (pointed out by the maintainer): <https://grg41.github.io/>
    (3 pages × 3 languages). The link text is the same in all three; the **href follows the homepage
    language** (zh → `/`, ja → `/ja/`, en → `/en/`); the block uses an i18n key rather than inline HTML
    so the L1b key-coverage check forces all three languages to be written
- **Fixed a silent failure in `kits verify`**: in `local m="$1" md="kits/$m"` the `$m` expands
  **before** the assignment, so `md` was always `kits/` — L1/L3/L4 and the "module not found" error
  all landed on the wrong level. Measured: `kits verify no-such-module` printed PASS and exited 0,
  while `kits add` uses it as its gate. After splitting the assignment all 31 modules pass again
  (no false positives), and four counterexamples (missing key / broken JSON / empty i18n dir /
  compose=file without Dockerfile) each flip it to FAIL
- **L1 now checks tile i18n key coverage**: a missing key, an i18n file that is not valid JSON, and an
  `i18n/` directory with no `*.json` each report an ERR. A missing key does **not** error on the page
  (`t()` renders the key name as-is), and a parse failure only reaches `console.error` in server.js
- **Two `kits reload` fixes plus one bookkeeping fix**: the k8s branch called `deploy/api`, but the api
  is the **second container of the redis Deployment**, so that exec could never work in this deployment;
  the compose branch now reports the real diagnosis (backend drift) using the pod label; and
  `kits add --dry-run` no longer writes `G41_KITS`
- **Found on the live host (not fixed, left to the maintainer)**:
  - The VPS `.env` had no `G41_BACKEND=k8s` (the deployment has long been k3s), so `kits reload` always
    took the compose branch; added with `./g41.sh backend k8s` this time. **Note: `deploy-local.sh`
    pushes `.env` wholesale and the local `.env` lacks that key, so the next push wipes it again**
  - The VPS `.env` has no `RELOAD_SECRET` (empty inside the container), and server.js **skips** the check
    when expected is empty. `/admin/` is not proxied by nginx today, so nothing is exposed — but the
    repository's `kits/redis/site/location.conf` carries `/admin/`, so reinstalling redis would publish
    that unauthenticated reload endpoint
  - `.gx/conf.d/locations/999-redis.conf` has a **different inode and older content** than the repository
    source (only `/data/`) — the classic shape of a hardlink replaced by rsync and never reinstalled, so
    the host and the repo disagree
  - The three language versions of this log already diverged before this entry (zh-only 2026-08-24 /
    06-24 / 06-22; en·ja-only 2026-07-14); this entry is synced in all three, the old divergence is untouched
- **Tile copy correction (pointed out by her)**: the name line read "キツのめ means 'fox's eye'" — that is
  **my own reading**, not where the name came from. The maintainer noted `kitsunome` was chosen with
  **つめ** (claw) in mind, and 小爪 comes from there; all three i18n files and the three doc versions now
  carry both halves (キツ (fox)・の・め + my reading + the つめ inside → 小爪)
- **Added a WP8 boot ring for the first-paint gap — and it caught the cause of cold-load blank pages**
  (the maintainer observed "the tiles took longer to load"):
  - Measured first: the server is not the bottleneck (API from inside the container:
    `/data/tiles` **2.6 ms**, `/data/i18n_zh` **2.7 ms**; first-paint payload ≈ 45 KB). The cost is
    **structural** — `init()` waits for all six requests, and `#g41-app` stays at `opacity:0` until then
  - Added `#g41-loading` (a pure-CSS five-dot ring, visible on the first frame before any JS;
    it degrades to a static five-dot ring under `prefers-reduced-motion`), with `endLoading()` inside
    `applyStatus()` (shared by the normal page and the status-code pages) and `bootFailed()` replacing
    the ring with "読み込みに失敗しました / Failed to load" plus the real error text — **a ring that
    spins forever claims "still loading", which is worse than the blank screen it replaces**
  - The failure state immediately caught itself: cold loads (no cache) failed **5/5** with
    `closeDetail is not defined` and the page stuck at `opacity:0`. Root cause: `tiles.js` sat **after**
    `G41.js`, while `G41.js` starts the data requests as soon as it runs and its `init()` callback needs
    functions from `tiles.js` — so a faster data response throws a ReferenceError (the old build had no
    failure state, so it looked like "blank page + one console line"; that is most likely what felt slower)
  - Fix: move `tiles.js` before `G41.js` (it has only top-level function declarations and does not depend
    on `G41.js`); cold loads on the live site then passed **5/5**
  - Criterion: a local stub delaying `tiles.js` by 3 s reproduced `is-failed` + ReferenceError +
    appOpacity 0 before the fix and, under the same conditions after it, ring removed / appOpacity 1 /
    no error; live verification used headless chromium (CDP: read the state, then take the pixels in one
    session) for the boot, failure and loaded states
- **Boot ring, second revision (bigger + visible label + scrim) and `Cache-Control` for static assets**
  (the maintainer sent a phone screenshot: "the loading animation did not appear or was not obvious"):
  - Measured: the ring really was too weak — at 412×915 the first version was a 64 px ring with 6 px
    dots (15% of the screen width in diameter, dots at 1.4%). Now the geometry scales with `vmin`
    (≈99 px / 9 px on a phone), a **visible** "読み込み中 / Loading" line sits under the ring, and the
    overlay carries a `rgba(0,0,0,.55)` scrim; the failure state is unchanged and `.g41-sr` was removed
    because the label is now visible
  - Criterion: local stub plus phone viewport (412×915 @2.6) screenshots before/after; CDP measured the
    overlay covering (0,0,412,915) and the ring+label column exactly centred (span 384–530, centre 457 = 915/2)
  - **Fixed the structural reason she may have been served old files**: the site sent no `Cache-Control`
    at all, so browsers used heuristic freshness from `Last-Modified` (10%) and could mix old HTML with
    new JS/CSS. `kits/nginx/store/nginx.conf` now adds
    `add_header Cache-Control "no-cache" always` in the server block; verified live that `no-cache` is
    served and that `If-None-Match` answers 304 (cheap revalidation)
  - **Found (not fixed — fixing it restarts the pod, the maintainer decides)**: the `reloader` container
    in `kits/nginx/k8s/deployment.yaml` has ① **no volumeMounts at all**, so it scans its own image's
    directories and can never see the mounted ConfigMap/Secret (`/tmp/.last` is stuck at 2026-09-26);
    ② even with mounts, `kill -HUP 1` targets the wrong process — the pod sets
    `shareProcessNamespace`, so PID 1 is the **pause** container. Consequence: after `k8s conf` / CD
    re-renders the ConfigMaps, **nginx keeps running the old config** until the pod restarts — this time
    `Cache-Control` only went live after a manual `kubectl exec … nginx -s reload`. The claim in
    `k8s/host/g41-cert-reload.sh` that nginx hot-reloads via this sidecar is therefore false
- **Boot ring, third revision: one chain, reveal order, no background while loading**
  (the maintainer gave three more points the same day, with three screenshots):
  - **One chain**: the old build had every dot run the whole keyframe track (pauses included), so the
    phases guaranteed distribution but never order — measured at one instant the adjacent gaps were
    **96°/282°/81°/147°/114°** (two dots almost overlapping), which makes "each doing its own thing"
    an accurate description. Now all five share one rotation curve (2.4 s /
    `cubic-bezier(.5,.08,.5,.92)`) and differ only by negative delays: the order can never break and
    the easing makes the arc breathe; dot sizes of 100/85/70/55/42% form a comet tail. Measured
    internal gaps **38–44°**, monotonic
  - **Reveal timing**: `main-entry` used to be added in `init()`, so the entrance animation played
    behind `opacity:0`. It moved into `revealApp()`: dismiss the ring first, then add the entrance
    class and fade in inside `requestAnimationFrame`. Live measurement:
    `ring 1 → (0.28 with entry:true and tiles:12) → app 1 → ring removed`
  - **No background while loading**: the overlay went from a translucent scrim to **opaque black**
    (a WP8 boot screen is flat colour anyway), so the artwork no longer competes for attention
  - Criterion: local stub plus quantitative CDP sampling (angular gaps, reveal order); under
    `--reduced`, `animationName=none` (a static ring)
- **First paint treated like a splash screen: all styles inlined + gzip enabled**
  (the maintainer: do not make the user wait long before they even see the loading animation):
  - Root cause measured: the three `<link rel="stylesheet">` tags (15.4 KB total) are
    **render-blocking** — the HTML can arrive and still leave a blank page. With a stub delaying the
    stylesheets by 3 s, **FCP = 3024 / 6908 ms**, i.e. exactly when the stylesheets arrived
  - All three CSS files are now **inlined into `G41.html`'s `<style>` block** (moved by a script that
    proves byte-for-byte equality), and the `.css` sources were deleted (single source). Under the same
    conditions **FCP = 36 / 928 ms** and `performance` shows **0** `/css/` requests. The CSP already had
    `style-src 'self' 'unsafe-inline'`, so inlining a `<style>` needs no policy change
  - **The site had no compression at all** (nginx defaults to off and nginx.conf had no `gzip`
    directive): now `gzip on` / `gzip_vary on` etc.; measured live, the homepage HTML drops from
    **19728 to 6873 bytes**
  - Deployment: `kits add home -C` plus a manual removal of the leftover `.wr/G41/css/` (reinstalling
    never deletes hardlinks whose source files are gone) + `kits add nginx -C` + `k8s conf` +
    `nginx -t` + a manual `nginx -s reload` (the reloader is still broken)
  - Live measurement: 600 ms after navigation the boot ring is already painted
    (`bg=rgb(0,0,0)`, `css:[]`, FCP 568 ms)
  - Instrument note: `curl -H 'Accept-Encoding: gzip'` does **not** decompress, so piping it into grep
    reads binary — that "any external stylesheets left?" check was invalid until redone with
    `--compressed`

| Commit | Description |
|--------|-------------|
| `ba86aba` | fix(g41.sh): kits verify's L1/L3/L4 never ran; tile i18n key coverage added |
| `4435b12` | feat(home): self-introduction tile tile_kitsunome (小爪 / キツのめ) |
| `8451fe9` | refactor(tile_gh-proxy): homepage tile retired, depends narrowed to nginx |
| `26afe10` | docs: three-language sync for tile_kitsunome / gh-proxy / kits-spec / AGENTS.md |
| `45b16f0` | fix(g41.sh): kits reload's k8s target was wrong — api is not a standalone Deployment |
| `b324278` | fix(tile_kitsunome): restore the つめ (claw) in the name line — "fox's eye" is my reading, not the origin |
| `e95ac78` | feat(tile_kitsunome): add the front-page link to the tile (each language points at its own copy) |
| `8b35b39` | feat(home): WP8 boot ring for the first-paint gap; boot failures are now visible |
| `7d3b7b8` | fix(home): cold-load blank pages were caused by the G41.js / tiles.js load order |
| `f2d7197` | fix(home): boot ring enlarged + visible label + scrim; `Cache-Control: no-cache` added |
| `e243c0c` | fix(home): ring v3 — five dots form one chain, reveal timing, no background while loading |
| `cb8cd28` | perf: first paint no longer waits — all styles inlined + nginx gzip enabled |

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