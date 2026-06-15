# acme

[中文](acme.md) | [English](../en/acme.md) | [日本語](../ja/acme.md)

SSL 证书管理（acme.sh + ZeroSSL/Cloudflare DNS）。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core, dsock |
| 容器 | ca |

## 安装

```bash
./g41.sh kits add acme
```

## 注意

- 从 Dockerfile 本地构建（`FROM neilpang/acme.sh:3.1.3`）
- Docker API 通过 dsock 代理访问（`DOCKER_HOST=tcp://ds:2375`）
- 环境变量白名单：仅注入 `CF_Key`、`CF_Email`、`G41_DOMAIN`
- 证书输出到 `.ca/fc`（fullchain）和 `.ca/k`（私钥）
- 健康检查：`acme.sh --list`
- daemon 模式自动续期