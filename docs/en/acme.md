# acme
[中文](../zh/acme.md) | English | [日本語](../ja/acme.md) | [ｶﾀﾘｯｼｭ](../katalish/acme.md) | [偽中国語](../pcn/acme.md)

SSL certificate management (acme.sh + ZeroSSL/Cloudflare DNS)

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core,dsock |
| 容器 | ca |
| 镜像 | neilpang/acme.sh |

## Install

```bash
./g41.sh kits add acme
```

## Notes

- 通过 DOCKER_HOST=tcp://ds:2375 连接 dsock\n- 环境变量：CF_Key、CF_Email、ACME_EMAIL\n- 证书存储在 .ca/ 目录
