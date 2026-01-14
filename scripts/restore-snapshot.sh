#!/bin/bash
# USAGE: ./scripts/restore-snapshot.sh [OPTIONAL_HASH]

CURRENT_BRANCH=$(git branch --show-current)
SNAPSHOT_BRANCH="local-snapshots/$CURRENT_BRANCH"

# 1. Verify Shadow Branch
if ! git show-ref --verify --quiet refs/heads/$SNAPSHOT_BRANCH; then
    echo "❌ No snapshots found. (Is dev-mode.sh running?)"
    exit 1
fi

# 2. AI MODE (Non-Interactive)
if [ -n "$1" ]; then
    TARGET_HASH=$1
    echo "🤖 AI Auto-Restore initiated for hash: $TARGET_HASH"
    if git restore --source=$TARGET_HASH .; then
        echo "✅ Success! Files restored to $TARGET_HASH."
        exit 0
    else
        echo "❌ Restore failed. Invalid hash?"
        exit 1
    fi
fi

# 3. HUMAN MODE (Interactive Menu)
echo "📼 Security Footage for '$CURRENT_BRANCH':"
echo "--------------------------------------------------------"
git log $SNAPSHOT_BRANCH -n 20 --date=format:'%Y-%m-%d %H:%M:%S' --pretty=format:"%C(yellow)%h%Creset - %C(cyan)%cd%Creset - %C(green)%cr%Creset"
echo "--------------------------------------------------------"

echo "Enter Hash to restore:"
read -p "> " COMMIT_HASH
if [ -z "$COMMIT_HASH" ]; then echo "❌ Cancelled."; exit 1; fi

echo "⚠️  Overwriting current files with state from $COMMIT_HASH."
read -p "Are you sure? (y/N) " CONFIRM
if [[ $CONFIRM != "y" ]]; then exit 0; fi

echo "↺ Restoring..."
git restore --source=$COMMIT_HASH .
echo "✅ Done."
