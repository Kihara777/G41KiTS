# bt

[中文](../zh/bt.md) | [English](../en/bt.md) | [日本語](../ja/bt.md) | 偽中国語 | [ｶﾀﾘｯｼｭ](../katalish/bt.md)

BitTorrent 依頼者（WebUI 與 WebDAV 共有付）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,hako,nginx |
| 容器 | tr |
| 鏡像 | alpine + transmission-daemon（Dockerfile 本地构建） |

## 導入

```bash
./g41.sh kits add bt
```

## 注意

- WebUI: /transmission/
- WebDAV: /transmission/share
- 健康検査: nc -zw1 127.0.0.1 9091