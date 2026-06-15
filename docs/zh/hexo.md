# hexo

[中文](hexo.md) | [English](../en/hexo.md) | [日本語](../ja/hexo.md)

个人博客引擎。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, hako, nginx |
| 容器 | hx |

## 安装

```bash
./g41.sh kits add hexo
```

## 注意

- 从 Dockerfile 本地构建（`FROM node:24.16.0-alpine` + hexo-cli@4.3.2）
- 虚拟主机 `server_name log.*`
- 健康检查：`wget -q http://127.0.0.1:4000/`
- 持久化目录 `.hx` 含 survive 标志
