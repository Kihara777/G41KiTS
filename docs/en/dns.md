# dns
[中文](../zh/dns.md) | [English](dns.md) | [日本語](../ja/dns.md) | [ｶﾀﾘｯｼｭ](../katalish/dns.md) | [偽中国語](../pcn/dns.md)

AdGuard recursive DNS with DoT/DoH/DoQ

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | acme,home,nginx |
| Container | ns |
| Image | adguard/dnsproxy |

## Install

```bash
./g41.sh kits add dns
```

## Notes

- 53/TCP+UDP (plain DNS)
- 853/TCP (DoT)
- 443/UDP (DoQ)
- DoH: /dns-query
- Health check: nc -zw1 127.0.0.1 53
