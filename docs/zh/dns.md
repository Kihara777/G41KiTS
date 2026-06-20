# dns

[中文](dns.md) | [English](../en/dns.md) | [日本語](../ja/dns.md)

AdGuard 递归 DNS，支持 DoT/DoH/DoQ

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | acme,home,nginx |
| 容器 | ns |
| 镜像 | adguard/dnsproxy |

## 安装

```bash
./g41.sh kits add dns
```

## 注意

- 53/TCP+UDP（普通DNS）
- 853/TCP（DoT）
- 443/UDP（DoQ）
- DoH: /dns-query
- 健康检查: nc -zw1 127.0.0.1 53
