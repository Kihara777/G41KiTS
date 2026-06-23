# nginx

[中文](../zh/nginx.md) | [English](../en/nginx.md) | [日本語](../ja/nginx.md) | [ｶﾀﾘｯｼｭ](../katalish/nginx.md) | 偽中国語 

TLS 1.3 / HTTP/3 門関、全後端之逆代理

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core |
| 容器 | gx |
| 镜像 | nginx |

## 導入

```bash
./g41.sh kits add nginx
```

## 注意

- 端口 80/443，HTTP/3 QUIC\n- 所有 location 通过 include 加载\n- 安全头：HSTS、CSP、X-Frame、Referrer