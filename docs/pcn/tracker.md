# tracker

[中文](../zh/tracker.md) | [English](../en/tracker.md) | [日本語](../ja/tracker.md) | [ｶﾀﾘｯｼｭ](../katalish/tracker.md) | 偽中国語 

軽量 HTTPS BitTorrent 追跡器

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | hako,home,nginx |
| 容器 | wt |
| 鏡像 | node + bittorrent-tracker（Dockerfile 本地构建） |

## 導入

```bash
./g41.sh kits add tracker
```

## 注意

- HTTP/UDP/WebSocket 多重規約
- 埋込: /tracker（状態頁）
- UDP 6969 公開（UFW）
- 健康検査: wget http://127.0.0.1:8000/stats