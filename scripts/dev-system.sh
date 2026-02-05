#!/bin/bash
# Architectural Governor Watcher v1.0

echo "🚀 Starting Architectural Governor Watcher..."

# Cleanup logs on startup
./scripts/cleanup_logs.sh

# Check if cargo-watch is installed for high performance
if command -v cargo-watch >/dev/null 2>&1; then
    cd _dev-system/analyzer && cargo watch -w src -w ../config -s "cargo run --release"
else
    # Fallback to simple loop
    echo "⚠️ cargo-watch not found. Using simple loop fallback."
    while true; do
        cd _dev-system/analyzer && cargo run --release --quiet
        cd ../..
        sleep 5
    done
fi
