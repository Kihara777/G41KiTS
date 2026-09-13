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

# --- 2. 本地 :local 镜像：构建上下文是否变化 -----------------------------
# 构建走 containerd 原生路径（nerdctl + BuildKit 的 containerd worker），
# **不依赖 dockerd**（k8s 模式下 dockerd 是停用的）。详见 g41-image-build.sh。
#
# 判定"是否需要重建"：对模块的构建输入（Dockerfile + 被 COPY 的本地文件）
# 求哈希，与上次成功构建时记录的哈希比对；仅哈希变化才重建，避免每周空转。
local_stale=""
local_unchanged=""

# 计算某模块的构建输入指纹（Dockerfile + 全部 COPY/ADD 的本地文件内容）
build_sig() {
  _m="$1"; _df="$REPO/kits/$_m/Dockerfile"
  _ins=""
  for _tok in $(grep -hE '^(COPY|ADD)[[:space:]]' "$_df" 2>/dev/null \
                | sed 's/^[A-Z]*[[:space:]]*//' | grep -v '^--'); do
    case "$_tok" in
      http*|/*) continue ;;   # 跳过远程资源与绝对路径
    esac
    for _p in "$REPO/$_tok" "$REPO/kits/$_m/$_tok"; do
      [ -f "$_p" ] && _ins="$_ins $_p"
    done
  done
  { cat "$_df" 2>/dev/null; for _f in $_ins; do cat "$_f" 2>/dev/null; done; } \
    | sha256sum | awk '{print $1}'
}

for m in aria2 bt redis; do
  [ -f "$REPO/kits/$m/Dockerfile" ] || continue
  [ -d "$REPO/kits/$m/k8s" ] || continue   # 仅 k8s 下真正部署的模块

  sig=$(build_sig "$m")
  prev_sig=""
  [ -f "$STATE_DIR/build-$m.sha256" ] && prev_sig=$(cat "$STATE_DIR/build-$m.sha256" 2>/dev/null || true)

  if [ "$sig" = "$prev_sig" ]; then
    local_unchanged="$local_unchanged $m"
    log "LOCAL $m — 构建输入未变化 (${sig%${sig#????????}}…)，跳过重建"
  else
    log "LOCAL $m — 构建输入已变化 ${prev_sig:+(${prev_sig%${prev_sig#????????}}… -> )}${sig%${sig#????????}}…，需重建"
    local_stale="$local_stale $m"
  fi
done

# --- 3. 执行更新 ---------------------------------------------------------
if [ -z "${updated# }" ] && [ -z "${local_stale# }" ]; then
  log "没有需要更新的镜像"
else
  # 3a. 本地镜像重建（containerd 原生，无需 dockerd）
  if [ -n "${local_stale# }" ]; then
    if [ -x /opt/g41/k8s/host/g41-image-build.sh ]; then
      log "REBUILD 本地镜像:${local_stale}"
      if /opt/g41/k8s/host/g41-image-build.sh $local_stale >/tmp/g41-rebuild.log 2>&1; then
        log "REBUILD 完成:${local_stale}"
        # 重建成功后更新各模块的构建指纹
        for m in $local_stale; do
          build_sig "$m" > "$STATE_DIR/build-$m.sha256"
        done
        # 重建后的镜像需要滚动重启相关 Deployment 才会生效
        for m in $local_stale; do
          case "$m" in
            redis)     d=redis ;;
            aria2|bt)  d=download ;;
            *)         d="" ;;
          esac
          [ -n "$d" ] || continue
          # hostPort 护栏：download 用 51413，需 maxSurge=0 才能滚动
          ensure_rollout_safe "$d"
          log "REBUILD 重启 $d 以加载新镜像"
          if kubectl -n "$NS" rollout restart "deploy/$d" >/dev/null 2>&1 \
             && kubectl -n "$NS" rollout status "deploy/$d" --timeout=300s >/dev/null 2>&1; then
            log "REBUILD $d 完成"
          else
            log "ERROR $d 重启失败或超时"
            failed="$failed $d"
          fi
        done
      else
        log "ERROR 本地镜像重建失败，日志尾部："
        tail -10 /tmp/g41-rebuild.log | sed 's/^/        /'
        failed="$failed $local_stale"
      fi
    else
      log "WARN g41-image-build.sh 不存在，跳过本地镜像重建"
    fi
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

# --- 4. 回收陈旧镜像与快照 -----------------------------------------------
# 坑：kubelet 的 image GC 只在**磁盘使用率超过 85%** 时才触发（默认阈值），
# 本机长期在 30% 上下，因此 GC 从不运行 —— 已删除/已切版本的镜像快照会
# 无限累积（实测堆积到 8.6GB，其中 5.9GB 是孤儿快照，而实际在用仅 2.7GB）。
# 这里主动回收，不等 GC 触发。
#
# 用 nerdctl system prune：它按「是否被容器引用」判定，保留一切在用镜像，
# 比 `ctr images prune --all` 安全（后者会连 tag 一起删、逼出重新拉取）。
pruned_before=$(du -sm /var/lib/rancher/k3s/agent/containerd 2>/dev/null | cut -f1)
if command -v nerdctl >/dev/null 2>&1; then
  log "GC 回收未引用镜像与快照…"
  if nerdctl --address /run/k3s/containerd/containerd.sock --namespace k8s.io \
        system prune -f >/tmp/g41-prune.log 2>&1; then
    pruned_after=$(du -sm /var/lib/rancher/k3s/agent/containerd 2>/dev/null | cut -f1)
    if [ -n "$pruned_before" ] && [ -n "$pruned_after" ]; then
      saved=$((pruned_before - pruned_after))
      if [ "$saved" -gt 100 ]; then
        log "GC 完成：containerd ${pruned_before}MB -> ${pruned_after}MB（释放 ${saved}MB）"
      else
        log "GC 完成：无可回收空间（${pruned_after}MB）"
      fi
    else
      log "GC 完成（空间统计不可用）"
    fi
  else
    log "WARN GC 失败，日志尾部："
    tail -5 /tmp/g41-prune.log | sed 's/^/        /'
  fi
else
  log "NOTE: nerdctl 不可用，跳过镜像 GC"
fi

# --- 5. 通知 -------------------------------------------------------------
# 仅在**确实发生了更新或失败**时发信；一切最新则静默，避免每周噪音。
if [ -n "${updated# }" ] || [ -n "${failed# }" ] || [ -n "${local_stale# }" ]; then
  {
    echo "G41KiTS 每周镜像检查报告"
    echo
    echo "时间:     $(date -Is)"
    echo "上游更新:${updated:- 无}"
    echo "本地重建:${local_stale:- 无}"
    echo "本地未变:${local_unchanged:- 无}"
    echo "失败:    ${failed:- 无}"
    echo "跳过:    ${skipped:- 无（查询失败通常为网络/限流，下周会重试）}"
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
  log "=== 完成：$([ -z "${updated# }" ] && echo 无上游更新 || echo "已更新:${updated}")${local_stale:+  本地重建:$local_stale}${local_unchanged:+  本地未变:$local_unchanged}${skipped:+  跳过:$skipped} ==="
  exit 0
else
  log "=== 完成但有失败:$failed ==="
  exit 1
fi
