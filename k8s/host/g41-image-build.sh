#!/bin/sh
# G41KiTS — 本地 :local 镜像构建（containerd 原生路径，无需 dockerd）
#
# 背景：k8s 模式下 dockerd 是停用的（集群用 k3s 自带的 containerd）。原
# `g41.sh k8s build` 走 `docker build` + `docker save | k3s ctr images import`，
# 在无 dockerd 的机器上无法运行。
#
# 本脚本改走 containerd 原生路径：
#   nerdctl build --buildkit-host <buildkitd.sock> --address <containerd.sock>
# BuildKit 以 containerd worker 模式直接构建到 k3s 的 k8s.io namespace 与
# overlayfs snapshotter，**省去 save/import 两步**，构建完镜像即刻可被 kubelet 使用。
#
# 依赖（由 k8s/host/buildkitd.service 提供 daemon 侧）：
#   /usr/local/bin/nerdctl      构建客户端
#   /usr/local/bin/buildkitd    BuildKit 守护进程
#
# 用法：
#   g41-image-build.sh            # 构建全部 compose=file 模块
#   g41-image-build.sh aria2 bt   # 只构建指定模块
#
# 退出码：0 = 全部成功；1 = 有失败

set -eu

REPO=/opt/g41
NS=k8s.io
BUILDKIT_SOCK=unix:///run/buildkit/buildkitd.sock
CONTAINERD_SOCK=/run/k3s/containerd/containerd.sock
LOG_TAG=g41-image-build

log() { echo "$(date -Is) [$LOG_TAG] $*"; }

PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PATH

command -v nerdctl >/dev/null 2>&1 || { log "FATAL: nerdctl 未找到（/usr/local/bin/nerdctl）"; exit 1; }

# BuildKit 必须先就绪，否则构建会以 "unknown service" 之类的方式失败
if ! systemctl is-active --quiet buildkitd.service; then
  log "FATAL: buildkitd.service 未运行，请先 systemctl start buildkitd.service"
  exit 1
fi

# 未指定模块时，从仓库自动发现所有 compose=file 的模块
if [ "$#" -gt 0 ]; then
  mods="$*"
else
  mods=""
  for f in "$REPO"/kits/*/info.json; do
    [ -f "$f" ] || continue
    m=$(basename "$(dirname "$f")")
    [ "$(jq -r '.compose // "none"' "$f" 2>/dev/null)" = "file" ] || continue
    [ -f "$REPO/kits/$m/Dockerfile" ] || continue
    # 仅构建在 k8s 下真正部署的模块：autoheal/dsock 等已退役（无 k8s/ 目录），
    # 构建它们既无意义，又会因构建上下文差异而失败。
    [ -d "$REPO/kits/$m/k8s" ] || continue
    mods="$mods $m"
  done
fi

[ -n "${mods# }" ] || { log "没有找到 compose=file 模块，无事可做"; exit 0; }

failed=""
built=""

for m in $mods; do
  df="$REPO/kits/$m/Dockerfile"
  if [ ! -f "$df" ]; then
    log "SKIP  $m — 无 Dockerfile"
    continue
  fi
  tag="g41k8s/$m:local"

  # 构建上下文取决于 Dockerfile 的 COPY/ADD 路径风格：
  #   形如 kits/<m>/xxx -> 上下文为仓库根（如 redis）
  #   形如裸文件名 xxx  -> 上下文为 kit 目录（autoheal 等 compose-only 模块）
  # 判定错误会以 "failed to calculate checksum ... not found" 失败。
  if grep -qE '^(COPY|ADD)[[:space:]]+[^[:space:]]*kits/' "$df"; then
    ctx="$REPO"; dfrel="kits/$m/Dockerfile"
  else
    ctx="$REPO/kits/$m"; dfrel="Dockerfile"
  fi

  log "BUILD $m -> $tag（上下文 ${ctx#"$REPO"/}）"
  if ( cd "$ctx" && nerdctl \
        --address "$CONTAINERD_SOCK" --namespace "$NS" \
        build --buildkit-host "$BUILDKIT_SOCK" \
        -f "$dfrel" -t "$tag" . ) >/tmp/g41-build-$m.log 2>&1; then
    d=$(k3s ctr -n "$NS" images ls 2>/dev/null | grep -F "$tag" | awk '{print $3}' | head -1)
    log "OK    $m -> ${d:-?}"
    built="$built $m"
  else
    log "ERROR $m 构建失败，日志尾部："
    tail -15 "/tmp/g41-build-$m.log" | sed 's/^/        /'
    failed="$failed $m"
  fi
done

if [ -n "${built# }" ]; then
  log "已构建:${built}"
fi
if [ -n "${failed# }" ]; then
  log "构建失败:${failed}"
  exit 1
fi
log "全部完成"
