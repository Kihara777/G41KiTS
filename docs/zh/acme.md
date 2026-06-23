# acme
中文 | [English](../en/acme.md) | [日本語](../ja/acme.md) | [ｶﾀﾘｯｼｭ](../katalish/acme.md) | [偽中国語](../pcn/acme.md)

SSL 证书管理（acme.sh + ZeroSSL/Cloudflare DNS）

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core,dsock |
| 容器 | ca |
| 镜像 | neilpang/acme.sh |

## 安装

```bash
./g41.sh kits add acme
```

## 注意

- 通过 DOCKER_HOST=tcp://ds:2375 连接 dsock\n- 环境变量：CF_Key、CF_Email、ACME_EMAIL\n- 证书存储在 .ca/ 目录
