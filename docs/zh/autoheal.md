# autoheal

[中文](autoheal.md) | [English](../en/autoheal.md) | [日本語](../ja/autoheal.md)

自动重启不健康容器（本地 Dockerfile 构建）

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core, dsock |
| 容器 | ah |
| 镜像 | 本地构建 |

## 安装

```bash
./g41.sh kits add autoheal
```

## 注意

- 基于 willfarrell/autoheal 的本地构建
- 支持 TCP socket 连接 dsock 代理
