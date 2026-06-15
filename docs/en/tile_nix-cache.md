# tile_nix-cache

[中文](../zh/tile_nix-cache.md) | [English](tile_nix-cache.md) | [日本語](../ja/tile_nix-cache.md)

> NixOS binary cache mirror — channels, cache, and releases.

## Info

| Field | Value |
|-------|-------|
| Type | tile |
| Depends | home, nginx |
| Compose | none |

## Install

```bash
./g41.sh kits add tile_nix-cache
```

## Paths

| URL | Target | Purpose |
|-----|--------|---------|
| `/nichan/` | `https://channels.nixos.org/` | Nix channel metadata |
| `/nica/` | `https://cache.nixos.org/` | Binary cache packages |
| `/nira/` | `https://releases.nixos.org/` | NixOS release ISOs |

## Notes

- Provides a home-page tile with usage instructions in three languages
- Upstream CSP header is stripped for compatibility
- No Docker service — pure nginx proxy configuration
- Used to accelerate package installation and system updates for NixOS