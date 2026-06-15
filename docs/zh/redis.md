# redis

[中文](redis.md) | [English](../en/redis.md) | [日本語](../ja/redis.md)

Redis 配置存储 + Node.js HTTP API 桥接。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core |
| 容器 | rd / ra（API） |

## 安装

```bash
./g41.sh kits add redis
```

## 注意

- 从 Dockerfile 本地构建（`FROM redis:8.4.0-alpine` + `FROM node:24.16.0-alpine`）
- Redis 通过 `REDIS_PASSWORD` 环境变量启用 `--requirepass` 认证
- API 容器通过 `depends_on` + pipeline 批量加载数据
- 数据端点 `/data/<key>` 从 Redis 读取并以 JSON 返回
- 短链接端点 `/link/<name>` 自动解析 `__HOST__` 占位符为当前域名
- 加载阶段使用 `data:loaded` + `data:loading` 检查点防止重复加载
- `multi()` pipeline 批量写入减少 crash-restart 循环