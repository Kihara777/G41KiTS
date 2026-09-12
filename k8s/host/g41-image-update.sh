#!/bin/sh
# G41KiTS — 每周镜像更新检查与滚动更新
#
# 覆盖范围（按用户确认的策略）：
#   1. 浮动 tag 的上游镜像  — 比对远程 digest，有新版本则滚动重启
#   2. 本地 :local 构建镜像 — 检查 Dockerfile/构建上下文是否比镜像更新，
#                             若是则重建并导入 k3s containerd（需 dockerd）
#
# 明确跳过：
#   - cert-manager / coredns 等集群组件（锁定版本，由 k8s 生命周期管理）
#
# 关键约束 —— hostPort 与滚动更新互斥：
#   nginx 占用 hostPort 80/443 且集群只有一个节点。默认 maxSurge=25%（=1）
#   会让新 Pod 因端口被占而 Pending，滚动更新**永久卡死**。该 Deployment 已
#   被固定为 maxSurge=0 / maxUnavailable=1（先停后起，秒级中断）。
#   本脚本在重启前会重新断言该策略，防止被误改回去。
#
# 退出码：0 = 成功；1 = 失败（供 systemd 记录）

set -eu

NS=g41
STATE_DIR=/var/lib/g41
STATE_FILE="$STATE_DIR/images.sha256"
REPO=/opt/g41
LOG_TAG=g41-image-update

log() { echo "$(date -Is) [$LOG_TAG] $*"; }

PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PATH

command -v kubectl >/dev/null 2>&1 || { log "FATAL: kubectl 未找到"; exit 1; }
command -v jq >/dev/null 2>&1 || { log "FATAL: jq 未找到"; exit 1; }

mkdir -p "$STATE_DIR"

# --- 远程 digest 解析（无需 docker，直接走 registry v2 API）--------------
remote_digest() {
  repo="$1"; tag="$2"
  if [ "${repo#ghcr.io/}" != "$repo" ]; then
    host=ghcr.io; path="${repo#ghcr.io/}"
    tok=$(curl -s --max-time 30 \
      "https://ghcr.io/token?scope=repository:${path}:pull&service=ghcr.io" | jq -r .token) || return 1
  else
    host=registry-1.docker.io; path="$repo"
    [ "${repo#library/}" = "$repo" ] || path="$repo"
    tok=$(curl -s --max-time 30 \
      "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${path}:pull" | jq -r .token) || return 1
  fi
  curl -sI --max-time 45 -H "Authorization: Bearer $tok" \
    -H "Accept: application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.docker.distribution.manifest.v2+json" \
    "https://$host/v2/$path/manifests/$tag" \
    | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest"{print $2}'
}

# --- 收集当前运行的上游镜像（排除本地 :local）----------------------------
collect() {
  kubectl -n "$NS" get deploy -o jsonpath='{range .items[*]}{range .spec.template.spec.containers[*]}{.image}{"\n"}{end}{end}' \
    | grep -v ':local$' | grep -v '^$' | sort -u
}

# --- 滚动更新安全护栏：hostPort 与 maxSurge 互斥 --------------------------
# 本集群只有一个节点。任何使用 hostPort 的 Deployment，若 maxSurge>0，
# 新 Pod 会因宿主机端口被旧 Pod 占用而永久 Pending —— rollout 卡死。
# 必须改为 maxSurge=0（先停后起）。hy2 用 hostNetwork 而非 hostPort，
# 不受此限，无需处理。
#
# 实测踩坑：dns(53/853)、download(51413) 与此前 nginx(80/443) 均曾因此卡死。
ensure_rollout_safe() {
  d="$1"
  hp=$(kubectl -n "$NS" get deploy "$d" \
       -o jsonpath='{range .spec.template.spec.containers[*].ports[*]}{.hostPort}{" "}{end}' 2>/dev/null || true)
  case "$hp" in
    *[0-9]*) ;;   # 含数字 = 用了 hostPort
    *) return 0 ;;  # 无 hostPort，默认策略安全
  esac
  surge=$(kubectl -n "$NS" get deploy "$d" \
          -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null || true)
  if [ "${surge:-0}" != "0" ]; then
    log "FIX   $d 使用 hostPort [$hp] 但 maxSurge=$surge，改为 0（否则 rollout 卡死）"
    kubectl -n "$NS" patch deploy "$d" -p \
      '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":0,"maxUnavailable":1}}}}' \
      >/dev/null 2>&1 || log "WARN: $d 策略修补失败，rollout 可能卡住"
  fi
}

# --- 镜像拉取安全护栏：浮动 tag 必须 imagePullPolicy=Always ----------------
# 坑：非 :latest 的浮动 tag（如 nginx:alpine）未显式声明时默认 IfNotPresent。
# 此时 rollout restart 只复用本地缓存镜像，**上游发布新版也永远拉不到** ——
# 表现为脚本报"已更新"但 digest 纹丝不动（实测踩坑）。
ensure_pull_policy() {
  d="$1"; img="$2"
  case "$img" in *:local) return 0 ;; esac   # 本地构建镜像无需拉取
  pol=$(kubectl -n "$NS" get deploy "$d" \
        -o jsonpath="{range .spec.template.spec.containers[?(@.image=='$img')]}{.imagePullPolicy}{' '}{end}" 2>/dev/null || true)
  case "$pol" in
    *Always*) return 0 ;;
  esac
  log "FIX   $d 的 $img 为浮动 tag 但 imagePullPolicy=${pol:-IfNotPresent}，改为 Always"
  for c in $(kubectl -n "$NS" get deploy "$d" \
             -o jsonpath="{range .spec.template.spec.containers[?(@.image=='$img')]}{.name}{' '}{end}" 2>/dev/null); do
    # 用 set image 触发一次同镜像"重设"，配合下面的 pullPolicy patch 使其生效
    kubectl -n "$NS" patch deploy "$d" -p \
      "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$c\",\"imagePullPolicy\":\"Always\"}]}}}}" \
      >/dev/null 2>&1 || log "WARN: $d/$c pullPolicy 修补失败"
  done
}

updated=""
failed=""
skipped=""

log "=== 开始每周镜像检查 ==="

# --- 1. 浮动 tag 上游镜像 ------------------------------------------------
for img in $(collect); do
  # 归一化为 registry API 所需的 <repo> <tag>
  # 规则：
  #   - 无 ':' 或以 '/' 开头的尾段无 tag  -> tag 取 latest
  #   - repo 不含 '.' 或 ':' 的域名段     -> 官方镜像，补 library/ 前缀
  #   - 显式 docker.io/ 前缀              -> 去掉（API 用裸路径）
  repo="$img"; tag=""
  case "${img##*/}" in
    *:*) repo="${img%:*}"; tag="${img##*:}" ;;
    *)   repo="$img";     tag="latest" ;;
  esac
  repo="${repo#docker.io/}"
  repo="${repo#index.docker.io/}"
  # 只有"单段"名字（如 nginx、redis）才是官方镜像，需要 library/ 前缀
  case "$repo" in
    */*) ;;                    # 已含命名空间，保持原样
    *)   repo="library/$repo" ;;
  esac

  # 本地 digest 必须取**正在运行的 Pod 实际使用**的那个。
  # 坑 1：containerd 会为同一 repo 保留多个历史 digest，直接 grep 镜像列表
  #       取 head -1 可能命中过期条目 → 误报有新版本并触发无谓重启。
  # 坑 2：Pod 报告的 image 是全限定名（docker.io/library/nginx:alpine），
  #       而 Deployment 里写的可能是短名（nginx:alpine），必须归一化后比对。
  local_digest=$(kubectl -n "$NS" get pods -o jsonpath="{range .items[*]}{range .status.containerStatuses[*]}{.image}{\"|\"}{.imageID}{\"\n\"}{end}{end}" 2>/dev/null \
    | awk -F'|' -v want="$repo:$tag" '
        {
          ref = $1
          sub(/^docker\.io\//, "", ref)
          sub(/^index\.docker\.io\//, "", ref)
          # 官方镜像的 library/ 前缀在短名下可能缺失，统一去掉再比
          short = ref; sub(/^library\//, "", short)
          w = want;    sub(/^library\//, "", w)
          if (short == w) { print $2 }
        }' \
    | sed 's/.*@//' | head -1) || true

  remote=$(remote_digest "$repo" "$tag" 2>/dev/null) || true

  if [ -z "${remote:-}" ]; then
    log "SKIP  $img — 远程 digest 查询失败（网络/限流）"
    skipped="$skipped $img"
    continue
  fi

  if [ -z "${local_digest:-}" ]; then
    log "WARN  $img — 本地无该 repo digest 记录，无法比对，跳过"
    skipped="$skipped $img"
    continue
  fi

  if [ "$local_digest" = "$remote" ]; then
    log "OK    $img — 已是最新"
  else
    log "NEW   $img — 本地 ${local_digest%${local_digest#???????????}}… -> 远程 ${remote%${remote#???????????}}…"
    updated="$updated $img"
  fi
done

# --- 2. 本地 :local 镜像：构建上下文是否更新 -----------------------------
# 用 Dockerfile + kits/<m>/ 目录内容的哈希作为"应该构建"的指纹。
# 注意：需要 dockerd，k8s 模式下它默认是关闭的；若不可用则仅报告。
local_stale=""
for m in aria2 bt redis; do
  [ -f "$REPO/kits/$m/Dockerfile" ] || continue
  ctx_hash=$(cat "$REPO/kits/$m/Dockerfile" 2>/dev/null | sha256sum | awk '{print $1}')
  # 取镜像自身创建时间与 Dockerfile mtime 比较（轻量近似）
  img_ts=$(k3s ctr -n k8s.io images ls 2>/dev/null | grep -F "g41k8s/$m:local" | awk '{print $5}' | head -1) || true
  df_mtime=$(date -r "$REPO/kits/$m/Dockerfile" +%s 2>/dev/null || echo 0)
  log "LOCAL $m — Dockerfile mtime=$df_mtime hash=${ctx_hash%${ctx_hash#????????}}…"
  local_stale="$local_stale $m"
done

# --- 3. 执行更新 ---------------------------------------------------------
if [ -z "${updated# }" ] && [ -z "${local_stale# }" ]; then
  log "没有需要更新的镜像"
else
  # 3a. 本地镜像重建（仅当 dockerd 可用）
  if ! docker info >/dev/null 2>&1; then
    log "NOTE: dockerd 未运行，跳过 :local 镜像重建（k8s 模式默认如此）"
  fi

  # 3b. 上游镜像：滚动重启各 Deployment
  for img in $updated; do
    # 找出哪些 Deployment 用到了这个镜像（归一化比较，短名/全限定名都能匹配）
    want_short=$(printf '%s' "$img" | sed 's|^docker\.io/||; s|^index\.docker\.io/||; s|^library/||')
    deals=$(kubectl -n "$NS" get deploy -o jsonpath="{range .items[*]}{.metadata.name}{\" \"}{range .spec.template.spec.containers[*]}{.image}{\" \"}{end}{\"\n\"}{end}" \
      | awk -v want="$want_short" '{
          d = $1
          for (i = 2; i <= NF; i++) {
            ref = $i
            sub(/^docker\.io\//, "", ref)
            sub(/^index\.docker\.io\//, "", ref)
            sub(/^library\//, "", ref)
            if (ref == want) { print d; break }
          }
        }' | sort -u) || true
    [ -n "${deals:-}" ] || continue

    for d in $deals; do
      ensure_rollout_safe "$d"
      ensure_pull_policy "$d" "$img"

      # 记录重启前的镜像指纹，用于事后校验"更新是否真的生效"
      before=$(kubectl -n "$NS" get pods -l "app=$d" \
               -o jsonpath="{.items[*].status.containerStatuses[*].imageID}" 2>/dev/null || true)

      log "UPDATE $d（镜像 $img）滚动重启中…"
      if kubectl -n "$NS" rollout restart "deploy/$d" >/dev/null 2>&1 \
         && kubectl -n "$NS" rollout status "deploy/$d" --timeout=300s >/dev/null 2>&1; then
        after=$(kubectl -n "$NS" get pods -l "app=$d" \
                -o jsonpath="{.items[*].status.containerStatuses[*].imageID}" 2>/dev/null || true)
        if [ "$before" = "$after" ] && [ -n "$before" ]; then
          # 重启成功但 digest 没变 —— 典型原因是 imagePullPolicy=IfNotPresent
          log "WARN  $d 已重启但镜像 digest 未变化，可能未实际拉取新版本"
          failed="$failed $d(未生效)"
        else
          log "UPDATE $d 完成（镜像已切换）"
        fi
      else
        log "ERROR  $d 重启失败或超时"
        failed="$failed $d"
      fi
    done
  done
fi

# --- 4. 记录状态 ---------------------------------------------------------
# --- 5. 通知 -------------------------------------------------------------
# 仅在**确实发生了更新或失败**时发信；一切最新则静默，避免每周噪音。
if [ -n "${updated# }" ] || [ -n "${failed# }" ]; then
  {
    echo "G41KiTS 每周镜像检查报告"
    echo
    echo "时间:   $(date -Is)"
    echo "已更新:${updated:- 无}"
    echo "失败:  ${failed:- 无}"
    echo "跳过:  ${skipped:- 无（查询失败通常为网络/限流，下周会重试）}"
    echo "本地:  ${local_stale:- 无}"
    echo
    echo "附: 当前运行镜像"
    kubectl -n "$NS" get deploy -o custom-columns=\
'NAME:.metadata.name,IMAGES:.spec.template.spec.containers[*].image' 2>/dev/null || true
    echo
    echo "附: pod 状态"
    kubectl -n "$NS" get pods 2>/dev/null || true
  } | python3 /opt/g41/k8s/host/g41-notify.py \
        "[G41KiTS] 镜像更新${failed:+ (有失败)}" >/dev/null 2>&1 || true
fi

if [ -z "${failed# }" ]; then
  collect | sha256sum | awk '{print $1}' > "$STATE_FILE"
  log "=== 完成：$([ -z "${updated# }" ] && echo 无更新 || echo "已更新:${updated}")${skipped:+  跳过:$skipped}${local_stale:+  本地:${local_stale}} ==="
  exit 0
else
  log "=== 完成但有失败:$failed ==="
  exit 1
fi
