#!/usr/bin/env bash
# 本地私有内容（.gitignore，不经 GitHub）→ VPS，经本地 SSH 配置
# 用法：./deploy-local.sh [SSH别名] [远程路径]
# 默认 SSH 别名 G41（~/.ssh/config）、远程 /root/G41KiTS
set -e -o pipefail
HOST="${1:-G41}"
REMOTE="${2:-/root/G41KiTS}"
cd "$(dirname "$0")"

INCLUDES=(
  --include='/.env'
  --include='/.local.sh'
  --include='/.local/***'
  --include='/kits/*/.local/***'
)

echo "== dry-run（仅预览）=="
rsync -avn "${INCLUDES[@]}" --exclude='*' ./ "$HOST:$REMOTE/"

echo
read -r -p "确认同步以上私有内容？(y/N) " ans
[ "$ans" = "y" ] || { echo "已取消"; exit 0; }

rsync -av "${INCLUDES[@]}" --exclude='*' ./ "$HOST:$REMOTE/"
echo "私有内容已推送。"
