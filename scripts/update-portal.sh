#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_SSH_KEY="$HOME/.ssh/robust_vps_ed25519"

if [[ -f "$DEFAULT_SSH_KEY" ]]; then
  PORTAL_VPS_SSH_KEY_VALUE="${PORTAL_VPS_SSH_KEY:-$DEFAULT_SSH_KEY}"
else
  PORTAL_VPS_SSH_KEY_VALUE="${PORTAL_VPS_SSH_KEY:-}"
fi

PORTAL_VPS_HOST="${PORTAL_VPS_HOST:-164.90.242.73}" \
PORTAL_VPS_USER="${PORTAL_VPS_USER:-root}" \
PORTAL_VPS_APP_DIR="${PORTAL_VPS_APP_DIR:-/opt/robust-vtb/current}" \
PORTAL_VPS_SERVICE="${PORTAL_VPS_SERVICE:-robust-vtb-portal}" \
PORTAL_VPS_HEALTH_URL="${PORTAL_VPS_HEALTH_URL:-http://127.0.0.1:8080/api/health}" \
PORTAL_VPS_BUILD_SCRIPT="${PORTAL_VPS_BUILD_SCRIPT:-/root/scripts/robust-vtb-portal-build.sh}" \
PORTAL_VPS_RUNTIME_USER="${PORTAL_VPS_RUNTIME_USER:-robustvtb}" \
PORTAL_VPS_SSH_KEY="$PORTAL_VPS_SSH_KEY_VALUE" \
"$ROOT_DIR/scripts/deploy-portal-vps.sh"
