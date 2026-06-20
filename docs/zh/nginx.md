# nginx

[中文](nginx.md) | [English](../en/nginx.md) | [日本語](../ja/nginx.md)

TLS 1.3 / HTTP/3 网关，反向代理全部后端

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core |
| 容器 | gx |
| 镜像 | nginx |

## 安装

```bash
./g41.sh kits add nginx
```

## 注意

- 443 端口复用、HTTP/3、QUIC BPF 可选
- 反向代理所有后端服务
