# G41KiTS → k3s 移行ガイド

Docker Compose から k3s への移行。デュアルトラック共存、データ移行ゼロ、ロールバック可能。

## 前提条件

- **RAM ≥ 1GB**（958MB VPS で実証済みの 1GB 構成）
- リポジトリ同期済み（`k8s/`、`kits/*/k8s/`、最新 `g41.sh`）
- 事前バックアップ：`./g41.sh kits pack -SAL`

## デプロイ

```bash
# 一発実行：スリム k3s 導入 + ホストチューニング + 段階的デプロイ
./g41.sh init k8s
```

k3s（traefik/metrics-server/servicelb/local-storage 無効化）を導入し、tmpfs-kine +
状態バックアップ/復元ユニットを適用、ホスト調整（journald volatile、zram、swappiness、
snapd 停止、fail2ban 許可リスト）、その後 `k8s stage` で依存順にワークロードを起動します。

## 1GB 構成の要点（`init k8s` が実施）

1. **tmpfs kine** — sqlite データストアを `/dev/shm`（約 19MB）に配置。5 分タイマーで
   ディスクへバックアップし、起動時ユニットが復元。
2. **k3s-standalone ユニット** — ファイルログ（journald から分離、k3s プロセス凍結を回避）、
   `MemoryMin=400M`、`OOMScoreAdjust=-900`、`Restart=always`。
3. **ディスク swap + zram** — ワークロード超過分は swap へ、kine は RAM 常駐。

## 日常操作

| タスク | コマンド |
|---|---|
| 全体適用 | `./g41.sh k8s apply --all` |
| 段階的デプロイ | `./g41.sh k8s stage` |
| nginx 設定再生成 | `./g41.sh k8s conf` |
| hexo ブログ再構築 | `./g41.sh k8s hexo` |
| イメージ再構築 | `./g41.sh k8s build` |
| 状態確認 | `./g41.sh k8s status` |

## 証明書

cert-manager が `g41.moe` + `*.g41.moe` を発行（Let's Encrypt、Cloudflare DNS01）。
通常は 0 にスケールし、毎月 1 日の cron が 2 時間の更新ウィンドウを開きます。

## ロールバック

```bash
./g41.sh backend compose
kubectl delete namespace g41
docker compose start   # コンテナは残存、データディレクトリは共有
```

## アーキテクチャ注記

- **8 Pod**（12 → 8）：hexo 静的化（オンデマンドビルド Job）、tracker を api プロセスに統合、
  api を redis Pod に統合、aria2+bt を 1 Pod に統合。
- Service 名は nginx upstream に一致（例外：hexo は `hx`、api は `ra`）。
- 外部ポートは hostPort/hostNetwork で compose と同一（80/443/53/853/51413）。
- 詳細は `k8s/README.md` を参照。
