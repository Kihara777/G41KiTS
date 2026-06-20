# redis

[中文](redis.md) | [English](../en/redis.md) | [日本語](../ja/redis.md)

Redis 配置存储 + Node.js HTTP API 桥接

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core, nginx |
| 容器 | rd |
| 镜像 | 本地构建 |

## 安装

```bash
./g41.sh kits add redis
```

## 注意

- 内存数据库 + Node.js API（server.js）
- 通过 REDIS_PASSWORD 环境变量认证
