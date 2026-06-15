# tile_flake

[中文](../zh/tile_flake.md) | [English](../en/tile_flake.md) | [日本語](../ja/tile_flake.md)

> 個人 Nix flake リポジトリタイル — カスタムパッケージ、オーバーレイ、NixOS モジュール、スキル。

## 基本情報

| 項目 | 値 |
|------|-----|
| タイプ | tile |
| 依存 | home |
| Compose | none |
| アイコン | ❄ |

## インストール

```bash
./g41.sh kits add tile_flake
```

## 注意

- 詳細画面に **13 エントリ**を提供、3 カテゴリ：
  - **パッケージ**（5）：codewhale, codewhale-tui, codewhale-artifacts, codewhale-artifacts-tui, kitsunome
  - **パッチ**（3）：opencode-codex, opencode-rcli, codewhale-rcli
  - **スキル**（5）：feishu, mcp-builder, plugin-creator, skill-creator, skill-installer
- 各エントリに NixKits ドキュメントへのクリック可能なリンク
- Docker サービスなし — タイルデータのみ