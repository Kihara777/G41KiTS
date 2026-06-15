# tile_nix-cache

[中文](../zh/tile_nix-cache.md) | [English](../en/tile_nix-cache.md) | [日本語](tile_nix-cache.md)

> NixOS バイナリキャッシュミラー — channels、cache、releases。

## 基本情報

| 項目 | 値 |
|------|-----|
| タイプ | タイル |
| 依存 | home, nginx |
| Compose | none |

## インストール

```bash
./g41.sh kits add tile_nix-cache
```

## パス

| URL | ターゲット | 用途 |
|-----|-----------|------|
| `/nichan/` | `https://channels.nixos.org/` | Nix チャンネルメタデータ |
| `/nica/` | `https://cache.nixos.org/` | バイナリキャッシュパッケージ |
| `/nira/` | `https://releases.nixos.org/` | NixOS リリース ISO |

## 注意

- 3 言語の使用説明付きホームページタイルを提供
- 互換性のため上流 CSP ヘッダーを削除
- Docker サービスなし — 純粋な nginx プロキシ設定
- NixOS のパッケージインストールとシステム更新を高速化