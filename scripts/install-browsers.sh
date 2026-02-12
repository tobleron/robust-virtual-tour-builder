#!/bin/bash
set -euo pipefail

PLAYWRIGHT_CLI="npx playwright"

if ! command -v npx &> /dev/null; then
  echo "❌ npm/npmx is required to provision Playwright browsers. Please install Node.js and npm."
  exit 1
fi

PROVISIONED_BROWSERS=(chromium firefox webkit)
if [ "${PLAYWRIGHT_INSTALL_SKIP:-0}" = "1" ]; then
  echo "⚠️  Browser provisioning skipped via PLAYWRIGHT_INSTALL_SKIP=1."
  exit 0
fi

echo "🧱 Provisioning Playwright browsers: ${PROVISIONED_BROWSERS[*]}"
# Try to keep the output concise if already installed.
$PLAYWRIGHT_CLI install ${PROVISIONED_BROWSERS[*]} --with-deps

echo "✅ Playwright browsers are provisioned."
