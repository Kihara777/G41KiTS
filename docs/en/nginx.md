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

## Compression (gzip)

```nginx
gzip on;  gzip_comp_level 5;  gzip_min_length 256;  gzip_proxied any;  gzip_vary on;
gzip_types text/plain text/css application/javascript application/json image/svg+xml application/manifest+json;
```

**Before 2026-10-12 there was not a single `gzip` directive** (nginx defaults to off), so the homepage
HTML (~19.7 KB with the styles inlined) and the JS shipped uncompressed. Measured: `G41.html` →
**6.9 KB**, `G41.js` 7.0 KB → ~2 KB. `gzip_vary on` pairs with `Cache-Control: no-cache` so caches
keep encodings apart.

## Splash text localisation

The splash line (`読み込み中 / Loading`) must be readable **before any JS and any extra request** —
a client-side script would either arrive too late (an extra round trip) or be blocked by the CSP
(`script-src` is `'self'`, so inline scripts are not allowed). It is therefore substituted **server-side**
by `Accept-Language`:

```nginx
map $http_accept_language $g41_loading_text {   # http block
    default       "Loading";
    "~*^\s*zh"    "载入中";
    "~*^\s*ja"    "読み込み中";
    "~*^\s*en"    "Loading";
}
sub_filter_once on;                              # server block
sub_filter '読み込み中 / Loading' $g41_loading_text;
```

- **First language wins**, the same rule as `G41.js`'s `detectLang`; `zh` uses simplified characters
  (consistent with the rest of the site's Chinese)
- The response now varies by `Accept-Language`, so `Vary` must mention it. `gzip_vary` is switched off
  and the server block emits a single `Vary: Accept-Encoding, Accept-Language` instead of two headers
- The replaced string is the **bilingual fallback** in `G41.html` (still readable when the file is opened
  directly) — editing the copy means touching both places
- Known boundary: nginx cannot see the language preference in `localStorage`, so a visitor who manually
  switched to Chinese on a Japanese device sees the Japanese splash for a second or two before the app
  applies their choice
