# dsock
[中文](../zh/dsock.md) | [English](../en/dsock.md) | 日本語 | [ｶﾀﾘｯｼｭ](../katalish/dsock.md) | [偽中国語](../pcn/dsock.md)

Docker API セキュリティプロキシ、docker.sock 直接マウントの代替

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core |
| 容器 | ds |
| 镜像 | tecnativa/docker-socket-proxy |

## インストール

```bash
./g41.sh kits add dsock
```

## 注意

- 挂载 /var/run/docker.sock 只读（:ro）\n- 限制 API 端点为 CONTAINERS + EXEC + POST
