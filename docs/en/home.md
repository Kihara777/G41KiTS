# home
[中文](../zh/home.md) | English | [日本語](../ja/home.md)

Site core data — character messages, theme colors, status codes, i18n. Directly provides the homete tile (G41KiTS project intro).

## Info

| Item | Value |
|------|-------|
| Type | data + tile |
| Depends | core, nginx, redis |
| compose | none |

## Provides

- **Tile**: tile_homete (G41KiTS project overview and tech stack)
- **Global i18n**: character dialogue, greetings — JA / ZH / EN
- **Data files**: chars.json, colors.json, langs.json, status.json
- **Web resources**: homepage HTML, JS, CSS, images
- **Site config**: SSL/TLS base settings, HSTS, error pages (prefix=0)

## Install

```bash
./g41.sh kits add home
```

## First paint (boot ring and failure state)

The first paint waits for all six data requests in `G41.js` (tiles / chars / status / three i18n
payloads) before `init()` runs, and `#g41-app` stays at `opacity:0` until then. That blank gap is
filled by the **WP8 boot ring** in `#g41-loading`: pure CSS (`.g41-ring` in `base.css`), so it is
visible on the first frame, before any JS arrives; under `prefers-reduced-motion` it degrades to a
**static ring of five dots**.

**Second revision (2026-10-12)**: the first version was a bare 64 px ring (6 px dots) and the
maintainer reported on a phone that it "did not appear or was not obvious enough" — measured at
412×915 it was 15% of the screen width in diameter, with dots at 1.4%. Three things were
strengthened: the diameter and dot size now scale with `vmin` (≈99 px / 9 px on a phone), a
**visible** "読み込み中 / Loading" line sits under the ring, and the overlay carries a
`rgba(0,0,0,.55)` scrim (otherwise the full-screen artwork swallows the ring).

| State | Switched by | What shows |
|-------|-------------|------------|
| Booting | nothing (CSS only) | amber five-dot ring, centred in the viewport |
| Ready | `endLoading()` inside `applyStatus()` | ring fades out, `#g41-app` fades in (status-code pages included) |
| Boot failed | `bootFailed()` | the ring is replaced by "読み込みに失敗しました / Failed to load" plus the real error text |

**The ring must not spin forever** — spinning forever says "still loading".
That is exactly why `bootFailed()` exists.

### The script order is a criterion, not a style choice

```html
<script src="/js/tiles.js"></script>   <!-- must run first: closeDetail / buildTiles live here -->
<script src="/js/G41.js"></script>     <!-- starts the data requests whose callback needs them -->
```

In the other order a cold load (no cache) can resolve the data first, `init()` throws
`ReferenceError: closeDetail is not defined`, and the whole page stays at `opacity:0`.
**Measured on 2026-10-12: 5/5 blank pages on cold loads before the fix**; delaying `tiles.js` by
three seconds reproduces it deterministically on a local stub. `tiles.js` has only top-level
function declarations and does not depend on `G41.js`, so running it first is safe.
