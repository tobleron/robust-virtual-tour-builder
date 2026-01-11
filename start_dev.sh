#!/bin/bash

# Kill background processes on exit
trap "kill 0" EXIT

echo "--- Remax VTB Dev Environment (Hot Reload Enabled) ---"

# Pre-flight: Clean up existing processes on dev ports
echo "Checking for stale processes on ports 8080 and 9999..."
for port in 8080 9999; do
    PID=$(lsof -ti :$port)
    if [ ! -z "$PID" ]; then
        echo "Cleaning up process $PID on port $port..."
        kill -9 $PID 2>/dev/null
    fi
done
sleep 1

# 1. Start Backend
echo "[1/3] Starting Rust Backend (Release Mode for Speed)..."
export PATH="$PWD/backend/bin:$PATH"
cd backend
# Using --release is critical for image processing performance in Rust
RUST_LOG=info cargo run --release > ../backend_log.txt 2>&1 &
BACKEND_PID=$!
cd ..

# Wait for backend to be ready
echo "Waiting for backend to compile and start..."
MAX_RETRIES=60
COUNT=0
while ! curl -s http://localhost:8080/health > /dev/null; do
    sleep 2
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "❌ Backend failed to start after 2 minutes. Check backend_log.txt"
        kill $BACKEND_PID 2>/dev/null
        exit 1
    fi
    printf "."
done
echo " ✅ Backend is UP!"

# 2. Start Tailwind CSS Watcher (Standalone Rust Binary)
echo "[2/3] Starting Tailwind CSS Watcher..."
./bin/tailwindcss -i ./css/tailwind.css -o ./css/output.css --watch &


# 3. Start Frontend with Vite (Hot Reload)
echo "[3/3] Starting Frontend with Vite on port 9999..."
npm run dev &

echo "------------------------------------------------"
echo "🚀 Remax VTB is ready!"
echo ""
echo "👉 Web Interface: http://localhost:9999"
echo "🛠️  API Backend:    http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop all services."
echo "------------------------------------------------"

wait
