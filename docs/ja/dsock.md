# dsock

[中文](dsock.md) | [English](../en/dsock.md) | [日本語](../ja/dsock.md)

Docker API セキュリティプロキシ

## 基本情報

| 項目 | 値 |
|------|-----|
| 类型 | service |
| 依赖 | core |
| 容器 | ds |
| 镜像 | tecnativa/docker-socket-proxy |

## インストール

```bash
./g41.sh kits add dsock
```

## 注意

- docker.sock を読み取り専用でマウント
- API を CONTAINERS+EXEC+POST に制限
