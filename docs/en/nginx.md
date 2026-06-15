# nginx

[中文](../zh/nginx.md) | [English](nginx.md) | [日本語](../ja/nginx.md)

TLS 1.3 / HTTP/3 gateway, reverse proxy for all backends.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core |
| Container | gx |

## Install

```bash
./g41.sh kits add nginx
```

## Notes

- Locally built from Dockerfile (`FROM alpine:3.23.4`)
- store/ provides base nginx.conf + mime.types
- All locations loaded via `include /etc/nginx/conf.d/locations/*.conf`
- Security headers: HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy, CSP
- Proxy paths (/nichan/, /gr/, etc.) override CSP with relaxed policy
- QUIC/HTTP3 enabled via `quic_bpf on`