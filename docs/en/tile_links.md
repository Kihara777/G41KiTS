# tile_links

[中文](../zh/tile_links.md) | [English](../en/tile_links.md) | [日本語](../ja/tile_links.md)

> Short links tile — entry point for external tool download links on the homepage.

## Info

| Field | Value |
|-------|-------|
| Type | tile |
| Depends | home |
| Compose | none |

## Install

```bash
./g41.sh kits add tile_links
```

## Notes

- Aggregates short links from all `link_*` modules
- Includes 7-Zip, .NET SDK, DirectX, VC++ Redist, Visual Studio, VS Code
- No Docker service — tile data served via Redis API