#!/bin/bash
set -euo pipefail

BRANCH="${1:-$(git branch --show-current)}"

if [ "$BRANCH" != "main" ]; then
  exit 0
fi

echo "🔒 Running main-branch release guard..."

SEARCH_ROOTS=("backend/src" "src" "public")
MARKERS=(
  "ALLOW_DEV_AUTH_BOOTSTRAP"
  "DEV_AUTH_EMAIL"
  "DEV_AUTH_USERNAME"
  "DEV_AUTH_NAME"
  "DEV_AUTH_PASSWORD"
  "/api/auth/dev-login"
  "data-auth-dev-login"
  "Use Dev Account"
  "dev_bootstrap_login"
  "pub async fn dev_signin"
)

violations=""
for marker in "${MARKERS[@]}"; do
  match=$(rg -n -F --glob '!**/*.md' --glob '!**/*.sql' "$marker" "${SEARCH_ROOTS[@]}" || true)
  if [ -n "$match" ]; then
    violations="${violations}\n[marker] ${marker}\n${match}\n"
  fi
done

if [ -n "$violations" ]; then
  echo "❌ Main release guard blocked production-bound code."
  echo "   Dev-only authentication/bootstrap markers are present on 'main'."
  printf "%b" "$violations"
  echo
  echo "Required action:"
  echo "1. Keep dev-only auth/bootstrap work on development."
  echo "2. Promote only production-safe commits to main."
  echo "3. Do not mix dev-login shortcuts with production feature commits."
  exit 1
fi

echo "✅ Main release guard passed."
