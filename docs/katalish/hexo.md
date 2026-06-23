# hexo
[中文](../zh/hexo.md) | [English](../en/hexo.md) | [日本語](../ja/hexo.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/hexo.md)

個人 ﾌﾞﾛｸﾞ ｴﾝｼﾞﾝ

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | ﾀｲﾙ_apps,hako,nginx |
| ｺﾝﾃﾅ | hx |
| ｲﾒｰｼﾞ | node + hexo-cli（Dockerfile 本地构建） |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add hexo
```

## 注意

- ｻｰﾊﾞｰ_name: log.*
- ﾍﾙｽ ﾁｪｯｸ: wget http://127.0.0.1:4000/
- Survive: .hx/ preserved ｵﾝ uninstall