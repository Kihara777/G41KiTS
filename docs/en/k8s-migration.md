# G41KiTS → k3s Migration Guide

Migration from Docker Compose to k3s. Dual-track coexistence, zero data migration, reversible.

## Prerequisites

- **RAM ≥ 1GB** (the 1GB configuration below is proven on a 958MB VPS)
- Repo synced (includes `k8s/`, `kits/*/k8s/`, latest `g41.sh`)
- Backup first: `./g41.sh kits pack -SAL`

## Deploy

```bash
# One-shot: installs slim k3s + host tuning + staged deployment
./g41.sh init k8s
```

This installs k3s (traefik/metrics-server/servicelb/local-storage disabled), applies
the tmpfs-kine + state backup/restore systemd units, tunes the host (journald volatile,
zram, swappiness, snapd off, fail2ban allowlist), then deploys workloads in dependency
order via `k8s stage`.

## 1GB specifics (what `init k8s` does)

1. **tmpfs kine** — the sqlite datastore lives in `/dev/shm` (~19MB); a 5-min timer
   backs it up to disk and a prep unit restores it on boot.
2. **k3s-standalone unit** — file-based logging (decoupled from journald, which can
   freeze the k3s process), `MemoryMin=400M`, `OOMScoreAdjust=-900`, `Restart=always`.
3. **Disk swap + zram** — workload overflow goes to swap; kine stays in RAM.

## Daily operations

| Task | Command |
|---|---|
| Apply all | `./g41.sh k8s apply --all` |
| Staged deploy | `./g41.sh k8s stage` |
| Regenerate nginx conf | `./g41.sh k8s conf` |
| Rebuild hexo blog | `./g41.sh k8s hexo` |
| Rebuild images | `./g41.sh k8s build` |
| Status | `./g41.sh k8s status` |

## Certificates

cert-manager issues `g41.moe` + `*.g41.moe` (Let's Encrypt, Cloudflare DNS01). It is
scaled to 0 most of the time; a monthly cron opens a 2-hour renewal window on the 1st.

## Rollback

```bash
./g41.sh backend compose
kubectl delete namespace g41
docker compose start   # containers remain; data dirs are shared
```

## Architecture notes

- **8 pods** (12 → 8): hexo static-ified (on-demand build job), tracker merged into the
  api process, api merged into the redis pod, aria2+bt merged into one pod.
- Service names match nginx upstreams (exception: `hx` for hexo, `ra` for api).
- External ports are hostPort/hostNetwork, identical to compose (80/443/53/853/51413).
- See `k8s/README.md` for full architecture decisions.
