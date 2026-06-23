# nginx
中文 | [English](../en/nginx.md) | [日本語](../ja/nginx.md)

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

- 端口 80/443，HTTP/3 QUIC\n- 所有 location 通过 include 加载\n- 安全头：HSTS、CSP、X-Frame、Referrer
