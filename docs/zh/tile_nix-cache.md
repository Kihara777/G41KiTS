# tile_nix-cache

[中文](tile_nix-cache.md) | [English](../en/tile_nix-cache.md) | [日本語](../ja/tile_nix-cache.md)

> NixOS 二进制缓存镜像 — channels、cache、releases 三种代理。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | 磁贴 |
| 依赖 | home, nginx |
| Compose | none |

## 安装

```bash
./g41.sh kits add tile_nix-cache
```

## 路径

| URL | 目标 | 用途 |
|-----|------|------|
| `/nichan/` | `https://channels.nixos.org/` | Nix 频道元数据 |
| `/nica/` | `https://cache.nixos.org/` | 二进制缓存包 |
| `/nira/` | `https://releases.nixos.org/` | NixOS 发行版 ISO |

## 注意

- 提供首页磁贴，含三语言使用说明
- 剥离上游 CSP 头以保证兼容性
- 无 Docker 服务 — 纯 nginx 代理配置
- 用于加速 NixOS 系统的包安装和系统更新