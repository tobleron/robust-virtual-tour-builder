#!/bin/bash
# USAGE: ./scripts/fast-commit.sh "feat: Description" [target-branch] [bump-override]
# Optional third argument: 'major', 'minor', 'patch' to override auto-detection.
MSG="$1"

if [ -z "$MSG" ]; then echo "❌ Error: Commit message required."; exit 1; fi

# 0. Branch Guard
CURRENT_BRANCH=$(git branch --show-current)
TARGET_BRANCH="${2:-development}"
if [ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]; then
    echo "❌ Error: Target is '$TARGET_BRANCH' but current is '$CURRENT_BRANCH'."
    echo "   ► To commit to this branch, use: ./scripts/fast-commit.sh \"$MSG\" $CURRENT_BRANCH"
    exit 1
fi

# 0.5 Project Guard (Quick Check)
./scripts/project-guard.sh

# 1. Versioning (Smart Detection)
BUMP_REQUEST="${3:-$MSG}"
echo "📈 Processing versioning..."
node scripts/bump-version.js "$BUMP_REQUEST"
node scripts/update-version.js
node scripts/sync-sw.cjs

NEW_VER=$(node -p "require('./package.json').version")
BUILD_NUM=$(node -p "require('./package.json').buildNumber")
FULL_VER="${NEW_VER}+${BUILD_NUM}"

# 2. Changelog (Maintain history)
echo "📝 Updating Changelog..."
node scripts/update-changelog.js "$MSG"

# 3. Commit
git add .
git commit -m "v$FULL_VER [FAST]: $MSG"
echo "🚀 Fast-Committed v$FULL_VER"
