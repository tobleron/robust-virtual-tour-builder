#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "❌ git is required."
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [ "$CURRENT_BRANCH" != "development" ]; then
  echo "🔀 Switching branch: $CURRENT_BRANCH -> development"
  git checkout development
else
  echo "✅ Already on development branch."
fi

echo "🔖 Syncing version metadata for current branch..."
node scripts/update-version.js

echo "🛠️ Running setup checks..."
./scripts/setup.sh
