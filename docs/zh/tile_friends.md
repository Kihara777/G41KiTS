# tile_friends

中文 | [English](../en/tile_friends.md) | [日本語](../ja/tile_friends.md)

友情链接磁贴 —— 展示与本站互换友链的站点。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | tile |
| 依赖 | home |
| 图标 | 🤝 |
| 磁贴类型 | `list`（点击展开链接列表） |

## 安装

```bash
./g41.sh kits add tile_friends
```

## 磁贴内容

点击磁贴后以列表形式展开所有友链，每项含图标、站点名与跳转链接。

| 站点 | 链接 | 说明 |
|------|------|------|
| 汐雾の雾星面包房 | <https://shiogiri.com> | 「汐雾」的个人站点，互为友链 |

## 添加友链

友链条目内联在 `tile.json` 的 `items` 数组中，新增一项即可：

```json
{
  "icon": "🌫",
  "label": "friend_shiogiri",
  "href": "https://shiogiri.com"
}
```

`label` 是 i18n **键名**（不是显示文本），需在 `i18n/{zh,ja,en}.json` 三语中
各补一条对应的显示名：

```json
{"friend_shiogiri": "汐雾の雾星面包房"}
```

## 相关

- 磁贴与首页的渲染逻辑见 [home](home.md)
- 应用入口列表磁贴见 [tile_apps](tile_apps.md)
