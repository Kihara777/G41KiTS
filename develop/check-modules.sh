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
  # 三类都要覆盖：有 k8s 清单的、声明了 inject 的、以及带内容种子（tile/link/i18n）的。
  # 漏掉第三类时，`tile_*` 这些模块**一个包都不会生成**，而检查照样全绿——
  # 2026-11-08 变异测试正是这样发现漏洞的。
  # 只导出有 k8s 清单或 inject 的模块。
  # 内容（tile/app/link/i18n/data）不再按模块导出——2026-11-08 实测发现同名 ConfigMap
  # 依次 apply 会互相修剪，所以内容统一由 `kits content` 生成一张聚合的。
  if [ -d "$d/k8s" ] \
     || [ -n "$(jq -r '.inject.from // ""' "$d/info.json" 2>/dev/null | grep -v null)" ]; then :; else
    continue
  fi
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

        # 两种 ConfigMap：
        #   g41.content=seed → 键名映射到 tile/link/i18n 源文件
        #   其余（blc 模板一类）→ g41.module 指向的 blc_template 目录
        if cm.dig("metadata", "labels", "g41.content") == "seed"
          bad = cm["data"].any? do |k, c|
            src =
              case k
              when /^tile\.(.+)\.json$/        then "kits/#{$1}/tile.json"
              when /^app\.(.+)\.json$/         then "kits/#{$1}/app.json"
              when /^link\.(.+)\.json$/        then "kits/#{$1}/link.json"
              when /^i18n\.(.+)\.([a-z]{2,3})\.json$/ then "kits/#{$1}/i18n/#{$2}.json"
              when /^data\.(.+)\.([A-Za-z0-9_-]+)\.json$/ then "kits/#{$1}/data/#{$2}.json"
              else nil
              end
            src.nil? || !File.exist?(src) || File.binread(src) != c.b
          end
          exit(bad ? 1 : 0)
        end

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

# ---------- 4b. 聚合内容种子 ----------
section "内容种子（聚合）"
if "$ROOT/g41.sh" kits content >/tmp/cm-content.log 2>&1; then
  seedline=$(tail -1 /tmp/cm-content.log)
  pass "kits content：$seedline"
else
  fail "kits content 失败：$(tail -2 /tmp/cm-content.log | tr '\n' ' ')"
fi

# api 源码也是生成物（2026-11-09）。在引用闭环判据之前生成，
# 这样「redis 引用了 g41-api-src，有没有东西生产它」才能被回答。
if "$ROOT/g41.sh" kits api-src >/tmp/cm-api.log 2>&1; then
  pass "kits api-src：$(tail -1 /tmp/cm-api.log)"
else
  fail "kits api-src 失败：$(tail -2 /tmp/cm-api.log | tr '\n' ' ')"
fi

if [ -f dist/g41-content.yaml ]; then
  # 键数必须等于仓库里内容文件的总数——少了就是有模块被漏掉，
  # 而漏掉的表现在页面上是「某个磁贴不见了」，不是任何报错。
  want=0
  for f in kits/*/tile.json kits/*/app.json kits/*/link.json kits/*/i18n/*.json kits/*/data/*.json; do
    [ -f "$f" ] && want=$((want+1))
  done
  got=$(grep -cE '^  (tile|app|link|i18n|data)\.' dist/g41-content.yaml || true)
  if [ "$want" -eq "$got" ]; then pass "内容键数 $got = 仓库内容文件数 $want"; else fail "内容键数 $got ≠ 仓库文件数 $want"; fi

  if command -v kubeconform >/dev/null 2>&1; then
    if kubeconform -strict -summary -ignore-missing-schemas dist/g41-content.yaml >/tmp/cm-kc2.log 2>&1 \
       && ! grep -q 'Valid: 0, Invalid: 0' /tmp/cm-kc2.log; then
      pass "内容种子 schema"
    else
      fail "内容种子 schema：$(tail -1 /tmp/cm-kc2.log)"
    fi
  else
    skip "内容种子 schema（未安装 kubeconform）"
  fi

  if command -v ruby >/dev/null 2>&1; then
    if ruby -e '
      require "yaml"
      cm = YAML.load_stream(File.read(ARGV[0])).compact.find { |d| d["kind"] == "ConfigMap" }
      exit 1 if cm.nil?
      bad = cm["data"].any? do |k, c|
        src = case k
              when /^tile\.(.+)\.json$/ then "kits/#{$1}/tile.json"
              when /^app\.(.+)\.json$/  then "kits/#{$1}/app.json"
              when /^link\.(.+)\.json$/ then "kits/#{$1}/link.json"
              when /^i18n\.(.+)\.([a-z]{2,3})\.json$/ then "kits/#{$1}/i18n/#{$2}.json"
              when /^data\.(.+)\.([A-Za-z0-9_-]+)\.json$/ then "kits/#{$1}/data/#{$2}.json"
              end
        src.nil? || !File.exist?(src) || File.binread(src) != c.b
      end
      exit(bad ? 1 : 0)
    ' dist/g41-content.yaml; then
      pass "内容种子逐字节还原"
    else
      fail "内容种子还原不一致"
    fi
  else
    skip "内容种子逐字节还原（没有 ruby）"
  fi
fi

# ---------- 4c. ConfigMap 引用闭环 ----------
# 2026-11-08 的真实故障：`blc` 的清单引用了一个可选 ConfigMap（`blc-template-blct-tts`），
# 而生产上那个 ConfigMap 还没建。`optional: true` **不会跳过挂载**——它挂一个空卷，
# **把宿主目录整块遮住**，模板页当场 404。我原以为「缺失 = 少一个模板」，那只是结果对了一半。
# 判据：清单里引用的每个 ConfigMap 名，都必须在某个导出包（或内容种子里）被生产出来。
section "ConfigMap 引用闭环"
if command -v ruby >/dev/null 2>&1; then
  if ruby -e '
    require "yaml"
    refs = {}
    Dir["kits/*/k8s/*.yaml"].each do |f|
      YAML.load_stream(File.read(f)).compact.each do |d|
        next unless d["kind"] == "Deployment"
        (d.dig("spec","template","spec","volumes") || []).each do |v|
          cm = v["configMap"]; next if cm.nil?
          refs[cm["name"]] = f
        end
      end
    end
    # nginx 的几张 ConfigMap 是 `g41.sh k8s conf` 在运行期生成的，不在导出包里；
    # 判据要求「要么有包生产，要么 g41.sh 里提到了这个名字」。
    src = (File.read("g41.sh") rescue "")
    produced = []
    Dir["dist/*.yaml"].each do |f|
      YAML.load_stream(File.read(f)).compact.each do |d|
        next unless d["kind"] == "ConfigMap"
        produced << d.dig("metadata","name")
      end
    end
    # nginx 的几张 ConfigMap 由 `g41.sh k8s conf` 在运行期用 `nginx-conf-$sub` 拼名生成，
    # 导出包里没有、g41.sh 里也不是字面量。这里显式列出这类运行期生成的形状。
    runtime = ->(n) { n.start_with?("nginx-conf-") || n == "nginx-main" }
    missing = refs.reject { |name, _| produced.include?(name) || runtime.call(name) }
    unless missing.empty?
      missing.each { |name, f| warn "  #{f} 引用 ConfigMap #{name}，但没有包生产它" }
      exit 1
    end
    exit 0
  '; then
    pass "清单引用的 ConfigMap 都有包生产"
  else
    fail "有 ConfigMap 被引用却没有包生产（部署时会被空卷遮住）"
  fi
else
  skip "ConfigMap 引用闭环（没有 ruby）"
fi

# ---------- 4d. 镜像 tag 与版本一致 ----------
# 2026-11-09：自建镜像的清单开始引用版本 tag（g41k8s/<m>:<ver>）而不是 :local。
# 一旦版本升级而清单没跟，apply 出去的就是旧 tag（或 :local），而两者都存在，
# 没有任何东西会报错——只有「跑的不是你以为的那份镜像」。
section "镜像 tag 与版本一致"
bad_tag=""
for f in kits/*/k8s/*.yaml; do
  [ -f "$f" ] || continue
  while read -r mod tag; do
    [ -n "$mod" ] || continue
    [ -f "kits/$mod/info.json" ] || { bad_tag="$bad_tag ${f##*/}:$mod(无此模块)"; continue; }
    want=$(jq -r '.version // "local"' "kits/$mod/info.json" 2>/dev/null || echo "local")
    [ "$tag" = "$want" ] || bad_tag="$bad_tag ${f##*/}:g41k8s/$mod:$tag(期望 $want)"
  done < <(grep -oE 'g41k8s/[A-Za-z0-9_-]+:[A-Za-z0-9._+-]+' "$f" 2>/dev/null | sed 's|g41k8s/||' | tr ':' ' ' || true)
done
if [ -z "$bad_tag" ]; then pass "清单引用的自建镜像 tag 与 info.json 版本一致"; else fail "tag 与版本不一致:$bad_tag"; fi

# ---------- 5. 集群类判据：只查存在性 ----------
section "README 三语一致"
# 2026-11-12：README 三个版本原先都写着 `kits add -y all` 作为安装命令，而那是死路。
# 判据：三份 README 都必须出现 `kits install`（安装入口）与 `kits health`（体检）。
readme_bad=""
for f in README.md docs/README.en.md docs/README.ja.md; do
  [ -f "$f" ] || { readme_bad="$readme_bad $f(缺失)"; continue; }
  grep -q 'kits install' "$f" || readme_bad="$readme_bad ${f##*/}(无 kits install)"
  grep -q 'kits health'  "$f" || readme_bad="$readme_bad ${f##*/}(无 kits health)"
done
if [ -z "$readme_bad" ]; then pass "三份 README 都写了 install 与 health"; else fail "README 过时:$readme_bad"; fi

section "体检键名映射（kits health --self-test）"
# 内容种子的键名 → 源文件映射曾出过一次 bug（没先剥 .json），
# 表现是满屏「没有对应的源文件」——判据自己错的时候，看起来像系统坏了。
if "$ROOT/g41.sh" kits health --self-test >/tmp/cm-health.log 2>&1; then
  pass "$(tail -1 /tmp/cm-health.log)"
else
  fail "键名映射自检失败：$(tail -2 /tmp/cm-health.log | tr '\n' ' ')"
fi

section "现状账（kits status）"
if "$ROOT/g41.sh" kits status >/tmp/cm-status.log 2>&1; then
  rows=$(tail -n +3 /tmp/cm-status.log | grep -c . || true)
  # 行数为 0 说明账是空的——命令成功但什么都没报，和「没有模块」长得一样。
  if [ "$rows" -ge 10 ]; then pass "kits status：$rows 个模块入账"; else fail "kits status 只报出 $rows 行，账目可疑"; fi
else
  fail "kits status 失败：$(tail -2 /tmp/cm-status.log | tr '\n' ' ')"
fi

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
