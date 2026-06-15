# dsock

[中文](../zh/dsock.md) | [English](../en/dsock.md) | [日本語](dsock.md)

Docker API セキュリティプロキシ — docker.sock 直接マウントの代替。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core |
| コンテナ | ds |
| イメージ | tecnativa/docker-socket-proxy |

## インストール

```bash
./g41.sh kits add dsock
```

## 注意

- `/var/run/docker.sock` を読み取り専用（`:ro`）でマウント
- API エンドポイントを `CONTAINERS` + `EXEC` + `POST` に制限
- acme は `DOCKER_HOST=tcp://ds:2375` で接続
- autoheal は `DOCKER_SOCK=tcp://ds:2375` で接続
- 直接の docker.sock マウントを置き換え、攻撃面を縮小