# nginx

[中文](../zh/nginx.md) | [English](nginx.md) | [日本語](../ja/nginx.md)

TLS 1.3 / HTTP/3 gateway — reverse proxy to all backends.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core |
| Container | gx |
| Image | nginx |

## Install

```bash
./g41.sh kits add nginx
```

## Notes

- Listens on 80/443 with HTTP/3 QUIC enabled
- Security headers: HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- Proxy paths (nix-cache, gh-proxy) get relaxed CSP overrides
- Locations assembled from each module's `site/` configs
- Upstreams discovered via `kit_resolve`