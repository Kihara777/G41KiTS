# hy2

[中文](hy2.md) | [English](../en/hy2.md) | [日本語](../ja/hy2.md)

Hysteria2 代理，与 nginx 共用 443 端口。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | nginx |
| 容器 | hq |
| 镜像 | tobyxdd/hysteria |

## 安装

```bash
./g41.sh kits add hy2
```

## 注意

- 使用 host 网络模式，通过 SO_REUSEPORT 与 nginx 共享 443/UDP
- 配置文件 `hysteria.yaml` 在 .local/ 目录中（含密码，gitignored）
- 订阅文件通过 WebDAV 提供
