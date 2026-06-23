# 記録

[中文](../../MAINTENANCE.md) | [English](../MAINTENANCE.en.md) | [日本語](../MAINTENANCE.ja.md) | [ｶﾀﾘｯｼｭ](../katalish/MAINTENANCE.md) | 偽中国語

## 2026-06-20

- 化: `main` GitHub 於
- 三言語文書公開（27 部品 + 部品仕様）: zh:29 / en:29 / ja:29
- AGENTS.md 中国語以完全書直（292 行）、構造開発問題網羅
- README 於 `.local/` 初期化追加
- 三言語記録（MAINTENANCE.md / en / ja）
- 三言語 NOTICE.md（資産於関声明）

## 2026-06-18

- 全 Docker 版解除: Dockerfile FROM 行、compose image 、npm 包版、ADD --checksum 版於変更
- `skills/` 不在於 `g41.sh kits pack` 之 `set -e` 修正
- 全堆強制再構築、14/14 healthy

## 2026-06-16

- 2 回之全面安全監査（4 代理並列）: 24 件之問題発見、修正許容
- g41.sh 強化: `set -o pipefail`、`sed -i` → 書込、compose include 行番号於正確挿入
- autoheal 修正: willfarrell/autoheal Hub 自 Dockerfile 於変更（TCP 対応之 master 版 entrypoint）
- CSP 安全之階層化: 厳格、aria2/nix-cache/gh-proxy 代理緩和
- tiles.js tracker 埋込 XSS 修正: `innerHTML` → `createElement` + `textContent`
- G41.js fetch 於 5 秒追加（`AbortSignal.timeout(5000)`）
- server.js 之全 `catch(e){}` 於 `console.error` 追加
- 準備監査合格: 於、全書類 `.gitignore` 以除外
- tile_bilibili 部品新規作成: Bilibili VTuber 磁貼（三言語 i18n）
- tile_flake 磁貼於 13 件之 NixKits 包//技能入力
- tile_gh-proxy i18n 之 `g41.moe` → `__HOST__`
- g41.sh TUI ANSI 増分於変更（解消）
- GitHub 倉庫作成與設定

## 2026-06-11 ~ 2026-06-12

- 資料與機能之分離（A/B/C 層）: compose 変数化、nginx site 設定之汎化、server.js 環境変数注入
- 安全強化: dsock 新部品（Docker API 代理）、BT 、Redis 認証
- 標準化（HTTP > > kill -0 1）
- 部品名変更: 純粋磁貼 → `tile_*` 接頭辞（5 件）、純粋連結 → `link_*` 接頭辞（6 件）
- 修正: 、読込、404 応答
- hy2 部品秘匿化: `.local/` 以書類與 nginx 設定隠蔽
- g41.sh 拡張: `.local/site/` 與 `.local/webroot/` 之自動検出
- server.js 再構築: 生 TCP → `redis` npm 包永続接続 + 書込

## 2026-06-10

- 初期監査: compose.yaml、g41.sh、全 kits/ 部品
- 基盤構築: Metro/WP8.1 風首頁、Redis 設定 API、多言語 i18n、KITS 部品体系