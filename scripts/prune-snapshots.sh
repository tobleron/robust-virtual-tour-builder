#!/bin/bash

MAX_SNAPSHOTS=600
CURRENT_BRANCH=$(git branch --show-current)
SNAPSHOT_BRANCH="local-snapshots/$CURRENT_BRANCH"
ARCHIVE_PREFIX="local-snapshots/archive/${CURRENT_BRANCH}"

# 1. Check if snapshot branch exists
if ! git show-ref --verify --quiet refs/heads/$SNAPSHOT_BRANCH; then
    # Snapshot branch doesn't exist yet, nothing to prune
    exit 0
fi

# 2. Count commits
COUNT=$(git rev-list --count $SNAPSHOT_BRANCH)

if [ "$COUNT" -lt "$MAX_SNAPSHOTS" ]; then
    # echo "✅ Snapshot count ($COUNT) is within limit ($MAX_SNAPSHOTS)."
    exit 0
fi

# 3. Rotate if limit exceeded
echo "🧹 Snapshot limit exceeded ($COUNT > $MAX_SNAPSHOTS). Rotating..."

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ARCHIVE_NAME="${ARCHIVE_PREFIX}_${TIMESTAMP}"

# Rename current snapshot branch to archive
git branch -m $SNAPSHOT_BRANCH $ARCHIVE_NAME
echo "📦 Archived old snapshots to: $ARCHIVE_NAME"

# Create new snapshot branch from current state
git branch $SNAPSHOT_BRANCH $CURRENT_BRANCH
echo "✨ Created fresh snapshot branch: $SNAPSHOT_BRANCH"

# 4. Optional: Clean up old archives (keep last 5)
# List archives, sort by time, skip last 5, delete rest
git branch --list "${ARCHIVE_PREFIX}_*" | sort | head -n -5 | while read -r branch; do
    # Trim whitespace
    branch=$(echo "$branch" | xargs)
    if [ -n "$branch" ]; then
        git branch -D "$branch"
        echo "🗑️  Deleted old archive: $branch"
    fi
done
