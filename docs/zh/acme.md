# acme

[中文](acme.md) | [English](../en/acme.md) | [日本語](../ja/acme.md)

SSL 证书管理 — acme.sh + ZeroSSL/Cloudflare DNS。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core, dsock |
| 容器 | ca |
| 镜像 | neilpang/acme.sh |

## 安装

```bash
./g41.sh kits add acme
```

## 注意

- 通过 `DOCKER_HOST=tcp://ds:2375` 使用 dsock 代理操作 Docker
- 证书文件存储在 `.ca/` 持久化目录
- 域名通过 `G41_DOMAIN` + `G41_EXTRA_DOMAINS` 环境变量配置