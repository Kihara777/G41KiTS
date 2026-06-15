# tile_gh-proxy

[中文](tile_gh-proxy.md) | [English](../en/tile_gh-proxy.md) | [日本語](../ja/tile_gh-proxy.md)

> raw.githubusercontent.com 的反向代理，通过 `/gr/` 路径访问。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | 磁贴 |
| 依赖 | home, nginx |
| Compose | none |

## 安装

```bash
./g41.sh kits add tile_gh-proxy
```

## 路径

| URL | 目标 |
|-----|------|
| `/gr/` | `https://raw.githubusercontent.com/` |

## 注意

- 提供三语言使用说明的首页磁贴
- 剥离上游 CSP 头以保证兼容性
- 无 Docker 服务 — 纯 nginx 代理配置
- 示例 URL 中的 `__HOST__` 会动态替换为当前域名