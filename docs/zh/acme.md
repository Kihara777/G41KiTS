# acme

[中文](acme.md) | [English](../en/acme.md) | [日本語](../ja/acme.md)

SSL 证书管理（acme.sh + ZeroSSL/Cloudflare DNS）

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core, dsock |
| 容器 | ca |
| 镜像 | 本地构建 |

## 安装

```bash
./g41.sh kits add acme
```

## 注意

- 通过 dsock 代理访问 Docker API
- 使用 Cloudflare DNS 验证签发证书
