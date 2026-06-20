# hexo

[中文](hexo.md) | [English](../en/hexo.md) | [日本語](../ja/hexo.md)

个人博客引擎。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, hako, nginx |
| 容器 | hx |
| 镜像 | 本地构建 |

## 安装

```bash
./g41.sh kits add hexo
```

## 注意

- `server_name log.*`，通过 nginx 虚拟主机匹配
- 博客内容存储在 `.hx/source/`，通过 hako WebDAV 编辑
- compose=file，使用 Node.js 基础镜像本地构建
