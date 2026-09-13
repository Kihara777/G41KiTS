# tile_friends

[中文](../zh/tile_friends.md) | English | [日本語](../ja/tile_friends.md)

Friend-links tile — shows the sites this homepage exchanges mutual links with.

## Basics

| Item | Value |
|------|-------|
| Type | tile |
| Depends | home |
| Icon | 🤝 |
| Tile type | `list` (click to expand the link list) |

## Install

```bash
./g41.sh kits add tile_friends
```

## Tile content

Clicking the tile expands every friend link as a list, each row carrying an icon,
the site name and a target URL.

| Site | Link | Notes |
|------|------|-------|
| Shiogiri's Mist-Star Bakery | <https://shiogiri.com> | Personal site of "Shiogiri"; mutual link |

## Adding a friend link

Entries live inline in the `items` array of `tile.json`; append one object per site:

```json
{
  "icon": "🌫",
  "label": "friend_shiogiri",
  "href": "https://shiogiri.com"
}
```

`label` is an i18n **key** (not display text), so add a matching display name to
each of `i18n/{zh,ja,en}.json`:

```json
{"friend_shiogiri": "Shiogiri's Mist-Star Bakery"}
```

## See also

- Tile and homepage rendering: [home](home.md)
- Application-entry list tile: [tile_apps](tile_apps.md)
