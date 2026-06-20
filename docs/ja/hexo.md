# hexo

[中文](../zh/hexo.md) | [English](../en/hexo.md) | [日本語](hexo.md)

個人ブログエンジン

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,hako,nginx |
| コンテナ | hx |
| イメージ | node + hexo-cli（Dockerfile 本地构建） |

## インストール

```bash
./g41.sh kits add hexo
```

## 注意

- server_name: log.*
- ヘルスチェック: wget http://127.0.0.1:4000/
- Survive: アンインストール時 .hx/ 保持
