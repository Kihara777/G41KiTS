# nginx
[中文](../zh/nginx.md) | English | [日本語](../ja/nginx.md)

TLS 1.3 / HTTP/3 gateway, reverse proxy to all backends

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core |
| 容器 | gx |
| 镜像 | nginx |

## Install

```bash
./g41.sh kits add nginx
```

## Notes

- 端口 80/443，HTTP/3 QUIC\n- 所有 location 通过 include 加载\n- 安全头：HSTS、CSP、X-Frame、Referrer

## Cache policy for static assets

Static files (HTML/CSS/JS/JSON) are always sent with `Cache-Control: no-cache`:

```nginx
add_header Cache-Control "no-cache" always;   # server block, alongside the security headers
```

**Why the default (no header at all) is wrong**: without `Cache-Control`, browsers apply
heuristic freshness based on `Last-Modified` (roughly 10%), so after a deploy a visitor can get a
**mix of old HTML with new JS/CSS**. On 2026-10-12 that is exactly why the new boot ring was
invisible (the page looked completely unchanged). This site has no filename fingerprinting, so
`no-cache` plus ETag (revalidation answers 304, which is cheap) is the only way to never ship a
mixed generation.

## How config changes take effect (the reloader sidecar)

The `reloader` container in `kits/nginx/k8s/deployment.yaml` is supposed to send nginx a SIGHUP when
`/etc/nginx` or `/certs` change. **Measured on 2026-10-12: it does not work**, for two reasons:

1. That container has **no volumeMounts at all** — it scans the nginx config directory inside its own
   image, so it can never see the mounted ConfigMap/Secret (`/tmp/.last` is stuck at 2026-09-26).
2. Even with the mounts, `kill -HUP 1` targets the wrong process: the pod sets
   `shareProcessNamespace`, so PID 1 is the **pause** container, not the nginx master
   (it should be `kill -HUP $(pgrep -f "nginx: master")`).

Consequence: after `k8s conf` / CD re-renders the ConfigMaps, **nginx keeps running the old config**;
only a pod restart applies it. The claim in `k8s/host/g41-cert-reload.sh` that nginx hot-reloads via
this sidecar is therefore false (after a certificate renewal nginx keeps serving the old certificate).
