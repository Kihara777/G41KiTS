# hexo

[中文](../../zh/hexo.md) | [English](../../en/hexo.md) | [日本語](../../ja/hexo.md) | [偽中国語](hexo.md) | [ｶﾀﾘｯｼｭ](../../katalish/hexo.md)

個人網誌引擎

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,hako,nginx |
| 容器 | hx |
| 鏡像 | node + hexo-cli（Dockerfile 本地构建） |

## 導入

```bash
./g41.sh kits add hexo
```

## 注意

- server_name: log.*
- 健康検査: wget http://127.0.0.1:4000/
- Survive: 導入時 .hx/ 保持