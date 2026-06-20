# acme

[中文](../zh/acme.md) | [English](acme.md) | [日本語](../ja/acme.md)

SSL certificate management via acme.sh + ZeroSSL/Cloudflare DNS.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core, dsock |
| Container | ca |
| Image | local build |

## Install

```bash
./g41.sh kits add acme
```

## Notes

- Connects to Docker API via `DOCKER_HOST=tcp://ds:2375`
- Uses ZeroSSL as CA with Cloudflare DNS challenge
- Only `CF_Key` and `CF_Email` env vars injected
- Certificates stored in `.ca/` persist dir
- Daemon mode auto-renews