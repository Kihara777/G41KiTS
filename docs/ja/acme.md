# acme

[中文](acme.md) | [English](../en/acme.md) | [日本語](../ja/acme.md)

SSL 証明書管理（acme.sh + ZeroSSL/Cloudflare DNS）

## 基本情報

| 項目 | 値 |
|------|-----|
| 类型 | service |
| 依赖 | core, dsock |
| 容器 | ca |
| 镜像 | ローカルビルド |

## インストール

```bash
./g41.sh kits add acme
```

## 注意

- dsock プロキシ経由で Docker API にアクセス
- Cloudflare DNS 検証で証明書を発行
