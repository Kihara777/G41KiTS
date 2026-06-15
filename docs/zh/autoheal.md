# autoheal

[中文](autoheal.md) | [English](../en/autoheal.md) | [日本語](../ja/autoheal.md)

自动重启不健康的 Docker 容器。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | 服务 |
| 依赖 | core, dsock |
| 容器 | ah |

## 安装

```bash
./g41.sh kits add autoheal
```

## 注意

- 使用自定义 Dockerfile 本地构建（基于 `willfarrell/autoheal`），**非 Hub 镜像**
- 通过 dsock 代理访问 Docker API（`DOCKER_SOCK=tcp://ds:2375`）
- 监控范围：所有带健康检查的容器（`AUTOHEAL_CONTAINER_LABEL=all`）
- 健康检查使用 `pgrep -f autoheal` 确认守护进程运行
- 默认检测间隔 5 秒，启动等待 30 秒
- 仅重启 `health: unhealthy` 的容器，跳过 `restarting` 状态的容器
