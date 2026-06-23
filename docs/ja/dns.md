# dns
[中文](../zh/dns.md) | [English](../en/dns.md) | [日本語](dns.md) | [ｶﾀﾘｯｼｭ](../katalish/dns.md) | [偽中国語](../pcn/dns.md)

AdGuard 再帰 DNS（DoT/DoH/DoQ 対応）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | acme,home,nginx |
| コンテナ | ns |
| イメージ | adguard/dnsproxy |

## インストール

```bash
./g41.sh kits add dns
```

## 注意

- 53/TCP+UDP（通常DNS）
- 853/TCP（DoT）
- 443/UDP（DoQ）
- DoH: /dns-query
- ヘルスチェック: nc -zw1 127.0.0.1 53
