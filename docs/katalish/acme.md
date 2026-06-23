# acme
[中文](../zh/acme.md) | [English](../en/acme.md) | [日本語](../ja/acme.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/acme.md)

SSL ｻｰﾃｨﾌｨｹｰﾄ management (acme.sh + ZeroSSL/Cloudflare DNS)

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | ｺｱ,dsock |
| 容器 | ca |
| 镜像 | neilpang/acme.sh |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add acme
```

## 注意

- 通过 DOCKER_HOST=tcp://ds:2375 连接 dsock\n- 环境变量：CF_Key、CF_Email、ACME_EMAIL\n- 证书存储在 .ca/ 目录