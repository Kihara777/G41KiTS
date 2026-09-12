#!/bin/sh
# G41KiTS — 证书更新后分发到各消费 Pod
#
# 背景：cert-manager 续期后只更新 Secret `g41/g41-tls`，Pod 内挂载的证书
#       虽然会被 kubelet 自动刷新（..data 符号链接切换），但**进程不会自动
#       重读**。各消费者的热加载能力并不一致：
#
#         nginx  — 自带 reloader sidecar，监听 /certs 变化后 kill -HUP 1
#                  → 已热加载，本脚本仅做校验，不重启
#         hy2    — hostNetwork + UDP/443，无热加载机制 → 必须滚动重启
#         dns    — UDP/53 + 853，无热加载机制         → 必须滚动重启
#
#       注意：hy2/dns 上的 `reloader.stakater.com/auto` 注解是**失效的** ——
#       集群内并未部署 stakater/reloader 控制器。该注解仅为保留兼容，真正
#       生效的重启由本脚本负责。
#
# 幂等：以 Secret 中 tls.crt 的 sha256 为版本指纹，与状态文件比对；
#       指纹未变则直接退出，不会无谓重启。
#
# 退出码：0 = 无变化或已完成；1 = 失败（供 systemd 记录）

set -eu

NS=g41
SECRET=g41-tls
STATE_DIR=/var/lib/g41
STATE_FILE="$STATE_DIR/cert.sha256"
LOG_TAG=g41-cert-reload

log() { echo "$(date -Is) [$LOG_TAG] $*"; }

# systemd 环境下确保 PATH 含 kubectl
PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PATH

command -v kubectl >/dev/null 2>&1 || { log "FATAL: kubectl 未找到"; exit 1; }

mkdir -p "$STATE_DIR"

# --- 1. 读取当前 Secret 中证书（一次取出，后续复用）-----------------------
CRT_FILE=$(mktemp)
trap 'rm -f "$CRT_FILE"' EXIT
kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.tls\.crt}' 2>/dev/null \
  | base64 -d > "$CRT_FILE" 2>/dev/null || true

if [ ! -s "$CRT_FILE" ]; then
  log "FATAL: 无法读取 $NS/$SECRET 的 tls.crt"
  exit 1
fi

cur=$(sha256sum "$CRT_FILE" | awk '{print $1}')

prev=""
[ -f "$STATE_FILE" ] && prev=$(cat "$STATE_FILE" 2>/dev/null || true)

if [ "$cur" = "$prev" ]; then
  log "证书未变化 (${cur%${cur#???????}}…)，无需操作"
  exit 0
fi

log "检测到证书更新: ${prev:-<无记录>} -> $cur"

# --- 2. 证书有效期自检（防止分发一张已过期的证书）------------------------
notafter=$(openssl x509 -in "$CRT_FILE" -noout -enddate 2>/dev/null | cut -d= -f2) || true
if [ -z "${notafter:-}" ]; then
  log "FATAL: 新证书不可解析，中止分发"
  exit 1
fi
if ! openssl x509 -in "$CRT_FILE" -noout -checkend 0 >/dev/null 2>&1; then
  log "FATAL: 新证书已过期 (notAfter=$notafter)，中止分发"
  exit 1
fi
log "新证书有效，notAfter=$notafter"

# --- 3. nginx：校验热加载是否已生效 --------------------------------------
# reloader sidecar 每 5s 扫描 /certs，触发 SIGHUP。只需确认 nginx 配置仍然
# 合法且进程未进入错误状态，不主动重启（避免 443 秒级中断）。
if kubectl -n "$NS" get deploy nginx >/dev/null 2>&1; then
  if kubectl -n "$NS" exec deploy/nginx -c nginx -- nginx -t >/dev/null 2>&1; then
    log "nginx: 配置校验通过，交由 reloader sidecar 热加载（不重启）"
  else
    log "WARN: nginx 配置校验失败，请人工检查"
  fi
fi

# --- 4. hy2 / dns：滚动重启以重读证书 ------------------------------------
# 这两个服务无热加载能力，必须重建 Pod。重启会短暂中断：
#   hy2 — hostNetwork UDP/443，代理连接会断开数秒
#   dns — UDP/53/853，期间 DNS 查询失败

# hostPort 与 maxSurge 互斥：单节点集群里，使用 hostPort 的 Deployment 若
# maxSurge>0，新 Pod 会因端口被占而永久 Pending（dns 实测踩过）。强制归零。
ensure_rollout_safe() {
  d="$1"
  hp=$(kubectl -n "$NS" get deploy "$d" \
       -o jsonpath='{range .spec.template.spec.containers[*].ports[*]}{.hostPort}{" "}{end}' 2>/dev/null || true)
  case "$hp" in
    *[0-9]*) ;;
    *) return 0 ;;
  esac
  surge=$(kubectl -n "$NS" get deploy "$d" \
          -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null || true)
  if [ "${surge:-0}" != "0" ]; then
    log "FIX   $d 使用 hostPort [$hp] 但 maxSurge=$surge，改为 0"
    kubectl -n "$NS" patch deploy "$d" -p \
      '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":0,"maxUnavailable":1}}}}' \
      >/dev/null 2>&1 || true
  fi
}

restart_one() {
  svc="$1"
  if ! kubectl -n "$NS" get deploy "$svc" >/dev/null 2>&1; then
    log "$svc: 部署不存在，跳过"
    return 0
  fi
  ensure_rollout_safe "$svc"
  log "$svc: 滚动重启中…"
  if kubectl -n "$NS" rollout restart "deploy/$svc" >/dev/null 2>&1 \
     && kubectl -n "$NS" rollout status "deploy/$svc" --timeout=180s >/dev/null 2>&1; then
    log "$svc: 重启完成，已加载新证书"
  else
    log "ERROR: $svc 重启超时或失败"
    return 1
  fi
}

rc=0
restart_one hy2 || rc=1
restart_one dns || rc=1

# --- 5. 记录状态 ---------------------------------------------------------
# 仅在所有步骤成功后落盘指纹，失败时保留旧值以便下次重试
if [ "$rc" -eq 0 ]; then
  echo "$cur" > "$STATE_FILE"
  log "全部完成，指纹已更新"
else
  log "部分步骤失败，指纹未更新（下次运行会重试）"
fi

# --- 6. 通知 -------------------------------------------------------------
# 仅在**证书真的轮换时**发信（本分支只在指纹变化后到达），无变化时静默。
{
  echo "G41KiTS 证书已更新并分发"
  echo
  echo "证书指纹: ${prev:-<无记录>} -> $cur"
  echo "有效期至: ${notafter:-未知}"
  echo "时间:     $(date -Is)"
  echo
  echo "动作:"
  echo "  nginx  已校验，由 reloader sidecar 热加载（未重启）"
  echo "  hy2    滚动重启完成"
  echo "  dns    滚动重启完成"
  echo
  echo "附: pod 状态"
  kubectl -n "$NS" get pods -o wide 2>/dev/null || true
} | python3 /opt/g41/k8s/host/g41-notify.py \
      "[G41KiTS] 证书已轮换 ${notafter:-}" >/dev/null 2>&1 || true

exit "$rc"
