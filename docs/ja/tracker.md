# tracker
[中文](../zh/tracker.md) | [English](../en/tracker.md) | [日本語](tracker.md) | [ｶﾀﾘｯｼｭ](../katalish/tracker.md) | [偽中国語](../pcn/tracker.md)

軽量 HTTPS BitTorrent トラッカー

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | hako,home,nginx |
| コンテナ | wt |
| イメージ | node + bittorrent-tracker（Dockerfile 本地构建） |

## インストール

```bash
./g41.sh kits add tracker
```

## 注意

- HTTP/UDP/WebSocket マルチプロトコル
- 埋め込み: /tracker（ステータスページ）
- UDP 6969 公開（UFW）
- ヘルスチェック: wget http://127.0.0.1:8000/stats
