# hako

[中文](hako.md) | [English](../en/hako.md) | [日本語](../ja/hako.md)

Web 文件管理器，含公开 WebDAV 共享。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, nginx |
| 容器 | fb |
| 镜像 | filebrowser/filebrowser:v2.63.14-s6 |

## 安装

```bash
./g41.sh kits add hako
```

## 注意

- Docker Hub 镜像，固定版本 `v2.63.14-s6`
- WebUI 默认端口 80
- 健康检查：`wget -q http://127.0.0.1:80/`
- branding 文件通过 `.local/branding/` 安装
