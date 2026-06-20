# dns

[中文](../zh/dns.md) | [English](../en/dns.md) | [日本語](dns.md)

AdGuard 再帰 DNS、DoT/DoH/DoQ 対応。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | acme, home, nginx |
| コンテナ | ns |

## インストール

```bash
./g41.sh kits add dns
```

## 注意

- 53/TCP+UDP、853/TCP(DoT)、443/UDP(QUIC/DoQ) で待ち受け
- DoH パス `/dns-query`（nginx プロキシ経由）
- TLS 証明書を使用（nginx と `.ca/` を共有）
- 設定は `.local/config.yaml` でデプロイ