# redis

[中文](redis.md) | [English](../en/redis.md) | [日本語](../ja/redis.md)

Redis 配置存储 + Node.js HTTP API 桥接。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core, nginx |
| 容器 | rd（Redis）、ra（API） |
| 镜像 | 本地构建 |

## 安装

```bash
./g41.sh kits add redis
```

## 注意

- Redis 通过 `REDIS_PASSWORD` 认证（`--requirepass`）
- API 在 5800 端口提供 `/data/` 和 `/link/` 端点
- 数据从 `.rd/data/` 加载至 Redis，由 `data:loaded` 标志控制
- 加载阶段使用 `multi()` pipeline 批量写入
- 其他容器无法直接访问 Redis