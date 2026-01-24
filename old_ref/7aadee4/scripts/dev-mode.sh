#!/bin/bash
# USAGE: ./scripts/dev-mode.sh &
echo "👁️  Starting AntiGravity Snapshot Watcher..."

# Start Project Guard in background
./scripts/project-guard.sh &
SENTINEL_PID=$!
# Kill sentinel when this script exits
trap "kill $SENTINEL_PID" EXIT

# Prune/Rotate old snapshots on startup
./scripts/prune-snapshots.sh

CURRENT_BRANCH=$(git branch --show-current)
SNAPSHOT_BRANCH="local-snapshots/$CURRENT_BRANCH"

# Initialize shadow branch pointer if missing
if ! git show-ref --verify --quiet refs/heads/$SNAPSHOT_BRANCH; then
    echo "Initializing shadow branch: $SNAPSHOT_BRANCH"
    git branch $SNAPSHOT_BRANCH $CURRENT_BRANCH
fi

# Watch loop
fswatch -o ./src ./backend/src | while read f; do
    git add .
    TREE=$(git write-tree)
    # Create commit on shadow branch
    COMMIT=$(echo "Auto-snapshot: $(date '+%H:%M:%S')" | git commit-tree $TREE -p $SNAPSHOT_BRANCH)
    # Update shadow ref
    git update-ref refs/heads/$SNAPSHOT_BRANCH $COMMIT
    echo "📸 Snapshot saved to $SNAPSHOT_BRANCH at $(date '+%H:%M:%S')"
done
