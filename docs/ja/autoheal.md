# autoheal

[中文](../zh/autoheal.md) | [English](../en/autoheal.md) | [日本語](autoheal.md)

異常のある Docker コンテナを自動再起動。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | サービス |
| 依存 | core, dsock |
| コンテナ | ah |

## インストール

```bash
./g41.sh kits add autoheal
```

## 注意

- ローカルビルドのカスタム Dockerfile 使用（`willfarrell/autoheal` ベース）、**Hub イメージではない**
- dsock プロキシ経由で Docker API にアクセス（`DOCKER_SOCK=tcp://ds:2375`）
- ヘルスチェック付きの全コンテナを監視（`AUTOHEAL_CONTAINER_LABEL=all`）
- ヘルスチェックは `pgrep -f autoheal` でデーモンの稼働を確認
- デフォルトの検査間隔 5 秒、起動遅延 30 秒
- `health: unhealthy` のコンテナのみ再起動し、`restarting` 状態のコンテナはスキップ
