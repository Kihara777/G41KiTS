# dns
[中文](../zh/dns.md) | [English](../en/dns.md) | [日本語](../ja/dns.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/dns.md)

AdGuard ﾘｶｰｼﾌﾞ DNS ｳｨｽﾞ DoT/DoH/DoQ

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | acme,home,nginx |
| ｺﾝﾃﾅ | ns |
| ｲﾒｰｼﾞ | adguard/dnsproxy |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add dns
```

## 注意

- 53/TCP+UDP (plain DNS)
- 853/TCP (DoT)
- 443/UDP (DoQ)
- DoH: /dns-query
- ﾍﾙｽ ﾁｪｯｸ: nc -zw1 127.0.0.1 53