# hy2

[中文](../zh/hy2.md) | [English](../en/hy2.md) | [日本語](hy2.md)

Hysteria2 プロキシ（nginx と 443 ポート共有）。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | nginx |
| コンテナ | hq |

## インストール

```bash
./g41.sh kits add hy2
```

## 注意

- ホストネットワークで nginx とポート共有
- プライベート設定（hysteria.yaml）は `.local/` に保管
- サブスクリプションファイルと location 設定は `.local/` 経由（非公開）
- ヘルスチェック：`kill -0 1`（ホストネットワーク制限）
- リソース制限：512m / 2.0 CPU
