#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Remax VTB Setup..."

# 1. Check for Prerequisites
echo "🔍 Checking prerequisites..."

check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ $1 is not installed. Please install it before proceeding."
        exit 1
    else
        echo "✅ $1 is installed."
    fi
}

check_cmd node
check_cmd npm
check_cmd cargo
check_cmd ffmpeg
check_cmd fswatch

# 2. Install Node Dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# 3. Build ReScript (if not already watching)
if ! pgrep -f "rescript watch" > /dev/null; then
    echo "🏗️ Building ReScript modules..."
    npm run res:build
else
    echo "✅ ReScript watcher already running, skipping build."
fi

# 4. Check for Optional Tools
if ! command -v cargo-watch &> /dev/null; then
    echo "⚠️  cargo-watch is not installed."
    echo "💡 Run 'cargo install cargo-watch' for a better backend dev experience."
fi

# 5. Ensure directories exist
echo "📁 Preparing directory structure..."
mkdir -p logs bin dist/static dist/images
touch logs/.gitkeep dist/index.html dist/service-worker.js dist/manifest.json dist/asset-manifest.json

# 6. Cleanup stale ports (8080 for backend, 3000 for frontend)
echo "🧹 Cleaning up stale ports..."
lsof -ti:8080,3000 | xargs kill -9 2>/dev/null || true

# 7. Start Snapshot Watcher
echo "👁️  Initializing Snapshot Watcher..."
./scripts/ensure-watcher.sh

echo ""
echo "✨ Environment Ready!"
echo "🚀 Run 'npm run dev' to start development"
echo ""
