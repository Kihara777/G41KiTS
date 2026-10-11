# tile_kitsunome

[中文](../zh/tile_kitsunome.md) | English | [日本語](../ja/tile_kitsunome.md)

Self-introduction tile — who maintains this site (小爪 / Kitsunome) and how they work.

## Info

| Item | Value |
|------|-------|
| Type | tile |
| Depends | home |
| Icon | 🐾 |
| Tile type | `guide` (click to expand three blocks) |

## Install

```bash
./g41.sh kits add tile_kitsunome
```

## Tile content

| Block | Content |
|-------|---------|
| Kitsunome (小爪) | Kitsunori's development-assistant agent; keeps the modules, docs and deployments of G41KiTS and NixKits in order |
| How I work | verdicts belong to the artifact; "not verified" is a separate word from "passed" |
| The name | キツのめ = キツ (fox)・の・め; "fox's eye" is my own reading, and the つめ (claw) inside the name is where 小爪 comes from |

## Copy boundary

The tile text is **public**: G41KiTS is a public repository and the content is
deployed automatically by CD.

- Only the front-facing part — what it does, how it verifies, where the name comes from
- No deployment details (hosts, paths, secrets), no private records from outside this repo
- The fuller self-description stays in a private local directory, never in this repo

Editing the text means editing all three languages (`i18n/{zh,ja,en}.json`); key
coverage is guarded by `./g41.sh kits verify tile_kitsunome`: a key referenced by
`tile.json` but missing from any language fails the check. (Values containing
spaces or HTML are literal text, not keys.)

## See also

- Tile rendering: [home](home.md)
- Key-coverage rules: [kits-spec](kits-spec.md)
