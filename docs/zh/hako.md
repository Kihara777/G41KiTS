# hako

[中文](hako.md) | [English](../en/hako.md) | [日本語](../ja/hako.md)

Web 文件管理器，含公开 WebDAV 共享

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps,nginx |
| 容器 | fb |
| 镜像 | filebrowser/filebrowser |

## 安装

```bash
./g41.sh kits add hako
```

## 注意

- 基于 File Browser
- WebDAV 共享
- 健康检查: wget http://127.0.0.1:80/
