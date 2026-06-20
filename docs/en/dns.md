# dns

[中文](../zh/dns.md) | [English](dns.md) | [日本語](../ja/dns.md)

AdGuard recursive DNS with DoT/DoH/DoQ.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | acme, home, nginx |
| Container | ns |

## Install

```bash
./g41.sh kits add dns
```

## Notes

- Listens 53/TCP+UDP, 853/TCP(DoT), 443/UDP(QUIC/DoQ)
- DoH path `/dns-query` (through nginx proxy)
- Uses TLS certs (shares `.ca/` with nginx)
- Config deployed via `.local/config.yaml`