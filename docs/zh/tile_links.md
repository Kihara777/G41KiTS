# tile_links

[中文](../zh/tile_links.md) | [English](../en/tile_links.md) | [日本語](../ja/tile_links.md)

> 短链接磁贴 — 首页上外部工具下载链接的入口。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | tile |
| 依赖 | home |
| Compose | none |

## 安装

```bash
./g41.sh kits add tile_links
```

## 注意

- 聚合来自所有 `link_*` 模块的短链接
- 包括 7-Zip、.NET SDK、DirectX、VC++ Redist、Visual Studio、VS Code
- 无 Docker 服务 — 纯磁贴数据，通过 Redis API 提供