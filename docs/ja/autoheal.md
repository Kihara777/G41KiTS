# autoheal

[中文](autoheal.md) | [English](../en/autoheal.md) | [日本語](../ja/autoheal.md)

異常コンテナの自動再起動（ローカル Dockerfile）

## 基本情報

| 項目 | 値 |
|------|-----|
| 类型 | service |
| 依赖 | core, dsock |
| 容器 | ah |
| 镜像 | ローカルビルド |

## インストール

```bash
./g41.sh kits add autoheal
```

## 注意

- willfarrell/autoheal をベースにローカルビルド
- dsock プロキシへの TCP ソケット接続をサポート
