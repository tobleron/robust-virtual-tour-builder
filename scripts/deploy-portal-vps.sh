#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_USER="${PORTAL_VPS_USER:-root}"
REMOTE_HOST="${PORTAL_VPS_HOST:-}"
REMOTE_APP_DIR="${PORTAL_VPS_APP_DIR:-/opt/robust-vtb/current}"
REMOTE_SERVICE="${PORTAL_VPS_SERVICE:-robust-vtb-portal}"
REMOTE_RESET_TARGET="${PORTAL_REMOTE_RESET_TARGET:-0}"
REMOTE_HEALTH_URL="${PORTAL_VPS_HEALTH_URL:-http://127.0.0.1:8080/api/health}"
REMOTE_INSTALL_CMD="${PORTAL_VPS_INSTALL_CMD:-npm install}"
REMOTE_BUILD_SCRIPT="${PORTAL_VPS_BUILD_SCRIPT:-/root/scripts/robust-vtb-full-build.sh}"
REMOTE_RUNTIME_USER="${PORTAL_VPS_RUNTIME_USER:-robustvtb}"
REMOTE_SSH_KEY="${PORTAL_VPS_SSH_KEY:-}"
REMOTE_SSH_OPTS="${PORTAL_VPS_SSH_OPTS:-}"

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
SSH_CMD=(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new)
if [[ -n "$REMOTE_SSH_KEY" ]]; then
  SSH_CMD+=(-i "$REMOTE_SSH_KEY")
fi
if [[ -n "$REMOTE_SSH_OPTS" ]]; then
  # shellcheck disable=SC2206
  EXTRA_SSH_OPTS=($REMOTE_SSH_OPTS)
  SSH_CMD+=("${EXTRA_SSH_OPTS[@]}")
fi

if ! "${SSH_CMD[@]}" "$REMOTE" "exit 0" >/dev/null 2>&1; then
  echo "[portal-deploy] SSH to $REMOTE is unavailable on port 22. Check sshd/firewall on the VPS before retrying." >&2
  exit 1
fi

echo "[portal-deploy] Host: $REMOTE"
echo "[portal-deploy] App dir: $REMOTE_APP_DIR"
if [[ -n "$REMOTE_SSH_KEY" ]]; then
  echo "[portal-deploy] SSH key: $REMOTE_SSH_KEY"
fi

read -r -d '' REMOTE_BUILD <<'EOF' || true
set -euo pipefail
cd "$REMOTE_APP_DIR"

if [[ "$REMOTE_RESET_TARGET" == "1" ]]; then
  rm -rf backend/target
fi

echo "[portal-deploy] Installing frontend dependencies..."
eval "$REMOTE_INSTALL_CMD"

echo "[portal-deploy] Running portal build script..."
if [[ -x "$REMOTE_BUILD_SCRIPT" ]]; then
  "$REMOTE_BUILD_SCRIPT"
else
  npm run build:portal
  cd backend
  APP_DIST_ROOT="$REMOTE_APP_DIR/dist-portal" \
  APP_SURFACE=portal \
  cargo build --release --bin portal --no-default-features --features portal-runtime
  cd "$REMOTE_APP_DIR"
fi

rm -f /root/robust-vtb-portal-deploy-*.tgz || true
npm cache clean --force || true
apt-get clean || true

mkdir -p "$REMOTE_APP_DIR/cache"
chown -R "$REMOTE_RUNTIME_USER:$REMOTE_RUNTIME_USER" "$REMOTE_APP_DIR/cache"

echo "[portal-deploy] Restarting $REMOTE_SERVICE..."
systemctl restart "$REMOTE_SERVICE"

echo "[portal-deploy] Service status:"
systemctl --no-pager --full status "$REMOTE_SERVICE" | sed -n '1,20p'

echo "[portal-deploy] Health check:"
for attempt in $(seq 1 20); do
  if curl --fail --silent --show-error "$REMOTE_HEALTH_URL"; then
    echo
    break
  fi
  if [[ "$attempt" -eq 20 ]]; then
    echo "[portal-deploy] Health check failed after $attempt attempts." >&2
    systemctl --no-pager --full status "$REMOTE_SERVICE" | sed -n '1,30p' >&2 || true
    journalctl -u "$REMOTE_SERVICE" -n 50 --no-pager >&2 || true
    exit 1
  fi
  echo "[portal-deploy] Health check not ready yet (attempt $attempt/20); retrying..."
  sleep 2
done
EOF

mkdir -p "$ROOT_DIR/.tmp"

echo "[portal-deploy] Syncing source to $REMOTE..."

RSYNC_RSH="${SSH_CMD[*]}"
rsync -az --delete \
  -v \
  -e "$RSYNC_RSH" \
  --exclude '.git' \
  --exclude '.DS_Store' \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude '.agent' \
  --exclude '.claude' \
  --exclude '.gemini' \
  --exclude '.github' \
  --exclude '.vscode' \
  --exclude 'artifacts' \
  --exclude 'docs' \
  --exclude 'cypress' \
  --exclude 'cache' \
  --exclude 'data' \
  --exclude 'lib/bs' \
  --exclude 'node_modules' \
  --exclude 'backend/target' \
  --exclude '_dev-system' \
  --exclude 'dist' \
  --exclude 'dist-portal' \
  --exclude 'backend/data' \
  --exclude 'backend/logs' \
  --exclude 'backend/temp' \
  --exclude 'playwright-report' \
  --exclude 'test-results' \
  --exclude 'tests/cypress/videos' \
  --exclude '*.mp4' \
  --exclude '*.webm' \
  --exclude '.tmp' \
  "$ROOT_DIR"/ "$REMOTE:$REMOTE_APP_DIR/"

echo "[portal-deploy] Running remote build/restart..."

"${SSH_CMD[@]}" "$REMOTE" \
  "REMOTE_APP_DIR='$REMOTE_APP_DIR' REMOTE_SERVICE='$REMOTE_SERVICE' REMOTE_RESET_TARGET='$REMOTE_RESET_TARGET' REMOTE_HEALTH_URL='$REMOTE_HEALTH_URL' REMOTE_INSTALL_CMD='$REMOTE_INSTALL_CMD' REMOTE_BUILD_SCRIPT='$REMOTE_BUILD_SCRIPT' REMOTE_RUNTIME_USER='$REMOTE_RUNTIME_USER' bash -s" \
  <<<"$REMOTE_BUILD"

echo "[portal-deploy] Done."
