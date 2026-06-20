# dns

[中文](dns.md) | [English](../en/dns.md) | [日本語](../ja/dns.md)

AdGuard 递归 DNS，支持 DoT/DoH/DoQ。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | acme, home, nginx |
| 容器 | ns |

## 安装

```bash
./g41.sh kits add dns
```

## 注意

- 监听 53/TCP+UDP、853/TCP(DoT)、443/UDP(QUIC/DoQ)
- DoH 路径 `/dns-query`（通过 nginx 代理）
- 使用 TLS 证书（与 nginx 共享 `.ca/`）
- 配置文件通过 `.local/config.yaml` 部署