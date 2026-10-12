# nginx
[中文](../zh/nginx.md) | [English](../en/nginx.md) | 日本語

TLS 1.3 / HTTP/3 ゲートウェイ、全バックエンドへのリバースプロキシ

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core |
| 容器 | gx |
| 镜像 | nginx |

## インストール

```bash
./g41.sh kits add nginx
```

## 注意

- 端口 80/443，HTTP/3 QUIC\n- 所有 location 通过 include 加载\n- 安全头：HSTS、CSP、X-Frame、Referrer

## 静的アセットのキャッシュ方針

静的ファイル（HTML/CSS/JS/JSON）には常に `Cache-Control: no-cache` を付けます：

```nginx
add_header Cache-Control "no-cache" always;   # server ブロック、セキュリティヘッダと並べて
```

**デフォルト（何も書かない）が誤りである理由**：`Cache-Control` が無いとブラウザは
`Last-Modified` による**ヒューリスティックキャッシュ**（約 10%）を使うため、デプロイ後に
「古い HTML と新しい JS/CSS」の**混合世代**を受け取ることがあります。2026-10-12 に新しい
起動リングが見えなかったのはまさにこれでした（頁が何も変わっていないように見えた）。
本サイトにファイル名の指紋は無いので、`no-cache` + ETag（再検証は 304 で安価）が
混合世代を出さない唯一の方法です。

## 設定変更はどう反映されるか（reloader sidecar）

`kits/nginx/k8s/deployment.yaml` の `reloader` コンテナが `/etc/nginx`・`/certs` の変化を
見て nginx に SIGHUP を送る役割です。**2026-10-12 の実測では動いていません**。理由は二つ：

1. このコンテナには **volumeMounts が一つも無い** —— 自分のイメージ内の nginx ディレクトリを
   `find` しているため、マウントされた ConfigMap/Secret を永遠に見られません
   （`/tmp/.last` は 2026-09-26 で止まったまま）。
2. 仮にマウントしても `kill -HUP 1` は誤ったプロセスを撃ちます。pod は
   `shareProcessNamespace` を有効にしているため PID 1 は **pause** であり、
   nginx master ではありません（`kill -HUP $(pgrep -f "nginx: master")` であるべきです）。

結果：`k8s conf` / CD が ConfigMap を再描画しても **nginx は古い設定のまま動き続け**、
pod の再起動だけが反映します。`k8s/host/g41-cert-reload.sh` の「reloader sidecar が
ホットリロードする」という記述はしたがって誤りです（証明書更新後も nginx は古い証明書を
持ち続けます）。

## 圧縮（gzip）

```nginx
gzip on;  gzip_comp_level 5;  gzip_min_length 256;  gzip_proxied any;  gzip_vary on;
gzip_types text/plain text/css application/javascript application/json image/svg+xml application/manifest+json;
```

**2026-10-12 より前は `gzip` 指令が一つもありませんでした**（nginx の既定は off）—— ホームページの
HTML（スタイル内聯後で約 19.7KB）も JS もそのまま送信されていました。実測：`G41.html` → **6.9KB**、
`G41.js` 7.0KB → 約 2KB。`gzip_vary on` は `Cache-Control: no-cache` と組で、キャッシュが
エンコーディングを混ぜないようにします。

## splash 文案のローカライズ

起動画面の一行（`読み込み中 / Loading`）は**あらゆる JS と追加要求より前に**読める必要があります ——
クライアント側スクリプトは遅すぎるか（往復が増える）、CSP に阻まれます（`script-src` は `'self'` で
インラインスクリプト不可）。そこで `Accept-Language` により **nginx 側**で置換します：

```nginx
map $http_accept_language $g41_loading_text {   # http ブロック
    default       "Loading";
    "~*^\s*zh"    "载入中";
    "~*^\s*ja"    "読み込み中";
    "~*^\s*en"    "Loading";
}
sub_filter_once on;                              # server ブロック
sub_filter '読み込み中 / Loading' $g41_loading_text;
```

- **第一言語優先**、`G41.js` の `detectLang` と同じ規則。`zh` は簡体字（サイト全体の中国語と揃える）
- 応答が `Accept-Language` で変わるため `Vary` に記載が必要。`gzip_vary` を切り、
  server ブロックで `Vary: Accept-Encoding, Accept-Language` を 1 本にまとめています（Vary が二重にならないよう）
- 置換対象は `G41.html` の**二言語フォールバック**（ファイルを直接開いても読める）—— 文案の変更は二箇所
- 既知の境界：nginx は `localStorage` の言語設定を見られないため、日本語端末で手動で中国語に
  切り替えた訪客は、splash が日本語で出て app 起動直後に中国語へ変わります（1〜2 秒の差）
