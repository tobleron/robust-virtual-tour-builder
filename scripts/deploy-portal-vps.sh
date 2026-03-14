#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_USER="${PORTAL_VPS_USER:-root}"
REMOTE_HOST="${PORTAL_VPS_HOST:-}"
REMOTE_APP_DIR="${PORTAL_VPS_APP_DIR:-/opt/robust-vtb/current}"
REMOTE_SERVICE="${PORTAL_VPS_SERVICE:-robust-vtb-portal}"
REMOTE_RESET_TARGET="${PORTAL_REMOTE_RESET_TARGET:-0}"

if [[ -z "$REMOTE_HOST" ]]; then
  echo "PORTAL_VPS_HOST is required."
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required."
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "ssh is required."
  exit 1
fi

REMOTE="${REMOTE_USER}@${REMOTE_HOST}"

read -r -d '' REMOTE_BUILD <<'EOF' || true
set -euo pipefail
cd "$REMOTE_APP_DIR"

if [[ "$REMOTE_RESET_TARGET" == "1" ]]; then
  rm -rf backend/target
fi

npm install
npm run build:portal
cd backend
APP_DIST_ROOT="$REMOTE_APP_DIR/dist-portal" \
APP_SURFACE=portal \
cargo build --release --bin portal --no-default-features --features portal-runtime
cd "$REMOTE_APP_DIR"

rm -f /root/robust-vtb-portal-deploy-*.tgz || true
npm cache clean --force || true
apt-get clean || true
systemctl restart "$REMOTE_SERVICE"
systemctl --no-pager --full status "$REMOTE_SERVICE" | sed -n '1,20p'
EOF

mkdir -p "$ROOT_DIR/.tmp"

rsync -az --delete \
  --exclude '.git' \
  --exclude 'node_modules' \
  --exclude 'backend/target' \
  --exclude 'dist' \
  --exclude 'dist-portal' \
  --exclude 'backend/data' \
  --exclude 'backend/logs' \
  --exclude 'backend/temp' \
  --exclude 'playwright-report' \
  --exclude 'test-results' \
  --exclude '.tmp' \
  "$ROOT_DIR"/ "$REMOTE:$REMOTE_APP_DIR/"

ssh "$REMOTE" \
  "REMOTE_APP_DIR='$REMOTE_APP_DIR' REMOTE_SERVICE='$REMOTE_SERVICE' REMOTE_RESET_TARGET='$REMOTE_RESET_TARGET' bash -s" \
  <<<"$REMOTE_BUILD"
