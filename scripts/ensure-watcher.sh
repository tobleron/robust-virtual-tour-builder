#!/bin/bash
# Check if the watcher process is running (searching for the script name)
if pgrep -f "scripts/dev-mode.sh" > /dev/null; then
    echo "✅ Snapshot Watcher is already running."
else
    echo "👁️  Watcher not found. Starting it now..."
    ./scripts/dev-mode.sh &
    echo "✅ Snapshot Watcher started in background."
fi
