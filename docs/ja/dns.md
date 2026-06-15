# dns

[中文](../zh/dns.md) | [English](../en/dns.md) | [日本語](dns.md)

AdGuard 再帰 DNS（DoT/DoH/DoQ 対応）。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | acme, home, nginx |
| コンテナ | ns |
| イメージ | adguard/dnsproxy:v0.81.3 |

## インストール

```bash
./g41.sh kits add dns
```

## 注意

- Docker Hub イメージ、`v0.81.3` に固定
- TCP DNS：53、UDP DNS：53
- DoT（DNS-over-TLS）：853/TCP
- DoH（DNS-over-HTTPS）：`/dns-query`
- DoQ（DNS-over-QUIC）：443/UDP
- ヘルスチェック：`nc -zw1 127.0.0.1 53`
