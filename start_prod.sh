#!/bin/bash

# Kill background processes on exit
trap "kill 0" EXIT

echo "--- Robust Virtual Tour Builder Production Mode (Release Build) ---"

# Step 1: Build Backend in Release Mode
echo "[1/2] Building Rust Backend (Release Mode)..."
echo "This might take a while if dependencies are not cached..."
export PATH="$PWD/backend/bin:$PATH"
cd backend
cargo build --release
if [ $? -ne 0 ]; then
    echo "❌ Backend build failed."
    exit 1
fi
cd ..

# Step 2: Run the Release Binary
echo "[2/2] Starting Backend in Release Mode..."
# Note: The backend is configured to serve static files from ../
# So we don't necessarily need 'npm run build' unless we change main.rs to serve 'dist/'
# For now, we serve the source files but with the optimized backend engine.

./backend/target/release/backend
