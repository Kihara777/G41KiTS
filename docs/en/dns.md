# dns

[中文](../zh/dns.md) | [English](dns.md) | [日本語](../ja/dns.md)

AdGuard recursive DNS with DoT/DoH/DoQ.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | acme, home, nginx |
| Container | ns |
| Image | adguard/dnsproxy:v0.81.3 |

## Install

```bash
./g41.sh kits add dns
```

## Notes

- Docker Hub image, pinned to `v0.81.3`
- TCP DNS: 53, UDP DNS: 53
- DoT (DNS-over-TLS): 853/TCP
- DoH (DNS-over-HTTPS): `/dns-query`
- DoQ (DNS-over-QUIC): 443/UDP
- Health check: `nc -zw1 127.0.0.1 53`
