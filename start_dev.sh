#!/bin/bash

# Kill background processes on exit
trap "kill 0" EXIT

echo "--- Remax VTB Pure Rust Dev Environment ---"

# Pre-flight: Basic dependency check
if [ ! -d "node_modules" ]; then
    echo "⚠️  node_modules not found. Running initial setup..."
    ./scripts/setup.sh
fi

# Pre-flight: Clean up existing processes on dev ports
echo "Checking for stale processes on port 8080..."

for port in 8080; do
    PID=$(lsof -ti :$port)
    if [ ! -z "$PID" ]; then
        echo "Cleaning up process $PID on port $port..."
        kill -9 $PID 2>/dev/null
    fi
done
sleep 1

# [NEW] 0. Start Safety Net (Snapshot Watcher)
echo "[0/2] Initializing AntiGravity Safety Net..."
./scripts/ensure-watcher.sh

# 1. Start Tailwind CSS Watcher
echo "[1/2] Starting Tailwind CSS Watcher..."
if npm list tailwindcss > /dev/null 2>&1 || [ -f "node_modules/.bin/tailwindcss" ]; then
    npm run css:watch &
elif [ -f "./bin/tailwindcss" ]; then
    echo "ℹ️  Using local tailwind binary fallback."
    ./bin/tailwindcss -i ./css/tailwind.css -o ./css/output.css --watch &
else
    echo "⚠️  Tailwind not found. Please run './scripts/setup.sh'."
fi


# 1.5. Start ReScript Watcher
echo "[1.5/2] Starting ReScript Watcher..."
if npm list rescript > /dev/null 2>&1 || [ -f "node_modules/.bin/rescript" ]; then
    npm run res:watch &
else
    echo "⚠️  ReScript not found. Run 'npm install'."
fi

# 2. Start Backend
echo "[2/2] Starting Rust Backend..."
export PATH="$PWD/backend/bin:$PATH"
cd backend
if command -v cargo-watch &> /dev/null; then
    RUST_LOG=info cargo watch -x "run --release"
else
    RUST_LOG=info cargo run --release
fi
