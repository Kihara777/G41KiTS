# hy2

[中文](hy2.md) | [English](../en/hy2.md) | [日本語](../ja/hy2.md)

Hysteria2 代理，与 nginx 共用 443 端口。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | nginx |
| 容器 | hq |

## 安装

```bash
./g41.sh kits add hy2
```

## 注意

- 使用 host 网络模式与 nginx 端口复用
- 私密配置文件（hysteria.yaml）位于 `.local/`
- 订阅文件和 location 配置通过 `.local/` 安装（不公开）
- 健康检查：`kill -0 1`（host 网络限制）
- 资源限制：512m / 2.0 CPU
