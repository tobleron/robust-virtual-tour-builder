#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ARGS=()
if [ "${START_RESET_TARGET:-0}" = "1" ]; then
  ARGS+=("--reset-target")
fi

node scripts/start-local-builder.mjs "${ARGS[@]}" "$@"
