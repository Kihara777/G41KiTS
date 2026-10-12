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

**Third revision (2026-10-12, same day)**: three points, two of them measurable:

1. **The five dots must form one chain.** The old build had every dot run the whole keyframe track
   (including its own pauses), so the phases only guaranteed an even distribution, never an order —
   measured at one instant the adjacent gaps were 96°/282°/81°/147°/114°, with two dots almost
   overlapping. Now all five share a single rotation curve (2.4 s /
   `cubic-bezier(.5,.08,.5,.92)`) and only differ by negative delays: the order can never break, the
   easing makes the arc breathe, and dot sizes of 100/85/70/55/42% form a comet tail. Measured
   internal gaps 38–44°, monotonic in both samples. Dot centres compensate for their size
   (`top = (dot − size)/2`), so unequal dots still sit on one circle.
2. **When the ring goes away**: `main-entry` used to be added in `init()`, so the entrance animation
   played behind `opacity:0` and the ring revealed a frozen result. It now lives in `revealApp()`:
   the ring is dismissed first, then `requestAnimationFrame` adds the entrance class and fades in.
   Measured order: `ring 1 → (0.28 with entry:true and tiles:12) → app 1 → ring removed`.
3. **No background while loading**: the overlay changed from a translucent scrim to **opaque black**
   (a WP8 boot screen is flat colour anyway); the artwork no longer competes for attention and the
   failure text gains contrast.

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
