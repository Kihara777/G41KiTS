# aria2

[中文](../zh/aria2.md) | [English](../en/aria2.md) | [日本語](../ja/aria2.md) | [ｶﾀﾘｯｼｭ](../katalish/aria2.md) | 偽中国語 

並列下載管理者（WebUI 與 WebDAV 共有付）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,hako,nginx |
| 容器 | ad |
| 鏡像 | alpine + aria2（Dockerfile 本地构建） |

## 導入

```bash
./g41.sh kits add aria2
```

## 注意

- WebUI: /aria2/
- RPC: /aria2rpc(WebSocket ws://)
- AriaNg AllInOne 内蔵
- 健康検査: nc -zw1 127.0.0.1 6800