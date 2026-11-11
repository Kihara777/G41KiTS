#!/usr/bin/env bash
# G41KiTS — 定期生产体检（2026-11-12 加）
#
# 存在理由：`kits health` 能查出「镜像缺失 / 宿主内容比 Pod 新 / 内容种子与仓库
# 不一致 / api 源码与仓库不一致」，但**没人跑它就等于没有**。这条把它变成定时任务。
#
# 两条设计约束（都是被别处教训换来的）：
#   1. **只在状态变化时通知**。每 6 小时发一封「还是红的」会把红变成背景噪音；
#      这个仓里已经有过一条每半小时响、而响过之后什么也做不了的信号。
#   2. 通知失败不影响退出码。通知是尽力而为，体检本身的结果才是事实。

set -uo pipefail

REPO=${G41_REPO:-/opt/g41}
STATE=${G41_HEALTH_STATE:-/var/lib/g41/health-last}
NOTIFY="$REPO/k8s/host/g41-notify.py"

cd "$REPO" || { echo "FATAL: $REPO 不存在"; exit 2; }

out=$(./g41.sh kits health 2>&1)
rc=$?

case "$rc" in
  0) state="green" ;;
  1) state="red" ;;
  2) state="unverified" ;;   # 没能验到——不是通过，也不是失败
  *) state="error:$rc" ;;
esac

prev="none"
[ -f "$STATE" ] && prev=$(cat "$STATE" 2>/dev/null || echo "none")

echo "health: $state（上次: $prev）"
echo "$out"

mkdir -p "$(dirname "$STATE")" 2>/dev/null
printf '%s' "$state" > "$STATE" 2>/dev/null

# 只在变化时通知；首次运行（none → 任意）也算变化，好让人知道它开始看了
if [ "$state" != "$prev" ] && [ "$state" != "green" ]; then
  if [ -x "$NOTIFY" ] || [ -f "$NOTIFY" ]; then
    printf '体检状态变化：%s → %s\n\n%s\n' "$prev" "$state" "$out" \
      | python3 "$NOTIFY" "G41KiTS 体检：$state" >/dev/null 2>&1 || true
  fi
fi

# 恢复成绿时也发一封——「它自己好了」同样值得知道
if [ "$state" = "green" ] && [ "$prev" != "green" ] && [ "$prev" != "none" ]; then
  [ -f "$NOTIFY" ] && python3 "$NOTIFY" "G41KiTS 体检：已恢复 green" <<EOF >/dev/null 2>&1 || true
之前：$prev

$out
EOF
fi

exit "$rc"
