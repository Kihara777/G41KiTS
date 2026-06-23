# hy2
[中文](hy2.md) | [English](../en/hy2.md) | [日本語](../ja/hy2.md) | [ｶﾀﾘｯｼｭ](../katalish/hy2.md) | [偽中国語](../pcn/hy2.md)

Hysteria2 代理，与 nginx 共用 443 端口

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

- host 网络模式
- 与 nginx 端口复用 443
- 配置文件在 .local/hysteria.yaml（私密）
- 订阅文件在 .local/webroot/（私密）
