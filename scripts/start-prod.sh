#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "❌ git is required."
  exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "❌ cargo is required."
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "❌ npx is required."
  exit 1
fi

stop_processes() {
  local pattern="$1"
  local label="$2"
  local pids=""
  pids="$(pgrep -f "$pattern" || true)"
  if [ -n "$pids" ]; then
    echo "🛑 Stopping $label: $pids"
    # Send SIGTERM first for graceful shutdown
    # shellcheck disable=SC2086
    kill $pids || true
    # Wait up to 5 seconds for graceful termination
    local wait_count=0
    while [ $wait_count -lt 5 ]; do
      sleep 1
      # Check if all processes are gone
      local remaining=""
      remaining="$(pgrep -f "$pattern" || true)"
      if [ -z "$remaining" ]; then
        break
      fi
      wait_count=$((wait_count + 1))
    done
    # Force kill any remaining processes with SIGKILL
    local remaining=""
    remaining="$(pgrep -f "$pattern" || true)"
    if [ -n "$remaining" ]; then
      echo "🛑 Force killing remaining $label: $remaining"
      # shellcheck disable=SC2086
      kill -9 $remaining || true
      sleep 1
    fi
  fi
}

stop_port_listener() {
  local port="$1"
  local pids=""
  pids="$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  if [ -n "$pids" ]; then
    echo "🛑 Releasing port $port: $pids"
    # Use SIGKILL to ensure port is released immediately
    # shellcheck disable=SC2086
    kill -9 $pids || true
    # Wait for port to be fully released
    sleep 2
  fi
}

wait_for_backend() {
  local attempts=90
  local n=1
  while [ $n -le $attempts ]; do
    if curl -fsS "http://localhost:8080/api/health" >/dev/null 2>&1; then
      echo "✅ Backend health check passed."
      return 0
    fi

    if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
      echo "❌ Backend exited before becoming ready."
      return 1
    fi

    if [ $((n % 10)) -eq 0 ]; then
      echo "⏳ Waiting for backend health... (${n}s)"
    fi
    sleep 1
    n=$((n + 1))
  done

  echo "❌ Backend did not become healthy in time."
  return 1
}

cleanup() {
  local code=$?
  if [ -n "${SERVE_PID:-}" ] && kill -0 "$SERVE_PID" >/dev/null 2>&1; then
    kill "$SERVE_PID" >/dev/null 2>&1 || true
  fi
  if [ -n "${BACKEND_PID:-}" ] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
  fi
  exit $code
}

CURRENT_BRANCH="$(git branch --show-current)"
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "🔀 Switching branch: $CURRENT_BRANCH -> main"
  git checkout main
else
  echo "✅ Already on main branch."
fi

echo "🔖 Syncing version metadata for current branch..."
node scripts/update-version.js

stop_processes 'rescript.*watch|rescript.*-w|cargo watch' "active dev watchers"
stop_processes 'cargo run --release|target/release/backend' "active backend runtime"
stop_processes 'rsbuild preview|serve dist -s -l 3000' "active frontend runtime"
stop_port_listener 8080
stop_port_listener 3000

echo "📦 Building production frontend..."
npm run build

echo "🚀 Starting production runtime (frontend preview proxy + backend release)..."
trap cleanup EXIT INT TERM

(cd backend && cargo run --release) &
BACKEND_PID=$!

wait_for_backend

# Use Rsbuild preview for local production parity; keeps /api proxy behavior.
# Force production mode so runtime flags (MODE/DEV) are not interpreted as development.
NODE_ENV=production npx rsbuild preview --mode production --port 3000 &
SERVE_PID=$!

wait
