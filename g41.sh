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
  echo "  kits simulate       Trace mode (--dry-run)"
  exit 0
}

kits_verify() {
  local m="$1" md="kits/$m" errors=0
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

  # compose include
  if grep -q "kits/$m/compose.yaml" compose.yaml 2>/dev/null; then
    echo "  [compose] compose.yaml include"
    found=$((found+1))
  fi

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

  # Compose include
  if [ -f "kits/$m/compose.yaml" ]; then
    if [ -n "$dry" ]; then
      echo "  [dry] compose include"
    else
      grep -q "kits/$m/compose.yaml" compose.yaml 2>/dev/null || {
        local last_ln
        last_ln=$(grep -n '^  - kits/' compose.yaml | tail -1 | cut -d: -f1)
        if [ -n "$last_ln" ]; then
          sed "${last_ln}a\  - kits/$m/compose.yaml" compose.yaml > compose.yaml.tmp && mv compose.yaml.tmp compose.yaml
        else
          # no existing module entries: append after include: line
          sed "/^include:/a\  - kits/$m/compose.yaml" compose.yaml > compose.yaml.tmp && mv compose.yaml.tmp compose.yaml
        fi
      }
      echo "  + compose include"
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

  kits_mark "$m" "add"
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

  # compose include
  if grep -q "kits/$m/compose.yaml" compose.yaml 2>/dev/null; then
    sed "\|kits/$m/compose.yaml|d" compose.yaml > compose.yaml.tmp && mv compose.yaml.tmp compose.yaml
    echo "  - compose include"; removed=$((removed+1))
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
  docker compose exec -T api wget -q -O- --post-data="{\"secret\":\"$secret\"}" http://127.0.0.1:5800/admin/reload 2>/dev/null || {
    echo "ERROR: Reload failed. Ensure api container is running."
    return 1
  }
  echo
  echo "Reload complete. Tiles, i18n, and links refreshed."
}

main() {
  case "${1:-}" in
    init)
      do_init
      ;;
    kits)
      case "${2:-}" in
        --help|-h) kits_help;;
        check) kits_check "$3";;
        verify) kits_verify "$3";;
        add) shift 2; kits_add "$@";;
        del) shift 2; kits_del "$@";;

        pack) shift 2; kits_pack "$@";;
        reload) kits_reload;;
        simulate) echo "Use: ./g41.sh kits add <name> --dry-run";;
        "") kits_list;;
        *) echo "Unknown kits command: $2"; kits_help;;
      esac
      ;;
    --help|-h)
      echo "Usage: $0 [init|kits|--help]"
      echo "  (no args)   Show G41 ASCII art"
      echo "  init        Run full server setup"
      echo "  kits        Module management"
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
