#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v cargo >/dev/null 2>&1; then
  echo "❌ cargo is required."
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "❌ npm is required."
  exit 1
fi

PORT="${PORT:-8080}"
DEV_AUTH_EMAIL_VALUE="${DEV_AUTH_EMAIL:-admin@dev.local}"
PORTAL_ADMIN_EMAILS_VALUE="${PORTAL_ADMIN_EMAILS:-$DEV_AUTH_EMAIL_VALUE}"

existing_listener="$(lsof -nP -iTCP:${PORT} -sTCP:LISTEN 2>/dev/null | tail -n +2 || true)"
if [[ -n "${existing_listener}" ]]; then
  existing_command="$(echo "${existing_listener}" | awk 'NR==1 {print $1}')"
  existing_pid="$(echo "${existing_listener}" | awk 'NR==1 {print $2}')"
  echo "ℹ️ Port ${PORT} is already in use by ${existing_command} (PID ${existing_pid})."
  if [[ "${existing_command}" == "backend" ]]; then
    echo "   The local portal/backend is likely already running."
    echo "   Open: http://127.0.0.1:${PORT}/portal-admin/signin"
    echo "   Or stop it first with: kill ${existing_pid}"
    exit 0
  else
    echo "   Stop that process or run with a different port, e.g.:"
    echo "   PORT=8081 ./scripts/run-portal.sh"
    exit 1
  fi
fi

echo "🧱 Building portal frontend..."
npm run build:portal

echo "🚀 Starting portal backend on http://127.0.0.1:${PORT}"
echo "   Admin allowlist: ${PORTAL_ADMIN_EMAILS_VALUE}"
echo "   Dev auth email:  ${DEV_AUTH_EMAIL_VALUE}"

cd backend
APP_SURFACE=portal \
APP_DIST_ROOT="$ROOT_DIR/dist-portal" \
DEV_AUTH_EMAIL="$DEV_AUTH_EMAIL_VALUE" \
PORTAL_ADMIN_EMAILS="$PORTAL_ADMIN_EMAILS_VALUE" \
PORT="$PORT" \
cargo run --bin portal --no-default-features --features portal-runtime
