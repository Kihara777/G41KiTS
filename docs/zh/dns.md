# dns

[中文](dns.md) | [English](../en/dns.md) | [日本語](../ja/dns.md)

AdGuard 递归 DNS，支持 DoT/DoH/DoQ。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | acme, home, nginx |
| 容器 | ns |
| 镜像 | adguard/dnsproxy:v0.81.3 |

## 安装

```bash
./g41.sh kits add dns
```

## 注意

- Docker Hub 镜像，固定版本 `v0.81.3`
- TCP DNS：53、UDP DNS：53
- DoT（DNS-over-TLS）：853/TCP
- DoH（DNS-over-HTTPS）：`/dns-query`
- DoQ（DNS-over-QUIC）：443/UDP
- 健康检查：`nc -zw1 127.0.0.1 53`
