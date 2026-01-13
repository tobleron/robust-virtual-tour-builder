#!/bin/bash

# Kill background processes on exit
trap "kill 0" EXIT

echo "--- Remax VTB Pure Rust Dev Environment ---"

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

# 1. Start Tailwind CSS Watcher (Standalone Binary)
if [ -f "./bin/tailwindcss" ]; then
    echo "[1/2] Starting Tailwind CSS Watcher (Standalone)..."
    chmod +x ./bin/tailwindcss
    ./bin/tailwindcss -i ./css/tailwind.css -o ./css/output.css --watch &
else
    echo "⚠️  Tailwind binary not found in ./bin/tailwindcss. CSS watching disabled."
    echo "Please download the standalone Tailwind CSS v4 CLI and place it at ./bin/tailwindcss"
fi

# 1.5. Start ReScript Watcher
echo "[1.5/2] Starting ReScript Watcher..."
if npm list rescript > /dev/null 2>&1 || [ -f "node_modules/.bin/rescript" ]; then
    npm run res:watch &
else
    echo "⚠️  ReScript not found. Please run 'npm install'."
fi


# 2. Start Backend with Cargo Watch
echo "[2/2] Starting Rust Backend (Watcher Mode)..."
export PATH="$PWD/backend/bin:$PATH"
cd backend

if command -v cargo-watch &> /dev/null; then
    echo "✅ cargo-watch found. Starting backend in RELEASE mode..."
    # cargo watch will restart the server whenever rust files change.
    # --release is critical for image processing performance
    RUST_LOG=info cargo watch -x "run --release"
else
    echo "❌ cargo-watch NOT found."
    echo "Please install it using: cargo install cargo-watch"
    echo "Falling back to standard release run (no auto-restart)."
    RUST_LOG=info cargo run --release
fi
