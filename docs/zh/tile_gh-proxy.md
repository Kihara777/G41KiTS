# tile_gh-proxy

中文 | [English](../en/tile_gh-proxy.md) | [日本語](../ja/tile_gh-proxy.md)

raw.githubusercontent.com 反向代理。**首页磁贴已于 2026-10-12 撤下** —— 保留服务本身，
不再在首页介绍这个代理。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | proxy（无磁贴） |
| 依赖 | nginx |
| 访问路径 | `/gr/` |

## 安装

```bash
./g41.sh kits add tile_gh-proxy
```

安装内容只有 nginx 片段（`zones` + `locations` 各一个文件），不含 `tile.json` / `i18n/`。

## 注意

- 目录名保留 `tile_` 前缀是历史原因：改名会一并改掉已部署的 nginx 片段名
  （`999-tile_gh-proxy.conf`）与 `G41_KITS` 记账，收益不抵风险，故不动。
- 撤磁贴时 `depends` 由 `home, nginx` 收窄为 `nginx` —— 该模块不再消费 `home`
  提供的 `tile` / `i18n` 类型。**代价**：`kits del` 靠依赖树的 `accepts` 发现要删的
  已装文件，收窄后它不会再清理历史遗留的 `.rd/data/tiles/tile_gh-proxy.json` 与
  `.rd/data/i18n/tile_gh-proxy/`，撤除时需手工删除一次（已执行）。

## 相关

- 首页磁贴的渲染逻辑见 [home](home.md)
- 新替代它的自我介绍磁贴见 [tile_kitsunome](tile_kitsunome.md)
