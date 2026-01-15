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

# 2. Install Node Dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# 3. Build ReScript
echo "🏗️ Building ReScript modules..."
npm run res:build

# 4. Check for Cargo-Watch (Optional but recommended)
if ! command -v cargo-watch &> /dev/null; then
    echo "⚠️  cargo-watch is not installed."
    echo "💡 Run 'cargo install cargo-watch' for a better backend dev experience."
fi

# 5. Ensure logs directory exists and is writable
echo "📁 Preparing log directory..."
mkdir -p logs
touch logs/.gitkeep

# 6. Ensure bin directory exists for local binaries
mkdir -p bin

echo "✅ Setup complete! You can now run 'npm run dev' to begin development (remember to start the backend too)."
