# nginx
[中文](../zh/nginx.md) | [English](../en/nginx.md) | [日本語](../ja/nginx.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/nginx.md)

TLS 1.3 / HTTP/3 ｹﾞｰﾄｳｪｲ, ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ ﾄｩ ｵｰﾙ ﾊﾞｯｸｴﾝﾄﾞｽﾞ

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | ｺｱ |
| 容器 | gx |
| 镜像 | nginx |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add nginx
```

## 注意

- 端口 80/443，HTTP/3 QUIC\n- 所有 location 通过 ｲﾝｸﾙｰﾄﾞ 加载\n- 安全头：HSTS、CSP、X-Frame、Referrer