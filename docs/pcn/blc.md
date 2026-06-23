# blc

[中文](../zh/blc.md) | [English](../en/blc.md) | [日本語](../ja/blc.md) | 偽中国語 | [ｶﾀﾘｯｼｭ](../katalish/blc.md)

Bilibili （AI 翻訳付）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,nginx |
| 容器 | lc |
| 鏡像 | xfgryujk/blivechat |

## 導入

```bash
./g41.sh kits add blc
```

## 注意

- server_name: blc.*
- WebSocket: /api/chat
- 健康検査: wget http://127.0.0.1:12450/