# tile_apps

[中文](../zh/tile_apps.md) | [English](../en/tile_apps.md) | [日本語](../ja/tile_apps.md)

> 应用列表磁贴 — 全部服务的首页入口。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | tile |
| 依赖 | core, home, nginx |
| Compose | none |

## 安装

```bash
./g41.sh kits add tile_apps
```

## 注意

- 聚合来自所有 `app.json` 模块的应用条目
- 每个应用条目包含名称、图标、描述和链接
- 无 Docker 服务 — 纯磁贴数据，通过 Redis API 提供