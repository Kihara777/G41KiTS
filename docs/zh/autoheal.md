# autoheal

[中文](autoheal.md) | [English](../en/autoheal.md) | [日本語](../ja/autoheal.md)

自动重启不健康的 Docker 容器

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core,dsock |
| 容器 | ah |
| 镜像 | 本地构建 |

## 安装

```bash
./g41.sh kits add autoheal
```

## 注意

- 自定义 Dockerfile（基于 willfarrell/autoheal），支持 TCP socket\n- 通过 DOCKER_SOCK=tcp://ds:2375 连接 dsock\n- 每 5 秒检查一次容器健康状态
