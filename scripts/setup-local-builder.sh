#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

detect_package_manager() {
  if command -v brew >/dev/null 2>&1; then
    echo "brew"
    return
  fi
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
    return
  fi
  echo ""
}

install_if_missing() {
  local cmd="$1"
  local manager="$2"
  local package_name="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "✅ $cmd is installed."
    return
  fi

  if [ -z "$manager" ]; then
    echo "❌ Missing $cmd and no supported package manager was found."
    echo "   Install the prerequisite manually, then rerun this script."
    exit 1
  fi

  echo "📦 Installing $cmd via $manager..."
  if [ "$manager" = "brew" ]; then
    brew install "$package_name"
    return
  fi

  sudo apt-get update
  sudo apt-get install -y "$package_name"
}

PACKAGE_MANAGER="$(detect_package_manager)"
if [ -z "$PACKAGE_MANAGER" ]; then
  echo "❌ Supported first-install package managers are Homebrew and apt."
  echo "   Install Node.js, Git, Rustup, and FFmpeg manually, then run node scripts/setup-local-builder.mjs"
  exit 1
fi

install_if_missing git "$PACKAGE_MANAGER" git
if [ "$PACKAGE_MANAGER" = "brew" ]; then
  install_if_missing node "$PACKAGE_MANAGER" node
else
  install_if_missing node "$PACKAGE_MANAGER" nodejs
  install_if_missing npm "$PACKAGE_MANAGER" npm
fi
install_if_missing ffmpeg "$PACKAGE_MANAGER" ffmpeg

if ! command -v cargo >/dev/null 2>&1; then
  echo "📦 Installing rustup..."
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
fi

node scripts/setup-local-builder.mjs "$@"
