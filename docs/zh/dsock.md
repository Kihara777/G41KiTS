# dsock

[中文](dsock.md) | [English](../en/dsock.md) | [日本語](../ja/dsock.md)

Docker API 安全代理 — 替代 docker.sock 直接挂载。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core |
| 容器 | ds |
| 镜像 | tecnativa/docker-socket-proxy |

## 安装

```bash
./g41.sh kits add dsock
```

## 注意

- 挂载 `/var/run/docker.sock` 只读（`:ro`）
- 限制 API 端点为 `CONTAINERS` + `EXEC` + `POST`
- acme 通过 `DOCKER_HOST=tcp://ds:2375` 连接
- autoheal 通过 `DOCKER_SOCK=tcp://ds:2375` 连接
- 替代直接 docker.sock 挂载以降低安全风险