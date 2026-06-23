# hako

[中文](../../zh/hako.md) | [English](../../en/hako.md) | [日本語](../../ja/hako.md) | 偽中国語 | [ｶﾀﾘｯｼｭ](../../katalish/hako.md)

Web 書類管理者（公開 WebDAV 共有付）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,nginx |
| 容器 | fb |
| 鏡像 | filebrowser/filebrowser |

## 導入

```bash
./g41.sh kits add hako
```

## 注意

- File Browser 基
- WebDAV 共有
- 健康検査: wget http://127.0.0.1:80/