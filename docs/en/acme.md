# acme

[中文](acme.md) | [English](../en/acme.md) | [日本語](../ja/acme.md)

SSL cert management (acme.sh + ZeroSSL/Cloudflare DNS)

## Info

| Item | Value |
|------|-----|
| 类型 | service |
| 依赖 | core, dsock |
| 容器 | ca |
| 镜像 | local build |

## Install

```bash
./g41.sh kits add acme
```

## Notes

- Accesses Docker API through dsock proxy
- Issues certs via Cloudflare DNS verification
