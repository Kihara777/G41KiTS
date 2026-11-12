# G41KiTS Architecture Overview
[中文](../zh/architecture.md) | English | [日本語](../ja/architecture.md) 

One picture of **how a module travels from declaration to production, which pipeline carries it, what the
single source for each pipeline is, and where the checks live.**

Field-level detail is in [kits-spec.md](kits-spec.md); the migration story is in
[k8s-migration.md](k8s-migration.md).

## In one sentence

The repository is the only source; there is no second copy of content on the host. Every downstream artifact
is generated one-way from `kits/`, and lands in a ConfigMap, in containerd, or in cluster manifests.

## What a module is

```
kits/<name>/
├── info.json          declaration
├── tile.json          ┐
├── app.json           │ content files (the provider's `provides` decides which pipeline carries them)
├── link.json          │
├── i18n/<lang>.json   │
├── data/<name>.json   ┘
├── k8s/*.yaml         cluster manifests (a module is only deployed when it has these)
├── store/             files hardlinked into the running directory (a few modules)
└── .local/            deployment-specific files (never committed)
```

## The four pipelines

```
                      ┌──────────────────────────────────────────────┐
   kits/*/info.json   │  the repository is the only source           │
   + content files    └──────────────────────────────────────────────┘
          │
          ├──(1) kits content ──→ dist/g41-content.yaml ──apply──→ ConfigMap g41-content
          │        │             (the type → directory map ships with it as _map.json)
          │        │                                                  │
          │        │                                                  ▼
          │        │                                    redis Pod: /seed volume
          │        │                                                  │
          │        │                                     loader materialises → Redis
          │        │                                                  │
          │        │                                                  ▼
          │        │                                                frontend
          │        │
          ├──(2) kits api-src ──→ dist/g41-api-src.yaml ──apply──→ ConfigMap g41-api-src
          │                                                          │
          │                                            redis Pod: /app/server.js
          │
          ├──(3) g41-image-build.sh ──→ containerd: g41k8s/<module>:<version> (+ :local alias)
          │
          └──(4) kits export <module> ──→ dist/<module>-<version>.yaml ──kubectl apply──→ cluster

  Load trigger: content is loaded only when Redis has no `data:loaded`. After changing content or
  source, run `DEL data:loaded` and restart the redis Pod — otherwise the Pod restarts but
  **does not reload**.
```

## Type and destination are decided by the provider

A module's type does not come from a filename; it comes from **what it depends on** and what that provider
declares it accepts.

```
home/info.json:
  provides: [{dir:"tiles", accepts:["tile"], file:"tile.json", ext:"json", content:true},
             {dir:"i18n",  accepts:["i18n"], file:"i18n",     ext:"json", content:true}]

kits/tile_friends/   depends on home and has tile.json + i18n/  → consumes tile and i18n
kits/dns/            has tile.json and depends on home → same
```

`kits content` derives a map and ships it with the seed:

```
_map.json = { "tile": {dir:"tiles",  file:"tile.json", ext:"json", shape:"file"},
              "i18n": {dir:"i18n",   file:"i18n",      ext:"json", shape:"dir"},
              "app":  {dir:"tile_apps",  ...}, "link": {dir:"tile_links", ...},
              "data": {dir:"",       ...} }        ← empty dir = the Redis data root

Both the writing side and the reading side of the loader use this table — changing only one side
produces "materialised successfully but cannot be read".
```

`content: true` means "this type travels through the content seed". `site` (nginx config), `webroot`
(static assets) and `blc_template` are not marked and each has its own supply path.

## From repository to production

```
git push
   │
   ├─ GitHub Actions: check.yml (21 gate checks, never touches production)
   └─ GitHub Actions: deploy.yml
        ├─ guard: HEAD == origin/main? (otherwise refuse — a backlogged old run must not roll production back)
        ├─ rsync to the deploy host
        ├─ kits content → apply g41-content
        ├─ kits api-src → apply g41-api-src
        └─ k8s apply --all
```

Images are not on this path: **self-built images live only in the deploy host's containerd** and are built
with `/opt/g41/k8s/host/g41-image-build.sh` (no argument = every deployed module). That is the recovery path.

## Command surface

| Command | What it does | When to use it |
|---------|--------------|----------------|
| `kits install <m>` | verify → build image → refresh seed/source → bundle → apply (installs dependencies) | install one module |
| `kits uninstall <m>` | delete objects + drop the module from the seed (refuses while others depend on it) | remove one module |
| `kits update <m> --to <v> --build` | bump version + build + bundle | upgrade |
| `kits rollback <m>` | go back to an older bundle in `dist/` | emergency rollback (**cluster only — fix the repo too**) |
| `kits status [--cluster]` | ledger: version / pod group / image / content keys | "what is installed right now" |
| `kits health` | five checks | "does production match the repository" |
| `kits images --verify` | are the manifest-referenced tags present in containerd | before applying |
| `kits remote <url>` | install one manifest from a remote URL | external extensions |

Under the k8s backend, `kits add` / `kits del` **forward** to `install` / `uninstall` — their original
host-assembly path has no consumers in k8s mode.

## Where the checks live

| Check | Location | What runs | Failure means |
|-------|----------|-----------|---------------|
| 21 gate checks | GitHub Actions (every push) | syntax, manifest schema, byte-exact content round-trip, image tag matching version, ConfigMap reference closure, README and health self-tests | this commit should not merge |
| 32 loader self-tests | inside the container (`G41_FS_SELFTEST=1`) | seed key parsing, map-driven behaviour, stale-key pruning, readDir filtering | the loader logic is broken |
| 5 production checks | deploy host, every six hours (`g41-health.timer`) | image presence, drift, content seed matching the repo key by key, api source matching, site returning 200 | production diverged from the repository; **notified only on state change** |
| Three-state rule | every check | 0 pass / 1 failure / 2 could not verify | 2 is not a pass |

## Known limits

1. **New types still need code**: `_map` makes "where it goes" data, but the loader's semantics (a tile is a
   list entry, i18n merges per language) branch on the type name. That predates the ConfigMap change.
2. **`dir` is also the Redis key namespace**: changing `tile_apps`'s `dir` changes the keys and the frontend
   stops recognising them. "The provider decides the destination" holds only outside the key namespace.
3. **No image registry**: images live only in the deploy host's containerd. They can be rebuilt from git, but
   there is no remote copy.
4. **`kits add all` is slow**: 25 modules each run verify + export, so it takes minutes.
