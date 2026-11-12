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
  local m="" skip="" dry="" core="" nb=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -y) skip="-y";;
      -C|--core) core="1";;
      --dry-run) dry="1";;
      --no-build) nb="1";;   # k8s 转发给 install 时会用到
      *) m="$1";;
    esac
    shift
  done
  [ -z "$m" ] && { echo "ERROR: module name required"; return 1; }

  # 2026-11-12：k8s 后端下 `kits add` **直接转给 kits install**，不再走宿主装配。
  # 之前它只打印提示然后继续铺文件——那批文件没有消费者（内容走 g41-content ConfigMap、
  # api 源码走 g41-api-src），铺出去只会让人以为装好了。
  if [ "$(backend_get)" = "k8s" ]; then
    echo "（backend=k8s：kits add 转给 kits install）"
    if [ "$m" = "all" ]; then
      # 共享生成物（内容种子 / api 源码）与装哪个模块无关，批量时只做一次。
      # 否则 25 个模块各生成一次 63 键的 ConfigMap，实测一轮要几分钟。
      kits_content >/dev/null 2>&1 || true
      kits_api_src >/dev/null 2>&1 || true
      export KITS_INSTALL_SKIP_SHARED=1 KITS_INSTALL_SKIP_DEPS=1
      local cnt=0 n
      for d in kits/*/; do
        n=$(basename "$d"); [ -f "$d/info.json" ] || continue
        kits_install "$n" ${dry:+--dry-run} ${nb:+--no-build} >/dev/null && cnt=$((cnt+1))
      done
      unset KITS_INSTALL_SKIP_SHARED KITS_INSTALL_SKIP_DEPS
      echo "All: $cnt 个模块已应用"
      return 0
    fi
    kits_install "$m" ${dry:+--dry-run} ${nb:+--no-build}
    return $?
  fi

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

  # k8s 后端下 `kits del` 走的是宿主装配的删除，而内容/源码已由 ConfigMap 供给——
  # 删宿主文件删不掉线上任何东西（2026-11-12）。直接转给 uninstall。
  if [ "$(backend_get)" = "k8s" ]; then
    echo "（backend=k8s：kits del 转给 kits uninstall）"
    if [ "$m" = "all" ]; then
      echo "ERROR: k8s 后端下不支持 del all —— 那会把整站删空。请逐个指名。"
      return 2
    fi
    kits_uninstall "$m" ${core:+--force}
    return $?
  fi

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
  local out="dist/g41-content.yaml" exclude=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--out) out="$2"; shift;;
      --exclude) exclude="$2"; shift;;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) ;;
    esac
    shift
  done
  mkdir -p "$(dirname "$out")" 2>/dev/null
  local tmp="${out}.tmp.$$"; rm -f "$tmp"
  local n=0 m d cf total=0 sz dep t f e dir src

  # 类型判定改回**依赖驱动**（2026-11-12）：
  #   旧做法看文件名（有 tile.json 就是 tile），于是「有 tile.json 但没依赖 home」的模块
  #   照样会被收进种子——按文件名装，而不是按声明的依赖装。
  #   现在遍历 m 的直接依赖 p，取 p 的 provides[].accepts/file/ext/dir：
  #     kits/<m>/<provides.file> 是目录 → shape=dir（i18n、data 这种）
  #     kits/<m>/<provides.file> 是文件 → shape=file（tile、app、link）
  #     两者都不是 → 这个模块不是该类型的消费者
  # 这一步完全来自数据，不含推断。
  local plan mapent; plan=$(mktemp); mapent=$(mktemp)
  : > "$plan"; : > "$mapent"
  for d in kits/*/; do
    m=$(basename "$d")
    [ -f "$d/info.json" ] || continue
    if [ -n "$exclude" ] && [ "$exclude" = "$m" ]; then continue; fi
    # 依赖 + 自己：provider 往往就是内容的**生产者本人的依赖**（home 自己有 tile.json 和
    # i18n/，而它不会依赖自己）。只扫 depends 会把 home 自己的 tile 弄丢——实测 12 个 tile
    # 变成 11 个，少的那一个正是首页自己的。
    for dep in $(jq -r '.depends[]?' "$d/info.json" 2>/dev/null || true) "$m"; do
      [ -f "kits/$dep/info.json" ] || continue
      while IFS=$'\t' read -r t dir f e; do
        [ -n "$t" ] || continue
        src="kits/$m/$f"
        # shape 的判据只有一条：provides.file **含点就是文件名，不含点就是目录名**。
        # 早先这里按「该模块下有没有这个目录/文件」来推，而 seed_map_json 用含点规则——
        # 同一个事实两个来源。现在统一成含点规则，存在性只用来判断「这是不是消费者」。
        case "$f" in
          *.*) shape="file";;
          *)   shape="dir";;
        esac
        printf '%s\t%s\t%s\t%s\t%s\n' "$t" "$dir" "$f" "$e" "$shape" >> "$mapent"
        if [ "$shape" = "file" ]; then
          [ -f "$src" ] || continue
          printf '%s\t%s\t%s\n' "$t.$m.$e" "$src" "$m" >> "$plan"
        else
          [ -d "$src" ] || continue
          for cf in "$src"/*."$e"; do
            [ -f "$cf" ] || continue
            printf '%s\t%s\t%s\n' "$t.$m.$(basename "${cf%.$e}").$e" "$cf" "$m" >> "$plan"
          done
        fi
      # 只有标了 content:true 的类型走内容种子。别的类型各有各的供给路径：
      #   site（nginx conf）走自己的 ConfigMap、webroot 走 hostPath、
      #   blc_template 走 inject —— 它们也曾被这条通用扫描误纳（实测 blc_template 混进来过）。
      # 标记写在 provider 的 info.json 上，所以「哪些类型进种子」也是数据，不是代码。
      done < <(jq -r '.provides[]? | select(.accepts != null and .content == true) | "\(.accepts[0])\t\(.dir // "")\t\(.file // "")\t\(.ext // "json")"' "kits/$dep/info.json" 2>/dev/null)
    done
  done

  if [ ! -s "$plan" ]; then
    echo "ERROR: 没有解析出任何内容键 —— 检查 provides 与 depends 是否对得上"; rm -f "$plan" "$mapent"; return 1
  fi

  # 同一个类型可能被多个 provider 以**不同目录**声明，那才是真冲突；取第一个并提示。
  # 注意顺序：先按整行去重，再找重复的 type —— 否则每个消费模块都会往 mapent 里加一行，
  # 一上来就满屏「重复」（第一版就是这么误报的，把 app/i18n/link/tile 全报了）。
  sort -u "$mapent" -o "$mapent"
  local dup; dup=$(cut -f1 "$mapent" | uniq -d | tr '\n' ' ')
  if [ -n "$dup" ]; then
    echo "WARN: 这些类型被多个 provider 声明，取第一个: $dup"
  fi
  awk -F'\t' '!seen[$1]++' "$mapent" > "$mapent.first" && mv "$mapent.first" "$mapent"

  local mapfile; mapfile=$(mktemp)
  # 直接用 seed_map_json 的产物（2026-11-12 第二次修）：
  # 这里原先自己另生成一份，而那一份**没有把 `.rd/data` 归一化成空目录**，
  # 于是 data 型内容落到 `/tmp/g41-seed/.rd/data/home/…`；readDir 会过滤点开头的目录，
  # 装载时看不见 → 过期键清理把 `data:home/*` 全删了 → 前端 /data/home/status 拿到 404 的 HTML。
  # 两份映射 = 两个真相，而这个错误的代价是**首页直接报错**。
  seed_map_json > "$mapfile" 2>/dev/null || { echo "ERROR: 生成 _map.json 失败"; rm -f "$plan" "$mapent" "$mapfile"; return 1; }
  if [ ! -s "$mapfile" ]; then
    echo "ERROR: 映射为空"; rm -f "$plan" "$mapent" "$mapfile"; return 1
  fi

  # 体积按实际要发的键算（不是按文件名扫）
  while IFS=$'\t' read -r t cf _; do
    [ -f "$cf" ] || continue
    sz=$(wc -c < "$cf" | tr -d ' '); total=$((total + sz))
  done < "$plan"
  sz=$(wc -c < "$mapfile" | tr -d ' '); total=$((total + sz))
  if [ "$total" -gt 900000 ]; then
    echo "ERROR: 内容共 $total 字节，超过 ConfigMap 安全上限 900000 —— 该走镜像而不是 ConfigMap"
    rm -f "$plan" "$mapent" "$mapfile"; return 1
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
    # 映射本身也作为数据发下去：容器里的 loader 看不到仓库的 provides，
    # 没有它就只能把「类型 → 目录」硬编码在 loader 里（那正是之前丢掉动态性的一步）。
    cm_emit "_map.json" "$mapfile"; n=$((n+1))
    # 内容键按 plan（依赖驱动解析出来的）逐条发
    while IFS=$'\t' read -r key cf _; do
      [ -f "$cf" ] || continue
      cm_emit "$key" "$cf"; n=$((n+1))
    done < <(sort -t$'\t' -k3,3 -k1,1 "$plan")
  } > "$tmp"

  if [ "$n" -le 1 ]; then
    echo "ERROR: 除了映射以外一个内容键都没生成 —— 没有可种的内容"
    rm -f "$plan" "$mapent" "$mapfile" "$tmp"; return 1
  fi
  rm -f "$plan" "$mapent" "$mapfile"
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

# 模块现状账（2026-11-10）：仓库侧事实 + 可选集群侧事实。
#
# 为什么需要它：设施现在能建版本、能发、能回滚，但没有一张「现在装了什么、
# 清单指向哪个镜像、内容键是谁供的」的账。查这些要翻四个地方：
# info.json、k8s 清单、kits content 的产物、集群里的 Deployment。
# 这四条一旦不一致，**每一处单独看都是对的**。
# k8s 原生的「装一个模块」（2026-11-10）。
#
# 为什么不是复用 `kits add`：那条路是**宿主内容装配**（往 .rd/data、.gx 铺硬链接），
# 而内容已经改由 ConfigMap 供给——现在跑它只会往宿主铺一批没人读的文件。
# 装了看起来没坏，页面也正常，**因为真正生效的是另一条路**。这种死路留着最危险。
#
# 这里只做四件事，每一步都能单独查：
#   1. verify（已有的 L1–L4）
#   2. 自建镜像先构建（否则 apply 下去就是 ImagePullBackOff）
#   3. 刷新内容种子与 api 源码（仓库级生成物，幂等）
#   4. 导出该模块的包并 apply（包里的镜像 tag 已钉版本）
kits_install() {
  local m="" dry="" nohandoff=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) dry="1";;
      --no-build) nohandoff="1";;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) m="$1";;
    esac
    shift
  done
  [ -n "$m" ] || { echo "ERROR: module name required"; return 1; }
  [ -f "kits/$m/info.json" ] || { echo "ERROR: 模块 '$m' 不存在"; return 1; }

  local be; be=$(backend_get)
  if [ "$be" != "k8s" ]; then
    echo "ERROR: backend=$be —— kits install 只实现 k8s 路径；compose 请用 kits add（没能验到）"
    return 2
  fi

  # 依赖先装（2026-11-12）。这是 `kits add` 原本的语义，install 之前漏了。
  # 放在校验之前：依赖装不上时，装本体没有意义。
  # 深度上限防止 A depends B、B depends A 这种环把脚本拖死——环本身应该在校验里报，
  # 但那是「理想」，这里是「别挂」。
  local depth="${KITS_INSTALL_DEPTH:-0}"
  if [ "${KITS_INSTALL_SKIP_DEPS:-0}" = "1" ]; then
    echo "（批量模式：跳过依赖递归——本次会把所有模块都装一遍）"
  elif [ "$depth" -lt 5 ]; then
    local dep kc
    kc=$(kit_core 2>/dev/null || echo "core")
    for dep in $(jq -r '.depends[]?' "kits/$m/info.json" 2>/dev/null || true); do
      [ "$dep" = "$m" ] && continue
      # `core` 是虚拟依赖（.env 的 G41_CORE），不是 kits/ 下的目录——原 kits_add 也跳过它
      [ "$dep" = "$kc" ] && continue
      [ "$dep" = "core" ] && continue
      [ -d "kits/$dep" ] || { echo "ERROR: 依赖 '$dep' 不在仓库里（kits/$dep）"; return 1; }
      # 只装「有东西可装」的依赖：有 k8s 清单或有内容种子的
      if [ -d "kits/$dep/k8s" ] || [ -f "kits/$dep/tile.json" ] || [ -f "kits/$dep/app.json" ] \
         || [ -f "kits/$dep/link.json" ] || [ -d "kits/$dep/i18n" ] || [ -d "kits/$dep/data" ]; then
        echo "→ 依赖 $dep"
        KITS_INSTALL_DEPTH=$((depth+1)) kits_install "$dep" \
          ${dry:+--dry-run} ${nohandoff:+--no-build} >/dev/null || {
          echo "ERROR: 依赖 '$dep' 安装失败，停止"; return 1; }
      fi
    done
  else
    echo "WARN: 依赖递归超过 5 层（可能有环），跳过继续装本体"
  fi

  echo "=== 1/4 校验 $m ==="
  kits_verify "$m" || return 1

  local mode; mode=$(jq -r '.compose // "none"' "kits/$m/info.json" 2>/dev/null)
  if [ "$mode" = "file" ] && [ -z "$nohandoff" ]; then
    local bs="/opt/g41/k8s/host/g41-image-build.sh"
    if [ -x "$bs" ]; then
      echo "=== 2/4 构建镜像 ==="
      "$bs" "$m" || { echo "ERROR: 镜像构建失败"; return 1; }
    else
      echo "=== 2/4 跳过构建：找不到 $bs（只在部署机上能建）==="
      echo "    注意：包里的 tag 是版本化的，镜像不存在时 apply 后是 ImagePullBackOff"
    fi
  else
    echo "=== 2/4 跳过构建（compose=$mode${nohandoff:+，--no-build}）==="
  fi

  echo "=== 3/4 刷新内容种子与 api 源码 ==="
  # 这两份是**仓库级生成物**，与具体装哪个模块无关。批量装（kits add all / install all）时
  # 每个模块都重生成一次 = 25 倍冗余，实测一轮要好几分钟。
  # 批量的调用方负责先做一次，然后设 KITS_INSTALL_SKIP_SHARED=1 跳过。
  if [ "${KITS_INSTALL_SKIP_SHARED:-0}" = "1" ]; then
    echo "    跳过（批量模式：调用方已生成）"
  else
    kits_content >/dev/null || { echo "ERROR: 内容种子生成失败"; return 1; }
    kits_api_src >/dev/null || { echo "ERROR: api 源码生成失败"; return 1; }
    echo "    dist/g41-content.yaml + dist/g41-api-src.yaml"
  fi

  echo "=== 4/4 导出并应用 $m 的包 ==="
  kits_export "$m" || return 1
  local ver; ver=$(kit_version "$m")
  local bundle="dist/$m-$ver.yaml"

  if [ -n "$dry" ]; then
    echo "    未加 --apply：包已生成，**没有**发送到集群"
    echo "    应用: kubectl apply -f $bundle"
    return 0
  fi
  command -v kubectl >/dev/null 2>&1 || { echo "ERROR: 找不到 kubectl —— 没能验到"; return 2; }
  kubectl apply -f dist/g41-content.yaml 2>&1 | tail -1
  kubectl apply -f dist/g41-api-src.yaml 2>&1 | tail -1
  kubectl apply -f "$bundle" 2>&1
  echo
  echo "装完。核对：./g41.sh kits status $m --cluster"
}

kits_status() {
  local only="" cluster=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --cluster) cluster="1";;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) only="$1";;
    esac
    shift
  done

  printf '%-14s %-8s %-10s %-24s %s\n' MODULE VERSION POD IMAGES CONTENT
  printf '%-14s %-8s %-10s %-24s %s\n' ------ ------- --- ------ -------
  local m d ver pod img content
  for d in kits/*/; do
    m=$(basename "$d")
    [ -f "$d/info.json" ] || continue
    [ -n "$only" ] && [ "$only" != "$m" ] && continue
    # 只报「有 k8s 清单」或「有内容」或「已部署」的模块，其余是纯宿主模块
    [ -d "$d/k8s" ] || [ -f "$d/tile.json" ] || [ -f "$d/app.json" ] || \
      [ -f "$d/link.json" ] || [ -d "$d/i18n" ] || [ -d "$d/data" ] || continue

    ver=$(kit_version "$m")
    pod=$(jq -r '.k8s.pod // ""' "$d/info.json" 2>/dev/null || true)
    if [ -z "$pod" ] || [ "$pod" = "null" ]; then
      # 没有显式组的模块自成一组（有清单才算）
      if [ -d "$d/k8s" ]; then pod="$m"; else pod="-"; fi
    fi

    img="-"
    # 镜像可能写在同组别的模块文件里（bt 的 tag 在 aria2 的 deployment 里），
    # 所以按模块名在全部清单里找，而不是只看自己的目录。
    if [ -d "$d/k8s" ] || [ "$pod" != "-" ]; then
      img=$(grep -rhoE "g41k8s/$m:[A-Za-z0-9._+-]+" kits/*/k8s/*.yaml 2>/dev/null | sort -u | head -2 | tr '\n' ' ' || true)
      img=${img% }
      [ -n "$img" ] || img="-"
    fi

    content=""
    [ -f "$d/tile.json" ] && content="${content}tile "
    [ -f "$d/app.json" ] && content="${content}app "
    [ -f "$d/link.json" ] && content="${content}link "
    [ -d "$d/i18n" ] && content="${content}i18n($(ls "$d"i18n/*.json 2>/dev/null | wc -l | tr -d ' ')) "
    [ -d "$d/data" ] && content="${content}data($(ls "$d"data/*.json 2>/dev/null | wc -l | tr -d ' ')) "
    [ -n "$content" ] || content="-"

    printf '%-14s %-8s %-10s %-22s %s\n' "$m" "$ver" "$pod" "$img" "$content"
  done

  if [ -n "$cluster" ]; then
    echo
    echo '=== 集群侧（实际跑着的镜像）==='
    command -v kubectl >/dev/null 2>&1 || command -v k3s >/dev/null 2>&1 || {
      echo "  没能验到：找不到 kubectl/k3s"; return 2; }
    local kc="kubectl"; command -v kubectl >/dev/null 2>&1 || kc="k3s kubectl"
    $kc get deploy -n g41 -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[*].image}{"\n"}{end}' 2>/dev/null || {
      echo "  没能验到：读不到 Deployment"; return 2; }
  fi
}

# 镜像清单与存在性（2026-11-10）。
#
# 背景：自建镜像只活在部署机的 containerd 里，没有 registry。这一点曾被我当成
# 「不可恢复」，其实不对——仓库在 git 里，`g41-image-build.sh` 无参就能把所有
# 已部署的自建镜像重建一遍。所以真正缺的不是恢复能力，是两样：
#   1. 一张「清单引用了哪些 tag」的账（`--verify` 会拿它去比 containerd）
#   2. 写在文档里的恢复路径（见 AGENTS.md「镜像重建」）
# 缺这两样时，镜像没了只会在 apply 之后以 ImagePullBackOff 的形式出现。
kits_images() {
  local verify=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --verify) verify="1";;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) ;;
    esac
    shift
  done

  # 仓库侧：清单引用了哪些 tag
  local refs; refs=$(grep -rhoE 'g41k8s/[A-Za-z0-9_-]+:[A-Za-z0-9._+-]+' kits/*/k8s/*.yaml 2>/dev/null | sort -u || true)
  if [ -z "$refs" ]; then
    echo "ERROR: 清单里没有任何 g41k8s/ 镜像引用 —— 没能验到"; return 2
  fi

  # 集群侧：本机 containerd 里有哪些
  local ctr=""
  if command -v k3s >/dev/null 2>&1; then ctr="k3s ctr"; fi
  if [ -z "$ctr" ] && command -v ctr >/dev/null 2>&1; then ctr="ctr"; fi
  if [ -z "$ctr" ]; then
    echo "清单引用的镜像（仓库侧）："
    echo "$refs" | sed 's/^/  /'
    echo
    echo "没能验到：本机没有 k3s ctr / ctr（镜像存在性只能在部署机上查）"
    return 2
  fi

  local have; have=$($ctr -n k8s.io images ls 2>/dev/null | awk '{print $1}' | sed 's|^docker.io/||' | sort -u || true)
  local missing="" m
  for m in $refs; do
    echo "$have" | grep -qx "$m" || missing="$missing $m"
  done

  if [ -z "$missing" ]; then
    echo "清单引用的 $(echo "$refs" | wc -l | tr -d ' ') 个镜像 tag 都存在于本机 containerd。"
    return 0
  fi
  echo "⚠ 清单引用了、但本机 containerd 里没有的镜像:"
  for m in $missing; do echo "    $m"; done
  echo
  echo "补建：/opt/g41/k8s/host/g41-image-build.sh   （不带参数 = 全部已部署模块）"
  echo "装出来会怎样：apply 之后 Pod 变 ImagePullBackOff，而 Deployment 看起来是好的。"
  return 1
}

# 卸载（2026-11-10）：k8s 原生。
#
# 三件事必须一起说清楚，否则「删了」会是个错觉：
#   1. 删 k8s 对象（按导出包 delete）
#   2. 重生成内容种子并**排除**该模块 —— 配合 server.js 的过期键清理，
#      重载后 Redis 里那份也会掉
#   3. **仓库里该模块还在**：下一次 CD 会把它装回来。真要移除，得先删模块目录。
kits_uninstall() {
  local m="" dry="" force=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) dry="1";;
      --force) force="1";;
      -*) echo "ERROR: unknown flag $1"; return 1;;
      *) m="$1";;
    esac
    shift
  done
  [ -n "$m" ] || { echo "ERROR: module name required"; return 1; }
  [ -f "kits/$m/info.json" ] || { echo "ERROR: 模块 '$m' 不存在"; return 1; }
  [ "$(backend_get)" = "k8s" ] || { echo "ERROR: backend=$(backend_get) —— uninstall 只实现 k8s 路径（没能验到）"; return 2; }

  # 反向依赖检查（2026-11-12）：删掉一个别人依赖的模块，坏的不是这台机器，
  # 是依赖它的那些服务——而它们的 Pod 会继续 Running，直到下一次启动/重连才发现。
  local rd="" d
  for d in kits/*/; do
    local other; other=$(basename "$d")
    [ "$other" = "$m" ] && continue
    [ -f "$d/info.json" ] || continue
    jq -r '.depends[]?' "$d/info.json" 2>/dev/null | grep -qx "$m" && rd="$rd $other"
  done
  if [ -n "$rd" ] && [ -z "$force" ]; then
    echo "ERROR: 这些模块依赖 '$m':$rd"
    echo "       删掉它会破坏它们，而它们的 Pod 现在仍然显示 Running。"
    echo "       确认要删请加 --force。"
    return 1
  fi
  [ -n "$rd" ] && echo "⚠ 强制卸载：$rd 依赖此模块，它们会受影响"

  local ver; ver=$(kit_version "$m")
  if ! kits_export "$m" >/dev/null 2>&1; then
    echo "ERROR: 导出包失败，未做任何删除"; return 1
  fi
  local bundle="dist/$m-$ver.yaml"
  [ -f "$bundle" ] || { echo "ERROR: 找不到 $bundle"; return 1; }

  echo "将要删除的对象（$bundle）："
  grep -E '^kind:|^  name:' "$bundle" | paste - - 2>/dev/null | sed 's/^/  /' || true

  if [ -n "$dry" ]; then
    echo
    echo "未执行：这是 --dry-run。真正执行会 kubectl delete 上面这些对象。"
    return 0
  fi

  command -v kubectl >/dev/null 2>&1 || { echo "ERROR: 找不到 kubectl —— 没能验到"; return 2; }
  kubectl delete -f "$bundle" --ignore-not-found 2>&1 | tail -4
  echo
  echo "=== 重生成内容种子（排除 $m）==="
  kits_content --exclude "$m" || return 1
  kubectl apply -f dist/g41-content.yaml 2>&1 | tail -1
  echo
  echo "⚠ 仓库里 $m 仍在：下一次 CD 的 k8s apply --all 会把它装回来。"
  echo "  真要移除：删掉 kits/$m/ 并提交。"
  echo "  要让 Redis 立刻掉键：DEL data:loaded 并重启 redis Pod（装载时会清理过期键）。"
}

# 生产体检（2026-11-11）。
#
# 这些检查以前分散在四个地方、全靠人记得跑：镜像在不在、Pod 有没有比内容旧、
# 内容种子与仓库是否逐键一致、api 源码是不是仓库那份。
# 每一条单独都能「看起来没事」——比如内容种子少了一个键，页面只是少一块。
#
# 三种结果不合并：0 = 全绿；1 = 有失败；2 = 有「没能验到」且无失败（失败优先）。
# 内容种子的键名 → 仓库源文件。抽出来是为了能被自检（2026-11-11：
# 第一版没先剥 `.json` 就切，把 `i18n.tile_mail.zh.json` 的模块名取成了
# `tile_mail.zh`，于是所有 i18n 键都报「没有对应的源文件」——判据当场错了，
# 而它错的表现是「满屏警告」，看起来反而像系统坏了）。
# 从各 provider 的 provides 生成映射 JSON（与 kits content 发给容器的 `_map.json` 同源）。
# 缓存到文件，因为体检要按 60 多个键逐条查，每条跑一次 jq 太浪费。
seed_map_json() {
  local cache="${TMPDIR:-/tmp}/g41-seedmap.$$"
  if [ -f "$cache" ]; then cat "$cache"; return 0; fi
  local ent; ent=$(mktemp)
  : > "$ent"
  local d dep t dir f e
  for d in kits/*/; do
    [ -f "$d/info.json" ] || continue
    for dep in $(jq -r '.depends[]?' "$d/info.json" 2>/dev/null || true) "$(basename "$d")"; do
      [ -f "kits/$dep/info.json" ] || continue
      jq -r '.provides[]? | select(.accepts != null and .content == true) | "\(.accepts[0])\t\(.dir // "")\t\(.file // "")\t\(.ext // "json")\t\(if (.file // "" | test("\\.")) then "file" else "dir" end)"' \
        "kits/$dep/info.json" 2>/dev/null >> "$ent"
    done
  done
  sort -u "$ent" | awk -F'\t' '!seen[$1]++' | jq -R -s '
    split("\n") | map(select(length > 0)) | map(split("\t"))
    | map({type:.[0], dir:(if .[1] == ".rd/data" then "" else .[1] end), file:.[2], ext:.[3], shape:.[4]})
    | map({key:.type, value:{dir:.dir, file:.file, ext:.ext, shape:.shape}}) | from_entries
  ' > "$cache" 2>/dev/null
  rm -f "$ent"
  cat "$cache"
}

# 内容种子的键名 → 仓库源文件。**走同一份映射**（2026-11-12）：
# 之前这里另存了一套硬编码 case，映射变了它不跟——而且它自己写错过一次
# （没先剥 .json，把所有 i18n 键判成「没有源文件」）。
seed_key_src() {
  local key="$1"
  [ "$key" = "_map.json" ] && return 1
  local map type rest shape file mod extra
  map=$(seed_map_json) || return 1
  type="${key%%.*}"; rest="${key#*.}"; rest="${rest%.json}"
  shape=$(printf '%s' "$map" | jq -r --arg t "$type" '.[$t].shape // empty' 2>/dev/null)
  file=$(printf '%s' "$map" | jq -r --arg t "$type" '.[$t].file // empty' 2>/dev/null)
  [ -n "$shape" ] || return 1
  [ -n "$file" ] || return 1
  if [ "$shape" = "file" ]; then
    # 文件形状：键里不该再有额外段
    case "$rest" in *.*) return 1;; esac
    echo "kits/$rest/$file"
  else
    mod="${rest%%.*}"; extra="${rest#*.}"
    [ "$mod" != "$extra" ] || return 1
    echo "kits/$mod/$file/$extra.json"
  fi
}

kits_health() {
  local failed=0 unverified=0
  if [ "${1:-}" = "--self-test" ]; then
    local n=0 bad=0 got want
    while IFS='|' read -r key want; do
      [ -n "$key" ] || continue
      n=$((n+1)); got=$(seed_key_src "$key" 2>/dev/null || echo "-")
      [ "$got" = "$want" ] || { echo "  ✘ $key → $got（期望 $want）"; bad=$((bad+1)); }
    done <<'MAP'
tile.dns.json|kits/dns/tile.json
app.aria2.json|kits/aria2/app.json
link.link_vscode.json|kits/link_vscode/link.json
i18n.tile_mail.zh.json|kits/tile_mail/i18n/zh.json
data.home.colors.json|kits/home/data/colors.json
MAP
    local u; u=$(seed_key_src "nonsense" 2>/dev/null || true)
    [ -z "$u" ] || { echo "  ✘ 无法映射的键本应返回空：$u"; bad=$((bad+1)); }
    n=$((n+1))
    if [ "$bad" -eq 0 ]; then echo "键名映射 $n 项通过"; return 0; fi
    echo "键名映射失败 $bad 项"; return 1
  fi
  echo "=== 1/5 镜像存在性 ==="
  kits_images --verify
  case $? in 0) ;; 2) unverified=$((unverified+1));; *) failed=$((failed+1));; esac

  echo
  echo "=== 2/5 内容比进程新（drift）==="
  k8s_drift
  case $? in 0) ;; 2) unverified=$((unverified+1));; *) failed=$((failed+1));; esac

  echo
  echo "=== 3/5 内容种子与仓库逐键一致 ==="
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "  没能验到：找不到 kubectl"; unverified=$((unverified+1))
  else
    local cmjson; cmjson=$(kubectl get cm g41-content -n g41 -o json 2>/dev/null) || cmjson=""
    if [ -z "$cmjson" ]; then
      echo "  没能验到：读不到 g41-content"; unverified=$((unverified+1))
    else
      local bad=0 checked=0 key b64 src want got
      while IFS=' ' read -r key b64; do
        [ -n "$key" ] || continue
        # _map.json 是映射本身，不是内容 —— 跳过而不是「无法映射」
        [ "$key" = "_map.json" ] && continue
        # 键名 → 仓库源文件：单一来源在 seed_key_src（它有自检）
        if ! src=$(seed_key_src "$key"); then
          echo "  ⚠ 无法映射的键: $key"; bad=$((bad+1)); continue
        fi
        [ -f "$src" ] || { echo "  ⚠ 键 $key 没有对应的源文件（$src）"; bad=$((bad+1)); continue; }
        want=$(sha256sum "$src" | awk '{print $1}')
        got=$(printf '%s' "$b64" | base64 -d 2>/dev/null | sha256sum | awk '{print $1}')
        checked=$((checked+1))
        [ "$want" = "$got" ] || { echo "  ⚠ $key 与 $src 内容不同"; bad=$((bad+1)); }
      done < <(echo "$cmjson" | jq -r '.data | to_entries[] | "\(.key) \(.value|@base64)"' 2>/dev/null)
      if [ "$bad" -eq 0 ]; then
        echo "  $checked 个键与仓库逐字节一致"
      else
        failed=$((failed+1))
      fi
    fi
  fi

  echo
  echo "=== 4/5 api 源码与仓库一致 ==="
  if command -v kubectl >/dev/null 2>&1 && [ -f kits/redis/store/server.js ]; then
    local cm_sha local_sha
    cm_sha=$(kubectl get cm g41-api-src -n g41 -o jsonpath='{.data.server\.js}' 2>/dev/null | sha256sum | awk '{print $1}')
    local_sha=$(sha256sum kits/redis/store/server.js | awk '{print $1}')
    if [ "$cm_sha" = "$local_sha" ]; then
      echo "  server.js 与仓库一致"
    else
      echo "  ⚠ 集群里的 server.js 与仓库不同（集群 ${cm_sha:0:12} / 仓库 ${local_sha:0:12}）"
      failed=$((failed+1))
    fi
  else
    echo "  没能验到：缺 kubectl 或源文件"; unverified=$((unverified+1))
  fi

  echo
  echo "=== 5/5 站点可访问性 ==="
  # 前四项查的是「仓库与集群是否一致」，它们全绿而站点挂掉是完全可能的
  # （nginx 挂了、证书过期、upstream 没起来）。所以必须有一条真的发请求。
  local dom=""
  [ -f .env ] && dom=$(grep '^G41_DOMAIN=' .env 2>/dev/null | cut -d= -f2- | tr -d '"')
  if [ -z "$dom" ]; then
    echo "  没能验到：.env 里没有 G41_DOMAIN"; unverified=$((unverified+1))
  elif ! command -v curl >/dev/null 2>&1; then
    echo "  没能验到：找不到 curl"; unverified=$((unverified+1))
  else
    local p code urls_ok=0 urls_bad=0
    # 端点必须覆盖**前端真正会请求的那些**（2026-11-12 事故）：
    # 那天 `/` 与 `/data/tiles` 都是 200，但 `/data/home/status` 是 404 的 HTML，
    # 前端 JSON.parse 直接报错、整页打不开。体检当时报绿——因为查的位置不对。
    # 这份清单来自 `/js/G41.js` 里的实际请求。
    for p in "/" "/data/tiles" "/data/i18n_zh" "/data/home/status" "/data/home/chars"; do
      # curl 失败时自己就会输出 000，不能再 `|| echo 000` —— 那会拼成 000000。
      code=$(curl -s -k -o /dev/null -w '%{http_code}' --max-time 10 "https://$dom$p" 2>/dev/null || true)
      [ -n "$code" ] || code="000"
      if [ "$code" = "200" ]; then
        urls_ok=$((urls_ok+1))
      else
        echo "  ⚠ https://$dom$p → $code（期望 200）"
        urls_bad=$((urls_bad+1))
      fi
    done
    if [ "$urls_bad" -eq 0 ]; then
      echo "  $urls_ok 个端点返回 200"
    else
      failed=$((failed+1))
    fi
  fi

  echo
  if [ "$failed" -gt 0 ]; then
    echo "体检：**失败 $failed 项**（其中没能验到 $unverified 项）"
    return 1
  fi
  if [ "$unverified" -gt 0 ]; then
    echo "体检：没有失败，但 **$unverified 项没能验到** —— 这不是通过"
    return 2
  fi
  echo "体检：五项全部通过"
  return 0
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
  kubectl apply --validate=false -f "dist/$m-$target.yaml" || return 1
  # 2026-11-10 实测：回滚只改集群，**不改仓库**。集群退回 1.0.0 而
  # kits/<m>/info.json 仍是 1.1.0 时，下一次 CD 的 k8s apply --all 会按仓库
  # 把它改回 1.1.0——回滚看起来生效了，然后自己悄悄失效。
  local repo_ver; repo_ver=$(kit_version "$m")
  if [ "$repo_ver" != "$target" ]; then
    echo
    echo "⚠ 集群已回到 $target，但仓库里是 $repo_ver。"
    echo "  下一次 CD 会按仓库把集群改回 $repo_ver。要固化这次回滚："
    echo "    ./g41.sh kits update $m --to $target --build   （然后在部署机上 build 并提交）"
  fi
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
        status) shift 2; kits_status "$@";;
        install) shift 2; kits_install "$@";;
        images) shift 2; kits_images "$@";;
        uninstall) shift 2; kits_uninstall "$@";;
        health) shift 2; kits_health "$@";;
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
