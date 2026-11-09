#!/usr/bin/env bash
set -e -o pipefail

DEBIAN_FRONTEND=noninteractive

validate_dirs() {
  echo 'Validating working directory...'
  local required=(compose.yaml .env kits/)
  local missing=()
  for f in "${required[@]}"; do
    [ -e "$f" ] || missing+=("$f")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: Missing: ${missing[*]}"
    echo "Run from G41KiTS project root."
    exit 1
  fi
}

setup_dns_stub() {
  echo '=== Disable systemd-resolved stub ==='
  mkdir -p /etc/systemd/resolved.conf.d/
  chmod 755 /etc/systemd/resolved.conf.d/
  cat << DSL > /etc/systemd/resolved.conf.d/noresolved.conf
[Resolve]
DNSStubListener=no
DSL
  systemctl restart systemd-resolved.service
  echo 'StubListener disabled'
}

install_golang() {
  echo '=== Go + q DNS client ==='
  snap install go --classic
  export PATH=$PATH:$HOME/go/bin
  go install github.com/natesales/q@latest
  ln -sf ~/go/bin/q /usr/local/bin/q && chmod +x /usr/local/bin/q
  echo 'Go + q installed'
}

install_packages() {
  echo "=== Install packages: $* ==="
  apt update -q
  apt install -yq "$@"
}

install_docker() {
  echo '=== Docker ==='
  install_packages docker.io docker-compose-v2
  systemctl enable docker.service
  echo 'Docker installed'
}

deploy_containers() {
  echo '=== Build & Deploy ==='
  docker compose build
  docker compose up -d
  echo 'Containers running'
}

setup_acme() {
  echo '=== SSL Certificate ==='
  source .env
  echo "Domain: $G41_DOMAIN, Extra: $G41_EXTRA_DOMAINS"
  local extra_args=""
  for d in $G41_EXTRA_DOMAINS; do
    extra_args="$extra_args -d $d --challenge-alias $G41_DOMAIN"
  done
  docker compose exec \
    -e CF_Key="$CF_Key" \
    -e CF_Email="$CF_Email" \
    acme --register-account -m $ACME_EMAIL --server zerossl --issue \
      -d $G41_DOMAIN -d *.$G41_DOMAIN --challenge-alias no \
      $extra_args \
      --dns dns_cf --keylength ec-384 \
      --fullchain-file /acme.sh/fc \
      --key-file /acme.sh/k \
      --reloadcmd "docker compose restart dns hy2" \
      --log
  echo 'SSL cert issued'
}


do_init() {
  validate_dirs

  # Load optional local init (deployer-specific VPS setup)
  if [ -d .local ] && [ -f .local/install.sh ]; then
    echo '=== Local init: .local/install.sh ==='
    source .local/install.sh
  elif [ -f .local.sh ]; then
    echo '=== Local init: .local.sh ==='
    source .local.sh
  fi

  if declare -f do_init_local >/dev/null 2>&1; then
    do_init_local
  else
    echo '=== No local init found (.local/install.sh or .local.sh), skipping host setup ==='
  fi

  setup_dns_stub
  install_golang
  install_docker
  deploy_containers
  setup_acme
  show_ascii
}

do_init_k8s() {
  validate_dirs

  # 部署者专属主机初始化（.local/install.sh 或 .local.sh）
  if [ -d .local ] && [ -f .local/install.sh ]; then
    source .local/install.sh
  elif [ -f .local.sh ]; then
    source .local.sh
  fi
  if declare -f do_init_local >/dev/null 2>&1; then
    do_init_local
  fi

  setup_dns_stub

  echo '=== k3s ==='
  if ! command -v k3s >/dev/null 2>&1; then
    curl -sfL https://get.k3s.io | sh -s - --disable traefik --disable metrics-server --disable servicelb
  fi
  bash k8s/host/install-1gb.sh     # tmpfs kine + 状态备份 + standalone 单元
  bash k8s/host/host-tune.sh       # journald/zram/swappiness/snapd/fail2ban
  ./g41.sh backend k8s
  systemctl enable --now k3s-standalone
  for i in $(seq 1 72); do kubectl get nodes 2>/dev/null | grep -q ' Ready ' && break; sleep 5; done
  ./g41.sh k8s stage
  show_ascii
}

show_ascii() {
cat <<'G41ONLY'
                                                       ^^^^^"
                                                  '`   ^!Ii:""`'`^"
                                               ^`{+^(@> "Il;,!i+~:,",
                                            ^^,li!^ ((@'     `^":;:",:,,
                                          ,^;~l;,^ t@:kB k@#mxi!^"  `::,,,
                                         ,"I!I'    (r::@(+{(((1I:(#/...',I,
                 ^^^^^^""]}[)"^         ,,,^    v$@@t-:@@:<((((((((((vJ'^^^;
              "^:>lIi!l!~ll>-}}{//(i   ^"I'  z@@dW@@af:(@@@0hM)//!)1n||/([^^,
           ^^".         ^I::;;:;i ':ndl' .^z@@bB@@@j@kI;j!      .`^```^^][1^:"
         ^`     "-+<>li     ;l  :jjf@|lrz,  _z0+'   :@I:k; "::::::;::,"^^^":~"
          `:tW$aOz@@$ooo@J()  l@kf(@C               'ck-(( ^::::::::::,,:,,"^:^
      `n@@@@@@@@@phWwCXxB@@@@mkr(@@#  @@"@@@   ,,,"^.:/r]Q.^,I::;::::::::,,,.}.
    "^!`         .QbW@@$B@*a@(c(@@p:n  @@`i@@@  ,,,"^^~|}r[.^;;::::::::::,:, Q
   ,^lI,Il!Il^        +w(h@o@((Y@@mj(!B  @@@(@@ ,,,,^^^([fo ^I;::::::,,:,::.^}.
  ,";:;^I;I>--tj[!  ;  /.(@@@(f@@j0Z((i@@      ':,,,,^^I1[v `,:::::::::,:," d
  ,,,,;I`!-t{.      >  ):(@bd(@@@|hb]+(("@.  :ll,I,,,,^^]/(v'",::::::,,::" ^C
 ,,lill<-)    '.)@M1'+xj~{@wh@:{  {B@{<)v<@! ';;,,,,,,"^^)(C.^,::::;::::' ;@
,,I;;l!_.  ].m*i,``' <[t!iBpa      (l@O-1t:@< .I:,l,,,,"^^1j`^::,::::,"  |@
,,;,i`'  {Y*^,,"l>!.l[j}_-p)  ^^;,.  trJ[[|`l@ :,,l,,,,,"^^t>^,::,,:`  "@
,,lI`v']kt''^Ii>i>'`t|_-nbC  `:;IllI   {Cx(r'@ ":,l,,,,,,^^!}^,,,.  .)Bc
,,I,```,`;!l<iil!, i;(|Qk(  ,::l!!IlI:' ~]x}ih  ,:I^^,,,,,"^,.   ^a*W`
,,lI;<l            `)-__                    ^ .
,,:;,,; @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 ,,!I;; @-------------------------------------------------------------@
  ,:;;, @0----@@@@@@@*--1(---@@@-]---@@@-[{}}{){)1)(())))111)1){{11}]-@
  ,,::; @J--*@@@@-w@@@@-]--Q@@@@---@@@@@-cOmkdQCmpZnnCZYQOntrCdQzCwv]-@
   ,,:: @z--@@@-----------@@@@@@--@@@@@@-]....._]..]#..0..0[X..;d..}]-@
    ,,I @z--@@@--*@@@@@/{@@$-f@@-----@@@-..b##.`}``....#..#}]|]...]j]-@
      , @m--@@@B----M@@@@@@@@@@@@M-}-@@@-..]Z]..[..].'.#..0#bzh".wc/]-@
        @Z---@@@@@@@@@@}-----$@@---|-@@@-J].../dr..C)..z.....!0..J{[]-@
        @--]---*B@@*-|h--1()-0**-[1}-*a*-(jzJvf1(vYjnvnvrXwQcf/tf1}]]-@
       @@o------------------------------------------------------------@
       @@@@@@m0@@@@@@@@@@@@@@@@@@@@@@@w0@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
G41ONLY
}

kits_help() {
  echo "Usage: $0 kits [check|add|del|reload|--help] [module]"
  echo "  kits              Interactive module browser"
  echo "  kits check <mod>  Verify installed module files"
  echo "  kits verify <mod>  Full pre-install validation (L1-L4)"
  echo "  kits add <mod>    Install module (-y skip, -C core, 'all' for all)"
  echo "  kits del <mod>    Uninstall module (-y skip, -C core, 'all' cascading)"
  echo "  kits reload       Hot-reload tile/i18n/link data into Redis (zero downtime)"
  echo "  kits pack [-L] [-S] [-A] [-D]  Build archive (-L .local, -S store, -A agents, -D docs)"
  echo "  kits export <mod> [-o <path>]  Bundle a module's k8s manifests into one file (可远程分发)"
  echo "  kits update <mod> [--to <ver>] [--build] [--apply]   改版本号、重出包、可选构建与落集群"
  echo "  kits rollback <mod> [--to <ver>] [--apply] 回滚到 dist/ 里现存的一个旧版本"
  echo "  kits selftest [mod]  跑模块自带的自检（info.json 的 selftest 字段）"
  echo "  kits remote <url> [--apply] [-n <ns>] [--sha256 <hex>]"
  echo "                   从远程地址安装模块：先取、算哈希、显示来源，--apply 才落集群"
  echo "  kits simulate       Trace mode (--dry-run)"
  echo "  backend [get|compose|k8s]  Select deployment backend"
  echo "  k8s [apply|build|status]   k8s backend operations (apply --all = bootstrap all kits)"
  exit 0
}

kits_verify() {
  # md 必须单独赋值：`local m="$1" md="kits/$m"` 里 $m 的展开发生在赋值**之前**
  # （local 的右值先作为参数统一展开），于是 md 恒为 "kits/" —— L1/L3/L4 与
  # 模块不存在时的报错会全部落在 kits/ 这一层，等于从不检查，却照样打印 PASS。
  local m="$1" errors=0
  local md="kits/$m"
  [ -n "$m" ] || { echo "ERROR: module name required"; return 1; }
  [ -d "$md" ] || { echo "ERROR: module '$m' not found"; return 1; }
  echo "Verify: $m"

  # L1 — Self-check: declared files/dirs must exist
  echo "  L1 self-check..."
  if [ -f "$md/info.json" ]; then
    local compose=$(jq -r '.compose // "none"' "$md/info.json" 2>/dev/null)
    case "$compose" in
      file) [ -f "$md/Dockerfile" ] || { echo "  ERR: compose=file but no Dockerfile"; errors=$((errors+1)); }
            ;&
      hub)  [ -f "$md/compose.yaml" ] || { echo "  ERR: compose=$compose but no compose.yaml"; errors=$((errors+1)); }
            ;;
    esac
    [ -n "$(jq -r '.store // ""' "$md/info.json" 2>/dev/null)" ] && [ ! -d "$md/store" ] && { echo "  ERR: store declared but no store/ dir"; errors=$((errors+1)); }
    [ -n "$(jq -r '.webroot // ""' "$md/info.json" 2>/dev/null)" ] && [ "$(jq -r '.webroot.method // ""' "$md/info.json" 2>/dev/null)" != "mkdir" ] && [ ! -d "$md/webroot" ] && { echo "  ERR: webroot declared but no webroot/ dir"; errors=$((errors+1)); }
  fi
  [ -f "$md/tile.json" ] && [ ! -d "$md/i18n" ] && { echo "  ERR: tile module missing i18n dir"; errors=$((errors+1)); }
  # L1b — tile i18n key coverage.
  # tile.json 的 label / sections[].h / sections[].p / items[].label|desc 在页面上经
  # t() 解析：值若是 i18n 键，**缺键不会报错**，只是把键名原样渲染到首页；server.js
  # 解析不了的 i18n 文件也只 console.error（数据端点照样 200）。两种都是静默劣化，
  # 所以逐语言要求存在。只把「纯标识符形状的值」当键 —— 含空格/HTML 的值是字面文本
  # （如 home 磁贴里的 <a href=…>），不参与检查。
  if [ -f "$md/tile.json" ] && [ -d "$md/i18n" ]; then
    local lfiles=$(ls "$md"/i18n/*.json 2>/dev/null)
    [ -n "$lfiles" ] || { echo "  ERR: tile.json present but i18n/ has no *.json"; errors=$((errors+1)); }
    local tkeys=$(jq -r '[.label, (.sections[]?|.h,.p), (.items[]?|.label,.desc)]
                          | map(select(type=="string" and test("^[A-Za-z][A-Za-z0-9_]*$")))
                          | unique[]' "$md/tile.json" 2>/dev/null)
    local lf lang k hit
    for lf in $lfiles; do
      lang=$(basename "$lf" .json)
      jq empty "$lf" 2>/dev/null || { echo "  ERR: i18n/$lang.json is not valid JSON"; errors=$((errors+1)); continue; }
      for k in $tkeys; do
        hit=$(jq -r --arg k "$k" 'has($k)' "$lf" 2>/dev/null)
        [ "$hit" = "true" ] || { echo "  ERR: i18n/$lang.json missing key '$k' (referenced by tile.json)"; errors=$((errors+1)); }
      done
    done
  fi
  if [ -d "$md/site" ]; then
    local has_zone=0 has_upstream=0 has_location=0
    local ext=$(kit_site_ext "$m")
    for sf in $(kit_site_files "$m" 2>/dev/null); do
      [ -f "$md/site/$sf.$ext" ] && case "$sf" in
        zone) has_zone=1 ;; upstream) has_upstream=1 ;; location) has_location=1 ;;
      esac
    done
    [ $has_zone -eq 1 ] && [ $has_upstream -eq 0 ] && [ $has_location -eq 0 ] && { echo "  WARN: zone without upstream or location"; }
  fi

  # L2 — Dependency availability
  echo "  L2 dependencies..."
  if [ -f "$md/info.json" ]; then
    local deps=$(jq -r '.depends[]?' "$md/info.json" 2>/dev/null)
    for dep in $deps; do
      [ "$dep" = "$(kit_core)" ] && continue
      if [ ! -d "kits/$dep" ] && ! kits_installed "$dep"; then
        echo "  ERR: dependency '$dep' not found in kits/ and not installed"; errors=$((errors+1))
      fi
    done
  fi

  # L3 — Provides file validation (verify consumer has required files for provider)
  echo "  L3 provides validation..."
  if [ -f "$md/info.json" ]; then
    local deps=$(jq -r '.depends[]?' "$md/info.json" 2>/dev/null)
    for dep in $deps; do
      [ "$dep" = "$(kit_core)" ] && continue
      [ ! -f "kits/$dep/info.json" ] && continue
      local accepts=$(jq -r '.provides[]? | select(.check != false) | .accepts[]?' "kits/$dep/info.json" 2>/dev/null)
      for type in $accepts; do
        local fname=$(kit_provides_file "$type" "$m")
        local fpath="$md/$fname"
        [ -f "$fpath" ] || [ -d "$fpath" ] || { echo "  ERR: $dep requires $type but no $fname"; errors=$((errors+1)); }
      done
    done
  fi

  # L4 — .local file validation
  echo "  L4 .local files..."
  local item_count=$(jq '.local | length' "$md/info.json" 2>/dev/null)
  if [ -n "$item_count" ] && [ "$item_count" -gt 0 ] 2>/dev/null; then
    local i=0
    while [ $i -lt $item_count ]; do
      local lf=$(jq -r ".local[$i].file" "$md/info.json" 2>/dev/null)
      local lsrc="$md/.local/$lf"
      if [ ! -f "$lsrc" ] && [ ! -d "$lsrc" ]; then
        echo "  WARN: .local file missing: $lsrc"
      fi
      i=$((i+1))
    done
  fi

  [ $errors -gt 0 ] && { echo "FAIL: $errors error(s)"; return 1; }
  echo "PASS"
  return 0
}

kits_check() {
  local m="$1" found=0
  [ -n "$m" ] || { echo "ERROR: module name required"; return 1; }
  local dr=$(kit_data_root "$m")
  local cr=$(kit_conf_root "$m")
  echo "Check: $m"
  if ! kits_installed "$m"; then
    echo "  WARN: not in G41_KITS — module not installed"
  fi

  # backend artifacts
  case "$(backend_get)" in
    k8s)
      [ -d "kits/$m/k8s" ] && [ -n "$(ls kits/$m/k8s/*.yaml 2>/dev/null)" ] && { echo "  [k8s] manifests: kits/$m/k8s/"; found=$((found+1)); }
      if command -v kubectl >/dev/null 2>&1 && kubectl get deploy -n g41 "$m" >/dev/null 2>&1; then
        echo "  [k8s] deployment $m"; found=$((found+1))
      fi
      ;;
    *)
      if grep -q "kits/$m/compose.yaml" compose.yaml 2>/dev/null; then
        echo "  [compose] compose.yaml include"
        found=$((found+1))
      fi
      ;;
  esac

  # discover installed files by type from dependency provides
  local type_list=$(kit_type_list "$m")
  for type in $type_list; do
    case "$type" in
      tile|app|link)
        local ext=$(kit_provides_ext "$type" "$m")
        [ -f "${dr}/$(kit_provides_dir "$type")/$m.$ext" ] && { echo "  [$type] ${dr}/$(kit_provides_dir "$type")/$m.$ext"; found=$((found+1)); }
        ;;
      i18n)
        [ -d "${dr}/$(kit_provides_dir "i18n")/$m" ] && { echo "  [i18n] ${dr}/$(kit_provides_dir "i18n")/$m/"; found=$((found+1)); }
        ;;
      blc_template)
        local tdir="$(kit_provides_dir "blc_template")/$m"
        [ -d "$tdir" ] && { echo "  [blc_template] $tdir/"; found=$((found+1)); }
        ;;
    esac
  done

  # site configs
  if [ -d "kits/$m/site" ]; then
  local sext=$(kit_site_ext "$m")
  for sub in $(kit_site_subs "$m"); do
    local count=0
    [ -n "$sext" ] || continue
    for cf in $cr/$sub/*-$m.$sext; do
      [ -f "$cf" ] || continue
      count=$((count+1)) && found=$((found+1))
    done
    [ $count -gt 0 ] && echo "  [site:$sub] $count file(s) (*-$m.$sext)"
  done
  fi

  # webroot
  if [ -f "kits/$m/info.json" ]; then
    local target=$(jq -r '.webroot.target // ""' "kits/$m/info.json" 2>/dev/null)
    if [ -n "$target" ]; then
      local base=$(kit_provides_dir "webroot" "$m" 2>/dev/null)
      [ -d "$base/$target" ] && { echo "  [webroot] $base/$target/"; found=$((found+1)); }
    fi
  fi

  # persist (runtime state, not module-owned)
  local pd=$(kit_persist_dir "$m")
  if [ -n "$pd" ]; then
    [ -d "$pd" ] && { echo "  [persist] $pd/ (present)"; found=$((found+1)); }
    [ -d "kits/$m/$pd" ] && { echo "  [survive] survived in kits/$m/$pd/"; found=$((found+1)); }
  fi

  echo "Found: $found items"
  [ $found -gt 0 ] || { echo "  (no installed artifacts found)"; return 1; }
  return 0
}

kits_confirm() {
  local skip="$1" msg="$2"
  [ "$skip" = "-y" ] && return 0
  echo -n "$msg (y/N) "; read r
  [ "$r" = "y" ] || [ "$r" = "Y" ]
}

kits_installed() {
  local current=$(grep "^G41_KITS=" .env 2>/dev/null | sed 's/^G41_KITS="//;s/"$//')
  echo "$current" | tr ' ' '\n' | grep -qx "$1"
}
kits_installed_list() {
  grep "^G41_KITS=" .env 2>/dev/null | sed 's/^G41_KITS="//;s/"$//' | tr ' ' '\n' | grep -v "^$"
}



kits_mark() {
  local m="$1" act="$2" tmp=$(mktemp)
  local current=$(grep "^G41_KITS=" .env 2>/dev/null | sed 's/^G41_KITS="//;s/"$//')
  [ "$act" = "add" ] && { echo "$current" | grep -qw "$m" || current="$current $m"; }
  [ "$act" = "del" ] && current=$(echo "$current" | tr ' ' '\n' | grep -vx "$m" | tr '\n' ' ')
  current=$(echo "$current" | xargs)
  sed "/^G41_KITS=/d" .env > "$tmp"
  [ -n "$current" ] && echo "G41_KITS=\"$current\"" >> "$tmp"
  mv "$tmp" .env
}

# ==== Backend (compose | k8s) ====
backend_get() {
  local v=$(grep "^G41_BACKEND=" .env 2>/dev/null | sed 's/^G41_BACKEND=//;s/"//g' | tr -d '\r\n')
  [ -n "$v" ] && { echo "$v"; return 0; }
  echo "compose"
}
backend_set() {
  local v="$1" tmp=$(mktemp)
  case "$v" in compose|k8s) ;; *) echo "ERROR: backend must be 'compose' or 'k8s'"; return 1;; esac
  sed "/^G41_BACKEND=/d" .env > "$tmp"
  echo "G41_BACKEND=$v" >> "$tmp"
  mv "$tmp" .env
  echo "Backend: $v"
}

# Regenerate compose.yaml include block from installed state.
# Replaces fragile sed line-editing: idempotent, order-preserving,
# and keeps entries that exist in include but not in G41_KITS.
# op: add <m> | del <m> — reflects the pending G41_KITS change (before kits_mark).
compose_include_regenerate() {
  local op="$1" m="$2" tmp=$(mktemp)
  local existing=$(awk '/^include:/{f=1;next} f && /^  - /{sub(/^  - /,"");sub(/[[:space:]]*$/,"");print; next} f && /^[^[:space:]]/{exit}' compose.yaml)
  local paths="" m2
  for m2 in $(kits_installed_list); do
    [ -f "kits/$m2/compose.yaml" ] && paths="$paths\nkits/$m2/compose.yaml"
  done
  # union: file entries ∪ G41_KITS entries (preserves entries not tracked in G41_KITS)
  local union=$(printf '%s\n%s' "$existing" "$(printf '%b' "$paths")" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | awk '!seen[$0]++')
  case "$op" in
    add) printf '%s' "$union" | grep -qx "kits/$m/compose.yaml" || union=$(printf '%s\nkits/%s/compose.yaml' "$union" "$m");;
    del) union=$(printf '%s' "$union" | grep -vx "kits/$m/compose.yaml");;
    *) echo "ERROR: compose_include_regenerate: op must be add|del"; return 1;;
  esac
  local rendered=""
  while IFS= read -r e; do
    [ -f "$e" ] || continue
    rendered="$rendered  - $e\n"
  done <<< "$union"
  [ -z "$rendered" ] && rendered="  # (no container modules installed)\n"
  awk -v r="$rendered" '
    /^include:/ { print; printf "%s", r; f=1; next }
    f && /^  - / { next }
    f && /^[^[:space:]]/ { f=0 }
    { print }
  ' compose.yaml > "$tmp"
  mv "$tmp" compose.yaml
  echo "  [compose] include regenerated"
}

# ==== k8s backend helpers ====
G41K8S_ROOT="/opt/g41"

k8s_ready() {
  command -v kubectl >/dev/null 2>&1 || { echo "ERROR: kubectl not found — install k3s first"; return 1; }
  kubectl cluster-info >/dev/null 2>&1 || { echo "ERROR: k3s API unreachable — is k3s running?"; return 1; }
  return 0
}

k8s_link_root() {
  # stable absolute path for hostPath volumes, independent of the checkout location
  if [ "$(readlink -f "$G41K8S_ROOT" 2>/dev/null)" != "$(pwd)" ]; then
    ln -sfn "$(pwd)" "$G41K8S_ROOT"
    echo "  [k8s] $G41K8S_ROOT -> $(pwd)"
  fi
}

k8s_apply_base() {
  # 前置校验：REDIS_PASSWORD 缺失会导致**静默半失效**（k8s secretKeyRef 缺键时
  # 注入空串，redis 以 --requirepass "" 启动、api 无法认证 → /data/* 502 而 pod
  # 仍显示 Running）。曾在实机踩到：.env 少该键，重启 redis 后数据端点全 502。
  # RELOAD_SECRET 不在此列 —— 它只影响热重载端点，且已有独立报错（见 kits reload）。
  if ! grep -q "^REDIS_PASSWORD=..*" .env 2>/dev/null; then
    echo "ERROR: .env 缺少 REDIS_PASSWORD" >&2
    echo "       该键缺失会让 redis/api 静默半失效（502 而非报错）。" >&2
    echo "       请在 .env 中补上（参见 .env.example）：" >&2
    echo "         REDIS_PASSWORD=\$(openssl rand -hex 24)" >&2
    return 1
  fi

  # secret: whole .env as g41-env (declarative, idempotent, self-updating)
  #   - namespace g41: workloads (redis/api/nginx/hy2/…)
  #   - namespace cert-manager: ClusterIssuer 的 apiKeySecretRef 要求 Secret
  #     与 cert-manager 部署同命名空间
  kubectl create secret generic g41-env --from-env-file=.env \
    --namespace g41 --dry-run=client -o yaml | kubectl apply --validate=false -f -
  kubectl get ns cert-manager >/dev/null 2>&1 && \
    kubectl create secret generic g41-env --from-env-file=.env \
    --namespace cert-manager --dry-run=client -o yaml | kubectl apply --validate=false -f -
  # ClusterIssuer + Certificate rendered from .env (domains are deployment-specific)
  local dns="" d
  source .env 2>/dev/null
  dns="    - \"$G41_DOMAIN\"\n    - \"*.$G41_DOMAIN\""
  for d in $G41_EXTRA_DOMAINS; do
    [ -n "$d" ] && dns="$dns\n    - \"$d\""
  done
  if kubectl get pods -n cert-manager -l app.kubernetes.io/name=webhook --no-headers 2>/dev/null | grep -q Running; then
    printf 'apiVersion: cert-manager.io/v1\nkind: ClusterIssuer\nmetadata:\n  name: g41-issuer\nspec:\n  acme:\n    server: https://acme-v02.api.letsencrypt.org/directory\n    email: %s\n    privateKeySecretRef:\n      name: g41-issuer-key\n    solvers:\n    - dns01:\n        cloudflare:\n          email: %s\n          apiKeySecretRef:\n            name: g41-env\n            key: CF_Key\n        cnameStrategy: Follow\n' "$ACME_EMAIL" "$CF_Email" | kubectl apply --validate=false -f -
    printf 'apiVersion: cert-manager.io/v1\nkind: Certificate\nmetadata:\n  name: g41-tls\n  namespace: g41\nspec:\n  secretName: g41-tls\n  issuerRef:\n    name: g41-issuer\n    kind: ClusterIssuer\n  dnsNames:\n%b' "$dns" | kubectl apply --validate=false -f -
  else
    echo "  [k8s] cert-manager 未运行（续期窗口模式），跳过 issuer/certificate 应用"
  fi
}

k8s_build() {
  local m="$1"
  local mode=$(jq -r '.compose // "none"' "kits/$m/info.json" 2>/dev/null)
  [ "$mode" = "file" ] || return 0
  local tag="g41k8s/$m:local"

  # 优先走 containerd 原生路径（nerdctl + BuildKit 的 containerd worker）。
  # k8s 模式下 dockerd 通常是停用的，老的 docker build + save/import 无法运行；
  # 该路径直接构建进 k3s 的 k8s.io namespace，省去 save/import 两步。
  if command -v /opt/g41/k8s/host/g41-image-build.sh >/dev/null 2>&1; then
    /opt/g41/k8s/host/g41-image-build.sh "$m" || { echo "ERROR: containerd 构建失败 for $m"; return 1; }
    return 0
  fi
  if command -v nerdctl >/dev/null 2>&1 && systemctl is-active --quiet buildkitd.service 2>/dev/null; then
    echo "  [k8s] build $tag via nerdctl+BuildKit (containerd)"
    local ctx="." dfrel="kits/$m/Dockerfile"
    # COPY 路径不含 kits/ 前缀时，构建上下文为 kit 目录本身
    grep -qE '^(COPY|ADD)[[:space:]]+[^[:space:]]*kits/' "kits/$m/Dockerfile" 2>/dev/null \
      || { ctx="kits/$m"; dfrel="Dockerfile"; }
    ( cd "$ctx" && nerdctl --address /run/k3s/containerd/containerd.sock --namespace k8s.io \
        build --buildkit-host unix:///run/buildkit/buildkitd.sock \
        -f "$dfrel" -t "$tag" . ) || { echo "ERROR: nerdctl build failed for $m"; return 1; }
    return 0
  fi

  # 回退：传统 docker 路径（需 dockerd 运行）
  echo "  [k8s] build $tag (kits/$m/Dockerfile) via docker"
  docker build -q -f "kits/$m/Dockerfile" -t "$tag" . || { echo "ERROR: docker build failed for $m"; return 1; }
  docker save "$tag" | k3s ctr images import - || { echo "ERROR: image import failed for $m"; return 1; }
}

k8s_apply_module() {
  k8s_ready || return 1
  k8s_link_root
  local f
  [ -d "k8s/base" ] && for f in k8s/base/*.yaml; do [ -f "$f" ] && kubectl apply --validate=false -f "$f"; done
  k8s_apply_base
  for f in "kits/$1/k8s"/*.yaml; do
    [ -f "$f" ] && kubectl apply --validate=false -f "$f"
  done
  k8s_nginx_conf_apply
}

k8s_apply() {
  k8s_ready || return 1
  k8s_link_root
  local f m dir
  [ -d "k8s/base" ] && for f in k8s/base/*.yaml; do [ -f "$f" ] && kubectl apply --validate=false -f "$f"; done
  k8s_apply_base
  if [ "$1" = "--all" ]; then
    for m in kits/*/; do
      dir="${m%/}/k8s"
      [ -d "$dir" ] && for f in "$dir"/*.yaml; do [ -f "$f" ] && kubectl apply --validate=false -f "$f"; done
    done
  else
    for m in $(kits_installed_list); do
      dir="kits/$m/k8s"
      [ -d "$dir" ] && for f in "$dir"/*.yaml; do [ -f "$f" ] && kubectl apply --validate=false -f "$f"; done
    done
  fi
  k8s_nginx_conf_apply
  echo "k8s apply done."
}

k8s_stage() {
  # 分阶段部署（1GB 机防 Pod 启动风暴）：
  # 应用全部 manifest → 全部缩 0 → 按依赖顺序逐个拉起并等待 Ready
  k8s_ready || return 1
  k8s_link_root
  local f m dir
  [ -d "k8s/base" ] && for f in k8s/base/*.yaml; do [ -f "$f" ] && kubectl apply --validate=false -f "$f"; done
  k8s_apply_base
  for m in kits/*/; do
    dir="${m%/}/k8s"
    [ -d "$dir" ] && for f in "$dir"/*.yaml; do [ -f "$f" ] && kubectl apply --validate=false -f "$f"; done
  done
  k8s_nginx_conf_apply
  kubectl scale deployment -n g41 --replicas=0 --all 2>/dev/null
  local order="redis nginx dns download hako blc hy2"
  for m in $order; do
    echo "  [stage] scale up $m"
    kubectl scale deployment -n g41 "$m" --replicas=1 2>/dev/null
    local tries=0 ready=""
    while [ $tries -lt 36 ]; do
      ready=$(kubectl get deploy -n g41 "$m" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
      [ "$ready" = "1" ] && break
      sleep 10; tries=$((tries+1))
    done
    [ "$ready" = "1" ] && echo "  [stage] $m ready" || echo "  [stage] $m 未就绪（继续下一个）"
  done
  echo "stage done."
}

k8s_nginx_conf_apply() {
  # 将 g41.sh 装配进 .gx 的 nginx 配置渲染为 ConfigMap 并应用
  # （nginx-main: nginx.conf+mime.types；conf.d 下 4 个固定子目录各一个 ConfigMap）
  # （nginx-main: nginx.conf+mime.types；conf.d 下 4 个固定子目录各一个 ConfigMap）
  # delete+apply 确保移除的 site 片段不会残留在 ConfigMap 中
  [ -d .gx ] || { echo "  [k8s] nginx conf: .gx 未装配，跳过"; return 0; }
  [ -f .gx/nginx.conf ] || { echo "  [k8s] nginx conf: .gx/nginx.conf 缺失，跳过"; return 0; }
  kubectl delete configmap nginx-main --ignore-not-found >/dev/null 2>&1
  kubectl create configmap nginx-main --namespace g41 --from-file=nginx.conf=.gx/nginx.conf --from-file=mime.types=.gx/mime.types \
    --dry-run=client -o yaml | kubectl apply --validate=false -f -
  local sub n
  for sub in zones upstreams servers locations; do
    local dir=".gx/conf.d/$sub"
    [ -d "$dir" ] || continue
    n=$(ls "$dir" 2>/dev/null | wc -l)
    [ "$n" -gt 0 ] || continue
    kubectl delete configmap "nginx-conf-$sub" --ignore-not-found >/dev/null 2>&1
    kubectl create configmap "nginx-conf-$sub" --namespace g41 --from-file="$dir" \
      --dry-run=client -o yaml | kubectl apply --validate=false -f -
  done
  echo "  [k8s] nginx conf ConfigMaps applied"
}

k8s_apply_base_only() {
  k8s_ready || return 1
  k8s_link_root
  local f
  [ -d "k8s/base" ] && for f in k8s/base/*.yaml; do [ -f "$f" ] && kubectl apply --validate=false -f "$f"; done
  k8s_apply_base
  echo "k8s base applied."
}

k8s_status() {
  k8s_ready || return 1
  kubectl get -n g41 pods,svc,deploy 2>/dev/null
}

# ==== Resolver Helpers (recursive — walk full dependency tree) ====
kit_resolve() {
  local accept="$1" filter="$2" mod="$3" seen="${4:-}" core="$(kit_core)"
  case " $seen " in *" $mod "*) return 1;; esac
  seen="$seen $mod"
  local dep r
  for dep in $(jq -r '.depends[]?' "kits/$mod/info.json" 2>/dev/null) "$mod"; do
    [ "$dep" = "$core" ] && continue
    r=$(jq -r ".provides[] | select(.accepts[]? == \"$accept\") | $filter" "kits/$dep/info.json" 2>/dev/null | head -1)
    [ -n "$r" ] && [ "$r" != "null" ] && { echo "$r"; return 0; }
  done
  for dep in $(jq -r '.depends[]?' "kits/$mod/info.json" 2>/dev/null); do
    [ "$dep" = "$core" ] && continue
    kit_resolve "$accept" "$filter" "$dep" "$seen" && return 0
  done
  return 1
}

kit_resolve_multi() {
  local accept="$1" filter="$2" mod="$3" seen="${4:-}" core="$(kit_core)"
  case " $seen " in *" $mod "*) return 1;; esac
  seen="$seen $mod"
  local dep r
  for dep in $(jq -r '.depends[]?' "kits/$mod/info.json" 2>/dev/null) "$mod"; do
    [ "$dep" = "$core" ] && continue
    r=$(jq -r ".provides[] | select(.accepts[]? == \"$accept\") | $filter" "kits/$dep/info.json" 2>/dev/null)
    [ -n "$r" ] && [ "$r" != "null" ] && { echo "$r"; return 0; }
  done
  for dep in $(jq -r '.depends[]?' "kits/$mod/info.json" 2>/dev/null); do
    [ "$dep" = "$core" ] && continue
    kit_resolve_multi "$accept" "$filter" "$dep" "$seen" && return 0
  done
  return 1
}

kit_persist_dir() {
  jq -r '.persist | if type=="object" then .dir else . end' "kits/$1/info.json" 2>/dev/null | tr -d '\r\n'
}
kit_persist_survive() {
  jq -r '.persist.survive // false' "kits/$1/info.json" 2>/dev/null | tr -d '\r\n'
}
kit_provides_dir() {
  local accept="$1" mod="${2:-$m}" r
  r=$(kit_resolve "$accept" ".dir" "$mod" 2>/dev/null)
  [ -n "$r" ] && [ "$r" != "null" ] || { echo "FATAL: provides '$accept' missing dir field" >&2; exit 1; }
  echo "$r"
}
kit_provides_file() {
  local accept="$1" mod="${2:-$m}" r
  r=$(kit_resolve "$accept" ".file" "$mod" 2>/dev/null)
  [ -n "$r" ] && [ "$r" != "null" ] || { echo "FATAL: provides '$accept' missing file field" >&2; exit 1; }
  echo "$r"
}
kit_provides_ext() {
  local accept="$1" mod="${2:-$m}"
  kit_resolve "$accept" ".ext // \"json\"" "$mod" 2>/dev/null || echo "json"
}
kit_data_root()  { kit_resolve "data" ".dir" "$1"; }
kit_conf_root()  { kit_resolve "site" ".dir" "$1"; }

kit_site_files() {
  local mod="$1" r
  r=$(kit_resolve_multi "site" ".layout.files[]?" "$mod" 2>/dev/null | tr '\n' ' ')
  [ -n "$r" ] && { echo "$r"; return 0; }
  return 1
}
kit_site_sub() {
  local s="$1" mod="${2:-$m}" r
  r=$(kit_resolve "site" ".layout[\"$s\"]" "$mod" 2>/dev/null)
  [ -n "$r" ] && [ "$r" != "null" ] && { echo "$r"; return 0; }
  return 1
}
kit_site_subs() {
  local mod="$1"
  for f in $(kit_site_files "$mod"); do
    kit_site_sub "$f" "$mod"
  done
}
kit_type_list() {
  local mod="$1"
  {
    jq -r '.depends[]?' "kits/$mod/info.json" 2>/dev/null | while read dep; do
      [ "$dep" = "$(kit_core)" ] && continue
      [ ! -f "kits/$dep/info.json" ] && continue
      jq -r '.provides[]?.accepts[]?' "kits/$dep/info.json" 2>/dev/null
    done
    jq -r '.provides[]?.accepts[]?' "kits/$mod/info.json" 2>/dev/null
  } | sort -u
}
kit_core() {
  local v=$(grep "^G41_CORE=" .env 2>/dev/null | sed 's/^G41_CORE=//;s/"//g' | tr -d '\r\n')
  [ -n "$v" ] || { echo "FATAL: G41_CORE not set in .env" >&2; exit 1; }
  echo "$v"
}
kit_default_prefix() {
  local v=$(grep "^G41_PREFIX=" .env 2>/dev/null | sed 's/^G41_PREFIX=//;s/"//g' | tr -d '\r\n')
  [ -n "$v" ] || { echo "FATAL: G41_PREFIX not set in .env" >&2; exit 1; }
  echo "$v"
}
kit_site_ext() {
  local mod="$1" r
  r=$(kit_resolve "site" ".layout.ext" "$mod" 2>/dev/null)
  [ -n "$r" ] && [ "$r" != "null" ] && { echo "$r"; return 0; }
  return 1
}
kit_provides_ext() {
  local accept="$1" mod="${2:-$m}" r
  r=$(kit_resolve "$accept" ".ext" "$mod" 2>/dev/null)
  [ -n "$r" ] && [ "$r" != "null" ] || { echo "FATAL: provides '$accept' missing ext field" >&2; exit 1; }
  echo "$r"
}

kits_add() {
  local m="" skip="" dry="" core=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -y) skip="-y";;
      -C|--core) core="1";;
      --dry-run) dry="1";;
      *) m="$1";;
    esac
    shift
  done
  [ -z "$m" ] && { echo "ERROR: module name required"; return 1; }

  # virtual module "all" — install all kits
  if [ "$m" = "all" ]; then
    local count=0
    for d in kits/*/; do
      local mname=$(basename "$d")
      [ ! -f "$d/info.json" ] && continue
      kits_add "$skip" ${dry:+--dry-run} ${core:+-C} "$mname" && count=$((count+1))
    done
    echo "All: $count module(s) installed"
    return 0
  fi

  [ -z "$core" ] && kits_installed "$m" && { echo "Module '$m' already installed. Use -C to force reinstall."; return 0; }
  kits_verify "$m" || return 1
  local dr=$(kit_data_root "$m")
  local cr=$(kit_conf_root "$m")
  # Auto-install missing dependencies
  if [ -f "kits/$m/info.json" ]; then
    local deps=$(jq -r '.depends[]?' "kits/$m/info.json" 2>/dev/null)
    for dep in $deps; do
      [ "$dep" = "$(kit_core)" ] && continue
      if ! kits_installed "$dep"; then
        echo "  -> auto-installing dependency: $dep"
        kits_add "$skip" ${dry:+--dry-run} "$dep" || { echo "ERROR: failed to install dependency '$dep'"; return 1; }
      fi
    done
  fi
  kits_confirm "$skip" "Install module '$m'?" || { echo "Cancelled."; return 0; }

  # Backend: compose include (regenerated) — k8s handled after content assembly
  if [ "$(backend_get)" = "compose" ] && [ -f "kits/$m/compose.yaml" ]; then
    if [ -n "$dry" ]; then
      echo "  [dry] compose include"
    else
      compose_include_regenerate add "$m"
    fi
  fi

  # ==== Helpers ====
  kit_ln() {
    local src="$1" dst="$2"
    [ -n "$dry" ] && { echo "  [dry] $dst"; return 0; }
    mkdir -p "$(dirname "$dst")" 2>/dev/null
    rm -f "$dst" 2>/dev/null
    ln -f "$src" "$dst" 2>/dev/null
  }
  kit_log() { [ -n "$dry" ] && echo "  [dry] $*" || echo "  + $*"; }

  # ==== Install ====
  # type-driven install from dependency provides
  local type_list=$(kit_type_list "$m")

  for type in $type_list; do
    local pdir=$(kit_provides_dir "$type")
    [ -z "$pdir" ] && continue
    local fname=$(kit_provides_file "$type")
    local src="kits/$m/$fname"
    case "$type" in
      tile|app|link)
        [ -f "$src" ] || continue
        mkdir -p "${dr}/$pdir" 2>/dev/null
        kit_ln "$src" "${dr}/$pdir/$m.$(kit_provides_ext "$type" "$m")" && kit_log "$type"
        ;;
      i18n)
        [ -d "$src" ] || continue
        local tdir="${dr}/$pdir/$m"
        [ -d "$tdir" ] && rm -rf "$tdir"
        [ -z "$dry" ] && mkdir -p "$tdir"
        local ext=$(kit_provides_ext "i18n" "$m")
        for f in "$src"/*.$ext; do
          [ -f "$f" ] && [ -z "$dry" ] && ln -f "$f" "$tdir/$(basename $f)" 2>/dev/null
        done
        [ -n "$dry" ] && echo "  [dry] i18n"
        [ -z "$dry" ] && kit_log "i18n"
        ;;
      site)
        [ -d "$src" ] || continue
        local prefix=$(jq -r ".provides[] | select(.dir == \"$cr\") | .prefix // \"$(kit_default_prefix)\"" "kits/$m/info.json" 2>/dev/null | tr -d '\r\n ' | head -1)
        [ -z "$prefix" ] && prefix=$(kit_default_prefix)
        local ext=$(kit_site_ext "$m")
        for sf in $(kit_site_files "$m"); do
          local sconf="$src/$sf.$ext"
          [ ! -f "$sconf" ] && continue
          local sub=$(kit_site_sub "$sf")
          local tdir="$pdir/$sub"
          mkdir -p "$tdir" 2>/dev/null
          local dst="$tdir/$(printf "%03d" "${prefix##0}")-$m.$ext"
          rm -f "$tdir/$m.$ext" 2>/dev/null
          kit_ln "$sconf" "$dst" && kit_log "$sub"
        done
        ;;
      blc_template)
        [ -d "$src" ] || continue
        local tdir="$pdir/$m"
        [ -d "$tdir" ] && rm -rf "$tdir"
        [ -z "$dry" ] && mkdir -p "$tdir"
        for f in "$src"/*; do
          [ -f "$f" ] || continue
          kit_ln "$f" "$tdir/$(basename "$f")"
        done
        [ -n "$dry" ] && echo "  [dry] blc_template"
        [ -z "$dry" ] && kit_log "blc_template"
        ;;
    esac
  done

  # .local site files (private deployer configs, gitignored)
  if [ -d "kits/$m/.local/site" ]; then
    local cr=$(kit_conf_root "$m")
    local sext=$(kit_site_ext "$m")
    [ -z "$sext" ] && sext="conf"
    local prefix=$(jq -r ".provides[] | select(.dir == \"$cr\") | .prefix // \"$(kit_default_prefix)\"" "kits/$m/info.json" 2>/dev/null | tr -d '\r\n ' | head -1)
    [ -z "$prefix" ] && prefix=$(kit_default_prefix)
    for sf in $(kit_site_files "$m"); do
      local sconf="kits/$m/.local/site/$sf.$sext"
      [ ! -f "$sconf" ] && continue
      local sub=$(kit_site_sub "$sf")
      local tdir="$cr/$sub"
      mkdir -p "$tdir" 2>/dev/null
      local dst="$tdir/$(printf "%03d" "${prefix##0}")-$m.$sext"
      kit_ln "$sconf" "$dst" && kit_log "local-site $sf"
    done
  fi

  # store directory
  if jq -e '.store' "kits/$m/info.json" >/dev/null 2>&1; then
    local sd=$(jq -r '.store.dir' "kits/$m/info.json")
    local store_path="kits/$m/store"
    if [ -d "$store_path" ]; then
      for f in $(ls "$store_path" 2>/dev/null); do
        local src="$store_path/$f"
        if [ -d "$src" ]; then
          local subs=$(jq -r ".store.items.\"$f\".subs[]?" "kits/$m/info.json" 2>/dev/null)
          [ -z "$dry" ] && mkdir -p "$sd/$f"
          for s in $subs; do [ -z "$dry" ] && mkdir -p "$sd/$f/$s"; done
          kit_log "mkdir $f"
        elif [ -f "$src" ]; then
          kit_ln "$src" "$sd/$f" && kit_log "store $f"
        fi
      done
    fi
  fi

  # data directory (static — provides without accepts)
  if [ -d "kits/$m/data" ]; then
    local static_dirs=$(jq -r '.provides[] | select(.accepts == null and .dir != "i18n") | .dir' "kits/$m/info.json" 2>/dev/null | tr -d '\r')
    for dd in $static_dirs; do
      [ -z "$dd" ] && continue
      local tdir="${dr}/$dd"
      mkdir -p "$tdir" 2>/dev/null
      for f in kits/$m/data/*; do
        [ ! -f "$f" ] && continue
        kit_ln "$f" "$tdir/$(basename $f)" 2>/dev/null
      done
      kit_log "data"
    done
  fi

  # webroot
  if jq -e '.webroot.target' "kits/$m/info.json" >/dev/null 2>&1; then
    local method=$(jq -r '.webroot.method | values' "kits/$m/info.json" | tr -d '\r\n')
    local target=$(jq -r '.webroot.target | values' "kits/$m/info.json" | tr -d '\r\n')
    local base=$(kit_provides_dir "webroot" 2>/dev/null)
    local tdir="$base/$target"
    case $method in
      mkdir)
        [ -z "$dry" ] && mkdir -p "$tdir"
        for d in $(jq -r '.webroot.dirs[]?' "kits/$m/info.json" 2>/dev/null | tr -d '\r'); do
          [ -z "$d" ] && continue
          [ -z "$dry" ] && mkdir -p "$tdir/$d"
        done
        kit_log "webroot(dir)"
        ;;
      hardlink)
        [ ! -d "$tdir" ] && mkdir -p "$tdir"
        local files=$(jq -r '.webroot.files[]?' "kits/$m/info.json" 2>/dev/null | tr -d '\r')
        if [ -n "$files" ]; then
          for f in $files; do
            [ -z "$f" ] && continue
            local src="kits/$m/webroot/$f"
            [ ! -f "$src" ] && continue
            kit_ln "$src" "$tdir/$f" && kit_log "webroot($method) $f"
          done
        elif [ -d "kits/$m/webroot" ]; then
          for src in $(find kits/$m/webroot/ -type f 2>/dev/null); do
            local rel="${src#kits/$m/webroot/}"
            mkdir -p "$tdir/$(dirname "$rel")" 2>/dev/null
            kit_ln "$src" "$tdir/$rel" && kit_log "webroot($method) $rel"
          done
        fi
        ;;
    esac
  fi

  # .local webroot files (private deployer assets, gitignored)
  if [ -d "kits/$m/.local/webroot" ]; then
    local base=$(kit_provides_dir "webroot" 2>/dev/null)
    local target=$(jq -r '.webroot.target | values' "kits/$m/info.json" 2>/dev/null | tr -d '\r\n')
    if [ -n "$base" ] && [ -n "$target" ]; then
      local tdir="$base/$target"
      mkdir -p "$tdir" 2>/dev/null
      for src in $(find "kits/$m/.local/webroot" -type f 2>/dev/null); do
        local rel="${src#kits/$m/.local/webroot/}"
        mkdir -p "$tdir/$(dirname "$rel")" 2>/dev/null
        kit_ln "$src" "$tdir/$rel" && kit_log "local-webroot $rel"
      done
    fi
  fi

  # persist
  local pd=$(kit_persist_dir "$m")
  local ps=$(kit_persist_survive "$m")
  if [ "$ps" = "true" ] && [ -n "$pd" ]; then
    local bk="kits/$m/$pd"
    if [ -d "$bk" ]; then
      [ -z "$dry" ] && mv "$bk" "$pd" 2>/dev/null && kit_log "survive restore: $pd"
    fi
  fi
  if [ -n "$pd" ] && [ "$pd" != "null" ]; then
    [ -z "$dry" ] && mkdir -p "$pd"
    kit_log "persist $pd"
  fi

  # local files (from info.json)
  local item_count=$(jq '.local | length' "kits/$m/info.json" 2>/dev/null)
  if [ -n "$item_count" ] && [ "$item_count" -gt 0 ] 2>/dev/null; then
    local i=0
    while [ $i -lt $item_count ]; do
      local lf=$(jq -r ".local[$i].file" "kits/$m/info.json" 2>/dev/null)
      local lto=$(jq -r ".local[$i].to" "kits/$m/info.json" 2>/dev/null)
      local ldir=$(jq -r ".local[$i].dir // false" "kits/$m/info.json" 2>/dev/null)
      local lsrc="kits/$m/.local/$lf"
      local pd=$(kit_persist_dir "$m")
      [ -n "$pd" ] && [ "$pd" != "null" ] && lto="$pd/$lto"
      if [ ! -f "$lsrc" ] && [ ! -d "$lsrc" ]; then
        echo "  WARNING: local file missing: $lsrc"
      elif [ "$ldir" = "copy" ]; then
        if [ -z "$dry" ]; then
          cp -al "$lsrc" "$lto" 2>/dev/null && kit_log "local(copy) $lf"
        else
          echo "  [dry] local(copy) $lf"
        fi
      elif [ "$ldir" = "create" ]; then
        [ -z "$dry" ] && mkdir -p "$lto" && kit_log "local(create) $lf"
      else
        kit_ln "$lsrc" "$lto" && kit_log "local $lf"
      fi
      i=$((i+1))
    done
  fi

  # 记账只在真装时写：G41_KITS 是「已安装」状态的记录，dry-run 写进去之后
  # 就分不出「真装过」和「只是演练过」了（演练会污染 `kits check` 与 include 生成）。
  [ -z "$dry" ] && kits_mark "$m" "add"

  # k8s backend: build local images and apply manifests (after content assembly)
  if [ "$(backend_get)" = "k8s" ]; then
    if [ -n "$dry" ]; then
      echo "  [dry] k8s build + apply"
    else
      k8s_build "$m" || return 1
      [ -d "kits/$m/k8s" ] && k8s_apply_module "$m"
    fi
  fi

  echo "Module '$m' installed."
}

kits_del() {
  local m="" skip="" core=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -y) skip="-y";;
      -C|--core) core="1";;
      *) m="$1";;
    esac
    shift
  done
  [ -z "$m" ] && { echo "ERROR: module name required"; return 1; }

  # virtual module "all" — cascading uninstall all
  if [ "$m" = "all" ]; then
    local remaining=$(kits_installed_list | tr '\n' ' ')
    [ -z "$remaining" ] && { echo "No modules installed."; return 0; }
    while [ -n "$remaining" ]; do
      local leaf=""
      for mod in $remaining; do
        local needed=0
        for other in $remaining; do
          [ "$other" = "$mod" ] && continue
          jq -e ".depends | index(\"$mod\")" "kits/$other/info.json" >/dev/null 2>&1 && needed=1 && break
        done
        [ $needed -eq 0 ] && { leaf="$mod"; break; }
      done
      [ -z "$leaf" ] && { echo "ERROR: circular dependency detected in: $remaining"; return 1; }
      echo "  del $leaf (no dependents)"
      kits_del "$skip" ${core:+-C} "$leaf"
      remaining=$(kits_installed_list | tr '\n' ' ')
    done
    echo "All modules uninstalled."
    return 0
  fi

  kits_installed "$m" || { echo "Module '$m' not installed."; return 0; }
  local dr=$(kit_data_root "$m")
  local cr=$(kit_conf_root "$m")
  # Block core-dependent modules from uninstall (bypassable with -C)
  if [ -z "$core" ] && [ -f "kits/$m/info.json" ]; then
    local core_name=$(kit_core)
    jq -e ".depends | index(\"$core_name\")" "kits/$m/info.json" >/dev/null 2>&1 && { echo "ERROR: '$m' depends on $core_name — cannot uninstall. Use -C to force."; return 1; }
  fi
  kits_confirm "$skip" "Uninstall module '$m'?" || { echo "Cancelled."; return 0; }
  local removed=0

  # Backend: compose include (regenerated) / k8s manifests
  if [ "$(backend_get)" = "compose" ]; then
    if grep -q "kits/$m/compose.yaml" compose.yaml 2>/dev/null; then
      compose_include_regenerate del "$m"
      echo "  - compose include"; removed=$((removed+1))
    fi
  elif [ -d "kits/$m/k8s" ]; then
    if command -v kubectl >/dev/null 2>&1; then
      local f
      for f in "kits/$m/k8s"/*.yaml; do
        [ -f "$f" ] && kubectl delete -f "$f" --ignore-not-found=true
      done
      echo "  - k8s manifests"; removed=$((removed+1))
    else
      echo "  WARN: kubectl not found — skip k8s manifest removal"
    fi
  fi

  # discover and remove installed files by type
  local type_list=$(kit_type_list "$m")
  for type in $type_list; do
    case "$type" in
      tile|app|link)
        local ext=$(kit_provides_ext "$type" "$m")
        local tp="$(kit_provides_dir "$type")/$m.$ext"
        [ -f "${dr}/$tp" ] && { rm -f "${dr}/$tp"; echo "  - $type"; removed=$((removed+1)); }
        ;;
      i18n)
        [ -d "${dr}/$(kit_provides_dir "i18n")/$m" ] && { rm -rf "${dr}/$(kit_provides_dir "i18n")/$m"; echo "  - i18n"; removed=$((removed+1)); }
        ;;
      blc_template)
        local tp="$(kit_provides_dir "blc_template")/$m"
        [ -d "$tp" ] && { rm -rf "$tp"; echo "  - blc_template"; removed=$((removed+1)); }
        ;;
    esac
  done

  # site configs — discover all prefixed files
  if [ -d "kits/$m/site" ]; then
  local sext=$(kit_site_ext "$m")
  for sub in $(kit_site_subs "$m"); do
    local scount=0
    [ -n "$sext" ] || continue
    for cf in $cr/$sub/*-$m.$sext; do
      [ -f "$cf" ] || continue
      rm -f "$cf" && scount=$((scount+1)) && removed=$((removed+1))
    done
    [ $scount -gt 0 ] && echo "  - site:$sub ($scount file(s))"
  done
  fi

  # webroot
  if [ -f "kits/$m/info.json" ]; then
    local target=$(jq -r '.webroot.target // ""' "kits/$m/info.json" 2>/dev/null)
    if [ -n "$target" ]; then
      local base=$(kit_provides_dir "webroot" "$m" 2>/dev/null)
      [ -d "$base/$target" ] && { rm -rf "$base/$target"; echo "  - webroot: $base/$target"; removed=$((removed+1)); }
    fi
  fi

  # store directory
  if [ -f "kits/$m/info.json" ] && jq -e '.store' "kits/$m/info.json" >/dev/null 2>&1; then
    local sd=$(jq -r '.store.dir' "kits/$m/info.json" 2>/dev/null)
    local store_path="kits/$m/store"
    if [ -d "$store_path" ]; then
      for f in $(ls "$store_path" 2>/dev/null); do
        local src="$store_path/$f"
        if [ -d "$src" ]; then
          rmdir "$sd/$f" 2>/dev/null && { echo "  - store(dir): $f"; removed=$((removed+1)); }
        elif [ -f "$src" ]; then
          [ -f "$sd/$f" ] && rm -f "$sd/$f" && { echo "  - store: $f"; removed=$((removed+1)); }
        fi
      done
    fi
  fi
  local pd=$(kit_persist_dir "$m")
  if [ -n "$pd" ] && [ -d "$pd" ]; then
    local ps=$(kit_persist_survive "$m")
    if [ "$ps" = "true" ]; then
      mv "$pd" "kits/$m/" 2>/dev/null && echo "  - survive: $pd → kits/$m/"
    else
      rm -rf "$pd" 2>/dev/null && echo "  - purge: $pd"
    fi
    removed=$((removed+1))
  fi

  kits_mark "$m" "del"
  echo "Module '$m' uninstalled. ($removed items removed)"
}

kits_pack() {
  local add_local= add_store= add_agents= add_docs= name="G41KiTS"
  for a in "$@"; do
    case "$a" in
      -L|--local) add_local=1 ;;
      -S|--store) add_store=1 ;;
      -A|--agents) add_agents=1 ;;
      -D|--docs) add_docs=1 ;;
      -*)
        local s="${a#-}"
        for ((i=0; i<${#s}; i++)); do
          case "${s:$i:1}" in
            L) add_local=1 ;; S) add_store=1 ;; A) add_agents=1 ;; D) add_docs=1 ;;
          esac
        done
        ;;
    esac
  done
  local suffix=""
  [ -n "$add_agents" ] && suffix="${suffix}A"
  [ -n "$add_docs" ] && suffix="${suffix}D"
  [ -n "$add_local" ] && suffix="${suffix}L"
  [ -n "$add_store" ] && suffix="${suffix}S"
  [ -n "$suffix" ] && name="${name}_$suffix"

  local tmpdir=$(mktemp -d)
  cp -a . "$tmpdir/src"
  rm -f "$tmpdir/src"/G41KiTS*.tar.gz
  cd "$tmpdir/src"
  git init -q && git add -A

  # --docs: add documentation
  [ -n "$add_docs" ] && git add -f docs/ README.md 2>/dev/null

  # --agents: add docs excluded by .gitignore
  [ -n "$add_agents" ] && { git add -f AGENTS.md 2>/dev/null; [ -d skills ] && git add -f skills/ 2>/dev/null || true; }

  # --local: add deployment secrets and module-local files
  [ -n "$add_local" ] && { git add -f .env kits/*/.local/ 2>/dev/null; }

  # --store: discover and add all persistent directories
  if [ -n "$add_store" ]; then
    local persist_dirs=$(for f in kits/*/info.json; do
      jq -r '.persist | if type=="object" then .dir elif type=="string" then . else empty end' "$f" 2>/dev/null
      jq -r '.store.dir // empty' "$f" 2>/dev/null
    done | sort -u | grep -v '^$')
    persist_dirs="$persist_dirs .wr"
    for d in $persist_dirs; do
      [ -d "$d" ] && git add -f "$d" 2>/dev/null
    done
  fi

  local dst="$OLDPWD/$name.tar.gz"
  git ls-files -z | tar -czf "$dst" --null -T - --transform='s,^,G41KiTS/,' 
  cd "$OLDPWD"
  rm -rf "$tmpdir"
  ls -lh "$dst"
  echo "Pack: $dst"
}

kits_list() {
  local mods=() list_height
  for d in kits/*/; do [ -d "$d" ] && mods+=("$(basename "$d")"); done
  if [ ${#mods[@]} -eq 0 ]; then echo "No modules in kits/"; return; fi
  list_height=${#mods[@]}
  local i=0 sel=0 prev=-1

  _draw_screen() {
    printf '\e[2J\e[H'
    printf "=== Kits === (j/k:nav  a:add  d:del  q:quit)\n"
    for i in $(seq 0 $((list_height-1))); do
      local mark=" "; kits_installed "${mods[$i]}" && mark="*"
      [ $i -eq $sel ] && printf ' \e[7m [%s] %s \e[0m\n' "$mark" "${mods[$i]}" || printf '   [%s] %s\n' "$mark" "${mods[$i]}"
    done
    if [ -f "kits/${mods[$sel]}/info.json" ]; then
      printf '\e[2m---\e[0m\n'
      jq -r '"\(.desc)\nDepends: \(.depends | join(","))"' "kits/${mods[$sel]}/info.json" 2>/dev/null
      printf '\e[2m---\e[0m\n'
    fi
    prev=$sel
  }

  _redraw_footer() {
    local footer_start=$((list_height+3))
    printf '\e[s'
    printf '\e[%d;0H\e[J' $footer_start
    if [ -f "kits/${mods[$sel]}/info.json" ]; then
      printf '\e[2m---\e[0m\n'
      jq -r '"\(.desc)\nDepends: \(.depends | join(","))"' "kits/${mods[$sel]}/info.json" 2>/dev/null
      printf '\e[2m---\e[0m\n'
    fi
    printf '\e[u'
  }

  printf '\e[?25l'
  _draw_screen
  while true; do
    read -rsn1 key
    case "$key" in
      j|J) [ $sel -lt $((list_height-1)) ] && { sel=$((sel+1)); _redraw_footer; };;
      k|K) [ $sel -gt 0 ] && { sel=$((sel-1)); _redraw_footer; };;
      a|A) printf '\e[?25h'; kits_add "${mods[$sel]}"; read -rsn1 key < /dev/tty; printf '\e[?25l'; _draw_screen;;
      d|D) printf '\e[?25h'; kits_del "${mods[$sel]}"; read -rsn1 key < /dev/tty; printf '\e[?25l'; _draw_screen;;
      q|Q) break;;
    esac
  done
  printf '\e[?25h\n'
}

kits_reload() {
  local secret=""
  source .env 2>/dev/null
  secret="${RELOAD_SECRET:-}"
  if [ -z "$secret" ]; then
    echo "ERROR: RELOAD_SECRET not set in .env"
    echo "Generate one and add to .env: RELOAD_SECRET=<random_string>"
    return 1
  fi
  echo "Hot-reloading Redis data..."
  local node_script="
    var http=require('http');
    var data=JSON.stringify({secret:'$secret'});
    var req=http.request({hostname:'127.0.0.1',port:5800,path:'/admin/reload',method:'POST',headers:{'Content-Type':'application/json','Content-Length':data.length}},function(res){
      var body='';res.on('data',function(c){body+=c;});
      res.on('end',function(){console.log(body);process.exit(res.statusCode===200?0:1);});
    });
    req.on('error',function(e){console.error(e.message);process.exit(1);});
    req.write(data);req.end();
  "
  case "$(backend_get)" in
    k8s)
      k8s_ready >/dev/null 2>&1 || return 1
      # api 不是独立的 Deployment —— 它是 redis Deployment 的第二个容器
      # （kits/redis/k8s/deployment.yaml）。原先写 `deploy/api`，那条 exec 在本
      # 部署里永远失败，于是「零停机热重载」只能报一句指向错误方向的错。
      kubectl exec -n g41 deploy/redis -c api -- node -e "$node_script" 2>/dev/null || {
        echo "ERROR: Reload failed. Ensure the redis Deployment's api container is running."
        return 1
      }
      ;;
    *)
      docker compose exec -T api node -e "$node_script" 2>/dev/null || {
        # backend=compose 而机器上跑的是 k3s 时，上面的失败只会报「api container
        # is not running」——指向错误的方向。检测到 k3s 里真有 api 容器就改成
        # 报真正的诊断（.env 缺 G41_BACKEND=k8s 是已知的漂移形态）。
        if command -v kubectl >/dev/null 2>&1 && \
           kubectl get pods -n g41 -l app.kubernetes.io/name=api --no-headers 2>/dev/null | grep -q Running; then
          echo "ERROR: reload failed via compose, but a k3s 'api' container is Running."
          echo "       backend=$(backend_get) — switch with: ./g41.sh backend k8s"
        else
          echo "ERROR: Reload failed. Ensure api container is running."
        fi
        return 1
      }
      ;;
  esac
  echo
  echo "Reload complete. Tiles, i18n, and links refreshed."
}

# ==== 模块版本与远程分发（2026-11-07 加）====
#
# 为什么需要这两样东西一起加：
#   「远程安装」若没有版本，装出来是什么就取决于拿到的那一刻，事后无从对账；
#   「版本」若没有分发，只在本仓内部生效，外人还是用不上。
#   所以 kit_version 定身份，kits_export 产可远程取的对象，kits_remote 消费它。
#
# 三条不许省的语义：
#   1. 装到哪由清单自己说（namespace 在清单里），不由 URL 决定；
#   2. 取值失败 = 显式失败（退出 2「没能验到」），不许当成「装好了」；
#   3. 哈希默认只做事后对账，除非调用方给了 --sha256（那才是事前校验）。

kit_version() {
  local m="$1" v=""
  # set -e 在场：模块不存在时 jq 会非零退出并直接杀脚本，所以用 || true 接住，
  # 让它退回 "local" 而不是「什么都没输出就死了」。
  v=$(jq -r '.version // ""' "kits/$m/info.json" 2>/dev/null || true)
  [ -n "$v" ] && [ "$v" != "null" ] && { echo "$v"; return 0; }
  echo "local"
}

# Pod 组（2026-11-07 加）：一个 k8s Deployment 里可能塞着多个模块的容器。
# 1GB 机上「Pod 整合」是刻意决策（见 k8s/README.md），不能为了模块化把它拆开。
# 所以安装单位不是模块，是 Pod 组——拆开装只会得到没有后端的 Service。
kit_k8s_pod() {
  local m="$1" p=""
  p=$(jq -r '.k8s.pod // ""' "kits/$m/info.json" 2>/dev/null || true)
  [ -n "$p" ] && [ "$p" != "null" ] && { echo "$p"; return 0; }
  echo "$m"
}

kit_k8s_group() {
  local m="$1" pod d n
  pod=$(kit_k8s_pod "$m")
  for d in kits/*/; do
    n=$(basename "$d")
    [ -f "$d/info.json" ] || continue
    [ "$(kit_k8s_pod "$n")" = "$pod" ] && echo "$n"
  done
  # 必须显式 return 0：最后一次比较若为假，函数会以 1 退出，
  # 而调用方是 `group=$(…)` —— set -e 会把整个脚本杀掉且**一字不打印**。
  return 0
}

# ConfigMap 的 data 键 → 块标量。规则必须跟着原文件的末尾换行走：
#   无末尾换行 |-  /  恰好一个 |  /  两个以上 |+
# 多或少一个换行会让「逐字节还原」这条判据变成假的，而它看着照样绿。
cm_emit() {
  local key="$1" src="$2" ind="|" lb="" l2=""
  lb=$(tail -c 1 "$src" 2>/dev/null | od -An -tx1 | tr -d ' \n')
  if [ "$lb" != "0a" ]; then
    ind="|-"
  else
    l2=$(tail -c 2 "$src" 2>/dev/null | od -An -tx1 | tr -d ' \n')
    [ "${l2}" = "0a0a" ] && ind="|+"
  fi
  echo "  ${key}: $ind"
  sed 's/^/    /' "$src"
  [ "$ind" = "|-" ] && echo
  # 必须显式 return 0：最后那条 test 为假时函数返回 1，
  # 而调用方式是 `[ -f X ] && cm_emit …`——失败的正是 && 后那条命令，set -e 会当场退出且不打印。
  return 0
}

# 内容种子（2026-11-08）：tile / app / link / i18n / data 这类内容最终是喂给 Redis 的数据。
#
# **必须是聚合的一张**，不是每个模块一张。2026-11-08 实测：三个模块的包依次
# `kubectl apply` 之后，`/seed` 里只剩最后一个模块的键——ConfigMap 同名时 apply 会按
# last-applied 修剪掉别人加的键，**不是「按键合并、自然累积」**。我一开始写反了，
# 是那次实测推翻了它。所以改成：`kits content` 扫全部模块，生成一张完整的 g41-content。
# 代价：内容更新是「整体一次」，不按模块粒度。内容很小、loader 也总是全量读，
# 这个代价换「装 N 个模块得到 N 个模块的内容」是划算的。
kits_content() {
  local out="dist/g41-content.yaml"
  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--out) out="$2"; shift;;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) ;;
    esac
    shift
  done
  mkdir -p "$(dirname "$out")" 2>/dev/null
  local tmp="${out}.tmp.$$"; rm -f "$tmp"
  local n=0 m d cf total=0 sz

  # 先算体积：ConfigMap 上限 1MiB，超了在 apply 时才报，报错很难读。
  for d in kits/*/; do
    for cf in "$d"tile.json "$d"app.json "$d"link.json "$d"i18n/*.json "$d"data/*.json; do
      [ -f "$cf" ] || continue
      sz=$(wc -c < "$cf" | tr -d ' '); total=$((total + sz))
    done
  done
  if [ "$total" -gt 900000 ]; then
    echo "ERROR: 内容共 $total 字节，超过 ConfigMap 安全上限 900000 —— 该走镜像而不是 ConfigMap"
    return 1
  fi

  {
    echo "# G41KiTS content seed —— 由 \`kits content\` 生成，勿手改"
    echo "# generated: $(date -Is)"
    echo "---"
    echo "apiVersion: v1"
    echo "kind: ConfigMap"
    echo "metadata:"
    echo "  name: g41-content"
    echo "  namespace: g41"
    echo "  labels:"
    echo "    app.kubernetes.io/part-of: g41"
    echo "    g41.content: \"seed\""
    echo "data:"
    for d in kits/*/; do
      m=$(basename "$d")
      [ -f "$d/info.json" ] || continue
      [ -f "$d/tile.json" ] && { cm_emit "tile.$m.json" "$d/tile.json"; n=$((n+1)); }
      [ -f "$d/app.json" ]  && { cm_emit "app.$m.json"  "$d/app.json";  n=$((n+1)); }
      [ -f "$d/link.json" ] && { cm_emit "link.$m.json" "$d/link.json"; n=$((n+1)); }
      for cf in "$d"i18n/*.json; do
        [ -f "$cf" ] || continue
        cm_emit "i18n.$m.$(basename "${cf%.json}").json" "$cf"; n=$((n+1))
      done
      for cf in "$d"data/*.json; do
        [ -f "$cf" ] || continue
        cm_emit "data.$m.$(basename "${cf%.json}").json" "$cf"; n=$((n+1))
      done
    done
  } > "$tmp"

  if [ "$n" -le 0 ]; then
    echo "ERROR: 一个内容键都没生成 —— 没有可种的内容"; rm -f "$tmp"; return 1
  fi
  mv -f "$tmp" "$out"
  echo "内容种子: $out（$n 个键，$total 字节）"
}

# 生成 api 源码 ConfigMap（2026-11-09）。
#
# 为什么需要它：`server.js` 原先是宿主机单文件 /opt/g41/.rd/server.js，靠人手工 cp。
# 手工搬运意味着「改仓库 ≠ 改运行的那份」，而且实测过两者 inode 不同源——
# 改完仓库、重启、日志干净、站点正常，跑的却还是旧代码。
# 现在改成 ConfigMap 供给，由 CD 生成并 apply，仓库是唯一来源。
kits_api_src() {
  local out="dist/g41-api-src.yaml" src="kits/redis/store/server.js"
  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--out) out="$2"; shift;;
      *) ;;
    esac
    shift
  done
  [ -f "$src" ] || { echo "ERROR: $src 不存在"; return 1; }
  mkdir -p "$(dirname "$out")" 2>/dev/null
  local tmp="${out}.tmp.$$"; rm -f "$tmp"
  {
    echo "# G41KiTS api 源码 —— 由 \`kits api-src\` 生成，勿手改"
    echo "# generated: $(date -Is)"
    echo "---"
    echo "apiVersion: v1"
    echo "kind: ConfigMap"
    echo "metadata:"
    echo "  name: g41-api-src"
    echo "  namespace: g41"
    echo "  labels:"
    echo "    app.kubernetes.io/part-of: g41"
    echo "    g41.api-src: \"1\""
    echo "data:"
    cm_emit "server.js" "$src"
  } > "$tmp"
  grep -q '^  server.js:' "$tmp" || { echo "ERROR: 生成的清单里没有 server.js 键"; rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$out"
  echo "api 源码: $out（$(wc -c < "$src" | tr -d ' ') 字节）"
}

# 备份轮转（2026-11-09）：每次手工迁移都 `cp -a` 一份十几 G 的备份，
# 攒几次就把盘吃掉，而没有任何东西会提醒。保留最近 N 份，其余删掉并打印删了什么。
kits_backup() {
  local root="${1:-/root}" keep=2 pattern="G41KiTS.bak." list n i=0
  if [ "$(id -u)" != "0" ]; then
    echo "ERROR: 备份轮转只在部署机上跑（需要读写 /root）——没能验到"; return 2
  fi
  list=$(ls -1dt "$root/$pattern"* 2>/dev/null || true)
  n=$(echo "$list" | grep -c . || true)
  echo "现有备份: $n 份"
  [ "$n" -gt 0 ] || return 0
  for d in $list; do
    i=$((i+1))
    local sz; sz=$(du -sh "$d" 2>/dev/null | cut -f1)
    if [ "$i" -le "$keep" ]; then
      printf '  保留 %s (%s)\n' "$(basename "$d")" "$sz"
    else
      printf '  删除 %s (%s)\n' "$(basename "$d")" "$sz"
      rm -rf "$d"
    fi
  done
  echo "轮转完成，保留最近 $keep 份"
}

kits_export() {
  local m="" out=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--out) out="$2"; shift;;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) m="$1";;
    esac
    shift
  done
  [ -n "$m" ] || { echo "ERROR: module name required"; return 1; }
  [ -f "kits/$m/info.json" ] || { echo "ERROR: 模块 '$m' 不存在"; return 1; }

  local ver; ver=$(kit_version "$m")
  local inj_from inj_cm inj_ns
  inj_from=$(jq -r '.inject.from // ""' "kits/$m/info.json" 2>/dev/null || true)
  inj_cm=$(jq -r '.inject.configmap // ""' "kits/$m/info.json" 2>/dev/null || true)
  inj_ns=$(jq -r '.inject.namespace // "g41"' "kits/$m/info.json" 2>/dev/null || true)
  [ "$inj_from" = "null" ] && inj_from=""
  [ -d "kits/$m/$inj_from" ] || inj_from=""

  local has_seed=""
  # 末尾必须 || true：三者都为假时这个复合命令返回 1，set -e 会当场杀脚本，
  # 而它本该走到下面那句人话报错。
  { [ -f "kits/$m/tile.json" ] || [ -f "kits/$m/app.json" ] || [ -f "kits/$m/link.json" ] \
    || [ -d "kits/$m/i18n" ] || [ -d "kits/$m/data" ]; } && has_seed=1 || true

  if [ ! -d "kits/$m/k8s" ] && [ -z "$inj_from" ] && [ -z "$has_seed" ]; then
    echo "ERROR: kits/$m 既没有 k8s/ 清单，也没有可注入的内容 —— 没有可导出的东西"
    return 1
  fi

  [ -n "$out" ] || out="dist/$m-$ver.yaml"
  mkdir -p "$(dirname "$out")" 2>/dev/null
  # 先写临时文件再 mv：直接写 $out 时，中途失败会留下**上一版或半截**的文件，
  # 而下一个读它的人（常常是我）会把旧产物当成这次的结果。
  local tmpout="${out}.tmp.$$"
  rm -f "$tmpout" 2>/dev/null || true

  local f count=0 objs=0
  local group; group=$(kit_k8s_group "$m")
  {
    echo "# G41KiTS module bundle — $m @ $ver"
    echo "# repo: https://github.com/Kihara777/G41KiTS"
    echo "# generated: $(date -Is)"
    if [ "$(echo "$group" | wc -l)" -gt 1 ]; then
      echo "# pod group '$(kit_k8s_pod "$m")' — 本次含同组模块: $(echo "$group" | tr '\n' ' ')"
      echo "# 一个 Pod 不能拆开装：只装其中一个会得到没有后端的 Service。"
    fi
    echo "# 用法: kubectl apply -f <这份文件>；卸载: kubectl delete -f <同一份文件>"
    local gm
    # 镜像 tag 钉到各模块自己的版本：`g41k8s/<m>:local` → `g41k8s/<m>:<version>`。
    # 必须对**组内全部模块**做替换：一个 Pod 里可能跑着别的模块的容器
    # （如 download 里的 bt），它的镜像 tag 写在 aria2 的文件里。
    # 不钉住的话，包与镜像的对应只存在于「当时 :local 指向谁」，而那是会变的。
    local seds=() gm gmver
    for gm in $group; do
      gmver=$(kit_version "$gm")
      seds+=(-e "s|g41k8s/${gm}:local|g41k8s/${gm}:${gmver}|g")
    done
    for gm in $group; do
      for f in "kits/$gm/k8s"/*.yaml; do
        [ -f "$f" ] || continue
        count=$((count+1))
        echo "---"
        echo "# from: kits/$gm/${f##*/}"
        sed "${seds[@]}" "$f"
        echo
      done
    done

    # 内容注入类：把模块内容打成 ConfigMap。
    # 为什么不用 Secret：这些是可公开分发的静态资源，不是凭据。
    if [ -n "$inj_from" ]; then
      local total=0 sz
      for f in "kits/$m/$inj_from"/*; do
        [ -f "$f" ] || continue
        sz=$(wc -c < "$f" | tr -d ' ')
        total=$((total + sz))
      done
      # ConfigMap 上限 1MiB（etcd 限制，超出会在 apply 时才报，且报错很难读）
      if [ "$total" -gt 900000 ]; then
        echo "# ERROR: 内容共 $total 字节，超过 ConfigMap 安全上限 900000 —— 该走镜像而不是 ConfigMap" >&2
        return 1
      fi
      echo "---"
      echo "apiVersion: v1"
      echo "kind: ConfigMap"
      echo "metadata:"
      echo "  name: $inj_cm"
      echo "  namespace: $inj_ns"
      echo "  labels:"
      echo "    app.kubernetes.io/part-of: g41"
      echo "    g41.module: $m"
      echo "    g41.version: \"$ver\""
      echo "data:"
      for f in "kits/$m/$inj_from"/*; do
        [ -f "$f" ] || continue
        # 块标量指示符必须跟着原文件的末尾换行走，否则还原会多/少一个换行：
        #   无末尾换行 -> |-（strip）  恰好一个 -> |（clip）  两个以上 -> |+（keep）
        # 这不是洁癖：多一个换行会让「逐字节还原」这条判据变成假的。
        local ind="|" lastbyte="" last2=""
        lastbyte=$(tail -c 1 "$f" 2>/dev/null | od -An -tx1 | tr -d ' \n')
        if [ "$lastbyte" != "0a" ]; then
          ind="|-"
        else
          last2=$(tail -c 2 "$f" 2>/dev/null | od -An -tx1 | tr -d ' \n')
          [ "${last2}" = "0a0a" ] && ind="|+"
        fi
        echo "  $(basename "$f"): $ind"
        sed 's/^/    /' "$f"
        # |- 时 sed 输出没有末尾换行，补一个让下一行从行首开始；
        # 该换行会被 strip 掉，不进入内容。| 与 |+ 自带换行，不再补。
        [ "$ind" = "|-" ] && echo
      done
      count=$((count+1))
    fi

  } > "$tmpout"

  if [ "$count" -le 0 ]; then
    echo "ERROR: 没有产出任何对象"; rm -f "$tmpout"; return 1
  fi
  objs=$(grep -cE '^kind:' "$tmpout" || true)
  if [ -z "$objs" ] || [ "$objs" -le 0 ]; then
    echo "ERROR: 产物里没有一个 kind: —— 生成失败，不留下半截文件"; rm -f "$tmpout"; return 1
  fi
  mv -f "$tmpout" "$out"
  echo "导出: $out（$m @ $ver，$count 份来源，$objs 个对象${inj_from:+，含内容注入 $inj_from}）"
}

kits_remote() {
  local url="" apply="" ns="" expect=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --apply) apply="1";;
      -n|--namespace) ns="$2"; shift;;
      --sha256) expect="$2"; shift;;
      -h|--help)
        echo "Usage: $0 kits remote <url> [--apply] [-n <namespace>] [--sha256 <hex>]"
        echo "  不加 --apply 只取下来算哈希并做静态语法检查，不连集群。"
        echo "  --sha256 给了期望值才做事前校验；不给则哈希仅供事后对账。"
        return 0;;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) url="$1";;
    esac
    shift
  done
  [ -n "$url" ] || { echo "ERROR: url required"; return 1; }
  command -v curl >/dev/null 2>&1 || { echo "ERROR: curl 未找到 —— 没能验到"; return 2; }

  # 临时文件名必须带 .yaml 后缀：kubeconform 会静默跳过无扩展名的文件，
  # 并打印 "0 resource found in 0 file"、退出码仍是 0 —— 看起来像通过。
  local tmp; tmp=$(mktemp "${TMPDIR:-/tmp}/g41-remote-XXXXXX.yaml" 2>/dev/null) \
    || tmp=$(mktemp) || { echo "ERROR: mktemp 失败"; return 2; }

  if ! curl -fsSL --max-time 30 "$url" -o "$tmp"; then
    echo "ERROR: 取不到 $url（网络不可达或 404）——**没能验到**，不是通过"
    rm -f "$tmp"; return 2
  fi

  local sha bytes docs
  sha=$(sha256sum "$tmp" | awk '{print $1}')
  bytes=$(wc -c < "$tmp" | tr -d ' ')
  docs=$(grep -cE '^kind:' "$tmp" 2>/dev/null || true)
  [ -n "$docs" ] || docs=0

  echo "来源   : $url"
  echo "sha256 : $sha"
  echo "大小   : $bytes 字节"
  echo "对象数 : $docs"

  # 0 个对象不是「空清单」，是「这不是清单」——拒绝，且不许静默通过。
  if [ "$docs" -eq 0 ]; then
    echo "ERROR: 内容里没有任何 k8s 对象（0 个 kind:），拒绝安装"
    rm -f "$tmp"; return 1
  fi

  if [ -n "$expect" ]; then
    if [ "$expect" != "$sha" ]; then
      echo "ERROR: sha256 不匹配"
      echo "  期望: $expect"
      echo "  实际: $sha"
      echo "  文件未被应用。"
      rm -f "$tmp"; return 1
    fi
    echo "校验   : sha256 与期望一致"
  else
    echo "注意   : 未给 --sha256，上面的哈希只能**事后对账**，不是事前校验"
  fi

  if [ -z "$apply" ]; then
    # 静态检查：kubeconform 若能取到就做 schema 校验；取不到就明说没验。
    # 注意：不许写成 `if kubeconform … | tail -5; then` —— 那样判的是 tail 的
    # 退出码（恒 0），等于永远「通过」。必须先收集输出再判状态。
    if command -v kubeconform >/dev/null 2>&1; then
      # set -e 在场：`kc_out=$(cmd)` 失败会当场退出脚本、连理由都不打印。
      # 用 `|| kc_rc=$?` 接住，才能既拿到状态码又打印诊断。
      local kc_out="" kc_rc=0
      kc_out=$(kubeconform -strict -summary "$tmp" 2>&1) || kc_rc=$?
      echo "$kc_out" | tail -5
      if [ "$kc_rc" -ne 0 ]; then
        echo "静态校验: kubeconform 失败（退出码 $kc_rc）"
        rm -f "$tmp"; return 1
      fi
      # 校验了 0 个对象也算失败：说明这份文件根本没被读到，不是「全绿」。
      case "$kc_out" in
        *"Valid: 0, Invalid: 0"*)
          echo "静态校验: 0 个对象被校验 —— 没能验到，不算通过"
          rm -f "$tmp"; return 2;;
      esac
      echo "静态校验: kubeconform 通过（schema 层，不含集群实际状态）"
    else
      echo "静态校验: 未执行（没有 kubeconform）——**没能验到**"
    fi
    echo "未加 --apply：清单已取到并核对，**没有**发送到集群。"
    rm -f "$tmp"; return 0
  fi

  local kubectl="kubectl"
  if ! command -v kubectl >/dev/null 2>&1; then
    command -v k3s >/dev/null 2>&1 || { echo "ERROR: 找不到 kubectl 或 k3s —— 没能验到"; rm -f "$tmp"; return 2; }
    kubectl="k3s kubectl"
  fi

  local nsf=(); [ -n "$ns" ] && nsf=(-n "$ns")

  echo "--- 应用到集群${ns:+（namespace=$ns）} ---"
  if $kubectl apply --validate=false "${nsf[@]}" -f "$tmp" 2>&1; then
    echo "已应用。卸载：kubectl delete ${nsf[*]} -f <同一份清单>"
    rm -f "$tmp"; return 0
  fi
  echo "ERROR: apply 失败（清单见 $tmp，保留以便排查）"
  return 1
}

kits_update() {
  local m="" to="" apply="" build=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --to) to="$2"; shift;;
      --apply) apply="1";;
      --build) build="1";;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) m="$1";;
    esac
    shift
  done
  [ -n "$m" ] || { echo "ERROR: module name required"; return 1; }
  [ -f "kits/$m/info.json" ] || { echo "ERROR: 模块 '$m' 不存在"; return 1; }

  if [ -n "$to" ]; then
    # 只接受安全的 tag 字符；版本会直接进镜像 tag 与文件名。
    case "$to" in
      *[!A-Za-z0-9._+-]*) echo "ERROR: 版本 '$to' 含非法字符（只允许字母数字 . _ + -）"; return 1;;
    esac
    grep -q '"version"' "kits/$m/info.json" || {
      echo "ERROR: kits/$m/info.json 还没有 version 字段——先手工加上再 update"; return 1; }
    local cur; cur=$(kit_version "$m")
    if [ "$cur" = "$to" ]; then
      echo "版本已是 $to，无需改动"
    else
      sed "s/\"version\": *\"[^\"]*\"/\"version\": \"$to\"/" \
        "kits/$m/info.json" > "kits/$m/info.json.new.$$"
      mv -f "kits/$m/info.json.new.$$" "kits/$m/info.json"
      local now; now=$(kit_version "$m")
      # 写后读回：sed 没匹配上时会「成功」但什么都没改。
      [ "$now" = "$to" ] || { echo "ERROR: 写回后读到的是 '$now'，不是 '$to'——版本未生效"; return 1; }
      echo "版本: $cur → $to"

      # 清单里的镜像 tag 必须跟着版本走（2026-11-09）。
      # 不同步的话：info.json 说 1.1.0、清单还写着 1.0.0，apply 出去跑的是旧镜像，
      # 而两个 tag 都存在、Pod 也健康——没有东西会报错。
      local mf changed=0
      for mf in "kits/$m/k8s"/*.yaml; do
        [ -f "$mf" ] || continue
        grep -q "g41k8s/$m:$cur" "$mf" 2>/dev/null || continue
        sed -i "s|g41k8s/$m:$cur|g41k8s/$m:$to|g" "$mf"
        changed=$((changed+1))
      done
      if [ "$changed" -gt 0 ]; then
        echo "清单 tag 已同步: $changed 份（g41k8s/$m:$cur → $to）"
        echo "  注意：新 tag 的镜像必须先构建出来，否则 apply 后是 ImagePullBackOff"
        echo "  （在部署机上跑 /opt/g41/k8s/host/g41-image-build.sh $m）"
      fi
    fi
  fi

  local ver; ver=$(kit_version "$m")

  # --build：镜像必须先于清单存在，否则 apply 下去就是 ImagePullBackOff。
  # 把这一步并进来，是为了不再依赖「人记得先建」（2026-11-09 我自己就差点漏）。
  if [ -n "$build" ]; then
    local bs="/opt/g41/k8s/host/g41-image-build.sh"
    if [ -x "$bs" ]; then
      echo "构建镜像（$m @ $ver）…"
      "$bs" "$m" || { echo "ERROR: 镜像构建失败，未生成包"; return 1; }
    else
      echo "ERROR: 找不到 $bs —— 镜像构建只在部署机上能做（没能验到）"
      return 2
    fi
  fi

  kits_export "$m" || return 1

  if [ -z "$apply" ]; then
    echo "未加 --apply：包已生成，**没有**发送到集群。"
    echo "  应用: kubectl apply -f dist/$m-$ver.yaml"
    return 0
  fi
  command -v kubectl >/dev/null 2>&1 || { echo "ERROR: 找不到 kubectl —— 没能验到"; return 2; }
  kubectl apply --validate=false -f "dist/$m-$ver.yaml"
}

kits_rollback() {
  local m="" to="" apply=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --to) to="$2"; shift;;
      --apply) apply="1";;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) m="$1";;
    esac
    shift
  done
  [ -n "$m" ] || { echo "ERROR: module name required"; return 1; }

  # 可回滚的版本 = dist/ 里现存的本模块包。
  # 注意：dist/ 是生成物、不入库，所以**旧包不存在就回不去**——
  # 这不是保守，是事实；真正可靠的来源是 git 历史（重新 export 对应提交）。
  local list; list=$(ls -1 dist/"$m"-*.yaml 2>/dev/null | sed "s|dist/$m-||; s|\.yaml$||" | sort -V || true)
  if [ -z "$list" ]; then
    echo "ERROR: dist/ 里没有任何 '$m' 的包——回滚需要旧包还在。"
    echo "       先导出当前版本，或从 git 历史里找回对应提交再 export。"
    return 2
  fi

  local target="$to"
  if [ -z "$target" ]; then
    # 默认回退到「当前版本的前一个」；只有当前一个版本时明确拒绝，不猜。
    local cur; cur=$(kit_version "$m")
    # 必须 `|| true`：只剩当前版本时 grep 无匹配返回 1，而 set -e 会让
    # `target=$(…)` 直接把脚本杀掉——连下面那句「没有可回滚的目标」都打不出来。
    target=$(echo "$list" | grep -vx "$cur" | tail -1 || true)
    if [ -z "$target" ]; then
      echo "ERROR: 只有 '$cur' 一个版本可选，没有可回滚的目标"
      echo "       现存版本: $(echo "$list" | tr '\n' ' ')"
      return 1
    fi
  fi
  echo "$list" | grep -qx "$target" || {
    echo "ERROR: 没有 '$target' 这个版本的包"; echo "       现存: $(echo "$list" | tr '\n' ' ')"; return 1; }

  echo "回滚目标: $m @ $target（现存: $(echo "$list" | tr '\n' ' ')）"
  if [ -z "$apply" ]; then
    echo "未加 --apply：**没有**发送到集群。"
    echo "  应用: kubectl apply -f dist/$m-$target.yaml"
    echo "  注意：包里的镜像 tag 是 g41k8s/$m:$target，该镜像必须仍在 containerd 里，否则会 ImagePullBackOff。"
    return 0
  fi
  command -v kubectl >/dev/null 2>&1 || { echo "ERROR: 找不到 kubectl —— 没能验到"; return 2; }
  kubectl apply --validate=false -f "dist/$m-$target.yaml"
}

kits_selftest() {
  local m="${1:-}" fails=0 ran=0 mod cmd
  local list
  if [ -n "$m" ]; then
    list="$m"
  else
    list=$(ls -1 kits/*/info.json 2>/dev/null | sed 's|kits/||; s|/info.json||' || true)
  fi
  for mod in $list; do
    [ -f "kits/$mod/info.json" ] || { echo "ERROR: 模块 '$mod' 不存在"; return 1; }
    cmd=$(jq -r '.selftest // ""' "kits/$mod/info.json" 2>/dev/null || true)
    [ -n "$cmd" ] && [ "$cmd" != "null" ] || continue
    ran=$((ran+1))
    echo "--- $mod: $cmd"
    # 在模块目录里跑，路径相对模块根，与部署时的相对关系一致。
    if ( cd "kits/$mod" && sh -c "$cmd" ); then
      echo "    ✔ $mod"
    else
      echo "    ✘ $mod 自检失败"
      fails=$((fails+1))
    fi
  done
  if [ "$ran" -eq 0 ]; then
    echo "没有模块声明 selftest —— 没能验到，不是通过"
    return 2
  fi
  echo
  echo "自检：$ran 个模块，失败 $fails 个"
  [ "$fails" -eq 0 ]
}

k8s_drift() {
  # 「宿主内容变了，而 Pod 没重启」——这类不一致在 k8s 下不会自己报错：
  # 文件是新的、进程是旧的，服务照常响应，只是行为还是旧的。
  # 判据：Pod 的 startTime 之后，它挂载的 hostPath 里还有文件被改过 → 报 drift。
  local kubectl="kubectl"
  if ! command -v kubectl >/dev/null 2>&1; then
    command -v k3s >/dev/null 2>&1 || { echo "ERROR: 找不到 kubectl 或 k3s —— 没能验到"; return 2; }
    kubectl="k3s kubectl"
  fi
  local ns="${1:-g41}"
  local raw; raw=$($kubectl get pods -n "$ns" -o json 2>/dev/null) || {
    echo "ERROR: 读不到 namespace '$ns' 的 Pod —— 没能验到"; return 2; }

  local count; count=$(echo "$raw" | jq -r '.items | length' 2>/dev/null)
  [ -n "$count" ] && [ "$count" -gt 0 ] || { echo "ERROR: '$ns' 里没有 Pod —— 没能验到"; return 2; }

  local drift=0 checked=0 line pod start paths p newest
  while IFS=$'\t' read -r pod start paths; do
    [ -n "$pod" ] || continue
    [ "$start" != "null" ] || continue
    [ -n "$paths" ] && [ "$paths" != "null" ] || continue
    checked=$((checked+1))
    local pod_drift=""
    IFS=',' read -ra arr <<< "$paths"
    for p in "${arr[@]}"; do
      [ -e "$p" ] || continue
      # -newermt 接受 ISO8601；只比文件，目录的 mtime 会因内容增减而变，噪声大。
      newest=$(find "$p" -type f -newermt "$start" 2>/dev/null | head -3 || true)
      [ -n "$newest" ] && pod_drift="$pod_drift $newest"
    done
    if [ -n "$pod_drift" ]; then
      drift=$((drift+1))
      echo "⚠ drift: $pod（startTime $start）— 之后被改过的宿主文件:"
      for p in $pod_drift; do echo "    $p"; done
    fi
  done < <(echo "$raw" | jq -r '
    .items[] |
    # 判据只认**只读挂载**：Pod 改不了它，所以里面的变化只可能来自宿主供给
    # （config、server.js、内容目录）。可写挂载里既有配置也有数据库/下载文件，
    # 按文件名分不开——`filebrowser.db`、`dump.rdb` 会被误报成 drift，
    # 而一条天天空响的判据会训练人忽略它。
    # 代价说清楚：可写的配置文件（如 blc 的 config.ini）不在射程内。
    ([ .spec.containers[]? as $c | $c.volumeMounts[]? |
       select(.readOnly == true) | .name ] | unique) as $names |
    {pod: .metadata.name, start: .status.startTime,
     paths: [ .spec.volumes[]? | select(.hostPath) | select(.name as $n | $names | index($n)) | .hostPath.path ]} |
    select((.paths|length) > 0) |
    "\(.pod)\t\(.start)\t\(.paths|join(","))"
  ' 2>/dev/null)

  echo
  if [ "$drift" -gt 0 ]; then
    echo "$drift 个 Pod 的内容比进程新 —— 重启对应 Deployment 才会生效。"
    return 1
  fi
  echo "$checked 个挂载 hostPath 的 Pod，内容都没有比进程新。"
  return 0
}

main() {
  case "${1:-}" in
    init)
      if [ "${2:-}" = "k8s" ]; then do_init_k8s; else do_init; fi
      ;;
    kits)
      case "${2:-}" in
        --help|-h) kits_help;;
        check) kits_check "$3";;
        verify) kits_verify "$3";;
        add) shift 2; kits_add "$@";;
        del) shift 2; kits_del "$@";;

        pack) shift 2; kits_pack "$@";;
        export) shift 2; kits_export "$@";;
        content) shift 2; kits_content "$@";;
        api-src) shift 2; kits_api_src "$@";;
        backup) shift 2; kits_backup "$@";;
        update) shift 2; kits_update "$@";;
        rollback) shift 2; kits_rollback "$@";;
        selftest) shift 2; kits_selftest "$@";;
        remote) shift 2; kits_remote "$@";;
        reload) kits_reload;;
        simulate) echo "Use: ./g41.sh kits add <name> --dry-run";;
        "") kits_list;;
        *) echo "Unknown kits command: $2"; kits_help;;
      esac
      ;;
    k8s)
      case "${2:-}" in
        apply) shift 2; k8s_apply "$@";;
        stage) k8s_stage;;
        base) k8s_apply_base_only;;
        conf) k8s_nginx_conf_apply;;
        build) shift 2; if [ -n "${1:-}" ]; then k8s_build "$1"; else for m in $(kits_installed_list); do [ -d "kits/$m/k8s" ] && k8s_build "$m"; done; fi;;
        status) k8s_status;;
        drift) shift 2; k8s_drift "$@";;
        ""|--help|-h) echo "Usage: $0 k8s [apply|stage|base|conf|build|status]  (stage = 分阶段部署，1GB 机推荐)"
        echo "        drift [ns]   报出「宿主文件比 Pod 新」的不一致（默认 ns=g41）";;
        *) echo "Unknown k8s command: $2";;
      esac
      ;;
    backend)
      case "${2:-}" in
        ""|get) backend_get;;
        compose|k8s) backend_set "$2";;
        *) echo "Usage: $0 backend [get|compose|k8s]";;
      esac
      ;;
    --help|-h)
      echo "Usage: $0 [init|kits|backend|k8s|--help]"
      echo "  (no args)   Show G41 ASCII art"
      echo "  init        Run full server setup"
      echo "  kits        Module management"
      echo "  backend     Select deployment backend (compose|k8s)"
      echo "  k8s         k8s backend operations"
      exit 0
      ;;
    "")
      show_ascii
      ;;
    *)
      echo "Unknown: $1  Try --help"; exit 1
      ;;
  esac
}

main "$@"
