#!/usr/bin/env bash
# G41KiTS — 模块系统自检入口
#
# 为什么要有这个文件：
#   2026-11-07 之前，本仓的判据散在几处——`kits selftest`、导出的对照臂、
#   `k8s drift`、kubeconform——但**没有一条命令把它们跑一遍**。判据存在而在跑，
#   与判据存在但没人跑，是两件事；后者只是一份说明书。
#
# 三种结果不许合并（和本仓其他判据同一条规矩）：
#   0 = 全部通过
#   1 = 有失败
#   2 = 有「没能验到」（缺工具/缺集群）且没有失败
#   有失败时一律返回 1，即使同时也存在「没能验到」——失败优先。
#
# 用法：
#   bash develop/check-modules.sh            # 全跑
#   bash develop/check-modules.sh --quiet    # 只打印失败与汇总
#
# 不做什么（明说，免得被当成验过了）：
#   - 不连集群。`k8s drift` 需要集群，这里只检查命令存在与语法。
#   - 不构建镜像。/真跑镜像在 CI 里没有 k3s，属于另一层验证。

set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT" || exit 2

QUIET=""
[ "${1:-}" = "--quiet" ] && QUIET=1

fails=0
unverified=0
ran=0

pass() { ran=$((ran+1)); [ -n "$QUIET" ] || echo "  ✔ $*"; }
fail() { ran=$((ran+1)); fails=$((fails+1)); echo "  ✘ $*"; }
skip() { ran=$((ran+1)); unverified=$((unverified+1)); echo "  ▸ 没能验到：$*"; }
section() { [ -n "$QUIET" ] || { echo; echo "=== $* ==="; }; }

# ---------- 1. 语法 ----------
section "语法"
if bash -n g41.sh 2>/tmp/cm.err; then pass "g41.sh 语法"; else fail "g41.sh 语法：$(head -2 /tmp/cm.err | tr '\n' ' ')"; fi
if sh -n k8s/host/g41-image-build.sh 2>/tmp/cm.err; then pass "k8s/host/g41-image-build.sh 语法"; else fail "k8s/host/g41-image-build.sh 语法"; fi
if command -v node >/dev/null 2>&1; then
  if node --check kits/redis/store/server.js 2>/tmp/cm.err; then pass "server.js 语法"; else fail "server.js 语法：$(head -2 /tmp/cm.err | tr '\n' ' ')"; fi
else
  skip "server.js 语法（没有 node）"
fi

# ---------- 2. 模块元数据 ----------
section "模块元数据"
bad_json=""
for f in kits/*/info.json; do
  [ -f "$f" ] || continue
  jq empty "$f" 2>/dev/null || bad_json="$bad_json $f"
done
if [ -z "$bad_json" ]; then pass "所有 info.json 是合法 JSON"; else fail "非法 JSON:$bad_json"; fi

# version 一旦写了就必须是安全字符（它直接进镜像 tag 与文件名）
bad_ver=""
for f in kits/*/info.json; do
  v=$(jq -r '.version // ""' "$f" 2>/dev/null)
  [ -n "$v" ] && [ "$v" != "null" ] || continue
  case "$v" in *[!A-Za-z0-9._+-]*) bad_ver="$bad_ver $f:$v";; esac
done
if [ -z "$bad_ver" ]; then pass "version 字段字符安全"; else fail "version 含非法字符:$bad_ver"; fi

# 同 Pod 组内不能有两个模块都缺 k8s 目录（否则组是不完整的）
section "Pod 组完整性"
group_broken=""
for f in kits/*/info.json; do
  m=$(basename "$(dirname "$f")")
  pod=$(jq -r '.k8s.pod // ""' "$f" 2>/dev/null)
  [ -n "$pod" ] && [ "$pod" != "null" ] || continue
  # 组里至少有一个模块提供 Deployment，否则整组没有工作负载
  has_deploy=0
  for g in kits/*/info.json; do
    gm=$(basename "$(dirname "$g")")
    [ "$(jq -r '.k8s.pod // ""' "$g" 2>/dev/null)" = "$pod" ] || continue
    grep -q '^kind: Deployment' "kits/$gm/k8s/"*.yaml 2>/dev/null && has_deploy=1
  done
  [ "$has_deploy" -eq 1 ] || group_broken="$group_broken $pod"
done
if [ -z "$group_broken" ]; then pass "每个 Pod 组都有 Deployment"; else fail "Pod 组没有 Deployment:$group_broken"; fi

# ---------- 3. 模块自带自检 ----------
section "模块自检"
"$ROOT/g41.sh" kits selftest >/tmp/cm-selftest.log 2>&1
st_rc=$?
if [ "$st_rc" -eq 0 ]; then
  pass "kits selftest：$(grep -o '自检：[0-9]* 个模块，失败 [0-9]* 个' /tmp/cm-selftest.log | tail -1)"
elif [ "$st_rc" -eq 2 ]; then
  skip "kits selftest（没有模块声明 selftest）"
else
  fail "kits selftest 失败：$(grep '✘' /tmp/cm-selftest.log | head -3 | tr '\n' ' ')"
fi

# ---------- 4. 导出与 schema ----------
section "导出与 schema"
exported=0
bad_export=""
for d in kits/*/; do
  m=$(basename "$d")
  [ -d "$d/k8s" ] || [ -n "$(jq -r '.inject.from // ""' "$d/info.json" 2>/dev/null | grep -v null)" ] || continue
  if "$ROOT/g41.sh" kits export "$m" >/tmp/cm-export.log 2>&1; then
    exported=$((exported+1))
  else
    bad_export="$bad_export $m"
  fi
done
if [ -z "$bad_export" ]; then pass "导出：$exported 个模块"; else fail "导出失败:$bad_export"; fi

if [ "$exported" -gt 0 ]; then
  if command -v kubeconform >/dev/null 2>&1; then
    kc_bad=""
    for f in dist/*.yaml; do
      [ -f "$f" ] || continue
      if ! kubeconform -strict -summary -ignore-missing-schemas "$f" >/tmp/cm-kc.log 2>&1; then
        kc_bad="$kc_bad ${f##*/}"
      fi
      # 校验了 0 个对象 = 根本没读到文件，不能算通过
      grep -q 'Valid: 0, Invalid: 0' /tmp/cm-kc.log && kc_bad="$kc_bad ${f##*/}(0对象)"
    done
    if [ -z "$kc_bad" ]; then pass "kubeconform：$(ls dist/*.yaml 2>/dev/null | wc -l) 个包"; else fail "kubeconform:$kc_bad"; fi
  else
    skip "kubeconform（未安装）"
  fi

  # ConfigMap 逐字节还原：导出必须是可逆的，否则「导出」是一次静默变形
  if command -v ruby >/dev/null 2>&1; then
    rt_bad=""
    for f in dist/*.yaml; do
      [ -f "$f" ] || continue
      ruby -e '
        require "yaml"
        docs = YAML.load_stream(File.read(ARGV[0])).compact
        cm = docs.find { |d| d["kind"] == "ConfigMap" }
        exit 0 if cm.nil?
        mod = cm.dig("metadata", "labels", "g41.module")
        exit 0 if mod.nil?
        src = "kits/#{mod}/blc_template"
        exit 0 unless File.directory?(src)
        bad = cm["data"].any? { |n, c| File.binread(File.join(src, n)) != c.b }
        exit(bad ? 1 : 0)
      ' "$f" || rt_bad="$rt_bad ${f##*/}"
    done
    if [ -z "$rt_bad" ]; then pass "ConfigMap 逐字节还原"; else fail "ConfigMap 还原不一致:$rt_bad"; fi
  else
    skip "ConfigMap 逐字节还原（没有 ruby）"
  fi
fi

# ---------- 5. 集群类判据：只查存在性 ----------
section "集群类判据（不连集群）"
if grep -q '^k8s_drift()' g41.sh; then pass "k8s drift 已实现（这里不连集群，故不验它的行为）"; else fail "k8s drift 缺失"; fi

# ---------- 汇总 ----------
echo
if [ "$fails" -gt 0 ]; then
  echo "结果：**失败 $fails 项**（共跑 $ran 项，其中没能验到 $unverified 项）"
  exit 1
fi
if [ "$unverified" -gt 0 ]; then
  echo "结果：没有失败，但 **$unverified 项没能验到**（共 $ran 项）——这不是通过"
  exit 2
fi
echo "结果：$ran 项全部通过"
exit 0
