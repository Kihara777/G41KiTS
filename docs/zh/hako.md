# hako

[中文](hako.md) | [English](../en/hako.md) | [日本語](../ja/hako.md)

Web 文件管理器，含公开 WebDAV 共享。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, nginx |
| 容器 | fb |
| 镜像 | filebrowser/filebrowser |

## 安装

```bash
./g41.sh kits add hako
```

## 注意

- Web 文件管理界面，支持上传/下载/预览
- 公开 WebDAV 共享路径 `/hako/`
- 配置文件 `filebrowser.db` 和 `settings.json` 通过 .local 部署
