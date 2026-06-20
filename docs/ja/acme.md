# acme

[中文](../zh/acme.md) | [English](../en/acme.md) | [日本語](acme.md)

SSL 証明書管理（acme.sh + ZeroSSL/Cloudflare DNS）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core,dsock |
| 容器 | ca |
| 镜像 | neilpang/acme.sh |

## インストール

```bash
./g41.sh kits add acme
```

## 注意

- 通过 DOCKER_HOST=tcp://ds:2375 连接 dsock\n- 环境变量：CF_Key、CF_Email、ACME_EMAIL\n- 证书存储在 .ca/ 目录
