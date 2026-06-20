# nginx

[中文](nginx.md) | [English](../en/nginx.md) | [日本語](../ja/nginx.md)

TLS 1.3 / HTTP/3 ゲートウェイ

## 基本情報

| 項目 | 値 |
|------|-----|
| 类型 | service |
| 依赖 | core |
| 容器 | gx |
| 镜像 | nginx |

## インストール

```bash
./g41.sh kits add nginx
```

## 注意

- 443 ポートで HTTP/3 と QUIC BPF をサポート
- 全バックエンドサービスへのリバースプロキシ
