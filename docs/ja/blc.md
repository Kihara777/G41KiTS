# blc
[中文](../zh/blc.md) | [English](../en/blc.md) | 日本語

Bilibili ライブチャット（AI 翻訳付き）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | tile_apps,nginx |
| コンテナ | lc |
| イメージ | xfgryujk/blivechat |

## インストール

```bash
./g41.sh kits add blc
```

## 依存モジュールへの提供

blc は依存モジュールに `blc_template` タイプを提供します：

| フィールド | 値 |
|-----------|-----|
| タイプ | `blc_template` |
| ターゲットディレクトリ | `.lc/custom_public/templates/<モジュール名>/` |
| コンテナ内パス | `/mnt/data/data/custom_public/templates/<モジュール名>/` |
| ソースディレクトリ | コンシューマモジュールの `blc_template/` |

blc に依存するモジュールは、`blc_template/` ディレクトリ（`template.json` を含む）をモジュールディレクトリに配置できます。インストール時に blivechat テンプレートディレクトリにハードリンクされます。新しいテンプレートを有効にするには blc コンテナを再起動してください：

```bash
docker compose restart blc
```

## 注意

- server_name: blc.*
- WebSocket: /api/chat
- ヘルスチェック: wget http://127.0.0.1:12450/
- テンプレートディレクトリ: `.lc/custom_public/templates/`（再起動が必要）
