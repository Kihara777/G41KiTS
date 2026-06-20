# dns
[中文](dns.md) | [English](../en/dns.md) | [日本語](../ja/dns.md)
AdGuard 递归 DNS — DoT/DoH/DoQ。
## 基本信息
| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | acme, home, nginx |
| 容器 | ns |
| 镜像 | adguard/dnsproxy |
## 安装
```bash
./g41.sh kits add dns
```
## 注意
- DNS 监听: 53/TCP+UDP, 853/TCP (DoT), 443/UDP (QUIC)
- DoH 端点: /dns-query
- 依赖 acme 提供 TLS 证书
