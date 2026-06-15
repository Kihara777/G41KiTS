# acme

[中文](../zh/acme.md) | [English](acme.md) | [日本語](../ja/acme.md)

SSL certificate management (acme.sh + ZeroSSL/Cloudflare DNS).

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core, dsock |
| Container | ca |

## Install

```bash
./g41.sh kits add acme
```

## Notes

- Locally built from Dockerfile (`FROM neilpang/acme.sh:3.1.3`)
- Docker API accessed via dsock proxy (`DOCKER_HOST=tcp://ds:2375`)
- Environment variable whitelist: only `CF_Key`, `CF_Email`, `G41_DOMAIN` injected
- Certificate output to `.ca/fc` (fullchain) and `.ca/k` (private key)
- Health check: `acme.sh --list`
- Automatic renewal in daemon mode