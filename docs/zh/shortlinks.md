# shortlinks
[中文](shortlinks.md) | [English](../en/shortlinks.md) | [日本語](../ja/shortlinks.md) | [ｶﾀﾘｯｼｭ](../katalish/shortlinks.md) | [偽中国語](../pcn/shortlinks.md)

动态短链接，通过 Redis API 代理。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | link |
| 依赖 | nginx |

## 安装

```bash
./g41.sh kits add shortlinks
```

## 注意

- nginx location 正则匹配长 token，转发至 Redis API