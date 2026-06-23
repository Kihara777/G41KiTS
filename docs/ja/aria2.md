# aria2
[中文](../zh/aria2.md) | [English](../en/aria2.md) | 日本語 | [ｶﾀﾘｯｼｭ](../katalish/aria2.md) | [偽中国語](../pcn/aria2.md)

並列ダウンロードマネージャ（WebUI と WebDAV 共有付き）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,hako,nginx |
| コンテナ | ad |
| イメージ | alpine + aria2（Dockerfile 本地构建） |

## インストール

```bash
./g41.sh kits add aria2
```

## 注意

- WebUI: /aria2/
- RPC: /aria2rpc(WebSocket ws://)
- AriaNg AllInOne 内蔵
- ヘルスチェック: nc -zw1 127.0.0.1 6800
