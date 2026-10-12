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
filled by the **WP8 boot ring** in `#g41-loading`.

**Why the styles live inside `G41.html`**: the three `.css` files (~15 KB) used to be render-blocking —
the HTML could arrive and still leave a blank page, because the first pixel had to wait for the
stylesheets. Measured locally with a stub delaying them by 3 s: first contentful paint went from
**3024 / 6908 ms to 36 / 928 ms** after inlining, and `/css/` disappears from `performance` entirely.
**The first paint makes a single request (the HTML itself)** and the ring can be painted on the first
byte. Edit styles in `G41.html`'s `<style>` block — there are no standalone `.css` sources any more
(two copies would drift).

**Geometry and colour**: ring and dot sizes scale with `vmin` (≈99 px / 9 px on a phone), the five dots
sit at even 72° spacing, **dot size is fixed**, the colour is `--wp-amber`, and the backdrop is
**opaque black** (a WP8 boot screen is flat colour anyway, and the artwork no longer competes for
attention). A **visible** "読み込み中 / Loading" line sits under the ring (static, bilingual: i18n has
not been read yet at that point).

**The animation is a three-phase cycle** (3.6 s; every dot makes its own journey):

| Phase | Implementation | Criterion (one cycle of sampling) |
|-------|----------------|-----------------------------------|
| Enter | each dot fades in at the start of its own journey | every dot appears (`opacity 0 → 1`) |
| Spin | **each dot travels around the circle itself** (`g41-travel`, eased so it speeds up and slows down); the five differ only by negative delays | the angle advances monotonically; **the angle *between* dots changes** (measured span 81.8°, versus 0.0° for a rigidly rotating ring) |
| Exit | each dot fades out at the end of its journey | every dot disappears (`opacity 1 → 0`); visible count `5 →…→ 0 →…→ 5` |

**"The angle between dots changes" is the dividing line**: one revision (v4) implemented the three phases
as "the whole ring rotates rigidly + each dot pulses its opacity" — the dots never moved relative to each
other, the relative angle stayed at 0.0°, and the criteria of the day (count, dot size, monotonic angle)
**passed it**, so I could not see it while she saw "completely wrong" at a glance. Only `transform` and
`opacity` are animated, so "fixed dot size" has a direct criterion: all five `::after` computed widths
come back equal. Under `prefers-reduced-motion` both animations are off — five static dots, evenly
spaced at 72°, all lit.

**Text localisation**: the splash line must be readable **before any JS and any extra request**, so it is
substituted server-side by `Accept-Language` (`map` + `sub_filter`, first language wins, the same rule
as `G41.js`'s `detectLang`).

| State | Switched by | What shows |
|-------|-------------|------------|
| Booting | nothing (CSS only) | amber five-dot ring, centred in the viewport |
| Ready | `revealApp()`, called from `applyStatus()` | the ring is dismissed **first**, then `requestAnimationFrame` adds the entrance class and fades in |
| Boot failed | `bootFailed()` | the ring is replaced by "読み込みに失敗しました / Failed to load" plus the real error text |

**The reveal order is a criterion**: `main-entry` used to be added in `init()`, so the entrance
animation played behind `opacity:0` and dismissing the ring revealed a frozen result. Measured order
now: `ring 1 → (0.28 with entry:true and tiles:12) → app 1 → ring removed` — tiles ready and the
entrance animation in the same frame, with the ring fading out at the same moment.

**The ring must not spin forever** — spinning forever says "still loading".
That is exactly why `bootFailed()` exists.

(Four revisions' worth of history is in the 2026-10-12 entry of `MAINTENANCE.md`.)

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
