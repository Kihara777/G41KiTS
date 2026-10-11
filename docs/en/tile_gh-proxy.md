# tile_gh-proxy
[中文](../zh/tile_gh-proxy.md) | English | [日本語](../ja/tile_gh-proxy.md)

Reverse proxy for raw.githubusercontent.com. **The homepage tile was retired on
2026-10-12** — the service stays, the homepage no longer advertises it.

## Info

| Item | Value |
|------|-------|
| Type | proxy (no tile) |
| Depends | nginx |
| Path | `/gr/` |

## Install

```bash
./g41.sh kits add tile_gh-proxy
```

Only nginx fragments are installed (one file each in `zones` and `locations`);
there is no `tile.json` / `i18n/` any more.

## Notes

- The directory keeps its `tile_` prefix for historical reasons: renaming it would
  also rename the deployed nginx fragment (`999-tile_gh-proxy.conf`) and the
  `G41_KITS` bookkeeping entry, which is not worth the risk.
- Retiring the tile narrowed `depends` from `home, nginx` to `nginx` — the module
  no longer consumes the `tile` / `i18n` types that `home` provides. **Cost**:
  `kits del` discovers installed files through the dependency tree's `accepts`,
  so it no longer cleans up the legacy `.rd/data/tiles/tile_gh-proxy.json` and
  `.rd/data/i18n/tile_gh-proxy/`; those were removed by hand once (already done).

## See also

- Homepage tile rendering: [home](home.md)
- The self-introduction tile that replaced it: [tile_kitsunome](tile_kitsunome.md)
